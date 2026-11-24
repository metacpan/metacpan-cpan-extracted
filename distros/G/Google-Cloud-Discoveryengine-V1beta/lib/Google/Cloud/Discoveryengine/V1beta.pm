package Google::Cloud::Discoveryengine::V1beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1beta::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1beta::Completion;
use Google::Cloud::Discoveryengine::V1beta::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1beta::Logging;
use Google::Cloud::Discoveryengine::V1beta::Schema;
use Google::Cloud::Discoveryengine::V1beta::Assistant;
use Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting;
use Google::Cloud::Discoveryengine::V1beta::CmekConfigService;
use Google::Cloud::Discoveryengine::V1beta::Common;
use Google::Cloud::Discoveryengine::V1beta::Chunk;
use Google::Cloud::Discoveryengine::V1beta::RankService;
use Google::Cloud::Discoveryengine::V1beta::UserLicense;
use Google::Cloud::Discoveryengine::V1beta::Grounding;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1beta::SampleQuery;
use Google::Cloud::Discoveryengine::V1beta::UserStore;
use Google::Cloud::Discoveryengine::V1beta::Safety;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1beta::Project;
use Google::Cloud::Discoveryengine::V1beta::SchemaService;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfig;
use Google::Cloud::Discoveryengine::V1beta::Engine;
use Google::Cloud::Discoveryengine::V1beta::DataStore;
use Google::Cloud::Discoveryengine::V1beta::Document;
use Google::Cloud::Discoveryengine::V1beta::Control;
use Google::Cloud::Discoveryengine::V1beta::AclConfig;
use Google::Cloud::Discoveryengine::V1beta::UserLicenseService;
use Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1beta::UserStoreService;
use Google::Cloud::Discoveryengine::V1beta::Answer;
use Google::Cloud::Discoveryengine::V1beta::ProjectService;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfigService;
use Google::Cloud::Discoveryengine::V1beta::EngineService;
use Google::Cloud::Discoveryengine::V1beta::DataStoreService;
use Google::Cloud::Discoveryengine::V1beta::SearchService;
use Google::Cloud::Discoveryengine::V1beta::ControlService;
use Google::Cloud::Discoveryengine::V1beta::AclConfigService;
use Google::Cloud::Discoveryengine::V1beta::AssistAnswer;
use Google::Cloud::Discoveryengine::V1beta::Evaluation;
use Google::Cloud::Discoveryengine::V1beta::Conversation;
use Google::Cloud::Discoveryengine::V1beta::ServingConfig;
use Google::Cloud::Discoveryengine::V1beta::Session;
use Google::Cloud::Discoveryengine::V1beta::EvaluationService;
use Google::Cloud::Discoveryengine::V1beta::ServingConfigService;
use Google::Cloud::Discoveryengine::V1beta::Feedback;
use Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1beta::AssistantService;
use Google::Cloud::Discoveryengine::V1beta::UserEvent;
use Google::Cloud::Discoveryengine::V1beta::SessionService;
use Google::Cloud::Discoveryengine::V1beta::ImportConfig;
use Google::Cloud::Discoveryengine::V1beta::RecommendationService;
use Google::Cloud::Discoveryengine::V1beta::PurgeConfig;
use Google::Cloud::Discoveryengine::V1beta::SearchTuningService;
use Google::Cloud::Discoveryengine::V1beta::SampleQueryService;
use Google::Cloud::Discoveryengine::V1beta::UserEventService;
use Google::Cloud::Discoveryengine::V1beta::DocumentService;
use Google::Cloud::Discoveryengine::V1beta::CompletionService;

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

    my $target = 'discoveryengine.googleapis.com:443';
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

sub update_acl_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.AclConfigService/UpdateAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_acl_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.AclConfigService/GetAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.AclConfigService',
        method         => 'GetAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_assist {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.AssistantService/StreamAssist',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.AssistantService',
        method         => 'StreamAssist',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cmek_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.CmekConfigService/UpdateCmekConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.CmekConfigService',
        method         => 'UpdateCmekConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub complete_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.CompletionService/CompleteQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.CompletionService',
        method         => 'CompleteQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub import_suggestion_deny_list_entries {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportSuggestionDenyListEntriesRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.CompletionService/ImportSuggestionDenyListEntries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.CompletionService',
        method         => 'ImportSuggestionDenyListEntries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_control {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::Control::Control';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.ControlService/CreateControl',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'CreateControl',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub converse_conversation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.ConversationalSearchService/ConverseConversation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.ConversationalSearchService',
        method         => 'ConverseConversation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_data_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.DataStoreService/CreateDataStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'CreateDataStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::Document::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.DocumentService/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.DocumentService',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.EngineService/CreateEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.EngineService',
        method         => 'CreateEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_evaluation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.EvaluationService/GetEvaluation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.EvaluationService',
        method         => 'GetEvaluation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_grounded_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.GroundedGenerationService/StreamGenerateGroundedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.GroundedGenerationService',
        method         => 'StreamGenerateGroundedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_identity_mapping_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.IdentityMappingStoreService/CreateIdentityMappingStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.IdentityMappingStoreService',
        method         => 'CreateIdentityMappingStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_license_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.LicenseConfigService/CreateLicenseConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.LicenseConfigService',
        method         => 'CreateLicenseConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub provision_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.ProjectService/ProvisionProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.ProjectService',
        method         => 'ProvisionProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rank {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.RankService/Rank',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.RankService',
        method         => 'Rank',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recommend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.RecommendationService/Recommend',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.RecommendationService',
        method         => 'Recommend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_sample_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SampleQueryService/GetSampleQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQueryService',
        method         => 'GetSampleQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_sample_query_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SampleQuerySetService/GetSampleQuerySet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SampleQuerySetService',
        method         => 'GetSampleQuerySet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_schema {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::Schema::Schema';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SchemaService/GetSchema',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SchemaService',
        method         => 'GetSchema',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub train_custom_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.SearchTuningService/TrainCustomModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_serving_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.ServingConfigService/CreateServingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::Session::Session';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SessionService/CreateSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SessionService',
        method         => 'CreateSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_site_search_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::GetSiteSearchEngineRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.SiteSearchEngineService/GetSiteSearchEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService',
        method         => 'GetSiteSearchEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_create_target_sites {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::BatchCreateTargetSitesRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.SiteSearchEngineService/BatchCreateTargetSites',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService',
        method         => 'BatchCreateTargetSites',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_sitemap {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::CreateSitemapRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.SiteSearchEngineService/CreateSitemap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService',
        method         => 'CreateSitemap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_advanced_site_search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::EnableAdvancedSiteSearchRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.SiteSearchEngineService/EnableAdvancedSiteSearch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService',
        method         => 'EnableAdvancedSiteSearch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recrawl_uris {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::RecrawlUrisRequest';
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
            path           => '/google.cloud.discoveryengine.v1beta.SiteSearchEngineService/RecrawlUris',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.SiteSearchEngineService',
        method         => 'RecrawlUris',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub write_user_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.UserEventService/WriteUserEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserEventService',
        method         => 'WriteUserEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_user_licenses {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.UserLicenseService/ListUserLicenses',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserLicenseService',
        method         => 'ListUserLicenses',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_user_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1beta.UserStoreService/GetUserStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserStoreService',
        method         => 'GetUserStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Discoveryengine::V1beta

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/discoveryengine/v1beta/acl_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/acl_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/agent_gateway_setting.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/answer.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/assist_answer.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/assistant.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/assistant_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/chunk.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/cmek_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/common.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/completion.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/completion_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/control.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/control_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/conversation.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/conversational_search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/custom_tuning_model.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/data_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/data_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/document.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/document_processing_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/document_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/evaluation.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/evaluation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/feedback.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/grounded_generation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/grounding.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/identity_mapping_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/identity_mapping_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/import_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/license_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/license_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/logging.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/project.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/project_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/purge_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/rank_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/recommendation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/safety.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/sample_query.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/sample_query_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/sample_query_set.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/sample_query_set_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/schema.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/schema_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/search_tuning_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/serving_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/serving_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/session.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/session_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/site_search_engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/site_search_engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_event.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_event_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_license.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_license_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1beta/user_store_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Discoveryengine::V1beta->new(
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

=item * B<update_acl_config>

    my $response = $client->update_acl_config(
        acl_config               => $acl_config,
    );

Calls the RPC method C<UpdateAclConfig> on C<google.cloud.discoveryengine.v1beta.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::AclConfigService::UpdateAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig>

Parameters:

=over 4

=item * C<acl_config> - L<Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig>

=back

=item * B<get_acl_config>

    my $response = $client->get_acl_config(
        name                     => $name,
    );

Calls the RPC method C<GetAclConfig> on C<google.cloud.discoveryengine.v1beta.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::AclConfigService::GetAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::AclConfig::AclConfig>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<stream_assist>

    my $response = $client->stream_assist(
        name                     => $name,
        query                    => $query,
        session                  => $session,
        user_metadata            => $user_metadata,
        agents_spec              => $agents_spec,
        tools_spec               => $tools_spec,
        generation_spec          => $generation_spec,
    );

Calls the RPC method C<StreamAssist> on C<google.cloud.discoveryengine.v1beta.AssistantService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::AssistantService::StreamAssistResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - L<Google::Cloud::Discoveryengine::V1beta::Session::Query>

=item * C<session> - C<string>

=item * C<user_metadata> - L<Google::Cloud::Discoveryengine::V1beta::AssistantService::AssistUserMetadata>

=item * C<agents_spec> - L<Google::Cloud::Discoveryengine::V1beta::AssistantService::AgentsSpec>

=item * C<tools_spec> - L<Google::Cloud::Discoveryengine::V1beta::AssistantService::ToolsSpec>

=item * C<generation_spec> - L<Google::Cloud::Discoveryengine::V1beta::AssistantService::GenerationSpec>

=back

=item * B<update_cmek_config>

    my $response = $client->update_cmek_config(
        config                   => $config,
        set_default              => $set_default,
    );

Calls the RPC method C<UpdateCmekConfig> on C<google.cloud.discoveryengine.v1beta.CmekConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::UpdateCmekConfigRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<config> - L<Google::Cloud::Discoveryengine::V1beta::CmekConfigService::CmekConfig>

=item * C<set_default> - C<bool>

=back

=item * B<complete_query>

    my $response = $client->complete_query(
        data_store               => $data_store,
        query                    => $query,
        query_model              => $query_model,
        user_pseudo_id           => $user_pseudo_id,
        include_tail_suggestions => $include_tail_suggestions,
    );

Calls the RPC method C<CompleteQuery> on C<google.cloud.discoveryengine.v1beta.CompletionService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::CompletionService::CompleteQueryResponse>

Parameters:

=over 4

=item * C<data_store> - C<string>

=item * C<query> - C<string>

=item * C<query_model> - C<string>

=item * C<user_pseudo_id> - C<string>

=item * C<include_tail_suggestions> - C<bool>

=back

=item * B<import_suggestion_deny_list_entries>

    my $response = $client->import_suggestion_deny_list_entries(
        parent                   => $parent,
    );

Calls the RPC method C<ImportSuggestionDenyListEntries> on C<google.cloud.discoveryengine.v1beta.CompletionService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportSuggestionDenyListEntriesRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=back

=item * B<create_control>

    my $response = $client->create_control(
        parent                   => $parent,
        control                  => $control,
        control_id               => $control_id,
    );

Calls the RPC method C<CreateControl> on C<google.cloud.discoveryengine.v1beta.ControlService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Discoveryengine::V1beta::Control::Control>

=item * C<control_id> - C<string>

=back

=item * B<converse_conversation>

    my $response = $client->converse_conversation(
        name                     => $name,
        query                    => $query,
        serving_config           => $serving_config,
        conversation             => $conversation,
        safe_search              => $safe_search,
        user_labels              => { ... },
        summary_spec             => $summary_spec,
        filter                   => $filter,
        boost_spec               => $boost_spec,
    );

Calls the RPC method C<ConverseConversation> on C<google.cloud.discoveryengine.v1beta.ConversationalSearchService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - L<Google::Cloud::Discoveryengine::V1beta::Conversation::TextInput>

=item * C<serving_config> - C<string>

=item * C<conversation> - L<Google::Cloud::Discoveryengine::V1beta::Conversation::Conversation>

=item * C<safe_search> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<summary_spec> - L<SearchRequest::ContentSearchSpec::SummarySpec::SummarySpec>

=item * C<filter> - C<string>

=item * C<boost_spec> - L<SearchRequest::BoostSpec::BoostSpec>

=back

=item * B<create_data_store>

    my $response = $client->create_data_store(
        parent                   => $parent,
        data_store               => $data_store,
        data_store_id            => $data_store_id,
        create_advanced_site_search => $create_advanced_site_search,
        skip_default_schema_creation => $skip_default_schema_creation,
    );

Calls the RPC method C<CreateDataStore> on C<google.cloud.discoveryengine.v1beta.DataStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<data_store> - L<Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore>

=item * C<data_store_id> - C<string>

=item * C<create_advanced_site_search> - C<bool>

=item * C<skip_default_schema_creation> - C<bool>

=back

=item * B<get_document>

    my $response = $client->get_document(
        name                     => $name,
    );

Calls the RPC method C<GetDocument> on C<google.cloud.discoveryengine.v1beta.DocumentService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::DocumentService::GetDocumentRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::Document::Document>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_engine>

    my $response = $client->create_engine(
        parent                   => $parent,
        engine                   => $engine,
        engine_id                => $engine_id,
    );

Calls the RPC method C<CreateEngine> on C<google.cloud.discoveryengine.v1beta.EngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::EngineService::CreateEngineRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<engine> - L<Google::Cloud::Discoveryengine::V1beta::Engine::Engine>

=item * C<engine_id> - C<string>

=back

=item * B<get_evaluation>

    my $response = $client->get_evaluation(
        name                     => $name,
    );

Calls the RPC method C<GetEvaluation> on C<google.cloud.discoveryengine.v1beta.EvaluationService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::EvaluationService::GetEvaluationRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::Evaluation::Evaluation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<stream_generate_grounded_content>

    my $response = $client->stream_generate_grounded_content(
        location                 => $location,
        system_instruction       => $system_instruction,
        contents                 => [ ... ],
        generation_spec          => $generation_spec,
        grounding_spec           => $grounding_spec,
        user_labels              => { ... },
    );

Calls the RPC method C<StreamGenerateGroundedContent> on C<google.cloud.discoveryengine.v1beta.GroundedGenerationService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerateGroundedContentResponse>

Parameters:

=over 4

=item * C<location> - C<string>

=item * C<system_instruction> - L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent>

=item * C<contents> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundedGenerationContent>

=item * C<generation_spec> - L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GenerationSpec>

=item * C<grounding_spec> - L<Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService::GroundingSpec>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<create_identity_mapping_store>

    my $response = $client->create_identity_mapping_store(
        parent                   => $parent,
        identity_mapping_store_id => $identity_mapping_store_id,
        identity_mapping_store   => $identity_mapping_store,
    );

Calls the RPC method C<CreateIdentityMappingStore> on C<google.cloud.discoveryengine.v1beta.IdentityMappingStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService::CreateIdentityMappingStoreRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<identity_mapping_store_id> - C<string>

=item * C<identity_mapping_store> - L<Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore::IdentityMappingStore>

=back

=item * B<create_license_config>

    my $response = $client->create_license_config(
        parent                   => $parent,
        license_config           => $license_config,
        license_config_id        => $license_config_id,
    );

Calls the RPC method C<CreateLicenseConfig> on C<google.cloud.discoveryengine.v1beta.LicenseConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::LicenseConfigService::CreateLicenseConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<license_config> - L<Google::Cloud::Discoveryengine::V1beta::LicenseConfig::LicenseConfig>

=item * C<license_config_id> - C<string>

=back

=item * B<provision_project>

    my $response = $client->provision_project(
        name                     => $name,
        accept_data_use_terms    => $accept_data_use_terms,
        data_use_terms_version   => $data_use_terms_version,
        saas_params              => $saas_params,
        provision_intent         => $provision_intent,
        idp_config               => $idp_config,
        pre_provision_mode       => $pre_provision_mode,
    );

Calls the RPC method C<ProvisionProject> on C<google.cloud.discoveryengine.v1beta.ProjectService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<accept_data_use_terms> - C<bool>

=item * C<data_use_terms_version> - C<string>

=item * C<saas_params> - L<Google::Cloud::Discoveryengine::V1beta::ProjectService::SaasParams>

=item * C<provision_intent> - L<Google::Cloud::Discoveryengine::V1beta::ProjectService::ProvisionIntent>

=item * C<idp_config> - L<Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig>

=item * C<pre_provision_mode> - C<bool>

=back

=item * B<rank>

    my $response = $client->rank(
        ranking_config           => $ranking_config,
        model                    => $model,
        top_n                    => $top_n,
        query                    => $query,
        records                  => [ ... ],
        ignore_record_details_in_response => $ignore_record_details_in_response,
        user_labels              => { ... },
    );

Calls the RPC method C<Rank> on C<google.cloud.discoveryengine.v1beta.RankService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::RankService::RankRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::RankService::RankResponse>

Parameters:

=over 4

=item * C<ranking_config> - C<string>

=item * C<model> - C<string>

=item * C<top_n> - C<int32>

=item * C<query> - C<string>

=item * C<records> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::RankService::RankingRecord>

=item * C<ignore_record_details_in_response> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<recommend>

    my $response = $client->recommend(
        serving_config           => $serving_config,
        user_event               => $user_event,
        page_size                => $page_size,
        filter                   => $filter,
        validate_only            => $validate_only,
        params                   => { ... },
        user_labels              => { ... },
    );

Calls the RPC method C<Recommend> on C<google.cloud.discoveryengine.v1beta.RecommendationService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::RecommendationService::RecommendResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent>

=item * C<page_size> - C<int32>

=item * C<filter> - C<string>

=item * C<validate_only> - C<bool>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<get_sample_query>

    my $response = $client->get_sample_query(
        name                     => $name,
    );

Calls the RPC method C<GetSampleQuery> on C<google.cloud.discoveryengine.v1beta.SampleQueryService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SampleQueryService::GetSampleQueryRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::SampleQuery::SampleQuery>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_sample_query_set>

    my $response = $client->get_sample_query_set(
        name                     => $name,
    );

Calls the RPC method C<GetSampleQuerySet> on C<google.cloud.discoveryengine.v1beta.SampleQuerySetService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService::GetSampleQuerySetRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::SampleQuerySet::SampleQuerySet>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_schema>

    my $response = $client->get_schema(
        name                     => $name,
    );

Calls the RPC method C<GetSchema> on C<google.cloud.discoveryengine.v1beta.SchemaService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SchemaService::GetSchemaRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::Schema::Schema>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search>

    my $response = $client->search(
        serving_config           => $serving_config,
        branch                   => $branch,
        query                    => $query,
        page_categories          => [ ... ],
        image_query              => $image_query,
        page_size                => $page_size,
        page_token               => $page_token,
        offset                   => $offset,
        one_box_page_size        => $one_box_page_size,
        data_store_specs         => [ ... ],
        num_results_per_data_store => $num_results_per_data_store,
        filter                   => $filter,
        canonical_filter         => $canonical_filter,
        order_by                 => $order_by,
        user_info                => $user_info,
        language_code            => $language_code,
        region_code              => $region_code,
        facet_specs              => [ ... ],
        boost_spec               => $boost_spec,
        params                   => { ... },
        query_expansion_spec     => $query_expansion_spec,
        spell_correction_spec    => $spell_correction_spec,
        user_pseudo_id           => $user_pseudo_id,
        content_search_spec      => $content_search_spec,
        embedding_spec           => $embedding_spec,
        ranking_expression       => $ranking_expression,
        ranking_expression_backend => $ranking_expression_backend,
        safe_search              => $safe_search,
        user_labels              => { ... },
        search_as_you_type_spec  => $search_as_you_type_spec,
        display_spec             => $display_spec,
        crowding_specs           => [ ... ],
        session                  => $session,
        session_spec             => $session_spec,
        relevance_threshold      => $relevance_threshold,
        relevance_filter_spec    => $relevance_filter_spec,
        personalization_spec     => $personalization_spec,
        relevance_score_spec     => $relevance_score_spec,
        search_addon_spec        => $search_addon_spec,
        custom_ranking_params    => $custom_ranking_params,
        entity                   => $entity,
    );

Calls the RPC method C<Search> on C<google.cloud.discoveryengine.v1beta.SearchService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SearchService::SearchRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<image_query> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::ImageQuery>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<one_box_page_size> - C<int32>

=item * C<data_store_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::SearchService::DataStoreSpec>

=item * C<num_results_per_data_store> - C<int32>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<user_info> - L<Google::Cloud::Discoveryengine::V1beta::Common::UserInfo>

=item * C<language_code> - C<string>

=item * C<region_code> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::SearchService::FacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::BoostSpec>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<query_expansion_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::QueryExpansionSpec>

=item * C<spell_correction_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::SpellCorrectionSpec>

=item * C<user_pseudo_id> - C<string>

=item * C<content_search_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::ContentSearchSpec>

=item * C<embedding_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::EmbeddingSpec>

=item * C<ranking_expression> - C<string>

=item * C<ranking_expression_backend> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::RankingExpressionBackend>

=item * C<safe_search> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<search_as_you_type_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::SearchAsYouTypeSpec>

=item * C<display_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::DisplaySpec>

=item * C<crowding_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::SearchService::CrowdingSpec>

=item * C<session> - C<string>

=item * C<session_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::SessionSpec>

=item * C<relevance_threshold> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::RelevanceThreshold>

=item * C<relevance_filter_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::RelevanceFilterSpec>

=item * C<personalization_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::PersonalizationSpec>

=item * C<relevance_score_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::RelevanceScoreSpec>

=item * C<search_addon_spec> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::SearchAddonSpec>

=item * C<custom_ranking_params> - L<Google::Cloud::Discoveryengine::V1beta::SearchService::CustomRankingParams>

=item * C<entity> - C<string>

=back

=item * B<train_custom_model>

    my $response = $client->train_custom_model(
        data_store               => $data_store,
        model_type               => $model_type,
        error_config             => $error_config,
        model_id                 => $model_id,
    );

Calls the RPC method C<TrainCustomModel> on C<google.cloud.discoveryengine.v1beta.SearchTuningService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SearchTuningService::TrainCustomModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<data_store> - C<string>

=item * C<model_type> - C<string>

=item * C<error_config> - L<Google::Cloud::Discoveryengine::V1beta::ImportConfig::ImportErrorConfig>

=item * C<model_id> - C<string>

=back

=item * B<create_serving_config>

    my $response = $client->create_serving_config(
        parent                   => $parent,
        serving_config           => $serving_config,
        serving_config_id        => $serving_config_id,
    );

Calls the RPC method C<CreateServingConfig> on C<google.cloud.discoveryengine.v1beta.ServingConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ServingConfigService::CreateServingConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<serving_config> - L<Google::Cloud::Discoveryengine::V1beta::ServingConfig::ServingConfig>

=item * C<serving_config_id> - C<string>

=back

=item * B<create_session>

    my $response = $client->create_session(
        parent                   => $parent,
        session                  => $session,
        session_id               => $session_id,
    );

Calls the RPC method C<CreateSession> on C<google.cloud.discoveryengine.v1beta.SessionService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::Session::Session>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<session> - L<Google::Cloud::Discoveryengine::V1beta::Session::Session>

=item * C<session_id> - C<string>

=back

=item * B<get_site_search_engine>

    my $response = $client->get_site_search_engine(
        name                     => $name,
    );

Calls the RPC method C<GetSiteSearchEngine> on C<google.cloud.discoveryengine.v1beta.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::GetSiteSearchEngineRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::SiteSearchEngine>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<batch_create_target_sites>

    my $response = $client->batch_create_target_sites(
        parent                   => $parent,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchCreateTargetSites> on C<google.cloud.discoveryengine.v1beta.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::BatchCreateTargetSitesRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::CreateTargetSiteRequest>

=back

=item * B<create_sitemap>

    my $response = $client->create_sitemap(
        parent                   => $parent,
        sitemap                  => $sitemap,
    );

Calls the RPC method C<CreateSitemap> on C<google.cloud.discoveryengine.v1beta.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::CreateSitemapRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<sitemap> - L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine::Sitemap>

=back

=item * B<enable_advanced_site_search>

    my $response = $client->enable_advanced_site_search(
        site_search_engine       => $site_search_engine,
    );

Calls the RPC method C<EnableAdvancedSiteSearch> on C<google.cloud.discoveryengine.v1beta.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::EnableAdvancedSiteSearchRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<site_search_engine> - C<string>

=back

=item * B<recrawl_uris>

    my $response = $client->recrawl_uris(
        site_search_engine       => $site_search_engine,
        uris                     => [ ... ],
        site_credential          => $site_credential,
    );

Calls the RPC method C<RecrawlUris> on C<google.cloud.discoveryengine.v1beta.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService::RecrawlUrisRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<site_search_engine> - C<string>

=item * C<uris> - ArrayRef of C<string>

=item * C<site_credential> - C<string>

=back

=item * B<write_user_event>

    my $response = $client->write_user_event(
        parent                   => $parent,
        user_event               => $user_event,
        write_async              => $write_async,
    );

Calls the RPC method C<WriteUserEvent> on C<google.cloud.discoveryengine.v1beta.UserEventService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::UserEventService::WriteUserEventRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1beta::UserEvent::UserEvent>

=item * C<write_async> - C<bool>

=back

=item * B<list_user_licenses>

    my $response = $client->list_user_licenses(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListUserLicenses> on C<google.cloud.discoveryengine.v1beta.UserLicenseService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<get_user_store>

    my $response = $client->get_user_store(
        name                     => $name,
    );

Calls the RPC method C<GetUserStore> on C<google.cloud.discoveryengine.v1beta.UserStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1beta::UserStoreService::GetUserStoreRequest>

Returns: L<Google::Cloud::Discoveryengine::V1beta::UserStore::UserStore>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
