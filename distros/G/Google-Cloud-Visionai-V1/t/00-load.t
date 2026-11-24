#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Visionai::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::AppPlatformClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::HealthCheckServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::LiveVideoAnalyticsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::StreamingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::StreamsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1::WarehouseClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Visionai::V1 $Google::Cloud::Visionai::V1::VERSION, Perl $], $^X" );
