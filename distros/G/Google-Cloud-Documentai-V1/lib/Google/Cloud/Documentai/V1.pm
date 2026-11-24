package Google::Cloud::Documentai::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Documentai::V1::Barcode;
use Google::Cloud::Documentai::V1::DocumentSchema;
use Google::Cloud::Documentai::V1::Geometry;
use Google::Cloud::Documentai::V1::OperationMetadata;
use Google::Cloud::Documentai::V1::DocumentIo;
use Google::Cloud::Documentai::V1::Document;
use Google::Cloud::Documentai::V1::Evaluation;
use Google::Cloud::Documentai::V1::ProcessorType;
use Google::Cloud::Documentai::V1::Processor;
use Google::Cloud::Documentai::V1::DocumentProcessorService;

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

sub process_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.documentai.v1.DocumentProcessorService/ProcessDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1.DocumentProcessorService',
        method         => 'ProcessDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub evaluate_processor_version {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionRequest';
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
            path           => '/google.cloud.documentai.v1.DocumentProcessorService/EvaluateProcessorVersion',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.documentai.v1.DocumentProcessorService',
        method         => 'EvaluateProcessorVersion',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Documentai::V1

__END__

=head1 NAME

Google::Cloud::Documentai::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Documentai::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Documentai::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Documentai::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/documentai/v1/barcode.proto>

=item * C<googleapis/google/cloud/documentai/v1/document.proto>

=item * C<googleapis/google/cloud/documentai/v1/document_io.proto>

=item * C<googleapis/google/cloud/documentai/v1/document_processor_service.proto>

=item * C<googleapis/google/cloud/documentai/v1/document_schema.proto>

=item * C<googleapis/google/cloud/documentai/v1/evaluation.proto>

=item * C<googleapis/google/cloud/documentai/v1/geometry.proto>

=item * C<googleapis/google/cloud/documentai/v1/operation_metadata.proto>

=item * C<googleapis/google/cloud/documentai/v1/processor.proto>

=item * C<googleapis/google/cloud/documentai/v1/processor_type.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Documentai::V1->new(
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

=item * B<process_document>

    my $response = $client->process_document(
        name                     => $name,
        skip_human_review        => $skip_human_review,
        field_mask               => $field_mask,
        process_options          => $process_options,
        labels                   => { ... },
        imageless_mode           => $imageless_mode,
    );

Calls the RPC method C<ProcessDocument> on C<google.cloud.documentai.v1.DocumentProcessorService>.

Request: L<Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest>

Returns: L<Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<skip_human_review> - C<bool>

=item * C<field_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<process_options> - L<Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions>

=item * C<labels> - C<map<string, string>> (HashRef)

=item * C<imageless_mode> - C<bool>

=back

=item * B<evaluate_processor_version>

    my $response = $client->evaluate_processor_version(
        processor_version        => $processor_version,
        evaluation_documents     => $evaluation_documents,
    );

Calls the RPC method C<EvaluateProcessorVersion> on C<google.cloud.documentai.v1.DocumentProcessorService>.

Request: L<Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<processor_version> - C<string>

=item * C<evaluation_documents> - L<Google::Cloud::Documentai::V1::DocumentIo::BatchDocumentsInputConfig>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
