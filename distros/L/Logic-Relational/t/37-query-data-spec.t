#!/usr/bin/env perl

use v5.38;
use feature 'try';
no warnings 'experimental::try';

use lib ('../lib', 'lib');
use Test2::V0 '!call';

use Logic::Relational::Program ();
use Logic::Relational::Syntax;

# -----------------------------------------------------------------------------
# 1. Basic Conjunctive Queries & Projection
# -----------------------------------------------------------------------------
logic FamilyKB {
    fact parent('Alice',   'Bob');
    fact parent('Alice',   'Charlie');
    fact parent('Bob',     'Diana');
    fact parent('Bob',     'Edward');
    fact parent('Charlie', 'Fiona');

    fact gender('Alice',   'female');
    fact gender('Bob',     'male');
    fact gender('Charlie', 'male');
    fact gender('Diana',   'female');
    fact gender('Edward',  'male');
    fact gender('Fiona',   'female');

    rule grandparent($g, $c) {
        fresh my $p;
        parent($g, $p);
        parent($p, $c);
    }
}

subtest 'Positive conjunctive query with projection' => sub {
    my $prog = FamilyKB->program;

    my $res = $prog->query_data(
        {
            goals  => [{ pred => 'parent', args => ['Alice', '$child'] }],
            select => ['$child'],
        }
    );

    ok($res->{ok}, 'Query succeeded');
    is($res->{matched},   1,                 'Matched is true');
    is($res->{count},     2,                 'Found 2 children');
    is($res->{truncated}, JSON::PP::false(), 'Not truncated');
    is($res->{results}, [{ child => 'Bob' }, { child => 'Charlie' }],
        'Correct variable projection');
    ok(exists $res->{audit}{steps},         'Audit contains steps');
    ok(exists $res->{audit}{elapsed_ms},    'Audit contains elapsed_ms');
    ok(exists $res->{audit}{planned_goals}, 'Audit contains planned_goals');
};

subtest 'Multi-goal conjunction and variable join' => sub {
    my $res = FamilyKB->query_data(
        {
            goals => [
                { pred => 'parent', args => ['Alice',  '$child'] },
                { pred => 'gender', args => ['$child', 'female'] },
            ],
            select => ['$child'],
        }
    );

    ok($res->{ok}, 'Query succeeded');
    is($res->{count},   0,  'Alice has no female children');
    is($res->{matched}, 0,  'Matched is 0');
    is($res->{results}, [], 'Empty results array');

    my $res2 = FamilyKB->query_data(
        {
            goals => [
                { pred => 'parent', args => ['Alice',  '$child'] },
                { pred => 'gender', args => ['$child', 'male'] },
            ],
            select => ['$child'],
        }
    );

    is($res2->{count}, 2, 'Alice has 2 male children');
    is(
        $res2->{results},
        [{ child => 'Bob' }, { child => 'Charlie' }],
        'Bob and Charlie are male children'
    );
};

subtest 'Omission of select projects all positive variables' => sub {
    my $res = FamilyKB->query_data(
        {
            goals => [{ pred => 'grandparent', args => ['Alice', '$grandchild'] }],
        }
    );

    ok($res->{ok}, 'Query succeeded');
    is($res->{count}, 3, 'Found 3 grandchildren');
    is(
        $res->{results},
        [{ grandchild => 'Diana' }, { grandchild => 'Edward' }, { grandchild => 'Fiona' },],
        'All grandchildren projected'
    );
};

subtest 'Anonymous wildcards ($_) in arguments' => sub {
    my $res = FamilyKB->query_data(
        {
            goals => [{ pred => 'parent', args => ['$_', 'Diana'] }],
        }
    );

    ok($res->{ok}, 'Query with wildcard succeeds');
    is($res->{matched}, 1, 'Match found');

    # Anonymous wildcard is not projected
    is($res->{results}, [{}], 'Anonymous wildcard yields empty projected row');
};

# -----------------------------------------------------------------------------
# 2. query_json String Interface & JSON Round-trip
# -----------------------------------------------------------------------------
subtest 'query_json string interface' => sub {
    my $json_in = <<'JSON';
{
  "goals": [
    { "pred": "parent", "args": ["Bob", "$child"] },
    { "pred": "gender", "args": ["$child", "$g"] }
  ],
  "select": ["$child", "$g"]
}
JSON

    my $json_out = FamilyKB->query_json($json_in, pretty => 1);
    ok(defined $json_out, 'query_json produced output');

    my $decoded = JSON::PP->new->utf8->decode($json_out);
    is($decoded->{ok},    1, 'JSON query succeeded');
    is($decoded->{count}, 2, 'Found 2 children of Bob');
    is(
        $decoded->{results},
        [{ child => 'Diana', g => 'female' }, { child => 'Edward', g => 'male' },],
        'Correct JSON results with multiple selected variables'
    );
};

# -----------------------------------------------------------------------------
# 3. Validation and Error Handling
# -----------------------------------------------------------------------------
subtest 'Validation error reporting' => sub {
    my $prog = FamilyKB->program;

    # Not a hash
    my $r1 = $prog->query_data('not a hash');
    is($r1->{ok},         0,              'Non-hash rejected');
    is($r1->{error_code}, 'INVALID_SPEC', 'INVALID_SPEC on non-hash');

    # Empty goals
    my $r2 = $prog->query_data({ goals => [] });
    is($r2->{ok},         0,              'Empty goals rejected');
    is($r2->{error_code}, 'INVALID_SPEC', 'INVALID_SPEC on empty goals');

    # Unknown predicate
    my $r3 = $prog->query_data(
        {
            goals => [{ pred => 'unknown_relation', args => ['X'] }]
        }
    );
    is($r3->{ok},         0,                   'Unknown predicate rejected');
    is($r3->{error_code}, 'UNKNOWN_PREDICATE', 'UNKNOWN_PREDICATE code');

    # Arity mismatch
    my $r4 = $prog->query_data(
        {
            goals => [{ pred => 'parent', args => ['Alice', 'Bob', 'Extra'] }]
        }
    );
    is($r4->{ok},         0,                'Arity mismatch rejected');
    is($r4->{error_code}, 'ARITY_MISMATCH', 'ARITY_MISMATCH code');

    # Invalid select variable
    my $r5 = $prog->query_data(
        {
            goals  => [{ pred => 'parent', args => ['Alice', '$child'] }],
            select => ['$nonexistent'],
        }
    );
    is($r5->{ok},         0,              'Nonexistent select var rejected');
    is($r5->{error_code}, 'INVALID_SPEC', 'INVALID_SPEC code');

    # Invalid JSON string
    my $r6 = $prog->query_json('{ invalid json ...');
    my $d6 = JSON::PP->new->utf8->decode($r6);
    is($d6->{ok},         0,              'Invalid JSON caught');
    is($d6->{error_code}, 'INVALID_JSON', 'INVALID_JSON error code');
};

done_testing();
