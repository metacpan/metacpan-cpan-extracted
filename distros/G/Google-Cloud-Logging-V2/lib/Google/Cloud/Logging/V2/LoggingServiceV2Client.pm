package Google::Cloud::Logging::V2::LoggingServiceV2Client;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Logging::V2::LogEntry;
use Google::Logging::V2::LoggingConfig;
use Google::Logging::V2::LoggingMetrics;
use Google::Logging::V2::Logging;

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

    my $target = 'logging.googleapis.com:443';
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

sub delete_log {
    my ($self, %params) = @_;

    my $request_class = 'Google::Logging::V2::Logging::DeleteLogRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.logging.v2.LoggingServiceV2/DeleteLog',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.logging.v2.LoggingServiceV2',
        method         => 'DeleteLog',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub tail_log_entries {
    my ($self, %params) = @_;

    my $request_class = 'Google::Logging::V2::Logging::TailLogEntriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Logging::V2::Logging::TailLogEntriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.logging.v2.LoggingServiceV2/TailLogEntries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.logging.v2.LoggingServiceV2',
        method         => 'TailLogEntries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Logging::V2::LoggingServiceV2Client

__END__

=head1 NAME

Google::Cloud::Logging::V2::LoggingServiceV2Client - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Logging::V2::LoggingServiceV2Client;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Logging::V2::LoggingServiceV2Client->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Logging::V2::LoggingServiceV2Client->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Logging::V2::LoggingServiceV2Client> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/logging/v2/log_entry.proto>

=item * C<googleapis/google/logging/v2/logging.proto>

=item * C<googleapis/google/logging/v2/logging_config.proto>

=item * C<googleapis/google/logging/v2/logging_metrics.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Logging::V2::LoggingServiceV2Client->new(
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

=item * B<delete_log>

    my $response = $client->delete_log(
        log_name                 => $log_name,
    );

Calls the RPC method C<DeleteLog> on C<google.logging.v2.LoggingServiceV2>.

Request: L<Google::Logging::V2::Logging::DeleteLogRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<log_name> - C<string>

=back

=item * B<tail_log_entries>

    my $response = $client->tail_log_entries(
        resource_names           => [ ... ],
        filter                   => $filter,
        buffer_window            => $buffer_window,
    );

Calls the RPC method C<TailLogEntries> on C<google.logging.v2.LoggingServiceV2>.

Request: L<Google::Logging::V2::Logging::TailLogEntriesRequest>

Returns: L<Google::Logging::V2::Logging::TailLogEntriesResponse>

Parameters:

=over 4

=item * C<resource_names> - ArrayRef of C<string>

=item * C<filter> - C<string>

=item * C<buffer_window> - L<Google::Protobuf::Duration::Duration>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
