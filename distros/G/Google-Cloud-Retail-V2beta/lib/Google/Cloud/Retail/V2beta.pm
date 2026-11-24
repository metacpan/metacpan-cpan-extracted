package Google::Cloud::Retail::V2beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Retail::V2beta::Promotion;
use Google::Cloud::Retail::V2beta::Safety;
use Google::Cloud::Retail::V2beta::ExportConfig;
use Google::Cloud::Retail::V2beta::Project;
use Google::Cloud::Retail::V2beta::Common;
use Google::Cloud::Retail::V2beta::GenerativeQuestion;
use Google::Cloud::Retail::V2beta::PurgeConfig;
use Google::Cloud::Retail::V2beta::AnalyticsService;
use Google::Cloud::Retail::V2beta::ProjectService;
use Google::Cloud::Retail::V2beta::Product;
use Google::Cloud::Retail::V2beta::Model;
use Google::Cloud::Retail::V2beta::GenerativeQuestionService;
use Google::Cloud::Retail::V2beta::UserEvent;
use Google::Cloud::Retail::V2beta::SearchService;
use Google::Cloud::Retail::V2beta::ModelService;
use Google::Cloud::Retail::V2beta::ImportConfig;
use Google::Cloud::Retail::V2beta::PredictionService;
use Google::Cloud::Retail::V2beta::ServingConfig;
use Google::Cloud::Retail::V2beta::Control;
use Google::Cloud::Retail::V2beta::ConversationalSearchService;
use Google::Cloud::Retail::V2beta::Catalog;
use Google::Cloud::Retail::V2beta::UserEventService;
use Google::Cloud::Retail::V2beta::ProductService;
use Google::Cloud::Retail::V2beta::CompletionService;
use Google::Cloud::Retail::V2beta::ServingConfigService;
use Google::Cloud::Retail::V2beta::ControlService;
use Google::Cloud::Retail::V2beta::CatalogService;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'retail.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub export_analytics_metrics {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.AnalyticsService/ExportAnalyticsMetrics',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.AnalyticsService',
        method         => 'ExportAnalyticsMetrics',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_catalogs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CatalogService/ListCatalogs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CatalogService',
        method         => 'ListCatalogs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_completion_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CatalogService::UpdateCompletionConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Catalog::CompletionConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CatalogService/UpdateCompletionConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CatalogService',
        method         => 'UpdateCompletionConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_attributes_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CatalogService::UpdateAttributesConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CatalogService/UpdateAttributesConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CatalogService',
        method         => 'UpdateAttributesConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_catalog_attribute {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CatalogService::RemoveCatalogAttributeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CatalogService/RemoveCatalogAttribute',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CatalogService',
        method         => 'RemoveCatalogAttribute',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub replace_catalog_attribute {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CatalogService::ReplaceCatalogAttributeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Catalog::AttributesConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CatalogService/ReplaceCatalogAttribute',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CatalogService',
        method         => 'ReplaceCatalogAttribute',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub complete_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.CompletionService/CompleteQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.CompletionService',
        method         => 'CompleteQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_control {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Control::Control';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ControlService/CreateControl',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ControlService',
        method         => 'CreateControl',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub conversational_search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ConversationalSearchService/ConversationalSearch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ConversationalSearchService',
        method         => 'ConversationalSearch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_generative_questions_feature_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.GenerativeQuestionService/UpdateGenerativeQuestionsFeatureConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionsFeatureConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ModelService/CreateModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ModelService',
        method         => 'CreateModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_product {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ProductService::CreateProductRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Product::Product';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ProductService/CreateProduct',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ProductService',
        method         => 'CreateProduct',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_alert_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::Project::AlertConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ProjectService/GetAlertConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ProjectService',
        method         => 'GetAlertConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_serving_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.ServingConfigService/CreateServingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub write_user_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::UserEvent::UserEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.UserEventService/WriteUserEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.UserEventService',
        method         => 'WriteUserEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Retail::V2beta

__END__

=head1 NAME

Google::Cloud::Retail::V2beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/retail/v2beta/analytics_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/catalog.proto>

=item * C<googleapis/google/cloud/retail/v2beta/catalog_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/common.proto>

=item * C<googleapis/google/cloud/retail/v2beta/completion_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/control.proto>

=item * C<googleapis/google/cloud/retail/v2beta/control_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/conversational_search_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/export_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/generative_question.proto>

=item * C<googleapis/google/cloud/retail/v2beta/generative_question_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/import_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/model.proto>

=item * C<googleapis/google/cloud/retail/v2beta/model_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/prediction_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/product.proto>

=item * C<googleapis/google/cloud/retail/v2beta/product_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/project.proto>

=item * C<googleapis/google/cloud/retail/v2beta/project_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/promotion.proto>

=item * C<googleapis/google/cloud/retail/v2beta/purge_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/safety.proto>

=item * C<googleapis/google/cloud/retail/v2beta/search_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/serving_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/serving_config_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/user_event.proto>

=item * C<googleapis/google/cloud/retail/v2beta/user_event_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Retail::V2beta->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<export_analytics_metrics>

    my $response = $client->export_analytics_metrics(
        catalog                  => $catalog,
        output_config            => $output_config,
        filter                   => $filter,
    );

Calls the RPC method C<ExportAnalyticsMetrics> on C<google.cloud.retail.v2beta.AnalyticsService>.

Request: L<Google::Cloud::Retail::V2beta::ExportConfig::ExportAnalyticsMetricsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<catalog> - C<string>

=item * C<output_config> - L<Google::Cloud::Retail::V2beta::ExportConfig::OutputConfig>

=item * C<filter> - C<string>

=back

=item * B<list_catalogs>

    my $response = $client->list_catalogs(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListCatalogs> on C<google.cloud.retail.v2beta.CatalogService>.

Request: L<Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsRequest>

Returns: L<Google::Cloud::Retail::V2beta::CatalogService::ListCatalogsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_completion_config>

    my $response = $client->update_completion_config(
        completion_config        => $completion_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateCompletionConfig> on C<google.cloud.retail.v2beta.CatalogService>.

Request: L<Google::Cloud::Retail::V2beta::CatalogService::UpdateCompletionConfigRequest>

Returns: L<Google::Cloud::Retail::V2beta::Catalog::CompletionConfig>

Parameters:

=over 4

=item * C<completion_config> - L<Google::Cloud::Retail::V2beta::Catalog::CompletionConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<update_attributes_config>

    my $response = $client->update_attributes_config(
        attributes_config        => $attributes_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateAttributesConfig> on C<google.cloud.retail.v2beta.CatalogService>.

Request: L<Google::Cloud::Retail::V2beta::CatalogService::UpdateAttributesConfigRequest>

Returns: L<Google::Cloud::Retail::V2beta::Catalog::AttributesConfig>

Parameters:

=over 4

=item * C<attributes_config> - L<Google::Cloud::Retail::V2beta::Catalog::AttributesConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<remove_catalog_attribute>

    my $response = $client->remove_catalog_attribute(
        attributes_config        => $attributes_config,
        key                      => $key,
    );

Calls the RPC method C<RemoveCatalogAttribute> on C<google.cloud.retail.v2beta.CatalogService>.

Request: L<Google::Cloud::Retail::V2beta::CatalogService::RemoveCatalogAttributeRequest>

Returns: L<Google::Cloud::Retail::V2beta::Catalog::AttributesConfig>

Parameters:

=over 4

=item * C<attributes_config> - C<string>

=item * C<key> - C<string>

=back

=item * B<replace_catalog_attribute>

    my $response = $client->replace_catalog_attribute(
        attributes_config        => $attributes_config,
        catalog_attribute        => $catalog_attribute,
        update_mask              => $update_mask,
    );

Calls the RPC method C<ReplaceCatalogAttribute> on C<google.cloud.retail.v2beta.CatalogService>.

Request: L<Google::Cloud::Retail::V2beta::CatalogService::ReplaceCatalogAttributeRequest>

Returns: L<Google::Cloud::Retail::V2beta::Catalog::AttributesConfig>

Parameters:

=over 4

=item * C<attributes_config> - C<string>

=item * C<catalog_attribute> - L<Google::Cloud::Retail::V2beta::Catalog::CatalogAttribute>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<complete_query>

    my $response = $client->complete_query(
        catalog                  => $catalog,
        query                    => $query,
        visitor_id               => $visitor_id,
        language_codes           => [ ... ],
        device_type              => $device_type,
        dataset                  => $dataset,
        max_suggestions          => $max_suggestions,
        enable_attribute_suggestions => $enable_attribute_suggestions,
        entity                   => $entity,
    );

Calls the RPC method C<CompleteQuery> on C<google.cloud.retail.v2beta.CompletionService>.

Request: L<Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryRequest>

Returns: L<Google::Cloud::Retail::V2beta::CompletionService::CompleteQueryResponse>

Parameters:

=over 4

=item * C<catalog> - C<string>

=item * C<query> - C<string>

=item * C<visitor_id> - C<string>

=item * C<language_codes> - ArrayRef of C<string>

=item * C<device_type> - C<string>

=item * C<dataset> - C<string>

=item * C<max_suggestions> - C<int32>

=item * C<enable_attribute_suggestions> - C<bool>

=item * C<entity> - C<string>

=back

=item * B<create_control>

    my $response = $client->create_control(
        parent                   => $parent,
        control                  => $control,
        control_id               => $control_id,
    );

Calls the RPC method C<CreateControl> on C<google.cloud.retail.v2beta.ControlService>.

Request: L<Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Retail::V2beta::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Retail::V2beta::Control::Control>

=item * C<control_id> - C<string>

=back

=item * B<conversational_search>

    my $response = $client->conversational_search(
        placement                => $placement,
        branch                   => $branch,
        query                    => $query,
        page_categories          => [ ... ],
        conversation_id          => $conversation_id,
        search_params            => $search_params,
        visitor_id               => $visitor_id,
        user_info                => $user_info,
        conversational_filtering_spec => $conversational_filtering_spec,
        user_labels              => { ... },
        safety_settings          => [ ... ],
    );

Calls the RPC method C<ConversationalSearch> on C<google.cloud.retail.v2beta.ConversationalSearchService>.

Request: L<Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchRequest>

Returns: L<Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalSearchResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<conversation_id> - C<string>

=item * C<search_params> - L<Google::Cloud::Retail::V2beta::ConversationalSearchService::SearchParams>

=item * C<visitor_id> - C<string>

=item * C<user_info> - L<Google::Cloud::Retail::V2beta::Common::UserInfo>

=item * C<conversational_filtering_spec> - L<Google::Cloud::Retail::V2beta::ConversationalSearchService::ConversationalFilteringSpec>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<safety_settings> - ArrayRef of L<Google::Cloud::Retail::V2beta::Safety::SafetySetting>

=back

=item * B<update_generative_questions_feature_config>

    my $response = $client->update_generative_questions_feature_config(
        generative_questions_feature_config => $generative_questions_feature_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateGenerativeQuestionsFeatureConfig> on C<google.cloud.retail.v2beta.GenerativeQuestionService>.

Request: L<Google::Cloud::Retail::V2beta::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest>

Returns: L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig>

Parameters:

=over 4

=item * C<generative_questions_feature_config> - L<Google::Cloud::Retail::V2beta::GenerativeQuestion::GenerativeQuestionsFeatureConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_model>

    my $response = $client->create_model(
        parent                   => $parent,
        model                    => $model,
        dry_run                  => $dry_run,
    );

Calls the RPC method C<CreateModel> on C<google.cloud.retail.v2beta.ModelService>.

Request: L<Google::Cloud::Retail::V2beta::ModelService::CreateModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<model> - L<Google::Cloud::Retail::V2beta::Model::Model>

=item * C<dry_run> - C<bool>

=back

=item * B<predict>

    my $response = $client->predict(
        placement                => $placement,
        user_event               => $user_event,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        validate_only            => $validate_only,
        params                   => { ... },
        labels                   => { ... },
    );

Calls the RPC method C<Predict> on C<google.cloud.retail.v2beta.PredictionService>.

Request: L<Google::Cloud::Retail::V2beta::PredictionService::PredictRequest>

Returns: L<Google::Cloud::Retail::V2beta::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<user_event> - L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<validate_only> - C<bool>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<labels> - C<map<string, string>> (HashRef)

=back

=item * B<create_product>

    my $response = $client->create_product(
        parent                   => $parent,
        product                  => $product,
        product_id               => $product_id,
    );

Calls the RPC method C<CreateProduct> on C<google.cloud.retail.v2beta.ProductService>.

Request: L<Google::Cloud::Retail::V2beta::ProductService::CreateProductRequest>

Returns: L<Google::Cloud::Retail::V2beta::Product::Product>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<product> - L<Google::Cloud::Retail::V2beta::Product::Product>

=item * C<product_id> - C<string>

=back

=item * B<get_alert_config>

    my $response = $client->get_alert_config(
        name                     => $name,
    );

Calls the RPC method C<GetAlertConfig> on C<google.cloud.retail.v2beta.ProjectService>.

Request: L<Google::Cloud::Retail::V2beta::ProjectService::GetAlertConfigRequest>

Returns: L<Google::Cloud::Retail::V2beta::Project::AlertConfig>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search>

    my $response = $client->search(
        placement                => $placement,
        branch                   => $branch,
        query                    => $query,
        visitor_id               => $visitor_id,
        user_info                => $user_info,
        page_size                => $page_size,
        page_token               => $page_token,
        offset                   => $offset,
        filter                   => $filter,
        canonical_filter         => $canonical_filter,
        order_by                 => $order_by,
        facet_specs              => [ ... ],
        dynamic_facet_spec       => $dynamic_facet_spec,
        boost_spec               => $boost_spec,
        query_expansion_spec     => $query_expansion_spec,
        variant_rollup_keys      => [ ... ],
        page_categories          => [ ... ],
        search_mode              => $search_mode,
        personalization_spec     => $personalization_spec,
        labels                   => { ... },
        spell_correction_spec    => $spell_correction_spec,
        entity                   => $entity,
        conversational_search_spec => $conversational_search_spec,
        tile_navigation_spec     => $tile_navigation_spec,
        language_code            => $language_code,
        region_code              => $region_code,
        place_id                 => $place_id,
        user_attributes          => { ... },
    );

Calls the RPC method C<Search> on C<google.cloud.retail.v2beta.SearchService>.

Request: L<Google::Cloud::Retail::V2beta::SearchService::SearchRequest>

Returns: L<Google::Cloud::Retail::V2beta::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<visitor_id> - C<string>

=item * C<user_info> - L<Google::Cloud::Retail::V2beta::Common::UserInfo>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Retail::V2beta::SearchService::FacetSpec>

=item * C<dynamic_facet_spec> - L<Google::Cloud::Retail::V2beta::SearchService::DynamicFacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Retail::V2beta::SearchService::BoostSpec>

=item * C<query_expansion_spec> - L<Google::Cloud::Retail::V2beta::SearchService::QueryExpansionSpec>

=item * C<variant_rollup_keys> - ArrayRef of C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<search_mode> - L<Google::Cloud::Retail::V2beta::SearchService::SearchMode>

=item * C<personalization_spec> - L<Google::Cloud::Retail::V2beta::SearchService::PersonalizationSpec>

=item * C<labels> - C<map<string, string>> (HashRef)

=item * C<spell_correction_spec> - L<Google::Cloud::Retail::V2beta::SearchService::SpellCorrectionSpec>

=item * C<entity> - C<string>

=item * C<conversational_search_spec> - L<Google::Cloud::Retail::V2beta::SearchService::ConversationalSearchSpec>

=item * C<tile_navigation_spec> - L<Google::Cloud::Retail::V2beta::SearchService::TileNavigationSpec>

=item * C<language_code> - C<string>

=item * C<region_code> - C<string>

=item * C<place_id> - C<string>

=item * C<user_attributes> - C<map<string, StringList>> (HashRef)

=back

=item * B<create_serving_config>

    my $response = $client->create_serving_config(
        parent                   => $parent,
        serving_config           => $serving_config,
        serving_config_id        => $serving_config_id,
    );

Calls the RPC method C<CreateServingConfig> on C<google.cloud.retail.v2beta.ServingConfigService>.

Request: L<Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest>

Returns: L<Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<serving_config> - L<Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig>

=item * C<serving_config_id> - C<string>

=back

=item * B<write_user_event>

    my $response = $client->write_user_event(
        parent                   => $parent,
        user_event               => $user_event,
        write_async              => $write_async,
    );

Calls the RPC method C<WriteUserEvent> on C<google.cloud.retail.v2beta.UserEventService>.

Request: L<Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest>

Returns: L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<user_event> - L<Google::Cloud::Retail::V2beta::UserEvent::UserEvent>

=item * C<write_async> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
