package Google::Cloud::Discoveryengine::V1alpha;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1alpha::Completion;
use Google::Cloud::Discoveryengine::V1alpha::Grounding;
use Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1alpha::Answer;
use Google::Cloud::Discoveryengine::V1alpha::Common;
use Google::Cloud::Discoveryengine::V1alpha::Project;
use Google::Cloud::Discoveryengine::V1alpha::Schema;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuery;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1alpha::Chunk;
use Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1alpha::RankService;
use Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1alpha::Session;
use Google::Cloud::Discoveryengine::V1alpha::Document;
use Google::Cloud::Discoveryengine::V1alpha::AclConfig;
use Google::Cloud::Discoveryengine::V1alpha::Control;
use Google::Cloud::Discoveryengine::V1alpha::Engine;
use Google::Cloud::Discoveryengine::V1alpha::UserEvent;
use Google::Cloud::Discoveryengine::V1alpha::ProjectService;
use Google::Cloud::Discoveryengine::V1alpha::SchemaService;
use Google::Cloud::Discoveryengine::V1alpha::DataStore;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1alpha::ChunkService;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1alpha::SearchService;
use Google::Cloud::Discoveryengine::V1alpha::AclConfigService;
use Google::Cloud::Discoveryengine::V1alpha::ControlService;
use Google::Cloud::Discoveryengine::V1alpha::EngineService;
use Google::Cloud::Discoveryengine::V1alpha::ImportConfig;
use Google::Cloud::Discoveryengine::V1alpha::RecommendationService;
use Google::Cloud::Discoveryengine::V1alpha::DataStoreService;
use Google::Cloud::Discoveryengine::V1alpha::Evaluation;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfig;
use Google::Cloud::Discoveryengine::V1alpha::Conversation;
use Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService;
use Google::Cloud::Discoveryengine::V1alpha::SearchTuningService;
use Google::Cloud::Discoveryengine::V1alpha::PurgeConfig;
use Google::Cloud::Discoveryengine::V1alpha::SampleQueryService;
use Google::Cloud::Discoveryengine::V1alpha::EvaluationService;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfigService;
use Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1alpha::CompletionService;
use Google::Cloud::Discoveryengine::V1alpha::DocumentService;
use Google::Cloud::Discoveryengine::V1alpha::UserEventService;
use Google::Cloud::Discoveryengine::V1alpha::SessionService;

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

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.AclConfigService/UpdateAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.AclConfigService',
        method         => 'UpdateAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_acl_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.AclConfigService/GetAclConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.AclConfigService',
        method         => 'GetAclConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_chunk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ChunkService/GetChunk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ChunkService',
        method         => 'GetChunk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub complete_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.CompletionService/CompleteQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.CompletionService',
        method         => 'CompleteQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_control {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Control::Control';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ControlService/CreateControl',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ControlService',
        method         => 'CreateControl',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub converse_conversation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ConversationalSearchService/ConverseConversation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ConversationalSearchService',
        method         => 'ConverseConversation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_data_store {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.DataStoreService/CreateDataStore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'CreateDataStore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_document_processing_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.DataStoreService/UpdateDocumentProcessingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DataStoreService',
        method         => 'UpdateDocumentProcessingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Document::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.DocumentService/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.DocumentService',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.EngineService/CreateEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EngineService',
        method         => 'CreateEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub estimate_data_size {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.EstimateBillingService/EstimateDataSize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EstimateBillingService',
        method         => 'EstimateDataSize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_evaluation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.EvaluationService/GetEvaluation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.EvaluationService',
        method         => 'GetEvaluation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub check_grounding {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.GroundedGenerationService/CheckGrounding',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.GroundedGenerationService',
        method         => 'CheckGrounding',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Project::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ProjectService/GetProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'GetProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub provision_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.ProjectService/ProvisionProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'ProvisionProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_consent_change {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Project::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ProjectService/ReportConsentChange',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ProjectService',
        method         => 'ReportConsentChange',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rank {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.RankService/Rank',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.RankService',
        method         => 'Rank',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recommend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.RecommendationService/Recommend',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.RecommendationService',
        method         => 'Recommend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_sample_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SampleQueryService/GetSampleQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQueryService',
        method         => 'GetSampleQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_sample_query_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SampleQuerySetService/GetSampleQuerySet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SampleQuerySetService',
        method         => 'GetSampleQuerySet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_schema {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SchemaService/GetSchema',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SchemaService',
        method         => 'GetSchema',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub train_custom_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.SearchTuningService/TrainCustomModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SearchTuningService',
        method         => 'TrainCustomModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_serving_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.ServingConfigService/UpdateServingConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::CreateSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::Session::Session';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SessionService/CreateSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SessionService',
        method         => 'CreateSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_site_search_engine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.SiteSearchEngineService/GetSiteSearchEngine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService',
        method         => 'GetSiteSearchEngine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_create_target_sites {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.SiteSearchEngineService/BatchCreateTargetSites',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService',
        method         => 'BatchCreateTargetSites',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_advanced_site_search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.SiteSearchEngineService/EnableAdvancedSiteSearch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService',
        method         => 'EnableAdvancedSiteSearch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recrawl_uris {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest';
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
            path           => '/google.cloud.discoveryengine.v1alpha.SiteSearchEngineService/RecrawlUris',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.SiteSearchEngineService',
        method         => 'RecrawlUris',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub write_user_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.discoveryengine.v1alpha.UserEventService/WriteUserEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.discoveryengine.v1alpha.UserEventService',
        method         => 'WriteUserEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Discoveryengine::V1alpha

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1alpha->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1alpha->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1alpha> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/acl_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/acl_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/answer.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/chunk.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/chunk_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/common.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/completion.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/completion_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/control.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/control_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/conversation.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/conversational_search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/custom_tuning_model.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/data_store.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/data_store_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/document.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/document_processing_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/document_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/estimate_billing_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/evaluation.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/evaluation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/grounded_generation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/grounding.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/import_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/project.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/project_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/purge_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/rank_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/recommendation_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/sample_query.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/sample_query_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/sample_query_set.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/sample_query_set_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/schema.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/schema_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/search_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/search_tuning_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/serving_config.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/serving_config_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/session.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/session_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/site_search_engine.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/site_search_engine_service.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/user_event.proto>

=item * C<googleapis/google/cloud/discoveryengine/v1alpha/user_event_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Discoveryengine::V1alpha->new(
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

Calls the RPC method C<UpdateAclConfig> on C<google.cloud.discoveryengine.v1alpha.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::AclConfigService::UpdateAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig>

Parameters:

=over 4

=item * C<acl_config> - L<Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig>

=back

=item * B<get_acl_config>

    my $response = $client->get_acl_config(
        name                     => $name,
    );

Calls the RPC method C<GetAclConfig> on C<google.cloud.discoveryengine.v1alpha.AclConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::AclConfigService::GetAclConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::AclConfig::AclConfig>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_chunk>

    my $response = $client->get_chunk(
        name                     => $name,
    );

Calls the RPC method C<GetChunk> on C<google.cloud.discoveryengine.v1alpha.ChunkService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk>

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

Calls the RPC method C<CompleteQuery> on C<google.cloud.discoveryengine.v1alpha.CompletionService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse>

Parameters:

=over 4

=item * C<data_store> - C<string>

=item * C<query> - C<string>

=item * C<query_model> - C<string>

=item * C<user_pseudo_id> - C<string>

=item * C<include_tail_suggestions> - C<bool>

=back

=item * B<create_control>

    my $response = $client->create_control(
        parent                   => $parent,
        control                  => $control,
        control_id               => $control_id,
    );

Calls the RPC method C<CreateControl> on C<google.cloud.discoveryengine.v1alpha.ControlService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ControlService::CreateControlRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Control::Control>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<control> - L<Google::Cloud::Discoveryengine::V1alpha::Control::Control>

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

Calls the RPC method C<ConverseConversation> on C<google.cloud.discoveryengine.v1alpha.ConversationalSearchService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::ConverseConversationResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - L<Google::Cloud::Discoveryengine::V1alpha::Conversation::TextInput>

=item * C<serving_config> - C<string>

=item * C<conversation> - L<Google::Cloud::Discoveryengine::V1alpha::Conversation::Conversation>

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

Calls the RPC method C<CreateDataStore> on C<google.cloud.discoveryengine.v1alpha.DataStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::DataStoreService::CreateDataStoreRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<data_store> - L<Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore>

=item * C<data_store_id> - C<string>

=item * C<create_advanced_site_search> - C<bool>

=item * C<skip_default_schema_creation> - C<bool>

=back

=item * B<update_document_processing_config>

    my $response = $client->update_document_processing_config(
        document_processing_config => $document_processing_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateDocumentProcessingConfig> on C<google.cloud.discoveryengine.v1alpha.DataStoreService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::DataStoreService::UpdateDocumentProcessingConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig>

Parameters:

=over 4

=item * C<document_processing_config> - L<Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<get_document>

    my $response = $client->get_document(
        name                     => $name,
    );

Calls the RPC method C<GetDocument> on C<google.cloud.discoveryengine.v1alpha.DocumentService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Document::Document>

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

Calls the RPC method C<CreateEngine> on C<google.cloud.discoveryengine.v1alpha.EngineService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::EngineService::CreateEngineRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<engine> - L<Google::Cloud::Discoveryengine::V1alpha::Engine::Engine>

=item * C<engine_id> - C<string>

=back

=item * B<estimate_data_size>

    my $response = $client->estimate_data_size(
        location                 => $location,
    );

Calls the RPC method C<EstimateDataSize> on C<google.cloud.discoveryengine.v1alpha.EstimateBillingService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService::EstimateDataSizeRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<location> - C<string>

=back

=item * B<get_evaluation>

    my $response = $client->get_evaluation(
        name                     => $name,
    );

Calls the RPC method C<GetEvaluation> on C<google.cloud.discoveryengine.v1alpha.EvaluationService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Evaluation::Evaluation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<check_grounding>

    my $response = $client->check_grounding(
        grounding_config         => $grounding_config,
        answer_candidate         => $answer_candidate,
        facts                    => [ ... ],
        grounding_spec           => $grounding_spec,
        user_labels              => { ... },
    );

Calls the RPC method C<CheckGrounding> on C<google.cloud.discoveryengine.v1alpha.GroundedGenerationService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse>

Parameters:

=over 4

=item * C<grounding_config> - C<string>

=item * C<answer_candidate> - C<string>

=item * C<facts> - ArrayRef of L<Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact>

=item * C<grounding_spec> - L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=back

=item * B<get_project>

    my $response = $client->get_project(
        name                     => $name,
    );

Calls the RPC method C<GetProject> on C<google.cloud.discoveryengine.v1alpha.ProjectService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Project::Project>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<provision_project>

    my $response = $client->provision_project(
        name                     => $name,
        accept_data_use_terms    => $accept_data_use_terms,
        data_use_terms_version   => $data_use_terms_version,
    );

Calls the RPC method C<ProvisionProject> on C<google.cloud.discoveryengine.v1alpha.ProjectService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<accept_data_use_terms> - C<bool>

=item * C<data_use_terms_version> - C<string>

=back

=item * B<report_consent_change>

    my $response = $client->report_consent_change(
        consent_change_action    => $consent_change_action,
        project                  => $project,
        service_term_id          => $service_term_id,
        service_term_version     => $service_term_version,
    );

Calls the RPC method C<ReportConsentChange> on C<google.cloud.discoveryengine.v1alpha.ProjectService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Project::Project>

Parameters:

=over 4

=item * C<consent_change_action> - L<Google::Cloud::Discoveryengine::V1alpha::ProjectService::ConsentChangeAction>

=item * C<project> - C<string>

=item * C<service_term_id> - C<string>

=item * C<service_term_version> - C<string>

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

Calls the RPC method C<Rank> on C<google.cloud.discoveryengine.v1alpha.RankService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankResponse>

Parameters:

=over 4

=item * C<ranking_config> - C<string>

=item * C<model> - C<string>

=item * C<top_n> - C<int32>

=item * C<query> - C<string>

=item * C<records> - ArrayRef of L<Google::Cloud::Discoveryengine::V1alpha::RankService::RankingRecord>

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

Calls the RPC method C<Recommend> on C<google.cloud.discoveryengine.v1alpha.RecommendationService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::RecommendationService::RecommendResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent>

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

Calls the RPC method C<GetSampleQuery> on C<google.cloud.discoveryengine.v1alpha.SampleQueryService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::SampleQuery::SampleQuery>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_sample_query_set>

    my $response = $client->get_sample_query_set(
        name                     => $name,
    );

Calls the RPC method C<GetSampleQuerySet> on C<google.cloud.discoveryengine.v1alpha.SampleQuerySetService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet::SampleQuerySet>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_schema>

    my $response = $client->get_schema(
        name                     => $name,
    );

Calls the RPC method C<GetSchema> on C<google.cloud.discoveryengine.v1alpha.SchemaService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SchemaService::GetSchemaRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Schema::Schema>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search>

    my $response = $client->search(
        serving_config           => $serving_config,
        branch                   => $branch,
        query                    => $query,
        image_query              => $image_query,
        page_size                => $page_size,
        page_token               => $page_token,
        offset                   => $offset,
        data_store_specs         => [ ... ],
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
        custom_fine_tuning_spec  => $custom_fine_tuning_spec,
        session                  => $session,
        session_spec             => $session_spec,
        relevance_threshold      => $relevance_threshold,
    );

Calls the RPC method C<Search> on C<google.cloud.discoveryengine.v1alpha.SearchService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<serving_config> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<image_query> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::ImageQuery>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<data_store_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1alpha::SearchService::DataStoreSpec>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<user_info> - L<Google::Cloud::Discoveryengine::V1alpha::Common::UserInfo>

=item * C<language_code> - C<string>

=item * C<region_code> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Discoveryengine::V1alpha::SearchService::FacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::BoostSpec>

=item * C<params> - C<map<string, google.protobuf.Value>> (HashRef)

=item * C<query_expansion_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::QueryExpansionSpec>

=item * C<spell_correction_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SpellCorrectionSpec>

=item * C<user_pseudo_id> - C<string>

=item * C<content_search_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::ContentSearchSpec>

=item * C<embedding_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::EmbeddingSpec>

=item * C<ranking_expression> - C<string>

=item * C<ranking_expression_backend> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::RankingExpressionBackend>

=item * C<safe_search> - C<bool>

=item * C<user_labels> - C<map<string, string>> (HashRef)

=item * C<search_as_you_type_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchAsYouTypeSpec>

=item * C<custom_fine_tuning_spec> - L<Google::Cloud::Discoveryengine::V1alpha::Common::CustomFineTuningSpec>

=item * C<session> - C<string>

=item * C<session_spec> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SessionSpec>

=item * C<relevance_threshold> - L<Google::Cloud::Discoveryengine::V1alpha::SearchService::RelevanceThreshold>

=back

=item * B<train_custom_model>

    my $response = $client->train_custom_model(
        data_store               => $data_store,
        model_type               => $model_type,
        error_config             => $error_config,
        model_id                 => $model_id,
    );

Calls the RPC method C<TrainCustomModel> on C<google.cloud.discoveryengine.v1alpha.SearchTuningService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SearchTuningService::TrainCustomModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<data_store> - C<string>

=item * C<model_type> - C<string>

=item * C<error_config> - L<Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportErrorConfig>

=item * C<model_id> - C<string>

=back

=item * B<update_serving_config>

    my $response = $client->update_serving_config(
        serving_config           => $serving_config,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateServingConfig> on C<google.cloud.discoveryengine.v1alpha.ServingConfigService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig>

Parameters:

=over 4

=item * C<serving_config> - L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_session>

    my $response = $client->create_session(
        parent                   => $parent,
        session                  => $session,
    );

Calls the RPC method C<CreateSession> on C<google.cloud.discoveryengine.v1alpha.SessionService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService::CreateSessionRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::Session::Session>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<session> - L<Google::Cloud::Discoveryengine::V1alpha::Session::Session>

=back

=item * B<get_site_search_engine>

    my $response = $client->get_site_search_engine(
        name                     => $name,
    );

Calls the RPC method C<GetSiteSearchEngine> on C<google.cloud.discoveryengine.v1alpha.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::GetSiteSearchEngineRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<batch_create_target_sites>

    my $response = $client->batch_create_target_sites(
        parent                   => $parent,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchCreateTargetSites> on C<google.cloud.discoveryengine.v1alpha.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::BatchCreateTargetSitesRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::CreateTargetSiteRequest>

=back

=item * B<enable_advanced_site_search>

    my $response = $client->enable_advanced_site_search(
        site_search_engine       => $site_search_engine,
    );

Calls the RPC method C<EnableAdvancedSiteSearch> on C<google.cloud.discoveryengine.v1alpha.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::EnableAdvancedSiteSearchRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<site_search_engine> - C<string>

=back

=item * B<recrawl_uris>

    my $response = $client->recrawl_uris(
        site_search_engine       => $site_search_engine,
        uris                     => [ ... ],
    );

Calls the RPC method C<RecrawlUris> on C<google.cloud.discoveryengine.v1alpha.SiteSearchEngineService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService::RecrawlUrisRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<site_search_engine> - C<string>

=item * C<uris> - ArrayRef of C<string>

=back

=item * B<write_user_event>

    my $response = $client->write_user_event(
        parent                   => $parent,
        user_event               => $user_event,
        write_async              => $write_async,
    );

Calls the RPC method C<WriteUserEvent> on C<google.cloud.discoveryengine.v1alpha.UserEventService>.

Request: L<Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest>

Returns: L<Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<user_event> - L<Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent>

=item * C<write_async> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
