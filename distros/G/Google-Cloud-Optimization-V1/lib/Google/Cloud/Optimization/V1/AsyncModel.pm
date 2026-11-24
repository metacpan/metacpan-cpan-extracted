package Google::Cloud::Optimization::V1::AsyncModel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvb3B0aW1pemF0aW9uL3YxL2FzeW5jX21vZGVsLnByb3RvEhxnb29n
bGUuY2xvdWQub3B0aW1pemF0aW9uLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqwBCgtJbnB1dENvbmZpZxJI
CgpnY3Nfc291cmNlGAEgASgLMicuZ29vZ2xlLmNsb3VkLm9wdGltaXphdGlvbi52MS5HY3NT
b3VyY2VIAFIJZ2NzU291cmNlEkkKC2RhdGFfZm9ybWF0GAIgASgOMiguZ29vZ2xlLmNsb3Vk
Lm9wdGltaXphdGlvbi52MS5EYXRhRm9ybWF0UgpkYXRhRm9ybWF0QggKBnNvdXJjZSLBAQoM
T3V0cHV0Q29uZmlnElcKD2djc19kZXN0aW5hdGlvbhgBIAEoCzIsLmdvb2dsZS5jbG91ZC5v
cHRpbWl6YXRpb24udjEuR2NzRGVzdGluYXRpb25IAFIOZ2NzRGVzdGluYXRpb24SSQoLZGF0
YV9mb3JtYXQYAiABKA4yKC5nb29nbGUuY2xvdWQub3B0aW1pemF0aW9uLnYxLkRhdGFGb3Jt
YXRSCmRhdGFGb3JtYXRCDQoLZGVzdGluYXRpb24iIgoJR2NzU291cmNlEhUKA3VyaRgBIAEo
CUID4EECUgN1cmkiJwoOR2NzRGVzdGluYXRpb24SFQoDdXJpGAEgASgJQgPgQQJSA3VyaSLY
AgoSQXN5bmNNb2RlbE1ldGFkYXRhEkwKBXN0YXRlGAEgASgOMjYuZ29vZ2xlLmNsb3VkLm9w
dGltaXphdGlvbi52MS5Bc3luY01vZGVsTWV0YWRhdGEuU3RhdGVSBXN0YXRlEiMKDXN0YXRl
X21lc3NhZ2UYAiABKAlSDHN0YXRlTWVzc2FnZRI7CgtjcmVhdGVfdGltZRgDIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYBCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lIlUKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASCwoHUlVOTklORxABEg0KCVNVQ0NFRURFRBACEg0KCUNB
TkNFTExFRBADEgoKBkZBSUxFRBAEKj8KCkRhdGFGb3JtYXQSGwoXREFUQV9GT1JNQVRfVU5T
UEVDSUZJRUQQABIICgRKU09OEAESCgoGU1RSSU5HEAJCewogY29tLmdvb2dsZS5jbG91ZC5v
cHRpbWl6YXRpb24udjFCD0FzeW5jTW9kZWxQcm90b1ABWkRjbG91ZC5nb29nbGUuY29tL2dv
L29wdGltaXphdGlvbi9hcGl2MS9vcHRpbWl6YXRpb25wYjtvcHRpbWl6YXRpb25wYkqeGgoG
EgQOAG0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCgkK
AgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVAFsKCQoCCAsSAxUAWwoICgEIEgMWACIKCQoC
CAoSAxYAIgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADkKCQoCCAESAxgAOQo1CgIE
ABIEGwAmARopIFRoZSBkZXNpcmVkIGlucHV0IGxvY2F0aW9uIGluZm9ybWF0aW9uLgoKCgoD
BAABEgMbCBMKTAoEBAAIABIEHgIiAxo+IFRoZSBsb2NhdGlvbiBvZiB0aGUgaW5wdXQgbW9k
ZWwgaW4gY2xvdWQgc3RvcmFnZS4KIFJlcXVpcmVkLgoKDAoFBAAIAAESAx4IDgplCgQEAAIA
EgMhBB0aWCBUaGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gdG8gcmVhZCB0aGUg
aW5wdXQgZnJvbS4gVGhpcyBtdXN0IGJlIGEKIHNpbmdsZSBmaWxlLgoKDAoFBAACAAYSAyEE
DQoMCgUEAAIAARIDIQ4YCgwKBQQAAgADEgMhGxwKUwoEBAACARIDJQIdGkYgVGhlIGlucHV0
IGRhdGEgZm9ybWF0IHRoYXQgdXNlZCB0byBzdG9yZSB0aGUgbW9kZWwgaW4gQ2xvdWQgU3Rv
cmFnZS4KCgwKBQQAAgEGEgMlAgwKDAoFBAACAQESAyUNGAoMCgUEAAIBAxIDJRscCioKAgQB
EgQpADMBGh4gVGhlIGRlc2lyZWQgb3V0cHV0IGxvY2F0aW9uLgoKCgoDBAEBEgMpCBQKTgoE
BAEIABIELAIvAxpAIFRoZSBsb2NhdGlvbiBvZiB0aGUgb3V0cHV0IHJlc3VsdCBpbiBjbG91
ZCBzdG9yYWdlLgogUmVxdWlyZWQuCgoMCgUEAQgAARIDLAgTCkgKBAQBAgASAy4EJxo7IFRo
ZSBHb29nbGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB0byB3cml0ZSB0aGUgb3V0cHV0IHRv
LgoKDAoFBAECAAYSAy4EEgoMCgUEAQIAARIDLhMiCgwKBQQBAgADEgMuJSYKVgoEBAECARID
MgIdGkkgVGhlIG91dHB1dCBkYXRhIGZvcm1hdCB0aGF0IHVzZWQgdG8gc3RvcmUgdGhlIHJl
c3VsdHMgaW4gQ2xvdWQgU3RvcmFnZS4KCgwKBQQBAgEGEgMyAgwKDAoFBAECAQESAzINGAoM
CgUEAQIBAxIDMhscClcKAgQCEgQ2ADkBGksgVGhlIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGxv
Y2F0aW9uIHdoZXJlIHRoZSBpbnB1dCBmaWxlIHdpbGwgYmUgcmVhZCBmcm9tLgoKCgoDBAIB
EgM2CBEKQgoEBAICABIDOAI6GjUgUmVxdWlyZWQuIFVSSSBvZiB0aGUgR29vZ2xlIENsb3Vk
IFN0b3JhZ2UgbG9jYXRpb24uCgoMCgUEAgIABRIDOAIICgwKBQQCAgABEgM4CQwKDAoFBAIC
AAMSAzgPEAoMCgUEAgIACBIDOBE5Cg8KCAQCAgAInAgAEgM4EjgKWQoCBAMSBDwAPwEaTSBU
aGUgR29vZ2xlIENsb3VkIFN0b3JhZ2UgbG9jYXRpb24gd2hlcmUgdGhlIG91dHB1dCBmaWxl
IHdpbGwgYmUgd3JpdHRlbiB0by4KCgoKAwQDARIDPAgWCkIKBAQDAgASAz4COho1IFJlcXVp
cmVkLiBVUkkgb2YgdGhlIEdvb2dsZSBDbG91ZCBTdG9yYWdlIGxvY2F0aW9uLgoKDAoFBAMC
AAUSAz4CCAoMCgUEAwIAARIDPgkMCgwKBQQDAgADEgM+DxAKDAoFBAMCAAgSAz4ROQoPCggE
AwIACJwIABIDPhI4ClIKAgQEEgRCAGEBGkYgVGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24g
bWV0YWRhdGEgZm9yIGFzeW5jIG1vZGVsIHJlbGF0ZWQgbWV0aG9kcy4KCgoKAwQEARIDQgga
CjEKBAQEBAASBEQCUwMaIyBQb3NzaWJsZSBzdGF0ZXMgb2YgdGhlIG9wZXJhdGlvbi4KCgwK
BQQEBAABEgNEBwwKTwoGBAQEAAIAEgNGBBoaQCBUaGUgZGVmYXVsdCB2YWx1ZS4gVGhpcyB2
YWx1ZSBpcyB1c2VkIGlmIHRoZSBzdGF0ZSBpcyBvbWl0dGVkLgoKDgoHBAQEAAIAARIDRgQV
Cg4KBwQEBAACAAISA0YYGQosCgYEBAQAAgESA0kEEBodIFJlcXVlc3QgaXMgYmVpbmcgcHJv
Y2Vzc2VkLgoKDgoHBAQEAAIBARIDSQQLCg4KBwQEBAACAQISA0kODwo2CgYEBAQAAgISA0wE
EhonIFRoZSBvcGVyYXRpb24gY29tcGxldGVkIHN1Y2Nlc3NmdWxseS4KCg4KBwQEBAACAgES
A0wEDQoOCgcEBAQAAgICEgNMEBEKLQoGBAQEAAIDEgNPBBIaHiBUaGUgb3BlcmF0aW9uIHdh
cyBjYW5jZWxsZWQuCgoOCgcEBAQAAgMBEgNPBA0KDgoHBAQEAAIDAhIDTxARCioKBgQEBAAC
BBIDUgQPGhsgVGhlIG9wZXJhdGlvbiBoYXMgZmFpbGVkLgoKDgoHBAQEAAIEARIDUgQKCg4K
BwQEBAACBAISA1INDgoyCgQEBAIAEgNWAhIaJSBUaGUgc3RhdGUgb2YgdGhlIGN1cnJlbnQg
b3BlcmF0aW9uLgoKDAoFBAQCAAYSA1YCBwoMCgUEBAIAARIDVggNCgwKBQQEAgADEgNWEBEK
lgEKBAQEAgESA1oCGxqIASBBIG1lc3NhZ2UgcHJvdmlkaW5nIG1vcmUgZGV0YWlscyBhYm91
dCB0aGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgb3BlcmF0aW9uLgogRm9yIGV4YW1wbGUsIHRo
ZSBlcnJvciBtZXNzYWdlIGlmIHRoZSBvcGVyYXRpb24gaXMgZmFpbGVkLgoKDAoFBAQCAQUS
A1oCCAoMCgUEBAIBARIDWgkWCgwKBQQEAgEDEgNaGRoKMgoEBAQCAhIDXQIsGiUgVGhlIGNy
ZWF0aW9uIHRpbWUgb2YgdGhlIG9wZXJhdGlvbi4KCgwKBQQEAgIGEgNdAhsKDAoFBAQCAgES
A10cJwoMCgUEBAICAxIDXSorCjUKBAQEAgMSA2ACLBooIFRoZSBsYXN0IHVwZGF0ZSB0aW1l
IG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEBAIDBhIDYAIbCgwKBQQEAgMBEgNgHCcKDAoFBAQC
AwMSA2AqKwo2CgIFABIEZABtARoqIERhdGEgZm9ybWF0cyBmb3IgaW5wdXQgYW5kIG91dHB1
dCBmaWxlcy4KCgoKAwUAARIDZAUPCh0KBAUAAgASA2YCHhoQIERlZmF1bHQgdmFsdWUuCgoM
CgUFAAIAARIDZgIZCgwKBQUAAgACEgNmHB0KKQoEBQACARIDaQILGhwgSW5wdXQgZGF0YSBp
biBqc29uIGZvcm1hdC4KCgwKBQUAAgEBEgNpAgYKDAoFBQACAQISA2kJCgorCgQFAAICEgNs
Ag0aHiBJbnB1dCBkYXRhIGluIHN0cmluZyBmb3JtYXQuCgoMCgUFAAICARIDbAIICgwKBQUA
AgICEgNsCwxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Optimization::V1::AsyncModel::InputConfig ===
    # Fields for InputConfig
    # Field: gcs_source Type: 11 (.google.cloud.optimization.v1.GcsSource)
    # Field: data_format Type: 14 (.google.cloud.optimization.v1.DataFormat)

# === Message: Google::Cloud::Optimization::V1::AsyncModel::OutputConfig ===
    # Fields for OutputConfig
    # Field: gcs_destination Type: 11 (.google.cloud.optimization.v1.GcsDestination)
    # Field: data_format Type: 14 (.google.cloud.optimization.v1.DataFormat)

# === Message: Google::Cloud::Optimization::V1::AsyncModel::GcsSource ===
    # Fields for GcsSource
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Optimization::V1::AsyncModel::GcsDestination ===
    # Fields for GcsDestination
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Optimization::V1::AsyncModel::AsyncModelMetadata ===
    # Fields for AsyncModelMetadata
    # Field: state Type: 14 (.google.cloud.optimization.v1.AsyncModelMetadata.State)
    # Field: state_message Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# Enum: AsyncModelMetadata::State
our $AsyncModelMetadata_STATE_UNSPECIFIED = 0;
our $AsyncModelMetadata_RUNNING = 1;
our $AsyncModelMetadata_SUCCEEDED = 2;
our $AsyncModelMetadata_CANCELLED = 3;
our $AsyncModelMetadata_FAILED = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Optimization::V1::AsyncModel - Compiled Protocol Buffers messages for google/cloud/optimization/v1/async_model.proto

=head1 SYNOPSIS

    use Google::Cloud::Optimization::V1::AsyncModel;

    my $msg = Google::Cloud::Optimization::V1::AsyncModel::InputConfig->new({
        gcs_source => $gcs_source,
        data_format => $data_format,
    });

    # Read or update a field
    my $val = $msg->gcs_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Optimization::V1::AsyncModel::InputConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/optimization/v1/async_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Optimization::V1::AsyncModel::InputConfig

The desired input location information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Optimization::V1::AsyncModel::GcsSource>)

The Google Cloud Storage location to read the input from. This must be a
single file.

=item * C<< $msg->data_format() >> / C<< $msg->data_format($value) >>

Type: C<Enum> (L<Google::Cloud::Optimization::V1::DataFormat>)

The input data format that used to store the model in Cloud Storage.

=back

=head2 Google::Cloud::Optimization::V1::AsyncModel::OutputConfig

The desired output location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_destination() >> / C<< $msg->gcs_destination($value) >>

Type: C<Message> (L<Google::Cloud::Optimization::V1::AsyncModel::GcsDestination>)

The Google Cloud Storage location to write the output to.

=item * C<< $msg->data_format() >> / C<< $msg->data_format($value) >>

Type: C<Enum> (L<Google::Cloud::Optimization::V1::DataFormat>)

The output data format that used to store the results in Cloud Storage.

=back

=head2 Google::Cloud::Optimization::V1::AsyncModel::GcsSource

The Google Cloud Storage location where the input file will be read from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. URI of the Google Cloud Storage location.

=back

=head2 Google::Cloud::Optimization::V1::AsyncModel::GcsDestination

The Google Cloud Storage location where the output file will be written to.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. URI of the Google Cloud Storage location.

=back

=head2 Google::Cloud::Optimization::V1::AsyncModel::AsyncModelMetadata

The long running operation metadata for async model related methods.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Optimization::V1::AsyncModelMetadata::State>)

The state of the current operation.

=item * C<< $msg->state_message() >> / C<< $msg->state_message($value) >>

Type: C<String>

A message providing more details about the current state of the operation.
For example, the error message if the operation is failed.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The creation time of the operation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The last update time of the operation.

=back

=head3 Enum: AsyncModelMetadata::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<RUNNING> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<CANCELLED> => C<3>

=item * C<FAILED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Optimization::V1::AsyncModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
