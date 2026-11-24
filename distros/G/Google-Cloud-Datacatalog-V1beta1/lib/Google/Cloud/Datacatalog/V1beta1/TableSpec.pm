package Google::Cloud::Datacatalog::V1beta1::TableSpec;

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
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjFiZXRhMS90YWJsZV9zcGVjLnByb3RvEiBn
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKdAgoRQmlnUXVlcnlUYWJs
ZVNwZWMSYgoRdGFibGVfc291cmNlX3R5cGUYASABKA4yMS5nb29nbGUuY2xvdWQuZGF0YWNh
dGFsb2cudjFiZXRhMS5UYWJsZVNvdXJjZVR5cGVCA+BBA1IPdGFibGVTb3VyY2VUeXBlEkkK
CXZpZXdfc3BlYxgCIAEoCzIqLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MWJldGExLlZp
ZXdTcGVjSABSCHZpZXdTcGVjEkwKCnRhYmxlX3NwZWMYAyABKAsyKy5nb29nbGUuY2xvdWQu
ZGF0YWNhdGFsb2cudjFiZXRhMS5UYWJsZVNwZWNIAFIJdGFibGVTcGVjQgsKCXR5cGVfc3Bl
YyIuCghWaWV3U3BlYxIiCgp2aWV3X3F1ZXJ5GAEgASgJQgPgQQNSCXZpZXdRdWVyeSJaCglU
YWJsZVNwZWMSTQoNZ3JvdXBlZF9lbnRyeRgBIAEoCUIo4EED+kEiCiBkYXRhY2F0YWxvZy5n
b29nbGVhcGlzLmNvbS9FbnRyeVIMZ3JvdXBlZEVudHJ5IqsBChdCaWdRdWVyeURhdGVTaGFy
ZGVkU3BlYxJCCgdkYXRhc2V0GAEgASgJQijgQQP6QSIKIGRhdGFjYXRhbG9nLmdvb2dsZWFw
aXMuY29tL0VudHJ5UgdkYXRhc2V0EiYKDHRhYmxlX3ByZWZpeBgCIAEoCUID4EEDUgt0YWJs
ZVByZWZpeBIkCgtzaGFyZF9jb3VudBgDIAEoA0ID4EEDUgpzaGFyZENvdW50KnsKD1RhYmxl
U291cmNlVHlwZRIhCh1UQUJMRV9TT1VSQ0VfVFlQRV9VTlNQRUNJRklFRBAAEhEKDUJJR1FV
RVJZX1ZJRVcQAhISCg5CSUdRVUVSWV9UQUJMRRAFEh4KGkJJR1FVRVJZX01BVEVSSUFMSVpF
RF9WSUVXEAdC3AEKJGNvbS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFiZXRhMVABWkZj
bG91ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRhbG9nL2FwaXYxYmV0YTEvZGF0YWNhdGFsb2dw
YjtkYXRhY2F0YWxvZ3BiqgIgR29vZ2xlLkNsb3VkLkRhdGFDYXRhbG9nLlYxQmV0YTHKAiBH
b29nbGVcQ2xvdWRcRGF0YUNhdGFsb2dcVjFiZXRhMeoCI0dvb2dsZTo6Q2xvdWQ6OkRhdGFD
YXRhbG9nOjpWMWJldGExSv8YCgYSBA4AaAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAPQoJCgII
JRIDFQA9CggKAQgSAxYAXQoJCgIICxIDFgBdCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgS
AxgAPQoJCgIIARIDGAA9CggKAQgSAxkAPQoJCgIIKRIDGQA9CggKAQgSAxoAPAoJCgIILRID
GgA8CikKAgQAEgQdACwBGh0gRGVzY3JpYmVzIGEgQmlnUXVlcnkgdGFibGUuCgoKCgMEAAES
Ax0IGQozCgQEAAIAEgQfAiAyGiUgT3V0cHV0IG9ubHkuIFRoZSB0YWJsZSBzb3VyY2UgdHlw
ZS4KCgwKBQQAAgAGEgMfAhEKDAoFBAACAAESAx8SIwoMCgUEAAIAAxIDHyYnCgwKBQQAAgAI
EgMgBjEKDwoIBAACAAicCAASAyAHMAocCgQEAAgAEgQjAisDGg4gT3V0cHV0IG9ubHkuCgoM
CgUEAAgAARIDIwgRCngKBAQAAgESAyYEGxprIFRhYmxlIHZpZXcgc3BlY2lmaWNhdGlvbi4g
VGhpcyBmaWVsZCBzaG91bGQgb25seSBiZSBwb3B1bGF0ZWQgaWYKIGB0YWJsZV9zb3VyY2Vf
dHlwZWAgaXMgYEJJR1FVRVJZX1ZJRVdgLgoKDAoFBAACAQYSAyYEDAoMCgUEAAIBARIDJg0W
CgwKBQQAAgEDEgMmGRoKeQoEBAACAhIDKgQdGmwgU3BlYyBvZiBhIEJpZ1F1ZXJ5IHRhYmxl
LiBUaGlzIGZpZWxkIHNob3VsZCBvbmx5IGJlIHBvcHVsYXRlZCBpZgogYHRhYmxlX3NvdXJj
ZV90eXBlYCBpcyBgQklHUVVFUllfVEFCTEVgLgoKDAoFBAACAgYSAyoEDQoMCgUEAAICARID
Kg4YCgwKBQQAAgIDEgMqGxwKIAoCBQASBC8AOwEaFCBUYWJsZSBzb3VyY2UgdHlwZS4KCgoK
AwUAARIDLwUUCiQKBAUAAgASAzECJBoXIERlZmF1bHQgdW5rbm93biB0eXBlLgoKDAoFBQAC
AAESAzECHwoMCgUFAAIAAhIDMSIjChoKBAUAAgESAzQCFBoNIFRhYmxlIHZpZXcuCgoMCgUF
AAIBARIDNAIPCgwKBQUAAgECEgM0EhMKJQoEBQACAhIDNwIVGhggQmlnUXVlcnkgbmF0aXZl
IHRhYmxlLgoKDAoFBQACAgESAzcCEAoMCgUFAAICAhIDNxMUCioKBAUAAgMSAzoCIRodIEJp
Z1F1ZXJ5IG1hdGVyaWFsaXplZCB2aWV3LgoKDAoFBQACAwESAzoCHAoMCgUFAAIDAhIDOh8g
CicKAgQBEgQ+AEEBGhsgVGFibGUgdmlldyBzcGVjaWZpY2F0aW9uLgoKCgoDBAEBEgM+CBAK
QgoEBAECABIDQAJEGjUgT3V0cHV0IG9ubHkuIFRoZSBxdWVyeSB0aGF0IGRlZmluZXMgdGhl
IHRhYmxlIHZpZXcuCgoMCgUEAQIABRIDQAIICgwKBQQBAgABEgNACRMKDAoFBAECAAMSA0AW
FwoMCgUEAQIACBIDQBhDCg8KCAQBAgAInAgAEgNAGUIKKQoCBAISBEQAUAEaHSBOb3JtYWwg
QmlnUXVlcnkgdGFibGUgc3BlYy4KCgoKAwQCARIDRAgRCtECCgQEAgIAEgRKAk8EGsICIE91
dHB1dCBvbmx5LiBJZiB0aGUgdGFibGUgaXMgYSBkYXRlZCBzaGFyZCwgaS5lLiwgd2l0aCBu
YW1lIHBhdHRlcm4KIGBbcHJlZml4XVlZWVlNTUREYCwgYGdyb3VwZWRfZW50cnlgIGlzIHRo
ZSBEYXRhIENhdGFsb2cgcmVzb3VyY2UgbmFtZSBvZgogdGhlIGRhdGUgc2hhcmRlZCBncm91
cGVkIGVudHJ5LCBmb3IgZXhhbXBsZSwKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZW50cnlncm91cHMve2VudHJ5X2dyb3VwX2lkfS9lbnRyaWVzL3tl
bnRyeV9pZH1gLgogT3RoZXJ3aXNlLCBgZ3JvdXBlZF9lbnRyeWAgaXMgZW1wdHkuCgoMCgUE
AgIABRIDSgIICgwKBQQCAgABEgNKCRYKDAoFBAICAAMSA0oZGgoNCgUEAgIACBIEShtPAwoP
CggEAgIACJwIABIDSwQtCg8KBwQCAgAInwgSBEwETgUKugEKAgQDEgRVAGgBGq0BIFNwZWMg
Zm9yIGEgZ3JvdXAgb2YgQmlnUXVlcnkgdGFibGVzIHdpdGggbmFtZSBwYXR0ZXJuIGBbcHJl
Zml4XVlZWVlNTUREYC4KIENvbnRleHQ6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmln
cXVlcnkvZG9jcy9wYXJ0aXRpb25lZC10YWJsZXMjcGFydGl0aW9uaW5nX3ZlcnN1c19zaGFy
ZGluZwoKCgoDBAMBEgNVCB8K3AEKBAQDAgASBFkCXgQazQEgT3V0cHV0IG9ubHkuIFRoZSBE
YXRhIENhdGFsb2cgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0YXNldCBlbnRyeSB0aGUKIGN1
cnJlbnQgdGFibGUgYmVsb25ncyB0bywgZm9yIGV4YW1wbGUsCiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2VudHJ5Z3JvdXBzL3tlbnRyeV9ncm91cF9p
ZH0vZW50cmllcy97ZW50cnlfaWR9YC4KCgwKBQQDAgAFEgNZAggKDAoFBAMCAAESA1kJEAoM
CgUEAwIAAxIDWRMUCg0KBQQDAgAIEgRZFV4DCg8KCAQDAgAInAgAEgNaBC0KDwoHBAMCAAif
CBIEWwRdBQrIAQoEBAMCARIDZAJGGroBIE91dHB1dCBvbmx5LiBUaGUgdGFibGUgbmFtZSBw
cmVmaXggb2YgdGhlIHNoYXJkcy4gVGhlIG5hbWUgb2YgYW55IGdpdmVuCiBzaGFyZCBpcwog
YFt0YWJsZV9wcmVmaXhdWVlZWU1NRERgLCBmb3IgZXhhbXBsZSwgZm9yIHNoYXJkIGBNeVRh
YmxlMjAxODAxMDFgLCB0aGUKIGB0YWJsZV9wcmVmaXhgIGlzIGBNeVRhYmxlYC4KCgwKBQQD
AgEFEgNkAggKDAoFBAMCAQESA2QJFQoMCgUEAwIBAxIDZBgZCgwKBQQDAgEIEgNkGkUKDwoI
BAMCAQicCAASA2QbRAozCgQEAwICEgNnAkQaJiBPdXRwdXQgb25seS4gVG90YWwgbnVtYmVy
IG9mIHNoYXJkcy4KCgwKBQQDAgIFEgNnAgcKDAoFBAMCAgESA2cIEwoMCgUEAwICAxIDZxYX
CgwKBQQDAgIIEgNnGEMKDwoIBAMCAgicCAASA2cZQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryTableSpec ===
    # Fields for BigQueryTableSpec
    # Field: table_source_type Type: 14 (.google.cloud.datacatalog.v1beta1.TableSourceType)
    # Field: view_spec Type: 11 (.google.cloud.datacatalog.v1beta1.ViewSpec)
    # Field: table_spec Type: 11 (.google.cloud.datacatalog.v1beta1.TableSpec)

# === Message: Google::Cloud::Datacatalog::V1beta1::TableSpec::ViewSpec ===
    # Fields for ViewSpec
    # Field: view_query Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::TableSpec::TableSpec ===
    # Fields for TableSpec
    # Field: grouped_entry Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryDateShardedSpec ===
    # Fields for BigQueryDateShardedSpec
    # Field: dataset Type: 9 ()
    # Field: table_prefix Type: 9 ()
    # Field: shard_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::TableSpec - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1beta1/table_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1beta1::TableSpec;

    my $msg = Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryTableSpec->new({
        table_source_type => $table_source_type,
        view_spec => $view_spec,
        table_spec => $table_spec,
    });

    # Read or update a field
    my $val = $msg->table_source_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryTableSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1beta1/table_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryTableSpec

Describes a BigQuery table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->table_source_type() >> / C<< $msg->table_source_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1beta1::TableSourceType>)

Output only. The table source type.

=item * C<< $msg->view_spec() >> / C<< $msg->view_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::TableSpec::ViewSpec>)

Table view specification. This field should only be populated if
`table_source_type` is `BIGQUERY_VIEW`.

=item * C<< $msg->table_spec() >> / C<< $msg->table_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1beta1::TableSpec::TableSpec>)

Spec of a BigQuery table. This field should only be populated if
`table_source_type` is `BIGQUERY_TABLE`.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::TableSpec::ViewSpec

Table view specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->view_query() >> / C<< $msg->view_query($value) >>

Type: C<String>

Output only. The query that defines the table view.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::TableSpec::TableSpec

Normal BigQuery table spec.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grouped_entry() >> / C<< $msg->grouped_entry($value) >>

Type: C<String>

Output only. If the table is a dated shard, i.e., with name pattern
`[prefix]YYYYMMDD`, `grouped_entry` is the Data Catalog resource name of
the date sharded grouped entry, for example,
`projects/{project_id}/locations/{location}/entrygroups/{entry_group_id}/entries/{entry_id}`.
Otherwise, `grouped_entry` is empty.

=back

=head2 Google::Cloud::Datacatalog::V1beta1::TableSpec::BigQueryDateShardedSpec

Spec for a group of BigQuery tables with name pattern `[prefix]YYYYMMDD`.
Context:
https://cloud.google.com/bigquery/docs/partitioned-tables#partitioning_versus_sharding

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Output only. The Data Catalog resource name of the dataset entry the
current table belongs to, for example,
`projects/{project_id}/locations/{location}/entrygroups/{entry_group_id}/entries/{entry_id}`.

=item * C<< $msg->table_prefix() >> / C<< $msg->table_prefix($value) >>

Type: C<String>

Output only. The table name prefix of the shards. The name of any given
shard is
`[table_prefix]YYYYMMDD`, for example, for shard `MyTable20180101`, the
`table_prefix` is `MyTable`.

=item * C<< $msg->shard_count() >> / C<< $msg->shard_count($value) >>

Type: C<Int64>

Output only. Total number of shards.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1beta1::TableSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
