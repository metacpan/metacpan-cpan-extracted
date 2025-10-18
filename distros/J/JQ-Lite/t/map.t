use strict;
use warnings;
use Test::More;
use JSON::PP ();
use JQ::Lite;

my $json = q([
  {"id": 1},
  {"id": 5},
  {"id": 15},
  {"id": 25}
]);

my $jq = JQ::Lite->new;

my @map_results = $jq->run_query($json, 'map(select(.id > 10))');

is_deeply($map_results[0], [{id => 15}, {id => 25}], 'map(select(.id > 10)) returns elements with id > 10');

my @empty_results = $jq->run_query($json, 'map(select(.id > 100))');
is_deeply($empty_results[0], [], 'map(select(.id > 100)) returns empty array');

my $people = q([
  {"name": "Alice", "age": 30, "city": "Tokyo"},
  {"name": "Bob", "age": 25, "city": "Osaka"}
]);

my @projected = $jq->run_query($people, 'map({name, age})');
is_deeply(
    $projected[0],
    [
        { name => 'Alice', age => 30 },
        { name => 'Bob',   age => 25 },
    ],
    'map({name, age}) expands object shorthand entries'
);

my @adults = $jq->run_query($people, 'map({name, adult: (.age >= 20)})');
is_deeply(
    $adults[0],
    [
        { name => 'Alice', adult => JSON::PP::true },
        { name => 'Bob',   adult => JSON::PP::true },
    ],
    'map({name, adult: (.age >= 20)}) evaluates the filter per element'
);

done_testing;
