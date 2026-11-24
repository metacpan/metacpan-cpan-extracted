package Google::Cloud::Apphub::V1::Workload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Apphub::V1::Attributes };
    eval { require Google::Cloud::Apphub::V1::Properties };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvYXBwaHViL3YxL3dvcmtsb2FkLnByb3RvEhZnb29nbGUuY2xvdWQu
YXBwaHViLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBp
L2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJ2dvb2dsZS9j
bG91ZC9hcHBodWIvdjEvYXR0cmlidXRlcy5wcm90bxonZ29vZ2xlL2Nsb3VkL2FwcGh1Yi92
MS9wcm9wZXJ0aWVzLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrMH
CghXb3JrbG9hZBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIg
ASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2Ny
aXB0aW9uEl0KEndvcmtsb2FkX3JlZmVyZW5jZRgEIAEoCzIpLmdvb2dsZS5jbG91ZC5hcHBo
dWIudjEuV29ya2xvYWRSZWZlcmVuY2VCA+BBA1IRd29ya2xvYWRSZWZlcmVuY2USYAoTd29y
a2xvYWRfcHJvcGVydGllcxgFIAEoCzIqLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuV29ya2xv
YWRQcm9wZXJ0aWVzQgPgQQNSEndvcmtsb2FkUHJvcGVydGllcxJkChNkaXNjb3ZlcmVkX3dv
cmtsb2FkGAYgASgJQjPgQQLgQQX6QSoSKGFwcGh1Yi5nb29nbGVhcGlzLmNvbS9EaXNjb3Zl
cmVkV29ya2xvYWRSEmRpc2NvdmVyZWRXb3JrbG9hZBJHCgphdHRyaWJ1dGVzGAcgASgLMiIu
Z29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5BdHRyaWJ1dGVzQgPgQQFSCmF0dHJpYnV0ZXMSQAoL
Y3JlYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSHQoDdWlkGAogASgJQgvijM/XCAIIAeBBA1IDdWlkEkEK
BXN0YXRlGAsgASgOMiYuZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5Xb3JrbG9hZC5TdGF0ZUID
4EEDUgVzdGF0ZSJUCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5H
EAESCgoGQUNUSVZFEAISDAoIREVMRVRJTkcQAxIMCghERVRBQ0hFRBAEOpIB6kGOAQoeYXBw
aHViLmdvb2dsZWFwaXMuY29tL1dvcmtsb2FkEldwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vYXBwbGljYXRpb25zL3thcHBsaWNhdGlvbn0vd29ya2xvYWRzL3t3
b3JrbG9hZH0qCXdvcmtsb2FkczIId29ya2xvYWQiKgoRV29ya2xvYWRSZWZlcmVuY2USFQoD
dXJpGAEgASgJQgPgQQNSA3VyaSLwAwoSV29ya2xvYWRQcm9wZXJ0aWVzEiQKC2djcF9wcm9q
ZWN0GAEgASgJQgPgQQNSCmdjcFByb2plY3QSHwoIbG9jYXRpb24YAiABKAlCA+BBA1IIbG9j
YXRpb24SFwoEem9uZRgDIAEoCUID4EEDUgR6b25lElQKD2Z1bmN0aW9uYWxfdHlwZRgEIAEo
CzImLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuRnVuY3Rpb25hbFR5cGVCA+BBA1IOZnVuY3Rp
b25hbFR5cGUScgoRZXh0ZW5kZWRfbWV0YWRhdGEYBSADKAsyQC5nb29nbGUuY2xvdWQuYXBw
aHViLnYxLldvcmtsb2FkUHJvcGVydGllcy5FeHRlbmRlZE1ldGFkYXRhRW50cnlCA+BBA1IQ
ZXh0ZW5kZWRNZXRhZGF0YRJBCghpZGVudGl0eRgGIAEoCzIgLmdvb2dsZS5jbG91ZC5hcHBo
dWIudjEuSWRlbnRpdHlCA+BBA1IIaWRlbnRpdHkabQoVRXh0ZW5kZWRNZXRhZGF0YUVudHJ5
EhAKA2tleRgBIAEoCVIDa2V5Ej4KBXZhbHVlGAIgASgLMiguZ29vZ2xlLmNsb3VkLmFwcGh1
Yi52MS5FeHRlbmRlZE1ldGFkYXRhUgV2YWx1ZToCOAEimwMKEkRpc2NvdmVyZWRXb3JrbG9h
ZBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSXQoSd29ya2xvYWRfcmVmZXJlbmNlGAIgASgL
MikuZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5Xb3JrbG9hZFJlZmVyZW5jZUID4EEDUhF3b3Jr
bG9hZFJlZmVyZW5jZRJgChN3b3JrbG9hZF9wcm9wZXJ0aWVzGAMgASgLMiouZ29vZ2xlLmNs
b3VkLmFwcGh1Yi52MS5Xb3JrbG9hZFByb3BlcnRpZXNCA+BBA1ISd29ya2xvYWRQcm9wZXJ0
aWVzOqoB6kGmAQooYXBwaHViLmdvb2dsZWFwaXMuY29tL0Rpc2NvdmVyZWRXb3JrbG9hZBJR
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Rpc2NvdmVyZWRXb3Jr
bG9hZHMve2Rpc2NvdmVyZWRfd29ya2xvYWR9KhNkaXNjb3ZlcmVkV29ya2xvYWRzMhJkaXNj
b3ZlcmVkV29ya2xvYWRCrwEKGmNvbS5nb29nbGUuY2xvdWQuYXBwaHViLnYxQg1Xb3JrbG9h
ZFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXBwaHViL2FwaXYxL2FwcGh1YnBiO2Fw
cGh1YnBiqgIWR29vZ2xlLkNsb3VkLkFwcEh1Yi5WMcoCFkdvb2dsZVxDbG91ZFxBcHBIdWJc
VjHqAhlHb29nbGU6OkNsb3VkOjpBcHBIdWI6OlYxSvAuCgcSBQ4AsAEBCrwECgEMEgMOABIy
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
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACkKCQoCAwESAxMA
JQoJCgIDAhIDFAAjCgkKAgMDEgMVADEKCQoCAwQSAxYAMQoJCgIDBRIDFwApCggKAQgSAxkA
MwoJCgIIJRIDGQAzCggKAQgSAxoASQoJCgIICxIDGgBJCggKAQgSAxsAIgoJCgIIChIDGwAi
CggKAQgSAxwALgoJCgIICBIDHAAuCggKAQgSAx0AMwoJCgIIARIDHQAzCggKAQgSAx4AMwoJ
CgIIKRIDHgAzCggKAQgSAx8AMgoJCgIILRIDHwAyCv8BCgIEABIEJQByARryASBXb3JrbG9h
ZCBpcyBhbiBBcHAgSHViIGRhdGEgbW9kZWwgdGhhdCBjb250YWlucyBhIGRpc2NvdmVyZWQg
d29ya2xvYWQsIHdoaWNoCiByZXByZXNlbnRzIGEgYmluYXJ5IGRlcGxveW1lbnQgKHN1Y2gg
YXMgbWFuYWdlZCBpbnN0YW5jZSBncm91cHMgKE1JR3MpIGFuZAogR0tFIGRlcGxveW1lbnRz
KSB0aGF0IHBlcmZvcm1zIHRoZSBzbWFsbGVzdCBsb2dpY2FsIHN1YnNldCBvZiBidXNpbmVz
cwogZnVuY3Rpb25hbGl0eS4KCgoKAwQAARIDJQgQCgsKAwQABxIEJgIrBAoNCgUEAAedCBIE
JgIrBAofCgQEAAQAEgQuAj0DGhEgV29ya2xvYWQgc3RhdGUuCgoMCgUEAAQAARIDLgcMCiMK
BgQABAACABIDMAQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgMwBBUKDgoH
BAAEAAIAAhIDMBgZCi8KBgQABAACARIDMwQRGiAgVGhlIFdvcmtsb2FkIGlzIGJlaW5nIGNy
ZWF0ZWQuCgoOCgcEAAQAAgEBEgMzBAwKDgoHBAAEAAIBAhIDMw8QCicKBgQABAACAhIDNgQP
GhggVGhlIFdvcmtsb2FkIGlzIHJlYWR5LgoKDgoHBAAEAAICARIDNgQKCg4KBwQABAACAgIS
AzYNDgovCgYEAAQAAgMSAzkEERogIFRoZSBXb3JrbG9hZCBpcyBiZWluZyBkZWxldGVkLgoK
DgoHBAAEAAIDARIDOQQMCg4KBwQABAACAwISAzkPEApECgYEAAQAAgQSAzwEERo1IFRoZSB1
bmRlcmx5aW5nIGNvbXB1dGUgcmVzb3VyY2VzIGhhdmUgYmVlbiBkZWxldGVkLgoKDgoHBAAE
AAIEARIDPAQMCg4KBwQABAACBAISAzwPEAqxAQoEBAACABIDQQI9GqMBIElkZW50aWZpZXIu
IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBXb3JrbG9hZC4gRm9ybWF0OgogYCJwcm9qZWN0
cy97aG9zdC1wcm9qZWN0LWlkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBsaWNhdGlvbnMv
e2FwcGxpY2F0aW9uLWlkfS93b3JrbG9hZHMve3dvcmtsb2FkLWlkfSJgCgoMCgUEAAIABRID
QQIICgwKBQQAAgABEgNBCQ0KDAoFBAACAAMSA0EQEQoMCgUEAAIACBIDQRI8Cg8KCAQAAgAI
nAgAEgNBEzsKaQoEBAACARIDRQJDGlwgT3B0aW9uYWwuIFVzZXItZGVmaW5lZCBuYW1lIGZv
ciB0aGUgV29ya2xvYWQuCiBDYW4gaGF2ZSBhIG1heGltdW0gbGVuZ3RoIG9mIDYzIGNoYXJh
Y3RlcnMuCgoMCgUEAAIBBRIDRQIICgwKBQQAAgEBEgNFCRUKDAoFBAACAQMSA0UYGQoMCgUE
AAIBCBIDRRpCCg8KCAQAAgEInAgAEgNFG0EKbwoEBAACAhIDSQJCGmIgT3B0aW9uYWwuIFVz
ZXItZGVmaW5lZCBkZXNjcmlwdGlvbiBvZiBhIFdvcmtsb2FkLgogQ2FuIGhhdmUgYSBtYXhp
bXVtIGxlbmd0aCBvZiAyMDQ4IGNoYXJhY3RlcnMuCgoMCgUEAAICBRIDSQIICgwKBQQAAgIB
EgNJCRQKDAoFBAACAgMSA0kXGAoMCgUEAAICCBIDSRlBCg8KCAQAAgIInAgAEgNJGkAKewoE
BAACAxIETQJOMhptIE91dHB1dCBvbmx5LiBSZWZlcmVuY2Ugb2YgYW4gdW5kZXJseWluZyBj
b21wdXRlIHJlc291cmNlIHJlcHJlc2VudGVkIGJ5IHRoZQogV29ya2xvYWQuIFRoZXNlIGFy
ZSBpbW11dGFibGUuCgoMCgUEAAIDBhIDTQITCgwKBQQAAgMBEgNNFCYKDAoFBAACAwMSA00p
KgoMCgUEAAIDCBIDTgYxCg8KCAQAAgMInAgAEgNOBzAKfAoEBAACBBIEUgJTMhpuIE91dHB1
dCBvbmx5LiBQcm9wZXJ0aWVzIG9mIGFuIHVuZGVybHlpbmcgY29tcHV0ZSByZXNvdXJjZSBy
ZXByZXNlbnRlZCBieQogdGhlIFdvcmtsb2FkLiBUaGVzZSBhcmUgaW1tdXRhYmxlLgoKDAoF
BAACBAYSA1ICFAoMCgUEAAIEARIDUhUoCgwKBQQAAgQDEgNSKywKDAoFBAACBAgSA1MGMQoP
CggEAAIECJwIABIDUwcwClsKBAQAAgUSBFYCXAQaTSBSZXF1aXJlZC4gSW1tdXRhYmxlLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgb3JpZ2luYWwgZGlzY292ZXJlZCB3b3JrbG9hZC4K
CgwKBQQAAgUFEgNWAggKDAoFBAACBQESA1YJHAoMCgUEAAIFAxIDVh8gCg0KBQQAAgUIEgRW
IVwDCg8KCAQAAgUInAgAEgNXBCoKDwoIBAACBQicCAESA1gEKwoPCgcEAAIFCJ8IEgRZBFsF
CjYKBAQAAgYSA18CRRopIE9wdGlvbmFsLiBDb25zdW1lciBwcm92aWRlZCBhdHRyaWJ1dGVz
LgoKDAoFBAACBgYSA18CDAoMCgUEAAIGARIDXw0XCgwKBQQAAgYDEgNfGhsKDAoFBAACBggS
A18cRAoPCggEAAIGCJwIABIDXx1DCikKBAQAAgcSBGICYzIaGyBPdXRwdXQgb25seS4gQ3Jl
YXRlIHRpbWUuCgoMCgUEAAIHBhIDYgIbCgwKBQQAAgcBEgNiHCcKDAoFBAACBwMSA2IqKwoM
CgUEAAIHCBIDYwYxCg8KCAQAAgcInAgAEgNjBzAKKQoEBAACCBIEZgJnMhobIE91dHB1dCBv
bmx5LiBVcGRhdGUgdGltZS4KCgwKBQQAAggGEgNmAhsKDAoFBAACCAESA2YcJwoMCgUEAAII
AxIDZiorCgwKBQQAAggIEgNnBjEKDwoIBAACCAicCAASA2cHMApsCgQEAAIJEgRrAm4EGl4g
T3V0cHV0IG9ubHkuIEEgdW5pdmVyc2FsbHkgdW5pcXVlIGlkZW50aWZpZXIgKFVVSUQpIGZv
ciB0aGUgYFdvcmtsb2FkYCBpbgogdGhlIFVVSUQ0IGZvcm1hdC4KCgwKBQQAAgkFEgNrAggK
DAoFBAACCQESA2sJDAoMCgUEAAIJAxIDaw8RCg0KBQQAAgkIEgRrEm4DChIKCwQAAgkIzPH5
igEBEgNsBCoKDwoIBAACCQicCAASA20ELQorCgQEAAIKEgNxAj8aHiBPdXRwdXQgb25seS4g
V29ya2xvYWQgc3RhdGUuCgoMCgUEAAIKBhIDcQIHCgwKBQQAAgoBEgNxCA0KDAoFBAACCgMS
A3EQEgoMCgUEAAIKCBIDcRM+Cg8KCAQAAgoInAgAEgNxFD0KVgoCBAESBHUAeAEaSiBSZWZl
cmVuY2Ugb2YgYW4gdW5kZXJseWluZyBjb21wdXRlIHJlc291cmNlIHJlcHJlc2VudGVkIGJ5
IHRoZSBXb3JrbG9hZC4KCgoKAwQBARIDdQgZCkAKBAQBAgASA3cCPRozIE91dHB1dCBvbmx5
LiBUaGUgdW5kZXJseWluZyBjb21wdXRlIHJlc291cmNlIHVyaS4KCgwKBQQBAgAFEgN3AggK
DAoFBAECAAESA3cJDAoMCgUEAQIAAxIDdw8QCgwKBQQBAgAIEgN3ETwKDwoIBAECAAicCAAS
A3cSOwpYCgIEAhIFewCVAQEaSyBQcm9wZXJ0aWVzIG9mIGFuIHVuZGVybHlpbmcgY29tcHV0
ZSByZXNvdXJjZSByZXByZXNlbnRlZCBieSB0aGUgV29ya2xvYWQuCgoKCgMEAgESA3sIGgqJ
AQoEBAICABIDfgJFGnwgT3V0cHV0IG9ubHkuIFRoZSBzZXJ2aWNlIHByb2plY3QgaWRlbnRp
ZmllciB0aGF0IHRoZSB1bmRlcmx5aW5nIGNsb3VkCiByZXNvdXJjZSByZXNpZGVzIGluLiBF
bXB0eSBmb3Igbm9uLWNsb3VkIHJlc291cmNlcy4KCgwKBQQCAgAFEgN+AggKDAoFBAICAAES
A34JFAoMCgUEAgIAAxIDfhcYCgwKBQQCAgAIEgN+GUQKDwoIBAICAAicCAASA34aQwpzCgQE
AgIBEgSCAQJCGmUgT3V0cHV0IG9ubHkuIFRoZSBsb2NhdGlvbiB0aGF0IHRoZSB1bmRlcmx5
aW5nIGNvbXB1dGUgcmVzb3VyY2UgcmVzaWRlcyBpbgogKGZvciBleGFtcGxlLCB1cy13ZXN0
MSkuCgoNCgUEAgIBBRIEggECCAoNCgUEAgIBARIEggEJEQoNCgUEAgIBAxIEggEUFQoNCgUE
AgIBCBIEggEWQQoQCggEAgIBCJwIABIEggEXQAqEAQoEBAICAhIEhgECPhp2IE91dHB1dCBv
bmx5LiBUaGUgbG9jYXRpb24gdGhhdCB0aGUgdW5kZXJseWluZyBjb21wdXRlIHJlc291cmNl
IHJlc2lkZXMgaW4KIGlmIGl0IGlzIHpvbmFsIChmb3IgZXhhbXBsZSwgdXMtd2VzdDEtYSku
CgoNCgUEAgICBRIEhgECCAoNCgUEAgICARIEhgEJDQoNCgUEAgICAxIEhgEQEQoNCgUEAgIC
CBIEhgESPQoQCggEAgICCJwIABIEhgETPAo4CgQEAgIDEgaJAQKKATIaKCBPdXRwdXQgb25s
eS4gVGhlIHR5cGUgb2YgdGhlIHdvcmtsb2FkLgoKDQoFBAICAwYSBIkBAhAKDQoFBAICAwES
BIkBESAKDQoFBAICAwMSBIkBIyQKDQoFBAICAwgSBIoBBjEKEAoIBAICAwicCAASBIoBBzAK
/wEKBAQCAgQSBpABApEBMhruASBPdXRwdXQgb25seS4gQWRkaXRpb25hbCBtZXRhZGF0YSBz
cGVjaWZpYyB0byB0aGUgcmVzb3VyY2UgdHlwZS4KIFRoZSBrZXkgaXMgYSBzdHJpbmcgdGhh
dCBpZGVudGlmaWVzIHRoZSB0eXBlIG9mIG1ldGFkYXRhIGFuZCB0aGUgdmFsdWUgaXMKIHRo
ZSBtZXRhZGF0YSBjb250ZW50cyBzcGVjaWZpYyB0byB0aGF0IHR5cGUuCiBLZXkgZm9ybWF0
OiBgYXBwaHViLmdvb2dsZWFwaXMuY29tL3ttZXRhZGF0YVR5cGV9YAoKDQoFBAICBAYSBJAB
Ah8KDQoFBAICBAESBJABIDEKDQoFBAICBAMSBJABNDUKDQoFBAICBAgSBJEBBjEKEAoIBAIC
BAicCAASBJEBBzAKRwoEBAICBRIElAECRBo5IE91dHB1dCBvbmx5LiBUaGUgaWRlbnRpdHkg
YXNzb2NpYXRlZCB3aXRoIHRoZSB3b3JrbG9hZC4KCg0KBQQCAgUGEgSUAQIKCg0KBQQCAgUB
EgSUAQsTCg0KBQQCAgUDEgSUARYXCg0KBQQCAgUIEgSUARhDChAKCAQCAgUInAgAEgSUARlC
Cv8BCgIEAxIGmwEAsAEBGvABIERpc2NvdmVyZWRXb3JrbG9hZCBpcyBhIGJpbmFyeSBkZXBs
b3ltZW50IChzdWNoIGFzIG1hbmFnZWQgaW5zdGFuY2UgZ3JvdXBzCiAoTUlHcykgYW5kIEdL
RSBkZXBsb3ltZW50cykgdGhhdCBwZXJmb3JtcyB0aGUgc21hbGxlc3QgbG9naWNhbCBzdWJz
ZXQgb2YKIGJ1c2luZXNzIGZ1bmN0aW9uYWxpdHkuIEEgZGlzY292ZXJlZCB3b3JrbG9hZCBj
YW4gYmUgcmVnaXN0ZXJlZCB0byBhbiBBcHAgSHViCiBXb3JrbG9hZC4KCgsKAwQDARIEmwEI
GgoNCgMEAwcSBpwBAqEBBAoPCgUEAwedCBIGnAECoQEECqIBCgQEAwIAEgSlAQI9GpMBIElk
ZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkaXNjb3ZlcmVkIHdvcmtsb2Fk
LiBGb3JtYXQ6CiBgInByb2plY3RzL3tob3N0LXByb2plY3QtaWR9L2xvY2F0aW9ucy97bG9j
YXRpb259L2Rpc2NvdmVyZWRXb3JrbG9hZHMve3V1aWR9ImAKCg0KBQQDAgAFEgSlAQIICg0K
BQQDAgABEgSlAQkNCg0KBQQDAgADEgSlARARCg0KBQQDAgAIEgSlARI8ChAKCAQDAgAInAgA
EgSlARM7Cn0KBAQDAgESBqkBAqoBMhptIE91dHB1dCBvbmx5LiBSZWZlcmVuY2Ugb2YgYW4g
dW5kZXJseWluZyBjb21wdXRlIHJlc291cmNlIHJlcHJlc2VudGVkIGJ5IHRoZQogV29ya2xv
YWQuIFRoZXNlIGFyZSBpbW11dGFibGUuCgoNCgUEAwIBBhIEqQECEwoNCgUEAwIBARIEqQEU
JgoNCgUEAwIBAxIEqQEpKgoNCgUEAwIBCBIEqgEGMQoQCggEAwIBCJwIABIEqgEHMAp+CgQE
AwICEgauAQKvATIabiBPdXRwdXQgb25seS4gUHJvcGVydGllcyBvZiBhbiB1bmRlcmx5aW5n
IGNvbXB1dGUgcmVzb3VyY2UgcmVwcmVzZW50ZWQgYnkKIHRoZSBXb3JrbG9hZC4gVGhlc2Ug
YXJlIGltbXV0YWJsZS4KCg0KBQQDAgIGEgSuAQIUCg0KBQQDAgIBEgSuARUoCg0KBQQDAgID
EgSuASssCg0KBQQDAgIIEgSvAQYxChAKCAQDAgIInAgAEgSvAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Workload::Workload ===
    # Fields for Workload
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: workload_reference Type: 11 (.google.cloud.apphub.v1.WorkloadReference)
    # Field: workload_properties Type: 11 (.google.cloud.apphub.v1.WorkloadProperties)
    # Field: discovered_workload Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.apphub.v1.Attributes)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.apphub.v1.Workload.State)

# Enum: Workload::State
our $Workload_STATE_UNSPECIFIED = 0;
our $Workload_CREATING = 1;
our $Workload_ACTIVE = 2;
our $Workload_DELETING = 3;
our $Workload_DETACHED = 4;

# === Message: Google::Cloud::Apphub::V1::Workload::WorkloadReference ===
    # Fields for WorkloadReference
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Apphub::V1::Workload::WorkloadProperties ===
    # Fields for WorkloadProperties
    # Field: gcp_project Type: 9 ()
    # Field: location Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: functional_type Type: 11 (.google.cloud.apphub.v1.FunctionalType)
    # Field: extended_metadata Type: 11 (.google.cloud.apphub.v1.WorkloadProperties.ExtendedMetadataEntry)
    # Field: identity Type: 11 (.google.cloud.apphub.v1.Identity)

# === Message: Google::Cloud::Apphub::V1::Workload::DiscoveredWorkload ===
    # Fields for DiscoveredWorkload
    # Field: name Type: 9 ()
    # Field: workload_reference Type: 11 (.google.cloud.apphub.v1.WorkloadReference)
    # Field: workload_properties Type: 11 (.google.cloud.apphub.v1.WorkloadProperties)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Workload - Compiled Protocol Buffers messages for google/cloud/apphub/v1/workload.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Workload;

    my $msg = Google::Cloud::Apphub::V1::Workload::Workload->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        workload_reference => $workload_reference,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Workload::Workload->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/workload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Workload::Workload

Workload is an App Hub data model that contains a discovered workload, which
represents a binary deployment (such as managed instance groups (MIGs) and
GKE deployments) that performs the smallest logical subset of business
functionality.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the Workload. Format:
`"projects/{host-project-id}/locations/{location}/applications/{application-id}/workloads/{workload-id}"`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined name for the Workload.
Can have a maximum length of 63 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of a Workload.
Can have a maximum length of 2048 characters.

=item * C<< $msg->workload_reference() >> / C<< $msg->workload_reference($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Workload::WorkloadReference>)

Output only. Reference of an underlying compute resource represented by the
Workload. These are immutable.

=item * C<< $msg->workload_properties() >> / C<< $msg->workload_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Workload::WorkloadProperties>)

Output only. Properties of an underlying compute resource represented by
the Workload. These are immutable.

=item * C<< $msg->discovered_workload() >> / C<< $msg->discovered_workload($value) >>

Type: C<String>

Required. Immutable. The resource name of the original discovered workload.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Attributes>)

Optional. Consumer provided attributes.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A universally unique identifier (UUID) for the `Workload` in
the UUID4 format.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Workload::State>)

Output only. Workload state.

=back

=head3 Enum: Workload::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<DETACHED> => C<4>

=back

=head2 Google::Cloud::Apphub::V1::Workload::WorkloadReference

Reference of an underlying compute resource represented by the Workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Output only. The underlying compute resource uri.

=back

=head2 Google::Cloud::Apphub::V1::Workload::WorkloadProperties

Properties of an underlying compute resource represented by the Workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_project() >> / C<< $msg->gcp_project($value) >>

Type: C<String>

Output only. The service project identifier that the underlying cloud
resource resides in. Empty for non-cloud resources.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Output only. The location that the underlying compute resource resides in
(for example, us-west1).

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

Output only. The location that the underlying compute resource resides in
if it is zonal (for example, us-west1-a).

=item * C<< $msg->functional_type() >> / C<< $msg->functional_type($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Properties::FunctionalType>)

Output only. The type of the workload.

=item * C<< $msg->extended_metadata() >> / C<< $msg->extended_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Workload::WorkloadProperties::ExtendedMetadataEntry>)

Output only. Additional metadata specific to the resource type.
The key is a string that identifies the type of metadata and the value is
the metadata contents specific to that type.
Key format: `apphub.googleapis.com/{metadataType}`

=item * C<< $msg->identity() >> / C<< $msg->identity($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Properties::Identity>)

Output only. The identity associated with the workload.

=back

=head2 Google::Cloud::Apphub::V1::Workload::DiscoveredWorkload

DiscoveredWorkload is a binary deployment (such as managed instance groups
(MIGs) and GKE deployments) that performs the smallest logical subset of
business functionality. A discovered workload can be registered to an App Hub
Workload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the discovered workload. Format:
`"projects/{host-project-id}/locations/{location}/discoveredWorkloads/{uuid}"`

=item * C<< $msg->workload_reference() >> / C<< $msg->workload_reference($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Workload::WorkloadReference>)

Output only. Reference of an underlying compute resource represented by the
Workload. These are immutable.

=item * C<< $msg->workload_properties() >> / C<< $msg->workload_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Workload::WorkloadProperties>)

Output only. Properties of an underlying compute resource represented by
the Workload. These are immutable.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Workload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
