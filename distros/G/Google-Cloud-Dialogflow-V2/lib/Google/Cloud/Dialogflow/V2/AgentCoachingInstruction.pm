package Google::Cloud::Dialogflow::V2::AgentCoachingInstruction;

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
Cjtnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9hZ2VudF9jb2FjaGluZ19pbnN0cnVjdGlv
bi5wcm90bxIaZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8izgcKGEFnZW50Q29hY2hpbmdJbnN0cnVjdGlvbhImCgxkaXNwbGF5
X25hbWUYASABKAlCA+BBAVILZGlzcGxheU5hbWUSLAoPZGlzcGxheV9kZXRhaWxzGAIgASgJ
QgPgQQFSDmRpc3BsYXlEZXRhaWxzEiEKCWNvbmRpdGlvbhgDIAEoCUID4EEBUgljb25kaXRp
b24SJgoMYWdlbnRfYWN0aW9uGAQgASgJQgPgQQFSC2FnZW50QWN0aW9uEigKDXN5c3RlbV9h
Y3Rpb24YBSABKAlCA+BBAVIMc3lzdGVtQWN0aW9uEoQBChZkdXBsaWNhdGVfY2hlY2tfcmVz
dWx0GAggASgLMkkuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdlbnRDb2FjaGluZ0lu
c3RydWN0aW9uLkR1cGxpY2F0ZUNoZWNrUmVzdWx0QgPgQQNSFGR1cGxpY2F0ZUNoZWNrUmVz
dWx0EnEKEHRyaWdnZXJpbmdfZXZlbnQYCiABKA4yQS5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5BZ2VudENvYWNoaW5nSW5zdHJ1Y3Rpb24uVHJpZ2dlckV2ZW50QgPgQQFSD3RyaWdn
ZXJpbmdFdmVudBrSAgoURHVwbGljYXRlQ2hlY2tSZXN1bHQSlwEKFWR1cGxpY2F0ZV9zdWdn
ZXN0aW9ucxgBIAMoCzJdLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFnZW50Q29hY2hp
bmdJbnN0cnVjdGlvbi5EdXBsaWNhdGVDaGVja1Jlc3VsdC5EdXBsaWNhdGVTdWdnZXN0aW9u
QgPgQQNSFGR1cGxpY2F0ZVN1Z2dlc3Rpb25zGp8BChNEdXBsaWNhdGVTdWdnZXN0aW9uEigK
DWFuc3dlcl9yZWNvcmQYASABKAlCA+BBA1IMYW5zd2VyUmVjb3JkEi4KEHN1Z2dlc3Rpb25f
aW5kZXgYAyABKAVCA+BBA1IPc3VnZ2VzdGlvbkluZGV4Ei4KEHNpbWlsYXJpdHlfc2NvcmUY
BCABKAJCA+BBA1IPc2ltaWxhcml0eVNjb3JlIpcBCgxUcmlnZ2VyRXZlbnQSHQoZVFJJR0dF
Ul9FVkVOVF9VTlNQRUNJRklFRBAAEhQKEEVORF9PRl9VVFRFUkFOQ0UQARIPCgtNQU5VQUxf
Q0FMTBACEhQKEENVU1RPTUVSX01FU1NBR0UQAxIRCg1BR0VOVF9NRVNTQUdFEAQSGAoUVE9P
TF9DQUxMX0NPTVBMRVRJT04QBUKjAQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYy
Qh1BZ2VudENvYWNoaW5nSW5zdHJ1Y3Rpb25Qcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dv
L2RpYWxvZ2Zsb3cvYXBpdjIvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29v
Z2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJKpx4KBhIEDgBlAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgApCggKAQgSAxQANwoJCgIIJRID
FAA3CggKAQgSAxUAVQoJCgIICxIDFQBVCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcA
PgoJCgIICBIDFwA+CggKAQgSAxgANwoJCgIIARIDGAA3CggKAQgSAxkAIAoJCgIIJBIDGQAg
CkYKAgQAEgQcAGUBGjogQWdlbnQgQ29hY2hpbmcgaW5zdHJ1Y3Rpb25zIHRoYXQgY3VzdG9t
ZXIgY2FuIGNvbmZpZ3VyZS4KCgoKAwQAARIDHAggCjUKBAQAAwASBB4CMAMaJyBEdXBsaWNh
dGlvbiBjaGVjayBmb3IgdGhlIHN1Z2dlc3Rpb24uCgoMCgUEAAMAARIDHgoeCjMKBgQAAwAD
ABIEIAQrBRojIFRoZSBkdXBsaWNhdGUgc3VnZ2VzdGlvbiBkZXRhaWxzLgoKDgoHBAADAAMA
ARIDIAwfClYKCAQAAwADAAIAEgMiBksaRSBPdXRwdXQgb25seS4gVGhlIGFuc3dlciByZWNv
cmQgaWQgb2YgdGhlIHBhc3QgZHVwbGljYXRlIHN1Z2dlc3Rpb24uCgoQCgkEAAMAAwACAAUS
AyIGDAoQCgkEAAMAAwACAAESAyINGgoQCgkEAAMAAwACAAMSAyIdHgoQCgkEAAMAAwACAAgS
AyIfSgoTCgwEAAMAAwACAAicCAASAyIgSQpjCggEAAMAAwACARIDJgZNGlIgT3V0cHV0IG9u
bHkuIFRoZSBpbmRleCBvZiB0aGUgZHVwbGljYXRlIHN1Z2dlc3Rpb24gaW4gdGhlIHBhc3QK
IHN1Z2dlc3Rpb24gbGlzdC4KChAKCQQAAwADAAIBBRIDJgYLChAKCQQAAwADAAIBARIDJgwc
ChAKCQQAAwADAAIBAxIDJh8gChAKCQQAAwADAAIBCBIDJiFMChMKDAQAAwADAAIBCJwIABID
JiJLCmEKCAQAAwADAAICEgMqBk0aUCBPdXRwdXQgb25seS4gVGhlIHNpbWlsYXJpdHkgc2Nv
cmUgb2YgYmV0d2VlbiB0aGUgcGFzdCBhbmQgY3VycmVudAogc3VnZ2VzdGlvbi4KChAKCQQA
AwADAAICBRIDKgYLChAKCQQAAwADAAICARIDKgwcChAKCQQAAwADAAICAxIDKh8gChAKCQQA
AwADAAICCBIDKiFMChMKDAQAAwADAAICCJwIABIDKiJLCjkKBgQAAwACABIELgQvNBopIE91
dHB1dCBvbmx5LiBUaGUgZHVwbGljYXRlIHN1Z2dlc3Rpb25zLgoKDgoHBAADAAIABBIDLgQM
Cg4KBwQAAwACAAYSAy4NIAoOCgcEAAMAAgABEgMuITYKDgoHBAADAAIAAxIDLjk6Cg4KBwQA
AwACAAgSAy8IMwoRCgoEAAMAAgAInAgAEgMvCTIKPwoEBAAEABIEMwJFAxoxIFRoZSBldmVu
dCB0aGF0IHNob3VsZCB0cmlnZ2VyIHRoaXMgaW5zdHJ1Y3Rpb24uCgoMCgUEAAQAARIDMwcT
CjAKBgQABAACABIDNQQiGiEgRGVmYXVsdCB2YWx1ZSBmb3IgVHJpZ2dlckV2ZW50LgoKDgoH
BAAEAAIAARIDNQQdCg4KBwQABAACAAISAzUgIQpJCgYEAAQAAgESAzgEGRo6IFRyaWdnZXJz
IHdoZW4gZWFjaCBjaGF0IG1lc3NhZ2Ugb3Igdm9pY2UgdXR0ZXJhbmNlIGVuZHMuCgoOCgcE
AAQAAgEBEgM4BBQKDgoHBAAEAAIBAhIDOBcYCkQKBgQABAACAhIDOwQUGjUgVHJpZ2dlcnMg
b24gdGhlIGNvbnZlcnNhdGlvbiBtYW51YWxseSBieSBBUEkgY2FsbHMuCgoOCgcEAAQAAgIB
EgM7BA8KDgoHBAAEAAICAhIDOxITCjYKBgQABAACAxIDPgQZGicgVHJpZ2dlcnMgYWZ0ZXIg
ZWFjaCBjdXN0b21lciBtZXNzYWdlLgoKDgoHBAAEAAIDARIDPgQUCg4KBwQABAACAwISAz4X
GAozCgYEAAQAAgQSA0EEFhokIFRyaWdnZXJzIGFmdGVyIGVhY2ggYWdlbnQgbWVzc2FnZS4K
Cg4KBwQABAACBAESA0EEEQoOCgcEAAQAAgQCEgNBFBUKMgoGBAAEAAIFEgNEBB0aIyBUcmln
Z2VycyBvbiB0b29sIGNhbGwgY29tcGxldGlvbi4KCg4KBwQABAACBQESA0QEGAoOCgcEAAQA
AgUCEgNEGxwKOgoEBAACABIDSAJDGi0gT3B0aW9uYWwuIERpc3BsYXkgbmFtZSBmb3IgdGhl
IGluc3RydWN0aW9uLgoKDAoFBAACAAUSA0gCCAoMCgUEAAIAARIDSAkVCgwKBQQAAgADEgNI
GBkKDAoFBAACAAgSA0gaQgoPCggEAAIACJwIABIDSBtBCkYKBAQAAgESA0sCRho5IE9wdGlv
bmFsLiBUaGUgZGV0YWlsZWQgZGVzY3JpcHRpb24gb2YgdGhpcyBpbnN0cnVjdGlvbi4KCgwK
BQQAAgEFEgNLAggKDAoFBAACAQESA0sJGAoMCgUEAAIBAxIDSxscCgwKBQQAAgEIEgNLHUUK
DwoIBAACAQicCAASA0seRArTAQoEBAACAhIDUAJAGsUBIE9wdGlvbmFsLiBUaGUgY29uZGl0
aW9uIG9mIHRoZSBpbnN0cnVjdGlvbi4gRm9yIGV4YW1wbGUsICJ0aGUgY3VzdG9tZXIKIHdh
bnRzIHRvIGNhbmNlbCBhbiBvcmRlciIuICBJZiB0aGUgdXNlcnMgd2FudCB0aGUgaW5zdHJ1
Y3Rpb24gdG8gYmUKIHRyaWdnZXJlZCB1bmNvbmRpdGlvbmFsbHksIHRoZSBjb25kaXRpb24g
Y2FuIGJlIGVtcHR5LgoKDAoFBAACAgUSA1ACCAoMCgUEAAICARIDUAkSCgwKBQQAAgIDEgNQ
FRYKDAoFBAACAggSA1AXPwoPCggEAAICCJwIABIDUBg+CtEBCgQEAAIDEgNVAkMawwEgT3B0
aW9uYWwuIFRoZSBhY3Rpb24gdGhhdCBodW1hbiBhZ2VudCBzaG91bGQgdGFrZS4gRm9yIGV4
YW1wbGUsICJhcG9sb2dpemUKIGZvciB0aGUgc2xvdyBzaGlwcGluZyIuIElmIHRoZSB1c2Vy
cyBvbmx5IHdhbnQgdG8gdXNlIGFnZW50IGNvYWNoaW5nIGZvcgogaW50ZW50IGRldGVjdGlv
biwgYWdlbnRfYWN0aW9uIGNhbiBiZSBlbXB0eQoKDAoFBAACAwUSA1UCCAoMCgUEAAIDARID
VQkVCgwKBQQAAgMDEgNVGBkKDAoFBAACAwgSA1UaQgoPCggEAAIDCJwIABIDVRtBCv0BCgQE
AAIEEgNbAkQa7wEgT3B0aW9uYWwuIFRoZSBhY3Rpb24gdGhhdCBzeXN0ZW0gc2hvdWxkIHRh
a2UuIEZvciBleGFtcGxlLAogImNhbGwgR2V0T3JkZXJUaW1lIHdpdGggb3JkZXJfbnVtYmVy
PXtvcmRlciBudW1iZXIgcHJvdmlkZWQgYnkgdGhlCiBjdXN0b21lcn0iLiBJZiB0aGUgdXNl
cnMgZG9uJ3QgaGF2ZSBwbHVnaW5zIG9yIGRvbid0IHdhbnQgdG8gdHJpZ2dlcgogcGx1Z2lu
cywgdGhlIHN5c3RlbV9hY3Rpb24gY2FuIGJlIGVtcHR5CgoMCgUEAAIEBRIDWwIICgwKBQQA
AgQBEgNbCRYKDAoFBAACBAMSA1sZGgoMCgUEAAIECBIDWxtDCg8KCAQAAgQInAgAEgNbHEIK
UAoEBAACBRIEXgJfMhpCIE91dHB1dCBvbmx5LiBEdXBsaWNhdGlvbiBjaGVjayBmb3IgdGhl
IEFnZW50Q29hY2hpbmdJbnN0cnVjdGlvbi4KCgwKBQQAAgUGEgNeAhYKDAoFBAACBQESA14X
LQoMCgUEAAIFAxIDXjAxCgwKBQQAAgUIEgNfBjEKDwoIBAACBQicCAASA18HMAqlAQoEBAAC
BhIDZAJOGpcBIE9wdGlvbmFsLiBUaGUgZXZlbnQgdGhhdCBzaG91bGQgdHJpZ2dlciB0aGlz
IGluc3RydWN0aW9uLgogSWYgVU5TUEVDSUZJRUQsIHRoZSBpbnN0cnVjdGlvbiB0cmlnZ2Vy
aW5nIHdpbGwgYmUgc2FtZSBhcyB0aGUgZ2VuZXJhdG9yJ3MKIHRyaWdnZXJfZXZlbnQuCgoM
CgUEAAIGBhIDZAIOCgwKBQQAAgYBEgNkDx8KDAoFBAACBgMSA2QiJAoMCgUEAAIGCBIDZCVN
Cg8KCAQAAgYInAgAEgNkJkxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::AgentCoachingInstruction ===
    # Fields for AgentCoachingInstruction
    # Field: display_name Type: 9 ()
    # Field: display_details Type: 9 ()
    # Field: condition Type: 9 ()
    # Field: agent_action Type: 9 ()
    # Field: system_action Type: 9 ()
    # Field: duplicate_check_result Type: 11 (.google.cloud.dialogflow.v2.AgentCoachingInstruction.DuplicateCheckResult)
    # Field: triggering_event Type: 14 (.google.cloud.dialogflow.v2.AgentCoachingInstruction.TriggerEvent)

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

Google::Cloud::Dialogflow::V2::AgentCoachingInstruction - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/agent_coaching_instruction.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::AgentCoachingInstruction;

    my $msg = Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::AgentCoachingInstruction->new({
        display_name => $display_name,
        display_details => $display_details,
        condition => $condition,
        agent_action => $agent_action,
    });

    # Read or update a field
    my $val = $msg->display_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::AgentCoachingInstruction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/agent_coaching_instruction.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::AgentCoachingInstruction

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

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::AgentCoachingInstruction::DuplicateCheckResult>)

Output only. Duplication check for the AgentCoachingInstruction.

=item * C<< $msg->triggering_event() >> / C<< $msg->triggering_event($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::TriggerEvent>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::AgentCoachingInstruction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
