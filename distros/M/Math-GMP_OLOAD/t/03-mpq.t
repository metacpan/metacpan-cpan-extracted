# Testing extended overloading of gmp objects with Math::GMPq.

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

eval { require Math::GMPq;};

if($@) {
  warn "\$\@: $@\n";
  plan skip_all => 'Math::GMPq failed to load';
  done_testing();
  exit 0;
}

if($Math::GMPq::VERSION < 0.69) {
  plan skip_all => " Math::GMPq::VERSION ($Math::GMPq::VERSION) not supported - need at least 0.69.";
  done_testing();
  exit 0;
}

if($Math::GMP::VERSION < 2.11) {
  plan skip_all => " Math::GMP::VERSION ($Math::GMP::VERSION) not supported - need at least 2.11.";
  done_testing();
  exit 0;
}

my $q0 = Math::GMPq->new('2/3');
my $q1 = $q0 ** 3;
cmp_ok("$q1", 'eq', '8/27', "GMPq ** 3 returns expected value");
$q0 **= 4;
cmp_ok("$q0", 'eq', '16/81', "GMPq **= 4 returns expected value");
my $n = 5;
my $q2 = $n / $q0;
cmp_ok("$q2", 'eq', '405/16', "5 / GMPq returns expected value");

$n += 2;
$n /= $q2;
cmp_ok(ref($n), 'eq', 'Math::GMPq', "IV / GMPq returns GMPq");
cmp_ok("$n", 'eq', '112/405',       "IV / GMPq returns correct value");


##### START EXPERIMENTAL #####

my $rop;
my $gmpq_big = Math::GMPq->new(100);
my $gmp_big  = Math::GMP->new(100);

my $gmpq_tiny = Math::GMPq->new(5);
my $gmp_tiny =  Math::GMP->new(5);

cmp_ok($gmpq_big, '>', $gmp_tiny, "GMPQ_BIG > GMP_TINY");
cmp_ok($gmp_tiny, '<', $gmpq_big, "GMP_TINY < GMPQ_BIG");
cmp_ok($gmpq_big, '>=', $gmp_tiny, "GMPQ_BIG >= GMP_TINY");
cmp_ok($gmp_tiny, '<=', $gmpq_big, "GMP_TINY <= GMPQ_BIG");
cmp_ok($gmpq_big, '>=', $gmp_big, "GMPQ_BIG >= GMP_BIG");
cmp_ok($gmp_big, '<=', $gmpq_big, "GMP_BIG <= GMPQ_BIG");
cmp_ok($gmpq_big, '==', $gmp_big, "GMPQ_BIG == GMP_BIG");
cmp_ok($gmp_big, '==', $gmpq_big, "GMP_BIG == GMPQ_BIG");
cmp_ok($gmpq_big, '!=', $gmp_tiny, "GMPQ_BIG != GMP_TINY");
cmp_ok($gmp_big, '!=', $gmpq_tiny, "GMP_BIG != GMPQ_TINY");
cmp_ok(($gmpq_big <=> $gmp_tiny), '>', 0, "GMPQ_BIG <=> GMP_TINY > 0");
cmp_ok(($gmp_big <=> $gmpq_tiny), '>', 0, "GMP_BIG <=> GMPQ_TINY > 0");
##################################
$rop = $gmpq_big + $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMPq + GMP returns GMPq");
cmp_ok($rop, '==', 105, "GMPq + GMP returns correct value");

$rop = $gmpq_big - $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMPq - GMP returns GMPq");
cmp_ok($rop, '==', 95, "GMPq + GMP returns correct value");

$rop = $gmpq_big * $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMPq * GMP returns GMPq");
cmp_ok($rop, '==', 500, "GMPq * GMP returns correct value");

$rop = $gmpq_big / $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMPq / GMP returns GMPq");
cmp_ok($rop, '==', 20, "GMPq / GMP returns correct value");

$rop = $gmpq_big ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMPq ** GMP returns GMPq");
cmp_ok($rop, '==', 10000000000, "GMPq ** GMP returns correct value");

###################################
$rop = $gmp_tiny + $gmpq_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMP + GMPq returns GMPq");
cmp_ok($rop, '==', 10, "GMPq + GMP returns correct value");

$rop = $gmp_tiny - $gmpq_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMP - GMPq returns GMPq");
cmp_ok($rop, '==', 0, "GMPq + GMP returns correct value");

$rop = $gmp_tiny * $gmpq_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMP * GMPq returns GMPq");
cmp_ok($rop, '==', 25, "GMPq * GMP returns correct value");

$rop = $gmp_tiny / $gmpq_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "GMP / GMPq returns GMPq");
cmp_ok($rop, '==', 1, "GMP / GMPq returns correct value");

eval { $rop = $gmp_tiny ** $gmpq_tiny;};
like($@, qr/^Raising a value to an mpq_t power is not allowed/, "GMP ** GMPq produces expected error");

$rop = $gmp_tiny ** 5;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "GMP ** IV returns GMP");
cmp_ok($rop, '==', 3125, "GMP ** IV returns correct value");

$rop = 6 ** $gmp_tiny;
cmp_ok(ref($rop), 'eq', 'Math::GMP', "IV ** GMP returns GMP");
cmp_ok($rop, '==', 7776, "IV ** GMP returns correct value");
##################################
my $op_gmp = Math::GMP->new(6);
my $op_gmpq = Math::GMPq->new(5);

$op_gmpq *=  $op_gmp;
cmp_ok(ref($op_gmpq), 'eq', 'Math::GMPq', "GMPq *= GMP returns GMPq");
cmp_ok($op_gmpq, '==', 30, "GMPq *= GMP returns correct value");

$op_gmp *=  $op_gmpq;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPq', "GMP *= GMPq returns GMPq");
cmp_ok($op_gmp, '==', 180, "GMPq *= GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpq = Math::GMPq->new(5);

$op_gmpq +=  $op_gmp;
cmp_ok(ref($op_gmpq), 'eq', 'Math::GMPq', "GMPq += GMP returns GMPq");
cmp_ok($op_gmpq, '==', 11, "GMPq += GMP returns correct value");

$op_gmp +=  $op_gmpq;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPq', "GMP += GMPq returns GMPq");
cmp_ok($op_gmp, '==', 17, "GMPq += GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpq = Math::GMPq->new(5);

$op_gmpq /=  $op_gmp;
cmp_ok(ref($op_gmpq), 'eq', 'Math::GMPq', "GMPq /= GMP returns GMPq");
cmp_ok($op_gmpq, '==', Math::GMPq->new(5) / 6, "GMPq /= GMP returns correct value");

$op_gmp /=  $op_gmpq;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPq', "GMP /= GMPq returns GMPq");
cmp_ok($op_gmp, '==', 6 / (Math::GMPq->new(5) / 6), "GMPq /= GMP returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpq = Math::GMPq->new(5);

$op_gmpq -=  $op_gmp;
cmp_ok(ref($op_gmpq), 'eq', 'Math::GMPq', "GMPq -= GMP returns GMPq");
cmp_ok($op_gmpq, '==', -1, "GMPq -= GMP returns correct value");

$op_gmp -=  $op_gmpq;
cmp_ok(ref($op_gmp), 'eq', 'Math::GMPq', "GMP -= GMPq returns GMPq");
cmp_ok($op_gmp, '==', 7, "GMP -= GMPq returns correct value");

$op_gmp = Math::GMP->new(6);
$op_gmpq = Math::GMPq->new(5);

$op_gmpq **=  $op_gmp;
cmp_ok(ref($op_gmpq), 'eq', 'Math::GMPq', "GMPq **= GMP returns GMPq");
cmp_ok($op_gmpq, '==', 15625, "GMPq **= GMP returns correct value");

eval { $op_gmp **=  $op_gmpq;};
like($@, qr/^Raising a value to an mpq_t power is not allowed/, "GMP **= GMPq produces expected error");
##################################
cmp_ok(($gmp_tiny <=> $gmpq_big), '<', 0, "GMP_TINY <=> GMPQ_BIG < 0");
cmp_ok(($gmpq_tiny <=> $gmp_big), '<', 0, "GMPQ_TINY <=> GMP_BIG < 0");
cmp_ok($gmpq_big, '>', $gmpq_tiny, "GMPQ_BIG > GMPQ_TINY");
cmp_ok($gmpq_tiny, '<', $gmpq_big, "GMPQ_TINY < GMPQ_BIG");
cmp_ok($gmpq_big, '>=', $gmpq_tiny, "GMPQ_BIG >= GMPQ_TINY");
cmp_ok($gmpq_tiny, '<=', $gmpq_big, "GMPQ_TINY <= GMPQ_BIG");
cmp_ok($gmpq_tiny, '>=', $gmpq_tiny, "GMPQ_TINY >= GMPQ_TINY");
cmp_ok($gmpq_tiny, '<=', $gmpq_tiny, "GMPQ_TINY <= GMPQ_TINY");
cmp_ok($gmpq_tiny, '==', $gmpq_tiny, "GMPQ_TINY == GMPQ_TINY");
cmp_ok($gmpq_big, '!=', $gmpq_tiny, "GMPQ_BIG != GMPQ_TINY");
cmp_ok(($gmpq_tiny <=> $gmpq_tiny), '==', 0, "GMPQ_TINY <=> GMPQ_TINY == 0");
cmp_ok(($gmpq_big <=> $gmpq_tiny), '>', 0, "GMPQ_BIG <=> GMPQ_TINY > 0");
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

eval { $rop = Math::GMP->new(11) ** Math::GMPq->new(2);};
like($@, qr/^Raising a value to an mpq_t power is not allowed/, "GMP ** GMPq produces expected error");

done_testing();
