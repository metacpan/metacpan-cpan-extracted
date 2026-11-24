package Google::Cloud::Dialogflow::V2beta1::IntentsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dialogflow::V2beta1::ValidationResult;
use Google::Cloud::Dialogflow::V2beta1::Grounding;
use Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction;
use Google::Cloud::Dialogflow::V2beta1::Gcs;
use Google::Cloud::Dialogflow::V2beta1::Operations;
use Google::Cloud::Dialogflow::V2beta1::ToolCall;
use Google::Cloud::Dialogflow::V2beta1::KnowledgeBase;
use Google::Cloud::Dialogflow::V2beta1::Context;
use Google::Cloud::Dialogflow::V2beta1::Agent;
use Google::Cloud::Dialogflow::V2beta1::Fulfillment;
use Google::Cloud::Dialogflow::V2beta1::Version;
use Google::Cloud::Dialogflow::V2beta1::PhoneNumber;
use Google::Cloud::Dialogflow::V2beta1::AudioConfig;
use Google::Cloud::Dialogflow::V2beta1::Tool;
use Google::Cloud::Dialogflow::V2beta1::SipTrunk;
use Google::Cloud::Dialogflow::V2beta1::EncryptionSpec;
use Google::Cloud::Dialogflow::V2beta1::EntityType;
use Google::Cloud::Dialogflow::V2beta1::Document;
use Google::Cloud::Dialogflow::V2beta1::Intent;
use Google::Cloud::Dialogflow::V2beta1::Environment;
use Google::Cloud::Dialogflow::V2beta1::Toolset;
use Google::Cloud::Dialogflow::V2beta1::CesTool;
use Google::Cloud::Dialogflow::V2beta1::CesApp;
use Google::Cloud::Dialogflow::V2beta1::SessionEntityType;
use Google::Cloud::Dialogflow::V2beta1::CompanionAgent;
use Google::Cloud::Dialogflow::V2beta1::Generator;
use Google::Cloud::Dialogflow::V2beta1::Session;
use Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation;
use Google::Cloud::Dialogflow::V2beta1::Participant;
use Google::Cloud::Dialogflow::V2beta1::Webhook;
use Google::Cloud::Dialogflow::V2beta1::ConversationEvent;
use Google::Cloud::Dialogflow::V2beta1::ConversationProfile;
use Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent;
use Google::Cloud::Dialogflow::V2beta1::AnswerRecord;
use Google::Cloud::Dialogflow::V2beta1::Conversation;

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

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Intents/ListIntents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Intents',
        method         => 'ListIntents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_intent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Intent::UpdateIntentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Intent::Intent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Intents/UpdateIntent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Intents',
        method         => 'UpdateIntent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_delete_intents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Intent::BatchDeleteIntentsRequest';
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
            path           => '/google.cloud.dialogflow.v2beta1.Intents/BatchDeleteIntents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Intents',
        method         => 'BatchDeleteIntents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::V2beta1::IntentsClient

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::IntentsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::IntentsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::V2beta1::IntentsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::V2beta1::IntentsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::V2beta1::IntentsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dialogflow/v2beta1/agent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/agent_coaching_instruction.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/answer_record.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/audio_config.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/ces_app.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/ces_tool.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/companion_agent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/context.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/conversation.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/conversation_event.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/conversation_profile.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/document.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/encryption_spec.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/environment.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/fulfillment.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/gcs.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/generator.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/generator_evaluation.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/grounding.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/human_agent_assistant_event.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/intent.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/knowledge_base.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/operations.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/participant.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/phone_number.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/session.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/session_entity_type.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/sip_trunk.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/tool.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/tool_call.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/toolset.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/validation_result.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/version.proto>

=item * C<googleapis/google/cloud/dialogflow/v2beta1/webhook.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dialogflow::V2beta1::IntentsClient->new(
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

Calls the RPC method C<ListIntents> on C<google.cloud.dialogflow.v2beta1.Intents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<intent_view> - L<Google::Cloud::Dialogflow::V2beta1::Intent::IntentView>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_intent>

    my $response = $client->update_intent(
        intent                   => $intent,
        language_code            => $language_code,
        update_mask              => $update_mask,
        intent_view              => $intent_view,
    );

Calls the RPC method C<UpdateIntent> on C<google.cloud.dialogflow.v2beta1.Intents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Intent::UpdateIntentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Intent::Intent>

Parameters:

=over 4

=item * C<intent> - L<Google::Cloud::Dialogflow::V2beta1::Intent::Intent>

=item * C<language_code> - C<string>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<intent_view> - L<Google::Cloud::Dialogflow::V2beta1::Intent::IntentView>

=back

=item * B<batch_delete_intents>

    my $response = $client->batch_delete_intents(
        parent                   => $parent,
        intents                  => [ ... ],
    );

Calls the RPC method C<BatchDeleteIntents> on C<google.cloud.dialogflow.v2beta1.Intents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Intent::BatchDeleteIntentsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<intents> - ArrayRef of L<Google::Cloud::Dialogflow::V2beta1::Intent::Intent>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
