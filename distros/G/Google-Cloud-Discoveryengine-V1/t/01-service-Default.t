use strict;
use warnings;
use Test::More;
use File::Spec;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %args) = @_;
    return bless \%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my $class = shift;
    my $args = ( @_ == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : { @_ };
    return bless $args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Fallback Mocks for External Response Classes
BEGIN {
    for my $pkg (qw( Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse Google::Cloud::Discoveryengine::V1::Control::Control Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationResponse Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector Google::Cloud::Discoveryengine::V1::Document::Document Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentResponse Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig Google::Cloud::Discoveryengine::V1::RankService::RankResponse Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse Google::Cloud::Discoveryengine::V1::Schema::Schema Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig Google::Cloud::Discoveryengine::V1::Session::Session Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse Google::Cloud::Discoveryengine::V1::UserStore::UserStore Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Discoveryengine::V1;

my $client = Google::Cloud::Discoveryengine::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'update_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.AclConfigService', 'Correct service path');
        is($args->{method}, 'UpdateAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->update_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'get_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.AclConfigService', 'Correct service path');
        is($args->{method}, 'GetAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->get_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'stream_assist method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.AssistantService', 'Correct service path');
        is($args->{method}, 'StreamAssist', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_assist();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse', 'Response object class');
    done_testing();
};

subtest 'update_cmek_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.CmekConfigService', 'Correct service path');
        is($args->{method}, 'UpdateCmekConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_cmek_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_collection method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.CollectionService', 'Correct service path');
        is($args->{method}, 'DeleteCollection', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_collection();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'import_suggestion_deny_list_entries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.CompletionService', 'Correct service path');
        is($args->{method}, 'ImportSuggestionDenyListEntries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->import_suggestion_deny_list_entries();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::Control::Control', 'Response object class');
    done_testing();
};

subtest 'converse_conversation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConverseConversation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationResponse'->new();
        return $response;
    };
    
    my $res = $client->converse_conversation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationResponse', 'Response object class');
    done_testing();
};

subtest 'set_up_data_connector method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.DataConnectorService', 'Correct service path');
        is($args->{method}, 'SetUpDataConnector', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->set_up_data_connector();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_data_connector method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.DataConnectorService', 'Correct service path');
        is($args->{method}, 'UpdateDataConnector', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector'->new();
        return $response;
    };
    
    my $res = $client->update_data_connector();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector', 'Response object class');
    done_testing();
};

subtest 'create_data_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.DataStoreService', 'Correct service path');
        is($args->{method}, 'CreateDataStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_data_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.DocumentService', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::Document::Document'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::Document::Document', 'Response object class');
    done_testing();
};

subtest 'create_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.EngineService', 'Correct service path');
        is($args->{method}, 'CreateEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'stream_generate_grounded_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.GroundedGenerationService', 'Correct service path');
        is($args->{method}, 'StreamGenerateGroundedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_generate_grounded_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentResponse', 'Response object class');
    done_testing();
};

subtest 'create_identity_mapping_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.IdentityMappingStoreService', 'Correct service path');
        is($args->{method}, 'CreateIdentityMappingStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore'->new();
        return $response;
    };
    
    my $res = $client->create_identity_mapping_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore', 'Response object class');
    done_testing();
};

subtest 'create_license_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.LicenseConfigService', 'Correct service path');
        is($args->{method}, 'CreateLicenseConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig'->new();
        return $response;
    };
    
    my $res = $client->create_license_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig', 'Response object class');
    done_testing();
};

subtest 'provision_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.ProjectService', 'Correct service path');
        is($args->{method}, 'ProvisionProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->provision_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'rank method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.RankService', 'Correct service path');
        is($args->{method}, 'Rank', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::RankService::RankRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::RankService::RankResponse'->new();
        return $response;
    };
    
    my $res = $client->rank();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::RankService::RankResponse', 'Response object class');
    done_testing();
};

subtest 'recommend method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.RecommendationService', 'Correct service path');
        is($args->{method}, 'Recommend', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse'->new();
        return $response;
    };
    
    my $res = $client->recommend();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse', 'Response object class');
    done_testing();
};

subtest 'get_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SchemaService', 'Correct service path');
        is($args->{method}, 'GetSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::Schema::Schema'->new();
        return $response;
    };
    
    my $res = $client->get_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::Schema::Schema', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'train_custom_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SearchTuningService', 'Correct service path');
        is($args->{method}, 'TrainCustomModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->train_custom_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_serving_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.ServingConfigService', 'Correct service path');
        is($args->{method}, 'CreateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->create_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'create_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SessionService', 'Correct service path');
        is($args->{method}, 'CreateSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::CreateSessionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::Session::Session'->new();
        return $response;
    };
    
    my $res = $client->create_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::Session::Session', 'Response object class');
    done_testing();
};

subtest 'get_site_search_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'GetSiteSearchEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::GetSiteSearchEngineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine'->new();
        return $response;
    };
    
    my $res = $client->get_site_search_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine', 'Response object class');
    done_testing();
};

subtest 'batch_create_target_sites method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'BatchCreateTargetSites', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::BatchCreateTargetSitesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_create_target_sites();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_sitemap method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'CreateSitemap', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::CreateSitemapRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_sitemap();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'enable_advanced_site_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'EnableAdvancedSiteSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::EnableAdvancedSiteSearchRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->enable_advanced_site_search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'recrawl_uris method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'RecrawlUris', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::RecrawlUrisRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->recrawl_uris();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'write_user_event method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

subtest 'list_user_licenses method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.UserLicenseService', 'Correct service path');
        is($args->{method}, 'ListUserLicenses', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_user_licenses();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse', 'Response object class');
    done_testing();
};

subtest 'get_user_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.UserStoreService', 'Correct service path');
        is($args->{method}, 'GetUserStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore'->new();
        return $response;
    };
    
    my $res = $client->get_user_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore', 'Response object class');
    done_testing();
};

subtest 'get_widget_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1.WidgetConfigService', 'Correct service path');
        is($args->{method}, 'GetWidgetConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig'->new();
        return $response;
    };
    
    my $res = $client->get_widget_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig', 'Response object class');
    done_testing();
};

done_testing();
