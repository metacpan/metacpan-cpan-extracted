#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Factory::Sub' ) || print "Bail out!\n";
}

diag( "Testing Factory::Sub $Factory::Sub::VERSION, Perl $], $^X" );
