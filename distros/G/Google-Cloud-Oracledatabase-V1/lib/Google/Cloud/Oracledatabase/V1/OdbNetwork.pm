package Google::Cloud::Oracledatabase::V1::OdbNetwork;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvb2RiX25ldHdvcmsucHJvdG8SHmdv
b2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byL3BgoKT2RiTmV0d29yaxIXCgRuYW1lGAEgASgJQgPg
QQhSBG5hbWUSQwoHbmV0d29yaxgCIAEoCUIp4EEC4EEF+kEgCh5jb21wdXRlLmdvb2dsZWFw
aXMuY29tL05ldHdvcmtSB25ldHdvcmsSUwoGbGFiZWxzGAMgAygLMjYuZ29vZ2xlLmNsb3Vk
Lm9yYWNsZWRhdGFiYXNlLnYxLk9kYk5ldHdvcmsuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxz
EkAKC2NyZWF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
UgpjcmVhdGVUaW1lEksKBXN0YXRlGAUgASgOMjAuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFi
YXNlLnYxLk9kYk5ldHdvcmsuU3RhdGVCA+BBA1IFc3RhdGUSKgoOZW50aXRsZW1lbnRfaWQY
BiABKAlCA+BBA1INZW50aXRsZW1lbnRJZBIuCg9nY3Bfb3JhY2xlX3pvbmUYByABKAlCBuBB
AeBBBVINZ2NwT3JhY2xlWm9uZRJ+ChtzZXJ2aWNlX2Nvbm5lY3Rpdml0eV9jb25maWcYCCAB
KAsyOS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuU2VydmljZUNvbm5lY3Rpdml0
eUNvbmZpZ0ID4EEBUhlzZXJ2aWNlQ29ubmVjdGl2aXR5Q29uZmlnEiUKC3JlY29uY2lsaW5n
GAkgASgIQgPgQQNSC3JlY29uY2lsaW5nGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVID
a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiXAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABIQCgxQUk9WSVNJT05JTkcQARINCglBVkFJTEFCTEUQAhIPCgtURVJNSU5BVElO
RxADEgoKBkZBSUxFRBAEOooB6kGGAQoob3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20v
T2RiTmV0d29yaxJBcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L29k
Yk5ldHdvcmtzL3tvZGJfbmV0d29ya30qC29kYk5ldHdvcmtzMgpvZGJOZXR3b3JrIowCChdD
cmVhdGVPZGJOZXR3b3JrUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKhIob3JhY2xl
ZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vT2RiTmV0d29ya1IGcGFyZW50EikKDm9kYl9uZXR3
b3JrX2lkGAIgASgJQgPgQQJSDG9kYk5ldHdvcmtJZBJQCgtvZGJfbmV0d29yaxgDIAEoCzIq
Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5PZGJOZXR3b3JrQgPgQQJSCm9kYk5l
dHdvcmsSKgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCKLAQoX
RGVsZXRlT2RiTmV0d29ya1JlcXVlc3QSRAoEbmFtZRgBIAEoCUIw4EEC+kEqCihvcmFjbGVk
YXRhYmFzZS5nb29nbGVhcGlzLmNvbS9PZGJOZXR3b3JrUgRuYW1lEioKCnJlcXVlc3RfaWQY
AiABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQi2QEKF1VwZGF0ZU9kYk5ldHdvcmtSZXF1
ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID
4EEBUgp1cGRhdGVNYXNrElAKC29kYl9uZXR3b3JrGAIgASgLMiouZ29vZ2xlLmNsb3VkLm9y
YWNsZWRhdGFiYXNlLnYxLk9kYk5ldHdvcmtCA+BBAlIKb2RiTmV0d29yaxIqCgpyZXF1ZXN0
X2lkGAMgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElkIuUBChZMaXN0T2RiTmV0d29ya3NS
ZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqEihvcmFjbGVkYXRhYmFzZS5nb29nbGVh
cGlzLmNvbS9PZGJOZXR3b3JrUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgE
IAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKyAQoX
TGlzdE9kYk5ldHdvcmtzUmVzcG9uc2USTQoMb2RiX25ldHdvcmtzGAEgAygLMiouZ29vZ2xl
LmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLk9kYk5ldHdvcmtSC29kYk5ldHdvcmtzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMo
CVILdW5yZWFjaGFibGUiXAoUR2V0T2RiTmV0d29ya1JlcXVlc3QSRAoEbmFtZRgBIAEoCUIw
4EEC+kEqCihvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9PZGJOZXR3b3JrUgRuYW1l
InUKElBzY0ludGVyZmFjZUNvbmZpZxJfChJuZXR3b3JrX2F0dGFjaG1lbnQYASABKAlCMOBB
AfpBKgooY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9OZXR3b3JrQXR0YWNobWVudFIRbmV0d29y
a0F0dGFjaG1lbnQihgEKGVNlcnZpY2VDb25uZWN0aXZpdHlDb25maWcSaQoUcHNjX2ludGVy
ZmFjZV9jb25maWcYASABKAsyMi5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuUHNj
SW50ZXJmYWNlQ29uZmlnQgPgQQFSEnBzY0ludGVyZmFjZUNvbmZpZ0LpAQoiY29tLmdvb2ds
ZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MUIPT2RiTmV0d29ya1Byb3RvUAFaSmNsb3VkLmdv
b2dsZS5jb20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFj
bGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xl
XENsb3VkXE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJh
c2U6OlYxStNQCgcSBQ4AmQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACoK
CQoCAwQSAxYAKQoICgEIEgMYADsKCQoCCCUSAxgAOwoICgEIEgMZAGEKCQoCCAsSAxkAYQoI
CgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADAKCQoCCAgSAxsAMAoICgEIEgMcADsKCQoC
CAESAxwAOwoICgEIEgMdADsKCQoCCCkSAx0AOwoICgEIEgMeADoKCQoCCC0SAx4AOgotCgIE
ABIEIQBrARohIFJlcHJlc2VudHMgT2RiTmV0d29yayByZXNvdXJjZS4KCgoKAwQAARIDIQgS
CgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBApACgQEAAQAEgQqAjkDGjIgVGhlIHZhcmlv
dXMgbGlmZWN5Y2xlIHN0YXRlcyBvZiB0aGUgT0RCIE5ldHdvcmsuCgoMCgUEAAQAARIDKgcM
CisKBgQABAACABIDLAQaGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg4KBwQABAAC
AAESAywEFQoOCgcEAAQAAgACEgMsGBkKRgoGBAAEAAIBEgMvBBUaNyBJbmRpY2F0ZXMgdGhh
dCB0aGUgcmVzb3VyY2UgaXMgaW4gcHJvdmlzaW9uaW5nIHN0YXRlLgoKDgoHBAAEAAIBARID
LwQQCg4KBwQABAACAQISAy8TFApDCgYEAAQAAgISAzIEEho0IEluZGljYXRlcyB0aGF0IHRo
ZSByZXNvdXJjZSBpcyBpbiBhdmFpbGFibGUgc3RhdGUuCgoOCgcEAAQAAgIBEgMyBA0KDgoH
BAAEAAICAhIDMhARCkUKBgQABAACAxIDNQQUGjYgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291
cmNlIGlzIGluIHRlcm1pbmF0aW5nIHN0YXRlLgoKDgoHBAAEAAIDARIDNQQPCg4KBwQABAAC
AwISAzUSEwpACgYEAAQAAgQSAzgEDxoxIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBp
cyBpbiBmYWlsZWQgc3RhdGUuCgoOCgcEAAQAAgQBEgM4BAoKDgoHBAAEAAIEAhIDOA0OCpkB
CgQEAAIAEgM9Aj0aiwEgSWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhlIE9kYk5ldHdvcmsg
cmVzb3VyY2UgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tyZWdpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30KCgwKBQQAAgAF
EgM9AggKDAoFBAACAAESAz0JDQoMCgUEAAIAAxIDPRARCgwKBQQAAgAIEgM9EjwKDwoIBAAC
AAicCAASAz0TOwqHAQoEBAACARIEQQJFBBp5IFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBu
YW1lIG9mIHRoZSBWUEMgbmV0d29yayBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIHByb2pl
Y3RzL3twcm9qZWN0fS9nbG9iYWwvbmV0d29ya3Mve25ldHdvcmt9CgoMCgUEAAIBBRIDQQII
CgwKBQQAAgEBEgNBCRAKDAoFBAACAQMSA0ETFAoNCgUEAAIBCBIEQRVFAwoPCggEAAIBCJwI
ABIDQgQqCg8KCAQAAgEInAgBEgNDBCsKDgoHBAACAQifCBIDRARQCkUKBAQAAgISA0gCSho4
IE9wdGlvbmFsLiBMYWJlbHMgb3IgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIHJlc291cmNl
LgoKDAoFBAACAgYSA0gCFQoMCgUEAAICARIDSBYcCgwKBQQAAgIDEgNIHyAKDAoFBAACAggS
A0ghSQoPCggEAAICCJwIABIDSCJICk8KBAQAAgMSBEsCTDIaQSBPdXRwdXQgb25seS4gVGhl
IGRhdGUgYW5kIHRpbWUgdGhhdCB0aGUgT2RiTmV0d29yayB3YXMgY3JlYXRlZC4KCgwKBQQA
AgMGEgNLAhsKDAoFBAACAwESA0scJwoMCgUEAAIDAxIDSyorCgwKBQQAAgMIEgNMBjEKDwoI
BAACAwicCAASA0wHMAo1CgQEAAIEEgNPAj4aKCBPdXRwdXQgb25seS4gU3RhdGUgb2YgdGhl
IE9EQiBOZXR3b3JrLgoKDAoFBAACBAYSA08CBwoMCgUEAAIEARIDTwgNCgwKBQQAAgQDEgNP
EBEKDAoFBAACBAgSA08SPQoPCggEAAIECJwIABIDTxM8CmMKBAQAAgUSA1MCSBpWIE91dHB1
dCBvbmx5LiBUaGUgSUQgb2YgdGhlIHN1YnNjcmlwdGlvbiBlbnRpdGxlbWVudCBhc3NvY2lh
dGVkIHdpdGggdGhlCiBPZGJOZXR3b3JrLgoKDAoFBAACBQUSA1MCCAoMCgUEAAIFARIDUwkX
CgwKBQQAAgUDEgNTGhsKDAoFBAACBQgSA1McRwoPCggEAAIFCJwIABIDUx1GCrQBCgQEAAIG
EgRYAlsEGqUBIE9wdGlvbmFsLiBJbW11dGFibGUuIFRoZSBHQ1AgT3JhY2xlIHpvbmUgd2hl
cmUgT2RiTmV0d29yayBpcyBob3N0ZWQuCiBFeGFtcGxlOiB1cy1lYXN0NC1iLXIyLgogSWYg
bm90IHNwZWNpZmllZCwgdGhlIHN5c3RlbSB3aWxsIHBpY2sgYSB6b25lIGJhc2VkIG9uIGF2
YWlsYWJpbGl0eS4KCgwKBQQAAgYFEgNYAggKDAoFBAACBgESA1gJGAoMCgUEAAIGAxIDWBsc
Cg0KBQQAAgYIEgRYHVsDCg8KCAQAAgYInAgAEgNZBCoKDwoIBAACBgicCAESA1oEKwqWAwoE
BAACBxIEZQJmLxqHAyBPcHRpb25hbC4gQ29uZmlndXJhdGlvbiB0byBlbmFibGUgdGhlIHNl
cnZpY2UgKE9yYWNsZWRhdGFiYXNlQEdvb2dsZSBDbG91ZCkKIHRvIGVzdGFibGlzaCBjb25u
ZWN0aXZpdHkgdG8gdGhlIGRhdGFiYXNlLgoKIFRoaXMgc2hvdWxkIGJlIHNwZWNpZmllZCBp
ZiB5b3UgaW50ZW5kIHRvIGFzc29jaWF0ZSB0aGlzIE9kYk5ldHdvcmsgd2l0aCBhCiBEYXRh
YmFzZUNvbm5lY3Rpb24gcmVzb3VyY2UgdG8gYEV4ZWN1dGVTUUxgIG9uIHRoZSBkYXRhYmFz
ZSwgb3IgdG8gY3JlYXRlIGEKIFNlcnZpY2VJbnRlZ3JhdGlvbiB3aXRoIHRoZSBEYXRhYmFz
ZS4KCiBQbGVhc2UgZG9uJ3Qgc3BlY2lmeSBpdCBvdGhlcndpc2UgdG8gYXZvaWQgY29tcGxp
Y2F0aW5nIHRoZSBuZXR3b3JrIHNldHVwLgoKDAoFBAACBwYSA2UCGwoMCgUEAAIHARIDZRw3
CgwKBQQAAgcDEgNlOjsKDAoFBAACBwgSA2YGLgoPCggEAAIHCJwIABIDZgctCl8KBAQAAggS
A2oCQxpSIE91dHB1dCBvbmx5LiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgT2RiTmV0d29yayBp
cyBjdXJyZW50bHkgcmVjb25jaWxpbmcKIGNoYW5nZXMuCgoMCgUEAAIIBRIDagIGCgwKBQQA
AggBEgNqBxIKDAoFBAACCAMSA2oVFgoMCgUEAAIICBIDahdCCg8KCAQAAggInAgAEgNqGEEK
MwoCBAESBW4AjQEBGiYgVGhlIHJlcXVlc3QgZm9yIGBPZGJOZXR3b3JrLkNyZWF0ZWAuCgoK
CgMEAQESA24IHwqAAQoEBAECABIEcQJ2BBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50IHZhbHVl
IGZvciB0aGUgT2RiTmV0d29yayBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS4KCgwKBQQBAgAFEgNxAggKDAoFBAEC
AAESA3EJDwoMCgUEAQIAAxIDcRITCg0KBQQBAgAIEgRxFHYDCg8KCAQBAgAInAgAEgNyBCoK
DwoHBAECAAifCBIEcwR1BQr4AQoEBAECARIDfAJFGuoBIFJlcXVpcmVkLiBUaGUgSUQgb2Yg
dGhlIE9kYk5ldHdvcmsgdG8gY3JlYXRlLiBUaGlzIHZhbHVlIGlzIHJlc3RyaWN0ZWQKIHRv
ICheW2Etel0oW2EtejAtOS1dezAsNjF9W2EtejAtOV0pPyQpIGFuZCBtdXN0IGJlIGEgbWF4
aW11bSBvZiA2MwogY2hhcmFjdGVycyBpbiBsZW5ndGguIFRoZSB2YWx1ZSBtdXN0IHN0YXJ0
IHdpdGggYSBsZXR0ZXIgYW5kIGVuZCB3aXRoCiBhIGxldHRlciBvciBhIG51bWJlci4KCgwK
BQQBAgEFEgN8AggKDAoFBAECAQESA3wJFwoMCgUEAQIBAxIDfBobCgwKBQQBAgEIEgN8HEQK
DwoIBAECAQicCAASA3wdQwpGCgQEAQICEgN/AkYaOSBSZXF1aXJlZC4gRGV0YWlscyBvZiB0
aGUgT2RiTmV0d29yayBpbnN0YW5jZSB0byBjcmVhdGUuCgoMCgUEAQICBhIDfwIMCgwKBQQB
AgIBEgN/DRgKDAoFBAECAgMSA38bHAoMCgUEAQICCBIDfx1FCg8KCAQBAgIInAgAEgN/HkQK
1wMKBAQBAgMSBokBAowBBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8gaWRlbnRp
ZnkgdGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkgZHVwbGlj
YXRlIHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2FtZSByZXF1
ZXN0IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJvZ3Jlc3Mg
b3IgY29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4g
VGhpcyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBs
aWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVV
SUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVk
ICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAECAwUSBIkB
AggKDQoFBAECAwESBIkBCRMKDQoFBAECAwMSBIkBFhcKDwoFBAECAwgSBokBGIwBAwoTCgsE
AQIDCMzx+YoBARIEigEEKgoQCggEAQIDCJwIABIEiwEEKgo0CgIEAhIGkAEApgEBGiYgVGhl
IHJlcXVlc3QgZm9yIGBPZGJOZXR3b3JrLkRlbGV0ZWAuCgoLCgMEAgESBJABCB8KkgEKBAQC
AgASBpMBApgBBBqBASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHJlc291cmNlIGluIHRo
ZSBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L29kYk5ldHdvcmtzL3tvZGJfbmV0d29ya30uCgoNCgUEAgIABRIEkwECCAoNCgUE
AgIAARIEkwEJDQoNCgUEAgIAAxIEkwEQEQoPCgUEAgIACBIGkwESmAEDChAKCAQCAgAInAgA
EgSUAQQqChEKBwQCAgAInwgSBpUBBJcBBQrXAwoEBAICARIGogECpQEEGsYDIE9wdGlvbmFs
LiBBbiBvcHRpb25hbCBJRCB0byBpZGVudGlmeSB0aGUgcmVxdWVzdC4gVGhpcyB2YWx1ZSBp
cyB1c2VkIHRvCiBpZGVudGlmeSBkdXBsaWNhdGUgcmVxdWVzdHMuIElmIHlvdSBtYWtlIGEg
cmVxdWVzdCB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIGFuZCB0aGUgb3JpZ2luYWwgcmVx
dWVzdCBpcyBzdGlsbCBpbiBwcm9ncmVzcyBvciBjb21wbGV0ZWQsIHRoZSBzZXJ2ZXIKIGln
bm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzIGNsaWVudHMgZnJvbQog
YWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4KCiBUaGUgcmVx
dWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6
ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAw
MDAwMDAwMDAwMCkuCgoNCgUEAgIBBRIEogECCAoNCgUEAgIBARIEogEJEwoNCgUEAgIBAxIE
ogEWFwoPCgUEAgIBCBIGogEYpQEDChMKCwQCAgEIzPH5igEBEgSjAQQqChAKCAQCAgEInAgA
EgSkAQQqCjQKAgQDEgapAQDHAQEaJiBUaGUgcmVxdWVzdCBmb3IgYE9kYk5ldHdvcmsuVXBk
YXRlYC4KCgsKAwQDARIEqQEIHwr3AgoEBAMCABIGrwECsAEvGuYCIE9wdGlvbmFsLiBBIG1h
c2sgc3BlY2lmeWluZyB3aGljaCBmaWVsZHMgaW4gdGhlIE9kYk5ldHdvcmsgc2hvdWxkIGJl
CiB1cGRhdGVkLiBBIGZpZWxkIHNwZWNpZmllZCBpbiB0aGUgbWFzayBpcyB1cGRhdGVkLiBJ
ZiBhIG1hc2sgaXNuJ3QKIHByb3ZpZGVkLCB0aGUgc2VydmljZSB0cmVhdHMgdGhpcyBhcyBh
biBpbXBsaWVkIGZpZWxkIG1hc2sgZXF1aXZhbGVudCB0bwogYWxsIGZpZWxkcyB0aGF0IGFy
ZSBwb3B1bGF0ZWQgKGhhdmUgYSBub24tZW1wdHkgdmFsdWUpLiBUbyBjbGVhciBvciB1bnNl
dCBhCiBmaWVsZCwgdGhlIGZpZWxkIG11c3QgYmUgZXhwbGljaXRseSBzcGVjaWZpZWQgaW4g
dGhlIGB1cGRhdGVfbWFza2AuCgoNCgUEAwIABhIErwECGwoNCgUEAwIAARIErwEcJwoNCgUE
AwIAAxIErwEqKwoNCgUEAwIACBIEsAEGLgoQCggEAwIACJwIABIEsAEHLQrVAwoEBAMCARIE
uQECRhrGAyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJlaW5nIHVwZGF0ZWQuIE5vdGUgb25s
eSBgbGFiZWxzYCBhbmQKIGBzZXJ2aWNlX2Nvbm5lY3Rpdml0eV9jb25maWdgIGNhbiBiZSB1
cGRhdGVkLgogVGhlIHByb3ZpZGVkIGxhYmVscyB3aWxsIGNvbXBsZXRlbHkgcmVwbGFjZSB0
aGUgZXhpc3RpbmcgbGFiZWxzLgogQW55IGV4aXN0aW5nIGxhYmVsIGtleXMgdGhhdCBhcmUg
bm90IGluY2x1ZGVkIGluIHRoZSB1cGRhdGUgcmVxdWVzdCB3aWxsIGJlCiBkZWxldGVkLiBO
b3QgcHJvdmlkaW5nIGxhYmVscyBhbmQgdXBkYXRlX21hc2sgd2lsbCBub3QgdXBkYXRlIHRo
ZSBsYWJlbHMuCiBUbyBjbGVhciBhbGwgbGFiZWxzLCBzcGVjaWZ5IGBsYWJlbHNgIGluIHRo
ZSBgdXBkYXRlX21hc2tgIGFuZCBvbWl0IG9yCiBsZWF2ZSB0aGUgYGxhYmVsc2AgZmllbGQg
ZW1wdHkgaW4gdGhlIHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAMCAQYSBLkBAgwKDQoFBAMCAQES
BLkBDRgKDQoFBAMCAQMSBLkBGxwKDQoFBAMCAQgSBLkBHUUKEAoIBAMCAQicCAASBLkBHkQK
1wMKBAQDAgISBsMBAsYBBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8gaWRlbnRp
ZnkgdGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkgZHVwbGlj
YXRlIHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2FtZSByZXF1
ZXN0IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJvZ3Jlc3Mg
b3IgY29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4g
VGhpcyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBs
aWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVV
SUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVk
ICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAMCAgUSBMMB
AggKDQoFBAMCAgESBMMBCRMKDQoFBAMCAgMSBMMBFhcKDwoFBAMCAggSBsMBGMYBAwoTCgsE
AwICCMzx+YoBARIExAEEKgoQCggEAwICCJwIABIExQEEKgoyCgIEBBIGygEA4QEBGiQgVGhl
IHJlcXVlc3QgZm9yIGBPZGJOZXR3b3JrLkxpc3RgLgoKCwoDBAQBEgTKAQgeCoMBCgQEBAIA
EgbNAQLSAQQacyBSZXF1aXJlZC4gVGhlIHBhcmVudCB2YWx1ZSBmb3IgdGhlIE9EQiBOZXR3
b3JrIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259LgoKDQoFBAQCAAUSBM0BAggKDQoFBAQCAAESBM0BCQ8KDQoFBAQC
AAMSBM0BEhMKDwoFBAQCAAgSBs0BFNIBAwoQCggEBAIACJwIABIEzgEEKgoRCgcEBAIACJ8I
EgbPAQTRAQUKwwEKBAQEAgESBNcBAj8atAEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJl
ciBvZiBpdGVtcyB0byByZXR1cm4uCiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MCBPREIg
TmV0d29ya3Mgd2lsbCBiZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7
IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAQCAQUS
BNcBAgcKDQoFBAQCAQESBNcBCBEKDQoFBAQCAQMSBNcBFBUKDQoFBAQCAQgSBNcBFj4KEAoI
BAQCAQicCAASBNcBFz0KWQoEBAQCAhIE2gECQRpLIE9wdGlvbmFsLiBBIHRva2VuIGlkZW50
aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCg0K
BQQEAgIFEgTaAQIICg0KBQQEAgIBEgTaAQkTCg0KBQQEAgIDEgTaARYXCg0KBQQEAgIIEgTa
ARhAChAKCAQEAgIInAgAEgTaARk/ClEKBAQEAgMSBN0BAj0aQyBPcHRpb25hbC4gQW4gZXhw
cmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LgoKDQoF
BAQCAwUSBN0BAggKDQoFBAQCAwESBN0BCQ8KDQoFBAQCAwMSBN0BEhMKDQoFBAQCAwgSBN0B
FDwKEAoIBAQCAwicCAASBN0BFTsKUAoEBAQCBBIE4AECPxpCIE9wdGlvbmFsLiBBbiBleHBy
ZXNzaW9uIGZvciBvcmRlcmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVzdC4KCg0KBQQE
AgQFEgTgAQIICg0KBQQEAgQBEgTgAQkRCg0KBQQEAgQDEgTgARQVCg0KBQQEAgQIEgTgARY+
ChAKCAQEAgQInAgAEgTgARc9CjMKAgQFEgbkAQDuAQEaJSBUaGUgcmVzcG9uc2UgZm9yIGBP
ZGJOZXR3b3JrLkxpc3RgLgoKCwoDBAUBEgTkAQgfCikKBAQFAgASBOYBAicaGyBUaGUgbGlz
dCBvZiBPREIgTmV0d29ya3MuCgoNCgUEBQIABBIE5gECCgoNCgUEBQIABhIE5gELFQoNCgUE
BQIAARIE5gEWIgoNCgUEBQIAAxIE5gElJgpPCgQEBQIBEgTpAQIdGkEgQSB0b2tlbiBpZGVu
dGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uCgoN
CgUEBQIBBRIE6QECCAoNCgUEBQIBARIE6QEJGAoNCgUEBQIBAxIE6QEbHApvCgQEBQICEgTt
AQIiGmEgVW5yZWFjaGFibGUgbG9jYXRpb25zIHdoZW4gbGlzdGluZyByZXNvdXJjZXMgYWNy
b3NzIGFsbCBsb2NhdGlvbnMgdXNpbmcKIHdpbGRjYXJkIGxvY2F0aW9uICctJy4KCg0KBQQF
AgIEEgTtAQIKCg0KBQQFAgIFEgTtAQsRCg0KBQQFAgIBEgTtARIdCg0KBQQFAgIDEgTtASAh
CjEKAgQGEgbxAQD6AQEaIyBUaGUgcmVxdWVzdCBmb3IgYE9kYk5ldHdvcmsuR2V0YC4KCgsK
AwQGARIE8QEIHAqUAQoEBAYCABIG9AEC+QEEGoMBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgT2RiTmV0d29yayBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97b2RiX25ldHdvcmt9LgoK
DQoFBAYCAAUSBPQBAggKDQoFBAYCAAESBPQBCQ0KDQoFBAYCAAMSBPQBEBEKDwoFBAYCAAgS
BvQBEvkBAwoQCggEBgIACJwIABIE9QEEKgoRCgcEBgIACJ8IEgb2AQT4AQUKpQEKAgQHEgb/
AQCLAgEalgEgQ29uZmlndXJhdGlvbiBmb3IgYSBQcml2YXRlIFNlcnZpY2UgQ29ubmVjdCAo
UFNDKSBpbnRlcmZhY2UgdXNlZCBieQogT3JhY2xlZGF0YWJhc2VAR29vZ2xlIENsb3VkIHRv
IGVzdGFibGlzaCBwcml2YXRlIGNvbm5lY3Rpdml0eSB0byB0aGUKIGRhdGFiYXNlLgoKCwoD
BAcBEgT/AQgaCq0CCgQEBwIAEgaFAgKKAgQanAIgT3B0aW9uYWwuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBOZXR3b3JrIEF0dGFjaG1lbnQgdGhhdAogT3JhY2xlZGF0YWJhc2VAR29v
Z2xlIENsb3VkIHdpbGwgdXNlIHRvIGVzdGFibGlzaCBwcml2YXRlIGNvbm5lY3Rpdml0eSB0
bwogdGhlIGRhdGFiYXNlIHZpYSBhIFByaXZhdGUgU2VydmljZSBDb25uZWN0IEludGVyZmFj
ZSAoUFNDLUkpLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L3JlZ2lvbnMve3JlZ2lv
bn0vbmV0d29ya0F0dGFjaG1lbnRzL3tuZXR3b3JrX2F0dGFjaG1lbnR9CgoNCgUEBwIABRIE
hQICCAoNCgUEBwIAARIEhQIJGwoNCgUEBwIAAxIEhQIeHwoPCgUEBwIACBIGhQIgigIDChAK
CAQHAgAInAgAEgSGAgQqChEKBwQHAgAInwgSBocCBIkCBQqMAwoCBAgSBpUCAJkCARr9AiBD
b25maWd1cmF0aW9uIHRvIGVuYWJsZSB0aGUgc2VydmljZSAoT3JhY2xlZGF0YWJhc2VAR29v
Z2xlIENsb3VkKSB0bwogZXN0YWJsaXNoIGNvbm5lY3Rpdml0eSB0byB0aGUgZGF0YWJhc2Uu
CgogVGhpcyBzaG91bGQgYmUgc3BlY2lmaWVkIGlmIHlvdSBpbnRlbmQgdG8gYXNzb2NpYXRl
IHRoaXMgT2RiTmV0d29yayB3aXRoIGEKIERhdGFiYXNlQ29ubmVjdGlvbiByZXNvdXJjZSB0
byBgRXhlY3V0ZVNRTGAgb24gdGhlIGRhdGFiYXNlLCBvciB0byBjcmVhdGUgYQogU2Vydmlj
ZUludGVncmF0aW9uIHdpdGggdGhlIERhdGFiYXNlLgoKIFBsZWFzZSBkb24ndCBzcGVjaWZ5
IGl0IG90aGVyd2lzZSB0byBhdm9pZCBjb21wbGljYXRpbmcgdGhlIG5ldHdvcmsgc2V0dXAu
CgoLCgMECAESBJUCCCEKVgoEBAgCABIGlwICmAIvGkYgT3B0aW9uYWwuIENvbmZpZ3VyYXRp
b24gZm9yIFByaXZhdGUgU2VydmljZSBDb25uZWN0IChQU0MpIGludGVyZmFjZS4KCg0KBQQI
AgAGEgSXAgIUCg0KBQQIAgABEgSXAhUpCg0KBQQIAgADEgSXAiwtCg0KBQQIAgAIEgSYAgYu
ChAKCAQIAgAInAgAEgSYAgctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork ===
    # Fields for OdbNetwork
    # Field: name Type: 9 ()
    # Field: network Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.OdbNetwork.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.OdbNetwork.State)
    # Field: entitlement_id Type: 9 ()
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: service_connectivity_config Type: 11 (.google.cloud.oracledatabase.v1.ServiceConnectivityConfig)
    # Field: reconciling Type: 8 ()

# Enum: OdbNetwork::State
our $OdbNetwork_STATE_UNSPECIFIED = 0;
our $OdbNetwork_PROVISIONING = 1;
our $OdbNetwork_AVAILABLE = 2;
our $OdbNetwork_TERMINATING = 3;
our $OdbNetwork_FAILED = 4;

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::CreateOdbNetworkRequest ===
    # Fields for CreateOdbNetworkRequest
    # Field: parent Type: 9 ()
    # Field: odb_network_id Type: 9 ()
    # Field: odb_network Type: 11 (.google.cloud.oracledatabase.v1.OdbNetwork)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::DeleteOdbNetworkRequest ===
    # Fields for DeleteOdbNetworkRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::UpdateOdbNetworkRequest ===
    # Fields for UpdateOdbNetworkRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: odb_network Type: 11 (.google.cloud.oracledatabase.v1.OdbNetwork)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksRequest ===
    # Fields for ListOdbNetworksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksResponse ===
    # Fields for ListOdbNetworksResponse
    # Field: odb_networks Type: 11 (.google.cloud.oracledatabase.v1.OdbNetwork)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::GetOdbNetworkRequest ===
    # Fields for GetOdbNetworkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig ===
    # Fields for PscInterfaceConfig
    # Field: network_attachment Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig ===
    # Fields for ServiceConnectivityConfig
    # Field: psc_interface_config Type: 11 (.google.cloud.oracledatabase.v1.PscInterfaceConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::OdbNetwork - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/odb_network.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::OdbNetwork;

    my $msg = Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork->new({
        name => $name,
        network => $network,
        labels => $labels,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/odb_network.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork

Represents OdbNetwork resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the OdbNetwork resource in the following format:
projects/{project}/locations/{region}/odbNetworks/{odb_network}

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Required. Immutable. The name of the VPC network in the following format:
projects/{project}/global/networks/{network}

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork::LabelsEntry>)

Optional. Labels or tags associated with the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the OdbNetwork was created.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::State>)

Output only. State of the ODB Network.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. The ID of the subscription entitlement associated with the
OdbNetwork.

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Optional. Immutable. The GCP Oracle zone where OdbNetwork is hosted.
Example: us-east4-b-r2.
If not specified, the system will pick a zone based on availability.

=item * C<< $msg->service_connectivity_config() >> / C<< $msg->service_connectivity_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig>)

Optional. Configuration to enable the service (Oracledatabase@Google Cloud)
to establish connectivity to the database.

This should be specified if you intend to associate this OdbNetwork with a
DatabaseConnection resource to `ExecuteSQL` on the database, or to create a
ServiceIntegration with the Database.

Please don't specify it otherwise to avoid complicating the network setup.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. Indicates whether the OdbNetwork is currently reconciling
changes.

=back

=head3 Enum: OdbNetwork::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<TERMINATING> => C<3>

=item * C<FAILED> => C<4>

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::CreateOdbNetworkRequest

The request for `OdbNetwork.Create`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the OdbNetwork in the following format:
projects/{project}/locations/{location}.

=item * C<< $msg->odb_network_id() >> / C<< $msg->odb_network_id($value) >>

Type: C<String>

Required. The ID of the OdbNetwork to create. This value is restricted
to (^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$) and must be a maximum of 63
characters in length. The value must start with a letter and end with
a letter or a number.

=item * C<< $msg->odb_network() >> / C<< $msg->odb_network($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork>)

Required. Details of the OdbNetwork instance to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::DeleteOdbNetworkRequest

The request for `OdbNetwork.Delete`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::UpdateOdbNetworkRequest

The request for `OdbNetwork.Update`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the OdbNetwork should be
updated. A field specified in the mask is updated. If a mask isn't
provided, the service treats this as an implied field mask equivalent to
all fields that are populated (have a non-empty value). To clear or unset a
field, the field must be explicitly specified in the `update_mask`.

=item * C<< $msg->odb_network() >> / C<< $msg->odb_network($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork>)

Required. The resource being updated. Note only `labels` and
`service_connectivity_config` can be updated.
The provided labels will completely replace the existing labels.
Any existing label keys that are not included in the update request will be
deleted. Not providing labels and update_mask will not update the labels.
To clear all labels, specify `labels` in the `update_mask` and omit or
leave the `labels` field empty in the update request.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional ID to identify the request. This value is used to
identify duplicate requests. If you make a request with the same request ID
and the original request is still in progress or completed, the server
ignores the second request. This prevents clients from
accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksRequest

The request for `OdbNetwork.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the ODB Network in the following format:
projects/{project}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 ODB Networks will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression for ordering the results of the request.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::ListOdbNetworksResponse

The response for `OdbNetwork.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->odb_networks() >> / C<< $msg->odb_networks($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::OdbNetwork>)

The list of ODB Networks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::GetOdbNetworkRequest

The request for `OdbNetwork.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the OdbNetwork in the following format:
projects/{project}/locations/{location}/odbNetworks/{odb_network}.

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig

Configuration for a Private Service Connect (PSC) interface used by
Oracledatabase@Google Cloud to establish private connectivity to the
database.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network_attachment() >> / C<< $msg->network_attachment($value) >>

Type: C<String>

Optional. The resource name of the Network Attachment that
Oracledatabase@Google Cloud will use to establish private connectivity to
the database via a Private Service Connect Interface (PSC-I).
Format:
projects/{project}/regions/{region}/networkAttachments/{network_attachment}

=back

=head2 Google::Cloud::Oracledatabase::V1::OdbNetwork::ServiceConnectivityConfig

Configuration to enable the service (Oracledatabase@Google Cloud) to
establish connectivity to the database.

This should be specified if you intend to associate this OdbNetwork with a
DatabaseConnection resource to `ExecuteSQL` on the database, or to create a
ServiceIntegration with the Database.

Please don't specify it otherwise to avoid complicating the network setup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->psc_interface_config() >> / C<< $msg->psc_interface_config($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::OdbNetwork::PscInterfaceConfig>)

Optional. Configuration for Private Service Connect (PSC) interface.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::OdbNetwork::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
