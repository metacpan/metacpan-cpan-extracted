#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Device::Inverter::KOSTAL::PIKO' ) || print "Bail out!\n";
}

diag( "Testing Device::Inverter::KOSTAL::PIKO $Device::Inverter::KOSTAL::PIKO::VERSION, Perl $], $^X" );
