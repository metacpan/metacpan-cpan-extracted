package Google::Ai::Generativelanguage::V1beta3::TextService;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Ai::Generativelanguage::V1beta3::Citation };
    eval { require Google::Ai::Generativelanguage::V1beta3::Safety };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYmV0YTMvdGV4dF9zZXJ2aWNlLnBy
b3RvEiRnb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMaM2dvb2dsZS9haS9n
ZW5lcmF0aXZlbGFuZ3VhZ2UvdjFiZXRhMy9jaXRhdGlvbi5wcm90bxoxZ29vZ2xlL2FpL2dl
bmVyYXRpdmVsYW5ndWFnZS92MWJldGEzL3NhZmV0eS5wcm90bxocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ipQQKE0dlbmVy
YXRlVGV4dFJlcXVlc3QSGQoFbW9kZWwYASABKAlCA+BBAlIFbW9kZWwSTQoGcHJvbXB0GAIg
ASgLMjAuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLlRleHRQcm9tcHRC
A+BBAlIGcHJvbXB0EioKC3RlbXBlcmF0dXJlGAMgASgCQgPgQQFIAFILdGVtcGVyYXR1cmWI
AQESMQoPY2FuZGlkYXRlX2NvdW50GAQgASgFQgPgQQFIAVIOY2FuZGlkYXRlQ291bnSIAQES
NAoRbWF4X291dHB1dF90b2tlbnMYBSABKAVCA+BBAUgCUg9tYXhPdXRwdXRUb2tlbnOIAQES
HQoFdG9wX3AYBiABKAJCA+BBAUgDUgR0b3BQiAEBEh0KBXRvcF9rGAcgASgFQgPgQQFIBFIE
dG9wS4gBARJcCg9zYWZldHlfc2V0dGluZ3MYCCADKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2
ZWxhbmd1YWdlLnYxYmV0YTMuU2FmZXR5U2V0dGluZ1IOc2FmZXR5U2V0dGluZ3MSJQoOc3Rv
cF9zZXF1ZW5jZXMYCSADKAlSDXN0b3BTZXF1ZW5jZXNCDgoMX3RlbXBlcmF0dXJlQhIKEF9j
YW5kaWRhdGVfY291bnRCFAoSX21heF9vdXRwdXRfdG9rZW5zQggKBl90b3BfcEIICgZfdG9w
X2simgIKFEdlbmVyYXRlVGV4dFJlc3BvbnNlElQKCmNhbmRpZGF0ZXMYASADKAsyNC5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuVGV4dENvbXBsZXRpb25SCmNhbmRp
ZGF0ZXMSTQoHZmlsdGVycxgDIAMoCzIzLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2Uu
djFiZXRhMy5Db250ZW50RmlsdGVyUgdmaWx0ZXJzEl0KD3NhZmV0eV9mZWVkYmFjaxgEIAMo
CzI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5TYWZldHlGZWVkYmFj
a1IOc2FmZXR5RmVlZGJhY2siJQoKVGV4dFByb21wdBIXCgR0ZXh0GAEgASgJQgPgQQJSBHRl
eHQijQIKDlRleHRDb21wbGV0aW9uEhsKBm91dHB1dBgBIAEoCUID4EEDUgZvdXRwdXQSWQoO
c2FmZXR5X3JhdGluZ3MYAiADKAsyMi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YmV0YTMuU2FmZXR5UmF0aW5nUg1zYWZldHlSYXRpbmdzEm0KEWNpdGF0aW9uX21ldGFkYXRh
GAMgASgLMjYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkNpdGF0aW9u
TWV0YWRhdGFCA+BBA0gAUhBjaXRhdGlvbk1ldGFkYXRhiAEBQhQKEl9jaXRhdGlvbl9tZXRh
ZGF0YSJyChBFbWJlZFRleHRSZXF1ZXN0EkUKBW1vZGVsGAEgASgJQi/gQQL6QSkKJ2dlbmVy
YXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9Nb2RlbFIFbW9kZWwSFwoEdGV4dBgCIAEo
CUID4EECUgR0ZXh0InoKEUVtYmVkVGV4dFJlc3BvbnNlElcKCWVtYmVkZGluZxgBIAEoCzIv
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5FbWJlZGRpbmdCA+BBA0gA
UgllbWJlZGRpbmeIAQFCDAoKX2VtYmVkZGluZyJ5ChVCYXRjaEVtYmVkVGV4dFJlcXVlc3QS
RQoFbW9kZWwYASABKAlCL+BBAvpBKQonZ2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMu
Y29tL01vZGVsUgVtb2RlbBIZCgV0ZXh0cxgCIAMoCUID4EECUgV0ZXh0cyJuChZCYXRjaEVt
YmVkVGV4dFJlc3BvbnNlElQKCmVtYmVkZGluZ3MYASADKAsyLy5nb29nbGUuYWkuZ2VuZXJh
dGl2ZWxhbmd1YWdlLnYxYmV0YTMuRW1iZWRkaW5nQgPgQQNSCmVtYmVkZGluZ3MiIQoJRW1i
ZWRkaW5nEhQKBXZhbHVlGAEgAygCUgV2YWx1ZSKuAQoWQ291bnRUZXh0VG9rZW5zUmVxdWVz
dBJFCgVtb2RlbBgBIAEoCUIv4EEC+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBp
cy5jb20vTW9kZWxSBW1vZGVsEk0KBnByb21wdBgCIAEoCzIwLmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFiZXRhMy5UZXh0UHJvbXB0QgPgQQJSBnByb21wdCI6ChdDb3VudFRl
eHRUb2tlbnNSZXNwb25zZRIfCgt0b2tlbl9jb3VudBgBIAEoBVIKdG9rZW5Db3VudDLNBwoL
VGV4dFNlcnZpY2UStAIKDEdlbmVyYXRlVGV4dBI5Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFiZXRhMy5HZW5lcmF0ZVRleHRSZXF1ZXN0GjouZ29vZ2xlLmFpLmdlbmVyYXRp
dmVsYW5ndWFnZS52MWJldGEzLkdlbmVyYXRlVGV4dFJlc3BvbnNlIqwBgtPkkwJdIiYvdjFi
ZXRhMy97bW9kZWw9bW9kZWxzLyp9OmdlbmVyYXRlVGV4dDoBKlowIisvdjFiZXRhMy97bW9k
ZWw9dHVuZWRNb2RlbHMvKn06Z2VuZXJhdGVUZXh0OgEq2kFGbW9kZWwscHJvbXB0LHRlbXBl
cmF0dXJlLGNhbmRpZGF0ZV9jb3VudCxtYXhfb3V0cHV0X3Rva2Vucyx0b3BfcCx0b3BfaxK5
AQoJRW1iZWRUZXh0EjYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkVt
YmVkVGV4dFJlcXVlc3QaNy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMu
RW1iZWRUZXh0UmVzcG9uc2UiO4LT5JMCKCIjL3YxYmV0YTMve21vZGVsPW1vZGVscy8qfTpl
bWJlZFRleHQ6ASraQQptb2RlbCx0ZXh0Es4BCg5CYXRjaEVtYmVkVGV4dBI7Lmdvb2dsZS5h
aS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5CYXRjaEVtYmVkVGV4dFJlcXVlc3QaPC5n
b29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTMuQmF0Y2hFbWJlZFRleHRSZXNw
b25zZSJBgtPkkwItIigvdjFiZXRhMy97bW9kZWw9bW9kZWxzLyp9OmJhdGNoRW1iZWRUZXh0
OgEq2kELbW9kZWwsdGV4dHMS0wEKD0NvdW50VGV4dFRva2VucxI8Lmdvb2dsZS5haS5nZW5l
cmF0aXZlbGFuZ3VhZ2UudjFiZXRhMy5Db3VudFRleHRUb2tlbnNSZXF1ZXN0Gj0uZ29vZ2xl
LmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWJldGEzLkNvdW50VGV4dFRva2Vuc1Jlc3BvbnNl
IkOC0+STAi4iKS92MWJldGEzL3ttb2RlbD1tb2RlbHMvKn06Y291bnRUZXh0VG9rZW5zOgEq
2kEMbW9kZWwscHJvbXB0GiTKQSFnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb21C
ngEKKGNvbS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYmV0YTNCEFRleHRTZXJ2
aWNlUHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2Uv
YXBpdjFiZXRhMy9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqU
TQoHEgUOAKMCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
LQoJCgIDABIDEgA9CgkKAgMBEgMTADsKCQoCAwISAxQAJgoJCgIDAxIDFQAhCgkKAgMEEgMW
ACkKCQoCAwUSAxcAIwoICgEIEgMZAHUKCQoCCAsSAxkAdQoICgEIEgMaACIKCQoCCAoSAxoA
IgoICgEIEgMbADEKCQoCCAgSAxsAMQoICgEIEgMcAEEKCQoCCAESAxwAQQrAAQoCBgASBCIA
TwEaswEgQVBJIGZvciB1c2luZyBHZW5lcmF0aXZlIExhbmd1YWdlIE1vZGVscyAoR0xNcykg
dHJhaW5lZCB0byBnZW5lcmF0ZSB0ZXh0LgoKIEFsc28ga25vd24gYXMgTGFyZ2UgTGFuZ3Vh
Z2UgTW9kZWxzIChMTE0pcywgdGhlc2UgZ2VuZXJhdGUgdGV4dCBnaXZlbiBhbgogaW5wdXQg
cHJvbXB0IGZyb20gdGhlIHVzZXIuCgoKCgMGAAESAyIIEwoKCgMGAAMSAyMCSQoMCgUGAAOZ
CBIDIwJJCksKBAYAAgASBCYCMQMaPSBHZW5lcmF0ZXMgYSByZXNwb25zZSBmcm9tIHRoZSBt
b2RlbCBnaXZlbiBhbiBpbnB1dCBtZXNzYWdlLgoKDAoFBgACAAESAyYGEgoMCgUGAAIAAhID
JhMmCgwKBQYAAgADEgMmMUUKDQoFBgACAAQSBCcELgYKEQoJBgACAASwyrwiEgQnBC4GCg0K
BQYAAgAEEgQvBDBRChAKCAYAAgAEmwgAEgQvBDBRCk0KBAYAAgESBDQCOgMaPyBHZW5lcmF0
ZXMgYW4gZW1iZWRkaW5nIGZyb20gdGhlIG1vZGVsIGdpdmVuIGFuIGlucHV0IG1lc3NhZ2Uu
CgoMCgUGAAIBARIDNAYPCgwKBQYAAgECEgM0ECAKDAoFBgACAQMSAzQrPAoNCgUGAAIBBBIE
NQQ4BgoRCgkGAAIBBLDKvCISBDUEOAYKDAoFBgACAQQSAzkEOAoPCggGAAIBBJsIABIDOQQ4
CmUKBAYAAgISBD4CRAMaVyBHZW5lcmF0ZXMgbXVsdGlwbGUgZW1iZWRkaW5ncyBmcm9tIHRo
ZSBtb2RlbCBnaXZlbiBpbnB1dCB0ZXh0IGluIGEKIHN5bmNocm9ub3VzIGNhbGwuCgoMCgUG
AAICARIDPgYUCgwKBQYAAgICEgM+FSoKDAoFBgACAgMSAz41SwoNCgUGAAICBBIEPwRCBgoR
CgkGAAICBLDKvCISBD8EQgYKDAoFBgACAgQSA0MEOQoPCggGAAICBJsIABIDQwQ5Ck8KBAYA
AgMSBEcCTgMaQSBSdW5zIGEgbW9kZWwncyB0b2tlbml6ZXIgb24gYSB0ZXh0IGFuZCByZXR1
cm5zIHRoZSB0b2tlbiBjb3VudC4KCgwKBQYAAgMBEgNHBhUKDAoFBgACAwISA0cWLAoMCgUG
AAIDAxIDSA8mCg0KBQYAAgMEEgRJBEwGChEKCQYAAgMEsMq8IhIESQRMBgoMCgUGAAIDBBID
TQQ6Cg8KCAYAAgMEmwgAEgNNBDoKTQoCBAASBVIAnwEBGkAgUmVxdWVzdCB0byBnZW5lcmF0
ZSBhIHRleHQgY29tcGxldGlvbiByZXNwb25zZSBmcm9tIHRoZSBtb2RlbC4KCgoKAwQAARID
UggbCrMBCgQEAAIAEgNYAjwapQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBgTW9kZWxg
IG9yIGBUdW5lZE1vZGVsYCB0byB1c2UgZm9yIGdlbmVyYXRpbmcgdGhlCiBjb21wbGV0aW9u
LgogRXhhbXBsZXM6CiAgbW9kZWxzL3RleHQtYmlzb24tMDAxCiAgdHVuZWRNb2RlbHMvc2Vu
dGVuY2UtdHJhbnNsYXRvci11M2I3bQoKDAoFBAACAAUSA1gCCAoMCgUEAAIAARIDWAkOCgwK
BQQAAgADEgNYERIKDAoFBAACAAgSA1gTOwoPCggEAAIACJwIABIDWBQ6CsgBCgQEAAIBEgNe
AkEaugEgUmVxdWlyZWQuIFRoZSBmcmVlLWZvcm0gaW5wdXQgdGV4dCBnaXZlbiB0byB0aGUg
bW9kZWwgYXMgYSBwcm9tcHQuCgogR2l2ZW4gYSBwcm9tcHQsIHRoZSBtb2RlbCB3aWxsIGdl
bmVyYXRlIGEgVGV4dENvbXBsZXRpb24gcmVzcG9uc2UgaXQKIHByZWRpY3RzIGFzIHRoZSBj
b21wbGV0aW9uIG9mIHRoZSBpbnB1dCB0ZXh0LgoKDAoFBAACAQYSA14CDAoMCgUEAAIBARID
Xg0TCgwKBQQAAgEDEgNeFhcKDAoFBAACAQgSA14YQAoPCggEAAIBCJwIABIDXhk/CqcDCgQE
AAICEgNoAkoamQMgT3B0aW9uYWwuIENvbnRyb2xzIHRoZSByYW5kb21uZXNzIG9mIHRoZSBv
dXRwdXQuCiBOb3RlOiBUaGUgZGVmYXVsdCB2YWx1ZSB2YXJpZXMgYnkgbW9kZWwsIHNlZSB0
aGUgYE1vZGVsLnRlbXBlcmF0dXJlYAogYXR0cmlidXRlIG9mIHRoZSBgTW9kZWxgIHJldHVy
bmVkIHRoZSBgZ2V0TW9kZWxgIGZ1bmN0aW9uLgoKIFZhbHVlcyBjYW4gcmFuZ2UgZnJvbSBb
MC4wLDEuMF0sCiBpbmNsdXNpdmUuIEEgdmFsdWUgY2xvc2VyIHRvIDEuMCB3aWxsIHByb2R1
Y2UgcmVzcG9uc2VzIHRoYXQgYXJlIG1vcmUKIHZhcmllZCBhbmQgY3JlYXRpdmUsIHdoaWxl
IGEgdmFsdWUgY2xvc2VyIHRvIDAuMCB3aWxsIHR5cGljYWxseSByZXN1bHQgaW4KIG1vcmUg
c3RyYWlnaHRmb3J3YXJkIHJlc3BvbnNlcyBmcm9tIHRoZSBtb2RlbC4KCgwKBQQAAgIEEgNo
AgoKDAoFBAACAgUSA2gLEAoMCgUEAAICARIDaBEcCgwKBQQAAgIDEgNoHyAKDAoFBAACAggS
A2ghSQoPCggEAAICCJwIABIDaCJICpUBCgQEAAIDEgNuAk4ahwEgT3B0aW9uYWwuIE51bWJl
ciBvZiBnZW5lcmF0ZWQgcmVzcG9uc2VzIHRvIHJldHVybi4KCiBUaGlzIHZhbHVlIG11c3Qg
YmUgYmV0d2VlbiBbMSwgOF0sIGluY2x1c2l2ZS4gSWYgdW5zZXQsIHRoaXMgd2lsbCBkZWZh
dWx0CiB0byAxLgoKDAoFBAACAwQSA24CCgoMCgUEAAIDBRIDbgsQCgwKBQQAAgMBEgNuESAK
DAoFBAACAwMSA24jJAoMCgUEAAIDCBIDbiVNCg8KCAQAAgMInAgAEgNuJkwKrgEKBAQAAgQS
A3QCUBqgASBPcHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHRva2VucyB0byBpbmNs
dWRlIGluIGEgY2FuZGlkYXRlLgoKIElmIHVuc2V0LCB0aGlzIHdpbGwgZGVmYXVsdCB0byBv
dXRwdXRfdG9rZW5fbGltaXQgc3BlY2lmaWVkIGluIHRoZSBgTW9kZWxgCiBzcGVjaWZpY2F0
aW9uLgoKDAoFBAACBAQSA3QCCgoMCgUEAAIEBRIDdAsQCgwKBQQAAgQBEgN0ESIKDAoFBAAC
BAMSA3QlJgoMCgUEAAIECBIDdCdPCg8KCAQAAgQInAgAEgN0KE4KpAQKBAQAAgUSBIIBAkQa
lQQgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIGN1bXVsYXRpdmUgcHJvYmFiaWxpdHkgb2YgdG9r
ZW5zIHRvIGNvbnNpZGVyIHdoZW4KIHNhbXBsaW5nLgoKIFRoZSBtb2RlbCB1c2VzIGNvbWJp
bmVkIFRvcC1rIGFuZCBudWNsZXVzIHNhbXBsaW5nLgoKIFRva2VucyBhcmUgc29ydGVkIGJh
c2VkIG9uIHRoZWlyIGFzc2lnbmVkIHByb2JhYmlsaXRpZXMgc28gdGhhdCBvbmx5IHRoZQog
bW9zdCBsaWtlbHkgdG9rZW5zIGFyZSBjb25zaWRlcmVkLiBUb3AtayBzYW1wbGluZyBkaXJl
Y3RseSBsaW1pdHMgdGhlCiBtYXhpbXVtIG51bWJlciBvZiB0b2tlbnMgdG8gY29uc2lkZXIs
IHdoaWxlIE51Y2xldXMgc2FtcGxpbmcgbGltaXRzIG51bWJlcgogb2YgdG9rZW5zIGJhc2Vk
IG9uIHRoZSBjdW11bGF0aXZlIHByb2JhYmlsaXR5LgoKIE5vdGU6IFRoZSBkZWZhdWx0IHZh
bHVlIHZhcmllcyBieSBtb2RlbCwgc2VlIHRoZSBgTW9kZWwudG9wX3BgCiBhdHRyaWJ1dGUg
b2YgdGhlIGBNb2RlbGAgcmV0dXJuZWQgdGhlIGBnZXRNb2RlbGAgZnVuY3Rpb24uCgoNCgUE
AAIFBBIEggECCgoNCgUEAAIFBRIEggELEAoNCgUEAAIFARIEggERFgoNCgUEAAIFAxIEggEZ
GgoNCgUEAAIFCBIEggEbQwoQCggEAAIFCJwIABIEggEcQgraAgoEBAACBhIEjQECRBrLAiBP
cHRpb25hbC4gVGhlIG1heGltdW0gbnVtYmVyIG9mIHRva2VucyB0byBjb25zaWRlciB3aGVu
IHNhbXBsaW5nLgoKIFRoZSBtb2RlbCB1c2VzIGNvbWJpbmVkIFRvcC1rIGFuZCBudWNsZXVz
IHNhbXBsaW5nLgoKIFRvcC1rIHNhbXBsaW5nIGNvbnNpZGVycyB0aGUgc2V0IG9mIGB0b3Bf
a2AgbW9zdCBwcm9iYWJsZSB0b2tlbnMuCiBEZWZhdWx0cyB0byA0MC4KCiBOb3RlOiBUaGUg
ZGVmYXVsdCB2YWx1ZSB2YXJpZXMgYnkgbW9kZWwsIHNlZSB0aGUgYE1vZGVsLnRvcF9rYAog
YXR0cmlidXRlIG9mIHRoZSBgTW9kZWxgIHJldHVybmVkIHRoZSBgZ2V0TW9kZWxgIGZ1bmN0
aW9uLgoKDQoFBAACBgQSBI0BAgoKDQoFBAACBgUSBI0BCxAKDQoFBAACBgESBI0BERYKDQoF
BAACBgMSBI0BGRoKDQoFBAACBggSBI0BG0MKEAoIBAACBgicCAASBI0BHEIK5wQKBAQAAgcS
BJkBAi0a2AQgQSBsaXN0IG9mIHVuaXF1ZSBgU2FmZXR5U2V0dGluZ2AgaW5zdGFuY2VzIGZv
ciBibG9ja2luZyB1bnNhZmUgY29udGVudC4KCiB0aGF0IHdpbGwgYmUgZW5mb3JjZWQgb24g
dGhlIGBHZW5lcmF0ZVRleHRSZXF1ZXN0LnByb21wdGAgYW5kCiBgR2VuZXJhdGVUZXh0UmVz
cG9uc2UuY2FuZGlkYXRlc2AuIFRoZXJlIHNob3VsZCBub3QgYmUgbW9yZSB0aGFuIG9uZQog
c2V0dGluZyBmb3IgZWFjaCBgU2FmZXR5Q2F0ZWdvcnlgIHR5cGUuIFRoZSBBUEkgd2lsbCBi
bG9jayBhbnkgcHJvbXB0cyBhbmQKIHJlc3BvbnNlcyB0aGF0IGZhaWwgdG8gbWVldCB0aGUg
dGhyZXNob2xkcyBzZXQgYnkgdGhlc2Ugc2V0dGluZ3MuIFRoaXMgbGlzdAogb3ZlcnJpZGVz
IHRoZSBkZWZhdWx0IHNldHRpbmdzIGZvciBlYWNoIGBTYWZldHlDYXRlZ29yeWAgc3BlY2lm
aWVkIGluIHRoZQogc2FmZXR5X3NldHRpbmdzLiBJZiB0aGVyZSBpcyBubyBgU2FmZXR5U2V0
dGluZ2AgZm9yIGEgZ2l2ZW4KIGBTYWZldHlDYXRlZ29yeWAgcHJvdmlkZWQgaW4gdGhlIGxp
c3QsIHRoZSBBUEkgd2lsbCB1c2UgdGhlIGRlZmF1bHQgc2FmZXR5CiBzZXR0aW5nIGZvciB0
aGF0IGNhdGVnb3J5LgoKDQoFBAACBwQSBJkBAgoKDQoFBAACBwYSBJkBCxgKDQoFBAACBwES
BJkBGSgKDQoFBAACBwMSBJkBKywK6QEKBAQAAggSBJ4BAiUa2gEgVGhlIHNldCBvZiBjaGFy
YWN0ZXIgc2VxdWVuY2VzICh1cCB0byA1KSB0aGF0IHdpbGwgc3RvcCBvdXRwdXQgZ2VuZXJh
dGlvbi4KIElmIHNwZWNpZmllZCwgdGhlIEFQSSB3aWxsIHN0b3AgYXQgdGhlIGZpcnN0IGFw
cGVhcmFuY2Ugb2YgYSBzdG9wCiBzZXF1ZW5jZS4gVGhlIHN0b3Agc2VxdWVuY2Ugd2lsbCBu
b3QgYmUgaW5jbHVkZWQgYXMgcGFydCBvZiB0aGUgcmVzcG9uc2UuCgoNCgUEAAIIBBIEngEC
CgoNCgUEAAIIBRIEngELEQoNCgUEAAIIARIEngESIAoNCgUEAAIIAxIEngEjJApNCgIEARIG
ogEAtQEBGj8gVGhlIHJlc3BvbnNlIGZyb20gdGhlIG1vZGVsLCBpbmNsdWRpbmcgY2FuZGlk
YXRlIGNvbXBsZXRpb25zLgoKCwoDBAEBEgSiAQgcCjMKBAQBAgASBKQBAikaJSBDYW5kaWRh
dGUgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgoKDQoFBAECAAQSBKQBAgoKDQoFBAECAAYS
BKQBCxkKDQoFBAECAAESBKQBGiQKDQoFBAECAAMSBKQBJygK+gMKBAQBAgESBLEBAiUa6wMg
QSBzZXQgb2YgY29udGVudCBmaWx0ZXJpbmcgbWV0YWRhdGEgZm9yIHRoZSBwcm9tcHQgYW5k
IHJlc3BvbnNlCiB0ZXh0LgoKIFRoaXMgaW5kaWNhdGVzIHdoaWNoIGBTYWZldHlDYXRlZ29y
eWAocykgYmxvY2tlZCBhCiBjYW5kaWRhdGUgZnJvbSB0aGlzIHJlc3BvbnNlLCB0aGUgbG93
ZXN0IGBIYXJtUHJvYmFiaWxpdHlgCiB0aGF0IHRyaWdnZXJlZCBhIGJsb2NrLCBhbmQgdGhl
IEhhcm1UaHJlc2hvbGQgc2V0dGluZyBmb3IgdGhhdCBjYXRlZ29yeS4KIFRoaXMgaW5kaWNh
dGVzIHRoZSBzbWFsbGVzdCBjaGFuZ2UgdG8gdGhlIGBTYWZldHlTZXR0aW5nc2AgdGhhdCB3
b3VsZCBiZQogbmVjZXNzYXJ5IHRvIHVuYmxvY2sgYXQgbGVhc3QgMSByZXNwb25zZS4KCiBU
aGUgYmxvY2tpbmcgaXMgY29uZmlndXJlZCBieSB0aGUgYFNhZmV0eVNldHRpbmdzYCBpbiB0
aGUgcmVxdWVzdCAob3IgdGhlCiBkZWZhdWx0IGBTYWZldHlTZXR0aW5nc2Agb2YgdGhlIEFQ
SSkuCgoNCgUEAQIBBBIEsQECCgoNCgUEAQIBBhIEsQELGAoNCgUEAQIBARIEsQEZIAoNCgUE
AQIBAxIEsQEjJApJCgQEAQICEgS0AQIuGjsgUmV0dXJucyBhbnkgc2FmZXR5IGZlZWRiYWNr
IHJlbGF0ZWQgdG8gY29udGVudCBmaWx0ZXJpbmcuCgoNCgUEAQICBBIEtAECCgoNCgUEAQIC
BhIEtAELGQoNCgUEAQICARIEtAEaKQoNCgUEAQICAxIEtAEsLQp4CgIEAhIGugEAvQEBGmog
VGV4dCBnaXZlbiB0byB0aGUgbW9kZWwgYXMgYSBwcm9tcHQuCgogVGhlIE1vZGVsIHdpbGwg
dXNlIHRoaXMgVGV4dFByb21wdCB0byBHZW5lcmF0ZSBhIHRleHQgY29tcGxldGlvbi4KCgsK
AwQCARIEugEIEgoqCgQEAgIAEgS8AQI7GhwgUmVxdWlyZWQuIFRoZSBwcm9tcHQgdGV4dC4K
Cg0KBQQCAgAFEgS8AQIICg0KBQQCAgABEgS8AQkNCg0KBQQCAgADEgS8ARARCg0KBQQCAgAI
EgS8ARI6ChAKCAQCAgAInAgAEgS8ARM5CjIKAgQDEgbAAQDQAQEaJCBPdXRwdXQgdGV4dCBy
ZXR1cm5lZCBmcm9tIGEgbW9kZWwuCgoLCgMEAwESBMABCBYKSAoEBAMCABIEwgECQBo6IE91
dHB1dCBvbmx5LiBUaGUgZ2VuZXJhdGVkIHRleHQgcmV0dXJuZWQgZnJvbSB0aGUgbW9kZWwu
CgoNCgUEAwIABRIEwgECCAoNCgUEAwIAARIEwgEJDwoNCgUEAwIAAxIEwgESEwoNCgUEAwIA
CBIEwgEUPwoQCggEAwIACJwIABIEwgEVPgphCgQEAwIBEgTHAQIrGlMgUmF0aW5ncyBmb3Ig
dGhlIHNhZmV0eSBvZiBhIHJlc3BvbnNlLgoKIFRoZXJlIGlzIGF0IG1vc3Qgb25lIHJhdGlu
ZyBwZXIgY2F0ZWdvcnkuCgoNCgUEAwIBBBIExwECCgoNCgUEAwIBBhIExwELFwoNCgUEAwIB
ARIExwEYJgoNCgUEAwIBAxIExwEpKgrPAQoEBAMCAhIGzgECzwEyGr4BIE91dHB1dCBvbmx5
LiBDaXRhdGlvbiBpbmZvcm1hdGlvbiBmb3IgbW9kZWwtZ2VuZXJhdGVkIGBvdXRwdXRgIGlu
IHRoaXMKIGBUZXh0Q29tcGxldGlvbmAuCgogVGhpcyBmaWVsZCBtYXkgYmUgcG9wdWxhdGVk
IHdpdGggYXR0cmlidXRpb24gaW5mb3JtYXRpb24gZm9yIGFueSB0ZXh0CiBpbmNsdWRlZCBp
biB0aGUgYG91dHB1dGAuCgoNCgUEAwICBBIEzgECCgoNCgUEAwICBhIEzgELGwoNCgUEAwIC
ARIEzgEcLQoNCgUEAwICAxIEzgEwMQoNCgUEAwICCBIEzwEGMQoQCggEAwICCJwIABIEzwEH
MAo/CgIEBBIG0wEA3wEBGjEgUmVxdWVzdCB0byBnZXQgYSB0ZXh0IGVtYmVkZGluZyBmcm9t
IHRoZSBtb2RlbC4KCgsKAwQEARIE0wEIGApXCgQEBAIAEgbVAQLaAQQaRyBSZXF1aXJlZC4g
VGhlIG1vZGVsIG5hbWUgdG8gdXNlIHdpdGggdGhlIGZvcm1hdCBtb2RlbD1tb2RlbHMve21v
ZGVsfS4KCg0KBQQEAgAFEgTVAQIICg0KBQQEAgABEgTVAQkOCg0KBQQEAgADEgTVARESCg8K
BQQEAgAIEgbVARPaAQMKEAoIBAQCAAicCAASBNYBBCoKEQoHBAQCAAifCBIG1wEE2QEFCl8K
BAQEAgESBN4BAjsaUSBSZXF1aXJlZC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0IHRoYXQg
dGhlIG1vZGVsIHdpbGwgdHVybiBpbnRvIGFuCiBlbWJlZGRpbmcuCgoNCgUEBAIBBRIE3gEC
CAoNCgUEBAIBARIE3gEJDQoNCgUEBAIBAxIE3gEQEQoNCgUEBAIBCBIE3gESOgoQCggEBAIB
CJwIABIE3gETOQozCgIEBRIG4gEA5QEBGiUgVGhlIHJlc3BvbnNlIHRvIGEgRW1iZWRUZXh0
UmVxdWVzdC4KCgsKAwQFARIE4gEIGQpJCgQEBQIAEgTkAQJPGjsgT3V0cHV0IG9ubHkuIFRo
ZSBlbWJlZGRpbmcgZ2VuZXJhdGVkIGZyb20gdGhlIGlucHV0IHRleHQuCgoNCgUEBQIABBIE
5AECCgoNCgUEBQIABhIE5AELFAoNCgUEBQIAARIE5AEVHgoNCgUEBQIAAxIE5AEhIgoNCgUE
BQIACBIE5AEjTgoQCggEBQIACJwIABIE5AEkTQpFCgIEBhIG6AEA9wEBGjcgQmF0Y2ggcmVx
dWVzdCB0byBnZXQgYSB0ZXh0IGVtYmVkZGluZyBmcm9tIHRoZSBtb2RlbC4KCgsKAwQGARIE
6AEIHQqAAQoEBAYCABIG7AEC8QEEGnAgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBgTW9k
ZWxgIHRvIHVzZSBmb3IgZ2VuZXJhdGluZyB0aGUgZW1iZWRkaW5nLgogRXhhbXBsZXM6CiAg
bW9kZWxzL2VtYmVkZGluZy1nZWNrby0wMDEKCg0KBQQGAgAFEgTsAQIICg0KBQQGAgABEgTs
AQkOCg0KBQQGAgADEgTsARESCg8KBQQGAgAIEgbsARPxAQMKEAoIBAYCAAicCAASBO0BBCoK
EQoHBAYCAAifCBIG7gEE8AEFCqcBCgQEBgIBEgT2AQJFGpgBIFJlcXVpcmVkLiBUaGUgZnJl
ZS1mb3JtIGlucHV0IHRleHRzIHRoYXQgdGhlIG1vZGVsIHdpbGwgdHVybiBpbnRvIGFuCiBl
bWJlZGRpbmcuICBUaGUgY3VycmVudCBsaW1pdCBpcyAxMDAgdGV4dHMsIG92ZXIgd2hpY2gg
YW4gZXJyb3Igd2lsbCBiZQogdGhyb3duLgoKDQoFBAYCAQQSBPYBAgoKDQoFBAYCAQUSBPYB
CxEKDQoFBAYCAQESBPYBEhcKDQoFBAYCAQMSBPYBGhsKDQoFBAYCAQgSBPYBHEQKEAoIBAYC
AQicCAASBPYBHUMKMwoCBAcSBvoBAP0BARolIFRoZSByZXNwb25zZSB0byBhIEVtYmVkVGV4
dFJlcXVlc3QuCgoLCgMEBwESBPoBCB4KSgoEBAcCABIE/AECUBo8IE91dHB1dCBvbmx5LiBU
aGUgZW1iZWRkaW5ncyBnZW5lcmF0ZWQgZnJvbSB0aGUgaW5wdXQgdGV4dC4KCg0KBQQHAgAE
EgT8AQIKCg0KBQQHAgAGEgT8AQsUCg0KBQQHAgABEgT8ARUfCg0KBQQHAgADEgT8ASIjCg0K
BQQHAgAIEgT8ASRPChAKCAQHAgAInAgAEgT8ASVOCjwKAgQIEgaAAgCDAgEaLiBBIGxpc3Qg
b2YgZmxvYXRzIHJlcHJlc2VudGluZyB0aGUgZW1iZWRkaW5nLgoKCwoDBAgBEgSAAggRCiUK
BAQIAgASBIICAhsaFyBUaGUgZW1iZWRkaW5nIHZhbHVlcy4KCg0KBQQIAgAEEgSCAgIKCg0K
BQQIAgAFEgSCAgsQCg0KBQQIAgABEgSCAhEWCg0KBQQIAgADEgSCAhkaCqoBCgIECRIGiQIA
mQIBGpsBIENvdW50cyB0aGUgbnVtYmVyIG9mIHRva2VucyBpbiB0aGUgYHByb21wdGAgc2Vu
dCB0byBhIG1vZGVsLgoKIE1vZGVscyBtYXkgdG9rZW5pemUgdGV4dCBkaWZmZXJlbnRseSwg
c28gZWFjaCBtb2RlbCBtYXkgcmV0dXJuIGEgZGlmZmVyZW50CiBgdG9rZW5fY291bnRgLgoK
CwoDBAkBEgSJAggeCskBCgQECQIAEgaQAgKVAgQauAEgUmVxdWlyZWQuIFRoZSBtb2RlbCdz
IHJlc291cmNlIG5hbWUuIFRoaXMgc2VydmVzIGFzIGFuIElEIGZvciB0aGUgTW9kZWwgdG8K
IHVzZS4KCiBUaGlzIG5hbWUgc2hvdWxkIG1hdGNoIGEgbW9kZWwgbmFtZSByZXR1cm5lZCBi
eSB0aGUgYExpc3RNb2RlbHNgIG1ldGhvZC4KCiBGb3JtYXQ6IGBtb2RlbHMve21vZGVsfWAK
Cg0KBQQJAgAFEgSQAgIICg0KBQQJAgABEgSQAgkOCg0KBQQJAgADEgSQAhESCg8KBQQJAgAI
EgaQAhOVAgMKEAoIBAkCAAicCAASBJECBCoKEQoHBAkCAAifCBIGkgIElAIFClIKBAQJAgES
BJgCAkEaRCBSZXF1aXJlZC4gVGhlIGZyZWUtZm9ybSBpbnB1dCB0ZXh0IGdpdmVuIHRvIHRo
ZSBtb2RlbCBhcyBhIHByb21wdC4KCg0KBQQJAgEGEgSYAgIMCg0KBQQJAgEBEgSYAg0TCg0K
BQQJAgEDEgSYAhYXCg0KBQQJAgEIEgSYAhhAChAKCAQJAgEInAgAEgSYAhk/CmsKAgQKEgae
AgCjAgEaXSBBIHJlc3BvbnNlIGZyb20gYENvdW50VGV4dFRva2Vuc2AuCgogSXQgcmV0dXJu
cyB0aGUgbW9kZWwncyBgdG9rZW5fY291bnRgIGZvciB0aGUgYHByb21wdGAuCgoLCgMECgES
BJ4CCB8KaQoEBAoCABIEogICGBpbIFRoZSBudW1iZXIgb2YgdG9rZW5zIHRoYXQgdGhlIGBt
b2RlbGAgdG9rZW5pemVzIHRoZSBgcHJvbXB0YCBpbnRvLgoKIEFsd2F5cyBub24tbmVnYXRp
dmUuCgoNCgUECgIABRIEogICBwoNCgUECgIAARIEogIIEwoNCgUECgIAAxIEogIWF2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest ===
    # Fields for GenerateTextRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta3.TextPrompt)
    # Field: temperature Type: 2 ()
    # Field: candidate_count Type: 5 ()
    # Field: max_output_tokens Type: 5 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: safety_settings Type: 11 (.google.ai.generativelanguage.v1beta3.SafetySetting)
    # Field: stop_sequences Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse ===
    # Fields for GenerateTextResponse
    # Field: candidates Type: 11 (.google.ai.generativelanguage.v1beta3.TextCompletion)
    # Field: filters Type: 11 (.google.ai.generativelanguage.v1beta3.ContentFilter)
    # Field: safety_feedback Type: 11 (.google.ai.generativelanguage.v1beta3.SafetyFeedback)

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt ===
    # Fields for TextPrompt
    # Field: text Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::TextCompletion ===
    # Fields for TextCompletion
    # Field: output Type: 9 ()
    # Field: safety_ratings Type: 11 (.google.ai.generativelanguage.v1beta3.SafetyRating)
    # Field: citation_metadata Type: 11 (.google.ai.generativelanguage.v1beta3.CitationMetadata)

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest ===
    # Fields for EmbedTextRequest
    # Field: model Type: 9 ()
    # Field: text Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse ===
    # Fields for EmbedTextResponse
    # Field: embedding Type: 11 (.google.ai.generativelanguage.v1beta3.Embedding)

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest ===
    # Fields for BatchEmbedTextRequest
    # Field: model Type: 9 ()
    # Field: texts Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse ===
    # Fields for BatchEmbedTextResponse
    # Field: embeddings Type: 11 (.google.ai.generativelanguage.v1beta3.Embedding)

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::Embedding ===
    # Fields for Embedding
    # Field: value Type: 2 ()

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest ===
    # Fields for CountTextTokensRequest
    # Field: model Type: 9 ()
    # Field: prompt Type: 11 (.google.ai.generativelanguage.v1beta3.TextPrompt)

# === Message: Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse ===
    # Fields for CountTextTokensResponse
    # Field: token_count Type: 5 ()

# === Service Client: Google::Ai::Generativelanguage::V1beta3::TextService::TextServiceClient ===
package Google::Ai::Generativelanguage::V1beta3::TextService::TextServiceClient;

=pod

=head2 Service Client: Google::Ai::Generativelanguage::V1beta3::TextService::TextServiceClient

Client stub representing the remote C<TextService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub generate_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'GenerateText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse',
    });
}

sub embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'EmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse',
    });
}

sub batch_embed_text {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'BatchEmbedText',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse',
    });
}

sub count_text_tokens {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.ai.generativelanguage.v1beta3.TextService',
        method         => 'CountTextTokens',
        request        => $req,
        response_class => 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::TextService - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1beta3/text_service.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::TextService;

    my $msg = Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest->new({
        model => $model,
        prompt => $prompt,
        temperature => $temperature,
        candidate_count => $candidate_count,
    });

    # Read or update a field
    my $val = $msg->model();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1beta3/text_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest

Request to generate a text completion response from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the `Model` or `TunedModel` to use for generating the
completion.
Examples:
 models/text-bison-001
 tunedModels/sentence-translator-u3b7m

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>)

Required. The free-form input text given to the model as a prompt.

Given a prompt, the model will generate a TextCompletion response it
predicts as the completion of the input text.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.
Note: The default value varies by model, see the `Model.temperature`
attribute of the `Model` returned the `getModel` function.

Values can range from [0.0,1.0],
inclusive. A value closer to 1.0 will produce responses that are more
varied and creative, while a value closer to 0.0 will typically result in
more straightforward responses from the model.

=item * C<< $msg->candidate_count() >> / C<< $msg->candidate_count($value) >>

Type: C<Int32>

Optional. Number of generated responses to return.

This value must be between [1, 8], inclusive. If unset, this will default
to 1.

=item * C<< $msg->max_output_tokens() >> / C<< $msg->max_output_tokens($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to include in a candidate.

If unset, this will default to output_token_limit specified in the `Model`
specification.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. The maximum cumulative probability of tokens to consider when
sampling.

The model uses combined Top-k and nucleus sampling.

Tokens are sorted based on their assigned probabilities so that only the
most likely tokens are considered. Top-k sampling directly limits the
maximum number of tokens to consider, while Nucleus sampling limits number
of tokens based on the cumulative probability.

Note: The default value varies by model, see the `Model.top_p`
attribute of the `Model` returned the `getModel` function.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. The maximum number of tokens to consider when sampling.

The model uses combined Top-k and nucleus sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
Defaults to 40.

Note: The default value varies by model, see the `Model.top_k`
attribute of the `Model` returned the `getModel` function.

=item * C<< $msg->safety_settings() >> / C<< $msg->safety_settings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetySetting>)

A list of unique `SafetySetting` instances for blocking unsafe content.

that will be enforced on the `GenerateTextRequest.prompt` and
`GenerateTextResponse.candidates`. There should not be more than one
setting for each `SafetyCategory` type. The API will block any prompts and
responses that fail to meet the thresholds set by these settings. This list
overrides the default settings for each `SafetyCategory` specified in the
safety_settings. If there is no `SafetySetting` for a given
`SafetyCategory` provided in the list, the API will use the default safety
setting for that category.

=item * C<< $msg->stop_sequences() >> / C<< $msg->stop_sequences($value) >>

Type: C<String>

The set of character sequences (up to 5) that will stop output generation.
If specified, the API will stop at the first appearance of a stop
sequence. The stop sequence will not be included as part of the response.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse

The response from the model, including candidate completions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->candidates() >> / C<< $msg->candidates($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TextService::TextCompletion>)

Candidate responses from the model.

=item * C<< $msg->filters() >> / C<< $msg->filters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::ContentFilter>)

A set of content filtering metadata for the prompt and response
text.

This indicates which `SafetyCategory`(s) blocked a
candidate from this response, the lowest `HarmProbability`
that triggered a block, and the HarmThreshold setting for that category.
This indicates the smallest change to the `SafetySettings` that would be
necessary to unblock at least 1 response.

The blocking is configured by the `SafetySettings` in the request (or the
default `SafetySettings` of the API).

=item * C<< $msg->safety_feedback() >> / C<< $msg->safety_feedback($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetyFeedback>)

Returns any safety feedback related to content filtering.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt

Text given to the model as a prompt.

The Model will use this TextPrompt to Generate a text completion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. The prompt text.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::TextCompletion

Output text returned from a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<String>

Output only. The generated text returned from the model.

=item * C<< $msg->safety_ratings() >> / C<< $msg->safety_ratings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Safety::SafetyRating>)

Ratings for the safety of a response.

There is at most one rating per category.

=item * C<< $msg->citation_metadata() >> / C<< $msg->citation_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::Citation::CitationMetadata>)

Output only. Citation information for model-generated `output` in this
`TextCompletion`.

This field may be populated with attribution information for any text
included in the `output`.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest

Request to get a text embedding from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The model name to use with the format model=models/{model}.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Required. The free-form input text that the model will turn into an
embedding.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse

The response to a EmbedTextRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->embedding() >> / C<< $msg->embedding($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TextService::Embedding>)

Output only. The embedding generated from the input text.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest

Batch request to get a text embedding from the model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model() >> / C<< $msg->model($value) >>

Type: C<String>

Required. The name of the `Model` to use for generating the embedding.
Examples:
 models/embedding-gecko-001

=item * C<< $msg->texts() >> / C<< $msg->texts($value) >>

Type: C<String>

Required. The free-form input texts that the model will turn into an
embedding.  The current limit is 100 texts, over which an error will be
thrown.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse

The response to a EmbedTextRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->embeddings() >> / C<< $msg->embeddings($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TextService::Embedding>)

Output only. The embeddings generated from the input text.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::Embedding

A list of floats representing the embedding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Float>

The embedding values.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest

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

Type: C<Message> (L<Google::Ai::Generativelanguage::V1beta3::TextService::TextPrompt>)

Required. The free-form input text given to the model as a prompt.

=back

=head2 Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse

A response from `CountTextTokens`.

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1beta3::TextService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
