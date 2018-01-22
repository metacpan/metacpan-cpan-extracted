#!perl -T
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Device::TPLink' ) || print "Bail out!\n";
    use_ok( 'Device::TPLink::Kasa' ) || print "Bail out!\n";
    use_ok( 'Device::TPLink::SmartHome' ) || print "Bail out!\n";
    use_ok( 'Device::TPLink::SmartHome::Kasa' ) || print "Bail out!\n";
    use_ok( 'Device::TPLink::SmartHome::Direct' ) || print "Bail out!\n";
}

diag( "Testing Device::TPLink $Device::TPLink::VERSION, Perl $], $^X" );
