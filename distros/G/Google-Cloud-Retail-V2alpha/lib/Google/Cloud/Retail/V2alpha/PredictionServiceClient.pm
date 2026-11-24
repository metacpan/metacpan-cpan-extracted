package Google::Cloud::Retail::V2alpha::PredictionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Retail::V2alpha::Promotion;
use Google::Cloud::Retail::V2alpha::PurgeConfig;
use Google::Cloud::Retail::V2alpha::ExportConfig;
use Google::Cloud::Retail::V2alpha::Common;
use Google::Cloud::Retail::V2alpha::GenerativeQuestion;
use Google::Cloud::Retail::V2alpha::Safety;
use Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink;
use Google::Cloud::Retail::V2alpha::AnalyticsService;
use Google::Cloud::Retail::V2alpha::Project;
use Google::Cloud::Retail::V2alpha::Product;
use Google::Cloud::Retail::V2alpha::Model;
use Google::Cloud::Retail::V2alpha::GenerativeQuestionService;
use Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService;
use Google::Cloud::Retail::V2alpha::ProjectService;
use Google::Cloud::Retail::V2alpha::SearchService;
use Google::Cloud::Retail::V2alpha::UserEvent;
use Google::Cloud::Retail::V2alpha::Branch;
use Google::Cloud::Retail::V2alpha::ModelService;
use Google::Cloud::Retail::V2alpha::ConversationalSearchService;
use Google::Cloud::Retail::V2alpha::ServingConfig;
use Google::Cloud::Retail::V2alpha::Control;
use Google::Cloud::Retail::V2alpha::PredictionService;
use Google::Cloud::Retail::V2alpha::ImportConfig;
use Google::Cloud::Retail::V2alpha::BranchService;
use Google::Cloud::Retail::V2alpha::ServingConfigService;
use Google::Cloud::Retail::V2alpha::ControlService;
use Google::Cloud::Retail::V2alpha::ProductService;
use Google::Cloud::Retail::V2alpha::CompletionService;
use Google::Cloud::Retail::V2alpha::Catalog;
use Google::Cloud::Retail::V2alpha::UserEventService;
use Google::Cloud::Retail::V2alpha::CatalogService;

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

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2alpha.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2alpha.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Retail::V2alpha::PredictionServiceClient

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::PredictionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::PredictionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2alpha::PredictionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2alpha::PredictionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2alpha::PredictionServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/retail/v2alpha/analytics_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/branch.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/branch_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/catalog.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/catalog_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/common.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/completion_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/control.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/control_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/conversational_search_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/export_config.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/generative_question.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/generative_question_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/import_config.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/merchant_center_account_link.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/merchant_center_account_link_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/model.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/model_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/prediction_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/product.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/product_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/project.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/project_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/promotion.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/purge_config.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/safety.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/search_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/serving_config.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/serving_config_service.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/user_event.proto>

=item * C<googleapis/google/cloud/retail/v2alpha/user_event_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Retail::V2alpha::PredictionServiceClient->new(
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

Calls the RPC method C<Predict> on C<google.cloud.retail.v2alpha.PredictionService>.

Request: L<Google::Cloud::Retail::V2alpha::PredictionService::PredictRequest>

Returns: L<Google::Cloud::Retail::V2alpha::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<user_event> - L<Google::Cloud::Retail::V2alpha::UserEvent::UserEvent>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<validate_only> - C<bool>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<labels> - C<map<string, string>> (HashRef)

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
