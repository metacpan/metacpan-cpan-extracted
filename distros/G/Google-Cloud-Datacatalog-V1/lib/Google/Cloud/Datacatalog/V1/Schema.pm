package Google::Cloud::Datacatalog::V1::Schema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvc2NoZW1hLnByb3RvEhtnb29nbGUuY2xv
dWQuZGF0YWNhdGFsb2cudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iTQoG
U2NoZW1hEkMKB2NvbHVtbnMYAiADKAsyKS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEu
Q29sdW1uU2NoZW1hUgdjb2x1bW5zIu4ICgxDb2x1bW5TY2hlbWESGwoGY29sdW1uGAYgASgJ
QgPgQQJSBmNvbHVtbhIXCgR0eXBlGAEgASgJQgPgQQJSBHR5cGUSJQoLZGVzY3JpcHRpb24Y
AiABKAlCA+BBAVILZGVzY3JpcHRpb24SFwoEbW9kZRgDIAEoCUID4EEBUgRtb2RlEigKDWRl
ZmF1bHRfdmFsdWUYCCABKAlCA+BBAVIMZGVmYXVsdFZhbHVlEi4KEG9yZGluYWxfcG9zaXRp
b24YCSABKAVCA+BBAVIPb3JkaW5hbFBvc2l0aW9uEm8KFWhpZ2hlc3RfaW5kZXhpbmdfdHlw
ZRgKIAEoDjI2Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Db2x1bW5TY2hlbWEuSW5k
ZXhpbmdUeXBlQgPgQQFSE2hpZ2hlc3RJbmRleGluZ1R5cGUSTgoKc3ViY29sdW1ucxgHIAMo
CzIpLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5Db2x1bW5TY2hlbWFCA+BBAVIKc3Vi
Y29sdW1ucxJqChJsb29rZXJfY29sdW1uX3NwZWMYEiABKAsyOi5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjEuQ29sdW1uU2NoZW1hLkxvb2tlckNvbHVtblNwZWNIAFIQbG9va2VyQ29s
dW1uU3BlYxJtChJyYW5nZV9lbGVtZW50X3R5cGUYEyABKAsyOi5nb29nbGUuY2xvdWQuZGF0
YWNhdGFsb2cudjEuQ29sdW1uU2NoZW1hLkZpZWxkRWxlbWVudFR5cGVCA+BBAVIQcmFuZ2VF
bGVtZW50VHlwZRIcCgdnY19ydWxlGAsgASgJQgPgQQFSBmdjUnVsZRr4AQoQTG9va2VyQ29s
dW1uU3BlYxJfCgR0eXBlGAEgASgOMksuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkNv
bHVtblNjaGVtYS5Mb29rZXJDb2x1bW5TcGVjLkxvb2tlckNvbHVtblR5cGVSBHR5cGUiggEK
EExvb2tlckNvbHVtblR5cGUSIgoeTE9PS0VSX0NPTFVNTl9UWVBFX1VOU1BFQ0lGSUVEEAAS
DQoJRElNRU5TSU9OEAESEwoPRElNRU5TSU9OX0dST1VQEAISCgoGRklMVEVSEAMSCwoHTUVB
U1VSRRAEEg0KCVBBUkFNRVRFUhAFGisKEEZpZWxkRWxlbWVudFR5cGUSFwoEdHlwZRgBIAEo
CUID4EECUgR0eXBlIpwBCgxJbmRleGluZ1R5cGUSHQoZSU5ERVhJTkdfVFlQRV9VTlNQRUNJ
RklFRBAAEhYKEklOREVYSU5HX1RZUEVfTk9ORRABEhwKGElOREVYSU5HX1RZUEVfTk9OX1VO
SVFVRRACEhgKFElOREVYSU5HX1RZUEVfVU5JUVVFEAMSHQoZSU5ERVhJTkdfVFlQRV9QUklN
QVJZX0tFWRAEQg0KC3N5c3RlbV9zcGVjQsMBCh9jb20uZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YWNhdGFsb2cvYXBpdjEvZGF0YWNh
dGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIbR29vZ2xlLkNsb3VkLkRhdGFDYXRhbG9nLlYxygIb
R29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYx6gIeR29vZ2xlOjpDbG91ZDo6RGF0YUNhdGFs
b2c6OlYxSq4lCgcSBQ4AkwEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
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
CAoBAhIDEAAkCgkKAgMAEgMSACkKCAoBCBIDFAA4CgkKAgglEgMUADgKCAoBCBIDFQBYCgkK
AggLEgMVAFgKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA4CgkKAggBEgMXADgKCAoB
CBIDGAA4CgkKAggpEgMYADgKCAoBCBIDGQA3CgkKAggtEgMZADcKVgoCBAASBBwAIgEaSiBS
ZXByZXNlbnRzIGEgc2NoZW1hLCBmb3IgZXhhbXBsZSwgYSBCaWdRdWVyeSwgR29vZ2xlU1FM
LCBvciBBdnJvIHNjaGVtYS4KCgoKAwQAARIDHAgOCqsBCgQEAAIAEgMhAiQanQEgVGhlIHVu
aWZpZWQgR29vZ2xlU1FMLWxpa2Ugc2NoZW1hIG9mIGNvbHVtbnMuCgogVGhlIG92ZXJhbGwg
bWF4aW11bSBudW1iZXIgb2YgY29sdW1ucyBhbmQgbmVzdGVkIGNvbHVtbnMgaXMgMTAsMDAw
LgogVGhlIG1heGltdW0gbmVzdGVkIGRlcHRoIGlzIDE1IGxldmVscy4KCgwKBQQAAgAEEgMh
AgoKDAoFBAACAAYSAyELFwoMCgUEAAIAARIDIRgfCgwKBQQAAgADEgMhIiMKVQoCBAESBSYA
kwEBGkggQSBjb2x1bW4gd2l0aGluIGEgc2NoZW1hLiBDb2x1bW5zIGNhbiBiZSBuZXN0ZWQg
aW5zaWRlCiBvdGhlciBjb2x1bW5zLgoKCgoDBAEBEgMmCBQKPQoEBAEEABIEKAI3AxovIFNw
ZWNpZmllcyBpbmNsdXNpb24gb2YgdGhlIGNvbHVtbiBpbiBhbiBpbmRleAoKDAoFBAEEAAES
AygHEwodCgYEAQQAAgASAyoEIhoOIFVuc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDKgQdCg4K
BwQBBAACAAISAyogIQovCgYEAQQAAgESAy0EGxogIENvbHVtbiBub3QgYSBwYXJ0IG9mIGFu
IGluZGV4LgoKDgoHBAEEAAIBARIDLQQWCg4KBwQBBAACAQISAy0ZGgoxCgYEAQQAAgISAzAE
IRoiIENvbHVtbiBQYXJ0IG9mIG5vbiB1bmlxdWUgaW5kZXguCgoOCgcEAQQAAgIBEgMwBBwK
DgoHBAEEAAICAhIDMB8gCi0KBgQBBAACAxIDMwQdGh4gQ29sdW1uIHBhcnQgb2YgdW5pcXVl
IGluZGV4LgoKDgoHBAEEAAIDARIDMwQYCg4KBwQBBAACAwISAzMbHAowCgYEAQQAAgQSAzYE
IhohIENvbHVtbiBwYXJ0IG9mIHRoZSBwcmltYXJ5IGtleS4KCg4KBwQBBAACBAESAzYEHQoO
CgcEAQQAAgQCEgM2ICEKNgoEBAEDABIEOgJSAxooIENvbHVtbiBpbmZvIHNwZWNpZmljIHRv
IExvb2tlciBTeXN0ZW0uCgoMCgUEAQMAARIDOgoaCigKBgQBAwAEABIEPAROBRoYIENvbHVt
biB0eXBlIGluIExvb2tlci4KCg4KBwQBAwAEAAESAzwJGQofCggEAQMABAACABIDPgYpGg4g
VW5zcGVjaWZpZWQuCgoQCgkEAQMABAACAAESAz4GJAoQCgkEAQMABAACAAISAz4nKAodCggE
AQMABAACARIDQQYUGgwgRGltZW5zaW9uLgoKEAoJBAEDAAQAAgEBEgNBBg8KEAoJBAEDAAQA
AgECEgNBEhMKOgoIBAEDAAQAAgISA0QGGhopIERpbWVuc2lvbiBncm91cCAtIHBhcmVudCBm
b3IgRGltZW5zaW9uLgoKEAoJBAEDAAQAAgIBEgNEBhUKEAoJBAEDAAQAAgICEgNEGBkKGgoI
BAEDAAQAAgMSA0cGERoJIEZpbHRlci4KChAKCQQBAwAEAAIDARIDRwYMChAKCQQBAwAEAAID
AhIDRw8QChsKCAQBAwAEAAIEEgNKBhIaCiBNZWFzdXJlLgoKEAoJBAEDAAQAAgQBEgNKBg0K
EAoJBAEDAAQAAgQCEgNKEBEKHQoIBAEDAAQAAgUSA00GFBoMIFBhcmFtZXRlci4KChAKCQQB
AwAEAAIFARIDTQYPChAKCQQBAwAEAAIFAhIDTRITCjwKBgQBAwACABIDUQQeGi0gTG9va2Vy
IHNwZWNpZmljIGNvbHVtbiB0eXBlIG9mIHRoaXMgY29sdW1uLgoKDgoHBAEDAAIABhIDUQQU
Cg4KBwQBAwACAAESA1EVGQoOCgcEAQMAAgADEgNRHB0KNwoEBAEDARIEVQJZAxopIFJlcHJl
c2VudHMgdGhlIHR5cGUgb2YgYSBmaWVsZCBlbGVtZW50LgoKDAoFBAEDAQESA1UKGgqAAQoG
BAEDAQIAEgNYBD0acSBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgYSBmaWVsZCBlbGVtZW50LiBT
ZWUKIFtDb2x1bW5TY2hlbWEudHlwZV1bZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLkNv
bHVtblNjaGVtYS50eXBlXS4KCg4KBwQBAwECAAUSA1gECgoOCgcEAQMBAgABEgNYCw8KDgoH
BAEDAQIAAxIDWBITCg4KBwQBAwECAAgSA1gUPAoRCgoEAQMBAgAInAgAEgNYFTsKdgoEBAEC
ABIDXwI9GmkgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGNvbHVtbi4KCiBNdXN0IGJlIGEgVVRG
LTggc3RyaW5nIHdpdGhvdXQgZG90cyAoLikuCiBUaGUgbWF4aW11bSBzaXplIGlzIDY0IGJ5
dGVzLgoKDAoFBAECAAUSA18CCAoMCgUEAQIAARIDXwkPCgwKBQQBAgADEgNfEhMKDAoFBAEC
AAgSA18UPAoPCggEAQIACJwIABIDXxU7CmkKBAQBAgESA2QCOxpcIFJlcXVpcmVkLiBUeXBl
IG9mIHRoZSBjb2x1bW4uCgogTXVzdCBiZSBhIFVURi04IHN0cmluZyB3aXRoIHRoZSBtYXhp
bXVtIHNpemUgb2YgMTI4IGJ5dGVzLgoKDAoFBAECAQUSA2QCCAoMCgUEAQIBARIDZAkNCgwK
BQQBAgEDEgNkEBEKDAoFBAECAQgSA2QSOgoPCggEAQIBCJwIABIDZBM5CqUBCgQEAQICEgNq
AkIalwEgT3B0aW9uYWwuIERlc2NyaXB0aW9uIG9mIHRoZSBjb2x1bW4uIERlZmF1bHQgdmFs
dWUgaXMgYW4gZW1wdHkgc3RyaW5nLgoKIFRoZSBkZXNjcmlwdGlvbiBtdXN0IGJlIGEgVVRG
LTggc3RyaW5nIHdpdGggdGhlIG1heGltdW0gc2l6ZSBvZiAyMDAwCiBieXRlcy4KCgwKBQQB
AgIFEgNqAggKDAoFBAECAgESA2oJFAoMCgUEAQICAxIDahcYCgwKBQQBAgIIEgNqGUEKDwoI
BAECAgicCAASA2oaQArYAQoEBAECAxIDcQI7GsoBIE9wdGlvbmFsLiBBIGNvbHVtbidzIG1v
ZGUgaW5kaWNhdGVzIHdoZXRoZXIgdmFsdWVzIGluIHRoaXMgY29sdW1uIGFyZQogcmVxdWly
ZWQsIG51bGxhYmxlLCBvciByZXBlYXRlZC4KCiBPbmx5IGBOVUxMQUJMRWAsIGBSRVFVSVJF
RGAsIGFuZCBgUkVQRUFURURgIHZhbHVlcyBhcmUgc3VwcG9ydGVkLgogRGVmYXVsdCBtb2Rl
IGlzIGBOVUxMQUJMRWAuCgoMCgUEAQIDBRIDcQIICgwKBQQBAgMBEgNxCQ0KDAoFBAECAwMS
A3EQEQoMCgUEAQIDCBIDcRI6Cg8KCAQBAgMInAgAEgNxEzkKNgoEBAECBBIDdAJEGikgT3B0
aW9uYWwuIERlZmF1bHQgdmFsdWUgZm9yIHRoZSBjb2x1bW4uCgoMCgUEAQIEBRIDdAIICgwK
BQQBAgQBEgN0CRYKDAoFBAECBAMSA3QZGgoMCgUEAQIECBIDdBtDCg8KCAQBAgQInAgAEgN0
HEIKKQoEBAECBRIDdwJGGhwgT3B0aW9uYWwuIE9yZGluYWwgcG9zaXRpb24KCgwKBQQBAgUF
EgN3AgcKDAoFBAECBQESA3cIGAoMCgUEAQIFAxIDdxscCgwKBQQBAgUIEgN3HUUKDwoIBAEC
BQicCAASA3ceRApCCgQEAQIGEgR6AnsvGjQgT3B0aW9uYWwuIE1vc3QgaW1wb3J0YW50IGlu
Y2x1c2lvbiBvZiB0aGlzIGNvbHVtbi4KCgwKBQQBAgYGEgN6Ag4KDAoFBAECBgESA3oPJAoM
CgUEAQIGAxIDeicpCgwKBQQBAgYIEgN7Bi4KDwoIBAECBgicCAASA3sHLQpcCgQEAQIHEgN/
AlAaTyBPcHRpb25hbC4gU2NoZW1hIG9mIHN1Yi1jb2x1bW5zLiBBIGNvbHVtbiBjYW4gaGF2
ZSB6ZXJvIG9yIG1vcmUKIHN1Yi1jb2x1bW5zLgoKDAoFBAECBwQSA38CCgoMCgUEAQIHBhID
fwsXCgwKBQQBAgcBEgN/GCIKDAoFBAECBwMSA38lJgoMCgUEAQIHCBIDfydPCg8KCAQBAgcI
nAgAEgN/KE4KWgoEBAEIABIGggEChQEDGkogSW5mb3JtYXRpb24gb25seSBhcHBseWluZyBm
b3IgY29sdW1ucyBpbiBFbnRyaWVzIGZyb20gYSBzcGVjaWZpYyBzeXN0ZW0uCgoNCgUEAQgA
ARIEggEIEwo7CgQEAQIIEgSEAQQtGi0gTG9va2VyIHNwZWNpZmljIGNvbHVtbiBpbmZvIG9m
IHRoaXMgY29sdW1uLgoKDQoFBAECCAYSBIQBBBQKDQoFBAECCAESBIQBFScKDQoFBAECCAMS
BIQBKiwK6gEKBAQBAgkSBo0BAo4BLxrZASBPcHRpb25hbC4gVGhlIHN1YnR5cGUgb2YgdGhl
IFJBTkdFLCBpZiB0aGUgdHlwZSBvZiB0aGlzIGZpZWxkIGlzIFJBTkdFLiBJZgogdGhlIHR5
cGUgaXMgUkFOR0UsIHRoaXMgZmllbGQgaXMgcmVxdWlyZWQuIFBvc3NpYmxlIHZhbHVlcyBm
b3IgdGhlIGZpZWxkCiBlbGVtZW50IHR5cGUgb2YgYSBSQU5HRSBpbmNsdWRlOgogKiBEQVRF
CiAqIERBVEVUSU1FCiAqIFRJTUVTVEFNUAoKDQoFBAECCQYSBI0BAhIKDQoFBAECCQESBI0B
EyUKDQoFBAECCQMSBI0BKCoKDQoFBAECCQgSBI4BBi4KEAoIBAECCQicCAASBI4BBy0KfQoE
BAECChIEkgECPxpvIE9wdGlvbmFsLiBHYXJiYWdlIGNvbGxlY3Rpb24gcG9saWN5IGZvciB0
aGUgY29sdW1uIG9yIGNvbHVtbiBmYW1pbHkuCiBBcHBsaWVzIHRvIHN5c3RlbXMgbGlrZSBD
bG91ZCBCaWd0YWJsZS4KCg0KBQQBAgoFEgSSAQIICg0KBQQBAgoBEgSSAQkQCg0KBQQBAgoD
EgSSARMVCg0KBQQBAgoIEgSSARY+ChAKCAQBAgoInAgAEgSSARc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::Schema::Schema ===
    # Fields for Schema
    # Field: columns Type: 11 (.google.cloud.datacatalog.v1.ColumnSchema)

# === Message: Google::Cloud::Datacatalog::V1::Schema::ColumnSchema ===
    # Fields for ColumnSchema
    # Field: column Type: 9 ()
    # Field: type Type: 9 ()
    # Field: description Type: 9 ()
    # Field: mode Type: 9 ()
    # Field: default_value Type: 9 ()
    # Field: ordinal_position Type: 5 ()
    # Field: highest_indexing_type Type: 14 (.google.cloud.datacatalog.v1.ColumnSchema.IndexingType)
    # Field: subcolumns Type: 11 (.google.cloud.datacatalog.v1.ColumnSchema)
    # Field: looker_column_spec Type: 11 (.google.cloud.datacatalog.v1.ColumnSchema.LookerColumnSpec)
    # Field: range_element_type Type: 11 (.google.cloud.datacatalog.v1.ColumnSchema.FieldElementType)
    # Field: gc_rule Type: 9 ()

# Enum: ColumnSchema::IndexingType
our $ColumnSchema_INDEXING_TYPE_UNSPECIFIED = 0;
our $ColumnSchema_INDEXING_TYPE_NONE = 1;
our $ColumnSchema_INDEXING_TYPE_NON_UNIQUE = 2;
our $ColumnSchema_INDEXING_TYPE_UNIQUE = 3;
our $ColumnSchema_INDEXING_TYPE_PRIMARY_KEY = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::Schema - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::Schema;

    my $msg = Google::Cloud::Datacatalog::V1::Schema::Schema->new({
        columns => $columns,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::Schema::Schema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::Schema::Schema

Represents a schema, for example, a BigQuery, GoogleSQL, or Avro schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Schema::ColumnSchema>)

The unified GoogleSQL-like schema of columns.

The overall maximum number of columns and nested columns is 10,000.
The maximum nested depth is 15 levels.

=back

=head2 Google::Cloud::Datacatalog::V1::Schema::ColumnSchema

A column within a schema. Columns can be nested inside
other columns.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->column() >> / C<< $msg->column($value) >>

Type: C<String>

Required. Name of the column.

Must be a UTF-8 string without dots (.).
The maximum size is 64 bytes.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Required. Type of the column.

Must be a UTF-8 string with the maximum size of 128 bytes.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the column. Default value is an empty string.

The description must be a UTF-8 string with the maximum size of 2000
bytes.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

Optional. A column's mode indicates whether values in this column are
required, nullable, or repeated.

Only `NULLABLE`, `REQUIRED`, and `REPEATED` values are supported.
Default mode is `NULLABLE`.

=item * C<< $msg->default_value() >> / C<< $msg->default_value($value) >>

Type: C<String>

Optional. Default value for the column.

=item * C<< $msg->ordinal_position() >> / C<< $msg->ordinal_position($value) >>

Type: C<Int32>

Optional. Ordinal position

=item * C<< $msg->highest_indexing_type() >> / C<< $msg->highest_indexing_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::ColumnSchema::IndexingType>)

Optional. Most important inclusion of this column.

=item * C<< $msg->subcolumns() >> / C<< $msg->subcolumns($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Schema::ColumnSchema>)

Optional. Schema of sub-columns. A column can have zero or more
sub-columns.

=item * C<< $msg->looker_column_spec() >> / C<< $msg->looker_column_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::LookerColumnSpec>)

Looker specific column info of this column.

=item * C<< $msg->range_element_type() >> / C<< $msg->range_element_type($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::Schema::ColumnSchema::FieldElementType>)

Optional. The subtype of the RANGE, if the type of this field is RANGE. If
the type is RANGE, this field is required. Possible values for the field
element type of a RANGE include:
* DATE
* DATETIME
* TIMESTAMP

=item * C<< $msg->gc_rule() >> / C<< $msg->gc_rule($value) >>

Type: C<String>

Optional. Garbage collection policy for the column or column family.
Applies to systems like Cloud Bigtable.

=back

=head3 Enum: ColumnSchema::IndexingType

=over 4

=item * C<INDEXING_TYPE_UNSPECIFIED> => C<0>

=item * C<INDEXING_TYPE_NONE> => C<1>

=item * C<INDEXING_TYPE_NON_UNIQUE> => C<2>

=item * C<INDEXING_TYPE_UNIQUE> => C<3>

=item * C<INDEXING_TYPE_PRIMARY_KEY> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::Schema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
