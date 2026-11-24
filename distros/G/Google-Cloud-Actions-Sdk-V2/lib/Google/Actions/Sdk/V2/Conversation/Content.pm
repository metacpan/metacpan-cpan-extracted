package Google::Actions::Sdk::V2::Conversation::Content;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Canvas };
    eval { require Google::Actions::Sdk::V2::Conversation::Card };
    eval { require Google::Actions::Sdk::V2::Conversation::Collection };
    eval { require Google::Actions::Sdk::V2::Conversation::Image };
    eval { require Google::Actions::Sdk::V2::Conversation::List };
    eval { require Google::Actions::Sdk::V2::Conversation::Media };
    eval { require Google::Actions::Sdk::V2::Conversation::Table };
    my $descriptor_b64 = <<'EOF';
Cj9nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2Nv
bnRlbnQucHJvdG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24aPmdvb2ds
ZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRlbnQvY2FudmFzLnBy
b3RvGjxnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50
L2NhcmQucHJvdG8aQmdvb2dsZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0
L2NvbnRlbnQvY29sbGVjdGlvbi5wcm90bxo9Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2NvbnZl
cnNhdGlvbi9wcm9tcHQvY29udGVudC9pbWFnZS5wcm90bxo8Z29vZ2xlL2FjdGlvbnMvc2Rr
L3YyL2NvbnZlcnNhdGlvbi9wcm9tcHQvY29udGVudC9saXN0LnByb3RvGj1nb29nbGUvYWN0
aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L21lZGlhLnByb3RvGj1n
b29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L3RhYmxl
LnByb3RvIvkDCgdDb250ZW50Ej4KBGNhcmQYASABKAsyKC5nb29nbGUuYWN0aW9ucy5zZGsu
djIuY29udmVyc2F0aW9uLkNhcmRIAFIEY2FyZBJBCgVpbWFnZRgCIAEoCzIpLmdvb2dsZS5h
Y3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uSW1hZ2VIAFIFaW1hZ2USQQoFdGFibGUYAyAB
KAsyKS5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLlRhYmxlSABSBXRhYmxl
EkEKBW1lZGlhGAQgASgLMikuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5N
ZWRpYUgAUgVtZWRpYRJICgZjYW52YXMYBSABKAsyKi5nb29nbGUuYWN0aW9ucy5zZGsudjIu
Y29udmVyc2F0aW9uLkNhbnZhc0ICGAFIAFIGY2FudmFzElAKCmNvbGxlY3Rpb24YBiABKAsy
Li5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLkNvbGxlY3Rpb25IAFIKY29s
bGVjdGlvbhI+CgRsaXN0GAcgASgLMiguZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNh
dGlvbi5MaXN0SABSBGxpc3RCCQoHY29udGVudEKIAQomY29tLmdvb2dsZS5hY3Rpb25zLnNk
ay52Mi5jb252ZXJzYXRpb25CDENvbnRlbnRQcm90b1ABWk5nb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlvbjtjb252ZXJz
YXRpb25K+QsKBhIEDgA4AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAAKwoJCgIDABIDEgBICgkKAgMBEgMTAEYKCQoCAwISAxQATAoJCgIDAxIDFQBHCgkK
AgMEEgMWAEYKCQoCAwUSAxcARwoJCgIDBhIDGABHCggKAQgSAxoAZQoJCgIICxIDGgBlCggK
AQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALQoJCgIICBIDHAAtCggKAQgSAx0APwoJCgII
ARIDHQA/CiIKAgQAEgQgADgBGhYgQ29udGVudCB0byBiZSBzaG93bi4KCgoKAwQAARIDIAgP
ChgKBAQACAASBCICNwMaCiBDb250ZW50LgoKDAoFBAAIAAESAyIIDwocCgQEAAIAEgMkBBIa
DyBBIGJhc2ljIGNhcmQuCgoMCgUEAAIABhIDJAQICgwKBQQAAgABEgMkCQ0KDAoFBAACAAMS
AyQQEQoYCgQEAAIBEgMnBBQaCyBBbiBpbWFnZS4KCgwKBQQAAgEGEgMnBAkKDAoFBAACAQES
AycKDwoMCgUEAAIBAxIDJxITChoKBAQAAgISAyoEFBoNIFRhYmxlIGNhcmQuCgoMCgUEAAIC
BhIDKgQJCgwKBQQAAgIBEgMqCg8KDAoFBAACAgMSAyoSEwo/CgQEAAIDEgMtBBQaMiBSZXNw
b25zZSBpbmRpY2F0aW5nIGEgc2V0IG9mIG1lZGlhIHRvIGJlIHBsYXllZC4KCgwKBQQAAgMG
EgMtBAkKDAoFBAACAwESAy0KDwoMCgUEAAIDAxIDLRITCkcKBAQAAgQSAzAEKho6IEEgcmVz
cG9uc2UgdG8gYmUgdXNlZCBmb3IgaW50ZXJhY3RpdmUgY2FudmFzIGV4cGVyaWVuY2UuCgoM
CgUEAAIEBhIDMAQKCgwKBQQAAgQBEgMwCxEKDAoFBAACBAMSAzAUFQoMCgUEAAIECBIDMBYp
Cg0KBgQAAgQIAxIDMBcoCkgKBAQAAgUSAzMEHho7IEEgY2FyZCBwcmVzZW50aW5nIGEgY29s
bGVjdGlvbiBvZiBvcHRpb25zIHRvIHNlbGVjdCBmcm9tLgoKDAoFBAACBQYSAzMEDgoMCgUE
AAIFARIDMw8ZCgwKBQQAAgUDEgMzHB0KQgoEBAACBhIDNgQSGjUgQSBjYXJkIHByZXNlbnRp
bmcgYSBsaXN0IG9mIG9wdGlvbnMgdG8gc2VsZWN0IGZyb20uCgoMCgUEAAIGBhIDNgQICgwK
BQQAAgYBEgM2CQ0KDAoFBAACBgMSAzYQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Content::Content ===
    # Fields for Content
    # Field: card Type: 11 (.google.actions.sdk.v2.conversation.Card)
    # Field: image Type: 11 (.google.actions.sdk.v2.conversation.Image)
    # Field: table Type: 11 (.google.actions.sdk.v2.conversation.Table)
    # Field: media Type: 11 (.google.actions.sdk.v2.conversation.Media)
    # Field: canvas Type: 11 (.google.actions.sdk.v2.conversation.Canvas)
    # Field: collection Type: 11 (.google.actions.sdk.v2.conversation.Collection)
    # Field: list Type: 11 (.google.actions.sdk.v2.conversation.List)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Content - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/content.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Content;

    my $msg = Google::Actions::Sdk::V2::Conversation::Content::Content->new({
        card => $card,
        image => $image,
        table => $table,
        media => $media,
    });

    # Read or update a field
    my $val = $msg->card();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Content::Content->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Content::Content

Content to be shown.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->card() >> / C<< $msg->card($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Card::Card>)

A basic card.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Image::Image>)

An image.

=item * C<< $msg->table() >> / C<< $msg->table($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Table::Table>)

Table card.

=item * C<< $msg->media() >> / C<< $msg->media($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Media::Media>)

Response indicating a set of media to be played.

=item * C<< $msg->canvas() >> / C<< $msg->canvas($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Canvas::Canvas>)

A response to be used for interactive canvas experience.

=item * C<< $msg->collection() >> / C<< $msg->collection($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Collection::Collection>)

A card presenting a collection of options to select from.

=item * C<< $msg->list() >> / C<< $msg->list($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::List::List>)

A card presenting a list of options to select from.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Content::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
