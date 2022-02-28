# Check that scalars that are (or might be)
# both POK and NOK are being handled correctly.

use strict;
use warnings;

use Math::GMPf qw(:mpf);
*_ITSA = \&Math::GMPf::_itsa;

use Test::More;

warn "\n GMPF_PV_NV_BUG set to ", GMPF_PV_NV_BUG, "\n";
warn " The string 'nan' apparently numifies to zero\n"
  if 'nan' + 0 == 0;

# Check that both the perl environment and the XS
# environment agree on whether the problem is present.
cmp_ok(GMPF_PV_NV_BUG, '==', Math::GMPf::_has_pv_nv_bug(),
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
  my $fr = Math::GMPf->new($pv_finite);
  cmp_ok("$fr", 'eq', '0.5e5001',
         "'5e5000' is not an Inf");                        # Test 4
}

if('nan' + 0 != 'nan' + 0) { # Skip if numification of
                              # 'nan' fails to DWIM
  my $pv_nan = 'nan';

  if($pv_nan != 42) { # True
    # On perl-5.8.8 any string which numifies to an integer value
    # (including 0) will have its IOK flag set. Brilliant !!
    eval { my $fr = Math::GMPf->new($pv_nan); };
    like($@, qr/First arg to Rmpf_init_set_str is not a valid base 10 number/,
           "illegal input correctly detected");           # Test 5
  }
}
else { # Instead verify that 'nan' numifies to zero
  cmp_ok('nan' + 0, '==', 0, "'nan' numifies to zero");    # Test 5 alt.
}

my $perl_sqrt = sqrt 2; # sqrt(2) as NV
my $str = "$perl_sqrt"; # sqrt(2) as decimal string, rounded twice.

if($str > 0) {
  cmp_ok(_ITSA($str), '==', 4,
         "Correctly designated as a PV");                  # Test 6
  cmp_ok(_ITSA($perl_sqrt), '==', 3,
         "Correctly designated as an NV");                 # Test 7
}

my $nv_sqrt = sqrt(2);
my $t = "$nv_sqrt";

# The next 4 tests should fail if the value
# in the PV slot of $nv_sqrt is used.

Rmpf_set_default_prec(200);

cmp_ok(Math::GMPf->new(1) * $nv_sqrt, '==', sqrt(2),
       "overload_mul() uses value in NV slot");            # Test 8

cmp_ok(Math::GMPf->new(0) + $nv_sqrt, '==', sqrt(2),
       "overload_add() uses value in NV slot");            # Test 9

cmp_ok(Math::GMPf->new(0) - $nv_sqrt, '==', -(sqrt(2)),
       "overload_sub() uses value in NV slot");            # Test 10

cmp_ok(Math::GMPf->new(sqrt 2) / $nv_sqrt, '==', 1.0,
       "overload_div() uses value in NV slot");            # Test 11

done_testing();
