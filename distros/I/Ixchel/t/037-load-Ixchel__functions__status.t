#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::functions::status' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::functions::status::VERSION, Perl $], $^X" );
