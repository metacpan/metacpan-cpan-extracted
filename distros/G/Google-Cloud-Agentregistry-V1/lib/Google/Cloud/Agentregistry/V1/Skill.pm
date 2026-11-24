package Google::Cloud::Agentregistry::V1::Skill;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9za2lsbC5wcm90bxIdZ29vZ2xlLmNs
b3VkLmFnZW50cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
G2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90
bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLXCwoFU2tpbGwSFwoEbmFtZRgB
IAEoCUID4EEIUgRuYW1lEh0KA3VpZBgCIAEoCUIL4ozP1wgCCAHgQQNSA3VpZBImCgxkaXNw
bGF5X25hbWUYAyABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVzY3JpcHRpb24YBCABKAlC
A+BBAVILZGVzY3JpcHRpb24SQgoEdHlwZRgFIAEoDjIpLmdvb2dsZS5jbG91ZC5hZ2VudHJl
Z2lzdHJ5LnYxLlNraWxsLlR5cGVCA+BBAlIEdHlwZRJFCgVzdGF0ZRgGIAEoDjIqLmdvb2ds
ZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLlNraWxsLlN0YXRlQgPgQQNSBXN0YXRlElgKDHRh
cmdldF9zdGF0ZRgHIAEoDjIwLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLlNraWxs
LlRhcmdldFN0YXRlQgPgQQJSC3RhcmdldFN0YXRlEl0KEGRlZmF1bHRfcmV2aXNpb24YCCAB
KAlCMuBBAfpBLAoqYWdlbnRyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9Ta2lsbFJldmlzaW9u
Ug9kZWZhdWx0UmV2aXNpb24SUQoLZnJvbnRtYXR0ZXIYCSABKAsyKi5nb29nbGUuY2xvdWQu
YWdlbnRyZWdpc3RyeS52MS5Gcm9udG1hdHRlckID4EEDUgtmcm9udG1hdHRlchIeCghza2ls
bF9pZBgRIAEoCUID4EEDUgdza2lsbElkEkAKC2NyZWF0ZV90aW1lGAsgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAwg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkwKCXB1
Ymxpc2hlchgPIAEoCUIu4EEB+kEoCiZhZ2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1B1
Ymxpc2hlclIJcHVibGlzaGVyEl8KEGluaXRpYWxfcmV2aXNpb24YDiABKAsyLC5nb29nbGUu
Y2xvdWQuYWdlbnRyZWdpc3RyeS52MS5Ta2lsbFJldmlzaW9uQgbgQQHgQQRSD2luaXRpYWxS
ZXZpc2lvbhJbCg9zY2FubmluZ19jb25maWcYFCABKAsyLS5nb29nbGUuY2xvdWQuYWdlbnRy
ZWdpc3RyeS52MS5TY2FubmluZ0NvbmZpZ0ID4EEBUg5zY2FubmluZ0NvbmZpZyIoCgRUeXBl
EhQKEFRZUEVfVU5TUEVDSUZJRUQQABIKCgZTSU1QTEUQASKtAQoFU3RhdGUSFQoRU1RBVEVf
VU5TUEVDSUZJRUQQABISCg5TVEFURV9DUkVBVElORxABEg8KC1NUQVRFX0RSQUZUEAISEAoM
U1RBVEVfQUNUSVZFEAMSEgoOU1RBVEVfRElTQUJMRUQQBBIUChBTVEFURV9ERVBSRUNBVEVE
EAUSGAoUU1RBVEVfREVDT01NSVNTSU9ORUQQBhISCg5TVEFURV9ERUxFVElORxAHIrUBCgtU
YXJnZXRTdGF0ZRIcChhUQVJHRVRfU1RBVEVfVU5TUEVDSUZJRUQQABIWChJUQVJHRVRfU1RB
VEVfRFJBRlQQARIXChNUQVJHRVRfU1RBVEVfQUNUSVZFEAISGQoVVEFSR0VUX1NUQVRFX0RJ
U0FCTEVEEAMSGwoXVEFSR0VUX1NUQVRFX0RFUFJFQ0FURUQQBBIfChtUQVJHRVRfU1RBVEVf
REVDT01NSVNTSU9ORUQQBTpu6kFrCiJhZ2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1Nr
aWxsEjZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2tpbGxzL3tz
a2lsbH0qBnNraWxsczIFc2tpbGwiwgEKDlNjYW5uaW5nQ29uZmlnElEKBnBvbGljeRgBIAEo
DjI0Lmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLlNjYW5uaW5nQ29uZmlnLlBvbGlj
eUID4EEBUgZwb2xpY3kiXQoGUG9saWN5EhYKElBPTElDWV9VTlNQRUNJRklFRBAAEgwKCERJ
U0FCTEVEEAESFAoQRU5BQkxFRF9CTE9DS0lORxACEhcKE0VOQUJMRURfTk9OQkxPQ0tJTkcQ
AyKvAgoLRnJvbnRtYXR0ZXISFwoEbmFtZRgFIAEoCUID4EECUgRuYW1lEiUKC2Rlc2NyaXB0
aW9uGAIgASgJQgPgQQJSC2Rlc2NyaXB0aW9uEh0KB2xpY2Vuc2UYBiABKAlCA+BBAVIHbGlj
ZW5zZRIpCg1jb21wYXRpYmlsaXR5GAMgASgJQgPgQQFSDWNvbXBhdGliaWxpdHkSWQoIbWV0
YWRhdGEYBCADKAsyOC5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5Gcm9udG1hdHRl
ci5NZXRhZGF0YUVudHJ5QgPgQQFSCG1ldGFkYXRhGjsKDU1ldGFkYXRhRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJGChNBcmNoaXZlVXBsb2Fk
U291cmNlEi8KD2FyY2hpdmVfY29udGVudBgBIAEoDEIG4EEC4EEEUg5hcmNoaXZlQ29udGVu
dCK1CgoNU2tpbGxSZXZpc2lvbhJRCgpnY3Nfc291cmNlGAkgASgLMiguZ29vZ2xlLmNsb3Vk
LmFnZW50cmVnaXN0cnkudjEuR2NzU291cmNlQgbgQQXgQQFIAFIJZ2NzU291cmNlEnAKFWFy
Y2hpdmVfdXBsb2FkX3NvdXJjZRgMIAEoCzIyLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5
LnYxLkFyY2hpdmVVcGxvYWRTb3VyY2VCBuBBBeBBAUgAUhNhcmNoaXZlVXBsb2FkU291cmNl
EhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJNCgVzdGF0ZRgCIAEoDjIyLmdvb2dsZS5jbG91
ZC5hZ2VudHJlZ2lzdHJ5LnYxLlNraWxsUmV2aXNpb24uU3RhdGVCA+BBA1IFc3RhdGUSJAoL
c2hhMjU2X2hhc2gYAyABKAlCA+BBA1IKc2hhMjU2SGFzaBJRCgtmcm9udG1hdHRlchgEIAEo
CzIqLmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLkZyb250bWF0dGVyQgPgQQNSC2Zy
b250bWF0dGVyEkAKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEiIKCnNpemVfYnl0ZXMYCyABKANCA+BBA1IJc2l6ZUJ5
dGVzEh0KA3VpZBgOIAEoCUIL4ozP1wgCCAHgQQNSA3VpZBJdCgtzY2FuX3Jlc3VsdBgPIAEo
CzI3Lmdvb2dsZS5jbG91ZC5hZ2VudHJlZ2lzdHJ5LnYxLlNraWxsUmV2aXNpb24uU2NhblJl
c3VsdEID4EEDUgpzY2FuUmVzdWx0GpwDCgpTY2FuUmVzdWx0EmUKCnNjYW5fc3RhdGUYASAB
KA4yQS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5Ta2lsbFJldmlzaW9uLlNjYW5S
ZXN1bHQuU2NhblN0YXRlQgPgQQNSCXNjYW5TdGF0ZRI8CglzY2FuX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCHNjYW5UaW1lEigKDWVycm9yX21lc3Nh
Z2UYAyABKAlCA+BBA1IMZXJyb3JNZXNzYWdlEkgKCGZpbmRpbmdzGAQgAygJQizgQQP6QSYK
JGFnZW50cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vRmluZGluZ1IIZmluZGluZ3MidQoJU2Nh
blN0YXRlEhoKFlNDQU5fU1RBVEVfVU5TUEVDSUZJRUQQABIKCgZGQUlMRUQQARIWChJVTlNV
UFBPUlRFRF9GT1JNQVQQAhINCglTVUNDRUVERUQQAxIMCghESVNBQkxFRBAEEgsKB1JVTk5J
TkcQBSJSCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCgoG
QUNUSVZFEAISCgoGRkFJTEVEEAMSDAoIREVMRVRJTkcQBDqcAepBmAEKKmFnZW50cmVnaXN0
cnkuZ29vZ2xlYXBpcy5jb20vU2tpbGxSZXZpc2lvbhJLcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L3NraWxscy97c2tpbGx9L3JldmlzaW9ucy97cmV2aXNpb259
Kg5za2lsbFJldmlzaW9uczINc2tpbGxSZXZpc2lvbkIICgZzb3VyY2UiRwoJR2NzU291cmNl
EhUKA3VyaRgBIAEoCUID4EECUgN1cmkSIwoKZ2VuZXJhdGlvbhgCIAEoA0ID4EEBUgpnZW5l
cmF0aW9uIpsECglQdWJsaXNoZXISFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiwKD3Zlcmlm
aWVkX3ByZWZpeBgCIAEoCUID4EECUg52ZXJpZmllZFByZWZpeBImCgxkaXNwbGF5X25hbWUY
AyABKAlCA+BBAVILZGlzcGxheU5hbWUSYgoOcHVibGlzaGVyX3RpZXIYBCABKA4yNi5nb29n
bGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5QdWJsaXNoZXIuUHVibGlzaGVyVGllckID4EED
Ug1wdWJsaXNoZXJUaWVyEjAKEWRvY3VtZW50YXRpb25fdXJpGAUgASgJQgPgQQFSEGRvY3Vt
ZW50YXRpb25VcmkSJAoLc3VwcG9ydF91cmkYBiABKAlCA+BBAVIKc3VwcG9ydFVyaSJeCg1Q
dWJsaXNoZXJUaWVyEh4KGlBVQkxJU0hFUl9USUVSX1VOU1BFQ0lGSUVEEAASDwoLRklSU1Rf
UEFSVFkQARIPCgtUSElSRF9QQVJUWRACEgsKB1BSSVZBVEUQAzqCAepBfwomYWdlbnRyZWdp
c3RyeS5nb29nbGVhcGlzLmNvbS9QdWJsaXNoZXISPnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9wdWJsaXNoZXJzL3twdWJsaXNoZXJ9KgpwdWJsaXNoZXJzMglw
dWJsaXNoZXJC3QEKIWNvbS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MUIKU2tpbGxQ
cm90b1ABWkdjbG91ZC5nb29nbGUuY29tL2dvL2FnZW50cmVnaXN0cnkvYXBpdjEvYWdlbnRy
ZWdpc3RyeXBiO2FnZW50cmVnaXN0cnlwYqoCHUdvb2dsZS5DbG91ZC5BZ2VudFJlZ2lzdHJ5
LlYxygIdR29vZ2xlXENsb3VkXEFnZW50UmVnaXN0cnlcVjHqAiBHb29nbGU6OkNsb3VkOjpB
Z2VudFJlZ2lzdHJ5OjpWMUqsdAoHEgUOAKkDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACUKCQoCAwISAxQAIwoJ
CgIDAxIDFQApCggKAQgSAxcAOgoJCgIIJRIDFwA6CggKAQgSAxgAXgoJCgIICxIDGABeCggK
AQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAKwoJCgIICBIDGgArCggKAQgSAxsAOgoJCgII
ARIDGwA6CggKAQgSAxwAOgoJCgIIKRIDHAA6CggKAQgSAx0AOQoJCgIILRIDHQA5CqcBCgIE
ABIFIQC2AQEamQEgUmVwcmVzZW50cyBhbiBFeGVjdXRhYmxlIEFnZW50IFNraWxsIG9yIGEg
Q29tcG9zaXRlIFRvb2wgU3VpdGUgKEJ1bmRsZSkuCiBTaWJsaW5nIHJlc291cmNlIHdpdGgg
QWdlbnQgYW5kIE1jcFNlcnZlciB1bmRlciBhZ2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29t
LgoKCgoDBAABEgMhCA0KCwoDBAAHEgQiAicECg0KBQQAB50IEgQiAicECjEKBAQABAASBCoC
MAMaIyBUaGUgc3RydWN0dXJhbCB0eXBlIG9mIHRoZSBTa2lsbC4KCgwKBQQABAABEgMqBwsK
NQoGBAAEAAIAEgMsBBkaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4K
Cg4KBwQABAACAAESAywEFAoOCgcEAAQAAgACEgMsFxgKWAoGBAAEAAIBEgMvBA8aSSBBIHN0
YW5kYXJkLCBsZWFmIGV4ZWN1dGFibGUgc2tpbGwgY29udGFpbmluZyBuYXR1cmFsIGxhbmd1
YWdlIGFuZCBjb2RlLgoKDgoHBAAEAAIBARIDLwQKCg4KBwQABAACAQISAy8NDgolCgQEAAQB
EgQzAksDGhcgU3lzdGVtLW1hbmFnZWQgc3RhdGUuCgoMCgUEAAQBARIDMwcMCjUKBgQABAEC
ABIDNQQaGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQB
AgABEgM1BBUKDgoHBAAEAQIAAhIDNRgZCj4KBgQABAECARIDOAQXGi8gVGhlIHNraWxsIGlz
IGJlaW5nIGNyZWF0ZWQuIEl0IGlzIG5vdCBzZXJ2ZWQuCgoOCgcEAAQBAgEBEgM4BBIKDgoH
BAAEAQIBAhIDOBUWClMKBgQABAECAhIDOwQUGkQgVGhlIHNraWxsIGlzIGluIGRyYWZ0LCBv
ciBsYWNrcyBhIHZhbGlkIHBheWxvYWQuIEl0IGlzIG5vdCBzZXJ2ZWQuCgoOCgcEAAQBAgIB
EgM7BA8KDgoHBAAEAQICAhIDOxITCjMKBgQABAECAxIDPgQVGiQgVGhlIHNraWxsIGlzIGFj
dGl2ZSBhbmQgaXMgc2VydmVkLgoKDgoHBAAEAQIDARIDPgQQCg4KBwQABAECAwISAz4TFAo5
CgYEAAQBAgQSA0EEFxoqIFRoZSBza2lsbCBpcyBkaXNhYmxlZCBhbmQgaXMgbm90IHNlcnZl
ZC4KCg4KBwQABAECBAESA0EEEgoOCgcEAAQBAgQCEgNBFRYKSwoGBAAEAQIFEgNEBBkaPCBU
aGUgc2tpbGwgaXMgZGVwcmVjYXRlZC4gSXQgaXMgc2VydmVkLCBidXQgZW1pdHMgd2Fybmlu
Z3MuCgoOCgcEAAQBAgUBEgNEBBQKDgoHBAAEAQIFAhIDRBcYCj8KBgQABAECBhIDRwQdGjAg
VGhlIHNraWxsIGlzIGRlY29tbWlzc2lvbmVkIGFuZCBpcyBub3Qgc2VydmVkLgoKDgoHBAAE
AQIGARIDRwQYCg4KBwQABAECBgISA0cbHAo+CgYEAAQBAgcSA0oEFxovIFRoZSBza2lsbCBp
cyBiZWluZyBkZWxldGVkLiBJdCBpcyBub3Qgc2VydmVkLgoKDgoHBAAEAQIHARIDSgQSCg4K
BwQABAECBwISA0oVFgovCgQEAAQCEgROAmADGiEgVXNlci1jb25maWd1cmFibGUgdGFyZ2V0
IHN0YXRlLgoKDAoFBAAEAgESA04HEgo1CgYEAAQCAgASA1AEIRomIERlZmF1bHQgdmFsdWUu
IFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoHBAAEAgIAARIDUAQcCg4KBwQABAICAAISA1Af
IAo8CgYEAAQCAgESA1MEGxotIFRoZSBza2lsbCBpcyBpbiBkcmFmdCBhbmQgY2Fubm90IGJl
IHNlcnZlZC4KCg4KBwQABAICAQESA1MEFgoOCgcEAAQCAgECEgNTGRoKNwoGBAAEAgICEgNW
BBwaKCBUaGUgc2tpbGwgaXMgYWN0aXZlIGFuZCBjYW4gYmUgc2VydmVkLgoKDgoHBAAEAgIC
ARIDVgQXCg4KBwQABAICAgISA1YaGwo8CgYEAAQCAgMSA1kEHhotIFRoZSBza2lsbCBpcyBk
aXNhYmxlZCBhbmQgY2Fubm90IGJlIHNlcnZlZC4KCg4KBwQABAICAwESA1kEGQoOCgcEAAQC
AgMCEgNZHB0KVQoGBAAEAgIEEgNcBCAaRiBUaGUgc2tpbGwgaXMgZGVwcmVjYXRlZC4gSXQg
Y2FuIHN0aWxsIGJlIHNlcnZlZCwgYnV0IGVtaXRzIHdhcm5pbmdzLgoKDgoHBAAEAgIEARID
XAQbCg4KBwQABAICBAISA1weHwpCCgYEAAQCAgUSA18EJBozIFRoZSBza2lsbCBpcyBkZWNv
bW1pc3Npb25lZCBhbmQgY2Fubm90IGJlIHNlcnZlZC4KCg4KBwQABAICBQESA18EHwoOCgcE
AAQCAgUCEgNfIiMK2QIKBAQAAgASA2cCPRrLAiBJZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1l
IG9mIHRoZSBTa2lsbC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9za2lsbHMve3NraWxsfWAKIFRoZSBge3NraWxsfWAgc2VnbWVudCBhY3Rz
IGFzIHRoZSByZXNvdXJjZSBJRC4gSWYgdGhlIHNraWxsIGlzIGFzc29jaWF0ZWQKIHdpdGgg
YSBQdWJsaXNoZXIsIHRoaXMgc2VnbWVudCB0eXBpY2FsbHkgdXNlcyBhIGh5cGhlbmF0ZWQg
bmFtZXNwYWNlIHByZWZpeAogY29ycmVzcG9uZGluZyB0byB0aGUgcHVibGlzaGVyIChlLmcu
LCBgZ29vZ2xlLXdvcmtzcGFjZS1jcmVhdGUtZG9jc2ApLgoKDAoFBAACAAUSA2cCCAoMCgUE
AAIAARIDZwkNCgwKBQQAAgADEgNnEBEKDAoFBAACAAgSA2cSPAoPCggEAAIACJwIABIDZxM7
Cl4KBAQAAgESBGsCbgQaUCBPdXRwdXQgb25seS4gVW5pdmVyc2FsbHkgdW5pcXVlIGlkZW50
aWZpZXIgKFVVSUQ0KSBmb3IgdGhlIGxvZ2ljYWwKIGNvbnRhaW5lci4KCgwKBQQAAgEFEgNr
AggKDAoFBAACAQESA2sJDAoMCgUEAAIBAxIDaw8QCg0KBQQAAgEIEgRrEW4DChIKCwQAAgEI
zPH5igEBEgNsBCoKDwoIBAACAQicCAASA20ELQplCgQEAAICEgNyAkMaWCBPcHRpb25hbC4g
SHVtYW4tcmVhZGFibGUgZGlzcGxheSBuYW1lIG9mIHRoZSBza2lsbC4KIE1heGltdW0gbGVu
Z3RoIGlzIDEyOCBjaGFyYWN0ZXJzLgoKDAoFBAACAgUSA3ICCAoMCgUEAAICARIDcgkVCgwK
BQQAAgIDEgNyGBkKDAoFBAACAggSA3IaQgoPCggEAAICCJwIABIDchtBCnQKBAQAAgMSA3YC
QhpnIE9wdGlvbmFsLiBCcmllZiBzdW1tYXJ5IGRlc2NyaWJpbmcgdGhlIGNhcGFiaWxpdGll
cyBvZiB0aGUgc2tpbGwuCiBNYXhpbXVtIGxlbmd0aCBpcyAyMDQ4IGNoYXJhY3RlcnMuCgoM
CgUEAAIDBRIDdgIICgwKBQQAAgMBEgN2CRQKDAoFBAACAwMSA3YXGAoMCgUEAAIDCBIDdhlB
Cg8KCAQAAgMInAgAEgN2GkAKVgoEBAACBBIDeQI5GkkgUmVxdWlyZWQuIFN0cnVjdHVyYWwg
ZGVwbG95bWVudCB0eXBlIChTSU1QTEUgbGVhZiB2cyBDT01QT1NJVEUgYnVuZGxlKS4KCgwK
BQQAAgQGEgN5AgYKDAoFBAACBAESA3kHCwoMCgUEAAIEAxIDeQ4PCgwKBQQAAgQIEgN5EDgK
DwoIBAACBAicCAASA3kRNwpCCgQEAAIFEgN8Aj4aNSBPdXRwdXQgb25seS4gVGhlIHN5c3Rl
bS1tYW5hZ2VkIHN0YXRlIG9mIHRoZSBza2lsbC4KCgwKBQQAAgUGEgN8AgcKDAoFBAACBQES
A3wIDQoMCgUEAAIFAxIDfBARCgwKBQQAAgUIEgN8Ej0KDwoIBAACBQicCAASA3wTPApACgQE
AAIGEgN/AkgaMyBSZXF1aXJlZC4gVXNlci1tYW5hZ2VkIHRhcmdldCBzdGF0ZSBvZiB0aGUg
c2tpbGwuCgoMCgUEAAIGBhIDfwINCgwKBQQAAgYBEgN/DhoKDAoFBAACBgMSA38dHgoMCgUE
AAIGCBIDfx9HCg8KCAQAAgYInAgAEgN/IEYKygEKBAQAAgcSBoUBAooBBBq5ASBPcHRpb25h
bC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmV2aXNpb24gY3VycmVudGx5IHNl
cnZlZCBieQogZGVmYXVsdCAoZmxvYXRpbmcgdHJhY2spLgogRm9ybWF0OgogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9za2lsbHMve3NraWxsfS9yZXZpc2lv
bnMve3JldmlzaW9ufWAKCg0KBQQAAgcFEgSFAQIICg0KBQQAAgcBEgSFAQkZCg0KBQQAAgcD
EgSFARwdCg8KBQQAAgcIEgaFAR6KAQMKEAoIBAACBwicCAASBIYBBCoKEQoHBAACBwifCBIG
hwEEiQEFCmsKBAQAAggSBI4BAkoaXSBPdXRwdXQgb25seS4gTGlnaHR3ZWlnaHQgZnJvbnRt
YXR0ZXIgbWV0YWRhdGEgYXR0cmlidXRlcyBjb3BpZWQgZnJvbSB0aGUKIGRlZmF1bHQgcmV2
aXNpb24uCgoNCgUEAAIIBhIEjgECDQoNCgUEAAIIARIEjgEOGQoNCgUEAAIIAxIEjgEcHQoN
CgUEAAIICBIEjgEeSQoQCggEAAIICJwIABIEjgEfSAqsAwoEBAACCRIElgECQxqdAyBPdXRw
dXQgb25seS4gQSBzdGFibGUsIGdsb2JhbGx5IHVuaXF1ZSBsb2dpY2FsIGlkZW50aWZpZXIg
Zm9yIHRoZSBza2lsbC4KIEl0IGlzIHNlY3VyZWx5IGNvbnN0cnVjdGVkIGJ5IHRoZSBiYWNr
ZW5kIGJ5IGNvbWJpbmluZyB0aGUgYXNzb2NpYXRlZAogYHB1Ymxpc2hlcmAncyB2ZXJpZmll
ZCBuYW1lc3BhY2UgYW5kIHRoZSBza2lsbCdzIHJlc291cmNlIElEIHRvIGVuZm9yY2UKIHN0
cmljdCBvd25lcnNoaXAuIEZvciBleGFtcGxlLCB0aGUgcHJlZml4IGBnb29nbGUtYCBpcyBy
ZXNlcnZlZCBleGNsdXNpdmVseQogZm9yIGZpcnN0LXBhcnR5IEdvb2dsZSBwdWJsaXNoZXJz
IHRvIHByZXZlbnQgbmFtZXNwYWNlIHNxdWF0dGluZy4KIEV4YW1wbGU6IGB1cm46c2tpbGw6
Z29vZ2xlLXdvcmtzcGFjZTpjcmVhdGUtZG9jc2AKCg0KBQQAAgkFEgSWAQIICg0KBQQAAgkB
EgSWAQkRCg0KBQQAAgkDEgSWARQWCg0KBQQAAgkIEgSWARdCChAKCAQAAgkInAgAEgSWARhB
CisKBAQAAgoSBpkBApoBMhobIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZS4KCg0KBQQAAgoG
EgSZAQIbCg0KBQQAAgoBEgSZARwnCg0KBQQAAgoDEgSZASosCg0KBQQAAgoIEgSaAQYxChAK
CAQAAgoInAgAEgSaAQcwCisKBAQAAgsSBp0BAp4BMhobIE91dHB1dCBvbmx5LiBVcGRhdGUg
dGltZS4KCg0KBQQAAgsGEgSdAQIbCg0KBQQAAgsBEgSdARwnCg0KBQQAAgsDEgSdASosCg0K
BQQAAgsIEgSeAQYxChAKCAQAAgsInAgAEgSeAQcwCrsCCgQEAAIMEgalAQKqAQQaqgIgT3B0
aW9uYWwuIFRoZSBwdWJsaXNoZXIgcmVzb3VyY2UgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc2tp
bGwuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
cHVibGlzaGVycy97cHVibGlzaGVyfWAKIFRoZSBwdWJsaXNoZXIgZGljdGF0ZXMgdGhlIGFs
bG93ZWQgbmFtZXNwYWNlIHByZWZpeGVzIGZvciB0aGUgc2tpbGwncyBuYW1lCiBhbmQgbG9n
aWNhbCBgc2tpbGxfaWRgIChlLmcuLCBQdWJsaXNoZXIgYGdvb2dsZWAgYXV0aG9yaXplcyB0
aGUgYGdvb2dsZS0qYAogcHJlZml4KS4KCg0KBQQAAgwFEgSlAQIICg0KBQQAAgwBEgSlAQkS
Cg0KBQQAAgwDEgSlARUXCg8KBQQAAgwIEgalARiqAQMKEAoIBAACDAicCAASBKYBBCoKEQoH
BAACDAifCBIGpwEEqQEFCtoBCgQEAAINEgavAQKyAQQayQEgT3B0aW9uYWwuIElucHV0IG9u
bHkuIE9wdGlvbmFsIG5lc3RlZCBpbml0aWFsIHJldmlzaW9uIHBheWxvYWQgdG8gc3VwcG9y
dAogc3RhbmRhcmQgb25lLXNob3QgY3JlYXRpb24uIFRoZSBzZXJ2ZXIgcHJvY2Vzc2VzIHRo
aXMgZmllbGQgb24gaW5wdXQgZHVyaW5nCiBjcmVhdGlvbiBidXQgbXVzdCBuZXZlciByZXR1
cm4gaXQgaW4gcmVzcG9uc2VzLgoKDQoFBAACDQYSBK8BAg8KDQoFBAACDQESBK8BECAKDQoF
BAACDQMSBK8BIyUKDwoFBAACDQgSBq8BJrIBAwoQCggEAAINCJwIABIEsAEEKgoQCggEAAIN
CJwIARIEsQEELApJCgQEAAIOEgS1AQJPGjsgT3B0aW9uYWwuIE9wdGlvbmFsLiBTY2Fubmlu
ZyBjb25maWd1cmF0aW9uIGZvciB0aGUgc2tpbGwuCgoNCgUEAAIOBhIEtQECEAoNCgUEAAIO
ARIEtQERIAoNCgUEAAIOAxIEtQEjJQoNCgUEAAIOCBIEtQEmTgoQCggEAAIOCJwIABIEtQEn
TQo4CgIEARIGuQEAzgEBGiogQ29uZmlndXJhdGlvbiBmb3Igc2Nhbm5pbmcgb2YgdGhlIHNr
aWxsLgoKCwoDBAEBEgS5AQgWCn0KBAQBBAASBr0BAsoBAxptIERlZmluZXMgdGhlIHBvbGlj
eSBmb3Igc2VjdXJpdHkgc2Nhbm5pbmcuCgogVGhpcyBlbnVtIGlzIG5vdCBmcm96ZW47IG5l
dyB2YWx1ZXMgbWF5IGJlIGFkZGVkIGluIHRoZSBmdXR1cmUuCgoNCgUEAQQAARIEvQEHDQpM
CgYEAQQAAgASBL8BBBsaPCBEZWZhdWx0IHZhbHVlLiBJbmhlcml0cyBzeXN0ZW0gZGVmYXVs
dCAoRU5BQkxFRF9CTE9DS0lORykuCgoPCgcEAQQAAgABEgS/AQQWCg8KBwQBBAACAAISBL8B
GRoKJAoGBAEEAAIBEgTCAQQRGhQgQnlwYXNzZXMgc2Nhbm5pbmcuCgoPCgcEAQQAAgEBEgTC
AQQMCg8KBwQBBAACAQISBMIBDxAKZgoGBAEEAAICEgTGAQQZGlYgU2NhbnMgdGhlIHNraWxs
IHBhY2thZ2UgYW5kIGJsb2NrcyBkb3dubG9hZCBpZiBzZWN1cml0eSBvciBzYWZldHkgaXNz
dWVzCiBhcmUgZm91bmQuCgoPCgcEAQQAAgIBEgTGAQQUCg8KBwQBBAACAgISBMYBFxgKUwoG
BAEEAAIDEgTJAQQcGkMgU2NhbnMgdGhlIHNraWxsIHBhY2thZ2UgaW4gYXVkaXQgbW9kZSB3
aXRob3V0IGJsb2NraW5nIGRvd25sb2Fkcy4KCg8KBwQBBAACAwESBMkBBBcKDwoHBAEEAAID
AhIEyQEaGwo3CgQEAQIAEgTNAQI9GikgT3B0aW9uYWwuIFRoZSBzZWN1cml0eSBzY2Fubmlu
ZyBwb2xpY3kuCgoNCgUEAQIABhIEzQECCAoNCgUEAQIAARIEzQEJDwoNCgUEAQIAAxIEzQES
EwoNCgUEAQIACBIEzQEUPAoQCggEAQIACJwIABIEzQEVOwpoCgIEAhIG0gEA4gEBGlogU3Ry
dWN0dXJlZCBtZXRhZGF0YSBhdHRyaWJ1dGVzIGV4dHJhY3RlZCBmcm9tIHRoZSBwYWNrYWdl
J3MgbG9jYWwgU0tJTEwubWQKIGZyb250bWF0dGVyLgoKCwoDBAIBEgTSAQgTCjAKBAQCAgAS
BNQBAjsaIiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHNraWxsLgoKDQoFBAICAAUSBNQB
AggKDQoFBAICAAESBNQBCQ0KDQoFBAICAAMSBNQBEBEKDQoFBAICAAgSBNQBEjoKEAoIBAIC
AAicCAASBNQBEzkKMQoEBAICARIE1wECQhojIFJlcXVpcmVkLiBGdW5jdGlvbmFsIGRlc2Ny
aXB0aW9uLgoKDQoFBAICAQUSBNcBAggKDQoFBAICAQESBNcBCRQKDQoFBAICAQMSBNcBFxgK
DQoFBAICAQgSBNcBGUEKEAoIBAICAQicCAASBNcBGkAKIgoEBAICAhIE2gECPhoUIE9wdGlv
bmFsLiBMaWNlbnNlLgoKDQoFBAICAgUSBNoBAggKDQoFBAICAgESBNoBCRAKDQoFBAICAgMS
BNoBExQKDQoFBAICAggSBNoBFT0KEAoIBAICAgicCAASBNoBFjwKSwoEBAICAxIE3QECRBo9
IE9wdGlvbmFsLiBFbnZpcm9ubWVudGFsIGRlcGVuZGVuY2llcyBvciBjb21wYW5pb24gc2Vy
dmljZXMuCgoNCgUEAgIDBRIE3QECCAoNCgUEAgIDARIE3QEJFgoNCgUEAgIDAxIE3QEZGgoN
CgUEAgIDCBIE3QEbQwoQCggEAgIDCJwIABIE3QEcQgppCgQEAgIEEgThAQJMGlsgT3B0aW9u
YWwuIEV4dGVuc2libGUgZmxhdHRlbmVkIG1hcCBtYXBwaW5nIGN1c3RvbSB0YWdzLCBhdXRo
b3JzLCBhbmQKIHZlcnNpb24gcGFyYW1ldGVycy4KCg0KBQQCAgQGEgThAQIVCg0KBQQCAgQB
EgThARYeCg0KBQQCAgQDEgThASEiCg0KBQQCAgQIEgThASNLChAKCAQCAgQInAgAEgThASRK
Cj0KAgQDEgblAQDsAQEaLyBEaXJlY3Qgd3JpdGUtb25seSByYXcgYXJjaGl2ZSBwYXlsb2Fk
IHVwbG9hZC4KCgsKAwQDARIE5QEIGwpzCgQEAwIAEgboAQLrAQQaYyBSZXF1aXJlZC4gSW5w
dXQgb25seS4gV3JpdGUtb25seSByYXcgWklQL1RBUiBhcmNoaXZlIHBheWxvYWQgYnl0ZXMK
IGNvbnRhaW5pbmcgdGhlIHNraWxsIHBhY2thZ2UuCgoNCgUEAwIABRIE6AECBwoNCgUEAwIA
ARIE6AEIFwoNCgUEAwIAAxIE6AEaGwoPCgUEAwIACBIG6AEc6wEDChAKCAQDAgAInAgAEgTp
AQQqChAKCAQDAgAInAgBEgTqAQQsCk8KAgQEEgbvAQDsAgEaQSBSZXByZXNlbnRzIGFuIGlt
bXV0YWJsZSwgdmVyc2lvbmVkIHNuYXBzaG90IG9mIGEgU2tpbGwgcGFja2FnZS4KCgsKAwQE
ARIE7wEIFQoNCgMEBAcSBvABAvUBBAoPCgUEBAedCBIG8AEC9QEECjQKBAQEAwASBvgBAp8C
AxokIFNjYW4gcmVzdWx0IG9mIHRoZSBza2lsbCByZXZpc2lvbi4KCg0KBQQEAwABEgT4AQoU
Ck0KBgQEAwAEABIG+gEEjAIFGjsgUmVwcmVzZW50cyB0aGUgbGlmZWN5Y2xlIHN0YXRlIG9m
IHRoZSB2dWxuZXJhYmlsaXR5IHNjYW4uCgoPCgcEBAMABAABEgT6AQkSCicKCAQEAwAEAAIA
EgT8AQYhGhUgU2hvdWxkIG5vdCBiZSB1c2VkLgoKEQoJBAQDAAQAAgABEgT8AQYcChEKCQQE
AwAEAAIAAhIE/AEfIApOCggEBAMABAACARIE/wEGERo8IFRoZSB1bmRlcmx5aW5nIHNjYW5u
aW5nIHN5c3RlbSBmYWlsZWQgdG8gZXhlY3V0ZSB0aGUgc2Nhbi4KChEKCQQEAwAEAAIBARIE
/wEGDAoRCgkEBAMABAACAQISBP8BDxAKVwoIBAQDAAQAAgISBIICBh0aRSBUaGUgdXBsb2Fk
ZWQgYXJ0aWZhY3QgZm9ybWF0IGlzIHVuc3VwcG9ydGVkIGJ5IHRoZSBzY2FubmluZyBzeXN0
ZW0uCgoRCgkEBAMABAACAgESBIICBhgKEQoJBAQDAAQAAgICEgSCAhscCjgKCAQEAwAEAAID
EgSFAgYUGiYgVGhlIHNjYW4gaGFzIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuCgoRCgkEBAMA
BAACAwESBIUCBg8KEQoJBAQDAAQAAgMCEgSFAhITCioKCAQEAwAEAAIEEgSIAgYTGhggVGhl
IHNjYW4gd2FzIGRpc2FibGVkLgoKEQoJBAQDAAQAAgQBEgSIAgYOChEKCQQEAwAEAAIEAhIE
iAIREgooCggEBAMABAACBRIEiwIGEhoWIFRoZSBzY2FuIGlzIHJ1bm5pbmcuCgoRCgkEBAMA
BAACBQESBIsCBg0KEQoJBAQDAAQAAgUCEgSLAhARCkQKBgQEAwACABIEjwIESRo0IE91dHB1
dCBvbmx5LiBUaGUgc3RhdGUgb2YgdGhlIHZ1bG5lcmFiaWxpdHkgY2hlY2suCgoPCgcEBAMA
AgAGEgSPAgQNCg8KBwQEAwACAAESBI8CDhgKDwoHBAQDAAIAAxIEjwIbHAoPCgcEBAMAAgAI
EgSPAh1IChIKCgQEAwACAAicCAASBI8CHkcKRgoGBAQDAAIBEgaSAgSTAjQaNCBPdXRwdXQg
b25seS4gVGhlIHRpbWUgd2hlbiB0aGUgc2NhbiB3YXMgY29tcGxldGVkLgoKDwoHBAQDAAIB
BhIEkgIEHQoPCgcEBAMAAgEBEgSSAh4nCg8KBwQEAwACAQMSBJICKisKDwoHBAQDAAIBCBIE
kwIIMwoSCgoEBAMAAgEInAgAEgSTAgkyCkQKBgQEAwACAhIElgIESRo0IE91dHB1dCBvbmx5
LiBUaGUgZXJyb3IgbWVzc2FnZSBpZiB0aGUgc2NhbiBmYWlsZWQuCgoPCgcEBAMAAgIFEgSW
AgQKCg8KBwQEAwACAgESBJYCCxgKDwoHBAQDAAICAxIElgIbHAoPCgcEBAMAAgIIEgSWAh1I
ChIKCgQEAwACAgicCAASBJYCHkcKUwoGBAQDAAIDEgaZAgSeAgYaQSBPdXRwdXQgb25seS4g
VGhlIGZpbmRpbmcgcmVzb3VyY2UgbmFtZXMgZm9yIHRoZSBza2lsbCByZXZpc2lvbi4KCg8K
BwQEAwACAwQSBJkCBAwKDwoHBAQDAAIDBRIEmQINEwoPCgcEBAMAAgMBEgSZAhQcCg8KBwQE
AwACAwMSBJkCHyAKEQoHBAQDAAIDCBIGmQIhngIFChIKCgQEAwACAwicCAASBJoCBi8KEwoJ
BAQDAAIDCJ8IEgabAgadAgcKMAoEBAQEABIGogICsQIDGiAgU3lzdGVtLW1hbmFnZWQgY29t
cHV0ZWQgc3RhdGUuCgoNCgUEBAQAARIEogIHDAo2CgYEBAQAAgASBKQCBBoaJiBEZWZhdWx0
IHZhbHVlLiBUaGlzIHZhbHVlIGlzIHVudXNlZC4KCg8KBwQEBAACAAESBKQCBBUKDwoHBAQE
AAIAAhIEpAIYGQowCgYEBAQAAgESBKcCBBEaICBUaGUgcmV2aXNpb24gaXMgYmVpbmcgY3Jl
YXRlZC4KCg8KBwQEBAACAQESBKcCBAwKDwoHBAQEAAIBAhIEpwIPEAopCgYEBAQAAgISBKoC
BA8aGSBUaGUgcmV2aXNpb24gaXMgYWN0aXZlLgoKDwoHBAQEAAICARIEqgIECgoPCgcEBAQA
AgICEgSqAg0OCjsKBgQEBAACAxIErQIEDxorIFRoZSByZXZpc2lvbiBmYWlsZWQgdG8gY29t
cGlsZSBvciBpbmdlc3QuCgoPCgcEBAQAAgMBEgStAgQKCg8KBwQEBAACAwISBK0CDQ4KMAoG
BAQEAAIEEgSwAgQRGiAgVGhlIHJldmlzaW9uIGlzIGJlaW5nIGRlbGV0ZWQuCgoPCgcEBAQA
AgQBEgSwAgQMCg8KBwQEBAACBAISBLACDxAKoAQKBAQECAASBr8CAssCAxqPBCBPdXRwdXQg
b25seS4gVGhlIHN0b3JhZ2UgbG9jYXRpb24gcG9pbnRlci4KIEluIHN0YW5kYXJkIGxpc3Rp
bmcsIHRoZSByYXcgemlwIGJ5dGVzIGFyZSBjb21wbGV0ZWx5IGV4Y2x1ZGVkLgogVGhleSBh
cmUgc3RyZWFtZWQgc2VwYXJhdGVseSB2aWEgYSBkZWRpY2F0ZWQgR2V0U2tpbGxSZXZpc2lv
biByZXF1ZXN0IHdpdGgKIGA/YWx0PW1lZGlhYC4KIFRoZSBwaHlzaWNhbCBzb3VyY2UgcG9p
bnRpbmcgdG8gdGhlIGV4ZWN1dGFibGUgcGF5bG9hZC4KIEV4YWN0bHkgb25lIHNvdXJjZSBt
dXN0IGJlIHByb3ZpZGVkIGR1cmluZyBjcmVhdGlvbjsgb3RoZXJ3aXNlLCB0aGUKIHNlcnZl
ciB3aWxsIHJldHVybiBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IuCgogU2l6ZSBjb25z
dHJhaW50czoKIC0gTWF4aW11bSBjb21wcmVzc2VkIFpJUCBzaXplOiA1MDAgS0IKIC0gTWF4
aW11bSB0b3RhbCB1bmNvbXByZXNzZWQgc2l6ZTogMTAgTUIKIC0gTWF4aW11bSBpbmRpdmlk
dWFsIHVuY29tcHJlc3NlZCBmaWxlIHNpemU6IDEgTUIKCg0KBQQECAABEgS/AggOCksKBAQE
AgASBsECBMQCBho7IE9wdGlvbmFsLiBJbW11dGFibGUuIENsb3VkIFN0b3JhZ2Ugb2JqZWN0
IGdlbmVyYXRpb24gVVJJLgoKDQoFBAQCAAYSBMECBA0KDQoFBAQCAAESBMECDhgKDQoFBAQC
AAMSBMECGxwKDwoFBAQCAAgSBsECHcQCBQoQCggEBAIACJwIABIEwgIGLQoQCggEBAIACJwI
ARIEwwIGLApTCgQEBAIBEgbHAgTKAgYaQyBPcHRpb25hbC4gSW1tdXRhYmxlLiBEaXJlY3Qg
d3JpdGUtb25seSByYXcgYXJjaGl2ZSB1cGxvYWQgc291cmNlLgoKDQoFBAQCAQYSBMcCBBcK
DQoFBAQCAQESBMcCGC0KDQoFBAQCAQMSBMcCMDIKDwoFBAQCAQgSBscCM8oCBQoQCggEBAIB
CJwIABIEyAIGLQoQCggEBAIBCJwIARIEyQIGLAqYAQoEBAQCAhIE0AICPRqJASBJZGVudGlm
aWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBTa2lsbFJldmlzaW9uLgogRm9ybWF0OgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9za2lsbHMve3NraWxsfS9y
ZXZpc2lvbnMve3JldmlzaW9ufWAKCg0KBQQEAgIFEgTQAgIICg0KBQQEAgIBEgTQAgkNCg0K
BQQEAgIDEgTQAhARCg0KBQQEAgIIEgTQAhI8ChAKCAQEAgIInAgAEgTQAhM7ClEKBAQEAgMS
BNMCAj4aQyBPdXRwdXQgb25seS4gVGhlIHN5c3RlbS1tYW5hZ2VkIGxpZmVjeWNsZSBzdGF0
ZSBvZiB0aGlzIHJldmlzaW9uLgoKDQoFBAQCAwYSBNMCAgcKDQoFBAQCAwESBNMCCA0KDQoF
BAQCAwMSBNMCEBEKDQoFBAQCAwgSBNMCEj0KEAoIBAQCAwicCAASBNMCEzwKagoEBAQCBBIE
1wICRRpcIE91dHB1dCBvbmx5LiBDcnlwdG9ncmFwaGljIFNIQS0yNTYgaW50ZWdyaXR5IGFu
ZCBkZWR1cGxpY2F0aW9uIGRpZ2VzdCBvZgogdGhlIHBheWxvYWQgemlwLgoKDQoFBAQCBAUS
BNcCAggKDQoFBAQCBAESBNcCCRQKDQoFBAQCBAMSBNcCFxgKDQoFBAQCBAgSBNcCGUQKEAoI
BAQCBAicCAASBNcCGkMKTwoEBAQCBRIE2gICShpBIE91dHB1dCBvbmx5LiBFeHRyYWN0ZWQg
WUFNTCBmcm9udG1hdHRlciBjb25maWd1cmF0aW9uIHNuYXBzaG90LgoKDQoFBAQCBQYSBNoC
Ag0KDQoFBAQCBQESBNoCDhkKDQoFBAQCBQMSBNoCHB0KDQoFBAQCBQgSBNoCHkkKEAoIBAQC
BQicCAASBNoCH0gKOwoEBAQCBhIG3QIC3gIyGisgT3V0cHV0IG9ubHkuIFJldmlzaW9uIGNy
ZWF0aW9uIHRpbWVzdGFtcC4KCg0KBQQEAgYGEgTdAgIbCg0KBQQEAgYBEgTdAhwnCg0KBQQE
AgYDEgTdAiorCg0KBQQEAgYIEgTeAgYxChAKCAQEAgYInAgAEgTeAgcwCmsKBAQEAgcSBOIC
AkQaXSBPdXRwdXQgb25seS4gU2l6ZSBvZiB0aGUgY29tcGlsZWQgemlwIHBheWxvYWQgaW4g
Ynl0ZXMgKGFzc2lzdHMgY2xpZW50CiBkb3dubG9hZCBwcm9ncmVzcykuCgoNCgUEBAIHBRIE
4gICBwoNCgUEBAIHARIE4gIIEgoNCgUEBAIHAxIE4gIVFwoNCgUEBAIHCBIE4gIYQwoQCggE
BAIHCJwIABIE4gIZQgpcCgQEBAIIEgblAgLoAgQaTCBPdXRwdXQgb25seS4gVW5pdmVyc2Fs
bHkgdW5pcXVlIGlkZW50aWZpZXIgKFVVSUQ0KSBmb3IgdGhlIHNraWxsIHJldmlzaW9uLgoK
DQoFBAQCCAUSBOUCAggKDQoFBAQCCAESBOUCCQwKDQoFBAQCCAMSBOUCDxEKDwoFBAQCCAgS
BuUCEugCAwoTCgsEBAIICMzx+YoBARIE5gIEKgoQCggEBAIICJwIABIE5wIELQo/CgQEBAIJ
EgTrAgJKGjEgT3V0cHV0IG9ubHkuIFNjYW4gcmVzdWx0IG9mIHRoZSBza2lsbCByZXZpc2lv
bi4KCg0KBQQEAgkGEgTrAgIMCg0KBQQEAgkBEgTrAg0YCg0KBQQEAgkDEgTrAhsdCg0KBQQE
AgkIEgTrAh5JChAKCAQEAgkInAgAEgTrAh9ICjkKAgQFEgbvAgD4AgEaKyBTcGVjaWZpY2F0
aW9ucyBmb3IgQ2xvdWQgU3RvcmFnZSBvYmplY3RzLgoKCwoDBAUBEgTvAggRCmAKBAQFAgAS
BPMCAjoaUiBSZXF1aXJlZC4gQ2xvdWQgU3RvcmFnZSBvYmplY3QgVVJJLgogRm9ybWF0Ogog
YGdzOi8ve2J1Y2tldF9uYW1lfS97b2JqZWN0X25hbWV9YAoKDQoFBAUCAAUSBPMCAggKDQoF
BAUCAAESBPMCCQwKDQoFBAUCAAMSBPMCDxAKDQoFBAUCAAgSBPMCETkKEAoIBAUCAAicCAAS
BPMCEjgKbwoEBAUCARIE9wICQBphIE9wdGlvbmFsLiBDbG91ZCBTdG9yYWdlIG9iamVjdCBn
ZW5lcmF0aW9uIElELiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgbGF0ZXN0CiBnZW5lcmF0aW9u
IGlzIHVzZWQuCgoNCgUEBQIBBRIE9wICBwoNCgUEBQIBARIE9wIIEgoNCgUEBQIBAxIE9wIV
FgoNCgUEBQIBCBIE9wIXPwoQCggEBQIBCJwIABIE9wIYPgqiAQoCBAYSBv0CAKkDARqTASBS
ZXByZXNlbnRzIGEgdmVyaWZpZWQgUHVibGlzaGVyIG9mIFNraWxscy4KIFByZXBvcHVsYXRl
ZCBwdWJsaXNoZXJzIGluY2x1ZGUgYHB1Ymxpc2hlcnMvY2xvdWQuZ29vZ2xlLmNvbWAgYW5k
CiBgcHVibGlzaGVycy93b3Jrc3BhY2UuZ29vZ2xlLmNvbWAuCgoLCgMEBgESBP0CCBEKDQoD
BAYHEgb+AgKDAwQKDwoFBAYHnQgSBv4CAoMDBApTCgQEBgQAEgaGAwKSAwMaQyBDdXJhdGlv
biB0aWVyIHJlcHJlc2VudGluZyB0aGUgcHVibGlzaGVyJ3MgbGV2ZWwgb2YgdmVyaWZpY2F0
aW9uLgoKDQoFBAYEAAESBIYDBxQKLQoGBAYEAAIAEgSIAwQjGh0gRGVmYXVsdCB2YWx1ZS4g
VW5zcGVjaWZpZWQuCgoPCgcEBgQAAgABEgSIAwQeCg8KBwQGBAACAAISBIgDISIKTAoGBAYE
AAIBEgSLAwQUGjwgRmlyc3QtcGFydHkgR29vZ2xlLWN1cmF0ZWQgYW5kIHZlcmlmaWVkIGds
b2JhbCBwdWJsaXNoZXJzLgoKDwoHBAYEAAIBARIEiwMEDwoPCgcEBgQAAgECEgSLAxITCkUK
BgQGBAACAhIEjgMEFBo1IFRoaXJkLXBhcnR5IHZlcmlmaWVkIGVudGVycHJpc2UgcGFydG5l
ciBwdWJsaXNoZXJzLgoKDwoHBAYEAAICARIEjgMEDwoPCgcEBgQAAgICEgSOAxITCk4KBgQG
BAACAxIEkQMEEBo+IFByaXZhdGUgcHVibGlzaGVycyB3aXRoaW4gdGhlIGRldmVsb3Blcidz
IHdvcmtzcGFjZS9wcm9qZWN0LgoKDwoHBAYEAAIDARIEkQMECwoPCgcEBgQAAgMCEgSRAw4P
CoUBCgQEBgIAEgSWAwI9GncgSWRlbnRpZmllci4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgcHVi
bGlzaGVyLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3B1Ymxpc2hlcnMve3B1Ymxpc2hlcn1gCgoNCgUEBgIABRIElgMCCAoNCgUEBgIAARIE
lgMJDQoNCgUEBgIAAxIElgMQEQoNCgUEBgIACBIElgMSPAoQCggEBgIACJwIABIElgMTOwr2
AQoEBAYCARIEnAMCRhrnASBSZXF1aXJlZC4gVGhlIHZlcmlmaWVkIHByZWZpeCAoZS5nLiAi
c25vd2ZsYWtlLSIsICJnb29nbGUtIikgYXNzb2NpYXRlZAogd2l0aCB0aGlzIHB1Ymxpc2hl
ci4gVGhlIHN5c3RlbSB1c2VzIHRoaXMgcHJlZml4IHRvIGVuZm9yY2UgbmFtZS1zcXVhdHRp
bmcKIHJ1bGVzIGR1cmluZyBTa2lsbCByZWdpc3RyYXRpb24uIE11c3QgYmUgZ2xvYmFsbHkg
dW5pcXVlIGFjcm9zcyBhbGwKIHB1Ymxpc2hlcnMuCgoNCgUEBgIBBRIEnAMCCAoNCgUEBgIB
ARIEnAMJGAoNCgUEBgIBAxIEnAMbHAoNCgUEBgIBCBIEnAMdRQoQCggEBgIBCJwIABIEnAMe
RApHCgQEBgICEgSfAwJDGjkgT3B0aW9uYWwuIEh1bWFuIHJlYWRhYmxlIGRpc3BsYXkgbmFt
ZSBvZiB0aGUgcHVibGlzaGVyLgoKDQoFBAYCAgUSBJ8DAggKDQoFBAYCAgESBJ8DCRUKDQoF
BAYCAgMSBJ8DGBkKDQoFBAYCAggSBJ8DGkIKEAoIBAYCAgicCAASBJ8DG0EKQAoEBAYCAxIE
ogMCTxoyIE91dHB1dCBvbmx5LiBUaGUgY3VyYXRpb24gdGllciBvZiB0aGUgcHVibGlzaGVy
LgoKDQoFBAYCAwYSBKIDAg8KDQoFBAYCAwESBKIDEB4KDQoFBAYCAwMSBKIDISIKDQoFBAYC
AwgSBKIDI04KEAoIBAYCAwicCAASBKIDJE0KSwoEBAYCBBIEpQMCSBo9IE9wdGlvbmFsLiBV
UkkgcG9pbnRpbmcgdG8gb2ZmaWNpYWwgcHVibGlzaGVyIGRvY3VtZW50YXRpb24uCgoNCgUE
BgIEBRIEpQMCCAoNCgUEBgIEARIEpQMJGgoNCgUEBgIEAxIEpQMdHgoNCgUEBgIECBIEpQMf
RwoQCggEBgIECJwIABIEpQMgRgpGCgQEBgIFEgSoAwJCGjggT3B0aW9uYWwuIFVSSSBwb2lu
dGluZyB0byB0aGUgc3VwcG9ydCBwb3J0YWwgb3IgZW1haWwuCgoNCgUEBgIFBRIEqAMCCAoN
CgUEBgIFARIEqAMJFAoNCgUEBgIFAxIEqAMXGAoNCgUEBgIFCBIEqAMZQQoQCggEBgIFCJwI
ABIEqAMaQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Skill::Skill ===
    # Fields for Skill
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: type Type: 14 (.google.cloud.agentregistry.v1.Skill.Type)
    # Field: state Type: 14 (.google.cloud.agentregistry.v1.Skill.State)
    # Field: target_state Type: 14 (.google.cloud.agentregistry.v1.Skill.TargetState)
    # Field: default_revision Type: 9 ()
    # Field: frontmatter Type: 11 (.google.cloud.agentregistry.v1.Frontmatter)
    # Field: skill_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: publisher Type: 9 ()
    # Field: initial_revision Type: 11 (.google.cloud.agentregistry.v1.SkillRevision)
    # Field: scanning_config Type: 11 (.google.cloud.agentregistry.v1.ScanningConfig)

# Enum: Skill::Type
our $Skill_TYPE_UNSPECIFIED = 0;
our $Skill_SIMPLE = 1;

# Enum: Skill::State
our $Skill_STATE_UNSPECIFIED = 0;
our $Skill_STATE_CREATING = 1;
our $Skill_STATE_DRAFT = 2;
our $Skill_STATE_ACTIVE = 3;
our $Skill_STATE_DISABLED = 4;
our $Skill_STATE_DEPRECATED = 5;
our $Skill_STATE_DECOMMISSIONED = 6;
our $Skill_STATE_DELETING = 7;

# Enum: Skill::TargetState
our $Skill_TARGET_STATE_UNSPECIFIED = 0;
our $Skill_TARGET_STATE_DRAFT = 1;
our $Skill_TARGET_STATE_ACTIVE = 2;
our $Skill_TARGET_STATE_DISABLED = 3;
our $Skill_TARGET_STATE_DEPRECATED = 4;
our $Skill_TARGET_STATE_DECOMMISSIONED = 5;

# === Message: Google::Cloud::Agentregistry::V1::Skill::ScanningConfig ===
    # Fields for ScanningConfig
    # Field: policy Type: 14 (.google.cloud.agentregistry.v1.ScanningConfig.Policy)

# Enum: ScanningConfig::Policy
our $ScanningConfig_POLICY_UNSPECIFIED = 0;
our $ScanningConfig_DISABLED = 1;
our $ScanningConfig_ENABLED_BLOCKING = 2;
our $ScanningConfig_ENABLED_NONBLOCKING = 3;

# === Message: Google::Cloud::Agentregistry::V1::Skill::Frontmatter ===
    # Fields for Frontmatter
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: license Type: 9 ()
    # Field: compatibility Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.agentregistry.v1.Frontmatter.MetadataEntry)

# === Message: Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource ===
    # Fields for ArchiveUploadSource
    # Field: archive_content Type: 12 ()

# === Message: Google::Cloud::Agentregistry::V1::Skill::SkillRevision ===
    # Fields for SkillRevision
    # Field: gcs_source Type: 11 (.google.cloud.agentregistry.v1.GcsSource)
    # Field: archive_upload_source Type: 11 (.google.cloud.agentregistry.v1.ArchiveUploadSource)
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.agentregistry.v1.SkillRevision.State)
    # Field: sha256_hash Type: 9 ()
    # Field: frontmatter Type: 11 (.google.cloud.agentregistry.v1.Frontmatter)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: size_bytes Type: 3 ()
    # Field: uid Type: 9 ()
    # Field: scan_result Type: 11 (.google.cloud.agentregistry.v1.SkillRevision.ScanResult)

# Enum: SkillRevision::State
our $SkillRevision_STATE_UNSPECIFIED = 0;
our $SkillRevision_CREATING = 1;
our $SkillRevision_ACTIVE = 2;
our $SkillRevision_FAILED = 3;
our $SkillRevision_DELETING = 4;

# === Message: Google::Cloud::Agentregistry::V1::Skill::GcsSource ===
    # Fields for GcsSource
    # Field: uri Type: 9 ()
    # Field: generation Type: 3 ()

# === Message: Google::Cloud::Agentregistry::V1::Skill::Publisher ===
    # Fields for Publisher
    # Field: name Type: 9 ()
    # Field: verified_prefix Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: publisher_tier Type: 14 (.google.cloud.agentregistry.v1.Publisher.PublisherTier)
    # Field: documentation_uri Type: 9 ()
    # Field: support_uri Type: 9 ()

# Enum: Publisher::PublisherTier
our $Publisher_PUBLISHER_TIER_UNSPECIFIED = 0;
our $Publisher_FIRST_PARTY = 1;
our $Publisher_THIRD_PARTY = 2;
our $Publisher_PRIVATE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Skill - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/skill.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Skill;

    my $msg = Google::Cloud::Agentregistry::V1::Skill::Skill->new({
        name => $name,
        uid => $uid,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Skill::Skill->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/skill.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Skill::Skill

Represents an Executable Agent Skill or a Composite Tool Suite (Bundle).
Sibling resource with Agent and McpServer under agentregistry.googleapis.com.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the Skill.
Format: `projects/{project}/locations/{location}/skills/{skill}`
The `{skill}` segment acts as the resource ID. If the skill is associated
with a Publisher, this segment typically uses a hyphenated namespace prefix
corresponding to the publisher (e.g., `google-workspace-create-docs`).

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Universally unique identifier (UUID4) for the logical
container.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Human-readable display name of the skill.
Maximum length is 128 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Brief summary describing the capabilities of the skill.
Maximum length is 2048 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Skill::Type>)

Required. Structural deployment type (SIMPLE leaf vs COMPOSITE bundle).

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Skill::State>)

Output only. The system-managed state of the skill.

=item * C<< $msg->target_state() >> / C<< $msg->target_state($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Skill::TargetState>)

Required. User-managed target state of the skill.

=item * C<< $msg->default_revision() >> / C<< $msg->default_revision($value) >>

Type: C<String>

Optional. The full resource name of the revision currently served by
default (floating track).
Format:
`projects/{project}/locations/{location}/skills/{skill}/revisions/{revision}`

=item * C<< $msg->frontmatter() >> / C<< $msg->frontmatter($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::Frontmatter>)

Output only. Lightweight frontmatter metadata attributes copied from the
default revision.

=item * C<< $msg->skill_id() >> / C<< $msg->skill_id($value) >>

Type: C<String>

Output only. A stable, globally unique logical identifier for the skill.
It is securely constructed by the backend by combining the associated
`publisher`'s verified namespace and the skill's resource ID to enforce
strict ownership. For example, the prefix `google-` is reserved exclusively
for first-party Google publishers to prevent namespace squatting.
Example: `urn:skill:google-workspace:create-docs`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->publisher() >> / C<< $msg->publisher($value) >>

Type: C<String>

Optional. The publisher resource associated with this skill.
Format: `projects/{project}/locations/{location}/publishers/{publisher}`
The publisher dictates the allowed namespace prefixes for the skill's name
and logical `skill_id` (e.g., Publisher `google` authorizes the `google-*`
prefix).

=item * C<< $msg->initial_revision() >> / C<< $msg->initial_revision($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::SkillRevision>)

Optional. Input only. Optional nested initial revision payload to support
standard one-shot creation. The server processes this field on input during
creation but must never return it in responses.

=item * C<< $msg->scanning_config() >> / C<< $msg->scanning_config($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::ScanningConfig>)

Optional. Optional. Scanning configuration for the skill.

=back

=head3 Enum: Skill::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<SIMPLE> => C<1>

=back

=head3 Enum: Skill::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STATE_CREATING> => C<1>

=item * C<STATE_DRAFT> => C<2>

=item * C<STATE_ACTIVE> => C<3>

=item * C<STATE_DISABLED> => C<4>

=item * C<STATE_DEPRECATED> => C<5>

=item * C<STATE_DECOMMISSIONED> => C<6>

=item * C<STATE_DELETING> => C<7>

=back

=head3 Enum: Skill::TargetState

=over 4

=item * C<TARGET_STATE_UNSPECIFIED> => C<0>

=item * C<TARGET_STATE_DRAFT> => C<1>

=item * C<TARGET_STATE_ACTIVE> => C<2>

=item * C<TARGET_STATE_DISABLED> => C<3>

=item * C<TARGET_STATE_DEPRECATED> => C<4>

=item * C<TARGET_STATE_DECOMMISSIONED> => C<5>

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::ScanningConfig

Configuration for scanning of the skill.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy() >> / C<< $msg->policy($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::ScanningConfig::Policy>)

Optional. The security scanning policy.

=back

=head3 Enum: ScanningConfig::Policy

=over 4

=item * C<POLICY_UNSPECIFIED> => C<0>

=item * C<DISABLED> => C<1>

=item * C<ENABLED_BLOCKING> => C<2>

=item * C<ENABLED_NONBLOCKING> => C<3>

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::Frontmatter

Structured metadata attributes extracted from the package's local SKILL.md
frontmatter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the skill.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. Functional description.

=item * C<< $msg->license() >> / C<< $msg->license($value) >>

Type: C<String>

Optional. License.

=item * C<< $msg->compatibility() >> / C<< $msg->compatibility($value) >>

Type: C<String>

Optional. Environmental dependencies or companion services.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::Frontmatter::MetadataEntry>)

Optional. Extensible flattened map mapping custom tags, authors, and
version parameters.

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource

Direct write-only raw archive payload upload.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->archive_content() >> / C<< $msg->archive_content($value) >>

Type: C<Bytes>

Required. Input only. Write-only raw ZIP/TAR archive payload bytes
containing the skill package.

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::SkillRevision

Represents an immutable, versioned snapshot of a Skill package.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_source() >> / C<< $msg->gcs_source($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::GcsSource>)

Optional. Immutable. Cloud Storage object generation URI.

=item * C<< $msg->archive_upload_source() >> / C<< $msg->archive_upload_source($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource>)

Optional. Immutable. Direct write-only raw archive upload source.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the SkillRevision.
Format:
`projects/{project}/locations/{location}/skills/{skill}/revisions/{revision}`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::SkillRevision::State>)

Output only. The system-managed lifecycle state of this revision.

=item * C<< $msg->sha256_hash() >> / C<< $msg->sha256_hash($value) >>

Type: C<String>

Output only. Cryptographic SHA-256 integrity and deduplication digest of
the payload zip.

=item * C<< $msg->frontmatter() >> / C<< $msg->frontmatter($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::Frontmatter>)

Output only. Extracted YAML frontmatter configuration snapshot.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Revision creation timestamp.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

Output only. Size of the compiled zip payload in bytes (assists client
download progress).

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Universally unique identifier (UUID4) for the skill revision.

=item * C<< $msg->scan_result() >> / C<< $msg->scan_result($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Skill::SkillRevision::ScanResult>)

Output only. Scan result of the skill revision.

=back

=head3 Enum: SkillRevision::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<FAILED> => C<3>

=item * C<DELETING> => C<4>

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::GcsSource

Specifications for Cloud Storage objects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Required. Cloud Storage object URI.
Format:
`gs://{bucket_name}/{object_name}`

=item * C<< $msg->generation() >> / C<< $msg->generation($value) >>

Type: C<Int64>

Optional. Cloud Storage object generation ID. If not specified, the latest
generation is used.

=back

=head2 Google::Cloud::Agentregistry::V1::Skill::Publisher

Represents a verified Publisher of Skills.
Prepopulated publishers include `publishers/cloud.google.com` and
`publishers/workspace.google.com`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the publisher.
Format: `projects/{project}/locations/{location}/publishers/{publisher}`

=item * C<< $msg->verified_prefix() >> / C<< $msg->verified_prefix($value) >>

Type: C<String>

Required. The verified prefix (e.g. "snowflake-", "google-") associated
with this publisher. The system uses this prefix to enforce name-squatting
rules during Skill registration. Must be globally unique across all
publishers.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Human readable display name of the publisher.

=item * C<< $msg->publisher_tier() >> / C<< $msg->publisher_tier($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Publisher::PublisherTier>)

Output only. The curation tier of the publisher.

=item * C<< $msg->documentation_uri() >> / C<< $msg->documentation_uri($value) >>

Type: C<String>

Optional. URI pointing to official publisher documentation.

=item * C<< $msg->support_uri() >> / C<< $msg->support_uri($value) >>

Type: C<String>

Optional. URI pointing to the support portal or email.

=back

=head3 Enum: Publisher::PublisherTier

=over 4

=item * C<PUBLISHER_TIER_UNSPECIFIED> => C<0>

=item * C<FIRST_PARTY> => C<1>

=item * C<THIRD_PARTY> => C<2>

=item * C<PRIVATE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Skill::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
