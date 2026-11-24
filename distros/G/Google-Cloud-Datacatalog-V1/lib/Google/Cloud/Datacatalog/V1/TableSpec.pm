package Google::Cloud::Datacatalog::V1::TableSpec;

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
Cixnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvdGFibGVfc3BlYy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmRhdGFjYXRhbG9nLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIo4CChFCaWdRdWVyeVRhYmxlU3BlYxJdChF0
YWJsZV9zb3VyY2VfdHlwZRgBIAEoDjIsLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5U
YWJsZVNvdXJjZVR5cGVCA+BBA1IPdGFibGVTb3VyY2VUeXBlEkQKCXZpZXdfc3BlYxgCIAEo
CzIlLmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5WaWV3U3BlY0gAUgh2aWV3U3BlYxJH
Cgp0YWJsZV9zcGVjGAMgASgLMiYuZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlRhYmxl
U3BlY0gAUgl0YWJsZVNwZWNCCwoJdHlwZV9zcGVjIi4KCFZpZXdTcGVjEiIKCnZpZXdfcXVl
cnkYASABKAlCA+BBA1IJdmlld1F1ZXJ5IloKCVRhYmxlU3BlYxJNCg1ncm91cGVkX2VudHJ5
GAEgASgJQijgQQP6QSIKIGRhdGFjYXRhbG9nLmdvb2dsZWFwaXMuY29tL0VudHJ5Ugxncm91
cGVkRW50cnki5AEKF0JpZ1F1ZXJ5RGF0ZVNoYXJkZWRTcGVjEkIKB2RhdGFzZXQYASABKAlC
KOBBA/pBIgogZGF0YWNhdGFsb2cuZ29vZ2xlYXBpcy5jb20vRW50cnlSB2RhdGFzZXQSJgoM
dGFibGVfcHJlZml4GAIgASgJQgPgQQNSC3RhYmxlUHJlZml4EiQKC3NoYXJkX2NvdW50GAMg
ASgDQgPgQQNSCnNoYXJkQ291bnQSNwoVbGF0ZXN0X3NoYXJkX3Jlc291cmNlGAQgASgJQgPg
QQNSE2xhdGVzdFNoYXJkUmVzb3VyY2UqewoPVGFibGVTb3VyY2VUeXBlEiEKHVRBQkxFX1NP
VVJDRV9UWVBFX1VOU1BFQ0lGSUVEEAASEQoNQklHUVVFUllfVklFVxACEhIKDkJJR1FVRVJZ
X1RBQkxFEAUSHgoaQklHUVVFUllfTUFURVJJQUxJWkVEX1ZJRVcQB0LDAQofY29tLmdvb2ds
ZS5jbG91ZC5kYXRhY2F0YWxvZy52MVABWkFjbG91ZC5nb29nbGUuY29tL2dvL2RhdGFjYXRh
bG9nL2FwaXYxL2RhdGFjYXRhbG9ncGI7ZGF0YWNhdGFsb2dwYqoCG0dvb2dsZS5DbG91ZC5E
YXRhQ2F0YWxvZy5WMcoCG0dvb2dsZVxDbG91ZFxEYXRhQ2F0YWxvZ1xWMeoCHkdvb2dsZTo6
Q2xvdWQ6OkRhdGFDYXRhbG9nOjpWMUrYGgoGEgQOAHEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMV
ADgKCQoCCCUSAxUAOAoICgEIEgMWAFgKCQoCCAsSAxYAWAoICgEIEgMXACIKCQoCCAoSAxcA
IgoICgEIEgMYADgKCQoCCAESAxgAOAoICgEIEgMZADgKCQoCCCkSAxkAOAoICgEIEgMaADcK
CQoCCC0SAxoANwopCgIEABIEHQAsARodIERlc2NyaWJlcyBhIEJpZ1F1ZXJ5IHRhYmxlLgoK
CgoDBAABEgMdCBkKMwoEBAACABIEHwIgMholIE91dHB1dCBvbmx5LiBUaGUgdGFibGUgc291
cmNlIHR5cGUuCgoMCgUEAAIABhIDHwIRCgwKBQQAAgABEgMfEiMKDAoFBAACAAMSAx8mJwoM
CgUEAAIACBIDIAYxCg8KCAQAAgAInAgAEgMgBzAKHAoEBAAIABIEIwIrAxoOIE91dHB1dCBv
bmx5LgoKDAoFBAAIAAESAyMIEQpnCgQEAAIBEgMmBBsaWiBUYWJsZSB2aWV3IHNwZWNpZmlj
YXRpb24uIFBvcHVsYXRlZCBvbmx5IGlmCiB0aGUgYHRhYmxlX3NvdXJjZV90eXBlYCBpcyBg
QklHUVVFUllfVklFV2AuCgoMCgUEAAIBBhIDJgQMCgwKBQQAAgEBEgMmDRYKDAoFBAACAQMS
AyYZGgpxCgQEAAICEgMqBB0aZCBTcGVjaWZpY2F0aW9uIG9mIGEgQmlnUXVlcnkgdGFibGUu
IFBvcHVsYXRlZCBvbmx5IGlmCiB0aGUgYHRhYmxlX3NvdXJjZV90eXBlYCBpcyBgQklHUVVF
UllfVEFCTEVgLgoKDAoFBAACAgYSAyoEDQoMCgUEAAICARIDKg4YCgwKBQQAAgIDEgMqGxwK
IAoCBQASBC8AOwEaFCBUYWJsZSBzb3VyY2UgdHlwZS4KCgoKAwUAARIDLwUUCiQKBAUAAgAS
AzECJBoXIERlZmF1bHQgdW5rbm93biB0eXBlLgoKDAoFBQACAAESAzECHwoMCgUFAAIAAhID
MSIjChoKBAUAAgESAzQCFBoNIFRhYmxlIHZpZXcuCgoMCgUFAAIBARIDNAIPCgwKBQUAAgEC
EgM0EhMKJQoEBQACAhIDNwIVGhggQmlnUXVlcnkgbmF0aXZlIHRhYmxlLgoKDAoFBQACAgES
AzcCEAoMCgUFAAICAhIDNxMUCioKBAUAAgMSAzoCIRodIEJpZ1F1ZXJ5IG1hdGVyaWFsaXpl
ZCB2aWV3LgoKDAoFBQACAwESAzoCHAoMCgUFAAIDAhIDOh8gCicKAgQBEgQ+AEEBGhsgVGFi
bGUgdmlldyBzcGVjaWZpY2F0aW9uLgoKCgoDBAEBEgM+CBAKQgoEBAECABIDQAJEGjUgT3V0
cHV0IG9ubHkuIFRoZSBxdWVyeSB0aGF0IGRlZmluZXMgdGhlIHRhYmxlIHZpZXcuCgoMCgUE
AQIABRIDQAIICgwKBQQBAgABEgNACRMKDAoFBAECAAMSA0AWFwoMCgUEAQIACBIDQBhDCg8K
CAQBAgAInAgAEgNAGUIKMgoCBAISBEQAUgEaJiBOb3JtYWwgQmlnUXVlcnkgdGFibGUgc3Bl
Y2lmaWNhdGlvbi4KCgoKAwQCARIDRAgRCtoCCgQEAgIAEgRMAlEEGssCIE91dHB1dCBvbmx5
LiBJZiB0aGUgdGFibGUgaXMgZGF0ZS1zaGFyZGVkLCB0aGF0IGlzLCBpdCBtYXRjaGVzIHRo
ZQogYFtwcmVmaXhdWVlZWU1NRERgIG5hbWUgcGF0dGVybiwgdGhpcyBmaWVsZCBpcyB0aGUg
RGF0YSBDYXRhbG9nIHJlc291cmNlCiBuYW1lIG9mIHRoZSBkYXRlLXNoYXJkZWQgZ3JvdXBl
ZCBlbnRyeS4gRm9yIGV4YW1wbGU6CgogYHByb2plY3RzL3tQUk9KRUNUX0lEfS9sb2NhdGlv
bnMve0xPQ0FUSU9OfS9lbnRyeWdyb3Vwcy97RU5UUllfR1JPVVBfSUR9L2VudHJpZXMve0VO
VFJZX0lEfWAuCgogT3RoZXJ3aXNlLCBgZ3JvdXBlZF9lbnRyeWAgaXMgZW1wdHkuCgoMCgUE
AgIABRIDTAIICgwKBQQCAgABEgNMCRYKDAoFBAICAAMSA0wZGgoNCgUEAgIACBIETBtRAwoP
CggEAgIACJwIABIDTQQtCg8KBwQCAgAInwgSBE4EUAUKggIKAgQDEgRZAHEBGvUBIFNwZWNp
ZmljYXRpb24gZm9yIGEgZ3JvdXAgb2YgQmlnUXVlcnkgdGFibGVzIHdpdGggdGhlIGBbcHJl
Zml4XVlZWVlNTUREYCBuYW1lCiBwYXR0ZXJuLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBz
ZWUgW0ludHJvZHVjdGlvbiB0byBwYXJ0aXRpb25lZCB0YWJsZXNdCiAoaHR0cHM6Ly9jbG91
ZC5nb29nbGUuY29tL2JpZ3F1ZXJ5L2RvY3MvcGFydGl0aW9uZWQtdGFibGVzI3BhcnRpdGlv
bmluZ192ZXJzdXNfc2hhcmRpbmcpLgoKCgoDBAMBEgNZCB8K3QEKBAQDAgASBF4CYwQazgEg
T3V0cHV0IG9ubHkuIFRoZSBEYXRhIENhdGFsb2cgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0
YXNldCBlbnRyeSB0aGUKIGN1cnJlbnQgdGFibGUgYmVsb25ncyB0by4gRm9yIGV4YW1wbGU6
CgogYHByb2plY3RzL3tQUk9KRUNUX0lEfS9sb2NhdGlvbnMve0xPQ0FUSU9OfS9lbnRyeWdy
b3Vwcy97RU5UUllfR1JPVVBfSUR9L2VudHJpZXMve0VOVFJZX0lEfWAuCgoMCgUEAwIABRID
XgIICgwKBQQDAgABEgNeCRAKDAoFBAMCAAMSA14TFAoNCgUEAwIACBIEXhVjAwoPCggEAwIA
CJwIABIDXwQtCg8KBwQDAgAInwgSBGAEYgUKzQEKBAQDAgESA2oCRhq/ASBPdXRwdXQgb25s
eS4gVGhlIHRhYmxlIG5hbWUgcHJlZml4IG9mIHRoZSBzaGFyZHMuCgogVGhlIG5hbWUgb2Yg
YW55IGdpdmVuIHNoYXJkIGlzIGBbdGFibGVfcHJlZml4XVlZWVlNTUREYC4KIEZvciBleGFt
cGxlLCBmb3IgdGhlIGBNeVRhYmxlMjAxODAxMDFgIHNoYXJkLCB0aGUKIGB0YWJsZV9wcmVm
aXhgIGlzIGBNeVRhYmxlYC4KCgwKBQQDAgEFEgNqAggKDAoFBAMCAQESA2oJFQoMCgUEAwIB
AxIDahgZCgwKBQQDAgEIEgNqGkUKDwoIBAMCAQicCAASA2obRAozCgQEAwICEgNtAkQaJiBP
dXRwdXQgb25seS4gVG90YWwgbnVtYmVyIG9mIHNoYXJkcy4KCgwKBQQDAgIFEgNtAgcKDAoF
BAMCAgESA20IEwoMCgUEAwICAxIDbRYXCgwKBQQDAgIIEgNtGEMKDwoIBAMCAgicCAASA20Z
QgpHCgQEAwIDEgNwAk8aOiBPdXRwdXQgb25seS4gQmlnUXVlcnkgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgbGF0ZXN0IHNoYXJkLgoKDAoFBAMCAwUSA3ACCAoMCgUEAwIDARIDcAkeCgwKBQQD
AgMDEgNwISIKDAoFBAMCAwgSA3AjTgoPCggEAwIDCJwIABIDcCRNYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec ===
    # Fields for BigQueryTableSpec
    # Field: table_source_type Type: 14 (.google.cloud.datacatalog.v1.TableSourceType)
    # Field: view_spec Type: 11 (.google.cloud.datacatalog.v1.ViewSpec)
    # Field: table_spec Type: 11 (.google.cloud.datacatalog.v1.TableSpec)

# === Message: Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec ===
    # Fields for ViewSpec
    # Field: view_query Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::TableSpec::TableSpec ===
    # Fields for TableSpec
    # Field: grouped_entry Type: 9 ()

# === Message: Google::Cloud::Datacatalog::V1::TableSpec::BigQueryDateShardedSpec ===
    # Fields for BigQueryDateShardedSpec
    # Field: dataset Type: 9 ()
    # Field: table_prefix Type: 9 ()
    # Field: shard_count Type: 3 ()
    # Field: latest_shard_resource Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::TableSpec - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/table_spec.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::TableSpec;

    my $msg = Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec->new({
        table_source_type => $table_source_type,
        view_spec => $view_spec,
        table_spec => $table_spec,
    });

    # Read or update a field
    my $val = $msg->table_source_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/table_spec.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec

Describes a BigQuery table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->table_source_type() >> / C<< $msg->table_source_type($value) >>

Type: C<Enum> (L<Google::Cloud::Datacatalog::V1::TableSourceType>)

Output only. The table source type.

=item * C<< $msg->view_spec() >> / C<< $msg->view_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec>)

Table view specification. Populated only if
the `table_source_type` is `BIGQUERY_VIEW`.

=item * C<< $msg->table_spec() >> / C<< $msg->table_spec($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::TableSpec::TableSpec>)

Specification of a BigQuery table. Populated only if
the `table_source_type` is `BIGQUERY_TABLE`.

=back

=head2 Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec

Table view specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->view_query() >> / C<< $msg->view_query($value) >>

Type: C<String>

Output only. The query that defines the table view.

=back

=head2 Google::Cloud::Datacatalog::V1::TableSpec::TableSpec

Normal BigQuery table specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grouped_entry() >> / C<< $msg->grouped_entry($value) >>

Type: C<String>

Output only. If the table is date-sharded, that is, it matches the
`[prefix]YYYYMMDD` name pattern, this field is the Data Catalog resource
name of the date-sharded grouped entry. For example:

`projects/{PROJECT_ID}/locations/{LOCATION}/entrygroups/{ENTRY_GROUP_ID}/entries/{ENTRY_ID}`.

Otherwise, `grouped_entry` is empty.

=back

=head2 Google::Cloud::Datacatalog::V1::TableSpec::BigQueryDateShardedSpec

Specification for a group of BigQuery tables with the `[prefix]YYYYMMDD` name
pattern.

For more information, see [Introduction to partitioned tables]
(https://cloud.google.com/bigquery/docs/partitioned-tables#partitioning_versus_sharding).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Output only. The Data Catalog resource name of the dataset entry the
current table belongs to. For example:

`projects/{PROJECT_ID}/locations/{LOCATION}/entrygroups/{ENTRY_GROUP_ID}/entries/{ENTRY_ID}`.

=item * C<< $msg->table_prefix() >> / C<< $msg->table_prefix($value) >>

Type: C<String>

Output only. The table name prefix of the shards.

The name of any given shard is `[table_prefix]YYYYMMDD`.
For example, for the `MyTable20180101` shard, the
`table_prefix` is `MyTable`.

=item * C<< $msg->shard_count() >> / C<< $msg->shard_count($value) >>

Type: C<Int64>

Output only. Total number of shards.

=item * C<< $msg->latest_shard_resource() >> / C<< $msg->latest_shard_resource($value) >>

Type: C<String>

Output only. BigQuery resource name of the latest shard.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::TableSpec::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
