package Google::Actions::Sdk::V2::Conversation::Prompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Canvas };
    eval { require Google::Actions::Sdk::V2::Conversation::Content };
    eval { require Google::Actions::Sdk::V2::Conversation::Link };
    eval { require Google::Actions::Sdk::V2::Conversation::Simple };
    eval { require Google::Actions::Sdk::V2::Conversation::Suggestion };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9wcm9tcHQucHJv
dG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24aPmdvb2dsZS9hY3Rpb25z
L3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRlbnQvY2FudmFzLnByb3RvGj9nb29n
bGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2NvbnRlbnQu
cHJvdG8aPGdvb2dsZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRl
bnQvbGluay5wcm90bxo2Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNhdGlvbi9wcm9t
cHQvc2ltcGxlLnByb3RvGjpnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3By
b21wdC9zdWdnZXN0aW9uLnByb3RvIvcDCgZQcm9tcHQSGgoGYXBwZW5kGAEgASgIQgIYAVIG
YXBwZW5kEhoKCG92ZXJyaWRlGAggASgIUghvdmVycmlkZRJNCgxmaXJzdF9zaW1wbGUYAiAB
KAsyKi5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLlNpbXBsZVILZmlyc3RT
aW1wbGUSRQoHY29udGVudBgDIAEoCzIrLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJz
YXRpb24uQ29udGVudFIHY29udGVudBJLCgtsYXN0X3NpbXBsZRgEIAEoCzIqLmdvb2dsZS5h
Y3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uU2ltcGxlUgpsYXN0U2ltcGxlElAKC3N1Z2dl
c3Rpb25zGAUgAygLMi4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5TdWdn
ZXN0aW9uUgtzdWdnZXN0aW9ucxI8CgRsaW5rGAYgASgLMiguZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLmNvbnZlcnNhdGlvbi5MaW5rUgRsaW5rEkIKBmNhbnZhcxgJIAEoCzIqLmdvb2dsZS5h
Y3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uQ2FudmFzUgZjYW52YXNChwEKJmNvbS5nb29n
bGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uQgtQcm9tcHRQcm90b1ABWk5nb29nbGUu
Z29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyL2NvbnZlcnNh
dGlvbjtjb252ZXJzYXRpb25KuRkKBhIEDgBQAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgBICgkKAgMBEgMTAEkKCQoCAwISAxQARgoJ
CgIDAxIDFQBACgkKAgMEEgMWAEQKCAoBCBIDGABlCgkKAggLEgMYAGUKCAoBCBIDGQAiCgkK
AggKEgMZACIKCAoBCBIDGgAsCgkKAggIEgMaACwKCAoBCBIDGwA/CgkKAggBEgMbAD8KLQoC
BAASBB4AUAEaISBSZXByZXNlbnQgYSByZXNwb25zZSB0byBhIHVzZXIuCgoKCgMEAAESAx4I
Dgr7BAoEBAACABIDKgImGu0EIE9wdGlvbmFsLiBNb2RlIGZvciBob3cgdGhpcyBtZXNzYWdl
cyBzaG91bGQgYmUgbWVyZ2VkIHdpdGggcHJldmlvdXNseQogZGVmaW5lZCBtZXNzYWdlcy4K
ICJmYWxzZSIgd2lsbCBjbGVhciBhbGwgcHJldmlvdXNseSBkZWZpbmVkIG1lc3NhZ2VzIChm
aXJzdCBhbmQgbGFzdAogc2ltcGxlLCBjb250ZW50LCBzdWdnZXN0aW9ucyBsaW5rIGFuZCBj
YW52YXMpIGFuZCBhZGQgbWVzc2FnZXMgZGVmaW5lZCBpbgogdGhpcyBwcm9tcHQuCiAidHJ1
ZSIgd2lsbCBhZGQgbWVzc2FnZXMgZGVmaW5lZCBpbiB0aGlzIHByb21wdCB0byBtZXNzYWdl
cyBkZWZpbmVkIGluCiBwcmV2aW91cyByZXNwb25zZXMuIFNldHRpbmcgdGhpcyBmaWVsZCB0
byAidHJ1ZSIgd2lsbCBhbHNvIGVuYWJsZSBhcHBlbmRpbmcKIHRvIHNvbWUgZmllbGRzIGlu
c2lkZSBTaW1wbGUgcHJvbXB0cywgdGhlIFN1Z2dlc3Rpb24gcHJvbXB0IGFuZCB0aGUgQ2Fu
dmFzCiBwcm9tcHQgKHBhcnQgb2YgdGhlIENvbnRlbnQgcHJvbXB0KS4gVGhlIENvbnRlbnQg
YW5kIExpbmsgbWVzc2FnZXMgd2lsbAogYWx3YXlzIGJlIG92ZXJ3cml0dGVuIGlmIGRlZmlu
ZWQgaW4gdGhlIHByb21wdC4KIERlZmF1bHQgdmFsdWUgaXMgImZhbHNlIi4KCgwKBQQAAgAF
EgMqAgYKDAoFBAACAAESAyoHDQoMCgUEAAIAAxIDKhARCgwKBQQAAgAIEgMqEiUKDQoGBAAC
AAgDEgMqEyQK7wQKBAQAAgESAzcCFBrhBCBPcHRpb25hbC4gTW9kZSBmb3IgaG93IHRoaXMg
bWVzc2FnZXMgc2hvdWxkIGJlIG1lcmdlZCB3aXRoIHByZXZpb3VzbHkKIGRlZmluZWQgbWVz
c2FnZXMuCiAidHJ1ZSIgY2xlYXJzIGFsbCBwcmV2aW91c2x5IGRlZmluZWQgbWVzc2FnZXMg
KGZpcnN0IGFuZCBsYXN0CiBzaW1wbGUsIGNvbnRlbnQsIHN1Z2dlc3Rpb25zIGxpbmsgYW5k
IGNhbnZhcykgYW5kIGFkZHMgbWVzc2FnZXMgZGVmaW5lZCBpbgogdGhpcyBwcm9tcHQuCiAi
ZmFsc2UiIGFkZHMgbWVzc2FnZXMgZGVmaW5lZCBpbiB0aGlzIHByb21wdCB0byBtZXNzYWdl
cyBkZWZpbmVkIGluCiBwcmV2aW91cyByZXNwb25zZXMuIExlYXZpbmcgdGhpcyBmaWVsZCB0
byAiZmFsc2UiIGFsc28gZW5hYmxlcwogYXBwZW5kaW5nIHRvIHNvbWUgZmllbGRzIGluc2lk
ZSBTaW1wbGUgcHJvbXB0cywgdGhlIFN1Z2dlc3Rpb25zIHByb21wdCwKIGFuZCB0aGUgQ2Fu
dmFzIHByb21wdCAocGFydCBvZiB0aGUgQ29udGVudCBwcm9tcHQpLiBUaGUgQ29udGVudCBh
bmQgTGluawogbWVzc2FnZXMgYXJlIGFsd2F5cyBvdmVyd3JpdHRlbiBpZiBkZWZpbmVkIGlu
IHRoZSBwcm9tcHQuIERlZmF1bHQKIHZhbHVlIGlzICJmYWxzZSIuCgoMCgUEAAIBBRIDNwIG
CgwKBQQAAgEBEgM3Bw8KDAoFBAACAQMSAzcSEwpACgQEAAICEgM6AhoaMyBPcHRpb25hbC4g
VGhlIGZpcnN0IHZvaWNlIGFuZCB0ZXh0LW9ubHkgcmVzcG9uc2UuCgoMCgUEAAICBhIDOgII
CgwKBQQAAgIBEgM6CRUKDAoFBAACAgMSAzoYGQpVCgQEAAIDEgM9AhYaSCBPcHRpb25hbC4g
QSBjb250ZW50IGxpa2UgYSBjYXJkLCBsaXN0IG9yIG1lZGlhIHRvIGRpc3BsYXkgdG8gdGhl
IHVzZXIuCgoMCgUEAAIDBhIDPQIJCgwKBQQAAgMBEgM9ChEKDAoFBAACAwMSAz0UFQo/CgQE
AAIEEgNAAhkaMiBPcHRpb25hbC4gVGhlIGxhc3Qgdm9pY2UgYW5kIHRleHQtb25seSByZXNw
b25zZS4KCgwKBQQAAgQGEgNAAggKDAoFBAACBAESA0AJFAoMCgUEAAIEAxIDQBcYCswCCgQE
AAIFEgNHAiYavgIgT3B0aW9uYWwuIFN1Z2dlc3Rpb25zIHRvIGJlIGRpc3BsYXllZCB0byB0
aGUgdXNlciB3aGljaCB3aWxsIGFsd2F5cyBhcHBlYXIKIGF0IHRoZSBlbmQgb2YgdGhlIHJl
c3BvbnNlLgogSWYgdGhlICJvdmVycmlkZSIgZmllbGQgaW4gdGhlIGNvbnRhaW5pbmcgcHJv
bXB0IGlzICJmYWxzZSIsIHRoZSB0aXRsZXMKIGRlZmluZWQgaW4gdGhpcyBmaWVsZCB3aWxs
IGJlIGFkZGVkIHRvIHRpdGxlcyBkZWZpbmVkIGluIGFueSBwcmV2aW91c2x5CiBkZWZpbmVk
IHN1Z2dlc3Rpb25zIHByb21wdHMgYW5kIGR1cGxpY2F0ZSB2YWx1ZXMgd2lsbCBiZSByZW1v
dmVkLgoKDAoFBAACBQQSA0cCCgoMCgUEAAIFBhIDRwsVCgwKBQQAAgUBEgNHFiEKDAoFBAAC
BQMSA0ckJQqwAQoEBAACBhIDTAIQGqIBIE9wdGlvbmFsLiBBbiBhZGRpdGlvbmFsIHN1Z2dl
c3Rpb24gY2hpcCB0aGF0IGNhbiBsaW5rIG91dCB0byB0aGUgYXNzb2NpYXRlZCBhcHAKIG9y
IHNpdGUuCiBUaGUgY2hpcCB3aWxsIGJlIHJlbmRlcmVkIHdpdGggdGhlIHRpdGxlICJPcGVu
IDxuYW1lPiIuIE1heCAyMCBjaGFycy4KCgwKBQQAAgYGEgNMAgYKDAoFBAACBgESA0wHCwoM
CgUEAAIGAxIDTA4PClkKBAQAAgcSA08CFBpMIE9wdGlvbmFsLiBSZXByZXNlbnRzIGEgSW50
ZXJhY3RpdmUgQ2FudmFzIHJlc3BvbnNlIHRvIGJlIHNlbnQgdG8gdGhlIHVzZXIuCgoMCgUE
AAIHBhIDTwIICgwKBQQAAgcBEgNPCQ8KDAoFBAACBwMSA08SE2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Prompt::Prompt ===
    # Fields for Prompt
    # Field: append Type: 8 ()
    # Field: override Type: 8 ()
    # Field: first_simple Type: 11 (.google.actions.sdk.v2.conversation.Simple)
    # Field: content Type: 11 (.google.actions.sdk.v2.conversation.Content)
    # Field: last_simple Type: 11 (.google.actions.sdk.v2.conversation.Simple)
    # Field: suggestions Type: 11 (.google.actions.sdk.v2.conversation.Suggestion)
    # Field: link Type: 11 (.google.actions.sdk.v2.conversation.Link)
    # Field: canvas Type: 11 (.google.actions.sdk.v2.conversation.Canvas)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Prompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Prompt;

    my $msg = Google::Actions::Sdk::V2::Conversation::Prompt::Prompt->new({
        append => $append,
        override => $override,
        first_simple => $first_simple,
        content => $content,
    });

    # Read or update a field
    my $val = $msg->append();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Prompt::Prompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Prompt::Prompt

Represent a response to a user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->append() >> / C<< $msg->append($value) >>

Type: C<Bool>

Optional. Mode for how this messages should be merged with previously
defined messages.
"false" will clear all previously defined messages (first and last
simple, content, suggestions link and canvas) and add messages defined in
this prompt.
"true" will add messages defined in this prompt to messages defined in
previous responses. Setting this field to "true" will also enable appending
to some fields inside Simple prompts, the Suggestion prompt and the Canvas
prompt (part of the Content prompt). The Content and Link messages will
always be overwritten if defined in the prompt.
Default value is "false".

=item * C<< $msg->override() >> / C<< $msg->override($value) >>

Type: C<Bool>

Optional. Mode for how this messages should be merged with previously
defined messages.
"true" clears all previously defined messages (first and last
simple, content, suggestions link and canvas) and adds messages defined in
this prompt.
"false" adds messages defined in this prompt to messages defined in
previous responses. Leaving this field to "false" also enables
appending to some fields inside Simple prompts, the Suggestions prompt,
and the Canvas prompt (part of the Content prompt). The Content and Link
messages are always overwritten if defined in the prompt. Default
value is "false".

=item * C<< $msg->first_simple() >> / C<< $msg->first_simple($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Simple::Simple>)

Optional. The first voice and text-only response.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Content::Content>)

Optional. A content like a card, list or media to display to the user.

=item * C<< $msg->last_simple() >> / C<< $msg->last_simple($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Simple::Simple>)

Optional. The last voice and text-only response.

=item * C<< $msg->suggestions() >> / C<< $msg->suggestions($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Suggestion::Suggestion>)

Optional. Suggestions to be displayed to the user which will always appear
at the end of the response.
If the "override" field in the containing prompt is "false", the titles
defined in this field will be added to titles defined in any previously
defined suggestions prompts and duplicate values will be removed.

=item * C<< $msg->link() >> / C<< $msg->link($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Link::Link>)

Optional. An additional suggestion chip that can link out to the associated app
or site.
The chip will be rendered with the title "Open <name>". Max 20 chars.

=item * C<< $msg->canvas() >> / C<< $msg->canvas($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Canvas::Canvas>)

Optional. Represents a Interactive Canvas response to be sent to the user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Prompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
