use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Math::Trig; # for checking results

print "1..17\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(100);

my $angle = 2.2314; #13.2314;
my $inv = 0.5123;
my $angle2 = $angle * $inv;
my $hangle = 0.1234;
my $invatanh = 0.991;
my $hinv = 1.4357;

my $sin = Rmpfr_init();
my $cos = Rmpfr_init();
my $tan = Rmpfr_init();
my $asin = Rmpfr_init();
my $acos = Rmpfr_init();
my $atan = Rmpfr_init();
my $atan2 = Rmpfr_init();
my $sinh = Rmpfr_init();
my $cosh = Rmpfr_init();
my $tanh = Rmpfr_init();
my $asinh = Rmpfr_init();
my $acosh = Rmpfr_init();
my $atanh = Rmpfr_init();
my $b_angle = Rmpfr_init();
my $b_angle2 = Rmpfr_init();
my $b_inv = Rmpfr_init();
my $b_hangle = Rmpfr_init();
my $b_invatanh = Rmpfr_init();
my $b_hinv = Rmpfr_init();
my $rop = Rmpfr_init();


Rmpfr_set_d($b_angle, $angle, GMP_RNDN);
Rmpfr_set_d($b_angle2, $angle2, GMP_RNDN);
Rmpfr_set_d($b_inv, $inv, GMP_RNDN);
Rmpfr_set_d($b_invatanh, $invatanh, GMP_RNDN);
Rmpfr_set_d($b_hinv, $hinv, GMP_RNDN);
Rmpfr_set_d($b_hangle, $hangle, GMP_RNDN);

Rmpfr_sin($sin, $b_angle, GMP_RNDN);
if($sin - sin($angle) < 0.00001 &&
   $sin - sin($angle) > -0.00001) {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpfr_cos($cos, $b_angle, GMP_RNDN);
if($cos - cos($angle) < 0.00001 &&
   $cos - cos($angle) > -0.00001) {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpfr_tan($tan, $b_angle, GMP_RNDN);
if($tan - tan($angle) < 0.00001 &&
   $tan - tan($angle) > -0.00001) {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpfr_asin($asin, $b_inv, GMP_RNDN);
if($asin - asin($inv) < 0.00001 &&
   $asin - asin($inv) > -0.00001) {print "ok 4\n"}
else {print "not ok 4\n"}

Rmpfr_acos($acos, $b_inv, GMP_RNDN);
if($acos - acos($inv) < 0.00001 &&
   $acos - acos($inv) > -0.00001) {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpfr_atan($atan, $b_inv, GMP_RNDN);
if($atan - atan($inv) < 0.00001 &&
   $atan - atan($inv) > -0.00001) {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpfr_sinh($sinh, $b_hangle, GMP_RNDN);
if($sinh - sinh($hangle) < 0.00001 &&
   $sinh - sinh($hangle) > -0.00001) {print "ok 7\n"}
else {print "not ok 7\n"}

Rmpfr_cosh($cosh, $b_hangle, GMP_RNDN);
if($cosh - cosh($hangle) < 0.00001 &&
   $cosh - cosh($hangle) > -0.00001) {print "ok 8\n"}
else {print "not ok 8\n"}

Rmpfr_tanh($tanh, $b_hangle, GMP_RNDN);
if($tanh - tanh($hangle) < 0.00001 &&
   $tanh - tanh($hangle) > -0.00001) {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpfr_asinh($asinh, $b_hinv, GMP_RNDN);
if($asinh - asinh($hinv) < 0.00001 &&
   $asinh - asinh($hinv) > -0.00001) {print "ok 10\n"}
else {print "not ok 10\n"}

Rmpfr_acosh($acosh, $b_hinv, GMP_RNDN);
if($acosh - acosh($hinv) < 0.00001 &&
   $acosh - acosh($hinv) > -0.00001) {print "ok 11\n"}
else {print "not ok 11\n"}

Rmpfr_atanh($atanh, $b_invatanh, GMP_RNDN);
if($atanh - atanh($invatanh) < 0.00001 &&
   $atanh - atanh($invatanh) > -0.00001) {print "ok 12\n"}
else {print "not ok 12\n"}

Rmpfr_sin_cos($sin, $cos, $b_angle, GMP_RNDN);
if($sin - sin($angle) < 0.00001 &&
   $sin - sin($angle) > -0.00001 &&
   $cos - cos($angle) < 0.00001 &&
   $cos - cos($angle) > -0.00001) {print "ok 13\n"}
else {print "not ok 13\n"}

Rmpfr_atan2($atan2,$b_angle2, $b_angle, GMP_RNDN);
if($atan2 - atan2($angle2, $angle) < 0.00000001 &&
   $atan2 - atan2($angle2, $angle) > -0.00000001) {print "ok 14\n"}
else {print "not ok 14 $atan2 ", atan2($angle2, $angle),"\n"}

$angle *= -1;
$b_angle *= -1;

Rmpfr_atan2($atan2,$b_angle2, $b_angle, GMP_RNDN);
if($atan2 - atan2($angle2, $angle) < 0.00000001 &&
   $atan2 - atan2($angle2, $angle) > -0.00000001) {print "ok 15\n"}
else {print "not ok 15 $atan2 ", atan2($angle2, $angle),"\n"}

# Return $angle and $b_angle to their original values:
$angle *= -1;
$b_angle *= -1;

my $ok = '';

Rmpfr_sec($rop, $b_angle, GMP_RNDN);
if($rop - sec($angle) < 0.000000001
   && $rop - sec($angle) > -0.000000001) {$ok .= 'a'}

Rmpfr_csc($rop, $b_angle, GMP_RNDN);
if($rop - csc($angle) < 0.000000001
   && $rop - csc($angle) > -0.000000001) {$ok .= 'b'}

Rmpfr_cot($rop, $b_angle, GMP_RNDN);
if($rop - cot($angle) < 0.000000001
   && $rop - cot($angle) > -0.000000001) {$ok .= 'c'}

Rmpfr_sech($rop, $b_angle, GMP_RNDN);
if($rop - sech($angle) < 0.000000001
   && $rop - sech($angle) > -0.000000001) {$ok .= 'd'}

Rmpfr_csch($rop, $b_angle, GMP_RNDN);
if($rop - csch($angle) < 0.000000001
   && $rop - csch($angle) > -0.000000001) {$ok .= 'e'}

Rmpfr_coth($rop, $b_angle, GMP_RNDN);
if($rop - coth($angle) < 0.000000001
   && $rop - coth($angle) > -0.000000001) {$ok .= 'f'}

if($ok eq 'abcdef') {print "ok 16\n"}
else {print "not ok 16 $ok\n"}

$ok = '';

Rmpfr_sinh_cosh($sinh, $cosh, $b_hinv, GMP_RNDN);
if($sinh > 1.982318 && $sinh < 1.982319) {$ok .= 'a'}
if($cosh > 2.22026726 && $cosh < 2.22026727) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 17\n"}
else {print "not ok 17 $ok\n"}

