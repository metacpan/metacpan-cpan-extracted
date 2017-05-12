#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DigitalOcean' ) || print "Bail out!\n";
}

diag( "Testing DigitalOcean , Perl $], $^X" );
