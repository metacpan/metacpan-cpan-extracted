package Google::Ai::Generativelanguage::V1beta::File;

use strict;
use warnings;

our $VERSION = '0.12';

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

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::File::File - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::File;

    my $msg = Google::Ai::Generativelanguage::V1beta::File::File->new(
        video_metadata => $value,
    );

=head1 FIELDS

=over 4

=item * B<video_metadata>

Type: Message (.google.ai.generativelanguage.v1beta.VideoFileMetadata)

=item * B<name>

Type: String

=item * B<display_name>

Type: String

=item * B<mime_type>

Type: String

=item * B<size_bytes>

Type: Int64

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<update_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<expiration_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<sha256_hash>

Type: Bytes

=item * B<uri>

Type: String

=item * B<download_uri>

Type: String

=item * B<state>

Type: Enum (.google.ai.generativelanguage.v1beta.File.State)

=item * B<source>

Type: Enum (.google.ai.generativelanguage.v1beta.File.Source)

=item * B<error>

Type: Message (.google.rpc.Status)

=back

=cut

# Enum: File::State
our $File_STATE_UNSPECIFIED = 0;
our $File_PROCESSING = 1;
our $File_ACTIVE = 2;
our $File_FAILED = 10;

=pod

=head2 Enum: File::State

Values:

=over 4

=item * C<STATE_UNSPECIFIED> => 0

=item * C<PROCESSING> => 1

=item * C<ACTIVE> => 2

=item * C<FAILED> => 10

=back

=cut

# Enum: File::Source
our $File_SOURCE_UNSPECIFIED = 0;
our $File_UPLOADED = 1;
our $File_GENERATED = 2;
our $File_REGISTERED = 3;

=pod

=head2 Enum: File::Source

Values:

=over 4

=item * C<SOURCE_UNSPECIFIED> => 0

=item * C<UPLOADED> => 1

=item * C<GENERATED> => 2

=item * C<REGISTERED> => 3

=back

=cut

# === Message: Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata ===
    # Fields for VideoFileMetadata
    # Field: video_duration Type: 11 (.google.protobuf.Duration)

=pod

=head1 NAME

Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta::File;

    my $msg = Google::Ai::Generativelanguage::V1beta::File::VideoFileMetadata->new(
        video_duration => $value,
    );

=head1 FIELDS

=over 4

=item * B<video_duration>

Type: Message (.google.protobuf.Duration)

=back

=cut

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::File - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
