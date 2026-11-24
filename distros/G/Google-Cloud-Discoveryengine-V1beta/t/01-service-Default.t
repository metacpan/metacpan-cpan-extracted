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
    for my $pkg (qw( Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistResponse Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryResponse Google::Cloud::Discoveryengine::V1beta::Control::Control Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse Google::Cloud::Discoveryengine::V1beta::Document::Document Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet Google::Cloud::Discoveryengine::V1beta::Schema::Schema Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig Google::Cloud::Discoveryengine::V1beta::Session::Session Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Discoveryengine::V1beta;

my $client = Google::Cloud::Discoveryengine::V1beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'update_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.AclConfigService', 'Correct service path');
        is($args->{method}, 'UpdateAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->update_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'get_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.AclConfigService', 'Correct service path');
        is($args->{method}, 'GetAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->get_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'stream_assist method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.AssistantService', 'Correct service path');
        is($args->{method}, 'StreamAssist', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_assist();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistResponse', 'Response object class');
    done_testing();
};

subtest 'update_cmek_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.CmekConfigService', 'Correct service path');
        is($args->{method}, 'UpdateCmekConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_cmek_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'import_suggestion_deny_list_entries method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.CompletionService', 'Correct service path');
        is($args->{method}, 'ImportSuggestionDenyListEntries', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportSuggestionDenyListEntriesRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::Control::Control', 'Response object class');
    done_testing();
};

subtest 'converse_conversation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConverseConversation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse'->new();
        return $response;
    };
    
    my $res = $client->converse_conversation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse', 'Response object class');
    done_testing();
};

subtest 'create_data_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.DataStoreService', 'Correct service path');
        is($args->{method}, 'CreateDataStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.DocumentService', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::Document::Document'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::Document::Document', 'Response object class');
    done_testing();
};

subtest 'create_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.EngineService', 'Correct service path');
        is($args->{method}, 'CreateEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_evaluation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.EvaluationService', 'Correct service path');
        is($args->{method}, 'GetEvaluation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation'->new();
        return $response;
    };
    
    my $res = $client->get_evaluation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation', 'Response object class');
    done_testing();
};

subtest 'stream_generate_grounded_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.GroundedGenerationService', 'Correct service path');
        is($args->{method}, 'StreamGenerateGroundedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_generate_grounded_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse', 'Response object class');
    done_testing();
};

subtest 'create_identity_mapping_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService', 'Correct service path');
        is($args->{method}, 'CreateIdentityMappingStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore'->new();
        return $response;
    };
    
    my $res = $client->create_identity_mapping_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore', 'Response object class');
    done_testing();
};

subtest 'create_license_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.LicenseConfigService', 'Correct service path');
        is($args->{method}, 'CreateLicenseConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig'->new();
        return $response;
    };
    
    my $res = $client->create_license_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig', 'Response object class');
    done_testing();
};

subtest 'provision_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.ProjectService', 'Correct service path');
        is($args->{method}, 'ProvisionProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.RankService', 'Correct service path');
        is($args->{method}, 'Rank', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse'->new();
        return $response;
    };
    
    my $res = $client->rank();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse', 'Response object class');
    done_testing();
};

subtest 'recommend method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.RecommendationService', 'Correct service path');
        is($args->{method}, 'Recommend', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse'->new();
        return $response;
    };
    
    my $res = $client->recommend();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse', 'Response object class');
    done_testing();
};

subtest 'get_sample_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SampleQueryService', 'Correct service path');
        is($args->{method}, 'GetSampleQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery'->new();
        return $response;
    };
    
    my $res = $client->get_sample_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery', 'Response object class');
    done_testing();
};

subtest 'get_sample_query_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SampleQuerySetService', 'Correct service path');
        is($args->{method}, 'GetSampleQuerySet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet'->new();
        return $response;
    };
    
    my $res = $client->get_sample_query_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet', 'Response object class');
    done_testing();
};

subtest 'get_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SchemaService', 'Correct service path');
        is($args->{method}, 'GetSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::Schema::Schema'->new();
        return $response;
    };
    
    my $res = $client->get_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::Schema::Schema', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'train_custom_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SearchTuningService', 'Correct service path');
        is($args->{method}, 'TrainCustomModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.ServingConfigService', 'Correct service path');
        is($args->{method}, 'CreateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->create_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'create_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SessionService', 'Correct service path');
        is($args->{method}, 'CreateSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::Session::Session'->new();
        return $response;
    };
    
    my $res = $client->create_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::Session::Session', 'Response object class');
    done_testing();
};

subtest 'get_site_search_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'GetSiteSearchEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::GetSiteSearchEngineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine'->new();
        return $response;
    };
    
    my $res = $client->get_site_search_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine', 'Response object class');
    done_testing();
};

subtest 'batch_create_target_sites method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'BatchCreateTargetSites', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::BatchCreateTargetSitesRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'CreateSitemap', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::CreateSitemapRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'EnableAdvancedSiteSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::EnableAdvancedSiteSearchRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'RecrawlUris', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::RecrawlUrisRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

subtest 'list_user_licenses method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.UserLicenseService', 'Correct service path');
        is($args->{method}, 'ListUserLicenses', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_user_licenses();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse', 'Response object class');
    done_testing();
};

subtest 'get_user_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1beta.UserStoreService', 'Correct service path');
        is($args->{method}, 'GetUserStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore'->new();
        return $response;
    };
    
    my $res = $client->get_user_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore', 'Response object class');
    done_testing();
};

done_testing();
