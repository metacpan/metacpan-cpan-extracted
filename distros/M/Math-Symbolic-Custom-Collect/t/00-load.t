#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Symbolic::Custom::Collect' ) || print "Bail out!\n";
}

diag( "Testing Math::Symbolic::Custom::Collect $Math::Symbolic::Custom::Collect::VERSION, Perl $], $^X" );
