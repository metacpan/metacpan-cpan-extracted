use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $objects = q([
  { "score": 10 },
  { "score": 30 },
  { "score": 20 }
]);

my ($avg_score) = $jq->run_query($objects, 'avg_by(.score)');
is($avg_score, 20, 'avg_by(.score) averages numeric fields across objects');

my $mixed = q([
  { "score": 5 },
  { "score": null },
  { "score": "ignore" },
  { "score": 15 }
]);

my ($avg_mixed) = $jq->run_query($mixed, 'avg_by(.score)');
is($avg_mixed, 10, 'avg_by(.score) ignores non-numeric values');

my $numbers = q([1, 3, 5, 7]);
my ($avg_direct) = $jq->run_query($numbers, 'avg_by(.)');
is($avg_direct, 4, 'avg_by(.) averages numeric array items directly');

my $nested = q([
  { "meta": { "scores": [1, 2] } },
  { "meta": { "scores": [3] } }
]);

my ($avg_nested) = $jq->run_query($nested, 'avg_by(.meta.scores[])');
is($avg_nested, 2, 'avg_by handles traversal paths yielding multiple values');

my $empty = q([]);
my ($avg_empty) = $jq->run_query($empty, 'avg_by(.)');
is($avg_empty, 0, 'avg_by on empty arrays yields 0');

done_testing;
