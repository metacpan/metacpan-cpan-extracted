package Google::Cloud::Dialogflow::V2beta1::ConversationEvent;

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
    eval { require Google::Cloud::Dialogflow::V2beta1::Participant };
    eval { require Google::Cloud::Dialogflow::V2beta1::Session };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL2NvbnZlcnNhdGlvbl9ldmVudC5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29vZ2xlL2Ns
b3VkL2RpYWxvZ2Zsb3cvdjJiZXRhMS9wYXJ0aWNpcGFudC5wcm90bxotZ29vZ2xlL2Nsb3Vk
L2RpYWxvZ2Zsb3cvdjJiZXRhMS9zZXNzaW9uLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5w
cm90byLgBAoRQ29udmVyc2F0aW9uRXZlbnQSIgoMY29udmVyc2F0aW9uGAEgASgJUgxjb252
ZXJzYXRpb24SSwoEdHlwZRgCIAEoDjI3Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0
YTEuQ29udmVyc2F0aW9uRXZlbnQuVHlwZVIEdHlwZRI1CgxlcnJvcl9zdGF0dXMYAyABKAsy
Ei5nb29nbGUucnBjLlN0YXR1c1ILZXJyb3JTdGF0dXMSWgoTbmV3X21lc3NhZ2VfcGF5bG9h
ZBgEIAEoCzIoLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuTWVzc2FnZUgAUhFu
ZXdNZXNzYWdlUGF5bG9hZBKCAQoebmV3X3JlY29nbml0aW9uX3Jlc3VsdF9wYXlsb2FkGAUg
ASgLMjsuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TdHJlYW1pbmdSZWNvZ25p
dGlvblJlc3VsdEgAUhtuZXdSZWNvZ25pdGlvblJlc3VsdFBheWxvYWQitgEKBFR5cGUSFAoQ
VFlQRV9VTlNQRUNJRklFRBAAEhgKFENPTlZFUlNBVElPTl9TVEFSVEVEEAESGQoVQ09OVkVS
U0FUSU9OX0ZJTklTSEVEEAISHQoZSFVNQU5fSU5URVJWRU5USU9OX05FRURFRBADEg8KC05F
V19NRVNTQUdFEAUSGgoWTkVXX1JFQ09HTklUSU9OX1JFU1VMVBAHEhcKE1VOUkVDT1ZFUkFC
TEVfRVJST1IQBEIJCgdwYXlsb2FkQqsBCiNjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMUIWQ29udmVyc2F0aW9uRXZlbnRQcm90b1ABWkNjbG91ZC5nb29nbGUuY29tL2dv
L2RpYWxvZ2Zsb3cvYXBpdjJiZXRhMS9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogICREaq
Ah9Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkJldGExStQaCgYSBA4AYQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwASAxIAKQoJCgIDARID
EwAjCgkKAgMCEgMUADsKCQoCAwMSAxUANwoJCgIDBBIDFgAhCggKAQgSAxgAPAoJCgIIJRID
GAA8CggKAQgSAxkAWgoJCgIICxIDGQBaCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsA
NwoJCgIICBIDGwA3CggKAQgSAxwAPAoJCgIIARIDHAA8CggKAQgSAx0AIAoJCgIIJBIDHQAg
CmcKAgQAEgQhAGEBGlsgUmVwcmVzZW50cyBhIG5vdGlmaWNhdGlvbiBzZW50IHRvIFB1Yi9T
dWIgc3Vic2NyaWJlcnMgZm9yIGNvbnZlcnNhdGlvbgogbGlmZWN5Y2xlIGV2ZW50cy4KCgoK
AwQAARIDIQgZCj0KBAQABAASBCMCSwMaLyBFbnVtZXJhdGlvbiBvZiB0aGUgdHlwZXMgb2Yg
ZXZlbnRzIGF2YWlsYWJsZS4KCgwKBQQABAABEgMjBwsKHgoGBAAEAAIAEgMlBBkaDyBUeXBl
IG5vdCBzZXQuCgoOCgcEAAQAAgABEgMlBBQKDgoHBAAEAAIAAhIDJRcYCpEBCgYEAAQAAgES
AykEHRqBASBBIG5ldyBjb252ZXJzYXRpb24gaGFzIGJlZW4gb3BlbmVkLiBUaGlzIGlzIGZp
cmVkIHdoZW4gYSB0ZWxlcGhvbmUgY2FsbAogaXMgYW5zd2VyZWQsIG9yIGEgY29udmVyc2F0
aW9uIGlzIGNyZWF0ZWQgdmlhIHRoZSBBUEkuCgoOCgcEAAQAAgEBEgMpBBgKDgoHBAAEAAIB
AhIDKRscCvkBCgYEAAQAAgISAy8EHhrpASBBbiBleGlzdGluZyBjb252ZXJzYXRpb24gaGFz
IGNsb3NlZC4gVGhpcyBpcyBmaXJlZCB3aGVuIGEgdGVsZXBob25lIGNhbGwKIGlzIHRlcm1p
bmF0ZWQsIG9yIGEgY29udmVyc2F0aW9uIGlzIGNsb3NlZCB2aWEgdGhlIEFQSS4KIFRoZSBl
dmVudCBpcyBmaXJlZCBmb3IgZXZlcnkgQ29tcGxldGVDb252ZXJzYXRpb24gY2FsbCwgZXZl
biBpZiB0aGUKIGNvbnZlcnNhdGlvbiBpcyBhbHJlYWR5IGNsb3NlZC4KCg4KBwQABAACAgES
Ay8EGQoOCgcEAAQAAgICEgMvHB0KeQoGBAAEAAIDEgMzBCIaaiBBbiBleGlzdGluZyBjb252
ZXJzYXRpb24gaGFzIHJlY2VpdmVkIG5vdGlmaWNhdGlvbiBmcm9tIERpYWxvZ2Zsb3cgdGhh
dAogaHVtYW4gaW50ZXJ2ZW50aW9uIGlzIHJlcXVpcmVkLgoKDgoHBAAEAAIDARIDMwQdCg4K
BwQABAACAwISAzMgIQqRAgoGBAAEAAIEEgM4BBQagQIgQW4gZXhpc3RpbmcgY29udmVyc2F0
aW9uIGhhcyByZWNlaXZlZCBhIG5ldyBtZXNzYWdlLCBlaXRoZXIgZnJvbSBBUEkgb3IKIHRl
bGVwaG9ueS4gSXQgaXMgY29uZmlndXJlZCBpbgogW0NvbnZlcnNhdGlvblByb2ZpbGUubmV3
X21lc3NhZ2VfZXZlbnRfbm90aWZpY2F0aW9uX2NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpYWxv
Z2Zsb3cudjJiZXRhMS5Db252ZXJzYXRpb25Qcm9maWxlLm5ld19tZXNzYWdlX2V2ZW50X25v
dGlmaWNhdGlvbl9jb25maWddCgoOCgcEAAQAAgQBEgM4BA8KDgoHBAAEAAIEAhIDOBITCvgB
CgYEAAQAAgUSAz4EHxroASBBbiBleGlzdGluZyBjb252ZXJzYXRpb24gaGFzIHJlY2VpdmVk
IGEgbmV3IHNwZWVjaCByZWNvZ25pdGlvbiByZXN1bHQuCiBUaGlzIGlzIG1haW5seSBmb3Ig
ZGVsaXZlcmluZyBpbnRlcm1lZGlhdGUgdHJhbnNjcmlwdHMuIFRoZSBub3RpZmljYXRpb24K
IGlzIGNvbmZpZ3VyZWQgaW4KIFtDb252ZXJzYXRpb25Qcm9maWxlLm5ld19yZWNvZ25pdGlv
bl9ldmVudF9ub3RpZmljYXRpb25fY29uZmlnXVtdLgoKDgoHBAAEAAIFARIDPgQaCg4KBwQA
BAACBQISAz4dHgqGAwoGBAAEAAIGEgNKBBwa9gIgVW5yZWNvdmVyYWJsZSBlcnJvciBkdXJp
bmcgYSB0ZWxlcGhvbmUgY2FsbC4KCiBJbiBnZW5lcmFsIG5vbi1yZWNvdmVyYWJsZSBlcnJv
cnMgb25seSBvY2N1ciBpZiBzb21ldGhpbmcgd2FzCiBtaXNjb25maWd1cmVkIGluIHRoZSBD
b252ZXJzYXRpb25Qcm9maWxlIGNvcnJlc3BvbmRpbmcgdG8gdGhlIGNhbGwuIEFmdGVyCiBh
IG5vbi1yZWNvdmVyYWJsZSBlcnJvciwgRGlhbG9nZmxvdyBtYXkgc3RvcCByZXNwb25kaW5n
LgoKIFdlIGRvbid0IGZpcmUgdGhpcyBldmVudDoKCiAqIGluIGFuIEFQSSBjYWxsIGJlY2F1
c2Ugd2UgY2FuIGRpcmVjdGx5IHJldHVybiB0aGUgZXJyb3IsIG9yLAogKiB3aGVuIHdlIGNh
biByZWNvdmVyIGZyb20gYW4gZXJyb3IuCgoOCgcEAAQAAgYBEgNKBBcKDgoHBAAEAAIGAhID
ShobCqMBCgQEAAIAEgNQAhoalQEgUmVxdWlyZWQuIFRoZSB1bmlxdWUgaWRlbnRpZmllciBv
ZiB0aGUgY29udmVyc2F0aW9uIHRoaXMgbm90aWZpY2F0aW9uCiByZWZlcnMgdG8uCiBGb3Jt
YXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vY29udmVyc2F0aW9ucy88Q29udmVyc2F0aW9u
IElEPmAuCgoMCgUEAAIABRIDUAIICgwKBQQAAgABEgNQCRUKDAoFBAACAAMSA1AYGQpQCgQE
AAIBEgNTAhAaQyBSZXF1aXJlZC4gVGhlIHR5cGUgb2YgdGhlIGV2ZW50IHRoYXQgdGhpcyBu
b3RpZmljYXRpb24gcmVmZXJzIHRvLgoKDAoFBAACAQYSA1MCBgoMCgUEAAIBARIDUwcLCgwK
BQQAAgEDEgNTDg8KeAoEBAACAhIDVwIlGmsgT3B0aW9uYWwuIE1vcmUgZGV0YWlsZWQgaW5m
b3JtYXRpb24gYWJvdXQgYW4gZXJyb3IuIE9ubHkgc2V0IGZvciB0eXBlCiBVTlJFQ09WRVJB
QkxFX0VSUk9SX0lOX1BIT05FX0NBTEwuCgoMCgUEAAICBhIDVwITCgwKBQQAAgIBEgNXFCAK
DAoFBAACAgMSA1cjJAouCgQEAAgAEgRaAmADGiAgUGF5bG9hZCBvZiBjb252ZXJzYXRpb24g
ZXZlbnQuCgoMCgUEAAgAARIDWggPCiwKBAQAAgMSA1wEJBofIFBheWxvYWQgb2YgTkVXX01F
U1NBR0UgZXZlbnQuCgoMCgUEAAIDBhIDXAQLCgwKBQQAAgMBEgNcDB8KDAoFBAACAwMSA1wi
Iwo3CgQEAAIEEgNfBEIaKiBQYXlsb2FkIG9mIE5FV19SRUNPR05JVElPTl9SRVNVTFQgZXZl
bnQuCgoMCgUEAAIEBhIDXwQeCgwKBQQAAgQBEgNfHz0KDAoFBAACBAMSA19AQWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent ===
    # Fields for ConversationEvent
    # Field: conversation Type: 9 ()
    # Field: type Type: 14 (.google.cloud.dialogflow.v2beta1.ConversationEvent.Type)
    # Field: error_status Type: 11 (.google.rpc.Status)
    # Field: new_message_payload Type: 11 (.google.cloud.dialogflow.v2beta1.Message)
    # Field: new_recognition_result_payload Type: 11 (.google.cloud.dialogflow.v2beta1.StreamingRecognitionResult)

# Enum: ConversationEvent::Type
our $ConversationEvent_TYPE_UNSPECIFIED = 0;
our $ConversationEvent_CONVERSATION_STARTED = 1;
our $ConversationEvent_CONVERSATION_FINISHED = 2;
our $ConversationEvent_HUMAN_INTERVENTION_NEEDED = 3;
our $ConversationEvent_NEW_MESSAGE = 5;
our $ConversationEvent_NEW_RECOGNITION_RESULT = 7;
our $ConversationEvent_UNRECOVERABLE_ERROR = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::ConversationEvent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/conversation_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::ConversationEvent;

    my $msg = Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent->new({
        conversation => $conversation,
        type => $type,
        error_status => $error_status,
        new_message_payload => $new_message_payload,
    });

    # Read or update a field
    my $val = $msg->conversation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/conversation_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent

Represents a notification sent to Pub/Sub subscribers for conversation
lifecycle events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<String>

Required. The unique identifier of the conversation this notification
refers to.
Format: `projects/<Project ID>/conversations/<Conversation ID>`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::ConversationEvent::Type>)

Required. The type of the event that this notification refers to.

=item * C<< $msg->error_status() >> / C<< $msg->error_status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Optional. More detailed information about an error. Only set for type
UNRECOVERABLE_ERROR_IN_PHONE_CALL.

=item * C<< $msg->new_message_payload() >> / C<< $msg->new_message_payload($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Participant::Message>)

Payload of NEW_MESSAGE event.

=item * C<< $msg->new_recognition_result_payload() >> / C<< $msg->new_recognition_result_payload($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::Session::StreamingRecognitionResult>)

Payload of NEW_RECOGNITION_RESULT event.

=back

=head3 Enum: ConversationEvent::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CONVERSATION_STARTED> => C<1>

=item * C<CONVERSATION_FINISHED> => C<2>

=item * C<HUMAN_INTERVENTION_NEEDED> => C<3>

=item * C<NEW_MESSAGE> => C<5>

=item * C<NEW_RECOGNITION_RESULT> => C<7>

=item * C<UNRECOVERABLE_ERROR> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::ConversationEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
