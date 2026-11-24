package Google::Cloud::Automl::V1::Geometry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvYXV0b21sL3YxL2dlb21ldHJ5LnByb3RvEhZnb29nbGUuY2xvdWQu
YXV0b21sLnYxIi4KEE5vcm1hbGl6ZWRWZXJ0ZXgSDAoBeBgBIAEoAlIBeBIMCgF5GAIgASgC
UgF5ImkKDEJvdW5kaW5nUG9seRJZChNub3JtYWxpemVkX3ZlcnRpY2VzGAIgAygLMiguZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MS5Ob3JtYWxpemVkVmVydGV4UhJub3JtYWxpemVkVmVydGlj
ZXNCoAEKGmNvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYxUAFaMmNsb3VkLmdvb2dsZS5jb20v
Z28vYXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9tbHBiqgIWR29vZ2xlLkNsb3VkLkF1dG9N
TC5WMcoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHqAhlHb29nbGU6OkNsb3VkOjpBdXRvTUw6
OlYxSrsMCgYSBA4ALAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQAB8KCAoBCBIDEgAzCgkKAgglEgMSADMKCAoBCBIDEwBJCgkKAggLEgMTAEkKCAoBCBID
FAAiCgkKAggKEgMUACIKCAoBCBIDFQAzCgkKAggBEgMVADMKCAoBCBIDFgAzCgkKAggpEgMW
ADMKCAoBCBIDFwAyCgkKAggtEgMXADIKzQIKAgQAEgQeACQBGsACIEEgdmVydGV4IHJlcHJl
c2VudHMgYSAyRCBwb2ludCBpbiB0aGUgaW1hZ2UuCiBUaGUgbm9ybWFsaXplZCB2ZXJ0ZXgg
Y29vcmRpbmF0ZXMgYXJlIGJldHdlZW4gMCB0byAxIGZyYWN0aW9ucyByZWxhdGl2ZSB0bwog
dGhlIG9yaWdpbmFsIHBsYW5lIChpbWFnZSwgdmlkZW8pLiBFLmcuIGlmIHRoZSBwbGFuZSAo
ZS5nLiB3aG9sZSBpbWFnZSkgd291bGQKIGhhdmUgc2l6ZSAxMCB4IDIwIHRoZW4gYSBwb2lu
dCB3aXRoIG5vcm1hbGl6ZWQgY29vcmRpbmF0ZXMgKDAuMSwgMC4zKSB3b3VsZAogYmUgYXQg
dGhlIHBvc2l0aW9uICgxLCA2KSBvbiB0aGF0IHBsYW5lLgoKCgoDBAABEgMeCBgKLwoEBAAC
ABIDIAIOGiIgUmVxdWlyZWQuIEhvcml6b250YWwgY29vcmRpbmF0ZS4KCgwKBQQAAgAFEgMg
AgcKDAoFBAACAAESAyAICQoMCgUEAAIAAxIDIAwNCi0KBAQAAgESAyMCDhogIFJlcXVpcmVk
LiBWZXJ0aWNhbCBjb29yZGluYXRlLgoKDAoFBAACAQUSAyMCBwoMCgUEAAIBARIDIwgJCgwK
BQQAAgEDEgMjDA0KzQEKAgQBEgQpACwBGsABIEEgYm91bmRpbmcgcG9seWdvbiBvZiBhIGRl
dGVjdGVkIG9iamVjdCBvbiBhIHBsYW5lLgogT24gb3V0cHV0IGJvdGggdmVydGljZXMgYW5k
IG5vcm1hbGl6ZWRfdmVydGljZXMgYXJlIHByb3ZpZGVkLgogVGhlIHBvbHlnb24gaXMgZm9y
bWVkIGJ5IGNvbm5lY3RpbmcgdmVydGljZXMgaW4gdGhlIG9yZGVyIHRoZXkgYXJlIGxpc3Rl
ZC4KCgoKAwQBARIDKQgUCkYKBAQBAgASAysCNBo5IE91dHB1dCBvbmx5IC4gVGhlIGJvdW5k
aW5nIHBvbHlnb24gbm9ybWFsaXplZCB2ZXJ0aWNlcy4KCgwKBQQBAgAEEgMrAgoKDAoFBAEC
AAYSAysLGwoMCgUEAQIAARIDKxwvCgwKBQQBAgADEgMrMjNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Geometry::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Automl::V1::Geometry::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: normalized_vertices Type: 11 (.google.cloud.automl.v1.NormalizedVertex)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Geometry - Compiled Protocol Buffers messages for google/cloud/automl/v1/geometry.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Geometry;

    my $msg = Google::Cloud::Automl::V1::Geometry::NormalizedVertex->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Geometry::NormalizedVertex->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/geometry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Geometry::NormalizedVertex

A vertex represents a 2D point in the image.
The normalized vertex coordinates are between 0 to 1 fractions relative to
the original plane (image, video). E.g. if the plane (e.g. whole image) would
have size 10 x 20 then a point with normalized coordinates (0.1, 0.3) would
be at the position (1, 6) on that plane.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->x() >> / C<< $msg->x($value) >>

Type: C<Float>

Required. Horizontal coordinate.

=item * C<< $msg->y() >> / C<< $msg->y($value) >>

Type: C<Float>

Required. Vertical coordinate.

=back

=head2 Google::Cloud::Automl::V1::Geometry::BoundingPoly

A bounding polygon of a detected object on a plane.
On output both vertices and normalized_vertices are provided.
The polygon is formed by connecting vertices in the order they are listed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Geometry::NormalizedVertex>)

Output only . The bounding polygon normalized vertices.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Geometry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
