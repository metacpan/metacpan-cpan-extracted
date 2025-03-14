# Some basic tests to check that Math::GMPz overloading of
# comparison operators works correctly with Math::MPFR objects.

use strict;
use warnings;
use Math::GMPz;

use Test::More;

eval {require Math::MPFR;};

if($@) {
  is(1, 1);
  warn "Skipping all tests - unable to load Math::MPFR";
  done_testing();
  exit 0;
}
else {
  if(Math::MPFR::MPFR_VERSION_MAJOR() < 3) {
    is(1, 1);
    warn "Skipping all tests - Math::MPFR needs to have been built against mpfr-3.0.0 or later";
    done_testing();
    exit 0;
  }
}

my $mpz = Math::GMPz->new(2);

my $ok = 0;
$ok = 1 if !defined($mpz <=> Math::MPFR->new());
cmp_ok($ok, '==', 1, "GMPZ <==> MPFR(NaN) not defined");

$ok = 0;
my $res = ($mpz == Math::MPFR->new());
$ok = 1 if(defined($res) && $res == 0);
cmp_ok($ok, '==', 1, "GMPZ == MPFR(NaN) returns 0");


$ok = 0;
$res = ($mpz != Math::MPFR->new());
$ok = 1 if(defined($res) && $res == 1);
cmp_ok($ok, '==', 1, "GMPZ != MPFR(NaN) returns 1");

my $mpfr = Math::MPFR->new(2.5);
cmp_ok(($mpz > $mpfr), '==',  0,  "$mpfr: '>'  ok");
cmp_ok(($mpz < $mpfr), '==' , 1,  "$mpfr: '<'  ok");
cmp_ok(($mpz == $mpfr), '==', 0, "$mpfr: '==' ok");
cmp_ok(($mpz != $mpfr), '==', 1, "$mpfr: '!=' ok");
cmp_ok(($mpz >= $mpfr), '==', 0, "$mpfr: '>=' ok");
cmp_ok(($mpz <= $mpfr), '==', 1, "$mpfr: '<=' ok");
cmp_ok(($mpz <=> $mpfr), '==', -1, "$mpfr: '<=>' ok");

Math::MPFR::Rmpfr_set_NV($mpfr, 2.0, 0);
cmp_ok(($mpz > $mpfr), '==',  0,  "$mpfr: '>'  ok");
cmp_ok(($mpz < $mpfr), '==' , 0,  "$mpfr: '<'  ok");
cmp_ok(($mpz == $mpfr), '==', 1, "$mpfr: '==' ok");
cmp_ok(($mpz != $mpfr), '==', 0, "$mpfr: '!=' ok");
cmp_ok(($mpz >= $mpfr), '==', 1, "$mpfr: '>=' ok");
cmp_ok(($mpz <= $mpfr), '==', 1, "$mpfr: '<=' ok");
cmp_ok(($mpz <=> $mpfr), '==', 0, "$mpfr: '<=>' ok");

Math::MPFR::Rmpfr_set_NV($mpfr, 1.5, 0);
cmp_ok(($mpz > $mpfr), '==',  1,  "$mpfr: '>'  ok");
cmp_ok(($mpz < $mpfr), '==' , 0,  "$mpfr: '<'  ok");
cmp_ok(($mpz == $mpfr), '==', 0, "$mpfr: '==' ok");
cmp_ok(($mpz != $mpfr), '==', 1, "$mpfr: '!=' ok");
cmp_ok(($mpz >= $mpfr), '==', 1, "$mpfr: '>=' ok");
cmp_ok(($mpz <= $mpfr), '==', 0, "$mpfr: '<=' ok");
cmp_ok(($mpz <=> $mpfr), '==', 1, "$mpfr: '<=>' ok");

done_testing();

