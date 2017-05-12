#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lingua::FR::Hyphen' ) || print "Bail out!\n";
}

diag( "Testing Lingua::FR::Hyphen $Lingua::FR::Hyphen::VERSION, Perl $], $^X" );
