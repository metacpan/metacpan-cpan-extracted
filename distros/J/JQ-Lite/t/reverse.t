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

done_testing;
