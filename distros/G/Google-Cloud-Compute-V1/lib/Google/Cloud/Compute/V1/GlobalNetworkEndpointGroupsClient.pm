package Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient;

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

sub attach_network_endpoints {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AttachNetworkEndpointsGlobalNetworkEndpointGroupRequest';
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
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/AttachNetworkEndpoints',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'AttachNetworkEndpoints',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteGlobalNetworkEndpointGroupRequest';
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
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detach_network_endpoints {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DetachNetworkEndpointsGlobalNetworkEndpointGroupRequest';
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
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/DetachNetworkEndpoints',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'DetachNetworkEndpoints',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetGlobalNetworkEndpointGroupRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworkEndpointGroup';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertGlobalNetworkEndpointGroupRequest';
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
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListGlobalNetworkEndpointGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworkEndpointGroupList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_network_endpoints {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListNetworkEndpointsGlobalNetworkEndpointGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworkEndpointGroupsListNetworkEndpoints';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.GlobalNetworkEndpointGroups/ListNetworkEndpoints',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalNetworkEndpointGroups',
        method         => 'ListNetworkEndpoints',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient->new(
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

=item * B<attach_network_endpoints>

    my $response = $client->attach_network_endpoints(
        global_network_endpoint_groups_attach_endpoints_request_resource => $global_network_endpoint_groups_attach_endpoints_request_resource,
        network_endpoint_group   => $network_endpoint_group,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<AttachNetworkEndpoints> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::AttachNetworkEndpointsGlobalNetworkEndpointGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<global_network_endpoint_groups_attach_endpoints_request_resource> - L<Google::Cloud::Compute::V1::Compute::GlobalNetworkEndpointGroupsAttachEndpointsRequest>

=item * C<network_endpoint_group> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        network_endpoint_group   => $network_endpoint_group,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteGlobalNetworkEndpointGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network_endpoint_group> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<detach_network_endpoints>

    my $response = $client->detach_network_endpoints(
        global_network_endpoint_groups_detach_endpoints_request_resource => $global_network_endpoint_groups_detach_endpoints_request_resource,
        network_endpoint_group   => $network_endpoint_group,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<DetachNetworkEndpoints> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::DetachNetworkEndpointsGlobalNetworkEndpointGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<global_network_endpoint_groups_detach_endpoints_request_resource> - L<Google::Cloud::Compute::V1::Compute::GlobalNetworkEndpointGroupsDetachEndpointsRequest>

=item * C<network_endpoint_group> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        network_endpoint_group   => $network_endpoint_group,
        project                  => $project,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::GetGlobalNetworkEndpointGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NetworkEndpointGroup>

Parameters:

=over 4

=item * C<network_endpoint_group> - C<string>

=item * C<project> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        network_endpoint_group_resource => $network_endpoint_group_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertGlobalNetworkEndpointGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network_endpoint_group_resource> - L<Google::Cloud::Compute::V1::Compute::NetworkEndpointGroup>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::ListGlobalNetworkEndpointGroupsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NetworkEndpointGroupList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<list_network_endpoints>

    my $response = $client->list_network_endpoints(
        filter                   => $filter,
        max_results              => $max_results,
        network_endpoint_group   => $network_endpoint_group,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<ListNetworkEndpoints> on C<google.cloud.compute.v1.GlobalNetworkEndpointGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::ListNetworkEndpointsGlobalNetworkEndpointGroupsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NetworkEndpointGroupsListNetworkEndpoints>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<network_endpoint_group> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
