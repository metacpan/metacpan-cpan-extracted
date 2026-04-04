#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Legba' ) || print "Bail out!\n";
}

diag( "Testing Legba $Legba::VERSION, Perl $], $^X" );
