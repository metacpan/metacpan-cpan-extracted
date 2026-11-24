#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 28;

BEGIN {
    use_ok( 'Google::Cloud::Discoveryengine::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::AclConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::AssistantServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::CmekConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::DataStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::DocumentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::EngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::EvaluationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::RankServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::RecommendationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SampleQueryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySetServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SearchTuningServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SessionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::UserEventServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::UserLicenseServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1beta::UserStoreServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Discoveryengine::V1beta $Google::Cloud::Discoveryengine::V1beta::VERSION, Perl $], $^X" );
