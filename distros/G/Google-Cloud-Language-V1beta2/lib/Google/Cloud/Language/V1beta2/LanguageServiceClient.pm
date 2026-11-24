package Google::Cloud::Language::V1beta2::LanguageServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Language::V1beta2::LanguageService;

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

    my $target = 'language.googleapis.com:443';
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

sub analyze_sentiment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSentimentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSentimentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/AnalyzeSentiment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'AnalyzeSentiment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_entities {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitiesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitiesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/AnalyzeEntities',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'AnalyzeEntities',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_entity_sentiment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitySentimentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitySentimentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/AnalyzeEntitySentiment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'AnalyzeEntitySentiment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_syntax {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSyntaxRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSyntaxResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/AnalyzeSyntax',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'AnalyzeSyntax',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub classify_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::ClassifyTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::ClassifyTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/ClassifyText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'ClassifyText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub moderate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::ModerateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::ModerateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/ModerateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'ModerateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub annotate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnnotateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Language::V1beta2::LanguageService::AnnotateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.language.v1beta2.LanguageService/AnnotateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.language.v1beta2.LanguageService',
        method         => 'AnnotateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Language::V1beta2::LanguageServiceClient

__END__

=head1 NAME

Google::Cloud::Language::V1beta2::LanguageServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Language::V1beta2::LanguageServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Language::V1beta2::LanguageServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Language::V1beta2::LanguageServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Language::V1beta2::LanguageServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/language/v1beta2/language_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Language::V1beta2::LanguageServiceClient->new(
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

=item * B<analyze_sentiment>

    my $response = $client->analyze_sentiment(
        document                 => $document,
        encoding_type            => $encoding_type,
    );

Calls the RPC method C<AnalyzeSentiment> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSentimentRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSentimentResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<encoding_type> - L<Google::Cloud::Language::V1beta2::LanguageService::EncodingType>

=back

=item * B<analyze_entities>

    my $response = $client->analyze_entities(
        document                 => $document,
        encoding_type            => $encoding_type,
    );

Calls the RPC method C<AnalyzeEntities> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitiesRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitiesResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<encoding_type> - L<Google::Cloud::Language::V1beta2::LanguageService::EncodingType>

=back

=item * B<analyze_entity_sentiment>

    my $response = $client->analyze_entity_sentiment(
        document                 => $document,
        encoding_type            => $encoding_type,
    );

Calls the RPC method C<AnalyzeEntitySentiment> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitySentimentRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeEntitySentimentResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<encoding_type> - L<Google::Cloud::Language::V1beta2::LanguageService::EncodingType>

=back

=item * B<analyze_syntax>

    my $response = $client->analyze_syntax(
        document                 => $document,
        encoding_type            => $encoding_type,
    );

Calls the RPC method C<AnalyzeSyntax> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSyntaxRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::AnalyzeSyntaxResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<encoding_type> - L<Google::Cloud::Language::V1beta2::LanguageService::EncodingType>

=back

=item * B<classify_text>

    my $response = $client->classify_text(
        document                 => $document,
        classification_model_options => $classification_model_options,
    );

Calls the RPC method C<ClassifyText> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::ClassifyTextRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::ClassifyTextResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<classification_model_options> - L<Google::Cloud::Language::V1beta2::LanguageService::ClassificationModelOptions>

=back

=item * B<moderate_text>

    my $response = $client->moderate_text(
        document                 => $document,
    );

Calls the RPC method C<ModerateText> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::ModerateTextRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::ModerateTextResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=back

=item * B<annotate_text>

    my $response = $client->annotate_text(
        document                 => $document,
        features                 => $features,
        encoding_type            => $encoding_type,
    );

Calls the RPC method C<AnnotateText> on C<google.cloud.language.v1beta2.LanguageService>.

Request: L<Google::Cloud::Language::V1beta2::LanguageService::AnnotateTextRequest>

Returns: L<Google::Cloud::Language::V1beta2::LanguageService::AnnotateTextResponse>

Parameters:

=over 4

=item * C<document> - L<Google::Cloud::Language::V1beta2::LanguageService::Document>

=item * C<features> - L<Google::Cloud::Language::V1beta2::LanguageService::Features>

=item * C<encoding_type> - L<Google::Cloud::Language::V1beta2::LanguageService::EncodingType>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
