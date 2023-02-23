# Just some additional tests to check that ~0, unsigned and signed longs are
# are being handled as expected.

use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Config;

print"1..6\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(65);

my $n = ~0;

my $mpfr1 = Math::MPFR::new($n);
my $mpfr2 = Math::MPFR->new($n);
my ($mpfr3, $info3) = Rmpfr_init_set_ui($n, GMP_RNDN);
my ($mpfr4, $info4) = Rmpfr_init_set_si($n, GMP_RNDN);

if($mpfr4 == -1) {print "ok 1\n"}
else {print "not ok 1\n"}

if($mpfr1 == $n &&
   $mpfr2 == $n ) {print "ok 2\n"}
else {print "not ok 2\n"}

if(Math::MPFR::_has_longlong() &&
   $Config::Config{longsize} == 4) {
   if($mpfr3 != $n) {print "ok 3 A\n"}
   else {print "not ok 3 A $mpfr3 == $n\n"}
}

else {
  if($n == $mpfr3) {print "ok 3 B \n"}
  else {print "not ok 3 B $mpfr3 != $n\n"}
}

my $ok = '';

# Check the overloaded operators.
# But skip these tests 4a to 4h (as they fail) if
# $] < 5.007 and perl was built with -Duse64bitint
# but without -Duselongdouble
if(!($] < 5.007 && !Math::MPFR::_has_longdouble() && Math::MPFR::_has_longlong())) {
  if($mpfr1 - 1 == $n - 1) {$ok .= 'a'}
  else {warn "4a: ", $mpfr1 - 1, " != ", $n - 1}

  $mpfr1 -= 1;

  if($mpfr1 == $n - 1) {$ok .= 'b'}
  else {warn "4b: ", $mpfr1, " != ", $n - 1}

  $mpfr1 = $mpfr1 / 2;

  if($mpfr1 == ($n - 1) / 2) {$ok .= 'c'}
  else {
    my $t = ($n - 1) / 2;
    warn "4c: ", $mpfr1, " != ", $t;
  }

  $mpfr1 = $mpfr1 * 2;

  if($mpfr1 == $n - 1) {$ok .= 'd'}
  else {warn "4d: ", $mpfr1, " != ", $n - 1}

  $mpfr1 /= 2;

  if($mpfr1 == ($n - 1) / 2) {$ok .= 'e'}
  else {
    my $t = ($n - 1) / 2;
    warn "4e: ", $mpfr1 - 1, " != ", $t;
  }

  $mpfr1 *= 2;

  if($mpfr1 == $n - 1) {$ok .= 'f'}
  else {warn "4f: ", $mpfr1, " != ", $n - 1}

  if($mpfr1 + 1 == $n) {$ok .= 'g'}
  else {warn "4g: ", $mpfr1 + 1, " != ", $n}

  $mpfr1 += 1;

  if($mpfr1 == $n) {$ok .= 'h'}
  else {warn "4h: ", $mpfr1, " != ", $n}
}
else {
  warn "Skipping tests 4a to 4h as they fail on perl 5.6\nbuilt with -Duse64bitint but without -Duselongdouble\n";
  $ok = 'abcdefgh';
}

#my $bits = Math::MPFR::_has_longlong() ? 32 : 16;
my $bits = $Config{ivsize} > 4 ? 32 : 16;

if($mpfr1 ** 0.5 < 2 ** $bits &&
   $mpfr1 ** 0.5 > (2 ** $bits) - 1 ) {$ok .= 'i'}

$mpfr1 **= 0.5;

if($mpfr1 < 2 ** $bits &&
   $mpfr1 > (2 ** $bits) - 1) {$ok .= 'j'}

if($ok eq 'abcdefghij') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

if(Math::MPFR::_has_longlong()) {
  my $ul;
  if($Config::Config{cc} eq 'cl') {
    $ul = Rmpfr_integer_string($mpfr2, 10, GMP_RNDN);
  }
  else {$ul = Rmpfr_get_uj($mpfr2, GMP_RNDN)}
  if($ul == $n) {print "ok 5\n"}
  else {print "not ok 5 $ul != $n\n"}
}
else {
  warn "Skipping test 5 - no 'long long' support\n";
  print "ok 5\n";
}

$ok = '';

Rmpfr_set_str($mpfr1, ~0, 10, GMP_RNDN);
my $string = Rmpfr_integer_string($mpfr1, 10, GMP_RNDN);

if($string == ~0) {$ok .= 'a'}
else {print "$string != ", ~0, "\n"}

$mpfr1 += 0.25;

$string = Rmpfr_integer_string($mpfr1, 10, GMP_RNDN);

if($string == ~0) {$ok .= 'b'}
else {print "$string != ", ~0, "\n"}

if(Math::MPFR::_has_longdouble()) {
  Rmpfr_set_ld($mpfr1, (~0 - 1) / -2, GMP_RNDN);
}
elsif(Math::MPFR::_has_longlong()){
  if(Math::MPFR::_has_inttypes()) {
    Rmpfr_set_sj($mpfr1, (~0 - 1) / -2, GMP_RNDN);
  }
  else {Rmpfr_set_str($mpfr1, (~0 - 1) / -2, 10, GMP_RNDN)}
}
elsif($Config{ivsize} >= 8) { # Not a 'long long'; must be a 'long'
  Rmpfr_set_si($mpfr1, (~0 - 1) / -2, GMP_RNDN);
}
else {
  Rmpfr_set_d($mpfr1, (~0 - 1) / -2, GMP_RNDN);
}
$string = Rmpfr_integer_string($mpfr1, 10, GMP_RNDN);

if($string == (~0 - 1) / -2) {$ok .= 'c'}
else {print "$string != ", (~0 - 1) / -2, "\n"}

$mpfr1 -= 0.25;

$string = Rmpfr_integer_string($mpfr1, 10, GMP_RNDN);

if($string == (~0 - 1) / -2) {$ok .= 'd'}
else {print "$string != ", (~0 - 1) / -2, "\n"}

if($ok eq 'abcd') {print "ok 6\n"}
else {print "not ok 6 $ok \n"}




