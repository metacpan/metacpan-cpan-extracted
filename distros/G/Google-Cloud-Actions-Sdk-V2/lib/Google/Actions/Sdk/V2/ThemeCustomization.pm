package Google::Actions::Sdk::V2::ThemeCustomization;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvYWN0aW9ucy9zZGsvdjIvdGhlbWVfY3VzdG9taXphdGlvbi5wcm90bxIVZ29v
Z2xlLmFjdGlvbnMuc2RrLnYyIrkDChJUaGVtZUN1c3RvbWl6YXRpb24SKQoQYmFja2dyb3Vu
ZF9jb2xvchgBIAEoCVIPYmFja2dyb3VuZENvbG9yEiMKDXByaW1hcnlfY29sb3IYAiABKAlS
DHByaW1hcnlDb2xvchIfCgtmb250X2ZhbWlseRgDIAEoCVIKZm9udEZhbWlseRJoChJpbWFn
ZV9jb3JuZXJfc3R5bGUYBCABKA4yOi5nb29nbGUuYWN0aW9ucy5zZGsudjIuVGhlbWVDdXN0
b21pemF0aW9uLkltYWdlQ29ybmVyU3R5bGVSEGltYWdlQ29ybmVyU3R5bGUSPAoabGFuZHNj
YXBlX2JhY2tncm91bmRfaW1hZ2UYBSABKAlSGGxhbmRzY2FwZUJhY2tncm91bmRJbWFnZRI6
Chlwb3J0cmFpdF9iYWNrZ3JvdW5kX2ltYWdlGAYgASgJUhdwb3J0cmFpdEJhY2tncm91bmRJ
bWFnZSJOChBJbWFnZUNvcm5lclN0eWxlEiIKHklNQUdFX0NPUk5FUl9TVFlMRV9VTlNQRUNJ
RklFRBAAEgoKBkNVUlZFRBABEgoKBkFOR0xFRBACQnAKGWNvbS5nb29nbGUuYWN0aW9ucy5z
ZGsudjJCF1RoZW1lQ3VzdG9taXphdGlvblByb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dl
bnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjI7c2RrSpsWCgYSBA4AUgEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB4KCAoBCBIDEgBPCgkKAggL
EgMSAE8KCAoBCBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAA4CgkKAggIEgMUADgKCAoBCBID
FQAyCgkKAggBEgMVADIKQQoCBAASBBgAUgEaNSBTdHlsZXMgYXBwbGllZCB0byBjYXJkcyB0
aGF0IGFyZSBwcmVzZW50ZWQgdG8gdXNlcnMKCgoKAwQAARIDGAgaCkcKBAQABAASBBoCIwMa
OSBEZXNjcmliZXMgaG93IHRoZSBib3JkZXJzIG9mIGltYWdlcyBzaG91bGQgYmUgcmVuZGVy
ZWQuCgoMCgUEAAQAARIDGgcXCikKBgQABAACABIDHAQnGhogVW5kZWZpbmVkIC8gVW5zcGVj
aWZpZWQuCgoOCgcEAAQAAgABEgMcBCIKDgoHBAAEAAIAAhIDHCUmCigKBgQABAACARIDHwQP
GhkgUm91bmQgY29ybmVyIGZvciBpbWFnZS4KCg4KBwQABAACAQESAx8ECgoOCgcEAAQAAgEC
EgMfDQ4KLgoGBAAEAAICEgMiBA8aHyBSZWN0YW5ndWxhciBjb3JuZXIgZm9yIGltYWdlLgoK
DgoHBAAEAAICARIDIgQKCg4KBwQABAACAgISAyINDgrDAQoEBAACABIDKQIeGrUBIEJhY2tn
cm91bmQgY29sb3Igb2YgY2FyZHMuIEFjdHMgYXMgYSBmYWxsYmFjayBpZiBgYmFja2dyb3Vu
ZF9pbWFnZWAgaXMKIG5vdCBwcm92aWRlZCBieSBkZXZlbG9wZXJzIG9yIGBiYWNrZ3JvdW5k
X2ltYWdlYCBkb2Vzbid0IGZpdCBmb3IgY2VydGFpbgogc3VyZmFjZXMuCiBFeGFtcGxlIHVz
YWdlOiAjRkFGQUZBCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCRkKDAoFBAACAAMSAykc
HQqtAQoEBAACARIDLgIbGp8BIFByaW1hcnkgdGhlbWUgY29sb3Igb2YgdGhlIEFjdGlvbiB3
aWxsIGJlIHVzZWQgdG8gc2V0IHRleHQgY29sb3Igb2YgdGl0bGUsCiBhY3Rpb24gaXRlbSBi
YWNrZ3JvdW5kIGNvbG9yIGZvciBBY3Rpb25zIG9uIEdvb2dsZSBjYXJkcy4KIEV4YW1wbGUg
dXNhZ2U6ICNGQUZBRkEKCgwKBQQAAgEFEgMuAggKDAoFBAACAQESAy4JFgoMCgUEAAIBAxID
LhkaCp8CCgQEAAICEgM9AhkakQIgVGhlIGZvbnQgZmFtaWx5IHRoYXQgd2lsbCBiZSB1c2Vk
IGZvciB0aXRsZSBvZiBjYXJkcy4KIFN1cHBvcnRlZCBmb250czoKIC0gU2FucyBTZXJpZgog
LSBTYW5zIFNlcmlmIE1lZGl1bQogLSBTYW5zIFNlcmlmIEJvbGQKIC0gU2FucyBTZXJpZiBC
bGFjawogLSBTYW5zIFNlcmlmIENvbmRlbnNlZAogLSBTYW5zIFNlcmlmIENvbmRlbnNlZCBN
ZWRpdW0KIC0gU2VyaWYKIC0gU2VyaWYgQm9sZAogLSBNb25vc3BhY2UKIC0gQ3Vyc2l2ZQog
LSBTYW5zIFNlcmlmIFNtYWxsY2FwcwoKDAoFBAACAgUSAz0CCAoMCgUEAAICARIDPQkUCgwK
BQQAAgIDEgM9FxgKkQEKBAQAAgMSA0ECKhqDASBCb3JkZXIgc3R5bGUgb2YgZm9yZWdyb3Vu
ZCBpbWFnZSBvZiBjYXJkcy4gRm9yIGV4YW1wbGUsIGNhbiBiZSBhcHBsaWVkIG9uCiB0aGUg
Zm9yZWdyb3VuZCBpbWFnZSBvZiBhIGJhc2ljIGNhcmQgb3IgY2Fyb3VzZWwgY2FyZC4KCgwK
BQQAAgMGEgNBAhIKDAoFBAACAwESA0ETJQoMCgUEAAIDAxIDQSgpCt8CCgQEAAIEEgNJAiga
0QIgTGFuZHNjYXBlIG1vZGUgKG1pbmltdW0gMTkyMHgxMjAwIHBpeGVscykuCiBUaGlzIHNo
b3VsZCBiZSBzcGVjaWZpZWQgYXMgYSByZWZlcmVuY2UgdG8gdGhlIGNvcnJlc3BvbmRpbmcg
aW1hZ2UgaW4gdGhlCiBgcmVzb3VyY2VzL2ltYWdlcy9gIGRpcmVjdG9yeS4gRWc6IGAkcmVz
b3VyY2VzLmltYWdlcy5mb29gICh3aXRob3V0IHRoZQogZXh0ZW5zaW9uKSBmb3IgaW1hZ2Ug
aW4gYHJlc291cmNlcy9pbWFnZXMvZm9vLmpwZ2AKIFdoZW4gd29ya2luZyBvbiBhIHByb2pl
Y3QgcHVsbGVkIGZyb20gQ29uc29sZSB0aGUgR29vZ2xlIG1hbmFnZWQgdXJsIHB1bGxlZAog
Y291bGQgYmUgdXNlZC4KCgwKBQQAAgQFEgNJAggKDAoFBAACBAESA0kJIwoMCgUEAAIEAxID
SSYnCt4CCgQEAAIFEgNRAica0AIgUG9ydHJhaXQgbW9kZSAobWluaW11bSAxMjAweDE5MjAg
cGl4ZWxzKS4KIFRoaXMgc2hvdWxkIGJlIHNwZWNpZmllZCBhcyBhIHJlZmVyZW5jZSB0byB0
aGUgY29ycmVzcG9uZGluZyBpbWFnZSBpbiB0aGUKIGByZXNvdXJjZXMvaW1hZ2VzL2AgZGly
ZWN0b3J5LiBFZzogYCRyZXNvdXJjZXMuaW1hZ2VzLmZvb2AgKHdpdGhvdXQgdGhlCiBleHRl
bnNpb24pIGZvciBpbWFnZSBpbiBgcmVzb3VyY2VzL2ltYWdlcy9mb28uanBnYAogV2hlbiB3
b3JraW5nIG9uIGEgcHJvamVjdCBwdWxsZWQgZnJvbSBDb25zb2xlIHRoZSBHb29nbGUgbWFu
YWdlZCB1cmwgcHVsbGVkCiBjb3VsZCBiZSB1c2VkLgoKDAoFBAACBQUSA1ECCAoMCgUEAAIF
ARIDUQkiCgwKBQQAAgUDEgNRJSZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization ===
    # Fields for ThemeCustomization
    # Field: background_color Type: 9 ()
    # Field: primary_color Type: 9 ()
    # Field: font_family Type: 9 ()
    # Field: image_corner_style Type: 14 (.google.actions.sdk.v2.ThemeCustomization.ImageCornerStyle)
    # Field: landscape_background_image Type: 9 ()
    # Field: portrait_background_image Type: 9 ()

# Enum: ThemeCustomization::ImageCornerStyle
our $ThemeCustomization_IMAGE_CORNER_STYLE_UNSPECIFIED = 0;
our $ThemeCustomization_CURVED = 1;
our $ThemeCustomization_ANGLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ThemeCustomization - Compiled Protocol Buffers messages for google/actions/sdk/v2/theme_customization.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ThemeCustomization;

    my $msg = Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization->new({
        background_color => $background_color,
        primary_color => $primary_color,
        font_family => $font_family,
        image_corner_style => $image_corner_style,
    });

    # Read or update a field
    my $val = $msg->background_color();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/theme_customization.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ThemeCustomization::ThemeCustomization

Styles applied to cards that are presented to users

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->background_color() >> / C<< $msg->background_color($value) >>

Type: C<String>

Background color of cards. Acts as a fallback if `background_image` is
not provided by developers or `background_image` doesn't fit for certain
surfaces.
Example usage: #FAFAFA

=item * C<< $msg->primary_color() >> / C<< $msg->primary_color($value) >>

Type: C<String>

Primary theme color of the Action will be used to set text color of title,
action item background color for Actions on Google cards.
Example usage: #FAFAFA

=item * C<< $msg->font_family() >> / C<< $msg->font_family($value) >>

Type: C<String>

The font family that will be used for title of cards.
Supported fonts:
- Sans Serif
- Sans Serif Medium
- Sans Serif Bold
- Sans Serif Black
- Sans Serif Condensed
- Sans Serif Condensed Medium
- Serif
- Serif Bold
- Monospace
- Cursive
- Sans Serif Smallcaps

=item * C<< $msg->image_corner_style() >> / C<< $msg->image_corner_style($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::ThemeCustomization::ImageCornerStyle>)

Border style of foreground image of cards. For example, can be applied on
the foreground image of a basic card or carousel card.

=item * C<< $msg->landscape_background_image() >> / C<< $msg->landscape_background_image($value) >>

Type: C<String>

Landscape mode (minimum 1920x1200 pixels).
This should be specified as a reference to the corresponding image in the
`resources/images/` directory. Eg: `$resources.images.foo` (without the
extension) for image in `resources/images/foo.jpg`
When working on a project pulled from Console the Google managed url pulled
could be used.

=item * C<< $msg->portrait_background_image() >> / C<< $msg->portrait_background_image($value) >>

Type: C<String>

Portrait mode (minimum 1200x1920 pixels).
This should be specified as a reference to the corresponding image in the
`resources/images/` directory. Eg: `$resources.images.foo` (without the
extension) for image in `resources/images/foo.jpg`
When working on a project pulled from Console the Google managed url pulled
could be used.

=back

=head3 Enum: ThemeCustomization::ImageCornerStyle

=over 4

=item * C<IMAGE_CORNER_STYLE_UNSPECIFIED> => C<0>

=item * C<CURVED> => C<1>

=item * C<ANGLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ThemeCustomization::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
