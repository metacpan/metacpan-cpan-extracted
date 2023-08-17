
BEGIN {
  eval {require 5.008};

  if($@) {
    print "1..1\n";
    warn "\nSkipping for perl $\]\n";
    print "ok 1\n";
    exit 0;
  }
}

use strict;
use warnings;
use Math::GMPz qw(:mpz);

#use Devel::Peek;

eval {require Math::BigInt::GMP;};

unless($@) {
  require Math::BigInt;
  Math::BigInt->import('only', 'GMP');
}
else {
  print "1..1\n";
  warn "\n Skipping all tests - couldn't load Math::BigInt::GMP\n";
  print "ok 1\n";
  exit 0;
}

print "1..123\n";

my $v = $Math::BigInt::GMP::VERSION;
warn "\nUsing Math::BigInt::GMP version $v\n" if $v;

$v = $Math::BigInt::VERSION;
warn "Using Math::BigInt version $v\n";

my $str = '123456' x 9;

my $bi  = Math::BigInt->new($str);
my $div = Math::BigInt->new(substr($str, 0, 22));
my $add = Math::BigInt->new('105');
my $discard;

my $z = Math::GMPz->new($bi);
my $smaller = $z - 100;

my $neg = Math::BigInt->new('-1023456');

if($z == $str) {print "ok 1\n"}
else {
  warn "\nexpected $str, got $z\n";
  print "not ok 1\n";
}

if($z * $div == $bi * $div) {print "ok 2\n"}
else {
  warn "\nexpected ", $bi * $div, ", got ", $z * $div, "\n";
  print "not ok 2\n";
}

if($z + $div == $bi + $div) {print "ok 3\n"}
else {
  warn "\nexpected ", $bi + $div, ", got ", $z + $div, "\n";
  print "not ok 3\n";
}

if($z / $div == $bi / $div) {print "ok 4\n"}
else {
  warn "\nexpected ", $bi / $div, ", got ", $z / $div, "\n";
  print "not ok 4\n";
}

if($z - $div == $bi - $div) {print "ok 5\n"}
else {
  warn "\nexpected ", $bi - $div, ", got ", $z - $div, "\n";
  print "not ok 5\n";
}

if($z % $div == $bi % $div) {print "ok 6\n"}
else {
  warn "\nexpected ", $bi % $div, ", got ", $z % $div, "\n";
  print "not ok 6\n";
}



my $nan = sqrt(Math::BigInt->new(-17));

eval {if($z == $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_equiv/) {print "ok 7\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 7\n";
}

eval {if($z != $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_not_equiv/) {print "ok 8\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 8\n";
}

############################

eval {$discard = $z & $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_and/) {print "ok 9\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 9\n";
}

if(($z & $div) == ($bi & $div)) {print "ok 10\n"}
else {
  warn "\nexpected ", $bi & $div, ", got ", $z & $div, "\n";
  print "not ok 10\n";
}

############################
############################

eval {$discard = $z | $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_ior/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 11\n";
}

if(($z | $div) == ($bi | $div)) {print "ok 12\n"}
else {
  warn "\nexpected ", $bi | $div, ", got ", $z | $div, "\n";
  print "not ok 12\n";
}

############################
############################

eval {$discard = $z ^ $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_xor/) {print "ok 13\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 13\n";
}

if(($z ^ $div) == ($bi ^ $div)) {print "ok 14\n"}
else {
  warn "\nexpected ", $bi ^ $div, ", got ", $z ^ $div, "\n";
  print "not ok 14\n";
}

############################
############################

eval {if($z > $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_gt/) {print "ok 15\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 15\n";
}

if($z > $div) {print "ok 16\n"}
else {
  warn "\n$z is not greater than $div\n";
  print "not ok 16\n";
}

############################
############################

eval {if($z >= $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_gte/) {print "ok 17\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 17\n";
}

if($z >= $div) {print "ok 18\n"}
else {
  warn "\n$z is not greater than or equal to $div\n";
  print "not ok 18\n";
}

############################
############################

eval {if($z < $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_lt/) {print "ok 19\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 19\n";
}

if($smaller < $bi) {print "ok 20\n"}
else {
  warn "\n$z is not less than to $bi\n";
  print "not ok 20\n";
}

############################
############################

eval {if($z <= $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_lte/) {print "ok 21\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 21\n";
}

if($smaller <= $bi) {print "ok 22\n"}
else {
  warn "\n$z is not less than or equal to $bi\n";
  print "not ok 22\n";
}

############################
############################

eval {if($z <=> $nan){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_spaceship/) {print "ok 23\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 23\n";
}

if($smaller <=> $bi) {print "ok 24\n"}
else {
  warn "\n$z is equal to $bi\n";
  print "not ok 24\n";
}

if(!($z <=> $bi)) {print "ok 25\n"}
else {
  warn "\n$z is not equal to $bi\n";
  print "not ok 25\n";
}

############################
############################

eval {$z ^= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_xor_eq/) {print "ok 26\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 26\n";
}

#warn "$z\n";

$z  ^= $div;
$bi ^= $div;

#warn "$z\n";

if($z == $bi) {print "ok 27\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 27\n";
}

############################
############################

eval {$z |= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_ior_eq/) {print "ok 28\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 28\n";
}

#warn "$z\n";

$z  |= $div * 1000;
$bi |= $div * 1000;

#warn "$z\n";

if($z == $bi) {print "ok 29\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 29\n";
}

############################
############################

eval {$z &= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_and_eq/) {print "ok 30\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 30\n";
}

#warn "$z\n";

$z  &= $div * 100;
$bi &= $div * 100;

#warn "$z\n";

if($z == $bi) {print "ok 31\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 31\n";
}

############################
############################

eval {$z %= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_mod_eq/) {print "ok 32\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 32\n";
}

$z  %= $div * 100;
$bi %= $div * 100;

if($z == $bi) {print "ok 33\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 33\n";
}

############################
############################

eval {$z /= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_div_eq/) {print "ok 34\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 34\n";
}

$z  /= Math::BigInt->new(10);
$bi /= Math::BigInt->new(10);

if($z == $bi) {print "ok 35\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 35\n";
}

############################
############################

eval {$z -= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_sub_eq/) {print "ok 36\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 36\n";
}

$z  -= $add;
$bi -= $add;

if($z == $bi) {print "ok 37\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 37\n";
}

############################
############################

eval {$z += $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_add_eq/) {print "ok 38\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 38\n";
}

$z  += $add;
$bi += $add;

if($z == $bi) {print "ok 39\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 39\n";
}

############################
############################

eval {$z *= $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_mul_eq/) {print "ok 40\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 40\n";
}

$z  *= $add;
$bi *= $add;

if($z == $bi) {print "ok 41\n"}
else {
  warn "\n$z != $bi\n";
  print "not ok 41\n";
}

############################

eval{$discard = $z * $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_mul/) {print "ok 42\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 42\n";
}

eval{$discard = $z + $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_add/) {print "ok 43\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 43\n";
}

eval{$discard = $z - $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_sub/) {print "ok 44\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 44\n";
}

eval{$discard = $z / $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_div/) {print "ok 45\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 45\n";
}

eval{$discard = $z % $nan};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_mod/) {print "ok 46\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 46\n";
}

my $ninf = Math::BigInt->new(-10) / Math::BigInt->new(0);
my $pinf = Math::BigInt->new(10) / Math::BigInt->new(0);

eval {if($z == $ninf){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_equiv/) {print "ok 47\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 47\n";
}

eval {if($z == $pinf){}};

if($@ =~ /^Invalid Math::BigInt object supplied to Math::GMPz::overload_equiv/) {print "ok 48\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 48\n";
}

if($z + $neg == $z - 1023456) {print "ok 49\n"}
else {
  warn "Expected ", $z - 1023456, ", got ", $z + $neg, "\n";
  print "not ok 49\n";
}

my $check1 = Math::GMPz->new($neg);

if($check1 == Math::GMPz->new(-1023456)) {print "ok 50\n"}
else {
  warn "\nexpected -1023456, got $check1\n";
  print "not ok 50\n";
}

my $check2 = new_from_MBI($neg);

if($check2 == Math::GMPz->new(-1023456)) {print "ok 51\n"}
else {
  warn "\nexpected -1023456, got $check1\n";
  print "not ok 51\n";
}

eval {$check2 = new_from_MBI(Math::GMPz->new(1234))};

if($@ =~ /^Inappropriate arg supplied to new_from_MBI/) {print "ok 52\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 52\n";
}

my $check3 = Math::GMPz::_new_from_MBI($neg + 6);

if($check3 == Math::GMPz->new(-1023450)) {print "ok 53\n"}
else {
  warn "\nexpected -1023450, got $check3\n";
  print "not ok 53\n";
}

# Check that -ve values are being handled correctly.

my $bitop = Math::BigInt->new(-5);
my $checkop = Math::GMPz->new(-5);
my $zop   = Math::GMPz->new(17);

########################################

if(($zop & $bitop) == 17) {print "ok 54\n"}
else {
  warn "\nexpected 17, got ", $zop & $bitop, "\n";
  print "not ok 54\n";
}

if($checkop == $bitop) {print "ok 55\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 55\n";
}

########################################
########################################

$zop *= -1;

if(($zop & $bitop) == -21) {print "ok 56\n"}
else {
  warn "\nexpected -21, got ", $zop & $bitop, "\n";
  print "not ok 56\n";
}

if($checkop == $bitop) {print "ok 57\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 57\n";
}

########################################

########################################

$zop *= -1; # +17

if(($zop | $bitop) == -5) {print "ok 58\n"}
else {
  warn "\nexpected -5, got ", $zop | $bitop, "\n";
  print "not ok 58\n";
}

if($checkop == $bitop) {print "ok 59\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 59\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop | $bitop) == -1) {print "ok 60\n"}
else {
  warn "\nexpected -1, got ", $zop | $bitop, "\n";
  print "not ok 60\n";
}

if($checkop == $bitop) {print "ok 61\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 61\n";
}

########################################

########################################

$zop *= -1; # +17

if(($zop ^ $bitop) == -22) {print "ok 62\n"}
else {
  warn "\nexpected -22, got ", $zop ^ $bitop, "\n";
  print "not ok 62\n";
}

if($checkop == $bitop) {print "ok 63\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 63\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop ^ $bitop) == 20) {print "ok 64\n"}
else {
  warn "\nexpected 20, got ", $zop ^ $bitop, "\n";
  print "not ok 64\n";
}

if($checkop == $bitop) {print "ok 65\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 65\n";
}

########################################
#//////////////////////////////////////#
########################################

my $zcopy;

$zop *= -1; # +17
$zcopy = $zop;
$zcopy &= $bitop;

if($zcopy == 17) {print "ok 66\n"}
else {
  warn "\nexpected 17, got ", $zcopy, "\n";
  print "not ok 66\n";
}

if($checkop == $bitop) {print "ok 67\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 67\n";
}

########################################
########################################

$zop *= -1; # -17
$zcopy = $zop;
$zcopy &= $bitop;

if($zcopy == -21) {print "ok 68\n"}
else {
  warn "\nexpected -21, got ", $zcopy, "\n";
  print "not ok 68\n";
}

if($checkop == $bitop) {print "ok 69\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 69\n";
}

########################################

########################################

$zop *= -1; # +17
$zcopy = $zop;
$zcopy |= $bitop;

if($zcopy == -5) {print "ok 70\n"}
else {
  warn "\nexpected -5, got ", $zcopy, "\n";
  print "not ok 70\n";
}

if($checkop == $bitop) {print "ok 71\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 71\n";
}

########################################
########################################

$zop *= -1; # -17
$zcopy = $zop;
$zcopy |= $bitop;

if($zcopy == -1) {print "ok 72\n"}
else {
  warn "\nexpected -1, got ", $zcopy, "\n";
  print "not ok 72\n";
}

if($checkop == $bitop) {print "ok 73\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 73\n";
}

########################################

########################################

$zop *= -1; # +17
$zcopy = $zop;
$zcopy ^= $bitop;

if($zcopy == -22) {print "ok 74\n"}
else {
  warn "\nexpected -22, got ", $zcopy, "\n";
  print "not ok 74\n";
}

if($checkop == $bitop) {print "ok 75\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 75\n";
}

########################################
########################################

$zop *= -1; # -17
$zcopy = $zop;
$zcopy ^= $bitop;

if($zcopy == 20) {print "ok 76\n"}
else {
  warn "\nexpected 20, got ", $zcopy, "\n";
  print "not ok 76\n";
}

if($checkop == $bitop) {print "ok 77\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 77\n";
}

########################################
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
########################################

$zop *= -1; # 17

if(($zop * $bitop) == -85) {print "ok 78\n"}
else {
  warn "\nexpected -85, got ", $zop * $bitop, "\n";
  print "not ok 78\n";
}

if($checkop == $bitop) {print "ok 79\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 79\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop * $bitop) == 85) {print "ok 80\n"}
else {
  warn "\nexpected 85, got ", $zop* $bitop, "\n";
  print "not ok 80\n";
}

if($checkop == $bitop) {print "ok 81\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 81\n";
}

########################################

########################################

$zop *= -1; # +17

if(($zop + $bitop) == 12) {print "ok 82\n"}
else {
  warn "\nexpected 12, got ", $zop + $bitop, "\n";
  print "not ok 82\n";
}

if($checkop == $bitop) {print "ok 83\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 83\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop + $bitop) == -22) {print "ok 84\n"}
else {
  warn "\nexpected -22, got ", $zop + $bitop, "\n";
  print "not ok 84\n";
}

if($checkop == $bitop) {print "ok 85\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 85\n";
}

########################################

########################################

$zop *= -1; # +17

if(($zop - $bitop) == 22) {print "ok 86\n"}
else {
  warn "\nexpected 22, got ", $zop - $bitop, "\n";
  print "not ok 86\n";
}

if($checkop == $bitop) {print "ok 87\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 87\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop - $bitop) == -12) {print "ok 88\n"}
else {
  warn "\nexpected -12, got ", $zop - $bitop, "\n";
  print "not ok 88\n";
}

if($checkop == $bitop) {print "ok 89\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 89\n";
}

########################################
########################################

$zop *= -1; # +17

if(($zop / $bitop) == -3) {print "ok 90\n"}
else {
  warn "\nexpected -3, got ", $zop / $bitop, "\n";
  print "not ok 90\n";
}

if($checkop == $bitop) {print "ok 91\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 91\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop / $bitop) == 3) {print "ok 92\n"}
else {
  warn "\nexpected 3, got ", $zop / $bitop, "\n";
  print "not ok 92\n";
}

if($checkop == $bitop) {print "ok 93\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 93\n";
}

########################################

########################################

$zop *= -1; # +17

if(($zop % $bitop) == 2) {print "ok 94\n"}
else {
  warn "\nexpected 2, got ", $zop % $bitop, "\n";
  print "not ok 94\n";
}

if($checkop == $bitop) {print "ok 95\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 95\n";
}

########################################
########################################

$zop *= -1; # -17

if(($zop % $bitop) == 3) {print "ok 96\n"}
else {
  warn "\nexpected 3, got ", $zop % $bitop, "\n";
  print "not ok 96\n";
}

if($checkop == $bitop) {print "ok 97\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 97\n";
}

########################################
#//////////////////////////////////////#
########################################

$zop *= -1; # +17
$zcopy = $zop;
$zcopy *= $bitop;

if($zcopy == -85) {print "ok 98\n"}
else {
  warn "\nexpected -85, got ", $zcopy, "\n";
  print "not ok 98\n";
}

if($checkop == $bitop) {print "ok 99\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 99\n";
}

########################################
########################################

$zcopy = $zop;
$zcopy += $bitop;

if($zcopy == 12) {print "ok 100\n"}
else {
  warn "\nexpected 12, got ", $zcopy, "\n";
  print "not ok 100\n";
}

if($checkop == $bitop) {print "ok 101\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 101\n";
}

########################################

########################################

$zcopy = $zop;
$zcopy -= $bitop;

if($zcopy == 22) {print "ok 102\n"}
else {
  warn "\nexpected 22, got ", $zcopy, "\n";
  print "not ok 102\n";
}

if($checkop == $bitop) {print "ok 103\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 103\n";
}

########################################
########################################

$zcopy = $zop;
$zcopy /= $bitop;

if($zcopy == -3) {print "ok 104\n"}
else {
  warn "\nexpected -1, got ", $zcopy, "\n";
  print "not ok 104\n";
}

if($checkop == $bitop) {print "ok 105\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 105\n";
}

########################################

########################################

$zcopy = $zop;
$zcopy %= $bitop;

if($zcopy == 2) {print "ok 106\n"}
else {
  warn "\nexpected 2, got ", $zcopy, "\n";
  print "not ok 106\n";
}

if($checkop == $bitop) {print "ok 107\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 107\n";
}

########################################
########################################

$zop *= -1; # -17
$zcopy = $zop;
$zcopy %= $bitop;

if($zcopy == 3) {print "ok 108\n"}
else {
  warn "\nexpected 3, got ", $zcopy, "\n";
  print "not ok 108\n";
}

if($checkop == $bitop) {print "ok 109\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 109\n";
}

########################################


if($zop < $bitop) {print "ok 110\n"}
else {
  warn "\n$zop is not less than $bitop\n";
  print "not ok 110\n";
}

if($checkop == $bitop) {print "ok 111\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 111\n";
}

if($zop <= $bitop) {print "ok 112\n"}
else {
  warn "\n$zop is not less than or equal to $bitop\n";
  print "not ok 112\n";
}

if($checkop == $bitop) {print "ok 113\n"}
else {
  warn "\nexpected -5, got $bitop\n";
  print "not ok 113\n";
}

$zop *= -1;     # +17
$bitop -= 20;   # -25
$checkop -= 20; # -25

if($zop > $bitop) {print "ok 114\n"}
else {
  warn "\n$zop is not greater than $bitop\n";
  print "not ok 114\n";
}

if($checkop == $bitop) {print "ok 115\n"}
else {
  warn "\nexpected -25, got $bitop\n";
  print "not ok 115\n";
}

if($zop >= $bitop) {print "ok 116\n"}
else {
  warn "\n$zop is not greater than or equal to $bitop\n";
  print "not ok 116\n";
}

if($checkop == $bitop) {print "ok 117\n"}
else {
  warn "\nexpected -25, got $bitop\n";
  print "not ok 117\n";
}

if($zop != $bitop) {print "ok 118\n"}
else {
  warn "\n$zop is not equal to $bitop\n";
  print "not ok 118\n";
}

if($checkop == $bitop) {print "ok 119\n"}
else {
  warn "\nexpected -25, got $bitop\n";
  print "not ok 119\n";
}

my $c = $zop <=> $bitop;
if($c > 0) {print "ok 120\n"}
else {
  warn "\nexpected a positive value, got $c\n";
  print "not ok 120\n";
}

if($checkop == $bitop) {print "ok 121\n"}
else {
  warn "\nexpected -25, got $bitop\n";
  print "not ok 121\n";
}

$zop *= -2; # -34

$c = $zop <=> $bitop;
if($c < 0) {print "ok 122\n"}
else {
  warn "\nexpected a negative value, got $c\n";
  print "not ok 122\n";
}

if($checkop == $bitop) {print "ok 123\n"}
else {
  warn "\nexpected -25, got $bitop\n";
  print "not ok 123\n";
}




