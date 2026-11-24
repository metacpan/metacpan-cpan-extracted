package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ck5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfbGlua19wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRl
cmFjdGlvbm1vZGVsLnByb21wdCJyChBTdGF0aWNMaW5rUHJvbXB0EhIKBG5hbWUYASABKAlS
BG5hbWUSSgoEb3BlbhgCIAEoCzI2Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsLnByb21wdC5PcGVuVXJsUgRvcGVuImcKB09wZW5VcmwSEAoDdXJsGAEgASgJUgN1
cmwSSgoEaGludBgCIAEoDjI2Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1v
ZGVsLnByb21wdC5VcmxIaW50UgRoaW50KigKB1VybEhpbnQSFAoQSElOVF9VTlNQRUNJRklF
RBAAEgcKA0FNUBABQqEBCjFjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9u
bW9kZWwucHJvbXB0QhVTdGF0aWNMaW5rUHJvbXB0UHJvdG9QAVpTZ29vZ2xlLmdvbGFuZy5v
cmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVs
L3Byb21wdDtwcm9tcHRKqgwKBhIEDgAzAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1
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
ZW5zZS4KCggKAQISAxAANgoICgEIEgMSAGoKCQoCCAsSAxIAagoICgEIEgMTACIKCQoCCAoS
AxMAIgoICgEIEgMUADYKCQoCCAgSAxQANgoICgEIEgMVAEoKCQoCCAESAxUASgppCgIEABIE
GQAfARpdIERlZmluZXMgYSBsaW5rIHdoaWNoIHdpbGwgYmUgZGlzcGxheWVkIGFzIGEgc3Vn
Z2VzdGlvbiBjaGlwIGFuZCBjYW4gYmUgb3BlbmVkCiBieSB0aGUgdXNlci4KCgoKAwQAARID
GQgYCh8KBAQAAgASAxsCEhoSIE5hbWUgb2YgdGhlIGxpbmsKCgwKBQQAAgAFEgMbAggKDAoF
BAACAAESAxsJDQoMCgUEAAIAAxIDGxARCj0KBAQAAgESAx4CExowIERlZmluZXMgYmVoYXZp
b3Igd2hlbiB0aGUgdXNlciBvcGVucyB0aGUgbGluay4KCgwKBQQAAgEGEgMeAgkKDAoFBAAC
AQESAx4KDgoMCgUEAAIBAxIDHhESCjwKAgQBEgQiACkBGjAgRGVmaW5lcyBiZWhhdmlvciB3
aGVuIHRoZSB1c2VyIG9wZW5zIHRoZSBsaW5rLgoKCgoDBAEBEgMiCA8KcQoEBAECABIDJQIR
GmQgVGhlIHVybCBmaWVsZCB3aGljaCBjb3VsZCBiZSBhbnkgb2Y6CiAtIGh0dHAvaHR0cHMg
dXJscyBmb3Igb3BlbmluZyBhbiBBcHAtbGlua2VkIEFwcCBvciBhIHdlYnBhZ2UKCgwKBQQB
AgAFEgMlAggKDAoFBAECAAESAyUJDAoMCgUEAQIAAxIDJQ8QCjEKBAQBAgESAygCExokIElu
ZGljYXRlcyBhIGhpbnQgZm9yIHRoZSB1cmwgdHlwZS4KCgwKBQQBAgEGEgMoAgkKDAoFBAEC
AQESAygKDgoMCgUEAQIBAxIDKBESCisKAgUAEgQsADMBGh8gRGlmZmVyZW50IHR5cGVzIG9m
IHVybCBoaW50cy4KCgoKAwUAARIDLAUMChoKBAUAAgASAy4CFxoNIFVuc3BlY2lmaWVkCgoM
CgUFAAIAARIDLgISCgwKBQUAAgACEgMuFRYKhgEKBAUAAgESAzICChp5IFVSTCB0aGF0IHBv
aW50cyBkaXJlY3RseSB0byBBTVAgY29udGVudCwgb3IgdG8gYSBjYW5vbmljYWwgVVJMCiB3
aGljaCByZWZlcnMgdG8gQU1QIGNvbnRlbnQgdmlhIGA8bGluayByZWw9ImFtcGh0bWwiPmAu
CgoMCgUFAAIBARIDMgIFCgwKBQUAAgECEgMyCAliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt ===
    # Fields for StaticLinkPrompt
    # Field: name Type: 9 ()
    # Field: open Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.OpenUrl)

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::OpenUrl ===
    # Fields for OpenUrl
    # Field: url Type: 9 ()
    # Field: hint Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.UrlHint)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_link_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt->new({
        name => $name,
        open => $open,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_link_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::StaticLinkPrompt

Defines a link which will be displayed as a suggestion chip and can be opened
by the user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the link

=item * C<< $msg->open() >> / C<< $msg->open($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::OpenUrl>)

Defines behavior when the user opens the link.

=back

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::OpenUrl

Defines behavior when the user opens the link.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The url field which could be any of:
- http/https urls for opening an App-linked App or a webpage

=item * C<< $msg->hint() >> / C<< $msg->hint($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::UrlHint>)

Indicates a hint for the url type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticLinkPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
