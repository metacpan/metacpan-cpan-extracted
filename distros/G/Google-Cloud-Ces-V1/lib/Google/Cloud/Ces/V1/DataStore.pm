package Google::Cloud::Ces::V1::DataStore;

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
CiRnb29nbGUvY2xvdWQvY2VzL3YxL2RhdGFfc3RvcmUucHJvdG8SE2dvb2dsZS5jbG91ZC5j
ZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8igwYKCURhdGFTdG9yZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5h
bWUSRQoEdHlwZRgCIAEoDjIsLmdvb2dsZS5jbG91ZC5jZXMudjEuRGF0YVN0b3JlLkRhdGFT
dG9yZVR5cGVCA+BBA1IEdHlwZRJ0Chhkb2N1bWVudF9wcm9jZXNzaW5nX21vZGUYBCABKA4y
NS5nb29nbGUuY2xvdWQuY2VzLnYxLkRhdGFTdG9yZS5Eb2N1bWVudFByb2Nlc3NpbmdNb2Rl
QgPgQQNSFmRvY3VtZW50UHJvY2Vzc2luZ01vZGUSJgoMZGlzcGxheV9uYW1lGAUgASgJQgPg
QQNSC2Rpc3BsYXlOYW1lEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEl4KEGNvbm5lY3Rvcl9jb25maWcYByABKAsy
Li5nb29nbGUuY2xvdWQuY2VzLnYxLkRhdGFTdG9yZS5Db25uZWN0b3JDb25maWdCA+BBA1IP
Y29ubmVjdG9yQ29uZmlnGooBCg9Db25uZWN0b3JDb25maWcSHgoKY29sbGVjdGlvbhgBIAEo
CVIKY29sbGVjdGlvbhI2Chdjb2xsZWN0aW9uX2Rpc3BsYXlfbmFtZRgCIAEoCVIVY29sbGVj
dGlvbkRpc3BsYXlOYW1lEh8KC2RhdGFfc291cmNlGAMgASgJUgpkYXRhU291cmNlImoKDURh
dGFTdG9yZVR5cGUSHwobREFUQV9TVE9SRV9UWVBFX1VOU1BFQ0lGSUVEEAASDgoKUFVCTElD
X1dFQhABEhAKDFVOU1RSVUNUVVJFRBACEgcKA0ZBURADEg0KCUNPTk5FQ1RPUhAEIl0KFkRv
Y3VtZW50UHJvY2Vzc2luZ01vZGUSKAokRE9DVU1FTlRfUFJPQ0VTU0lOR19NT0RFX1VOU1BF
Q0lGSUVEEAASDQoJRE9DVU1FTlRTEAESCgoGQ0hVTktTEAJCVgoXY29tLmdvb2dsZS5jbG91
ZC5jZXMudjFCDkRhdGFTdG9yZVByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2Fw
aXYxL2Nlc3BiO2Nlc3BiSvAZCgYSBA4AYQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwApCggKAQgSAxUAQAoJCgII
CxIDFQBACggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAvCggKAQgS
AxgAMAoJCgIIARIDGAAwCjcKAgQAEgQbAGEBGisgQSBEYXRhU3RvcmUgcmVzb3VyY2UgaW4g
VmVydGV4IEFJIFNlYXJjaC4KCgoKAwQAARIDGwgRCkMKBAQAAwASBB0CJwMaNSBUaGUgY29u
bmVjdG9yIGNvbmZpZyBmb3IgdGhlIGRhdGEgc3RvcmUgY29ubmVjdGlvbi4KCgwKBQQAAwAB
EgMdChkKSwoGBAADAAIAEgMfBBoaPCBSZXNvdXJjZSBuYW1lIG9mIHRoZSBjb2xsZWN0aW9u
IHRoZSBkYXRhIHN0b3JlIGJlbG9uZ3MgdG8uCgoOCgcEAAMAAgAFEgMfBAoKDgoHBAADAAIA
ARIDHwsVCg4KBwQAAwACAAMSAx8YGQpKCgYEAAMAAgESAyIEJxo7IERpc3BsYXkgbmFtZSBv
ZiB0aGUgY29sbGVjdGlvbiB0aGUgZGF0YSBzdG9yZSBiZWxvbmdzIHRvLgoKDgoHBAADAAIB
BRIDIgQKCg4KBwQAAwACAQESAyILIgoOCgcEAAMAAgEDEgMiJSYKZwoGBAADAAICEgMmBBsa
WCBUaGUgbmFtZSBvZiB0aGUgZGF0YSBzb3VyY2UuCiBFeGFtcGxlOiBgc2FsZXNmb3JjZWAs
IGBqaXJhYCwgYGNvbmZsdWVuY2VgLCBgYmlncXVlcnlgLgoKDgoHBAADAAICBRIDJgQKCg4K
BwQAAwACAgESAyYLFgoOCgcEAAMAAgIDEgMmGRoKKwoEBAAEABIEKgI7AxodIFRoZSB0eXBl
IG9mIHRoZSBkYXRhIHN0b3JlLgoKDAoFBAAEAAESAyoHFAqGAQoGBAAEAAIAEgMtBCQadyBO
b3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIGluZGljYXRlcyB0aGF0IHRoZSBkYXRhIHN0b3Jl
IHR5cGUgaXMgbm90CiBzcGVjaWZpZWQsIHNvIGl0IHdpbGwgbm90IGJlIHVzZWQgZHVyaW5n
IHNlYXJjaC4KCg4KBwQABAACAAESAy0EHwoOCgcEAAQAAgACEgMtIiMKPwoGBAAEAAIBEgMw
BBMaMCBBIGRhdGEgc3RvcmUgdGhhdCBjb250YWlucyBwdWJsaWMgd2ViIGNvbnRlbnQuCgoO
CgcEAAQAAgEBEgMwBA4KDgoHBAAEAAIBAhIDMBESCkYKBgQABAACAhIDMwQVGjcgQSBkYXRh
IHN0b3JlIHRoYXQgY29udGFpbnMgdW5zdHJ1Y3R1cmVkIHByaXZhdGUgZGF0YS4KCg4KBwQA
BAACAgESAzMEEAoOCgcEAAQAAgICEgMzExQKSAoGBAAEAAIDEgM2BAwaOSBBIGRhdGEgc3Rv
cmUgdGhhdCBjb250YWlucyBzdHJ1Y3R1cmVkIGRhdGEgdXNlZCBhcyBGQVEuCgoOCgcEAAQA
AgMBEgM2BAcKDgoHBAAEAAIDAhIDNgoLCl0KBgQABAACBBIDOgQSGk4gQSBkYXRhIHN0b3Jl
IHRoYXQgaXMgYSBjb25uZWN0b3IgdG8gYSBmaXJzdC1wYXJ0eSBvciBhIHRoaXJkLXBhcnR5
CiBzZXJ2aWNlLgoKDgoHBAAEAAIEARIDOgQNCg4KBwQABAACBAISAzoQEQo/CgQEAAQBEgQ+
AkcDGjEgVGhlIGRvY3VtZW50IHByb2Nlc3NpbmcgbW9kZSBvZiB0aGUgZGF0YSBzdG9yZS4K
CgwKBQQABAEBEgM+Bx0KHwoGBAAEAQIAEgNABC0aECBOb3Qgc3BlY2lmaWVkLgoKDgoHBAAE
AQIAARIDQAQoCg4KBwQABAECAAISA0ArLAo2CgYEAAQBAgESA0MEEhonIERvY3VtZW50cyBh
cmUgcHJvY2Vzc2VkIGFzIGRvY3VtZW50cy4KCg4KBwQABAECAQESA0MEDQoOCgcEAAQBAgEC
EgNDEBEKMwoGBAAEAQICEgNGBA8aJCBEb2N1bWVudHMgYXJlIGNvbnZlcnRlZCB0byBjaHVu
a3MuCgoOCgcEAAQBAgIBEgNGBAoKDgoHBAAEAQICAhIDRg0OCqIBCgQEAAIAEgNMAjsalAEg
UmVxdWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRGF0YVN0b3JlLgogRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9u
cy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YVN0b3JlfWAKCgwKBQQAAgAFEgNMAggK
DAoFBAACAAESA0wJDQoMCgUEAAIAAxIDTBARCgwKBQQAAgAIEgNMEjoKDwoIBAACAAicCAAS
A0wTOQpsCgQEAAIBEgNQAkUaXyBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2YgdGhlIGRhdGEg
c3RvcmUuIFRoaXMgZmllbGQgaXMgcmVhZG9ubHkgYW5kCiBwb3B1bGF0ZWQgYnkgdGhlIHNl
cnZlci4KCgwKBQQAAgEGEgNQAg8KDAoFBAACAQESA1AQFAoMCgUEAAIBAxIDUBcYCgwKBQQA
AgEIEgNQGUQKDwoIBAACAQicCAASA1AaQwqQAQoEBAACAhIEVAJVMhqBASBPdXRwdXQgb25s
eS4gVGhlIGRvY3VtZW50IHByb2Nlc3NpbmcgbW9kZSBmb3IgdGhlIGRhdGEgc3RvcmUgY29u
bmVjdGlvbi4KIE9ubHkgc2V0IGZvciBQVUJMSUNfV0VCIGFuZCBVTlNUUlVDVFVSRUQgZGF0
YSBzdG9yZXMuCgoMCgUEAAICBhIDVAIYCgwKBQQAAgIBEgNUGTEKDAoFBAACAgMSA1Q0NQoM
CgUEAAICCBIDVQYxCg8KCAQAAgIInAgAEgNVBzAKPwoEBAACAxIDWAJGGjIgT3V0cHV0IG9u
bHkuIFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIGRhdGEgc3RvcmUuCgoMCgUEAAIDBRIDWAII
CgwKBQQAAgMBEgNYCRUKDAoFBAACAwMSA1gYGQoMCgUEAAIDCBIDWBpFCg8KCAQAAgMInAgA
EgNYG0QKRwoEBAACBBIEWwJcMho5IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUg
ZGF0YSBzdG9yZSB3YXMgY3JlYXRlZC4KCgwKBQQAAgQGEgNbAhsKDAoFBAACBAESA1scJwoM
CgUEAAIEAxIDWyorCgwKBQQAAgQIEgNcBjEKDwoIBAACBAicCAASA1wHMApQCgQEAAIFEgRf
AmAyGkIgT3V0cHV0IG9ubHkuIFRoZSBjb25uZWN0b3IgY29uZmlnIGZvciB0aGUgZGF0YSBz
dG9yZSBjb25uZWN0aW9uLgoKDAoFBAACBQYSA18CEQoMCgUEAAIFARIDXxIiCgwKBQQAAgUD
EgNfJSYKDAoFBAACBQgSA2AGMQoPCggEAAIFCJwIABIDYAcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::DataStore::DataStore ===
    # Fields for DataStore
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.ces.v1.DataStore.DataStoreType)
    # Field: document_processing_mode Type: 14 (.google.cloud.ces.v1.DataStore.DocumentProcessingMode)
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: connector_config Type: 11 (.google.cloud.ces.v1.DataStore.ConnectorConfig)

# Enum: DataStore::DataStoreType
our $DataStore_DATA_STORE_TYPE_UNSPECIFIED = 0;
our $DataStore_PUBLIC_WEB = 1;
our $DataStore_UNSTRUCTURED = 2;
our $DataStore_FAQ = 3;
our $DataStore_CONNECTOR = 4;

# Enum: DataStore::DocumentProcessingMode
our $DataStore_DOCUMENT_PROCESSING_MODE_UNSPECIFIED = 0;
our $DataStore_DOCUMENTS = 1;
our $DataStore_CHUNKS = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::DataStore - Compiled Protocol Buffers messages for google/cloud/ces/v1/data_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::DataStore;

    my $msg = Google::Cloud::Ces::V1::DataStore::DataStore->new({
        name => $name,
        type => $type,
        document_processing_mode => $document_processing_mode,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::DataStore::DataStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/data_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::DataStore::DataStore

A DataStore resource in Vertex AI Search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of the DataStore.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{dataStore}`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::DataStore::DataStoreType>)

Output only. The type of the data store. This field is readonly and
populated by the server.

=item * C<< $msg->document_processing_mode() >> / C<< $msg->document_processing_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::DataStore::DocumentProcessingMode>)

Output only. The document processing mode for the data store connection.
Only set for PUBLIC_WEB and UNSTRUCTURED data stores.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the data store.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the data store was created.

=item * C<< $msg->connector_config() >> / C<< $msg->connector_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::DataStore::DataStore::ConnectorConfig>)

Output only. The connector config for the data store connection.

=back

=head3 Enum: DataStore::DataStoreType

=over 4

=item * C<DATA_STORE_TYPE_UNSPECIFIED> => C<0>

=item * C<PUBLIC_WEB> => C<1>

=item * C<UNSTRUCTURED> => C<2>

=item * C<FAQ> => C<3>

=item * C<CONNECTOR> => C<4>

=back

=head3 Enum: DataStore::DocumentProcessingMode

=over 4

=item * C<DOCUMENT_PROCESSING_MODE_UNSPECIFIED> => C<0>

=item * C<DOCUMENTS> => C<1>

=item * C<CHUNKS> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::DataStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
