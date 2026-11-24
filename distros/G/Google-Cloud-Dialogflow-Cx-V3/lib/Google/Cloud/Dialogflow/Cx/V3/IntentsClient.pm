package Google::Cloud::Dialogflow::Cx::V3::IntentsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::Cx::V3::ValidationMessage;
use Google::Cloud::Dialogflow::Cx::V3::ImportStrategy;
use Google::Cloud::Dialogflow::Cx::V3::Inline;
use Google::Cloud::Dialogflow::Cx::V3::Gcs;
use Google::Cloud::Dialogflow::Cx::V3::AudioConfig;
use Google::Cloud::Dialogflow::Cx::V3::SafetySettings;
use Google::Cloud::Dialogflow::Cx::V3::CodeBlock;
use Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition;
use Google::Cloud::Dialogflow::Cx::V3::SecuritySettings;
use Google::Cloud::Dialogflow::Cx::V3::ToolCall;
use Google::Cloud::Dialogflow::Cx::V3::DataStoreConnection;
use Google::Cloud::Dialogflow::Cx::V3::Experiment;
use Google::Cloud::Dialogflow::Cx::V3::Changelog;
use Google::Cloud::Dialogflow::Cx::V3::Deployment;
use Google::Cloud::Dialogflow::Cx::V3::Trace;
use Google::Cloud::Dialogflow::Cx::V3::EntityType;
use Google::Cloud::Dialogflow::Cx::V3::Intent;
use Google::Cloud::Dialogflow::Cx::V3::AdvancedSettings;
use Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings;
use Google::Cloud::Dialogflow::Cx::V3::ResponseMessage;
use Google::Cloud::Dialogflow::Cx::V3::Tool;
use Google::Cloud::Dialogflow::Cx::V3::Example;
use Google::Cloud::Dialogflow::Cx::V3::SessionEntityType;
use Google::Cloud::Dialogflow::Cx::V3::Generator;
use Google::Cloud::Dialogflow::Cx::V3::Webhook;
use Google::Cloud::Dialogflow::Cx::V3::Fulfillment;
use Google::Cloud::Dialogflow::Cx::V3::Page;
use Google::Cloud::Dialogflow::Cx::V3::Playbook;
use Google::Cloud::Dialogflow::Cx::V3::TransitionRouteGroup;
use Google::Cloud::Dialogflow::Cx::V3::Flow;
use Google::Cloud::Dialogflow::Cx::V3::Version;
use Google::Cloud::Dialogflow::Cx::V3::Session;
use Google::Cloud::Dialogflow::Cx::V3::Agent;
use Google::Cloud::Dialogflow::Cx::V3::TestCase;
use Google::Cloud::Dialogflow::Cx::V3::Environment;

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

    my $target = 'dialogflow.googleapis.com:443';
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

sub list_intents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3.Intents/ListIntents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3.Intents',
        method         => 'ListIntents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::Cx::V3::IntentsClient

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::IntentsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::IntentsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::Cx::V3::IntentsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::Cx::V3::IntentsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::Cx::V3::IntentsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/cx/v3/advanced_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/changelog.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/code_block.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/data_store_connection.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/deployment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/example.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/experiment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/flow.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/generative_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/import_strategy.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/inline.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/page.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/parameter_definition.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/playbook.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/response_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/safety_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/security_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/session.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/test_case.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/trace.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/transition_route_group.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/validation_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/version.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::Cx::V3::IntentsClient->new(
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

=item * B<list_intents>

    my $response = $client->list_intents(
        parent                   => $parent,
        language_code            => $language_code,
        intent_view              => $intent_view,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListIntents> on C<google.cloud.dialogflow.cx.v3.Intents>.

Request: L<Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<intent_view> - L<Google::Cloud::Dialogflow::Cx::V3::Intent::IntentView>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
