use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @all_truthy = $jq->run_query('[true, 1, "yes"]', 'all');
ok($all_truthy[0], 'all returns true when every array element is truthy');

my @all_falsey = $jq->run_query('[true, false, true]', 'all');
ok(!$all_falsey[0], 'all returns false when any array element is falsy');

my @filter_truthy = $jq->run_query('[{"active":true}, {"active":1}]', 'all(.active)');
ok($filter_truthy[0], 'all(filter) returns true when filter yields truthy values for every element');

my @filter_falsey = $jq->run_query('[{"active":true}, {"active":null}]', 'all(.active)');
ok(!$filter_falsey[0], 'all(filter) returns false when filter yields a falsy value');

my @empty_array = $jq->run_query('[]', 'all');
ok($empty_array[0], 'all on an empty array returns true (vacuous truth)');

my @scalar_value = $jq->run_query('0', 'all');
ok(!$scalar_value[0], 'all on a scalar uses the value\'s truthiness');

done_testing;
