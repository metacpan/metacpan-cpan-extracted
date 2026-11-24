package Google::Cloud::Bigquery::V2::Arrow;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvYXJyb3cucHJvdG8SGGdvb2dsZS5jbG91ZC5i
aWdxdWVyeS52MiI6CgtBcnJvd1NjaGVtYRIrChFzZXJpYWxpemVkX3NjaGVtYRgBIAEoDFIQ
c2VyaWFsaXplZFNjaGVtYSJKChBBcnJvd1JlY29yZEJhdGNoEjYKF3NlcmlhbGl6ZWRfcmVj
b3JkX2JhdGNoGAEgASgMUhVzZXJpYWxpemVkUmVjb3JkQmF0Y2giiQQKGUFycm93U2VyaWFs
aXphdGlvbk9wdGlvbnMScwoSYnVmZmVyX2NvbXByZXNzaW9uGAIgASgOMkQuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnYyLkFycm93U2VyaWFsaXphdGlvbk9wdGlvbnMuQ29tcHJlc3Npb25D
b2RlY1IRYnVmZmVyQ29tcHJlc3Npb24ShwEKGXBpY29zX3RpbWVzdGFtcF9wcmVjaXNpb24Y
AyABKA4ySy5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuQXJyb3dTZXJpYWxpemF0aW9uT3B0
aW9ucy5QaWNvc1RpbWVzdGFtcFByZWNpc2lvblIXcGljb3NUaW1lc3RhbXBQcmVjaXNpb24i
SAoQQ29tcHJlc3Npb25Db2RlYxIbChdDT01QUkVTU0lPTl9VTlNQRUNJRklFRBAAEg0KCUxa
NF9GUkFNRRABEggKBFpTVEQQAiKiAQoXUGljb3NUaW1lc3RhbXBQcmVjaXNpb24SKQolUElD
T1NfVElNRVNUQU1QX1BSRUNJU0lPTl9VTlNQRUNJRklFRBAAEh4KGlRJTUVTVEFNUF9QUkVD
SVNJT05fTUlDUk9TEAESHQoZVElNRVNUQU1QX1BSRUNJU0lPTl9OQU5PUxACEh0KGVRJTUVT
VEFNUF9QUkVDSVNJT05fUElDT1MQA0JpChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYy
QgpBcnJvd1Byb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIv
YmlncXVlcnlwYjtiaWdxdWVyeXBiSrcXCgYSBA4AWQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACEKCAoBCBIDEgBSCgkKAggLEgMSAFIKCAoBCBIDEwAi
CgkKAggKEgMTACIKCAoBCBIDFAArCgkKAggIEgMUACsKCAoBCBIDFQA1CgkKAggBEgMVADUK
zgIKAgQAEgQfACIBGsECIEFycm93IHNjaGVtYSBhcyBzcGVjaWZpZWQKIGluIGh0dHBzOi8v
YXJyb3cuYXBhY2hlLm9yZy9kb2NzL3B5dGhvbi9hcGkvZGF0YXR5cGVzLmh0bWwgYW5kIHNl
cmlhbGl6ZWQgdG8KIGJ5dGVzIHVzaW5nIElQQzoKIGh0dHBzOi8vYXJyb3cuYXBhY2hlLm9y
Zy9kb2NzL2Zvcm1hdC9Db2x1bW5hci5odG1sI3NlcmlhbGl6YXRpb24tYW5kLWludGVycHJv
Y2Vzcy1jb21tdW5pY2F0aW9uLWlwYwoKIFNlZSBjb2RlIHNhbXBsZXMgb24gaG93IHRoaXMg
bWVzc2FnZSBjYW4gYmUgZGVzZXJpYWxpemVkLgoKIFRoaXMgZmVhdHVyZSBpcyBub3QgeWV0
IGF2YWlsYWJsZS4KCgoKAwQAARIDHwgTCisKBAQAAgASAyECHhoeIElQQyBzZXJpYWxpemVk
IEFycm93IHNjaGVtYS4KCgwKBQQAAgAFEgMhAgcKDAoFBAACAAESAyEIGQoMCgUEAAIAAxID
IRwdCkUKAgQBEgQnACoBGjkgQXJyb3cgUmVjb3JkQmF0Y2guCgogVGhpcyBmZWF0dXJlIGlz
IG5vdCB5ZXQgYXZhaWxhYmxlLgoKCgoDBAEBEgMnCBgKMAoEBAECABIDKQIkGiMgSVBDLXNl
cmlhbGl6ZWQgQXJyb3cgUmVjb3JkQmF0Y2guCgoMCgUEAQIABRIDKQIHCgwKBQQBAgABEgMp
CB8KDAoFBAECAAMSAykiIwpkCgIEAhIELwBZARpYIENvbnRhaW5zIG9wdGlvbnMgc3BlY2lm
aWMgdG8gQXJyb3cgU2VyaWFsaXphdGlvbi4KCiBUaGlzIGZlYXR1cmUgaXMgbm90IHlldCBh
dmFpbGFibGUuCgoKCgMEAgESAy8IIQo3CgQEAgQAEgQxAjoDGikgQ29tcHJlc3Npb24gY29k
ZWMncyBzdXBwb3J0ZWQgYnkgQXJyb3cuCgoMCgUEAgQAARIDMQcXCjwKBgQCBAACABIDMwQg
Gi0gSWYgdW5zcGVjaWZpZWQgbm8gY29tcHJlc3Npb24gd2lsbCBiZSB1c2VkLgoKDgoHBAIE
AAIAARIDMwQbCg4KBwQCBAACAAISAzMeHwpYCgYEAgQAAgESAzYEEhpJIExaNCBGcmFtZSAo
aHR0cHM6Ly9naXRodWIuY29tL2x6NC9sejQvYmxvYi9kZXYvZG9jL2x6NF9GcmFtZV9mb3Jt
YXQubWQpCgoOCgcEAgQAAgEBEgM2BA0KDgoHBAIEAAIBAhIDNhARCicKBgQCBAACAhIDOQQN
GhggWnN0YW5kYXJkIGNvbXByZXNzaW9uLgoKDgoHBAIEAAICARIDOQQICg4KBwQCBAACAgIS
AzkLDAqlAQoEBAIEARIEPgJQAxqWASBUaGUgcHJlY2lzaW9uIG9mIHRoZSB0aW1lc3RhbXAg
dmFsdWUgaW4gdGhlIEF2cm8gbWVzc2FnZS4gVGhpcyBwcmVjaXNpb24KIHdpbGwgKipvbmx5
KiogYmUgYXBwbGllZCB0byB0aGUgY29sdW1uKHMpIHdpdGggdGhlIGBUSU1FU1RBTVBfUElD
T1NgIHR5cGUuCgoMCgUEAgQBARIDPgceClgKBgQCBAECABIDQAQuGkkgVW5zcGVjaWZpZWQg
dGltZXN0YW1wIHByZWNpc2lvbi4gVGhlIGRlZmF1bHQgcHJlY2lzaW9uIGlzIG1pY3Jvc2Vj
b25kcy4KCg4KBwQCBAECAAESA0AEKQoOCgcEAgQBAgACEgNALC0KtQEKBgQCBAECARIDRQQj
GqUBIFRpbWVzdGFtcCB2YWx1ZXMgcmV0dXJuZWQgaW4gdGhlIHJlc3VsdHMgd2lsbCBiZSB0
cnVuY2F0ZWQgdG8gbWljcm9zZWNvbmQKIGxldmVsIHByZWNpc2lvbi4gVGhlIHZhbHVlIHdp
bGwgYmUgZW5jb2RlZCBhcyBBcnJvdyBUSU1FU1RBTVAgdHlwZSBpbiBhCiA2NCBiaXQgaW50
ZWdlci4KCg4KBwQCBAECAQESA0UEHgoOCgcEAgQBAgECEgNFISIKtAEKBgQCBAECAhIDSgQi
GqQBIFRpbWVzdGFtcCB2YWx1ZXMgcmV0dXJuZWQgaW4gdGhlIHJlc3VsdHMgd2lsbCBiZSB0
cnVuY2F0ZWQgdG8gbmFub3NlY29uZAogbGV2ZWwgcHJlY2lzaW9uLiBUaGUgdmFsdWUgd2ls
bCBiZSBlbmNvZGVkIGFzIEFycm93IFRJTUVTVEFNUCB0eXBlIGluIGEKIDY0IGJpdCBpbnRl
Z2VyLgoKDgoHBAIEAQICARIDSgQdCg4KBwQCBAECAgISA0ogIQqzAQoGBAIEAQIDEgNPBCIa
owEgVGltZXN0YW1wIHZhbHVlcyByZXR1cm5lZCBpbiB0aGUgcmVzdWx0cyB3aWxsIGNvbnRh
aW4gZnVsbCBwcmVjaXNpb24KIHBpY29zZWNvbmQgdmFsdWUuIFRoZSB2YWx1ZSB3aWxsIGJl
IGVuY29kZWQgYXMgYSBzdHJpbmcgd2hpY2ggY29uZm9ybXMgdG8KIElTTyA4NjAxIGZvcm1h
dC4KCg4KBwQCBAECAwESA08EHQoOCgcEAgQBAgMCEgNPICEKXAoEBAICABIDVAIqGk8gVGhl
IGNvbXByZXNzaW9uIGNvZGVjIHRvIHVzZSBmb3IgQXJyb3cgYnVmZmVycyBpbiBzZXJpYWxp
emVkIHJlY29yZAogYmF0Y2hlcy4KCgwKBQQCAgAGEgNUAhIKDAoFBAICAAESA1QTJQoMCgUE
AgIAAxIDVCgpCmwKBAQCAgESA1gCOBpfIE9wdGlvbmFsLiBTZXQgdGltZXN0YW1wIHByZWNp
c2lvbiBvcHRpb24uIElmIG5vdCBzZXQsIHRoZSBkZWZhdWx0IHByZWNpc2lvbgogaXMgbWlj
cm9zZWNvbmRzLgoKDAoFBAICAQYSA1gCGQoMCgUEAgIBARIDWBozCgwKBQQCAgEDEgNYNjdi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Arrow::ArrowSchema ===
    # Fields for ArrowSchema
    # Field: serialized_schema Type: 12 ()

# === Message: Google::Cloud::Bigquery::V2::Arrow::ArrowRecordBatch ===
    # Fields for ArrowRecordBatch
    # Field: serialized_record_batch Type: 12 ()

# === Message: Google::Cloud::Bigquery::V2::Arrow::ArrowSerializationOptions ===
    # Fields for ArrowSerializationOptions
    # Field: buffer_compression Type: 14 (.google.cloud.bigquery.v2.ArrowSerializationOptions.CompressionCodec)
    # Field: picos_timestamp_precision Type: 14 (.google.cloud.bigquery.v2.ArrowSerializationOptions.PicosTimestampPrecision)

# Enum: ArrowSerializationOptions::CompressionCodec
our $ArrowSerializationOptions_COMPRESSION_UNSPECIFIED = 0;
our $ArrowSerializationOptions_LZ4_FRAME = 1;
our $ArrowSerializationOptions_ZSTD = 2;

# Enum: ArrowSerializationOptions::PicosTimestampPrecision
our $ArrowSerializationOptions_PICOS_TIMESTAMP_PRECISION_UNSPECIFIED = 0;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_MICROS = 1;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_NANOS = 2;
our $ArrowSerializationOptions_TIMESTAMP_PRECISION_PICOS = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::Arrow - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/arrow.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::Arrow;

    my $msg = Google::Cloud::Bigquery::V2::Arrow::ArrowSchema->new({
        serialized_schema => $serialized_schema,
    });

    # Read or update a field
    my $val = $msg->serialized_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::Arrow::ArrowSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/arrow.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::Arrow::ArrowSchema

Arrow schema as specified
in https://arrow.apache.org/docs/python/api/datatypes.html and serialized to
bytes using IPC:
https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc

See code samples on how this message can be deserialized.

This feature is not yet available.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_schema() >> / C<< $msg->serialized_schema($value) >>

Type: C<Bytes>

IPC serialized Arrow schema.

=back

=head2 Google::Cloud::Bigquery::V2::Arrow::ArrowRecordBatch

Arrow RecordBatch.

This feature is not yet available.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_record_batch() >> / C<< $msg->serialized_record_batch($value) >>

Type: C<Bytes>

IPC-serialized Arrow RecordBatch.

=back

=head2 Google::Cloud::Bigquery::V2::Arrow::ArrowSerializationOptions

Contains options specific to Arrow Serialization.

This feature is not yet available.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->buffer_compression() >> / C<< $msg->buffer_compression($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::ArrowSerializationOptions::CompressionCodec>)

The compression codec to use for Arrow buffers in serialized record
batches.

=item * C<< $msg->picos_timestamp_precision() >> / C<< $msg->picos_timestamp_precision($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::V2::ArrowSerializationOptions::PicosTimestampPrecision>)

Optional. Set timestamp precision option. If not set, the default precision
is microseconds.

=back

=head3 Enum: ArrowSerializationOptions::CompressionCodec

=over 4

=item * C<COMPRESSION_UNSPECIFIED> => C<0>

=item * C<LZ4_FRAME> => C<1>

=item * C<ZSTD> => C<2>

=back

=head3 Enum: ArrowSerializationOptions::PicosTimestampPrecision

=over 4

=item * C<PICOS_TIMESTAMP_PRECISION_UNSPECIFIED> => C<0>

=item * C<TIMESTAMP_PRECISION_MICROS> => C<1>

=item * C<TIMESTAMP_PRECISION_NANOS> => C<2>

=item * C<TIMESTAMP_PRECISION_PICOS> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::Arrow::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
