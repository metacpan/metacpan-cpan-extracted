use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q([
  { "id": 1 },
  { "id": 5 },
  { "id": 15 },
  { "id": 25 }
]);

my $jq = JQ::Lite->new;
my @calc = $jq->run_query($json, 'map(select(.id + 5 > 20))');

is_deeply(
    $calc[0],
    [ { id => 25 } ],
    'id + 5 > 20 selects only 25'
);

done_testing;
