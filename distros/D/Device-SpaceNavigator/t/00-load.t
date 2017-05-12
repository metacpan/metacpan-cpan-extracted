#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Device::SpaceNavigator' ) || print "Bail out!
";
}

diag( "Testing Device::SpaceNavigator $Device::SpaceNavigator::VERSION, Perl $], $^X" );
