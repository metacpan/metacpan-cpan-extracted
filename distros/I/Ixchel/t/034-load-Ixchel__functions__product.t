#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::functions::product' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::functions::product::VERSION, Perl $], $^X" );
