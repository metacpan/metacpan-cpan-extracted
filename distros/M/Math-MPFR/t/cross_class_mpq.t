# Do: $mpfr_rop = $mpfr * $mpq;
# Do: q_mul_fr   ($mpq_rop,  $mpq,  $mpfr); Rmpfr_set_q($mpfr_from_q, $mpq_rop, default_rounding_mode());
# Check that $mpfr_rop == $mpfr_from_q, as documrntation implies (I think)
#
# Also:
# Do: q_fmod_fr($mpq_rop, $mpq, $mpfr);
# Do: Rmpfr_get_q($q_from_mpfr, $mpfr);
# Check that $mpq_rop ==  $mpq % $q_from_mpfr;
# LHS was assigned using only Math::MPFR functionality.
# RHS is calcualted using Math::GMPq overloading of '%' operator (fmod).

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

eval {require Math::GMPq;};

if($@) {
  cmp_ok(1, '==', 1);
  warn "Skipping all tests - could not load Math::GMPq";
  done_testing();
  exit 0;
}

if($Math::GMPq::VERSION < 0.61) {
  is(1, 1);
  warn "Skipping all tests - we need Math-GMPq-0.61 or later, but have only version $Math::GMPq::VERSION";
  done_testing();
  exit 0;
}

my $mpfr = Math::MPFR->new(22222.22);
my $mpfr_from_q = Math::MPFR->new();
my $mpq_rop = Math::GMPq->new();

for(1..100) {
  my $num = 10 + int(rand(10000));
  my $den = 100 + int(rand(1000));

  my $q1 = "$num/$den";
  my $q2 = "$den/$num";

  for my $s($q1, $q2) {
    my $mpq = Math::GMPq->new($s);
    $mpq *= -1 unless $_ % 3;

    my $mpfr_rop = $mpfr * $mpq;
    q_mul_fr($mpq_rop,  $mpq,  $mpfr);
    Rmpfr_set_q($mpfr_from_q, $mpq_rop, MPFR_RNDN);

    cmp_ok($mpfr_from_q, '==', $mpfr_rop, "values match for 22222.22 * $mpq");
  }
}

Rmpfr_set_d($mpfr, 2.22, MPFR_RNDN);
my $q_from_mpfr = Math::GMPq->new();
Rmpfr_get_q($q_from_mpfr, $mpfr);

for(1..100) {
  my $num = 10 + int(rand(10000));
  my $den = 100 + int(rand(1000));

  my $q1 = "$num/$den";
  my $q2 = "$den/$num";

  for my $s($q1, $q2) {
    my $mpq = Math::GMPq->new($s);
    $mpq *= -1 unless $_ % 3;
    q_fmod_fr($mpq_rop, $mpq, $mpfr);
    cmp_ok($mpq % $q_from_mpfr, '==', $mpq_rop, "values match for $mpq % 2.22");
  }
}

done_testing();
