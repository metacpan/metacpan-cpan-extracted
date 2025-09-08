#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dist::PolicyFiles' ) || print "Bail out!\n";
}

diag( "Testing Dist::PolicyFiles $Dist::PolicyFiles::VERSION, Perl $], $^X" );
