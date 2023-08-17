use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..2\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $ok = '';

my $numerator = Math::MPFR->new(11.5);
my $denominator = Math::MPFR->new(3);
my $zero = Math::MPFR->new(0);
my $inf = Math::MPFR->new(1);
$inf /= $zero;
my $rop = Rmpfr_init();

Rmpfr_remainder($rop, $numerator, $denominator, GMP_RNDN);
if($rop == -0.5) {$ok .= 'a'}

Rmpfr_fmod($rop, $numerator, $denominator, GMP_RNDN);
if($rop == 2.5) {$ok .= 'b'}

Rmpfr_remainder($rop, $numerator, $zero, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'c'}

Rmpfr_fmod($rop, $numerator, $zero, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'd'}

Rmpfr_remquo($rop, $numerator, $zero, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'e'}

Rmpfr_remainder($rop, $inf, $denominator, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'f'}

Rmpfr_fmod($rop, $inf, $denominator, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'g'}

Rmpfr_remquo($rop, $inf, $denominator, GMP_RNDN);
if(Rmpfr_nan_p($rop)) {$ok .= 'h'}

Rmpfr_remainder($rop, $numerator, $inf, GMP_RNDN);
if($rop == $numerator) {$ok .= 'i'}

Rmpfr_fmod($rop, $numerator, $inf, GMP_RNDN);
if($rop == $numerator) {$ok .= 'j'}

Rmpfr_remquo($rop, $numerator, $inf, GMP_RNDN);
if($rop == $numerator) {$ok .= 'k'}

if($ok eq 'abcdefghijk') {print "ok 1\n"}
else {print "not ok 1 $ok \n"}

$ok = '';

$numerator += 30.5; # 42
$denominator += 14; # 17

my($q, $ret) = Rmpfr_remquo($rop, $numerator, $denominator, GMP_RNDN);

if($q == 2) {$ok .= 'a'}
if($rop == 8) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

