package Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine;

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
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2l0ZV9zZWFyY2hfZW5n
aW5lLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8imwIKEFNpdGVTZWFyY2hFbmdpbmUS
EgoEbmFtZRgBIAEoCVIEbmFtZTryAepB7gEKL2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9TaXRlU2VhcmNoRW5naW5lElBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vc2l0ZVNlYXJjaEVuZ2luZRJpcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xs
ZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zaXRlU2VhcmNoRW5naW5lIuIKCgpU
YXJnZXRTaXRlEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRI4ChRwcm92aWRlZF91cmlfcGF0
dGVybhgCIAEoCUIG4EEC4EEEUhJwcm92aWRlZFVyaVBhdHRlcm4SSQoEdHlwZRgDIAEoDjI1
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5UYXJnZXRTaXRlLlR5cGVS
BHR5cGUSJAoLZXhhY3RfbWF0Y2gYBiABKAhCA+BBBFIKZXhhY3RNYXRjaBI3ChVnZW5lcmF0
ZWRfdXJpX3BhdHRlcm4YBCABKAlCA+BBA1ITZ2VuZXJhdGVkVXJpUGF0dGVybhIrCg9yb290
X2RvbWFpbl91cmkYCiABKAlCA+BBA1INcm9vdERvbWFpblVyaRJ1ChZzaXRlX3ZlcmlmaWNh
dGlvbl9pbmZvGAcgASgLMjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNpdGVWZXJpZmljYXRpb25JbmZvQgPgQQNSFHNpdGVWZXJpZmljYXRpb25JbmZvEm0KD2lu
ZGV4aW5nX3N0YXR1cxgIIAEoDjI/Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5UYXJnZXRTaXRlLkluZGV4aW5nU3RhdHVzQgPgQQNSDmluZGV4aW5nU3RhdHVzEkAK
C3VwZGF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1
cGRhdGVUaW1lEmoKDmZhaWx1cmVfcmVhc29uGAkgASgLMj4uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLlRhcmdldFNpdGUuRmFpbHVyZVJlYXNvbkID4EEDUg1mYWls
dXJlUmVhc29uGtABCg1GYWlsdXJlUmVhc29uEnIKDXF1b3RhX2ZhaWx1cmUYASABKAsySy5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuVGFyZ2V0U2l0ZS5GYWlsdXJl
UmVhc29uLlF1b3RhRmFpbHVyZUgAUgxxdW90YUZhaWx1cmUaQAoMUXVvdGFGYWlsdXJlEjAK
FHRvdGFsX3JlcXVpcmVkX3F1b3RhGAEgASgDUhJ0b3RhbFJlcXVpcmVkUXVvdGFCCQoHZmFp
bHVyZSI2CgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABILCgdJTkNMVURFEAESCwoHRVhD
TFVERRACImcKDkluZGV4aW5nU3RhdHVzEh8KG0lOREVYSU5HX1NUQVRVU19VTlNQRUNJRklF
RBAAEgsKB1BFTkRJTkcQARIKCgZGQUlMRUQQAhINCglTVUNDRUVERUQQAxIMCghERUxFVElO
RxAEOqEC6kGdAgopZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1RhcmdldFNpdGUS
anByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhU3RvcmVzL3tk
YXRhX3N0b3JlfS9zaXRlU2VhcmNoRW5naW5lL3RhcmdldFNpdGVzL3t0YXJnZXRfc2l0ZX0S
gwFwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMv
e2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NpdGVTZWFyY2hFbmdpbmUv
dGFyZ2V0U2l0ZXMve3RhcmdldF9zaXRlfSLMAgoUU2l0ZVZlcmlmaWNhdGlvbkluZm8SiAEK
F3NpdGVfdmVyaWZpY2F0aW9uX3N0YXRlGAEgASgOMlAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlNpdGVWZXJpZmljYXRpb25JbmZvLlNpdGVWZXJpZmljYXRpb25T
dGF0ZVIVc2l0ZVZlcmlmaWNhdGlvblN0YXRlEjsKC3ZlcmlmeV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdmVyaWZ5VGltZSJsChVTaXRlVmVyaWZpY2F0aW9u
U3RhdGUSJwojU0lURV9WRVJJRklDQVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIMCghWRVJJ
RklFRBABEg4KClVOVkVSSUZJRUQQAhIMCghFWEVNUFRFRBADQqECCihjb20uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhQhVTaXRlU2VhcmNoRW5naW5lUHJvdG9QAVpS
Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFhbHBoYS9kaXNjb3Zl
cnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCJEdvb2ds
ZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2dsZVxDbG91ZFxEaXNjb3Zl
cnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFh
bHBoYUrBLAoHEgUOAKwBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEEKCQoC
CCUSAxYAQQoICgEIEgMXAGkKCQoCCAsSAxcAaQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZADYKCQoCCAgSAxkANgoICgEIEgMaAEEKCQoCCAESAxoAQQoICgEIEgMbAC0KCQoCCCQS
AxsALQoICgEIEgMcAEEKCQoCCCkSAxwAQQoICgEIEgMdAEAKCQoCCC0SAx0AQAqHAQoCBAAS
BCEAKwEaeyBTaXRlU2VhcmNoRW5naW5lIGNhcHR1cmVzIERhdGFTdG9yZSBsZXZlbCBzaXRl
IHNlYXJjaCBwZXJzaXN0aW5nCiBjb25maWd1cmF0aW9ucy4gSXQgaXMgYSBzaW5nbGV0b24g
dmFsdWUgcGVyIGRhdGEgc3RvcmUuCgoKCgMEAAESAyEIGAoLCgMEAAcSBCICJgQKDQoFBAAH
nQgSBCICJgQKiwEKBAQAAgASAyoCEhp+IFRoZSBmdWxseSBxdWFsaWZpZWQgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgc2l0ZSBzZWFyY2ggZW5naW5lLgogRm9ybWF0OiBgcHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovc2l0ZVNlYXJjaEVuZ2luZWAKCgwKBQQAAgAFEgMq
AggKDAoFBAACAAESAyoJDQoMCgUEAAIAAxIDKhARCjYKAgQBEgUuAJQBARopIEEgdGFyZ2V0
IHNpdGUgZm9yIHRoZSBTaXRlU2VhcmNoRW5naW5lLgoKCgoDBAEBEgMuCBIKCwoDBAEHEgQv
AjMECg0KBQQBB50IEgQvAjMECjUKBAQBAwASBDYCQwMaJyBTaXRlIHNlYXJjaCBpbmRleGlu
ZyBmYWlsdXJlIHJlYXNvbnMuCgoMCgUEAQMAARIDNgoXCjMKBgQBAwADABIEOAQ8BRojIEZh
aWxlZCBkdWUgdG8gaW5zdWZmaWNpZW50IHF1b3RhLgoKDgoHBAEDAAMAARIDOAwYCn4KCAQB
AwADAAIAEgM7BiUabSBUaGlzIG51bWJlciBpcyBhbiBlc3RpbWF0aW9uIG9uIGhvdyBtdWNo
IHRvdGFsIHF1b3RhIHRoaXMgcHJvamVjdCBuZWVkcwogdG8gc3VjY2Vzc2Z1bGx5IGNvbXBs
ZXRlIGluZGV4aW5nLgoKEAoJBAEDAAMAAgAFEgM7BgsKEAoJBAEDAAMAAgABEgM7DCAKEAoJ
BAEDAAMAAgADEgM7IyQKIQoGBAEDAAgAEgQ/BEIFGhEgRmFpbHVyZSByZWFzb24uCgoOCgcE
AQMACAABEgM/ChEKMgoGBAEDAAIAEgNBBiUaIyBGYWlsZWQgZHVlIHRvIGluc3VmZmljaWVu
dCBxdW90YS4KCg4KBwQBAwACAAYSA0EGEgoOCgcEAQMAAgABEgNBEyAKDgoHBAEDAAIAAxID
QSMkCisKBAQBBAASBEYCUAMaHSBQb3NzaWJsZSB0YXJnZXQgc2l0ZSB0eXBlcy4KCgwKBQQB
BAABEgNGBwsKoAEKBgQBBAACABIDSQQZGpABIFRoaXMgdmFsdWUgaXMgdW51c2VkLiBJbiB0
aGlzIGNhc2UsIHNlcnZlciBiZWhhdmlvciBkZWZhdWx0cyB0bwogW1R5cGUuSU5DTFVERV1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlRhcmdldFNpdGUuVHlwZS5J
TkNMVURFXS4KCg4KBwQBBAACAAESA0kEFAoOCgcEAQQAAgACEgNJFxgKKQoGBAEEAAIBEgNM
BBAaGiBJbmNsdWRlIHRoZSB0YXJnZXQgc2l0ZS4KCg4KBwQBBAACAQESA0wECwoOCgcEAQQA
AgECEgNMDg8KKQoGBAEEAAICEgNPBBAaGiBFeGNsdWRlIHRoZSB0YXJnZXQgc2l0ZS4KCg4K
BwQBBAACAgESA08ECwoOCgcEAQQAAgICEgNPDg8KOAoEBAEEARIEUwJmAxoqIFRhcmdldCBz
aXRlIGluZGV4aW5nIHN0YXR1cyBlbnVtZXJhdGlvbi4KCgwKBQQBBAEBEgNTBxUKJwoGBAEE
AQIAEgNVBCQaGCBEZWZhdWx0cyB0byBTVUNDRUVERUQuCgoOCgcEAQQBAgABEgNVBB8KDgoH
BAEEAQIAAhIDVSIjCmQKBgQBBAECARIDWQQQGlUgVGhlIHRhcmdldCBzaXRlIGlzIGluIHRo
ZSB1cGRhdGUgcXVldWUgYW5kIHdpbGwgYmUgcGlja2VkIHVwIGJ5IGluZGV4aW5nCiBwaXBl
bGluZS4KCg4KBwQBBAECAQESA1kECwoOCgcEAQQBAgECEgNZDg8KNQoGBAEEAQICEgNcBA8a
JiBUaGUgdGFyZ2V0IHNpdGUgZmFpbHMgdG8gYmUgaW5kZXhlZC4KCg4KBwQBBAECAgESA1wE
CgoOCgcEAQQBAgICEgNcDQ4KMgoGBAEEAQIDEgNfBBIaIyBUaGUgdGFyZ2V0IHNpdGUgaGFz
IGJlZW4gaW5kZXhlZC4KCg4KBwQBBAECAwESA18EDQoOCgcEAQQBAgMCEgNfEBEK/gEKBgQB
BAECBBIDZQQRGu4BIFRoZSBwcmV2aW91c2x5IGluZGV4ZWQgdGFyZ2V0IHNpdGUgaGFzIGJl
ZW4gbWFya2VkIHRvIGJlIGRlbGV0ZWQuIFRoaXMgaXMKIGEgdHJhbnNpdGlvbmluZyBzdGF0
ZSB3aGljaCB3aWxsIHJlc3VsdGVkIGluIGVpdGhlcjoKIDEuIHRhcmdldCBzaXRlIGRlbGV0
ZWQgaWYgdW5pbmRleGluZyBpcyBzdWNjZXNzZnVsOwogMi4gc3RhdGUgcmV2ZXJ0cyB0byBT
VUNDRUVERUQgaWYgdGhlIHVuaW5kZXhpbmcgZmFpbHMuCgoOCgcEAQQBAgQBEgNlBAwKDgoH
BAEEAQIEAhIDZQ8QCoQCCgQEAQIAEgNrAj4a9gEgT3V0cHV0IG9ubHkuIFRoZSBmdWxseSBx
dWFsaWZpZWQgcmVzb3VyY2UgbmFtZSBvZiB0aGUgdGFyZ2V0IHNpdGUuCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9u
fS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9zaXRlU2VhcmNoRW5naW5lL3RhcmdldFNpdGVz
L3t0YXJnZXRfc2l0ZX1gCiBUaGUgYHRhcmdldF9zaXRlX2lkYCBpcyBzeXN0ZW0tZ2VuZXJh
dGVkLgoKDAoFBAECAAUSA2sCCAoMCgUEAQIAARIDawkNCgwKBQQBAgADEgNrEBEKDAoFBAEC
AAgSA2sSPQoPCggEAQIACJwIABIDaxM8CnkKBAQBAgESBG8CcgQaayBSZXF1aXJlZC4gSW5w
dXQgb25seS4gVGhlIHVzZXIgcHJvdmlkZWQgVVJJIHBhdHRlcm4gZnJvbSB3aGljaCB0aGUK
IGBnZW5lcmF0ZWRfdXJpX3BhdHRlcm5gIGlzIGdlbmVyYXRlZC4KCgwKBQQBAgEFEgNvAggK
DAoFBAECAQESA28JHQoMCgUEAQIBAxIDbyAhCg0KBQQBAgEIEgRvInIDCg8KCAQBAgEInAgA
EgNwBCoKDwoIBAECAQicCAESA3EELApiCgQEAQICEgN2AhAaVSBUaGUgdHlwZSBvZiB0aGUg
dGFyZ2V0IHNpdGUsIGUuZy4sIHdoZXRoZXIgdGhlIHNpdGUgaXMgdG8gYmUgaW5jbHVkZWQg
b3IKIGV4Y2x1ZGVkLgoKDAoFBAECAgYSA3YCBgoMCgUEAQICARIDdgcLCgwKBQQBAgIDEgN2
Dg8KpgMKBAQBAgMSA34CQhqYAyBJbnB1dCBvbmx5LiBJZiBzZXQgdG8gZmFsc2UsIGEgdXJp
X3BhdHRlcm4gaXMgZ2VuZXJhdGVkIHRvIGluY2x1ZGUgYWxsCiBwYWdlcyB3aG9zZSBhZGRy
ZXNzIGNvbnRhaW5zIHRoZSBwcm92aWRlZF91cmlfcGF0dGVybi4gSWYgc2V0IHRvIHRydWUs
IGFuCiB1cmlfcGF0dGVybiBpcyBnZW5lcmF0ZWQgdG8gdHJ5IHRvIGJlIGFuIGV4YWN0IG1h
dGNoIG9mIHRoZQogcHJvdmlkZWRfdXJpX3BhdHRlcm4gb3IganVzdCB0aGUgc3BlY2lmaWMg
cGFnZSBpZiB0aGUgcHJvdmlkZWRfdXJpX3BhdHRlcm4KIGlzIGEgc3BlY2lmaWMgb25lLiBw
cm92aWRlZF91cmlfcGF0dGVybiBpcyBhbHdheXMgbm9ybWFsaXplZCB0bwogZ2VuZXJhdGUg
dGhlIFVSSSBwYXR0ZXJuIHRvIGJlIHVzZWQgYnkgdGhlIHNlYXJjaCBlbmdpbmUuCgoMCgUE
AQIDBRIDfgIGCgwKBQQBAgMBEgN+BxIKDAoFBAECAwMSA34VFgoMCgUEAQIDCBIDfhdBCg8K
CAQBAgMInAgAEgN+GEAKWAoEBAECBBIEgQECTxpKIE91dHB1dCBvbmx5LiBUaGlzIGlzIHN5
c3RlbS1nZW5lcmF0ZWQgYmFzZWQgb24gdGhlIHByb3ZpZGVkX3VyaV9wYXR0ZXJuLgoKDQoF
BAECBAUSBIEBAggKDQoFBAECBAESBIEBCR4KDQoFBAECBAMSBIEBISIKDQoFBAECBAgSBIEB
I04KEAoIBAECBAicCAASBIEBJE0KRQoEBAECBRIEhAECSho3IE91dHB1dCBvbmx5LiBSb290
IGRvbWFpbiBvZiB0aGUgcHJvdmlkZWRfdXJpX3BhdHRlcm4uCgoNCgUEAQIFBRIEhAECCAoN
CgUEAQIFARIEhAEJGAoNCgUEAQIFAxIEhAEbHQoNCgUEAQIFCBIEhAEeSQoQCggEAQIFCJwI
ABIEhAEfSApPCgQEAQIGEgaHAQKIATIaPyBPdXRwdXQgb25seS4gU2l0ZSBvd25lcnNoaXAg
YW5kIHZhbGlkaXR5IHZlcmlmaWNhdGlvbiBzdGF0dXMuCgoNCgUEAQIGBhIEhwECFgoNCgUE
AQIGARIEhwEXLQoNCgUEAQIGAxIEhwEwMQoNCgUEAQIGCBIEiAEGMQoQCggEAQIGCJwIABIE
iAEHMAovCgQEAQIHEgaLAQKMATIaHyBPdXRwdXQgb25seS4gSW5kZXhpbmcgc3RhdHVzLgoK
DQoFBAECBwYSBIsBAhAKDQoFBAECBwESBIsBESAKDQoFBAECBwMSBIsBIyQKDQoFBAECBwgS
BIwBBjEKEAoIBAECBwicCAASBIwBBzAKQwoEBAECCBIGjwECkAEyGjMgT3V0cHV0IG9ubHku
IFRoZSB0YXJnZXQgc2l0ZSdzIGxhc3QgdXBkYXRlZCB0aW1lLgoKDQoFBAECCAYSBI8BAhsK
DQoFBAECCAESBI8BHCcKDQoFBAECCAMSBI8BKisKDQoFBAECCAgSBJABBjEKEAoIBAECCAic
CAASBJABBzAKLAoEBAECCRIEkwECTxoeIE91dHB1dCBvbmx5LiBGYWlsdXJlIHJlYXNvbi4K
Cg0KBQQBAgkGEgSTAQIPCg0KBQQBAgkBEgSTARAeCg0KBQQBAgkDEgSTASEiCg0KBQQBAgkI
EgSTASNOChAKCAQBAgkInAgAEgSTASRNClIKAgQCEgaXAQCsAQEaRCBWZXJpZmljYXRpb24g
aW5mb3JtYXRpb24gZm9yIHRhcmdldCBzaXRlcyBpbiBhZHZhbmNlZCBzaXRlIHNlYXJjaC4K
CgsKAwQCARIElwEIHAoqCgQEAgQAEgaZAQKlAQMaGiBTaXRlIHZlcmlmaWNhdGlvbiBzdGF0
ZS4KCg0KBQQCBAABEgSZAQccCicKBgQCBAACABIEmwEELBoXIERlZmF1bHRzIHRvIFZFUklG
SUVELgoKDwoHBAIEAAIAARIEmwEEJwoPCgcEAgQAAgACEgSbASorCioKBgQCBAACARIEngEE
ERoaIFNpdGUgb3duZXJzaGlwIHZlcmlmaWVkLgoKDwoHBAIEAAIBARIEngEEDAoPCgcEAgQA
AgECEgSeAQ8QCk0KBgQCBAACAhIEoQEEExo9IFNpdGUgb3duZXJzaGlwIHBlbmRpbmcgdmVy
aWZpY2F0aW9uIG9yIHZlcmlmaWNhdGlvbiBmYWlsZWQuCgoPCgcEAgQAAgIBEgShAQQOCg8K
BwQCBAACAgISBKEBERIKWgoGBAIEAAIDEgSkAQQRGkogU2l0ZSBleGVtcHQgZnJvbSB2ZXJp
ZmljYXRpb24sIGUuZy4sIGEgcHVibGljIHdlYnNpdGUgdGhhdCBvcGVucyB0byBhbGwuCgoP
CgcEAgQAAgMBEgSkAQQMCg8KBwQCBAACAwISBKQBDxAKTgoEBAICABIEqAECNBpAIFNpdGUg
dmVyaWZpY2F0aW9uIHN0YXRlIGluZGljYXRpbmcgdGhlIG93bmVyc2hpcCBhbmQgdmFsaWRp
dHkuCgoNCgUEAgIABhIEqAECFwoNCgUEAgIAARIEqAEYLwoNCgUEAgIAAxIEqAEyMwouCgQE
AgIBEgSrAQIsGiAgTGF0ZXN0IHNpdGUgdmVyaWZpY2F0aW9uIHRpbWUuCgoNCgUEAgIBBhIE
qwECGwoNCgUEAgIBARIEqwEcJwoNCgUEAgIBAxIEqwEqK2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine ===
    # Fields for SiteSearchEngine
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::TargetSite ===
    # Fields for TargetSite
    # Field: name Type: 9 ()
    # Field: provided_uri_pattern Type: 9 ()
    # Field: type Type: 14 (.google.cloud.discoveryengine.v1alpha.TargetSite.Type)
    # Field: exact_match Type: 8 ()
    # Field: generated_uri_pattern Type: 9 ()
    # Field: root_domain_uri Type: 9 ()
    # Field: site_verification_info Type: 11 (.google.cloud.discoveryengine.v1alpha.SiteVerificationInfo)
    # Field: indexing_status Type: 14 (.google.cloud.discoveryengine.v1alpha.TargetSite.IndexingStatus)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: failure_reason Type: 11 (.google.cloud.discoveryengine.v1alpha.TargetSite.FailureReason)

# Enum: TargetSite::Type
our $TargetSite_TYPE_UNSPECIFIED = 0;
our $TargetSite_INCLUDE = 1;
our $TargetSite_EXCLUDE = 2;

# Enum: TargetSite::IndexingStatus
our $TargetSite_INDEXING_STATUS_UNSPECIFIED = 0;
our $TargetSite_PENDING = 1;
our $TargetSite_FAILED = 2;
our $TargetSite_SUCCEEDED = 3;
our $TargetSite_DELETING = 4;

# === Message: Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteVerificationInfo ===
    # Fields for SiteVerificationInfo
    # Field: site_verification_state Type: 14 (.google.cloud.discoveryengine.v1alpha.SiteVerificationInfo.SiteVerificationState)
    # Field: verify_time Type: 11 (.google.protobuf.Timestamp)

# Enum: SiteVerificationInfo::SiteVerificationState
our $SiteVerificationInfo_SITE_VERIFICATION_STATE_UNSPECIFIED = 0;
our $SiteVerificationInfo_VERIFIED = 1;
our $SiteVerificationInfo_UNVERIFIED = 2;
our $SiteVerificationInfo_EXEMPTED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/site_search_engine.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/site_search_engine.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteSearchEngine

SiteSearchEngine captures DataStore level site search persisting
configurations. It is a singleton value per data store.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully qualified resource name of the site search engine.
Format: `projects/*/locations/*/dataStores/*/siteSearchEngine`

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::TargetSite

A target site for the SiteSearchEngine.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The fully qualified resource name of the target site.
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/siteSearchEngine/targetSites/{target_site}`
The `target_site_id` is system-generated.

=item * C<< $msg->provided_uri_pattern() >> / C<< $msg->provided_uri_pattern($value) >>

Type: C<String>

Required. Input only. The user provided URI pattern from which the
`generated_uri_pattern` is generated.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::TargetSite::Type>)

The type of the target site, e.g., whether the site is to be included or
excluded.

=item * C<< $msg->exact_match() >> / C<< $msg->exact_match($value) >>

Type: C<Bool>

Input only. If set to false, a uri_pattern is generated to include all
pages whose address contains the provided_uri_pattern. If set to true, an
uri_pattern is generated to try to be an exact match of the
provided_uri_pattern or just the specific page if the provided_uri_pattern
is a specific one. provided_uri_pattern is always normalized to
generate the URI pattern to be used by the search engine.

=item * C<< $msg->generated_uri_pattern() >> / C<< $msg->generated_uri_pattern($value) >>

Type: C<String>

Output only. This is system-generated based on the provided_uri_pattern.

=item * C<< $msg->root_domain_uri() >> / C<< $msg->root_domain_uri($value) >>

Type: C<String>

Output only. Root domain of the provided_uri_pattern.

=item * C<< $msg->site_verification_info() >> / C<< $msg->site_verification_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteVerificationInfo>)

Output only. Site ownership and validity verification status.

=item * C<< $msg->indexing_status() >> / C<< $msg->indexing_status($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::TargetSite::IndexingStatus>)

Output only. Indexing status.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The target site's last updated time.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::TargetSite::FailureReason>)

Output only. Failure reason.

=back

=head3 Enum: TargetSite::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<INCLUDE> => C<1>

=item * C<EXCLUDE> => C<2>

=back

=head3 Enum: TargetSite::IndexingStatus

=over 4

=item * C<INDEXING_STATUS_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<FAILED> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::SiteVerificationInfo

Verification information for target sites in advanced site search.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->site_verification_state() >> / C<< $msg->site_verification_state($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SiteVerificationInfo::SiteVerificationState>)

Site verification state indicating the ownership and validity.

=item * C<< $msg->verify_time() >> / C<< $msg->verify_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Latest site verification time.

=back

=head3 Enum: SiteVerificationInfo::SiteVerificationState

=over 4

=item * C<SITE_VERIFICATION_STATE_UNSPECIFIED> => C<0>

=item * C<VERIFIED> => C<1>

=item * C<UNVERIFIED> => C<2>

=item * C<EXEMPTED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::SiteSearchEngine::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
