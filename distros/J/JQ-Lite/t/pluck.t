use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q([
  {"name": "Alice", "age": 30},
  {"name": "Bob", "age": 25},
  {"name": "Carol"}
]);

my $jq = JQ::Lite->new;

my @results = $jq->run_query($json, 'pluck("age")');

is_deeply($results[0], [30, 25, undef], 'pluck("age") extracts values including missing ones as undef');

my @nested_results = $jq->run_query($json, 'pluck("name")');

is_deeply($nested_results[0], ["Alice", "Bob", "Carol"], 'pluck("name") extracts string values');

my $nested_json = q([
  {"meta": {"score": 10}},
  {"meta": {"score": 15}},
  {"meta": {"label": "pending"}}
]);

my @nested = $jq->run_query($nested_json, 'pluck("meta.score")');

is_deeply($nested[0], [10, 15, undef], 'pluck("meta.score") supports dotted paths');

done_testing;
