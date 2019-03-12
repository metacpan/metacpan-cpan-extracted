#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::Yeelight' ) || print "Bail out!\n";
}

diag( "Testing Device::Yeelight $Device::Yeelight::VERSION, Perl $], $^X" );
