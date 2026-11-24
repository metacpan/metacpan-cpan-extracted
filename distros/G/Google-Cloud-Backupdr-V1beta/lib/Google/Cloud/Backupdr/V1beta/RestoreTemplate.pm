package Google::Cloud::Backupdr::V1beta::RestoreTemplate;

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
    eval { require Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon };
    eval { require Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL3Jlc3RvcmVfdGVtcGxhdGUucHJvdG8S
HGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxo6Z29vZ2xlL2Nsb3VkL2JhY2t1cGRyL3YxYmV0YS9yZXN0b3JlX3RlbXBs
YXRlX2NvbW1vbi5wcm90bxo9Z29vZ2xlL2Nsb3VkL2JhY2t1cGRyL3YxYmV0YS9yZXN0b3Jl
X3RlbXBsYXRlX2V4ZWN1dGlvbi5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2su
cHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8ixgoKD1Jlc3RvcmVUZW1wbGF0ZRIXCgRuYW1lGAEgASgJQgPgQQhS
BG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRl
X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRp
bWUSQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCnVwZGF0ZVRpbWUSKwoNcmVzb3VyY2VfdHlwZRgFIAEoCUIG4EEF4EECUgxyZXNvdXJj
ZVR5cGUSVgoGbGFiZWxzGAYgAygLMjkuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5S
ZXN0b3JlVGVtcGxhdGUuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEnAKF2JhY2t1cF9zZWxl
Y3Rpb25fY29uZmlnGAcgASgLMjMuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5CYWNr
dXBTZWxlY3Rpb25Db25maWdCA+BBAlIVYmFja3VwU2VsZWN0aW9uQ29uZmlnEmEKEnByZV9y
ZXN0b3JlX2NvbmZpZxgIIAEoCzIuLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUHJl
UmVzdG9yZUNvbmZpZ0ID4EEBUhBwcmVSZXN0b3JlQ29uZmlnEmQKE3Bvc3RfcmVzdG9yZV9j
b25maWcYCSABKAsyLy5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLlBvc3RSZXN0b3Jl
Q29uZmlnQgPgQQFSEXBvc3RSZXN0b3JlQ29uZmlnEmYKE3ZlcmlmaWNhdGlvbl9jb25maWcY
CiABKAsyMC5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLlZlcmlmaWNhdGlvbkNvbmZp
Z0ID4EEBUhJ2ZXJpZmljYXRpb25Db25maWcSSwoScmVzdG9yZV9wcm9wZXJ0aWVzGAsgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EECUhFyZXN0b3JlUHJvcGVydGllcxJOCgVz
dGF0ZRgMIAEoDjIzLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVRlbXBs
YXRlLlN0YXRlQgPgQQNSBXN0YXRlEmAKEWV4ZWN1dGlvbl9zdW1tYXJ5GA0gASgLMi4uZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5FeGVjdXRpb25TdW1tYXJ5QgPgQQNSEGV4ZWN1
dGlvblN1bW1hcnkSFwoEZXRhZxgOIAEoCUID4EEBUgRldGFnGjkKC0xhYmVsc0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiVAoFU3RhdGUSFQoR
U1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEgwKCFVQREFU
SU5HEAMSDAoIREVMRVRJTkcQBDqdAepBmQEKJ2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jl
c3RvcmVUZW1wbGF0ZRJLcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L3Jlc3RvcmVUZW1wbGF0ZXMve3Jlc3RvcmVfdGVtcGxhdGV9KhByZXN0b3JlVGVtcGxhdGVz
Mg9yZXN0b3JlVGVtcGxhdGUi8QEKEEV4ZWN1dGlvblN1bW1hcnkSXwoObGFzdF9leGVjdXRp
b24YASABKAlCOOBBA/pBMgowYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVRlbXBs
YXRlRXhlY3V0aW9uUg1sYXN0RXhlY3V0aW9uEnwKFGxhc3RfZXhlY3V0aW9uX3N0YXRlGAIg
ASgOMkUuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5SZXN0b3JlVGVtcGxhdGVFeGVj
dXRpb24uRXhlY3V0aW9uU3RhdGVCA+BBA1ISbGFzdEV4ZWN1dGlvblN0YXRlIqcCChxDcmVh
dGVSZXN0b3JlVGVtcGxhdGVSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC+kEpEidiYWNr
dXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVtcGxhdGVSBnBhcmVudBIzChNyZXN0b3Jl
X3RlbXBsYXRlX2lkGAIgASgJQgPgQQJSEXJlc3RvcmVUZW1wbGF0ZUlkEl0KEHJlc3RvcmVf
dGVtcGxhdGUYAyABKAsyLS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhLlJlc3RvcmVU
ZW1wbGF0ZUID4EECUg9yZXN0b3JlVGVtcGxhdGUSKgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP
1wgCCAHgQQFSCXJlcXVlc3RJZCJgChlHZXRSZXN0b3JlVGVtcGxhdGVSZXF1ZXN0EkMKBG5h
bWUYASABKAlCL+BBAvpBKQonYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVRlbXBs
YXRlUgRuYW1lIpUCChxVcGRhdGVSZXN0b3JlVGVtcGxhdGVSZXF1ZXN0EkAKC3VwZGF0ZV9t
YXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNr
El0KEHJlc3RvcmVfdGVtcGxhdGUYAiABKAsyLS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjFi
ZXRhLlJlc3RvcmVUZW1wbGF0ZUID4EECUg9yZXN0b3JlVGVtcGxhdGUSKgoKcmVxdWVzdF9p
ZBgDIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZBIoCg12YWxpZGF0ZV9vbmx5GAQgASgI
QgPgQQFSDHZhbGlkYXRlT25seSKqAQocRGVsZXRlUmVzdG9yZVRlbXBsYXRlUmVxdWVzdBJD
CgRuYW1lGAEgASgJQi/gQQL6QSkKJ2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jlc3RvcmVU
ZW1wbGF0ZVIEbmFtZRIqCgpyZXF1ZXN0X2lkGAIgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVz
dElkEhkKBWZvcmNlGAMgASgIQgPgQQFSBWZvcmNlIswBChlSdW5SZXN0b3JlVGVtcGxhdGVS
ZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20v
UmVzdG9yZVRlbXBsYXRlUgRuYW1lEj4KBmJhY2t1cBgCIAEoCUIm4EEB+kEgCh5iYWNrdXBk
ci5nb29nbGVhcGlzLmNvbS9CYWNrdXBSBmJhY2t1cBIqCgpyZXF1ZXN0X2lkGAMgASgJQgvi
jM/XCAIIAeBBAVIJcmVxdWVzdElkIpQBChpSdW5SZXN0b3JlVGVtcGxhdGVSZXNwb25zZRJ2
ChpyZXN0b3JlX3RlbXBsYXRlX2V4ZWN1dGlvbhgBIAEoCUI44EED+kEyCjBiYWNrdXBkci5n
b29nbGVhcGlzLmNvbS9SZXN0b3JlVGVtcGxhdGVFeGVjdXRpb25SGHJlc3RvcmVUZW1wbGF0
ZUV4ZWN1dGlvbiLpAQobTGlzdFJlc3RvcmVUZW1wbGF0ZXNSZXF1ZXN0EkcKBnBhcmVudBgB
IAEoCUIv4EEC+kEpEidiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVtcGxhdGVS
BnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tl
bhgDIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIe
CghvcmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5IsQBChxMaXN0UmVzdG9yZVRlbXBsYXRl
c1Jlc3BvbnNlEloKEXJlc3RvcmVfdGVtcGxhdGVzGAEgAygLMi0uZ29vZ2xlLmNsb3VkLmJh
Y2t1cGRyLnYxYmV0YS5SZXN0b3JlVGVtcGxhdGVSEHJlc3RvcmVUZW1wbGF0ZXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJ
Ugt1bnJlYWNoYWJsZULYAQogY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCFFJl
c3RvcmVUZW1wbGF0ZVByb3RvUAFaPGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBp
djFiZXRhL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCHEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5W
MUJldGHKAhxHb29nbGVcQ2xvdWRcQmFja3VwRFJcVjFiZXRh6gIfR29vZ2xlOjpDbG91ZDo6
QmFja3VwRFI6OlYxYmV0YUqNWAoHEgUOAMoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
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
TGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJ
CgIDAxIDFQBECgkKAgMEEgMWAEcKCQoCAwUSAxcAKgoJCgIDBhIDGAAmCgkKAgMHEgMZACkK
CAoBCBIDGwA5CgkKAgglEgMbADkKCAoBCBIDHABTCgkKAggLEgMcAFMKCAoBCBIDHQAiCgkK
AggKEgMdACIKCAoBCBIDHgA1CgkKAggIEgMeADUKCAoBCBIDHwA5CgkKAggBEgMfADkKCAoB
CBIDIAA5CgkKAggpEgMgADkKCAoBCBIDIQA4CgkKAggtEgMhADgKYwoCBAASBCUAfgEaVyBB
IGBSZXN0b3JlVGVtcGxhdGVgIGVuY2Fwc3VsYXRlcyBEUiByZWFkaW5lc3MgY29uZmlndXJh
dGlvbnMgZm9yIHZhbGlkYXRpbmcKIGJhY2t1cHMuCgoKCgMEAAESAyUIFwoLCgMEAAcSBCYC
KwQKDQoFBAAHnQgSBCYCKwQKMQoEBAAEABIELgI9AxojIFRoZSBzdGF0ZSBvZiB0aGUgUmVz
dG9yZVRlbXBsYXRlLgoKDAoFBAAEAAESAy4HDAolCgYEAAQAAgASAzAEGhoWIFN0YXRlIG5v
dCBzcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMwBBUKDgoHBAAEAAIAAhIDMBgZCi8KBgQABAAC
ARIDMwQRGiAgVGhlIHRlbXBsYXRlIGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMz
BAwKDgoHBAAEAAIBAhIDMw8QCjkKBgQABAACAhIDNgQPGiogVGhlIHRlbXBsYXRlIGlzIGFj
dGl2ZSBhbmQgcmVhZHkgdG8gdXNlLgoKDgoHBAAEAAICARIDNgQKCg4KBwQABAACAgISAzYN
DgovCgYEAAQAAgMSAzkEERogIFRoZSB0ZW1wbGF0ZSBpcyBiZWluZyB1cGRhdGVkLgoKDgoH
BAAEAAIDARIDOQQMCg4KBwQABAACAwISAzkPEAovCgYEAAQAAgQSAzwEERogIFRoZSB0ZW1w
bGF0ZSBpcyBiZWluZyBkZWxldGVkLgoKDgoHBAAEAAIEARIDPAQMCg4KBwQABAACBAISAzwP
EApECgQEAAIAEgNAAj0aNyBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
UmVzdG9yZVRlbXBsYXRlLgoKDAoFBAACAAUSA0ACCAoMCgUEAAIAARIDQAkNCgwKBQQAAgAD
EgNAEBEKDAoFBAACAAgSA0ASPAoPCggEAAIACJwIABIDQBM7CksKBAQAAgESA0MCQho+IE9w
dGlvbmFsLiBVc2VyLXByb3ZpZGVkIGRlc2NyaXB0aW9uIG9mIHRoZSByZXN0b3JlIHRlbXBs
YXRlLgoKDAoFBAACAQUSA0MCCAoMCgUEAAIBARIDQwkUCgwKBQQAAgEDEgNDFxgKDAoFBAAC
AQgSA0MZQQoPCggEAAIBCJwIABIDQxpACkwKBAQAAgISBEYCRzIaPiBPdXRwdXQgb25seS4g
VGhlIHRpbWUgd2hlbiB0aGUgcmVzdG9yZSB0ZW1wbGF0ZSB3YXMgY3JlYXRlZC4KCgwKBQQA
AgIGEgNGAhsKDAoFBAACAgESA0YcJwoMCgUEAAICAxIDRiorCgwKBQQAAgIIEgNHBjEKDwoI
BAACAgicCAASA0cHMApRCgQEAAIDEgRKAksyGkMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdo
ZW4gdGhlIHJlc3RvcmUgdGVtcGxhdGUgd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgMGEgNK
AhsKDAoFBAACAwESA0ocJwoMCgUEAAIDAxIDSiorCgwKBQQAAgMIEgNLBjEKDwoIBAACAwic
CAASA0sHMAq5AQoEBAACBBIEUAJTBBqqASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgc3Bl
Y2lmaWMgdHlwZSBvZiB0aGUgd29ya2xvYWQgYmVpbmcgcmVzdG9yZWQuCiBUaGUgZm9ybWF0
IGlzICJ7c2VydmljZV9uYW1lfS97cmVzb3VyY2Vfa2luZH0iLCBmb3IgZXhhbXBsZSwKICJj
b21wdXRlLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlIi4KCgwKBQQAAgQFEgNQAggKDAoFBAAC
BAESA1AJFgoMCgUEAAIEAxIDUBkaCg0KBQQAAgQIEgRQG1MDCg8KCAQAAgQInAgAEgNRBCsK
DwoIBAACBAicCAESA1IEKgotCgQEAAIFEgNWAkoaICBPcHRpb25hbC4gVXNlci1kZWZpbmVk
IGxhYmVscy4KCgwKBQQAAgUGEgNWAhUKDAoFBAACBQESA1YWHAoMCgUEAAIFAxIDVh8gCgwK
BQQAAgUIEgNWIUkKDwoIBAACBQicCAASA1YiSAo5CgQEAAIGEgRZAlovGisgUmVxdWlyZWQu
IEJhY2t1cCBzZWxlY3Rpb24gY29uZmlndXJhdGlvbi4KCgwKBQQAAgYGEgNZAhcKDAoFBAAC
BgESA1kYLwoMCgUEAAIGAxIDWTIzCgwKBQQAAgYIEgNaBi4KDwoIBAACBgicCAASA1oHLQo0
CgQEAAIHEgRdAl4vGiYgT3B0aW9uYWwuIFByZS1yZXN0b3JlIGNvbmZpZ3VyYXRpb24uCgoM
CgUEAAIHBhIDXQISCgwKBQQAAgcBEgNdEyUKDAoFBAACBwMSA10oKQoMCgUEAAIHCBIDXgYu
Cg8KCAQAAgcInAgAEgNeBy0KNQoEBAACCBIEYQJiLxonIE9wdGlvbmFsLiBQb3N0LXJlc3Rv
cmUgY29uZmlndXJhdGlvbi4KCgwKBQQAAggGEgNhAhMKDAoFBAACCAESA2EUJwoMCgUEAAII
AxIDYSorCgwKBQQAAggIEgNiBi4KDwoIBAACCAicCAASA2IHLQo1CgQEAAIJEgRlAmYvGicg
T3B0aW9uYWwuIFZlcmlmaWNhdGlvbiBjb25maWd1cmF0aW9uLgoKDAoFBAACCQYSA2UCFAoM
CgUEAAIJARIDZRUoCgwKBQQAAgkDEgNlKy0KDAoFBAACCQgSA2YGLgoPCggEAAIJCJwIABID
ZgctCr8ECgQEAAIKEgRyAnMvGrAEIFJlcXVpcmVkLiBEZWZpbmVzIHRhcmdldCBlbnZpcm9u
bWVudHMgd2hlcmUgdGhlIHJlc291cmNlIHdpbGwgYmUgcmVzdG9yZWQuCgogVGhlIHRhcmdl
dCByZXNvdXJjZSBuYW1lIGluIGByZXN0b3JlX3Byb3BlcnRpZXNgIHN1cHBvcnRzIHRoZQog
YHtFWEVDVVRJT05fSUR9YCB0b2tlbiB0byBkeW5hbWljYWxseSBnZW5lcmF0ZSB1bmlxdWUg
cmVzb3VyY2UgbmFtZXMgZm9yCiBlYWNoIGV4ZWN1dGlvbi4gRHVyaW5nIHJlc3RvcmUgZXhl
Y3V0aW9uLCBldmVyeSBvY2N1cnJlbmNlIG9mCiBge0VYRUNVVElPTl9JRH1gIGluIHRoZSB0
YXJnZXQgcmVzb3VyY2UgbmFtZSBpcyByZXBsYWNlZCB3aXRoIHRoZQogOC1jaGFyYWN0ZXIg
YFJlc3RvcmVUZW1wbGF0ZUV4ZWN1dGlvbmAgSUQgKGZvciBleGFtcGxlLAogYCJyZXN0b3Jl
ZC1yZXNvdXJjZS17RVhFQ1VUSU9OX0lEfSJgIG9yCiBgInJlc3RvcmVkLXtFWEVDVVRJT05f
SUR9LXJlc291cmNlImAgcmVzb2x2ZXMgdG8KIGAicmVzdG9yZWQtcmVzb3VyY2UtNWQ0Mzdi
MDYiYCBvciBgInJlc3RvcmVkLTVkNDM3YjA2LXJlc291cmNlImApLgoKDAoFBAACCgYSA3IC
GAoMCgUEAAIKARIDchkrCgwKBQQAAgoDEgNyLjAKDAoFBAACCggSA3MGLgoPCggEAAIKCJwI
ABIDcwctCj4KBAQAAgsSA3YCPxoxIE91dHB1dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHJl
c3RvcmUgdGVtcGxhdGUuCgoMCgUEAAILBhIDdgIHCgwKBQQAAgsBEgN2CA0KDAoFBAACCwMS
A3YQEgoMCgUEAAILCBIDdhM+Cg8KCAQAAgsInAgAEgN2FD0KOwoEBAACDBIEeQJ6MhotIE91
dHB1dCBvbmx5LiBTdW1tYXJ5IG9mIHRoZSBsYXN0IGV4ZWN1dGlvbi4KCgwKBQQAAgwGEgN5
AhIKDAoFBAACDAESA3kTJAoMCgUEAAIMAxIDeScpCgwKBQQAAgwIEgN6BjEKDwoIBAACDAic
CAASA3oHMAo2CgQEAAINEgN9AjwaKSBPcHRpb25hbC4gRXRhZyBmb3IgY29uY3VycmVuY3kg
Y29udHJvbC4KCgwKBQQAAg0FEgN9AggKDAoFBAACDQESA30JDQoMCgUEAAINAxIDfRASCgwK
BQQAAg0IEgN9EzsKDwoIBAACDQicCAASA30UOgouCgIEARIGgQEAjwEBGiAgU3VtbWFyeSBv
ZiB0aGUgbGFzdCBleGVjdXRpb24uCgoLCgMEAQESBIEBCBgKtwEKBAQBAgASBoUBAooBBBqm
ASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGxhc3QgZXhlY3V0aW9u
LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9y
ZXN0b3JlVGVtcGxhdGVzL3tyZXN0b3JlX3RlbXBsYXRlfS9leGVjdXRpb25zL3tleGVjdXRp
b259YAoKDQoFBAECAAUSBIUBAggKDQoFBAECAAESBIUBCRcKDQoFBAECAAMSBIUBGhsKDwoF
BAECAAgSBoUBHIoBAwoQCggEAQIACJwIABIEhgEELQoRCgcEAQIACJ8IEgaHAQSJAQUKPwoE
BAECARIGjQECjgEyGi8gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgbGFzdCBleGVj
dXRpb24uCgoNCgUEAQIBBhIEjQECKQoNCgUEAQIBARIEjQEqPgoNCgUEAQIBAxIEjQFBQgoN
CgUEAQIBCBIEjgEGMQoQCggEAQIBCJwIABIEjgEHMApICgIEAhIGkgEArQEBGjogUmVxdWVz
dCBtZXNzYWdlIGZvciBjcmVhdGluZyBhIFJlc3RvcmVUZW1wbGF0ZSBpbnN0YW5jZS4KCgsK
AwQCARIEkgEIJAqCAQoEBAICABIGlQECmgEEGnIgUmVxdWlyZWQuIFRoZSByZXN0b3JlIHRl
bXBsYXRlIHByb2plY3QgYW5kIGxvY2F0aW9uIGluIHRoZSBmb3JtYXQKICdwcm9qZWN0cy97
cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0nLgoKDQoFBAICAAUSBJUBAggKDQoF
BAICAAESBJUBCQ8KDQoFBAICAAMSBJUBEhMKDwoFBAICAAgSBpUBFJoBAwoQCggEAgIACJwI
ABIElgEEKgoRCgcEAgIACJ8IEgaXAQSZAQUKggEKBAQCAgESBJ4BAkoadCBSZXF1aXJlZC4g
VGhlIElEIG9mIHRoZSByZXN0b3JlIHRlbXBsYXRlIHRvIGNyZWF0ZS4gVGhlIElEIG11c3Qg
YmUKIHVuaXF1ZSBmb3IgdGhlIHNwZWNpZmllZCBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCg0K
BQQCAgEFEgSeAQIICg0KBQQCAgEBEgSeAQkcCg0KBQQCAgEDEgSeAR8gCg0KBQQCAgEIEgSe
ASFJChAKCAQCAgEInAgAEgSeASJICjUKBAQCAgISBKEBAlAaJyBSZXF1aXJlZC4gQSBSZXN0
b3JlVGVtcGxhdGUgcmVzb3VyY2UuCgoNCgUEAgICBhIEoQECEQoNCgUEAgICARIEoQESIgoN
CgUEAgICAxIEoQElJgoNCgUEAgICCBIEoQEnTwoQCggEAgICCJwIABIEoQEoTgreAgoEBAIC
AxIGqQECrAEEGs0CIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYg
eW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwog
aWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLgoK
IFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlv
biB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAw
LTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQCAgMFEgSpAQIICg0KBQQCAgMBEgSpAQkTCg0K
BQQCAgMDEgSpARYXCg8KBQQCAgMIEgapARisAQMKEwoLBAICAwjM8fmKAQESBKoBBCoKEAoI
BAICAwicCAASBKsBBCoKRwoCBAMSBrABALoBARo5IFJlcXVlc3QgbWVzc2FnZSBmb3IgZ2V0
dGluZyBhIFJlc3RvcmVUZW1wbGF0ZSBpbnN0YW5jZS4KCgsKAwQDARIEsAEIIQqoAQoEBAMC
ABIGtAECuQEEGpcBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgcmVzdG9yZSB0ZW1wbGF0
ZSB0byByZXRyaWV2ZS4KIEZvcm1hdDoKICdwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVzdG9yZVRlbXBsYXRlcy97cmVzdG9yZV90ZW1wbGF0ZV9pZH0n
CgoNCgUEAwIABRIEtAECCAoNCgUEAwIAARIEtAEJDQoNCgUEAwIAAxIEtAEQEQoPCgUEAwIA
CBIGtAESuQEDChAKCAQDAgAInAgAEgS1AQQqChEKBwQDAgAInwgSBrYBBLgBBQpICgIEBBIG
vQEA1wEBGjogUmVxdWVzdCBtZXNzYWdlIGZvciB1cGRhdGluZyBhIFJlc3RvcmVUZW1wbGF0
ZSBpbnN0YW5jZS4KCgsKAwQEARIEvQEIJAq2AgoEBAQCABIGwwECxAEvGqUCIE9wdGlvbmFs
LiBUaGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLgogRmllbGQgbWFzayBpcyB1c2VkIHRv
IHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIFJlc3RvcmVU
ZW1wbGF0ZSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQg
aW4gdGhlIHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAog
dGhlIGZ1bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlz
IGluIHRoZSBtYXNrLgoKDQoFBAQCAAYSBMMBAhsKDQoFBAQCAAESBMMBHCcKDQoFBAQCAAMS
BMMBKisKDQoFBAQCAAgSBMQBBi4KEAoIBAQCAAicCAASBMQBBy0KOQoEBAQCARIExwECUBor
IFJlcXVpcmVkLiBUaGUgcmVzdG9yZSB0ZW1wbGF0ZSB0byB1cGRhdGUuCgoNCgUEBAIBBhIE
xwECEQoNCgUEBAIBARIExwESIgoNCgUEBAIBAxIExwElJgoNCgUEBAIBCBIExwEnTwoQCggE
BAIBCJwIABIExwEoTgreAgoEBAQCAhIGzwEC0gEEGs0CIE9wdGlvbmFsLiBBbiBvcHRpb25h
bCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiBy
ZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91ciByZXF1ZXN0LCB0aGUg
c2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJl
YWR5IGJlZW4gY29tcGxldGVkLgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBV
VUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRl
ZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQEAgIFEgTP
AQIICg0KBQQEAgIBEgTPAQkTCg0KBQQEAgIDEgTPARYXCg8KBQQEAgIIEgbPARjSAQMKEwoL
BAQCAgjM8fmKAQESBNABBCoKEAoIBAQCAgicCAASBNEBBCoKawoEBAQCAxIE1gECQhpdIE9w
dGlvbmFsLiBPbmx5IHZhbGlkYXRlIHRoZSByZXF1ZXN0LCBidXQgZG8gbm90IHBlcmZvcm0g
bXV0YXRpb25zLgogVGhlIGRlZmF1bHQgaXMgJ2ZhbHNlJy4KCg0KBQQEAgMFEgTWAQIGCg0K
BQQEAgMBEgTWAQcUCg0KBQQEAgMDEgTWARcYCg0KBQQEAgMIEgTWARlBChAKCAQEAgMInAgA
EgTWARpACkgKAgQFEgbaAQD0AQEaOiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEg
UmVzdG9yZVRlbXBsYXRlIGluc3RhbmNlLgoKCwoDBAUBEgTaAQgkCqYBCgQEBQIAEgbeAQLj
AQQalQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXN0b3JlIHRlbXBsYXRlIHRvIGRl
bGV0ZS4KIEZvcm1hdDoKICdwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vcmVzdG9yZVRlbXBsYXRlcy97cmVzdG9yZV90ZW1wbGF0ZV9pZH0nCgoNCgUEBQIA
BRIE3gECCAoNCgUEBQIAARIE3gEJDQoNCgUEBQIAAxIE3gEQEQoPCgUEBQIACBIG3gES4wED
ChAKCAQFAgAInAgAEgTfAQQqChEKBwQFAgAInwgSBuABBOIBBQreAgoEBAUCARIG6wEC7gEE
Gs0CIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVl
c3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3Qg
cmV0cnkgeW91ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRo
ZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLgoKIFRoZSByZXF1
ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHpl
cm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAw
MDAwMDAwMDAwKS4KCg0KBQQFAgEFEgTrAQIICg0KBQQFAgEBEgTrAQkTCg0KBQQFAgEDEgTr
ARYXCg8KBQQFAgEIEgbrARjuAQMKEwoLBAUCAQjM8fmKAQESBOwBBCoKEAoIBAUCAQicCAAS
BO0BBCoKuAEKBAQFAgISBPMBAjoaqQEgT3B0aW9uYWwuIElmIHNldCB0byB0cnVlLCBhbnkg
Y2hpbGQgUmVzdG9yZVRlbXBsYXRlRXhlY3V0aW9ucyB3aWxsIGFsc28gYmUKIGRlbGV0ZWQu
IElmIGZhbHNlIGFuZCB0aGUgUmVzdG9yZVRlbXBsYXRlIGhhcyBhbnkgY2hpbGQgZXhlY3V0
aW9ucywgdGhlCiByZXF1ZXN0IHdpbGwgZmFpbC4KCg0KBQQFAgIFEgTzAQIGCg0KBQQFAgIB
EgTzAQcMCg0KBQQFAgIDEgTzAQ8QCg0KBQQFAgIIEgTzARE5ChAKCAQFAgIInAgAEgTzARI4
Cj4KAgQGEgb3AQCWAgEaMCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHJ1bm5pbmcgYSBSZXN0b3Jl
VGVtcGxhdGUuCgoLCgMEBgESBPcBCCEKowEKBAQGAgASBvsBAoACBBqSASBSZXF1aXJlZC4g
VGhlIG5hbWUgb2YgdGhlIHJlc3RvcmUgdGVtcGxhdGUgdG8gcnVuLgogRm9ybWF0OgogJ3By
b2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVGVtcGxh
dGVzL3tyZXN0b3JlX3RlbXBsYXRlX2lkfScKCg0KBQQGAgAFEgT7AQIICg0KBQQGAgABEgT7
AQkNCg0KBQQGAgADEgT7ARARCg8KBQQGAgAIEgb7ARKAAgMKEAoIBAYCAAicCAASBPwBBCoK
EQoHBAYCAAifCBIG/QEE/wEFCr8CCgQEBgIBEgaHAgKKAgQargIgT3B0aW9uYWwuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBCYWNrdXAgdG8gcmVzdG9yZSBmcm9tLgogSWYgbm90IHNw
ZWNpZmllZCwgdGhlIGxhdGVzdCBiYWNrdXAgbWF0Y2hpbmcgdGhlIGJhY2t1cCBzZWxlY3Rp
b24KIGNvbmZpZ3VyYXRpb24gaW4gdGhlIFJlc3RvcmVUZW1wbGF0ZSB3aWxsIGJlIHVzZWQu
CiBGb3JtYXQ6CiAncHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Jh
Y2t1cFZhdWx0cy97YmFja3VwX3ZhdWx0fS9kYXRhU291cmNlcy97ZGF0YV9zb3VyY2V9L2Jh
Y2t1cHMve2JhY2t1cH0nCgoNCgUEBgIBBRIEhwICCAoNCgUEBgIBARIEhwIJDwoNCgUEBgIB
AxIEhwISEwoPCgUEBgIBCBIGhwIUigIDChAKCAQGAgEInAgAEgSIAgQqCg8KBwQGAgEInwgS
BIkCBFAK3gIKBAQGAgISBpICApUCBBrNAiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVz
dCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJ
RCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3
aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVu
IGNvbXBsZXRlZC4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRo
IHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAw
MDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBgICBRIEkgICCAoNCgUE
BgICARIEkgIJEwoNCgUEBgICAxIEkgIWFwoPCgUEBgICCBIGkgIYlQIDChMKCwQGAgIIzPH5
igEBEgSTAgQqChAKCAQGAgIInAgAEgSUAgQqCjgKAgQHEgaZAgCjAgEaKiBSZXNwb25zZSBt
ZXNzYWdlIGZvciBSdW5SZXN0b3JlVGVtcGxhdGUuCgoLCgMEBwESBJkCCCIKywEKBAQHAgAS
Bp0CAqICBBq6ASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGluaXRp
YXRlZCBSZXN0b3JlVGVtcGxhdGVFeGVjdXRpb24uCiBGb3JtYXQ6CiBgcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVUZW1wbGF0ZXMve3Jlc3RvcmVf
dGVtcGxhdGV9L2V4ZWN1dGlvbnMve2V4ZWN1dGlvbn1gCgoNCgUEBwIABRIEnQICCAoNCgUE
BwIAARIEnQIJIwoNCgUEBwIAAxIEnQImJwoPCgUEBwIACBIGnQIoogIDChAKCAQHAgAInAgA
EgSeAgQtChEKBwQHAgAInwgSBp8CBKECBQo9CgIECBIGpgIAvQIBGi8gUmVxdWVzdCBtZXNz
YWdlIGZvciBsaXN0aW5nIFJlc3RvcmVUZW1wbGF0ZXMuCgoLCgMECAESBKYCCCMKlAEKBAQI
AgASBqoCAq8CBBqDASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZyb20g
d2hpY2ggdG8gbGlzdCB0aGUgcmVzdG9yZQogdGVtcGxhdGVzLgogRm9ybWF0OiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4KCg0KBQQIAgAFEgSqAgIICg0K
BQQIAgABEgSqAgkPCg0KBQQIAgADEgSqAhITCg8KBQQIAgAIEgaqAhSvAgMKEAoIBAgCAAic
CAASBKsCBCoKEQoHBAgCAAifCBIGrAIErgIFCkAKBAQIAgESBLICAj8aMiBPcHRpb25hbC4g
VGhlIG1heGltdW0gbnVtYmVyIG9mIGl0ZW1zIHRvIHJldHVybi4KCg0KBQQIAgEFEgSyAgIH
Cg0KBQQIAgEBEgSyAggRCg0KBQQIAgEDEgSyAhQVCg0KBQQIAgEIEgSyAhY+ChAKCAQIAgEI
nAgAEgSyAhc9Cl4KBAQIAgISBLYCAkEaUCBPcHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNl
aXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RSZXN0b3JlVGVtcGxhdGVzYAogY2FsbC4KCg0K
BQQIAgIFEgS2AgIICg0KBQQIAgIBEgS2AgkTCg0KBQQIAgIDEgS2AhYXCg0KBQQIAgIIEgS2
AhhAChAKCAQIAgIInAgAEgS2Ahk/CkwKBAQIAgMSBLkCAj0aPiBPcHRpb25hbC4gRmllbGQg
bWF0Y2ggZXhwcmVzc2lvbiB1c2VkIHRvIGZpbHRlciB0aGUgcmVzdWx0cy4KCg0KBQQIAgMF
EgS5AgIICg0KBQQIAgMBEgS5AgkPCg0KBQQIAgMDEgS5AhITCg0KBQQIAgMIEgS5AhQ8ChAK
CAQIAgMInAgAEgS5AhU7Cj0KBAQIAgQSBLwCAj8aLyBPcHRpb25hbC4gRmllbGQgYnkgd2hp
Y2ggdG8gc29ydCB0aGUgcmVzdWx0cy4KCg0KBQQIAgQFEgS8AgIICg0KBQQIAgQBEgS8AgkR
Cg0KBQQIAgQDEgS8AhQVCg0KBQQIAgQIEgS8AhY+ChAKCAQIAgQInAgAEgS8Ahc9Cj4KAgQJ
EgbAAgDKAgEaMCBSZXNwb25zZSBtZXNzYWdlIGZvciBsaXN0aW5nIFJlc3RvcmVUZW1wbGF0
ZXMuCgoLCgMECQESBMACCCQKLQoEBAkCABIEwgICMRofIFRoZSBsaXN0IG9mIFJlc3RvcmVU
ZW1wbGF0ZXMuCgoNCgUECQIABBIEwgICCgoNCgUECQIABhIEwgILGgoNCgUECQIAARIEwgIb
LAoNCgUECQIAAxIEwgIvMApnCgQECQIBEgTGAgIdGlkgQSB0b2tlbiB3aGljaCBtYXkgYmUg
c2VudCBhcyBgcGFnZV90b2tlbmAgaW4gYSBzdWJzZXF1ZW50CiBgTGlzdFJlc3RvcmVUZW1w
bGF0ZXNgIGNhbGwuCgoNCgUECQIBBRIExgICCAoNCgUECQIBARIExgIJGAoNCgUECQIBAxIE
xgIbHAo0CgQECQICEgTJAgIiGiYgTG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNo
ZWQuCgoNCgUECQICBBIEyQICCgoNCgUECQICBRIEyQILEQoNCgUECQICARIEyQISHQoNCgUE
CQICAxIEyQIgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate ===
    # Fields for RestoreTemplate
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resource_type Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1beta.RestoreTemplate.LabelsEntry)
    # Field: backup_selection_config Type: 11 (.google.cloud.backupdr.v1beta.BackupSelectionConfig)
    # Field: pre_restore_config Type: 11 (.google.cloud.backupdr.v1beta.PreRestoreConfig)
    # Field: post_restore_config Type: 11 (.google.cloud.backupdr.v1beta.PostRestoreConfig)
    # Field: verification_config Type: 11 (.google.cloud.backupdr.v1beta.VerificationConfig)
    # Field: restore_properties Type: 11 (.google.protobuf.Struct)
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.RestoreTemplate.State)
    # Field: execution_summary Type: 11 (.google.cloud.backupdr.v1beta.ExecutionSummary)
    # Field: etag Type: 9 ()

# Enum: RestoreTemplate::State
our $RestoreTemplate_STATE_UNSPECIFIED = 0;
our $RestoreTemplate_CREATING = 1;
our $RestoreTemplate_ACTIVE = 2;
our $RestoreTemplate_UPDATING = 3;
our $RestoreTemplate_DELETING = 4;

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::ExecutionSummary ===
    # Fields for ExecutionSummary
    # Field: last_execution Type: 9 ()
    # Field: last_execution_state Type: 14 (.google.cloud.backupdr.v1beta.RestoreTemplateExecution.ExecutionState)

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::CreateRestoreTemplateRequest ===
    # Fields for CreateRestoreTemplateRequest
    # Field: parent Type: 9 ()
    # Field: restore_template_id Type: 9 ()
    # Field: restore_template Type: 11 (.google.cloud.backupdr.v1beta.RestoreTemplate)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::GetRestoreTemplateRequest ===
    # Fields for GetRestoreTemplateRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::UpdateRestoreTemplateRequest ===
    # Fields for UpdateRestoreTemplateRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: restore_template Type: 11 (.google.cloud.backupdr.v1beta.RestoreTemplate)
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::DeleteRestoreTemplateRequest ===
    # Fields for DeleteRestoreTemplateRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::RunRestoreTemplateRequest ===
    # Fields for RunRestoreTemplateRequest
    # Field: name Type: 9 ()
    # Field: backup Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::RunRestoreTemplateResponse ===
    # Fields for RunRestoreTemplateResponse
    # Field: restore_template_execution Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::ListRestoreTemplatesRequest ===
    # Fields for ListRestoreTemplatesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplate::ListRestoreTemplatesResponse ===
    # Fields for ListRestoreTemplatesResponse
    # Field: restore_templates Type: 11 (.google.cloud.backupdr.v1beta.RestoreTemplate)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreTemplate - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/restore_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::RestoreTemplate;

    my $msg = Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/restore_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate

A `RestoreTemplate` encapsulates DR readiness configurations for validating
backups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the RestoreTemplate.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-provided description of the restore template.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the restore template was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the restore template was last updated.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Immutable. The specific type of the workload being restored.
The format is "{service_name}/{resource_kind}", for example,
"compute.googleapis.com/Instance".

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate::LabelsEntry>)

Optional. User-defined labels.

=item * C<< $msg->backup_selection_config() >> / C<< $msg->backup_selection_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::BackupSelectionConfig>)

Required. Backup selection configuration.

=item * C<< $msg->pre_restore_config() >> / C<< $msg->pre_restore_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PreRestoreConfig>)

Optional. Pre-restore configuration.

=item * C<< $msg->post_restore_config() >> / C<< $msg->post_restore_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PostRestoreConfig>)

Optional. Post-restore configuration.

=item * C<< $msg->verification_config() >> / C<< $msg->verification_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::VerificationConfig>)

Optional. Verification configuration.

=item * C<< $msg->restore_properties() >> / C<< $msg->restore_properties($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. Defines target environments where the resource will be restored.

The target resource name in `restore_properties` supports the
`{EXECUTION_ID}` token to dynamically generate unique resource names for
each execution. During restore execution, every occurrence of
`{EXECUTION_ID}` in the target resource name is replaced with the
8-character `RestoreTemplateExecution` ID (for example,
`"restored-resource-{EXECUTION_ID}"` or
`"restored-{EXECUTION_ID}-resource"` resolves to
`"restored-resource-5d437b06"` or `"restored-5d437b06-resource"`).

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::State>)

Output only. The state of the restore template.

=item * C<< $msg->execution_summary() >> / C<< $msg->execution_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::ExecutionSummary>)

Output only. Summary of the last execution.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Optional. Etag for concurrency control.

=back

=head3 Enum: RestoreTemplate::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::ExecutionSummary

Summary of the last execution.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->last_execution() >> / C<< $msg->last_execution($value) >>

Type: C<String>

Output only. The resource name of the last execution.
Format:
`projects/{project}/locations/{location}/restoreTemplates/{restore_template}/executions/{execution}`

=item * C<< $msg->last_execution_state() >> / C<< $msg->last_execution_state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplateExecution::ExecutionState>)

Output only. The state of the last execution.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::CreateRestoreTemplateRequest

Request message for creating a RestoreTemplate instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The restore template project and location in the format
'projects/{project_id}/locations/{location}'.

=item * C<< $msg->restore_template_id() >> / C<< $msg->restore_template_id($value) >>

Type: C<String>

Required. The ID of the restore template to create. The ID must be
unique for the specified project and location.

=item * C<< $msg->restore_template() >> / C<< $msg->restore_template($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate>)

Required. A RestoreTemplate resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::GetRestoreTemplateRequest

Request message for getting a RestoreTemplate instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the restore template to retrieve.
Format:
'projects/{project_id}/locations/{location}/restoreTemplates/{restore_template_id}'

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::UpdateRestoreTemplateRequest

Request message for updating a RestoreTemplate instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.
Field mask is used to specify the fields to be overwritten in the
RestoreTemplate resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask.

=item * C<< $msg->restore_template() >> / C<< $msg->restore_template($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate>)

Required. The restore template to update.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Only validate the request, but do not perform mutations.
The default is 'false'.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::DeleteRestoreTemplateRequest

Request message for deleting a RestoreTemplate instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the restore template to delete.
Format:
'projects/{project_id}/locations/{location}/restoreTemplates/{restore_template_id}'

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, any child RestoreTemplateExecutions will also be
deleted. If false and the RestoreTemplate has any child executions, the
request will fail.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::RunRestoreTemplateRequest

Request message for running a RestoreTemplate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the restore template to run.
Format:
'projects/{project_id}/locations/{location}/restoreTemplates/{restore_template_id}'

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<String>

Optional. The resource name of the Backup to restore from.
If not specified, the latest backup matching the backup selection
configuration in the RestoreTemplate will be used.
Format:
'projects/{project}/locations/{location}/backupVaults/{backup_vault}/dataSources/{data_source}/backups/{backup}'

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::RunRestoreTemplateResponse

Response message for RunRestoreTemplate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_template_execution() >> / C<< $msg->restore_template_execution($value) >>

Type: C<String>

Output only. The resource name of the initiated RestoreTemplateExecution.
Format:
`projects/{project}/locations/{location}/restoreTemplates/{restore_template}/executions/{execution}`

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::ListRestoreTemplatesRequest

Request message for listing RestoreTemplates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which to list the restore
templates.
Format: `projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListRestoreTemplates`
call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Field match expression used to filter the results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field by which to sort the results.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplate::ListRestoreTemplatesResponse

Response message for listing RestoreTemplates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_templates() >> / C<< $msg->restore_templates($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::RestoreTemplate>)

The list of RestoreTemplates.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token which may be sent as `page_token` in a subsequent
`ListRestoreTemplates` call.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::RestoreTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
