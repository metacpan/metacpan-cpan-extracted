package Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1alpha::Permission;
use Google::Ai::Generativelanguage::V1alpha::Retriever;
use Google::Ai::Generativelanguage::V1alpha::Safety;
use Google::Ai::Generativelanguage::V1alpha::Citation;
use Google::Ai::Generativelanguage::V1alpha::Model;
use Google::Ai::Generativelanguage::V1alpha::TunedModel;
use Google::Ai::Generativelanguage::V1alpha::Content;
use Google::Ai::Generativelanguage::V1alpha::PredictionService;
use Google::Ai::Generativelanguage::V1alpha::File;
use Google::Ai::Generativelanguage::V1alpha::PermissionService;
use Google::Ai::Generativelanguage::V1alpha::RetrieverService;
use Google::Ai::Generativelanguage::V1alpha::DiscussService;
use Google::Ai::Generativelanguage::V1alpha::TextService;
use Google::Ai::Generativelanguage::V1alpha::ModelService;
use Google::Ai::Generativelanguage::V1alpha::GenerativeService;
use Google::Ai::Generativelanguage::V1alpha::CachedContent;
use Google::Ai::Generativelanguage::V1alpha::FileService;
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

sub generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/GenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'GenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_answer {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/GenerateAnswer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'GenerateAnswer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/StreamGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'StreamGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/EmbedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'EmbedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/BatchEmbedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'BatchEmbedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/CountTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'CountTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bidi_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentClientMessage';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentServerMessage';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/BidiGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'BidiGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient->new(
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
        system_instruction       => $system_instruction,
        contents                 => [ ... ],
        tools                    => [ ... ],
        tool_config              => $tool_config,
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
        cached_content           => $cached_content,
    );

Calls the RPC method C<GenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerationConfig>

=item * C<cached_content> - C<string>

=back

=item * B<generate_answer>

    my $response = $client->generate_answer(
        model                    => $model,
        contents                 => [ ... ],
        answer_style             => $answer_style,
        safety_settings          => [ ... ],
        temperature              => $temperature,
    );

Calls the RPC method C<GenerateAnswer> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<answer_style> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::AnswerStyle>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<temperature> - C<float>

=back

=item * B<stream_generate_content>

    my $response = $client->stream_generate_content(
        model                    => $model,
        system_instruction       => $system_instruction,
        contents                 => [ ... ],
        tools                    => [ ... ],
        tool_config              => $tool_config,
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
        cached_content           => $cached_content,
    );

Calls the RPC method C<StreamGenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerationConfig>

=item * C<cached_content> - C<string>

=back

=item * B<embed_content>

    my $response = $client->embed_content(
        model                    => $model,
        content                  => $content,
        task_type                => $task_type,
        title                    => $title,
        output_dimensionality    => $output_dimensionality,
    );

Calls the RPC method C<EmbedContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<content> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<task_type> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::TaskType>

=item * C<title> - C<string>

=item * C<output_dimensionality> - C<int32>

=back

=item * B<batch_embed_contents>

    my $response = $client->batch_embed_contents(
        model                    => $model,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchEmbedContents> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest>

=back

=item * B<count_tokens>

    my $response = $client->count_tokens(
        model                    => $model,
        contents                 => [ ... ],
        generate_content_request => $generate_content_request,
    );

Calls the RPC method C<CountTokens> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<generate_content_request> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

=back

=item * B<bidi_generate_content>

    my $response = $client->bidi_generate_content();

Calls the RPC method C<BidiGenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentClientMessage>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentServerMessage>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
