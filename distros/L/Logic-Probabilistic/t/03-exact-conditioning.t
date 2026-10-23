use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all not_goal);

subtest 'Bayes Rule: Medical Diagnosis' => sub {
    my $prog = Logic::Probabilistic->new;

    # Prior: 1% population has disease
    $prog->pfact( 0.01, 'disease' );

    # Likelihoods:
    # 90% true positive rate
    $prog->pfact( 0.90, 'test_triggers_if_sick' );

    # 5% false positive rate
    $prog->pfact( 0.05, 'test_triggers_if_healthy' );

    # Rules for positive test
    # positive_test :- disease, test_triggers_if_sick.
    $prog->rule(
        head => call('positive_test'),
        body => all( call('disease'), call('test_triggers_if_sick') ),
    );

    # positive_test :- not(disease), test_triggers_if_healthy.
    $prog->rule(
        head => call('positive_test'),
        body =>
          all( not_goal( call('disease') ), call('test_triggers_if_healthy') ),
    );

    # P(positive_test) = 0.01 * 0.90 + 0.99 * 0.05 = 0.009 + 0.0495 = 0.0585
    my $res_test = $prog->query('positive_test');
    ok( abs( $res_test->probability - 0.0585 ) < 1e-6,
        'P(positive_test) == 0.0585' );

   # Posterior: P(disease | positive_test) = 0.009 / 0.0585 = 2 / 13 ~= 0.153846
    my $res_post = $prog->query( 'disease', evidence => ['positive_test'] );

    my $expected = 0.009 / 0.0585;
    ok(
        abs( $res_post->probability - $expected ) < 1e-6,
        'P(disease | positive_test) == 2/13 (~15.38%)'
    );
    ok( abs( $res_post->evidence_probability - 0.0585 ) < 1e-6,
        'P(E) recorded correctly' );
};

subtest 'Explaining Away: Earthquake and Burglary Alarm' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pfact( 0.01, 'burglary' );
    $prog->pfact( 0.02, 'earthquake' );

    $prog->pfact( 0.95, 'cause_burglary' );
    $prog->pfact( 0.20, 'cause_earthquake' );

    # alarm :- burglary, cause_burglary.
    $prog->rule(
        head => call('alarm'),
        body => all( call('burglary'), call('cause_burglary') ),
    );

    # alarm :- earthquake, cause_earthquake.
    $prog->rule(
        head => call('alarm'),
        body => all( call('earthquake'), call('cause_earthquake') ),
    );

    # 1. P(burglary | alarm)
    my $res_b_given_a = $prog->query( 'burglary', evidence => ['alarm'] );

    # 2. P(burglary | alarm, earthquake)
    my $res_b_given_ae =
      $prog->query( 'burglary', evidence => [ 'alarm', 'earthquake' ] );

    # Burglary probability should be substantially higher given alarm alone,
    # but drops once earthquake explains the alarm!
    cmp_ok(
        $res_b_given_a->probability,
        '>',
        $res_b_given_ae->probability,
        'Explaining away observed: P(B|Alarm) > P(B|Alarm, Earthquake)'
    );
};

subtest 'Zero probability evidence throws exception' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.5, 'rain' );
    $prog->pfact( 0.0, 'impossible_fact' );

    my $err;
    try {
        $prog->query( 'rain', evidence => ['impossible_fact'] );
    }
    catch ($e) {
        $err = $e;
    }

    ok( $err, 'throws error on impossible evidence' );
    like( $err, qr/Zero probability evidence/, 'error message is descriptive' );
};

done_testing();
