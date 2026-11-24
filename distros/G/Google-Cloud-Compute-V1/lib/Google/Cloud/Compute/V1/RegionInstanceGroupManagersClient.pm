package Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient;

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

sub abandon_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AbandonInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/AbandonInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'AbandonInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub apply_updates_to_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ApplyUpdatesToInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/ApplyUpdatesToInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'ApplyUpdatesToInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CreateInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/CreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'CreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/DeleteInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'DeleteInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeletePerInstanceConfigsRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/DeletePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'DeletePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRegionInstanceGroupManagerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManager';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRegionInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagerList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_errors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListErrorsRegionInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListErrorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/ListErrors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'ListErrors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_managed_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListManagedInstancesRegionInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListInstancesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/ListManagedInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'ListManagedInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListPerInstanceConfigsRegionInstanceGroupManagersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListInstanceConfigsResp';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/ListPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'ListPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchPerInstanceConfigsRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/PatchPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'PatchPerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub recreate_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RecreateInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/RecreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'RecreateInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResizeRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResumeInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/ResumeInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'ResumeInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_instance_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetInstanceTemplateRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/SetInstanceTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'SetInstanceTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_target_pools {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetTargetPoolsRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/SetTargetPools',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'SetTargetPools',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/StartInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'StartInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/StopInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'StopInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SuspendInstancesRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/SuspendInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'SuspendInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_per_instance_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdatePerInstanceConfigsRegionInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.RegionInstanceGroupManagers/UpdatePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionInstanceGroupManagers',
        method         => 'UpdatePerInstanceConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient->new(
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
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_abandon_instances_request_resource => $region_instance_group_managers_abandon_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<AbandonInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::AbandonInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_abandon_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersAbandonInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<apply_updates_to_instances>

    my $response = $client->apply_updates_to_instances(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_apply_updates_request_resource => $region_instance_group_managers_apply_updates_request_resource,
    );

Calls the RPC method C<ApplyUpdatesToInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ApplyUpdatesToInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_apply_updates_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersApplyUpdatesRequest>

=back

=item * B<create_instances>

    my $response = $client->create_instances(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_create_instances_request_resource => $region_instance_group_managers_create_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<CreateInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::CreateInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_create_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersCreateInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        instance_group_manager   => $instance_group_manager,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<delete_instances>

    my $response = $client->delete_instances(
        instance_group_manager   => $instance_group_manager,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_delete_instances_request_resource => $region_instance_group_managers_delete_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<DeleteInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_delete_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersDeleteInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<delete_per_instance_configs>

    my $response = $client->delete_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_manager_delete_instance_config_req_resource => $region_instance_group_manager_delete_instance_config_req_resource,
    );

Calls the RPC method C<DeletePerInstanceConfigs> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeletePerInstanceConfigsRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_manager_delete_instance_config_req_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagerDeleteInstanceConfigReq>

=back

=item * B<get>

    my $response = $client->get(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

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

Calls the RPC method C<List> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRegionInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagerList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<list_errors>

    my $response = $client->list_errors(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListErrors> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListErrorsRegionInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListErrorsResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<list_managed_instances>

    my $response = $client->list_managed_instances(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListManagedInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListManagedInstancesRegionInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListInstancesResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<list_per_instance_configs>

    my $response = $client->list_per_instance_configs(
        filter                   => $filter,
        instance_group_manager   => $instance_group_manager,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListPerInstanceConfigs> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListPerInstanceConfigsRegionInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersListInstanceConfigsResp>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        instance_group_manager   => $instance_group_manager,
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<patch_per_instance_configs>

    my $response = $client->patch_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_manager_patch_instance_config_req_resource => $region_instance_group_manager_patch_instance_config_req_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchPerInstanceConfigs> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchPerInstanceConfigsRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_manager_patch_instance_config_req_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagerPatchInstanceConfigReq>

=item * C<request_id> - C<string>

=back

=item * B<recreate_instances>

    my $response = $client->recreate_instances(
        instance_group_manager   => $instance_group_manager,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_recreate_request_resource => $region_instance_group_managers_recreate_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<RecreateInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::RecreateInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_recreate_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersRecreateRequest>

=item * C<request_id> - C<string>

=back

=item * B<resize>

    my $response = $client->resize(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        size                     => $size,
    );

Calls the RPC method C<Resize> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ResizeRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<size> - C<int32>

=back

=item * B<resume_instances>

    my $response = $client->resume_instances(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_resume_instances_request_resource => $region_instance_group_managers_resume_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<ResumeInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ResumeInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_resume_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersResumeInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_instance_template>

    my $response = $client->set_instance_template(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_set_template_request_resource => $region_instance_group_managers_set_template_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetInstanceTemplate> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SetInstanceTemplateRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_set_template_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersSetTemplateRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_target_pools>

    my $response = $client->set_target_pools(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_set_target_pools_request_resource => $region_instance_group_managers_set_target_pools_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetTargetPools> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SetTargetPoolsRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_set_target_pools_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersSetTargetPoolsRequest>

=item * C<request_id> - C<string>

=back

=item * B<start_instances>

    my $response = $client->start_instances(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_start_instances_request_resource => $region_instance_group_managers_start_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<StartInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::StartInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_start_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersStartInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<stop_instances>

    my $response = $client->stop_instances(
        instance_group_manager   => $instance_group_manager,
        no_graceful_shutdown     => $no_graceful_shutdown,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_stop_instances_request_resource => $region_instance_group_managers_stop_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<StopInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::StopInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<no_graceful_shutdown> - C<bool>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_stop_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersStopInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<suspend_instances>

    my $response = $client->suspend_instances(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_managers_suspend_instances_request_resource => $region_instance_group_managers_suspend_instances_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SuspendInstances> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SuspendInstancesRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_managers_suspend_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagersSuspendInstancesRequest>

=item * C<request_id> - C<string>

=back

=item * B<update_per_instance_configs>

    my $response = $client->update_per_instance_configs(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        region                   => $region,
        region_instance_group_manager_update_instance_config_req_resource => $region_instance_group_manager_update_instance_config_req_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdatePerInstanceConfigs> on C<google.cloud.compute.v1.RegionInstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdatePerInstanceConfigsRegionInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_instance_group_manager_update_instance_config_req_resource> - L<Google::Cloud::Compute::V1::Compute::RegionInstanceGroupManagerUpdateInstanceConfigReq>

=item * C<request_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
