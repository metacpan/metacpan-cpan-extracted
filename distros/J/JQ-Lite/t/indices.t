use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "tags": ["perl", "json", "perl", "cli"],
  "phrase": "banana",
  "users": [
    {"name": "Alice"},
    {"name": "Bob"},
    {"name": "Alice"}
  ],
  "numbers": [1, 2, 3, 2, 1],
  "mixed": [true, false, true],
  "items": [1, null, 2, null]
});

my $jq = JQ::Lite->new;

my @tag_indices = $jq->run_query($json, '.tags | indices("perl")');
is_deeply($tag_indices[0], [0, 2], 'indices() finds all matching array positions');

my @user_indices = $jq->run_query($json, '.users | indices({"name":"Alice"})');
is_deeply($user_indices[0], [0, 2], 'indices() performs deep comparisons for arrays of hashes');

my @number_indices = $jq->run_query($json, '.numbers | indices(2)');
is_deeply($number_indices[0], [1, 3], 'indices() handles numeric comparisons');

my @bool_indices = $jq->run_query($json, '.mixed | indices(true)');
is_deeply($bool_indices[0], [0, 2], 'indices() works with JSON::PP::Boolean values');

my @null_indices = $jq->run_query($json, '.items | indices(null)');
is_deeply($null_indices[0], [1, 3], 'indices() treats null as undef when scanning arrays');

my @string_indices = $jq->run_query($json, '.phrase | indices("an")');
is_deeply($string_indices[0], [1, 3], 'indices() lists every substring occurrence');

my @empty_fragment = $jq->run_query($json, '.phrase | indices("")');
is_deeply($empty_fragment[0], [0, 1, 2, 3, 4, 5, 6], 'indices("") returns every string boundary');

my @no_match = $jq->run_query($json, '.tags | indices("python")');
is_deeply($no_match[0], [], 'indices() returns an empty array when no matches exist');

my @undef_string = $jq->run_query($json, '.phrase | indices(null)');
is_deeply($undef_string[0], [], 'string searches with null yield an empty array');

done_testing;
