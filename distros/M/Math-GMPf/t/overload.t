use strict;
use warnings;
use Math::GMPf qw(:mpf);
use Math::BigInt; # for some error checking

print "1..103\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

Rmpf_set_default_prec(200);

my $p = Rmpf_init();
my $q = Rmpf_init();

my $ui = (2 ** 31) + 17;
my $negi = -1236;
my $posi = 1238;
my $posd = (2 ** 41) + 11234;
my $negd = -((2 ** 43) - 111);
my $frac = 23.124901;

Rmpf_set_ui($p, 1234);
Rmpf_set_si($q, -5678);

my $ok = '';

my $z = $p * $q;
if(Rmpf_get_str($z, 10,0) eq '-0.7006652e7'
   && $z == -7006652
   && "$z" eq '-0.7006652e7') {$ok = 'a'}

$z = $p * $ui;
if(Rmpf_get_str($z, 10, 0) eq '0.264999484261e13'
   && $z == 2649994842610
   && "$z" eq '0.264999484261e13') {$ok .= 'b'}

$z = $p * $negi;
if(Rmpf_get_str($z, 10, 0) eq '-0.1525224e7'
   && $z == -1525224
   && "$z" eq '-0.1525224e7') {$ok .= 'c'}

$z = $p * $posd;
if(Rmpf_get_str($z, 10, 0) eq '0.2713594711213924e16'
   && $z == 2713594711213924
   && "$z" eq '0.2713594711213924e16') {$ok .= 'd'}

$z = $p * $negd;
if(Rmpf_get_str($z, 10, 0) eq '-0.10854378789267698e17'
   && $z == -10854378789267698
   && "$z" eq '-0.10854378789267698e17') {$ok .= 'e'}

$z = $p * $frac;
if($z > 28536.12783 && $z < 28536.12784) {$ok .= 'f'}
else { warn "\n 1f: \$z: $z\n"}

$z = $p * $posi;
if($z == 1527692) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

$p *= $q;
if(Rmpf_get_str($p, 10, 0) eq '-0.7006652e7'
   && $p == -7006652
   && "$p" eq '-0.7006652e7') {$ok = 'a'}
Rmpf_set_ui($p, 1234);

$p *= $ui;
if(Rmpf_get_str($p, 10, 0) eq '0.264999484261e13'
   && $p == 2649994842610
   && "$p" eq '0.264999484261e13') {$ok .= 'b'}
Rmpf_set_ui($p, 1234);

$p *= $negi;
if(Rmpf_get_str($p, 10, 0) eq '-0.1525224e7'
   && $p == -1525224
   && "$p" eq '-0.1525224e7') {$ok .= 'c'}
Rmpf_set_ui($p, 1234);

$p *= $posd;
if(Rmpf_get_str($p, 10, 0) eq '0.2713594711213924e16'
   && $p == 2713594711213924
   && "$p" eq '0.2713594711213924e16') {$ok .= 'd'}
Rmpf_set_ui($p, 1234);

$p *= $negd;
if(Rmpf_get_str($p, 10, 0) eq '-0.10854378789267698e17'
   && $p == -10854378789267698
   && "$p" eq '-0.10854378789267698e17') {$ok .= 'e'}
Rmpf_set_ui($p, 1234);

$p *= $frac;
if($p > 28536.12783 && $p < 28536.12784) {$ok .= 'f'}
Rmpf_set_ui($p, 1234);

$p *= $posi;
if($p == 1527692) {$ok .= 'g'}
Rmpf_set_ui($p, 1234);

if($ok eq 'abcdefg'
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

$z = $p + $p;
if(Rmpf_get_str($z, 10, 0) eq '0.2468e4'
   && $z == 2468
   && "$z" eq '0.2468e4') {$ok = 'a'}

$z = $p + $ui;
if(Rmpf_get_str($z, 10, 0) eq '0.2147484899e10'
   && $z == 2147484899
   && "$z" eq '0.2147484899e10') {$ok .= 'b'}

$z = $p + $negi;
if(Rmpf_get_str($z, 10, 0) eq '-0.2e1'
   && $z == -2
   && "$z" eq '-0.2e1') {$ok .= 'c'}

$z = $p + $posd;
if(Rmpf_get_str($z, 10, 0) eq '0.219902326802e13'
   && $z == 2199023268020
   && "$z" eq '0.219902326802e13') {$ok .= 'd'}

$z = $p + $negd;
if(Rmpf_get_str($z, 10, 0) eq '-0.8796093020863e13'
   && $z == -8796093020863
   && "$z" eq '-0.8796093020863e13') {$ok .= 'e'}

$z = $p + $frac;
if($z > 1257.1249 && $z < 1257.124902) {$ok .= 'f'}

$z = $p + $posi;
if($z == 2472) {$ok .= 'g'}

if($ok eq 'abcdefg'
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($z) == 1) {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

$p += $p;
if(Rmpf_get_str($p, 10, 0) eq '0.2468e4'
   && $p == 2468
   && "$p" eq '0.2468e4') {$ok = 'a'}
Rmpf_set_ui($p, 1234);

$p += $ui;
if(Rmpf_get_str($p, 10, 0) eq '0.2147484899e10'
   && $p == 2147484899
   && "$p" eq '0.2147484899e10') {$ok .= 'b'}
Rmpf_set_ui($p, 1234);

$p += $negi;
if(Rmpf_get_str($p, 10, 0) eq '-0.2e1'
   && $p == -2
   && "$p" eq '-0.2e1') {$ok .= 'c'}
Rmpf_set_ui($p, 1234);

$p += $posd;
if(Rmpf_get_str($p, 10, 0) eq '0.219902326802e13'
   && $p == 2199023268020
   && "$p" eq '0.219902326802e13') {$ok .= 'd'}
Rmpf_set_ui($p, 1234);

$p += $negd;
if(Rmpf_get_str($p, 10, 0) eq '-0.8796093020863e13'
   && $p == -8796093020863
   && "$p" eq '-0.8796093020863e13') {$ok .= 'e'}
Rmpf_set_ui($p, 1234);

$p += $frac;
if($p > 1257.1249 && $p < 1257.124902) {$ok .= 'f'}
Rmpf_set_ui($p, 1234);

$p += $posi;
if($p == 2472) {$ok .= 'g'}
Rmpf_set_ui($p, 1234);

if($ok eq 'abcdefg'
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 4\n"}
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
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($z) == 1) {print "ok 5\n"}
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
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 6\n"}
else {print "not ok 6 $ok\n"}

my $c = $p;
if("$c" eq '0.1234e4'
   && "$c" eq "$p"
   && $c == $p
   && $c != $q
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($c) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 7\n"}
else {print "not ok 7\n"}

$c *= -1;
if(Rmpf_get_str(abs($c), 10, 0) eq '0.1234e4'
   && Math::GMPf::get_refcnt($c) == 1) {print "ok 8\n"}
else {print "not ok 8\n"}

$ok = ($p!=$ui).($p==$ui).($p>$ui).($p>=$ui).($p<$ui).($p<=$ui).($p<=>$ui);
if($ok eq '100011-1') {print "ok 9\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 9\n";
}

$ok = ($p!=$negi).($p==$negi).($p>$negi).($p>=$negi).($p<$negi).($p<=$negi).($p<=>$negi);
if($ok eq '1011001') {print "ok 10\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 10\n";
}

$ok = ($p!=$posd).($p==$posd).($p>$posd).($p>=$posd).($p<$posd).($p<=$posd).($p<=>$posd);
if($ok eq '100011-1') {print "ok 11\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 11\n";
}

$ok = ($p!=$negd).($p==$negd).($p>$negd).($p>=$negd).($p<$negd).($p<=$negd).($p<=>$negd);
if($ok eq '1011001') {print "ok 12\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 12\n";
}

$ok = ($p!=$frac).($p==$frac).($p>$frac).($p>=$frac).($p<$frac).($p<=$frac).($p<=>$frac);
if($ok eq '1011001') {print "ok 13\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 13\n";
}

$ok = ($ui!=$p).($ui==$p).($ui>$p).($ui>=$p).($ui<$p).($ui<=$p).($ui<=>$p);
if($ok eq '1011001') {print "ok 14\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 14\n";
}

$ok = ($negi!=$p).($negi==$p).($negi>$p).($negi>=$p).($negi<$p).($negi<=$p).($negi<=>$p);
if($ok eq '100011-1') {print "ok 15\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 15\n";
}

$ok = ($posd!=$p).($posd==$p).($posd>$p).($posd>=$p).($posd<$p).($posd<=$p).($posd<=>$p);
if($ok eq '1011001') {print "ok 16\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 16\n";
}

$ok = ($negd!=$p).($negd==$p).($negd>$p).($negd>=$p).($negd<$p).($negd<=$p).($negd<=>$p);
if($ok eq '100011-1') {print "ok 17\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 17\n";
}

$ok = ($frac!=$p).($frac==$p).($frac>$p).($frac>=$p).($frac<$p).($frac<=$p).($frac<=>$p);
if($ok eq '100011-1'
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 18\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 18\n";
}

Rmpf_set_ui($q, 0);

if($p && Math::GMPf::get_refcnt($p) == 1) {print "ok 19\n"}
else {print "not ok 19\n"}

if(!$q && Math::GMPf::get_refcnt($q) == 1) {print "ok 20\n"}
else {print "not ok 20\n"}

if(not($q) && Math::GMPf::get_refcnt($q) == 1) {print "ok 21\n"}
else {print "not ok 21\n"}

unless($q || Math::GMPf::get_refcnt($q) != 1) {print "ok 22\n"}
else {print "not ok 22\n"}

$z = $c;
$z *= -1;
if($z == -$c
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($c) == 1) {print "ok 23\n"}
else {print "not ok 23\n"}

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
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 24\n"}
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
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 25\n"}
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
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 26\n"}
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
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 27\n"}
else {print "not ok 27 $ok\n"}

$ok = ($posi!=$p).($posi==$p).($posi>$p).($posi>=$p).($posi<$p).($posi<=$p).($posi<=>$p);
if($ok eq '1011001'
   && Math::GMPf::get_refcnt($p) == 1) {print "ok 28\n"}
else {print "not ok 28\n"}

$ok = ($p!=$posi).($p==$posi).($p>$posi).($p>=$posi).($p<$posi).($p<=$posi).($p<=>$posi);
if($ok eq '100011-1') {print "ok 29\n"}
else {print "not ok 29\n"}

Rmpf_set_ui($z, 2);

my $root = sqrt($z);
if($root > 1.414 && $root < 1.415
   && Math::GMPf::get_refcnt($z) == 1
   && Math::GMPf::get_refcnt($root) == 1) {print "ok 30\n"}
else {print "not ok 30\n"}

my $root_copy = $root;

$root = $root ** 2;
$root_copy **= 2;

if($root_copy > 1.99999 && $root_copy < 2.00000001
   && $root > 1.99999 && $root < 2.00000001
   && Math::GMPf::get_refcnt($root) == 1
   && Math::GMPf::get_refcnt($root_copy) == 1) {print "ok 31\n"}
else {print "not ok 31\n"}


if($] >= 5.008) {
  Rmpf_set_d($z, 2.11115);

  $root = int($z);
  if($z > 2.1111 && $z < 2.1112
     && $root == 2
     && int($z) == 2
     && Math::GMPf::get_refcnt($z) == 1
     && Math::GMPf::get_refcnt($root) == 1) {print "ok 32\n"}
  else {print "not ok 32\n"}
  }

else {
  warn "Skipping test 32 - no overloading of 'int' on perl $] \n";
  print "ok 32\n";
}

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

if($ok eq 'abcdefghij') {print "ok 33\n"}
else {print "not ok 33 $ok\n"}

$mbi = "this is a string";
$ok = '';

eval{$q = $p + $mbi;};
if($@ =~ /Invalid string/) {$ok = 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'd'}
eval{$q = $p ** $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'e'}
eval{$p += $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid string/) {$ok .= 'i'}
eval{$p **= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'j'}
eval{if($p > $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'k'}
eval{if($p < $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'l'}
eval{if($p >= $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'm'}
eval{if($p <= $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'n'}
eval{if($p <=> $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'o'}
eval{if($p == $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'p'}
eval{if($p != $mbi){};};
if($@ =~ /Invalid string/) {$ok .= 'q'}

if($ok eq 'abcdefghijklmnopq') {print "ok 34\n"}
else {print "not ok 34 $ok\n"}

my $dp;

# Allow "." or "," as the decimal point (according to whichever is valid for the locale).
eval{Rmpf_init_set_str("-111111111111112.34567879", 10);};
$dp = '.' unless $@;
eval{Rmpf_init_set_str("-111111111111112,34567879", 10);};
$dp = ',' unless $@;

#warn "Decimal point: $dp\n";

$mbi = $dp ? "-111111111111112${dp}34567879"
           : "-11111111111111234567879@-8";

$q = $p + $mbi;
$p = $q - $mbi;
$q = $p * $mbi;
$p = $q / $mbi;

if($p > 1233.999 && $p < 1234.001
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 35\n"}
else {print "not ok 35\n"}

$p *= $mbi;
$p /= $mbi;
$p += $mbi;
$p -= $mbi;

if($p > 1233.999 && $p < 1234.001
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 36\n"}
else {print "not ok 36\n"}

$q = $mbi + $p;
$p = $mbi - $q;

if($p > -1234.001 && $p < -1233.999
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 37\n"}
else {print "not ok 37\n"}


$q = $mbi * $p;
$p = $mbi / $q;

if($p < -0.00081 && $p > -0.000811
   && Math::GMPf::get_refcnt($p) == 1
   && Math::GMPf::get_refcnt($q) == 1) {print "ok 38\n"}
else {print "not ok 38\n"}

Rmpf_set_str($p, "1234567${dp}123", 10);

if($p > $mbi &&
   $p >= $mbi &&
   $mbi < $p &&
   $mbi <= $p &&
   ($p <=> $mbi) > 0 &&
   ($mbi <=> $p) < 0 &&
   $p != $mbi &&
   !($p == $mbi) &&
   Math::GMPf::get_refcnt($p) == 1) {print "ok 39\n"}
else {print "not ok 39\n"}

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

if($ok eq 'abcdefghij') {print "ok 40\n"}
else {print "not ok 40 $ok\n"}

$ok = '';
my $zero = Math::GMPf->new();

$ok .= 'a' if Math::GMPf::overload_string($zero) eq '0';
$ok .= 'A' if $zero;

$zero *= -1;

$ok .= 'b' if Math::GMPf::overload_string($zero) eq '0';
$ok .= 'B' if $zero;

Rmpf_set_si($zero, -0.0);

$ok .= 'c' if Math::GMPf::overload_string($zero) eq '0';
$ok .= 'C' if $zero;

# check overload_copy precision

my $mpf1 = Rmpf_init2(101);
Rmpf_set_d($mpf1, 0.7);

my $mpf2 = $mpf1;
$ok .= 'd' if Rmpf_get_prec($mpf2) == Rmpf_get_prec($mpf1) && $mpf2 == $mpf1;

$mpf2 += 1;
$ok .= 'e' if Rmpf_get_prec($mpf2) == Rmpf_get_prec($mpf1) && $mpf2 == $mpf1 + 1;

my $mpf3 = $mpf1;
$mpf1 += 1;
$ok .= 'f' if Rmpf_get_prec($mpf3) == Rmpf_get_prec($mpf1) && $mpf3 == $mpf1 - 1;

if($ok eq 'abcdef') {print "ok 41\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 41\n";
}

$ok = '';

$mpf3++;
$ok .= 'a' if $mpf3 == $mpf1;

++$mpf3;
$ok .= 'b' if $mpf3 == $mpf1 + 1;

$mpf3--;
$ok .= 'c' if $mpf3 == $mpf1;

--$mpf3;
$ok .= 'd' if $mpf3 == $mpf1 - 1;

if($ok eq 'abcd') {print "ok 42\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 42\n";
}

my $inf = 999**(999**999);
my $infstring = "$inf";
my $ninf = $inf * -1;
my $ninfstring = "$ninf";
my $nan = $inf / $inf;
my $nanstring = "$nan";
my $nan_skip = 0;
Rmpf_set_d($mpf1, 0.0);

$nan_skip = 1 if $nan == $nan;

if($mpf1 == $inf) {
  warn "\n $mpf1 == $inf\n";
  print "not ok 43\n";
}
else {print "ok 43\n"}

if($mpf1 == $ninf) {
  warn "\n $mpf1 == $ninf\n";
  print "not ok 44\n";
}
else {print "ok 44\n"}

if($mpf1 == $infstring) {
  warn "\n $mpf1 == $infstring\n";
  print "not ok 45\n";
}
else {print "ok 45\n"}

if($mpf1 == $ninfstring) {
  warn "\n $mpf1 == $ninfstring\n";
  print "not ok 46\n";
}
else {print "ok 46\n"}

#######################

if($mpf1 != $inf) {print "ok 47\n"}
else {
  warn "\n $mpf1 == $inf\n";
  print "not ok 47\n";
}

if($mpf1 != $ninf) {print "ok 48\n"}
else {
  warn "\n $mpf1 == $ninf\n";
  print "not ok 48\n";
}

if($mpf1 != $infstring) {print "ok 49\n"}
else {
  warn "\n $mpf1 == $infstring\n";
  print "not ok 49\n";
}

if($mpf1 != $ninfstring) {print "ok 50\n"}
else {
  warn "\n $mpf1 == $ninfstring\n";
  print "not ok 50\n";
}

########################

if($mpf1 > $inf) {
  warn "\n $mpf1 > $inf\n";
  print "not ok 51\n";
}
else {print "ok 51\n"}

if($mpf1 < $ninf) {
  warn "\n $mpf1 < $ninf\n";
  print "not ok 52\n";
}
else {print "ok 52\n"}

if($mpf1 > $infstring) {
  warn "\n $mpf1 > $infstring\n";
  print "not ok 53\n";
}
else {print "ok 53\n"}

if($mpf1 < $ninfstring) {
  warn "\n $mpf1 < $ninfstring\n";
  print "not ok 54\n";
}
else {print "ok 54\n"}

#########################

if($mpf1 < $inf) {print "ok 55\n"}
else {
  warn "\n $mpf1 >= $inf\n";
  print "not ok 55\n";
}

if($mpf1 > $ninf) {print "ok 56\n"}
else {
  warn "\n $mpf1 <= $ninf\n";
  print "not ok 56\n";
}

if($mpf1 < $infstring) {print "ok 57\n"}
else {
  warn "\n $mpf1 >= $infstring\n";
  print "not ok 57\n";
}

if($mpf1 > $ninfstring) {print "ok 58\n"}
else {
  warn "\n $mpf1 <= $ninfstring\n";
  print "not ok 58\n";
}

########################

if($mpf1 >= $inf) {
  warn "\n $mpf1 >= $inf\n";
  print "not ok 59\n";
}
else {print "ok 59\n"}

if($mpf1 <= $ninf) {
  warn "\n $mpf1 <= $ninf\n";
  print "not ok 60\n";
}
else {print "ok 60\n"}

if($mpf1 >= $infstring) {
  warn "\n $mpf1 >= $infstring\n";
  print "not ok 61\n";
}
else {print "ok 61\n"}

if($mpf1 <= $ninfstring) {
  warn "\n $mpf1 <= $ninfstring\n";
  print "not ok 62\n";
}
else {print "ok 62\n"}

#########################

if($mpf1 <= $inf) {print "ok 63\n"}
else {
  warn "\n $mpf1 > $inf\n";
  print "not ok 63\n";
}

if($mpf1 >= $ninf) {print "ok 64\n"}
else {
  warn "\n $mpf1 < $ninf\n";
  print "not ok 64\n";
}

if($mpf1 <= $infstring) {print "ok 65\n"}
else {
  warn "\n $mpf1 > $infstring\n";
  print "not ok 65\n";
}

if($mpf1 >= $ninfstring) {print "ok 66\n"}
else {
  warn "\n $mpf1 < $ninfstring\n";
  print "not ok 66\n";
}

###########################
###########################

if($inf == $mpf1) {
  warn "\n $inf == $mpf1\n";
  print "not ok 67\n";
}
else {print "ok 67\n"}

if($ninf == $mpf1) {
  warn "\n $ninf == $mpf1\n";
  print "not ok 68\n";
}
else {print "ok 68\n"}

if($infstring == $mpf1) {
  warn "\n $infstring == $mpf1\n";
  print "not ok 69\n";
}
else {print "ok 69\n"}

if($ninfstring == $mpf1) {
  warn "\n $ninfstring == $mpf1\n";
  print "not ok 70\n";
}
else {print "ok 70\n"}

#######################


if($inf != $mpf1) {print "ok 71\n"}
else {
  warn "\n $inf == $mpf1\n";
  print "not ok 71\n";
}

if($ninf != $mpf1) {print "ok 72\n"}
else {
  warn "\n $ninf == $mpf1\n";
  print "not ok 72\n";
}

if($infstring != $mpf1) {print "ok 73\n"}
else {
  warn "\n $infstring == $mpf1\n";
  print "not ok 73\n";
}

if($ninfstring != $mpf1) {print "ok 74\n"}
else {
  warn "\n $ninfstring == $mpf1\n";
  print "not ok 74\n";
}

########################

if($inf < $mpf1) {
  warn "\n $inf < $mpf1\n";
  print "not ok 75\n";
}
else {print "ok 75\n"}

if($ninf > $mpf1) {
  warn "\n $mpf1 > $ninf\n";
  print "not ok 76\n";
}
else {print "ok 76\n"}

if($infstring < $mpf1) {
  warn "\n $infstring < $mpf1\n";
  print "not ok 77\n";
}
else {print "ok 77\n"}

if($ninfstring > $mpf1) {
  warn "\n $ninfstring > $mpf1\n";
  print "not ok 78\n";
}
else {print "ok 78\n"}

#########################

if($inf > $mpf1) {print "ok 79\n"}
else {
  warn "\n $inf <= $mpf1\n";
  print "not ok 79\n";
}

if($ninf < $mpf1) {print "ok 80\n"}
else {
  warn "\n $ninf >= $mpf1\n";
  print "not ok 80\n";
}

if($infstring > $mpf1) {print "ok 81\n"}
else {
  warn "\n $infstring <= $mpf1\n";
  print "not ok 81\n";
}

if($ninfstring < $mpf1) {print "ok 82\n"}
else {
  warn "\n $ninfstring >= $mpf1\n";
  print "not ok 82\n";
}

########################

if($inf <= $mpf1) {
  warn "\n $inf <= $mpf1\n";
  print "not ok 83\n";
}
else {print "ok 83\n"}

if($ninf >= $mpf1) {
  warn "\n $ninf >= $mpf1\n";
  print "not ok 84\n";
}
else {print "ok 84\n"}

if($infstring <= $mpf1) {
  warn "\n $infstring <= $mpf1\n";
  print "not ok 85\n";
}
else {print "ok 85\n"}

if($ninfstring >= $mpf1) {
  warn "\n $ninfstring >= $mpf1\n";
  print "not ok 86\n";
}
else {print "ok 86\n"}

#########################

if($inf >= $mpf1) {print "ok 87\n"}
else {
  warn "\n $inf < $mpf1\n";
  print "not ok 87\n";
}

if($ninf <= $mpf1) {print "ok 88\n"}
else {
  warn "\n $ninf > $mpf1\n";
  print "not ok 88\n";
}

if($infstring >= $mpf1) {print "ok 89\n"}
else {
  warn "\n $infstring < $mpf1\n";
  print "not ok 89\n";
}

if($ninfstring <= $mpf1) {print "ok 90\n"}
else {
  warn "\n $ninfstring > $mpf1\n";
  print "not ok 90\n";
}

###########################
###########################

if(($mpf1 <=> $inf) < 0) {print "ok 91\n"}
else {
  my $p = ($mpf1 <=> $inf);
  warn "\n \$p: $p\n";
  print "not ok 91\n";
}

if(($mpf1 <=> $ninf) > 0) {print "ok 92\n"}
else {
  warn "\n ", ($mpf1 <=> $ninf), "\n";
  print "not ok 92\n";
}

if(($mpf1 <=> $infstring) < 0) {print "ok 93\n"}
else {
  warn "\n ",  ($mpf1 <=> $infstring), "\n";
  print "not ok 93\n";
}

if(($mpf1 <=> $ninfstring) > 0) {print "ok 94\n"}
else {
  warn "\n ",  ($mpf1 <=> $ninfstring), "\n";
  print "not ok 94\n";
}

###########################

if(($inf <=> $mpf1) > 0) {print "ok 95\n"}
else {
  warn "\n ", ($inf <=> $mpf1), "\n";
  print "not ok 95\n";
}

if(($ninf <=> $mpf1) < 0) {print "ok 96\n"}
else {
  my $p = ($ninf <=> $mpf1);
  warn "\n \$p: $p\n";
  print "not ok 96\n";
}

if(($infstring <=> $mpf1) > 0) {print "ok 97\n"}
else {
  warn "\n ", ($infstring <=> $mpf1), "\n";
  print "not ok 97\n";
}

if(($ninfstring <=> $mpf1) < 0) {print "ok 98\n"}
else {
  warn "\n ", ($ninfstring <=> $mpf1), "\n";
  print "not ok 98\n";
}

###########################
###########################

if(!$nan_skip) {
  eval {my $r = $mpf1 * $nanstring;};
  if($@ =~ /supplied to Math::GMPf::overload_mul/) {print "ok 99\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok 99\n";
  }

  my $r = ($mpf1 <=> $nanstring);
  if(!defined($r)) {print "ok 100\n"}
  else {
    warn "\n expected 'undef', got '$r'\n";
    print "not ok 100\n";
  }
}
else {
  warn "\n Skipping NaN handling tests\n";
  print "ok 99\nok 100\n";
}

eval{my $r = $mpf1 * $infstring;};
if($@ =~ /supplied to Math::GMPf::overload_mul/) {print "ok 101\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 101\n";
}

my $nv = 'inf' + 0;

if($nv != 0 && $nv / $nv != 1) {

  if($nv != Math::GMPf->new(0)) {print "ok 102\n"}
  else {print "not ok 102\n"}

  if($nv == Math::GMPf->new(0)) { print "not ok 103\n" }
  else { print "ok 103\n" }

}
else {
  print "skipping tests 102 and 103\n";
  print "ok 102\n";
  print "ok 103\n";
}
 
