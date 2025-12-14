use strict;
use warnings;

use Test::More;

use JQ::Lite;

my $jq = JQ::Lite->new;

sub run {
    my ($json, $query) = @_;
    return [ $jq->run_query($json, $query) ];
}

my $input = '{"num": 6, "den": 2}';
my $success = run($input, 'try .num / .den');

is_deeply(
    $success,
    [3],
    'try returns expression result when no error occurs'
);

my $fail_json = '{"num": 1, "den": 0}';
my $fallback = run($fail_json, 'try (.num / .den)');

is_deeply(
    $fallback,
    [undef],
    'try falls back to null when an error is thrown'
);

my $pipeline = run('{"a": {"b": 2}}', 'try .a.b | . + 1 catch 0');

is_deeply(
    $pipeline,
    [3],
    'try spans a downstream pipeline segment before catch'
);

my $type_error = run('{"a": {"b": "x"}}', 'try .a.b | . + 1 catch 0');

is_deeply(
    $type_error,
    [0],
    'try catches type errors raised by downstream filters'
);

my $with_catch = run($fail_json, 'try (.num / .den) catch $error');

like(
    $with_catch->[0],
    qr/division by zero/i,
    'catch receives the error message via $error'
);

my $catch_filter = run($fail_json, 'try (.num / .den) catch (.den // 1)');

is_deeply(
    $catch_filter,
    [0],
    'catch expression is evaluated as a filter on the original input'
);

my $multi_value = run('[{"v": 0}, {"v": 2}]', 'map(try (1 /.v) catch 42)');

is_deeply(
    $multi_value,
    [[42, 0.5]],
    'try works inside other filters and propagates catch results'
);

DONE_TESTING:

if ($ENV{AUTOMATED_TESTING}) {
    done_testing();
} else {
    done_testing();
}
