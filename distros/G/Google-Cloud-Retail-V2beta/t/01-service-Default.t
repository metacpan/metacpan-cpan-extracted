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
    for my $pkg (qw( Google::Cloud::Retail::V2beta::Catalog::AttributesConfig Google::Cloud::Retail::V2beta::Catalog::CompletionConfig Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsResponse Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse Google::Cloud::Retail::V2beta::Control::Control Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchResponse Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig Google::Cloud::Retail::V2beta::PredictionService::PredictResponse Google::Cloud::Retail::V2beta::Product::Product Google::Cloud::Retail::V2beta::Project::AlertConfig Google::Cloud::Retail::V2beta::SearchService::SearchResponse Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig Google::Cloud::Retail::V2beta::UserEvent::UserEvent Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Retail::V2beta;

my $client = Google::Cloud::Retail::V2beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'export_analytics_metrics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.AnalyticsService', 'Correct service path');
        is($args->{method}, 'ExportAnalyticsMetrics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->export_analytics_metrics();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_catalogs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CatalogService', 'Correct service path');
        is($args->{method}, 'ListCatalogs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_catalogs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsResponse', 'Response object class');
    done_testing();
};

subtest 'update_completion_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateCompletionConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CatalogService::UpdateCompletionConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Catalog::CompletionConfig'->new();
        return $response;
    };
    
    my $res = $client->update_completion_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Catalog::CompletionConfig', 'Response object class');
    done_testing();
};

subtest 'update_attributes_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateAttributesConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CatalogService::UpdateAttributesConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->update_attributes_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'remove_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CatalogService', 'Correct service path');
        is($args->{method}, 'RemoveCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CatalogService::RemoveCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->remove_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'replace_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CatalogService', 'Correct service path');
        is($args->{method}, 'ReplaceCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CatalogService::ReplaceCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->replace_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'create_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Control::Control', 'Response object class');
    done_testing();
};

subtest 'conversational_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConversationalSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchResponse'->new();
        return $response;
    };
    
    my $res = $client->conversational_search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchResponse', 'Response object class');
    done_testing();
};

subtest 'update_generative_questions_feature_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.GenerativeQuestionService', 'Correct service path');
        is($args->{method}, 'UpdateGenerativeQuestionsFeatureConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig'->new();
        return $response;
    };
    
    my $res = $client->update_generative_questions_feature_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig', 'Response object class');
    done_testing();
};

subtest 'create_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ModelService', 'Correct service path');
        is($args->{method}, 'CreateModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.retail.v2beta.PredictionService', 'Correct service path');
        is($args->{method}, 'Predict', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse'->new();
        return $response;
    };
    
    my $res = $client->predict();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse', 'Response object class');
    done_testing();
};

subtest 'create_product method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ProductService', 'Correct service path');
        is($args->{method}, 'CreateProduct', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ProductService::CreateProductRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Product::Product'->new();
        return $response;
    };
    
    my $res = $client->create_product();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Product::Product', 'Response object class');
    done_testing();
};

subtest 'get_alert_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ProjectService', 'Correct service path');
        is($args->{method}, 'GetAlertConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::Project::AlertConfig'->new();
        return $response;
    };
    
    my $res = $client->get_alert_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::Project::AlertConfig', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'create_serving_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.ServingConfigService', 'Correct service path');
        is($args->{method}, 'CreateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->create_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'write_user_event method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2beta.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

done_testing();
