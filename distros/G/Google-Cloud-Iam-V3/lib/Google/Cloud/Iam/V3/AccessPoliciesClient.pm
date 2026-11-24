package Google::Cloud::Iam::V3::AccessPoliciesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Iam::V3::OperationMetadata;
use Google::Iam::V3::PrincipalAccessBoundaryPolicyResources;
use Google::Iam::V3::PolicyBindingResources;
use Google::Iam::V3::AccessPolicyResources;
use Google::Iam::V3::PolicyBindingsService;
use Google::Iam::V3::PrincipalAccessBoundaryPoliciesService;
use Google::Iam::V3::AccessPoliciesService;

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

    my $target = 'iam.googleapis.com:443';
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

sub create_access_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.iam.v3.AccessPolicies/CreateAccessPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.iam.v3.AccessPolicies',
        method         => 'CreateAccessPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Iam::V3::AccessPoliciesClient

__END__

=head1 NAME

Google::Cloud::Iam::V3::AccessPoliciesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Iam::V3::AccessPoliciesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Iam::V3::AccessPoliciesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Iam::V3::AccessPoliciesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Iam::V3::AccessPoliciesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/iam/v3/access_policies_service.proto>

=item * C<googleapis/google/iam/v3/access_policy_resources.proto>

=item * C<googleapis/google/iam/v3/operation_metadata.proto>

=item * C<googleapis/google/iam/v3/policy_binding_resources.proto>

=item * C<googleapis/google/iam/v3/policy_bindings_service.proto>

=item * C<googleapis/google/iam/v3/principal_access_boundary_policies_service.proto>

=item * C<googleapis/google/iam/v3/principal_access_boundary_policy_resources.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Iam::V3::AccessPoliciesClient->new(
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

=item * B<create_access_policy>

    my $response = $client->create_access_policy(
        parent                   => $parent,
        access_policy_id         => $access_policy_id,
        access_policy            => $access_policy,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateAccessPolicy> on C<google.iam.v3.AccessPolicies>.

Request: L<Google::Iam::V3::AccessPoliciesService::CreateAccessPolicyRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<access_policy_id> - C<string>

=item * C<access_policy> - L<Google::Iam::V3::AccessPolicyResources::AccessPolicy>

=item * C<validate_only> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
