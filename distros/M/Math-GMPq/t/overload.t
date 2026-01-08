use warnings;
use strict;
use Config;
use Math::GMPq qw(:mpq);
use Math::BigInt; # for some error checking

print "1..39\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $p = Rmpq_init();
my $q = Rmpq_init();

my $ui = (2 ** 31) + 17;
my $negi = -1236;
my $posd = (2 ** 41) + 11234;
my $negd = -((2 ** 43) - 111);
my $frac = 23.124901;

Rmpq_set_ui($p, 113, 73);
Rmpq_set_si($q, -227, 65537);

Rmpq_canonicalize($p);
Rmpq_canonicalize($q);

my $ok = '';

my $z = $p * $q;
if(Rmpq_get_str($z, 10) eq '-25651/4784201'
   && "$z" eq '-25651/4784201') {$ok = 'a'}

$z = $p * $ui;
if(Rmpq_get_str($z, 10) eq '242665654145/73'
   && "$z" eq '242665654145/73') {$ok .= 'b'}

$z = $p * $negi;
if(Rmpq_get_str($z, 10) eq '-139668/73'
   && "$z" eq '-139668/73') {$ok .= 'c'}

$z = $p * $posd;
if(Rmpq_get_str($z, 10) eq '248489629146818/73'
   && "$z" eq '248489629146818/73') {$ok .= 'd'}

$z = $p * $negd;
if(Rmpq_get_str($z, 10) eq '-993958511496961/73'
   && "$z" eq '-993958511496961/73') {$ok .= 'e'}

$z = $p * $frac;
if($z < 35.7960797 && $z > 35.7960796) {$ok .= 'f'}
else {print $z, "\n"}

#35.796079630136988253351063738666
#35.796079630136986301169306547287

if($ok eq 'abcdef') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

$p *= $q;
if(Rmpq_get_str($p, 10) eq '-25651/4784201'
   && "$p" eq '-25651/4784201') {$ok = 'a'}
Rmpq_set_ui($p, 113, 73);

$p *= $ui;
if(Rmpq_get_str($p, 10) eq '242665654145/73'
   && "$p" eq '242665654145/73') {$ok .= 'b'}
Rmpq_set_ui($p, 113, 73);

$p *= $negi;
if(Rmpq_get_str($p, 10) eq '-139668/73'
   && "$p" eq '-139668/73') {$ok .= 'c'}
Rmpq_set_ui($p, 113, 73);

$p *= $posd;
if(Rmpq_get_str($p, 10) eq '248489629146818/73'
   && "$p" eq '248489629146818/73') {$ok .= 'd'}
Rmpq_set_ui($p, 113, 73);

$p *= $negd;
if(Rmpq_get_str($p, 10) eq '-993958511496961/73'
   && "$p" eq '-993958511496961/73') {$ok .= 'e'}
Rmpq_set_ui($p, 113, 73);

$p *= $frac;
if($z < 35.7960797 && $z > 35.7960796) {$ok .= 'f'}
else {print $z, "\n"}
Rmpq_set_ui($p, 113, 73);

if($ok eq 'abcdef') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

$z = $p + $p;
if(Rmpq_get_str($z, 10) eq '226/73'
   && "$z" eq '226/73') {$ok = 'a'}

$z = $p + $ui;
if(Rmpq_get_str($z, 10) eq '156766307658/73'
   && "$z" eq '156766307658/73') {$ok .= 'b'}

$z = $p + $negi;
if(Rmpq_get_str($z, 10) eq '-90115/73'
   && "$z" eq '-90115/73') {$ok .= 'c'}

$z = $p + $posd;
if(Rmpq_get_str($z, 10) eq '160528698475491/73'
   && "$z" eq '160528698475491/73') {$ok .= 'd'}

$z = $p + $negd;
if(Rmpq_get_str($z, 10) eq '-642114790612968/73'
   && "$z" eq '-642114790612968/73') {$ok .= 'e'}

$z = $p + $frac;
if($z < 24.672847 && $z > 24.672846) {$ok .= 'f'}
else {print $z, "\n"}

if($ok eq 'abcdef') {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

$p += $p;
if(Rmpq_get_str($p, 10) eq '226/73'
   && "$p" eq '226/73') {$ok = 'a'}
Rmpq_set_ui($p, 113, 73);

$p += $ui;
if(Rmpq_get_str($p, 10) eq '156766307658/73'
   && "$p" eq '156766307658/73') {$ok .= 'b'}
Rmpq_set_ui($p, 113, 73);

$p += $negi;
if(Rmpq_get_str($p, 10) eq '-90115/73'
   && "$p" eq '-90115/73') {$ok .= 'c'}
Rmpq_set_ui($p, 113, 73);

$p += $posd;
if(Rmpq_get_str($p, 10) eq '160528698475491/73'
   && "$p" eq '160528698475491/73') {$ok .= 'd'}
Rmpq_set_ui($p, 113, 73);

$p += $negd;
if(Rmpq_get_str($p, 10) eq '-642114790612968/73'
   && "$p" eq '-642114790612968/73') {$ok .= 'e'}
Rmpq_set_ui($p, 113, 73);

$p += $frac;
if($z < 24.672847 && $z > 24.672846) {$ok .= 'f'}
else {print $z, "\n"}
Rmpq_set_ui($p, 113, 73);

if($ok eq 'abcdef') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

$ok = '';

$z = $p / $q;
if(Rmpq_get_str($z, 10) eq '-7405681/16571'
   && "$z" eq '-7405681/16571') {$ok = 'a'}

$z *= $q / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '1'}

$z = $p / $ui;
if(Rmpq_get_str($z, 10) eq '113/156766307545'
   && "$z" eq '113/156766307545') {$ok .= 'b'}

$z *= $ui / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '2'}

$z = $p / $negi;
if(Rmpq_get_str($z, 10) eq '-113/90228'
   && "$z" eq '-113/90228') {$ok .= 'c'}

$z *= $negi / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '3'}

$z = $p / $posd;
if(Rmpq_get_str($z, 10) eq '113/160528698475378'
   && "$z" eq '113/160528698475378') {$ok .= 'd'}

$z *= $posd / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '4'}

$z = $p / $negd;
if(Rmpq_get_str($z, 10) eq '-1/5682431775337'
   && "$z" eq '-1/5682431775337') {$ok .= 'e'}

$z *= $negd / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '5'}

$z = $p / $frac;
if($z < 0.0669385 && $z > 0.0669384) {$ok .= 'f'}
else {print $z, "\n"}

$z *= $frac / $p;
if(Rmpq_get_str($z, 16) eq '1') {$ok .= '6'}

if($ok eq 'a1b2c3d4e5f6') {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

$ok = '';

$p *= $ui;
$p /= $ui;
if("$p" eq '113/73') {$ok = 'a'}

$p *= $negi;
$p /= $negi;
if("$p" eq '113/73') {$ok .= 'b'}

$p *= $posd;
$p /= $posd;
if("$p" eq '113/73') {$ok .= 'c'}

$p *= $negd;
$p /= $negd;
if("$p" eq '113/73') {$ok .= 'd'}

$p *= $frac;
$p /= $frac;
if("$p" eq '113/73') {$ok .= 'e'}

$p *= $q;
$p /= $q;

if("$p" eq '113/73') {$ok .= 'f'}

if($ok eq 'abcdef') {print "ok 6\n"}
else {print "not ok 6 $ok\n"}

my $c = $p;
if("$c" eq '113/73'
   && "$c" eq "$p"
   && $c == $p
   && $c != $q) {print "ok 7\n"}
else {print "not ok 7\n"}

$c *= -1;
if(Rmpq_get_str(abs($c), 10) eq '113/73') {print "ok 8\n"}
else {print "not ok 8\n"}

$ok = ($p!=$ui).($p==$ui).($p>$ui).($p>=$ui).($p<$ui).($p<=$ui).($p<=>$ui);
if($ok eq '100011-1') {print "ok 9\n"}
else {print "not ok 9\n"}

$ok = ($p!=$negi).($p==$negi).($p>$negi).($p>=$negi).($p<$negi).($p<=$negi).($p<=>$negi);
if($ok eq '1011001') {print "ok 10\n"}
else {print "not ok 10\n"}

$ok = ($p!=$posd).($p==$posd).($p>$posd).($p>=$posd).($p<$posd).($p<=$posd).($p<=>$posd);
if($ok eq '100011-1') {print "ok 11\n"}
else {print "not ok 11\n"}

$ok = ($p!=$negd).($p==$negd).($p>$negd).($p>=$negd).($p<$negd).($p<=$negd).($p<=>$negd);
if($ok eq '1011001') {print "ok 12\n"}
else {print "not ok 12\n"}

$ok = ($p!=$frac).($p==$frac).($p>$frac).($p>=$frac).($p<$frac).($p<=$frac).($p<=>$frac);
if($ok eq '100011-1') {print "ok 13\n"}
else {print "not ok 13\n"}

$ok = ($ui!=$p).($ui==$p).($ui>$p).($ui>=$p).($ui<$p).($ui<=$p).($ui<=>$p);
if($ok eq '1011001') {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = ($negi!=$p).($negi==$p).($negi>$p).($negi>=$p).($negi<$p).($negi<=$p).($negi<=>$p);
if($ok eq '100011-1') {print "ok 15\n"}
else {print "not ok 15\n"}

$ok = ($posd!=$p).($posd==$p).($posd>$p).($posd>=$p).($posd<$p).($posd<=$p).($posd<=>$p);
if($ok eq '1011001') {print "ok 16\n"}
else {print "not ok 16\n"}

$ok = ($negd!=$p).($negd==$p).($negd>$p).($negd>=$p).($negd<$p).($negd<=$p).($negd<=>$p);
if($ok eq '100011-1') {print "ok 17\n"}
else {print "not ok 17\n"}

$ok = ($frac!=$p).($frac==$p).($frac>$p).($frac>=$p).($frac<$p).($frac<=$p).($frac<=>$p);
if($ok eq '1011001') {print "ok 18\n"}
else {print "not ok 18\n"}

Rmpq_set_ui($q, 0, 1);

if($p) {print "ok 19\n"}
else {print "not ok 19\n"}

if(!$q) {print "ok 20\n"}
else {print "not ok 20\n"}

if(not$q) {print "ok 21\n"}
else {print "not ok 21\n"}

unless($q) {print "ok 22\n"}
else {print "not ok 22\n"}

$z = $c;
$z *= -1;
if($z == -$c) {print "ok 23\n"}
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

if($ok eq 'abcdef') {print "ok 24\n"}
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
$z += $frac;
if($z -= $p) {$ok .= 'f'}

if($ok eq 'abcdef') {print "ok 25\n"}
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

if($ok eq 'abcdef') {print "ok 26\n"}
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

if($ok eq 'abcdef') {print "ok 27\n"}
else {print "not ok 27 $ok\n"}

my $mbi = Math::BigInt->new(112345);
Rmpq_set_d($p, 12.7);
Rmpq_set_d($q, 13.6);

$ok = '';

eval{$q = $p + $mbi;};
if($@ =~ /Invalid argument/) {$ok = 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'd'}
eval{$p += $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'i'}

if($ok eq 'abcdfghi') {print "ok 28\n"}
else {print "not ok 28 $ok\n"}

$mbi = "this is a string";
Rmpq_set_d($p, 12.7);
Rmpq_set_d($q, 13.6);

$ok = '';

eval{$q = $p + $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok = 'a'}
eval{$q = $p * $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'b'}
eval{$q = $p - $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'c'}
eval{$q = $p / $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'd'}
eval{$p += $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'e'}
eval{$p *= $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'f'}
eval{$p -= $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'g'}
eval{$p /= $mbi;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'h'}
eval{$q = $mbi + $p;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'i'}
eval{$q = $mbi * $p;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'j'}
eval{$q = $mbi - $p;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'k'}
eval{$q = $mbi / $p;};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'l'}
eval{if($q > $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'm'}
eval{if($q >= $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'n'}
eval{if($q < $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'o'}
eval{if($q <= $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'p'}
eval{if($q <=> $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'q'}
eval{if($q == $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 'r'}
eval{if($q != $mbi){};};
if($@ =~ /String supplied to Rmpq_set_str function \(/i) {$ok .= 's'}

if($ok eq 'abcdefghijklmnopqrs') {print "ok 29\n"}
else {print "not ok 29 $ok\n"}

$mbi = '0x1/02';

$q = $p + $mbi;
$p = $q - $mbi;
$q = $p * $mbi;
$p = $q / $mbi;

if($p < 12.71 && $p > 12.69) {print "ok 30\n"}
else {print "not ok 30\n"}

$q = $mbi + $p;
$p = $mbi - $q;

if($p > -12.71 && $p < -12.69) {print "ok 31\n"}
else {print "not ok 31\n"}

$q = $mbi * $p;
$p = $mbi / $q;

if($p < -0.078 && $p > -0.079) {print "ok 32\n"}
else {print "not ok 32\n"}

Rmpq_set_d($p, 1234567.123);

if($p > $mbi &&
   $p >= $mbi &&
   $mbi < $p &&
   $mbi <= $p &&
   ($p <=> $mbi) == 1 &&
   ($mbi <=> $p) == -1 &&
   $p != $mbi &&
   !($p == $mbi)
) {print "ok 33\n"}
else {print "not ok 33\n"}

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
eval{$p += $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'f'}
eval{$p *= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'g'}
eval{$p -= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'h'}
eval{$p /= $mbi;};
if($@ =~ /Invalid argument/) {$ok .= 'i'}

if($ok eq 'abcdfghi') {print "ok 34\n"}
else {print "not ok 34 $ok\n"}

if($] >= 5.008) {
  Rmpq_set_ui($p, 27, 7);
  if(int($p) == 3) {print "ok 35\n"}
  else {print "not ok 35\n"}
}
else {
  warn "Skipping test 35 - no overloading of 'int' on perl $]\n";
  print "ok 35\n";
}

Rmpq_set_ui($p, 113, 73);
$q = $p;

$ok = '';

$p++;
$ok .= 'a' if $p == $q + 1;

++$p;
$ok .= 'b' if $p == $q + 2;

$p--;
$ok .= 'c' if $p == $q + 1;

--$p;
$ok .= 'd' if $p == $q;

if($ok eq 'abcd') {print "ok 36\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 36\n";
}

my $obj0 = Math::GMPq->new(~0) / 19;
my $obj1 = $obj0++;

if($obj1 - $obj0 == -1) {print "ok 37\n"}
else {
  warn "$obj1 is not 1 less than $obj0\n";
  print "not ok 37\n";
}

my $obj2 = ++$obj0;
if($obj2 == $obj0) {print "ok 38\n"}
else {
  warn "$obj2 != $obj0\n";
  print "not ok 38\n";
}

if($obj2 - $obj1 == 2) {print "ok 39\n"}
else {
  warn "$obj2 is 2 greater than $obj1\n";
  print "not ok 39\n";
}
