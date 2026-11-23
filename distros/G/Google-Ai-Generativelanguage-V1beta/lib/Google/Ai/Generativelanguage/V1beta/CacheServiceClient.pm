package Google::Ai::Generativelanguage::V1beta::CacheServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta::Citation;
use Google::Ai::Generativelanguage::V1beta::File;
use Google::Ai::Generativelanguage::V1beta::Permission;
use Google::Ai::Generativelanguage::V1beta::Retriever;
use Google::Ai::Generativelanguage::V1beta::Safety;
use Google::Ai::Generativelanguage::V1beta::Content;
use Google::Ai::Generativelanguage::V1beta::Model;
use Google::Ai::Generativelanguage::V1beta::TunedModel;
use Google::Ai::Generativelanguage::V1beta::PredictionService;
use Google::Ai::Generativelanguage::V1beta::FileService;
use Google::Ai::Generativelanguage::V1beta::PermissionService;
use Google::Ai::Generativelanguage::V1beta::RetrieverService;
use Google::Ai::Generativelanguage::V1beta::DiscussService;
use Google::Ai::Generativelanguage::V1beta::TextService;
use Google::Ai::Generativelanguage::V1beta::CachedContent;
use Google::Ai::Generativelanguage::V1beta::GenerativeService;
use Google::Ai::Generativelanguage::V1beta::ModelService;
use Google::Ai::Generativelanguage::V1beta::CacheService;

our $VERSION = '0.02';

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

sub list_cached_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/ListCachedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'ListCachedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/CreateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'CreateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/GetCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'GetCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/UpdateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'UpdateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.CacheService/DeleteCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'DeleteCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta::CacheServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::CacheServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::CacheServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta::CacheServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta::CacheServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta::CacheServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta/cached_content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/cache_service.proto>

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

    my $client = Google::Ai::Generativelanguage::V1beta::CacheServiceClient->new(
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

=item * B<list_cached_contents>

Calls the RPC method C<ListCachedContents> on the service. Takes a hash of parameters representing the request.

=item * B<create_cached_content>

Calls the RPC method C<CreateCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<get_cached_content>

Calls the RPC method C<GetCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<update_cached_content>

Calls the RPC method C<UpdateCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<delete_cached_content>

Calls the RPC method C<DeleteCachedContent> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
