package Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient;

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

sub add_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddAssociationNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/AddAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'AddAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddPacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/AddPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'AddPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/AddRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'AddRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListNetworkFirewallPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::NetworkFirewallPolicyAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub clone_rules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::CloneRulesNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/CloneRules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'CloneRules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetAssociationNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/GetAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'GetAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetPacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/GetPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'GetPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/GetRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'GetRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListNetworkFirewallPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchPacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/PatchPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'PatchPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/PatchRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'PatchRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveAssociationNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/RemoveAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'RemoveAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemovePacketMirroringRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/RemovePacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'RemovePacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveRuleNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/RemoveRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'RemoveRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsNetworkFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.NetworkFirewallPolicies/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.NetworkFirewallPolicies',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient->new(
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

=item * B<add_association>

    my $response = $client->add_association(
        firewall_policy          => $firewall_policy,
        firewall_policy_association_resource => $firewall_policy_association_resource,
        project                  => $project,
        replace_existing_association => $replace_existing_association,
        request_id               => $request_id,
    );

Calls the RPC method C<AddAssociation> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddAssociationNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_association_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation>

=item * C<project> - C<string>

=item * C<replace_existing_association> - C<bool>

=item * C<request_id> - C<string>

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

Calls the RPC method C<AddPacketMirroringRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<max_priority> - C<int32>

=item * C<min_priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<add_rule>

    my $response = $client->add_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        max_priority             => $max_priority,
        min_priority             => $min_priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<AddRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<max_priority> - C<int32>

=item * C<min_priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListNetworkFirewallPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::NetworkFirewallPolicyAggregatedList>

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

=item * B<clone_rules>

    my $response = $client->clone_rules(
        firewall_policy          => $firewall_policy,
        project                  => $project,
        request_id               => $request_id,
        source_firewall_policy   => $source_firewall_policy,
    );

Calls the RPC method C<CloneRules> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::CloneRulesNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<source_firewall_policy> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        firewall_policy          => $firewall_policy,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        firewall_policy          => $firewall_policy,
        project                  => $project,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_association>

    my $response = $client->get_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
        project                  => $project,
    );

Calls the RPC method C<GetAssociation> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetAssociationNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        resource                 => $resource,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetIamPolicyNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=back

=item * B<get_packet_mirroring_rule>

    my $response = $client->get_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        project                  => $project,
    );

Calls the RPC method C<GetPacketMirroringRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=back

=item * B<get_rule>

    my $response = $client->get_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        project                  => $project,
    );

Calls the RPC method C<GetRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        firewall_policy_resource => $firewall_policy_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListNetworkFirewallPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<patch>

    my $response = $client->patch(
        firewall_policy          => $firewall_policy,
        firewall_policy_resource => $firewall_policy_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<patch_packet_mirroring_rule>

    my $response = $client->patch_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchPacketMirroringRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchPacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<patch_rule>

    my $response = $client->patch_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_association>

    my $response = $client->remove_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveAssociation> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveAssociationNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

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

Calls the RPC method C<RemovePacketMirroringRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemovePacketMirroringRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_rule>

    my $response = $client->remove_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveRule> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveRuleNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        global_set_policy_request_resource => $global_set_policy_request_resource,
        project                  => $project,
        resource                 => $resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetIamPolicyNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<global_set_policy_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::GlobalSetPolicyRequest>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.NetworkFirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsNetworkFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
