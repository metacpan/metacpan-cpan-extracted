use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice" },
    { "name": "Bob" },
    { "name": "Carol" },
    { "name": "Dave" }
  ]
});

my $jq = JQ::Lite->new;

my @limit_2 = $jq->run_query($json, '.users | limit(2)');
my @limit_0 = $jq->run_query($json, '.users | limit(0)');
my @limit_10 = $jq->run_query($json, '.users | limit(10)');

is_deeply($limit_2[0], [ {name => 'Alice'}, {name => 'Bob'} ], 'limit(2) returns first 2');
is_deeply($limit_0[0], [], 'limit(0) returns empty array');
is_deeply([ map { $_->{name} } @{ $limit_10[0] } ],
          ['Alice', 'Bob', 'Carol', 'Dave'],
          'limit(10) returns all available elements');

done_testing;
