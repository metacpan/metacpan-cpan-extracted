package Google::Ai::Generativelanguage::V1beta::FileServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta::Safety;
use Google::Ai::Generativelanguage::V1beta::Citation;
use Google::Ai::Generativelanguage::V1beta::Permission;
use Google::Ai::Generativelanguage::V1beta::Model;
use Google::Ai::Generativelanguage::V1beta::Content;
use Google::Ai::Generativelanguage::V1beta::TunedModel;
use Google::Ai::Generativelanguage::V1beta::Retriever;
use Google::Ai::Generativelanguage::V1beta::PredictionService;
use Google::Ai::Generativelanguage::V1beta::File;
use Google::Ai::Generativelanguage::V1beta::DiscussService;
use Google::Ai::Generativelanguage::V1beta::TextService;
use Google::Ai::Generativelanguage::V1beta::PermissionService;
use Google::Ai::Generativelanguage::V1beta::CachedContent;
use Google::Ai::Generativelanguage::V1beta::ModelService;
use Google::Ai::Generativelanguage::V1beta::RetrieverService;
use Google::Ai::Generativelanguage::V1beta::GenerativeService;
use Google::Ai::Generativelanguage::V1beta::FileService;
use Google::Ai::Generativelanguage::V1beta::CacheService;

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

    my $target = 'generativelanguage.googleapis.com:443';
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

sub create_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/CreateFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'CreateFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_files {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/ListFiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'ListFiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::File::File';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/GetFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'GetFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.FileService/DeleteFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DeleteFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub download_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/DownloadFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DownloadFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta::FileServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::FileServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::FileServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta::FileServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta::FileServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta::FileServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta/cache_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/cached_content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/file.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/file_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/generative_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/prediction_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/retriever.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/retriever_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1beta::FileServiceClient->new(
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

=item * B<create_file>

    my $response = $client->create_file(
        file                     => $file,
    );

Calls the RPC method C<CreateFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse>

Parameters:

=over 4

=item * C<file> - L<Google::Ai::Generativelanguage::V1beta::File::File>

=back

=item * B<list_files>

    my $response = $client->list_files(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListFiles> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_file>

    my $response = $client->get_file(
        name                     => $name,
    );

Calls the RPC method C<GetFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::File::File>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_file>

    my $response = $client->delete_file(
        name                     => $name,
    );

Calls the RPC method C<DeleteFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<download_file>

    my $response = $client->download_file(
        name                     => $name,
    );

Calls the RPC method C<DownloadFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
