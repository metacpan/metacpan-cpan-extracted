package Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Identitytoolkit::V2::MfaInfo;
use Google::Cloud::Identitytoolkit::V2::AuthenticationService;
use Google::Cloud::Identitytoolkit::V2::AccountManagementService;

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

    my $target = 'identitytoolkit.googleapis.com:443';
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

sub finalize_mfa_enrollment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.identitytoolkit.v2.AccountManagementService/FinalizeMfaEnrollment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'FinalizeMfaEnrollment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_mfa_enrollment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.identitytoolkit.v2.AccountManagementService/StartMfaEnrollment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'StartMfaEnrollment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub withdraw_mfa {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.identitytoolkit.v2.AccountManagementService/WithdrawMfa',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.identitytoolkit.v2.AccountManagementService',
        method         => 'WithdrawMfa',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient

__END__

=head1 NAME

Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/identitytoolkit/v2/account_management_service.proto>

=item * C<googleapis/google/cloud/identitytoolkit/v2/authentication_service.proto>

=item * C<googleapis/google/cloud/identitytoolkit/v2/mfa_info.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Identitytoolkit::V2::AccountManagementServiceClient->new(
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

=item * B<finalize_mfa_enrollment>

    my $response = $client->finalize_mfa_enrollment(
        id_token                 => $id_token,
        display_name             => $display_name,
        tenant_id                => $tenant_id,
    );

Calls the RPC method C<FinalizeMfaEnrollment> on C<google.cloud.identitytoolkit.v2.AccountManagementService>.

Request: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest>

Returns: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse>

Parameters:

=over 4

=item * C<id_token> - C<string>

=item * C<display_name> - C<string>

=item * C<tenant_id> - C<string>

=back

=item * B<start_mfa_enrollment>

    my $response = $client->start_mfa_enrollment(
        id_token                 => $id_token,
        tenant_id                => $tenant_id,
    );

Calls the RPC method C<StartMfaEnrollment> on C<google.cloud.identitytoolkit.v2.AccountManagementService>.

Request: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest>

Returns: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse>

Parameters:

=over 4

=item * C<id_token> - C<string>

=item * C<tenant_id> - C<string>

=back

=item * B<withdraw_mfa>

    my $response = $client->withdraw_mfa(
        id_token                 => $id_token,
        mfa_enrollment_id        => $mfa_enrollment_id,
        tenant_id                => $tenant_id,
    );

Calls the RPC method C<WithdrawMfa> on C<google.cloud.identitytoolkit.v2.AccountManagementService>.

Request: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest>

Returns: L<Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse>

Parameters:

=over 4

=item * C<id_token> - C<string>

=item * C<mfa_enrollment_id> - C<string>

=item * C<tenant_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
