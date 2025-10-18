use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q([
  { "id": 1 },
  { "id": 5 },
  { "id": 15 },
  { "id": 25 }
]);

my $jq = JQ::Lite->new;
my @calc = $jq->run_query($json, 'map(select(.id + 5 > 20))');

is_deeply(
    $calc[0],
    [ { id => 25 } ],
    'id + 5 > 20 selects only 25'
);

my @incremented = $jq->run_query($json, 'map(.id + 1)');

is_deeply(
    $incremented[0],
    [ 2, 6, 16, 26 ],
    'map(.id + 1) increments each id'
);

my $people = q([
  { "name": "Alice", "city": "Tokyo" },
  { "name": "Bob",   "city": "Osaka" }
]);

my @joined = $jq->run_query($people, 'map(.name + "@" + .city)');

is_deeply(
    $joined[0],
    [ 'Alice@Tokyo', 'Bob@Osaka' ],
    'map(.name + "@" + .city) concatenates name and city'
);

done_testing;
