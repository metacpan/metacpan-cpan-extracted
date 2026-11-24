package Google::Cloud::Licensemanager::V1::ApiEntities;

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
CjFnb29nbGUvY2xvdWQvbGljZW5zZW1hbmFnZXIvdjEvYXBpX2VudGl0aWVzLnByb3RvEh5n
b29nbGUuY2xvdWQubGljZW5zZW1hbmFnZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8ijAgKDUNvbmZpZ3VyYXRpb24SFwoEbmFtZRgBIAEoCUID4EEIUgRu
YW1lEiYKDGRpc3BsYXlfbmFtZRgFIAEoCUID4EECUgtkaXNwbGF5TmFtZRJHCgdwcm9kdWN0
GAYgASgJQi3gQQL6QScKJWxpY2Vuc2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2R1Y3RS
B3Byb2R1Y3QSUwoMbGljZW5zZV90eXBlGAcgASgOMisuZ29vZ2xlLmNsb3VkLmxpY2Vuc2Vt
YW5hZ2VyLnYxLkxpY2Vuc2VUeXBlQgPgQQJSC2xpY2Vuc2VUeXBlEmIKFGN1cnJlbnRfYmls
bGluZ19pbmZvGAggASgLMisuZ29vZ2xlLmNsb3VkLmxpY2Vuc2VtYW5hZ2VyLnYxLkJpbGxp
bmdJbmZvQgPgQQJSEmN1cnJlbnRCaWxsaW5nSW5mbxJcChFuZXh0X2JpbGxpbmdfaW5mbxgJ
IAEoCzIrLmdvb2dsZS5jbG91ZC5saWNlbnNlbWFuYWdlci52MS5CaWxsaW5nSW5mb0ID4EEC
Ug9uZXh0QmlsbGluZ0luZm8SQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSVgoGbGFiZWxzGAQg
AygLMjkuZ29vZ2xlLmNsb3VkLmxpY2Vuc2VtYW5hZ2VyLnYxLkNvbmZpZ3VyYXRpb24uTGFi
ZWxzRW50cnlCA+BBAVIGbGFiZWxzEk4KBXN0YXRlGAogASgOMjMuZ29vZ2xlLmNsb3VkLmxp
Y2Vuc2VtYW5hZ2VyLnYxLkNvbmZpZ3VyYXRpb24uU3RhdGVCA+BBA1IFc3RhdGUaOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJY
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhAKDFNUQVRFX0FDVElWRRABEhMKD1NU
QVRFX1NVU1BFTkRFRBACEhEKDVNUQVRFX0RFTEVURUQQAzqYAepBlAEKK2xpY2Vuc2VtYW5h
Z2VyLmdvb2dsZWFwaXMuY29tL0NvbmZpZ3VyYXRpb24SRnByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9jb25maWd1cmF0aW9ucy97Y29uZmlndXJhdGlvbn0qDmNv
bmZpZ3VyYXRpb25zMg1jb25maWd1cmF0aW9uIowCCgtCaWxsaW5nSW5mbxJpChJ1c2VyX2Nv
dW50X2JpbGxpbmcYASABKAsyNC5nb29nbGUuY2xvdWQubGljZW5zZW1hbmFnZXIudjEuVXNl
ckNvdW50QmlsbGluZ0luZm9CA+BBAkgAUhB1c2VyQ291bnRCaWxsaW5nEj4KCnN0YXJ0X3Rp
bWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXN0YXJ0VGltZRI6
CghlbmRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IHZW5k
VGltZUIWChRjdXJyZW50X2JpbGxpbmdfaW5mbyI6ChRVc2VyQ291bnRCaWxsaW5nSW5mbxIi
Cgp1c2VyX2NvdW50GAEgASgFQgPgQQJSCXVzZXJDb3VudCJBCg5Vc2VyQ291bnRVc2FnZRIv
ChF1bmlxdWVfdXNlcl9jb3VudBgBIAEoBUID4EECUg91bmlxdWVVc2VyQ291bnQikgQKB1By
b2R1Y3QSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEh0KB3ZlcnNpb24YAiABKAlCA+BBAlIH
dmVyc2lvbhIsCg9wcm9kdWN0X2NvbXBhbnkYAyABKAlCA+BBAlIOcHJvZHVjdENvbXBhbnkS
SAoFc3RhdGUYBCABKA4yLS5nb29nbGUuY2xvdWQubGljZW5zZW1hbmFnZXIudjEuUHJvZHVj
dC5TdGF0ZUID4EEDUgVzdGF0ZRIVCgNza3UYBSABKAlCA+BBAlIDc2t1EiUKC2Rlc2NyaXB0
aW9uGAYgASgJQgPgQQJSC2Rlc2NyaXB0aW9uEiYKDGRpc3BsYXlfbmFtZRgHIAEoCUID4EEC
UgtkaXNwbGF5TmFtZSJ2CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhYKElNUQVRF
X1BST1ZJU0lPTklORxABEhEKDVNUQVRFX1JVTk5JTkcQAhIVChFTVEFURV9URVJNSU5BVElO
RxADEhQKEFNUQVRFX1RFUk1JTkFURUQQBDp56kF2CiVsaWNlbnNlbWFuYWdlci5nb29nbGVh
cGlzLmNvbS9Qcm9kdWN0Ejpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcHJvZHVjdHMve3Byb2R1Y3R9Kghwcm9kdWN0czIHcHJvZHVjdCKeCAoISW5zdGFuY2US
FwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lElEKBmxh
YmVscxgEIAMoCzI0Lmdvb2dsZS5jbG91ZC5saWNlbnNlbWFuYWdlci52MS5JbnN0YW5jZS5M
YWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSSQoFc3RhdGUYBSABKA4yLi5nb29nbGUuY2xvdWQu
bGljZW5zZW1hbmFnZXIudjEuSW5zdGFuY2UuU3RhdGVCA+BBA1IFc3RhdGUSGwoGcmVnaW9u
GAYgASgJQgPgQQNSBnJlZ2lvbhJzChJwcm9kdWN0X2FjdGl2YXRpb24YByADKAsyPy5nb29n
bGUuY2xvdWQubGljZW5zZW1hbmFnZXIudjEuSW5zdGFuY2UuUHJvZHVjdEFjdGl2YXRpb25F
bnRyeUID4EEDUhFwcm9kdWN0QWN0aXZhdGlvbhIxChJsaWNlbnNlX3ZlcnNpb25faWQYCCAB
KAlCA+BBA1IQbGljZW5zZVZlcnNpb25JZBJZChBjb21wdXRlX2luc3RhbmNlGAkgASgJQi7g
QQL6QSgKJmNvbXB1dGUuZ29vZ2xlYXBpcy5jb20vQ29tcHV0ZUluc3RhbmNlUg9jb21wdXRl
SW5zdGFuY2UaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ARp1ChZQcm9kdWN0QWN0aXZhdGlvbkVudHJ5EhAKA2tleRgBIAEoCVID
a2V5EkUKBXZhbHVlGAIgASgOMi8uZ29vZ2xlLmNsb3VkLmxpY2Vuc2VtYW5hZ2VyLnYxLkFj
dGl2YXRpb25TdGF0ZVIFdmFsdWU6AjgBIoQBCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEhAKDFBST1ZJU0lPTklORxABEgsKB1NUQUdJTkcQAhILCgdSVU5OSU5HEAMSDAoIU1RP
UFBJTkcQBBILCgdTVE9QUEVEEAUSDgoKVEVSTUlOQVRFRBAGEg0KCVJFUEFJUklORxAHOn7q
QXsKJmxpY2Vuc2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlEjxwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0qCWlu
c3RhbmNlczIIaW5zdGFuY2UibwoFVXNhZ2USUAoNbGltYV9pbnN0YW5jZRgBIAEoCUIr+kEo
CiZsaWNlbnNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIMbGltYUluc3RhbmNl
EhQKBXVzZXJzGAIgASgFUgV1c2Vycyp5CgtMaWNlbnNlVHlwZRIcChhMSUNFTlNFX1RZUEVf
VU5TUEVDSUZJRUQQABIjCh9MSUNFTlNFX1RZUEVfUEVSX01PTlRIX1BFUl9VU0VSEAESJwoj
TElDRU5TRV9UWVBFX0JSSU5HX1lPVVJfT1dOX0xJQ0VOU0UQAir+AQoPQWN0aXZhdGlvblN0
YXRlEiAKHEFDVElWQVRJT05fU1RBVEVfVU5TUEVDSUZJRUQQABIiCh5BQ1RJVkFUSU9OX1NU
QVRFX0tFWV9SRVFVRVNURUQQARIfChtBQ1RJVkFUSU9OX1NUQVRFX0FDVElWQVRJTkcQAhIe
ChpBQ1RJVkFUSU9OX1NUQVRFX0FDVElWQVRFRBADEiEKHUFDVElWQVRJT05fU1RBVEVfREVB
Q1RJVkFUSU5HEAQSIAocQUNUSVZBVElPTl9TVEFURV9ERUFDVElWQVRFRBAFEh8KG0FDVElW
QVRJT05fU1RBVEVfVEVSTUlOQVRFRBAGQuoBCiJjb20uZ29vZ2xlLmNsb3VkLmxpY2Vuc2Vt
YW5hZ2VyLnYxQhBBcGlFbnRpdGllc1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vbGlj
ZW5zZW1hbmFnZXIvYXBpdjEvbGljZW5zZW1hbmFnZXJwYjtsaWNlbnNlbWFuYWdlcnBiqgIe
R29vZ2xlLkNsb3VkLkxpY2Vuc2VNYW5hZ2VyLlYxygIeR29vZ2xlXENsb3VkXExpY2Vuc2VN
YW5hZ2VyXFYx6gIhR29vZ2xlOjpDbG91ZDo6TGljZW5zZU1hbmFnZXI6OlYxSuVGCgcSBQ4A
pgIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYAOwoJCgIIJRIDFgA7CggKAQgS
AxcAYQoJCgIICxIDFwBhCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMQoJCgIICBID
GQAxCggKAQgSAxoAOwoJCgIIARIDGgA7CggKAQgSAxsAOwoJCgIIKRIDGwA7CggKAQgSAxwA
OgoJCgIILRIDHAA6Cj0KAgUAEgQfACgBGjEgRGlmZmVyZW50IHR5cGVzIG9mIGxpY2Vuc2Vz
IHRoYXQgYXJlIHN1cHBvcnRlZC4KCgoKAwUAARIDHwUQChsKBAUAAgASAyECHxoOIHVuc3Bl
Y2lmaWVkLgoKDAoFBQACAAESAyECGgoMCgUFAAIAAhIDIR0eCkkKBAUAAgESAyQCJho8IEJp
bGxpbmcgd2lsbCBiZSBiYXNlZCBvbiBudW1iZXIgb2YgdXNlcnMgbGlzdGVkIHBlciBtb250
aC4KCgwKBQUAAgEBEgMkAiEKDAoFBQACAQISAyQkJQomCgQFAAICEgMnAioaGSBCcmluZyB5
b3VyIG93biBsaWNlbnNlLgoKDAoFBQACAgESAycCJQoMCgUFAAICAhIDJygpCkIKAgUBEgQr
AEABGjYgU3RhdGUgb2YgdGhlIExpY2Vuc2UgS2V5IGFjdGl2YXRpb24gb24gdGhlIGluc3Rh
bmNlLgoKCgoDBQEBEgMrBRQKOgoEBQECABIDLQIjGi0gVGhlIFN0YXR1cyBvZiB0aGUgYWN0
aXZhdGlvbiBpcyB1bnNwZWNpZmllZAoKDAoFBQECAAESAy0CHgoMCgUFAQIAAhIDLSEiCj8K
BAUBAgESAzACJRoyIEFjdGl2YXRpb24ga2V5IChNQUspIHJlcXVlc3RlZCBmb3IgdGhlIGlu
c3RhbmNlLgoKDAoFBQECAQESAzACIAoMCgUFAQIBAhIDMCMkCkUKBAUBAgISAzMCIho4IExp
Y2Vuc2UgYWN0aXZhdGlvbiBwcm9jZXNzIGlzIHJ1bm5pbmcgb24gdGhlIGluc3RhbmNlLgoK
DAoFBQECAgESAzMCHQoMCgUFAQICAhIDMyAhCj4KBAUBAgMSAzYCIRoxIExpY2Vuc2UgYWN0
aXZhdGlvbiBpcyBjb21wbGV0ZSBvbiB0aGUgaW5zdGFuY2UuCgoMCgUFAQIDARIDNgIcCgwK
BQUBAgMCEgM2HyAKOwoEBQECBBIDOQIkGi4gTGljZW5zZSBLZXkgaXMgZGVhY3RpdmF0aW5n
IG9uIHRoZSBpbnN0YW5jZS4KCgwKBQUBAgQBEgM5Ah8KDAoFBQECBAISAzkiIwo6CgQFAQIF
EgM8AiMaLSBMaWNlbnNlIEtleSBpcyBkZWFjdGl2YXRlZCBvbiB0aGUgaW5zdGFuY2UuCgoM
CgUFAQIFARIDPAIeCgwKBQUBAgUCEgM8ISIKPQoEBQECBhIDPwIiGjAgTGljZW5zZSBLZXkg
YWN0aXZhdGlvbiBmYWlsZWQgb24gdGhlIGluc3RhbmNlLgoKDAoFBQECBgESAz8CHQoMCgUF
AQIGAhIDPyAhCjUKAgQAEgRDAH4BGikgQ29uZmlndXJhdGlvbiBmb3IgYSBHb29nbGUgU1BM
QSBwcm9kdWN0CgoKCgMEAAESA0MIFQoLCgMEAAcSBEQCSQQKDQoFBAAHnQgSBEQCSQQKKwoE
BAAEABIETAJYAxodIFN0YXRlIG9mIHRoZSBjb25maWd1cmF0aW9uLgoKDAoFBAAEAAESA0wH
DAo/CgYEAAQAAgASA04EGhowIFRoZSBTdGF0dXMgb2YgdGhlIGNvbmZpZ3VyYXRpb24gaXMg
dW5zcGVjaWZpZWQKCg4KBwQABAACAAESA04EFQoOCgcEAAQAAgACEgNOGBkKMgoGBAAEAAIB
EgNRBBUaIyBDb25maWd1cmF0aW9uIGlzIGluIGFjdGl2ZSBzdGF0ZS4KCg4KBwQABAACAQES
A1EEEAoOCgcEAAQAAgECEgNRExQKNwoGBAAEAAICEgNUBBgaKCBDb25maWd1cmF0aW9uIGlz
IGluIGRlYWN0aXZhdGVkIHN0YXRlLgoKDgoHBAAEAAICARIDVAQTCg4KBwQABAACAgISA1QW
FwozCgYEAAQAAgMSA1cEFhokIENvbmZpZ3VyYXRpb24gaXMgaW4gZGVsZXRlZCBzdGF0ZS4K
Cg4KBwQABAACAwESA1cEEQoOCgcEAAQAAgMCEgNXFBUKKwoEBAACABIDWwI9Gh4gSWRlbnRp
Zmllci4gbmFtZSBvZiByZXNvdXJjZQoKDAoFBAACAAUSA1sCCAoMCgUEAAIAARIDWwkNCgwK
BQQAAgADEgNbEBEKDAoFBAACAAgSA1sSPAoPCggEAAIACJwIABIDWxM7CikKBAQAAgESA14C
QxocIFJlcXVpcmVkLiBVc2VyIGdpdmVuIG5hbWUuCgoMCgUEAAIBBRIDXgIICgwKBQQAAgEB
EgNeCRUKDAoFBAACAQMSA14YGQoMCgUEAAIBCBIDXhpCCg8KCAQAAgEInAgAEgNeG0EKUAoE
BAACAhIEYQJmBBpCIFJlcXVpcmVkLiBOYW1lIGZpZWxkICh3aXRoIFVSTCkgb2YgdGhlIFBy
b2R1Y3Qgb2ZmZXJlZCBmb3IgU1BMQS4KCgwKBQQAAgIFEgNhAggKDAoFBAACAgESA2EJEAoM
CgUEAAICAxIDYRMUCg0KBQQAAgIIEgRhFWYDCg8KCAQAAgIInAgAEgNiBCoKDwoHBAACAgif
CBIEYwRlBQo+CgQEAAIDEgNpAkgaMSBSZXF1aXJlZC4gTGljZW5zZVR5cGUgdG8gYmUgYXBw
bGllZCBmb3IgYmlsbGluZwoKDAoFBAACAwYSA2kCDQoMCgUEAAIDARIDaQ4aCgwKBQQAAgMD
EgNpHR4KDAoFBAACAwgSA2kfRwoPCggEAAIDCJwIABIDaSBGClYKBAQAAgQSA2wCUBpJIFJl
cXVpcmVkLiBCaWxsaW5nIGluZm9ybWF0aW9uIGFwcGxpY2FibGUgdGlsbCBlbmQgb2YgdGhl
IGN1cnJlbnQgbW9udGguCgoMCgUEAAIEBhIDbAINCgwKBQQAAgQBEgNsDiIKDAoFBAACBAMS
A2wlJgoMCgUEAAIECBIDbCdPCg8KCAQAAgQInAgAEgNsKE4KRwoEBAACBRIDbwJNGjogUmVx
dWlyZWQuIEJpbGxpbmcgaW5mb3JtYXRpb24gYXBwbGljYWJsZSBmb3IgbmV4dCBtb250aC4K
CgwKBQQAAgUGEgNvAg0KDAoFBAACBQESA28OHwoMCgUEAAIFAxIDbyIjCgwKBQQAAgUIEgNv
JEwKDwoIBAACBQicCAASA28lSwo8CgQEAAIGEgRyAnMyGi4gT3V0cHV0IG9ubHkuIFtPdXRw
dXQgb25seV0gQ3JlYXRlIHRpbWUgc3RhbXAKCgwKBQQAAgYGEgNyAhsKDAoFBAACBgESA3Ic
JwoMCgUEAAIGAxIDciorCgwKBQQAAgYIEgNzBjEKDwoIBAACBgicCAASA3MHMAo8CgQEAAIH
EgR2AncyGi4gT3V0cHV0IG9ubHkuIFtPdXRwdXQgb25seV0gVXBkYXRlIHRpbWUgc3RhbXAK
CgwKBQQAAgcGEgN2AhsKDAoFBAACBwESA3YcJwoMCgUEAAIHAxIDdiorCgwKBQQAAgcIEgN3
BjEKDwoIBAACBwicCAASA3cHMAoyCgQEAAIIEgN6AkoaJSBPcHRpb25hbC4gTGFiZWxzIGFz
IGtleSB2YWx1ZSBwYWlycwoKDAoFBAACCAYSA3oCFQoMCgUEAAIIARIDehYcCgwKBQQAAggD
EgN6HyAKDAoFBAACCAgSA3ohSQoPCggEAAIICJwIABIDeiJICjcKBAQAAgkSA30CPxoqIE91
dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgY29uZmlndXJhdGlvbi4KCgwKBQQAAgkGEgN9AgcK
DAoFBAACCQESA30IDQoMCgUEAAIJAxIDfRASCgwKBQQAAgkIEgN9Ez4KDwoIBAACCQicCAAS
A30UPQokCgIEARIGgQEAkAEBGhYgQmlsbGluZyBJbmZvcm1hdGlvbi4KCgsKAwQBARIEgQEI
EwoOCgQEAQgAEgaCAQKHAQMKDQoFBAEIAAESBIIBCBwKXQoEBAECABIGhQEEhgExGk0gUmVx
dWlyZWQuIFRoaXMgdHlwZSBvZiBiaWxsaW5nIHVzZXMgdXNlciBjb3VudCBmb3IgY29tcHV0
aW5nIHRvdGFsCiBjaGFyZ2UuCgoNCgUEAQIABhIEhQEEGAoNCgUEAQIAARIEhQEZKwoNCgUE
AQIAAxIEhQEuLwoNCgUEAQIACBIEhgEIMAoQCggEAQIACJwIABIEhgEJLwo3CgQEAQIBEgaK
AQKLATIaJyBPdXRwdXQgb25seS4gV2hlbiB0aGUgYmlsbGluZyBzdGFydHMuCgoNCgUEAQIB
BhIEigECGwoNCgUEAQIBARIEigEcJgoNCgUEAQIBAxIEigEpKgoNCgUEAQIBCBIEiwEGMQoQ
CggEAQIBCJwIABIEiwEHMAo1CgQEAQICEgaOAQKPATIaJSBPdXRwdXQgb25seS4gV2hlbiB0
aGUgYmlsbGluZyBlbmRzLgoKDQoFBAECAgYSBI4BAhsKDQoFBAECAgESBI4BHCQKDQoFBAEC
AgMSBI4BJygKDQoFBAECAggSBI8BBjEKEAoIBAECAgicCAASBI8BBzAKRwoCBAISBpMBAJYB
ARo5IFRoaXMgYXBwcm9hY2ggdXNlcyB0b3RhbCB1bmlxdWUgdXNlciBjb3VudCBmb3IgYmls
bGluZy4KCgsKAwQCARIEkwEIHAo2CgQEAgIAEgSVAQJAGiggUmVxdWlyZWQuIE51bWJlciBv
ZiB1c2VycyB0byBiaWxsIGZvci4KCg0KBQQCAgAFEgSVAQIHCg0KBQQCAgABEgSVAQgSCg0K
BQQCAgADEgSVARUWCg0KBQQCAgAIEgSVARc/ChAKCAQCAgAInAgAEgSVARg+CmQKAgQDEgaa
AQCdAQEaViBNZXNzYWdlIHJlcHJlc2VudGluZyB1c2FnZSBmb3IgbGljZW5zZSBjb25maWd1
cmF0aW9ucyB3aGljaCB1c2UgdXNlci1jb3VudAogYmlsbGluZy4KCgsKAwQDARIEmgEIFgo6
CgQEAwIAEgScAQJHGiwgUmVxdWlyZWQuIFVuaXF1ZSBudW1iZXIgb2YgbGljZW5zZWQgdXNl
cnMuCgoNCgUEAwIABRIEnAECBwoNCgUEAwIAARIEnAEIGQoNCgUEAwIAAxIEnAEcHQoNCgUE
AwIACBIEnAEeRgoQCggEAwIACJwIABIEnAEfRQopCgIEBBIGoAEAzwEBGhsgUHJvZHVjdHMg
Zm9yIEdvb2dsZSBTUExBLgoKCwoDBAQBEgSgAQgPCg0KAwQEBxIGoQECpgEECg8KBQQEB50I
EgahAQKmAQQKJwoEBAQEABIGqQECuAEDGhcgU3RhdGUgb2YgdGhlIHByb2R1Y3QuCgoNCgUE
BAQAARIEqQEHDAo3CgYEBAQAAgASBKsBBBoaJyBUaGUgU3RhdHVzIG9mIHRoZSBwcm9kdWN0
IGlzIHVua25vd24uCgoPCgcEBAQAAgABEgSrAQQVCg8KBwQEBAACAAISBKsBGBkKNgoGBAQE
AAIBEgSuAQQbGiYgUHJvZHVjdCBpcyB1bmRlciBwcm92aXNpb25pbmcgc3RhZ2UuCgoPCgcE
BAQAAgEBEgSuAQQWCg8KBwQEBAACAQISBK4BGRoKNAoGBAQEAAICEgSxAQQWGiQgUHJvZHVj
dCBpcyBvayB0byBydW4gb24gaW5zdGFuY2VzLgoKDwoHBAQEAAICARIEsQEEEQoPCgcEBAQA
AgICEgSxARQVCloKBgQEBAACAxIEtAEEGhpKIFRoZSBwcm9kdWN0IGlzIGFib3V0IHRvIHRl
cm1pbmF0ZSBvciBoYXMgYmVlbiBhbm5vdW5jZWQgZm9yIHRlcm1pbmF0aW9uLgoKDwoHBAQE
AAIDARIEtAEEFQoPCgcEBAQAAgMCEgS0ARgZCjIKBgQEBAACBBIEtwEEGRoiIFRoZSBwcm9k
dWN0IGhhcyBiZWVuIHRlcm1pbmF0ZWQuCgoPCgcEBAQAAgQBEgS3AQQUCg8KBwQEBAACBAIS
BLcBFxgKegoEBAQCABIEvAECPRpsIElkZW50aWZpZXIuIEZ1bGwgbmFtZSBvZiB0aGUgcHJv
ZHVjdCByZXNvdXJjZS4KIGV4ICJwcm9qZWN0cy8xL2xvY2F0aW9ucy91cy1jZW50cmFsMS9w
cm9kdWN0cy9vZmZpY2UtMjAyMSIKCg0KBQQEAgAFEgS8AQIICg0KBQQEAgABEgS8AQkNCg0K
BQQEAgADEgS8ARARCg0KBQQEAgAIEgS8ARI8ChAKCAQEAgAInAgAEgS8ARM7CjEKBAQEAgES
BL8BAj4aIyBSZXF1aXJlZC4gVmVyc2lvbiBvZiB0aGUgcHJvZHVjdC4KCg0KBQQEAgEFEgS/
AQIICg0KBQQEAgEBEgS/AQkQCg0KBQQEAgEDEgS/ARMUCg0KBQQEAgEIEgS/ARU9ChAKCAQE
AgEInAgAEgS/ARY8CjwKBAQEAgISBMIBAkYaLiBSZXF1aXJlZC4gQ29tcGFueSB0aGF0IHJl
bGVhc2VkIHRoZSBwcm9kdWN0LgoKDQoFBAQCAgUSBMIBAggKDQoFBAQCAgESBMIBCRgKDQoF
BAQCAgMSBMIBGxwKDQoFBAQCAggSBMIBHUUKEAoIBAQCAgicCAASBMIBHkQKMgoEBAQCAxIE
xQECPhokIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgcHJvZHVjdC4KCg0KBQQEAgMGEgTF
AQIHCg0KBQQEAgMBEgTFAQgNCg0KBQQEAgMDEgTFARARCg0KBQQEAgMIEgTFARI9ChAKCAQE
AgMInAgAEgTFARM8Ck8KBAQEAgQSBMgBAjoaQSBSZXF1aXJlZC4gU0tVIGZvciBtYXBwaW5n
IHRvIHRoZSBCaWxsaW5nL1N1YnNjcmlwdGlvbiByZXNvdXJjZS4KCg0KBQQEAgQFEgTIAQII
Cg0KBQQEAgQBEgTIAQkMCg0KBQQEAgQDEgTIAQ8QCg0KBQQEAgQIEgTIARE5ChAKCAQEAgQI
nAgAEgTIARI4Ck0KBAQEAgUSBMsBAkIaPyBSZXF1aXJlZC4gSHVtYW4tcmVhZGFibGUsIGRl
dGFpbGVkIGRlc2NyaXB0aW9uIG9mIHRoZSBQcm9kdWN0CgoNCgUEBAIFBRIEywECCAoNCgUE
BAIFARIEywEJFAoNCgUEBAIFAxIEywEXGAoNCgUEBAIFCBIEywEZQQoQCggEBAIFCJwIABIE
ywEaQAo8CgQEBAIGEgTOAQJDGi4gUmVxdWlyZWQuIEh1bWFuLXJlYWRhYmxlIG5hbWUgb2Yg
dGhlIFByb2R1Y3QKCg0KBQQEAgYFEgTOAQIICg0KBQQEAgYBEgTOAQkVCg0KBQQEAgYDEgTO
ARgZCg0KBQQEAgYIEgTOARpCChAKCAQEAgYInAgAEgTOARtBCjIKAgQFEgbSAQCaAgEaJCBN
ZXNzYWdlIGRlc2NyaWJpbmcgSW5zdGFuY2Ugb2JqZWN0CgoLCgMEBQESBNIBCBAKDQoDBAUH
EgbTAQLYAQQKDwoFBAUHnQgSBtMBAtgBBAohCgQEBQQAEgbbAQL1AQMaESBWTSBzdGF0dXMg
ZW51bS4KCg0KBQQFBAABEgTbAQcMCjYKBgQFBAACABIE3QEEGhomIFRoZSBTdGF0dXMgb2Yg
dGhlIFZNIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAUEAAIAARIE3QEEFQoPCgcEBQQAAgACEgTd
ARgZCkEKBgQFBAACARIE4AEEFRoxIFJlc291cmNlcyBhcmUgYmVpbmcgYWxsb2NhdGVkIGZv
ciB0aGUgaW5zdGFuY2UuCgoPCgcEBQQAAgEBEgTgAQQQCg8KBwQFBAACAQISBOABExQKYAoG
BAUEAAICEgTkAQQQGlAgQWxsIHJlcXVpcmVkIHJlc291cmNlcyBoYXZlIGJlZW4gYWxsb2Nh
dGVkIGFuZAogdGhlIGluc3RhbmNlIGlzIGJlaW5nIHN0YXJ0ZWQuCgoPCgcEBQQAAgIBEgTk
AQQLCg8KBwQFBAACAgISBOQBDg8KKgoGBAUEAAIDEgTnAQQQGhogVGhlIGluc3RhbmNlIGlz
IHJ1bm5pbmcuCgoPCgcEBQQAAgMBEgTnAQQLCg8KBwQFBAACAwISBOcBDg8KWgoGBAUEAAIE
EgTqAQQRGkogVGhlIGluc3RhbmNlIGlzIGN1cnJlbnRseSBzdG9wcGluZyAoZWl0aGVyIGJl
aW5nIGRlbGV0ZWQgb3IgdGVybWluYXRlZCkuCgoPCgcEBQQAAgQBEgTqAQQMCg8KBwQFBAAC
BAISBOoBDxAKeQoGBAUEAAIFEgTuAQQQGmkgVGhlIGluc3RhbmNlIGhhcyBzdG9wcGVkIGR1
ZSB0byB2YXJpb3VzIHJlYXNvbnMgKHVzZXIgcmVxdWVzdCwgVk0KIHByZWVtcHRpb24sIHBy
b2plY3QgZnJlZXppbmcsIGV0Yy4pLgoKDwoHBAUEAAIFARIE7gEECwoPCgcEBQQAAgUCEgTu
AQ4PCjYKBgQFBAACBhIE8QEEExomIFRoZSBpbnN0YW5jZSBoYXMgZmFpbGVkIGluIHNvbWUg
d2F5LgoKDwoHBAUEAAIGARIE8QEEDgoPCgcEBQQAAgYCEgTxARESCiwKBgQFBAACBxIE9AEE
EhocIFRoZSBpbnN0YW5jZSBpcyBpbiByZXBhaXIuCgoPCgcEBQQAAgcBEgT0AQQNCg8KBwQF
BAACBwISBPQBEBEKLAoEBAUCABIE+AECPRoeIElkZW50aWZpZXIuIG5hbWUgb2YgcmVzb3Vy
Y2UKCg0KBQQFAgAFEgT4AQIICg0KBQQFAgABEgT4AQkNCg0KBQQFAgADEgT4ARARCg0KBQQF
AgAIEgT4ARI8ChAKCAQFAgAInAgAEgT4ARM7Cj4KBAQFAgESBvsBAvwBMhouIE91dHB1dCBv
bmx5LiBbT3V0cHV0IG9ubHldIENyZWF0ZSB0aW1lIHN0YW1wCgoNCgUEBQIBBhIE+wECGwoN
CgUEBQIBARIE+wEcJwoNCgUEBQIBAxIE+wEqKwoNCgUEBQIBCBIE/AEGMQoQCggEBQIBCJwI
ABIE/AEHMAo+CgQEBQICEgb/AQKAAjIaLiBPdXRwdXQgb25seS4gW091dHB1dCBvbmx5XSBV
cGRhdGUgdGltZSBzdGFtcAoKDQoFBAUCAgYSBP8BAhsKDQoFBAUCAgESBP8BHCcKDQoFBAUC
AgMSBP8BKisKDQoFBAUCAggSBIACBjEKEAoIBAUCAgicCAASBIACBzAKMwoEBAUCAxIEgwIC
SholIE9wdGlvbmFsLiBMYWJlbHMgYXMga2V5IHZhbHVlIHBhaXJzCgoNCgUEBQIDBhIEgwIC
FQoNCgUEBQIDARIEgwIWHAoNCgUEBQIDAxIEgwIfIAoNCgUEBQIDCBIEgwIhSQoQCggEBQID
CJwIABIEgwIiSAoxCgQEBQIEEgSGAgI+GiMgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0
aGUgVk0uCgoNCgUEBQIEBhIEhgICBwoNCgUEBQIEARIEhgIIDQoNCgUEBQIEAxIEhgIQEQoN
CgUEBQIECBIEhgISPQoQCggEBQIECJwIABIEhgITPAo0CgQEBQIFEgSJAgJAGiYgT3V0cHV0
IG9ubHkuIFRoZSBsb2NhdGlvbiBvZiB0aGUgVk0uCgoNCgUEBQIFBRIEiQICCAoNCgUEBQIF
ARIEiQIJDwoNCgUEBQIFAxIEiQISEwoNCgUEBQIFCBIEiQIUPwoQCggEBQIFCJwIABIEiQIV
PgpUCgQEBQIGEgaMAgKNAjIaRCBPdXRwdXQgb25seS4gTWFwIHdpdGggUHJvZHVjdF9OYW1l
IGFuZCBBY3RpdmF0aW9uIFN0YXRlIG9mIHRoZSBWTS4KCg0KBQQFAgYGEgSMAgIeCg0KBQQF
AgYBEgSMAh8xCg0KBQQFAgYDEgSMAjQ1Cg0KBQQFAgYIEgSNAgYxChAKCAQFAgYInAgAEgSN
AgcwCjAKBAQFAgcSBJACAkwaIiBPdXRwdXQgb25seS4gbGljZW5zZSB2ZXJzaW9uIGlkLgoK
DQoFBAUCBwUSBJACAggKDQoFBAUCBwESBJACCRsKDQoFBAUCBwMSBJACHh8KDQoFBAUCBwgS
BJACIEsKEAoIBAUCBwicCAASBJACIUoKdgoEBAUCCBIGlAICmQIEGmYgUmVxdWlyZWQuIENv
bXB1dGUgSW5zdGFuY2UgcmVzb3VyY2UgbmFtZSwgaS5lLgogcHJvamVjdHMve3Byb2plY3R9
L3pvbmVzL3t6b25lfS9pbnN0YW5jZXMve2luc3RhbmNlfQoKDQoFBAUCCAUSBJQCAggKDQoF
BAUCCAESBJQCCRkKDQoFBAUCCAMSBJQCHB0KDwoFBAUCCAgSBpQCHpkCAwoQCggEBQIICJwI
ABIElQIEKgoRCgcEBQIICJ8IEgaWAgSYAgUKSwoCBAYSBp0CAKYCARo9IE1lc3NhZ2UgZGVz
Y3JpYmluZyB0b3RhbCBjb3VudHMgb2YgdXNlcnMgd2hvIGFjY2Vzc2VkIGEgVk0uCgoLCgME
BgESBJ0CCA0KcQoEBAYCABIGoAICogIFGmEgTGlNYSBJbnN0YW5jZSByZXNvdXJjZSBuYW1l
LCBpLmUuCiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFu
Y2VzL3tpbnN0YW5jZX0KCg0KBQQGAgAFEgSgAgIICg0KBQQGAgABEgSgAgkWCg0KBQQGAgAD
EgSgAhkaCg8KBQQGAgAIEgagAhuiAgQKEQoHBAYCAAifCBIGoAIcogIDCjgKBAQGAgESBKUC
AhIaKiBOdW1iZXIgb2YgdW5pcXVlIHVzZXJzIGFjY2Vzc2luZyB0aGUgVk0uCgoNCgUEBgIB
BRIEpQICBwoNCgUEBgIBARIEpQIIDQoNCgUEBgIBAxIEpQIQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::Configuration ===
    # Fields for Configuration
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: product Type: 9 ()
    # Field: license_type Type: 14 (.google.cloud.licensemanager.v1.LicenseType)
    # Field: current_billing_info Type: 11 (.google.cloud.licensemanager.v1.BillingInfo)
    # Field: next_billing_info Type: 11 (.google.cloud.licensemanager.v1.BillingInfo)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.licensemanager.v1.Configuration.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.licensemanager.v1.Configuration.State)

# Enum: Configuration::State
our $Configuration_STATE_UNSPECIFIED = 0;
our $Configuration_STATE_ACTIVE = 1;
our $Configuration_STATE_SUSPENDED = 2;
our $Configuration_STATE_DELETED = 3;

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo ===
    # Fields for BillingInfo
    # Field: user_count_billing Type: 11 (.google.cloud.licensemanager.v1.UserCountBillingInfo)
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo ===
    # Fields for UserCountBillingInfo
    # Field: user_count Type: 5 ()

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::UserCountUsage ===
    # Fields for UserCountUsage
    # Field: unique_user_count Type: 5 ()

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::Product ===
    # Fields for Product
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: product_company Type: 9 ()
    # Field: state Type: 14 (.google.cloud.licensemanager.v1.Product.State)
    # Field: sku Type: 9 ()
    # Field: description Type: 9 ()
    # Field: display_name Type: 9 ()

# Enum: Product::State
our $Product_STATE_UNSPECIFIED = 0;
our $Product_STATE_PROVISIONING = 1;
our $Product_STATE_RUNNING = 2;
our $Product_STATE_TERMINATING = 3;
our $Product_STATE_TERMINATED = 4;

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.licensemanager.v1.Instance.LabelsEntry)
    # Field: state Type: 14 (.google.cloud.licensemanager.v1.Instance.State)
    # Field: region Type: 9 ()
    # Field: product_activation Type: 11 (.google.cloud.licensemanager.v1.Instance.ProductActivationEntry)
    # Field: license_version_id Type: 9 ()
    # Field: compute_instance Type: 9 ()

# Enum: Instance::State
our $Instance_STATE_UNSPECIFIED = 0;
our $Instance_PROVISIONING = 1;
our $Instance_STAGING = 2;
our $Instance_RUNNING = 3;
our $Instance_STOPPING = 4;
our $Instance_STOPPED = 5;
our $Instance_TERMINATED = 6;
our $Instance_REPAIRING = 7;

# === Message: Google::Cloud::Licensemanager::V1::ApiEntities::Usage ===
    # Fields for Usage
    # Field: lima_instance Type: 9 ()
    # Field: users Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Licensemanager::V1::ApiEntities - Compiled Protocol Buffers messages for google/cloud/licensemanager/v1/api_entities.proto

=head1 SYNOPSIS

    use Google::Cloud::Licensemanager::V1::ApiEntities;

    my $msg = Google::Cloud::Licensemanager::V1::ApiEntities::Configuration->new({
        name => $name,
        display_name => $display_name,
        product => $product,
        license_type => $license_type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Licensemanager::V1::ApiEntities::Configuration->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/licensemanager/v1/api_entities.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::Configuration

Configuration for a Google SPLA product

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. name of resource

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. User given name.

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<String>

Required. Name field (with URL) of the Product offered for SPLA.

=item * C<< $msg->license_type() >> / C<< $msg->license_type($value) >>

Type: C<Enum> (L<Google::Cloud::Licensemanager::V1::LicenseType>)

Required. LicenseType to be applied for billing

=item * C<< $msg->current_billing_info() >> / C<< $msg->current_billing_info($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo>)

Required. Billing information applicable till end of the current month.

=item * C<< $msg->next_billing_info() >> / C<< $msg->next_billing_info($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo>)

Required. Billing information applicable for next month.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Create time stamp

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Update time stamp

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::Configuration::LabelsEntry>)

Optional. Labels as key value pairs

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Licensemanager::V1::Configuration::State>)

Output only. State of the configuration.

=back

=head3 Enum: Configuration::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STATE_ACTIVE> => C<1>

=item * C<STATE_SUSPENDED> => C<2>

=item * C<STATE_DELETED> => C<3>

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::BillingInfo

Billing Information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_count_billing() >> / C<< $msg->user_count_billing($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo>)

Required. This type of billing uses user count for computing total
charge.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the billing starts.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the billing ends.

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::UserCountBillingInfo

This approach uses total unique user count for billing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_count() >> / C<< $msg->user_count($value) >>

Type: C<Int32>

Required. Number of users to bill for.

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::UserCountUsage

Message representing usage for license configurations which use user-count
billing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unique_user_count() >> / C<< $msg->unique_user_count($value) >>

Type: C<Int32>

Required. Unique number of licensed users.

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::Product

Products for Google SPLA.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Full name of the product resource.
ex "projects/1/locations/us-central1/products/office-2021"

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Required. Version of the product.

=item * C<< $msg->product_company() >> / C<< $msg->product_company($value) >>

Type: C<String>

Required. Company that released the product.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Licensemanager::V1::Product::State>)

Output only. State of the product.

=item * C<< $msg->sku() >> / C<< $msg->sku($value) >>

Type: C<String>

Required. SKU for mapping to the Billing/Subscription resource.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. Human-readable, detailed description of the Product

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Human-readable name of the Product

=back

=head3 Enum: Product::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<STATE_PROVISIONING> => C<1>

=item * C<STATE_RUNNING> => C<2>

=item * C<STATE_TERMINATING> => C<3>

=item * C<STATE_TERMINATED> => C<4>

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::Instance

Message describing Instance object

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. name of resource

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Create time stamp

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. [Output only] Update time stamp

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::Instance::LabelsEntry>)

Optional. Labels as key value pairs

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Licensemanager::V1::Instance::State>)

Output only. The state of the VM.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Output only. The location of the VM.

=item * C<< $msg->product_activation() >> / C<< $msg->product_activation($value) >>

Type: C<Message> (L<Google::Cloud::Licensemanager::V1::ApiEntities::Instance::ProductActivationEntry>)

Output only. Map with Product_Name and Activation State of the VM.

=item * C<< $msg->license_version_id() >> / C<< $msg->license_version_id($value) >>

Type: C<String>

Output only. license version id.

=item * C<< $msg->compute_instance() >> / C<< $msg->compute_instance($value) >>

Type: C<String>

Required. Compute Instance resource name, i.e.
projects/{project}/zones/{zone}/instances/{instance}

=back

=head3 Enum: Instance::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<STAGING> => C<2>

=item * C<RUNNING> => C<3>

=item * C<STOPPING> => C<4>

=item * C<STOPPED> => C<5>

=item * C<TERMINATED> => C<6>

=item * C<REPAIRING> => C<7>

=back

=head2 Google::Cloud::Licensemanager::V1::ApiEntities::Usage

Message describing total counts of users who accessed a VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->lima_instance() >> / C<< $msg->lima_instance($value) >>

Type: C<String>

LiMa Instance resource name, i.e.
projects/{project}/locations/{location}/instances/{instance}

=item * C<< $msg->users() >> / C<< $msg->users($value) >>

Type: C<Int32>

Number of unique users accessing the VM.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Licensemanager::V1::ApiEntities::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
