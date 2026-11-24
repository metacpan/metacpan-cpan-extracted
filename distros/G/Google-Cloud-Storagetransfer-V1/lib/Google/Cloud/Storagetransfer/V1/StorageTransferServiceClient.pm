package Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Storagetransfer::V1::TransferTypes;
use Google::Storagetransfer::V1::Transfer;

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

    my $target = 'storagetransfer.googleapis.com:443';
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

sub get_google_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storagetransfer.v1.StorageTransferService/GetGoogleServiceAccount',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'GetGoogleServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_transfer_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storagetransfer::V1::TransferTypes::TransferJob';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storagetransfer.v1.StorageTransferService/CreateTransferJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'CreateTransferJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_transfer_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storagetransfer::V1::TransferTypes::TransferJob';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storagetransfer.v1.StorageTransferService/UpdateTransferJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storagetransfer.v1.StorageTransferService',
        method         => 'UpdateTransferJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient

__END__

=head1 NAME

Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/storagetransfer/v1/transfer.proto>

=item * C<googleapis/google/storagetransfer/v1/transfer_types.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient->new(
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

=item * B<get_google_service_account>

    my $response = $client->get_google_service_account(
        project_id               => $project_id,
    );

Calls the RPC method C<GetGoogleServiceAccount> on C<google.storagetransfer.v1.StorageTransferService>.

Request: L<Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest>

Returns: L<Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount>

Parameters:

=over 4

=item * C<project_id> - C<string>

=back

=item * B<create_transfer_job>

    my $response = $client->create_transfer_job(
        transfer_job             => $transfer_job,
    );

Calls the RPC method C<CreateTransferJob> on C<google.storagetransfer.v1.StorageTransferService>.

Request: L<Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest>

Returns: L<Google::Storagetransfer::V1::TransferTypes::TransferJob>

Parameters:

=over 4

=item * C<transfer_job> - L<Google::Storagetransfer::V1::TransferTypes::TransferJob>

=back

=item * B<update_transfer_job>

    my $response = $client->update_transfer_job(
        job_name                 => $job_name,
        project_id               => $project_id,
        transfer_job             => $transfer_job,
        update_transfer_job_field_mask => $update_transfer_job_field_mask,
    );

Calls the RPC method C<UpdateTransferJob> on C<google.storagetransfer.v1.StorageTransferService>.

Request: L<Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest>

Returns: L<Google::Storagetransfer::V1::TransferTypes::TransferJob>

Parameters:

=over 4

=item * C<job_name> - C<string>

=item * C<project_id> - C<string>

=item * C<transfer_job> - L<Google::Storagetransfer::V1::TransferTypes::TransferJob>

=item * C<update_transfer_job_field_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
