package Google::Cloud::Retail::V2::ControlServiceClient;

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
use Google::Cloud::Retail::V2::PurgeConfig;
use Google::Cloud::Retail::V2::GenerativeQuestion;
use Google::Cloud::Retail::V2::Common;
use Google::Cloud::Retail::V2::ExportConfig;
use Google::Cloud::Retail::V2::GenerativeQuestionService;
use Google::Cloud::Retail::V2::Control;
use Google::Cloud::Retail::V2::Model;
use Google::Cloud::Retail::V2::Product;
use Google::Cloud::Retail::V2::AnalyticsService;
use Google::Cloud::Retail::V2::ControlService;
use Google::Cloud::Retail::V2::ModelService;
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
1; # End of Google::Cloud::Retail::V2::ControlServiceClient

__END__

=head1 NAME

Google::Cloud::Retail::V2::ControlServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::ControlServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2::ControlServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2::ControlServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2::ControlServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Retail::V2::ControlServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
