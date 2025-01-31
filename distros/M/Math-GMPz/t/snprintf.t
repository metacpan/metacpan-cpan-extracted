use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz);

use Test::More;

my($have_mpq, $have_mpf) = (0, 0);

eval {require Math::GMPq;};
$have_mpq = 1 unless $@;

eval {require Math::GMPf;};
$have_mpf = 1 unless $@;

my $buflen = 16;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpz_snprintf($buf, 7, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'double'");
}

if($Config{nvtype} eq 'long double' && !Math::GMPz::GMPZ_WIN32_FMT_BUG) {
  Rmpz_snprintf($buf, 7, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142', "sqrt 2 ok for 'long double'");
}

Rmpz_snprintf($buf, 7, "%Zd", Math::GMPz->new(12345678), $buflen);
cmp_ok($buf, '==', 123456, "Math::GMPz: 12345678 ok");

Rmpz_snprintf($buf, 8, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello w', "'hello world' ok for PV");

if($have_mpq) {
  Rmpz_snprintf($buf, 4, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/', "Math::GMPq: 19/21 ok");
}

if($have_mpf) {
  Rmpz_snprintf($buf, 7, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142', "Math::GMPf: sqrt 2 ok");
}

done_testing();
