package Google::Ai::Generativelanguage::V1alpha::FileServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1alpha::Model;
use Google::Ai::Generativelanguage::V1alpha::TunedModel;
use Google::Ai::Generativelanguage::V1alpha::Permission;
use Google::Ai::Generativelanguage::V1alpha::Citation;
use Google::Ai::Generativelanguage::V1alpha::Safety;
use Google::Ai::Generativelanguage::V1alpha::Retriever;
use Google::Ai::Generativelanguage::V1alpha::File;
use Google::Ai::Generativelanguage::V1alpha::PredictionService;
use Google::Ai::Generativelanguage::V1alpha::Content;
use Google::Ai::Generativelanguage::V1alpha::ModelService;
use Google::Ai::Generativelanguage::V1alpha::PermissionService;
use Google::Ai::Generativelanguage::V1alpha::TextService;
use Google::Ai::Generativelanguage::V1alpha::DiscussService;
use Google::Ai::Generativelanguage::V1alpha::RetrieverService;
use Google::Ai::Generativelanguage::V1alpha::FileService;
use Google::Ai::Generativelanguage::V1alpha::CachedContent;
use Google::Ai::Generativelanguage::V1alpha::GenerativeService;
use Google::Ai::Generativelanguage::V1alpha::CacheService;

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

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/CreateFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'CreateFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_files {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/ListFiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'ListFiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::File::File';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/GetFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'GetFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest';
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
            path           => '/google.ai.generativelanguage.v1alpha.FileService/DeleteFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'DeleteFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1alpha::FileServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::FileServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::FileServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1alpha::FileServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1alpha::FileServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1alpha::FileServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1alpha/cache_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/cached_content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/file.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/file_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/generative_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/prediction_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/retriever.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/retriever_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1alpha::FileServiceClient->new(
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

Calls the RPC method C<CreateFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse>

Parameters:

=over 4

=item * C<file> - L<Google::Ai::Generativelanguage::V1alpha::File::File>

=back

=item * B<list_files>

    my $response = $client->list_files(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListFiles> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_file>

    my $response = $client->get_file(
        name                     => $name,
    );

Calls the RPC method C<GetFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::File::File>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_file>

    my $response = $client->delete_file(
        name                     => $name,
    );

Calls the RPC method C<DeleteFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
