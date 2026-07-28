#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok( 'Google::Cloud::Networksecurity::V1::AddressGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::DnsThreatDetectorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::FirewallActivationClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::InterceptClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::MirroringClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::NetworksecurityClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::OrganizationAddressGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::SSERealmServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networksecurity::V1::AddressGroupServiceClient $Google::Cloud::Networksecurity::V1::AddressGroupServiceClient::VERSION, Perl $], $^X" );
