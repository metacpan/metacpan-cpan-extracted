# Testing extended overloading of gmp objects with Math::MPFR.
# This is essentially the same as t/oloadex_math_gmp.t from
# the Math-MPFR-4.47 test suite.

use strict;
use warnings;

use Test::More;

eval { require Math::GMP_OLOAD;};

if($@) {
  warn "\$\@: $@\n";
  plan skip_all => 'Math::GMP_OLOAD failed to load';
  done_testing();
  exit 0;
}

eval { require Math::MPFR;};

if($@) {
  warn "\$\@: $@\n";
  plan skip_all => 'Math::MPFR failed to load';
  done_testing();
  exit 0;
}

if($Math::MPFR::VERSION < 4.47) {
  plan skip_all => " Math::MPFR::VERSION ($Math::MPFR::VERSION) not supported - need at least 4.47.";
  done_testing();
  exit 0;
}

if($Math::GMP::VERSION < 2.11) {
  plan skip_all => " Math::GMP::VERSION ($Math::GMP::VERSION) not supported - need at least 2.11.";
  done_testing();
  exit 0;
}

my $z = Math::GMP->new('1234' x 2);
my $f = Math::MPFR->new(0);

cmp_ok( $f, '<', $z, "'<' ok");
cmp_ok( $f, '<', $z, "'!=' ok");
cmp_ok( $f, '<=', $z, "'<=' ok");
cmp_ok( $f + $z, '==', $z, "'==' ok");
cmp_ok( $f + $z, '==', $z, "'>=' ok");
cmp_ok( $f += $z, '==', $z, "'+=' ok");
$f += $z;
cmp_ok( $f, '>', $z, "'>' ok");
cmp_ok( $f - $z, '==', $z, "'-' ok");
$f -= $z;
cmp_ok($f, '==', $z, "'-=' ok");
cmp_ok($f ** Math::GMP->new(2), '==', $z ** 2, "'**' ok");
$f **= Math::GMP->new(2);
cmp_ok($f, '==', $z ** 2, "'**=' ok");

$f **= 0.5;

cmp_ok($f * 5, '==', $z * 5, "'*' ok");
cmp_ok($f *= Math::GMP->new(5), '==', $z * 5, "'*=' ok");
cmp_ok($f / Math::GMP->new(5), '==', $z, "'/' ok");
cmp_ok($f /= Math::GMP->new(5), '==', $z, "'/=' ok");

Math::MPFR::Rmpfr_sprintf(my $buf, "%Zd", $z, 32);
cmp_ok($buf, 'eq', "$z", "'%Zd' formatting ok");

Math::MPFR::Rmpfr_sprintf($buf, "%Zu", $z, 32);
cmp_ok($buf, 'eq', "$z", "'%Zu' formatting ok");

Math::MPFR::Rmpfr_sprintf($buf, "%Zx", $z, 32);
cmp_ok($buf, 'eq', 'bc4ff2', "'%Zx' formatting ok");

Math::MPFR::Rmpfr_sprintf($buf, "%ZX", $z, 32);
cmp_ok($buf, 'eq', 'BC4FF2', "'%ZX' formatting ok");

##### START EXPERIMENTAL #####

my $rop;
my $mpfr_big = Math::MPFR->new(100);
my $gmp_big  = Math::GMP->new(100);

my $mpfr_tiny = Math::MPFR->new(5);
my $gmp_tiny =  Math::GMP->new(5);

cmp_ok($mpfr_big, '>', $gmp_tiny, "MPFR_BIG > GMP_TINY");
cmp_ok($gmp_tiny, '<', $mpfr_big, "GMP_TINY < MPFR_BIG");
cmp_ok($mpfr_big, '>=', $gmp_tiny, "MPFR_BIG >= GMP_TINY");
cmp_ok($gmp_tiny, '<=', $mpfr_big, "GMP_TINY <= MPFR_BIG");
cmp_ok($mpfr_big, '>=', $gmp_big, "MPFR_BIG >= GMP_BIG");
cmp_ok($gmp_big, '<=', $mpfr_big, "GMP_BIG <= MPFR_BIG");
cmp_ok($mpfr_big, '==', $gmp_big, "MPFR_BIG == GMP_BIG");
cmp_ok($gmp_big, '==', $mpfr_big, "GMP_BIG == MPFR_BIG");
cmp_ok($mpfr_big, '!=', $gmp_tiny, "MPFR_BIG != GMP_TINY");
cmp_ok($gmp_big, '!=', $mpfr_tiny, "GMP_BIG != MPFR_TINY");
cmp_ok(($mpfr_big <=> $gmp_tiny), '>', 0, "MPFR_BIG <=> GMP_TINY > 0");
cmp_ok(($gmp_big <=> $mpfr_tiny), '>', 0, "GMP_BIG <=> MPFR_TINY > 0");
##################################
$rop = $mpfr_big + $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "MPFR + GMP returns MPFR");
cmp_ok($rop, '==', 105, "MPFR + GMP returns correct value");

$rop = $mpfr_big - $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "MPFR - GMP returns MPFR");
cmp_ok($rop, '==', 95, "MPFR + GMP returns correct value");

$rop = $mpfr_big * $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "MPFR * GMP returns MPFR");
cmp_ok($rop, '==', 500, "MPFR * GMP returns correct value");

$rop = $mpfr_big / $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "MPFR / GMP returns MPFR");
cmp_ok($rop, '==', 20, "MPFR / GMP returns correct value");

$rop = $mpfr_big ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "MPFR ** GMP returns MPFR");
cmp_ok($rop, '==', 10000000000, "MPFR ** GMP returns correct value");
###################################
$rop = $gmp_tiny + $mpfr_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "GMP + MPFR returns MPFR");
cmp_ok($rop, '==', 10, "MPFR + GMP returns correct value");

$rop = $gmp_tiny - $mpfr_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "GMP - MPFR returns MPFR");
cmp_ok($rop, '==', 0, "MPFR + GMP returns correct value");

$rop = $gmp_tiny * $mpfr_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "GMP * MPFR returns MPFR");
cmp_ok($rop, '==', 25, "MPFR * GMP returns correct value");

$rop = $gmp_tiny / $mpfr_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "GMP / MPFR returns MPFR");
cmp_ok($rop, '==', 1, "GMP / MPFR returns correct value");

$rop = $gmp_tiny ** $mpfr_tiny;
cmp_ok(ref($rop), 'eq', 'Math::MPFR', "GMP ** MPFR returns MPFR");
cmp_ok($rop, '==', 3125, "MPFR ** GMP returns correct value");

$rop = $gmp_tiny ** 5;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "GMP ** IV returns GMP");
cmp_ok($rop, '==', 3125, "GMP ** IV returns correct value");

$rop = 6 ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "IV ** GMP returns GMP");
cmp_ok($rop, '==', 7776, "IV ** GMP returns correct value");
##################################
my $op_gmp = Math::GMP->new(6);
my $op_mpfr = Math::MPFR->new(5);

$op_mpfr *=  $op_gmp;
cmp_ok(ref($op_mpfr), 'eq', 'Math::MPFR', "MPFR *= GMP returns MPFR");
cmp_ok($op_mpfr, '==', 30, "MPFR *= GMP returns correct value");

$op_gmp *=  $op_mpfr;
cmp_ok(ref($op_gmp), 'eq', 'Math::MPFR', "GMP *= MPFR returns MPFR");
cmp_ok($op_gmp, '==', 180, "MPFR *= GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_mpfr = Math::MPFR->new(5);

$op_mpfr +=  $op_gmp;
cmp_ok(ref($op_mpfr), 'eq', 'Math::MPFR', "MPFR += GMP returns MPFR");
cmp_ok($op_mpfr, '==', 11, "MPFR += GMP returns correct value");

$op_gmp +=  $op_mpfr;
cmp_ok(ref($op_gmp), 'eq', 'Math::MPFR', "GMP += MPFR returns MPFR");
cmp_ok($op_gmp, '==', 17, "MPFR += GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_mpfr = Math::MPFR->new(5);

$op_mpfr /=  $op_gmp;
cmp_ok(ref($op_mpfr), 'eq', 'Math::MPFR', "MPFR /= GMP returns MPFR");
cmp_ok($op_mpfr, '==', Math::MPFR->new(5) / 6, "MPFR /= GMP returns correct value");

$op_gmp /=  $op_mpfr;
cmp_ok(ref($op_gmp), 'eq', 'Math::MPFR', "GMP /= MPFR returns MPFR");
cmp_ok($op_gmp, '==', 6 / (Math::MPFR->new(5) / 6), "MPFR /= GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_mpfr = Math::MPFR->new(5);

$op_mpfr -=  $op_gmp;
cmp_ok(ref($op_mpfr), 'eq', 'Math::MPFR', "MPFR -= GMP returns MPFR");
cmp_ok($op_mpfr, '==', -1, "MPFR -= GMP returns correct value");

$op_gmp -=  $op_mpfr;
cmp_ok(ref($op_gmp), 'eq', 'Math::MPFR', "GMP -= MPFR returns MPFR");
cmp_ok($op_gmp, '==', 7, "GMP -= MPFR returns correct value");

$op_gmp = Math::GMP->new(6);
$op_mpfr = Math::MPFR->new(5);

$op_mpfr **=  $op_gmp;
cmp_ok(ref($op_mpfr), 'eq', 'Math::MPFR', "MPFR **= GMP returns MPFR");
cmp_ok($op_mpfr, '==', 15625, "MPFR **= GMP returns correct value");

$op_gmp **=  $op_mpfr;
cmp_ok(ref($op_gmp), 'eq', 'Math::MPFR', "GMP **= MPFR returns MPFR");
cmp_ok($op_gmp, '==', 6 ** $op_mpfr, "GMP **= MPFR returns correct value"); # Line 200

##################################
cmp_ok(($gmp_tiny <=> $mpfr_big), '<', 0, "GMP_TINY <=> MPFR_BIG < 0");
cmp_ok(($mpfr_tiny <=> $gmp_big), '<', 0, "MPFR_TINY <=> GMP_BIG < 0");
cmp_ok($mpfr_big, '>', $mpfr_tiny, "MPFR_BIG > MPFR_TINY");
cmp_ok($mpfr_tiny, '<', $mpfr_big, "MPFR_TINY < MPFR_BIG");
cmp_ok($mpfr_big, '>=', $mpfr_tiny, "MPFR_BIG >= MPFR_TINY");
cmp_ok($mpfr_tiny, '<=', $mpfr_big, "MPFR_TINY <= MPFR_BIG");
cmp_ok($mpfr_tiny, '>=', $mpfr_tiny, "MPFR_TINY >= MPFR_TINY");
cmp_ok($mpfr_tiny, '<=', $mpfr_tiny, "MPFR_TINY <= MPFR_TINY");
cmp_ok($mpfr_tiny, '==', $mpfr_tiny, "MPFR_TINY == MPFR_TINY");
cmp_ok($mpfr_big, '!=', $mpfr_tiny, "MPFR_BIG != MPFR_TINY");
cmp_ok(($mpfr_tiny <=> $mpfr_tiny), '==', 0, "MPFR_TINY <=> MPFR_TINY == 0");
cmp_ok(($mpfr_big <=> $mpfr_tiny), '>', 0, "MPFR_BIG <=> MPFR_TINY > 0");

cmp_ok($gmp_big, '>', $gmp_tiny, "GMP_BIG > GMP_TINY");
cmp_ok($gmp_tiny, '<', $gmp_big, "GMP_TINY < GMP_BIG");
cmp_ok($gmp_big, '>=', $gmp_tiny, "GMP_BIG >= GMP_TINY");

cmp_ok(200, '>', $gmp_big, "200 > GMP_BIG");
cmp_ok(200, '>=', $gmp_big, "200 >= GMP_BIG");

cmp_ok($gmp_big, '<', 200, "GMP_BIG < 200");
cmp_ok($gmp_big, '<=', 200, "GMP_BIG <= 200");

cmp_ok((5 <=> $gmp_tiny), '==', 0, "5 <=> GMP_TINY == 0");
cmp_ok(($gmp_tiny <=> 5), '==', 0, "GMP_TINY <=> 5 == 0");

cmp_ok((6 <=> $gmp_tiny), '>', 0, "6 <=> GMP_TINY > 0");
cmp_ok(($gmp_tiny <=> 6), '<', 0, "GMP_TINY <=> 6 < 0");

cmp_ok($gmp_tiny, '<=', $gmp_big, "GMP_TINY <= GMP_BIG");
cmp_ok($gmp_tiny, '>=', $gmp_tiny, "GMP_TINY >= GMP_TINY");
cmp_ok($gmp_tiny, '<=', $gmp_tiny, "GMP_TINY <= GMP_TINY");
cmp_ok($gmp_tiny, '==', $gmp_tiny, "GMP_TINY == GMP_TINY");
cmp_ok($gmp_big, '!=', $gmp_tiny, "GMP_BIG != GMP_TINY");

cmp_ok(($gmp_tiny <=> $gmp_tiny), '==', 0, "GMP_TINY <=> GMP_TINY == 0");
cmp_ok(($gmp_big <=> $gmp_tiny), '>', 0, "GMP_BIG <=> GMP_TINY > 0");

done_testing();
