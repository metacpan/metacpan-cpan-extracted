#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 9;

BEGIN {
    use_ok( 'Google::Cloud::Appengine::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::ApplicationsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::AuthorizedCertificatesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::AuthorizedDomainsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::DomainMappingsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::FirewallClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::InstancesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::ServicesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appengine::V1::VersionsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Appengine::V1 $Google::Cloud::Appengine::V1::VERSION, Perl $], $^X" );
