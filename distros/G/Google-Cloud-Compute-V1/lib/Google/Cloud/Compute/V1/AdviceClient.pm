package Google::Cloud::Compute::V1::AdviceClient;

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

sub calendar_mode {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRpcRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CalendarModeAdviceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/CalendarMode',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'CalendarMode',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub capacity {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CapacityAdviceRpcRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CapacityAdviceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/Capacity',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'Capacity',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub capacity_history {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CapacityHistoryAdviceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::CapacityHistoryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Advice/CapacityHistory',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Advice',
        method         => 'CapacityHistory',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::AdviceClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::AdviceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::AdviceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::AdviceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::AdviceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::AdviceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::AdviceClient->new(
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

=item * B<calendar_mode>

    my $response = $client->calendar_mode(
        calendar_mode_advice_request_resource => $calendar_mode_advice_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<CalendarMode> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRpcRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceResponse>

Parameters:

=over 4

=item * C<calendar_mode_advice_request_resource> - L<Google::Cloud::Compute::V1::Compute::CalendarModeAdviceRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<capacity>

    my $response = $client->capacity(
        capacity_advice_request_resource => $capacity_advice_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<Capacity> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CapacityAdviceRpcRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CapacityAdviceResponse>

Parameters:

=over 4

=item * C<capacity_advice_request_resource> - L<Google::Cloud::Compute::V1::Compute::CapacityAdviceRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<capacity_history>

    my $response = $client->capacity_history(
        capacity_history_request_resource => $capacity_history_request_resource,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<CapacityHistory> on C<google.cloud.compute.v1.Advice>.

Request: L<Google::Cloud::Compute::V1::Compute::CapacityHistoryAdviceRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::CapacityHistoryResponse>

Parameters:

=over 4

=item * C<capacity_history_request_resource> - L<Google::Cloud::Compute::V1::Compute::CapacityHistoryRequest>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
