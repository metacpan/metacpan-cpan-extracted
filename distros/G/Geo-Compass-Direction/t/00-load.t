#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::Compass::Direction' ) || print "Bail out!\n";
}

diag( "Testing Geo::Compass::Direction $Geo::Compass::Direction::VERSION, Perl $], $^X" );
