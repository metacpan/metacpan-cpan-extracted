package Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL3Jlc3RvcmVfdmVyaWZpY2F0aW9uX3Bs
YW4ucHJvdG8SHGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrYIChdSZXN0b3JlVmVyaWZpY2F0aW9u
UGxhbhIaCgRuYW1lGAEgASgJQgbgQQPgQQhSBG5hbWUSJQoLZGVzY3JpcHRpb24YAiABKAlC
A+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSXgoGbGFiZWxzGAUg
AygLMkEuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5SZXN0b3JlVmVyaWZpY2F0aW9u
UGxhbi5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSVgoFc3RhdGUYBiABKA4yOy5nb29nbGUu
Y2xvdWQuYmFja3VwZHIudjFiZXRhLlJlc3RvcmVWZXJpZmljYXRpb25QbGFuLlN0YXRlQgPg
QQNSBXN0YXRlEh8KCHNjaGVkdWxlGAcgASgJQgPgQQJSCHNjaGVkdWxlEiAKCXRpbWVfem9u
ZRgIIAEoCUID4EEBUgh0aW1lWm9uZRJzChRzdWNjZXNzX2NsZWFudXBfcnVsZRgJIAEoCzI8
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVZlcmlmaWNhdGlvbkNsZWFu
dXBSdWxlQgPgQQFSEnN1Y2Nlc3NDbGVhbnVwUnVsZRJzChRmYWlsdXJlX2NsZWFudXBfcnVs
ZRgKIAEoCzI8Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVZlcmlmaWNh
dGlvbkNsZWFudXBSdWxlQgPgQQFSEmZhaWx1cmVDbGVhbnVwUnVsZRo5CgtMYWJlbHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIm0KBVN0YXRl
EhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQAhIMCghE
RUxFVElORxADEgwKCElOQUNUSVZFEAQSDAoIVVBEQVRJTkcQBRIJCgVFUlJPUhAGOsQB6kHA
AQovYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVZlcmlmaWNhdGlvblBsYW4SWnBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0
aW9uUGxhbnMve3Jlc3RvcmVWZXJpZmljYXRpb25QbGFufSoYcmVzdG9yZVZlcmlmaWNhdGlv
blBsYW5zMhdyZXN0b3JlVmVyaWZpY2F0aW9uUGxhbiKjAQoeUmVzdG9yZVZlcmlmaWNhdGlv
bkNsZWFudXBSdWxlEkMKDWNsZWFudXBfZGVsYXkYASABKAsyGS5nb29nbGUucHJvdG9idWYu
RHVyYXRpb25CA+BBAVIMY2xlYW51cERlbGF5EisKDHNraXBfY2xlYW51cBgCIAEoCEID4EEB
SABSC3NraXBDbGVhbnVwiAEBQg8KDV9za2lwX2NsZWFudXAi4QIKJENyZWF0ZVJlc3RvcmVW
ZXJpZmljYXRpb25QbGFuUmVxdWVzdBJPCgZwYXJlbnQYASABKAlCN+BBAvpBMRIvYmFja3Vw
ZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5SBnBhcmVudBJEChxy
ZXN0b3JlX3ZlcmlmaWNhdGlvbl9wbGFuX2lkGAIgASgJQgPgQQJSGXJlc3RvcmVWZXJpZmlj
YXRpb25QbGFuSWQSdgoZcmVzdG9yZV92ZXJpZmljYXRpb25fcGxhbhgDIAEoCzI1Lmdvb2ds
ZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5CA+BBAlIX
cmVzdG9yZVZlcmlmaWNhdGlvblBsYW4SKgoKcmVxdWVzdF9pZBgEIAEoCUIL4ozP1wgCCAHg
QQFSCXJlcXVlc3RJZCJwCiFHZXRSZXN0b3JlVmVyaWZpY2F0aW9uUGxhblJlcXVlc3QSSwoE
bmFtZRgBIAEoCUI34EEC+kExCi9iYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVmVy
aWZpY2F0aW9uUGxhblIEbmFtZSL5AQojTGlzdFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc1Jl
cXVlc3QSTwoGcGFyZW50GAEgASgJQjfgQQL6QTESL2JhY2t1cGRyLmdvb2dsZWFwaXMuY29t
L1Jlc3RvcmVWZXJpZmljYXRpb25QbGFuUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPg
QQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZp
bHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJC
eSLlAQokTGlzdFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc1Jlc3BvbnNlEnMKGnJlc3RvcmVf
dmVyaWZpY2F0aW9uX3BsYW5zGAEgAygLMjUuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0
YS5SZXN0b3JlVmVyaWZpY2F0aW9uUGxhblIYcmVzdG9yZVZlcmlmaWNhdGlvblBsYW5zEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgD
IAMoCVILdW5yZWFjaGFibGUiugEKJERlbGV0ZVJlc3RvcmVWZXJpZmljYXRpb25QbGFuUmVx
dWVzdBJLCgRuYW1lGAEgASgJQjfgQQL6QTEKL2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jl
c3RvcmVWZXJpZmljYXRpb25QbGFuUgRuYW1lEioKCnJlcXVlc3RfaWQYAiABKAlCC+KMz9cI
AggB4EEBUglyZXF1ZXN0SWQSGQoFZm9yY2UYAyABKAhCA+BBAVIFZm9yY2VC4AEKIGNvbS5n
b29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhQhxSZXN0b3JlVmVyaWZpY2F0aW9uUGxhblBy
b3RvUAFaPGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjFiZXRhL2JhY2t1cGRy
cGI7YmFja3VwZHJwYqoCHEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMUJldGHKAhxHb29nbGVc
Q2xvdWRcQmFja3VwRFJcVjFiZXRh6gIfR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYxYmV0
YUrqWAoHEgUOAJ8CAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJCgIDAxIDFQAoCgkKAgME
EgMWACkKCAoBCBIDGAA5CgkKAgglEgMYADkKCAoBCBIDGQBTCgkKAggLEgMZAFMKCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwA9CgkKAggIEgMbAD0KCAoBCBIDHAA5CgkKAggBEgMc
ADkKCAoBCBIDHQA5CgkKAggpEgMdADkKCAoBCBIDHgA4CgkKAggtEgMeADgKlwIKAgQAEgQk
AHoBGooCIEEgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCBzcGVjaWZpZXMgdGhlIHNjaGVk
dWxpbmcgYW5kIGNsZWFuLXVwIHRlbXBsYXRlCiBmb3IgYXV0b21hdGVkIHJlc3RvcmUgdmVy
aWZpY2F0aW9uLiBJdCBjb250YWlucyBhIGBzY2hlZHVsZWAgdG8gZGljdGF0ZSB3aGVuCiB0
aGUgdmVyaWZpY2F0aW9ucyBzaG91bGQgcnVuLCBhbmQgYSBgUmVzdG9yZVZlcmlmaWNhdGlv
bkNsZWFudXBSdWxlYCBmb3IKIHBvc3QtdmVyaWZpY2F0aW9uIHJlc291cmNlIGRlbGV0aW9u
LgoKCgoDBAABEgMkCB8KCwoDBAAHEgQlAioECg0KBQQAB50IEgQlAioEClcKBAQABAASBC0C
QgMaSSBgU3RhdGVgIGVudW1lcmF0ZXMgdGhlIHBvc3NpYmxlIHN0YXRlcyBmb3IgYSBgUmVz
dG9yZVZlcmlmaWNhdGlvblBsYW5gLgoKDAoFBAAEAAESAy0HDAofCgYEAAQAAgASAy8EGhoQ
IFN0YXRlIG5vdCBzZXQuCgoOCgcEAAQAAgABEgMvBBUKDgoHBAAEAAIAAhIDLxgZCi8KBgQA
BAACARIDMgQRGiAgVGhlIHJlc291cmNlIGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEB
EgMyBAwKDgoHBAAEAAIBAhIDMg8QCkMKBgQABAACAhIDNQQPGjQgVGhlIHJlc291cmNlIGhh
cyBiZWVuIGNyZWF0ZWQgYW5kIGlzIGZ1bGx5IHVzYWJsZS4KCg4KBwQABAACAgESAzUECgoO
CgcEAAQAAgICEgM1DQ4KLwoGBAAEAAIDEgM4BBEaICBUaGUgcmVzb3VyY2UgaXMgYmVpbmcg
ZGVsZXRlZC4KCg4KBwQABAACAwESAzgEDAoOCgcEAAQAAgMCEgM4DxAKQQoGBAAEAAIEEgM7
BBEaMiBUaGUgcmVzb3VyY2UgaGFzIGJlZW4gY3JlYXRlZCBidXQgaXMgbm90IHVzYWJsZS4K
Cg4KBwQABAACBAESAzsEDAoOCgcEAAQAAgQCEgM7DxAKLwoGBAAEAAIFEgM+BBEaICBUaGUg
cmVzb3VyY2UgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAACBQESAz4EDAoOCgcEAAQAAgUC
EgM+DxAKUAoGBAAEAAIGEgNBBA4aQSBUaGUgcmVzb3VyY2UgaXMgaW4gYW4gZXJyb3Igc3Rh
dGUgZHVlIHRvIGEgY29uZmlndXJhdGlvbiBpc3N1ZS4KCg4KBwQABAACBgESA0EECQoOCgcE
AAQAAgYCEgNBDA0KxgEKBAQAAgASBEkCTAQatwEgT3V0cHV0IG9ubHkuIElkZW50aWZpZXIu
IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZQogYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYC4K
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
c3RvcmVWZXJpZmljYXRpb25QbGFucy97cmVzdG9yZVZlcmlmaWNhdGlvblBsYW59YAoKDAoF
BAACAAUSA0kCCAoMCgUEAAIAARIDSQkNCgwKBQQAAgADEgNJEBEKDQoFBAACAAgSBEkSTAMK
DwoIBAACAAicCAASA0oELQoPCggEAAIACJwIARIDSwQsCpwDCgQEAAIBEgNVAkIajgMgT3B0
aW9uYWwuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFu
YCByZXNvdXJjZS4KCiBUaGUgZGVzY3JpcHRpb24gYWxsb3dzIGZvciBhZGRpdGlvbmFsIGRl
dGFpbHMgYWJvdXQKIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAgYW5kIGl0cyB1c2UgY2Fz
ZXMgdG8gYmUgcHJvdmlkZWQuIEFuIGV4YW1wbGUKIGRlc2NyaXB0aW9uIGlzIHRoZSBmb2xs
b3dpbmc6ICJUaGlzIGlzIGEgcmVzdG9yZSB2ZXJpZmljYXRpb24gcGxhbiB0aGF0CiBwZXJm
b3JtcyBhIGRhaWx5IHZlcmlmaWNhdGlvbiBhbmQgY2xlYW5zIHVwIHRoZSByZXNvdXJjZXMg
aW1tZWRpYXRlbHkKIGFmdGVyLiIgVGhlIGRlc2NyaXB0aW9uIG11c3QgYmUgYXQgbW9zdCAy
MDQ4IGNoYXJhY3RlcnMuCgoMCgUEAAIBBRIDVQIICgwKBQQAAgEBEgNVCRQKDAoFBAACAQMS
A1UXGAoMCgUEAAIBCBIDVRlBCg8KCAQAAgEInAgAEgNVGkAKTAoEBAACAhIEWAJZMho+IE91
dHB1dCBvbmx5LiBXaGVuIHRoZSBgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW5gIHdhcyBjcmVh
dGVkLgoKDAoFBAACAgYSA1gCGwoMCgUEAAICARIDWBwnCgwKBQQAAgIDEgNYKisKDAoFBAAC
AggSA1kGMQoPCggEAAICCJwIABIDWQcwClEKBAQAAgMSBFwCXTIaQyBPdXRwdXQgb25seS4g
V2hlbiB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCB3YXMgbGFzdCB1cGRhdGVkLgoK
DAoFBAACAwYSA1wCGwoMCgUEAAIDARIDXBwnCgwKBQQAAgMDEgNcKisKDAoFBAACAwgSA10G
MQoPCggEAAIDCJwIABIDXQcwCi0KBAQAAgQSA2ACShogIE9wdGlvbmFsLiBVc2VyLWRlZmlu
ZWQgbGFiZWxzLgoKDAoFBAACBAYSA2ACFQoMCgUEAAIEARIDYBYcCgwKBQQAAgQDEgNgHyAK
DAoFBAACBAgSA2AhSQoPCggEAAIECJwIABIDYCJICkoKBAQAAgUSA2MCPho9IE91dHB1dCBv
bmx5LiBUaGUgYFN0YXRlYCBmb3IgdGhlIGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbmAuCgoM
CgUEAAIFBhIDYwIHCgwKBQQAAgUBEgNjCA0KDAoFBAACBQMSA2MQEQoMCgUEAAIFCBIDYxI9
Cg8KCAQAAgUInAgAEgNjEzwKxgEKBAQAAgYSA2oCPxq4ASBSZXF1aXJlZC4gRGVzY3JpYmVz
IHRoZSBzY2hlZHVsZSBvbiB3aGljaCB0aGUgcmVzdG9yZSB2ZXJpZmljYXRpb24gd2lsbCBi
ZQogZXhlY3V0ZWQuCgogVGhlIHNjaGVkdWxlIGlzIHNwZWNpZmllZCBhcyBhCiBbQ3JvbnRh
Yl0oaHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvQ3JvbiNPdmVydmlldykgc3RyaW5n
LgoKDAoFBAACBgUSA2oCCAoMCgUEAAIGARIDagkRCgwKBQQAAgYDEgNqFBUKDAoFBAACBggS
A2oWPgoPCggEAAIGCJwIABIDahc9CtUCCgQEAAIHEgNxAkAaxwIgT3B0aW9uYWwuIFNwZWNp
ZmllcyB0aGUgdGltZSB6b25lIHRvIGJlIHVzZWQgaW4gaW50ZXJwcmV0aW5nCiBbc2NoZWR1
bGVdW2dvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuUmVzdG9yZVZlcmlmaWNhdGlvblBs
YW4uc2NoZWR1bGVdLgogVGhlIHZhbHVlIG9mIHRoaXMgZmllbGQgbXVzdCBiZSBhIHRpbWUg
em9uZSBuYW1lIGZyb20gdGhlIFt0egogZGF0YWJhc2VdKGh0dHBzOi8vZW4ud2lraXBlZGlh
Lm9yZy93aWtpL1R6X2RhdGFiYXNlKSwgbGlrZQogIkFtZXJpY2EvTmV3X1lvcmsiIG9yICJV
VEMiLiBEZWZhdWx0cyB0byBgVVRDYCBpZiBub3Qgc3BlY2lmaWVkLgoKDAoFBAACBwUSA3EC
CAoMCgUEAAIHARIDcQkSCgwKBQQAAgcDEgNxFRYKDAoFBAACBwgSA3EXPwoPCggEAAIHCJwI
ABIDcRg+ClkKBAQAAggSBHQCdS8aSyBPcHRpb25hbC4gVGhlIGNsZWFudXAgcnVsZSB0byBh
cHBseSBpZiB0aGUgcmVzdG9yZSB2ZXJpZmljYXRpb24gc3VjY2VlZHMuCgoMCgUEAAIIBhID
dAIgCgwKBQQAAggBEgN0ITUKDAoFBAACCAMSA3Q4OQoMCgUEAAIICBIDdQYuCg8KCAQAAggI
nAgAEgN1By0KVgoEBAACCRIEeAJ5LxpIIE9wdGlvbmFsLiBUaGUgY2xlYW51cCBydWxlIHRv
IGFwcGx5IGlmIHRoZSByZXN0b3JlIHZlcmlmaWNhdGlvbiBmYWlscy4KCgwKBQQAAgkGEgN4
AiAKDAoFBAACCQESA3ghNQoMCgUEAAIJAxIDeDg6CgwKBQQAAgkIEgN5Bi4KDwoIBAACCQic
CAASA3kHLQozCgIEARIFfQCFAQEaJiBEZWZpbmVzIHRoZSBzcGVjaWZpYyBjbGVhbnVwIGFj
dGlvbi4KCgoKAwQBARIDfQgmCpYBCgQEAQIAEgaAAQKBAS8ahQEgT3B0aW9uYWwuIER1cmF0
aW9uIGFmdGVyIHJlc3RvcmUgZmluaXNoZXMgd2hlbiBjbGVhbnVwIHRyaWdnZXJzLgogRGVs
YXkgbXVzdCBiZSBub24tbmVnYXRpdmUgYW5kIGF0IG1vc3QgMzAgZGF5cyAoMjU5MjAwMCBz
ZWNvbmRzKS4KCg0KBQQBAgAGEgSAAQIaCg0KBQQBAgABEgSAARsoCg0KBQQBAgADEgSAASss
Cg0KBQQBAgAIEgSBAQYuChAKCAQBAgAInAgAEgSBAQctClcKBAQBAgESBIQBAkoaSSBPcHRp
b25hbC4gSWYgc2V0IHRvIHRydWUsIHRoZSByZXN0b3JlZCByZXNvdXJjZSB3aWxsIG5vdCBi
ZSBjbGVhbmVkIHVwLgoKDQoFBAECAQQSBIQBAgoKDQoFBAECAQUSBIQBCw8KDQoFBAECAQES
BIQBEBwKDQoFBAECAQMSBIQBHyAKDQoFBAECAQgSBIQBIUkKEAoIBAECAQicCAASBIQBIkgK
TQoCBAISBogBAK8BARo/IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGNyZWF0aW5nIGEgYFJl
c3RvcmVWZXJpZmljYXRpb25QbGFuYC4KCgsKAwQCARIEiAEILArsAQoEBAICABIGjAECkQEE
GtsBIFJlcXVpcmVkLiBUaGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCBwcm9qZWN0IGFu
ZCBsb2NhdGlvbiBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259YC4gSW4gR29vZ2xlIENsb3VkIEJhY2t1cCBhbmQgRFIKIGxvY2F0aW9u
cyBtYXAgdG8gR29vZ2xlIENsb3VkIHJlZ2lvbnMsIGZvciBleGFtcGxlICoqdXMtY2VudHJh
bDEqKi4KCg0KBQQCAgAFEgSMAQIICg0KBQQCAgABEgSMAQkPCg0KBQQCAgADEgSMARITCg8K
BQQCAgAIEgaMARSRAQMKEAoIBAICAAicCAASBI0BBCoKEQoHBAICAAifCBIGjgEEkAEFCqYC
CgQEAgIBEgaXAQKYAS8alQIgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBgUmVzdG9yZVZl
cmlmaWNhdGlvblBsYW5gIHRvIGNyZWF0ZS4gVGhlIG5hbWUKIG11c3QgYmUgdW5pcXVlIGZv
ciB0aGUgc3BlY2lmaWVkIHByb2plY3QgYW5kIGxvY2F0aW9uLiBUaGUgbmFtZSBtdXN0IHN0
YXJ0CiB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciBmb2xsb3dlZCBieSB1cCB0byA2MiBsb3dl
cmNhc2UgbGV0dGVycywgbnVtYmVycywgb3IKIGh5cGhlbnMuIFBhdHRlcm4sIGBeW2Etel0o
Wy1hLXowLTldKlthLXowLTldKT8kYC4KCg0KBQQCAgEFEgSXAQIICg0KBQQCAgEBEgSXAQkl
Cg0KBQQCAgEDEgSXASgpCg0KBQQCAgEIEgSYAQYuChAKCAQCAgEInAgAEgSYAQctClQKBAQC
AgISBpsBApwBLxpEIFJlcXVpcmVkLiBUaGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCBy
ZXNvdXJjZSBvYmplY3QgdG8gY3JlYXRlLgoKDQoFBAICAgYSBJsBAhkKDQoFBAICAgESBJsB
GjMKDQoFBAICAgMSBJsBNjcKDQoFBAICAggSBJwBBi4KEAoIBAICAgicCAASBJwBBy0KkQYK
BAQCAgMSBqsBAq4BBBqABiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBp
ZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0
IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cg
dG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRl
ZC4gVGhlIHNlcnZlciB3aWxsCiBndWFyYW50ZWUgdGhhdCBmb3IgYXQgbGVhc3QgNjAgbWlu
dXRlcyBzaW5jZSB0aGUgZmlyc3QgcmVxdWVzdC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIg
YSBzaXR1YXRpb24gd2hlcmUgeW91IG1ha2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZAogdGhl
IHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRo
IHRoZSBzYW1lIHJlcXVlc3QKIElELCB0aGUgc2VydmVyIGNhbiBjaGVjayBpZiBvcmlnaW5h
bCBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElECiB3YXMgcmVjZWl2ZWQsIGFu
ZCBpZiBzbywgd2lsbCBpZ25vcmUgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHByZXZlbnRz
CiBjbGllbnRzIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBjb21taXRt
ZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBl
eGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAw
MDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEAgIDBRIEqwECCAoNCgUEAgIDARIE
qwEJEwoNCgUEAgIDAxIEqwEWFwoPCgUEAgIDCBIGqwEYrgEDChMKCwQCAgMIzPH5igEBEgSs
AQQqChAKCAQCAgMInAgAEgStAQQqCkwKAgQDEgayAQC9AQEaPiBUaGUgcmVxdWVzdCBtZXNz
YWdlIGZvciBnZXR0aW5nIGEgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYC4KCgsKAwQDARIE
sgEIKQrEAQoEBAMCABIGtwECvAEEGrMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuYCB0byByZXRyaWV2ZS4KCiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVWZXJp
ZmljYXRpb25QbGFucy97cmVzdG9yZVZlcmlmaWNhdGlvblBsYW59YAoKDQoFBAMCAAUSBLcB
AggKDQoFBAMCAAESBLcBCQ0KDQoFBAMCAAMSBLcBEBEKDwoFBAMCAAgSBrcBErwBAwoQCggE
AwIACJwIABIEuAEEKgoRCgcEAwIACJ8IEga5AQS7AQUKVQoCBAQSBsABAOQBARpHIFRoZSBy
ZXF1ZXN0IG1lc3NhZ2UgZm9yIGdldHRpbmcgYSBsaXN0IG9mIGBSZXN0b3JlVmVyaWZpY2F0
aW9uUGxhbnNgLgoKCwoDBAQBEgTAAQgrCuwCCgQEBAIAEgbHAQLMAQQa2wIgUmVxdWlyZWQu
IFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBmb3Igd2hpY2ggdG8gcmV0cmlldmUKIGBSZXN0
b3JlVmVyaWZpY2F0aW9uUGxhbnNgIGluZm9ybWF0aW9uLiBGb3JtYXQ6CiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259YC4gSW4gR29vZ2xlIENsb3VkIEJhY2t1
cCBhbmQgRFIsCiBsb2NhdGlvbnMgbWFwIHRvIEdvb2dsZSBDbG91ZCByZWdpb25zLCBmb3Ig
ZXhhbXBsZSAqKnVzLWNlbnRyYWwxKiouIFRvCiByZXRyaWV2ZSByZXN0b3JlIHZlcmlmaWNh
dGlvbiBwbGFucyBmb3IgYWxsIGxvY2F0aW9ucywgdXNlCiAiLSIgZm9yIHRoZSBge2xvY2F0
aW9ufWAgdmFsdWUuCgoNCgUEBAIABRIExwECCAoNCgUEBAIAARIExwEJDwoNCgUEBAIAAxIE
xwESEwoPCgUEBAIACBIGxwEUzAEDChAKCAQEAgAInAgAEgTIAQQqChEKBwQEAgAInwgSBskB
BMsBBQq1AwoEBAQCARIE1AECPxqmAyBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9m
IGBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnNgIHRvIHJldHVybiBpbiBhCiBzaW5nbGUgcmVz
cG9uc2UuIElmIG5vdCBzcGVjaWZpZWQsIGEgZGVmYXVsdCB2YWx1ZSB3aWxsIGJlIGNob3Nl
biBieSB0aGUKIHNlcnZpY2UuIE5vdGUgdGhhdCB0aGUgcmVzcG9uc2UgbWF5IGluY2x1ZGUg
YSBwYXJ0aWFsIGxpc3QgYW5kIGEgY2FsbGVyCiBzaG91bGQgb25seSByZWx5IG9uIHRoZSBy
ZXNwb25zZSdzCiBbbmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuYmFja3VwZHIudjFi
ZXRhLkxpc3RSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnNSZXNwb25zZS5uZXh0X3BhZ2VfdG9r
ZW5dCiB0byBkZXRlcm1pbmUgaWYgdGhlcmUgYXJlIG1vcmUgaW5zdGFuY2VzIGxlZnQgdG8g
YmUgcXVlcmllZC4KCg0KBQQEAgEFEgTUAQIHCg0KBQQEAgEBEgTUAQgRCg0KBQQEAgEDEgTU
ARQVCg0KBQQEAgEIEgTUARY+ChAKCAQEAgEInAgAEgTUARc9CqEDCgQEBAICEgTdAQJBGpID
IE9wdGlvbmFsLiBUaGUgdmFsdWUgb2YKIFtuZXh0X3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91
ZC5iYWNrdXBkci52MWJldGEuTGlzdFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc1Jlc3BvbnNl
Lm5leHRfcGFnZV90b2tlbl0KIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdFJlc3Rv
cmVWZXJpZmljYXRpb25QbGFuc2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0
aGUgc3Vic2VxdWVudCBwYWdlIGluIGEgbXVsdGktcGFnZSBsaXN0IG9mCiByZXN1bHRzLiBX
aGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBgTGlz
dFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHBy
b3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCg0KBQQEAgIFEgTdAQIICg0KBQQEAgIBEgTdAQkT
Cg0KBQQEAgIDEgTdARYXCg0KBQQEAgIIEgTdARhAChAKCAQEAgIInAgAEgTdARk/CkwKBAQE
AgMSBOABAj0aPiBPcHRpb25hbC4gRmllbGQgbWF0Y2ggZXhwcmVzc2lvbiB1c2VkIHRvIGZp
bHRlciB0aGUgcmVzdWx0cy4KCg0KBQQEAgMFEgTgAQIICg0KBQQEAgMBEgTgAQkPCg0KBQQE
AgMDEgTgARITCg0KBQQEAgMIEgTgARQ8ChAKCAQEAgMInAgAEgTgARU7Cj0KBAQEAgQSBOMB
Aj8aLyBPcHRpb25hbC4gRmllbGQgYnkgd2hpY2ggdG8gc29ydCB0aGUgcmVzdWx0cy4KCg0K
BQQEAgQFEgTjAQIICg0KBQQEAgQBEgTjAQkRCg0KBQQEAgQDEgTjARQVCg0KBQQEAgQIEgTj
ARY+ChAKCAQEAgQInAgAEgTjARc9ClYKAgQFEgbnAQD7AQEaSCBUaGUgcmVzcG9uc2UgbWVz
c2FnZSBmb3IgZ2V0dGluZyBhIGxpc3Qgb2YgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc2Au
CgoLCgMEBQESBOcBCCwKoQMKBAQFAgASBPABAkIakgMgVGhlIGxpc3Qgb2YgYFJlc3RvcmVW
ZXJpZmljYXRpb25QbGFuc2AgaW4gdGhlIHByb2plY3QgZm9yIHRoZSBzcGVjaWZpZWQKIGxv
Y2F0aW9uLgoKIElmIHRoZSBge2xvY2F0aW9ufWAgdmFsdWUgaW4gdGhlIHJlcXVlc3QgaXMg
Ii0iLCB0aGUgcmVzcG9uc2UgY29udGFpbnMgYQogbGlzdCBvZiByZXNvdXJjZXMgZnJvbSBh
bGwgbG9jYXRpb25zLiBJbiBjYXNlIGFueSBsb2NhdGlvbiBpcyB1bnJlYWNoYWJsZSwKIHRo
ZSByZXNwb25zZSB3aWxsIG9ubHkgcmV0dXJuIHJlc3RvcmUgdmVyaWZpY2F0aW9uIHBsYW5z
IGluIHJlYWNoYWJsZQogbG9jYXRpb25zIGFuZCB0aGUgJ3VucmVhY2hhYmxlJyBmaWVsZCB3
aWxsIGJlIHBvcHVsYXRlZCB3aXRoIGEgbGlzdCBvZgogdW5yZWFjaGFibGUgbG9jYXRpb25z
LgoKDQoFBAUCAAQSBPABAgoKDQoFBAUCAAYSBPABCyIKDQoFBAUCAAESBPABIz0KDQoFBAUC
AAMSBPABQEEKsgIKBAQFAgESBPcBAh0aowIgQSB0b2tlbiB3aGljaCBtYXkgYmUgc2VudCBh
cwogW3BhZ2VfdG9rZW5dW2dvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuTGlzdFJlc3Rv
cmVWZXJpZmljYXRpb25QbGFuc1JlcXVlc3QucGFnZV90b2tlbl0KIGluIGEgc3Vic2VxdWVu
dCBgTGlzdFJlc3RvcmVWZXJpZmljYXRpb25QbGFuc2AgY2FsbCB0byByZXRyaWV2ZSB0aGUg
bmV4dAogcGFnZSBvZiByZXN1bHRzLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQgb3IgZW1w
dHksIHRoZW4gdGhlcmUgYXJlIG5vIG1vcmUKIHJlc3VsdHMgdG8gcmV0dXJuLgoKDQoFBAUC
AQUSBPcBAggKDQoFBAUCAQESBPcBCRgKDQoFBAUCAQMSBPcBGxwKNAoEBAUCAhIE+gECIhom
IExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAUCAgQSBPoBAgoK
DQoFBAUCAgUSBPoBCxEKDQoFBAUCAgESBPoBEh0KDQoFBAUCAgMSBPoBICEKTQoCBAYSBv4B
AJ8CARo/IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIGRlbGV0aW5nIGEgYFJlc3RvcmVWZXJp
ZmljYXRpb25QbGFuYC4KCgsKAwQGARIE/gEILArCAQoEBAYCABIGgwICiAIEGrEBIFJlcXVp
cmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYFJlc3RvcmVWZXJpZmljYXRpb25QbGFu
YCB0byBkZWxldGUuCgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9yZXN0b3JlVmVyaWZpY2F0aW9uUGxhbnMve3Jlc3RvcmVWZXJpZmljYXRp
b25QbGFufWAKCg0KBQQGAgAFEgSDAgIICg0KBQQGAgABEgSDAgkNCg0KBQQGAgADEgSDAhAR
Cg8KBQQGAgAIEgaDAhKIAgMKEAoIBAYCAAicCAASBIQCBCoKEQoHBAYCAAifCBIGhQIEhwIF
CpEGCgQEBgIBEgaXAgKaAgQagAYgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQg
dG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28g
dGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBr
bm93IHRvCiBpZ25vcmUgdGhlIHJlcXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21w
bGV0ZWQuIFRoZSBzZXJ2ZXIgd2lsbAogZ3VhcmFudGVlIHRoYXQgZm9yIGF0IGxlYXN0IDYw
IG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUsIGNvbnNp
ZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVzdCBhbmQK
IHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3QgYWdhaW4g
d2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sgaWYgb3Jp
Z2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJlY2VpdmVk
LCBhbmQgaWYgc28sIHdpbGwgaWdub3JlIHRoZSBzZWNvbmQgcmVxdWVzdC4gVGhpcyBwcmV2
ZW50cwogY2xpZW50cyBmcm9tIGFjY2lkZW50YWxseSBjcmVhdGluZyBkdXBsaWNhdGUgY29t
bWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0
aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAw
MC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAYCAQUSBJcCAggKDQoFBAYC
AQESBJcCCRMKDQoFBAYCAQMSBJcCFhcKDwoFBAYCAQgSBpcCGJoCAwoTCgsEBgIBCMzx+YoB
ARIEmAIEKgoQCggEBgIBCJwIABIEmQIEKgqQAQoEBAYCAhIEngICOhqBASBPcHRpb25hbC4g
SWYgc2V0IHRvIHRydWUsIGFueSBSZXN0b3JlVmVyaWZpY2F0aW9uUGxhbkFzc29jaWF0aW9u
cyBsaW5rZWQgdG8KIHRoaXMgUmVzdG9yZVZlcmlmaWNhdGlvblBsYW4gd2lsbCBhbHNvIGJl
IGRlbGV0ZWQuCgoNCgUEBgICBRIEngICBgoNCgUEBgICARIEngIHDAoNCgUEBgICAxIEngIP
EAoNCgUEBgICCBIEngIROQoQCggEBgICCJwIABIEngISOGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan ===
    # Fields for RestoreVerificationPlan
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlan.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.RestoreVerificationPlan.State)
    # Field: schedule Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: success_cleanup_rule Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationCleanupRule)
    # Field: failure_cleanup_rule Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationCleanupRule)

# Enum: RestoreVerificationPlan::State
our $RestoreVerificationPlan_STATE_UNSPECIFIED = 0;
our $RestoreVerificationPlan_CREATING = 1;
our $RestoreVerificationPlan_ACTIVE = 2;
our $RestoreVerificationPlan_DELETING = 3;
our $RestoreVerificationPlan_INACTIVE = 4;
our $RestoreVerificationPlan_UPDATING = 5;
our $RestoreVerificationPlan_ERROR = 6;

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationCleanupRule ===
    # Fields for RestoreVerificationCleanupRule
    # Field: cleanup_delay Type: 11 (.google.protobuf.Duration)
    # Field: skip_cleanup Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest ===
    # Fields for CreateRestoreVerificationPlanRequest
    # Field: parent Type: 9 ()
    # Field: restore_verification_plan_id Type: 9 ()
    # Field: restore_verification_plan Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlan)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::GetRestoreVerificationPlanRequest ===
    # Fields for GetRestoreVerificationPlanRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::ListRestoreVerificationPlansRequest ===
    # Fields for ListRestoreVerificationPlansRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::ListRestoreVerificationPlansResponse ===
    # Fields for ListRestoreVerificationPlansResponse
    # Field: restore_verification_plans Type: 11 (.google.cloud.backupdr.v1beta.RestoreVerificationPlan)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest ===
    # Fields for DeleteRestoreVerificationPlanRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: force Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/restore_verification_plan.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan;

    my $msg = Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/restore_verification_plan.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan

A `RestoreVerificationPlan` specifies the scheduling and clean-up template
for automated restore verification. It contains a `schedule` to dictate when
the verifications should run, and a `RestoreVerificationCleanupRule` for
post-verification resource deletion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
`RestoreVerificationPlan`.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the `RestoreVerificationPlan` resource.

The description allows for additional details about
`RestoreVerificationPlan` and its use cases to be provided. An example
description is the following: "This is a restore verification plan that
performs a daily verification and cleans up the resources immediately
after." The description must be at most 2048 characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the `RestoreVerificationPlan` was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the `RestoreVerificationPlan` was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan::LabelsEntry>)

Optional. User-defined labels.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::State>)

Output only. The `State` for the `RestoreVerificationPlan`.

=item * C<< $msg->schedule() >> / C<< $msg->schedule($value) >>

Type: C<String>

Required. Describes the schedule on which the restore verification will be
executed.

The schedule is specified as a
[Crontab](https://en.wikipedia.org/wiki/Cron#Overview) string.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Optional. Specifies the time zone to be used in interpreting
[schedule][google.cloud.backupdr.v1beta.RestoreVerificationPlan.schedule].
The value of this field must be a time zone name from the [tz
database](https://en.wikipedia.org/wiki/Tz_database), like
"America/New_York" or "UTC". Defaults to `UTC` if not specified.

=item * C<< $msg->success_cleanup_rule() >> / C<< $msg->success_cleanup_rule($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationCleanupRule>)

Optional. The cleanup rule to apply if the restore verification succeeds.

=item * C<< $msg->failure_cleanup_rule() >> / C<< $msg->failure_cleanup_rule($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationCleanupRule>)

Optional. The cleanup rule to apply if the restore verification fails.

=back

=head3 Enum: RestoreVerificationPlan::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<INACTIVE> => C<4>

=item * C<UPDATING> => C<5>

=item * C<ERROR> => C<6>

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationCleanupRule

Defines the specific cleanup action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cleanup_delay() >> / C<< $msg->cleanup_delay($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Duration after restore finishes when cleanup triggers.
Delay must be non-negative and at most 30 days (2592000 seconds).

=item * C<< $msg->skip_cleanup() >> / C<< $msg->skip_cleanup($value) >>

Type: C<Bool>

Optional. If set to true, the restored resource will not be cleaned up.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::CreateRestoreVerificationPlanRequest

The request message for creating a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The `RestoreVerificationPlan` project and location in the format
`projects/{project}/locations/{location}`. In Google Cloud Backup and DR
locations map to Google Cloud regions, for example B<us-central1>.

=item * C<< $msg->restore_verification_plan_id() >> / C<< $msg->restore_verification_plan_id($value) >>

Type: C<String>

Required. The name of the `RestoreVerificationPlan` to create. The name
must be unique for the specified project and location. The name must start
with a lowercase letter followed by up to 62 lowercase letters, numbers, or
hyphens. Pattern, `^[a-z]([-a-z0-9]*[a-z0-9])?$`.

=item * C<< $msg->restore_verification_plan() >> / C<< $msg->restore_verification_plan($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan>)

Required. The `RestoreVerificationPlan` resource object to create.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::GetRestoreVerificationPlanRequest

The request message for getting a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `RestoreVerificationPlan` to retrieve.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::ListRestoreVerificationPlansRequest

The request message for getting a list of `RestoreVerificationPlans`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve
`RestoreVerificationPlans` information. Format:
`projects/{project}/locations/{location}`. In Google Cloud Backup and DR,
locations map to Google Cloud regions, for example B<us-central1>. To
retrieve restore verification plans for all locations, use
"-" for the `{location}` value.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `RestoreVerificationPlans` to return in a
single response. If not specified, a default value will be chosen by the
service. Note that the response may include a partial list and a caller
should only rely on the response's
[next_page_token][google.cloud.backupdr.v1beta.ListRestoreVerificationPlansResponse.next_page_token]
to determine if there are more instances left to be queried.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value of
[next_page_token][google.cloud.backupdr.v1beta.ListRestoreVerificationPlansResponse.next_page_token]
received from a previous `ListRestoreVerificationPlans` call.
Provide this to retrieve the subsequent page in a multi-page list of
results. When paginating, all other parameters provided to
`ListRestoreVerificationPlans` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Field match expression used to filter the results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field by which to sort the results.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::ListRestoreVerificationPlansResponse

The response message for getting a list of `RestoreVerificationPlans`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_verification_plans() >> / C<< $msg->restore_verification_plans($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::RestoreVerificationPlan>)

The list of `RestoreVerificationPlans` in the project for the specified
location.

If the `{location}` value in the request is "-", the response contains a
list of resources from all locations. In case any location is unreachable,
the response will only return restore verification plans in reachable
locations and the 'unreachable' field will be populated with a list of
unreachable locations.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token which may be sent as
[page_token][google.cloud.backupdr.v1beta.ListRestoreVerificationPlansRequest.page_token]
in a subsequent `ListRestoreVerificationPlans` call to retrieve the next
page of results. If this field is omitted or empty, then there are no more
results to return.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::DeleteRestoreVerificationPlanRequest

The request message for deleting a `RestoreVerificationPlan`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the `RestoreVerificationPlan` to delete.

Format:
`projects/{project}/locations/{location}/restoreVerificationPlans/{restoreVerificationPlan}`

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed. The server will
guarantee that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, will ignore the second request. This prevents
clients from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, any RestoreVerificationPlanAssociations linked to
this RestoreVerificationPlan will also be deleted.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::RestoreVerificationPlan::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
