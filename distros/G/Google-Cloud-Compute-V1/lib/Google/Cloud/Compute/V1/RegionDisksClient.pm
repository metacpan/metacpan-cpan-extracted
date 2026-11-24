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

sub add_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddResourcePoliciesRegionDiskRequest';
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
            path           => '/google.cloud.compute.v1.RegionDisks/AddResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/BulkInsert',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/CreateSnapshot',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Disk';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionDisks/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionDisks/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::DiskList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionDisks/List',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/RemoveResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionDisks/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/SetLabels',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/StartAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/StopAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/StopGroupAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.RegionDisks/UpdateKmsKey',
            request        => $request,
            response_class => $response_class,
        });
    }

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

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



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

    my $response = $client->add_resource_policies(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        region_disks_add_resource_policies_request_resource => $region_disks_add_resource_policies_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<AddResourcePolicies> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::AddResourcePoliciesRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_disks_add_resource_policies_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionDisksAddResourcePoliciesRequest>

=item * C<request_id> - C<string>

=back

=item * B<bulk_insert>

    my $response = $client->bulk_insert(
        bulk_insert_disk_resource_resource => $bulk_insert_disk_resource_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<BulkInsert> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::BulkInsertRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<bulk_insert_disk_resource_resource> - L<Google::Cloud::Compute::V1::Compute::BulkInsertDiskResource>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<create_snapshot>

    my $response = $client->create_snapshot(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        snapshot_resource        => $snapshot_resource,
    );

Calls the RPC method C<CreateSnapshot> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::CreateSnapshotRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<snapshot_resource> - L<Google::Cloud::Compute::V1::Compute::Snapshot>

=back

=item * B<delete>

    my $response = $client->delete(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Disk>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        region                   => $region,
        resource                 => $resource,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetIamPolicyRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        disk_resource            => $disk_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        source_image             => $source_image,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk_resource> - L<Google::Cloud::Compute::V1::Compute::Disk>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<source_image> - C<string>

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

Calls the RPC method C<List> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRegionDisksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::DiskList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<remove_resource_policies>

    my $response = $client->remove_resource_policies(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        region_disks_remove_resource_policies_request_resource => $region_disks_remove_resource_policies_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveResourcePolicies> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveResourcePoliciesRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_disks_remove_resource_policies_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionDisksRemoveResourcePoliciesRequest>

=item * C<request_id> - C<string>

=back

=item * B<resize>

    my $response = $client->resize(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        region_disks_resize_request_resource => $region_disks_resize_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<Resize> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::ResizeRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_disks_resize_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionDisksResizeRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        project                  => $project,
        region                   => $region,
        region_set_policy_request_resource => $region_set_policy_request_resource,
        resource                 => $resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::SetIamPolicyRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_set_policy_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionSetPolicyRequest>

=item * C<resource> - C<string>

=back

=item * B<set_labels>

    my $response = $client->set_labels(
        project                  => $project,
        region                   => $region,
        region_set_labels_request_resource => $region_set_labels_request_resource,
        request_id               => $request_id,
        resource                 => $resource,
    );

Calls the RPC method C<SetLabels> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::SetLabelsRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_set_labels_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionSetLabelsRequest>

=item * C<request_id> - C<string>

=item * C<resource> - C<string>

=back

=item * B<start_async_replication>

    my $response = $client->start_async_replication(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        region_disks_start_async_replication_request_resource => $region_disks_start_async_replication_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<StartAsyncReplication> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::StartAsyncReplicationRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_disks_start_async_replication_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionDisksStartAsyncReplicationRequest>

=item * C<request_id> - C<string>

=back

=item * B<stop_async_replication>

    my $response = $client->stop_async_replication(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<StopAsyncReplication> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::StopAsyncReplicationRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<stop_group_async_replication>

    my $response = $client->stop_group_async_replication(
        disks_stop_group_async_replication_resource_resource => $disks_stop_group_async_replication_resource_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<StopGroupAsyncReplication> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::StopGroupAsyncReplicationRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disks_stop_group_async_replication_resource_resource> - L<Google::Cloud::Compute::V1::Compute::DisksStopGroupAsyncReplicationResource>

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

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::TestIamPermissionsRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1::Compute::TestPermissionsRequest>

=back

=item * B<update>

    my $response = $client->update(
        disk                     => $disk,
        disk_resource            => $disk_resource,
        paths                    => $paths,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        update_mask              => $update_mask,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disk_resource> - L<Google::Cloud::Compute::V1::Compute::Disk>

=item * C<paths> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<update_mask> - C<string>

=back

=item * B<update_kms_key>

    my $response = $client->update_kms_key(
        disk                     => $disk,
        project                  => $project,
        region                   => $region,
        region_disk_update_kms_key_request_resource => $region_disk_update_kms_key_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdateKmsKey> on C<google.cloud.compute.v1.RegionDisks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateKmsKeyRegionDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_disk_update_kms_key_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionDiskUpdateKmsKeyRequest>

=item * C<request_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
