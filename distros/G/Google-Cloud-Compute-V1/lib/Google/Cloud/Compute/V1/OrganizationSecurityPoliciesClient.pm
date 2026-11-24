package Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient;

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

sub add_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddAssociationOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/AddAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'AddAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddRuleOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/AddRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'AddRule',
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

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetOrganizationSecurityPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SecurityPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetAssociationOrganizationSecurityPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SecurityPolicyAssociation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/GetAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'GetAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRuleOrganizationSecurityPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SecurityPolicyRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/GetRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'GetRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListOrganizationSecurityPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::SecurityPolicyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_associations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListAssociationsOrganizationSecurityPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::OrganizationSecurityPoliciesListAssociationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/ListAssociations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'ListAssociations',
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

sub move {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/Move',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'Move',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRuleOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/PatchRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'PatchRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveAssociationOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/RemoveAssociation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'RemoveAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveRuleOrganizationSecurityPolicyRequest';
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
            path           => '/google.cloud.compute.v1.OrganizationSecurityPolicies/RemoveRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.OrganizationSecurityPolicies',
        method         => 'RemoveRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient->new(
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
        replace_existing_association => $replace_existing_association,
        request_id               => $request_id,
        security_policy          => $security_policy,
        security_policy_association_resource => $security_policy_association_resource,
    );

Calls the RPC method C<AddAssociation> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AddAssociationOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<replace_existing_association> - C<bool>

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=item * C<security_policy_association_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicyAssociation>

=back

=item * B<add_rule>

    my $response = $client->add_rule(
        request_id               => $request_id,
        security_policy          => $security_policy,
        security_policy_rule_resource => $security_policy_rule_resource,
    );

Calls the RPC method C<AddRule> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::AddRuleOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=item * C<security_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicyRule>

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

=item * B<delete>

    my $response = $client->delete(
        request_id               => $request_id,
        security_policy          => $security_policy,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        security_policy          => $security_policy,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SecurityPolicy>

Parameters:

=over 4

=item * C<security_policy> - C<string>

=back

=item * B<get_association>

    my $response = $client->get_association(
        name                     => $name,
        security_policy          => $security_policy,
    );

Calls the RPC method C<GetAssociation> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetAssociationOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SecurityPolicyAssociation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<security_policy> - C<string>

=back

=item * B<get_rule>

    my $response = $client->get_rule(
        priority                 => $priority,
        security_policy          => $security_policy,
    );

Calls the RPC method C<GetRule> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRuleOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SecurityPolicyRule>

Parameters:

=over 4

=item * C<priority> - C<int32>

=item * C<security_policy> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        parent_id                => $parent_id,
        request_id               => $request_id,
        security_policy_resource => $security_policy_resource,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<parent_id> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicy>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        parent_id                => $parent_id,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListOrganizationSecurityPoliciesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::SecurityPolicyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<parent_id> - C<string>

=back

=item * B<list_associations>

    my $response = $client->list_associations(
        target_resource          => $target_resource,
    );

Calls the RPC method C<ListAssociations> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListAssociationsOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::OrganizationSecurityPoliciesListAssociationsResponse>

Parameters:

=over 4

=item * C<target_resource> - C<string>

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

=item * B<move>

    my $response = $client->move(
        parent_id                => $parent_id,
        request_id               => $request_id,
        security_policy          => $security_policy,
    );

Calls the RPC method C<Move> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<parent_id> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        request_id               => $request_id,
        security_policy          => $security_policy,
        security_policy_resource => $security_policy_resource,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=item * C<security_policy_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicy>

=back

=item * B<patch_rule>

    my $response = $client->patch_rule(
        priority                 => $priority,
        request_id               => $request_id,
        security_policy          => $security_policy,
        security_policy_rule_resource => $security_policy_rule_resource,
    );

Calls the RPC method C<PatchRule> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRuleOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=item * C<security_policy_rule_resource> - L<Google::Cloud::Compute::V1::Compute::SecurityPolicyRule>

=back

=item * B<remove_association>

    my $response = $client->remove_association(
        name                     => $name,
        request_id               => $request_id,
        security_policy          => $security_policy,
    );

Calls the RPC method C<RemoveAssociation> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveAssociationOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=back

=item * B<remove_rule>

    my $response = $client->remove_rule(
        priority                 => $priority,
        request_id               => $request_id,
        security_policy          => $security_policy,
    );

Calls the RPC method C<RemoveRule> on C<google.cloud.compute.v1.OrganizationSecurityPolicies>.

Request: L<Google::Cloud::Compute::V1::Compute::RemoveRuleOrganizationSecurityPolicyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<priority> - C<int32>

=item * C<request_id> - C<string>

=item * C<security_policy> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
