package Google::Cloud::Backupdr::V1beta::Bindingmatchingresource;

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
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2JpbmRpbmdtYXRjaGluZ3Jlc291cmNl
LnByb3RvEhxnb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJv
dG9idWYvdGltZXN0YW1wLnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byJwCiFHZXRC
aW5kaW5nTWF0Y2hpbmdSZXNvdXJjZVJlcXVlc3QSSwoEbmFtZRgBIAEoCUI34EEC+kExCi9i
YWNrdXBkci5nb29nbGVhcGlzLmNvbS9CaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZVIEbmFtZSL5
AQojTGlzdEJpbmRpbmdNYXRjaGluZ1Jlc291cmNlc1JlcXVlc3QSTwoGcGFyZW50GAEgASgJ
QjfgQQL6QTESL2JhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0JpbmRpbmdNYXRjaGluZ1Jlc291
cmNlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2Vf
dG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0
ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSK0AQokTGlzdEJpbmRpbmdNYXRj
aGluZ1Jlc291cmNlc1Jlc3BvbnNlEmQKEm1hdGNoaW5nX3Jlc291cmNlcxgBIAMoCzI1Lmdv
b2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuQmluZGluZ01hdGNoaW5nUmVzb3VyY2VSEW1h
dGNoaW5nUmVzb3VyY2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biKZBAoXQmluZGluZ01hdGNoaW5nUmVzb3VyY2USGgoEbmFtZRgBIAEoCUIG4EEI4EEDUgRu
YW1lEh8KCHJlc291cmNlGAIgASgJQgPgQQNSCHJlc291cmNlElEKFGxhc3RfZXZhbHVhdGlv
bl90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhJsYXN0RXZh
bHVhdGlvblRpbWUScAoXYXV0b19wcm90ZWN0aW9uX2RldGFpbHMYBCABKAsyMy5nb29nbGUu
Y2xvdWQuYmFja3VwZHIudjFiZXRhLkF1dG9Qcm90ZWN0aW9uRGV0YWlsc0ID4EEDUhVhdXRv
UHJvdGVjdGlvbkRldGFpbHM6+wHqQfcBCi9iYWNrdXBkci5nb29nbGVhcGlzLmNvbS9CaW5k
aW5nTWF0Y2hpbmdSZXNvdXJjZRKQAXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hdXRvUHJvdGVjdGlvblBvbGljaWVzL3thdXRvX3Byb3RlY3Rpb25fcG9saWN5
fS9iaW5kaW5ncy97YmluZGluZ30vbWF0Y2hpbmdSZXNvdXJjZXMve21hdGNoaW5nX3Jlc291
cmNlfSoYYmluZGluZ01hdGNoaW5nUmVzb3VyY2VzMhdiaW5kaW5nTWF0Y2hpbmdSZXNvdXJj
ZSLJAwoVQXV0b1Byb3RlY3Rpb25EZXRhaWxzElQKBXN0YXRlGAEgASgOMjkuZ29vZ2xlLmNs
b3VkLmJhY2t1cGRyLnYxYmV0YS5BdXRvUHJvdGVjdGlvbkRldGFpbHMuU3RhdGVCA+BBA1IF
c3RhdGUSbQoXYmFja3VwX3BsYW5fYXNzb2NpYXRpb24YAiABKAlCNeBBA/pBLwotYmFja3Vw
ZHIuZ29vZ2xlYXBpcy5jb20vQmFja3VwUGxhbkFzc29jaWF0aW9uUhViYWNrdXBQbGFuQXNz
b2NpYXRpb24SSwoLZGF0YV9zb3VyY2UYAyABKAlCKuBBA/pBJAoiYmFja3VwZHIuZ29vZ2xl
YXBpcy5jb20vRGF0YVNvdXJjZVIKZGF0YVNvdXJjZRItCgVlcnJvchgEIAEoCzISLmdvb2ds
ZS5ycGMuU3RhdHVzQgPgQQNSBWVycm9yIm8KBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVE
EAASDQoJUFJPVEVDVEVEEAESFQoRUFJPVEVDVElPTl9GQUlMRUQQAhIQCgxVTlBST1RFQ1RJ
TkcQAxIXChNVTlBST1RFQ1RJT05fRkFJTEVEEARC4AEKIGNvbS5nb29nbGUuY2xvdWQuYmFj
a3VwZHIudjFiZXRhQhxCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZVByb3RvUAFaPGNsb3VkLmdv
b2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjFiZXRhL2JhY2t1cGRycGI7YmFja3VwZHJwYqoC
HEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMUJldGHKAhxHb29nbGVcQ2xvdWRcQmFja3VwRFJc
VjFiZXRh6gIfR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYxYmV0YUrrMgoHEgUOALQBAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgAp
CgkKAgMBEgMTACMKCQoCAwISAxQAKQoJCgIDAxIDFQAhCggKAQgSAxcAOQoJCgIIJRIDFwA5
CggKAQgSAxgAUwoJCgIICxIDGABTCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAPQoJ
CgIICBIDGgA9CggKAQgSAxsAOQoJCgIIARIDGwA5CggKAQgSAxwAOQoJCgIIKRIDHAA5CggK
AQgSAx0AOAoJCgIILRIDHQA4CkQKAgQAEgQgACoBGjggUmVxdWVzdCBtZXNzYWdlIGZvciBn
ZXR0aW5nIGEgQmluZGluZ01hdGNoaW5nUmVzb3VyY2UuCgoKCgMEAAESAyAIKQrkAQoEBAAC
ABIEJAIpBBrVASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1hdGNoaW5nIHJlc291cmNl
IHRvIHJldHJpZXZlLgogRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xp
Y3l9L2JpbmRpbmdzL3tiaW5kaW5nfS9tYXRjaGluZ1Jlc291cmNlcy97bWF0Y2hpbmdfcmVz
b3VyY2V9CgoMCgUEAAIABRIDJAIICgwKBQQAAgABEgMkCQ0KDAoFBAACAAMSAyQQEQoNCgUE
AAIACBIEJBIpAwoPCggEAAIACJwIABIDJQQqCg8KBwQAAgAInwgSBCYEKAUKQAoCBAESBC0A
TwEaNCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIExpc3QgQmluZGluZ01hdGNoaW5nUmVzb3VyY2Vz
LgoKCgoDBAEBEgMtCCsK7wIKBAQBAgASBDMCOAQa4AIgUmVxdWlyZWQuIFRoZSBwcm9qZWN0
LCBsb2NhdGlvbiwgYXV0byBwcm90ZWN0aW9uIHBvbGljeSBhbmQgYmluZGluZyBmb3IKIHdo
aWNoIHRvIHJldHJpZXZlIGBCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZXNgIGluZm9ybWF0aW9u
LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1
dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1dG9fcHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdz
L3tiaW5kaW5nfWAuCiBJbiBHb29nbGUgQ2xvdWQgQmFja3VwIGFuZCBEUiwgbG9jYXRpb25z
IG1hcCB0byBHb29nbGUgQ2xvdWQgcmVnaW9ucywgZm9yCiBleGFtcGxlICoqdXMtY2VudHJh
bDEqKi4KCgwKBQQBAgAFEgMzAggKDAoFBAECAAESAzMJDwoMCgUEAQIAAxIDMxITCg0KBQQB
AgAIEgQzFDgDCg8KCAQBAgAInAgAEgM0BCoKDwoHBAECAAifCBIENQQ3BQquAwoEBAECARID
QAI/GqADIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYEJpbmRpbmdNYXRjaGlu
Z1Jlc291cmNlc2AgdG8gcmV0dXJuIGluIGEKIHNpbmdsZSByZXNwb25zZS4gVGhlIGRlZmF1
bHQgcGFnZSBzaXplIGlzIDEwMCBhbmQgbWF4aW11bSBwYWdlIHNpemUgaXMgMjAwLgogTm90
ZSB0aGF0IHRoZSByZXNwb25zZSBtYXkgaW5jbHVkZSBhIHBhcnRpYWwgbGlzdCBhbmQgYSBj
YWxsZXIgc2hvdWxkCiBvbmx5IHJlbHkgb24gdGhlIHJlc3BvbnNlJ3MKIFtuZXh0X3BhZ2Vf
dG9rZW5dW2dvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGEuTGlzdEJpbmRpbmdNYXRjaGlu
Z1Jlc291cmNlc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0KIHRvIGRldGVybWluZSBpZiB0
aGVyZSBhcmUgbW9yZSBpbnN0YW5jZXMgbGVmdCB0byBiZSBxdWVyaWVkLgoKDAoFBAECAQUS
A0ACBwoMCgUEAQIBARIDQAgRCgwKBQQBAgEDEgNAFBUKDAoFBAECAQgSA0AWPgoPCggEAQIB
CJwIABIDQBc9Cp8DCgQEAQICEgNIAkEakQMgT3B0aW9uYWwuIFRoZSB2YWx1ZSBvZgogW25l
eHRfcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5MaXN0QmluZGlu
Z01hdGNoaW5nUmVzb3VyY2VzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXQogcmVjZWl2ZWQg
ZnJvbSBhIHByZXZpb3VzIGBMaXN0QmluZGluZ01hdGNoaW5nUmVzb3VyY2VzYCBjYWxsLiBQ
cm92aWRlIHRoaXMKIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UgaW4gYSBtdWx0
aS1wYWdlIGxpc3Qgb2YgcmVzdWx0cy4gV2hlbgogcGFnaW5hdGluZywgYWxsIG90aGVyIHBh
cmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZXNgCiBt
dXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoMCgUE
AQICBRIDSAIICgwKBQQBAgIBEgNICRMKDAoFBAECAgMSA0gWFwoMCgUEAQICCBIDSBhACg8K
CAQBAgIInAgAEgNIGT8KSwoEBAECAxIDSwI9Gj4gT3B0aW9uYWwuIEZpZWxkIG1hdGNoIGV4
cHJlc3Npb24gdXNlZCB0byBmaWx0ZXIgdGhlIHJlc3VsdHMuCgoMCgUEAQIDBRIDSwIICgwK
BQQBAgMBEgNLCQ8KDAoFBAECAwMSA0sSEwoMCgUEAQIDCBIDSxQ8Cg8KCAQBAgMInAgAEgNL
FTsKPAoEBAECBBIDTgI/Gi8gT3B0aW9uYWwuIEZpZWxkIGJ5IHdoaWNoIHRvIHNvcnQgdGhl
IHJlc3VsdHMuCgoMCgUEAQIEBRIDTgIICgwKBQQBAgQBEgNOCREKDAoFBAECBAMSA04UFQoM
CgUEAQIECBIDThY+Cg8KCAQBAgQInAgAEgNOFz0KVAoCBAISBFIAXQEaSCBUaGUgcmVzcG9u
c2UgbWVzc2FnZSBmb3IgZ2V0dGluZyBhIGxpc3Qgb2YgYEJpbmRpbmdNYXRjaGluZ1Jlc291
cmNlc2AuCgoKCgMEAgESA1IILAppCgQEAgIAEgNVAjoaXCBUaGUgbGlzdCBvZiBgQmluZGlu
Z01hdGNoaW5nUmVzb3VyY2VzYCBpbiB0aGUgcHJvamVjdCxsb2NhdGlvbiBmb3IgdGhlCiBz
cGVjaWZpZWQgYmluZGluZy4KCgwKBQQCAgAEEgNVAgoKDAoFBAICAAYSA1ULIgoMCgUEAgIA
ARIDVSM1CgwKBQQCAgADEgNVODkKsQIKBAQCAgESA1wCHRqjAiBBIHRva2VuIHdoaWNoIG1h
eSBiZSBzZW50IGFzCiBbcGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0
YS5MaXN0QmluZGluZ01hdGNoaW5nUmVzb3VyY2VzUmVxdWVzdC5wYWdlX3Rva2VuXQogaW4g
YSBzdWJzZXF1ZW50IGBMaXN0QmluZGluZ01hdGNoaW5nUmVzb3VyY2VzYCBjYWxsIHRvIHJl
dHJpZXZlIHRoZSBuZXh0CiBwYWdlIG9mIHJlc3VsdHMuIElmIHRoaXMgZmllbGQgaXMgb21p
dHRlZCBvciBlbXB0eSwgdGhlbiB0aGVyZSBhcmUgbm8gbW9yZQogcmVzdWx0cyB0byByZXR1
cm4uCgoMCgUEAgIBBRIDXAIICgwKBQQCAgEBEgNcCRgKDAoFBAICAQMSA1wbHApyCgIEAxIF
YQCDAQEaZSBCaW5kaW5nTWF0Y2hpbmdSZXNvdXJjZSBjb250YWlucyB0aGUgZGV0YWlscyBv
ZiBhIHJlc291cmNlIHRoYXQgbWF0Y2hlcyB0aGUKIGNyaXRlcmlhIG9mIGEgYmluZGluZy4K
CgoKAwQDARIDYQgfCgsKAwQDBxIEYgJnBAoNCgUEAwedCBIEYgJnBAr6AQoEBAMCABIEbAJv
BBrrASBPdXRwdXQgb25seS4gSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
CiBgQmluZGluZ01hdGNoaW5nUmVzb3VyY2VgLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2F1dG9Qcm90ZWN0aW9uUG9saWNpZXMve2F1dG9f
cHJvdGVjdGlvbl9wb2xpY3l9L2JpbmRpbmdzL3tiaW5kaW5nfS9tYXRjaGluZ1Jlc291cmNl
cy97bWF0Y2hpbmdfcmVzb3VyY2V9YAoKDAoFBAMCAAUSA2wCCAoMCgUEAwIAARIDbAkNCgwK
BQQDAgADEgNsEBEKDQoFBAMCAAgSBGwSbwMKDwoIBAMCAAicCAASA20ELAoPCggEAwIACJwI
ARIDbgQtCukCCgQEAwIBEgN4AkIa2wIgT3V0cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2Yg
dGhlIHdvcmtsb2FkIHRoYXQgbWF0Y2hlcyB0aGUgY3JpdGVyaWEgb2YgdGhlCiBiaW5kaW5n
LgoKIFRoZSBmb3JtYXQgY2FuIGJlIGVpdGhlciBhIHJlbGF0aXZlIHJlc291cmNlIG5hbWUg
KGUuZy4sCiBgcHJvamVjdHMvbXktcHJvamVjdC96b25lcy91cy1jZW50cmFsMS1hL2luc3Rh
bmNlcy9teS1pbnN0YW5jZWApIG9yIGEKIHNjaGVtZWxlc3MgZnVsbCByZXNvdXJjZSBuYW1l
IChlLmcuLAogYC8vY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy9teS1wcm9qZWN0
L3pvbmVzL3VzLWNlbnRyYWwxLWEvaW5zdGFuY2VzL215LWluc3RhbmNlYCkuCgoMCgUEAwIB
BRIDeAIICgwKBQQDAgEBEgN4CREKDAoFBAMCAQMSA3gUFQoMCgUEAwIBCBIDeBZBCg8KCAQD
AgEInAgAEgN4F0AKYAoEBAMCAhIEfAJ9MhpSIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1w
IHdoZW4gdGhlIHJlc291cmNlIHdhcyBsYXN0IGV2YWx1YXRlZCBmb3IKIHByb3RlY3Rpb24u
CgoMCgUEAwICBhIDfAIbCgwKBQQDAgIBEgN8HDAKDAoFBAMCAgMSA3wzNAoMCgUEAwICCBID
fQYxCg8KCAQDAgIInAgAEgN9BzAKcwoEBAMCAxIGgQECggEyGmMgT3V0cHV0IG9ubHkuIFRo
ZSBhdXRvIHByb3RlY3Rpb24gZGV0YWlscyBvZiB0aGUgcmVzb3VyY2UgZnJvbSB0aGUgY3Vy
cmVudAogYmluZGluZydzIHBlcnNwZWN0aXZlLgoKDQoFBAMCAwYSBIEBAhcKDQoFBAMCAwES
BIEBGC8KDQoFBAMCAwMSBIEBMjMKDQoFBAMCAwgSBIIBBjEKEAoIBAMCAwicCAASBIIBBzAK
fAoCBAQSBocBALQBARpuIEF1dG9Qcm90ZWN0aW9uRGV0YWlscyBjb250YWlucyB0aGUgcHJv
dGVjdGlvbiBkZXRhaWxzIG9mIGEgcmVzb3VyY2UgZnJvbSB0aGUKIGN1cnJlbnQgYmluZGlu
ZydzIHBlcnNwZWN0aXZlLgoKCwoDBAQBEgSHAQgdCjwKBAQEBAASBokBApgBAxosIEVudW0g
Zm9yIHByb3RlY3Rpb24gc3RhdGUgb2YgdGhlIHJlc291cmNlLgoKDQoFBAQEAAESBIkBBwwK
JAoGBAQEAAIAEgSLAQQaGhQgU3RhdGUgdW5zcGVjaWZpZWQuCgoPCgcEBAQAAgABEgSLAQQV
Cg8KBwQEBAACAAISBIsBGBkKKAoGBAQEAAIBEgSOAQQSGhggUmVzb3VyY2UgaXMgcHJvdGVj
dGVkLgoKDwoHBAQEAAIBARIEjgEEDQoPCgcEBAQAAgECEgSOARARCi0KBgQEBAACAhIEkQEE
GhodIFJlc291cmNlIHByb3RlY3Rpb24gZmFpbGVkLgoKDwoHBAQEAAICARIEkQEEFQoPCgcE
BAQAAgICEgSRARgZCjAKBgQEBAACAxIElAEEFRogIFJlc291cmNlIGlzIGJlaW5nIHVucHJv
dGVjdGVkLgoKDwoHBAQEAAIDARIElAEEEAoPCgcEBAQAAgMCEgSUARMUCi8KBgQEBAACBBIE
lwEEHBofIFJlc291cmNlIHVucHJvdGVjdGlvbiBmYWlsZWQuCgoPCgcEBAQAAgQBEgSXAQQX
Cg8KBwQEBAACBAISBJcBGhsKcwoEBAQCABIEnAECPhplIE91dHB1dCBvbmx5LiBQcm90ZWN0
aW9uIHN0YXRlIG9mIHRoZSByZXNvdXJjZSBmcm9tIHRoZSBjdXJyZW50IGJpbmRpbmcncwog
cGVyc3BlY3RpdmUuIE91dHB1dCBvbmx5LgoKDQoFBAQCAAYSBJwBAgcKDQoFBAQCAAESBJwB
CA0KDQoFBAQCAAMSBJwBEBEKDQoFBAQCAAgSBJwBEj0KEAoIBAQCAAicCAASBJwBEzwKywEK
BAQEAgESBqEBAqYBBBq6ASBPdXRwdXQgb25seS4gUmVzb3VyY2UgbmFtZSBvZiBiYWNrdXAg
cGxhbiBhc3NvY2lhdGlvbiBsaW5rZWQgdG8gdGhlCiByZXNvdXJjZSwgaWYgYW55LiBGb3Jt
YXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYmFja3VwUGxh
bkFzc29jaWF0aW9ucy97YmFja3VwUGxhbkFzc29jaWF0aW9uSWR9CgoNCgUEBAIBBRIEoQEC
CAoNCgUEBAIBARIEoQEJIAoNCgUEBAIBAxIEoQEjJAoPCgUEBAIBCBIGoQElpgEDChAKCAQE
AgEInAgAEgSiAQQtChEKBwQEAgEInwgSBqMBBKUBBQrJAQoEBAQCAhIGqwECsAEEGrgBIE91
dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBkYXRhc291cmNlIGxpbmtlZCB0byB0
aGUgcmVzb3VyY2UsIGlmCiBhbnkuIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9iYWNrdXBWYXVsdHMve2JhY2t1cFZhdWx0SWR9L2RhdGFTb3Vy
Y2VzL3tkYXRhU291cmNlSWR9CgoNCgUEBAICBRIEqwECCAoNCgUEBAICARIEqwEJFAoNCgUE
BAICAxIEqwEXGAoPCgUEBAICCBIGqwEZsAEDChAKCAQEAgIInAgAEgSsAQQtChEKBwQEAgII
nwgSBq0BBK8BBQpYCgQEBAIDEgSzAQJKGkogT3V0cHV0IG9ubHkuIEVycm9yIGR1cmluZyBs
YXN0IHN5bmMgZm9yIHByb3RlY3Rpb24vdW5wcm90ZWN0aW9uLCBpZiBhbnkuCgoNCgUEBAID
BhIEswECEwoNCgUEBAIDARIEswEUGQoNCgUEBAIDAxIEswEcHQoNCgUEBAIDCBIEswEeSQoQ
CggEBAIDCJwIABIEswEfSGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest ===
    # Fields for GetBindingMatchingResourceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesRequest ===
    # Fields for ListBindingMatchingResourcesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesResponse ===
    # Fields for ListBindingMatchingResourcesResponse
    # Field: matching_resources Type: 11 (.google.cloud.backupdr.v1beta.BindingMatchingResource)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource ===
    # Fields for BindingMatchingResource
    # Field: name Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: last_evaluation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: auto_protection_details Type: 11 (.google.cloud.backupdr.v1beta.AutoProtectionDetails)

# === Message: Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails ===
    # Fields for AutoProtectionDetails
    # Field: state Type: 14 (.google.cloud.backupdr.v1beta.AutoProtectionDetails.State)
    # Field: backup_plan_association Type: 9 ()
    # Field: data_source Type: 9 ()
    # Field: error Type: 11 (.google.rpc.Status)

# Enum: AutoProtectionDetails::State
our $AutoProtectionDetails_STATE_UNSPECIFIED = 0;
our $AutoProtectionDetails_PROTECTED = 1;
our $AutoProtectionDetails_PROTECTION_FAILED = 2;
our $AutoProtectionDetails_UNPROTECTING = 3;
our $AutoProtectionDetails_UNPROTECTION_FAILED = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::Bindingmatchingresource - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/bindingmatchingresource.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::Bindingmatchingresource;

    my $msg = Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/bindingmatchingresource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::GetBindingMatchingResourceRequest

Request message for getting a BindingMatchingResource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the matching resource to retrieve.
Format:
projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}/matchingResources/{matching_resource}

=back

=head2 Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesRequest

Request message for List BindingMatchingResources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project, location, auto protection policy and binding for
which to retrieve `BindingMatchingResources` information. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}`.
In Google Cloud Backup and DR, locations map to Google Cloud regions, for
example B<us-central1>.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of `BindingMatchingResources` to return in a
single response. The default page size is 100 and maximum page size is 200.
Note that the response may include a partial list and a caller should
only rely on the response's
[next_page_token][google.cloud.backupdr.v1beta.ListBindingMatchingResourcesResponse.next_page_token]
to determine if there are more instances left to be queried.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The value of
[next_page_token][google.cloud.backupdr.v1beta.ListBindingMatchingResourcesResponse.next_page_token]
received from a previous `ListBindingMatchingResources` call. Provide this
to retrieve the subsequent page in a multi-page list of results. When
paginating, all other parameters provided to `ListBindingMatchingResources`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Field match expression used to filter the results.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Field by which to sort the results.

=back

=head2 Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::ListBindingMatchingResourcesResponse

The response message for getting a list of `BindingMatchingResources`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->matching_resources() >> / C<< $msg->matching_resources($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource>)

The list of `BindingMatchingResources` in the project,location for the
specified binding.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token which may be sent as
[page_token][google.cloud.backupdr.v1beta.ListBindingMatchingResourcesRequest.page_token]
in a subsequent `ListBindingMatchingResources` call to retrieve the next
page of results. If this field is omitted or empty, then there are no more
results to return.

=back

=head2 Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::BindingMatchingResource

BindingMatchingResource contains the details of a resource that matches the
criteria of a binding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Identifier. The resource name of the
`BindingMatchingResource`. Format:
`projects/{project}/locations/{location}/autoProtectionPolicies/{auto_protection_policy}/bindings/{binding}/matchingResources/{matching_resource}`

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Output only. Resource name of the workload that matches the criteria of the
binding.

The format can be either a relative resource name (e.g.,
`projects/my-project/zones/us-central1-a/instances/my-instance`) or a
schemeless full resource name (e.g.,
`//compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/my-instance`).

=item * C<< $msg->last_evaluation_time() >> / C<< $msg->last_evaluation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was last evaluated for
protection.

=item * C<< $msg->auto_protection_details() >> / C<< $msg->auto_protection_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails>)

Output only. The auto protection details of the resource from the current
binding's perspective.

=back

=head2 Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::AutoProtectionDetails

AutoProtectionDetails contains the protection details of a resource from the
current binding's perspective.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::AutoProtectionDetails::State>)

Output only. Protection state of the resource from the current binding's
perspective. Output only.

=item * C<< $msg->backup_plan_association() >> / C<< $msg->backup_plan_association($value) >>

Type: C<String>

Output only. Resource name of backup plan association linked to the
resource, if any. Format:
projects/{project}/locations/{location}/backupPlanAssociations/{backupPlanAssociationId}

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Output only. Resource name of the datasource linked to the resource, if
any. Format:
projects/{project}/locations/{location}/backupVaults/{backupVaultId}/dataSources/{dataSourceId}

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

Output only. Error during last sync for protection/unprotection, if any.

=back

=head3 Enum: AutoProtectionDetails::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROTECTED> => C<1>

=item * C<PROTECTION_FAILED> => C<2>

=item * C<UNPROTECTING> => C<3>

=item * C<UNPROTECTION_FAILED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::Bindingmatchingresource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
