# Firstly some tests that overloaded '>>', '>>=', '<<' and '>>='
# on Math::GMPz objects whose value is -ve  work correctly.

# Then check that NVs are accepted.

# Then check that bad second args are detected.

use strict;
use warnings;

use Math::GMPz qw(:mpz);
use Math::BigInt;
use Math::BigFloat;
use Config;

use Test::More;

my $z = Math::GMPz->new(-401);
my $rs = $z >> 1;
cmp_ok($rs, '==', -201, " -401 >> 1 works correctly");

$rs = $z << 1;
cmp_ok($rs, '==', -802, " -401 >> 1 works correctly");

cmp_ok($z >> 1, '==', $z << -1, ">> 1 equates to << -1");
cmp_ok($z >> -1, '==', $z << 1, ">> -1 equates to << 1");

$z >>= 1;
cmp_ok($z, '==', -201, " -401 >>= 1 works correctly");

$z >>= -1;
cmp_ok($z, '==', -402, " -201 >>= -1 works correctly");

$z <<= 1;
cmp_ok($z, '==', -804, " -402 <<= 1 works correctly");

$z <<= -1;
cmp_ok($z, '==', -402, " -804 << -1 works correctly");

Rmpz_set_ui($z, 500);
cmp_ok($z >> '2.7', '==', 125,  "500 >> '2.7' == 125");
cmp_ok($z << '3.8', '==', 4000, "500 << '3.8' == 4000");

$z >>= '1.9';
cmp_ok($z, '==', 250, "500 >>= '1.9' returns 250");

$z <<= '2.01';
cmp_ok($z, '==', 1000, "250 >>= '2.01' returns 1000");

eval { my $discard = 2 >> Math::GMPz->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "switched overload throws expected error");

eval {my $discard = $z >> Math::BigInt->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "Math::BigInt shift arg throws expected error");

eval {$z <<= Math::BigInt->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "Math::BigFloat shift arg throws expected error");

if($Config{longsize} < $Config{ivsize}) {
  eval { my $discard = $z >> ~0;};
  like ( $@, qr/Magnitude of UV argument overflows mp_bitcnt_t/, "mp_bitcnt_t overflow is caught in '>>'");

  eval { my $discard = $z << ~0;};
  like ( $@, qr/Magnitude of UV argument overflows mp_bitcnt_t/, "mp_bitcnt_t overflow is caught in '<<'");

  eval { $z >>= ~0;};
  like ( $@, qr/Magnitude of UV argument overflows mp_bitcnt_t/, "mp_bitcnt_t overflow is caught in '>>='");

  eval { $z <<= ~0;};
  like ( $@, qr/Magnitude of UV argument overflows mp_bitcnt_t/, "mp_bitcnt_t overflow is caught in '<<='");
}

done_testing();
