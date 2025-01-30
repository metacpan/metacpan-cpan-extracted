use strict;
use warnings;
use Config;
use Math::GMPf qw(:mpf);

use Test::More;

my($have_mpz, $have_mpq) = (0, 0);

eval {require Math::GMPz;};
$have_mpz = 1 unless $@;

eval {require Math::GMPq;};
$have_mpq = 1 unless $@;

my $buflen = 32;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpf_sprintf($buf, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'double'");
}

# This test is likely to FAIL on Windows if GMPF_WIN32_FMT_BUG is TRUE.
if($Config{nvtype} eq 'long double' && !Math::GMPf::GMPF_WIN32_FMT_BUG) {
  Rmpf_sprintf($buf, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'long double'");
}

Rmpf_sprintf($buf, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
cmp_ok($buf, 'eq', '1.4142135623731', "Math::GMPf: sqrt 2 ok");

Rmpf_sprintf($buf, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello world', "'hello world' ok for PV");

if($have_mpz) {
  Rmpf_sprintf($buf, "%Zd", Math::GMPz->new(~0), $buflen);
  my $not_zero = ~0;
  cmp_ok($buf, 'eq', "$not_zero", "Math::GMPz: ~0 ok");
}

if($have_mpq) {
  Rmpf_sprintf($buf, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/21', "Math::GMPq: 19/21 ok");
}

# Next 2 tests on Win32 might fail if GMPF_WIN32_FMT_BUG is TRUE.
if($Config{nvsize} == 8 && !Math::GMPf::GMPF_WIN32_FMT_BUG) {
  Rmpf_sprintf($buf, "%a", sqrt 2, 32);
  $buf =~ s/^0x//i;
  $buf =~ s/p/@/i;
  cmp_ok(Math::GMPf->new($buf, 16), '==', sqrt(2), 'Rmpf_sprintf() reads "%a" correctly');

  Rmpf_sprintf($buf, "%A", sqrt 2, 32);
  $buf =~ s/^0x//i;
  $buf =~ s/p/@/i;
  cmp_ok(Math::GMPf->new($buf, 16), '==', sqrt(2), 'Rmpf_sprintf() reads "%A" correctly');
}

done_testing();
