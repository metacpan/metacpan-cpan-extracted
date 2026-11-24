#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Grafeas::V1' ) || print "Bail out!\n";
    use_ok( 'Grafeas::V1::GrafeasClient' ) || print "Bail out!\n";
}

diag( "Testing Grafeas::V1 $Grafeas::V1::VERSION, Perl $], $^X" );
