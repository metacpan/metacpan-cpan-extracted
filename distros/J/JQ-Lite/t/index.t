use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    {"name": "Alice", "age": 30},
    {"name": "Bob", "age": 25},
    {"name": "Carol", "age": 35}
  ],
  "tags": ["perl", "json", "cli"],
  "title": "jq-lite in perl",
  "flags": [true, false, true],
  "nothing": null
});

my $jq = JQ::Lite->new;

my @object_index = $jq->run_query($json, '.users | index({"name":"Bob","age":25})');
is(scalar @object_index, 1, 'object index returns single result');
is($object_index[0], 1, 'object index finds the first matching entry');

my @array_index = $jq->run_query($json, '.tags | index("perl")');
is($array_index[0], 0, 'scalar array search returns zero-based index');

my @string_index = $jq->run_query($json, '.title | index("lite")');
is($string_index[0], 3, 'substring search returns the expected offset');

my @boolean_index = $jq->run_query($json, '.flags | index(true)');
is($boolean_index[0], 0, 'boolean search matches JSON::PP::Boolean values');

my @missing = $jq->run_query($json, '.tags | index("python")');
ok(!defined $missing[0], 'missing values yield undef (null)');

my @null_haystack = $jq->run_query($json, '.nothing | index("perl")');
ok(!defined $null_haystack[0], 'null input yields undef (null)');

my @null_needle = $jq->run_query($json, '.title | index(null)');
ok(!defined $null_needle[0], 'null needle yields undef (null) for strings');

my @null_both = $jq->run_query($json, '.nothing | index(null)');
ok(!defined $null_both[0], 'null input and needle yield undef (null)');

done_testing;
