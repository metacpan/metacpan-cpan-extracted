package Google::Cloud::Compute::V1::RegionDisksClient;

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

our $VERSION = '0.02';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = 'localhost:50051';
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
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub add_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddResourcePoliciesRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'AddResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bulk_insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::BulkInsertRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'BulkInsert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_snapshot {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CreateSnapshotRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'CreateSnapshot',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Disk';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetIamPolicyRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRegionDisksRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::DiskList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveResourcePoliciesRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'RemoveResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResizeRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetIamPolicyRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetLabelsRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'SetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartAsyncReplicationRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'StartAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopAsyncReplicationRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'StopAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_group_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopGroupAsyncReplicationRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'StopGroupAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_kms_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateKmsKeyRegionDiskRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionDisks',
        method         => 'UpdateKmsKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::RegionDisksClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::RegionDisksClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::RegionDisksClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::RegionDisksClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::RegionDisksClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::RegionDisksClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::RegionDisksClient->new(
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

=item * B<add_resource_policies>

Calls the RPC method C<AddResourcePolicies> on the service. Takes a hash of parameters representing the request.

=item * B<bulk_insert>

Calls the RPC method C<BulkInsert> on the service. Takes a hash of parameters representing the request.

=item * B<create_snapshot>

Calls the RPC method C<CreateSnapshot> on the service. Takes a hash of parameters representing the request.

=item * B<delete>

Calls the RPC method C<Delete> on the service. Takes a hash of parameters representing the request.

=item * B<get>

Calls the RPC method C<Get> on the service. Takes a hash of parameters representing the request.

=item * B<get_iam_policy>

Calls the RPC method C<GetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<insert>

Calls the RPC method C<Insert> on the service. Takes a hash of parameters representing the request.

=item * B<list>

Calls the RPC method C<List> on the service. Takes a hash of parameters representing the request.

=item * B<remove_resource_policies>

Calls the RPC method C<RemoveResourcePolicies> on the service. Takes a hash of parameters representing the request.

=item * B<resize>

Calls the RPC method C<Resize> on the service. Takes a hash of parameters representing the request.

=item * B<set_iam_policy>

Calls the RPC method C<SetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<set_labels>

Calls the RPC method C<SetLabels> on the service. Takes a hash of parameters representing the request.

=item * B<start_async_replication>

Calls the RPC method C<StartAsyncReplication> on the service. Takes a hash of parameters representing the request.

=item * B<stop_async_replication>

Calls the RPC method C<StopAsyncReplication> on the service. Takes a hash of parameters representing the request.

=item * B<stop_group_async_replication>

Calls the RPC method C<StopGroupAsyncReplication> on the service. Takes a hash of parameters representing the request.

=item * B<test_iam_permissions>

Calls the RPC method C<TestIamPermissions> on the service. Takes a hash of parameters representing the request.

=item * B<update>

Calls the RPC method C<Update> on the service. Takes a hash of parameters representing the request.

=item * B<update_kms_key>

Calls the RPC method C<UpdateKmsKey> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
