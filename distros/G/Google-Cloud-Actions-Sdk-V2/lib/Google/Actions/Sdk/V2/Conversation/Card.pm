package Google::Actions::Sdk::V2::Conversation::Card;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Image };
    eval { require Google::Actions::Sdk::V2::Conversation::Link };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2Nh
cmQucHJvdG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24aPWdvb2dsZS9h
Y3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRlbnQvaW1hZ2UucHJvdG8a
PGdvb2dsZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRlbnQvbGlu
ay5wcm90byKjAgoEQ2FyZBIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSGgoIc3VidGl0bGUYAiAB
KAlSCHN1YnRpdGxlEhIKBHRleHQYAyABKAlSBHRleHQSPwoFaW1hZ2UYBCABKAsyKS5nb29n
bGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLkltYWdlUgVpbWFnZRJSCgppbWFnZV9m
aWxsGAUgASgOMjMuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5JbWFnZS5J
bWFnZUZpbGxSCWltYWdlRmlsbBJACgZidXR0b24YBiABKAsyKC5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuY29udmVyc2F0aW9uLkxpbmtSBmJ1dHRvbkKFAQomY29tLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5jb252ZXJzYXRpb25CCUNhcmRQcm90b1ABWk5nb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlvbjtjb252ZXJz
YXRpb25KrAsKBhIEDgAyAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAKwoJCgIDABIDEgBHCgkKAgMBEgMTAEYKCAoBCBIDFQBlCgkKAggLEgMVAGUKCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAqCgkKAggIEgMXACoKCAoBCBIDGAA/CgkKAggB
EgMYAD8KVgoCBAASBBsAMgEaSiBBIGJhc2ljIGNhcmQgZm9yIGRpc3BsYXlpbmcgc29tZSBp
bmZvcm1hdGlvbiwgZS5nLiBhbiBpbWFnZSBhbmQvb3IgdGV4dC4KCgoKAwQAARIDGwgMCjQK
BAQAAgASAx4CExonIE92ZXJhbGwgdGl0bGUgb2YgdGhlIGNhcmQuCiBPcHRpb25hbC4KCgwK
BQQAAgAFEgMeAggKDAoFBAACAAESAx4JDgoMCgUEAAIAAxIDHhESChgKBAQAAgESAyECFhoL
IE9wdGlvbmFsLgoKDAoFBAACAQUSAyECCAoMCgUEAAIBARIDIQkRCgwKBQQAAgEDEgMhFBUK
hAEKBAQAAgISAyYCEhp3IEJvZHkgdGV4dCBvZiB0aGUgY2FyZC4KIFN1cHBvcnRzIGEgbGlt
aXRlZCBzZXQgb2YgbWFya2Rvd24gc3ludGF4IGZvciBmb3JtYXR0aW5nLgogUmVxdWlyZWQs
IHVubGVzcyBpbWFnZSBpcyBwcmVzZW50LgoKDAoFBAACAgUSAyYCCAoMCgUEAAICARIDJgkN
CgwKBQQAAgIDEgMmEBEKUgoEBAACAxIDKgISGkUgQSBoZXJvIGltYWdlIGZvciB0aGUgY2Fy
ZC4gVGhlIGhlaWdodCBpcyBmaXhlZCB0byAxOTJkcC4KIE9wdGlvbmFsLgoKDAoFBAACAwYS
AyoCBwoMCgUEAAIDARIDKggNCgwKBQQAAgMDEgMqEBEKQQoEBAACBBIDLQIhGjQgSG93IHRo
ZSBpbWFnZSBiYWNrZ3JvdW5kIHdpbGwgYmUgZmlsbGVkLiBPcHRpb25hbC4KCgwKBQQAAgQG
EgMtAhEKDAoFBAACBAESAy0SHAoMCgUEAAIEAxIDLR8gCiEKBAQAAgUSAzECEhoUIEJ1dHRv
bi4KIE9wdGlvbmFsLgoKDAoFBAACBQYSAzECBgoMCgUEAAIFARIDMQcNCgwKBQQAAgUDEgMx
EBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Card::Card ===
    # Fields for Card
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: text Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.conversation.Image)
    # Field: image_fill Type: 14 (.google.actions.sdk.v2.conversation.Image.ImageFill)
    # Field: button Type: 11 (.google.actions.sdk.v2.conversation.Link)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Card - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/card.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Card;

    my $msg = Google::Actions::Sdk::V2::Conversation::Card::Card->new({
        title => $title,
        subtitle => $subtitle,
        text => $text,
        image => $image,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Card::Card->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/card.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Card::Card

A basic card for displaying some information, e.g. an image and/or text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Overall title of the card.
Optional.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Optional.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Body text of the card.
Supports a limited set of markdown syntax for formatting.
Required, unless image is present.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Image::Image>)

A hero image for the card. The height is fixed to 192dp.
Optional.

=item * C<< $msg->image_fill() >> / C<< $msg->image_fill($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Image::ImageFill>)

How the image background will be filled. Optional.

=item * C<< $msg->button() >> / C<< $msg->button($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Link::Link>)

Button.
Optional.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Card::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
