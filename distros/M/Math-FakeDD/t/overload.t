# Test overloading of various operators.
# Overloading of '+' and '+=' is tested in t/add.t
# Overloading of '-' and '-=' is tested in t/sub.t
# Overloading of '*' and '*=' is tested in t/mul.t
# Overloading of '/' and '/=' is tested in t/div.t

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok($Math::FakeDD::VERSION, '==', 0.03, "Version number is correct");

my $obj = Math::FakeDD->new();

dd_assign($obj, '1.3');

cmp_ok(dd_stringify($obj), 'eq', sprintf("%s", $obj), "'1.3' interpolated correctly under overloading");

dd_assign($obj, 2);

my $obj2 = dd_sqrt($obj);

cmp_ok(dd_stringify($obj2), 'eq', sprintf("%s", sqrt($obj)), "sqrt(2) interpolated correctly under overloading");

cmp_ok($obj2, '==', Math::FakeDD->new(2) ** 0.5, "overloading of sqrt() == overloaded '** 0.5'");

cmp_ok(dd_eq(dd_sqrt($obj), $obj2), '==', 1, "sqrt(2) evaluated consistently");
cmp_ok(dd_sqrt($obj), '==', $obj2, "overloading of '==' ok");
cmp_ok(dd_sqrt($obj), '!=', $obj , "overloading of '!=' ok");

my $nv = sqrt 5;

cmp_ok(($obj2 == $nv), '==', 0, "the condition obj2 == nv is false");
cmp_ok(($obj2 != $nv), '!=', 0, "the condition obj2 != nv is true" );
cmp_ok(($nv == $obj2), '==', 0, "the condition nv == obj2 is false");
cmp_ok(($nv != $obj2), '!=', 0, "the condition nv != obj2 is true" );

cmp_ok(($nv   >   $obj2),  '!=', 0, "the condition nv >= obj2 is true" );
cmp_ok(($nv   >=  $obj2),  '!=', 0, "the condition nv > obj2  is true" );
cmp_ok(($nv   <=> $obj2), '>', 0, "nv > obj2" );
cmp_ok(($obj2 <=> $nv),   '<', 0, "obj2 < nv" );

cmp_ok(Math::FakeDD->new(3) ** 0.5  , '==', 3 ** Math::FakeDD->new(0.5  ), "1:'**' overloading ok");
cmp_ok(Math::FakeDD->new(3) ** '0.6', '==', 3 ** Math::FakeDD->new('0.6'), "2:'**' overloading ok");
cmp_ok(Math::FakeDD->new(3) ** 0.6  , '==', 3 ** Math::FakeDD->new(0.6  ), "3:'**' overloading ok");

my $op1 = Math::MPFR::Rmpfr_init2(2098);
my $op2 = Math::MPFR::Rmpfr_init2(2098);
my $rop1 = Math::MPFR::Rmpfr_init2(2098);
my $rop2 = Math::MPFR::Rmpfr_init2(2098);

Math::MPFR::Rmpfr_set_NV($op1, 0.6, 0);
Math::MPFR::Rmpfr_set_str($op2, '0.6', 0, 0);
Math::MPFR::Rmpfr_pow($rop1, Math::MPFR->new(3), $op1, 0);
Math::MPFR::Rmpfr_pow($rop2, Math::MPFR->new(3), $op2, 0);

cmp_ok($rop1, '!=', $rop2, "MPFR 2098-bit: 3 **0.6 != 3 ** '0.6'");

my $s1 = Math::MPFR::mpfrtoa($rop1);
my $s2 = Math::MPFR::mpfrtoa($rop2);

unless(NV_IS_DOUBLEDOUBLE) {

  # Actual doubledouble builds are too buggy
  # to be reliable here.

  cmp_ok($s1, 'ne', $s2, "MPFR 2098-bit: mpfrtoa(3**0.6) ne mpfrtoa(3**'0.6')"); # This test should fail
                                                                                 # if NV_IS_DOUBLEDOUBLE

  if(NV_IS_DOUBLE || NV_IS_80BIT_LD) {
    cmp_ok(Math::FakeDD->new($s1), '!=', Math::FakeDD->new($s2), "DD 3**0.6 != DD 3**'0.6'");
    cmp_ok(Math::FakeDD->new(3) ** 0.6  , '!=', 3 ** Math::FakeDD->new('0.6'), "4:'**' overloading ok");
  }
  else {
    # These tests should pass if NV_IS_DOUBLE
    cmp_ok(Math::FakeDD->new($s1), '==', Math::FakeDD->new($s2), "DD 3**0.6 == DD 3**'0.6'");
    cmp_ok(Math::FakeDD->new(3) ** 0.6  , '==', 3 ** Math::FakeDD->new('0.6'), "4:'**' overloading ok");
  }
}

my $check1 = Math::FakeDD->new(3);
$check1 **= '0.6';

cmp_ok($check1, '==', dd_pow(3, '0.6'), "'**=' overloading ok");

my $fudd1 = Math::FakeDD->new(2 ** 100);
my $fudd2 = $fudd1 + (2 ** - 100);

cmp_ok(dd_cmp($fudd1, $fudd2), '<', 0, "(2 ** 100) < (2 ** 100) + (2 **-100)");
cmp_ok(dd_cmp($fudd2, $fudd1), '>', 0, "(2 ** 100) + (2 **-100) > (2 ** 100)");

cmp_ok(dd_cmp($fudd1, -$fudd2), '>', 0, "(2 ** 100) < -(2 ** 100) - (2 **-100)");
cmp_ok(dd_cmp($fudd1, abs(-$fudd2)), '<', 0, "(2 ** 100) < abs(-(2 ** 100) + -(2 **-100))");

cmp_ok($fudd1, '==', int($fudd2), "(2 ** 100) < int((2 ** 100) + (2 **-100))");

my %oload = Math::FakeDD::oload();

cmp_ok(scalar keys(%oload), '==', 28, "Math::FakeDD::oload relative sizes ok");

for(0.2, 0.3, 0.4, 0.50, 0.6, 0.8, 1, 2) {

  cmp_ok( approx( (sin(Math::FakeDD->new($_)) ** 2) + (cos(Math::FakeDD->new($_)) ** 2), 0.0000000001, 1),
         '==', 1, "sin($_) and cos($_) ok");
  cmp_ok(sin(Math::FakeDD->new($_)), '==', dd_sin($_), "dd_sin($_) ok");
  cmp_ok(cos(Math::FakeDD->new($_)), '==', dd_cos($_), "dd_cos($_) ok");
}

cmp_ok(Math::FakeDD->new(1)                         , '==', 1, "Math::FakeDD->new(1) returns true");
cmp_ok(Math::FakeDD->new()                          , '==', 0, "Math::FakeDD->new() returns false");

# We currently insist that the precision of the Math::MPFR
# object passed to mpfr2dd() is 2098. Hence:

my $mpfr_nan = Math::MPFR::Rmpfr_init2(2098);
my $bool = 0;
$bool = 1 if mpfr2dd($mpfr_nan);

cmp_ok($bool, '==', 0, "Math::FakeDD->new(NaN) is false in boolean context");

my $atan1 = dd_atan2(0.5, '0.3');
cmp_ok($atan1, '==', atan2(Math::FakeDD->new(0.5), Math::FakeDD->new('0.3')), "1: atan2 ok");

my $atan2 = dd_atan2('0.3', 0.5);
cmp_ok($atan2, '==', atan2('0.3', Math::FakeDD->new(0.5)), "2: atan2 ok");

cmp_ok(approx($atan1, 0.0000000001, '1.0303768265243125'), '==', 1, "3: atan2 ok");
cmp_ok(approx($atan2, 0.0000000001, '0.54041950027058416'), '==', 1, "4: atan2 ok");

my $nan = Math::FakeDD->new('nan');

cmp_ok($nan                                   , '!=', $nan               , "NaN != NaN");
cmp_ok($nan                                   , '!=', Math::FakeDD->new(), "NaN != 0");
cmp_ok(defined($nan <=> Math::FakeDD->new(1)), '==', 0, "1: NaN with spaceship op returns undef");

cmp_ok(defined(Math::FakeDD->new(1) <=> $nan), '==', 0, "2: NaN with spaceship op returns undef");



done_testing();

sub approx {
  return 1 if($_[2] - $_[1] < $_[0] && $_[2] + $_[1] > $_[0]);
  return 0;
}
