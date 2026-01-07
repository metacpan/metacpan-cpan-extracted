# Some further testing of the dd_repro() function.
# For all of the doubledouble values we test in this script,
# the least significant double (LSD) should be zero, and the
# most significant double (MSD) should be non-zero.
use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Math::FakeDD qw(:all);

use Test::More;

my $how_many = 3000;
my @randoms;

for(1 .. $how_many) { push @randoms, Math::MPFR->new() }

my $state = Rmpfr_randinit_default();
my $mpfr_trans = Rmpfr_init2(2098);

Rmpfr_urandomb(@randoms, $state);
for my $r(@randoms) {
  Rmpfr_set_exp($r, rand_exp());
  Rmpfr_set($mpfr_trans, $r, MPFR_RNDN);
  my $dd = mpfr2dd($mpfr_trans);
  cmp_ok($dd->{msd}, '!=', 0, "$r: MSD != 0");
  cmp_ok($dd->{lsd}, '==', 0, "$r: LSD == 0");

  my $repro = dd_repro($dd);
  cmp_ok(dd_repro_test($repro, $dd), '==', 15, "$repro is correct");
}

done_testing();

sub rand_exp {
  # return a random exponent in the range -1074 .. 1023.
  my $exp = int(rand(1075));
  return $exp * -1 if $exp > 1023;
  return $exp * -1 if int(rand(2)) == 1;
  return $exp;
}

