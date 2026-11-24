package Google::Cloud::Compute::V1beta::InstancesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1beta::Compute;

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

    my $target = 'compute/v1beta.googleapis.com:443';
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

sub add_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/AddAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'AddAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/AddNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'AddNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddResourcePoliciesInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/AddResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'AddResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListInstancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub attach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AttachDiskInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/AttachDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'AttachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bulk_insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::BulkInsertInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/BulkInsert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'BulkInsert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/DeleteAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'DeleteAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/DeleteNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'DeleteNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DetachDiskInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/DetachDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'DetachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Instance';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_firewalls {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetEffectiveFirewallsInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstancesGetEffectiveFirewallsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetEffectiveFirewalls',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetEffectiveFirewalls',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_guest_attributes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetGuestAttributesInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::GuestAttributes';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetGuestAttributes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetGuestAttributes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_partner_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetPartnerMetadataInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::PartnerMetadata';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetPartnerMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetPartnerMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_screenshot {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetScreenshotInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Screenshot';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetScreenshot',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetScreenshot',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_serial_port_output {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetSerialPortOutputInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::SerialPortOutput';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetSerialPortOutput',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetSerialPortOutput',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_shielded_instance_identity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetShieldedInstanceIdentityInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIdentity';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetShieldedInstanceIdentity',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetShieldedInstanceIdentity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_shielded_vm_identity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetShieldedVmIdentityInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::ShieldedVmIdentity';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetShieldedVmIdentity',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetShieldedVmIdentity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_vm_extension_state {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetVmExtensionStateInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::VmExtensionState';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/GetVmExtensionState',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'GetVmExtensionState',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListInstancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_referrers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListReferrersInstancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceListReferrers';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/ListReferrers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'ListReferrers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_vm_extension_states {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesInstancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/ListVmExtensionStates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'ListVmExtensionStates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_partner_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchPartnerMetadataInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/PatchPartnerMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'PatchPartnerMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub perform_maintenance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PerformMaintenanceInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/PerformMaintenance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'PerformMaintenance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_resource_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveResourcePoliciesInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/RemoveResourcePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'RemoveResourcePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_host_as_faulty {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ReportHostAsFaultyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/ReportHostAsFaulty',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'ReportHostAsFaulty',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResetInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Reset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Reset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResumeInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Resume',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Resume',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub send_diagnostic_interrupt {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SendDiagnosticInterrupt',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SendDiagnosticInterrupt',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_deletion_protection {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetDeletionProtectionInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetDeletionProtection',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetDeletionProtection',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_disk_auto_delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetDiskAutoDeleteInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetDiskAutoDelete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetDiskAutoDelete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetLabelsInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetLabels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_resources {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetMachineResourcesInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetMachineResources',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetMachineResources',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetMachineTypeInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetMachineType',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetMachineType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetMetadataInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_min_cpu_platform {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetMinCpuPlatformInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetMinCpuPlatform',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetMinCpuPlatform',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_name {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetNameInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetName',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetName',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_scheduling {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetSchedulingInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetScheduling',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetScheduling',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_security_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetSecurityPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetSecurityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetSecurityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetServiceAccountInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetServiceAccount',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_shielded_instance_integrity_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetShieldedInstanceIntegrityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetShieldedInstanceIntegrityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_shielded_vm_integrity_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetShieldedVmIntegrityPolicyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetShieldedVmIntegrityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetShieldedVmIntegrityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_tags {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetTagsInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SetTags',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SetTags',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub simulate_maintenance_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SimulateMaintenanceEventInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/SimulateMaintenanceEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'SimulateMaintenanceEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::StartInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Start',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Start',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_with_encryption_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::StartWithEncryptionKeyInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/StartWithEncryptionKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'StartWithEncryptionKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::StopInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Stop',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Stop',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SuspendInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Suspend',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Suspend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateAccessConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/UpdateAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'UpdateAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_display_device {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateDisplayDeviceInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/UpdateDisplayDevice',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'UpdateDisplayDevice',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateNetworkInterfaceInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/UpdateNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'UpdateNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_shielded_instance_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateShieldedInstanceConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/UpdateShieldedInstanceConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'UpdateShieldedInstanceConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_shielded_vm_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateShieldedVmConfigInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Instances/UpdateShieldedVmConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Instances',
        method         => 'UpdateShieldedVmConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::InstancesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::InstancesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::InstancesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::InstancesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::InstancesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::InstancesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::InstancesClient->new(
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

=item * B<add_access_config>

    my $response = $client->add_access_config(
        access_config_resource   => $access_config_resource,
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddAccessConfig> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<access_config_resource> - L<Google::Cloud::Compute::V1beta::Compute::AccessConfig>

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<add_network_interface>

    my $response = $client->add_network_interface(
        instance                 => $instance,
        network_interface_resource => $network_interface_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddNetworkInterface> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface_resource> - L<Google::Cloud::Compute::V1beta::Compute::NetworkInterface>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<add_resource_policies>

    my $response = $client->add_resource_policies(
        instance                 => $instance,
        instances_add_resource_policies_request_resource => $instances_add_resource_policies_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddResourcePolicies> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddResourcePoliciesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_add_resource_policies_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesAddResourcePoliciesRequest>

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
        return_partial_success   => $return_partial_success,
        service_project_number   => $service_project_number,
    );

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListInstancesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceAggregatedList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<include_all_scopes> - C<bool>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<service_project_number> - C<int64>

=back

=item * B<attach_disk>

    my $response = $client->attach_disk(
        attached_disk_resource   => $attached_disk_resource,
        force_attach             => $force_attach,
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AttachDisk> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AttachDiskInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<attached_disk_resource> - L<Google::Cloud::Compute::V1beta::Compute::AttachedDisk>

=item * C<force_attach> - C<bool>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<bulk_insert>

    my $response = $client->bulk_insert(
        bulk_insert_instance_resource_resource => $bulk_insert_instance_resource_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<BulkInsert> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::BulkInsertInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<bulk_insert_instance_resource_resource> - L<Google::Cloud::Compute::V1beta::Compute::BulkInsertInstanceResource>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        instance                 => $instance,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete_access_config>

    my $response = $client->delete_access_config(
        access_config            => $access_config,
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<DeleteAccessConfig> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<access_config> - C<string>

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete_network_interface>

    my $response = $client->delete_network_interface(
        instance                 => $instance,
        network_interface_name   => $network_interface_name,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<DeleteNetworkInterface> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface_name> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<detach_disk>

    my $response = $client->detach_disk(
        device_name              => $device_name,
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<DetachDisk> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DetachDiskInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<device_name> - C<string>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        instance                 => $instance,
        project                  => $project,
        view                     => $view,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Instance>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<view> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_effective_firewalls>

    my $response = $client->get_effective_firewalls(
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetEffectiveFirewalls> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetEffectiveFirewallsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstancesGetEffectiveFirewallsResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_guest_attributes>

    my $response = $client->get_guest_attributes(
        instance                 => $instance,
        project                  => $project,
        query_path               => $query_path,
        variable_key             => $variable_key,
        zone                     => $zone,
    );

Calls the RPC method C<GetGuestAttributes> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetGuestAttributesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::GuestAttributes>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<query_path> - C<string>

=item * C<variable_key> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        resource                 => $resource,
        zone                     => $zone,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetIamPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_partner_metadata>

    my $response = $client->get_partner_metadata(
        instance                 => $instance,
        namespaces               => $namespaces,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetPartnerMetadata> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetPartnerMetadataInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::PartnerMetadata>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<namespaces> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_screenshot>

    my $response = $client->get_screenshot(
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetScreenshot> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetScreenshotInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Screenshot>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_serial_port_output>

    my $response = $client->get_serial_port_output(
        instance                 => $instance,
        port                     => $port,
        project                  => $project,
        start                    => $start,
        zone                     => $zone,
    );

Calls the RPC method C<GetSerialPortOutput> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetSerialPortOutputInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::SerialPortOutput>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<port> - C<int32>

=item * C<project> - C<string>

=item * C<start> - C<int64>

=item * C<zone> - C<string>

=back

=item * B<get_shielded_instance_identity>

    my $response = $client->get_shielded_instance_identity(
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetShieldedInstanceIdentity> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetShieldedInstanceIdentityInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIdentity>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_shielded_vm_identity>

    my $response = $client->get_shielded_vm_identity(
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetShieldedVmIdentity> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetShieldedVmIdentityInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::ShieldedVmIdentity>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_vm_extension_state>

    my $response = $client->get_vm_extension_state(
        extension_name           => $extension_name,
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetVmExtensionState> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetVmExtensionStateInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::VmExtensionState>

Parameters:

=over 4

=item * C<extension_name> - C<string>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        instance_resource        => $instance_resource,
        project                  => $project,
        request_id               => $request_id,
        source_instance_template => $source_instance_template,
        source_machine_image     => $source_machine_image,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_resource> - L<Google::Cloud::Compute::V1beta::Compute::Instance>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<source_instance_template> - C<string>

=item * C<source_machine_image> - C<string>

=item * C<zone> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        view                     => $view,
        zone                     => $zone,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListInstancesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<view> - C<string>

=item * C<zone> - C<string>

=back

=item * B<list_referrers>

    my $response = $client->list_referrers(
        filter                   => $filter,
        instance                 => $instance,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<ListReferrers> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListReferrersInstancesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceListReferrers>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<list_vm_extension_states>

    my $response = $client->list_vm_extension_states(
        filter                   => $filter,
        instance                 => $instance,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<ListVmExtensionStates> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesInstancesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::ListVmExtensionStatesResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<patch_partner_metadata>

    my $response = $client->patch_partner_metadata(
        instance                 => $instance,
        partner_metadata_resource => $partner_metadata_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<PatchPartnerMetadata> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchPartnerMetadataInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<partner_metadata_resource> - L<Google::Cloud::Compute::V1beta::Compute::PartnerMetadata>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<perform_maintenance>

    my $response = $client->perform_maintenance(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<PerformMaintenance> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PerformMaintenanceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<remove_resource_policies>

    my $response = $client->remove_resource_policies(
        instance                 => $instance,
        instances_remove_resource_policies_request_resource => $instances_remove_resource_policies_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<RemoveResourcePolicies> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveResourcePoliciesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_remove_resource_policies_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesRemoveResourcePoliciesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<report_host_as_faulty>

    my $response = $client->report_host_as_faulty(
        instance                 => $instance,
        instances_report_host_as_faulty_request_resource => $instances_report_host_as_faulty_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<ReportHostAsFaulty> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ReportHostAsFaultyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_report_host_as_faulty_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesReportHostAsFaultyRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<reset>

    my $response = $client->reset(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Reset> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResetInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<resume>

    my $response = $client->resume(
        instance                 => $instance,
        instances_resume_request_resource => $instances_resume_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Resume> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResumeInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_resume_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesResumeRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<send_diagnostic_interrupt>

    my $response = $client->send_diagnostic_interrupt(
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<SendDiagnosticInterrupt> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::SendDiagnosticInterruptInstanceResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_deletion_protection>

    my $response = $client->set_deletion_protection(
        deletion_protection      => $deletion_protection,
        project                  => $project,
        request_id               => $request_id,
        resource                 => $resource,
        zone                     => $zone,
    );

Calls the RPC method C<SetDeletionProtection> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetDeletionProtectionInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<deletion_protection> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_disk_auto_delete>

    my $response = $client->set_disk_auto_delete(
        auto_delete              => $auto_delete,
        device_name              => $device_name,
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetDiskAutoDelete> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetDiskAutoDeleteInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<auto_delete> - C<bool>

=item * C<device_name> - C<string>

=item * C<instance> - C<string>

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

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetIamPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=item * C<zone_set_policy_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::ZoneSetPolicyRequest>

=back

=item * B<set_labels>

    my $response = $client->set_labels(
        instance                 => $instance,
        instances_set_labels_request_resource => $instances_set_labels_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetLabels> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetLabelsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_labels_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetLabelsRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_machine_resources>

    my $response = $client->set_machine_resources(
        instance                 => $instance,
        instances_set_machine_resources_request_resource => $instances_set_machine_resources_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetMachineResources> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetMachineResourcesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_machine_resources_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetMachineResourcesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_machine_type>

    my $response = $client->set_machine_type(
        instance                 => $instance,
        instances_set_machine_type_request_resource => $instances_set_machine_type_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetMachineType> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetMachineTypeInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_machine_type_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetMachineTypeRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_metadata>

    my $response = $client->set_metadata(
        instance                 => $instance,
        metadata_resource        => $metadata_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetMetadata> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetMetadataInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<metadata_resource> - L<Google::Cloud::Compute::V1beta::Compute::Metadata>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_min_cpu_platform>

    my $response = $client->set_min_cpu_platform(
        instance                 => $instance,
        instances_set_min_cpu_platform_request_resource => $instances_set_min_cpu_platform_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetMinCpuPlatform> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetMinCpuPlatformInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_min_cpu_platform_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetMinCpuPlatformRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_name>

    my $response = $client->set_name(
        instance                 => $instance,
        instances_set_name_request_resource => $instances_set_name_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetName> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetNameInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_name_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetNameRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_scheduling>

    my $response = $client->set_scheduling(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        scheduling_resource      => $scheduling_resource,
        zone                     => $zone,
    );

Calls the RPC method C<SetScheduling> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetSchedulingInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<scheduling_resource> - L<Google::Cloud::Compute::V1beta::Compute::Scheduling>

=item * C<zone> - C<string>

=back

=item * B<set_security_policy>

    my $response = $client->set_security_policy(
        instance                 => $instance,
        instances_set_security_policy_request_resource => $instances_set_security_policy_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetSecurityPolicy> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetSecurityPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_security_policy_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetSecurityPolicyRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_service_account>

    my $response = $client->set_service_account(
        instance                 => $instance,
        instances_set_service_account_request_resource => $instances_set_service_account_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetServiceAccount> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetServiceAccountInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_service_account_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesSetServiceAccountRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_shielded_instance_integrity_policy>

    my $response = $client->set_shielded_instance_integrity_policy(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        shielded_instance_integrity_policy_resource => $shielded_instance_integrity_policy_resource,
        zone                     => $zone,
    );

Calls the RPC method C<SetShieldedInstanceIntegrityPolicy> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_instance_integrity_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceIntegrityPolicy>

=item * C<zone> - C<string>

=back

=item * B<set_shielded_vm_integrity_policy>

    my $response = $client->set_shielded_vm_integrity_policy(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        shielded_vm_integrity_policy_resource => $shielded_vm_integrity_policy_resource,
        zone                     => $zone,
    );

Calls the RPC method C<SetShieldedVmIntegrityPolicy> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetShieldedVmIntegrityPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_vm_integrity_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::ShieldedVmIntegrityPolicy>

=item * C<zone> - C<string>

=back

=item * B<set_tags>

    my $response = $client->set_tags(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        tags_resource            => $tags_resource,
        zone                     => $zone,
    );

Calls the RPC method C<SetTags> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetTagsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<tags_resource> - L<Google::Cloud::Compute::V1beta::Compute::Tags>

=item * C<zone> - C<string>

=back

=item * B<simulate_maintenance_event>

    my $response = $client->simulate_maintenance_event(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        with_extended_notifications => $with_extended_notifications,
        zone                     => $zone,
    );

Calls the RPC method C<SimulateMaintenanceEvent> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SimulateMaintenanceEventInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<with_extended_notifications> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<start>

    my $response = $client->start(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Start> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::StartInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<start_with_encryption_key>

    my $response = $client->start_with_encryption_key(
        instance                 => $instance,
        instances_start_with_encryption_key_request_resource => $instances_start_with_encryption_key_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StartWithEncryptionKey> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::StartWithEncryptionKeyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_start_with_encryption_key_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstancesStartWithEncryptionKeyRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<stop>

    my $response = $client->stop(
        discard_local_ssd        => $discard_local_ssd,
        instance                 => $instance,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Stop> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::StopInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<discard_local_ssd> - C<bool>

=item * C<instance> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<suspend>

    my $response = $client->suspend(
        discard_local_ssd        => $discard_local_ssd,
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Suspend> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SuspendInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<discard_local_ssd> - C<bool>

=item * C<instance> - C<string>

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

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=item * C<zone> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        discard_local_ssd        => $discard_local_ssd,
        instance                 => $instance,
        instance_resource        => $instance_resource,
        minimal_action           => $minimal_action,
        most_disruptive_allowed_action => $most_disruptive_allowed_action,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<discard_local_ssd> - C<bool>

=item * C<instance> - C<string>

=item * C<instance_resource> - L<Google::Cloud::Compute::V1beta::Compute::Instance>

=item * C<minimal_action> - C<string>

=item * C<most_disruptive_allowed_action> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_access_config>

    my $response = $client->update_access_config(
        access_config_resource   => $access_config_resource,
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateAccessConfig> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<access_config_resource> - L<Google::Cloud::Compute::V1beta::Compute::AccessConfig>

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_display_device>

    my $response = $client->update_display_device(
        display_device_resource  => $display_device_resource,
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateDisplayDevice> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateDisplayDeviceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<display_device_resource> - L<Google::Cloud::Compute::V1beta::Compute::DisplayDevice>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_network_interface>

    my $response = $client->update_network_interface(
        instance                 => $instance,
        network_interface        => $network_interface,
        network_interface_resource => $network_interface_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateNetworkInterface> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<network_interface_resource> - L<Google::Cloud::Compute::V1beta::Compute::NetworkInterface>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_shielded_instance_config>

    my $response = $client->update_shielded_instance_config(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        shielded_instance_config_resource => $shielded_instance_config_resource,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateShieldedInstanceConfig> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateShieldedInstanceConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_instance_config_resource> - L<Google::Cloud::Compute::V1beta::Compute::ShieldedInstanceConfig>

=item * C<zone> - C<string>

=back

=item * B<update_shielded_vm_config>

    my $response = $client->update_shielded_vm_config(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        shielded_vm_config_resource => $shielded_vm_config_resource,
        zone                     => $zone,
    );

Calls the RPC method C<UpdateShieldedVmConfig> on C<google.cloud.compute.v1beta.Instances>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateShieldedVmConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_vm_config_resource> - L<Google::Cloud::Compute::V1beta::Compute::ShieldedVmConfig>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
