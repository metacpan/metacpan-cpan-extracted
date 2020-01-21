# Add various tests here as they come to mind.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

if($] < 5.03) {
  plan skip_all => "Perl's string to NV assignment is unreliable\n";
}

else {

  plan tests => 4;

  cmp_ok(nvtoa(2 ** 120) + 0, '==', 2 ** 120, "nvtoa(2 ** 120) + 0 == 2 ** 120");

  cmp_ok(nvtoa(29 * (2 ** 1001)) + 0, '==', 29 * (2 ** 1001), "nvtoa(29 * (2 ** 1001)) + 0 == 29 * (2 ** 1001)");

  cmp_ok(nvtoa(1.7976931348623157e+308) + 0, '==', 1.7976931348623157e+308, "nvtoa(DBL_MAX) +  0 == DBL_MAX");

  cmp_ok(nvtoa(123456789012345.0) + 0, '==', 123456789012345.0, "nvtoa(123456789012345.0) == 123456789012345.0");

}
