package Google::Cloud::Oracledatabase::V1::DatabaseConnection;

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
Cjhnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGF0YWJhc2VfY29ubmVjdGlvbi5w
cm90bxIeZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrUJChJEYXRhYmFzZUNvbm5lY3Rpb24S
aAoVd2FsbGV0X3NlY3JldF92ZXJzaW9uGAYgASgJQjLgQQH6QSwKKnNlY3JldG1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vU2VjcmV0VmVyc2lvbkgAUhN3YWxsZXRTZWNyZXRWZXJzaW9uElYK
C29kYl9uZXR3b3JrGAcgASgJQjPgQQHgQQX6QSoKKG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFw
aXMuY29tL09kYk5ldHdvcmtIAVIKb2RiTmV0d29yaxIXCgRuYW1lGAEgASgJQgPgQQhSBG5h
bWUSKQoMZGlzcGxheV9uYW1lGAIgASgJQgbgQQHgQQVSC2Rpc3BsYXlOYW1lEiIKCHVzZXJu
YW1lGAMgASgJQgbgQQHgQQVSCHVzZXJuYW1lEmoKF3Bhc3N3b3JkX3NlY3JldF92ZXJzaW9u
GAQgASgJQjLgQQH6QSwKKnNlY3JldG1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vU2VjcmV0VmVy
c2lvblIVcGFzc3dvcmRTZWNyZXRWZXJzaW9uEjMKEWNvbm5lY3Rpb25fc3RyaW5nGAUgASgJ
QgbgQQLgQQVSEGNvbm5lY3Rpb25TdHJpbmcSUwoFc3RhdGUYCiABKA4yOC5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuRGF0YWJhc2VDb25uZWN0aW9uLlN0YXRlQgPgQQNSBXN0
YXRlElsKBmxhYmVscxgLIAMoCzI+Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5E
YXRhYmFzZUNvbm5lY3Rpb24uTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzEkAKC2NyZWF0ZV90
aW1lGAwgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkAKC3VwZGF0ZV90aW1lGA0gASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EED
Ugp1cGRhdGVUaW1lEjAKEWxpZmVjeWNsZV9kZXRhaWxzGA4gASgJQgPgQQNSEGxpZmVjeWNs
ZURldGFpbHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ASJSCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFU
SU5HEAESCgoGQUNUSVZFEAISCgoGRkFJTEVEEAMSDAoIREVMRVRJTkcQBDqyAepBrgEKMG9y
YWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0RhdGFiYXNlQ29ubmVjdGlvbhJRcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFiYXNlQ29ubmVjdGlvbnMv
e2RhdGFiYXNlX2Nvbm5lY3Rpb259KhNkYXRhYmFzZUNvbm5lY3Rpb25zMhJkYXRhYmFzZUNv
bm5lY3Rpb25CDwoNd2FsbGV0X3NvdXJjZUIXChVuZXR3b3JrX2NvbmZpZ3VyYXRpb24ixAIK
H0NyZWF0ZURhdGFiYXNlQ29ubmVjdGlvblJlcXVlc3QSUAoGcGFyZW50GAEgASgJQjjgQQL6
QTISMG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0RhdGFiYXNlQ29ubmVjdGlvblIG
cGFyZW50EjkKFmRhdGFiYXNlX2Nvbm5lY3Rpb25faWQYAiABKAlCA+BBAlIUZGF0YWJhc2VD
b25uZWN0aW9uSWQSaAoTZGF0YWJhc2VfY29ubmVjdGlvbhgDIAEoCzIyLmdvb2dsZS5jbG91
ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRhYmFzZUNvbm5lY3Rpb25CA+BBAlISZGF0YWJhc2VD
b25uZWN0aW9uEioKCnJlcXVlc3RfaWQYBCABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQi
mwEKH0RlbGV0ZURhdGFiYXNlQ29ubmVjdGlvblJlcXVlc3QSTAoEbmFtZRgBIAEoCUI44EEC
+kEyCjBvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZUNvbm5lY3Rpb25S
BG5hbWUSKgoKcmVxdWVzdF9pZBgCIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJZCL1AQoe
TGlzdERhdGFiYXNlQ29ubmVjdGlvbnNSZXF1ZXN0ElAKBnBhcmVudBgBIAEoCUI44EEC+kEy
EjBvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZUNvbm5lY3Rpb25SBnBh
cmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgD
IAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVyGAQgASgJQgPgQQFSBmZpbHRlchIeCghv
cmRlcl9ieRgFIAEoCUID4EEBUgdvcmRlckJ5ItIBCh9MaXN0RGF0YWJhc2VDb25uZWN0aW9u
c1Jlc3BvbnNlEmUKFGRhdGFiYXNlX2Nvbm5lY3Rpb25zGAEgAygLMjIuZ29vZ2xlLmNsb3Vk
Lm9yYWNsZWRhdGFiYXNlLnYxLkRhdGFiYXNlQ29ubmVjdGlvblITZGF0YWJhc2VDb25uZWN0
aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFj
aGFibGUYAyADKAlSC3VucmVhY2hhYmxlImwKHEdldERhdGFiYXNlQ29ubmVjdGlvblJlcXVl
c3QSTAoEbmFtZRgBIAEoCUI44EEC+kEyCjBvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNv
bS9EYXRhYmFzZUNvbm5lY3Rpb25SBG5hbWUi+QEKH1VwZGF0ZURhdGFiYXNlQ29ubmVjdGlv
blJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRN
YXNrQgPgQQFSCnVwZGF0ZU1hc2sSaAoTZGF0YWJhc2VfY29ubmVjdGlvbhgCIAEoCzIyLmdv
b2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRhYmFzZUNvbm5lY3Rpb25CA+BBAlIS
ZGF0YWJhc2VDb25uZWN0aW9uEioKCnJlcXVlc3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUgly
ZXF1ZXN0SWQibQodVGVzdERhdGFiYXNlQ29ubmVjdGlvblJlcXVlc3QSTAoEbmFtZRgBIAEo
CUI44EEC+kEyCjBvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZUNvbm5l
Y3Rpb25SBG5hbWUiXwoeVGVzdERhdGFiYXNlQ29ubmVjdGlvblJlc3BvbnNlEhgKB3N1Y2Nl
c3MYASABKAhSB3N1Y2Nlc3MSIwoNZXJyb3JfbWVzc2FnZRgCIAEoCVIMZXJyb3JNZXNzYWdl
QvEBCiJjb20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxQhdEYXRhYmFzZUNvbm5l
Y3Rpb25Qcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYx
L29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFj
bGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2ds
ZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUq1UQoHEgUOAKwCAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACUK
CQoCAwISAxQAIwoJCgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA7CgkKAgglEgMYADsK
CAoBCBIDGQBhCgkKAggLEgMZAGEKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA4CgkK
AggIEgMbADgKCAoBCBIDHAA7CgkKAggBEgMcADsKCAoBCBIDHQA7CgkKAggpEgMdADsKCAoB
CBIDHgA6CgkKAggtEgMeADoKNgoCBAASBSEAjQEBGikgUmVwcmVzZW50cyBEYXRhYmFzZUNv
bm5lY3Rpb24gcmVzb3VyY2UuCgoKCgMEAAESAyEIGgoLCgMEAAcSBCICJwQKDQoFBAAHnQgS
BCICJwQKOgoEBAAEABIEKgI5AxosIFN0YXRlcyBvZiB0aGUgRGF0YWJhc2VDb25uZWN0aW9u
IHJlc291cmNlLgoKDAoFBAAEAAESAyoHDAorCgYEAAQAAgASAywEGhocIERlZmF1bHQgdW5z
cGVjaWZpZWQgdmFsdWUuCgoOCgcEAAQAAgABEgMsBBUKDgoHBAAEAAIAAhIDLBgZCkQKBgQA
BAACARIDLwQRGjUgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGEgY3JlYXRp
bmcgc3RhdGUuCgoOCgcEAAQAAgEBEgMvBAwKDgoHBAAEAAIBAhIDLw8QCkMKBgQABAACAhID
MgQPGjQgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGFuIGFjdGl2ZSBzdGF0
ZS4KCg4KBwQABAACAgESAzIECgoOCgcEAAQAAgICEgMyDQ4KQgoGBAAEAAIDEgM1BA8aMyBJ
bmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gYSBmYWlsZWQgc3RhdGUuCgoOCgcE
AAQAAgMBEgM1BAoKDgoHBAAEAAIDAhIDNQ0OCkQKBgQABAACBBIDOAQRGjUgSW5kaWNhdGVz
IHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGEgZGVsZXRpbmcgc3RhdGUuCgoOCgcEAAQAAgQB
EgM4BAwKDgoHBAAEAAIEAhIDOA8QClIKBAQACAASBDwCSQMaRCBIb3cgdGhlIE9yYWNsZSBX
YWxsZXQgaXMgc3VwcGxpZWQgZm9yIHNlY3VyZSBUTFMvbVRMUyBjb25uZWN0aW9ucy4KCgwK
BQQACAABEgM8CBUKkQMKBAQAAgASBEMESAYaggMgT3B0aW9uYWwuIE9wdGlvbmFsOiBUaGUg
cmVzb3VyY2UgbmFtZSBvZiB0aGUgR0NQIFNlY3JldCBNYW5hZ2VyIHNlY3JldAogdmVyc2lv
biBjb250YWluaW5nIGJhc2U2NCBlbmNvZGVkIGNvbnRlbnQgb2YgdGhlIE9yYWNsZSBXYWxs
ZXQgWklQIGZpbGUKIHJlcXVpcmVkIGZvciBtVExTL1RMUyBjb25uZWN0aW9ucy4gRm9ybWF0
OgogcHJvamVjdHMve3Byb2plY3R9L3NlY3JldHMve3NlY3JldF9pZH0vdmVyc2lvbnMve3Zl
cnNpb25faWR9IFRoZQogc2VydmljZSdzIFBlci1Qcm9kdWN0IFBlci1Qcm9qZWN0IFNlcnZp
Y2UgQWNjb3VudCAoUDRTQSkgbXVzdCBoYXZlIHRoZQogJ3NlY3JldG1hbmFnZXIuc2VjcmV0
QWNjZXNzb3InIHBlcm1pc3Npb24gb24gdGhpcyBzZWNyZXQuCgoMCgUEAAIABRIDQwQKCgwK
BQQAAgABEgNDCyAKDAoFBAACAAMSA0MjJAoNCgUEAAIACBIEQyVIBQoPCggEAAIACJwIABID
RAYsCg8KBwQAAgAInwgSBEUGRwcKQAoEBAAIARIETAJWAxoyIE5ldHdvcmsgY29uZmlndXJh
dGlvbiBmb3IgcmVhY2hpbmcgdGhlIGRhdGFiYXNlLgoKDAoFBAAIAQESA0wIHQqbAQoEBAAC
ARIETwRVBhqMASBPcHRpb25hbC4gSW1tdXRhYmxlLiBGb3IgT3JhY2xlIERhdGFiYXNlQEdv
b2dsZSBjbG91ZCByZXNvdXJjZXMuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9vZGJOZXR3b3Jrcy97b2RiTmV0d29ya30KCgwKBQQAAgEFEgNP
BAoKDAoFBAACAQESA08LFgoMCgUEAAIBAxIDTxkaCg0KBQQAAgEIEgRPG1UFCg8KCAQAAgEI
nAgAEgNQBiwKDwoIBAACAQicCAESA1EGLQoPCgcEAAIBCJ8IEgRSBlQHCqQBCgQEAAICEgNb
Aj0algEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIERhdGFiYXNlQ29u
bmVjdGlvbi4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9kYXRhYmFzZUNvbm5lY3Rpb25zL3tkYXRhYmFzZV9jb25uZWN0aW9ufQoKDAoFBAAC
AgUSA1sCCAoMCgUEAAICARIDWwkNCgwKBQQAAgIDEgNbEBEKDAoFBAACAggSA1sSPAoPCggE
AAICCJwIABIDWxM7ClMKBAQAAgMSBF4CYQQaRSBPcHRpb25hbC4gSW1tdXRhYmxlLiBVc2Vy
LWZyaWVuZGx5IGRpc3BsYXkgbmFtZSBmb3IgdGhlIGNvbm5lY3Rpb24uCgoMCgUEAAIDBRID
XgIICgwKBQQAAgMBEgNeCRUKDAoFBAACAwMSA14YGQoNCgUEAAIDCBIEXhphAwoPCggEAAID
CJwIABIDXwQqCg8KCAQAAgMInAgBEgNgBCsKWgoEBAACBBIEZAJnBBpMIE9wdGlvbmFsLiBJ
bW11dGFibGUuIFRoZSBkZWZhdWx0IGRhdGFiYXNlIHVzZXJuYW1lIHRvIHVzZSBmb3IgY29u
bmVjdGlvbnMuCgoMCgUEAAIEBRIDZAIICgwKBQQAAgQBEgNkCREKDAoFBAACBAMSA2QUFQoN
CgUEAAIECBIEZBZnAwoPCggEAAIECJwIABIDZQQqCg8KCAQAAgQInAgBEgNmBCsK1wIKBAQA
AgUSBG4CcwQayAIgT3B0aW9uYWwuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBHQ1AgU2Vj
cmV0IE1hbmFnZXIgc2VjcmV0IHZlcnNpb24KIGNvbnRhaW5pbmcgdGhlIHBhc3N3b3JkIGZv
ciB0aGUgc3BlY2lmaWVkIHVzZXJuYW1lLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0v
c2VjcmV0cy97c2VjcmV0X2lkfS92ZXJzaW9ucy97dmVyc2lvbl9pZH0KIFRoZSBzZXJ2aWNl
J3MgUGVyLVByb2R1Y3QgUGVyLVByb2plY3QgU2VydmljZSBBY2NvdW50IChQNFNBKQogbXVz
dCBoYXZlIHRoZSAnc2VjcmV0bWFuYWdlci5zZWNyZXRBY2Nlc3NvcicgcGVybWlzc2lvbiBv
biB0aGlzIHNlY3JldC4KCgwKBQQAAgUFEgNuAggKDAoFBAACBQESA24JIAoMCgUEAAIFAxID
biMkCg0KBQQAAgUIEgRuJXMDCg8KCAQAAgUInAgAEgNvBCoKDwoHBAACBQifCBIEcARyBQqP
AQoEBAACBhIEdwJ6BBqAASBSZXF1aXJlZC4gSW1tdXRhYmxlLiBPcmFjbGUgRWFzeSBDb25u
ZWN0IG9yIFROUyBjb25uZWN0aW9uIHN0cmluZy4KIEV4YW1wbGU6ICJ5b3VyLWRiLWhvc3Qu
ZXhhbXBsZS5jb206MTUyMS9ZT1VSX1NFUlZJQ0VfTkFNRSIKCgwKBQQAAgYFEgN3AggKDAoF
BAACBgESA3cJGgoMCgUEAAIGAxIDdx0eCg0KBQQAAgYIEgR3H3oDCg8KCAQAAgYInAgAEgN4
BCoKDwoIBAACBgicCAESA3kEKwpACgQEAAIHEgN9Aj8aMyBPdXRwdXQgb25seS4gVGhlIGN1
cnJlbnQgc3RhdGUgb2YgdGhlIGNvbm5lY3Rpb24uCgoMCgUEAAIHBhIDfQIHCgwKBQQAAgcB
EgN9CA0KDAoFBAACBwMSA30QEgoMCgUEAAIHCBIDfRM+Cg8KCAQAAgcInAgAEgN9FD0KVwoE
BAACCBIEgAECSxpJIE9wdGlvbmFsLiBPcHRpb25hbDogTGFiZWxzIGFzIGtleS12YWx1ZSBw
YWlycyB0byBvcmdhbml6ZSB0aGUgcmVzb3VyY2UuCgoNCgUEAAIIBhIEgAECFQoNCgUEAAII
ARIEgAEWHAoNCgUEAAIIAxIEgAEfIQoNCgUEAAIICBIEgAEiSgoQCggEAAIICJwIABIEgAEj
SQo/CgQEAAIJEgaDAQKEATIaLyBPdXRwdXQgb25seS4gVGhlIGNyZWF0ZSB0aW1lIG9mIHRo
ZSByZXNvdXJjZS4KCg0KBQQAAgkGEgSDAQIbCg0KBQQAAgkBEgSDARwnCg0KBQQAAgkDEgSD
ASosCg0KBQQAAgkIEgSEAQYxChAKCAQAAgkInAgAEgSEAQcwCj8KBAQAAgoSBocBAogBMhov
IE91dHB1dCBvbmx5LiBUaGUgdXBkYXRlIHRpbWUgb2YgdGhlIHJlc291cmNlLgoKDQoFBAAC
CgYSBIcBAhsKDQoFBAACCgESBIcBHCcKDQoFBAACCgMSBIcBKiwKDQoFBAACCggSBIgBBjEK
EAoIBAACCgicCAASBIgBBzAKXwoEBAACCxIEjAECTBpRIE91dHB1dCBvbmx5LiBBZGRpdGlv
bmFsIGluZm9ybWF0aW9uIGFib3V0IHRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZQogY29ubmVj
dGlvbi4KCg0KBQQAAgsFEgSMAQIICg0KBQQAAgsBEgSMAQkaCg0KBQQAAgsDEgSMAR0fCg0K
BQQAAgsIEgSMASBLChAKCAQAAgsInAgAEgSMASFKCjwKAgQBEgaQAQCwAQEaLiBUaGUgcmVx
dWVzdCBmb3IgYERhdGFiYXNlQ29ubmVjdGlvbi5DcmVhdGVgLgoKCwoDBAEBEgSQAQgnCooB
CgQEAQIAEgaTAQKYAQQaeiBSZXF1aXJlZC4gVGhlIHBhcmVudCB2YWx1ZSBmb3IgdGhlIERh
dGFiYXNlQ29ubmVjdGlvbiBpbiB0aGUgZm9sbG93aW5nCiBmb3JtYXQ6IHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS4KCg0KBQQBAgAFEgSTAQIICg0KBQQBAgAB
EgSTAQkPCg0KBQQBAgADEgSTARITCg8KBQQBAgAIEgaTARSYAQMKEAoIBAECAAicCAASBJQB
BCoKEQoHBAECAAifCBIGlQEElwEFCoECCgQEAQIBEgSeAQJNGvIBIFJlcXVpcmVkLiBUaGUg
SUQgb2YgdGhlIERhdGFiYXNlQ29ubmVjdGlvbiB0byBjcmVhdGUuIFRoaXMgdmFsdWUgaXMK
IHJlc3RyaWN0ZWQgdG8gKF5bYS16XShbYS16MC05LV17MCw2MX1bYS16MC05XSk/JCkgYW5k
IG11c3QgYmUgYSBtYXhpbXVtIG9mCiA2MyBjaGFyYWN0ZXJzIGluIGxlbmd0aC4gVGhlIHZh
bHVlIG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlciBhbmQgZW5kIHdpdGggYQogbGV0dGVyIG9y
IGEgbnVtYmVyLgoKDQoFBAECAQUSBJ4BAggKDQoFBAECAQESBJ4BCR8KDQoFBAECAQMSBJ4B
IiMKDQoFBAECAQgSBJ4BJEwKEAoIBAECAQicCAASBJ4BJUsKUQoEBAECAhIGoQECogEvGkEg
UmVxdWlyZWQuIERldGFpbHMgb2YgdGhlIERhdGFiYXNlQ29ubmVjdGlvbiBpbnN0YW5jZSB0
byBjcmVhdGUuCgoNCgUEAQICBhIEoQECFAoNCgUEAQICARIEoQEVKAoNCgUEAQICAxIEoQEr
LAoNCgUEAQICCBIEogEGLgoQCggEAQICCJwIABIEogEHLQrXAwoEBAECAxIGrAECrwEEGsYD
IE9wdGlvbmFsLiBBbiBvcHRpb25hbCBJRCB0byBpZGVudGlmeSB0aGUgcmVxdWVzdC4gVGhp
cyB2YWx1ZSBpcyB1c2VkIHRvCiBpZGVudGlmeSBkdXBsaWNhdGUgcmVxdWVzdHMuIElmIHlv
dSBtYWtlIGEgcmVxdWVzdCB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIGFuZCB0aGUgb3Jp
Z2luYWwgcmVxdWVzdCBpcyBzdGlsbCBpbiBwcm9ncmVzcyBvciBjb21wbGV0ZWQsIHRoZSBz
ZXJ2ZXIKIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRzIGNsaWVu
dHMgZnJvbQogYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRtZW50cy4K
CiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRp
b24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAw
MC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEAQIDBRIErAECCAoNCgUEAQIDARIErAEJEwoN
CgUEAQIDAxIErAEWFwoPCgUEAQIDCBIGrAEYrwEDChMKCwQBAgMIzPH5igEBEgStAQQqChAK
CAQBAgMInAgAEgSuAQQqCjwKAgQCEgazAQDJAQEaLiBUaGUgcmVxdWVzdCBmb3IgYERhdGFi
YXNlQ29ubmVjdGlvbi5EZWxldGVgLgoKCwoDBAIBEgSzAQgnCqIBCgQEAgIAEga2AQK7AQQa
kQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXNvdXJjZSBpbiB0aGUgZm9sbG93aW5n
IGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRh
YmFzZUNvbm5lY3Rpb25zL3tkYXRhYmFzZV9jb25uZWN0aW9ufS4KCg0KBQQCAgAFEgS2AQII
Cg0KBQQCAgABEgS2AQkNCg0KBQQCAgADEgS2ARARCg8KBQQCAgAIEga2ARK7AQMKEAoIBAIC
AAicCAASBLcBBCoKEQoHBAICAAifCBIGuAEEugEFCtcDCgQEAgIBEgbFAQLIAQQaxgMgT3B0
aW9uYWwuIEFuIG9wdGlvbmFsIElEIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0LiBUaGlzIHZh
bHVlIGlzIHVzZWQgdG8KIGlkZW50aWZ5IGR1cGxpY2F0ZSByZXF1ZXN0cy4gSWYgeW91IG1h
a2UgYSByZXF1ZXN0IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogYW5kIHRoZSBvcmlnaW5h
bCByZXF1ZXN0IGlzIHN0aWxsIGluIHByb2dyZXNzIG9yIGNvbXBsZXRlZCwgdGhlIHNlcnZl
cgogaWdub3JlcyB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMgY2xpZW50cyBm
cm9tCiBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRo
ZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0
aGF0IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAw
MDAtMDAwMDAwMDAwMDAwKS4KCg0KBQQCAgEFEgTFAQIICg0KBQQCAgEBEgTFAQkTCg0KBQQC
AgEDEgTFARYXCg8KBQQCAgEIEgbFARjIAQMKEwoLBAICAQjM8fmKAQESBMYBBCoKEAoIBAIC
AQicCAASBMcBBCoKOgoCBAMSBswBAOMBARosIFRoZSByZXF1ZXN0IGZvciBgRGF0YWJhc2VD
b25uZWN0aW9uLkxpc3RgLgoKCwoDBAMBEgTMAQgmCooBCgQEAwIAEgbPAQLUAQQaeiBSZXF1
aXJlZC4gVGhlIHBhcmVudCB2YWx1ZSBmb3IgdGhlIERhdGFiYXNlQ29ubmVjdGlvbiBpbiB0
aGUgZm9sbG93aW5nCiBmb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS4KCg0KBQQDAgAFEgTPAQIICg0KBQQDAgABEgTPAQkPCg0KBQQDAgADEgTPARIT
Cg8KBQQDAgAIEgbPARTUAQMKEAoIBAMCAAicCAASBNABBCoKEQoHBAMCAAifCBIG0QEE0wEF
CsoBCgQEAwIBEgTZAQI/GrsBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgaXRl
bXMgdG8gcmV0dXJuLgogSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgNTAgRGF0YWJhc2VDb25u
ZWN0aW9ucyB3aWxsIGJlIHJldHVybmVkLgogVGhlIG1heGltdW0gdmFsdWUgaXMgMTAwMDsg
dmFsdWVzIGFib3ZlIDEwMDAgd2lsbCBiZSBjb2VyY2VkIHRvIDEwMDAuCgoNCgUEAwIBBRIE
2QECBwoNCgUEAwIBARIE2QEIEQoNCgUEAwIBAxIE2QEUFQoNCgUEAwIBCBIE2QEWPgoQCggE
AwIBCJwIABIE2QEXPQpZCgQEAwICEgTcAQJBGksgT3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRp
ZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNlcnZlciBzaG91bGQgcmV0dXJuLgoKDQoF
BAMCAgUSBNwBAggKDQoFBAMCAgESBNwBCRMKDQoFBAMCAgMSBNwBFhcKDQoFBAMCAggSBNwB
GEAKEAoIBAMCAgicCAASBNwBGT8KUQoEBAMCAxIE3wECPRpDIE9wdGlvbmFsLiBBbiBleHBy
ZXNzaW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3VsdHMgb2YgdGhlIHJlcXVlc3QuCgoNCgUE
AwIDBRIE3wECCAoNCgUEAwIDARIE3wEJDwoNCgUEAwIDAxIE3wESEwoNCgUEAwIDCBIE3wEU
PAoQCggEAwIDCJwIABIE3wEVOwpQCgQEAwIEEgTiAQI/GkIgT3B0aW9uYWwuIEFuIGV4cHJl
c3Npb24gZm9yIG9yZGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LgoKDQoFBAMC
BAUSBOIBAggKDQoFBAMCBAESBOIBCREKDQoFBAMCBAMSBOIBFBUKDQoFBAMCBAgSBOIBFj4K
EAoIBAMCBAicCAASBOIBFz0KOwoCBAQSBuYBAPABARotIFRoZSByZXNwb25zZSBmb3IgYERh
dGFiYXNlQ29ubmVjdGlvbi5MaXN0YC4KCgsKAwQEARIE5gEIJwowCgQEBAIAEgToAQI3GiIg
VGhlIGxpc3Qgb2YgRGF0YWJhc2VDb25uZWN0aW9ucy4KCg0KBQQEAgAEEgToAQIKCg0KBQQE
AgAGEgToAQsdCg0KBQQEAgABEgToAR4yCg0KBQQEAgADEgToATU2Ck8KBAQEAgESBOsBAh0a
QSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hv
dWxkIHJldHVybi4KCg0KBQQEAgEFEgTrAQIICg0KBQQEAgEBEgTrAQkYCg0KBQQEAgEDEgTr
ARscCm8KBAQEAgISBO8BAiIaYSBVbnJlYWNoYWJsZSBsb2NhdGlvbnMgd2hlbiBsaXN0aW5n
IHJlc291cmNlcyBhY3Jvc3MgYWxsIGxvY2F0aW9ucyB1c2luZwogd2lsZGNhcmQgbG9jYXRp
b24gJy0nLgoKDQoFBAQCAgQSBO8BAgoKDQoFBAQCAgUSBO8BCxEKDQoFBAQCAgESBO8BEh0K
DQoFBAQCAgMSBO8BICEKOQoCBAUSBvMBAPwBARorIFRoZSByZXF1ZXN0IGZvciBgRGF0YWJh
c2VDb25uZWN0aW9uLkdldGAuCgoLCgMEBQESBPMBCCQKrAEKBAQFAgASBvYBAvsBBBqbASBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIERhdGFiYXNlQ29ubmVjdGlvbiBpbiB0aGUgZm9s
bG93aW5nIGZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9kYXRhYmFzZUNvbm5lY3Rpb25zL3tkYXRhYmFzZV9jb25uZWN0aW9ufS4KCg0KBQQFAgAF
EgT2AQIICg0KBQQFAgABEgT2AQkNCg0KBQQFAgADEgT2ARARCg8KBQQFAgAIEgb2ARL7AQMK
EAoIBAUCAAicCAASBPcBBCoKEQoHBAUCAAifCBIG+AEE+gEFCjwKAgQGEgb/AQCWAgEaLiBU
aGUgcmVxdWVzdCBmb3IgYERhdGFiYXNlQ29ubmVjdGlvbi5VcGRhdGVgLgoKCwoDBAYBEgT/
AQgnCvABCgQEBgIAEgaDAgKEAi8a3wEgT3B0aW9uYWwuIEEgbWFzayBzcGVjaWZ5aW5nIHdo
aWNoIGZpZWxkcyBpbiB0aGUgRGF0YWJhc2VDb25uZWN0aW9uIHNob3VsZAogYmUgdXBkYXRl
ZC4gQSBmaWVsZCBzcGVjaWZpZWQgaW4gdGhlIG1hc2sgaXMgb3ZlcndyaXR0ZW4uIElmIGEg
bWFzayBpc24ndAogcHJvdmlkZWQgdGhlbiBhbGwgdGhlIGZpZWxkcyBpbiB0aGUgRGF0YWJh
c2VDb25uZWN0aW9uIGFyZSBvdmVyd3JpdHRlbi4KCg0KBQQGAgAGEgSDAgIbCg0KBQQGAgAB
EgSDAhwnCg0KBQQGAgADEgSDAiorCg0KBQQGAgAIEgSEAgYuChAKCAQGAgAInAgAEgSEAgct
CjcKBAQGAgESBocCAogCLxonIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVpbmcgdXBkYXRl
ZC4KCg0KBQQGAgEGEgSHAgIUCg0KBQQGAgEBEgSHAhUoCg0KBQQGAgEDEgSHAissCg0KBQQG
AgEIEgSIAgYuChAKCAQGAgEInAgAEgSIAgctCtcDCgQEBgICEgaSAgKVAgQaxgMgT3B0aW9u
YWwuIEFuIG9wdGlvbmFsIElEIHRvIGlkZW50aWZ5IHRoZSByZXF1ZXN0LiBUaGlzIHZhbHVl
IGlzIHVzZWQgdG8KIGlkZW50aWZ5IGR1cGxpY2F0ZSByZXF1ZXN0cy4gSWYgeW91IG1ha2Ug
YSByZXF1ZXN0IHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogYW5kIHRoZSBvcmlnaW5hbCBy
ZXF1ZXN0IGlzIHN0aWxsIGluIHByb2dyZXNzIG9yIGNvbXBsZXRlZCwgdGhlIHNlcnZlcgog
aWdub3JlcyB0aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMgY2xpZW50cyBmcm9t
CiBhY2NpZGVudGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSBy
ZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0
IHplcm8gVVVJRCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAt
MDAwMDAwMDAwMDAwKS4KCg0KBQQGAgIFEgSSAgIICg0KBQQGAgIBEgSSAgkTCg0KBQQGAgID
EgSSAhYXCg8KBQQGAgIIEgaSAhiVAgMKEwoLBAYCAgjM8fmKAQESBJMCBCoKEAoIBAYCAgic
CAASBJQCBCoKUAoCBAcSBpkCAKMCARpCIFJlcXVlc3QgbWVzc2FnZSBmb3IgYERhdGFiYXNl
Q29ubmVjdGlvbi5UZXN0RGF0YWJhc2VDb25uZWN0aW9uYC4KCgsKAwQHARIEmQIIJQqkAQoE
BAcCABIGnQICogIEGpMBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgRGF0YWJhc2VDb25u
ZWN0aW9uIHRvIHRlc3QuCiBGb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YWJhc2VDb25uZWN0aW9ucy97ZGF0YWJhc2VfY29ubmVjdGlvbn0K
Cg0KBQQHAgAFEgSdAgIICg0KBQQHAgABEgSdAgkNCg0KBQQHAgADEgSdAhARCg8KBQQHAgAI
EgadAhKiAgMKEAoIBAcCAAicCAASBJ4CBCoKEQoHBAcCAAifCBIGnwIEoQIFClEKAgQIEgam
AgCsAgEaQyBSZXNwb25zZSBtZXNzYWdlIGZvciBgRGF0YWJhc2VDb25uZWN0aW9uLlRlc3RE
YXRhYmFzZUNvbm5lY3Rpb25gLgoKCwoDBAgBEgSmAggmCjsKBAQIAgASBKgCAhMaLSBXaGV0
aGVyIHRoZSB0ZXN0IGNvbm5lY3Rpb24gd2FzIHN1Y2Nlc3NmdWwuCgoNCgUECAIABRIEqAIC
BgoNCgUECAIAARIEqAIHDgoNCgUECAIAAxIEqAIREgo8CgQECAIBEgSrAgIbGi4gRXJyb3Ig
bWVzc2FnZSBpZiB0aGUgdGVzdCBjb25uZWN0aW9uIGZhaWxlZC4KCg0KBQQIAgEFEgSrAgII
Cg0KBQQIAgEBEgSrAgkWCg0KBQQIAgEDEgSrAhkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection ===
    # Fields for DatabaseConnection
    # Field: wallet_secret_version Type: 9 ()
    # Field: odb_network Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: username Type: 9 ()
    # Field: password_secret_version Type: 9 ()
    # Field: connection_string Type: 9 ()
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.DatabaseConnection.State)
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.DatabaseConnection.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: lifecycle_details Type: 9 ()

# Enum: DatabaseConnection::State
our $DatabaseConnection_STATE_UNSPECIFIED = 0;
our $DatabaseConnection_CREATING = 1;
our $DatabaseConnection_ACTIVE = 2;
our $DatabaseConnection_FAILED = 3;
our $DatabaseConnection_DELETING = 4;

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::CreateDatabaseConnectionRequest ===
    # Fields for CreateDatabaseConnectionRequest
    # Field: parent Type: 9 ()
    # Field: database_connection_id Type: 9 ()
    # Field: database_connection Type: 11 (.google.cloud.oracledatabase.v1.DatabaseConnection)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::DeleteDatabaseConnectionRequest ===
    # Fields for DeleteDatabaseConnectionRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsRequest ===
    # Fields for ListDatabaseConnectionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsResponse ===
    # Fields for ListDatabaseConnectionsResponse
    # Field: database_connections Type: 11 (.google.cloud.oracledatabase.v1.DatabaseConnection)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::GetDatabaseConnectionRequest ===
    # Fields for GetDatabaseConnectionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::UpdateDatabaseConnectionRequest ===
    # Fields for UpdateDatabaseConnectionRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: database_connection Type: 11 (.google.cloud.oracledatabase.v1.DatabaseConnection)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionRequest ===
    # Fields for TestDatabaseConnectionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionResponse ===
    # Fields for TestDatabaseConnectionResponse
    # Field: success Type: 8 ()
    # Field: error_message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DatabaseConnection - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/database_connection.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DatabaseConnection;

    my $msg = Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection->new({
        wallet_secret_version => $wallet_secret_version,
        odb_network => $odb_network,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->wallet_secret_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/database_connection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection

Represents DatabaseConnection resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->wallet_secret_version() >> / C<< $msg->wallet_secret_version($value) >>

Type: C<String>

Optional. Optional: The resource name of the GCP Secret Manager secret
version containing base64 encoded content of the Oracle Wallet ZIP file
required for mTLS/TLS connections. Format:
projects/{project}/secrets/{secret_id}/versions/{version_id} The
service's Per-Product Per-Project Service Account (P4SA) must have the
'secretmanager.secretAccessor' permission on this secret.

=item * C<< $msg->odb_network() >> / C<< $msg->odb_network($value) >>

Type: C<String>

Optional. Immutable. For Oracle Database@Google cloud resources.
Format: projects/{project}/locations/{location}/odbNetworks/{odbNetwork}

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the DatabaseConnection.
Format:
projects/{project}/locations/{location}/databaseConnections/{database_connection}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Immutable. User-friendly display name for the connection.

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

Optional. Immutable. The default database username to use for connections.

=item * C<< $msg->password_secret_version() >> / C<< $msg->password_secret_version($value) >>

Type: C<String>

Optional. The resource name of the GCP Secret Manager secret version
containing the password for the specified username.
Format: projects/{project}/secrets/{secret_id}/versions/{version_id}
The service's Per-Product Per-Project Service Account (P4SA)
must have the 'secretmanager.secretAccessor' permission on this secret.

=item * C<< $msg->connection_string() >> / C<< $msg->connection_string($value) >>

Type: C<String>

Required. Immutable. Oracle Easy Connect or TNS connection string.
Example: "your-db-host.example.com:1521/YOUR_SERVICE_NAME"

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::State>)

Output only. The current state of the connection.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection::LabelsEntry>)

Optional. Optional: Labels as key-value pairs to organize the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create time of the resource.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update time of the resource.

=item * C<< $msg->lifecycle_details() >> / C<< $msg->lifecycle_details($value) >>

Type: C<String>

Output only. Additional information about the current state of the
connection.

=back

=head3 Enum: DatabaseConnection::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::CreateDatabaseConnectionRequest

The request for `DatabaseConnection.Create`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the DatabaseConnection in the following
format: projects/{project}/locations/{location}.

=item * C<< $msg->database_connection_id() >> / C<< $msg->database_connection_id($value) >>

Type: C<String>

Required. The ID of the DatabaseConnection to create. This value is
restricted to (^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$) and must be a maximum of
63 characters in length. The value must start with a letter and end with a
letter or a number.

=item * C<< $msg->database_connection() >> / C<< $msg->database_connection($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection>)

Required. Details of the DatabaseConnection instance to create.

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

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::DeleteDatabaseConnectionRequest

The request for `DatabaseConnection.Delete`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the resource in the following format:
projects/{project}/locations/{location}/databaseConnections/{database_connection}.

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

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsRequest

The request for `DatabaseConnection.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for the DatabaseConnection in the following
format: projects/{project}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 DatabaseConnections will be returned.
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

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsResponse

The response for `DatabaseConnection.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->database_connections() >> / C<< $msg->database_connections($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection>)

The list of DatabaseConnections.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::GetDatabaseConnectionRequest

The request for `DatabaseConnection.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DatabaseConnection in the following format:
projects/{project}/locations/{location}/databaseConnections/{database_connection}.

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::UpdateDatabaseConnectionRequest

The request for `DatabaseConnection.Update`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the DatabaseConnection should
be updated. A field specified in the mask is overwritten. If a mask isn't
provided then all the fields in the DatabaseConnection are overwritten.

=item * C<< $msg->database_connection() >> / C<< $msg->database_connection($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection>)

Required. The resource being updated.

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

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionRequest

Request message for `DatabaseConnection.TestDatabaseConnection`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the DatabaseConnection to test.
Format:
projects/{project}/locations/{location}/databaseConnections/{database_connection}

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionResponse

Response message for `DatabaseConnection.TestDatabaseConnection`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->success() >> / C<< $msg->success($value) >>

Type: C<Bool>

Whether the test connection was successful.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

Error message if the test connection failed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DatabaseConnection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
