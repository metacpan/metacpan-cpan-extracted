package Google::Cloud::Vision::V1::Geometry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvdmlzaW9uL3YxL2dlb21ldHJ5LnByb3RvEhZnb29nbGUuY2xvdWQu
dmlzaW9uLnYxIiQKBlZlcnRleBIMCgF4GAEgASgFUgF4EgwKAXkYAiABKAVSAXkiLgoQTm9y
bWFsaXplZFZlcnRleBIMCgF4GAEgASgCUgF4EgwKAXkYAiABKAJSAXkipQEKDEJvdW5kaW5n
UG9seRI6Cgh2ZXJ0aWNlcxgBIAMoCzIeLmdvb2dsZS5jbG91ZC52aXNpb24udjEuVmVydGV4
Ugh2ZXJ0aWNlcxJZChNub3JtYWxpemVkX3ZlcnRpY2VzGAIgAygLMiguZ29vZ2xlLmNsb3Vk
LnZpc2lvbi52MS5Ob3JtYWxpemVkVmVydGV4UhJub3JtYWxpemVkVmVydGljZXMiNAoIUG9z
aXRpb24SDAoBeBgBIAEoAlIBeBIMCgF5GAIgASgCUgF5EgwKAXoYAyABKAJSAXpCbgoaY29t
Lmdvb2dsZS5jbG91ZC52aXNpb24udjFCDUdlb21ldHJ5UHJvdG9QAVo1Y2xvdWQuZ29vZ2xl
LmNvbS9nby92aXNpb24vdjIvYXBpdjEvdmlzaW9ucGI7dmlzaW9ucGL4AQGiAgRHQ1ZOSqEQ
CgYSBA4AQwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8K
CAoBCBIDEgAfCgkKAggfEgMSAB8KCAoBCBIDEwBMCgkKAggLEgMTAEwKCAoBCBIDFAAiCgkK
AggKEgMUACIKCAoBCBIDFQAuCgkKAggIEgMVAC4KCAoBCBIDFgAzCgkKAggBEgMWADMKCAoB
CBIDFwAiCgkKAggkEgMXACIKhQEKAgQAEgQbACEBGnkgQSB2ZXJ0ZXggcmVwcmVzZW50cyBh
IDJEIHBvaW50IGluIHRoZSBpbWFnZS4KIE5PVEU6IHRoZSB2ZXJ0ZXggY29vcmRpbmF0ZXMg
YXJlIGluIHRoZSBzYW1lIHNjYWxlIGFzIHRoZSBvcmlnaW5hbCBpbWFnZS4KCgoKAwQAARID
GwgOChwKBAQAAgASAx0CDhoPIFggY29vcmRpbmF0ZS4KCgwKBQQAAgAFEgMdAgcKDAoFBAAC
AAESAx0ICQoMCgUEAAIAAxIDHQwNChwKBAQAAgESAyACDhoPIFkgY29vcmRpbmF0ZS4KCgwK
BQQAAgEFEgMgAgcKDAoFBAACAQESAyAICQoMCgUEAAIBAxIDIAwNCp8BCgIEARIEJgAsARqS
ASBBIHZlcnRleCByZXByZXNlbnRzIGEgMkQgcG9pbnQgaW4gdGhlIGltYWdlLgogTk9URTog
dGhlIG5vcm1hbGl6ZWQgdmVydGV4IGNvb3JkaW5hdGVzIGFyZSByZWxhdGl2ZSB0byB0aGUg
b3JpZ2luYWwgaW1hZ2UKIGFuZCByYW5nZSBmcm9tIDAgdG8gMS4KCgoKAwQBARIDJggYChwK
BAQBAgASAygCDhoPIFggY29vcmRpbmF0ZS4KCgwKBQQBAgAFEgMoAgcKDAoFBAECAAESAygI
CQoMCgUEAQIAAxIDKAwNChwKBAQBAgESAysCDhoPIFkgY29vcmRpbmF0ZS4KCgwKBQQBAgEF
EgMrAgcKDAoFBAECAQESAysICQoMCgUEAQIBAxIDKwwNCkMKAgQCEgQvADUBGjcgQSBib3Vu
ZGluZyBwb2x5Z29uIGZvciB0aGUgZGV0ZWN0ZWQgaW1hZ2UgYW5ub3RhdGlvbi4KCgoKAwQC
ARIDLwgUCi0KBAQCAgASAzECHxogIFRoZSBib3VuZGluZyBwb2x5Z29uIHZlcnRpY2VzLgoK
DAoFBAICAAQSAzECCgoMCgUEAgIABhIDMQsRCgwKBQQCAgABEgMxEhoKDAoFBAICAAMSAzEd
Hgo4CgQEAgIBEgM0AjQaKyBUaGUgYm91bmRpbmcgcG9seWdvbiBub3JtYWxpemVkIHZlcnRp
Y2VzLgoKDAoFBAICAQQSAzQCCgoMCgUEAgIBBhIDNAsbCgwKBQQCAgEBEgM0HC8KDAoFBAIC
AQMSAzQyMwrUAQoCBAMSBDoAQwEaxwEgQSAzRCBwb3NpdGlvbiBpbiB0aGUgaW1hZ2UsIHVz
ZWQgcHJpbWFyaWx5IGZvciBGYWNlIGRldGVjdGlvbiBsYW5kbWFya3MuCiBBIHZhbGlkIFBv
c2l0aW9uIG11c3QgaGF2ZSBib3RoIHggYW5kIHkgY29vcmRpbmF0ZXMuCiBUaGUgcG9zaXRp
b24gY29vcmRpbmF0ZXMgYXJlIGluIHRoZSBzYW1lIHNjYWxlIGFzIHRoZSBvcmlnaW5hbCBp
bWFnZS4KCgoKAwQDARIDOggQChwKBAQDAgASAzwCDhoPIFggY29vcmRpbmF0ZS4KCgwKBQQD
AgAFEgM8AgcKDAoFBAMCAAESAzwICQoMCgUEAwIAAxIDPAwNChwKBAQDAgESAz8CDhoPIFkg
Y29vcmRpbmF0ZS4KCgwKBQQDAgEFEgM/AgcKDAoFBAMCAQESAz8ICQoMCgUEAwIBAxIDPwwN
CicKBAQDAgISA0ICDhoaIFogY29vcmRpbmF0ZSAob3IgZGVwdGgpLgoKDAoFBAMCAgUSA0IC
BwoMCgUEAwICARIDQggJCgwKBQQDAgIDEgNCDA1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vision::V1::Geometry::Vertex ===
    # Fields for Vertex
    # Field: x Type: 5 ()
    # Field: y Type: 5 ()

# === Message: Google::Cloud::Vision::V1::Geometry::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Vision::V1::Geometry::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: vertices Type: 11 (.google.cloud.vision.v1.Vertex)
    # Field: normalized_vertices Type: 11 (.google.cloud.vision.v1.NormalizedVertex)

# === Message: Google::Cloud::Vision::V1::Geometry::Position ===
    # Fields for Position
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()
    # Field: z Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vision::V1::Geometry - Compiled Protocol Buffers messages for google/cloud/vision/v1/geometry.proto

=head1 SYNOPSIS

    use Google::Cloud::Vision::V1::Geometry;

    my $msg = Google::Cloud::Vision::V1::Geometry::Vertex->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vision::V1::Geometry::Vertex->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vision/v1/geometry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vision::V1::Geometry::Vertex

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

Y coordinate.

=back

=head2 Google::Cloud::Vision::V1::Geometry::NormalizedVertex

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

Y coordinate.

=back

=head2 Google::Cloud::Vision::V1::Geometry::BoundingPoly

A bounding polygon for the detected image annotation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->vertices() >> / C<< $msg->vertices($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::Vertex>)

The bounding polygon vertices.

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Vision::V1::Geometry::NormalizedVertex>)

The bounding polygon normalized vertices.

=back

=head2 Google::Cloud::Vision::V1::Geometry::Position

A 3D position in the image, used primarily for Face detection landmarks.
A valid Position must have both x and y coordinates.
The position coordinates are in the same scale as the original image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Float>

X coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Float>

Y coordinate.

=item * C<< $msg->z() >> / C<< $msg->z($value) >>

Type: C<Float>

Z coordinate (or depth).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vision::V1::Geometry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
