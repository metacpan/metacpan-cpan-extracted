# This file so named because it tests the fixing of a bug that had lngamma(-0) evaluate to
# NaN (instead of the correct value of +Inf).
# The bug was present in mpfr up to (and including) version 3.1.2.

use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..4\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $z = Math::MPFR->new(0);
my $neg = Math::MPFR->new(-3);
my $lng = Math::MPFR->new();

$z *= -1;

if(Rmpfr_signbit($z)) {print "ok 1\n"}
else {
  warn "\$z: $z\n";
  print "not ok 1\n";
}

Rmpfr_lngamma($lng, $z, MPFR_RNDN);

if(Rmpfr_inf_p($lng) && $lng > 0) {print "ok 2\n"}
else {
  warn "\$lng: $lng\n";
  print "not ok 2\n";
}

Rmpfr_lngamma($lng, $neg, MPFR_RNDN);

if(Rmpfr_inf_p($lng) && $lng > 0) {print "ok 3\n"}
else {
  warn "\$lng: $lng\n";
  print "not ok 3\n";
}

Rmpfr_lgamma($lng, $neg, MPFR_RNDN);

if(Rmpfr_inf_p($lng) && $lng > 0) {print "ok 4\n"}
else {
  warn "\$lng: $lng\n";
  print "not ok 4\n";
}

