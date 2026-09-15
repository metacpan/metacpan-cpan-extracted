use strict;
use warnings;

use Test::More;
use JQ::Lite;
use JSON::PP ();

my $jq = JQ::Lite->new;

sub result_for {
    my ($json, $query) = @_;
    my @results = $jq->run_query($json, $query);
    return $results[0];
}

sub results_for {
    my ($json, $query) = @_;
    return [$jq->run_query($json, $query)];
}

subtest 'preserved 2.x compatibility semantics' => sub {
    ok(
        !result_for('[1,2,3]', 'contains([1,3])'),
        'contains does not treat its array argument as a jq-style subset',
    );

    ok(
        !result_for(
            '{"a":{"b":1,"c":2}}',
            'contains({"a":{"b":1}})',
        ),
        'contains requires equality for nested object values',
    );

    ok(
        !result_for('false', '. // 9'),
        'alternative preserves false instead of selecting its fallback',
    );

    is_deeply(
        result_for('[[1,2],[3]]', 'transpose'),
        [[1, 3]],
        'transpose truncates jagged matrices to their shortest row',
    );
};

subtest 'permissive and vectorised semantics' => sub {
    is(
        result_for('"1e3"', '. * 1'),
        1000,
        'multiplication numerically coerces a numeric-looking string',
    );

    is(
        result_for('true', '. + 1'),
        2,
        'addition numerically coerces a boolean',
    );

    is_deeply(
        result_for('[1.2,"2.8","x"]', 'floor'),
        [1, 2, 'x'],
        'floor vectorises and passes non-numeric values through',
    );

    is_deeply(
        result_for('["1","true","bad"]', 'fromjson'),
        [1, JSON::PP::true, 'bad'],
        'fromjson vectorises and passes invalid JSON text through',
    );

    my $match = result_for('42', 'match("2")');
    is(ref($match), 'HASH', 'match accepts a non-string scalar');
    is($match->{string}, '2', 'match uses the scalar string representation');
    is($match->{offset}, 1, 'match reports the coerced-string offset');
};

subtest 'contains_subset extension limitations' => sub {
    ok(
        result_for('[1,2,3]', 'contains_subset([1,3])'),
        'contains_subset supports distinct same-type subset values',
    );
    ok(
        !result_for('[1]', 'contains_subset([1,1])'),
        'duplicate needles require distinct matches, unlike jq contains',
    );
    ok(
        result_for('["1"]', 'contains_subset([1])'),
        'scalar subset comparison coerces types, unlike jq contains',
    );
};

subtest 'comparison semantics' => sub {
    ok(result_for('{}', '"10" == 10'), 'numeric string equals number');
    ok(result_for('{}', 'false < 0'), 'cross-type ordering matches jq here');
    ok(!result_for('{}', '[1,2] < [1,3]'), 'arrays are not ordered lexicographically');
    ok(result_for('{}', '.missing == null'), 'missing compares equal to null');
};

subtest 'null, missing, and path semantics' => sub {
    is_deeply(results_for('{}', '.missing'), [], 'missing field emits no result');
    is_deeply(results_for('{}', '.missing.value'), [], 'path through missing field emits no result');
    is_deeply(results_for('{"a":[]}', '.a.value'), [], 'field access through array emits no result');
    is_deeply(results_for('{}', '.[5]'), [undef], 'numeric object index emits null');
};

subtest 'iterator and pipeline semantics' => sub {
    is_deeply(
        results_for('[{"x":1},{"x":2}]', '.x'),
        [1, 2],
        'field access projects through array values',
    );
    is_deeply(
        results_for('{"a":[{"x":1}],"n":3}', '.[] | .x'),
        [1],
        'pipeline projection traverses nested array and drops missing scalar field',
    );
    is_deeply(results_for('{"b":2,"a":1}', 'keys[]'), ['a', 'b'], 'iterator suffix is stable');
    is_deeply(results_for('null', '0, [4,5][]'), [0, 4, 5], 'comma branches survive iterator suffix');
};

subtest 'assignment and update semantics' => sub {
    is_deeply(result_for('{"a":1}', '.a = 2'), {a => 2}, 'plain assignment emits updated root');
    is_deeply(results_for('{"a":1}', '.a |= . + 1'), [2], 'update assignment emits updated value');
    is_deeply(results_for('{"a":1}', '.missing |= . + 1'), [], 'missing update target emits no result');
    is_deeply(results_for('{"a":0}', '.a = (1,2)'), [], 'multi-result assignment emits no result');
};

subtest 'unsupported jq syntax remains non-functional' => sub {
    is_deeply(
        results_for('1', 'def inc: . + 1; inc'),
        [undef],
        'user-defined jq function syntax currently evaluates to null',
    );
};

done_testing;
