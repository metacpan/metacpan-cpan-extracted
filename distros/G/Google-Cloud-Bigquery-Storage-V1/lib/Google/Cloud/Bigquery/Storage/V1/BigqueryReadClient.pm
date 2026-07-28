package Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::Storage::V1::Arrow;
use Google::Cloud::Bigquery::Storage::V1::Avro;
use Google::Cloud::Bigquery::Storage::V1::Protobuf;
use Google::Cloud::Bigquery::Storage::V1::Annotations;
use Google::Cloud::Bigquery::Storage::V1::Table;
use Google::Cloud::Bigquery::Storage::V1::Stream;
use Google::Cloud::Bigquery::Storage::V1::Storage;

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

sub create_read_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::Storage::V1::Storage::CreateReadSessionRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Bigquery::Storage::V1::Stream::ReadSession';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.storage.v1.BigQueryRead',
        method         => 'CreateReadSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/bigquery/storage/v1/storage.proto>

=item * C<google/cloud/bigquery/storage/v1/arrow.proto>

=item * C<google/cloud/bigquery/storage/v1/protobuf.proto>

=item * C<google/cloud/bigquery/storage/v1/avro.proto>

=item * C<google/cloud/bigquery/storage/v1/annotations.proto>

=item * C<google/cloud/bigquery/storage/v1/table.proto>

=item * C<google/cloud/bigquery/storage/v1/stream.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient->new(
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

=item * B<create_read_session>

Calls the RPC method C<CreateReadSession> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
