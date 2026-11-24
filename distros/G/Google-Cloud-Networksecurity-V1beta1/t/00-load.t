#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Networksecurity::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1beta1::DnsThreatDetectorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1beta1::NetworkSecurityClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networksecurity::V1beta1 $Google::Cloud::Networksecurity::V1beta1::VERSION, Perl $], $^X" );
