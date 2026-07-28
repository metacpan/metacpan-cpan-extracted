package Google::Cloud::Iam::V1::IamPolicyClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Iam::V1::Options;
use Google::Iam::V1::Policy;
use Google::Iam::V1::ResourcePolicyMember;
use Google::Iam::V1::IamPolicy;
use Google::Iam::V1::Logging::AuditData;

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

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    my $response = $self->transport->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    my $response = $self->transport->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse';
    my $response = $self->transport->call({
        service        => 'google.iam.v1.IAMPolicy',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Iam::V1::IamPolicyClient

__END__

=head1 NAME

Google::Cloud::Iam::V1::IamPolicyClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Iam::V1::IamPolicyClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Iam::V1::IamPolicyClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Iam::V1::IamPolicyClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Iam::V1::IamPolicyClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/iam/v1/resource_policy_member.proto>

=item * C<google/iam/v1/options.proto>

=item * C<google/iam/v1/policy.proto>

=item * C<google/iam/v1/iam_policy.proto>

=item * C<google/iam/v1/logging/audit_data.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Iam::V1::IamPolicyClient->new(
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

=item * B<set_iam_policy>

Calls the RPC method C<SetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<get_iam_policy>

Calls the RPC method C<GetIamPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<test_iam_permissions>

Calls the RPC method C<TestIamPermissions> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
