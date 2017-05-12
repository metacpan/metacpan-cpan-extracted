#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::TM1638' ) || print "Bail out!\n";
}

diag( "Testing Device::TM1638 $Device::TM1638::VERSION, Perl $], $^X" );
