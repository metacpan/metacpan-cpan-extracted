#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Networkconnectivity::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1::DataTransferServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1::HubServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1::InternalRangeServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRoutingServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networkconnectivity::V1 $Google::Cloud::Networkconnectivity::V1::VERSION, Perl $], $^X" );
