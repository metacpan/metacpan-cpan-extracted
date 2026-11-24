package Google::Ai::Generativelanguage::V1alpha::File;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvZmlsZS5wcm90bxIkZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9i
dWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aF2dv
b2dsZS9ycGMvc3RhdHVzLnByb3RvIpYGCgRGaWxlEmEKDnZpZGVvX21ldGFkYXRhGAwgASgL
MjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLlZpZGVvTWV0YWRhdGFC
A+BBA0gAUg12aWRlb01ldGFkYXRhEhoKBG5hbWUYASABKAlCBuBBCOBBBVIEbmFtZRImCgxk
aXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUSIAoJbWltZV90eXBlGAMgASgJ
QgPgQQNSCG1pbWVUeXBlEiIKCnNpemVfYnl0ZXMYBCABKANCA+BBA1IJc2l6ZUJ5dGVzEkAK
C2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgp1cGRhdGVUaW1lEkgKD2V4cGlyYXRpb25fdGltZRgHIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IOZXhwaXJhdGlvblRpbWUSJAoLc2hhMjU2X2hh
c2gYCCABKAxCA+BBA1IKc2hhMjU2SGFzaBIVCgN1cmkYCSABKAlCA+BBA1IDdXJpEksKBXN0
YXRlGAogASgOMjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkZpbGUu
U3RhdGVCA+BBA1IFc3RhdGUSLQoFZXJyb3IYCyABKAsyEi5nb29nbGUucnBjLlN0YXR1c0ID
4EEDUgVlcnJvciJGCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg4KClBST0NFU1NJ
TkcQARIKCgZBQ1RJVkUQAhIKCgZGQUlMRUQQCjpG6kFDCiZnZW5lcmF0aXZlbGFuZ3VhZ2Uu
Z29vZ2xlYXBpcy5jb20vRmlsZRIMZmlsZXMve2ZpbGV9KgVmaWxlczIEZmlsZUIKCghtZXRh
ZGF0YSJRCg1WaWRlb01ldGFkYXRhEkAKDnZpZGVvX2R1cmF0aW9uGAEgASgLMhkuZ29vZ2xl
LnByb3RvYnVmLkR1cmF0aW9uUg12aWRlb0R1cmF0aW9uQpcBCihjb20uZ29vZ2xlLmFpLmdl
bmVyYXRpdmVsYW5ndWFnZS52MWFscGhhQglGaWxlUHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNv
bS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2UvYXBpdjFhbHBoYS9nZW5lcmF0aXZlbGFuZ3Vh
Z2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkr4GwoGEgQOAHABCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgID
AhIDFAAoCgkKAgMDEgMVACkKCQoCAwQSAxYAIQoICgEIEgMYAHUKCQoCCAsSAxgAdQoICgEI
EgMZACIKCQoCCAoSAxkAIgoICgEIEgMaACoKCQoCCAgSAxoAKgoICgEIEgMbAEEKCQoCCAES
AxsAQQo2CgIEABIEHwBqARoqIEEgZmlsZSB1cGxvYWRlZCB0byB0aGUgQVBJLgogTmV4dCBJ
RDogMTUKCgoKAwQAARIDHwgMCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBAozCgQEAAQA
EgQoAjQDGiUgU3RhdGVzIGZvciB0aGUgbGlmZWN5Y2xlIG9mIGEgRmlsZS4KCgwKBQQABAAB
EgMoBwwKTwoGBAAEAAIAEgMqBBoaQCBUaGUgZGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBp
cyB1c2VkIGlmIHRoZSBzdGF0ZSBpcyBvbWl0dGVkLgoKDgoHBAAEAAIAARIDKgQVCg4KBwQA
BAACAAISAyoYGQpOCgYEAAQAAgESAy0EExo/IEZpbGUgaXMgYmVpbmcgcHJvY2Vzc2VkIGFu
ZCBjYW5ub3QgYmUgdXNlZCBmb3IgaW5mZXJlbmNlIHlldC4KCg4KBwQABAACAQESAy0EDgoO
CgcEAAQAAgECEgMtERIKPwoGBAAEAAICEgMwBA8aMCBGaWxlIGlzIHByb2Nlc3NlZCBhbmQg
YXZhaWxhYmxlIGZvciBpbmZlcmVuY2UuCgoOCgcEAAQAAgIBEgMwBAoKDgoHBAAEAAICAhID
MA0OCigKBgQABAACAxIDMwQQGhkgRmlsZSBmYWlsZWQgcHJvY2Vzc2luZy4KCg4KBwQABAAC
AwESAzMECgoOCgcEAAQAAgMCEgMzDQ8KJgoEBAAIABIENwI7AxoYIE1ldGFkYXRhIGZvciB0
aGUgRmlsZS4KCgwKBQQACAABEgM3CBAKMgoEBAACABIEOQQ6NBokIE91dHB1dCBvbmx5LiBN
ZXRhZGF0YSBmb3IgYSB2aWRlby4KCgwKBQQAAgAGEgM5BBEKDAoFBAACAAESAzkSIAoMCgUE
AAIAAxIDOSMlCgwKBQQAAgAIEgM6CDMKDwoIBAACAAicCAASAzoJMgrCAgoEBAACARIEQgJF
BBqzAiBJbW11dGFibGUuIElkZW50aWZpZXIuIFRoZSBgRmlsZWAgcmVzb3VyY2UgbmFtZS4g
VGhlIElEIChuYW1lIGV4Y2x1ZGluZyB0aGUKICJmaWxlcy8iIHByZWZpeCkgY2FuIGNvbnRh
aW4gdXAgdG8gNDAgY2hhcmFjdGVycyB0aGF0IGFyZSBsb3dlcmNhc2UKIGFscGhhbnVtZXJp
YyBvciBkYXNoZXMgKC0pLiBUaGUgSUQgY2Fubm90IHN0YXJ0IG9yIGVuZCB3aXRoIGEgZGFz
aC4gSWYgdGhlCiBuYW1lIGlzIGVtcHR5IG9uIGNyZWF0ZSwgYSB1bmlxdWUgbmFtZSB3aWxs
IGJlIGdlbmVyYXRlZC4gRXhhbXBsZToKIGBmaWxlcy8xMjMtNDU2YAoKDAoFBAACAQUSA0IC
CAoMCgUEAAIBARIDQgkNCgwKBQQAAgEDEgNCEBEKDQoFBAACAQgSBEISRQMKDwoIBAACAQic
CAASA0MELAoPCggEAAIBCJwIARIDRAQrCrYBCgQEAAICEgNKAkMaqAEgT3B0aW9uYWwuIFRo
ZSBodW1hbi1yZWFkYWJsZSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBgRmlsZWAuIFRoZSBkaXNw
bGF5IG5hbWUKIG11c3QgYmUgbm8gbW9yZSB0aGFuIDUxMiBjaGFyYWN0ZXJzIGluIGxlbmd0
aCwgaW5jbHVkaW5nIHNwYWNlcy4gRXhhbXBsZToKICJXZWxjb21lIEltYWdlIgoKDAoFBAAC
AgUSA0oCCAoMCgUEAAICARIDSgkVCgwKBQQAAgIDEgNKGBkKDAoFBAACAggSA0oaQgoPCggE
AAICCJwIABIDShtBCjIKBAQAAgMSA00CQxolIE91dHB1dCBvbmx5LiBNSU1FIHR5cGUgb2Yg
dGhlIGZpbGUuCgoMCgUEAAIDBRIDTQIICgwKBQQAAgMBEgNNCRIKDAoFBAACAwMSA00VFgoM
CgUEAAIDCBIDTRdCCg8KCAQAAgMInAgAEgNNGEEKNgoEBAACBBIDUAJDGikgT3V0cHV0IG9u
bHkuIFNpemUgb2YgdGhlIGZpbGUgaW4gYnl0ZXMuCgoMCgUEAAIEBRIDUAIHCgwKBQQAAgQB
EgNQCBIKDAoFBAACBAMSA1AVFgoMCgUEAAIECBIDUBdCCg8KCAQAAgQInAgAEgNQGEEKSgoE
BAACBRIEUwJUMho8IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIG9mIHdoZW4gdGhlIGBG
aWxlYCB3YXMgY3JlYXRlZC4KCgwKBQQAAgUGEgNTAhsKDAoFBAACBQESA1McJwoMCgUEAAIF
AxIDUyorCgwKBQQAAgUIEgNUBjEKDwoIBAACBQicCAASA1QHMApPCgQEAAIGEgRXAlgyGkEg
T3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2Ygd2hlbiB0aGUgYEZpbGVgIHdhcyBsYXN0
IHVwZGF0ZWQuCgoMCgUEAAIGBhIDVwIbCgwKBQQAAgYBEgNXHCcKDAoFBAACBgMSA1cqKwoM
CgUEAAIGCBIDWAYxCg8KCAQAAgYInAgAEgNYBzAKfgoEBAACBxIEXAJdMhpwIE91dHB1dCBv
bmx5LiBUaGUgdGltZXN0YW1wIG9mIHdoZW4gdGhlIGBGaWxlYCB3aWxsIGJlIGRlbGV0ZWQu
IE9ubHkgc2V0IGlmCiB0aGUgYEZpbGVgIGlzIHNjaGVkdWxlZCB0byBleHBpcmUuCgoMCgUE
AAIHBhIDXAIbCgwKBQQAAgcBEgNcHCsKDAoFBAACBwMSA1wuLwoMCgUEAAIHCBIDXQYxCg8K
CAQAAgcInAgAEgNdBzAKPwoEBAACCBIDYAJEGjIgT3V0cHV0IG9ubHkuIFNIQS0yNTYgaGFz
aCBvZiB0aGUgdXBsb2FkZWQgYnl0ZXMuCgoMCgUEAAIIBRIDYAIHCgwKBQQAAggBEgNgCBMK
DAoFBAACCAMSA2AWFwoMCgUEAAIICBIDYBhDCg8KCAQAAggInAgAEgNgGUIKMgoEBAACCRID
YwI9GiUgT3V0cHV0IG9ubHkuIFRoZSB1cmkgb2YgdGhlIGBGaWxlYC4KCgwKBQQAAgkFEgNj
AggKDAoFBAACCQESA2MJDAoMCgUEAAIJAxIDYw8QCgwKBQQAAgkIEgNjETwKDwoIBAACCQic
CAASA2MSOwo5CgQEAAIKEgNmAj8aLCBPdXRwdXQgb25seS4gUHJvY2Vzc2luZyBzdGF0ZSBv
ZiB0aGUgRmlsZS4KCgwKBQQAAgoGEgNmAgcKDAoFBAACCgESA2YIDQoMCgUEAAIKAxIDZhAS
CgwKBQQAAgoIEgNmEz4KDwoIBAACCgicCAASA2YUPQpDCgQEAAILEgNpAksaNiBPdXRwdXQg
b25seS4gRXJyb3Igc3RhdHVzIGlmIEZpbGUgcHJvY2Vzc2luZyBmYWlsZWQuCgoMCgUEAAIL
BhIDaQITCgwKBQQAAgsBEgNpFBkKDAoFBAACCwMSA2kcHgoMCgUEAAILCBIDaR9KCg8KCAQA
AgsInAgAEgNpIEkKKgoCBAESBG0AcAEaHiBNZXRhZGF0YSBmb3IgYSB2aWRlbyBgRmlsZWAu
CgoKCgMEAQESA20IFQolCgQEAQIAEgNvAi4aGCBEdXJhdGlvbiBvZiB0aGUgdmlkZW8uCgoM
CgUEAQIABhIDbwIaCgwKBQQBAgABEgNvGykKDAoFBAECAAMSA28sLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::File::File ===
    # Fields for File
    # Field: video_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.VideoMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: size_bytes Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expiration_time Type: 11 (.google.protobuf.Timestamp)
    # Field: sha256_hash Type: 12 ()
    # Field: uri Type: 9 ()
    # Field: state Type: 14 (.google.ai.generativelanguage.v1alpha.File.State)
    # Field: error Type: 11 (.google.rpc.Status)

# Enum: File::State
our $File_STATE_UNSPECIFIED = 0;
our $File_PROCESSING = 1;
our $File_ACTIVE = 2;
our $File_FAILED = 10;

# === Message: Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata ===
    # Fields for VideoMetadata
    # Field: video_duration Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::File - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/file.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::File;

    my $msg = Google::Ai::Generativelanguage::V1alpha::File::File->new({
        video_metadata => $video_metadata,
        name => $name,
        display_name => $display_name,
        mime_type => $mime_type,
    });

    # Read or update a field
    my $val = $msg->video_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::File::File->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::File::File

A file uploaded to the API.
Next ID: 15

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->video_metadata() >> / C<< $msg->video_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata>)

Output only. Metadata for a video.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. The `File` resource name. The ID (name excluding the
"files/" prefix) can contain up to 40 characters that are lowercase
alphanumeric or dashes (-). The ID cannot start or end with a dash. If the
name is empty on create, a unique name will be generated. Example:
`files/123-456`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The human-readable display name for the `File`. The display name
must be no more than 512 characters in length, including spaces. Example:
"Welcome Image"

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

Output only. MIME type of the file.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. Size of the file in bytes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of when the `File` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of when the `File` was last updated.

=item * C<< $msg->expiration_time() >> / C<< $msg->expiration_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of when the `File` will be deleted. Only set if
the `File` is scheduled to expire.

=item * C<< $msg->sha256_hash() >> / C<< $msg->sha256_hash($value) >>

Type: C<Bytes>

Output only. SHA-256 hash of the uploaded bytes.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Output only. The uri of the `File`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::File::State>)

Output only. Processing state of the File.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Error status if File processing failed.

=back

=head3 Enum: File::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROCESSING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<10>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::File::VideoMetadata

Metadata for a video `File`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->video_duration() >> / C<< $msg->video_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of the video.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
