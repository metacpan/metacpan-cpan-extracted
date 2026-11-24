package Google::Cloud::Documentai::V1beta3::Geometry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL2dlb21ldHJ5LnByb3RvEh9nb29n
bGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzIiQKBlZlcnRleBIMCgF4GAEgASgFUgF4EgwK
AXkYAiABKAVSAXkiLgoQTm9ybWFsaXplZFZlcnRleBIMCgF4GAEgASgCUgF4EgwKAXkYAiAB
KAJSAXkitwEKDEJvdW5kaW5nUG9seRJDCgh2ZXJ0aWNlcxgBIAMoCzInLmdvb2dsZS5jbG91
ZC5kb2N1bWVudGFpLnYxYmV0YTMuVmVydGV4Ugh2ZXJ0aWNlcxJiChNub3JtYWxpemVkX3Zl
cnRpY2VzGAIgAygLMjEuZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5Ob3JtYWxp
emVkVmVydGV4UhJub3JtYWxpemVkVmVydGljZXNC5AEKI2NvbS5nb29nbGUuY2xvdWQuZG9j
dW1lbnRhaS52MWJldGEzQg1HZW9tZXRyeVByb3RvUAFaQ2Nsb3VkLmdvb2dsZS5jb20vZ28v
ZG9jdW1lbnRhaS9hcGl2MWJldGEzL2RvY3VtZW50YWlwYjtkb2N1bWVudGFpcGKqAh9Hb29n
bGUuQ2xvdWQuRG9jdW1lbnRBSS5WMUJldGEzygIfR29vZ2xlXENsb3VkXERvY3VtZW50QUlc
VjFiZXRhM+oCIkdvb2dsZTo6Q2xvdWQ6OkRvY3VtZW50QUk6OlYxYmV0YTNKtg0KBhIEDgA2
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoICgEIEgMS
ADwKCQoCCCUSAxIAPAoICgEIEgMTAFoKCQoCCAsSAxMAWgoICgEIEgMUACIKCQoCCAoSAxQA
IgoICgEIEgMVAC4KCQoCCAgSAxUALgoICgEIEgMWADwKCQoCCAESAxYAPAoICgEIEgMXADwK
CQoCCCkSAxcAPAoICgEIEgMYADsKCQoCCC0SAxgAOwqFAQoCBAASBBwAIgEaeSBBIHZlcnRl
eCByZXByZXNlbnRzIGEgMkQgcG9pbnQgaW4gdGhlIGltYWdlLgogTk9URTogdGhlIHZlcnRl
eCBjb29yZGluYXRlcyBhcmUgaW4gdGhlIHNhbWUgc2NhbGUgYXMgdGhlIG9yaWdpbmFsIGlt
YWdlLgoKCgoDBAABEgMcCA4KHAoEBAACABIDHgIOGg8gWCBjb29yZGluYXRlLgoKDAoFBAAC
AAUSAx4CBwoMCgUEAAIAARIDHggJCgwKBQQAAgADEgMeDA0KPwoEBAACARIDIQIOGjIgWSBj
b29yZGluYXRlIChzdGFydHMgZnJvbSB0aGUgdG9wIG9mIHRoZSBpbWFnZSkuCgoMCgUEAAIB
BRIDIQIHCgwKBQQAAgEBEgMhCAkKDAoFBAACAQMSAyEMDQqfAQoCBAESBCcALQEakgEgQSB2
ZXJ0ZXggcmVwcmVzZW50cyBhIDJEIHBvaW50IGluIHRoZSBpbWFnZS4KIE5PVEU6IHRoZSBu
b3JtYWxpemVkIHZlcnRleCBjb29yZGluYXRlcyBhcmUgcmVsYXRpdmUgdG8gdGhlIG9yaWdp
bmFsIGltYWdlCiBhbmQgcmFuZ2UgZnJvbSAwIHRvIDEuCgoKCgMEAQESAycIGAocCgQEAQIA
EgMpAg4aDyBYIGNvb3JkaW5hdGUuCgoMCgUEAQIABRIDKQIHCgwKBQQBAgABEgMpCAkKDAoF
BAECAAMSAykMDQo/CgQEAQIBEgMsAg4aMiBZIGNvb3JkaW5hdGUgKHN0YXJ0cyBmcm9tIHRo
ZSB0b3Agb2YgdGhlIGltYWdlKS4KCgwKBQQBAgEFEgMsAgcKDAoFBAECAQESAywICQoMCgUE
AQIBAxIDLAwNCkMKAgQCEgQwADYBGjcgQSBib3VuZGluZyBwb2x5Z29uIGZvciB0aGUgZGV0
ZWN0ZWQgaW1hZ2UgYW5ub3RhdGlvbi4KCgoKAwQCARIDMAgUCi0KBAQCAgASAzICHxogIFRo
ZSBib3VuZGluZyBwb2x5Z29uIHZlcnRpY2VzLgoKDAoFBAICAAQSAzICCgoMCgUEAgIABhID
MgsRCgwKBQQCAgABEgMyEhoKDAoFBAICAAMSAzIdHgo4CgQEAgIBEgM1AjQaKyBUaGUgYm91
bmRpbmcgcG9seWdvbiBub3JtYWxpemVkIHZlcnRpY2VzLgoKDAoFBAICAQQSAzUCCgoMCgUE
AgIBBhIDNQsbCgwKBQQCAgEBEgM1HC8KDAoFBAICAQMSAzUyM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::Geometry::Vertex ===
    # Fields for Vertex
    # Field: x Type: 5 ()
    # Field: y Type: 5 ()

# === Message: Google::Cloud::Documentai::V1beta3::Geometry::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Documentai::V1beta3::Geometry::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: vertices Type: 11 (.google.cloud.documentai.v1beta3.Vertex)
    # Field: normalized_vertices Type: 11 (.google.cloud.documentai.v1beta3.NormalizedVertex)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::Geometry - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/geometry.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::Geometry;

    my $msg = Google::Cloud::Documentai::V1beta3::Geometry::Vertex->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::Geometry::Vertex->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/geometry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::Geometry::Vertex

A vertex represents a 2D point in the image.
NOTE: the vertex coordinates are in the same scale as the original image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Int32>

X coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Int32>

Y coordinate (starts from the top of the image).

=back

=head2 Google::Cloud::Documentai::V1beta3::Geometry::NormalizedVertex

A vertex represents a 2D point in the image.
NOTE: the normalized vertex coordinates are relative to the original image
and range from 0 to 1.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Float>

X coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Float>

Y coordinate (starts from the top of the image).

=back

=head2 Google::Cloud::Documentai::V1beta3::Geometry::BoundingPoly

A bounding polygon for the detected image annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vertices() >> / C<< $msg->vertices($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Geometry::Vertex>)

The bounding polygon vertices.

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Geometry::NormalizedVertex>)

The bounding polygon normalized vertices.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::Geometry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
