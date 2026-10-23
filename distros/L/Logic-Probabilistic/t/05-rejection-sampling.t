use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all not_goal variable);

subtest 'Unconditional Monte Carlo: Biased Coin' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.70, 'heads' );

    my $res = $prog->query(
        'heads',
        method  => 'rejection',
        samples => 4000,
        seed    => 42,
    );

    is( $res->method,           'rejection', 'method is rejection' );
    is( $res->total_samples,    4000,        '4000 total samples drawn' );
    is( $res->accepted_samples, 4000,        '4000 accepted samples' );

    # Analytical value 0.7 should be well within confidence interval
    my ( $low99, $high99 ) = $res->ci(0.99);
    cmp_ok( $res->probability, '>=', $low99,  'prob >= ci_low' );
    cmp_ok( $res->probability, '<=', $high99, 'prob <= ci_high' );
    cmp_ok( 0.70,              '>=', $low99,  'analytical 0.7 >= ci_low(99%)' );
    cmp_ok( 0.70, '<=', $high99, 'analytical 0.7 <= ci_high(99%)' );

    like(
        $res->to_string,
        qr/\A P \s = \s 0\.\d{4} /x,
        'starts with probability'
    );
    like( $res->to_string, qr/\[95% \s CI: /x, 'contains CI' );
    like(
        $res->to_string,
        qr/\(4000 \s samples, \s rejection\)\z/x,
        'ends with method'
    );
};

subtest 'Conditional Monte Carlo: Bayes Medical Diagnosis' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.01, 'disease' );
    $prog->pfact( 0.90, 'test_triggers_if_sick' );
    $prog->pfact( 0.05, 'test_triggers_if_healthy' );

    $prog->rule(
        head => call('positive_test'),
        body => all( call('disease'), call('test_triggers_if_sick') ),
    );

    $prog->rule(
        head => call('positive_test'),
        body =>
          all( not_goal( call('disease') ), call('test_triggers_if_healthy') ),
    );

    # Exact is 2/13 ~= 0.153846
    my $exact = 2.0 / 13.0;

    my $res = $prog->query(
        'disease',
        evidence => ['positive_test'],
        method   => 'rejection',
        samples  => 10_000,
        seed     => 12345,
    );

    # Evidence probability P(E) ~= 0.0585
    ok(
        abs( $res->evidence_probability - 0.0585 ) < 0.015,
        'Estimated P(positive_test) is close to 0.0585'
    );

    cmp_ok( $res->accepted_samples, '>', 450,
        'enough accepted samples gathered' );

    # Analytical 2/13 should be inside 99% CI of accepted samples
    my ( $low, $high ) = $res->ci(0.99);
    cmp_ok( $exact, '>=', $low,  'exact 2/13 is within 99% CI lower bound' );
    cmp_ok( $exact, '<=', $high, 'exact 2/13 is within 99% CI upper bound' );
};

subtest 'Monte Carlo Relational: Network Reliability' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.6, 'edge', 'a', 'b' );
    $prog->pfact( 0.7, 'edge', 'b', 'c' );
    $prog->pfact( 0.5, 'edge', 'a', 'c' );

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

    # Analytical exact is 0.71
    my $res = $prog->query(
        [ 'path', 'a', 'c' ],
        method  => 'rejection',
        samples => 5000,
        seed    => 999,
    );

    my ( $low, $high ) = $res->ci(0.99);
    cmp_ok( 0.71, '>=', $low,  'exact 0.71 within 99% CI lower bound' );
    cmp_ok( 0.71, '<=', $high, 'exact 0.71 within 99% CI upper bound' );
};

subtest 'Target Accepted Mode' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.2, 'rare_event' );
    $prog->pfact( 0.8, 'outcome' );

    my $res = $prog->query(
        'outcome',
        evidence        => ['rare_event'],
        method          => 'rejection',
        target_accepted => 1,
        samples         => 200,              # Target 200 accepted samples
        seed            => 777,
    );

    is( $res->accepted_samples, 200, 'gathered exactly 200 accepted samples' );
    cmp_ok( $res->total_samples, '>', 200,
        'total draws exceeded accepted samples' );
};

subtest 'Impossible evidence throws exception' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.5, 'heads' );
    $prog->pfact( 0.0, 'impossible_fact' );

    my $err;
    try {
        $prog->query(
            'heads',
            evidence     => ['impossible_fact'],
            method       => 'rejection',
            samples      => 100,
            max_attempts => 100,
        );
    }
    catch ($e) {
        $err = $e;
    }

    ok( $err, 'throws error when evidence is never satisfied' );
    like(
        $err,
        qr/No samples satisfied the evidence/,
        'error message is descriptive'
    );
};

done_testing();
