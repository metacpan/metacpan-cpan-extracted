use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

use Config;

my ($op, $op2, $res);

# Create an inf portably:
my $kludge = Math::MPFR->new();
Rmpfr_set_inf($kludge, 1);      # +inf
my $inf = Rmpfr_get_NV($kludge, MPFR_RNDN);

# %bounds is a copy of %emax_emin, declared in anytoa()
my %bounds = (53   => [1024,  -1073,  -1022 ],
              64   => [16384, -16444, -16382],
              2098 => [1024],
              113  => [16384, -16493, -16382],
              );

my @exp_53   =  ('1.4142135623730951', '0.13999999999999999', '0.1', '5e-324', '8.7001827429576e-311',
                 '2.8481815407166473e-306', '2.0', '0.0', '0.0');
my @nexp_53  = map { "-" . $_} @exp_53;

my @exp_64   = ('1.4142135623730950488', '0.14', '0.1', '4.940656458412465442e-324',
                 '8.700182742957616492e-311', '2.8481815407166473465e-306', '2.0', '1.223126e-4943',
                 '1.3771174474187147233e-4928');
my @nexp_64  = map { "-" . $_} @exp_64;

my @exp_113  = ('1.414213562373095048801688724209698', '0.13999999999999999999999999999999999', '0.1',
                '4.940656458412465441765687928682214e-324', '8.700182742957616491956667080939156e-311',
                '2.8481815407166473465204174448562866e-306', '2.0', '1.22312599818982326042266e-4943',
                '1.3771174474187147232911910237982503e-4928');
my @nexp_113 = map { "-" . $_} @exp_113;

my @exp_2098 = ('1.4142135623730950488016887242097', '0.14', '0.1', '5e-324', '8.7001827429576e-311',
                '2.8481815407166473e-306',
                '2.0000000000000000000000000000000000000000000000000000000000006223015277861142', '0.0',
                '0.0');
my @nexp_2098 = map { "-" . $_} @exp_2098;

my %expected = (
  '53'   => \@exp_53,
  '64'   => \@exp_64,
  '113'  => \@exp_113,
  '2098' => \@exp_2098,
               );

my %nexpected = (
  '53'   => \@nexp_53,
  '64'   => \@nexp_64,
  '113'  => \@nexp_113,
  '2098' => \@nexp_2098,
               );

my $emax = Rmpfr_get_emax();
my $emin = Rmpfr_get_emin();

for my $bits(53, 64, 113, 2098) {
  $op = Rmpfr_init2($bits);
  $op2 = Rmpfr_init2($bits);

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  $op **= 0.5;
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "1: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "1: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[0], "$res eq $expected{$bits}->[0]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "2: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "2: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[0], "$res eq $nexpected{$bits}->[0]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_strtofr($op, '1.4', 10, MPFR_RNDN);
  $op /= 10;
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "3: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "3: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[1], "$res eq $expected{$bits}->[1]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "4: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "4: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[1], "$res eq $nexpected{$bits}->[1]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_strtofr($op, '0.1', 10, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "5: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "5: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[2], "$res eq $expected{$bits}->[2]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "6: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "6: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[2], "$res eq $nexpected{$bits}->[2]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  if( MPFR_VERSION() >= 262146 && $bits == 53 ) {
    # The mpfr library does not properly support 1-bit precision until 4.0.2
    # Also, cater for older perls that don't set subnormals correctly.
    Rmpfr_set($kludge, Math::MPFR->new(2) ** -1074, MPFR_RNDN);
    Rmpfr_set_d($op, Rmpfr_get_d($kludge, MPFR_RNDN),  MPFR_RNDN);
    $res = anytoa($op, $bits);
    cmp_ok(Rmpfr_get_emax(), '==', $emax, "7: emax was reset correctly");
    cmp_ok(Rmpfr_get_emin(), '==', $emin, "7: emin was reset correctly");
    cmp_ok($res, 'eq', $expected{$bits}->[3], "$res eq $expected{$bits}->[3]");

    Rmpfr_neg($op, $op, MPFR_RNDN);
    $res = anytoa($op, $bits);
    cmp_ok(Rmpfr_get_emax(), '==', $emax, "8: emax was reset correctly");
    cmp_ok(Rmpfr_get_emin(), '==', $emin, "8: emin was reset correctly");
    cmp_ok($res, 'eq', $nexpected{$bits}->[3], "$res eq $nexpected{$bits}->[3]");
  }

  # Deal with 2 more subnormals that might be mis-assigned by older perls
  Rmpfr_set($op, (Math::MPFR->new(2) ** -1030) +  (Math::MPFR->new(2) ** -1040),  MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "9: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "9: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[4], "$res eq $expected{$bits}->[4]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless ($bits == 2098 || $bits == 53);

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "10: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "10: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[4], "$res eq $nexpected{$bits}->[4]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless ($bits == 2098 || $bits == 53);

  Rmpfr_neg($op, $op, MPFR_RNDN); # Revert to +ve value.

  Rmpfr_add_d($op, $op, 2 ** -1015, MPFR_RNDN);

  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "11: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "11: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[5], "$res eq $expected{$bits}->[5]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "12: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "12: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[5], "$res eq $nexpected{$bits}->[5]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  Rmpfr_add_d($op, $op, 2 ** -200, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "13: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "13: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[6], "$res eq $expected{$bits}->[6]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "14: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "14: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[6], "$res eq $nexpected{$bits}->[6]");

  cmp_ok($res, 'eq', mpfrtoa($op), "$res eq mpfrtoa($op)")
    unless $bits == 2098;

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  $op **= -16420;
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "15: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "15: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[7], "$res eq $expected{$bits}->[7]");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "16: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "16: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[7], "$res eq $nexpected{$bits}->[7]");

  Rmpfr_neg($op, $op, MPFR_RNDN); # Revert to +ve value.

  Rmpfr_set_ui($op2, 2, MPFR_RNDN);
  $op2 **= -16370;
  Rmpfr_add($op, $op, $op2, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "17: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "17: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[8], "$res eq $expected{$bits}->[8]");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "18: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "18: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[8], "$res eq $nexpected{$bits}->[8]");

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  $op **= -16420;
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "19: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "19: emin was reset correctly");
  cmp_ok($res, 'eq', $expected{$bits}->[7], "$res eq $expected{$bits}->[7]");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "20: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "20: emin was reset correctly");
  cmp_ok($res, 'eq', $nexpected{$bits}->[7], "$res eq $nexpected{$bits}->[7]");

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  $op **= ($bounds{$bits}->[0]) - 1;
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "21: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "21: emin was reset correctly");
  # $res will evaluate to Inf when nvtype is double or double or double-double.
  # So we need to establish that $res is not 'Inf' - which we do by
  # evaluating Math::MPFR->new($res), which should be finite and positive.
  cmp_ok(Math::MPFR->new($res), '>', 0, "$res > 0");
  cmp_ok(Math::MPFR->new($res), '<', $inf, "$res < Inf");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "22: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "22: emin was reset correctly");
  # $res will evaluate to -Inf when nvtype is double or double or double-double.
  # So we need to establish that $res is not '-Inf' - which we do by
  # evaluating Math::MPFR->new($res), which should be finite and negative.
  cmp_ok(Math::MPFR->new($res), '<', 0, "$res < 0");
  cmp_ok(Math::MPFR->new($res), '>', -$inf, "$res > -Inf");

  Rmpfr_set_ui($op, 2, MPFR_RNDN);
  $op **= $bounds{$bits}->[0];
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "23: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "23: emin was reset correctly");

  # Evaluate Math::MPFR->new($res) to ensure that $res really is '+Inf'.
  cmp_ok(Math::MPFR->new($res), '==', $inf, "$res is positive and infinite");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "24: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "24: emin was reset correctly");
  cmp_ok(Math::MPFR->new($res), '==', -$inf, "$res is negative and infinite");

  Rmpfr_set_nan($op);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "25: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "25: emin was reset correctly");
  like($res, qr/nan/i, "$res is NaN");

  Rmpfr_neg($op, $op, MPFR_RNDN);
  $res = anytoa($op, $bits);
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "26: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "26: emin was reset correctly");
  like($res, qr/nan/i, "$res is still NaN");

  eval { anytoa(16, 53); };
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "27: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "27: emin was reset correctly");
  like($@, qr/^1st argument given to anytoa/, "dies if 1st arg is not a Math::MPFR object");

  eval { anytoa(Math::MPFR->new(0), 128); };
  cmp_ok(Rmpfr_get_emax(), '==', $emax, "28: emax was reset correctly");
  cmp_ok(Rmpfr_get_emin(), '==', $emin, "28: emin was reset correctly");
  like($@, qr/^2nd argument given to anytoa/, "dies if 2nd arg is invalid value");
}

done_testing();
