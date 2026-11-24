package Google::Cloud::Asset::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Asset::V1::AssetEnrichmentResourceowners;
use Google::Cloud::Asset::V1::Assets;
use Google::Cloud::Asset::V1::AssetService;

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

    my $target = 'cloudasset.googleapis.com:443';
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

sub export_assets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest';
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
            path           => '/google.cloud.asset.v1.AssetService/ExportAssets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'ExportAssets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_get_assets_history {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/BatchGetAssetsHistory',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'BatchGetAssetsHistory',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_feed {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::GetFeedRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::Feed';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/GetFeed',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'GetFeed',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_feed {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::Feed';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/UpdateFeed',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'UpdateFeed',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_all_iam_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/SearchAllIamPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'SearchAllIamPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_iam_policy_longrunning {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest';
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
            path           => '/google.cloud.asset.v1.AssetService/AnalyzeIamPolicyLongrunning',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'AnalyzeIamPolicyLongrunning',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_assets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/QueryAssets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'QueryAssets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_saved_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::SavedQuery';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/GetSavedQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'GetSavedQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_saved_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::SavedQuery';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/UpdateSavedQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'UpdateSavedQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_org_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/AnalyzeOrgPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'AnalyzeOrgPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_org_policy_governed_assets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.asset.v1.AssetService/AnalyzeOrgPolicyGovernedAssets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.asset.v1.AssetService',
        method         => 'AnalyzeOrgPolicyGovernedAssets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Asset::V1

__END__

=head1 NAME

Google::Cloud::Asset::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Asset::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Asset::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Asset::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Asset::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/asset/v1/asset_enrichment_resourceowners.proto>

=item * C<googleapis/google/cloud/asset/v1/asset_service.proto>

=item * C<googleapis/google/cloud/asset/v1/assets.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Asset::V1->new(
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

=item * B<export_assets>

    my $response = $client->export_assets(
        parent                   => $parent,
        read_time                => $read_time,
        asset_types              => [ ... ],
        content_type             => $content_type,
        output_config            => $output_config,
        relationship_types       => [ ... ],
    );

Calls the RPC method C<ExportAssets> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::ExportAssetsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<read_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<asset_types> - ArrayRef of C<string>

=item * C<content_type> - L<Google::Cloud::Asset::V1::AssetService::ContentType>

=item * C<output_config> - L<Google::Cloud::Asset::V1::AssetService::OutputConfig>

=item * C<relationship_types> - ArrayRef of C<string>

=back

=item * B<batch_get_assets_history>

    my $response = $client->batch_get_assets_history(
        parent                   => $parent,
        asset_names              => [ ... ],
        content_type             => $content_type,
        read_time_window         => $read_time_window,
        relationship_types       => [ ... ],
    );

Calls the RPC method C<BatchGetAssetsHistory> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::BatchGetAssetsHistoryResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<asset_names> - ArrayRef of C<string>

=item * C<content_type> - L<Google::Cloud::Asset::V1::AssetService::ContentType>

=item * C<read_time_window> - L<Google::Cloud::Asset::V1::Assets::TimeWindow>

=item * C<relationship_types> - ArrayRef of C<string>

=back

=item * B<get_feed>

    my $response = $client->get_feed(
        name                     => $name,
    );

Calls the RPC method C<GetFeed> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::GetFeedRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::Feed>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_feed>

    my $response = $client->update_feed(
        feed                     => $feed,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateFeed> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::UpdateFeedRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::Feed>

Parameters:

=over 4

=item * C<feed> - L<Google::Cloud::Asset::V1::AssetService::Feed>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<search_all_iam_policies>

    my $response = $client->search_all_iam_policies(
        scope                    => $scope,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
        asset_types              => [ ... ],
        order_by                 => $order_by,
    );

Calls the RPC method C<SearchAllIamPolicies> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::SearchAllIamPoliciesResponse>

Parameters:

=over 4

=item * C<scope> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<asset_types> - ArrayRef of C<string>

=item * C<order_by> - C<string>

=back

=item * B<analyze_iam_policy_longrunning>

    my $response = $client->analyze_iam_policy_longrunning(
        analysis_query           => $analysis_query,
        saved_analysis_query     => $saved_analysis_query,
        output_config            => $output_config,
    );

Calls the RPC method C<AnalyzeIamPolicyLongrunning> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::AnalyzeIamPolicyLongrunningRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<analysis_query> - L<Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisQuery>

=item * C<saved_analysis_query> - C<string>

=item * C<output_config> - L<Google::Cloud::Asset::V1::AssetService::IamPolicyAnalysisOutputConfig>

=back

=item * B<query_assets>

    my $response = $client->query_assets(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        timeout                  => $timeout,
        output_config            => $output_config,
    );

Calls the RPC method C<QueryAssets> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::QueryAssetsRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::QueryAssetsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<timeout> - L<Google::Protobuf::Duration::Duration>

=item * C<output_config> - L<Google::Cloud::Asset::V1::AssetService::QueryAssetsOutputConfig>

=back

=item * B<get_saved_query>

    my $response = $client->get_saved_query(
        name                     => $name,
    );

Calls the RPC method C<GetSavedQuery> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::GetSavedQueryRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::SavedQuery>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_saved_query>

    my $response = $client->update_saved_query(
        saved_query              => $saved_query,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateSavedQuery> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::UpdateSavedQueryRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::SavedQuery>

Parameters:

=over 4

=item * C<saved_query> - L<Google::Cloud::Asset::V1::AssetService::SavedQuery>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<analyze_org_policies>

    my $response = $client->analyze_org_policies(
        scope                    => $scope,
        constraint               => $constraint,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<AnalyzeOrgPolicies> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPoliciesResponse>

Parameters:

=over 4

=item * C<scope> - C<string>

=item * C<constraint> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<analyze_org_policy_governed_assets>

    my $response = $client->analyze_org_policy_governed_assets(
        scope                    => $scope,
        constraint               => $constraint,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<AnalyzeOrgPolicyGovernedAssets> on C<google.cloud.asset.v1.AssetService>.

Request: L<Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsRequest>

Returns: L<Google::Cloud::Asset::V1::AssetService::AnalyzeOrgPolicyGovernedAssetsResponse>

Parameters:

=over 4

=item * C<scope> - C<string>

=item * C<constraint> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
