#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ham::Device::FT817COMM' ) || print "Bail out!\n";
}

diag( "Testing Ham::Device::FT817COMM $Ham::Device::FT817COMM::VERSION, Perl $], $^X" );
