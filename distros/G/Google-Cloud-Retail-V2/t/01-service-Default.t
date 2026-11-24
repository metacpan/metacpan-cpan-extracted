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
    for my $pkg (qw( Google::Cloud::Retail::V2::Catalog::AttributesConfig Google::Cloud::Retail::V2::Catalog::CompletionConfig Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse Google::Cloud::Retail::V2::Control::Control Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchResponse Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig Google::Cloud::Retail::V2::PredictionService::PredictResponse Google::Cloud::Retail::V2::Product::Product Google::Cloud::Retail::V2::SearchService::SearchResponse Google::Cloud::Retail::V2::ServingConfig::ServingConfig Google::Cloud::Retail::V2::UserEvent::UserEvent Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Retail::V2;

my $client = Google::Cloud::Retail::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'export_analytics_metrics method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.AnalyticsService', 'Correct service path');
        is($args->{method}, 'ExportAnalyticsMetrics', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'ListCatalogs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_catalogs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse', 'Response object class');
    done_testing();
};

subtest 'update_completion_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateCompletionConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::CompletionConfig'->new();
        return $response;
    };
    
    my $res = $client->update_completion_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::CompletionConfig', 'Response object class');
    done_testing();
};

subtest 'update_attributes_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'UpdateAttributesConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->update_attributes_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'remove_catalog_attribute method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CatalogService', 'Correct service path');
        is($args->{method}, 'RemoveCatalogAttribute', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig'->new();
        return $response;
    };
    
    my $res = $client->remove_catalog_attribute();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Catalog::AttributesConfig', 'Response object class');
    done_testing();
};

subtest 'complete_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.CompletionService', 'Correct service path');
        is($args->{method}, 'CompleteQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->complete_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse', 'Response object class');
    done_testing();
};

subtest 'create_control method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.ControlService', 'Correct service path');
        is($args->{method}, 'CreateControl', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ControlService::CreateControlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Control::Control'->new();
        return $response;
    };
    
    my $res = $client->create_control();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Control::Control', 'Response object class');
    done_testing();
};

subtest 'conversational_search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.ConversationalSearchService', 'Correct service path');
        is($args->{method}, 'ConversationalSearch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchResponse'->new();
        return $response;
    };
    
    my $res = $client->conversational_search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchResponse', 'Response object class');
    done_testing();
};

subtest 'update_generative_questions_feature_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.GenerativeQuestionService', 'Correct service path');
        is($args->{method}, 'UpdateGenerativeQuestionsFeatureConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig'->new();
        return $response;
    };
    
    my $res = $client->update_generative_questions_feature_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig', 'Response object class');
    done_testing();
};

subtest 'create_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.ModelService', 'Correct service path');
        is($args->{method}, 'CreateModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ModelService::CreateModelRequest', 'Request object');
        
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
        is($args->{service}, 'google.cloud.retail.v2.PredictionService', 'Correct service path');
        is($args->{method}, 'Predict', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::PredictionService::PredictRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::PredictionService::PredictResponse'->new();
        return $response;
    };
    
    my $res = $client->predict();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::PredictionService::PredictResponse', 'Response object class');
    done_testing();
};

subtest 'create_product method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.ProductService', 'Correct service path');
        is($args->{method}, 'CreateProduct', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ProductService::CreateProductRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::Product::Product'->new();
        return $response;
    };
    
    my $res = $client->create_product();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::Product::Product', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::SearchService::SearchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::SearchService::SearchResponse'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::SearchService::SearchResponse', 'Response object class');
    done_testing();
};

subtest 'create_serving_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.ServingConfigService', 'Correct service path');
        is($args->{method}, 'CreateServingConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig'->new();
        return $response;
    };
    
    my $res = $client->create_serving_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig', 'Response object class');
    done_testing();
};

subtest 'write_user_event method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.retail.v2.UserEventService', 'Correct service path');
        is($args->{method}, 'WriteUserEvent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest', 'Request object');
        
        my $response = 'Google::Cloud::Retail::V2::UserEvent::UserEvent'->new();
        return $response;
    };
    
    my $res = $client->write_user_event();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Retail::V2::UserEvent::UserEvent', 'Response object class');
    done_testing();
};

done_testing();
