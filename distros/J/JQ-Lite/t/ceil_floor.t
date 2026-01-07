use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "price": 19.2,
  "debt": -1.7,
  "numbers": [1.1, -1.1, "n/a", null, [2.3, -2.3]],
  "bools": [true, false, [true]]
});

my $jq = JQ::Lite->new;

my @ceil_price = $jq->run_query($json, '.price | ceil');
is($ceil_price[0], 20, 'ceil rounds positive scalar up');

my @ceil_debt = $jq->run_query($json, '.debt | ceil');
is($ceil_debt[0], -1, 'ceil rounds negative scalar toward zero');

my @ceil_values = $jq->run_query($json, '.numbers | ceil');
is_deeply(
    $ceil_values[0],
    [2, -1, 'n/a', undef, [3, -2]],
    'ceil processes arrays recursively and leaves non-numeric values untouched'
);

my @ceil_bools = $jq->run_query($json, '.bools | ceil');
is_deeply(
    $ceil_bools[0],
    [1, 0, [1]],
    'ceil treats booleans as numeric values'
);

my @floor_price = $jq->run_query($json, '.price | floor');
is($floor_price[0], 19, 'floor rounds positive scalar down');

my @floor_debt = $jq->run_query($json, '.debt | floor');
is($floor_debt[0], -2, 'floor rounds negative scalar away from zero');

my @floor_values = $jq->run_query($json, '.numbers | floor');
is_deeply(
    $floor_values[0],
    [1, -2, 'n/a', undef, [2, -3]],
    'floor processes arrays recursively and leaves non-numeric values untouched'
);

my @floor_bools = $jq->run_query($json, '.bools | floor');
is_deeply(
    $floor_bools[0],
    [1, 0, [1]],
    'floor treats booleans as numeric values'
);


done_testing;
