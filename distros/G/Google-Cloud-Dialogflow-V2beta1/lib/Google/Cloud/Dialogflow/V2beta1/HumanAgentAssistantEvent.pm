package Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Dialogflow::V2beta1::Participant };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2h1bWFuX2FnZW50X2Fzc2lzdGFu
dF9ldmVudC5wcm90bxIfZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRoxZ29vZ2xl
L2Nsb3VkL2RpYWxvZ2Zsb3cvdjJiZXRhMS9wYXJ0aWNpcGFudC5wcm90byLCAQoYSHVtYW5B
Z2VudEFzc2lzdGFudEV2ZW50EiIKDGNvbnZlcnNhdGlvbhgBIAEoCVIMY29udmVyc2F0aW9u
EiAKC3BhcnRpY2lwYW50GAMgASgJUgtwYXJ0aWNpcGFudBJgChJzdWdnZXN0aW9uX3Jlc3Vs
dHMYBSADKAsyMS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlN1Z2dlc3Rpb25S
ZXN1bHRSEXN1Z2dlc3Rpb25SZXN1bHRzQrIBCiNjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zs
b3cudjJiZXRhMUIdSHVtYW5BZ2VudEFzc2lzdGFudEV2ZW50UHJvdG9QAVpDY2xvdWQuZ29v
Z2xlLmNvbS9nby9kaWFsb2dmbG93L2FwaXYyYmV0YTEvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zs
b3dwYqICAkRGqgIfR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJCZXRhMUr1DgoGEgQOADEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMS
ADsKCAoBCBIDFAA8CgkKAgglEgMUADwKCAoBCBIDFQBaCgkKAggLEgMVAFoKCAoBCBIDFgAi
CgkKAggKEgMWACIKCAoBCBIDFwA+CgkKAggIEgMXAD4KCAoBCBIDGAA8CgkKAggBEgMYADwK
CAoBCBIDGQAgCgkKAggkEgMZACAKiAEKAgQAEgQdADEBGnwgT3V0cHV0IG9ubHkuIFJlcHJl
c2VudHMgYSBub3RpZmljYXRpb24gc2VudCB0byBQdWIvU3ViIHN1YnNjcmliZXJzIGZvcgog
YWdlbnQgYXNzaXN0YW50IGV2ZW50cyBpbiBhIHNwZWNpZmljIGNvbnZlcnNhdGlvbi4KCgoK
AwQAARIDHQggCn4KBAQAAgASAyACGhpxIFRoZSBjb252ZXJzYXRpb24gdGhpcyBub3RpZmlj
YXRpb24gcmVmZXJzIHRvLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2NvbnZl
cnNhdGlvbnMvPENvbnZlcnNhdGlvbiBJRD5gLgoKDAoFBAACAAUSAyACCAoMCgUEAAIAARID
IAkVCgwKBQQAAgADEgMgGBkKyQMKBAQAAgESAyoCGRq7AyBUaGUgcGFydGljaXBhbnQgdGhh
dCB0aGUgc3VnZ2VzdGlvbiBpcyBjb21waWxlZCBmb3IuIEFuZCBUaGlzIGZpZWxkIGlzIHVz
ZWQKIHRvIGNhbGwKIFtQYXJ0aWNpcGFudHMuTGlzdFN1Z2dlc3Rpb25zXVtnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MmJldGExLlBhcnRpY2lwYW50cy5MaXN0U3VnZ2VzdGlvbnNdCiBB
UEkuIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9jb252ZXJzYXRpb25zLzxDb252
ZXJzYXRpb24KIElEPi9wYXJ0aWNpcGFudHMvPFBhcnRpY2lwYW50IElEPmAuCiBJdCB3aWxs
IG5vdCBiZSBzZXQgaW4gbGVnYWN5IHdvcmtmbG93LgogW0h1bWFuQWdlbnRBc3Npc3RhbnRD
b25maWcubmFtZV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5IdW1hbkFnZW50
QXNzaXN0YW50Q29uZmlnLm5hbWVdCiBmb3IgbW9yZSBpbmZvcm1hdGlvbi4KCgwKBQQAAgEF
EgMqAggKDAoFBAACAQESAyoJFAoMCgUEAAIBAxIDKhcYCqkCCgQEAAICEgMwAjMamwIgVGhl
IHN1Z2dlc3Rpb24gcmVzdWx0cyBwYXlsb2FkIHRoYXQgdGhpcyBub3RpZmljYXRpb24gcmVm
ZXJzIHRvLiBJdCB3aWxsCiBvbmx5IGJlIHNldCB3aGVuCiBbSHVtYW5BZ2VudEFzc2lzdGFu
dENvbmZpZy5TdWdnZXN0aW9uQ29uZmlnLmdyb3VwX3N1Z2dlc3Rpb25fcmVzcG9uc2VzXVtn
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLkh1bWFuQWdlbnRBc3Npc3RhbnRDb25m
aWcuU3VnZ2VzdGlvbkNvbmZpZy5ncm91cF9zdWdnZXN0aW9uX3Jlc3BvbnNlc10KIHNldHMg
dG8gdHJ1ZS4KCgwKBQQAAgIEEgMwAgoKDAoFBAACAgYSAzALGwoMCgUEAAICARIDMBwuCgwK
BQQAAgIDEgMwMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent::HumanAgentAssistantEvent ===
    # Fields for HumanAgentAssistantEvent
    # Field: conversation Type: 9 ()
    # Field: participant Type: 9 ()
    # Field: suggestion_results Type: 11 (.google.cloud.dialogflow.v2beta1.SuggestionResult)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/human_agent_assistant_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent;

    my $msg = Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent::HumanAgentAssistantEvent->new({
        conversation => $conversation,
        participant => $participant,
        suggestion_results => $suggestion_results,
    });

    # Read or update a field
    my $val = $msg->conversation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent::HumanAgentAssistantEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/human_agent_assistant_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent::HumanAgentAssistantEvent

Output only. Represents a notification sent to Pub/Sub subscribers for
agent assistant events in a specific conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<String>

The conversation this notification refers to.
Format: `projects/<Project ID>/conversations/<Conversation ID>`.

=item * C<< $msg->participant() >> / C<< $msg->participant($value) >>

Type: C<String>

The participant that the suggestion is compiled for. And This field is used
to call
[Participants.ListSuggestions][google.cloud.dialogflow.v2beta1.Participants.ListSuggestions]
API. Format: `projects/<Project ID>/conversations/<Conversation
ID>/participants/<Participant ID>`.
It will not be set in legacy workflow.
[HumanAgentAssistantConfig.name][google.cloud.dialogflow.v2beta1.HumanAgentAssistantConfig.name]
for more information.

=item * C<< $msg->suggestion_results() >> / C<< $msg->suggestion_results($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Participant::SuggestionResult>)

The suggestion results payload that this notification refers to. It will
only be set when
[HumanAgentAssistantConfig.SuggestionConfig.group_suggestion_responses][google.cloud.dialogflow.v2beta1.HumanAgentAssistantConfig.SuggestionConfig.group_suggestion_responses]
sets to true.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::HumanAgentAssistantEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
