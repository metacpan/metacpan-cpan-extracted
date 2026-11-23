#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Google::Cloud::Networksecurity::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::AddressGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::DnsThreatDetectorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::FirewallActivationClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::InterceptClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::MirroringClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::NetworkSecurityClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::OrganizationAddressGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::SSERealmServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Networksecurity::V1 $Google::Cloud::Networksecurity::V1::VERSION, Perl $], $^X" );
