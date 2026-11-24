#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 28;

BEGIN {
    use_ok( 'Google::Cloud::Discoveryengine::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::AclConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::AssistantServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::CmekConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::CollectionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::CompletionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::ControlServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::ConversationalSearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::DataConnectorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::DataStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::DocumentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::EngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::GroundedGenerationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::LicenseConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::ProjectServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::RankServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::RecommendationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::SchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::SearchServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::SearchTuningServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::ServingConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::SessionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::UserEventServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::UserLicenseServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::UserStoreServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Discoveryengine::V1::WidgetConfigServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Discoveryengine::V1 $Google::Cloud::Discoveryengine::V1::VERSION, Perl $], $^X" );
