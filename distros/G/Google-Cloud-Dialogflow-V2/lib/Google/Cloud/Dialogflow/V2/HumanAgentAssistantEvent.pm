package Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Dialogflow::V2::Participant };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9odW1hbl9hZ2VudF9hc3Npc3RhbnRfZXZl
bnQucHJvdG8SGmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyGixnb29nbGUvY2xvdWQvZGlh
bG9nZmxvdy92Mi9wYXJ0aWNpcGFudC5wcm90byK9AQoYSHVtYW5BZ2VudEFzc2lzdGFudEV2
ZW50EiIKDGNvbnZlcnNhdGlvbhgBIAEoCVIMY29udmVyc2F0aW9uEiAKC3BhcnRpY2lwYW50
GAMgASgJUgtwYXJ0aWNpcGFudBJbChJzdWdnZXN0aW9uX3Jlc3VsdHMYBSADKAsyLC5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5TdWdnZXN0aW9uUmVzdWx0UhFzdWdnZXN0aW9uUmVz
dWx0c0KjAQoeY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyQh1IdW1hbkFnZW50QXNz
aXN0YW50RXZlbnRQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBp
djIvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29vZ2xlLkNsb3VkLkRpYWxv
Z2Zsb3cuVjJKnAsKBhIEDgApAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIwoJCgIDABIDEgA2CggKAQgSAxQANwoJCgIIJRIDFAA3CggKAQgSAxUAVQoJ
CgIICxIDFQBVCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAPgoJCgIICBIDFwA+CggK
AQgSAxgANwoJCgIIARIDGAA3CggKAQgSAxkAIAoJCgIIJBIDGQAgCocBCgIEABIEHQApARp7
IFJlcHJlc2VudHMgYSBub3RpZmljYXRpb24gc2VudCB0byBDbG91ZCBQdWIvU3ViIHN1YnNj
cmliZXJzIGZvcgogaHVtYW4gYWdlbnQgYXNzaXN0YW50IGV2ZW50cyBpbiBhIHNwZWNpZmlj
IGNvbnZlcnNhdGlvbi4KCgoKAwQAARIDHQggCn4KBAQAAgASAyACGhpxIFRoZSBjb252ZXJz
YXRpb24gdGhpcyBub3RpZmljYXRpb24gcmVmZXJzIHRvLgogRm9ybWF0OiBgcHJvamVjdHMv
PFByb2plY3QgSUQ+L2NvbnZlcnNhdGlvbnMvPENvbnZlcnNhdGlvbiBJRD5gLgoKDAoFBAAC
AAUSAyACCAoMCgUEAAIAARIDIAkVCgwKBQQAAgADEgMgGBkKzAEKBAQAAgESAyUCGRq+ASBU
aGUgcGFydGljaXBhbnQgdGhhdCB0aGUgc3VnZ2VzdGlvbiBpcyBjb21waWxlZCBmb3IuCiBG
b3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vY29udmVyc2F0aW9ucy88Q29udmVyc2F0
aW9uCiBJRD4vcGFydGljaXBhbnRzLzxQYXJ0aWNpcGFudCBJRD5gLiBJdCB3aWxsIG5vdCBi
ZSBzZXQgaW4gbGVnYWN5IHdvcmtmbG93LgoKDAoFBAACAQUSAyUCCAoMCgUEAAIBARIDJQkU
CgwKBQQAAgEDEgMlFxgKTwoEBAACAhIDKAIzGkIgVGhlIHN1Z2dlc3Rpb24gcmVzdWx0cyBw
YXlsb2FkIHRoYXQgdGhpcyBub3RpZmljYXRpb24gcmVmZXJzIHRvLgoKDAoFBAACAgQSAygC
CgoMCgUEAAICBhIDKAsbCgwKBQQAAgIBEgMoHC4KDAoFBAACAgMSAygxMmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent ===
    # Fields for HumanAgentAssistantEvent
    # Field: conversation Type: 9 ()
    # Field: participant Type: 9 ()
    # Field: suggestion_results Type: 11 (.google.cloud.dialogflow.v2.SuggestionResult)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/human_agent_assistant_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent;

    my $msg = Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent->new({
        conversation => $conversation,
        participant => $participant,
        suggestion_results => $suggestion_results,
    });

    # Read or update a field
    my $val = $msg->conversation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/human_agent_assistant_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::HumanAgentAssistantEvent

Represents a notification sent to Cloud Pub/Sub subscribers for
human agent assistant events in a specific conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<String>

The conversation this notification refers to.
Format: `projects/<Project ID>/conversations/<Conversation ID>`.

=item * C<< $msg->participant() >> / C<< $msg->participant($value) >>

Type: C<String>

The participant that the suggestion is compiled for.
Format: `projects/<Project ID>/conversations/<Conversation
ID>/participants/<Participant ID>`. It will not be set in legacy workflow.

=item * C<< $msg->suggestion_results() >> / C<< $msg->suggestion_results($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::SuggestionResult>)

The suggestion results payload that this notification refers to.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::HumanAgentAssistantEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
