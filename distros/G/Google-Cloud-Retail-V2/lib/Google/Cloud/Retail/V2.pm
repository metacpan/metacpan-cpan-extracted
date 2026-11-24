package Google::Cloud::Retail::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Retail::V2::Promotion;
use Google::Cloud::Retail::V2::Safety;
use Google::Cloud::Retail::V2::GenerativeQuestion;
use Google::Cloud::Retail::V2::PurgeConfig;
use Google::Cloud::Retail::V2::Common;
use Google::Cloud::Retail::V2::ExportConfig;
use Google::Cloud::Retail::V2::GenerativeQuestionService;
use Google::Cloud::Retail::V2::Model;
use Google::Cloud::Retail::V2::Control;
use Google::Cloud::Retail::V2::Product;
use Google::Cloud::Retail::V2::AnalyticsService;
use Google::Cloud::Retail::V2::ModelService;
use Google::Cloud::Retail::V2::ControlService;
use Google::Cloud::Retail::V2::SearchService;
use Google::Cloud::Retail::V2::UserEvent;
use Google::Cloud::Retail::V2::ServingConfig;
use Google::Cloud::Retail::V2::ConversationalSearchService;
use Google::Cloud::Retail::V2::PredictionService;
use Google::Cloud::Retail::V2::ImportConfig;
use Google::Cloud::Retail::V2::ServingConfigService;
use Google::Cloud::Retail::V2::Catalog;
use Google::Cloud::Retail::V2::CompletionService;
use Google::Cloud::Retail::V2::ProductService;
use Google::Cloud::Retail::V2::UserEventService;
use Google::Cloud::Retail::V2::CatalogService;

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

    my $request_class = 'Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest';
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
            path           => '/google.cloud.retail.v2.AnalyticsService/ExportAnalyticsMetrics',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.AnalyticsService',
        method         => 'ExportAnalyticsMetrics',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_catalogs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.CatalogService/ListCatalogs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'ListCatalogs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_completion_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::Catalog::CompletionConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.CatalogService/UpdateCompletionConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'UpdateCompletionConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_attributes_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.CatalogService/UpdateAttributesConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'UpdateAttributesConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_catalog_attribute {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::Catalog::AttributesConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.CatalogService/RemoveCatalogAttribute',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.CatalogService',
        method         => 'RemoveCatalogAttribute',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub complete_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.CompletionService/CompleteQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.CompletionService',
        method         => 'CompleteQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_control {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::ControlService::CreateControlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::Control::Control';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.ControlService/CreateControl',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.ControlService',
        method         => 'CreateControl',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub conversational_search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.ConversationalSearchService/ConversationalSearch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.ConversationalSearchService',
        method         => 'ConversationalSearch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_generative_questions_feature_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.GenerativeQuestionService/UpdateGenerativeQuestionsFeatureConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.GenerativeQuestionService',
        method         => 'UpdateGenerativeQuestionsFeatureConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::ModelService::CreateModelRequest';
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
            path           => '/google.cloud.retail.v2.ModelService/CreateModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.ModelService',
        method         => 'CreateModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_product {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::ProductService::CreateProductRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::Product::Product';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.ProductService/CreateProduct',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.ProductService',
        method         => 'CreateProduct',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_serving_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::ServingConfig::ServingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.ServingConfigService/CreateServingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub write_user_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2::UserEvent::UserEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2.UserEventService/WriteUserEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2.UserEventService',
        method         => 'WriteUserEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Retail::V2

__END__

=head1 NAME

Google::Cloud::Retail::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/retail/v2/analytics_service.proto>

=item * C<googleapis/google/cloud/retail/v2/catalog.proto>

=item * C<googleapis/google/cloud/retail/v2/catalog_service.proto>

=item * C<googleapis/google/cloud/retail/v2/common.proto>

=item * C<googleapis/google/cloud/retail/v2/completion_service.proto>

=item * C<googleapis/google/cloud/retail/v2/control.proto>

=item * C<googleapis/google/cloud/retail/v2/control_service.proto>

=item * C<googleapis/google/cloud/retail/v2/conversational_search_service.proto>

=item * C<googleapis/google/cloud/retail/v2/export_config.proto>

=item * C<googleapis/google/cloud/retail/v2/generative_question.proto>

=item * C<googleapis/google/cloud/retail/v2/generative_question_service.proto>

=item * C<googleapis/google/cloud/retail/v2/import_config.proto>

=item * C<googleapis/google/cloud/retail/v2/model.proto>

=item * C<googleapis/google/cloud/retail/v2/model_service.proto>

=item * C<googleapis/google/cloud/retail/v2/prediction_service.proto>

=item * C<googleapis/google/cloud/retail/v2/product.proto>

=item * C<googleapis/google/cloud/retail/v2/product_service.proto>

=item * C<googleapis/google/cloud/retail/v2/promotion.proto>

=item * C<googleapis/google/cloud/retail/v2/purge_config.proto>

=item * C<googleapis/google/cloud/retail/v2/safety.proto>

=item * C<googleapis/google/cloud/retail/v2/search_service.proto>

=item * C<googleapis/google/cloud/retail/v2/serving_config.proto>

=item * C<googleapis/google/cloud/retail/v2/serving_config_service.proto>

=item * C<googleapis/google/cloud/retail/v2/user_event.proto>

=item * C<googleapis/google/cloud/retail/v2/user_event_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Retail::V2->new(
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

Calls the RPC method C<ExportAnalyticsMetrics> on C<google.cloud.retail.v2.AnalyticsService>.

Request: L<Google::Cloud::Retail::V2::ExportConfig::ExportAnalyticsMetricsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<catalog> - C<string>

=item * C<output_config> - L<Google::Cloud::Retail::V2::ExportConfig::OutputConfig>

=item * C<filter> - C<string>

=back

=item * B<list_catalogs>

    my $response = $client->list_catalogs(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListCatalogs> on C<google.cloud.retail.v2.CatalogService>.

Request: L<Google::Cloud::Retail::V2::CatalogService::ListCatalogsRequest>

Returns: L<Google::Cloud::Retail::V2::CatalogService::ListCatalogsResponse>

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

Calls the RPC method C<UpdateCompletionConfig> on C<google.cloud.retail.v2.CatalogService>.

Request: L<Google::Cloud::Retail::V2::CatalogService::UpdateCompletionConfigRequest>

Returns: L<Google::Cloud::Retail::V2::Catalog::CompletionConfig>

Parameters:

=over 4

=item * C<completion_config> - L<Google::Cloud::Retail::V2::Catalog::CompletionConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<update_attributes_config>

    my $response = $client->update_attributes_config(
        attributes_config        => $attributes_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateAttributesConfig> on C<google.cloud.retail.v2.CatalogService>.

Request: L<Google::Cloud::Retail::V2::CatalogService::UpdateAttributesConfigRequest>

Returns: L<Google::Cloud::Retail::V2::Catalog::AttributesConfig>

Parameters:

=over 4

=item * C<attributes_config> - L<Google::Cloud::Retail::V2::Catalog::AttributesConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<remove_catalog_attribute>

    my $response = $client->remove_catalog_attribute(
        attributes_config        => $attributes_config,
        key                      => $key,
    );

Calls the RPC method C<RemoveCatalogAttribute> on C<google.cloud.retail.v2.CatalogService>.

Request: L<Google::Cloud::Retail::V2::CatalogService::RemoveCatalogAttributeRequest>

Returns: L<Google::Cloud::Retail::V2::Catalog::AttributesConfig>

Parameters:

=over 4

=item * C<attributes_config> - C<string>

=item * C<key> - C<string>

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

Calls the RPC method C<CompleteQuery> on C<google.cloud.retail.v2.CompletionService>.

Request: L<Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest>

Returns: L<Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse>

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

Calls the RPC method C<CreateControl> on C<google.cloud.retail.v2.ControlService>.

Request: L<Google::Cloud::Retail::V2::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Retail::V2::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Retail::V2::Control::Control>

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

Calls the RPC method C<ConversationalSearch> on C<google.cloud.retail.v2.ConversationalSearchService>.

Request: L<Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchRequest>

Returns: L<Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalSearchResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<conversation_id> - C<string>

=item * C<search_params> - L<Google::Cloud::Retail::V2::ConversationalSearchService::SearchParams>

=item * C<visitor_id> - C<string>

=item * C<user_info> - L<Google::Cloud::Retail::V2::Common::UserInfo>

=item * C<conversational_filtering_spec> - L<Google::Cloud::Retail::V2::ConversationalSearchService::ConversationalFilteringSpec>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<safety_settings> - ArrayRef of L<Google::Cloud::Retail::V2::Safety::SafetySetting>

=back

=item * B<update_generative_questions_feature_config>

    my $response = $client->update_generative_questions_feature_config(
        generative_questions_feature_config => $generative_questions_feature_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateGenerativeQuestionsFeatureConfig> on C<google.cloud.retail.v2.GenerativeQuestionService>.

Request: L<Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest>

Returns: L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig>

Parameters:

=over 4

=item * C<generative_questions_feature_config> - L<Google::Cloud::Retail::V2::GenerativeQuestion::GenerativeQuestionsFeatureConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_model>

    my $response = $client->create_model(
        parent                   => $parent,
        model                    => $model,
        dry_run                  => $dry_run,
    );

Calls the RPC method C<CreateModel> on C<google.cloud.retail.v2.ModelService>.

Request: L<Google::Cloud::Retail::V2::ModelService::CreateModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<model> - L<Google::Cloud::Retail::V2::Model::Model>

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

Calls the RPC method C<Predict> on C<google.cloud.retail.v2.PredictionService>.

Request: L<Google::Cloud::Retail::V2::PredictionService::PredictRequest>

Returns: L<Google::Cloud::Retail::V2::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<user_event> - L<Google::Cloud::Retail::V2::UserEvent::UserEvent>

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

Calls the RPC method C<CreateProduct> on C<google.cloud.retail.v2.ProductService>.

Request: L<Google::Cloud::Retail::V2::ProductService::CreateProductRequest>

Returns: L<Google::Cloud::Retail::V2::Product::Product>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<product> - L<Google::Cloud::Retail::V2::Product::Product>

=item * C<product_id> - C<string>

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

Calls the RPC method C<Search> on C<google.cloud.retail.v2.SearchService>.

Request: L<Google::Cloud::Retail::V2::SearchService::SearchRequest>

Returns: L<Google::Cloud::Retail::V2::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<visitor_id> - C<string>

=item * C<user_info> - L<Google::Cloud::Retail::V2::Common::UserInfo>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Retail::V2::SearchService::FacetSpec>

=item * C<dynamic_facet_spec> - L<Google::Cloud::Retail::V2::SearchService::DynamicFacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Retail::V2::SearchService::BoostSpec>

=item * C<query_expansion_spec> - L<Google::Cloud::Retail::V2::SearchService::QueryExpansionSpec>

=item * C<variant_rollup_keys> - ArrayRef of C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<search_mode> - L<Google::Cloud::Retail::V2::SearchService::SearchMode>

=item * C<personalization_spec> - L<Google::Cloud::Retail::V2::SearchService::PersonalizationSpec>

=item * C<labels> - C<map<string, string>> (HashRef)

=item * C<spell_correction_spec> - L<Google::Cloud::Retail::V2::SearchService::SpellCorrectionSpec>

=item * C<entity> - C<string>

=item * C<conversational_search_spec> - L<Google::Cloud::Retail::V2::SearchService::ConversationalSearchSpec>

=item * C<tile_navigation_spec> - L<Google::Cloud::Retail::V2::SearchService::TileNavigationSpec>

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

Calls the RPC method C<CreateServingConfig> on C<google.cloud.retail.v2.ServingConfigService>.

Request: L<Google::Cloud::Retail::V2::ServingConfigService::CreateServingConfigRequest>

Returns: L<Google::Cloud::Retail::V2::ServingConfig::ServingConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<serving_config> - L<Google::Cloud::Retail::V2::ServingConfig::ServingConfig>

=item * C<serving_config_id> - C<string>

=back

=item * B<write_user_event>

    my $response = $client->write_user_event(
        parent                   => $parent,
        user_event               => $user_event,
        write_async              => $write_async,
    );

Calls the RPC method C<WriteUserEvent> on C<google.cloud.retail.v2.UserEventService>.

Request: L<Google::Cloud::Retail::V2::UserEventService::WriteUserEventRequest>

Returns: L<Google::Cloud::Retail::V2::UserEvent::UserEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<user_event> - L<Google::Cloud::Retail::V2::UserEvent::UserEvent>

=item * C<write_async> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
