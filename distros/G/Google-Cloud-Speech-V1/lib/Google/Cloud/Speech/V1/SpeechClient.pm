package Google::Cloud::Speech::V1::SpeechClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Speech::V1::Resource;
use Google::Cloud::Speech::V1::CloudSpeech;
use Google::Cloud::Speech::V1::CloudSpeechAdaptation;

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

    my $target = 'speech.googleapis.com:443';
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

sub recognize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Speech::V1::CloudSpeech::RecognizeResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.speech.v1.Speech/Recognize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.speech.v1.Speech',
        method         => 'Recognize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub long_running_recognize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeRequest';
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
            path           => '/google.cloud.speech.v1.Speech/LongRunningRecognize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.speech.v1.Speech',
        method         => 'LongRunningRecognize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub streaming_recognize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.speech.v1.Speech/StreamingRecognize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.speech.v1.Speech',
        method         => 'StreamingRecognize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Speech::V1::SpeechClient

__END__

=head1 NAME

Google::Cloud::Speech::V1::SpeechClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Speech::V1::SpeechClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Speech::V1::SpeechClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Speech::V1::SpeechClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Speech::V1::SpeechClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/speech/v1/cloud_speech.proto>

=item * C<googleapis/google/cloud/speech/v1/cloud_speech_adaptation.proto>

=item * C<googleapis/google/cloud/speech/v1/resource.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Speech::V1::SpeechClient->new(
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

=item * B<recognize>

    my $response = $client->recognize(
        config                   => $config,
        audio                    => $audio,
    );

Calls the RPC method C<Recognize> on C<google.cloud.speech.v1.Speech>.

Request: L<Google::Cloud::Speech::V1::CloudSpeech::RecognizeRequest>

Returns: L<Google::Cloud::Speech::V1::CloudSpeech::RecognizeResponse>

Parameters:

=over 4

=item * C<config> - L<Google::Cloud::Speech::V1::CloudSpeech::RecognitionConfig>

=item * C<audio> - L<Google::Cloud::Speech::V1::CloudSpeech::RecognitionAudio>

=back

=item * B<long_running_recognize>

    my $response = $client->long_running_recognize(
        config                   => $config,
        audio                    => $audio,
        output_config            => $output_config,
    );

Calls the RPC method C<LongRunningRecognize> on C<google.cloud.speech.v1.Speech>.

Request: L<Google::Cloud::Speech::V1::CloudSpeech::LongRunningRecognizeRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<config> - L<Google::Cloud::Speech::V1::CloudSpeech::RecognitionConfig>

=item * C<audio> - L<Google::Cloud::Speech::V1::CloudSpeech::RecognitionAudio>

=item * C<output_config> - L<Google::Cloud::Speech::V1::CloudSpeech::TranscriptOutputConfig>

=back

=item * B<streaming_recognize>

    my $response = $client->streaming_recognize();

Calls the RPC method C<StreamingRecognize> on C<google.cloud.speech.v1.Speech>.

Request: L<Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeRequest>

Returns: L<Google::Cloud::Speech::V1::CloudSpeech::StreamingRecognizeResponse>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
