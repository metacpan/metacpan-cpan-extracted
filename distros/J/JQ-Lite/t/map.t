use strict;
use warnings;
use Test::More;
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

done_testing;
