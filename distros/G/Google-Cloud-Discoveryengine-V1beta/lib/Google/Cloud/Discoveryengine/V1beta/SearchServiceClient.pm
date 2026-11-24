package Google::Cloud::Discoveryengine::V1beta::SearchServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Discoveryengine::V1beta::Grounding;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySet;
use Google::Cloud::Discoveryengine::V1beta::SampleQuery;
use Google::Cloud::Discoveryengine::V1beta::UserStore;
use Google::Cloud::Discoveryengine::V1beta::Safety;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngine;
use Google::Cloud::Discoveryengine::V1beta::CustomTuningModel;
use Google::Cloud::Discoveryengine::V1beta::Completion;
use Google::Cloud::Discoveryengine::V1beta::DocumentProcessingConfig;
use Google::Cloud::Discoveryengine::V1beta::Logging;
use Google::Cloud::Discoveryengine::V1beta::Assistant;
use Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting;
use Google::Cloud::Discoveryengine::V1beta::Common;
use Google::Cloud::Discoveryengine::V1beta::UserLicense;
use Google::Cloud::Discoveryengine::V1beta::RankService;
use Google::Cloud::Discoveryengine::V1beta::Schema;
use Google::Cloud::Discoveryengine::V1beta::Chunk;
use Google::Cloud::Discoveryengine::V1beta::CmekConfigService;
use Google::Cloud::Discoveryengine::V1beta::GroundedGenerationService;
use Google::Cloud::Discoveryengine::V1beta::SampleQuerySetService;
use Google::Cloud::Discoveryengine::V1beta::UserStoreService;
use Google::Cloud::Discoveryengine::V1beta::Answer;
use Google::Cloud::Discoveryengine::V1beta::SiteSearchEngineService;
use Google::Cloud::Discoveryengine::V1beta::Project;
use Google::Cloud::Discoveryengine::V1beta::Document;
use Google::Cloud::Discoveryengine::V1beta::Control;
use Google::Cloud::Discoveryengine::V1beta::AclConfig;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfig;
use Google::Cloud::Discoveryengine::V1beta::UserLicenseService;
use Google::Cloud::Discoveryengine::V1beta::SchemaService;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStore;
use Google::Cloud::Discoveryengine::V1beta::Engine;
use Google::Cloud::Discoveryengine::V1beta::DataStore;
use Google::Cloud::Discoveryengine::V1beta::AssistAnswer;
use Google::Cloud::Discoveryengine::V1beta::ProjectService;
use Google::Cloud::Discoveryengine::V1beta::SearchService;
use Google::Cloud::Discoveryengine::V1beta::ControlService;
use Google::Cloud::Discoveryengine::V1beta::AclConfigService;
use Google::Cloud::Discoveryengine::V1beta::LicenseConfigService;
use Google::Cloud::Discoveryengine::V1beta::IdentityMappingStoreService;
use Google::Cloud::Discoveryengine::V1beta::EngineService;
use Google::Cloud::Discoveryengine::V1beta::DataStoreService;
use Google::Cloud::Discoveryengine::V1beta::Session;
use Google::Cloud::Discoveryengine::V1beta::Conversation;
use Google::Cloud::Discoveryengine::V1beta::ServingConfig;
use Google::Cloud::Discoveryengine::V1beta::Evaluation;
use Google::Cloud::Discoveryengine::V1beta::AssistantService;
use Google::Cloud::Discoveryengine::V1beta::Feedback;
use Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService;
use Google::Cloud::Discoveryengine::V1beta::ServingConfigService;
use Google::Cloud::Discoveryengine::V1beta::EvaluationService;
use Google::Cloud::Discoveryengine::V1beta::UserEvent;
use Google::Cloud::Discoveryengine::V1beta::SessionService;
use Google::Cloud::Discoveryengine::V1beta::ImportConfig;
use Google::Cloud::Discoveryengine::V1beta::RecommendationService;
use Google::Cloud::Discoveryengine::V1beta::SearchTuningService;
use Google::Cloud::Discoveryengine::V1beta::SampleQueryService;
use Google::Cloud::Discoveryengine::V1beta::PurgeConfig;
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
1; # End of Google::Cloud::Discoveryengine::V1beta::SearchServiceClient

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::SearchServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::SearchServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Discoveryengine::V1beta::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Discoveryengine::V1beta::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Discoveryengine::V1beta::SearchServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Discoveryengine::V1beta::SearchServiceClient->new(
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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
