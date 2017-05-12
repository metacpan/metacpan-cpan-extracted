########################################################################
# Verifies load is okay
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Math::PRBS' ) or diag "Couldn't even load Math::PRBS";
}
