package Google::Cloud::Datacatalog::V1::PhysicalSchema;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGF0YWNhdGFsb2cvdjEvcGh5c2ljYWxfc2NoZW1hLnByb3RvEhtn
b29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEimgUKDlBoeXNpY2FsU2NoZW1hEkwKBGF2cm8Y
ASABKAsyNi5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjEuUGh5c2ljYWxTY2hlbWEuQXZy
b1NjaGVtYUgAUgRhdnJvElIKBnRocmlmdBgCIAEoCzI4Lmdvb2dsZS5jbG91ZC5kYXRhY2F0
YWxvZy52MS5QaHlzaWNhbFNjaGVtYS5UaHJpZnRTY2hlbWFIAFIGdGhyaWZ0ElgKCHByb3Rv
YnVmGAMgASgLMjouZ29vZ2xlLmNsb3VkLmRhdGFjYXRhbG9nLnYxLlBoeXNpY2FsU2NoZW1h
LlByb3RvYnVmU2NoZW1hSABSCHByb3RvYnVmElUKB3BhcnF1ZXQYBCABKAsyOS5nb29nbGUu
Y2xvdWQuZGF0YWNhdGFsb2cudjEuUGh5c2ljYWxTY2hlbWEuUGFycXVldFNjaGVtYUgAUgdw
YXJxdWV0EkkKA29yYxgFIAEoCzI1Lmdvb2dsZS5jbG91ZC5kYXRhY2F0YWxvZy52MS5QaHlz
aWNhbFNjaGVtYS5PcmNTY2hlbWFIAFIDb3JjEkkKA2NzdhgGIAEoCzI1Lmdvb2dsZS5jbG91
ZC5kYXRhY2F0YWxvZy52MS5QaHlzaWNhbFNjaGVtYS5Dc3ZTY2hlbWFIAFIDY3N2GiAKCkF2
cm9TY2hlbWESEgoEdGV4dBgBIAEoCVIEdGV4dBoiCgxUaHJpZnRTY2hlbWESEgoEdGV4dBgB
IAEoCVIEdGV4dBokCg5Qcm90b2J1ZlNjaGVtYRISCgR0ZXh0GAEgASgJUgR0ZXh0Gg8KDVBh
cnF1ZXRTY2hlbWEaCwoJT3JjU2NoZW1hGgsKCUNzdlNjaGVtYUIICgZzY2hlbWFC2AEKH2Nv
bS5nb29nbGUuY2xvdWQuZGF0YWNhdGFsb2cudjFCE1BoeXNpY2FsU2NoZW1hUHJvdG9QAVpB
Y2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhY2F0YWxvZy9hcGl2MS9kYXRhY2F0YWxvZ3BiO2Rh
dGFjYXRhbG9ncGKqAhtHb29nbGUuQ2xvdWQuRGF0YUNhdGFsb2cuVjHKAhtHb29nbGVcQ2xv
dWRcRGF0YUNhdGFsb2dcVjHqAh5Hb29nbGU6OkNsb3VkOjpEYXRhQ2F0YWxvZzo6VjFK1hAK
BhIEDgBLAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoI
CgEIEgMSADgKCQoCCCUSAxIAOAoICgEIEgMTAFgKCQoCCAsSAxMAWAoICgEIEgMUACIKCQoC
CAoSAxQAIgoICgEIEgMVADQKCQoCCAgSAxUANAoICgEIEgMWADgKCQoCCAESAxYAOAoICgEI
EgMXADgKCQoCCCkSAxcAOAoICgEIEgMYADcKCQoCCC0SAxgANwqJAQoCBAASBBwASwEafSBO
YXRpdmUgc2NoZW1hIHVzZWQgYnkgYSByZXNvdXJjZSByZXByZXNlbnRlZCBhcyBhbiBlbnRy
eS4gVXNlZCBieSBxdWVyeQogZW5naW5lcyBmb3IgZGVzZXJpYWxpemluZyBhbmQgcGFyc2lu
ZyBzb3VyY2UgZGF0YS4KCgoKAwQAARIDHAgWCisKBAQAAwASBB4CIQMaHSBTY2hlbWEgaW4g
QXZybyBKU09OIGZvcm1hdC4KCgwKBQQAAwABEgMeChQKMAoGBAADAAIAEgMgBBQaISBKU09O
IHNvdXJjZSBvZiB0aGUgQXZybyBzY2hlbWEuCgoOCgcEAAMAAgAFEgMgBAoKDgoHBAADAAIA
ARIDIAsPCg4KBwQAAwACAAMSAyASEwooCgQEAAMBEgQkAicDGhogU2NoZW1hIGluIFRocmlm
dCBmb3JtYXQuCgoMCgUEAAMBARIDJAoWCjEKBgQAAwECABIDJgQUGiIgVGhyaWZ0IElETCBz
b3VyY2Ugb2YgdGhlIHNjaGVtYS4KCg4KBwQAAwECAAUSAyYECgoOCgcEAAMBAgABEgMmCw8K
DgoHBAADAQIAAxIDJhITCjEKBAQAAwISBCoCLQMaIyBTY2hlbWEgaW4gcHJvdG9jb2wgYnVm
ZmVyIGZvcm1hdC4KCgwKBQQAAwIBEgMqChgKNgoGBAADAgIAEgMsBBQaJyBQcm90b2NvbCBi
dWZmZXIgc291cmNlIG9mIHRoZSBzY2hlbWEuCgoOCgcEAAMCAgAFEgMsBAoKDgoHBAADAgIA
ARIDLAsPCg4KBwQAAwICAAMSAywSEwozCgQEAAMDEgMwAhoaJiBNYXJrcyBhIFBhcnF1ZXQt
ZW5jb2RlZCBkYXRhIHNvdXJjZS4KCgwKBQQAAwMBEgMwChcKMAoEBAADBBIDMwIWGiMgTWFy
a3MgYW4gT1JDLWVuY29kZWQgZGF0YSBzb3VyY2UuCgoMCgUEAAMEARIDMwoTCi8KBAQAAwUS
AzYCFhoiIE1hcmtzIGEgQ1NWLWVuY29kZWQgZGF0YSBzb3VyY2UuCgoMCgUEAAMFARIDNgoT
CgwKBAQACAASBDgCSgMKDAoFBAAIAAESAzgIDgoqCgQEAAIAEgM6BBgaHSBTY2hlbWEgaW4g
QXZybyBKU09OIGZvcm1hdC4KCgwKBQQAAgAGEgM6BA4KDAoFBAACAAESAzoPEwoMCgUEAAIA
AxIDOhYXCicKBAQAAgESAz0EHBoaIFNjaGVtYSBpbiBUaHJpZnQgZm9ybWF0LgoKDAoFBAAC
AQYSAz0EEAoMCgUEAAIBARIDPREXCgwKBQQAAgEDEgM9GhsKMAoEBAACAhIDQAQgGiMgU2No
ZW1hIGluIHByb3RvY29sIGJ1ZmZlciBmb3JtYXQuCgoMCgUEAAICBhIDQAQSCgwKBQQAAgIB
EgNAExsKDAoFBAACAgMSA0AeHwozCgQEAAIDEgNDBB4aJiBNYXJrcyBhIFBhcnF1ZXQtZW5j
b2RlZCBkYXRhIHNvdXJjZS4KCgwKBQQAAgMGEgNDBBEKDAoFBAACAwESA0MSGQoMCgUEAAID
AxIDQxwdCjAKBAQAAgQSA0YEFhojIE1hcmtzIGFuIE9SQy1lbmNvZGVkIGRhdGEgc291cmNl
LgoKDAoFBAACBAYSA0YEDQoMCgUEAAIEARIDRg4RCgwKBQQAAgQDEgNGFBUKLwoEBAACBRID
SQQWGiIgTWFya3MgYSBDU1YtZW5jb2RlZCBkYXRhIHNvdXJjZS4KCgwKBQQAAgUGEgNJBA0K
DAoFBAACBQESA0kOEQoMCgUEAAIFAxIDSRQVYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema ===
    # Fields for PhysicalSchema
    # Field: avro Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.AvroSchema)
    # Field: thrift Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.ThriftSchema)
    # Field: protobuf Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.ProtobufSchema)
    # Field: parquet Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.ParquetSchema)
    # Field: orc Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.OrcSchema)
    # Field: csv Type: 11 (.google.cloud.datacatalog.v1.PhysicalSchema.CsvSchema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Datacatalog::V1::PhysicalSchema - Compiled Protocol Buffers messages for google/cloud/datacatalog/v1/physical_schema.proto

=head1 SYNOPSIS

    use Google::Cloud::Datacatalog::V1::PhysicalSchema;

    my $msg = Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema->new({
        avro => $avro,
        thrift => $thrift,
        protobuf => $protobuf,
        parquet => $parquet,
    });

    # Read or update a field
    my $val = $msg->avro();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/datacatalog/v1/physical_schema.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema

Native schema used by a resource represented as an entry. Used by query
engines for deserializing and parsing source data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->avro() >> / C<< $msg->avro($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::AvroSchema>)

Schema in Avro JSON format.

=item * C<< $msg->thrift() >> / C<< $msg->thrift($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ThriftSchema>)

Schema in Thrift format.

=item * C<< $msg->protobuf() >> / C<< $msg->protobuf($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ProtobufSchema>)

Schema in protocol buffer format.

=item * C<< $msg->parquet() >> / C<< $msg->parquet($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::ParquetSchema>)

Marks a Parquet-encoded data source.

=item * C<< $msg->orc() >> / C<< $msg->orc($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::OrcSchema>)

Marks an ORC-encoded data source.

=item * C<< $msg->csv() >> / C<< $msg->csv($value) >>

Type: C<Message> (L<Google::Cloud::Datacatalog::V1::PhysicalSchema::PhysicalSchema::CsvSchema>)

Marks a CSV-encoded data source.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Datacatalog::V1::PhysicalSchema::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
