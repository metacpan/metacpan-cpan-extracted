use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Math::BigInt; # for some error tests

print "1..66\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(200);

my $p = Rmpfr_init();
my $q = Rmpfr_init();

my $ui = (2 ** 31) + 17;
my $negi = -1236;
my $posi = 1238;
my($posd, $negd);

if(Math::MPFR::_has_longlong()) {
   use integer;
   $posd = (2 ** 41) + 11234;
   $negd = -((2 ** 43) - 111);
}

else {
   $posd = (2 ** 41) + 11234;
   $negd = -((2 ** 43) - 111);
}
my $frac = 23.124901;

Rmpfr_set_ui($p, 1234, GMP_RNDN);
Rmpfr_set_si($q, -5678, GMP_RNDN);

my $ok = '';

my $z = $p * $q;
if(Rmpfr_get_str($z, 10,7, GMP_RNDN) eq '-7.006652e6'
   && $z == -7006652
   && "$z" eq '-7.006652e6') {$ok = 'a'}

$z = $p * $ui;
if(Rmpfr_get_str($z, 10, 13, GMP_RNDN) eq '2.649994842610e12'
   && $z == 2649994842610
   && "$z" eq '2.64999484261e12') {$ok .= 'b'}

$z = $p * $negi;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '-1.525224e6'
   && $z == -1525224
   && "$z" eq '-1.525224e6') {$ok .= 'c'}

$z = $p * $posd;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '2.713594711213924e15'
   && $z == 2713594711213924
   && "$z" eq '2.713594711213924e15'
                                    ) {$ok .= 'd'}

$z = $p * $negd;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '-1.0854378789267698e16'
   && $z == -10854378789267698
   && "$z" eq '-1.0854378789267698e16'
                                      ) {$ok .= 'e'}

$z = $p * $frac;
if($z > 28536.12783 && $z < 28536.12784) {$ok .= 'f'}

$z = $p * $posi;
if($z == 1527692) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

$p *= $q;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '-7.006652e6'
   && $p == -7006652
   && "$p" eq '-7.006652e6') {$ok = 'a'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $ui;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '2.64999484261e12'
   && $p == 2649994842610
   && "$p" eq '2.64999484261e12') {$ok .= 'b'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $negi;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '-1.525224e6'
   && $p == -1525224
   && "$p" eq '-1.525224e6') {$ok .= 'c'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $posd;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '2.713594711213924e15'
   && $p == 2713594711213924
   && "$p" eq '2.713594711213924e15') {$ok .= 'd'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $negd;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '-1.0854378789267698e16'
   && $p == -10854378789267698
   && "$p" eq '-1.0854378789267698e16') {$ok .= 'e'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $frac;
if($p > 28536.12783 && $p < 28536.12784) {$ok .= 'f'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p *= $posi;
if($p == 1527692) {$ok .= 'g'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

$z = $p + $p;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '2.468e3'
   && $z == 2468
   && "$z" eq '2.468e3') {$ok = 'a'}

$z = $p + $ui;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '2.147484899e9'
   && $z == 2147484899
   && "$z" eq '2.147484899e9') {$ok .= 'b'}

$z = $p + $negi;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '-2'
   && $z == -2
   && "$z" eq '-2') {$ok .= 'c'}

$z = $p + $posd;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '2.19902326802e12'
   && $z == 2199023268020
   && "$z" eq '2.19902326802e12') {$ok .= 'd'}

$z = $p + $negd;
if(Rmpfr_get_str($z, 10, 0, GMP_RNDN) eq '-8.796093020863e12'
   && $z == -8796093020863
   && "$z" eq '-8.796093020863e12') {$ok .= 'e'}

$z = $p + $frac;
if($z > 1257.1249 && $z < 1257.124902) {$ok .= 'f'}

$z = $p + $posi;
if($z == 2472) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($z) == 1) {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

$p += $p;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '2.468e3'
   && $p == 2468
   && "$p" eq '2.468e3') {$ok = 'a'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $ui;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '2.147484899e9'
   && $p == 2147484899
   && "$p" eq '2.147484899e9') {$ok .= 'b'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $negi;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '-2'
   && $p == -2
   && "$p" eq '-2') {$ok .= 'c'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $posd;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '2.19902326802e12'
   && $p == 2199023268020
   && "$p" eq '2.19902326802e12') {$ok .= 'd'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $negd;
if(Rmpfr_get_str($p, 10, 0, GMP_RNDN) eq '-8.796093020863e12'
   && $p == -8796093020863
   && "$p" eq '-8.796093020863e12') {$ok .= 'e'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $frac;
if($p > 1257.1249 && $p < 1257.124902) {$ok .= 'f'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

$p += $posi;
if($p == 2472) {$ok .= 'g'}
Rmpfr_set_ui($p, 1234, GMP_RNDN);

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

$ok = '';

$z = $p / $q;
if($z > -0.2174 && $z < -0.2173) {$ok = 'a'}

$z *= $q / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '1'}

$z = $p / $ui;
if($z > 5.7462e-7 && $z < 5.7463e-7) {$ok .= 'b'}

$z *= $ui / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '2'}

$z = $p / $negi;
if($z > -0.998382 && $z < -0.998381) {$ok .= 'c'}

$z *= $negi / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '3'}

$z = $p / $posd;
if($z > 5.6115822e-10  && $z < 5.6115823e-10  ) {$ok .= 'd'}

$z *= $posd / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '4'}

$z = $p / $negd;
if($z > -1.402896e-10  && $z < -1.402895e-10  ) {$ok .= 'e'}

$z *= $negd / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '5'}

$z = $p / $frac;
if($z > 53.36239  && $z < 53.362391  ) {$ok .= 'f'}

$z *= $frac / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '6'}

$z = $p / $posi;
if($z > 0.9967  && $z < 0.9968  ) {$ok .= 'g'}

$z *= $posi / $p;
if($z > 0.999 && $z < 1.001) {$ok .= '7'}

if($ok eq 'a1b2c3d4e5f6g7'
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($z) == 1) {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

$ok = '';

$p *= $ui;
$p /= $ui;
if($p < 1234.0001 && $p > 1233.9999) {$ok = 'a'}

$p *= $negi;
$p /= $negi;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'b'}

$p *= $posd;
$p /= $posd;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'c'}

$p *= $negd;
$p /= $negd;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'd'}

$p *= $frac;
$p /= $frac;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'e'}

$p *= $q;
$p /= $q;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'f'}

$p *= $posi;
$p /= $posi;
if($p < 1234.0001 && $p > 1233.9999) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 6\n"}
else {print "not ok 6 $ok\n"}

my $c = $p;
if("$c" eq '1.234e3'
   && "$c" eq "$p"
   && $c == $p
   && $c != $q
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($c) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 7\n"}
else {print "not ok 7\n"}

$c *= -1;
if(Rmpfr_get_str(abs($c), 10, 0, GMP_RNDN) eq '1.234e3'
   && Math::MPFR::get_refcnt($c) == 1) {print "ok 8\n"}
else {print "not ok 8\n"}

$ok = adjust($p!=$ui).adjust($p==$ui).adjust($p>$ui).adjust($p>=$ui).adjust($p<$ui)
.adjust($p<=$ui).adjust($p<=>$ui);
if($ok eq '100011-1') {print "ok 9\n"}
else {print "not ok 9\n"}

$ok = adjust($p!=$negi).adjust($p==$negi).adjust($p>$negi).adjust($p>=$negi)
.adjust($p<$negi).adjust($p<=$negi).adjust($p<=>$negi);
if($ok eq '1011001') {print "ok 10\n"}
else {print "not ok 10\n"}

$ok = adjust($p!=$posd).adjust($p==$posd).adjust($p>$posd).adjust($p>=$posd)
.adjust($p<$posd).adjust($p<=$posd).adjust($p<=>$posd);
if($ok eq '100011-1') {print "ok 11\n"}
else {print "not ok 11\n"}

$ok = adjust($p!=$negd).adjust($p==$negd).adjust($p>$negd).adjust($p>=$negd)
.adjust($p<$negd).adjust($p<=$negd).adjust($p<=>$negd);
if($ok eq '1011001') {print "ok 12\n"}
else {print "not ok 12\n"}

$ok = adjust($p!=$frac).adjust($p==$frac).adjust($p>$frac).adjust($p>=$frac)
.adjust($p<$frac).adjust($p<=$frac).adjust($p<=>$frac);
if($ok eq '1011001') {print "ok 13\n"}
else {print "not ok 13\n"}

$ok = adjust($ui!=$p).adjust($ui==$p).adjust($ui>$p).adjust($ui>=$p)
.adjust($ui<$p).adjust($ui<=$p).adjust($ui<=>$p);
if($ok eq '1011001') {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = adjust($negi!=$p).adjust($negi==$p).adjust($negi>$p).adjust($negi>=$p)
.adjust($negi<$p).adjust($negi<=$p).adjust($negi<=>$p);
if($ok eq '100011-1') {print "ok 15\n"}
else {print "not ok 15\n"}

$ok = adjust($posd!=$p).adjust($posd==$p).adjust($posd>$p).adjust($posd>=$p)
.adjust($posd<$p).adjust($posd<=$p).adjust($posd<=>$p);
if($ok eq '1011001') {print "ok 16\n"}
else {print "not ok 16\n"}

$ok = adjust($negd!=$p).adjust($negd==$p).adjust($negd>$p).adjust($negd>=$p)
.adjust($negd<$p).adjust($negd<=$p).adjust($negd<=>$p);
if($ok eq '100011-1') {print "ok 17\n"}
else {print "not ok 17\n"}

$ok = adjust($frac!=$p).adjust($frac==$p).adjust($frac>$p).adjust($frac>=$p)
.adjust($frac<$p).adjust($frac<=$p).adjust($frac<=>$p);
if($ok eq '100011-1'
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpfr_set_ui($q, 0, GMP_RNDN);

if($p && Math::MPFR::get_refcnt($p) == 1) {print "ok 19\n"}
else {print "not ok 19 $p\n"}

if(!$q && Math::MPFR::get_refcnt($q) == 1) {print "ok 20\n"}
else {print "not ok 20\n"}

if(not($q) && Math::MPFR::get_refcnt($q) == 1) {print "ok 21\n"}
else {print "not ok 21\n"}

unless($q || Math::MPFR::get_refcnt($q) != 1) {print "ok 22\n"}
else {print "not ok 22\n"}

$z = $c;
$z *= -1;
if($z == -$c
  && Math::MPFR::get_refcnt($z) == 1
  && Math::MPFR::get_refcnt($c) == 1) {print "ok 23\n"}
else {
  warn "\$z: $z -\$c: ", -$c, "\n";
  warn "refcounts are ", Math::MPFR::get_refcnt($z), " and ", Math::MPFR::get_refcnt($c), "\n";
  print "not ok 23\n";
}

$ok = '';

$z = $p - $p;
$z += $p;
if($z == $p) {$ok = 'a'}

$z = $p - $ui;
$z += $ui;
if($z == $p) {$ok .= 'b'}

$z = $p - $negi;
$z += $negi;
if($z == $p) {$ok .= 'c'}

$z = $p - $negd;
$z += $negd;
if($z == $p) {$ok .= 'd'}

$z = $p - $posd;
$z += $posd;
if($z == $p) {$ok .= 'e'}

$z = $p - $frac;
$z += $frac;
if($z == $p) {$ok .= 'f'}

$z = $p - $posi;
$z += $posi;
if($z == $p) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 24\n"}
else {print "not ok 24 $ok\n"}

$ok = '';

$z = $p + $p;
$z -= $p;
if($z == $p) {$ok = 'a'}

$z = $p + $ui;
$z -= $ui;
if($z == $p) {$ok .= 'b'}

$z = $p + $negi;
$z -= $negi;
if($z == $p) {$ok .= 'c'}

$z = $p + $negd;
$z -= $negd;
if($z == $p) {$ok .= 'd'}

$z = $p + $posd;
$z -= $posd;
if($z == $p) {$ok .= 'e'}

$z = $p + $frac;
$z -= $frac;
if($z == $p) {$ok .= 'f'}

$z = $p + $posi;
$z -= $posi;
if($z == $p) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 25\n"}
else {print "not ok 25 $ok\n"}

$ok = '';

$z = $p - $p;
$z += $p;
if($z == $p) {$ok = 'a'}

$z = $ui - $p;
$z -= $ui;
if($z == -$p) {$ok .= 'b'}

$z = $negi - $p;
$z -= $negi;
if($z == -$p) {$ok .= 'c'}

$z = $negd - $p;
$z -= $negd;
if($z == -$p) {$ok .= 'd'}

$z = $posd - $p;
$z -= $posd;
if($z == -$p) {$ok .= 'e'}

$z = $frac - $p;
$z -= $frac;
if($z == -$p) {$ok .= 'f'}

$z = $posi - $p;
$z -= $posi;
if($z == -$p) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 26\n"}
else {print "not ok 26 $ok\n"}

$ok = '';

$z = $p + $p;
$z -= $p;
if($z == $p) {$ok = 'a'}

$z = $ui + $p;
$z -= $ui;
if($z == $p) {$ok .= 'b'}

$z = $negi + $p;
$z -= $negi;
if($z == $p) {$ok .= 'c'}

$z = $negd + $p;
$z -= $negd;
if($z == $p) {$ok .= 'd'}

$z = $posd + $p;
$z -= $posd;
if($z == $p) {$ok .= 'e'}

$z = $frac + $p;
$z -= $frac;
if($z == $p) {$ok .= 'f'}

$z = $posi + $p;
$z -= $posi;
if($z == $p) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 27\n"}
else {print "not ok 27 $ok\n"}

$ok = ($posi!=$p).($posi==$p).($posi>$p).($posi>=$p).($posi<$p).($posi<=$p).($posi<=>$p);
if($ok eq '1011001'
   && Math::MPFR::get_refcnt($p) == 1) {print "ok 28\n"}
else {print "not ok 28\n"}

$ok = ($p!=$posi).($p==$posi).($p>$posi).($p>=$posi).($p<$posi).($p<=$posi).($p<=>$posi);
if($ok eq '100011-1') {print "ok 29\n"}
else {print "not ok 29\n"}

Rmpfr_set_ui($z, 2, GMP_RNDN);

my $root = sqrt($z);
if($root > 1.414 && $root < 1.415
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($root) == 1) {print "ok 30\n"}
else {print "not ok 30\n"}

my $root_copy = $root;

$root = $root ** 2;
$root_copy **= 2;

if($root_copy > 1.99999 && $root_copy < 2.00000001
   && $root > 1.99999 && $root < 2.00000001
   && Math::MPFR::get_refcnt($root) == 1
   && Math::MPFR::get_refcnt($root_copy) == 1) {print "ok 31\n"}
else {print "not ok 31\n"}

$z = $root ** -2;

if($z > 0.24999 && $z < 0.25001
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($root) == 1) {print "ok 32\n"}
else {print "not ok 32\n"}

$root_copy **= -2;

if($root_copy > 0.24999 && $root_copy < 0.25001
   && Math::MPFR::get_refcnt($root) == 1
   && Math::MPFR::get_refcnt($root_copy)  == 1) {print "ok 33\n"}
else {print "not ok 33\n"}

Rmpfr_set_ui($z, 2, GMP_RNDN);
Rmpfr_set_ui($root, 3, GMP_RNDN);

$p = $z ** $root;

if($p == 8
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($root) == 1) {print "ok 34\n"}
else {print "not ok 34\n"}

$z **= $root;

if($z == 8
   && Math::MPFR::get_refcnt($root) == 1
   && Math::MPFR::get_refcnt($z)  == 1) {print "ok 35\n"}
else {print "not ok 35\n"}

Rmpfr_set_ui($z, 2, GMP_RNDN);
Rmpfr_set_si($root, -3, GMP_RNDN);

$p = $z ** $root;

if($p == 0.125
   && Math::MPFR::get_refcnt($z) == 1
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($root) == 1) {print "ok 36\n"}
else {print "not ok 36\n"}

$z **= $root;

if($z == 0.125
   && Math::MPFR::get_refcnt($root) == 1
   && Math::MPFR::get_refcnt($z)  == 1) {print "ok 37\n"}
else {print "not ok 37\n"}

my $s = sin($p);
$c = cos($p);

$s **= 2;
$c **= 2;

if($s + $c < 1.0001 && $s + $c > 0.9999
   && Math::MPFR::get_refcnt($s) == 1
   && Math::MPFR::get_refcnt($c) == 1) {print "ok 38\n"}
else {print "not ok 38\n"}

Rmpfr_set_ui($c, 10, GMP_RNDN);

$s = log($c);

if($] >= 5.008) {
  my $int = int($s);
  if(int($s) == 2 && $int == 2
    && Math::MPFR::get_refcnt($s) == 1
    && Math::MPFR::get_refcnt($int) == 1) {print "ok 39\n"}
  else {print "not ok 39\n"}
  }
else {
  warn "Skipping test 39 - no overloading of 'int' on perl $]\n";
  print "ok 39\n";
}

$s = exp($s);

if($s < 10.0001 && $s > 0.9999
   && Math::MPFR::get_refcnt($s) == 1
   && Math::MPFR::get_refcnt($c) == 1) {print "ok 40\n"}
else {print "not ok 40\n"}

Rmpfr_set_ui($s, 3, GMP_RNDN);

$ok = '';

my $y_atan2 = Rmpfr_init();
Rmpfr_set_d($y_atan2, 2.07, GMP_RNDN);
my $atan2 = Rmpfr_init();

my $x_atan2 = 2 ** 31 + 2;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'z'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'a'}

$x_atan2 *= -1;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'b'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'c'}

$x_atan2 = 2;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'd'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'e'}

$x_atan2 *= -1;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'f'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'g'}

$x_atan2 *= 0.50123;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'h'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'i'}

$x_atan2 *= -1;

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'j'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'k'}

$x_atan2 = "1.988766";

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'l'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'm'}

$x_atan2 = "-1.988766";

$atan2 = atan2($y_atan2, $x_atan2);
if($atan2 - atan2(2.07, $x_atan2) < 0.0000001 &&
   $atan2 - atan2(2.07, $x_atan2) > -0.0000001) {$ok .= 'n'}

$atan2 = atan2($x_atan2, $y_atan2);
if($atan2 - atan2($x_atan2, 2.07) < 0.0000001 &&
   $atan2 - atan2($x_atan2, 2.07) > -0.0000001) {$ok .= 'o'}

if($ok eq 'zabcdefghijklmno'
  && Math::MPFR::get_refcnt($atan2) == 1
  && Math::MPFR::get_refcnt($y_atan2) == 1) {print "ok 41\n"}
else {print "not ok 41 $ok\n"}

Rmpfr_set_d($p, 81, GMP_RNDN);
$q = $p ** 0.5;

if($q == 9) {print "ok 42\n"}
else {print "not ok 42\n"}

Rmpfr_set_d($p, 2, GMP_RNDN);
$q = 0.5 ** $p;

if($q == 0.25) {print "ok 43\n"}
else {print "not ok 43\n"}

Rmpfr_set_d($p, 36, GMP_RNDN);

$p **= 0.5;
if($p == 6
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 44\n"}
else {print "not ok 44\n"}

my $mbi = Math::BigInt->new(112345);
$ok = '';

eval{$q = $p + $mbi;};
if($@ =~ /Invalid argument/) {$ok = 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'd'}
eval{$q = $p ** $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'e'}
eval{$p += $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'i'}
eval{$p **= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'j'}

if($ok eq 'abcdefghij') {print "ok 45\n"}
else {print "not ok 45 $ok\n"}

$mbi = "this is a string";
$ok = '';

$q = $p + $mbi;
if($q == $p) {$ok = 'a'}

$q = $p * $mbi;
if($q == 0) {$ok .= 'b'}

$q = $p - $mbi;
if($q == $p) {$ok .= 'c'}

$q = $p / $mbi;
if(Rmpfr_inf_p($q)) {$ok .= 'd'}

$q = $p ** $mbi;
if($q == 1) {$ok .= 'e'}

$q = $p;

$p += $mbi;
if($q == $p) {$ok .= 'f'}

$p *= $mbi;
if($p == 0) {$ok .= 'g'}

$p -= $mbi;
if($p == 0) {$ok .= 'h'}

$p /= $mbi;
if(Rmpfr_nan_p($p)) {$ok .= 'i'}

$p **= $mbi;
if($p == 1) {$ok .= 'j'}

if($p >$mbi) {$ok .= 'k'}

unless($p <$mbi) {$ok .= 'l'}

if($p >= $mbi) {$ok .= 'm'}

unless($p <= $mbi) {$ok .= 'n'}

if($p <=> $mbi) {$ok .= 'o'}

unless($p == $mbi) {$ok .= 'p'}

if($p != $mbi) {$ok .= 'q'}

if($ok eq 'abcdefghijklmnopq') {print "ok 46\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 46 $ok\n";
}

$mbi = "-111111111111112.34567879";
Rmpfr_set_si($p, 1234, GMP_RNDN);

$q = $p + $mbi;
$p = $q - $mbi;
$q = $p * $mbi;
$p = $q / $mbi;

if($p == 1234
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 47\n"}
else {print "not ok 47\n"}

$p *= $mbi;
$p /= $mbi;
$p += $mbi;
$p -= $mbi;

if($p == 1234
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 48\n"}
else {print "not ok 48\n"}

$q = $mbi + $p;
$p = $mbi - $q;

if($p == -1234
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 49\n"}
else {print "not ok 49\n"}

$q = $mbi * $p;
$p = $mbi / $q;

if($p < -0.00081 && $p > -0.000811
   && Math::MPFR::get_refcnt($p) == 1
   && Math::MPFR::get_refcnt($q) == 1) {print "ok 50\n"}
else {print "not ok 50\n"}

Rmpfr_set_str($p, "1234567.123", 10, GMP_RNDN);

if($p > $mbi &&
   $p >= $mbi &&
   $mbi < $p &&
   $mbi <= $p &&
   ($p <=> $mbi) > 0 &&
   ($mbi <=> $p) < 0 &&
   $p != $mbi &&
   !($p == $mbi) &&
   Math::MPFR::get_refcnt($p) == 1) {print "ok 51\n"}
else {print "not ok 51\n"}

$mbi = \$p;
$ok = '';

eval{$q = $p + $mbi;};
if($@ =~ /Invalid argument/) {$ok = 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'd'}
eval{$q = $p ** $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'e'}
eval{$p += $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'i'}
eval{$p **= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'j'}

if($ok eq 'abcdefghij') {print "ok 52\n"}
else {print "not ok 52 $ok\n"}

my $p_copy = $p;
$p_copy += 1;
if($p_copy - $p == 1) {print "ok 53\n"}
else {print "not ok 53\n"}

$ok = '';

Rmpfr_set_str($z, '0.0e10', 10, GMP_RNDN);
if("$z" eq '0') {$ok = 'a'}

Rmpfr_set_str($z, '0.0e-10', 10, GMP_RNDN);
if("$z" eq '0') {$ok .= 'b'}

Rmpfr_set_str($z, '0.0e10', 10, GMP_RNDN);
if("$z" eq '0') {$ok .= 'c'}

Rmpfr_set_str($z, '0.0e-10', 10, GMP_RNDN);
if("$z" eq '0') {$ok .= 'd'}

Rmpfr_set_str($z, '0.0E10', 10, GMP_RNDN);
if("$z" eq '0') {$ok .= 'e'}

Rmpfr_set_str($z, '0.0E-10', 10, GMP_RNDN);
if("$z" eq '0') {$ok .= 'f'}

Rmpfr_set_str($z, '1.0', 10, GMP_RNDN);
if("$z" eq '1') {$ok .= 'g'}

Rmpfr_set_str($z, '-1.0', 10, GMP_RNDN);
if("$z" eq '-1') {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 54\n"}
else {print "not ok 54 $ok\n"}

$ok = '';

my $nan = Math::MPFR->new();

$ok .= 'a' if lc(Math::MPFR::overload_string($nan, 10, 0, GMP_RNDN)) eq 'nan';

my ($man, $exp) = Rmpfr_deref2($nan, 10, 0, GMP_RNDN);

$ok .= 'b' if lc($man) eq '@nan@';

my $one = Math::MPFR->new(1);
my $minus_one = Math::MPFR->new(-1);
my $zero = Math::MPFR->new(0);
my $minus_zero = Math::MPFR->new(-0.0);

my $inf = $one / $zero;
$ok .= 'c' if lc(Math::MPFR::overload_string($inf)) eq 'inf';

$inf = $minus_one / $minus_zero;
$ok .= 'd' if lc(Math::MPFR::overload_string($inf)) eq 'inf';

$inf = $one / $minus_zero;
$ok .= 'e' if lc(Math::MPFR::overload_string($inf)) eq '-inf';

$inf = $minus_one / $zero;
$ok .= 'f' if lc(Math::MPFR::overload_string($inf)) eq '-inf';

$ok .= 'g' if Math::MPFR::overload_string($zero) eq '0';
$ok .= 'h' if Math::MPFR::overload_string($minus_zero) eq '-0';

my $minus_zero2 = Math::MPFR->new(-0);
$ok .= 'i' if Math::MPFR::overload_string($minus_zero2) eq '0';
$ok .= 'j' if lc(Math::MPFR::overload_string($zero / $minus_zero)) eq 'nan';

if($ok eq 'abcdefghij') {print "ok 55\n"}
else {print "not ok 55 $ok\n"}

$ok = '';

$ok .= 'A' if $nan;
$ok .= $nan ? 'B' : 'b';
$ok .= 'c' if $one;
$ok .= 'D' if $zero;
$ok .= 'e' if !$nan;
$ok .= $one ? 'f' : 'F';
$ok .= $zero ? 'G' : 'g';

if($ok eq 'bcefg') {print "ok 56\n"}
else {print "not ok 56 $ok\n"}

my $next = Math::MPFR->new(200);

if(Math::MPFR::overload_string($next) eq '2e2') {print "ok 57\n"}
else {print "not ok 57\n"}

$zero *= -1;

if(Math::MPFR::overload_string($zero) eq '-0') {print "ok 58\n"}
else {print "not ok 58\n"}

$zero ? print "not ok 59\n" : print "ok 59\n";

# testing overload_copy subroutine precision handling.
# current default precision is 200.

$ok = '';

my $mpfr1 = Rmpfr_init2(100);
Rmpfr_set_ui($mpfr1, 1234, GMP_RNDN);

my $mpfr2 = $mpfr1;
$ok .= 'a' if Rmpfr_get_prec($mpfr2) == 100;
$mpfr2 *= 2;
$ok .= 'b' if $mpfr2 == 2468 && $mpfr1 == 1234
       && Rmpfr_get_prec($mpfr1) == 100
       && Rmpfr_get_prec($mpfr2) == 100;

my $mpfr3 = $mpfr1;
$mpfr1 *= 2;

$ok .= 'c' if $mpfr1 == 2468 && $mpfr3 == 1234
       && Rmpfr_get_prec($mpfr1) == 100
       && Rmpfr_get_prec($mpfr3) == 100;

if($ok eq 'abc'){print "ok 60\n"}
else {print "not ok 60 $ok\n"}

$ok = '';

$mpfr1 += 0.5;

$mpfr1++;
$ok .= 'a' if $mpfr1 == 2469.5;

++$mpfr1;
$ok .= 'b' if $mpfr1 == 2470.5;

$mpfr1--;
$ok .= 'c' if $mpfr1 == 2469.5;

--$mpfr1;
$ok .= 'd' if $mpfr1 == 2468.5;

if($ok eq 'abcd') {print "ok 61\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 61\n";
}

my $unblessed = Rmpfr_init_nobless();
my $blessed = Rmpfr_init();

if(Math::MPFR::_isobject($blessed)) { print "ok 62\n"}
else {print "not ok 62\n"}

unless(Math::MPFR::_isobject($unblessed)) { print "ok 63\n"}
else {print "not ok 63\n"}

if(Math::MPFR::nnumflag() == 17) { print "ok 64\n" }
else {
  warn "nnumflag(): expected 17, got ", Math::MPFR::nnumflag(), "\n";
  print "not ok 64\n";
}

Math::MPFR::clear_nnum();

if(Math::MPFR::nnumflag() == 0) { print "ok 65\n" }
else {
  warn "nnumflag(): expected 0, got ", Math::MPFR::nnumflag(), "\n";
  print "not ok 65\n";
}

Math::MPFR::set_nnum(16);

if(Math::MPFR::nnumflag() == 16) { print "ok 66\n" }
else {
  warn "nnumflag(): expected 16, got ", Math::MPFR::nnumflag(), "\n";
  print "not ok 66\n";
}

sub adjust {
    if($_[0]) {
      if($_[0] > 0) { return 1}
      return -1;
      }
    return 0;
}

