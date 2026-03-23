# Testing extended overloading of gmp objects with Math::GMPz.

use strict;
use warnings;

use Test::More;

eval { require Math::GMP_OLOAD;};

if($@) {
  warn "\$\@: $@\n";
  plan skip_all => 'Math::GMP_OLOAD failed to load';
  done_testing();
  exit 0;
}

eval { require Math::GMPz;};

if($@) {
  warn "\$\@: $@\n";
  plan skip_all => 'Math::GMPz failed to load';
  done_testing();
  exit 0;
}

if($Math::GMPz::VERSION < 0.68) {
  plan skip_all => " Math::GMPz::VERSION ($Math::GMPz::VERSION) not supported - need at least 0.68.";
  done_testing();
  exit 0;
}

if($Math::GMP::VERSION < 2.11) {
  plan skip_all => " Math::GMP::VERSION ($Math::GMP::VERSION) not supported - need at least 2.11.";
  done_testing();
  exit 0;
}


my $z0 = Math::GMPz->new(2);
my $z1 = $z0 ** 3;
cmp_ok("$z1", 'eq', '8', "GMPz ** 3 returns expected value");
$z0 **= 4;
cmp_ok("$z0", 'eq', '16', "GMPz **= 4 returns expected value");
my $n = 250;
my $z2 = $n / $z0;
cmp_ok("$z2", 'eq', '15', "250 / GMPz returns expected value");

$n *= 5;
$n /= $z2;
cmp_ok(ref($n), 'eq', 'Math::GMPz', "IV / GMPz returns GMPz");
cmp_ok("$n", 'eq', '83',       "IV / GMPz returns correct value");


##### START EXPERIMENTAL #####

my $rop;
my $gmpz_big = Math::GMPz->new(100);
my $gmp_big  = Math::GMP->new(100);

my $gmpz_tiny = Math::GMPz->new(5);
my $gmp_tiny =  Math::GMP->new(5);

cmp_ok($gmpz_big, '>', $gmp_tiny, "GMPZ_BIG > GMP_TINY");
cmp_ok($gmp_tiny, '<', $gmpz_big, "GMP_TINY < GMPZ_BIG");
cmp_ok($gmpz_big, '>=', $gmp_tiny, "GMPZ_BIG >= GMP_TINY");
cmp_ok($gmp_tiny, '<=', $gmpz_big, "GMP_TINY <= GMPZ_BIG");
cmp_ok($gmpz_big, '>=', $gmp_big, "GMPZ_BIG >= GMP_BIG");
cmp_ok($gmp_big, '<=', $gmpz_big, "GMP_BIG <= GMPZ_BIG");
cmp_ok($gmpz_big, '==', $gmp_big, "GMPZ_BIG == GMP_BIG");
cmp_ok($gmp_big, '==', $gmpz_big, "GMP_BIG == GMPZ_BIG");
cmp_ok($gmpz_big, '!=', $gmp_tiny, "GMPZ_BIG != GMP_TINY");
cmp_ok($gmp_big, '!=', $gmpz_tiny, "GMP_BIG != GMPZ_TINY");
cmp_ok(($gmpz_big <=> $gmp_tiny), '>', 0, "GMPZ_BIG <=> GMP_TINY > 0");
cmp_ok(($gmp_big <=> $gmpz_tiny), '>', 0, "GMP_BIG <=> GMPZ_TINY > 0");
##################################
$rop = $gmpz_big + $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMPz + GMP returns GMPz");
cmp_ok($rop, '==', 105, "GMPz + GMP returns correct value");

$rop = $gmpz_big - $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMPz - GMP returns GMPz");
cmp_ok($rop, '==', 95, "GMPz + GMP returns correct value");

$rop = $gmpz_big * $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMPz * GMP returns GMPz");
cmp_ok($rop, '==', 500, "GMPz * GMP returns correct value");

$rop = $gmpz_big / $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMPz / GMP returns GMPz");
cmp_ok($rop, '==', 20, "GMPz / GMP returns correct value");

$rop = $gmpz_big ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMPz ** GMP returns GMPz");
cmp_ok($rop, '==', 10000000000, "GMPz ** GMP returns correct value");
###################################
$rop = $gmp_tiny + $gmpz_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMP + GMPz returns GMPz");
cmp_ok($rop, '==', 10, "GMPz + GMP returns correct value");

$rop = $gmp_tiny - $gmpz_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMP - GMPz returns GMPz");
cmp_ok($rop, '==', 0, "GMPz + GMP returns correct value");

$rop = $gmp_tiny * $gmpz_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMP * GMPz returns GMPz");
cmp_ok($rop, '==', 25, "GMPz * GMP returns correct value");

$rop = $gmp_tiny / $gmpz_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMP / GMPz returns GMPz");
cmp_ok($rop, '==', 1, "GMP / GMPz returns correct value");

$rop = $gmp_tiny ** $gmpz_tiny;
print "\n\n", ref($gmp_tiny), " ($gmp_tiny) ** ", ref($gmpz_tiny), " ($gmpz_tiny)  == ", ref($rop), " ($rop)\n\n";

cmp_ok(ref($rop), 'eq', 'Math::GMPz', "GMP ** GMPz returns GMPz");
cmp_ok($rop, '==', 3125, "GMP ** GMPz returns correct value");


$rop = $gmp_tiny ** 5;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "GMP ** IV returns GMP");
cmp_ok($rop, '==', 3125, "GMP ** IV returns correct value");

$rop = 6 ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "IV ** GMP returns GMP");
cmp_ok($rop, '==', 7776, "IV ** GMP returns correct value");
##################################
my $op_gmp = Math::GMP->new(6);
my $op_gmpz = Math::GMPz->new(5);

$op_gmpz *=  $op_gmp;
cmp_ok(ref($op_gmpz), 'eq', 'Math::GMPz', "GMPz *= GMP returns GMPz");
cmp_ok($op_gmpz, '==', 30, "GMPz *= GMP returns correct value");

$op_gmp *=  $op_gmpz;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPz', "GMP *= GMPz returns GMPz");
cmp_ok($op_gmp, '==', 180, "GMPz *= GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpz = Math::GMPz->new(5);

$op_gmpz +=  $op_gmp;
cmp_ok(ref($op_gmpz), 'eq', 'Math::GMPz', "GMPz += GMP returns GMPz");
cmp_ok($op_gmpz, '==', 11, "GMPz += GMP returns correct value");

$op_gmp +=  $op_gmpz;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPz', "GMP += GMPz returns GMPz");
cmp_ok($op_gmp, '==', 17, "GMPz += GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpz = Math::GMPz->new(5);

$op_gmpz /=  $op_gmp;
cmp_ok(ref($op_gmpz), 'eq', 'Math::GMPz', "GMPz /= GMP returns GMPz");
cmp_ok($op_gmpz, '==', 0, "GMPz /= GMP returns correct value");

$op_gmpz += 2;

print "\n\nOP_GMP: $op_gmp OP_GMPZ: $op_gmpz\n\n";

$op_gmp /=  $op_gmpz;

cmp_ok(ref($op_gmp), 'eq', 'Math::GMPz', "GMP /= GMPz returns GMPz");
cmp_ok($op_gmp, '==', 3, "GMP /= GMPz returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpz = Math::GMPz->new(5);

$op_gmpz -=  $op_gmp;
cmp_ok(ref($op_gmpz), 'eq', 'Math::GMPz', "GMPz -= GMP returns GMPz");
cmp_ok($op_gmpz, '==', -1, "GMPz -= GMP returns correct value");

$op_gmp -=  $op_gmpz;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPz', "GMP -= GMPz returns GMPz");
cmp_ok($op_gmp, '==', 7, "GMP -= GMPz returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpz = Math::GMPz->new(5);

$op_gmpz **=  $op_gmp;
cmp_ok(ref($op_gmpz), 'eq', 'Math::GMPz', "GMPz **= GMP returns GMPz");
cmp_ok($op_gmpz, '==', 15625, "GMPz **= GMP returns correct value");

$op_gmpz -= 15610; # Now == 15

cmp_ok($op_gmpz, '==', 15, "GMPz sanity check");
cmp_ok($op_gmp, '==', 6, "GMP_sanity check");

$op_gmp **=  $op_gmpz;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPz', "GMP **= GMPz returns GMPz");
cmp_ok($op_gmp, '==', 470184984576, "GMP **= GMPz returns correct value");

##################################
cmp_ok(($gmp_tiny <=> $gmpz_big), '<', 0, "GMP_TINY <=> GMPZ_BIG < 0");
cmp_ok(($gmpz_tiny <=> $gmp_big), '<', 0, "GMPZ_TINY <=> GMP_BIG < 0");
cmp_ok($gmpz_big, '>', $gmpz_tiny, "GMPZ_BIG > GMPZ_TINY");
cmp_ok($gmpz_tiny, '<', $gmpz_big, "GMPZ_TINY < GMPZ_BIG");
cmp_ok($gmpz_big, '>=', $gmpz_tiny, "GMPZ_BIG >= GMPZ_TINY");
cmp_ok($gmpz_tiny, '<=', $gmpz_big, "GMPZ_TINY <= GMPZ_BIG");
cmp_ok($gmpz_tiny, '>=', $gmpz_tiny, "GMPZ_TINY >= GMPZ_TINY");
cmp_ok($gmpz_tiny, '<=', $gmpz_tiny, "GMPZ_TINY <= GMPZ_TINY");
cmp_ok($gmpz_tiny, '==', $gmpz_tiny, "GMPZ_TINY == GMPZ_TINY");
cmp_ok($gmpz_big, '!=', $gmpz_tiny, "GMPZ_BIG != GMPZ_TINY");
cmp_ok(($gmpz_tiny <=> $gmpz_tiny), '==', 0, "GMPZ_TINY <=> GMPZ_TINY == 0");
cmp_ok(($gmpz_big <=> $gmpz_tiny), '>', 0, "GMPZ_BIG <=> GMPZ_TINY > 0");

cmp_ok($gmp_big, '>', $gmp_tiny, "GMP_BIG > GMP_TINY");
cmp_ok($gmp_tiny, '<', $gmp_big, "GMP_TINY < GMP_BIG");
cmp_ok($gmp_big, '>=', $gmp_tiny, "GMP_BIG >= GMP_TINY");

cmp_ok(200, '>', $gmp_big, "200 > GMP_BIG");
cmp_ok(200, '>=', $gmp_big, "200 >= GMP_BIG");

cmp_ok($gmp_big, '<', 200, "GMP_BIG < 200");
cmp_ok($gmp_big, '<=', 200, "GMP_BIG <= 200");

cmp_ok((5 <=> $gmp_tiny), '==', 0, "5 <=> GMP_TINY == 0");
cmp_ok(($gmp_tiny <=> 5), '==', 0, "GMP_TINY <=> 5 == 0");

cmp_ok((6 <=> $gmp_tiny), '>', 0, "6 <=> GMP_TINY > 0");
cmp_ok(($gmp_tiny <=> 6), '<', 0, "GMP_TINY <=> 6 < 0");

cmp_ok($gmp_tiny, '<=', $gmp_big, "GMP_TINY <= GMP_BIG");
cmp_ok($gmp_tiny, '>=', $gmp_tiny, "GMP_TINY >= GMP_TINY");
cmp_ok($gmp_tiny, '<=', $gmp_tiny, "GMP_TINY <= GMP_TINY");
cmp_ok($gmp_tiny, '==', $gmp_tiny, "GMP_TINY == GMP_TINY");
cmp_ok($gmp_big, '!=', $gmp_tiny, "GMP_BIG != GMP_TINY");

cmp_ok(($gmp_tiny <=> $gmp_tiny), '==', 0, "GMP_TINY <=> GMP_TINY == 0");
cmp_ok(($gmp_big <=> $gmp_tiny), '>', 0, "GMP_BIG <=> GMP_TINY > 0");

done_testing();
