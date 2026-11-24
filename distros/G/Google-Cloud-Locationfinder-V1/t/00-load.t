#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Locationfinder::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Locationfinder::V1::CloudLocationFinderClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Locationfinder::V1 $Google::Cloud::Locationfinder::V1::VERSION, Perl $], $^X" );
