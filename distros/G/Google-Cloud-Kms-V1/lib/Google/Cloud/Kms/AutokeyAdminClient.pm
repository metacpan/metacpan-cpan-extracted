package Google::Cloud::Kms::AutokeyAdminClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Kms::V1::Resources;
use Google::Cloud::Kms::V1::EkmService;
use Google::Cloud::Kms::V1::AutokeyAdmin;
use Google::Cloud::Kms::V1::Autokey;
use Google::Cloud::Kms::V1::HsmManagement;
use Google::Cloud::Kms::V1::Service;

our $VERSION = '0.04';

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

    my $target = 'cloudkms.googleapis.com';
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

sub update_autokey_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::UpdateAutokeyConfigRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig';
    my $response = $self->transport->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'UpdateAutokeyConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_autokey_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::GetAutokeyConfigRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::AutokeyConfig';
    my $response = $self->transport->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'GetAutokeyConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub show_effective_autokey_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Kms::V1::AutokeyAdmin::ShowEffectiveAutokeyConfigResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.kms.v1.AutokeyAdmin',
        method         => 'ShowEffectiveAutokeyConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Kms::AutokeyAdminClient

__END__

=head1 NAME

Google::Cloud::Kms::AutokeyAdminClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Kms::AutokeyAdminClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Kms::AutokeyAdminClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Kms::AutokeyAdminClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Kms::AutokeyAdminClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/kms/v1/service.proto>

=item * C<google/cloud/kms/v1/autokey.proto>

=item * C<google/cloud/kms/v1/ekm_service.proto>

=item * C<google/cloud/kms/v1/autokey_admin.proto>

=item * C<google/cloud/kms/v1/hsm_management.proto>

=item * C<google/cloud/kms/v1/resources.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Kms::AutokeyAdminClient->new(
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

=item * B<update_autokey_config>

Calls the RPC method C<UpdateAutokeyConfig> on the service. Takes a hash of parameters representing the request.

=item * B<get_autokey_config>

Calls the RPC method C<GetAutokeyConfig> on the service. Takes a hash of parameters representing the request.

=item * B<show_effective_autokey_config>

Calls the RPC method C<ShowEffectiveAutokeyConfig> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
