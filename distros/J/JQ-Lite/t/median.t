use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json_objects = q([
  { "value": 10 },
  { "value": 30 },
  { "value": 20 }
]);

my $json_even = q([1, 3, 5, 7]);
my $json_mixed = q(["foo", 2, 4, "bar"]);
my $json_no_numeric = q(["foo", "bar"]);
my $json_scientific = q([1e2, "200", 50]);

my $jq = JQ::Lite->new;

my ($median_objects) = $jq->run_query($json_objects, 'map(.value) | median');
is($median_objects, 20, 'median over mapped values');

my ($median_even) = $jq->run_query($json_even, 'median');
is($median_even, 4, 'median averages the middle pair for even-length arrays');

my ($median_mixed) = $jq->run_query($json_mixed, 'median');
is($median_mixed, 3, 'median uses only numeric values');

my ($median_no_numeric) = $jq->run_query($json_no_numeric, 'median');
ok(!defined $median_no_numeric, 'median returns undef when no numeric values are present');

my ($median_scientific) = $jq->run_query($json_scientific, 'median');
is($median_scientific, 100, 'median handles scientific notation and numeric strings');

done_testing;
