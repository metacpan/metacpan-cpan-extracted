#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::functions::serial' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::functions::serial::VERSION, Perl $], $^X" );
