# Test cross class overloading of +=, *=, -=, /=, ....
# for the cases where the second arg is either a
# a Math::GMPq object or a Math::MPFR object.
# In these cases the operation returns a Math::GMPq
# or (respectively) a Math::MPFR object.

use strict;
use warnings;
use Math::GMPz qw(:mpz);

use Test::More;

my $have_mpfr = 0;
eval {require Math::MPFR;};
$have_mpfr = 1 unless $@;

my $have_gmpq = 0;
eval {require Math::GMPq;};
$have_gmpq = 1 unless $@;


my $z1 = Math::GMPz->new(123);
my $z2 = Math::GMPz->new(123);
my $q = 0;
$q  = Math::GMPq->new('1/11') if $have_gmpq;
my $fr = 0;
$fr = Math::MPFR->new(17.1) if $have_mpfr;

eval {$z1 /= 0;};
like($@, qr/^Division by 0 not allowed/, 'division by 0 is illegal');

if($have_gmpq) {
  if($Math::GMPq::VERSION < 0.43) {
    warn "\n  Skipping Math::GMPq tests -  Math::GMPq version 0.35(or later)\n" .
          "  is needed. We have only version $Math::GMPq::VERSION\n";
  }
  else {
    my $z = Math::GMPz->new(123);
    $z *= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', $q * Math::GMPz->new(123), '$z *= $q sets $z to 123/11');

    $z = Math::GMPz->new(123);
    cmp_ok(ref($z), 'eq', 'Math::GMPz', '$z has been reverted to a Math::GMPz object');
    $z += $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', $q + Math::GMPz->new(123), '$z += $q sets $z to 1354/11');

    $z = Math::GMPz->new(123);
    $z -= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', Math::GMPz->new(123) - $q, '$z -= $q sets $z to 1352/11');

    $z = Math::GMPz->new(123);
    $z /= $q;
    cmp_ok(ref($z), 'eq', 'Math::GMPq', '$z changes to a Math::GMPq object');
    cmp_ok($z, '==', Math::GMPz->new(123) / $q, '$z /= $q sets $z to 1353');
  }
}

############################################

if($have_mpfr) {
  if($Math::MPFR::VERSION < 4.19) {
    warn "\n  Skipping remaining tests -  Math::MPFR version 4.19 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
  }
  else {
    my $z = Math::GMPz->new(123);
    cmp_ok(ref($z), 'eq', 'Math::GMPz', '$z has been reverted to a Math::GMPz object');
    $z *= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', $fr * Math::GMPz->new(123), '$z *= $fr sets $z to 2.1033000000000002e3');

    $z = Math::GMPz->new(123);
    $z += $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', $fr + Math::GMPz->new(123), '$z += $fr sets $z to 1.4009999999999999e2');

    $z = Math::GMPz->new(123);
    $z -= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(123) - $fr, '$z -= $fr sets $z to 1.0590000000000001e2');

    $z = Math::GMPz->new(123);
    $z /= $fr;
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(123) / $fr, '$z /= $fr sets $z to 7.1929824561403501');

    $z = Math::GMPz->new(2);
    $z **= Math::MPFR->new(0.5);
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(2) ** Math::MPFR->new(0.5), '$z **= $Math::MPFR->new(0.5) sets $z to 1.4142135623730951');

    $z = Math::GMPz->new(2);
    Math::MPFR::Rmpfr_set_default_prec(113);
    $z **= Math::MPFR->new(0.5);
    cmp_ok(ref($z), 'eq', 'Math::MPFR', '$z changes to a Math::MPFR object');
    cmp_ok($z, '==', Math::GMPz->new(2) ** Math::MPFR->new(0.5), '$z **= Math::MPFR->new(0.5) sets $z to 1.41421356237309504880168872420969798');
  }

}

done_testing();
