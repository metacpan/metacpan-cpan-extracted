package Google::Cloud::Firestore::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Firestore::V1::BloomFilter;
use Google::Firestore::V1::ExplainStats;
use Google::Firestore::V1::QueryProfile;
use Google::Firestore::V1::Document;
use Google::Firestore::V1::Common;
use Google::Firestore::V1::AggregationResult;
use Google::Firestore::V1::Pipeline;
use Google::Firestore::V1::Query;
use Google::Firestore::V1::Write;
use Google::Firestore::V1::Firestore;

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

    my $target = 'firestore.googleapis.com:443';
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

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Document::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::UpdateDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Document::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/UpdateDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'UpdateDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_get_documents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::BatchGetDocumentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Firestore::BatchGetDocumentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/BatchGetDocuments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'BatchGetDocuments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub execute_pipeline {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::ExecutePipelineRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Firestore::ExecutePipelineResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/ExecutePipeline',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'ExecutePipeline',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub partition_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::PartitionQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Firestore::PartitionQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/PartitionQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'PartitionQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_write {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::V1::Firestore::BatchWriteRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Firestore::V1::Firestore::BatchWriteResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.v1.Firestore/BatchWrite',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.v1.Firestore',
        method         => 'BatchWrite',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Firestore::V1

__END__

=head1 NAME

Google::Cloud::Firestore::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Firestore::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Firestore::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Firestore::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Firestore::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/firestore/v1/aggregation_result.proto>

=item * C<googleapis/google/firestore/v1/bloom_filter.proto>

=item * C<googleapis/google/firestore/v1/common.proto>

=item * C<googleapis/google/firestore/v1/document.proto>

=item * C<googleapis/google/firestore/v1/explain_stats.proto>

=item * C<googleapis/google/firestore/v1/firestore.proto>

=item * C<googleapis/google/firestore/v1/pipeline.proto>

=item * C<googleapis/google/firestore/v1/query.proto>

=item * C<googleapis/google/firestore/v1/query_profile.proto>

=item * C<googleapis/google/firestore/v1/write.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Firestore::V1->new(
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

=item * B<get_document>

    my $response = $client->get_document(
        name                     => $name,
        mask                     => $mask,
        request_options          => $request_options,
    );

Calls the RPC method C<GetDocument> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::GetDocumentRequest>

Returns: L<Google::Firestore::V1::Document::Document>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<mask> - L<Google::Firestore::V1::Common::DocumentMask>

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=item * B<update_document>

    my $response = $client->update_document(
        document                 => $document,
        update_mask              => $update_mask,
        mask                     => $mask,
        current_document         => $current_document,
        request_options          => $request_options,
    );

Calls the RPC method C<UpdateDocument> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::UpdateDocumentRequest>

Returns: L<Google::Firestore::V1::Document::Document>

Parameters:

=over 4

=item * C<document> - L<Google::Firestore::V1::Document::Document>

=item * C<update_mask> - L<Google::Firestore::V1::Common::DocumentMask>

=item * C<mask> - L<Google::Firestore::V1::Common::DocumentMask>

=item * C<current_document> - L<Google::Firestore::V1::Common::Precondition>

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=item * B<batch_get_documents>

    my $response = $client->batch_get_documents(
        database                 => $database,
        documents                => [ ... ],
        mask                     => $mask,
        request_options          => $request_options,
    );

Calls the RPC method C<BatchGetDocuments> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::BatchGetDocumentsRequest>

Returns: L<Google::Firestore::V1::Firestore::BatchGetDocumentsResponse>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<documents> - ArrayRef of C<string>

=item * C<mask> - L<Google::Firestore::V1::Common::DocumentMask>

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=item * B<execute_pipeline>

    my $response = $client->execute_pipeline(
        database                 => $database,
        auto_commit_transaction  => $auto_commit_transaction,
        request_options          => $request_options,
    );

Calls the RPC method C<ExecutePipeline> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::ExecutePipelineRequest>

Returns: L<Google::Firestore::V1::Firestore::ExecutePipelineResponse>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<auto_commit_transaction> - C<bool>

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=item * B<partition_query>

    my $response = $client->partition_query(
        parent                   => $parent,
        partition_count          => $partition_count,
        page_token               => $page_token,
        page_size                => $page_size,
        request_options          => $request_options,
    );

Calls the RPC method C<PartitionQuery> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::PartitionQueryRequest>

Returns: L<Google::Firestore::V1::Firestore::PartitionQueryResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<partition_count> - C<int64>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=item * B<batch_write>

    my $response = $client->batch_write(
        database                 => $database,
        writes                   => [ ... ],
        labels                   => { ... },
        request_options          => $request_options,
    );

Calls the RPC method C<BatchWrite> on C<google.firestore.v1.Firestore>.

Request: L<Google::Firestore::V1::Firestore::BatchWriteRequest>

Returns: L<Google::Firestore::V1::Firestore::BatchWriteResponse>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<writes> - ArrayRef of L<Google::Firestore::V1::Write::Write>

=item * C<labels> - C<map<string, string>> (HashRef)

=item * C<request_options> - L<Google::Firestore::V1::Common::RequestOptions>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
