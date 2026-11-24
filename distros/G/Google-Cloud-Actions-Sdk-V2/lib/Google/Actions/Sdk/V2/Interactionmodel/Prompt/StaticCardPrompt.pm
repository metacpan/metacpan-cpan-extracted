package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ck5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfY2FyZF9wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRl
cmFjdGlvbm1vZGVsLnByb21wdBpPZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9u
bW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGljX2ltYWdlX3Byb21wdC5wcm90bxpOZ29vZ2xl
L2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGlj
X2xpbmtfcHJvbXB0LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIpID
ChBTdGF0aWNDYXJkUHJvbXB0EhkKBXRpdGxlGAEgASgJQgPgQQFSBXRpdGxlEh8KCHN1YnRp
dGxlGAIgASgJQgPgQQFSCHN1YnRpdGxlEhcKBHRleHQYAyABKAlCA+BBAlIEdGV4dBJbCgVp
bWFnZRgEIAEoCzJALmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnBy
b21wdC5TdGF0aWNJbWFnZVByb21wdEID4EEBUgVpbWFnZRJuCgppbWFnZV9maWxsGAUgASgO
MkouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRp
Y0ltYWdlUHJvbXB0LkltYWdlRmlsbEID4EEBUglpbWFnZUZpbGwSXAoGYnV0dG9uGAYgASgL
Mj8uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRp
Y0xpbmtQcm9tcHRCA+BBAVIGYnV0dG9uQqEBCjFjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
LmludGVyYWN0aW9ubW9kZWwucHJvbXB0QhVTdGF0aWNDYXJkUHJvbXB0UHJvdG9QAVpTZ29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRl
cmFjdGlvbm1vZGVsL3Byb21wdDtwcm9tcHRKtw0KBhIEDgAvAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANgoJCgIDABIDEgBZCgkKAgMBEgMTAFgKCQoC
AwISAxQAKQoICgEIEgMWAGoKCQoCCAsSAxYAagoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEI
EgMYADYKCQoCCAgSAxgANgoICgEIEgMZAEoKCQoCCAESAxkASgpWCgIEABIEHAAvARpKIEEg
YmFzaWMgY2FyZCBmb3IgZGlzcGxheWluZyBzb21lIGluZm9ybWF0aW9uLCBlLmcuIGFuIGlt
YWdlIGFuZC9vciB0ZXh0LgoKCgoDBAABEgMcCBgKMwoEBAACABIDHgI8GiYgT3B0aW9uYWwu
IE92ZXJhbGwgdGl0bGUgb2YgdGhlIGNhcmQuCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMe
CQ4KDAoFBAACAAMSAx4REgoMCgUEAAIACBIDHhM7Cg8KCAQAAgAInAgAEgMeFDoKLgoEBAAC
ARIDIQI/GiEgT3B0aW9uYWwuIFN1YnRpdGxlIG9mIHRoZSBjYXJkLgoKDAoFBAACAQUSAyEC
CAoMCgUEAAIBARIDIQkRCgwKBQQAAgEDEgMhFBUKDAoFBAACAQgSAyEWPgoPCggEAAIBCJwI
ABIDIRc9CpMBCgQEAAICEgMlAjsahQEgUmVxdWlyZWQuIEJvZHkgdGV4dCBvZiB0aGUgY2Fy
ZCB3aGljaCBpcyBuZWVkZWQgdW5sZXNzIGltYWdlIGlzIHByZXNlbnQuIFN1cHBvcnRzIGEK
IGxpbWl0ZWQgc2V0IG9mIG1hcmtkb3duIHN5bnRheCBmb3IgZm9ybWF0dGluZy4KCgwKBQQA
AgIFEgMlAggKDAoFBAACAgESAyUJDQoMCgUEAAICAxIDJRARCgwKBQQAAgIIEgMlEjoKDwoI
BAACAgicCAASAyUTOQpRCgQEAAIDEgMoAkcaRCBPcHRpb25hbC4gQSBoZXJvIGltYWdlIGZv
ciB0aGUgY2FyZC4gVGhlIGhlaWdodCBpcyBmaXhlZCB0byAxOTJkcC4KCgwKBQQAAgMGEgMo
AhMKDAoFBAACAwESAygUGQoMCgUEAAIDAxIDKBwdCgwKBQQAAgMIEgMoHkYKDwoIBAACAwic
CAASAygfRQpBCgQEAAIEEgMrAlYaNCBPcHRpb25hbC4gSG93IHRoZSBpbWFnZSBiYWNrZ3Jv
dW5kIHdpbGwgYmUgZmlsbGVkLgoKDAoFBAACBAYSAysCHQoMCgUEAAIEARIDKx4oCgwKBQQA
AgQDEgMrKywKDAoFBAACBAgSAystVQoPCggEAAIECJwIABIDKy5UCkQKBAQAAgUSAy4CRxo3
IE9wdGlvbmFsLiBBIGNsaWNrYWJsZSBidXR0b24gdG8gYmUgc2hvd24gaW4gdGhlIENhcmQu
CgoMCgUEAAIFBhIDLgISCgwKBQQAAgUBEgMuExkKDAoFBAACBQMSAy4cHQoMCgUEAAIFCBID
Lh5GCg8KCAQAAgUInAgAEgMuH0ViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt ===
    # Fields for StaticCardPrompt
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: text Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt)
    # Field: image_fill Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt.ImageFill)
    # Field: button Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticLinkPrompt)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_card_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt->new({
        title => $title,
        subtitle => $subtitle,
        text => $text,
        image => $image,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_card_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt

A basic card for displaying some information, e.g. an image and/or text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. Overall title of the card.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Optional. Subtitle of the card.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. Body text of the card which is needed unless image is present. Supports a
limited set of markdown syntax for formatting.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt>)

Optional. A hero image for the card. The height is fixed to 192dp.

=item * C<< $msg->image_fill() >> / C<< $msg->image_fill($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::ImageFill>)

Optional. How the image background will be filled.

=item * C<< $msg->button() >> / C<< $msg->button($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt>)

Optional. A clickable button to be shown in the Card.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
