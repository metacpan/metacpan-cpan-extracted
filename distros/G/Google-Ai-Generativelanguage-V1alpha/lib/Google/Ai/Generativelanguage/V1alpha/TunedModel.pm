package Google::Ai::Generativelanguage::V1alpha::TunedModel;

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
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxYWxwaGEvdHVuZWRfbW9kZWwucHJv
dG8SJGdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLoBwoKVHVuZWRNb2RlbBJrChJ0dW5lZF9tb2Rl
bF9zb3VyY2UYAyABKAsyNi5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEu
VHVuZWRNb2RlbFNvdXJjZUID4EEBSABSEHR1bmVkTW9kZWxTb3VyY2USUAoKYmFzZV9tb2Rl
bBgEIAEoCUIv4EEF+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29vZ2xlYXBpcy5jb20vTW9k
ZWxIAFIJYmFzZU1vZGVsEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRImCgxkaXNwbGF5X25h
bWUYBSABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YBiABKAlCA+BBAVIL
ZGVzY3JpcHRpb24SKgoLdGVtcGVyYXR1cmUYCyABKAJCA+BBAUgBUgt0ZW1wZXJhdHVyZYgB
ARIdCgV0b3BfcBgMIAEoAkID4EEBSAJSBHRvcFCIAQESHQoFdG9wX2sYDSABKAVCA+BBAUgD
UgR0b3BLiAEBElEKBXN0YXRlGAcgASgOMjYuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MWFscGhhLlR1bmVkTW9kZWwuU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUY
CCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSVgoLdHVuaW5nX3Rhc2sYCiABKAsyMC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxh
bmd1YWdlLnYxYWxwaGEuVHVuaW5nVGFza0ID4EECUgp0dW5pbmdUYXNrEjkKFnJlYWRlcl9w
cm9qZWN0X251bWJlcnMYDiADKANCA+BBAVIUcmVhZGVyUHJvamVjdE51bWJlcnMiRAoFU3Rh
dGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIMCghDUkVBVElORxABEgoKBkFDVElWRRACEgoK
BkZBSUxFRBADOmXqQWIKLGdlbmVyYXRpdmVsYW5ndWFnZS5nb29nbGVhcGlzLmNvbS9UdW5l
ZE1vZGVsEhl0dW5lZE1vZGVscy97dHVuZWRfbW9kZWx9Kgt0dW5lZE1vZGVsczIKdHVuZWRN
b2RlbEIOCgxzb3VyY2VfbW9kZWxCDgoMX3RlbXBlcmF0dXJlQggKBl90b3BfcEIICgZfdG9w
X2siuQEKEFR1bmVkTW9kZWxTb3VyY2USVQoLdHVuZWRfbW9kZWwYASABKAlCNOBBBfpBLgos
Z2VuZXJhdGl2ZWxhbmd1YWdlLmdvb2dsZWFwaXMuY29tL1R1bmVkTW9kZWxSCnR1bmVkTW9k
ZWwSTgoKYmFzZV9tb2RlbBgCIAEoCUIv4EED+kEpCidnZW5lcmF0aXZlbGFuZ3VhZ2UuZ29v
Z2xlYXBpcy5jb20vTW9kZWxSCWJhc2VNb2RlbCKwAwoKVHVuaW5nVGFzaxI+CgpzdGFydF90
aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglzdGFydFRpbWUS
RAoNY29tcGxldGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IMY29tcGxldGVUaW1lElcKCXNuYXBzaG90cxgDIAMoCzI0Lmdvb2dsZS5haS5nZW5lcmF0
aXZlbGFuZ3VhZ2UudjFhbHBoYS5UdW5pbmdTbmFwc2hvdEID4EEDUglzbmFwc2hvdHMSXQoN
dHJhaW5pbmdfZGF0YRgEIAEoCzItLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFh
bHBoYS5EYXRhc2V0QgngQQTgQQLgQQVSDHRyYWluaW5nRGF0YRJkCg9oeXBlcnBhcmFtZXRl
cnMYBSABKAsyNS5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuSHlwZXJw
YXJhbWV0ZXJzQgPgQQVSD2h5cGVycGFyYW1ldGVycyKPAgoPSHlwZXJwYXJhbWV0ZXJzEi0K
DWxlYXJuaW5nX3JhdGUYECABKAJCBuBBBeBBAUgAUgxsZWFybmluZ1JhdGUSQgoYbGVhcm5p
bmdfcmF0ZV9tdWx0aXBsaWVyGBEgASgCQgbgQQXgQQFIAFIWbGVhcm5pbmdSYXRlTXVsdGlw
bGllchIpCgtlcG9jaF9jb3VudBgOIAEoBUID4EEFSAFSCmVwb2NoQ291bnSIAQESJwoKYmF0
Y2hfc2l6ZRgPIAEoBUID4EEFSAJSCWJhdGNoU2l6ZYgBAUIWChRsZWFybmluZ19yYXRlX29w
dGlvbkIOCgxfZXBvY2hfY291bnRCDQoLX2JhdGNoX3NpemUibQoHRGF0YXNldBJXCghleGFt
cGxlcxgBIAEoCzI0Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5UdW5p
bmdFeGFtcGxlc0ID4EEBSABSCGV4YW1wbGVzQgkKB2RhdGFzZXQizgEKDlR1bmluZ0V4YW1w
bGVzEk8KCGV4YW1wbGVzGAEgAygLMjMuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52
MWFscGhhLlR1bmluZ0V4YW1wbGVSCGV4YW1wbGVzEmsKEm11bHRpdHVybl9leGFtcGxlcxgC
IAMoCzI8Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFhbHBoYS5UdW5pbmdNdWx0
aXR1cm5FeGFtcGxlUhFtdWx0aXR1cm5FeGFtcGxlcyIqCgpUdW5pbmdQYXJ0EhQKBHRleHQY
AiABKAlIAFIEdGV4dEIGCgRkYXRhInAKDVR1bmluZ0NvbnRlbnQSRgoFcGFydHMYASADKAsy
MC5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxYWxwaGEuVHVuaW5nUGFydFIFcGFy
dHMSFwoEcm9sZRgCIAEoCUID4EEBUgRyb2xlIu4BChZUdW5pbmdNdWx0aXR1cm5FeGFtcGxl
EmwKEnN5c3RlbV9pbnN0cnVjdGlvbhgIIAEoCzIzLmdvb2dsZS5haS5nZW5lcmF0aXZlbGFu
Z3VhZ2UudjFhbHBoYS5UdW5pbmdDb250ZW50QgPgQQFIAFIRc3lzdGVtSW5zdHJ1Y3Rpb26I
AQESTwoIY29udGVudHMYASADKAsyMy5nb29nbGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYx
YWxwaGEuVHVuaW5nQ29udGVudFIIY29udGVudHNCFQoTX3N5c3RlbV9pbnN0cnVjdGlvbiJh
Cg1UdW5pbmdFeGFtcGxlEiQKCnRleHRfaW5wdXQYASABKAlCA+BBAUgAUgl0ZXh0SW5wdXQS
GwoGb3V0cHV0GAMgASgJQgPgQQJSBm91dHB1dEINCgttb2RlbF9pbnB1dCKqAQoOVHVuaW5n
U25hcHNob3QSFwoEc3RlcBgBIAEoBUID4EEDUgRzdGVwEhkKBWVwb2NoGAIgASgFQgPgQQNS
BWVwb2NoEiAKCW1lYW5fbG9zcxgDIAEoAkID4EEDUghtZWFuTG9zcxJCCgxjb21wdXRlX3Rp
bWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSC2NvbXB1dGVUaW1l
Qp0BCihjb20uZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MWFscGhhQg9UdW5lZE1v
ZGVsUHJvdG9QAVpeY2xvdWQuZ29vZ2xlLmNvbS9nby9haS9nZW5lcmF0aXZlbGFuZ3VhZ2Uv
YXBpdjFhbHBoYS9nZW5lcmF0aXZlbGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkq3
VAoHEgUOALMCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
LQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAHUKCQoCCAsSAxYA
dQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoCCAgSAxgAMAoICgEIEgMZAEEK
CQoCCAESAxkAQQpOCgIEABIFHACFAQEaQSBBIGZpbmUtdHVuZWQgbW9kZWwgY3JlYXRlZCB1
c2luZyBNb2RlbFNlcnZpY2UuQ3JlYXRlVHVuZWRNb2RlbC4KCgoKAwQAARIDHAgSCgsKAwQA
BxIEHQIiBAoNCgUEAAedCBIEHQIiBAotCgQEAAQAEgQlAjEDGh8gVGhlIHN0YXRlIG9mIHRo
ZSB0dW5lZCBtb2RlbC4KCgwKBQQABAABEgMlBwwKOQoGBAAEAAIAEgMnBBoaKiBUaGUgZGVm
YXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQAAgABEgMnBBUKDgoH
BAAEAAIAAhIDJxgZCiwKBgQABAACARIDKgQRGh0gVGhlIG1vZGVsIGlzIGJlaW5nIGNyZWF0
ZWQuCgoOCgcEAAQAAgEBEgMqBAwKDgoHBAAEAAIBAhIDKg8QCi8KBgQABAACAhIDLQQPGiAg
VGhlIG1vZGVsIGlzIHJlYWR5IHRvIGJlIHVzZWQuCgoOCgcEAAQAAgIBEgMtBAoKDgoHBAAE
AAICAhIDLQ0OCjAKBgQABAACAxIDMAQPGiEgVGhlIG1vZGVsIGZhaWxlZCB0byBiZSBjcmVh
dGVkLgoKDgoHBAAEAAIDARIDMAQKCg4KBwQABAACAwISAzANDgpACgQEAAgAEgQ0AkIDGjIg
VGhlIG1vZGVsIHVzZWQgYXMgdGhlIHN0YXJ0aW5nIHBvaW50IGZvciB0dW5pbmcuCgoMCgUE
AAgAARIDNAgUCl4KBAQAAgASBDcEODEaUCBPcHRpb25hbC4gVHVuZWRNb2RlbCB0byB1c2Ug
YXMgdGhlIHN0YXJ0aW5nIHBvaW50IGZvciB0cmFpbmluZyB0aGUgbmV3CiBtb2RlbC4KCgwK
BQQAAgAGEgM3BBQKDAoFBAACAAESAzcVJwoMCgUEAAIAAxIDNyorCgwKBQQAAgAIEgM4CDAK
DwoIBAACAAicCAASAzgJLwpjCgQEAAIBEgQ8BEEGGlUgSW1tdXRhYmxlLiBUaGUgbmFtZSBv
ZiB0aGUgYE1vZGVsYCB0byB0dW5lLgogRXhhbXBsZTogYG1vZGVscy9nZW1pbmktMS41LWZs
YXNoLTAwMWAKCgwKBQQAAgEFEgM8BAoKDAoFBAACAQESAzwLFQoMCgUEAAIBAxIDPBgZCg0K
BQQAAgEIEgQ8GkEFCg8KCAQAAgEInAgAEgM9Bi0KDwoHBAACAQifCBIEPgZABwqdAwoEBAAC
AhIDTgI+Go8DIE91dHB1dCBvbmx5LiBUaGUgdHVuZWQgbW9kZWwgbmFtZS4gQSB1bmlxdWUg
bmFtZSB3aWxsIGJlIGdlbmVyYXRlZCBvbgogY3JlYXRlLiBFeGFtcGxlOiBgdHVuZWRNb2Rl
bHMvYXoybWIwYnB3NmlgIElmIGRpc3BsYXlfbmFtZSBpcyBzZXQgb24KIGNyZWF0ZSwgdGhl
IGlkIHBvcnRpb24gb2YgdGhlIG5hbWUgd2lsbCBiZSBzZXQgYnkgY29uY2F0ZW5hdGluZyB0
aGUgd29yZHMKIG9mIHRoZSBkaXNwbGF5X25hbWUgd2l0aCBoeXBoZW5zIGFuZCBhZGRpbmcg
YSByYW5kb20gcG9ydGlvbiBmb3IKIHVuaXF1ZW5lc3MuCgogRXhhbXBsZToKCiAgKiBkaXNw
bGF5X25hbWUgPSBgU2VudGVuY2UgVHJhbnNsYXRvcmAKICAqIG5hbWUgPSBgdHVuZWRNb2Rl
bHMvc2VudGVuY2UtdHJhbnNsYXRvci11M2I3bWAKCgwKBQQAAgIFEgNOAggKDAoFBAACAgES
A04JDQoMCgUEAAICAxIDThARCgwKBQQAAgIIEgNOEj0KDwoIBAACAgicCAASA04TPAqQAQoE
BAACAxIDUgJDGoIBIE9wdGlvbmFsLiBUaGUgbmFtZSB0byBkaXNwbGF5IGZvciB0aGlzIG1v
ZGVsIGluIHVzZXIgaW50ZXJmYWNlcy4KIFRoZSBkaXNwbGF5IG5hbWUgbXVzdCBiZSB1cCB0
byA0MCBjaGFyYWN0ZXJzIGluY2x1ZGluZyBzcGFjZXMuCgoMCgUEAAIDBRIDUgIICgwKBQQA
AgMBEgNSCRUKDAoFBAACAwMSA1IYGQoMCgUEAAIDCBIDUhpCCg8KCAQAAgMInAgAEgNSG0EK
OwoEBAACBBIDVQJCGi4gT3B0aW9uYWwuIEEgc2hvcnQgZGVzY3JpcHRpb24gb2YgdGhpcyBt
b2RlbC4KCgwKBQQAAgQFEgNVAggKDAoFBAACBAESA1UJFAoMCgUEAAIEAxIDVRcYCgwKBQQA
AgQIEgNVGUEKDwoIBAACBAicCAASA1UaQAr3AgoEBAACBRIDXwJLGukCIE9wdGlvbmFsLiBD
b250cm9scyB0aGUgcmFuZG9tbmVzcyBvZiB0aGUgb3V0cHV0LgoKIFZhbHVlcyBjYW4gcmFu
Z2Ugb3ZlciBgWzAuMCwxLjBdYCwgaW5jbHVzaXZlLiBBIHZhbHVlIGNsb3NlciB0byBgMS4w
YCB3aWxsCiBwcm9kdWNlIHJlc3BvbnNlcyB0aGF0IGFyZSBtb3JlIHZhcmllZCwgd2hpbGUg
YSB2YWx1ZSBjbG9zZXIgdG8gYDAuMGAgd2lsbAogdHlwaWNhbGx5IHJlc3VsdCBpbiBsZXNz
IHN1cnByaXNpbmcgcmVzcG9uc2VzIGZyb20gdGhlIG1vZGVsLgoKIFRoaXMgdmFsdWUgc3Bl
Y2lmaWVzIGRlZmF1bHQgdG8gYmUgdGhlIG9uZSB1c2VkIGJ5IHRoZSBiYXNlIG1vZGVsIHdo
aWxlCiBjcmVhdGluZyB0aGUgbW9kZWwuCgoMCgUEAAIFBBIDXwIKCgwKBQQAAgUFEgNfCxAK
DAoFBAACBQESA18RHAoMCgUEAAIFAxIDXx8hCgwKBQQAAgUIEgNfIkoKDwoIBAACBQicCAAS
A18jSQryAQoEBAACBhIDaAJFGuQBIE9wdGlvbmFsLiBGb3IgTnVjbGV1cyBzYW1wbGluZy4K
CiBOdWNsZXVzIHNhbXBsaW5nIGNvbnNpZGVycyB0aGUgc21hbGxlc3Qgc2V0IG9mIHRva2Vu
cyB3aG9zZSBwcm9iYWJpbGl0eQogc3VtIGlzIGF0IGxlYXN0IGB0b3BfcGAuCgogVGhpcyB2
YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBiZSB0aGUgb25lIHVzZWQgYnkgdGhlIGJhc2Ug
bW9kZWwgd2hpbGUKIGNyZWF0aW5nIHRoZSBtb2RlbC4KCgwKBQQAAgYEEgNoAgoKDAoFBAAC
BgUSA2gLEAoMCgUEAAIGARIDaBEWCgwKBQQAAgYDEgNoGRsKDAoFBAACBggSA2gcRAoPCggE
AAIGCJwIABIDaB1DCq0CCgQEAAIHEgNyAkUanwIgT3B0aW9uYWwuIEZvciBUb3AtayBzYW1w
bGluZy4KCiBUb3AtayBzYW1wbGluZyBjb25zaWRlcnMgdGhlIHNldCBvZiBgdG9wX2tgIG1v
c3QgcHJvYmFibGUgdG9rZW5zLgogVGhpcyB2YWx1ZSBzcGVjaWZpZXMgZGVmYXVsdCB0byBi
ZSB1c2VkIGJ5IHRoZSBiYWNrZW5kIHdoaWxlIG1ha2luZyB0aGUKIGNhbGwgdG8gdGhlIG1v
ZGVsLgoKIFRoaXMgdmFsdWUgc3BlY2lmaWVzIGRlZmF1bHQgdG8gYmUgdGhlIG9uZSB1c2Vk
IGJ5IHRoZSBiYXNlIG1vZGVsIHdoaWxlCiBjcmVhdGluZyB0aGUgbW9kZWwuCgoMCgUEAAIH
BBIDcgIKCgwKBQQAAgcFEgNyCxAKDAoFBAACBwESA3IRFgoMCgUEAAIHAxIDchkbCgwKBQQA
AgcIEgNyHEQKDwoIBAACBwicCAASA3IdQwo5CgQEAAIIEgN1Aj4aLCBPdXRwdXQgb25seS4g
VGhlIHN0YXRlIG9mIHRoZSB0dW5lZCBtb2RlbC4KCgwKBQQAAggGEgN1AgcKDAoFBAACCAES
A3UIDQoMCgUEAAIIAxIDdRARCgwKBQQAAggIEgN1Ej0KDwoIBAACCAicCAASA3UTPApHCgQE
AAIJEgR4AnkyGjkgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIG1vZGVs
IHdhcyBjcmVhdGVkLgoKDAoFBAACCQYSA3gCGwoMCgUEAAIJARIDeBwnCgwKBQQAAgkDEgN4
KisKDAoFBAACCQgSA3kGMQoPCggEAAIJCJwIABIDeQcwCkcKBAQAAgoSBHwCfTIaOSBPdXRw
dXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoaXMgbW9kZWwgd2FzIHVwZGF0ZWQuCgoM
CgUEAAIKBhIDfAIbCgwKBQQAAgoBEgN8HCcKDAoFBAACCgMSA3wqKwoMCgUEAAIKCBIDfQYx
Cg8KCAQAAgoInAgAEgN9BzAKRwoEBAACCxIEgAECRxo5IFJlcXVpcmVkLiBUaGUgdHVuaW5n
IHRhc2sgdGhhdCBjcmVhdGVzIHRoZSB0dW5lZCBtb2RlbC4KCg0KBQQAAgsGEgSAAQIMCg0K
BQQAAgsBEgSAAQ0YCg0KBQQAAgsDEgSAARsdCg0KBQQAAgsIEgSAAR5GChAKCAQAAgsInAgA
EgSAAR9FCl0KBAQAAgwSBoMBAoQBLxpNIE9wdGlvbmFsLiBMaXN0IG9mIHByb2plY3QgbnVt
YmVycyB0aGF0IGhhdmUgcmVhZCBhY2Nlc3MgdG8gdGhlIHR1bmVkIG1vZGVsLgoKDQoFBAAC
DAQSBIMBAgoKDQoFBAACDAUSBIMBCxAKDQoFBAACDAESBIMBEScKDQoFBAACDAMSBIMBKiwK
DQoFBAACDAgSBIQBBi4KEAoIBAACDAicCAASBIQBBy0KQQoCBAESBogBAJsBARozIFR1bmVk
IG1vZGVsIGFzIGEgc291cmNlIGZvciB0cmFpbmluZyBhIG5ldyBtb2RlbC4KCgsKAwQBARIE
iAEIGAqbAQoEBAECABIGjAECkQEEGooBIEltbXV0YWJsZS4gVGhlIG5hbWUgb2YgdGhlIGBU
dW5lZE1vZGVsYCB0byB1c2UgYXMgdGhlIHN0YXJ0aW5nIHBvaW50IGZvcgogdHJhaW5pbmcg
dGhlIG5ldyBtb2RlbC4KIEV4YW1wbGU6IGB0dW5lZE1vZGVscy9teS10dW5lZC1tb2RlbGAK
Cg0KBQQBAgAFEgSMAQIICg0KBQQBAgABEgSMAQkUCg0KBQQBAgADEgSMARcYCg8KBQQBAgAI
EgaMARmRAQMKEAoIBAECAAicCAASBI0BBCsKEQoHBAECAAifCBIGjgEEkAEFCoUBCgQEAQIB
EgaVAQKaAQQadSBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIGJhc2UgYE1vZGVsYCB0
aGlzIGBUdW5lZE1vZGVsYCB3YXMgdHVuZWQgZnJvbS4KIEV4YW1wbGU6IGBtb2RlbHMvZ2Vt
aW5pLTEuNS1mbGFzaC0wMDFgCgoNCgUEAQIBBRIElQECCAoNCgUEAQIBARIElQEJEwoNCgUE
AQIBAxIElQEWFwoPCgUEAQIBCBIGlQEYmgEDChAKCAQBAgEInAgAEgSWAQQtChEKBwQBAgEI
nwgSBpcBBJkBBQo2CgIEAhIGngEAtQEBGiggVHVuaW5nIHRhc2tzIHRoYXQgY3JlYXRlIHR1
bmVkIG1vZGVscy4KCgsKAwQCARIEngEIEgpMCgQEAgIAEgagAQKhATIaPCBPdXRwdXQgb25s
eS4gVGhlIHRpbWVzdGFtcCB3aGVuIHR1bmluZyB0aGlzIG1vZGVsIHN0YXJ0ZWQuCgoNCgUE
AgIABhIEoAECGwoNCgUEAgIAARIEoAEcJgoNCgUEAgIAAxIEoAEpKgoNCgUEAgIACBIEoQEG
MQoQCggEAgIACJwIABIEoQEHMApOCgQEAgIBEgakAQKlATIaPiBPdXRwdXQgb25seS4gVGhl
IHRpbWVzdGFtcCB3aGVuIHR1bmluZyB0aGlzIG1vZGVsIGNvbXBsZXRlZC4KCg0KBQQCAgEG
EgSkAQIbCg0KBQQCAgEBEgSkARwpCg0KBQQCAgEDEgSkASwtCg0KBQQCAgEIEgSlAQYxChAK
CAQCAgEInAgAEgSlAQcwCj8KBAQCAgISBqgBAqkBMhovIE91dHB1dCBvbmx5LiBNZXRyaWNz
IGNvbGxlY3RlZCBkdXJpbmcgdHVuaW5nLgoKDQoFBAICAgQSBKgBAgoKDQoFBAICAgYSBKgB
CxkKDQoFBAICAgESBKgBGiMKDQoFBAICAgMSBKgBJicKDQoFBAICAggSBKkBBjEKEAoIBAIC
AgicCAASBKkBBzAKSwoEBAICAxIGrAECsAEEGjsgUmVxdWlyZWQuIElucHV0IG9ubHkuIElt
bXV0YWJsZS4gVGhlIG1vZGVsIHRyYWluaW5nIGRhdGEuCgoNCgUEAgIDBhIErAECCQoNCgUE
AgIDARIErAEKFwoNCgUEAgIDAxIErAEaGwoPCgUEAgIDCBIGrAEcsAEDChAKCAQCAgMInAgA
EgStAQQsChAKCAQCAgMInAgBEgSuAQQqChAKCAQCAgMInAgCEgSvAQQrCnkKBAQCAgQSBLQB
AlAaayBJbW11dGFibGUuIEh5cGVycGFyYW1ldGVycyBjb250cm9sbGluZyB0aGUgdHVuaW5n
IHByb2Nlc3MuIElmIG5vdCBwcm92aWRlZCwKIGRlZmF1bHQgdmFsdWVzIHdpbGwgYmUgdXNl
ZC4KCg0KBQQCAgQGEgS0AQIRCg0KBQQCAgQBEgS0ARIhCg0KBQQCAgQDEgS0ASQlCg0KBQQC
AgQIEgS0ASZPChAKCAQCAgQInAgAEgS0ASdOCn4KAgQDEga5AQDXAQEacCBIeXBlcnBhcmFt
ZXRlcnMgY29udHJvbGxpbmcgdGhlIHR1bmluZyBwcm9jZXNzLiBSZWFkIG1vcmUgYXQKIGh0
dHBzOi8vYWkuZ29vZ2xlLmRldi9kb2NzL21vZGVsX3R1bmluZ19ndWlkYW5jZQoKCwoDBAMB
EgS5AQgXCkUKBAQDCAASBrsBAs0BAxo1IE9wdGlvbnMgZm9yIHNwZWNpZnlpbmcgbGVhcm5p
bmcgcmF0ZSBkdXJpbmcgdHVuaW5nLgoKDQoFBAMIAAESBLsBCBwKvAEKBAQDAgASBr8BBMIB
BhqrASBPcHRpb25hbC4gSW1tdXRhYmxlLiBUaGUgbGVhcm5pbmcgcmF0ZSBoeXBlcnBhcmFt
ZXRlciBmb3IgdHVuaW5nLgogSWYgbm90IHNldCwgYSBkZWZhdWx0IG9mIDAuMDAxIG9yIDAu
MDAwMiB3aWxsIGJlIGNhbGN1bGF0ZWQgYmFzZWQgb24gdGhlCiBudW1iZXIgb2YgdHJhaW5p
bmcgZXhhbXBsZXMuCgoNCgUEAwIABRIEvwEECQoNCgUEAwIAARIEvwEKFwoNCgUEAwIAAxIE
vwEaHAoPCgUEAwIACBIGvwEdwgEFChAKCAQDAgAInAgAEgTAAQYtChAKCAQDAgAInAgBEgTB
AQYsCtQCCgQEAwIBEgbJAQTMAQYawwIgT3B0aW9uYWwuIEltbXV0YWJsZS4gVGhlIGxlYXJu
aW5nIHJhdGUgbXVsdGlwbGllciBpcyB1c2VkIHRvIGNhbGN1bGF0ZSBhCiBmaW5hbCBsZWFy
bmluZ19yYXRlIGJhc2VkIG9uIHRoZSBkZWZhdWx0IChyZWNvbW1lbmRlZCkgdmFsdWUuIEFj
dHVhbAogbGVhcm5pbmcgcmF0ZSA6PSBsZWFybmluZ19yYXRlX211bHRpcGxpZXIgKiBkZWZh
dWx0IGxlYXJuaW5nIHJhdGUgRGVmYXVsdAogbGVhcm5pbmcgcmF0ZSBpcyBkZXBlbmRlbnQg
b24gYmFzZSBtb2RlbCBhbmQgZGF0YXNldCBzaXplLiBJZiBub3Qgc2V0LCBhCiBkZWZhdWx0
IG9mIDEuMCB3aWxsIGJlIHVzZWQuCgoNCgUEAwIBBRIEyQEECQoNCgUEAwIBARIEyQEKIgoN
CgUEAwIBAxIEyQElJwoPCgUEAwIBCBIGyQEozAEFChAKCAQDAgEInAgAEgTKAQYtChAKCAQD
AgEInAgBEgTLAQYsCpQBCgQEAwICEgTRAQJMGoUBIEltbXV0YWJsZS4gVGhlIG51bWJlciBv
ZiB0cmFpbmluZyBlcG9jaHMuIEFuIGVwb2NoIGlzIG9uZSBwYXNzIHRocm91Z2ggdGhlCiB0
cmFpbmluZyBkYXRhLiBJZiBub3Qgc2V0LCBhIGRlZmF1bHQgb2YgNSB3aWxsIGJlIHVzZWQu
CgoNCgUEAwICBBIE0QECCgoNCgUEAwICBRIE0QELEAoNCgUEAwICARIE0QERHAoNCgUEAwIC
AxIE0QEfIQoNCgUEAwICCBIE0QEiSwoQCggEAwICCJwIABIE0QEjSgqfAQoEBAMCAxIE1gEC
SxqQASBJbW11dGFibGUuIFRoZSBiYXRjaCBzaXplIGh5cGVycGFyYW1ldGVyIGZvciB0dW5p
bmcuCiBJZiBub3Qgc2V0LCBhIGRlZmF1bHQgb2YgNCBvciAxNiB3aWxsIGJlIHVzZWQgYmFz
ZWQgb24gdGhlIG51bWJlciBvZgogdHJhaW5pbmcgZXhhbXBsZXMuCgoNCgUEAwIDBBIE1gEC
CgoNCgUEAwIDBRIE1gELEAoNCgUEAwIDARIE1gERGwoNCgUEAwIDAxIE1gEeIAoNCgUEAwID
CBIE1gEhSgoQCggEAwIDCJwIABIE1gEiSQozCgIEBBIG2gEA4AEBGiUgRGF0YXNldCBmb3Ig
dHJhaW5pbmcgb3IgdmFsaWRhdGlvbi4KCgsKAwQEARIE2gEIDwo5CgQEBAgAEgbcAQLfAQMa
KSBJbmxpbmUgZGF0YSBvciBhIHJlZmVyZW5jZSB0byB0aGUgZGF0YS4KCg0KBQQECAABEgTc
AQgPCkgKBAQEAgASBN4BBEkaOiBPcHRpb25hbC4gSW5saW5lIGV4YW1wbGVzIHdpdGggc2lt
cGxlIGlucHV0L291dHB1dCB0ZXh0LgoKDQoFBAQCAAYSBN4BBBIKDQoFBAQCAAESBN4BExsK
DQoFBAQCAAMSBN4BHh8KDQoFBAQCAAgSBN4BIEgKEAoIBAQCAAicCAASBN4BIUcKTQoCBAUS
BuMBAOoBARo/IEEgc2V0IG9mIHR1bmluZyBleGFtcGxlcy4gQ2FuIGJlIHRyYWluaW5nIG9y
IHZhbGlkYXRpb24gZGF0YS4KCgsKAwQFARIE4wEIFgp8CgQEBQIAEgTmAQImGm4gVGhlIGV4
YW1wbGVzLiBFeGFtcGxlIGlucHV0IGNhbiBiZSBmb3IgdGV4dCBvciBkaXNjdXNzLCBidXQg
YWxsIGV4YW1wbGVzCiBpbiBhIHNldCBtdXN0IGJlIG9mIHRoZSBzYW1lIHR5cGUuCgoNCgUE
BQIABBIE5gECCgoNCgUEBQIABhIE5gELGAoNCgUEBQIAARIE5gEZIQoNCgUEBQIAAxIE5gEk
JQo+CgQEBQIBEgTpAQI5GjAgQ29udGVudCBleGFtcGxlcy4gRm9yIG11bHRpdHVybiBjb252
ZXJzYXRpb25zLgoKDQoFBAUCAQQSBOkBAgoKDQoFBAUCAQYSBOkBCyEKDQoFBAUCAQESBOkB
IjQKDQoFBAUCAQMSBOkBNzgKugIKAgQGEgb0AQD6AQEaqwIgQSBkYXRhdHlwZSBjb250YWlu
aW5nIGRhdGEgdGhhdCBpcyBwYXJ0IG9mIGEgbXVsdGktcGFydCBgVHVuaW5nQ29udGVudGAK
IG1lc3NhZ2UuCgogVGhpcyBpcyBhIHN1YnNldCBvZiB0aGUgUGFydCB1c2VkIGZvciBtb2Rl
bCBpbmZlcmVuY2UsIHdpdGggbGltaXRlZCB0eXBlCiBzdXBwb3J0LgoKIEEgYFBhcnRgIGNv
bnNpc3RzIG9mIGRhdGEgd2hpY2ggaGFzIGFuIGFzc29jaWF0ZWQgZGF0YXR5cGUuIEEgYFBh
cnRgIGNhbgogb25seSBjb250YWluIG9uZSBvZiB0aGUgYWNjZXB0ZWQgdHlwZXMgaW4gYFBh
cnQuZGF0YWAuCgoLCgMEBgESBPQBCBIKOQoEBAYIABIG9gEC+QEDGikgRGF0YSBmb3IgdGhl
IHBhcnQuIE9ubHkgdGV4dCBzdXBwb3J0ZWQuCgoNCgUEBggAARIE9gEIDAocCgQEBgIAEgT4
AQQUGg4gSW5saW5lIHRleHQuCgoNCgUEBgIABRIE+AEECgoNCgUEBgIAARIE+AELDwoNCgUE
BgIAAxIE+AESEwrrAgoCBAcSBoICAIwCARrcAiBUaGUgc3RydWN0dXJlZCBkYXRhdHlwZSBj
b250YWluaW5nIG11bHRpLXBhcnQgY29udGVudCBvZiBhbiBleGFtcGxlIG1lc3NhZ2UuCgog
VGhpcyBpcyBhIHN1YnNldCBvZiB0aGUgQ29udGVudCBwcm90byB1c2VkIGR1cmluZyBtb2Rl
bCBpbmZlcmVuY2Ugd2l0aAogbGltaXRlZCB0eXBlIHN1cHBvcnQuIEEgYENvbnRlbnRgIGlu
Y2x1ZGVzIGEgYHJvbGVgIGZpZWxkIGRlc2lnbmF0aW5nIHRoZQogcHJvZHVjZXIgb2YgdGhl
IGBDb250ZW50YCBhbmQgYSBgcGFydHNgIGZpZWxkIGNvbnRhaW5pbmcgbXVsdGktcGFydCBk
YXRhCiB0aGF0IGNvbnRhaW5zIHRoZSBjb250ZW50IG9mIHRoZSBtZXNzYWdlIHR1cm4uCgoL
CgMEBwESBIICCBUKZwoEBAcCABIEhQICIBpZIE9yZGVyZWQgYFBhcnRzYCB0aGF0IGNvbnN0
aXR1dGUgYSBzaW5nbGUgbWVzc2FnZS4gUGFydHMgbWF5IGhhdmUgZGlmZmVyZW50CiBNSU1F
IHR5cGVzLgoKDQoFBAcCAAQSBIUCAgoKDQoFBAcCAAYSBIUCCxUKDQoFBAcCAAESBIUCFhsK
DQoFBAcCAAMSBIUCHh8KrgEKBAQHAgESBIsCAjsanwEgT3B0aW9uYWwuIFRoZSBwcm9kdWNl
ciBvZiB0aGUgY29udGVudC4gTXVzdCBiZSBlaXRoZXIgJ3VzZXInIG9yICdtb2RlbCcuCgog
VXNlZnVsIHRvIHNldCBmb3IgbXVsdGktdHVybiBjb252ZXJzYXRpb25zLCBvdGhlcndpc2Ug
Y2FuIGJlIGxlZnQgYmxhbmsKIG9yIHVuc2V0LgoKDQoFBAcCAQUSBIsCAggKDQoFBAcCAQES
BIsCCQ0KDQoFBAcCAQMSBIsCEBEKDQoFBAcCAQgSBIsCEjoKEAoIBAcCAQicCAASBIsCEzkK
NgoCBAgSBo8CAJcCARooIEEgdHVuaW5nIGV4YW1wbGUgd2l0aCBtdWx0aXR1cm4gaW5wdXQu
CgoLCgMECAESBI8CCB4KVQoEBAgCABIGkgICkwIvGkUgT3B0aW9uYWwuIERldmVsb3BlciBz
ZXQgc3lzdGVtIGluc3RydWN0aW9ucy4KIEN1cnJlbnRseSwgdGV4dCBvbmx5LgoKDQoFBAgC
AAQSBJICAgoKDQoFBAgCAAYSBJICCxgKDQoFBAgCAAESBJICGSsKDQoFBAgCAAMSBJICLi8K
DQoFBAgCAAgSBJMCBi4KEAoIBAgCAAicCAASBJMCBy0KQwoEBAgCARIElgICJho1IEVhY2gg
Q29udGVudCByZXByZXNlbnRzIGEgdHVybiBpbiB0aGUgY29udmVyc2F0aW9uLgoKDQoFBAgC
AQQSBJYCAgoKDQoFBAgCAQYSBJYCCxgKDQoFBAgCAQESBJYCGSEKDQoFBAgCAQMSBJYCJCUK
LAoCBAkSBpoCAKMCARoeIEEgc2luZ2xlIGV4YW1wbGUgZm9yIHR1bmluZy4KCgsKAwQJARIE
mgIIFQo6CgQECQgAEgacAgKfAgMaKiBUaGUgaW5wdXQgdG8gdGhlIG1vZGVsIGZvciB0aGlz
IGV4YW1wbGUuCgoNCgUECQgAARIEnAIIEworCgQECQIAEgSeAgRDGh0gT3B0aW9uYWwuIFRl
eHQgbW9kZWwgaW5wdXQuCgoNCgUECQIABRIEngIECgoNCgUECQIAARIEngILFQoNCgUECQIA
AxIEngIYGQoNCgUECQIACBIEngIaQgoQCggECQIACJwIABIEngIbQQo0CgQECQIBEgSiAgI9
GiYgUmVxdWlyZWQuIFRoZSBleHBlY3RlZCBtb2RlbCBvdXRwdXQuCgoNCgUECQIBBRIEogIC
CAoNCgUECQIBARIEogIJDwoNCgUECQIBAxIEogISEwoNCgUECQIBCBIEogIUPAoQCggECQIB
CJwIABIEogIVOwowCgIEChIGpgIAswIBGiIgUmVjb3JkIGZvciBhIHNpbmdsZSB0dW5pbmcg
c3RlcC4KCgsKAwQKARIEpgIIFgotCgQECgIAEgSoAgI9Gh8gT3V0cHV0IG9ubHkuIFRoZSB0
dW5pbmcgc3RlcC4KCg0KBQQKAgAFEgSoAgIHCg0KBQQKAgABEgSoAggMCg0KBQQKAgADEgSo
Ag8QCg0KBQQKAgAIEgSoAhE8ChAKCAQKAgAInAgAEgSoAhI7Cj0KBAQKAgESBKsCAj4aLyBP
dXRwdXQgb25seS4gVGhlIGVwb2NoIHRoaXMgc3RlcCB3YXMgcGFydCBvZi4KCg0KBQQKAgEF
EgSrAgIHCg0KBQQKAgEBEgSrAggNCg0KBQQKAgEDEgSrAhARCg0KBQQKAgEIEgSrAhI9ChAK
CAQKAgEInAgAEgSrAhM8ClIKBAQKAgISBK4CAkIaRCBPdXRwdXQgb25seS4gVGhlIG1lYW4g
bG9zcyBvZiB0aGUgdHJhaW5pbmcgZXhhbXBsZXMgZm9yIHRoaXMgc3RlcC4KCg0KBQQKAgIF
EgSuAgIHCg0KBQQKAgIBEgSuAggRCg0KBQQKAgIDEgSuAhQVCg0KBQQKAgIIEgSuAhZBChAK
CAQKAgIInAgAEgSuAhdACksKBAQKAgMSBrECArICMho7IE91dHB1dCBvbmx5LiBUaGUgdGlt
ZXN0YW1wIHdoZW4gdGhpcyBtZXRyaWMgd2FzIGNvbXB1dGVkLgoKDQoFBAoCAwYSBLECAhsK
DQoFBAoCAwESBLECHCgKDQoFBAoCAwMSBLECKywKDQoFBAoCAwgSBLICBjEKEAoIBAoCAwic
CAASBLICBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel ===
    # Fields for TunedModel
    # Field: tuned_model_source Type: 11 (.google.ai.generativelanguage.v1alpha.TunedModelSource)
    # Field: base_model Type: 9 ()
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: temperature Type: 2 ()
    # Field: top_p Type: 2 ()
    # Field: top_k Type: 5 ()
    # Field: state Type: 14 (.google.ai.generativelanguage.v1alpha.TunedModel.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: tuning_task Type: 11 (.google.ai.generativelanguage.v1alpha.TuningTask)
    # Field: reader_project_numbers Type: 3 ()

# Enum: TunedModel::State
our $TunedModel_STATE_UNSPECIFIED = 0;
our $TunedModel_CREATING = 1;
our $TunedModel_ACTIVE = 2;
our $TunedModel_FAILED = 3;

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource ===
    # Fields for TunedModelSource
    # Field: tuned_model Type: 9 ()
    # Field: base_model Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask ===
    # Fields for TuningTask
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: complete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: snapshots Type: 11 (.google.ai.generativelanguage.v1alpha.TuningSnapshot)
    # Field: training_data Type: 11 (.google.ai.generativelanguage.v1alpha.Dataset)
    # Field: hyperparameters Type: 11 (.google.ai.generativelanguage.v1alpha.Hyperparameters)

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters ===
    # Fields for Hyperparameters
    # Field: learning_rate Type: 2 ()
    # Field: learning_rate_multiplier Type: 2 ()
    # Field: epoch_count Type: 5 ()
    # Field: batch_size Type: 5 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset ===
    # Fields for Dataset
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1alpha.TuningExamples)

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples ===
    # Fields for TuningExamples
    # Field: examples Type: 11 (.google.ai.generativelanguage.v1alpha.TuningExample)
    # Field: multiturn_examples Type: 11 (.google.ai.generativelanguage.v1alpha.TuningMultiturnExample)

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart ===
    # Fields for TuningPart
    # Field: text Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent ===
    # Fields for TuningContent
    # Field: parts Type: 11 (.google.ai.generativelanguage.v1alpha.TuningPart)
    # Field: role Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample ===
    # Fields for TuningMultiturnExample
    # Field: system_instruction Type: 11 (.google.ai.generativelanguage.v1alpha.TuningContent)
    # Field: contents Type: 11 (.google.ai.generativelanguage.v1alpha.TuningContent)

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample ===
    # Fields for TuningExample
    # Field: text_input Type: 9 ()
    # Field: output Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot ===
    # Fields for TuningSnapshot
    # Field: step Type: 5 ()
    # Field: epoch Type: 5 ()
    # Field: mean_loss Type: 2 ()
    # Field: compute_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::TunedModel - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1alpha/tuned_model.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha::TunedModel;

    my $msg = Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel->new({
        tuned_model_source => $tuned_model_source,
        base_model => $base_model,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->tuned_model_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1alpha/tuned_model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel

A fine-tuned model created using ModelService.CreateTunedModel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model_source() >> / C<< $msg->tuned_model_source($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource>)

Optional. TunedModel to use as the starting point for training the new
model.

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Immutable. The name of the `Model` to tune.
Example: `models/gemini-1.5-flash-001`

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The tuned model name. A unique name will be generated on
create. Example: `tunedModels/az2mb0bpw6i` If display_name is set on
create, the id portion of the name will be set by concatenating the words
of the display_name with hyphens and adding a random portion for
uniqueness.

Example:

 * display_name = `Sentence Translator`
 * name = `tunedModels/sentence-translator-u3b7m`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The name to display for this model in user interfaces.
The display name must be up to 40 characters including spaces.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A short description of this model.

=item * C<< $msg->temperature() >> / C<< $msg->temperature($value) >>

Type: C<Float>

Optional. Controls the randomness of the output.

Values can range over `[0.0,1.0]`, inclusive. A value closer to `1.0` will
produce responses that are more varied, while a value closer to `0.0` will
typically result in less surprising responses from the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_p() >> / C<< $msg->top_p($value) >>

Type: C<Float>

Optional. For Nucleus sampling.

Nucleus sampling considers the smallest set of tokens whose probability
sum is at least `top_p`.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->top_k() >> / C<< $msg->top_k($value) >>

Type: C<Int32>

Optional. For Top-k sampling.

Top-k sampling considers the set of `top_k` most probable tokens.
This value specifies default to be used by the backend while making the
call to the model.

This value specifies default to be the one used by the base model while
creating the model.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::State>)

Output only. The state of the tuned model.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this model was updated.

=item * C<< $msg->tuning_task() >> / C<< $msg->tuning_task($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask>)

Required. The tuning task that creates the tuned model.

=item * C<< $msg->reader_project_numbers() >> / C<< $msg->reader_project_numbers($value) >>

Type: C<Int64>

Optional. List of project numbers that have read access to the tuned model.

=back

=head3 Enum: TunedModel::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource

Tuned model as a source for training a new model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tuned_model() >> / C<< $msg->tuned_model($value) >>

Type: C<String>

Immutable. The name of the `TunedModel` to use as the starting point for
training the new model.
Example: `tunedModels/my-tuned-model`

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

Output only. The name of the base `Model` this `TunedModel` was tuned from.
Example: `models/gemini-1.5-flash-001`

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask

Tuning tasks that create tuned models.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model started.

=item * C<< $msg->complete_time() >> / C<< $msg->complete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when tuning this model completed.

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot>)

Output only. Metrics collected during tuning.

=item * C<< $msg->training_data() >> / C<< $msg->training_data($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset>)

Required. Input only. Immutable. The model training data.

=item * C<< $msg->hyperparameters() >> / C<< $msg->hyperparameters($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters>)

Immutable. Hyperparameters controlling the tuning process. If not provided,
default values will be used.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters

Hyperparameters controlling the tuning process. Read more at
https://ai.google.dev/docs/model_tuning_guidance

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->learning_rate() >> / C<< $msg->learning_rate($value) >>

Type: C<Float>

Optional. Immutable. The learning rate hyperparameter for tuning.
If not set, a default of 0.001 or 0.0002 will be calculated based on the
number of training examples.

=item * C<< $msg->learning_rate_multiplier() >> / C<< $msg->learning_rate_multiplier($value) >>

Type: C<Float>

Optional. Immutable. The learning rate multiplier is used to calculate a
final learning_rate based on the default (recommended) value. Actual
learning rate := learning_rate_multiplier * default learning rate Default
learning rate is dependent on base model and dataset size. If not set, a
default of 1.0 will be used.

=item * C<< $msg->epoch_count() >> / C<< $msg->epoch_count($value) >>

Type: C<Int32>

Immutable. The number of training epochs. An epoch is one pass through the
training data. If not set, a default of 5 will be used.

=item * C<< $msg->batch_size() >> / C<< $msg->batch_size($value) >>

Type: C<Int32>

Immutable. The batch size hyperparameter for tuning.
If not set, a default of 4 or 16 will be used based on the number of
training examples.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset

Dataset for training or validation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples>)

Optional. Inline examples with simple input/output text.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples

A set of tuning examples. Can be training or validation data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample>)

The examples. Example input can be for text or discuss, but all examples
in a set must be of the same type.

=item * C<< $msg->multiturn_examples() >> / C<< $msg->multiturn_examples($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample>)

Content examples. For multiturn conversations.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart

A datatype containing data that is part of a multi-part `TuningContent`
message.

This is a subset of the Part used for model inference, with limited type
support.

A `Part` consists of data which has an associated datatype. A `Part` can
only contain one of the accepted types in `Part.data`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Inline text.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent

The structured datatype containing multi-part content of an example message.

This is a subset of the Content proto used during model inference with
limited type support. A `Content` includes a `role` field designating the
producer of the `Content` and a `parts` field containing multi-part data
that contains the content of the message turn.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parts() >> / C<< $msg->parts($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart>)

Ordered `Parts` that constitute a single message. Parts may have different
MIME types.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Optional. The producer of the content. Must be either 'user' or 'model'.

Useful to set for multi-turn conversations, otherwise can be left blank
or unset.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample

A tuning example with multiturn input.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->system_instruction() >> / C<< $msg->system_instruction($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent>)

Optional. Developer set system instructions.
Currently, text only.

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent>)

Each Content represents a turn in the conversation.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample

A single example for tuning.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_input() >> / C<< $msg->text_input($value) >>

Type: C<String>

Optional. Text model input.

=item * C<< $msg->output() >> / C<< $msg->output($value) >>

Type: C<String>

Required. The expected model output.

=back

=head2 Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot

Record for a single tuning step.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Int32>

Output only. The tuning step.

=item * C<< $msg->epoch() >> / C<< $msg->epoch($value) >>

Type: C<Int32>

Output only. The epoch this step was part of.

=item * C<< $msg->mean_loss() >> / C<< $msg->mean_loss($value) >>

Type: C<Float>

Output only. The mean loss of the training examples for this step.

=item * C<< $msg->compute_time() >> / C<< $msg->compute_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this metric was computed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1alpha::TunedModel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
