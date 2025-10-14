use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $length_json = '{"one":[1,2],"two":[3]}';
my @lengths     = $jq->run_query($length_json, 'map_values(length)');
is_deeply($lengths[0], { one => 2, two => 1 }, 'map_values(length) transforms each value within an object');

my $filter_json = '{"keep":{"value":1},"drop":{"value":0}}';
my @filtered    = $jq->run_query($filter_json, 'map_values(select(.value > 0))');
is_deeply($filtered[0], { keep => { value => 1 } }, 'map_values(select(.value > 0)) removes entries whose nested values fail the filter');

my $array_json = q([
  {"counts": [1, 2, 3]},
  {"counts": []}
]);
my @array_results = $jq->run_query($array_json, 'map_values(length)');
is_deeply($array_results[0], [
    { counts => 3 },
    { counts => 0 },
], 'map_values(length) processes arrays of objects element-wise');

my @emptied = $jq->run_query($length_json, 'map_values(empty)');
is_deeply($emptied[0], {}, 'map_values(empty) drops keys when the filter yields no result');

done_testing;
