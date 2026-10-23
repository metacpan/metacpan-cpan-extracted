use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic;
use Logic::Relational::DSL qw(call all not_goal variable);

subtest 'Unconditional MCMC: Biased Coin' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.75, 'heads' );

    my $res = $prog->query(
        'heads',
        method  => 'mcmc',
        samples => 3000,
        burn_in => 200,
        lag     => 2,
        seed    => 42,
    );

    is( $res->method,        'mcmc', 'method is mcmc' );
    is( $res->total_samples, 3000,   '3000 samples collected' );

    my ( $low99, $high99 ) = $res->ci(0.99);
    cmp_ok( 0.75, '>=', $low99,  'analytical 0.75 >= ci_low(99%)' );
    cmp_ok( 0.75, '<=', $high99, 'analytical 0.75 <= ci_high(99%)' );
};

subtest 'Conditional MCMC: Medical Diagnosis Inversion' => sub {
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

    # Analytical exact is 2/13 ~= 0.153846
    my $exact = 2.0 / 13.0;

    my $res = $prog->query(
        'disease',
        evidence => ['positive_test'],
        method   => 'mcmc',
        samples  => 5000,
        burn_in  => 1000,
        lag      => 10,
        seed     => 42,
    );

    ok( abs( $res->probability - $exact ) < 0.03,
        'MCMC estimate is within 0.03 of exact 2/13 (~0.1538)' );
    cmp_ok( $res->probability, '>', 0.10, 'estimate > 0.10' );
    cmp_ok( $res->probability, '<', 0.20, 'estimate < 0.20' );
};

subtest 'Rare Evidence Conditioning' => sub {
    my $prog = Logic::Probabilistic->new;

    # Rare event A with prior 0.5% (1 in 200)
    $prog->pfact( 0.005, 'rare_a' );
    $prog->pfact( 0.600, 'feature_b' );

    $prog->pfact( 0.800, 'c_cause_b' );
    $prog->pfact( 0.200, 'c_cause_not_b' );

    # c :- rare_a, feature_b, c_cause_b.
    $prog->rule(
        head => call('outcome_c'),
        body => all( call('rare_a'), call('feature_b'), call('c_cause_b') ),
    );

    # c :- rare_a, not(feature_b), c_cause_not_b.
    $prog->rule(
        head => call('outcome_c'),
        body => all(
            call('rare_a'), not_goal( call('feature_b') ),
            call('c_cause_not_b')
        ),
    );

    # P(outcome_c | rare_a) = 0.60 * 0.80 + 0.40 * 0.20 = 0.48 + 0.08 = 0.56
    my $exact = 0.56;

    my $res = $prog->query(
        'outcome_c',
        evidence => ['rare_a'],
        method   => 'mcmc',
        samples  => 3000,
        burn_in  => 500,
        lag      => 2,
        seed     => 999,
    );

    my ( $low, $high ) = $res->ci(0.99);
    cmp_ok( $exact, '>=', $low,
        'rare-evidence exact 0.56 within 99% CI lower bound' );
    cmp_ok( $exact, '<=', $high,
        'rare-evidence exact 0.56 within 99% CI upper bound' );
};

subtest 'MCMC on Categorical Choices' => sub {
    my $prog = Logic::Probabilistic->new;

    $prog->pchoice( 'spinner',
        [ [ 0.2, 'red' ], [ 0.5, 'green' ], [ 0.3, 'blue' ], ] );

    # Rule: not_red :- spinner(green).
    # Rule: not_red :- spinner(blue).
    $prog->rule( head => call('not_red'), body => call( 'spinner', 'green' ) );
    $prog->rule( head => call('not_red'), body => call( 'spinner', 'blue' ) );

    # Condition on not_red.
    # P(spinner(green) | not_red) = 0.5 / (0.5 + 0.3) = 0.5 / 0.8 = 0.625
    my $exact = 0.625;

    my $res = $prog->query(
        [ 'spinner', 'green' ],
        evidence => ['not_red'],
        method   => 'mcmc',
        samples  => 3000,
        burn_in  => 300,
        lag      => 2,
        seed     => 777,
    );

    my ( $low, $high ) = $res->ci(0.99);
    cmp_ok( $exact, '>=', $low,  'exact 0.625 within 99% CI lower bound' );
    cmp_ok( $exact, '<=', $high, 'exact 0.625 within 99% CI upper bound' );
};

subtest 'MCMC Convergence Diagnostics (Gelman-Rubin & ESS)' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.40, 'event_a' );
    $prog->pfact( 0.50, 'event_b' );
    $prog->rule(
        head => call('cooccur'),
        body => all( call('event_a'), call('event_b') ),
    );

    # Query with 4 chains (default)
    my $res = $prog->query(
        'cooccur',
        method  => 'mcmc',
        chains  => 4,
        samples => 4000,
        burn_in => 200,
        lag     => 2,
        seed    => 1234,
    );

    is( $res->chains, 4, 'ran 4 chains' );
    ok( defined $res->r_hat, 'R-hat diagnostic is defined' );
    cmp_ok( $res->r_hat, '<', 1.05, 'R-hat is below 1.05 (chains converged)' );
    ok( $res->is_converged, 'is_converged is true' );
    cmp_ok( $res->ess, '>', 100, 'Effective Sample Size (ESS) > 100' );
    like( $res->to_string, qr/R-hat\s*=\s*\d+\.\d+/x,
        'to_string contains R-hat' );
    like( $res->to_string, qr/ESS\s*=\s*\d+/x, 'to_string contains ESS' );
    like(
        $res->to_string,
        qr/4\ chains\ x\ 1000\ samples/x,
        'to_string shows chains breakdown'
    );
};

subtest 'Diagnostic Warning on Trapped / Unconverged Chains' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.5, 'dummy' );
    my $mcmc = Logic::Probabilistic::Inference::MCMC->new( program => $prog );

    # Simulate 4 chains trapped in disparate modes
    my @trapped_chains = (
        [ (1) x 800, (0) x 200 ],    # Chain 1 stuck in mode ~ 0.8
        [ (0) x 800, (1) x 200 ],    # Chain 2 stuck in mode ~ 0.2
        [ (1) x 750, (0) x 250 ],    # Chain 3 stuck in mode ~ 0.75
        [ (0) x 850, (1) x 150 ],    # Chain 4 stuck in mode ~ 0.15
    );

    my ( $r_hat, $ess, $means, $warnings ) =
      $mcmc->_calculate_diagnostics( \@trapped_chains, 1900, 4000 );

    cmp_ok( $r_hat, '>', 1.20,
        'R-hat detects strong non-convergence (> 1.20)' );
    ok( scalar(@$warnings) > 0, 'Convergence warning was generated' );
    like(
        $warnings->[0],
        qr/Chain convergence warning/,
        'warning text explains failure'
    );

    my $bad_result = Logic::Probabilistic::Result->new(
        probability      => 0.475,
        method           => 'mcmc',
        total_samples    => 4000,
        accepted_samples => 4000,
        metadata         => {
            chains   => 4,
            r_hat    => $r_hat,
            ess      => $ess,
            warnings => $warnings,
        },
    );

    ok( !$bad_result->is_converged, 'bad result is_converged returns false' );
    like( $bad_result->to_string, qr/WARNING:\s*unconverged/x,
        'to_string displays WARNING badge' );
};

subtest 'Single Chain MCMC' => sub {
    my $prog = Logic::Probabilistic->new;
    $prog->pfact( 0.60, 'coin' );

    my $res = $prog->query(
        'coin',
        method  => 'mcmc',
        chains  => 1,
        samples => 2000,
        burn_in => 100,
        lag     => 2,
        seed    => 42,
    );

    is( $res->chains,        1,    'chains count is 1' );
    is( $res->total_samples, 2000, '2000 samples collected' );
    ok( defined $res->ess,  'ESS is computed for single chain' );
    ok( $res->is_converged, 'single chain default is_converged' );
};

done_testing();
