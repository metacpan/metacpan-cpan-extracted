package Google::Cloud::Bigquery::Storage::V1beta2::Arrow;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEyL2Fycm93LnByb3RvEiVn
b29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyIjoKC0Fycm93U2NoZW1hEisK
EXNlcmlhbGl6ZWRfc2NoZW1hGAEgASgMUhBzZXJpYWxpemVkU2NoZW1hIkoKEEFycm93UmVj
b3JkQmF0Y2gSNgoXc2VyaWFsaXplZF9yZWNvcmRfYmF0Y2gYASABKAxSFXNlcmlhbGl6ZWRS
ZWNvcmRCYXRjaCK+AQoZQXJyb3dTZXJpYWxpemF0aW9uT3B0aW9ucxJfCgZmb3JtYXQYASAB
KA4yRy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyLkFycm93U2VyaWFs
aXphdGlvbk9wdGlvbnMuRm9ybWF0UgZmb3JtYXQiQAoGRm9ybWF0EhYKEkZPUk1BVF9VTlNQ
RUNJRklFRBAAEg4KCkFSUk9XXzBfMTQQARIOCgpBUlJPV18wXzE1EAJCfgopY29tLmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTJCCkFycm93UHJvdG9QAVpDY2xvdWQu
Z29vZ2xlLmNvbS9nby9iaWdxdWVyeS9zdG9yYWdlL2FwaXYxYmV0YTIvc3RvcmFnZXBiO3N0
b3JhZ2VwYkqFDgoGEgQOADgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAuCggKAQgSAxIAWgoJCgIICxIDEgBaCggKAQgSAxMAIgoJCgIIChIDEwAiCggK
AQgSAxQAKwoJCgIICBIDFAArCggKAQgSAxUAQgoJCgIIARIDFQBCCqkCCgIEABIEHQAgARqc
AiBBcnJvdyBzY2hlbWEgYXMgc3BlY2lmaWVkIGluCiBodHRwczovL2Fycm93LmFwYWNoZS5v
cmcvZG9jcy9weXRob24vYXBpL2RhdGF0eXBlcy5odG1sCiBhbmQgc2VyaWFsaXplZCB0byBi
eXRlcyB1c2luZyBJUEM6CiBodHRwczovL2Fycm93LmFwYWNoZS5vcmcvZG9jcy9mb3JtYXQv
Q29sdW1uYXIuaHRtbCNzZXJpYWxpemF0aW9uLWFuZC1pbnRlcnByb2Nlc3MtY29tbXVuaWNh
dGlvbi1pcGMKCiBTZWUgY29kZSBzYW1wbGVzIG9uIGhvdyB0aGlzIG1lc3NhZ2UgY2FuIGJl
IGRlc2VyaWFsaXplZC4KCgoKAwQAARIDHQgTCisKBAQAAgASAx8CHhoeIElQQyBzZXJpYWxp
emVkIEFycm93IHNjaGVtYS4KCgwKBQQAAgAFEgMfAgcKDAoFBAACAAESAx8IGQoMCgUEAAIA
AxIDHxwdCiAKAgQBEgQjACYBGhQgQXJyb3cgUmVjb3JkQmF0Y2guCgoKCgMEAQESAyMIGAow
CgQEAQIAEgMlAiQaIyBJUEMtc2VyaWFsaXplZCBBcnJvdyBSZWNvcmRCYXRjaC4KCgwKBQQB
AgAFEgMlAgcKDAoFBAECAAESAyUIHwoMCgUEAQIAAxIDJSIjCj8KAgQCEgQpADgBGjMgQ29u
dGFpbnMgb3B0aW9ucyBzcGVjaWZpYyB0byBBcnJvdyBTZXJpYWxpemF0aW9uLgoKCgoDBAIB
EgMpCCEKRQoEBAIEABIEKwI0Axo3IFRoZSBJUEMgZm9ybWF0IHRvIHVzZSB3aGVuIHNlcmlh
bGl6aW5nIEFycm93IHN0cmVhbXMuCgoMCgUEAgQAARIDKwcNCk0KBgQCBAACABIDLQQbGj4g
SWYgdW5zcGVjaWVkIHRoZSBJUEMgZm9ybWF0IGFzIG9mIDAuMTUgcmVsZWFzZSB3aWxsIGJl
IHVzZWQuCgoOCgcEAgQAAgABEgMtBBYKDgoHBAIEAAIAAhIDLRkaClMKBgQCBAACARIDMAQT
GkQgVXNlIHRoZSBsZWdhY3kgSVBDIG1lc3NhZ2UgZm9ybWF0IGFzIG9mIEFwYWNoZSBBcnJv
dyBSZWxlYXNlIDAuMTQuCgoOCgcEAgQAAgEBEgMwBA4KDgoHBAIEAAIBAhIDMBESCkgKBgQC
BAACAhIDMwQTGjkgVXNlIHRoZSBtZXNzYWdlIGZvcm1hdCBhcyBvZiBBcGFjaGUgQXJyb3cg
UmVsZWFzZSAwLjE1LgoKDgoHBAIEAAICARIDMwQOCg4KBwQCBAACAgISAzMREgorCgQEAgIA
EgM3AhQaHiBUaGUgQXJyb3cgSVBDIGZvcm1hdCB0byB1c2UuCgoMCgUEAgIABhIDNwIICgwK
BQQCAgABEgM3CQ8KDAoFBAICAAMSAzcSE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSchema ===
    # Fields for ArrowSchema
    # Field: serialized_schema Type: 12 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowRecordBatch ===
    # Fields for ArrowRecordBatch
    # Field: serialized_record_batch Type: 12 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSerializationOptions ===
    # Fields for ArrowSerializationOptions
    # Field: format Type: 14 (.google.cloud.bigquery.storage.v1beta2.ArrowSerializationOptions.Format)

# Enum: ArrowSerializationOptions::Format
our $ArrowSerializationOptions_FORMAT_UNSPECIFIED = 0;
our $ArrowSerializationOptions_ARROW_0_14 = 1;
our $ArrowSerializationOptions_ARROW_0_15 = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta2::Arrow - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta2/arrow.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta2::Arrow;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSchema->new({
        serialized_schema => $serialized_schema,
    });

    # Read or update a field
    my $val = $msg->serialized_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta2/arrow.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSchema

Arrow schema as specified in
https://arrow.apache.org/docs/python/api/datatypes.html
and serialized to bytes using IPC:
https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc

See code samples on how this message can be deserialized.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_schema() >> / C<< $msg->serialized_schema($value) >>

Type: C<Bytes>

IPC serialized Arrow schema.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowRecordBatch

Arrow RecordBatch.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_record_batch() >> / C<< $msg->serialized_record_batch($value) >>

Type: C<Bytes>

IPC-serialized Arrow RecordBatch.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Arrow::ArrowSerializationOptions

Contains options specific to Arrow Serialization.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1beta2::ArrowSerializationOptions::Format>)

The Arrow IPC format to use.

=back

=head3 Enum: ArrowSerializationOptions::Format

=over 4

=item * C<FORMAT_UNSPECIFIED> => C<0>

=item * C<ARROW_0_14> => C<1>

=item * C<ARROW_0_15> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta2::Arrow::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
