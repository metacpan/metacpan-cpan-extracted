use Test::More tests => 16;

BEGIN { use_ok('Math::EWMA'); }

my $e = Math::EWMA->new(alpha => .25);

cmp_ok( $e->alpha, '==', '0.25','alpha set correct' );

my $result = $e->ewma(4);

cmp_ok($e->ewma, '==', $result, 'ewma() returns last result');
cmp_ok($e->last_avg, '==', $result, 'last_avg() returns last result');
cmp_ok($result, '==', 4, 'Current average is 4');

$result = $e->ewma(8);

cmp_ok($e->ewma, '==', $result, 'ewma() returns last result');
cmp_ok($e->last_avg, '==', $result, 'last_avg() returns last result');
cmp_ok($result, '==', 5, 'Current average is 5');

$result = $e->ewma(7);

cmp_ok($result, '==', 5.5, 'Current average is 5.5');

$result = $e->ewma(13.99);
cmp_ok($result, '==', 7.62, 'Current average is 7.62');
cmp_ok($e->ewma, '==', 7.62, 'Current average is 7.62');
cmp_ok($e->last_avg, '>=', 7.62245, 'last_avg is ~7.6225'); 
cmp_ok($e->precision, '==', 2, 'precision is currently 2');

$e->precision(3);

cmp_ok($e->precision, '==', 3, 'precision is currently 3');
like($e->ewma, qr/\d\.\d{3}/, 'Current average has 3 deceimal places');

#test new object can continue from a previous sequence
my $e2 = Math::EWMA->new(alpha => .25, last_avg => 5.5);

$result = $e2->ewma(13.99);
cmp_ok($result, '==', 7.62, 'Current average is 7.62');

