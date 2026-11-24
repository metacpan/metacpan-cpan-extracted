package Google::Actions::Sdk::V2::Interactionmodel::IntentEvent;

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
Cjlnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9pbnRlbnRfZXZlbnQu
cHJvdG8SJmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsGjpnb29nbGUv
YWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9ldmVudF9oYW5kbGVyLnByb3RvGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIrQBCgtJbnRlbnRFdmVudBIbCgZpbnRl
bnQYASABKAlCA+BBAlIGaW50ZW50EjMKE3RyYW5zaXRpb25fdG9fc2NlbmUYAiABKAlCA+BB
AVIRdHJhbnNpdGlvblRvU2NlbmUSUwoHaGFuZGxlchgDIAEoCzI0Lmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLkV2ZW50SGFuZGxlckID4EEBUgdoYW5kbGVyQpgB
Cipjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWxCEEludGVudEV2
ZW50UHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rp
b25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVyYWN0aW9ubW9kZWxKiQsKBhIEDgAn
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
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABID
EgBECgkKAgMBEgMTACkKCAoBCBIDFQBtCgkKAggLEgMVAG0KCAoBCBIDFgAiCgkKAggKEgMW
ACIKCAoBCBIDFwAxCgkKAggIEgMXADEKCAoBCBIDGABDCgkKAggBEgMYAEMKTgoCBAASBBsA
JwEaQiBSZWdpc3RlcnMgRXZlbnRzIHdoaWNoIHRyaWdnZXIgYXMgdGhlIHJlc3VsdCBvZiBh
biBpbnRlbnQgbWF0Y2guCgoKCgMEAAESAxsIEwo1CgQEAAIAEgMdAj0aKCBSZXF1aXJlZC4g
SW50ZW50IHRyaWdnZXJpbmcgdGhlIGV2ZW50LgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARID
HQkPCgwKBQQAAgADEgMdEhMKDAoFBAACAAgSAx0UPAoPCggEAAIACJwIABIDHRU7CpIBCgQE
AAIBEgMhAkoahAEgT3B0aW9uYWwuIERlc3RpbmF0aW9uIHNjZW5lIHdoaWNoIHRoZSBjb252
ZXJzYXRpb24gc2hvdWxkIGp1bXAgdG8uIFRoZSBzdGF0ZSBvZiB0aGUKIGN1cnJlbnQgc2Nl
bmUgaXMgZGVzdHJveWVkIG9uIHRoZSB0cmFuc2l0aW9uLgoKDAoFBAACAQUSAyECCAoMCgUE
AAIBARIDIQkcCgwKBQQAAgEDEgMhHyAKDAoFBAACAQgSAyEhSQoPCggEAAIBCJwIABIDISJI
CsgBCgQEAAICEgMmAkQaugEgT3B0aW9uYWwuIEV2ZW50IGhhbmRsZXIgd2hpY2ggaXMgdHJp
Z2dlcmVkIHdoZW4gdGhlIGludGVudCBpcyBtYXRjaGVkLiBTaG91bGQgZXhlY3V0ZQogYmVm
b3JlIHRyYW5zaXRpb25pbmcgdG8gdGhlIGRlc3RpbmF0aW9uIHNjZW5lLiBVc2VmdWwgdG8g
Z2VuZXJhdGUgcHJvbXB0cwogaW4gcmVzcG9uc2UgdG8gZXZlbnRzLgoKDAoFBAACAgYSAyYC
DgoMCgUEAAICARIDJg8WCgwKBQQAAgIDEgMmGRoKDAoFBAACAggSAyYbQwoPCggEAAICCJwI
ABIDJhxCYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent ===
    # Fields for IntentEvent
    # Field: intent Type: 9 ()
    # Field: transition_to_scene Type: 9 ()
    # Field: handler Type: 11 (.google.actions.sdk.v2.interactionmodel.EventHandler)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::IntentEvent - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/intent_event.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::IntentEvent;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent->new({
        intent => $intent,
        transition_to_scene => $transition_to_scene,
        handler => $handler,
    });

    # Read or update a field
    my $val = $msg->intent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/intent_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::IntentEvent

Registers Events which trigger as the result of an intent match.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->intent() >> / C<< $msg->intent($value) >>

Type: C<String>

Required. Intent triggering the event.

=item * C<< $msg->transition_to_scene() >> / C<< $msg->transition_to_scene($value) >>

Type: C<String>

Optional. Destination scene which the conversation should jump to. The state of the
current scene is destroyed on the transition.

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler>)

Optional. Event handler which is triggered when the intent is matched. Should execute
before transitioning to the destination scene. Useful to generate prompts
in response to events.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::IntentEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
