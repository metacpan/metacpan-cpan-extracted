package Google::Cloud::Dialogflow::V2::ConversationEvent;

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
    eval { require Google::Cloud::Dialogflow::V2::Participant };
    eval { require Google::Cloud::Dialogflow::V2::Session };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jb252ZXJzYXRpb25fZXZlbnQucHJvdG8S
Gmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGixnb29nbGUvY2xvdWQvZGlhbG9n
Zmxvdy92Mi9wYXJ0aWNpcGFudC5wcm90bxooZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvdjIv
c2Vzc2lvbi5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8i0AQKEUNvbnZlcnNhdGlv
bkV2ZW50EiIKDGNvbnZlcnNhdGlvbhgBIAEoCVIMY29udmVyc2F0aW9uEkYKBHR5cGUYAiAB
KA4yMi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5Db252ZXJzYXRpb25FdmVudC5UeXBl
UgR0eXBlEjUKDGVycm9yX3N0YXR1cxgDIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzUgtlcnJv
clN0YXR1cxJVChNuZXdfbWVzc2FnZV9wYXlsb2FkGAQgASgLMiMuZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuTWVzc2FnZUgAUhFuZXdNZXNzYWdlUGF5bG9hZBJ9Ch5uZXdfcmVjb2du
aXRpb25fcmVzdWx0X3BheWxvYWQYBSABKAsyNi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52
Mi5TdHJlYW1pbmdSZWNvZ25pdGlvblJlc3VsdEgAUhtuZXdSZWNvZ25pdGlvblJlc3VsdFBh
eWxvYWQitgEKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEhgKFENPTlZFUlNBVElPTl9T
VEFSVEVEEAESGQoVQ09OVkVSU0FUSU9OX0ZJTklTSEVEEAISHQoZSFVNQU5fSU5URVJWRU5U
SU9OX05FRURFRBADEg8KC05FV19NRVNTQUdFEAUSGgoWTkVXX1JFQ09HTklUSU9OX1JFU1VM
VBAHEhcKE1VOUkVDT1ZFUkFCTEVfRVJST1IQBEIJCgdwYXlsb2FkQpwBCh5jb20uZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJCFkNvbnZlcnNhdGlvbkV2ZW50UHJvdG9QAVo+Y2xvdWQu
Z29vZ2xlLmNvbS9nby9kaWFsb2dmbG93L2FwaXYyL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93
cGKiAgJERqoCGkdvb2dsZS5DbG91ZC5EaWFsb2dmbG93LlYySrEaCgYSBA4AYQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgID
ARIDEwAjCgkKAgMCEgMUADYKCQoCAwMSAxUAMgoJCgIDBBIDFgAhCggKAQgSAxgANwoJCgII
JRIDGAA3CggKAQgSAxkAVQoJCgIICxIDGQBVCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgS
AxsANwoJCgIICBIDGwA3CggKAQgSAxwANwoJCgIIARIDHAA3CggKAQgSAx0AIAoJCgIIJBID
HQAgCmcKAgQAEgQhAGEBGlsgUmVwcmVzZW50cyBhIG5vdGlmaWNhdGlvbiBzZW50IHRvIFB1
Yi9TdWIgc3Vic2NyaWJlcnMgZm9yIGNvbnZlcnNhdGlvbgogbGlmZWN5Y2xlIGV2ZW50cy4K
CgoKAwQAARIDIQgZCj0KBAQABAASBCMCSwMaLyBFbnVtZXJhdGlvbiBvZiB0aGUgdHlwZXMg
b2YgZXZlbnRzIGF2YWlsYWJsZS4KCgwKBQQABAABEgMjBwsKHgoGBAAEAAIAEgMlBBkaDyBU
eXBlIG5vdCBzZXQuCgoOCgcEAAQAAgABEgMlBBQKDgoHBAAEAAIAAhIDJRcYCpEBCgYEAAQA
AgESAykEHRqBASBBIG5ldyBjb252ZXJzYXRpb24gaGFzIGJlZW4gb3BlbmVkLiBUaGlzIGlz
IGZpcmVkIHdoZW4gYSB0ZWxlcGhvbmUgY2FsbAogaXMgYW5zd2VyZWQsIG9yIGEgY29udmVy
c2F0aW9uIGlzIGNyZWF0ZWQgdmlhIHRoZSBBUEkuCgoOCgcEAAQAAgEBEgMpBBgKDgoHBAAE
AAIBAhIDKRscCvkBCgYEAAQAAgISAy8EHhrpASBBbiBleGlzdGluZyBjb252ZXJzYXRpb24g
aGFzIGNsb3NlZC4gVGhpcyBpcyBmaXJlZCB3aGVuIGEgdGVsZXBob25lIGNhbGwKIGlzIHRl
cm1pbmF0ZWQsIG9yIGEgY29udmVyc2F0aW9uIGlzIGNsb3NlZCB2aWEgdGhlIEFQSS4KIFRo
ZSBldmVudCBpcyBmaXJlZCBmb3IgZXZlcnkgQ29tcGxldGVDb252ZXJzYXRpb24gY2FsbCwg
ZXZlbiBpZiB0aGUKIGNvbnZlcnNhdGlvbiBpcyBhbHJlYWR5IGNsb3NlZC4KCg4KBwQABAAC
AgESAy8EGQoOCgcEAAQAAgICEgMvHB0KeQoGBAAEAAIDEgMzBCIaaiBBbiBleGlzdGluZyBj
b252ZXJzYXRpb24gaGFzIHJlY2VpdmVkIG5vdGlmaWNhdGlvbiBmcm9tIERpYWxvZ2Zsb3cg
dGhhdAogaHVtYW4gaW50ZXJ2ZW50aW9uIGlzIHJlcXVpcmVkLgoKDgoHBAAEAAIDARIDMwQd
Cg4KBwQABAACAwISAzMgIQqMAgoGBAAEAAIEEgM4BBQa/AEgQW4gZXhpc3RpbmcgY29udmVy
c2F0aW9uIGhhcyByZWNlaXZlZCBhIG5ldyBtZXNzYWdlLCBlaXRoZXIgZnJvbSBBUEkgb3IK
IHRlbGVwaG9ueS4gSXQgaXMgY29uZmlndXJlZCBpbgogW0NvbnZlcnNhdGlvblByb2ZpbGUu
bmV3X21lc3NhZ2VfZXZlbnRfbm90aWZpY2F0aW9uX2NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRp
YWxvZ2Zsb3cudjIuQ29udmVyc2F0aW9uUHJvZmlsZS5uZXdfbWVzc2FnZV9ldmVudF9ub3Rp
ZmljYXRpb25fY29uZmlnXQoKDgoHBAAEAAIEARIDOAQPCg4KBwQABAACBAISAzgSEwr4AQoG
BAAEAAIFEgM+BB8a6AEgQW4gZXhpc3RpbmcgY29udmVyc2F0aW9uIGhhcyByZWNlaXZlZCBh
IG5ldyBzcGVlY2ggcmVjb2duaXRpb24gcmVzdWx0LgogVGhpcyBpcyBtYWlubHkgZm9yIGRl
bGl2ZXJpbmcgaW50ZXJtZWRpYXRlIHRyYW5zY3JpcHRzLiBUaGUgbm90aWZpY2F0aW9uCiBp
cyBjb25maWd1cmVkIGluCiBbQ29udmVyc2F0aW9uUHJvZmlsZS5uZXdfcmVjb2duaXRpb25f
ZXZlbnRfbm90aWZpY2F0aW9uX2NvbmZpZ11bXS4KCg4KBwQABAACBQESAz4EGgoOCgcEAAQA
AgUCEgM+HR4KhgMKBgQABAACBhIDSgQcGvYCIFVucmVjb3ZlcmFibGUgZXJyb3IgZHVyaW5n
IGEgdGVsZXBob25lIGNhbGwuCgogSW4gZ2VuZXJhbCBub24tcmVjb3ZlcmFibGUgZXJyb3Jz
IG9ubHkgb2NjdXIgaWYgc29tZXRoaW5nIHdhcwogbWlzY29uZmlndXJlZCBpbiB0aGUgQ29u
dmVyc2F0aW9uUHJvZmlsZSBjb3JyZXNwb25kaW5nIHRvIHRoZSBjYWxsLiBBZnRlcgogYSBu
b24tcmVjb3ZlcmFibGUgZXJyb3IsIERpYWxvZ2Zsb3cgbWF5IHN0b3AgcmVzcG9uZGluZy4K
CiBXZSBkb24ndCBmaXJlIHRoaXMgZXZlbnQ6CgogKiBpbiBhbiBBUEkgY2FsbCBiZWNhdXNl
IHdlIGNhbiBkaXJlY3RseSByZXR1cm4gdGhlIGVycm9yLCBvciwKICogd2hlbiB3ZSBjYW4g
cmVjb3ZlciBmcm9tIGFuIGVycm9yLgoKDgoHBAAEAAIGARIDSgQXCg4KBwQABAACBgISA0oa
GwqZAQoEBAACABIDUAIaGosBIFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGUgY29udmVy
c2F0aW9uIHRoaXMgbm90aWZpY2F0aW9uCiByZWZlcnMgdG8uCiBGb3JtYXQ6IGBwcm9qZWN0
cy88UHJvamVjdCBJRD4vY29udmVyc2F0aW9ucy88Q29udmVyc2F0aW9uIElEPmAuCgoMCgUE
AAIABRIDUAIICgwKBQQAAgABEgNQCRUKDAoFBAACAAMSA1AYGQpGCgQEAAIBEgNTAhAaOSBU
aGUgdHlwZSBvZiB0aGUgZXZlbnQgdGhhdCB0aGlzIG5vdGlmaWNhdGlvbiByZWZlcnMgdG8u
CgoMCgUEAAIBBhIDUwIGCgwKBQQAAgEBEgNTBwsKDAoFBAACAQMSA1MODwpuCgQEAAICEgNX
AiUaYSBNb3JlIGRldGFpbGVkIGluZm9ybWF0aW9uIGFib3V0IGFuIGVycm9yLiBPbmx5IHNl
dCBmb3IgdHlwZQogVU5SRUNPVkVSQUJMRV9FUlJPUl9JTl9QSE9ORV9DQUxMLgoKDAoFBAAC
AgYSA1cCEwoMCgUEAAICARIDVxQgCgwKBQQAAgIDEgNXIyQKLgoEBAAIABIEWgJgAxogIFBh
eWxvYWQgb2YgY29udmVyc2F0aW9uIGV2ZW50LgoKDAoFBAAIAAESA1oIDwosCgQEAAIDEgNc
BCQaHyBQYXlsb2FkIG9mIE5FV19NRVNTQUdFIGV2ZW50LgoKDAoFBAACAwYSA1wECwoMCgUE
AAIDARIDXAwfCgwKBQQAAgMDEgNcIiMKNwoEBAACBBIDXwRCGiogUGF5bG9hZCBvZiBORVdf
UkVDT0dOSVRJT05fUkVTVUxUIGV2ZW50LgoKDAoFBAACBAYSA18EHgoMCgUEAAIEARIDXx89
CgwKBQQAAgQDEgNfQEFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::ConversationEvent::ConversationEvent ===
    # Fields for ConversationEvent
    # Field: conversation Type: 9 ()
    # Field: type Type: 14 (.google.cloud.dialogflow.v2.ConversationEvent.Type)
    # Field: error_status Type: 11 (.google.rpc.Status)
    # Field: new_message_payload Type: 11 (.google.cloud.dialogflow.v2.Message)
    # Field: new_recognition_result_payload Type: 11 (.google.cloud.dialogflow.v2.StreamingRecognitionResult)

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

Google::Cloud::Dialogflow::V2::ConversationEvent - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/conversation_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::ConversationEvent;

    my $msg = Google::Cloud::Dialogflow::V2::ConversationEvent::ConversationEvent->new({
        conversation => $conversation,
        type => $type,
        error_status => $error_status,
        new_message_payload => $new_message_payload,
    });

    # Read or update a field
    my $val = $msg->conversation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::ConversationEvent::ConversationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/conversation_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::ConversationEvent::ConversationEvent

Represents a notification sent to Pub/Sub subscribers for conversation
lifecycle events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->conversation() >> / C<< $msg->conversation($value) >>

Type: C<String>

The unique identifier of the conversation this notification
refers to.
Format: `projects/<Project ID>/conversations/<Conversation ID>`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::ConversationEvent::Type>)

The type of the event that this notification refers to.

=item * C<< $msg->error_status() >> / C<< $msg->error_status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

More detailed information about an error. Only set for type
UNRECOVERABLE_ERROR_IN_PHONE_CALL.

=item * C<< $msg->new_message_payload() >> / C<< $msg->new_message_payload($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::Message>)

Payload of NEW_MESSAGE event.

=item * C<< $msg->new_recognition_result_payload() >> / C<< $msg->new_recognition_result_payload($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Session::StreamingRecognitionResult>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::ConversationEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
