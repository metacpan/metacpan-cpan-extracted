#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {

    use_ok( 'Device::Network::ConfigParser' ) || print "Bail out!\n";
    use_ok( 'Device::Network::ConfigParser::CheckPoint::Gaia' ) || print "Bail out!\n";
}
