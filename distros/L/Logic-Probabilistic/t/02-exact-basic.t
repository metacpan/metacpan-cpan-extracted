use v5.38;
use experimental 'signatures';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all);

subtest 'Single coin toss' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.7, 'heads' );

    my $res = $prog->query('heads');
    is( $res->method, 'exact', 'used exact method' );
    ok( abs( $res->probability - 0.7 ) < 1e-9, 'P(heads) == 0.7' );
    is( $res->total_samples, 2, '2 possible worlds evaluated' );
};

subtest 'Two independent coins: conjunction and disjunction' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.5, 'c1' );
    $prog->pfact( 0.5, 'c2' );

    # Rule: both :- c1, c2.
    $prog->rule(
        head => call('both'),
        body => all( call('c1'), call('c2') ),
    );

    # Rule: either :- c1.
    # Rule: either :- c2.
    $prog->rule(
        head => call('either'),
        body => call('c1'),
    );
    $prog->rule(
        head => call('either'),
        body => call('c2'),
    );

    my $res_both = $prog->query('both');
    ok( abs( $res_both->probability - 0.25 ) < 1e-9, 'P(c1 AND c2) == 0.25' );

    my $res_either = $prog->query('either');
    ok( abs( $res_either->probability - 0.75 ) < 1e-9, 'P(c1 OR c2) == 0.75' );
    is( $res_either->total_samples, 4, '4 possible worlds' );
};

subtest 'Categorical choice: fair die' => sub {
    my $prog = Logic::Probabilistic->new;
    my $p    = 1.0 / 6.0;

    $prog->pchoice( 'roll',
        [ [ $p, 1 ], [ $p, 2 ], [ $p, 3 ], [ $p, 4 ], [ $p, 5 ], [ $p, 6 ], ] );

    # Query roll(3)
    my $res_3 = $prog->query( [ 'roll', 3 ] );
    ok( abs( $res_3->probability - ( 1.0 / 6.0 ) ) < 1e-6,
        'P(roll(3)) == 1/6' );

    # Rule: even :- roll(2) ; roll(4) ; roll(6)
    $prog->rule( head => call('even'), body => call( 'roll', 2 ) );
    $prog->rule( head => call('even'), body => call( 'roll', 4 ) );
    $prog->rule( head => call('even'), body => call( 'roll', 6 ) );

    my $res_even = $prog->query('even');
    ok( abs( $res_even->probability - 0.5 ) < 1e-6, 'P(even) == 0.5' );
    is( $res_even->total_samples, 6, '6 possible worlds' );
};

done_testing();
