package Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGExL3JlYWRfb3B0aW9ucy5w
cm90bxIlZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMSJkChBUYWJsZVJl
YWRPcHRpb25zEicKD3NlbGVjdGVkX2ZpZWxkcxgBIAMoCVIOc2VsZWN0ZWRGaWVsZHMSJwoP
cm93X3Jlc3RyaWN0aW9uGAIgASgJUg5yb3dSZXN0cmljdGlvbkJwCiljb20uZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMVpDY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdx
dWVyeS9zdG9yYWdlL2FwaXYxYmV0YTEvc3RvcmFnZXBiO3N0b3JhZ2VwYkqBFQoGEgQOAFMB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAuCggKAQgSAxIA
WgoJCgIICxIDEgBaCggKAQgSAxMAQgoJCgIIARIDEwBCCjQKAgQAEgQWAFMBGiggT3B0aW9u
cyBkaWN0YXRpbmcgaG93IHdlIHJlYWQgYSB0YWJsZS4KCgoKAwQAARIDFggYCskLCgQEAAIA
EgNGAiYauwsgT3B0aW9uYWwuIFRoZSBuYW1lcyBvZiB0aGUgZmllbGRzIGluIHRoZSB0YWJs
ZSB0byBiZSByZXR1cm5lZC4gSWYgbm8KIGZpZWxkIG5hbWVzIGFyZSBzcGVjaWZpZWQsIHRo
ZW4gYWxsIGZpZWxkcyBpbiB0aGUgdGFibGUgYXJlIHJldHVybmVkLgoKIE5lc3RlZCBmaWVs
ZHMgLS0gdGhlIGNoaWxkIGVsZW1lbnRzIG9mIGEgU1RSVUNUIGZpZWxkIC0tIGNhbiBiZSBz
ZWxlY3RlZAogaW5kaXZpZHVhbGx5IHVzaW5nIHRoZWlyIGZ1bGx5LXF1YWxpZmllZCBuYW1l
cywgYW5kIHdpbGwgYmUgcmV0dXJuZWQgYXMKIHJlY29yZCBmaWVsZHMgY29udGFpbmluZyBv
bmx5IHRoZSBzZWxlY3RlZCBuZXN0ZWQgZmllbGRzLiBJZiBhIFNUUlVDVAogZmllbGQgaXMg
c3BlY2lmaWVkIGluIHRoZSBzZWxlY3RlZCBmaWVsZHMgbGlzdCwgYWxsIG9mIHRoZSBjaGls
ZCBlbGVtZW50cwogd2lsbCBiZSByZXR1cm5lZC4KCiBBcyBhbiBleGFtcGxlLCBjb25zaWRl
ciBhIHRhYmxlIHdpdGggdGhlIGZvbGxvd2luZyBzY2hlbWE6CgogICB7CiAgICAgICAibmFt
ZSI6ICJzdHJ1Y3RfZmllbGQiLAogICAgICAgInR5cGUiOiAiUkVDT1JEIiwKICAgICAgICJt
b2RlIjogIk5VTExBQkxFIiwKICAgICAgICJmaWVsZHMiOiBbCiAgICAgICAgICAgewogICAg
ICAgICAgICAgICAibmFtZSI6ICJzdHJpbmdfZmllbGQxIiwKICAgICAgICAgICAgICAgInR5
cGUiOiAiU1RSSU5HIiwKIC4gICAgICAgICAgICAgICJtb2RlIjogIk5VTExBQkxFIgogICAg
ICAgICAgIH0sCiAgICAgICAgICAgewogICAgICAgICAgICAgICAibmFtZSI6ICJzdHJpbmdf
ZmllbGQyIiwKICAgICAgICAgICAgICAgInR5cGUiOiAiU1RSSU5HIiwKICAgICAgICAgICAg
ICAgIm1vZGUiOiAiTlVMTEFCTEUiCiAgICAgICAgICAgfQogICAgICAgXQogICB9CgogU3Bl
Y2lmeWluZyAic3RydWN0X2ZpZWxkIiBpbiB0aGUgc2VsZWN0ZWQgZmllbGRzIGxpc3Qgd2ls
bCByZXN1bHQgaW4gYQogcmVhZCBzZXNzaW9uIHNjaGVtYSB3aXRoIHRoZSBmb2xsb3dpbmcg
bG9naWNhbCBzdHJ1Y3R1cmU6CgogICBzdHJ1Y3RfZmllbGQgewogICAgICAgc3RyaW5nX2Zp
ZWxkMQogICAgICAgc3RyaW5nX2ZpZWxkMgogICB9CgogU3BlY2lmeWluZyAic3RydWN0X2Zp
ZWxkLnN0cmluZ19maWVsZDEiIGluIHRoZSBzZWxlY3RlZCBmaWVsZHMgbGlzdCB3aWxsCiBy
ZXN1bHQgaW4gYSByZWFkIHNlc3Npb24gc2NoZW1hIHdpdGggdGhlIGZvbGxvd2luZyBsb2dp
Y2FsIHN0cnVjdHVyZToKCiAgIHN0cnVjdF9maWVsZCB7CiAgICAgICBzdHJpbmdfZmllbGQx
CiAgIH0KCiBUaGUgb3JkZXIgb2YgdGhlIGZpZWxkcyBpbiB0aGUgcmVhZCBzZXNzaW9uIHNj
aGVtYSBpcyBkZXJpdmVkIGZyb20gdGhlCiB0YWJsZSBzY2hlbWEgYW5kIGRvZXMgbm90IGNv
cnJlc3BvbmQgdG8gdGhlIG9yZGVyIGluIHdoaWNoIHRoZSBmaWVsZHMgYXJlCiBzcGVjaWZp
ZWQgaW4gdGhpcyBsaXN0LgoKDAoFBAACAAQSA0YCCgoMCgUEAAIABRIDRgsRCgwKBQQAAgAB
EgNGEiEKDAoFBAACAAMSA0YkJQqTAwoEBAACARIDUgIdGoUDIE9wdGlvbmFsLiBTUUwgdGV4
dCBmaWx0ZXJpbmcgc3RhdGVtZW50LCBzaW1pbGFyIHRvIGEgV0hFUkUgY2xhdXNlIGluCiBh
IFNRTCBxdWVyeS4gQWdncmVnYXRlcyBhcmUgbm90IHN1cHBvcnRlZC4KCiBFeGFtcGxlczog
ImludF9maWVsZCA+IDUiCiAgICAgICAgICAgImRhdGVfZmllbGQgPSBDQVNUKCcyMDE0LTkt
MjcnIGFzIERBVEUpIgogICAgICAgICAgICJudWxsYWJsZV9maWVsZCBpcyBub3QgTlVMTCIK
ICAgICAgICAgICAic3RfZXF1YWxzKGdlb19maWVsZCwgc3RfZ2VvZnJvbXRleHQoIlBPSU5U
KDIsIDIpIikpIgogICAgICAgICAgICJudW1lcmljX2ZpZWxkIEJFVFdFRU4gMS4wIEFORCA1
LjAiCgogUmVzdHJpY3RlZCB0byBhIG1heGltdW0gbGVuZ3RoIGZvciAxIE1CLgoKDAoFBAAC
AQUSA1ICCAoMCgUEAAIBARIDUgkYCgwKBQQAAgEDEgNSGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions ===
    # Fields for TableReadOptions
    # Field: selected_fields Type: 9 ()
    # Field: row_restriction Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta1/read_options.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions->new({
        selected_fields => $selected_fields,
        row_restriction => $row_restriction,
    });

    # Read or update a field
    my $val = $msg->selected_fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta1/read_options.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::TableReadOptions

Options dictating how we read a table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->selected_fields() >> / C<< $msg->selected_fields($value) >>

Type: C<String>

Optional. The names of the fields in the table to be returned. If no
field names are specified, then all fields in the table are returned.

Nested fields -- the child elements of a STRUCT field -- can be selected
individually using their fully-qualified names, and will be returned as
record fields containing only the selected nested fields. If a STRUCT
field is specified in the selected fields list, all of the child elements
will be returned.

As an example, consider a table with the following schema:

  {
      "name": "struct_field",
      "type": "RECORD",
      "mode": "NULLABLE",
      "fields": [
          {
              "name": "string_field1",
              "type": "STRING",
.              "mode": "NULLABLE"
          },
          {
              "name": "string_field2",
              "type": "STRING",
              "mode": "NULLABLE"
          }
      ]
  }

Specifying "struct_field" in the selected fields list will result in a
read session schema with the following logical structure:

  struct_field {
      string_field1
      string_field2
  }

Specifying "struct_field.string_field1" in the selected fields list will
result in a read session schema with the following logical structure:

  struct_field {
      string_field1
  }

The order of the fields in the read session schema is derived from the
table schema and does not correspond to the order in which the fields are
specified in this list.

=item * C<< $msg->row_restriction() >> / C<< $msg->row_restriction($value) >>

Type: C<String>

Optional. SQL text filtering statement, similar to a WHERE clause in
a SQL query. Aggregates are not supported.

Examples: "int_field > 5"
          "date_field = CAST('2014-9-27' as DATE)"
          "nullable_field is not NULL"
          "st_equals(geo_field, st_geofromtext("POINT(2, 2)"))"
          "numeric_field BETWEEN 1.0 AND 5.0"

Restricted to a maximum length for 1 MB.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta1::ReadOptions::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
