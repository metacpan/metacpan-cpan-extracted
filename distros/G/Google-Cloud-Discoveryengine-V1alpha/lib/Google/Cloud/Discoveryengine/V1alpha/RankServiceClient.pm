package Google::Cloud::Discoveryengine::V1alpha::RankServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1alpha::Common;
use Google::Cloud::Discoveryengine::V1alpha::Schema;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuery;
use Google::Cloud::Discoveryengine::V1alpha::Chunk;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1alpha::Project;
use Google::Cloud::Discoveryengine::V1alpha::Answer;
use Google::Cloud::Discoveryengine::V1alpha::Grounding;
use Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1alpha::RankService;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1alpha::Completion;
use Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1alpha::UserEvent;
use Google::Cloud::Discoveryengine::V1alpha::Document;
use Google::Cloud::Discoveryengine::V1alpha::AclConfig;
use Google::Cloud::Discoveryengine::V1alpha::Engine;
use Google::Cloud::Discoveryengine::V1alpha::Control;
use Google::Cloud::Discoveryengine::V1alpha::SchemaService;
use Google::Cloud::Discoveryengine::V1alpha::ChunkService;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1alpha::ProjectService;
use Google::Cloud::Discoveryengine::V1alpha::Session;
use Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1alpha::DataStore;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1alpha::RecommendationService;
use Google::Cloud::Discoveryengine::V1alpha::SearchService;
use Google::Cloud::Discoveryengine::V1alpha::ImportConfig;
use Google::Cloud::Discoveryengine::V1alpha::AclConfigService;
use Google::Cloud::Discoveryengine::V1alpha::EngineService;
use Google::Cloud::Discoveryengine::V1alpha::ControlService;
use Google::Cloud::Discoveryengine::V1alpha::DataStoreService;
use Google::Cloud::Discoveryengine::V1alpha::Conversation;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfig;
use Google::Cloud::Discoveryengine::V1alpha::Evaluation;
use Google::Cloud::Discoveryengine::V1alpha::SearchTuningService;
use Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService;
use Google::Cloud::Discoveryengine::V1alpha::PurgeConfig;
use Google::Cloud::Discoveryengine::V1alpha::SampleQueryService;
use Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfigService;
use Google::Cloud::Discoveryengine::V1alpha::EvaluationService;
use Google::Cloud::Discoveryengine::V1alpha::CompletionService;
use Google::Cloud::Discoveryengine::V1alpha::UserEventService;
use Google::Cloud::Discoveryengine::V1alpha::DocumentService;
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
1; # End of Google::Cloud::Discoveryengine::V1alpha::RankServiceClient

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::RankServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::RankServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1alpha::RankServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1alpha::RankServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1alpha::RankServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Discoveryengine::V1alpha::RankServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
