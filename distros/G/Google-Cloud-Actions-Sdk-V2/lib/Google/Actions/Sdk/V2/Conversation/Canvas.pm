package Google::Actions::Sdk::V2::Conversation::Canvas;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2Nh
bnZhcy5wcm90bxIiZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbhocZ29vZ2xl
L3Byb3RvYnVmL3N0cnVjdC5wcm90byKXAQoGQ2FudmFzEhAKA3VybBgBIAEoCVIDdXJsEioK
BGRhdGEYBCADKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVSBGRhdGESIQoMc3VwcHJlc3Nf
bWljGAMgASgIUgtzdXBwcmVzc01pYxIsChJlbmFibGVfZnVsbF9zY3JlZW4YCCABKAhSEGVu
YWJsZUZ1bGxTY3JlZW5ChwEKJmNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0
aW9uQgtDYW52YXNQcm90b1ABWk5nb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVh
cGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlvbjtjb252ZXJzYXRpb25Klg8KBhIEDgAx
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABID
EgAmCggKAQgSAxQAZQoJCgIICxIDFABlCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYA
LAoJCgIICBIDFgAsCggKAQgSAxcAPwoJCgIIARIDFwA/CqcCCgIEABIEHQAxARqaAiBSZXBy
ZXNlbnRzIGFuIEludGVyYWN0aXZlIENhbnZhcyByZXNwb25zZSB0byBiZSBzZW50IHRvIHRo
ZSB1c2VyLgogVGhpcyBjYW4gYmUgdXNlZCBpbiBjb25qdW5jdGlvbiB3aXRoIHRoZSAiZmly
c3Rfc2ltcGxlIiBmaWVsZCBpbiB0aGUKIGNvbnRhaW5pbmcgcHJvbXB0IHRvIHNwZWFrIHRv
IHRoZSB1c2VyIGluIGFkZGl0aW9uIHRvIGRpc3BsYXlpbmcgYQogaW50ZXJhY3RpdmUgY2Fu
dmFzIHJlc3BvbnNlLiBUaGUgbWF4aW11bSBzaXplIG9mIHRoZSByZXNwb25zZSBpcyA1MGsg
Ynl0ZXMuCgoKCgMEAAESAx0IDgp9CgQEAAIAEgMgAhEacCBVUkwgb2YgdGhlIGludGVyYWN0
aXZlIGNhbnZhcyB3ZWIgYXBwIHRvIGxvYWQuIElmIG5vdCBzZXQsIHRoZSB1cmwgZnJvbQog
Y3VycmVudCBhY3RpdmUgY2FudmFzIHdpbGwgYmUgcmV1c2VkLgoKDAoFBAACAAUSAyACCAoM
CgUEAAIAARIDIAkMCgwKBQQAAgADEgMgDxAKmAIKBAQAAgESAycCKhqKAiBPcHRpb25hbC4g
SlNPTiBkYXRhIHRvIGJlIHBhc3NlZCB0aHJvdWdoIHRvIHRoZSBpbW1lcnNpdmUgZXhwZXJp
ZW5jZQogd2ViIHBhZ2UgYXMgYW4gZXZlbnQuCiBJZiB0aGUgIm92ZXJyaWRlIiBmaWVsZCBp
biB0aGUgY29udGFpbmluZyBwcm9tcHQgaXMgImZhbHNlIiBkYXRhIHZhbHVlcwogZGVmaW5l
ZCBpbiB0aGlzIENhbnZhcyBwcm9tcHQgd2lsbCBiZSBhZGRlZCBhZnRlciBkYXRhIHZhbHVl
cyBkZWZpbmVkIGluCiBwcmV2aW91cyBDYW52YXMgcHJvbXB0cy4KCgwKBQQAAgEEEgMnAgoK
DAoFBAACAQYSAycLIAoMCgUEAAIBARIDJyElCgwKBQQAAgEDEgMnKCkKLgoEBAACAhIDKgIY
GiEgT3B0aW9uYWwuIERlZmF1bHQgdmFsdWU6IGZhbHNlLgoKDAoFBAACAgUSAyoCBgoMCgUE
AAICARIDKgcTCgwKBQQAAgIDEgMqFhcKrQIKBAQAAgMSAzACHhqfAiBJZiBgdHJ1ZWAgdGhl
IGNhbnZhcyBhcHBsaWNhdGlvbiBvY2N1cGllcyB0aGUgZnVsbCBzY3JlZW4gYW5kIHdvbid0
CiBoYXZlIGEgaGVhZGVyIGF0IHRoZSB0b3AuIEEgdG9hc3QgbWVzc2FnZSB3aWxsIGFsc28g
YmUgZGlzcGxheWVkIG9uIHRoZQogbG9hZGluZyBzY3JlZW4gdGhhdCBpbmNsdWRlcyB0aGUg
QWN0aW9uJ3MgZGlzcGxheSBuYW1lLCB0aGUgZGV2ZWxvcGVyJ3MKIG5hbWUsIGFuZCBpbnN0
cnVjdGlvbnMgZm9yIGV4aXRpbmcgdGhlIEFjdGlvbi4gRGVmYXVsdCB2YWx1ZTogYGZhbHNl
YC4KCgwKBQQAAgMFEgMwAgYKDAoFBAACAwESAzAHGQoMCgUEAAIDAxIDMBwdYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Canvas::Canvas ===
    # Fields for Canvas
    # Field: url Type: 9 ()
    # Field: data Type: 11 (.google.protobuf.Value)
    # Field: suppress_mic Type: 8 ()
    # Field: enable_full_screen Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Canvas - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/canvas.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Canvas;

    my $msg = Google::Actions::Sdk::V2::Conversation::Canvas::Canvas->new({
        url => $url,
        data => $data,
        suppress_mic => $suppress_mic,
        enable_full_screen => $enable_full_screen,
    });

    # Read or update a field
    my $val = $msg->url();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Canvas::Canvas->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/canvas.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Canvas::Canvas

Represents an Interactive Canvas response to be sent to the user.
This can be used in conjunction with the "first_simple" field in the
containing prompt to speak to the user in addition to displaying a
interactive canvas response. The maximum size of the response is 50k bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

URL of the interactive canvas web app to load. If not set, the url from
current active canvas will be reused.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

Optional. JSON data to be passed through to the immersive experience
web page as an event.
If the "override" field in the containing prompt is "false" data values
defined in this Canvas prompt will be added after data values defined in
previous Canvas prompts.

=item * C<< $msg->suppress_mic() >> / C<< $msg->suppress_mic($value) >>

Type: C<Bool>

Optional. Default value: false.

=item * C<< $msg->enable_full_screen() >> / C<< $msg->enable_full_screen($value) >>

Type: C<Bool>

If `true` the canvas application occupies the full screen and won't
have a header at the top. A toast message will also be displayed on the
loading screen that includes the Action's display name, the developer's
name, and instructions for exiting the Action. Default value: `false`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Canvas::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
