package Google::Cloud::Bigquery::Storage::V1beta2::Avro;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEyL2F2cm8ucHJvdG8SJWdv
b2dsZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTIiJAoKQXZyb1NjaGVtYRIWCgZz
Y2hlbWEYASABKAlSBnNjaGVtYSJACghBdnJvUm93cxI0ChZzZXJpYWxpemVkX2JpbmFyeV9y
b3dzGAEgASgMUhRzZXJpYWxpemVkQmluYXJ5Um93c0J9Ciljb20uZ29vZ2xlLmNsb3VkLmJp
Z3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMkIJQXZyb1Byb3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20v
Z28vYmlncXVlcnkvc3RvcmFnZS9hcGl2MWJldGEyL3N0b3JhZ2VwYjtzdG9yYWdlcGJK4QcK
BhIEDgAiAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALgoI
CgEIEgMSAFoKCQoCCAsSAxIAWgoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUACoKCQoC
CAgSAxQAKgoICgEIEgMVAEIKCQoCCAESAxUAQgoaCgIEABIEGAAcARoOIEF2cm8gc2NoZW1h
LgoKCgoDBAABEgMYCBIKZQoEBAACABIDGwIUGlggSnNvbiBzZXJpYWxpemVkIHNjaGVtYSwg
YXMgZGVzY3JpYmVkIGF0CiBodHRwczovL2F2cm8uYXBhY2hlLm9yZy9kb2NzLzEuOC4xL3Nw
ZWMuaHRtbC4KCgwKBQQAAgAFEgMbAggKDAoFBAACAAESAxsJDwoMCgUEAAIAAxIDGxITChgK
AgQBEgQfACIBGgwgQXZybyByb3dzLgoKCgoDBAEBEgMfCBAKMQoEBAECABIDIQIjGiQgQmlu
YXJ5IHNlcmlhbGl6ZWQgcm93cyBpbiBhIGJsb2NrLgoKDAoFBAECAAUSAyECBwoMCgUEAQIA
ARIDIQgeCgwKBQQBAgADEgMhISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroSchema ===
    # Fields for AvroSchema
    # Field: schema Type: 9 ()

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroRows ===
    # Fields for AvroRows
    # Field: serialized_binary_rows Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta2::Avro - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta2/avro.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta2::Avro;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroSchema->new({
        schema => $schema,
    });

    # Read or update a field
    my $val = $msg->schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta2/avro.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroSchema

Avro schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->schema() >> / C<< $msg->schema($value) >>

Type: C<String>

Json serialized schema, as described at
https://avro.apache.org/docs/1.8.1/spec.html.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Avro::AvroRows

Avro rows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_binary_rows() >> / C<< $msg->serialized_binary_rows($value) >>

Type: C<Bytes>

Binary serialized rows in a block.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta2::Avro::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
