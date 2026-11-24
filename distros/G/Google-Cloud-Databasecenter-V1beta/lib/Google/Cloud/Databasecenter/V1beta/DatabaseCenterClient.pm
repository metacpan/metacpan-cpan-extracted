package Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Databasecenter::V1beta::SuspensionReason;
use Google::Cloud::Databasecenter::V1beta::OperationErrorType;
use Google::Cloud::Databasecenter::V1beta::MetricData;
use Google::Cloud::Databasecenter::V1beta::Product;
use Google::Cloud::Databasecenter::V1beta::Affiliation;
use Google::Cloud::Databasecenter::V1beta::MachineConfig;
use Google::Cloud::Databasecenter::V1beta::Maintenance;
use Google::Cloud::Databasecenter::V1beta::Signals;
use Google::Cloud::Databasecenter::V1beta::Service;

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

    my $target = 'databasecenter.googleapis.com:443';
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

sub query_products {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/QueryProducts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'QueryProducts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregate_fleet {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/AggregateFleet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'AggregateFleet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_database_resource_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/QueryDatabaseResourceGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'QueryDatabaseResourceGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregate_issue_stats {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/AggregateIssueStats',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'AggregateIssueStats',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregate_query_stats {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/AggregateQueryStats',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'AggregateQueryStats',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_issues {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.databasecenter.v1beta.DatabaseCenter/QueryIssues',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.databasecenter.v1beta.DatabaseCenter',
        method         => 'QueryIssues',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/databasecenter/v1beta/affiliation.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/machine_config.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/maintenance.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/metric_data.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/operation_error_type.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/product.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/service.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/signals.proto>

=item * C<googleapis/google/cloud/databasecenter/v1beta/suspension_reason.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Databasecenter::V1beta::DatabaseCenterClient->new(
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

=item * B<query_products>

    my $response = $client->query_products(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryProducts> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<aggregate_fleet>

    my $response = $client->aggregate_fleet(
        parent                   => $parent,
        filter                   => $filter,
        group_by                 => $group_by,
        order_by                 => $order_by,
        page_size                => $page_size,
        page_token               => $page_token,
        baseline_date            => $baseline_date,
    );

Calls the RPC method C<AggregateFleet> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<group_by> - C<string>

=item * C<order_by> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<baseline_date> - L<Google::Type::Date::Date>

=back

=item * B<query_database_resource_groups>

    my $response = $client->query_database_resource_groups(
        parent                   => $parent,
        filter                   => $filter,
        signal_type_groups       => [ ... ],
        signal_filters           => [ ... ],
        order_by                 => $order_by,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryDatabaseResourceGroups> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<signal_type_groups> - ArrayRef of L<Google::Cloud::Databasecenter::V1beta::Signals::SignalTypeGroup>

=item * C<signal_filters> - ArrayRef of L<Google::Cloud::Databasecenter::V1beta::Signals::SignalFilter>

=item * C<order_by> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<aggregate_issue_stats>

    my $response = $client->aggregate_issue_stats(
        parent                   => $parent,
        filter                   => $filter,
        signal_type_groups       => [ ... ],
        baseline_date            => $baseline_date,
    );

Calls the RPC method C<AggregateIssueStats> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<signal_type_groups> - ArrayRef of L<Google::Cloud::Databasecenter::V1beta::Signals::SignalTypeGroup>

=item * C<baseline_date> - L<Google::Type::Date::Date>

=back

=item * B<aggregate_query_stats>

    my $response = $client->aggregate_query_stats(
        parent                   => $parent,
        order_by                 => $order_by,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<AggregateQueryStats> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<order_by> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<query_issues>

    my $response = $client->query_issues(
        parent                   => $parent,
        filter                   => $filter,
        signal_products_filters  => [ ... ],
        order_by                 => $order_by,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryIssues> on C<google.cloud.databasecenter.v1beta.DatabaseCenter>.

Request: L<Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest>

Returns: L<Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<signal_products_filters> - ArrayRef of L<Google::Cloud::Databasecenter::V1beta::Service::SignalProductsFilters>

=item * C<order_by> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
