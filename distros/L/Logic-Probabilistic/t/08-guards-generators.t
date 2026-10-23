use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call variable all guard);

subtest 'Custom Perl Generator and Guard with Exact Inference' => sub {
    my $prog = Logic::Probabilistic->new;

    # Custom iterator generator yielding numbers 1..5
    $prog->generator(
        'stream_1_to_5',
        1,
        sub ($arg) {
            my $count = 0;
            return sub {
                $count++;
                return ( $count <= 5 ) ? [$count] : undef;
            };
        }
    );

    # Probabilistic sensor: 90% chance of successfully detecting a trigger
    $prog->pfact( 0.90, 'sensor_active' );

    # Rule: detected_even(X) :- stream_1_to_5(X), guard(is_even), sensor_active.
    my $x = variable('X');
    $prog->rule(
        head => call( 'detected_even', $x ),
        body => all(
            call( 'stream_1_to_5', $x ),
            guard( [$x], sub ($n) { return ( $n % 2 ) == 0; } ),
            call('sensor_active'),
        ),
    );

    # P(detected_even(2)) = 0.90
    my $res2 = $prog->query( [ 'detected_even', 2 ], method => 'exact' );
    ok( abs( $res2->probability - 0.90 ) < 1e-6,
        'P(detected_even(2)) == 0.90' );

    # P(detected_even(4)) = 0.90
    my $res4 = $prog->query( [ 'detected_even', 4 ], method => 'exact' );
    ok( abs( $res4->probability - 0.90 ) < 1e-6,
        'P(detected_even(4)) == 0.90' );

    # P(detected_even(3)) = 0.0 (fails guard)
    my $res3 = $prog->query( [ 'detected_even', 3 ], method => 'exact' );
    is( $res3->probability, 0.0, 'P(detected_even(3)) == 0.0' );

    # P(detected_even(6)) = 0.0 (outside generator domain)
    my $res6 = $prog->query( [ 'detected_even', 6 ], method => 'exact' );
    is( $res6->probability, 0.0, 'P(detected_even(6)) == 0.0' );
};

subtest 'Guards with Monte Carlo and MCMC Inference' => sub {
    my $prog = Logic::Probabilistic->new;

    # Probabilistic score between 1 and 100
    $prog->pchoice( 'score', [ [ 0.10, 50 ], [ 0.40, 75 ], [ 0.50, 90 ], ] );

    # Rule: passing_grade(Threshold) :- score(S), guard(S >= Threshold).
    my $s         = variable('S');
    my $threshold = variable('Threshold');
    $prog->rule(
        head => call( 'passing_grade', $threshold ),
        body => all(
            call( 'score', $s ),
            guard(
                [ $s, $threshold ],
                sub ( $val, $thresh ) {
                    return $val >= $thresh;
                }
            ),
        ),
    );

    # Threshold 70: scores 75 (0.40) and 90 (0.50) pass => exact 0.90
    my $res_exact = $prog->query( [ 'passing_grade', 70 ], method => 'exact' );
    ok(
        abs( $res_exact->probability - 0.90 ) < 1e-6,
        'Exact P(passing_grade(70)) == 0.90'
    );

    # Rejection sampling
    my $res_mc = $prog->query(
        [ 'passing_grade', 70 ],
        method  => 'rejection',
        samples => 3000,
        seed    => 42,
    );
    my ( $low, $high ) = $res_mc->ci(0.99);
    cmp_ok( 0.90, '>=', $low,  '0.90 within MC 99% CI low' );
    cmp_ok( 0.90, '<=', $high, '0.90 within MC 99% CI high' );

    # MCMC sampling
    my $res_mcmc = $prog->query(
        [ 'passing_grade', 70 ],
        method  => 'mcmc',
        chains  => 4,
        samples => 2000,
        burn_in => 100,
        lag     => 2,
        seed    => 123,
    );
    my ( $m_low, $m_high ) = $res_mcmc->ci(0.99);
    cmp_ok( 0.90, '>=', $m_low,  '0.90 within MCMC 99% CI low' );
    cmp_ok( 0.90, '<=', $m_high, '0.90 within MCMC 99% CI high' );
};

done_testing();
