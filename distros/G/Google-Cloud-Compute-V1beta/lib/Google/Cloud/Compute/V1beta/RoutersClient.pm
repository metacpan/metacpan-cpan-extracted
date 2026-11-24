package Google::Cloud::Compute::V1beta::RoutersClient;

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

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RouterAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/DeleteNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'DeleteNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/DeleteRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'DeleteRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Router';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetNamedSetRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/GetNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'GetNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_nat_ip_info {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetNatIpInfoRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/GetNatIpInfo',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'GetNatIpInfo',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_nat_mapping_info {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetNatMappingInfoRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/GetNatMappingInfo',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'GetNatMappingInfo',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetRoutePolicyRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/GetRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'GetRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_router_status {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetRouterStatusRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/GetRouterStatus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'GetRouterStatus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RouterList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_bgp_routes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListBgpRoutesRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/ListBgpRoutes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'ListBgpRoutes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_named_sets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListNamedSetsRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/ListNamedSets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'ListNamedSets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_route_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListRoutePoliciesRoutersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/ListRoutePolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'ListRoutePolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/PatchNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'PatchNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/PatchRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'PatchRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub preview {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PreviewRouterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Routers/Preview',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Preview',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_named_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateNamedSetRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/UpdateNamedSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'UpdateNamedSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_route_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateRoutePolicyRouterRequest';
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
            path           => '/google.cloud.compute.v1beta.Routers/UpdateRoutePolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Routers',
        method         => 'UpdateRoutePolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::RoutersClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::RoutersClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::RoutersClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::RoutersClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::RoutersClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::RoutersClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::RoutersClient->new(
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
        return_partial_success   => $return_partial_success,
        service_project_number   => $service_project_number,
    );

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RouterAggregatedList>

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

=item * B<delete>

    my $response = $client->delete(
        etag                     => $etag,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<etag> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<delete_named_set>

    my $response = $client->delete_named_set(
        named_set                => $named_set,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<DeleteNamedSet> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

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

Calls the RPC method C<DeleteRoutePolicy> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<policy> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Router>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<get_named_set>

    my $response = $client->get_named_set(
        named_set                => $named_set,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetNamedSet> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersGetNamedSetResponse>

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

Calls the RPC method C<GetNatIpInfo> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetNatIpInfoRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::NatIpInfoResponse>

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
        return_partial_success   => $return_partial_success,
        router                   => $router,
    );

Calls the RPC method C<GetNatMappingInfo> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetNatMappingInfoRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::VmEndpointNatMappingsList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<nat_name> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<router> - C<string>

=back

=item * B<get_route_policy>

    my $response = $client->get_route_policy(
        policy                   => $policy,
        project                  => $project,
        region                   => $region,
        router                   => $router,
    );

Calls the RPC method C<GetRoutePolicy> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersGetRoutePolicyResponse>

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

Calls the RPC method C<GetRouterStatus> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetRouterStatusRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RouterStatusResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router_resource          => $router_resource,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router_resource> - L<Google::Cloud::Compute::V1beta::Compute::Router>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RouterList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<return_partial_success> - C<bool>

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
        return_partial_success   => $return_partial_success,
        route_type               => $route_type,
        router                   => $router,
    );

Calls the RPC method C<ListBgpRoutes> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListBgpRoutesRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersListBgpRoutes>

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

=item * C<return_partial_success> - C<bool>

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
        return_partial_success   => $return_partial_success,
        router                   => $router,
    );

Calls the RPC method C<ListNamedSets> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListNamedSetsRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersListNamedSets>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<return_partial_success> - C<bool>

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
        return_partial_success   => $return_partial_success,
        router                   => $router,
    );

Calls the RPC method C<ListRoutePolicies> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListRoutePoliciesRoutersRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersListRoutePolicies>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<router> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
        router_resource          => $router_resource,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=item * C<router_resource> - L<Google::Cloud::Compute::V1beta::Compute::Router>

=back

=item * B<patch_named_set>

    my $response = $client->patch_named_set(
        named_set_resource       => $named_set_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<PatchNamedSet> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<named_set_resource> - L<Google::Cloud::Compute::V1beta::Compute::NamedSet>

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

Calls the RPC method C<PatchRoutePolicy> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<route_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::RoutePolicy>

=item * C<router> - C<string>

=back

=item * B<preview>

    my $response = $client->preview(
        project                  => $project,
        region                   => $region,
        router                   => $router,
        router_resource          => $router_resource,
    );

Calls the RPC method C<Preview> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PreviewRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::RoutersPreviewResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<router> - C<string>

=item * C<router_resource> - L<Google::Cloud::Compute::V1beta::Compute::Router>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        region                   => $region,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=back

=item * B<update>

    my $response = $client->update(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
        router_resource          => $router_resource,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<router> - C<string>

=item * C<router_resource> - L<Google::Cloud::Compute::V1beta::Compute::Router>

=back

=item * B<update_named_set>

    my $response = $client->update_named_set(
        named_set_resource       => $named_set_resource,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        router                   => $router,
    );

Calls the RPC method C<UpdateNamedSet> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateNamedSetRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<named_set_resource> - L<Google::Cloud::Compute::V1beta::Compute::NamedSet>

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

Calls the RPC method C<UpdateRoutePolicy> on C<google.cloud.compute.v1beta.Routers>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateRoutePolicyRouterRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<route_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::RoutePolicy>

=item * C<router> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
