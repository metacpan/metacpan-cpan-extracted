#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ham::WorldMap' ) || print "Bail out!\n";
}

diag( "Testing Ham::WorldMap $Ham::WorldMap::VERSION, Perl $], $^X" );
