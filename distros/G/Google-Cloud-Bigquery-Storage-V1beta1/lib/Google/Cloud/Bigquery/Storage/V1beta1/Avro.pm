package Google::Cloud::Bigquery::Storage::V1beta1::Avro;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGExL2F2cm8ucHJvdG8SJWdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTEiJAoKQXZyb1NjaGVtYRIWCgZz
Y2hlbWEYASABKAlSBnNjaGVtYSJdCghBdnJvUm93cxI0ChZzZXJpYWxpemVkX2JpbmFyeV9y
b3dzGAEgASgMUhRzZXJpYWxpemVkQmluYXJ5Um93cxIbCglyb3dfY291bnQYAiABKANSCHJv
d0NvdW50QnsKKWNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGExQglB
dnJvUHJvdG9aQ2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvc3RvcmFnZS9hcGl2MWJl
dGExL3N0b3JhZ2VwYjtzdG9yYWdlcGJKrwgKBhIEDgAkAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAALgoICgEIEgMSAFoKCQoCCAsSAxIAWgoICgEIEgMT
ACoKCQoCCAgSAxMAKgoICgEIEgMUAEIKCQoCCAESAxQAQgoaCgIEABIEFwAbARoOIEF2cm8g
c2NoZW1hLgoKCgoDBAABEgMXCBIKZAoEBAACABIDGgIUGlcgSnNvbiBzZXJpYWxpemVkIHNj
aGVtYSwgYXMgZGVzY3JpYmVkIGF0CiBodHRwczovL2F2cm8uYXBhY2hlLm9yZy9kb2NzLzEu
OC4xL3NwZWMuaHRtbAoKDAoFBAACAAUSAxoCCAoMCgUEAAIAARIDGgkPCgwKBQQAAgADEgMa
EhMKGAoCBAESBB4AJAEaDCBBdnJvIHJvd3MuCgoKCgMEAQESAx4IEAoxCgQEAQIAEgMgAiMa
JCBCaW5hcnkgc2VyaWFsaXplZCByb3dzIGluIGEgYmxvY2suCgoMCgUEAQIABRIDIAIHCgwK
BQQBAgABEgMgCB4KDAoFBAECAAMSAyAhIgo4CgQEAQIBEgMjAhYaKyBUaGUgY291bnQgb2Yg
cm93cyBpbiB0aGUgcmV0dXJuaW5nIGJsb2NrLgoKDAoFBAECAQUSAyMCBwoMCgUEAQIBARID
IwgRCgwKBQQBAgEDEgMjFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroSchema ===
    # Fields for AvroSchema
    # Field: schema Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroRows ===
    # Fields for AvroRows
    # Field: serialized_binary_rows Type: 12 ()
    # Field: row_count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta1::Avro - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta1/avro.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta1::Avro;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroSchema->new({
        schema => $schema,
    });

    # Read or update a field
    my $val = $msg->schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta1/avro.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroSchema

Avro schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<String>

Json serialized schema, as described at
https://avro.apache.org/docs/1.8.1/spec.html

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta1::Avro::AvroRows

Avro rows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_binary_rows() >> / C<< $msg->serialized_binary_rows($value) >>

Type: C<Bytes>

Binary serialized rows in a block.

=item * C<< $msg->row_count() >> / C<< $msg->row_count($value) >>

Type: C<Int64>

The count of rows in the returning block.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta1::Avro::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
