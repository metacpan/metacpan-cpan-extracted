package Google::Cloud::Ces::V1beta::Agent;

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
    eval { require Google::Cloud::Ces::V1beta::AgentCard };
    eval { require Google::Cloud::Ces::V1beta::AgentTransfers };
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hZ2VudC5wcm90bxIXZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2FnZW50X2NhcmQucHJv
dG8aLWdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2FnZW50X3RyYW5zZmVycy5wcm90bxokZ29v
Z2xlL2Nsb3VkL2Nlcy92MWJldGEvY29tbW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIt4VCgVBZ2VudBJLCglsbG1fYWdlbnQYGiABKAsyJy5nb29nbGUuY2xv
dWQuY2VzLnYxYmV0YS5BZ2VudC5MbG1BZ2VudEID4EEBSABSCGxsbUFnZW50EnMKF3JlbW90
ZV9kaWFsb2dmbG93X2FnZW50GBsgASgLMjQuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuQWdl
bnQuUmVtb3RlRGlhbG9nZmxvd0FnZW50QgPgQQFIAFIVcmVtb3RlRGlhbG9nZmxvd0FnZW50
El4KEHJlbW90ZV9hMmFfYWdlbnQYKSABKAsyLS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5B
Z2VudC5SZW1vdGVBMmFBZ2VudEID4EEBSABSDnJlbW90ZUEyYUFnZW50EhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUS
JQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SUgoObW9kZWxfc2V0dGlu
Z3MYBCABKAsyJi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Nb2RlbFNldHRpbmdzQgPgQQFS
DW1vZGVsU2V0dGluZ3MSJQoLaW5zdHJ1Y3Rpb24YBiABKAlCA+BBAVILaW5zdHJ1Y3Rpb24S
NQoFdG9vbHMYByADKAlCH+BBAfpBGQoXY2VzLmdvb2dsZWFwaXMuY29tL1Rvb2xSBXRvb2xz
EkMKDGNoaWxkX2FnZW50cxgIIAMoCUIg4EEB+kEaChhjZXMuZ29vZ2xlYXBpcy5jb20vQWdl
bnRSC2NoaWxkQWdlbnRzElwKFmJlZm9yZV9hZ2VudF9jYWxsYmFja3MYEiADKAsyIS5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YS5DYWxsYmFja0ID4EEBUhRiZWZvcmVBZ2VudENhbGxiYWNr
cxJaChVhZnRlcl9hZ2VudF9jYWxsYmFja3MYEyADKAsyIS5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5DYWxsYmFja0ID4EEBUhNhZnRlckFnZW50Q2FsbGJhY2tzElwKFmJlZm9yZV9tb2Rl
bF9jYWxsYmFja3MYFCADKAsyIS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5DYWxsYmFja0ID
4EEBUhRiZWZvcmVNb2RlbENhbGxiYWNrcxJaChVhZnRlcl9tb2RlbF9jYWxsYmFja3MYFSAD
KAsyIS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5DYWxsYmFja0ID4EEBUhNhZnRlck1vZGVs
Q2FsbGJhY2tzEloKFWJlZm9yZV90b29sX2NhbGxiYWNrcxgWIAMoCzIhLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLkNhbGxiYWNrQgPgQQFSE2JlZm9yZVRvb2xDYWxsYmFja3MSWAoUYWZ0
ZXJfdG9vbF9jYWxsYmFja3MYFyADKAsyIS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5DYWxs
YmFja0ID4EEBUhJhZnRlclRvb2xDYWxsYmFja3MSQAoLY3JlYXRlX3RpbWUYDyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYECABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
RAoKZ3VhcmRyYWlscxgRIAMoCUIk4EEB+kEeChxjZXMuZ29vZ2xlYXBpcy5jb20vR3VhcmRy
YWlsUgpndWFyZHJhaWxzEhIKBGV0YWcYGCABKAlSBGV0YWcSTAoIdG9vbHNldHMYHCADKAsy
Ky5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5BZ2VudC5BZ2VudFRvb2xzZXRCA+BBAVIIdG9v
bHNldHMSMAoRZ2VuZXJhdGVkX3N1bW1hcnkYHSABKAlCA+BBA1IQZ2VuZXJhdGVkU3VtbWFy
eRJRCg50cmFuc2Zlcl9ydWxlcxgeIAMoCzIlLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRy
YW5zZmVyUnVsZUID4EEBUg10cmFuc2ZlclJ1bGVzEjAKEXZhbGlkYXRpb25fZXJyb3JzGCAg
AygJQgPgQQNSEHZhbGlkYXRpb25FcnJvcnMaCgoITGxtQWdlbnQa7QUKFVJlbW90ZURpYWxv
Z2Zsb3dBZ2VudBJHCgVhZ2VudBgBIAEoCUIx4EEC+kErCilkaWFsb2dmbG93Lmdvb2dsZWFw
aXMuY29tL0RpYWxvZ2Zsb3dBZ2VudFIFYWdlbnQSHAoHZmxvd19pZBgCIAEoCUID4EEBUgZm
bG93SWQSKgoOZW52aXJvbm1lbnRfaWQYAyABKAlCA+BBAVINZW52aXJvbm1lbnRJZBKJAQoW
aW5wdXRfdmFyaWFibGVfbWFwcGluZxgEIAMoCzJOLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LkFnZW50LlJlbW90ZURpYWxvZ2Zsb3dBZ2VudC5JbnB1dFZhcmlhYmxlTWFwcGluZ0VudHJ5
QgPgQQFSFGlucHV0VmFyaWFibGVNYXBwaW5nEowBChdvdXRwdXRfdmFyaWFibGVfbWFwcGlu
ZxgFIAMoCzJPLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkFnZW50LlJlbW90ZURpYWxvZ2Zs
b3dBZ2VudC5PdXRwdXRWYXJpYWJsZU1hcHBpbmdFbnRyeUID4EEBUhVvdXRwdXRWYXJpYWJs
ZU1hcHBpbmcSWAomcmVzcGVjdF9yZXNwb25zZV9pbnRlcnJ1cHRpb25fc2V0dGluZ3MYBiAB
KAhCA+BBAVIjcmVzcGVjdFJlc3BvbnNlSW50ZXJydXB0aW9uU2V0dGluZ3MSOQoWbGFuZ3Vh
Z2VfY29kZV92YXJpYWJsZRgHIAEoCUID4EEBUhRsYW5ndWFnZUNvZGVWYXJpYWJsZRpHChlJ
bnB1dFZhcmlhYmxlTWFwcGluZ0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIg
ASgJUgV2YWx1ZToCOAEaSAoaT3V0cHV0VmFyaWFibGVNYXBwaW5nRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARpeCg5SZW1vdGVBMmFBZ2VudBJM
CgphMmFfY29uZmlnGAEgASgLMiguZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuUmVtb3RlQTJh
Q29uZmlnQgPgQQJSCWEyYUNvbmZpZxpsCgxBZ2VudFRvb2xzZXQSPAoHdG9vbHNldBgBIAEo
CUIi4EEC+kEcChpjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbHNldFIHdG9vbHNldBIeCgh0b29s
X2lkcxgEIAMoCUID4EEBUgd0b29sSWRzOm/qQWwKGGNlcy5nb29nbGVhcGlzLmNvbS9BZ2Vu
dBJBcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0v
YWdlbnRzL3thZ2VudH0qBmFnZW50czIFYWdlbnRCDAoKYWdlbnRfdHlwZULAAQobY29tLmdv
b2dsZS5jbG91ZC5jZXMudjFiZXRhQgpBZ2VudFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20v
Z28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYupBYwopZGlhbG9nZmxvdy5nb29nbGVhcGlz
LmNvbS9EaWFsb2dmbG93QWdlbnQSNnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hZ2VudHMve2FnZW50fUqJVAoHEgUOAIICAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQAMgoJCgIDAxIDFQA3CgkKAgMEEgMWAC4KCQoCAwUSAxcAKQoICgEIEgMZAEQKCQoCCAsS
AxkARAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbACsKCQoCCAgSAxsAKwoICgEIEgMc
ADQKCQoCCAESAxwANAoJCgEIEgQdACACCgwKBAidCAASBB0AIAIKmwEKAgQAEgUkAIICARqN
ASBBbiBhZ2VudCBhY3RzIGFzIHRoZSBmdW5kYW1lbnRhbCBidWlsZGluZyBibG9jayB0aGF0
IHByb3ZpZGVzIGluc3RydWN0aW9ucyB0bwogdGhlIExhcmdlIExhbmd1YWdlIE1vZGVsIChM
TE0pIGZvciBleGVjdXRpbmcgc3BlY2lmaWMgdGFza3MuCgoKCgMEAAESAyQIDQoLCgMEAAcS
BCUCKgQKDQoFBAAHnQgSBCUCKgQKlwEKBAQAAwASAy4CFRqJASBEZWZhdWx0IGFnZW50IHR5
cGUuIFRoZSBhZ2VudCB1c2VzIGluc3RydWN0aW9ucyBhbmQgY2FsbGJhY2tzIHNwZWNpZmll
ZCBpbgogdGhlIGFnZW50IHRvIHBlcmZvcm0gdGhlIHRhc2sgdXNpbmcgYSBsYXJnZSBsYW5n
dWFnZSBtb2RlbC4KCgwKBQQAAwABEgMuChIKvAIKBAQAAwESBDYCZAMarQIgVGhlIGFnZW50
IHdoaWNoIHdpbGwgdHJhbnNmZXIgZXhlY3V0aW9uIHRvIGEgcmVtb3RlCiBbRGlhbG9nZmxv
dwogQ1hdKGh0dHBzOi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvY3gvZG9j
cy9jb25jZXB0L2FnZW50KSBhZ2VudC4KIFRoZSBEaWFsb2dmbG93IGFnZW50IHdpbGwgcHJv
Y2VzcyBzdWJzZXF1ZW50IHVzZXIgcXVlcmllcyB1bnRpbCB0aGUgc2Vzc2lvbgogZW5kcyBv
ciBmbG93IGVuZHMsIGFuZCB0aGUgY29udHJvbCBpcyB0cmFuc2ZlcnJlZCBiYWNrIHRvIHRo
ZSBwYXJlbnQgQ0VTCiBhZ2VudC4KCgwKBQQAAwEBEgM2Ch8KxgEKBgQAAwECABIEOwRABhq1
ASBSZXF1aXJlZC4gVGhlCiBbRGlhbG9nZmxvd10oaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2ds
ZS5jb20vZGlhbG9nZmxvdy9jeC9kb2NzL2NvbmNlcHQvYWdlbnQpCiBhZ2VudCByZXNvdXJj
ZSBuYW1lLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2FnZW50cy97YWdlbnR9YAoKDgoHBAADAQIABRIDOwQKCg4KBwQAAwECAAESAzsLEAoO
CgcEAAMBAgADEgM7ExQKDwoHBAADAQIACBIEOxVABQoRCgoEAAMBAgAInAgAEgM8BiwKEQoJ
BAADAQIACJ8IEgQ9Bj8HCksKBgQAAwECARIDQwRAGjwgT3B0aW9uYWwuIFRoZSBmbG93IElE
IG9mIHRoZSBmbG93IGluIHRoZSBEaWFsb2dmbG93IGFnZW50LgoKDgoHBAADAQIBBRIDQwQK
Cg4KBwQAAwECAQESA0MLEgoOCgcEAAMBAgEDEgNDFRYKDgoHBAADAQIBCBIDQxc/ChEKCgQA
AwECAQicCAASA0MYPgqhAQoGBAADAQICEgNHBEcakQEgT3B0aW9uYWwuIFRoZSBlbnZpcm9u
bWVudCBJRCBvZiB0aGUgRGlhbG9nZmxvdyBhZ2VudCB0byBiZSB1c2VkIGZvciB0aGUKIGFn
ZW50IGV4ZWN1dGlvbi4gSWYgbm90IHNwZWNpZmllZCwgdGhlIGRyYWZ0IGVudmlyb25tZW50
IHdpbGwgYmUgdXNlZC4KCg4KBwQAAwECAgUSA0cECgoOCgcEAAMBAgIBEgNHCxkKDgoHBAAD
AQICAxIDRxwdCg4KBwQAAwECAggSA0ceRgoRCgoEAAMBAgIInAgAEgNHH0UKnAEKBgQAAwEC
AxIESwRMMRqLASBPcHRpb25hbC4gVGhlIG1hcHBpbmcgb2YgdGhlIGFwcCB2YXJpYWJsZXMg
bmFtZXMgdG8gdGhlIERpYWxvZ2Zsb3cKIHNlc3Npb24gcGFyYW1ldGVycyBuYW1lcyB0byBi
ZSBzZW50IHRvIHRoZSBEaWFsb2dmbG93IGFnZW50IGFzIGlucHV0LgoKDgoHBAADAQIDBhID
SwQXCg4KBwQAAwECAwESA0sYLgoOCgcEAAMBAgMDEgNLMTIKDgoHBAADAQIDCBIDTAgwChEK
CgQAAwECAwicCAASA0wJLwq8AQoGBAADAQIEEgRRBFIxGqsBIE9wdGlvbmFsLiBUaGUgbWFw
cGluZyBvZiB0aGUgRGlhbG9nZmxvdyBzZXNzaW9uIHBhcmFtZXRlcnMgbmFtZXMgdG8gdGhl
CiBhcHAgdmFyaWFibGVzIG5hbWVzIHRvIGJlIHNlbnQgYmFjayB0byB0aGUgQ0VTIGFnZW50
IGFmdGVyIHRoZSBEaWFsb2dmbG93CiBhZ2VudCBleGVjdXRpb24gZW5kcy4KCg4KBwQAAwEC
BAYSA1EEFwoOCgcEAAMBAgQBEgNRGC8KDgoHBAADAQIEAxIDUTIzCg4KBwQAAwECBAgSA1II
MAoRCgoEAAMBAgQInAgAEgNSCS8K+QMKBgQAAwECBRIEXQReMRroAyBPcHRpb25hbC4gSW5k
aWNhdGVzIHdoZXRoZXIgdG8gcmVzcGVjdCB0aGUgbWVzc2FnZS1sZXZlbCBpbnRlcnJ1cHRp
b24KIHNldHRpbmdzIGNvbmZpZ3VyZWQgaW4gdGhlIERpYWxvZ2Zsb3cgYWdlbnQuCgogKiBJ
ZiBmYWxzZTogYWxsIHJlc3BvbnNlIG1lc3NhZ2VzIGZyb20gdGhlIERpYWxvZ2Zsb3cgYWdl
bnQgZm9sbG93IHRoZQogYXBwLWxldmVsIGJhcmdlLWluIHNldHRpbmdzLgogKiBJZiB0cnVl
OiBvbmx5IHJlc3BvbnNlIG1lc3NhZ2VzIHdpdGgKIFtgYWxsb3dfcGxheWJhY2tfaW50ZXJy
dXB0aW9uYF0oaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vZGlhbG9nZmxvdy9jeC9k
b2NzL3JlZmVyZW5jZS9ycGMvZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjMjdGV4dCkK
IHNldCB0byB0cnVlIHdpbGwgYmUgaW50ZXJydXB0YWJsZSwgYWxsIG90aGVyIG1lc3NhZ2Vz
IGZvbGxvdyB0aGUKIGFwcC1sZXZlbCBiYXJnZS1pbiBzZXR0aW5ncy4KCg4KBwQAAwECBQUS
A10ECAoOCgcEAAMBAgUBEgNdCS8KDgoHBAADAQIFAxIDXTIzCg4KBwQAAwECBQgSA14IMAoR
CgoEAAMBAgUInAgAEgNeCS8KzQEKBgQAAwECBhIDYwRPGr0BIE9wdGlvbmFsLiBUaGUgbmFt
ZSBvZiB0aGUgdmFyaWFibGUgdGhhdCBjb250YWlucyB0aGUgbGFuZ3VhZ2UgY29kZSB0byBi
ZQogdXNlZCBmb3IgdGhlIERpYWxvZ2Zsb3cgc2Vzc2lvbi4gSWYgdW5zcGVjaWZpZWQsIHRo
ZSBkZWZhdWx0IGxhbmd1YWdlCiBjb2RlIG9mIHRoZSBEaWFsb2dmbG93IGFnZW50IHdpbGwg
YmUgdXNlZC4KCg4KBwQAAwECBgUSA2MECgoOCgcEAAMBAgYBEgNjCyEKDgoHBAADAQIGAxID
YyQlCg4KBwQAAwECBggSA2MmTgoRCgoEAAMBAgYInAgAEgNjJ00KdAoEBAADAhIEaAJrAxpm
IFRoZSBhZ2VudCB3aGljaCB3aWxsIHRyYW5zZmVyIGV4ZWN1dGlvbiB0byBhIHJlbW90ZQog
W0EyQV0oaHR0cHM6Ly9naXRodWIuY29tL2EyYXByb2plY3QvQTJBKSBhZ2VudC4KCgwKBQQA
AwIBEgNoChgKPAoGBAADAgIAEgNqBEwaLSBSZXF1aXJlZC4gVGhlIEEyQSBjb25uZWN0aW9u
IGNvbmZpZ3VyYXRpb24uCgoOCgcEAAMCAgAGEgNqBBMKDgoHBAADAgIAARIDahQeCg4KBwQA
AwICAAMSA2ohIgoOCgcEAAMCAgAIEgNqI0sKEQoKBAADAgIACJwIABIDaiRKCjgKBAQAAwMS
BG4CeQMaKiBBIHRvb2xzZXQgd2l0aCBhIHNlbGVjdGlvbiBvZiBpdHMgdG9vbHMuCgoMCgUE
AAMDARIDbgoWCo8BCgYEAAMDAgASBHIEdQYafyBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIHRvb2xzZXQuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdG9vbHNldHMve3Rvb2xzZXR9YAoKDgoHBAAD
AwIABRIDcgQKCg4KBwQAAwMCAAESA3ILEgoOCgcEAAMDAgADEgNyFRYKDwoHBAADAwIACBIE
chd1BQoRCgoEAAMDAgAInAgAEgNzBiwKEAoJBAADAwIACJ8IEgN0Bk4KPwoGBAADAwIBEgN4
BEoaMCBPcHRpb25hbC4gVGhlIHRvb2xzIElEcyB0byBmaWx0ZXIgdGhlIHRvb2xzZXQuCgoO
CgcEAAMDAgEEEgN4BAwKDgoHBAADAwIBBRIDeA0TCg4KBwQAAwMCAQESA3gUHAoOCgcEAAMD
AgEDEgN4HyAKDgoHBAADAwIBCBIDeCFJChEKCgQAAwMCAQicCAASA3giSAojCgQEAAgAEgV8
Ao8BAxoUIFRoZSB0eXBlIG9mIGFnZW50LgoKDAoFBAAIAAESA3wIEgowCgQEAAIAEgN+BEUa
IyBPcHRpb25hbC4gVGhlIGRlZmF1bHQgYWdlbnQgdHlwZS4KCgwKBQQAAgAGEgN+BAwKDAoF
BAACAAESA34NFgoMCgUEAAIAAxIDfhkbCgwKBQQAAgAIEgN+HEQKDwoIBAACAAicCAASA34d
QwrJAwoEBAACARIGiAEEiQExGrgDIE9wdGlvbmFsLiBUaGUgcmVtb3RlCiBbRGlhbG9nZmxv
d10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2RpYWxvZ2Zsb3cvY3gvZG9jcy9jb25jZXB0
L2NvbnNvbGUtY29udmVyc2F0aW9uYWwtYWdlbnRzKQogYWdlbnQgdG8gYmUgdXNlZCBmb3Ig
dGhlIGFnZW50IGV4ZWN1dGlvbi4gSWYgdGhpcyBmaWVsZCBpcyBzZXQsIGFsbCBvdGhlcgog
YWdlbnQgbGV2ZWwgcHJvcGVydGllcyB3aWxsIGJlIGlnbm9yZWQuCgogTm90ZTogSWYgdGhl
IERpYWxvZ2Zsb3cgYWdlbnQgaXMgaW4gYSBkaWZmZXJlbnQgcHJvamVjdCBmcm9tIHRoZSBh
cHAsIHlvdQogc2hvdWxkIGdyYW50IGByb2xlcy9kaWFsb2dmbG93LmNsaWVudGAgdG8gdGhl
IENFUyBzZXJ2aWNlIGFnZW50CiBgc2VydmljZS08UFJPSkVDVC1OVU1CRVI+QGdjcC1zYS1j
ZXMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb21gLgoKDQoFBAACAQYSBIgBBBkKDQoFBAACAQES
BIgBGjEKDQoFBAACAQMSBIgBNDYKDQoFBAACAQgSBIkBCDAKEAoIBAACAQicCAASBIkBCS8K
egoEBAACAhIGjQEEjgExGmogT3B0aW9uYWwuIFRoZSByZW1vdGUgW0EyQV0oaHR0cHM6Ly9n
aXRodWIuY29tL2EyYXByb2plY3QvQTJBKSBhZ2VudCB0byBiZQogdXNlZCBmb3IgdGhlIGFn
ZW50IGV4ZWN1dGlvbi4KCg0KBQQAAgIGEgSNAQQSCg0KBQQAAgIBEgSNARMjCg0KBQQAAgID
EgSNASYoCg0KBQQAAgIIEgSOAQgwChAKCAQAAgIInAgAEgSOAQkvCowBCgQEAAIDEgSTAQI9
Gn4gSWRlbnRpZmllci4gVGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBhZ2VudC4KIEZv
cm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3th
cHB9L2FnZW50cy97YWdlbnR9YAoKDQoFBAACAwUSBJMBAggKDQoFBAACAwESBJMBCQ0KDQoF
BAACAwMSBJMBEBEKDQoFBAACAwgSBJMBEjwKEAoIBAACAwicCAASBJMBEzsKNAoEBAACBBIE
lgECQxomIFJlcXVpcmVkLiBEaXNwbGF5IG5hbWUgb2YgdGhlIGFnZW50LgoKDQoFBAACBAUS
BJYBAggKDQoFBAACBAESBJYBCRUKDQoFBAACBAMSBJYBGBkKDQoFBAACBAgSBJYBGkIKEAoI
BAACBAicCAASBJYBG0EKQgoEBAACBRIEmQECQho0IE9wdGlvbmFsLiBIdW1hbi1yZWFkYWJs
ZSBkZXNjcmlwdGlvbiBvZiB0aGUgYWdlbnQuCgoNCgUEAAIFBRIEmQECCAoNCgUEAAIFARIE
mQEJFAoNCgUEAAIFAxIEmQEXGAoNCgUEAAIFCBIEmQEZQQoQCggEAAIFCJwIABIEmQEaQAo7
CgQEAAIGEgScAQJMGi0gT3B0aW9uYWwuIENvbmZpZ3VyYXRpb25zIGZvciB0aGUgTExNIG1v
ZGVsLgoKDQoFBAACBgYSBJwBAg8KDQoFBAACBgESBJwBEB4KDQoFBAACBgMSBJwBISIKDQoF
BAACBggSBJwBI0sKEAoIBAACBgicCAASBJwBJEoKVwoEBAACBxIEnwECQhpJIE9wdGlvbmFs
LiBJbnN0cnVjdGlvbnMgZm9yIHRoZSBMTE0gbW9kZWwgdG8gZ3VpZGUgdGhlIGFnZW50J3Mg
YmVoYXZpb3IuCgoNCgUEAAIHBRIEnwECCAoNCgUEAAIHARIEnwEJFAoNCgUEAAIHAxIEnwEX
GAoNCgUEAAIHCBIEnwEZQQoQCggEAAIHCJwIABIEnwEaQAqNAQoEBAACCBIGowECpgEEGn0g
T3B0aW9uYWwuIExpc3Qgb2YgYXZhaWxhYmxlIHRvb2xzIGZvciB0aGUgYWdlbnQuCiBGb3Jt
YXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBw
fS90b29scy97dG9vbH1gCgoNCgUEAAIIBBIEowECCgoNCgUEAAIIBRIEowELEQoNCgUEAAII
ARIEowESFwoNCgUEAAIIAxIEowEaGwoPCgUEAAIICBIGowEcpgEDChAKCAQAAggInAgAEgSk
AQQqCg8KBwQAAggInwgSBKUBBEkKkQEKBAQAAgkSBqoBAq0BBBqAASBPcHRpb25hbC4gTGlz
dCBvZiBjaGlsZCBhZ2VudHMgaW4gdGhlIGFnZW50IHRyZWUuCiBGb3JtYXQ6IGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9hZ2VudHMve2Fn
ZW50fWAKCg0KBQQAAgkEEgSqAQIKCg0KBQQAAgkFEgSqAQsRCg0KBQQAAgkBEgSqARIeCg0K
BQQAAgkDEgSqASEiCg8KBQQAAgkIEgaqASOtAQMKEAoIBAACCQicCAASBKsBBCoKDwoHBAAC
CQifCBIErAEESgqbAgoEBAACChIGswECtAEvGooCIE9wdGlvbmFsLiBUaGUgY2FsbGJhY2tz
IHRvIGV4ZWN1dGUgYmVmb3JlIHRoZSBhZ2VudCBpcyBjYWxsZWQuCiBUaGUgcHJvdmlkZWQg
Y2FsbGJhY2tzIGFyZSBleGVjdXRlZCBzZXF1ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVy
IHRoZXkKIGFyZSBnaXZlbiBpbiB0aGUgbGlzdC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFu
IG92ZXJyaWRkZW4gcmVzcG9uc2UsCiBleGVjdXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5p
bmcgY2FsbGJhY2tzIGFyZSBza2lwcGVkLgoKDQoFBAACCgQSBLMBAgoKDQoFBAACCgYSBLMB
CxMKDQoFBAACCgESBLMBFCoKDQoFBAACCgMSBLMBLS8KDQoFBAACCggSBLQBBi4KEAoIBAAC
CgicCAASBLQBBy0KmgIKBAQAAgsSBroBArsBLxqJAiBPcHRpb25hbC4gVGhlIGNhbGxiYWNr
cyB0byBleGVjdXRlIGFmdGVyIHRoZSBhZ2VudCBpcyBjYWxsZWQuCiBUaGUgcHJvdmlkZWQg
Y2FsbGJhY2tzIGFyZSBleGVjdXRlZCBzZXF1ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVy
IHRoZXkKIGFyZSBnaXZlbiBpbiB0aGUgbGlzdC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFu
IG92ZXJyaWRkZW4gcmVzcG9uc2UsCiBleGVjdXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5p
bmcgY2FsbGJhY2tzIGFyZSBza2lwcGVkLgoKDQoFBAACCwQSBLoBAgoKDQoFBAACCwYSBLoB
CxMKDQoFBAACCwESBLoBFCkKDQoFBAACCwMSBLoBLC4KDQoFBAACCwgSBLsBBi4KEAoIBAAC
CwicCAASBLsBBy0K9AIKBAQAAgwSBsIBAsMBLxrjAiBPcHRpb25hbC4gVGhlIGNhbGxiYWNr
cyB0byBleGVjdXRlIGJlZm9yZSB0aGUgbW9kZWwgaXMgY2FsbGVkLiBJZiB0aGVyZSBhcmUK
IG11bHRpcGxlIGNhbGxzIHRvIHRoZSBtb2RlbCwgdGhlIGNhbGxiYWNrIHdpbGwgYmUgZXhl
Y3V0ZWQgbXVsdGlwbGUgdGltZXMuCiBUaGUgcHJvdmlkZWQgY2FsbGJhY2tzIGFyZSBleGVj
dXRlZCBzZXF1ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVyIHRoZXkKIGFyZSBnaXZlbiBp
biB0aGUgbGlzdC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFuIG92ZXJyaWRkZW4gcmVzcG9u
c2UsCiBleGVjdXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5pbmcgY2FsbGJhY2tzIGFyZSBz
a2lwcGVkLgoKDQoFBAACDAQSBMIBAgoKDQoFBAACDAYSBMIBCxMKDQoFBAACDAESBMIBFCoK
DQoFBAACDAMSBMIBLS8KDQoFBAACDAgSBMMBBi4KEAoIBAACDAicCAASBMMBBy0K8wIKBAQA
Ag0SBsoBAssBLxriAiBPcHRpb25hbC4gVGhlIGNhbGxiYWNrcyB0byBleGVjdXRlIGFmdGVy
IHRoZSBtb2RlbCBpcyBjYWxsZWQuIElmIHRoZXJlIGFyZQogbXVsdGlwbGUgY2FsbHMgdG8g
dGhlIG1vZGVsLCB0aGUgY2FsbGJhY2sgd2lsbCBiZSBleGVjdXRlZCBtdWx0aXBsZSB0aW1l
cy4KIFRoZSBwcm92aWRlZCBjYWxsYmFja3MgYXJlIGV4ZWN1dGVkIHNlcXVlbnRpYWxseSBp
biB0aGUgZXhhY3Qgb3JkZXIgdGhleQogYXJlIGdpdmVuIGluIHRoZSBsaXN0LiBJZiBhIGNh
bGxiYWNrIHJldHVybnMgYW4gb3ZlcnJpZGRlbiByZXNwb25zZSwKIGV4ZWN1dGlvbiBzdG9w
cyBhbmQgYW55IHJlbWFpbmluZyBjYWxsYmFja3MgYXJlIHNraXBwZWQuCgoNCgUEAAINBBIE
ygECCgoNCgUEAAINBhIEygELEwoNCgUEAAINARIEygEUKQoNCgUEAAINAxIEygEsLgoNCgUE
AAINCBIEywEGLgoQCggEAAINCJwIABIEywEHLQryAgoEBAACDhIG0gEC0wEvGuECIE9wdGlv
bmFsLiBUaGUgY2FsbGJhY2tzIHRvIGV4ZWN1dGUgYmVmb3JlIHRoZSB0b29sIGlzIGludm9r
ZWQuIElmIHRoZXJlIGFyZQogbXVsdGlwbGUgdG9vbCBpbnZvY2F0aW9ucywgdGhlIGNhbGxi
YWNrIHdpbGwgYmUgZXhlY3V0ZWQgbXVsdGlwbGUgdGltZXMuCiBUaGUgcHJvdmlkZWQgY2Fs
bGJhY2tzIGFyZSBleGVjdXRlZCBzZXF1ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVyIHRo
ZXkKIGFyZSBnaXZlbiBpbiB0aGUgbGlzdC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFuIG92
ZXJyaWRkZW4gcmVzcG9uc2UsCiBleGVjdXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5pbmcg
Y2FsbGJhY2tzIGFyZSBza2lwcGVkLgoKDQoFBAACDgQSBNIBAgoKDQoFBAACDgYSBNIBCxMK
DQoFBAACDgESBNIBFCkKDQoFBAACDgMSBNIBLC4KDQoFBAACDggSBNMBBi4KEAoIBAACDgic
CAASBNMBBy0K8QIKBAQAAg8SBtoBAtsBLxrgAiBPcHRpb25hbC4gVGhlIGNhbGxiYWNrcyB0
byBleGVjdXRlIGFmdGVyIHRoZSB0b29sIGlzIGludm9rZWQuIElmIHRoZXJlIGFyZQogbXVs
dGlwbGUgdG9vbCBpbnZvY2F0aW9ucywgdGhlIGNhbGxiYWNrIHdpbGwgYmUgZXhlY3V0ZWQg
bXVsdGlwbGUgdGltZXMuCiBUaGUgcHJvdmlkZWQgY2FsbGJhY2tzIGFyZSBleGVjdXRlZCBz
ZXF1ZW50aWFsbHkgaW4gdGhlIGV4YWN0IG9yZGVyIHRoZXkKIGFyZSBnaXZlbiBpbiB0aGUg
bGlzdC4gSWYgYSBjYWxsYmFjayByZXR1cm5zIGFuIG92ZXJyaWRkZW4gcmVzcG9uc2UsCiBl
eGVjdXRpb24gc3RvcHMgYW5kIGFueSByZW1haW5pbmcgY2FsbGJhY2tzIGFyZSBza2lwcGVk
LgoKDQoFBAACDwQSBNoBAgoKDQoFBAACDwYSBNoBCxMKDQoFBAACDwESBNoBFCgKDQoFBAAC
DwMSBNoBKy0KDQoFBAACDwgSBNsBBi4KEAoIBAACDwicCAASBNsBBy0KRAoEBAACEBIG3gEC
3wEyGjQgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoZSBhZ2VudCB3YXMgY3JlYXRl
ZC4KCg0KBQQAAhAGEgTeAQIbCg0KBQQAAhABEgTeARwnCg0KBQQAAhADEgTeASosCg0KBQQA
AhAIEgTfAQYxChAKCAQAAhAInAgAEgTfAQcwCkkKBAQAAhESBuIBAuMBMho5IE91dHB1dCBv
bmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgYWdlbnQgd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQA
AhEGEgTiAQIbCg0KBQQAAhEBEgTiARwnCg0KBQQAAhEDEgTiASosCg0KBQQAAhEIEgTjAQYx
ChAKCAQAAhEInAgAEgTjAQcwCpQBCgQEAAISEgboAQLrAQQagwEgT3B0aW9uYWwuIExpc3Qg
b2YgZ3VhcmRyYWlscyBmb3IgdGhlIGFnZW50LgogRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2d1YXJkcmFpbHMve2d1YXJk
cmFpbH1gCgoNCgUEAAISBBIE6AECCgoNCgUEAAISBRIE6AELEQoNCgUEAAISARIE6AESHAoN
CgUEAAISAxIE6AEfIQoPCgUEAAISCBIG6AEi6wEDChAKCAQAAhIInAgAEgTpAQQqCg8KBwQA
AhIInwgSBOoBBE4KrgEKBAQAAhMSBPABAhManwEgRXRhZyB1c2VkIHRvIGVuc3VyZSB0aGUg
b2JqZWN0IGhhc24ndCBjaGFuZ2VkIGR1cmluZyBhIHJlYWQtbW9kaWZ5LXdyaXRlCiBvcGVy
YXRpb24uIElmIHRoZSBldGFnIGlzIGVtcHR5LCB0aGUgdXBkYXRlIHdpbGwgb3ZlcndyaXRl
IGFueSBjb25jdXJyZW50CiBjaGFuZ2VzLgoKDQoFBAACEwUSBPABAggKDQoFBAACEwESBPAB
CQ0KDQoFBAACEwMSBPABEBIKOQoEBAACFBIE8wECTxorIE9wdGlvbmFsLiBMaXN0IG9mIHRv
b2xzZXRzIGZvciB0aGUgYWdlbnQuCgoNCgUEAAIUBBIE8wECCgoNCgUEAAIUBhIE8wELFwoN
CgUEAAIUARIE8wEYIAoNCgUEAAIUAxIE8wEjJQoNCgUEAAIUCBIE8wEmTgoQCggEAAIUCJwI
ABIE8wEnTQqKAQoEBAACFRIE9wECTBp8IE91dHB1dCBvbmx5LiBJZiB0aGUgYWdlbnQgaXMg
Z2VuZXJhdGVkIGJ5IHRoZSBMTE0gYXNzaXN0YW50LCB0aGlzIGZpZWxkCiBjb250YWlucyBh
IGRlc2NyaXB0aXZlIHN1bW1hcnkgb2YgdGhlIGdlbmVyYXRpb24uCgoNCgUEAAIVBRIE9wEC
CAoNCgUEAAIVARIE9wEJGgoNCgUEAAIVAxIE9wEdHwoNCgUEAAIVCBIE9wEgSwoQCggEAAIV
CJwIABIE9wEhSgpzCgQEAAIWEgb7AQL8AS8aYyBPcHRpb25hbC4gQWdlbnQgdHJhbnNmZXIg
cnVsZXMuCiBJZiBtdWx0aXBsZSBydWxlcyBtYXRjaCwgdGhlIGZpcnN0IG9uZSBpbiB0aGUg
bGlzdCB3aWxsIGJlIHVzZWQuCgoNCgUEAAIWBBIE+wECCgoNCgUEAAIWBhIE+wELFwoNCgUE
AAIWARIE+wEYJgoNCgUEAAIWAxIE+wEpKwoNCgUEAAIWCBIE/AEGLgoQCggEAAIWCJwIABIE
/AEHLQpnCgQEAAIXEgaAAgKBAjIaVyBPdXRwdXQgb25seS4gTWlzY29uZmlndXJhdGlvbnMg
b3IgZXJyb3JzIGluIHRoZSBhZ2VudCB0aGF0IG1heSBhZmZlY3QgYWdlbnQKIHF1YWxpdHku
CgoNCgUEAAIXBBIEgAICCgoNCgUEAAIXBRIEgAILEQoNCgUEAAIXARIEgAISIwoNCgUEAAIX
AxIEgAImKAoNCgUEAAIXCBIEgQIGMQoQCggEAAIXCJwIABIEgQIHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Agent::Agent ===
    # Fields for Agent
    # Field: llm_agent Type: 11 (.google.cloud.ces.v1beta.Agent.LlmAgent)
    # Field: remote_dialogflow_agent Type: 11 (.google.cloud.ces.v1beta.Agent.RemoteDialogflowAgent)
    # Field: remote_a2a_agent Type: 11 (.google.cloud.ces.v1beta.Agent.RemoteA2aAgent)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: model_settings Type: 11 (.google.cloud.ces.v1beta.ModelSettings)
    # Field: instruction Type: 9 ()
    # Field: tools Type: 9 ()
    # Field: child_agents Type: 9 ()
    # Field: before_agent_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: after_agent_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: before_model_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: after_model_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: before_tool_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: after_tool_callbacks Type: 11 (.google.cloud.ces.v1beta.Callback)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: guardrails Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: toolsets Type: 11 (.google.cloud.ces.v1beta.Agent.AgentToolset)
    # Field: generated_summary Type: 9 ()
    # Field: transfer_rules Type: 11 (.google.cloud.ces.v1beta.TransferRule)
    # Field: validation_errors Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Agent - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/agent.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Agent;

    my $msg = Google::Cloud::Ces::V1beta::Agent::Agent->new({
        llm_agent => $llm_agent,
        remote_dialogflow_agent => $remote_dialogflow_agent,
        remote_a2a_agent => $remote_a2a_agent,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->llm_agent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Agent::Agent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/agent.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Agent::Agent

An agent acts as the fundamental building block that provides instructions to
the Large Language Model (LLM) for executing specific tasks.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->llm_agent() >> / C<< $msg->llm_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Agent::Agent::LlmAgent>)

Optional. The default agent type.

=item * C<< $msg->remote_dialogflow_agent() >> / C<< $msg->remote_dialogflow_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Agent::Agent::RemoteDialogflowAgent>)

Optional. The remote
[Dialogflow](https://cloud.google.com/dialogflow/cx/docs/concept/console-conversational-agents)
agent to be used for the agent execution. If this field is set, all other
agent level properties will be ignored.

Note: If the Dialogflow agent is in a different project from the app, you
should grant `roles/dialogflow.client` to the CES service agent
`service-<PROJECT-NUMBER>@gcp-sa-ces.iam.gserviceaccount.com`.

=item * C<< $msg->remote_a2a_agent() >> / C<< $msg->remote_a2a_agent($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Agent::Agent::RemoteA2aAgent>)

Optional. The remote [A2A](https://github.com/a2aproject/A2A) agent to be
used for the agent execution.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the agent.
Format: `projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the agent.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Human-readable description of the agent.

=item * C<< $msg->model_settings() >> / C<< $msg->model_settings($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ModelSettings>)

Optional. Configurations for the LLM model.

=item * C<< $msg->instruction() >> / C<< $msg->instruction($value) >>

Type: C<String>

Optional. Instructions for the LLM model to guide the agent's behavior.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<String>

Optional. List of available tools for the agent.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->child_agents() >> / C<< $msg->child_agents($value) >>

Type: C<String>

Optional. List of child agents in the agent tree.
Format: `projects/{project}/locations/{location}/apps/{app}/agents/{agent}`

=item * C<< $msg->before_agent_callbacks() >> / C<< $msg->before_agent_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute before the agent is called.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_agent_callbacks() >> / C<< $msg->after_agent_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute after the agent is called.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->before_model_callbacks() >> / C<< $msg->before_model_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute before the model is called. If there are
multiple calls to the model, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_model_callbacks() >> / C<< $msg->after_model_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute after the model is called. If there are
multiple calls to the model, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->before_tool_callbacks() >> / C<< $msg->before_tool_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute before the tool is invoked. If there are
multiple tool invocations, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->after_tool_callbacks() >> / C<< $msg->after_tool_callbacks($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::Callback>)

Optional. The callbacks to execute after the tool is invoked. If there are
multiple tool invocations, the callback will be executed multiple times.
The provided callbacks are executed sequentially in the exact order they
are given in the list. If a callback returns an overridden response,
execution stops and any remaining callbacks are skipped.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the agent was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the agent was last updated.

=item * C<< $msg->guardrails() >> / C<< $msg->guardrails($value) >>

Type: C<String>

Optional. List of guardrails for the agent.
Format:
`projects/{project}/locations/{location}/apps/{app}/guardrails/{guardrail}`

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Etag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=item * C<< $msg->toolsets() >> / C<< $msg->toolsets($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Agent::Agent::AgentToolset>)

Optional. List of toolsets for the agent.

=item * C<< $msg->generated_summary() >> / C<< $msg->generated_summary($value) >>

Type: C<String>

Output only. If the agent is generated by the LLM assistant, this field
contains a descriptive summary of the generation.

=item * C<< $msg->transfer_rules() >> / C<< $msg->transfer_rules($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AgentTransfers::TransferRule>)

Optional. Agent transfer rules.
If multiple rules match, the first one in the list will be used.

=item * C<< $msg->validation_errors() >> / C<< $msg->validation_errors($value) >>

Type: C<String>

Output only. Misconfigurations or errors in the agent that may affect agent
quality.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Agent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
