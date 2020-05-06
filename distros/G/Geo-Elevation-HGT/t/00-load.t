#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::Elevation::HGT' ) || print "Bail out!\n";
}

diag( "Testing Geo::Elevation::HGT $Geo::Elevation::HGT::VERSION, Perl $], $^X" );
