use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    {
      "name": "Alice",
      "friends": [ { "name": "Charlie" }, { "name": "Dave" } ]
    },
    {
      "name": "Bob",
      "friends": [ { "name": "Eve" } ]
    }
  ]
});

my $jq = JQ::Lite->new;
my @result = $jq->run_query($json, ".users[].friends[].name");

is_deeply(\@result, ['Charlie', 'Dave', 'Eve'], 'Multi-level array traversal works');
done_testing;
