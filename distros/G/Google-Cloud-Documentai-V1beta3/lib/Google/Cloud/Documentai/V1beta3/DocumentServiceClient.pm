package Google::Cloud::Documentai::V1beta3::DocumentServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Documentai::V1beta3::Barcode;
use Google::Cloud::Documentai::V1beta3::Geometry;
use Google::Cloud::Documentai::V1beta3::OperationMetadata;
use Google::Cloud::Documentai::V1beta3::Evaluation;
use Google::Cloud::Documentai::V1beta3::DocumentSchema;
use Google::Cloud::Documentai::V1beta3::ProcessorType;
use Google::Cloud::Documentai::V1beta3::Document;
use Google::Cloud::Documentai::V1beta3::Processor;
use Google::Cloud::Documentai::V1beta3::DocumentIo;
use Google::Cloud::Documentai::V1beta3::Dataset;
use Google::Cloud::Documentai::V1beta3::DocumentProcessorService;
use Google::Cloud::Documentai::V1beta3::DocumentService;

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

    my $target = 'documentai.googleapis.com:443';
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

sub update_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.documentai.v1beta3.DocumentService/UpdateDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1beta3.DocumentService',
        method         => 'UpdateDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.documentai.v1beta3.DocumentService/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1beta3.DocumentService',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_delete_documents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.documentai.v1beta3.DocumentService/BatchDeleteDocuments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1beta3.DocumentService',
        method         => 'BatchDeleteDocuments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_dataset_schema {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.documentai.v1beta3.DocumentService/UpdateDatasetSchema',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1beta3.DocumentService',
        method         => 'UpdateDatasetSchema',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Documentai::V1beta3::DocumentServiceClient

__END__

=head1 NAME

Google::Cloud::Documentai::V1beta3::DocumentServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::DocumentServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Documentai::V1beta3::DocumentServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Documentai::V1beta3::DocumentServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Documentai::V1beta3::DocumentServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/documentai/v1beta3/barcode.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/dataset.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/document.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/document_io.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/document_processor_service.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/document_schema.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/document_service.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/evaluation.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/geometry.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/operation_metadata.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/processor.proto>

=item * C<googleapis/google/cloud/documentai/v1beta3/processor_type.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Documentai::V1beta3::DocumentServiceClient->new(
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

=item * B<update_dataset>

    my $response = $client->update_dataset(
        dataset                  => $dataset,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateDataset> on C<google.cloud.documentai.v1beta3.DocumentService>.

Request: L<Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<dataset> - L<Google::Cloud::Documentai::V1beta3::Dataset::Dataset>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<get_document>

    my $response = $client->get_document(
        dataset                  => $dataset,
        document_id              => $document_id,
        read_mask                => $read_mask,
        page_range               => $page_range,
    );

Calls the RPC method C<GetDocument> on C<google.cloud.documentai.v1beta3.DocumentService>.

Request: L<Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest>

Returns: L<Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse>

Parameters:

=over 4

=item * C<dataset> - C<string>

=item * C<document_id> - L<Google::Cloud::Documentai::V1beta3::Dataset::DocumentId>

=item * C<read_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<page_range> - L<Google::Cloud::Documentai::V1beta3::DocumentService::DocumentPageRange>

=back

=item * B<batch_delete_documents>

    my $response = $client->batch_delete_documents(
        dataset                  => $dataset,
        dataset_documents        => $dataset_documents,
    );

Calls the RPC method C<BatchDeleteDocuments> on C<google.cloud.documentai.v1beta3.DocumentService>.

Request: L<Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<dataset> - C<string>

=item * C<dataset_documents> - L<Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments>

=back

=item * B<update_dataset_schema>

    my $response = $client->update_dataset_schema(
        dataset_schema           => $dataset_schema,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateDatasetSchema> on C<google.cloud.documentai.v1beta3.DocumentService>.

Request: L<Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest>

Returns: L<Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema>

Parameters:

=over 4

=item * C<dataset_schema> - L<Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
