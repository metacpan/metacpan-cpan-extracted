package Google::Cloud::Certificatemanager::V1::TrustConfig;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvY2VydGlmaWNhdGVtYW5hZ2VyL3YxL3RydXN0X2NvbmZpZy5wcm90
bxIiZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3By
b3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8i3wEKF0xpc3RUcnVzdENvbmZpZ3NSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEj
CiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIgCglwYWdlX3Np
emUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdl
VG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghvcmRlcl9ieRgFIAEoCUID
4EEBUgdvcmRlckJ5IroBChhMaXN0VHJ1c3RDb25maWdzUmVzcG9uc2USVAoNdHJ1c3RfY29u
ZmlncxgBIAMoCzIvLmdvb2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEuVHJ1c3RD
b25maWdSDHRydXN0Q29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxlImIKFUdldFRydXN0Q29u
ZmlnUmVxdWVzdBJJCgRuYW1lGAEgASgJQjXgQQL6QS8KLWNlcnRpZmljYXRlbWFuYWdlci5n
b29nbGVhcGlzLmNvbS9UcnVzdENvbmZpZ1IEbmFtZSLjAQoYQ3JlYXRlVHJ1c3RDb25maWdS
ZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5j
b20vTG9jYXRpb25SBnBhcmVudBIrCg90cnVzdF9jb25maWdfaWQYAiABKAlCA+BBAlINdHJ1
c3RDb25maWdJZBJXCgx0cnVzdF9jb25maWcYAyABKAsyLy5nb29nbGUuY2xvdWQuY2VydGlm
aWNhdGVtYW5hZ2VyLnYxLlRydXN0Q29uZmlnQgPgQQJSC3RydXN0Q29uZmlnIrUBChhVcGRh
dGVUcnVzdENvbmZpZ1JlcXVlc3QSVwoMdHJ1c3RfY29uZmlnGAEgASgLMi8uZ29vZ2xlLmNs
b3VkLmNlcnRpZmljYXRlbWFuYWdlci52MS5UcnVzdENvbmZpZ0ID4EECUgt0cnVzdENvbmZp
ZxJACgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BB
AlIKdXBkYXRlTWFzayJ+ChhEZWxldGVUcnVzdENvbmZpZ1JlcXVlc3QSSQoEbmFtZRgBIAEo
CUI14EEC+kEvCi1jZXJ0aWZpY2F0ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVHJ1c3RDb25m
aWdSBG5hbWUSFwoEZXRhZxgCIAEoCUID4EEBUgRldGFnIsUMCgtUcnVzdENvbmZpZxIXCgRu
YW1lGAEgASgJQgPgQQhSBG5hbWUSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSWAoGbGFiZWxz
GAQgAygLMjsuZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MS5UcnVzdENvbmZp
Zy5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSJQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SEgoEZXRhZxgGIAEoCVIEZXRhZxJ7ChNzcGlmZmVfdHJ1c3Rfc3RvcmVz
GAcgAygLMkYuZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MS5UcnVzdENvbmZp
Zy5TcGlmZmVUcnVzdFN0b3Jlc0VudHJ5QgPgQQFSEXNwaWZmZVRydXN0U3RvcmVzEmIKDHRy
dXN0X3N0b3JlcxgIIAMoCzI6Lmdvb2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEu
VHJ1c3RDb25maWcuVHJ1c3RTdG9yZUID4EEBUgt0cnVzdFN0b3JlcxKGAQoYYWxsb3dsaXN0
ZWRfY2VydGlmaWNhdGVzGAkgAygLMkYuZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdl
ci52MS5UcnVzdENvbmZpZy5BbGxvd2xpc3RlZENlcnRpZmljYXRlQgPgQQFSF2FsbG93bGlz
dGVkQ2VydGlmaWNhdGVzElgKBHRhZ3MYCiADKAsyOS5nb29nbGUuY2xvdWQuY2VydGlmaWNh
dGVtYW5hZ2VyLnYxLlRydXN0Q29uZmlnLlRhZ3NFbnRyeUIJ4EEE4EEF4EEBUgR0YWdzGkAK
C1RydXN0QW5jaG9yEikKD3BlbV9jZXJ0aWZpY2F0ZRgBIAEoCUgAUg5wZW1DZXJ0aWZpY2F0
ZUIGCgRraW5kGkMKDkludGVybWVkaWF0ZUNBEikKD3BlbV9jZXJ0aWZpY2F0ZRgBIAEoCUgA
Ug5wZW1DZXJ0aWZpY2F0ZUIGCgRraW5kGuMBCgpUcnVzdFN0b3JlEmUKDXRydXN0X2FuY2hv
cnMYASADKAsyOy5nb29nbGUuY2xvdWQuY2VydGlmaWNhdGVtYW5hZ2VyLnYxLlRydXN0Q29u
ZmlnLlRydXN0QW5jaG9yQgPgQQFSDHRydXN0QW5jaG9ycxJuChBpbnRlcm1lZGlhdGVfY2Fz
GAIgAygLMj4uZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRlbWFuYWdlci52MS5UcnVzdENvbmZp
Zy5JbnRlcm1lZGlhdGVDQUID4EEBUg9pbnRlcm1lZGlhdGVDYXMaRgoWQWxsb3dsaXN0ZWRD
ZXJ0aWZpY2F0ZRIsCg9wZW1fY2VydGlmaWNhdGUYASABKAlCA+BBAlIOcGVtQ2VydGlmaWNh
dGUaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZh
bHVlOgI4ARqAAQoWU3BpZmZlVHJ1c3RTdG9yZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJQ
CgV2YWx1ZRgCIAEoCzI6Lmdvb2dsZS5jbG91ZC5jZXJ0aWZpY2F0ZW1hbmFnZXIudjEuVHJ1
c3RDb25maWcuVHJ1c3RTdG9yZVIFdmFsdWU6AjgBGjcKCVRhZ3NFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOpMB6kGPAQotY2VydGlmaWNhdGVt
YW5hZ2VyLmdvb2dsZWFwaXMuY29tL1RydXN0Q29uZmlnEkNwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vdHJ1c3RDb25maWdzL3t0cnVzdF9jb25maWd9Kgx0cnVz
dENvbmZpZ3MyC3RydXN0Q29uZmlnQoYCCiZjb20uZ29vZ2xlLmNsb3VkLmNlcnRpZmljYXRl
bWFuYWdlci52MUIQVHJ1c3RDb25pZmdQcm90b1ABWlZjbG91ZC5nb29nbGUuY29tL2dvL2Nl
cnRpZmljYXRlbWFuYWdlci9hcGl2MS9jZXJ0aWZpY2F0ZW1hbmFnZXJwYjtjZXJ0aWZpY2F0
ZW1hbmFnZXJwYqoCIkdvb2dsZS5DbG91ZC5DZXJ0aWZpY2F0ZU1hbmFnZXIuVjHKAiJHb29n
bGVcQ2xvdWRcQ2VydGlmaWNhdGVNYW5hZ2VyXFYx6gIlR29vZ2xlOjpDbG91ZDo6Q2VydGlm
aWNhdGVNYW5hZ2VyOjpWMUrkQgoHEgUOAPEBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKgoJ
CgIDAxIDFQApCggKAQgSAxcAPwoJCgIIJRIDFwA/CggKAQgSAxgAbQoJCgIICxIDGABtCggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMQoJCgIICBIDGgAxCggKAQgSAxsAPwoJCgII
ARIDGwA/CggKAQgSAxwAPwoJCgIIKRIDHAA/CggKAQgSAx0APgoJCgIILRIDHQA+CjgKAgQA
EgQgADkBGiwgUmVxdWVzdCBmb3IgdGhlIGBMaXN0VHJ1c3RDb25maWdzYCBtZXRob2QuCgoK
CgMEAAESAyAIHwqUAQoEBAACABIEIwIoBBqFASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5k
IGxvY2F0aW9uIGZyb20gd2hpY2ggdGhlIFRydXN0Q29uZmlncyBzaG91bGQgYmUKIGxpc3Rl
ZCwgc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoK
DAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkPCgwKBQQAAgADEgMjEhMKDQoFBAACAAgSBCMU
KAMKDwoIBAACAAicCAASAyQEKgoPCgcEAAIACJ8IEgQlBCcFCksKBAQAAgESAysCPxo+IE9w
dGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiBUcnVzdENvbmZpZ3MgdG8gcmV0dXJuIHBlciBj
YWxsLgoKDAoFBAACAQUSAysCBwoMCgUEAAIBARIDKwgRCgwKBQQAAgEDEgMrFBUKDAoFBAAC
AQgSAysWPgoPCggEAAIBCJwIABIDKxc9CtkBCgQEAAICEgMwAkEaywEgT3B0aW9uYWwuIFRo
ZSB2YWx1ZSByZXR1cm5lZCBieSB0aGUgbGFzdCBgTGlzdFRydXN0Q29uZmlnc1Jlc3BvbnNl
YC4KIEluZGljYXRlcyB0aGF0IHRoaXMgaXMgYSBjb250aW51YXRpb24gb2YgYSBwcmlvciBg
TGlzdFRydXN0Q29uZmlnc2AgY2FsbCwKIGFuZCB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJl
dHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoMCgUEAAICBRIDMAIICgwKBQQAAgIBEgMw
CRMKDAoFBAACAgMSAzAWFwoMCgUEAAICCBIDMBhACg8KCAQAAgIInAgAEgMwGT8KUQoEBAAC
AxIDMwI9GkQgT3B0aW9uYWwuIEZpbHRlciBleHByZXNzaW9uIHRvIHJlc3RyaWN0IHRoZSBU
cnVzdENvbmZpZ3MgcmV0dXJuZWQuCgoMCgUEAAIDBRIDMwIICgwKBQQAAgMBEgMzCQ8KDAoF
BAACAwMSAzMSEwoMCgUEAAIDCBIDMxQ8Cg8KCAQAAgMInAgAEgMzFTsK2QEKBAQAAgQSAzgC
PxrLASBPcHRpb25hbC4gQSBsaXN0IG9mIFRydXN0Q29uZmlnIGZpZWxkIG5hbWVzIHVzZWQg
dG8gc3BlY2lmeSB0aGUgb3JkZXIgb2YKIHRoZSByZXR1cm5lZCByZXN1bHRzLiBUaGUgZGVm
YXVsdCBzb3J0aW5nIG9yZGVyIGlzIGFzY2VuZGluZy4gVG8gc3BlY2lmeQogZGVzY2VuZGlu
ZyBvcmRlciBmb3IgYSBmaWVsZCwgYWRkIGEgc3VmZml4IGAiIGRlc2MiYC4KCgwKBQQAAgQF
EgM4AggKDAoFBAACBAESAzgJEQoMCgUEAAIEAxIDOBQVCgwKBQQAAgQIEgM4Fj4KDwoIBAAC
BAicCAASAzgXPQo5CgIEARIEPABHARotIFJlc3BvbnNlIGZvciB0aGUgYExpc3RUcnVzdENv
bmZpZ3NgIG1ldGhvZC4KCgoKAwQBARIDPAggCj4KBAQBAgASAz4CKRoxIEEgbGlzdCBvZiBU
cnVzdENvbmZpZ3MgZm9yIHRoZSBwYXJlbnQgcmVzb3VyY2UuCgoMCgUEAQIABBIDPgIKCgwK
BQQBAgAGEgM+CxYKDAoFBAECAAESAz4XJAoMCgUEAQIAAxIDPicoCugBCgQEAQIBEgNDAh0a
2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4gdGhvc2UgYXBwZWFyaW5n
IGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9rZW5gIGlzIGluY2x1ZGVk
LiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwgdGhpcwogbWV0aG9kIGFn
YWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2VuYCBhcyBgcGFnZV90b2tl
bmAuCgoMCgUEAQIBBRIDQwIICgwKBQQBAgEBEgNDCRgKDAoFBAECAQMSA0MbHAozCgQEAQIC
EgNGAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCgwKBQQBAgIE
EgNGAgoKDAoFBAECAgUSA0YLEQoMCgUEAQICARIDRhIdCgwKBQQBAgIDEgNGICEKNgoCBAIS
BEoAUwEaKiBSZXF1ZXN0IGZvciB0aGUgYEdldFRydXN0Q29uZmlnYCBtZXRob2QuCgoKCgME
AgESA0oIHQqAAQoEBAICABIETQJSBBpyIFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIFRydXN0
Q29uZmlnIHRvIGRlc2NyaWJlLiBNdXN0IGJlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL3RydXN0Q29uZmlncy8qYC4KCgwKBQQCAgAFEgNNAggKDAoFBAICAAES
A00JDQoMCgUEAgIAAxIDTRARCg0KBQQCAgAIEgRNElIDCg8KCAQCAgAInAgAEgNOBCoKDwoH
BAICAAifCBIETwRRBQo5CgIEAxIEVgBmARotIFJlcXVlc3QgZm9yIHRoZSBgQ3JlYXRlVHJ1
c3RDb25maWdgIG1ldGhvZC4KCgoKAwQDARIDVgggCnIKBAQDAgASBFkCXgQaZCBSZXF1aXJl
ZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0aGUgVHJ1c3RDb25maWcuIE11c3QgYmUgaW4g
dGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDAoFBAMCAAUSA1kCCAoM
CgUEAwIAARIDWQkPCgwKBQQDAgADEgNZEhMKDQoFBAMCAAgSBFkUXgMKDwoIBAMCAAicCAAS
A1oEKgoPCgcEAwIACJ8IEgRbBF0FCmsKBAQDAgESA2ICRhpeIFJlcXVpcmVkLiBBIHVzZXIt
cHJvdmlkZWQgbmFtZSBvZiB0aGUgVHJ1c3RDb25maWcuIE11c3QgbWF0Y2ggdGhlIHJlZ2V4
cAogYFthLXowLTktXXsxLDYzfWAuCgoMCgUEAwIBBRIDYgIICgwKBQQDAgEBEgNiCRgKDAoF
BAMCAQMSA2IbHAoMCgUEAwIBCBIDYh1FCg8KCAQDAgEInAgAEgNiHkQKQwoEBAMCAhIDZQJI
GjYgUmVxdWlyZWQuIEEgZGVmaW5pdGlvbiBvZiB0aGUgVHJ1c3RDb25maWcgdG8gY3JlYXRl
LgoKDAoFBAMCAgYSA2UCDQoMCgUEAwICARIDZQ4aCgwKBQQDAgIDEgNlHR4KDAoFBAMCAggS
A2UfRwoPCggEAwICCJwIABIDZSBGCjkKAgQEEgRpAHIBGi0gUmVxdWVzdCBmb3IgdGhlIGBV
cGRhdGVUcnVzdENvbmZpZ2AgbWV0aG9kLgoKCgoDBAQBEgNpCCAKQwoEBAQCABIDawJIGjYg
UmVxdWlyZWQuIEEgZGVmaW5pdGlvbiBvZiB0aGUgVHJ1c3RDb25maWcgdG8gdXBkYXRlLgoK
DAoFBAQCAAYSA2sCDQoMCgUEBAIAARIDaw4aCgwKBQQEAgADEgNrHR4KDAoFBAQCAAgSA2sf
RwoPCggEBAIACJwIABIDayBGCsIBCgQEBAIBEgRwAnEvGrMBIFJlcXVpcmVkLiBUaGUgdXBk
YXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVzb3VyY2UuIEZvciB0aGUgYEZpZWxkTWFza2AK
IGRlZmluaXRpb24sIHNlZQogaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9j
b2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9nb29nbGUucHJvdG9idWYjZmllbGRtYXNrLgoK
DAoFBAQCAQYSA3ACGwoMCgUEBAIBARIDcBwnCgwKBQQEAgEDEgNwKisKDAoFBAQCAQgSA3EG
LgoPCggEBAIBCJwIABIDcQctCjoKAgQFEgV1AIMBARotIFJlcXVlc3QgZm9yIHRoZSBgRGVs
ZXRlVHJ1c3RDb25maWdgIG1ldGhvZC4KCgoKAwQFARIDdQggCn4KBAQFAgASBHgCfQQacCBS
ZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBUcnVzdENvbmZpZyB0byBkZWxldGUuIE11c3QgYmUg
aW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovdHJ1c3RDb25maWdzLypg
LgoKDAoFBAUCAAUSA3gCCAoMCgUEBQIAARIDeAkNCgwKBQQFAgADEgN4EBEKDQoFBAUCAAgS
BHgSfQMKDwoIBAUCAAicCAASA3kEKgoPCgcEBQIACJ8IEgR6BHwFCs0BCgQEBQIBEgSCAQI7
Gr4BIE9wdGlvbmFsLiBUaGUgY3VycmVudCBldGFnIG9mIHRoZSBUcnVzdENvbmZpZy4KIElm
IGFuIGV0YWcgaXMgcHJvdmlkZWQgYW5kIGRvZXMgbm90IG1hdGNoIHRoZSBjdXJyZW50IGV0
YWcgb2YgdGhlIHJlc291cmNlLAogZGVsZXRpb24gd2lsbCBiZSBibG9ja2VkIGFuZCBhbiBB
Qk9SVEVEIGVycm9yIHdpbGwgYmUgcmV0dXJuZWQuCgoNCgUEBQIBBRIEggECCAoNCgUEBQIB
ARIEggEJDQoNCgUEBQIBAxIEggEQEQoNCgUEBQIBCBIEggESOgoQCggEBQIBCJwIABIEggET
OQonCgIEBhIGhgEA8QEBGhkgRGVmaW5lcyBhIHRydXN0IGNvbmZpZy4KCgsKAwQGARIEhgEI
EwoNCgMEBgcSBocBAowBBAoPCgUEBgedCBIGhwECjAEECikKBAQGAwASBo8BApcBAxoZIERl
ZmluZXMgYSB0cnVzdCBhbmNob3IuCgoNCgUEBgMAARIEjwEKFQo3CgYEBgMACAASBpEBBJYB
BRolIEtpbmQgb2YgdGhlIHRydXN0IGFuY2hvci4gUmVxdWlyZWQuCgoPCgcEBgMACAABEgSR
AQoOCoYBCgYEBgMAAgASBJUBBiEadiBQRU0gcm9vdCBjZXJ0aWZpY2F0ZSBvZiB0aGUgUEtJ
IHVzZWQgZm9yIHZhbGlkYXRpb24uCgogRWFjaCBjZXJ0aWZpY2F0ZSBwcm92aWRlZCBpbiBQ
RU0gZm9ybWF0IG1heSBvY2N1cHkgdXAgdG8gNWtCLgoKDwoHBAYDAAIABRIElQEGDAoPCgcE
BgMAAgABEgSVAQ0cCg8KBwQGAwACAAMSBJUBHyAKLQoEBAYDARIGmgECowEDGh0gRGVmaW5l
cyBhbiBpbnRlcm1lZGlhdGUgQ0EuCgoNCgUEBgMBARIEmgEKGAo6CgYEBgMBCAASBpwBBKIB
BRooIEtpbmQgb2YgdGhlIGludGVybWVkaWF0ZSBDQS4gUmVxdWlyZWQuCgoPCgcEBgMBCAAB
EgScAQoOCpsBCgYEBgMBAgASBKEBBiEaigEgUEVNIGludGVybWVkaWF0ZSBjZXJ0aWZpY2F0
ZSB1c2VkIGZvciBidWlsZGluZyB1cCBwYXRocwogZm9yIHZhbGlkYXRpb24uCgogRWFjaCBj
ZXJ0aWZpY2F0ZSBwcm92aWRlZCBpbiBQRU0gZm9ybWF0IG1heSBvY2N1cHkgdXAgdG8gNWtC
LgoKDwoHBAYDAQIABRIEoQEGDAoPCgcEBgMBAgABEgShAQ0cCg8KBwQGAwECAAMSBKEBHyAK
KAoEBAYDAhIGpgECswEDGhggRGVmaW5lcyBhIHRydXN0IHN0b3JlLgoKDQoFBAYDAgESBKYB
ChQKdwoGBAYDAgIAEgapAQSqATEaZSBPcHRpb25hbC4gTGlzdCBvZiBUcnVzdCBBbmNob3Jz
IHRvIGJlIHVzZWQgd2hpbGUgcGVyZm9ybWluZyB2YWxpZGF0aW9uCiBhZ2FpbnN0IGEgZ2l2
ZW4gVHJ1c3RTdG9yZS4KCg8KBwQGAwICAAQSBKkBBAwKDwoHBAYDAgIABhIEqQENGAoPCgcE
BgMCAgABEgSpARkmCg8KBwQGAwICAAMSBKkBKSoKDwoHBAYDAgIACBIEqgEIMAoSCgoEBgMC
AgAInAgAEgSqAQkvCt4BCgYEBgMCAgESBrEBBLIBMRrLASBPcHRpb25hbC4gU2V0IG9mIGlu
dGVybWVkaWF0ZSBDQSBjZXJ0aWZpY2F0ZXMgdXNlZCBmb3IgdGhlIHBhdGggYnVpbGRpbmcK
IHBoYXNlIG9mIGNoYWluIHZhbGlkYXRpb24uCgogVGhlIGZpZWxkIGlzIGN1cnJlbnRseSBu
b3Qgc3VwcG9ydGVkIGlmIFRydXN0Q29uZmlnIGlzIHVzZWQgZm9yIHRoZQogd29ya2xvYWQg
Y2VydGlmaWNhdGUgZmVhdHVyZS4KCg8KBwQGAwICAQQSBLEBBAwKDwoHBAYDAgIBBhIEsQEN
GwoPCgcEBgMCAgEBEgSxARwsCg8KBwQGAwICAQMSBLEBLzAKDwoHBAYDAgIBCBIEsgEIMAoS
CgoEBgMCAgEInAgAEgSyAQkvCjUKBAQGAwMSBrYBAroBAxolIERlZmluZXMgYW4gYWxsb3ds
aXN0ZWQgY2VydGlmaWNhdGUuCgoNCgUEBgMDARIEtgEKIAqUAQoGBAYDAwIAEgS5AQRIGoMB
IFJlcXVpcmVkLiBQRU0gY2VydGlmaWNhdGUgdGhhdCBpcyBhbGxvd2xpc3RlZC4gVGhlIGNl
cnRpZmljYXRlIGNhbiBiZSB1cAogdG8gNWsgYnl0ZXMsIGFuZCBtdXN0IGJlIGEgcGFyc2Vh
YmxlIFguNTA5IGNlcnRpZmljYXRlLgoKDwoHBAYDAwIABRIEuQEECgoPCgcEBgMDAgABEgS5
AQsaCg8KBwQGAwMCAAMSBLkBHR4KDwoHBAYDAwIACBIEuQEfRwoSCgoEBgMDAgAInAgAEgS5
ASBGCqwBCgQEBgIAEgS/AQI9Gp0BIElkZW50aWZpZXIuIEEgdXNlci1kZWZpbmVkIG5hbWUg
b2YgdGhlIHRydXN0IGNvbmZpZy4gVHJ1c3RDb25maWcgbmFtZXMgbXVzdAogYmUgdW5pcXVl
IGdsb2JhbGx5IGFuZCBtYXRjaCBwYXR0ZXJuCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi90
cnVzdENvbmZpZ3MvKmAuCgoNCgUEBgIABRIEvwECCAoNCgUEBgIAARIEvwEJDQoNCgUEBgIA
AxIEvwEQEQoNCgUEBgIACBIEvwESPAoQCggEBgIACJwIABIEvwETOwpHCgQEBgIBEgbCAQLD
ATIaNyBPdXRwdXQgb25seS4gVGhlIGNyZWF0aW9uIHRpbWVzdGFtcCBvZiBhIFRydXN0Q29u
ZmlnLgoKDQoFBAYCAQYSBMIBAhsKDQoFBAYCAQESBMIBHCcKDQoFBAYCAQMSBMIBKisKDQoF
BAYCAQgSBMMBBjEKEAoIBAYCAQicCAASBMMBBzAKSgoEBAYCAhIGxgECxwEyGjogT3V0cHV0
IG9ubHkuIFRoZSBsYXN0IHVwZGF0ZSB0aW1lc3RhbXAgb2YgYSBUcnVzdENvbmZpZy4KCg0K
BQQGAgIGEgTGAQIbCg0KBQQGAgIBEgTGARwnCg0KBQQGAgIDEgTGASorCg0KBQQGAgIIEgTH
AQYxChAKCAQGAgIInAgAEgTHAQcwCkYKBAQGAgMSBMoBAkoaOCBPcHRpb25hbC4gU2V0IG9m
IGxhYmVscyBhc3NvY2lhdGVkIHdpdGggYSBUcnVzdENvbmZpZy4KCg0KBQQGAgMGEgTKAQIV
Cg0KBQQGAgMBEgTKARYcCg0KBQQGAgMDEgTKAR8gCg0KBQQGAgMIEgTKASFJChAKCAQGAgMI
nAgAEgTKASJIClYKBAQGAgQSBM0BAkIaSCBPcHRpb25hbC4gT25lIG9yIG1vcmUgcGFyYWdy
YXBocyBvZiB0ZXh0IGRlc2NyaXB0aW9uIG9mIGEgVHJ1c3RDb25maWcuCgoNCgUEBgIEBRIE
zQECCAoNCgUEBgIEARIEzQEJFAoNCgUEBgIEAxIEzQEXGAoNCgUEBgIECBIEzQEZQQoQCggE
BgIECJwIABIEzQEaQArMAQoEBAYCBRIE0gECEhq9ASBUaGlzIGNoZWNrc3VtIGlzIGNvbXB1
dGVkIGJ5IHRoZSBzZXJ2ZXIgYmFzZWQgb24gdGhlIHZhbHVlIG9mIG90aGVyCiBmaWVsZHMs
IGFuZCBtYXkgYmUgc2VudCBvbiB1cGRhdGUgYW5kIGRlbGV0ZSByZXF1ZXN0cyB0byBlbnN1
cmUgdGhlCiBjbGllbnQgaGFzIGFuIHVwLXRvLWRhdGUgdmFsdWUgYmVmb3JlIHByb2NlZWRp
bmcuCgoNCgUEBgIFBRIE0gECCAoNCgUEBgIFARIE0gEJDQoNCgUEBgIFAxIE0gEQEQqDAQoE
BAYCBhIG1gEC1wEvGnMgT3B0aW9uYWwuIERlZmluZXMgYSBtYXBwaW5nIGZyb20gYSB0cnVz
dCBkb21haW4gdG8gYSBUcnVzdFN0b3JlLiBUaGlzIGlzCiB1c2VkIGZvciBTUElGRkUgY2Vy
dGlmaWNhdGUgdmFsaWRhdGlvbi4KCg0KBQQGAgYGEgTWAQIZCg0KBQQGAgYBEgTWARotCg0K
BQQGAgYDEgTWATAxCg0KBQQGAgYIEgTXAQYuChAKCAQGAgYInAgAEgTXAQctCo0CCgQEBgIH
EgTfAQJQGv4BIE9wdGlvbmFsLiBTZXQgb2YgdHJ1c3Qgc3RvcmVzIHRvIHBlcmZvcm0gdmFs
aWRhdGlvbiBhZ2FpbnN0LgoKIFRoaXMgZmllbGQgaXMgc3VwcG9ydGVkIHdoZW4gVHJ1c3RD
b25maWcgaXMgY29uZmlndXJlZCB3aXRoIExvYWQgQmFsYW5jZXJzLAogY3VycmVudGx5IG5v
dCBzdXBwb3J0ZWQgZm9yIFNQSUZGRSBjZXJ0aWZpY2F0ZSB2YWxpZGF0aW9uLgoKIE9ubHkg
b25lIFRydXN0U3RvcmUgc3BlY2lmaWVkIGlzIGN1cnJlbnRseSBhbGxvd2VkLgoKDQoFBAYC
BwQSBN8BAgoKDQoFBAYCBwYSBN8BCxUKDQoFBAYCBwESBN8BFiIKDQoFBAYCBwMSBN8BJSYK
DQoFBAYCBwgSBN8BJ08KEAoIBAYCBwicCAASBN8BKE4K/QEKBAQGAggSBuUBAuYBLxrsASBP
cHRpb25hbC4gQSBjZXJ0aWZpY2F0ZSBtYXRjaGluZyBhbiBhbGxvd2xpc3RlZCBjZXJ0aWZp
Y2F0ZSBpcyBhbHdheXMKIGNvbnNpZGVyZWQgdmFsaWQgYXMgbG9uZyBhcyB0aGUgY2VydGlm
aWNhdGUgaXMgcGFyc2VhYmxlLCBwcm9vZiBvZiBwcml2YXRlCiBrZXkgcG9zc2Vzc2lvbiBp
cyBlc3RhYmxpc2hlZCwgYW5kIGNvbnN0cmFpbnRzIG9uIHRoZSBjZXJ0aWZpY2F0ZSdzIFNB
TgogZmllbGQgYXJlIG1ldC4KCg0KBQQGAggEEgTlAQIKCg0KBQQGAggGEgTlAQshCg0KBQQG
AggBEgTlASI6Cg0KBQQGAggDEgTlAT0+Cg0KBQQGAggIEgTmAQYuChAKCAQGAggInAgAEgTm
AQctCrcBCgQEBgIJEgbsAQLwAQQapgEgT3B0aW9uYWwuIElucHV0IG9ubHkuIEltbXV0YWJs
ZS4gVGFnIGtleXMvdmFsdWVzIGRpcmVjdGx5IGJvdW5kIHRvIHRoaXMKIHJlc291cmNlLiBG
b3IgZXhhbXBsZToKICAgIjEyMy9lbnZpcm9ubWVudCI6ICJwcm9kdWN0aW9uIiwKICAgIjEy
My9jb3N0Q2VudGVyIjogIm1hcmtldGluZyIKCg0KBQQGAgkGEgTsAQIVCg0KBQQGAgkBEgTs
ARYaCg0KBQQGAgkDEgTsAR0fCg8KBQQGAgkIEgbsASDwAQMKEAoIBAYCCQicCAASBO0BBCwK
EAoIBAYCCQicCAESBO4BBCsKEAoIBAYCCQicCAISBO8BBCpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest ===
    # Fields for ListTrustConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsResponse ===
    # Fields for ListTrustConfigsResponse
    # Field: trust_configs Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::GetTrustConfigRequest ===
    # Fields for GetTrustConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::CreateTrustConfigRequest ===
    # Fields for CreateTrustConfigRequest
    # Field: parent Type: 9 ()
    # Field: trust_config_id Type: 9 ()
    # Field: trust_config Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig)

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::UpdateTrustConfigRequest ===
    # Fields for UpdateTrustConfigRequest
    # Field: trust_config Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::DeleteTrustConfigRequest ===
    # Fields for DeleteTrustConfigRequest
    # Field: name Type: 9 ()
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig ===
    # Fields for TrustConfig
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: spiffe_trust_stores Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig.SpiffeTrustStoresEntry)
    # Field: trust_stores Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig.TrustStore)
    # Field: allowlisted_certificates Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig.AllowlistedCertificate)
    # Field: tags Type: 11 (.google.cloud.certificatemanager.v1.TrustConfig.TagsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Certificatemanager::V1::TrustConfig - Compiled Protocol Buffers messages for google/cloud/certificatemanager/v1/trust_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Certificatemanager::V1::TrustConfig;

    my $msg = Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/certificatemanager/v1/trust_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsRequest

Request for the `ListTrustConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the TrustConfigs should be
listed, specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of TrustConfigs to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value returned by the last `ListTrustConfigsResponse`.
Indicates that this is a continuation of a prior `ListTrustConfigs` call,
and that the system should return the next page of data.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression to restrict the TrustConfigs returned.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. A list of TrustConfig field names used to specify the order of
the returned results. The default sorting order is ascending. To specify
descending order for a field, add a suffix `" desc"`.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::ListTrustConfigsResponse

Response for the `ListTrustConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->trust_configs() >> / C<< $msg->trust_configs($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig>)

A list of TrustConfigs for the parent resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::GetTrustConfigRequest

Request for the `GetTrustConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TrustConfig to describe. Must be in the format
`projects/*/locations/*/trustConfigs/*`.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::CreateTrustConfigRequest

Request for the `CreateTrustConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the TrustConfig. Must be in the format
`projects/*/locations/*`.

=item * C<< $msg->trust_config_id() >> / C<< $msg->trust_config_id($value) >>

Type: C<String>

Required. A user-provided name of the TrustConfig. Must match the regexp
`[a-z0-9-]{1,63}`.

=item * C<< $msg->trust_config() >> / C<< $msg->trust_config($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig>)

Required. A definition of the TrustConfig to create.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::UpdateTrustConfigRequest

Request for the `UpdateTrustConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->trust_config() >> / C<< $msg->trust_config($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig>)

Required. A definition of the TrustConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::DeleteTrustConfigRequest

Request for the `DeleteTrustConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TrustConfig to delete. Must be in the format
`projects/*/locations/*/trustConfigs/*`.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. The current etag of the TrustConfig.
If an etag is provided and does not match the current etag of the resource,
deletion will be blocked and an ABORTED error will be returned.

=back

=head2 Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig

Defines a trust config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. A user-defined name of the trust config. TrustConfig names must
be unique globally and match pattern
`projects/*/locations/*/trustConfigs/*`.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation timestamp of a TrustConfig.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update timestamp of a TrustConfig.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::LabelsEntry>)

Optional. Set of labels associated with a TrustConfig.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. One or more paragraphs of text description of a TrustConfig.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

This checksum is computed by the server based on the value of other
fields, and may be sent on update and delete requests to ensure the
client has an up-to-date value before proceeding.

=item * C<< $msg->spiffe_trust_stores() >> / C<< $msg->spiffe_trust_stores($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::SpiffeTrustStoresEntry>)

Optional. Defines a mapping from a trust domain to a TrustStore. This is
used for SPIFFE certificate validation.

=item * C<< $msg->trust_stores() >> / C<< $msg->trust_stores($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TrustStore>)

Optional. Set of trust stores to perform validation against.

This field is supported when TrustConfig is configured with Load Balancers,
currently not supported for SPIFFE certificate validation.

Only one TrustStore specified is currently allowed.

=item * C<< $msg->allowlisted_certificates() >> / C<< $msg->allowlisted_certificates($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::AllowlistedCertificate>)

Optional. A certificate matching an allowlisted certificate is always
considered valid as long as the certificate is parseable, proof of private
key possession is established, and constraints on the certificate's SAN
field are met.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Cloud::Certificatemanager::V1::TrustConfig::TrustConfig::TagsEntry>)

Optional. Input only. Immutable. Tag keys/values directly bound to this
resource. For example:
  "123/environment": "production",
  "123/costCenter": "marketing"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Certificatemanager::V1::TrustConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
