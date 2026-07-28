package Google::Cloud::Bigquery::Storage::V1::Arrow;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MS9hcnJvdy5wcm90bxIgZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjEiOgoLQXJyb3dTY2hlbWESKwoRc2VyaWFsaXpl
ZF9zY2hlbWEYASABKAxSEHNlcmlhbGl6ZWRTY2hlbWEiawoQQXJyb3dSZWNvcmRCYXRjaBI2
ChdzZXJpYWxpemVkX3JlY29yZF9iYXRjaBgBIAEoDFIVc2VyaWFsaXplZFJlY29yZEJhdGNo
Eh8KCXJvd19jb3VudBgCIAEoA0ICGAFSCHJvd0NvdW50IpkEChlBcnJvd1NlcmlhbGl6YXRp
b25PcHRpb25zEnsKEmJ1ZmZlcl9jb21wcmVzc2lvbhgCIAEoDjJMLmdvb2dsZS5jbG91ZC5i
aWdxdWVyeS5zdG9yYWdlLnYxLkFycm93U2VyaWFsaXphdGlvbk9wdGlvbnMuQ29tcHJlc3Np
b25Db2RlY1IRYnVmZmVyQ29tcHJlc3Npb24SjwEKGXBpY29zX3RpbWVzdGFtcF9wcmVjaXNp
b24YAyABKA4yUy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MS5BcnJvd1Nlcmlh
bGl6YXRpb25PcHRpb25zLlBpY29zVGltZXN0YW1wUHJlY2lzaW9uUhdwaWNvc1RpbWVzdGFt
cFByZWNpc2lvbiJIChBDb21wcmVzc2lvbkNvZGVjEhsKF0NPTVBSRVNTSU9OX1VOU1BFQ0lG
SUVEEAASDQoJTFo0X0ZSQU1FEAESCAoEWlNURBACIqIBChdQaWNvc1RpbWVzdGFtcFByZWNp
c2lvbhIpCiVQSUNPU19USU1FU1RBTVBfUFJFQ0lTSU9OX1VOU1BFQ0lGSUVEEAASHgoaVElN
RVNUQU1QX1BSRUNJU0lPTl9NSUNST1MQARIdChlUSU1FU1RBTVBfUFJFQ0lTSU9OX05BTk9T
EAISHQoZVElNRVNUQU1QX1BSRUNJU0lPTl9QSUNPUxADQroBCiRjb20uZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnN0b3JhZ2UudjFCCkFycm93UHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9n
by9iaWdxdWVyeS9zdG9yYWdlL2FwaXYxL3N0b3JhZ2VwYjtzdG9yYWdlcGKqAiBHb29nbGUu
Q2xvdWQuQmlnUXVlcnkuU3RvcmFnZS5WMcoCIEdvb2dsZVxDbG91ZFxCaWdRdWVyeVxTdG9y
YWdlXFYxSqcYCgYSBA4AWAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACkKCAoBCBIDEgA9CgkKAgglEgMSAD0KCAoBCBIDEwBVCgkKAggLEgMTAFUKCAoB
CBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQArCgkKAggIEgMVACsKCAoBCBIDFgA9CgkKAggB
EgMWAD0KCAoBCBIDFwA+CgkKAggpEgMXAD4KqQIKAgQAEgQfACIBGpwCIEFycm93IHNjaGVt
YSBhcyBzcGVjaWZpZWQgaW4KIGh0dHBzOi8vYXJyb3cuYXBhY2hlLm9yZy9kb2NzL3B5dGhv
bi9hcGkvZGF0YXR5cGVzLmh0bWwKIGFuZCBzZXJpYWxpemVkIHRvIGJ5dGVzIHVzaW5nIElQ
QzoKIGh0dHBzOi8vYXJyb3cuYXBhY2hlLm9yZy9kb2NzL2Zvcm1hdC9Db2x1bW5hci5odG1s
I3NlcmlhbGl6YXRpb24tYW5kLWludGVycHJvY2Vzcy1jb21tdW5pY2F0aW9uLWlwYwoKIFNl
ZSBjb2RlIHNhbXBsZXMgb24gaG93IHRoaXMgbWVzc2FnZSBjYW4gYmUgZGVzZXJpYWxpemVk
LgoKCgoDBAABEgMfCBMKKwoEBAACABIDIQIeGh4gSVBDIHNlcmlhbGl6ZWQgQXJyb3cgc2No
ZW1hLgoKDAoFBAACAAUSAyECBwoMCgUEAAIAARIDIQgZCgwKBQQAAgADEgMhHB0KIAoCBAES
BCUALAEaFCBBcnJvdyBSZWNvcmRCYXRjaC4KCgoKAwQBARIDJQgYCjAKBAQBAgASAycCJBoj
IElQQy1zZXJpYWxpemVkIEFycm93IFJlY29yZEJhdGNoLgoKDAoFBAECAAUSAycCBwoMCgUE
AQIAARIDJwgfCgwKBQQBAgADEgMnIiMKkwEKBAQBAgESAysCKhqFASBbRGVwcmVjYXRlZF0g
VGhlIGNvdW50IG9mIHJvd3MgaW4gYHNlcmlhbGl6ZWRfcmVjb3JkX2JhdGNoYC4KIFBsZWFz
ZSB1c2UgdGhlIGZvcm1hdC1pbmRlcGVuZGVudCBSZWFkUm93c1Jlc3BvbnNlLnJvd19jb3Vu
dCBpbnN0ZWFkLgoKDAoFBAECAQUSAysCBwoMCgUEAQIBARIDKwgRCgwKBQQBAgEDEgMrFBUK
DAoFBAECAQgSAysWKQoNCgYEAQIBCAMSAysXKAo/CgIEAhIELwBYARozIENvbnRhaW5zIG9w
dGlvbnMgc3BlY2lmaWMgdG8gQXJyb3cgU2VyaWFsaXphdGlvbi4KCgoKAwQCARIDLwghCjcK
BAQCBAASBDECOgMaKSBDb21wcmVzc2lvbiBjb2RlYydzIHN1cHBvcnRlZCBieSBBcnJvdy4K
CgwKBQQCBAABEgMxBxcKPAoGBAIEAAIAEgMzBCAaLSBJZiB1bnNwZWNpZmllZCBubyBjb21w
cmVzc2lvbiB3aWxsIGJlIHVzZWQuCgoOCgcEAgQAAgABEgMzBBsKDgoHBAIEAAIAAhIDMx4f
ClgKBgQCBAACARIDNgQSGkkgTFo0IEZyYW1lIChodHRwczovL2dpdGh1Yi5jb20vbHo0L2x6
NC9ibG9iL2Rldi9kb2MvbHo0X0ZyYW1lX2Zvcm1hdC5tZCkKCg4KBwQCBAACAQESAzYEDQoO
CgcEAgQAAgECEgM2EBEKJwoGBAIEAAICEgM5BA0aGCBac3RhbmRhcmQgY29tcHJlc3Npb24u
CgoOCgcEAgQAAgIBEgM5BAgKDgoHBAIEAAICAhIDOQsMCqUBCgQEAgQBEgQ+Ak8DGpYBIFRo
ZSBwcmVjaXNpb24gb2YgdGhlIHRpbWVzdGFtcCB2YWx1ZSBpbiB0aGUgQXZybyBtZXNzYWdl
LiBUaGlzIHByZWNpc2lvbgogd2lsbCAqKm9ubHkqKiBiZSBhcHBsaWVkIHRvIHRoZSBjb2x1
bW4ocykgd2l0aCB0aGUgYFRJTUVTVEFNUF9QSUNPU2AgdHlwZS4KCgwKBQQCBAEBEgM+Bx4K
WAoGBAIEAQIAEgNABC4aSSBVbnNwZWNpZmllZCB0aW1lc3RhbXAgcHJlY2lzaW9uLiBUaGUg
ZGVmYXVsdCBwcmVjaXNpb24gaXMgbWljcm9zZWNvbmRzLgoKDgoHBAIEAQIAARIDQAQpCg4K
BwQCBAECAAISA0AsLQqyAQoGBAIEAQIBEgNFBCMaogEgVGltZXN0YW1wIHZhbHVlcyByZXR1
cm5lZCBieSBSZWFkIEFQSSB3aWxsIGJlIHRydW5jYXRlZCB0byBtaWNyb3NlY29uZAogbGV2
ZWwgcHJlY2lzaW9uLiBUaGUgdmFsdWUgd2lsbCBiZSBlbmNvZGVkIGFzIEFycm93IFRJTUVT
VEFNUCB0eXBlIGluIGEKIDY0IGJpdCBpbnRlZ2VyLgoKDgoHBAIEAQIBARIDRQQeCg4KBwQC
BAECAQISA0UhIgqxAQoGBAIEAQICEgNKBCIaoQEgVGltZXN0YW1wIHZhbHVlcyByZXR1cm5l
ZCBieSBSZWFkIEFQSSB3aWxsIGJlIHRydW5jYXRlZCB0byBuYW5vc2Vjb25kCiBsZXZlbCBw
cmVjaXNpb24uIFRoZSB2YWx1ZSB3aWxsIGJlIGVuY29kZWQgYXMgQXJyb3cgVElNRVNUQU1Q
IHR5cGUgaW4gYQogNjQgYml0IGludGVnZXIuCgoOCgcEAgQBAgIBEgNKBB0KDgoHBAIEAQIC
AhIDSiAhCpEBCgYEAgQBAgMSA04EIhqBASBSZWFkIEFQSSB3aWxsIHJldHVybiBmdWxsIHBy
ZWNpc2lvbiBwaWNvc2Vjb25kIHZhbHVlLiBUaGUgdmFsdWUgd2lsbCBiZQogZW5jb2RlZCBh
cyBhIHN0cmluZyB3aGljaCBjb25mb3JtcyB0byBJU08gODYwMSBmb3JtYXQuCgoOCgcEAgQB
AgMBEgNOBB0KDgoHBAIEAQIDAhIDTiAhClwKBAQCAgASA1MCKhpPIFRoZSBjb21wcmVzc2lv
biBjb2RlYyB0byB1c2UgZm9yIEFycm93IGJ1ZmZlcnMgaW4gc2VyaWFsaXplZCByZWNvcmQK
IGJhdGNoZXMuCgoMCgUEAgIABhIDUwISCgwKBQQCAgABEgNTEyUKDAoFBAICAAMSA1MoKQps
CgQEAgIBEgNXAjgaXyBPcHRpb25hbC4gU2V0IHRpbWVzdGFtcCBwcmVjaXNpb24gb3B0aW9u
LiBJZiBub3Qgc2V0LCB0aGUgZGVmYXVsdCBwcmVjaXNpb24KIGlzIG1pY3Jvc2Vjb25kcy4K
CgwKBQQCAgEGEgNXAhkKDAoFBAICAQESA1caMwoMCgUEAgIBAxIDVzY3YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema ===
    # Fields for ArrowSchema
    # Field: serialized_schema Type: 12 ()

=pod

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Arrow;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSchema->new(
        serialized_schema => $value,
    );

=head1 FIELDS

=over 4

=item * B<serialized_schema>

Type: Bytes

=back

=cut

# === Message: Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch ===
    # Fields for ArrowRecordBatch
    # Field: serialized_record_batch Type: 12 ()
    # Field: row_count Type: 3 ()

=pod

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Arrow;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowRecordBatch->new(
        serialized_record_batch => $value,
    );

=head1 FIELDS

=over 4

=item * B<serialized_record_batch>

Type: Bytes

=item * B<row_count>

Type: Int64

=back

=cut

# === Message: Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions ===
    # Fields for ArrowSerializationOptions
    # Field: buffer_compression Type: 14 (.google.cloud.bigquery.storage.v1.ArrowSerializationOptions.CompressionCodec)
    # Field: picos_timestamp_precision Type: 14 (.google.cloud.bigquery.storage.v1.ArrowSerializationOptions.PicosTimestampPrecision)

=pod

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Arrow;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Arrow::ArrowSerializationOptions->new(
        buffer_compression => $value,
    );

=head1 FIELDS

=over 4

=item * B<buffer_compression>

Type: Enum (.google.cloud.bigquery.storage.v1.ArrowSerializationOptions.CompressionCodec)

=item * B<picos_timestamp_precision>

Type: Enum (.google.cloud.bigquery.storage.v1.ArrowSerializationOptions.PicosTimestampPrecision)

=back

=cut

# Enum: ArrowSerializationOptions::CompressionCodec
our $ArrowSerializationOptions_COMPRESSION_UNSPECIFIED = 0;
our $ArrowSerializationOptions_LZ4_FRAME = 1;
our $ArrowSerializationOptions_ZSTD = 2;

=pod

=head2 Enum: ArrowSerializationOptions::CompressionCodec

Values:

=over 4

=item * C<COMPRESSION_UNSPECIFIED> => 0

=item * C<LZ4_FRAME> => 1

=item * C<ZSTD> => 2

=back

=cut

# Enum: ArrowSerializationOptions::PicosTimestampPrecision
our $ArrowSerializationOptions_PICOS_TIMESTAMP_PRECISION_UNSPECIFIED = 0;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_MICROS = 1;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_NANOS = 2;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_PICOS = 3;

=pod

=head2 Enum: ArrowSerializationOptions::PicosTimestampPrecision

Values:

=over 4

=item * C<PICOS_TIMESTAMP_PRECISION_UNSPECIFIED> => 0

=item * C<TIMESTAMP_PRECISION_MICROS> => 1

=item * C<TIMESTAMP_PRECISION_NANOS> => 2

=item * C<TIMESTAMP_PRECISION_PICOS> => 3

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Arrow - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
