#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Device::Cisco::NXAPI' ) || print "Cannot use Device::Cisco::NXAPI\n";
}

BEGIN {
    use_ok( 'Device::Cisco::NXAPI::Test' ) || print "Cannot Use Device::Cisco::NXAPI::Test\n";
}

diag( "Testing Device::Cisco::NXAPI $Device::Cisco::NXAPI::VERSION, Perl $], $^X" );
diag( "Testing Device::Cisco::NXAPI::Test $Device::Cisco::NXAPI::Test::VERSION, Perl $], $^X" );
