use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = q({
  "title": "Hello World",
  "tags": ["perl", "json", "cli"],
  "mixed": ["abc123", null, 42, {"kind": "object"}],
  "multiline": "alpha\nbeta",
  "dots": "a\nb",
  "spaced": "ab"
});

my $jq = JQ::Lite->new;

my @prefix = $jq->run_query($json, '.title | test("^Hello")');
ok($prefix[0], 'test() matches prefix anchored regex');

my @case_sensitive = $jq->run_query($json, '.title | test("world")');
ok(!$case_sensitive[0], 'test() is case-sensitive by default');

my @case_insensitive = $jq->run_query($json, '.title | test("world"; "i")');
ok($case_insensitive[0], 'test() honours case-insensitive flag');

my $invalid_flag_ok = eval { $jq->run_query($json, '.title | test("Hello"; "z")'); 1 };
my $invalid_flag_error = $@;
ok(!$invalid_flag_ok, 'test() dies on unknown regex flags');
like(
    $invalid_flag_error,
    qr/test\(\): invalid regular expression - unknown regex flag 'z'/,
    'test() surfaces unknown regex flags in error message'
);

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

my @multiline_flag = $jq->run_query($json, '.multiline | test("^beta"; "m")');
ok($multiline_flag[0], 'test() honors multiline flag (m) for line anchors');

my @multiline_default = $jq->run_query($json, '.multiline | test("^beta")');
ok(!$multiline_default[0], 'test() defaults to single-line anchors without m');

my @dotall_flag = $jq->run_query($json, '.dots | test("a.*b"; "s")');
ok($dotall_flag[0], 'test() honors dotall flag (s) for newlines');

my @dotall_default = $jq->run_query($json, '.dots | test("a.*b")');
ok(!$dotall_default[0], 'test() defaults to non-dotall behavior without s');

my @extended_flag = $jq->run_query($json, '.spaced | test("a b"; "x")');
ok($extended_flag[0], 'test() honors extended flag (x) for embedded whitespace');

my @extended_default = $jq->run_query($json, '.spaced | test("a b")');
ok(!$extended_default[0], 'test() treats embedded whitespace literally without x');

done_testing;
