use Test::More tests => 26;

BEGIN { use_ok('Math::SMA'); }

my $e = Math::SMA->new(size => 5);

cmp_ok( $e->size, '==', 5,'size set correct' );

my $result = $e->sma(4);

cmp_ok($e->sma, '==', $result, 'sma() returns last result');
cmp_ok($e->last_avg, '==', $result, 'last_avg() returns last result');
cmp_ok($result, '==', 4, 'Current average is 4');

$result = $e->sma(8);

cmp_ok($e->sma, '==', $result, 'sma() returns last result');
cmp_ok($e->last_avg, '==', $result, 'last_avg() returns last result');
cmp_ok($result, '==', 6, 'Current average is 6');

$result = $e->sma(6);

cmp_ok($result, '==', 6, 'Current average is 6');

$result = $e->sma(8);
cmp_ok($result, '>=', 6.49, 'Current average is 6.5');
cmp_ok($result, '<', 6.51, 'Current average is 6.5');

$result = $e->sma(7);
cmp_ok($result, '>=', 6.59, 'Current average is 6.6');
cmp_ok($result, '<', 6.61, 'Current average is 6.6');
cmp_ok(@{$e->values}, '==', 5, 'Array size is 5');

$result = $e->sma(5.373);
cmp_ok($result, '>=', 6.86, 'Current average is 6.8746');
cmp_ok($result, '<', 7.88, 'Current average is 6.8746');
cmp_ok(@{$e->values}, '==', 5, 'Array size is 5');

cmp_ok($e->precision, '==', 2, 'precision is currently 2');
like($e->sma, qr/\d\.\d{2}/, 'Current average has 2 decimal places');

$e->precision(3);

cmp_ok($e->precision, '==', 3, 'precision is currently 3');
like($e->sma, qr/\d\.\d{3}/, 'Current average has 3 decimal places');

#test new object can continue from a previous sequence (and one with more values than size)
my $e2 = Math::SMA->new(size => 3, values => [3,3,4,5,6]);
cmp_ok(@{$e->values}, '==', 5, 'values has 5 items');

cmp_ok($e2->last_avg(), '==', 5, 'Current average is 5');

$result = $e2->sma(7);

cmp_ok(@{$e2->values}, '==', $e2->size(), 'values has 3 items');
cmp_ok(@{$e2->values}, '==', 3, 'values has 3 items');

cmp_ok($result, '==', 6, 'Current average is 6');

