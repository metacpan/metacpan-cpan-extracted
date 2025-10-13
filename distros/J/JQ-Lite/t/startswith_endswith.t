use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = q({
  "title": "Hello World!",
  "tags": ["perl", "json", "cli"],
  "names": ["Alice", "Bob", "Alfred"],
  "mixed": ["prefix", null, 123, {"key": "value"}]
});

my $jq = JQ::Lite->new;

my @starts_title = $jq->run_query($json, '.title | startswith("Hello")');
ok($starts_title[0], 'startswith() returns true for matching prefix');

my @starts_false = $jq->run_query($json, '.title | startswith("World")');
ok(!$starts_false[0], 'startswith() returns false when prefix does not match');

my @ends_title = $jq->run_query($json, '.title | endswith("World!")');
ok($ends_title[0], 'endswith() returns true for matching suffix');

my @ends_false = $jq->run_query($json, '.title | endswith("Hello")');
ok(!$ends_false[0], 'endswith() returns false when suffix does not match');

my @array_prefix = $jq->run_query($json, '.names | startswith("Al")');
is_deeply(
    $array_prefix[0],
    [JSON::PP::true, JSON::PP::false, JSON::PP::true],
    'startswith() maps over arrays and produces booleans'
);

my @array_suffix = $jq->run_query($json, '.names | endswith("ce")');
is_deeply(
    $array_suffix[0],
    [JSON::PP::true, JSON::PP::false, JSON::PP::false],
    'endswith() maps over arrays and produces booleans'
);

my @mixed_values = $jq->run_query($json, '.mixed | startswith("pre")');
is_deeply(
    $mixed_values[0],
    [JSON::PP::true, JSON::PP::false, JSON::PP::false, JSON::PP::false],
    'non-string values yield JSON false booleans'
);

my @empty_prefix = $jq->run_query($json, '.title | startswith("")');
ok($empty_prefix[0], 'empty prefix always matches');

my @empty_suffix = $jq->run_query($json, '.title | endswith("")');
ok($empty_suffix[0], 'empty suffix always matches');

my @default_chain = $jq->run_query($json, '.missing? | startswith("foo") | default("fallback")');
is($default_chain[0], 'fallback', 'startswith() preserves undef values for default() to handle');

my @array_empty = $jq->run_query($json, '.names | endswith("")');
is_deeply(
    $array_empty[0],
    [JSON::PP::true, JSON::PP::true, JSON::PP::true],
    'empty suffix returns true for every string in array'
);

my @case_sensitive = $jq->run_query($json, '.tags | startswith("P")');
is_deeply(
    $case_sensitive[0],
    [JSON::PP::false, JSON::PP::false, JSON::PP::false],
    'startswith() remains case-sensitive'
);

my @trim_chain = $jq->run_query($json, '.tags | trim | endswith("n")');
is_deeply(
    $trim_chain[0],
    [JSON::PP::false, JSON::PP::true, JSON::PP::false],
    'endswith() composes with other filters like trim()'
);

done_testing;
