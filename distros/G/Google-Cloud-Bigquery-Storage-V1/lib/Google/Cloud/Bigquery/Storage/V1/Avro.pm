package Google::Cloud::Bigquery::Storage::V1::Avro;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MS9hdnJvLnByb3RvEiBnb29nbGUu
Y2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MSIkCgpBdnJvU2NoZW1hEhYKBnNjaGVtYRgBIAEo
CVIGc2NoZW1hImEKCEF2cm9Sb3dzEjQKFnNlcmlhbGl6ZWRfYmluYXJ5X3Jvd3MYASABKAxS
FHNlcmlhbGl6ZWRCaW5hcnlSb3dzEh8KCXJvd19jb3VudBgCIAEoA0ICGAFSCHJvd0NvdW50
IpMDChhBdnJvU2VyaWFsaXphdGlvbk9wdGlvbnMSQQodZW5hYmxlX2Rpc3BsYXlfbmFtZV9h
dHRyaWJ1dGUYASABKAhSGmVuYWJsZURpc3BsYXlOYW1lQXR0cmlidXRlEo4BChlwaWNvc190
aW1lc3RhbXBfcHJlY2lzaW9uGAIgASgOMlIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3Jh
Z2UudjEuQXZyb1NlcmlhbGl6YXRpb25PcHRpb25zLlBpY29zVGltZXN0YW1wUHJlY2lzaW9u
UhdwaWNvc1RpbWVzdGFtcFByZWNpc2lvbiKiAQoXUGljb3NUaW1lc3RhbXBQcmVjaXNpb24S
KQolUElDT1NfVElNRVNUQU1QX1BSRUNJU0lPTl9VTlNQRUNJRklFRBAAEh4KGlRJTUVTVEFN
UF9QUkVDSVNJT05fTUlDUk9TEAESHQoZVElNRVNUQU1QX1BSRUNJU0lPTl9OQU5PUxACEh0K
GVRJTUVTVEFNUF9QUkVDSVNJT05fUElDT1MQA0K5AQokY29tLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5zdG9yYWdlLnYxQglBdnJvUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdx
dWVyeS9zdG9yYWdlL2FwaXYxL3N0b3JhZ2VwYjtzdG9yYWdlcGKqAiBHb29nbGUuQ2xvdWQu
QmlnUXVlcnkuU3RvcmFnZS5WMcoCIEdvb2dsZVxDbG91ZFxCaWdRdWVyeVxTdG9yYWdlXFYx
SvAWCgYSBA4AUAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACkKCAoBCBIDEgA9CgkKAgglEgMSAD0KCAoBCBIDEwBVCgkKAggLEgMTAFUKCAoBCBIDFAAi
CgkKAggKEgMUACIKCAoBCBIDFQAqCgkKAggIEgMVACoKCAoBCBIDFgA9CgkKAggBEgMWAD0K
CAoBCBIDFwA+CgkKAggpEgMXAD4KGgoCBAASBBoAHgEaDiBBdnJvIHNjaGVtYS4KCgoKAwQA
ARIDGggSCmUKBAQAAgASAx0CFBpYIEpzb24gc2VyaWFsaXplZCBzY2hlbWEsIGFzIGRlc2Ny
aWJlZCBhdAogaHR0cHM6Ly9hdnJvLmFwYWNoZS5vcmcvZG9jcy8xLjguMS9zcGVjLmh0bWwu
CgoMCgUEAAIABRIDHQIICgwKBQQAAgABEgMdCQ8KDAoFBAACAAMSAx0SEwoYCgIEARIEIQAo
ARoMIEF2cm8gcm93cy4KCgoKAwQBARIDIQgQCjEKBAQBAgASAyMCIxokIEJpbmFyeSBzZXJp
YWxpemVkIHJvd3MgaW4gYSBibG9jay4KCgwKBQQBAgAFEgMjAgcKDAoFBAECAAESAyMIHgoM
CgUEAQIAAxIDIyEiCowBCgQEAQIBEgMnAioafyBbRGVwcmVjYXRlZF0gVGhlIGNvdW50IG9m
IHJvd3MgaW4gdGhlIHJldHVybmluZyBibG9jay4KIFBsZWFzZSB1c2UgdGhlIGZvcm1hdC1p
bmRlcGVuZGVudCBSZWFkUm93c1Jlc3BvbnNlLnJvd19jb3VudCBpbnN0ZWFkLgoKDAoFBAEC
AQUSAycCBwoMCgUEAQIBARIDJwgRCgwKBQQBAgEDEgMnFBUKDAoFBAECAQgSAycWKQoNCgYE
AQIBCAMSAycXKAo+CgIEAhIEKwBQARoyIENvbnRhaW5zIG9wdGlvbnMgc3BlY2lmaWMgdG8g
QXZybyBTZXJpYWxpemF0aW9uLgoKCgoDBAIBEgMrCCAKpQEKBAQCBAASBC4CPwMalgEgVGhl
IHByZWNpc2lvbiBvZiB0aGUgdGltZXN0YW1wIHZhbHVlIGluIHRoZSBBdnJvIG1lc3NhZ2Uu
IFRoaXMgcHJlY2lzaW9uCiB3aWxsICoqb25seSoqIGJlIGFwcGxpZWQgdG8gdGhlIGNvbHVt
bihzKSB3aXRoIHRoZSBgVElNRVNUQU1QX1BJQ09TYCB0eXBlLgoKDAoFBAIEAAESAy4HHgpY
CgYEAgQAAgASAzAELhpJIFVuc3BlY2lmaWVkIHRpbWVzdGFtcCBwcmVjaXNpb24uIFRoZSBk
ZWZhdWx0IHByZWNpc2lvbiBpcyBtaWNyb3NlY29uZHMuCgoOCgcEAgQAAgABEgMwBCkKDgoH
BAIEAAIAAhIDMCwtCrEBCgYEAgQAAgESAzUEIxqhASBUaW1lc3RhbXAgdmFsdWVzIHJldHVy
bmVkIGJ5IFJlYWQgQVBJIHdpbGwgYmUgdHJ1bmNhdGVkIHRvIG1pY3Jvc2Vjb25kCiBsZXZl
bCBwcmVjaXNpb24uIFRoZSB2YWx1ZSB3aWxsIGJlIGVuY29kZWQgYXMgQXZybyBUSU1FU1RB
TVAgdHlwZSBpbiBhCiA2NCBiaXQgaW50ZWdlci4KCg4KBwQCBAACAQESAzUEHgoOCgcEAgQA
AgECEgM1ISIKsAEKBgQCBAACAhIDOgQiGqABIFRpbWVzdGFtcCB2YWx1ZXMgcmV0dXJuZWQg
YnkgUmVhZCBBUEkgd2lsbCBiZSB0cnVuY2F0ZWQgdG8gbmFub3NlY29uZAogbGV2ZWwgcHJl
Y2lzaW9uLiBUaGUgdmFsdWUgd2lsbCBiZSBlbmNvZGVkIGFzIEF2cm8gVElNRVNUQU1QIHR5
cGUgaW4gYQogNjQgYml0IGludGVnZXIuCgoOCgcEAgQAAgIBEgM6BB0KDgoHBAIEAAICAhID
OiAhCpEBCgYEAgQAAgMSAz4EIhqBASBSZWFkIEFQSSB3aWxsIHJldHVybiBmdWxsIHByZWNp
c2lvbiBwaWNvc2Vjb25kIHZhbHVlLiBUaGUgdmFsdWUgd2lsbCBiZQogZW5jb2RlZCBhcyBh
IHN0cmluZyB3aGljaCBjb25mb3JtcyB0byBJU08gODYwMSBmb3JtYXQuCgoOCgcEAgQAAgMB
EgM+BB0KDgoHBAIEAAIDAhIDPiAhCvMDCgQEAgIAEgNLAika5QMgRW5hYmxlIGRpc3BsYXlO
YW1lIGF0dHJpYnV0ZSBpbiBBdnJvIHNjaGVtYS4KCiBUaGUgQXZybyBzcGVjaWZpY2F0aW9u
IHJlcXVpcmVzIGZpZWxkIG5hbWVzIHRvIGJlIGFscGhhbnVtZXJpYy4gIEJ5CiBkZWZhdWx0
LCBpbiBjYXNlcyB3aGVuIGNvbHVtbiBuYW1lcyBkbyBub3QgY29uZm9ybSB0byB0aGVzZSBy
ZXF1aXJlbWVudHMKIChlLmcuIG5vbi1hc2NpaSB1bmljb2RlIGNvZGVwb2ludHMpIGFuZCBB
dnJvIGlzIHJlcXVlc3RlZCBhcyBhbiBvdXRwdXQKIGZvcm1hdCwgdGhlIENyZWF0ZVJlYWRT
ZXNzaW9uIGNhbGwgd2lsbCBmYWlsLgoKIFNldHRpbmcgdGhpcyBmaWVsZCB0byB0cnVlLCBw
b3B1bGF0ZXMgYXZybyBmaWVsZCBuYW1lcyB3aXRoIGEgcGxhY2Vob2xkZXIKIHZhbHVlIGFu
ZCBwb3B1bGF0ZXMgYSAiZGlzcGxheU5hbWUiIGF0dHJpYnV0ZSBmb3IgZXZlcnkgYXZybyBm
aWVsZCB3aXRoIHRoZQogb3JpZ2luYWwgY29sdW1uIG5hbWUuCgoMCgUEAgIABRIDSwIGCgwK
BQQCAgABEgNLByQKDAoFBAICAAMSA0snKApsCgQEAgIBEgNPAjgaXyBPcHRpb25hbC4gU2V0
IHRpbWVzdGFtcCBwcmVjaXNpb24gb3B0aW9uLiBJZiBub3Qgc2V0LCB0aGUgZGVmYXVsdCBw
cmVjaXNpb24KIGlzIG1pY3Jvc2Vjb25kcy4KCgwKBQQCAgEGEgNPAhkKDAoFBAICAQESA08a
MwoMCgUEAgIBAxIDTzY3YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema ===
    # Fields for AvroSchema
    # Field: schema Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1::Avro::AvroRows ===
    # Fields for AvroRows
    # Field: serialized_binary_rows Type: 12 ()
    # Field: row_count Type: 3 ()

# === Message: Google::Cloud::Bigquery::Storage::V1::Avro::AvroSerializationOptions ===
    # Fields for AvroSerializationOptions
    # Field: enable_display_name_attribute Type: 8 ()
    # Field: picos_timestamp_precision Type: 14 (.google.cloud.bigquery.storage.v1.AvroSerializationOptions.PicosTimestampPrecision)

# Enum: AvroSerializationOptions::PicosTimestampPrecision
our $AvroSerializationOptions_PICOS_TIMESTAMP_PRECISION_UNSPECIFIED = 0;
our $AvroSerializationOptions_TIMESTAMP_PRECISION_MICROS = 1;
our $AvroSerializationOptions_TIMESTAMP_PRECISION_NANOS = 2;
our $AvroSerializationOptions_TIMESTAMP_PRECISION_PICOS = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1::Avro - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1/avro.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1::Avro;

    my $msg = Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema->new({
        schema => $schema,
    });

    # Read or update a field
    my $val = $msg->schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1/avro.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1::Avro::AvroSchema

Avro schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<String>

Json serialized schema, as described at
https://avro.apache.org/docs/1.8.1/spec.html.

=back

=head2 Google::Cloud::Bigquery::Storage::V1::Avro::AvroRows

Avro rows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_binary_rows() >> / C<< $msg->serialized_binary_rows($value) >>

Type: C<Bytes>

Binary serialized rows in a block.

=item * C<< $msg->row_count() >> / C<< $msg->row_count($value) >>

Type: C<Int64>

[Deprecated] The count of rows in the returning block.
Please use the format-independent ReadRowsResponse.row_count instead.

=back

=head2 Google::Cloud::Bigquery::Storage::V1::Avro::AvroSerializationOptions

Contains options specific to Avro Serialization.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_display_name_attribute() >> / C<< $msg->enable_display_name_attribute($value) >>

Type: C<Bool>

Enable displayName attribute in Avro schema.

The Avro specification requires field names to be alphanumeric.  By
default, in cases when column names do not conform to these requirements
(e.g. non-ascii unicode codepoints) and Avro is requested as an output
format, the CreateReadSession call will fail.

Setting this field to true, populates avro field names with a placeholder
value and populates a "displayName" attribute for every avro field with the
original column name.

=item * C<< $msg->picos_timestamp_precision() >> / C<< $msg->picos_timestamp_precision($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1::AvroSerializationOptions::PicosTimestampPrecision>)

Optional. Set timestamp precision option. If not set, the default precision
is microseconds.

=back

=head3 Enum: AvroSerializationOptions::PicosTimestampPrecision

=over 4

=item * C<PICOS_TIMESTAMP_PRECISION_UNSPECIFIED> => C<0>

=item * C<TIMESTAMP_PRECISION_MICROS> => C<1>

=item * C<TIMESTAMP_PRECISION_NANOS> => C<2>

=item * C<TIMESTAMP_PRECISION_PICOS> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1::Avro::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
