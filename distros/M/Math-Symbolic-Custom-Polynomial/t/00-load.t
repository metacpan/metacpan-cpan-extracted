#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Symbolic::Custom::Polynomial' ) || print "Bail out!\n";
}

diag( "Testing Math::Symbolic::Custom::Polynomial $Math::Symbolic::Custom::Polynomial::VERSION, Perl $], $^X" );
