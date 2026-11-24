package Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault;

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
    eval { require Google::Type::Datetime };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZXhhc2NhbGVfZGJfc3RvcmFnZV92
YXVsdC5wcm90bxIeZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvGhpnb29nbGUvdHlwZS9kYXRl
dGltZS5wcm90byLHBgoWRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdBIXCgRuYW1lGAEgASgJQgPg
QQhSBG5hbWUSKQoMZGlzcGxheV9uYW1lGAIgASgJQgbgQQLgQQVSC2Rpc3BsYXlOYW1lEi4K
D2djcF9vcmFjbGVfem9uZRgDIAEoCUIG4EEB4EEFUg1nY3BPcmFjbGVab25lEmgKCnByb3Bl
cnRpZXMYBCABKAsyQC5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRXhhc2NhbGVE
YlN0b3JhZ2VWYXVsdFByb3BlcnRpZXNCBuBBAuBBBVIKcHJvcGVydGllcxJACgtjcmVhdGVf
dGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRIqCg5lbnRpdGxlbWVudF9pZBgGIAEoCUID4EEDUg1lbnRpdGxlbWVudElkEl8KBmxhYmVs
cxgHIAMoCzJCLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5FeGFzY2FsZURiU3Rv
cmFnZVZhdWx0LkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxJ6ChZleGFkYXRhX2luZnJhc3Ry
dWN0dXJlGAggASgJQkPgQQHgQQX6QToKOG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29t
L0Nsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlUhVleGFkYXRhSW5mcmFzdHJ1Y3R1cmUaOQoL
TGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4
ATrIAepBxAEKNG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0V4YXNjYWxlRGJTdG9y
YWdlVmF1bHQSW3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9leGFz
Y2FsZURiU3RvcmFnZVZhdWx0cy97ZXhhc2NhbGVfZGJfc3RvcmFnZV92YXVsdH0qF2V4YXNj
YWxlRGJTdG9yYWdlVmF1bHRzMhZleGFzY2FsZURiU3RvcmFnZVZhdWx0IrsICiBFeGFzY2Fs
ZURiU3RvcmFnZVZhdWx0UHJvcGVydGllcxIXCgRvY2lkGAEgASgJQgPgQQNSBG9jaWQSNwoJ
dGltZV96b25lGAIgASgLMhUuZ29vZ2xlLnR5cGUuVGltZVpvbmVCA+BBA1IIdGltZVpvbmUS
fAobZXhhc2NhbGVfZGJfc3RvcmFnZV9kZXRhaWxzGAMgASgLMjguZ29vZ2xlLmNsb3VkLm9y
YWNsZWRhdGFiYXNlLnYxLkV4YXNjYWxlRGJTdG9yYWdlRGV0YWlsc0ID4EECUhhleGFzY2Fs
ZURiU3RvcmFnZURldGFpbHMSYQoFc3RhdGUYBCABKA4yRi5nb29nbGUuY2xvdWQub3JhY2xl
ZGF0YWJhc2UudjEuRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdFByb3BlcnRpZXMuU3RhdGVCA+BB
A1IFc3RhdGUSJQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAVILZGVzY3JpcHRpb24SKQoOdm1f
Y2x1c3Rlcl9pZHMYBiADKAlCA+BBA1IMdm1DbHVzdGVySWRzEi0KEHZtX2NsdXN0ZXJfY291
bnQYCSABKAVCA+BBA1IOdm1DbHVzdGVyQ291bnQSSAoeYWRkaXRpb25hbF9mbGFzaF9jYWNo
ZV9wZXJjZW50GAcgASgFQgPgQQFSG2FkZGl0aW9uYWxGbGFzaENhY2hlUGVyY2VudBIcCgdv
Y2lfdXJpGAggASgJQgPgQQNSBm9jaVVyaRKQAQoZYXR0YWNoZWRfc2hhcGVfYXR0cmlidXRl
cxgKIAMoDjJPLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5FeGFzY2FsZURiU3Rv
cmFnZVZhdWx0UHJvcGVydGllcy5TaGFwZUF0dHJpYnV0ZUID4EEDUhdhdHRhY2hlZFNoYXBl
QXR0cmlidXRlcxKSAQoaYXZhaWxhYmxlX3NoYXBlX2F0dHJpYnV0ZXMYCyADKA4yTy5nb29n
bGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdFByb3Bl
cnRpZXMuU2hhcGVBdHRyaWJ1dGVCA+BBA1IYYXZhaWxhYmxlU2hhcGVBdHRyaWJ1dGVzInoK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASEAoMUFJPVklTSU9OSU5HEAESDQoJQVZB
SUxBQkxFEAISDAoIVVBEQVRJTkcQAxIPCgtURVJNSU5BVElORxAEEg4KClRFUk1JTkFURUQQ
BRIKCgZGQUlMRUQQBiJXCg5TaGFwZUF0dHJpYnV0ZRIfChtTSEFQRV9BVFRSSUJVVEVfVU5T
UEVDSUZJRUQQABIRCg1TTUFSVF9TVE9SQUdFEAESEQoNQkxPQ0tfU1RPUkFHRRACIngKGEV4
YXNjYWxlRGJTdG9yYWdlRGV0YWlscxIxChJhdmFpbGFibGVfc2l6ZV9nYnMYASABKAVCA+BB
A1IQYXZhaWxhYmxlU2l6ZUdicxIpCg50b3RhbF9zaXplX2dicxgCIAEoBUID4EECUgx0b3Rh
bFNpemVHYnMiiwIKI1VwZGF0ZUV4YXNjYWxlRGJTdG9yYWdlVmF1bHRSZXF1ZXN0EkAKC3Vw
ZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRh
dGVNYXNrEnYKGWV4YXNjYWxlX2RiX3N0b3JhZ2VfdmF1bHQYAiABKAsyNi5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdEID4EECUhZleGFz
Y2FsZURiU3RvcmFnZVZhdWx0EioKCnJlcXVlc3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUgly
ZXF1ZXN0SWQidAogR2V0RXhhc2NhbGVEYlN0b3JhZ2VWYXVsdFJlcXVlc3QSUAoEbmFtZRgB
IAEoCUI84EEC+kE2CjRvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9FeGFzY2FsZURi
U3RvcmFnZVZhdWx0UgRuYW1lIv0BCiJMaXN0RXhhc2NhbGVEYlN0b3JhZ2VWYXVsdHNSZXF1
ZXN0ElQKBnBhcmVudBgBIAEoCUI84EEC+kE2EjRvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlz
LmNvbS9FeGFzY2FsZURiU3RvcmFnZVZhdWx0UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgF
QgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsK
BmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3Jk
ZXJCeSLkAQojTGlzdEV4YXNjYWxlRGJTdG9yYWdlVmF1bHRzUmVzcG9uc2UScwoaZXhhc2Nh
bGVfZGJfc3RvcmFnZV92YXVsdHMYASADKAsyNi5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJh
c2UudjEuRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdFIXZXhhc2NhbGVEYlN0b3JhZ2VWYXVsdHMS
JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxl
GAMgAygJUgt1bnJlYWNoYWJsZSLkAgojQ3JlYXRlRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdFJl
cXVlc3QSVAoGcGFyZW50GAEgASgJQjzgQQL6QTYSNG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFw
aXMuY29tL0V4YXNjYWxlRGJTdG9yYWdlVmF1bHRSBnBhcmVudBJDChxleGFzY2FsZV9kYl9z
dG9yYWdlX3ZhdWx0X2lkGAIgASgJQgPgQQJSGGV4YXNjYWxlRGJTdG9yYWdlVmF1bHRJZBJ2
ChlleGFzY2FsZV9kYl9zdG9yYWdlX3ZhdWx0GAMgASgLMjYuZ29vZ2xlLmNsb3VkLm9yYWNs
ZWRhdGFiYXNlLnYxLkV4YXNjYWxlRGJTdG9yYWdlVmF1bHRCA+BBAlIWZXhhc2NhbGVEYlN0
b3JhZ2VWYXVsdBIqCgpyZXF1ZXN0X2lkGAQgASgJQgvijM/XCAIIAeBBAVIJcmVxdWVzdElk
IqMBCiNEZWxldGVFeGFzY2FsZURiU3RvcmFnZVZhdWx0UmVxdWVzdBJQCgRuYW1lGAEgASgJ
QjzgQQL6QTYKNG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0V4YXNjYWxlRGJTdG9y
YWdlVmF1bHRSBG5hbWUSKgoKcmVxdWVzdF9pZBgCIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVl
c3RJZEL1AQoiY29tLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MUIbRXhhc2NhbGVE
YlN0b3JhZ2VWYXVsdFByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0YWJh
c2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xlLkNs
b3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNlXFYx
6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSoRmCgcSBQ4A1wIBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoC
AwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoJCgIDBRIDFwAkCggK
AQgSAxkAOwoJCgIIJRIDGQA7CggKAQgSAxoAYQoJCgIICxIDGgBhCggKAQgSAxsAIgoJCgII
ChIDGwAiCggKAQgSAxwAPAoJCgIICBIDHAA8CggKAQgSAx0AOwoJCgIIARIDHQA7CggKAQgS
Ax4AOwoJCgIIKRIDHgA7CggKAQgSAx8AOgoJCgIILRIDHwA6CrIBCgIEABIEIwBcARqlASBF
eGFzY2FsZURiU3RvcmFnZVZhdWx0IHJlcHJlc2VudHMgYSBzdG9yYWdlIHZhdWx0IGV4YWRi
IHZtIGNsdXN0ZXIgcmVzb3VyY2UuCiBodHRwczovL2RvY3Mub3JhY2xlLmNvbS9lbi11cy9p
YWFzL2FwaS8jL2VuL2RhdGFiYXNlLzIwMTYwOTE4L0V4YXNjYWxlRGJTdG9yYWdlVmF1bHQv
CgoKCgMEAAESAyMIHgoLCgMEAAcSBCQCKQQKDQoFBAAHnQgSBCQCKQQKsgEKBAQAAgASAy4C
PRqkASBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRXhhc2NhbGVEYlN0
b3JhZ2VWYXVsdC4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9leGFzY2FsZURiU3RvcmFnZVZhdWx0cy97ZXhhc2NhbGVfZGJfc3RvcmFnZV92
YXVsdH0KCgwKBQQAAgAFEgMuAggKDAoFBAACAAESAy4JDQoMCgUEAAIAAxIDLhARCgwKBQQA
AgAIEgMuEjwKDwoIBAACAAicCAASAy4TOwrmAQoEBAACARIEMwI2BBrXASBSZXF1aXJlZC4g
SW1tdXRhYmxlLiBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VW
YXVsdC4gVGhlCiBuYW1lIGRvZXMgbm90IGhhdmUgdG8gYmUgdW5pcXVlIHdpdGhpbiB5b3Vy
IHByb2plY3QuIFRoZSBuYW1lIG11c3QgYmUgMS0yNTUKIGNoYXJhY3RlcnMgbG9uZyBhbmQg
Y2FuIG9ubHkgY29udGFpbiBhbHBoYW51bWVyaWMgY2hhcmFjdGVycy4KCgwKBQQAAgEFEgMz
AggKDAoFBAACAQESAzMJFQoMCgUEAAIBAxIDMxgZCg0KBQQAAgEIEgQzGjYDCg8KCAQAAgEI
nAgAEgM0BCoKDwoIBAACAQicCAESAzUEKwrHAQoEBAACAhIEOwI+BBq4ASBPcHRpb25hbC4g
SW1tdXRhYmxlLiBUaGUgR0NQIE9yYWNsZSB6b25lIHdoZXJlIE9yYWNsZQogRXhhc2NhbGVE
YlN0b3JhZ2VWYXVsdCBpcyBob3N0ZWQuIEV4YW1wbGU6IHVzLWVhc3Q0LWItcjIuIElmIG5v
dCBzcGVjaWZpZWQsCiB0aGUgc3lzdGVtIHdpbGwgcGljayBhIHpvbmUgYmFzZWQgb24gYXZh
aWxhYmlsaXR5LgoKDAoFBAACAgUSAzsCCAoMCgUEAAICARIDOwkYCgwKBQQAAgIDEgM7GxwK
DQoFBAACAggSBDsdPgMKDwoIBAACAgicCAASAzwEKgoPCggEAAICCJwIARIDPQQrClIKBAQA
AgMSBEECRAQaRCBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgcHJvcGVydGllcyBvZiB0aGUg
RXhhc2NhbGVEYlN0b3JhZ2VWYXVsdC4KCgwKBQQAAgMGEgNBAiIKDAoFBAACAwESA0EjLQoM
CgUEAAIDAxIDQTAxCg0KBQQAAgMIEgRBMkQDCg8KCAQAAgMInAgAEgNCBCoKDwoIBAACAwic
CAESA0MEKwpbCgQEAAIEEgRHAkgyGk0gT3V0cHV0IG9ubHkuIFRoZSBkYXRlIGFuZCB0aW1l
IHdoZW4gdGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQgd2FzIGNyZWF0ZWQuCgoMCgUEAAIE
BhIDRwIbCgwKBQQAAgQBEgNHHCcKDAoFBAACBAMSA0cqKwoMCgUEAAIECBIDSAYxCg8KCAQA
AgQInAgAEgNIBzAKbwoEBAACBRIDTAJIGmIgT3V0cHV0IG9ubHkuIFRoZSBJRCBvZiB0aGUg
c3Vic2NyaXB0aW9uIGVudGl0bGVtZW50IGFzc29jaWF0ZWQgd2l0aCB0aGUKIEV4YXNjYWxl
RGJTdG9yYWdlVmF1bHQuCgoMCgUEAAIFBRIDTAIICgwKBQQAAgUBEgNMCRcKDAoFBAACBQMS
A0waGwoMCgUEAAIFCBIDTBxHCg8KCAQAAgUInAgAEgNMHUYKVwoEBAACBhIDTwJKGkogT3B0
aW9uYWwuIFRoZSBsYWJlbHMgb3IgdGFncyBhc3NvY2lhdGVkIHdpdGggdGhlIEV4YXNjYWxl
RGJTdG9yYWdlVmF1bHQuCgoMCgUEAAIGBhIDTwIVCgwKBQQAAgYBEgNPFhwKDAoFBAACBgMS
A08fIAoMCgUEAAIGCBIDTyFJCg8KCAQAAgYInAgAEgNPIkgK/AEKBAQAAgcSBFUCWwQa7QEg
T3B0aW9uYWwuIEltbXV0YWJsZS4gVGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1cmUgcmVzb3Vy
Y2Ugb24gd2hpY2gKIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQKIHJlc291cmNlIGlzIGNyZWF0
ZWQsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97cmVnaW9ufS9jbG91ZEV4YWRhdGFJbmZyYXN0dWN0dXJlcy97Y2xvdWRfZXh0cmFk
YXRhX2luZnJhc3RydWN0dXJlfQoKDAoFBAACBwUSA1UCCAoMCgUEAAIHARIDVQkfCgwKBQQA
AgcDEgNVIiMKDQoFBAACBwgSBFUkWwMKDwoIBAACBwicCAASA1YEKgoPCggEAAIHCJwIARID
VwQrCg8KBwQAAgcInwgSBFgEWgUKSQoCBAESBWAAsQEBGjwgVGhlIHByb3BlcnRpZXMgb2Yg
dGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQuCiBuZXh0IElEOiAxMgoKCgoDBAEBEgNgCCgK
OAoEBAEEABIEYgJ3AxoqIFRoZSBzdGF0ZSBvZiB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VWYXVs
dC4KCgwKBQQBBAABEgNiBwwKSAoGBAEEAAIAEgNkBBoaOSBUaGUgc3RhdGUgb2YgdGhlIEV4
YXNjYWxlRGJTdG9yYWdlVmF1bHQgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAQQAAgABEgNkBBUK
DgoHBAEEAAIAAhIDZBgZCkEKBgQBBAACARIDZwQVGjIgVGhlIEV4YXNjYWxlRGJTdG9yYWdl
VmF1bHQgaXMgYmVpbmcgcHJvdmlzaW9uZWQuCgoOCgcEAQQAAgEBEgNnBBAKDgoHBAEEAAIB
AhIDZxMUCjkKBgQBBAACAhIDagQSGiogVGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQgaXMg
YXZhaWxhYmxlLgoKDgoHBAEEAAICARIDagQNCg4KBwQBBAACAgISA2oQEQo9CgYEAQQAAgMS
A20EERouIFRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0IGlzIGJlaW5nIHVwZGF0ZWQuCgoO
CgcEAQQAAgMBEgNtBAwKDgoHBAEEAAIDAhIDbQ8QCj0KBgQBBAACBBIDcAQUGi4gVGhlIEV4
YXNjYWxlRGJTdG9yYWdlVmF1bHQgaXMgYmVpbmcgZGVsZXRlZC4KCg4KBwQBBAACBAESA3AE
DwoOCgcEAQQAAgQCEgNwEhMKPQoGBAEEAAIFEgNzBBMaLiBUaGUgRXhhc2NhbGVEYlN0b3Jh
Z2VWYXVsdCBoYXMgYmVlbiBkZWxldGVkLgoKDgoHBAEEAAIFARIDcwQOCg4KBwQBBAACBQIS
A3MREgo3CgYEAQQAAgYSA3YEDxooIFRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0IGhhcyBm
YWlsZWQuCgoOCgcEAQQAAgYBEgN2BAoKDgoHBAEEAAIGAhIDdg0OCmAKBAQBBAESBXsChAED
GlEgVGhlIHNoYXBlIGF0dHJpYnV0ZSBvZiB0aGUgVk0gY2x1c3RlcnMgYXR0YWNoZWQgdG8g
dGhlCiBFeGFzY2FsZURiU3RvcmFnZVZhdWx0LgoKDAoFBAEEAQESA3sHFQorCgYEAQQBAgAS
A30EJBocIERlZmF1bHQgdW5zcGVjaWZpZWQgdmFsdWUuCgoOCgcEAQQBAgABEgN9BB8KDgoH
BAEEAQIAAhIDfSIjCkIKBgQBBAECARIEgAEEFhoyIEluZGljYXRlcyB0aGF0IHRoZSByZXNv
dXJjZSBpcyBpbiBzbWFydCBzdG9yYWdlLgoKDwoHBAEEAQIBARIEgAEEEQoPCgcEAQQBAgEC
EgSAARQVCkIKBgQBBAECAhIEgwEEFhoyIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBp
cyBpbiBibG9jayBzdG9yYWdlLgoKDwoHBAEEAQICARIEgwEEEQoPCgcEAQQBAgICEgSDARQV
CkUKBAQBAgASBIcBAj4aNyBPdXRwdXQgb25seS4gVGhlIE9DSUQgZm9yIHRoZSBFeGFzY2Fs
ZURiU3RvcmFnZVZhdWx0LgoKDQoFBAECAAUSBIcBAggKDQoFBAECAAESBIcBCQ0KDQoFBAEC
AAMSBIcBEBEKDQoFBAECAAgSBIcBEj0KEAoIBAECAAicCAASBIcBEzwKSwoEBAECARIGigEC
iwEyGjsgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHpvbmUgb2YgdGhlIEV4YXNjYWxlRGJTdG9y
YWdlVmF1bHQuCgoNCgUEAQIBBhIEigECFgoNCgUEAQIBARIEigEXIAoNCgUEAQIBAxIEigEj
JAoNCgUEAQIBCBIEiwEGMQoQCggEAQIBCJwIABIEiwEHMApOCgQEAQICEgaOAQKPAS8aPiBS
ZXF1aXJlZC4gVGhlIHN0b3JhZ2UgZGV0YWlscyBvZiB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VW
YXVsdC4KCg0KBQQBAgIGEgSOAQIaCg0KBQQBAgIBEgSOARs2Cg0KBQQBAgIDEgSOATk6Cg0K
BQQBAgIIEgSPAQYuChAKCAQBAgIInAgAEgSPAQctCkUKBAQBAgMSBJIBAj4aNyBPdXRwdXQg
b25seS4gVGhlIHN0YXRlIG9mIHRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0LgoKDQoFBAEC
AwYSBJIBAgcKDQoFBAECAwESBJIBCA0KDQoFBAECAwMSBJIBEBEKDQoFBAECAwgSBJIBEj0K
EAoIBAECAwicCAASBJIBEzwKSAoEBAECBBIElQECQho6IE9wdGlvbmFsLiBUaGUgZGVzY3Jp
cHRpb24gb2YgdGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQuCgoNCgUEAQIEBRIElQECCAoN
CgUEAQIEARIElQEJFAoNCgUEAQIEAxIElQEXGAoNCgUEAQIECBIElQEZQQoQCggEAQIECJwI
ABIElQEaQApoCgQEAQIFEgaZAQKaATIaWCBPdXRwdXQgb25seS4gVGhlIGxpc3Qgb2YgVk0g
Y2x1c3RlciBPQ0lEcyBhc3NvY2lhdGVkIHdpdGggdGhlCiBFeGFzY2FsZURiU3RvcmFnZVZh
dWx0LgoKDQoFBAECBQQSBJkBAgoKDQoFBAECBQUSBJkBCxEKDQoFBAECBQESBJkBEiAKDQoF
BAECBQMSBJkBIyQKDQoFBAECBQgSBJoBBjEKEAoIBAECBQicCAASBJoBBzAKYwoEBAECBhIE
ngECSRpVIE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIFZNIGNsdXN0ZXJzIGFzc29jaWF0
ZWQgd2l0aCB0aGUKIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQuCgoNCgUEAQIGBRIEngECBwoN
CgUEAQIGARIEngEIGAoNCgUEAQIGAxIEngEbHAoNCgUEAQIGCBIEngEdSAoQCggEAQIGCJwI
ABIEngEeRwpwCgQEAQIHEgaiAQKjAS8aYCBPcHRpb25hbC4gVGhlIHNpemUgb2YgYWRkaXRp
b25hbCBmbGFzaCBjYWNoZSBpbiBwZXJjZW50YWdlIG9mIGhpZ2ggY2FwYWNpdHkKIGRhdGFi
YXNlIHN0b3JhZ2UuCgoNCgUEAQIHBRIEogECBwoNCgUEAQIHARIEogEIJgoNCgUEAQIHAxIE
ogEpKgoNCgUEAQIHCBIEowEGLgoQCggEAQIHCJwIABIEowEHLQpQCgQEAQIIEgSmAQJBGkIg
T3V0cHV0IG9ubHkuIERlZXAgbGluayB0byB0aGUgT0NJIGNvbnNvbGUgdG8gdmlldyB0aGlz
IHJlc291cmNlLgoKDQoFBAECCAUSBKYBAggKDQoFBAECCAESBKYBCRAKDQoFBAECCAMSBKYB
ExQKDQoFBAECCAgSBKYBFUAKEAoIBAECCAicCAASBKYBFj8KbwoEBAECCRIGqgECqwEyGl8g
T3V0cHV0IG9ubHkuIFRoZSBzaGFwZSBhdHRyaWJ1dGVzIG9mIHRoZSBWTSBjbHVzdGVycyBh
dHRhY2hlZCB0byB0aGUKIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQuCgoNCgUEAQIJBBIEqgEC
CgoNCgUEAQIJBhIEqgELGQoNCgUEAQIJARIEqgEaMwoNCgUEAQIJAxIEqgE2OAoNCgUEAQIJ
CBIEqwEGMQoQCggEAQIJCJwIABIEqwEHMAqAAQoEBAECChIGrwECsAEyGnAgT3V0cHV0IG9u
bHkuIFRoZSBzaGFwZSBhdHRyaWJ1dGVzIGF2YWlsYWJsZSBmb3IgdGhlIFZNIGNsdXN0ZXJz
IHRvIGJlCiBhdHRhY2hlZCB0byB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdC4KCg0KBQQB
AgoEEgSvAQIKCg0KBQQBAgoGEgSvAQsZCg0KBQQBAgoBEgSvARo0Cg0KBQQBAgoDEgSvATc5
Cg0KBQQBAgoIEgSwAQYxChAKCAQBAgoInAgAEgSwAQcwCkIKAgQCEga0AQC8AQEaNCBUaGUg
c3RvcmFnZSBkZXRhaWxzIG9mIHRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0LgoKCwoDBAIB
EgS0AQggCm8KBAQCAgASBLcBAksaYSBPdXRwdXQgb25seS4gVGhlIGF2YWlsYWJsZSBzdG9y
YWdlIGNhcGFjaXR5IGZvciB0aGUgRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdCwKIGluIGdpZ2Fi
eXRlcyAoR0IpLgoKDQoFBAICAAUSBLcBAgcKDQoFBAICAAESBLcBCBoKDQoFBAICAAMSBLcB
HR4KDQoFBAICAAgSBLcBH0oKEAoIBAICAAicCAASBLcBIEkKagoEBAICARIEuwECRBpcIFJl
cXVpcmVkLiBUaGUgdG90YWwgc3RvcmFnZSBhbGxvY2F0aW9uIGZvciB0aGUgRXhhc2NhbGVE
YlN0b3JhZ2VWYXVsdCwgaW4KIGdpZ2FieXRlcyAoR0IpLgoKDQoFBAICAQUSBLsBAgcKDQoF
BAICAQESBLsBCBYKDQoFBAICAQMSBLsBGRoKDQoFBAICAQgSBLsBG0MKEAoIBAICAQicCAAS
BLsBHEIKQAoCBAMSBr8BAN0BARoyIFRoZSByZXF1ZXN0IGZvciBgRXhhc2NhbGVEYlN0b3Jh
Z2VWYXVsdC5VcGRhdGVgLgoKCwoDBAMBEgS/AQgrCoMDCgQEAwIAEgbFAQLGAS8a8gIgT3B0
aW9uYWwuIEEgbWFzayBzcGVjaWZ5aW5nIHdoaWNoIGZpZWxkcyBpbiB0aGUgRXhhc2NhbGVE
YlN0b3JhZ2VWYXVsdAogc2hvdWxkIGJlIHVwZGF0ZWQuIEEgZmllbGQgc3BlY2lmaWVkIGlu
IHRoZSBtYXNrIGlzIHVwZGF0ZWQuIElmIGEgbWFzawogaXNuJ3QgcHJvdmlkZWQsIHRoZSBz
ZXJ2aWNlIHRyZWF0cyB0aGlzIGFzIGFuIGltcGxpZWQgZmllbGQgbWFzayBlcXVpdmFsZW50
CiB0byBhbGwgZmllbGRzIHRoYXQgYXJlIHBvcHVsYXRlZCAoaGF2ZSBhIG5vbi1lbXB0eSB2
YWx1ZSkuIFRvIGNsZWFyIG9yCiB1bnNldCBhIGZpZWxkLCB0aGUgZmllbGQgbXVzdCBiZSBl
eHBsaWNpdGx5IHNwZWNpZmllZCBpbiB0aGUgYHVwZGF0ZV9tYXNrYC4KCg0KBQQDAgAGEgTF
AQIbCg0KBQQDAgABEgTFARwnCg0KBQQDAgADEgTFASorCg0KBQQDAgAIEgTGAQYuChAKCAQD
AgAInAgAEgTGAQctCrIDCgQEAwIBEgbOAQLPAS8aoQMgUmVxdWlyZWQuIFRoZSByZXNvdXJj
ZSBiZWluZyB1cGRhdGVkLiBOb3RlIG9ubHkgbGFiZWxzIGNhbiBiZSB1cGRhdGVkLgogVGhl
IHByb3ZpZGVkIGxhYmVscyB3aWxsIGNvbXBsZXRlbHkgcmVwbGFjZSB0aGUgZXhpc3Rpbmcg
bGFiZWxzLgogQW55IGV4aXN0aW5nIGxhYmVsIGtleXMgdGhhdCBhcmUgbm90IGluY2x1ZGVk
IGluIHRoZSB1cGRhdGUgcmVxdWVzdCB3aWxsIGJlCiBkZWxldGVkLiBOb3QgcHJvdmlkaW5n
IGxhYmVscyBhbmQgdXBkYXRlX21hc2sgd2lsbCBub3QgdXBkYXRlIHRoZSBsYWJlbHMuCiBU
byBjbGVhciBhbGwgbGFiZWxzLCBzcGVjaWZ5IGBsYWJlbHNgIGluIHRoZSBgdXBkYXRlX21h
c2tgIGFuZCBvbWl0IG9yCiBsZWF2ZSB0aGUgYGxhYmVsc2AgZmllbGQgZW1wdHkgaW4gdGhl
IHVwZGF0ZSByZXF1ZXN0LgoKDQoFBAMCAQYSBM4BAhgKDQoFBAMCAQESBM4BGTIKDQoFBAMC
AQMSBM4BNTYKDQoFBAMCAQgSBM8BBi4KEAoIBAMCAQicCAASBM8BBy0K1wMKBAQDAgISBtkB
AtwBBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8gaWRlbnRpZnkgdGhlIHJlcXVl
c3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkgZHVwbGljYXRlIHJlcXVlc3Rz
LiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiBhbmQg
dGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJvZ3Jlc3Mgb3IgY29tcGxldGVk
LCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2ZW50
cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29tbWl0
bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUg
ZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0w
MDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAMCAgUSBNkBAggKDQoFBAMCAgES
BNkBCRMKDQoFBAMCAgMSBNkBFhcKDwoFBAMCAggSBtkBGNwBAwoTCgsEAwICCMzx+YoBARIE
2gEEKgoQCggEAwICCJwIABIE2wEEKgo9CgIEBBIG4AEA6QEBGi8gVGhlIHJlcXVlc3QgZm9y
IGBFeGFzY2FsZURiU3RvcmFnZVZhdWx0LkdldGAuCgoLCgMEBAESBOABCCgKugEKBAQEAgAS
BuMBAugBBBqpASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEV4YXNjYWxlRGJTdG9yYWdl
VmF1bHQgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vZXhhc2NhbGVEYlN0b3JhZ2VWYXVsdHMve2V4YXNjYWxlX2Ri
X3N0b3JhZ2VfdmF1bHR9LgoKDQoFBAQCAAUSBOMBAggKDQoFBAQCAAESBOMBCQ0KDQoFBAQC
AAMSBOMBEBEKDwoFBAQCAAgSBuMBEugBAwoQCggEBAIACJwIABIE5AEEKgoRCgcEBAIACJ8I
EgblAQTnAQUKPgoCBAUSBuwBAIUCARowIFRoZSByZXF1ZXN0IGZvciBgRXhhc2NhbGVEYlN0
b3JhZ2VWYXVsdC5MaXN0YC4KCgsKAwQFARIE7AEIKgqKAQoEBAUCABIG7wEC9AEEGnogUmVx
dWlyZWQuIFRoZSBwYXJlbnQgdmFsdWUgZm9yIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQgaW4g
dGhlIGZvbGxvd2luZwogZm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0uCgoNCgUEBQIABRIE7wECCAoNCgUEBQIAARIE7wEJDwoNCgUEBQIAAxIE7wES
EwoPCgUEBQIACBIG7wEU9AEDChAKCAQFAgAInAgAEgTwAQQqChEKBwQFAgAInwgSBvEBBPMB
BQrOAQoEBAUCARIE+QECPxq/ASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIGl0
ZW1zIHRvIHJldHVybi4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIEV4YXNjYWxlRGJT
dG9yYWdlVmF1bHRzIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAx
MDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0KBQQF
AgEFEgT5AQIHCg0KBQQFAgEBEgT5AQgRCg0KBQQFAgEDEgT5ARQVCg0KBQQFAgEIEgT5ARY+
ChAKCAQFAgEInAgAEgT5ARc9ClkKBAQFAgISBPwBAkEaSyBPcHRpb25hbC4gQSB0b2tlbiBp
ZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4u
CgoNCgUEBQICBRIE/AECCAoNCgUEBQICARIE/AEJEwoNCgUEBQICAxIE/AEWFwoNCgUEBQIC
CBIE/AEYQAoQCggEBQICCJwIABIE/AEZPwqPAQoEBAUCAxIEgAICPRqAASBPcHRpb25hbC4g
QW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0
LiBGaWx0ZXIKIHRoZSBsaXN0IGFzIHNwZWNpZmllZCBpbiBodHRwczovL2dvb2dsZS5haXAu
ZGV2LzE2MC4KCg0KBQQFAgMFEgSAAgIICg0KBQQFAgMBEgSAAgkPCg0KBQQFAgMDEgSAAhIT
Cg0KBQQFAgMIEgSAAhQ8ChAKCAQFAgMInAgAEgSAAhU7CosBCgQEBQIEEgSEAgI/Gn0gT3B0
aW9uYWwuIEFuIGV4cHJlc3Npb24gZm9yIG9yZGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSBy
ZXF1ZXN0LiBPcmRlcgogcmVzdWx0cyBhcyBzcGVjaWZpZWQgaW4gaHR0cHM6Ly9nb29nbGUu
YWlwLmRldi8xMzIuCgoNCgUEBQIEBRIEhAICCAoNCgUEBQIEARIEhAIJEQoNCgUEBQIEAxIE
hAIUFQoNCgUEBQIECBIEhAIWPgoQCggEBQIECJwIABIEhAIXPQo/CgIEBhIGiAIAlQIBGjEg
VGhlIHJlc3BvbnNlIGZvciBgRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdC5MaXN0YC4KCgsKAwQG
ARIEiAIIKwosCgQEBgIAEgSKAgJBGh4gVGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHRzLgoK
DQoFBAYCAAQSBIoCAgoKDQoFBAYCAAYSBIoCCyEKDQoFBAYCAAESBIoCIjwKDQoFBAYCAAMS
BIoCP0AK7gEKBAQGAgESBJACAh0a3wEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2Yg
cmVzdWx0cyB0aGUgc2VydmVyIHNob3VsZCByZXR1cm4uIElmIHByZXNlbnQsCiB0aGUgbmV4
dCBwYWdlIHRva2VuIGNhbiBiZSBwcm92aWRlZCB0byBhIHN1YnNlcXVlbnQKIExpc3RFeGFz
Y2FsZURiU3RvcmFnZVZhdWx0cyBjYWxsIHRvIGxpc3QgdGhlIG5leHQgcGFnZS4KIElmIGVt
cHR5LCB0aGVyZSBhcmUgbm8gbW9yZSBwYWdlcy4KCg0KBQQGAgEFEgSQAgIICg0KBQQGAgEB
EgSQAgkYCg0KBQQGAgEDEgSQAhscCm8KBAQGAgISBJQCAiIaYSBVbnJlYWNoYWJsZSBsb2Nh
dGlvbnMgd2hlbiBsaXN0aW5nIHJlc291cmNlcyBhY3Jvc3MgYWxsIGxvY2F0aW9ucyB1c2lu
Zwogd2lsZGNhcmQgbG9jYXRpb24gJy0nLgoKDQoFBAYCAgQSBJQCAgoKDQoFBAYCAgUSBJQC
CxEKDQoFBAYCAgESBJQCEh0KDQoFBAYCAgMSBJQCICEKQAoCBAcSBpgCAL4CARoyIFRoZSBy
ZXF1ZXN0IGZvciBgRXhhc2NhbGVEYlN0b3JhZ2VWYXVsdC5DcmVhdGVgLgoKCwoDBAcBEgSY
AggrCpIBCgQEBwIAEgabAgKgAgQagQEgUmVxdWlyZWQuIFRoZSB2YWx1ZSBmb3IgcGFyZW50
IG9mIHRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0IGluIHRoZQogZm9sbG93aW5nIGZvcm1h
dDogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259LgoKDQoFBAcCAAUS
BJsCAggKDQoFBAcCAAESBJsCCQ8KDQoFBAcCAAMSBJsCEhMKDwoFBAcCAAgSBpsCFKACAwoQ
CggEBwIACJwIABIEnAIEKgoRCgcEBwIACJ8IEgadAgSfAgUKhwIKBAQHAgESBqYCAqcCLxr2
ASBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSBFeGFzY2FsZURiU3RvcmFnZVZhdWx0IHRvIGNy
ZWF0ZS4gVGhpcyB2YWx1ZSBpcwogcmVzdHJpY3RlZCB0byAoXlthLXpdKFthLXowLTktXXsw
LDYxfVthLXowLTldKT8kKSBhbmQgbXVzdCBiZSBhIG1heGltdW0gb2YKIDYzIGNoYXJhY3Rl
cnMgaW4gbGVuZ3RoLiBUaGUgdmFsdWUgbXVzdCBzdGFydCB3aXRoIGEgbGV0dGVyIGFuZCBl
bmQgd2l0aCBhCiBsZXR0ZXIgb3IgYSBudW1iZXIuCgoNCgUEBwIBBRIEpgICCAoNCgUEBwIB
ARIEpgIJJQoNCgUEBwIBAxIEpgIoKQoNCgUEBwIBCBIEpwIGLgoQCggEBwIBCJwIABIEpwIH
LQo3CgQEBwICEgaqAgKrAi8aJyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIGJlaW5nIGNyZWF0
ZWQuCgoNCgUEBwICBhIEqgICGAoNCgUEBwICARIEqgIZMgoNCgUEBwICAxIEqgI1NgoNCgUE
BwICCBIEqwIGLgoQCggEBwICCJwIABIEqwIHLQqRBgoEBAcCAxIGugICvQIEGoAGIE9wdGlv
bmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50aWZ5IHJlcXVlc3RzLiBTcGVj
aWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHNvIHRoYXQgaWYgeW91IG11c3QgcmV0cnkgeW91
ciByZXF1ZXN0LCB0aGUgc2VydmVyIHdpbGwga25vdyB0bwogaWdub3JlIHRoZSByZXF1ZXN0
IGlmIGl0IGhhcyBhbHJlYWR5IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIHdpbGwKIGd1
YXJhbnRlZSB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCBy
ZXF1ZXN0LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3Ug
bWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElm
IHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQs
IHRoZSBzZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBz
YW1lIHJlcXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCB3aWxsIGlnbm9yZSB0
aGUgc2Vjb25kIHJlcXVlc3QuIFRoaXMgcHJldmVudHMKIGNsaWVudHMgZnJvbSBhY2NpZGVu
dGFsbHkgY3JlYXRpbmcgZHVwbGljYXRlIGNvbW1pdG1lbnRzLgoKIFRoZSByZXF1ZXN0IElE
IG11c3QgYmUgYSB2YWxpZCBVVUlEIHdpdGggdGhlIGV4Y2VwdGlvbiB0aGF0IHplcm8gVVVJ
RCBpcwogbm90IHN1cHBvcnRlZCAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAw
MDAwKS4KCg0KBQQHAgMFEgS6AgIICg0KBQQHAgMBEgS6AgkTCg0KBQQHAgMDEgS6AhYXCg8K
BQQHAgMIEga6Ahi9AgMKEwoLBAcCAwjM8fmKAQESBLsCBCoKEAoIBAcCAwicCAASBLwCBCoK
SAoCBAgSBsECANcCARo6IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGBFeGFzY2FsZURiU3Rv
cmFnZVZhdWx0LkRlbGV0ZWAuCgoLCgMECAESBMECCCsKugEKBAQIAgASBsQCAskCBBqpASBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIEV4YXNjYWxlRGJTdG9yYWdlVmF1bHQgaW4gdGhl
IGZvbGxvd2luZyBmb3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vZXhhc2NhbGVEYlN0b3JhZ2VWYXVsdHMve2V4YXNjYWxlX2RiX3N0b3JhZ2VfdmF1
bHR9LgoKDQoFBAgCAAUSBMQCAggKDQoFBAgCAAESBMQCCQ0KDQoFBAgCAAMSBMQCEBEKDwoF
BAgCAAgSBsQCEskCAwoQCggECAIACJwIABIExQIEKgoRCgcECAIACJ8IEgbGAgTIAgUK1wMK
BAQIAgESBtMCAtYCBBrGAyBPcHRpb25hbC4gQW4gb3B0aW9uYWwgSUQgdG8gaWRlbnRpZnkg
dGhlIHJlcXVlc3QuIFRoaXMgdmFsdWUgaXMgdXNlZCB0bwogaWRlbnRpZnkgZHVwbGljYXRl
IHJlcXVlc3RzLiBJZiB5b3UgbWFrZSBhIHJlcXVlc3Qgd2l0aCB0aGUgc2FtZSByZXF1ZXN0
IElECiBhbmQgdGhlIG9yaWdpbmFsIHJlcXVlc3QgaXMgc3RpbGwgaW4gcHJvZ3Jlc3Mgb3Ig
Y29tcGxldGVkLCB0aGUgc2VydmVyCiBpZ25vcmVzIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhp
cyBwcmV2ZW50cyBjbGllbnRzIGZyb20KIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNh
dGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQg
d2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgw
MDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAgCAQUSBNMCAggK
DQoFBAgCAQESBNMCCRMKDQoFBAgCAQMSBNMCFhcKDwoFBAgCAQgSBtMCGNYCAwoTCgsECAIB
CMzx+YoBARIE1AIEKgoQCggECAIBCJwIABIE1QIEKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault ===
    # Fields for ExascaleDbStorageVault
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: gcp_oracle_zone Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVaultProperties)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: entitlement_id Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVault.LabelsEntry)
    # Field: exadata_infrastructure Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties ===
    # Fields for ExascaleDbStorageVaultProperties
    # Field: ocid Type: 9 ()
    # Field: time_zone Type: 11 (.google.type.TimeZone)
    # Field: exascale_db_storage_details Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageDetails)
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVaultProperties.State)
    # Field: description Type: 9 ()
    # Field: vm_cluster_ids Type: 9 ()
    # Field: vm_cluster_count Type: 5 ()
    # Field: additional_flash_cache_percent Type: 5 ()
    # Field: oci_uri Type: 9 ()
    # Field: attached_shape_attributes Type: 14 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVaultProperties.ShapeAttribute)
    # Field: available_shape_attributes Type: 14 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVaultProperties.ShapeAttribute)

# Enum: ExascaleDbStorageVaultProperties::State
our $ExascaleDbStorageVaultProperties_STATE_UNSPECIFIED = 0;
our $ExascaleDbStorageVaultProperties_PROVISIONING = 1;
our $ExascaleDbStorageVaultProperties_AVAILABLE = 2;
our $ExascaleDbStorageVaultProperties_UPDATING = 3;
our $ExascaleDbStorageVaultProperties_TERMINATING = 4;
our $ExascaleDbStorageVaultProperties_TERMINATED = 5;
our $ExascaleDbStorageVaultProperties_FAILED = 6;

# Enum: ExascaleDbStorageVaultProperties::ShapeAttribute
our $ExascaleDbStorageVaultProperties_SHAPE_ATTRIBUTE_UNSPECIFIED = 0;
our $ExascaleDbStorageVaultProperties_SMART_STORAGE = 1;
our $ExascaleDbStorageVaultProperties_BLOCK_STORAGE = 2;

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails ===
    # Fields for ExascaleDbStorageDetails
    # Field: available_size_gbs Type: 5 ()
    # Field: total_size_gbs Type: 5 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::UpdateExascaleDbStorageVaultRequest ===
    # Fields for UpdateExascaleDbStorageVaultRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: exascale_db_storage_vault Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVault)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::GetExascaleDbStorageVaultRequest ===
    # Fields for GetExascaleDbStorageVaultRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsRequest ===
    # Fields for ListExascaleDbStorageVaultsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsResponse ===
    # Fields for ListExascaleDbStorageVaultsResponse
    # Field: exascale_db_storage_vaults Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVault)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::CreateExascaleDbStorageVaultRequest ===
    # Fields for CreateExascaleDbStorageVaultRequest
    # Field: parent Type: 9 ()
    # Field: exascale_db_storage_vault_id Type: 9 ()
    # Field: exascale_db_storage_vault Type: 11 (.google.cloud.oracledatabase.v1.ExascaleDbStorageVault)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::DeleteExascaleDbStorageVaultRequest ===
    # Fields for DeleteExascaleDbStorageVaultRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/exascale_db_storage_vault.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault;

    my $msg = Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault->new({
        name => $name,
        display_name => $display_name,
        gcp_oracle_zone => $gcp_oracle_zone,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/exascale_db_storage_vault.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault

ExascaleDbStorageVault represents a storage vault exadb vm cluster resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/ExascaleDbStorageVault/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the ExascaleDbStorageVault.
Format:
projects/{project}/locations/{location}/exascaleDbStorageVaults/{exascale_db_storage_vault}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Immutable. The display name for the ExascaleDbStorageVault. The
name does not have to be unique within your project. The name must be 1-255
characters long and can only contain alphanumeric characters.

=item * C<< $msg->gcp_oracle_zone() >> / C<< $msg->gcp_oracle_zone($value) >>

Type: C<String>

Optional. Immutable. The GCP Oracle zone where Oracle
ExascaleDbStorageVault is hosted. Example: us-east4-b-r2. If not specified,
the system will pick a zone based on availability.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties>)

Required. Immutable. The properties of the ExascaleDbStorageVault.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time when the ExascaleDbStorageVault was created.

=item * C<< $msg->entitlement_id() >> / C<< $msg->entitlement_id($value) >>

Type: C<String>

Output only. The ID of the subscription entitlement associated with the
ExascaleDbStorageVault.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault::LabelsEntry>)

Optional. The labels or tags associated with the ExascaleDbStorageVault.

=item * C<< $msg->exadata_infrastructure() >> / C<< $msg->exadata_infrastructure($value) >>

Type: C<String>

Optional. Immutable. The Exadata Infrastructure resource on which
ExascaleDbStorageVault
resource is created, in the following format:
projects/{project}/locations/{region}/cloudExadataInfrastuctures/{cloud_extradata_infrastructure}

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties

The properties of the ExascaleDbStorageVault.
next ID: 12

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. The OCID for the ExascaleDbStorageVault.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<Message> (L<Google::Type::Datetime::TimeZone>)

Output only. The time zone of the ExascaleDbStorageVault.

=item * C<< $msg->exascale_db_storage_details() >> / C<< $msg->exascale_db_storage_details($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails>)

Required. The storage details of the ExascaleDbStorageVault.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVaultProperties::State>)

Output only. The state of the ExascaleDbStorageVault.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the ExascaleDbStorageVault.

=item * C<< $msg->vm_cluster_ids() >> / C<< $msg->vm_cluster_ids($value) >>

Type: C<String>

Output only. The list of VM cluster OCIDs associated with the
ExascaleDbStorageVault.

=item * C<< $msg->vm_cluster_count() >> / C<< $msg->vm_cluster_count($value) >>

Type: C<Int32>

Output only. The number of VM clusters associated with the
ExascaleDbStorageVault.

=item * C<< $msg->additional_flash_cache_percent() >> / C<< $msg->additional_flash_cache_percent($value) >>

Type: C<Int32>

Optional. The size of additional flash cache in percentage of high capacity
database storage.

=item * C<< $msg->oci_uri() >> / C<< $msg->oci_uri($value) >>

Type: C<String>

Output only. Deep link to the OCI console to view this resource.

=item * C<< $msg->attached_shape_attributes() >> / C<< $msg->attached_shape_attributes($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVaultProperties::ShapeAttribute>)

Output only. The shape attributes of the VM clusters attached to the
ExascaleDbStorageVault.

=item * C<< $msg->available_shape_attributes() >> / C<< $msg->available_shape_attributes($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVaultProperties::ShapeAttribute>)

Output only. The shape attributes available for the VM clusters to be
attached to the ExascaleDbStorageVault.

=back

=head3 Enum: ExascaleDbStorageVaultProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<TERMINATING> => C<4>

=item * C<TERMINATED> => C<5>

=item * C<FAILED> => C<6>

=back

=head3 Enum: ExascaleDbStorageVaultProperties::ShapeAttribute

=over 4

=item * C<SHAPE_ATTRIBUTE_UNSPECIFIED> => C<0>

=item * C<SMART_STORAGE> => C<1>

=item * C<BLOCK_STORAGE> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails

The storage details of the ExascaleDbStorageVault.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->available_size_gbs() >> / C<< $msg->available_size_gbs($value) >>

Type: C<Int32>

Output only. The available storage capacity for the ExascaleDbStorageVault,
in gigabytes (GB).

=item * C<< $msg->total_size_gbs() >> / C<< $msg->total_size_gbs($value) >>

Type: C<Int32>

Required. The total storage allocation for the ExascaleDbStorageVault, in
gigabytes (GB).

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::UpdateExascaleDbStorageVaultRequest

The request for `ExascaleDbStorageVault.Update`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. A mask specifying which fields in the ExascaleDbStorageVault
should be updated. A field specified in the mask is updated. If a mask
isn't provided, the service treats this as an implied field mask equivalent
to all fields that are populated (have a non-empty value). To clear or
unset a field, the field must be explicitly specified in the `update_mask`.

=item * C<< $msg->exascale_db_storage_vault() >> / C<< $msg->exascale_db_storage_vault($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault>)

Required. The resource being updated. Note only labels can be updated.
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

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::GetExascaleDbStorageVaultRequest

The request for `ExascaleDbStorageVault.Get`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the ExascaleDbStorageVault in the following format:
projects/{project}/locations/{location}/exascaleDbStorageVaults/{exascale_db_storage_vault}.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsRequest

The request for `ExascaleDbStorageVault.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for ExascaleDbStorageVault in the following
format: projects/{project}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return.
If unspecified, at most 50 ExascaleDbStorageVaults will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Filter
the list as specified in https://google.aip.dev/160.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression for ordering the results of the request. Order
results as specified in https://google.aip.dev/132.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsResponse

The response for `ExascaleDbStorageVault.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->exascale_db_storage_vaults() >> / C<< $msg->exascale_db_storage_vaults($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault>)

The ExascaleDbStorageVaults.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return. If present,
the next page token can be provided to a subsequent
ListExascaleDbStorageVaults call to list the next page.
If empty, there are no more pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable locations when listing resources across all locations using
wildcard location '-'.

=back

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::CreateExascaleDbStorageVaultRequest

The request for `ExascaleDbStorageVault.Create`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The value for parent of the ExascaleDbStorageVault in the
following format: projects/{project}/locations/{location}.

=item * C<< $msg->exascale_db_storage_vault_id() >> / C<< $msg->exascale_db_storage_vault_id($value) >>

Type: C<String>

Required. The ID of the ExascaleDbStorageVault to create. This value is
restricted to (^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$) and must be a maximum of
63 characters in length. The value must start with a letter and end with a
letter or a number.

=item * C<< $msg->exascale_db_storage_vault() >> / C<< $msg->exascale_db_storage_vault($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault>)

Required. The resource being created.

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

=head2 Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::DeleteExascaleDbStorageVaultRequest

The request message for `ExascaleDbStorageVault.Delete`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the ExascaleDbStorageVault in the following format:
projects/{project}/locations/{location}/exascaleDbStorageVaults/{exascale_db_storage_vault}.

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

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
