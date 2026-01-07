use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = <<'JSON';
{
  "users": [
    { "name": "Alice", "age": 30 },
    { "name": "Bob",   "age": 22 },
    { "name": "Carol", "age": 19 }
  ]
}
JSON

my @res1 = $jq->run_query($json, '.users | count');
is_deeply(\@res1, [3], 'count users');

my @res2 = $jq->run_query($json, '.users[] | select(.age > 25) | count');
is_deeply(\@res2, [1], 'count users over 25');

my @per_user = $jq->run_query($json, '.users[] | count');
is_deeply(\@per_user, [1, 1, 1], 'count reports one item per streamed user');

my $nested = <<'JSON';
[
  ["a", "b"],
  ["c"]
]
JSON

my @per_array = $jq->run_query($nested, '.[] | count');
is_deeply(\@per_array, [2, 1], 'count measures each array independently');

my @object_stream = $jq->run_query('{"a":1}', '. as $x | $x | count');
is_deeply(\@object_stream, [1], 'count treats streamed objects as single items');

my @mixed_sequence = $jq->run_query('[1,2]', '.[], 5, null | count');
is_deeply(\@mixed_sequence, [1, 1, 1, 0], 'count reports 1 for scalars streamed from comma sequences');

done_testing;
