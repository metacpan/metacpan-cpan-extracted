package Google::Cloud::Chronicle::V1::SearchServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Chronicle::V1::SimulatedData;
use Google::Cloud::Chronicle::V1::Event;
use Google::Cloud::Chronicle::V1::FeaturedContentMetadata;
use Google::Cloud::Chronicle::V1::Entity;
use Google::Cloud::Chronicle::V1::DataAccessControl;
use Google::Cloud::Chronicle::V1::Instance;
use Google::Cloud::Chronicle::V1::BigQueryExport;
use Google::Cloud::Chronicle::V1::FindingsRefinement;
use Google::Cloud::Chronicle::V1::DashboardQuery;
use Google::Cloud::Chronicle::V1::Feed;
use Google::Cloud::Chronicle::V1::ReferenceList;
use Google::Cloud::Chronicle::V1::Rule;
use Google::Cloud::Chronicle::V1::RuleExecutionError;
use Google::Cloud::Chronicle::V1::DataTable;
use Google::Cloud::Chronicle::V1::Search;
use Google::Cloud::Chronicle::V1::DashboardChart;
use Google::Cloud::Chronicle::V1::NativeDashboard;
use Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard;

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

    my $target = 'chronicle.googleapis.com:443';
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

    my $request_class = 'Google::Cloud::Chronicle::V1::Search::SearchRequest';
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
            path           => '/google.cloud.chronicle.v1.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Chronicle::V1::SearchServiceClient

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::SearchServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::SearchServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Chronicle::V1::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Chronicle::V1::SearchServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Chronicle::V1::SearchServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/chronicle/v1/big_query_export.proto>

=item * C<googleapis/google/cloud/chronicle/v1/dashboard_chart.proto>

=item * C<googleapis/google/cloud/chronicle/v1/dashboard_query.proto>

=item * C<googleapis/google/cloud/chronicle/v1/data_access_control.proto>

=item * C<googleapis/google/cloud/chronicle/v1/data_table.proto>

=item * C<googleapis/google/cloud/chronicle/v1/entity.proto>

=item * C<googleapis/google/cloud/chronicle/v1/event.proto>

=item * C<googleapis/google/cloud/chronicle/v1/featured_content_metadata.proto>

=item * C<googleapis/google/cloud/chronicle/v1/featured_content_native_dashboard.proto>

=item * C<googleapis/google/cloud/chronicle/v1/feed.proto>

=item * C<googleapis/google/cloud/chronicle/v1/findings_refinement.proto>

=item * C<googleapis/google/cloud/chronicle/v1/instance.proto>

=item * C<googleapis/google/cloud/chronicle/v1/native_dashboard.proto>

=item * C<googleapis/google/cloud/chronicle/v1/reference_list.proto>

=item * C<googleapis/google/cloud/chronicle/v1/rule.proto>

=item * C<googleapis/google/cloud/chronicle/v1/rule_execution_error.proto>

=item * C<googleapis/google/cloud/chronicle/v1/search.proto>

=item * C<googleapis/google/cloud/chronicle/v1/simulated_data.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Chronicle::V1::SearchServiceClient->new(
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
        parent                   => $parent,
        query                    => $query,
        time_range               => $time_range,
        dialect                  => $dialect,
        draft_data_access_scope  => $draft_data_access_scope,
        result_limit             => $result_limit,
        simulated_data_visibility => $simulated_data_visibility,
    );

Calls the RPC method C<Search> on C<google.cloud.chronicle.v1.SearchService>.

Request: L<Google::Cloud::Chronicle::V1::Search::SearchRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<query> - C<string>

=item * C<time_range> - L<Google::Type::Interval::Interval>

=item * C<dialect> - L<Google::Cloud::Chronicle::V1::Search::QueryDialect>

=item * C<draft_data_access_scope> - L<Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessScope>

=item * C<result_limit> - C<int32>

=item * C<simulated_data_visibility> - L<Google::Cloud::Chronicle::V1::Search::SimulatedDataVisibility>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
