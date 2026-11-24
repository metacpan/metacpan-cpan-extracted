package Google::Cloud::Dialogflow::V2::EnvironmentsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::V2::ValidationResult;
use Google::Cloud::Dialogflow::V2::AgentCoachingInstruction;
use Google::Cloud::Dialogflow::V2::Grounding;
use Google::Cloud::Dialogflow::V2::Gcs;
use Google::Cloud::Dialogflow::V2::ConversationModel;
use Google::Cloud::Dialogflow::V2::AudioConfig;
use Google::Cloud::Dialogflow::V2::EntityType;
use Google::Cloud::Dialogflow::V2::Agent;
use Google::Cloud::Dialogflow::V2::KnowledgeBase;
use Google::Cloud::Dialogflow::V2::Version;
use Google::Cloud::Dialogflow::V2::Operations;
use Google::Cloud::Dialogflow::V2::ToolCall;
use Google::Cloud::Dialogflow::V2::Fulfillment;
use Google::Cloud::Dialogflow::V2::EncryptionSpec;
use Google::Cloud::Dialogflow::V2::Context;
use Google::Cloud::Dialogflow::V2::Tool;
use Google::Cloud::Dialogflow::V2::SipTrunk;
use Google::Cloud::Dialogflow::V2::Document;
use Google::Cloud::Dialogflow::V2::ConversationDataset;
use Google::Cloud::Dialogflow::V2::SessionEntityType;
use Google::Cloud::Dialogflow::V2::Environment;
use Google::Cloud::Dialogflow::V2::Intent;
use Google::Cloud::Dialogflow::V2::CesApp;
use Google::Cloud::Dialogflow::V2::Toolset;
use Google::Cloud::Dialogflow::V2::CesTool;
use Google::Cloud::Dialogflow::V2::Session;
use Google::Cloud::Dialogflow::V2::CompanionAgent;
use Google::Cloud::Dialogflow::V2::Generator;
use Google::Cloud::Dialogflow::V2::Webhook;
use Google::Cloud::Dialogflow::V2::Participant;
use Google::Cloud::Dialogflow::V2::GeneratorEvaluation;
use Google::Cloud::Dialogflow::V2::ConversationProfile;
use Google::Cloud::Dialogflow::V2::AnswerRecord;
use Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent;
use Google::Cloud::Dialogflow::V2::ConversationEvent;
use Google::Cloud::Dialogflow::V2::Conversation;

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

sub list_environments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2.Environments/ListEnvironments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'ListEnvironments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_environment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2::Environment::Environment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2.Environments/UpdateEnvironment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2.Environments',
        method         => 'UpdateEnvironment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::V2::EnvironmentsClient

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::EnvironmentsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::EnvironmentsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::V2::EnvironmentsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::V2::EnvironmentsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::V2::EnvironmentsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/v2/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/agent_coaching_instruction.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/answer_record.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/ces_app.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/ces_tool.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/companion_agent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/context.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/conversation.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/conversation_dataset.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/conversation_event.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/conversation_model.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/conversation_profile.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/document.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/encryption_spec.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/generator_evaluation.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/grounding.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/human_agent_assistant_event.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/knowledge_base.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/operations.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/participant.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/session.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/sip_trunk.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/toolset.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/validation_result.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/version.proto>

=item * C<googleapis/google/cloud/dialogflow/v2/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::V2::EnvironmentsClient->new(
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

=item * B<list_environments>

    my $response = $client->list_environments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListEnvironments> on C<google.cloud.dialogflow.v2.Environments>.

Request: L<Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest>

Returns: L<Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_environment>

    my $response = $client->update_environment(
        environment              => $environment,
        update_mask              => $update_mask,
        allow_load_to_draft_and_discard_changes => $allow_load_to_draft_and_discard_changes,
    );

Calls the RPC method C<UpdateEnvironment> on C<google.cloud.dialogflow.v2.Environments>.

Request: L<Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest>

Returns: L<Google::Cloud::Dialogflow::V2::Environment::Environment>

Parameters:

=over 4

=item * C<environment> - L<Google::Cloud::Dialogflow::V2::Environment::Environment>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<allow_load_to_draft_and_discard_changes> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
