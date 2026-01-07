use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = q({
  "title": "Hello World",
  "tags": ["perl", "json", "cli"],
  "mixed": ["abc123", null, 42, {"kind": "object"}]
});

my $jq = JQ::Lite->new;

my @prefix = $jq->run_query($json, '.title | test("^Hello")');
ok($prefix[0], 'test() matches prefix anchored regex');

my @case_sensitive = $jq->run_query($json, '.title | test("world")');
ok(!$case_sensitive[0], 'test() is case-sensitive by default');

my @case_insensitive = $jq->run_query($json, '.title | test("world"; "i")');
ok($case_insensitive[0], 'test() honours case-insensitive flag');

my @array_map = $jq->run_query($json, '.tags | test("^p")');
is_deeply(
    $array_map[0],
    [JSON::PP::true, JSON::PP::false, JSON::PP::false],
    'test() maps over arrays and returns JSON booleans'
);

my @mixed_values = $jq->run_query($json, '.mixed | test("\\\\d")');
is_deeply(
    $mixed_values[0],
    [JSON::PP::true, JSON::PP::false, JSON::PP::true, JSON::PP::false],
    'test() coerces scalars and treats non-strings as false'
);

my $invalid_ok = eval { $jq->run_query($json, '.title | test("(")'); 1 };
my $invalid_error = $@;
ok(!$invalid_ok, 'test() dies when given an invalid regular expression');
like(
    $invalid_error,
    qr/test\(\): invalid regular expression/, 
    'test() surfaces regex compile errors with a helpful message'
);

my @default_chain = $jq->run_query($json, '.missing? | test("foo") | default("fallback")');
is($default_chain[0], 'fallback', 'test() preserves undef so default() can supply a fallback');

done_testing;
