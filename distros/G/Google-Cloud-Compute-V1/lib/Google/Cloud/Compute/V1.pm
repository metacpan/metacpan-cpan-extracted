package Google::Cloud::Compute::V1;

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

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListAcceleratorTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::AcceleratorTypeAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.AcceleratorTypes/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.AcceleratorTypes',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetAcceleratorTypeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::AcceleratorType';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.AcceleratorTypes/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.AcceleratorTypes',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListAcceleratorTypesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::AcceleratorTypeList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.AcceleratorTypes/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.AcceleratorTypes',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteAddressRequest';
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
            path           => '/google.cloud.compute.v1.Addresses/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Addresses',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertAddressRequest';
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
            path           => '/google.cloud.compute.v1.Addresses/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Addresses',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveAddressRequest';
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
            path           => '/google.cloud.compute.v1.Addresses/Move',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Addresses',
        method         => 'Move',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_labels {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetLabelsAddressRequest';
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
            path           => '/google.cloud.compute.v1.Addresses/SetLabels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Addresses',
        method         => 'SetLabels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsAddressRequest';
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
            path           => '/google.cloud.compute.v1.Addresses/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Addresses',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub calendar_mode {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRpcRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CalendarModeAdviceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/CalendarMode',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'CalendarMode',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub capacity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CapacityAdviceRpcRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CapacityAdviceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/Capacity',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'Capacity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub capacity_history {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CapacityHistoryAdviceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CapacityHistoryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/CapacityHistory',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'CapacityHistory',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchAutoscalerRequest';
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
            path           => '/google.cloud.compute.v1.Autoscalers/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Autoscalers',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateAutoscalerRequest';
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
            path           => '/google.cloud.compute.v1.Autoscalers/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Autoscalers',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_signed_url_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddSignedUrlKeyBackendBucketRequest';
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
            path           => '/google.cloud.compute.v1.BackendBuckets/AddSignedUrlKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'AddSignedUrlKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_signed_url_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteSignedUrlKeyBackendBucketRequest';
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
            path           => '/google.cloud.compute.v1.BackendBuckets/DeleteSignedUrlKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'DeleteSignedUrlKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetIamPolicyBackendBucketRequest';
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
            path           => '/google.cloud.compute.v1.BackendBuckets/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_usable {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListUsableBackendBucketsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::BackendBucketListUsable';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.BackendBuckets/ListUsable',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'ListUsable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_edge_security_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetEdgeSecurityPolicyBackendBucketRequest';
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
            path           => '/google.cloud.compute.v1.BackendBuckets/SetEdgeSecurityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'SetEdgeSecurityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetIamPolicyBackendBucketRequest';
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
            path           => '/google.cloud.compute.v1.BackendBuckets/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendBuckets',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_security_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetEffectiveSecurityPoliciesBackendServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::GetEffectiveSecurityPoliciesBackendServiceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.BackendServices/GetEffectiveSecurityPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendServices',
        method         => 'GetEffectiveSecurityPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_health {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetHealthBackendServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::BackendServiceGroupHealth';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.BackendServices/GetHealth',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendServices',
        method         => 'GetHealth',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_security_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSecurityPolicyBackendServiceRequest';
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
            path           => '/google.cloud.compute.v1.BackendServices/SetSecurityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.BackendServices',
        method         => 'SetSecurityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
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

sub add_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddAssociationFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/AddAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'AddAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/AddRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'AddRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub clone_rules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CloneRulesFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/CloneRules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'CloneRules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetAssociationFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyAssociation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.FirewallPolicies/GetAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'GetAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRuleFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.FirewallPolicies/GetRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'GetRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_associations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListAssociationsFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPoliciesListAssociationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.FirewallPolicies/ListAssociations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'ListAssociations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/PatchRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'PatchRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveAssociationFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/RemoveAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'RemoveAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.FirewallPolicies/RemoveRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FirewallPolicies',
        method         => 'RemoveRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_target {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetTargetForwardingRuleRequest';
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
            path           => '/google.cloud.compute.v1.ForwardingRules/SetTarget',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.ForwardingRules',
        method         => 'SetTarget',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CancelFutureReservationRequest';
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
            path           => '/google.cloud.compute.v1.FutureReservations/Cancel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.FutureReservations',
        method         => 'Cancel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
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

sub wait {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::WaitGlobalOperationRequest';
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
            path           => '/google.cloud.compute.v1.GlobalOperations/Wait',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.GlobalOperations',
        method         => 'Wait',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_version {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetVersionHostRequest';
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
            path           => '/google.cloud.compute.v1.Hosts/GetVersion',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Hosts',
        method         => 'GetVersion',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub deprecate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeprecateImageRequest';
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
            path           => '/google.cloud.compute.v1.Images/Deprecate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Images',
        method         => 'Deprecate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_from_family {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetFromFamilyImageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Image';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Images/GetFromFamily',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Images',
        method         => 'GetFromFamily',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
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

sub add_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddInstancesInstanceGroupRequest';
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
            path           => '/google.cloud.compute.v1.InstanceGroups/AddInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroups',
        method         => 'AddInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListInstancesInstanceGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceGroupsListInstances';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InstanceGroups/ListInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroups',
        method         => 'ListInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_instances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveInstancesInstanceGroupRequest';
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
            path           => '/google.cloud.compute.v1.InstanceGroups/RemoveInstances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroups',
        method         => 'RemoveInstances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_named_ports {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetNamedPortsInstanceGroupRequest';
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
            path           => '/google.cloud.compute.v1.InstanceGroups/SetNamedPorts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InstanceGroups',
        method         => 'SetNamedPorts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddAccessConfigInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/AddAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AddAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddNetworkInterfaceInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/AddNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AddNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub attach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AttachDiskInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/AttachDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'AttachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteAccessConfigInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/DeleteAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DeleteAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNetworkInterfaceInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/DeleteNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DeleteNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub detach_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DetachDiskInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/DetachDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'DetachDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_firewalls {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstancesGetEffectiveFirewallsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/GetEffectiveFirewalls',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetEffectiveFirewalls',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_guest_attributes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetGuestAttributesInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::GuestAttributes';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/GetGuestAttributes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetGuestAttributes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_screenshot {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetScreenshotInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Screenshot';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/GetScreenshot',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetScreenshot',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_serial_port_output {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetSerialPortOutputInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SerialPortOutput';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/GetSerialPortOutput',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetSerialPortOutput',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_shielded_instance_identity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetShieldedInstanceIdentityInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ShieldedInstanceIdentity';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/GetShieldedInstanceIdentity',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'GetShieldedInstanceIdentity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_referrers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListReferrersInstancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InstanceListReferrers';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/ListReferrers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'ListReferrers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub perform_maintenance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PerformMaintenanceInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/PerformMaintenance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'PerformMaintenance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_host_as_faulty {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ReportHostAsFaultyInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/ReportHostAsFaulty',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'ReportHostAsFaulty',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResetInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/Reset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Reset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResumeInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/Resume',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Resume',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub send_diagnostic_interrupt {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Instances/SendDiagnosticInterrupt',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SendDiagnosticInterrupt',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_deletion_protection {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDeletionProtectionInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetDeletionProtection',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetDeletionProtection',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_disk_auto_delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDiskAutoDeleteInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetDiskAutoDelete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetDiskAutoDelete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_resources {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMachineResourcesInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetMachineResources',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMachineResources',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_machine_type {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMachineTypeInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetMachineType',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMachineType',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMetadataInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_min_cpu_platform {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetMinCpuPlatformInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetMinCpuPlatform',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetMinCpuPlatform',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_name {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetNameInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetName',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetName',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_scheduling {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSchedulingInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetScheduling',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetScheduling',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetServiceAccountInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetServiceAccount',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_shielded_instance_integrity_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetShieldedInstanceIntegrityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetShieldedInstanceIntegrityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_tags {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetTagsInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SetTags',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SetTags',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub simulate_maintenance_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SimulateMaintenanceEventInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/SimulateMaintenanceEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'SimulateMaintenanceEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/Start',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Start',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_with_encryption_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StartWithEncryptionKeyInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/StartWithEncryptionKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'StartWithEncryptionKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::StopInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/Stop',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Stop',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub suspend {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SuspendInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/Suspend',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'Suspend',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_access_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateAccessConfigInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/UpdateAccessConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateAccessConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_display_device {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateDisplayDeviceInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/UpdateDisplayDevice',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateDisplayDevice',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_network_interface {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateNetworkInterfaceInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/UpdateNetworkInterface',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateNetworkInterface',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_shielded_instance_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateShieldedInstanceConfigInstanceRequest';
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
            path           => '/google.cloud.compute.v1.Instances/UpdateShieldedInstanceConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Instances',
        method         => 'UpdateShieldedInstanceConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_operational_status {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetOperationalStatusInterconnectAttachmentGroupRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InterconnectAttachmentGroupsGetOperationalStatusResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.InterconnectAttachmentGroups/GetOperationalStatus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InterconnectAttachmentGroups',
        method         => 'GetOperationalStatus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_members {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CreateMembersInterconnectGroupRequest';
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
            path           => '/google.cloud.compute.v1.InterconnectGroups/CreateMembers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.InterconnectGroups',
        method         => 'CreateMembers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_diagnostics {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetDiagnosticsInterconnectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InterconnectsGetDiagnosticsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Interconnects/GetDiagnostics',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Interconnects',
        method         => 'GetDiagnostics',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_macsec_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetMacsecConfigInterconnectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::InterconnectsGetMacsecConfigResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Interconnects/GetMacsecConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Interconnects',
        method         => 'GetMacsecConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddPacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.NetworkFirewallPolicies/AddPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'AddPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetPacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.NetworkFirewallPolicies/GetPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'GetPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchPacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.NetworkFirewallPolicies/PatchPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'PatchPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemovePacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.NetworkFirewallPolicies/RemovePacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'RemovePacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddPeeringNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/AddPeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'AddPeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_request_remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CancelRequestRemovePeeringNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/CancelRequestRemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'CancelRequestRemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_peering_routes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListPeeringRoutesNetworksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/ListPeeringRoutes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'ListPeeringRoutes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemovePeeringNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/RemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'RemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub request_remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RequestRemovePeeringNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/RequestRemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'RequestRemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub switch_to_custom_mode {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SwitchToCustomModeNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/SwitchToCustomMode',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'SwitchToCustomMode',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdatePeeringNetworkRequest';
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
            path           => '/google.cloud.compute.v1.Networks/UpdatePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'UpdatePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_nodes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddNodesNodeGroupRequest';
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
            path           => '/google.cloud.compute.v1.NodeGroups/AddNodes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NodeGroups',
        method         => 'AddNodes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_nodes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNodesNodeGroupRequest';
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
            path           => '/google.cloud.compute.v1.NodeGroups/DeleteNodes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NodeGroups',
        method         => 'DeleteNodes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_nodes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListNodesNodeGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NodeGroupsListNodes';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.NodeGroups/ListNodes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NodeGroups',
        method         => 'ListNodes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_node_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetNodeTemplateNodeGroupRequest';
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
            path           => '/google.cloud.compute.v1.NodeGroups/SetNodeTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NodeGroups',
        method         => 'SetNodeTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub copy_rules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CopyRulesOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/CopyRules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'CopyRules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_preconfigured_expression_sets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListPreconfiguredExpressionSetsOrganizationSecurityPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SecurityPoliciesListPreconfiguredExpressionSetsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/ListPreconfiguredExpressionSets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'ListPreconfiguredExpressionSets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub disable_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DisableXpnHostProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/DisableXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'DisableXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub disable_xpn_resource {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DisableXpnResourceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/DisableXpnResource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'DisableXpnResource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::EnableXpnHostProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/EnableXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'EnableXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_xpn_resource {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::EnableXpnResourceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/EnableXpnResource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'EnableXpnResource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetXpnHostProjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/GetXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'GetXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_xpn_resources {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetXpnResourcesProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ProjectsGetXpnResources';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/GetXpnResources',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'GetXpnResources',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_xpn_hosts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListXpnHostsProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::XpnHostList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/ListXpnHosts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'ListXpnHosts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveDiskProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/MoveDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'MoveDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveInstanceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/MoveInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'MoveInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_cloud_armor_tier {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetCloudArmorTierProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetCloudArmorTier',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetCloudArmorTier',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_common_instance_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetCommonInstanceMetadataProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetCommonInstanceMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetCommonInstanceMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_default_network_tier {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDefaultNetworkTierProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetDefaultNetworkTier',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetDefaultNetworkTier',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_usage_export_bucket {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetUsageExportBucketProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetUsageExportBucket',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetUsageExportBucket',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub announce {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AnnouncePublicAdvertisedPrefixeRequest';
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
            path           => '/google.cloud.compute.v1.PublicAdvertisedPrefixes/Announce',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.PublicAdvertisedPrefixes',
        method         => 'Announce',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub withdraw {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::WithdrawPublicAdvertisedPrefixeRequest';
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
            path           => '/google.cloud.compute.v1.PublicAdvertisedPrefixes/Withdraw',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.PublicAdvertisedPrefixes',
        method         => 'Withdraw',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchAssociationRegionNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1.RegionNetworkFirewallPolicies/PatchAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionNetworkFirewallPolicies',
        method         => 'PatchAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_available_features {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListAvailableFeaturesRegionSslPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SslPoliciesListAvailableFeaturesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionSslPolicies/ListAvailableFeatures',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionSslPolicies',
        method         => 'ListAvailableFeatures',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_url_map {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetUrlMapRegionTargetHttpProxyRequest';
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
            path           => '/google.cloud.compute.v1.RegionTargetHttpProxies/SetUrlMap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpProxies',
        method         => 'SetUrlMap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_ssl_certificates {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSslCertificatesRegionTargetHttpsProxyRequest';
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
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/SetSslCertificates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'SetSslCertificates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub validate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ValidateRegionUrlMapRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::UrlMapsValidateResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionUrlMaps/Validate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionUrlMaps',
        method         => 'Validate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub advance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AdvanceRolloutRequest';
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
            path           => '/google.cloud.compute.v1.Rollouts/Advance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Advance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub pause {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PauseRolloutRequest';
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
            path           => '/google.cloud.compute.v1.Rollouts/Pause',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Pause',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/DeleteNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'DeleteNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/DeleteRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'DeleteRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetNamedSetRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersGetNamedSetResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/GetNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'GetNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_nat_ip_info {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetNatIpInfoRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NatIpInfoResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/GetNatIpInfo',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'GetNatIpInfo',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_nat_mapping_info {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetNatMappingInfoRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::VmEndpointNatMappingsList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/GetNatMappingInfo',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'GetNatMappingInfo',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRoutePolicyRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersGetRoutePolicyResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/GetRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'GetRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_router_status {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRouterStatusRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RouterStatusResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/GetRouterStatus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'GetRouterStatus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_bgp_routes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListBgpRoutesRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersListBgpRoutes';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/ListBgpRoutes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'ListBgpRoutes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_named_sets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListNamedSetsRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersListNamedSets';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/ListNamedSets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'ListNamedSets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_route_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRoutePoliciesRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersListRoutePolicies';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/ListRoutePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'ListRoutePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/PatchNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'PatchNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/PatchRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'PatchRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub preview {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PreviewRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RoutersPreviewResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Routers/Preview',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'Preview',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/UpdateNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'UpdateNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdateRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1.Routers/UpdateRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Routers',
        method         => 'UpdateRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_disks {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListDisksStoragePoolsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::StoragePoolListDisks';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.StoragePools/ListDisks',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.StoragePools',
        method         => 'ListDisks',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub expand_ip_cidr_range {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ExpandIpCidrRangeSubnetworkRequest';
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
            path           => '/google.cloud.compute.v1.Subnetworks/ExpandIpCidrRange',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Subnetworks',
        method         => 'ExpandIpCidrRange',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_private_ip_google_access {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetPrivateIpGoogleAccessSubnetworkRequest';
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
            path           => '/google.cloud.compute.v1.Subnetworks/SetPrivateIpGoogleAccess',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Subnetworks',
        method         => 'SetPrivateIpGoogleAccess',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_certificate_map {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetCertificateMapTargetHttpsProxyRequest';
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
            path           => '/google.cloud.compute.v1.TargetHttpsProxies/SetCertificateMap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetHttpsProxies',
        method         => 'SetCertificateMap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_quic_override {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetQuicOverrideTargetHttpsProxyRequest';
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
            path           => '/google.cloud.compute.v1.TargetHttpsProxies/SetQuicOverride',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetHttpsProxies',
        method         => 'SetQuicOverride',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_ssl_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSslPolicyTargetHttpsProxyRequest';
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
            path           => '/google.cloud.compute.v1.TargetHttpsProxies/SetSslPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetHttpsProxies',
        method         => 'SetSslPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_health_check {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddHealthCheckTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1.TargetPools/AddHealthCheck',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetPools',
        method         => 'AddHealthCheck',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddInstanceTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1.TargetPools/AddInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetPools',
        method         => 'AddInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_health_check {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveHealthCheckTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1.TargetPools/RemoveHealthCheck',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetPools',
        method         => 'RemoveHealthCheck',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveInstanceTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1.TargetPools/RemoveInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetPools',
        method         => 'RemoveInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_backup {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetBackupTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1.TargetPools/SetBackup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetPools',
        method         => 'SetBackup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_backend_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetBackendServiceTargetSslProxyRequest';
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
            path           => '/google.cloud.compute.v1.TargetSslProxies/SetBackendService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetSslProxies',
        method         => 'SetBackendService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_proxy_header {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetProxyHeaderTargetSslProxyRequest';
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
            path           => '/google.cloud.compute.v1.TargetSslProxies/SetProxyHeader',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.TargetSslProxies',
        method         => 'SetProxyHeader',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub invalidate_cache {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InvalidateCacheUrlMapRequest';
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
            path           => '/google.cloud.compute.v1.UrlMaps/InvalidateCache',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.UrlMaps',
        method         => 'InvalidateCache',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_status {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetStatusVpnGatewayRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::VpnGatewaysGetStatusResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.VpnGateways/GetStatus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.VpnGateways',
        method         => 'GetStatus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1

__END__

=head1 NAME

Google::Cloud::Compute::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1->new(
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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1.AcceleratorTypes>.

Request: L<Google::Cloud::Compute::V1::Compute::AggregatedListAcceleratorTypesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::AcceleratorTypeAggregatedList>

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

=item * B<get>

    my $response = $client->get(
        accelerator_type         => $accelerator_type,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.AcceleratorTypes>.

Request: L<Google::Cloud::Compute::V1::Compute::GetAcceleratorTypeRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::AcceleratorType>

Parameters:

=over 4

=item * C<accelerator_type> - C<string>

=item * C<project> - C<string>

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

Calls the RPC method C<List> on C<google.cloud.compute.v1.AcceleratorTypes>.

Request: L<Google::Cloud::Compute::V1::Compute::ListAcceleratorTypesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::AcceleratorTypeList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        address                  => $address,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.Addresses>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteAddressRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<address> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        address_resource         => $address_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.Addresses>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertAddressRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<address_resource> - L<Google::Cloud::Compute::V1::Compute::Address>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<move>

    my $response = $client->move(
        address                  => $address,
        project                  => $project,
        region                   => $region,
        region_addresses_move_request_resource => $region_addresses_move_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<Move> on C<google.cloud.compute.v1.Addresses>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveAddressRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<address> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_addresses_move_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionAddressesMoveRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_labels>

    my $response = $client->set_labels(
        project                  => $project,
        region                   => $region,
        region_set_labels_request_resource => $region_set_labels_request_resource,
        request_id               => $request_id,
        resource                 => $resource,
    );

Calls the RPC method C<SetLabels> on C<google.cloud.compute.v1.Addresses>.

Request: L<Google::Cloud::Compute::V1::Compute::SetLabelsAddressRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_set_labels_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionSetLabelsRequest>

=item * C<request_id> - C<string>

=item * C<resource> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        region                   => $region,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1.Addresses>.

Request: L<Google::Cloud::Compute::V1::Compute::TestIamPermissionsAddressRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1::Compute::TestPermissionsRequest>

=back

=item * B<calendar_mode>

    my $response = $client->calendar_mode(
        calendar_mode_advice_request_resource => $calendar_mode_advice_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<CalendarMode> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRpcRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceResponse>

Parameters:

=over 4

=item * C<calendar_mode_advice_request_resource> - L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<capacity>

    my $response = $client->capacity(
        capacity_advice_request_resource => $capacity_advice_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<Capacity> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CapacityAdviceRpcRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CapacityAdviceResponse>

Parameters:

=over 4

=item * C<capacity_advice_request_resource> - L<Google::Cloud::Compute::V1::Compute::CapacityAdviceRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<capacity_history>

    my $response = $client->capacity_history(
        capacity_history_request_resource => $capacity_history_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<CapacityHistory> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CapacityHistoryAdviceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CapacityHistoryResponse>

Parameters:

=over 4

=item * C<capacity_history_request_resource> - L<Google::Cloud::Compute::V1::Compute::CapacityHistoryRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        autoscaler               => $autoscaler,
        autoscaler_resource      => $autoscaler_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.Autoscalers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchAutoscalerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<autoscaler> - C<string>

=item * C<autoscaler_resource> - L<Google::Cloud::Compute::V1::Compute::Autoscaler>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        autoscaler               => $autoscaler,
        autoscaler_resource      => $autoscaler_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1.Autoscalers>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateAutoscalerRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<autoscaler> - C<string>

=item * C<autoscaler_resource> - L<Google::Cloud::Compute::V1::Compute::Autoscaler>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<add_signed_url_key>

    my $response = $client->add_signed_url_key(
        backend_bucket           => $backend_bucket,
        project                  => $project,
        request_id               => $request_id,
        signed_url_key_resource  => $signed_url_key_resource,
    );

Calls the RPC method C<AddSignedUrlKey> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::AddSignedUrlKeyBackendBucketRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<backend_bucket> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<signed_url_key_resource> - L<Google::Cloud::Compute::V1::Compute::SignedUrlKey>

=back

=item * B<delete_signed_url_key>

    my $response = $client->delete_signed_url_key(
        backend_bucket           => $backend_bucket,
        key_name                 => $key_name,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<DeleteSignedUrlKey> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteSignedUrlKeyBackendBucketRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<backend_bucket> - C<string>

=item * C<key_name> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        resource                 => $resource,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::GetIamPolicyBackendBucketRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=back

=item * B<list_usable>

    my $response = $client->list_usable(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<ListUsable> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::ListUsableBackendBucketsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::BackendBucketListUsable>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<set_edge_security_policy>

    my $response = $client->set_edge_security_policy(
        backend_bucket           => $backend_bucket,
        project                  => $project,
        request_id               => $request_id,
        security_policy_reference_resource => $security_policy_reference_resource,
    );

Calls the RPC method C<SetEdgeSecurityPolicy> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::SetEdgeSecurityPolicyBackendBucketRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<backend_bucket> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy_reference_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicyReference>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        global_set_policy_request_resource => $global_set_policy_request_resource,
        project                  => $project,
        resource                 => $resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1.BackendBuckets>.

Request: L<Google::Cloud::Compute::V1::Compute::SetIamPolicyBackendBucketRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Policy>

Parameters:

=over 4

=item * C<global_set_policy_request_resource> - L<Google::Cloud::Compute::V1::Compute::GlobalSetPolicyRequest>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=back

=item * B<get_effective_security_policies>

    my $response = $client->get_effective_security_policies(
        backend_service          => $backend_service,
        project                  => $project,
    );

Calls the RPC method C<GetEffectiveSecurityPolicies> on C<google.cloud.compute.v1.BackendServices>.

Request: L<Google::Cloud::Compute::V1::Compute::GetEffectiveSecurityPoliciesBackendServiceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::GetEffectiveSecurityPoliciesBackendServiceResponse>

Parameters:

=over 4

=item * C<backend_service> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_health>

    my $response = $client->get_health(
        backend_service          => $backend_service,
        project                  => $project,
        resource_group_reference_resource => $resource_group_reference_resource,
    );

Calls the RPC method C<GetHealth> on C<google.cloud.compute.v1.BackendServices>.

Request: L<Google::Cloud::Compute::V1::Compute::GetHealthBackendServiceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::BackendServiceGroupHealth>

Parameters:

=over 4

=item * C<backend_service> - C<string>

=item * C<project> - C<string>

=item * C<resource_group_reference_resource> - L<Google::Cloud::Compute::V1::Compute::ResourceGroupReference>

=back

=item * B<set_security_policy>

    my $response = $client->set_security_policy(
        backend_service          => $backend_service,
        project                  => $project,
        request_id               => $request_id,
        security_policy_reference_resource => $security_policy_reference_resource,
    );

Calls the RPC method C<SetSecurityPolicy> on C<google.cloud.compute.v1.BackendServices>.

Request: L<Google::Cloud::Compute::V1::Compute::SetSecurityPolicyBackendServiceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<backend_service> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy_reference_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicyReference>

=back

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

=item * B<add_association>

    my $response = $client->add_association(
        firewall_policy          => $firewall_policy,
        firewall_policy_association_resource => $firewall_policy_association_resource,
        replace_existing_association => $replace_existing_association,
        request_id               => $request_id,
    );

Calls the RPC method C<AddAssociation> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AddAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_association_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyAssociation>

=item * C<replace_existing_association> - C<bool>

=item * C<request_id> - C<string>

=back

=item * B<add_rule>

    my $response = $client->add_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<AddRule> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AddRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

=item * C<request_id> - C<string>

=back

=item * B<clone_rules>

    my $response = $client->clone_rules(
        firewall_policy          => $firewall_policy,
        request_id               => $request_id,
        source_firewall_policy   => $source_firewall_policy,
    );

Calls the RPC method C<CloneRules> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::CloneRulesFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<request_id> - C<string>

=item * C<source_firewall_policy> - C<string>

=back

=item * B<get_association>

    my $response = $client->get_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
    );

Calls the RPC method C<GetAssociation> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::FirewallPolicyAssociation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

=back

=item * B<get_rule>

    my $response = $client->get_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
    );

Calls the RPC method C<GetRule> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=back

=item * B<list_associations>

    my $response = $client->list_associations(
        include_inherited_policies => $include_inherited_policies,
        target_resource          => $target_resource,
    );

Calls the RPC method C<ListAssociations> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListAssociationsFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::FirewallPoliciesListAssociationsResponse>

Parameters:

=over 4

=item * C<include_inherited_policies> - C<bool>

=item * C<target_resource> - C<string>

=back

=item * B<patch_rule>

    my $response = $client->patch_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchRule> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<remove_association>

    my $response = $client->remove_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveAssociation> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_rule>

    my $response = $client->remove_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveRule> on C<google.cloud.compute.v1.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<set_target>

    my $response = $client->set_target(
        forwarding_rule          => $forwarding_rule,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_reference_resource => $target_reference_resource,
    );

Calls the RPC method C<SetTarget> on C<google.cloud.compute.v1.ForwardingRules>.

Request: L<Google::Cloud::Compute::V1::Compute::SetTargetForwardingRuleRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<forwarding_rule> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_reference_resource> - L<Google::Cloud::Compute::V1::Compute::TargetReference>

=back

=item * B<cancel>

    my $response = $client->cancel(
        future_reservation       => $future_reservation,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Cancel> on C<google.cloud.compute.v1.FutureReservations>.

Request: L<Google::Cloud::Compute::V1::Compute::CancelFutureReservationRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<future_reservation> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

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

=item * B<wait>

    my $response = $client->wait(
        operation                => $operation,
        project                  => $project,
    );

Calls the RPC method C<Wait> on C<google.cloud.compute.v1.GlobalOperations>.

Request: L<Google::Cloud::Compute::V1::Compute::WaitGlobalOperationRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<operation> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_version>

    my $response = $client->get_version(
        association              => $association,
        host                     => $host,
        hosts_get_version_request_resource => $hosts_get_version_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<GetVersion> on C<google.cloud.compute.v1.Hosts>.

Request: L<Google::Cloud::Compute::V1::Compute::GetVersionHostRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<association> - C<string>

=item * C<host> - C<string>

=item * C<hosts_get_version_request_resource> - L<Google::Cloud::Compute::V1::Compute::HostsGetVersionRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<deprecate>

    my $response = $client->deprecate(
        deprecation_status_resource => $deprecation_status_resource,
        image                    => $image,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Deprecate> on C<google.cloud.compute.v1.Images>.

Request: L<Google::Cloud::Compute::V1::Compute::DeprecateImageRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<deprecation_status_resource> - L<Google::Cloud::Compute::V1::Compute::DeprecationStatus>

=item * C<image> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get_from_family>

    my $response = $client->get_from_family(
        family                   => $family,
        project                  => $project,
    );

Calls the RPC method C<GetFromFamily> on C<google.cloud.compute.v1.Images>.

Request: L<Google::Cloud::Compute::V1::Compute::GetFromFamilyImageRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Image>

Parameters:

=over 4

=item * C<family> - C<string>

=item * C<project> - C<string>

=back

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

=item * B<add_instances>

    my $response = $client->add_instances(
        instance_group           => $instance_group,
        instance_groups_add_instances_request_resource => $instance_groups_add_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddInstances> on C<google.cloud.compute.v1.InstanceGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::AddInstancesInstanceGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group> - C<string>

=item * C<instance_groups_add_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupsAddInstancesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<list_instances>

    my $response = $client->list_instances(
        filter                   => $filter,
        instance_group           => $instance_group,
        instance_groups_list_instances_request_resource => $instance_groups_list_instances_request_resource,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<ListInstances> on C<google.cloud.compute.v1.InstanceGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::ListInstancesInstanceGroupsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceGroupsListInstances>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance_group> - C<string>

=item * C<instance_groups_list_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupsListInstancesRequest>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<remove_instances>

    my $response = $client->remove_instances(
        instance_group           => $instance_group,
        instance_groups_remove_instances_request_resource => $instance_groups_remove_instances_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<RemoveInstances> on C<google.cloud.compute.v1.InstanceGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveInstancesInstanceGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group> - C<string>

=item * C<instance_groups_remove_instances_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupsRemoveInstancesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_named_ports>

    my $response = $client->set_named_ports(
        instance_group           => $instance_group,
        instance_groups_set_named_ports_request_resource => $instance_groups_set_named_ports_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetNamedPorts> on C<google.cloud.compute.v1.InstanceGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::SetNamedPortsInstanceGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_group> - C<string>

=item * C<instance_groups_set_named_ports_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceGroupsSetNamedPortsRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<add_access_config>

    my $response = $client->add_access_config(
        access_config_resource   => $access_config_resource,
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddAccessConfig> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::AddAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<access_config_resource> - L<Google::Cloud::Compute::V1::Compute::AccessConfig>

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

Calls the RPC method C<AddNetworkInterface> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::AddNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface_resource> - L<Google::Cloud::Compute::V1::Compute::NetworkInterface>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

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

Calls the RPC method C<AttachDisk> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::AttachDiskInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<attached_disk_resource> - L<Google::Cloud::Compute::V1::Compute::AttachedDisk>

=item * C<force_attach> - C<bool>

=item * C<instance> - C<string>

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

Calls the RPC method C<DeleteAccessConfig> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<DeleteNetworkInterface> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<DetachDisk> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::DetachDiskInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<device_name> - C<string>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_effective_firewalls>

    my $response = $client->get_effective_firewalls(
        instance                 => $instance,
        network_interface        => $network_interface,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetEffectiveFirewalls> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstancesGetEffectiveFirewallsResponse>

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

Calls the RPC method C<GetGuestAttributes> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::GetGuestAttributesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::GuestAttributes>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<query_path> - C<string>

=item * C<variable_key> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_screenshot>

    my $response = $client->get_screenshot(
        instance                 => $instance,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<GetScreenshot> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::GetScreenshotInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Screenshot>

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

Calls the RPC method C<GetSerialPortOutput> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::GetSerialPortOutputInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SerialPortOutput>

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

Calls the RPC method C<GetShieldedInstanceIdentity> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::GetShieldedInstanceIdentityInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::ShieldedInstanceIdentity>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

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
        zone                     => $zone,
    );

Calls the RPC method C<ListReferrers> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::ListReferrersInstancesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InstanceListReferrers>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<instance> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<perform_maintenance>

    my $response = $client->perform_maintenance(
        instance                 => $instance,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<PerformMaintenance> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::PerformMaintenanceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

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

Calls the RPC method C<ReportHostAsFaulty> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::ReportHostAsFaultyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_report_host_as_faulty_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesReportHostAsFaultyRequest>

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

Calls the RPC method C<Reset> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::ResetInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<Resume> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::ResumeInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

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

Calls the RPC method C<SendDiagnosticInterrupt> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SendDiagnosticInterruptInstanceResponse>

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

Calls the RPC method C<SetDeletionProtection> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetDeletionProtectionInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<SetDiskAutoDelete> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetDiskAutoDeleteInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<auto_delete> - C<bool>

=item * C<device_name> - C<string>

=item * C<instance> - C<string>

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

Calls the RPC method C<SetMachineResources> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetMachineResourcesInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_machine_resources_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesSetMachineResourcesRequest>

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

Calls the RPC method C<SetMachineType> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetMachineTypeInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_machine_type_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesSetMachineTypeRequest>

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

Calls the RPC method C<SetMetadata> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetMetadataInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<metadata_resource> - L<Google::Cloud::Compute::V1::Compute::Metadata>

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

Calls the RPC method C<SetMinCpuPlatform> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetMinCpuPlatformInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_min_cpu_platform_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesSetMinCpuPlatformRequest>

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

Calls the RPC method C<SetName> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetNameInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_name_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesSetNameRequest>

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

Calls the RPC method C<SetScheduling> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetSchedulingInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<scheduling_resource> - L<Google::Cloud::Compute::V1::Compute::Scheduling>

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

Calls the RPC method C<SetServiceAccount> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetServiceAccountInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_set_service_account_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesSetServiceAccountRequest>

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

Calls the RPC method C<SetShieldedInstanceIntegrityPolicy> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetShieldedInstanceIntegrityPolicyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_instance_integrity_policy_resource> - L<Google::Cloud::Compute::V1::Compute::ShieldedInstanceIntegrityPolicy>

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

Calls the RPC method C<SetTags> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SetTagsInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<tags_resource> - L<Google::Cloud::Compute::V1::Compute::Tags>

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

Calls the RPC method C<SimulateMaintenanceEvent> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SimulateMaintenanceEventInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<Start> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::StartInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<StartWithEncryptionKey> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::StartWithEncryptionKeyInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<instances_start_with_encryption_key_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstancesStartWithEncryptionKeyRequest>

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

Calls the RPC method C<Stop> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::StopInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

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

Calls the RPC method C<Suspend> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::SuspendInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<discard_local_ssd> - C<bool>

=item * C<instance> - C<string>

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

Calls the RPC method C<UpdateAccessConfig> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateAccessConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<access_config_resource> - L<Google::Cloud::Compute::V1::Compute::AccessConfig>

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

Calls the RPC method C<UpdateDisplayDevice> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateDisplayDeviceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<display_device_resource> - L<Google::Cloud::Compute::V1::Compute::DisplayDevice>

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

Calls the RPC method C<UpdateNetworkInterface> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateNetworkInterfaceInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<network_interface> - C<string>

=item * C<network_interface_resource> - L<Google::Cloud::Compute::V1::Compute::NetworkInterface>

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

Calls the RPC method C<UpdateShieldedInstanceConfig> on C<google.cloud.compute.v1.Instances>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateShieldedInstanceConfigInstanceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<shielded_instance_config_resource> - L<Google::Cloud::Compute::V1::Compute::ShieldedInstanceConfig>

=item * C<zone> - C<string>

=back

=item * B<get_operational_status>

    my $response = $client->get_operational_status(
        interconnect_attachment_group => $interconnect_attachment_group,
        project                  => $project,
    );

Calls the RPC method C<GetOperationalStatus> on C<google.cloud.compute.v1.InterconnectAttachmentGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::GetOperationalStatusInterconnectAttachmentGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InterconnectAttachmentGroupsGetOperationalStatusResponse>

Parameters:

=over 4

=item * C<interconnect_attachment_group> - C<string>

=item * C<project> - C<string>

=back

=item * B<create_members>

    my $response = $client->create_members(
        interconnect_group       => $interconnect_group,
        interconnect_groups_create_members_request_resource => $interconnect_groups_create_members_request_resource,
        project                  => $project,
    );

Calls the RPC method C<CreateMembers> on C<google.cloud.compute.v1.InterconnectGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::CreateMembersInterconnectGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<interconnect_group> - C<string>

=item * C<interconnect_groups_create_members_request_resource> - L<Google::Cloud::Compute::V1::Compute::InterconnectGroupsCreateMembersRequest>

=item * C<project> - C<string>

=back

=item * B<get_diagnostics>

    my $response = $client->get_diagnostics(
        interconnect             => $interconnect,
        project                  => $project,
    );

Calls the RPC method C<GetDiagnostics> on C<google.cloud.compute.v1.Interconnects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetDiagnosticsInterconnectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InterconnectsGetDiagnosticsResponse>

Parameters:

=over 4

=item * C<interconnect> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_macsec_config>

    my $response = $client->get_macsec_config(
        interconnect             => $interconnect,
        project                  => $project,
    );

Calls the RPC method C<GetMacsecConfig> on C<google.cloud.compute.v1.Interconnects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetMacsecConfigInterconnectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::InterconnectsGetMacsecConfigResponse>

Parameters:

=over 4

=item * C<interconnect> - C<string>

=item * C<project> - C<string>

=back

=item * B<add_packet_mirroring_rule>

    my $response = $client->add_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        max_priority             => $max_priority,
        min_priority             => $min_priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<AddPacketMirroringRule> on C<google.cloud.compute.v1.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AddPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

=item * C<max_priority> - C<int32>

=item * C<min_priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get_packet_mirroring_rule>

    my $response = $client->get_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        project                  => $project,
    );

Calls the RPC method C<GetPacketMirroringRule> on C<google.cloud.compute.v1.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=back

=item * B<patch_packet_mirroring_rule>

    my $response = $client->patch_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchPacketMirroringRule> on C<google.cloud.compute.v1.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_packet_mirroring_rule>

    my $response = $client->remove_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RemovePacketMirroringRule> on C<google.cloud.compute.v1.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::RemovePacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<add_peering>

    my $response = $client->add_peering(
        network                  => $network,
        networks_add_peering_request_resource => $networks_add_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<AddPeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::AddPeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_add_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksAddPeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<cancel_request_remove_peering>

    my $response = $client->cancel_request_remove_peering(
        network                  => $network,
        networks_cancel_request_remove_peering_request_resource => $networks_cancel_request_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<CancelRequestRemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::CancelRequestRemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_cancel_request_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksCancelRequestRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list_peering_routes>

    my $response = $client->list_peering_routes(
        direction                => $direction,
        filter                   => $filter,
        max_results              => $max_results,
        network                  => $network,
        order_by                 => $order_by,
        page_token               => $page_token,
        peering_name             => $peering_name,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListPeeringRoutes> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::ListPeeringRoutesNetworksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList>

Parameters:

=over 4

=item * C<direction> - C<string>

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<network> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<peering_name> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<remove_peering>

    my $response = $client->remove_peering(
        network                  => $network,
        networks_remove_peering_request_resource => $networks_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::RemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<request_remove_peering>

    my $response = $client->request_remove_peering(
        network                  => $network,
        networks_request_remove_peering_request_resource => $networks_request_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RequestRemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::RequestRemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_request_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksRequestRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<switch_to_custom_mode>

    my $response = $client->switch_to_custom_mode(
        network                  => $network,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<SwitchToCustomMode> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::SwitchToCustomModeNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<update_peering>

    my $response = $client->update_peering(
        network                  => $network,
        networks_update_peering_request_resource => $networks_update_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdatePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdatePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_update_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksUpdatePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<add_nodes>

    my $response = $client->add_nodes(
        node_group               => $node_group,
        node_groups_add_nodes_request_resource => $node_groups_add_nodes_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<AddNodes> on C<google.cloud.compute.v1.NodeGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::AddNodesNodeGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<node_group> - C<string>

=item * C<node_groups_add_nodes_request_resource> - L<Google::Cloud::Compute::V1::Compute::NodeGroupsAddNodesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<delete_nodes>

    my $response = $client->delete_nodes(
        node_group               => $node_group,
        node_groups_delete_nodes_request_resource => $node_groups_delete_nodes_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<DeleteNodes> on C<google.cloud.compute.v1.NodeGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteNodesNodeGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<node_group> - C<string>

=item * C<node_groups_delete_nodes_request_resource> - L<Google::Cloud::Compute::V1::Compute::NodeGroupsDeleteNodesRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<list_nodes>

    my $response = $client->list_nodes(
        filter                   => $filter,
        max_results              => $max_results,
        node_group               => $node_group,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        zone                     => $zone,
    );

Calls the RPC method C<ListNodes> on C<google.cloud.compute.v1.NodeGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::ListNodesNodeGroupsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NodeGroupsListNodes>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<node_group> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<zone> - C<string>

=back

=item * B<set_node_template>

    my $response = $client->set_node_template(
        node_group               => $node_group,
        node_groups_set_node_template_request_resource => $node_groups_set_node_template_request_resource,
        project                  => $project,
        request_id               => $request_id,
        zone                     => $zone,
    );

Calls the RPC method C<SetNodeTemplate> on C<google.cloud.compute.v1.NodeGroups>.

Request: L<Google::Cloud::Compute::V1::Compute::SetNodeTemplateNodeGroupRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<node_group> - C<string>

=item * C<node_groups_set_node_template_request_resource> - L<Google::Cloud::Compute::V1::Compute::NodeGroupsSetNodeTemplateRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<zone> - C<string>

=back

=item * B<copy_rules>

    my $response = $client->copy_rules(
        request_id               => $request_id,
        security_policy          => $security_policy,
        source_security_policy   => $source_security_policy,
    );

Calls the RPC method C<CopyRules> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::CopyRulesOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=item * C<source_security_policy> - C<string>

=back

=item * B<list_preconfigured_expression_sets>

    my $response = $client->list_preconfigured_expression_sets(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        parent_id                => $parent_id,
    );

Calls the RPC method C<ListPreconfiguredExpressionSets> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListPreconfiguredExpressionSetsOrganizationSecurityPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SecurityPoliciesListPreconfiguredExpressionSetsResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<parent_id> - C<string>

=back

=item * B<disable_xpn_host>

    my $response = $client->disable_xpn_host(
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<DisableXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::DisableXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<disable_xpn_resource>

    my $response = $client->disable_xpn_resource(
        project                  => $project,
        projects_disable_xpn_resource_request_resource => $projects_disable_xpn_resource_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<DisableXpnResource> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::DisableXpnResourceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_disable_xpn_resource_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsDisableXpnResourceRequest>

=item * C<request_id> - C<string>

=back

=item * B<enable_xpn_host>

    my $response = $client->enable_xpn_host(
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<EnableXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::EnableXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<enable_xpn_resource>

    my $response = $client->enable_xpn_resource(
        project                  => $project,
        projects_enable_xpn_resource_request_resource => $projects_enable_xpn_resource_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<EnableXpnResource> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::EnableXpnResourceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_enable_xpn_resource_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsEnableXpnResourceRequest>

=item * C<request_id> - C<string>

=back

=item * B<get_xpn_host>

    my $response = $client->get_xpn_host(
        project                  => $project,
    );

Calls the RPC method C<GetXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Project>

Parameters:

=over 4

=item * C<project> - C<string>

=back

=item * B<get_xpn_resources>

    my $response = $client->get_xpn_resources(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<GetXpnResources> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetXpnResourcesProjectsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::ProjectsGetXpnResources>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<list_xpn_hosts>

    my $response = $client->list_xpn_hosts(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        projects_list_xpn_hosts_request_resource => $projects_list_xpn_hosts_request_resource,
    );

Calls the RPC method C<ListXpnHosts> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::ListXpnHostsProjectsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::XpnHostList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<projects_list_xpn_hosts_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsListXpnHostsRequest>

=back

=item * B<move_disk>

    my $response = $client->move_disk(
        disk_move_request_resource => $disk_move_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<MoveDisk> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveDiskProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk_move_request_resource> - L<Google::Cloud::Compute::V1::Compute::DiskMoveRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<move_instance>

    my $response = $client->move_instance(
        instance_move_request_resource => $instance_move_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<MoveInstance> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveInstanceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_move_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceMoveRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<set_cloud_armor_tier>

    my $response = $client->set_cloud_armor_tier(
        project                  => $project,
        projects_set_cloud_armor_tier_request_resource => $projects_set_cloud_armor_tier_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetCloudArmorTier> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetCloudArmorTierProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_set_cloud_armor_tier_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsSetCloudArmorTierRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_common_instance_metadata>

    my $response = $client->set_common_instance_metadata(
        metadata_resource        => $metadata_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<SetCommonInstanceMetadata> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetCommonInstanceMetadataProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<metadata_resource> - L<Google::Cloud::Compute::V1::Compute::Metadata>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<set_default_network_tier>

    my $response = $client->set_default_network_tier(
        project                  => $project,
        projects_set_default_network_tier_request_resource => $projects_set_default_network_tier_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetDefaultNetworkTier> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetDefaultNetworkTierProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_set_default_network_tier_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsSetDefaultNetworkTierRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_usage_export_bucket>

    my $response = $client->set_usage_export_bucket(
        project                  => $project,
        request_id               => $request_id,
        usage_export_location_resource => $usage_export_location_resource,
    );

Calls the RPC method C<SetUsageExportBucket> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetUsageExportBucketProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<usage_export_location_resource> - L<Google::Cloud::Compute::V1::Compute::UsageExportLocation>

=back

=item * B<announce>

    my $response = $client->announce(
        project                  => $project,
        public_advertised_prefix => $public_advertised_prefix,
        request_id               => $request_id,
    );

Calls the RPC method C<Announce> on C<google.cloud.compute.v1.PublicAdvertisedPrefixes>.

Request: L<Google::Cloud::Compute::V1::Compute::AnnouncePublicAdvertisedPrefixeRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<public_advertised_prefix> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<withdraw>

    my $response = $client->withdraw(
        project                  => $project,
        public_advertised_prefix => $public_advertised_prefix,
        request_id               => $request_id,
    );

Calls the RPC method C<Withdraw> on C<google.cloud.compute.v1.PublicAdvertisedPrefixes>.

Request: L<Google::Cloud::Compute::V1::Compute::WithdrawPublicAdvertisedPrefixeRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<public_advertised_prefix> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<patch_association>

    my $response = $client->patch_association(
        firewall_policy          => $firewall_policy,
        firewall_policy_association_resource => $firewall_policy_association_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchAssociation> on C<google.cloud.compute.v1.RegionNetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchAssociationRegionNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_association_resource> - L<Google::Cloud::Compute::V1::Compute::FirewallPolicyAssociation>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list_available_features>

    my $response = $client->list_available_features(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListAvailableFeatures> on C<google.cloud.compute.v1.RegionSslPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListAvailableFeaturesRegionSslPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SslPoliciesListAvailableFeaturesResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<set_url_map>

    my $response = $client->set_url_map(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_http_proxy        => $target_http_proxy,
        url_map_reference_resource => $url_map_reference_resource,
    );

Calls the RPC method C<SetUrlMap> on C<google.cloud.compute.v1.RegionTargetHttpProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetUrlMapRegionTargetHttpProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_http_proxy> - C<string>

=item * C<url_map_reference_resource> - L<Google::Cloud::Compute::V1::Compute::UrlMapReference>

=back

=item * B<set_ssl_certificates>

    my $response = $client->set_ssl_certificates(
        project                  => $project,
        region                   => $region,
        region_target_https_proxies_set_ssl_certificates_request_resource => $region_target_https_proxies_set_ssl_certificates_request_resource,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetSslCertificates> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetSslCertificatesRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_target_https_proxies_set_ssl_certificates_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionTargetHttpsProxiesSetSslCertificatesRequest>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<validate>

    my $response = $client->validate(
        project                  => $project,
        region                   => $region,
        region_url_maps_validate_request_resource => $region_url_maps_validate_request_resource,
        url_map                  => $url_map,
    );

Calls the RPC method C<Validate> on C<google.cloud.compute.v1.RegionUrlMaps>.

Request: L<Google::Cloud::Compute::V1::Compute::ValidateRegionUrlMapRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::UrlMapsValidateResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_url_maps_validate_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionUrlMapsValidateRequest>

=item * C<url_map> - C<string>

=back

=item * B<advance>

    my $response = $client->advance(
        current_wave_number      => $current_wave_number,
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Advance> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::AdvanceRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<current_wave_number> - C<int64>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<pause>

    my $response = $client->pause(
        etag                     => $etag,
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Pause> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::PauseRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<etag> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<delete_named_set>

    my $response = $client->delete_named_set(
        named_set                => $named_set,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<DeleteNamedSet> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<named_set> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<delete_route_policy>

    my $response = $client->delete_route_policy(
        policy                   => $policy,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<DeleteRoutePolicy> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<policy> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_named_set>

    my $response = $client->get_named_set(
        named_set                => $named_set,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetNamedSet> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersGetNamedSetResponse>

Parameters:

=over 4

=item * C<named_set> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_nat_ip_info>

    my $response = $client->get_nat_ip_info(
        nat_name                 => $nat_name,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetNatIpInfo> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetNatIpInfoRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NatIpInfoResponse>

Parameters:

=over 4

=item * C<nat_name> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_nat_mapping_info>

    my $response = $client->get_nat_mapping_info(
        filter                   => $filter,
        max_results              => $max_results,
        nat_name                 => $nat_name,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetNatMappingInfo> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetNatMappingInfoRoutersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::VmEndpointNatMappingsList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<nat_name> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_route_policy>

    my $response = $client->get_route_policy(
        policy                   => $policy,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetRoutePolicy> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersGetRoutePolicyResponse>

Parameters:

=over 4

=item * C<policy> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_router_status>

    my $response = $client->get_router_status(
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetRouterStatus> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRouterStatusRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RouterStatusResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<list_bgp_routes>

    my $response = $client->list_bgp_routes(
        address_family           => $address_family,
        destination_prefix       => $destination_prefix,
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        peer                     => $peer,
        policy_applied           => $policy_applied,
        project                  => $project,
        region                   => $region,
        route_type               => $route_type,
        router                   => $router,
    );

Calls the RPC method C<ListBgpRoutes> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListBgpRoutesRoutersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersListBgpRoutes>

Parameters:

=over 4

=item * C<address_family> - C<string>

=item * C<destination_prefix> - C<string>

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<peer> - C<string>

=item * C<policy_applied> - C<bool>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<route_type> - C<string>

=item * C<router> - C<string>

=back

=item * B<list_named_sets>

    my $response = $client->list_named_sets(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<ListNamedSets> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListNamedSetsRoutersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersListNamedSets>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<list_route_policies>

    my $response = $client->list_route_policies(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<ListRoutePolicies> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRoutePoliciesRoutersRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersListRoutePolicies>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<patch_named_set>

    my $response = $client->patch_named_set(
        named_set_resource       => $named_set_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<PatchNamedSet> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<named_set_resource> - L<Google::Cloud::Compute::V1::Compute::NamedSet>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<patch_route_policy>

    my $response = $client->patch_route_policy(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        route_policy_resource    => $route_policy_resource,
        router                   => $router,
    );

Calls the RPC method C<PatchRoutePolicy> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<route_policy_resource> - L<Google::Cloud::Compute::V1::Compute::RoutePolicy>

=item * C<router> - C<string>

=back

=item * B<preview>

    my $response = $client->preview(
        project                  => $project,
        region                   => $region,
        router                   => $router,
        router_resource          => $router_resource,
    );

Calls the RPC method C<Preview> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::PreviewRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RoutersPreviewResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=item * C<router_resource> - L<Google::Cloud::Compute::V1::Compute::Router>

=back

=item * B<update_named_set>

    my $response = $client->update_named_set(
        named_set_resource       => $named_set_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<UpdateNamedSet> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<named_set_resource> - L<Google::Cloud::Compute::V1::Compute::NamedSet>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<update_route_policy>

    my $response = $client->update_route_policy(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        route_policy_resource    => $route_policy_resource,
        router                   => $router,
    );

Calls the RPC method C<UpdateRoutePolicy> on C<google.cloud.compute.v1.Routers>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdateRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<route_policy_resource> - L<Google::Cloud::Compute::V1::Compute::RoutePolicy>

=item * C<router> - C<string>

=back

=item * B<list_disks>

    my $response = $client->list_disks(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        storage_pool             => $storage_pool,
        zone                     => $zone,
    );

Calls the RPC method C<ListDisks> on C<google.cloud.compute.v1.StoragePools>.

Request: L<Google::Cloud::Compute::V1::Compute::ListDisksStoragePoolsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::StoragePoolListDisks>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<storage_pool> - C<string>

=item * C<zone> - C<string>

=back

=item * B<expand_ip_cidr_range>

    my $response = $client->expand_ip_cidr_range(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        subnetwork               => $subnetwork,
        subnetworks_expand_ip_cidr_range_request_resource => $subnetworks_expand_ip_cidr_range_request_resource,
    );

Calls the RPC method C<ExpandIpCidrRange> on C<google.cloud.compute.v1.Subnetworks>.

Request: L<Google::Cloud::Compute::V1::Compute::ExpandIpCidrRangeSubnetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<subnetwork> - C<string>

=item * C<subnetworks_expand_ip_cidr_range_request_resource> - L<Google::Cloud::Compute::V1::Compute::SubnetworksExpandIpCidrRangeRequest>

=back

=item * B<set_private_ip_google_access>

    my $response = $client->set_private_ip_google_access(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        subnetwork               => $subnetwork,
        subnetworks_set_private_ip_google_access_request_resource => $subnetworks_set_private_ip_google_access_request_resource,
    );

Calls the RPC method C<SetPrivateIpGoogleAccess> on C<google.cloud.compute.v1.Subnetworks>.

Request: L<Google::Cloud::Compute::V1::Compute::SetPrivateIpGoogleAccessSubnetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<subnetwork> - C<string>

=item * C<subnetworks_set_private_ip_google_access_request_resource> - L<Google::Cloud::Compute::V1::Compute::SubnetworksSetPrivateIpGoogleAccessRequest>

=back

=item * B<set_certificate_map>

    my $response = $client->set_certificate_map(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxies_set_certificate_map_request_resource => $target_https_proxies_set_certificate_map_request_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetCertificateMap> on C<google.cloud.compute.v1.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetCertificateMapTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxies_set_certificate_map_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxiesSetCertificateMapRequest>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_quic_override>

    my $response = $client->set_quic_override(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxies_set_quic_override_request_resource => $target_https_proxies_set_quic_override_request_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetQuicOverride> on C<google.cloud.compute.v1.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetQuicOverrideTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxies_set_quic_override_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxiesSetQuicOverrideRequest>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_ssl_policy>

    my $response = $client->set_ssl_policy(
        project                  => $project,
        request_id               => $request_id,
        ssl_policy_reference_resource => $ssl_policy_reference_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetSslPolicy> on C<google.cloud.compute.v1.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetSslPolicyTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<ssl_policy_reference_resource> - L<Google::Cloud::Compute::V1::Compute::SslPolicyReference>

=item * C<target_https_proxy> - C<string>

=back

=item * B<add_health_check>

    my $response = $client->add_health_check(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_add_health_check_request_resource => $target_pools_add_health_check_request_resource,
    );

Calls the RPC method C<AddHealthCheck> on C<google.cloud.compute.v1.TargetPools>.

Request: L<Google::Cloud::Compute::V1::Compute::AddHealthCheckTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_add_health_check_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetPoolsAddHealthCheckRequest>

=back

=item * B<add_instance>

    my $response = $client->add_instance(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_add_instance_request_resource => $target_pools_add_instance_request_resource,
    );

Calls the RPC method C<AddInstance> on C<google.cloud.compute.v1.TargetPools>.

Request: L<Google::Cloud::Compute::V1::Compute::AddInstanceTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_add_instance_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetPoolsAddInstanceRequest>

=back

=item * B<remove_health_check>

    my $response = $client->remove_health_check(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_remove_health_check_request_resource => $target_pools_remove_health_check_request_resource,
    );

Calls the RPC method C<RemoveHealthCheck> on C<google.cloud.compute.v1.TargetPools>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveHealthCheckTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_remove_health_check_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetPoolsRemoveHealthCheckRequest>

=back

=item * B<remove_instance>

    my $response = $client->remove_instance(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_remove_instance_request_resource => $target_pools_remove_instance_request_resource,
    );

Calls the RPC method C<RemoveInstance> on C<google.cloud.compute.v1.TargetPools>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveInstanceTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_remove_instance_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetPoolsRemoveInstanceRequest>

=back

=item * B<set_backup>

    my $response = $client->set_backup(
        failover_ratio           => $failover_ratio,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_reference_resource => $target_reference_resource,
    );

Calls the RPC method C<SetBackup> on C<google.cloud.compute.v1.TargetPools>.

Request: L<Google::Cloud::Compute::V1::Compute::SetBackupTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<failover_ratio> - C<float>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_reference_resource> - L<Google::Cloud::Compute::V1::Compute::TargetReference>

=back

=item * B<set_backend_service>

    my $response = $client->set_backend_service(
        project                  => $project,
        request_id               => $request_id,
        target_ssl_proxies_set_backend_service_request_resource => $target_ssl_proxies_set_backend_service_request_resource,
        target_ssl_proxy         => $target_ssl_proxy,
    );

Calls the RPC method C<SetBackendService> on C<google.cloud.compute.v1.TargetSslProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetBackendServiceTargetSslProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_ssl_proxies_set_backend_service_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetSslProxiesSetBackendServiceRequest>

=item * C<target_ssl_proxy> - C<string>

=back

=item * B<set_proxy_header>

    my $response = $client->set_proxy_header(
        project                  => $project,
        request_id               => $request_id,
        target_ssl_proxies_set_proxy_header_request_resource => $target_ssl_proxies_set_proxy_header_request_resource,
        target_ssl_proxy         => $target_ssl_proxy,
    );

Calls the RPC method C<SetProxyHeader> on C<google.cloud.compute.v1.TargetSslProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetProxyHeaderTargetSslProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_ssl_proxies_set_proxy_header_request_resource> - L<Google::Cloud::Compute::V1::Compute::TargetSslProxiesSetProxyHeaderRequest>

=item * C<target_ssl_proxy> - C<string>

=back

=item * B<invalidate_cache>

    my $response = $client->invalidate_cache(
        cache_invalidation_rule_resource => $cache_invalidation_rule_resource,
        project                  => $project,
        request_id               => $request_id,
        url_map                  => $url_map,
    );

Calls the RPC method C<InvalidateCache> on C<google.cloud.compute.v1.UrlMaps>.

Request: L<Google::Cloud::Compute::V1::Compute::InvalidateCacheUrlMapRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<cache_invalidation_rule_resource> - L<Google::Cloud::Compute::V1::Compute::CacheInvalidationRule>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<url_map> - C<string>

=back

=item * B<get_status>

    my $response = $client->get_status(
        project                  => $project,
        region                   => $region,
        vpn_gateway              => $vpn_gateway,
    );

Calls the RPC method C<GetStatus> on C<google.cloud.compute.v1.VpnGateways>.

Request: L<Google::Cloud::Compute::V1::Compute::GetStatusVpnGatewayRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::VpnGatewaysGetStatusResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<vpn_gateway> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
