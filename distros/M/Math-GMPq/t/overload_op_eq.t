# Test cross class overloading of +=, *=, -=, /=,
# and **= for the cases where the second arg is a
# Math::MPFR object.
# In these cases the operation returns a Math::MPFR object

use strict;
use warnings;
use Math::GMPq qw(:mpq);

use Test::More;

my $have_mpfr = 0;
eval {require Math::MPFR;};
$have_mpfr = 1 unless $@;

my $q  = Math::GMPq->new('1/11');
my $fr = 0;
$fr = Math::MPFR->new(17.1) if $have_mpfr;

############################################

if($have_mpfr) {

  if($Math::MPFR::VERSION < 4.19) {
    is(1,1);
    warn "\n  Skipping remaining tests -  Math::MPFR version 4.19 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
    done_testing();
    exit 0;
  }
  else {

    $q = Math::GMPq->new('1/11');
    cmp_ok(ref($q), 'eq', 'Math::GMPq', '$q is a Math::GMPq object');
    $q *= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', $fr * Math::GMPq->new('1/11'), '$q *= $fr sets $q to 1.5545454545454547');

    $q = Math::GMPq->new('1/11');
    cmp_ok(ref($q), 'eq', 'Math::GMPq', '$q has been reverted to a Math::GMPq object');
    $q += $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', $fr + Math::GMPq->new('1/11'), '$q += $fr sets $q to 1.7190909090909091e1');

    $q = Math::GMPq->new('1/11');
    $q -= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new('1/11') - $fr, '$q -= $fr sets $z to -1.7009090909090911e1');

    $q = Math::GMPq->new('1/11');
    $q /= $fr;
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new('1/11') / $fr, '$q /= $fr sets $q to 5.3163211057947893e-3');

    $q = Math::GMPq->new(2);
    $q **= Math::MPFR->new(0.5);
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new(2) ** Math::MPFR->new(0.5), '$q **= $Math::MPFR->new(0.5) sets $q to 1.4142135623730951');

    $q = Math::GMPq->new(2);
    Math::MPFR::Rmpfr_set_default_prec(113);
    $q **= Math::MPFR->new(0.5);
    cmp_ok(ref($q), 'eq', 'Math::MPFR', '$q changes to a Math::MPFR object');
    cmp_ok($q, '==', Math::GMPq->new(2) ** Math::MPFR->new(0.5), '$q **= Math::MPFR->new(0.5) sets $z to 1.41421356237309504880168872420969798');
  }
}
else {
  is(1,1);
  warn "Skipping all tests - could not load Math::MPFR";
}

done_testing();
