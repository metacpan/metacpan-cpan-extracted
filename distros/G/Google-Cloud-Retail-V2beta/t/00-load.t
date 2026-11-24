#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 14;

BEGIN {
    use_ok( 'Google::Cloud::Retail::V2beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::AnalyticsServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::CatalogServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::GenerativeQuestionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::PredictionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ProductServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Retail::V2beta::UserEventServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Retail::V2beta $Google::Cloud::Retail::V2beta::VERSION, Perl $], $^X" );
