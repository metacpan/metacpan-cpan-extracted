#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 16;

BEGIN {
    use_ok( 'Google::Cloud::Retail::V2alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::AnalyticsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::BranchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::CatalogServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::GenerativeQuestionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::PredictionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ProductServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2alpha::UserEventServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Retail::V2alpha $Google::Cloud::Retail::V2alpha::VERSION, Perl $], $^X" );
