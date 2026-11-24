package Google::Cloud::Gkemulticloud::V1::AttachedResources;

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
    eval { require Google::Cloud::Gkemulticloud::V1::CommonResources };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvZ2tlbXVsdGljbG91ZC92MS9hdHRhY2hlZF9yZXNvdXJjZXMucHJv
dG8SHWdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29nbGUvY2xvdWQv
Z2tlbXVsdGljbG91ZC92MS9jb21tb25fcmVzb3VyY2VzLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvGhZnb29nbGUvdHlwZS9kYXRlLnByb3RvIpMRCg9BdHRhY2hl
ZENsdXN0ZXISEgoEbmFtZRgBIAEoCVIEbmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEB
UgtkZXNjcmlwdGlvbhJXCgtvaWRjX2NvbmZpZxgDIAEoCzIxLmdvb2dsZS5jbG91ZC5na2Vt
dWx0aWNsb3VkLnYxLkF0dGFjaGVkT2lkY0NvbmZpZ0ID4EECUgpvaWRjQ29uZmlnEi4KEHBs
YXRmb3JtX3ZlcnNpb24YBCABKAlCA+BBAlIPcGxhdGZvcm1WZXJzaW9uEicKDGRpc3RyaWJ1
dGlvbhgQIAEoCUID4EECUgxkaXN0cmlidXRpb24SKgoOY2x1c3Rlcl9yZWdpb24YFiABKAlC
A+BBA1INY2x1c3RlclJlZ2lvbhI/CgVmbGVldBgFIAEoCzIkLmdvb2dsZS5jbG91ZC5na2Vt
dWx0aWNsb3VkLnYxLkZsZWV0QgPgQQJSBWZsZWV0Ek8KBXN0YXRlGAYgASgOMjQuZ29vZ2xl
LmNsb3VkLmdrZW11bHRpY2xvdWQudjEuQXR0YWNoZWRDbHVzdGVyLlN0YXRlQgPgQQNSBXN0
YXRlEhUKA3VpZBgHIAEoCUID4EEDUgN1aWQSJQoLcmVjb25jaWxpbmcYCCABKAhCA+BBA1IL
cmVjb25jaWxpbmcSQAoLY3JlYXRlX3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSEgoEZXRhZxgLIAEoCVIEZXRh
ZxIyChJrdWJlcm5ldGVzX3ZlcnNpb24YDCABKAlCA+BBA1IRa3ViZXJuZXRlc1ZlcnNpb24S
ZgoLYW5ub3RhdGlvbnMYDSADKAsyPy5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5B
dHRhY2hlZENsdXN0ZXIuQW5ub3RhdGlvbnNFbnRyeUID4EEBUgthbm5vdGF0aW9ucxJ0Chh3
b3JrbG9hZF9pZGVudGl0eV9jb25maWcYDiABKAsyNS5nb29nbGUuY2xvdWQuZ2tlbXVsdGlj
bG91ZC52MS5Xb3JrbG9hZElkZW50aXR5Q29uZmlnQgPgQQNSFndvcmtsb2FkSWRlbnRpdHlD
b25maWcSWAoObG9nZ2luZ19jb25maWcYDyABKAsyLC5nb29nbGUuY2xvdWQuZ2tlbXVsdGlj
bG91ZC52MS5Mb2dnaW5nQ29uZmlnQgPgQQFSDWxvZ2dpbmdDb25maWcSUAoGZXJyb3JzGBQg
AygLMjMuZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xvdWQudjEuQXR0YWNoZWRDbHVzdGVyRXJy
b3JCA+BBA1IGZXJyb3JzEmcKDWF1dGhvcml6YXRpb24YFSABKAsyPC5nb29nbGUuY2xvdWQu
Z2tlbXVsdGljbG91ZC52MS5BdHRhY2hlZENsdXN0ZXJzQXV0aG9yaXphdGlvbkID4EEBUg1h
dXRob3JpemF0aW9uEmEKEW1vbml0b3JpbmdfY29uZmlnGBcgASgLMi8uZ29vZ2xlLmNsb3Vk
LmdrZW11bHRpY2xvdWQudjEuTW9uaXRvcmluZ0NvbmZpZ0ID4EEBUhBtb25pdG9yaW5nQ29u
ZmlnEloKDHByb3h5X2NvbmZpZxgYIAEoCzIyLmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3Vk
LnYxLkF0dGFjaGVkUHJveHlDb25maWdCA+BBAVILcHJveHlDb25maWcSagoUYmluYXJ5X2F1
dGhvcml6YXRpb24YGSABKAsyMi5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5CaW5h
cnlBdXRob3JpemF0aW9uQgPgQQFSE2JpbmFyeUF1dGhvcml6YXRpb24ScQoXc2VjdXJpdHlf
cG9zdHVyZV9jb25maWcYGiABKAsyNC5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5T
ZWN1cml0eVBvc3R1cmVDb25maWdCA+BBAVIVc2VjdXJpdHlQb3N0dXJlQ29uZmlnElQKBHRh
Z3MYGyADKAsyOC5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5BdHRhY2hlZENsdXN0
ZXIuVGFnc0VudHJ5QgbgQQHgQQRSBHRhZ3MSdAoYc3lzdGVtX2NvbXBvbmVudHNfY29uZmln
GBwgASgLMjUuZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xvdWQudjEuU3lzdGVtQ29tcG9uZW50
c0NvbmZpZ0ID4EEBUhZzeXN0ZW1Db21wb25lbnRzQ29uZmlnGj4KEEFubm90YXRpb25zRW50
cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARo3CglUYWdz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJ1CgVT
dGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhAKDFBST1ZJU0lPTklORxABEgsKB1JVTk5J
TkcQAhIPCgtSRUNPTkNJTElORxADEgwKCFNUT1BQSU5HEAQSCQoFRVJST1IQBRIMCghERUdS
QURFRBAGOn7qQXsKLGdrZW11bHRpY2xvdWQuZ29vZ2xlYXBpcy5jb20vQXR0YWNoZWRDbHVz
dGVyEktwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXR0YWNoZWRD
bHVzdGVycy97YXR0YWNoZWRfY2x1c3Rlcn0i1gEKHUF0dGFjaGVkQ2x1c3RlcnNBdXRob3Jp
emF0aW9uElgKC2FkbWluX3VzZXJzGAEgAygLMjIuZ29vZ2xlLmNsb3VkLmdrZW11bHRpY2xv
dWQudjEuQXR0YWNoZWRDbHVzdGVyVXNlckID4EEBUgphZG1pblVzZXJzElsKDGFkbWluX2dy
b3VwcxgCIAMoCzIzLmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxLkF0dGFjaGVkQ2x1
c3Rlckdyb3VwQgPgQQFSC2FkbWluR3JvdXBzIjYKE0F0dGFjaGVkQ2x1c3RlclVzZXISHwoI
dXNlcm5hbWUYASABKAlCA+BBAlIIdXNlcm5hbWUiMQoUQXR0YWNoZWRDbHVzdGVyR3JvdXAS
GQoFZ3JvdXAYASABKAlCA+BBAlIFZ3JvdXAiTAoSQXR0YWNoZWRPaWRjQ29uZmlnEh0KCmlz
c3Vlcl91cmwYASABKAlSCWlzc3VlclVybBIXCgRqd2tzGAIgASgMQgPgQQFSBGp3a3MigwIK
FEF0dGFjaGVkU2VydmVyQ29uZmlnEhIKBG5hbWUYASABKAlSBG5hbWUSYQoOdmFsaWRfdmVy
c2lvbnMYAiADKAsyOi5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5BdHRhY2hlZFBs
YXRmb3JtVmVyc2lvbkluZm9SDXZhbGlkVmVyc2lvbnM6dOpBcQoxZ2tlbXVsdGljbG91ZC5n
b29nbGVhcGlzLmNvbS9BdHRhY2hlZFNlcnZlckNvbmZpZxI8cHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2F0dGFjaGVkU2VydmVyQ29uZmlnIvcBChtBdHRhY2hl
ZFBsYXRmb3JtVmVyc2lvbkluZm8SGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhIdCgdlbmFi
bGVkGAMgASgIQgPgQQFSB2VuYWJsZWQSIwoLZW5kX29mX2xpZmUYBCABKAhCA+BBAVIJZW5k
T2ZMaWZlEj8KEGVuZF9vZl9saWZlX2RhdGUYBSABKAsyES5nb29nbGUudHlwZS5EYXRlQgPg
QQFSDWVuZE9mTGlmZURhdGUSOQoMcmVsZWFzZV9kYXRlGAYgASgLMhEuZ29vZ2xlLnR5cGUu
RGF0ZUID4EEBUgtyZWxlYXNlRGF0ZSIwChRBdHRhY2hlZENsdXN0ZXJFcnJvchIYCgdtZXNz
YWdlGAEgASgJUgdtZXNzYWdlInMKE0F0dGFjaGVkUHJveHlDb25maWcSXAoRa3ViZXJuZXRl
c19zZWNyZXQYASABKAsyLy5nb29nbGUuY2xvdWQuZ2tlbXVsdGljbG91ZC52MS5LdWJlcm5l
dGVzU2VjcmV0UhBrdWJlcm5ldGVzU2VjcmV0IkQKEEt1YmVybmV0ZXNTZWNyZXQSEgoEbmFt
ZRgBIAEoCVIEbmFtZRIcCgluYW1lc3BhY2UYAiABKAlSCW5hbWVzcGFjZSKjAQoWU3lzdGVt
Q29tcG9uZW50c0NvbmZpZxJLCgt0b2xlcmF0aW9ucxgBIAMoCzIpLmdvb2dsZS5jbG91ZC5n
a2VtdWx0aWNsb3VkLnYxLlRvbGVyYXRpb25SC3RvbGVyYXRpb25zEjwKBmxhYmVscxgCIAMo
CzIkLmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxLkxhYmVsUgZsYWJlbHMipgMKClRv
bGVyYXRpb24SEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlElgKDGtl
eV9vcGVyYXRvchgDIAEoDjI1Lmdvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxLlRvbGVy
YXRpb24uS2V5T3BlcmF0b3JSC2tleU9wZXJhdG9yEkgKBmVmZmVjdBgEIAEoDjIwLmdvb2ds
ZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYxLlRvbGVyYXRpb24uRWZmZWN0UgZlZmZlY3QiXAoL
S2V5T3BlcmF0b3ISHAoYS0VZX09QRVJBVE9SX1VOU1BFQ0lGSUVEEAASFgoSS0VZX09QRVJB
VE9SX0VRVUFMEAESFwoTS0VZX09QRVJBVE9SX0VYSVNUUxACIm4KBkVmZmVjdBIWChJFRkZF
Q1RfVU5TUEVDSUZJRUQQABIWChJFRkZFQ1RfTk9fU0NIRURVTEUQARIdChlFRkZFQ1RfUFJF
RkVSX05PX1NDSEVEVUxFEAISFQoRRUZGRUNUX05PX0VYRUNVVEUQAyIvCgVMYWJlbBIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWVC6QEKIWNvbS5nb29nbGUuY2xv
dWQuZ2tlbXVsdGljbG91ZC52MUIWQXR0YWNoZWRSZXNvdXJjZXNQcm90b1ABWkdjbG91ZC5n
b29nbGUuY29tL2dvL2drZW11bHRpY2xvdWQvYXBpdjEvZ2tlbXVsdGljbG91ZHBiO2drZW11
bHRpY2xvdWRwYqoCHUdvb2dsZS5DbG91ZC5Ha2VNdWx0aUNsb3VkLlYxygIdR29vZ2xlXENs
b3VkXEdrZU11bHRpQ2xvdWRcVjHqAiBHb29nbGU6OkNsb3VkOjpHa2VNdWx0aUNsb3VkOjpW
MUqscgoHEgUOAIADAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAPgoJCgIDAxIDFQApCgkKAgME
EgMWACAKCAoBCBIDGAA6CgkKAgglEgMYADoKCAoBCBIDGQBeCgkKAggLEgMZAF4KCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwA3CgkKAggIEgMbADcKCAoBCBIDHAA6CgkKAggBEgMc
ADoKCAoBCBIDHQA6CgkKAggpEgMdADoKCAoBCBIDHgA5CgkKAggtEgMeADkKSAoCBAASBSEA
xAEBGjsgQW4gQW50aG9zIGNsdXN0ZXIgcnVubmluZyBvbiBjdXN0b21lciBvd24gaW5mcmFz
dHJ1Y3R1cmUuCgoKCgMEAAESAyEIFwoLCgMEAAcSBCICJQQKDQoFBAAHnQgSBCICJQQKMwoE
BAAEABIEKAJBAxolIFRoZSBsaWZlY3ljbGUgc3RhdGUgb2YgdGhlIGNsdXN0ZXIuCgoMCgUE
AAQAARIDKAcMChkKBgQABAACABIDKgQaGgogTm90IHNldC4KCg4KBwQABAACAAESAyoEFQoO
CgcEAAQAAgACEgMqGBkKUgoGBAAEAAIBEgMtBBUaQyBUaGUgUFJPVklTSU9OSU5HIHN0YXRl
IGluZGljYXRlcyB0aGUgY2x1c3RlciBpcyBiZWluZyByZWdpc3RlcmVkLgoKDgoHBAAEAAIB
ARIDLQQQCg4KBwQABAACAQISAy0TFApgCgYEAAQAAgISAzEEEBpRIFRoZSBSVU5OSU5HIHN0
YXRlIGluZGljYXRlcyB0aGUgY2x1c3RlciBoYXMgYmVlbiByZWdpc3RlciBhbmQgaXMgZnVs
bHkKIHVzYWJsZS4KCg4KBwQABAACAgESAzEECwoOCgcEAAQAAgICEgMxDg8KjgEKBgQABAAC
AxIDNQQUGn8gVGhlIFJFQ09OQ0lMSU5HIHN0YXRlIGluZGljYXRlcyB0aGF0IHNvbWUgd29y
ayBpcyBhY3RpdmVseSBiZWluZyBkb25lIG9uCiB0aGUgY2x1c3Rlciwgc3VjaCBhcyB1cGdy
YWRpbmcgc29mdHdhcmUgY29tcG9uZW50cy4KCg4KBwQABAACAwESAzUEDwoOCgcEAAQAAgMC
EgM1EhMKUQoGBAAEAAIEEgM4BBEaQiBUaGUgU1RPUFBJTkcgc3RhdGUgaW5kaWNhdGVzIHRo
ZSBjbHVzdGVyIGlzIGJlaW5nIGRlLXJlZ2lzdGVyZWQuCgoOCgcEAAQAAgQBEgM4BAwKDgoH
BAAEAAIEAhIDOA8QClsKBgQABAACBRIDPAQOGkwgVGhlIEVSUk9SIHN0YXRlIGluZGljYXRl
cyB0aGUgY2x1c3RlciBpcyBpbiBhIGJyb2tlbiB1bnJlY292ZXJhYmxlCiBzdGF0ZS4KCg4K
BwQABAACBQESAzwECQoOCgcEAAQAAgUCEgM8DA0KbgoGBAAEAAIGEgNABBEaXyBUaGUgREVH
UkFERUQgc3RhdGUgaW5kaWNhdGVzIHRoZSBjbHVzdGVyIHJlcXVpcmVzIHVzZXIgYWN0aW9u
IHRvCiByZXN0b3JlIGZ1bGwgZnVuY3Rpb25hbGl0eS4KCg4KBwQABAACBgESA0AEDAoOCgcE
AAQAAgYCEgNADxAKoQIKBAQAAgASA0oCEhqTAiBUaGUgbmFtZSBvZiB0aGlzIHJlc291cmNl
LgoKIENsdXN0ZXIgbmFtZXMgYXJlIGZvcm1hdHRlZCBhcwogYHByb2plY3RzLzxwcm9qZWN0
LW51bWJlcj4vbG9jYXRpb25zLzxyZWdpb24+L2F0dGFjaGVkQ2x1c3RlcnMvPGNsdXN0ZXIt
aWQ+YC4KCiBTZWUgW1Jlc291cmNlIE5hbWVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
YXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMpCiBmb3IgbW9yZSBkZXRhaWxzIG9uIEdvb2ds
ZSBDbG91ZCBQbGF0Zm9ybSByZXNvdXJjZSBuYW1lcy4KCgwKBQQAAgAFEgNKAggKDAoFBAAC
AAESA0oJDQoMCgUEAAIAAxIDShARCnYKBAQAAgESA04CQhppIE9wdGlvbmFsLiBBIGh1bWFu
IHJlYWRhYmxlIGRlc2NyaXB0aW9uIG9mIHRoaXMgY2x1c3Rlci4KIENhbm5vdCBiZSBsb25n
ZXIgdGhhbiAyNTUgVVRGLTggZW5jb2RlZCBieXRlcy4KCgwKBQQAAgEFEgNOAggKDAoFBAAC
AQESA04JFAoMCgUEAAIBAxIDThcYCgwKBQQAAgEIEgNOGUEKDwoIBAACAQicCAASA04aQApN
CgQEAAICEgNRAk4aQCBSZXF1aXJlZC4gT3BlbklEIENvbm5lY3QgKE9JREMpIGNvbmZpZ3Vy
YXRpb24gZm9yIHRoZSBjbHVzdGVyLgoKDAoFBAACAgYSA1ECFAoMCgUEAAICARIDURUgCgwK
BQQAAgIDEgNRIyQKDAoFBAACAggSA1ElTQoPCggEAAICCJwIABIDUSZMCo0CCgQEAAIDEgNY
Akca/wEgUmVxdWlyZWQuIFRoZSBwbGF0Zm9ybSB2ZXJzaW9uIGZvciB0aGUgY2x1c3RlciAo
ZS5nLiBgMS4xOS4wLWdrZS4xMDAwYCkuCgogWW91IGNhbiBsaXN0IGFsbCBzdXBwb3J0ZWQg
dmVyc2lvbnMgb24gYSBnaXZlbiBHb29nbGUgQ2xvdWQgcmVnaW9uIGJ5CiBjYWxsaW5nCiBb
R2V0QXR0YWNoZWRTZXJ2ZXJDb25maWddW2dvb2dsZS5jbG91ZC5na2VtdWx0aWNsb3VkLnYx
LkF0dGFjaGVkQ2x1c3RlcnMuR2V0QXR0YWNoZWRTZXJ2ZXJDb25maWddLgoKDAoFBAACAwUS
A1gCCAoMCgUEAAIDARIDWAkZCgwKBQQAAgMDEgNYHB0KDAoFBAACAwgSA1geRgoPCggEAAID
CJwIABIDWB9FCocBCgQEAAIEEgNdAkQaeiBSZXF1aXJlZC4gVGhlIEt1YmVybmV0ZXMgZGlz
dHJpYnV0aW9uIG9mIHRoZSB1bmRlcmx5aW5nIGF0dGFjaGVkIGNsdXN0ZXIuCgogU3VwcG9y
dGVkIHZhbHVlczogWyJla3MiLCAiYWtzIiwgImdlbmVyaWMiXS4KCgwKBQQAAgQFEgNdAggK
DAoFBAACBAESA10JFQoMCgUEAAIEAxIDXRgaCgwKBQQAAgQIEgNdG0MKDwoIBAACBAicCAAS
A10cQgqWAQoEBAACBRIDYwJJGogBIE91dHB1dCBvbmx5LiBUaGUgcmVnaW9uIHdoZXJlIHRo
aXMgY2x1c3RlciBydW5zLgoKIEZvciBFS1MgY2x1c3RlcnMsIHRoaXMgaXMgYSBBV1MgcmVn
aW9uLiBGb3IgQUtTIGNsdXN0ZXJzLAogdGhpcyBpcyBhbiBBenVyZSByZWdpb24uCgoMCgUE
AAIFBRIDYwIICgwKBQQAAgUBEgNjCRcKDAoFBAACBQMSA2MaHAoMCgUEAAIFCBIDYx1ICg8K
CAQAAgUInAgAEgNjHkcKLQoEBAACBhIDZgI7GiAgUmVxdWlyZWQuIEZsZWV0IGNvbmZpZ3Vy
YXRpb24uCgoMCgUEAAIGBhIDZgIHCgwKBQQAAgYBEgNmCA0KDAoFBAACBgMSA2YQEQoMCgUE
AAIGCBIDZhI6Cg8KCAQAAgYInAgAEgNmEzkKPQoEBAACBxIDaQI+GjAgT3V0cHV0IG9ubHku
IFRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBjbHVzdGVyLgoKDAoFBAACBwYSA2kCBwoMCgUE
AAIHARIDaQgNCgwKBQQAAgcDEgNpEBEKDAoFBAACBwgSA2kSPQoPCggEAAIHCJwIABIDaRM8
CkkKBAQAAggSA2wCPRo8IE91dHB1dCBvbmx5LiBBIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlm
aWVyIGZvciB0aGUgY2x1c3Rlci4KCgwKBQQAAggFEgNsAggKDAoFBAACCAESA2wJDAoMCgUE
AAIIAxIDbA8QCgwKBQQAAggIEgNsETwKDwoIBAACCAicCAASA2wSOwpZCgQEAAIJEgNvAkMa
TCBPdXRwdXQgb25seS4gSWYgc2V0LCB0aGVyZSBhcmUgY3VycmVudGx5IGNoYW5nZXMgaW4g
ZmxpZ2h0IHRvIHRoZSBjbHVzdGVyLgoKDAoFBAACCQUSA28CBgoMCgUEAAIJARIDbwcSCgwK
BQQAAgkDEgNvFRYKDAoFBAACCQgSA28XQgoPCggEAAIJCJwIABIDbxhBCksKBAQAAgoSBHIC
czIaPSBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBjbHVzdGVyIHdhcyBy
ZWdpc3RlcmVkLgoKDAoFBAACCgYSA3ICGwoMCgUEAAIKARIDchwnCgwKBQQAAgoDEgNyKisK
DAoFBAACCggSA3MGMQoPCggEAAIKCJwIABIDcwcwCk0KBAQAAgsSBHYCdzIaPyBPdXRwdXQg
b25seS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBjbHVzdGVyIHdhcyBsYXN0IHVwZGF0ZWQu
CgoMCgUEAAILBhIDdgIbCgwKBQQAAgsBEgN2HCcKDAoFBAACCwMSA3YqLAoMCgUEAAILCBID
dwYxCg8KCAQAAgsInAgAEgN3BzAK3QEKBAQAAgwSA34CExrPASBBbGxvd3MgY2xpZW50cyB0
byBwZXJmb3JtIGNvbnNpc3RlbnQgcmVhZC1tb2RpZnktd3JpdGVzCiB0aHJvdWdoIG9wdGlt
aXN0aWMgY29uY3VycmVuY3kgY29udHJvbC4KCiBDYW4gYmUgc2VudCBvbiB1cGRhdGUgYW5k
IGRlbGV0ZSByZXF1ZXN0cyB0byBlbnN1cmUgdGhlCiBjbGllbnQgaGFzIGFuIHVwLXRvLWRh
dGUgdmFsdWUgYmVmb3JlIHByb2NlZWRpbmcuCgoMCgUEAAIMBRIDfgIICgwKBQQAAgwBEgN+
CQ0KDAoFBAACDAMSA34QEgpDCgQEAAINEgSBAQJNGjUgT3V0cHV0IG9ubHkuIFRoZSBLdWJl
cm5ldGVzIHZlcnNpb24gb2YgdGhlIGNsdXN0ZXIuCgoNCgUEAAINBRIEgQECCAoNCgUEAAIN
ARIEgQEJGwoNCgUEAAINAxIEgQEeIAoNCgUEAAINCBIEgQEhTAoQCggEAAINCJwIABIEgQEi
SwrIAwoEBAACDhIEjAECUBq5AyBPcHRpb25hbC4gQW5ub3RhdGlvbnMgb24gdGhlIGNsdXN0
ZXIuCgogVGhpcyBmaWVsZCBoYXMgdGhlIHNhbWUgcmVzdHJpY3Rpb25zIGFzIEt1YmVybmV0
ZXMgYW5ub3RhdGlvbnMuCiBUaGUgdG90YWwgc2l6ZSBvZiBhbGwga2V5cyBhbmQgdmFsdWVz
IGNvbWJpbmVkIGlzIGxpbWl0ZWQgdG8gMjU2ay4KIEtleSBjYW4gaGF2ZSAyIHNlZ21lbnRz
OiBwcmVmaXggKG9wdGlvbmFsKSBhbmQgbmFtZSAocmVxdWlyZWQpLAogc2VwYXJhdGVkIGJ5
IGEgc2xhc2ggKC8pLgogUHJlZml4IG11c3QgYmUgYSBETlMgc3ViZG9tYWluLgogTmFtZSBt
dXN0IGJlIDYzIGNoYXJhY3RlcnMgb3IgbGVzcywgYmVnaW4gYW5kIGVuZCB3aXRoIGFscGhh
bnVtZXJpY3MsCiB3aXRoIGRhc2hlcyAoLSksIHVuZGVyc2NvcmVzIChfKSwgZG90cyAoLiks
IGFuZCBhbHBoYW51bWVyaWNzIGJldHdlZW4uCgoNCgUEAAIOBhIEjAECFQoNCgUEAAIOARIE
jAEWIQoNCgUEAAIOAxIEjAEkJgoNCgUEAAIOCBIEjAEnTwoQCggEAAIOCJwIABIEjAEoTgo6
CgQEAAIPEgaPAQKQATIaKiBPdXRwdXQgb25seS4gV29ya2xvYWQgSWRlbnRpdHkgc2V0dGlu
Z3MuCgoNCgUEAAIPBhIEjwECGAoNCgUEAAIPARIEjwEZMQoNCgUEAAIPAxIEjwE0NgoNCgUE
AAIPCBIEkAEGMQoQCggEAAIPCJwIABIEkAEHMApBCgQEAAIQEgSTAQJNGjMgT3B0aW9uYWwu
IExvZ2dpbmcgY29uZmlndXJhdGlvbiBmb3IgdGhpcyBjbHVzdGVyLgoKDQoFBAACEAYSBJMB
Ag8KDQoFBAACEAESBJMBEB4KDQoFBAACEAMSBJMBISMKDQoFBAACEAgSBJMBJEwKEAoIBAAC
EAicCAASBJMBJUsKRAoEBAACERIGlgEClwEyGjQgT3V0cHV0IG9ubHkuIEEgc2V0IG9mIGVy
cm9ycyBmb3VuZCBpbiB0aGUgY2x1c3Rlci4KCg0KBQQAAhEEEgSWAQIKCg0KBQQAAhEGEgSW
AQsfCg0KBQQAAhEBEgSWASAmCg0KBQQAAhEDEgSWASkrCg0KBQQAAhEIEgSXAQYxChAKCAQA
AhEInAgAEgSXAQcwCk8KBAQAAhISBpoBApsBLxo/IE9wdGlvbmFsLiBDb25maWd1cmF0aW9u
IHJlbGF0ZWQgdG8gdGhlIGNsdXN0ZXIgUkJBQyBzZXR0aW5ncy4KCg0KBQQAAhIGEgSaAQIf
Cg0KBQQAAhIBEgSaASAtCg0KBQQAAhIDEgSaATAyCg0KBQQAAhIIEgSbAQYuChAKCAQAAhII
nAgAEgSbAQctCkYKBAQAAhMSBp4BAp8BLxo2IE9wdGlvbmFsLiBNb25pdG9yaW5nIGNvbmZp
Z3VyYXRpb24gZm9yIHRoaXMgY2x1c3Rlci4KCg0KBQQAAhMGEgSeAQISCg0KBQQAAhMBEgSe
ARMkCg0KBQQAAhMDEgSeAScpCg0KBQQAAhMIEgSfAQYuChAKCAQAAhMInAgAEgSfAQctCk0K
BAQAAhQSBqIBAqMBLxo9IE9wdGlvbmFsLiBQcm94eSBjb25maWd1cmF0aW9uIGZvciBvdXRi
b3VuZCBIVFRQKFMpIHRyYWZmaWMuCgoNCgUEAAIUBhIEogECFQoNCgUEAAIUARIEogEWIgoN
CgUEAAIUAxIEogElJwoNCgUEAAIUCBIEowEGLgoQCggEAAIUCJwIABIEowEHLQpQCgQEAAIV
EgamAQKnAS8aQCBPcHRpb25hbC4gQmluYXJ5IEF1dGhvcml6YXRpb24gY29uZmlndXJhdGlv
biBmb3IgdGhpcyBjbHVzdGVyLgoKDQoFBAACFQYSBKYBAhUKDQoFBAACFQESBKYBFioKDQoF
BAACFQMSBKYBLS8KDQoFBAACFQgSBKcBBi4KEAoIBAACFQicCAASBKcBBy0KTAoEBAACFhIG
qgECqwEvGjwgT3B0aW9uYWwuIFNlY3VyaXR5IFBvc3R1cmUgY29uZmlndXJhdGlvbiBmb3Ig
dGhpcyBjbHVzdGVyLgoKDQoFBAACFgYSBKoBAhcKDQoFBAACFgESBKoBGC8KDQoFBAACFgMS
BKoBMjQKDQoFBAACFggSBKsBBi4KEAoIBAACFgicCAASBKsBBy0KvwUKBAQAAhcSBrsBAr4B
BBquBSBPcHRpb25hbC4gSW5wdXQgb25seS4gVGFnIGtleXMgYW5kIHZhbHVlcyBkaXJlY3Rs
eSBib3VuZCB0byB0aGlzIHJlc291cmNlLgoKIFRoZSB0YWcga2V5IG11c3QgYmUgc3BlY2lm
aWVkIGluIHRoZSBmb3JtYXQKIGA8dGFnIG5hbWVzcGFjZT4vPHRhZyBrZXkgbmFtZT4sYAog
d2hlcmUgdGhlIHRhZyBuYW1lc3BhY2UgaXMgdGhlIElEIG9mIHRoZSBvcmdhbml6YXRpb24g
b3IgbmFtZSBvZiB0aGUKIHByb2plY3QgdGhhdCB0aGUgdGFnIGtleSBpcyBkZWZpbmVkIGlu
LiBUaGUgc2hvcnQgbmFtZSBvZiBhIHRhZyBrZXkgb3IKIHZhbHVlIGNhbiBoYXZlIGEgbWF4
aW11bSBsZW5ndGggb2YgMjU2IGNoYXJhY3RlcnMuIFRoZSBwZXJtaXR0ZWQgY2hhcmFjdGVy
CiBzZXQgZm9yIHRoZSBzaG9ydCBuYW1lIGluY2x1ZGVzIFVURi04IGVuY29kZWQgVW5pY29k
ZSBjaGFyYWN0ZXJzIGV4Y2VwdAogc2luZ2xlIHF1b3RhdGlvbiBtYXJrcyAoYCdgKSwgZG91
YmxlIHF1b3RhdGlvbiBtYXJrcyAoYCJgKSwgYmFja3NsYXNoZXMKIChgXGApLCBhbmQgZm9y
d2FyZCBzbGFzaGVzIChgL2ApLgoKIFNlZQogW1RhZ3NdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2RvY3MvdGFncy90YWdzLW92ZXJ2aWV3KQogZm9yIG1v
cmUgZGV0YWlscyBvbiBHb29nbGUgQ2xvdWQgUGxhdGZvcm0gdGFncy4KCg0KBQQAAhcGEgS7
AQIVCg0KBQQAAhcBEgS7ARYaCg0KBQQAAhcDEgS7AR0fCg8KBQQAAhcIEga7ASC+AQMKEAoI
BAACFwicCAASBLwBBCoKEAoIBAACFwicCAESBL0BBCwKZAoEBAACGBIGwgECwwEvGlQgT3B0
aW9uYWwuIEt1YmVybmV0ZXMgY29uZmlndXJhdGlvbnMgZm9yIGF1dG8taW5zdGFsbGVkIGNv
bXBvbmVudHMgb24gdGhlCiBjbHVzdGVyLgoKDQoFBAACGAYSBMIBAhgKDQoFBAACGAESBMIB
GTEKDQoFBAACGAMSBMIBNDYKDQoFBAACGAgSBMMBBi4KEAoIBAACGAicCAASBMMBBy0KQwoC
BAESBscBANkBARo1IENvbmZpZ3VyYXRpb24gcmVsYXRlZCB0byB0aGUgY2x1c3RlciBSQkFD
IHNldHRpbmdzLgoKCwoDBAEBEgTHAQglCs0CCgQEAQIAEgbOAQLPAS8avAIgT3B0aW9uYWwu
IFVzZXJzIHRoYXQgY2FuIHBlcmZvcm0gb3BlcmF0aW9ucyBhcyBhIGNsdXN0ZXIgYWRtaW4u
IEEgbWFuYWdlZAogQ2x1c3RlclJvbGVCaW5kaW5nIHdpbGwgYmUgY3JlYXRlZCB0byBncmFu
dCB0aGUgYGNsdXN0ZXItYWRtaW5gIENsdXN0ZXJSb2xlCiB0byB0aGUgdXNlcnMuIFVwIHRv
IHRlbiBhZG1pbiB1c2VycyBjYW4gYmUgcHJvdmlkZWQuCgogRm9yIG1vcmUgaW5mbyBvbiBS
QkFDLCBzZWUKIGh0dHBzOi8va3ViZXJuZXRlcy5pby9kb2NzL3JlZmVyZW5jZS9hY2Nlc3Mt
YXV0aG4tYXV0aHovcmJhYy8jdXNlci1mYWNpbmctcm9sZXMKCg0KBQQBAgAEEgTOAQIKCg0K
BQQBAgAGEgTOAQseCg0KBQQBAgABEgTOAR8qCg0KBQQBAgADEgTOAS0uCg0KBQQBAgAIEgTP
AQYuChAKCAQBAgAInAgAEgTPAQctCtkCCgQEAQIBEgbXAQLYAS8ayAIgT3B0aW9uYWwuIEdy
b3VwcyBvZiB1c2VycyB0aGF0IGNhbiBwZXJmb3JtIG9wZXJhdGlvbnMgYXMgYSBjbHVzdGVy
IGFkbWluLiBBCiBtYW5hZ2VkIENsdXN0ZXJSb2xlQmluZGluZyB3aWxsIGJlIGNyZWF0ZWQg
dG8gZ3JhbnQgdGhlIGBjbHVzdGVyLWFkbWluYAogQ2x1c3RlclJvbGUgdG8gdGhlIGdyb3Vw
cy4gVXAgdG8gdGVuIGFkbWluIGdyb3VwcyBjYW4gYmUgcHJvdmlkZWQuCgogRm9yIG1vcmUg
aW5mbyBvbiBSQkFDLCBzZWUKIGh0dHBzOi8va3ViZXJuZXRlcy5pby9kb2NzL3JlZmVyZW5j
ZS9hY2Nlc3MtYXV0aG4tYXV0aHovcmJhYy8jdXNlci1mYWNpbmctcm9sZXMKCg0KBQQBAgEE
EgTXAQIKCg0KBQQBAgEGEgTXAQsfCg0KBQQBAgEBEgTXASAsCg0KBQQBAgEDEgTXAS8wCg0K
BQQBAgEIEgTYAQYuChAKCAQBAgEInAgAEgTYAQctCkgKAgQCEgbcAQDfAQEaOiBJZGVudGl0
aWVzIG9mIGEgdXNlci10eXBlIHN1YmplY3QgZm9yIEF0dGFjaGVkIGNsdXN0ZXJzLgoKCwoD
BAIBEgTcAQgbCksKBAQCAgASBN4BAj8aPSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHVz
ZXIsIGUuZy4gYG15LWdjcC1pZEBnbWFpbC5jb21gLgoKDQoFBAICAAUSBN4BAggKDQoFBAIC
AAESBN4BCREKDQoFBAICAAMSBN4BFBUKDQoFBAICAAgSBN4BFj4KEAoIBAICAAicCAASBN4B
Fz0KSQoCBAMSBuIBAOUBARo7IElkZW50aXRpZXMgb2YgYSBncm91cC10eXBlIHN1YmplY3Qg
Zm9yIEF0dGFjaGVkIGNsdXN0ZXJzLgoKCwoDBAMBEgTiAQgcCkwKBAQDAgASBOQBAjwaPiBS
ZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGdyb3VwLCBlLmcuIGBteS1ncm91cEBkb21haW4u
Y29tYC4KCg0KBQQDAgAFEgTkAQIICg0KBQQDAgABEgTkAQkOCg0KBQQDAgADEgTkARESCg0K
BQQDAgAIEgTkARM7ChAKCAQDAgAInAgAEgTkARQ6CtAECgIEBBIG8gEA/gEBGsEEIE9JREMg
ZGlzY292ZXJ5IGluZm9ybWF0aW9uIG9mIHRoZSB0YXJnZXQgY2x1c3Rlci4KCiBLdWJlcm5l
dGVzIFNlcnZpY2UgQWNjb3VudCAoS1NBKSB0b2tlbnMgYXJlIEpXVCB0b2tlbnMgc2lnbmVk
IGJ5IHRoZSBjbHVzdGVyCiBBUEkgc2VydmVyLiBUaGlzIGZpZWxkcyBpbmRpY2F0ZXMgaG93
IEdvb2dsZSBDbG91ZCBQbGF0Zm9ybSBzZXJ2aWNlcwogdmFsaWRhdGUgS1NBIHRva2VucyBp
biBvcmRlciB0byBhbGxvdyBzeXN0ZW0gd29ya2xvYWRzIChzdWNoIGFzIEdLRSBDb25uZWN0
CiBhbmQgdGVsZW1ldHJ5IGFnZW50cykgdG8gYXV0aGVudGljYXRlIGJhY2sgdG8gR29vZ2xl
IENsb3VkIFBsYXRmb3JtLgoKIEJvdGggY2x1c3RlcnMgd2l0aCBwdWJsaWMgYW5kIHByaXZh
dGUgaXNzdWVyIFVSTHMgYXJlIHN1cHBvcnRlZC4KIENsdXN0ZXJzIHdpdGggcHVibGljIGlz
c3VlcnMgb25seSBuZWVkIHRvIHNwZWNpZnkgdGhlIGBpc3N1ZXJfdXJsYCBmaWVsZAogd2hp
bGUgY2x1c3RlcnMgd2l0aCBwcml2YXRlIGlzc3VlcnMgbmVlZCB0byBwcm92aWRlIGJvdGgK
IGBpc3N1ZXJfdXJsYCBhbmQgYG9pZGNfandrc2AuCgoLCgMEBAESBPIBCBoKVwoEBAQCABIE
9AECGBpJIEEgSlNPTiBXZWIgVG9rZW4gKEpXVCkgaXNzdWVyIFVSSS4gYGlzc3VlcmAgbXVz
dCBzdGFydCB3aXRoIGBodHRwczovL2AuCgoNCgUEBAIABRIE9AECCAoNCgUEBAIAARIE9AEJ
EwoNCgUEBAIAAxIE9AEWFwrXAgoEBAQCARIE/QECOhrIAiBPcHRpb25hbC4gT0lEQyB2ZXJp
ZmljYXRpb24ga2V5cyBpbiBKV0tTIGZvcm1hdCAoUkZDIDc1MTcpLgogSXQgY29udGFpbnMg
YSBsaXN0IG9mIE9JREMgdmVyaWZpY2F0aW9uIGtleXMgdGhhdCBjYW4gYmUgdXNlZCB0byB2
ZXJpZnkKIE9JREMgSldUcy4KCiBUaGlzIGZpZWxkIGlzIHJlcXVpcmVkIGZvciBjbHVzdGVy
IHRoYXQgZG9lc24ndCBoYXZlIGEgcHVibGljbHkgYXZhaWxhYmxlCiBkaXNjb3ZlcnkgZW5k
cG9pbnQuIFdoZW4gcHJvdmlkZWQsIGl0IHdpbGwgYmUgZGlyZWN0bHkgdXNlZAogdG8gdmVy
aWZ5IHRoZSBPSURDIEpXVCBhc3NlcnRlZCBieSB0aGUgSURQLgoKDQoFBAQCAQUSBP0BAgcK
DQoFBAQCAQESBP0BCAwKDQoFBAQCAQMSBP0BDxAKDQoFBAQCAQgSBP0BETkKEAoIBAQCAQic
CAASBP0BEjgKXgoCBAUSBoICAI0CARpQIEF0dGFjaGVkU2VydmVyQ29uZmlnIHByb3ZpZGVz
IGluZm9ybWF0aW9uIGFib3V0IHN1cHBvcnRlZAogS3ViZXJuZXRlcyB2ZXJzaW9ucwoKCwoD
BAUBEgSCAggcCg0KAwQFBxIGgwIChgIECg8KBQQFB50IEgaDAgKGAgQKMAoEBAUCABIEiQIC
EhoiIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjb25maWcuCgoNCgUEBQIABRIEiQICCAoN
CgUEBQIAARIEiQIJDQoNCgUEBQIAAxIEiQIQEQowCgQEBQIBEgSMAgI6GiIgTGlzdCBvZiB2
YWxpZCBwbGF0Zm9ybSB2ZXJzaW9ucy4KCg0KBQQFAgEEEgSMAgIKCg0KBQQFAgEGEgSMAgsm
Cg0KBQQFAgEBEgSMAic1Cg0KBQQFAgEDEgSMAjg5ClEKAgQGEgaQAgCmAgEaQyBJbmZvcm1h
dGlvbiBhYm91dCBhIHN1cHBvcnRlZCBBdHRhY2hlZCBDbHVzdGVycyBwbGF0Zm9ybSB2ZXJz
aW9uLgoKCwoDBAYBEgSQAggjCiYKBAQGAgASBJICAhUaGCBQbGF0Zm9ybSB2ZXJzaW9uIG5h
bWUuCgoNCgUEBgIABRIEkgICCAoNCgUEBgIAARIEkgIJEAoNCgUEBgIAAxIEkgITFAqaAQoE
BAYCARIElgICPBqLASBPcHRpb25hbC4gVHJ1ZSBpZiB0aGUgdmVyc2lvbiBpcyBhdmFpbGFi
bGUgZm9yIGF0dGFjaGVkY2x1c3RlciBjcmVhdGlvbi4gSWYKIGEgdmVyc2lvbiBpcyBlbmFi
bGVkLCBpdCBjYW4gYmUgdXNlZCB0byBhdHRhY2ggbmV3IGNsdXN0ZXJzLgoKDQoFBAYCAQUS
BJYCAgYKDQoFBAYCAQESBJYCBw4KDQoFBAYCAQMSBJYCERIKDQoFBAYCAQgSBJYCEzsKEAoI
BAYCAQicCAASBJYCFDoKsgEKBAQGAgISBJsCAkAaowEgT3B0aW9uYWwuIFRydWUgaWYgdGhp
cyBjbHVzdGVyIHZlcnNpb24gYmVsb25ncyB0byBhIG1pbm9yIHZlcnNpb24gdGhhdCBoYXMK
IHJlYWNoZWQgaXRzIGVuZCBvZiBsaWZlIGFuZCBpcyBubyBsb25nZXIgaW4gc2NvcGUgdG8g
cmVjZWl2ZSBzZWN1cml0eSBhbmQKIGJ1ZyBmaXhlcy4KCg0KBQQGAgIFEgSbAgIGCg0KBQQG
AgIBEgSbAgcSCg0KBQQGAgIDEgSbAhUWCg0KBQQGAgIIEgSbAhc/ChAKCAQGAgIInAgAEgSb
Ahg+CpsCCgQEBgIDEgahAgKiAi8aigIgT3B0aW9uYWwuIFRoZSBlc3RpbWF0ZWQgZGF0ZSAo
aW4gUGFjaWZpYyBUaW1lKSB3aGVuIHRoaXMgY2x1c3RlciB2ZXJzaW9uCiB3aWxsIHJlYWNo
IGl0cyBlbmQgb2YgbGlmZS4gT3IgaWYgdGhpcyB2ZXJzaW9uIGlzIG5vIGxvbmdlciBzdXBw
b3J0ZWQgKHRoZQogYGVuZF9vZl9saWZlYCBmaWVsZCBpcyB0cnVlKSwgdGhpcyBpcyB0aGUg
YWN0dWFsIGRhdGUgKGluIFBhY2lmaWMgdGltZSkKIHdoZW4gdGhlIHZlcnNpb24gcmVhY2hl
ZCBpdHMgZW5kIG9mIGxpZmUuCgoNCgUEBgIDBhIEoQICEgoNCgUEBgIDARIEoQITIwoNCgUE
BgIDAxIEoQImJwoNCgUEBgIDCBIEogIGLgoQCggEBgIDCJwIABIEogIHLQpbCgQEBgIEEgSl
AgJNGk0gT3B0aW9uYWwuIFRoZSBkYXRlIChpbiBQYWNpZmljIFRpbWUpIHdoZW4gdGhlIGNs
dXN0ZXIgdmVyc2lvbiB3YXMgcmVsZWFzZWQuCgoNCgUEBgIEBhIEpQICEgoNCgUEBgIEARIE
pQITHwoNCgUEBgIEAxIEpQIiIwoNCgUEBgIECBIEpQIkTAoQCggEBgIECJwIABIEpQIlSwpR
CgIEBxIGqQIArAIBGkMgQXR0YWNoZWRDbHVzdGVyRXJyb3IgZGVzY3JpYmVzIGVycm9ycyBm
b3VuZCBvbiBhdHRhY2hlZCBjbHVzdGVycy4KCgsKAwQHARIEqQIIHAo4CgQEBwIAEgSrAgIV
GiogSHVtYW4tZnJpZW5kbHkgZGVzY3JpcHRpb24gb2YgdGhlIGVycm9yLgoKDQoFBAcCAAUS
BKsCAggKDQoFBAcCAAESBKsCCRAKDQoFBAcCAAMSBKsCExQKKgoCBAgSBq8CALgCARocIERl
dGFpbHMgb2YgYSBwcm94eSBjb25maWcuCgoLCgMECAESBK8CCBsKuQMKBAQIAgASBLcCAika
qgMgVGhlIEt1YmVybmV0ZXMgU2VjcmV0IHJlc291cmNlIHRoYXQgY29udGFpbnMgdGhlIEhU
VFAoUykgcHJveHkKIGNvbmZpZ3VyYXRpb24uIFRoZSBzZWNyZXQgbXVzdCBiZSBhIEpTT04g
ZW5jb2RlZCBwcm94eSBjb25maWd1cmF0aW9uCiBhcyBkZXNjcmliZWQgaW4KIGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9rdWJlcm5ldGVzLWVuZ2luZS9tdWx0aS1jbG91ZC9kb2NzL2F0
dGFjaGVkL2Vrcy9ob3ctdG8vdXNlLWEtcHJveHkjY29uZmlndXJlLXByb3h5LXN1cHBvcnQK
IGZvciBFS1MgY2x1c3RlcnMgYW5kCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20va3ViZXJu
ZXRlcy1lbmdpbmUvbXVsdGktY2xvdWQvZG9jcy9hdHRhY2hlZC9ha3MvaG93LXRvL3VzZS1h
LXByb3h5I2NvbmZpZ3VyZS1wcm94eS1zdXBwb3J0CiBmb3IgQUtTIGNsdXN0ZXJzLgoKDQoF
BAgCAAYSBLcCAhIKDQoFBAgCAAESBLcCEyQKDQoFBAgCAAMSBLcCJygKNQoCBAkSBrsCAMEC
ARonIEluZm9ybWF0aW9uIGFib3V0IGEgS3ViZXJuZXRlcyBTZWNyZXQKCgsKAwQJARIEuwII
GAouCgQECQIAEgS9AgISGiAgTmFtZSBvZiB0aGUga3ViZXJuZXRlcyBzZWNyZXQuCgoNCgUE
CQIABRIEvQICCAoNCgUECQIAARIEvQIJDQoNCgUECQIAAxIEvQIQEQpDCgQECQIBEgTAAgIX
GjUgTmFtZXNwYWNlIGluIHdoaWNoIHRoZSBrdWJlcm5ldGVzIHNlY3JldCBpcyBzdG9yZWQu
CgoNCgUECQIBBRIEwAICCAoNCgUECQIBARIEwAIJEgoNCgUECQIBAxIEwAIVFgp4CgIEChIG
xQIAywIBGmogU3lzdGVtQ29tcG9uZW50c0NvbmZpZyBkZWZpbmVzIHRoZSBmaWVsZHMgZm9y
IGN1c3RvbWl6aW5nIGNvbmZpZ3VyYXRpb25zIGZvcgogYXV0by1pbnN0YWxsZWQgY29tcG9u
ZW50cy4KCgsKAwQKARIExQIIHgpWCgQECgIAEgTHAgImGkggU2V0cyBjdXN0b20gdG9sZXJh
dGlvbnMgZm9yIHBvZHMgY3JlYXRlZCBieSBhdXRvLWluc3RhbGxlZCBjb21wb25lbnRzLgoK
DQoFBAoCAAQSBMcCAgoKDQoFBAoCAAYSBMcCCxUKDQoFBAoCAAESBMcCFiEKDQoFBAoCAAMS
BMcCJCUKUQoEBAoCARIEygICHBpDIFNldHMgY3VzdG9tIGxhYmVscyBmb3IgcG9kcyBjcmVh
dGVkIGJ5IGF1dG8taW5zdGFsbGVkIGNvbXBvbmVudHMuCgoNCgUECgIBBBIEygICCgoNCgUE
CgIBBhIEygILEAoNCgUECgIBARIEygIRFwoNCgUECgIBAxIEygIaGwptCgIECxIGzwIA9gIB
Gl8gVG9sZXJhdGlvbiBkZWZpbmVzIHRoZSBmaWVsZHMgZm9yIHRvbGVyYXRpb25zIGZvciBw
b2RzIGNyZWF0ZWQgYnkKIGF1dG8taW5zdGFsbGVkIGNvbXBvbmVudHMuCgoLCgMECwESBM8C
CBIKWAoEBAsEABIG0QIC2gIDGkggS2V5T3BlcmF0b3IgcmVwcmVzZW50cyBhIGtleSdzIHJl
bGF0aW9uc2hpcCB0byB0aGUgdmFsdWUgZS5nLiAnRXF1YWwnLgoKDQoFBAsEAAESBNECBxIK
LAoGBAsEAAIAEgTTAgQhGhwgT3BlcmF0b3IgaXMgbm90IHNwZWNpZmllZC4KCg8KBwQLBAAC
AAESBNMCBBwKDwoHBAsEAAIAAhIE0wIfIAorCgYECwQAAgESBNYCBBsaGyBPcGVyYXRvciBt
YXBzIHRvICdFcXVhbCcuCgoPCgcECwQAAgEBEgTWAgQWCg8KBwQLBAACAQISBNYCGRoKLAoG
BAsEAAICEgTZAgQcGhwgT3BlcmF0b3IgbWFwcyB0byAnRXhpc3RzJy4KCg8KBwQLBAACAgES
BNkCBBcKDwoHBAsEAAICAhIE2QIaGwpPCgQECwQBEgbdAgLpAgMaPyBFZmZlY3QgaW5kaWNh
dGVzIHRoZSB0YWludCBlZmZlY3QgdG8gbWF0Y2ggZS5nLiAnTm9TY2hlZHVsZScuCgoNCgUE
CwQBARIE3QIHDQoqCgYECwQBAgASBN8CBBsaGiBFZmZlY3QgaXMgbm90IHNwZWNpZmllZC4K
Cg8KBwQLBAECAAESBN8CBBYKDwoHBAsEAQIAAhIE3wIZGgouCgYECwQBAgESBOICBBsaHiBF
ZmZlY3QgbWFwcyB0byAnTm9TY2hlZHVsZScuCgoPCgcECwQBAgEBEgTiAgQWCg8KBwQLBAEC
AQISBOICGRoKNAoGBAsEAQICEgTlAgQiGiQgRWZmZWN0IG1hcHMgdG8gJ1ByZWZlck5vU2No
ZWR1bGUnLgoKDwoHBAsEAQICARIE5QIEHQoPCgcECwQBAgICEgTlAiAhCi0KBgQLBAECAxIE
6AIEGhodIEVmZmVjdCBtYXBzIHRvICdOb0V4ZWN1dGUnLgoKDwoHBAsEAQIDARIE6AIEFQoP
CgcECwQBAgMCEgToAhgZCkQKBAQLAgASBOwCAhEaNiBLZXkgaXMgdGhlIHRhaW50IGtleSB0
aGF0IHRoZSB0b2xlcmF0aW9uIGFwcGxpZXMgdG8uCgoNCgUECwIABRIE7AICCAoNCgUECwIA
ARIE7AIJDAoNCgUECwIAAxIE7AIPEApICgQECwIBEgTvAgITGjogVmFsdWUgaXMgdGhlIHRh
aW50IHZhbHVlIHRoYXQgdGhlIHRvbGVyYXRpb24gYXBwbGllcyB0by4KCg0KBQQLAgEFEgTv
AgIICg0KBQQLAgEBEgTvAgkOCg0KBQQLAgEDEgTvAhESClYKBAQLAgISBPICAh8aSCBLZXlP
cGVyYXRvciByZXByZXNlbnRzIGEga2V5J3MgcmVsYXRpb25zaGlwIHRvIHRoZSB2YWx1ZSBl
LmcuICdFeGlzdCcuCgoNCgUECwICBhIE8gICDQoNCgUECwICARIE8gIOGgoNCgUECwICAxIE
8gIdHgpMCgQECwIDEgT1AgIUGj4gRWZmZWN0IGluZGljYXRlcyB0aGUgdGFpbnQgZWZmZWN0
IHRvIG1hdGNoIGUuZy4gJ05vU2NoZWR1bGUnCgoNCgUECwIDBhIE9QICCAoNCgUECwIDARIE
9QIJDwoNCgUECwIDAxIE9QISEwpuCgIEDBIG+gIAgAMBGmAgTGFiZWwgZGVmaW5lcyB0aGUg
YWRkaXRpb25hbCBmaWVsZHMgZm9yIGxhYmVscyBmb3IgcG9kcyBjcmVhdGVkIGJ5CiBhdXRv
LWluc3RhbGxlZCBjb21wb25lbnRzLgoKCwoDBAwBEgT6AggNCi0KBAQMAgASBPwCAhEaHyBU
aGlzIGlzIHRoZSBrZXkgb2YgdGhlIGxhYmVsLgoKDQoFBAwCAAUSBPwCAggKDQoFBAwCAAES
BPwCCQwKDQoFBAwCAAMSBPwCDxAKLwoEBAwCARIE/wICExohIFRoaXMgaXMgdGhlIHZhbHVl
IG9mIHRoZSBsYWJlbC4KCg0KBQQMAgEFEgT/AgIICg0KBQQMAgEBEgT/AgkOCg0KBQQMAgED
EgT/AhESYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster ===
    # Fields for AttachedCluster
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: oidc_config Type: 11 (.google.cloud.gkemulticloud.v1.AttachedOidcConfig)
    # Field: platform_version Type: 9 ()
    # Field: distribution Type: 9 ()
    # Field: cluster_region Type: 9 ()
    # Field: fleet Type: 11 (.google.cloud.gkemulticloud.v1.Fleet)
    # Field: state Type: 14 (.google.cloud.gkemulticloud.v1.AttachedCluster.State)
    # Field: uid Type: 9 ()
    # Field: reconciling Type: 8 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: kubernetes_version Type: 9 ()
    # Field: annotations Type: 11 (.google.cloud.gkemulticloud.v1.AttachedCluster.AnnotationsEntry)
    # Field: workload_identity_config Type: 11 (.google.cloud.gkemulticloud.v1.WorkloadIdentityConfig)
    # Field: logging_config Type: 11 (.google.cloud.gkemulticloud.v1.LoggingConfig)
    # Field: errors Type: 11 (.google.cloud.gkemulticloud.v1.AttachedClusterError)
    # Field: authorization Type: 11 (.google.cloud.gkemulticloud.v1.AttachedClustersAuthorization)
    # Field: monitoring_config Type: 11 (.google.cloud.gkemulticloud.v1.MonitoringConfig)
    # Field: proxy_config Type: 11 (.google.cloud.gkemulticloud.v1.AttachedProxyConfig)
    # Field: binary_authorization Type: 11 (.google.cloud.gkemulticloud.v1.BinaryAuthorization)
    # Field: security_posture_config Type: 11 (.google.cloud.gkemulticloud.v1.SecurityPostureConfig)
    # Field: tags Type: 11 (.google.cloud.gkemulticloud.v1.AttachedCluster.TagsEntry)
    # Field: system_components_config Type: 11 (.google.cloud.gkemulticloud.v1.SystemComponentsConfig)

# Enum: AttachedCluster::State
our $AttachedCluster_STATE_UNSPECIFIED = 0;
our $AttachedCluster_PROVISIONING = 1;
our $AttachedCluster_RUNNING = 2;
our $AttachedCluster_RECONCILING = 3;
our $AttachedCluster_STOPPING = 4;
our $AttachedCluster_ERROR = 5;
our $AttachedCluster_DEGRADED = 6;

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization ===
    # Fields for AttachedClustersAuthorization
    # Field: admin_users Type: 11 (.google.cloud.gkemulticloud.v1.AttachedClusterUser)
    # Field: admin_groups Type: 11 (.google.cloud.gkemulticloud.v1.AttachedClusterGroup)

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser ===
    # Fields for AttachedClusterUser
    # Field: username Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup ===
    # Fields for AttachedClusterGroup
    # Field: group Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig ===
    # Fields for AttachedOidcConfig
    # Field: issuer_url Type: 9 ()
    # Field: jwks Type: 12 ()

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedServerConfig ===
    # Fields for AttachedServerConfig
    # Field: name Type: 9 ()
    # Field: valid_versions Type: 11 (.google.cloud.gkemulticloud.v1.AttachedPlatformVersionInfo)

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo ===
    # Fields for AttachedPlatformVersionInfo
    # Field: version Type: 9 ()
    # Field: enabled Type: 8 ()
    # Field: end_of_life Type: 8 ()
    # Field: end_of_life_date Type: 11 (.google.type.Date)
    # Field: release_date Type: 11 (.google.type.Date)

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError ===
    # Fields for AttachedClusterError
    # Field: message Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig ===
    # Fields for AttachedProxyConfig
    # Field: kubernetes_secret Type: 11 (.google.cloud.gkemulticloud.v1.KubernetesSecret)

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret ===
    # Fields for KubernetesSecret
    # Field: name Type: 9 ()
    # Field: namespace Type: 9 ()

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig ===
    # Fields for SystemComponentsConfig
    # Field: tolerations Type: 11 (.google.cloud.gkemulticloud.v1.Toleration)
    # Field: labels Type: 11 (.google.cloud.gkemulticloud.v1.Label)

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration ===
    # Fields for Toleration
    # Field: key Type: 9 ()
    # Field: value Type: 9 ()
    # Field: key_operator Type: 14 (.google.cloud.gkemulticloud.v1.Toleration.KeyOperator)
    # Field: effect Type: 14 (.google.cloud.gkemulticloud.v1.Toleration.Effect)

# Enum: Toleration::KeyOperator
our $Toleration_KEY_OPERATOR_UNSPECIFIED = 0;
our $Toleration_KEY_OPERATOR_EQUAL = 1;
our $Toleration_KEY_OPERATOR_EXISTS = 2;

# Enum: Toleration::Effect
our $Toleration_EFFECT_UNSPECIFIED = 0;
our $Toleration_EFFECT_NO_SCHEDULE = 1;
our $Toleration_EFFECT_PREFER_NO_SCHEDULE = 2;
our $Toleration_EFFECT_NO_EXECUTE = 3;

# === Message: Google::Cloud::Gkemulticloud::V1::AttachedResources::Label ===
    # Fields for Label
    # Field: key Type: 9 ()
    # Field: value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AttachedResources - Compiled Protocol Buffers messages for google/cloud/gkemulticloud/v1/attached_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkemulticloud::V1::AttachedResources;

    my $msg = Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster->new({
        name => $name,
        description => $description,
        oidc_config => $oidc_config,
        platform_version => $platform_version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkemulticloud/v1/attached_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster

An Anthos cluster running on customer own infrastructure.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of this resource.

Cluster names are formatted as
`projects/<project-number>/locations/<region>/attachedClusters/<cluster-id>`.

See [Resource Names](https://cloud.google.com/apis/design/resource_names)
for more details on Google Cloud Platform resource names.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A human readable description of this cluster.
Cannot be longer than 255 UTF-8 encoded bytes.

=item * C<< $msg->oidc_config() >> / C<< $msg->oidc_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig>)

Required. OpenID Connect (OIDC) configuration for the cluster.

=item * C<< $msg->platform_version() >> / C<< $msg->platform_version($value) >>

Type: C<String>

Required. The platform version for the cluster (e.g. `1.19.0-gke.1000`).

You can list all supported versions on a given Google Cloud region by
calling
[GetAttachedServerConfig][google.cloud.gkemulticloud.v1.AttachedClusters.GetAttachedServerConfig].

=item * C<< $msg->distribution() >> / C<< $msg->distribution($value) >>

Type: C<String>

Required. The Kubernetes distribution of the underlying attached cluster.

Supported values: ["eks", "aks", "generic"].

=item * C<< $msg->cluster_region() >> / C<< $msg->cluster_region($value) >>

Type: C<String>

Output only. The region where this cluster runs.

For EKS clusters, this is a AWS region. For AKS clusters,
this is an Azure region.

=item * C<< $msg->fleet() >> / C<< $msg->fleet($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet>)

Required. Fleet configuration.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::AttachedCluster::State>)

Output only. The current state of the cluster.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A globally unique identifier for the cluster.

=item * C<< $msg->reconciling() >> / C<< $msg->reconciling($value) >>

Type: C<Bool>

Output only. If set, there are currently changes in flight to the cluster.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this cluster was registered.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which this cluster was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Allows clients to perform consistent read-modify-writes
through optimistic concurrency control.

Can be sent on update and delete requests to ensure the
client has an up-to-date value before proceeding.

=item * C<< $msg->kubernetes_version() >> / C<< $msg->kubernetes_version($value) >>

Type: C<String>

Output only. The Kubernetes version of the cluster.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::AnnotationsEntry>)

Optional. Annotations on the cluster.

This field has the same restrictions as Kubernetes annotations.
The total size of all keys and values combined is limited to 256k.
Key can have 2 segments: prefix (optional) and name (required),
separated by a slash (/).
Prefix must be a DNS subdomain.
Name must be 63 characters or less, begin and end with alphanumerics,
with dashes (-), underscores (_), dots (.), and alphanumerics between.

=item * C<< $msg->workload_identity_config() >> / C<< $msg->workload_identity_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig>)

Output only. Workload Identity settings.

=item * C<< $msg->logging_config() >> / C<< $msg->logging_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig>)

Optional. Logging configuration for this cluster.

=item * C<< $msg->errors() >> / C<< $msg->errors($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError>)

Output only. A set of errors found in the cluster.

=item * C<< $msg->authorization() >> / C<< $msg->authorization($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization>)

Optional. Configuration related to the cluster RBAC settings.

=item * C<< $msg->monitoring_config() >> / C<< $msg->monitoring_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig>)

Optional. Monitoring configuration for this cluster.

=item * C<< $msg->proxy_config() >> / C<< $msg->proxy_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig>)

Optional. Proxy configuration for outbound HTTP(S) traffic.

=item * C<< $msg->binary_authorization() >> / C<< $msg->binary_authorization($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization>)

Optional. Binary Authorization configuration for this cluster.

=item * C<< $msg->security_posture_config() >> / C<< $msg->security_posture_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig>)

Optional. Security Posture configuration for this cluster.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::TagsEntry>)

Optional. Input only. Tag keys and values directly bound to this resource.

The tag key must be specified in the format
`<tag namespace>/<tag key name>,`
where the tag namespace is the ID of the organization or name of the
project that the tag key is defined in. The short name of a tag key or
value can have a maximum length of 256 characters. The permitted character
set for the short name includes UTF-8 encoded Unicode characters except
single quotation marks (`'`), double quotation marks (`"`), backslashes
(`\`), and forward slashes (`/`).

See
[Tags](https://cloud.google.com/resource-manager/docs/tags/tags-overview)
for more details on Google Cloud Platform tags.

=item * C<< $msg->system_components_config() >> / C<< $msg->system_components_config($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig>)

Optional. Kubernetes configurations for auto-installed components on the
cluster.

=back

=head3 Enum: AttachedCluster::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<RECONCILING> => C<3>

=item * C<STOPPING> => C<4>

=item * C<ERROR> => C<5>

=item * C<DEGRADED> => C<6>

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization

Configuration related to the cluster RBAC settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->admin_users() >> / C<< $msg->admin_users($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser>)

Optional. Users that can perform operations as a cluster admin. A managed
ClusterRoleBinding will be created to grant the `cluster-admin` ClusterRole
to the users. Up to ten admin users can be provided.

For more info on RBAC, see
https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles

=item * C<< $msg->admin_groups() >> / C<< $msg->admin_groups($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup>)

Optional. Groups of users that can perform operations as a cluster admin. A
managed ClusterRoleBinding will be created to grant the `cluster-admin`
ClusterRole to the groups. Up to ten admin groups can be provided.

For more info on RBAC, see
https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser

Identities of a user-type subject for Attached clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

Required. The name of the user, e.g. `my-gcp-id@gmail.com`.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup

Identities of a group-type subject for Attached clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->group() >> / C<< $msg->group($value) >>

Type: C<String>

Required. The name of the group, e.g. `my-group@domain.com`.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig

OIDC discovery information of the target cluster.

Kubernetes Service Account (KSA) tokens are JWT tokens signed by the cluster
API server. This fields indicates how Google Cloud Platform services
validate KSA tokens in order to allow system workloads (such as GKE Connect
and telemetry agents) to authenticate back to Google Cloud Platform.

Both clusters with public and private issuer URLs are supported.
Clusters with public issuers only need to specify the `issuer_url` field
while clusters with private issuers need to provide both
`issuer_url` and `oidc_jwks`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->issuer_url() >> / C<< $msg->issuer_url($value) >>

Type: C<String>

A JSON Web Token (JWT) issuer URI. `issuer` must start with `https://`.

=item * C<< $msg->jwks() >> / C<< $msg->jwks($value) >>

Type: C<Bytes>

Optional. OIDC verification keys in JWKS format (RFC 7517).
It contains a list of OIDC verification keys that can be used to verify
OIDC JWTs.

This field is required for cluster that doesn't have a publicly available
discovery endpoint. When provided, it will be directly used
to verify the OIDC JWT asserted by the IDP.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedServerConfig

AttachedServerConfig provides information about supported
Kubernetes versions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the config.

=item * C<< $msg->valid_versions() >> / C<< $msg->valid_versions($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo>)

List of valid platform versions.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo

Information about a supported Attached Clusters platform version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Platform version name.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Optional. True if the version is available for attachedcluster creation. If
a version is enabled, it can be used to attach new clusters.

=item * C<< $msg->end_of_life() >> / C<< $msg->end_of_life($value) >>

Type: C<Bool>

Optional. True if this cluster version belongs to a minor version that has
reached its end of life and is no longer in scope to receive security and
bug fixes.

=item * C<< $msg->end_of_life_date() >> / C<< $msg->end_of_life_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. The estimated date (in Pacific Time) when this cluster version
will reach its end of life. Or if this version is no longer supported (the
`end_of_life` field is true), this is the actual date (in Pacific time)
when the version reached its end of life.

=item * C<< $msg->release_date() >> / C<< $msg->release_date($value) >>

Type: C<Message> (L<Google::Type::Date::Date>)

Optional. The date (in Pacific Time) when the cluster version was released.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError

AttachedClusterError describes errors found on attached clusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Human-friendly description of the error.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig

Details of a proxy config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kubernetes_secret() >> / C<< $msg->kubernetes_secret($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret>)

The Kubernetes Secret resource that contains the HTTP(S) proxy
configuration. The secret must be a JSON encoded proxy configuration
as described in
https://cloud.google.com/kubernetes-engine/multi-cloud/docs/attached/eks/how-to/use-a-proxy#configure-proxy-support
for EKS clusters and
https://cloud.google.com/kubernetes-engine/multi-cloud/docs/attached/aks/how-to/use-a-proxy#configure-proxy-support
for AKS clusters.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret

Information about a Kubernetes Secret

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the kubernetes secret.

=item * C<< $msg->namespace() >> / C<< $msg->namespace($value) >>

Type: C<String>

Namespace in which the kubernetes secret is stored.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig

SystemComponentsConfig defines the fields for customizing configurations for
auto-installed components.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tolerations() >> / C<< $msg->tolerations($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration>)

Sets custom tolerations for pods created by auto-installed components.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkemulticloud::V1::AttachedResources::Label>)

Sets custom labels for pods created by auto-installed components.

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration

Toleration defines the fields for tolerations for pods created by
auto-installed components.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Key is the taint key that the toleration applies to.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

Value is the taint value that the toleration applies to.

=item * C<< $msg->key_operator() >> / C<< $msg->key_operator($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::Toleration::KeyOperator>)

KeyOperator represents a key's relationship to the value e.g. 'Exist'.

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<Enum> (L<Google::Cloud::Gkemulticloud::V1::Toleration::Effect>)

Effect indicates the taint effect to match e.g. 'NoSchedule'

=back

=head3 Enum: Toleration::KeyOperator

=over 4

=item * C<KEY_OPERATOR_UNSPECIFIED> => C<0>

=item * C<KEY_OPERATOR_EQUAL> => C<1>

=item * C<KEY_OPERATOR_EXISTS> => C<2>

=back

=head3 Enum: Toleration::Effect

=over 4

=item * C<EFFECT_UNSPECIFIED> => C<0>

=item * C<EFFECT_NO_SCHEDULE> => C<1>

=item * C<EFFECT_PREFER_NO_SCHEDULE> => C<2>

=item * C<EFFECT_NO_EXECUTE> => C<3>

=back

=head2 Google::Cloud::Gkemulticloud::V1::AttachedResources::Label

Label defines the additional fields for labels for pods created by
auto-installed components.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

This is the key of the label.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

This is the value of the label.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkemulticloud::V1::AttachedResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
