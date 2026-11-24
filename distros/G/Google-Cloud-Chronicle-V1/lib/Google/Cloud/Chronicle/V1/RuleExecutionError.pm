package Google::Cloud::Chronicle::V1::RuleExecutionError;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Rpc::Status };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL3J1bGVfZXhlY3V0aW9uX2Vycm9yLnByb3Rv
Ehlnb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoXZ29vZ2xlL3JwYy9zdGF0dXMu
cHJvdG8aGmdvb2dsZS90eXBlL2ludGVydmFsLnByb3RvIsEBCh5MaXN0UnVsZUV4ZWN1dGlv
bkVycm9yc1JlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0SK2Nocm9uaWNsZS5nb29n
bGVhcGlzLmNvbS9SdWxlRXhlY3V0aW9uRXJyb3JSBnBhcmVudBIbCglwYWdlX3NpemUYAiAB
KAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIY
BCABKAlSBmZpbHRlciKsAQofTGlzdFJ1bGVFeGVjdXRpb25FcnJvcnNSZXNwb25zZRJhChVy
dWxlX2V4ZWN1dGlvbl9lcnJvcnMYASADKAsyLS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYx
LlJ1bGVFeGVjdXRpb25FcnJvclITcnVsZUV4ZWN1dGlvbkVycm9ycxImCg9uZXh0X3BhZ2Vf
dG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4izgMKElJ1bGVFeGVjdXRpb25FcnJvchI7CgRy
dWxlGAQgASgJQiXgQQP6QR8KHWNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9SdWxlSABSBHJ1
bGUSUQoMY3VyYXRlZF9ydWxlGAUgASgJQizgQQP6QSYKJGNocm9uaWNsZS5nb29nbGVhcGlz
LmNvbS9DdXJhdGVkUnVsZUgAUgtjdXJhdGVkUnVsZRIXCgRuYW1lGAEgASgJQgPgQQNSBG5h
bWUSLQoFZXJyb3IYAiABKAsyEi5nb29nbGUucnBjLlN0YXR1c0ID4EEDUgVlcnJvchI5Cgp0
aW1lX3JhbmdlGAMgASgLMhUuZ29vZ2xlLnR5cGUuSW50ZXJ2YWxCA+BBA1IJdGltZVJhbmdl
OpoB6kGWAQorY2hyb25pY2xlLmdvb2dsZWFwaXMuY29tL1J1bGVFeGVjdXRpb25FcnJvchJn
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2V9L3J1bGVFeGVjdXRpb25FcnJvcnMve3J1bGVfZXhlY3V0aW9uX2Vycm9yfUIICgZz
b3VyY2UysQMKGVJ1bGVFeGVjdXRpb25FcnJvclNlcnZpY2US5gEKF0xpc3RSdWxlRXhlY3V0
aW9uRXJyb3JzEjkuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5MaXN0UnVsZUV4ZWN1dGlv
bkVycm9yc1JlcXVlc3QaOi5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkxpc3RSdWxlRXhl
Y3V0aW9uRXJyb3JzUmVzcG9uc2UiVILT5JMCRRJDL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vcnVsZUV4ZWN1dGlvbkVycm9yc9pBBnBhcmVudBqq
AcpBGGNocm9uaWNsZS5nb29nbGVhcGlzLmNvbdJBiwFodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Nocm9uaWNsZSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2No
cm9uaWNsZS5yZWFkb25seSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtQtACCh1jb20uZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MUIXUnVsZUV4ZWN1
dGlvbkVycm9yUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9jaHJvbmljbGUvYXBpdjEv
Y2hyb25pY2xlcGI7Y2hyb25pY2xlcGKqAhlHb29nbGUuQ2xvdWQuQ2hyb25pY2xlLlYxygIZ
R29vZ2xlXENsb3VkXENocm9uaWNsZVxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkNocm9uaWNsZTo6
VjHqQX8KJGNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9DdXJhdGVkUnVsZRJXcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2N1
cmF0ZWRSdWxlcy97Y3VyYXRlZFJ1bGV9SuojCgcSBQ4AmwEBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgID
AhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAIQoJCgIDBRIDFwAkCggKAQgSAxkANgoJCgII
JRIDGQA2CggKAQgSAxoAUgoJCgIICxIDGgBSCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgS
AxwAOAoJCgIICBIDHAA4CggKAQgSAx0ANgoJCgIIARIDHQA2CggKAQgSAx4ANgoJCgIIKRID
HgA2CggKAQgSAx8ANQoJCgIILRIDHwA1CgkKAQgSBCAAIwIKDAoECJ0IABIEIAAjAgpdCgIG
ABIEJwA2ARpRIFJ1bGVFeGVjdXRpb25FcnJvclNlcnZpY2UgY29udGFpbnMgZW5kcG9pbnRz
IHJlbGF0ZWQgdG8gcnVsZSBleGVjdXRpb24KIGVycm9ycy4KCgoKAwYAARIDJwghCgoKAwYA
AxIDKAJACgwKBQYAA5kIEgMoAkAKCwoDBgADEgQpAiw3Cg0KBQYAA5oIEgQpAiw3CiwKBAYA
AgASBC8CNQMaHiBMaXN0cyBydWxlIGV4ZWN1dGlvbiBlcnJvcnMuCgoMCgUGAAIAARIDLwYd
CgwKBQYAAgACEgMvHjwKDAoFBgACAAMSAzAPLgoNCgUGAAIABBIEMQQzBgoRCgkGAAIABLDK
vCISBDEEMwYKDAoFBgACAAQSAzQENAoPCggGAAIABJsIABIDNAQ0CjoKAgQAEgQ5AGYBGi4g
UmVxdWVzdCBtZXNzYWdlIGZvciBMaXN0UnVsZUV4ZWN1dGlvbkVycm9ycy4KCgoKAwQAARID
OQgmCpIBCgQEAAIAEgQ9AkIEGoMBIFJlcXVpcmVkLiBUaGUgaW5zdGFuY2UgdG8gbGlzdCBy
dWxlIGV4ZWN1dGlvbiBlcnJvcnMgZnJvbS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfQoKDAoFBAACAAUS
Az0CCAoMCgUEAAIAARIDPQkPCgwKBQQAAgADEgM9EhMKDQoFBAACAAgSBD0UQgMKDwoIBAAC
AAicCAASAz4EKgoPCgcEAAIACJ8IEgQ/BEEFCoUCCgQEAAIBEgNIAhYa9wEgVGhlIG1heGlt
dW0gbnVtYmVyIG9mIHJ1bGUgZXhlY3V0aW9uIGVycm9ycyB0byByZXR1cm4uIFRoZSBzZXJ2
aWNlIG1heQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQs
IGF0IG1vc3QgMTAwMCBydWxlIGV4ZWN1dGlvbgogZXJyb3JzIHdpbGwgYmUgcmV0dXJuZWQu
IFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDAwOyB2YWx1ZXMgYWJvdmUgMTAwMDAKIHdpbGwg
YmUgY29lcmNlZCB0byAxMDAwMC4KCgwKBQQAAgEFEgNIAgcKDAoFBAACAQESA0gIEQoMCgUE
AAIBAxIDSBQVCoYCCgQEAAICEgNPAhga+AEgQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9t
IGEgcHJldmlvdXMgYExpc3RSdWxlRXhlY3V0aW9uRXJyb3JzYCBjYWxsLgogUHJvdmlkZSB0
aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5n
LCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdFJ1bGVFeGVjdXRpb25F
cnJvcnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9r
ZW4uCgoMCgUEAAICBRIDTwIICgwKBQQAAgIBEgNPCRMKDAoFBAACAgMSA08WFwq2BgoEBAAC
AxIDZQIUGqgGIEEgZmlsdGVyIHRoYXQgY2FuIGJlIHVzZWQgdG8gcmV0cmlldmUgc3BlY2lm
aWMgcnVsZSBleGVjdXRpb24gZXJyb3JzLgogT25seSB0aGUgZm9sbG93aW5nIGZpbHRlcnMg
YXJlIGFsbG93ZWQ6CiBgYGAKICAgcnVsZSA9ICJ7UnVsZS5uYW1lfSIKICAgY3VyYXRlZF9y
dWxlID0gIntDdXJhdGVkUnVsZS5uYW1lfSIKIGBgYAogVGhlIHZhbHVlIGZvciBydWxlIG9y
IGN1cmF0ZWRfcnVsZSBtdXN0IGJlIGEgdmFsaWQgcnVsZSByZXNvdXJjZSBuYW1lIG9yIGEK
IHZhbGlkIGN1cmF0ZWQgcnVsZSByZXNvdXJjZSBuYW1lIHNwZWNpZmllZCBpbiBxdW90ZXMu
CgogRm9yICdydWxlJywgYW4gb3B0aW9uYWwgJ3JldmlzaW9uX2lkJyBjYW4gYmUgc3BlY2lm
aWVkIHdoaWNoIGNhbiBiZSB1c2VkIHRvCiBmZXRjaCBlcnJvcnMgZm9yIGEgZ2l2ZW4gcmV2
aXNpb24gb2YgdGhlIHJ1bGUuIEEgJy0nIGlzIGFsc28gYWxsb3dlZCB0bwogZmV0Y2ggZXJy
b3JzIGFjcm9zcyBhbGwgcmV2aXNpb25zIG9mIHRoZSBydWxlLiBJZiB1bnNwZWNpZmllZCwg
b25seSBlcnJvcnMKIGNvcnJlc3BvbmRpbmcgdG8gdGhlIG1vc3QgcmVjZW50IHJldmlzaW9u
IG9mIHRoZSBydWxlIHdpbGwgYmUgcmV0dXJuZWQuIFNvCiB0aGVzZSB2YXJpYXRpb25zIGFy
ZSBhbGwgYWxsb3dlZDoKIGBgYAogICBydWxlID0gIntSdWxlLm5hbWV9IgogICBydWxlID0g
IntSdWxlLm5hbWV9QHtSdWxlLnJldmlzaW9uX2lkfSIKICAgcnVsZSA9ICJ7UnVsZS5uYW1l
fUAtIgogYGBgCiBSZXZpc2lvbiBJRHMgYXJlIG5vdCBzdXBwb3J0ZWQgZm9yIGN1cmF0ZWQg
cnVsZXMuCgoMCgUEAAIDBRIDZQIICgwKBQQAAgMBEgNlCQ8KDAoFBAACAwMSA2USEwo7CgIE
ARIEaQBwARovIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIExpc3RSdWxlRXhlY3V0aW9uRXJyb3Jz
LgoKCgoDBAEBEgNpCCcKLQoEBAECABIDawI4GiAgTGlzdCBvZiBydWxlIGV4ZWN1dGlvbiBl
cnJvcnMuCgoMCgUEAQIABBIDawIKCgwKBQQBAgAGEgNrCx0KDAoFBAECAAESA2seMwoMCgUE
AQIAAxIDazY3Co8BCgQEAQIBEgNvAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQg
YXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDAoFBAEC
AQUSA28CCAoMCgUEAQIBARIDbwkYCgwKBQQBAgEDEgNvGxwKbAoCBAISBXQAmwEBGl8gVGhl
IFJ1bGVFeGVjdXRpb25FcnJvciByZXNvdXJjZSByZXByZXNlbnRzIGFuIGVycm9yIGdlbmVy
YXRlZCBmcm9tCiBydW5uaW5nL2RlcGxveWluZyBhIHJ1bGUuCgoKCgMEAgESA3QIGgoLCgME
AgcSBHUCeAQKDQoFBAIHnQgSBHUCeAQKWQoEBAIIABIFewKNAQMaSiBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgc291cmNlIHRoYXQgZ2VuZXJhdGVkIHRoZSBydWxlIGV4ZWN1dGlvbiBl
cnJvci4KCgwKBQQCCAABEgN7CA4KZQoEBAICABIFfgSDAQYaViBPdXRwdXQgb25seS4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIHJ1bGUgdGhhdCBnZW5lcmF0ZWQgdGhlIHJ1bGUKIGV4
ZWN1dGlvbiBlcnJvci4KCgwKBQQCAgAFEgN+BAoKDAoFBAICAAESA34LDwoMCgUEAgIAAxID
fhITCg4KBQQCAgAIEgV+FIMBBQoPCggEAgIACJwIABIDfwYvChEKBwQCAgAInwgSBoABBoIB
BwpuCgQEAgIBEgaHAQSMAQYaXiBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIGN1cmF0ZWQgcnVsZSB0aGF0IGdlbmVyYXRlZCB0aGUKIHJ1bGUgZXhlY3V0aW9uIGVy
cm9yLgoKDQoFBAICAQUSBIcBBAoKDQoFBAICAQESBIcBCxcKDQoFBAICAQMSBIcBGhsKDwoF
BAICAQgSBocBHIwBBQoQCggEAgIBCJwIABIEiAEGLwoRCgcEAgIBCJ8IEgaJAQaLAQcKvgEK
BAQCAgISBJIBAj4arwEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBy
dWxlIGV4ZWN1dGlvbiBlcnJvci4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS9ydWxlRXhlY3V0aW9uRXJy
b3JzL3tydWxlX2V4ZWN1dGlvbl9lcnJvcn0KCg0KBQQCAgIFEgSSAQIICg0KBQQCAgIBEgSS
AQkNCg0KBQQCAgIDEgSSARARCg0KBQQCAgIIEgSSARI9ChAKCAQCAgIInAgAEgSSARM8CloK
BAQCAgMSBJUBAkoaTCBPdXRwdXQgb25seS4gVGhlIGVycm9yIHN0YXR1cyBjb3JyZXNwb25k
aW5nIHdpdGggdGhlIHJ1bGUgZXhlY3V0aW9uIGVycm9yLgoKDQoFBAICAwYSBJUBAhMKDQoF
BAICAwESBJUBFBkKDQoFBAICAwMSBJUBHB0KDQoFBAICAwgSBJUBHkkKEAoIBAICAwicCAAS
BJUBH0gKZAoEBAICBBIGmQECmgEyGlQgT3V0cHV0IG9ubHkuIFRoZSBldmVudCB0aW1lIHJh
bmdlIHRoYXQgdGhlIHJ1bGUgZXhlY3V0aW9uIGVycm9yIGNvcnJlc3BvbmRzCiB3aXRoLgoK
DQoFBAICBAYSBJkBAhYKDQoFBAICBAESBJkBFyEKDQoFBAICBAMSBJkBJCUKDQoFBAICBAgS
BJoBBjEKEAoIBAICBAicCAASBJoBBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest ===
    # Fields for ListRuleExecutionErrorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse ===
    # Fields for ListRuleExecutionErrorsResponse
    # Field: rule_execution_errors Type: 11 (.google.cloud.chronicle.v1.RuleExecutionError)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError ===
    # Fields for RuleExecutionError
    # Field: rule Type: 9 ()
    # Field: curated_rule Type: 9 ()
    # Field: name Type: 9 ()
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: time_range Type: 11 (.google.type.Interval)

# === Service Client: Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionErrorServiceClient ===
package Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionErrorServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionErrorServiceClient

Client stub representing the remote C<RuleExecutionErrorService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub list_rule_execution_errors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.RuleExecutionErrorService',
        method         => 'ListRuleExecutionErrors',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::RuleExecutionError - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/rule_execution_error.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::RuleExecutionError;

    my $msg = Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/rule_execution_error.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest

Request message for ListRuleExecutionErrors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The instance to list rule execution errors from.
Format:
projects/{project}/locations/{location}/instances/{instance}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of rule execution errors to return. The service may
return fewer than this value. If unspecified, at most 1000 rule execution
errors will be returned. The maximum value is 10000; values above 10000
will be coerced to 10000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListRuleExecutionErrors` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListRuleExecutionErrors`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter that can be used to retrieve specific rule execution errors.
Only the following filters are allowed:
```
  rule = "{Rule.name}"
  curated_rule = "{CuratedRule.name}"
```
The value for rule or curated_rule must be a valid rule resource name or a
valid curated rule resource name specified in quotes.

For 'rule', an optional 'revision_id' can be specified which can be used to
fetch errors for a given revision of the rule. A '-' is also allowed to
fetch errors across all revisions of the rule. If unspecified, only errors
corresponding to the most recent revision of the rule will be returned. So
these variations are all allowed:
```
  rule = "{Rule.name}"
  rule = "{Rule.name}@{Rule.revision_id}"
  rule = "{Rule.name}@-"
```
Revision IDs are not supported for curated rules.

=back

=head2 Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse

Response message for ListRuleExecutionErrors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule_execution_errors() >> / C<< $msg->rule_execution_errors($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError>)

List of rule execution errors.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError

The RuleExecutionError resource represents an error generated from
running/deploying a rule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<String>

Output only. The resource name of the rule that generated the rule
execution error.

=item * C<< $msg->curated_rule() >> / C<< $msg->curated_rule($value) >>

Type: C<String>

Output only. The resource name of the curated rule that generated the
rule execution error.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the rule execution error.
Format:
projects/{project}/locations/{location}/instances/{instance}/ruleExecutionErrors/{rule_execution_error}

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. The error status corresponding with the rule execution error.

=item * C<< $msg->time_range() >> / C<< $msg->time_range($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Output only. The event time range that the rule execution error corresponds
with.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::RuleExecutionError::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
