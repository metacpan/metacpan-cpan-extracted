#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Google::Cloud::Networkconnectivity::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1beta::DataTransferServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1beta::HubServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRoutingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networkconnectivity::V1beta::TransportManagerClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networkconnectivity::V1beta $Google::Cloud::Networkconnectivity::V1beta::VERSION, Perl $], $^X" );
