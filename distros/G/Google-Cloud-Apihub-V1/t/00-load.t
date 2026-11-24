#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Google::Cloud::Apihub::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubCollectClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubCurateClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubDependenciesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubDiscoveryClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ApiHubPluginClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::HostProjectRegistrationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::LintingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::ProvisioningClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apihub::V1 $Google::Cloud::Apihub::V1::VERSION, Perl $], $^X" );
