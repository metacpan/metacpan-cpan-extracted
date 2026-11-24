package Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::EventHandler };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9nbG9iYWxfaW50ZW50
X2V2ZW50LnByb3RvEiZnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbBo6
Z29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvZXZlbnRfaGFuZGxlci5w
cm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKdAQoRR2xvYmFsSW50ZW50
RXZlbnQSMwoTdHJhbnNpdGlvbl90b19zY2VuZRgBIAEoCUID4EEBUhF0cmFuc2l0aW9uVG9T
Y2VuZRJTCgdoYW5kbGVyGAIgASgLMjQuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0
aW9ubW9kZWwuRXZlbnRIYW5kbGVyQgPgQQFSB2hhbmRsZXJCngEKKmNvbS5nb29nbGUuYWN0
aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbEIWR2xvYmFsSW50ZW50RXZlbnRQcm90b1AB
WlZnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3Yy
L2ludGVyYWN0aW9ubW9kZWw7aW50ZXJhY3Rpb25tb2RlbEq0DQoGEgQOACwBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAvCgkKAgMAEgMSAEQKCQoCAwES
AxMAKQoICgEIEgMVAG0KCQoCCAsSAxUAbQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ADcKCQoCCAgSAxcANwoICgEIEgMYAEMKCQoCCAESAxgAQwr4AwoCBAASBCMALAEa6wMgRGVm
aW5lcyBhIGdsb2JhbCBpbnRlbnQgaGFuZGxlci4gR2xvYmFsIGludGVudCBldmVudHMgYXJl
IHNjb3BlZCB0byB0aGUKIGVudGlyZSBBY3Rpb25zIHByb2plY3QgYW5kIG1heSBiZSBvdmVy
cmlkZGVuIGJ5IGludGVudCBoYW5kbGVycyBpbiBhIHNjZW5lLgogSW50ZW50IG5hbWVzIG11
c3QgYmUgdW5pcXVlIHdpdGhpbiBhbiBBY3Rpb25zIHByb2plY3QuCgogR2xvYmFsIGludGVu
dHMgY2FuIGJlIG1hdGNoZWQgYW55dGltZSBkdXJpbmcgYSBzZXNzaW9uLCBhbGxvd2luZyB1
c2VycyB0bwogYWNjZXNzIGNvbW1vbiBmbG93cyBsaWtlICAiZ2V0IGhlbHAiIG9yICJnbyBi
YWNrIGhvbWUuIiBUaGV5IGNhbiBhbHNvIGJlCiB1c2VkIHRvIGRlZXAgbGluayB1c2VycyBp
bnRvIHNwZWNpZmljIGZsb3dzIHdoZW4gdGhleSBpbnZva2UgYW4gQWN0aW9uLgoKIE5vdGUs
IHRoZSBpbnRlbnQgbmFtZSBpcyBzcGVjaWZpZWQgaW4gdGhlIG5hbWUgb2YgdGhlIGZpbGUu
CgoKCgMEAAESAyMIGQqSAQoEBAACABIDJgJKGoQBIE9wdGlvbmFsLiBEZXN0aW5hdGlvbiBz
Y2VuZSB3aGljaCB0aGUgY29udmVyc2F0aW9uIHNob3VsZCBqdW1wIHRvLiBUaGUgc3RhdGUg
b2YgdGhlCiBjdXJyZW50IHNjZW5lIGlzIGRlc3Ryb3llZCBvbiB0aGUgdHJhbnNpdGlvbi4K
CgwKBQQAAgAFEgMmAggKDAoFBAACAAESAyYJHAoMCgUEAAIAAxIDJh8gCgwKBQQAAgAIEgMm
IUkKDwoIBAACAAicCAASAyYiSArIAQoEBAACARIDKwJEGroBIE9wdGlvbmFsLiBFdmVudCBo
YW5kbGVyIHdoaWNoIGlzIHRyaWdnZXJlZCB3aGVuIHRoZSBpbnRlbnQgaXMgbWF0Y2hlZC4g
U2hvdWxkIGV4ZWN1dGUKIGJlZm9yZSB0cmFuc2l0aW9uaW5nIHRvIHRoZSBkZXN0aW5hdGlv
biBzY2VuZS4gVXNlZnVsIHRvIGdlbmVyYXRlIFByb21wdHMKIGluIHJlc3BvbnNlIHRvIGV2
ZW50cy4KCgwKBQQAAgEGEgMrAg4KDAoFBAACAQESAysPFgoMCgUEAAIBAxIDKxkaCgwKBQQA
AgEIEgMrG0MKDwoIBAACAQicCAASAyscQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent ===
    # Fields for GlobalIntentEvent
    # Field: transition_to_scene Type: 9 ()
    # Field: handler Type: 11 (.google.actions.sdk.v2.interactionmodel.EventHandler)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/global_intent_event.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent->new({
        transition_to_scene => $transition_to_scene,
        handler => $handler,
    });

    # Read or update a field
    my $val = $msg->transition_to_scene();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/global_intent_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent

Defines a global intent handler. Global intent events are scoped to the
entire Actions project and may be overridden by intent handlers in a scene.
Intent names must be unique within an Actions project.

Global intents can be matched anytime during a session, allowing users to
access common flows like  "get help" or "go back home." They can also be
used to deep link users into specific flows when they invoke an Action.

Note, the intent name is specified in the name of the file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->transition_to_scene() >> / C<< $msg->transition_to_scene($value) >>

Type: C<String>

Optional. Destination scene which the conversation should jump to. The state of the
current scene is destroyed on the transition.

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler>)

Optional. Event handler which is triggered when the intent is matched. Should execute
before transitioning to the destination scene. Useful to generate Prompts
in response to events.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
