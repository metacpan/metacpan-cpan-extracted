package Google::Cloud::Texttospeech::V1::CloudTtsLrs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Texttospeech::V1::CloudTts };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvdGV4dHRvc3BlZWNoL3YxL2Nsb3VkX3R0c19scnMucHJvdG8SHGdv
b2dsZS5jbG91ZC50ZXh0dG9zcGVlY2gudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGixnb29nbGUvY2xvdWQvdGV4dHRvc3BlZWNoL3YxL2Nsb3VkX3R0cy5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8iygIKGlN5bnRoZXNpemVMb25nQXVkaW9SZXF1ZXN0EhYKBnBhcmVu
dBgBIAEoCVIGcGFyZW50EkcKBWlucHV0GAIgASgLMiwuZ29vZ2xlLmNsb3VkLnRleHR0b3Nw
ZWVjaC52MS5TeW50aGVzaXNJbnB1dEID4EECUgVpbnB1dBJRCgxhdWRpb19jb25maWcYAyAB
KAsyKS5nb29nbGUuY2xvdWQudGV4dHRvc3BlZWNoLnYxLkF1ZGlvQ29uZmlnQgPgQQJSC2F1
ZGlvQ29uZmlnEikKDm91dHB1dF9nY3NfdXJpGAQgASgJQgPgQQJSDG91dHB1dEdjc1VyaRJN
CgV2b2ljZRgFIAEoCzIyLmdvb2dsZS5jbG91ZC50ZXh0dG9zcGVlY2gudjEuVm9pY2VTZWxl
Y3Rpb25QYXJhbXNCA+BBAlIFdm9pY2UiHQobU3ludGhlc2l6ZUxvbmdBdWRpb1Jlc3BvbnNl
ItMBChtTeW50aGVzaXplTG9uZ0F1ZGlvTWV0YWRhdGESOQoKc3RhcnRfdGltZRgBIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRJIChBsYXN0X3VwZGF0ZV90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEICGAFSDmxhc3RVcGRhdGVU
aW1lEi8KE3Byb2dyZXNzX3BlcmNlbnRhZ2UYAyABKAFSEnByb2dyZXNzUGVyY2VudGFnZTKf
AwofVGV4dFRvU3BlZWNoTG9uZ0F1ZGlvU3ludGhlc2l6ZRKqAgoTU3ludGhlc2l6ZUxvbmdB
dWRpbxI4Lmdvb2dsZS5jbG91ZC50ZXh0dG9zcGVlY2gudjEuU3ludGhlc2l6ZUxvbmdBdWRp
b1JlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrkBgtPkkwI8IjcvdjEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfTpzeW50aGVzaXplTG9uZ0F1ZGlvOgEq
ykF0Cjhnb29nbGUuY2xvdWQudGV4dHRvc3BlZWNoLnYxLlN5bnRoZXNpemVMb25nQXVkaW9S
ZXNwb25zZRI4Z29vZ2xlLmNsb3VkLnRleHR0b3NwZWVjaC52MS5TeW50aGVzaXplTG9uZ0F1
ZGlvTWV0YWRhdGEaT8pBG3RleHR0b3NwZWVjaC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C7wEKIGNvbS5nb29nbGUu
Y2xvdWQudGV4dHRvc3BlZWNoLnYxQiNUZXh0VG9TcGVlY2hMb25nQXVkaW9TeW50aGVzaXNQ
cm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dvL3RleHR0b3NwZWVjaC9hcGl2MS90ZXh0dG9z
cGVlY2hwYjt0ZXh0dG9zcGVlY2hwYqoCHEdvb2dsZS5DbG91ZC5UZXh0VG9TcGVlY2guVjHK
AhxHb29nbGVcQ2xvdWRcVGV4dFRvU3BlZWNoXFYx6gIfR29vZ2xlOjpDbG91ZDo6VGV4dFRv
U3BlZWNoOjpWMUqgFAoGEgQOAFgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAlCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMV
ADYKCQoCAwQSAxYALQoJCgIDBRIDFwApCggKAQgSAxkAOQoJCgIIJRIDGQA5CggKAQgSAxoA
WwoJCgIICxIDGgBbCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwARAoJCgIICBIDHABE
CggKAQgSAx0AOQoJCgIIARIDHQA5CggKAQgSAx4AOQoJCgIIKRIDHgA5CggKAQgSAx8AOAoJ
CgIILRIDHwA4CkYKAgYAEgQiADMBGjogU2VydmljZSB0aGF0IGltcGxlbWVudHMgR29vZ2xl
IENsb3VkIFRleHQtdG8tU3BlZWNoIEFQSS4KCgoKAwYAARIDIggnCgoKAwYAAxIDIwJDCgwK
BQYAA5kIEgMjAkMKCwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3CjoKBAYAAgASBCgCMgMa
LCBTeW50aGVzaXplcyBsb25nIGZvcm0gdGV4dCBhc3luY2hyb25vdXNseS4KCgwKBQYAAgAB
EgMoBhkKDAoFBgACAAISAygaNAoMCgUGAAIAAxIDKQ8rCg0KBQYAAgAEEgQqBC0GChEKCQYA
AgAEsMq8IhIEKgQtBgoNCgUGAAIABBIELgQxBgoPCgcGAAIABJkIEgQuBDEGCl0KAgQAEgQ3
AEkBGlEgVGhlIHRvcC1sZXZlbCBtZXNzYWdlIHNlbnQgYnkgdGhlIGNsaWVudCBmb3IgdGhl
CiBgU3ludGhlc2l6ZUxvbmdBdWRpb2AgbWV0aG9kLgoKCgoDBAABEgM3CCIKWwoEBAACABID
OgIUGk4gVGhlIHJlc291cmNlIHN0YXRlcyBvZiB0aGUgcmVxdWVzdCBpbiB0aGUgZm9ybSBv
ZgogYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDAoFBAACAAUSAzoCCAoMCgUEAAIAARID
OgkPCgwKBQQAAgADEgM6EhMKVQoEBAACARIDPQJEGkggUmVxdWlyZWQuIFRoZSBTeW50aGVz
aXplciByZXF1aXJlcyBlaXRoZXIgcGxhaW4gdGV4dCBvciBTU01MIGFzIGlucHV0LgoKDAoF
BAACAQYSAz0CEAoMCgUEAAIBARIDPREWCgwKBQQAAgEDEgM9GRoKDAoFBAACAQgSAz0bQwoP
CggEAAIBCJwIABIDPRxCCkQKBAQAAgISA0ACSBo3IFJlcXVpcmVkLiBUaGUgY29uZmlndXJh
dGlvbiBvZiB0aGUgc3ludGhlc2l6ZWQgYXVkaW8uCgoMCgUEAAICBhIDQAINCgwKBQQAAgIB
EgNADhoKDAoFBAACAgMSA0AdHgoMCgUEAAICCBIDQB9HCg8KCAQAAgIInAgAEgNAIEYKuAEK
BAQAAgMSA0UCRRqqASBSZXF1aXJlZC4gU3BlY2lmaWVzIGEgQ2xvdWQgU3RvcmFnZSBVUkkg
Zm9yIHRoZSBzeW50aGVzaXMgcmVzdWx0cy4gTXVzdCBiZQogc3BlY2lmaWVkIGluIHRoZSBm
b3JtYXQ6IGBnczovL2J1Y2tldF9uYW1lL29iamVjdF9uYW1lYCwgYW5kIHRoZSBidWNrZXQK
IG11c3QgYWxyZWFkeSBleGlzdC4KCgwKBQQAAgMFEgNFAggKDAoFBAACAwESA0UJFwoMCgUE
AAIDAxIDRRobCgwKBQQAAgMIEgNFHEQKDwoIBAACAwicCAASA0UdQwpECgQEAAIEEgNIAkoa
NyBSZXF1aXJlZC4gVGhlIGRlc2lyZWQgdm9pY2Ugb2YgdGhlIHN5bnRoZXNpemVkIGF1ZGlv
LgoKDAoFBAACBAYSA0gCFgoMCgUEAAIEARIDSBccCgwKBQQAAgQDEgNIHyAKDAoFBAACBAgS
A0ghSQoPCggEAAIECJwIABIDSCJIClQKAgQBEgNMACYaSSBUaGUgbWVzc2FnZSByZXR1cm5l
ZCB0byB0aGUgY2xpZW50IGJ5IHRoZSBgU3ludGhlc2l6ZUxvbmdBdWRpb2AgbWV0aG9kLgoK
CgoDBAEBEgNMCCMKUQoCBAISBE8AWAEaRSBNZXRhZGF0YSBmb3IgcmVzcG9uc2UgcmV0dXJu
ZWQgYnkgdGhlIGBTeW50aGVzaXplTG9uZ0F1ZGlvYCBtZXRob2QuCgoKCgMEAgESA08IIwoy
CgQEAgIAEgNRAisaJSBUaW1lIHdoZW4gdGhlIHJlcXVlc3Qgd2FzIHJlY2VpdmVkLgoKDAoF
BAICAAYSA1ECGwoMCgUEAgIAARIDURwmCgwKBQQCAgADEgNRKSoKJgoEBAICARIDVAJFGhkg
RGVwcmVjYXRlZC4gRG8gbm90IHVzZS4KCgwKBQQCAgEGEgNUAhsKDAoFBAICAQESA1QcLAoM
CgUEAgIBAxIDVC8wCgwKBQQCAgEIEgNUMUQKDQoGBAICAQgDEgNUMkMKWgoEBAICAhIDVwIh
Gk0gVGhlIHByb2dyZXNzIG9mIHRoZSBtb3N0IHJlY2VudCBwcm9jZXNzaW5nIHVwZGF0ZSBp
biBwZXJjZW50YWdlLCBpZS4gNzAuMCUuCgoMCgUEAgICBRIDVwIICgwKBQQCAgIBEgNXCRwK
DAoFBAICAgMSA1cfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioRequest ===
    # Fields for SynthesizeLongAudioRequest
    # Field: parent Type: 9 ()
    # Field: input Type: 11 (.google.cloud.texttospeech.v1.SynthesisInput)
    # Field: audio_config Type: 11 (.google.cloud.texttospeech.v1.AudioConfig)
    # Field: output_gcs_uri Type: 9 ()
    # Field: voice Type: 11 (.google.cloud.texttospeech.v1.VoiceSelectionParams)

# === Message: Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioResponse ===
    # Fields for SynthesizeLongAudioResponse

# === Message: Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioMetadata ===
    # Fields for SynthesizeLongAudioMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: progress_percentage Type: 1 ()

# === Service Client: Google::Cloud::Texttospeech::V1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient ===
package Google::Cloud::Texttospeech::V1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient;

=pod

=head2 Service Client: Google::Cloud::Texttospeech::V1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient

Client stub representing the remote C<TextToSpeechLongAudioSynthesize> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<texttospeech.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'texttospeech.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub synthesize_long_audio {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.texttospeech.v1.TextToSpeechLongAudioSynthesize',
        method         => 'SynthesizeLongAudio',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Texttospeech::V1::CloudTtsLrs - Compiled Protocol Buffers messages for google/cloud/texttospeech/v1/cloud_tts_lrs.proto

=head1 SYNOPSIS

    use Google::Cloud::Texttospeech::V1::CloudTtsLrs;

    my $msg = Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioRequest->new({
        parent => $parent,
        input => $input,
        audio_config => $audio_config,
        output_gcs_uri => $output_gcs_uri,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/texttospeech/v1/cloud_tts_lrs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioRequest

The top-level message sent by the client for the
`SynthesizeLongAudio` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The resource states of the request in the form of
`projects/*/locations/*`.

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<Message> (L<Google::Cloud::Texttospeech::V1::CloudTts::SynthesisInput>)

Required. The Synthesizer requires either plain text or SSML as input.

=item * C<< $msg->audio_config() >> / C<< $msg->audio_config($value) >>

Type: C<Message> (L<Google::Cloud::Texttospeech::V1::CloudTts::AudioConfig>)

Required. The configuration of the synthesized audio.

=item * C<< $msg->output_gcs_uri() >> / C<< $msg->output_gcs_uri($value) >>

Type: C<String>

Required. Specifies a Cloud Storage URI for the synthesis results. Must be
specified in the format: `gs://bucket_name/object_name`, and the bucket
must already exist.

=item * C<< $msg->voice() >> / C<< $msg->voice($value) >>

Type: C<Message> (L<Google::Cloud::Texttospeech::V1::CloudTts::VoiceSelectionParams>)

Required. The desired voice of the synthesized audio.

=back

=head2 Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioResponse

The message returned to the client by the `SynthesizeLongAudio` method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Texttospeech::V1::CloudTtsLrs::SynthesizeLongAudioMetadata

Metadata for response returned by the `SynthesizeLongAudio` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the request was received.

=item * C<< $msg->last_update_time() >> / C<< $msg->last_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Deprecated. Do not use.

=item * C<< $msg->progress_percentage() >> / C<< $msg->progress_percentage($value) >>

Type: C<Double>

The progress of the most recent processing update in percentage, ie. 70.0%.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Texttospeech::V1::CloudTtsLrs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
