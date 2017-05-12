# This test does nothing except test compilation of the module.

# To test this module against a real router, see the test in
# "../xt/connecting-test.t".

use warnings;
use strict;
use Test::More tests => 1;
BEGIN { use_ok('Device::Router::RTX') };

# Local variables:
# mode: perl
# End:
