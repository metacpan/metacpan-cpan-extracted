package Google::Actions::Sdk::V2::Conversation::Image;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2lt
YWdlLnByb3RvEiJnb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uIpkBCgVJbWFn
ZRIQCgN1cmwYASABKAlSA3VybBIQCgNhbHQYAiABKAlSA2FsdBIWCgZoZWlnaHQYAyABKAVS
BmhlaWdodBIUCgV3aWR0aBgEIAEoBVIFd2lkdGgiPgoJSW1hZ2VGaWxsEg8KC1VOU1BFQ0lG
SUVEEAASCAoER1JBWRABEgkKBVdISVRFEAISCwoHQ1JPUFBFRBADQoYBCiZjb20uZ29vZ2xl
LmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbkIKSW1hZ2VQcm90b1ABWk5nb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlv
bjtjb252ZXJzYXRpb25K6BEKBhIEDgA/AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAKwoICgEIEgMSAGUKCQoCCAsSAxIAZQoICgEIEgMTACIKCQoCCAoS
AxMAIgoICgEIEgMUACsKCQoCCAgSAxQAKwoICgEIEgMVAD8KCQoCCAESAxUAPwotCgIEABIE
GAA/ARohIEFuIGltYWdlIGRpc3BsYXllZCBpbiB0aGUgY2FyZC4KCgoKAwQAARIDGAgNCscB
CgQEAAQAEgQcAi0DGrgBIFBvc3NpYmxlIGltYWdlIGRpc3BsYXkgb3B0aW9ucyBmb3IgYWZm
ZWN0aW5nIHRoZSBwcmVzZW50YXRpb24gb2YgdGhlIGltYWdlLgogVGhpcyBzaG91bGQgYmUg
dXNlZCBmb3Igd2hlbiB0aGUgaW1hZ2UncyBhc3BlY3QgcmF0aW8gZG9lcyBub3QgbWF0Y2gg
dGhlCiBpbWFnZSBjb250YWluZXIncyBhc3BlY3QgcmF0aW8uCgoMCgUEAAQAARIDHAcQCigK
BgQABAACABIDHgQUGhkgVW5zcGVjaWZpZWQgaW1hZ2UgZmlsbC4KCg4KBwQABAACAAESAx4E
DwoOCgcEAAQAAgACEgMeEhMKWAoGBAAEAAIBEgMhBA0aSSBGaWxsIHRoZSBnYXBzIGJldHdl
ZW4gdGhlIGltYWdlIGFuZCB0aGUgaW1hZ2UgY29udGFpbmVyIHdpdGggZ3JheSBiYXJzLgoK
DgoHBAAEAAIBARIDIQQICg4KBwQABAACAQISAyELDApZCgYEAAQAAgISAyQEDhpKIEZpbGwg
dGhlIGdhcHMgYmV0d2VlbiB0aGUgaW1hZ2UgYW5kIHRoZSBpbWFnZSBjb250YWluZXIgd2l0
aCB3aGl0ZSBiYXJzLgoKDgoHBAAEAAICARIDJAQJCg4KBwQABAACAgISAyQMDQqXAwoGBAAE
AAIDEgMsBBAahwMgSW1hZ2UgaXMgc2NhbGVkIHN1Y2ggdGhhdCB0aGUgaW1hZ2Ugd2lkdGgg
YW5kIGhlaWdodCBtYXRjaCBvciBleGNlZWQgdGhlCiBjb250YWluZXIgZGltZW5zaW9ucy4g
VGhpcyBtYXkgY3JvcCB0aGUgdG9wIGFuZCBib3R0b20gb2YgdGhlIGltYWdlIGlmCiB0aGUg
c2NhbGVkIGltYWdlIGhlaWdodCBpcyBncmVhdGVyIHRoYW4gdGhlIGNvbnRhaW5lciBoZWln
aHQsIG9yIGNyb3AgdGhlCiBsZWZ0IGFuZCByaWdodCBvZiB0aGUgaW1hZ2UgaWYgdGhlIHNj
YWxlZCBpbWFnZSB3aWR0aCBpcyBncmVhdGVyIHRoYW4gdGhlCiBjb250YWluZXIgd2lkdGgu
IFRoaXMgaXMgc2ltaWxhciB0byAiWm9vbSBNb2RlIiBvbiBhIHdpZGVzY3JlZW4gVFYgd2hl
bgogcGxheWluZyBhIDQ6MyB2aWRlby4KCg4KBwQABAACAwESAywECwoOCgcEAAQAAgMCEgMs
Dg8KogEKBAQAAgASAzECERqUASBUaGUgc291cmNlIHVybCBvZiB0aGUgaW1hZ2UuIEltYWdl
cyBjYW4gYmUgSlBHLCBQTkcgYW5kIEdJRiAoYW5pbWF0ZWQgYW5kCiBub24tYW5pbWF0ZWQp
LiBGb3IgZXhhbXBsZSxgaHR0cHM6Ly93d3cuYWdlbnR4LmNvbS9sb2dvLnBuZ2AuIFJlcXVp
cmVkLgoKDAoFBAACAAUSAzECCAoMCgUEAAIAARIDMQkMCgwKBQQAAgADEgMxDxAKbQoEBAAC
ARIDNgIRGmAgQSB0ZXh0IGRlc2NyaXB0aW9uIG9mIHRoZSBpbWFnZSB0byBiZSB1c2VkIGZv
ciBhY2Nlc3NpYmlsaXR5LCBlLmcuIHNjcmVlbgogcmVhZGVycy4KIFJlcXVpcmVkLgoKDAoF
BAACAQUSAzYCCAoMCgUEAAIBARIDNgkMCgwKBQQAAgEDEgM2DxAKPAoEBAACAhIDOgITGi8g
VGhlIGhlaWdodCBvZiB0aGUgaW1hZ2UgaW4gcGl4ZWxzLgogT3B0aW9uYWwuCgoMCgUEAAIC
BRIDOgIHCgwKBQQAAgIBEgM6CA4KDAoFBAACAgMSAzoREgo7CgQEAAIDEgM+AhIaLiBUaGUg
d2lkdGggb2YgdGhlIGltYWdlIGluIHBpeGVscy4KIE9wdGlvbmFsLgoKDAoFBAACAwUSAz4C
BwoMCgUEAAIDARIDPggNCgwKBQQAAgMDEgM+EBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Image::Image ===
    # Fields for Image
    # Field: url Type: 9 ()
    # Field: alt Type: 9 ()
    # Field: height Type: 5 ()
    # Field: width Type: 5 ()

# Enum: Image::ImageFill
our $Image_UNSPECIFIED = 0;
our $Image_GRAY = 1;
our $Image_WHITE = 2;
our $Image_CROPPED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Image - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/image.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Image;

    my $msg = Google::Actions::Sdk::V2::Conversation::Image::Image->new({
        url => $url,
        alt => $alt,
        height => $height,
        width => $width,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Image::Image->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/image.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Image::Image

An image displayed in the card.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The source url of the image. Images can be JPG, PNG and GIF (animated and
non-animated). For example,`https://www.agentx.com/logo.png`. Required.

=item * C<< $msg->alt() >> / C<< $msg->alt($value) >>

Type: C<String>

A text description of the image to be used for accessibility, e.g. screen
readers.
Required.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

The height of the image in pixels.
Optional.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

The width of the image in pixels.
Optional.

=back

=head3 Enum: Image::ImageFill

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<GRAY> => C<1>

=item * C<WHITE> => C<2>

=item * C<CROPPED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Image::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
