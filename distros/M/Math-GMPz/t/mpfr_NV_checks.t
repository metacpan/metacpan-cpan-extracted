# If Math::MPFR is available, use it to
# run checks on Rmpz_set_NV and Rmpz_cmp_NV

use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Test::More;

eval {require Math::MPFR};
if($@) {
  warn "Math::MPFR unavailable";
  cmp_ok(1, '==', 1, "dummy test");
  done_testing();
  exit 0;
}

*set_prec = \&Math::MPFR::Rmpfr_set_default_prec;
*get_prec = \&Math::MPFR::Rmpfr_get_default_prec;
*get_z    = \&Math::MPFR::Rmpfr_get_z;
*cmp_z    = \&Math::MPFR::Rmpfr_cmp_z;

warn "Math-MPFR version: $Math::MPFR::VERSION\n";
warn "MPFR version     : Math::MPFR::MPFR_VERSION_STRING\n";

my $prec   = $Math::MPFR::NV_properties{bits};
my $max    = $Math::MPFR::NV_properties{emax};
my $min    = $Math::MPFR::NV_properties{emin};
my $nv_max = $Math::MPFR::NV_properties{NV_MAX};

warn "NV precision: $prec\n";

set_prec($prec);
cmp_ok(get_prec(), '==', $prec, "precision is $prec");

my $z0 = Math::GMPz->new();

for my $power( ($max - 10) .. ($max - 9),
     -5 .. 50,
     $min .. ($min + 10),) { test_it(2 ** $power) }

for($nv_max, -$nv_max) { test_it($_) }

#################
done_testing(); #
#################

sub test_it {
  my $nv = shift;
  my $mpfr = Math::MPFR->new($nv);
  cmp_ok($mpfr, '==', $nv, "$nv == Math::MPFR object");
  get_z($z0, $mpfr, 1); # Round towards zero because that is what Rmpz_set_NV does.
  my $z1 = Math::GMPz->new($nv);
  cmp_ok($z0, '==', $z1, "$nv assigns consistently");
  cmp_ok(Rmpz_cmp_NV($z1, $nv), '==', cmp_z($mpfr, $z1) * - 1, "comparisons agree for $nv");
}




