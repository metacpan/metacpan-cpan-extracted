package Google::Cloud::Compute::V1beta::FirewallPoliciesClient;

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

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddAssociationFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/AddAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'AddAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddPacketMirroringRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/AddPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'AddPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/AddRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'AddRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub clone_rules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::CloneRulesFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/CloneRules',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'CloneRules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetAssociationFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/GetAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'GetAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetPacketMirroringRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/GetPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'GetPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/GetRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'GetRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListFirewallPoliciesRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_associations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListAssociationsFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/ListAssociations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'ListAssociations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::MoveFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/Move',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'Move',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchPacketMirroringRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/PatchPacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'PatchPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/PatchRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'PatchRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveAssociationFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/RemoveAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'RemoveAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemovePacketMirroringRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/RemovePacketMirroringRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'RemovePacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveRuleFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/RemoveRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'RemoveRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsFirewallPolicyRequest';
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
            path           => '/google.cloud.compute.v1beta.FirewallPolicies/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.FirewallPolicies',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::FirewallPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::FirewallPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::FirewallPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::FirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::FirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::FirewallPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::FirewallPoliciesClient->new(
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
        replace_existing_association => $replace_existing_association,
        request_id               => $request_id,
    );

Calls the RPC method C<AddAssociation> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_association_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation>

=item * C<replace_existing_association> - C<bool>

=item * C<request_id> - C<string>

=back

=item * B<add_packet_mirroring_rule>

    my $response = $client->add_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<AddPacketMirroringRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddPacketMirroringRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<request_id> - C<string>

=back

=item * B<add_rule>

    my $response = $client->add_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<AddRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<request_id> - C<string>

=back

=item * B<clone_rules>

    my $response = $client->clone_rules(
        firewall_policy          => $firewall_policy,
        request_id               => $request_id,
        source_firewall_policy   => $source_firewall_policy,
    );

Calls the RPC method C<CloneRules> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::CloneRulesFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<request_id> - C<string>

=item * C<source_firewall_policy> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        firewall_policy          => $firewall_policy,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        firewall_policy          => $firewall_policy,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=back

=item * B<get_association>

    my $response = $client->get_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
    );

Calls the RPC method C<GetAssociation> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyAssociation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        resource                 => $resource,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetIamPolicyFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<resource> - C<string>

=back

=item * B<get_packet_mirroring_rule>

    my $response = $client->get_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
    );

Calls the RPC method C<GetPacketMirroringRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetPacketMirroringRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=back

=item * B<get_rule>

    my $response = $client->get_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
    );

Calls the RPC method C<GetRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=back

=item * B<insert>

    my $response = $client->insert(
        firewall_policy_resource => $firewall_policy_resource,
        parent_id                => $parent_id,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

=item * C<parent_id> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        parent_id                => $parent_id,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListFirewallPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<parent_id> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<list_associations>

    my $response = $client->list_associations(
        include_inherited_policies => $include_inherited_policies,
        target_resource          => $target_resource,
    );

Calls the RPC method C<ListAssociations> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListAssociationsFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::FirewallPoliciesListAssociationsResponse>

Parameters:

=over 4

=item * C<include_inherited_policies> - C<bool>

=item * C<target_resource> - C<string>

=back

=item * B<move>

    my $response = $client->move(
        firewall_policy          => $firewall_policy,
        parent_id                => $parent_id,
        request_id               => $request_id,
    );

Calls the RPC method C<Move> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::MoveFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<parent_id> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        firewall_policy          => $firewall_policy,
        firewall_policy_resource => $firewall_policy_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicy>

=item * C<request_id> - C<string>

=back

=item * B<patch_packet_mirroring_rule>

    my $response = $client->patch_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchPacketMirroringRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchPacketMirroringRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<patch_rule>

    my $response = $client->patch_rule(
        firewall_policy          => $firewall_policy,
        firewall_policy_rule_resource => $firewall_policy_rule_resource,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<PatchRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<firewall_policy_rule_resource> - L<Google::Cloud::Compute::V1beta::Compute::FirewallPolicyRule>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<remove_association>

    my $response = $client->remove_association(
        firewall_policy          => $firewall_policy,
        name                     => $name,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveAssociation> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveAssociationFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<name> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_packet_mirroring_rule>

    my $response = $client->remove_packet_mirroring_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<RemovePacketMirroringRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemovePacketMirroringRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<remove_rule>

    my $response = $client->remove_rule(
        firewall_policy          => $firewall_policy,
        priority                 => $priority,
        request_id               => $request_id,
    );

Calls the RPC method C<RemoveRule> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveRuleFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<firewall_policy> - C<string>

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        global_organization_set_policy_request_resource => $global_organization_set_policy_request_resource,
        resource                 => $resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetIamPolicyFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<global_organization_set_policy_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::GlobalOrganizationSetPolicyRequest>

=item * C<resource> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.FirewallPolicies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsFirewallPolicyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
