package Google::Cloud::Ces::V1::ToolService;

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
    eval { require Google::Cloud::Ces::V1::Schema };
    eval { require Google::Cloud::Ces::V1::SearchSuggestions };
    eval { require Google::Cloud::Ces::V1::SessionService };
    eval { require Google::Cloud::Ces::V1::Tool };
    eval { require Google::Cloud::Ces::V1::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2xfc2VydmljZS5wcm90bxITZ29vZ2xlLmNsb3Vk
LmNlcy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aIGdvb2dsZS9jbG91ZC9jZXMvdjEvc2NoZW1hLnByb3RvGixnb29n
bGUvY2xvdWQvY2VzL3YxL3NlYXJjaF9zdWdnZXN0aW9ucy5wcm90bxopZ29vZ2xlL2Nsb3Vk
L2Nlcy92MS9zZXNzaW9uX3NlcnZpY2UucHJvdG8aHmdvb2dsZS9jbG91ZC9jZXMvdjEvdG9v
bC5wcm90bxomZ29vZ2xlL2Nsb3VkL2Nlcy92MS90b29sc2V0X3Rvb2wucHJvdG8aHGdvb2ds
ZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8i7QMKEkV4ZWN1dGVUb29sUmVxdWVzdBI1CgR0b29s
GAEgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sSABSBHRvb2wSSgoMdG9v
bHNldF90b29sGAMgASgLMiAuZ29vZ2xlLmNsb3VkLmNlcy52MS5Ub29sc2V0VG9vbEID4EEB
SABSC3Rvb2xzZXRUb29sEjwKCXZhcmlhYmxlcxgFIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5T
dHJ1Y3RCA+BBAUgBUgl2YXJpYWJsZXMSOAoHY29udGV4dBgGIAEoCzIXLmdvb2dsZS5wcm90
b2J1Zi5TdHJ1Y3RCA+BBAUgBUgdjb250ZXh0EjYKBnBhcmVudBgEIAEoCUIe4EEC+kEYChZj
ZXMuZ29vZ2xlYXBpcy5jb20vQXBwUgZwYXJlbnQSMAoEYXJncxgCIAEoCzIXLmdvb2dsZS5w
cm90b2J1Zi5TdHJ1Y3RCA+BBAVIEYXJncxJFCgttb2NrX2NvbmZpZxgHIAEoCzIfLmdvb2ds
ZS5jbG91ZC5jZXMudjEuTW9ja0NvbmZpZ0ID4EEBUgptb2NrQ29uZmlnQhEKD3Rvb2xfaWRl
bnRpZmllckIYChZ0b29sX2V4ZWN1dGlvbl9jb250ZXh0IrcDChNFeGVjdXRlVG9vbFJlc3Bv
bnNlEjIKBHRvb2wYASABKAlCHPpBGQoXY2VzLmdvb2dsZWFwaXMuY29tL1Rvb2xIAFIEdG9v
bBJFCgx0b29sc2V0X3Rvb2wYAyABKAsyIC5nb29nbGUuY2xvdWQuY2VzLnYxLlRvb2xzZXRU
b29sSABSC3Rvb2xzZXRUb29sEjMKCHJlc3BvbnNlGAIgASgLMhcuZ29vZ2xlLnByb3RvYnVm
LlN0cnVjdFIIcmVzcG9uc2USNQoJdmFyaWFibGVzGAQgASgLMhcuZ29vZ2xlLnByb3RvYnVm
LlN0cnVjdFIJdmFyaWFibGVzEjwKCWNpdGF0aW9ucxgFIAEoCzIeLmdvb2dsZS5jbG91ZC5j
ZXMudjEuQ2l0YXRpb25zUgljaXRhdGlvbnMSaAoZZ29vZ2xlX3NlYXJjaF9zdWdnZXN0aW9u
cxgGIAEoCzIsLmdvb2dsZS5jbG91ZC5jZXMudjEuR29vZ2xlU2VhcmNoU3VnZ2VzdGlvbnNS
F2dvb2dsZVNlYXJjaFN1Z2dlc3Rpb25zQhEKD3Rvb2xfaWRlbnRpZmllciLpAQoZUmV0cmll
dmVUb29sU2NoZW1hUmVxdWVzdBI1CgR0b29sGAEgASgJQh/gQQH6QRkKF2Nlcy5nb29nbGVh
cGlzLmNvbS9Ub29sSABSBHRvb2wSSgoMdG9vbHNldF90b29sGAIgASgLMiAuZ29vZ2xlLmNs
b3VkLmNlcy52MS5Ub29sc2V0VG9vbEID4EEBSABSC3Rvb2xzZXRUb29sEjYKBnBhcmVudBgD
IAEoCUIe4EEC+kEYChZjZXMuZ29vZ2xlYXBpcy5jb20vQXBwUgZwYXJlbnRCEQoPdG9vbF9p
ZGVudGlmaWVyIqwCChpSZXRyaWV2ZVRvb2xTY2hlbWFSZXNwb25zZRIyCgR0b29sGAEgASgJ
Qhz6QRkKF2Nlcy5nb29nbGVhcGlzLmNvbS9Ub29sSABSBHRvb2wSRQoMdG9vbHNldF90b29s
GAIgASgLMiAuZ29vZ2xlLmNsb3VkLmNlcy52MS5Ub29sc2V0VG9vbEgAUgt0b29sc2V0VG9v
bBI+CgxpbnB1dF9zY2hlbWEYAyABKAsyGy5nb29nbGUuY2xvdWQuY2VzLnYxLlNjaGVtYVIL
aW5wdXRTY2hlbWESQAoNb3V0cHV0X3NjaGVtYRgEIAEoCzIbLmdvb2dsZS5jbG91ZC5jZXMu
djEuU2NoZW1hUgxvdXRwdXRTY2hlbWFCEQoPdG9vbF9pZGVudGlmaWVyIrUBChRSZXRyaWV2
ZVRvb2xzUmVxdWVzdBI8Cgd0b29sc2V0GAEgASgJQiLgQQL6QRwKGmNlcy5nb29nbGVhcGlz
LmNvbS9Ub29sc2V0Ugd0b29sc2V0Eh4KCHRvb2xfaWRzGAMgAygJQgPgQQFSB3Rvb2xJZHMS
PwoZYnlwYXNzX3BlcnNpc3RlbmNlX2NvbmZpZxgEIAEoCEID4EEBUhdieXBhc3NQZXJzaXN0
ZW5jZUNvbmZpZyJIChVSZXRyaWV2ZVRvb2xzUmVzcG9uc2USLwoFdG9vbHMYASADKAsyGS5n
b29nbGUuY2xvdWQuY2VzLnYxLlRvb2xSBXRvb2xzMpsFCgtUb29sU2VydmljZRKjAQoLRXhl
Y3V0ZVRvb2wSJy5nb29nbGUuY2xvdWQuY2VzLnYxLkV4ZWN1dGVUb29sUmVxdWVzdBooLmdv
b2dsZS5jbG91ZC5jZXMudjEuRXhlY3V0ZVRvb2xSZXNwb25zZSJBgtPkkwI7IjYvdjEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2FwcHMvKn06ZXhlY3V0ZVRvb2w6ASoSvwEK
ElJldHJpZXZlVG9vbFNjaGVtYRIuLmdvb2dsZS5jbG91ZC5jZXMudjEuUmV0cmlldmVUb29s
U2NoZW1hUmVxdWVzdBovLmdvb2dsZS5jbG91ZC5jZXMudjEuUmV0cmlldmVUb29sU2NoZW1h
UmVzcG9uc2UiSILT5JMCQiI9L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9h
cHBzLyp9OnJldHJpZXZlVG9vbFNjaGVtYToBKhK3AQoNUmV0cmlldmVUb29scxIpLmdvb2ds
ZS5jbG91ZC5jZXMudjEuUmV0cmlldmVUb29sc1JlcXVlc3QaKi5nb29nbGUuY2xvdWQuY2Vz
LnYxLlJldHJpZXZlVG9vbHNSZXNwb25zZSJPgtPkkwJJIkQvdjEve3Rvb2xzZXQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9hcHBzLyovdG9vbHNldHMvKn06cmV0cmlldmVUb29sczoBKhpq
ykESY2VzLmdvb2dsZWFwaXMuY29t0kFSaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jZXMsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUJY
Chdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIQVG9vbFNlcnZpY2VQcm90b1ABWiljbG91ZC5n
b29nbGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkrrOgoHEgUOAN4BAQq8BAoBDBID
DgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUg
QXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkg
bm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5z
ZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRw
Oi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWly
ZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJl
CiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAi
QVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5Z
IEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9y
IHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1p
dGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMB
EgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACoKCQoCAwUSAxcANgoJCgID
BhIDGAAzCgkKAgMHEgMZACgKCQoCAwgSAxoAMAoJCgIDCRIDGwAmCggKAQgSAx0AQAoJCgII
CxIDHQBACggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8AMQoJCgIICBIDHwAxCggKAQgS
AyAAMAoJCgIIARIDIAAwCkgKAgYAEgQjAEIBGjwgVG9vbCBzZXJ2aWNlIHByb3ZpZGVzIEFQ
SXMgZm9yIGludGVyYWN0aW5nIHdpdGggQ0VTIHRvb2xzLgoKCgoDBgABEgMjCBMKCgoDBgAD
EgMkAjoKDAoFBgADmQgSAyQCOgoLCgMGAAMSBCUCJzcKDQoFBgADmggSBCUCJzcKQQoEBgAC
ABIEKgIvAxozIEV4ZWN1dGVzIHRoZSBnaXZlbiB0b29sIHdpdGggdGhlIGdpdmVuIGFyZ3Vt
ZW50cy4KCgwKBQYAAgABEgMqBhEKDAoFBgACAAISAyoSJAoMCgUGAAIAAxIDKi9CCg0KBQYA
AgAEEgQrBC4GChEKCQYAAgAEsMq8IhIEKwQuBgp9CgQGAAIBEgQzAjkDGm8gUmV0cmlldmUg
dGhlIHNjaGVtYSBvZiB0aGUgZ2l2ZW4gdG9vbC4gVGhlIHNjaGVtYSBpcyBjb21wdXRlZCBv
biB0aGUgZmx5CiBmb3IgdGhlIGdpdmVuIGluc3RhbmNlIG9mIHRoZSB0b29sLgoKDAoFBgAC
AQESAzMGGAoMCgUGAAIBAhIDMxkyCgwKBQYAAgEDEgM0DykKDQoFBgACAQQSBDUEOAYKEQoJ
BgACAQSwyrwiEgQ1BDgGCk0KBAYAAgISBDwCQQMaPyBSZXRyaWV2ZSB0aGUgbGlzdCBvZiB0
b29scyBpbmNsdWRlZCBpbiB0aGUgc3BlY2lmaWVkIHRvb2xzZXQuCgoMCgUGAAICARIDPAYT
CgwKBQYAAgICEgM8FCgKDAoFBgACAgMSAzwzSAoNCgUGAAICBBIEPQRABgoRCgkGAAICBLDK
vCISBD0EQAYKagoCBAASBEYAcgEaXiBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVG9vbFNlcnZp
Y2UuRXhlY3V0ZVRvb2xdW2dvb2dsZS5jbG91ZC5jZXMudjEuVG9vbFNlcnZpY2UuRXhlY3V0
ZVRvb2xdLgoKCgoDBAABEgNGCBoKdQoEBAAIABIESQJVAxpnIFRoZSBpZGVudGlmaWVyIG9m
IHRoZSB0b29sIHRvIGV4ZWN1dGUuIEl0IGNvdWxkIGJlIGVpdGhlciBhIHBlcnNpc3RlZCB0
b29sCiBvciBhIHRvb2wgZnJvbSBhIHRvb2xzZXQuCgoMCgUEAAgAARIDSQgXCoQBCgQEAAIA
EgRNBFAGGnYgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSB0b29sIHRvIGV4ZWN1dGUuCiBG
b3JtYXQ6CiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97
YXBwfS90b29scy97dG9vbH0KCgwKBQQAAgAFEgNNBAoKDAoFBAACAAESA00LDwoMCgUEAAIA
AxIDTRITCg0KBQQAAgAIEgRNFFAFCg8KCAQAAgAInAgAEgNOBiwKDgoHBAACAAifCBIDTwZL
CpgBCgQEAAIBEgNUBEoaigEgT3B0aW9uYWwuIFRoZSB0b29sc2V0IHRvb2wgdG8gZXhlY3V0
ZS4gT25seSBvbmUgdG9vbCBzaG91bGQgbWF0Y2ggdGhlCiBwcmVkaWNhdGUgZnJvbSB0aGUg
dG9vbHNldC4gT3RoZXJ3aXNlLCBhbiBlcnJvciB3aWxsIGJlIHJldHVybmVkLgoKDAoFBAAC
AQYSA1QEDwoMCgUEAAIBARIDVBAcCgwKBQQAAgEDEgNUHyAKDAoFBAACAQgSA1QhSQoPCggE
AAIBCJwIABIDVCJICkgKBAQACAESBFgCYQMaOiBBZGRpdGlvbmFsIGNvbnRleHQgdG8gYmUg
cHJvdmlkZWQgZm9yIHRoZSB0b29sIGV4ZWN1dGlvbgoKDAoFBAAIAQESA1gIHgpSCgQEAAIC
EgRaBFsxGkQgT3B0aW9uYWwuIFRoZSB2YXJpYWJsZXMgdGhhdCBhcmUgYXZhaWxhYmxlIGZv
ciB0aGUgdG9vbCBleGVjdXRpb24uCgoMCgUEAAICBhIDWgQaCgwKBQQAAgIBEgNaGyQKDAoF
BAACAgMSA1onKAoMCgUEAAICCBIDWwgwCg8KCAQAAgIInAgAEgNbCS8KxQEKBAQAAgMSA2AE
UBq3ASBPcHRpb25hbC4gVGhlCiBbVG9vbENhbGxDb250ZXh0XShodHRwczovL2RvY3MuY2xv
dWQuZ29vZ2xlLmNvbS9jdXN0b21lci1lbmdhZ2VtZW50LWFpL2NvbnZlcnNhdGlvbmFsLWFn
ZW50cy9wcy90b29sL3B5dGhvbiNlbnZpcm9ubWVudAogZm9yIGRldGFpbHMpIHRvIGJlIHBh
c3NlZCB0byB0aGUgUHl0aG9uIHRvb2wuCgoMCgUEAAIDBhIDYAQaCgwKBQQAAgMBEgNgGyIK
DAoFBAACAwMSA2AlJgoMCgUEAAIDCBIDYCdPCg8KCAQAAgMInAgAEgNgKE4KmAEKBAQAAgQS
BGUCaAQaiQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBhcHAgd2hpY2gg
dGhlIHRvb2wvdG9vbHNldCBiZWxvbmdzIHRvLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH1gCgoMCgUEAAIEBRIDZQIICgwK
BQQAAgQBEgNlCQ8KDAoFBAACBAMSA2USEwoNCgUEAAIECBIEZRRoAwoPCggEAAIECJwIABID
ZgQqCg4KBwQAAgQInwgSA2cESApdCgQEAAIFEgNsAksaUCBPcHRpb25hbC4gVGhlIGlucHV0
IHBhcmFtZXRlcnMgYW5kIHZhbHVlcyBmb3IgdGhlIHRvb2wgaW4gSlNPTiBvYmplY3QKIGZv
cm1hdC4KCgwKBQQAAgUGEgNsAhgKDAoFBAACBQESA2wZHQoMCgUEAAIFAxIDbCAhCgwKBQQA
AgUIEgNsIkoKDwoIBAACBQicCAASA2wjSQq1AQoEBAACBhIDcQJGGqcBIE9wdGlvbmFsLiBN
b2NrIGNvbmZpZ3VyYXRpb24gZm9yIHRoZSB0b29sIGV4ZWN1dGlvbi4KIElmIHRoaXMgZmll
bGQgaXMgc2V0LCB0b29scyB0aGF0IGNhbGwgb3RoZXIgdG9vbHMgd2lsbCBiZQogbW9ja2Vk
IGJhc2VkIG9uIHRoZSBwcm92aWRlZCBwYXR0ZXJucyBhbmQgcmVzcG9uc2VzLgoKDAoFBAAC
BgYSA3ECDAoMCgUEAAIGARIDcQ0YCgwKBQQAAgYDEgNxGxwKDAoFBAACBggSA3EdRQoPCggE
AAIGCJwIABIDcR5ECmwKAgQBEgV2AJEBARpfIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbVG9v
bFNlcnZpY2UuRXhlY3V0ZVRvb2xdW2dvb2dsZS5jbG91ZC5jZXMudjEuVG9vbFNlcnZpY2Uu
RXhlY3V0ZVRvb2xdLgoKCgoDBAEBEgN2CBsKPgoEBAEIABIFeAKAAQMaLyBUaGUgaWRlbnRp
ZmllciBvZiB0aGUgdG9vbCB0aGF0IGdvdCBleGVjdXRlZC4KCgwKBQQBCAABEgN4CBcKggEK
BAQBAgASBHsEfFAadCBUaGUgbmFtZSBvZiB0aGUgdG9vbCB0aGF0IGdvdCBleGVjdXRlZC4K
IEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBz
L3thcHB9L3Rvb2xzL3t0b29sfWAKCgwKBQQBAgAFEgN7BAoKDAoFBAECAAESA3sLDwoMCgUE
AQIAAxIDexITCgwKBQQBAgAIEgN8CE8KDgoHBAECAAifCBIDfAlOCjIKBAQBAgESA38EIRol
IFRoZSB0b29sc2V0IHRvb2wgdGhhdCBnb3QgZXhlY3V0ZWQuCgoMCgUEAQIBBhIDfwQPCgwK
BQQBAgEBEgN/EBwKDAoFBAECAQMSA38fIAqMAgoEBAECAhIEhgECJhr9ASBUaGUgdG9vbCBl
eGVjdXRpb24gcmVzdWx0IGluIEpTT04gb2JqZWN0IGZvcm1hdC4KIFVzZSAib3V0cHV0IiBr
ZXkgdG8gc3BlY2lmeSB0b29sIHJlc3BvbnNlIGFuZCAiZXJyb3IiIGtleSB0byBzcGVjaWZ5
CiBlcnJvciBkZXRhaWxzIChpZiBhbnkpLiBJZiAib3V0cHV0IiBhbmQgImVycm9yIiBrZXlz
IGFyZSBub3Qgc3BlY2lmaWVkLAogdGhlbiB3aG9sZSAicmVzcG9uc2UiIGlzIHRyZWF0ZWQg
YXMgdG9vbCBleGVjdXRpb24gcmVzdWx0LgoKDQoFBAECAgYSBIYBAhgKDQoFBAECAgESBIYB
GSEKDQoFBAECAgMSBIYBJCUKRQoEBAECAxIEiQECJxo3IFRoZSB2YXJpYWJsZSB2YWx1ZXMg
YXQgdGhlIGVuZCBvZiB0aGUgdG9vbCBleGVjdXRpb24uCgoNCgUEAQIDBhIEiQECGAoNCgUE
AQIDARIEiQEZIgoNCgUEAQIDAxIEiQElJgpXCgQEAQIEEgSMAQIaGkkgQ2l0YXRpb25zIHRo
YXQgcHJvdmlkZSB0aGUgc291cmNlIGluZm9ybWF0aW9uIGZvciB0aGUgdG9vbCdzIGV4ZWN1
dGlvbi4KCg0KBQQBAgQGEgSMAQILCg0KBQQBAgQBEgSMAQwVCg0KBQQBAgQDEgSMARgZCoYB
CgQEAQIFEgSQAQI4GnggVGhlIHN1Z2dlc3Rpb25zIHJldHVybmVkIGZyb20gR29vZ2xlIFNl
YXJjaCBhcyBhIHJlc3VsdCBvZiBpbnZva2luZyB0aGUKIEdvb2dsZSBTZWFyY2ggVG9vbCBk
dXJpbmcgdGhlIHRvb2wgZXhlY3V0aW9uLgoKDQoFBAECBQYSBJABAhkKDQoFBAECBQESBJAB
GjMKDQoFBAECBQMSBJABNjcKegoCBAISBpUBAK0BARpsIFJlcXVlc3QgbWVzc2FnZSBmb3IK
IFtUb29sU2VydmljZS5SZXRyaWV2ZVRvb2xTY2hlbWFdW2dvb2dsZS5jbG91ZC5jZXMudjEu
VG9vbFNlcnZpY2UuUmV0cmlldmVUb29sU2NoZW1hXS4KCgsKAwQCARIElQEIIQqHAQoEBAII
ABIGmAECpQEDGncgVGhlIGlkZW50aWZpZXIgb2YgdGhlIHRvb2wgdG8gcmV0cmlldmUgdGhl
IHNjaGVtYSBmb3IuIEl0IGNvdWxkIGJlIGVpdGhlciBhCiBwZXJzaXN0ZWQgdG9vbCBvciBh
IHRvb2wgZnJvbSBhIHRvb2xzZXQuCgoNCgUEAggAARIEmAEIFwqXAQoEBAICABIGnAEEnwEG
GoYBIE9wdGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdG9vbCB0byByZXRyaWV2ZSB0aGUgc2No
ZW1hIGZvci4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfQoKDQoFBAICAAUSBJwBBAoKDQoFBAICAAES
BJwBCw8KDQoFBAICAAMSBJwBEhMKDwoFBAICAAgSBpwBFJ8BBQoQCggEAgIACJwIABIEnQEG
LAoPCgcEAgIACJ8IEgSeAQZLCqoBCgQEAgIBEgSkAQRKGpsBIE9wdGlvbmFsLiBUaGUgdG9v
bHNldCB0b29sIHRvIHJldHJpZXZlIHRoZSBzY2hlbWEgZm9yLiBPbmx5IG9uZSB0b29sCiBz
aG91bGQgbWF0Y2ggdGhlIHByZWRpY2F0ZSBmcm9tIHRoZSB0b29sc2V0LiBPdGhlcndpc2Us
IGFuIGVycm9yIHdpbGwgYmUKIHJldHVybmVkLgoKDQoFBAICAQYSBKQBBA8KDQoFBAICAQES
BKQBEBwKDQoFBAICAQMSBKQBHyAKDQoFBAICAQgSBKQBIUkKEAoIBAICAQicCAASBKQBIkgK
mgEKBAQCAgISBqkBAqwBBBqJASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IGFwcCB3aGljaCB0aGUgdG9vbC90b29sc2V0IGJlbG9uZ3MgdG8uCiBGb3JtYXQ6IGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfWAKCg0KBQQC
AgIFEgSpAQIICg0KBQQCAgIBEgSpAQkPCg0KBQQCAgIDEgSpARITCg8KBQQCAgIIEgapARSs
AQMKEAoIBAICAgicCAASBKoBBCoKDwoHBAICAgifCBIEqwEESAp7CgIEAxIGsQEAwgEBGm0g
UmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtUb29sU2VydmljZS5SZXRyaWV2ZVRvb2xTY2hlbWFd
W2dvb2dsZS5jbG91ZC5jZXMudjEuVG9vbFNlcnZpY2UuUmV0cmlldmVUb29sU2NoZW1hXS4K
CgsKAwQDARIEsQEIIgpECgQEAwgAEgazAQK7AQMaNCBUaGUgaWRlbnRpZmllciBvZiB0aGUg
dG9vbCB0aGF0IHRoZSBzY2hlbWEgaXMgZm9yLgoKDQoFBAMIAAESBLMBCBcKiQEKBAQDAgAS
BrYBBLcBUBp5IFRoZSBuYW1lIG9mIHRoZSB0b29sIHRoYXQgdGhlIHNjaGVtYSBpcyBmb3Iu
CiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBw
cy97YXBwfS90b29scy97dG9vbH1gCgoNCgUEAwIABRIEtgEECgoNCgUEAwIAARIEtgELDwoN
CgUEAwIAAxIEtgESEwoNCgUEAwIACBIEtwEITwoPCgcEAwIACJ8IEgS3AQlOCjgKBAQDAgES
BLoBBCEaKiBUaGUgdG9vbHNldCB0b29sIHRoYXQgdGhlIHNjaGVtYSBpcyBmb3IuCgoNCgUE
AwIBBhIEugEEDwoNCgUEAwIBARIEugEQHAoNCgUEAwIBAxIEugEfIAo4CgQEAwICEgS+AQIa
GiogVGhlIHNjaGVtYSBvZiB0aGUgdG9vbCBpbnB1dCBwYXJhbWV0ZXJzLgoKDQoFBAMCAgYS
BL4BAggKDQoFBAMCAgESBL4BCRUKDQoFBAMCAgMSBL4BGBkKOQoEBAMCAxIEwQECGxorIFRo
ZSBzY2hlbWEgb2YgdGhlIHRvb2wgb3V0cHV0IHBhcmFtZXRlcnMuCgoNCgUEAwIDBhIEwQEC
CAoNCgUEAwIDARIEwQEJFgoNCgUEAwIDAxIEwQEZGgpwCgIEBBIGxgEA1wEBGmIgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW1Rvb2xTZXJ2aWNlLlJldHJpZXZlVG9vbHNdW2dvb2dsZS5jbG91
ZC5jZXMudjEuVG9vbFNlcnZpY2UuUmV0cmlldmVUb29sc10uCgoLCgMEBAESBMYBCBwKoQEK
BAQEAgASBsoBAs0BBBqQASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHRvb2xzZXQgdG8g
cmV0cmlldmUgdGhlIHRvb2xzIGZvci4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1gCgoN
CgUEBAIABRIEygECCAoNCgUEBAIAARIEygEJEAoNCgUEBAIAAxIEygETFAoPCgUEBAIACBIG
ygEVzQEDChAKCAQEAgAInAgAEgTLAQQqCg8KBwQEAgAInwgSBMwBBEwKigEKBAQEAgESBNEB
AkgafCBPcHRpb25hbC4gVGhlIGlkZW50aWZpZXJzIG9mIHRoZSB0b29scyB0byByZXRyaWV2
ZSBmcm9tIHRoZSB0b29sc2V0LgogSWYgZW1wdHksIGFsbCB0b29scyBpbiB0aGUgdG9vbHNl
dCB3aWxsIGJlIHJldHVybmVkLgoKDQoFBAQCAQQSBNEBAgoKDQoFBAQCAQUSBNEBCxEKDQoF
BAQCAQESBNEBEhoKDQoFBAQCAQMSBNEBHR4KDQoFBAQCAQgSBNEBH0cKEAoIBAQCAQicCAAS
BNEBIEYKwwEKBAQEAgISBNYBAk4atAEgT3B0aW9uYWwuIElmIHRydWUsIHRoZSByZXR1cm5l
ZCB0b29scyB3aWxsIGNvbnRhaW4gcmF3IGRlc2NyaXB0aW9ucyBhbmQKIHNjaGVtYXMgZGly
ZWN0bHkgZnJvbSB0aGUgc2VydmVyLCBieXBhc3NpbmcgYW55IHN0b3JlZCBwZXJzaXN0ZW5j
ZQogY29uZmlndXJhdGlvbnMgKG92ZXJyaWRlcy9zbmFwc2hvdHMpLgoKDQoFBAQCAgUSBNYB
AgYKDQoFBAQCAgESBNYBByAKDQoFBAQCAgMSBNYBIyQKDQoFBAQCAggSBNYBJU0KEAoIBAQC
AgicCAASBNYBJkwKcQoCBAUSBtsBAN4BARpjIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbVG9v
bFNlcnZpY2UuUmV0cmlldmVUb29sc11bZ29vZ2xlLmNsb3VkLmNlcy52MS5Ub29sU2Vydmlj
ZS5SZXRyaWV2ZVRvb2xzXS4KCgsKAwQFARIE2wEIHQpNCgQEBQIAEgTdAQIaGj8gVGhlIGxp
c3Qgb2YgdG9vbHMgdGhhdCBhcmUgaW5jbHVkZWQgaW4gdGhlIHNwZWNpZmllZCB0b29sc2V0
LgoKDQoFBAUCAAQSBN0BAgoKDQoFBAUCAAYSBN0BCw8KDQoFBAUCAAESBN0BEBUKDQoFBAUC
AAMSBN0BGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest ===
    # Fields for ExecuteToolRequest
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: variables Type: 11 (.google.protobuf.Struct)
    # Field: context Type: 11 (.google.protobuf.Struct)
    # Field: parent Type: 9 ()
    # Field: args Type: 11 (.google.protobuf.Struct)
    # Field: mock_config Type: 11 (.google.cloud.ces.v1.MockConfig)

# === Message: Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse ===
    # Fields for ExecuteToolResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: response Type: 11 (.google.protobuf.Struct)
    # Field: variables Type: 11 (.google.protobuf.Struct)
    # Field: citations Type: 11 (.google.cloud.ces.v1.Citations)
    # Field: google_search_suggestions Type: 11 (.google.cloud.ces.v1.GoogleSearchSuggestions)

# === Message: Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaRequest ===
    # Fields for RetrieveToolSchemaRequest
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaResponse ===
    # Fields for RetrieveToolSchemaResponse
    # Field: tool Type: 9 ()
    # Field: toolset_tool Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: input_schema Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1.Schema)

# === Message: Google::Cloud::Ces::V1::ToolService::RetrieveToolsRequest ===
    # Fields for RetrieveToolsRequest
    # Field: toolset Type: 9 ()
    # Field: tool_ids Type: 9 ()
    # Field: bypass_persistence_config Type: 8 ()

# === Message: Google::Cloud::Ces::V1::ToolService::RetrieveToolsResponse ===
    # Fields for RetrieveToolsResponse
    # Field: tools Type: 11 (.google.cloud.ces.v1.Tool)

# === Service Client: Google::Cloud::Ces::V1::ToolService::ToolServiceClient ===
package Google::Cloud::Ces::V1::ToolService::ToolServiceClient;

=pod

=head2 Service Client: Google::Cloud::Ces::V1::ToolService::ToolServiceClient

Client stub representing the remote C<ToolService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<ces.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'ces.googleapis.com:443' );

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

sub execute_tool {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1.ToolService',
        method         => 'ExecuteTool',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse',
    });
}

sub retrieve_tool_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1.ToolService',
        method         => 'RetrieveToolSchema',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaResponse',
    });
}

sub retrieve_tools {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Ces::V1::ToolService::RetrieveToolsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.ces.v1.ToolService',
        method         => 'RetrieveTools',
        request        => $req,
        response_class => 'Google::Cloud::Ces::V1::ToolService::RetrieveToolsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::ToolService - Compiled Protocol Buffers messages for google/cloud/ces/v1/tool_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::ToolService;

    my $msg = Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest->new({
        tool => $tool,
        toolset_tool => $toolset_tool,
        variables => $variables,
        context => $context,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/tool_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::ToolService::ExecuteToolRequest

Request message for
[ToolService.ExecuteTool][google.cloud.ces.v1.ToolService.ExecuteTool].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to execute.
Format:
projects/{project}/locations/{location}/apps/{app}/tools/{tool}

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to execute. Only one tool should match the
predicate from the toolset. Otherwise, an error will be returned.

=item * C<< $msg->variables() >> / C<< $msg->variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The variables that are available for the tool execution.

=item * C<< $msg->context() >> / C<< $msg->context($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The
[ToolCallContext](https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/python#environment
for details) to be passed to the Python tool.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the app which the tool/toolset belongs to.
Format: `projects/{project}/locations/{location}/apps/{app}`

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The input parameters and values for the tool in JSON object
format.

=item * C<< $msg->mock_config() >> / C<< $msg->mock_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::SessionService::MockConfig>)

Optional. Mock configuration for the tool execution.
If this field is set, tools that call other tools will be
mocked based on the provided patterns and responses.

=back

=head2 Google::Cloud::Ces::V1::ToolService::ExecuteToolResponse

Response message for
[ToolService.ExecuteTool][google.cloud.ces.v1.ToolService.ExecuteTool].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The name of the tool that got executed.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

The toolset tool that got executed.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The tool execution result in JSON object format.
Use "output" key to specify tool response and "error" key to specify
error details (if any). If "output" and "error" keys are not specified,
then whole "response" is treated as tool execution result.

=item * C<< $msg->variables() >> / C<< $msg->variables($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The variable values at the end of the tool execution.

=item * C<< $msg->citations() >> / C<< $msg->citations($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::SessionService::Citations>)

Citations that provide the source information for the tool's execution.

=item * C<< $msg->google_search_suggestions() >> / C<< $msg->google_search_suggestions($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions>)

The suggestions returned from Google Search as a result of invoking the
Google Search Tool during the tool execution.

=back

=head2 Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaRequest

Request message for
[ToolService.RetrieveToolSchema][google.cloud.ces.v1.ToolService.RetrieveToolSchema].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. The name of the tool to retrieve the schema for.
Format:
projects/{project}/locations/{location}/apps/{app}/tools/{tool}

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

Optional. The toolset tool to retrieve the schema for. Only one tool
should match the predicate from the toolset. Otherwise, an error will be
returned.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The resource name of the app which the tool/toolset belongs to.
Format: `projects/{project}/locations/{location}/apps/{app}`

=back

=head2 Google::Cloud::Ces::V1::ToolService::RetrieveToolSchemaResponse

Response message for
[ToolService.RetrieveToolSchema][google.cloud.ces.v1.ToolService.RetrieveToolSchema].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The name of the tool that the schema is for.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset_tool() >> / C<< $msg->toolset_tool($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

The toolset tool that the schema is for.

=item * C<< $msg->input_schema() >> / C<< $msg->input_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

The schema of the tool input parameters.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

The schema of the tool output parameters.

=back

=head2 Google::Cloud::Ces::V1::ToolService::RetrieveToolsRequest

Request message for
[ToolService.RetrieveTools][google.cloud.ces.v1.ToolService.RetrieveTools].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<String>

Required. The name of the toolset to retrieve the tools for.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->tool_ids() >> / C<< $msg->tool_ids($value) >>

Type: C<String>

Optional. The identifiers of the tools to retrieve from the toolset.
If empty, all tools in the toolset will be returned.

=item * C<< $msg->bypass_persistence_config() >> / C<< $msg->bypass_persistence_config($value) >>

Type: C<Bool>

Optional. If true, the returned tools will contain raw descriptions and
schemas directly from the server, bypassing any stored persistence
configurations (overrides/snapshots).

=back

=head2 Google::Cloud::Ces::V1::ToolService::RetrieveToolsResponse

Response message for
[ToolService.RetrieveTools][google.cloud.ces.v1.ToolService.RetrieveTools].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Tool::Tool>)

The list of tools that are included in the specified toolset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::ToolService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
