use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;
use File::Temp qw(tempfile);

use Logic::Probabilistic;
use Logic::Probabilistic::Syntax;
use Logic::Relational::DSL qw(call all save_snapshot load_snapshot not_goal);

sub is_close ( $got, $expected, $desc, $tol = 1e-6 ) {
    my $diff = abs( $got - $expected );
    ok( $diff < $tol, "$desc (got $got, expected $expected, diff $diff)" );
    return;
}

subtest 'Basic save and load of probabilistic facts' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.70, 'coin', 'heads' );
    $prog->pfact( 0.40, 'bonus' );
    $prog->rule(
        head => call('win'),
        body => all( call( 'coin', 'heads' ), call('bonus') )
    );

    my $res_before = $prog->query('win');
    is_close( $res_before->probability, 0.28,
        'P(win) before snapshot == 0.28' );

    # Save to scalar ref
    my $json_str;
    $prog->save_snapshot( \$json_str );
    ok( defined $json_str && length($json_str) > 0,
        'snapshot generated in memory' );
    like(
        $json_str,
        qr/"engine"\s*:\s*"Logic::Probabilistic"/x,
        'contains engine metadata'
    );
    like( $json_str, qr/"coin"/x, 'contains coin fact' );

    # Mutate program state
    $prog->update_pfact( 0.10, 'bonus' );
    my $res_mutated = $prog->query('win');
    is_close( $res_mutated->probability, 0.07, 'P(win) mutated == 0.07' );

    # Reload snapshot with mode => replace
    my $loaded = $prog->load_snapshot( \$json_str, mode => 'replace' );
    cmp_ok( $loaded, '>=', 2, 'loaded at least 2 facts' );

    my $res_after = $prog->query('win');
    is_close( $res_after->probability, 0.28,
        'P(win) restored after load == 0.28' );
};

subtest 'Save and load to file on disk' => sub {
    my ( $fh, $filename ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
    close $fh;

    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.60, 'sunny' );
    $prog->pfact( 0.80, 'weekend' );
    $prog->rule(
        head => call('park'),
        body => all( call('sunny'), call('weekend') )
    );

    # Save to file
    $prog->save_snapshot($filename);
    ok( -s $filename > 0, 'snapshot file written to disk' );

    # Create a fresh program and load snapshot
    my $fresh_prog = Logic::Probabilistic->new;
    $fresh_prog->rule(
        head => call('park'),
        body => all( call('sunny'), call('weekend') )
    );

    $fresh_prog->load_snapshot($filename);
    my $res = $fresh_prog->query('park');
    is_close( $res->probability, 0.48, 'P(park) on fresh program == 0.48' );
};

subtest 'Categorical choices serialization' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pchoice( 'weather',
        [ [ 0.60, 'sunny' ], [ 0.30, 'cloudy' ], [ 0.10, 'rainy' ], ] );
    $prog->rule(
        head => call('good_weather'),
        body => call( 'weather', 'sunny' )
    );

    my $json_str;
    $prog->save_snapshot( \$json_str );
    like( $json_str, qr/"pchoices"/x, 'contains pchoices section' );
    like( $json_str, qr/"sunny"/x,    'contains outcome sunny' );

    my $fresh_prog = Logic::Probabilistic->new;
    $fresh_prog->rule(
        head => call('good_weather'),
        body => call( 'weather', 'sunny' )
    );
    $fresh_prog->load_snapshot( \$json_str );

    my $res = $fresh_prog->query('good_weather');
    is_close( $res->probability, 0.60, 'P(good_weather) restored == 0.60' );
};

subtest 'Deterministic facts alongside probabilistic facts' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.50, 'parent_prob', 'alice', 'bob' );
    $prog->fact( 'parent', 'bob', 'carol' );    # deterministic fact
    my $vx = Logic::Relational::DSL::variable('X');
    my $vy = Logic::Relational::DSL::variable('Y');
    $prog->rule(
        head => call( 'ancestor',    $vx, $vy ),
        body => call( 'parent_prob', $vx, $vy )
    );
    $prog->rule(
        head => call( 'ancestor', $vx, $vy ),
        body => call( 'parent',   $vx, $vy )
    );

    my $json_str;
    $prog->save_snapshot( \$json_str );
    like( $json_str, qr/"deterministic_facts"/x,
        'contains deterministic facts' );

    my $fresh_prog = Logic::Probabilistic->new;
    $fresh_prog->rule(
        head => call( 'ancestor',    $vx, $vy ),
        body => call( 'parent_prob', $vx, $vy )
    );
    $fresh_prog->rule(
        head => call( 'ancestor', $vx, $vy ),
        body => call( 'parent',   $vx, $vy )
    );
    $fresh_prog->load_snapshot( \$json_str );

    my $res1 = $fresh_prog->query( [ 'ancestor', 'alice', 'bob' ] );
    is_close( $res1->probability, 0.50, 'ancestor(alice, bob) == 0.50' );

    my $res2 = $fresh_prog->query( [ 'ancestor', 'bob', 'carol' ] );
    is_close( $res2->probability, 1.00,
        'ancestor(bob, carol) == 1.00 (deterministic)' );
};

subtest 'Snapshot merge mode' => sub {
    my $prog1 = Logic::Probabilistic->new;
    $prog1->pfact( 0.40, 'a' );
    my $json_a;
    $prog1->save_snapshot( \$json_a );

    my $prog2 = Logic::Probabilistic->new;
    $prog2->pfact( 0.30, 'b' );
    $prog2->load_snapshot( \$json_a, mode => 'merge' );

    is( scalar( $prog2->all_pfacts ), 2, 'prog2 has 2 facts after merge' );
    ok( ( grep { $_->predicate eq 'a' } $prog2->all_pfacts ),
        'contains fact a' );
    ok( ( grep { $_->predicate eq 'b' } $prog2->all_pfacts ),
        'contains fact b' );
};

subtest 'TTL simulation pause (relative TTL mode)' => sub {
    my $prog = Logic::Probabilistic->new;

    # Fact with 10 seconds remaining TTL
    $prog->pfact( 0.90, 'sensor_alert', { expires_in => 10 } );

    my $json_str;
    $prog->save_snapshot( \$json_str );

    my $fresh_prog = Logic::Probabilistic->new;
    $fresh_prog->load_snapshot( \$json_str, ttl_mode => 'relative' );

    my ($pf) = $fresh_prog->all_pfacts;
    ok( defined $pf,             'fact loaded in relative TTL mode' );
    ok( defined $pf->expires_at, 'has expires_at' );
    cmp_ok( $pf->remaining_ttl, '>',  0,  'has remaining TTL (> 0)' );
    cmp_ok( $pf->remaining_ttl, '<=', 10, 'remaining TTL <= 10' );
};

prob_logic SyntaxSnapshotModel {
    pfact 0.85 => signal;
}

subtest 'Declarative syntax $PROGRAM snapshot integration' => sub {
    my $json_dsl;
    $SyntaxSnapshotModel::PROGRAM->save_snapshot( \$json_dsl );
    like( $json_dsl, qr/"signal"/x, 'snapshot saved via $Model::PROGRAM' );

    $SyntaxSnapshotModel::PROGRAM->update_pfact( 0.10, 'signal' );
    my $res_low = $SyntaxSnapshotModel::PROGRAM->query('signal');
    is_close( $res_low->probability, 0.10, 'signal updated to 0.10' );

    $SyntaxSnapshotModel::PROGRAM->load_snapshot( \$json_dsl );
    my $res_restored = $SyntaxSnapshotModel::PROGRAM->query('signal');
    is_close( $res_restored->probability, 0.85, 'signal restored to 0.85' );
};

done_testing();
