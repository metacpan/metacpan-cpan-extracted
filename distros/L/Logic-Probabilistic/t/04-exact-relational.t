use v5.38;
use experimental 'signatures';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all variable);

subtest 'Probabilistic Graph Reachability (Network Reliability)' => sub {
    my $prog = Logic::Probabilistic->new;

    # Probabilistic edges
    # A -> B (p=0.6)
    # B -> C (p=0.7)
    # A -> C (p=0.5) direct
    $prog->pfact( 0.6, 'edge', 'a', 'b' );
    $prog->pfact( 0.7, 'edge', 'b', 'c' );
    $prog->pfact( 0.5, 'edge', 'a', 'c' );

    # Recursive path rules
    # path(X, Y) :- edge(X, Y).
    my $x = variable('x');
    my $y = variable('y');
    my $z = variable('z');

    $prog->rule(
        head => call( 'path', $x, $y ),
        body => call( 'edge', $x, $y ),
    );

    # path(X, Y) :- edge(X, Z), path(Z, Y).
    $prog->rule(
        head => call( 'path', $x, $y ),
        body => all( call( 'edge', $x, $z ), call( 'path', $z, $y ) ),
    );

    # P(path(a, c)) = P(direct OR via_b)
    # P(direct) = 0.5
    # P(via_b)  = 0.6 * 0.7 = 0.42
    # P(both)   = 0.5 * 0.42 = 0.21
    # P(path)   = 0.5 + 0.42 - 0.21 = 0.71
    my $res = $prog->query( [ 'path', 'a', 'c' ] );

    ok( abs( $res->probability - 0.71 ) < 1e-6, 'P(path(a, c)) == 0.71' );
    is( $res->total_samples, 8, '2^3 = 8 possible worlds evaluated' );
};

subtest 'Existential query with logical variables' => sub {
    my $prog = Logic::Probabilistic->new;

    # Independent faults for components c1 and c2
    $prog->pfact( 0.2, 'fault', 'c1' );
    $prog->pfact( 0.3, 'fault', 'c2' );

    my $comp = variable('comp');

    # system_fails :- fault(Comp).
    $prog->rule(
        head => call('system_fails'),
        body => call( 'fault', $comp ),
    );

    # P(system_fails) = 1 - (1 - 0.2) * (1 - 0.3) = 1 - 0.56 = 0.44
    my $res = $prog->query('system_fails');
    ok( abs( $res->probability - 0.44 ) < 1e-6, 'P(system_fails) == 0.44' );
};

done_testing();
