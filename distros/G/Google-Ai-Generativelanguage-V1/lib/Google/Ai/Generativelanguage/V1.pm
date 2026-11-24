package Google::Ai::Generativelanguage::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1::Model;
use Google::Ai::Generativelanguage::V1::Safety;
use Google::Ai::Generativelanguage::V1::Citation;
use Google::Ai::Generativelanguage::V1::Content;
use Google::Ai::Generativelanguage::V1::ModelService;
use Google::Ai::Generativelanguage::V1::GenerativeService;

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

sub generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.GenerativeService/GenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'GenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.GenerativeService/StreamGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'StreamGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.GenerativeService/EmbedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'EmbedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.GenerativeService/BatchEmbedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'BatchEmbedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.GenerativeService/CountTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'CountTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.ModelService/GetModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.ModelService',
        method         => 'GetModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1.ModelService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.ModelService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1/content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1/generative_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1/safety.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1->new(
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

=item * B<generate_content>

    my $response = $client->generate_content(
        model                    => $model,
        contents                 => [ ... ],
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
    );

Calls the RPC method C<GenerateContent> on C<google.ai.generativelanguage.v1.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1::Content::Content>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerationConfig>

=back

=item * B<stream_generate_content>

    my $response = $client->stream_generate_content(
        model                    => $model,
        contents                 => [ ... ],
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
    );

Calls the RPC method C<StreamGenerateContent> on C<google.ai.generativelanguage.v1.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1::Content::Content>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerationConfig>

=back

=item * B<embed_content>

    my $response = $client->embed_content(
        model                    => $model,
        content                  => $content,
        task_type                => $task_type,
        title                    => $title,
        output_dimensionality    => $output_dimensionality,
    );

Calls the RPC method C<EmbedContent> on C<google.ai.generativelanguage.v1.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<content> - L<Google::Ai::Generativelanguage::V1::Content::Content>

=item * C<task_type> - L<Google::Ai::Generativelanguage::V1::GenerativeService::TaskType>

=item * C<title> - C<string>

=item * C<output_dimensionality> - C<int32>

=back

=item * B<batch_embed_contents>

    my $response = $client->batch_embed_contents(
        model                    => $model,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchEmbedContents> on C<google.ai.generativelanguage.v1.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest>

=back

=item * B<count_tokens>

    my $response = $client->count_tokens(
        model                    => $model,
        contents                 => [ ... ],
        generate_content_request => $generate_content_request,
    );

Calls the RPC method C<CountTokens> on C<google.ai.generativelanguage.v1.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1::Content::Content>

=item * C<generate_content_request> - L<Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest>

=back

=item * B<get_model>

    my $response = $client->get_model(
        name                     => $name,
    );

Calls the RPC method C<GetModel> on C<google.ai.generativelanguage.v1.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1::ModelService::GetModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1::Model::Model>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.ai.generativelanguage.v1.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1::ModelService::ListModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1::ModelService::ListModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
