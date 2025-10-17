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

# --- objects ---
my @object = $jq->run_query($json, '.object | keys_unsorted');
my @sorted = $jq->run_query($json, '.object | keys');

# Set equality: keys_unsorted (when sorted) should equal keys
is_deeply(
    [ sort @{ $object[0] } ],
    $sorted[0],
    'keys_unsorted returns the same set of keys as keys (after sorting)',
);

# Order of keys_unsorted is implementation-defined and may match sorted order.
note('keys_unsorted order is implementation-defined; do not assert difference from keys');

# --- arrays ---
my @array = $jq->run_query($json, '.array | keys_unsorted');
is_deeply($array[0], [0, 1, 2], 'keys_unsorted returns indexes for arrays');

# --- scalars ---
my @scalar = $jq->run_query($json, '.array[0] | keys_unsorted');
ok(!defined $scalar[0], 'non-object/array inputs return undef');

done_testing();
