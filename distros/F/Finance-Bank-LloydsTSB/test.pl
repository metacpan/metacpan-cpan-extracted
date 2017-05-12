# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Finance::Bank::LloydsTSB;
ok(1); # If we made it this far, we're ok.

#########################

# If anyone has an idea how to safely test this module, please let me know!
