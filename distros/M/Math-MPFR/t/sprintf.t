use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

use Test::More;

my($have_gmp, $have_mpz, $have_mpq, $have_mpf) = (0, 0, 0, 0);

eval {require Math::GMP;};
$have_gmp = 1 unless $@;

eval {require Math::GMPz;};
$have_mpz = 1 unless $@;

eval {require Math::GMPq;};
$have_mpq = 1 unless $@;

eval {require Math::GMPf;};
$have_mpf = 1 unless $@;

my $buflen = 32;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpfr_sprintf($buf, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'double'");
}

if($Config{nvtype} eq 'long double') {
  Rmpfr_sprintf($buf, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'long double'");
}

Rmpfr_sprintf($buf, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello world', "'hello world' ok for PV");

if($have_gmp) {
  Rmpfr_sprintf($buf, "%Zd", Math::GMP->new(~0), $buflen);
  cmp_ok($buf, '==', ~0, "Math::GMP: ~0 ok");
}

if($have_mpz) {
  Rmpfr_sprintf($buf, "%Zd", Math::GMPz->new(~0), $buflen);
  cmp_ok($buf, '==', ~0, "Math::GMPz: ~0 ok");
}

if($have_mpq) {
  Rmpfr_sprintf($buf, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/21', "Math::GMPq: 19/21 ok");
}

if($have_mpf) {
  Rmpfr_sprintf($buf, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "Math::GMPf: sqrt 2 ok");
}


my $fr = Math::MPFR->new($nv);

Rmpfr_sprintf($buf, "%.14RUg", $fr, $buflen);
cmp_ok($buf, 'eq', '1.4142135623731', "Math::MPFR: sqrt 2 ok");

Rmpfr_sprintf($buf, "%.14RDg", $fr, $buflen);
cmp_ok($buf, 'eq', '1.414213562373', "Math::MPFR: sqrt 2 ok");

Rmpfr_sprintf($buf, "%Pd", prec_cast(Rmpfr_get_prec($fr)), $buflen);
cmp_ok($buf, 'eq', '53', "Math::MPFR precision is '53'");

if($Config{nvsize} == 8) {
  Rmpfr_sprintf($buf, "%a", sqrt(2), 32);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%a" correctly');
  Rmpfr_sprintf($buf, "%A", sqrt(2), 32);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%A" correctly');
}
elsif($Config{nvtype} ne '__float128') {
  my $prec_orig = Rmpfr_get_default_prec();
  my $prec = 64;
  if(length(sqrt(2)) > 25) { $prec = 113 }
  Rmpfr_set_default_prec($prec);
  Rmpfr_sprintf($buf, "%La", sqrt(2), 48);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%La" correctly');
  Rmpfr_sprintf($buf, "%LA", sqrt(2), 48);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%LA" correctly');
  Rmpfr_set_default_prec($prec_orig);
}

done_testing();
