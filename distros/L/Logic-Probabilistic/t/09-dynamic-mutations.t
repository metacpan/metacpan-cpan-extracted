use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(all call);

subtest 'Dynamic PFact retraction' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.20, 'sensor_alert' );
    $prog->pfact( 0.05, 'node_down', 'alpha' );
    $prog->pfact( 0.10, 'node_down', 'beta' );

    # Initial query
    my $res_sensor = $prog->query('sensor_alert');
    ok( abs( $res_sensor->probability - 0.20 ) < 1e-6,
        'Initial P(sensor_alert) == 0.20' );

    # Retract sensor_alert
    my $removed_sensor = $prog->retract_pfact('sensor_alert');
    ok( $removed_sensor, 'retract_pfact returned removed PFact object' );
    is( $removed_sensor->predicate,
        'sensor_alert', 'Removed predicate matches' );

    my $res_sensor_after = $prog->query('sensor_alert');
    is( $res_sensor_after->probability,
        0.0, 'P(sensor_alert) is 0 after retraction' );

    # Retract specific node_down argument
    my $removed_node = $prog->retract_pfact( 'node_down', 'alpha' );
    ok( $removed_node, 'retract_pfact(node_down, alpha) succeeded' );

    my $res_alpha = $prog->query( [ 'node_down', 'alpha' ] );
    is( $res_alpha->probability, 0.0, 'P(node_down(alpha)) is 0.0' );

    my $res_beta = $prog->query( [ 'node_down', 'beta' ] );
    ok(
        abs( $res_beta->probability - 0.10 ) < 1e-6,
        'P(node_down(beta)) remains 0.10'
    );

    # Retract non-existent returns undef
    my $missing = $prog->retract_pfact('non_existent');
    ok( !defined $missing, 'Retracting non-existent returns undef' );
};

subtest 'Dynamic PFact update and set (upsert)' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.40, 'battery_low', 'drone_1' );

    my $res1 = $prog->query( [ 'battery_low', 'drone_1' ] );
    ok(
        abs( $res1->probability - 0.40 ) < 1e-6,
        'P(battery_low(drone_1)) == 0.40'
    );

    # Update probability in place (replaces rather than creating noisy-OR)
    my $updated = $prog->update_pfact( 0.85, 'battery_low', 'drone_1' );
    ok( $updated, 'update_pfact succeeded' );

    my $res2 = $prog->query( [ 'battery_low', 'drone_1' ] );
    ok( abs( $res2->probability - 0.85 ) < 1e-6,
        'P(battery_low(drone_1)) updated to 0.85 (not noisy-OR)' );

    # Updating non-existent returns undef
    my $miss = $prog->update_pfact( 0.99, 'battery_low', 'drone_999' );
    ok( !defined $miss, 'Updating missing fact returns undef' );

    # set_pfact acts as upsert
    my $upsert_existing = $prog->set_pfact( 0.25, 'battery_low', 'drone_1' );
    is( $upsert_existing->probability, 0.25, 'set_pfact updated existing' );
    my $res3 = $prog->query( [ 'battery_low', 'drone_1' ] );
    ok(
        abs( $res3->probability - 0.25 ) < 1e-6,
        'P(battery_low(drone_1)) is now 0.25'
    );

    my $upsert_new = $prog->set_pfact( 0.75, 'battery_low', 'drone_2' );
    is( $upsert_new->probability, 0.75, 'set_pfact inserted new atom' );
    my $res4 = $prog->query( [ 'battery_low', 'drone_2' ] );
    ok(
        abs( $res4->probability - 0.75 ) < 1e-6,
        'P(battery_low(drone_2)) is 0.75'
    );
};

subtest 'Dynamic PChoice update and retraction' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pchoice( 'traffic', [ [ 0.20, 'low' ], [ 0.80, 'high' ] ] );

    my $res_low = $prog->query( [ 'traffic', 'low' ] );
    ok(
        abs( $res_low->probability - 0.20 ) < 1e-6,
        'Initial P(traffic(low)) == 0.20'
    );

    # Update outcomes
    my $updated =
      $prog->update_pchoice( 'traffic', [ [ 0.60, 'low' ], [ 0.40, 'high' ] ] );
    ok( $updated, 'update_pchoice succeeded' );

    my $res_low_after = $prog->query( [ 'traffic', 'low' ] );
    ok( abs( $res_low_after->probability - 0.60 ) < 1e-6,
        'P(traffic(low)) updated to 0.60' );

    # Retract choice
    my $removed = $prog->retract_pchoice('traffic');
    ok( $removed, 'retract_pchoice succeeded' );

    my $res_low_gone = $prog->query( [ 'traffic', 'low' ] );
    is( $res_low_gone->probability,
        0.0, 'P(traffic(low)) is 0.0 after retract' );
};

subtest 'Deterministic facts assert and retract delegation' => sub {
    my $prog = Logic::Probabilistic->new;

    require Logic::Relational::Goal::Call;
    $prog->pfact( 0.90, 'link_active' );

    # Rule: path_open :- link_active, route(A, B).
    $prog->rule(
        head => Logic::Relational::Goal::Call->new( 'path_open', [] ),
        body => Logic::Relational::DSL::all(
            Logic::Relational::Goal::Call->new( 'link_active', [] ),
            Logic::Relational::Goal::Call->new( 'route', [ 'alpha', 'beta' ] ),
        ),
    );

    # Assert deterministic route
    $prog->fact( 'route', 'alpha', 'beta' );

    my $res1 = $prog->query('path_open');
    ok(
        abs( $res1->probability - 0.90 ) < 1e-6,
        'P(path_open) == 0.90 with route'
    );

    # Retract deterministic route
    my $status = $prog->retract( 'route', 'alpha', 'beta' );
    is( $status, 1, 'retract returned 1 for route fact' );

    my $res2 = $prog->query('path_open');
    is( $res2->probability, 0.0, 'P(path_open) == 0.0 after route retracted' );
};

subtest 'Expiring facts and pfacts with automatic pruning' => sub {
    my $prog = Logic::Probabilistic->new;

    # Probabilistic fact expiring in 1 second
    $prog->pfact( 0.80, 'transient_glitch', { expires_in => 1 } );

    # Deterministic fact expiring in 1 second
    $prog->assert_fact(
        term       => [ 'heartbeat_received', 'node_1' ],
        expires_in => 1,
    );

    # Query immediately: both are active
    my $res_pfact_now = $prog->query('transient_glitch');
    ok(
        abs( $res_pfact_now->probability - 0.80 ) < 1e-6,
        'Immediate P(transient_glitch) == 0.80'
    );

    my $res_fact_now = $prog->query( [ 'heartbeat_received', 'node_1' ] );
    is( $res_fact_now->probability, 1.0, 'Immediate heartbeat fact is true' );

    # Wait for expiration
    sleep 2;

    # Query again: both should be expired and pruned automatically
    my $res_pfact_later = $prog->query('transient_glitch');
    is( $res_pfact_later->probability,
        0.0, 'P(transient_glitch) is 0.0 after expiration' );

    my $res_fact_later = $prog->query( [ 'heartbeat_received', 'node_1' ] );
    is( $res_fact_later->probability,
        0.0, 'Heartbeat fact is 0.0 after expiration' );
};

subtest 'Sampling inference with dynamic mutations' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.30, 'sensor_val' );

    my $res_rej1 = $prog->query(
        'sensor_val',
        method  => 'rejection',
        samples => 1000,
        seed    => 42,
    );
    my ( $low1, $high1 ) = $res_rej1->ci(0.99);
    cmp_ok( 0.30, '>=', $low1,  '0.30 within Rejection CI low' );
    cmp_ok( 0.30, '<=', $high1, '0.30 within Rejection CI high' );

    # Mutate to 0.80
    $prog->update_pfact( 0.80, 'sensor_val' );

    my $res_mcmc2 = $prog->query(
        'sensor_val',
        method  => 'mcmc',
        chains  => 2,
        samples => 1000,
        seed    => 42,
    );
    my ( $low2, $high2 ) = $res_mcmc2->ci(0.99);
    cmp_ok( 0.80, '>=', $low2,  '0.80 within MCMC CI low after update' );
    cmp_ok( 0.80, '<=', $high2, '0.80 within MCMC CI high after update' );

    # Retract
    $prog->retract_pfact('sensor_val');

    my $res_rej3 = $prog->query(
        'sensor_val',
        method  => 'rejection',
        samples => 500,
    );
    is( $res_rej3->probability, 0.0,
        'P(sensor_val) == 0.0 under Rejection after retract' );
};

done_testing();
