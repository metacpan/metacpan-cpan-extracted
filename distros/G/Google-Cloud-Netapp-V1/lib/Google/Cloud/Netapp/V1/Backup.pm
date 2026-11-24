package Google::Cloud::Netapp::V1::Backup;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvbmV0YXBwL3YxL2JhY2t1cC5wcm90bxIWZ29vZ2xlLmNsb3VkLm5l
dGFwcC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i/AoKBkJhY2t1cBIXCgRuYW1lGAEgASgJQgPg
QQhSBG5hbWUSPwoFc3RhdGUYAiABKA4yJC5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1
cC5TdGF0ZUID4EEDUgVzdGF0ZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24S
MQoSdm9sdW1lX3VzYWdlX2J5dGVzGAQgASgDQgPgQQNSEHZvbHVtZVVzYWdlQnl0ZXMSSQoL
YmFja3VwX3R5cGUYBSABKA4yIy5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cC5UeXBl
QgPgQQNSCmJhY2t1cFR5cGUSRgoNc291cmNlX3ZvbHVtZRgGIAEoCUIh+kEeChxuZXRhcHAu
Z29vZ2xlYXBpcy5jb20vVm9sdW1lUgxzb3VyY2VWb2x1bWUSUQoPc291cmNlX3NuYXBzaG90
GAcgASgJQiP6QSAKHm5ldGFwcC5nb29nbGVhcGlzLmNvbS9TbmFwc2hvdEgAUg5zb3VyY2VT
bmFwc2hvdIgBARJACgtjcmVhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKY3JlYXRlVGltZRJCCgZsYWJlbHMYCSADKAsyKi5nb29nbGUuY2xvdWQu
bmV0YXBwLnYxLkJhY2t1cC5MYWJlbHNFbnRyeVIGbGFiZWxzEjMKE2NoYWluX3N0b3JhZ2Vf
Ynl0ZXMYCiABKANCA+BBA1IRY2hhaW5TdG9yYWdlQnl0ZXMSKAoNc2F0aXNmaWVzX3B6cxgL
IAEoCEID4EEDUgxzYXRpc2ZpZXNQenMSKAoNc2F0aXNmaWVzX3B6aRgMIAEoCEID4EEDUgxz
YXRpc2ZpZXNQemkSTgoNdm9sdW1lX3JlZ2lvbhgNIAEoCUIp4EED+kEjCiFsb2NhdGlvbnMu
Z29vZ2xlYXBpcy5jb20vTG9jYXRpb25SDHZvbHVtZVJlZ2lvbhJOCg1iYWNrdXBfcmVnaW9u
GA4gASgJQingQQP6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIMYmFj
a3VwUmVnaW9uEl4KG2VuZm9yY2VkX3JldGVudGlvbl9lbmRfdGltZRgPIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IYZW5mb3JjZWRSZXRlbnRpb25FbmRUaW1lEksK
DG9udGFwX3NvdXJjZRgQIAEoCzIjLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuT250YXBTb3Vy
Y2VCA+BBAVILb250YXBTb3VyY2UaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJtCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEgwKCENSRUFUSU5HEAESDQoJVVBMT0FESU5HEAISCQoFUkVBRFkQAxIMCghERUxFVElO
RxAEEgkKBUVSUk9SEAUSDAoIVVBEQVRJTkcQBiI3CgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJ
RUQQABIKCgZNQU5VQUwQARINCglTQ0hFRFVMRUQQAjqJAepBhQEKHG5ldGFwcC5nb29nbGVh
cGlzLmNvbS9CYWNrdXASVHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9iYWNrdXBWYXVsdHMve2JhY2t1cF92YXVsdH0vYmFja3Vwcy97YmFja3VwfSoHYmFja3Vw
czIGYmFja3VwQhIKEF9zb3VyY2Vfc25hcHNob3QiwQEKEkxpc3RCYWNrdXBzUmVxdWVzdBI8
CgZwYXJlbnQYASABKAlCJOBBAvpBHhIcbmV0YXBwLmdvb2dsZWFwaXMuY29tL0JhY2t1cFIG
cGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEo
CVIJcGFnZVRva2VuEhkKCG9yZGVyX2J5GAQgASgJUgdvcmRlckJ5EhYKBmZpbHRlchgFIAEo
CVIGZmlsdGVyIpkBChNMaXN0QmFja3Vwc1Jlc3BvbnNlEjgKB2JhY2t1cHMYASADKAsyHi5n
b29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cFIHYmFja3VwcxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hh
YmxlIkwKEEdldEJhY2t1cFJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxuZXRhcHAu
Z29vZ2xlYXBpcy5jb20vQmFja3VwUgRuYW1lIrIBChNDcmVhdGVCYWNrdXBSZXF1ZXN0EjwK
BnBhcmVudBgBIAEoCUIk4EEC+kEeEhxuZXRhcHAuZ29vZ2xlYXBpcy5jb20vQmFja3VwUgZw
YXJlbnQSIAoJYmFja3VwX2lkGAIgASgJQgPgQQJSCGJhY2t1cElkEjsKBmJhY2t1cBgDIAEo
CzIeLmdvb2dsZS5jbG91ZC5uZXRhcHAudjEuQmFja3VwQgPgQQJSBmJhY2t1cCJPChNEZWxl
dGVCYWNrdXBSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgocbmV0YXBwLmdvb2dsZWFw
aXMuY29tL0JhY2t1cFIEbmFtZSKUAQoTVXBkYXRlQmFja3VwUmVxdWVzdBJACgt1cGRhdGVf
bWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBkYXRlTWFz
axI7CgZiYWNrdXAYAiABKAsyHi5nb29nbGUuY2xvdWQubmV0YXBwLnYxLkJhY2t1cEID4EEC
UgZiYWNrdXAiwQEKC09udGFwU291cmNlElEKDHN0b3JhZ2VfcG9vbBgBIAEoCUIp4EEC+kEj
CiFuZXRhcHAuZ29vZ2xlYXBpcy5jb20vU3RvcmFnZVBvb2xIAFILc3RvcmFnZVBvb2yIAQES
JAoLdm9sdW1lX3V1aWQYAiABKAlCA+BBAlIKdm9sdW1lVXVpZBIoCg1zbmFwc2hvdF91dWlk
GAMgASgJQgPgQQFSDHNuYXBzaG90VXVpZEIPCg1fc3RvcmFnZV9wb29sQq0BChpjb20uZ29v
Z2xlLmNsb3VkLm5ldGFwcC52MUILQmFja3VwUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9n
by9uZXRhcHAvYXBpdjEvbmV0YXBwcGI7bmV0YXBwcGKqAhZHb29nbGUuQ2xvdWQuTmV0QXBw
LlYxygIWR29vZ2xlXENsb3VkXE5ldEFwcFxWMeoCGUdvb2dsZTo6Q2xvdWQ6Ok5ldEFwcDo6
VjFKjk0KBxIFDgCbAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMSAxUAKQoICgEI
EgMXADMKCQoCCCUSAxcAMwoICgEIEgMYAEkKCQoCCAsSAxgASQoICgEIEgMZACIKCQoCCAoS
AxkAIgoICgEIEgMaACwKCQoCCAgSAxoALAoICgEIEgMbADMKCQoCCAESAxsAMwoICgEIEgMc
ADMKCQoCCCkSAxwAMwoICgEIEgMdADIKCQoCCC0SAx0AMgofCgIEABIFIACeAQEaEiBBIE5l
dEFwcCBCYWNrdXAuCgoKCgMEAAESAyAIDgoLCgMEAAcSBCECJgQKDQoFBAAHnQgSBCECJgQK
IQoEBAAEABIEKQJCAxoTIFRoZSBCYWNrdXAgU3RhdGVzCgoMCgUEAAQAARIDKQcMCh8KBgQA
BAACABIDKwQaGhAgU3RhdGUgbm90IHNldC4KCg4KBwQABAACAAESAysEFQoOCgcEAAQAAgAC
EgMrGBkKvAEKBgQABAACARIDMAQRGqwBIEJhY2t1cCBpcyBiZWluZyBjcmVhdGVkLiBXaGls
ZSBpbiB0aGlzIHN0YXRlLCB0aGUgc25hcHNob3QgZm9yIHRoZSBiYWNrdXAKIHBvaW50LWlu
LXRpbWUgbWF5IG5vdCBoYXZlIGJlZW4gY3JlYXRlZCB5ZXQsIGFuZCBzbyB0aGUgcG9pbnQt
aW4tdGltZSBtYXkKIG5vdCBoYXZlIGJlZW4gZml4ZWQuCgoOCgcEAAQAAgEBEgMwBAwKDgoH
BAAEAAIBAhIDMA8QCoEBCgYEAAQAAgISAzQEEhpyIEJhY2t1cCBpcyBiZWluZyB1cGxvYWRl
ZC4gV2hpbGUgaW4gdGhpcyBzdGF0ZSwgbm9uZSBvZiB0aGUgd3JpdGVzIHRvIHRoZQogdm9s
dW1lIHdpbGwgYmUgaW5jbHVkZWQgaW4gdGhlIGJhY2t1cC4KCg4KBwQABAACAgESAzQEDQoO
CgcEAAQAAgICEgM0EBEKLQoGBAAEAAIDEgM3BA4aHiBCYWNrdXAgaXMgYXZhaWxhYmxlIGZv
ciB1c2UuCgoOCgcEAAQAAgMBEgM3BAkKDgoHBAAEAAIDAhIDNwwNCikKBgQABAACBBIDOgQR
GhogQmFja3VwIGlzIGJlaW5nIGRlbGV0ZWQuCgoOCgcEAAQAAgQBEgM6BAwKDgoHBAAEAAIE
AhIDOg8QCnAKBgQABAACBRIDPgQOGmEgQmFja3VwIGlzIG5vdCB2YWxpZCBhbmQgY2Fubm90
IGJlIHVzZWQgZm9yIGNyZWF0aW5nIG5ldyB2b2x1bWVzIG9yCiByZXN0b3JpbmcgZXhpc3Rp
bmcgdm9sdW1lcy4KCg4KBwQABAACBQESAz4ECQoOCgcEAAQAAgUCEgM+DA0KKQoGBAAEAAIG
EgNBBBEaGiBCYWNrdXAgaXMgYmVpbmcgdXBkYXRlZC4KCg4KBwQABAACBgESA0EEDAoOCgcE
AAQAAgYCEgNBDxAKHQoEBAAEARIERQJOAxoPIEJhY2t1cCB0eXBlcy4KCgwKBQQABAEBEgNF
BwsKKQoGBAAEAQIAEgNHBBkaGiBVbnNwZWNpZmllZCBiYWNrdXAgdHlwZS4KCg4KBwQABAEC
AAESA0cEFAoOCgcEAAQBAgACEgNHFxgKJAoGBAAEAQIBEgNKBA8aFSBNYW51YWwgYmFja3Vw
IHR5cGUuCgoOCgcEAAQBAgEBEgNKBAoKDgoHBAAEAQIBAhIDSg0OCicKBgQABAECAhIDTQQS
GhggU2NoZWR1bGVkIGJhY2t1cCB0eXBlLgoKDgoHBAAEAQICARIDTQQNCg4KBwQABAECAgIS
A00QEQqnAQoEBAACABIDUwI9GpkBIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBiYWNrdXAuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9u
cy97bG9jYXRpb259L2JhY2t1cFZhdWx0cy97YmFja3VwX3ZhdWx0X2lkfS9iYWNrdXBzL3ti
YWNrdXBfaWR9YC4KCgwKBQQAAgAFEgNTAggKDAoFBAACAAESA1MJDQoMCgUEAAIAAxIDUxAR
CgwKBQQAAgAIEgNTEjwKDwoIBAACAAicCAASA1MTOwotCgQEAAIBEgNWAj4aICBPdXRwdXQg
b25seS4gVGhlIGJhY2t1cCBzdGF0ZS4KCgwKBQQAAgEGEgNWAgcKDAoFBAACAQESA1YIDQoM
CgUEAAIBAxIDVhARCgwKBQQAAgEIEgNWEj0KDwoIBAACAQicCAASA1YTPAp9CgQEAAICEgNa
AhkacCBBIGRlc2NyaXB0aW9uIG9mIHRoZSBiYWNrdXAgd2l0aCAyMDQ4IGNoYXJhY3RlcnMg
b3IgbGVzcy4KIFJlcXVlc3RzIHdpdGggbG9uZ2VyIGRlc2NyaXB0aW9ucyB3aWxsIGJlIHJl
amVjdGVkLgoKDAoFBAACAgUSA1oCCAoMCgUEAAICARIDWgkUCgwKBQQAAgIDEgNaFxgKtAEK
BAQAAgMSA18CSxqmASBPdXRwdXQgb25seS4gU2l6ZSBvZiB0aGUgZmlsZSBzeXN0ZW0gd2hl
biB0aGUgYmFja3VwIHdhcyBjcmVhdGVkLiBXaGVuCiBjcmVhdGluZyBhIG5ldyB2b2x1bWUg
ZnJvbSB0aGUgYmFja3VwLCB0aGUgdm9sdW1lIGNhcGFjaXR5IHdpbGwgaGF2ZSB0byBiZQog
YXQgbGVhc3QgYXMgYmlnLgoKDAoFBAACAwUSA18CBwoMCgUEAAIDARIDXwgaCgwKBQQAAgMD
EgNfHR4KDAoFBAACAwgSA18fSgoPCggEAAIDCJwIABIDXyBJClwKBAQAAgQSA2MCQxpPIE91
dHB1dCBvbmx5LiBUeXBlIG9mIGJhY2t1cCwgbWFudWFsbHkgY3JlYXRlZCBvciBjcmVhdGVk
IGJ5IGEgYmFja3VwCiBwb2xpY3kuCgoMCgUEAAIEBhIDYwIGCgwKBQQAAgQBEgNjBxIKDAoF
BAACBAMSA2MVFgoMCgUEAAIECBIDYxdCCg8KCAQAAgQInAgAEgNjGEEK0wEKBAQAAgUSBGgC
agQaxAEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHZvbHVtZSB0aGF0IHRoaXMgYmFja3Vw
IGJlbG9uZ3MgdG8uIFlvdSBtdXN0CiBwcm92aWRlIGVpdGhlciBgc291cmNlX3ZvbHVtZWAg
b3IgYG9udGFwX3NvdXJjZWAuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vdm9sdW1lcy97dm9sdW1lX2lkfWAKCgwKBQQAAgUFEgNoAggK
DAoFBAACBQESA2gJFgoMCgUEAAIFAxIDaBkaCg0KBQQAAgUIEgRoG2oDCg4KBwQAAgUInwgS
A2kETgqIAgoEBAACBhIEcAJyBBr5ASBJZiBzcGVjaWZpZWQsIGJhY2t1cCB3aWxsIGJlIGNy
ZWF0ZWQgZnJvbSB0aGUgZ2l2ZW4gc25hcHNob3QuCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGVy
ZSB3aWxsIGJlIGEgbmV3IHNuYXBzaG90IHRha2VuIHRvIGluaXRpYXRlIHRoZSBiYWNrdXAK
IGNyZWF0aW9uLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97
bG9jYXRpb259L3ZvbHVtZXMve3ZvbHVtZV9pZH0vc25hcHNob3RzL3tzbmFwc2hvdF9pZH1g
CgoMCgUEAAIGBBIDcAIKCgwKBQQAAgYFEgNwCxEKDAoFBAACBgESA3ASIQoMCgUEAAIGAxID
cCQlCg0KBQQAAgYIEgRwJnIDCg4KBwQAAgYInwgSA3EEUApCCgQEAAIHEgR1AnYyGjQgT3V0
cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIGJhY2t1cCB3YXMgY3JlYXRlZC4KCgwKBQQA
AgcGEgN1AhsKDAoFBAACBwESA3UcJwoMCgUEAAIHAxIDdSorCgwKBQQAAgcIEgN2BjEKDwoI
BAACBwicCAASA3YHMApDCgQEAAIIEgN5AiEaNiBSZXNvdXJjZSBsYWJlbHMgdG8gcmVwcmVz
ZW50IHVzZXIgcHJvdmlkZWQgbWV0YWRhdGEuCgoMCgUEAAIIBhIDeQIVCgwKBQQAAggBEgN5
FhwKDAoFBAACCAMSA3kfIAqAAQoEBAACCRIDfQJNGnMgT3V0cHV0IG9ubHkuIFRvdGFsIHNp
emUgb2YgYWxsIGJhY2t1cHMgaW4gYSBjaGFpbiBpbiBieXRlcyA9IGJhc2VsaW5lCiBiYWNr
dXAgc2l6ZSArIHN1bShpbmNyZW1lbnRhbCBiYWNrdXAgc2l6ZSkKCgwKBQQAAgkFEgN9AgcK
DAoFBAACCQESA30IGwoMCgUEAAIJAxIDfR4gCgwKBQQAAgkIEgN9IUwKDwoIBAACCQicCAAS
A30iSwo0CgQEAAIKEgSAAQJGGiYgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUg
dXNlCgoNCgUEAAIKBRIEgAECBgoNCgUEAAIKARIEgAEHFAoNCgUEAAIKAxIEgAEXGQoNCgUE
AAIKCBIEgAEaRQoQCggEAAIKCJwIABIEgAEbRAo0CgQEAAILEgSDAQJGGiYgT3V0cHV0IG9u
bHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlCgoNCgUEAAILBRIEgwECBgoNCgUEAAILARIE
gwEHFAoNCgUEAAILAxIEgwEXGQoNCgUEAAILCBIEgwEaRQoQCggEAAILCJwIABIEgwEbRAqM
AQoEBAACDBIGhwECjAEEGnwgT3V0cHV0IG9ubHkuIFJlZ2lvbiBvZiB0aGUgdm9sdW1lIGZy
b20gd2hpY2ggdGhlIGJhY2t1cCB3YXMgY3JlYXRlZC4KIEZvcm1hdDogYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAgwFEgSHAQIICg0KBQQA
AgwBEgSHAQkWCg0KBQQAAgwDEgSHARkbCg8KBQQAAgwIEgaHARyMAQMKEAoIBAACDAicCAAS
BIgBBC0KEQoHBAACDAifCBIGiQEEiwEFCnYKBAQAAg0SBpABApUBBBpmIE91dHB1dCBvbmx5
LiBSZWdpb24gaW4gd2hpY2ggYmFja3VwIGlzIHN0b3JlZC4KIEZvcm1hdDogYHByb2plY3Rz
L3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufWAKCg0KBQQAAg0FEgSQAQIICg0K
BQQAAg0BEgSQAQkWCg0KBQQAAg0DEgSQARkbCg8KBQQAAg0IEgaQARyVAQMKEAoIBAACDQic
CAASBJEBBC0KEQoHBAACDQifCBIGkgEElAEFClAKBAQAAg4SBpgBApkBMhpAIE91dHB1dCBv
bmx5LiBUaGUgdGltZSB1bnRpbCB3aGljaCB0aGUgYmFja3VwIGlzIG5vdCBkZWxldGFibGUu
CgoNCgUEAAIOBhIEmAECGwoNCgUEAAIOARIEmAEcNwoNCgUEAAIOAxIEmAE6PAoNCgUEAAIO
CBIEmQEGMQoQCggEAAIOCJwIABIEmQEHMAqAAQoEBAACDxIEnQECSRpyIE9wdGlvbmFsLiBS
ZXByZXNlbnRzIHNvdXJjZSBkZXRhaWxzIGZvciBPTlRBUCBiYWNrdXBzLgogRWl0aGVyIHNv
dXJjZV92b2x1bWUgb3Igb250YXBfc291cmNlIHNob3VsZCBiZSBwcm92aWRlZC4KCg0KBQQA
Ag8GEgSdAQINCg0KBQQAAg8BEgSdAQ4aCg0KBQQAAg8DEgSdAR0fCg0KBQQAAg8IEgSdASBI
ChAKCAQAAg8InAgAEgSdASFHCjEKAgQBEgahAQDDAQEaIyBMaXN0QmFja3Vwc1JlcXVlc3Qg
bGlzdHMgYmFja3Vwcy4KCgsKAwQBARIEoQEIGgr0AwoEBAECABIGqwECsAEEGuMDIFJlcXVp
cmVkLiBUaGUgYmFja3VwVmF1bHQgZm9yIHdoaWNoIHRvIHJldHJpZXZlIGJhY2t1cCBpbmZv
cm1hdGlvbiwKIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vYmFja3VwVmF1bHRzL3tiYWNrdXBfdmF1bHRfaWR9YC4KIFRvIHJl
dHJpZXZlIGJhY2t1cCBpbmZvcm1hdGlvbiBmb3IgYWxsIGxvY2F0aW9ucywgdXNlICItIiBm
b3IgdGhlCiBge2xvY2F0aW9ufWAgdmFsdWUuCiBUbyByZXRyaWV2ZSBiYWNrdXAgaW5mb3Jt
YXRpb24gZm9yIGFsbCBiYWNrdXBWYXVsdHMsIHVzZSAiLSIgZm9yIHRoZQogYHtiYWNrdXBf
dmF1bHRfaWR9YCB2YWx1ZS4KIFRvIHJldHJpZXZlIGJhY2t1cCBpbmZvcm1hdGlvbiBmb3Ig
YSB2b2x1bWUsIHVzZSAiLSIgZm9yIHRoZQogYHtiYWNrdXBfdmF1bHRfaWR9YCB2YWx1ZSBh
bmQgc3BlY2lmeSB2b2x1bWUgZnVsbCBuYW1lIHdpdGggdGhlIGZpbHRlci4KCg0KBQQBAgAF
EgSrAQIICg0KBQQBAgABEgSrAQkPCg0KBQQBAgADEgSrARITCg8KBQQBAgAIEgarARSwAQMK
EAoIBAECAAicCAASBKwBBCoKEQoHBAECAAifCBIGrQEErwEFCq0BCgQEAQIBEgS1AQIWGp4B
IFRoZSBtYXhpbXVtIG51bWJlciBvZiBpdGVtcyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1h
eSByZXR1cm4gZmV3ZXIKIHRoYW4gdGhpcyB2YWx1ZS4gVGhlIG1heGltdW0gdmFsdWUKIGlz
IDEwMDA7IHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoF
BAECAQUSBLUBAgcKDQoFBAECAQESBLUBCBEKDQoFBAECAQMSBLUBFBUKdAoEBAECAhIEuQEC
GBpmIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgdG8gdXNlIGlmIHRoZXJlIGFyZSBhZGRp
dGlvbmFsCiByZXN1bHRzIHRvIHJldHJpZXZlIGZvciB0aGlzIGxpc3QgcmVxdWVzdC4KCg0K
BQQBAgIFEgS5AQIICg0KBQQBAgIBEgS5AQkTCg0KBQQBAgIDEgS5ARYXClgKBAQBAgMSBLwB
AhYaSiBTb3J0IHJlc3VsdHMuIFN1cHBvcnRlZCB2YWx1ZXMgYXJlICJuYW1lIiwgIm5hbWUg
ZGVzYyIgb3IgIiIgKHVuc29ydGVkKS4KCg0KBQQBAgMFEgS8AQIICg0KBQQBAgMBEgS8AQkR
Cg0KBQQBAgMDEgS8ARQVCt8BCgQEAQIEEgTCAQIUGtABIFRoZSBzdGFuZGFyZCBsaXN0IGZp
bHRlci4KIElmIHNwZWNpZmllZCwgYmFja3VwcyB3aWxsIGJlIHJldHVybmVkIGJhc2VkIG9u
IHRoZSBhdHRyaWJ1dGUgbmFtZSB0aGF0CiBtYXRjaGVzIHRoZSBmaWx0ZXIgZXhwcmVzc2lv
bi4gSWYgZW1wdHksIHRoZW4gbm8gYmFja3VwcyBhcmUgZmlsdGVyZWQgb3V0LgogU2VlIGh0
dHBzOi8vZ29vZ2xlLmFpcC5kZXYvMTYwCgoNCgUEAQIEBRIEwgECCAoNCgUEAQIEARIEwgEJ
DwoNCgUEAQIEAxIEwgESEwpICgIEAhIGxgEA0AEBGjogTGlzdEJhY2t1cHNSZXNwb25zZSBp
cyB0aGUgcmVzdWx0IG9mIExpc3RCYWNrdXBzUmVxdWVzdC4KCgsKAwQCARIExgEIGwoxCgQE
AgIAEgTIAQIeGiMgQSBsaXN0IG9mIGJhY2t1cHMgaW4gdGhlIHByb2plY3QuCgoNCgUEAgIA
BBIEyAECCgoNCgUEAgIABhIEyAELEQoNCgUEAgIAARIEyAESGQoNCgUEAgIAAxIEyAEcHQqD
AQoEBAICARIEzAECHRp1IFRoZSB0b2tlbiB5b3UgY2FuIHVzZSB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlIG9mIHJlc3VsdHMuIE5vdCByZXR1cm5lZAogaWYgdGhlcmUgYXJlIG5vIG1v
cmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQCAgEFEgTMAQIICg0KBQQCAgEBEgTMAQkY
Cg0KBQQCAgEDEgTMARscCjQKBAQCAgISBM8BAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBu
b3QgYmUgcmVhY2hlZC4KCg0KBQQCAgIEEgTPAQIKCg0KBQQCAgIFEgTPAQsRCg0KBQQCAgIB
EgTPARIdCg0KBQQCAgIDEgTPASAhCjwKAgQDEgbTAQDaAQEaLiBHZXRCYWNrdXBSZXF1ZXN0
IGdldHMgdGhlIHN0YXRlIG9mIGEgYmFja3VwLgoKCwoDBAMBEgTTAQgYCqUBCgQEAwIAEgbW
AQLZAQQalAEgUmVxdWlyZWQuIFRoZSBiYWNrdXAgcmVzb3VyY2UgbmFtZSwgaW4gdGhlIGZv
cm1hdAogYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNr
dXBWYXVsdHMve2JhY2t1cF92YXVsdF9pZH0vYmFja3Vwcy97YmFja3VwX2lkfWAKCg0KBQQD
AgAFEgTWAQIICg0KBQQDAgABEgTWAQkNCg0KBQQDAgADEgTWARARCg8KBQQDAgAIEgbWARLZ
AQMKEAoIBAMCAAicCAASBNcBBCoKDwoHBAMCAAifCBIE2AEETgo1CgIEBBIG3QEA8AEBGicg
Q3JlYXRlQmFja3VwUmVxdWVzdCBjcmVhdGVzIGEgYmFja3VwLgoKCwoDBAQBEgTdAQgbCpQB
CgQEBAIAEgbgAQLlAQQagwEgUmVxdWlyZWQuIFRoZSBOZXRBcHAgYmFja3VwVmF1bHQgdG8g
Y3JlYXRlIHRoZSBiYWNrdXBzIG9mLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9iYWNrdXBWYXVsdHMve2JhY2t1cF92YXVsdF9pZH1gCgoNCgUEBAIABRIE4AEC
CAoNCgUEBAIAARIE4AEJDwoNCgUEBAIAAxIE4AESEwoPCgUEBAIACBIG4AEU5QEDChAKCAQE
AgAInAgAEgThAQQqChEKBwQEAgAInwgSBuIBBOQBBQqBAgoEBAQCARIE7AECQBryASBSZXF1
aXJlZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIGJhY2t1cC4KIFRoZSBJRCBtdXN0IGJlIHVu
aXF1ZSB3aXRoaW4gdGhlIHNwZWNpZmllZCBiYWNrdXBWYXVsdC4KIE11c3QgY29udGFpbiBv
bmx5IGxldHRlcnMsIG51bWJlcnMgYW5kIGh5cGhlbiwgd2l0aCB0aGUgZmlyc3QKIGNoYXJh
Y3RlciBhIGxldHRlciwgdGhlIGxhc3QgYSBsZXR0ZXIgb3IgYQogbnVtYmVyLCBhbmQgYSA2
MyBjaGFyYWN0ZXIgbWF4aW11bS4KCg0KBQQEAgEFEgTsAQIICg0KBQQEAgEBEgTsAQkSCg0K
BQQEAgEDEgTsARUWCg0KBQQEAgEIEgTsARc/ChAKCAQEAgEInAgAEgTsARg+CisKBAQEAgIS
BO8BAj0aHSBSZXF1aXJlZC4gQSBiYWNrdXAgcmVzb3VyY2UKCg0KBQQEAgIGEgTvAQIICg0K
BQQEAgIBEgTvAQkPCg0KBQQEAgIDEgTvARITCg0KBQQEAgIIEgTvARQ8ChAKCAQEAgIInAgA
EgTvARU7CjUKAgQFEgbzAQD6AQEaJyBEZWxldGVCYWNrdXBSZXF1ZXN0IGRlbGV0ZXMgYSBi
YWNrdXAuCgoLCgMEBQESBPMBCBsKpQEKBAQFAgASBvYBAvkBBBqUASBSZXF1aXJlZC4gVGhl
IGJhY2t1cCByZXNvdXJjZSBuYW1lLCBpbiB0aGUgZm9ybWF0CiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L2JhY2t1cFZhdWx0cy97YmFja3VwX3ZhdWx0
X2lkfS9iYWNrdXBzL3tiYWNrdXBfaWR9YAoKDQoFBAUCAAUSBPYBAggKDQoFBAUCAAESBPYB
CQ0KDQoFBAUCAAMSBPYBEBEKDwoFBAUCAAgSBvYBEvkBAwoQCggEBQIACJwIABIE9wEEKgoP
CgcEBQIACJ8IEgT4AQROClMKAgQGEgb9AQCIAgEaRSBVcGRhdGVCYWNrdXBSZXF1ZXN0IHVw
ZGF0ZXMgZGVzY3JpcHRpb24gYW5kL29yIGxhYmVscyBmb3IgYSBiYWNrdXAuCgoLCgMEBgES
BP0BCBsK2AIKBAQGAgASBoMCAoQCLxrHAiBSZXF1aXJlZC4gRmllbGQgbWFzayBpcyB1c2Vk
IHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIEJhY2t1
cCByZXNvdXJjZSB0byBiZSB1cGRhdGVkLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhl
IHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1
bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRo
ZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwg
ZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBgIABhIEgwICGwoNCgUEBgIAARIE
gwIcJwoNCgUEBgIAAxIEgwIqKwoNCgUEBgIACBIEhAIGLgoQCggEBgIACJwIABIEhAIHLQoy
CgQEBgIBEgSHAgI9GiQgUmVxdWlyZWQuIFRoZSBiYWNrdXAgYmVpbmcgdXBkYXRlZAoKDQoF
BAYCAQYSBIcCAggKDQoFBAYCAQESBIcCCQ8KDQoFBAYCAQMSBIcCEhMKDQoFBAYCAQgSBIcC
FDwKEAoIBAYCAQicCAASBIcCFTsKMAoCBAcSBosCAJsCARoiIFJlcHJlc2VudHMgT05UQVAg
c291cmNlIGRldGFpbHMuCgoLCgMEBwESBIsCCBMK0QEKBAQHAgASBo8CApQCBBrAASBSZXF1
aXJlZC4gTmFtZSBvZiB0aGUgc3RvcmFnZSBwb29sLiBUaGlzIG11c3QgYmUgc3BlY2lmaWVk
IGZvciBjcmVhdGluZwogYmFja3VwcyBmb3IgT05UQVAgbW9kZSB2b2x1bWVzLiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3RzX2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zdG9yYWdl
UG9vbHMve3N0b3JhZ2VfcG9vbF9pZH1gCgoNCgUEBwIABBIEjwICCgoNCgUEBwIABRIEjwIL
EQoNCgUEBwIAARIEjwISHgoNCgUEBwIAAxIEjwIhIgoPCgUEBwIACBIGjwIjlAIDChAKCAQH
AgAInAgAEgSQAgQqChEKBwQHAgAInwgSBpECBJMCBQo+CgQEBwIBEgSXAgJCGjAgUmVxdWly
ZWQuIFRoZSBVVUlEIG9mIHRoZSBPTlRBUCBzb3VyY2Ugdm9sdW1lLgoKDQoFBAcCAQUSBJcC
AggKDQoFBAcCAQESBJcCCRQKDQoFBAcCAQMSBJcCFxgKDQoFBAcCAQgSBJcCGUEKEAoIBAcC
AQicCAASBJcCGkAKQAoEBAcCAhIEmgICRBoyIE9wdGlvbmFsLiBUaGUgVVVJRCBvZiB0aGUg
T05UQVAgc291cmNlIHNuYXBzaG90LgoKDQoFBAcCAgUSBJoCAggKDQoFBAcCAgESBJoCCRYK
DQoFBAcCAgMSBJoCGRoKDQoFBAcCAggSBJoCG0MKEAoIBAcCAgicCAASBJoCHEJiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Netapp::V1::Backup::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.netapp.v1.Backup.State)
    # Field: description Type: 9 ()
    # Field: volume_usage_bytes Type: 3 ()
    # Field: backup_type Type: 14 (.google.cloud.netapp.v1.Backup.Type)
    # Field: source_volume Type: 9 ()
    # Field: source_snapshot Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.netapp.v1.Backup.LabelsEntry)
    # Field: chain_storage_bytes Type: 3 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()
    # Field: volume_region Type: 9 ()
    # Field: backup_region Type: 9 ()
    # Field: enforced_retention_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ontap_source Type: 11 (.google.cloud.netapp.v1.OntapSource)

# Enum: Backup::State
our $Backup_STATE_UNSPECIFIED = 0;
our $Backup_CREATING = 1;
our $Backup_UPLOADING = 2;
our $Backup_READY = 3;
our $Backup_DELETING = 4;
our $Backup_ERROR = 5;
our $Backup_UPDATING = 6;

# Enum: Backup::Type
our $Backup_TYPE_UNSPECIFIED = 0;
our $Backup_MANUAL = 1;
our $Backup_SCHEDULED = 2;

# === Message: Google::Cloud::Netapp::V1::Backup::ListBackupsRequest ===
    # Fields for ListBackupsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Backup::ListBackupsResponse ===
    # Fields for ListBackupsResponse
    # Field: backups Type: 11 (.google.cloud.netapp.v1.Backup)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Backup::GetBackupRequest ===
    # Fields for GetBackupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Backup::CreateBackupRequest ===
    # Fields for CreateBackupRequest
    # Field: parent Type: 9 ()
    # Field: backup_id Type: 9 ()
    # Field: backup Type: 11 (.google.cloud.netapp.v1.Backup)

# === Message: Google::Cloud::Netapp::V1::Backup::DeleteBackupRequest ===
    # Fields for DeleteBackupRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Netapp::V1::Backup::UpdateBackupRequest ===
    # Fields for UpdateBackupRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: backup Type: 11 (.google.cloud.netapp.v1.Backup)

# === Message: Google::Cloud::Netapp::V1::Backup::OntapSource ===
    # Fields for OntapSource
    # Field: storage_pool Type: 9 ()
    # Field: volume_uuid Type: 9 ()
    # Field: snapshot_uuid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Netapp::V1::Backup - Compiled Protocol Buffers messages for google/cloud/netapp/v1/backup.proto

=head1 SYNOPSIS

    use Google::Cloud::Netapp::V1::Backup;

    my $msg = Google::Cloud::Netapp::V1::Backup::Backup->new({
        name => $name,
        state => $state,
        description => $description,
        volume_usage_bytes => $volume_usage_bytes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Netapp::V1::Backup::Backup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/netapp/v1/backup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Netapp::V1::Backup::Backup

A NetApp Backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the backup.
Format:
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}/backups/{backup_id}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::Backup::State>)

Output only. The backup state.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the backup with 2048 characters or less.
Requests with longer descriptions will be rejected.

=item * C<< $msg->volume_usage_bytes() >> / C<< $msg->volume_usage_bytes($value) >>

Type: C<Int64>

Output only. Size of the file system when the backup was created. When
creating a new volume from the backup, the volume capacity will have to be
at least as big.

=item * C<< $msg->backup_type() >> / C<< $msg->backup_type($value) >>

Type: C<Enum> (L<Google::Cloud::Netapp::V1::Backup::Type>)

Output only. Type of backup, manually created or created by a backup
policy.

=item * C<< $msg->source_volume() >> / C<< $msg->source_volume($value) >>

Type: C<String>

The resource name of the volume that this backup belongs to. You must
provide either `source_volume` or `ontap_source`. Format:
`projects/{project_id}/locations/{location}/volumes/{volume_id}`

=item * C<< $msg->source_snapshot() >> / C<< $msg->source_snapshot($value) >>

Type: C<String>

If specified, backup will be created from the given snapshot.
If not specified, there will be a new snapshot taken to initiate the backup
creation. Format:
`projects/{project_id}/locations/{location}/volumes/{volume_id}/snapshots/{snapshot_id}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the backup was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Backup::Backup::LabelsEntry>)

Resource labels to represent user provided metadata.

=item * C<< $msg->chain_storage_bytes() >> / C<< $msg->chain_storage_bytes($value) >>

Type: C<Int64>

Output only. Total size of all backups in a chain in bytes = baseline
backup size + sum(incremental backup size)

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use

=item * C<< $msg->volume_region() >> / C<< $msg->volume_region($value) >>

Type: C<String>

Output only. Region of the volume from which the backup was created.
Format: `projects/{project_id}/locations/{location}`

=item * C<< $msg->backup_region() >> / C<< $msg->backup_region($value) >>

Type: C<String>

Output only. Region in which backup is stored.
Format: `projects/{project_id}/locations/{location}`

=item * C<< $msg->enforced_retention_end_time() >> / C<< $msg->enforced_retention_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time until which the backup is not deletable.

=item * C<< $msg->ontap_source() >> / C<< $msg->ontap_source($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Backup::OntapSource>)

Optional. Represents source details for ONTAP backups.
Either source_volume or ontap_source should be provided.

=back

=head3 Enum: Backup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPLOADING> => C<2>

=item * C<READY> => C<3>

=item * C<DELETING> => C<4>

=item * C<ERROR> => C<5>

=item * C<UPDATING> => C<6>

=back

=head3 Enum: Backup::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<MANUAL> => C<1>

=item * C<SCHEDULED> => C<2>

=back

=head2 Google::Cloud::Netapp::V1::Backup::ListBackupsRequest

ListBackupsRequest lists backups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The backupVault for which to retrieve backup information,
in the format
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}`.
To retrieve backup information for all locations, use "-" for the
`{location}` value.
To retrieve backup information for all backupVaults, use "-" for the
`{backup_vault_id}` value.
To retrieve backup information for a volume, use "-" for the
`{backup_vault_id}` value and specify volume full name with the filter.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of items to return. The service may return fewer
than this value. The maximum value
is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value to use if there are additional
results to retrieve for this list request.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort results. Supported values are "name", "name desc" or "" (unsorted).

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

The standard list filter.
If specified, backups will be returned based on the attribute name that
matches the filter expression. If empty, then no backups are filtered out.
See https://google.aip.dev/160

=back

=head2 Google::Cloud::Netapp::V1::Backup::ListBackupsResponse

ListBackupsResponse is the result of ListBackupsRequest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backups() >> / C<< $msg->backups($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Backup::Backup>)

A list of backups in the project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token you can use to retrieve the next page of results. Not returned
if there are no more results in the list.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Netapp::V1::Backup::GetBackupRequest

GetBackupRequest gets the state of a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backup resource name, in the format
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}/backups/{backup_id}`

=back

=head2 Google::Cloud::Netapp::V1::Backup::CreateBackupRequest

CreateBackupRequest creates a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The NetApp backupVault to create the backups of, in the format
`projects/*/locations/*/backupVaults/{backup_vault_id}`

=item * C<< $msg->backup_id() >> / C<< $msg->backup_id($value) >>

Type: C<String>

Required. The ID to use for the backup.
The ID must be unique within the specified backupVault.
Must contain only letters, numbers and hyphen, with the first
character a letter, the last a letter or a
number, and a 63 character maximum.

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Backup::Backup>)

Required. A backup resource

=back

=head2 Google::Cloud::Netapp::V1::Backup::DeleteBackupRequest

DeleteBackupRequest deletes a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The backup resource name, in the format
`projects/{project_id}/locations/{location}/backupVaults/{backup_vault_id}/backups/{backup_id}`

=back

=head2 Google::Cloud::Netapp::V1::Backup::UpdateBackupRequest

UpdateBackupRequest updates description and/or labels for a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
Backup resource to be updated.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->backup() >> / C<< $msg->backup($value) >>

Type: C<Message> (L<Google::Cloud::Netapp::V1::Backup::Backup>)

Required. The backup being updated

=back

=head2 Google::Cloud::Netapp::V1::Backup::OntapSource

Represents ONTAP source details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->storage_pool() >> / C<< $msg->storage_pool($value) >>

Type: C<String>

Required. Name of the storage pool. This must be specified for creating
backups for ONTAP mode volumes. Format:
`projects/{projects_id}/locations/{location}/storagePools/{storage_pool_id}`

=item * C<< $msg->volume_uuid() >> / C<< $msg->volume_uuid($value) >>

Type: C<String>

Required. The UUID of the ONTAP source volume.

=item * C<< $msg->snapshot_uuid() >> / C<< $msg->snapshot_uuid($value) >>

Type: C<String>

Optional. The UUID of the ONTAP source snapshot.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Netapp::V1::Backup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
