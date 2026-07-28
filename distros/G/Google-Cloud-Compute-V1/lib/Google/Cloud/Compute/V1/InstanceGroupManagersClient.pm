package Google::Cloud::Compute::V1::InstanceGroupManagersClient;

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

sub abandon_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AbandonInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'AbandonInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagerAggregatedList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub apply_updates_to_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ApplyUpdatesToInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'ApplyUpdatesToInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CreateInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'CreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'DeleteInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeletePerInstanceConfigsInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'DeletePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManager';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagerList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_errors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListErrorsInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListErrorsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'ListErrors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_managed_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListManagedInstancesInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListManagedInstancesResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'ListManagedInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListPerInstanceConfigsInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListPerInstanceConfigsResp';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'ListPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchPerInstanceConfigsInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'PatchPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recreate_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RecreateInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'RecreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResizeInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResumeInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'ResumeInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_instance_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetInstanceTemplateInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'SetInstanceTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_target_pools {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetTargetPoolsInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'SetTargetPools',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'StartInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'StopInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SuspendInstancesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'SuspendInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdatePerInstanceConfigsInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroupManagers',
        method         => 'UpdatePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::InstanceGroupManagersClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::InstanceGroupManagersClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::InstanceGroupManagersClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::InstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::InstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::InstanceGroupManagersClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::InstanceGroupManagersClient->new(
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

=item * B<abandon_instances>

Calls the RPC method C<AbandonInstances> on the service. Takes a hash of parameters representing the request.

=item * B<aggregated_list>

Calls the RPC method C<AggregatedList> on the service. Takes a hash of parameters representing the request.

=item * B<apply_updates_to_instances>

Calls the RPC method C<ApplyUpdatesToInstances> on the service. Takes a hash of parameters representing the request.

=item * B<create_instances>

Calls the RPC method C<CreateInstances> on the service. Takes a hash of parameters representing the request.

=item * B<delete>

Calls the RPC method C<Delete> on the service. Takes a hash of parameters representing the request.

=item * B<delete_instances>

Calls the RPC method C<DeleteInstances> on the service. Takes a hash of parameters representing the request.

=item * B<delete_per_instance_configs>

Calls the RPC method C<DeletePerInstanceConfigs> on the service. Takes a hash of parameters representing the request.

=item * B<get>

Calls the RPC method C<Get> on the service. Takes a hash of parameters representing the request.

=item * B<insert>

Calls the RPC method C<Insert> on the service. Takes a hash of parameters representing the request.

=item * B<list>

Calls the RPC method C<List> on the service. Takes a hash of parameters representing the request.

=item * B<list_errors>

Calls the RPC method C<ListErrors> on the service. Takes a hash of parameters representing the request.

=item * B<list_managed_instances>

Calls the RPC method C<ListManagedInstances> on the service. Takes a hash of parameters representing the request.

=item * B<list_per_instance_configs>

Calls the RPC method C<ListPerInstanceConfigs> on the service. Takes a hash of parameters representing the request.

=item * B<patch>

Calls the RPC method C<Patch> on the service. Takes a hash of parameters representing the request.

=item * B<patch_per_instance_configs>

Calls the RPC method C<PatchPerInstanceConfigs> on the service. Takes a hash of parameters representing the request.

=item * B<recreate_instances>

Calls the RPC method C<RecreateInstances> on the service. Takes a hash of parameters representing the request.

=item * B<resize>

Calls the RPC method C<Resize> on the service. Takes a hash of parameters representing the request.

=item * B<resume_instances>

Calls the RPC method C<ResumeInstances> on the service. Takes a hash of parameters representing the request.

=item * B<set_instance_template>

Calls the RPC method C<SetInstanceTemplate> on the service. Takes a hash of parameters representing the request.

=item * B<set_target_pools>

Calls the RPC method C<SetTargetPools> on the service. Takes a hash of parameters representing the request.

=item * B<start_instances>

Calls the RPC method C<StartInstances> on the service. Takes a hash of parameters representing the request.

=item * B<stop_instances>

Calls the RPC method C<StopInstances> on the service. Takes a hash of parameters representing the request.

=item * B<suspend_instances>

Calls the RPC method C<SuspendInstances> on the service. Takes a hash of parameters representing the request.

=item * B<update_per_instance_configs>

Calls the RPC method C<UpdatePerInstanceConfigs> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
