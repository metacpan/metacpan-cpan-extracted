package Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

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

    my $target = 'compute/v1.googleapis.com:443';
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

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListRegionHealthAggregationPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::HealthAggregationPolicyAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRegionHealthAggregationPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRegionHealthAggregationPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::HealthAggregationPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertRegionHealthAggregationPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRegionHealthAggregationPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::HealthAggregationPolicyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRegionHealthAggregationPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsRegionHealthAggregationPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionHealthAggregationPolicies/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionHealthAggregationPolicies',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient->new(
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

=item * B<aggregated_list>

    my $response = $client->aggregated_list(
        filter                   => $filter,
        include_all_scopes       => $include_all_scopes,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        service_project_number   => $service_project_number,
    );

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AggregatedListRegionHealthAggregationPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::HealthAggregationPolicyAggregatedList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<include_all_scopes> - C<bool>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<service_project_number> - C<int64>

=back

=item * B<delete>

    my $response = $client->delete(
        health_aggregation_policy => $health_aggregation_policy,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRegionHealthAggregationPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<health_aggregation_policy> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        health_aggregation_policy => $health_aggregation_policy,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRegionHealthAggregationPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::HealthAggregationPolicy>

Parameters:

=over 4

=item * C<health_aggregation_policy> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        health_aggregation_policy_resource => $health_aggregation_policy_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertRegionHealthAggregationPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<health_aggregation_policy_resource> - L<Google::Cloud::Compute::V1::Compute::HealthAggregationPolicy>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRegionHealthAggregationPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::HealthAggregationPolicyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        health_aggregation_policy => $health_aggregation_policy,
        health_aggregation_policy_resource => $health_aggregation_policy_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRegionHealthAggregationPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<health_aggregation_policy> - C<string>

=item * C<health_aggregation_policy_resource> - L<Google::Cloud::Compute::V1::Compute::HealthAggregationPolicy>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        region                   => $region,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1.RegionHealthAggregationPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::TestIamPermissionsRegionHealthAggregationPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1::Compute::TestPermissionsRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
