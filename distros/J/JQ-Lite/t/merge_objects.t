use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = <<'JSON';
{
  "items": [
    { "name": "Widget", "value": 1 },
    { "value": 2, "active": true },
    { "nested": { "id": 42 } },
    7,
    null,
    ["ignored"]
  ],
  "single": { "foo": "bar" },
  "no_hashes": ["alpha", "beta"]
}
JSON

my $jq = JQ::Lite->new;

my @merged = $jq->run_query($json, '.items | merge_objects');
is_deeply(
    \@merged,
    [
        {
            name   => 'Widget',
            value  => 2,
            active => JSON::PP::true,
            nested => { id => 42 },
        }
    ],
    'merge_objects folds arrays of objects into one hash with later values winning',
);

my @single = $jq->run_query($json, '.single | merge_objects');
is_deeply(
    \@single,
    [
        { foo => 'bar' },
    ],
    'merge_objects returns a shallow copy when applied to a single object',
);

my @empty = $jq->run_query($json, '.no_hashes | merge_objects');
is_deeply(
    \@empty,
    [
        {},
    ],
    'merge_objects returns an empty hash when no objects are present in the array',
);

done_testing();
