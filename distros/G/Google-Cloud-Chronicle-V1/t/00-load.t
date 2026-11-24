#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 16;

BEGIN {
    use_ok( 'Google::Cloud::Chronicle::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::BigQueryExportServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::DashboardChartServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::DashboardQueryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::DataAccessControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::DataTableServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::EntityServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboardServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::FeedsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::FindingsRefinementServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::InstanceServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::NativeDashboardServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::ReferenceListServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::RuleExecutionErrorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::RuleServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Chronicle::V1::SearchServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Chronicle::V1 $Google::Cloud::Chronicle::V1::VERSION, Perl $], $^X" );
