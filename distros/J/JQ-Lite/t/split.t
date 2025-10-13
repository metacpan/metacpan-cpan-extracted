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
  "mixed": ["alpha beta", null, ["inner"], {"skip": "value"}],
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
    [qw(alpha beta)],
    [],
    [[qw(inner)]],
    { skip => 'value' },
];
is_deeply($array[0], $expected, 'split applies recursively to arrays and keeps non-strings untouched');

my @literal = $jq->run_query($json, '.dots | split(".")');
is_deeply($literal[0], [qw(a b c)], 'split uses literal separator rather than regex');

my @trailing = $jq->run_query($json, '.trailing | split(",")');
is_deeply($trailing[0], ['tail', ''], 'split preserves trailing empty fields');

done_testing;
