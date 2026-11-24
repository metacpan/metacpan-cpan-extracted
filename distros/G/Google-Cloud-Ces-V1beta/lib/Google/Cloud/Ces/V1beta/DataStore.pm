package Google::Cloud::Ces::V1beta::DataStore;

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
Cihnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9kYXRhX3N0b3JlLnByb3RvEhdnb29nbGUuY2xv
dWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKPBgoJRGF0YVN0b3JlEhcKBG5hbWUYASABKAlC
A+BBAlIEbmFtZRJJCgR0eXBlGAIgASgOMjAuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuRGF0
YVN0b3JlLkRhdGFTdG9yZVR5cGVCA+BBA1IEdHlwZRJ4Chhkb2N1bWVudF9wcm9jZXNzaW5n
X21vZGUYBCABKA4yOS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5EYXRhU3RvcmUuRG9jdW1l
bnRQcm9jZXNzaW5nTW9kZUID4EEDUhZkb2N1bWVudFByb2Nlc3NpbmdNb2RlEiYKDGRpc3Bs
YXlfbmFtZRgFIAEoCUID4EEDUgtkaXNwbGF5TmFtZRJACgtjcmVhdGVfdGltZRgGIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJiChBjb25uZWN0
b3JfY29uZmlnGAcgASgLMjIuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuRGF0YVN0b3JlLkNv
bm5lY3RvckNvbmZpZ0ID4EEDUg9jb25uZWN0b3JDb25maWcaigEKD0Nvbm5lY3RvckNvbmZp
ZxIeCgpjb2xsZWN0aW9uGAEgASgJUgpjb2xsZWN0aW9uEjYKF2NvbGxlY3Rpb25fZGlzcGxh
eV9uYW1lGAIgASgJUhVjb2xsZWN0aW9uRGlzcGxheU5hbWUSHwoLZGF0YV9zb3VyY2UYAyAB
KAlSCmRhdGFTb3VyY2UiagoNRGF0YVN0b3JlVHlwZRIfChtEQVRBX1NUT1JFX1RZUEVfVU5T
UEVDSUZJRUQQABIOCgpQVUJMSUNfV0VCEAESEAoMVU5TVFJVQ1RVUkVEEAISBwoDRkFREAMS
DQoJQ09OTkVDVE9SEAQiXQoWRG9jdW1lbnRQcm9jZXNzaW5nTW9kZRIoCiRET0NVTUVOVF9Q
Uk9DRVNTSU5HX01PREVfVU5TUEVDSUZJRUQQABINCglET0NVTUVOVFMQARIKCgZDSFVOS1MQ
AkJeChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCDkRhdGFTdG9yZVByb3RvUAFaLWNs
b3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYkrwGQoGEgQOAGEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMS
ACkKCQoCAwESAxMAKQoICgEIEgMVAEQKCQoCCAsSAxUARAoICgEIEgMWACIKCQoCCAoSAxYA
IgoICgEIEgMXAC8KCQoCCAgSAxcALwoICgEIEgMYADQKCQoCCAESAxgANAo3CgIEABIEGwBh
ARorIEEgRGF0YVN0b3JlIHJlc291cmNlIGluIFZlcnRleCBBSSBTZWFyY2guCgoKCgMEAAES
AxsIEQpDCgQEAAMAEgQdAicDGjUgVGhlIGNvbm5lY3RvciBjb25maWcgZm9yIHRoZSBkYXRh
IHN0b3JlIGNvbm5lY3Rpb24uCgoMCgUEAAMAARIDHQoZCksKBgQAAwACABIDHwQaGjwgUmVz
b3VyY2UgbmFtZSBvZiB0aGUgY29sbGVjdGlvbiB0aGUgZGF0YSBzdG9yZSBiZWxvbmdzIHRv
LgoKDgoHBAADAAIABRIDHwQKCg4KBwQAAwACAAESAx8LFQoOCgcEAAMAAgADEgMfGBkKSgoG
BAADAAIBEgMiBCcaOyBEaXNwbGF5IG5hbWUgb2YgdGhlIGNvbGxlY3Rpb24gdGhlIGRhdGEg
c3RvcmUgYmVsb25ncyB0by4KCg4KBwQAAwACAQUSAyIECgoOCgcEAAMAAgEBEgMiCyIKDgoH
BAADAAIBAxIDIiUmCmcKBgQAAwACAhIDJgQbGlggVGhlIG5hbWUgb2YgdGhlIGRhdGEgc291
cmNlLgogRXhhbXBsZTogYHNhbGVzZm9yY2VgLCBgamlyYWAsIGBjb25mbHVlbmNlYCwgYGJp
Z3F1ZXJ5YC4KCg4KBwQAAwACAgUSAyYECgoOCgcEAAMAAgIBEgMmCxYKDgoHBAADAAICAxID
JhkaCisKBAQABAASBCoCOwMaHSBUaGUgdHlwZSBvZiB0aGUgZGF0YSBzdG9yZS4KCgwKBQQA
BAABEgMqBxQKhgEKBgQABAACABIDLQQkGncgTm90IHNwZWNpZmllZC4gVGhpcyB2YWx1ZSBp
bmRpY2F0ZXMgdGhhdCB0aGUgZGF0YSBzdG9yZSB0eXBlIGlzIG5vdAogc3BlY2lmaWVkLCBz
byBpdCB3aWxsIG5vdCBiZSB1c2VkIGR1cmluZyBzZWFyY2guCgoOCgcEAAQAAgABEgMtBB8K
DgoHBAAEAAIAAhIDLSIjCj8KBgQABAACARIDMAQTGjAgQSBkYXRhIHN0b3JlIHRoYXQgY29u
dGFpbnMgcHVibGljIHdlYiBjb250ZW50LgoKDgoHBAAEAAIBARIDMAQOCg4KBwQABAACAQIS
AzAREgpGCgYEAAQAAgISAzMEFRo3IEEgZGF0YSBzdG9yZSB0aGF0IGNvbnRhaW5zIHVuc3Ry
dWN0dXJlZCBwcml2YXRlIGRhdGEuCgoOCgcEAAQAAgIBEgMzBBAKDgoHBAAEAAICAhIDMxMU
CkgKBgQABAACAxIDNgQMGjkgQSBkYXRhIHN0b3JlIHRoYXQgY29udGFpbnMgc3RydWN0dXJl
ZCBkYXRhIHVzZWQgYXMgRkFRLgoKDgoHBAAEAAIDARIDNgQHCg4KBwQABAACAwISAzYKCwpd
CgYEAAQAAgQSAzoEEhpOIEEgZGF0YSBzdG9yZSB0aGF0IGlzIGEgY29ubmVjdG9yIHRvIGEg
Zmlyc3QtcGFydHkgb3IgYSB0aGlyZC1wYXJ0eQogc2VydmljZS4KCg4KBwQABAACBAESAzoE
DQoOCgcEAAQAAgQCEgM6EBEKPwoEBAAEARIEPgJHAxoxIFRoZSBkb2N1bWVudCBwcm9jZXNz
aW5nIG1vZGUgb2YgdGhlIGRhdGEgc3RvcmUuCgoMCgUEAAQBARIDPgcdCh8KBgQABAECABID
QAQtGhAgTm90IHNwZWNpZmllZC4KCg4KBwQABAECAAESA0AEKAoOCgcEAAQBAgACEgNAKywK
NgoGBAAEAQIBEgNDBBIaJyBEb2N1bWVudHMgYXJlIHByb2Nlc3NlZCBhcyBkb2N1bWVudHMu
CgoOCgcEAAQBAgEBEgNDBA0KDgoHBAAEAQIBAhIDQxARCjMKBgQABAECAhIDRgQPGiQgRG9j
dW1lbnRzIGFyZSBjb252ZXJ0ZWQgdG8gY2h1bmtzLgoKDgoHBAAEAQICARIDRgQKCg4KBwQA
BAECAgISA0YNDgqiAQoEBAACABIDTAI7GpQBIFJlcXVpcmVkLiBGdWxsIHJlc291cmNlIG5h
bWUgb2YgdGhlIERhdGFTdG9yZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMv
e2RhdGFTdG9yZX1gCgoMCgUEAAIABRIDTAIICgwKBQQAAgABEgNMCQ0KDAoFBAACAAMSA0wQ
EQoMCgUEAAIACBIDTBI6Cg8KCAQAAgAInAgAEgNMEzkKbAoEBAACARIDUAJFGl8gT3V0cHV0
IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSBkYXRhIHN0b3JlLiBUaGlzIGZpZWxkIGlzIHJlYWRv
bmx5IGFuZAogcG9wdWxhdGVkIGJ5IHRoZSBzZXJ2ZXIuCgoMCgUEAAIBBhIDUAIPCgwKBQQA
AgEBEgNQEBQKDAoFBAACAQMSA1AXGAoMCgUEAAIBCBIDUBlECg8KCAQAAgEInAgAEgNQGkMK
kAEKBAQAAgISBFQCVTIagQEgT3V0cHV0IG9ubHkuIFRoZSBkb2N1bWVudCBwcm9jZXNzaW5n
IG1vZGUgZm9yIHRoZSBkYXRhIHN0b3JlIGNvbm5lY3Rpb24uCiBPbmx5IHNldCBmb3IgUFVC
TElDX1dFQiBhbmQgVU5TVFJVQ1RVUkVEIGRhdGEgc3RvcmVzLgoKDAoFBAACAgYSA1QCGAoM
CgUEAAICARIDVBkxCgwKBQQAAgIDEgNUNDUKDAoFBAACAggSA1UGMQoPCggEAAICCJwIABID
VQcwCj8KBAQAAgMSA1gCRhoyIE91dHB1dCBvbmx5LiBUaGUgZGlzcGxheSBuYW1lIG9mIHRo
ZSBkYXRhIHN0b3JlLgoKDAoFBAACAwUSA1gCCAoMCgUEAAIDARIDWAkVCgwKBQQAAgMDEgNY
GBkKDAoFBAACAwgSA1gaRQoPCggEAAIDCJwIABIDWBtECkcKBAQAAgQSBFsCXDIaOSBPdXRw
dXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIGRhdGEgc3RvcmUgd2FzIGNyZWF0ZWQuCgoM
CgUEAAIEBhIDWwIbCgwKBQQAAgQBEgNbHCcKDAoFBAACBAMSA1sqKwoMCgUEAAIECBIDXAYx
Cg8KCAQAAgQInAgAEgNcBzAKUAoEBAACBRIEXwJgMhpCIE91dHB1dCBvbmx5LiBUaGUgY29u
bmVjdG9yIGNvbmZpZyBmb3IgdGhlIGRhdGEgc3RvcmUgY29ubmVjdGlvbi4KCgwKBQQAAgUG
EgNfAhEKDAoFBAACBQESA18SIgoMCgUEAAIFAxIDXyUmCgwKBQQAAgUIEgNgBjEKDwoIBAAC
BQicCAASA2AHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::DataStore::DataStore ===
    # Fields for DataStore
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.ces.v1beta.DataStore.DataStoreType)
    # Field: document_processing_mode Type: 14 (.google.cloud.ces.v1beta.DataStore.DocumentProcessingMode)
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: connector_config Type: 11 (.google.cloud.ces.v1beta.DataStore.ConnectorConfig)

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

Google::Cloud::Ces::V1beta::DataStore - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/data_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::DataStore;

    my $msg = Google::Cloud::Ces::V1beta::DataStore::DataStore->new({
        name => $name,
        type => $type,
        document_processing_mode => $document_processing_mode,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::DataStore::DataStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/data_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::DataStore::DataStore

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

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::DataStore::DataStoreType>)

Output only. The type of the data store. This field is readonly and
populated by the server.

=item * C<< $msg->document_processing_mode() >> / C<< $msg->document_processing_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::DataStore::DocumentProcessingMode>)

Output only. The document processing mode for the data store connection.
Only set for PUBLIC_WEB and UNSTRUCTURED data stores.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name of the data store.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the data store was created.

=item * C<< $msg->connector_config() >> / C<< $msg->connector_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::DataStore::DataStore::ConnectorConfig>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::DataStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
