package Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent;

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
Cj5nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9jb25kaXRpb25hbF9l
dmVudC5wcm90bxImZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwaOmdv
b2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL2V2ZW50X2hhbmRsZXIucHJv
dG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8ivwEKEENvbmRpdGlvbmFsRXZl
bnQSIQoJY29uZGl0aW9uGAEgASgJQgPgQQJSCWNvbmRpdGlvbhIzChN0cmFuc2l0aW9uX3Rv
X3NjZW5lGAIgASgJQgPgQQFSEXRyYW5zaXRpb25Ub1NjZW5lElMKB2hhbmRsZXIYAyABKAsy
NC5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5FdmVudEhhbmRsZXJC
A+BBAVIHaGFuZGxlckKdAQoqY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsQhVDb25kaXRpb25hbEV2ZW50UHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2Vu
cHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVy
YWN0aW9ubW9kZWxKlxIKBhIEDgA2AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAALwoJCgIDABIDEgBECgkKAgMBEgMTACkKCAoBCBIDFQBtCgkKAggLEgMV
AG0KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA2CgkKAggIEgMXADYKCAoBCBIDGABD
CgkKAggBEgMYAEMKTgoCBAASBBsANgEaQiBSZWdpc3RlcnMgZXZlbnRzIHRoYXQgdHJpZ2dl
ciBhcyB0aGUgcmVzdWx0IG9mIGEgdHJ1ZSBjb25kaXRpb24uCgoKCgMEAAESAxsIGAr0BgoE
BAACABIDKwJAGuYGIFJlcXVpcmVkLiBGaWx0ZXIgY29uZGl0aW9uIGZvciB0aGlzIGV2ZW50
IHRvIHRyaWdnZXIuIElmIGNvbmRpdGlvbiBpcyBldmFsdWF0ZWQgdG8KIHRydWUgdGhlbiB0
aGUgYXNzb2NpYXRlZCBgaGFuZGxlcmAgd2lsbCBiZSB0cmlnZ2VyZWQuCiBUaGUgZm9sbG93
aW5nIHZhcmlhYmxlIHJlZmVyZW5jZXMgYXJlIHN1cHBvcnRlZDoKICAgYCRzZXNzaW9uYCAt
IFRvIHJlZmVyZW5jZSBkYXRhIGluIHNlc3Npb24gc3RvcmFnZS4KICAgYCR1c2VyYCAtIFRv
IHJlZmVyZW5jZSBkYXRhIGluIHVzZXIgc3RvcmFnZS4KIFRoZSBmb2xsb3dpbmcgYm9vbGVh
biBvcGVyYXRvcnMgYXJlIHN1cHBvcnRlZCAod2l0aCBleGFtcGxlcyk6CiAgIGAmJmAgLSBg
c2Vzc2lvbi5wYXJhbXMuY291bnRlciA+IDAgJiYgc2Vzc2lvbi5wYXJhbXMuY291bnRlciA8
IDEwMGAKICAgYHx8YCAtIGBzZXNzaW9uLnBhcmFtcy5mb28gPT0gIkpvaG4iIHx8IHNlc3Np
b24ucGFyYW1zLmNvdW50ZXIgPT0gIkFkYW0iYAogICBgIWAgIC0gYCEoc2Vzc2lvbi5wYXJh
bXMuY291bnRlciA9PSA1KWAKIFRoZSBmb2xsb3dpbmcgY29tcGFyaXNvbnMgYXJlIHN1cHBv
cnRlZDoKICAgYD09YCwgYCE9YCwgYDxgLCBgPmAsIGA8PWAsIGA+PWAKIFRoZSBmb2xsb3dp
bmcgbGlzdCBhbmQgc3RyaW5nIG9wZXJhdG9ycyBhcmUgc3VwcG9ydGVkICh3aXRoIGV4YW1w
bGVzKToKICAgYGluYCAgICAgICAgLSAiV2F0ZXJtZWxvbiIgaW4gYHNlc3Npb24ucGFyYW1z
LmZydWl0TGlzdGAKICAgYHNpemVgICAgICAgLSBgc2l6ZShzZXNzaW9uLnBhcmFtcy5mcnVp
dExpc3QpID4gMmAKICAgYHN1YnN0cmluZ2AgLSBgc2Vzc2lvbi5wYXJhbXMuZnVsbE5hbWUu
Y29udGFpbnMoIkpvaG4iKWAKCgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJEgoMCgUEAAIA
AxIDKxUWCgwKBQQAAgAIEgMrFz8KDwoIBAACAAicCAASAysYPgrGAQoEBAACARIDMAJKGrgB
IE9wdGlvbmFsLiBEZXN0aW5hdGlvbiBzY2VuZSB3aGljaCB0aGUgY29udmVyc2F0aW9uIHNo
b3VsZCBqdW1wIHRvIHdoZW4gdGhlIGFzc29jaWF0ZWQKIGNvbmRpdGlvbiBpcyBldmFsdWF0
ZWQgdG8gdHJ1ZS4gVGhlIHN0YXRlIG9mIHRoZSBjdXJyZW50IHNjZW5lIGlzIGRlc3Ryb3ll
ZAogb24gdGhlIHRyYW5zaXRpb24uCgoMCgUEAAIBBRIDMAIICgwKBQQAAgEBEgMwCRwKDAoF
BAACAQMSAzAfIAoMCgUEAAIBCBIDMCFJCg8KCAQAAgEInAgAEgMwIkgK4gEKBAQAAgISAzUC
RBrUASBPcHRpb25hbC4gRXZlbnQgaGFuZGxlciB3aGljaCBpcyB0cmlnZ2VyZWQgd2hlbiB0
aGUgYXNzb2NpYXRlZCBjb25kaXRpb24gaXMgZXZhbHVhdGVkCiB0byBgdHJ1ZWAuIFNob3Vs
ZCBleGVjdXRlIGJlZm9yZSB0cmFuc2l0aW9uaW5nIHRvIHRoZSBkZXN0aW5hdGlvbiBzY2Vu
ZS4KIFVzZWZ1bCB0byBnZW5lcmF0ZSBQcm9tcHRzIGluIHJlc3BvbnNlIHRvIGV2ZW50cy4K
CgwKBQQAAgIGEgM1Ag4KDAoFBAACAgESAzUPFgoMCgUEAAICAxIDNRkaCgwKBQQAAgIIEgM1
G0MKDwoIBAACAgicCAASAzUcQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent ===
    # Fields for ConditionalEvent
    # Field: condition Type: 9 ()
    # Field: transition_to_scene Type: 9 ()
    # Field: handler Type: 11 (.google.actions.sdk.v2.interactionmodel.EventHandler)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/conditional_event.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent->new({
        condition => $condition,
        transition_to_scene => $transition_to_scene,
        handler => $handler,
    });

    # Read or update a field
    my $val = $msg->condition();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/conditional_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::ConditionalEvent

Registers events that trigger as the result of a true condition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Required. Filter condition for this event to trigger. If condition is evaluated to
true then the associated `handler` will be triggered.
The following variable references are supported:
  `$session` - To reference data in session storage.
  `$user` - To reference data in user storage.
The following boolean operators are supported (with examples):
  `&&` - `session.params.counter > 0 && session.params.counter < 100`
  `||` - `session.params.foo == "John" || session.params.counter == "Adam"`
  `!`  - `!(session.params.counter == 5)`
The following comparisons are supported:
  `==`, `!=`, `<`, `>`, `<=`, `>=`
The following list and string operators are supported (with examples):
  `in`        - "Watermelon" in `session.params.fruitList`
  `size`      - `size(session.params.fruitList) > 2`
  `substring` - `session.params.fullName.contains("John")`

=item * C<< $msg->transition_to_scene() >> / C<< $msg->transition_to_scene($value) >>

Type: C<String>

Optional. Destination scene which the conversation should jump to when the associated
condition is evaluated to true. The state of the current scene is destroyed
on the transition.

=item * C<< $msg->handler() >> / C<< $msg->handler($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EventHandler::EventHandler>)

Optional. Event handler which is triggered when the associated condition is evaluated
to `true`. Should execute before transitioning to the destination scene.
Useful to generate Prompts in response to events.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::ConditionalEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
