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

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AbandonInstancesInstanceGroupManagerRequest';
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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/AbandonInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagerAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/ApplyUpdatesToInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/CreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/DeleteInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/DeletePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagerList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/List',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListErrorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/ListErrors',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListManagedInstancesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/ListManagedInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListPerInstanceConfigsResp';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/ListPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/PatchPerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/RecreateInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/ResumeInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/SetInstanceTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/SetTargetPools',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/StartInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/StopInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/SuspendInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.compute.v1.InstanceGroupManagers/UpdatePerInstanceConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

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

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



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

    my $response = $client->abandon_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_abandon_instances_request_resource => $instance_group_managers_abandon_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AbandonInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::AbandonInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_abandon_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersAbandonInstancesRequest>

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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::AggregatedListInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagerAggregatedList>

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

=item * B<apply_updates_to_instances>

    my $response = $client->apply_updates_to_instances(
        instance_group_manager   => $instance_group_manager,
        instance_group_managers_apply_updates_request_resource => $instance_group_managers_apply_updates_request_resource,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<ApplyUpdatesToInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ApplyUpdatesToInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_apply_updates_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersApplyUpdatesRequest>

=item * C<project> - C<string>

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

Calls the RPC method C<CreateInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::CreateInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_create_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersCreateInstancesRequest>

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

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<DeleteInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_delete_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersDeleteInstancesRequest>

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

Calls the RPC method C<DeletePerInstanceConfigs> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeletePerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_delete_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersDeletePerInstanceConfigsReq>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        instance_group_manager   => $instance_group_manager,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        instance_group_manager_resource => $instance_group_manager_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

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
        zone                     => $zone,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagerList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

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
        zone                     => $zone,
    );

Calls the RPC method C<ListErrors> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListErrorsInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListErrorsResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

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
        zone                     => $zone,
    );

Calls the RPC method C<ListManagedInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListManagedInstancesInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListManagedInstancesResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

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
        zone                     => $zone,
    );

Calls the RPC method C<ListPerInstanceConfigs> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListPerInstanceConfigsInstanceGroupManagersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersListPerInstanceConfigsResp>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group_manager> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

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

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_manager_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManager>

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

Calls the RPC method C<PatchPerInstanceConfigs> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchPerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_patch_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersPatchPerInstanceConfigsReq>

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

Calls the RPC method C<RecreateInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::RecreateInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_recreate_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersRecreateInstancesRequest>

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

Calls the RPC method C<Resize> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ResizeInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<size> - C<int32>

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

Calls the RPC method C<ResumeInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::ResumeInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_resume_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersResumeInstancesRequest>

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

Calls the RPC method C<SetInstanceTemplate> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SetInstanceTemplateInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_set_instance_template_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersSetInstanceTemplateRequest>

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

Calls the RPC method C<SetTargetPools> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SetTargetPoolsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_set_target_pools_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersSetTargetPoolsRequest>

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

Calls the RPC method C<StartInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::StartInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_start_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersStartInstancesRequest>

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

Calls the RPC method C<StopInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::StopInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_stop_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersStopInstancesRequest>

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

Calls the RPC method C<SuspendInstances> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::SuspendInstancesInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_suspend_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersSuspendInstancesRequest>

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

Calls the RPC method C<UpdatePerInstanceConfigs> on C<google.cloud.compute.v1.InstanceGroupManagers>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdatePerInstanceConfigsInstanceGroupManagerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group_manager> - C<string>

=item * C<instance_group_managers_update_per_instance_configs_req_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupManagersUpdatePerInstanceConfigsReq>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
