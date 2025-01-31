use strict;
use warnings;
use Config;
use Math::GMPq qw(:mpq);

use Test::More;

my($have_mpz, $have_mpf) = (0, 0);

eval {require Math::GMPz;};
$have_mpz = 1 unless $@;

eval {require Math::GMPf;};
$have_mpf = 1 unless $@;

my $buflen = 16;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpq_snprintf($buf, 7, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'double'");
}

if($Config{nvtype} eq 'long double' && !Math::GMPq::GMPQ_WIN32_FMT_BUG) {
  Rmpq_snprintf($buf, 7, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'long double'");
}

Rmpq_snprintf($buf, 4, "%Qd", Math::GMPq->new('19/21'), $buflen);
cmp_ok($buf, 'eq', '19/', "Math::GMPq: 19/21 ok");

Rmpq_snprintf($buf, 8, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello w', "'hello world' ok for PV");

if($have_mpz) {
  Rmpq_snprintf($buf, 7, "%Zd", Math::GMPz->new(12345678), $buflen);
  cmp_ok($buf, '==', 123456, "Math::GMPz: 12345678 ok");
}

if($have_mpf) {
  Rmpq_snprintf($buf, 7, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142', "Math::GMPf: sqrt 2 ok");
}

done_testing();
