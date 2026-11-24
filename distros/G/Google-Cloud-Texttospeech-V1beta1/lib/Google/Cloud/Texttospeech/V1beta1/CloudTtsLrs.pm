package Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs;

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
    eval { require Google::Cloud::Texttospeech::V1beta1::CloudTts };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvdGV4dHRvc3BlZWNoL3YxYmV0YTEvY2xvdWRfdHRzX2xycy5wcm90
bxIhZ29vZ2xlLmNsb3VkLnRleHR0b3NwZWVjaC52MWJldGExGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoxZ29vZ2xlL2Nsb3VkL3RleHR0b3NwZWVjaC92MWJldGExL2Ns
b3VkX3R0cy5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i2QIKGlN5bnRoZXNpemVMb25nQXVkaW9S
ZXF1ZXN0EhYKBnBhcmVudBgBIAEoCVIGcGFyZW50EkwKBWlucHV0GAIgASgLMjEuZ29vZ2xl
LmNsb3VkLnRleHR0b3NwZWVjaC52MWJldGExLlN5bnRoZXNpc0lucHV0QgPgQQJSBWlucHV0
ElYKDGF1ZGlvX2NvbmZpZxgDIAEoCzIuLmdvb2dsZS5jbG91ZC50ZXh0dG9zcGVlY2gudjFi
ZXRhMS5BdWRpb0NvbmZpZ0ID4EECUgthdWRpb0NvbmZpZxIpCg5vdXRwdXRfZ2NzX3VyaRgE
IAEoCUID4EECUgxvdXRwdXRHY3NVcmkSUgoFdm9pY2UYBSABKAsyNy5nb29nbGUuY2xvdWQu
dGV4dHRvc3BlZWNoLnYxYmV0YTEuVm9pY2VTZWxlY3Rpb25QYXJhbXNCA+BBAlIFdm9pY2Ui
HQobU3ludGhlc2l6ZUxvbmdBdWRpb1Jlc3BvbnNlItMBChtTeW50aGVzaXplTG9uZ0F1ZGlv
TWV0YWRhdGESOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCXN0YXJ0VGltZRJIChBsYXN0X3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEICGAFSDmxhc3RVcGRhdGVUaW1lEi8KE3Byb2dyZXNzX3BlcmNlbnRh
Z2UYAyABKAFSEnByb2dyZXNzUGVyY2VudGFnZTKzAwofVGV4dFRvU3BlZWNoTG9uZ0F1ZGlv
U3ludGhlc2l6ZRK+AgoTU3ludGhlc2l6ZUxvbmdBdWRpbxI9Lmdvb2dsZS5jbG91ZC50ZXh0
dG9zcGVlY2gudjFiZXRhMS5TeW50aGVzaXplTG9uZ0F1ZGlvUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24iyAGC0+STAkEiPC92MWJldGExL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKn06c3ludGhlc2l6ZUxvbmdBdWRpbzoBKspBfgo9Z29vZ2xlLmNs
b3VkLnRleHR0b3NwZWVjaC52MWJldGExLlN5bnRoZXNpemVMb25nQXVkaW9SZXNwb25zZRI9
Z29vZ2xlLmNsb3VkLnRleHR0b3NwZWVjaC52MWJldGExLlN5bnRoZXNpemVMb25nQXVkaW9N
ZXRhZGF0YRpPykEbdGV4dHRvc3BlZWNoLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKIAgolY29tLmdvb2dsZS5jbG91
ZC50ZXh0dG9zcGVlY2gudjFiZXRhMUIjVGV4dFRvU3BlZWNoTG9uZ0F1ZGlvU3ludGhlc2lz
UHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNvbS9nby90ZXh0dG9zcGVlY2gvYXBpdjFiZXRhMS90
ZXh0dG9zcGVlY2hwYjt0ZXh0dG9zcGVlY2hwYqoCIUdvb2dsZS5DbG91ZC5UZXh0VG9TcGVl
Y2guVjFCZXRhMcoCIUdvb2dsZVxDbG91ZFxUZXh0VG9TcGVlY2hcVjFiZXRhMeoCJEdvb2ds
ZTo6Q2xvdWQ6OlRleHRUb1NwZWVjaDo6VjFiZXRhMUqgFAoGEgQOAFgBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVADsKCQoCAwQSAxYALQoJCgIDBRIDFwApCggKAQgSAxkA
PgoJCgIIJRIDGQA+CggKAQgSAxoAYAoJCgIICxIDGgBgCggKAQgSAxsAIgoJCgIIChIDGwAi
CggKAQgSAxwARAoJCgIICBIDHABECggKAQgSAx0APgoJCgIIARIDHQA+CggKAQgSAx4APgoJ
CgIIKRIDHgA+CggKAQgSAx8APQoJCgIILRIDHwA9CkYKAgYAEgQiADMBGjogU2VydmljZSB0
aGF0IGltcGxlbWVudHMgR29vZ2xlIENsb3VkIFRleHQtdG8tU3BlZWNoIEFQSS4KCgoKAwYA
ARIDIggnCgoKAwYAAxIDIwJDCgwKBQYAA5kIEgMjAkMKCwoDBgADEgQkAiU3Cg0KBQYAA5oI
EgQkAiU3CjoKBAYAAgASBCgCMgMaLCBTeW50aGVzaXplcyBsb25nIGZvcm0gdGV4dCBhc3lu
Y2hyb25vdXNseS4KCgwKBQYAAgABEgMoBhkKDAoFBgACAAISAygaNAoMCgUGAAIAAxIDKQ8r
Cg0KBQYAAgAEEgQqBC0GChEKCQYAAgAEsMq8IhIEKgQtBgoNCgUGAAIABBIELgQxBgoPCgcG
AAIABJkIEgQuBDEGCl0KAgQAEgQ3AEkBGlEgVGhlIHRvcC1sZXZlbCBtZXNzYWdlIHNlbnQg
YnkgdGhlIGNsaWVudCBmb3IgdGhlCiBgU3ludGhlc2l6ZUxvbmdBdWRpb2AgbWV0aG9kLgoK
CgoDBAABEgM3CCIKWwoEBAACABIDOgIUGk4gVGhlIHJlc291cmNlIHN0YXRlcyBvZiB0aGUg
cmVxdWVzdCBpbiB0aGUgZm9ybSBvZgogYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDAoF
BAACAAUSAzoCCAoMCgUEAAIAARIDOgkPCgwKBQQAAgADEgM6EhMKVQoEBAACARIDPQJEGkgg
UmVxdWlyZWQuIFRoZSBTeW50aGVzaXplciByZXF1aXJlcyBlaXRoZXIgcGxhaW4gdGV4dCBv
ciBTU01MIGFzIGlucHV0LgoKDAoFBAACAQYSAz0CEAoMCgUEAAIBARIDPREWCgwKBQQAAgED
EgM9GRoKDAoFBAACAQgSAz0bQwoPCggEAAIBCJwIABIDPRxCCkQKBAQAAgISA0ACSBo3IFJl
cXVpcmVkLiBUaGUgY29uZmlndXJhdGlvbiBvZiB0aGUgc3ludGhlc2l6ZWQgYXVkaW8uCgoM
CgUEAAICBhIDQAINCgwKBQQAAgIBEgNADhoKDAoFBAACAgMSA0AdHgoMCgUEAAICCBIDQB9H
Cg8KCAQAAgIInAgAEgNAIEYKuAEKBAQAAgMSA0UCRRqqASBSZXF1aXJlZC4gU3BlY2lmaWVz
IGEgQ2xvdWQgU3RvcmFnZSBVUkkgZm9yIHRoZSBzeW50aGVzaXMgcmVzdWx0cy4gTXVzdCBi
ZQogc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQ6IGBnczovL2J1Y2tldF9uYW1lL29iamVjdF9u
YW1lYCwgYW5kIHRoZSBidWNrZXQKIG11c3QgYWxyZWFkeSBleGlzdC4KCgwKBQQAAgMFEgNF
AggKDAoFBAACAwESA0UJFwoMCgUEAAIDAxIDRRobCgwKBQQAAgMIEgNFHEQKDwoIBAACAwic
CAASA0UdQwpECgQEAAIEEgNIAkoaNyBSZXF1aXJlZC4gVGhlIGRlc2lyZWQgdm9pY2Ugb2Yg
dGhlIHN5bnRoZXNpemVkIGF1ZGlvLgoKDAoFBAACBAYSA0gCFgoMCgUEAAIEARIDSBccCgwK
BQQAAgQDEgNIHyAKDAoFBAACBAgSA0ghSQoPCggEAAIECJwIABIDSCJIClQKAgQBEgNMACYa
SSBUaGUgbWVzc2FnZSByZXR1cm5lZCB0byB0aGUgY2xpZW50IGJ5IHRoZSBgU3ludGhlc2l6
ZUxvbmdBdWRpb2AgbWV0aG9kLgoKCgoDBAEBEgNMCCMKUQoCBAISBE8AWAEaRSBNZXRhZGF0
YSBmb3IgcmVzcG9uc2UgcmV0dXJuZWQgYnkgdGhlIGBTeW50aGVzaXplTG9uZ0F1ZGlvYCBt
ZXRob2QuCgoKCgMEAgESA08IIwoyCgQEAgIAEgNRAisaJSBUaW1lIHdoZW4gdGhlIHJlcXVl
c3Qgd2FzIHJlY2VpdmVkLgoKDAoFBAICAAYSA1ECGwoMCgUEAgIAARIDURwmCgwKBQQCAgAD
EgNRKSoKJgoEBAICARIDVAJFGhkgRGVwcmVjYXRlZC4gRG8gbm90IHVzZS4KCgwKBQQCAgEG
EgNUAhsKDAoFBAICAQESA1QcLAoMCgUEAgIBAxIDVC8wCgwKBQQCAgEIEgNUMUQKDQoGBAIC
AQgDEgNUMkMKWgoEBAICAhIDVwIhGk0gVGhlIHByb2dyZXNzIG9mIHRoZSBtb3N0IHJlY2Vu
dCBwcm9jZXNzaW5nIHVwZGF0ZSBpbiBwZXJjZW50YWdlLCBpZS4gNzAuMCUuCgoMCgUEAgIC
BRIDVwIICgwKBQQCAgIBEgNXCRwKDAoFBAICAgMSA1cfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest ===
    # Fields for SynthesizeLongAudioRequest
    # Field: parent Type: 9 ()
    # Field: input Type: 11 (.google.cloud.texttospeech.v1beta1.SynthesisInput)
    # Field: audio_config Type: 11 (.google.cloud.texttospeech.v1beta1.AudioConfig)
    # Field: output_gcs_uri Type: 9 ()
    # Field: voice Type: 11 (.google.cloud.texttospeech.v1beta1.VoiceSelectionParams)

# === Message: Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioResponse ===
    # Fields for SynthesizeLongAudioResponse

# === Message: Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioMetadata ===
    # Fields for SynthesizeLongAudioMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: progress_percentage Type: 1 ()

# === Service Client: Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient ===
package Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient;

=pod

=head2 Service Client: Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::TextToSpeechLongAudioSynthesizeClient

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
        ? Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.texttospeech.v1beta1.TextToSpeechLongAudioSynthesize',
        method         => 'SynthesizeLongAudio',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs - Compiled Protocol Buffers messages for google/cloud/texttospeech/v1beta1/cloud_tts_lrs.proto

=head1 SYNOPSIS

    use Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs;

    my $msg = Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest->new({
        parent => $parent,
        input => $input,
        audio_config => $audio_config,
        output_gcs_uri => $output_gcs_uri,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/texttospeech/v1beta1/cloud_tts_lrs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest

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

Type: C<Message> (L<Google::Cloud::Texttospeech::V1beta1::CloudTts::SynthesisInput>)

Required. The Synthesizer requires either plain text or SSML as input.

=item * C<< $msg->audio_config() >> / C<< $msg->audio_config($value) >>

Type: C<Message> (L<Google::Cloud::Texttospeech::V1beta1::CloudTts::AudioConfig>)

Required. The configuration of the synthesized audio.

=item * C<< $msg->output_gcs_uri() >> / C<< $msg->output_gcs_uri($value) >>

Type: C<String>

Required. Specifies a Cloud Storage URI for the synthesis results. Must be
specified in the format: `gs://bucket_name/object_name`, and the bucket
must already exist.

=item * C<< $msg->voice() >> / C<< $msg->voice($value) >>

Type: C<Message> (L<Google::Cloud::Texttospeech::V1beta1::CloudTts::VoiceSelectionParams>)

Required. The desired voice of the synthesized audio.

=back

=head2 Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioResponse

The message returned to the client by the `SynthesizeLongAudio` method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
