#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hash::ExtendedKeys' ) || print "Bail out!\n";
}

diag( "Testing Hash::ExtendedKeys $Hash::ExtendedKeys::VERSION, Perl $], $^X" );
