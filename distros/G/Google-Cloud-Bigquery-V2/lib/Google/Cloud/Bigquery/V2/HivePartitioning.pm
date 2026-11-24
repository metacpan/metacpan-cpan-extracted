package Google::Cloud::Bigquery::V2::HivePartitioning;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Wrappers };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvaGl2ZV9wYXJ0aXRpb25pbmcucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoeZ29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvItsBChdIaXZlUGFydGl0aW9uaW5n
T3B0aW9ucxIXCgRtb2RlGAEgASgJQgPgQQFSBG1vZGUSLwoRc291cmNlX3VyaV9wcmVmaXgY
AiABKAlCA+BBAVIPc291cmNlVXJpUHJlZml4ElkKGHJlcXVpcmVfcGFydGl0aW9uX2ZpbHRl
chgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5Cb29sVmFsdWVCA+BBAVIWcmVxdWlyZVBhcnRp
dGlvbkZpbHRlchIbCgZmaWVsZHMYBCADKAlCA+BBA1IGZmllbGRzQnIKHGNvbS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkudjJCFUhpdmVQYXJ0aXRpb25pbmdQcm90b1o7Y2xvdWQuZ29vZ2xl
LmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGJKgxoKBhIE
DgBVAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
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
ABIDEgApCgkKAgMBEgMTACgKCAoBCBIDFQBSCgkKAggLEgMVAFIKCAoBCBIDFgA2CgkKAggI
EgMWADYKCAoBCBIDFwA1CgkKAggBEgMXADUKPwoCBAASBBoAVQEaMyBPcHRpb25zIGZvciBj
b25maWd1cmluZyBoaXZlIHBhcnRpdGlvbmluZyBkZXRlY3QuCgoKCgMEAAESAxoIHwqgBAoE
BAACABIDKAI7GpIEIE9wdGlvbmFsLiBXaGVuIHNldCwgd2hhdCBtb2RlIG9mIGhpdmUgcGFy
dGl0aW9uaW5nIHRvIHVzZSB3aGVuIHJlYWRpbmcKIGRhdGEuICBUaGUgZm9sbG93aW5nIG1v
ZGVzIGFyZSBzdXBwb3J0ZWQ6CgogKiBBVVRPOiBhdXRvbWF0aWNhbGx5IGluZmVyIHBhcnRp
dGlvbiBrZXkgbmFtZShzKSBhbmQgdHlwZShzKS4KCiAqIFNUUklOR1M6IGF1dG9tYXRpY2Fs
bHkgaW5mZXIgcGFydGl0aW9uIGtleSBuYW1lKHMpLiAgQWxsIHR5cGVzIGFyZQogc3RyaW5n
cy4KCiAqIENVU1RPTTogcGFydGl0aW9uIGtleSBzY2hlbWEgaXMgZW5jb2RlZCBpbiB0aGUg
c291cmNlIFVSSSBwcmVmaXguCgogTm90IGFsbCBzdG9yYWdlIGZvcm1hdHMgc3VwcG9ydCBo
aXZlIHBhcnRpdGlvbmluZy4gUmVxdWVzdGluZyBoaXZlCiBwYXJ0aXRpb25pbmcgb24gYW4g
dW5zdXBwb3J0ZWQgZm9ybWF0IHdpbGwgbGVhZCB0byBhbiBlcnJvci4KIEN1cnJlbnRseSBz
dXBwb3J0ZWQgZm9ybWF0cyBhcmU6IEpTT04sIENTViwgT1JDLCBBdnJvIGFuZCBQYXJxdWV0
LgoKDAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkNCgwKBQQAAgADEgMoEBEKDAoFBAACAAgS
AygSOgoPCggEAAIACJwIABIDKBM5CqkHCgQEAAIBEgNBAkgamwcgT3B0aW9uYWwuIFdoZW4g
aGl2ZSBwYXJ0aXRpb24gZGV0ZWN0aW9uIGlzIHJlcXVlc3RlZCwgYSBjb21tb24gcHJlZml4
IGZvcgogYWxsIHNvdXJjZSB1cmlzIG11c3QgYmUgcmVxdWlyZWQuICBUaGUgcHJlZml4IG11
c3QgZW5kIGltbWVkaWF0ZWx5IGJlZm9yZQogdGhlIHBhcnRpdGlvbiBrZXkgZW5jb2Rpbmcg
YmVnaW5zLiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgZmlsZXMgZm9sbG93aW5nCiB0aGlzIGRh
dGEgbGF5b3V0OgoKIGdzOi8vYnVja2V0L3BhdGhfdG9fdGFibGUvZHQ9MjAxOS0wNi0wMS9j
b3VudHJ5PVVTQS9pZD03L2ZpbGUuYXZybwoKIGdzOi8vYnVja2V0L3BhdGhfdG9fdGFibGUv
ZHQ9MjAxOS0wNS0zMS9jb3VudHJ5PUNBL2lkPTMvZmlsZS5hdnJvCgogV2hlbiBoaXZlIHBh
cnRpdGlvbmluZyBpcyByZXF1ZXN0ZWQgd2l0aCBlaXRoZXIgQVVUTyBvciBTVFJJTkdTIGRl
dGVjdGlvbiwKIHRoZSBjb21tb24gcHJlZml4IGNhbiBiZSBlaXRoZXIgb2YgZ3M6Ly9idWNr
ZXQvcGF0aF90b190YWJsZSBvcgogZ3M6Ly9idWNrZXQvcGF0aF90b190YWJsZS8uCgogQ1VT
VE9NIGRldGVjdGlvbiByZXF1aXJlcyBlbmNvZGluZyB0aGUgcGFydGl0aW9uaW5nIHNjaGVt
YSBpbW1lZGlhdGVseQogYWZ0ZXIgdGhlIGNvbW1vbiBwcmVmaXguICBGb3IgQ1VTVE9NLCBh
bnkgb2YKCiAqIGdzOi8vYnVja2V0L3BhdGhfdG9fdGFibGUve2R0OkRBVEV9L3tjb3VudHJ5
OlNUUklOR30ve2lkOklOVEVHRVJ9CgogKiBnczovL2J1Y2tldC9wYXRoX3RvX3RhYmxlL3tk
dDpTVFJJTkd9L3tjb3VudHJ5OlNUUklOR30ve2lkOklOVEVHRVJ9CgogKiBnczovL2J1Y2tl
dC9wYXRoX3RvX3RhYmxlL3tkdDpEQVRFfS97Y291bnRyeTpTVFJJTkd9L3tpZDpTVFJJTkd9
Cgogd291bGQgYWxsIGJlIHZhbGlkIHNvdXJjZSBVUkkgcHJlZml4ZXMuCgoMCgUEAAIBBRID
QQIICgwKBQQAAgEBEgNBCRoKDAoFBAACAQMSA0EdHgoMCgUEAAIBCBIDQR9HCg8KCAQAAgEI
nAgAEgNBIEYK8QIKBAQAAgISBEsCTC8a4gIgT3B0aW9uYWwuIElmIHNldCB0byB0cnVlLCBx
dWVyaWVzIG92ZXIgdGhpcyB0YWJsZSByZXF1aXJlIGEgcGFydGl0aW9uCiBmaWx0ZXIgdGhh
dCBjYW4gYmUgdXNlZCBmb3IgcGFydGl0aW9uIGVsaW1pbmF0aW9uIHRvIGJlIHNwZWNpZmll
ZC4KCiBOb3RlIHRoYXQgdGhpcyBmaWVsZCBzaG91bGQgb25seSBiZSB0cnVlIHdoZW4gY3Jl
YXRpbmcgYSBwZXJtYW5lbnQKIGV4dGVybmFsIHRhYmxlIG9yIHF1ZXJ5aW5nIGEgdGVtcG9y
YXJ5IGV4dGVybmFsIHRhYmxlLgoKIEhpdmUtcGFydGl0aW9uZWQgbG9hZHMgd2l0aCByZXF1
aXJlX3BhcnRpdGlvbl9maWx0ZXIgZXhwbGljaXRseSBzZXQgdG8KIHRydWUgd2lsbCBmYWls
LgoKDAoFBAACAgYSA0sCGwoMCgUEAAICARIDSxw0CgwKBQQAAgIDEgNLNzgKDAoFBAACAggS
A0wGLgoPCggEAAICCJwIABIDTActCpgDCgQEAAIDEgNUAkkaigMgT3V0cHV0IG9ubHkuIEZv
ciBwZXJtYW5lbnQgZXh0ZXJuYWwgdGFibGVzLCB0aGlzIGZpZWxkIGlzIHBvcHVsYXRlZCB3
aXRoCiB0aGUgaGl2ZSBwYXJ0aXRpb24ga2V5cyBpbiB0aGUgb3JkZXIgdGhleSB3ZXJlIGlu
ZmVycmVkLiBUaGUgdHlwZXMgb2YgdGhlCiBwYXJ0aXRpb24ga2V5cyBjYW4gYmUgZGVkdWNl
ZCBieSBjaGVja2luZyB0aGUgdGFibGUgc2NoZW1hICh3aGljaCB3aWxsCiBpbmNsdWRlIHRo
ZSBwYXJ0aXRpb24ga2V5cykuIE5vdCBldmVyeSBBUEkgd2lsbCBwb3B1bGF0ZSB0aGlzIGZp
ZWxkIGluIHRoZQogb3V0cHV0LiBGb3IgZXhhbXBsZSwgVGFibGVzLkdldCB3aWxsIHBvcHVs
YXRlIGl0LCBidXQgVGFibGVzLkxpc3Qgd2lsbCBub3QKIGNvbnRhaW4gdGhpcyBmaWVsZC4K
CgwKBQQAAgMEEgNUAgoKDAoFBAACAwUSA1QLEQoMCgUEAAIDARIDVBIYCgwKBQQAAgMDEgNU
GxwKDAoFBAACAwgSA1QdSAoPCggEAAIDCJwIABIDVB5HYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions ===
    # Fields for HivePartitioningOptions
    # Field: mode Type: 9 ()
    # Field: source_uri_prefix Type: 9 ()
    # Field: require_partition_filter Type: 11 (.google.protobuf.BoolValue)
    # Field: fields Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::HivePartitioning - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/hive_partitioning.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::HivePartitioning;

    my $msg = Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions->new({
        mode => $mode,
        source_uri_prefix => $source_uri_prefix,
        require_partition_filter => $require_partition_filter,
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->mode();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/hive_partitioning.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::HivePartitioning::HivePartitioningOptions

Options for configuring hive partitioning detect.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

Optional. When set, what mode of hive partitioning to use when reading
data.  The following modes are supported:

* AUTO: automatically infer partition key name(s) and type(s).

* STRINGS: automatically infer partition key name(s).  All types are
strings.

* CUSTOM: partition key schema is encoded in the source URI prefix.

Not all storage formats support hive partitioning. Requesting hive
partitioning on an unsupported format will lead to an error.
Currently supported formats are: JSON, CSV, ORC, Avro and Parquet.

=item * C<< $msg->source_uri_prefix() >> / C<< $msg->source_uri_prefix($value) >>

Type: C<String>

Optional. When hive partition detection is requested, a common prefix for
all source uris must be required.  The prefix must end immediately before
the partition key encoding begins. For example, consider files following
this data layout:

gs://bucket/path_to_table/dt=2019-06-01/country=USA/id=7/file.avro

gs://bucket/path_to_table/dt=2019-05-31/country=CA/id=3/file.avro

When hive partitioning is requested with either AUTO or STRINGS detection,
the common prefix can be either of gs://bucket/path_to_table or
gs://bucket/path_to_table/.

CUSTOM detection requires encoding the partitioning schema immediately
after the common prefix.  For CUSTOM, any of

* gs://bucket/path_to_table/{dt:DATE}/{country:STRING}/{id:INTEGER}

* gs://bucket/path_to_table/{dt:STRING}/{country:STRING}/{id:INTEGER}

* gs://bucket/path_to_table/{dt:DATE}/{country:STRING}/{id:STRING}

would all be valid source URI prefixes.

=item * C<< $msg->require_partition_filter() >> / C<< $msg->require_partition_filter($value) >>

Type: C<Message> (L<Google::Protobuf::Wrappers::BoolValue>)

Optional. If set to true, queries over this table require a partition
filter that can be used for partition elimination to be specified.

Note that this field should only be true when creating a permanent
external table or querying a temporary external table.

Hive-partitioned loads with require_partition_filter explicitly set to
true will fail.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<String>

Output only. For permanent external tables, this field is populated with
the hive partition keys in the order they were inferred. The types of the
partition keys can be deduced by checking the table schema (which will
include the partition keys). Not every API will populate this field in the
output. For example, Tables.Get will populate it, but Tables.List will not
contain this field.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::HivePartitioning::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
