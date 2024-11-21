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

my $buflen = 16;
my $buf;
my $nv = sqrt(2);

if($Config{nvsize} == 8) {
  Rmpfr_snprintf($buf, 7, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'double'");

  Rmpfr_snprintf($buf, 8, "%a", $nv, $buflen);
  cmp_ok($buf, 'eq', '0x1.6a0', 'sqrt 2 ok for "%a" formatting');

  Rmpfr_snprintf($buf, 8, "%A", $nv, $buflen);
  cmp_ok($buf, 'eq', '0X1.6A0', 'sqrt 2 ok for "%A" formatting');
}

if($Config{nvtype} eq 'long double') {
  Rmpfr_snprintf($buf, 7, "%.14Lg", $nv, $buflen * 2);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'long double'");

  if(length(sqrt(2.0)) > 25) {
    # IEEE 754 long double
    Rmpfr_snprintf($buf, 8, "%La", $nv, $buflen * 2);
    cmp_ok($buf, 'eq', '0x1.6a0', 'sqrt 2 ok for 128-bit "%La" formatting');

    Rmpfr_snprintf($buf, 8, "%LA", $nv, $buflen * 2);
    cmp_ok($buf, 'eq', '0X1.6A0', 'sqrt 2 ok for 128-bit "%La" formatting');
  }
  else {
    # 80-bit extended precision long double
    my($buf1, $buf2);

    Rmpfr_snprintf($buf1, 8, "%La", $nv, $buflen * 2);
    like($buf1, qr/^0x1.6a0$|^0x2.d41$|^0x5.a82$|^0xb.504$/, 'sqrt 2 ok for 80-bit "%La" formatting');

    Rmpfr_snprintf($buf2, 8, "%LA", $nv, $buflen * 2);
    cmp_ok($buf2, 'eq', uc($buf1), 'sqrt 2 ok for 80-bit "%LA" formatting');

  }
}

Rmpfr_snprintf($buf, 8, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello w', "'hello world' ok for PV");

if($have_gmp) {
  Rmpfr_snprintf($buf, 7, "%Zd", Math::GMP->new(12345678), $buflen);
  cmp_ok($buf, 'eq', '123456', "Math::GMP: 12345678 ok");
}

if($have_mpz) {
  Rmpfr_snprintf($buf, 7, "%Zd", Math::GMPz->new(12345678), $buflen);
  cmp_ok($buf, 'eq', 123456, "Math::GMPz: 12345678 ok");
}

if($have_mpq) {
  Rmpfr_snprintf($buf, 4, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/', "Math::GMPq: 19/21 ok");
}

if($have_mpf) {
  Rmpfr_snprintf($buf, 7, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142', "Math::GMPf: sqrt 2 ok");
}


my $fr = Math::MPFR->new($nv);

Rmpfr_snprintf($buf, 7, "%.14RDg", $fr, $buflen);
cmp_ok($buf, 'eq', '1.4142', "Math::MPFR: sqrt 2 ok");

Rmpfr_snprintf($buf, 3, "%Pd", prec_cast(Rmpfr_get_prec($fr)), $buflen);
cmp_ok($buf, 'eq', '53', "Math::MPFR precision is '53'");

done_testing();
