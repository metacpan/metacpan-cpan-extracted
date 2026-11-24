package Google::Cloud::Visionai::V1::StreamingServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Visionai::V1::Lva;
use Google::Cloud::Visionai::V1::LvaResources;
use Google::Cloud::Visionai::V1::Common;
use Google::Cloud::Visionai::V1::StreamsResources;
use Google::Cloud::Visionai::V1::HealthService;
use Google::Cloud::Visionai::V1::StreamingResources;
use Google::Cloud::Visionai::V1::Annotations;
use Google::Cloud::Visionai::V1::LvaService;
use Google::Cloud::Visionai::V1::Warehouse;
use Google::Cloud::Visionai::V1::StreamsService;
use Google::Cloud::Visionai::V1::StreamingService;
use Google::Cloud::Visionai::V1::Platform;

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

    my $target = 'visionai.googleapis.com:443';
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

sub send_packets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.visionai.v1.StreamingService/SendPackets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'SendPackets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub receive_packets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.visionai.v1.StreamingService/ReceivePackets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'ReceivePackets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub receive_events {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.visionai.v1.StreamingService/ReceiveEvents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'ReceiveEvents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub acquire_lease {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Visionai::V1::StreamingService::Lease';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.visionai.v1.StreamingService/AcquireLease',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'AcquireLease',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Visionai::V1::StreamingServiceClient

__END__

=head1 NAME

Google::Cloud::Visionai::V1::StreamingServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::StreamingServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Visionai::V1::StreamingServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Visionai::V1::StreamingServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Visionai::V1::StreamingServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/visionai/v1/annotations.proto>

=item * C<googleapis/google/cloud/visionai/v1/common.proto>

=item * C<googleapis/google/cloud/visionai/v1/health_service.proto>

=item * C<googleapis/google/cloud/visionai/v1/lva.proto>

=item * C<googleapis/google/cloud/visionai/v1/lva_resources.proto>

=item * C<googleapis/google/cloud/visionai/v1/lva_service.proto>

=item * C<googleapis/google/cloud/visionai/v1/platform.proto>

=item * C<googleapis/google/cloud/visionai/v1/streaming_resources.proto>

=item * C<googleapis/google/cloud/visionai/v1/streaming_service.proto>

=item * C<googleapis/google/cloud/visionai/v1/streams_resources.proto>

=item * C<googleapis/google/cloud/visionai/v1/streams_service.proto>

=item * C<googleapis/google/cloud/visionai/v1/warehouse.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Visionai::V1::StreamingServiceClient->new(
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

=item * B<send_packets>

    my $response = $client->send_packets();

Calls the RPC method C<SendPackets> on C<google.cloud.visionai.v1.StreamingService>.

Request: L<Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest>

Returns: L<Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse>

=item * B<receive_packets>

    my $response = $client->receive_packets();

Calls the RPC method C<ReceivePackets> on C<google.cloud.visionai.v1.StreamingService>.

Request: L<Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest>

Returns: L<Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse>

=item * B<receive_events>

    my $response = $client->receive_events();

Calls the RPC method C<ReceiveEvents> on C<google.cloud.visionai.v1.StreamingService>.

Request: L<Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest>

Returns: L<Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse>

=item * B<acquire_lease>

    my $response = $client->acquire_lease(
        series                   => $series,
        owner                    => $owner,
        term                     => $term,
        lease_type               => $lease_type,
    );

Calls the RPC method C<AcquireLease> on C<google.cloud.visionai.v1.StreamingService>.

Request: L<Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest>

Returns: L<Google::Cloud::Visionai::V1::StreamingService::Lease>

Parameters:

=over 4

=item * C<series> - C<string>

=item * C<owner> - C<string>

=item * C<term> - L<Google::Protobuf::Duration::Duration>

=item * C<lease_type> - L<Google::Cloud::Visionai::V1::StreamingService::LeaseType>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
