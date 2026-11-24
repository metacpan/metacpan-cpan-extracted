#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Videointelligence::V1beta2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligenceServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Videointelligence::V1beta2 $Google::Cloud::Videointelligence::V1beta2::VERSION, Perl $], $^X" );
