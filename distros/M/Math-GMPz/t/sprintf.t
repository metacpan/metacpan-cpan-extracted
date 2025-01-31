use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz);

use Test::More;

my($have_mpq, $have_mpf) = (0, 0);
my $not_zero = ~0;

eval {require Math::GMPq;};
$have_mpq = 1 unless $@;

eval {require Math::GMPf;};
$have_mpf = 1 unless $@;

my $buflen = 32;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpz_sprintf($buf, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'double'");
}

if($Config{nvtype} eq 'long double' && !Math::GMPz::GMPZ_WIN32_FMT_BUG) {
  Rmpz_sprintf($buf, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'long double'");
}

Rmpz_sprintf($buf, "%Zd", Math::GMPz->new(~0), $buflen);
cmp_ok($buf, 'eq', "$not_zero", "Math::GMPz: ~0 ok");

Rmpz_sprintf($buf, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello world', "'hello world' ok for PV");

if($have_mpq) {
  Rmpz_sprintf($buf, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/21', "Math::GMPq: 19/21 ok");
}

if($have_mpf) {
  Rmpz_sprintf($buf, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "Math::GMPf: sqrt 2 ok");
}

done_testing();
