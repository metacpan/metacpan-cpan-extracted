package Google::Actions::Sdk::V2::Interactionmodel::EventHandler;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9ldmVudF9oYW5kbGVy
LnByb3RvEiZnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbBpBZ29vZ2xl
L2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0L3N0YXRpY19wcm9tcHQu
cHJvdG8i1QEKDEV2ZW50SGFuZGxlchInCg93ZWJob29rX2hhbmRsZXIYASABKAlSDndlYmhv
b2tIYW5kbGVyEmIKDXN0YXRpY19wcm9tcHQYAiABKAsyOy5nb29nbGUuYWN0aW9ucy5zZGsu
djIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3RhdGljUHJvbXB0SABSDHN0YXRpY1Byb21w
dBIuChJzdGF0aWNfcHJvbXB0X25hbWUYAyABKAlIAFIQc3RhdGljUHJvbXB0TmFtZUIICgZw
cm9tcHRCmQEKKmNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbEIR
RXZlbnRIYW5kbGVyUHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xl
YXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVyYWN0aW9ubW9kZWxK
3gkKBhIEDgAoAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
LwoJCgIDABIDEgBLCggKAQgSAxQAbQoJCgIICxIDFABtCggKAQgSAxUAIgoJCgIIChIDFQAi
CggKAQgSAxYAMgoJCgIICBIDFgAyCggKAQgSAxcAQwoJCgIIARIDFwBDCoQBCgIEABIEGwAo
ARp4IERlZmluZXMgYSBoYW5kbGVyIHRvIGJlIGV4ZWN1dGVkIGFmdGVyIGFuIGV2ZW50LiBF
eGFtcGxlcyBvZiBldmVudHMgYXJlCiBpbnRlbnQgYW5kIGNvbmRpdGlvbiBiYXNlZCBldmVu
dHMgaW4gYSBzY2VuZS4KCgoKAwQAARIDGwgUCjMKBAQAAgASAx0CHRomIE5hbWUgb2YgdGhl
IHdlYmhvb2sgaGFuZGxlciB0byBjYWxsLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkY
CgwKBQQAAgADEgMdGxwKRAoEBAAIABIEIAInAxo2IFByb21wdHMgY2FuIGVpdGhlciBiZSBp
bmxpbmVkIG9yIHJlZmVyZW5jZWQgYnkgbmFtZS4KCgwKBQQACAABEgMgCA4KXQoEBAACARID
IwRRGlAgSW5saW5lZCBzdGF0aWMgcHJvbXB0LiBDYW4gY29udGFpbiByZWZlcmVuY2VzIHRv
IHN0cmluZyByZXNvdXJjZXMgaW4KIGJ1bmRsZXMuCgoMCgUEAAIBBhIDIwQ+CgwKBQQAAgEB
EgMjP0wKDAoFBAACAQMSAyNPUAozCgQEAAICEgMmBCIaJiBOYW1lIG9mIHRoZSBzdGF0aWMg
cHJvbXB0IHRvIGludm9rZS4KCgwKBQQAAgIFEgMmBAoKDAoFBAACAgESAyYLHQoMCgUEAAIC
AxIDJiAhYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler ===
    # Fields for EventHandler
    # Field: webhook_handler Type: 9 ()
    # Field: static_prompt Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticPrompt)
    # Field: static_prompt_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::EventHandler - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/event_handler.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::EventHandler;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler->new({
        webhook_handler => $webhook_handler,
        static_prompt => $static_prompt,
        static_prompt_name => $static_prompt_name,
    });

    # Read or update a field
    my $val = $msg->webhook_handler();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/event_handler.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler

Defines a handler to be executed after an event. Examples of events are
intent and condition based events in a scene.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->webhook_handler() >> / C<< $msg->webhook_handler($value) >>

Type: C<String>

Name of the webhook handler to call.

=item * C<< $msg->static_prompt() >> / C<< $msg->static_prompt($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt>)

Inlined static prompt. Can contain references to string resources in
bundles.

=item * C<< $msg->static_prompt_name() >> / C<< $msg->static_prompt_name($value) >>

Type: C<String>

Name of the static prompt to invoke.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
