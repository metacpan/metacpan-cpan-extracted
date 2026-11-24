package Google::Firestore::Admin::V1beta2::Operation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Firestore::Admin::V1beta2::Index };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Api::Annotations };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxYmV0YTIvb3BlcmF0aW9uLnByb3RvEh5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIaKmdvb2dsZS9maXJlc3RvcmUvYWRtaW4vdjFi
ZXRhMi9pbmRleC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90byKQAwoWSW5kZXhPcGVyYXRpb25NZXRhZGF0YRI5
CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRU
aW1lEjUKCGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5k
VGltZRIUCgVpbmRleBgDIAEoCVIFaW5kZXgSRAoFc3RhdGUYBCABKA4yLi5nb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxYmV0YTIuT3BlcmF0aW9uU3RhdGVSBXN0YXRlElcKEnByb2dyZXNz
X2RvY3VtZW50cxgFIAEoCzIoLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5Qcm9n
cmVzc1IRcHJvZ3Jlc3NEb2N1bWVudHMSTwoOcHJvZ3Jlc3NfYnl0ZXMYBiABKAsyKC5nb29n
bGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuUHJvZ3Jlc3NSDXByb2dyZXNzQnl0ZXMijgYK
FkZpZWxkT3BlcmF0aW9uTWV0YWRhdGESOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSFAoFZmllbGQYAyABKAlSBWZpZWxkEncK
E2luZGV4X2NvbmZpZ19kZWx0YXMYBCADKAsyRy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYx
YmV0YTIuRmllbGRPcGVyYXRpb25NZXRhZGF0YS5JbmRleENvbmZpZ0RlbHRhUhFpbmRleENv
bmZpZ0RlbHRhcxJECgVzdGF0ZRgFIAEoDjIuLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFi
ZXRhMi5PcGVyYXRpb25TdGF0ZVIFc3RhdGUSVQoRZG9jdW1lbnRfcHJvZ3Jlc3MYBiABKAsy
KC5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuUHJvZ3Jlc3NSEGRvY3VtZW50UHJv
Z3Jlc3MSTwoOYnl0ZXNfcHJvZ3Jlc3MYByABKAsyKC5nb29nbGUuZmlyZXN0b3JlLmFkbWlu
LnYxYmV0YTIuUHJvZ3Jlc3NSDWJ5dGVzUHJvZ3Jlc3MahAIKEEluZGV4Q29uZmlnRGVsdGES
cwoLY2hhbmdlX3R5cGUYASABKA4yUi5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIu
RmllbGRPcGVyYXRpb25NZXRhZGF0YS5JbmRleENvbmZpZ0RlbHRhLkNoYW5nZVR5cGVSCmNo
YW5nZVR5cGUSOwoFaW5kZXgYAiABKAsyJS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0
YTIuSW5kZXhSBWluZGV4Ij4KCkNoYW5nZVR5cGUSGwoXQ0hBTkdFX1RZUEVfVU5TUEVDSUZJ
RUQQABIHCgNBREQQARIKCgZSRU1PVkUQAiLhAwoXRXhwb3J0RG9jdW1lbnRzTWV0YWRhdGES
OQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0
VGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2Vu
ZFRpbWUSVwoPb3BlcmF0aW9uX3N0YXRlGAMgASgOMi4uZ29vZ2xlLmZpcmVzdG9yZS5hZG1p
bi52MWJldGEyLk9wZXJhdGlvblN0YXRlUg5vcGVyYXRpb25TdGF0ZRJXChJwcm9ncmVzc19k
b2N1bWVudHMYBCABKAsyKC5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuUHJvZ3Jl
c3NSEXByb2dyZXNzRG9jdW1lbnRzEk8KDnByb2dyZXNzX2J5dGVzGAUgASgLMiguZ29vZ2xl
LmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLlByb2dyZXNzUg1wcm9ncmVzc0J5dGVzEiUKDmNv
bGxlY3Rpb25faWRzGAYgAygJUg1jb2xsZWN0aW9uSWRzEioKEW91dHB1dF91cmlfcHJlZml4
GAcgASgJUg9vdXRwdXRVcmlQcmVmaXgi3wMKF0ltcG9ydERvY3VtZW50c01ldGFkYXRhEjkK
CnN0YXJ0X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRp
bWUSNQoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRU
aW1lElcKD29wZXJhdGlvbl9zdGF0ZRgDIAEoDjIuLmdvb2dsZS5maXJlc3RvcmUuYWRtaW4u
djFiZXRhMi5PcGVyYXRpb25TdGF0ZVIOb3BlcmF0aW9uU3RhdGUSVwoScHJvZ3Jlc3NfZG9j
dW1lbnRzGAQgASgLMiguZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLlByb2dyZXNz
UhFwcm9ncmVzc0RvY3VtZW50cxJPCg5wcm9ncmVzc19ieXRlcxgFIAEoCzIoLmdvb2dsZS5m
aXJlc3RvcmUuYWRtaW4udjFiZXRhMi5Qcm9ncmVzc1INcHJvZ3Jlc3NCeXRlcxIlCg5jb2xs
ZWN0aW9uX2lkcxgGIAMoCVINY29sbGVjdGlvbklkcxIoChBpbnB1dF91cmlfcHJlZml4GAcg
ASgJUg5pbnB1dFVyaVByZWZpeCJFChdFeHBvcnREb2N1bWVudHNSZXNwb25zZRIqChFvdXRw
dXRfdXJpX3ByZWZpeBgBIAEoCVIPb3V0cHV0VXJpUHJlZml4IlgKCFByb2dyZXNzEiUKDmVz
dGltYXRlZF93b3JrGAEgASgDUg1lc3RpbWF0ZWRXb3JrEiUKDmNvbXBsZXRlZF93b3JrGAIg
ASgDUg1jb21wbGV0ZWRXb3JrKp4BCg5PcGVyYXRpb25TdGF0ZRIfChtPUEVSQVRJT05fU1RB
VEVfVU5TUEVDSUZJRUQQABIQCgxJTklUSUFMSVpJTkcQARIOCgpQUk9DRVNTSU5HEAISDgoK
Q0FOQ0VMTElORxADEg4KCkZJTkFMSVpJTkcQBBIOCgpTVUNDRVNTRlVMEAUSCgoGRkFJTEVE
EAYSDQoJQ0FOQ0VMTEVEEAdCpAEKImNvbS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0
YTJCDk9wZXJhdGlvblByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZmlyZXN0b3JlL2Fk
bWluL2FwaXYxYmV0YTIvYWRtaW5wYjthZG1pbnBiogIER0NGU6oCJEdvb2dsZS5DbG91ZC5G
aXJlc3RvcmUuQWRtaW4uVjFCZXRhMkrqNwoHEgUPAMkBAQq9BAoBDBIDDwASMrIEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCgoICgECEgMRACcKCQoCAwASAxMANAoJCgIDARIDFAApCgkKAgMC
EgMVACYKCAoBCBIDFwBBCgkKAgglEgMXAEEKCAoBCBIDGABVCgkKAggLEgMYAFUKCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgAvCgkKAggIEgMaAC8KCAoBCBIDGwA7CgkKAggBEgMb
ADsKCAoBCBIDHAAiCgkKAggkEgMcACIKvwEKAgQAEgQgADQBGrIBIE1ldGFkYXRhIGZvciBb
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbl0gcmVzdWx0cyBmcm9tCiBbRmlyZXN0b3JlQWRtaW4uQ3JlYXRlSW5kZXhdW2dvb2ds
ZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3RvcmVBZG1pbi5DcmVhdGVJbmRleF0u
CgoKCgMEAAESAyAIHgovCgQEAAIAEgMiAisaIiBUaGUgdGltZSB0aGlzIG9wZXJhdGlvbiBz
dGFydGVkLgoKDAoFBAACAAYSAyICGwoMCgUEAAIAARIDIhwmCgwKBQQAAgADEgMiKSoKYAoE
BAACARIDJgIpGlMgVGhlIHRpbWUgdGhpcyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJl
IHVuc2V0IGlmIG9wZXJhdGlvbiBzdGlsbCBpbgogcHJvZ3Jlc3MuCgoMCgUEAAIBBhIDJgIb
CgwKBQQAAgEBEgMmHCQKDAoFBAACAQMSAyYnKAq2AQoEBAACAhIDKgITGqgBIFRoZSBpbmRl
eCByZXNvdXJjZSB0aGF0IHRoaXMgb3BlcmF0aW9uIGlzIGFjdGluZyBvbi4gRm9yIGV4YW1w
bGU6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2Nv
bGxlY3Rpb25Hcm91cHMve2NvbGxlY3Rpb25faWR9L2luZGV4ZXMve2luZGV4X2lkfWAKCgwK
BQQAAgIFEgMqAggKDAoFBAACAgESAyoJDgoMCgUEAAICAxIDKhESCioKBAQAAgMSAy0CGxod
IFRoZSBzdGF0ZSBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACAwYSAy0CEAoMCgUEAAIDARID
LREWCgwKBQQAAgMDEgMtGRoKPQoEBAACBBIDMAIiGjAgVGhlIHByb2dyZXNzLCBpbiBkb2N1
bWVudHMsIG9mIHRoaXMgb3BlcmF0aW9uLgoKDAoFBAACBAYSAzACCgoMCgUEAAIEARIDMAsd
CgwKBQQAAgQDEgMwICEKOQoEBAACBRIDMwIeGiwgVGhlIHByb2dyZXNzLCBpbiBieXRlcywg
b2YgdGhpcyBvcGVyYXRpb24uCgoMCgUEAAIFBhIDMwIKCgwKBQQAAgUBEgMzCxkKDAoFBAAC
BQMSAzMcHQq/AQoCBAESBDgAZQEasgEgTWV0YWRhdGEgZm9yIFtnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXSByZXN1bHRzIGZy
b20KIFtGaXJlc3RvcmVBZG1pbi5VcGRhdGVGaWVsZF1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1p
bi52MWJldGEyLkZpcmVzdG9yZUFkbWluLlVwZGF0ZUZpZWxkXS4KCgoKAwQBARIDOAgeCkAK
BAQBAwASBDoCTAMaMiBJbmZvcm1hdGlvbiBhYm91dCBhbiBpbmRleCBjb25maWd1cmF0aW9u
IGNoYW5nZS4KCgwKBQQBAwABEgM6ChoKNgoGBAEDAAQAEgQ8BEUFGiYgU3BlY2lmaWVzIGhv
dyB0aGUgaW5kZXggaXMgY2hhbmdpbmcuCgoOCgcEAQMABAABEgM8CRMKQAoIBAEDAAQAAgAS
Az4GIhovIFRoZSB0eXBlIG9mIGNoYW5nZSBpcyBub3Qgc3BlY2lmaWVkIG9yIGtub3duLgoK
EAoJBAEDAAQAAgABEgM+Bh0KEAoJBAEDAAQAAgACEgM+ICEKOQoIBAEDAAQAAgESA0EGDhoo
IFRoZSBzaW5nbGUgZmllbGQgaW5kZXggaXMgYmVpbmcgYWRkZWQuCgoQCgkEAQMABAACAQES
A0EGCQoQCgkEAQMABAACAQISA0EMDQo7CggEAQMABAACAhIDRAYRGiogVGhlIHNpbmdsZSBm
aWVsZCBpbmRleCBpcyBiZWluZyByZW1vdmVkLgoKEAoJBAEDAAQAAgIBEgNEBgwKEAoJBAED
AAQAAgICEgNEDxAKNQoGBAEDAAIAEgNIBB8aJiBTcGVjaWZpZXMgaG93IHRoZSBpbmRleCBp
cyBjaGFuZ2luZy4KCg4KBwQBAwACAAYSA0gEDgoOCgcEAQMAAgABEgNIDxoKDgoHBAEDAAIA
AxIDSB0eCikKBgQBAwACARIDSwQUGhogVGhlIGluZGV4IGJlaW5nIGNoYW5nZWQuCgoOCgcE
AQMAAgEGEgNLBAkKDgoHBAEDAAIBARIDSwoPCg4KBwQBAwACAQMSA0sSEwovCgQEAQIAEgNP
AisaIiBUaGUgdGltZSB0aGlzIG9wZXJhdGlvbiBzdGFydGVkLgoKDAoFBAECAAYSA08CGwoM
CgUEAQIAARIDTxwmCgwKBQQBAgADEgNPKSoKYAoEBAECARIDUwIpGlMgVGhlIHRpbWUgdGhp
cyBvcGVyYXRpb24gY29tcGxldGVkLiBXaWxsIGJlIHVuc2V0IGlmIG9wZXJhdGlvbiBzdGls
bCBpbgogcHJvZ3Jlc3MuCgoMCgUEAQIBBhIDUwIbCgwKBQQBAgEBEgNTHCQKDAoFBAECAQMS
A1MnKAq3AQoEBAECAhIDVwITGqkBIFRoZSBmaWVsZCByZXNvdXJjZSB0aGF0IHRoaXMgb3Bl
cmF0aW9uIGlzIGFjdGluZyBvbi4gRm9yIGV4YW1wbGU6CiBgcHJvamVjdHMve3Byb2plY3Rf
aWR9L2RhdGFiYXNlcy97ZGF0YWJhc2VfaWR9L2NvbGxlY3Rpb25Hcm91cHMve2NvbGxlY3Rp
b25faWR9L2ZpZWxkcy97ZmllbGRfcGF0aH1gCgoMCgUEAQICBRIDVwIICgwKBQQBAgIBEgNX
CQ4KDAoFBAECAgMSA1cREgqjAQoEBAECAxIDWwI0GpUBIEEgbGlzdCBvZiBbSW5kZXhDb25m
aWdEZWx0YV1bZ29vZ2xlLmZpcmVzdG9yZS5hZG1pbi52MWJldGEyLkZpZWxkT3BlcmF0aW9u
TWV0YWRhdGEuSW5kZXhDb25maWdEZWx0YV0sIHdoaWNoIGRlc2NyaWJlIHRoZSBpbnRlbnQg
b2YgdGhpcwogb3BlcmF0aW9uLgoKDAoFBAECAwQSA1sCCgoMCgUEAQIDBhIDWwsbCgwKBQQB
AgMBEgNbHC8KDAoFBAECAwMSA1syMwoqCgQEAQIEEgNeAhsaHSBUaGUgc3RhdGUgb2YgdGhl
IG9wZXJhdGlvbi4KCgwKBQQBAgQGEgNeAhAKDAoFBAECBAESA14RFgoMCgUEAQIEAxIDXhka
Cj0KBAQBAgUSA2ECIRowIFRoZSBwcm9ncmVzcywgaW4gZG9jdW1lbnRzLCBvZiB0aGlzIG9w
ZXJhdGlvbi4KCgwKBQQBAgUGEgNhAgoKDAoFBAECBQESA2ELHAoMCgUEAQIFAxIDYR8gCjkK
BAQBAgYSA2QCHhosIFRoZSBwcm9ncmVzcywgaW4gYnl0ZXMsIG9mIHRoaXMgb3BlcmF0aW9u
LgoKDAoFBAECBgYSA2QCCgoMCgUEAQIGARIDZAsZCgwKBQQBAgYDEgNkHB0KxwEKAgQCEgRp
AH8BGroBIE1ldGFkYXRhIGZvciBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl1bZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0gcmVzdWx0cyBmcm9tCiBbRmlyZXN0b3JlQWRt
aW4uRXhwb3J0RG9jdW1lbnRzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuRmly
ZXN0b3JlQWRtaW4uRXhwb3J0RG9jdW1lbnRzXS4KCgoKAwQCARIDaQgfCi8KBAQCAgASA2sC
KxoiIFRoZSB0aW1lIHRoaXMgb3BlcmF0aW9uIHN0YXJ0ZWQuCgoMCgUEAgIABhIDawIbCgwK
BQQCAgABEgNrHCYKDAoFBAICAAMSA2spKgpgCgQEAgIBEgNvAikaUyBUaGUgdGltZSB0aGlz
IG9wZXJhdGlvbiBjb21wbGV0ZWQuIFdpbGwgYmUgdW5zZXQgaWYgb3BlcmF0aW9uIHN0aWxs
IGluCiBwcm9ncmVzcy4KCgwKBQQCAgEGEgNvAhsKDAoFBAICAQESA28cJAoMCgUEAgIBAxID
bycoCjEKBAQCAgISA3ICJRokIFRoZSBzdGF0ZSBvZiB0aGUgZXhwb3J0IG9wZXJhdGlvbi4K
CgwKBQQCAgIGEgNyAhAKDAoFBAICAgESA3IRIAoMCgUEAgICAxIDciMkCj0KBAQCAgMSA3UC
IhowIFRoZSBwcm9ncmVzcywgaW4gZG9jdW1lbnRzLCBvZiB0aGlzIG9wZXJhdGlvbi4KCgwK
BQQCAgMGEgN1AgoKDAoFBAICAwESA3ULHQoMCgUEAgIDAxIDdSAhCjkKBAQCAgQSA3gCHhos
IFRoZSBwcm9ncmVzcywgaW4gYnl0ZXMsIG9mIHRoaXMgb3BlcmF0aW9uLgoKDAoFBAICBAYS
A3gCCgoMCgUEAgIEARIDeAsZCgwKBQQCAgQDEgN4HB0KNwoEBAICBRIDewIlGiogV2hpY2gg
Y29sbGVjdGlvbiBpZHMgYXJlIGJlaW5nIGV4cG9ydGVkLgoKDAoFBAICBQQSA3sCCgoMCgUE
AgIFBRIDewsRCgwKBQQCAgUBEgN7EiAKDAoFBAICBQMSA3sjJAo4CgQEAgIGEgN+Ah8aKyBX
aGVyZSB0aGUgZW50aXRpZXMgYXJlIGJlaW5nIGV4cG9ydGVkIHRvLgoKDAoFBAICBgUSA34C
CAoMCgUEAgIGARIDfgkaCgwKBQQCAgYDEgN+HR4KyQEKAgQDEgaDAQCZAQEaugEgTWV0YWRh
dGEgZm9yIFtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXVtnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uXSByZXN1bHRzIGZyb20KIFtGaXJlc3RvcmVBZG1pbi5JbXBvcnREb2N1
bWVudHNdW2dvb2dsZS5maXJlc3RvcmUuYWRtaW4udjFiZXRhMi5GaXJlc3RvcmVBZG1pbi5J
bXBvcnREb2N1bWVudHNdLgoKCwoDBAMBEgSDAQgfCjAKBAQDAgASBIUBAisaIiBUaGUgdGlt
ZSB0aGlzIG9wZXJhdGlvbiBzdGFydGVkLgoKDQoFBAMCAAYSBIUBAhsKDQoFBAMCAAESBIUB
HCYKDQoFBAMCAAMSBIUBKSoKYQoEBAMCARIEiQECKRpTIFRoZSB0aW1lIHRoaXMgb3BlcmF0
aW9uIGNvbXBsZXRlZC4gV2lsbCBiZSB1bnNldCBpZiBvcGVyYXRpb24gc3RpbGwgaW4KIHBy
b2dyZXNzLgoKDQoFBAMCAQYSBIkBAhsKDQoFBAMCAQESBIkBHCQKDQoFBAMCAQMSBIkBJygK
MgoEBAMCAhIEjAECJRokIFRoZSBzdGF0ZSBvZiB0aGUgaW1wb3J0IG9wZXJhdGlvbi4KCg0K
BQQDAgIGEgSMAQIQCg0KBQQDAgIBEgSMAREgCg0KBQQDAgIDEgSMASMkCj4KBAQDAgMSBI8B
AiIaMCBUaGUgcHJvZ3Jlc3MsIGluIGRvY3VtZW50cywgb2YgdGhpcyBvcGVyYXRpb24uCgoN
CgUEAwIDBhIEjwECCgoNCgUEAwIDARIEjwELHQoNCgUEAwIDAxIEjwEgIQo6CgQEAwIEEgSS
AQIeGiwgVGhlIHByb2dyZXNzLCBpbiBieXRlcywgb2YgdGhpcyBvcGVyYXRpb24uCgoNCgUE
AwIEBhIEkgECCgoNCgUEAwIEARIEkgELGQoNCgUEAwIEAxIEkgEcHQo4CgQEAwIFEgSVAQIl
GiogV2hpY2ggY29sbGVjdGlvbiBpZHMgYXJlIGJlaW5nIGltcG9ydGVkLgoKDQoFBAMCBQQS
BJUBAgoKDQoFBAMCBQUSBJUBCxEKDQoFBAMCBQESBJUBEiAKDQoFBAMCBQMSBJUBIyQKPQoE
BAMCBhIEmAECHhovIFRoZSBsb2NhdGlvbiBvZiB0aGUgZG9jdW1lbnRzIGJlaW5nIGltcG9y
dGVkLgoKDQoFBAMCBgUSBJgBAggKDQoFBAMCBgESBJgBCRkKDQoFBAMCBgMSBJgBHB0KbAoC
BAQSBpwBAKEBARpeIFJldHVybmVkIGluIHRoZSBbZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJh
dGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0gcmVzcG9uc2UgZmllbGQuCgoL
CgMEBAESBJwBCB8KtwEKBAQEAgASBKABAh8aqAEgTG9jYXRpb24gb2YgdGhlIG91dHB1dCBm
aWxlcy4gVGhpcyBjYW4gYmUgdXNlZCB0byBiZWdpbiBhbiBpbXBvcnQKIGludG8gQ2xvdWQg
RmlyZXN0b3JlICh0aGlzIHByb2plY3Qgb3IgYW5vdGhlciBwcm9qZWN0KSBhZnRlciB0aGUg
b3BlcmF0aW9uCiBjb21wbGV0ZXMgc3VjY2Vzc2Z1bGx5LgoKDQoFBAQCAAUSBKABAggKDQoF
BAQCAAESBKABCRoKDQoFBAQCAAMSBKABHR4KNQoCBQASBqQBAL4BARonIERlc2NyaWJlcyB0
aGUgc3RhdGUgb2YgdGhlIG9wZXJhdGlvbi4KCgsKAwUAARIEpAEFEwocCgQFAAIAEgSmAQIi
Gg4gVW5zcGVjaWZpZWQuCgoNCgUFAAIAARIEpgECHQoNCgUFAAIAAhIEpgEgIQo5CgQFAAIB
EgSpAQITGisgUmVxdWVzdCBpcyBiZWluZyBwcmVwYXJlZCBmb3IgcHJvY2Vzc2luZy4KCg0K
BQUAAgEBEgSpAQIOCg0KBQUAAgECEgSpARESCjQKBAUAAgISBKwBAhEaJiBSZXF1ZXN0IGlz
IGFjdGl2ZWx5IGJlaW5nIHByb2Nlc3NlZC4KCg0KBQUAAgIBEgSsAQIMCg0KBQUAAgICEgSs
AQ8QCpABCgQFAAIDEgSwAQIRGoEBIFJlcXVlc3QgaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVp
bmcgY2FuY2VsbGVkIGFmdGVyIHVzZXIgY2FsbGVkCiBnb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9ucy5DYW5jZWxPcGVyYXRpb24gb24gdGhlIG9wZXJhdGlvbi4KCg0KBQUAAgMBEgSw
AQIMCg0KBQUAAgMCEgSwAQ8QCkwKBAUAAgQSBLMBAhEaPiBSZXF1ZXN0IGhhcyBiZWVuIHBy
b2Nlc3NlZCBhbmQgaXMgaW4gaXRzIGZpbmFsaXphdGlvbiBzdGFnZS4KCg0KBQUAAgQBEgSz
AQIMCg0KBQUAAgQCEgSzAQ8QCjMKBAUAAgUSBLYBAhEaJSBSZXF1ZXN0IGhhcyBjb21wbGV0
ZWQgc3VjY2Vzc2Z1bGx5LgoKDQoFBQACBQESBLYBAgwKDQoFBQACBQISBLYBDxAKTwoEBQAC
BhIEuQECDRpBIFJlcXVlc3QgaGFzIGZpbmlzaGVkIGJlaW5nIHByb2Nlc3NlZCwgYnV0IGVu
Y291bnRlcmVkIGFuIGVycm9yLgoKDQoFBQACBgESBLkBAggKDQoFBQACBgISBLkBCwwKdgoE
BQACBxIEvQECEBpoIFJlcXVlc3QgaGFzIGZpbmlzaGVkIGJlaW5nIGNhbmNlbGxlZCBhZnRl
ciB1c2VyIGNhbGxlZAogZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbnMuQ2FuY2VsT3Bl
cmF0aW9uLgoKDQoFBQACBwESBL0BAgsKDQoFBQACBwISBL0BDg8KtwEKAgQFEgbDAQDJAQEa
qAEgRGVzY3JpYmVzIHRoZSBwcm9ncmVzcyBvZiB0aGUgb3BlcmF0aW9uLgogVW5pdCBvZiB3
b3JrIGlzIGdlbmVyaWMgYW5kIG11c3QgYmUgaW50ZXJwcmV0ZWQgYmFzZWQgb24gd2hlcmUg
W1Byb2dyZXNzXVtnb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxYmV0YTIuUHJvZ3Jlc3NdCiBp
cyB1c2VkLgoKCwoDBAUBEgTDAQgQCi0KBAQFAgASBMUBAhsaHyBUaGUgYW1vdW50IG9mIHdv
cmsgZXN0aW1hdGVkLgoKDQoFBAUCAAUSBMUBAgcKDQoFBAUCAAESBMUBCBYKDQoFBAUCAAMS
BMUBGRoKLQoEBAUCARIEyAECGxofIFRoZSBhbW91bnQgb2Ygd29yayBjb21wbGV0ZWQuCgoN
CgUEBQIBBRIEyAECBwoNCgUEBQIBARIEyAEIFgoNCgUEBQIBAxIEyAEZGmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1beta2::Operation::IndexOperationMetadata ===
    # Fields for IndexOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: index Type: 9 ()
    # Field: state Type: 14 (.google.firestore.admin.v1beta2.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1beta2.Progress)

# === Message: Google::Firestore::Admin::V1beta2::Operation::FieldOperationMetadata ===
    # Fields for FieldOperationMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: field Type: 9 ()
    # Field: index_config_deltas Type: 11 (.google.firestore.admin.v1beta2.FieldOperationMetadata.IndexConfigDelta)
    # Field: state Type: 14 (.google.firestore.admin.v1beta2.OperationState)
    # Field: document_progress Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: bytes_progress Type: 11 (.google.firestore.admin.v1beta2.Progress)

# === Message: Google::Firestore::Admin::V1beta2::Operation::ExportDocumentsMetadata ===
    # Fields for ExportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1beta2.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::Operation::ImportDocumentsMetadata ===
    # Fields for ImportDocumentsMetadata
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_state Type: 14 (.google.firestore.admin.v1beta2.OperationState)
    # Field: progress_documents Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: progress_bytes Type: 11 (.google.firestore.admin.v1beta2.Progress)
    # Field: collection_ids Type: 9 ()
    # Field: input_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::Operation::ExportDocumentsResponse ===
    # Fields for ExportDocumentsResponse
    # Field: output_uri_prefix Type: 9 ()

# === Message: Google::Firestore::Admin::V1beta2::Operation::Progress ===
    # Fields for Progress
    # Field: estimated_work Type: 3 ()
    # Field: completed_work Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1beta2::Operation - Compiled Protocol Buffers messages for google/firestore/admin/v1beta2/operation.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1beta2::Operation;

    my $msg = Google::Firestore::Admin::V1beta2::Operation::IndexOperationMetadata->new({
        start_time => $start_time,
        end_time => $end_time,
        index => $index,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->start_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1beta2::Operation::IndexOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1beta2/operation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1beta2::Operation::IndexOperationMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation] results from
[FirestoreAdmin.CreateIndex][google.firestore.admin.v1beta2.FirestoreAdmin.CreateIndex].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<String>

The index resource that this operation is acting on. For example:
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/indexes/{index_id}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::OperationState>)

The state of the operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in bytes, of this operation.

=back

=head2 Google::Firestore::Admin::V1beta2::Operation::FieldOperationMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation] results from
[FirestoreAdmin.UpdateField][google.firestore.admin.v1beta2.FirestoreAdmin.UpdateField].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->field() >> / C<< $msg->field($value) >>

Type: C<String>

The field resource that this operation is acting on. For example:
`projects/{project_id}/databases/{database_id}/collectionGroups/{collection_id}/fields/{field_path}`

=item * C<< $msg->index_config_deltas() >> / C<< $msg->index_config_deltas($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::FieldOperationMetadata::IndexConfigDelta>)

A list of [IndexConfigDelta][google.firestore.admin.v1beta2.FieldOperationMetadata.IndexConfigDelta], which describe the intent of this
operation.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::OperationState>)

The state of the operation.

=item * C<< $msg->document_progress() >> / C<< $msg->document_progress($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->bytes_progress() >> / C<< $msg->bytes_progress($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in bytes, of this operation.

=back

=head2 Google::Firestore::Admin::V1beta2::Operation::ExportDocumentsMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation] results from
[FirestoreAdmin.ExportDocuments][google.firestore.admin.v1beta2.FirestoreAdmin.ExportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::OperationState>)

The state of the export operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids are being exported.

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Where the entities are being exported to.

=back

=head2 Google::Firestore::Admin::V1beta2::Operation::ImportDocumentsMetadata

Metadata for [google.longrunning.Operation][google.longrunning.Operation] results from
[FirestoreAdmin.ImportDocuments][google.firestore.admin.v1beta2.FirestoreAdmin.ImportDocuments].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this operation completed. Will be unset if operation still in
progress.

=item * C<< $msg->operation_state() >> / C<< $msg->operation_state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1beta2::OperationState>)

The state of the import operation.

=item * C<< $msg->progress_documents() >> / C<< $msg->progress_documents($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in documents, of this operation.

=item * C<< $msg->progress_bytes() >> / C<< $msg->progress_bytes($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1beta2::Operation::Progress>)

The progress, in bytes, of this operation.

=item * C<< $msg->collection_ids() >> / C<< $msg->collection_ids($value) >>

Type: C<String>

Which collection ids are being imported.

=item * C<< $msg->input_uri_prefix() >> / C<< $msg->input_uri_prefix($value) >>

Type: C<String>

The location of the documents being imported.

=back

=head2 Google::Firestore::Admin::V1beta2::Operation::ExportDocumentsResponse

Returned in the [google.longrunning.Operation][google.longrunning.Operation] response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_uri_prefix() >> / C<< $msg->output_uri_prefix($value) >>

Type: C<String>

Location of the output files. This can be used to begin an import
into Cloud Firestore (this project or another project) after the operation
completes successfully.

=back

=head2 Google::Firestore::Admin::V1beta2::Operation::Progress

Describes the progress of the operation.
Unit of work is generic and must be interpreted based on where [Progress][google.firestore.admin.v1beta2.Progress]
is used.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->estimated_work() >> / C<< $msg->estimated_work($value) >>

Type: C<Int64>

The amount of work estimated.

=item * C<< $msg->completed_work() >> / C<< $msg->completed_work($value) >>

Type: C<Int64>

The amount of work completed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1beta2::Operation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
