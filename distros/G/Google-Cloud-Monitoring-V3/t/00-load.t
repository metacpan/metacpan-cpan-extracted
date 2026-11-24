#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 9;

BEGIN {
    use_ok( 'Google::Cloud::Monitoring::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::AlertPolicyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::GroupServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::MetricServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::NotificationChannelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::QueryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::ServiceMonitoringServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::SnoozeServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Monitoring::V3::UptimeCheckServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Monitoring::V3 $Google::Cloud::Monitoring::V3::VERSION, Perl $], $^X" );
