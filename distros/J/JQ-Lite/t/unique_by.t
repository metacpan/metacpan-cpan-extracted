use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "users": [
    { "name": "Alice", "city": "Tokyo" },
    { "name": "Bob",   "city": "Osaka" },
    { "name": "Alice", "city": "Kyoto" },
    { "name": "Charlie", "city": "Nagoya" }
  ],
  "numbers": [1, 2, 1, 3, 2],
  "nested": [
    { "meta": { "id": 1 }, "value": "first" },
    { "meta": { "id": 1 }, "value": "duplicate" },
    { "meta": { "id": 2 }, "value": "unique" }
  ]
}
JSON

my $jq = JQ::Lite->new;

my @by_name = $jq->run_query($json, '.users | unique_by(.name) | map(.name)');
is_deeply(
    \@by_name,
    [['Alice', 'Bob', 'Charlie']],
    'unique_by(.name) keeps the first occurrence for each projected name',
);

my @by_self = $jq->run_query($json, '.numbers | unique_by(.)');
is_deeply(
    \@by_self,
    [[1, 2, 3]],
    'unique_by(.) removes duplicate scalars while preserving order',
);

my @by_nested = $jq->run_query($json, '.nested | unique_by(.meta.id) | map(.value)');
is_deeply(
    \@by_nested,
    [['first', 'unique']],
    'unique_by(.meta.id) deduplicates using nested keys',
);

done_testing();
