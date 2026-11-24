package Google::Cloud::Retail::V2beta::ControlServiceClient;

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
use Google::Cloud::Retail::V2beta::Common;
use Google::Cloud::Retail::V2beta::GenerativeQuestion;
use Google::Cloud::Retail::V2beta::ExportConfig;
use Google::Cloud::Retail::V2beta::Project;
use Google::Cloud::Retail::V2beta::PurgeConfig;
use Google::Cloud::Retail::V2beta::Product;
use Google::Cloud::Retail::V2beta::Model;
use Google::Cloud::Retail::V2beta::GenerativeQuestionService;
use Google::Cloud::Retail::V2beta::AnalyticsService;
use Google::Cloud::Retail::V2beta::ProjectService;
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
1; # End of Google::Cloud::Retail::V2beta::ControlServiceClient

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::ControlServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ControlServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2beta::ControlServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2beta::ControlServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2beta::ControlServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Retail::V2beta::ControlServiceClient->new(
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

Calls the RPC method C<CreateControl> on C<google.cloud.retail.v2beta.ControlService>.

Request: L<Google::Cloud::Retail::V2beta::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Retail::V2beta::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Retail::V2beta::Control::Control>

=item * C<control_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
