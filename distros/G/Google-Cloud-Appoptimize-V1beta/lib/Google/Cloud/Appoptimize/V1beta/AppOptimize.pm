package Google::Cloud::Appoptimize::V1beta::AppOptimize;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYXBwb3B0aW1pemUvdjFiZXRhL2FwcF9vcHRpbWl6ZS5wcm90bxIf
Z29vZ2xlLmNsb3VkLmFwcG9wdGltaXplLnYxYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8aHGdv
b2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8iwAEKE0NyZWF0ZVJlcG9ydFJlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMS
IWFwcG9wdGltaXplLmdvb2dsZWFwaXMuY29tL1JlcG9ydFIGcGFyZW50EiAKCXJlcG9ydF9p
ZBgCIAEoCUID4EECUghyZXBvcnRJZBJECgZyZXBvcnQYAyABKAsyJy5nb29nbGUuY2xvdWQu
YXBwb3B0aW1pemUudjFiZXRhLlJlcG9ydEID4EECUgZyZXBvcnQijAMKBlJlcG9ydBJCCgtl
eHBpcmVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA0gAUgpl
eHBpcmVUaW1lEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIjCgpkaW1lbnNpb25zGAIgAygJ
QgPgQQJSCmRpbWVuc2lvbnMSHQoHbWV0cmljcxgHIAMoCUID4EECUgdtZXRyaWNzEkMKBnNj
b3BlcxgDIAMoCzImLmdvb2dsZS5jbG91ZC5hcHBvcHRpbWl6ZS52MWJldGEuU2NvcGVCA+BB
AVIGc2NvcGVzEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXI6cepBbgohYXBwb3B0aW1p
emUuZ29vZ2xlYXBpcy5jb20vUmVwb3J0Ejhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vcmVwb3J0cy97cmVwb3J0fSoHcmVwb3J0czIGcmVwb3J0QgwKCmV4cGly
YXRpb24isAEKBVNjb3BlEk8KB3Byb2plY3QYASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJj
ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdEgAUgdwcm9qZWN0Ek0KC2FwcGxpY2F0
aW9uGAIgASgJQingQQL6QSMKIWFwcGh1Yi5nb29nbGVhcGlzLmNvbS9BcHBsaWNhdGlvbkgA
UgthcHBsaWNhdGlvbkIHCgVzY29wZSJRChBHZXRSZXBvcnRSZXF1ZXN0Ej0KBG5hbWUYASAB
KAlCKeBBAvpBIwohYXBwb3B0aW1pemUuZ29vZ2xlYXBpcy5jb20vUmVwb3J0UgRuYW1lIp0B
ChJMaXN0UmVwb3J0c1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMSIWFwcG9wdGlt
aXplLmdvb2dsZWFwaXMuY29tL1JlcG9ydFIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID
4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKAAQoT
TGlzdFJlcG9ydHNSZXNwb25zZRJBCgdyZXBvcnRzGAEgAygLMicuZ29vZ2xlLmNsb3VkLmFw
cG9wdGltaXplLnYxYmV0YS5SZXBvcnRSB3JlcG9ydHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuIn4KE0RlbGV0ZVJlcG9ydFJlcXVlc3QSPQoEbmFtZRgBIAEo
CUIp4EEC+kEjCiFhcHBvcHRpbWl6ZS5nb29nbGVhcGlzLmNvbS9SZXBvcnRSBG5hbWUSKAoN
YWxsb3dfbWlzc2luZxgCIAEoCEID4EEBUgxhbGxvd01pc3NpbmcimAEKEVJlYWRSZXBvcnRS
ZXF1ZXN0Ej0KBG5hbWUYASABKAlCKeBBAvpBIwohYXBwb3B0aW1pemUuZ29vZ2xlYXBpcy5j
b20vUmVwb3J0UgRuYW1lEiAKCXBhZ2Vfc2l6ZRgEIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpw
YWdlX3Rva2VuGAUgASgJQgPgQQFSCXBhZ2VUb2tlbiKvAQoSUmVhZFJlcG9ydFJlc3BvbnNl
Ei4KBHJvd3MYASADKAsyGi5nb29nbGUucHJvdG9idWYuTGlzdFZhbHVlUgRyb3dzEkEKB2Nv
bHVtbnMYBSADKAsyJy5nb29nbGUuY2xvdWQuYXBwb3B0aW1pemUudjFiZXRhLkNvbHVtblIH
Y29sdW1ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAyABKAlSDW5leHRQYWdlVG9rZW4ihwEKBkNv
bHVtbhISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHR5cGUYAiABKAlSBHR5cGUSEgoEbW9kZRgD
IAEoCVIEbW9kZRJBCgdjb2x1bW5zGAQgAygLMicuZ29vZ2xlLmNsb3VkLmFwcG9wdGltaXpl
LnYxYmV0YS5Db2x1bW5SB2NvbHVtbnMiEwoRT3BlcmF0aW9uTWV0YWRhdGEygggKC0FwcE9w
dGltaXplEtwBCgxDcmVhdGVSZXBvcnQSNC5nb29nbGUuY2xvdWQuYXBwb3B0aW1pemUudjFi
ZXRhLkNyZWF0ZVJlcG9ydFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
IneC0+STAjkiLy92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9yZXBv
cnRzOgZyZXBvcnTaQRdwYXJlbnQscmVwb3J0LHJlcG9ydF9pZMpBGwoGUmVwb3J0EhFPcGVy
YXRpb25NZXRhZGF0YRKnAQoJR2V0UmVwb3J0EjEuZ29vZ2xlLmNsb3VkLmFwcG9wdGltaXpl
LnYxYmV0YS5HZXRSZXBvcnRSZXF1ZXN0GicuZ29vZ2xlLmNsb3VkLmFwcG9wdGltaXplLnYx
YmV0YS5SZXBvcnQiPoLT5JMCMRIvL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL3JlcG9ydHMvKn3aQQRuYW1lEroBCgtMaXN0UmVwb3J0cxIzLmdvb2dsZS5jbG91ZC5h
cHBvcHRpbWl6ZS52MWJldGEuTGlzdFJlcG9ydHNSZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLmFw
cG9wdGltaXplLnYxYmV0YS5MaXN0UmVwb3J0c1Jlc3BvbnNlIkCC0+STAjESLy92MWJldGEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9yZXBvcnRz2kEGcGFyZW50EpwBCgxE
ZWxldGVSZXBvcnQSNC5nb29nbGUuY2xvdWQuYXBwb3B0aW1pemUudjFiZXRhLkRlbGV0ZVJl
cG9ydFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiPoLT5JMCMSovL3YxYmV0YS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JlcG9ydHMvKn3aQQRuYW1lEr0BCgpSZWFk
UmVwb3J0EjIuZ29vZ2xlLmNsb3VkLmFwcG9wdGltaXplLnYxYmV0YS5SZWFkUmVwb3J0UmVx
dWVzdBozLmdvb2dsZS5jbG91ZC5hcHBvcHRpbWl6ZS52MWJldGEuUmVhZFJlcG9ydFJlc3Bv
bnNlIkaC0+STAjkiNC92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBv
cnRzLyp9OnJlYWQ6ASraQQRuYW1lGk7KQRphcHBvcHRpbWl6ZS5nb29nbGVhcGlzLmNvbdJB
Lmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CrgIKI2Nv
bS5nb29nbGUuY2xvdWQuYXBwb3B0aW1pemUudjFiZXRhQhBBcHBPcHRpbWl6ZVByb3RvUAFa
RWNsb3VkLmdvb2dsZS5jb20vZ28vYXBwb3B0aW1pemUvYXBpdjFiZXRhL2FwcG9wdGltaXpl
cGI7YXBwb3B0aW1pemVwYqoCH0dvb2dsZS5DbG91ZC5BcHBPcHRpbWl6ZS5WMUJldGHKAh9H
b29nbGVcQ2xvdWRcQXBwT3B0aW1pemVcVjFiZXRh6kFnCiFhcHBodWIuZ29vZ2xlYXBpcy5j
b20vQXBwbGljYXRpb24SQnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hcHBsaWNhdGlvbnMve2FwcGxpY2F0aW9ufUr0YgoHEgUOAJgDHAq8BAoBDBIDDgASMrEE
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
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC0KCQoCAwUSAxcAJQoJCgIDBhIDGAAm
CgkKAgMHEgMZACkKCAoBCBIDGwA8CgkKAgglEgMbADwKCAoBCBIDHABcCgkKAggLEgMcAFwK
CAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAxCgkKAggIEgMeADEKCAoBCBIDHwA8CgkK
AggBEgMfADwKCAoBCBIDIAA8CgkKAggpEgMgADwKCQoBCBIEIwAmAgo8CgQInQgAEgQjACYC
Gi4gUmVzb3VyY2UgZGVmaW5pdGlvbiBmb3IgQXBwIEh1YiBBcHBsaWNhdGlvbi4KCkUKAgYA
EgQpAF8BGjkgU2VydmljZSBmb3IgbWFuYWdpbmcgYW5kIHF1ZXJ5aW5nIG9wdGltaXphdGlv
biByZXBvcnRzLgoKCgoDBgABEgMpCBMKCgoDBgADEgMqAkIKDAoFBgADmQgSAyoCQgoLCgMG
AAMSBCsCLDcKDQoFBgADmggSBCsCLDcKzQEKBAYAAgASBDMCPQMavgEgQ3JlYXRlcyBhIG5l
dyByZXBvcnQuCgogVGhpcyBpbml0aWF0ZXMgYSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9uIHRo
YXQsIHVwb24gY29tcGxldGlvbiwgcmVzdWx0cwogaW4gYSByZXBvcnQgcmVzb3VyY2UuIE9u
Y2UgdGhlIHJlcG9ydCBpcyBjcmVhdGVkLCBpdHMgcmVzdWx0cyBjYW4gYmUgcmVhZAogdmlh
IGBSZWFkUmVwb3J0YC4KCgwKBQYAAgABEgMzBhIKDAoFBgACAAISAzMTJgoMCgUGAAIAAxID
MzFNCg0KBQYAAgAEEgQ0BDcGChEKCQYAAgAEsMq8IhIENAQ3BgoMCgUGAAIABBIDOARFCg8K
CAYAAgAEmwgAEgM4BEUKDQoFBgACAAQSBDkEPAYKDwoHBgACAASZCBIEOQQ8BgpACgQGAAIB
EgRAAkUDGjIgUmV0cmlldmVzIHRoZSBkZXRhaWxzIG9mIGEgcmVwb3J0IGNvbmZpZ3VyYXRp
b24uCgoMCgUGAAIBARIDQAYPCgwKBQYAAgECEgNAECAKDAoFBgACAQMSA0ArMQoNCgUGAAIB
BBIEQQRDBgoRCgkGAAIBBLDKvCISBEEEQwYKDAoFBgACAQQSA0QEMgoPCggGAAIBBJsIABID
RAQyCjUKBAYAAgISBEgCTQMaJyBMaXN0cyByZXBvcnRzIHdpdGhpbiBhIGdpdmVuIHByb2pl
Y3QuCgoMCgUGAAICARIDSAYRCgwKBQYAAgICEgNIEiQKDAoFBgACAgMSA0gvQgoNCgUGAAIC
BBIESQRLBgoRCgkGAAICBLDKvCISBEkESwYKDAoFBgACAgQSA0wENAoPCggGAAICBJsIABID
TAQ0Ci0KBAYAAgMSBFACVQMaHyBEZWxldGVzIHRoZSBzcGVjaWZpZWQgcmVwb3J0LgoKDAoF
BgACAwESA1AGEgoMCgUGAAIDAhIDUBMmCgwKBQYAAgMDEgNQMUYKDQoFBgACAwQSBFEEUwYK
EQoJBgACAwSwyrwiEgRRBFMGCgwKBQYAAgMEEgNUBDIKDwoIBgACAwSbCAASA1QEMgo1CgQG
AAIEEgRYAl4DGicgUmVhZHMgZGF0YSB3aXRoaW4gYSBzcGVjaWZpZWQgcmVwb3J0LgoKDAoF
BgACBAESA1gGEAoMCgUGAAIEAhIDWBEiCgwKBQYAAgQDEgNYLT8KDQoFBgACBAQSBFkEXAYK
EQoJBgACBASwyrwiEgRZBFwGCgwKBQYAAgQEEgNdBDIKDwoIBgACBASbCAASA10EMgo8CgIE
ABIEYgB4ARowIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBDcmVhdGVSZXBvcnRgIG1ldGhv
ZC4KCgoKAwQAARIDYggbCvQBCgQEAAIAEgRpAm4EGuUBIFJlcXVpcmVkLiBUaGUgcGFyZW50
IEdvb2dsZSBDbG91ZCBwcm9qZWN0IHRoYXQgd2lsbCBvd24gdGhlIHJlcG9ydC4KCiBUaGlz
IHZhbHVlIGRvZXMgbm90IGRlZmluZSB0aGUgc2NvcGUgb2YgdGhlIHJlcG9ydCBkYXRhLiBT
ZWUgYFJlcG9ydC5zY29wZWAKIGZvciBzZXR0aW5nIHRoZSBkYXRhIHNjb3BlLgoKIEZvcm1h
dDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoMCgUEAAIA
BRIDaQIICgwKBQQAAgABEgNpCQ8KDAoFBAACAAMSA2kSEwoNCgUEAAIACBIEaRRuAwoPCggE
AAIACJwIABIDagQqCg8KBwQAAgAInwgSBGsEbQUKlwIKBAQAAgESA3QCQBqJAiBSZXF1aXJl
ZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhpcyByZXBvcnQuIFRoaXMgSUQgbXVzdCBiZSB1bmlx
dWUgd2l0aGluCiB0aGUgcGFyZW50IHByb2plY3QgYW5kIHNob3VsZCBjb21wbHkgd2l0aCBS
RkMgMTAzNCByZXN0cmljdGlvbnMgKGxldHRlcnMsCiBudW1iZXJzLCBhbmQgaHlwaGVuLCB3
aXRoIHRoZSBmaXJzdCBjaGFyYWN0ZXIgYSBsZXR0ZXIsIHRoZSBsYXN0IGEgbGV0dGVyCiBv
ciBhIG51bWJlciwgYW5kIGEgNjMgY2hhcmFjdGVyIG1heGltdW0pLgoKDAoFBAACAQUSA3QC
CAoMCgUEAAIBARIDdAkSCgwKBQQAAgEDEgN0FRYKDAoFBAACAQgSA3QXPwoPCggEAAIBCJwI
ABIDdBg+CjcKBAQAAgISA3cCPRoqIFJlcXVpcmVkLiBUaGUgcmVwb3J0IHJlc291cmNlIHRv
IGNyZWF0ZS4KCgwKBQQAAgIGEgN3AggKDAoFBAACAgESA3cJDwoMCgUEAAICAxIDdxITCgwK
BQQAAgIIEgN3FDwKDwoIBAACAgicCAASA3cVOwphCgIEARIFfADpAQEaVCBBIGNvbmZpZ3Vy
YXRpb24gdGhhdCBkZWZpbmVzIHRoZSBwYXJhbWV0ZXJzIGZvciB0aGUgZGF0YSByZXByZXNl
bnRlZCBieSBhCiByZXBvcnQuCgoKCgMEAQESA3wIDgoMCgMEAQcSBX0CggEECg4KBQQBB50I
EgV9AoIBBAo4CgQEAQgAEgaFAQKLAQMaKCBEZWZpbmVzIHRoaXMgcmVwb3J0J3MgZXhwaXJh
dGlvbiB0aW1lLgoKDQoFBAEIAAESBIUBCBIKugEKBAQBAgASBokBBIoBNBqpASBPdXRwdXQg
b25seS4gVGltZXN0YW1wIGluIFVUQyBvZiB3aGVuIHRoaXMgcmVwb3J0IGV4cGlyZXMuIE9u
Y2UgdGhlCiByZXBvcnQgZXhwaXJlcywgaXQgd2lsbCBubyBsb25nZXIgYmUgYWNjZXNzaWJs
ZSBhbmQgdGhlIHJlcG9ydCdzCiB1bmRlcmx5aW5nIGRhdGEgd2lsbCBiZSBkZWxldGVkLgoK
DQoFBAECAAYSBIkBBB0KDQoFBAECAAESBIkBHikKDQoFBAECAAMSBIkBLC0KDQoFBAECAAgS
BIoBCDMKEAoIBAECAAicCAASBIoBCTIKNAoEBAECARIEjgECPRomIElkZW50aWZpZXIuIFRo
ZSBuYW1lIG9mIHRoaXMgcmVwb3J0LgoKDQoFBAECAQUSBI4BAggKDQoFBAECAQESBI4BCQ0K
DQoFBAECAQMSBI4BEBEKDQoFBAECAQgSBI4BEjwKEAoIBAECAQicCAASBI4BEzsK5AcKBAQB
AgISBK0BAkoa1QcgUmVxdWlyZWQuIEEgbGlzdCBvZiBkaW1lbnNpb25zIHRvIGluY2x1ZGUg
aW4gdGhlIHJlcG9ydC4gU3VwcG9ydGVkIHZhbHVlczoKCiAgICogYHByb2plY3RgCiAgICog
YGFwcGxpY2F0aW9uYAogICAqIGBzZXJ2aWNlX29yX3dvcmtsb2FkYAogICAqIGByZXNvdXJj
ZWAKICAgKiBgcmVzb3VyY2VfdHlwZWAKICAgKiBgbG9jYXRpb25gCiAgICogYHByb2R1Y3Rf
ZGlzcGxheV9uYW1lYAogICAqIGBza3VgCiAgICogYG1vbnRoYAogICAqIGBkYXlgCiAgICog
YGhvdXJgCgogVG8gYWdncmVnYXRlIHJlc3VsdHMgYnkgdGltZSwgc3BlY2lmeSBhdCBsZWFz
dCBvbmUgdGltZSBkaW1lbnNpb24KIChgbW9udGhgLCBgZGF5YCwgb3IgYGhvdXJgKS4gQWxs
IHRpbWUgZGltZW5zaW9ucyB1c2UgUGFjaWZpYyBUaW1lLAogcmVzcGVjdCBEYXlsaWdodCBT
YXZpbmcgVGltZSAoRFNUKSwgYW5kIGZvbGxvdyB0aGVzZSBJU08gODYwMSBmb3JtYXRzOgoK
ICAgKiBgbW9udGhgOiBgWVlZWS1NTWAgKGUuZy4sIGAyMDI0LTAxYCkKICAgKiBgZGF5YDog
YFlZWVktTU0tRERgIChlLmcuLCBgMjAyNC0wMS0xMGApCiAgICogYGhvdXJgOiBgWVlZWS1N
TS1ERFRISGAgKGUuZy4sIGAyMDI0LTAxLTEwVDAwYCkKCiBJZiB0aGUgdGltZSByYW5nZSBm
aWx0ZXIgZG9lcyBub3QgYWxpZ24gd2l0aCB0aGUgc2VsZWN0ZWQgdGltZSBkaW1lbnNpb24s
CiB0aGUgcmFuZ2UgaXMgZXhwYW5kZWQgdG8gZW5jb21wYXNzIHRoZSBmdWxsIHBlcmlvZCBv
ZiB0aGUgZmluZXN0LWdyYWluZWQKIHRpbWUgZGltZW5zaW9uLgoKIEZvciBleGFtcGxlLCBp
ZiB0aGUgZmlsdGVyIGlzIGAyMDI2LTAxLTEwYCB0aHJvdWdoIGAyMDI2LTAxLTEyYCBhbmQg
dGhlCiBgbW9udGhgIGRpbWVuc2lvbiBpcyBzZWxlY3RlZCwgdGhlIGVmZmVjdGl2ZSB0aW1l
IHJhbmdlIGV4cGFuZHMgdG8gaW5jbHVkZQogYWxsIG9mIEphbnVhcnkgKGAyMDI2LTAxLTAx
YCB0byBgMjAyNi0wMi0wMWApLgoKDQoFBAECAgQSBK0BAgoKDQoFBAECAgUSBK0BCxEKDQoF
BAECAgESBK0BEhwKDQoFBAECAgMSBK0BHyAKDQoFBAECAggSBK0BIUkKEAoIBAECAgicCAAS
BK0BIkgK4QIKBAQBAgMSBLoBAkca0gIgUmVxdWlyZWQuIEEgbGlzdCBvZiBtZXRyaWNzIHRv
IGluY2x1ZGUgaW4gdGhlIHJlcG9ydC4gU3VwcG9ydGVkIHZhbHVlczoKCiAgICogYGNvc3Rg
CiAgICogYGNwdV9tZWFuX3V0aWxpemF0aW9uYAogICAqIGBjcHVfdXNhZ2VfY29yZV9zZWNv
bmRzYAogICAqIGBjcHVfYWxsb2NhdGlvbl9jb3JlX3NlY29uZHNgCiAgICogYGNwdV9wOTVf
dXRpbGl6YXRpb25gCiAgICogYG1lbW9yeV9tZWFuX3V0aWxpemF0aW9uYAogICAqIGBtZW1v
cnlfdXNhZ2VfYnl0ZV9zZWNvbmRzYAogICAqIGBtZW1vcnlfYWxsb2NhdGlvbl9ieXRlX3Nl
Y29uZHNgCiAgICogYG1lbW9yeV9wOTVfdXRpbGl6YXRpb25gCgoNCgUEAQIDBBIEugECCgoN
CgUEAQIDBRIEugELEQoNCgUEAQIDARIEugESGQoNCgUEAQIDAxIEugEcHQoNCgUEAQIDCBIE
ugEeRgoQCggEAQIDCJwIABIEugEfRQqEAQoEBAECBBIEvgECRRp2IE9wdGlvbmFsLiBUaGUg
cmVzb3VyY2UgY29udGFpbmVycyBmb3Igd2hpY2ggdG8gZmV0Y2ggZGF0YS4gRGVmYXVsdCBp
cyB0aGUKIHByb2plY3Qgc3BlY2lmaWVkIGluIHRoZSByZXBvcnQncyBwYXJlbnQuCgoNCgUE
AQIEBBIEvgECCgoNCgUEAQIEBhIEvgELEAoNCgUEAQIEARIEvgERFwoNCgUEAQIEAxIEvgEa
GwoNCgUEAQIECBIEvgEcRAoQCggEAQIECJwIABIEvgEdQwqNDQoEBAECBRIE6AECPRr+DCBP
cHRpb25hbC4gQSBDb21tb24gRXhwcmVzc2lvbiBMYW5ndWFnZSAoQ0VMKSBleHByZXNzaW9u
IHVzZWQgdG8gZmlsdGVyIHRoZQogZGF0YSBmb3IgdGhlIHJlcG9ydC4KCiBQcmVkaWNhdGVz
IG1heSByZWZlciB0byBhbnkgZGltZW5zaW9uLiBGaWx0ZXJpbmcgbXVzdCBjb25mb3JtIHRv
IHRoZXNlCiBjb25zdHJhaW50czoKCiAgICogQWxsIHN0cmluZyBmaWVsZCBwcmVkaWNhdGVz
IG11c3QgdXNlIGV4YWN0IHN0cmluZyBtYXRjaGVzLgogICAqIE11bHRpcGxlIHByZWRpY2F0
ZXMgcmVmZXJyaW5nIHRvIHRoZSBzYW1lIHN0cmluZyBmaWVsZCBtdXN0IGJlIGpvaW5lZAog
ICAgIHVzaW5nIHRoZSBsb2dpY2FsIE9SIG9wZXJhdG9yICgnfHwnKS4KICAgKiBBbGwgb3Ro
ZXIgcHJlZGljYXRlcyBtdXN0IGJlIGpvaW5lZCB1c2luZyB0aGUgbG9naWNhbCBBTkQgb3Bl
cmF0b3IKICAgICAoYCYmYCkuCiAgICogQSBwcmVkaWNhdGUgb24gYSB0aW1lIGRpbWVuc2lv
biAoZS5nLiwgYGRheWApIHNwZWNpZnlpbmcgdGhlIHN0YXJ0IHRpbWUKICAgICBtdXN0IHVz
ZSBhIGdyZWF0ZXItdGhhbi1vci1lcXVhbC10byBjb21wYXJpc29uIChgPj1gKS4KICAgKiBB
IHByZWRpY2F0ZSBvbiBhIHRpbWUgZGltZW5zaW9uIHNwZWNpZnlpbmcgdGhlIGVuZCB0aW1l
IG11c3QgdXNlIGEKICAgICBsZXNzLXRoYW4gY29tcGFyaXNvbiAoYDxgKS4KCiBFeGFtcGxl
czoKCiAgIDEuIEZpbHRlciBieSBhIHNwZWNpZmljIHJlc291cmNlIHR5cGU6CiAgICAgIGAi
cmVzb3VyY2VfdHlwZSA9PSAnY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZSciYAoK
ICAgMi4gRmlsdGVyIGRhdGEgcG9pbnRzIHRoYXQgZmFsbCB3aXRoaW4gYSBzcGVjaWZpYyBh
YnNvbHV0ZSB0aW1lIGludGVydmFsOgogICAgICBgImhvdXIgPj0gdGltZXN0YW1wKCcyMDI0
LTAxLTAxVDAwOjAwOjAwWicpICYmCiAgICAgIGhvdXIgPCB0aW1lc3RhbXAoJzIwMjQtMDIt
MDFUMDA6MDA6MDBaJykiYAoKICAgMy4gRmlsdGVyIGRhdGEgcG9pbnRzIHRoYXQgZmFsbCB3
aXRoaW4gdGhlIHBhc3QgNzIgaG91cnM6CiAgICAgIGAiaG91ciA+PSBub3cgLSBkdXJhdGlv
bignNzJoJykiYAoKICAgNC4gQ29tYmluZSBzdHJpbmcgcHJlZGljYXRlIHdpdGggdGltZSBp
bnRlcnZhbCBwcmVkaWNhdGU6CiAgICAgIGAiKGxvY2F0aW9uID09ICd1cy1lYXN0MScgfHwg
bG9jYXRpb24gPT0gJ3VzLXdlc3QxJykgJiYKICAgICAgIGhvdXIgPj0gdGltZXN0YW1wKCcy
MDIzLTEyLTAxVDAwOjAwOjAwWicpICYmCiAgICAgICBob3VyIDwgdGltZXN0YW1wKCcyMDI0
LTAyLTAxVDAwOjAwOjAwWicpImAKCiBJZiB0aGUgZmlsdGVyIG9taXRzIHRpbWUgZGltZW5z
aW9ucyAoYG1vbnRoYCwgYGRheWAsIGBob3VyYCksIHRoZSByZXBvcnQKIGRlZmF1bHRzIHRv
IGEgNy1kYXkgcmFuZ2UgZW5kaW5nIGF0IHRoZSBwcmV2aW91cyBQYWNpZmljIFRpbWUgbWlk
bmlnaHQsCiB3aXRoIERheWxpZ2h0IFNhdmluZyBUaW1lIChEU1QpIGFwcGxpZWQuCgogRm9y
IGV4YW1wbGUsIGlmIHRoZSBjdXJyZW50IFBhY2lmaWMgVGltZSBpcyBgMjAyNi0wMS0wNVQx
MjowMDowMGAsCiB0aGUgZGVmYXVsdCByYW5nZSBpcyBgMjAyNS0xMi0yOVQwMDowMDowMGAg
dG8gYDIwMjYtMDEtMDVUMDA6MDA6MDBgIFBhY2lmaWMKIHRpbWUuCgoNCgUEAQIFBRIE6AEC
CAoNCgUEAQIFARIE6AEJDwoNCgUEAQIFAxIE6AESEwoNCgUEAQIFCBIE6AEUPAoQCggEAQIF
CJwIABIE6AEVOworCgIEAhIG7AEAgwIBGh0gU3BlY2lmaWVzIHRoZSByZXBvcnQgc2NvcGUu
CgoLCgMEAgESBOwBCA0KDgoEBAIIABIG7QECggIDCg0KBQQCCAABEgTtAQgNCnEKBAQCAgAS
BvEBBPYBBhphIFJlcXVpcmVkLiBBIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBwcm9qZWN0IHRv
IGZldGNoIGRhdGEgZnJvbS4KCiBGb3JtYXQ6IGAicHJvamVjdHMve3Byb2plY3R9ImAuCgoN
CgUEAgIABRIE8QEECgoNCgUEAgIAARIE8QELEgoNCgUEAgIAAxIE8QEVFgoPCgUEAgIACBIG
8QEX9gEFChAKCAQCAgAInAgAEgTyAQYsChEKBwQCAgAInwgSBvMBBvUBBwqaAQoEBAICARIG
/AEEgQIGGokBIFJlcXVpcmVkLiBBbiBBcHAgSHViIEFwcGxpY2F0aW9uIHRvIGZldGNoIGRh
dGEgZnJvbS4KCiBGb3JtYXQ6CiBgInByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hcHBsaWNhdGlvbnMve2FwcGxpY2F0aW9ufSJgLgoKDQoFBAICAQUSBPwBBAoK
DQoFBAICAQESBPwBCxYKDQoFBAICAQMSBPwBGRoKDwoFBAICAQgSBvwBG4ECBQoQCggEAgIB
CJwIABIE/QEGLAoRCgcEAgIBCJ8IEgb+AQaAAgcKOwoCBAMSBoYCAJACARotIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgdGhlIGBHZXRSZXBvcnRgIG1ldGhvZC4KCgsKAwQDARIEhgIIGAqIAQoE
BAMCABIGigICjwIEGnggUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXBvcnQgdG8gcmV0
cmlldmUuCgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3JlcG9ydHMve3JlcG9ydF9pZH1gLgoKDQoFBAMCAAUSBIoCAggKDQoFBAMCAAESBIoC
CQ0KDQoFBAMCAAMSBIoCEBEKDwoFBAMCAAgSBooCEo8CAwoQCggEAwIACJwIABIEiwIEKgoR
CgcEAwIACJ8IEgaMAgSOAgUKPQoCBAQSBpMCAKkCARovIFJlcXVlc3QgbWVzc2FnZSBmb3Ig
dGhlIGBMaXN0UmVwb3J0c2AgbWV0aG9kLgoKCwoDBAQBEgSTAggaCoMBCgQEBAIAEgaXAgKc
AgQacyBSZXF1aXJlZC4gVGhlIHBhcmVudCBwcm9qZWN0IHdob3NlIHJlcG9ydHMgYXJlIHRv
IGJlIGxpc3RlZC4KCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn1gLgoKDQoFBAQCAAUSBJcCAggKDQoFBAQCAAESBJcCCQ8KDQoFBAQCAAMSBJcC
EhMKDwoFBAQCAAgSBpcCFJwCAwoQCggEBAIACJwIABIEmAIEKgoRCgcEBAIACJ8IEgaZAgSb
AgUKvgEKBAQEAgESBKECAj8arwEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBy
ZXBvcnRzIHRvIHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0
aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgdGhlIHNlcnZlciB3aWxsIGRldGVybWluZSB0
aGUgbnVtYmVyCiBvZiByZXN1bHRzIHRvIHJldHVybi4KCg0KBQQEAgEFEgShAgIHCg0KBQQE
AgEBEgShAggRCg0KBQQEAgEDEgShAhQVCg0KBQQEAgEIEgShAhY+ChAKCAQEAgEInAgAEgSh
Ahc9CvkBCgQEBAICEgSoAgJBGuoBIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVk
IGZyb20gYSBwcmV2aW91cyBgTGlzdFJlcG9ydHNgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8g
cmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBv
dGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0UmVwb3J0c2AgbXVzdCBtYXRjaAog
dGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQEAgIFEgSoAgII
Cg0KBQQEAgIBEgSoAgkTCg0KBQQEAgIDEgSoAhYXCg0KBQQEAgIIEgSoAhhAChAKCAQEAgII
nAgAEgSoAhk/Cj4KAgQFEgasAgCzAgEaMCBSZXNwb25zZSBtZXNzYWdlIGZvciB0aGUgYExp
c3RSZXBvcnRzYCBtZXRob2QuCgoLCgMEBQESBKwCCBsKJAoEBAUCABIErgICHhoWIFRoZSBs
aXN0IG9mIHJlcG9ydHMuCgoNCgUEBQIABBIErgICCgoNCgUEBQIABhIErgILEQoNCgUEBQIA
ARIErgISGQoNCgUEBQIAAxIErgIcHQqLAQoEBAUCARIEsgICHRp9IEEgdG9rZW4gdGhhdCBj
YW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4K
IElmIHRoaXMgZmllbGQgaXMgZW1wdHksIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2Vz
LgoKDQoFBAUCAQUSBLICAggKDQoFBAUCAQESBLICCRgKDQoFBAUCAQMSBLICGxwKPgoCBAYS
BrYCAMQCARowIFJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBEZWxldGVSZXBvcnRgIG1ldGhv
ZC4KCgsKAwQGARIEtgIIGwqGAQoEBAYCABIGugICvwIEGnYgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSByZXBvcnQgdG8gZGVsZXRlLgoKIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9yZXBvcnRzL3tyZXBvcnRfaWR9YC4KCg0KBQQGAgAF
EgS6AgIICg0KBQQGAgABEgS6AgkNCg0KBQQGAgADEgS6AhARCg8KBQQGAgAIEga6AhK/AgMK
EAoIBAYCAAicCAASBLsCBCoKEQoHBAYCAAifCBIGvAIEvgIFCosBCgQEBgIBEgTDAgJCGn0g
T3B0aW9uYWwuIElmIHNldCB0byB0cnVlLCBhbmQgdGhlIHJlcG9ydCBpcyBub3QgZm91bmQs
IHRoZSByZXF1ZXN0IHdpbGwKIHN1Y2NlZWQgYnV0IG5vIGFjdGlvbiB3aWxsIGJlIHRha2Vu
IG9uIHRoZSBzZXJ2ZXIuCgoNCgUEBgIBBRIEwwICBgoNCgUEBgIBARIEwwIHFAoNCgUEBgIB
AxIEwwIXGAoNCgUEBgIBCBIEwwIZQQoQCggEBgIBCJwIABIEwwIaQAo8CgIEBxIGxwIA3QIB
Gi4gUmVxdWVzdCBtZXNzYWdlIGZvciB0aGUgYFJlYWRSZXBvcnRgIG1ldGhvZC4KCgsKAwQH
ARIExwIIGQqOAQoEBAcCABIGywIC0AIEGn4gUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSByZXBvcnQgdG8gcXVlcnkuCgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9ydHMve3JlcG9ydF9pZH1gLgoKDQoFBAcCAAUS
BMsCAggKDQoFBAcCAAESBMsCCQ0KDQoFBAcCAAMSBMsCEBEKDwoFBAcCAAgSBssCEtACAwoQ
CggEBwIACJwIABIEzAIEKgoRCgcEBwIACJ8IEgbNAgTPAgUKgAIKBAQHAgESBNYCAj8a8QEg
T3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiByb3dzIHRvIHJldHVybi4gVGhlIHNl
cnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmll
ZCwgYXQgbW9zdCAxMCwwMDAgcm93cyB3aWxsIGJlIHJldHVybmVkCiBwZXIgcGFnZS4gVGhl
IG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyAyNSwwMDA7IHZhbHVlcyBhYm92ZSAyNSwwMDAg
YXJlCiBjb2VyY2VkIHRvIDI1LDAwMC4KCg0KBQQHAgEFEgTWAgIHCg0KBQQHAgEBEgTWAggR
Cg0KBQQHAgEDEgTWAhQVCg0KBQQHAgEIEgTWAhY+ChAKCAQHAgEInAgAEgTWAhc9CpACCgQE
BwICEgTcAgJBGoECIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBw
cmV2aW91cyBgUmVhZFJlcG9ydGAgY2FsbCwgdG8KIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50
IHBhZ2Ugb2YgcmVzdWx0cy4gV2hlbiBgcGFnZV90b2tlbmAgaXMgc3BlY2lmaWVkLAogYGpv
Yl9yZWZlcmVuY2VgIG11c3QgYWxzbyBiZSBwcm92aWRlZCBmcm9tIHRoZSBwcmV2aW91cyBy
ZXNwb25zZSwgYW5kIHRoZQogYHN0YXRlbWVudGAgZmllbGQgbXVzdCBub3QgYmUgc2V0LgoK
DQoFBAcCAgUSBNwCAggKDQoFBAcCAgESBNwCCRMKDQoFBAcCAgMSBNwCFhcKDQoFBAcCAggS
BNwCGEAKEAoIBAcCAgicCAASBNwCGT8KPQoCBAgSBuACAOsCARovIFJlc3BvbnNlIG1lc3Nh
Z2UgZm9yIHRoZSBgUmVhZFJlcG9ydGAgbWV0aG9kLgoKCwoDBAgBEgTgAggaClMKBAQIAgAS
BOICAi4aRSBBIGxpc3Qgb2Ygcm93cywgd2hlcmUgZWFjaCByb3cgcmVwcmVzZW50cyBhIHJl
Y29yZCBmcm9tIHRoZSByZXBvcnQuCgoNCgUECAIABBIE4gICCgoNCgUECAIABhIE4gILJAoN
CgUECAIAARIE4gIlKQoNCgUECAIAAxIE4gIsLQpVCgQECAIBEgTlAgIeGkcgVGhlIGNvbHVt
bnMgZGVzY3JpYmluZyB0aGUgc3RydWN0dXJlIG9mIHRoZSBkYXRhIGluIHRoZSBgcm93c2Ag
ZmllbGQuCgoNCgUECAIBBBIE5QICCgoNCgUECAIBBhIE5QILEQoNCgUECAIBARIE5QISGQoN
CgUECAIBAxIE5QIcHQq6AQoEBAgCAhIE6gICHRqrASBBIHRva2VuIHRoYXQgY2FuIGJlIHNl
bnQgYXMgYHBhZ2VfdG9rZW5gIGluIGEgc3Vic2VxdWVudCBgUmVhZFJlcG9ydGAKIHJlcXVl
c3QgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBJZiB0aGlzIGZpZWxk
IGlzIGVtcHR5LAogdGhlcmUgYXJlIG5vIGZ1cnRoZXIgcGFnZXMuCgoNCgUECAICBRIE6gIC
CAoNCgUECAICARIE6gIJGAoNCgUECAICAxIE6gIbHAo7CgIECRIG7gIAlAMBGi0gRGVzY3Jp
YmVzIGEgc2luZ2xlIGNvbHVtbiB3aXRoaW4gYENvbHVtbnNgLgoKCwoDBAkBEgTuAggOCtoB
CgQECQIAEgT2AgISGssBIFRoZSBuYW1lIG9mIHRoZSBjb2x1bW4uCgogVGhpcyBmaWVsZDoK
CiAgICogQ29udGFpbnMgb25seSBsZXR0ZXJzIChhLXosIEEtWiksIG51bWJlcnMgKDAtOSks
IG9yIHVuZGVyc2NvcmVzIChfKTsKICAgKiBTdGFydCB3aXRoIGEgbGV0dGVyIG9yIHVuZGVy
c2NvcmU7IGFuZAogICAqIEhhcyBhIG1heGltdW0gbGVuZ3RoIGlzIDEyOCBjaGFyYWN0ZXJz
LgoKDQoFBAkCAAUSBPYCAggKDQoFBAkCAAESBPYCCQ0KDQoFBAkCAAMSBPYCEBEKlwIKBAQJ
AgESBIUDAhIaiAIgVGhlIGRhdGEgdHlwZSBvZiB0aGUgY29sdW1uLgoKIFN1cHBvcnRlZCB2
YWx1ZXMgaW5jbHVkZToKCiAgICogYFNUUklOR2AKICAgKiBgSU5UNjRgCiAgICogYEZMT0FU
NjRgCiAgICogYEJPT0xFQU5gCiAgICogYFRJTUVTVEFNUGAKICAgKiBgUkVDT1JEYAoKIGBS
RUNPUkRgIGluZGljYXRlcyB0aGF0IHRoZSBmaWVsZCBjb250YWlucyBhIG5lc3RlZCBzY2hl
bWEsIGRlc2NyaWJlZCBpbgogdGhlIGBjb2x1bW5zYCBwcm9wZXJ0eSBvZiB0aGlzIGBDb2x1
bW5gLgoKDQoFBAkCAQUSBIUDAggKDQoFBAkCAQESBIUDCQ0KDQoFBAkCAQMSBIUDEBEKkwIK
BAQJAgISBI8DAhIahAIgVGhlIG1vZGUgb2YgdGhlIGNvbHVtbiwgaW5kaWNhdGluZyBpZiBp
dCBpcyBudWxsYWJsZSwgcmVxdWlyZWQsIG9yCiByZXBlYXRlZC4KCiBQb3NzaWJsZSB2YWx1
ZXM6CgogICAqIGBOVUxMQUJMRWA6IFRoZSBjb2x1bW4gYWxsb3dzIE5VTEwgdmFsdWVzLgog
ICAqIGBSRVFVSVJFRGA6IFRoZSBjb2x1bW4gZG9lcyBub3QgYWxsb3cgTlVMTCB2YWx1ZXMu
CiAgICogYFJFUEVBVEVEYDogVGhlIGNvbHVtbiBjb250YWlucyBhbiBhcnJheSBvZiB2YWx1
ZXMuCgoNCgUECQICBRIEjwMCCAoNCgUECQICARIEjwMJDQoNCgUECQICAxIEjwMQEQppCgQE
CQIDEgSTAwIeGlsgSWYgdGhlIGB0eXBlYCBvZiB0aGlzIGNvbHVtbiBpcyBgUkVDT1JEYCwg
dGhpcyBzdWItZmllbGQgZGVzY3JpYmVzIHRoZQogbmVzdGVkIHN0cnVjdHVyZS4KCg0KBQQJ
AgMEEgSTAwIKCg0KBQQJAgMGEgSTAwsRCg0KBQQJAgMBEgSTAxIZCg0KBQQJAgMDEgSTAxwd
CpMBCgIEChIEmAMAHBqGASBSZXByZXNlbnRzIG1ldGFkYXRhIHJlbGF0ZWQgdG8gdGhlIGNy
ZWF0aW9uIG9mIGEgUmVwb3J0LiBUaGlzIHZhbHVlIGlzCiBlbWJlZGRlZCBpbiB0aGUgT3Bl
cmF0aW9uIG9iamVjdCByZXR1cm5lZCBieSBgQ3JlYXRlUmVwb3J0YC4KCgsKAwQKARIEmAMI
GWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest ===
    # Fields for CreateReportRequest
    # Field: parent Type: 9 ()
    # Field: report_id Type: 9 ()
    # Field: report Type: 11 (.google.cloud.appoptimize.v1beta.Report)

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::Report ===
    # Fields for Report
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: name Type: 9 ()
    # Field: dimensions Type: 9 ()
    # Field: metrics Type: 9 ()
    # Field: scopes Type: 11 (.google.cloud.appoptimize.v1beta.Scope)
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope ===
    # Fields for Scope
    # Field: project Type: 9 ()
    # Field: application Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest ===
    # Fields for GetReportRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest ===
    # Fields for ListReportsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse ===
    # Fields for ListReportsResponse
    # Field: reports Type: 11 (.google.cloud.appoptimize.v1beta.Report)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest ===
    # Fields for DeleteReportRequest
    # Field: name Type: 9 ()
    # Field: allow_missing Type: 8 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest ===
    # Fields for ReadReportRequest
    # Field: name Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse ===
    # Fields for ReadReportResponse
    # Field: rows Type: 11 (.google.protobuf.ListValue)
    # Field: columns Type: 11 (.google.cloud.appoptimize.v1beta.Column)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::Column ===
    # Fields for Column
    # Field: name Type: 9 ()
    # Field: type Type: 9 ()
    # Field: mode Type: 9 ()
    # Field: columns Type: 11 (.google.cloud.appoptimize.v1beta.Column)

# === Message: Google::Cloud::Appoptimize::V1beta::AppOptimize::OperationMetadata ===
    # Fields for OperationMetadata

# === Service Client: Google::Cloud::Appoptimize::V1beta::AppOptimize::AppOptimizeClient ===
package Google::Cloud::Appoptimize::V1beta::AppOptimize::AppOptimizeClient;

=pod

=head2 Service Client: Google::Cloud::Appoptimize::V1beta::AppOptimize::AppOptimizeClient

Client stub representing the remote C<AppOptimize> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<appoptimize.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'appoptimize.googleapis.com:443' );

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

sub create_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.appoptimize.v1beta.AppOptimize',
        method         => 'CreateReport',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.appoptimize.v1beta.AppOptimize',
        method         => 'GetReport',
        request        => $req,
        response_class => 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Report',
    });
}

sub list_reports {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.appoptimize.v1beta.AppOptimize',
        method         => 'ListReports',
        request        => $req,
        response_class => 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse',
    });
}

sub delete_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.appoptimize.v1beta.AppOptimize',
        method         => 'DeleteReport',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub read_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.appoptimize.v1beta.AppOptimize',
        method         => 'ReadReport',
        request        => $req,
        response_class => 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Appoptimize::V1beta::AppOptimize - Compiled Protocol Buffers messages for google/cloud/appoptimize/v1beta/app_optimize.proto

=head1 SYNOPSIS

    use Google::Cloud::Appoptimize::V1beta::AppOptimize;

    my $msg = Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest->new({
        parent => $parent,
        report_id => $report_id,
        report => $report,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/appoptimize/v1beta/app_optimize.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest

Request message for the `CreateReport` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent Google Cloud project that will own the report.

This value does not define the scope of the report data. See `Report.scope`
for setting the data scope.

Format: `projects/{project}/locations/{location}`.

=item * C<< $msg->report_id() >> / C<< $msg->report_id($value) >>

Type: C<String>

Required. The ID to use for this report. This ID must be unique within
the parent project and should comply with RFC 1034 restrictions (letters,
numbers, and hyphen, with the first character a letter, the last a letter
or a number, and a 63 character maximum).

=item * C<< $msg->report() >> / C<< $msg->report($value) >>

Type: C<Message> (L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Report>)

Required. The report resource to create.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::Report

A configuration that defines the parameters for the data represented by a
report.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp in UTC of when this report expires. Once the
report expires, it will no longer be accessible and the report's
underlying data will be deleted.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of this report.

=item * C<< $msg->dimensions() >> / C<< $msg->dimensions($value) >>

Type: C<String>

Required. A list of dimensions to include in the report. Supported values:

  * `project`
  * `application`
  * `service_or_workload`
  * `resource`
  * `resource_type`
  * `location`
  * `product_display_name`
  * `sku`
  * `month`
  * `day`
  * `hour`

To aggregate results by time, specify at least one time dimension
(`month`, `day`, or `hour`). All time dimensions use Pacific Time,
respect Daylight Saving Time (DST), and follow these ISO 8601 formats:

  * `month`: `YYYY-MM` (e.g., `2024-01`)
  * `day`: `YYYY-MM-DD` (e.g., `2024-01-10`)
  * `hour`: `YYYY-MM-DDTHH` (e.g., `2024-01-10T00`)

If the time range filter does not align with the selected time dimension,
the range is expanded to encompass the full period of the finest-grained
time dimension.

For example, if the filter is `2026-01-10` through `2026-01-12` and the
`month` dimension is selected, the effective time range expands to include
all of January (`2026-01-01` to `2026-02-01`).

=item * C<< $msg->metrics() >> / C<< $msg->metrics($value) >>

Type: C<String>

Required. A list of metrics to include in the report. Supported values:

  * `cost`
  * `cpu_mean_utilization`
  * `cpu_usage_core_seconds`
  * `cpu_allocation_core_seconds`
  * `cpu_p95_utilization`
  * `memory_mean_utilization`
  * `memory_usage_byte_seconds`
  * `memory_allocation_byte_seconds`
  * `memory_p95_utilization`

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<Message> (L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope>)

Optional. The resource containers for which to fetch data. Default is the
project specified in the report's parent.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A Common Expression Language (CEL) expression used to filter the
data for the report.

Predicates may refer to any dimension. Filtering must conform to these
constraints:

  * All string field predicates must use exact string matches.
  * Multiple predicates referring to the same string field must be joined
    using the logical OR operator ('||').
  * All other predicates must be joined using the logical AND operator
    (`&&`).
  * A predicate on a time dimension (e.g., `day`) specifying the start time
    must use a greater-than-or-equal-to comparison (`>=`).
  * A predicate on a time dimension specifying the end time must use a
    less-than comparison (`<`).

Examples:

  1. Filter by a specific resource type:
     `"resource_type == 'compute.googleapis.com/Instance'"`

  2. Filter data points that fall within a specific absolute time interval:
     `"hour >= timestamp('2024-01-01T00:00:00Z') &&
     hour < timestamp('2024-02-01T00:00:00Z')"`

  3. Filter data points that fall within the past 72 hours:
     `"hour >= now - duration('72h')"`

  4. Combine string predicate with time interval predicate:
     `"(location == 'us-east1' || location == 'us-west1') &&
      hour >= timestamp('2023-12-01T00:00:00Z') &&
      hour < timestamp('2024-02-01T00:00:00Z')"`

If the filter omits time dimensions (`month`, `day`, `hour`), the report
defaults to a 7-day range ending at the previous Pacific Time midnight,
with Daylight Saving Time (DST) applied.

For example, if the current Pacific Time is `2026-01-05T12:00:00`,
the default range is `2025-12-29T00:00:00` to `2026-01-05T00:00:00` Pacific
time.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope

Specifies the report scope.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. A Google Cloud Platform project to fetch data from.

Format: `"projects/{project}"`.

=item * C<< $msg->application() >> / C<< $msg->application($value) >>

Type: C<String>

Required. An App Hub Application to fetch data from.

Format:
`"projects/{project}/locations/{location}/applications/{application}"`.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest

Request message for the `GetReport` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the report to retrieve.

Format: `projects/{project}/locations/{location}/reports/{report_id}`.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest

Request message for the `ListReports` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent project whose reports are to be listed.

Format: `projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of reports to return. The service may return
fewer than this value. If unspecified, the server will determine the number
of results to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListReports` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListReports` must match
the call that provided the page token.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse

Response message for the `ListReports` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reports() >> / C<< $msg->reports($value) >>

Type: C<Message> (L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Report>)

The list of reports.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is empty, there are no subsequent pages.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest

Request message for the `DeleteReport` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the report to delete.

Format: `projects/{project}/locations/{location}/reports/{report_id}`.

=item * C<< $msg->allow_missing() >> / C<< $msg->allow_missing($value) >>

Type: C<Bool>

Optional. If set to true, and the report is not found, the request will
succeed but no action will be taken on the server.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest

Request message for the `ReadReport` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the report to query.

Format: `projects/{project}/locations/{location}/reports/{report_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of rows to return. The service may return
fewer than this value. If unspecified, at most 10,000 rows will be returned
per page. The maximum allowed value is 25,000; values above 25,000 are
coerced to 25,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ReadReport` call, to
retrieve the subsequent page of results. When `page_token` is specified,
`job_reference` must also be provided from the previous response, and the
`statement` field must not be set.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse

Response message for the `ReadReport` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::ListValue>)

A list of rows, where each row represents a record from the report.

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Column>)

The columns describing the structure of the data in the `rows` field.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` in a subsequent `ReadReport`
request to retrieve the next page of results. If this field is empty,
there are no further pages.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::Column

Describes a single column within `Columns`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the column.

This field:

  * Contains only letters (a-z, A-Z), numbers (0-9), or underscores (_);
  * Start with a letter or underscore; and
  * Has a maximum length is 128 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

The data type of the column.

Supported values include:

  * `STRING`
  * `INT64`
  * `FLOAT64`
  * `BOOLEAN`
  * `TIMESTAMP`
  * `RECORD`

`RECORD` indicates that the field contains a nested schema, described in
the `columns` property of this `Column`.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<String>

The mode of the column, indicating if it is nullable, required, or
repeated.

Possible values:

  * `NULLABLE`: The column allows NULL values.
  * `REQUIRED`: The column does not allow NULL values.
  * `REPEATED`: The column contains an array of values.

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Column>)

If the `type` of this column is `RECORD`, this sub-field describes the
nested structure.

=back

=head2 Google::Cloud::Appoptimize::V1beta::AppOptimize::OperationMetadata

Represents metadata related to the creation of a Report. This value is
embedded in the Operation object returned by `CreateReport`.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Appoptimize::V1beta::AppOptimize::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
