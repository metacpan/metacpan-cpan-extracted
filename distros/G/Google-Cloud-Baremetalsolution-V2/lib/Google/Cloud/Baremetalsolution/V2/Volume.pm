package Google::Cloud::Baremetalsolution::V2::Volume;

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
    eval { require Google::Cloud::Baremetalsolution::V2::Common };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvdm9sdW1lLnByb3RvEiFnb29n
bGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9jbG91ZC9iYXJl
bWV0YWxzb2x1dGlvbi92Mi9jb21tb24ucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9t
YXNrLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqsSCgZWb2x1bWUS
FwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEg4KAmlkGAsgASgJUgJpZBJYCgxzdG9yYWdlX3R5
cGUYAiABKA4yNS5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuVm9sdW1lLlN0
b3JhZ2VUeXBlUgtzdG9yYWdlVHlwZRJFCgVzdGF0ZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC5i
YXJlbWV0YWxzb2x1dGlvbi52Mi5Wb2x1bWUuU3RhdGVSBXN0YXRlEiwKEnJlcXVlc3RlZF9z
aXplX2dpYhgEIAEoA1IQcmVxdWVzdGVkU2l6ZUdpYhJBCh1vcmlnaW5hbGx5X3JlcXVlc3Rl
ZF9zaXplX2dpYhgQIAEoA1Iab3JpZ2luYWxseVJlcXVlc3RlZFNpemVHaWISKAoQY3VycmVu
dF9zaXplX2dpYhgFIAEoA1IOY3VycmVudFNpemVHaWISLAoSZW1lcmdlbmN5X3NpemVfZ2li
GA4gASgDUhBlbWVyZ2VuY3lTaXplR2liEiAKDG1heF9zaXplX2dpYhgRIAEoA1IKbWF4U2l6
ZUdpYhItChNhdXRvX2dyb3duX3NpemVfZ2liGAYgASgDUhBhdXRvR3Jvd25TaXplR2liEi4K
E3JlbWFpbmluZ19zcGFjZV9naWIYByABKANSEXJlbWFpbmluZ1NwYWNlR2liEoMBChtzbmFw
c2hvdF9yZXNlcnZhdGlvbl9kZXRhaWwYCCABKAsyQy5nb29nbGUuY2xvdWQuYmFyZW1ldGFs
c29sdXRpb24udjIuVm9sdW1lLlNuYXBzaG90UmVzZXJ2YXRpb25EZXRhaWxSGXNuYXBzaG90
UmVzZXJ2YXRpb25EZXRhaWwShwEKHXNuYXBzaG90X2F1dG9fZGVsZXRlX2JlaGF2aW9yGAkg
ASgOMkQuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZvbHVtZS5TbmFwc2hv
dEF1dG9EZWxldGVCZWhhdmlvclIac25hcHNob3RBdXRvRGVsZXRlQmVoYXZpb3ISTQoGbGFi
ZWxzGAwgAygLMjUuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZvbHVtZS5M
YWJlbHNFbnRyeVIGbGFiZWxzEikKEHNuYXBzaG90X2VuYWJsZWQYDSABKAhSD3NuYXBzaG90
RW5hYmxlZBIVCgNwb2QYDyABKAlCA+BBBVIDcG9kElMKCHByb3RvY29sGBIgASgOMjIuZ29v
Z2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZvbHVtZS5Qcm90b2NvbEID4EEDUghw
cm90b2NvbBIkCgtib290X3ZvbHVtZRgTIAEoCEID4EEDUgpib290Vm9sdW1lEmgKEHBlcmZv
cm1hbmNlX3RpZXIYFCABKA4yOC5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIu
Vm9sdW1lUGVyZm9ybWFuY2VUaWVyQgPgQQVSD3BlcmZvcm1hbmNlVGllchIZCgVub3RlcxgV
IAEoCUID4EEEUgVub3RlcxJkChB3b3JrbG9hZF9wcm9maWxlGBYgASgOMjkuZ29vZ2xlLmNs
b3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZvbHVtZS5Xb3JrbG9hZFByb2ZpbGVSD3dvcmts
b2FkUHJvZmlsZRJACgtleHBpcmVfdGltZRgYIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBCA+BBA1IKZXhwaXJlVGltZRJPCglpbnN0YW5jZXMYGSADKAlCMeBBA/pBKwopYmFy
ZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSCWluc3RhbmNlcxIfCghh
dHRhY2hlZBgaIAEoCEID4EEDUghhdHRhY2hlZBr/AQoZU25hcHNob3RSZXNlcnZhdGlvbkRl
dGFpbBIsChJyZXNlcnZlZF9zcGFjZV9naWIYASABKANSEHJlc2VydmVkU3BhY2VHaWISPQob
cmVzZXJ2ZWRfc3BhY2VfdXNlZF9wZXJjZW50GAIgASgFUhhyZXNlcnZlZFNwYWNlVXNlZFBl
cmNlbnQSPwoccmVzZXJ2ZWRfc3BhY2VfcmVtYWluaW5nX2dpYhgDIAEoA1IZcmVzZXJ2ZWRT
cGFjZVJlbWFpbmluZ0dpYhI0ChZyZXNlcnZlZF9zcGFjZV9wZXJjZW50GAQgASgFUhRyZXNl
cnZlZFNwYWNlUGVyY2VudBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIj0KC1N0b3JhZ2VUeXBlEhwKGFNUT1JBR0VfVFlQRV9V
TlNQRUNJRklFRBAAEgcKA1NTRBABEgcKA0hERBACImEKBVN0YXRlEhUKEVNUQVRFX1VOU1BF
Q0lGSUVEEAASDAoIQ1JFQVRJTkcQARIJCgVSRUFEWRACEgwKCERFTEVUSU5HEAMSDAoIVVBE
QVRJTkcQBBIMCghDT09MX09GRhAFIn0KGlNuYXBzaG90QXV0b0RlbGV0ZUJlaGF2aW9yEi0K
KVNOQVBTSE9UX0FVVE9fREVMRVRFX0JFSEFWSU9SX1VOU1BFQ0lGSUVEEAASDAoIRElTQUJM
RUQQARIQCgxPTERFU1RfRklSU1QQAhIQCgxORVdFU1RfRklSU1QQAyJACghQcm90b2NvbBIY
ChRQUk9UT0NPTF9VTlNQRUNJRklFRBAAEhEKDUZJQlJFX0NIQU5ORUwQARIHCgNORlMQAiJK
Cg9Xb3JrbG9hZFByb2ZpbGUSIAocV09SS0xPQURfUFJPRklMRV9VTlNQRUNJRklFRBAAEgsK
B0dFTkVSSUMQARIICgRIQU5BEAI6ZupBYwonYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBp
cy5jb20vVm9sdW1lEjhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
dm9sdW1lcy97dm9sdW1lfSJXChBHZXRWb2x1bWVSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BB
AvpBKQonYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vVm9sdW1lUgRuYW1lIqsB
ChJMaXN0Vm9sdW1lc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9u
cy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVII
cGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhYKBmZpbHRlchgEIAEo
CVIGZmlsdGVyIqQBChNMaXN0Vm9sdW1lc1Jlc3BvbnNlEkMKB3ZvbHVtZXMYASADKAsyKS5n
b29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuVm9sdW1lUgd2b2x1bWVzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMo
CVILdW5yZWFjaGFibGUimgEKE1VwZGF0ZVZvbHVtZVJlcXVlc3QSRgoGdm9sdW1lGAEgASgL
MikuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLlZvbHVtZUID4EECUgZ2b2x1
bWUSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1
cGRhdGVNYXNrIoMBChNSZW5hbWVWb2x1bWVSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpB
KQonYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBpcy5jb20vVm9sdW1lUgRuYW1lEicKDW5l
d192b2x1bWVfaWQYAiABKAlCA+BBAlILbmV3Vm9sdW1lSWQiWQoSRXZpY3RWb2x1bWVSZXF1
ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonYmFyZW1ldGFsc29sdXRpb24uZ29vZ2xlYXBp
cy5jb20vVm9sdW1lUgRuYW1lInkKE1Jlc2l6ZVZvbHVtZVJlcXVlc3QSRwoGdm9sdW1lGAEg
ASgJQi/gQQL6QSkKJ2JhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL1ZvbHVtZVIG
dm9sdW1lEhkKCHNpemVfZ2liGAIgASgDUgdzaXplR2liQvoBCiVjb20uZ29vZ2xlLmNsb3Vk
LmJhcmVtZXRhbHNvbHV0aW9uLnYyQgtWb2x1bWVQcm90b1ABWlNjbG91ZC5nb29nbGUuY29t
L2dvL2JhcmVtZXRhbHNvbHV0aW9uL2FwaXYyL2JhcmVtZXRhbHNvbHV0aW9ucGI7YmFyZW1l
dGFsc29sdXRpb25wYqoCIUdvb2dsZS5DbG91ZC5CYXJlTWV0YWxTb2x1dGlvbi5WMsoCIUdv
b2dsZVxDbG91ZFxCYXJlTWV0YWxTb2x1dGlvblxWMuoCJEdvb2dsZTo6Q2xvdWQ6OkJhcmVN
ZXRhbFNvbHV0aW9uOjpWMkrHUwoHEgUOAMoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJ
CgIDAxIDFQAqCgkKAgMEEgMWACkKCAoBCBIDGAA+CgkKAgglEgMYAD4KCAoBCBIDGQBqCgkK
AggLEgMZAGoKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAsCgkKAggIEgMbACwKCAoB
CBIDHAA+CgkKAggBEgMcAD4KCAoBCBIDHQA+CgkKAggpEgMdAD4KCAoBCBIDHgA9CgkKAggt
EgMeAD0KIAoCBAASBSEA6AEBGhMgQSBzdG9yYWdlIHZvbHVtZS4KCgoKAwQAARIDIQgOCgsK
AwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBAouCgQEAAQAEgQoAjEDGiAgVGhlIHN0b3JhZ2Ug
dHlwZSBmb3IgYSB2b2x1bWUuCgoMCgUEAAQAARIDKAcSCj0KBgQABAACABIDKgQhGi4gVGhl
IHN0b3JhZ2UgdHlwZSBmb3IgdGhpcyB2b2x1bWUgaXMgdW5rbm93bi4KCg4KBwQABAACAAES
AyoEHAoOCgcEAAQAAgACEgMqHyAKOQoGBAAEAAIBEgMtBAwaKiBUaGUgc3RvcmFnZSB0eXBl
IGZvciB0aGlzIHZvbHVtZSBpcyBTU0QuCgoOCgcEAAQAAgEBEgMtBAcKDgoHBAAEAAIBAhID
LQoLCjoKBgQABAACAhIDMAQMGisgVGhpcyBzdG9yYWdlIHR5cGUgZm9yIHRoaXMgdm9sdW1l
IGlzIEhERC4KCg4KBwQABAACAgESAzAEBwoOCgcEAAQAAgICEgMwCgsKOQoEBAAEARIENAJH
AxorIFRoZSBwb3NzaWJsZSBzdGF0ZXMgZm9yIGEgc3RvcmFnZSB2b2x1bWUuCgoMCgUEAAQB
ARIDNAcMCjsKBgQABAECABIDNgQaGiwgVGhlIHN0b3JhZ2Ugdm9sdW1lIGlzIGluIGFuIHVu
a25vd24gc3RhdGUuCgoOCgcEAAQBAgABEgM2BBUKDgoHBAAEAQIAAhIDNhgZCjUKBgQABAEC
ARIDOQQRGiYgVGhlIHN0b3JhZ2Ugdm9sdW1lIGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQB
AgEBEgM5BAwKDgoHBAAEAQIBAhIDOQ8QCjUKBgQABAECAhIDPAQOGiYgVGhlIHN0b3JhZ2Ug
dm9sdW1lIGlzIHJlYWR5IGZvciB1c2UuCgoOCgcEAAQBAgIBEgM8BAkKDgoHBAAEAQICAhID
PAwNCkUKBgQABAECAxIDPwQRGjYgVGhlIHN0b3JhZ2Ugdm9sdW1lIGhhcyBiZWVuIHJlcXVl
c3RlZCB0byBiZSBkZWxldGVkLgoKDgoHBAAEAQIDARIDPwQMCg4KBwQABAECAwISAz8PEAo1
CgYEAAQBAgQSA0IEERomIFRoZSBzdG9yYWdlIHZvbHVtZSBpcyBiZWluZyB1cGRhdGVkLgoK
DgoHBAAEAQIEARIDQgQMCg4KBwQABAECBAISA0IPEApiCgYEAAQBAgUSA0YEERpTIFRoZSBz
dG9yYWdlIHZvbHVtZSBpcyBpbiBjb29sIG9mZiBzdGF0ZS4gSXQgd2lsbCBiZSBkZWxldGVk
IGFmdGVyCiBgZXhwaXJlX3RpbWVgLgoKDgoHBAAEAQIFARIDRgQMCg4KBwQABAECBQISA0YP
EApZCgQEAAMAEgRKAl4DGksgRGV0YWlscyBhYm91dCBzbmFwc2hvdCBzcGFjZSByZXNlcnZh
dGlvbiBhbmQgdXNhZ2Ugb24gdGhlIHN0b3JhZ2Ugdm9sdW1lLgoKDAoFBAADAAESA0oKIwpX
CgYEAAMAAgASA0wEIRpIIFRoZSBzcGFjZSBvbiB0aGlzIHN0b3JhZ2Ugdm9sdW1lIHJlc2Vy
dmVkIGZvciBzbmFwc2hvdHMsIHNob3duIGluIEdpQi4KCg4KBwQAAwACAAUSA0wECQoOCgcE
AAMAAgABEgNMChwKDgoHBAADAAIAAxIDTB8gCu4BCgYEAAMAAgESA1IEKhreASBUaGUgcGVy
Y2VudCBvZiBzbmFwc2hvdCBzcGFjZSBvbiB0aGlzIHN0b3JhZ2Ugdm9sdW1lIGFjdHVhbGx5
IGJlaW5nIHVzZWQKIGJ5IHRoZSBzbmFwc2hvdCBjb3BpZXMuIFRoaXMgdmFsdWUgbWlnaHQg
YmUgaGlnaGVyIHRoYW4gMTAwJSBpZiB0aGUKIHNuYXBzaG90IGNvcGllcyBoYXZlIG92ZXJm
bG93ZWQgaW50byB0aGUgZGF0YSBwb3J0aW9uIG9mIHRoZSBzdG9yYWdlCiB2b2x1bWUuCgoO
CgcEAAMAAgEFEgNSBAkKDgoHBAADAAIBARIDUgolCg4KBwQAAwACAQMSA1IoKQpqCgYEAAMA
AgISA1YEKxpbIFRoZSBhbW91bnQsIGluIEdpQiwgb2YgYXZhaWxhYmxlIHNwYWNlIGluIHRo
aXMgc3RvcmFnZSB2b2x1bWUncyByZXNlcnZlZAogc25hcHNob3Qgc3BhY2UuCgoOCgcEAAMA
AgIFEgNWBAkKDgoHBAADAAICARIDVgomCg4KBwQAAwACAgMSA1YpKgqgAgoGBAADAAIDEgNd
BCUakAIgUGVyY2VudCBvZiB0aGUgdG90YWwgVm9sdW1lIHNpemUgcmVzZXJ2ZWQgZm9yIHNu
YXBzaG90IGNvcGllcy4KIEVuYWJsaW5nIHNuYXBzaG90cyByZXF1aXJlcyByZXNlcnZpbmcg
MjAlIG9yIG1vcmUgb2YKIHRoZSBzdG9yYWdlIHZvbHVtZSBzcGFjZSBmb3Igc25hcHNob3Rz
LiBNYXhpbXVtIHJlc2VydmVkIHNwYWNlIGZvcgogc25hcHNob3RzIGlzIDQwJS4KIFNldHRp
bmcgdGhpcyBmaWVsZCB3aWxsIGVmZmVjdGl2ZWx5IHNldCBzbmFwc2hvdF9lbmFibGVkIHRv
IHRydWUuCgoOCgcEAAMAAgMFEgNdBAkKDgoHBAADAAIDARIDXQogCg4KBwQAAwACAwMSA10j
JApfCgQEAAQCEgRiAm8DGlEgVGhlIGtpbmRzIG9mIGF1dG8gZGVsZXRlIGJlaGF2aW9yIHRv
IHVzZSB3aGVuIHNuYXBzaG90IHJlc2VydmVkIHNwYWNlIGlzCiBmdWxsLgoKDAoFBAAEAgES
A2IHIQoqCgYEAAQCAgASA2QEMhobIFRoZSB1bnNwZWNpZmllZCBiZWhhdmlvci4KCg4KBwQA
BAICAAESA2QELQoOCgcEAAQCAgACEgNkMDEKggEKBgQABAICARIDaAQRGnMgRG9uJ3QgZGVs
ZXRlIGFueSBzbmFwc2hvdHMuIFRoaXMgZGlzYWJsZXMgbmV3IHNuYXBzaG90IGNyZWF0aW9u
LCBhcwogbG9uZyBhcyB0aGUgc25hcHNob3QgcmVzZXJ2ZWQgc3BhY2UgaXMgZnVsbC4KCg4K
BwQABAICAQESA2gEDAoOCgcEAAQCAgECEgNoDxAKMwoGBAAEAgICEgNrBBUaJCBEZWxldGUg
dGhlIG9sZGVzdCBzbmFwc2hvdHMgZmlyc3QuCgoOCgcEAAQCAgIBEgNrBBAKDgoHBAAEAgIC
AhIDaxMUCjMKBgQABAICAxIDbgQVGiQgRGVsZXRlIHRoZSBuZXdlc3Qgc25hcHNob3RzIGZp
cnN0LgoKDgoHBAAEAgIDARIDbgQQCg4KBwQABAICAwISA24TFAohCgQEAAQDEgRyAnwDGhMg
U3RvcmFnZSBwcm90b2NvbC4KCgwKBQQABAMBEgNyBw8KKAoGBAAEAwIAEgN0BB0aGSBWYWx1
ZSBpcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAAEAwIAARIDdAQYCg4KBwQABAMCAAISA3QbHAoo
CgYEAAQDAgESA3cEFhoZIEZpYnJlIENoYW5uZWwgcHJvdG9jb2wuCgoOCgcEAAQDAgEBEgN3
BBEKDgoHBAAEAwIBAhIDdxQVCnYKBgQABAMCAhIDewQMGmcgTkZTIHByb3RvY29sIG1lYW5z
IFZvbHVtZSBpcyBhIE5GUyBTaGFyZSB2b2x1bWUuCiBTdWNoIHZvbHVtZXMgY2Fubm90IGJl
IG1hbmlwdWxhdGVkIHZpYSBWb2x1bWVzIEFQSS4KCg4KBwQABAMCAgESA3sEBwoOCgcEAAQD
AgICEgN7CgsKPAoEBAAEBBIFfwKIAQMaLSBUaGUgcG9zc2libGUgdmFsdWVzIGZvciBhIHdv
cmtsb2FkIHByb2ZpbGUuCgoMCgUEAAQEARIDfwcWCj4KBgQABAQCABIEgQEEJRouIFRoZSB3
b3JrbG9hZCBwcm9maWxlIGlzIGluIGFuIHVua25vd24gc3RhdGUuCgoPCgcEAAQEAgABEgSB
AQQgCg8KBwQABAQCAAISBIEBIyQKMgoGBAAEBAIBEgSEAQQQGiIgVGhlIHdvcmtsb2FkIHBy
b2ZpbGUgaXMgZ2VuZXJpYy4KCg8KBwQABAQCAQESBIQBBAsKDwoHBAAEBAIBAhIEhAEODwov
CgYEAAQEAgISBIcBBA0aHyBUaGUgd29ya2xvYWQgcHJvZmlsZSBpcyBoYW5hLgoKDwoHBAAE
BAICARIEhwEECAoPCgcEAAQEAgICEgSHAQsMCv8BCgQEAAIAEgSPAQI+GvABIE91dHB1dCBv
bmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGlzIGBWb2x1bWVgLgogUmVzb3VyY2UgbmFt
ZXMgYXJlIHNjaGVtZWxlc3MgVVJJcyB0aGF0IGZvbGxvdyB0aGUgY29udmVudGlvbnMgaW4K
IGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcy4K
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdm9s
dW1lcy97dm9sdW1lfWAKCg0KBQQAAgAFEgSPAQIICg0KBQQAAgABEgSPAQkNCg0KBQQAAgAD
EgSPARARCg0KBQQAAgAIEgSPARI9ChAKCAQAAgAInAgAEgSPARM8CkkKBAQAAgESBJIBAhEa
OyBBbiBpZGVudGlmaWVyIGZvciB0aGUgYFZvbHVtZWAsIGdlbmVyYXRlZCBieSB0aGUgYmFj
a2VuZC4KCg0KBQQAAgEFEgSSAQIICg0KBQQAAgEBEgSSAQkLCg0KBQQAAgEDEgSSAQ4QCjEK
BAQAAgISBJUBAh8aIyBUaGUgc3RvcmFnZSB0eXBlIGZvciB0aGlzIHZvbHVtZS4KCg0KBQQA
AgIGEgSVAQINCg0KBQQAAgIBEgSVAQ4aCg0KBQQAAgIDEgSVAR0eCjEKBAQAAgMSBJgBAhIa
IyBUaGUgc3RhdGUgb2YgdGhpcyBzdG9yYWdlIHZvbHVtZS4KCg0KBQQAAgMGEgSYAQIHCg0K
BQQAAgMBEgSYAQgNCg0KBQQAAgMDEgSYARARCkIKBAQAAgQSBJsBAh8aNCBUaGUgcmVxdWVz
dGVkIHNpemUgb2YgdGhpcyBzdG9yYWdlIHZvbHVtZSwgaW4gR2lCLgoKDQoFBAACBAUSBJsB
AgcKDQoFBAACBAESBJsBCBoKDQoFBAACBAMSBJsBHR4KMgoEBAACBRIEngECKxokIE9yaWdp
bmFsbHkgcmVxdWVzdGVkIHNpemUsIGluIEdpQi4KCg0KBQQAAgUFEgSeAQIHCg0KBQQAAgUB
EgSeAQglCg0KBQQAAgUDEgSeASgqCukBCgQEAAIGEgSjAQIdGtoBIFRoZSBjdXJyZW50IHNp
emUgb2YgdGhpcyBzdG9yYWdlIHZvbHVtZSwgaW4gR2lCLCBpbmNsdWRpbmcgc3BhY2UgcmVz
ZXJ2ZWQKIGZvciBzbmFwc2hvdHMuIFRoaXMgc2l6ZSBtaWdodCBiZSBkaWZmZXJlbnQgdGhh
biB0aGUgcmVxdWVzdGVkIHNpemUgaWYgdGhlCiBzdG9yYWdlIHZvbHVtZSBoYXMgYmVlbiBj
b25maWd1cmVkIHdpdGggYXV0byBncm93IG9yIGF1dG8gc2hyaW5rLgoKDQoFBAACBgUSBKMB
AgcKDQoFBAACBgESBKMBCBgKDQoFBAACBgMSBKMBGxwKfAoEBAACBxIEpwECIBpuIEFkZGl0
aW9uYWwgZW1lcmdlbmN5IHNpemUgdGhhdCB3YXMgcmVxdWVzdGVkIGZvciB0aGlzIFZvbHVt
ZSwgaW4gR2lCLgogY3VycmVudF9zaXplX2dpYiBpbmNsdWRlcyB0aGlzIHZhbHVlLgoKDQoF
BAACBwUSBKcBAgcKDQoFBAACBwESBKcBCBoKDQoFBAACBwMSBKcBHR8KVAoEBAACCBIEqgEC
GhpGIE1heGltdW0gc2l6ZSB2b2x1bWUgY2FuIGJlIGV4cGFuZGVkIHRvIGluIGNhc2Ugb2Yg
ZXZlcmdlbmN5LCBpbiBHaUIuCgoNCgUEAAIIBRIEqgECBwoNCgUEAAIIARIEqgEIFAoNCgUE
AAIIAxIEqgEXGQqaAQoEBAACCRIErgECIBqLASBUaGUgc2l6ZSwgaW4gR2lCLCB0aGF0IHRo
aXMgc3RvcmFnZSB2b2x1bWUgaGFzIGV4cGFuZGVkIGFzIGEgcmVzdWx0IG9mIGFuCiBhdXRv
IGdyb3cgcG9saWN5LiBJbiB0aGUgYWJzZW5jZSBvZiBhdXRvLWdyb3csIHRoZSB2YWx1ZSBp
cyAwLgoKDQoFBAACCQUSBK4BAgcKDQoFBAACCQESBK4BCBsKDQoFBAACCQMSBK4BHh8KeAoE
BAACChIEsgECIBpqIFRoZSBzcGFjZSByZW1haW5pbmcgaW4gdGhlIHN0b3JhZ2Ugdm9sdW1l
IGZvciBuZXcgTFVOcywgaW4gR2lCLCBleGNsdWRpbmcKIHNwYWNlIHJlc2VydmVkIGZvciBz
bmFwc2hvdHMuCgoNCgUEAAIKBRIEsgECBwoNCgUEAAIKARIEsgEIGwoNCgUEAAIKAxIEsgEe
HwpZCgQEAAILEgS1AQI8GksgRGV0YWlscyBhYm91dCBzbmFwc2hvdCBzcGFjZSByZXNlcnZh
dGlvbiBhbmQgdXNhZ2Ugb24gdGhlIHN0b3JhZ2Ugdm9sdW1lLgoKDQoFBAACCwYSBLUBAhsK
DQoFBAACCwESBLUBHDcKDQoFBAACCwMSBLUBOjsKSQoEBAACDBIEuAECPxo7IFRoZSBiZWhh
dmlvciB0byB1c2Ugd2hlbiBzbmFwc2hvdCByZXNlcnZlZCBzcGFjZSBpcyBmdWxsLgoKDQoF
BAACDAYSBLgBAhwKDQoFBAACDAESBLgBHToKDQoFBAACDAMSBLgBPT4KKgoEBAACDRIEuwEC
IhocIExhYmVscyBhcyBrZXkgdmFsdWUgcGFpcnMuCgoNCgUEAAINBhIEuwECFQoNCgUEAAIN
ARIEuwEWHAoNCgUEAAINAxIEuwEfIQouCgQEAAIOEgS+AQIdGiAgV2hldGhlciBzbmFwc2hv
dHMgYXJlIGVuYWJsZWQuCgoNCgUEAAIOBRIEvgECBgoNCgUEAAIOARIEvgEHFwoNCgUEAAIO
AxIEvgEaHAokCgQEAAIPEgTBAQI8GhYgSW1tdXRhYmxlLiBQb2QgbmFtZS4KCg0KBQQAAg8F
EgTBAQIICg0KBQQAAg8BEgTBAQkMCg0KBQQAAg8DEgTBAQ8RCg0KBQQAAg8IEgTBARI7ChAK
CAQAAg8InAgAEgTBARM6Cj0KBAQAAhASBMQBAkUaLyBPdXRwdXQgb25seS4gU3RvcmFnZSBw
cm90b2NvbCBmb3IgdGhlIFZvbHVtZS4KCg0KBQQAAhAGEgTEAQIKCg0KBQQAAhABEgTEAQsT
Cg0KBQQAAhADEgTEARYYCg0KBQQAAhAIEgTEARlEChAKCAQAAhAInAgAEgTEARpDCnMKBAQA
AhESBMgBAkQaZSBPdXRwdXQgb25seS4gV2hldGhlciB0aGlzIHZvbHVtZSBpcyBhIGJvb3Qg
dm9sdW1lLiBBIGJvb3Qgdm9sdW1lIGlzIG9uZQogd2hpY2ggY29udGFpbnMgYSBib290IExV
Ti4KCg0KBQQAAhEFEgTIAQIGCg0KBQQAAhEBEgTIAQcSCg0KBQQAAhEDEgTIARUXCg0KBQQA
AhEIEgTIARhDChAKCAQAAhEInAgAEgTIARlCClAKBAQAAhISBswBAs0BMBpAIEltbXV0YWJs
ZS4gUGVyZm9ybWFuY2UgdGllciBvZiB0aGUgVm9sdW1lLgogRGVmYXVsdCBpcyBTSEFSRUQu
CgoNCgUEAAISBhIEzAECFwoNCgUEAAISARIEzAEYKAoNCgUEAAISAxIEzAErLQoNCgUEAAIS
CBIEzQEGLwoQCggEAAISCJwIABIEzQEHLgp9CgQEAAITEgTRAQI/Gm8gSW5wdXQgb25seS4g
VXNlci1zcGVjaWZpZWQgbm90ZXMgZm9yIG5ldyBWb2x1bWUuCiBVc2VkIHRvIHByb3Zpc2lv
biBWb2x1bWVzIHRoYXQgcmVxdWlyZSBtYW51YWwgaW50ZXJ2ZW50aW9uLgoKDQoFBAACEwUS
BNEBAggKDQoFBAACEwESBNEBCQ4KDQoFBAACEwMSBNEBERMKDQoFBAACEwgSBNEBFD4KEAoI
BAACEwicCAASBNEBFT0KNAoEBAACFBIE1AECKBomIFRoZSB3b3JrbG9hZCBwcm9maWxlIGZv
ciB0aGUgdm9sdW1lLgoKDQoFBAACFAYSBNQBAhEKDQoFBAACFAESBNQBEiIKDQoFBAACFAMS
BNQBJScKfgoEBAACFRIG2AEC2QEyGm4gT3V0cHV0IG9ubHkuIFRpbWUgYWZ0ZXIgd2hpY2gg
dm9sdW1lIHdpbGwgYmUgZnVsbHkgZGVsZXRlZC4KIEl0IGlzIGZpbGxlZCBvbmx5IGZvciB2
b2x1bWVzIGluIENPT0xPRkYgc3RhdGUuCgoNCgUEAAIVBhIE2AECGwoNCgUEAAIVARIE2AEc
JwoNCgUEAAIVAxIE2AEqLAoNCgUEAAIVCBIE2QEGMQoQCggEAAIVCJwIABIE2QEHMAptCgQE
AAIWEgbdAQLiAQQaXSBPdXRwdXQgb25seS4gSW5zdGFuY2VzIHRoaXMgVm9sdW1lIGlzIGF0
dGFjaGVkIHRvLgogVGhpcyBmaWVsZCBpcyBzZXQgb25seSBpbiBHZXQgcmVxdWVzdHMuCgoN
CgUEAAIWBBIE3QECCgoNCgUEAAIWBRIE3QELEQoNCgUEAAIWARIE3QESGwoNCgUEAAIWAxIE
3QEeIAoPCgUEAAIWCBIG3QEh4gEDChAKCAQAAhYInAgAEgTeAQQtChEKBwQAAhYInwgSBt8B
BOEBBQq2AQoEBAACFxIE5wECQRqnASBPdXRwdXQgb25seS4gSXMgdGhlIFZvbHVtZSBhdHRh
Y2hlZCBhdCBhdCBsZWFzdCBvbmUgaW5zdGFuY2UuCiBUaGlzIGZpZWxkIGlzIGEgbGlnaHR3
ZWlnaHQgY291bnRlcnBhcnQgb2YgYGluc3RhbmNlc2AgZmllbGQuCiBJdCBpcyBmaWxsZWQg
aW4gTGlzdCByZXNwb25zZXMgYXMgd2VsbC4KCg0KBQQAAhcFEgTnAQIGCg0KBQQAAhcBEgTn
AQcPCg0KBQQAAhcDEgTnARIUCg0KBQQAAhcIEgTnARVAChAKCAQAAhcInAgAEgTnARY/CkIK
AgQBEgbrAQDzAQEaNCBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIHN0b3JhZ2Ugdm9sdW1lIGlu
Zm9ybWF0aW9uLgoKCwoDBAEBEgTrAQgYCjEKBAQBAgASBu0BAvIBBBohIFJlcXVpcmVkLiBO
YW1lIG9mIHRoZSByZXNvdXJjZS4KCg0KBQQBAgAFEgTtAQIICg0KBQQBAgABEgTtAQkNCg0K
BQQBAgADEgTtARARCg8KBQQBAgAIEgbtARLyAQMKEAoIBAECAAicCAASBO4BBCoKEQoHBAEC
AAifCBIG7wEE8QEFCkEKAgQCEgb2AQCIAgEaMyBNZXNzYWdlIGZvciByZXF1ZXN0aW5nIGEg
bGlzdCBvZiBzdG9yYWdlIHZvbHVtZXMuCgoLCgMEAgESBPYBCBoKQAoEBAICABIG+AEC/QEE
GjAgUmVxdWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgTGlzdFZvbHVtZXNSZXF1ZXN0LgoKDQoF
BAICAAUSBPgBAggKDQoFBAICAAESBPgBCQ8KDQoFBAICAAMSBPgBEhMKDwoFBAICAAgSBvgB
FP0BAwoQCggEAgIACJwIABIE+QEEKgoRCgcEAgIACJ8IEgb6AQT8AQUKkwEKBAQCAgESBIEC
AhYahAEgUmVxdWVzdGVkIHBhZ2Ugc2l6ZS4gVGhlIHNlcnZlciBtaWdodCByZXR1cm4gZmV3
ZXIgaXRlbXMgdGhhbiByZXF1ZXN0ZWQuCiBJZiB1bnNwZWNpZmllZCwgc2VydmVyIHdpbGwg
cGljayBhbiBhcHByb3ByaWF0ZSBkZWZhdWx0LgoKDQoFBAICAQUSBIECAgcKDQoFBAICAQES
BIECCBEKDQoFBAICAQMSBIECFBUKRgoEBAICAhIEhAICGBo4IEEgdG9rZW4gaWRlbnRpZnlp
bmcgYSBwYWdlIG9mIHJlc3VsdHMgZnJvbSB0aGUgc2VydmVyLgoKDQoFBAICAgUSBIQCAggK
DQoFBAICAgESBIQCCRMKDQoFBAICAgMSBIQCFhcKHAoEBAICAxIEhwICFBoOIExpc3QgZmls
dGVyLgoKDQoFBAICAwUSBIcCAggKDQoFBAICAwESBIcCCQ8KDQoFBAICAwMSBIcCEhMKSAoC
BAMSBosCAJQCARo6IFJlc3BvbnNlIG1lc3NhZ2UgY29udGFpbmluZyB0aGUgbGlzdCBvZiBz
dG9yYWdlIHZvbHVtZXMuCgoLCgMEAwESBIsCCBsKLAoEBAMCABIEjQICHhoeIFRoZSBsaXN0
IG9mIHN0b3JhZ2Ugdm9sdW1lcy4KCg0KBQQDAgAEEgSNAgIKCg0KBQQDAgAGEgSNAgsRCg0K
BQQDAgABEgSNAhIZCg0KBQQDAgADEgSNAhwdCkYKBAQDAgESBJACAh0aOCBBIHRva2VuIGlk
ZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIGZyb20gdGhlIHNlcnZlci4KCg0KBQQDAgEF
EgSQAgIICg0KBQQDAgEBEgSQAgkYCg0KBQQDAgEDEgSQAhscCjQKBAQDAgISBJMCAiIaJiBM
b2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQDAgIEEgSTAgIKCg0K
BQQDAgIFEgSTAgsRCg0KBQQDAgIBEgSTAhIdCg0KBQQDAgIDEgSTAiAhCi4KAgQEEgaXAgCi
AgEaICBNZXNzYWdlIGZvciB1cGRhdGluZyBhIHZvbHVtZS4KCgsKAwQEARIElwIIGwqvAQoE
BAQCABIEnAICPRqgASBSZXF1aXJlZC4gVGhlIHZvbHVtZSB0byB1cGRhdGUuCgogVGhlIGBu
YW1lYCBmaWVsZCBpcyB1c2VkIHRvIGlkZW50aWZ5IHRoZSB2b2x1bWUgdG8gdXBkYXRlLgog
Rm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdm9sdW1l
cy97dm9sdW1lfQoKDQoFBAQCAAYSBJwCAggKDQoFBAQCAAESBJwCCQ8KDQoFBAQCAAMSBJwC
EhMKDQoFBAQCAAgSBJwCFDwKEAoIBAQCAAicCAASBJwCFTsKYwoEBAQCARIEoQICLBpVIFRo
ZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUuCiBUaGUgb25seSBjdXJyZW50bHkgc3VwcG9y
dGVkIGZpZWxkcyBhcmU6CiAgICdsYWJlbHMnCgoNCgUEBAIBBhIEoQICGwoNCgUEBAIBARIE
oQIcJwoNCgUEBAIBAxIEoQIqKwo2CgIEBRIGpQIAsQIBGiggTWVzc2FnZSByZXF1ZXN0aW5n
IHJlbmFtZSBvZiBhIHNlcnZlci4KCgsKAwQFARIEpQIIGwqOAQoEBAUCABIGqAICrQIEGn4g
UmVxdWlyZWQuIFRoZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBpZGVudGlmeSB0aGUgdm9s
dW1lLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
dm9sdW1lcy97dm9sdW1lfQoKDQoFBAUCAAUSBKgCAggKDQoFBAUCAAESBKgCCQ0KDQoFBAUC
AAMSBKgCEBEKDwoFBAUCAAgSBqgCEq0CAwoQCggEBQIACJwIABIEqQIEKgoRCgcEBQIACJ8I
EgaqAgSsAgUKNQoEBAUCARIEsAICRBonIFJlcXVpcmVkLiBUaGUgbmV3IGBpZGAgb2YgdGhl
IHZvbHVtZS4KCg0KBQQFAgEFEgSwAgIICg0KBQQFAgEBEgSwAgkWCg0KBQQFAgEDEgSwAhka
Cg0KBQQFAgEIEgSwAhtDChAKCAQFAgEInAgAEgSwAhxCCj4KAgQGEga0AgC8AgEaMCBSZXF1
ZXN0IGZvciBza2lwIHZvbHVtZSBjb29sb2ZmIGFuZCBkZWxldGUgaXQuCgoLCgMEBgESBLQC
CBoKMwoEBAYCABIGtgICuwIEGiMgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBWb2x1bWUu
CgoNCgUEBgIABRIEtgICCAoNCgUEBgIAARIEtgIJDQoNCgUEBgIAAxIEtgIQEQoPCgUEBgIA
CBIGtgISuwIDChAKCAQGAgAInAgAEgS3AgQqChEKBwQGAgAInwgSBrgCBLoCBQo0CgIEBxIG
vwIAygIBGiYgUmVxdWVzdCBmb3IgZW1lcmdlbmN5IHJlc2l6ZSBWb2x1bWUuCgoLCgMEBwES
BL8CCBsKLQoEBAcCABIGwQICxgIEGh0gUmVxdWlyZWQuIFZvbHVtZSB0byByZXNpemUuCgoN
CgUEBwIABRIEwQICCAoNCgUEBwIAARIEwQIJDwoNCgUEBwIAAxIEwQISEwoPCgUEBwIACBIG
wQIUxgIDChAKCAQHAgAInAgAEgTCAgQqChEKBwQHAgAInwgSBsMCBMUCBQooCgQEBwIBEgTJ
AgIVGhogTmV3IFZvbHVtZSBzaXplLCBpbiBHaUIuCgoNCgUEBwIBBRIEyQICBwoNCgUEBwIB
ARIEyQIIEAoNCgUEBwIBAxIEyQITFGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::Volume ===
    # Fields for Volume
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: storage_type Type: 14 (.google.cloud.baremetalsolution.v2.Volume.StorageType)
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.Volume.State)
    # Field: requested_size_gib Type: 3 ()
    # Field: originally_requested_size_gib Type: 3 ()
    # Field: current_size_gib Type: 3 ()
    # Field: emergency_size_gib Type: 3 ()
    # Field: max_size_gib Type: 3 ()
    # Field: auto_grown_size_gib Type: 3 ()
    # Field: remaining_space_gib Type: 3 ()
    # Field: snapshot_reservation_detail Type: 11 (.google.cloud.baremetalsolution.v2.Volume.SnapshotReservationDetail)
    # Field: snapshot_auto_delete_behavior Type: 14 (.google.cloud.baremetalsolution.v2.Volume.SnapshotAutoDeleteBehavior)
    # Field: labels Type: 11 (.google.cloud.baremetalsolution.v2.Volume.LabelsEntry)
    # Field: snapshot_enabled Type: 8 ()
    # Field: pod Type: 9 ()
    # Field: protocol Type: 14 (.google.cloud.baremetalsolution.v2.Volume.Protocol)
    # Field: boot_volume Type: 8 ()
    # Field: performance_tier Type: 14 (.google.cloud.baremetalsolution.v2.VolumePerformanceTier)
    # Field: notes Type: 9 ()
    # Field: workload_profile Type: 14 (.google.cloud.baremetalsolution.v2.Volume.WorkloadProfile)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: instances Type: 9 ()
    # Field: attached Type: 8 ()

# Enum: Volume::StorageType
our $Volume_STORAGE_TYPE_UNSPECIFIED = 0;
our $Volume_SSD = 1;
our $Volume_HDD = 2;

# Enum: Volume::State
our $Volume_STATE_UNSPECIFIED = 0;
our $Volume_CREATING = 1;
our $Volume_READY = 2;
our $Volume_DELETING = 3;
our $Volume_UPDATING = 4;
our $Volume_COOL_OFF = 5;

# Enum: Volume::SnapshotAutoDeleteBehavior
our $Volume_SNAPSHOT_AUTO_DELETE_BEHAVIOR_UNSPECIFIED = 0;
our $Volume_DISABLED = 1;
our $Volume_OLDEST_FIRST = 2;
our $Volume_NEWEST_FIRST = 3;

# Enum: Volume::Protocol
our $Volume_PROTOCOL_UNSPECIFIED = 0;
our $Volume_FIBRE_CHANNEL = 1;
our $Volume_NFS = 2;

# Enum: Volume::WorkloadProfile
our $Volume_WORKLOAD_PROFILE_UNSPECIFIED = 0;
our $Volume_GENERIC = 1;
our $Volume_HANA = 2;

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::GetVolumeRequest ===
    # Fields for GetVolumeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesRequest ===
    # Fields for ListVolumesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesResponse ===
    # Fields for ListVolumesResponse
    # Field: volumes Type: 11 (.google.cloud.baremetalsolution.v2.Volume)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::UpdateVolumeRequest ===
    # Fields for UpdateVolumeRequest
    # Field: volume Type: 11 (.google.cloud.baremetalsolution.v2.Volume)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::RenameVolumeRequest ===
    # Fields for RenameVolumeRequest
    # Field: name Type: 9 ()
    # Field: new_volume_id Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::EvictVolumeRequest ===
    # Fields for EvictVolumeRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Volume::ResizeVolumeRequest ===
    # Fields for ResizeVolumeRequest
    # Field: volume Type: 9 ()
    # Field: size_gib Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Volume - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/volume.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::Volume;

    my $msg = Google::Cloud::Baremetalsolution::V2::Volume::Volume->new({
        name => $name,
        id => $id,
        storage_type => $storage_type,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::Volume::Volume->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/volume.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::Volume::Volume

A storage volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of this `Volume`.
Resource names are schemeless URIs that follow the conventions in
https://cloud.google.com/apis/design/resource_names.
Format:
`projects/{project}/locations/{location}/volumes/{volume}`

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

An identifier for the `Volume`, generated by the backend.

=item * C<< $msg->storage_type() >> / C<< $msg->storage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Volume::StorageType>)

The storage type for this volume.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Volume::State>)

The state of this storage volume.

=item * C<< $msg->requested_size_gib() >> / C<< $msg->requested_size_gib($value) >>

Type: C<Int64>

The requested size of this storage volume, in GiB.

=item * C<< $msg->originally_requested_size_gib() >> / C<< $msg->originally_requested_size_gib($value) >>

Type: C<Int64>

Originally requested size, in GiB.

=item * C<< $msg->current_size_gib() >> / C<< $msg->current_size_gib($value) >>

Type: C<Int64>

The current size of this storage volume, in GiB, including space reserved
for snapshots. This size might be different than the requested size if the
storage volume has been configured with auto grow or auto shrink.

=item * C<< $msg->emergency_size_gib() >> / C<< $msg->emergency_size_gib($value) >>

Type: C<Int64>

Additional emergency size that was requested for this Volume, in GiB.
current_size_gib includes this value.

=item * C<< $msg->max_size_gib() >> / C<< $msg->max_size_gib($value) >>

Type: C<Int64>

Maximum size volume can be expanded to in case of evergency, in GiB.

=item * C<< $msg->auto_grown_size_gib() >> / C<< $msg->auto_grown_size_gib($value) >>

Type: C<Int64>

The size, in GiB, that this storage volume has expanded as a result of an
auto grow policy. In the absence of auto-grow, the value is 0.

=item * C<< $msg->remaining_space_gib() >> / C<< $msg->remaining_space_gib($value) >>

Type: C<Int64>

The space remaining in the storage volume for new LUNs, in GiB, excluding
space reserved for snapshots.

=item * C<< $msg->snapshot_reservation_detail() >> / C<< $msg->snapshot_reservation_detail($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Volume::Volume::SnapshotReservationDetail>)

Details about snapshot space reservation and usage on the storage volume.

=item * C<< $msg->snapshot_auto_delete_behavior() >> / C<< $msg->snapshot_auto_delete_behavior($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Volume::SnapshotAutoDeleteBehavior>)

The behavior to use when snapshot reserved space is full.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Volume::Volume::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->snapshot_enabled() >> / C<< $msg->snapshot_enabled($value) >>

Type: C<Bool>

Whether snapshots are enabled.

=item * C<< $msg->pod() >> / C<< $msg->pod($value) >>

Type: C<String>

Immutable. Pod name.

=item * C<< $msg->protocol() >> / C<< $msg->protocol($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Volume::Protocol>)

Output only. Storage protocol for the Volume.

=item * C<< $msg->boot_volume() >> / C<< $msg->boot_volume($value) >>

Type: C<Bool>

Output only. Whether this volume is a boot volume. A boot volume is one
which contains a boot LUN.

=item * C<< $msg->performance_tier() >> / C<< $msg->performance_tier($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::VolumePerformanceTier>)

Immutable. Performance tier of the Volume.
Default is SHARED.

=item * C<< $msg->notes() >> / C<< $msg->notes($value) >>

Type: C<String>

Input only. User-specified notes for new Volume.
Used to provision Volumes that require manual intervention.

=item * C<< $msg->workload_profile() >> / C<< $msg->workload_profile($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Volume::WorkloadProfile>)

The workload profile for the volume.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time after which volume will be fully deleted.
It is filled only for volumes in COOLOFF state.

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<String>

Output only. Instances this Volume is attached to.
This field is set only in Get requests.

=item * C<< $msg->attached() >> / C<< $msg->attached($value) >>

Type: C<Bool>

Output only. Is the Volume attached at at least one instance.
This field is a lightweight counterpart of `instances` field.
It is filled in List responses as well.

=back

=head3 Enum: Volume::StorageType

=over 4

=item * C<STORAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<SSD> => C<1>

=item * C<HDD> => C<2>

=back

=head3 Enum: Volume::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<DELETING> => C<3>

=item * C<UPDATING> => C<4>

=item * C<COOL_OFF> => C<5>

=back

=head3 Enum: Volume::SnapshotAutoDeleteBehavior

=over 4

=item * C<SNAPSHOT_AUTO_DELETE_BEHAVIOR_UNSPECIFIED> => C<0>

=item * C<DISABLED> => C<1>

=item * C<OLDEST_FIRST> => C<2>

=item * C<NEWEST_FIRST> => C<3>

=back

=head3 Enum: Volume::Protocol

=over 4

=item * C<PROTOCOL_UNSPECIFIED> => C<0>

=item * C<FIBRE_CHANNEL> => C<1>

=item * C<NFS> => C<2>

=back

=head3 Enum: Volume::WorkloadProfile

=over 4

=item * C<WORKLOAD_PROFILE_UNSPECIFIED> => C<0>

=item * C<GENERIC> => C<1>

=item * C<HANA> => C<2>

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::GetVolumeRequest

Message for requesting storage volume information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesRequest

Message for requesting a list of storage volumes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListVolumesRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. The server might return fewer items than requested.
If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::ListVolumesResponse

Response message containing the list of storage volumes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Volume::Volume>)

The list of storage volumes.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::UpdateVolumeRequest

Message for updating a volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume() >> / C<< $msg->volume($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Volume::Volume>)

Required. The volume to update.

The `name` field is used to identify the volume to update.
Format: projects/{project}/locations/{location}/volumes/{volume}

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.
The only currently supported fields are:
  'labels'

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::RenameVolumeRequest

Message requesting rename of a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` field is used to identify the volume.
Format: projects/{project}/locations/{location}/volumes/{volume}

=item * C<< $msg->new_volume_id() >> / C<< $msg->new_volume_id($value) >>

Type: C<String>

Required. The new `id` of the volume.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::EvictVolumeRequest

Request for skip volume cooloff and delete it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Volume.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Volume::ResizeVolumeRequest

Request for emergency resize Volume.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->volume() >> / C<< $msg->volume($value) >>

Type: C<String>

Required. Volume to resize.

=item * C<< $msg->size_gib() >> / C<< $msg->size_gib($value) >>

Type: C<Int64>

New Volume size, in GiB.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::Volume::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
