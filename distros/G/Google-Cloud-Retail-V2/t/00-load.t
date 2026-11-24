#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 13;

BEGIN {
    use_ok( 'Google::Cloud::Retail::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::AnalyticsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::CatalogServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::GenerativeQuestionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::PredictionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::ProductServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2::UserEventServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Retail::V2 $Google::Cloud::Retail::V2::VERSION, Perl $], $^X" );
