#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Visionai::V1alpha1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1alpha1::AppPlatformClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1alpha1::LiveVideoAnalyticsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1alpha1::StreamingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1alpha1::StreamsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Visionai::V1alpha1::WarehouseClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Visionai::V1alpha1 $Google::Cloud::Visionai::V1alpha1::VERSION, Perl $], $^X" );
