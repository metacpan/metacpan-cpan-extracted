package Google::Cloud::Bigquery::Storage::V1beta2::Protobuf;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Descriptor };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEyL3Byb3RvYnVmLnByb3Rv
EiVnb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyGiBnb29nbGUvcHJvdG9i
dWYvZGVzY3JpcHRvci5wcm90byJaCgtQcm90b1NjaGVtYRJLChBwcm90b19kZXNjcmlwdG9y
GAEgASgLMiAuZ29vZ2xlLnByb3RvYnVmLkRlc2NyaXB0b3JQcm90b1IPcHJvdG9EZXNjcmlw
dG9yIjQKCVByb3RvUm93cxInCg9zZXJpYWxpemVkX3Jvd3MYASADKAxSDnNlcmlhbGl6ZWRS
b3dzQoEBCiljb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMkINUHJv
dG9CdWZQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3N0b3JhZ2UvYXBp
djFiZXRhMi9zdG9yYWdlcGI7c3RvcmFnZXBiSsYKCgYSBA4AJwEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAC4KCQoCAwASAxIAKgoICgEIEgMUAFoKCQoC
CAsSAxQAWgoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWAC4KCQoCCAgSAxYALgoICgEI
EgMXAEIKCQoCCAESAxcAQgpbCgIEABIEGgAfARpPIFByb3RvU2NoZW1hIGRlc2NyaWJlcyB0
aGUgc2NoZW1hIG9mIHRoZSBzZXJpYWxpemVkIHByb3RvY29sIGJ1ZmZlciBkYXRhIHJvd3Mu
CgoKCgMEAAESAxoIEwr0AQoEBAACABIDHgI3GuYBIERlc2NyaXB0b3IgZm9yIGlucHV0IG1l
c3NhZ2UuIFRoZSBkZXNjcmlwdG9yIGhhcyB0byBiZSBzZWxmIGNvbnRhaW5lZCwKIGluY2x1
ZGluZyBhbGwgdGhlIG5lc3RlZCB0eXBlcywgZXhjZXB0ZWQgZm9yIHByb3RvIGJ1ZmZlciB3
ZWxsIGtub3duIHR5cGVzCiAoaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9j
b2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYpLgoKDAoFBAACAAYS
Ax4CIQoMCgUEAAIAARIDHiIyCgwKBQQAAgADEgMeNTYKCgoCBAESBCEAJwEKCgoDBAEBEgMh
CBEKuQEKBAQBAgASAyYCJRqrASBBIHNlcXVlbmNlIG9mIHJvd3Mgc2VyaWFsaXplZCBhcyBh
IFByb3RvY29sIEJ1ZmZlci4KCiBTZWUgaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20v
cHJvdG9jb2wtYnVmZmVycy9kb2NzL292ZXJ2aWV3IGZvciBtb3JlCiBpbmZvcm1hdGlvbiBv
biBkZXNlcmlhbGl6aW5nIHRoaXMgZmllbGQuCgoMCgUEAQIABBIDJgIKCgwKBQQBAgAFEgMm
CxAKDAoFBAECAAESAyYRIAoMCgUEAQIAAxIDJiMkYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoSchema ===
    # Fields for ProtoSchema
    # Field: proto_descriptor Type: 11 (.google.protobuf.DescriptorProto)

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoRows ===
    # Fields for ProtoRows
    # Field: serialized_rows Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta2::Protobuf - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta2/protobuf.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta2::Protobuf;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoSchema->new({
        proto_descriptor => $proto_descriptor,
    });

    # Read or update a field
    my $val = $msg->proto_descriptor();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta2/protobuf.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoSchema

ProtoSchema describes the schema of the serialized protocol buffer data rows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->proto_descriptor() >> / C<< $msg->proto_descriptor($value) >>

Type: C<Message> (L<Google::Protobuf::Descriptor::DescriptorProto>)

Descriptor for input message. The descriptor has to be self contained,
including all the nested types, excepted for proto buffer well known types
(https://developers.google.com/protocol-buffers/docs/reference/google.protobuf).

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::ProtoRows

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serialized_rows() >> / C<< $msg->serialized_rows($value) >>

Type: C<Bytes>

A sequence of rows serialized as a Protocol Buffer.

See https://developers.google.com/protocol-buffers/docs/overview for more
information on deserializing this field.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta2::Protobuf::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
