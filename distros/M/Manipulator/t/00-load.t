#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Manipulator' ) || print "Bail out!\n";
}

diag( "Testing Manipulator $Manipulator::VERSION, Perl $], $^X" );
