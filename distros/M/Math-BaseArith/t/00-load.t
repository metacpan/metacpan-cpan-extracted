#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::BaseArith' ) 
        or do { print "Bailing out!\n";  exit };
}

diag( "Testing Math::BaseArith $Math::BaseArith::VERSION, Perl $], $^X" );
