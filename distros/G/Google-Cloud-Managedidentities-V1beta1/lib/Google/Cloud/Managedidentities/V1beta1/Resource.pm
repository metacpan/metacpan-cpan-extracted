package Google::Cloud::Managedidentities::V1beta1::Resource;

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
CjVnb29nbGUvY2xvdWQvbWFuYWdlZGlkZW50aXRpZXMvdjFiZXRhMS9yZXNvdXJjZS5wcm90
bxImZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYxYmV0YTEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iugcKBkRvbWFpbhIXCgRuYW1lGAEgASgJQgPg
QQNSBG5hbWUSVwoGbGFiZWxzGAIgAygLMjouZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0
aWVzLnYxYmV0YTEuRG9tYWluLkxhYmVsc0VudHJ5QgPgQQFSBmxhYmVscxI0ChNhdXRob3Jp
emVkX25ldHdvcmtzGAMgAygJQgPgQQFSEmF1dGhvcml6ZWROZXR3b3JrcxIvChFyZXNlcnZl
ZF9pcF9yYW5nZRgEIAEoCUID4EECUg9yZXNlcnZlZElwUmFuZ2USIQoJbG9jYXRpb25zGAUg
AygJQgPgQQJSCWxvY2F0aW9ucxIZCgVhZG1pbhgGIAEoCUID4EEBUgVhZG1pbhIXCgRmcWRu
GAogASgJQgPgQQNSBGZxZG4SQAoLY3JlYXRlX3RpbWUYCyABKAsyGi5nb29nbGUucHJvdG9i
dWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYDCABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSTwoFc3RhdGUYDSAB
KA4yNC5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5Eb21haW4uU3Rh
dGVCA+BBA1IFc3RhdGUSKgoOc3RhdHVzX21lc3NhZ2UYDiABKAlCA+BBA1INc3RhdHVzTWVz
c2FnZRJKCgZ0cnVzdHMYDyADKAsyLS5nb29nbGUuY2xvdWQubWFuYWdlZGlkZW50aXRpZXMu
djFiZXRhMS5UcnVzdEID4EEDUgZ0cnVzdHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKPAQoFU3RhdGUSFQoRU1RBVEVfVU5T
UEVDSUZJRUQQABIMCghDUkVBVElORxABEgkKBVJFQURZEAISDAoIVVBEQVRJTkcQAxIMCghE
RUxFVElORxAEEg0KCVJFUEFJUklORxAFEhoKFlBFUkZPUk1JTkdfTUFJTlRFTkFOQ0UQBhIP
CgtVTkFWQUlMQUJMRRAHOmbqQWMKJ21hbmFnZWRpZGVudGl0aWVzLmdvb2dsZWFwaXMuY29t
L0RvbWFpbhI4cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvbWFp
bnMve2RvbWFpbn0ikggKBVRydXN0EiwKEnRhcmdldF9kb21haW5fbmFtZRgBIAEoCVIQdGFy
Z2V0RG9tYWluTmFtZRJWCgp0cnVzdF90eXBlGAIgASgOMjcuZ29vZ2xlLmNsb3VkLm1hbmFn
ZWRpZGVudGl0aWVzLnYxYmV0YTEuVHJ1c3QuVHJ1c3RUeXBlUgl0cnVzdFR5cGUSZQoPdHJ1
c3RfZGlyZWN0aW9uGAMgASgOMjwuZ29vZ2xlLmNsb3VkLm1hbmFnZWRpZGVudGl0aWVzLnYx
YmV0YTEuVHJ1c3QuVHJ1c3REaXJlY3Rpb25SDnRydXN0RGlyZWN0aW9uEjkKGHNlbGVjdGl2
ZV9hdXRoZW50aWNhdGlvbhgEIAEoCFIXc2VsZWN0aXZlQXV0aGVudGljYXRpb24SNQoXdGFy
Z2V0X2Ruc19pcF9hZGRyZXNzZXMYBSADKAlSFHRhcmdldERuc0lwQWRkcmVzc2VzEjkKFnRy
dXN0X2hhbmRzaGFrZV9zZWNyZXQYBiABKAlCA+BBBFIUdHJ1c3RIYW5kc2hha2VTZWNyZXQS
QAoLY3JlYXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSTgoFc3RhdGUYCSABKA4yMy5nb29nbGUuY2xvdWQu
bWFuYWdlZGlkZW50aXRpZXMudjFiZXRhMS5UcnVzdC5TdGF0ZUID4EEDUgVzdGF0ZRIwChFz
dGF0ZV9kZXNjcmlwdGlvbhgLIAEoCUID4EEDUhBzdGF0ZURlc2NyaXB0aW9uEloKGWxhc3Rf
dHJ1c3RfaGVhcnRiZWF0X3RpbWUYDCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSFmxhc3RUcnVzdEhlYXJ0YmVhdFRpbWUiaQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVD
SUZJRUQQABIMCghDUkVBVElORxABEgwKCFVQREFUSU5HEAISDAoIREVMRVRJTkcQAxINCglD
T05ORUNURUQQBBIQCgxESVNDT05ORUNURUQQBSJBCglUcnVzdFR5cGUSGgoWVFJVU1RfVFlQ
RV9VTlNQRUNJRklFRBAAEgoKBkZPUkVTVBABEgwKCEVYVEVSTkFMEAIiXwoOVHJ1c3REaXJl
Y3Rpb24SHwobVFJVU1RfRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASCwoHSU5CT1VORBABEgwK
CE9VVEJPVU5EEAISEQoNQklESVJFQ1RJT05BTBADQpUCCipjb20uZ29vZ2xlLmNsb3VkLm1h
bmFnZWRpZGVudGl0aWVzLnYxYmV0YTFCDVJlc291cmNlUHJvdG9QAVpYY2xvdWQuZ29vZ2xl
LmNvbS9nby9tYW5hZ2VkaWRlbnRpdGllcy9hcGl2MWJldGExL21hbmFnZWRpZGVudGl0aWVz
cGI7bWFuYWdlZGlkZW50aXRpZXNwYqoCJkdvb2dsZS5DbG91ZC5NYW5hZ2VkSWRlbnRpdGll
cy5WMUJldGExygImR29vZ2xlXENsb3VkXE1hbmFnZWRJZGVudGl0aWVzXFYxYmV0YTHqAilH
b29nbGU6OkNsb3VkOjpNYW5hZ2VkSWRlbnRpdGllczo6VjFiZXRhMUqYPwoHEgUOANcBAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABIDEgAp
CgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEMKCQoCCCUSAxYAQwoICgEIEgMXAG8K
CQoCCAsSAxcAbwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC4KCQoCCAgSAxkALgoI
CgEIEgMaAEMKCQoCCAESAxoAQwoICgEIEgMbAEMKCQoCCCkSAxsAQwoICgEIEgMcAEIKCQoC
CC0SAxwAQgqCAgoCBAASBCIAdwEa9QEgUmVwcmVzZW50cyBhIG1hbmFnZWQgTWljcm9zb2Z0
IEFjdGl2ZSBEaXJlY3RvcnkgZG9tYWluLgogSWYgdGhlIGRvbWFpbiBpcyBiZWluZyBjaGFu
Z2VkLCBpdCB3aWxsIGJlIHBsYWNlZCBpbnRvIHRoZSBVUERBVElORyBzdGF0ZSwKIHdoaWNo
IGluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBiZWluZyByZWNvbmNpbGVkLiBBdCB0
aGlzIHBvaW50LCBHZXQKIHdpbGwgcmVmbGVjdCBhbiBpbnRlcm1lZGlhdGUgc3RhdGUuCgoK
CgMEAAESAyIIDgoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKRAoEBAAEABIEKQJCAxo2
IFJlcHJlc2VudHMgdGhlIGRpZmZlcmVudCBzdGF0ZXMgb2YgYSBtYW5hZ2VkIGRvbWFpbi4K
CgwKBQQABAABEgMpBwwKGQoGBAAEAAIAEgMrBBoaCiBOb3Qgc2V0LgoKDgoHBAAEAAIAARID
KwQVCg4KBwQABAACAAISAysYGQotCgYEAAQAAgESAy4EERoeIFRoZSBkb21haW4gaXMgYmVp
bmcgY3JlYXRlZC4KCg4KBwQABAACAQESAy4EDAoOCgcEAAQAAgECEgMuDxAKQQoGBAAEAAIC
EgMxBA4aMiBUaGUgZG9tYWluIGhhcyBiZWVuIGNyZWF0ZWQgYW5kIGlzIGZ1bGx5IHVzYWJs
ZS4KCg4KBwQABAACAgESAzEECQoOCgcEAAQAAgICEgMxDA0KPQoGBAAEAAIDEgM0BBEaLiBU
aGUgZG9tYWluJ3MgY29uZmlndXJhdGlvbiBpcyBiZWluZyB1cGRhdGVkLgoKDgoHBAAEAAID
ARIDNAQMCg4KBwQABAACAwISAzQPEAotCgYEAAQAAgQSAzcEERoeIFRoZSBkb21haW4gaXMg
YmVpbmcgZGVsZXRlZC4KCg4KBwQABAACBAESAzcEDAoOCgcEAAQAAgQCEgM3DxAKdwoGBAAE
AAIFEgM7BBIaaCBUaGUgZG9tYWluIGlzIGJlaW5nIHJlcGFpcmVkIGFuZCBtYXkgYmUgdW51
c2FibGUuIERldGFpbHMKIGNhbiBiZSBmb3VuZCBpbiB0aGUgYHN0YXR1c19tZXNzYWdlYCBm
aWVsZC4KCg4KBwQABAACBQESAzsEDQoOCgcEAAQAAgUCEgM7EBEKNgoGBAAEAAIGEgM+BB8a
JyBUaGUgZG9tYWluIGlzIHVuZGVyZ29pbmcgbWFpbnRlbmFuY2UuCgoOCgcEAAQAAgYBEgM+
BBoKDgoHBAAEAAIGAhIDPh0eCjQKBgQABAACBxIDQQQUGiUgVGhlIGRvbWFpbiBpcyBub3Qg
c2VydmluZyByZXF1ZXN0cy4KCg4KBwQABAACBwESA0EEDwoOCgcEAAQAAgcCEgNBEhMKigEK
BAQAAgASA0YCPhp9IE91dHB1dCBvbmx5LiBUaGUgdW5pcXVlIG5hbWUgb2YgdGhlIGRvbWFp
biB1c2luZyB0aGUgZm9ybToKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2ds
b2JhbC9kb21haW5zL3tkb21haW5fbmFtZX1gLgoKDAoFBAACAAUSA0YCCAoMCgUEAAIAARID
RgkNCgwKBQQAAgADEgNGEBEKDAoFBAACAAgSA0YSPQoPCggEAAIACJwIABIDRhM8ClEKBAQA
AgESA0kCShpEIE9wdGlvbmFsLiBSZXNvdXJjZSBsYWJlbHMgdGhhdCBjYW4gY29udGFpbiB1
c2VyLXByb3ZpZGVkIG1ldGFkYXRhLgoKDAoFBAACAQYSA0kCFQoMCgUEAAIBARIDSRYcCgwK
BQQAAgEDEgNJHyAKDAoFBAACAQgSA0khSQoPCggEAAIBCJwIABIDSSJICuECCgQEAAICEgNQ
AlMa0wIgT3B0aW9uYWwuIFRoZSBmdWxsIG5hbWVzIG9mIHRoZSBHb29nbGUgQ29tcHV0ZSBF
bmdpbmUKIFtuZXR3b3Jrc10oL2NvbXB1dGUvZG9jcy9uZXR3b3Jrcy1hbmQtZmlyZXdhbGxz
I25ldHdvcmtzKSB0aGUgZG9tYWluCiBpbnN0YW5jZSBpcyBjb25uZWN0ZWQgdG8uIE5ldHdv
cmtzIGNhbiBiZSBhZGRlZCB1c2luZyBVcGRhdGVEb21haW4uCiBUaGUgZG9tYWluIGlzIG9u
bHkgYXZhaWxhYmxlIG9uIG5ldHdvcmtzIGxpc3RlZCBpbiBgYXV0aG9yaXplZF9uZXR3b3Jr
c2AuCiBJZiBDSURSIHN1Ym5ldHMgb3ZlcmxhcCBiZXR3ZWVuIG5ldHdvcmtzLCBkb21haW4g
Y3JlYXRpb24gd2lsbCBmYWlsLgoKDAoFBAACAgQSA1ACCgoMCgUEAAICBRIDUAsRCgwKBQQA
AgIBEgNQEiUKDAoFBAACAgMSA1AoKQoMCgUEAAICCBIDUCpSCg8KCAQAAgIInAgAEgNQK1EK
8AEKBAQAAgMSA1YCSBriASBSZXF1aXJlZC4gVGhlIENJRFIgcmFuZ2Ugb2YgaW50ZXJuYWwg
YWRkcmVzc2VzIHRoYXQgYXJlIHJlc2VydmVkIGZvciB0aGlzCiBkb21haW4uIFJlc2VydmVk
IG5ldHdvcmtzIG11c3QgYmUgLzI0IG9yIGxhcmdlci4gUmFuZ2VzIG11c3QgYmUKIHVuaXF1
ZSBhbmQgbm9uLW92ZXJsYXBwaW5nIHdpdGggZXhpc3Rpbmcgc3VibmV0cyBpbgogW0RvbWFp
bl0uW2F1dGhvcml6ZWRfbmV0d29ya3NdLgoKDAoFBAACAwUSA1YCCAoMCgUEAAIDARIDVgka
CgwKBQQAAgMDEgNWHR4KDAoFBAACAwgSA1YfRwoPCggEAAIDCJwIABIDViBGCt4BCgQEAAIE
EgNdAkka0AEgUmVxdWlyZWQuIExvY2F0aW9ucyB3aGVyZSBkb21haW4gbmVlZHMgdG8gYmUg
cHJvdmlzaW9uZWQuCiBbcmVnaW9uc11bY29tcHV0ZS9kb2NzL3JlZ2lvbnMtem9uZXMvXQog
ZS5nLiB1cy13ZXN0MSBvciB1cy1lYXN0NAogU2VydmljZSBzdXBwb3J0cyB1cCB0byA0IGxv
Y2F0aW9ucyBhdCBvbmNlLiBFYWNoIGxvY2F0aW9uIHdpbGwgdXNlIGEgLzI2CiBibG9jay4K
CgwKBQQAAgQEEgNdAgoKDAoFBAACBAUSA10LEQoMCgUEAAIEARIDXRIbCgwKBQQAAgQDEgNd
Hh8KDAoFBAACBAgSA10gSAoPCggEAAIECJwIABIDXSFHCqABCgQEAAIFEgNhAjwakgEgT3B0
aW9uYWwuIFRoZSBuYW1lIG9mIGRlbGVnYXRlZCBhZG1pbmlzdHJhdG9yIGFjY291bnQgdXNl
ZCB0byBwZXJmb3JtCiBBY3RpdmUgRGlyZWN0b3J5IG9wZXJhdGlvbnMuIElmIG5vdCBzcGVj
aWZpZWQsIGBzZXR1cGFkbWluYCB3aWxsIGJlIHVzZWQuCgoMCgUEAAIFBRIDYQIICgwKBQQA
AgUBEgNhCQ4KDAoFBAACBQMSA2EREgoMCgUEAAIFCBIDYRM7Cg8KCAQAAgUInAgAEgNhFDoK
1gEKBAQAAgYSA2YCPxrIASBPdXRwdXQgb25seS4gVGhlIGZ1bGx5LXF1YWxpZmllZCBkb21h
aW4gbmFtZSBvZiB0aGUgZXhwb3NlZCBkb21haW4gdXNlZCBieQogY2xpZW50cyB0byBjb25u
ZWN0IHRvIHRoZSBzZXJ2aWNlLiBTaW1pbGFyIHRvIHdoYXQgd291bGQgYmUgY2hvc2VuIGZv
ciBhbgogQWN0aXZlIERpcmVjdG9yeSBzZXQgdXAgb24gYW4gaW50ZXJuYWwgbmV0d29yay4K
CgwKBQQAAgYFEgNmAggKDAoFBAACBgESA2YJDQoMCgUEAAIGAxIDZhASCgwKBQQAAgYIEgNm
Ez4KDwoIBAACBgicCAASA2YUPQo+CgQEAAIHEgNpAlkaMSBPdXRwdXQgb25seS4gVGhlIHRp
bWUgdGhlIGluc3RhbmNlIHdhcyBjcmVhdGVkLgoKDAoFBAACBwYSA2kCGwoMCgUEAAIHARID
aRwnCgwKBQQAAgcDEgNpKiwKDAoFBAACBwgSA2ktWAoPCggEAAIHCJwIABIDaS5XCjEKBAQA
AggSA2wCWRokIE91dHB1dCBvbmx5LiBUaGUgbGFzdCB1cGRhdGUgdGltZS4KCgwKBQQAAggG
EgNsAhsKDAoFBAACCAESA2wcJwoMCgUEAAIIAxIDbCosCgwKBQQAAggIEgNsLVgKDwoIBAAC
CAicCAASA2wuVwo9CgQEAAIJEgNvAj8aMCBPdXRwdXQgb25seS4gVGhlIGN1cnJlbnQgc3Rh
dGUgb2YgdGhpcyBkb21haW4uCgoMCgUEAAIJBhIDbwIHCgwKBQQAAgkBEgNvCA0KDAoFBAAC
CQMSA28QEgoMCgUEAAIJCBIDbxM+Cg8KCAQAAgkInAgAEgNvFD0KagoEBAACChIDcwJJGl0g
T3V0cHV0IG9ubHkuIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gYWJvdXQgdGhlIGN1cnJlbnQg
c3RhdHVzIG9mIHRoaXMKIGRvbWFpbiwgaWYgYXZhaWxhYmxlLgoKDAoFBAACCgUSA3MCCAoM
CgUEAAIKARIDcwkXCgwKBQQAAgoDEgNzGhwKDAoFBAACCggSA3MdSAoPCggEAAIKCJwIABID
cx5HCkoKBAQAAgsSA3YCSRo9IE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCB0cnVzdHMgYXNz
b2NpYXRlZCB3aXRoIHRoZSBkb21haW4uCgoMCgUEAAILBBIDdgIKCgwKBQQAAgsGEgN2CxAK
DAoFBAACCwESA3YRFwoMCgUEAAILAxIDdhocCgwKBQQAAgsIEgN2HUgKDwoIBAACCwicCAAS
A3YeRwqQAQoCBAESBXsA1wEBGoIBIFJlcHJlc2VudHMgYSByZWxhdGlvbnNoaXAgYmV0d2Vl
biB0d28gZG9tYWlucy4gVGhpcyBhbGxvd3MgYSBjb250cm9sbGVyIGluCiBvbmUgZG9tYWlu
IHRvIGF1dGhlbnRpY2F0ZSBhIHVzZXIgaW4gYW5vdGhlciBkb21haW4uCgoKCgMEAQESA3sI
DQpDCgQEAQQAEgV9Ao8BAxo0IFJlcHJlc2VudHMgdGhlIGRpZmZlcmVudCBzdGF0ZXMgb2Yg
YSBkb21haW4gdHJ1c3QuCgoMCgUEAQQAARIDfQcMChkKBgQBBAACABIDfwQaGgogTm90IHNl
dC4KCg4KBwQBBAACAAESA38EFQoOCgcEAQQAAgACEgN/GBkKNAoGBAEEAAIBEgSCAQQRGiQg
VGhlIGRvbWFpbiB0cnVzdCBpcyBiZWluZyBjcmVhdGVkLgoKDwoHBAEEAAIBARIEggEEDAoP
CgcEAQQAAgECEgSCAQ8QCjQKBgQBBAACAhIEhQEEERokIFRoZSBkb21haW4gdHJ1c3QgaXMg
YmVpbmcgdXBkYXRlZC4KCg8KBwQBBAACAgESBIUBBAwKDwoHBAEEAAICAhIEhQEPEAo0CgYE
AQQAAgMSBIgBBBEaJCBUaGUgZG9tYWluIHRydXN0IGlzIGJlaW5nIGRlbGV0ZWQuCgoPCgcE
AQQAAgMBEgSIAQQMCg8KBwQBBAACAwISBIgBDxAKMAoGBAEEAAIEEgSLAQQSGiAgVGhlIGRv
bWFpbiB0cnVzdCBpcyBjb25uZWN0ZWQuCgoPCgcEAQQAAgQBEgSLAQQNCg8KBwQBBAACBAIS
BIsBEBEKMwoGBAEEAAIFEgSOAQQVGiMgVGhlIGRvbWFpbiB0cnVzdCBpcyBkaXNjb25uZWN0
ZWQuCgoPCgcEAQQAAgUBEgSOAQQQCg8KBwQBBAACBQISBI4BExQKRAoEBAEEARIGkgECmwED
GjQgUmVwcmVzZW50cyB0aGUgZGlmZmVyZW50IGludGVyLWZvcmVzdCB0cnVzdCB0eXBlcy4K
Cg0KBQQBBAEBEgSSAQcQChoKBgQBBAECABIElAEEHxoKIE5vdCBzZXQuCgoPCgcEAQQBAgAB
EgSUAQQaCg8KBwQBBAECAAISBJQBHR4KIwoGBAEEAQIBEgSXAQQPGhMgVGhlIGZvcmVzdCB0
cnVzdC4KCg8KBwQBBAECAQESBJcBBAoKDwoHBAEEAQIBAhIElwENDgosCgYEAQQBAgISBJoB
BBEaHCBUaGUgZXh0ZXJuYWwgZG9tYWluIHRydXN0LgoKDwoHBAEEAQICARIEmgEEDAoPCgcE
AQQBAgICEgSaAQ8QCokCCgQEAQQCEgahAQKtAQMa+AEgUmVwcmVzZW50cyB0aGUgZGlyZWN0
aW9uIG9mIHRydXN0LgogU2VlCiBbU3lzdGVtLkRpcmVjdG9yeVNlcnZpY2VzLkFjdGl2ZURp
cmVjdG9yeS5UcnVzdERpcmVjdGlvbl0oaHR0cHM6Ly9kb2NzLm1pY3Jvc29mdC5jb20vZW4t
dXMvZG90bmV0L2FwaS9zeXN0ZW0uZGlyZWN0b3J5c2VydmljZXMuYWN0aXZlZGlyZWN0b3J5
LnRydXN0ZGlyZWN0aW9uP3ZpZXc9bmV0ZnJhbWV3b3JrLTQuNy4yKQogZm9yIG1vcmUgaW5m
b3JtYXRpb24uCgoNCgUEAQQCARIEoQEHFQoaCgYEAQQCAgASBKMBBCQaCiBOb3Qgc2V0LgoK
DwoHBAEEAgIAARIEowEEHwoPCgcEAQQCAgACEgSjASIjCkUKBgQBBAICARIEpgEEEBo1IFRo
ZSBpbmJvdW5kIGRpcmVjdGlvbiByZXByZXNlbnRzIHRoZSB0cnVzdGluZyBzaWRlLgoKDwoH
BAEEAgIBARIEpgEECwoPCgcEAQQCAgECEgSmAQ4PCkQKBgQBBAICAhIEqQEEERo0IFRoZSBv
dXRib3VkIGRpcmVjdGlvbiByZXByZXNlbnRzIHRoZSB0cnVzdGVkIHNpZGUuCgoPCgcEAQQC
AgIBEgSpAQQMCg8KBwQBBAICAgISBKkBDxAKVQoGBAEEAgIDEgSsAQQWGkUgVGhlIGJpZGly
ZWN0aW9uYWwgZGlyZWN0aW9uIHJlcHJlc2VudHMgdGhlIHRydXN0ZWQgLyB0cnVzdGluZyBz
aWRlLgoKDwoHBAEEAgIDARIErAEEEQoPCgcEAQQCAgMCEgSsARQVCmcKBAQBAgASBLEBAiAa
WSBUaGUgZnVsbHkgcXVhbGlmaWVkIHRhcmdldCBkb21haW4gbmFtZSB3aGljaCB3aWxsIGJl
IGluIHRydXN0IHdpdGggdGhlCiBjdXJyZW50IGRvbWFpbi4KCg0KBQQBAgAFEgSxAQIICg0K
BQQBAgABEgSxAQkbCg0KBQQBAgADEgSxAR4fCkQKBAQBAgESBLQBAhsaNiBUaGUgdHlwZSBv
ZiB0cnVzdCByZXByZXNlbnRlZCBieSB0aGUgdHJ1c3QgcmVzb3VyY2UuCgoNCgUEAQIBBhIE
tAECCwoNCgUEAQIBARIEtAEMFgoNCgUEAQIBAxIEtAEZGgpoCgQEAQICEgS4AQIlGlogVGhl
IHRydXN0IGRpcmVjdGlvbiwgd2hpY2ggZGVjaWRlcyBpZiB0aGUgY3VycmVudCBkb21haW4g
aXMgdHJ1c3RlZCwKIHRydXN0aW5nLCBvciBib3RoLgoKDQoFBAECAgYSBLgBAhAKDQoFBAEC
AgESBLgBESAKDQoFBAECAgMSBLgBIyQKqwEKBAQBAgMSBL0BAiQanAEgVGhlIHRydXN0IGF1
dGhlbnRpY2F0aW9uIHR5cGUsIHdoaWNoIGRlY2lkZXMgd2hldGhlciB0aGUgdHJ1c3RlZCBz
aWRlIGhhcwogZm9yZXN0L2RvbWFpbiB3aWRlIGFjY2VzcyBvciBzZWxlY3RpdmUgYWNjZXNz
IHRvIGFuIGFwcHJvdmVkIHNldCBvZgogcmVzb3VyY2VzLgoKDQoFBAECAwUSBL0BAgYKDQoF
BAECAwESBL0BBx8KDQoFBAECAwMSBL0BIiMKbgoEBAECBBIEwQECLhpgIFRoZSB0YXJnZXQg
RE5TIHNlcnZlciBJUCBhZGRyZXNzZXMgd2hpY2ggY2FuIHJlc29sdmUgdGhlIHJlbW90ZSBk
b21haW4KIGludm9sdmVkIGluIHRoZSB0cnVzdC4KCg0KBQQBAgQEEgTBAQIKCg0KBQQBAgQF
EgTBAQsRCg0KBQQBAgQBEgTBARIpCg0KBQQBAgQDEgTBASwtCnMKBAQBAgUSBMUBAk8aZSBJ
bnB1dCBvbmx5LiBUaGUgdHJ1c3Qgc2VjcmV0IHVzZWQgZm9yIHRoZSBoYW5kc2hha2UKIHdp
dGggdGhlIHRhcmdldCBkb21haW4uIEl0IHdpbGwgbm90IGJlIHN0b3JlZC4KCg0KBQQBAgUF
EgTFAQIICg0KBQQBAgUBEgTFAQkfCg0KBQQBAgUDEgTFASIjCg0KBQQBAgUIEgTFASROChAK
CAQBAgUInAgAEgTFASVNCj8KBAQBAgYSBMgBAlgaMSBPdXRwdXQgb25seS4gVGhlIHRpbWUg
dGhlIGluc3RhbmNlIHdhcyBjcmVhdGVkLgoKDQoFBAECBgYSBMgBAhsKDQoFBAECBgESBMgB
HCcKDQoFBAECBgMSBMgBKisKDQoFBAECBggSBMgBLFcKEAoIBAECBgicCAASBMgBLVYKMgoE
BAECBxIEywECWBokIE91dHB1dCBvbmx5LiBUaGUgbGFzdCB1cGRhdGUgdGltZS4KCg0KBQQB
AgcGEgTLAQIbCg0KBQQBAgcBEgTLARwnCg0KBQQBAgcDEgTLASorCg0KBQQBAgcIEgTLASxX
ChAKCAQBAgcInAgAEgTLAS1WCjwKBAQBAggSBM4BAj4aLiBPdXRwdXQgb25seS4gVGhlIGN1
cnJlbnQgc3RhdGUgb2YgdGhlIHRydXN0LgoKDQoFBAECCAYSBM4BAgcKDQoFBAECCAESBM4B
CA0KDQoFBAECCAMSBM4BEBEKDQoFBAECCAgSBM4BEj0KEAoIBAECCAicCAASBM4BEzwKaAoE
BAECCRIE0gECTBpaIE91dHB1dCBvbmx5LiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGFib3V0
IHRoZSBjdXJyZW50IHN0YXRlIG9mIHRoZQogdHJ1c3QsIGlmIGF2YWlsYWJsZS4KCg0KBQQB
AgkFEgTSAQIICg0KBQQBAgkBEgTSAQkaCg0KBQQBAgkDEgTSAR0fCg0KBQQBAgkIEgTSASBL
ChAKCAQBAgkInAgAEgTSASFKCl8KBAQBAgoSBNYBAmcaUSBPdXRwdXQgb25seS4gVGhlIGxh
c3QgaGVhcnRiZWF0IHRpbWUgd2hlbiB0aGUgdHJ1c3Qgd2FzIGtub3duIHRvIGJlCiBjb25u
ZWN0ZWQuCgoNCgUEAQIKBhIE1gECGwoNCgUEAQIKARIE1gEcNQoNCgUEAQIKAxIE1gE4OgoN
CgUEAQIKCBIE1gE7ZgoQCggEAQIKCJwIABIE1gE8ZWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Managedidentities::V1beta1::Resource::Domain ===
    # Fields for Domain
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.managedidentities.v1beta1.Domain.LabelsEntry)
    # Field: authorized_networks Type: 9 ()
    # Field: reserved_ip_range Type: 9 ()
    # Field: locations Type: 9 ()
    # Field: admin Type: 9 ()
    # Field: fqdn Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.managedidentities.v1beta1.Domain.State)
    # Field: status_message Type: 9 ()
    # Field: trusts Type: 11 (.google.cloud.managedidentities.v1beta1.Trust)

# Enum: Domain::State
our $Domain_STATE_UNSPECIFIED = 0;
our $Domain_CREATING = 1;
our $Domain_READY = 2;
our $Domain_UPDATING = 3;
our $Domain_DELETING = 4;
our $Domain_REPAIRING = 5;
our $Domain_PERFORMING_MAINTENANCE = 6;
our $Domain_UNAVAILABLE = 7;

# === Message: Google::Cloud::Managedidentities::V1beta1::Resource::Trust ===
    # Fields for Trust
    # Field: target_domain_name Type: 9 ()
    # Field: trust_type Type: 14 (.google.cloud.managedidentities.v1beta1.Trust.TrustType)
    # Field: trust_direction Type: 14 (.google.cloud.managedidentities.v1beta1.Trust.TrustDirection)
    # Field: selective_authentication Type: 8 ()
    # Field: target_dns_ip_addresses Type: 9 ()
    # Field: trust_handshake_secret Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.managedidentities.v1beta1.Trust.State)
    # Field: state_description Type: 9 ()
    # Field: last_trust_heartbeat_time Type: 11 (.google.protobuf.Timestamp)

# Enum: Trust::State
our $Trust_STATE_UNSPECIFIED = 0;
our $Trust_CREATING = 1;
our $Trust_UPDATING = 2;
our $Trust_DELETING = 3;
our $Trust_CONNECTED = 4;
our $Trust_DISCONNECTED = 5;

# Enum: Trust::TrustType
our $Trust_TRUST_TYPE_UNSPECIFIED = 0;
our $Trust_FOREST = 1;
our $Trust_EXTERNAL = 2;

# Enum: Trust::TrustDirection
our $Trust_TRUST_DIRECTION_UNSPECIFIED = 0;
our $Trust_INBOUND = 1;
our $Trust_OUTBOUND = 2;
our $Trust_BIDIRECTIONAL = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Managedidentities::V1beta1::Resource - Compiled Protocol Buffers messages for google/cloud/managedidentities/v1beta1/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Managedidentities::V1beta1::Resource;

    my $msg = Google::Cloud::Managedidentities::V1beta1::Resource::Domain->new({
        name => $name,
        labels => $labels,
        authorized_networks => $authorized_networks,
        reserved_ip_range => $reserved_ip_range,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Managedidentities::V1beta1::Resource::Domain->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/managedidentities/v1beta1/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Managedidentities::V1beta1::Resource::Domain

Represents a managed Microsoft Active Directory domain.
If the domain is being changed, it will be placed into the UPDATING state,
which indicates that the resource is being reconciled. At this point, Get
will reflect an intermediate state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique name of the domain using the form:
`projects/{project_id}/locations/global/domains/{domain_name}`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Domain::LabelsEntry>)

Optional. Resource labels that can contain user-provided metadata.

=item * C<< $msg->authorized_networks() >> / C<< $msg->authorized_networks($value) >>

Type: C<String>

Optional. The full names of the Google Compute Engine
[networks](/compute/docs/networks-and-firewalls#networks) the domain
instance is connected to. Networks can be added using UpdateDomain.
The domain is only available on networks listed in `authorized_networks`.
If CIDR subnets overlap between networks, domain creation will fail.

=item * C<< $msg->reserved_ip_range() >> / C<< $msg->reserved_ip_range($value) >>

Type: C<String>

Required. The CIDR range of internal addresses that are reserved for this
domain. Reserved networks must be /24 or larger. Ranges must be
unique and non-overlapping with existing subnets in
[Domain].[authorized_networks].

=item * C<< $msg->locations() >> / C<< $msg->locations($value) >>

Type: C<String>

Required. Locations where domain needs to be provisioned.
[regions][compute/docs/regions-zones/]
e.g. us-west1 or us-east4
Service supports up to 4 locations at once. Each location will use a /26
block.

=item * C<< $msg->admin() >> / C<< $msg->admin($value) >>

Type: C<String>

Optional. The name of delegated administrator account used to perform
Active Directory operations. If not specified, `setupadmin` will be used.

=item * C<< $msg->fqdn() >> / C<< $msg->fqdn($value) >>

Type: C<String>

Output only. The fully-qualified domain name of the exposed domain used by
clients to connect to the service. Similar to what would be chosen for an
Active Directory set up on an internal network.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the instance was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1beta1::Domain::State>)

Output only. The current state of this domain.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Additional information about the current status of this
domain, if available.

=item * C<< $msg->trusts() >> / C<< $msg->trusts($value) >>

Type: C<Message> (L<Google::Cloud::Managedidentities::V1beta1::Resource::Trust>)

Output only. The current trusts associated with the domain.

=back

=head3 Enum: Domain::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<UPDATING> => C<3>

=item * C<DELETING> => C<4>

=item * C<REPAIRING> => C<5>

=item * C<PERFORMING_MAINTENANCE> => C<6>

=item * C<UNAVAILABLE> => C<7>

=back

=head2 Google::Cloud::Managedidentities::V1beta1::Resource::Trust

Represents a relationship between two domains. This allows a controller in
one domain to authenticate a user in another domain.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_domain_name() >> / C<< $msg->target_domain_name($value) >>

Type: C<String>

The fully qualified target domain name which will be in trust with the
current domain.

=item * C<< $msg->trust_type() >> / C<< $msg->trust_type($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1beta1::Trust::TrustType>)

The type of trust represented by the trust resource.

=item * C<< $msg->trust_direction() >> / C<< $msg->trust_direction($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1beta1::Trust::TrustDirection>)

The trust direction, which decides if the current domain is trusted,
trusting, or both.

=item * C<< $msg->selective_authentication() >> / C<< $msg->selective_authentication($value) >>

Type: C<Bool>

The trust authentication type, which decides whether the trusted side has
forest/domain wide access or selective access to an approved set of
resources.

=item * C<< $msg->target_dns_ip_addresses() >> / C<< $msg->target_dns_ip_addresses($value) >>

Type: C<String>

The target DNS server IP addresses which can resolve the remote domain
involved in the trust.

=item * C<< $msg->trust_handshake_secret() >> / C<< $msg->trust_handshake_secret($value) >>

Type: C<String>

Input only. The trust secret used for the handshake
with the target domain. It will not be stored.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the instance was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Managedidentities::V1beta1::Trust::State>)

Output only. The current state of the trust.

=item * C<< $msg->state_description() >> / C<< $msg->state_description($value) >>

Type: C<String>

Output only. Additional information about the current state of the
trust, if available.

=item * C<< $msg->last_trust_heartbeat_time() >> / C<< $msg->last_trust_heartbeat_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last heartbeat time when the trust was known to be
connected.

=back

=head3 Enum: Trust::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<UPDATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<CONNECTED> => C<4>

=item * C<DISCONNECTED> => C<5>

=back

=head3 Enum: Trust::TrustType

=over 4

=item * C<TRUST_TYPE_UNSPECIFIED> => C<0>

=item * C<FOREST> => C<1>

=item * C<EXTERNAL> => C<2>

=back

=head3 Enum: Trust::TrustDirection

=over 4

=item * C<TRUST_DIRECTION_UNSPECIFIED> => C<0>

=item * C<INBOUND> => C<1>

=item * C<OUTBOUND> => C<2>

=item * C<BIDIRECTIONAL> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Managedidentities::V1beta1::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
