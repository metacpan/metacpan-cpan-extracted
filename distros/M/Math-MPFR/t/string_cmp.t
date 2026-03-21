# Main purpose here is to test Rmpfr_cmp_str which
# compares the value of a Math::MPFR object (ist arg)
# with the value held by a PV (2nd arg).
# The 2 values are compared at inifinite precision
# The overloaded comparision operators compare the
# values at default_precision.
# NOTE: mpfr_strtofr is buggy prior to mpfr-4.0.2.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

if(262146 > MPFR_VERSION) { # ie less than 4.0.2
  eval {  Rmpfr_cmp_str(Math::MPFR->new(2), '1');};
  like($@, qr/^Rmpfr_cmp_str is NA:/, "Rmpfr_cmp_str() is not implemented");
  done_testing();
  exit(0);
}

my $op1 = sqrt(Math::MPFR->new(2));
my $s = '1.41421356237309504880168872420969798';

my $cmp = Rmpfr_cmp_str($op1, $s);
cmp_ok($cmp, '==', 1,  "1: Rmpfr_cmp_str declares that the Math::MPFR object > the PV");
cmp_ok($op1, '==', $s, "2: Overloading '==' claims that the Math::MPFR object == the PV");

$s = "$op1";

$cmp = Rmpfr_cmp_str($op1, $s);
cmp_ok($cmp, '==', 1,  "3: Rmpfr_cmp_str declares that the Math::MPFR object > the PV");
cmp_ok($op1, '==', $s, "4: Overloading '==' claims that the Math::MPFR object == the PV");


$cmp = Rmpfr_cmp_str($op1, decimalize($op1));
cmp_ok($cmp, '==', 0,  "5: Rmpfr_cmp_str declares that the Math::MPFR object == the PV");
cmp_ok($op1, '==', decimalize($op1), "6: Overloading '==' claims that the Math::MPFR object == the PV");

my $op2 = Math::MPFR->new('0.1');
$s = '0.1';

$cmp = Rmpfr_cmp_str($op2, $s);
cmp_ok($cmp, '==', 1,  "7: Rmpfr_cmp_str declares that the Math::MPFR object > the PV");
cmp_ok($op2, '==', $s, "8: Overloading '==' claims that the Math::MPFR object == the PV");

$cmp = Rmpfr_cmp_str($op2, decimalize($op2));
cmp_ok($cmp, '==', 0,  "9: Rmpfr_cmp_str declares that the Math::MPFR object == the PV");
cmp_ok($op2, '==', decimalize($op2), "10: Overloading '==' claims that the Math::MPFR object == the PV");

my $op3 = Math::MPFR->new(3.5);
cmp_ok(Rmpfr_cmp_str( $op3,  '3.5'), '==', 0, "Test 11 ok");
cmp_ok(Rmpfr_cmp_str(-$op3, '-3.5'), '==', 0, "Test 12 ok");
cmp_ok(Rmpfr_cmp_str($op3,   '3.500000000000000000000000000000000000000000000000000001'), '==', -1, "Test 13 ok");
cmp_ok(Rmpfr_cmp_str(-$op3, '-3.500000000000000000000000000000000000000000000000000001'), '==',  1, "Test 14 ok");
cmp_ok(Rmpfr_cmp_str($op3,   '3.499999999999999999999999999999999999999999999999999999'), '==',  1, "Test 15 ok");
cmp_ok(Rmpfr_cmp_str(-$op3, '-3.499999999999999999999999999999999999999999999999999999'), '==', -1, "Test 16 ok");

done_testing()
