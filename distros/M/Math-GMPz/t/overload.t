use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Math::BigFloat; # for some error checking
#use Devel::Peek;

print "1..44\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $have_mpf = 0;
my $have_mpq = 0;
my($float, $rat);
my ($p1, $p2);

eval{require Math::GMPf};
if(!$@) {
  $have_mpf = 1;
  $float = Math::GMPf::Rmpf_init_set_d(2.5);
  }

eval{require Math::GMPq};
if(!$@) {
  $have_mpq = 1;
  $rat = Math::GMPq::Rmpq_init();
  Math::GMPq::Rmpq_set_d($rat, 2.5);
  }

my $str = '12345';
my $x = Rmpz_init_set_str($str, 10);
my $y = Rmpz_init_set_str('7', 10);

my $z = 2 * $x * $y * (2 ** 35);
$z = -9 + $z + $y + -107 + ((2 ** 34) * -1);
$z = $z + 109 + (2 ** 34);

if("$z" eq '5938393582141440'
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 1\n"}
else {print "not ok 1\n"}

$z *= 11;
$z *= -3;
$z *= $y;
$z *= 2 ** 33;
$z *= $z;

if("$z" eq '138848639908977408444709674076474850607440061702497894400'
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 2\n"}
else {print "not ok 2\n"}

$z = sqrt($z);
$z /= 2 ** 33;
$z /= $y;
$z /= -3;
$z /= 11;

if("$z" eq '-5938393582141440'
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 3\n"}
else {print "not ok 3\n"}

my $m = 4294967295; #~0;

$z += 11234;
$z += -11234;
$z += $m;
$z += -$m;

$z += $y;
$z += ($y * -1);
$z += 2 ** 37;
$z += (2 ** 37) * -1;

if("$z" eq '-5938393582141440'
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 4\n"}
else {print "not ok 4 $z\n"}

$z -= 11234;
$z -= -11234;
$z -= $m;
$z -= -$m;
$z -= $y;
$z -= ($y * -1);
$z -= 2 ** 37;
$z -= (2 ** 37) * -1;

if("$z" eq '-5938393582141440'
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 5\n"}
else {print "not ok 5\n"}

my $z2 = -13 - $z;
$z2 = $z2 - (2 ** 39);
$z2 += (2 ** 39) - -13;
$z2 *= -1;

if("$z" eq '-5938393582141440'
   && Math::GMPz::get_refcnt($z2) == 1) { print "ok 6\n"}
else {print "not ok 6\n"}

$z2 = $z - 1118;
$z2 = $z2 - -1118;
$z2 = $z2 - $m;
$z2 = $z2 - -$m;
$z2 = $z2 - $y;
$z2 = $z2 - ($y * -1);
$z2 = $z2 - (2 ** 44);
$z2 = $z2 - ((2 ** 44) * -1);

if("$z2" eq '-5938393582141440'
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z) == 1) { print "ok 7\n"}
else {print "not ok 7\n"}

$z2 = 11176 - $z;
my $z3 = -11176 - $z;
$z3 -= $z2;
$z3 = $m - $z3;
$z3 = -$m - $z3;
$z3 = (2 ** 46) - $z3;
$z3 = ((2 ** 46) * -1) - $z3;

if("$z3" eq '-140746078312270'
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z3) == 1) { print "ok 8\n"}
else {print "not ok 8\n"}

my $ok = '';

$z = 112 / $x;
$z2 = -112 / $x;
if(Rmpz_get_str($z + $z2, 10) eq '0') {$ok = 'a'}

$z = 24689 / $x;
$z2 = -24689 / $x;
if(Rmpz_get_str($z - $z2, 10) eq '2') {$ok .= 'b'}

$z = $m / $x;
$z2 = -$m / $x;

if(Rmpz_get_str($z - $z2, 10) eq '695822') {$ok .= 'c'}

$z = (2 ** 47) / $x;
$z2 = ((2 ** 47) * -1) / $x;
if(Rmpz_get_str($z - $z2, 10) eq '22800727152') {$ok .= 'd'}

$z = $x / $y;
$z2 = -$x / $y;
if(Rmpz_get_str($z - $z2, 10) eq '3526') {$ok .= 'e'}

if($ok eq 'abcde'
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z3) == 1) { print "ok 9\n"}
else {print "not ok 9 $ok\n"}

$ok = '';

$z = $x / 10;
$z2 = ($x * -1) / 10;
if(Rmpz_get_str($z - $z2, 10) eq '2468') {$ok = 'a'}

$z =  $x / $m;
$z2 = ($x * -1) / $m;

if(Rmpz_get_str($z - $z2, 10) eq '0') {$ok .= 'b'}

$z =  $x / (2 ** 47);
$z2 = ($x * -1) / (2 ** 47);
if(Rmpz_get_str($z - $z2, 10) eq '0') {$ok .= 'c'}

if($ok eq 'abc'
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z3) == 1) { print "ok 10\n"}
else {print "not ok 10 $ok\n"}

my $z4 = Rmpz_init_set_str("9999999999999999999999999999999999999999999999999999", 10);
$z += $z4;

$ok = '';

$z2 = 23 % $z4;
$z3 = -23 % $z4;
if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok = 'a'}

$z4*= -1;
$z2 = 23 % $z4;
$z3 = -23 % $z4;
if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'b'}

$z2 = $m % $z4;
$z3 = -$m % $z4;

if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'c'}

$z4 *= -1;
$z2 = $m % $z4;
$z3 = -$m % $z4;
if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'd'}

$z2 = ((2 ** 41) + 12345) % $z4;
$z3 = -((2 ** 41) + 12345) % $z4;
if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'e'}

$z4 = -$z4;
$z2 = ((2 ** 41) + 12345) % $z4;
$z3 = -((2 ** 41) + 12345) % $z4;
if(Rmpz_get_str($z2 + $z3, 16) eq Rmpz_get_str($z, 16)
   && $z2 + $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'f'}

$z2 = $z4 % 23;
$z4 = -$z4;
$z3 = $z4 % 23;
if(Rmpz_get_str($z2 + $z3, 10) eq '23'
   && $z2 + $z3 == 23
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'g'}

$z2 = $z4 % -23;
$z4*= -1;
$z3 = $z4 % -23;
if(Rmpz_get_str($z2 + $z3, 10) eq '23'
   && $z2 + $z3 == 23
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'h'}

$z2 = $z4 % $m;
$z4 = -$z4;
$z3 = $z4 % $m;
if(Rmpz_get_str($z2 + $z3, 10) eq "$m"
   && $z2 + $z3 == $m
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z3) == 1) {$ok .= 'i'}

$z2 = $z4 % -$m;
$z4 = -$z4;
$z3 = $z4 % -$m;
if(Rmpz_get_str($z2 + $z3, 10) eq "$m"
   && $z2 + $z3 == $m
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {$ok .= 'j'}

my $w = (2 ** 41) + 12345;

$z2 = $z4 % ((2 ** 41) + 12345);
$z4*= -1;
$z3 = $z4 % ((2 ** 41) + 12345);
if(Rmpz_get_str($z2 + $z3, 10) eq "$w"
   && $z2 + $z3 == $w
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {$ok .= 'k'}


$z2 = $z4 % -((2 ** 41) + 12345);
$z4 *= -1;
$z3 = $z4 % -((2 ** 41) + 12345);
if(Rmpz_get_str($z2 + $z3, 10) eq "$w"
   && $z2 + $z3 == $w
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {$ok .= 'l'}

if($ok eq 'abcdefghijkl') {print "ok 11\n"}
else {print "not ok 11 $ok\n"}

$ok = '';

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= 23;
$z3 = -$z3;
$z3 %= 23;
if(Rmpz_get_str($z2 + $z3, 10) eq '23'
   && $z2 + $z3 == 23) {$ok = 'g'}

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= -23;
$z3 = -$z3;
$z3 %= -23;
if(Rmpz_get_str($z2 + $z3, 10) eq '23'
   && $z2 + $z3 == 23) {$ok .= 'h'}

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= $m;
$z3 = -$z3;
$z3 %= $m;
if(Rmpz_get_str($z2 + $z3, 10) eq "$m"
   && $z2 + $z3 == $m) {$ok .= 'i'}

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= -$m;
$z3 *= -1;
$z3 %= -$m;
if(Rmpz_get_str($z2 + $z3, 10) eq "$m"
   && $z2 + $z3 == $m) {$ok .= 'j'}

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= ((2 ** 41) + 12345);
$z3*= -1;
$z3 %= ((2 ** 41) + 12345);
if(Rmpz_get_str($z2 + $z3, 10) eq "$w"
   && $z2 + $z3 == $w) {$ok .= 'k'}

Rmpz_set($z2, $z4);
Rmpz_set($z3, $z4);
$z2 %= -((2 ** 41) + 12345);
$z3 = -$z3;
$z3 %= -((2 ** 41) + 12345);
if(Rmpz_get_str($z2 + $z3, 10) eq "$w"
   && $z2 + $z3 == $w) {$ok .= 'l'}

if($ok eq 'ghijkl'
   && Math::GMPz::get_refcnt($z2) == 1
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z3) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {print "ok 12\n"}
else {print "not ok 12\n"}

$z++;
if("$z" eq '10000000000000000000000000000000000000000000000000000'
   && Math::GMPz::get_refcnt($z) == 1) {print "ok 13\n"}
else {print "not ok 13\n"}

$z--;

if("$z" eq '9999999999999999999999999999999999999999999999999999'
   && Math::GMPz::get_refcnt($z) == 1) {print "ok 14\n"}
else {print "not ok 14\n"}

$z = -$z;

$z4 = abs($z);

if(Rmpz_get_str($z4 + $z, 16) eq '0'
   && $z4 + $z == 0
   && !($z4 + $z)
   && not($z4 + $z)
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {print "ok 15\n"}
else {print "not ok 15\n"}

$z = $z4 << 10;
$z >>= 10;

if("$z" eq "$z4"
   && $z == $z4
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {print "ok 16\n"}
else {print "not ok 16\n"}

$z4 <<= 10;
$z = $z4 >> 10;
$z <<= 10;

if("$z" eq "$z4"
   && $z == $z4
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {print "ok 17\n"}
else {print "not ok 17\n"}

$z = $z4 ** 2;
$z3 = sqrt($z);
$z3 **= 2;

if("$z3" eq "$z"
   && $z3 == $z
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z3) == 1
   && Math::GMPz::get_refcnt($z4) == 1) {print "ok 18\n"}
else {print "not ok 18\n"}

my $mers = Rmpz_init_set_str('1' x 2000, 2);

$ok = '';

my $and = $mers & 1234;
if("$and" eq '1234'
   && $and == 1234
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$and = $mers & $m;
if("$and" eq "$m"
   && $and == $m
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$and = $mers & $w;
if("$and" eq "$w"
   && $and == $w
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$and = $mers & $z;
if("$and" eq "$z"
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 19\n"}
else {print "not ok 19 $ok\n"}

$ok = '';

my $ior = $mers | 1234;
if("$ior" eq "$mers"
   && $ior == $mers
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$ior = $mers | $m;
if("$ior" eq "$mers"
   && $ior == $mers
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$ior = $mers | $w;
if("$ior" eq "$mers"
   && $ior == $mers
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$ior = $mers | $z;
if("$ior" eq "$mers"
   && $ior == $mers
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 20\n"}
else {print "not ok 20 $ok\n"}

$ok = '';

my $xor = $mers ^ 1234;
if("$xor" eq Rmpz_get_str($mers - 1234, 10)
   && $xor == $mers - 1234
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$xor = $mers ^ $m;
if("$xor" eq Rmpz_get_str($mers - $m, 10)
   && $xor == $mers - $m
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$xor = $mers ^ $w;
if("$xor" eq Rmpz_get_str($mers - $w, 10)
   && $xor == $mers - $w
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$xor = $mers ^ $z;
if("$xor" eq Rmpz_get_str($mers - $z, 10)
   && $xor == $mers - $z
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 21\n"}
else {print "not ok 21 $ok\n"}

$ok = '';

$and = $mers;
$and &= 1234;
if("$and" eq '1234'
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$and = $mers * 1;
$and &= $m;
if("$and" eq "$m"
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$and = $mers;
$and &= $w;
if("$and" eq "$w"
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$and = $mers + 0;
$and &= $z;
if("$and" eq "$z"
   && Math::GMPz::get_refcnt($and) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 22\n"}
else {print "not ok 22 $ok\n"}

$ok = '';

$ior = $mers * 1;
$ior |= 1234;
if("$ior" eq "$mers"
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$ior = $mers - 0;
$ior |= $m;
if("$ior" eq "$mers"
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$ior = $mers;
$ior |= $w;
if("$ior" eq "$mers"
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$ior = $mers;
$ior |= $z;
if("$ior" eq "$mers"
   && Math::GMPz::get_refcnt($ior) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 23\n"}
else {print "not ok 23 $ok\n"}

$ok = '';

$xor = $mers;
$xor ^= 1234;
if("$xor" eq Rmpz_get_str($mers - 1234, 10)
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok = 'a'}

$xor = $mers;
$xor ^= $m;
if("$xor" eq Rmpz_get_str($mers - $m, 10)
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'b'}

$xor = $mers;
$xor ^= $w;
if("$xor" eq Rmpz_get_str($mers - $w, 10)
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'c'}

$xor = $mers;
$xor ^= $z;
if("$xor" eq Rmpz_get_str($mers - $z, 10)
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($mers) == 1) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 24\n"}
else {print "not ok 24 $ok\n"}

$xor = ~$x;

if("$xor" eq "-12346"
   && Math::GMPz::get_refcnt($xor) == 1
   && Math::GMPz::get_refcnt($x) == 1) {print "ok 25\n"}
else {print "not ok 25\n"}

my $bul = Rmpz_init_set_str("$m", 10);
my $bsi1 = Rmpz_init_set_str("1234", 10);
my $bsi2 = Rmpz_init_set_str("-1234", 10);
my $bd = Rmpz_init_set_str("$w", 10);
my $mers_copy = $mers;

$ok = ($mers > 1234) . ($mers > -1234) . ($mers > $m) . ($mers > -$m) . ($mers > $w) . ($mers > -$w) . ($mers > $z) . ($mers > -$z)
    . ($mers >= 1234) . ($mers >= -1234) . ($mers >= $m) . ($mers >= -$m) . ($mers >= $w) . ($mers >= -$w) . ($mers >= $z) . ($mers >= -$z)
    . ($mers < 1234) . ($mers < -1234) . ($mers < $m) . ($mers < -$m) . ($mers < $w) . ($mers < -$w) . ($mers < $z) . ($mers < $z * -1)
    . ($mers <= 1234) . ($mers <= -1234) . ($mers <= $m) . ($mers <= -$m) . ($mers <= $w) . ($mers <= -$w) . ($mers <= $z) . ($mers <= $z * -1)
    . ($bsi1 > 1234) . ($bsi2 > -1234) . ($bul > $m) . ($bul > -$m) . ($bd > $w) . ($bd > -$w) . ($mers_copy > $mers) . ($mers_copy > $mers * -1)
    . ($bsi1 >= 1234) . ($bsi2 >= -1234) . ($bul >= $m) . ($bul >= -$m) . ($bd >= $w) . ($bd >= -$w) . ($mers_copy >= $mers) . ($mers_copy >= $mers * -1)
    . ($bsi1 < 1234) . ($bsi2 < -1234) . ($bul < $m) . ($bul < -$m) . ($bd < $w) . ($bd < -$w) . ($mers_copy < $mers) . ($mers_copy < $mers * -1)
    . ($bsi1 <= 1234) . ($bsi2 <= -1234) . ($bul <= $m) . ($bul <= -$m) . ($bd <= $w) . ($bd <= -$w) . ($mers_copy <= $mers) . ($mers_copy <= $mers * -1);
if($ok eq '1111111111111111000000000000000000010101111111110000000011101010'
   && Math::GMPz::get_refcnt($mers) == 1) {print "ok 26\n"}
else {print "not ok 26\n"}

$ok =
 (1234>$mers).(-1234>$mers).($m>$mers).(-$m>$mers).($w>$mers).(-$w>$mers).($z>$mers).($z*-1>$mers)
.(1234>=$mers).(-1234>=$mers).($m>=$mers).(-$m>=$mers).($w>=$mers).(-$w>=$mers).($z>=$mers).(-$z>=$mers)
.(1234<$mers).(-1234<$mers).($m<$mers).(-$m<$mers).($w<$mers).(-$w<$mers).($z<$mers).($z*-1<$mers)
.(1234<=$mers).(-1234<=$mers).($m<=$mers).(-$m<=$mers).($w<=$mers).(-$w<=$mers).($z<=$mers).(-$z<=$mers)
.(1234>$bsi1).(-1234>$bsi2).($m>$bul).(-$m>$bul).($w>$bd).(-$w>$bd)
.(1234>=$bsi1).(-1234>=$bsi2).($m>=$bul).(-$m>=$bul).($w>=$bd).(-$w>=$bd)
.(1234<$bsi1).(-1234<$bsi2).($m<$bul).(-$m<$bul).($w<$bd).(-$w<$bd)
.(1234<=$bsi1).(-1234<=$bsi2).($m<=$bul).(-$m<=$bul).($w<=$bd).(-$w<=$bd);

if($ok eq '00000000000000001111111111111111000000111010000101111111'
   && Math::GMPz::get_refcnt($mers) == 1) {print "ok 27\n"}
else {print "not ok 27\n"}


$ok =
 ($mers==1234).($mers==-1234).($mers==$m).($mers==-$m).($mers==$w).($mers==-$w).($mers==$z).($mers==-$z)
.($bsi1==1234).($bsi2==-1234).($bul==$m).($bul==-$m).($bd==$w).($bd==-$w)
.($mers!=1234).($mers!=-1234).($mers!=$m).($mers!=-$m).($mers!=$w).($mers!=-$w).($mers!=$z).($mers!=-$z)
.($bsi1!=1234).($bsi2!=-1234).($bul!=$m).($bul!=-$m).($bd!=$w).($bd!=-$w);

if($ok eq '0000000011101011111111000101'
   && Math::GMPz::get_refcnt($mers) == 1) {print "ok 28\n"}
else {print "not ok 28\n"}

$ok =
 (1234==$mers).(-1234==$mers).($m==$mers).(-$m==$mers).($w==$mers).(-$w==$mers).($z==$mers).(-$z==$mers)
.(1234==$bsi1).(-1234==$bsi2).($m==$bul).(-$m==$bul).($w==$bd).(-$w==$bd)
.(1234!=$mers).(-1234!=$mers).($m!=$mers).(-$m!=$mers).($w!=$mers).(-$w!=$mers).($z!=$mers).(-$z!=$mers)
.(1234!=$bsi1).(-1234!=$bsi2).($m!=$bul).(-$m!=$bul).($w!=$bd).(-$w!=$bd);

if($ok eq '0000000011101011111111000101'
   && Math::GMPz::get_refcnt($mers) == 1) {print "ok 29\n"}
else {print "not ok 29\n"}

my @k1 = ((1234<=>$mers),(-1234<=>$mers),($m<=>$mers),(-$m<=>$mers),($w<=>$mers),(-$w<=>$mers),
($z<=>$mers),(-$z<=>$mers),(1234<=>$bsi1),(-1234<=>$bsi2),($m<=>$bul),(-$m<=>$bul),($w<=>$bd),
(-$w<=>$bd));

my @k2 = (($mers<=>1234),($mers<=>-1234),($mers<=>$m),($mers<=>-$m),($mers<=>$w),($mers<=>-$w),
($mers<=>$z),($mers<=>-$z),($bsi1<=>1234),($bsi2<=>-1234),($bul<=>$m),($bul<=>-$m),($bd<=>$w),
($bd<=>-$w));

$ok = 1;
for(0..7) {
   if($k1[$_] >= 0 || $k2[$_] <= 0) {$ok = 0}
   }

for(8..10) {
   if($k1[$_] != 0 || $k2[$_] != 0) {$ok = 0}
   }

if($k1[11] >= 0 || $k2[11] <= 0) {$ok = 0}
if($k1[12] != 0 || $k2[12] != 0) {$ok = 0}
if($k1[13] >= 0 || $k2[13] <= 0) {$ok = 0}

if($ok) {print "ok 30\n"}
else {print "not pk 30\n"}

$ok = 1;
my $zero1 = Rmpz_init_set_str("0", 2);
my $zero2 = Rmpz_init();
my $one = Rmpz_init_set_str('1', 2);

if(!$mers) {$ok = 0}
if(not $mers) {$ok = 0}
if($zero1) {$ok = 0}
if($zero2) {$ok = 0}
unless($one) {$ok = 0}
unless(!$zero1) {$ok = 0}
unless(not $zero1) {$ok = 0}
unless(!$zero2) {$ok = 0}
unless(not $zero2) {$ok = 0}

if($ok) {print "ok 31\n"}
else {print "not pk 31\n"}

my $b_copy = $z;

if($b_copy == $z
   && "$b_copy" eq "$z"
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($b_copy) == 1) {print "ok 32\n"}
else {print "not ok 32\n"}

$z2 = $z;

if($z2 == $z
   && "$z2" eq "$z"
   && Math::GMPz::get_refcnt($z) == 1
   && Math::GMPz::get_refcnt($z2) == 1) {print "ok 33\n"}
else {print "not ok 33\n"}

my $mbi = Math::BigFloat->new(112345);
my $p = Rmpz_init_set_ui(10);
my $q = Rmpz_init();

$ok = '';

eval{$q = $p % $mbi;};
if($@ =~ /Invalid argument/) {$ok = 'A'}
eval{$q = $p + $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'd'}
eval{$q = $p ** $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'e'}
eval{$p %= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'F'}
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
eval{$q = $p & $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'k'}
eval{$q = $p | $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'l'}
eval{$q = $p ^ $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'm'}
eval{$p &= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'n'}
eval{$p |= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'o'}
eval{$p ^= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'p'}

if($ok eq 'AabcdeFfghijklmnop') {print "ok 34\n"}
else {print "not ok 34 $ok\n"}

$ok = '';
$mbi = "an invalid string";

eval{$q = $p % $mbi;};
if($@ =~ /Invalid string/) {$ok = 'A'}
eval{$q = $p + $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'd'}
eval{$p %= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'F'}
eval{$p += $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'i'}
eval{$q = $p & $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'j'}
eval{$q = $p | $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'k'}
eval{$q = $p ^ $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'l'}
eval{$p &= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'm'}
eval{$p |= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'n'}
eval{$p ^= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'o'}
eval{if($p != $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'p'}
eval{if($p > $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'q'}
eval{if($p >= $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'r'}
eval{if($p < $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 's'}
eval{if($p <= $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 't'}
eval{if($p <=> $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'u'}
eval{if($p == $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'v'}


if($ok eq 'AabcdFfghijklmnopqrstuv') {print "ok 35\n"}
else {print "not ok 35 $ok\n"}

my $string = '0X11111111111111111111Ff';

$p += $string;
$p -= $string;
$p *= $string;
$p /= $string;

if($p == 10 && Math::GMPz::get_refcnt($p) == 1) {print "ok 36\n"}
else {print "not ok 36\n"}

if($p < $string && $p <= $string && $string > $p
   && $string >= $p && ($p <=> $string) < 0
   && ($string <=> $p) > 0 && Math::GMPz::get_refcnt($p) == 1
   && $p != $string) {print "ok 37\n"}
else {print "not ok 37\n"}

$p += $string;
$q = $p - 10;

if($q == $string && Math::GMPz::get_refcnt($p) == 1
   && Math::GMPz::get_refcnt($q) == 1) {print "ok 38\n"}
else {print "not ok 38\n"}

$mbi = \$p;

$ok = '';

eval{$q = $p % $mbi;};
if($@ =~ /Invalid argument/) {$ok = 'A'}
eval{$q = $p + $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'd'}
eval{$q = $p ** $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'e'}
eval{$p %= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'F'}
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
eval{$q = $p & $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'k'}
eval{$q = $p | $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'l'}
eval{$q = $p ^ $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'm'}
eval{$p &= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'n'}
eval{$p |= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'o'}
eval{$p ^= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'p'}

if($ok eq 'AabcdeFfghijklmnop') {print "ok 39\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 39 $ok\n";
}

my $negative = "1702" - Math::GMPz->new("11702");

if($negative == -10000) {print "ok 40\n"}
else {
  warn "\nexpected -10000, got $negative\n";
  print "not ok 40\n";
}

if(3 ** Math::GMPz->new(15) == 14348907) {print "ok 41\n"}
else {
  warn "\n 3 ** Math::GMPz->new(15) == ", 3 ** Math::GMPz->new(15), "\n";
  print "not ok 41\n";
}

my $po = Math::GMPz->new(17);
$po **= Math::GMPz->new(7);

if($po == 410338673) {print "ok 42\n"}
else {
  warn "\n expected 410338673, got $po\n";
  print "not ok 42\n";
}

Rmpz_set_ui($po, ~0);
$po *= 10;

eval{my $error = 2 ** $po;};
if($@ =~ /^Exponent does not fit into unsigned long int/) {print "ok 43\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 43\n";
}

eval{$po **= $po;};
if($@ =~ /Exponent must fit into an unsigned long/) {print "ok 44\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 44\n";
}



## *,+,/,-,*=,+=,-=,/=,&,&=,|,|=,^,^=,
## >,>=,<,<=,<=>,==, !=
