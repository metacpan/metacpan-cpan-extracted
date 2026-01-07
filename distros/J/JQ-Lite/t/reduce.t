use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $numbers = '{ "numbers": [1, 2, 3, 4] }';
my @sum = $jq->run_query($numbers, 'reduce .numbers[] as $n (0; . + $n)');
is($sum[0], 10, 'reduce sums numeric arrays');

my $with_init_filter = '[1, 2, 3]';
my @length_init = $jq->run_query($with_init_filter, 'reduce .[] as $n (length; . + $n)');
is($length_init[0], 9, 'reduce falls back to filter evaluation for init expression');

my $items = '{ "items": [ { "name": "alice", "value": 2 }, { "name": "bob", "value": 3 } ] }';
my @total = $jq->run_query($items, 'reduce .items[] as $item (0; . + $item.value)');
is($total[0], 5, 'reduce accesses variable paths');

my @last_name = $jq->run_query($items, 'reduce .items[] as $item (null; $item.name)');
is($last_name[0], 'bob', 'reduce assigns variable value without arithmetic');

done_testing;
