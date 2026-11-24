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
    for my $pkg (qw( Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse Google::Cloud::Discoveryengine::V1alpha::Control::Control Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationResponse Google::Cloud::Discoveryengine::V1alpha::Document::Document Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse Google::Cloud::Discoveryengine::V1alpha::Project::Project Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet Google::Cloud::Discoveryengine::V1alpha::Schema::Schema Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig Google::Cloud::Discoveryengine::V1alpha::Session::Session Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Discoveryengine::V1alpha;

my $client = Google::Cloud::Discoveryengine::V1alpha->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'update_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.AclConfigService', 'Correct service path');
        is($args->{method}, 'UpdateAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->update_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'get_acl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.AclConfigService', 'Correct service path');
        is($args->{method}, 'GetAclConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig'->new();
        return $response;
    };
    
    my $res = $client->get_acl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig', 'Response object class');
    done_testing();
};

subtest 'get_chunk method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ChunkService', 'Correct service path');
        is($args->{method}, 'GetChunk', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk'->new();
        return $response;
    };
    
    my $res = $client->get_chunk();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'create_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Control::Control', 'Response object class');
    done_testing();
};

subtest 'converse_conversation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConverseConversation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationResponse'->new();
        return $response;
    };
    
    my $res = $client->converse_conversation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationResponse', 'Response object class');
    done_testing();
};

subtest 'create_data_store method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.DataStoreService', 'Correct service path');
        is($args->{method}, 'CreateDataStore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_data_store();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_document_processing_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.DataStoreService', 'Correct service path');
        is($args->{method}, 'UpdateDocumentProcessingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig'->new();
        return $response;
    };
    
    my $res = $client->update_document_processing_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig', 'Response object class');
    done_testing();
};

subtest 'get_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.DocumentService', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Document::Document'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Document::Document', 'Response object class');
    done_testing();
};

subtest 'create_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.EngineService', 'Correct service path');
        is($args->{method}, 'CreateEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'estimate_data_size method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.EstimateBillingService', 'Correct service path');
        is($args->{method}, 'EstimateDataSize', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->estimate_data_size();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_evaluation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.EvaluationService', 'Correct service path');
        is($args->{method}, 'GetEvaluation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation'->new();
        return $response;
    };
    
    my $res = $client->get_evaluation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation', 'Response object class');
    done_testing();
};

subtest 'check_grounding method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.GroundedGenerationService', 'Correct service path');
        is($args->{method}, 'CheckGrounding', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse'->new();
        return $response;
    };
    
    my $res = $client->check_grounding();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse', 'Response object class');
    done_testing();
};

subtest 'get_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'GetProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Project::Project'->new();
        return $response;
    };
    
    my $res = $client->get_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Project::Project', 'Response object class');
    done_testing();
};

subtest 'provision_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'ProvisionProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->provision_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'report_consent_change method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'ReportConsentChange', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Project::Project'->new();
        return $response;
    };
    
    my $res = $client->report_consent_change();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Project::Project', 'Response object class');
    done_testing();
};

subtest 'rank method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.RankService', 'Correct service path');
        is($args->{method}, 'Rank', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse'->new();
        return $response;
    };
    
    my $res = $client->rank();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse', 'Response object class');
    done_testing();
};

subtest 'recommend method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.RecommendationService', 'Correct service path');
        is($args->{method}, 'Recommend', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse'->new();
        return $response;
    };
    
    my $res = $client->recommend();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse', 'Response object class');
    done_testing();
};

subtest 'get_sample_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SampleQueryService', 'Correct service path');
        is($args->{method}, 'GetSampleQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery'->new();
        return $response;
    };
    
    my $res = $client->get_sample_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery', 'Response object class');
    done_testing();
};

subtest 'get_sample_query_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService', 'Correct service path');
        is($args->{method}, 'GetSampleQuerySet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet'->new();
        return $response;
    };
    
    my $res = $client->get_sample_query_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet', 'Response object class');
    done_testing();
};

subtest 'get_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SchemaService', 'Correct service path');
        is($args->{method}, 'GetSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema'->new();
        return $response;
    };
    
    my $res = $client->get_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'train_custom_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SearchTuningService', 'Correct service path');
        is($args->{method}, 'TrainCustomModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->train_custom_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_serving_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.ServingConfigService', 'Correct service path');
        is($args->{method}, 'UpdateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->update_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'create_session method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SessionService', 'Correct service path');
        is($args->{method}, 'CreateSession', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::CreateSessionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::Session::Session'->new();
        return $response;
    };
    
    my $res = $client->create_session();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::Session::Session', 'Response object class');
    done_testing();
};

subtest 'get_site_search_engine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'GetSiteSearchEngine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine'->new();
        return $response;
    };
    
    my $res = $client->get_site_search_engine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine', 'Response object class');
    done_testing();
};

subtest 'batch_create_target_sites method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'BatchCreateTargetSites', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_create_target_sites();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'enable_advanced_site_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'EnableAdvancedSiteSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService', 'Correct service path');
        is($args->{method}, 'RecrawlUris', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.discoveryengine.v1alpha.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

done_testing();
