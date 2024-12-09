#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Symbolic::Custom::Matrix' ) || print "Bail out!\n";
}

diag( "Testing Math::Symbolic::Custom::Matrix $Math::Symbolic::Custom::Matrix::VERSION, Perl $], $^X" );
