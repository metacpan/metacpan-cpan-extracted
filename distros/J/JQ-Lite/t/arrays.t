use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "items": [
    [1, 2, 3],
    {"note": "object"},
    [4],
    "scalar",
    [],
    42
  ]
}
JSON

my $jq = JQ::Lite->new;
my @results = $jq->run_query($json, '.items[] | arrays');

is_deeply(\@results, [[1,2,3], [4], []], 'arrays returns only array inputs');

@results = $jq->run_query($json, '.items | arrays');

is_deeply(\@results, [
    [
        [1, 2, 3],
        { note => 'object' },
        [4],
        'scalar',
        [],
        42,
    ]
], 'arrays passes through array inputs unchanged');

@results = $jq->run_query($json, '.items[1] | arrays');

is_deeply(\@results, [], 'arrays yields empty result when input is not an array');

done_testing();
