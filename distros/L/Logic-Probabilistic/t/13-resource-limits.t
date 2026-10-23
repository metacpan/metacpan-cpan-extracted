use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use Test::More;
use Logic::Probabilistic;
use Logic::Probabilistic::Syntax;

subtest 'Default max_worlds (4096) and croak message' => sub {
    my $prog = Logic::Probabilistic->new;

    # 13 binary pfacts = 2^13 = 8192 worlds (> 4096)
    for my $i ( 1 .. 13 ) {
        $prog->pfact( 0.5, "f$i" );
    }

    my $caught_err = '';
    try {
        $prog->query('f1');
    }
    catch ($e) {
        $caught_err = "$e";
    }

    ok( $caught_err, 'Threw error when exceeding default max_worlds' );
    like(
        $caught_err,
        qr/Model\s+has\s+8192\s+possible\s+worlds/x,
        'Error mentions 8192 worlds and 4096 limit'
    );
    like(
        $caught_err,
        qr/specify\s+'max_worlds\s+=>\s+8192'/x,
        'Error advises how to override max_worlds'
    );
    like(
        $caught_err,
        qr/Monte\s+Carlo\s+sampling/x,
        'Error suggests Monte Carlo sampling'
    );
};

subtest 'Per-query max_worlds override' => sub {
    my $prog = Logic::Probabilistic->new;

    for my $i ( 1 .. 13 ) {
        $prog->pfact( 0.5, "f$i" );
    }

    # Override on query allows execution
    my $res;
    try {
        $res = $prog->query( 'f1', max_worlds => 8192 );
    }
    catch ($e) {
        diag("Error: $e");
    }

    ok( defined $res, 'query with max_worlds => 8192 executed successfully' );
    is( $res->probability, 0.5, 'P(f1) = 0.5' );

    # Override with max_worlds => 0 (unlimited)
    my $res_unlimited;
    try {
        $res_unlimited = $prog->query( 'f1', max_worlds => 0 );
    }
    catch ($e) {
        diag("Error: $e");
    }

    ok( defined $res_unlimited,
        'query with max_worlds => 0 (unlimited) succeeded' );
    is( $res_unlimited->probability, 0.5, 'P(f1) = 0.5' );
};

subtest 'Program-level max_worlds override' => sub {
    my $prog = Logic::Probabilistic->new;

    for my $i ( 1 .. 13 ) {
        $prog->pfact( 0.5, "f$i" );
    }

    $prog->max_worlds(10_000);
    is( $prog->max_worlds, 10_000, 'Getter returns updated max_worlds' );

    my $res;
    try {
        $res = $prog->query('f1');
    }
    catch ($e) {
        diag("Error: $e");
    }

    ok( defined $res,
        'Program-level max_worlds allowed query without per-query flag' );
    is( $res->probability, 0.5, 'P(f1) = 0.5' );
};

subtest 'query_prob and query_dist declarative syntax with max_worlds' => sub {
    prob_logic LargeModel {
        for my $i ( 1 .. 13 ) {
            pfact 0.5 => f($i);
        }
    }

    # Should croak without override
    my $caught = '';
    my $res_fail;
    try {
        query_prob LargeModel::f(1)->$res_fail;
    }
    catch ($e) {
        $caught = "$e";
    }
    like(
        $caught,
        qr/exceeds\s+exact\s+inference\s+limit\s+of\s+4096/x,
        'Syntax queries enforce limit'
    );

    # Succeeds with max_worlds => 8192
    my $res_pass;
    try {
        query_prob LargeModel::f(1), max_worlds => 8192->$res_pass;
    }
    catch ($e) {
        diag("Error: $e");
    }
    ok( defined $res_pass, 'query_prob with max_worlds => 8192 succeeded' );
    is( $res_pass->probability, 0.5, 'P(f(1)) = 0.5' );

    # query_dist with max_worlds
    fresh my $x;
    my $dist;
    try {
        query_dist LargeModel::f($x), max_worlds => 8192->$dist;
    }
    catch ($e) {
        diag("Error: $e");
    }
    ok( defined $dist, 'query_dist with max_worlds => 8192 succeeded' );
};

subtest 'Timeout guard in Rejection and Exact inference' => sub {
    my $prog = Logic::Probabilistic->new;
    for my $i ( 1 .. 10 ) {
        $prog->pfact( 0.5, "coin$i" );
    }

    # Rejection sampling with timeout
    my $res_rej = $prog->query(
        'coin1',
        method  => 'rejection',
        samples => 100,
        timeout => 5,
    );
    ok( defined $res_rej, 'Rejection with generous timeout succeeds normally' );

    # Program level timeout
    $prog->timeout(10);
    is( $prog->timeout, 10, 'Program timeout getter works' );
};

done_testing();
