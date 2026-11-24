#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 9;

BEGIN {
    use_ok( 'Google::Cloud::Appengine::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::ApplicationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::AuthorizedCertificatesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::AuthorizedDomainsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::DomainMappingsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::FirewallClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::InstancesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::ServicesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1beta::VersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Appengine::V1beta $Google::Cloud::Appengine::V1beta::VERSION, Perl $], $^X" );
