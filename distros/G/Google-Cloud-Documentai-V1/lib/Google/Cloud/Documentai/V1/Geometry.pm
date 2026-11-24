package Google::Cloud::Documentai::V1::Geometry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9nZW9tZXRyeS5wcm90bxIaZ29vZ2xlLmNs
b3VkLmRvY3VtZW50YWkudjEiJAoGVmVydGV4EgwKAXgYASABKAVSAXgSDAoBeRgCIAEoBVIB
eSIuChBOb3JtYWxpemVkVmVydGV4EgwKAXgYASABKAJSAXgSDAoBeRgCIAEoAlIBeSKtAQoM
Qm91bmRpbmdQb2x5Ej4KCHZlcnRpY2VzGAEgAygLMiIuZ29vZ2xlLmNsb3VkLmRvY3VtZW50
YWkudjEuVmVydGV4Ugh2ZXJ0aWNlcxJdChNub3JtYWxpemVkX3ZlcnRpY2VzGAIgAygLMiwu
Z29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjEuTm9ybWFsaXplZFZlcnRleFISbm9ybWFsaXpl
ZFZlcnRpY2VzQssBCh5jb20uZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFCDUdlb21ldHJ5
UHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kb2N1bWVudGFpL2FwaXYxL2RvY3VtZW50
YWlwYjtkb2N1bWVudGFpcGKqAhpHb29nbGUuQ2xvdWQuRG9jdW1lbnRBSS5WMcoCGkdvb2ds
ZVxDbG91ZFxEb2N1bWVudEFJXFYx6gIdR29vZ2xlOjpDbG91ZDo6RG9jdW1lbnRBSTo6VjFK
tg0KBhIEDgA2AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
IwoICgEIEgMSADcKCQoCCCUSAxIANwoICgEIEgMTAFUKCQoCCAsSAxMAVQoICgEIEgMUACIK
CQoCCAoSAxQAIgoICgEIEgMVAC4KCQoCCAgSAxUALgoICgEIEgMWADcKCQoCCAESAxYANwoI
CgEIEgMXADcKCQoCCCkSAxcANwoICgEIEgMYADYKCQoCCC0SAxgANgqFAQoCBAASBBwAIgEa
eSBBIHZlcnRleCByZXByZXNlbnRzIGEgMkQgcG9pbnQgaW4gdGhlIGltYWdlLgogTk9URTog
dGhlIHZlcnRleCBjb29yZGluYXRlcyBhcmUgaW4gdGhlIHNhbWUgc2NhbGUgYXMgdGhlIG9y
aWdpbmFsIGltYWdlLgoKCgoDBAABEgMcCA4KHAoEBAACABIDHgIOGg8gWCBjb29yZGluYXRl
LgoKDAoFBAACAAUSAx4CBwoMCgUEAAIAARIDHggJCgwKBQQAAgADEgMeDA0KPwoEBAACARID
IQIOGjIgWSBjb29yZGluYXRlIChzdGFydHMgZnJvbSB0aGUgdG9wIG9mIHRoZSBpbWFnZSku
CgoMCgUEAAIBBRIDIQIHCgwKBQQAAgEBEgMhCAkKDAoFBAACAQMSAyEMDQqfAQoCBAESBCcA
LQEakgEgQSB2ZXJ0ZXggcmVwcmVzZW50cyBhIDJEIHBvaW50IGluIHRoZSBpbWFnZS4KIE5P
VEU6IHRoZSBub3JtYWxpemVkIHZlcnRleCBjb29yZGluYXRlcyBhcmUgcmVsYXRpdmUgdG8g
dGhlIG9yaWdpbmFsIGltYWdlCiBhbmQgcmFuZ2UgZnJvbSAwIHRvIDEuCgoKCgMEAQESAycI
GAocCgQEAQIAEgMpAg4aDyBYIGNvb3JkaW5hdGUuCgoMCgUEAQIABRIDKQIHCgwKBQQBAgAB
EgMpCAkKDAoFBAECAAMSAykMDQo/CgQEAQIBEgMsAg4aMiBZIGNvb3JkaW5hdGUgKHN0YXJ0
cyBmcm9tIHRoZSB0b3Agb2YgdGhlIGltYWdlKS4KCgwKBQQBAgEFEgMsAgcKDAoFBAECAQES
AywICQoMCgUEAQIBAxIDLAwNCkMKAgQCEgQwADYBGjcgQSBib3VuZGluZyBwb2x5Z29uIGZv
ciB0aGUgZGV0ZWN0ZWQgaW1hZ2UgYW5ub3RhdGlvbi4KCgoKAwQCARIDMAgUCi0KBAQCAgAS
AzICHxogIFRoZSBib3VuZGluZyBwb2x5Z29uIHZlcnRpY2VzLgoKDAoFBAICAAQSAzICCgoM
CgUEAgIABhIDMgsRCgwKBQQCAgABEgMyEhoKDAoFBAICAAMSAzIdHgo4CgQEAgIBEgM1AjQa
KyBUaGUgYm91bmRpbmcgcG9seWdvbiBub3JtYWxpemVkIHZlcnRpY2VzLgoKDAoFBAICAQQS
AzUCCgoMCgUEAgIBBhIDNQsbCgwKBQQCAgEBEgM1HC8KDAoFBAICAQMSAzUyM2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::Geometry::Vertex ===
    # Fields for Vertex
    # Field: x Type: 5 ()
    # Field: y Type: 5 ()

# === Message: Google::Cloud::Documentai::V1::Geometry::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Documentai::V1::Geometry::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: vertices Type: 11 (.google.cloud.documentai.v1.Vertex)
    # Field: normalized_vertices Type: 11 (.google.cloud.documentai.v1.NormalizedVertex)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::Geometry - Compiled Protocol Buffers messages for google/cloud/documentai/v1/geometry.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::Geometry;

    my $msg = Google::Cloud::Documentai::V1::Geometry::Vertex->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::Geometry::Vertex->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/geometry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::Geometry::Vertex

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

=head2 Google::Cloud::Documentai::V1::Geometry::NormalizedVertex

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

=head2 Google::Cloud::Documentai::V1::Geometry::BoundingPoly

A bounding polygon for the detected image annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vertices() >> / C<< $msg->vertices($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Geometry::Vertex>)

The bounding polygon vertices.

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1::Geometry::NormalizedVertex>)

The bounding polygon normalized vertices.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::Geometry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
