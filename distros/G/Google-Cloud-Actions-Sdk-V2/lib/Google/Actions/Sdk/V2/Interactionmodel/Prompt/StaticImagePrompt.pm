package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ck9nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfaW1hZ2VfcHJvbXB0LnByb3RvEi1nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50
ZXJhY3Rpb25tb2RlbC5wcm9tcHQaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i
uQEKEVN0YXRpY0ltYWdlUHJvbXB0EhUKA3VybBgBIAEoCUID4EECUgN1cmwSFQoDYWx0GAIg
ASgJQgPgQQJSA2FsdBIbCgZoZWlnaHQYAyABKAVCA+BBAVIGaGVpZ2h0EhkKBXdpZHRoGAQg
ASgFQgPgQQFSBXdpZHRoIj4KCUltYWdlRmlsbBIPCgtVTlNQRUNJRklFRBAAEggKBEdSQVkQ
ARIJCgVXSElURRACEgsKB0NST1BQRUQQA0KiAQoxY29tLmdvb2dsZS5hY3Rpb25zLnNkay52
Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdEIWU3RhdGljSW1hZ2VQcm9tcHRQcm90b1ABWlNn
b29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2lu
dGVyYWN0aW9ubW9kZWwvcHJvbXB0O3Byb21wdErrEgoGEgQOAD4BCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA2CgkKAgMAEgMSACkKCAoBCBIDFABqCgkK
AggLEgMUAGoKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA3CgkKAggIEgMWADcKCAoB
CBIDFwBKCgkKAggBEgMXAEoKLQoCBAASBBoAPgEaISBBbiBpbWFnZSBkaXNwbGF5ZWQgaW4g
dGhlIGNhcmQuCgoKCgMEAAESAxoIGQrHAQoEBAAEABIEHgIvAxq4ASBQb3NzaWJsZSBpbWFn
ZSBkaXNwbGF5IG9wdGlvbnMgZm9yIGFmZmVjdGluZyB0aGUgcHJlc2VudGF0aW9uIG9mIHRo
ZSBpbWFnZS4KIFRoaXMgc2hvdWxkIGJlIHVzZWQgZm9yIHdoZW4gdGhlIGltYWdlJ3MgYXNw
ZWN0IHJhdGlvIGRvZXMgbm90IG1hdGNoIHRoZQogaW1hZ2UgY29udGFpbmVyJ3MgYXNwZWN0
IHJhdGlvLgoKDAoFBAAEAAESAx4HEAonCgYEAAQAAgASAyAEFBoYIEltYWdlRmlsbCB1bnNw
ZWNpZmllZC4KCg4KBwQABAACAAESAyAEDwoOCgcEAAQAAgACEgMgEhMKWAoGBAAEAAIBEgMj
BA0aSSBGaWxsIHRoZSBnYXBzIGJldHdlZW4gdGhlIGltYWdlIGFuZCB0aGUgaW1hZ2UgY29u
dGFpbmVyIHdpdGggZ3JheSBiYXJzLgoKDgoHBAAEAAIBARIDIwQICg4KBwQABAACAQISAyML
DApZCgYEAAQAAgISAyYEDhpKIEZpbGwgdGhlIGdhcHMgYmV0d2VlbiB0aGUgaW1hZ2UgYW5k
IHRoZSBpbWFnZSBjb250YWluZXIgd2l0aCB3aGl0ZSBiYXJzLgoKDgoHBAAEAAICARIDJgQJ
Cg4KBwQABAACAgISAyYMDQqXAwoGBAAEAAIDEgMuBBAahwMgSW1hZ2UgaXMgc2NhbGVkIHN1
Y2ggdGhhdCB0aGUgaW1hZ2Ugd2lkdGggYW5kIGhlaWdodCBtYXRjaCBvciBleGNlZWQgdGhl
CiBjb250YWluZXIgZGltZW5zaW9ucy4gVGhpcyBtYXkgY3JvcCB0aGUgdG9wIGFuZCBib3R0
b20gb2YgdGhlIGltYWdlIGlmCiB0aGUgc2NhbGVkIGltYWdlIGhlaWdodCBpcyBncmVhdGVy
IHRoYW4gdGhlIGNvbnRhaW5lciBoZWlnaHQsIG9yIGNyb3AgdGhlCiBsZWZ0IGFuZCByaWdo
dCBvZiB0aGUgaW1hZ2UgaWYgdGhlIHNjYWxlZCBpbWFnZSB3aWR0aCBpcyBncmVhdGVyIHRo
YW4gdGhlCiBjb250YWluZXIgd2lkdGguIFRoaXMgaXMgc2ltaWxhciB0byAiWm9vbSBNb2Rl
IiBvbiBhIHdpZGVzY3JlZW4gVFYgd2hlbgogcGxheWluZyBhIDQ6MyB2aWRlby4KCg4KBwQA
BAACAwESAy4ECwoOCgcEAAQAAgMCEgMuDg8KogEKBAQAAgASAzMCOhqUASBSZXF1aXJlZC4g
VGhlIHNvdXJjZSB1cmwgb2YgdGhlIGltYWdlLiBJbWFnZXMgY2FuIGJlIEpQRywgUE5HIGFu
ZCBHSUYgKGFuaW1hdGVkIGFuZAogbm9uLWFuaW1hdGVkKS4gRm9yIGV4YW1wbGUsYGh0dHBz
Oi8vd3d3LmFnZW50eC5jb20vbG9nby5wbmdgLgoKDAoFBAACAAUSAzMCCAoMCgUEAAIAARID
MwkMCgwKBQQAAgADEgMzDxAKDAoFBAACAAgSAzMROQoPCggEAAIACJwIABIDMxI4CmwKBAQA
AgESAzcCOhpfIFJlcXVpcmVkLiBBIHRleHQgZGVzY3JpcHRpb24gb2YgdGhlIGltYWdlIHRv
IGJlIHVzZWQgZm9yIGFjY2Vzc2liaWxpdHksIGUuZy4gc2NyZWVuCiByZWFkZXJzLgoKDAoF
BAACAQUSAzcCCAoMCgUEAAIBARIDNwkMCgwKBQQAAgEDEgM3DxAKDAoFBAACAQgSAzcROQoP
CggEAAIBCJwIABIDNxI4CjsKBAQAAgISAzoCPBouIE9wdGlvbmFsLiBUaGUgaGVpZ2h0IG9m
IHRoZSBpbWFnZSBpbiBwaXhlbHMuCgoMCgUEAAICBRIDOgIHCgwKBQQAAgIBEgM6CA4KDAoF
BAACAgMSAzoREgoMCgUEAAICCBIDOhM7Cg8KCAQAAgIInAgAEgM6FDoKOgoEBAACAxIDPQI7
Gi0gT3B0aW9uYWwuIFRoZSB3aWR0aCBvZiB0aGUgaW1hZ2UgaW4gcGl4ZWxzLgoKDAoFBAAC
AwUSAz0CBwoMCgUEAAIDARIDPQgNCgwKBQQAAgMDEgM9EBEKDAoFBAACAwgSAz0SOgoPCggE
AAIDCJwIABIDPRM5YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt ===
    # Fields for StaticImagePrompt
    # Field: url Type: 9 ()
    # Field: alt Type: 9 ()
    # Field: height Type: 5 ()
    # Field: width Type: 5 ()

# Enum: StaticImagePrompt::ImageFill
our $StaticImagePrompt_UNSPECIFIED = 0;
our $StaticImagePrompt_GRAY = 1;
our $StaticImagePrompt_WHITE = 2;
our $StaticImagePrompt_CROPPED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_image_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt->new({
        url => $url,
        alt => $alt,
        height => $height,
        width => $width,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_image_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt

An image displayed in the card.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Required. The source url of the image. Images can be JPG, PNG and GIF (animated and
non-animated). For example,`https://www.agentx.com/logo.png`.

=item * C<< $msg->alt() >> / C<< $msg->alt($value) >>

Type: C<String>

Required. A text description of the image to be used for accessibility, e.g. screen
readers.

=item * C<< $msg->height() >> / C<< $msg->height($value) >>

Type: C<Int32>

Optional. The height of the image in pixels.

=item * C<< $msg->width() >> / C<< $msg->width($value) >>

Type: C<Int32>

Optional. The width of the image in pixels.

=back

=head3 Enum: StaticImagePrompt::ImageFill

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<GRAY> => C<1>

=item * C<WHITE> => C<2>

=item * C<CROPPED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
