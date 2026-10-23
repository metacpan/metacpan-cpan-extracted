use v5.38;
use experimental 'signatures';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all not_goal variable);

sub is_close ( $got, $expected, $desc, $tol = 1e-6 ) {
    my $diff = abs( $got - $expected );
    ok( $diff < $tol, "$desc (got $got, expected $expected, diff $diff)" );
    return;
}

subtest 'Unconditioned conjunction gradients' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.6, 'a' );
    $prog->pfact( 0.4, 'b' );
    $prog->rule(
        head => call('both'),
        body => all( call('a'), call('b') ),
    );

    # Standard query without gradients
    my $std_res = $prog->query('both');
    is_close( $std_res->probability, 0.24, 'P(both) = 0.24' );
    ok( !$std_res->has_gradients, 'has_gradients is false by default' );
    is( scalar keys %{ $std_res->gradients }, 0, 'gradients empty by default' );
    is( $std_res->gradient('a'), 0.0, 'gradient(a) is 0.0 by default' );

    # Query with gradients
    my $res = $prog->query( 'both', with_gradients => 1 );
    is_close( $res->probability, 0.24,
        'P(both) = 0.24 with gradients enabled' );
    ok( $res->has_gradients, 'has_gradients is true when enabled' );

    my $grads = $res->gradients;
    ok( exists $grads->{a}, 'gradient for a exists' );
    ok( exists $grads->{b}, 'gradient for b exists' );

    # Analytical: d(a*b)/da = b = 0.4; d(a*b)/db = a = 0.6
    is_close( $res->gradient('a'), 0.4, 'dP/da == 0.4' );
    is_close( $res->gradient('b'), 0.6, 'dP/db == 0.6' );

    # Lookup using PFact object
    my ($pf_a) = grep { $_->predicate eq 'a' } $prog->all_pfacts;
    ok( $pf_a, 'found PFact for a' );
    is_close( $res->gradient($pf_a), 0.4, 'dP/d(PFact_a) == 0.4' );
};

subtest 'Unconditioned disjunction gradients' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.7, 'a' );
    $prog->pfact( 0.3, 'b' );
    $prog->rule(
        head => call('either'),
        body => call('a'),
    );
    $prog->rule(
        head => call('either'),
        body => call('b'),
    );

    my $res = $prog->query( 'either', with_gradients => 1 );

    # P(either) = 0.7 + 0.3 - 0.21 = 0.79
    is_close( $res->probability, 0.79, 'P(either) = 0.79' );

    # Analytical: d(a + b - ab)/da = 1 - b = 0.7
    #             d(a + b - ab)/db = 1 - a = 0.3
    is_close( $res->gradient('a'), 0.7, 'dP/da == 1 - b == 0.7' );
    is_close( $res->gradient('b'), 0.3, 'dP/db == 1 - a == 0.3' );
};

subtest 'Conditioned inference (quotient rule & explaining away)' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.6, 'a' );
    $prog->pfact( 0.4, 'b' );
    $prog->rule(
        head => call('either'),
        body => call('a'),
    );
    $prog->rule(
        head => call('either'),
        body => call('b'),
    );

    # Query: a, given either (a or b)
    # P(E) = 0.6 + 0.4 - 0.24 = 0.76
    # P(Q, E) = P(a) = 0.6
    # P(Q | E) = 0.6 / 0.76 = 0.789473684...
    # dP/da = b / P(E)^2 = 0.4 / (0.76^2) = 0.4 / 0.5776 = 0.69252076...
    # dP/db = -a*(1-a) / P(E)^2 = -0.24 / 0.5776 = -0.41551245...
    my $res = $prog->query(
        'a',
        evidence       => ['either'],
        with_gradients => 1,
    );

    is_close( $res->probability, 0.6 / 0.76, 'P(a | either) matches' );
    is_close(
        $res->gradient('a'),
        0.4 / ( 0.76 * 0.76 ),
        'dP/da matches quotient rule'
    );
    is_close(
        $res->gradient('b'),
        -0.24 / ( 0.76 * 0.76 ),
        'dP/db matches explaining away (< 0)'
    );
};

subtest 'Probabilistic choices gradients' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pchoice( 'c', [ [ 0.3, 1 ], [ 0.4, 2 ], ] );
    $prog->rule(
        head => call('picked_one'),
        body => call( 'c', 1 ),
    );

    my $res = $prog->query( 'picked_one', with_gradients => 1 );
    is_close( $res->probability, 0.3, 'P(picked_one) = 0.3' );

    is_close( $res->gradient('c(1)'), 1.0, 'dP/d(c(1)) == 1.0' );
    is_close( $res->gradient('c(2)'), 0.0, 'dP/d(c(2)) == 0.0' );
};

subtest 'Boundary probabilities (0.0 and 1.0)' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.0, 'a' );
    $prog->pfact( 0.8, 'b' );
    $prog->rule(
        head => call('both'),
        body => all( call('a'), call('b') ),
    );

    my $res = $prog->query( 'both', with_gradients => 1 );
    is_close( $res->probability,   0.0, 'P(both) = 0.0' );
    is_close( $res->gradient('a'), 0.8, 'dP/da at p=0.0 is b = 0.8' );
    is_close( $res->gradient('b'), 0.0, 'dP/db at p=0.0 is a = 0.0' );

    my $prog2 = Logic::Probabilistic->new;
    $prog2->pfact( 1.0, 'x' );
    $prog2->pfact( 0.5, 'y' );
    $prog2->rule(
        head => call('either'),
        body => call('x'),
    );
    $prog2->rule(
        head => call('either'),
        body => call('y'),
    );

    my $res2 = $prog2->query( 'either', with_gradients => 1 );
    is_close( $res2->probability,   1.0, 'P(either) = 1.0' );
    is_close( $res2->gradient('x'), 0.5, 'dP/dx at p=1.0 is 1 - y = 0.5' );
    is_close( $res2->gradient('y'), 0.0, 'dP/dy at p=1.0 is 1 - x = 0.0' );
};

subtest 'Relational predicates with arguments and spacing' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.5, 'edge', 'a', 'b' );
    $prog->pfact( 0.6, 'edge', 'b', 'c' );
    my $x = variable('x');
    my $y = variable('y');
    my $z = variable('z');
    $prog->rule(
        head => call( 'path', $x, $y ),
        body => call( 'edge', $x, $y ),
    );
    $prog->rule(
        head => call( 'path', $x, $y ),
        body => all( call( 'edge', $x, $z ), call( 'path', $z, $y ) ),
    );

    my $res = $prog->query( [ 'path', 'a', 'c' ], with_gradients => 1 );
    is_close( $res->probability, 0.3, 'P(path(a,c)) = 0.3' );

    # Analytical: d(edge(a,b) * edge(b,c)) / d(edge(a,b)) = 0.6
    is_close( $res->gradient('edge(a,b)'), 0.6,
        'gradient with compact string' );
    is_close( $res->gradient('edge(a, b)'), 0.6,
        'gradient with spaced string' );
};

subtest 'Finite difference numerical verification on Alarm network' => sub {
    my $build_alarm = sub ( $p_b, $p_e ) {
        my $prog = Logic::Probabilistic->new;
        $prog->pfact( $p_b, 'burglary' );
        $prog->pfact( $p_e, 'earthquake' );
        $prog->pfact( 0.9,  'alarm_trigger_be' );
        $prog->pfact( 0.8,  'alarm_trigger_b' );
        $prog->pfact( 0.1,  'alarm_trigger_e' );

        $prog->rule(
            head => call('alarm'),
            body => all(
                call('burglary'), call('earthquake'),
                call('alarm_trigger_be')
            ),
        );
        $prog->rule(
            head => call('alarm'),
            body => all(
                call('burglary'), not_goal( call('earthquake') ),
                call('alarm_trigger_b')
            ),
        );
        $prog->rule(
            head => call('alarm'),
            body => all(
                not_goal( call('burglary') ), call('earthquake'),
                call('alarm_trigger_e')
            ),
        );
        return $prog;
    };

    my $p_b  = 0.05;
    my $p_e  = 0.02;
    my $prog = $build_alarm->( $p_b, $p_e );

    my $res       = $prog->query( 'alarm', with_gradients => 1 );
    my $exact_d_b = $res->gradient('burglary');
    my $exact_d_e = $res->gradient('earthquake');

    # Numerical finite differences: (f(x+h) - f(x-h)) / (2h)
    my $h            = 1e-5;
    my $prog_b_plus  = $build_alarm->( $p_b + $h, $p_e );
    my $prog_b_minus = $build_alarm->( $p_b - $h, $p_e );
    my $num_d_b =
      ( $prog_b_plus->query('alarm')->probability -
          $prog_b_minus->query('alarm')->probability ) /
      ( 2 * $h );

    my $prog_e_plus  = $build_alarm->( $p_b, $p_e + $h );
    my $prog_e_minus = $build_alarm->( $p_b, $p_e - $h );
    my $num_d_e =
      ( $prog_e_plus->query('alarm')->probability -
          $prog_e_minus->query('alarm')->probability ) /
      ( 2 * $h );

    is_close( $exact_d_b, $num_d_b,
        'burglary gradient matches finite difference', 1e-4 );
    is_close( $exact_d_e, $num_d_e,
        'earthquake gradient matches finite difference', 1e-4 );
};

done_testing();
