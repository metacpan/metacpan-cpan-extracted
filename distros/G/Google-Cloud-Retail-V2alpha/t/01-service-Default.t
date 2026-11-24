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
    for my $pkg (qw( Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse Google::Cloud::Retail::V2alpha::Control::Control Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse Google::Cloud::Retail::V2alpha::Product::Product Google::Cloud::Retail::V2alpha::Project::AlertConfig Google::Cloud::Retail::V2alpha::Project::LoggingConfig Google::Cloud::Retail::V2alpha::Project::Project Google::Cloud::Retail::V2alpha::SearchService::SearchResponse Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig Google::Cloud::Retail::V2alpha::UserEvent::UserEvent Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Retail::V2alpha;

my $client = Google::Cloud::Retail::V2alpha->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'export_analytics_metrics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.AnalyticsService', 'Correct service path');
        is($args->{method}, 'ExportAnalyticsMetrics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ExportConfig::ExportAnalyticsMetricsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->export_analytics_metrics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_branches method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.BranchService', 'Correct service path');
        is($args->{method}, 'ListBranches', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_branches();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::BranchService::ListBranchesResponse', 'Response object class');
    done_testing();
};

subtest 'list_catalogs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CatalogService', 'Correct service path');
        is($args->{method}, 'ListCatalogs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_catalogs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse', 'Response object class');
    done_testing();
};

subtest 'update_completion_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateCompletionConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateCompletionConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig'->new();
        return $response;
    };
    
    my $res = $client->update_completion_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Catalog::CompletionConfig', 'Response object class');
    done_testing();
};

subtest 'update_attributes_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateAttributesConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateAttributesConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->update_attributes_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'remove_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CatalogService', 'Correct service path');
        is($args->{method}, 'RemoveCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CatalogService::RemoveCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->remove_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'replace_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CatalogService', 'Correct service path');
        is($args->{method}, 'ReplaceCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CatalogService::ReplaceCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->replace_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'create_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Control::Control', 'Response object class');
    done_testing();
};

subtest 'conversational_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConversationalSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse'->new();
        return $response;
    };
    
    my $res = $client->conversational_search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse', 'Response object class');
    done_testing();
};

subtest 'update_generative_questions_feature_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.GenerativeQuestionService', 'Correct service path');
        is($args->{method}, 'UpdateGenerativeQuestionsFeatureConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig'->new();
        return $response;
    };
    
    my $res = $client->update_generative_questions_feature_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::GenerativeQuestion::GenerativeQuestionsFeatureConfig', 'Response object class');
    done_testing();
};

subtest 'list_merchant_center_account_links method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.MerchantCenterAccountLinkService', 'Correct service path');
        is($args->{method}, 'ListMerchantCenterAccountLinks', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse'->new();
        return $response;
    };
    
    my $res = $client->list_merchant_center_account_links();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse', 'Response object class');
    done_testing();
};

subtest 'create_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ModelService', 'Correct service path');
        is($args->{method}, 'CreateModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ModelService::CreateModelRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'predict method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.PredictionService', 'Correct service path');
        is($args->{method}, 'Predict', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse'->new();
        return $response;
    };
    
    my $res = $client->predict();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse', 'Response object class');
    done_testing();
};

subtest 'create_product method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ProductService', 'Correct service path');
        is($args->{method}, 'CreateProduct', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ProductService::CreateProductRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Product::Product'->new();
        return $response;
    };
    
    my $res = $client->create_product();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Product::Product', 'Response object class');
    done_testing();
};

subtest 'get_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'GetProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Project::Project'->new();
        return $response;
    };
    
    my $res = $client->get_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Project::Project', 'Response object class');
    done_testing();
};

subtest 'enroll_solution method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'EnrollSolution', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->enroll_solution();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_logging_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'UpdateLoggingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig'->new();
        return $response;
    };
    
    my $res = $client->update_logging_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Project::LoggingConfig', 'Response object class');
    done_testing();
};

subtest 'update_alert_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ProjectService', 'Correct service path');
        is($args->{method}, 'UpdateAlertConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::Project::AlertConfig'->new();
        return $response;
    };
    
    my $res = $client->update_alert_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::Project::AlertConfig', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'create_serving_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.ServingConfigService', 'Correct service path');
        is($args->{method}, 'CreateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->create_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'write_user_event method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2alpha.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2alpha::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2alpha::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2alpha::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

done_testing();
