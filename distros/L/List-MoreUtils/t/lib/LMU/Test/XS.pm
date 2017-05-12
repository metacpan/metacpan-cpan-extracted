package LMU::Test::XS;

use strict;

BEGIN
{
    $| = 1;
}

use Test::More;
use List::MoreUtils;

sub run_tests
{
    test_xs();
    done_testing();
}

sub test_xs
{
    is( List::MoreUtils::_XScompiled, 0+defined( $INC{'List/MoreUtils/XS.pm'}), "_XScompiled" );
}

1;
