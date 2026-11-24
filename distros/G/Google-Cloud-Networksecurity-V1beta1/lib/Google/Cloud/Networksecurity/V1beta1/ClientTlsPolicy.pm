package Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy;

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
    eval { require Google::Cloud::Networksecurity::V1beta1::Tls };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvY2xpZW50X3Rsc19wb2xp
Y3kucHJvdG8SJGdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxou
Z29vZ2xlL2Nsb3VkL25ldHdvcmtzZWN1cml0eS92MWJldGExL3Rscy5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8i5gUKD0NsaWVudFRsc1BvbGljeRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSJQoL
ZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SQAoLY3JlYXRlX3RpbWUYAyAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBk
YXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0
ZVRpbWUSXgoGbGFiZWxzGAUgAygLMkEuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52
MWJldGExLkNsaWVudFRsc1BvbGljeS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSFQoDc25p
GAYgASgJQgPgQQFSA3NuaRJtChJjbGllbnRfY2VydGlmaWNhdGUYByABKAsyOS5nb29nbGUu
Y2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEuQ2VydGlmaWNhdGVQcm92aWRlckID4EEB
UhFjbGllbnRDZXJ0aWZpY2F0ZRJpChRzZXJ2ZXJfdmFsaWRhdGlvbl9jYRgIIAMoCzIyLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5WYWxpZGF0aW9uQ0FCA+BBAVIS
c2VydmVyVmFsaWRhdGlvbkNhGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK
BXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6ggHqQX8KLm5ldHdvcmtzZWN1cml0eS5nb29nbGVh
cGlzLmNvbS9DbGllbnRUbHNQb2xpY3kSTXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jbGllbnRUbHNQb2xpY2llcy97Y2xpZW50X3Rsc19wb2xpY3l9Ip0BChxM
aXN0Q2xpZW50VGxzUG9saWNpZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFs
b2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUY
AiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKuAQodTGlz
dENsaWVudFRsc1BvbGljaWVzUmVzcG9uc2USZQoTY2xpZW50X3Rsc19wb2xpY2llcxgBIAMo
CzI1Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5DbGllbnRUbHNQb2xp
Y3lSEWNsaWVudFRsc1BvbGljaWVzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbiJnChlHZXRDbGllbnRUbHNQb2xpY3lSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBB
AvpBMAoubmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeVIE
bmFtZSKMAgocQ3JlYXRlQ2xpZW50VGxzUG9saWN5UmVxdWVzdBJOCgZwYXJlbnQYASABKAlC
NuBBAvpBMBIubmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGlj
eVIGcGFyZW50EjQKFGNsaWVudF90bHNfcG9saWN5X2lkGAIgASgJQgPgQQJSEWNsaWVudFRs
c1BvbGljeUlkEmYKEWNsaWVudF90bHNfcG9saWN5GAMgASgLMjUuZ29vZ2xlLmNsb3VkLm5l
dHdvcmtzZWN1cml0eS52MWJldGExLkNsaWVudFRsc1BvbGljeUID4EECUg9jbGllbnRUbHNQ
b2xpY3kiyAEKHFVwZGF0ZUNsaWVudFRsc1BvbGljeVJlcXVlc3QSQAoLdXBkYXRlX21hc2sY
ASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVwZGF0ZU1hc2sSZgoR
Y2xpZW50X3Rsc19wb2xpY3kYAiABKAsyNS5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5
LnYxYmV0YTEuQ2xpZW50VGxzUG9saWN5QgPgQQJSD2NsaWVudFRsc1BvbGljeSJqChxEZWxl
dGVDbGllbnRUbHNQb2xpY3lSZXF1ZXN0EkoKBG5hbWUYASABKAlCNuBBAvpBMAoubmV0d29y
a3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL0NsaWVudFRsc1BvbGljeVIEbmFtZUKOAgooY29t
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMUIUQ2xpZW50VGxzUG9saWN5
UHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkvYXBpdjFiZXRh
MS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCJEdvb2dsZS5DbG91ZC5O
ZXR3b3JrU2VjdXJpdHkuVjFCZXRhMcoCJEdvb2dsZVxDbG91ZFxOZXR3b3JrU2VjdXJpdHlc
VjFiZXRhMeoCJ0dvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFiZXRhMUr0LQoH
EgUOAKgBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJCgIDAxIDFQAqCgkKAgMEEgMWACkK
CAoBCBIDGABBCgkKAgglEgMYAEEKCAoBCBIDGQBpCgkKAggLEgMZAGkKCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwA1CgkKAggIEgMbADUKCAoBCBIDHABBCgkKAggBEgMcAEEKCAoB
CBIDHQBBCgkKAggpEgMdAEEKCAoBCBIDHgBACgkKAggtEgMeAEAK7AEKAgQAEgQjAEoBGt8B
IENsaWVudFRsc1BvbGljeSBpcyBhIHJlc291cmNlIHRoYXQgc3BlY2lmaWVzIGhvdyBhIGNs
aWVudCBzaG91bGQgYXV0aGVudGljYXRlCiBjb25uZWN0aW9ucyB0byBiYWNrZW5kcyBvZiBh
IHNlcnZpY2UuIFRoaXMgcmVzb3VyY2UgaXRzZWxmIGRvZXMgbm90IGFmZmVjdAogY29uZmln
dXJhdGlvbiB1bmxlc3MgaXQgaXMgYXR0YWNoZWQgdG8gYSBiYWNrZW5kIHNlcnZpY2UgcmVz
b3VyY2UuCgoKCgMEAAESAyMIFwoLCgMEAAcSBCQCJwQKDQoFBAAHnQgSBCQCJwQKnwEKBAQA
AgASAysCOxqRASBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgQ2xpZW50VGxzUG9saWN5IHJlc291
cmNlLiBJdCBtYXRjaGVzIHRoZSBwYXR0ZXJuCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jbGllbnRUbHNQb2xpY2llcy97Y2xpZW50X3Rsc19wb2xpY3l9YAoKDAoFBAAC
AAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEKDAoFBAACAAgSAysSOgoPCggE
AAIACJwIABIDKxM5Cj8KBAQAAgESAy4CQhoyIE9wdGlvbmFsLiBGcmVlLXRleHQgZGVzY3Jp
cHRpb24gb2YgdGhlIHJlc291cmNlLgoKDAoFBAACAQUSAy4CCAoMCgUEAAIBARIDLgkUCgwK
BQQAAgEDEgMuFxgKDAoFBAACAQgSAy4ZQQoPCggEAAIBCJwIABIDLhpACkkKBAQAAgISBDEC
MjIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMg
Y3JlYXRlZC4KCgwKBQQAAgIGEgMxAhsKDAoFBAACAgESAzEcJwoMCgUEAAICAxIDMSorCgwK
BQQAAgIIEgMyBjEKDwoIBAACAgicCAASAzIHMApJCgQEAAIDEgQ1AjYyGjsgT3V0cHV0IG9u
bHkuIFRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgcmVzb3VyY2Ugd2FzIHVwZGF0ZWQuCgoMCgUE
AAIDBhIDNQIbCgwKBQQAAgMBEgM1HCcKDAoFBAACAwMSAzUqKwoMCgUEAAIDCBIDNgYxCg8K
CAQAAgMInAgAEgM2BzAKSAoEBAACBBIDOQJKGjsgT3B0aW9uYWwuIFNldCBvZiBsYWJlbCB0
YWdzIGFzc29jaWF0ZWQgd2l0aCB0aGUgcmVzb3VyY2UuCgoMCgUEAAIEBhIDOQIVCgwKBQQA
AgQBEgM5FhwKDAoFBAACBAMSAzkfIAoMCgUEAAIECBIDOSFJCg8KCAQAAgQInAgAEgM5IkgK
gQEKBAQAAgUSAz0COhp0IE9wdGlvbmFsLiBTZXJ2ZXIgTmFtZSBJbmRpY2F0aW9uIHN0cmlu
ZyB0byBwcmVzZW50IHRvIHRoZSBzZXJ2ZXIgZHVyaW5nIFRMUwogaGFuZHNoYWtlLiBFLmc6
ICJzZWN1cmUuZXhhbXBsZS5jb20iLgoKDAoFBAACBQUSAz0CCAoMCgUEAAIFARIDPQkMCgwK
BQQAAgUDEgM9DxAKDAoFBAACBQgSAz0ROQoPCggEAAIFCJwIABIDPRI4CqwBCgQEAAIGEgRC
AkMvGp0BIE9wdGlvbmFsLiBEZWZpbmVzIGEgbWVjaGFuaXNtIHRvIHByb3Zpc2lvbiBjbGll
bnQgaWRlbnRpdHkgKHB1YmxpYyBhbmQKIHByaXZhdGUga2V5cykgZm9yIHBlZXIgdG8gcGVl
ciBhdXRoZW50aWNhdGlvbi4gVGhlIHByZXNlbmNlIG9mIHRoaXMKIGRpY3RhdGVzIG1UTFMu
CgoMCgUEAAIGBhIDQgIVCgwKBQQAAgYBEgNCFigKDAoFBAACBgMSA0IrLAoMCgUEAAIGCBID
QwYuCg8KCAQAAgYInAgAEgNDBy0KwQEKBAQAAgcSBEgCSS8asgEgT3B0aW9uYWwuIERlZmlu
ZXMgdGhlIG1lY2hhbmlzbSB0byBvYnRhaW4gdGhlIENlcnRpZmljYXRlIEF1dGhvcml0eQog
Y2VydGlmaWNhdGUgdG8gdmFsaWRhdGUgdGhlIHNlcnZlciBjZXJ0aWZpY2F0ZS4gSWYgZW1w
dHksIGNsaWVudCBkb2VzIG5vdAogdmFsaWRhdGUgdGhlIHNlcnZlciBjZXJ0aWZpY2F0ZS4K
CgwKBQQAAgcEEgNIAgoKDAoFBAACBwYSA0gLFwoMCgUEAAIHARIDSBgsCgwKBQQAAgcDEgNI
LzAKDAoFBAACBwgSA0kGLgoPCggEAAIHCJwIABIDSQctCj8KAgQBEgRNAF8BGjMgUmVxdWVz
dCB1c2VkIGJ5IHRoZSBMaXN0Q2xpZW50VGxzUG9saWNpZXMgbWV0aG9kLgoKCgoDBAEBEgNN
CCQKogEKBAQBAgASBFACVQQakwEgUmVxdWlyZWQuIFRoZSBwcm9qZWN0IGFuZCBsb2NhdGlv
biBmcm9tIHdoaWNoIHRoZSBDbGllbnRUbHNQb2xpY2llcyBzaG91bGQKIGJlIGxpc3RlZCwg
c3BlY2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlv
bn1gLgoKDAoFBAECAAUSA1ACCAoMCgUEAQIAARIDUAkPCgwKBQQBAgADEgNQEhMKDQoFBAEC
AAgSBFAUVQMKDwoIBAECAAicCAASA1EEKgoPCgcEAQIACJ8IEgRSBFQFCkYKBAQBAgESA1gC
Fho5IE1heGltdW0gbnVtYmVyIG9mIENsaWVudFRsc1BvbGljaWVzIHRvIHJldHVybiBwZXIg
Y2FsbC4KCgwKBQQBAgEFEgNYAgcKDAoFBAECAQESA1gIEQoMCgUEAQIBAxIDWBQVCtkBCgQE
AQICEgNeAhgaywEgVGhlIHZhbHVlIHJldHVybmVkIGJ5IHRoZSBsYXN0IGBMaXN0Q2xpZW50
VGxzUG9saWNpZXNSZXNwb25zZWAKIEluZGljYXRlcyB0aGF0IHRoaXMgaXMgYSBjb250aW51
YXRpb24gb2YgYSBwcmlvcgogYExpc3RDbGllbnRUbHNQb2xpY2llc2AgY2FsbCwgYW5kIHRo
YXQgdGhlIHN5c3RlbQogc2hvdWxkIHJldHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoM
CgUEAQICBRIDXgIICgwKBQQBAgIBEgNeCRMKDAoFBAECAgMSA14WFwpECgIEAhIEYgBqARo4
IFJlc3BvbnNlIHJldHVybmVkIGJ5IHRoZSBMaXN0Q2xpZW50VGxzUG9saWNpZXMgbWV0aG9k
LgoKCgoDBAIBEgNiCCUKMQoEBAICABIDZAIzGiQgTGlzdCBvZiBDbGllbnRUbHNQb2xpY3kg
cmVzb3VyY2VzLgoKDAoFBAICAAQSA2QCCgoMCgUEAgIABhIDZAsaCgwKBQQCAgABEgNkGy4K
DAoFBAICAAMSA2QxMgroAQoEBAICARIDaQIdGtoBIElmIHRoZXJlIG1pZ2h0IGJlIG1vcmUg
cmVzdWx0cyB0aGFuIHRob3NlIGFwcGVhcmluZyBpbiB0aGlzIHJlc3BvbnNlLCB0aGVuCiBg
bmV4dF9wYWdlX3Rva2VuYCBpcyBpbmNsdWRlZC4gVG8gZ2V0IHRoZSBuZXh0IHNldCBvZiBy
ZXN1bHRzLCBjYWxsIHRoaXMKIG1ldGhvZCBhZ2FpbiB1c2luZyB0aGUgdmFsdWUgb2YgYG5l
eHRfcGFnZV90b2tlbmAgYXMgYHBhZ2VfdG9rZW5gLgoKDAoFBAICAQUSA2kCCAoMCgUEAgIB
ARIDaQkYCgwKBQQCAgEDEgNpGxwKPAoCBAMSBG0AdgEaMCBSZXF1ZXN0IHVzZWQgYnkgdGhl
IEdldENsaWVudFRsc1BvbGljeSBtZXRob2QuCgoKCgMEAwESA20IIQqNAQoEBAMCABIEcAJ1
BBp/IFJlcXVpcmVkLiBBIG5hbWUgb2YgdGhlIENsaWVudFRsc1BvbGljeSB0byBnZXQuIE11
c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y2xpZW50VGxzUG9saWNpZXMvKmAuCgoMCgUEAwIABRIDcAIICgwKBQQDAgABEgNwCQ0KDAoF
BAMCAAMSA3AQEQoNCgUEAwIACBIEcBJ1AwoPCggEAwIACJwIABIDcQQqCg8KBwQDAgAInwgS
BHIEdAUKQAoCBAQSBXkAjAEBGjMgUmVxdWVzdCB1c2VkIGJ5IHRoZSBDcmVhdGVDbGllbnRU
bHNQb2xpY3kgbWV0aG9kLgoKCgoDBAQBEgN5CCQKgAEKBAQEAgASBXwCgQEEGnEgUmVxdWly
ZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIENsaWVudFRsc1BvbGljeS4gTXVzdCBi
ZSBpbgogdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2NhdGlvbnMve2xvY2F0aW9ufWAuCgoM
CgUEBAIABRIDfAIICgwKBQQEAgABEgN8CQ8KDAoFBAQCAAMSA3wSEwoOCgUEBAIACBIFfBSB
AQMKDwoIBAQCAAicCAASA30EKgoQCgcEBAIACJ8IEgV+BIABBQr9AQoEBAQCARIEhwECSxru
ASBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUgQ2xpZW50VGxzUG9saWN5IHJlc291cmNl
IHRvIGJlIGNyZWF0ZWQuIFRoaXMKIHZhbHVlIHNob3VsZCBiZSAxLTYzIGNoYXJhY3RlcnMg
bG9uZywgY29udGFpbmluZyBvbmx5IGxldHRlcnMsIG51bWJlcnMsCiBoeXBoZW5zLCBhbmQg
dW5kZXJzY29yZXMsIGFuZCBzaG91bGQgbm90IHN0YXJ0IHdpdGggYSBudW1iZXIuIEUuZy4K
ICJjbGllbnRfbXRsc19wb2xpY3kiLgoKDQoFBAQCAQUSBIcBAggKDQoFBAQCAQESBIcBCR0K
DQoFBAQCAQMSBIcBICEKDQoFBAQCAQgSBIcBIkoKEAoIBAQCAQicCAASBIcBI0kKQwoEBAQC
AhIGigECiwEvGjMgUmVxdWlyZWQuIENsaWVudFRsc1BvbGljeSByZXNvdXJjZSB0byBiZSBj
cmVhdGVkLgoKDQoFBAQCAgYSBIoBAhEKDQoFBAQCAgESBIoBEiMKDQoFBAQCAgMSBIoBJicK
DQoFBAQCAggSBIsBBi4KEAoIBAQCAgicCAASBIsBBy0KPQoCBAUSBo8BAJwBARovIFJlcXVl
c3QgdXNlZCBieSBVcGRhdGVDbGllbnRUbHNQb2xpY3kgbWV0aG9kLgoKCwoDBAUBEgSPAQgk
CuMCCgQEBQIAEgaWAQKXAS8a0gIgT3B0aW9uYWwuIEZpZWxkIG1hc2sgaXMgdXNlZCB0byBz
cGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBDbGllbnRUbHNQ
b2xpY3kgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4gIFRoZSBmaWVsZHMKIHNwZWNpZmllZCBp
biB0aGUgdXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0
aGUgZnVsbCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMg
aW4gdGhlCiBtYXNrLiBJZiB0aGUgdXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVu
IGFsbCBmaWVsZHMgd2lsbCBiZQogb3ZlcndyaXR0ZW4uCgoNCgUEBQIABhIElgECGwoNCgUE
BQIAARIElgEcJwoNCgUEBQIAAxIElgEqKwoNCgUEBQIACBIElwEGLgoQCggEBQIACJwIABIE
lwEHLQo9CgQEBQIBEgaaAQKbAS8aLSBSZXF1aXJlZC4gVXBkYXRlZCBDbGllbnRUbHNQb2xp
Y3kgcmVzb3VyY2UuCgoNCgUEBQIBBhIEmgECEQoNCgUEBQIBARIEmgESIwoNCgUEBQIBAxIE
mgEmJwoNCgUEBQIBCBIEmwEGLgoQCggEBQIBCJwIABIEmwEHLQpBCgIEBhIGnwEAqAEBGjMg
UmVxdWVzdCB1c2VkIGJ5IHRoZSBEZWxldGVDbGllbnRUbHNQb2xpY3kgbWV0aG9kLgoKCwoD
BAYBEgSfAQgkCpMBCgQEBgIAEgaiAQKnAQQaggEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUg
Q2xpZW50VGxzUG9saWN5IHRvIGRlbGV0ZS4gTXVzdCBiZSBpbgogdGhlIGZvcm1hdCBgcHJv
amVjdHMvKi9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbGllbnRUbHNQb2xpY2llcy8qYC4KCg0K
BQQGAgAFEgSiAQIICg0KBQQGAgABEgSiAQkNCg0KBQQGAgADEgSiARARCg8KBQQGAgAIEgai
ARKnAQMKEAoIBAYCAAicCAASBKMBBCoKEQoHBAYCAAifCBIGpAEEpgEFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy ===
    # Fields for ClientTlsPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networksecurity.v1beta1.ClientTlsPolicy.LabelsEntry)
    # Field: sni Type: 9 ()
    # Field: client_certificate Type: 11 (.google.cloud.networksecurity.v1beta1.CertificateProvider)
    # Field: server_validation_ca Type: 11 (.google.cloud.networksecurity.v1beta1.ValidationCA)

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesRequest ===
    # Fields for ListClientTlsPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesResponse ===
    # Fields for ListClientTlsPoliciesResponse
    # Field: client_tls_policies Type: 11 (.google.cloud.networksecurity.v1beta1.ClientTlsPolicy)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::GetClientTlsPolicyRequest ===
    # Fields for GetClientTlsPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::CreateClientTlsPolicyRequest ===
    # Fields for CreateClientTlsPolicyRequest
    # Field: parent Type: 9 ()
    # Field: client_tls_policy_id Type: 9 ()
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1beta1.ClientTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::UpdateClientTlsPolicyRequest ===
    # Fields for UpdateClientTlsPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: client_tls_policy Type: 11 (.google.cloud.networksecurity.v1beta1.ClientTlsPolicy)

# === Message: Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::DeleteClientTlsPolicyRequest ===
    # Fields for DeleteClientTlsPolicyRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/client_tls_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy;

    my $msg = Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/client_tls_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy

ClientTlsPolicy is a resource that specifies how a client should authenticate
connections to backends of a service. This resource itself does not affect
configuration unless it is attached to a backend service resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the ClientTlsPolicy resource. It matches the pattern
`projects/*/locations/{location}/clientTlsPolicies/{client_tls_policy}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy::LabelsEntry>)

Optional. Set of label tags associated with the resource.

=item * C<< $msg->sni() >> / C<< $msg->sni($value) >>

Type: C<String>

Optional. Server Name Indication string to present to the server during TLS
handshake. E.g: "secure.example.com".

=item * C<< $msg->client_certificate() >> / C<< $msg->client_certificate($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProvider>)

Optional. Defines a mechanism to provision client identity (public and
private keys) for peer to peer authentication. The presence of this
dictates mTLS.

=item * C<< $msg->server_validation_ca() >> / C<< $msg->server_validation_ca($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::ValidationCA>)

Optional. Defines the mechanism to obtain the Certificate Authority
certificate to validate the server certificate. If empty, client does not
validate the server certificate.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesRequest

Request used by the ListClientTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the ClientTlsPolicies should
be listed, specified in the format `projects/*/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of ClientTlsPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListClientTlsPoliciesResponse`
Indicates that this is a continuation of a prior
`ListClientTlsPolicies` call, and that the system
should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ListClientTlsPoliciesResponse

Response returned by the ListClientTlsPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client_tls_policies() >> / C<< $msg->client_tls_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy>)

List of ClientTlsPolicy resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::GetClientTlsPolicyRequest

Request used by the GetClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ClientTlsPolicy to get. Must be in the format
`projects/*/locations/{location}/clientTlsPolicies/*`.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::CreateClientTlsPolicyRequest

Request used by the CreateClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the ClientTlsPolicy. Must be in
the format `projects/*/locations/{location}`.

=item * C<< $msg->client_tls_policy_id() >> / C<< $msg->client_tls_policy_id($value) >>

Type: C<String>

Required. Short name of the ClientTlsPolicy resource to be created. This
value should be 1-63 characters long, containing only letters, numbers,
hyphens, and underscores, and should not start with a number. E.g.
"client_mtls_policy".

=item * C<< $msg->client_tls_policy() >> / C<< $msg->client_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy>)

Required. ClientTlsPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::UpdateClientTlsPolicyRequest

Request used by UpdateClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
ClientTlsPolicy resource by the update.  The fields
specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the
mask. If the user does not provide a mask then all fields will be
overwritten.

=item * C<< $msg->client_tls_policy() >> / C<< $msg->client_tls_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::ClientTlsPolicy>)

Required. Updated ClientTlsPolicy resource.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::DeleteClientTlsPolicyRequest

Request used by the DeleteClientTlsPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the ClientTlsPolicy to delete. Must be in
the format `projects/*/locations/{location}/clientTlsPolicies/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::ClientTlsPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
