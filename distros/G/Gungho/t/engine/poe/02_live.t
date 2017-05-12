use strict;
use Test::More;
use lib('t/lib');
use GunghoTest;
use GunghoTest::Live;

BEGIN
{
    GunghoTest->plan_or_skip(
        requires    => "POE",
        check_env   => "GUNGHO_TEST_LIVE",
        test_count  => 2
    );
}

GunghoTest::Live->run( {
    engine => {
        module => "POE",
    }
});