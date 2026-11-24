#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Cloudcontrolspartner::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerMonitoringClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Cloudcontrolspartner::V1 $Google::Cloud::Cloudcontrolspartner::V1::VERSION, Perl $], $^X" );
