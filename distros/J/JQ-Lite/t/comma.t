use strict;
use warnings;
use Test::More tests => 11;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $simple_json = '{"a":1,"b":2}';
my @simple = $jq->run_query($simple_json, '.a, .b');
is_deeply(\@simple, [1, 2], 'comma emits multiple top-level values');

my $users_json = '[{"name":"Alice","age":30},{"name":"Bob","age":25}]';
my @flat = $jq->run_query($users_json, '.[] | (.name, .age)');
is_deeply(\@flat, ['Alice', 30, 'Bob', 25], 'comma branches run against identical inputs in pipelines');

my @arrays = $jq->run_query($users_json, '.[] | [.name, .age], ["extra"]');
is_deeply(\@arrays,
    [
        ['Alice', 30],
        ['extra'],
        ['Bob', 25],
        ['extra'],
    ],
    'comma preserves evaluation order for each input');

my @prefixed = $jq->run_query($users_json, '(["name","age"]), (.[] | [.name, .age])');
is_deeply(
    \@prefixed,
    [
        ['name', 'age'],
        ['Alice', 30],
        ['Bob', 25],
    ],
    'parenthesised literal branches evaluate in full before subsequent branches'
);

my @fallback = $jq->run_query('{}', '(.missing), 1');
is_deeply(\@fallback, [1], 'comma skips branches that produce no output');

my @chain = $jq->run_query('null', '1, 2, 3');
is_deeply(\@chain, [1, 2, 3], 'comma is left-associative and preserves order');

my @empty_then = $jq->run_query('{}', 'empty, 1');
is_deeply(\@empty_then, [1], 'empty emits nothing before subsequent branches run');

my @optional = $jq->run_query('{"foo":0}', '.foo?, 1');
is_deeply(\@optional, [0, 1], 'optional lookup may yield zero or one result before the next branch');

my @array_seq = $jq->run_query('{"a":1,"b":2}', '[(.a, .b)]');
is_deeply(\@array_seq, [[1, 2]], 'sequence inside array literal collects all branch results for the element');

my @paren = $jq->run_query('[1,2]', '( .[] ), 3');
is_deeply(\@paren, [1, 2, 3], 'parenthesised sequence composes with subsequent branches');

my @trailing_empty = $jq->run_query('null', '1, empty');
is_deeply(\@trailing_empty, [1], 'empty trailing branch does not add results');

