#!/usr/bin/env perl

use v5.38;
use feature 'try';
no warnings 'experimental::try';

use lib ('../lib', 'lib');
use Test2::V0 '!call';

use Logic::Relational::Program ();
use Logic::Relational::Syntax;

# -----------------------------------------------------------------------------
# Test KB with duplicate derivation paths and cyclic/recursive relations
# -----------------------------------------------------------------------------
logic SearchKB {

    # Diamond graph: A -> B -> D and A -> C -> D
    fact edge('A', 'B');
    fact edge('A', 'C');
    fact edge('B', 'D');
    fact edge('C', 'D');

    rule reaches($from, $to) {
        edge($from, $to);
    }

    rule reaches($from, $to) {
        fresh my $mid;
        edge($from, $mid);
        reaches($mid, $to);
    }

    # Infinite generator: generates endless numbers
    generator nats(1), sub ($n) {
        my $curr = 0;
        return sub {
            return [$curr++];
        };
    };
}

subtest 'distinct set deduplication vs distinct: false' => sub {

    # Reaching D from A via diamond graph has 2 distinct derivation paths
    my $res_distinct = SearchKB->query_data(
        {
            goals    => [{ pred => 'reaches', args => ['A', '$dest'] }],
            select   => ['$dest'],
            distinct => 1,
        }
    );

    ok($res_distinct->{ok}, 'Query with distinct=1 succeeded');
    is($res_distinct->{count}, 3, 'Found exactly 3 unique destinations: B, C, D');
    is(
        $res_distinct->{results},
        [{ dest => 'B' }, { dest => 'C' }, { dest => 'D' }],
        'Deduplicated results (no duplicate D)'
    );

    # Now with distinct: false
    my $res_bag = SearchKB->query_data(
        {
            goals    => [{ pred => 'reaches', args => ['A', '$dest'] }],
            select   => ['$dest'],
            distinct => 0,
        }
    );

    ok($res_bag->{ok}, 'Query with distinct=0 succeeded');
    is($res_bag->{count}, 4, 'Found 4 rows (D derived twice)');
    is(
        $res_bag->{results},
        [{ dest => 'B' }, { dest => 'C' }, { dest => 'D' }, { dest => 'D' }],
        'Multiset results preserve duplicate D'
    );
};

subtest 'limit constraint and truncated flag' => sub {

    # Limit to 2 results
    my $res = SearchKB->query_data(
        {
            goals  => [{ pred => 'reaches', args => ['A', '$dest'] }],
            select => ['$dest'],
            limit  => 2,
        }
    );

    ok($res->{ok}, 'Query with limit succeeded');
    is($res->{count},     2,                                  'Exactly 2 rows returned');
    is($res->{truncated}, JSON::PP::true(),                   'truncated is true');
    is($res->{results},   [{ dest => 'B' }, { dest => 'C' }], 'First 2 solutions returned');
};

subtest 'max_steps constraint and runaway search prevention' => sub {

    # Query infinite generator with low max_steps limit
    my $res = SearchKB->query_data(
        {
            goals     => [{ pred => 'nats', args => ['$n'] }],
            select    => ['$n'],
            max_steps => 10,
        }
    );

    is($res->{ok},         0,                    'Exceeded max_steps fails gracefully');
    is($res->{error_code}, 'MAX_STEPS_EXCEEDED', 'MAX_STEPS_EXCEEDED error code');
    like($res->{error}, qr/exceeded\s+step\s+limit/ix, 'Error message indicates step limit');
    ok($res->{audit}{steps} >= 10, 'Audit records step count');
};

subtest 'timeout_ms constraint on long-running queries' => sub {

    # Query infinite generator with a very short timeout
    my $res = SearchKB->query_data(
        {
            goals      => [{ pred => 'nats', args => ['$n'] }],
            select     => ['$n'],
            limit      => 1000000,
            max_steps  => 0,                                      # unlimited steps
            timeout_ms => 15,                                     # 15 milliseconds
        }
    );

    is($res->{ok},         0,                  'Timeout triggered');
    is($res->{error_code}, 'TIMEOUT_EXCEEDED', 'TIMEOUT_EXCEEDED error code');
    like($res->{error}, qr/time\s+limit/ix, 'Error message indicates time limit');
    ok(exists $res->{audit}{elapsed_ms}, 'Audit records elapsed time');
};

subtest 'groundness requirements enforcement (UNBOUND_REQUIRED_ARG)' => sub {
    logic MathKB {
        predicate requires_bound => (
            doc             => 'Requires argument 0 to be bound',
            args            => ['input', 'output'],
            ground_required => [0],
        );

        rule requires_bound($in, $out) {
            unify($out, $in);
        }
    }

    # Query with unbound variable at position 0
    my $res = MathKB->query_data(
        {
            goals  => [{ pred => 'requires_bound', args => ['$unbound', '$out'] }],
            select => ['$unbound', '$out'],
        }
    );

    is($res->{ok},         0,                      'Unbound required argument rejected');
    is($res->{error_code}, 'UNBOUND_REQUIRED_ARG', 'UNBOUND_REQUIRED_ARG code');
    like(
        $res->{error},
        qr/requires\s+ground\s+\(bound\)\s+argument/ix,
        'Clear error message for groundness failure'
    );

    # Now supply a constant for argument 0
    my $res_ok = MathKB->query_data(
        {
            goals  => [{ pred => 'requires_bound', args => ['constant_val', '$out'] }],
            select => ['$out'],
        }
    );

    ok($res_ok->{ok}, 'Query succeeds when ground requirement is satisfied');
    is($res_ok->{results}, [{ out => 'constant_val' }], 'Correct result');
};

done_testing();
