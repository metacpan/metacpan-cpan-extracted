use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice" },
    { "name": "Bob" },
    { "name": "Carol" }
  ]
});

my $jq = JQ::Lite->new;

my @reversed = $jq->run_query($json, '.users | reverse');
my @names = map { $_->{name} } @{ $reversed[0] };

is_deeply(\@names, ['Carol', 'Bob', 'Alice'], 'users reversed correctly');

my @string_reversed = $jq->run_query('"stressed"', 'reverse');
is($string_reversed[0], 'desserts', 'reverse handles plain strings');

my @numeric_string = $jq->run_query('"123"', 'reverse');
is($numeric_string[0], '321', 'reverse treats numeric strings as strings');

my @non_string = $jq->run_query('42', 'reverse');
is($non_string[0], 42, 'reverse leaves numbers unchanged');

done_testing;
