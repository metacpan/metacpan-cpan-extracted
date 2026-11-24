#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 24;

BEGIN {
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::AclConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::ChunkServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::DataStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::DocumentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::EngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::EvaluationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::RankServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::RecommendationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SearchTuningServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SessionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1alpha::UserEventServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Discoveryengine::V1alpha $Google::Cloud::Discoveryengine::V1alpha::VERSION, Perl $], $^X" );
