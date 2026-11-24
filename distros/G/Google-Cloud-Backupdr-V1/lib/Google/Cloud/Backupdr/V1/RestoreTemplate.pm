package Google::Cloud::Backupdr::V1::RestoreTemplate;

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
    eval { require Google::Cloud::Backupdr::V1::RestoreTemplateCommon };
    eval { require Google::Cloud::Backupdr::V1::RestoreTemplateExecution };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvcmVzdG9yZV90ZW1wbGF0ZS5wcm90bxIYZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3Rv
Ghtnb29nbGUvYXBpL2ZpZWxkX2luZm8ucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJv
dG8aNmdvb2dsZS9jbG91ZC9iYWNrdXBkci92MS9yZXN0b3JlX3RlbXBsYXRlX2NvbW1vbi5w
cm90bxo5Z29vZ2xlL2Nsb3VkL2JhY2t1cGRyL3YxL3Jlc3RvcmVfdGVtcGxhdGVfZXhlY3V0
aW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxocZ29vZ2xlL3By
b3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKq
CgoPUmVzdG9yZVRlbXBsYXRlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIlCgtkZXNjcmlw
dGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJACgtjcmVhdGVfdGltZRgDIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIr
Cg1yZXNvdXJjZV90eXBlGAUgASgJQgbgQQXgQQJSDHJlc291cmNlVHlwZRJSCgZsYWJlbHMY
BiADKAsyNS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuUmVzdG9yZVRlbXBsYXRlLkxhYmVs
c0VudHJ5QgPgQQFSBmxhYmVscxJsChdiYWNrdXBfc2VsZWN0aW9uX2NvbmZpZxgHIAEoCzIv
Lmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5CYWNrdXBTZWxlY3Rpb25Db25maWdCA+BBAlIV
YmFja3VwU2VsZWN0aW9uQ29uZmlnEl0KEnByZV9yZXN0b3JlX2NvbmZpZxgIIAEoCzIqLmdv
b2dsZS5jbG91ZC5iYWNrdXBkci52MS5QcmVSZXN0b3JlQ29uZmlnQgPgQQFSEHByZVJlc3Rv
cmVDb25maWcSYAoTcG9zdF9yZXN0b3JlX2NvbmZpZxgJIAEoCzIrLmdvb2dsZS5jbG91ZC5i
YWNrdXBkci52MS5Qb3N0UmVzdG9yZUNvbmZpZ0ID4EEBUhFwb3N0UmVzdG9yZUNvbmZpZxJi
ChN2ZXJpZmljYXRpb25fY29uZmlnGAogASgLMiwuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
LlZlcmlmaWNhdGlvbkNvbmZpZ0ID4EEBUhJ2ZXJpZmljYXRpb25Db25maWcSSwoScmVzdG9y
ZV9wcm9wZXJ0aWVzGAsgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EECUhFyZXN0
b3JlUHJvcGVydGllcxJKCgVzdGF0ZRgMIAEoDjIvLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MS5SZXN0b3JlVGVtcGxhdGUuU3RhdGVCA+BBA1IFc3RhdGUSXAoRZXhlY3V0aW9uX3N1bW1h
cnkYDSABKAsyKi5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuRXhlY3V0aW9uU3VtbWFyeUID
4EEDUhBleGVjdXRpb25TdW1tYXJ5EhcKBGV0YWcYDiABKAlCA+BBAVIEZXRhZxo5CgtMYWJl
bHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIlQK
BVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDAoIQ1JFQVRJTkcQARIKCgZBQ1RJVkUQ
AhIMCghVUERBVElORxADEgwKCERFTEVUSU5HEAQ6nQHqQZkBCidiYWNrdXBkci5nb29nbGVh
cGlzLmNvbS9SZXN0b3JlVGVtcGxhdGUSS3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9yZXN0b3JlVGVtcGxhdGVzL3tyZXN0b3JlX3RlbXBsYXRlfSoQcmVzdG9y
ZVRlbXBsYXRlczIPcmVzdG9yZVRlbXBsYXRlIu0BChBFeGVjdXRpb25TdW1tYXJ5El8KDmxh
c3RfZXhlY3V0aW9uGAEgASgJQjjgQQP6QTIKMGJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jl
c3RvcmVUZW1wbGF0ZUV4ZWN1dGlvblINbGFzdEV4ZWN1dGlvbhJ4ChRsYXN0X2V4ZWN1dGlv
bl9zdGF0ZRgCIAEoDjJBLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MS5SZXN0b3JlVGVtcGxh
dGVFeGVjdXRpb24uRXhlY3V0aW9uU3RhdGVCA+BBA1ISbGFzdEV4ZWN1dGlvblN0YXRlIqMC
ChxDcmVhdGVSZXN0b3JlVGVtcGxhdGVSZXF1ZXN0EkcKBnBhcmVudBgBIAEoCUIv4EEC+kEp
EidiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVtcGxhdGVSBnBhcmVudBIzChNy
ZXN0b3JlX3RlbXBsYXRlX2lkGAIgASgJQgPgQQJSEXJlc3RvcmVUZW1wbGF0ZUlkElkKEHJl
c3RvcmVfdGVtcGxhdGUYAyABKAsyKS5nb29nbGUuY2xvdWQuYmFja3VwZHIudjEuUmVzdG9y
ZVRlbXBsYXRlQgPgQQJSD3Jlc3RvcmVUZW1wbGF0ZRIqCgpyZXF1ZXN0X2lkGAQgASgJQgvi
jM/XCAIIAeBBAVIJcmVxdWVzdElkImAKGUdldFJlc3RvcmVUZW1wbGF0ZVJlcXVlc3QSQwoE
bmFtZRgBIAEoCUIv4EEC+kEpCidiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVt
cGxhdGVSBG5hbWUikQIKHFVwZGF0ZVJlc3RvcmVUZW1wbGF0ZVJlcXVlc3QSQAoLdXBkYXRl
X21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1h
c2sSWQoQcmVzdG9yZV90ZW1wbGF0ZRgCIAEoCzIpLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52
MS5SZXN0b3JlVGVtcGxhdGVCA+BBAlIPcmVzdG9yZVRlbXBsYXRlEioKCnJlcXVlc3RfaWQY
AyABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQSKAoNdmFsaWRhdGVfb25seRgEIAEoCEID
4EEBUgx2YWxpZGF0ZU9ubHkiqgEKHERlbGV0ZVJlc3RvcmVUZW1wbGF0ZVJlcXVlc3QSQwoE
bmFtZRgBIAEoCUIv4EEC+kEpCidiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9SZXN0b3JlVGVt
cGxhdGVSBG5hbWUSKgoKcmVxdWVzdF9pZBgCIAEoCUIL4ozP1wgCCAHgQQFSCXJlcXVlc3RJ
ZBIZCgVmb3JjZRgDIAEoCEID4EEBUgVmb3JjZSLMAQoZUnVuUmVzdG9yZVRlbXBsYXRlUmVx
dWVzdBJDCgRuYW1lGAEgASgJQi/gQQL6QSkKJ2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL1Jl
c3RvcmVUZW1wbGF0ZVIEbmFtZRI+CgZiYWNrdXAYAiABKAlCJuBBAfpBIAoeYmFja3VwZHIu
Z29vZ2xlYXBpcy5jb20vQmFja3VwUgZiYWNrdXASKgoKcmVxdWVzdF9pZBgDIAEoCUIL4ozP
1wgCCAHgQQFSCXJlcXVlc3RJZCKUAQoaUnVuUmVzdG9yZVRlbXBsYXRlUmVzcG9uc2USdgoa
cmVzdG9yZV90ZW1wbGF0ZV9leGVjdXRpb24YASABKAlCOOBBA/pBMgowYmFja3VwZHIuZ29v
Z2xlYXBpcy5jb20vUmVzdG9yZVRlbXBsYXRlRXhlY3V0aW9uUhhyZXN0b3JlVGVtcGxhdGVF
eGVjdXRpb24i6QEKG0xpc3RSZXN0b3JlVGVtcGxhdGVzUmVxdWVzdBJHCgZwYXJlbnQYASAB
KAlCL+BBAvpBKRInYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vUmVzdG9yZVRlbXBsYXRlUgZw
YXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4Y
AyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoI
b3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLAAQocTGlzdFJlc3RvcmVUZW1wbGF0ZXNS
ZXNwb25zZRJWChFyZXN0b3JlX3RlbXBsYXRlcxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5iYWNr
dXBkci52MS5SZXN0b3JlVGVtcGxhdGVSEHJlc3RvcmVUZW1wbGF0ZXMSJgoPbmV4dF9wYWdl
X3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJl
YWNoYWJsZULEAQocY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MUIUUmVzdG9yZVRlbXBs
YXRlUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYWNrdXBkci9hcGl2MS9iYWNrdXBk
cnBiO2JhY2t1cGRycGKqAhhHb29nbGUuQ2xvdWQuQmFja3VwRFIuVjHKAhhHb29nbGVcQ2xv
dWRcQmFja3VwRFJcVjHqAhtHb29nbGU6OkNsb3VkOjpCYWNrdXBEUjo6VjFKjVgKBxIFDgDK
AgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwAS
AxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAQAoJCgIDBBIDFgBDCgkKAgMF
EgMXACoKCQoCAwYSAxgAJgoJCgIDBxIDGQApCggKAQgSAxsANQoJCgIIJRIDGwA1CggKAQgS
AxwATwoJCgIICxIDHABPCggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4ANQoJCgIICBID
HgA1CggKAQgSAx8ANQoJCgIIARIDHwA1CggKAQgSAyAANQoJCgIIKRIDIAA1CggKAQgSAyEA
NAoJCgIILRIDIQA0CmMKAgQAEgQlAH4BGlcgQSBgUmVzdG9yZVRlbXBsYXRlYCBlbmNhcHN1
bGF0ZXMgRFIgcmVhZGluZXNzIGNvbmZpZ3VyYXRpb25zIGZvciB2YWxpZGF0aW5nCiBiYWNr
dXBzLgoKCgoDBAABEgMlCBcKCwoDBAAHEgQmAisECg0KBQQAB50IEgQmAisECjEKBAQABAAS
BC4CPQMaIyBUaGUgc3RhdGUgb2YgdGhlIFJlc3RvcmVUZW1wbGF0ZS4KCgwKBQQABAABEgMu
BwwKJQoGBAAEAAIAEgMwBBoaFiBTdGF0ZSBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAAIAARID
MAQVCg4KBwQABAACAAISAzAYGQovCgYEAAQAAgESAzMEERogIFRoZSB0ZW1wbGF0ZSBpcyBi
ZWluZyBjcmVhdGVkLgoKDgoHBAAEAAIBARIDMwQMCg4KBwQABAACAQISAzMPEAo5CgYEAAQA
AgISAzYEDxoqIFRoZSB0ZW1wbGF0ZSBpcyBhY3RpdmUgYW5kIHJlYWR5IHRvIHVzZS4KCg4K
BwQABAACAgESAzYECgoOCgcEAAQAAgICEgM2DQ4KLwoGBAAEAAIDEgM5BBEaICBUaGUgdGVt
cGxhdGUgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAACAwESAzkEDAoOCgcEAAQAAgMCEgM5
DxAKLwoGBAAEAAIEEgM8BBEaICBUaGUgdGVtcGxhdGUgaXMgYmVpbmcgZGVsZXRlZC4KCg4K
BwQABAACBAESAzwEDAoOCgcEAAQAAgQCEgM8DxAKRAoEBAACABIDQAI9GjcgSWRlbnRpZmll
ci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFJlc3RvcmVUZW1wbGF0ZS4KCgwKBQQAAgAF
EgNAAggKDAoFBAACAAESA0AJDQoMCgUEAAIAAxIDQBARCgwKBQQAAgAIEgNAEjwKDwoIBAAC
AAicCAASA0ATOwpLCgQEAAIBEgNDAkIaPiBPcHRpb25hbC4gVXNlci1wcm92aWRlZCBkZXNj
cmlwdGlvbiBvZiB0aGUgcmVzdG9yZSB0ZW1wbGF0ZS4KCgwKBQQAAgEFEgNDAggKDAoFBAAC
AQESA0MJFAoMCgUEAAIBAxIDQxcYCgwKBQQAAgEIEgNDGUEKDwoIBAACAQicCAASA0MaQApM
CgQEAAICEgRGAkcyGj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIHJlc3RvcmUg
dGVtcGxhdGUgd2FzIGNyZWF0ZWQuCgoMCgUEAAICBhIDRgIbCgwKBQQAAgIBEgNGHCcKDAoF
BAACAgMSA0YqKwoMCgUEAAICCBIDRwYxCg8KCAQAAgIInAgAEgNHBzAKUQoEBAACAxIESgJL
MhpDIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSByZXN0b3JlIHRlbXBsYXRlIHdh
cyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAIDBhIDSgIbCgwKBQQAAgMBEgNKHCcKDAoFBAACAwMS
A0oqKwoMCgUEAAIDCBIDSwYxCg8KCAQAAgMInAgAEgNLBzAKuQEKBAQAAgQSBFACUwQaqgEg
UmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHNwZWNpZmljIHR5cGUgb2YgdGhlIHdvcmtsb2Fk
IGJlaW5nIHJlc3RvcmVkLgogVGhlIGZvcm1hdCBpcyAie3NlcnZpY2VfbmFtZX0ve3Jlc291
cmNlX2tpbmR9IiwgZm9yIGV4YW1wbGUsCiAiY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0
YW5jZSIuCgoMCgUEAAIEBRIDUAIICgwKBQQAAgQBEgNQCRYKDAoFBAACBAMSA1AZGgoNCgUE
AAIECBIEUBtTAwoPCggEAAIECJwIABIDUQQrCg8KCAQAAgQInAgBEgNSBCoKLQoEBAACBRID
VgJKGiAgT3B0aW9uYWwuIFVzZXItZGVmaW5lZCBsYWJlbHMuCgoMCgUEAAIFBhIDVgIVCgwK
BQQAAgUBEgNWFhwKDAoFBAACBQMSA1YfIAoMCgUEAAIFCBIDViFJCg8KCAQAAgUInAgAEgNW
IkgKOQoEBAACBhIEWQJaLxorIFJlcXVpcmVkLiBCYWNrdXAgc2VsZWN0aW9uIGNvbmZpZ3Vy
YXRpb24uCgoMCgUEAAIGBhIDWQIXCgwKBQQAAgYBEgNZGC8KDAoFBAACBgMSA1kyMwoMCgUE
AAIGCBIDWgYuCg8KCAQAAgYInAgAEgNaBy0KNAoEBAACBxIEXQJeLxomIE9wdGlvbmFsLiBQ
cmUtcmVzdG9yZSBjb25maWd1cmF0aW9uLgoKDAoFBAACBwYSA10CEgoMCgUEAAIHARIDXRMl
CgwKBQQAAgcDEgNdKCkKDAoFBAACBwgSA14GLgoPCggEAAIHCJwIABIDXgctCjUKBAQAAggS
BGECYi8aJyBPcHRpb25hbC4gUG9zdC1yZXN0b3JlIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAII
BhIDYQITCgwKBQQAAggBEgNhFCcKDAoFBAACCAMSA2EqKwoMCgUEAAIICBIDYgYuCg8KCAQA
AggInAgAEgNiBy0KNQoEBAACCRIEZQJmLxonIE9wdGlvbmFsLiBWZXJpZmljYXRpb24gY29u
ZmlndXJhdGlvbi4KCgwKBQQAAgkGEgNlAhQKDAoFBAACCQESA2UVKAoMCgUEAAIJAxIDZSst
CgwKBQQAAgkIEgNmBi4KDwoIBAACCQicCAASA2YHLQq/BAoEBAACChIEcgJzLxqwBCBSZXF1
aXJlZC4gRGVmaW5lcyB0YXJnZXQgZW52aXJvbm1lbnRzIHdoZXJlIHRoZSByZXNvdXJjZSB3
aWxsIGJlIHJlc3RvcmVkLgoKIFRoZSB0YXJnZXQgcmVzb3VyY2UgbmFtZSBpbiBgcmVzdG9y
ZV9wcm9wZXJ0aWVzYCBzdXBwb3J0cyB0aGUKIGB7RVhFQ1VUSU9OX0lEfWAgdG9rZW4gdG8g
ZHluYW1pY2FsbHkgZ2VuZXJhdGUgdW5pcXVlIHJlc291cmNlIG5hbWVzIGZvcgogZWFjaCBl
eGVjdXRpb24uIER1cmluZyByZXN0b3JlIGV4ZWN1dGlvbiwgZXZlcnkgb2NjdXJyZW5jZSBv
ZgogYHtFWEVDVVRJT05fSUR9YCBpbiB0aGUgdGFyZ2V0IHJlc291cmNlIG5hbWUgaXMgcmVw
bGFjZWQgd2l0aCB0aGUKIDgtY2hhcmFjdGVyIGBSZXN0b3JlVGVtcGxhdGVFeGVjdXRpb25g
IElEIChmb3IgZXhhbXBsZSwKIGAicmVzdG9yZWQtcmVzb3VyY2Ute0VYRUNVVElPTl9JRH0i
YCBvcgogYCJyZXN0b3JlZC17RVhFQ1VUSU9OX0lEfS1yZXNvdXJjZSJgIHJlc29sdmVzIHRv
CiBgInJlc3RvcmVkLXJlc291cmNlLTVkNDM3YjA2ImAgb3IgYCJyZXN0b3JlZC01ZDQzN2Iw
Ni1yZXNvdXJjZSJgKS4KCgwKBQQAAgoGEgNyAhgKDAoFBAACCgESA3IZKwoMCgUEAAIKAxID
ci4wCgwKBQQAAgoIEgNzBi4KDwoIBAACCgicCAASA3MHLQo+CgQEAAILEgN2Aj8aMSBPdXRw
dXQgb25seS4gVGhlIHN0YXRlIG9mIHRoZSByZXN0b3JlIHRlbXBsYXRlLgoKDAoFBAACCwYS
A3YCBwoMCgUEAAILARIDdggNCgwKBQQAAgsDEgN2EBIKDAoFBAACCwgSA3YTPgoPCggEAAIL
CJwIABIDdhQ9CjsKBAQAAgwSBHkCejIaLSBPdXRwdXQgb25seS4gU3VtbWFyeSBvZiB0aGUg
bGFzdCBleGVjdXRpb24uCgoMCgUEAAIMBhIDeQISCgwKBQQAAgwBEgN5EyQKDAoFBAACDAMS
A3knKQoMCgUEAAIMCBIDegYxCg8KCAQAAgwInAgAEgN6BzAKNgoEBAACDRIDfQI8GikgT3B0
aW9uYWwuIEV0YWcgZm9yIGNvbmN1cnJlbmN5IGNvbnRyb2wuCgoMCgUEAAINBRIDfQIICgwK
BQQAAg0BEgN9CQ0KDAoFBAACDQMSA30QEgoMCgUEAAINCBIDfRM7Cg8KCAQAAg0InAgAEgN9
FDoKLgoCBAESBoEBAI8BARogIFN1bW1hcnkgb2YgdGhlIGxhc3QgZXhlY3V0aW9uLgoKCwoD
BAEBEgSBAQgYCrcBCgQEAQIAEgaFAQKKAQQapgEgT3V0cHV0IG9ubHkuIFRoZSByZXNvdXJj
ZSBuYW1lIG9mIHRoZSBsYXN0IGV4ZWN1dGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcmVzdG9yZVRlbXBsYXRlcy97cmVzdG9yZV90
ZW1wbGF0ZX0vZXhlY3V0aW9ucy97ZXhlY3V0aW9ufWAKCg0KBQQBAgAFEgSFAQIICg0KBQQB
AgABEgSFAQkXCg0KBQQBAgADEgSFARobCg8KBQQBAgAIEgaFARyKAQMKEAoIBAECAAicCAAS
BIYBBC0KEQoHBAECAAifCBIGhwEEiQEFCj8KBAQBAgESBo0BAo4BMhovIE91dHB1dCBvbmx5
LiBUaGUgc3RhdGUgb2YgdGhlIGxhc3QgZXhlY3V0aW9uLgoKDQoFBAECAQYSBI0BAikKDQoF
BAECAQESBI0BKj4KDQoFBAECAQMSBI0BQUIKDQoFBAECAQgSBI4BBjEKEAoIBAECAQicCAAS
BI4BBzAKSAoCBAISBpIBAK0BARo6IFJlcXVlc3QgbWVzc2FnZSBmb3IgY3JlYXRpbmcgYSBS
ZXN0b3JlVGVtcGxhdGUgaW5zdGFuY2UuCgoLCgMEAgESBJIBCCQKggEKBAQCAgASBpUBApoB
BBpyIFJlcXVpcmVkLiBUaGUgcmVzdG9yZSB0ZW1wbGF0ZSBwcm9qZWN0IGFuZCBsb2NhdGlv
biBpbiB0aGUgZm9ybWF0CiAncHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9j
YXRpb259Jy4KCg0KBQQCAgAFEgSVAQIICg0KBQQCAgABEgSVAQkPCg0KBQQCAgADEgSVARIT
Cg8KBQQCAgAIEgaVARSaAQMKEAoIBAICAAicCAASBJYBBCoKEQoHBAICAAifCBIGlwEEmQEF
CoIBCgQEAgIBEgSeAQJKGnQgUmVxdWlyZWQuIFRoZSBJRCBvZiB0aGUgcmVzdG9yZSB0ZW1w
bGF0ZSB0byBjcmVhdGUuIFRoZSBJRCBtdXN0IGJlCiB1bmlxdWUgZm9yIHRoZSBzcGVjaWZp
ZWQgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoNCgUEAgIBBRIEngECCAoNCgUEAgIBARIEngEJ
HAoNCgUEAgIBAxIEngEfIAoNCgUEAgIBCBIEngEhSQoQCggEAgIBCJwIABIEngEiSAo1CgQE
AgICEgShAQJQGicgUmVxdWlyZWQuIEEgUmVzdG9yZVRlbXBsYXRlIHJlc291cmNlLgoKDQoF
BAICAgYSBKEBAhEKDQoFBAICAgESBKEBEiIKDQoFBAICAgMSBKEBJSYKDQoFBAICAggSBKEB
J08KEAoIBAICAgicCAASBKEBKE4K3gIKBAQCAgMSBqkBAqwBBBrNAiBPcHRpb25hbC4gQW4g
b3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVu
aXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVz
dCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBo
YXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEg
dmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBz
dXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUE
AgIDBRIEqQECCAoNCgUEAgIDARIEqQEJEwoNCgUEAgIDAxIEqQEWFwoPCgUEAgIDCBIGqQEY
rAEDChMKCwQCAgMIzPH5igEBEgSqAQQqChAKCAQCAgMInAgAEgSrAQQqCkcKAgQDEgawAQC6
AQEaOSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGdldHRpbmcgYSBSZXN0b3JlVGVtcGxhdGUgaW5z
dGFuY2UuCgoLCgMEAwESBLABCCEKqAEKBAQDAgASBrQBArkBBBqXASBSZXF1aXJlZC4gVGhl
IG5hbWUgb2YgdGhlIHJlc3RvcmUgdGVtcGxhdGUgdG8gcmV0cmlldmUuCiBGb3JtYXQ6CiAn
cHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVUZW1w
bGF0ZXMve3Jlc3RvcmVfdGVtcGxhdGVfaWR9JwoKDQoFBAMCAAUSBLQBAggKDQoFBAMCAAES
BLQBCQ0KDQoFBAMCAAMSBLQBEBEKDwoFBAMCAAgSBrQBErkBAwoQCggEAwIACJwIABIEtQEE
KgoRCgcEAwIACJ8IEga2AQS4AQUKSAoCBAQSBr0BANcBARo6IFJlcXVlc3QgbWVzc2FnZSBm
b3IgdXBkYXRpbmcgYSBSZXN0b3JlVGVtcGxhdGUgaW5zdGFuY2UuCgoLCgMEBAESBL0BCCQK
tgIKBAQEAgASBsMBAsQBLxqlAiBPcHRpb25hbC4gVGhlIGxpc3Qgb2YgZmllbGRzIHRvIHVw
ZGF0ZS4KIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUg
b3ZlcndyaXR0ZW4gaW4gdGhlCiBSZXN0b3JlVGVtcGxhdGUgcmVzb3VyY2UgYnkgdGhlIHVw
ZGF0ZS4KIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGluIHRoZSB1cGRhdGVfbWFzayBhcmUgcmVs
YXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QKIHRoZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQg
d2lsbCBiZSBvdmVyd3JpdHRlbiBpZiBpdCBpcyBpbiB0aGUgbWFzay4KCg0KBQQEAgAGEgTD
AQIbCg0KBQQEAgABEgTDARwnCg0KBQQEAgADEgTDASorCg0KBQQEAgAIEgTEAQYuChAKCAQE
AgAInAgAEgTEAQctCjkKBAQEAgESBMcBAlAaKyBSZXF1aXJlZC4gVGhlIHJlc3RvcmUgdGVt
cGxhdGUgdG8gdXBkYXRlLgoKDQoFBAQCAQYSBMcBAhEKDQoFBAQCAQESBMcBEiIKDQoFBAQC
AQMSBMcBJSYKDQoFBAQCAQgSBMcBJ08KEAoIBAQCAQicCAASBMcBKE4K3gIKBAQEAgISBs8B
AtIBBBrNAiBPcHRpb25hbC4gQW4gb3B0aW9uYWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSBy
ZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBt
dXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNlcnZlciB3aWxsIGtub3cgdG8KIGlnbm9y
ZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4KCiBUaGUg
cmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRoIHRoZSBleGNlcHRpb24gdGhh
dCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAw
LTAwMDAwMDAwMDAwMCkuCgoNCgUEBAICBRIEzwECCAoNCgUEBAICARIEzwEJEwoNCgUEBAIC
AxIEzwEWFwoPCgUEBAICCBIGzwEY0gEDChMKCwQEAgIIzPH5igEBEgTQAQQqChAKCAQEAgII
nAgAEgTRAQQqCmsKBAQEAgMSBNYBAkIaXSBPcHRpb25hbC4gT25seSB2YWxpZGF0ZSB0aGUg
cmVxdWVzdCwgYnV0IGRvIG5vdCBwZXJmb3JtIG11dGF0aW9ucy4KIFRoZSBkZWZhdWx0IGlz
ICdmYWxzZScuCgoNCgUEBAIDBRIE1gECBgoNCgUEBAIDARIE1gEHFAoNCgUEBAIDAxIE1gEX
GAoNCgUEBAIDCBIE1gEZQQoQCggEBAIDCJwIABIE1gEaQApICgIEBRIG2gEA9AEBGjogUmVx
dWVzdCBtZXNzYWdlIGZvciBkZWxldGluZyBhIFJlc3RvcmVUZW1wbGF0ZSBpbnN0YW5jZS4K
CgsKAwQFARIE2gEIJAqmAQoEBAUCABIG3gEC4wEEGpUBIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgcmVzdG9yZSB0ZW1wbGF0ZSB0byBkZWxldGUuCiBGb3JtYXQ6CiAncHJvamVjdHMv
e3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jlc3RvcmVUZW1wbGF0ZXMve3Jl
c3RvcmVfdGVtcGxhdGVfaWR9JwoKDQoFBAUCAAUSBN4BAggKDQoFBAUCAAESBN4BCQ0KDQoF
BAUCAAMSBN4BEBEKDwoFBAUCAAgSBt4BEuMBAwoQCggEBQIACJwIABIE3wEEKgoRCgcEBQIA
CJ8IEgbgAQTiAQUK3gIKBAQFAgESBusBAu4BBBrNAiBPcHRpb25hbC4gQW4gb3B0aW9uYWwg
cmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQogcmVx
dWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhlIHNl
cnZlciB3aWxsIGtub3cgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBpZiBpdCBoYXMgYWxyZWFk
eSBiZWVuIGNvbXBsZXRlZC4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJ
RCB3aXRoIHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQg
KDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBQIBBRIE6wEC
CAoNCgUEBQIBARIE6wEJEwoNCgUEBQIBAxIE6wEWFwoPCgUEBQIBCBIG6wEY7gEDChMKCwQF
AgEIzPH5igEBEgTsAQQqChAKCAQFAgEInAgAEgTtAQQqCrgBCgQEBQICEgTzAQI6GqkBIE9w
dGlvbmFsLiBJZiBzZXQgdG8gdHJ1ZSwgYW55IGNoaWxkIFJlc3RvcmVUZW1wbGF0ZUV4ZWN1
dGlvbnMgd2lsbCBhbHNvIGJlCiBkZWxldGVkLiBJZiBmYWxzZSBhbmQgdGhlIFJlc3RvcmVU
ZW1wbGF0ZSBoYXMgYW55IGNoaWxkIGV4ZWN1dGlvbnMsIHRoZQogcmVxdWVzdCB3aWxsIGZh
aWwuCgoNCgUEBQICBRIE8wECBgoNCgUEBQICARIE8wEHDAoNCgUEBQICAxIE8wEPEAoNCgUE
BQICCBIE8wEROQoQCggEBQICCJwIABIE8wESOAo+CgIEBhIG9wEAlgIBGjAgUmVxdWVzdCBt
ZXNzYWdlIGZvciBydW5uaW5nIGEgUmVzdG9yZVRlbXBsYXRlLgoKCwoDBAYBEgT3AQghCqMB
CgQEBgIAEgb7AQKAAgQakgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXN0b3JlIHRl
bXBsYXRlIHRvIHJ1bi4KIEZvcm1hdDoKICdwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVzdG9yZVRlbXBsYXRlcy97cmVzdG9yZV90ZW1wbGF0ZV9pZH0n
CgoNCgUEBgIABRIE+wECCAoNCgUEBgIAARIE+wEJDQoNCgUEBgIAAxIE+wEQEQoPCgUEBgIA
CBIG+wESgAIDChAKCAQGAgAInAgAEgT8AQQqChEKBwQGAgAInwgSBv0BBP8BBQq/AgoEBAYC
ARIGhwICigIEGq4CIE9wdGlvbmFsLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQmFja3Vw
IHRvIHJlc3RvcmUgZnJvbS4KIElmIG5vdCBzcGVjaWZpZWQsIHRoZSBsYXRlc3QgYmFja3Vw
IG1hdGNoaW5nIHRoZSBiYWNrdXAgc2VsZWN0aW9uCiBjb25maWd1cmF0aW9uIGluIHRoZSBS
ZXN0b3JlVGVtcGxhdGUgd2lsbCBiZSB1c2VkLgogRm9ybWF0OgogJ3Byb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBWYXVsdHMve2JhY2t1cF92YXVsdH0v
ZGF0YVNvdXJjZXMve2RhdGFfc291cmNlfS9iYWNrdXBzL3tiYWNrdXB9JwoKDQoFBAYCAQUS
BIcCAggKDQoFBAYCAQESBIcCCQ8KDQoFBAYCAQMSBIcCEhMKDwoFBAYCAQgSBocCFIoCAwoQ
CggEBgIBCJwIABIEiAIEKgoPCgcEBgIBCJ8IEgSJAgRQCt4CCgQEBgICEgaSAgKVAgQazQIg
T3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMu
IFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRy
eSB5b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIgd2lsbCBrbm93IHRvCiBpZ25vcmUgdGhlIHJl
cXVlc3QgaWYgaXQgaGFzIGFscmVhZHkgYmVlbiBjb21wbGV0ZWQuCgogVGhlIHJlcXVlc3Qg
SUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBV
VUlEIGlzCiBub3Qgc3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAw
MDAwMDApLgoKDQoFBAYCAgUSBJICAggKDQoFBAYCAgESBJICCRMKDQoFBAYCAgMSBJICFhcK
DwoFBAYCAggSBpICGJUCAwoTCgsEBgICCMzx+YoBARIEkwIEKgoQCggEBgICCJwIABIElAIE
Kgo4CgIEBxIGmQIAowIBGiogUmVzcG9uc2UgbWVzc2FnZSBmb3IgUnVuUmVzdG9yZVRlbXBs
YXRlLgoKCwoDBAcBEgSZAggiCssBCgQEBwIAEgadAgKiAgQaugEgT3V0cHV0IG9ubHkuIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBpbml0aWF0ZWQgUmVzdG9yZVRlbXBsYXRlRXhlY3V0
aW9uLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9yZXN0b3JlVGVtcGxhdGVzL3tyZXN0b3JlX3RlbXBsYXRlfS9leGVjdXRpb25zL3tleGVj
dXRpb259YAoKDQoFBAcCAAUSBJ0CAggKDQoFBAcCAAESBJ0CCSMKDQoFBAcCAAMSBJ0CJicK
DwoFBAcCAAgSBp0CKKICAwoQCggEBwIACJwIABIEngIELQoRCgcEBwIACJ8IEgafAgShAgUK
PQoCBAgSBqYCAL0CARovIFJlcXVlc3QgbWVzc2FnZSBmb3IgbGlzdGluZyBSZXN0b3JlVGVt
cGxhdGVzLgoKCwoDBAgBEgSmAggjCpQBCgQECAIAEgaqAgKvAgQagwEgUmVxdWlyZWQuIFRo
ZSBwcm9qZWN0IGFuZCBsb2NhdGlvbiBmcm9tIHdoaWNoIHRvIGxpc3QgdGhlIHJlc3RvcmUK
IHRlbXBsYXRlcy4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAuCgoNCgUECAIABRIEqgICCAoNCgUECAIAARIEqgIJDwoNCgUECAIAAxIEqgIS
EwoPCgUECAIACBIGqgIUrwIDChAKCAQIAgAInAgAEgSrAgQqChEKBwQIAgAInwgSBqwCBK4C
BQpACgQECAIBEgSyAgI/GjIgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVt
cyB0byByZXR1cm4uCgoNCgUECAIBBRIEsgICBwoNCgUECAIBARIEsgIIEQoNCgUECAIBAxIE
sgIUFQoNCgUECAIBCBIEsgIWPgoQCggECAIBCJwIABIEsgIXPQpeCgQECAICEgS2AgJBGlAg
T3B0aW9uYWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0
UmVzdG9yZVRlbXBsYXRlc2AKIGNhbGwuCgoNCgUECAICBRIEtgICCAoNCgUECAICARIEtgIJ
EwoNCgUECAICAxIEtgIWFwoNCgUECAICCBIEtgIYQAoQCggECAICCJwIABIEtgIZPwpMCgQE
CAIDEgS5AgI9Gj4gT3B0aW9uYWwuIEZpZWxkIG1hdGNoIGV4cHJlc3Npb24gdXNlZCB0byBm
aWx0ZXIgdGhlIHJlc3VsdHMuCgoNCgUECAIDBRIEuQICCAoNCgUECAIDARIEuQIJDwoNCgUE
CAIDAxIEuQISEwoNCgUECAIDCBIEuQIUPAoQCggECAIDCJwIABIEuQIVOwo9CgQECAIEEgS8
AgI/Gi8gT3B0aW9uYWwuIEZpZWxkIGJ5IHdoaWNoIHRvIHNvcnQgdGhlIHJlc3VsdHMuCgoN
CgUECAIEBRIEvAICCAoNCgUECAIEARIEvAIJEQoNCgUECAIEAxIEvAIUFQoNCgUECAIECBIE
vAIWPgoQCggECAIECJwIABIEvAIXPQo+CgIECRIGwAIAygIBGjAgUmVzcG9uc2UgbWVzc2Fn
ZSBmb3IgbGlzdGluZyBSZXN0b3JlVGVtcGxhdGVzLgoKCwoDBAkBEgTAAggkCi0KBAQJAgAS
BMICAjEaHyBUaGUgbGlzdCBvZiBSZXN0b3JlVGVtcGxhdGVzLgoKDQoFBAkCAAQSBMICAgoK
DQoFBAkCAAYSBMICCxoKDQoFBAkCAAESBMICGywKDQoFBAkCAAMSBMICLzAKZwoEBAkCARIE
xgICHRpZIEEgdG9rZW4gd2hpY2ggbWF5IGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIGluIGEg
c3Vic2VxdWVudAogYExpc3RSZXN0b3JlVGVtcGxhdGVzYCBjYWxsLgoKDQoFBAkCAQUSBMYC
AggKDQoFBAkCAQESBMYCCRgKDQoFBAkCAQMSBMYCGxwKNAoEBAkCAhIEyQICIhomIExvY2F0
aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkLgoKDQoFBAkCAgQSBMkCAgoKDQoFBAkC
AgUSBMkCCxEKDQoFBAkCAgESBMkCEh0KDQoFBAkCAgMSBMkCICFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate ===
    # Fields for RestoreTemplate
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resource_type Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.backupdr.v1.RestoreTemplate.LabelsEntry)
    # Field: backup_selection_config Type: 11 (.google.cloud.backupdr.v1.BackupSelectionConfig)
    # Field: pre_restore_config Type: 11 (.google.cloud.backupdr.v1.PreRestoreConfig)
    # Field: post_restore_config Type: 11 (.google.cloud.backupdr.v1.PostRestoreConfig)
    # Field: verification_config Type: 11 (.google.cloud.backupdr.v1.VerificationConfig)
    # Field: restore_properties Type: 11 (.google.protobuf.Struct)
    # Field: state Type: 14 (.google.cloud.backupdr.v1.RestoreTemplate.State)
    # Field: execution_summary Type: 11 (.google.cloud.backupdr.v1.ExecutionSummary)
    # Field: etag Type: 9 ()

# Enum: RestoreTemplate::State
our $RestoreTemplate_STATE_UNSPECIFIED = 0;
our $RestoreTemplate_CREATING = 1;
our $RestoreTemplate_ACTIVE = 2;
our $RestoreTemplate_UPDATING = 3;
our $RestoreTemplate_DELETING = 4;

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary ===
    # Fields for ExecutionSummary
    # Field: last_execution Type: 9 ()
    # Field: last_execution_state Type: 14 (.google.cloud.backupdr.v1.RestoreTemplateExecution.ExecutionState)

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::CreateRestoreTemplateRequest ===
    # Fields for CreateRestoreTemplateRequest
    # Field: parent Type: 9 ()
    # Field: restore_template_id Type: 9 ()
    # Field: restore_template Type: 11 (.google.cloud.backupdr.v1.RestoreTemplate)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::GetRestoreTemplateRequest ===
    # Fields for GetRestoreTemplateRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::UpdateRestoreTemplateRequest ===
    # Fields for UpdateRestoreTemplateRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: restore_template Type: 11 (.google.cloud.backupdr.v1.RestoreTemplate)
    # Field: request_id Type: 9 ()
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::DeleteRestoreTemplateRequest ===
    # Fields for DeleteRestoreTemplateRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateRequest ===
    # Fields for RunRestoreTemplateRequest
    # Field: name Type: 9 ()
    # Field: backup Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateResponse ===
    # Fields for RunRestoreTemplateResponse
    # Field: restore_template_execution Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesRequest ===
    # Fields for ListRestoreTemplatesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesResponse ===
    # Fields for ListRestoreTemplatesResponse
    # Field: restore_templates Type: 11 (.google.cloud.backupdr.v1.RestoreTemplate)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreTemplate - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/restore_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::RestoreTemplate;

    my $msg = Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/restore_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate

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

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate::LabelsEntry>)

Optional. User-defined labels.

=item * C<< $msg->backup_selection_config() >> / C<< $msg->backup_selection_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig>)

Required. Backup selection configuration.

=item * C<< $msg->pre_restore_config() >> / C<< $msg->pre_restore_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig>)

Optional. Pre-restore configuration.

=item * C<< $msg->post_restore_config() >> / C<< $msg->post_restore_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig>)

Optional. Post-restore configuration.

=item * C<< $msg->verification_config() >> / C<< $msg->verification_config($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig>)

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

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::State>)

Output only. The state of the restore template.

=item * C<< $msg->execution_summary() >> / C<< $msg->execution_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary>)

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary

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

Type: C<Enum> (L<Google::Cloud::Backupdr::V1::RestoreTemplateExecution::ExecutionState>)

Output only. The state of the last execution.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::CreateRestoreTemplateRequest

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

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate>)

Required. A RestoreTemplate resource.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server will know to
ignore the request if it has already been completed.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::GetRestoreTemplateRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::UpdateRestoreTemplateRequest

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

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate>)

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::DeleteRestoreTemplateRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateResponse

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesRequest

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

=head2 Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesResponse

Response message for listing RestoreTemplates.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_templates() >> / C<< $msg->restore_templates($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::RestoreTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
