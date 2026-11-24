package Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient;

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

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteZoneVmExtensionPolicyRequest';
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
            path           => '/google.cloud.compute.v1.ZoneVmExtensionPolicies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ZoneVmExtensionPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetZoneVmExtensionPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::VmExtensionPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.ZoneVmExtensionPolicies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ZoneVmExtensionPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertZoneVmExtensionPolicyRequest';
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
            path           => '/google.cloud.compute.v1.ZoneVmExtensionPolicies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ZoneVmExtensionPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListZoneVmExtensionPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::VmExtensionPolicyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.ZoneVmExtensionPolicies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ZoneVmExtensionPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateZoneVmExtensionPolicyRequest';
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
            path           => '/google.cloud.compute.v1.ZoneVmExtensionPolicies/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ZoneVmExtensionPolicies',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient->new(
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

=item * B<delete>

    my $response = $client->delete(
        project                  => $project,
        request_id               => $request_id,
        vm_extension_policy      => $vm_extension_policy,
        zone                     => $zone,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.ZoneVmExtensionPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteZoneVmExtensionPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<vm_extension_policy> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        vm_extension_policy      => $vm_extension_policy,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.ZoneVmExtensionPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetZoneVmExtensionPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::VmExtensionPolicy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<vm_extension_policy> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        request_id               => $request_id,
        vm_extension_policy_resource => $vm_extension_policy_resource,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.ZoneVmExtensionPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertZoneVmExtensionPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<vm_extension_policy_resource> - L<Google::Cloud::Compute::V1::Compute::VmExtensionPolicy>

=item * C<zone> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.ZoneVmExtensionPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListZoneVmExtensionPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::VmExtensionPolicyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        project                  => $project,
        request_id               => $request_id,
        vm_extension_policy      => $vm_extension_policy,
        vm_extension_policy_resource => $vm_extension_policy_resource,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1.ZoneVmExtensionPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateZoneVmExtensionPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<vm_extension_policy> - C<string>

=item * C<vm_extension_policy_resource> - L<Google::Cloud::Compute::V1::Compute::VmExtensionPolicy>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
