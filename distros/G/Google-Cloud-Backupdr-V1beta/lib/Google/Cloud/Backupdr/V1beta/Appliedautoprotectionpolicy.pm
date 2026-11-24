package Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy;

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
    eval { require Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy };
    eval { require Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2FwcGxpZWRhdXRvcHJvdGVjdGlvbnBv
bGljeS5wcm90bxIcZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo3Z29vZ2xl
L2Nsb3VkL2JhY2t1cGRyL3YxYmV0YS9hdXRvcHJvdGVjdGlvbnBvbGljeS5wcm90bxo+Z29v
Z2xlL2Nsb3VkL2JhY2t1cGRyL3YxYmV0YS9hdXRvcHJvdGVjdGlvbnBvbGljeWJpbmRpbmcu
cHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i1wcKG0FwcGxpZWRBdXRv
UHJvdGVjdGlvblBvbGljeRIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSYgoOc291cmNlX2Jp
bmRpbmcYAiABKAlCO+BBA/pBNQozYmFja3VwZHIuZ29vZ2xlYXBpcy5jb20vQXV0b1Byb3Rl
Y3Rpb25Qb2xpY3lCaW5kaW5nUg1zb3VyY2VCaW5kaW5nEkcKCGNyaXRlcmlhGAMgASgLMiYu
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5Dcml0ZXJpYUID4EEDUghjcml0ZXJpYRJj
ChNiYWNrdXBfcGxhbl9kZXRhaWxzGAQgAygLMi4uZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYx
YmV0YS5CYWNrdXBQbGFuRGV0YWlsQgPgQQNSEWJhY2t1cFBsYW5EZXRhaWxzEkAKC3VwZGF0
ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEnkKGmJpbmRpbmdfZXZhbHVhdGlvbl9zdW1tYXJ5GAcgASgLMjYu
Z29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5CaW5kaW5nRXZhbHVhdGlvblN1bW1hcnlC
A+BBA1IYYmluZGluZ0V2YWx1YXRpb25TdW1tYXJ5ElwKBnN0YXR1cxgIIAEoDjI/Lmdvb2ds
ZS5jbG91ZC5iYWNrdXBkci52MWJldGEuQXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWN5LlN0
YXRlQgPgQQNSBnN0YXR1cyJQCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENS
RUFUSU5HEAESCgoGQUNUSVZFEAISFgoSREVMRVRJT05fSU5JVElBVEVEEAM63QHqQdkBCjNi
YWNrdXBkci5nb29nbGVhcGlzLmNvbS9BcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xpY3kSZnBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBsaWVkQXV0b1Byb3Rl
Y3Rpb25Qb2xpY2llcy97YXBwbGllZF9hdXRvX3Byb3RlY3Rpb25fcG9saWN5fSodYXBwbGll
ZEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMyG2FwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljeSLw
AQooTGlzdEFwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljaWVzUmVxdWVzdBJBCgZwYXJlbnQY
ASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJl
bnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyAB
KAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoIb3Jk
ZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSL/AQopTGlzdEFwcGxpZWRBdXRvUHJvdGVjdGlv
blBvbGljaWVzUmVzcG9uc2USggEKIGFwcGxpZWRfYXV0b19wcm90ZWN0aW9uX3BvbGljaWVz
GAEgAygLMjkuZ29vZ2xlLmNsb3VkLmJhY2t1cGRyLnYxYmV0YS5BcHBsaWVkQXV0b1Byb3Rl
Y3Rpb25Qb2xpY3lSHWFwcGxpZWRBdXRvUHJvdGVjdGlvblBvbGljaWVzEiYKD25leHRfcGFn
ZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIlCgt1bnJlYWNoYWJsZRgDIAMoCUID4EEG
Ugt1bnJlYWNoYWJsZULkAQogY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCIEFw
cGxpZWRBdXRvUHJvdGVjdGlvblBvbGljeVByb3RvUAFaPGNsb3VkLmdvb2dsZS5jb20vZ28v
YmFja3VwZHIvYXBpdjFiZXRhL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCHEdvb2dsZS5DbG91
ZC5CYWNrdXBEUi5WMUJldGHKAhxHb29nbGVcQ2xvdWRcQmFja3VwRFJcVjFiZXRh6gIfR29v
Z2xlOjpDbG91ZDo6QmFja3VwRFI6OlYxYmV0YUqHJQoHEgUOAIoBAQq8BAoBDBIDDgASMrEE
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
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAQQoJCgIDAxIDFQBICgkKAgMEEgMWACkKCAoBCBIDGAA5CgkKAgglEgMYADkK
CAoBCBIDGQBTCgkKAggLEgMZAFMKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwBBCgkK
AggIEgMbAEEKCAoBCBIDHAA5CgkKAggBEgMcADkKCAoBCBIDHQA5CgkKAggpEgMdADkKCAoB
CBIDHgA4CgkKAggtEgMeADgKqgEKAgQAEgQjAGIBGp0BIEFwcGxpZWRBdXRvUHJvdGVjdGlv
blBvbGljeSBpcyBhIHJlYWQtb25seSB2aWV3IG9mIEF1dG9Qcm90ZWN0aW9uUG9saWN5CiBh
bmQgQXV0b1Byb3RlY3Rpb25Qb2xpY3lCaW5kaW5nIHJlc291cmNlcyB0aGF0IGFwcGx5IHRv
IGEgZ2l2ZW4gd29ya2xvYWQKIHByb2plY3QuCgoKCgMEAAESAyMIIwoLCgMEAAcSBCQCKQQK
DQoFBAAHnQgSBCQCKQQKWgoEBAAEABIELAI4AxpMIFJlcHJlc2VudHMgdGhlIHZhcmlvdXMg
c3RhdGVzIGFuIGFwcGxpZWQgYXV0byBwcm90ZWN0aW9uIHBvbGljeSBjYW4gYmUgaW4uCgoM
CgUEAAQAARIDLAcMCigKBgQABAACABIDLgQaGhkgU3RhdGUgaXMgbm90IHNwZWNpZmllZC4K
Cg4KBwQABAACAAESAy4EFQoOCgcEAAQAAgACEgMuGBkKPwoGBAAEAAIBEgMxBBEaMCBUaGUg
cG9saWN5IGlzIGluIHRoZSBwcm9jZXNzIG9mIGJlaW5nIGFwcGxpZWQuCgoOCgcEAAQAAgEB
EgMxBAwKDgoHBAAEAAIBAhIDMQ8QCjsKBgQABAACAhIDNAQPGiwgVGhlIHBvbGljeSBoYXMg
YmVlbiBhcHBsaWVkIGFuZCBpcyBhY3RpdmUuCgoOCgcEAAQAAgIBEgM0BAoKDgoHBAAEAAIC
AhIDNA0OCj8KBgQABAACAxIDNwQbGjAgVGhlIHBvbGljeSBpcyBpbiB0aGUgcHJvY2VzcyBv
ZiBiZWluZyByZW1vdmVkLgoKDgoHBAAEAAIDARIDNwQWCg4KBwQABAACAwISAzcZGgqaAQoE
BAACABIDPQI9GowBIElkZW50aWZpZXIuIENhbm9uaWNhbCByZXNvdXJjZSBuYW1lLgogRm9y
bWF0OgogcHJvamVjdHMve3dvcmtsb2FkLXByb2plY3QtbnVtYmVyfS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hcHBsaWVkQXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97aWR9LgoKDAoFBAACAAUS
Az0CCAoMCgUEAAIAARIDPQkNCgwKBQQAAgADEgM9EBEKDAoFBAACAAgSAz0SPAoPCggEAAIA
CJwIABIDPRM7CqYCCgQEAAIBEgRCAkcEGpcCIE91dHB1dCBvbmx5LiBUaGUgZnVsbCByZXNv
dXJjZSBuYW1lIG9mIHRoZSBBdXRvUHJvdGVjdGlvblBvbGljeUJpbmRpbmcgdGhhdAogYXBw
bGllcyB0aGUgc291cmNlIHBvbGljeSB0byBhIHNjb3BlIGluY2x1ZGluZyB0aGlzIHdvcmts
b2FkIHByb2plY3QuIGUuZy4sCiBwcm9qZWN0cy97YWRtaW4tcHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vYXV0b1Byb3RlY3Rpb25Qb2xpY2llcy97cG9saWN5X2lkfS9hdXRvUHJv
dGVjdGlvblBvbGljeUJpbmRpbmdzL3tiaW5kaW5nX2lkfS4KCgwKBQQAAgEFEgNCAggKDAoF
BAACAQESA0IJFwoMCgUEAAIBAxIDQhobCg0KBQQAAgEIEgRCHEcDCg8KCAQAAgEInAgAEgND
BC0KDwoHBAACAQifCBIERARGBQp5CgQEAAICEgNLAkQabCBPdXRwdXQgb25seS4gVGhlIGNy
aXRlcmlhIHJlc291cmNlcyBtdXN0IG1lZXQgZm9yIHRoaXMgcnVsZSB0byBhcHBseS4gRnJv
bQogQXV0b1Byb3RlY3Rpb25Qb2xpY3kuY3JpdGVyaWEuCgoMCgUEAAICBhIDSwIKCgwKBQQA
AgIBEgNLCxMKDAoFBAACAgMSA0sWFwoMCgUEAAICCBIDSxhDCg8KCAQAAgIInAgAEgNLGUIK
zgEKBAQAAgMSBFACUTIavwEgT3V0cHV0IG9ubHkuIFRoZSBzZXQgb2YgYmFja3VwIHBsYW4g
Y29uZmlndXJhdGlvbnMsIG1pcnJvcmluZyB0aGUKIGJhY2t1cF9wbGFuX2RldGFpbHMgZnJv
bSB0aGUgc291cmNlIEF1dG9Qcm90ZWN0aW9uUG9saWN5LiBFYWNoIGVsZW1lbnQKIHNwZWNp
ZmllcyBhIGJhY2t1cCBwbGFuIGZvciBhIGdpdmVuIHJlc291cmNlIHR5cGUuCgoMCgUEAAID
BBIDUAIKCgwKBQQAAgMGEgNQCxsKDAoFBAACAwESA1AcLwoMCgUEAAIDAxIDUDIzCgwKBQQA
AgMIEgNRBjEKDwoIBAACAwicCAASA1EHMApVCgQEAAIEEgRUAlUyGkcgT3V0cHV0IG9ubHku
IFRpbWVzdGFtcCBpbmRpY2F0aW5nIHdoZW4gdGhlIGJpbmRpbmcgd2FzIGxhc3QgbW9kaWZp
ZWQuCgoMCgUEAAIEBhIDVAIbCgwKBQQAAgQBEgNUHCcKDAoFBAACBAMSA1QqKwoMCgUEAAIE
CBIDVQYxCg8KCAQAAgQInAgAEgNVBzAKVAoEBAACBRIEWAJZMhpGIE91dHB1dCBvbmx5LiBU
aW1lc3RhbXAgaW5kaWNhdGluZyB3aGVuIHRoZSBiaW5kaW5nIHdhcyBsYXN0IGNyZWF0ZWQu
CgoMCgUEAAIFBhIDWAIbCgwKBQQAAgUBEgNYHCcKDAoFBAACBQMSA1gqKwoMCgUEAAIFCBID
WQYxCg8KCAQAAgUInAgAEgNZBzAKXgoEBAACBhIEXQJeMhpQIE91dHB1dCBvbmx5LiBUaGUg
c3VtbWFyeSBvZiB0aGUgbGFzdCBwb2xpY3kgYXBwbGljYXRpb24gd2hlbiB0aGUgam9iIGhh
cwogcnVuLgoKDAoFBAACBgYSA10CGgoMCgUEAAIGARIDXRs1CgwKBQQAAgYDEgNdODkKDAoF
BAACBggSA14GMQoPCggEAAIGCJwIABIDXgcwCk0KBAQAAgcSA2ECPxpAIE91dHB1dCBvbmx5
LiBUaGUgc3RhdHVzIG9mIHRoZSBhcHBsaWVkIGF1dG8gcHJvdGVjdGlvbiBwb2xpY3kuCgoM
CgUEAAIHBhIDYQIHCgwKBQQAAgcBEgNhCA4KDAoFBAACBwMSA2EREgoMCgUEAAIHCBIDYRM+
Cg8KCAQAAgcInAgAEgNhFD0KSAoCBAESBGUAfQEaPCBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGxp
c3RpbmcgQXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWNpZXMuCgoKCgMEAQESA2UIMAqYAQoE
BAECABIEaAJtBBqJASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGZvciB3
aGljaCB0byByZXRyaWV2ZSB0aGUgbGlzdCBvZgogYXBwbGllZCBwb2xpY2llcy4gRm9ybWF0
OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQBAgAFEgNo
AggKDAoFBAECAAESA2gJDwoMCgUEAQIAAxIDaBITCg0KBQQBAgAIEgRoFG0DCg8KCAQBAgAI
nAgAEgNpBCoKDwoHBAECAAifCBIEagRsBQpcCgQEAQIBEgNxAj8aTyBPcHRpb25hbC4gVGhl
IG1heGltdW0gbnVtYmVyIG9mIGFwcGxpZWQgcG9saWNpZXMgdG8gcmV0dXJuIGluIGEgc2lu
Z2xlCiBwYWdlLgoKDAoFBAECAQUSA3ECBwoMCgUEAQIBARIDcQgRCgwKBQQBAgEDEgNxFBUK
DAoFBAECAQgSA3EWPgoPCggEAQIBCJwIABIDcRc9CmoKBAQBAgISA3UCQRpdIE9wdGlvbmFs
LiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogYExpc3RBcHBsaWVk
QXV0b1Byb3RlY3Rpb25Qb2xpY2llc2AgY2FsbC4KCgwKBQQBAgIFEgN1AggKDAoFBAECAgES
A3UJEwoMCgUEAQICAxIDdRYXCgwKBQQBAgIIEgN1GEAKDwoIBAECAgicCAASA3UZPwpcCgQE
AQIDEgN5Aj0aTyBPcHRpb25hbC4gQSBmaWx0ZXIgZXhwcmVzc2lvbiB0aGF0IGZpbHRlcnMg
cmVzb3VyY2VzIGxpc3RlZCBpbiB0aGUKIHJlc3BvbnNlLgoKDAoFBAECAwUSA3kCCAoMCgUE
AQIDARIDeQkPCgwKBQQBAgMDEgN5EhMKDAoFBAECAwgSA3kUPAoPCggEAQIDCJwIABIDeRU7
Ck4KBAQBAgQSA3wCPxpBIE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIHRoYXQgc29ydHMgdGhl
IHJlc3VsdHMgaW4gdGhlIHJlc3BvbnNlLgoKDAoFBAECBAUSA3wCCAoMCgUEAQIEARIDfAkR
CgwKBQQBAgQDEgN8FBUKDAoFBAECBAgSA3wWPgoPCggEAQIECJwIABIDfBc9CkcKAgQCEgaA
AQCKAQEaOSBSZXNwb25zZSBtZXNzYWdlIGZvciBMaXN0QXBwbGllZEF1dG9Qcm90ZWN0aW9u
UG9saWNpZXMuCgoLCgMEAgESBIABCDEKSgoEBAICABIEggECTBo8IEEgbGlzdCBvZiB0aGUg
QXBwbGllZEF1dG9Qcm90ZWN0aW9uUG9saWN5IHJlc291cmNlcyBmb3VuZC4KCg0KBQQCAgAE
EgSCAQIKCg0KBQQCAgAGEgSCAQsmCg0KBQQCAgABEgSCASdHCg0KBQQCAgADEgSCAUpLClMK
BAQCAgESBIUBAh0aRSBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5g
IHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCgoNCgUEAgIBBRIEhQECCAoNCgUEAgIBARIE
hQEJGAoNCgUEAgIBAxIEhQEbHApGCgQEAgICEgaIAQKJATUaNiBVbm9yZGVyZWQgbGlzdC4g
TG9jYXRpb25zIHRoYXQgY291bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAgICBBIEiAECCgoN
CgUEAgICBRIEiAELEQoNCgUEAgICARIEiAESHQoNCgUEAgICAxIEiAEgIQoNCgUEAgICCBIE
iQEGNAoQCggEAgICCJwIABIEiQEHM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy ===
    # Fields for AppliedAutoProtectionPolicy
    # Field: name Type: 9 ()
    # Field: source_binding Type: 9 ()
    # Field: criteria Type: 11 (.google.cloud.backupdr.v1beta.Criteria)
    # Field: backup_plan_details Type: 11 (.google.cloud.backupdr.v1beta.BackupPlanDetail)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: binding_evaluation_summary Type: 11 (.google.cloud.backupdr.v1beta.BindingEvaluationSummary)
    # Field: status Type: 14 (.google.cloud.backupdr.v1beta.AppliedAutoProtectionPolicy.State)

# Enum: AppliedAutoProtectionPolicy::State
our $AppliedAutoProtectionPolicy_STATE_UNSPECIFIED = 0;
our $AppliedAutoProtectionPolicy_CREATING = 1;
our $AppliedAutoProtectionPolicy_ACTIVE = 2;
our $AppliedAutoProtectionPolicy_DELETION_INITIATED = 3;

# === Message: Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest ===
    # Fields for ListAppliedAutoProtectionPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse ===
    # Fields for ListAppliedAutoProtectionPoliciesResponse
    # Field: applied_auto_protection_policies Type: 11 (.google.cloud.backupdr.v1beta.AppliedAutoProtectionPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/appliedautoprotectionpolicy.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy;

    my $msg = Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy->new({
        name => $name,
        source_binding => $source_binding,
        criteria => $criteria,
        backup_plan_details => $backup_plan_details,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/appliedautoprotectionpolicy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy

AppliedAutoProtectionPolicy is a read-only view of AutoProtectionPolicy
and AutoProtectionPolicyBinding resources that apply to a given workload
project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Canonical resource name.
Format:
projects/{workload-project-number}/locations/{location}/appliedAutoProtectionPolicies/{id}.

=item * C<< $msg->source_binding() >> / C<< $msg->source_binding($value) >>

Type: C<String>

Output only. The full resource name of the AutoProtectionPolicyBinding that
applies the source policy to a scope including this workload project. e.g.,
projects/{admin-project}/locations/{location}/autoProtectionPolicies/{policy_id}/autoProtectionPolicyBindings/{binding_id}.

=item * C<< $msg->criteria() >> / C<< $msg->criteria($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::Criteria>)

Output only. The criteria resources must meet for this rule to apply. From
AutoProtectionPolicy.criteria.

=item * C<< $msg->backup_plan_details() >> / C<< $msg->backup_plan_details($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicy::BackupPlanDetail>)

Output only. The set of backup plan configurations, mirroring the
backup_plan_details from the source AutoProtectionPolicy. Each element
specifies a backup plan for a given resource type.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the binding was last modified.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp indicating when the binding was last created.

=item * C<< $msg->binding_evaluation_summary() >> / C<< $msg->binding_evaluation_summary($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary>)

Output only. The summary of the last policy application when the job has
run.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Cloud::Backupdr::V1beta::AppliedAutoProtectionPolicy::State>)

Output only. The status of the applied auto protection policy.

=back

=head3 Enum: AppliedAutoProtectionPolicy::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETION_INITIATED> => C<3>

=back

=head2 Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesRequest

Request message for listing AppliedAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location for which to retrieve the list of
applied policies. Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of applied policies to return in a single
page.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListAppliedAutoProtectionPolicies` call.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter expression that filters resources listed in the
response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. An expression that sorts the results in the response.

=back

=head2 Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::ListAppliedAutoProtectionPoliciesResponse

Response message for ListAppliedAutoProtectionPolicies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->applied_auto_protection_policies() >> / C<< $msg->applied_auto_protection_policies($value) >>

Type: C<Message> (L<Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::AppliedAutoProtectionPolicy>)

A list of the AppliedAutoProtectionPolicy resources found.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::Appliedautoprotectionpolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
