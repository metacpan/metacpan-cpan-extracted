use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "value": "foobar",
  "short": "bar",
  "exact": "foo",
  "blank": "",
  "array": ["foobar", "barfoo", null, ["foo", "foobar"]],
  "object": {"keep": "foobar"}
});

my $jq = JQ::Lite->new;

my @left = $jq->run_query($json, '.value | ltrimstr("foo")');
is($left[0], 'bar', 'ltrimstr removes matching prefix from scalar string');

my @left_no_match = $jq->run_query($json, '.value | ltrimstr("bar")');
is($left_no_match[0], 'foobar', 'ltrimstr leaves non-matching prefix untouched');

my @right = $jq->run_query($json, '.value | rtrimstr("bar")');
is($right[0], 'foo', 'rtrimstr removes matching suffix from scalar string');

my @left_empty = $jq->run_query($json, '.value | ltrimstr("")');
is($left_empty[0], 'foobar', 'ltrimstr with empty needle leaves string unchanged');

my @right_empty = $jq->run_query($json, '.value | rtrimstr("")');
is($right_empty[0], 'foobar', 'rtrimstr with empty needle leaves string unchanged');

my @left_too_long = $jq->run_query($json, '.short | ltrimstr("foobar")');
is($left_too_long[0], 'bar', 'ltrimstr ignores needles longer than the target');

my @right_too_long = $jq->run_query($json, '.short | rtrimstr("foobar")');
is($right_too_long[0], 'bar', 'rtrimstr ignores needles longer than the target');

my @left_exact = $jq->run_query($json, '.exact | ltrimstr("foo")');
is($left_exact[0], '', 'ltrimstr returns empty string when full value matches');

my @right_exact = $jq->run_query($json, '.exact | rtrimstr("foo")');
is($right_exact[0], '', 'rtrimstr returns empty string when full value matches');

my @blank_left = $jq->run_query($json, '.blank | ltrimstr("foo")');
is($blank_left[0], '', 'ltrimstr leaves empty strings untouched');

my @blank_right = $jq->run_query($json, '.blank | rtrimstr("foo")');
is($blank_right[0], '', 'rtrimstr leaves empty strings untouched');

my @array_left = $jq->run_query($json, '.array | ltrimstr("foo")');
is_deeply(
    $array_left[0],
    ['bar', 'barfoo', undef, ['', 'bar']],
    'ltrimstr recurses into arrays and nested arrays'
);

my @array_right = $jq->run_query($json, '.array | rtrimstr("bar")');
is_deeply(
    $array_right[0],
    ['foo', 'barfoo', undef, ['foo', 'foo']],
    'rtrimstr recurses into arrays and nested arrays'
);

my @object = $jq->run_query($json, '.object | ltrimstr("foo")');
is_deeply($object[0], { keep => 'foobar' }, 'ltrimstr leaves hashes untouched');

done_testing;
