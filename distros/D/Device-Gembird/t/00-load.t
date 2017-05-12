#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::Gembird' ) || print "Bail out!\n";
}

diag( "Testing Device::Gembird $Device::Gembird::VERSION, Perl $], $^X" );
