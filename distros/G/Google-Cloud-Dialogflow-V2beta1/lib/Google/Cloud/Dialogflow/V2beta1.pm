package Google::Cloud::Dialogflow::V2beta1;

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
use Google::Cloud::Dialogflow::V2beta1::Operations;
use Google::Cloud::Dialogflow::V2beta1::Gcs;
use Google::Cloud::Dialogflow::V2beta1::Grounding;
use Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction;
use Google::Cloud::Dialogflow::V2beta1::ToolCall;
use Google::Cloud::Dialogflow::V2beta1::AudioConfig;
use Google::Cloud::Dialogflow::V2beta1::PhoneNumber;
use Google::Cloud::Dialogflow::V2beta1::Version;
use Google::Cloud::Dialogflow::V2beta1::Fulfillment;
use Google::Cloud::Dialogflow::V2beta1::Context;
use Google::Cloud::Dialogflow::V2beta1::KnowledgeBase;
use Google::Cloud::Dialogflow::V2beta1::SipTrunk;
use Google::Cloud::Dialogflow::V2beta1::Tool;
use Google::Cloud::Dialogflow::V2beta1::Agent;
use Google::Cloud::Dialogflow::V2beta1::EntityType;
use Google::Cloud::Dialogflow::V2beta1::EncryptionSpec;
use Google::Cloud::Dialogflow::V2beta1::Document;
use Google::Cloud::Dialogflow::V2beta1::Environment;
use Google::Cloud::Dialogflow::V2beta1::Intent;
use Google::Cloud::Dialogflow::V2beta1::Toolset;
use Google::Cloud::Dialogflow::V2beta1::CesApp;
use Google::Cloud::Dialogflow::V2beta1::CesTool;
use Google::Cloud::Dialogflow::V2beta1::SessionEntityType;
use Google::Cloud::Dialogflow::V2beta1::CompanionAgent;
use Google::Cloud::Dialogflow::V2beta1::Generator;
use Google::Cloud::Dialogflow::V2beta1::Session;
use Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation;
use Google::Cloud::Dialogflow::V2beta1::Participant;
use Google::Cloud::Dialogflow::V2beta1::Webhook;
use Google::Cloud::Dialogflow::V2beta1::ConversationEvent;
use Google::Cloud::Dialogflow::V2beta1::AnswerRecord;
use Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent;
use Google::Cloud::Dialogflow::V2beta1::ConversationProfile;
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

sub get_agent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Agent::Agent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Agents/GetAgent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Agents',
        method         => 'GetAgent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_answer_record {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.AnswerRecords/GetAnswerRecord',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.AnswerRecords',
        method         => 'GetAnswerRecord',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_companion_agent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.CompanionAgents/CreateCompanionAgent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.CompanionAgents',
        method         => 'CreateCompanionAgent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_contexts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Contexts/ListContexts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Contexts',
        method         => 'ListContexts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_conversation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Conversation::CreateConversationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Conversations/CreateConversation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Conversations',
        method         => 'CreateConversation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_conversation_profiles {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.ConversationProfiles/ListConversationProfiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.ConversationProfiles',
        method         => 'ListConversationProfiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_documents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Documents/ListDocuments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Documents',
        method         => 'ListDocuments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_encryption_spec {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.EncryptionSpecService/GetEncryptionSpec',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.EncryptionSpecService',
        method         => 'GetEncryptionSpec',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub initialize_encryption_spec {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest';
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
            path           => '/google.cloud.dialogflow.v2beta1.EncryptionSpecService/InitializeEncryptionSpec',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.EncryptionSpecService',
        method         => 'InitializeEncryptionSpec',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_entity_types {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.EntityTypes/ListEntityTypes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.EntityTypes',
        method         => 'ListEntityTypes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_entity_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.EntityTypes/UpdateEntityType',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.EntityTypes',
        method         => 'UpdateEntityType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_delete_entity_types {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest';
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
            path           => '/google.cloud.dialogflow.v2beta1.EntityTypes/BatchDeleteEntityTypes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.EntityTypes',
        method         => 'BatchDeleteEntityTypes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_environments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Environments/ListEnvironments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'ListEnvironments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_environment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Environments/UpdateEnvironment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Environments',
        method         => 'UpdateEnvironment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_fulfillment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Fulfillments/GetFulfillment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Fulfillments',
        method         => 'GetFulfillment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_generator {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Generator::Generator';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Generators/CreateGenerator',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Generators',
        method         => 'CreateGenerator',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_generator_evaluation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation::CreateGeneratorEvaluationRequest';
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
            path           => '/google.cloud.dialogflow.v2beta1.GeneratorEvaluations/CreateGeneratorEvaluation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.GeneratorEvaluations',
        method         => 'CreateGeneratorEvaluation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
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

sub list_knowledge_bases {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.KnowledgeBases/ListKnowledgeBases',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'ListKnowledgeBases',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_knowledge_base {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.KnowledgeBases/GetKnowledgeBase',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'GetKnowledgeBase',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_knowledge_base {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.KnowledgeBases/DeleteKnowledgeBase',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.KnowledgeBases',
        method         => 'DeleteKnowledgeBase',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_participant {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Participant::CreateParticipantRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Participant::Participant';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Participants/CreateParticipant',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Participants',
        method         => 'CreateParticipant',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_phone_numbers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.PhoneNumbers/ListPhoneNumbers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.PhoneNumbers',
        method         => 'ListPhoneNumbers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detect_intent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Sessions/DetectIntent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Sessions',
        method         => 'DetectIntent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub streaming_detect_intent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Sessions/StreamingDetectIntent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Sessions',
        method         => 'StreamingDetectIntent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_session_entity_types {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.SessionEntityTypes/ListSessionEntityTypes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.SessionEntityTypes',
        method         => 'ListSessionEntityTypes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_sip_trunk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.SipTrunks/CreateSipTrunk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'CreateSipTrunk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Tools/CreateTool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Tools',
        method         => 'CreateTool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Versions/ListVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'ListVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_version {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dialogflow::V2beta1::Version::Version';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dialogflow.v2beta1.Versions/UpdateVersion',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dialogflow.v2beta1.Versions',
        method         => 'UpdateVersion',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dialogflow::V2beta1

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dialogflow::V2beta1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dialogflow::V2beta1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dialogflow::V2beta1> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Dialogflow::V2beta1->new(
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

=item * B<get_agent>

    my $response = $client->get_agent(
        parent                   => $parent,
    );

Calls the RPC method C<GetAgent> on C<google.cloud.dialogflow.v2beta1.Agents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Agent::Agent>

Parameters:

=over 4

=item * C<parent> - C<string>

=back

=item * B<get_answer_record>

    my $response = $client->get_answer_record(
        name                     => $name,
    );

Calls the RPC method C<GetAnswerRecord> on C<google.cloud.dialogflow.v2beta1.AnswerRecords>.

Request: L<Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_companion_agent>

    my $response = $client->create_companion_agent(
        parent                   => $parent,
        companion_agent          => $companion_agent,
        companion_agent_id       => $companion_agent_id,
    );

Calls the RPC method C<CreateCompanionAgent> on C<google.cloud.dialogflow.v2beta1.CompanionAgents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<companion_agent> - L<Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent>

=item * C<companion_agent_id> - C<string>

=back

=item * B<list_contexts>

    my $response = $client->list_contexts(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListContexts> on C<google.cloud.dialogflow.v2beta1.Contexts>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_conversation>

    my $response = $client->create_conversation(
        parent                   => $parent,
        conversation             => $conversation,
        conversation_id          => $conversation_id,
    );

Calls the RPC method C<CreateConversation> on C<google.cloud.dialogflow.v2beta1.Conversations>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Conversation::CreateConversationRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<conversation> - L<Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation>

=item * C<conversation_id> - C<string>

=back

=item * B<list_conversation_profiles>

    my $response = $client->list_conversation_profiles(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListConversationProfiles> on C<google.cloud.dialogflow.v2beta1.ConversationProfiles>.

Request: L<Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_documents>

    my $response = $client->list_documents(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListDocuments> on C<google.cloud.dialogflow.v2beta1.Documents>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<get_encryption_spec>

    my $response = $client->get_encryption_spec(
        name                     => $name,
    );

Calls the RPC method C<GetEncryptionSpec> on C<google.cloud.dialogflow.v2beta1.EncryptionSpecService>.

Request: L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<initialize_encryption_spec>

    my $response = $client->initialize_encryption_spec(
        encryption_spec          => $encryption_spec,
    );

Calls the RPC method C<InitializeEncryptionSpec> on C<google.cloud.dialogflow.v2beta1.EncryptionSpecService>.

Request: L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<encryption_spec> - L<Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec>

=back

=item * B<list_entity_types>

    my $response = $client->list_entity_types(
        parent                   => $parent,
        language_code            => $language_code,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListEntityTypes> on C<google.cloud.dialogflow.v2beta1.EntityTypes>.

Request: L<Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<language_code> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_entity_type>

    my $response = $client->update_entity_type(
        entity_type              => $entity_type,
        language_code            => $language_code,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateEntityType> on C<google.cloud.dialogflow.v2beta1.EntityTypes>.

Request: L<Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType>

Parameters:

=over 4

=item * C<entity_type> - L<Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType>

=item * C<language_code> - C<string>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<batch_delete_entity_types>

    my $response = $client->batch_delete_entity_types(
        parent                   => $parent,
        entity_type_names        => [ ... ],
    );

Calls the RPC method C<BatchDeleteEntityTypes> on C<google.cloud.dialogflow.v2beta1.EntityTypes>.

Request: L<Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<entity_type_names> - ArrayRef of C<string>

=back

=item * B<list_environments>

    my $response = $client->list_environments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListEnvironments> on C<google.cloud.dialogflow.v2beta1.Environments>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse>

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

Calls the RPC method C<UpdateEnvironment> on C<google.cloud.dialogflow.v2beta1.Environments>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Environment::Environment>

Parameters:

=over 4

=item * C<environment> - L<Google::Cloud::Dialogflow::V2beta1::Environment::Environment>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<allow_load_to_draft_and_discard_changes> - C<bool>

=back

=item * B<get_fulfillment>

    my $response = $client->get_fulfillment(
        name                     => $name,
    );

Calls the RPC method C<GetFulfillment> on C<google.cloud.dialogflow.v2beta1.Fulfillments>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_generator>

    my $response = $client->create_generator(
        parent                   => $parent,
        generator                => $generator,
        generator_id             => $generator_id,
    );

Calls the RPC method C<CreateGenerator> on C<google.cloud.dialogflow.v2beta1.Generators>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Generator::Generator>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<generator> - L<Google::Cloud::Dialogflow::V2beta1::Generator::Generator>

=item * C<generator_id> - C<string>

=back

=item * B<create_generator_evaluation>

    my $response = $client->create_generator_evaluation(
        parent                   => $parent,
        generator_evaluation     => $generator_evaluation,
    );

Calls the RPC method C<CreateGeneratorEvaluation> on C<google.cloud.dialogflow.v2beta1.GeneratorEvaluations>.

Request: L<Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation::CreateGeneratorEvaluationRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<generator_evaluation> - L<Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation::GeneratorEvaluation>

=back

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

=item * B<list_knowledge_bases>

    my $response = $client->list_knowledge_bases(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListKnowledgeBases> on C<google.cloud.dialogflow.v2beta1.KnowledgeBases>.

Request: L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<get_knowledge_base>

    my $response = $client->get_knowledge_base(
        name                     => $name,
    );

Calls the RPC method C<GetKnowledgeBase> on C<google.cloud.dialogflow.v2beta1.KnowledgeBases>.

Request: L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_knowledge_base>

    my $response = $client->delete_knowledge_base(
        name                     => $name,
        force                    => $force,
    );

Calls the RPC method C<DeleteKnowledgeBase> on C<google.cloud.dialogflow.v2beta1.KnowledgeBases>.

Request: L<Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<force> - C<bool>

=back

=item * B<create_participant>

    my $response = $client->create_participant(
        parent                   => $parent,
        participant              => $participant,
    );

Calls the RPC method C<CreateParticipant> on C<google.cloud.dialogflow.v2beta1.Participants>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Participant::CreateParticipantRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Participant::Participant>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<participant> - L<Google::Cloud::Dialogflow::V2beta1::Participant::Participant>

=back

=item * B<list_phone_numbers>

    my $response = $client->list_phone_numbers(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        show_deleted             => $show_deleted,
    );

Calls the RPC method C<ListPhoneNumbers> on C<google.cloud.dialogflow.v2beta1.PhoneNumbers>.

Request: L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<show_deleted> - C<bool>

=back

=item * B<detect_intent>

    my $response = $client->detect_intent(
        session                  => $session,
        query_params             => $query_params,
        query_input              => $query_input,
        output_audio_config      => $output_audio_config,
        output_audio_config_mask => $output_audio_config_mask,
        input_audio              => $input_audio,
    );

Calls the RPC method C<DetectIntent> on C<google.cloud.dialogflow.v2beta1.Sessions>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse>

Parameters:

=over 4

=item * C<session> - C<string>

=item * C<query_params> - L<Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters>

=item * C<query_input> - L<Google::Cloud::Dialogflow::V2beta1::Session::QueryInput>

=item * C<output_audio_config> - L<Google::Cloud::Dialogflow::V2beta1::AudioConfig::OutputAudioConfig>

=item * C<output_audio_config_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<input_audio> - C<bytes>

=back

=item * B<streaming_detect_intent>

    my $response = $client->streaming_detect_intent(
        session                  => $session,
        query_params             => $query_params,
        query_input              => $query_input,
        single_utterance         => $single_utterance,
        output_audio_config      => $output_audio_config,
        output_audio_config_mask => $output_audio_config_mask,
        input_audio              => $input_audio,
        enable_debugging_info    => $enable_debugging_info,
    );

Calls the RPC method C<StreamingDetectIntent> on C<google.cloud.dialogflow.v2beta1.Sessions>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse>

Parameters:

=over 4

=item * C<session> - C<string>

=item * C<query_params> - L<Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters>

=item * C<query_input> - L<Google::Cloud::Dialogflow::V2beta1::Session::QueryInput>

=item * C<single_utterance> - C<bool>

=item * C<output_audio_config> - L<Google::Cloud::Dialogflow::V2beta1::AudioConfig::OutputAudioConfig>

=item * C<output_audio_config_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<input_audio> - C<bytes>

=item * C<enable_debugging_info> - C<bool>

=back

=item * B<list_session_entity_types>

    my $response = $client->list_session_entity_types(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSessionEntityTypes> on C<google.cloud.dialogflow.v2beta1.SessionEntityTypes>.

Request: L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_sip_trunk>

    my $response = $client->create_sip_trunk(
        parent                   => $parent,
        sip_trunk                => $sip_trunk,
    );

Calls the RPC method C<CreateSipTrunk> on C<google.cloud.dialogflow.v2beta1.SipTrunks>.

Request: L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<sip_trunk> - L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk>

=back

=item * B<create_tool>

    my $response = $client->create_tool(
        parent                   => $parent,
        tool                     => $tool,
        tool_id                  => $tool_id,
    );

Calls the RPC method C<CreateTool> on C<google.cloud.dialogflow.v2beta1.Tools>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Tool::Tool>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<tool> - L<Google::Cloud::Dialogflow::V2beta1::Tool::Tool>

=item * C<tool_id> - C<string>

=back

=item * B<list_versions>

    my $response = $client->list_versions(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListVersions> on C<google.cloud.dialogflow.v2beta1.Versions>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_version>

    my $response = $client->update_version(
        version                  => $version,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateVersion> on C<google.cloud.dialogflow.v2beta1.Versions>.

Request: L<Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest>

Returns: L<Google::Cloud::Dialogflow::V2beta1::Version::Version>

Parameters:

=over 4

=item * C<version> - L<Google::Cloud::Dialogflow::V2beta1::Version::Version>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
