#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::SDS011' ) || print "Bail out!\n";
}

diag( "Testing Device::SDS011 $Device::SDS011::VERSION, Perl $], $^X" );
