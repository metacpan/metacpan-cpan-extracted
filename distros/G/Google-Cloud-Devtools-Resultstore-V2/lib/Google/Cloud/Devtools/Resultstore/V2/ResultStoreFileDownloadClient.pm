package Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Devtools::Resultstore::V2::Coverage;
use Google::Devtools::Resultstore::V2::FileProcessingError;
use Google::Devtools::Resultstore::V2::File;
use Google::Devtools::Resultstore::V2::ResultstoreFileDownload;
use Google::Devtools::Resultstore::V2::Common;
use Google::Devtools::Resultstore::V2::UploadMetadata;
use Google::Devtools::Resultstore::V2::FileSet;
use Google::Devtools::Resultstore::V2::TestSuite;
use Google::Devtools::Resultstore::V2::CoverageSummary;
use Google::Devtools::Resultstore::V2::Configuration;
use Google::Devtools::Resultstore::V2::Target;
use Google::Devtools::Resultstore::V2::ConfiguredTarget;
use Google::Devtools::Resultstore::V2::DownloadMetadata;
use Google::Devtools::Resultstore::V2::Action;
use Google::Devtools::Resultstore::V2::Invocation;
use Google::Devtools::Resultstore::V2::ResultstoreUpload;
use Google::Devtools::Resultstore::V2::ResultstoreDownload;

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

    my $target = 'resultstore.googleapis.com:443';
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

sub get_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.resultstore.v2.ResultStoreFileDownload/GetFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.resultstore.v2.ResultStoreFileDownload',
        method         => 'GetFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_file_tail {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.resultstore.v2.ResultStoreFileDownload/GetFileTail',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.resultstore.v2.ResultStoreFileDownload',
        method         => 'GetFileTail',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient

__END__

=head1 NAME

Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/devtools/resultstore/v2/action.proto>

=item * C<googleapis/google/devtools/resultstore/v2/common.proto>

=item * C<googleapis/google/devtools/resultstore/v2/configuration.proto>

=item * C<googleapis/google/devtools/resultstore/v2/configured_target.proto>

=item * C<googleapis/google/devtools/resultstore/v2/coverage.proto>

=item * C<googleapis/google/devtools/resultstore/v2/coverage_summary.proto>

=item * C<googleapis/google/devtools/resultstore/v2/download_metadata.proto>

=item * C<googleapis/google/devtools/resultstore/v2/file.proto>

=item * C<googleapis/google/devtools/resultstore/v2/file_processing_error.proto>

=item * C<googleapis/google/devtools/resultstore/v2/file_set.proto>

=item * C<googleapis/google/devtools/resultstore/v2/invocation.proto>

=item * C<googleapis/google/devtools/resultstore/v2/resultstore_download.proto>

=item * C<googleapis/google/devtools/resultstore/v2/resultstore_file_download.proto>

=item * C<googleapis/google/devtools/resultstore/v2/resultstore_upload.proto>

=item * C<googleapis/google/devtools/resultstore/v2/target.proto>

=item * C<googleapis/google/devtools/resultstore/v2/test_suite.proto>

=item * C<googleapis/google/devtools/resultstore/v2/upload_metadata.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient->new(
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

=item * B<get_file>

    my $response = $client->get_file(
        uri                      => $uri,
        read_offset              => $read_offset,
        read_limit               => $read_limit,
        archive_entry            => $archive_entry,
    );

Calls the RPC method C<GetFile> on C<google.devtools.resultstore.v2.ResultStoreFileDownload>.

Request: L<Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest>

Returns: L<Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse>

Parameters:

=over 4

=item * C<uri> - C<string>

=item * C<read_offset> - C<int64>

=item * C<read_limit> - C<int64>

=item * C<archive_entry> - C<string>

=back

=item * B<get_file_tail>

    my $response = $client->get_file_tail(
        uri                      => $uri,
        read_offset              => $read_offset,
        read_limit               => $read_limit,
        archive_entry            => $archive_entry,
    );

Calls the RPC method C<GetFileTail> on C<google.devtools.resultstore.v2.ResultStoreFileDownload>.

Request: L<Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest>

Returns: L<Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse>

Parameters:

=over 4

=item * C<uri> - C<string>

=item * C<read_offset> - C<int64>

=item * C<read_limit> - C<int64>

=item * C<archive_entry> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
