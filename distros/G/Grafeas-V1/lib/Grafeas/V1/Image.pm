package Grafeas::V1::Image;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChZncmFmZWFzL3YxL2ltYWdlLnByb3RvEgpncmFmZWFzLnYxIkMKBUxheWVyEhwKCWRpcmVj
dGl2ZRgBIAEoCVIJZGlyZWN0aXZlEhwKCWFyZ3VtZW50cxgCIAEoCVIJYXJndW1lbnRzIlgK
C0ZpbmdlcnByaW50EhcKB3YxX25hbWUYASABKAlSBnYxTmFtZRIXCgd2Ml9ibG9iGAIgAygJ
UgZ2MkJsb2ISFwoHdjJfbmFtZRgDIAEoCVIGdjJOYW1lImkKCUltYWdlTm90ZRIhCgxyZXNv
dXJjZV91cmwYASABKAlSC3Jlc291cmNlVXJsEjkKC2ZpbmdlcnByaW50GAIgASgLMhcuZ3Jh
ZmVhcy52MS5GaW5nZXJwcmludFILZmluZ2VycHJpbnQixgEKD0ltYWdlT2NjdXJyZW5jZRI5
CgtmaW5nZXJwcmludBgBIAEoCzIXLmdyYWZlYXMudjEuRmluZ2VycHJpbnRSC2ZpbmdlcnBy
aW50EhoKCGRpc3RhbmNlGAIgASgFUghkaXN0YW5jZRIwCgpsYXllcl9pbmZvGAMgAygLMhEu
Z3JhZmVhcy52MS5MYXllclIJbGF5ZXJJbmZvEioKEWJhc2VfcmVzb3VyY2VfdXJsGAQgASgJ
Ug9iYXNlUmVzb3VyY2VVcmxCUQoNaW8uZ3JhZmVhcy52MVABWjhnb29nbGUuZ29sYW5nLm9y
Zy9nZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3JhZmVhc6ICA0dSQUrQGAoGEgQO
AFIBCtoECgEMEgMOABIyzwQgQ29weXJpZ2h0IDIwMTkgVGhlIEdyYWZlYXMgQXV0aG9ycy4g
QWxsIHJpZ2h0cyByZXNlcnZlZC4KCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAATCggKAQgSAxIATwoJCgIICxIDEgBPCggKAQgSAxMA
IgoJCgIIChIDEwAiCggKAQgSAxQAJgoJCgIIARIDFAAmCggKAQgSAxUAIQoJCgIIJBIDFQAh
CkkKAgQAEgQYAB8BGj0gTGF5ZXIgaG9sZHMgbWV0YWRhdGEgc3BlY2lmaWMgdG8gYSBsYXll
ciBvZiBhIERvY2tlciBpbWFnZS4KCgoKAwQAARIDGAgNCqcBCgQEAAIAEgMbAhcamQEgUmVx
dWlyZWQuIFRoZSByZWNvdmVyZWQgRG9ja2VyZmlsZSBkaXJlY3RpdmUgdXNlZCB0byBjb25z
dHJ1Y3QgdGhpcyBsYXllci4KIFNlZSBodHRwczovL2RvY3MuZG9ja2VyLmNvbS9lbmdpbmUv
cmVmZXJlbmNlL2J1aWxkZXIvIGZvciBtb3JlIGluZm9ybWF0aW9uLgoKDAoFBAACAAUSAxsC
CAoMCgUEAAIAARIDGwkSCgwKBQQAAgADEgMbFRYKQwoEBAACARIDHgIXGjYgVGhlIHJlY292
ZXJlZCBhcmd1bWVudHMgdG8gdGhlIERvY2tlcmZpbGUgZGlyZWN0aXZlLgoKDAoFBAACAQUS
Ax4CCAoMCgUEAAIBARIDHgkSCgwKBQQAAgEDEgMeFRYKTgoCBAESBCIALwEaQiBBIHNldCBv
ZiBwcm9wZXJ0aWVzIHRoYXQgdW5pcXVlbHkgaWRlbnRpZnkgYSBnaXZlbiBEb2NrZXIgaW1h
Z2UuCgoKCgMEAQESAyIIEwpiCgQEAQIAEgMlAhUaVSBSZXF1aXJlZC4gVGhlIGxheWVyIElE
IG9mIHRoZSBmaW5hbCBsYXllciBpbiB0aGUgRG9ja2VyIGltYWdlJ3MgdjEKIHJlcHJlc2Vu
dGF0aW9uLgoKDAoFBAECAAUSAyUCCAoMCgUEAQIAARIDJQkQCgwKBQQBAgADEgMlExQKUwoE
BAECARIDKAIeGkYgUmVxdWlyZWQuIFRoZSBvcmRlcmVkIGxpc3Qgb2YgdjIgYmxvYnMgdGhh
dCByZXByZXNlbnQgYSBnaXZlbiBpbWFnZS4KCgwKBQQBAgEEEgMoAgoKDAoFBAECAQUSAygL
EQoMCgUEAQIBARIDKBIZCgwKBQQBAgEDEgMoHB0KxgEKBAQBAgISAy4CFRq4ASBPdXRwdXQg
b25seS4gVGhlIG5hbWUgb2YgdGhlIGltYWdlJ3MgdjIgYmxvYnMgY29tcHV0ZWQgdmlhOgog
ICBbYm90dG9tXSA6PSB2Ml9ibG9iW2JvdHRvbV0KICAgW05dIDo9IHNoYTI1Nih2Ml9ibG9i
W05dICsgIiAiICsgdjJfbmFtZVtOKzFdKQogT25seSB0aGUgbmFtZSBvZiB0aGUgZmluYWwg
YmxvYiBpcyBrZXB0LgoKDAoFBAECAgUSAy4CCAoMCgUEAQICARIDLgkQCgwKBQQBAgIDEgMu
ExQK/wEKAgQCEgQ2AD0BGvIBIEJhc2lzIGRlc2NyaWJlcyB0aGUgYmFzZSBpbWFnZSBwb3J0
aW9uIChOb3RlKSBvZiB0aGUgRG9ja2VySW1hZ2UKIHJlbGF0aW9uc2hpcC4gTGlua2VkIG9j
Y3VycmVuY2VzIGFyZSBkZXJpdmVkIGZyb20gdGhpcyBvciBhbiBlcXVpdmFsZW50IGltYWdl
CiB2aWE6CiAgIEZST00gPEJhc2lzLnJlc291cmNlX3VybD4KIE9yIGFuIGVxdWl2YWxlbnQg
cmVmZXJlbmNlLCBlLmcuLCBhIHRhZyBvZiB0aGUgcmVzb3VyY2VfdXJsLgoKCgoDBAIBEgM2
CBEKfgoEBAICABIDOQIaGnEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHJlc291cmNlX3Vy
bCBmb3IgdGhlIHJlc291cmNlIHJlcHJlc2VudGluZyB0aGUKIGJhc2lzIG9mIGFzc29jaWF0
ZWQgb2NjdXJyZW5jZSBpbWFnZXMuCgoMCgUEAgIABRIDOQIICgwKBQQCAgABEgM5CRUKDAoF
BAICAAMSAzkYGQpGCgQEAgIBEgM8Ah4aOSBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgZmlu
Z2VycHJpbnQgb2YgdGhlIGJhc2UgaW1hZ2UuCgoMCgUEAgIBBhIDPAINCgwKBQQCAgEBEgM8
DhkKDAoFBAICAQMSAzwcHQq1AQoCBAMSBEIAUgEaqAEgRGV0YWlscyBvZiB0aGUgZGVyaXZl
ZCBpbWFnZSBwb3J0aW9uIG9mIHRoZSBEb2NrZXJJbWFnZSByZWxhdGlvbnNoaXAuIFRoaXMK
IGltYWdlIHdvdWxkIGJlIHByb2R1Y2VkIGZyb20gYSBEb2NrZXJmaWxlIHdpdGggRlJPTSA8
RG9ja2VySW1hZ2UuQmFzaXMgaW4KIGF0dGFjaGVkIE5vdGU+LgoKCgoDBAMBEgNCCBcKPgoE
BAMCABIDRAIeGjEgUmVxdWlyZWQuIFRoZSBmaW5nZXJwcmludCBvZiB0aGUgZGVyaXZlZCBp
bWFnZS4KCgwKBQQDAgAGEgNEAg0KDAoFBAMCAAESA0QOGQoMCgUEAwIAAxIDRBwdCm4KBAQD
AgESA0gCFRphIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIGxheWVycyBieSB3aGljaCB0
aGlzIGltYWdlIGRpZmZlcnMgZnJvbSB0aGUKIGFzc29jaWF0ZWQgaW1hZ2UgYmFzaXMuCgoM
CgUEAwIBBRIDSAIHCgwKBQQDAgEBEgNICBAKDAoFBAMCAQMSA0gTFArRAQoEBAMCAhIDTQIg
GsMBIFRoaXMgY29udGFpbnMgbGF5ZXItc3BlY2lmaWMgbWV0YWRhdGEsIGlmIHBvcHVsYXRl
ZCBpdCBoYXMgbGVuZ3RoCiAiZGlzdGFuY2UiIGFuZCBpcyBvcmRlcmVkIHdpdGggW2Rpc3Rh
bmNlXSBiZWluZyB0aGUgbGF5ZXIgaW1tZWRpYXRlbHkKIGZvbGxvd2luZyB0aGUgYmFzZSBp
bWFnZSBhbmQgWzFdIGJlaW5nIHRoZSBmaW5hbCBsYXllci4KCgwKBQQDAgIEEgNNAgoKDAoF
BAMCAgYSA00LEAoMCgUEAwICARIDTREbCgwKBQQDAgIDEgNNHh8KXwoEBAMCAxIDUQIfGlIg
T3V0cHV0IG9ubHkuIFRoaXMgY29udGFpbnMgdGhlIGJhc2UgaW1hZ2UgVVJMIGZvciB0aGUg
ZGVyaXZlZCBpbWFnZQogb2NjdXJyZW5jZS4KCgwKBQQDAgMFEgNRAggKDAoFBAMCAwESA1EJ
GgoMCgUEAwIDAxIDUR0eYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Image::Layer ===
    # Fields for Layer
    # Field: directive Type: 9 ()
    # Field: arguments Type: 9 ()

# === Message: Grafeas::V1::Image::Fingerprint ===
    # Fields for Fingerprint
    # Field: v1_name Type: 9 ()
    # Field: v2_blob Type: 9 ()
    # Field: v2_name Type: 9 ()

# === Message: Grafeas::V1::Image::ImageNote ===
    # Fields for ImageNote
    # Field: resource_url Type: 9 ()
    # Field: fingerprint Type: 11 (.grafeas.v1.Fingerprint)

# === Message: Grafeas::V1::Image::ImageOccurrence ===
    # Fields for ImageOccurrence
    # Field: fingerprint Type: 11 (.grafeas.v1.Fingerprint)
    # Field: distance Type: 5 ()
    # Field: layer_info Type: 11 (.grafeas.v1.Layer)
    # Field: base_resource_url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Image - Compiled Protocol Buffers messages for grafeas/v1/image.proto

=head1 SYNOPSIS

    use Grafeas::V1::Image;

    my $msg = Grafeas::V1::Image::Layer->new({
        directive => $directive,
        arguments => $arguments,
    });

    # Read or update a field
    my $val = $msg->directive();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Image::Layer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/image.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Image::Layer

Layer holds metadata specific to a layer of a Docker image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->directive() >> / C<< $msg->directive($value) >>

Type: C<String>

Required. The recovered Dockerfile directive used to construct this layer.
See https://docs.docker.com/engine/reference/builder/ for more information.

=item * C<< $msg->arguments() >> / C<< $msg->arguments($value) >>

Type: C<String>

The recovered arguments to the Dockerfile directive.

=back

=head2 Grafeas::V1::Image::Fingerprint

A set of properties that uniquely identify a given Docker image.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->v1_name() >> / C<< $msg->v1_name($value) >>

Type: C<String>

Required. The layer ID of the final layer in the Docker image's v1
representation.

=item * C<< $msg->v2_blob() >> / C<< $msg->v2_blob($value) >>

Type: C<String>

Required. The ordered list of v2 blobs that represent a given image.

=item * C<< $msg->v2_name() >> / C<< $msg->v2_name($value) >>

Type: C<String>

Output only. The name of the image's v2 blobs computed via:
  [bottom] := v2_blob[bottom]
  [N] := sha256(v2_blob[N] + " " + v2_name[N+1])
Only the name of the final blob is kept.

=back

=head2 Grafeas::V1::Image::ImageNote

Basis describes the base image portion (Note) of the DockerImage
relationship. Linked occurrences are derived from this or an equivalent image
via:
  FROM <Basis.resource_url>
Or an equivalent reference, e.g., a tag of the resource_url.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_url() >> / C<< $msg->resource_url($value) >>

Type: C<String>

Required. Immutable. The resource_url for the resource representing the
basis of associated occurrence images.

=item * C<< $msg->fingerprint() >> / C<< $msg->fingerprint($value) >>

Type: C<Message> (L<Grafeas::V1::Image::Fingerprint>)

Required. Immutable. The fingerprint of the base image.

=back

=head2 Grafeas::V1::Image::ImageOccurrence

Details of the derived image portion of the DockerImage relationship. This
image would be produced from a Dockerfile with FROM <DockerImage.Basis in
attached Note>.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fingerprint() >> / C<< $msg->fingerprint($value) >>

Type: C<Message> (L<Grafeas::V1::Image::Fingerprint>)

Required. The fingerprint of the derived image.

=item * C<< $msg->distance() >> / C<< $msg->distance($value) >>

Type: C<Int32>

Output only. The number of layers by which this image differs from the
associated image basis.

=item * C<< $msg->layer_info() >> / C<< $msg->layer_info($value) >>

Type: C<Message> (L<Grafeas::V1::Image::Layer>)

This contains layer-specific metadata, if populated it has length
"distance" and is ordered with [distance] being the layer immediately
following the base image and [1] being the final layer.

=item * C<< $msg->base_resource_url() >> / C<< $msg->base_resource_url($value) >>

Type: C<String>

Output only. This contains the base image URL for the derived image
occurrence.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Image::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
