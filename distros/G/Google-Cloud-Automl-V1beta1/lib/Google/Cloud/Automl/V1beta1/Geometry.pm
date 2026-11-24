package Google::Cloud::Automl::V1beta1::Geometry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZ2VvbWV0cnkucHJvdG8SG2dvb2dsZS5j
bG91ZC5hdXRvbWwudjFiZXRhMSIuChBOb3JtYWxpemVkVmVydGV4EgwKAXgYASABKAJSAXgS
DAoBeRgCIAEoAlIBeSJuCgxCb3VuZGluZ1BvbHkSXgoTbm9ybWFsaXplZF92ZXJ0aWNlcxgC
IAMoCzItLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Ob3JtYWxpemVkVmVydGV4UhJu
b3JtYWxpemVkVmVydGljZXNCmwEKH2NvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTFQ
AVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRvbWwvYXBpdjFiZXRhMS9hdXRvbWxwYjthdXRv
bWxwYsoCG0dvb2dsZVxDbG91ZFxBdXRvTWxcVjFiZXRhMeoCHkdvb2dsZTo6Q2xvdWQ6OkF1
dG9NTDo6VjFiZXRhMUqmDAoGEgQOACwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAkCggKAQgSAxMATgoJCgIICxIDEwBOCggKAQgSAxQAIgoJCgIIChID
FAAiCggKAQgSAxUAOAoJCgIIARIDFQA4CggKAQgSAxYAOAoJCgIIKRIDFgA4CggKAQgSAxcA
NwoJCgIILRIDFwA3Cs0CCgIEABIEHgAkARrAAiBBIHZlcnRleCByZXByZXNlbnRzIGEgMkQg
cG9pbnQgaW4gdGhlIGltYWdlLgogVGhlIG5vcm1hbGl6ZWQgdmVydGV4IGNvb3JkaW5hdGVz
IGFyZSBiZXR3ZWVuIDAgdG8gMSBmcmFjdGlvbnMgcmVsYXRpdmUgdG8KIHRoZSBvcmlnaW5h
bCBwbGFuZSAoaW1hZ2UsIHZpZGVvKS4gRS5nLiBpZiB0aGUgcGxhbmUgKGUuZy4gd2hvbGUg
aW1hZ2UpIHdvdWxkCiBoYXZlIHNpemUgMTAgeCAyMCB0aGVuIGEgcG9pbnQgd2l0aCBub3Jt
YWxpemVkIGNvb3JkaW5hdGVzICgwLjEsIDAuMykgd291bGQKIGJlIGF0IHRoZSBwb3NpdGlv
biAoMSwgNikgb24gdGhhdCBwbGFuZS4KCgoKAwQAARIDHggYCi8KBAQAAgASAyACDhoiIFJl
cXVpcmVkLiBIb3Jpem9udGFsIGNvb3JkaW5hdGUuCgoMCgUEAAIABRIDIAIHCgwKBQQAAgAB
EgMgCAkKDAoFBAACAAMSAyAMDQotCgQEAAIBEgMjAg4aICBSZXF1aXJlZC4gVmVydGljYWwg
Y29vcmRpbmF0ZS4KCgwKBQQAAgEFEgMjAgcKDAoFBAACAQESAyMICQoMCgUEAAIBAxIDIwwN
Cs0BCgIEARIEKQAsARrAASBBIGJvdW5kaW5nIHBvbHlnb24gb2YgYSBkZXRlY3RlZCBvYmpl
Y3Qgb24gYSBwbGFuZS4KIE9uIG91dHB1dCBib3RoIHZlcnRpY2VzIGFuZCBub3JtYWxpemVk
X3ZlcnRpY2VzIGFyZSBwcm92aWRlZC4KIFRoZSBwb2x5Z29uIGlzIGZvcm1lZCBieSBjb25u
ZWN0aW5nIHZlcnRpY2VzIGluIHRoZSBvcmRlciB0aGV5IGFyZSBsaXN0ZWQuCgoKCgMEAQES
AykIFApGCgQEAQIAEgMrAjQaOSBPdXRwdXQgb25seSAuIFRoZSBib3VuZGluZyBwb2x5Z29u
IG5vcm1hbGl6ZWQgdmVydGljZXMuCgoMCgUEAQIABBIDKwIKCgwKBQQBAgAGEgMrCxsKDAoF
BAECAAESAyscLwoMCgUEAQIAAxIDKzIzYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex ===
    # Fields for NormalizedVertex
    # Field: x Type: 2 ()
    # Field: y Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly ===
    # Fields for BoundingPoly
    # Field: normalized_vertices Type: 11 (.google.cloud.automl.v1beta1.NormalizedVertex)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Geometry - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/geometry.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Geometry;

    my $msg = Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex->new({
        x => $x,
        y => $y,
    });

    # Read or update a field
    my $val = $msg->x();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/geometry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex

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

=head2 Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly

A bounding polygon of a detected object on a plane.
On output both vertices and normalized_vertices are provided.
The polygon is formed by connecting vertices in the order they are listed.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->normalized_vertices() >> / C<< $msg->normalized_vertices($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex>)

Output only . The bounding polygon normalized vertices.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Geometry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
