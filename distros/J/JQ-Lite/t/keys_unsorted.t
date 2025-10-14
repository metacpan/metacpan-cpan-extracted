use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = <<'JSON';
{
  "object": {
    "third": 3,
    "first": 1,
    "second": 2
  },
  "array": ["a", "b", "c"]
}
JSON

my $jq = JQ::Lite->new;

my @object = $jq->run_query($json, '.object | keys_unsorted');
my @sorted = $jq->run_query($json, '.object | keys');

is_deeply(
    [ sort @{ $object[0] } ],
    $sorted[0],
    'keys_unsorted returns the same keys as keys when sorted',
);

isnt(
    join(',', @{ $object[0] }),
    join(',', @{ $sorted[0] }),
    'keys_unsorted preserves unsorted ordering',
);

my @array = $jq->run_query($json, '.array | keys_unsorted');
is_deeply($array[0], [0, 1, 2], 'keys_unsorted returns indexes for arrays');

my @scalar = $jq->run_query($json, '.array[0] | keys_unsorted');
ok(!defined $scalar[0], 'non-object/array inputs return undef');

DONE_TESTING:
done_testing();
