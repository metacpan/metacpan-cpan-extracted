
# Testing % overloading between Math::GMPz, Math::GMPq, Math::MPFR and perl.
# We need to keep in mind that when r=x%m returns a negative value, then the
# positive value abs(m)+r is equivalent the negative vaue held in r.
# (Math::GMPz doesn't always agree with the others on when to return a negative value.)

use strict;
use warnings;
use Math::GMPz;

my($have_mpfr, $have_gmpq) = (0, 0);

use Test::More;

my @ops_1 = (101, -101, 12345, -12345);
my @ops_2 = (7, -7, 257, -257);

eval {require Math::MPFR;};

unless($@) {
  if($Math::MPFR::VERSION < 4.37) {
    warn "Skipping tests that require Math::MPFR - we need at least Math-MPFR-4.37, but have only version $Math::MPFR::VERSION";
  }
  else {
    $have_mpfr = 1;
    for my $op1(@ops_1) {
      for my $op2(@ops_2) {
        my $mod1 = Math::GMPz->new($op1) % Math::GMPz->new($op2);
        my $mod2 = Math::GMPz->new($op1) % Math::MPFR->new($op2);
        cmp_ok(is_equivalent($mod1, $mod2, $op2), '==', 1, "$op1 % $op2 ok between mpz and mpfr");
      }
    }
  }
}
else {
  warn "Skipping tests that require Math::MPFR as Math::MPFR failed to load\n";
}

########################################

eval {require Math::GMPq;};

unless($@) {
  if($Math::GMPq::VERSION < 0.59) {
    warn "Skipping tests that require Math::GMPq - we need at least Math-GMPq-0.59, but have only version $Math::GMPq::VERSION";
  }
  else {
    $have_gmpq = 1;
    for my $op1(@ops_1) {
      for my $op2(@ops_2) {
        my $mod1 = Math::GMPz->new($op1) % Math::GMPz->new($op2);
        my $mod2 = Math::GMPz->new($op1) % Math::GMPq->new($op2);
        cmp_ok(is_equivalent($mod1, $mod2, $op2), '==', 1, "$op1 % $op2 ok between mpz and mpq");
        if($have_mpfr) {
          # Math::MPFR and Math::GMPq should always agree on whether a negative value is returmed.
          # Here we use Math::MPFR::overload_equiv to compare the LHS (Math::MPFR::object) with $mod2 (Math::GMPq::object).
          cmp_ok(Math::GMPz->new($op1) % Math::MPFR->new($op2), '==', $mod2, "$op1 % $op2 ok between mpfr and mpq");
          # Here we perform the same comparison, but using Math::GMPq::overload_equiv - which could not handle
          # Math::MPFR objects prior to Math-GMPq-0.62.
          if($Math::GMPq::VERSION >= 0.62) {
            cmp_ok($mod2, '==', Math::GMPz->new($op1) % Math::MPFR->new($op2), "$op1 % $op2 ok between mpq and mpfr");
          }
        }
      }
    }
  }

}
else {
  warn "Skipping tests that require Math::GMPq as Math::GMPq failed to load\n";
}

########################################

for my $op1(@ops_1) {
  for my $op2(@ops_2) {
    my $mod1 = Math::GMPz->new($op1) % Math::GMPz->new($op2);
    my $perl_mod = $op1 % $op2;
    cmp_ok(is_equivalent($mod1, $perl_mod, $op2), '==', 1, "$op1 % $op2 ok between mpz and perl");
  }
}

done_testing();

sub is_equivalent {
  my ($op1, $op2, $mod) = (shift, shift, shift);
  $op1 += abs($mod) if $op1 < 0;
  $op2 += abs($mod) if $op2 < 0;
  return 1 if $op1 == $op2;
  return 0;
}
