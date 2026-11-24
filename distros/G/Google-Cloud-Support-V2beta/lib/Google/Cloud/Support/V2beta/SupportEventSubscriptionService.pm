package Google::Cloud::Support::V2beta::SupportEventSubscriptionService;

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
    eval { require Google::Cloud::Support::V2beta::SupportEventSubscription };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvc3VwcG9ydF9ldmVudF9zdWJzY3JpcHRp
b25fc2VydmljZS5wcm90bxIbZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo8
Z29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjJiZXRhL3N1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9u
LnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9m
aWVsZF9tYXNrLnByb3RvIvcBCiVDcmVhdGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1
ZXN0ElQKBnBhcmVudBgBIAEoCUI84EEC+kE2EjRjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5j
b20vU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUgZwYXJlbnQSeAoac3VwcG9ydF9ldmVudF9z
dWJzY3JpcHRpb24YAiABKAsyNS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuU3VwcG9y
dEV2ZW50U3Vic2NyaXB0aW9uQgPgQQJSGHN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbiJ2CiJH
ZXRTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0ElAKBG5hbWUYASABKAlCPOBBAvpB
Ngo0Y2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL1N1cHBvcnRFdmVudFN1YnNjcmlwdGlv
blIEbmFtZSKHAgokTGlzdFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbnNSZXF1ZXN0ElQKBnBh
cmVudBgBIAEoCUI84EEC+kE2EjRjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vU3VwcG9y
dEV2ZW50U3Vic2NyaXB0aW9uUgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQFSBmZpbHRl
chImCgxzaG93X2RlbGV0ZWQYAyABKAhCA+BBAVILc2hvd0RlbGV0ZWQSIAoJcGFnZV9zaXpl
GAQgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YBSABKAlCA+BBAVIJcGFnZVRv
a2VuIsYBCiVMaXN0U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uc1Jlc3BvbnNlEnUKG3N1cHBv
cnRfZXZlbnRfc3Vic2NyaXB0aW9ucxgBIAMoCzI1Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYy
YmV0YS5TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SGXN1cHBvcnRFdmVudFN1YnNjcmlwdGlv
bnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIuMBCiVVcGRhdGVT
dXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0EngKGnN1cHBvcnRfZXZlbnRfc3Vic2Ny
aXB0aW9uGAEgASgLMjUuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLlN1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvbkID4EECUhhzdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24SQAoLdXBkYXRl
X21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1h
c2sieQolRGVsZXRlU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVzdBJQCgRuYW1lGAEg
ASgJQjzgQQL6QTYKNGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9TdXBwb3J0RXZlbnRT
dWJzY3JpcHRpb25SBG5hbWUiewonVW5kZWxldGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25S
ZXF1ZXN0ElAKBG5hbWUYASABKAlCPOBBAvpBNgo0Y2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMu
Y29tL1N1cHBvcnRFdmVudFN1YnNjcmlwdGlvblIEbmFtZSJ6CiZFeHB1bmdlU3VwcG9ydEV2
ZW50U3Vic2NyaXB0aW9uUmVxdWVzdBJQCgRuYW1lGAEgASgJQjzgQQL6QTYKNGNsb3Vkc3Vw
cG9ydC5nb29nbGVhcGlzLmNvbS9TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SBG5hbWUy4w4K
H1N1cHBvcnRFdmVudFN1YnNjcmlwdGlvblNlcnZpY2USoAIKHkNyZWF0ZVN1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvbhJCLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5DcmVhdGVTdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0GjUuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJi
ZXRhLlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbiKCAYLT5JMCWCI6L3YyYmV0YS97cGFyZW50
PW9yZ2FuaXphdGlvbnMvKn0vc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uczoac3VwcG9ydF9l
dmVudF9zdWJzY3JpcHRpb27aQSFwYXJlbnQsc3VwcG9ydF9ldmVudF9zdWJzY3JpcHRpb24S
4AEKG0dldFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbhI/Lmdvb2dsZS5jbG91ZC5zdXBwb3J0
LnYyYmV0YS5HZXRTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25SZXF1ZXN0GjUuZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjJiZXRhLlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbiJJgtPkkwI8Ejov
djJiZXRhL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9zdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25z
Lyp92kEEbmFtZRLzAQodTGlzdFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbnMSQS5nb29nbGUu
Y2xvdWQuc3VwcG9ydC52MmJldGEuTGlzdFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbnNSZXF1
ZXN0GkIuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLkxpc3RTdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb25zUmVzcG9uc2UiS4LT5JMCPBI6L3YyYmV0YS97cGFyZW50PW9yZ2FuaXphdGlv
bnMvKn0vc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uc9pBBnBhcmVudBLAAgoeVXBkYXRlU3Vw
cG9ydEV2ZW50U3Vic2NyaXB0aW9uEkIuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhLlVw
ZGF0ZVN1cHBvcnRFdmVudFN1YnNjcmlwdGlvblJlcXVlc3QaNS5nb29nbGUuY2xvdWQuc3Vw
cG9ydC52MmJldGEuU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uIqIBgtPkkwJzMlUvdjJiZXRh
L3tzdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbi5uYW1lPW9yZ2FuaXphdGlvbnMvKi9zdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25zLyp9OhpzdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbtpB
JnN1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uLHVwZGF0ZV9tYXNrEuYBCh5EZWxldGVTdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb24SQi5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuRGVs
ZXRlU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5zdXBw
b3J0LnYyYmV0YS5TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24iSYLT5JMCPCo6L3YyYmV0YS97
bmFtZT1vcmdhbml6YXRpb25zLyovc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucy8qfdpBBG5h
bWUS7wEKIFVuZGVsZXRlU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uEkQuZ29vZ2xlLmNsb3Vk
LnN1cHBvcnQudjJiZXRhLlVuZGVsZXRlU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVz
dBo1Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5TdXBwb3J0RXZlbnRTdWJzY3JpcHRp
b24iToLT5JMCSCJDL3YyYmV0YS97bmFtZT1vcmdhbml6YXRpb25zLyovc3VwcG9ydEV2ZW50
U3Vic2NyaXB0aW9ucy8qfTp1bmRlbGV0ZToBKhLUAQofRXhwdW5nZVN1cHBvcnRFdmVudFN1
YnNjcmlwdGlvbhJDLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5FeHB1bmdlU3VwcG9y
dEV2ZW50U3Vic2NyaXB0aW9uUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eSJUgtPk
kwJHIkIvdjJiZXRhL3tuYW1lPW9yZ2FuaXphdGlvbnMvKi9zdXBwb3J0RXZlbnRTdWJzY3Jp
cHRpb25zLyp9OmV4cHVuZ2U6ASraQQRuYW1lGk/KQRtjbG91ZHN1cHBvcnQuZ29vZ2xlYXBp
cy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3Jt
QuEBCh9jb20uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRhQiRTdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb25TZXJ2aWNlUHJvdG9QAVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2Fw
aXYyYmV0YS9zdXBwb3J0cGI7c3VwcG9ydHBiqgIbR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjJC
ZXRhygIbR29vZ2xlXENsb3VkXFN1cHBvcnRcVjJiZXRh6gIeR29vZ2xlOjpDbG91ZDo6U3Vw
cG9ydDo6VjJiZXRhSqY3CgcSBQ4AigIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYARgoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA4CgkKAggl
EgMaADgKCAoBCBIDGwBQCgkKAggLEgMbAFAKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBID
HQBFCgkKAggIEgMdAEUKCAoBCBIDHgA4CgkKAggBEgMeADgKCAoBCBIDHwA4CgkKAggpEgMf
ADgKCAoBCBIDIAA3CgkKAggtEgMgADcKSQoCBgASBSMAiAEBGjwgU2VydmljZSBmb3IgbWFu
YWdpbmcgY3VzdG9tZXIgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb25zLgoKCgoDBgABEgMj
CCcKCgoDBgADEgMkAkMKDAoFBgADmQgSAyQCQwoLCgMGAAMSBCUCJjcKDQoFBgADmggSBCUC
JjcKSQoEBgACABIEKQIwAxo7IENyZWF0ZXMgYSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlv
biBmb3IgYW4gb3JnYW5pemF0aW9uLgoKDAoFBgACAAESAykGJAoMCgUGAAIAAhIDKSVKCgwK
BQYAAgADEgMqDycKDQoFBgACAAQSBCsELgYKEQoJBgACAASwyrwiEgQrBC4GCgwKBQYAAgAE
EgMvBE8KDwoIBgACAASbCAASAy8ETwoyCgQGAAIBEgQzAjkDGiQgR2V0cyBhIHN1cHBvcnQg
ZXZlbnQgc3Vic2NyaXB0aW9uLgoKDAoFBgACAQESAzMGIQoMCgUGAAIBAhIDMyJECgwKBQYA
AgEDEgM0DycKDQoFBgACAQQSBDUENwYKEQoJBgACAQSwyrwiEgQ1BDcGCgwKBQYAAgEEEgM4
BDIKDwoIBgACAQSbCAASAzgEMgpGCgQGAAICEgQ8AkIDGjggTGlzdHMgc3VwcG9ydCBldmVu
dCBzdWJzY3JpcHRpb25zIGZvciBhbiBvcmdhbml6YXRpb24uCgoMCgUGAAICARIDPAYjCgwK
BQYAAgICEgM8JEgKDAoFBgACAgMSAz0PNAoNCgUGAAICBBIEPgRABgoRCgkGAAICBLDKvCIS
BD4EQAYKDAoFBgACAgQSA0EENAoPCggGAAICBJsIABIDQQQ0CjUKBAYAAgMSBEUCTQMaJyBV
cGRhdGVzIGEgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24uCgoMCgUGAAIDARIDRQYkCgwK
BQYAAgMCEgNFJUoKDAoFBgACAwMSA0YPJwoNCgUGAAIDBBIERwRKBgoRCgkGAAIDBLDKvCIS
BEcESgYKDQoFBgACAwQSBEsETDEKEAoIBgACAwSbCAASBEsETDEKOgoEBgACBBIEUAJWAxos
IFNvZnQgZGVsZXRlcyBhIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9uLgoKDAoFBgACBAES
A1AGJAoMCgUGAAIEAhIDUCVKCgwKBQYAAgQDEgNRDycKDQoFBgACBAQSBFIEVAYKEQoJBgAC
BASwyrwiEgRSBFQGCgwKBQYAAgQEEgNVBDIKDwoIBgACBASbCAASA1UEMgo3CgQGAAIFEgRZ
Al8DGikgVW5kZWxldGVzIGEgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24uCgoMCgUGAAIF
ARIDWQYmCgwKBQYAAgUCEgNZJ04KDAoFBgACBQMSA1oPJwoNCgUGAAIFBBIEWwReBgoRCgkG
AAIFBLDKvCISBFsEXgYKzgYKBAYAAgYSBoABAocBAxq9BiBFeHB1bmdlcyBhIHN1cHBvcnQg
ZXZlbnQgc3Vic2NyaXB0aW9uLgoKIEVYQU1QTEVTOgoKIGNVUkw6CgogYGBgc2hlbGwKIHN1
cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uPSJvcmdhbml6YXRpb25zLzEyMzQ1Njc4OS9zdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25zL2FiY2RlZjEyMzQ1NiIKIGN1cmwgXAogICAtLXJlcXVl
c3QgUE9TVCBcCiAgIC0taGVhZGVyICJBdXRob3JpemF0aW9uOiBCZWFyZXIgJChnY2xvdWQg
YXV0aCBwcmludC1hY2Nlc3MtdG9rZW4pIiBcCiAgICJodHRwczovL2Nsb3Vkc3VwcG9ydC5n
b29nbGVhcGlzLmNvbS92MmJldGEvJHN1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uOmV4cHVu
Z2UiCiBgYGAKCiBQeXRob246CgogYGBgcHl0aG9uCiBpbXBvcnQgZ29vZ2xlYXBpY2xpZW50
LmRpc2NvdmVyeQoKIGFwaV92ZXJzaW9uID0gInYyYmV0YSIKIHN1cHBvcnRBcGlTZXJ2aWNl
ID0gZ29vZ2xlYXBpY2xpZW50LmRpc2NvdmVyeS5idWlsZCgKICAgICBzZXJ2aWNlTmFtZT0i
Y2xvdWRzdXBwb3J0IiwKICAgICB2ZXJzaW9uPWFwaV92ZXJzaW9uLAogICAgIGRpc2NvdmVy
eVNlcnZpY2VVcmw9ZiJodHRwczovL2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS8kZGlz
Y292ZXJ5L3Jlc3Q/dmVyc2lvbj17YXBpX3ZlcnNpb259IiwKICkKCiByZXF1ZXN0ID0gc3Vw
cG9ydEFwaVNlcnZpY2Uuc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucygpLmV4cHVuZ2UoCiAg
ICAgbmFtZT0ib3JnYW5pemF0aW9ucy8xMjM0NTY3ODkvc3VwcG9ydEV2ZW50U3Vic2NyaXB0
aW9ucy9hYmNkZWYxMjM0NTYiCiApCiBwcmludChyZXF1ZXN0LmV4ZWN1dGUoKSkKIGBgYAoK
DQoFBgACBgESBIABBiUKDQoFBgACBgISBIABJkwKDQoFBgACBgMSBIEBDyQKDwoFBgACBgQS
BoIBBIUBBgoTCgkGAAIGBLDKvCISBoIBBIUBBgoNCgUGAAIGBBIEhgEEMgoQCggGAAIGBJsI
ABIEhgEEMgpDCgIEABIGiwEAmAEBGjUgUmVxdWVzdCBtZXNzYWdlIGZvciBDcmVhdGVTdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb24uCgoLCgMEAAESBIsBCC0KlAEKBAQAAgASBo4BApMBBBqD
ASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lIHdoZXJlIHRoZSBzdXBwb3J0
IGV2ZW50IHN1YnNjcmlwdGlvbgogd2lsbCBiZSBjcmVhdGVkLiBGb3JtYXQ6IG9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbl9pZH0KCg0KBQQAAgAFEgSOAQIICg0KBQQAAgABEgSOAQkP
Cg0KBQQAAgADEgSOARITCg8KBQQAAgAIEgaOARSTAQMKEAoIBAACAAicCAASBI8BBCoKEQoH
BAACAAifCBIGkAEEkgEFCkAKBAQAAgESBpYBApcBLxowIFJlcXVpcmVkLiBUaGUgUHViL1N1
YiBjb25maWd1cmF0aW9uIHRvIGNyZWF0ZS4KCg0KBQQAAgEGEgSWAQIaCg0KBQQAAgEBEgSW
ARs1Cg0KBQQAAgEDEgSWATg5Cg0KBQQAAgEIEgSXAQYuChAKCAQAAgEInAgAEgSXAQctCkAK
AgQBEgabAQClAQEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIEdldFN1cHBvcnRFdmVudFN1YnNj
cmlwdGlvbi4KCgsKAwQBARIEmwEIKgqqAQoEBAECABIGnwECpAEEGpkBIFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24gdG8gcmV0cmlldmUu
CiBGb3JtYXQ6CiBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L3N1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvbnMve3N1YnNjcmlwdGlvbl9pZH0KCg0KBQQBAgAFEgSfAQIICg0KBQQB
AgABEgSfAQkNCg0KBQQBAgADEgSfARARCg8KBQQBAgAIEgafARKkAQMKEAoIBAECAAicCAAS
BKABBCoKEQoHBAECAAifCBIGoQEEowEFCkIKAgQCEgaoAQDMAQEaNCBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIExpc3RTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zLgoKCwoDBAIBEgSoAQgsCp8B
CgQEAgIAEgarAQKwAQQajgEgUmVxdWlyZWQuIFRoZSBmdWxseSBxdWFsaWZpZWQgbmFtZSBv
ZiB0aGUgQ2xvdWQgcmVzb3VyY2UgdG8gbGlzdCBzdXBwb3J0CiBldmVudCBzdWJzY3JpcHRp
b25zIHVuZGVyLiBGb3JtYXQ6IG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0KCg0K
BQQCAgAFEgSrAQIICg0KBQQCAgABEgSrAQkPCg0KBQQCAgADEgSrARITCg8KBQQCAgAIEgar
ARSwAQMKEAoIBAICAAicCAASBKwBBCoKEQoHBAICAAifCBIGrQEErwEFCqMCCgQEAgIBEgS8
AQI9GpQCIE9wdGlvbmFsLiBGaWx0ZXIgZXhwcmVzc2lvbiBiYXNlZCBvbiBBSVAtMTYwLgog
U3VwcG9ydGVkIGZpZWxkczoKIC0gcHViX3N1Yl90b3BpYwogLSBzdGF0ZQoKIEV4YW1wbGVz
OgogLSBgcHViX3N1Yl90b3BpYz0icHJvamVjdHMvZXhhbXBsZS1wcm9qZWN0L3RvcGljcy9l
eGFtcGxlLXRvcGljImAKIC0gYHN0YXRlPVdPUktJTkdgCiAtIGBwdWJfc3ViX3RvcGljPSJw
cm9qZWN0cy9leGFtcGxlLXByb2plY3QvdG9waWNzL2V4YW1wbGUtdG9waWMiIEFORAogc3Rh
dGU9V09SS0lOR2AKCg0KBQQCAgEFEgS8AQIICg0KBQQCAgEBEgS8AQkPCg0KBQQCAgEDEgS8
ARITCg0KBQQCAgEIEgS8ARQ8ChAKCAQCAgEInAgAEgS8ARU7CnUKBAQCAgISBMABAkEaZyBP
cHRpb25hbC4gV2hldGhlciB0byBzaG93IGRlbGV0ZWQgc3Vic2NyaXB0aW9ucy4gQnkgZGVm
YXVsdCwgZGVsZXRlZAogc3Vic2NyaXB0aW9ucyBhcmUgbm90IHJldHVybmVkLgoKDQoFBAIC
AgUSBMABAgYKDQoFBAICAgESBMABBxMKDQoFBAICAgMSBMABFhcKDQoFBAICAggSBMABGEAK
EAoIBAICAgicCAASBMABGT8KVgoEBAICAxIEwwECPxpIIE9wdGlvbmFsLiBUaGUgbWF4aW11
bSBudW1iZXIgb2Ygc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb25zIHRvIHJldHVybi4KCg0K
BQQCAgMFEgTDAQIHCg0KBQQCAgMBEgTDAQgRCg0KBQQCAgMDEgTDARQVCg0KBQQCAgMIEgTD
ARY+ChAKCAQCAgMInAgAEgTDARc9CoMCCgQEAgIEEgTLAQJBGvQBIE9wdGlvbmFsLiBBIHRv
a2VuIGlkZW50aWZ5aW5nIHRoZSBwYWdlIG9mIHJlc3VsdHMgdG8gcmV0dXJuLiBJZgogdW5z
cGVjaWZpZWQsIHRoZSBmaXJzdCBwYWdlIGlzIHJldHJpZXZlZC4KCiBXaGVuIHBhZ2luYXRp
bmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgTGlzdFN1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvbnNgIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUg
cGFnZQogdG9rZW4uCgoNCgUEAgIEBRIEywECCAoNCgUEAgIEARIEywEJEwoNCgUEAgIEAxIE
ywEWFwoNCgUEAgIECBIEywEYQAoQCggEAgIECJwIABIEywEZPwpDCgIEAxIGzwEA1gEBGjUg
UmVzcG9uc2UgbWVzc2FnZSBmb3IgTGlzdFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbnMuCgoL
CgMEAwESBM8BCC0KMAoEBAMCABIE0QECRBoiIFRoZSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlw
dGlvbnMuCgoNCgUEAwIABBIE0QECCgoNCgUEAwIABhIE0QELIwoNCgUEAwIAARIE0QEkPwoN
CgUEAwIAAxIE0QFCQwqQAQoEBAMCARIE1QECHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUg
c2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRo
aXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoN
CgUEAwIBBRIE1QECCAoNCgUEAwIBARIE1QEJGAoNCgUEAwIBAxIE1QEbHApDCgIEBBIG2QEA
4wEBGjUgUmVxdWVzdCBtZXNzYWdlIGZvciBVcGRhdGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRp
b24uCgoLCgMEBAESBNkBCC0KiAEKBAQEAgASBtwBAt0BLxp4IFJlcXVpcmVkLiBUaGUgc3Vw
cG9ydCBldmVudCBzdWJzY3JpcHRpb24gdG8gdXBkYXRlLgogVGhlIGBuYW1lYCBmaWVsZCBp
cyB1c2VkIHRvIGlkZW50aWZ5IHRoZSBjb25maWd1cmF0aW9uIHRvIHVwZGF0ZS4KCg0KBQQE
AgAGEgTcAQIaCg0KBQQEAgABEgTcARs1Cg0KBQQEAgADEgTcATg5Cg0KBQQEAgAIEgTdAQYu
ChAKCAQEAgAInAgAEgTdAQctCmUKBAQEAgESBuEBAuIBLxpVIE9wdGlvbmFsLiBUaGUgbGlz
dCBvZiBmaWVsZHMgdG8gdXBkYXRlLiBUaGUgb25seSBzdXBwb3J0ZWQgdmFsdWUgaXMKIHB1
Yl9zdWJfdG9waWMuCgoNCgUEBAIBBhIE4QECGwoNCgUEBAIBARIE4QEcJwoNCgUEBAIBAxIE
4QEqKwoNCgUEBAIBCBIE4gEGLgoQCggEBAIBCJwIABIE4gEHLQpDCgIEBRIG5gEA8AEBGjUg
UmVxdWVzdCBtZXNzYWdlIGZvciBEZWxldGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24uCgoL
CgMEBQESBOYBCC0KqAEKBAQFAgASBuoBAu8BBBqXASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9uIHRvIGRlbGV0ZS4KIEZvcm1hdDoKIG9y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9u
cy97c3Vic2NyaXB0aW9uX2lkfQoKDQoFBAUCAAUSBOoBAggKDQoFBAUCAAESBOoBCQ0KDQoF
BAUCAAMSBOoBEBEKDwoFBAUCAAgSBuoBEu8BAwoQCggEBQIACJwIABIE6wEEKgoRCgcEBQIA
CJ8IEgbsAQTuAQUKRQoCBAYSBvMBAP0BARo3IFJlcXVlc3QgbWVzc2FnZSBmb3IgVW5kZWxl
dGVTdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24uCgoLCgMEBgESBPMBCC8KqgEKBAQGAgASBvcB
AvwBBBqZASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHN1cHBvcnQgZXZlbnQgc3Vic2Ny
aXB0aW9uIHRvIHVuZGVsZXRlLgogRm9ybWF0Ogogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0
aW9uX2lkfS9zdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zL3tzdWJzY3JpcHRpb25faWR9CgoN
CgUEBgIABRIE9wECCAoNCgUEBgIAARIE9wEJDQoNCgUEBgIAAxIE9wEQEQoPCgUEBgIACBIG
9wES/AEDChAKCAQGAgAInAgAEgT4AQQqChEKBwQGAgAInwgSBvkBBPsBBQpECgIEBxIGgAIA
igIBGjYgUmVxdWVzdCBtZXNzYWdlIGZvciBFeHB1bmdlU3VwcG9ydEV2ZW50U3Vic2NyaXB0
aW9uLgoKCwoDBAcBEgSAAgguCqkBCgQEBwIAEgaEAgKJAgQamAEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlvbiB0byBleHB1bmdlLgogRm9y
bWF0Ogogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9zdXBwb3J0RXZlbnRTdWJz
Y3JpcHRpb25zL3tzdWJzY3JpcHRpb25faWR9CgoNCgUEBwIABRIEhAICCAoNCgUEBwIAARIE
hAIJDQoNCgUEBwIAAxIEhAIQEQoPCgUEBwIACBIGhAISiQIDChAKCAQHAgAInAgAEgSFAgQq
ChEKBwQHAgAInwgSBoYCBIgCBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest ===
    # Fields for CreateSupportEventSubscriptionRequest
    # Field: parent Type: 9 ()
    # Field: support_event_subscription Type: 11 (.google.cloud.support.v2beta.SupportEventSubscription)

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest ===
    # Fields for GetSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest ===
    # Fields for ListSupportEventSubscriptionsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: show_deleted Type: 8 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse ===
    # Fields for ListSupportEventSubscriptionsResponse
    # Field: support_event_subscriptions Type: 11 (.google.cloud.support.v2beta.SupportEventSubscription)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest ===
    # Fields for UpdateSupportEventSubscriptionRequest
    # Field: support_event_subscription Type: 11 (.google.cloud.support.v2beta.SupportEventSubscription)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest ===
    # Fields for DeleteSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest ===
    # Fields for UndeleteSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest ===
    # Fields for ExpungeSupportEventSubscriptionRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient ===
package Google::Cloud::Support::V2beta::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2beta::SupportEventSubscriptionService::SupportEventSubscriptionServiceClient

Client stub representing the remote C<SupportEventSubscriptionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

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

sub create_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'CreateSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription',
    });
}

sub get_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'GetSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription',
    });
}

sub list_support_event_subscriptions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'ListSupportEventSubscriptions',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse',
    });
}

sub update_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'UpdateSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription',
    });
}

sub delete_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'DeleteSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription',
    });
}

sub undelete_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'UndeleteSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription',
    });
}

sub expunge_support_event_subscription {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'ExpungeSupportEventSubscription',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::SupportEventSubscriptionService - Compiled Protocol Buffers messages for google/cloud/support/v2beta/support_event_subscription_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::SupportEventSubscriptionService;

    my $msg = Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->new({
        parent => $parent,
        support_event_subscription => $support_event_subscription,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/support_event_subscription_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest

Request message for CreateSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the support event subscription
will be created. Format: organizations/{organization_id}

=item * C<< $msg->support_event_subscription() >> / C<< $msg->support_event_subscription($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription>)

Required. The Pub/Sub configuration to create.

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest

Request message for GetSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to retrieve.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest

Request message for ListSupportEventSubscriptions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The fully qualified name of the Cloud resource to list support
event subscriptions under. Format: organizations/{organization_id}

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression based on AIP-160.
Supported fields:
- pub_sub_topic
- state

Examples:
- `pub_sub_topic="projects/example-project/topics/example-topic"`
- `state=WORKING`
- `pub_sub_topic="projects/example-project/topics/example-topic" AND
state=WORKING`

=item * C<< $msg->show_deleted() >> / C<< $msg->show_deleted($value) >>

Type: C<Bool>

Optional. Whether to show deleted subscriptions. By default, deleted
subscriptions are not returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of support event subscriptions to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying the page of results to return. If
unspecified, the first page is retrieved.

When paginating, all other parameters provided to
`ListSupportEventSubscriptions` must match the call that provided the page
token.

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse

Response message for ListSupportEventSubscriptions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->support_event_subscriptions() >> / C<< $msg->support_event_subscriptions($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription>)

The support event subscriptions.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest

Request message for UpdateSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->support_event_subscription() >> / C<< $msg->support_event_subscription($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription>)

Required. The support event subscription to update.
The `name` field is used to identify the configuration to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update. The only supported value is
pub_sub_topic.

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest

Request message for DeleteSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to delete.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest

Request message for UndeleteSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to undelete.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head2 Google::Cloud::Support::V2beta::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest

Request message for ExpungeSupportEventSubscription.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the support event subscription to expunge.
Format:
organizations/{organization_id}/supportEventSubscriptions/{subscription_id}

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::SupportEventSubscriptionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
