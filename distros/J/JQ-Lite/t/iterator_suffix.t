use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = '{"b":2,"a":1}';

my @keys_suffix = $jq->run_query($json, 'keys[]');
my @keys_pipe   = $jq->run_query($json, 'keys | .[]');
is_deeply(\@keys_suffix, \@keys_pipe, 'keys[] matches keys | .[]');
is_deeply(\@keys_suffix, ['a', 'b'], 'keys[] returns each sorted key');

my @entries_suffix = $jq->run_query($json, 'to_entries[]');
my @entries_pipe   = $jq->run_query($json, 'to_entries | .[]');
is_deeply(\@entries_suffix, \@entries_pipe, 'to_entries[] matches to_entries | .[]');
is_deeply(
    \@entries_suffix,
    [
        { key => 'a', value => 1 },
        { key => 'b', value => 2 },
    ],
    'to_entries[] returns each entry rather than a shared empty result'
);

my @spaced_suffix = $jq->run_query($json, 'keys []');
is_deeply(\@spaced_suffix, ['a', 'b'], 'iterator suffix permits whitespace');

my @function_suffix = $jq->run_query('"red,green,blue"', 'split(",")[]');
is_deeply(
    \@function_suffix,
    ['red', 'green', 'blue'],
    'iterator suffix applies to any array-producing function'
);

my @constructor_suffix = $jq->run_query($json, '[.a, .b][]');
is_deeply(
    \@constructor_suffix,
    [1, 2],
    'iterator suffix applies to an array constructor'
);

my @comma_path_suffix = $jq->run_query('[4,5]', '0, .[]');
is_deeply(
    \@comma_path_suffix,
    [0, 4, 5],
    'a trailing path iterator does not consume an earlier comma result'
);

my @comma_object_suffix = $jq->run_query('[4,5]', '{"kept":true}, .[]');
is_deeply(
    \@comma_object_suffix,
    [{ kept => JSON::PP::true }, 4, 5],
    'a trailing path iterator preserves an earlier object-valued branch'
);

my @comma_constructor_suffix = $jq->run_query('null', '0, [4,5][]');
is_deeply(
    \@comma_constructor_suffix,
    [0, 4, 5],
    'a non-path iterator suffix applies only to its comma branch'
);

my $users = '{"users":[{"name":"Alice"},{"name":"Bob"}]}';
my @path_results = $jq->run_query($users, '.users[] | .name');
is_deeply(\@path_results, ['Alice', 'Bob'], 'existing path iteration remains unchanged');

my $builtin_named_fields = '{"keys":["x","y"],"to_entries":[1,2]}';
my @dotted_keys = $jq->run_query($builtin_named_fields, '.keys[]');
is_deeply(\@dotted_keys, ['x', 'y'], '.keys[] remains dotted field traversal');

my @dotted_to_entries = $jq->run_query($builtin_named_fields, '.to_entries[]');
is_deeply(\@dotted_to_entries, [1, 2], '.to_entries[] remains dotted field traversal');

done_testing();
