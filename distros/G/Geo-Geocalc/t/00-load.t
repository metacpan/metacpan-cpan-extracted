#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::Geocalc' ) || print "Bail out!\n";
}

diag( "Testing Geo::Geocalc $Geo::Geocalc::VERSION, Perl $], $^X" );
