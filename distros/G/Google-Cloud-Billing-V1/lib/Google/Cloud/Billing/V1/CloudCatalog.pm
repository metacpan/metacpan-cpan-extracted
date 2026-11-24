package Google::Cloud::Billing::V1::CloudCatalog;

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
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Money };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlsbGluZy92MS9jbG91ZF9jYXRhbG9nLnByb3RvEhdnb29nbGUu
Y2xvdWQuYmlsbGluZy52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8aF2dvb2dsZS90eXBlL21vbmV5LnByb3RvIs8BCgdTZXJ2aWNlEhIKBG5hbWUYASABKAlS
BG5hbWUSHQoKc2VydmljZV9pZBgCIAEoCVIJc2VydmljZUlkEiEKDGRpc3BsYXlfbmFtZRgD
IAEoCVILZGlzcGxheU5hbWUSMAoUYnVzaW5lc3NfZW50aXR5X25hbWUYBCABKAlSEmJ1c2lu
ZXNzRW50aXR5TmFtZTo86kE5CiNjbG91ZGJpbGxpbmcuZ29vZ2xlYXBpcy5jb20vU2Vydmlj
ZRISc2VydmljZXMve3NlcnZpY2V9IsUDCgNTa3USEgoEbmFtZRgBIAEoCVIEbmFtZRIVCgZz
a3VfaWQYAiABKAlSBXNrdUlkEiAKC2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhI9
CghjYXRlZ29yeRgEIAEoCzIhLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLkNhdGVnb3J5Ughj
YXRlZ29yeRInCg9zZXJ2aWNlX3JlZ2lvbnMYBSADKAlSDnNlcnZpY2VSZWdpb25zEkcKDHBy
aWNpbmdfaW5mbxgGIAMoCzIkLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLlByaWNpbmdJbmZv
UgtwcmljaW5nSW5mbxIyChVzZXJ2aWNlX3Byb3ZpZGVyX25hbWUYByABKAlSE3NlcnZpY2VQ
cm92aWRlck5hbWUSRwoMZ2VvX3RheG9ub215GAggASgLMiQuZ29vZ2xlLmNsb3VkLmJpbGxp
bmcudjEuR2VvVGF4b25vbXlSC2dlb1RheG9ub215OkPqQUAKH2Nsb3VkYmlsbGluZy5nb29n
bGVhcGlzLmNvbS9Ta3USHXNlcnZpY2VzL3tzZXJ2aWNlfS9za3VzL3tza3V9IqsBCghDYXRl
Z29yeRIwChRzZXJ2aWNlX2Rpc3BsYXlfbmFtZRgBIAEoCVISc2VydmljZURpc3BsYXlOYW1l
EicKD3Jlc291cmNlX2ZhbWlseRgCIAEoCVIOcmVzb3VyY2VGYW1pbHkSJQoOcmVzb3VyY2Vf
Z3JvdXAYAyABKAlSDXJlc291cmNlR3JvdXASHQoKdXNhZ2VfdHlwZRgEIAEoCVIJdXNhZ2VU
eXBlItQCCgtQcmljaW5nSW5mbxJBCg5lZmZlY3RpdmVfdGltZRgBIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSDWVmZmVjdGl2ZVRpbWUSGAoHc3VtbWFyeRgCIAEoCVIHc3Vt
bWFyeRJZChJwcmljaW5nX2V4cHJlc3Npb24YAyABKAsyKi5nb29nbGUuY2xvdWQuYmlsbGlu
Zy52MS5QcmljaW5nRXhwcmVzc2lvblIRcHJpY2luZ0V4cHJlc3Npb24SUwoQYWdncmVnYXRp
b25faW5mbxgEIAEoCzIoLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLkFnZ3JlZ2F0aW9uSW5m
b1IPYWdncmVnYXRpb25JbmZvEjgKGGN1cnJlbmN5X2NvbnZlcnNpb25fcmF0ZRgFIAEoAVIW
Y3VycmVuY3lDb252ZXJzaW9uUmF0ZSLoAwoRUHJpY2luZ0V4cHJlc3Npb24SHQoKdXNhZ2Vf
dW5pdBgBIAEoCVIJdXNhZ2VVbml0EikKEGRpc3BsYXlfcXVhbnRpdHkYAiABKAFSD2Rpc3Bs
YXlRdWFudGl0eRJWCgx0aWVyZWRfcmF0ZXMYAyADKAsyMy5nb29nbGUuY2xvdWQuYmlsbGlu
Zy52MS5QcmljaW5nRXhwcmVzc2lvbi5UaWVyUmF0ZVILdGllcmVkUmF0ZXMSNAoWdXNhZ2Vf
dW5pdF9kZXNjcmlwdGlvbhgEIAEoCVIUdXNhZ2VVbml0RGVzY3JpcHRpb24SGwoJYmFzZV91
bml0GAUgASgJUghiYXNlVW5pdBIyChViYXNlX3VuaXRfZGVzY3JpcHRpb24YBiABKAlSE2Jh
c2VVbml0RGVzY3JpcHRpb24SPQobYmFzZV91bml0X2NvbnZlcnNpb25fZmFjdG9yGAcgASgB
UhhiYXNlVW5pdENvbnZlcnNpb25GYWN0b3IaawoIVGllclJhdGUSLAoSc3RhcnRfdXNhZ2Vf
YW1vdW50GAEgASgBUhBzdGFydFVzYWdlQW1vdW50EjEKCnVuaXRfcHJpY2UYAiABKAsyEi5n
b29nbGUudHlwZS5Nb25leVIJdW5pdFByaWNlIr0DCg9BZ2dyZWdhdGlvbkluZm8SZgoRYWdn
cmVnYXRpb25fbGV2ZWwYASABKA4yOS5nb29nbGUuY2xvdWQuYmlsbGluZy52MS5BZ2dyZWdh
dGlvbkluZm8uQWdncmVnYXRpb25MZXZlbFIQYWdncmVnYXRpb25MZXZlbBJvChRhZ2dyZWdh
dGlvbl9pbnRlcnZhbBgCIAEoDjI8Lmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLkFnZ3JlZ2F0
aW9uSW5mby5BZ2dyZWdhdGlvbkludGVydmFsUhNhZ2dyZWdhdGlvbkludGVydmFsEisKEWFn
Z3JlZ2F0aW9uX2NvdW50GAMgASgFUhBhZ2dyZWdhdGlvbkNvdW50Ik8KEEFnZ3JlZ2F0aW9u
TGV2ZWwSIQodQUdHUkVHQVRJT05fTEVWRUxfVU5TUEVDSUZJRUQQABILCgdBQ0NPVU5UEAES
CwoHUFJPSkVDVBACIlMKE0FnZ3JlZ2F0aW9uSW50ZXJ2YWwSJAogQUdHUkVHQVRJT05fSU5U
RVJWQUxfVU5TUEVDSUZJRUQQABIJCgVEQUlMWRABEgsKB01PTlRITFkQAiKyAQoLR2VvVGF4
b25vbXkSPQoEdHlwZRgBIAEoDjIpLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLkdlb1RheG9u
b215LlR5cGVSBHR5cGUSGAoHcmVnaW9ucxgCIAMoCVIHcmVnaW9ucyJKCgRUeXBlEhQKEFRZ
UEVfVU5TUEVDSUZJRUQQABIKCgZHTE9CQUwQARIMCghSRUdJT05BTBACEhIKDk1VTFRJX1JF
R0lPTkFMEAMiUQoTTGlzdFNlcnZpY2VzUmVxdWVzdBIbCglwYWdlX3NpemUYASABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAiABKAlSCXBhZ2VUb2tlbiJ8ChRMaXN0U2VydmljZXNS
ZXNwb25zZRI8CghzZXJ2aWNlcxgBIAMoCzIgLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLlNl
cnZpY2VSCHNlcnZpY2VzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tl
biKpAgoPTGlzdFNrdXNSZXF1ZXN0EkMKBnBhcmVudBgBIAEoCUIr4EEC+kElCiNjbG91ZGJp
bGxpbmcuZ29vZ2xlYXBpcy5jb20vU2VydmljZVIGcGFyZW50EjkKCnN0YXJ0X3RpbWUYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglzdGFydFRpbWUSNQoIZW5kX3RpbWUY
AyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgdlbmRUaW1lEiMKDWN1cnJlbmN5
X2NvZGUYBCABKAlSDGN1cnJlbmN5Q29kZRIbCglwYWdlX3NpemUYBSABKAVSCHBhZ2VTaXpl
Eh0KCnBhZ2VfdG9rZW4YBiABKAlSCXBhZ2VUb2tlbiJsChBMaXN0U2t1c1Jlc3BvbnNlEjAK
BHNrdXMYASADKAsyHC5nb29nbGUuY2xvdWQuYmlsbGluZy52MS5Ta3VSBHNrdXMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMt4DCgxDbG91ZENhdGFsb2cShAEK
DExpc3RTZXJ2aWNlcxIsLmdvb2dsZS5jbG91ZC5iaWxsaW5nLnYxLkxpc3RTZXJ2aWNlc1Jl
cXVlc3QaLS5nb29nbGUuY2xvdWQuYmlsbGluZy52MS5MaXN0U2VydmljZXNSZXNwb25zZSIX
gtPkkwIOEgwvdjEvc2VydmljZXPaQQASjgEKCExpc3RTa3VzEiguZ29vZ2xlLmNsb3VkLmJp
bGxpbmcudjEuTGlzdFNrdXNSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLmJpbGxpbmcudjEuTGlz
dFNrdXNSZXNwb25zZSItgtPkkwIeEhwvdjEve3BhcmVudD1zZXJ2aWNlcy8qfS9za3Vz2kEG
cGFyZW50GrUBykEbY2xvdWRiaWxsaW5nLmdvb2dsZWFwaXMuY29t0kGTAWh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtYmlsbGluZyxodHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Nsb3VkLWJpbGxpbmcucmVhZG9ubHksaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKNAQobY29tLmdvb2dsZS5jbG91ZC5iaWxs
aW5nLnYxQhFDbG91ZENhdGFsb2dQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2JpbGxp
bmcvYXBpdjEvYmlsbGluZ3BiO2JpbGxpbmdwYqICB0NMRENUTEeqAhdHb29nbGUuQ2xvdWQu
QmlsbGluZy5WMUr8ZQoHEgUOAOoCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWACkKCQoCAwUSAxcAIQoICgEIEgMZADQKCQoCCCUSAxkANAoICgEIEgMa
AEwKCQoCCAsSAxoATAoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADIKCQoCCAgSAxwA
MgoICgEIEgMdADQKCQoCCAESAx0ANAoICgEIEgMeACUKCQoCCCQSAx4AJQqcAQoCBgASBCMA
OQEajwEgQSBjYXRhbG9nIG9mIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBzZXJ2aWNlcyBhbmQg
U0tVcy4KIFByb3ZpZGVzIHByaWNpbmcgaW5mb3JtYXRpb24gYW5kIG1ldGFkYXRhIG9uIEdv
b2dsZSBDbG91ZCBQbGF0Zm9ybSBzZXJ2aWNlcwogYW5kIFNLVXMuCgoKCgMGAAESAyMIFAoK
CgMGAAMSAyQCQwoMCgUGAAOZCBIDJAJDCgsKAwYAAxIEJQIoNwoNCgUGAAOaCBIEJQIoNwow
CgQGAAIAEgQrAjADGiIgTGlzdHMgYWxsIHB1YmxpYyBjbG91ZCBzZXJ2aWNlcy4KCgwKBQYA
AgABEgMrBhIKDAoFBgACAAISAysTJgoMCgUGAAIAAxIDKzFFCg0KBQYAAgAEEgQsBC4GChEK
CQYAAgAEsMq8IhIELAQuBgoMCgUGAAIABBIDLwQuCg8KCAYAAgAEmwgAEgMvBC4KTAoEBgAC
ARIEMwI4Axo+IExpc3RzIGFsbCBwdWJsaWNseSBhdmFpbGFibGUgU0tVcyBmb3IgYSBnaXZl
biBjbG91ZCBzZXJ2aWNlLgoKDAoFBgACAQESAzMGDgoMCgUGAAIBAhIDMw8eCgwKBQYAAgED
EgMzKTkKDQoFBgACAQQSBDQENgYKEQoJBgACAQSwyrwiEgQ0BDYGCgwKBQYAAgEEEgM3BDQK
DwoIBgACAQSbCAASAzcENApFCgIEABIEPABQARo5IEVuY2Fwc3VsYXRlcyBhIHNpbmdsZSBz
ZXJ2aWNlIGluIEdvb2dsZSBDbG91ZCBQbGF0Zm9ybS4KCgoKAwQAARIDPAgPCgsKAwQABxIE
PQJABAoNCgUEAAedCBIEPQJABApVCgQEAAIAEgNEAhIaSCBUaGUgcmVzb3VyY2UgbmFtZSBm
b3IgdGhlIHNlcnZpY2UuCiBFeGFtcGxlOiAic2VydmljZXMvNkY4MS01ODQ0LTQ1NkEiCgoM
CgUEAAIABRIDRAIICgwKBQQAAgABEgNECQ0KDAoFBAACAAMSA0QQEQpJCgQEAAIBEgNIAhga
PCBUaGUgaWRlbnRpZmllciBmb3IgdGhlIHNlcnZpY2UuCiBFeGFtcGxlOiAiNkY4MS01ODQ0
LTQ1NkEiCgoMCgUEAAIBBRIDSAIICgwKBQQAAgEBEgNICRMKDAoFBAACAQMSA0gWFwo+CgQE
AAICEgNLAhoaMSBBIGh1bWFuIHJlYWRhYmxlIGRpc3BsYXkgbmFtZSBmb3IgdGhpcyBzZXJ2
aWNlLgoKDAoFBAACAgUSA0sCCAoMCgUEAAICARIDSwkVCgwKBQQAAgIDEgNLGBkKdAoEBAAC
AxIDTwIiGmcgVGhlIGJ1c2luZXNzIHVuZGVyIHdoaWNoIHRoZSBzZXJ2aWNlIGlzIG9mZmVy
ZWQuCiBFeC4gImJ1c2luZXNzRW50aXRpZXMvR0NQIiwgImJ1c2luZXNzRW50aXRpZXMvTWFw
cyIKCgwKBQQAAgMFEgNPAggKDAoFBAACAwESA08JHQoMCgUEAAIDAxIDTyAhCjcKAgQBEgRT
AHYBGisgRW5jYXBzdWxhdGVzIGEgc2luZ2xlIFNLVSBpbiBHb29nbGUgQ2xvdWQKCgoKAwQB
ARIDUwgLCgsKAwQBBxIEVAJXBAoNCgUEAQedCBIEVAJXBAplCgQEAQIAEgNbAhIaWCBUaGUg
cmVzb3VyY2UgbmFtZSBmb3IgdGhlIFNLVS4KIEV4YW1wbGU6ICJzZXJ2aWNlcy82RjgxLTU4
NDQtNDU2QS9za3VzL0QwNDEtQjhBMS02RTBCIgoKDAoFBAECAAUSA1sCCAoMCgUEAQIAARID
WwkNCgwKBQQBAgADEgNbEBEKRQoEBAECARIDXwIUGjggVGhlIGlkZW50aWZpZXIgZm9yIHRo
ZSBTS1UuCiBFeGFtcGxlOiAiRDA0MS1COEExLTZFMEIiCgoMCgUEAQIBBRIDXwIICgwKBQQB
AgEBEgNfCQ8KDAoFBAECAQMSA18SEwpgCgQEAQICEgNjAhkaUyBBIGh1bWFuIHJlYWRhYmxl
IGRlc2NyaXB0aW9uIG9mIHRoZSBTS1UsIGhhcyBhIG1heGltdW0gbGVuZ3RoIG9mIDI1Ngog
Y2hhcmFjdGVycy4KCgwKBQQBAgIFEgNjAggKDAoFBAECAgESA2MJFAoMCgUEAQICAxIDYxcY
ClUKBAQBAgMSA2YCGBpIIFRoZSBjYXRlZ29yeSBoaWVyYXJjaHkgb2YgdGhpcyBTS1UsIHB1
cmVseSBmb3Igb3JnYW5pemF0aW9uYWwgcHVycG9zZS4KCgwKBQQBAgMGEgNmAgoKDAoFBAEC
AwESA2YLEwoMCgUEAQIDAxIDZhYXCqEBCgQEAQIEEgNrAiYakwEgTGlzdCBvZiBzZXJ2aWNl
IHJlZ2lvbnMgdGhpcyBTS1UgaXMgb2ZmZXJlZCBhdC4KIEV4YW1wbGU6ICJhc2lhLWVhc3Qx
IgogU2VydmljZSByZWdpb25zIGNhbiBiZSBmb3VuZCBhdCBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYWJvdXQvbG9jYXRpb25zLwoKDAoFBAECBAQSA2sCCgoMCgUEAQIEBRIDawsRCgwK
BQQBAgQBEgNrEiEKDAoFBAECBAMSA2skJQpOCgQEAQIFEgNuAigaQSBBIHRpbWVsaW5lIG9m
IHByaWNpbmcgaW5mbyBmb3IgdGhpcyBTS1UgaW4gY2hyb25vbG9naWNhbCBvcmRlci4KCgwK
BQQBAgUEEgNuAgoKDAoFBAECBQYSA24LFgoMCgUEAQIFARIDbhcjCgwKBQQBAgUDEgNuJicK
dAoEBAECBhIDcgIjGmcgSWRlbnRpZmllcyB0aGUgc2VydmljZSBwcm92aWRlci4KIFRoaXMg
aXMgJ0dvb2dsZScgZm9yIGZpcnN0IHBhcnR5IHNlcnZpY2VzIGluIEdvb2dsZSBDbG91ZCBQ
bGF0Zm9ybS4KCgwKBQQBAgYFEgNyAggKDAoFBAECBgESA3IJHgoMCgUEAQIGAxIDciEiCjQK
BAQBAgcSA3UCHxonIFRoZSBnZW9ncmFwaGljIHRheG9ub215IGZvciB0aGlzIHNrdS4KCgwK
BQQBAgcGEgN1Ag0KDAoFBAECBwESA3UOGgoMCgUEAQIHAxIDdR0eCjoKAgQCEgV5AIgBARot
IFJlcHJlc2VudHMgdGhlIGNhdGVnb3J5IGhpZXJhcmNoeSBvZiBhIFNLVS4KCgoKAwQCARID
eQgQCkMKBAQCAgASA3sCIho2IFRoZSBkaXNwbGF5IG5hbWUgb2YgdGhlIHNlcnZpY2UgdGhp
cyBTS1UgYmVsb25ncyB0by4KCgwKBQQCAgAFEgN7AggKDAoFBAICAAESA3sJHQoMCgUEAgIA
AxIDeyAhCnsKBAQCAgESA38CHRpuIFRoZSB0eXBlIG9mIHByb2R1Y3QgdGhlIFNLVSByZWZl
cnMgdG8uCiBFeGFtcGxlOiAiQ29tcHV0ZSIsICJTdG9yYWdlIiwgIk5ldHdvcmsiLCAiQXBw
bGljYXRpb25TZXJ2aWNlcyIgZXRjLgoKDAoFBAICAQUSA38CCAoMCgUEAgIBARIDfwkYCgwK
BQQCAgEDEgN/GxwKeQoEBAICAhIEgwECHBprIEEgZ3JvdXAgY2xhc3NpZmljYXRpb24gZm9y
IHJlbGF0ZWQgU0tVcy4KIEV4YW1wbGU6ICJSQU0iLCAiR1BVIiwgIlByZWRpY3Rpb24iLCAi
T3BzIiwgIkdvb2dsZUVncmVzcyIgZXRjLgoKDQoFBAICAgUSBIMBAggKDQoFBAICAgESBIMB
CRcKDQoFBAICAgMSBIMBGhsKdgoEBAICAxIEhwECGBpoIFJlcHJlc2VudHMgaG93IHRoZSBT
S1UgaXMgY29uc3VtZWQuCiBFeGFtcGxlOiAiT25EZW1hbmQiLCAiUHJlZW1wdGlibGUiLCAi
Q29tbWl0MU1vIiwgIkNvbW1pdDFZciIgZXRjLgoKDQoFBAICAwUSBIcBAggKDQoFBAICAwES
BIcBCRMKDQoFBAICAwMSBIcBFhcKVwoCBAMSBosBAKUBARpJIFJlcHJlc2VudHMgdGhlIHBy
aWNpbmcgaW5mb3JtYXRpb24gZm9yIGEgU0tVIGF0IGEgc2luZ2xlIHBvaW50IG9mIHRpbWUu
CgoLCgMEAwESBIsBCBMKiAMKBAQDAgASBJIBAi8a+QIgVGhlIHRpbWVzdGFtcCBmcm9tIHdo
aWNoIHRoaXMgcHJpY2luZyB3YXMgZWZmZWN0aXZlIHdpdGhpbiB0aGUgcmVxdWVzdGVkCiB0
aW1lIHJhbmdlLiBUaGlzIGlzIGd1YXJhbnRlZWQgdG8gYmUgZ3JlYXRlciB0aGFuIG9yIGVx
dWFsIHRvIHRoZQogc3RhcnRfdGltZSBmaWVsZCBpbiB0aGUgcmVxdWVzdCBhbmQgbGVzcyB0
aGFuIHRoZSBlbmRfdGltZSBmaWVsZCBpbiB0aGUKIHJlcXVlc3QuIElmIGEgdGltZSByYW5n
ZSB3YXMgbm90IHNwZWNpZmllZCBpbiB0aGUgcmVxdWVzdCB0aGlzIGZpZWxkIHdpbGwKIGJl
IGVxdWl2YWxlbnQgdG8gYSB0aW1lIHdpdGhpbiB0aGUgbGFzdCAxMiBob3VycywgaW5kaWNh
dGluZyB0aGUgbGF0ZXN0CiBwcmljaW5nIGluZm8uCgoNCgUEAwIABhIEkgECGwoNCgUEAwIA
ARIEkgEcKgoNCgUEAwIAAxIEkgEtLgp3CgQEAwIBEgSWAQIVGmkgQW4gb3B0aW9uYWwgaHVt
YW4gcmVhZGFibGUgc3VtbWFyeSBvZiB0aGUgcHJpY2luZyBpbmZvcm1hdGlvbiwgaGFzIGEK
IG1heGltdW0gbGVuZ3RoIG9mIDI1NiBjaGFyYWN0ZXJzLgoKDQoFBAMCAQUSBJYBAggKDQoF
BAMCAQESBJYBCRAKDQoFBAMCAQMSBJYBExQKVgoEBAMCAhIEmQECKxpIIEV4cHJlc3NlcyB0
aGUgcHJpY2luZyBmb3JtdWxhLiBTZWUgYFByaWNpbmdFeHByZXNzaW9uYCBmb3IgYW4gZXhh
bXBsZS4KCg0KBQQDAgIGEgSZAQITCg0KBQQDAgIBEgSZARQmCg0KBQQDAgIDEgSZASkqCnYK
BAQDAgMSBJ0BAicaaCBBZ2dyZWdhdGlvbiBJbmZvLiBUaGlzIGNhbiBiZSBsZWZ0IHVuc3Bl
Y2lmaWVkIGlmIHRoZSBwcmljaW5nIGV4cHJlc3Npb24KIGRvZXNuJ3QgcmVxdWlyZSBhZ2dy
ZWdhdGlvbi4KCg0KBQQDAgMGEgSdAQIRCg0KBQQDAgMBEgSdARIiCg0KBQQDAgMDEgSdASUm
Cq4CCgQEAwIEEgSkAQImGp8CIENvbnZlcnNpb24gcmF0ZSB1c2VkIGZvciBjdXJyZW5jeSBj
b252ZXJzaW9uLCBmcm9tIFVTRCB0byB0aGUgY3VycmVuY3kKIHNwZWNpZmllZCBpbiB0aGUg
cmVxdWVzdC4gVGhpcyBpbmNsdWRlcyBhbnkgc3VyY2hhcmdlIGNvbGxlY3RlZCBmb3IgYmls
bGluZwogaW4gbm9uIFVTRCBjdXJyZW5jeS4gSWYgYSBjdXJyZW5jeSBpcyBub3Qgc3BlY2lm
aWVkIGluIHRoZSByZXF1ZXN0IHRoaXMKIGRlZmF1bHRzIHRvIDEuMC4KIEV4YW1wbGU6IFVT
RCAqIGN1cnJlbmN5X2NvbnZlcnNpb25fcmF0ZSA9IEpQWQoKDQoFBAMCBAUSBKQBAggKDQoF
BAMCBAESBKQBCSEKDQoFBAMCBAMSBKQBJCUK5wIKAgQEEgaxAQDjAQEa2AIgRXhwcmVzc2Vz
IGEgbWF0aGVtYXRpY2FsIHByaWNpbmcgZm9ybXVsYS4gRm9yIEV4YW1wbGU6LQoKIGB1c2Fn
ZV91bml0OiBHQnlgCiBgdGllcmVkX3JhdGVzOmAKICAgIGBbc3RhcnRfdXNhZ2VfYW1vdW50
OiAyMCwgdW5pdF9wcmljZTogJDEwXWAKICAgIGBbc3RhcnRfdXNhZ2VfYW1vdW50OiAxMDAs
IHVuaXRfcHJpY2U6ICQ1XWAKCiBUaGUgYWJvdmUgZXhwcmVzc2VzIGEgcHJpY2luZyBmb3Jt
dWxhIHdoZXJlIHRoZSBmaXJzdCAyMEdCIGlzIGZyZWUsIHRoZQogbmV4dCA4MEdCIGlzIHBy
aWNlZCBhdCAkMTAgcGVyIEdCIGZvbGxvd2VkIGJ5ICQ1IHBlciBHQiBmb3IgYWRkaXRpb25h
bAogdXNhZ2UuCgoLCgMEBAESBLEBCBkKVwoEBAQDABIGswECvAEDGkcgVGhlIHByaWNlIHJh
dGUgaW5kaWNhdGluZyBzdGFydGluZyB1c2FnZSBhbmQgaXRzIGNvcnJlc3BvbmRpbmcgcHJp
Y2UuCgoNCgUEBAMAARIEswEKEgrFAQoGBAQDAAIAEgS3AQQiGrQBIFVzYWdlIGlzIHByaWNl
ZCBhdCB0aGlzIHJhdGUgb25seSBhZnRlciB0aGlzIGFtb3VudC4KIEV4YW1wbGU6IHN0YXJ0
X3VzYWdlX2Ftb3VudCBvZiAxMCBpbmRpY2F0ZXMgdGhhdCB0aGUgdXNhZ2Ugd2lsbCBiZSBw
cmljZWQKIGF0IHRoZSB1bml0X3ByaWNlIGFmdGVyIHRoZSBmaXJzdCAxMCB1c2FnZV91bml0
cy4KCg8KBwQEAwACAAUSBLcBBAoKDwoHBAQDAAIAARIEtwELHQoPCgcEBAMAAgADEgS3ASAh
CnkKBgQEAwACARIEuwEEJRppIFRoZSBwcmljZSBwZXIgdW5pdCBvZiB1c2FnZS4KIEV4YW1w
bGU6IHVuaXRfcHJpY2Ugb2YgYW1vdW50ICQxMCBpbmRpY2F0ZXMgdGhhdCBlYWNoIHVuaXQg
d2lsbCBjb3N0ICQxMC4KCg8KBwQEAwACAQYSBLsBBBUKDwoHBAQDAAIBARIEuwEWIAoPCgcE
BAMAAgEDEgS7ASMkCpwBCgQEBAIAEgTAAQIYGo0BIFRoZSBzaG9ydCBoYW5kIGZvciB1bml0
IG9mIHVzYWdlIHRoaXMgcHJpY2luZyBpcyBzcGVjaWZpZWQgaW4uCiBFeGFtcGxlOiB1c2Fn
ZV91bml0IG9mICJHaUJ5IiBtZWFucyB0aGF0IHVzYWdlIGlzIHNwZWNpZmllZCBpbiAiR2li
aSBCeXRlIi4KCg0KBQQEAgAFEgTAAQIICg0KBQQEAgABEgTAAQkTCg0KBQQEAgADEgTAARYX
CtsDCgQEBAIBEgTKAQIeGswDIFRoZSByZWNvbW1lbmRlZCBxdWFudGl0eSBvZiB1bml0cyBm
b3IgZGlzcGxheWluZyBwcmljaW5nIGluZm8uIFdoZW4KIGRpc3BsYXlpbmcgcHJpY2luZyBp
bmZvIGl0IGlzIHJlY29tbWVuZGVkIHRvIGRpc3BsYXk6CiAodW5pdF9wcmljZSAqIGRpc3Bs
YXlfcXVhbnRpdHkpIHBlciBkaXNwbGF5X3F1YW50aXR5IHVzYWdlX3VuaXQuCiBUaGlzIGZp
ZWxkIGRvZXMgbm90IGFmZmVjdCB0aGUgcHJpY2luZyBmb3JtdWxhIGFuZCBpcyBmb3IgZGlz
cGxheSBwdXJwb3Nlcwogb25seS4KIEV4YW1wbGU6IElmIHRoZSB1bml0X3ByaWNlIGlzICIw
LjAwMDEgVVNEIiwgdGhlIHVzYWdlX3VuaXQgaXMgIkdCIiBhbmQKIHRoZSBkaXNwbGF5X3F1
YW50aXR5IGlzICIxMDAwIiB0aGVuIHRoZSByZWNvbW1lbmRlZCB3YXkgb2YgZGlzcGxheWlu
ZyB0aGUKIHByaWNpbmcgaW5mbyBpcyAiMC4xMCBVU0QgcGVyIDEwMDAgR0IiCgoNCgUEBAIB
BRIEygECCAoNCgUEBAIBARIEygEJGQoNCgUEBAIBAxIEygEcHQrOAQoEBAQCAhIEzwECJRq/
ASBUaGUgbGlzdCBvZiB0aWVyZWQgcmF0ZXMgZm9yIHRoaXMgcHJpY2luZy4gVGhlIHRvdGFs
IGNvc3QgaXMgY29tcHV0ZWQgYnkKIGFwcGx5aW5nIGVhY2ggb2YgdGhlIHRpZXJlZCByYXRl
cyBvbiB1c2FnZS4gVGhpcyByZXBlYXRlZCBsaXN0IGlzIHNvcnRlZAogYnkgYXNjZW5kaW5n
IG9yZGVyIG9mIHN0YXJ0X3VzYWdlX2Ftb3VudC4KCg0KBQQEAgIEEgTPAQIKCg0KBQQEAgIG
EgTPAQsTCg0KBQQEAgIBEgTPARQgCg0KBQQEAgIDEgTPASMkClAKBAQEAgMSBNMBAiQaQiBU
aGUgdW5pdCBvZiB1c2FnZSBpbiBodW1hbiByZWFkYWJsZSBmb3JtLgogRXhhbXBsZTogImdp
YmkgYnl0ZSIuCgoNCgUEBAIDBRIE0wECCAoNCgUEBAIDARIE0wEJHwoNCgUEBAIDAxIE0wEi
IwphCgQEBAIEEgTXAQIXGlMgVGhlIGJhc2UgdW5pdCBmb3IgdGhlIFNLVSB3aGljaCBpcyB0
aGUgdW5pdCB1c2VkIGluIHVzYWdlIGV4cG9ydHMuCiBFeGFtcGxlOiAiQnkiCgoNCgUEBAIE
BRIE1wECCAoNCgUEBAIEARIE1wEJEgoNCgUEBAIEAxIE1wEVFgpHCgQEBAIFEgTbAQIjGjkg
VGhlIGJhc2UgdW5pdCBpbiBodW1hbiByZWFkYWJsZSBmb3JtLgogRXhhbXBsZTogImJ5dGUi
LgoKDQoFBAQCBQUSBNsBAggKDQoFBAQCBQESBNsBCR4KDQoFBAQCBQMSBNsBISIKtgIKBAQE
AgYSBOIBAikapwIgQ29udmVyc2lvbiBmYWN0b3IgZm9yIGNvbnZlcnRpbmcgZnJvbSBwcmlj
ZSBwZXIgdXNhZ2VfdW5pdCB0byBwcmljZSBwZXIKIGJhc2VfdW5pdCwgYW5kIHN0YXJ0X3Vz
YWdlX2Ftb3VudCB0byBzdGFydF91c2FnZV9hbW91bnQgaW4gYmFzZV91bml0LgogdW5pdF9w
cmljZSAvIGJhc2VfdW5pdF9jb252ZXJzaW9uX2ZhY3RvciA9IHByaWNlIHBlciBiYXNlX3Vu
aXQuCiBzdGFydF91c2FnZV9hbW91bnQgKiBiYXNlX3VuaXRfY29udmVyc2lvbl9mYWN0b3Ig
PSBzdGFydF91c2FnZV9hbW91bnQgaW4KIGJhc2VfdW5pdC4KCg0KBQQEAgYFEgTiAQIICg0K
BQQEAgYBEgTiAQkkCg0KBQQEAgYDEgTiAScoCloKAgQFEgbmAQCFAgEaTCBSZXByZXNlbnRz
IHRoZSBhZ2dyZWdhdGlvbiBsZXZlbCBhbmQgaW50ZXJ2YWwgZm9yIHByaWNpbmcgb2YgYSBz
aW5nbGUgU0tVLgoKCwoDBAUBEgTmAQgXCtABCgQEBQQAEgbqAQLwAQMavwEgVGhlIGxldmVs
IGF0IHdoaWNoIHVzYWdlIGlzIGFnZ3JlZ2F0ZWQgdG8gY29tcHV0ZSBjb3N0LgogRXhhbXBs
ZTogIkFDQ09VTlQiIGFnZ3JlZ2F0aW9uIGxldmVsIGluZGljYXRlcyB0aGF0IHVzYWdlIGZv
ciB0aWVyZWQKIHByaWNpbmcgaXMgYWdncmVnYXRlZCBhY3Jvc3MgYWxsIHByb2plY3RzIGlu
IGEgc2luZ2xlIGFjY291bnQuCgoNCgUEBQQAARIE6gEHFwoOCgYEBQQAAgASBOsBBCYKDwoH
BAUEAAIAARIE6wEEIQoPCgcEBQQAAgACEgTrASQlCg4KBgQFBAACARIE7QEEEAoPCgcEBQQA
AgEBEgTtAQQLCg8KBwQFBAACAQISBO0BDg8KDgoGBAUEAAICEgTvAQQQCg8KBwQFBAACAgES
BO8BBAsKDwoHBAUEAAICAhIE7wEODwq6AQoEBAUEARIG9QEC+wEDGqkBIFRoZSBpbnRlcnZh
bCBhdCB3aGljaCB1c2FnZSBpcyBhZ2dyZWdhdGVkIHRvIGNvbXB1dGUgY29zdC4KIEV4YW1w
bGU6ICJNT05USExZIiBhZ2dyZWdhdGlvbiBpbnRlcnZhbCBpbmRpY2F0ZXMgdGhhdCB1c2Fn
ZSBmb3IgdGllcmVkCiBwcmljaW5nIGlzIGFnZ3JlZ2F0ZWQgZXZlcnkgbW9udGguCgoNCgUE
BQQBARIE9QEHGgoOCgYEBQQBAgASBPYBBCkKDwoHBAUEAQIAARIE9gEEJAoPCgcEBQQBAgAC
EgT2AScoCg4KBgQFBAECARIE+AEEDgoPCgcEBQQBAgEBEgT4AQQJCg8KBwQFBAECAQISBPgB
DA0KDgoGBAUEAQICEgT6AQQQCg8KBwQFBAECAgESBPoBBAsKDwoHBAUEAQICAhIE+gEODwoM
CgQEBQIAEgT9AQIpCg0KBQQFAgAGEgT9AQISCg0KBQQFAgABEgT9ARMkCg0KBQQFAgADEgT9
AScoCgwKBAQFAgESBP8BAi8KDQoFBAUCAQYSBP8BAhUKDQoFBAUCAQESBP8BFioKDQoFBAUC
AQMSBP8BLS4KpQEKBAQFAgISBIQCAh4algEgVGhlIG51bWJlciBvZiBpbnRlcnZhbHMgdG8g
YWdncmVnYXRlIG92ZXIuCiBFeGFtcGxlOiBJZiBhZ2dyZWdhdGlvbl9sZXZlbCBpcyAiREFJ
TFkiIGFuZCBhZ2dyZWdhdGlvbl9jb3VudCBpcyAxNCwKIGFnZ3JlZ2F0aW9uIHdpbGwgYmUg
b3ZlciAxNCBkYXlzLgoKDQoFBAUCAgUSBIQCAgcKDQoFBAUCAgESBIQCCBkKDQoFBAUCAgMS
BIQCHB0KRAoCBAYSBogCAKACARo2IEVuY2Fwc3VsYXRlcyB0aGUgZ2VvZ3JhcGhpYyB0YXhv
bm9teSBkYXRhIGZvciBhIHNrdS4KCgsKAwQGARIEiAIIEwpQCgQEBgQAEgaKAgKYAgMaQCBU
aGUgdHlwZSBvZiBHZW8gVGF4b25vbXk6IEdMT0JBTCwgUkVHSU9OQUwsIG9yIE1VTFRJX1JF
R0lPTkFMLgoKDQoFBAYEAAESBIoCBwsKLAoGBAYEAAIAEgSMAgQZGhwgVGhlIHR5cGUgaXMg
bm90IHNwZWNpZmllZC4KCg8KBwQGBAACAAESBIwCBBQKDwoHBAYEAAIAAhIEjAIXGAqPAQoG
BAYEAAIBEgSQAgQPGn8gVGhlIHNrdSBpcyBnbG9iYWwgaW4gbmF0dXJlLCBlLmcuIGEgbGlj
ZW5zZSBza3UuIEdsb2JhbCBza3VzIGFyZQogYXZhaWxhYmxlIGluIGFsbCByZWdpb25zLCBh
bmQgc28gaGF2ZSBhbiBlbXB0eSByZWdpb24gbGlzdC4KCg8KBwQGBAACAQESBJACBAoKDwoH
BAYEAAIBAhIEkAINDgpNCgYEBgQAAgISBJMCBBEaPSBUaGUgc2t1IGlzIGF2YWlsYWJsZSBp
biBhIHNwZWNpZmljIHJlZ2lvbiwgZS5nLiAidXMtd2VzdDIiLgoKDwoHBAYEAAICARIEkwIE
DAoPCgcEBgQAAgICEgSTAg8QCl8KBgQGBAACAxIElwIEFxpPIFRoZSBza3UgaXMgYXNzb2Np
YXRlZCB3aXRoIG11bHRpcGxlIHJlZ2lvbnMsIGUuZy4gInVzLXdlc3QyIiBhbmQKICJ1cy1l
YXN0MSIuCgoPCgcEBgQAAgMBEgSXAgQSCg8KBwQGBAACAwISBJcCFRYKTgoEBAYCABIEmwIC
EBpAIFRoZSB0eXBlIG9mIEdlbyBUYXhvbm9teTogR0xPQkFMLCBSRUdJT05BTCwgb3IgTVVM
VElfUkVHSU9OQUwuCgoNCgUEBgIABhIEmwICBgoNCgUEBgIAARIEmwIHCwoNCgUEBgIAAxIE
mwIODwqGAQoEBAYCARIEnwICHhp4IFRoZSBsaXN0IG9mIHJlZ2lvbnMgYXNzb2NpYXRlZCB3
aXRoIGEgc2t1LiBFbXB0eSBmb3IgR2xvYmFsIHNrdXMsIHdoaWNoIGFyZQogYXNzb2NpYXRl
ZCB3aXRoIGFsbCBHb29nbGUgQ2xvdWQgcmVnaW9ucy4KCg0KBQQGAgEEEgSfAgIKCg0KBQQG
AgEFEgSfAgsRCg0KBQQGAgEBEgSfAhIZCg0KBQQGAgEDEgSfAhwdCjMKAgQHEgajAgCrAgEa
JSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIGBMaXN0U2VydmljZXNgLgoKCwoDBAcBEgSjAggbCjYK
BAQHAgASBKUCAhYaKCBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBEZWZhdWx0cyB0byA1MDAwLgoK
DQoFBAcCAAUSBKUCAgcKDQoFBAcCAAESBKUCCBEKDQoFBAcCAAMSBKUCFBUK0QEKBAQHAgES
BKoCAhgawgEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0byByZXR1
cm4uIFRoaXMgc2hvdWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVlIHJldHVybmVk
IGZyb20gYSBwcmV2aW91cyBgTGlzdFNlcnZpY2VzYAogY2FsbC4gSWYgdW5zcGVjaWZpZWQs
IHRoZSBmaXJzdCBwYWdlIG9mIHJlc3VsdHMgaXMgcmV0dXJuZWQuCgoNCgUEBwIBBRIEqgIC
CAoNCgUEBwIBARIEqgIJEwoNCgUEBwIBAxIEqgIWFwo0CgIECBIGrgIAtgIBGiYgUmVzcG9u
c2UgbWVzc2FnZSBmb3IgYExpc3RTZXJ2aWNlc2AuCgoLCgMECAESBK4CCBwKIwoEBAgCABIE
sAICIBoVIEEgbGlzdCBvZiBzZXJ2aWNlcy4KCg0KBQQIAgAEEgSwAgIKCg0KBQQIAgAGEgSw
AgsSCg0KBQQIAgABEgSwAhMbCg0KBQQIAgADEgSwAh4fCuIBCgQECAIBEgS1AgIdGtMBIEEg
dG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLiBUbyByZXRyaWV2
ZSB0aGUgbmV4dCBwYWdlLAogY2FsbCBgTGlzdFNlcnZpY2VzYCBhZ2FpbiB3aXRoIHRoZSBg
cGFnZV90b2tlbmAgZmllbGQgc2V0IHRvIHRoaXMKIHZhbHVlLiBUaGlzIGZpZWxkIGlzIGVt
cHR5IGlmIHRoZXJlIGFyZSBubyBtb3JlIHJlc3VsdHMgdG8gcmV0cmlldmUuCgoNCgUECAIB
BRIEtQICCAoNCgUECAIBARIEtQIJGAoNCgUECAIBAxIEtQIbHAovCgIECRIGuQIA3wIBGiEg
UmVxdWVzdCBtZXNzYWdlIGZvciBgTGlzdFNrdXNgLgoKCwoDBAkBEgS5AggXClgKBAQJAgAS
BrwCAsECBBpIIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2VydmljZS4KIEV4YW1wbGU6
ICJzZXJ2aWNlcy82RjgxLTU4NDQtNDU2QSIKCg0KBQQJAgAFEgS8AgIICg0KBQQJAgABEgS8
AgkPCg0KBQQJAgADEgS8AhITCg8KBQQJAgAIEga8AhTBAgMKEAoIBAkCAAicCAASBL0CBCoK
EQoHBAkCAAifCBIGvgIEwAIFCvACCgQECQIBEgTJAgIrGuECIE9wdGlvbmFsIGluY2x1c2l2
ZSBzdGFydCB0aW1lIG9mIHRoZSB0aW1lIHJhbmdlIGZvciB3aGljaCB0aGUgcHJpY2luZwog
dmVyc2lvbnMgd2lsbCBiZSByZXR1cm5lZC4gVGltZXN0YW1wcyBpbiB0aGUgZnV0dXJlIGFy
ZSBub3QgYWxsb3dlZC4KIFRoZSB0aW1lIHJhbmdlIGhhcyB0byBiZSB3aXRoaW4gYSBzaW5n
bGUgY2FsZW5kYXIgbW9udGggaW4KIEFtZXJpY2EvTG9zX0FuZ2VsZXMgdGltZXpvbmUuIFRp
bWUgcmFuZ2UgYXMgYSB3aG9sZSBpcyBvcHRpb25hbC4gSWYgbm90CiBzcGVjaWZpZWQsIHRo
ZSBsYXRlc3QgcHJpY2luZyB3aWxsIGJlIHJldHVybmVkICh1cCB0byAxMiBob3VycyBvbGQg
YXQKIG1vc3QpLgoKDQoFBAkCAQYSBMkCAhsKDQoFBAkCAQESBMkCHCYKDQoFBAkCAQMSBMkC
KSoK7gIKBAQJAgISBNECAika3wIgT3B0aW9uYWwgZXhjbHVzaXZlIGVuZCB0aW1lIG9mIHRo
ZSB0aW1lIHJhbmdlIGZvciB3aGljaCB0aGUgcHJpY2luZwogdmVyc2lvbnMgd2lsbCBiZSBy
ZXR1cm5lZC4gVGltZXN0YW1wcyBpbiB0aGUgZnV0dXJlIGFyZSBub3QgYWxsb3dlZC4KIFRo
ZSB0aW1lIHJhbmdlIGhhcyB0byBiZSB3aXRoaW4gYSBzaW5nbGUgY2FsZW5kYXIgbW9udGgg
aW4KIEFtZXJpY2EvTG9zX0FuZ2VsZXMgdGltZXpvbmUuIFRpbWUgcmFuZ2UgYXMgYSB3aG9s
ZSBpcyBvcHRpb25hbC4gSWYgbm90CiBzcGVjaWZpZWQsIHRoZSBsYXRlc3QgcHJpY2luZyB3
aWxsIGJlIHJldHVybmVkICh1cCB0byAxMiBob3VycyBvbGQgYXQKIG1vc3QpLgoKDQoFBAkC
AgYSBNECAhsKDQoFBAkCAgESBNECHCQKDQoFBAkCAgMSBNECJygKtQEKBAQJAgMSBNYCAhsa
pgEgVGhlIElTTyA0MjE3IGN1cnJlbmN5IGNvZGUgZm9yIHRoZSBwcmljaW5nIGluZm8gaW4g
dGhlIHJlc3BvbnNlIHByb3RvLgogV2lsbCB1c2UgdGhlIGNvbnZlcnNpb24gcmF0ZSBhcyBv
ZiBzdGFydF90aW1lLgogT3B0aW9uYWwuIElmIG5vdCBzcGVjaWZpZWQgVVNEIHdpbGwgYmUg
dXNlZC4KCg0KBQQJAgMFEgTWAgIICg0KBQQJAgMBEgTWAgkWCg0KBQQJAgMDEgTWAhkaCjYK
BAQJAgQSBNkCAhYaKCBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBEZWZhdWx0cyB0byA1MDAwLgoK
DQoFBAkCBAUSBNkCAgcKDQoFBAkCBAESBNkCCBEKDQoFBAkCBAMSBNkCFBUKzQEKBAQJAgUS
BN4CAhgavgEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0byByZXR1
cm4uIFRoaXMgc2hvdWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVlIHJldHVybmVk
IGZyb20gYSBwcmV2aW91cyBgTGlzdFNrdXNgCiBjYWxsLiBJZiB1bnNwZWNpZmllZCwgdGhl
IGZpcnN0IHBhZ2Ugb2YgcmVzdWx0cyBpcyByZXR1cm5lZC4KCg0KBQQJAgUFEgTeAgIICg0K
BQQJAgUBEgTeAgkTCg0KBQQJAgUDEgTeAhYXCjAKAgQKEgbiAgDqAgEaIiBSZXNwb25zZSBt
ZXNzYWdlIGZvciBgTGlzdFNrdXNgLgoKCwoDBAoBEgTiAggYCj0KBAQKAgASBOQCAhgaLyBU
aGUgbGlzdCBvZiBwdWJsaWMgU0tVcyBvZiB0aGUgZ2l2ZW4gc2VydmljZS4KCg0KBQQKAgAE
EgTkAgIKCg0KBQQKAgAGEgTkAgsOCg0KBQQKAgABEgTkAg8TCg0KBQQKAgADEgTkAhYXCt4B
CgQECgIBEgTpAgIdGs8BIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiBy
ZXN1bHRzLiBUbyByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLAogY2FsbCBgTGlzdFNrdXNgIGFn
YWluIHdpdGggdGhlIGBwYWdlX3Rva2VuYCBmaWVsZCBzZXQgdG8gdGhpcwogdmFsdWUuIFRo
aXMgZmllbGQgaXMgZW1wdHkgaWYgdGhlcmUgYXJlIG5vIG1vcmUgcmVzdWx0cyB0byByZXRy
aWV2ZS4KCg0KBQQKAgEFEgTpAgIICg0KBQQKAgEBEgTpAgkYCg0KBQQKAgEDEgTpAhscYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Billing::V1::CloudCatalog::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: service_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: business_entity_name Type: 9 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::Sku ===
    # Fields for Sku
    # Field: name Type: 9 ()
    # Field: sku_id Type: 9 ()
    # Field: description Type: 9 ()
    # Field: category Type: 11 (.google.cloud.billing.v1.Category)
    # Field: service_regions Type: 9 ()
    # Field: pricing_info Type: 11 (.google.cloud.billing.v1.PricingInfo)
    # Field: service_provider_name Type: 9 ()
    # Field: geo_taxonomy Type: 11 (.google.cloud.billing.v1.GeoTaxonomy)

# === Message: Google::Cloud::Billing::V1::CloudCatalog::Category ===
    # Fields for Category
    # Field: service_display_name Type: 9 ()
    # Field: resource_family Type: 9 ()
    # Field: resource_group Type: 9 ()
    # Field: usage_type Type: 9 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::PricingInfo ===
    # Fields for PricingInfo
    # Field: effective_time Type: 11 (.google.protobuf.Timestamp)
    # Field: summary Type: 9 ()
    # Field: pricing_expression Type: 11 (.google.cloud.billing.v1.PricingExpression)
    # Field: aggregation_info Type: 11 (.google.cloud.billing.v1.AggregationInfo)
    # Field: currency_conversion_rate Type: 1 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::PricingExpression ===
    # Fields for PricingExpression
    # Field: usage_unit Type: 9 ()
    # Field: display_quantity Type: 1 ()
    # Field: tiered_rates Type: 11 (.google.cloud.billing.v1.PricingExpression.TierRate)
    # Field: usage_unit_description Type: 9 ()
    # Field: base_unit Type: 9 ()
    # Field: base_unit_description Type: 9 ()
    # Field: base_unit_conversion_factor Type: 1 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo ===
    # Fields for AggregationInfo
    # Field: aggregation_level Type: 14 (.google.cloud.billing.v1.AggregationInfo.AggregationLevel)
    # Field: aggregation_interval Type: 14 (.google.cloud.billing.v1.AggregationInfo.AggregationInterval)
    # Field: aggregation_count Type: 5 ()

# Enum: AggregationInfo::AggregationLevel
our $AggregationInfo_AGGREGATION_LEVEL_UNSPECIFIED = 0;
our $AggregationInfo_ACCOUNT = 1;
our $AggregationInfo_PROJECT = 2;

# Enum: AggregationInfo::AggregationInterval
our $AggregationInfo_AGGREGATION_INTERVAL_UNSPECIFIED = 0;
our $AggregationInfo_DAILY = 1;
our $AggregationInfo_MONTHLY = 2;

# === Message: Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy ===
    # Fields for GeoTaxonomy
    # Field: type Type: 14 (.google.cloud.billing.v1.GeoTaxonomy.Type)
    # Field: regions Type: 9 ()

# Enum: GeoTaxonomy::Type
our $GeoTaxonomy_TYPE_UNSPECIFIED = 0;
our $GeoTaxonomy_GLOBAL = 1;
our $GeoTaxonomy_REGIONAL = 2;
our $GeoTaxonomy_MULTI_REGIONAL = 3;

# === Message: Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest ===
    # Fields for ListServicesRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse ===
    # Fields for ListServicesResponse
    # Field: services Type: 11 (.google.cloud.billing.v1.Service)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest ===
    # Fields for ListSkusRequest
    # Field: parent Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: currency_code Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse ===
    # Fields for ListSkusResponse
    # Field: skus Type: 11 (.google.cloud.billing.v1.Sku)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Billing::V1::CloudCatalog::CloudCatalogClient ===
package Google::Cloud::Billing::V1::CloudCatalog::CloudCatalogClient;

=pod

=head2 Service Client: Google::Cloud::Billing::V1::CloudCatalog::CloudCatalogClient

Client stub representing the remote C<CloudCatalog> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<billing.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'billing.googleapis.com:443' );

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

sub list_services {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.v1.CloudCatalog',
        method         => 'ListServices',
        request        => $req,
        response_class => 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse',
    });
}

sub list_skus {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.billing.v1.CloudCatalog',
        method         => 'ListSkus',
        request        => $req,
        response_class => 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Billing::V1::CloudCatalog - Compiled Protocol Buffers messages for google/cloud/billing/v1/cloud_catalog.proto

=head1 SYNOPSIS

    use Google::Cloud::Billing::V1::CloudCatalog;

    my $msg = Google::Cloud::Billing::V1::CloudCatalog::Service->new({
        name => $name,
        service_id => $service_id,
        display_name => $display_name,
        business_entity_name => $business_entity_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Billing::V1::CloudCatalog::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/billing/v1/cloud_catalog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Billing::V1::CloudCatalog::Service

Encapsulates a single service in Google Cloud Platform.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name for the service.
Example: "services/6F81-5844-456A"

=item * C<< $msg->service_id() >> / C<< $msg->service_id($value) >>

Type: C<String>

The identifier for the service.
Example: "6F81-5844-456A"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A human readable display name for this service.

=item * C<< $msg->business_entity_name() >> / C<< $msg->business_entity_name($value) >>

Type: C<String>

The business under which the service is offered.
Ex. "businessEntities/GCP", "businessEntities/Maps"

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::Sku

Encapsulates a single SKU in Google Cloud

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name for the SKU.
Example: "services/6F81-5844-456A/skus/D041-B8A1-6E0B"

=item * C<< $msg->sku_id() >> / C<< $msg->sku_id($value) >>

Type: C<String>

The identifier for the SKU.
Example: "D041-B8A1-6E0B"

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human readable description of the SKU, has a maximum length of 256
characters.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::Category>)

The category hierarchy of this SKU, purely for organizational purpose.

=item * C<< $msg->service_regions() >> / C<< $msg->service_regions($value) >>

Type: C<String>

List of service regions this SKU is offered at.
Example: "asia-east1"
Service regions can be found at https://cloud.google.com/about/locations/

=item * C<< $msg->pricing_info() >> / C<< $msg->pricing_info($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::PricingInfo>)

A timeline of pricing info for this SKU in chronological order.

=item * C<< $msg->service_provider_name() >> / C<< $msg->service_provider_name($value) >>

Type: C<String>

Identifies the service provider.
This is 'Google' for first party services in Google Cloud Platform.

=item * C<< $msg->geo_taxonomy() >> / C<< $msg->geo_taxonomy($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy>)

The geographic taxonomy for this sku.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::Category

Represents the category hierarchy of a SKU.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_display_name() >> / C<< $msg->service_display_name($value) >>

Type: C<String>

The display name of the service this SKU belongs to.

=item * C<< $msg->resource_family() >> / C<< $msg->resource_family($value) >>

Type: C<String>

The type of product the SKU refers to.
Example: "Compute", "Storage", "Network", "ApplicationServices" etc.

=item * C<< $msg->resource_group() >> / C<< $msg->resource_group($value) >>

Type: C<String>

A group classification for related SKUs.
Example: "RAM", "GPU", "Prediction", "Ops", "GoogleEgress" etc.

=item * C<< $msg->usage_type() >> / C<< $msg->usage_type($value) >>

Type: C<String>

Represents how the SKU is consumed.
Example: "OnDemand", "Preemptible", "Commit1Mo", "Commit1Yr" etc.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::PricingInfo

Represents the pricing information for a SKU at a single point of time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->effective_time() >> / C<< $msg->effective_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp from which this pricing was effective within the requested
time range. This is guaranteed to be greater than or equal to the
start_time field in the request and less than the end_time field in the
request. If a time range was not specified in the request this field will
be equivalent to a time within the last 12 hours, indicating the latest
pricing info.

=item * C<< $msg->summary() >> / C<< $msg->summary($value) >>

Type: C<String>

An optional human readable summary of the pricing information, has a
maximum length of 256 characters.

=item * C<< $msg->pricing_expression() >> / C<< $msg->pricing_expression($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::PricingExpression>)

Expresses the pricing formula. See `PricingExpression` for an example.

=item * C<< $msg->aggregation_info() >> / C<< $msg->aggregation_info($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo>)

Aggregation Info. This can be left unspecified if the pricing expression
doesn't require aggregation.

=item * C<< $msg->currency_conversion_rate() >> / C<< $msg->currency_conversion_rate($value) >>

Type: C<Double>

Conversion rate used for currency conversion, from USD to the currency
specified in the request. This includes any surcharge collected for billing
in non USD currency. If a currency is not specified in the request this
defaults to 1.0.
Example: USD * currency_conversion_rate = JPY

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::PricingExpression

Expresses a mathematical pricing formula. For Example:-

`usage_unit: GBy`
`tiered_rates:`
   `[start_usage_amount: 20, unit_price: $10]`
   `[start_usage_amount: 100, unit_price: $5]`

The above expresses a pricing formula where the first 20GB is free, the
next 80GB is priced at $10 per GB followed by $5 per GB for additional
usage.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->usage_unit() >> / C<< $msg->usage_unit($value) >>

Type: C<String>

The short hand for unit of usage this pricing is specified in.
Example: usage_unit of "GiBy" means that usage is specified in "Gibi Byte".

=item * C<< $msg->display_quantity() >> / C<< $msg->display_quantity($value) >>

Type: C<Double>

The recommended quantity of units for displaying pricing info. When
displaying pricing info it is recommended to display:
(unit_price * display_quantity) per display_quantity usage_unit.
This field does not affect the pricing formula and is for display purposes
only.
Example: If the unit_price is "0.0001 USD", the usage_unit is "GB" and
the display_quantity is "1000" then the recommended way of displaying the
pricing info is "0.10 USD per 1000 GB"

=item * C<< $msg->tiered_rates() >> / C<< $msg->tiered_rates($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::PricingExpression::TierRate>)

The list of tiered rates for this pricing. The total cost is computed by
applying each of the tiered rates on usage. This repeated list is sorted
by ascending order of start_usage_amount.

=item * C<< $msg->usage_unit_description() >> / C<< $msg->usage_unit_description($value) >>

Type: C<String>

The unit of usage in human readable form.
Example: "gibi byte".

=item * C<< $msg->base_unit() >> / C<< $msg->base_unit($value) >>

Type: C<String>

The base unit for the SKU which is the unit used in usage exports.
Example: "By"

=item * C<< $msg->base_unit_description() >> / C<< $msg->base_unit_description($value) >>

Type: C<String>

The base unit in human readable form.
Example: "byte".

=item * C<< $msg->base_unit_conversion_factor() >> / C<< $msg->base_unit_conversion_factor($value) >>

Type: C<Double>

Conversion factor for converting from price per usage_unit to price per
base_unit, and start_usage_amount to start_usage_amount in base_unit.
unit_price / base_unit_conversion_factor = price per base_unit.
start_usage_amount * base_unit_conversion_factor = start_usage_amount in
base_unit.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo

Represents the aggregation level and interval for pricing of a single SKU.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->aggregation_level() >> / C<< $msg->aggregation_level($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::V1::AggregationInfo::AggregationLevel>)

=item * C<< $msg->aggregation_interval() >> / C<< $msg->aggregation_interval($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::V1::AggregationInfo::AggregationInterval>)

=item * C<< $msg->aggregation_count() >> / C<< $msg->aggregation_count($value) >>

Type: C<Int32>

The number of intervals to aggregate over.
Example: If aggregation_level is "DAILY" and aggregation_count is 14,
aggregation will be over 14 days.

=back

=head3 Enum: AggregationInfo::AggregationLevel

=over 4

=item * C<AGGREGATION_LEVEL_UNSPECIFIED> => C<0>

=item * C<ACCOUNT> => C<1>

=item * C<PROJECT> => C<2>

=back

=head3 Enum: AggregationInfo::AggregationInterval

=over 4

=item * C<AGGREGATION_INTERVAL_UNSPECIFIED> => C<0>

=item * C<DAILY> => C<1>

=item * C<MONTHLY> => C<2>

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy

Encapsulates the geographic taxonomy data for a sku.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Billing::V1::GeoTaxonomy::Type>)

The type of Geo Taxonomy: GLOBAL, REGIONAL, or MULTI_REGIONAL.

=item * C<< $msg->regions() >> / C<< $msg->regions($value) >>

Type: C<String>

The list of regions associated with a sku. Empty for Global skus, which are
associated with all Google Cloud regions.

=back

=head3 Enum: GeoTaxonomy::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<GLOBAL> => C<1>

=item * C<REGIONAL> => C<2>

=item * C<MULTI_REGIONAL> => C<3>

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest

Request message for `ListServices`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Defaults to 5000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to return. This should be a
`next_page_token` value returned from a previous `ListServices`
call. If unspecified, the first page of results is returned.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse

Response message for `ListServices`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->services() >> / C<< $msg->services($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::Service>)

A list of services.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. To retrieve the next page,
call `ListServices` again with the `page_token` field set to this
value. This field is empty if there are no more results to retrieve.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest

Request message for `ListSkus`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the service.
Example: "services/6F81-5844-456A"

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional inclusive start time of the time range for which the pricing
versions will be returned. Timestamps in the future are not allowed.
The time range has to be within a single calendar month in
America/Los_Angeles timezone. Time range as a whole is optional. If not
specified, the latest pricing will be returned (up to 12 hours old at
most).

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional exclusive end time of the time range for which the pricing
versions will be returned. Timestamps in the future are not allowed.
The time range has to be within a single calendar month in
America/Los_Angeles timezone. Time range as a whole is optional. If not
specified, the latest pricing will be returned (up to 12 hours old at
most).

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

The ISO 4217 currency code for the pricing info in the response proto.
Will use the conversion rate as of start_time.
Optional. If not specified USD will be used.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Defaults to 5000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to return. This should be a
`next_page_token` value returned from a previous `ListSkus`
call. If unspecified, the first page of results is returned.

=back

=head2 Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse

Response message for `ListSkus`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->skus() >> / C<< $msg->skus($value) >>

Type: C<Message> (L<Google::Cloud::Billing::V1::CloudCatalog::Sku>)

The list of public SKUs of the given service.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. To retrieve the next page,
call `ListSkus` again with the `page_token` field set to this
value. This field is empty if there are no more results to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Billing::V1::CloudCatalog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
