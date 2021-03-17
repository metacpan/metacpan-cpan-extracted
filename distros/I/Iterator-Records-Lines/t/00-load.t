#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Iterator::Records::Lines' ) || print "Bail out!\n";
}

diag( "Testing Iterator::Records::Lines $Iterator::Records::Lines::VERSION, Perl $], $^X" );
