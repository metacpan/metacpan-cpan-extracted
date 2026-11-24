package Google::Ai::Generativelanguage::V1alpha::DiscussService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1alpha::Citation };
    eval { require Google::Ai::Generativelanguage::V1alpha::Safety };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvZGlzY3Vzc19zZXJ2aWNl
LnByb3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEaM2dvb2dsZS9h
aS9nZW5lcmF0aXZlbGFuZ3VhZ2UvdjFhbHBoYS9jaXRhdGlvbi5wcm90bxoxZ29vZ2xlL2Fp
L2dlbmVyYXRpdmVsYW5ndWFnZS92MWFscGhhL3NhZmV0eS5wcm90bxocZ29vZ2xlL2FwaS9h
bm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ihgMKFkdl
bmVyYXRlTWVzc2FnZVJlcXVlc3QSRQoFbW9kZWwYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2
ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL01vZGVsUgVtb2RlbBJQCgZwcm9tcHQYAiABKAsy
My5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuTWVzc2FnZVByb21wdEID
4EECUgZwcm9tcHQSKgoLdGVtcGVyYXR1cmUYAyABKAJCA+BBAUgAUgt0ZW1wZXJhdHVyZYgB
ARIxCg9jYW5kaWRhdGVfY291bnQYBCABKAVCA+BBAUgBUg5jYW5kaWRhdGVDb3VudIgBARId
CgV0b3BfcBgFIAEoAkID4EEBSAJSBHRvcFCIAQESHQoFdG9wX2sYBiABKAVCA+BBAUgDUgR0
b3BLiAEBQg4KDF90ZW1wZXJhdHVyZUISChBfY2FuZGlkYXRlX2NvdW50QggKBl90b3BfcEII
CgZfdG9wX2siggIKF0dlbmVyYXRlTWVzc2FnZVJlc3BvbnNlEk0KCmNhbmRpZGF0ZXMYASAD
KAsyLS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuTWVzc2FnZVIKY2Fu
ZGlkYXRlcxJJCghtZXNzYWdlcxgCIAMoCzItLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3Vh
Z2UudjFhbHBoYS5NZXNzYWdlUghtZXNzYWdlcxJNCgdmaWx0ZXJzGAMgAygLMjMuZ29vZ2xl
LmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkNvbnRlbnRGaWx0ZXJSB2ZpbHRlcnMi
ygEKB01lc3NhZ2USGwoGYXV0aG9yGAEgASgJQgPgQQFSBmF1dGhvchIdCgdjb250ZW50GAIg
ASgJQgPgQQJSB2NvbnRlbnQSbQoRY2l0YXRpb25fbWV0YWRhdGEYAyABKAsyNi5nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuQ2l0YXRpb25NZXRhZGF0YUID4EEDSABS
EGNpdGF0aW9uTWV0YWRhdGGIAQFCFAoSX2NpdGF0aW9uX21ldGFkYXRhIs4BCg1NZXNzYWdl
UHJvbXB0Eh0KB2NvbnRleHQYASABKAlCA+BBAVIHY29udGV4dBJOCghleGFtcGxlcxgCIAMo
CzItLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5FeGFtcGxlQgPgQQFS
CGV4YW1wbGVzEk4KCG1lc3NhZ2VzGAMgAygLMi0uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MWFscGhhLk1lc3NhZ2VCA+BBAlIIbWVzc2FnZXMinwEKB0V4YW1wbGUSSAoFaW5w
dXQYASABKAsyLS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuTWVzc2Fn
ZUID4EECUgVpbnB1dBJKCgZvdXRwdXQYAiABKAsyLS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYWxwaGEuTWVzc2FnZUID4EECUgZvdXRwdXQitAEKGUNvdW50TWVzc2FnZVRv
a2Vuc1JlcXVlc3QSRQoFbW9kZWwYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdl
Lmdvb2dsZWFwaXMuY29tL01vZGVsUgVtb2RlbBJQCgZwcm9tcHQYAiABKAsyMy5nb29nbGUu
YWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuTWVzc2FnZVByb21wdEID4EECUgZwcm9t
cHQiPQoaQ291bnRNZXNzYWdlVG9rZW5zUmVzcG9uc2USHwoLdG9rZW5fY291bnQYASABKAVS
CnRva2VuQ291bnQylgQKDkRpc2N1c3NTZXJ2aWNlEvsBCg9HZW5lcmF0ZU1lc3NhZ2USPC5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuR2VuZXJhdGVNZXNzYWdlUmVx
dWVzdBo9Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5HZW5lcmF0ZU1l
c3NhZ2VSZXNwb25zZSJrgtPkkwIuIikvdjFhbHBoYS97bW9kZWw9bW9kZWxzLyp9OmdlbmVy
YXRlTWVzc2FnZToBKtpBNG1vZGVsLHByb21wdCx0ZW1wZXJhdHVyZSxjYW5kaWRhdGVfY291
bnQsdG9wX3AsdG9wX2sS3wEKEkNvdW50TWVzc2FnZVRva2VucxI/Lmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5Db3VudE1lc3NhZ2VUb2tlbnNSZXF1ZXN0GkAuZ29v
Z2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhLkNvdW50TWVzc2FnZVRva2Vuc1Jl
c3BvbnNlIkaC0+STAjEiLC92MWFscGhhL3ttb2RlbD1tb2RlbHMvKn06Y291bnRNZXNzYWdl
VG9rZW5zOgEq2kEMbW9kZWwscHJvbXB0GiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xl
YXBpcy5jb21CoQEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGFC
E0Rpc2N1c3NTZXJ2aWNlUHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0
aXZlbGFuZ3VhZ2UvYXBpdjFhbHBoYS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZl
bGFuZ3VhZ2VwYkqPQgoHEgUOAPUBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAALQoJCgIDABIDEgA9CgkKAgMBEgMTADsKCQoCAwISAxQAJgoJCgIDAxID
FQAhCgkKAgMEEgMWACkKCQoCAwUSAxcAIwoICgEIEgMZAHUKCQoCCAsSAxkAdQoICgEIEgMa
ACIKCQoCCAoSAxoAIgoICgEIEgMbADQKCQoCCAgSAxsANAoICgEIEgMcAEEKCQoCCAESAxwA
QQrJAQoCBgASBCIAOQEavAEgQW4gQVBJIGZvciB1c2luZyBHZW5lcmF0aXZlIExhbmd1YWdl
IE1vZGVscyAoR0xNcykgaW4gZGlhbG9nIGFwcGxpY2F0aW9ucy4KCiBBbHNvIGtub3duIGFz
IGxhcmdlIGxhbmd1YWdlIG1vZGVscyAoTExNcyksIHRoaXMgQVBJIHByb3ZpZGVzIG1vZGVs
cyB0aGF0CiBhcmUgdHJhaW5lZCBmb3IgbXVsdGktdHVybiBkaWFsb2cuCgoKCgMGAAESAyII
FgoKCgMGAAMSAyMCSQoMCgUGAAOZCBIDIwJJClMKBAYAAgASBCYCLgMaRSBHZW5lcmF0ZXMg
YSByZXNwb25zZSBmcm9tIHRoZSBtb2RlbCBnaXZlbiBhbiBpbnB1dCBgTWVzc2FnZVByb21w
dGAuCgoMCgUGAAIAARIDJgYVCgwKBQYAAgACEgMmFiwKDAoFBgACAAMSAycPJgoNCgUGAAIA
BBIEKAQrBgoRCgkGAAIABLDKvCISBCgEKwYKDQoFBgACAAQSBCwELT8KEAoIBgACAASbCAAS
BCwELT8KUQoEBgACARIEMQI4AxpDIFJ1bnMgYSBtb2RlbCdzIHRva2VuaXplciBvbiBhIHN0
cmluZyBhbmQgcmV0dXJucyB0aGUgdG9rZW4gY291bnQuCgoMCgUGAAIBARIDMQYYCgwKBQYA
AgECEgMxGTIKDAoFBgACAQMSAzIPKQoNCgUGAAIBBBIEMwQ2BgoRCgkGAAIBBLDKvCISBDME
NgYKDAoFBgACAQQSAzcEOgoPCggGAAIBBJsIABIDNwQ6CkQKAgQAEgQ8AGsBGjggUmVxdWVz
dCB0byBnZW5lcmF0ZSBhIG1lc3NhZ2UgcmVzcG9uc2UgZnJvbSB0aGUgbW9kZWwuCgoKCgME
AAESAzwIHgpYCgQEAAIAEgRAAkUEGkogUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBtb2Rl
bCB0byB1c2UuCgogRm9ybWF0OiBgbmFtZT1tb2RlbHMve21vZGVsfWAuCgoMCgUEAAIABRID
QAIICgwKBQQAAgABEgNACQ4KDAoFBAACAAMSA0AREgoNCgUEAAIACBIEQBNFAwoPCggEAAIA
CJwIABIDQQQqCg8KBwQAAgAInwgSBEIERAUKuAEKBAQAAgESA0wCRBqqASBSZXF1aXJlZC4g
VGhlIHN0cnVjdHVyZWQgdGV4dHVhbCBpbnB1dCBnaXZlbiB0byB0aGUgbW9kZWwgYXMgYSBw
cm9tcHQuCgogR2l2ZW4gYQogcHJvbXB0LCB0aGUgbW9kZWwgd2lsbCByZXR1cm4gd2hhdCBp
dCBwcmVkaWN0cyBpcyB0aGUgbmV4dCBtZXNzYWdlIGluIHRoZQogZGlzY3Vzc2lvbi4KCgwK
BQQAAgEGEgNMAg8KDAoFBAACAQESA0wQFgoMCgUEAAIBAxIDTBkaCgwKBQQAAgEIEgNMG0MK
DwoIBAACAQicCAASA0wcQgqZAgoEBAACAhIDVAJKGosCIE9wdGlvbmFsLiBDb250cm9scyB0
aGUgcmFuZG9tbmVzcyBvZiB0aGUgb3V0cHV0LgoKIFZhbHVlcyBjYW4gcmFuZ2Ugb3ZlciBg
WzAuMCwxLjBdYCwKIGluY2x1c2l2ZS4gQSB2YWx1ZSBjbG9zZXIgdG8gYDEuMGAgd2lsbCBw
cm9kdWNlIHJlc3BvbnNlcyB0aGF0IGFyZSBtb3JlCiB2YXJpZWQsIHdoaWxlIGEgdmFsdWUg
Y2xvc2VyIHRvIGAwLjBgIHdpbGwgdHlwaWNhbGx5IHJlc3VsdCBpbgogbGVzcyBzdXJwcmlz
aW5nIHJlc3BvbnNlcyBmcm9tIHRoZSBtb2RlbC4KCgwKBQQAAgIEEgNUAgoKDAoFBAACAgUS
A1QLEAoMCgUEAAICARIDVBEcCgwKBQQAAgIDEgNUHyAKDAoFBAACAggSA1QhSQoPCggEAAIC
CJwIABIDVCJICqUBCgQEAAIDEgNaAk4alwEgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgZ2Vu
ZXJhdGVkIHJlc3BvbnNlIG1lc3NhZ2VzIHRvIHJldHVybi4KCiBUaGlzIHZhbHVlIG11c3Qg
YmUgYmV0d2VlbgogYFsxLCA4XWAsIGluY2x1c2l2ZS4gSWYgdW5zZXQsIHRoaXMgd2lsbCBk
ZWZhdWx0IHRvIGAxYC4KCgwKBQQAAgMEEgNaAgoKDAoFBAACAwUSA1oLEAoMCgUEAAIDARID
WhEgCgwKBQQAAgMDEgNaIyQKDAoFBAACAwgSA1olTQoPCggEAAIDCJwIABIDWiZMCvwBCgQE
AAIEEgNjAkQa7gEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIGN1bXVsYXRpdmUgcHJvYmFiaWxp
dHkgb2YgdG9rZW5zIHRvIGNvbnNpZGVyIHdoZW4KIHNhbXBsaW5nLgoKIFRoZSBtb2RlbCB1
c2VzIGNvbWJpbmVkIFRvcC1rIGFuZCBudWNsZXVzIHNhbXBsaW5nLgoKIE51Y2xldXMgc2Ft
cGxpbmcgY29uc2lkZXJzIHRoZSBzbWFsbGVzdCBzZXQgb2YgdG9rZW5zIHdob3NlIHByb2Jh
YmlsaXR5CiBzdW0gaXMgYXQgbGVhc3QgYHRvcF9wYC4KCgwKBQQAAgQEEgNjAgoKDAoFBAAC
BAUSA2MLEAoMCgUEAAIEARIDYxEWCgwKBQQAAgQDEgNjGRoKDAoFBAACBAgSA2MbQwoPCggE
AAIECJwIABIDYxxCCssBCgQEAAIFEgNqAkQavQEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51
bWJlciBvZiB0b2tlbnMgdG8gY29uc2lkZXIgd2hlbiBzYW1wbGluZy4KCiBUaGUgbW9kZWwg
dXNlcyBjb21iaW5lZCBUb3AtayBhbmQgbnVjbGV1cyBzYW1wbGluZy4KCiBUb3AtayBzYW1w
bGluZyBjb25zaWRlcnMgdGhlIHNldCBvZiBgdG9wX2tgIG1vc3QgcHJvYmFibGUgdG9rZW5z
LgoKDAoFBAACBQQSA2oCCgoMCgUEAAIFBRIDagsQCgwKBQQAAgUBEgNqERYKDAoFBAACBQMS
A2oZGgoMCgUEAAIFCBIDahtDCg8KCAQAAgUInAgAEgNqHEIKmQEKAgQBEgRxAH8BGowBIFRo
ZSByZXNwb25zZSBmcm9tIHRoZSBtb2RlbC4KCiBUaGlzIGluY2x1ZGVzIGNhbmRpZGF0ZSBt
ZXNzYWdlcyBhbmQKIGNvbnZlcnNhdGlvbiBoaXN0b3J5IGluIHRoZSBmb3JtIG9mIGNocm9u
b2xvZ2ljYWxseS1vcmRlcmVkIG1lc3NhZ2VzLgoKCgoDBAEBEgNxCB8KOgoEBAECABIDcwIi
Gi0gQ2FuZGlkYXRlIHJlc3BvbnNlIG1lc3NhZ2VzIGZyb20gdGhlIG1vZGVsLgoKDAoFBAEC
AAQSA3MCCgoMCgUEAQIABhIDcwsSCgwKBQQBAgABEgNzEx0KDAoFBAECAAMSA3MgIQo6CgQE
AQIBEgN2AiAaLSBUaGUgY29udmVyc2F0aW9uIGhpc3RvcnkgdXNlZCBieSB0aGUgbW9kZWwu
CgoMCgUEAQIBBBIDdgIKCgwKBQQBAgEGEgN2CxIKDAoFBAECAQESA3YTGwoMCgUEAQIBAxID
dh4fCpECCgQEAQICEgN+AiUagwIgQSBzZXQgb2YgY29udGVudCBmaWx0ZXJpbmcgbWV0YWRh
dGEgZm9yIHRoZSBwcm9tcHQgYW5kIHJlc3BvbnNlCiB0ZXh0LgoKIFRoaXMgaW5kaWNhdGVz
IHdoaWNoIGBTYWZldHlDYXRlZ29yeWAocykgYmxvY2tlZCBhCiBjYW5kaWRhdGUgZnJvbSB0
aGlzIHJlc3BvbnNlLCB0aGUgbG93ZXN0IGBIYXJtUHJvYmFiaWxpdHlgCiB0aGF0IHRyaWdn
ZXJlZCBhIGJsb2NrLCBhbmQgdGhlIEhhcm1UaHJlc2hvbGQgc2V0dGluZyBmb3IgdGhhdCBj
YXRlZ29yeS4KCgwKBQQBAgIEEgN+AgoKDAoFBAECAgYSA34LGAoMCgUEAQICARIDfhkgCgwK
BQQBAgIDEgN+IyQKygEKAgQCEgaIAQCcAQEauwEgVGhlIGJhc2UgdW5pdCBvZiBzdHJ1Y3R1
cmVkIHRleHQuCgogQSBgTWVzc2FnZWAgaW5jbHVkZXMgYW4gYGF1dGhvcmAgYW5kIHRoZSBg
Y29udGVudGAgb2YKIHRoZSBgTWVzc2FnZWAuCgogVGhlIGBhdXRob3JgIGlzIHVzZWQgdG8g
dGFnIG1lc3NhZ2VzIHdoZW4gdGhleSBhcmUgZmVkIHRvIHRoZQogbW9kZWwgYXMgdGV4dC4K
CgsKAwQCARIEiAEIDwrIAQoEBAICABIEjwECPRq5ASBPcHRpb25hbC4gVGhlIGF1dGhvciBv
ZiB0aGlzIE1lc3NhZ2UuCgogVGhpcyBzZXJ2ZXMgYXMgYSBrZXkgZm9yIHRhZ2dpbmcKIHRo
ZSBjb250ZW50IG9mIHRoaXMgTWVzc2FnZSB3aGVuIGl0IGlzIGZlZCB0byB0aGUgbW9kZWwg
YXMgdGV4dC4KCiBUaGUgYXV0aG9yIGNhbiBiZSBhbnkgYWxwaGFudW1lcmljIHN0cmluZy4K
Cg0KBQQCAgAFEgSPAQIICg0KBQQCAgABEgSPAQkPCg0KBQQCAgADEgSPARITCg0KBQQCAgAI
EgSPARQ8ChAKCAQCAgAInAgAEgSPARU7CkcKBAQCAgESBJIBAj4aOSBSZXF1aXJlZC4gVGhl
IHRleHQgY29udGVudCBvZiB0aGUgc3RydWN0dXJlZCBgTWVzc2FnZWAuCgoNCgUEAgIBBRIE
kgECCAoNCgUEAgIBARIEkgEJEAoNCgUEAgIBAxIEkgETFAoNCgUEAgIBCBIEkgEVPQoQCggE
AgIBCJwIABIEkgEWPAqoAgoEBAICAhIGmgECmwEyGpcCIE91dHB1dCBvbmx5LiBDaXRhdGlv
biBpbmZvcm1hdGlvbiBmb3IgbW9kZWwtZ2VuZXJhdGVkIGBjb250ZW50YCBpbiB0aGlzCiBg
TWVzc2FnZWAuCgogSWYgdGhpcyBgTWVzc2FnZWAgd2FzIGdlbmVyYXRlZCBhcyBvdXRwdXQg
ZnJvbSB0aGUgbW9kZWwsIHRoaXMgZmllbGQgbWF5IGJlCiBwb3B1bGF0ZWQgd2l0aCBhdHRy
aWJ1dGlvbiBpbmZvcm1hdGlvbiBmb3IgYW55IHRleHQgaW5jbHVkZWQgaW4gdGhlCiBgY29u
dGVudGAuIFRoaXMgZmllbGQgaXMgdXNlZCBvbmx5IG9uIG91dHB1dC4KCg0KBQQCAgIEEgSa
AQIKCg0KBQQCAgIGEgSaAQsbCg0KBQQCAgIBEgSaARwtCg0KBQQCAgIDEgSaATAxCg0KBQQC
AgIIEgSbAQYxChAKCAQCAgIInAgAEgSbAQcwCqYDCgIEAxIGpQEAygEBGpcDIEFsbCBvZiB0
aGUgc3RydWN0dXJlZCBpbnB1dCB0ZXh0IHBhc3NlZCB0byB0aGUgbW9kZWwgYXMgYSBwcm9t
cHQuCgogQSBgTWVzc2FnZVByb21wdGAgY29udGFpbnMgYSBzdHJ1Y3R1cmVkIHNldCBvZiBm
aWVsZHMgdGhhdCBwcm92aWRlIGNvbnRleHQKIGZvciB0aGUgY29udmVyc2F0aW9uLCBleGFt
cGxlcyBvZiB1c2VyIGlucHV0L21vZGVsIG91dHB1dCBtZXNzYWdlIHBhaXJzIHRoYXQKIHBy
aW1lIHRoZSBtb2RlbCB0byByZXNwb25kIGluIGRpZmZlcmVudCB3YXlzLCBhbmQgdGhlIGNv
bnZlcnNhdGlvbiBoaXN0b3J5CiBvciBsaXN0IG9mIG1lc3NhZ2VzIHJlcHJlc2VudGluZyB0
aGUgYWx0ZXJuYXRpbmcgdHVybnMgb2YgdGhlIGNvbnZlcnNhdGlvbgogYmV0d2VlbiB0aGUg
dXNlciBhbmQgdGhlIG1vZGVsLgoKCwoDBAMBEgSlAQgVCskFCgQEAwIAEgS1AQI+GroFIE9w
dGlvbmFsLiBUZXh0IHRoYXQgc2hvdWxkIGJlIHByb3ZpZGVkIHRvIHRoZSBtb2RlbCBmaXJz
dCB0byBncm91bmQgdGhlCiByZXNwb25zZS4KCiBJZiBub3QgZW1wdHksIHRoaXMgYGNvbnRl
eHRgIHdpbGwgYmUgZ2l2ZW4gdG8gdGhlIG1vZGVsIGZpcnN0IGJlZm9yZSB0aGUKIGBleGFt
cGxlc2AgYW5kIGBtZXNzYWdlc2AuIFdoZW4gdXNpbmcgYSBgY29udGV4dGAgYmUgc3VyZSB0
byBwcm92aWRlIGl0CiB3aXRoIGV2ZXJ5IHJlcXVlc3QgdG8gbWFpbnRhaW4gY29udGludWl0
eS4KCiBUaGlzIGZpZWxkIGNhbiBiZSBhIGRlc2NyaXB0aW9uIG9mIHlvdXIgcHJvbXB0IHRv
IHRoZSBtb2RlbCB0byBoZWxwIHByb3ZpZGUKIGNvbnRleHQgYW5kIGd1aWRlIHRoZSByZXNw
b25zZXMuIEV4YW1wbGVzOiAiVHJhbnNsYXRlIHRoZSBwaHJhc2UgZnJvbQogRW5nbGlzaCB0
byBGcmVuY2guIiBvciAiR2l2ZW4gYSBzdGF0ZW1lbnQsIGNsYXNzaWZ5IHRoZSBzZW50aW1l
bnQgYXMgaGFwcHksCiBzYWQgb3IgbmV1dHJhbC4iCgogQW55dGhpbmcgaW5jbHVkZWQgaW4g
dGhpcyBmaWVsZCB3aWxsIHRha2UgcHJlY2VkZW5jZSBvdmVyIG1lc3NhZ2UgaGlzdG9yeQog
aWYgdGhlIHRvdGFsIGlucHV0IHNpemUgZXhjZWVkcyB0aGUgbW9kZWwncyBgaW5wdXRfdG9r
ZW5fbGltaXRgIGFuZCB0aGUKIGlucHV0IHJlcXVlc3QgaXMgdHJ1bmNhdGVkLgoKDQoFBAMC
AAUSBLUBAggKDQoFBAMCAAESBLUBCRAKDQoFBAMCAAMSBLUBExQKDQoFBAMCAAgSBLUBFT0K
EAoIBAMCAAicCAASBLUBFjwKtQMKBAQDAgESBMABAkkapgMgT3B0aW9uYWwuIEV4YW1wbGVz
IG9mIHdoYXQgdGhlIG1vZGVsIHNob3VsZCBnZW5lcmF0ZS4KCiBUaGlzIGluY2x1ZGVzIGJv
dGggdXNlciBpbnB1dCBhbmQgdGhlIHJlc3BvbnNlIHRoYXQgdGhlIG1vZGVsIHNob3VsZAog
ZW11bGF0ZS4KCiBUaGVzZSBgZXhhbXBsZXNgIGFyZSB0cmVhdGVkIGlkZW50aWNhbGx5IHRv
IGNvbnZlcnNhdGlvbiBtZXNzYWdlcyBleGNlcHQKIHRoYXQgdGhleSB0YWtlIHByZWNlZGVu
Y2Ugb3ZlciB0aGUgaGlzdG9yeSBpbiBgbWVzc2FnZXNgOgogSWYgdGhlIHRvdGFsIGlucHV0
IHNpemUgZXhjZWVkcyB0aGUgbW9kZWwncyBgaW5wdXRfdG9rZW5fbGltaXRgIHRoZSBpbnB1
dAogd2lsbCBiZSB0cnVuY2F0ZWQuIEl0ZW1zIHdpbGwgYmUgZHJvcHBlZCBmcm9tIGBtZXNz
YWdlc2AgYmVmb3JlIGBleGFtcGxlc2AuCgoNCgUEAwIBBBIEwAECCgoNCgUEAwIBBhIEwAEL
EgoNCgUEAwIBARIEwAETGwoNCgUEAwIBAxIEwAEeHwoNCgUEAwIBCBIEwAEgSAoQCggEAwIB
CJwIABIEwAEhRwqaAgoEBAMCAhIEyQECSRqLAiBSZXF1aXJlZC4gQSBzbmFwc2hvdCBvZiB0
aGUgcmVjZW50IGNvbnZlcnNhdGlvbiBoaXN0b3J5IHNvcnRlZAogY2hyb25vbG9naWNhbGx5
LgoKIFR1cm5zIGFsdGVybmF0ZSBiZXR3ZWVuIHR3byBhdXRob3JzLgoKIElmIHRoZSB0b3Rh
bCBpbnB1dCBzaXplIGV4Y2VlZHMgdGhlIG1vZGVsJ3MgYGlucHV0X3Rva2VuX2xpbWl0YCB0
aGUgaW5wdXQKIHdpbGwgYmUgdHJ1bmNhdGVkOiBUaGUgb2xkZXN0IGl0ZW1zIHdpbGwgYmUg
ZHJvcHBlZCBmcm9tIGBtZXNzYWdlc2AuCgoNCgUEAwICBBIEyQECCgoNCgUEAwICBhIEyQEL
EgoNCgUEAwICARIEyQETGwoNCgUEAwICAxIEyQEeHwoNCgUEAwICCBIEyQEgSAoQCggEAwIC
CJwIABIEyQEhRwqKAQoCBAQSBs8BANUBARp8IEFuIGlucHV0L291dHB1dCBleGFtcGxlIHVz
ZWQgdG8gaW5zdHJ1Y3QgdGhlIE1vZGVsLgoKIEl0IGRlbW9uc3RyYXRlcyBob3cgdGhlIG1v
ZGVsIHNob3VsZCByZXNwb25kIG9yIGZvcm1hdCBpdHMgcmVzcG9uc2UuCgoLCgMEBAESBM8B
CA8KSQoEBAQCABIE0QECPRo7IFJlcXVpcmVkLiBBbiBleGFtcGxlIG9mIGFuIGlucHV0IGBN
ZXNzYWdlYCBmcm9tIHRoZSB1c2VyLgoKDQoFBAQCAAYSBNEBAgkKDQoFBAQCAAESBNEBCg8K
DQoFBAQCAAMSBNEBEhMKDQoFBAQCAAgSBNEBFDwKEAoIBAQCAAicCAASBNEBFTsKVQoEBAQC
ARIE1AECPhpHIFJlcXVpcmVkLiBBbiBleGFtcGxlIG9mIHdoYXQgdGhlIG1vZGVsIHNob3Vs
ZCBvdXRwdXQgZ2l2ZW4gdGhlIGlucHV0LgoKDQoFBAQCAQYSBNQBAgkKDQoFBAQCAQESBNQB
ChAKDQoFBAQCAQMSBNQBExQKDQoFBAQCAQgSBNQBFT0KEAoIBAQCAQicCAASBNQBFjwKqgEK
AgQFEgbbAQDrAQEamwEgQ291bnRzIHRoZSBudW1iZXIgb2YgdG9rZW5zIGluIHRoZSBgcHJv
bXB0YCBzZW50IHRvIGEgbW9kZWwuCgogTW9kZWxzIG1heSB0b2tlbml6ZSB0ZXh0IGRpZmZl
cmVudGx5LCBzbyBlYWNoIG1vZGVsIG1heSByZXR1cm4gYSBkaWZmZXJlbnQKIGB0b2tlbl9j
b3VudGAuCgoLCgMEBQESBNsBCCEKyQEKBAQFAgASBuIBAucBBBq4ASBSZXF1aXJlZC4gVGhl
IG1vZGVsJ3MgcmVzb3VyY2UgbmFtZS4gVGhpcyBzZXJ2ZXMgYXMgYW4gSUQgZm9yIHRoZSBN
b2RlbCB0bwogdXNlLgoKIFRoaXMgbmFtZSBzaG91bGQgbWF0Y2ggYSBtb2RlbCBuYW1lIHJl
dHVybmVkIGJ5IHRoZSBgTGlzdE1vZGVsc2AgbWV0aG9kLgoKIEZvcm1hdDogYG1vZGVscy97
bW9kZWx9YAoKDQoFBAUCAAUSBOIBAggKDQoFBAUCAAESBOIBCQ4KDQoFBAUCAAMSBOIBERIK
DwoFBAUCAAgSBuIBE+cBAwoQCggEBQIACJwIABIE4wEEKgoRCgcEBQIACJ8IEgbkAQTmAQUK
SgoEBAUCARIE6gECRBo8IFJlcXVpcmVkLiBUaGUgcHJvbXB0LCB3aG9zZSB0b2tlbiBjb3Vu
dCBpcyB0byBiZSByZXR1cm5lZC4KCg0KBQQFAgEGEgTqAQIPCg0KBQQFAgEBEgTqARAWCg0K
BQQFAgEDEgTqARkaCg0KBQQFAgEIEgTqARtDChAKCAQFAgEInAgAEgTqARxCCm4KAgQGEgbw
AQD1AQEaYCBBIHJlc3BvbnNlIGZyb20gYENvdW50TWVzc2FnZVRva2Vuc2AuCgogSXQgcmV0
dXJucyB0aGUgbW9kZWwncyBgdG9rZW5fY291bnRgIGZvciB0aGUgYHByb21wdGAuCgoLCgME
BgESBPABCCIKaQoEBAYCABIE9AECGBpbIFRoZSBudW1iZXIgb2YgdG9rZW5zIHRoYXQgdGhl
IGBtb2RlbGAgdG9rZW5pemVzIHRoZSBgcHJvbXB0YCBpbnRvLgoKIEFsd2F5cyBub24tbmVn
YXRpdmUuCgoNCgUEBgIABRIE9AECBwoNCgUEBgIAARIE9AEIEwoNCgUEBgIAAxIE9AEWF2IG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest ===
    # Fields for GenerateMessageRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1alpha.MessagePrompt)
    # Field: temperature Type: 2 ()
    # Field: candidate_count Type: 5 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageResponse ===
    # Fields for GenerateMessageResponse
    # Field: candidates Type: 11 (.google.ai.generativelanguage.v1alpha.Message)
    # Field: messages Type: 11 (.google.ai.generativelanguage.v1alpha.Message)
    # Field: filters Type: 11 (.google.ai.generativelanguage.v1alpha.ContentFilter)

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::Message ===
    # Fields for Message
    # Field: author Type: 9 ()
    # Field: content Type: 9 ()
    # Field: citation_metadata Type: 11 (.google.ai.generativelanguage.v1alpha.CitationMetadata)

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt ===
    # Fields for MessagePrompt
    # Field: context Type: 9 ()
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1alpha.Example)
    # Field: messages Type: 11 (.google.ai.generativelanguage.v1alpha.Message)

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::Example ===
    # Fields for Example
    # Field: input Type: 11 (.google.ai.generativelanguage.v1alpha.Message)
    # Field: output Type: 11 (.google.ai.generativelanguage.v1alpha.Message)

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensRequest ===
    # Fields for CountMessageTokensRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1alpha.MessagePrompt)

# === Message: Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensResponse ===
    # Fields for CountMessageTokensResponse
    # Field: token_count Type: 5 ()

# === Service Client: Google::Ai::Generativelanguage::V1alpha::DiscussService::DiscussServiceClient ===
package Google::Ai::Generativelanguage::V1alpha::DiscussService::DiscussServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1alpha::DiscussService::DiscussServiceClient

Client stub representing the remote C<DiscussService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ai.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub generate_message {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.DiscussService',
        method         => 'GenerateMessage',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageResponse',
    });
}

sub count_message_tokens {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1alpha.DiscussService',
        method         => 'CountMessageTokens',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::DiscussService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/discuss_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::DiscussService;

    my $msg = Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest->new({
        model => $model,
        prompt => $prompt,
        temperature => $temperature,
        candidate_count => $candidate_count,
    });

    # Read or update a field
    my $val = $msg->model();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/discuss_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest

Request to generate a message response from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the model to use.

Format: `name=models/{model}`.

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt>)

Required. The structured textual input given to the model as a prompt.

Given a
prompt, the model will return what it predicts is the next message in the
discussion.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.

Values can range over `[0.0,1.0]`,
inclusive. A value closer to `1.0` will produce responses that are more
varied, while a value closer to `0.0` will typically result in
less surprising responses from the model.

=item * C<< $msg->candidate_count() >> / C<< $msg->candidate_count($value) >>

Type: C<Int32>

Optional. The number of generated response messages to return.

This value must be between
`[1, 8]`, inclusive. If unset, this will default to `1`.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. The maximum cumulative probability of tokens to consider when
sampling.

The model uses combined Top-k and nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to consider when sampling.

The model uses combined Top-k and nucleus sampling.

Top-k sampling considers the set of `top_k` most probable tokens.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageResponse

The response from the model.

This includes candidate messages and
conversation history in the form of chronologically-ordered messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->candidates() >> / C<< $msg->candidates($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Message>)

Candidate response messages from the model.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Message>)

The conversation history used by the model.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Safety::ContentFilter>)

A set of content filtering metadata for the prompt and response
text.

This indicates which `SafetyCategory`(s) blocked a
candidate from this response, the lowest `HarmProbability`
that triggered a block, and the HarmThreshold setting for that category.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::Message

The base unit of structured text.

A `Message` includes an `author` and the `content` of
the `Message`.

The `author` is used to tag messages when they are fed to the
model as text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->author() >> / C<< $msg->author($value) >>

Type: C<String>

Optional. The author of this Message.

This serves as a key for tagging
the content of this Message when it is fed to the model as text.

The author can be any alphanumeric string.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Required. The text content of the structured `Message`.

=item * C<< $msg->citation_metadata() >> / C<< $msg->citation_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::Citation::CitationMetadata>)

Output only. Citation information for model-generated `content` in this
`Message`.

If this `Message` was generated as output from the model, this field may be
populated with attribution information for any text included in the
`content`. This field is used only on output.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt

All of the structured input text passed to the model as a prompt.

A `MessagePrompt` contains a structured set of fields that provide context
for the conversation, examples of user input/model output message pairs that
prime the model to respond in different ways, and the conversation history
or list of messages representing the alternating turns of the conversation
between the user and the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<String>

Optional. Text that should be provided to the model first to ground the
response.

If not empty, this `context` will be given to the model first before the
`examples` and `messages`. When using a `context` be sure to provide it
with every request to maintain continuity.

This field can be a description of your prompt to the model to help provide
context and guide the responses. Examples: "Translate the phrase from
English to French." or "Given a statement, classify the sentiment as happy,
sad or neutral."

Anything included in this field will take precedence over message history
if the total input size exceeds the model's `input_token_limit` and the
input request is truncated.

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Example>)

Optional. Examples of what the model should generate.

This includes both user input and the response that the model should
emulate.

These `examples` are treated identically to conversation messages except
that they take precedence over the history in `messages`:
If the total input size exceeds the model's `input_token_limit` the input
will be truncated. Items will be dropped from `messages` before `examples`.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Message>)

Required. A snapshot of the recent conversation history sorted
chronologically.

Turns alternate between two authors.

If the total input size exceeds the model's `input_token_limit` the input
will be truncated: The oldest items will be dropped from `messages`.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::Example

An input/output example used to instruct the Model.

It demonstrates how the model should respond or format its response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input() >> / C<< $msg->input($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Message>)

Required. An example of an input `Message` from the user.

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Message>)

Required. An example of what the model should output given the input.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensRequest

Counts the number of tokens in the `prompt` sent to a model.

Models may tokenize text differently, so each model may return a different
`token_count`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The model's resource name. This serves as an ID for the Model to
use.

This name should match a model name returned by the `ListModels` method.

Format: `models/{model}`

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt>)

Required. The prompt, whose token count is to be returned.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensResponse

A response from `CountMessageTokens`.

It returns the model's `token_count` for the `prompt`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token_count() >> / C<< $msg->token_count($value) >>

Type: C<Int32>

The number of tokens that the `model` tokenizes the `prompt` into.

Always non-negative.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::DiscussService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
