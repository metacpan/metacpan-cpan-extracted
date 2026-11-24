#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Devicesandservices::Health::V4' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devicesandservices::Health::V4::DataSubscriptionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devicesandservices::Health::V4::HealthProfileServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devicesandservices::Health::V4 $Google::Cloud::Devicesandservices::Health::V4::VERSION, Perl $], $^X" );
