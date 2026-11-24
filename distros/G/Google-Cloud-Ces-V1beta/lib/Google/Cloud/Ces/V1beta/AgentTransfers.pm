package Google::Cloud::Ces::V1beta::AgentTransfers;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hZ2VudF90cmFuc2ZlcnMucHJvdG8SF2dvb2ds
ZS5jbG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvIjoKE0V4cHJlc3Npb25Db25kaXRpb24SIwoKZXhw
cmVzc2lvbhgBIAEoCUID4EECUgpleHByZXNzaW9uIjsKE1B5dGhvbkNvZGVDb25kaXRpb24S
JAoLcHl0aG9uX2NvZGUYASABKAlCA+BBAlIKcHl0aG9uQ29kZSL7BgoMVHJhbnNmZXJSdWxl
EnkKFmRldGVybWluaXN0aWNfdHJhbnNmZXIYAyABKAsyOy5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5UcmFuc2ZlclJ1bGUuRGV0ZXJtaW5pc3RpY1RyYW5zZmVyQgPgQQFIAFIVZGV0ZXJt
aW5pc3RpY1RyYW5zZmVyEn0KGGRpc2FibGVfcGxhbm5lcl90cmFuc2ZlchgEIAEoCzI8Lmdv
b2dsZS5jbG91ZC5jZXMudjFiZXRhLlRyYW5zZmVyUnVsZS5EaXNhYmxlUGxhbm5lclRyYW5z
ZmVyQgPgQQFIAFIWZGlzYWJsZVBsYW5uZXJUcmFuc2ZlchJBCgtjaGlsZF9hZ2VudBgBIAEo
CUIg4EEC+kEaChhjZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRSCmNoaWxkQWdlbnQSUgoJZGly
ZWN0aW9uGAIgASgOMi8uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuVHJhbnNmZXJSdWxlLkRp
cmVjdGlvbkID4EECUglkaXJlY3Rpb24a+gEKFURldGVybWluaXN0aWNUcmFuc2ZlchJmChRl
eHByZXNzaW9uX2NvbmRpdGlvbhgBIAEoCzIsLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkV4
cHJlc3Npb25Db25kaXRpb25CA+BBAUgAUhNleHByZXNzaW9uQ29uZGl0aW9uEmcKFXB5dGhv
bl9jb2RlX2NvbmRpdGlvbhgCIAEoCzIsLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlB5dGhv
bkNvZGVDb25kaXRpb25CA+BBAUgAUhNweXRob25Db2RlQ29uZGl0aW9uQhAKDmNvbmRpdGlv
bl90eXBlGn4KFkRpc2FibGVQbGFubmVyVHJhbnNmZXISZAoUZXhwcmVzc2lvbl9jb25kaXRp
b24YASABKAsyLC5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5FeHByZXNzaW9uQ29uZGl0aW9u
QgPgQQJSE2V4cHJlc3Npb25Db25kaXRpb24iUAoJRGlyZWN0aW9uEhkKFURJUkVDVElPTl9V
TlNQRUNJRklFRBAAEhMKD1BBUkVOVF9UT19DSElMRBABEhMKD0NISUxEX1RPX1BBUkVOVBAC
QgsKCXJ1bGVfdHlwZUJjChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCE0FnZW50VHJh
bnNmZXJzUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3Bi
O2Nlc3BiSscZCgYSBA4AZAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUARAoJCgIICxIDFQBECggK
AQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgIICBIDFwA0CggKAQgSAxgANAoJCgII
ARIDGAA0CjoKAgQAEgQbAB4BGi4gRXhwcmVzc2lvbiBjb25kaXRpb24gYmFzZWQgb24gc2Vz
c2lvbiBzdGF0ZS4KCgoKAwQAARIDGwgbClUKBAQAAgASAx0CQRpIIFJlcXVpcmVkLiBUaGUg
c3RyaW5nIHJlcHJlc2VudGF0aW9uIG9mIGNsb3VkLmFwaS5FeHByZXNzaW9uIGNvbmRpdGlv
bi4KCgwKBQQAAgAFEgMdAggKDAoFBAACAAESAx0JEwoMCgUEAAIAAxIDHRYXCgwKBQQAAgAI
EgMdGEAKDwoIBAACAAicCAASAx0ZPwo6CgIEARIEIQAkARouIFB5dGhvbiBjb2RlIGJsb2Nr
IHRvIGV2YWx1YXRlIHRoZSBjb25kaXRpb24uCgoKCgMEAQESAyEIGwo0CgQEAQIAEgMjAkIa
JyBSZXF1aXJlZC4gVGhlIHB5dGhvbiBjb2RlIHRvIGV4ZWN1dGUuCgoMCgUEAQIABRIDIwII
CgwKBQQBAgABEgMjCRQKDAoFBAECAAMSAyMXGAoMCgUEAQIACBIDIxlBCg8KCAQBAgAInAgA
EgMjGkAKOAoCBAISBCcAZAEaLCBSdWxlIGZvciB0cmFuc2ZlcnJpbmcgdG8gYSBzcGVjaWZp
YyBhZ2VudC4KCgoKAwQCARIDJwgUCmgKBAQCAwASBCoCNwMaWiBEZXRlcm1pbmlzdGljIHRy
YW5zZmVyIHJ1bGUuIFdoZW4gdGhlIGNvbmRpdGlvbiBldmFsdWF0ZXMgdG8gdHJ1ZSwgdGhl
CiB0cmFuc2ZlciBvY2N1cnMuCgoMCgUEAgMAARIDKgofCiwKBgQCAwAIABIELAQ2BRocIFRo
ZSBjb25kaXRpb24gdG8gZXZhbHVhdGUuCgoOCgcEAgMACAABEgMsChgKhgEKBgQCAwACABIE
LwYwMxp2IE9wdGlvbmFsLiBBIHJ1bGUgdGhhdCBldmFsdWF0ZXMgYSBzZXNzaW9uIHN0YXRl
IGNvbmRpdGlvbi4KIElmIHRoZSBjb25kaXRpb24gZXZhbHVhdGVzIHRvIHRydWUsIHRoZSB0
cmFuc2ZlciBvY2N1cnMuCgoOCgcEAgMAAgAGEgMvBhkKDgoHBAIDAAIAARIDLxouCg4KBwQC
AwACAAMSAy8xMgoOCgcEAgMAAgAIEgMwCjIKEQoKBAIDAAIACJwIABIDMAsxCpUBCgYEAgMA
AgESBDQGNTMahAEgT3B0aW9uYWwuIEEgcnVsZSB0aGF0IHVzZXMgUHl0aG9uIGNvZGUgYmxv
Y2sgdG8gZXZhbHVhdGUgdGhlCiBjb25kaXRpb25zLiBJZiB0aGUgY29uZGl0aW9uIGV2YWx1
YXRlcyB0byB0cnVlLCB0aGUgdHJhbnNmZXIgb2NjdXJzLgoKDgoHBAIDAAIBBhIDNAYZCg4K
BwQCAwACAQESAzQaLwoOCgcEAgMAAgEDEgM0MjMKDgoHBAIDAAIBCBIDNQoyChEKCgQCAwAC
AQicCAASAzULMQpXCgQEAgMBEgQ6Aj8DGkkgQSBydWxlIHRoYXQgcHJldmVudHMgdGhlIHBs
YW5uZXIgZnJvbSB0cmFuc2ZlcnJpbmcgdG8gdGhlIHRhcmdldCBhZ2VudC4KCgwKBQQCAwEB
EgM6CiAKfQoGBAIDAQIAEgQ9BD4xGm0gUmVxdWlyZWQuIElmIHRoZSBjb25kaXRpb24gZXZh
bHVhdGVzIHRvIHRydWUsIHBsYW5uZXIgd2lsbCBub3QgYmUgYWxsb3dlZAogdG8gdHJhbnNm
ZXIgdG8gdGhlIHRhcmdldCBhZ2VudC4KCg4KBwQCAwECAAYSAz0EFwoOCgcEAgMBAgABEgM9
GCwKDgoHBAIDAQIAAxIDPS8wCg4KBwQCAwECAAgSAz4IMAoRCgoEAgMBAgAInAgAEgM+CS8K
LgoEBAIEABIEQgJLAxogIFRoZSBkaXJlY3Rpb24gb2YgdGhlIHRyYW5zZmVyLgoKDAoFBAIE
AAESA0IHEAonCgYEAgQAAgASA0QEHhoYIFVuc3BlY2lmaWVkIGRpcmVjdGlvbi4KCg4KBwQC
BAACAAESA0QEGQoOCgcEAgQAAgACEgNEHB0KQwoGBAIEAAIBEgNHBBgaNCBUcmFuc2ZlciBm
cm9tIHRoZSBwYXJlbnQgYWdlbnQgdG8gdGhlIGNoaWxkIGFnZW50LgoKDgoHBAIEAAIBARID
RwQTCg4KBwQCBAACAQISA0cWFwpDCgYEAgQAAgISA0oEGBo0IFRyYW5zZmVyIGZyb20gdGhl
IGNoaWxkIGFnZW50IHRvIHRoZSBwYXJlbnQgYWdlbnQuCgoOCgcEAgQAAgIBEgNKBBMKDgoH
BAIEAAICAhIDShYXCh4KBAQCCAASBE4CWAMaECBUaGUgcnVsZSB0eXBlLgoKDAoFBAIIAAES
A04IEQprCgQEAgIAEgRRBFIxGl0gT3B0aW9uYWwuIEEgcnVsZSB0aGF0IGltbWVkaWF0ZWx5
IHRyYW5zZmVycyB0byB0aGUgdGFyZ2V0IGFnZW50IHdoZW4gdGhlCiBjb25kaXRpb24gaXMg
bWV0LgoKDAoFBAICAAYSA1EEGQoMCgUEAgIAARIDURowCgwKBQQCAgADEgNRMzQKDAoFBAIC
AAgSA1IIMAoPCggEAgIACJwIABIDUgkvCmAKBAQCAgESBFYEVzEaUiBPcHRpb25hbC4gUnVs
ZSB0aGF0IHByZXZlbnRzIHRoZSBwbGFubmVyIGZyb20gdHJhbnNmZXJyaW5nIHRvIHRoZSB0
YXJnZXQKIGFnZW50LgoKDAoFBAICAQYSA1YEGgoMCgUEAgIBARIDVhszCgwKBQQCAgEDEgNW
NjcKDAoFBAICAQgSA1cIMAoPCggEAgIBCJwIABIDVwkvCqIBCgQEAgICEgRdAmAEGpMBIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgY2hpbGQgYWdlbnQgdGhlIHJ1bGUg
YXBwbGllcyB0by4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vYXBwcy97YXBwfS9hZ2VudHMve2FnZW50fWAKCgwKBQQCAgIFEgNdAggKDAoF
BAICAgESA10JFAoMCgUEAgICAxIDXRcYCg0KBQQCAgIIEgRdGWADCg8KCAQCAgIInAgAEgNe
BCoKDgoHBAICAgifCBIDXwRKCjcKBAQCAgMSA2MCQxoqIFJlcXVpcmVkLiBUaGUgZGlyZWN0
aW9uIG9mIHRoZSB0cmFuc2Zlci4KCgwKBQQCAgMGEgNjAgsKDAoFBAICAwESA2MMFQoMCgUE
AgIDAxIDYxgZCgwKBQQCAgMIEgNjGkIKDwoIBAICAwicCAASA2MbQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::AgentTransfers::ExpressionCondition ===
    # Fields for ExpressionCondition
    # Field: expression Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::AgentTransfers::PythonCodeCondition ===
    # Fields for PythonCodeCondition
    # Field: python_code Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::AgentTransfers::TransferRule ===
    # Fields for TransferRule
    # Field: deterministic_transfer Type: 11 (.google.cloud.ces.v1beta.TransferRule.DeterministicTransfer)
    # Field: disable_planner_transfer Type: 11 (.google.cloud.ces.v1beta.TransferRule.DisablePlannerTransfer)
    # Field: child_agent Type: 9 ()
    # Field: direction Type: 14 (.google.cloud.ces.v1beta.TransferRule.Direction)

# Enum: TransferRule::Direction
our $TransferRule_DIRECTION_UNSPECIFIED = 0;
our $TransferRule_PARENT_TO_CHILD = 1;
our $TransferRule_CHILD_TO_PARENT = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::AgentTransfers - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/agent_transfers.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::AgentTransfers;

    my $msg = Google::Cloud::Ces::V1beta::AgentTransfers::ExpressionCondition->new({
        expression => $expression,
    });

    # Read or update a field
    my $val = $msg->expression();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::AgentTransfers::ExpressionCondition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/agent_transfers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::AgentTransfers::ExpressionCondition

Expression condition based on session state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expression() >> / C<< $msg->expression($value) >>

Type: C<String>

Required. The string representation of cloud.api.Expression condition.

=back

=head2 Google::Cloud::Ces::V1beta::AgentTransfers::PythonCodeCondition

Python code block to evaluate the condition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->python_code() >> / C<< $msg->python_code($value) >>

Type: C<String>

Required. The python code to execute.

=back

=head2 Google::Cloud::Ces::V1beta::AgentTransfers::TransferRule

Rule for transferring to a specific agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deterministic_transfer() >> / C<< $msg->deterministic_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentTransfers::TransferRule::DeterministicTransfer>)

Optional. A rule that immediately transfers to the target agent when the
condition is met.

=item * C<< $msg->disable_planner_transfer() >> / C<< $msg->disable_planner_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentTransfers::TransferRule::DisablePlannerTransfer>)

Optional. Rule that prevents the planner from transferring to the target
agent.

=item * C<< $msg->child_agent() >> / C<< $msg->child_agent($value) >>

Type: C<String>

Required. The resource name of the child agent the rule applies to.
Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::TransferRule::Direction>)

Required. The direction of the transfer.

=back

=head3 Enum: TransferRule::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<PARENT_TO_CHILD> => C<1>

=item * C<CHILD_TO_PARENT> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::AgentTransfers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
