# Keep an eye on the precisions of the objects that "op" and "op="
# overloading returns. (Just in case something changes.)

# Re Math::GMPz and Math::MPFR cross-class overloading:
# The Math::GMPz documentation specifies that the returned Math::MPFR
# objects will have been calculated to the same precision as the
# given Math::MPFR operand, and with default rounding.

# Similarly for Math::GMPq and Math::MPFR cross-class overloading:
# The Math::GMPq documentation specifies that the returned Math::MPFR
# objects will also have been calculated to the same precision as the
# given Math::MPFR operand, and with default rounding.

# THese requirements were not finalized until Math-GMPz-0.67
# and Math-GMPq-0.67, so we test only against those (and later) versions
# of those 2 mudules,

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

my ($have_gmpz, $have_gmpq) = (0, 0);

eval {require Math::GMPz;};
if($@) { warn "Skipping tests involving Math::GMPz objects - Math::GMPz failed to load\n" }
elsif($Math::GMPz::VERSION < 0.67) {
  warn "Skipping some tests involving Math::GMPz objects because they need Math-GMPz-0.67 or later, but we have only $Math::GMPz::VERSION\n";
}
else { $have_gmpz = 1 }

eval {require Math::GMPq;};
if($@) { warn "Skipping all tests involving Math::GMPq objects - Math::GMPq failed to load\n" }
elsif($Math::GMPq::VERSION < 0.67) {
  warn "Skipping some tests involving Math::GMPq objects because they need Math-GMPq-0.67 or later, but we have only $Math::GMPq::VERSION\n";
}
else { $have_gmpq = 1 }

my $fixed_prec = Rmpfr_init2(100);
Rmpfr_set_ui($fixed_prec, 42, MPFR_RNDN); # precision of 100 bits
###
{
  my $x = $fixed_prec + 0;
  cmp_ok($x, '==', 42, "value ok for '+'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '+'");

  $fixed_prec += 0;
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '+='");

  my $zero = 0;
  $zero += $fixed_prec;
  cmp_ok($zero, '==', 42, "value ok for '+='");
  cmp_ok(Rmpfr_get_prec($zero), '==', 53, "prec still ok for '+='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(108);
    $z += $fixed_prec;
    cmp_ok($z, '==', 150, "mpz: value ok for '+='");
    unless($Math::GMPz::VERSION < 0.66) {
      cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '+='");
    }
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(0.5);
    $q += $fixed_prec;
    cmp_ok($q, '==', 42.5, "mpq: value ok for '+='");
    cmp_ok(Rmpfr_get_prec($q), '==', 100, "mpq: prec still ok for '+='");
  }

}
###
{
  my $x = $fixed_prec - 0;
  cmp_ok($x, '==', 42, "value ok for '-'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '-'");

  $fixed_prec -= 0;
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '-='");

  my $zero = 0;
  $zero -= $fixed_prec;
  cmp_ok($zero, '==', -42, "value ok for '-='");
  cmp_ok(Rmpfr_get_prec($zero), '==', 53, "prec still ok for '-='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(192);
    $z -= $fixed_prec;
    cmp_ok($z, '==', 150, "mpz: value ok for '-='");
    unless($Math::GMPz::VERSION < 0.66) {
      cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '-='");
    }
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(0.5);
    $q -= $fixed_prec;
    cmp_ok($q, '==', -41.5, "mpq: value ok for '-='");
    cmp_ok(Rmpfr_get_prec($q), '==', 53, "mpq: prec still ok for '-='");
  }
}
###
{
  my $x = $fixed_prec * 1;
  cmp_ok($x, '==', 42, "value ok for '*'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '*'");

  $fixed_prec *= 1;
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '*='");

  my $unity = 1;
  $unity *= $fixed_prec;
  cmp_ok($unity, '==', 42, "value ok for '*='");
  cmp_ok(Rmpfr_get_prec($unity), '==', 53, "prec still ok for '*='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(10);
    $z *= $fixed_prec;
    cmp_ok($z, '==', 420, "mpz: value ok for '*='");
    unless($Math::GMPz::VERSION < 0.66) {
      cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '*='");
    }
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(0.5);
    $q *= $fixed_prec;
    cmp_ok($q, '==', 21, "mpq: value ok for '*='");
    cmp_ok(Rmpfr_get_prec($q), '==', 100, "mpq: prec still ok for '*='");
  }
}
###
{
  my $x = $fixed_prec / 1;
  cmp_ok($x, '==', 42, "value ok for '/'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '/'");

  $fixed_prec /= 1;
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '/='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(105);
    $z /= $fixed_prec;
    cmp_ok($z, '==', 2.5, "mpz: value ok for '/='");
    unless($Math::GMPz::VERSION < 0.66) {
      cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '/='");
    }
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(10.5);
    $q /= $fixed_prec;
    cmp_ok($q, '==', 0.25, "mpq: value ok for '/='");
    cmp_ok(Rmpfr_get_prec($q), '==', 100, "mpq: prec still ok for '/='");
  }
}
###
{
  my $x = $fixed_prec % 50;
  cmp_ok($x, '==', 42, "value ok for '%'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '%'");

  $fixed_prec %= 50;
  cmp_ok($fixed_prec, '==', 42, "value ok for '%='");
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '%='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(105);
    $z %= $fixed_prec;
    cmp_ok($z, '==', 21, "mpz: value ok for '%='");
    unless($Math::GMPz::VERSION < 0.66) {
      cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '%='");
    }
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(10.5);
    $q %= $fixed_prec;
    cmp_ok($q, '==', 10.5, "mpq: value ok for '%='");
    cmp_ok(Rmpfr_get_prec($q), '==', 100, "mpq: prec still ok for '%='");
  }
}
###
{
  my $x = $fixed_prec ** 1;
  cmp_ok($x, '==', 42, "value ok for '**'");
  cmp_ok(Rmpfr_get_prec($x), '==', 53, "prec ok for '**'");

  $fixed_prec **= 1;
  cmp_ok($fixed_prec, '==', 42, "value ok for '**='");
  cmp_ok(Rmpfr_get_prec($fixed_prec), '==', 100, "prec ok for '**='");

  if($have_gmpz) {
    my $z = Math::GMPz->new(2);
    $z **= $fixed_prec;
    cmp_ok($z, '==', 4398046511104, "mpz: value ok for '/='");
    cmp_ok(Rmpfr_get_prec($z), '==', 100, "mpz: prec still ok for '/='");
  }

  if($have_gmpq) {
    my $q = Math::GMPq->new(1.5);
    $q **= $fixed_prec;
    my $prec_orig = Rmpfr_get_default_prec();
    Rmpfr_set_default_prec(Rmpfr_get_prec($fixed_prec));
    cmp_ok($q, '==', Math::MPFR->new('2.487899772211502732011467742268e7'), "mpq: value ok for '/='");
    cmp_ok(Rmpfr_get_prec($q), '==', 100, "mpq: prec still ok for '/='");
    Rmpfr_set_default_prec($prec_orig);
  }
}
###
done_testing();
