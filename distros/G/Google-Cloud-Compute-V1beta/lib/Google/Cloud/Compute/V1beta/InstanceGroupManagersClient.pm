package Google::Cloud::Compute::V1beta::InstanceGroupManagersClient;

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

sub abandon_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AbandonInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/AbandonInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'AbandonInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagerAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub apply_updates_to_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ApplyUpdatesToInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ApplyUpdatesToInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ApplyUpdatesToInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub configure_accelerator_topologies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ConfigureAcceleratorTopologiesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ConfigureAcceleratorTopologies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ConfigureAcceleratorTopologies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::CreateInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/CreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'CreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/DeleteInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'DeleteInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeletePerInstanceConfigsInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/DeletePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'DeletePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManager';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_available_accelerator_topologies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetAvailableAcceleratorTopologiesInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersGetAvailableAcceleratorTopologiesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/GetAvailableAcceleratorTopologies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'GetAvailableAcceleratorTopologies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagerList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_errors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListErrorsInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListErrorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ListErrors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ListErrors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_managed_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListManagedInstancesInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListManagedInstancesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ListManagedInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ListManagedInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListPerInstanceConfigsInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListPerInstanceConfigsResp';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ListPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ListPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchPerInstanceConfigsInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/PatchPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'PatchPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recreate_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RecreateInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/RecreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'RecreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResizeInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize_advanced {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResizeAdvancedInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ResizeAdvanced',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ResizeAdvanced',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResumeInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/ResumeInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'ResumeInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_auto_healing_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetAutoHealingPoliciesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/SetAutoHealingPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'SetAutoHealingPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_instance_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetInstanceTemplateInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/SetInstanceTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'SetInstanceTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_target_pools {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetTargetPoolsInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/SetTargetPools',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'SetTargetPools',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::StartInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/StartInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'StartInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::StopInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/StopInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'StopInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SuspendInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/SuspendInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'SuspendInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdatePerInstanceConfigsInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1beta.InstanceGroupManagers/UpdatePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.InstanceGroupManagers',
        method         => 'UpdatePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::InstanceGroupManagersClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::InstanceGroupManagersClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::InstanceGroupManagersClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::InstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::InstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::InstanceGroupManagersClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::InstanceGroupManagersClient->new(
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

    my $response = $client->abandon_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_abandon_instances_request_resource => $instance_group_managers_abandon_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AbandonInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AbandonInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_abandon_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersAbandonInstancesRequest>

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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagerAggregatedList>

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

=item * B<apply_updates_to_instances>

    my $response = $client->apply_updates_to_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_apply_updates_request_resource => $instance_group_managers_apply_updates_request_resource,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<ApplyUpdatesToInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ApplyUpdatesToInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_apply_updates_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersApplyUpdatesRequest>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<configure_accelerator_topologies>

    my $response = $client->configure_accelerator_topologies(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_configure_accelerator_topologies_request_resource => $instance_group_managers_configure_accelerator_topologies_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<ConfigureAcceleratorTopologies> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ConfigureAcceleratorTopologiesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_configure_accelerator_topologies_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersConfigureAcceleratorTopologiesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<create_instances>

    my $response = $client->create_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_create_instances_request_resource => $instance_group_managers_create_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<CreateInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::CreateInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_create_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersCreateInstancesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        instance_group_manager   => $instance_group_manager,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete_instances>

    my $response = $client->delete_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_delete_instances_request_resource => $instance_group_managers_delete_instances_request_resource,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<DeleteInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_delete_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersDeleteInstancesRequest>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete_per_instance_configs>

    my $response = $client->delete_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_delete_per_instance_configs_req_resource => $instance_group_managers_delete_per_instance_configs_req_resource,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<DeletePerInstanceConfigs> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeletePerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_delete_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersDeletePerInstanceConfigsReq>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManager>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_available_accelerator_topologies>

    my $response = $client->get_available_accelerator_topologies(
        project                  => $project,
        resource_id              => $resource_id,
        zone                     => $zone,
    );

Calls the RPC method C<GetAvailableAcceleratorTopologies> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetAvailableAcceleratorTopologiesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersGetAvailableAcceleratorTopologiesResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManager>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

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
        zone                     => $zone,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagerList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<list_errors>

    my $response = $client->list_errors(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<ListErrors> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListErrorsInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListErrorsResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<list_managed_instances>

    my $response = $client->list_managed_instances(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<ListManagedInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListManagedInstancesInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListManagedInstancesResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<list_per_instance_configs>

    my $response = $client->list_per_instance_configs(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<ListPerInstanceConfigs> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListPerInstanceConfigsInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersListPerInstanceConfigsResp>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        instance_group_manager   => $instance_group_manager,
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManager>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<patch_per_instance_configs>

    my $response = $client->patch_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_patch_per_instance_configs_req_resource => $instance_group_managers_patch_per_instance_configs_req_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<PatchPerInstanceConfigs> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchPerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_patch_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersPatchPerInstanceConfigsReq>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<recreate_instances>

    my $response = $client->recreate_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_recreate_instances_request_resource => $instance_group_managers_recreate_instances_request_resource,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<RecreateInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RecreateInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_recreate_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersRecreateInstancesRequest>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<resize>

    my $response = $client->resize(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        request_id               => $request_id,
        size                     => $size,
        zone                     => $zone,
    );

Calls the RPC method C<Resize> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResizeInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<size> - C<int32>

=item * C<zone> - C<string>

=back

=item * B<resize_advanced>

    my $response = $client->resize_advanced(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_resize_advanced_request_resource => $instance_group_managers_resize_advanced_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<ResizeAdvanced> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResizeAdvancedInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_resize_advanced_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersResizeAdvancedRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<resume_instances>

    my $response = $client->resume_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_resume_instances_request_resource => $instance_group_managers_resume_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<ResumeInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResumeInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_resume_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersResumeInstancesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_auto_healing_policies>

    my $response = $client->set_auto_healing_policies(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_set_auto_healing_request_resource => $instance_group_managers_set_auto_healing_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetAutoHealingPolicies> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetAutoHealingPoliciesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_set_auto_healing_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersSetAutoHealingRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_instance_template>

    my $response = $client->set_instance_template(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_set_instance_template_request_resource => $instance_group_managers_set_instance_template_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetInstanceTemplate> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetInstanceTemplateInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_set_instance_template_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersSetInstanceTemplateRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_target_pools>

    my $response = $client->set_target_pools(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_set_target_pools_request_resource => $instance_group_managers_set_target_pools_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetTargetPools> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetTargetPoolsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_set_target_pools_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersSetTargetPoolsRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<start_instances>

    my $response = $client->start_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_start_instances_request_resource => $instance_group_managers_start_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StartInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::StartInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_start_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersStartInstancesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<stop_instances>

    my $response = $client->stop_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_stop_instances_request_resource => $instance_group_managers_stop_instances_request_resource,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<StopInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::StopInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_stop_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersStopInstancesRequest>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<suspend_instances>

    my $response = $client->suspend_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_suspend_instances_request_resource => $instance_group_managers_suspend_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SuspendInstances> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SuspendInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_suspend_instances_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersSuspendInstancesRequest>

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

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsInstanceGroupManagerRequest>

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
        instance_group_manager   => $instance_group_manager,
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManager>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update_per_instance_configs>

    my $response = $client->update_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_update_per_instance_configs_req_resource => $instance_group_managers_update_per_instance_configs_req_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<UpdatePerInstanceConfigs> on C<google.cloud.compute.v1beta.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdatePerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_update_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceGroupManagersUpdatePerInstanceConfigsReq>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
