package Google::Ai::Generativelanguage::V1beta3::TunedModel;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvdHVuZWRfbW9kZWwucHJv
dG8SJGdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMxofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKtBwoKVHVuZWRNb2RlbBJrChJ0dW5lZF9tb2Rl
bF9zb3VyY2UYAyABKAsyNi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMu
VHVuZWRNb2RlbFNvdXJjZUID4EEBSABSEHR1bmVkTW9kZWxTb3VyY2USUAoKYmFzZV9tb2Rl
bBgEIAEoCUIv4EEF+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9k
ZWxIAFIJYmFzZU1vZGVsEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRImCgxkaXNwbGF5X25h
bWUYBSABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YBiABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SKgoLdGVtcGVyYXR1cmUYCyABKAJCA+BBAUgBUgt0ZW1wZXJhdHVyZYgB
ARIdCgV0b3BfcBgMIAEoAkID4EEBSAJSBHRvcFCIAQESHQoFdG9wX2sYDSABKAVCA+BBAUgD
UgR0b3BLiAEBElEKBXN0YXRlGAcgASgOMjYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWJldGEzLlR1bmVkTW9kZWwuU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUY
CCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSVgoLdHVuaW5nX3Rhc2sYCiABKAsyMC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYmV0YTMuVHVuaW5nVGFza0ID4EECUgp0dW5pbmdUYXNrIkQKBVN0YXRlEhUK
EVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIKCgZGQUlM
RUQQAzpl6kFiCixnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vVHVuZWRNb2Rl
bBIZdHVuZWRNb2RlbHMve3R1bmVkX21vZGVsfSoLdHVuZWRNb2RlbHMyCnR1bmVkTW9kZWxC
DgoMc291cmNlX21vZGVsQg4KDF90ZW1wZXJhdHVyZUIICgZfdG9wX3BCCAoGX3RvcF9rIrkB
ChBUdW5lZE1vZGVsU291cmNlElUKC3R1bmVkX21vZGVsGAEgASgJQjTgQQX6QS4KLGdlbmVy
YXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9UdW5lZE1vZGVsUgp0dW5lZE1vZGVsEk4K
CmJhc2VfbW9kZWwYAiABKAlCL+BBA/pBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFw
aXMuY29tL01vZGVsUgliYXNlTW9kZWwisAMKClR1bmluZ1Rhc2sSPgoKc3RhcnRfdGltZRgB
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IJc3RhcnRUaW1lEkQKDWNv
bXBsZXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDGNv
bXBsZXRlVGltZRJXCglzbmFwc2hvdHMYAyADKAsyNC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYmV0YTMuVHVuaW5nU25hcHNob3RCA+BBA1IJc25hcHNob3RzEl0KDXRyYWlu
aW5nX2RhdGEYBCABKAsyLS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMu
RGF0YXNldEIJ4EEE4EEC4EEFUgx0cmFpbmluZ0RhdGESZAoPaHlwZXJwYXJhbWV0ZXJzGAUg
ASgLMjUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkh5cGVycGFyYW1l
dGVyc0ID4EEFUg9oeXBlcnBhcmFtZXRlcnMixQEKD0h5cGVycGFyYW1ldGVycxIpCgtlcG9j
aF9jb3VudBgOIAEoBUID4EEFSABSCmVwb2NoQ291bnSIAQESJwoKYmF0Y2hfc2l6ZRgPIAEo
BUID4EEFSAFSCWJhdGNoU2l6ZYgBARItCg1sZWFybmluZ19yYXRlGBAgASgCQgPgQQVIAlIM
bGVhcm5pbmdSYXRliAEBQg4KDF9lcG9jaF9jb3VudEINCgtfYmF0Y2hfc2l6ZUIQCg5fbGVh
cm5pbmdfcmF0ZSJtCgdEYXRhc2V0ElcKCGV4YW1wbGVzGAEgASgLMjQuZ29vZ2xlLmFpLmdl
bmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlR1bmluZ0V4YW1wbGVzQgPgQQFIAFIIZXhhbXBs
ZXNCCQoHZGF0YXNldCJmCg5UdW5pbmdFeGFtcGxlcxJUCghleGFtcGxlcxgBIAMoCzIzLmdv
b2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5UdW5pbmdFeGFtcGxlQgPgQQJS
CGV4YW1wbGVzImEKDVR1bmluZ0V4YW1wbGUSJAoKdGV4dF9pbnB1dBgBIAEoCUID4EEBSABS
CXRleHRJbnB1dBIbCgZvdXRwdXQYAyABKAlCA+BBAlIGb3V0cHV0Qg0KC21vZGVsX2lucHV0
IqoBCg5UdW5pbmdTbmFwc2hvdBIXCgRzdGVwGAEgASgFQgPgQQNSBHN0ZXASGQoFZXBvY2gY
AiABKAVCA+BBA1IFZXBvY2gSIAoJbWVhbl9sb3NzGAMgASgCQgPgQQNSCG1lYW5Mb3NzEkIK
DGNvbXB1dGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IL
Y29tcHV0ZVRpbWVCnQEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0
YTNCD1R1bmVkTW9kZWxQcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRp
dmVsYW5ndWFnZS9hcGl2MWJldGEzL2dlbmVyYXRpdmVsYW5ndWFnZXBiO2dlbmVyYXRpdmVs
YW5ndWFnZXBiSqVACgcSBQ4A6wEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAtCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYA
dQoJCgIICxIDFgB1CggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMAoJCgIICBIDGAAw
CggKAQgSAxkAQQoJCgIIARIDGQBBCk0KAgQAEgQcAH4BGkEgQSBmaW5lLXR1bmVkIG1vZGVs
IGNyZWF0ZWQgdXNpbmcgTW9kZWxTZXJ2aWNlLkNyZWF0ZVR1bmVkTW9kZWwuCgoKCgMEAAES
AxwIEgoLCgMEAAcSBB0CIgQKDQoFBAAHnQgSBB0CIgQKLQoEBAAEABIEJQIxAxofIFRoZSBz
dGF0ZSBvZiB0aGUgdHVuZWQgbW9kZWwuCgoMCgUEAAQAARIDJQcMCjkKBgQABAACABIDJwQa
GiogVGhlIGRlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAAEAAIA
ARIDJwQVCg4KBwQABAACAAISAycYGQosCgYEAAQAAgESAyoEERodIFRoZSBtb2RlbCBpcyBi
ZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDKgQMCg4KBwQABAACAQISAyoPEAovCgYEAAQA
AgISAy0EDxogIFRoZSBtb2RlbCBpcyByZWFkeSB0byBiZSB1c2VkLgoKDgoHBAAEAAICARID
LQQKCg4KBwQABAACAgISAy0NDgowCgYEAAQAAgMSAzAEDxohIFRoZSBtb2RlbCBmYWlsZWQg
dG8gYmUgY3JlYXRlZC4KCg4KBwQABAACAwESAzAECgoOCgcEAAQAAgMCEgMwDQ4KQAoEBAAI
ABIENAJCAxoyIFRoZSBtb2RlbCB1c2VkIGFzIHRoZSBzdGFydGluZyBwb2ludCBmb3IgdHVu
aW5nLgoKDAoFBAAIAAESAzQIFApeCgQEAAIAEgQ3BDgxGlAgT3B0aW9uYWwuIFR1bmVkTW9k
ZWwgdG8gdXNlIGFzIHRoZSBzdGFydGluZyBwb2ludCBmb3IgdHJhaW5pbmcgdGhlIG5ldwog
bW9kZWwuCgoMCgUEAAIABhIDNwQUCgwKBQQAAgABEgM3FScKDAoFBAACAAMSAzcqKwoMCgUE
AAIACBIDOAgwCg8KCAQAAgAInAgAEgM4CS8KXQoEBAACARIEPARBBhpPIEltbXV0YWJsZS4g
VGhlIG5hbWUgb2YgdGhlIGBNb2RlbGAgdG8gdHVuZS4KIEV4YW1wbGU6IGBtb2RlbHMvdGV4
dC1iaXNvbi0wMDFgCgoMCgUEAAIBBRIDPAQKCgwKBQQAAgEBEgM8CxUKDAoFBAACAQMSAzwY
GQoNCgUEAAIBCBIEPBpBBQoPCggEAAIBCJwIABIDPQYtCg8KBwQAAgEInwgSBD4GQAcKnAMK
BAQAAgISA0sCPhqOAyBPdXRwdXQgb25seS4gVGhlIHR1bmVkIG1vZGVsIG5hbWUuIEEgdW5p
cXVlIG5hbWUgd2lsbCBiZSBnZW5lcmF0ZWQgb24KIGNyZWF0ZS4gRXhhbXBsZTogYHR1bmVk
TW9kZWxzL2F6Mm1iMGJwdzZpYCBJZiBkaXNwbGF5X25hbWUgaXMgc2V0IG9uCiBjcmVhdGUs
IHRoZSBpZCBwb3J0aW9uIG9mIHRoZSBuYW1lIHdpbGwgYmUgc2V0IGJ5IGNvbmNhdGVuYXRp
bmcgdGhlIHdvcmRzCiBvZiB0aGUgZGlzcGxheV9uYW1lIHdpdGggaHlwaGVucyBhbmQgYWRk
aW5nIGEgcmFuZG9tIHBvcnRpb24gZm9yCiB1bmlxdWVuZXNzLiBFeGFtcGxlOgogICAgIGRp
c3BsYXlfbmFtZSA9ICJTZW50ZW5jZSBUcmFuc2xhdG9yIgogICAgIG5hbWUgPSAidHVuZWRN
b2RlbHMvc2VudGVuY2UtdHJhbnNsYXRvci11M2I3bSIKCgwKBQQAAgIFEgNLAggKDAoFBAAC
AgESA0sJDQoMCgUEAAICAxIDSxARCgwKBQQAAgIIEgNLEj0KDwoIBAACAgicCAASA0sTPAqQ
AQoEBAACAxIDTwJDGoIBIE9wdGlvbmFsLiBUaGUgbmFtZSB0byBkaXNwbGF5IGZvciB0aGlz
IG1vZGVsIGluIHVzZXIgaW50ZXJmYWNlcy4KIFRoZSBkaXNwbGF5IG5hbWUgbXVzdCBiZSB1
cCB0byA0MCBjaGFyYWN0ZXJzIGluY2x1ZGluZyBzcGFjZXMuCgoMCgUEAAIDBRIDTwIICgwK
BQQAAgMBEgNPCRUKDAoFBAACAwMSA08YGQoMCgUEAAIDCBIDTxpCCg8KCAQAAgMInAgAEgNP
G0EKOwoEBAACBBIDUgJCGi4gT3B0aW9uYWwuIEEgc2hvcnQgZGVzY3JpcHRpb24gb2YgdGhp
cyBtb2RlbC4KCgwKBQQAAgQFEgNSAggKDAoFBAACBAESA1IJFAoMCgUEAAIEAxIDUhcYCgwK
BQQAAgQIEgNSGUEKDwoIBAACBAicCAASA1IaQAr3AgoEBAACBRIDXAJLGukCIE9wdGlvbmFs
LiBDb250cm9scyB0aGUgcmFuZG9tbmVzcyBvZiB0aGUgb3V0cHV0LgoKIFZhbHVlcyBjYW4g
cmFuZ2Ugb3ZlciBgWzAuMCwxLjBdYCwgaW5jbHVzaXZlLiBBIHZhbHVlIGNsb3NlciB0byBg
MS4wYCB3aWxsCiBwcm9kdWNlIHJlc3BvbnNlcyB0aGF0IGFyZSBtb3JlIHZhcmllZCwgd2hp
bGUgYSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAgd2lsbAogdHlwaWNhbGx5IHJlc3VsdCBpbiBs
ZXNzIHN1cnByaXNpbmcgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgoKIFRoaXMgdmFsdWUg
c3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdGhlIG9uZSB1c2VkIGJ5IHRoZSBiYXNlIG1vZGVs
IHdoaWxlCiBjcmVhdGluZyB0aGUgbW9kZWwuCgoMCgUEAAIFBBIDXAIKCgwKBQQAAgUFEgNc
CxAKDAoFBAACBQESA1wRHAoMCgUEAAIFAxIDXB8hCgwKBQQAAgUIEgNcIkoKDwoIBAACBQic
CAASA1wjSQryAQoEBAACBhIDZQJFGuQBIE9wdGlvbmFsLiBGb3IgTnVjbGV1cyBzYW1wbGlu
Zy4KCiBOdWNsZXVzIHNhbXBsaW5nIGNvbnNpZGVycyB0aGUgc21hbGxlc3Qgc2V0IG9mIHRv
a2VucyB3aG9zZSBwcm9iYWJpbGl0eQogc3VtIGlzIGF0IGxlYXN0IGB0b3BfcGAuCgogVGhp
cyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB0aGUgb25lIHVzZWQgYnkgdGhlIGJh
c2UgbW9kZWwgd2hpbGUKIGNyZWF0aW5nIHRoZSBtb2RlbC4KCgwKBQQAAgYEEgNlAgoKDAoF
BAACBgUSA2ULEAoMCgUEAAIGARIDZREWCgwKBQQAAgYDEgNlGRsKDAoFBAACBggSA2UcRAoP
CggEAAIGCJwIABIDZR1DCq0CCgQEAAIHEgNvAkUanwIgT3B0aW9uYWwuIEZvciBUb3AtayBz
YW1wbGluZy4KCiBUb3AtayBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNldCBvZiBgdG9wX2tg
IG1vc3QgcHJvYmFibGUgdG9rZW5zLgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0
byBiZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhl
IG1vZGVsLgoKIFRoaXMgdmFsdWUgc3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdGhlIG9uZSB1
c2VkIGJ5IHRoZSBiYXNlIG1vZGVsIHdoaWxlCiBjcmVhdGluZyB0aGUgbW9kZWwuCgoMCgUE
AAIHBBIDbwIKCgwKBQQAAgcFEgNvCxAKDAoFBAACBwESA28RFgoMCgUEAAIHAxIDbxkbCgwK
BQQAAgcIEgNvHEQKDwoIBAACBwicCAASA28dQwo5CgQEAAIIEgNyAj4aLCBPdXRwdXQgb25s
eS4gVGhlIHN0YXRlIG9mIHRoZSB0dW5lZCBtb2RlbC4KCgwKBQQAAggGEgNyAgcKDAoFBAAC
CAESA3IIDQoMCgUEAAIIAxIDchARCgwKBQQAAggIEgNyEj0KDwoIBAACCAicCAASA3ITPApH
CgQEAAIJEgR1AnYyGjkgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIG1v
ZGVsIHdhcyBjcmVhdGVkLgoKDAoFBAACCQYSA3UCGwoMCgUEAAIJARIDdRwnCgwKBQQAAgkD
EgN1KisKDAoFBAACCQgSA3YGMQoPCggEAAIJCJwIABIDdgcwCkcKBAQAAgoSBHkCejIaOSBP
dXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoaXMgbW9kZWwgd2FzIHVwZGF0ZWQu
CgoMCgUEAAIKBhIDeQIbCgwKBQQAAgoBEgN5HCcKDAoFBAACCgMSA3kqKwoMCgUEAAIKCBID
egYxCg8KCAQAAgoInAgAEgN6BzAKRgoEBAACCxIDfQJHGjkgUmVxdWlyZWQuIFRoZSB0dW5p
bmcgdGFzayB0aGF0IGNyZWF0ZXMgdGhlIHR1bmVkIG1vZGVsLgoKDAoFBAACCwYSA30CDAoM
CgUEAAILARIDfQ0YCgwKBQQAAgsDEgN9Gx0KDAoFBAACCwgSA30eRgoPCggEAAILCJwIABID
fR9FCkEKAgQBEgaBAQCUAQEaMyBUdW5lZCBtb2RlbCBhcyBhIHNvdXJjZSBmb3IgdHJhaW5p
bmcgYSBuZXcgbW9kZWwuCgoLCgMEAQESBIEBCBgKmwEKBAQBAgASBoUBAooBBBqKASBJbW11
dGFibGUuIFRoZSBuYW1lIG9mIHRoZSBgVHVuZWRNb2RlbGAgdG8gdXNlIGFzIHRoZSBzdGFy
dGluZyBwb2ludCBmb3IKIHRyYWluaW5nIHRoZSBuZXcgbW9kZWwuCiBFeGFtcGxlOiBgdHVu
ZWRNb2RlbHMvbXktdHVuZWQtbW9kZWxgCgoNCgUEAQIABRIEhQECCAoNCgUEAQIAARIEhQEJ
FAoNCgUEAQIAAxIEhQEXGAoPCgUEAQIACBIGhQEZigEDChAKCAQBAgAInAgAEgSGAQQrChEK
BwQBAgAInwgSBocBBIkBBQp/CgQEAQIBEgaOAQKTAQQabyBPdXRwdXQgb25seS4gVGhlIG5h
bWUgb2YgdGhlIGJhc2UgYE1vZGVsYCB0aGlzIGBUdW5lZE1vZGVsYCB3YXMgdHVuZWQgZnJv
bS4KIEV4YW1wbGU6IGBtb2RlbHMvdGV4dC1iaXNvbi0wMDFgCgoNCgUEAQIBBRIEjgECCAoN
CgUEAQIBARIEjgEJEwoNCgUEAQIBAxIEjgEWFwoPCgUEAQIBCBIGjgEYkwEDChAKCAQBAgEI
nAgAEgSPAQQtChEKBwQBAgEInwgSBpABBJIBBQo2CgIEAhIGlwEArgEBGiggVHVuaW5nIHRh
c2tzIHRoYXQgY3JlYXRlIHR1bmVkIG1vZGVscy4KCgsKAwQCARIElwEIEgpMCgQEAgIAEgaZ
AQKaATIaPCBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHR1bmluZyB0aGlzIG1v
ZGVsIHN0YXJ0ZWQuCgoNCgUEAgIABhIEmQECGwoNCgUEAgIAARIEmQEcJgoNCgUEAgIAAxIE
mQEpKgoNCgUEAgIACBIEmgEGMQoQCggEAgIACJwIABIEmgEHMApOCgQEAgIBEgadAQKeATIa
PiBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHR1bmluZyB0aGlzIG1vZGVsIGNv
bXBsZXRlZC4KCg0KBQQCAgEGEgSdAQIbCg0KBQQCAgEBEgSdARwpCg0KBQQCAgEDEgSdASwt
Cg0KBQQCAgEIEgSeAQYxChAKCAQCAgEInAgAEgSeAQcwCj8KBAQCAgISBqEBAqIBMhovIE91
dHB1dCBvbmx5LiBNZXRyaWNzIGNvbGxlY3RlZCBkdXJpbmcgdHVuaW5nLgoKDQoFBAICAgQS
BKEBAgoKDQoFBAICAgYSBKEBCxkKDQoFBAICAgESBKEBGiMKDQoFBAICAgMSBKEBJicKDQoF
BAICAggSBKIBBjEKEAoIBAICAgicCAASBKIBBzAKSwoEBAICAxIGpQECqQEEGjsgUmVxdWly
ZWQuIElucHV0IG9ubHkuIEltbXV0YWJsZS4gVGhlIG1vZGVsIHRyYWluaW5nIGRhdGEuCgoN
CgUEAgIDBhIEpQECCQoNCgUEAgIDARIEpQEKFwoNCgUEAgIDAxIEpQEaGwoPCgUEAgIDCBIG
pQEcqQEDChAKCAQCAgMInAgAEgSmAQQsChAKCAQCAgMInAgBEgSnAQQqChAKCAQCAgMInAgC
EgSoAQQrCnkKBAQCAgQSBK0BAlAaayBJbW11dGFibGUuIEh5cGVycGFyYW1ldGVycyBjb250
cm9sbGluZyB0aGUgdHVuaW5nIHByb2Nlc3MuIElmIG5vdCBwcm92aWRlZCwKIGRlZmF1bHQg
dmFsdWVzIHdpbGwgYmUgdXNlZC4KCg0KBQQCAgQGEgStAQIRCg0KBQQCAgQBEgStARIhCg0K
BQQCAgQDEgStASQlCg0KBQQCAgQIEgStASZPChAKCAQCAgQInAgAEgStASdOCj8KAgQDEgax
AQC/AQEaMSBIeXBlcnBhcmFtZXRlcnMgY29udHJvbGxpbmcgdGhlIHR1bmluZyBwcm9jZXNz
LgoKCwoDBAMBEgSxAQgXCpUBCgQEAwIAEgS0AQJMGoYBIEltbXV0YWJsZS4gVGhlIG51bWJl
ciBvZiB0cmFpbmluZyBlcG9jaHMuIEFuIGVwb2NoIGlzIG9uZSBwYXNzIHRocm91Z2ggdGhl
CiB0cmFpbmluZyBkYXRhLiBJZiBub3Qgc2V0LCBhIGRlZmF1bHQgb2YgMTAgd2lsbCBiZSB1
c2VkLgoKDQoFBAMCAAQSBLQBAgoKDQoFBAMCAAUSBLQBCxAKDQoFBAMCAAESBLQBERwKDQoF
BAMCAAMSBLQBHyEKDQoFBAMCAAgSBLQBIksKEAoIBAMCAAicCAASBLQBI0oKoAEKBAQDAgES
BLkBAksakQEgSW1tdXRhYmxlLiBUaGUgYmF0Y2ggc2l6ZSBoeXBlcnBhcmFtZXRlciBmb3Ig
dHVuaW5nLgogSWYgbm90IHNldCwgYSBkZWZhdWx0IG9mIDE2IG9yIDY0IHdpbGwgYmUgdXNl
ZCBiYXNlZCBvbiB0aGUgbnVtYmVyIG9mCiB0cmFpbmluZyBleGFtcGxlcy4KCg0KBQQDAgEE
EgS5AQIKCg0KBQQDAgEFEgS5AQsQCg0KBQQDAgEBEgS5AREbCg0KBQQDAgEDEgS5AR4gCg0K
BQQDAgEIEgS5ASFKChAKCAQDAgEInAgAEgS5ASJJCrABCgQEAwICEgS+AQJOGqEBIEltbXV0
YWJsZS4gVGhlIGxlYXJuaW5nIHJhdGUgaHlwZXJwYXJhbWV0ZXIgZm9yIHR1bmluZy4KIElm
IG5vdCBzZXQsIGEgZGVmYXVsdCBvZiAwLjAwMDIgb3IgMC4wMDIgd2lsbCBiZSBjYWxjdWxh
dGVkIGJhc2VkIG9uIHRoZQogbnVtYmVyIG9mIHRyYWluaW5nIGV4YW1wbGVzLgoKDQoFBAMC
AgQSBL4BAgoKDQoFBAMCAgUSBL4BCxAKDQoFBAMCAgESBL4BER4KDQoFBAMCAgMSBL4BISMK
DQoFBAMCAggSBL4BJE0KEAoIBAMCAgicCAASBL4BJUwKMwoCBAQSBsIBAMgBARolIERhdGFz
ZXQgZm9yIHRyYWluaW5nIG9yIHZhbGlkYXRpb24uCgoLCgMEBAESBMIBCA8KOQoEBAQIABIG
xAECxwEDGikgSW5saW5lIGRhdGEgb3IgYSByZWZlcmVuY2UgdG8gdGhlIGRhdGEuCgoNCgUE
BAgAARIExAEIDwoqCgQEBAIAEgTGAQRJGhwgT3B0aW9uYWwuIElubGluZSBleGFtcGxlcy4K
Cg0KBQQEAgAGEgTGAQQSCg0KBQQEAgABEgTGARMbCg0KBQQEAgADEgTGAR4fCg0KBQQEAgAI
EgTGASBIChAKCAQEAgAInAgAEgTGASFHCk8KAgQFEgbLAQDPAQEaQSBBIHNldCBvZiB0dW5p
bmcgZXhhbXBsZXMuIENhbiBiZSB0cmFpbmluZyBvciB2YWxpZGF0YXRpb24gZGF0YS4KCgsK
AwQFARIEywEIFgqGAQoEBAUCABIEzgECTxp4IFJlcXVpcmVkLiBUaGUgZXhhbXBsZXMuIEV4
YW1wbGUgaW5wdXQgY2FuIGJlIGZvciB0ZXh0IG9yIGRpc2N1c3MsIGJ1dCBhbGwKIGV4YW1w
bGVzIGluIGEgc2V0IG11c3QgYmUgb2YgdGhlIHNhbWUgdHlwZS4KCg0KBQQFAgAEEgTOAQIK
Cg0KBQQFAgAGEgTOAQsYCg0KBQQFAgABEgTOARkhCg0KBQQFAgADEgTOASQlCg0KBQQFAgAI
EgTOASZOChAKCAQFAgAInAgAEgTOASdNCiwKAgQGEgbSAQDbAQEaHiBBIHNpbmdsZSBleGFt
cGxlIGZvciB0dW5pbmcuCgoLCgMEBgESBNIBCBUKOgoEBAYIABIG1AEC1wEDGiogVGhlIGlu
cHV0IHRvIHRoZSBtb2RlbCBmb3IgdGhpcyBleGFtcGxlLgoKDQoFBAYIAAESBNQBCBMKKwoE
BAYCABIE1gEEQxodIE9wdGlvbmFsLiBUZXh0IG1vZGVsIGlucHV0LgoKDQoFBAYCAAUSBNYB
BAoKDQoFBAYCAAESBNYBCxUKDQoFBAYCAAMSBNYBGBkKDQoFBAYCAAgSBNYBGkIKEAoIBAYC
AAicCAASBNYBG0EKNAoEBAYCARIE2gECPRomIFJlcXVpcmVkLiBUaGUgZXhwZWN0ZWQgbW9k
ZWwgb3V0cHV0LgoKDQoFBAYCAQUSBNoBAggKDQoFBAYCAQESBNoBCQ8KDQoFBAYCAQMSBNoB
EhMKDQoFBAYCAQgSBNoBFDwKEAoIBAYCAQicCAASBNoBFTsKMAoCBAcSBt4BAOsBARoiIFJl
Y29yZCBmb3IgYSBzaW5nbGUgdHVuaW5nIHN0ZXAuCgoLCgMEBwESBN4BCBYKLQoEBAcCABIE
4AECPRofIE91dHB1dCBvbmx5LiBUaGUgdHVuaW5nIHN0ZXAuCgoNCgUEBwIABRIE4AECBwoN
CgUEBwIAARIE4AEIDAoNCgUEBwIAAxIE4AEPEAoNCgUEBwIACBIE4AERPAoQCggEBwIACJwI
ABIE4AESOwo9CgQEBwIBEgTjAQI+Gi8gT3V0cHV0IG9ubHkuIFRoZSBlcG9jaCB0aGlzIHN0
ZXAgd2FzIHBhcnQgb2YuCgoNCgUEBwIBBRIE4wECBwoNCgUEBwIBARIE4wEIDQoNCgUEBwIB
AxIE4wEQEQoNCgUEBwIBCBIE4wESPQoQCggEBwIBCJwIABIE4wETPApSCgQEBwICEgTmAQJC
GkQgT3V0cHV0IG9ubHkuIFRoZSBtZWFuIGxvc3Mgb2YgdGhlIHRyYWluaW5nIGV4YW1wbGVz
IGZvciB0aGlzIHN0ZXAuCgoNCgUEBwICBRIE5gECBwoNCgUEBwICARIE5gEIEQoNCgUEBwIC
AxIE5gEUFQoNCgUEBwICCBIE5gEWQQoQCggEBwICCJwIABIE5gEXQApLCgQEBwIDEgbpAQLq
ATIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoaXMgbWV0cmljIHdhcyBj
b21wdXRlZC4KCg0KBQQHAgMGEgTpAQIbCg0KBQQHAgMBEgTpARwoCg0KBQQHAgMDEgTpASss
Cg0KBQQHAgMIEgTqAQYxChAKCAQHAgMInAgAEgTqAQcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel ===
    # Fields for TunedModel
    # Field: tuned_model_source Type: 11 (.google.ai.generativelanguage.v1beta3.TunedModelSource)
    # Field: base_model Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: temperature Type: 2 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: state Type: 14 (.google.ai.generativelanguage.v1beta3.TunedModel.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: tuning_task Type: 11 (.google.ai.generativelanguage.v1beta3.TuningTask)

# Enum: TunedModel::State
our $TunedModel_STATE_UNSPECIFIED = 0;
our $TunedModel_CREATING = 1;
our $TunedModel_ACTIVE = 2;
our $TunedModel_FAILED = 3;

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModelSource ===
    # Fields for TunedModelSource
    # Field: tuned_model Type: 9 ()
    # Field: base_model Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningTask ===
    # Fields for TuningTask
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1beta3.TuningSnapshot)
    # Field: training_data Type: 11 (.google.ai.generativelanguage.v1beta3.Dataset)
    # Field: hyperparameters Type: 11 (.google.ai.generativelanguage.v1beta3.Hyperparameters)

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::Hyperparameters ===
    # Fields for Hyperparameters
    # Field: epoch_count Type: 5 ()
    # Field: batch_size Type: 5 ()
    # Field: learning_rate Type: 2 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::Dataset ===
    # Fields for Dataset
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1beta3.TuningExamples)

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExamples ===
    # Fields for TuningExamples
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1beta3.TuningExample)

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExample ===
    # Fields for TuningExample
    # Field: text_input Type: 9 ()
    # Field: output Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningSnapshot ===
    # Fields for TuningSnapshot
    # Field: step Type: 5 ()
    # Field: epoch Type: 5 ()
    # Field: mean_loss Type: 2 ()
    # Field: compute_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::TunedModel - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/tuned_model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::TunedModel;

    my $msg = Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel->new({
        tuned_model_source => $tuned_model_source,
        base_model => $base_model,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->tuned_model_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/tuned_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel

A fine-tuned model created using ModelService.CreateTunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model_source() >> / C<< $msg->tuned_model_source($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModelSource>)

Optional. TunedModel to use as the starting point for training the new
model.

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Immutable. The name of the `Model` to tune.
Example: `models/text-bison-001`

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The tuned model name. A unique name will be generated on
create. Example: `tunedModels/az2mb0bpw6i` If display_name is set on
create, the id portion of the name will be set by concatenating the words
of the display_name with hyphens and adding a random portion for
uniqueness. Example:
    display_name = "Sentence Translator"
    name = "tunedModels/sentence-translator-u3b7m"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The name to display for this model in user interfaces.
The display name must be up to 40 characters including spaces.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A short description of this model.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.

Values can range over `[0.0,1.0]`, inclusive. A value closer to `1.0` will
produce responses that are more varied, while a value closer to `0.0` will
typically result in less surprising responses from the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. For Nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. For Top-k sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
This value specifies default to be used by the backend while making the
call to the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::State>)

Output only. The state of the tuned model.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was updated.

=item * C<< $msg->tuning_task() >> / C<< $msg->tuning_task($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningTask>)

Required. The tuning task that creates the tuned model.

=back

=head3 Enum: TunedModel::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModelSource

Tuned model as a source for training a new model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<String>

Immutable. The name of the `TunedModel` to use as the starting point for
training the new model.
Example: `tunedModels/my-tuned-model`

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Output only. The name of the base `Model` this `TunedModel` was tuned from.
Example: `models/text-bison-001`

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningTask

Tuning tasks that create tuned models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model started.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model completed.

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningSnapshot>)

Output only. Metrics collected during tuning.

=item * C<< $msg->training_data() >> / C<< $msg->training_data($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::Dataset>)

Required. Input only. Immutable. The model training data.

=item * C<< $msg->hyperparameters() >> / C<< $msg->hyperparameters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::Hyperparameters>)

Immutable. Hyperparameters controlling the tuning process. If not provided,
default values will be used.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::Hyperparameters

Hyperparameters controlling the tuning process.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->epoch_count() >> / C<< $msg->epoch_count($value) >>

Type: C<Int32>

Immutable. The number of training epochs. An epoch is one pass through the
training data. If not set, a default of 10 will be used.

=item * C<< $msg->batch_size() >> / C<< $msg->batch_size($value) >>

Type: C<Int32>

Immutable. The batch size hyperparameter for tuning.
If not set, a default of 16 or 64 will be used based on the number of
training examples.

=item * C<< $msg->learning_rate() >> / C<< $msg->learning_rate($value) >>

Type: C<Float>

Immutable. The learning rate hyperparameter for tuning.
If not set, a default of 0.0002 or 0.002 will be calculated based on the
number of training examples.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::Dataset

Dataset for training or validation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExamples>)

Optional. Inline examples.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExamples

A set of tuning examples. Can be training or validatation data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExample>)

Required. The examples. Example input can be for text or discuss, but all
examples in a set must be of the same type.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningExample

A single example for tuning.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_input() >> / C<< $msg->text_input($value) >>

Type: C<String>

Optional. Text model input.

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<String>

Required. The expected model output.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TunedModel::TuningSnapshot

Record for a single tuning step.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Int32>

Output only. The tuning step.

=item * C<< $msg->epoch() >> / C<< $msg->epoch($value) >>

Type: C<Int32>

Output only. The epoch this step was part of.

=item * C<< $msg->mean_loss() >> / C<< $msg->mean_loss($value) >>

Type: C<Float>

Output only. The mean loss of the training examples for this step.

=item * C<< $msg->compute_time() >> / C<< $msg->compute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this metric was computed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::TunedModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
