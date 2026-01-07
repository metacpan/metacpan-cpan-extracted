use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "items": [[1, 2], [3], [], [4, 5]]
}
JSON

my $jq = JQ::Lite->new;
my @results = $jq->run_query($json, '.items | flatten');

is_deeply($results[0], [1, 2, 3, 4, 5], 'flatten merges nested arrays into a single array');

my @string_chars = $jq->run_query('"hello"', 'flatten');
is_deeply($string_chars[0], 'hello', 'flatten leaves non-array values untouched');

my @numeric_string_chars = $jq->run_query('"123"', 'flatten');
is_deeply($numeric_string_chars[0], '123', 'flatten does not iterate over scalars');

my @number_results = $jq->run_query('123', 'flatten');
is_deeply($number_results[0], 123, 'flatten passes numbers through unchanged');

my @map_flatten = $jq->run_query('["a,b", null, "c,d"]', 'map(if . == null then null else split(",") end) | flatten');
is_deeply(
    $map_flatten[0],
    [ 'a', 'b', undef, 'c', 'd' ],
    'flatten preserves nulls and combines mapped array results',
);
done_testing();
