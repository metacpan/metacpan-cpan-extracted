package Google::Cloud::Discoveryengine::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1::Safety;
use Google::Cloud::Discoveryengine::V1::Chunk;
use Google::Cloud::Discoveryengine::V1::Logging;
use Google::Cloud::Discoveryengine::V1::RankService;
use Google::Cloud::Discoveryengine::V1::Grounding;
use Google::Cloud::Discoveryengine::V1::Schema;
use Google::Cloud::Discoveryengine::V1::AgentGatewaySetting;
use Google::Cloud::Discoveryengine::V1::UserStore;
use Google::Cloud::Discoveryengine::V1::Common;
use Google::Cloud::Discoveryengine::V1::Completion;
use Google::Cloud::Discoveryengine::V1::CmekConfigService;
use Google::Cloud::Discoveryengine::V1::UserLicense;
use Google::Cloud::Discoveryengine::V1::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1::Collection;
use Google::Cloud::Discoveryengine::V1::CollectionService;
use Google::Cloud::Discoveryengine::V1::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1::Answer;
use Google::Cloud::Discoveryengine::V1::Project;
use Google::Cloud::Discoveryengine::V1::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1::SchemaService;
use Google::Cloud::Discoveryengine::V1::UserStoreService;
use Google::Cloud::Discoveryengine::V1::LicenseConfig;
use Google::Cloud::Discoveryengine::V1::Assistant;
use Google::Cloud::Discoveryengine::V1::AclConfig;
use Google::Cloud::Discoveryengine::V1::DataConnector;
use Google::Cloud::Discoveryengine::V1::Document;
use Google::Cloud::Discoveryengine::V1::Control;
use Google::Cloud::Discoveryengine::V1::Engine;
use Google::Cloud::Discoveryengine::V1::IdentityMappingStore;
use Google::Cloud::Discoveryengine::V1::DataStore;
use Google::Cloud::Discoveryengine::V1::UserLicenseService;
use Google::Cloud::Discoveryengine::V1::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1::ProjectService;
use Google::Cloud::Discoveryengine::V1::AssistAnswer;
use Google::Cloud::Discoveryengine::V1::LicenseConfigService;
use Google::Cloud::Discoveryengine::V1::AclConfigService;
use Google::Cloud::Discoveryengine::V1::WidgetConfig;
use Google::Cloud::Discoveryengine::V1::DataConnectorService;
use Google::Cloud::Discoveryengine::V1::SearchService;
use Google::Cloud::Discoveryengine::V1::ControlService;
use Google::Cloud::Discoveryengine::V1::EngineService;
use Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService;
use Google::Cloud::Discoveryengine::V1::DataStoreService;
use Google::Cloud::Discoveryengine::V1::Session;
use Google::Cloud::Discoveryengine::V1::WidgetConfigService;
use Google::Cloud::Discoveryengine::V1::ServingConfig;
use Google::Cloud::Discoveryengine::V1::Conversation;
use Google::Cloud::Discoveryengine::V1::Feedback;
use Google::Cloud::Discoveryengine::V1::AssistantService;
use Google::Cloud::Discoveryengine::V1::ServingConfigService;
use Google::Cloud::Discoveryengine::V1::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1::UserEvent;
use Google::Cloud::Discoveryengine::V1::SessionService;
use Google::Cloud::Discoveryengine::V1::RecommendationService;
use Google::Cloud::Discoveryengine::V1::ImportConfig;
use Google::Cloud::Discoveryengine::V1::SearchTuningService;
use Google::Cloud::Discoveryengine::V1::PurgeConfig;
use Google::Cloud::Discoveryengine::V1::DocumentService;
use Google::Cloud::Discoveryengine::V1::CompletionService;
use Google::Cloud::Discoveryengine::V1::UserEventService;

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

    my $request_class = 'Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.AclConfigService/UpdateAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_acl_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.AclConfigService/GetAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.AclConfigService',
        method         => 'GetAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_assist {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.AssistantService/StreamAssist',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.AssistantService',
        method         => 'StreamAssist',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cmek_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest';
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
            path           => '/google.cloud.discoveryengine.v1.CmekConfigService/UpdateCmekConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.CmekConfigService',
        method         => 'UpdateCmekConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_collection {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest';
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
            path           => '/google.cloud.discoveryengine.v1.CollectionService/DeleteCollection',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.CollectionService',
        method         => 'DeleteCollection',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub complete_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.CompletionService/CompleteQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.CompletionService',
        method         => 'CompleteQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub import_suggestion_deny_list_entries {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest';
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
            path           => '/google.cloud.discoveryengine.v1.CompletionService/ImportSuggestionDenyListEntries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.CompletionService',
        method         => 'ImportSuggestionDenyListEntries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_control {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::Control::Control';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.ControlService/CreateControl',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.ControlService',
        method         => 'CreateControl',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub converse_conversation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.ConversationalSearchService/ConverseConversation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.ConversationalSearchService',
        method         => 'ConverseConversation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_up_data_connector {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest';
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
            path           => '/google.cloud.discoveryengine.v1.DataConnectorService/SetUpDataConnector',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.DataConnectorService',
        method         => 'SetUpDataConnector',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_data_connector {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.DataConnectorService/UpdateDataConnector',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.DataConnectorService',
        method         => 'UpdateDataConnector',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_data_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest';
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
            path           => '/google.cloud.discoveryengine.v1.DataStoreService/CreateDataStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'CreateDataStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::Document::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.DocumentService/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.DocumentService',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest';
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
            path           => '/google.cloud.discoveryengine.v1.EngineService/CreateEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.EngineService',
        method         => 'CreateEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_grounded_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.GroundedGenerationService/StreamGenerateGroundedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.GroundedGenerationService',
        method         => 'StreamGenerateGroundedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_identity_mapping_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.IdentityMappingStoreService/CreateIdentityMappingStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.IdentityMappingStoreService',
        method         => 'CreateIdentityMappingStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_license_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.LicenseConfigService/CreateLicenseConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'CreateLicenseConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub provision_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest';
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
            path           => '/google.cloud.discoveryengine.v1.ProjectService/ProvisionProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.ProjectService',
        method         => 'ProvisionProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rank {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::RankService::RankRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::RankService::RankResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.RankService/Rank',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.RankService',
        method         => 'Rank',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recommend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.RecommendationService/Recommend',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.RecommendationService',
        method         => 'Recommend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_schema {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::Schema::Schema';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.SchemaService/GetSchema',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SchemaService',
        method         => 'GetSchema',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub train_custom_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest';
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
            path           => '/google.cloud.discoveryengine.v1.SearchTuningService/TrainCustomModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_serving_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.ServingConfigService/CreateServingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::ConversationalSearchService::CreateSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::Session::Session';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.SessionService/CreateSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SessionService',
        method         => 'CreateSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_site_search_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::GetSiteSearchEngineRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.SiteSearchEngineService/GetSiteSearchEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SiteSearchEngineService',
        method         => 'GetSiteSearchEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_create_target_sites {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::BatchCreateTargetSitesRequest';
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
            path           => '/google.cloud.discoveryengine.v1.SiteSearchEngineService/BatchCreateTargetSites',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SiteSearchEngineService',
        method         => 'BatchCreateTargetSites',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_sitemap {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::CreateSitemapRequest';
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
            path           => '/google.cloud.discoveryengine.v1.SiteSearchEngineService/CreateSitemap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SiteSearchEngineService',
        method         => 'CreateSitemap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_advanced_site_search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::EnableAdvancedSiteSearchRequest';
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
            path           => '/google.cloud.discoveryengine.v1.SiteSearchEngineService/EnableAdvancedSiteSearch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SiteSearchEngineService',
        method         => 'EnableAdvancedSiteSearch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recrawl_uris {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::RecrawlUrisRequest';
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
            path           => '/google.cloud.discoveryengine.v1.SiteSearchEngineService/RecrawlUris',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.SiteSearchEngineService',
        method         => 'RecrawlUris',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub write_user_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.UserEventService/WriteUserEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.UserEventService',
        method         => 'WriteUserEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_user_licenses {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.UserLicenseService/ListUserLicenses',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.UserLicenseService',
        method         => 'ListUserLicenses',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_user_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::UserStore::UserStore';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.UserStoreService/GetUserStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.UserStoreService',
        method         => 'GetUserStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_widget_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1.WidgetConfigService/GetWidgetConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1.WidgetConfigService',
        method         => 'GetWidgetConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Discoveryengine::V1

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/discoveryengine/v1/acl_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/acl_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/agent_gateway_setting.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/answer.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/assist_answer.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/assistant.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/assistant_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/chunk.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/cmek_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/collection.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/collection_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/common.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/completion.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/completion_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/control.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/control_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/conversation.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/conversational_search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/custom_tuning_model.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/data_connector.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/data_connector_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/data_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/data_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/document.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/document_processing_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/document_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/feedback.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/grounded_generation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/grounding.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/identity_mapping_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/identity_mapping_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/import_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/license_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/license_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/logging.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/project.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/project_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/purge_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/rank_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/recommendation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/safety.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/schema.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/schema_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/search_tuning_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/serving_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/serving_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/session.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/session_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/site_search_engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/site_search_engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_event.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_event_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_license.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_license_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/user_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/widget_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1/widget_config_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Discoveryengine::V1->new(
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

Calls the RPC method C<UpdateAclConfig> on C<google.cloud.discoveryengine.v1.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::AclConfigService::UpdateAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig>

Parameters:

=over 4

=item * C<acl_config> - L<Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig>

=back

=item * B<get_acl_config>

    my $response = $client->get_acl_config(
        name                     => $name,
    );

Calls the RPC method C<GetAclConfig> on C<google.cloud.discoveryengine.v1.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::AclConfigService::GetAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::AclConfig::AclConfig>

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

Calls the RPC method C<StreamAssist> on C<google.cloud.discoveryengine.v1.AssistantService>.

Request: L<Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - L<Google::Cloud::Discoveryengine::V1::Session::Query>

=item * C<session> - C<string>

=item * C<user_metadata> - L<Google::Cloud::Discoveryengine::V1::AssistantService::AssistUserMetadata>

=item * C<agents_spec> - L<Google::Cloud::Discoveryengine::V1::AssistantService::AgentsSpec>

=item * C<tools_spec> - L<Google::Cloud::Discoveryengine::V1::AssistantService::ToolsSpec>

=item * C<generation_spec> - L<Google::Cloud::Discoveryengine::V1::AssistantService::GenerationSpec>

=back

=item * B<update_cmek_config>

    my $response = $client->update_cmek_config(
        config                   => $config,
        set_default              => $set_default,
    );

Calls the RPC method C<UpdateCmekConfig> on C<google.cloud.discoveryengine.v1.CmekConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<config> - L<Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig>

=item * C<set_default> - C<bool>

=back

=item * B<delete_collection>

    my $response = $client->delete_collection(
        name                     => $name,
    );

Calls the RPC method C<DeleteCollection> on C<google.cloud.discoveryengine.v1.CollectionService>.

Request: L<Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<complete_query>

    my $response = $client->complete_query(
        data_store               => $data_store,
        query                    => $query,
        query_model              => $query_model,
        user_pseudo_id           => $user_pseudo_id,
        include_tail_suggestions => $include_tail_suggestions,
    );

Calls the RPC method C<CompleteQuery> on C<google.cloud.discoveryengine.v1.CompletionService>.

Request: L<Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse>

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

Calls the RPC method C<ImportSuggestionDenyListEntries> on C<google.cloud.discoveryengine.v1.CompletionService>.

Request: L<Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest>

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

Calls the RPC method C<CreateControl> on C<google.cloud.discoveryengine.v1.ControlService>.

Request: L<Google::Cloud::Discoveryengine::V1::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Discoveryengine::V1::Control::Control>

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

Calls the RPC method C<ConverseConversation> on C<google.cloud.discoveryengine.v1.ConversationalSearchService>.

Request: L<Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::ConversationalSearchService::ConverseConversationResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - L<Google::Cloud::Discoveryengine::V1::Conversation::TextInput>

=item * C<serving_config> - C<string>

=item * C<conversation> - L<Google::Cloud::Discoveryengine::V1::Conversation::Conversation>

=item * C<safe_search> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<summary_spec> - L<SearchRequest::ContentSearchSpec::SummarySpec::SummarySpec>

=item * C<filter> - C<string>

=item * C<boost_spec> - L<SearchRequest::BoostSpec::BoostSpec>

=back

=item * B<set_up_data_connector>

    my $response = $client->set_up_data_connector(
        parent                   => $parent,
        collection_id            => $collection_id,
        collection_display_name  => $collection_display_name,
        data_connector           => $data_connector,
    );

Calls the RPC method C<SetUpDataConnector> on C<google.cloud.discoveryengine.v1.DataConnectorService>.

Request: L<Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<collection_id> - C<string>

=item * C<collection_display_name> - C<string>

=item * C<data_connector> - L<Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector>

=back

=item * B<update_data_connector>

    my $response = $client->update_data_connector(
        data_connector           => $data_connector,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateDataConnector> on C<google.cloud.discoveryengine.v1.DataConnectorService>.

Request: L<Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector>

Parameters:

=over 4

=item * C<data_connector> - L<Google::Cloud::Discoveryengine::V1::DataConnector::DataConnector>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_data_store>

    my $response = $client->create_data_store(
        parent                   => $parent,
        data_store               => $data_store,
        data_store_id            => $data_store_id,
        create_advanced_site_search => $create_advanced_site_search,
        skip_default_schema_creation => $skip_default_schema_creation,
    );

Calls the RPC method C<CreateDataStore> on C<google.cloud.discoveryengine.v1.DataStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<data_store> - L<Google::Cloud::Discoveryengine::V1::DataStore::DataStore>

=item * C<data_store_id> - C<string>

=item * C<create_advanced_site_search> - C<bool>

=item * C<skip_default_schema_creation> - C<bool>

=back

=item * B<get_document>

    my $response = $client->get_document(
        name                     => $name,
    );

Calls the RPC method C<GetDocument> on C<google.cloud.discoveryengine.v1.DocumentService>.

Request: L<Google::Cloud::Discoveryengine::V1::DocumentService::GetDocumentRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::Document::Document>

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

Calls the RPC method C<CreateEngine> on C<google.cloud.discoveryengine.v1.EngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::EngineService::CreateEngineRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<engine> - L<Google::Cloud::Discoveryengine::V1::Engine::Engine>

=item * C<engine_id> - C<string>

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

Calls the RPC method C<StreamGenerateGroundedContent> on C<google.cloud.discoveryengine.v1.GroundedGenerationService>.

Request: L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerateGroundedContentResponse>

Parameters:

=over 4

=item * C<location> - C<string>

=item * C<system_instruction> - L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GroundedGenerationContent>

=item * C<contents> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GroundedGenerationContent>

=item * C<generation_spec> - L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GenerationSpec>

=item * C<grounding_spec> - L<Google::Cloud::Discoveryengine::V1::GroundedGenerationService::GroundingSpec>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<create_identity_mapping_store>

    my $response = $client->create_identity_mapping_store(
        parent                   => $parent,
        identity_mapping_store_id => $identity_mapping_store_id,
        identity_mapping_store   => $identity_mapping_store,
    );

Calls the RPC method C<CreateIdentityMappingStore> on C<google.cloud.discoveryengine.v1.IdentityMappingStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<identity_mapping_store_id> - C<string>

=item * C<identity_mapping_store> - L<Google::Cloud::Discoveryengine::V1::IdentityMappingStore::IdentityMappingStore>

=back

=item * B<create_license_config>

    my $response = $client->create_license_config(
        parent                   => $parent,
        license_config           => $license_config,
        license_config_id        => $license_config_id,
    );

Calls the RPC method C<CreateLicenseConfig> on C<google.cloud.discoveryengine.v1.LicenseConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<license_config> - L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>

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

Calls the RPC method C<ProvisionProject> on C<google.cloud.discoveryengine.v1.ProjectService>.

Request: L<Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<accept_data_use_terms> - C<bool>

=item * C<data_use_terms_version> - C<string>

=item * C<saas_params> - L<Google::Cloud::Discoveryengine::V1::ProjectService::SaasParams>

=item * C<provision_intent> - L<Google::Cloud::Discoveryengine::V1::ProjectService::ProvisionIntent>

=item * C<idp_config> - L<Google::Cloud::Discoveryengine::V1::Common::IdpConfig>

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

Calls the RPC method C<Rank> on C<google.cloud.discoveryengine.v1.RankService>.

Request: L<Google::Cloud::Discoveryengine::V1::RankService::RankRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::RankService::RankResponse>

Parameters:

=over 4

=item * C<ranking_config> - C<string>

=item * C<model> - C<string>

=item * C<top_n> - C<int32>

=item * C<query> - C<string>

=item * C<records> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::RankService::RankingRecord>

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

Calls the RPC method C<Recommend> on C<google.cloud.discoveryengine.v1.RecommendationService>.

Request: L<Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::RecommendationService::RecommendResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent>

=item * C<page_size> - C<int32>

=item * C<filter> - C<string>

=item * C<validate_only> - C<bool>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<get_schema>

    my $response = $client->get_schema(
        name                     => $name,
    );

Calls the RPC method C<GetSchema> on C<google.cloud.discoveryengine.v1.SchemaService>.

Request: L<Google::Cloud::Discoveryengine::V1::SchemaService::GetSchemaRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::Schema::Schema>

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
        facet_specs              => [ ... ],
        boost_spec               => $boost_spec,
        params                   => { ... },
        query_expansion_spec     => $query_expansion_spec,
        spell_correction_spec    => $spell_correction_spec,
        user_pseudo_id           => $user_pseudo_id,
        content_search_spec      => $content_search_spec,
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
        relevance_score_spec     => $relevance_score_spec,
        search_addon_spec        => $search_addon_spec,
        custom_ranking_params    => $custom_ranking_params,
        entity                   => $entity,
    );

Calls the RPC method C<Search> on C<google.cloud.discoveryengine.v1.SearchService>.

Request: L<Google::Cloud::Discoveryengine::V1::SearchService::SearchRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<image_query> - L<Google::Cloud::Discoveryengine::V1::SearchService::ImageQuery>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<one_box_page_size> - C<int32>

=item * C<data_store_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::SearchService::DataStoreSpec>

=item * C<num_results_per_data_store> - C<int32>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<user_info> - L<Google::Cloud::Discoveryengine::V1::Common::UserInfo>

=item * C<language_code> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::SearchService::FacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::BoostSpec>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<query_expansion_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::QueryExpansionSpec>

=item * C<spell_correction_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::SpellCorrectionSpec>

=item * C<user_pseudo_id> - C<string>

=item * C<content_search_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::ContentSearchSpec>

=item * C<ranking_expression> - C<string>

=item * C<ranking_expression_backend> - L<Google::Cloud::Discoveryengine::V1::SearchService::RankingExpressionBackend>

=item * C<safe_search> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<search_as_you_type_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::SearchAsYouTypeSpec>

=item * C<display_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::DisplaySpec>

=item * C<crowding_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::SearchService::CrowdingSpec>

=item * C<session> - C<string>

=item * C<session_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::SessionSpec>

=item * C<relevance_threshold> - L<Google::Cloud::Discoveryengine::V1::SearchService::RelevanceThreshold>

=item * C<relevance_filter_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::RelevanceFilterSpec>

=item * C<relevance_score_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::RelevanceScoreSpec>

=item * C<search_addon_spec> - L<Google::Cloud::Discoveryengine::V1::SearchService::SearchAddonSpec>

=item * C<custom_ranking_params> - L<Google::Cloud::Discoveryengine::V1::SearchService::CustomRankingParams>

=item * C<entity> - C<string>

=back

=item * B<train_custom_model>

    my $response = $client->train_custom_model(
        data_store               => $data_store,
        model_type               => $model_type,
        error_config             => $error_config,
        model_id                 => $model_id,
    );

Calls the RPC method C<TrainCustomModel> on C<google.cloud.discoveryengine.v1.SearchTuningService>.

Request: L<Google::Cloud::Discoveryengine::V1::SearchTuningService::TrainCustomModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<data_store> - C<string>

=item * C<model_type> - C<string>

=item * C<error_config> - L<Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig>

=item * C<model_id> - C<string>

=back

=item * B<create_serving_config>

    my $response = $client->create_serving_config(
        parent                   => $parent,
        serving_config           => $serving_config,
        serving_config_id        => $serving_config_id,
    );

Calls the RPC method C<CreateServingConfig> on C<google.cloud.discoveryengine.v1.ServingConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::ServingConfigService::CreateServingConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<serving_config> - L<Google::Cloud::Discoveryengine::V1::ServingConfig::ServingConfig>

=item * C<serving_config_id> - C<string>

=back

=item * B<create_session>

    my $response = $client->create_session(
        parent                   => $parent,
        session                  => $session,
        session_id               => $session_id,
    );

Calls the RPC method C<CreateSession> on C<google.cloud.discoveryengine.v1.SessionService>.

Request: L<Google::Cloud::Discoveryengine::V1::ConversationalSearchService::CreateSessionRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::Session::Session>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<session> - L<Google::Cloud::Discoveryengine::V1::Session::Session>

=item * C<session_id> - C<string>

=back

=item * B<get_site_search_engine>

    my $response = $client->get_site_search_engine(
        name                     => $name,
    );

Calls the RPC method C<GetSiteSearchEngine> on C<google.cloud.discoveryengine.v1.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::GetSiteSearchEngineRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngine::SiteSearchEngine>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<batch_create_target_sites>

    my $response = $client->batch_create_target_sites(
        parent                   => $parent,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchCreateTargetSites> on C<google.cloud.discoveryengine.v1.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::BatchCreateTargetSitesRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::CreateTargetSiteRequest>

=back

=item * B<create_sitemap>

    my $response = $client->create_sitemap(
        parent                   => $parent,
        sitemap                  => $sitemap,
    );

Calls the RPC method C<CreateSitemap> on C<google.cloud.discoveryengine.v1.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::CreateSitemapRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<sitemap> - L<Google::Cloud::Discoveryengine::V1::SiteSearchEngine::Sitemap>

=back

=item * B<enable_advanced_site_search>

    my $response = $client->enable_advanced_site_search(
        site_search_engine       => $site_search_engine,
    );

Calls the RPC method C<EnableAdvancedSiteSearch> on C<google.cloud.discoveryengine.v1.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::EnableAdvancedSiteSearchRequest>

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

Calls the RPC method C<RecrawlUris> on C<google.cloud.discoveryengine.v1.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1::SiteSearchEngineService::RecrawlUrisRequest>

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

Calls the RPC method C<WriteUserEvent> on C<google.cloud.discoveryengine.v1.UserEventService>.

Request: L<Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent>

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

Calls the RPC method C<ListUserLicenses> on C<google.cloud.discoveryengine.v1.UserLicenseService>.

Request: L<Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse>

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

Calls the RPC method C<GetUserStore> on C<google.cloud.discoveryengine.v1.UserStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1::UserStoreService::GetUserStoreRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::UserStore::UserStore>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_widget_config>

    my $response = $client->get_widget_config(
        name                     => $name,
        accept_cache             => $accept_cache,
        get_widget_config_request_option => $get_widget_config_request_option,
        language_code            => $language_code,
        model_info_view          => $model_info_view,
    );

Calls the RPC method C<GetWidgetConfig> on C<google.cloud.discoveryengine.v1.WidgetConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1::WidgetConfig::WidgetConfig>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<accept_cache> - C<bool>

=item * C<get_widget_config_request_option> - L<Google::Cloud::Discoveryengine::V1::WidgetConfigService::GetWidgetConfigRequestOption>

=item * C<language_code> - C<string>

=item * C<model_info_view> - L<Google::Cloud::Discoveryengine::V1::WidgetConfigService::ModelInfoView>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
