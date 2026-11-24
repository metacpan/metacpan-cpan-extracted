package Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient;

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
use Google::Cloud::Discoveryengine::V1alpha::Completion;
use Google::Cloud::Discoveryengine::V1alpha::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1alpha::RankService;
use Google::Cloud::Discoveryengine::V1alpha::Grounding;
use Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1alpha::Answer;
use Google::Cloud::Discoveryengine::V1alpha::Project;
use Google::Cloud::Discoveryengine::V1alpha::Chunk;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1alpha::Schema;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuery;
use Google::Cloud::Discoveryengine::V1alpha::AclConfig;
use Google::Cloud::Discoveryengine::V1alpha::Engine;
use Google::Cloud::Discoveryengine::V1alpha::Control;
use Google::Cloud::Discoveryengine::V1alpha::Document;
use Google::Cloud::Discoveryengine::V1alpha::UserEvent;
use Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1alpha::Session;
use Google::Cloud::Discoveryengine::V1alpha::ProjectService;
use Google::Cloud::Discoveryengine::V1alpha::ChunkService;
use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1alpha::SchemaService;
use Google::Cloud::Discoveryengine::V1alpha::DataStore;
use Google::Cloud::Discoveryengine::V1alpha::AclConfigService;
use Google::Cloud::Discoveryengine::V1alpha::EngineService;
use Google::Cloud::Discoveryengine::V1alpha::ControlService;
use Google::Cloud::Discoveryengine::V1alpha::SearchService;
use Google::Cloud::Discoveryengine::V1alpha::ImportConfig;
use Google::Cloud::Discoveryengine::V1alpha::RecommendationService;
use Google::Cloud::Discoveryengine::V1alpha::DataStoreService;
use Google::Cloud::Discoveryengine::V1alpha::Evaluation;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfig;
use Google::Cloud::Discoveryengine::V1alpha::Conversation;
use Google::Cloud::Discoveryengine::V1alpha::SampleQueryService;
use Google::Cloud::Discoveryengine::V1alpha::PurgeConfig;
use Google::Cloud::Discoveryengine::V1alpha::EstimateBillingService;
use Google::Cloud::Discoveryengine::V1alpha::SearchTuningService;
use Google::Cloud::Discoveryengine::V1alpha::EvaluationService;
use Google::Cloud::Discoveryengine::V1alpha::ServingConfigService;
use Google::Cloud::Discoveryengine::V1alpha::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1alpha::UserEventService;
use Google::Cloud::Discoveryengine::V1alpha::DocumentService;
use Google::Cloud::Discoveryengine::V1alpha::CompletionService;
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
1; # End of Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Discoveryengine::V1alpha::SearchServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
