package Google::Cloud::Discoveryengine::V1alpha::PurgeConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvcHVyZ2VfY29uZmlnLnBy
b3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOGdvb2ds
ZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9pbXBvcnRfY29uZmlnLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90
byKVAQoWUHVyZ2VVc2VyRXZlbnRzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgoo
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50EhsKBmZp
bHRlchgCIAEoCUID4EECUgZmaWx0ZXISFAoFZm9yY2UYAyABKAhSBWZvcmNlIjoKF1B1cmdl
VXNlckV2ZW50c1Jlc3BvbnNlEh8KC3B1cmdlX2NvdW50GAEgASgDUgpwdXJnZUNvdW50It0B
ChdQdXJnZVVzZXJFdmVudHNNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEiMKDXN1Y2Nlc3NfY291
bnQYAyABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWlsdXJlX2NvdW50GAQgASgDUgxmYWlsdXJl
Q291bnQiQgoQUHVyZ2VFcnJvckNvbmZpZxIfCgpnY3NfcHJlZml4GAEgASgJSABSCWdjc1By
ZWZpeEINCgtkZXN0aW5hdGlvbiKYBAoVUHVyZ2VEb2N1bWVudHNSZXF1ZXN0ElAKCmdjc19z
b3VyY2UYBSABKAsyLy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuR2Nz
U291cmNlSABSCWdjc1NvdXJjZRJvCg1pbmxpbmVfc291cmNlGAYgASgLMkguZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlB1cmdlRG9jdW1lbnRzUmVxdWVzdC5Jbmxp
bmVTb3VyY2VIAFIMaW5saW5lU291cmNlEkUKBnBhcmVudBgBIAEoCUIt4EEC+kEnCiVkaXNj
b3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQnJhbmNoUgZwYXJlbnQSGwoGZmlsdGVyGAIg
ASgJQgPgQQJSBmZpbHRlchJZCgxlcnJvcl9jb25maWcYByABKAsyNi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuUHVyZ2VFcnJvckNvbmZpZ1ILZXJyb3JDb25maWcS
FAoFZm9yY2UYAyABKAhSBWZvcmNlGl0KDElubGluZVNvdXJjZRJNCglkb2N1bWVudHMYASAD
KAlCL+BBAvpBKQonZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50Uglk
b2N1bWVudHNCCAoGc291cmNlIooBChZQdXJnZURvY3VtZW50c1Jlc3BvbnNlEh8KC3B1cmdl
X2NvdW50GAEgASgDUgpwdXJnZUNvdW50Ek8KDHB1cmdlX3NhbXBsZRgCIAMoCUIs+kEpCidk
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRG9jdW1lbnRSC3B1cmdlU2FtcGxlIoEC
ChZQdXJnZURvY3VtZW50c01ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3Vu
dBgDIAEoA1IMc3VjY2Vzc0NvdW50EiMKDWZhaWx1cmVfY291bnQYBCABKANSDGZhaWx1cmVD
b3VudBIjCg1pZ25vcmVkX2NvdW50GAUgASgDUgxpZ25vcmVkQ291bnQicQolUHVyZ2VTdWdn
ZXN0aW9uRGVueUxpc3RFbnRyaWVzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgoo
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZVIGcGFyZW50IoIBCiZQ
dXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNSZXNwb25zZRIfCgtwdXJnZV9jb3VudBgB
IAEoA1IKcHVyZ2VDb3VudBI3Cg1lcnJvcl9zYW1wbGVzGAIgAygLMhIuZ29vZ2xlLnJwYy5T
dGF0dXNSDGVycm9yU2FtcGxlcyKiAQomUHVyZ2VTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVz
TWV0YWRhdGESOwoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcFIKdXBkYXRlVGltZSJtCiFQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc1Jl
cXVlc3QSSAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9EYXRhU3RvcmVSBnBhcmVudCKGAQoiUHVyZ2VDb21wbGV0aW9uU3VnZ2VzdGlv
bnNSZXNwb25zZRInCg9wdXJnZV9zdWNjZWVkZWQYASABKAhSDnB1cmdlU3VjY2VlZGVkEjcK
DWVycm9yX3NhbXBsZXMYAiADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVz
Ip4BCiJQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc01ldGFkYXRhEjsKC2NyZWF0ZV90aW1l
GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRh
dGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWVC
nAIKKGNvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCEFB1cmdlQ29u
ZmlnUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFh
bHBoYS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVO
R0lORaoCJEdvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2dsZVxD
bG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVy
eUVuZ2luZTo6VjFhbHBoYUqfTgoHEgUOAJkCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAQgoJ
CgIDAxIDFQApCgkKAgMEEgMWACEKCAoBCBIDGABBCgkKAgglEgMYAEEKCAoBCBIDGQBpCgkK
AggLEgMZAGkKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAxCgkKAggIEgMbADEKCAoB
CBIDHABBCgkKAggBEgMcAEEKCAoBCBIDHQAtCgkKAggkEgMdAC0KCAoBCBIDHgBBCgkKAggp
EgMeAEEKCAoBCBIDHwBACgkKAggtEgMfAEAKOQoCBAASBCIATwEaLSBSZXF1ZXN0IG1lc3Nh
Z2UgZm9yIFB1cmdlVXNlckV2ZW50cyBtZXRob2QuCgoKCgMEAAESAyIIHgrOAQoEBAACABIE
JgIrBBq/ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGNhdGFsb2cgdW5k
ZXIgd2hpY2ggdGhlIGV2ZW50cyBhcmUKIGNyZWF0ZWQuIFRoZSBmb3JtYXQgaXMKIGBwcm9q
ZWN0cy8ke3Byb2plY3RJZH0vbG9jYXRpb25zL2dsb2JhbC9jb2xsZWN0aW9ucy97JGNvbGxl
Y3Rpb25JZH0vZGF0YVN0b3Jlcy8ke2RhdGFTdG9yZUlkfWAKCgwKBQQAAgAFEgMmAggKDAoF
BAACAAESAyYJDwoMCgUEAAIAAxIDJhITCg0KBQQAAgAIEgQmFCsDCg8KCAQAAgAInAgAEgMn
BCoKDwoHBAACAAifCBIEKAQqBQqdBwoEBAACARIDRgI9Go8HIFJlcXVpcmVkLiBUaGUgZmls
dGVyIHN0cmluZyB0byBzcGVjaWZ5IHRoZSBldmVudHMgdG8gYmUgZGVsZXRlZCB3aXRoIGEK
IGxlbmd0aCBsaW1pdCBvZiA1LDAwMCBjaGFyYWN0ZXJzLiBUaGUgZWxpZ2libGUgZmllbGRz
IGZvciBmaWx0ZXJpbmcgYXJlOgoKICogYGV2ZW50VHlwZWA6IERvdWJsZSBxdW90ZWQKIFtV
c2VyRXZlbnQuZXZlbnRfdHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLlVzZXJFdmVudC5ldmVudF90eXBlXQogc3RyaW5nLgogKiBgZXZlbnRUaW1lYDogaW4g
SVNPIDg2MDEgInp1bHUiIGZvcm1hdC4KICogYHVzZXJQc2V1ZG9JZGA6IERvdWJsZSBxdW90
ZWQgc3RyaW5nLiBTcGVjaWZ5aW5nIHRoaXMgd2lsbCBkZWxldGUgYWxsCiAgIGV2ZW50cyBh
c3NvY2lhdGVkIHdpdGggYSB2aXNpdG9yLgogKiBgdXNlcklkYDogRG91YmxlIHF1b3RlZCBz
dHJpbmcuIFNwZWNpZnlpbmcgdGhpcyB3aWxsIGRlbGV0ZSBhbGwgZXZlbnRzCiAgIGFzc29j
aWF0ZWQgd2l0aCBhIHVzZXIuCgogRXhhbXBsZXM6CgogKiBEZWxldGluZyBhbGwgZXZlbnRz
IGluIGEgdGltZSByYW5nZToKICAgYGV2ZW50VGltZSA+ICIyMDEyLTA0LTIzVDE4OjI1OjQz
LjUxMVoiCiAgIGV2ZW50VGltZSA8ICIyMDEyLTA0LTIzVDE4OjMwOjQzLjUxMVoiYAogKiBE
ZWxldGluZyBzcGVjaWZpYyBldmVudFR5cGU6CiAgIGBldmVudFR5cGUgPSAic2VhcmNoImAK
ICogRGVsZXRpbmcgYWxsIGV2ZW50cyBmb3IgYSBzcGVjaWZpYyB2aXNpdG9yOgogICBgdXNl
clBzZXVkb0lkID0gInZpc2l0b3IxMDI0ImAKICogRGVsZXRpbmcgYWxsIGV2ZW50cyBpbnNp
ZGUgYSBEYXRhU3RvcmU6CiAgIGAqYAoKIFRoZSBmaWx0ZXJpbmcgZmllbGRzIGFyZSBhc3N1
bWVkIHRvIGhhdmUgYW4gaW1wbGljaXQgQU5ELgoKDAoFBAACAQUSA0YCCAoMCgUEAAIBARID
RgkPCgwKBQQAAgEDEgNGEhMKDAoFBAACAQgSA0YUPAoPCggEAAIBCJwIABIDRhU7CtsCCgQE
AAICEgNOAhEazQIgVGhlIGBmb3JjZWAgZmllbGQgaXMgY3VycmVudGx5IG5vdCBzdXBwb3J0
ZWQuIFB1cmdlIHVzZXIgZXZlbnQgcmVxdWVzdHMKIHdpbGwgcGVybWFuZW50bHkgZGVsZXRl
IGFsbCBwdXJnZWFibGUgZXZlbnRzLiBPbmNlIHRoZSBkZXZlbG9wbWVudCBpcwogY29tcGxl
dGU6CiBJZiBgZm9yY2VgIGlzIHNldCB0byBmYWxzZSwgdGhlIG1ldGhvZCB3aWxsIHJldHVy
biB0aGUgZXhwZWN0ZWQKIHB1cmdlIGNvdW50IHdpdGhvdXQgZGVsZXRpbmcgYW55IHVzZXIg
ZXZlbnRzLiBUaGlzIGZpZWxkIHdpbGwgZGVmYXVsdCB0bwogZmFsc2UgaWYgbm90IGluY2x1
ZGVkIGluIHRoZSByZXF1ZXN0LgoKDAoFBAACAgUSA04CBgoMCgUEAAICARIDTgcMCgwKBQQA
AgIDEgNODxAKvwEKAgQBEgRUAFcBGrIBIFJlc3BvbnNlIG9mIHRoZSBQdXJnZVVzZXJFdmVu
dHNSZXF1ZXN0LiBJZiB0aGUgbG9uZyBydW5uaW5nIG9wZXJhdGlvbiBpcwogc3VjY2Vzc2Z1
bGx5IGRvbmUsIHRoZW4gdGhpcyBtZXNzYWdlIGlzIHJldHVybmVkIGJ5IHRoZQogZ29vZ2xl
LmxvbmdydW5uaW5nLk9wZXJhdGlvbnMucmVzcG9uc2UgZmllbGQuCgoKCgMEAQESA1QIHwpN
CgQEAQIAEgNWAhgaQCBUaGUgdG90YWwgY291bnQgb2YgZXZlbnRzIHB1cmdlZCBhcyBhIHJl
c3VsdCBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAECAAUSA1YCBwoMCgUEAQIAARIDVggTCgwK
BQQBAgADEgNWFhcKnAEKAgQCEgRbAGgBGo8BIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHBy
b2dyZXNzIG9mIHRoZSBQdXJnZVVzZXJFdmVudHMgb3BlcmF0aW9uLgogVGhpcyB3aWxsIGJl
IHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRh
IGZpZWxkLgoKCgoDBAIBEgNbCB8KJQoEBAICABIDXQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0
aW1lLgoKDAoFBAICAAYSA10CGwoMCgUEAgIAARIDXRwnCgwKBQQCAgADEgNdKisKYwoEBAIC
ARIDYQIsGlYgT3BlcmF0aW9uIGxhc3QgdXBkYXRlIHRpbWUuIElmIHRoZSBvcGVyYXRpb24g
aXMgZG9uZSwgdGhpcyBpcyBhbHNvIHRoZQogZmluaXNoIHRpbWUuCgoMCgUEAgIBBhIDYQIb
CgwKBQQCAgEBEgNhHCcKDAoFBAICAQMSA2EqKwo/CgQEAgICEgNkAhoaMiBDb3VudCBvZiBl
bnRyaWVzIHRoYXQgd2VyZSBkZWxldGVkIHN1Y2Nlc3NmdWxseS4KCgwKBQQCAgIFEgNkAgcK
DAoFBAICAgESA2QIFQoMCgUEAgICAxIDZBgZCkkKBAQCAgMSA2cCGho8IENvdW50IG9mIGVu
dHJpZXMgdGhhdCBlbmNvdW50ZXJlZCBlcnJvcnMgd2hpbGUgcHJvY2Vzc2luZy4KCgwKBQQC
AgMFEgNnAgcKDAoFBAICAwESA2cIFQoMCgUEAgIDAxIDZxgZCkQKAgQDEgRrAHQBGjggQ29u
ZmlndXJhdGlvbiBvZiBkZXN0aW5hdGlvbiBmb3IgUHVyZ2UgcmVsYXRlZCBlcnJvcnMuCgoK
CgMEAwESA2sIGAotCgQEAwgAEgRtAnMDGh8gUmVxdWlyZWQuIEVycm9ycyBkZXN0aW5hdGlv
bi4KCgwKBQQDCAABEgNtCBMK7AEKBAQDAgASA3IEGhreASBDbG91ZCBTdG9yYWdlIHByZWZp
eCBmb3IgcHVyZ2UgZXJyb3JzLiBUaGlzIG11c3QgYmUgYW4gZW1wdHksCiBleGlzdGluZyBD
bG91ZCBTdG9yYWdlIGRpcmVjdG9yeS4gUHVyZ2UgZXJyb3JzIGFyZSB3cml0dGVuIHRvCiBz
aGFyZGVkIGZpbGVzIGluIHRoaXMgZGlyZWN0b3J5LCBvbmUgcGVyIGxpbmUsIGFzIGEgSlNP
Ti1lbmNvZGVkCiBgZ29vZ2xlLnJwYy5TdGF0dXNgIG1lc3NhZ2UuCgoMCgUEAwIABRIDcgQK
CgwKBQQDAgABEgNyCxUKDAoFBAMCAAMSA3IYGQqTAQoCBAQSBXkAqgEBGoUBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtEb2N1bWVudFNlcnZpY2UuUHVyZ2VEb2N1bWVudHNdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Eb2N1bWVudFNlcnZpY2UuUHVyZ2VEb2N1
bWVudHNdCiBtZXRob2QuCgoKCgMEBAESA3kIHQqsAQoEBAQDABIFfQKIAQManAEgVGhlIGlu
bGluZSBzb3VyY2UgZm9yIHRoZSBpbnB1dCBjb25maWcgZm9yCiBbRG9jdW1lbnRTZXJ2aWNl
LlB1cmdlRG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEu
RG9jdW1lbnRTZXJ2aWNlLlB1cmdlRG9jdW1lbnRzXQogbWV0aG9kLgoKDAoFBAQDAAESA30K
FgrNAQoGBAQDAAIAEgaCAQSHAQYaugEgUmVxdWlyZWQuIEEgbGlzdCBvZiBmdWxsIHJlc291
cmNlIG5hbWUgb2YgZG9jdW1lbnRzIHRvIHB1cmdlLiBJbiB0aGUKIGZvcm1hdAogYHByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyovYnJhbmNoZXMv
Ki9kb2N1bWVudHMvKmAuCiBSZWNvbW1lbmRlZCBtYXggb2YgMTAwIGl0ZW1zLgoKDwoHBAQD
AAIABBIEggEEDAoPCgcEBAMAAgAFEgSCAQ0TCg8KBwQEAwACAAESBIIBFB0KDwoHBAQDAAIA
AxIEggEgIQoRCgcEBAMAAgAIEgaCASKHAQUKEgoKBAQDAAIACJwIABIEgwEGLAoTCgkEBAMA
AgAInwgSBoQBBoYBBwpbCgQEBAgAEgaLAQKUAQMaSyBUaGUgZGVzaXJlZCBpbnB1dCBzb3Vy
Y2UgZm9yIHRoZSBwdXJnaW5nIGRvY3VtZW50cyBiYXNlZCBvbiBkb2N1bWVudCBJRHMuCgoN
CgUEBAgAARIEiwEIDgq/AQoEBAQCABIEkAEEHRqwASBDbG91ZCBTdG9yYWdlIGxvY2F0aW9u
IGZvciB0aGUgaW5wdXQgY29udGVudC4KIFN1cHBvcnRlZCBgZGF0YV9zY2hlbWFgOgogKiBg
ZG9jdW1lbnRfaWRgOiBPbmUgdmFsaWQKIFtEb2N1bWVudC5pZF1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50LmlkXSBwZXIgbGluZS4KCg0KBQQEAgAG
EgSQAQQNCg0KBQQEAgABEgSQAQ4YCg0KBQQEAgADEgSQARscCj4KBAQEAgESBJMBBCMaMCBJ
bmxpbmUgc291cmNlIGZvciB0aGUgaW5wdXQgY29udGVudCBmb3IgcHVyZ2UuCgoNCgUEBAIB
BhIEkwEEEAoNCgUEBAIBARIEkwERHgoNCgUEBAIBAxIEkwEhIgqtAQoEBAQCAhIGmAECnQEE
GpwBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxl
Y3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9YC4KCg0K
BQQEAgIFEgSYAQIICg0KBQQEAgIBEgSYAQkPCg0KBQQEAgIDEgSYARITCg8KBQQEAgIIEgaY
ARSdAQMKEAoIBAQCAgicCAASBJkBBCoKEQoHBAQCAgifCBIGmgEEnAEFCnIKBAQEAgMSBKIB
Aj0aZCBSZXF1aXJlZC4gRmlsdGVyIG1hdGNoaW5nIGRvY3VtZW50cyB0byBwdXJnZS4gT25s
eSBjdXJyZW50bHkgc3VwcG9ydGVkCiB2YWx1ZSBpcwogYCpgIChhbGwgaXRlbXMpLgoKDQoF
BAQCAwUSBKIBAggKDQoFBAQCAwESBKIBCQ8KDQoFBAQCAwMSBKIBEhMKDQoFBAQCAwgSBKIB
FDwKEAoIBAQCAwicCAASBKIBFTsKSQoEBAQCBBIEpQECJBo7IFRoZSBkZXNpcmVkIGxvY2F0
aW9uIG9mIGVycm9ycyBpbmN1cnJlZCBkdXJpbmcgdGhlIHB1cmdlLgoKDQoFBAQCBAYSBKUB
AhIKDQoFBAQCBAESBKUBEx8KDQoFBAQCBAMSBKUBIiMKiQEKBAQEAgUSBKkBAhEaeyBBY3R1
YWxseSBwZXJmb3JtcyB0aGUgcHVyZ2UuIElmIGBmb3JjZWAgaXMgc2V0IHRvIGZhbHNlLCBy
ZXR1cm4gdGhlCiBleHBlY3RlZCBwdXJnZSBjb3VudCB3aXRob3V0IGRlbGV0aW5nIGFueSBk
b2N1bWVudHMuCgoNCgUEBAIFBRIEqQECBgoNCgUEBAIFARIEqQEHDAoNCgUEBAIFAxIEqQEP
EAqdAgoCBAUSBrABALoBARqOAiBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0RvY3VtZW50U2Vy
dmljZS5QdXJnZURvY3VtZW50c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLkRvY3VtZW50U2VydmljZS5QdXJnZURvY3VtZW50c10KIG1ldGhvZC4gSWYgdGhlIGxv
bmcgcnVubmluZyBvcGVyYXRpb24gaXMgc3VjY2Vzc2Z1bGx5IGRvbmUsIHRoZW4gdGhpcyBt
ZXNzYWdlCiBpcyByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
bnMucmVzcG9uc2UgZmllbGQuCgoLCgMEBQESBLABCB4KUQoEBAUCABIEsgECGBpDIFRoZSB0
b3RhbCBjb3VudCBvZiBkb2N1bWVudHMgcHVyZ2VkIGFzIGEgcmVzdWx0IG9mIHRoZSBvcGVy
YXRpb24uCgoNCgUEBQIABRIEsgECBwoNCgUEBQIAARIEsgEIEwoNCgUEBQIAAxIEsgEWFwq4
AQoEBAUCARIGtwECuQEFGqcBIEEgc2FtcGxlIG9mIGRvY3VtZW50IG5hbWVzIHRoYXQgd2ls
bCBiZSBkZWxldGVkLiBPbmx5IHBvcHVsYXRlZCBpZiBgZm9yY2VgCiBpcyBzZXQgdG8gZmFs
c2UuIEEgbWF4IG9mIDEwMCBuYW1lcyB3aWxsIGJlIHJldHVybmVkIGFuZCB0aGUgbmFtZXMg
YXJlCiBjaG9zZW4gYXQgcmFuZG9tLgoKDQoFBAUCAQQSBLcBAgoKDQoFBAUCAQUSBLcBCxEK
DQoFBAUCAQESBLcBEh4KDQoFBAUCAQMSBLcBISIKDwoFBAUCAQgSBrcBI7kBBAoRCgcEBQIB
CJ8IEga3ASS5AQMKnQEKAgQGEga+AQDOAQEajgEgTWV0YWRhdGEgcmVsYXRlZCB0byB0aGUg
cHJvZ3Jlc3Mgb2YgdGhlIFB1cmdlRG9jdW1lbnRzIG9wZXJhdGlvbi4KIFRoaXMgd2lsbCBi
ZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0
YSBmaWVsZC4KCgsKAwQGARIEvgEIHgomCgQEBgIAEgTAAQIsGhggT3BlcmF0aW9uIGNyZWF0
ZSB0aW1lLgoKDQoFBAYCAAYSBMABAhsKDQoFBAYCAAESBMABHCcKDQoFBAYCAAMSBMABKisK
ZAoEBAYCARIExAECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3Bl
cmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAYC
AQYSBMQBAhsKDQoFBAYCAQESBMQBHCcKDQoFBAYCAQMSBMQBKisKQAoEBAYCAhIExwECGhoy
IENvdW50IG9mIGVudHJpZXMgdGhhdCB3ZXJlIGRlbGV0ZWQgc3VjY2Vzc2Z1bGx5LgoKDQoF
BAYCAgUSBMcBAgcKDQoFBAYCAgESBMcBCBUKDQoFBAYCAgMSBMcBGBkKSgoEBAYCAxIEygEC
Gho8IENvdW50IG9mIGVudHJpZXMgdGhhdCBlbmNvdW50ZXJlZCBlcnJvcnMgd2hpbGUgcHJv
Y2Vzc2luZy4KCg0KBQQGAgMFEgTKAQIHCg0KBQQGAgMBEgTKAQgVCg0KBQQGAgMDEgTKARgZ
Ck0KBAQGAgQSBM0BAhoaPyBDb3VudCBvZiBlbnRyaWVzIHRoYXQgd2VyZSBpZ25vcmVkIGFz
IGVudHJpZXMgd2VyZSBub3QgZm91bmQuCgoNCgUEBgIEBRIEzQECBwoNCgUEBgIEARIEzQEI
FQoNCgUEBgIEAxIEzQEYGQq4AQoCBAcSBtMBANwBARqpASBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbQ29tcGxldGlvblNlcnZpY2UuUHVyZ2VTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ29tcGxldGlvblNlcnZpY2Uu
UHVyZ2VTdWdnZXN0aW9uRGVueUxpc3RFbnRyaWVzXQogbWV0aG9kLgoKCwoDBAcBEgTTAQgt
CqoBCgQEBwIAEgbWAQLbAQQamQEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgZGF0YSBzdG9yZSBy
ZXNvdXJjZSBuYW1lIGZvciB3aGljaCB0byBpbXBvcnQgZGVueWxpc3QKIGVudHJpZXMuIEZv
bGxvd3MgcGF0dGVybiBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0
YVN0b3Jlcy8qLgoKDQoFBAcCAAUSBNYBAggKDQoFBAcCAAESBNYBCQ8KDQoFBAcCAAMSBNYB
EhMKDwoFBAcCAAgSBtYBFNsBAwoQCggEBwIACJwIABIE1wEEKgoRCgcEBwIACJ8IEgbYAQTa
AQUKuQEKAgQIEgbhAQDnAQEaqgEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtDb21wbGV0aW9u
U2VydmljZS5QdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXNdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Db21wbGV0aW9uU2VydmljZS5QdXJnZVN1Z2dlc3Rp
b25EZW55TGlzdEVudHJpZXNdCiBtZXRob2QuCgoLCgMECAESBOEBCC4KPgoEBAgCABIE4wEC
GBowIE51bWJlciBvZiBzdWdnZXN0aW9uIGRlbnkgbGlzdCBlbnRyaWVzIHB1cmdlZC4KCg0K
BQQIAgAFEgTjAQIHCg0KBQQIAgABEgTjAQgTCg0KBQQIAgADEgTjARYXCkwKBAQIAgESBOYB
Ai8aPiBBIHNhbXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0
aGUgcmVxdWVzdC4KCg0KBQQIAgEEEgTmAQIKCg0KBQQIAgEGEgTmAQscCg0KBQQIAgEBEgTm
AR0qCg0KBQQIAgEDEgTmAS0uCqkBCgIECRIG7AEA8wEBGpoBIE1ldGFkYXRhIHJlbGF0ZWQg
dG8gdGhlIHByb2dyZXNzIG9mIHRoZSBQdXJnZVN1Z2dlc3Rpb25EZW55TGlzdEVudHJpZXMK
IG9wZXJhdGlvbi4gVGhpcyBpcyByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMECQESBOwBCC4KJgoEBAkCABIE7gEC
LBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQJAgAGEgTuAQIbCg0KBQQJAgABEgTu
ARwnCg0KBQQJAgADEgTuASorCmQKBAQJAgESBPIBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRh
dGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBm
aW5pc2ggdGltZS4KCg0KBQQJAgEGEgTyAQIbCg0KBQQJAgEBEgTyARwnCg0KBQQJAgEDEgTy
ASorCrABCgIEChIG+AEAggIBGqEBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtDb21wbGV0aW9u
U2VydmljZS5QdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9uc11bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLkNvbXBsZXRpb25TZXJ2aWNlLlB1cmdlQ29tcGxldGlvblN1
Z2dlc3Rpb25zXQogbWV0aG9kLgoKCwoDBAoBEgT4AQgpCrABCgQECgIAEgb8AQKBAgQanwEg
UmVxdWlyZWQuIFRoZSBwYXJlbnQgZGF0YSBzdG9yZSByZXNvdXJjZSBuYW1lIGZvciB3aGlj
aCB0byBwdXJnZSBjb21wbGV0aW9uCiBzdWdnZXN0aW9ucy4gRm9sbG93cyBwYXR0ZXJuCiBw
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qLgoKDQoF
BAoCAAUSBPwBAggKDQoFBAoCAAESBPwBCQ8KDQoFBAoCAAMSBPwBEhMKDwoFBAoCAAgSBvwB
FIECAwoQCggECgIACJwIABIE/QEEKgoRCgcECgIACJ8IEgb+AQSAAgUKsQEKAgQLEgaHAgCN
AgEaogEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtDb21wbGV0aW9uU2VydmljZS5QdXJnZUNv
bXBsZXRpb25TdWdnZXN0aW9uc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLkNvbXBsZXRpb25TZXJ2aWNlLlB1cmdlQ29tcGxldGlvblN1Z2dlc3Rpb25zXQogbWV0
aG9kLgoKCwoDBAsBEgSHAggqCkwKBAQLAgASBIkCAhsaPiBXaGV0aGVyIHRoZSBjb21wbGV0
aW9uIHN1Z2dlc3Rpb25zIHdlcmUgc3VjY2Vzc2Z1bGx5IHB1cmdlZC4KCg0KBQQLAgAFEgSJ
AgIGCg0KBQQLAgABEgSJAgcWCg0KBQQLAgADEgSJAhkaCkwKBAQLAgESBIwCAi8aPiBBIHNh
bXBsZSBvZiBlcnJvcnMgZW5jb3VudGVyZWQgd2hpbGUgcHJvY2Vzc2luZyB0aGUgcmVxdWVz
dC4KCg0KBQQLAgEEEgSMAgIKCg0KBQQLAgEGEgSMAgscCg0KBQQLAgEBEgSMAh0qCg0KBQQL
AgEDEgSMAi0uCqUBCgIEDBIGkgIAmQIBGpYBIE1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIHBy
b2dyZXNzIG9mIHRoZSBQdXJnZUNvbXBsZXRpb25TdWdnZXN0aW9ucwogb3BlcmF0aW9uLiBU
aGlzIGlzIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1l
dGFkYXRhCiBmaWVsZC4KCgsKAwQMARIEkgIIKgomCgQEDAIAEgSUAgIsGhggT3BlcmF0aW9u
IGNyZWF0ZSB0aW1lLgoKDQoFBAwCAAYSBJQCAhsKDQoFBAwCAAESBJQCHCcKDQoFBAwCAAMS
BJQCKisKZAoEBAwCARIEmAICLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0
aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoK
DQoFBAwCAQYSBJgCAhsKDQoFBAwCAQESBJgCHCcKDQoFBAwCAQMSBJgCKitiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest ===
    # Fields for PurgeUserEventsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsResponse ===
    # Fields for PurgeUserEventsResponse
    # Field: purge_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsMetadata ===
    # Fields for PurgeUserEventsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig ===
    # Fields for PurgeErrorConfig
    # Field: gcs_prefix Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest ===
    # Fields for PurgeDocumentsRequest
    # Field: gcs_source Type: 11 (.google.cloud.discoveryengine.v1alpha.GcsSource)
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1alpha.PurgeDocumentsRequest.InlineSource)
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: error_config Type: 11 (.google.cloud.discoveryengine.v1alpha.PurgeErrorConfig)
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsResponse ===
    # Fields for PurgeDocumentsResponse
    # Field: purge_count Type: 3 ()
    # Field: purge_sample Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsMetadata ===
    # Fields for PurgeDocumentsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()
    # Field: ignored_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest ===
    # Fields for PurgeSuggestionDenyListEntriesRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesResponse ===
    # Fields for PurgeSuggestionDenyListEntriesResponse
    # Field: purge_count Type: 3 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata ===
    # Fields for PurgeSuggestionDenyListEntriesMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest ===
    # Fields for PurgeCompletionSuggestionsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsResponse ===
    # Fields for PurgeCompletionSuggestionsResponse
    # Field: purge_succeeded Type: 8 ()
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Message: Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsMetadata ===
    # Fields for PurgeCompletionSuggestionsMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::PurgeConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/purge_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::PurgeConfig;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest->new({
        parent => $parent,
        filter => $filter,
        force => $force,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/purge_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest

Request message for PurgeUserEvents method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the catalog under which the events are
created. The format is
`projects/${projectId}/locations/global/collections/{$collectionId}/dataStores/${dataStoreId}`

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter string to specify the events to be deleted with a
length limit of 5,000 characters. The eligible fields for filtering are:

* `eventType`: Double quoted
[UserEvent.event_type][google.cloud.discoveryengine.v1alpha.UserEvent.event_type]
string.
* `eventTime`: in ISO 8601 "zulu" format.
* `userPseudoId`: Double quoted string. Specifying this will delete all
  events associated with a visitor.
* `userId`: Double quoted string. Specifying this will delete all events
  associated with a user.

Examples:

* Deleting all events in a time range:
  `eventTime > "2012-04-23T18:25:43.511Z"
  eventTime < "2012-04-23T18:30:43.511Z"`
* Deleting specific eventType:
  `eventType = "search"`
* Deleting all events for a specific visitor:
  `userPseudoId = "visitor1024"`
* Deleting all events inside a DataStore:
  `*`

The filtering fields are assumed to have an implicit AND.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

The `force` field is currently not supported. Purge user event requests
will permanently delete all purgeable events. Once the development is
complete:
If `force` is set to false, the method will return the expected
purge count without deleting any user events. This field will default to
false if not included in the request.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsResponse

Response of the PurgeUserEventsRequest. If the long running operation is
successfully done, then this message is returned by the
google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of events purged as a result of the operation.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsMetadata

Metadata related to the progress of the PurgeUserEvents operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig

Configuration of destination for Purge related errors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_prefix() >> / C<< $msg->gcs_prefix($value) >>

Type: C<String>

Cloud Storage prefix for purge errors. This must be an empty,
existing Cloud Storage directory. Purge errors are written to
sharded files in this directory, one per line, as a JSON-encoded
`google.rpc.Status` message.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest

Request message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1alpha.DocumentService.PurgeDocuments]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ImportConfig::GcsSource>)

Cloud Storage location for the input content.
Supported `data_schema`:
* `document_id`: One valid
[Document.id][google.cloud.discoveryengine.v1alpha.Document.id] per line.

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest::InlineSource>)

Inline source for the input content for purge.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. Filter matching documents to purge. Only currently supported
value is
`*` (all items).

=item * C<< $msg->error_config() >> / C<< $msg->error_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig>)

The desired location of errors incurred during the purge.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Actually performs the purge. If `force` is set to false, return the
expected purge count without deleting any documents.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsResponse

Response message for
[DocumentService.PurgeDocuments][google.cloud.discoveryengine.v1alpha.DocumentService.PurgeDocuments]
method. If the long running operation is successfully done, then this message
is returned by the google.longrunning.Operations.response field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

The total count of documents purged as a result of the operation.

=item * C<< $msg->purge_sample() >> / C<< $msg->purge_sample($value) >>

Type: C<String>

A sample of document names that will be deleted. Only populated if `force`
is set to false. A max of 100 names will be returned and the names are
chosen at random.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsMetadata

Metadata related to the progress of the PurgeDocuments operation.
This will be returned by the google.longrunning.Operation.metadata field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of entries that were deleted successfully.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of entries that encountered errors while processing.

=item * C<< $msg->ignored_count() >> / C<< $msg->ignored_count($value) >>

Type: C<Int64>

Count of entries that were ignored as entries were not found.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest

Request message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1alpha.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to import denylist
entries. Follows pattern projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesResponse

Response message for
[CompletionService.PurgeSuggestionDenyListEntries][google.cloud.discoveryengine.v1alpha.CompletionService.PurgeSuggestionDenyListEntries]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_count() >> / C<< $msg->purge_count($value) >>

Type: C<Int64>

Number of suggestion deny list entries purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata

Metadata related to the progress of the PurgeSuggestionDenyListEntries
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest

Request message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1alpha.CompletionService.PurgeCompletionSuggestions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent data store resource name for which to purge completion
suggestions. Follows pattern
projects/*/locations/*/collections/*/dataStores/*.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsResponse

Response message for
[CompletionService.PurgeCompletionSuggestions][google.cloud.discoveryengine.v1alpha.CompletionService.PurgeCompletionSuggestions]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->purge_succeeded() >> / C<< $msg->purge_succeeded($value) >>

Type: C<Bool>

Whether the completion suggestions were successfully purged.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsMetadata

Metadata related to the progress of the PurgeCompletionSuggestions
operation. This is returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
