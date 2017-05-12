use warnings;
use strict;
use Math::MPFR ':mpfr';

print "1..5\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my @mpfr1 = Rmpfr_inits(17);
if(scalar(@mpfr1) == 17) {print "ok 1\n"}
else {print "not ok 1 ", scalar(@mpfr1), "\n"}

my $ok = 1;
for(@mpfr1) {$ok = 0 if !Rmpfr_nan_p($_) }
if($ok) {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

my @mpfr2 = Rmpfr_inits2(101, 17);
if(scalar(@mpfr1) == 17) {print "ok 3\n"}
else {print "not ok 3 ", scalar(@mpfr1), "\n"}

$ok = 1;
for(@mpfr2) {$ok = 0 if !Rmpfr_nan_p($_) }
if($ok) {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

$ok = 1;
for(@mpfr2) {$ok = 0 if Rmpfr_get_prec($_) != 101 }
if($ok) {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

