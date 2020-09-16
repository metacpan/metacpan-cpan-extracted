#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Iterator::Records' ) || print "Bail out!\n";
}

diag( "Testing Iterator::Records $Iterator::Records::VERSION, Perl $], $^X" );
