package Google::Cloud::Bigtable::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Bigtable::V2::PeerInfo;
use Google::Bigtable::V2::ResponseParams;
use Google::Bigtable::V2::RequestStats;
use Google::Bigtable::V2::FeatureFlags;
use Google::Bigtable::V2::Types;
use Google::Bigtable::V2::Data;
use Google::Bigtable::V2::Session;
use Google::Bigtable::V2::Bigtable;

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

    my $target = 'bigtable.googleapis.com:443';
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

sub read_rows {
    my ($self, %params) = @_;

    my $request_class = 'Google::Bigtable::V2::Bigtable::ReadRowsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Bigtable::V2::Bigtable::ReadRowsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.bigtable.v2.Bigtable/ReadRows',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.bigtable.v2.Bigtable',
        method         => 'ReadRows',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_client_configuration {
    my ($self, %params) = @_;

    my $request_class = 'Google::Bigtable::V2::Session::GetClientConfigurationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Bigtable::V2::Session::ClientConfiguration';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.bigtable.v2.Bigtable/GetClientConfiguration',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.bigtable.v2.Bigtable',
        method         => 'GetClientConfiguration',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub open_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Bigtable::V2::Session::SessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Bigtable::V2::Session::SessionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.bigtable.v2.Bigtable/OpenTable',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.bigtable.v2.Bigtable',
        method         => 'OpenTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub open_authorized_view {
    my ($self, %params) = @_;

    my $request_class = 'Google::Bigtable::V2::Session::SessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Bigtable::V2::Session::SessionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.bigtable.v2.Bigtable/OpenAuthorizedView',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.bigtable.v2.Bigtable',
        method         => 'OpenAuthorizedView',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub open_materialized_view {
    my ($self, %params) = @_;

    my $request_class = 'Google::Bigtable::V2::Session::SessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Bigtable::V2::Session::SessionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.bigtable.v2.Bigtable/OpenMaterializedView',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.bigtable.v2.Bigtable',
        method         => 'OpenMaterializedView',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigtable::V2

__END__

=head1 NAME

Google::Cloud::Bigtable::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigtable::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigtable::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigtable::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigtable::V2> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/bigtable/v2/bigtable.proto>

=item * C<googleapis/google/bigtable/v2/data.proto>

=item * C<googleapis/google/bigtable/v2/feature_flags.proto>

=item * C<googleapis/google/bigtable/v2/peer_info.proto>

=item * C<googleapis/google/bigtable/v2/request_stats.proto>

=item * C<googleapis/google/bigtable/v2/response_params.proto>

=item * C<googleapis/google/bigtable/v2/session.proto>

=item * C<googleapis/google/bigtable/v2/types.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigtable::V2->new(
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

=item * B<read_rows>

    my $response = $client->read_rows(
        table_name               => $table_name,
        authorized_view_name     => $authorized_view_name,
        materialized_view_name   => $materialized_view_name,
        app_profile_id           => $app_profile_id,
        rows                     => $rows,
        filter                   => $filter,
        rows_limit               => $rows_limit,
        request_stats_view       => $request_stats_view,
        reversed                 => $reversed,
    );

Calls the RPC method C<ReadRows> on C<google.bigtable.v2.Bigtable>.

Request: L<Google::Bigtable::V2::Bigtable::ReadRowsRequest>

Returns: L<Google::Bigtable::V2::Bigtable::ReadRowsResponse>

Parameters:

=over 4

=item * C<table_name> - C<string>

=item * C<authorized_view_name> - C<string>

=item * C<materialized_view_name> - C<string>

=item * C<app_profile_id> - C<string>

=item * C<rows> - L<Google::Bigtable::V2::Data::RowSet>

=item * C<filter> - L<Google::Bigtable::V2::Data::RowFilter>

=item * C<rows_limit> - C<int64>

=item * C<request_stats_view> - L<Google::Bigtable::V2::Bigtable::RequestStatsView>

=item * C<reversed> - C<bool>

=back

=item * B<get_client_configuration>

    my $response = $client->get_client_configuration(
        instance_name            => $instance_name,
        app_profile_id           => $app_profile_id,
    );

Calls the RPC method C<GetClientConfiguration> on C<google.bigtable.v2.Bigtable>.

Request: L<Google::Bigtable::V2::Session::GetClientConfigurationRequest>

Returns: L<Google::Bigtable::V2::Session::ClientConfiguration>

Parameters:

=over 4

=item * C<instance_name> - C<string>

=item * C<app_profile_id> - C<string>

=back

=item * B<open_table>

    my $response = $client->open_table();

Calls the RPC method C<OpenTable> on C<google.bigtable.v2.Bigtable>.

Request: L<Google::Bigtable::V2::Session::SessionRequest>

Returns: L<Google::Bigtable::V2::Session::SessionResponse>

=item * B<open_authorized_view>

    my $response = $client->open_authorized_view();

Calls the RPC method C<OpenAuthorizedView> on C<google.bigtable.v2.Bigtable>.

Request: L<Google::Bigtable::V2::Session::SessionRequest>

Returns: L<Google::Bigtable::V2::Session::SessionResponse>

=item * B<open_materialized_view>

    my $response = $client->open_materialized_view();

Calls the RPC method C<OpenMaterializedView> on C<google.bigtable.v2.Bigtable>.

Request: L<Google::Bigtable::V2::Session::SessionRequest>

Returns: L<Google::Bigtable::V2::Session::SessionResponse>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
