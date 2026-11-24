package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ck5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfbGlzdF9wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRl
cmFjdGlvbm1vZGVsLnByb21wdBpPZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9u
bW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGljX2ltYWdlX3Byb21wdC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90byL2AgoQU3RhdGljTGlzdFByb21wdBIZCgV0aXRs
ZRgBIAEoCUID4EEBUgV0aXRsZRIfCghzdWJ0aXRsZRgCIAEoCUID4EEBUghzdWJ0aXRsZRJj
CgVpdGVtcxgDIAMoCzJILmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVs
LnByb21wdC5TdGF0aWNMaXN0UHJvbXB0Lkxpc3RJdGVtQgPgQQJSBWl0ZW1zGsABCghMaXN0
SXRlbRIVCgNrZXkYASABKAlCA+BBAlIDa2V5EhkKBXRpdGxlGAIgASgJQgPgQQJSBXRpdGxl
EiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2NyaXB0aW9uElsKBWltYWdlGAQgASgL
MkAuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRp
Y0ltYWdlUHJvbXB0QgPgQQFSBWltYWdlQqEBCjFjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
LmludGVyYWN0aW9ubW9kZWwucHJvbXB0QhVTdGF0aWNMaXN0UHJvbXB0UHJvdG9QAVpTZ29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRl
cmFjdGlvbm1vZGVsL3Byb21wdDtwcm9tcHRKzw8KBhIEDgA2AQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANgoJCgIDABIDEgBZCgkKAgMBEgMTACkKCAoB
CBIDFQBqCgkKAggLEgMVAGoKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA2CgkKAggI
EgMXADYKCAoBCBIDGABKCgkKAggBEgMYAEoKRQoCBAASBBsANgEaOSBBIGNhcmQgZm9yIHBy
ZXNlbnRpbmcgYSBsaXN0IG9mIG9wdGlvbnMgdG8gc2VsZWN0IGZyb20uCgoKCgMEAAESAxsI
GAokCgQEAAMAEgQdAiwDGhYgQW4gaXRlbSBpbiB0aGUgbGlzdC4KCgwKBQQAAwABEgMdChIK
rQEKBgQAAwACABIDIAQ8Gp0BIFJlcXVpcmVkLiBUaGUgTkxVIGtleSB0aGF0IG1hdGNoZXMg
dGhlIGVudHJ5IGtleSBuYW1lIGluIHRoZSBhc3NvY2lhdGVkIHR5cGUuIFdoZW4KIGl0ZW0g
dGFwcGVkLCB0aGlzIGtleSB3aWxsIGJlIHBvc3RlZCBiYWNrIGFzIGEgc2VsZWN0IG9wdGlv
biBwYXJhbWV0ZXIuCgoOCgcEAAMAAgAFEgMgBAoKDgoHBAADAAIAARIDIAsOCg4KBwQAAwAC
AAMSAyAREgoOCgcEAAMAAgAIEgMgEzsKEQoKBAADAAIACJwIABIDIBQ6CscBCgYEAAMAAgES
AyUEPhq3ASBSZXF1aXJlZC4gVGl0bGUgb2YgdGhlIGl0ZW0uIFdoZW4gdGFwcGVkLCB0aGlz
IHRleHQgd2lsbCBiZSBwb3N0ZWQgYmFjayB0byB0aGUKIGNvbnZlcnNhdGlvbiB2ZXJiYXRp
bSBhcyBpZiB0aGUgdXNlciBoYWQgdHlwZWQgaXQuIEVhY2ggdGl0bGUgbXVzdCBiZQogdW5p
cXVlIGFtb25nIHRoZSBzZXQgb2YgaXRlbXMuCgoOCgcEAAMAAgEFEgMlBAoKDgoHBAADAAIB
ARIDJQsQCg4KBwQAAwACAQMSAyUTFAoOCgcEAAMAAgEIEgMlFT0KEQoKBAADAAIBCJwIABID
JRY8CjEKBgQAAwACAhIDKAREGiIgT3B0aW9uYWwuIEJvZHkgdGV4dCBvZiB0aGUgaXRlbS4K
Cg4KBwQAAwACAgUSAygECgoOCgcEAAMAAgIBEgMoCxYKDgoHBAADAAICAxIDKBkaCg4KBwQA
AwACAggSAygbQwoRCgoEAAMAAgIInAgAEgMoHEIKJgoGBAADAAIDEgMrBEkaFyBPcHRpb25h
bC4gSXRlbSBpbWFnZS4KCg4KBwQAAwACAwYSAysEFQoOCgcEAAMAAgMBEgMrFhsKDgoHBAAD
AAIDAxIDKx4fCg4KBwQAAwACAwgSAysgSAoRCgoEAAMAAgMInAgAEgMrIUcKKwoEBAACABID
LwI8Gh4gT3B0aW9uYWwuIFRpdGxlIG9mIHRoZSBsaXN0LgoKDAoFBAACAAUSAy8CCAoMCgUE
AAIAARIDLwkOCgwKBQQAAgADEgMvERIKDAoFBAACAAgSAy8TOwoPCggEAAIACJwIABIDLxQ6
Ci4KBAQAAgESAzICPxohIE9wdGlvbmFsLiBTdWJ0aXRsZSBvZiB0aGUgbGlzdC4KCgwKBQQA
AgEFEgMyAggKDAoFBAACAQESAzIJEQoMCgUEAAIBAxIDMhQVCgwKBQQAAgEIEgMyFj4KDwoI
BAACAQicCAASAzIXPQokCgQEAAICEgM1AkcaFyBSZXF1aXJlZC4gTGlzdCBpdGVtcy4KCgwK
BQQAAgIEEgM1AgoKDAoFBAACAgYSAzULEwoMCgUEAAICARIDNRQZCgwKBQQAAgIDEgM1HB0K
DAoFBAACAggSAzUeRgoPCggEAAICCJwIABIDNR9FYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt ===
    # Fields for StaticListPrompt
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: items Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticListPrompt.ListItem)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_list_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt->new({
        title => $title,
        subtitle => $subtitle,
        items => $items,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_list_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt

A card for presenting a list of options to select from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. Title of the list.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Optional. Subtitle of the list.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt::ListItem>)

Required. List items.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
