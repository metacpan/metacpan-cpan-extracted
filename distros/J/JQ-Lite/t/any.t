use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @bool_true = $jq->run_query('[false, true, false]', 'any');
ok($bool_true[0], 'any returns true when at least one array element is truthy');

my @bool_false = $jq->run_query('[false, false, null]', 'any');
ok(!$bool_false[0], 'any returns false when every array element is falsy');

my @filter_true = $jq->run_query('[{"active":false}, {"active":true}, {"active":false}]', 'any(.active)');
ok($filter_true[0], 'any(filter) returns true when filter yields a truthy value');

my @filter_false = $jq->run_query('[{"active":false}, {"active":null}]', 'any(.active)');
ok(!$filter_false[0], 'any(filter) returns false when filter never yields truthy results');

my @scalar_true = $jq->run_query('true', 'any');
ok($scalar_true[0], 'any on a scalar truthy value returns true');

my @scalar_false = $jq->run_query('0', 'any');
ok(!$scalar_false[0], 'any on a numeric zero returns false');

done_testing;
