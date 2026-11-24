package Google::Cloud::Discoveryengine::V1beta::Conversation;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::SearchService };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jb252ZXJzYXRpb24ucHJv
dG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjhnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9zZWFyY2hfc2VydmljZS5wcm90bxofZ29v
Z2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKnBgoMQ29udmVyc2F0aW9uEhcKBG5hbWUY
ASABKAlCA+BBBVIEbmFtZRJNCgVzdGF0ZRgCIAEoDjI3Lmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhLkNvbnZlcnNhdGlvbi5TdGF0ZVIFc3RhdGUSJAoOdXNlcl9wc2V1
ZG9faWQYAyABKAlSDHVzZXJQc2V1ZG9JZBJUCghtZXNzYWdlcxgEIAMoCzI4Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNvbnZlcnNhdGlvbk1lc3NhZ2VSCG1lc3Nh
Z2VzEj4KCnN0YXJ0X3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCXN0YXJ0VGltZRI6CghlbmRfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IHZW5kVGltZSI+CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEg8K
C0lOX1BST0dSRVNTEAESDQoJQ09NUExFVEVEEAI69gLqQfICCitkaXNjb3ZlcnllbmdpbmUu
Z29vZ2xlYXBpcy5jb20vQ29udmVyc2F0aW9uElxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vY29udmVyc2F0aW9ucy97
Y29udmVyc2F0aW9ufRJ1cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jb252
ZXJzYXRpb25zL3tjb252ZXJzYXRpb259Em5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMve2VuZ2luZX0v
Y29udmVyc2F0aW9ucy97Y29udmVyc2F0aW9ufSK+AgoFUmVwbHkSGAoFcmVwbHkYASABKAlC
AhgBUgVyZXBseRJYCgpyZWZlcmVuY2VzGAIgAygLMjQuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWJldGEuUmVwbHkuUmVmZXJlbmNlQgIYAVIKcmVmZXJlbmNlcxJVCgdzdW1t
YXJ5GAMgASgLMjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuU2VhcmNo
UmVzcG9uc2UuU3VtbWFyeVIHc3VtbWFyeRpqCglSZWZlcmVuY2USEAoDdXJpGAEgASgJUgN1
cmkSHwoLYW5jaG9yX3RleHQYAiABKAlSCmFuY2hvclRleHQSFAoFc3RhcnQYAyABKAVSBXN0
YXJ0EhAKA2VuZBgEIAEoBVIDZW5kOgIYASJrChNDb252ZXJzYXRpb25Db250ZXh0EisKEWNv
bnRleHRfZG9jdW1lbnRzGAEgAygJUhBjb250ZXh0RG9jdW1lbnRzEicKD2FjdGl2ZV9kb2N1
bWVudBgCIAEoCVIOYWN0aXZlRG9jdW1lbnQidQoJVGV4dElucHV0EhQKBWlucHV0GAEgASgJ
UgVpbnB1dBJSCgdjb250ZXh0GAIgASgLMjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuQ29udmVyc2F0aW9uQ29udGV4dFIHY29udGV4dCL3AQoTQ29udmVyc2F0aW9u
TWVzc2FnZRJPCgp1c2VyX2lucHV0GAEgASgLMi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuVGV4dElucHV0SABSCXVzZXJJbnB1dBJCCgVyZXBseRgCIAEoCzIqLmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlJlcGx5SABSBXJlcGx5EkAKC2Ny
ZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lQgkKB21lc3NhZ2VCmAIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YUIRQ29udmVyc2F0aW9uUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNj
b3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2lu
ZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5W
MUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6
Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSrUeCgcSBQ4AjAEBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFABCCgkKAgMDEgMVACkKCAoBCBIDFwBACgkKAgglEgMXAEAKCAoBCBIDGABo
CgkKAggLEgMYAGgKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAyCgkKAggIEgMaADIK
CAoBCBIDGwBACgkKAggBEgMbAEAKCAoBCBIDHAAtCgkKAggkEgMcAC0KCAoBCBIDHQBACgkK
AggpEgMdAEAKCAoBCBIDHgA/CgkKAggtEgMeAD8KNQoCBAASBCEASwEaKSBFeHRlcm5hbCBj
b252ZXJzYXRpb24gcHJvdG8gZGVmaW5pdGlvbi4KCgoKAwQAARIDIQgUCgsKAwQABxIEIgIn
BAoNCgUEAAedCBIEIgInBAo9CgQEAAQAEgQqAjMDGi8gRW51bWVyYXRpb24gb2YgdGhlIHN0
YXRlIG9mIHRoZSBjb252ZXJzYXRpb24uCgoMCgUEAAQAARIDKgcMChkKBgQABAACABIDLAQa
GgogVW5rbm93bi4KCg4KBwQABAACAAESAywEFQoOCgcEAAQAAgACEgMsGBkKMAoGBAAEAAIB
EgMvBBQaISBDb252ZXJzYXRpb24gaXMgY3VycmVudGx5IG9wZW4uCgoOCgcEAAQAAgEBEgMv
BA8KDgoHBAAEAAIBAhIDLxITCjEKBgQABAACAhIDMgQSGiIgQ29udmVyc2F0aW9uIGhhcyBi
ZWVuIGNvbXBsZXRlZC4KCg4KBwQABAACAgESAzIEDQoOCgcEAAQAAgICEgMyEBEK6gEKBAQA
AgASAzkCPBrcASBJbW11dGFibGUuIEZ1bGx5IHF1YWxpZmllZCBuYW1lCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2Rh
dGFTdG9yZS8qL2NvbnZlcnNhdGlvbnMvKmAKIG9yCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy9nbG9iYWwvY29sbGVjdGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMvKi9jb252
ZXJzYXRpb25zLypgLgoKDAoFBAACAAUSAzkCCAoMCgUEAAIAARIDOQkNCgwKBQQAAgADEgM5
EBEKDAoFBAACAAgSAzkSOwoPCggEAAIACJwIABIDORM6Ci0KBAQAAgESAzwCEhogIFRoZSBz
dGF0ZSBvZiB0aGUgQ29udmVyc2F0aW9uLgoKDAoFBAACAQYSAzwCBwoMCgUEAAIBARIDPAgN
CgwKBQQAAgEDEgM8EBEKNgoEBAACAhIDPwIcGikgQSB1bmlxdWUgaWRlbnRpZmllciBmb3Ig
dHJhY2tpbmcgdXNlcnMuCgoMCgUEAAICBRIDPwIICgwKBQQAAgIBEgM/CRcKDAoFBAACAgMS
Az8aGwolCgQEAAIDEgNCAiwaGCBDb252ZXJzYXRpb24gbWVzc2FnZXMuCgoMCgUEAAIDBBID
QgIKCgwKBQQAAgMGEgNCCx4KDAoFBAACAwESA0IfJwoMCgUEAAIDAxIDQiorCj8KBAQAAgQS
BEUCRjIaMSBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIGNvbnZlcnNhdGlvbiBzdGFydGVk
LgoKDAoFBAACBAYSA0UCGwoMCgUEAAIEARIDRRwmCgwKBQQAAgQDEgNFKSoKDAoFBAACBAgS
A0YGMQoPCggEAAIECJwIABIDRgcwCkAKBAQAAgUSBEkCSjIaMiBPdXRwdXQgb25seS4gVGhl
IHRpbWUgdGhlIGNvbnZlcnNhdGlvbiBmaW5pc2hlZC4KCgwKBQQAAgUGEgNJAhsKDAoFBAAC
BQESA0kcJAoMCgUEAAIFAxIDSScoCgwKBQQAAgUIEgNKBjEKDwoIBAACBQicCAASA0oHMAou
CgIEARIETgBpARoiIERlZmluZXMgYSByZXBseSBtZXNzYWdlIHRvIHVzZXIuCgoKCgMEAQES
A04IDQorCgQEAQMAEgRQAl4DGh0gRGVmaW5lcyByZWZlcmVuY2UgaW4gcmVwbHkuCgoMCgUE
AQMAARIDUAoTCgwKBQQBAwAHEgNRBB0KDQoGBAEDAAcDEgNRBB0KJAoGBAEDAAIAEgNUBBMa
FSBVUkkgbGluayByZWZlcmVuY2UuCgoOCgcEAQMAAgAFEgNUBAoKDgoHBAEDAAIAARIDVAsO
Cg4KBwQBAwACAAMSA1QREgodCgYEAQMAAgESA1cEGxoOIEFuY2hvciB0ZXh0LgoKDgoHBAED
AAIBBRIDVwQKCg4KBwQBAwACAQESA1cLFgoOCgcEAQMAAgEDEgNXGRoKKQoGBAEDAAICEgNa
BBQaGiBBbmNob3IgdGV4dCBzdGFydCBpbmRleC4KCg4KBwQBAwACAgUSA1oECQoOCgcEAQMA
AgIBEgNaCg8KDgoHBAEDAAICAxIDWhITCicKBgQBAwACAxIDXQQSGhggQW5jaG9yIHRleHQg
ZW5kIGluZGV4LgoKDgoHBAEDAAIDBRIDXQQJCg4KBwQBAwACAwESA10KDQoOCgcEAQMAAgMD
EgNdEBEKPgoEBAECABIDYgInGjEgREVQUkVDQVRFRDogdXNlIGBzdW1tYXJ5YCBpbnN0ZWFk
LgogVGV4dCByZXBseS4KCgwKBQQBAgAFEgNiAggKDAoFBAECAAESA2IJDgoMCgUEAQIAAxID
YhESCgwKBQQBAgAIEgNiEyYKDQoGBAECAAgDEgNiFCUKJwoEBAECARIDZQI4GhogUmVmZXJl
bmNlcyBpbiB0aGUgcmVwbHkuCgoMCgUEAQIBBBIDZQIKCgwKBQQBAgEGEgNlCxQKDAoFBAEC
AQESA2UVHwoMCgUEAQIBAxIDZSIjCgwKBQQBAgEIEgNlJDcKDQoGBAECAQgDEgNlJTYKLwoE
BAECAhIDaAIlGiIgU3VtbWFyeSBiYXNlZCBvbiBzZWFyY2ggcmVzdWx0cy4KCgwKBQQBAgIG
EgNoAhgKDAoFBAECAgESA2gZIAoMCgUEAQICAxIDaCMkCjEKAgQCEgRsAHQBGiUgRGVmaW5l
cyBjb250ZXh0IG9mIHRoZSBjb252ZXJzYXRpb24KCgoKAwQCARIDbAgbCm8KBAQCAgASA28C
KBpiIFRoZSBjdXJyZW50IGxpc3Qgb2YgZG9jdW1lbnRzIHRoZSB1c2VyIGlzIHNlZWluZy4K
IEl0IGNvbnRhaW5zIHRoZSBkb2N1bWVudCByZXNvdXJjZSByZWZlcmVuY2VzLgoKDAoFBAIC
AAQSA28CCgoMCgUEAgIABRIDbwsRCgwKBQQCAgABEgNvEiMKDAoFBAICAAMSA28mJwppCgQE
AgIBEgNzAh0aXCBUaGUgY3VycmVudCBhY3RpdmUgZG9jdW1lbnQgdGhlIHVzZXIgb3BlbmVk
LgogSXQgY29udGFpbnMgdGhlIGRvY3VtZW50IHJlc291cmNlIHJlZmVyZW5jZS4KCgwKBQQC
AgEFEgNzAggKDAoFBAICAQESA3MJGAoMCgUEAgIBAxIDcxscCiEKAgQDEgR3AH0BGhUgRGVm
aW5lcyB0ZXh0IGlucHV0LgoKCgoDBAMBEgN3CBEKGgoEBAMCABIDeQITGg0gVGV4dCBpbnB1
dC4KCgwKBQQDAgAFEgN5AggKDAoFBAMCAAESA3kJDgoMCgUEAwIAAxIDeRESCjEKBAQDAgES
A3wCIhokIENvbnZlcnNhdGlvbiBjb250ZXh0IG9mIHRoZSBpbnB1dC4KCgwKBQQDAgEGEgN8
AhUKDAoFBAMCAQESA3wWHQoMCgUEAwIBAxIDfCAhCi8KAgQEEgaAAQCMAQEaISBEZWZpbmVz
IGEgY29udmVyc2F0aW9uIG1lc3NhZ2UuCgoLCgMEBAESBIABCBsKDgoEBAQIABIGgQEChwED
Cg0KBQQECAABEgSBAQgPCiAKBAQEAgASBIMBBB0aEiBVc2VyIHRleHQgaW5wdXQuCgoNCgUE
BAIABhIEgwEEDQoNCgUEBAIAARIEgwEOGAoNCgUEBAIAAxIEgwEbHAodCgQEBAIBEgSGAQQU
Gg8gU2VhcmNoIHJlcGx5LgoKDQoFBAQCAQYSBIYBBAkKDQoFBAQCAQESBIYBCg8KDQoFBAQC
AQMSBIYBEhMKOgoEBAQCAhIGigECiwEyGiogT3V0cHV0IG9ubHkuIE1lc3NhZ2UgY3JlYXRp
b24gdGltZXN0YW1wLgoKDQoFBAQCAgYSBIoBAhsKDQoFBAQCAgESBIoBHCcKDQoFBAQCAgMS
BIoBKisKDQoFBAQCAggSBIsBBjEKEAoIBAQCAgicCAASBIsBBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Conversation::Conversation ===
    # Fields for Conversation
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.discoveryengine.v1beta.Conversation.State)
    # Field: user_pseudo_id Type: 9 ()
    # Field: messages Type: 11 (.google.cloud.discoveryengine.v1beta.ConversationMessage)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Conversation::State
our $Conversation_STATE_UNSPECIFIED = 0;
our $Conversation_IN_PROGRESS = 1;
our $Conversation_COMPLETED = 2;

# === Message: Google::Cloud::Discoveryengine::V1beta::Conversation::Reply ===
    # Fields for Reply
    # Field: reply Type: 9 ()
    # Field: references Type: 11 (.google.cloud.discoveryengine.v1beta.Reply.Reference)
    # Field: summary Type: 11 (.google.cloud.discoveryengine.v1beta.SearchResponse.Summary)

# === Message: Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationContext ===
    # Fields for ConversationContext
    # Field: context_documents Type: 9 ()
    # Field: active_document Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Conversation::TextInput ===
    # Fields for TextInput
    # Field: input Type: 9 ()
    # Field: context Type: 11 (.google.cloud.discoveryengine.v1beta.ConversationContext)

# === Message: Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationMessage ===
    # Fields for ConversationMessage
    # Field: user_input Type: 11 (.google.cloud.discoveryengine.v1beta.TextInput)
    # Field: reply Type: 11 (.google.cloud.discoveryengine.v1beta.Reply)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Conversation - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/conversation.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Conversation;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Conversation::Conversation->new({
        name => $name,
        state => $state,
        user_pseudo_id => $user_pseudo_id,
        messages => $messages,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Conversation::Conversation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/conversation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Conversation::Conversation

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

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::State>)

The state of the Conversation.

=item * C<< $msg->user_pseudo_id() >> / C<< $msg->user_pseudo_id($value) >>

Type: C<String>

A unique identifier for tracking users.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationMessage>)

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

=head2 Google::Cloud::Discoveryengine::V1beta::Conversation::Reply

Defines a reply message to user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reply() >> / C<< $msg->reply($value) >>

Type: C<String>

DEPRECATED: use `summary` instead.
Text reply.

=item * C<< $msg->references() >> / C<< $msg->references($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::Reply::Reference>)

References in the reply.

=item * C<< $msg->summary() >> / C<< $msg->summary($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::SearchService::SearchResponse::Summary>)

Summary based on search results.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationContext

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

=head2 Google::Cloud::Discoveryengine::V1beta::Conversation::TextInput

Defines text input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<String>

Text input.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationContext>)

Conversation context of the input.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Conversation::ConversationMessage

Defines a conversation message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_input() >> / C<< $msg->user_input($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::TextInput>)

User text input.

=item * C<< $msg->reply() >> / C<< $msg->reply($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Conversation::Reply>)

Search reply.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Message creation timestamp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Conversation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
