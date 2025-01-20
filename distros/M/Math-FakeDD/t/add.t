use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $obj1 = Math::FakeDD->new(8);
my $obj2 = Math::FakeDD->new(0.125);
my $obj3 = dd_add($obj1, $obj2);
my $obj4 = $obj1 + $obj2;

cmp_ok(dd_add('1.3', Math::FakeDD->new('9.1')), '==',
       dd_add(Math::FakeDD->new('9.1'), '1.3'), '1: commutativity holds');

cmp_ok('1.3' + Math::FakeDD->new('9.1'), '==',
       Math::FakeDD->new('9.1') + '1.3', '2: commutativity holds');

cmp_ok(dd_add(0.125, 8), '=='   , $obj1 + $obj2, "1: additions match");
cmp_ok(Math::FakeDD->new(8.125), '==', $obj3        , "2: additions match");
cmp_ok($obj4, '=='             , $obj3        , "3: additions match");
$obj3 += '0.125';
$obj4 += $obj2;
cmp_ok($obj3, '==', $obj4, '1: += ok');
dd_add_eq($obj3, '0.125');
cmp_ok($obj3, '==', Math::FakeDD->new(8.375), '2: += ok');

my $dbl_max = Math::MPFR::Rmpfr_get_d(Math::MPFR->new('1.fffffffffffffp+1023', 16), 0);
$obj1 = Math::FakeDD->new($dbl_max);
cmp_ok(dd_is_inf($obj1), '==', 0, "DBL_MAX is not an Inf");
$obj2 = $obj1 + (2 ** 970);
cmp_ok(dd_is_inf($obj2)  , '!=', 0, "addition (+) results in Inf");
$obj1 += 2 ** 970;
cmp_ok(dd_is_inf($obj1)  , '!=', 0, "addition (+=) results in Inf");

$obj1 = Math::FakeDD->new(-$dbl_max);
cmp_ok(dd_is_inf($obj1), '==', 0, "-DBL_MAX is not an Inf");
$obj2 = $obj1 - (2 ** 970);
cmp_ok($obj2, '==', dd_inf(-1), "subtraction (-) results in -Inf");
$obj1 -= 2 ** 970;
cmp_ok($obj1, '==', dd_inf(-1), "subtraction (-=) results in -Inf");


done_testing();
