package Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CkBnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2FnZW50X2NvYWNoaW5nX2luc3Ry
dWN0aW9uLnByb3RvEh9nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIt0HChhBZ2VudENvYWNoaW5nSW5zdHJ1Y3Rpb24S
JgoMZGlzcGxheV9uYW1lGAEgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiwKD2Rpc3BsYXlfZGV0
YWlscxgCIAEoCUID4EEBUg5kaXNwbGF5RGV0YWlscxIhCgljb25kaXRpb24YAyABKAlCA+BB
AVIJY29uZGl0aW9uEiYKDGFnZW50X2FjdGlvbhgEIAEoCUID4EEBUgthZ2VudEFjdGlvbhIo
Cg1zeXN0ZW1fYWN0aW9uGAUgASgJQgPgQQFSDHN5c3RlbUFjdGlvbhKJAQoWZHVwbGljYXRl
X2NoZWNrX3Jlc3VsdBgIIAEoCzJOLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
QWdlbnRDb2FjaGluZ0luc3RydWN0aW9uLkR1cGxpY2F0ZUNoZWNrUmVzdWx0QgPgQQNSFGR1
cGxpY2F0ZUNoZWNrUmVzdWx0EnYKEHRyaWdnZXJpbmdfZXZlbnQYCiABKA4yRi5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkFnZW50Q29hY2hpbmdJbnN0cnVjdGlvbi5Ucmln
Z2VyRXZlbnRCA+BBAVIPdHJpZ2dlcmluZ0V2ZW50GtcCChREdXBsaWNhdGVDaGVja1Jlc3Vs
dBKcAQoVZHVwbGljYXRlX3N1Z2dlc3Rpb25zGAEgAygLMmIuZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5BZ2VudENvYWNoaW5nSW5zdHJ1Y3Rpb24uRHVwbGljYXRlQ2hlY2tS
ZXN1bHQuRHVwbGljYXRlU3VnZ2VzdGlvbkID4EEDUhRkdXBsaWNhdGVTdWdnZXN0aW9ucxqf
AQoTRHVwbGljYXRlU3VnZ2VzdGlvbhIoCg1hbnN3ZXJfcmVjb3JkGAEgASgJQgPgQQNSDGFu
c3dlclJlY29yZBIuChBzdWdnZXN0aW9uX2luZGV4GAMgASgFQgPgQQNSD3N1Z2dlc3Rpb25J
bmRleBIuChBzaW1pbGFyaXR5X3Njb3JlGAQgASgCQgPgQQNSD3NpbWlsYXJpdHlTY29yZSKX
AQoMVHJpZ2dlckV2ZW50Eh0KGVRSSUdHRVJfRVZFTlRfVU5TUEVDSUZJRUQQABIUChBFTkRf
T0ZfVVRURVJBTkNFEAESDwoLTUFOVUFMX0NBTEwQAhIUChBDVVNUT01FUl9NRVNTQUdFEAMS
EQoNQUdFTlRfTUVTU0FHRRAEEhgKFFRPT0xfQ0FMTF9DT01QTEVUSU9OEAVCsgEKI2NvbS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExQh1BZ2VudENvYWNoaW5nSW5zdHJ1Y3Rp
b25Qcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9k
aWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaqAh9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxv
dy5WMkJldGExSqceCgYSBA4AZQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACgKCQoCAwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMVAFoK
CQoCCAsSAxUAWgoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAD4KCQoCCAgSAxcAPgoI
CgEIEgMYADwKCQoCCAESAxgAPAoICgEIEgMZACAKCQoCCCQSAxkAIApGCgIEABIEHABlARo6
IEFnZW50IENvYWNoaW5nIGluc3RydWN0aW9ucyB0aGF0IGN1c3RvbWVyIGNhbiBjb25maWd1
cmUuCgoKCgMEAAESAxwIIAo1CgQEAAMAEgQeAjADGicgRHVwbGljYXRpb24gY2hlY2sgZm9y
IHRoZSBzdWdnZXN0aW9uLgoKDAoFBAADAAESAx4KHgozCgYEAAMAAwASBCAEKwUaIyBUaGUg
ZHVwbGljYXRlIHN1Z2dlc3Rpb24gZGV0YWlscy4KCg4KBwQAAwADAAESAyAMHwpWCggEAAMA
AwACABIDIgZLGkUgT3V0cHV0IG9ubHkuIFRoZSBhbnN3ZXIgcmVjb3JkIGlkIG9mIHRoZSBw
YXN0IGR1cGxpY2F0ZSBzdWdnZXN0aW9uLgoKEAoJBAADAAMAAgAFEgMiBgwKEAoJBAADAAMA
AgABEgMiDRoKEAoJBAADAAMAAgADEgMiHR4KEAoJBAADAAMAAgAIEgMiH0oKEwoMBAADAAMA
AgAInAgAEgMiIEkKYwoIBAADAAMAAgESAyYGTRpSIE91dHB1dCBvbmx5LiBUaGUgaW5kZXgg
b2YgdGhlIGR1cGxpY2F0ZSBzdWdnZXN0aW9uIGluIHRoZSBwYXN0CiBzdWdnZXN0aW9uIGxp
c3QuCgoQCgkEAAMAAwACAQUSAyYGCwoQCgkEAAMAAwACAQESAyYMHAoQCgkEAAMAAwACAQMS
AyYfIAoQCgkEAAMAAwACAQgSAyYhTAoTCgwEAAMAAwACAQicCAASAyYiSwphCggEAAMAAwAC
AhIDKgZNGlAgT3V0cHV0IG9ubHkuIFRoZSBzaW1pbGFyaXR5IHNjb3JlIG9mIGJldHdlZW4g
dGhlIHBhc3QgYW5kIGN1cnJlbnQKIHN1Z2dlc3Rpb24uCgoQCgkEAAMAAwACAgUSAyoGCwoQ
CgkEAAMAAwACAgESAyoMHAoQCgkEAAMAAwACAgMSAyofIAoQCgkEAAMAAwACAggSAyohTAoT
CgwEAAMAAwACAgicCAASAyoiSwo5CgYEAAMAAgASBC4ELzQaKSBPdXRwdXQgb25seS4gVGhl
IGR1cGxpY2F0ZSBzdWdnZXN0aW9ucy4KCg4KBwQAAwACAAQSAy4EDAoOCgcEAAMAAgAGEgMu
DSAKDgoHBAADAAIAARIDLiE2Cg4KBwQAAwACAAMSAy45OgoOCgcEAAMAAgAIEgMvCDMKEQoK
BAADAAIACJwIABIDLwkyCj8KBAQABAASBDMCRQMaMSBUaGUgZXZlbnQgdGhhdCBzaG91bGQg
dHJpZ2dlciB0aGlzIGluc3RydWN0aW9uLgoKDAoFBAAEAAESAzMHEwowCgYEAAQAAgASAzUE
IhohIERlZmF1bHQgdmFsdWUgZm9yIFRyaWdnZXJFdmVudC4KCg4KBwQABAACAAESAzUEHQoO
CgcEAAQAAgACEgM1ICEKSQoGBAAEAAIBEgM4BBkaOiBUcmlnZ2VycyB3aGVuIGVhY2ggY2hh
dCBtZXNzYWdlIG9yIHZvaWNlIHV0dGVyYW5jZSBlbmRzLgoKDgoHBAAEAAIBARIDOAQUCg4K
BwQABAACAQISAzgXGApECgYEAAQAAgISAzsEFBo1IFRyaWdnZXJzIG9uIHRoZSBjb252ZXJz
YXRpb24gbWFudWFsbHkgYnkgQVBJIGNhbGxzLgoKDgoHBAAEAAICARIDOwQPCg4KBwQABAAC
AgISAzsSEwo2CgYEAAQAAgMSAz4EGRonIFRyaWdnZXJzIGFmdGVyIGVhY2ggY3VzdG9tZXIg
bWVzc2FnZS4KCg4KBwQABAACAwESAz4EFAoOCgcEAAQAAgMCEgM+FxgKMwoGBAAEAAIEEgNB
BBYaJCBUcmlnZ2VycyBhZnRlciBlYWNoIGFnZW50IG1lc3NhZ2UuCgoOCgcEAAQAAgQBEgNB
BBEKDgoHBAAEAAIEAhIDQRQVCjIKBgQABAACBRIDRAQdGiMgVHJpZ2dlcnMgb24gdG9vbCBj
YWxsIGNvbXBsZXRpb24uCgoOCgcEAAQAAgUBEgNEBBgKDgoHBAAEAAIFAhIDRBscCjoKBAQA
AgASA0gCQxotIE9wdGlvbmFsLiBEaXNwbGF5IG5hbWUgZm9yIHRoZSBpbnN0cnVjdGlvbi4K
CgwKBQQAAgAFEgNIAggKDAoFBAACAAESA0gJFQoMCgUEAAIAAxIDSBgZCgwKBQQAAgAIEgNI
GkIKDwoIBAACAAicCAASA0gbQQpGCgQEAAIBEgNLAkYaOSBPcHRpb25hbC4gVGhlIGRldGFp
bGVkIGRlc2NyaXB0aW9uIG9mIHRoaXMgaW5zdHJ1Y3Rpb24uCgoMCgUEAAIBBRIDSwIICgwK
BQQAAgEBEgNLCRgKDAoFBAACAQMSA0sbHAoMCgUEAAIBCBIDSx1FCg8KCAQAAgEInAgAEgNL
HkQK0wEKBAQAAgISA1ACQBrFASBPcHRpb25hbC4gVGhlIGNvbmRpdGlvbiBvZiB0aGUgaW5z
dHJ1Y3Rpb24uIEZvciBleGFtcGxlLCAidGhlIGN1c3RvbWVyCiB3YW50cyB0byBjYW5jZWwg
YW4gb3JkZXIiLiAgSWYgdGhlIHVzZXJzIHdhbnQgdGhlIGluc3RydWN0aW9uIHRvIGJlCiB0
cmlnZ2VyZWQgdW5jb25kaXRpb25hbGx5LCB0aGUgY29uZGl0aW9uIGNhbiBiZSBlbXB0eS4K
CgwKBQQAAgIFEgNQAggKDAoFBAACAgESA1AJEgoMCgUEAAICAxIDUBUWCgwKBQQAAgIIEgNQ
Fz8KDwoIBAACAgicCAASA1AYPgrRAQoEBAACAxIDVQJDGsMBIE9wdGlvbmFsLiBUaGUgYWN0
aW9uIHRoYXQgaHVtYW4gYWdlbnQgc2hvdWxkIHRha2UuIEZvciBleGFtcGxlLCAiYXBvbG9n
aXplCiBmb3IgdGhlIHNsb3cgc2hpcHBpbmciLiBJZiB0aGUgdXNlcnMgb25seSB3YW50IHRv
IHVzZSBhZ2VudCBjb2FjaGluZyBmb3IKIGludGVudCBkZXRlY3Rpb24sIGFnZW50X2FjdGlv
biBjYW4gYmUgZW1wdHkKCgwKBQQAAgMFEgNVAggKDAoFBAACAwESA1UJFQoMCgUEAAIDAxID
VRgZCgwKBQQAAgMIEgNVGkIKDwoIBAACAwicCAASA1UbQQr9AQoEBAACBBIDWwJEGu8BIE9w
dGlvbmFsLiBUaGUgYWN0aW9uIHRoYXQgc3lzdGVtIHNob3VsZCB0YWtlLiBGb3IgZXhhbXBs
ZSwKICJjYWxsIEdldE9yZGVyVGltZSB3aXRoIG9yZGVyX251bWJlcj17b3JkZXIgbnVtYmVy
IHByb3ZpZGVkIGJ5IHRoZQogY3VzdG9tZXJ9Ii4gSWYgdGhlIHVzZXJzIGRvbid0IGhhdmUg
cGx1Z2lucyBvciBkb24ndCB3YW50IHRvIHRyaWdnZXIKIHBsdWdpbnMsIHRoZSBzeXN0ZW1f
YWN0aW9uIGNhbiBiZSBlbXB0eQoKDAoFBAACBAUSA1sCCAoMCgUEAAIEARIDWwkWCgwKBQQA
AgQDEgNbGRoKDAoFBAACBAgSA1sbQwoPCggEAAIECJwIABIDWxxCClAKBAQAAgUSBF4CXzIa
QiBPdXRwdXQgb25seS4gRHVwbGljYXRpb24gY2hlY2sgZm9yIHRoZSBBZ2VudENvYWNoaW5n
SW5zdHJ1Y3Rpb24uCgoMCgUEAAIFBhIDXgIWCgwKBQQAAgUBEgNeFy0KDAoFBAACBQMSA14w
MQoMCgUEAAIFCBIDXwYxCg8KCAQAAgUInAgAEgNfBzAKpQEKBAQAAgYSA2QCThqXASBPcHRp
b25hbC4gVGhlIGV2ZW50IHRoYXQgc2hvdWxkIHRyaWdnZXIgdGhpcyBpbnN0cnVjdGlvbi4K
IElmIFVOU1BFQ0lGSUVELCB0aGUgaW5zdHJ1Y3Rpb24gdHJpZ2dlcmluZyB3aWxsIGJlIHNh
bWUgYXMgdGhlIGdlbmVyYXRvcidzCiB0cmlnZ2VyX2V2ZW50LgoKDAoFBAACBgYSA2QCDgoM
CgUEAAIGARIDZA8fCgwKBQQAAgYDEgNkIiQKDAoFBAACBggSA2QlTQoPCggEAAIGCJwIABID
ZCZMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction ===
    # Fields for AgentCoachingInstruction
    # Field: display_name Type: 9 ()
    # Field: display_details Type: 9 ()
    # Field: condition Type: 9 ()
    # Field: agent_action Type: 9 ()
    # Field: system_action Type: 9 ()
    # Field: duplicate_check_result Type: 11 (.google.cloud.dialogflow.v2beta1.AgentCoachingInstruction.DuplicateCheckResult)
    # Field: triggering_event Type: 14 (.google.cloud.dialogflow.v2beta1.AgentCoachingInstruction.TriggerEvent)

# Enum: AgentCoachingInstruction::TriggerEvent
our $AgentCoachingInstruction_TRIGGER_EVENT_UNSPECIFIED = 0;
our $AgentCoachingInstruction_END_OF_UTTERANCE = 1;
our $AgentCoachingInstruction_MANUAL_CALL = 2;
our $AgentCoachingInstruction_CUSTOMER_MESSAGE = 3;
our $AgentCoachingInstruction_AGENT_MESSAGE = 4;
our $AgentCoachingInstruction_TOOL_CALL_COMPLETION = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/agent_coaching_instruction.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction;

    my $msg = Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction->new({
        display_name => $display_name,
        display_details => $display_details,
        condition => $condition,
        agent_action => $agent_action,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/agent_coaching_instruction.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction

Agent Coaching instructions that customer can configure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Display name for the instruction.

=item * C<< $msg->display_details() >> / C<< $msg->display_details($value) >>

Type: C<String>

Optional. The detailed description of this instruction.

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<String>

Optional. The condition of the instruction. For example, "the customer
wants to cancel an order".  If the users want the instruction to be
triggered unconditionally, the condition can be empty.

=item * C<< $msg->agent_action() >> / C<< $msg->agent_action($value) >>

Type: C<String>

Optional. The action that human agent should take. For example, "apologize
for the slow shipping". If the users only want to use agent coaching for
intent detection, agent_action can be empty

=item * C<< $msg->system_action() >> / C<< $msg->system_action($value) >>

Type: C<String>

Optional. The action that system should take. For example,
"call GetOrderTime with order_number={order number provided by the
customer}". If the users don't have plugins or don't want to trigger
plugins, the system_action can be empty

=item * C<< $msg->duplicate_check_result() >> / C<< $msg->duplicate_check_result($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult>)

Output only. Duplication check for the AgentCoachingInstruction.

=item * C<< $msg->triggering_event() >> / C<< $msg->triggering_event($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::TriggerEvent>)

Optional. The event that should trigger this instruction.
If UNSPECIFIED, the instruction triggering will be same as the generator's
trigger_event.

=back

=head3 Enum: AgentCoachingInstruction::TriggerEvent

=over 4

=item * C<TRIGGER_EVENT_UNSPECIFIED> => C<0>

=item * C<END_OF_UTTERANCE> => C<1>

=item * C<MANUAL_CALL> => C<2>

=item * C<CUSTOMER_MESSAGE> => C<3>

=item * C<AGENT_MESSAGE> => C<4>

=item * C<TOOL_CALL_COMPLETION> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::AgentCoachingInstruction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
