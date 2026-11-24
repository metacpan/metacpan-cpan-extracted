package Google::Cloud::Retail::V2beta::SearchServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Retail::V2beta::Promotion;
use Google::Cloud::Retail::V2beta::GenerativeQuestion;
use Google::Cloud::Retail::V2beta::PurgeConfig;
use Google::Cloud::Retail::V2beta::Safety;
use Google::Cloud::Retail::V2beta::ExportConfig;
use Google::Cloud::Retail::V2beta::Project;
use Google::Cloud::Retail::V2beta::Common;
use Google::Cloud::Retail::V2beta::GenerativeQuestionService;
use Google::Cloud::Retail::V2beta::AnalyticsService;
use Google::Cloud::Retail::V2beta::ProjectService;
use Google::Cloud::Retail::V2beta::Product;
use Google::Cloud::Retail::V2beta::Model;
use Google::Cloud::Retail::V2beta::SearchService;
use Google::Cloud::Retail::V2beta::UserEvent;
use Google::Cloud::Retail::V2beta::ModelService;
use Google::Cloud::Retail::V2beta::ConversationalSearchService;
use Google::Cloud::Retail::V2beta::Control;
use Google::Cloud::Retail::V2beta::ServingConfig;
use Google::Cloud::Retail::V2beta::ImportConfig;
use Google::Cloud::Retail::V2beta::PredictionService;
use Google::Cloud::Retail::V2beta::ControlService;
use Google::Cloud::Retail::V2beta::ServingConfigService;
use Google::Cloud::Retail::V2beta::ProductService;
use Google::Cloud::Retail::V2beta::CompletionService;
use Google::Cloud::Retail::V2beta::Catalog;
use Google::Cloud::Retail::V2beta::UserEventService;
use Google::Cloud::Retail::V2beta::CatalogService;

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

    my $target = 'retail.googleapis.com:443';
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

    my $request_class = 'Google::Cloud::Retail::V2beta::SearchService::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Retail::V2beta::SearchService::SearchResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.retail.v2beta.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.retail.v2beta.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Retail::V2beta::SearchServiceClient

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::SearchServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::SearchServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Retail::V2beta::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Retail::V2beta::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Retail::V2beta::SearchServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/retail/v2beta/analytics_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/catalog.proto>

=item * C<googleapis/google/cloud/retail/v2beta/catalog_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/common.proto>

=item * C<googleapis/google/cloud/retail/v2beta/completion_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/control.proto>

=item * C<googleapis/google/cloud/retail/v2beta/control_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/conversational_search_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/export_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/generative_question.proto>

=item * C<googleapis/google/cloud/retail/v2beta/generative_question_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/import_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/model.proto>

=item * C<googleapis/google/cloud/retail/v2beta/model_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/prediction_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/product.proto>

=item * C<googleapis/google/cloud/retail/v2beta/product_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/project.proto>

=item * C<googleapis/google/cloud/retail/v2beta/project_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/promotion.proto>

=item * C<googleapis/google/cloud/retail/v2beta/purge_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/safety.proto>

=item * C<googleapis/google/cloud/retail/v2beta/search_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/serving_config.proto>

=item * C<googleapis/google/cloud/retail/v2beta/serving_config_service.proto>

=item * C<googleapis/google/cloud/retail/v2beta/user_event.proto>

=item * C<googleapis/google/cloud/retail/v2beta/user_event_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Retail::V2beta::SearchServiceClient->new(
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
        placement                => $placement,
        branch                   => $branch,
        query                    => $query,
        visitor_id               => $visitor_id,
        user_info                => $user_info,
        page_size                => $page_size,
        page_token               => $page_token,
        offset                   => $offset,
        filter                   => $filter,
        canonical_filter         => $canonical_filter,
        order_by                 => $order_by,
        facet_specs              => [ ... ],
        dynamic_facet_spec       => $dynamic_facet_spec,
        boost_spec               => $boost_spec,
        query_expansion_spec     => $query_expansion_spec,
        variant_rollup_keys      => [ ... ],
        page_categories          => [ ... ],
        search_mode              => $search_mode,
        personalization_spec     => $personalization_spec,
        labels                   => { ... },
        spell_correction_spec    => $spell_correction_spec,
        entity                   => $entity,
        conversational_search_spec => $conversational_search_spec,
        tile_navigation_spec     => $tile_navigation_spec,
        language_code            => $language_code,
        region_code              => $region_code,
        place_id                 => $place_id,
        user_attributes          => { ... },
    );

Calls the RPC method C<Search> on C<google.cloud.retail.v2beta.SearchService>.

Request: L<Google::Cloud::Retail::V2beta::SearchService::SearchRequest>

Returns: L<Google::Cloud::Retail::V2beta::SearchService::SearchResponse>

Parameters:

=over 4

=item * C<placement> - C<string>

=item * C<branch> - C<string>

=item * C<query> - C<string>

=item * C<visitor_id> - C<string>

=item * C<user_info> - L<Google::Cloud::Retail::V2beta::Common::UserInfo>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<offset> - C<int32>

=item * C<filter> - C<string>

=item * C<canonical_filter> - C<string>

=item * C<order_by> - C<string>

=item * C<facet_specs> - ArrayRef of L<Google::Cloud::Retail::V2beta::SearchService::FacetSpec>

=item * C<dynamic_facet_spec> - L<Google::Cloud::Retail::V2beta::SearchService::DynamicFacetSpec>

=item * C<boost_spec> - L<Google::Cloud::Retail::V2beta::SearchService::BoostSpec>

=item * C<query_expansion_spec> - L<Google::Cloud::Retail::V2beta::SearchService::QueryExpansionSpec>

=item * C<variant_rollup_keys> - ArrayRef of C<string>

=item * C<page_categories> - ArrayRef of C<string>

=item * C<search_mode> - L<Google::Cloud::Retail::V2beta::SearchService::SearchMode>

=item * C<personalization_spec> - L<Google::Cloud::Retail::V2beta::SearchService::PersonalizationSpec>

=item * C<labels> - C<map<string, string>> (HashRef)

=item * C<spell_correction_spec> - L<Google::Cloud::Retail::V2beta::SearchService::SpellCorrectionSpec>

=item * C<entity> - C<string>

=item * C<conversational_search_spec> - L<Google::Cloud::Retail::V2beta::SearchService::ConversationalSearchSpec>

=item * C<tile_navigation_spec> - L<Google::Cloud::Retail::V2beta::SearchService::TileNavigationSpec>

=item * C<language_code> - C<string>

=item * C<region_code> - C<string>

=item * C<place_id> - C<string>

=item * C<user_attributes> - C<map<string, StringList>> (HashRef)

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
