package Google::Ai::Generativelanguage::V1beta::File;

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
Ci5nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YS9maWxlLnByb3RvEiNnb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVm
L2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29n
bGUvcnBjL3N0YXR1cy5wcm90byLZBwoERmlsZRJkCg52aWRlb19tZXRhZGF0YRgMIAEoCzI2
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhLlZpZGVvRmlsZU1ldGFkYXRh
QgPgQQNIAFINdmlkZW9NZXRhZGF0YRIaCgRuYW1lGAEgASgJQgbgQQjgQQVSBG5hbWUSJgoM
ZGlzcGxheV9uYW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiAKCW1pbWVfdHlwZRgDIAEo
CUID4EEDUghtaW1lVHlwZRIiCgpzaXplX2J5dGVzGAQgASgDQgPgQQNSCXNpemVCeXRlcxJA
CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
Y3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKdXBkYXRlVGltZRJICg9leHBpcmF0aW9uX3RpbWUYByABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDmV4cGlyYXRpb25UaW1lEiQKC3NoYTI1Nl9o
YXNoGAggASgMQgPgQQNSCnNoYTI1Nkhhc2gSFQoDdXJpGAkgASgJQgPgQQNSA3VyaRImCgxk
b3dubG9hZF91cmkYDiABKAlCA+BBA1ILZG93bmxvYWRVcmkSSgoFc3RhdGUYCiABKA4yLy5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YS5GaWxlLlN0YXRlQgPgQQNSBXN0
YXRlEkgKBnNvdXJjZRgNIAEoDjIwLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFi
ZXRhLkZpbGUuU291cmNlUgZzb3VyY2USLQoFZXJyb3IYCyABKAsyEi5nb29nbGUucnBjLlN0
YXR1c0ID4EEDUgVlcnJvciJGCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg4KClBS
T0NFU1NJTkcQARIKCgZBQ1RJVkUQAhIKCgZGQUlMRUQQCiJNCgZTb3VyY2USFgoSU09VUkNF
X1VOU1BFQ0lGSUVEEAASDAoIVVBMT0FERUQQARINCglHRU5FUkFURUQQAhIOCgpSRUdJU1RF
UkVEEAM6RupBQwomZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL0ZpbGUSDGZp
bGVzL3tmaWxlfSoFZmlsZXMyBGZpbGVCCgoIbWV0YWRhdGEiVQoRVmlkZW9GaWxlTWV0YWRh
dGESQAoOdmlkZW9fZHVyYXRpb24YASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25S
DXZpZGVvRHVyYXRpb25ClQEKJ2NvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YmV0YUIJRmlsZVByb3RvUAFaXWNsb3VkLmdvb2dsZS5jb20vZ28vYWkvZ2VuZXJhdGl2ZWxh
bmd1YWdlL2FwaXYxYmV0YS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3Vh
Z2VwYkr2IAoHEgUOAIQBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKAoJCgIDAxIDFQApCgkK
AgMEEgMWACEKCAoBCBIDGAB0CgkKAggLEgMYAHQKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgAqCgkKAggIEgMaACoKCAoBCBIDGwBACgkKAggBEgMbAEAKNgoCBAASBB8AfgEaKiBB
IGZpbGUgdXBsb2FkZWQgdG8gdGhlIEFQSS4KIE5leHQgSUQ6IDE1CgoKCgMEAAESAx8IDAoL
CgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKMwoEBAAEABIEKAI0AxolIFN0YXRlcyBmb3Ig
dGhlIGxpZmVjeWNsZSBvZiBhIEZpbGUuCgoMCgUEAAQAARIDKAcMCk8KBgQABAACABIDKgQa
GkAgVGhlIGRlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdXNlZCBpZiB0aGUgc3RhdGUg
aXMgb21pdHRlZC4KCg4KBwQABAACAAESAyoEFQoOCgcEAAQAAgACEgMqGBkKTgoGBAAEAAIB
EgMtBBMaPyBGaWxlIGlzIGJlaW5nIHByb2Nlc3NlZCBhbmQgY2Fubm90IGJlIHVzZWQgZm9y
IGluZmVyZW5jZSB5ZXQuCgoOCgcEAAQAAgEBEgMtBA4KDgoHBAAEAAIBAhIDLRESCj8KBgQA
BAACAhIDMAQPGjAgRmlsZSBpcyBwcm9jZXNzZWQgYW5kIGF2YWlsYWJsZSBmb3IgaW5mZXJl
bmNlLgoKDgoHBAAEAAICARIDMAQKCg4KBwQABAACAgISAzANDgooCgYEAAQAAgMSAzMEEBoZ
IEZpbGUgZmFpbGVkIHByb2Nlc3NpbmcuCgoOCgcEAAQAAgMBEgMzBAoKDgoHBAAEAAIDAhID
Mw0PCgwKBAQABAESBDYCQgMKDAoFBAAEAQESAzYHDQoxCgYEAAQBAgASAzgEGxoiIFVzZWQg
aWYgc291cmNlIGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAAQBAgABEgM4BBYKDgoHBAAEAQIA
AhIDOBkaCjwKBgQABAECARIDOwQRGi0gSW5kaWNhdGVzIHRoZSBmaWxlIGlzIHVwbG9hZGVk
IGJ5IHRoZSB1c2VyLgoKDgoHBAAEAQIBARIDOwQMCg4KBwQABAECAQISAzsPEAo7CgYEAAQB
AgISAz4EEhosIEluZGljYXRlcyB0aGUgZmlsZSBpcyBnZW5lcmF0ZWQgYnkgR29vZ2xlLgoK
DgoHBAAEAQICARIDPgQNCg4KBwQABAECAgISAz4QEQpWCgYEAAQBAgMSA0EEExpHIEluZGlj
YXRlcyB0aGUgZmlsZSBpcyBhIHJlZ2lzdGVyZWQsIGkuZS4gYSBHb29nbGUgQ2xvdWQgU3Rv
cmFnZSBmaWxlLgoKDgoHBAAEAQIDARIDQQQOCg4KBwQABAECAwISA0EREgomCgQEAAgAEgRF
AkkDGhggTWV0YWRhdGEgZm9yIHRoZSBGaWxlLgoKDAoFBAAIAAESA0UIEAoyCgQEAAIAEgRH
BEg0GiQgT3V0cHV0IG9ubHkuIE1ldGFkYXRhIGZvciBhIHZpZGVvLgoKDAoFBAACAAYSA0cE
FQoMCgUEAAIAARIDRxYkCgwKBQQAAgADEgNHJykKDAoFBAACAAgSA0gIMwoPCggEAAIACJwI
ABIDSAkyCsICCgQEAAIBEgRQAlMEGrMCIEltbXV0YWJsZS4gSWRlbnRpZmllci4gVGhlIGBG
aWxlYCByZXNvdXJjZSBuYW1lLiBUaGUgSUQgKG5hbWUgZXhjbHVkaW5nIHRoZQogImZpbGVz
LyIgcHJlZml4KSBjYW4gY29udGFpbiB1cCB0byA0MCBjaGFyYWN0ZXJzIHRoYXQgYXJlIGxv
d2VyY2FzZQogYWxwaGFudW1lcmljIG9yIGRhc2hlcyAoLSkuIFRoZSBJRCBjYW5ub3Qgc3Rh
cnQgb3IgZW5kIHdpdGggYSBkYXNoLiBJZiB0aGUKIG5hbWUgaXMgZW1wdHkgb24gY3JlYXRl
LCBhIHVuaXF1ZSBuYW1lIHdpbGwgYmUgZ2VuZXJhdGVkLiBFeGFtcGxlOgogYGZpbGVzLzEy
My00NTZgCgoMCgUEAAIBBRIDUAIICgwKBQQAAgEBEgNQCQ0KDAoFBAACAQMSA1AQEQoNCgUE
AAIBCBIEUBJTAwoPCggEAAIBCJwIABIDUQQsCg8KCAQAAgEInAgBEgNSBCsKtgEKBAQAAgIS
A1gCQxqoASBPcHRpb25hbC4gVGhlIGh1bWFuLXJlYWRhYmxlIGRpc3BsYXkgbmFtZSBmb3Ig
dGhlIGBGaWxlYC4gVGhlIGRpc3BsYXkgbmFtZQogbXVzdCBiZSBubyBtb3JlIHRoYW4gNTEy
IGNoYXJhY3RlcnMgaW4gbGVuZ3RoLCBpbmNsdWRpbmcgc3BhY2VzLiBFeGFtcGxlOgogIldl
bGNvbWUgSW1hZ2UiCgoMCgUEAAICBRIDWAIICgwKBQQAAgIBEgNYCRUKDAoFBAACAgMSA1gY
GQoMCgUEAAICCBIDWBpCCg8KCAQAAgIInAgAEgNYG0EKMgoEBAACAxIDWwJDGiUgT3V0cHV0
IG9ubHkuIE1JTUUgdHlwZSBvZiB0aGUgZmlsZS4KCgwKBQQAAgMFEgNbAggKDAoFBAACAwES
A1sJEgoMCgUEAAIDAxIDWxUWCgwKBQQAAgMIEgNbF0IKDwoIBAACAwicCAASA1sYQQo2CgQE
AAIEEgNeAkMaKSBPdXRwdXQgb25seS4gU2l6ZSBvZiB0aGUgZmlsZSBpbiBieXRlcy4KCgwK
BQQAAgQFEgNeAgcKDAoFBAACBAESA14IEgoMCgUEAAIEAxIDXhUWCgwKBQQAAgQIEgNeF0IK
DwoIBAACBAicCAASA14YQQpKCgQEAAIFEgRhAmIyGjwgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
c3RhbXAgb2Ygd2hlbiB0aGUgYEZpbGVgIHdhcyBjcmVhdGVkLgoKDAoFBAACBQYSA2ECGwoM
CgUEAAIFARIDYRwnCgwKBQQAAgUDEgNhKisKDAoFBAACBQgSA2IGMQoPCggEAAIFCJwIABID
YgcwCk8KBAQAAgYSBGUCZjIaQSBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCBvZiB3aGVu
IHRoZSBgRmlsZWAgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgYGEgNlAhsKDAoFBAACBgES
A2UcJwoMCgUEAAIGAxIDZSorCgwKBQQAAgYIEgNmBjEKDwoIBAACBgicCAASA2YHMAp+CgQE
AAIHEgRqAmsyGnAgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgb2Ygd2hlbiB0aGUgYEZp
bGVgIHdpbGwgYmUgZGVsZXRlZC4gT25seSBzZXQgaWYKIHRoZSBgRmlsZWAgaXMgc2NoZWR1
bGVkIHRvIGV4cGlyZS4KCgwKBQQAAgcGEgNqAhsKDAoFBAACBwESA2ocKwoMCgUEAAIHAxID
ai4vCgwKBQQAAgcIEgNrBjEKDwoIBAACBwicCAASA2sHMAo/CgQEAAIIEgNuAkQaMiBPdXRw
dXQgb25seS4gU0hBLTI1NiBoYXNoIG9mIHRoZSB1cGxvYWRlZCBieXRlcy4KCgwKBQQAAggF
EgNuAgcKDAoFBAACCAESA24IEwoMCgUEAAIIAxIDbhYXCgwKBQQAAggIEgNuGEMKDwoIBAAC
CAicCAASA24ZQgoyCgQEAAIJEgNxAj0aJSBPdXRwdXQgb25seS4gVGhlIHVyaSBvZiB0aGUg
YEZpbGVgLgoKDAoFBAACCQUSA3ECCAoMCgUEAAIJARIDcQkMCgwKBQQAAgkDEgNxDxAKDAoF
BAACCQgSA3ERPAoPCggEAAIJCJwIABIDcRI7CjsKBAQAAgoSA3QCRxouIE91dHB1dCBvbmx5
LiBUaGUgZG93bmxvYWQgdXJpIG9mIHRoZSBgRmlsZWAuCgoMCgUEAAIKBRIDdAIICgwKBQQA
AgoBEgN0CRUKDAoFBAACCgMSA3QYGgoMCgUEAAIKCBIDdBtGCg8KCAQAAgoInAgAEgN0HEUK
OQoEBAACCxIDdwI/GiwgT3V0cHV0IG9ubHkuIFByb2Nlc3Npbmcgc3RhdGUgb2YgdGhlIEZp
bGUuCgoMCgUEAAILBhIDdwIHCgwKBQQAAgsBEgN3CA0KDAoFBAACCwMSA3cQEgoMCgUEAAIL
CBIDdxM+Cg8KCAQAAgsInAgAEgN3FD0KIgoEBAACDBIDegIVGhUgU291cmNlIG9mIHRoZSBG
aWxlLgoKDAoFBAACDAYSA3oCCAoMCgUEAAIMARIDegkPCgwKBQQAAgwDEgN6EhQKQwoEBAAC
DRIDfQJLGjYgT3V0cHV0IG9ubHkuIEVycm9yIHN0YXR1cyBpZiBGaWxlIHByb2Nlc3Npbmcg
ZmFpbGVkLgoKDAoFBAACDQYSA30CEwoMCgUEAAINARIDfRQZCgwKBQQAAg0DEgN9HB4KDAoF
BAACDQgSA30fSgoPCggEAAINCJwIABIDfSBJCiwKAgQBEgaBAQCEAQEaHiBNZXRhZGF0YSBm
b3IgYSB2aWRlbyBgRmlsZWAuCgoLCgMEAQESBIEBCBkKJgoEBAECABIEgwECLhoYIER1cmF0
aW9uIG9mIHRoZSB2aWRlby4KCg0KBQQBAgAGEgSDAQIaCg0KBQQBAgABEgSDARspCg0KBQQB
AgADEgSDASwtYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta::File::File ===
    # Fields for File
    # Field: video_metadata Type: 11 (.google.ai.generativelanguage.v1beta.VideoFileMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: mime_type Type: 9 ()
    # Field: size_bytes Type: 3 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expiration_time Type: 11 (.google.protobuf.Timestamp)
    # Field: sha256_hash Type: 12 ()
    # Field: uri Type: 9 ()
    # Field: download_uri Type: 9 ()
    # Field: state Type: 14 (.google.ai.generativelanguage.v1beta.File.State)
    # Field: source Type: 14 (.google.ai.generativelanguage.v1beta.File.Source)
    # Field: error Type: 11 (.google.rpc.Status)

# Enum: File::State
our $File_STATE_UNSPECIFIED = 0;
our $File_PROCESSING = 1;
our $File_ACTIVE = 2;
our $File_FAILED = 10;

# Enum: File::Source
our $File_SOURCE_UNSPECIFIED = 0;
our $File_UPLOADED = 1;
our $File_GENERATED = 2;
our $File_REGISTERED = 3;

# === Message: Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata ===
    # Fields for VideoFileMetadata
    # Field: video_duration Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta::File - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta/file.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::File;

    my $msg = Google::Ai::Generativelanguage::V1beta::File::File->new({
        video_metadata => $video_metadata,
        name => $name,
        display_name => $display_name,
        mime_type => $mime_type,
    });

    # Read or update a field
    my $val = $msg->video_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta::File::File->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta::File::File

A file uploaded to the API.
Next ID: 15

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->video_metadata() >> / C<< $msg->video_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata>)

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

=item * C<< $msg->download_uri() >> / C<< $msg->download_uri($value) >>

Type: C<String>

Output only. The download uri of the `File`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::File::State>)

Output only. Processing state of the File.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta::File::Source>)

Source of the File.

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

=head3 Enum: File::Source

=over 4

=item * C<SOURCE_UNSPECIFIED> => C<0>

=item * C<UPLOADED> => C<1>

=item * C<GENERATED> => C<2>

=item * C<REGISTERED> => C<3>

=back

=head2 Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata

Metadata for a video `File`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->video_duration() >> / C<< $msg->video_duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Duration of the video.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
