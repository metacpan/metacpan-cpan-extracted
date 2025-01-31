use strict;
use warnings;
use Test::More;

use Math::BigInt;

BEGIN{
 if($] < 5.022) {
   print "1..1\n";
   warn "\n skipping all tests - 'bitwise' feature not available\n";
   print "ok 1\n";
   exit;
   }
};

use feature 'bitwise';
use Math::GMPz qw(:mpz);
no warnings 'experimental::bitwise';

warn "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $x = Math::GMPz->new(1231);
my $y = Math::GMPz->new(119);
my $mbix = Math::BigInt->new(1231);
my $mbiy = Math::BigInt->new(119);

cmp_ok(71, '==',   $x & $y, "TEST 1");
cmp_ok(1279, '==', $x | $y, "TEST 2");
cmp_ok(1208, '==', $x ^ $y, "TEST 3");
cmp_ok($x - (~$x), '==', 2463, "TEST 4");
cmp_ok($y - (~$y), '==', 239, "TEST 5");

$x &= 124;
cmp_ok($x, '==', 76, "TEST 6");

$x |= $y;
cmp_ok($x, '==', 127, "TEST 7");

$x ^= 12;
cmp_ok($x, '==', 115, "TEST 8");

Rmpz_set_ui($x, 1231); # restore to original value

cmp_ok(71, '==',   $x & $mbiy, "TEST 9");
cmp_ok(1279, '==', $x | $mbiy, "TEST 10");
cmp_ok(1208, '==', $x ^ $mbiy, "TEST 11");
cmp_ok($x - (~$mbix), '==', 2463, "TEST 12");
cmp_ok($y - (~$mbiy), '==', 239, "TEST 13");

cmp_ok($x, '==', 1231, "TEST 14");
($x <<= 3) >>= 3;
cmp_ok($x, '==', 1231, "TEST 15");
($x >>= 2) <<= 2;
cmp_ok($x, '==', 1228, "TEST 16");

done_testing();

