package Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::Storage::V1beta::Partition;
use Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition;

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

    my $target = 'bigquerystorage.googleapis.com:443';
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

sub batch_create_metastore_partitions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.storage.v1beta.MetastorePartitionService/BatchCreateMetastorePartitions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'BatchCreateMetastorePartitions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_metastore_partitions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.storage.v1beta.MetastorePartitionService/StreamMetastorePartitions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.storage.v1beta.MetastorePartitionService',
        method         => 'StreamMetastorePartitions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/bigquery/storage/v1beta/metastore_partition.proto>

=item * C<googleapis/google/cloud/bigquery/storage/v1beta/partition.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::Storage::V1beta::MetastorePartitionServiceClient->new(
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

=item * B<batch_create_metastore_partitions>

    my $response = $client->batch_create_metastore_partitions(
        parent                   => $parent,
        requests                 => [ ... ],
        skip_existing_partitions => $skip_existing_partitions,
        trace_id                 => $trace_id,
    );

Calls the RPC method C<BatchCreateMetastorePartitions> on C<google.cloud.bigquery.storage.v1beta.MetastorePartitionService>.

Request: L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsRequest>

Returns: L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::BatchCreateMetastorePartitionsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<requests> - ArrayRef of L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::CreateMetastorePartitionRequest>

=item * C<skip_existing_partitions> - C<bool>

=item * C<trace_id> - C<string>

=back

=item * B<stream_metastore_partitions>

    my $response = $client->stream_metastore_partitions(
        parent                   => $parent,
        metastore_partitions     => [ ... ],
        skip_existing_partitions => $skip_existing_partitions,
    );

Calls the RPC method C<StreamMetastorePartitions> on C<google.cloud.bigquery.storage.v1beta.MetastorePartitionService>.

Request: L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsRequest>

Returns: L<Google::Cloud::Bigquery::Storage::V1beta::MetastorePartition::StreamMetastorePartitionsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<metastore_partitions> - ArrayRef of L<Google::Cloud::Bigquery::Storage::V1beta::Partition::MetastorePartition>

=item * C<skip_existing_partitions> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
