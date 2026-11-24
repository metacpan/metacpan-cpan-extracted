package Google::Cloud::Binaryauthorization::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Binaryauthorization::V1::Resources;
use Google::Cloud::Binaryauthorization::V1::Service;

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

    my $target = 'binaryauthorization.googleapis.com:443';
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

sub get_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Binaryauthorization::V1::Resources::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1/GetPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'GetPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_attestor {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Binaryauthorization::V1::Resources::Attestor';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1/CreateAttestor',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1',
        method         => 'CreateAttestor',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub validate_attestation_occurrence {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.binaryauthorization.v1.ValidationHelperV1/ValidateAttestationOccurrence',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.binaryauthorization.v1.ValidationHelperV1',
        method         => 'ValidateAttestationOccurrence',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Binaryauthorization::V1

__END__

=head1 NAME

Google::Cloud::Binaryauthorization::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Binaryauthorization::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Binaryauthorization::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Binaryauthorization::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Binaryauthorization::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/binaryauthorization/v1/resources.proto>

=item * C<googleapis/google/cloud/binaryauthorization/v1/service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Binaryauthorization::V1->new(
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

=item * B<get_policy>

    my $response = $client->get_policy(
        name                     => $name,
    );

Calls the RPC method C<GetPolicy> on C<google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1>.

Request: L<Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest>

Returns: L<Google::Cloud::Binaryauthorization::V1::Resources::Policy>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_attestor>

    my $response = $client->create_attestor(
        parent                   => $parent,
        attestor_id              => $attestor_id,
        attestor                 => $attestor,
    );

Calls the RPC method C<CreateAttestor> on C<google.cloud.binaryauthorization.v1.BinauthzManagementServiceV1>.

Request: L<Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest>

Returns: L<Google::Cloud::Binaryauthorization::V1::Resources::Attestor>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<attestor_id> - C<string>

=item * C<attestor> - L<Google::Cloud::Binaryauthorization::V1::Resources::Attestor>

=back

=item * B<validate_attestation_occurrence>

    my $response = $client->validate_attestation_occurrence(
        attestor                 => $attestor,
        attestation              => $attestation,
        occurrence_note          => $occurrence_note,
        occurrence_resource_uri  => $occurrence_resource_uri,
    );

Calls the RPC method C<ValidateAttestationOccurrence> on C<google.cloud.binaryauthorization.v1.ValidationHelperV1>.

Request: L<Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest>

Returns: L<Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse>

Parameters:

=over 4

=item * C<attestor> - C<string>

=item * C<attestation> - L<Grafeas::V1::AttestationOccurrence::AttestationOccurrence>

=item * C<occurrence_note> - C<string>

=item * C<occurrence_resource_uri> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
