use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "value": "foobar",
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
