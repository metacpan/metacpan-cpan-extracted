package Google::Cloud::Ces::V1::AgentTransfers;

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
Cilnb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50X3RyYW5zZmVycy5wcm90bxITZ29vZ2xlLmNs
b3VkLmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90byI6ChNFeHByZXNzaW9uQ29uZGl0aW9uEiMKCmV4cHJlc3Npb24Y
ASABKAlCA+BBAlIKZXhwcmVzc2lvbiI7ChNQeXRob25Db2RlQ29uZGl0aW9uEiQKC3B5dGhv
bl9jb2RlGAEgASgJQgPgQQJSCnB5dGhvbkNvZGUi4wYKDFRyYW5zZmVyUnVsZRJ1ChZkZXRl
cm1pbmlzdGljX3RyYW5zZmVyGAMgASgLMjcuZ29vZ2xlLmNsb3VkLmNlcy52MS5UcmFuc2Zl
clJ1bGUuRGV0ZXJtaW5pc3RpY1RyYW5zZmVyQgPgQQFIAFIVZGV0ZXJtaW5pc3RpY1RyYW5z
ZmVyEnkKGGRpc2FibGVfcGxhbm5lcl90cmFuc2ZlchgEIAEoCzI4Lmdvb2dsZS5jbG91ZC5j
ZXMudjEuVHJhbnNmZXJSdWxlLkRpc2FibGVQbGFubmVyVHJhbnNmZXJCA+BBAUgAUhZkaXNh
YmxlUGxhbm5lclRyYW5zZmVyEkEKC2NoaWxkX2FnZW50GAEgASgJQiDgQQL6QRoKGGNlcy5n
b29nbGVhcGlzLmNvbS9BZ2VudFIKY2hpbGRBZ2VudBJOCglkaXJlY3Rpb24YAiABKA4yKy5n
b29nbGUuY2xvdWQuY2VzLnYxLlRyYW5zZmVyUnVsZS5EaXJlY3Rpb25CA+BBAlIJZGlyZWN0
aW9uGvIBChVEZXRlcm1pbmlzdGljVHJhbnNmZXISYgoUZXhwcmVzc2lvbl9jb25kaXRpb24Y
ASABKAsyKC5nb29nbGUuY2xvdWQuY2VzLnYxLkV4cHJlc3Npb25Db25kaXRpb25CA+BBAUgA
UhNleHByZXNzaW9uQ29uZGl0aW9uEmMKFXB5dGhvbl9jb2RlX2NvbmRpdGlvbhgCIAEoCzIo
Lmdvb2dsZS5jbG91ZC5jZXMudjEuUHl0aG9uQ29kZUNvbmRpdGlvbkID4EEBSABSE3B5dGhv
bkNvZGVDb25kaXRpb25CEAoOY29uZGl0aW9uX3R5cGUaegoWRGlzYWJsZVBsYW5uZXJUcmFu
c2ZlchJgChRleHByZXNzaW9uX2NvbmRpdGlvbhgBIAEoCzIoLmdvb2dsZS5jbG91ZC5jZXMu
djEuRXhwcmVzc2lvbkNvbmRpdGlvbkID4EECUhNleHByZXNzaW9uQ29uZGl0aW9uIlAKCURp
cmVjdGlvbhIZChVESVJFQ1RJT05fVU5TUEVDSUZJRUQQABITCg9QQVJFTlRfVE9fQ0hJTEQQ
ARITCg9DSElMRF9UT19QQVJFTlQQAkILCglydWxlX3R5cGVCWwoXY29tLmdvb2dsZS5jbG91
ZC5jZXMudjFCE0FnZW50VHJhbnNmZXJzUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9j
ZXMvYXBpdjEvY2VzcGI7Y2VzcGJKxxkKBhIEDgBkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQBA
CgkKAggLEgMVAEAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA0CgkKAggIEgMXADQK
CAoBCBIDGAAwCgkKAggBEgMYADAKOgoCBAASBBsAHgEaLiBFeHByZXNzaW9uIGNvbmRpdGlv
biBiYXNlZCBvbiBzZXNzaW9uIHN0YXRlLgoKCgoDBAABEgMbCBsKVQoEBAACABIDHQJBGkgg
UmVxdWlyZWQuIFRoZSBzdHJpbmcgcmVwcmVzZW50YXRpb24gb2YgY2xvdWQuYXBpLkV4cHJl
c3Npb24gY29uZGl0aW9uLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkTCgwKBQQAAgAD
EgMdFhcKDAoFBAACAAgSAx0YQAoPCggEAAIACJwIABIDHRk/CjoKAgQBEgQhACQBGi4gUHl0
aG9uIGNvZGUgYmxvY2sgdG8gZXZhbHVhdGUgdGhlIGNvbmRpdGlvbi4KCgoKAwQBARIDIQgb
CjQKBAQBAgASAyMCQhonIFJlcXVpcmVkLiBUaGUgcHl0aG9uIGNvZGUgdG8gZXhlY3V0ZS4K
CgwKBQQBAgAFEgMjAggKDAoFBAECAAESAyMJFAoMCgUEAQIAAxIDIxcYCgwKBQQBAgAIEgMj
GUEKDwoIBAECAAicCAASAyMaQAo4CgIEAhIEJwBkARosIFJ1bGUgZm9yIHRyYW5zZmVycmlu
ZyB0byBhIHNwZWNpZmljIGFnZW50LgoKCgoDBAIBEgMnCBQKaAoEBAIDABIEKgI3AxpaIERl
dGVybWluaXN0aWMgdHJhbnNmZXIgcnVsZS4gV2hlbiB0aGUgY29uZGl0aW9uIGV2YWx1YXRl
cyB0byB0cnVlLCB0aGUKIHRyYW5zZmVyIG9jY3Vycy4KCgwKBQQCAwABEgMqCh8KLAoGBAID
AAgAEgQsBDYFGhwgVGhlIGNvbmRpdGlvbiB0byBldmFsdWF0ZS4KCg4KBwQCAwAIAAESAywK
GAqGAQoGBAIDAAIAEgQvBjAzGnYgT3B0aW9uYWwuIEEgcnVsZSB0aGF0IGV2YWx1YXRlcyBh
IHNlc3Npb24gc3RhdGUgY29uZGl0aW9uLgogSWYgdGhlIGNvbmRpdGlvbiBldmFsdWF0ZXMg
dG8gdHJ1ZSwgdGhlIHRyYW5zZmVyIG9jY3Vycy4KCg4KBwQCAwACAAYSAy8GGQoOCgcEAgMA
AgABEgMvGi4KDgoHBAIDAAIAAxIDLzEyCg4KBwQCAwACAAgSAzAKMgoRCgoEAgMAAgAInAgA
EgMwCzEKlQEKBgQCAwACARIENAY1MxqEASBPcHRpb25hbC4gQSBydWxlIHRoYXQgdXNlcyBQ
eXRob24gY29kZSBibG9jayB0byBldmFsdWF0ZSB0aGUKIGNvbmRpdGlvbnMuIElmIHRoZSBj
b25kaXRpb24gZXZhbHVhdGVzIHRvIHRydWUsIHRoZSB0cmFuc2ZlciBvY2N1cnMuCgoOCgcE
AgMAAgEGEgM0BhkKDgoHBAIDAAIBARIDNBovCg4KBwQCAwACAQMSAzQyMwoOCgcEAgMAAgEI
EgM1CjIKEQoKBAIDAAIBCJwIABIDNQsxClcKBAQCAwESBDoCPwMaSSBBIHJ1bGUgdGhhdCBw
cmV2ZW50cyB0aGUgcGxhbm5lciBmcm9tIHRyYW5zZmVycmluZyB0byB0aGUgdGFyZ2V0IGFn
ZW50LgoKDAoFBAIDAQESAzoKIAp9CgYEAgMBAgASBD0EPjEabSBSZXF1aXJlZC4gSWYgdGhl
IGNvbmRpdGlvbiBldmFsdWF0ZXMgdG8gdHJ1ZSwgcGxhbm5lciB3aWxsIG5vdCBiZSBhbGxv
d2VkCiB0byB0cmFuc2ZlciB0byB0aGUgdGFyZ2V0IGFnZW50LgoKDgoHBAIDAQIABhIDPQQX
Cg4KBwQCAwECAAESAz0YLAoOCgcEAgMBAgADEgM9LzAKDgoHBAIDAQIACBIDPggwChEKCgQC
AwECAAicCAASAz4JLwouCgQEAgQAEgRCAksDGiAgVGhlIGRpcmVjdGlvbiBvZiB0aGUgdHJh
bnNmZXIuCgoMCgUEAgQAARIDQgcQCicKBgQCBAACABIDRAQeGhggVW5zcGVjaWZpZWQgZGly
ZWN0aW9uLgoKDgoHBAIEAAIAARIDRAQZCg4KBwQCBAACAAISA0QcHQpDCgYEAgQAAgESA0cE
GBo0IFRyYW5zZmVyIGZyb20gdGhlIHBhcmVudCBhZ2VudCB0byB0aGUgY2hpbGQgYWdlbnQu
CgoOCgcEAgQAAgEBEgNHBBMKDgoHBAIEAAIBAhIDRxYXCkMKBgQCBAACAhIDSgQYGjQgVHJh
bnNmZXIgZnJvbSB0aGUgY2hpbGQgYWdlbnQgdG8gdGhlIHBhcmVudCBhZ2VudC4KCg4KBwQC
BAACAgESA0oEEwoOCgcEAgQAAgICEgNKFhcKHgoEBAIIABIETgJYAxoQIFRoZSBydWxlIHR5
cGUuCgoMCgUEAggAARIDTggRCmsKBAQCAgASBFEEUjEaXSBPcHRpb25hbC4gQSBydWxlIHRo
YXQgaW1tZWRpYXRlbHkgdHJhbnNmZXJzIHRvIHRoZSB0YXJnZXQgYWdlbnQgd2hlbiB0aGUK
IGNvbmRpdGlvbiBpcyBtZXQuCgoMCgUEAgIABhIDUQQZCgwKBQQCAgABEgNRGjAKDAoFBAIC
AAMSA1EzNAoMCgUEAgIACBIDUggwCg8KCAQCAgAInAgAEgNSCS8KYAoEBAICARIEVgRXMRpS
IE9wdGlvbmFsLiBSdWxlIHRoYXQgcHJldmVudHMgdGhlIHBsYW5uZXIgZnJvbSB0cmFuc2Zl
cnJpbmcgdG8gdGhlIHRhcmdldAogYWdlbnQuCgoMCgUEAgIBBhIDVgQaCgwKBQQCAgEBEgNW
GzMKDAoFBAICAQMSA1Y2NwoMCgUEAgIBCBIDVwgwCg8KCAQCAgEInAgAEgNXCS8KogEKBAQC
AgISBF0CYAQakwEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjaGlsZCBh
Z2VudCB0aGUgcnVsZSBhcHBsaWVzIHRvLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2FnZW50cy97YWdlbnR9YAoKDAoF
BAICAgUSA10CCAoMCgUEAgICARIDXQkUCgwKBQQCAgIDEgNdFxgKDQoFBAICAggSBF0ZYAMK
DwoIBAICAgicCAASA14EKgoOCgcEAgICCJ8IEgNfBEoKNwoEBAICAxIDYwJDGiogUmVxdWly
ZWQuIFRoZSBkaXJlY3Rpb24gb2YgdGhlIHRyYW5zZmVyLgoKDAoFBAICAwYSA2MCCwoMCgUE
AgIDARIDYwwVCgwKBQQCAgMDEgNjGBkKDAoFBAICAwgSA2MaQgoPCggEAgIDCJwIABIDYxtB
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition ===
    # Fields for ExpressionCondition
    # Field: expression Type: 9 ()

# === Message: Google::Cloud::Ces::V1::AgentTransfers::PythonCodeCondition ===
    # Fields for PythonCodeCondition
    # Field: python_code Type: 9 ()

# === Message: Google::Cloud::Ces::V1::AgentTransfers::TransferRule ===
    # Fields for TransferRule
    # Field: deterministic_transfer Type: 11 (.google.cloud.ces.v1.TransferRule.DeterministicTransfer)
    # Field: disable_planner_transfer Type: 11 (.google.cloud.ces.v1.TransferRule.DisablePlannerTransfer)
    # Field: child_agent Type: 9 ()
    # Field: direction Type: 14 (.google.cloud.ces.v1.TransferRule.Direction)

# Enum: TransferRule::Direction
our $TransferRule_DIRECTION_UNSPECIFIED = 0;
our $TransferRule_PARENT_TO_CHILD = 1;
our $TransferRule_CHILD_TO_PARENT = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::AgentTransfers - Compiled Protocol Buffers messages for google/cloud/ces/v1/agent_transfers.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::AgentTransfers;

    my $msg = Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition->new({
        expression => $expression,
    });

    # Read or update a field
    my $val = $msg->expression();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/agent_transfers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition

Expression condition based on session state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expression() >> / C<< $msg->expression($value) >>

Type: C<String>

Required. The string representation of cloud.api.Expression condition.

=back

=head2 Google::Cloud::Ces::V1::AgentTransfers::PythonCodeCondition

Python code block to evaluate the condition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->python_code() >> / C<< $msg->python_code($value) >>

Type: C<String>

Required. The python code to execute.

=back

=head2 Google::Cloud::Ces::V1::AgentTransfers::TransferRule

Rule for transferring to a specific agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deterministic_transfer() >> / C<< $msg->deterministic_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DeterministicTransfer>)

Optional. A rule that immediately transfers to the target agent when the
condition is met.

=item * C<< $msg->disable_planner_transfer() >> / C<< $msg->disable_planner_transfer($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DisablePlannerTransfer>)

Optional. Rule that prevents the planner from transferring to the target
agent.

=item * C<< $msg->child_agent() >> / C<< $msg->child_agent($value) >>

Type: C<String>

Required. The resource name of the child agent the rule applies to.
Format:
`projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->direction() >> / C<< $msg->direction($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::TransferRule::Direction>)

Required. The direction of the transfer.

=back

=head3 Enum: TransferRule::Direction

=over 4

=item * C<DIRECTION_UNSPECIFIED> => C<0>

=item * C<PARENT_TO_CHILD> => C<1>

=item * C<CHILD_TO_PARENT> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::AgentTransfers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
