use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $objects = q([
  { "amount": 10 },
  { "amount": 25 },
  { "amount": 5 }
]);

my ($sum_amount) = $jq->run_query($objects, 'sum_by(.amount)');
is($sum_amount, 40, 'sum_by(.amount) sums numeric fields across objects');

my $mixed = q([
  { "amount": 5 },
  { "amount": null },
  { "amount": "ignore" },
  { "amount": 10 }
]);

my ($sum_mixed) = $jq->run_query($mixed, 'sum_by(.amount)');
is($sum_mixed, 15, 'sum_by(.amount) ignores non-numeric values');

my $numbers = q([1, 2, 3, 4]);
my ($sum_direct) = $jq->run_query($numbers, 'sum_by(.)');
is($sum_direct, 10, 'sum_by(.) sums numeric array items directly');

my $nested = q([
  { "meta": { "scores": [1, 2] } },
  { "meta": { "scores": [3] } }
]);

my ($sum_nested) = $jq->run_query($nested, 'sum_by(.meta.scores[])');
is($sum_nested, 6, 'sum_by handles traversal paths yielding multiple values');

done_testing;
