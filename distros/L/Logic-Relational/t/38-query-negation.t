#!/usr/bin/env perl

use v5.38;
use feature 'try';
no warnings 'experimental::try';

use lib ('../lib', 'lib');
use Test2::V0 '!call';

use Logic::Relational::Program ();
use Logic::Relational::Syntax;

# -----------------------------------------------------------------------------
# Test KB for Negation
# -----------------------------------------------------------------------------
logic HospitalStaff {
    fact employee('Alice');
    fact employee('Bob');
    fact employee('Charlie');
    fact employee('David');

    fact on_leave('Bob');
    fact on_leave('David');

    fact role('Alice',   'doctor');
    fact role('Bob',     'doctor');
    fact role('Charlie', 'nurse');
    fact role('David',   'nurse');
}

subtest 'Negation-as-failure with {"not": {...}} syntax' => sub {

    # Find all employees who are NOT on leave
    my $res = HospitalStaff->query_data(
        {
            goals => [
                { pred => 'employee', args => ['$emp'] },
                { not  => { pred => 'on_leave', args => ['$emp'] } },
            ],
            select => ['$emp'],
        }
    );

    ok($res->{ok}, 'Query succeeded');
    is($res->{count}, 2, 'Found 2 active employees');
    is(
        $res->{results},
        [{ emp => 'Alice' }, { emp => 'Charlie' }],
        'Alice and Charlie are not on leave'
    );
};

subtest 'Inline negation syntax with "negated: true"' => sub {

    # Find active doctors
    my $res = HospitalStaff->query_data(
        {
            goals => [
                { pred => 'role',     args => ['$emp', 'doctor'] },
                { pred => 'on_leave', args => ['$emp'], negated => 1 },
            ],
            select => ['$emp'],
        }
    );

    ok($res->{ok}, 'Inline negated query succeeded');
    is($res->{count},   1,                    'Found 1 active doctor');
    is($res->{results}, [{ emp => 'Alice' }], 'Alice is the only active doctor');
};

subtest 'Goal reordering: negated goal specified before positive goal' => sub {

    # User puts the negated goal first in the query JSON
    my $res = HospitalStaff->query_data(
        {
            goals => [
                { not  => { pred => 'on_leave', args => ['$emp'] } },
                { pred => 'role', args => ['$emp', 'nurse'] },
            ],
            select => ['$emp'],
        }
    );

    ok($res->{ok}, 'Query succeeded despite negated goal listed first');
    is($res->{count},   1,                      'Found 1 active nurse');
    is($res->{results}, [{ emp => 'Charlie' }], 'Charlie is active nurse');

    # Verify execution order in audit
    my $planned = $res->{audit}{planned_goals};
    is(
        $planned,
        ["role(\$emp, 'nurse')", "\\+ on_leave(\$emp)"],
        'Planner reordered positive goal before negated goal'
    );
};

subtest 'Unsafe negation detection: unground free variable in negated goal' => sub {

    # Query with free variable in negated goal that is never bound positively
    my $res = HospitalStaff->query_data(
        {
            goals  => [{ not => { pred => 'on_leave', args => ['$unbound_var'] } }],
            select => ['$unbound_var'],
        }
    );

    is($res->{ok},         0,                 'Unsafe negation rejected');
    is($res->{error_code}, 'UNSAFE_NEGATION', 'UNSAFE_NEGATION error code');
    like(
        $res->{error},
        qr/contains unground free variable/i,
        'Informative error message for unground negated variable'
    );
};

subtest 'Negation with multiple variables' => sub {
    logic PairKB {
        fact pair(1, 2);
        fact pair(1, 3);
        fact pair(2, 4);

        fact blocked(1, 3);
    }

    my $res = PairKB->query_data(
        {
            goals => [
                { pred => 'pair',    args => ['$x', '$y'] },
                { pred => 'blocked', args => ['$x', '$y'], negated => 1 },
            ],
            select => ['$x', '$y'],
        }
    );

    ok($res->{ok}, 'Query succeeded');
    is($res->{count}, 2, '2 unblocked pairs');
    is(
        $res->{results},
        [{ x => 1, y => 2 }, { x => 2, y => 4 }],
        'Correct pairs after multi-variable negation'
    );
};

done_testing();
