package Google::Cloud::Discoveryengine::V1::SessionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1::Safety;
use Google::Cloud::Discoveryengine::V1::Completion;
use Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1::Chunk;
use Google::Cloud::Discoveryengine::V1::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1::Grounding;
use Google::Cloud::Discoveryengine::V1::Logging;
use Google::Cloud::Discoveryengine::V1::UserLicense;
use Google::Cloud::Discoveryengine::V1::Collection;
use Google::Cloud::Discoveryengine::V1::Schema;
use Google::Cloud::Discoveryengine::V1::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1::Common;
use Google::Cloud::Discoveryengine::V1::UserStore;
use Google::Cloud::Discoveryengine::V1::AgentGatewaySetting;
use Google::Cloud::Discoveryengine::V1::CmekConfigService;
use Google::Cloud::Discoveryengine::V1::RankService;
use Google::Cloud::Discoveryengine::V1::CollectionService;
use Google::Cloud::Discoveryengine::V1::Answer;
use Google::Cloud::Discoveryengine::V1::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1::Project;
use Google::Cloud::Discoveryengine::V1::UserLicenseService;
use Google::Cloud::Discoveryengine::V1::SchemaService;
use Google::Cloud::Discoveryengine::V1::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1::LicenseConfig;
use Google::Cloud::Discoveryengine::V1::Assistant;
use Google::Cloud::Discoveryengine::V1::AclConfig;
use Google::Cloud::Discoveryengine::V1::DataConnector;
use Google::Cloud::Discoveryengine::V1::Document;
use Google::Cloud::Discoveryengine::V1::Control;
use Google::Cloud::Discoveryengine::V1::UserStoreService;
use Google::Cloud::Discoveryengine::V1::Engine;
use Google::Cloud::Discoveryengine::V1::IdentityMappingStore;
use Google::Cloud::Discoveryengine::V1::DataStore;
use Google::Cloud::Discoveryengine::V1::AssistAnswer;
use Google::Cloud::Discoveryengine::V1::ProjectService;
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
1; # End of Google::Cloud::Discoveryengine::V1::SessionServiceClient

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::SessionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::SessionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1::SessionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1::SessionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1::SessionServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Discoveryengine::V1::SessionServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
