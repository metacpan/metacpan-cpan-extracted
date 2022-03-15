# Check that scalars that are (or might be)
# both POK and NOK are being handled correctly.

use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Math::MPFI qw(:mpfi);
*_ITSA = \&Math::MPFI::_itsa;

use Test::More;

warn "\n MPFI_PV_NV_BUG set to ", MPFI_PV_NV_BUG, "\n";
warn " The string 'nan' apparently numifies to zero\n"
  if 'nan' + 0 == 0;

# Check that both the perl environment and the XS
# environment agree on whether the problem is present.
cmp_ok(MPFI_PV_NV_BUG, '==', Math::MPFI::_has_pv_nv_bug(),
       "Perl environment and XS environment agree");       # Test 1

my $nv_1 = 1.3;
my $s    = "$nv_1";

cmp_ok(_ITSA($nv_1), '==', 3, "NV slot will be used");     # Test 2

my $nv_2 = '1.7';

if($nv_2 > 1) {      # True
  cmp_ok(_ITSA($nv_2), '==', 4, "PV slot will be used");   # Test 3
}

my $pv_finite = '5e5000';

if($pv_finite > 0) { # True
  my $fr = Math::MPFI->new($pv_finite);
  cmp_ok("$fr", 'eq', '[4.9999999999999996e5000,5.0000000000000003e5000]',
         "'5e5000' is not an Inf");                        # Test 4
}

if('nan' + 0 != 'nan' + 0) { # Skip if numification of
                              # 'nan' fails to DWIM
  my $pv_nan = 'nan';

  if($pv_nan != 42) { # True
    my $fr = Math::MPFI->new($pv_nan);
    cmp_ok(Rmpfr_nan_p($fr), '!=', 0,
           "NaN Math::MPFI object was created");           # Test 5
  }
}
else { # Instead verify that 'nan' numifies to zero
  cmp_ok('nan' + 0, '==', 0, "'nan' numifies to zero");    # Test 5 alt.
}

if('inf' + 0 > 0) { # Skip if numification of
                              # 'inf' fails to DWIM
  my $pv_inf = 'inf';

  if($pv_inf > 0) { # True
    my $fr = Math::MPFI->new($pv_inf);
    cmp_ok(Rmpfr_inf_p($fr), '!=', 0,
           "Inf Math::MPFI object was created");           # Test 6
  }
}
else { # Instead verify that 'inf' numifies to zero
  cmp_ok('inf' + 0, '==', 0, "'inf' numifies to zero");    # Test 6 alt.
}

my $nv_inf = Rmpfr_get_NV(Math::MPFI->new('Inf'), MPFR_RNDN);
$s = "$nv_inf";

cmp_ok(Rmpfr_inf_p(Math::MPFI->new($nv_inf)), '!=', 0,
       "Inf Math::MPFI object was created");               # Test 7

my $nv_nan = Rmpfr_get_NV(Math::MPFI->new(), MPFR_RNDN);
$s = "$nv_nan";
  cmp_ok(Rmpfr_nan_p(Math::MPFI->new($nv_nan)), '!=', 0,
         "NaN Math::MPFI object was created");             # Test 8

Rmpfr_set_default_prec($Math::MPFR::NV_properties{bits});
my $mpfr_sqrt = sqrt(Math::MPFR->new(2));

my $perl_sqrt = Rmpfr_get_NV($mpfr_sqrt, MPFR_RNDN); # sqrt(2) as NV
my $str = "$perl_sqrt"; # sqrt(2) as decimal string, rounded twice.

if($str > 0) {
  cmp_ok(_ITSA($str), '==', 4,
         "Correctly designated a PV");                     # Test 9
  cmp_ok(_ITSA($perl_sqrt), '==', 3,
         "Correctly designated as an NV");                 # Test 10
}

my $nv_sqrt = sqrt(2);
my $str_sqrt = "$nv_sqrt";

# The next 4 tests won't fail even if the
# value in the PV slot of $nv_sqrt is used.
# So they don't prove much ...

cmp_ok(Math::MPFI->new(1) * $nv_sqrt, '==', sqrt(2),
       "overload_mul() uses value in NV slot");            # Test 11

cmp_ok(Math::MPFI->new(0) + $nv_sqrt, '==', sqrt(2),
       "overload_add() uses value in NV slot");            # Test 12

cmp_ok(Math::MPFI->new(0) - $nv_sqrt, '==', -(sqrt(2)),
       "overload_sub() uses value in NV slot");            # Test 13

cmp_ok(Math::MPFI->new(sqrt 2) / $nv_sqrt, '==', 1.0,
       "overload_div() uses value in NV slot");            # Test 14

done_testing();
