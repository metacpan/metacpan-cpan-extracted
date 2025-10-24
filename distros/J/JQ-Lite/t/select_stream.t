use strict;
use warnings;

use Test::More;

use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = <<'JSON';
[
  {"id": 1, "flags": [true, false, true]},
  {"id": 2, "flags": [false, false]},
  {"id": 3, "flags": [true, true]}
]
JSON

my @stream_results = $jq->run_query($json, '.[] | select(.flags[]) | .id');

is_deeply(
    \@stream_results,
    [1, 1, 3, 3],
    'select() emits the input once per truthy value produced by the predicate'
);

my @fallback_results = $jq->run_query($json, '.[] | select(.id > 1) | .id');

is_deeply(
    \@fallback_results,
    [2, 3],
    'select() still handles basic comparison predicates'
);

done_testing();
