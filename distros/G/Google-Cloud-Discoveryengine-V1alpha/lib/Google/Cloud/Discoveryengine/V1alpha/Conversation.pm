package Google::Cloud::Discoveryengine::V1alpha::Conversation;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::SearchService };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29udmVyc2F0aW9uLnBy
b3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOWdvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9zZWFyY2hfc2VydmljZS5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKpBgoMQ29udmVyc2F0aW9uEhcKBG5h
bWUYASABKAlCA+BBBVIEbmFtZRJOCgVzdGF0ZRgCIAEoDjI4Lmdvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5Db252ZXJzYXRpb24uU3RhdGVSBXN0YXRlEiQKDnVzZXJf
cHNldWRvX2lkGAMgASgJUgx1c2VyUHNldWRvSWQSVQoIbWVzc2FnZXMYBCADKAsyOS5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29udmVyc2F0aW9uTWVzc2FnZVII
bWVzc2FnZXMSPgoKc3RhcnRfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBCA+BBA1IJc3RhcnRUaW1lEjoKCGVuZF90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgdlbmRUaW1lIj4KBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVE
EAASDwoLSU5fUFJPR1JFU1MQARINCglDT01QTEVURUQQAjr2AupB8gIKK2Rpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9Db252ZXJzYXRpb24SXHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jb252ZXJzYXRp
b25zL3tjb252ZXJzYXRpb259EnVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9
L2NvbnZlcnNhdGlvbnMve2NvbnZlcnNhdGlvbn0SbnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5n
aW5lfS9jb252ZXJzYXRpb25zL3tjb252ZXJzYXRpb259IsACCgVSZXBseRIYCgVyZXBseRgB
IAEoCUICGAFSBXJlcGx5ElkKCnJlZmVyZW5jZXMYAiADKAsyNS5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuUmVwbHkuUmVmZXJlbmNlQgIYAVIKcmVmZXJlbmNlcxJW
CgdzdW1tYXJ5GAMgASgLMjwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNlYXJjaFJlc3BvbnNlLlN1bW1hcnlSB3N1bW1hcnkaagoJUmVmZXJlbmNlEhAKA3VyaRgB
IAEoCVIDdXJpEh8KC2FuY2hvcl90ZXh0GAIgASgJUgphbmNob3JUZXh0EhQKBXN0YXJ0GAMg
ASgFUgVzdGFydBIQCgNlbmQYBCABKAVSA2VuZDoCGAEiawoTQ29udmVyc2F0aW9uQ29udGV4
dBIrChFjb250ZXh0X2RvY3VtZW50cxgBIAMoCVIQY29udGV4dERvY3VtZW50cxInCg9hY3Rp
dmVfZG9jdW1lbnQYAiABKAlSDmFjdGl2ZURvY3VtZW50InYKCVRleHRJbnB1dBIUCgVpbnB1
dBgBIAEoCVIFaW5wdXQSUwoHY29udGV4dBgCIAEoCzI5Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5Db252ZXJzYXRpb25Db250ZXh0Ugdjb250ZXh0IvkBChNDb252
ZXJzYXRpb25NZXNzYWdlElAKCnVzZXJfaW5wdXQYASABKAsyLy5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuVGV4dElucHV0SABSCXVzZXJJbnB1dBJDCgVyZXBseRgC
IAEoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5SZXBseUgAUgVy
ZXBseRJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKY3JlYXRlVGltZUIJCgdtZXNzYWdlQp0CCihjb20uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhQhFDb252ZXJzYXRpb25Qcm90b1ABWlJjbG91ZC5nb29nbGUu
Y29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rp
c2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3VkLkRpc2Nv
dmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMWFs
cGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSrUeCgcSBQ4A
jAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFABDCgkKAgMDEgMVACkKCAoBCBIDFwBBCgkKAggl
EgMXAEEKCAoBCBIDGABpCgkKAggLEgMYAGkKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBID
GgAyCgkKAggIEgMaADIKCAoBCBIDGwBBCgkKAggBEgMbAEEKCAoBCBIDHAAtCgkKAggkEgMc
AC0KCAoBCBIDHQBBCgkKAggpEgMdAEEKCAoBCBIDHgBACgkKAggtEgMeAEAKNQoCBAASBCEA
SwEaKSBFeHRlcm5hbCBjb252ZXJzYXRpb24gcHJvdG8gZGVmaW5pdGlvbi4KCgoKAwQAARID
IQgUCgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBAo9CgQEAAQAEgQqAjMDGi8gRW51bWVy
YXRpb24gb2YgdGhlIHN0YXRlIG9mIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAQAARIDKgcM
ChkKBgQABAACABIDLAQaGgogVW5rbm93bi4KCg4KBwQABAACAAESAywEFQoOCgcEAAQAAgAC
EgMsGBkKMAoGBAAEAAIBEgMvBBQaISBDb252ZXJzYXRpb24gaXMgY3VycmVudGx5IG9wZW4u
CgoOCgcEAAQAAgEBEgMvBA8KDgoHBAAEAAIBAhIDLxITCjEKBgQABAACAhIDMgQSGiIgQ29u
dmVyc2F0aW9uIGhhcyBiZWVuIGNvbXBsZXRlZC4KCg4KBwQABAACAgESAzIEDQoOCgcEAAQA
AgICEgMyEBEK6gEKBAQAAgASAzkCPBrcASBJbW11dGFibGUuIEZ1bGx5IHF1YWxpZmllZCBu
YW1lCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMv
e2NvbGxlY3Rpb259L2RhdGFTdG9yZS8qL2NvbnZlcnNhdGlvbnMvKmAKIG9yCiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259
L2VuZ2luZXMvKi9jb252ZXJzYXRpb25zLypgLgoKDAoFBAACAAUSAzkCCAoMCgUEAAIAARID
OQkNCgwKBQQAAgADEgM5EBEKDAoFBAACAAgSAzkSOwoPCggEAAIACJwIABIDORM6Ci0KBAQA
AgESAzwCEhogIFRoZSBzdGF0ZSBvZiB0aGUgQ29udmVyc2F0aW9uLgoKDAoFBAACAQYSAzwC
BwoMCgUEAAIBARIDPAgNCgwKBQQAAgEDEgM8EBEKNgoEBAACAhIDPwIcGikgQSB1bmlxdWUg
aWRlbnRpZmllciBmb3IgdHJhY2tpbmcgdXNlcnMuCgoMCgUEAAICBRIDPwIICgwKBQQAAgIB
EgM/CRcKDAoFBAACAgMSAz8aGwolCgQEAAIDEgNCAiwaGCBDb252ZXJzYXRpb24gbWVzc2Fn
ZXMuCgoMCgUEAAIDBBIDQgIKCgwKBQQAAgMGEgNCCx4KDAoFBAACAwESA0IfJwoMCgUEAAID
AxIDQiorCj8KBAQAAgQSBEUCRjIaMSBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbnZl
cnNhdGlvbiBzdGFydGVkLgoKDAoFBAACBAYSA0UCGwoMCgUEAAIEARIDRRwmCgwKBQQAAgQD
EgNFKSoKDAoFBAACBAgSA0YGMQoPCggEAAIECJwIABIDRgcwCkAKBAQAAgUSBEkCSjIaMiBP
dXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbnZlcnNhdGlvbiBmaW5pc2hlZC4KCgwKBQQA
AgUGEgNJAhsKDAoFBAACBQESA0kcJAoMCgUEAAIFAxIDSScoCgwKBQQAAgUIEgNKBjEKDwoI
BAACBQicCAASA0oHMAouCgIEARIETgBpARoiIERlZmluZXMgYSByZXBseSBtZXNzYWdlIHRv
IHVzZXIuCgoKCgMEAQESA04IDQorCgQEAQMAEgRQAl4DGh0gRGVmaW5lcyByZWZlcmVuY2Ug
aW4gcmVwbHkuCgoMCgUEAQMAARIDUAoTCgwKBQQBAwAHEgNRBB0KDQoGBAEDAAcDEgNRBB0K
JAoGBAEDAAIAEgNUBBMaFSBVUkkgbGluayByZWZlcmVuY2UuCgoOCgcEAQMAAgAFEgNUBAoK
DgoHBAEDAAIAARIDVAsOCg4KBwQBAwACAAMSA1QREgodCgYEAQMAAgESA1cEGxoOIEFuY2hv
ciB0ZXh0LgoKDgoHBAEDAAIBBRIDVwQKCg4KBwQBAwACAQESA1cLFgoOCgcEAQMAAgEDEgNX
GRoKKQoGBAEDAAICEgNaBBQaGiBBbmNob3IgdGV4dCBzdGFydCBpbmRleC4KCg4KBwQBAwAC
AgUSA1oECQoOCgcEAQMAAgIBEgNaCg8KDgoHBAEDAAICAxIDWhITCicKBgQBAwACAxIDXQQS
GhggQW5jaG9yIHRleHQgZW5kIGluZGV4LgoKDgoHBAEDAAIDBRIDXQQJCg4KBwQBAwACAwES
A10KDQoOCgcEAQMAAgMDEgNdEBEKPgoEBAECABIDYgInGjEgREVQUkVDQVRFRDogdXNlIGBz
dW1tYXJ5YCBpbnN0ZWFkLgogVGV4dCByZXBseS4KCgwKBQQBAgAFEgNiAggKDAoFBAECAAES
A2IJDgoMCgUEAQIAAxIDYhESCgwKBQQBAgAIEgNiEyYKDQoGBAECAAgDEgNiFCUKJwoEBAEC
ARIDZQI4GhogUmVmZXJlbmNlcyBpbiB0aGUgcmVwbHkuCgoMCgUEAQIBBBIDZQIKCgwKBQQB
AgEGEgNlCxQKDAoFBAECAQESA2UVHwoMCgUEAQIBAxIDZSIjCgwKBQQBAgEIEgNlJDcKDQoG
BAECAQgDEgNlJTYKLwoEBAECAhIDaAIlGiIgU3VtbWFyeSBiYXNlZCBvbiBzZWFyY2ggcmVz
dWx0cy4KCgwKBQQBAgIGEgNoAhgKDAoFBAECAgESA2gZIAoMCgUEAQICAxIDaCMkCjEKAgQC
EgRsAHQBGiUgRGVmaW5lcyBjb250ZXh0IG9mIHRoZSBjb252ZXJzYXRpb24KCgoKAwQCARID
bAgbCm8KBAQCAgASA28CKBpiIFRoZSBjdXJyZW50IGxpc3Qgb2YgZG9jdW1lbnRzIHRoZSB1
c2VyIGlzIHNlZWluZy4KIEl0IGNvbnRhaW5zIHRoZSBkb2N1bWVudCByZXNvdXJjZSByZWZl
cmVuY2VzLgoKDAoFBAICAAQSA28CCgoMCgUEAgIABRIDbwsRCgwKBQQCAgABEgNvEiMKDAoF
BAICAAMSA28mJwppCgQEAgIBEgNzAh0aXCBUaGUgY3VycmVudCBhY3RpdmUgZG9jdW1lbnQg
dGhlIHVzZXIgb3BlbmVkLgogSXQgY29udGFpbnMgdGhlIGRvY3VtZW50IHJlc291cmNlIHJl
ZmVyZW5jZS4KCgwKBQQCAgEFEgNzAggKDAoFBAICAQESA3MJGAoMCgUEAgIBAxIDcxscCiEK
AgQDEgR3AH0BGhUgRGVmaW5lcyB0ZXh0IGlucHV0LgoKCgoDBAMBEgN3CBEKGgoEBAMCABID
eQITGg0gVGV4dCBpbnB1dC4KCgwKBQQDAgAFEgN5AggKDAoFBAMCAAESA3kJDgoMCgUEAwIA
AxIDeRESCjEKBAQDAgESA3wCIhokIENvbnZlcnNhdGlvbiBjb250ZXh0IG9mIHRoZSBpbnB1
dC4KCgwKBQQDAgEGEgN8AhUKDAoFBAMCAQESA3wWHQoMCgUEAwIBAxIDfCAhCi8KAgQEEgaA
AQCMAQEaISBEZWZpbmVzIGEgY29udmVyc2F0aW9uIG1lc3NhZ2UuCgoLCgMEBAESBIABCBsK
DgoEBAQIABIGgQEChwEDCg0KBQQECAABEgSBAQgPCiAKBAQEAgASBIMBBB0aEiBVc2VyIHRl
eHQgaW5wdXQuCgoNCgUEBAIABhIEgwEEDQoNCgUEBAIAARIEgwEOGAoNCgUEBAIAAxIEgwEb
HAodCgQEBAIBEgSGAQQUGg8gU2VhcmNoIHJlcGx5LgoKDQoFBAQCAQYSBIYBBAkKDQoFBAQC
AQESBIYBCg8KDQoFBAQCAQMSBIYBEhMKOgoEBAQCAhIGigECiwEyGiogT3V0cHV0IG9ubHku
IE1lc3NhZ2UgY3JlYXRpb24gdGltZXN0YW1wLgoKDQoFBAQCAgYSBIoBAhsKDQoFBAQCAgES
BIoBHCcKDQoFBAQCAgMSBIoBKisKDQoFBAQCAggSBIsBBjEKEAoIBAQCAgicCAASBIsBBzBi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1alpha.Conversation.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.discoveryengine.v1alpha.ConversationMessage)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Conversation::State
our $Conversation_STATE_UNSPECIFIED = 0;
our $Conversation_IN_PROGRESS = 1;
our $Conversation_COMPLETED = 2;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Conversation::Reply ===
    # Fields for Reply
    # Field: reply Type: 9 ()
    # Field: references Type: 11 (.google.cloud.discoveryengine.v1alpha.Reply.Reference)
    # Field: summary Type: 11 (.google.cloud.discoveryengine.v1alpha.SearchResponse.Summary)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationContext ===
    # Fields for ConversationContext
    # Field: context_documents Type: 9 ()
    # Field: active_document Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Conversation::TextInput ===
    # Fields for TextInput
    # Field: input Type: 9 ()
    # Field: context Type: 11 (.google.cloud.discoveryengine.v1alpha.ConversationContext)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationMessage ===
    # Fields for ConversationMessage
    # Field: user_input Type: 11 (.google.cloud.discoveryengine.v1alpha.TextInput)
    # Field: reply Type: 11 (.google.cloud.discoveryengine.v1alpha.Reply)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Conversation - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Conversation;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Conversation::Conversation->new({
        name => $name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
        messages => $messages,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Conversation::Conversation

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::State>)

The state of the Conversation.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationMessage>)

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

=head2 Google::Cloud::Discoveryengine::V1alpha::Conversation::Reply

Defines a reply message to user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reply() >> / C<< $msg->reply($value) >>

Type: C<String>

DEPRECATED: use `summary` instead.
Text reply.

=item * C<< $msg->references() >> / C<< $msg->references($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::Reply::Reference>)

References in the reply.

=item * C<< $msg->summary() >> / C<< $msg->summary($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary>)

Summary based on search results.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationContext

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

=head2 Google::Cloud::Discoveryengine::V1alpha::Conversation::TextInput

Defines text input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<String>

Text input.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationContext>)

Conversation context of the input.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Conversation::ConversationMessage

Defines a conversation message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_input() >> / C<< $msg->user_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::TextInput>)

User text input.

=item * C<< $msg->reply() >> / C<< $msg->reply($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Conversation::Reply>)

Search reply.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Message creation timestamp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
