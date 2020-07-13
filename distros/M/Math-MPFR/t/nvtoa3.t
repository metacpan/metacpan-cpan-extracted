# Add various tests here as they come to mind.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

if($] < 5.03 && $Config{nvtype} ne '__float128') {
  plan skip_all => "Perl's string to NV assignment is unreliable\n";
}

else {

  plan tests => 11;

  my $m = 9.007199254740991e15; # 2 ** 53

  cmp_ok(nvtoa(2 ** 105), '==', 2 ** 105, "nvtoa(2 ** 105) == 2 ** 105");
  cmp_ok(nvtoa(2 ** 106), '==', 2 ** 106, "nvtoa(2 ** 106) == 2 ** 106");

  cmp_ok(nvtoa($m * (2 ** 53)), '==', $m * (2 ** 53), "nvtoa($m*(2**53)) == $m*(2**53)");
  cmp_ok(nvtoa($m * (2 ** 54)), '==', $m * (2 ** 54), "nvtoa($m*(2**54)) == $m*(2**54)");

  cmp_ok(nvtoa(2 ** 120), '==', 2 ** 120, "nvtoa(2 ** 120) == 2 ** 120");

  cmp_ok(nvtoa(29 * (2 ** 1001)), '==', 29 * (2 ** 1001), "nvtoa(29 * (2 ** 1001)) == 29 * (2 ** 1001)");

  cmp_ok(nvtoa(1.7976931348623157e+308), '==', 1.7976931348623157e+308, "nvtoa(DBL_MAX) == DBL_MAX");

  cmp_ok(nvtoa(123456789012345.0), '==', 123456789012345.0, "nvtoa(123456789012345.0) == 123456789012345.0");

  cmp_ok(nvtoa(1.0 / 10.0), 'eq', '0.1', "nvtoa(1.0 / 10.0) eq '0.1'");

  if($Config{nvsize} > 8 &&
     $Config{nvtype} eq 'long double' &&
     Math::MPFR::_required_ldbl_mant_dig() != 113) {

    cmp_ok(nvtoa(1.4 / 10),  'eq', '0.14',  "nvtoa(1.4 / 10) eq '0.14'" );

    if(Math::MPFR::_required_ldbl_mant_dig() == 2098) {
      # DoubleDouble
      cmp_ok(nvtoa(1.4 / 100), 'ne', '0.014', "nvtoa(1.4 / 10) ne '0.014'"); # 0.014000...0013
    }
    else {
      # 64-bit precision NV
      cmp_ok(nvtoa(1.4 / 100), 'eq', '0.014', "nvtoa(1.4 / 10) eq '0.014'");
    }
  }
  else {
    cmp_ok(nvtoa(1.4 / 10),  'ne', '0.14',  "nvtoa(1.4 / 10) ne '0.14'" ); # 0.13999...99

    if($Config{nvtype} eq '__float128' || ($Config{nvsize} > 8 && $Config{nvtype} eq 'long double')) {
      # 113-bit precision NV
      cmp_ok(nvtoa(1.4 / 100), 'eq', '0.014', "nvtoa(1.4 / 100) eq '0.014'");
    }
    else {
      # 53-bit precision NV
      cmp_ok(nvtoa(1.4 / 100), 'ne', '0.014', "nvtoa(1.4 / 100) ne '0.014'"); # 0.013999...99
    }
  }
}
