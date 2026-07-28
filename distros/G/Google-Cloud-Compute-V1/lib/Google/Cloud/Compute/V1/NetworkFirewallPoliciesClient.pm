package Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient;

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

our $VERSION = '0.02';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = 'localhost:50051';
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
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub add_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddAssociationNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'AddAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddPacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'AddPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'AddRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AggregatedListNetworkFirewallPoliciesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworkFirewallPolicyAggregatedList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub clone_rules {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CloneRulesNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'CloneRules',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetAssociationNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyAssociation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'GetAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetIamPolicyNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetPacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyRule';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'GetPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyRule';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'GetRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListNetworkFirewallPoliciesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::FirewallPolicyList';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchPacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'PatchPacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'PatchRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_association {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveAssociationNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'RemoveAssociation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_packet_mirroring_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemovePacketMirroringRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'RemovePacketMirroringRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemoveRuleNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'RemoveRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetIamPolicyNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Policy';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::TestIamPermissionsNetworkFirewallPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TestPermissionsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.NetworkFirewallPolicies',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient->new(
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

Calls the RPC method C<AddAssociation> on the service. Takes a hash of parameters representing the request.

=item * B<add_packet_mirroring_rule>

Calls the RPC method C<AddPacketMirroringRule> on the service. Takes a hash of parameters representing the request.

=item * B<add_rule>

Calls the RPC method C<AddRule> on the service. Takes a hash of parameters representing the request.

=item * B<aggregated_list>

Calls the RPC method C<AggregatedList> on the service. Takes a hash of parameters representing the request.

=item * B<clone_rules>

Calls the RPC method C<CloneRules> on the service. Takes a hash of parameters representing the request.

=item * B<delete>

Calls the RPC method C<Delete> on the service. Takes a hash of parameters representing the request.

=item * B<get>

Calls the RPC method C<Get> on the service. Takes a hash of parameters representing the request.

=item * B<get_association>

Calls the RPC method C<GetAssociation> on the service. Takes a hash of parameters representing the request.

=item * B<get_iam_policy>

Calls the RPC method C<GetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<get_packet_mirroring_rule>

Calls the RPC method C<GetPacketMirroringRule> on the service. Takes a hash of parameters representing the request.

=item * B<get_rule>

Calls the RPC method C<GetRule> on the service. Takes a hash of parameters representing the request.

=item * B<insert>

Calls the RPC method C<Insert> on the service. Takes a hash of parameters representing the request.

=item * B<list>

Calls the RPC method C<List> on the service. Takes a hash of parameters representing the request.

=item * B<patch>

Calls the RPC method C<Patch> on the service. Takes a hash of parameters representing the request.

=item * B<patch_packet_mirroring_rule>

Calls the RPC method C<PatchPacketMirroringRule> on the service. Takes a hash of parameters representing the request.

=item * B<patch_rule>

Calls the RPC method C<PatchRule> on the service. Takes a hash of parameters representing the request.

=item * B<remove_association>

Calls the RPC method C<RemoveAssociation> on the service. Takes a hash of parameters representing the request.

=item * B<remove_packet_mirroring_rule>

Calls the RPC method C<RemovePacketMirroringRule> on the service. Takes a hash of parameters representing the request.

=item * B<remove_rule>

Calls the RPC method C<RemoveRule> on the service. Takes a hash of parameters representing the request.

=item * B<set_iam_policy>

Calls the RPC method C<SetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<test_iam_permissions>

Calls the RPC method C<TestIamPermissions> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
