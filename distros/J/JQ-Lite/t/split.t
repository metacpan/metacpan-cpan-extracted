use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "text": "foo,bar,baz",
  "users": [
    { "name": "Alice" },
    { "name": "Bob" }
  ],
  "mixed": ["alpha beta", null, ["inner"], {"skip": "value"}, true],
  "trailing": "tail,",
  "dots": "a.b.c"
});

my $jq = JQ::Lite->new;

my @comma = $jq->run_query($json, '.text | split(",")');
is_deeply($comma[0], [qw(foo bar baz)], 'split(",") breaks comma-separated string');

my @chars = $jq->run_query($json, '.users[0].name | split("")');
is_deeply($chars[0], [qw(A l i c e)], 'split("") returns individual characters');

my @array = $jq->run_query($json, '.mixed | split(" ")');
my $expected = [
    qw(alpha beta),
    undef,
    'inner',
    { skip => 'value' },
    'true',
];
is_deeply($array[0], $expected, 'split applies recursively to arrays and flattens nested results');

my @null_value = $jq->run_query('null', 'split(",")');
ok(!defined $null_value[0], 'split propagates null inputs rather than dropping them');

my @bool_chars = $jq->run_query('true', 'split("")');
is_deeply($bool_chars[0], [qw(t r u e)], 'split treats booleans like strings when splitting characters');

my @bool_array = $jq->run_query('[true,false]', 'split(",")');
is_deeply($bool_array[0], [qw(true false)], 'split flattens results for arrays of booleans');

my @mixed_flat = $jq->run_query('[true,"a,b",false]', 'split(",")');
is_deeply($mixed_flat[0], [qw(true a b false)], 'split flattens results for mixed arrays containing strings and booleans');

my @literal = $jq->run_query($json, '.dots | split(".")');
is_deeply($literal[0], [qw(a b c)], 'split uses literal separator rather than regex');

my @trailing = $jq->run_query($json, '.trailing | split(",")');
is_deeply($trailing[0], ['tail', ''], 'split preserves trailing empty fields');

done_testing;
