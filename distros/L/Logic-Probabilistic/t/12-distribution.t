use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use Test::More;
use Logic::Probabilistic;
use Logic::Probabilistic::Distribution;
use Logic::Relational::DSL qw(call all variable is_goal);

subtest 'Logic::Probabilistic::Distribution container methods' => sub {
    my %probs = (
        1 => 0.1,
        2 => 0.2,
        3 => 0.4,
        4 => 0.3,
    );

    my $dist = Logic::Probabilistic::Distribution->new(
        probabilities => \%probs,
        method        => 'exact',
        total_samples => 10,
    );

    ok( $dist->is_numeric, 'Distribution identified as numeric' );
    is_deeply( [ $dist->values ], [ 1, 2, 3, 4 ], 'Values sorted numerically' );
    is( $dist->probability(3), 0.4, 'P(3) = 0.4' );
    is( $dist->probability(5), 0.0, 'P(non-existent) = 0.0' );
    is( $dist->prob(2),        0.2, 'prob alias' );
    is( $dist->pmf(4),         0.3, 'pmf alias' );

    # Moments:
    # E[X] = 1*0.1 + 2*0.2 + 3*0.4 + 4*0.3 = 0.1 + 0.4 + 1.2 + 1.2 = 2.9
    ok( abs( $dist->mean - 2.9 ) < 1e-9,        'mean = 2.9' );
    ok( abs( $dist->expectation - 2.9 ) < 1e-9, 'expectation alias = 2.9' );

    # Var(X) = E[X^2] - (E[X])^2
    # E[X^2] = 1*0.1 + 4*0.2 + 9*0.4 + 16*0.3 = 0.1 + 0.8 + 3.6 + 4.8 = 9.3
    # Var(X) = 9.3 - (2.9)^2 = 9.3 - 8.41 = 0.89
    ok( abs( $dist->variance - 0.89 ) < 1e-9,      'variance = 0.89' );
    ok( abs( $dist->std_dev - sqrt(0.89) ) < 1e-9, 'std_dev = sqrt(0.89)' );

    # Mode: 3 has prob 0.4
    is( scalar( $dist->mode ), 3, 'mode = 3' );
    is( $dist->min,            1, 'min = 1' );
    is( $dist->max,            4, 'max = 4' );

    # CDF:
    # CDF(1) = 0.1, CDF(2) = 0.3, CDF(3) = 0.7, CDF(4) = 1.0
    ok( abs( $dist->cdf(1) - 0.1 ) < 1e-9, 'cdf(1) = 0.1' );
    ok( abs( $dist->cdf(2) - 0.3 ) < 1e-9, 'cdf(2) = 0.3' );
    ok( abs( $dist->cdf(3) - 0.7 ) < 1e-9, 'cdf(3) = 0.7' );
    ok( abs( $dist->cdf(4) - 1.0 ) < 1e-9, 'cdf(4) = 1.0' );

    # Quantiles:
    is( $dist->quantile(0.1),  1, 'quantile(0.1) = 1' );
    is( $dist->quantile(0.25), 2, 'quantile(0.25) = 2' );
    is( $dist->quantile(0.5),  3, 'quantile(0.5) = 3 (median)' );
    is( $dist->quantile(0.8),  4, 'quantile(0.8) = 4' );
    is( $dist->percentile(50), 3, 'percentile(50) = 3' );

    # Sampling:
    my $sample_val = $dist->sample;
    ok( defined $sample_val && $sample_val >= 1 && $sample_val <= 4,
        "sample() produced valid value $sample_val" );

    # Stringification table output:
    my $str = "$dist";
    like( $str, qr/Value\s+\|\s+Probability/x, 'String output has header' );
    like( $str, qr/Mean:\s+2\.9000/x, 'String output has mean summary' );
};

subtest 'Categorical (non-numeric) distribution' => sub {
    my $coin_dist = Logic::Probabilistic::Distribution->new(
        probabilities => { heads => 0.6, tails => 0.4 },
        method        => 'exact',
    );

    ok( !$coin_dist->is_numeric, 'Categorical distribution is not numeric' );
    is_deeply(
        [ $coin_dist->values ],
        [ 'heads', 'tails' ],
        'Values sorted alphabetically'
    );
    is( scalar( $coin_dist->mode ), 'heads', 'Mode is heads' );

    # Calling numeric moments on non-numeric throws an exception
    my $caught_mean = 0;
    try {
        $coin_dist->mean;
    }
    catch ($e) {
        $caught_mean = 1;
    }
    ok( $caught_mean, 'mean on non-numeric distribution throws error' );

    my $str = "$coin_dist";
    like( $str, qr/heads\s+\|\s+0\.6000/x, 'Categorical string table renders' );
    like( $str, qr/Mode:\s+heads/x,        'Categorical mode in footer' );
};

subtest 'Exact inference: Two fair dice sum distribution' => sub {
    my $prog = Logic::Probabilistic->new;

    # Die 1 and Die 2 fair 6-sided dice
    $prog->pchoice( 'die1', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );
    $prog->pchoice( 'die2', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );

    my $d1    = variable('D1');
    my $d2    = variable('D2');
    my $total = variable('Total');

    # dice_sum(Total) :- die1(D1), die2(D2), Total is D1 + D2.
    $prog->rule(
        head => call( 'dice_sum', $total ),
        body => all(
            call( 'die1', $d1 ),
            call( 'die2', $d2 ),
            is_goal( $total, [ $d1, $d2 ], sub ( $a, $b ) { $a + $b } ),
        ),
    );

    # Query distribution with explicit variable and goal
    my $dist =
      $prog->query_distribution( call( 'dice_sum', $total ), var => $total );

    isa_ok( $dist, 'Logic::Probabilistic::Distribution' );
    is( $dist->total_samples, 36, '6 x 6 = 36 total worlds evaluated' );

    # Values must be 2 .. 12
    is_deeply(
        [ $dist->values ],
        [ 2 .. 12 ],
        'Possible sums are 2 through 12'
    );

    # Theoretical probabilities:
    # P(2) = 1/36, P(7) = 6/36 = 1/6, P(12) = 1/36
    ok( abs( $dist->probability(2) - ( 1 / 36 ) ) < 1e-6,
        'P(Sum = 2) == 1/36' );
    ok( abs( $dist->probability(7) - ( 6 / 36 ) ) < 1e-6,
        'P(Sum = 7) == 6/36' );
    ok( abs( $dist->probability(12) - ( 1 / 36 ) ) < 1e-6,
        'P(Sum = 12) == 1/36' );

    # Theoretical statistical moments:
    # Mean: 7.0
    # Variance: 35/6 = 5.83333...
    # Mode: 7
    ok( abs( $dist->mean - 7.0 ) < 1e-6, 'Expected sum is exactly 7.0' );
    ok(
        abs( $dist->variance - ( 35 / 6 ) ) < 1e-6,
        'Variance is exactly 35/6 (~5.8333)'
    );
    is( scalar( $dist->mode ), 7,  'Mode of two dice sum is 7' );
    is( $dist->min,            2,  'Min sum is 2' );
    is( $dist->max,            12, 'Max sum is 12' );

    # Test auto-detection of variable without passing var => $total
    my $q_var     = variable('QTotal');
    my $dist_auto = $prog->query_distribution( call( 'dice_sum', $q_var ) );
    ok(
        abs( $dist_auto->mean - 7.0 ) < 1e-6,
        'Auto-detected target variable correctly'
    );

    # Test query(..., as_distribution => 1) option
    my $dist_opt =
      $prog->query( call( 'dice_sum', $q_var ), as_distribution => 1 );
    isa_ok( $dist_opt, 'Logic::Probabilistic::Distribution' );
    ok( abs( $dist_opt->mean - 7.0 ) < 1e-6,
        'query(as_distribution => 1) works identically' );
};

subtest 'Conditioned distribution: Two dice sum given die1 = 6' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pchoice( 'die1', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );
    $prog->pchoice( 'die2', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );

    my $d1    = variable('D1');
    my $d2    = variable('D2');
    my $total = variable('Total');

    $prog->rule(
        head => call( 'dice_sum', $total ),
        body => all(
            call( 'die1', $d1 ),
            call( 'die2', $d2 ),
            is_goal( $total, [ $d1, $d2 ], sub ( $a, $b ) { $a + $b } ),
        ),
    );

    # Condition on die1 = 6
    my $dist = $prog->query_distribution( call( 'dice_sum', $total ),
        given => [ call( 'die1', 6 ) ] );

    # Given die1 = 6, sums are uniformly 7 .. 12 with prob 1/6
    is_deeply( [ $dist->values ], [ 7 .. 12 ], 'Conditioned sums are 7..12' );
    for my $s ( 7 .. 12 ) {
        ok( abs( $dist->probability($s) - ( 1 / 6 ) ) < 1e-6,
            "P(Sum = $s | die1=6) == 1/6" );
    }

    # Mean = 9.5
    ok( abs( $dist->mean - 9.5 ) < 1e-6, 'Conditional mean is 9.5' );
    ok( abs( $dist->evidence_probability - ( 1 / 6 ) ) < 1e-6,
        'P(evidence die1=6) == 1/6' );
};

subtest 'Rejection sampling distribution' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pchoice( 'die1', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );
    $prog->pchoice( 'die2', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );

    my $d1    = variable('D1');
    my $d2    = variable('D2');
    my $total = variable('Total');

    $prog->rule(
        head => call( 'dice_sum', $total ),
        body => all(
            call( 'die1', $d1 ),
            call( 'die2', $d2 ),
            is_goal( $total, [ $d1, $d2 ], sub ( $a, $b ) { $a + $b } ),
        ),
    );

    my $dist = $prog->query_distribution(
        call( 'dice_sum', $total ),
        method  => 'rejection',
        samples => 6000,
        seed    => 42,
    );

    isa_ok( $dist, 'Logic::Probabilistic::Distribution' );
    is( $dist->method, 'rejection', 'Method is rejection' );
    ok( abs( $dist->mean - 7.0 ) < 0.2,
        'Rejection sample mean is close to 7.0 (' . $dist->mean . ')' );
    is( $dist->total_samples, 6000, '6000 samples drawn' );
};

subtest 'MCMC sampling distribution' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pchoice( 'die1', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );
    $prog->pchoice( 'die2', [ map { [ 1 / 6, $_ ] } 1 .. 6 ] );

    my $d1    = variable('D1');
    my $d2    = variable('D2');
    my $total = variable('Total');

    $prog->rule(
        head => call( 'dice_sum', $total ),
        body => all(
            call( 'die1', $d1 ),
            call( 'die2', $d2 ),
            is_goal( $total, [ $d1, $d2 ], sub ( $a, $b ) { $a + $b } ),
        ),
    );

    my $dist = $prog->query_distribution(
        call( 'dice_sum', $total ),
        method  => 'mcmc',
        chains  => 2,
        samples => 4000,
        burn_in => 200,
        lag     => 3,
        seed    => 123,
    );

    isa_ok( $dist, 'Logic::Probabilistic::Distribution' );
    is( $dist->method, 'mcmc', 'Method is mcmc' );
    ok( abs( $dist->mean - 7.0 ) < 0.3,
        'MCMC sample mean is close to 7.0 (' . $dist->mean . ')' );
};

subtest 'Smart Outcome objects and raw data structure access' => sub {
    my %probs = (
        '[Alice, 100]' => 0.6,
        '[Bob, 200]'   => 0.4,
    );
    my %val_map = (
        '[Alice, 100]' => [ 'Alice', 100 ],
        '[Bob, 200]'   => [ 'Bob',   200 ],
    );

    my $dist = Logic::Probabilistic::Distribution->new(
        probabilities => \%probs,
        val_map       => \%val_map,
        method        => 'exact',
    );

    # 1. raw / object lookups
    is_deeply( $dist->raw('[Alice, 100]'), [ 'Alice', 100 ], 'dist->raw(key)' );
    is_deeply(
        $dist->object('[Bob, 200]'),
        [ 'Bob', 200 ],
        'dist->object(key)'
    );
    is_deeply(
        [ $dist->objects ],
        [ [ 'Alice', 100 ], [ 'Bob', 200 ] ],
        'dist->objects returns raw structures'
    );

    # 2. Rich Outcome objects
    my @outcomes = $dist->outcomes;
    is( scalar(@outcomes), 2, '2 outcomes returned' );

    my $o1 = $outcomes[0];
    isa_ok( $o1, 'Logic::Probabilistic::Distribution::Outcome' );

    # Stringification
    is( "$o1", '[Alice, 100]', 'Outcome stringifies to key' );

    # Transparent array dereferencing
    is( $o1->[0], 'Alice', '$outcome->[0] is Alice' );
    is( $o1->[1], 100,     '$outcome->[1] is 100' );

    # Methods
    is( $o1->probability, 0.6,  '$outcome->probability is 0.6' );
    is( $o1->pct,         60.0, '$outcome->pct is 60.0' );
    is_deeply( $o1->raw, [ 'Alice', 100 ], '$outcome->raw is original array' );

    # Probability lookup accepting Outcome object
    is( $dist->probability($o1),
        0.6, 'dist->probability accepts Outcome object' );

    # Hash raw structure transparent dereferencing
    my $hash_dist = Logic::Probabilistic::Distribution->new(
        probabilities => { 'user_profile' => 1.0 },
        val_map       => { 'user_profile' => { user => 'Bob', score => 42 } },
        method        => 'exact',
    );
    my ($hash_outcome) = $hash_dist->outcomes;
    is( $hash_outcome->{user},  'Bob', '$outcome->{user} via %{} dereference' );
    is( $hash_outcome->{score}, 42, '$outcome->{score} via %{} dereference' );
    is( $hash_outcome->value->{user},
        'Bob', '$outcome->value returns raw hash' );

    # Error handling when dereferencing mismatched types
    my $caught_hash_err = 0;
    try {
        my $val = $o1->{field};
    }
    catch ($e) {
        $caught_hash_err = 1;
    }
    ok( $caught_hash_err, 'Cannot dereference array outcome as HASH' );

    my $caught_arr_err = 0;
    try {
        my $val = $hash_outcome->[0];
    }
    catch ($e) {
        $caught_arr_err = 1;
    }
    ok( $caught_arr_err, 'Cannot dereference hash outcome as ARRAY' );

    # Numeric conversion on Outcome
    my $num_dist = Logic::Probabilistic::Distribution->new(
        probabilities => { 42 => 1.0 },
        method        => 'exact',
    );
    my ($num_outcome) = $num_dist->outcomes;
    is( 0 + $num_outcome, 42, '0 + $outcome evaluates numerically' );
};

done_testing();
