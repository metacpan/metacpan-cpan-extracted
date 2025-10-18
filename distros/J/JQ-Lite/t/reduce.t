use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $numbers = '{ "numbers": [1, 2, 3, 4] }';
my @sum = $jq->run_query($numbers, 'reduce .numbers[] as $n (0; . + $n)');
is($sum[0], 10, 'reduce sums numeric arrays');

my $items = '{ "items": [ { "name": "alice", "value": 2 }, { "name": "bob", "value": 3 } ] }';
my @total = $jq->run_query($items, 'reduce .items[] as $item (0; . + $item.value)');
is($total[0], 5, 'reduce accesses variable paths');

my @last_name = $jq->run_query($items, 'reduce .items[] as $item (null; $item.name)');
is($last_name[0], 'bob', 'reduce assigns variable value without arithmetic');

done_testing;
