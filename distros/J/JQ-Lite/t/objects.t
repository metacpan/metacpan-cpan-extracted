use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "items": [
    [1, 2, 3],
    {"note": "object"},
    {"type": "also object"},
    "scalar",
    42,
    null
  ]
}
JSON

my $jq = JQ::Lite->new;
my @results = $jq->run_query($json, '.items[] | objects');

is_deeply(\@results, [
    { note => 'object' },
    { type => 'also object' },
], 'objects returns only hash inputs when iterating arrays');

@results = $jq->run_query($json, '.items[1] | objects');

is_deeply(\@results, [ { note => 'object' } ], 'objects passes through object inputs unchanged');

@results = $jq->run_query($json, '.items[0] | objects');

is_deeply(\@results, [], 'objects yields empty result when input is not an object');

@results = $jq->run_query($json, '.items | objects');

is_deeply(\@results, [], 'objects yields no output for non-object top-level input');

done_testing();
