package Google::Cloud::Discoveryengine::V1::Conversation;

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
    eval { require Google::Cloud::Discoveryengine::V1::SearchService };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2NvbnZlcnNhdGlvbi5wcm90bxIf
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0Z29vZ2xlL2Nsb3VkL2Rp
c2NvdmVyeWVuZ2luZS92MS9zZWFyY2hfc2VydmljZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVm
L3RpbWVzdGFtcC5wcm90byKfBgoMQ29udmVyc2F0aW9uEhcKBG5hbWUYASABKAlCA+BBBVIE
bmFtZRJJCgVzdGF0ZRgCIAEoDjIzLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
Q29udmVyc2F0aW9uLlN0YXRlUgVzdGF0ZRIkCg51c2VyX3BzZXVkb19pZBgDIAEoCVIMdXNl
clBzZXVkb0lkElAKCG1lc3NhZ2VzGAQgAygLMjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5Db252ZXJzYXRpb25NZXNzYWdlUghtZXNzYWdlcxI+CgpzdGFydF90aW1lGAUg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFydFRpbWUSOgoIZW5k
X3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUi
PgoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIPCgtJTl9QUk9HUkVTUxABEg0KCUNP
TVBMRVRFRBACOvYC6kHyAgorZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0NvbnZl
cnNhdGlvbhJccHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFT
dG9yZXMve2RhdGFfc3RvcmV9L2NvbnZlcnNhdGlvbnMve2NvbnZlcnNhdGlvbn0SdXByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVj
dGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vY29udmVyc2F0aW9ucy97Y29udmVyc2F0
aW9ufRJucHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rp
b25zL3tjb2xsZWN0aW9ufS9lbmdpbmVzL3tlbmdpbmV9L2NvbnZlcnNhdGlvbnMve2NvbnZl
cnNhdGlvbn0iWgoFUmVwbHkSUQoHc3VtbWFyeRgDIAEoCzI3Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuU2VhcmNoUmVzcG9uc2UuU3VtbWFyeVIHc3VtbWFyeSJrChNDb252
ZXJzYXRpb25Db250ZXh0EisKEWNvbnRleHRfZG9jdW1lbnRzGAEgAygJUhBjb250ZXh0RG9j
dW1lbnRzEicKD2FjdGl2ZV9kb2N1bWVudBgCIAEoCVIOYWN0aXZlRG9jdW1lbnQicQoJVGV4
dElucHV0EhQKBWlucHV0GAEgASgJUgVpbnB1dBJOCgdjb250ZXh0GAIgASgLMjQuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Db252ZXJzYXRpb25Db250ZXh0Ugdjb250ZXh0
Iu8BChNDb252ZXJzYXRpb25NZXNzYWdlEksKCnVzZXJfaW5wdXQYASABKAsyKi5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlRleHRJbnB1dEgAUgl1c2VySW5wdXQSPgoFcmVw
bHkYAiABKAsyJi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlJlcGx5SABSBXJl
cGx5EkAKC2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lQgkKB21lc3NhZ2VChAIKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxQhFDb252ZXJzYXRpb25Qcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dv
L2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3Zlcnllbmdp
bmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUu
VjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6
RGlzY292ZXJ5RW5naW5lOjpWMUrpGAoGEgQOAHQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA+
CgkKAgMDEgMVACkKCAoBCBIDFwA8CgkKAgglEgMXADwKCAoBCBIDGABkCgkKAggLEgMYAGQK
CAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAyCgkKAggIEgMaADIKCAoBCBIDGwA8CgkK
AggBEgMbADwKCAoBCBIDHAAtCgkKAggkEgMcAC0KCAoBCBIDHQA8CgkKAggpEgMdADwKCAoB
CBIDHgA7CgkKAggtEgMeADsKNQoCBAASBCEASwEaKSBFeHRlcm5hbCBjb252ZXJzYXRpb24g
cHJvdG8gZGVmaW5pdGlvbi4KCgoKAwQAARIDIQgUCgsKAwQABxIEIgInBAoNCgUEAAedCBIE
IgInBAo9CgQEAAQAEgQqAjMDGi8gRW51bWVyYXRpb24gb2YgdGhlIHN0YXRlIG9mIHRoZSBj
b252ZXJzYXRpb24uCgoMCgUEAAQAARIDKgcMChkKBgQABAACABIDLAQaGgogVW5rbm93bi4K
Cg4KBwQABAACAAESAywEFQoOCgcEAAQAAgACEgMsGBkKMAoGBAAEAAIBEgMvBBQaISBDb252
ZXJzYXRpb24gaXMgY3VycmVudGx5IG9wZW4uCgoOCgcEAAQAAgEBEgMvBA8KDgoHBAAEAAIB
AhIDLxITCjEKBgQABAACAhIDMgQSGiIgQ29udmVyc2F0aW9uIGhhcyBiZWVuIGNvbXBsZXRl
ZC4KCg4KBwQABAACAgESAzIEDQoOCgcEAAQAAgICEgMyEBEK6gEKBAQAAgASAzkCPBrcASBJ
bW11dGFibGUuIEZ1bGx5IHF1YWxpZmllZCBuYW1lCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZS8qL2Nv
bnZlcnNhdGlvbnMvKmAKIG9yCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9i
YWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMvKi9jb252ZXJzYXRpb25zLypg
LgoKDAoFBAACAAUSAzkCCAoMCgUEAAIAARIDOQkNCgwKBQQAAgADEgM5EBEKDAoFBAACAAgS
AzkSOwoPCggEAAIACJwIABIDORM6Ci0KBAQAAgESAzwCEhogIFRoZSBzdGF0ZSBvZiB0aGUg
Q29udmVyc2F0aW9uLgoKDAoFBAACAQYSAzwCBwoMCgUEAAIBARIDPAgNCgwKBQQAAgEDEgM8
EBEKNgoEBAACAhIDPwIcGikgQSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdHJhY2tpbmcgdXNl
cnMuCgoMCgUEAAICBRIDPwIICgwKBQQAAgIBEgM/CRcKDAoFBAACAgMSAz8aGwolCgQEAAID
EgNCAiwaGCBDb252ZXJzYXRpb24gbWVzc2FnZXMuCgoMCgUEAAIDBBIDQgIKCgwKBQQAAgMG
EgNCCx4KDAoFBAACAwESA0IfJwoMCgUEAAIDAxIDQiorCj8KBAQAAgQSBEUCRjIaMSBPdXRw
dXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbnZlcnNhdGlvbiBzdGFydGVkLgoKDAoFBAACBAYS
A0UCGwoMCgUEAAIEARIDRRwmCgwKBQQAAgQDEgNFKSoKDAoFBAACBAgSA0YGMQoPCggEAAIE
CJwIABIDRgcwCkAKBAQAAgUSBEkCSjIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGNv
bnZlcnNhdGlvbiBmaW5pc2hlZC4KCgwKBQQAAgUGEgNJAhsKDAoFBAACBQESA0kcJAoMCgUE
AAIFAxIDSScoCgwKBQQAAgUIEgNKBjEKDwoIBAACBQicCAASA0oHMAouCgIEARIETgBRARoi
IERlZmluZXMgYSByZXBseSBtZXNzYWdlIHRvIHVzZXIuCgoKCgMEAQESA04IDQovCgQEAQIA
EgNQAiUaIiBTdW1tYXJ5IGJhc2VkIG9uIHNlYXJjaCByZXN1bHRzLgoKDAoFBAECAAYSA1AC
GAoMCgUEAQIAARIDUBkgCgwKBQQBAgADEgNQIyQKMQoCBAISBFQAXAEaJSBEZWZpbmVzIGNv
bnRleHQgb2YgdGhlIGNvbnZlcnNhdGlvbgoKCgoDBAIBEgNUCBsKbwoEBAICABIDVwIoGmIg
VGhlIGN1cnJlbnQgbGlzdCBvZiBkb2N1bWVudHMgdGhlIHVzZXIgaXMgc2VlaW5nLgogSXQg
Y29udGFpbnMgdGhlIGRvY3VtZW50IHJlc291cmNlIHJlZmVyZW5jZXMuCgoMCgUEAgIABBID
VwIKCgwKBQQCAgAFEgNXCxEKDAoFBAICAAESA1cSIwoMCgUEAgIAAxIDVyYnCmkKBAQCAgES
A1sCHRpcIFRoZSBjdXJyZW50IGFjdGl2ZSBkb2N1bWVudCB0aGUgdXNlciBvcGVuZWQuCiBJ
dCBjb250YWlucyB0aGUgZG9jdW1lbnQgcmVzb3VyY2UgcmVmZXJlbmNlLgoKDAoFBAICAQUS
A1sCCAoMCgUEAgIBARIDWwkYCgwKBQQCAgEDEgNbGxwKIQoCBAMSBF8AZQEaFSBEZWZpbmVz
IHRleHQgaW5wdXQuCgoKCgMEAwESA18IEQoaCgQEAwIAEgNhAhMaDSBUZXh0IGlucHV0LgoK
DAoFBAMCAAUSA2ECCAoMCgUEAwIAARIDYQkOCgwKBQQDAgADEgNhERIKMQoEBAMCARIDZAIi
GiQgQ29udmVyc2F0aW9uIGNvbnRleHQgb2YgdGhlIGlucHV0LgoKDAoFBAMCAQYSA2QCFQoM
CgUEAwIBARIDZBYdCgwKBQQDAgEDEgNkICEKLQoCBAQSBGgAdAEaISBEZWZpbmVzIGEgY29u
dmVyc2F0aW9uIG1lc3NhZ2UuCgoKCgMEBAESA2gIGwoMCgQEBAgAEgRpAm8DCgwKBQQECAAB
EgNpCA8KHwoEBAQCABIDawQdGhIgVXNlciB0ZXh0IGlucHV0LgoKDAoFBAQCAAYSA2sEDQoM
CgUEBAIAARIDaw4YCgwKBQQEAgADEgNrGxwKHAoEBAQCARIDbgQUGg8gU2VhcmNoIHJlcGx5
LgoKDAoFBAQCAQYSA24ECQoMCgUEBAIBARIDbgoPCgwKBQQEAgEDEgNuEhMKOAoEBAQCAhIE
cgJzMhoqIE91dHB1dCBvbmx5LiBNZXNzYWdlIGNyZWF0aW9uIHRpbWVzdGFtcC4KCgwKBQQE
AgIGEgNyAhsKDAoFBAQCAgESA3IcJwoMCgUEBAICAxIDciorCgwKBQQEAgIIEgNzBjEKDwoI
BAQCAgicCAASA3MHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1.Conversation.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.discoveryengine.v1.ConversationMessage)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Conversation::State
our $Conversation_STATE_UNSPECIFIED = 0;
our $Conversation_IN_PROGRESS = 1;
our $Conversation_COMPLETED = 2;

# === Message: Google::Cloud::Discoveryengine::V1::Conversation::Reply ===
    # Fields for Reply
    # Field: summary Type: 11 (.google.cloud.discoveryengine.v1.SearchResponse.Summary)

# === Message: Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext ===
    # Fields for ConversationContext
    # Field: context_documents Type: 9 ()
    # Field: active_document Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::Conversation::TextInput ===
    # Fields for TextInput
    # Field: input Type: 9 ()
    # Field: context Type: 11 (.google.cloud.discoveryengine.v1.ConversationContext)

# === Message: Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage ===
    # Fields for ConversationMessage
    # Field: user_input Type: 11 (.google.cloud.discoveryengine.v1.TextInput)
    # Field: reply Type: 11 (.google.cloud.discoveryengine.v1.Reply)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Conversation - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Conversation;

    my $msg = Google::Cloud::Discoveryengine::V1::Conversation::Conversation->new({
        name => $name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
        messages => $messages,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Conversation::Conversation

External conversation proto definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/{project}/locations/global/collections/{collection}/dataStore/*/conversations/*`
or
`projects/{project}/locations/global/collections/{collection}/engines/*/conversations/*`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1::Conversation::State>)

The state of the Conversation.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage>)

Conversation messages.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the conversation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the conversation finished.

=back

=head3 Enum: Conversation::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<COMPLETED> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1::Conversation::Reply

Defines a reply message to user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->summary() >> / C<< $msg->summary($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::SearchService::SearchResponse::Summary>)

Summary based on search results.

=back

=head2 Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext

Defines context of the conversation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context_documents() >> / C<< $msg->context_documents($value) >>

Type: C<String>

The current list of documents the user is seeing.
It contains the document resource references.

=item * C<< $msg->active_document() >> / C<< $msg->active_document($value) >>

Type: C<String>

The current active document the user opened.
It contains the document resource reference.

=back

=head2 Google::Cloud::Discoveryengine::V1::Conversation::TextInput

Defines text input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<String>

Text input.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext>)

Conversation context of the input.

=back

=head2 Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage

Defines a conversation message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_input() >> / C<< $msg->user_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Conversation::TextInput>)

User text input.

=item * C<< $msg->reply() >> / C<< $msg->reply($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Conversation::Reply>)

Search reply.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Message creation timestamp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
