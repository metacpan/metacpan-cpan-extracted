use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic::PFact;
use Logic::Probabilistic::PChoice;

subtest 'PFact instantiation and validation' => sub {
    my $pf = Logic::Probabilistic::PFact->new(
        probability => 0.75,
        predicate   => 'rain',
        args        => ['today'],
    );

    is( $pf->probability, 0.75,   'probability matches' );
    is( $pf->predicate,   'rain', 'predicate matches' );
    is_deeply( $pf->args, ['today'], 'args match' );
    is( $pf->key, 'rain/1',      'key is rain/1' );
    is( $pf->id,  'rain(today)', 'auto-generated ID matches' );
    ok( $pf->clause, 'clause object created' );

    # Invalid probabilities
    my $err_neg;
    try {
        Logic::Probabilistic::PFact->new(
            probability => -0.1,
            predicate   => 'bad',
        );
    }
    catch ($e) {
        $err_neg = $e;
    }
    ok( $err_neg, 'fails on negative probability' );

    my $err_high;
    try {
        Logic::Probabilistic::PFact->new(
            probability => 1.5,
            predicate   => 'bad',
        );
    }
    catch ($e) {
        $err_high = $e;
    }
    ok( $err_high, 'fails on probability > 1.0' );
};

subtest 'PChoice instantiation and validation' => sub {
    my $choice = Logic::Probabilistic::PChoice->new(
        predicate => 'die',
        args      => ['d1'],
        outcomes  => [
            [ 0.166666, 1 ],
            [ 0.166666, 2 ],
            [ 0.166666, 3 ],
            [ 0.166666, 4 ],
            [ 0.166666, 5 ],
            [ 0.166666, 6 ],
        ],
    );

    is( $choice->predicate, 'die',     'predicate matches' );
    is( $choice->id,        'die(d1)', 'id matches' );
    my @outs = $choice->outcomes;
    is( scalar(@outs),     6, '6 outcomes recorded' );
    is( $outs[0]->{value}, 1, 'first outcome value is 1' );
    is_deeply( $outs[0]->{args}, [ 'd1', 1 ], 'first outcome full args' );
    is( $outs[0]->{key}, 'die/2', 'key is die/2' );

    # Invalid sum > 1
    my $err_sum;
    try {
        Logic::Probabilistic::PChoice->new(
            predicate => 'bad',
            outcomes  => [ [ 0.6, 'a' ], [ 0.6, 'b' ] ],
        );
    }
    catch ($e) {
        $err_sum = $e;
    }
    ok( $err_sum, 'fails when outcome probabilities exceed 1.0' );

    # Partial sum (< 1.0) creates null outcome probability
    my $partial = Logic::Probabilistic::PChoice->new(
        predicate => 'rain_chance',
        outcomes  => [ [ 0.3, 'heavy' ], [ 0.2, 'light' ] ],
    );
    ok( abs( $partial->null_prob - 0.5 ) < 1e-6, 'null probability is 0.5' );
};

done_testing();
