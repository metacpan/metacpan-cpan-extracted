# Test overloaded '**' and '**=' ops with integer exponents - including
# Math::GMPz objects, Math::GMP objects, Math::GMPq objects and PVs.

use strict;
use warnings;
use Math::GMPq qw(:mpq);

use Test::More;

my($have_gmpz, $have_gmp) = (0, 0);

eval { require Math::GMPz;};
$have_gmpz = 1 unless $@;

eval { require Math::GMP;};
$have_gmp = 1 unless $@;

if($have_gmpz) {
  my $rop = Math::GMPq->new('2/3') ** Math::GMPz->new(3);
  cmp_ok(ref($rop), 'eq', 'Math::GMPq', "Test 1: returned a Math::GMPq object");
  cmp_ok("$rop", 'eq', '8/27', "Test 2: returned correct value");

  eval {$rop = Math::GMPq->new(5) ** Math::GMPz->new('1' x 36);};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow/, "Test 3: Produced expected error");

  my $q = Math::GMPq->new('3/4');
  $q **= Math::GMPz->new(3);
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "Test 4: returned a Math::GMPq object");
  cmp_ok("$q", 'eq', '27/64', "Test 5: returned correct value");

  eval {$q **= Math::GMPz->new('1' x 36);};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow_eq/, "Test 6: Produced expected error");
}

if($have_gmp) {
  my $rop = Math::GMPq->new('2/3') ** Math::GMP->new(3);
  cmp_ok(ref($rop), 'eq', 'Math::GMPq', "Test 7: returned a Math::GMPq object");
  cmp_ok("$rop", 'eq', '8/27', "Test 8: returned correct value");

  eval {$rop = Math::GMPq->new(5) ** Math::GMP->new('1' x 36);};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow/, "Test 9: Produced expected error");

  my $q = Math::GMPq->new('3/4');
  $q **= Math::GMP->new(3);
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "Test 10: returned a Math::GMPq object");
  cmp_ok("$q", 'eq', '27/64', "Test 11: returned correct value");

  eval {$q **= Math::GMP->new('1' x 36);};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow_eq/, "Test 12: Produced expected error");
}

######## TESTING STRINGS ########

my $rop = Math::GMPq->new('2/3') ** '3';
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "Test 13: returned a Math::GMPq object");
cmp_ok("$rop", 'eq', '8/27', "Test 14: returned correct value");

$rop **= '2';
cmp_ok(ref($rop), 'eq', 'Math::GMPq', "Test 15: returned a Math::GMPq object");
cmp_ok("$rop", 'eq', '64/729', "Test 16: returned correct value");

eval { $rop **= '+3';};
like($@, qr/Invalid string passed to Math::GMPq::overload_pow_eq/, "Test 17: Produced expected error");

eval { $rop **= '-3';};
like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow_eq/, "Test 18: Produced expected error");

eval { $rop **= '3.1';};
like($@, qr/Invalid string passed to Math::GMPq::overload_pow_eq/, "Test 19: Produced expected error");

######## TESTING Math::GMPq OBJECTS ########

eval { $rop = Math::GMPq->new('2/3') ** Math::GMPq->new(3);};
like($@, qr/^Raising a value to an mpq_t power is not allowed/, "Test 20: Produced expected error");

eval { $rop **= Math::GMPq->new(3);};
like($@, qr/^Invalid argument supplied to Math::GMPq::overload_pow_eq function/, "Test 21: Produced expected error");

eval { $rop = Math::GMPq->new('2/3') ** Math::GMPq->new('3/4');};
like($@, qr/^Raising a value to an mpq_t power is not allowed/, "Test 22: Produced expected error");

eval { $rop **= Math::GMPq->new('3/4');};
like($@, qr/^Invalid argument supplied to Math::GMPq::overload_pow_eq function/, "Test 23: Produced expected error");

done_testing();
