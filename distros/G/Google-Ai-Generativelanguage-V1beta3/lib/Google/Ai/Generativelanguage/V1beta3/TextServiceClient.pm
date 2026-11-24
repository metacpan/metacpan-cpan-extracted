package Google::Ai::Generativelanguage::V1beta3::TextServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta3::Citation;
use Google::Ai::Generativelanguage::V1beta3::Safety;
use Google::Ai::Generativelanguage::V1beta3::Permission;
use Google::Ai::Generativelanguage::V1beta3::TunedModel;
use Google::Ai::Generativelanguage::V1beta3::Model;
use Google::Ai::Generativelanguage::V1beta3::DiscussService;
use Google::Ai::Generativelanguage::V1beta3::TextService;
use Google::Ai::Generativelanguage::V1beta3::PermissionService;
use Google::Ai::Generativelanguage::V1beta3::ModelService;

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

sub generate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/GenerateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'GenerateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/EmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'EmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/BatchEmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'BatchEmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_text_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.TextService/CountTextTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'CountTextTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta3::TextServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::TextServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::TextServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta3::TextServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta3::TextServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta3::TextServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta3/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1beta3::TextServiceClient->new(
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

=item * B<generate_text>

    my $response = $client->generate_text(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        max_output_tokens        => $max_output_tokens,
        top_p                    => $top_p,
        top_k                    => $top_k,
        safety_settings          => [ ... ],
        stop_sequences           => [ ... ],
    );

Calls the RPC method C<GenerateText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<max_output_tokens> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting>

=item * C<stop_sequences> - ArrayRef of C<string>

=back

=item * B<embed_text>

    my $response = $client->embed_text(
        model                    => $model,
        text                     => $text,
    );

Calls the RPC method C<EmbedText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<text> - C<string>

=back

=item * B<batch_embed_text>

    my $response = $client->batch_embed_text(
        model                    => $model,
        texts                    => [ ... ],
    );

Calls the RPC method C<BatchEmbedText> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<texts> - ArrayRef of C<string>

=back

=item * B<count_text_tokens>

    my $response = $client->count_text_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountTextTokens> on C<google.ai.generativelanguage.v1beta3.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
