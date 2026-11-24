package Google::Actions::Sdk::V2::Interactionmodel::Scene;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::EventHandler };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::IntentEvent };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Slot };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9zY2VuZS5wcm90bxIm
Z29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwaPmdvb2dsZS9hY3Rpb25z
L3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL2NvbmRpdGlvbmFsX2V2ZW50LnByb3RvGjpnb29n
bGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9ldmVudF9oYW5kbGVyLnByb3Rv
Gjlnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9pbnRlbnRfZXZlbnQu
cHJvdG8aMWdvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3Nsb3QucHJv
dG8ivQMKBVNjZW5lEk8KCG9uX2VudGVyGAEgASgLMjQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
LmludGVyYWN0aW9ubW9kZWwuRXZlbnRIYW5kbGVyUgdvbkVudGVyElgKDWludGVudF9ldmVu
dHMYAiADKAsyMy5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5JbnRl
bnRFdmVudFIMaW50ZW50RXZlbnRzEmcKEmNvbmRpdGlvbmFsX2V2ZW50cxgDIAMoCzI4Lmdv
b2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLkNvbmRpdGlvbmFsRXZlbnRS
EWNvbmRpdGlvbmFsRXZlbnRzEkIKBXNsb3RzGAQgAygLMiwuZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLmludGVyYWN0aW9ubW9kZWwuU2xvdFIFc2xvdHMSXAoPb25fc2xvdF91cGRhdGVkGAUg
ASgLMjQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwuRXZlbnRIYW5k
bGVyUg1vblNsb3RVcGRhdGVkQpIBCipjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVy
YWN0aW9ubW9kZWxCClNjZW5lUHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8v
Z29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVyYWN0aW9u
bW9kZWxKxRIKBhIEDgA7AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
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
AQISAxAALwoJCgIDABIDEgBICgkKAgMBEgMTAEQKCQoCAwISAxQAQwoJCgIDAxIDFQA7CggK
AQgSAxcAbQoJCgIICxIDFwBtCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAKwoJCgII
CBIDGQArCggKAQgSAxoAQwoJCgIIARIDGgBDCvIBCgIEABIEIAA7ARrlASBTY2VuZSBpcyB0
aGUgYmFzaWMgdW5pdCBvZiBjb250cm9sIGZsb3cgd2hlbiBkZXNpZ25pbmcgYSBjb252ZXJz
YXRpb24uIFRoZXkKIGNhbiBiZSBjaGFpbmVkIHRvZ2V0aGVyIHdpdGggb3RoZXIgc2NlbmVz
LCBnZW5lcmF0ZSBwcm9tcHRzIGZvciB0aGUgZW5kIHVzZXIsCiBhbmQgZGVmaW5lIHNsb3Rz
LgogVGhlIHNjZW5lIG5hbWUgaXMgc3BlY2lmaWVkIGluIHRoZSBuYW1lIG9mIHRoZSBmaWxl
LgoKCgoDBAABEgMgCA0KRAoEBAACABIDIgIcGjcgSGFuZGxlciB0byBpbnZva2Ugd2hlbiB0
cmFuc2l0aW9uaW5nIGludG8gdGhpcyBzY2VuZS4KCgwKBQQAAgAGEgMiAg4KDAoFBAACAAES
AyIPFwoMCgUEAAIAAxIDIhobCosDCgQEAAIBEgMqAika/QIgVGhlIGxpc3Qgb2YgZXZlbnRz
IHRoYXQgdHJpZ2dlciBiYXNlZCBvbiBpbnRlbnRzLiBUaGVzZSBldmVudHMgY2FuCiBiZSB0
cmlnZ2VyZWQgYXQgYW55IHRpbWUgYWZ0ZXIgdGhlIG9uX2xvYWQgSGFuZGxlciBoYXMgYmVl
biBjYWxsZWQuCiBJbXBvcnRhbnQgLSB0aGVzZSBldmVudHMgZGVmaW5lIHRoZSBzZXQgb2Yg
aW50ZW50cyB3aGljaCBhcmUgc2NvcGVkIHRvCiB0aGlzIHNjZW5lIGFuZCB3aWxsIHRha2Ug
cHJlY2VkZW5jZSBvdmVyIGFueSBnbG9iYWxseSBkZWZpbmVkIGV2ZW50cyB0aGF0CiBoYXZl
IHRoZSBzYW1lIGludGVudHMgb3IgdGhlaXIgdHJpZ2dlcmluZyBwaHJhc2VzLiBJbnRlbnQg
bmFtZXMgbXVzdCBiZQogdW5pcXVlIHdpdGhpbiBhIHNjZW5lLgoKDAoFBAACAQQSAyoCCgoM
CgUEAAIBBhIDKgsWCgwKBQQAAgEBEgMqFyQKDAoFBAACAQMSAyonKAqVAgoEBAACAhIDMAIz
GocCIFRoZSBsaXN0IG9mIGV2ZW50cyB0byB0cmlnZ2VyIGJhc2VkIG9uIGNvbmRpdGlvbmFs
IHN0YXRlbWVudHMuIFRoZXNlIGFyZQogZXZhbHVhdGVkIGFmdGVyIHRoZSBmb3JtIGhhcyBi
ZWVuIGZpbGxlZCBvciBpbW1lZGlhdGVseSBhZnRlciBvbl9sb2FkIGlmCiB0aGlzIHNjZW5l
IGRvZXMgbm90IGhhdmUgYSBmb3JtIChldmFsdWF0aW9uIGlzIG9ubHkgZG9uZSBvbmNlKS4g
T25seSB0aGUKIGZpcnN0IG1hdGNoaW5nIGV2ZW50IHdpbGwgYmUgdHJpZ2dlcmVkLgoKDAoF
BAACAgQSAzACCgoMCgUEAAICBhIDMAsbCgwKBQQAAgIBEgMwHC4KDAoFBAACAgMSAzAxMgqx
AQoEBAACAxIDNQIaGqMBIE9yZGVyZWQgbGlzdCBvZiBzbG90cy4gRWFjaCBzbG90IGRlZmlu
ZXMgdGhlIHR5cGUgb2YgZGF0YQogdGhhdCBpdCB3aWxsIHJlc29sdmUgYW5kIGNvbmZpZ3Vy
YXRpb24gdG8gY3VzdG9taXplIHRoZSBleHBlcmllbmNlIG9mIHRoaXMKIHJlc29sdXRpb24g
KGUuZy4gcHJvbXB0cykuCgoMCgUEAAIDBBIDNQIKCgwKBQQAAgMGEgM1Cw8KDAoFBAACAwES
AzUQFQoMCgUEAAIDAxIDNRgZCtQBCgQEAAIEEgM6AiMaxgEgSGFuZGxlciBjYWxsZWQgd2hl
biB0aGVyZSBpcyBhIGNoYW5nZSBpbiBzdGF0ZSBvZiBhIHNsb3Qgbm90CiBjYXVzZWQgYnkg
dXBkYXRlcyB3aXRoaW4gYW5vdGhlciBIYW5kbGVyLiBUaGlzIGFsbG93cyBzbG90cyB0byBi
ZQogaW52YWxpZGF0ZWQsIHRoZSBzY2VuZSBpbnZhbGlkYXRlZCBvciBvdGhlciBjaGFuZ2Vz
IHRvIHNjZW5lIHN0YXRlLgoKDAoFBAACBAYSAzoCDgoMCgUEAAIEARIDOg8eCgwKBQQAAgQD
EgM6ISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene ===
    # Fields for Scene
    # Field: on_enter Type: 11 (.google.actions.sdk.v2.interactionmodel.EventHandler)
    # Field: intent_events Type: 11 (.google.actions.sdk.v2.interactionmodel.IntentEvent)
    # Field: conditional_events Type: 11 (.google.actions.sdk.v2.interactionmodel.ConditionalEvent)
    # Field: slots Type: 11 (.google.actions.sdk.v2.interactionmodel.Slot)
    # Field: on_slot_updated Type: 11 (.google.actions.sdk.v2.interactionmodel.EventHandler)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Scene - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/scene.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Scene;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene->new({
        on_enter => $on_enter,
        intent_events => $intent_events,
        conditional_events => $conditional_events,
        slots => $slots,
    });

    # Read or update a field
    my $val = $msg->on_enter();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/scene.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene

Scene is the basic unit of control flow when designing a conversation. They
can be chained together with other scenes, generate prompts for the end user,
and define slots.
The scene name is specified in the name of the file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->on_enter() >> / C<< $msg->on_enter($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler>)

Handler to invoke when transitioning into this scene.

=item * C<< $msg->intent_events() >> / C<< $msg->intent_events($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent>)

The list of events that trigger based on intents. These events can
be triggered at any time after the on_load Handler has been called.
Important - these events define the set of intents which are scoped to
this scene and will take precedence over any globally defined events that
have the same intents or their triggering phrases. Intent names must be
unique within a scene.

=item * C<< $msg->conditional_events() >> / C<< $msg->conditional_events($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent>)

The list of events to trigger based on conditional statements. These are
evaluated after the form has been filled or immediately after on_load if
this scene does not have a form (evaluation is only done once). Only the
first matching event will be triggered.

=item * C<< $msg->slots() >> / C<< $msg->slots($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot>)

Ordered list of slots. Each slot defines the type of data
that it will resolve and configuration to customize the experience of this
resolution (e.g. prompts).

=item * C<< $msg->on_slot_updated() >> / C<< $msg->on_slot_updated($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler>)

Handler called when there is a change in state of a slot not
caused by updates within another Handler. This allows slots to be
invalidated, the scene invalidated or other changes to scene state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Scene::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
