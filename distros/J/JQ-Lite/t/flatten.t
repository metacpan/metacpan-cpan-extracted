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

is_deeply(\@results, [[1,2], [3], [], [4,5]], 'flatten 1 layer of array');
done_testing();
