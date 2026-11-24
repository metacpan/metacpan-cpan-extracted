package Grafeas::V1::IntotoStatement;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Grafeas::V1::IntotoProvenance };
    eval { require Grafeas::V1::SlsaProvenance };
    eval { require Grafeas::V1::SlsaProvenanceZeroTwo };
    my $descriptor_b64 = <<'EOF';
CiFncmFmZWFzL3YxL2ludG90b19zdGF0ZW1lbnQucHJvdG8SCmdyYWZlYXMudjEaHGdvb2ds
ZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8aImdyYWZlYXMvdjEvaW50b3RvX3Byb3ZlbmFuY2UucHJvdG8aIGdyYWZlYXMvdjEvc2xz
YV9wcm92ZW5hbmNlLnByb3RvGilncmFmZWFzL3YxL3Nsc2FfcHJvdmVuYW5jZV96ZXJvX3R3
by5wcm90byLuAgoPSW5Ub3RvU3RhdGVtZW50EhMKBHR5cGUYASABKAlSBV90eXBlEi0KB3N1
YmplY3QYAiADKAsyEy5ncmFmZWFzLnYxLlN1YmplY3RSB3N1YmplY3QSJQoOcHJlZGljYXRl
X3R5cGUYAyABKAlSDXByZWRpY2F0ZVR5cGUSPgoKcHJvdmVuYW5jZRgEIAEoCzIcLmdyYWZl
YXMudjEuSW5Ub3RvUHJvdmVuYW5jZUgAUgpwcm92ZW5hbmNlEkUKD3Nsc2FfcHJvdmVuYW5j
ZRgFIAEoCzIaLmdyYWZlYXMudjEuU2xzYVByb3ZlbmFuY2VIAFIOc2xzYVByb3ZlbmFuY2US
XAoYc2xzYV9wcm92ZW5hbmNlX3plcm9fdHdvGAYgASgLMiEuZ3JhZmVhcy52MS5TbHNhUHJv
dmVuYW5jZVplcm9Ud29IAFIVc2xzYVByb3ZlbmFuY2VaZXJvVHdvQgsKCXByZWRpY2F0ZSKR
AQoHU3ViamVjdBISCgRuYW1lGAEgASgJUgRuYW1lEjcKBmRpZ2VzdBgCIAMoCzIfLmdyYWZl
YXMudjEuU3ViamVjdC5EaWdlc3RFbnRyeVIGZGlnZXN0GjkKC0RpZ2VzdEVudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEipA8KFkluVG90b1Nsc2FQ
cm92ZW5hbmNlVjESEwoEdHlwZRgBIAEoCVIFX3R5cGUSLQoHc3ViamVjdBgCIAMoCzITLmdy
YWZlYXMudjEuU3ViamVjdFIHc3ViamVjdBIlCg5wcmVkaWNhdGVfdHlwZRgDIAEoCVINcHJl
ZGljYXRlVHlwZRJRCglwcmVkaWNhdGUYBCABKAsyMy5ncmFmZWFzLnYxLkluVG90b1Nsc2FQ
cm92ZW5hbmNlVjEuU2xzYVByb3ZlbmFuY2VWMVIJcHJlZGljYXRlGsEBChBTbHNhUHJvdmVu
YW5jZVYxEl0KEGJ1aWxkX2RlZmluaXRpb24YASABKAsyMi5ncmFmZWFzLnYxLkluVG90b1Ns
c2FQcm92ZW5hbmNlVjEuQnVpbGREZWZpbml0aW9uUg9idWlsZERlZmluaXRpb24STgoLcnVu
X2RldGFpbHMYAiABKAsyLS5ncmFmZWFzLnYxLkluVG90b1Nsc2FQcm92ZW5hbmNlVjEuUnVu
RGV0YWlsc1IKcnVuRGV0YWlscxqwAgoPQnVpbGREZWZpbml0aW9uEh0KCmJ1aWxkX3R5cGUY
ASABKAlSCWJ1aWxkVHlwZRJIChNleHRlcm5hbF9wYXJhbWV0ZXJzGAIgASgLMhcuZ29vZ2xl
LnByb3RvYnVmLlN0cnVjdFISZXh0ZXJuYWxQYXJhbWV0ZXJzEkgKE2ludGVybmFsX3BhcmFt
ZXRlcnMYAyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UhJpbnRlcm5hbFBhcmFtZXRl
cnMSagoVcmVzb2x2ZWRfZGVwZW5kZW5jaWVzGAQgAygLMjUuZ3JhZmVhcy52MS5JblRvdG9T
bHNhUHJvdmVuYW5jZVYxLlJlc291cmNlRGVzY3JpcHRvclIUcmVzb2x2ZWREZXBlbmRlbmNp
ZXMa+AMKElJlc291cmNlRGVzY3JpcHRvchISCgRuYW1lGAEgASgJUgRuYW1lEhAKA3VyaRgC
IAEoCVIDdXJpElkKBmRpZ2VzdBgDIAMoCzJBLmdyYWZlYXMudjEuSW5Ub3RvU2xzYVByb3Zl
bmFuY2VWMS5SZXNvdXJjZURlc2NyaXB0b3IuRGlnZXN0RW50cnlSBmRpZ2VzdBIYCgdjb250
ZW50GAQgASgMUgdjb250ZW50EisKEWRvd25sb2FkX2xvY2F0aW9uGAUgASgJUhBkb3dubG9h
ZExvY2F0aW9uEh0KCm1lZGlhX3R5cGUYBiABKAlSCW1lZGlhVHlwZRJoCgthbm5vdGF0aW9u
cxgHIAMoCzJGLmdyYWZlYXMudjEuSW5Ub3RvU2xzYVByb3ZlbmFuY2VWMS5SZXNvdXJjZURl
c2NyaXB0b3IuQW5ub3RhdGlvbnNFbnRyeVILYW5ub3RhdGlvbnMaOQoLRGlnZXN0RW50cnkS
EAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpWChBBbm5vdGF0
aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiwKBXZhbHVlGAIgASgLMhYuZ29vZ2xlLnBy
b3RvYnVmLlZhbHVlUgV2YWx1ZToCOAEagQIKClJ1bkRldGFpbHMSTgoHYnVpbGRlchgBIAEo
CzI0LmdyYWZlYXMudjEuSW5Ub3RvU2xzYVByb3ZlbmFuY2VWMS5Qcm92ZW5hbmNlQnVpbGRl
clIHYnVpbGRlchJMCghtZXRhZGF0YRgCIAEoCzIwLmdyYWZlYXMudjEuSW5Ub3RvU2xzYVBy
b3ZlbmFuY2VWMS5CdWlsZE1ldGFkYXRhUghtZXRhZGF0YRJVCgpieXByb2R1Y3RzGAMgAygL
MjUuZ3JhZmVhcy52MS5JblRvdG9TbHNhUHJvdmVuYW5jZVYxLlJlc291cmNlRGVzY3JpcHRv
clIKYnlwcm9kdWN0cxqmAgoRUHJvdmVuYW5jZUJ1aWxkZXISDgoCaWQYASABKAlSAmlkElsK
B3ZlcnNpb24YAiADKAsyQS5ncmFmZWFzLnYxLkluVG90b1Nsc2FQcm92ZW5hbmNlVjEuUHJv
dmVuYW5jZUJ1aWxkZXIuVmVyc2lvbkVudHJ5Ugd2ZXJzaW9uEmgKFGJ1aWxkZXJfZGVwZW5k
ZW5jaWVzGAMgAygLMjUuZ3JhZmVhcy52MS5JblRvdG9TbHNhUHJvdmVuYW5jZVYxLlJlc291
cmNlRGVzY3JpcHRvclITYnVpbGRlckRlcGVuZGVuY2llcxo6CgxWZXJzaW9uRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARqsAQoNQnVpbGRNZXRh
ZGF0YRIjCg1pbnZvY2F0aW9uX2lkGAEgASgJUgxpbnZvY2F0aW9uSWQSOQoKc3RhcnRlZF9v
bhgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0ZWRPbhI7CgtmaW5p
c2hlZF9vbhgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmZpbmlzaGVkT25C
ZwoNaW8uZ3JhZmVhcy52MUIUSW5Ub3RvU3RhdGVtZW50UHJvdG9QAVo4Z29vZ2xlLmdvbGFu
Zy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFKth8K
BhIEDgBpAQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDIxIFRoZSBHcmFmZWFzIEF1dGhv
cnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAEwoJCgIDABIDEgAmCgkKAgMBEgMTACkKCQoC
AwISAxQALAoJCgIDAxIDFQAqCgkKAgMEEgMWADMKCAoBCBIDGABPCgkKAggLEgMYAE8KCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAmCgkKAggBEgMaACYKCAoBCBIDGwAhCgkKAggk
EgMbACEKCAoBCBIDHAA1CgkKAggIEgMcADUK4wEKAgQAEgQiAC0BGtYBIFNwZWMgZGVmaW5l
ZCBhdAogaHR0cHM6Ly9naXRodWIuY29tL2luLXRvdG8vYXR0ZXN0YXRpb24vdHJlZS9tYWlu
L3NwZWMjc3RhdGVtZW50IFRoZQogc2VyaWFsaXplZCBJblRvdG9TdGF0ZW1lbnQgd2lsbCBi
ZSBzdG9yZWQgYXMgRW52ZWxvcGUucGF5bG9hZC4KIEVudmVsb3BlLnBheWxvYWRUeXBlIGlz
IGFsd2F5cyAiYXBwbGljYXRpb24vdm5kLmluLXRvdG8ranNvbiIuCgoKCgMEAAESAyIIFwo6
CgQEAAIAEgMkAigaLSBBbHdheXMgYGh0dHBzOi8vaW4tdG90by5pby9TdGF0ZW1lbnQvdjAu
MWAuCgoMCgUEAAIABRIDJAIICgwKBQQAAgABEgMkCQ0KDAoFBAACAAMSAyQQEQoMCgUEAAIA
CBIDJBInCgwKBQQAAgAKEgMkEyYKDAoFBAACAAoSAyQfJgoLCgQEAAIBEgMlAh8KDAoFBAAC
AQQSAyUCCgoMCgUEAAIBBhIDJQsSCgwKBQQAAgEBEgMlExoKDAoFBAACAQMSAyUdHgpFCgQE
AAICEgMnAhwaOCBgaHR0cHM6Ly9zbHNhLmRldi9wcm92ZW5hbmNlL3YwLjFgIGZvciBTbHNh
UHJvdmVuYW5jZS4KCgwKBQQAAgIFEgMnAggKDAoFBAACAgESAycJFwoMCgUEAAICAxIDJxob
CgwKBAQACAASBCgCLAMKDAoFBAAIAAESAygIEQoLCgQEAAIDEgMpBCQKDAoFBAACAwYSAykE
FAoMCgUEAAIDARIDKRUfCgwKBQQAAgMDEgMpIiMKCwoEBAACBBIDKgQnCgwKBQQAAgQGEgMq
BBIKDAoFBAACBAESAyoTIgoMCgUEAAIEAxIDKiUmCgsKBAQAAgUSAysENwoMCgUEAAIFBhID
KwQZCgwKBQQAAgUBEgMrGjIKDAoFBAACBQMSAys1NgoKCgIEARIELgA1AQoKCgMEAQESAy4I
DwoLCgQEAQIAEgMvAhIKDAoFBAECAAUSAy8CCAoMCgUEAQIAARIDLwkNCgwKBQQBAgADEgMv
EBEKqgEKBAQBAgESAzQCIRqcASBgIjxBTEdPUklUSE0+IjogIjxIRVhfVkFMVUU+ImAKIEFs
Z29yaXRobXMgY2FuIGJlIGUuZy4gc2hhMjU2LCBzaGE1MTIKIFNlZQogaHR0cHM6Ly9naXRo
dWIuY29tL2luLXRvdG8vYXR0ZXN0YXRpb24vYmxvYi9tYWluL3NwZWMvZmllbGRfdHlwZXMu
bWQjRGlnZXN0U2V0CgoMCgUEAQIBBhIDNAIVCgwKBQQBAgEBEgM0FhwKDAoFBAECAQMSAzQf
IAoKCgIEAhIENwBpAQoKCgMEAgESAzcIHgpmCgQEAgIAEgM6AigaWSBJblRvdG8gc3BlYyBk
ZWZpbmVkIGF0CiBodHRwczovL2dpdGh1Yi5jb20vaW4tdG90by9hdHRlc3RhdGlvbi90cmVl
L21haW4vc3BlYyNzdGF0ZW1lbnQKCgwKBQQCAgAFEgM6AggKDAoFBAICAAESAzoJDQoMCgUE
AgIAAxIDOhARCgwKBQQCAgAIEgM6EicKDAoFBAICAAoSAzoTJgoMCgUEAgIAChIDOh8mCgsK
BAQCAgESAzsCHwoMCgUEAgIBBBIDOwIKCgwKBQQCAgEGEgM7CxIKDAoFBAICAQESAzsTGgoM
CgUEAgIBAxIDOx0eCgsKBAQCAgISAzwCHAoMCgUEAgICBRIDPAIICgwKBQQCAgIBEgM8CRcK
DAoFBAICAgMSAzwaGwoLCgQEAgIDEgM9AiEKDAoFBAICAwYSAz0CEgoMCgUEAgIDARIDPRMc
CgwKBQQCAgMDEgM9HyAKygEKBAQCAwASBEICRQMauwEgS2VlcCBpbiBzeW5jIHdpdGggc2No
ZW1hIGF0CiBodHRwczovL2dpdGh1Yi5jb20vc2xzYS1mcmFtZXdvcmsvc2xzYS9ibG9iL21h
aW4vZG9jcy9wcm92ZW5hbmNlL3NjaGVtYS92MS9wcm92ZW5hbmNlLnByb3RvCiBCdWlsZGVy
IHJlbmFtZWQgdG8gUHJvdmVuYW5jZUJ1aWxkZXIgYmVjYXVzZSBvZiBKYXZhIGNvbmZsaWN0
cy4KCgwKBQQCAwABEgNCChoKDQoGBAIDAAIAEgNDBCkKDgoHBAIDAAIABhIDQwQTCg4KBwQC
AwACAAESA0MUJAoOCgcEAgMAAgADEgNDJygKDQoGBAIDAAIBEgNEBB8KDgoHBAIDAAIBBhID
RAQOCg4KBwQCAwACAQESA0QPGgoOCgcEAgMAAgEDEgNEHR4KDAoEBAIDARIERwJMAwoMCgUE
AgMBARIDRwoZCg0KBgQCAwECABIDSAQaCg4KBwQCAwECAAUSA0gECgoOCgcEAgMBAgABEgNI
CxUKDgoHBAIDAQIAAxIDSBgZCg0KBgQCAwECARIDSQQzCg4KBwQCAwECAQYSA0kEGgoOCgcE
AgMBAgEBEgNJGy4KDgoHBAIDAQIBAxIDSTEyCg0KBgQCAwECAhIDSgQzCg4KBwQCAwECAgYS
A0oEGgoOCgcEAgMBAgIBEgNKGy4KDgoHBAIDAQICAxIDSjEyCg0KBgQCAwECAxIDSwQ6Cg4K
BwQCAwECAwQSA0sEDAoOCgcEAgMBAgMGEgNLDR8KDgoHBAIDAQIDARIDSyA1Cg4KBwQCAwEC
AwMSA0s4OQoMCgQEAgMCEgROAlYDCgwKBQQCAwIBEgNOChwKDQoGBAIDAgIAEgNPBBQKDgoH
BAIDAgIABRIDTwQKCg4KBwQCAwICAAESA08LDwoOCgcEAgMCAgADEgNPEhMKDQoGBAIDAgIB
EgNQBBMKDgoHBAIDAgIBBRIDUAQKCg4KBwQCAwICAQESA1ALDgoOCgcEAgMCAgEDEgNQERIK
DQoGBAIDAgICEgNRBCMKDgoHBAIDAgICBhIDUQQXCg4KBwQCAwICAgESA1EYHgoOCgcEAgMC
AgIDEgNRISIKDQoGBAIDAgIDEgNSBBYKDgoHBAIDAgIDBRIDUgQJCg4KBwQCAwICAwESA1IK
EQoOCgcEAgMCAgMDEgNSFBUKDQoGBAIDAgIEEgNTBCEKDgoHBAIDAgIEBRIDUwQKCg4KBwQC
AwICBAESA1MLHAoOCgcEAgMCAgQDEgNTHyAKDQoGBAIDAgIFEgNUBBoKDgoHBAIDAgIFBRID
VAQKCg4KBwQCAwICBQESA1QLFQoOCgcEAgMCAgUDEgNUGBkKDQoGBAIDAgIGEgNVBDcKDgoH
BAIDAgIGBhIDVQQmCg4KBwQCAwICBgESA1UnMgoOCgcEAgMCAgYDEgNVNTYKDAoEBAIDAxIE
WAJcAwoMCgUEAgMDARIDWAoUCg0KBgQCAwMCABIDWQQiCg4KBwQCAwMCAAYSA1kEFQoOCgcE
AgMDAgABEgNZFh0KDgoHBAIDAwIAAxIDWSAhCg0KBgQCAwMCARIDWgQfCg4KBwQCAwMCAQYS
A1oEEQoOCgcEAgMDAgEBEgNaEhoKDgoHBAIDAwIBAxIDWh0eCg0KBgQCAwMCAhIDWwQvCg4K
BwQCAwMCAgQSA1sEDAoOCgcEAgMDAgIGEgNbDR8KDgoHBAIDAwICARIDWyAqCg4KBwQCAwMC
AgMSA1stLgoMCgQEAgMEEgReAmIDCgwKBQQCAwQBEgNeChsKDQoGBAIDBAIAEgNfBBIKDgoH
BAIDBAIABRIDXwQKCg4KBwQCAwQCAAESA18LDQoOCgcEAgMEAgADEgNfEBEKDQoGBAIDBAIB
EgNgBCQKDgoHBAIDBAIBBhIDYAQXCg4KBwQCAwQCAQESA2AYHwoOCgcEAgMEAgEDEgNgIiMK
DQoGBAIDBAICEgNhBDkKDgoHBAIDBAICBBIDYQQMCg4KBwQCAwQCAgYSA2ENHwoOCgcEAgME
AgIBEgNhIDQKDgoHBAIDBAICAxIDYTc4CgwKBAQCAwUSBGQCaAMKDAoFBAIDBQESA2QKFwoN
CgYEAgMFAgASA2UEHQoOCgcEAgMFAgAFEgNlBAoKDgoHBAIDBQIAARIDZQsYCg4KBwQCAwUC
AAMSA2UbHAoNCgYEAgMFAgESA2YELQoOCgcEAgMFAgEGEgNmBB0KDgoHBAIDBQIBARIDZh4o
Cg4KBwQCAwUCAQMSA2YrLAoNCgYEAgMFAgISA2cELgoOCgcEAgMFAgIGEgNnBB0KDgoHBAID
BQICARIDZx4pCg4KBwQCAwUCAgMSA2csLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::IntotoStatement::InTotoStatement ===
    # Fields for InTotoStatement
    # Field: type Type: 9 ()
    # Field: subject Type: 11 (.grafeas.v1.Subject)
    # Field: predicate_type Type: 9 ()
    # Field: provenance Type: 11 (.grafeas.v1.InTotoProvenance)
    # Field: slsa_provenance Type: 11 (.grafeas.v1.SlsaProvenance)
    # Field: slsa_provenance_zero_two Type: 11 (.grafeas.v1.SlsaProvenanceZeroTwo)

# === Message: Grafeas::V1::IntotoStatement::Subject ===
    # Fields for Subject
    # Field: name Type: 9 ()
    # Field: digest Type: 11 (.grafeas.v1.Subject.DigestEntry)

# === Message: Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1 ===
    # Fields for InTotoSlsaProvenanceV1
    # Field: type Type: 9 ()
    # Field: subject Type: 11 (.grafeas.v1.Subject)
    # Field: predicate_type Type: 9 ()
    # Field: predicate Type: 11 (.grafeas.v1.InTotoSlsaProvenanceV1.SlsaProvenanceV1)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::IntotoStatement - Compiled Protocol Buffers messages for grafeas/v1/intoto_statement.proto

=head1 SYNOPSIS

    use Grafeas::V1::IntotoStatement;

    my $msg = Grafeas::V1::IntotoStatement::InTotoStatement->new({
        type => $type,
        subject => $subject,
        predicate_type => $predicate_type,
        provenance => $provenance,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::IntotoStatement::InTotoStatement->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/intoto_statement.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::IntotoStatement::InTotoStatement

Spec defined at
https://github.com/in-toto/attestation/tree/main/spec#statement The
serialized InTotoStatement will be stored as Envelope.payload.
Envelope.payloadType is always "application/vnd.in-toto+json".

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Always `https://in-toto.io/Statement/v0.1`.

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::Subject>)

=item * C<< $msg->predicate_type() >> / C<< $msg->predicate_type($value) >>

Type: C<String>

`https://slsa.dev/provenance/v0.1` for SlsaProvenance.

=item * C<< $msg->provenance() >> / C<< $msg->provenance($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::InTotoProvenance>)

=item * C<< $msg->slsa_provenance() >> / C<< $msg->slsa_provenance($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenance::SlsaProvenance>)

=item * C<< $msg->slsa_provenance_zero_two() >> / C<< $msg->slsa_provenance_zero_two($value) >>

Type: C<Message> (L<Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo>)

=back

=head2 Grafeas::V1::IntotoStatement::Subject

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

=item * C<< $msg->digest() >> / C<< $msg->digest($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::Subject::DigestEntry>)

`"<ALGORITHM>": "<HEX_VALUE>"`
Algorithms can be e.g. sha256, sha512
See
https://github.com/in-toto/attestation/blob/main/spec/field_types.md#DigestSet

=back

=head2 Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

InToto spec defined at
https://github.com/in-toto/attestation/tree/main/spec#statement

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::Subject>)

=item * C<< $msg->predicate_type() >> / C<< $msg->predicate_type($value) >>

Type: C<String>

=item * C<< $msg->predicate() >> / C<< $msg->predicate($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::SlsaProvenanceV1>)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::IntotoStatement::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
