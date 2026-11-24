package Google::Cloud::Datacatalog::V1::DataplexSpec;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Datacatalog::V1::Common };
    eval { require Google::Cloud::Datacatalog::V1::PhysicalSchema };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvZGF0YXBsZXhfc3BlYy5wcm90bxIbZ29v
Z2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxGihnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEv
Y29tbW9uLnByb3RvGjFnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvcGh5c2ljYWxfc2No
ZW1hLnByb3RvIsABCgxEYXRhcGxleFNwZWMSFAoFYXNzZXQYASABKAlSBWFzc2V0EkwKC2Rh
dGFfZm9ybWF0GAIgASgLMisuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlBoeXNpY2Fs
U2NoZW1hUgpkYXRhRm9ybWF0Ei0KEmNvbXByZXNzaW9uX2Zvcm1hdBgDIAEoCVIRY29tcHJl
c3Npb25Gb3JtYXQSHQoKcHJvamVjdF9pZBgEIAEoCVIJcHJvamVjdElkImUKE0RhdGFwbGV4
RmlsZXNldFNwZWMSTgoNZGF0YXBsZXhfc3BlYxgBIAEoCzIpLmdvb2dsZS5jbG91ZC5kYXRh
Y2F0YWxvZy52MS5EYXRhcGxleFNwZWNSDGRhdGFwbGV4U3BlYyLjAQoRRGF0YXBsZXhUYWJs
ZVNwZWMSWwoPZXh0ZXJuYWxfdGFibGVzGAEgAygLMjIuZ29vZ2xlLmNsb3VkLmRhdGFjYXRh
bG9nLnYxLkRhdGFwbGV4RXh0ZXJuYWxUYWJsZVIOZXh0ZXJuYWxUYWJsZXMSTgoNZGF0YXBs
ZXhfc3BlYxgCIAEoCzIpLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5EYXRhcGxleFNw
ZWNSDGRhdGFwbGV4U3BlYxIhCgx1c2VyX21hbmFnZWQYAyABKAhSC3VzZXJNYW5hZ2VkIvIB
ChVEYXRhcGxleEV4dGVybmFsVGFibGUSRQoGc3lzdGVtGAEgASgOMi0uZ29vZ2xlLmNsb3Vk
LmRhdGFjYXRhbG9nLnYxLkludGVncmF0ZWRTeXN0ZW1SBnN5c3RlbRIwChRmdWxseV9xdWFs
aWZpZWRfbmFtZRgcIAEoCVISZnVsbHlRdWFsaWZpZWROYW1lEjIKFWdvb2dsZV9jbG91ZF9y
ZXNvdXJjZRgDIAEoCVITZ29vZ2xlQ2xvdWRSZXNvdXJjZRIsChJkYXRhX2NhdGFsb2dfZW50
cnkYBCABKAlSEGRhdGFDYXRhbG9nRW50cnlC1gEKH2NvbS5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFCEURhdGFwbGV4U3BlY1Byb3RvUAFaQWNsb3VkLmdvb2dsZS5jb20vZ28vZGF0
YWNhdGFsb2cvYXBpdjEvZGF0YWNhdGFsb2dwYjtkYXRhY2F0YWxvZ3BiqgIbR29vZ2xlLkNs
b3VkLkRhdGFDYXRhbG9nLlYxygIbR29vZ2xlXENsb3VkXERhdGFDYXRhbG9nXFYx6gIeR29v
Z2xlOjpDbG91ZDo6RGF0YUNhdGFsb2c6OlYxSogXCgYSBA4AWAEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAMgoJCgIDARIDEwA7CggK
AQgSAxUAOAoJCgIIJRIDFQA4CggKAQgSAxYAWAoJCgIICxIDFgBYCggKAQgSAxcAIgoJCgII
ChIDFwAiCggKAQgSAxgAMgoJCgIICBIDGAAyCggKAQgSAxkAOAoJCgIIARIDGQA4CggKAQgS
AxoAOAoJCgIIKRIDGgA4CggKAQgSAxsANwoJCgIILRIDGwA3CiUKAgQAEgQeAC4BGhkgQ29t
bW9uIERhdGFwbGV4IGZpZWxkcy4KCgoKAwQAARIDHggUCrIBCgQEAAIAEgMiAhMapAEgRnVs
bHkgcXVhbGlmaWVkIHJlc291cmNlIG5hbWUgb2YgYW4gYXNzZXQgaW4gRGF0YXBsZXgsIHRv
IHdoaWNoIHRoZQogdW5kZXJseWluZyBkYXRhIHNvdXJjZSAoQ2xvdWQgU3RvcmFnZSBidWNr
ZXQgb3IgQmlnUXVlcnkgZGF0YXNldCkgb2YgdGhlCiBlbnRpdHkgaXMgYXR0YWNoZWQuCgoM
CgUEAAIABRIDIgIICgwKBQQAAgABEgMiCQ4KDAoFBAACAAMSAyIREgoiCgQEAAIBEgMlAiEa
FSBGb3JtYXQgb2YgdGhlIGRhdGEuCgoMCgUEAAIBBhIDJQIQCgwKBQQAAgEBEgMlERwKDAoF
BAACAQMSAyUfIApDCgQEAAICEgMoAiAaNiBDb21wcmVzc2lvbiBmb3JtYXQgb2YgdGhlIGRh
dGEsIGUuZy4sIHppcCwgZ3ppcCBldGMuCgoMCgUEAAICBRIDKAIICgwKBQQAAgIBEgMoCRsK
DAoFBAACAgMSAygeHwquAQoEBAACAxIDLQIYGqABIFByb2plY3QgSUQgb2YgdGhlIHVuZGVy
bHlpbmcgQ2xvdWQgU3RvcmFnZSBvciBCaWdRdWVyeSBkYXRhLiBOb3RlIHRoYXQKIHRoaXMg
bWF5IG5vdCBiZSB0aGUgc2FtZSBwcm9qZWN0IGFzIHRoZSBjb3JyZXNwb25kaW5nbHkgRGF0
YXBsZXggbGFrZSAvCiB6b25lIC8gYXNzZXQuCgoMCgUEAAIDBRIDLQIICgwKBQQAAgMBEgMt
CRMKDAoFBAACAwMSAy0WFwo5CgIEARIEMQA0ARotIEVudHJ5IHNwZWN5ZmljYXRpb24gZm9y
IGEgRGF0YXBsZXggZmlsZXNldC4KCgoKAwQBARIDMQgbCiYKBAQBAgASAzMCIRoZIENvbW1v
biBEYXRhcGxleCBmaWVsZHMuCgoMCgUEAQIABhIDMwIOCgwKBQQBAgABEgMzDxwKDAoFBAEC
AAMSAzMfIAo3CgIEAhIENwBDARorIEVudHJ5IHNwZWNpZmljYXRpb24gZm9yIGEgRGF0YXBs
ZXggdGFibGUuCgoKCgMEAgESAzcIGQqwAQoEBAICABIDPAI1GqIBIExpc3Qgb2YgZXh0ZXJu
YWwgdGFibGVzIHJlZ2lzdGVyZWQgYnkgRGF0YXBsZXggaW4gb3RoZXIgc3lzdGVtcyBiYXNl
ZCBvbgogdGhlIHNhbWUgdW5kZXJseWluZyBkYXRhLgoKIEV4dGVybmFsIHRhYmxlcyBhbGxv
dyB0byBxdWVyeSB0aGlzIGRhdGEgaW4gdGhvc2Ugc3lzdGVtcy4KCgwKBQQCAgAEEgM8AgoK
DAoFBAICAAYSAzwLIAoMCgUEAgIAARIDPCEwCgwKBQQCAgADEgM8MzQKJgoEBAICARIDPwIh
GhkgQ29tbW9uIERhdGFwbGV4IGZpZWxkcy4KCgwKBQQCAgEGEgM/Ag4KDAoFBAICAQESAz8P
HAoMCgUEAgIBAxIDPx8gCksKBAQCAgISA0ICGBo+IEluZGljYXRlcyBpZiB0aGUgdGFibGUg
c2NoZW1hIGlzIG1hbmFnZWQgYnkgdGhlIHVzZXIgb3Igbm90LgoKDAoFBAICAgUSA0ICBgoM
CgUEAgICARIDQgcTCgwKBQQCAgIDEgNCFhcKhAMKAgQDEgRMAFgBGvcCIEV4dGVybmFsIHRh
YmxlIHJlZ2lzdGVyZWQgYnkgRGF0YXBsZXguCiBEYXRhcGxleCBwdWJsaXNoZXMgZGF0YSBk
aXNjb3ZlcmVkIGZyb20gYW4gYXNzZXQgaW50byBtdWx0aXBsZSBvdGhlciBzeXN0ZW1zCiAo
QmlnUXVlcnksIERQTVMpIGluIGZvcm0gb2YgdGFibGVzLiBXZSBjYWxsIHRoZW0gImV4dGVy
bmFsIHRhYmxlcyIuIEV4dGVybmFsCiB0YWJsZXMgYXJlIGFsc28gc3luY2VkIGludG8gdGhl
IERhdGEgQ2F0YWxvZy4KIFRoaXMgbWVzc2FnZSBjb250YWlucyBwb2ludGVycyB0bwogdGhv
c2UgZXh0ZXJuYWwgdGFibGVzIChmdWxseSBxdWFsaWZpZWQgbmFtZSwgcmVzb3VyY2UgbmFt
ZSBldCBjZXRlcmEpIHdpdGhpbgogdGhlIERhdGEgQ2F0YWxvZy4KCgoKAwQDARIDTAgdCkEK
BAQDAgASA04CHho0IFNlcnZpY2UgaW4gd2hpY2ggdGhlIGV4dGVybmFsIHRhYmxlIGlzIHJl
Z2lzdGVyZWQuCgoMCgUEAwIABhIDTgISCgwKBQQDAgABEgNOExkKDAoFBAMCAAMSA04cHQpA
CgQEAwIBEgNRAiMaMyBGdWxseSBxdWFsaWZpZWQgbmFtZSAoRlFOKSBvZiB0aGUgZXh0ZXJu
YWwgdGFibGUuCgoMCgUEAwIBBRIDUQIICgwKBQQDAgEBEgNRCR0KDAoFBAMCAQMSA1EgIgpA
CgQEAwICEgNUAiMaMyBHb29nbGUgQ2xvdWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZXh0ZXJu
YWwgdGFibGUuCgoMCgUEAwICBRIDVAIICgwKBQQDAgIBEgNUCR4KDAoFBAMCAgMSA1QhIgpO
CgQEAwIDEgNXAiAaQSBOYW1lIG9mIHRoZSBEYXRhIENhdGFsb2cgZW50cnkgcmVwcmVzZW50
aW5nIHRoZSBleHRlcm5hbCB0YWJsZS4KCgwKBQQDAgMFEgNXAggKDAoFBAMCAwESA1cJGwoM
CgUEAwIDAxIDVx4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec ===
    # Fields for DataplexSpec
    # Field: asset Type: 9 ()
    # Field: data_format Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema)
    # Field: compression_format Type: 9 ()
    # Field: project_id Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexFilesetSpec ===
    # Fields for DataplexFilesetSpec
    # Field: dataplex_spec Type: 11 (.google.cloud.datacatalog.v1.DataplexSpec)

# === Message: Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexTableSpec ===
    # Fields for DataplexTableSpec
    # Field: external_tables Type: 11 (.google.cloud.datacatalog.v1.DataplexExternalTable)
    # Field: dataplex_spec Type: 11 (.google.cloud.datacatalog.v1.DataplexSpec)
    # Field: user_managed Type: 8 ()

# === Message: Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable ===
    # Fields for DataplexExternalTable
    # Field: system Type: 14 (.google.cloud.datacatalog.v1.IntegratedSystem)
    # Field: fully_qualified_name Type: 9 ()
    # Field: google_cloud_resource Type: 9 ()
    # Field: data_catalog_entry Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::DataplexSpec - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/dataplex_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::DataplexSpec;

    my $msg = Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec->new({
        asset => $asset,
        data_format => $data_format,
        compression_format => $compression_format,
        project_id => $project_id,
    });

    # Read or update a field
    my $val = $msg->asset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/dataplex_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec

Common Dataplex fields.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->asset() >> / C<< $msg->asset($value) >>

Type: C<String>

Fully qualified resource name of an asset in Dataplex, to which the
underlying data source (Cloud Storage bucket or BigQuery dataset) of the
entity is attached.

=item * C<< $msg->data_format() >> / C<< $msg->data_format($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema>)

Format of the data.

=item * C<< $msg->compression_format() >> / C<< $msg->compression_format($value) >>

Type: C<String>

Compression format of the data, e.g., zip, gzip etc.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Project ID of the underlying Cloud Storage or BigQuery data. Note that
this may not be the same project as the correspondingly Dataplex lake /
zone / asset.

=back

=head2 Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexFilesetSpec

Entry specyfication for a Dataplex fileset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataplex_spec() >> / C<< $msg->dataplex_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec>)

Common Dataplex fields.

=back

=head2 Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexTableSpec

Entry specification for a Dataplex table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->external_tables() >> / C<< $msg->external_tables($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable>)

List of external tables registered by Dataplex in other systems based on
the same underlying data.

External tables allow to query this data in those systems.

=item * C<< $msg->dataplex_spec() >> / C<< $msg->dataplex_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexSpec>)

Common Dataplex fields.

=item * C<< $msg->user_managed() >> / C<< $msg->user_managed($value) >>

Type: C<Bool>

Indicates if the table schema is managed by the user or not.

=back

=head2 Google::Cloud::Datacatalog::V1::DataplexSpec::DataplexExternalTable

External table registered by Dataplex.
Dataplex publishes data discovered from an asset into multiple other systems
(BigQuery, DPMS) in form of tables. We call them "external tables". External
tables are also synced into the Data Catalog.
This message contains pointers to
those external tables (fully qualified name, resource name et cetera) within
the Data Catalog.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->system() >> / C<< $msg->system($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::IntegratedSystem>)

Service in which the external table is registered.

=item * C<< $msg->fully_qualified_name() >> / C<< $msg->fully_qualified_name($value) >>

Type: C<String>

Fully qualified name (FQN) of the external table.

=item * C<< $msg->google_cloud_resource() >> / C<< $msg->google_cloud_resource($value) >>

Type: C<String>

Google Cloud resource name of the external table.

=item * C<< $msg->data_catalog_entry() >> / C<< $msg->data_catalog_entry($value) >>

Type: C<String>

Name of the Data Catalog entry representing the external table.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::DataplexSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
