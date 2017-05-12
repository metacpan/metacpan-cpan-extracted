#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Device::Dynamixel' ) || print "Bail out!
";
}

diag( "Testing Device::Dynamixel $Device::Dynamixel::VERSION, Perl $], $^X" );
