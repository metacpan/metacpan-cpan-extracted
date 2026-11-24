package Google::Cloud::Financialservices::V1::PredictionResult;

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
    eval { require Google::Cloud::Financialservices::V1::BigqueryDestination };
    eval { require Google::Cloud::Financialservices::V1::LineOfBusiness };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvcHJlZGljdGlvbl9yZXN1bHQu
cHJvdG8SIWdvb2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo8Z29vZ2xl
L2Nsb3VkL2ZpbmFuY2lhbHNlcnZpY2VzL3YxL2JpZ3F1ZXJ5X2Rlc3RpbmF0aW9uLnByb3Rv
Gjhnb29nbGUvY2xvdWQvZmluYW5jaWFsc2VydmljZXMvdjEvbGluZV9vZl9idXNpbmVzcy5w
cm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8iwwoKEFByZWRpY3Rpb25SZXN1bHQSFwoEbmFtZRgBIAEoCUID
4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lElcKBmxhYmVscxgEIAMoCzI/Lmdv
b2dsZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5QcmVkaWN0aW9uUmVzdWx0LkxhYmVs
c0VudHJ5UgZsYWJlbHMSVAoFc3RhdGUYBSABKA4yOS5nb29nbGUuY2xvdWQuZmluYW5jaWFs
c2VydmljZXMudjEuUHJlZGljdGlvblJlc3VsdC5TdGF0ZUID4EEDUgVzdGF0ZRJKCgdkYXRh
c2V0GAYgASgJQjDgQQL6QSoKKGZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0Rh
dGFzZXRSB2RhdGFzZXQSRAoFbW9kZWwYByABKAlCLuBBAvpBKAomZmluYW5jaWFsc2Vydmlj
ZXMuZ29vZ2xlYXBpcy5jb20vTW9kZWxSBW1vZGVsEjoKCGVuZF90aW1lGAkgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EECUgdlbmRUaW1lEi0KEnByZWRpY3Rpb25fcGVy
aW9kcxgKIAEoBVIRcHJlZGljdGlvblBlcmlvZHMSWgoHb3V0cHV0cxgLIAEoCzI7Lmdvb2ds
ZS5jbG91ZC5maW5hbmNpYWxzZXJ2aWNlcy52MS5QcmVkaWN0aW9uUmVzdWx0Lk91dHB1dHNC
A+BBAlIHb3V0cHV0cxJgChBsaW5lX29mX2J1c2luZXNzGAwgASgOMjEuZ29vZ2xlLmNsb3Vk
LmZpbmFuY2lhbHNlcnZpY2VzLnYxLkxpbmVPZkJ1c2luZXNzQgPgQQNSDmxpbmVPZkJ1c2lu
ZXNzGvQBCgdPdXRwdXRzEnIKFnByZWRpY3Rpb25fZGVzdGluYXRpb24YASABKAsyNi5nb29n
bGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuQmlnUXVlcnlEZXN0aW5hdGlvbkID4EEC
UhVwcmVkaWN0aW9uRGVzdGluYXRpb24SdQoaZXhwbGFpbmFiaWxpdHlfZGVzdGluYXRpb24Y
AiABKAsyNi5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuQmlnUXVlcnlEZXN0
aW5hdGlvblIZZXhwbGFpbmFiaWxpdHlEZXN0aW5hdGlvbho5CgtMYWJlbHNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlQKBVN0YXRlEhUKEVNU
QVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIMCghVUERBVElO
RxADEgwKCERFTEVUSU5HEAQ6nwHqQZsBCjFmaW5hbmNpYWxzZXJ2aWNlcy5nb29nbGVhcGlz
LmNvbS9QcmVkaWN0aW9uUmVzdWx0EmZwcm9qZWN0cy97cHJvamVjdF9udW19L2xvY2F0aW9u
cy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L3ByZWRpY3Rpb25SZXN1bHRzL3tw
cmVkaWN0aW9uX3Jlc3VsdH0i2AEKHExpc3RQcmVkaWN0aW9uUmVzdWx0c1JlcXVlc3QSSQoG
cGFyZW50GAEgASgJQjHgQQL6QSsKKWZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29t
L0luc3RhbmNlUgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdl
X3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGQoIb3Jk
ZXJfYnkYBSABKAlSB29yZGVyQnkizQEKHUxpc3RQcmVkaWN0aW9uUmVzdWx0c1Jlc3BvbnNl
EmIKEnByZWRpY3Rpb25fcmVzdWx0cxgBIAMoCzIzLmdvb2dsZS5jbG91ZC5maW5hbmNpYWxz
ZXJ2aWNlcy52MS5QcmVkaWN0aW9uUmVzdWx0UhFwcmVkaWN0aW9uUmVzdWx0cxImCg9uZXh0
X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlS
C3VucmVhY2hhYmxlImsKGkdldFByZWRpY3Rpb25SZXN1bHRSZXF1ZXN0Ek0KBG5hbWUYASAB
KAlCOeBBAvpBMwoxZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vUHJlZGljdGlv
blJlc3VsdFIEbmFtZSKsAgodQ3JlYXRlUHJlZGljdGlvblJlc3VsdFJlcXVlc3QSSQoGcGFy
ZW50GAEgASgJQjHgQQL6QSsKKWZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL0lu
c3RhbmNlUgZwYXJlbnQSNQoUcHJlZGljdGlvbl9yZXN1bHRfaWQYAiABKAlCA+BBAlIScHJl
ZGljdGlvblJlc3VsdElkEmUKEXByZWRpY3Rpb25fcmVzdWx0GAMgASgLMjMuZ29vZ2xlLmNs
b3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxLlByZWRpY3Rpb25SZXN1bHRCA+BBAlIQcHJlZGlj
dGlvblJlc3VsdBIiCgpyZXF1ZXN0X2lkGAQgASgJQgPgQQFSCXJlcXVlc3RJZCLsAQodVXBk
YXRlUHJlZGljdGlvblJlc3VsdFJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29n
bGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSZQoRcHJlZGljdGlvbl9y
ZXN1bHQYAiABKAsyMy5nb29nbGUuY2xvdWQuZmluYW5jaWFsc2VydmljZXMudjEuUHJlZGlj
dGlvblJlc3VsdEID4EECUhBwcmVkaWN0aW9uUmVzdWx0EiIKCnJlcXVlc3RfaWQYAyABKAlC
A+BBAVIJcmVxdWVzdElkIpIBCh1EZWxldGVQcmVkaWN0aW9uUmVzdWx0UmVxdWVzdBJNCgRu
YW1lGAEgASgJQjngQQL6QTMKMWZpbmFuY2lhbHNlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1By
ZWRpY3Rpb25SZXN1bHRSBG5hbWUSIgoKcmVxdWVzdF9pZBgCIAEoCUID4EEBUglyZXF1ZXN0
SWQilQIKJUV4cG9ydFByZWRpY3Rpb25SZXN1bHRNZXRhZGF0YVJlcXVlc3QSZgoRcHJlZGlj
dGlvbl9yZXN1bHQYASABKAlCOeBBAvpBMwoxZmluYW5jaWFsc2VydmljZXMuZ29vZ2xlYXBp
cy5jb20vUHJlZGljdGlvblJlc3VsdFIQcHJlZGljdGlvblJlc3VsdBKDAQofc3RydWN0dXJl
ZF9tZXRhZGF0YV9kZXN0aW5hdGlvbhgCIAEoCzI2Lmdvb2dsZS5jbG91ZC5maW5hbmNpYWxz
ZXJ2aWNlcy52MS5CaWdRdWVyeURlc3RpbmF0aW9uQgPgQQJSHXN0cnVjdHVyZWRNZXRhZGF0
YURlc3RpbmF0aW9uIigKJkV4cG9ydFByZWRpY3Rpb25SZXN1bHRNZXRhZGF0YVJlc3BvbnNl
QoQCCiVjb20uZ29vZ2xlLmNsb3VkLmZpbmFuY2lhbHNlcnZpY2VzLnYxQhVQcmVkaWN0aW9u
UmVzdWx0UHJvdG9QAVpTY2xvdWQuZ29vZ2xlLmNvbS9nby9maW5hbmNpYWxzZXJ2aWNlcy9h
cGl2MS9maW5hbmNpYWxzZXJ2aWNlc3BiO2ZpbmFuY2lhbHNlcnZpY2VzcGKqAiFHb29nbGUu
Q2xvdWQuRmluYW5jaWFsU2VydmljZXMuVjHKAiFHb29nbGVcQ2xvdWRcRmluYW5jaWFsU2Vy
dmljZXNcVjHqAiRHb29nbGU6OkNsb3VkOjpGaW5hbmNpYWxTZXJ2aWNlczo6VjFKv1MKBxIF
DgCkAjEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoC
AwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAEYKCQoCAwMSAxUAQgoJCgIDBBIDFgAqCgkK
AgMFEgMXACkKCAoBCBIDGQA+CgkKAgglEgMZAD4KCAoBCBIDGgBqCgkKAggLEgMaAGoKCAoB
CBIDGwAiCgkKAggKEgMbACIKCAoBCBIDHAA2CgkKAggIEgMcADYKCAoBCBIDHQA+CgkKAggB
EgMdAD4KCAoBCBIDHgA+CgkKAggpEgMeAD4KCAoBCBIDHwA9CgkKAggtEgMfAD0KVQoCBAAS
BSIAgQEBGkggUHJlZGljdGlvblJlc3VsdCBpcyB0aGUgcmVzdWx0IG9mIHVzaW5nIGEgbW9k
ZWwgdG8gY3JlYXRlIHByZWRpY3Rpb25zLgoKCgoDBAABEgMiCBgKCwoDBAAHEgQjAiYECg0K
BQQAB50IEgQjAiYEClMKBAQAAwASBCkCMQMaRSBPdXRwdXRzIGlzIGEgbGlzdCBvZiBwbGFj
ZXMgd2hlcmUgdGhlIG9wZXJhdGlvbiB3aWxsIHdyaXRlIHJlc3VsdHMuCgoMCgUEAAMAARID
KQoRCkMKBgQAAwACABIEKwQsMRozIFJlcXVpcmVkLiBUaGUgbG9jYXRpb24gdG8gb3V0cHV0
IHRoZSBwcmVkaWN0aW9ucy4KCg4KBwQAAwACAAYSAysEFwoOCgcEAAMAAgABEgMrGC4KDgoH
BAADAAIAAxIDKzEyCg4KBwQAAwACAAgSAywIMAoRCgoEAAMAAgAInAgAEgMsCS8KfQoGBAAD
AAIBEgMwBDcabiBUaGUgbG9jYXRpb24gdG8gb3V0cHV0IGV4cGxhaW5hYmlsaXR5IGluZm9y
bWF0aW9uLiAgSWYgbm90IHNwZWNpZmllZAogbm8gZXhwbGFpbmFiaWxpdHkgZGF0YSB3aWxs
IGJlIG91dHB1dC4KCg4KBwQAAwACAQYSAzAEFwoOCgcEAAMAAgEBEgMwGDIKDgoHBAADAAIB
AxIDMDU2CjIKBAQABAASBDQCQwMaJCBUaGUgcG9zc2libGUgc3RhdGVzIG9mIGEgcmVzb3Vy
Y2UuCgoMCgUEAAQAARIDNAcMCjgKBgQABAACABIDNgQaGikgU3RhdGUgaXMgdW5zcGVjaWZp
ZWQsIHNob3VsZCBub3Qgb2NjdXIuCgoOCgcEAAQAAgABEgM2BBUKDgoHBAAEAAIAAhIDNhgZ
Cj0KBgQABAACARIDOQQRGi4gVGhlIHJlc291cmNlIGhhcyBub3QgZmluaXNoZWQgYmVpbmcg
Y3JlYXRlZC4KCg4KBwQABAACAQESAzkEDAoOCgcEAAQAAgECEgM5DxAKOQoGBAAEAAICEgM8
BA8aKiBUaGUgcmVzb3VyY2UgaXMgYWN0aXZlL3JlYWR5IHRvIGJlIHVzZWQuCgoOCgcEAAQA
AgIBEgM8BAoKDgoHBAAEAAICAhIDPA0OCkEKBgQABAACAxIDPwQRGjIgVGhlIHJlc291cmNl
IGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIHVwZGF0ZWQuCgoOCgcEAAQAAgMBEgM/BAwK
DgoHBAAEAAIDAhIDPw8QCkEKBgQABAACBBIDQgQRGjIgVGhlIHJlc291cmNlIGlzIGluIHRo
ZSBwcm9jZXNzIG9mIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgQBEgNCBAwKDgoHBAAEAAIE
AhIDQg8QCrsBCgQEAAIAEgNIAj4arQEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBQcmVkaWN0aW9uUmVzdWx0LgogZm9ybWF0OgogYC9wcm9qZWN0cy97cHJvamVj
dF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L3ByZWRp
Y3Rpb25SZXN1bHRzL3twcmVkaWN0aW9uX3Jlc3VsdH1gCgoMCgUEAAIABRIDSAIICgwKBQQA
AgABEgNICQ0KDAoFBAACAAMSA0gQEQoMCgUEAAIACBIDSBI9Cg8KCAQAAgAInAgAEgNIEzwK
SAoEBAACARIESwJMMho6IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIG9mIGNyZWF0aW9u
IG9mIHRoaXMgcmVzb3VyY2UuCgoMCgUEAAIBBhIDSwIbCgwKBQQAAgEBEgNLHCcKDAoFBAAC
AQMSA0sqKwoMCgUEAAIBCBIDTAYxCg8KCAQAAgEInAgAEgNMBzAKVgoEBAACAhIETwJQMhpI
IE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIG9mIHRoZSBtb3N0IHJlY2VudCB1cGRhdGUg
b2YgdGhpcyByZXNvdXJjZS4KCgwKBQQAAgIGEgNPAhsKDAoFBAACAgESA08cJwoMCgUEAAIC
AxIDTyorCgwKBQQAAgIIEgNQBjEKDwoIBAACAgicCAASA1AHMAoVCgQEAAIDEgNTAiEaCCBM
YWJlbHMKCgwKBQQAAgMGEgNTAhUKDAoFBAACAwESA1MWHAoMCgUEAAIDAxIDUx8gCl0KBAQA
AgQSA1cCPhpQIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgUHJlZGljdGlvblJlc3VsdCAo
Y3JlYXRpbmcsIGFjdGl2ZSwgZGVsZXRpbmcsCiBldGMuKQoKDAoFBAACBAYSA1cCBwoMCgUE
AAIEARIDVwgNCgwKBQQAAgQDEgNXEBEKDAoFBAACBAgSA1cSPQoPCggEAAIECJwIABIDVxM8
CrMBCgQEAAIFEgRcAmEEGqQBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
RGF0YXNldCB0byBkbyBwcmVkaWN0aW9ucyBvbgogRm9ybWF0OgogYC9wcm9qZWN0cy97cHJv
amVjdF9udW19L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2Rh
dGFzZXQve2RhdGFzZXRfaWR9YAoKDAoFBAACBQUSA1wCCAoMCgUEAAIFARIDXAkQCgwKBQQA
AgUDEgNcExQKDQoFBAACBQgSBFwVYQMKDwoIBAACBQicCAASA10EKgoPCgcEAAIFCJ8IEgRe
BGAFCrgBCgQEAAIGEgRmAmsEGqkBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgTW9kZWwgdG8gdXNlIHRvIHVzZSB0byBtYWtlIHByZWRpY3Rpb25zCiBGb3JtYXQ6CiBg
L3Byb2plY3RzL3twcm9qZWN0X251bX0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2Vz
L3tpbnN0YW5jZX0vbW9kZWxzL3ttb2RlbH1gCgoMCgUEAAIGBRIDZgIICgwKBQQAAgYBEgNm
CQ4KDAoFBAACBgMSA2YREgoNCgUEAAIGCBIEZhNrAwoPCggEAAIGCJwIABIDZwQqCg8KBwQA
AgYInwgSBGgEagUK+gEKBAQAAgcSBHECci8a6wEgUmVxdWlyZWQuIFNwZWNpZmllcyB0aGUg
bGF0ZXN0IHRpbWUgZnJvbSB3aGljaCBkYXRhIGlzIHVzZWQgdG8gZ2VuZXJhdGUKIGZlYXR1
cmVzIGZvciBwcmVkaWN0aW9ucy4gIFRoaXMgdGltZSBzaG91bGQgYmUgbm8gbGF0ZXIgdGhh
biB0aGUgZW5kIG9mIHRoZQogW2RhdGVfcmFuZ2VdW2dvb2dsZS5jbG91ZC5maW5hbmNpYWxz
ZXJ2aWNlcy52MS5EYXRhc2V0LmRhdGVfcmFuZ2VdIG9mIHRoZQogZGF0YXNldC4KCgwKBQQA
AgcGEgNxAhsKDAoFBAACBwESA3EcJAoMCgUEAAIHAxIDcScoCgwKBQQAAgcIEgNyBi4KDwoI
BAACBwicCAASA3IHLQrlAQoEBAACCBIDeAIgGtcBIFRoZSBudW1iZXIgb2YgY29uc2VjdXRp
dmUgbW9udGhzIHRvIHByb2R1Y2UgcHJlZGljdGlvbnMgZm9yLCBlbmRpbmcgd2l0aAogdGhl
IGxhc3QgZnVsbCBtb250aCBwcmlvciB0bwogW2VuZF90aW1lXVtnb29nbGUuY2xvdWQuZmlu
YW5jaWFsc2VydmljZXMudjEuUHJlZGljdGlvblJlc3VsdC5lbmRfdGltZV0KIGFjY29yZGlu
ZyB0byB0aGUgZGF0YXNldCdzIHRpbWV6b25lLgoKDAoFBAACCAUSA3gCBwoMCgUEAAIIARID
eAgaCgwKBQQAAggDEgN4HR8KRgoEBAACCRIDewJAGjkgUmVxdWlyZWQuIFdoZXJlIHRvIHdy
aXRlIHRoZSBvdXRwdXQgb2YgdGhlIHByZWRpY3Rpb25zLgoKDAoFBAACCQYSA3sCCQoMCgUE
AAIJARIDewoRCgwKBQQAAgkDEgN7FBYKDAoFBAACCQgSA3sXPwoPCggEAAIJCJwIABIDexg+
CosBCgQEAAIKEgV/AoABMhp8IE91dHB1dCBvbmx5LiBUaGUgbGluZSBvZiBidXNpbmVzcyAo
UmV0YWlsL0NvbW1lcmNpYWwpIHRoaXMgcHJlZGljdGlvbiBpcwogZm9yLiBEZXRlcm1pbmVk
IGJ5IE1vZGVsLCBjYW5ub3QgYmUgc2V0IGJ5IHVzZXIuCgoMCgUEAAIKBhIDfwIQCgwKBQQA
AgoBEgN/ESEKDAoFBAACCgMSA38kJgoNCgUEAAIKCBIEgAEGMQoQCggEAAIKCJwIABIEgAEH
MAp4CgIEARIGhQEAnwEBGmogUmVxdWVzdCBmb3IgcmV0cmlldmluZyBhIHBhZ2luYXRlZCBs
aXN0IG9mIFByZWRpY3Rpb25SZXN1bHQgcmVzb3VyY2VzIHRoYXQKIG1lZXQgdGhlIHNwZWNp
ZmllZCBjcml0ZXJpYS4KCgsKAwQBARIEhQEIJApPCgQEAQIAEgaHAQKMAQQaPyBSZXF1aXJl
ZC4gVGhlIHBhcmVudCBvZiB0aGUgUHJlZGljdGlvblJlc3VsdCBpcyB0aGUgSW5zdGFuY2Uu
CgoNCgUEAQIABRIEhwECCAoNCgUEAQIAARIEhwEJDwoNCgUEAQIAAxIEhwESEwoPCgUEAQIA
CBIGhwEUjAEDChAKCAQBAgAInAgAEgSIAQQqChEKBwQBAgAInwgSBokBBIsBBQqtAQoEBAEC
ARIEkQECFhqeASBUaGUgbnVtYmVyIG9mIHJlc291cmNlcyB0byBiZSBpbmNsdWRlZCBpbiB0
aGUgcmVzcG9uc2UuIFRoZSByZXNwb25zZQogY29udGFpbnMgYSBuZXh0X3BhZ2VfdG9rZW4s
IHdoaWNoIGNhbiBiZSB1c2VkIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Ugb2YKIHJlc291
cmNlcy4KCg0KBQQBAgEFEgSRAQIHCg0KBQQBAgEBEgSRAQgRCg0KBQQBAgEDEgSRARQVCrkC
CgQEAQICEgSYAQIYGqoCIEluIGNhc2Ugb2YgcGFnaW5hdGVkIHJlc3VsdHMsIHRoaXMgaXMg
dGhlIHRva2VuIHRoYXQgd2FzIHJldHVybmVkIGluIHRoZQogcHJldmlvdXMgTGlzdFByZWRp
Y3Rpb25SZXN1bHRzUmVzcG9uc2UuIEl0IHNob3VsZCBiZSBjb3BpZWQgaGVyZSB0bwogcmV0
cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXNvdXJjZXMuIEVtcHR5IHdpbGwgZ2l2ZSB0aGUg
Zmlyc3QgcGFnZSBvZgogTGlzdFByZWRpY3Rpb25SZXN1bHRzUmVxdWVzdCwgYW5kIHRoZSBs
YXN0IHBhZ2Ugd2lsbCByZXR1cm4gYW4gZW1wdHkKIHBhZ2VfdG9rZW4uCgoNCgUEAQICBRIE
mAECCAoNCgUEAQICARIEmAEJEwoNCgUEAQICAxIEmAEWFwo6CgQEAQIDEgSbAQIUGiwgU3Bl
Y2lmeSBhIGZpbHRlciB0byBuYXJyb3cgc2VhcmNoIHJlc3VsdHMuCgoNCgUEAQIDBRIEmwEC
CAoNCgUEAQIDARIEmwEJDwoNCgUEAQIDAxIEmwESEwo0CgQEAQIEEgSeAQIWGiYgU3BlY2lm
eSBhIGZpZWxkIHRvIHVzZSBmb3Igb3JkZXJpbmcuCgoNCgUEAQIEBRIEngECCAoNCgUEAQIE
ARIEngEJEQoNCgUEAQIEAxIEngEUFQpDCgIEAhIGogEArQEBGjUgUmVzcG9uc2UgZm9yIHJl
dHJpZXZpbmcgYSBsaXN0IG9mIFByZWRpY3Rpb25SZXN1bHRzCgoLCgMEAgESBKIBCCUKMgoE
BAICABIEpAECMxokIExpc3Qgb2YgUHJlZGljdGlvblJlc3VsdCByZXNvdXJjZXMKCg0KBQQC
AgAEEgSkAQIKCg0KBQQCAgAGEgSkAQsbCg0KBQQCAgABEgSkARwuCg0KBQQCAgADEgSkATEy
CqcBCgQEAgIBEgSpAQIdGpgBIFRoaXMgdG9rZW4gc2hvdWxkIGJlIHBhc3NlZCB0byB0aGUg
bmV4dCBMaXN0UHJlZGljdGlvblJlc3VsdHNSZXF1ZXN0IHRvCiByZXRyaWV2ZSB0aGUgbmV4
dCBwYWdlIG9mIFByZWRpY3Rpb25SZXN1bHRzIChlbXB0eSBpbmRpY2ljYXRlcyB3ZSBhcmUK
IGRvbmUpLgoKDQoFBAICAQUSBKkBAggKDQoFBAICAQESBKkBCRgKDQoFBAICAQMSBKkBGxwK
NAoEBAICAhIErAECIhomIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoK
DQoFBAICAgQSBKwBAgoKDQoFBAICAgUSBKwBCxEKDQoFBAICAgESBKwBEh0KDQoFBAICAgMS
BKwBICEKTAoCBAMSBrABALgBARo+IFJlcXVlc3QgZm9yIHJldHJpZXZpbmcgYSBzcGVjaWZp
YyBQcmVkaWN0aW9uUmVzdWx0IHJlc291cmNlLgoKCwoDBAMBEgSwAQgiCkUKBAQDAgASBrIB
ArcBBBo1IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgUHJlZGljdGlvblJl
c3VsdAoKDQoFBAMCAAUSBLIBAggKDQoFBAMCAAESBLIBCQ0KDQoFBAMCAAMSBLIBEBEKDwoF
BAMCAAgSBrIBErcBAwoQCggEAwIACJwIABIEswEEKgoRCgcEAwIACJ8IEga0AQS2AQUKQQoC
BAQSBrsBANkBARozIFJlcXVlc3QgZm9yIGNyZWF0aW5nIGEgUHJlZGljdGlvblJlc3VsdCBy
ZXNvdXJjZS4KCgsKAwQEARIEuwEIJQpPCgQEBAIAEga9AQLCAQQaPyBSZXF1aXJlZC4gVGhl
IHBhcmVudCBvZiB0aGUgUHJlZGljdGlvblJlc3VsdCBpcyB0aGUgSW5zdGFuY2UuCgoNCgUE
BAIABRIEvQECCAoNCgUEBAIAARIEvQEJDwoNCgUEBAIAAxIEvQESEwoPCgUEBAIACBIGvQEU
wgEDChAKCAQEAgAInAgAEgS+AQQqChEKBwQEAgAInwgSBr8BBMEBBQpBCgQEBAIBEgTFAQJL
GjMgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBpZCBvZiB0aGUgUHJlZGljdGlvblJlc3VsdAoK
DQoFBAQCAQUSBMUBAggKDQoFBAQCAQESBMUBCR0KDQoFBAQCAQMSBMUBICEKDQoFBAQCAQgS
BMUBIkoKEAoIBAQCAQicCAASBMUBI0kKRgoEBAQCAhIGyAECyQEvGjYgUmVxdWlyZWQuIFRo
ZSBQcmVkaWN0aW9uUmVzdWx0IHRoYXQgd2lsbCBiZSBjcmVhdGVkLgoKDQoFBAQCAgYSBMgB
AhIKDQoFBAQCAgESBMgBEyQKDQoFBAQCAgMSBMgBJygKDQoFBAQCAggSBMkBBi4KEAoIBAQC
AgicCAASBMkBBy0KjwYKBAQEAgMSBNgBAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJl
cXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVl
c3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2
ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkg
YmVlbiBjb21wbGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0
IGxlYXN0IDYwIG1pbnV0ZXMgc2luY2UgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1w
bGUsIGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVx
dWVzdCBhbmQgdGhlCiByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVl
c3QgYWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hl
Y2sgaWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2Fz
IHJlY2VpdmVkLCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4g
VGhpcyBwcmV2ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBs
aWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVV
SUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVk
ICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAQCAwUSBNgB
AggKDQoFBAQCAwESBNgBCRMKDQoFBAQCAwMSBNgBFhcKDQoFBAQCAwgSBNgBGEAKEAoIBAQC
AwicCAASBNgBGT8KNwoCBAUSBtwBAPgBARopIFJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgUHJl
ZGljdGlvblJlc3VsdAoKCwoDBAUBEgTcAQglCuICCgQEBQIAEgbiAQLjAS8a0QIgT3B0aW9u
YWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3Zl
cndyaXR0ZW4gaW4gdGhlCiBQcmVkaWN0aW9uUmVzdWx0IHJlc291cmNlIGJ5IHRoZSB1cGRh
dGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0
aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdp
bGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhlIG1hc2suIElmIHRoZQogdXNlciBk
b2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBmaWVsZHMgd2lsbCBiZSBvdmVyd3Jp
dHRlbi4KCg0KBQQFAgAGEgTiAQIbCg0KBQQFAgABEgTiARwnCg0KBQQFAgADEgTiASorCg0K
BQQFAgAIEgTjAQYuChAKCAQFAgAInAgAEgTjAQctCnwKBAQFAgESBucBAugBLxpsIFJlcXVp
cmVkLiBUaGUgbmV3IHZhbHVlIG9mIHRoZSBQcmVkaWN0aW9uUmVzdWx0IGZpZWxkcyB0aGF0
IHdpbGwgYmUgdXBkYXRlZAogYWNjb3JkaW5nIHRvIHRoZSB1cGRhdGVfbWFzay4KCg0KBQQF
AgEGEgTnAQISCg0KBQQFAgEBEgTnARMkCg0KBQQFAgEDEgTnAScoCg0KBQQFAgEIEgToAQYu
ChAKCAQFAgEInAgAEgToAQctCo8GCgQEBQICEgT3AQJBGoAGIE9wdGlvbmFsLiBBbiBvcHRp
b25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVl
CiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0
aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBh
bHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1YXJhbnRlZSB0aGF0
IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0LgoKIEZv
ciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0
aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRo
ZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBzZXJ2ZXIg
Y2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3Qg
SUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0aGUgc2Vjb25kIHJl
cXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVudGFsbHkgY3JlYXRp
bmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2
YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1
cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQF
AgIFEgT3AQIICg0KBQQFAgIBEgT3AQkTCg0KBQQFAgIDEgT3ARYXCg0KBQQFAgIIEgT3ARhA
ChAKCAQFAgIInAgAEgT3ARk/CjgKAgQGEgb7AQCSAgEaKiBSZXF1ZXN0IGZvciBkZWxldGlu
ZyBhIFByZWRpY3Rpb25SZXN1bHQuCgoLCgMEBgESBPsBCCUKRgoEBAYCABIG/QECggIEGjYg
UmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBQcmVkaWN0aW9uUmVzdWx0LgoK
DQoFBAYCAAUSBP0BAggKDQoFBAYCAAESBP0BCQ0KDQoFBAYCAAMSBP0BEBEKDwoFBAYCAAgS
Bv0BEoICAwoQCggEBgIACJwIABIE/gEEKgoRCgcEBgIACJ8IEgb/AQSBAgUKjwYKBAQGAgES
BJECAkEagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkg
cmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3Ug
bXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25v
cmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuIFRoZSBz
ZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYwIG1pbnV0ZXMgYWZ0
ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNpZGVyIGEgc2l0dWF0
aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQgdGhlCiByZXF1ZXN0
IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4gd2l0aCB0aGUgc2Ft
ZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3JpZ2luYWwgb3BlcmF0
aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVkLCBhbmQgaWYgc28s
IHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50cwogY2xpZW50
cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgog
VGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9u
IHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAt
MDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAYCAQUSBJECAggKDQoFBAYCAQESBJECCRMKDQoF
BAYCAQMSBJECFhcKDQoFBAYCAQgSBJECGEAKEAoIBAYCAQicCAASBJECGT8KQAoCBAcSBpUC
AKECARoyIFJlcXVlc3QgZm9yIGV4cG9ydGluZyBQcmVkaWN0aW9uUmVzdWx0IG1ldGFkYXRh
LgoKCwoDBAcBEgSVAggtCkYKBAQHAgASBpcCApwCBBo2IFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgUHJlZGljdGlvblJlc3VsdC4KCg0KBQQHAgAFEgSXAgIICg0KBQQH
AgABEgSXAgkaCg0KBQQHAgADEgSXAh0eCg8KBQQHAgAIEgaXAh+cAgMKEAoIBAcCAAicCAAS
BJgCBCoKEQoHBAcCAAifCBIGmQIEmwIFCk8KBAQHAgESBp8CAqACLxo/IFJlcXVpcmVkLiBC
aWdRdWVyeSBvdXRwdXQgd2hlcmUgdGhlIG1ldGFkYXRhIHdpbGwgYmUgd3JpdHRlbi4KCg0K
BQQHAgEGEgSfAgIVCg0KBQQHAgEBEgSfAhY1Cg0KBQQHAgEDEgSfAjg5Cg0KBQQHAgEIEgSg
AgYuChAKCAQHAgEInAgAEgSgAgctCj8KAgQIEgSkAgAxGjMgUmVzcG9uc2UgZm9yIGV4cG9y
dGluZyBQcmVkaWN0aW9uUmVzdWx0IG1ldGFkYXRhLgoKCwoDBAgBEgSkAgguYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult ===
    # Fields for PredictionResult
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.financialservices.v1.PredictionResult.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.financialservices.v1.PredictionResult.State)
    # Field: dataset Type: 9 ()
    # Field: model Type: 9 ()
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: prediction_periods Type: 5 ()
    # Field: outputs Type: 11 (.google.cloud.financialservices.v1.PredictionResult.Outputs)
    # Field: line_of_business Type: 14 (.google.cloud.financialservices.v1.LineOfBusiness)

# Enum: PredictionResult::State
our $PredictionResult_STATE_UNSPECIFIED = 0;
our $PredictionResult_CREATING = 1;
our $PredictionResult_ACTIVE = 2;
our $PredictionResult_UPDATING = 3;
our $PredictionResult_DELETING = 4;

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest ===
    # Fields for ListPredictionResultsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse ===
    # Fields for ListPredictionResultsResponse
    # Field: prediction_results Type: 11 (.google.cloud.financialservices.v1.PredictionResult)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest ===
    # Fields for GetPredictionResultRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest ===
    # Fields for CreatePredictionResultRequest
    # Field: parent Type: 9 ()
    # Field: prediction_result_id Type: 9 ()
    # Field: prediction_result Type: 11 (.google.cloud.financialservices.v1.PredictionResult)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest ===
    # Fields for UpdatePredictionResultRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: prediction_result Type: 11 (.google.cloud.financialservices.v1.PredictionResult)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest ===
    # Fields for DeletePredictionResultRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest ===
    # Fields for ExportPredictionResultMetadataRequest
    # Field: prediction_result Type: 9 ()
    # Field: structured_metadata_destination Type: 11 (.google.cloud.financialservices.v1.BigQueryDestination)

# === Message: Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataResponse ===
    # Fields for ExportPredictionResultMetadataResponse

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Financialservices::V1::PredictionResult - Compiled Protocol Buffers messages for google/cloud/financialservices/v1/prediction_result.proto

=head1 SYNOPSIS

    use Google::Cloud::Financialservices::V1::PredictionResult;

    my $msg = Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/financialservices/v1/prediction_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult

PredictionResult is the result of using a model to create predictions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the PredictionResult.
format:
`/projects/{project_num}/locations/{location}/instances/{instance}/predictionResults/{prediction_result}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of creation of this resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of the most recent update of this resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::LabelsEntry>)

Labels

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::PredictionResult::State>)

Output only. State of the PredictionResult (creating, active, deleting,
etc.)

=item * C<< $msg->dataset() >> / C<< $msg->dataset($value) >>

Type: C<String>

Required. The resource name of the Dataset to do predictions on
Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/dataset/{dataset_id}`

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The resource name of the Model to use to use to make predictions
Format:
`/projects/{project_num}/locations/{location}/instances/{instance}/models/{model}`

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Specifies the latest time from which data is used to generate
features for predictions.  This time should be no later than the end of the
[date_range][google.cloud.financialservices.v1.Dataset.date_range] of the
dataset.

=item * C<< $msg->prediction_periods() >> / C<< $msg->prediction_periods($value) >>

Type: C<Int32>

The number of consecutive months to produce predictions for, ending with
the last full month prior to
[end_time][google.cloud.financialservices.v1.PredictionResult.end_time]
according to the dataset's timezone.

=item * C<< $msg->outputs() >> / C<< $msg->outputs($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::Outputs>)

Required. Where to write the output of the predictions.

=item * C<< $msg->line_of_business() >> / C<< $msg->line_of_business($value) >>

Type: C<Enum> (L<Google::Cloud::Financialservices::V1::LineOfBusiness>)

Output only. The line of business (Retail/Commercial) this prediction is
for. Determined by Model, cannot be set by user.

=back

=head3 Enum: PredictionResult::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest

Request for retrieving a paginated list of PredictionResult resources that
meet the specified criteria.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the PredictionResult is the Instance.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The number of resources to be included in the response. The response
contains a next_page_token, which can be used to retrieve the next page of
resources.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

In case of paginated results, this is the token that was returned in the
previous ListPredictionResultsResponse. It should be copied here to
retrieve the next page of resources. Empty will give the first page of
ListPredictionResultsRequest, and the last page will return an empty
page_token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Specify a filter to narrow search results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Specify a field to use for ordering.

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse

Response for retrieving a list of PredictionResults

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->prediction_results() >> / C<< $msg->prediction_results($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult>)

List of PredictionResult resources

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

This token should be passed to the next ListPredictionResultsRequest to
retrieve the next page of PredictionResults (empty indicicates we are
done).

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest

Request for retrieving a specific PredictionResult resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the PredictionResult

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest

Request for creating a PredictionResult resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent of the PredictionResult is the Instance.

=item * C<< $msg->prediction_result_id() >> / C<< $msg->prediction_result_id($value) >>

Type: C<String>

Required. The resource id of the PredictionResult

=item * C<< $msg->prediction_result() >> / C<< $msg->prediction_result($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult>)

Required. The PredictionResult that will be created.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest

Request for updating a PredictionResult

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
PredictionResult resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->prediction_result() >> / C<< $msg->prediction_result($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult>)

Required. The new value of the PredictionResult fields that will be updated
according to the update_mask.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest

Request for deleting a PredictionResult.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the PredictionResult.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest

Request for exporting PredictionResult metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->prediction_result() >> / C<< $msg->prediction_result($value) >>

Type: C<String>

Required. The resource name of the PredictionResult.

=item * C<< $msg->structured_metadata_destination() >> / C<< $msg->structured_metadata_destination($value) >>

Type: C<Message> (L<Google::Cloud::Financialservices::V1::BigqueryDestination::BigQueryDestination>)

Required. BigQuery output where the metadata will be written.

=back

=head2 Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataResponse

Response for exporting PredictionResult metadata.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Financialservices::V1::PredictionResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
