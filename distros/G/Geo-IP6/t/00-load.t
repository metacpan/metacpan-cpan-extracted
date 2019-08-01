#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::IP6' ) || print "Bail out!\n";
}

diag( "Testing Geo::IP6 $Geo::IP6::VERSION, Perl $], $^X" );
