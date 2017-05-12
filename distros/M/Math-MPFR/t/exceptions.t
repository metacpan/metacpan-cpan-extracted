use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..7\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $x = Rmpfr_init();
my $y = Rmpfr_init();

if(Rmpfr_underflow_p() || Rmpfr_overflow_p() || Rmpfr_inexflag_p() ||
   Rmpfr_nanflag_p() || Rmpfr_erangeflag_p()) {print "not ok 1\n"}
else {print "ok 1\n"}

Rmpfr_add($y, $y, $y, GMP_RNDN);
if(Rmpfr_nanflag_p()) {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpfr_set_ui($x, 2, GMP_RNDN);
Rmpfr_cos($x, $x, GMP_RNDN);
if(Rmpfr_inexflag_p()) {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpfr_set_ui($x, 1, GMP_RNDN);
Rmpfr_mul_2exp($x, $x, 1024, GMP_RNDN);
Rmpfr_get_ui($x, GMP_RNDN);
if(Rmpfr_erangeflag_p()) {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpfr_set_emin(-1020);
Rmpfr_set_emax(1020);

Rmpfr_set_ui($x, 1, GMP_RNDN);
Rmpfr_mul_2exp($x, $x, 1025, GMP_RNDN);
if(Rmpfr_overflow_p()) {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpfr_set_ui($x, 1, GMP_RNDN);
Rmpfr_div_2exp($x, $x, 1025, GMP_RNDN);
if(Rmpfr_underflow_p()) {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpfr_clear_flags();

if(Rmpfr_underflow_p() || Rmpfr_overflow_p() || Rmpfr_inexflag_p() ||
   Rmpfr_nanflag_p() || Rmpfr_erangeflag_p()) {print "not ok 7\n"}
else {print "ok 7\n"}




