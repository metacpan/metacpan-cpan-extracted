#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Infix::Custom' ) || print "Bail out!\n";
}

diag( "Testing Infix::Custom $Infix::Custom::VERSION, Perl $], $^X" );
