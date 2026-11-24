package Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting;
use Google::Cloud::Discoveryengine::V1beta::Assistant;
use Google::Cloud::Discoveryengine::V1beta::Schema;
use Google::Cloud::Discoveryengine::V1beta::UserLicense;
use Google::Cloud::Discoveryengine::V1beta::RankService;
use Google::Cloud::Discoveryengine::V1beta::Common;
use Google::Cloud::Discoveryengine::V1beta::Chunk;
use Google::Cloud::Discoveryengine::V1beta::CmekConfigService;
use Google::Cloud::Discoveryengine::V1beta::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1beta::Logging;
use Google::Cloud::Discoveryengine::V1beta::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1beta::Completion;
use Google::Cloud::Discoveryengine::V1beta::Safety;
use Google::Cloud::Discoveryengine::V1beta::Grounding;
use Google::Cloud::Discoveryengine::V1beta::UserStore;
use Google::Cloud::Discoveryengine::V1beta::SampleQuery;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1beta::SchemaService;
use Google::Cloud::Discoveryengine::V1beta::UserLicenseService;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfig;
use Google::Cloud::Discoveryengine::V1beta::Document;
use Google::Cloud::Discoveryengine::V1beta::AclConfig;
use Google::Cloud::Discoveryengine::V1beta::Control;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1beta::Engine;
use Google::Cloud::Discoveryengine::V1beta::Project;
use Google::Cloud::Discoveryengine::V1beta::DataStore;
use Google::Cloud::Discoveryengine::V1beta::Answer;
use Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1beta::UserStoreService;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfigService;
use Google::Cloud::Discoveryengine::V1beta::SearchService;
use Google::Cloud::Discoveryengine::V1beta::AclConfigService;
use Google::Cloud::Discoveryengine::V1beta::ControlService;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService;
use Google::Cloud::Discoveryengine::V1beta::EngineService;
use Google::Cloud::Discoveryengine::V1beta::ProjectService;
use Google::Cloud::Discoveryengine::V1beta::DataStoreService;
use Google::Cloud::Discoveryengine::V1beta::AssistAnswer;
use Google::Cloud::Discoveryengine::V1beta::Evaluation;
use Google::Cloud::Discoveryengine::V1beta::ServingConfig;
use Google::Cloud::Discoveryengine::V1beta::Conversation;
use Google::Cloud::Discoveryengine::V1beta::Session;
use Google::Cloud::Discoveryengine::V1beta::EvaluationService;
use Google::Cloud::Discoveryengine::V1beta::ServingConfigService;
use Google::Cloud::Discoveryengine::V1beta::Feedback;
use Google::Cloud::Discoveryengine::V1beta::AssistantService;
use Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1beta::UserEvent;
use Google::Cloud::Discoveryengine::V1beta::SessionService;
use Google::Cloud::Discoveryengine::V1beta::RecommendationService;
use Google::Cloud::Discoveryengine::V1beta::ImportConfig;
use Google::Cloud::Discoveryengine::V1beta::PurgeConfig;
use Google::Cloud::Discoveryengine::V1beta::SampleQueryService;
use Google::Cloud::Discoveryengine::V1beta::SearchTuningService;
use Google::Cloud::Discoveryengine::V1beta::CompletionService;
use Google::Cloud::Discoveryengine::V1beta::DocumentService;
use Google::Cloud::Discoveryengine::V1beta::UserEventService;

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
1; # End of Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Discoveryengine::V1beta::ProjectServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
