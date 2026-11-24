package Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::Cx::V3beta1::BigqueryExport;
use Google::Cloud::Dialogflow::Cx::V3beta1::ValidationMessage;
use Google::Cloud::Dialogflow::Cx::V3beta1::ImportStrategy;
use Google::Cloud::Dialogflow::Cx::V3beta1::Inline;
use Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock;
use Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::Gcs;
use Google::Cloud::Dialogflow::Cx::V3beta1::ParameterDefinition;
use Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection;
use Google::Cloud::Dialogflow::Cx::V3beta1::AudioConfig;
use Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall;
use Google::Cloud::Dialogflow::Cx::V3beta1::Changelog;
use Google::Cloud::Dialogflow::Cx::V3beta1::Deployment;
use Google::Cloud::Dialogflow::Cx::V3beta1::Experiment;
use Google::Cloud::Dialogflow::Cx::V3beta1::SecuritySettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::EntityType;
use Google::Cloud::Dialogflow::Cx::V3beta1::Intent;
use Google::Cloud::Dialogflow::Cx::V3beta1::GenerativeSettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings;
use Google::Cloud::Dialogflow::Cx::V3beta1::Trace;
use Google::Cloud::Dialogflow::Cx::V3beta1::Tool;
use Google::Cloud::Dialogflow::Cx::V3beta1::ResponseMessage;
use Google::Cloud::Dialogflow::Cx::V3beta1::SessionEntityType;
use Google::Cloud::Dialogflow::Cx::V3beta1::Generator;
use Google::Cloud::Dialogflow::Cx::V3beta1::Example;
use Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment;
use Google::Cloud::Dialogflow::Cx::V3beta1::Webhook;
use Google::Cloud::Dialogflow::Cx::V3beta1::Playbook;
use Google::Cloud::Dialogflow::Cx::V3beta1::Page;
use Google::Cloud::Dialogflow::Cx::V3beta1::Flow;
use Google::Cloud::Dialogflow::Cx::V3beta1::TransitionRouteGroup;
use Google::Cloud::Dialogflow::Cx::V3beta1::Version;
use Google::Cloud::Dialogflow::Cx::V3beta1::Agent;
use Google::Cloud::Dialogflow::Cx::V3beta1::Session;
use Google::Cloud::Dialogflow::Cx::V3beta1::TestCase;
use Google::Cloud::Dialogflow::Cx::V3beta1::Environment;
use Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory;

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

sub create_flow {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Flow::CreateFlowRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.cx.v3beta1.Flows/CreateFlow',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.cx.v3beta1.Flows',
        method         => 'CreateFlow',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/advanced_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/bigquery_export.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/changelog.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/code_block.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/conversation_history.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/data_store_connection.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/deployment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/example.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/experiment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/flow.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/generative_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/import_strategy.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/inline.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/page.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/parameter_definition.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/playbook.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/response_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/safety_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/security_settings.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/session.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/test_case.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/trace.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/transition_route_group.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/validation_message.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/version.proto>

=item * C<googleapis/google/cloud/dialogflow/cx/v3beta1/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::Cx::V3beta1::FlowsClient->new(
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

=item * B<create_flow>

    my $response = $client->create_flow(
        parent                   => $parent,
        flow                     => $flow,
        language_code            => $language_code,
    );

Calls the RPC method C<CreateFlow> on C<google.cloud.dialogflow.cx.v3beta1.Flows>.

Request: L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::CreateFlowRequest>

Returns: L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<flow> - L<Google::Cloud::Dialogflow::Cx::V3beta1::Flow::Flow>

=item * C<language_code> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
