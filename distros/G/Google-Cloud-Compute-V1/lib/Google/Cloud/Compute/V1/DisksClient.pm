package Google::Cloud::Compute::V1::DisksClient;

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

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddResourcePoliciesDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/AddResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'AddResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListDisksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::DiskAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Disks/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bulk_insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::BulkInsertDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/BulkInsert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'BulkInsert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bulk_set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::BulkSetLabelsDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/BulkSetLabels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'BulkSetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_snapshot {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CreateSnapshotDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/CreateSnapshot',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'CreateSnapshot',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetIamPolicyDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListDisksRequest';
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
            path           => '/google.cloud.compute.v1.Disks/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveResourcePoliciesDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/RemoveResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'RemoveResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResizeDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetIamPolicyDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetLabelsDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/SetLabels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'SetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartAsyncReplicationDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/StartAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'StartAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopAsyncReplicationDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/StopAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'StopAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_group_async_replication {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopGroupAsyncReplicationDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/StopGroupAsyncReplication',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'StopGroupAsyncReplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_kms_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateKmsKeyDiskRequest';
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
            path           => '/google.cloud.compute.v1.Disks/UpdateKmsKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Disks',
        method         => 'UpdateKmsKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::DisksClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::DisksClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::DisksClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::DisksClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::DisksClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::DisksClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::DisksClient->new(
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
        disks_add_resource_policies_request_resource => $disks_add_resource_policies_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddResourcePolicies> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::AddResourcePoliciesDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disks_add_resource_policies_request_resource> - L<Google::Cloud::Compute::V1::Compute::DisksAddResourcePoliciesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::AggregatedListDisksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::DiskAggregatedList>

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

=item * B<bulk_insert>

    my $response = $client->bulk_insert(
        bulk_insert_disk_resource_resource => $bulk_insert_disk_resource_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<BulkInsert> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::BulkInsertDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<bulk_insert_disk_resource_resource> - L<Google::Cloud::Compute::V1::Compute::BulkInsertDiskResource>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<bulk_set_labels>

    my $response = $client->bulk_set_labels(
        bulk_zone_set_labels_request_resource => $bulk_zone_set_labels_request_resource,
        project                  => $project,
        request_id               => $request_id,
        resource                 => $resource,
        zone                     => $zone,
    );

Calls the RPC method C<BulkSetLabels> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::BulkSetLabelsDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<bulk_zone_set_labels_request_resource> - L<Google::Cloud::Compute::V1::Compute::BulkZoneSetLabelsRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=back

=item * B<create_snapshot>

    my $response = $client->create_snapshot(
        disk                     => $disk,
        guest_flush              => $guest_flush,
        project                  => $project,
        request_id               => $request_id,
        snapshot_resource        => $snapshot_resource,
        zone                     => $zone,
    );

Calls the RPC method C<CreateSnapshot> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::CreateSnapshotDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<guest_flush> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<snapshot_resource> - L<Google::Cloud::Compute::V1::Compute::Snapshot>

=item * C<zone> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        disk                     => $disk,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        disk                     => $disk,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Disk>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        resource                 => $resource,
        zone                     => $zone,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetIamPolicyDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        disk_resource            => $disk_resource,
        project                  => $project,
        request_id               => $request_id,
        source_image             => $source_image,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk_resource> - L<Google::Cloud::Compute::V1::Compute::Disk>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<source_image> - C<string>

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

Calls the RPC method C<List> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::ListDisksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::DiskList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<remove_resource_policies>

    my $response = $client->remove_resource_policies(
        disk                     => $disk,
        disks_remove_resource_policies_request_resource => $disks_remove_resource_policies_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<RemoveResourcePolicies> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveResourcePoliciesDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disks_remove_resource_policies_request_resource> - L<Google::Cloud::Compute::V1::Compute::DisksRemoveResourcePoliciesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<resize>

    my $response = $client->resize(
        disk                     => $disk,
        disks_resize_request_resource => $disks_resize_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Resize> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::ResizeDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disks_resize_request_resource> - L<Google::Cloud::Compute::V1::Compute::DisksResizeRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        project                  => $project,
        resource                 => $resource,
        zone                     => $zone,
        zone_set_policy_request_resource => $zone_set_policy_request_resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::SetIamPolicyDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=item * C<zone_set_policy_request_resource> - L<Google::Cloud::Compute::V1::Compute::ZoneSetPolicyRequest>

=back

=item * B<set_labels>

    my $response = $client->set_labels(
        project                  => $project,
        request_id               => $request_id,
        resource                 => $resource,
        zone                     => $zone,
        zone_set_labels_request_resource => $zone_set_labels_request_resource,
    );

Calls the RPC method C<SetLabels> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::SetLabelsDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=item * C<zone_set_labels_request_resource> - L<Google::Cloud::Compute::V1::Compute::ZoneSetLabelsRequest>

=back

=item * B<start_async_replication>

    my $response = $client->start_async_replication(
        disk                     => $disk,
        disks_start_async_replication_request_resource => $disks_start_async_replication_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StartAsyncReplication> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::StartAsyncReplicationDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disks_start_async_replication_request_resource> - L<Google::Cloud::Compute::V1::Compute::DisksStartAsyncReplicationRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<stop_async_replication>

    my $response = $client->stop_async_replication(
        disk                     => $disk,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StopAsyncReplication> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::StopAsyncReplicationDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<stop_group_async_replication>

    my $response = $client->stop_group_async_replication(
        disks_stop_group_async_replication_resource_resource => $disks_stop_group_async_replication_resource_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StopGroupAsyncReplication> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::StopGroupAsyncReplicationDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disks_stop_group_async_replication_resource_resource> - L<Google::Cloud::Compute::V1::Compute::DisksStopGroupAsyncReplicationResource>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
        zone                     => $zone,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::TestIamPermissionsDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1::Compute::TestPermissionsRequest>

=item * C<zone> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        disk                     => $disk,
        disk_resource            => $disk_resource,
        paths                    => $paths,
        project                  => $project,
        request_id               => $request_id,
        update_mask              => $update_mask,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disk_resource> - L<Google::Cloud::Compute::V1::Compute::Disk>

=item * C<paths> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<update_mask> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_kms_key>

    my $response = $client->update_kms_key(
        disk                     => $disk,
        disk_update_kms_key_request_resource => $disk_update_kms_key_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateKmsKey> on C<google.cloud.compute.v1.Disks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateKmsKeyDiskRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk> - C<string>

=item * C<disk_update_kms_key_request_resource> - L<Google::Cloud::Compute::V1::Compute::DiskUpdateKmsKeyRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
