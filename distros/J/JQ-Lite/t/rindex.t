use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    {"name": "Alice"},
    {"name": "Bob"},
    {"name": "Alice"}
  ],
  "tags": ["perl", "json", "perl", "cli"],
  "phrase": "banana",
  "flags": [false, true, true],
  "nothing": null
});

my $jq = JQ::Lite->new;

my @object_rindex = $jq->run_query($json, '.users | rindex({"name":"Alice"})');
is(scalar @object_rindex, 1, 'object rindex returns single result');
is($object_rindex[0], 2, 'rindex finds the last matching array element');

my @scalar_rindex = $jq->run_query($json, '.tags | rindex("perl")');
is($scalar_rindex[0], 2, 'rindex on arrays returns last index for repeated values');

my @string_rindex = $jq->run_query($json, '.phrase | rindex("an")');
is($string_rindex[0], 3, 'rindex on strings returns the final substring position');

my @empty_fragment = $jq->run_query($json, '.phrase | rindex("")');
is($empty_fragment[0], 6, 'rindex("") returns the string length, matching jq');

my @bool_rindex = $jq->run_query($json, '.flags | rindex(true)');
is($bool_rindex[0], 2, 'rindex handles JSON::PP::Boolean values correctly');

my @missing = $jq->run_query($json, '.tags | rindex("python")');
ok(!defined $missing[0], 'missing value yields undef (null)');

my @null_haystack = $jq->run_query($json, '.nothing | rindex("an")');
ok(!defined $null_haystack[0], 'null input yields undef (null)');

my @null_needle = $jq->run_query($json, '.phrase | rindex(null)');
ok(!defined $null_needle[0], 'null needle yields undef (null) for strings');

my @null_both = $jq->run_query($json, '.nothing | rindex(null)');
ok(!defined $null_both[0], 'null input and needle yield undef (null)');

done_testing;
