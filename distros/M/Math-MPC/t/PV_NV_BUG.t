# Check that scalars that are (or might be)
# both POK and NOK are being handled correctly.

use strict;
use warnings;
use Config;

use Math::MPC qw(:mpc);
*_ITSA = \&Math::MPC::_itsa;

use Test::More;

warn "\n MPC_PV_NV_BUG set to ", MPC_PV_NV_BUG, "\n";
warn " The string 'nan' apparently numifies to zero\n"
  if 'nan' + 0 == 0;

# Check that both the perl environment and the XS
# environment agree on whether the problem is present.
cmp_ok(MPC_PV_NV_BUG, '==', Math::MPC::_has_pv_nv_bug(),
       "Perl environment and XS environment agree");       # Test 1

my $nv_1 = 1.3;
my $s    = "$nv_1";

my $rop = Math::MPFR->new();

cmp_ok(_ITSA($nv_1), '==', 3, "NV slot will be used");     # Test 2

my $nv_2 = '1.7';

if($nv_2 > 1) {      # True
  cmp_ok(_ITSA($nv_2), '==', 4, "PV slot will be used");   # Test 3
}

my $pv_finite = '2e500';

if($pv_finite > 0) { # True
  my $fr = Math::MPC->new($pv_finite);
  RMPC_RE($rop, $fr);
  cmp_ok(Math::MPFR::Rmpfr_inf_p($rop), '==', 0,
         "'2e500' is not an Inf");                         # Test 4
}

if('nan' + 0 != 'nan' + 0) { # Skip if numification of
                              # 'nan' fails to DWIM
  my $pv_nan = 'nan';

  if($pv_nan != 42) { # True
    # On perl-5.8.8 any string which numifies to an integer value
    # (including 0) will have its IOK flag set. Brilliant !!
    my $fr = Math::MPC->new($pv_nan);

    RMPC_RE($rop, $fr);

    cmp_ok(Math::MPFR::Rmpfr_nan_p($rop), '!=', 0,
           "NaN Math::MPC object was created");       # Test 5
  }
}
else { # Instead verify that 'nan' numifies to zero
  cmp_ok('nan' + 0, '==', 0, "'nan' numifies to zero");    # Test 5 alt.
}

my $nv_inf= Math::MPFR::Rmpfr_get_NV(Math::MPFR->new('Inf'), 0);
$s = "$nv_inf";

RMPC_RE($rop, Math::MPC->new($nv_inf));

cmp_ok(Math::MPFR::Rmpfr_inf_p($rop), '!=', 0,
       "Inf Math::MPC object was created");               # Test 6

my $nv_nan = Math::MPFR::Rmpfr_get_NV(Math::MPFR->new(), 0);
$s = "$nv_nan";

RMPC_RE($rop, Math::MPC->new($nv_nan));
  cmp_ok(Math::MPFR::Rmpfr_nan_p($rop), '!=', 0,
         "NaN Math::MPC object was created");             # Test 7


my $perl_sqrt = sqrt 2; # sqrt(2) as NV
my $str = "$perl_sqrt"; # sqrt(2) as decimal string, rounded twice.

if($str > 0) {
  cmp_ok(_ITSA($str), '==', 4,
         "Correctly designated a PV");                     # Test 8
  cmp_ok(_ITSA($perl_sqrt), '==', 3,
         "Correctly designated as an NV");                 # Test 9
}

my $nv_sqrt = sqrt(2);
my $str_sqrt = "$nv_sqrt";

# The next 4 tests should fail if the value
# in the PV slot of $nv_sqrt is used.

Rmpc_set_default_prec($Math::MPFR::NV_properties{bits});

cmp_ok(Math::MPC->new(1) * $nv_sqrt, '==', sqrt(2),
       "overload_mul() uses value in NV slot");            # Test 10

cmp_ok(Math::MPC->new(0) + $nv_sqrt, '==', sqrt(2),
       "overload_add() uses value in NV slot");            # Test 11

cmp_ok(Math::MPC->new(0) - $nv_sqrt, '==', -(sqrt(2)),
       "overload_sub() uses value in NV slot");            # Test 12

cmp_ok(Math::MPC->new(sqrt 2) / $nv_sqrt, '==', 1.0,
       "overload_div() uses value in NV slot");            # Test 13

done_testing();
