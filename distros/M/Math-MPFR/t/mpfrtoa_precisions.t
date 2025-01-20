# Examine the effect that different  precisions have on mpfrtoa() output.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

# Default precision is 53 bits.

my $min_allowed_prec = RMPFR_PREC_MIN; # Older mpfr libraries set the minimum to 2 bits.

my $f1;

if($min_allowed_prec == 1) {
  $f1 = Rmpfr_init2(1);
  Rmpfr_set_IV($f1, 2, MPFR_RNDN);
}

my $f10 = Rmpfr_init2(10);
Rmpfr_set_IV($f10, 2, MPFR_RNDN);

my $f40 = Rmpfr_init2(40);
Rmpfr_set_IV($f40, 2, MPFR_RNDN);

my $f53 = Rmpfr_init2(53);
Rmpfr_set_IV($f53, 2, MPFR_RNDN);

my $f64 = Rmpfr_init2(64);
Rmpfr_set_IV($f64, 2, MPFR_RNDN);

my $f113 = Rmpfr_init2(113);
Rmpfr_set_IV($f113, 2, MPFR_RNDN);

my $power = -1074;

if($min_allowed_prec == 1) {
  $f1    **= $power; # $f1  is a  1-bit precision representation of 2 ** $power
}
$f10   **= $power; # $f1  is a  1-bit precision representation of 2 ** $power
$f40   **= $power; # $f1  is a  1-bit precision representation of 2 ** $power
$f53   **= $power; # $f53 is a 53-bit precision representation of 2 ** $power
$f64   **= $power; # $f1  is a  1-bit precision representation of 2 ** $power
$f113  **= $power; # $f1  is a  1-bit precision representation of 2 ** $power

#print mpfrtoa($_) . "\n" for ($f1, $f10, $f40, $f53, $f64, $f113);

# All 6 values are equivalent as they both have a
# binary mantissa of "1" and an exponent of $power:
if($min_allowed_prec == 1) {
  cmp_ok($f113, '==', $f1, '$f113 == $f1');
  cmp_ok($f64 , '==', $f1, '$f64  == $f1');
  cmp_ok($f53 , '==', $f1, '$f53  == $f1');
  cmp_ok($f40 , '==', $f1, '$f40  == $f1');
  cmp_ok($f10 , '==', $f1, '$f10  == $f1');
}
else {
  cmp_ok($f113, '==', $f10, '$f113 == $f10');
  cmp_ok($f64 , '==', $f10, '$f64  == $f10');
  cmp_ok($f53 , '==', $f10, '$f53  == $f10');
  cmp_ok($f40 , '==', $f10, '$f40  == $f10');
}

# However, mpfrtoa() reports different strings for all 6 values:

if($min_allowed_prec == 1) {
  cmp_ok(mpfrtoa($f1),   'eq', '5e-324',
                  '$f1    eq    5e-324');
}
cmp_ok(mpfrtoa($f10),  'eq', '4.94e-324',
                '$f10   eq    4.94e-324');
cmp_ok(mpfrtoa($f40),  'eq', '4.940656458412e-324',
                '$f40   eq    4.940656458412e-324');
cmp_ok(mpfrtoa($f53),  'eq', '4.9406564584124654e-324',
                '$f53   eq    4.9406564584124654e-324');
cmp_ok(mpfrtoa($f64),  'eq', '4.940656458412465442e-324',
                '$f64   eq    4.940656458412465442e-324');
cmp_ok(mpfrtoa($f113), 'eq', '4.940656458412465441765687928682214e-324',
                '$f113  eq    4.940656458412465441765687928682214e-324');

if(196870 <= MPFR_VERSION) {
  my @input = ($f10, $f40, $f53, $f64, $f113);
  unshift(@input, $f1) if $min_allowed_prec == 1;
  for my $in( @input) {
    cmp_ok(dragon_test($in), '==', 15, "$in passes dragon_test");
  }
}
else {
  warn "Skipping dragon_test() checks - mpfr-3.1.6 (or later) required\n";
}

done_testing();


