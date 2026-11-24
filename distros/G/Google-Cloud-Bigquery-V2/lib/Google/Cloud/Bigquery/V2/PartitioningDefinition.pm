package Google::Cloud::Bigquery::V2::PartitioningDefinition;

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
CjZnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcGFydGl0aW9uaW5nX2RlZmluaXRpb24ucHJv
dG8SGGdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90byJ5ChZQYXJ0aXRpb25pbmdEZWZpbml0aW9uEl8KEnBhcnRpdGlvbmVkX2NvbHVt
bhgBIAMoCzIrLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5QYXJ0aXRpb25lZENvbHVtbkID
4EEBUhFwYXJ0aXRpb25lZENvbHVtbiI9ChFQYXJ0aXRpb25lZENvbHVtbhIeCgVmaWVsZBgB
IAEoCUID4EECSABSBWZpZWxkiAEBQggKBl9maWVsZEJ6Chxjb20uZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5LnYyQhtQYXJ0aXRpb25pbmdEZWZpbml0aW9uUHJvdG9QAVo7Y2xvdWQuZ29vZ2xl
LmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGJK5A0KBhIE
DgAwAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgID
ABIDEgApCggKAQgSAxQAUgoJCgIICxIDFABSCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgS
AxYAPAoJCgIICBIDFgA8CggKAQgSAxcANQoJCgIIARIDFwA1CpEBCgIEABIEGwAqARqEASBU
aGUgcGFydGl0aW9uaW5nIGluZm9ybWF0aW9uLCB3aGljaCBpbmNsdWRlcyBtYW5hZ2VkIHRh
YmxlLCBleHRlcm5hbCB0YWJsZQogYW5kIG1ldGFzdG9yZSBwYXJ0aXRpb25lZCB0YWJsZSBw
YXJ0aXRpb24gaW5mb3JtYXRpb24uCgoKCgMEAAESAxsIHgrnBAoEBAACABIEKAIpLxrYBCBP
cHRpb25hbC4gRGV0YWlscyBhYm91dCBlYWNoIHBhcnRpdGlvbmluZyBjb2x1bW4uIFRoaXMg
ZmllbGQgaXMgb3V0cHV0IG9ubHkKIGZvciBhbGwgcGFydGl0aW9uaW5nIHR5cGVzIG90aGVy
IHRoYW4gbWV0YXN0b3JlIHBhcnRpdGlvbmVkIHRhYmxlcy4KIEJpZ1F1ZXJ5IG5hdGl2ZSB0
YWJsZXMgb25seSBzdXBwb3J0IDEgcGFydGl0aW9uaW5nIGNvbHVtbi4gT3RoZXIgdGFibGUK
IHR5cGVzIG1heSBzdXBwb3J0IDAsIDEgb3IgbW9yZSBwYXJ0aXRpb25pbmcgY29sdW1ucy4K
IEZvciBtZXRhc3RvcmUgcGFydGl0aW9uZWQgdGFibGVzLCB0aGUgb3JkZXIgbXVzdCBtYXRj
aCB0aGUgZGVmaW5pdGlvbiBvcmRlcgogaW4gdGhlIEhpdmUgTWV0YXN0b3JlLCB3aGVyZSBp
dCBtdXN0IG1hdGNoIHRoZSBwaHlzaWNhbCBsYXlvdXQgb2YgdGhlCiB0YWJsZS4gRm9yIGV4
YW1wbGUsCgogQ1JFQVRFIFRBQkxFIGFfdGFibGUoaWQgQklHSU5ULCBuYW1lIFNUUklORykK
IFBBUlRJVElPTkVEIEJZIChjaXR5IFNUUklORywgc3RhdGUgU1RSSU5HKS4KCiBJbiB0aGlz
IGNhc2UgdGhlIHZhbHVlcyBtdXN0IGJlIFsnY2l0eScsICdzdGF0ZSddIGluIHRoYXQgb3Jk
ZXIuCgoMCgUEAAIABBIDKAIKCgwKBQQAAgAGEgMoCxwKDAoFBAACAAESAygdLwoMCgUEAAIA
AxIDKDIzCgwKBQQAAgAIEgMpBi4KDwoIBAACAAicCAASAykHLQoyCgIEARIELQAwARomIFRo
ZSBwYXJ0aXRpb25pbmcgY29sdW1uIGluZm9ybWF0aW9uLgoKCgoDBAEBEgMtCBkKOgoEBAEC
ABIDLwJFGi0gUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwYXJ0aXRpb24gY29sdW1uLgoK
DAoFBAECAAQSAy8CCgoMCgUEAQIABRIDLwsRCgwKBQQBAgABEgMvEhcKDAoFBAECAAMSAy8a
GwoMCgUEAQIACBIDLxxECg8KCAQBAgAInAgAEgMvHUNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitioningDefinition ===
    # Fields for PartitioningDefinition
    # Field: partitioned_column Type: 11 (.google.cloud.bigquery.v2.PartitionedColumn)

# === Message: Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitionedColumn ===
    # Fields for PartitionedColumn
    # Field: field Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::PartitioningDefinition - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/partitioning_definition.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::PartitioningDefinition;

    my $msg = Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitioningDefinition->new({
        partitioned_column => $partitioned_column,
    });

    # Read or update a field
    my $val = $msg->partitioned_column();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitioningDefinition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/partitioning_definition.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitioningDefinition

The partitioning information, which includes managed table, external table
and metastore partitioned table partition information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->partitioned_column() >> / C<< $msg->partitioned_column($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitionedColumn>)

Optional. Details about each partitioning column. This field is output only
for all partitioning types other than metastore partitioned tables.
BigQuery native tables only support 1 partitioning column. Other table
types may support 0, 1 or more partitioning columns.
For metastore partitioned tables, the order must match the definition order
in the Hive Metastore, where it must match the physical layout of the
table. For example,

CREATE TABLE a_table(id BIGINT, name STRING)
PARTITIONED BY (city STRING, state STRING).

In this case the values must be ['city', 'state'] in that order.

=back

=head2 Google::Cloud::Bigquery::V2::PartitioningDefinition::PartitionedColumn

The partitioning column information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<String>

Required. The name of the partition column.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::PartitioningDefinition::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
