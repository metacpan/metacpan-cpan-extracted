package Google::Cloud::Dataproc::V1::Operations;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZGF0YXByb2MvdjEvb3BlcmF0aW9ucy5wcm90bxIYZ29vZ2xlLmNs
b3VkLmRhdGFwcm9jLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsUEChZCYXRjaE9wZXJhdGlvbk1ldGFkYXRh
EhQKBWJhdGNoGAEgASgJUgViYXRjaBIdCgpiYXRjaF91dWlkGAIgASgJUgliYXRjaFV1aWQS
OwoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVh
dGVUaW1lEjcKCWRvbmVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CGRvbmVUaW1lEmoKDm9wZXJhdGlvbl90eXBlGAYgASgOMkMuZ29vZ2xlLmNsb3VkLmRhdGFw
cm9jLnYxLkJhdGNoT3BlcmF0aW9uTWV0YWRhdGEuQmF0Y2hPcGVyYXRpb25UeXBlUg1vcGVy
YXRpb25UeXBlEiAKC2Rlc2NyaXB0aW9uGAcgASgJUgtkZXNjcmlwdGlvbhJUCgZsYWJlbHMY
CCADKAsyPC5nb29nbGUuY2xvdWQuZGF0YXByb2MudjEuQmF0Y2hPcGVyYXRpb25NZXRhZGF0
YS5MYWJlbHNFbnRyeVIGbGFiZWxzEhoKCHdhcm5pbmdzGAkgAygJUgh3YXJuaW5ncxo5CgtM
YWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB
IkUKEkJhdGNoT3BlcmF0aW9uVHlwZRIkCiBCQVRDSF9PUEVSQVRJT05fVFlQRV9VTlNQRUNJ
RklFRBAAEgkKBUJBVENIEAEi9QQKGFNlc3Npb25PcGVyYXRpb25NZXRhZGF0YRIYCgdzZXNz
aW9uGAEgASgJUgdzZXNzaW9uEiEKDHNlc3Npb25fdXVpZBgCIAEoCVILc2Vzc2lvblV1aWQS
OwoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVh
dGVUaW1lEjcKCWRvbmVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CGRvbmVUaW1lEm4KDm9wZXJhdGlvbl90eXBlGAYgASgOMkcuZ29vZ2xlLmNsb3VkLmRhdGFw
cm9jLnYxLlNlc3Npb25PcGVyYXRpb25NZXRhZGF0YS5TZXNzaW9uT3BlcmF0aW9uVHlwZVIN
b3BlcmF0aW9uVHlwZRIgCgtkZXNjcmlwdGlvbhgHIAEoCVILZGVzY3JpcHRpb24SVgoGbGFi
ZWxzGAggAygLMj4uZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLlNlc3Npb25PcGVyYXRpb25N
ZXRhZGF0YS5MYWJlbHNFbnRyeVIGbGFiZWxzEhoKCHdhcm5pbmdzGAkgAygJUgh3YXJuaW5n
cxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBImUKFFNlc3Npb25PcGVyYXRpb25UeXBlEiYKIlNFU1NJT05fT1BFUkFUSU9OX1RZ
UEVfVU5TUEVDSUZJRUQQABIKCgZDUkVBVEUQARINCglURVJNSU5BVEUQAhIKCgZERUxFVEUQ
AyK1AgoWQ2x1c3Rlck9wZXJhdGlvblN0YXR1cxJRCgVzdGF0ZRgBIAEoDjI2Lmdvb2dsZS5j
bG91ZC5kYXRhcHJvYy52MS5DbHVzdGVyT3BlcmF0aW9uU3RhdHVzLlN0YXRlQgPgQQNSBXN0
YXRlEiQKC2lubmVyX3N0YXRlGAIgASgJQgPgQQNSCmlubmVyU3RhdGUSHQoHZGV0YWlscxgD
IAEoCUID4EEDUgdkZXRhaWxzEkkKEHN0YXRlX3N0YXJ0X3RpbWUYBCABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSDnN0YXRlU3RhcnRUaW1lIjgKBVN0YXRlEgsKB1VO
S05PV04QABILCgdQRU5ESU5HEAESCwoHUlVOTklORxACEggKBERPTkUQAyLYBAoYQ2x1c3Rl
ck9wZXJhdGlvbk1ldGFkYXRhEiYKDGNsdXN0ZXJfbmFtZRgHIAEoCUID4EEDUgtjbHVzdGVy
TmFtZRImCgxjbHVzdGVyX3V1aWQYCCABKAlCA+BBA1ILY2x1c3RlclV1aWQSTQoGc3RhdHVz
GAkgASgLMjAuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkNsdXN0ZXJPcGVyYXRpb25TdGF0
dXNCA+BBA1IGc3RhdHVzElwKDnN0YXR1c19oaXN0b3J5GAogAygLMjAuZ29vZ2xlLmNsb3Vk
LmRhdGFwcm9jLnYxLkNsdXN0ZXJPcGVyYXRpb25TdGF0dXNCA+BBA1INc3RhdHVzSGlzdG9y
eRIqCg5vcGVyYXRpb25fdHlwZRgLIAEoCUID4EEDUg1vcGVyYXRpb25UeXBlEiUKC2Rlc2Ny
aXB0aW9uGAwgASgJQgPgQQNSC2Rlc2NyaXB0aW9uElsKBmxhYmVscxgNIAMoCzI+Lmdvb2ds
ZS5jbG91ZC5kYXRhcHJvYy52MS5DbHVzdGVyT3BlcmF0aW9uTWV0YWRhdGEuTGFiZWxzRW50
cnlCA+BBA1IGbGFiZWxzEh8KCHdhcm5pbmdzGA4gAygJQgPgQQNSCHdhcm5pbmdzEjMKE2No
aWxkX29wZXJhdGlvbl9pZHMYDyADKAlCA+BBA1IRY2hpbGRPcGVyYXRpb25JZHMaOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASLl
BQoaTm9kZUdyb3VwT3BlcmF0aW9uTWV0YWRhdGESJwoNbm9kZV9ncm91cF9pZBgBIAEoCUID
4EEDUgtub2RlR3JvdXBJZBImCgxjbHVzdGVyX3V1aWQYAiABKAlCA+BBA1ILY2x1c3RlclV1
aWQSTQoGc3RhdHVzGAMgASgLMjAuZ29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkNsdXN0ZXJP
cGVyYXRpb25TdGF0dXNCA+BBA1IGc3RhdHVzElwKDnN0YXR1c19oaXN0b3J5GAQgAygLMjAu
Z29vZ2xlLmNsb3VkLmRhdGFwcm9jLnYxLkNsdXN0ZXJPcGVyYXRpb25TdGF0dXNCA+BBA1IN
c3RhdHVzSGlzdG9yeRJyCg5vcGVyYXRpb25fdHlwZRgFIAEoDjJLLmdvb2dsZS5jbG91ZC5k
YXRhcHJvYy52MS5Ob2RlR3JvdXBPcGVyYXRpb25NZXRhZGF0YS5Ob2RlR3JvdXBPcGVyYXRp
b25UeXBlUg1vcGVyYXRpb25UeXBlEiUKC2Rlc2NyaXB0aW9uGAYgASgJQgPgQQNSC2Rlc2Ny
aXB0aW9uEl0KBmxhYmVscxgHIAMoCzJALmdvb2dsZS5jbG91ZC5kYXRhcHJvYy52MS5Ob2Rl
R3JvdXBPcGVyYXRpb25NZXRhZGF0YS5MYWJlbHNFbnRyeUID4EEDUgZsYWJlbHMSHwoId2Fy
bmluZ3MYCCADKAlCA+BBA1IId2FybmluZ3MaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJ
UgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJzChZOb2RlR3JvdXBPcGVyYXRpb25U
eXBlEikKJU5PREVfR1JPVVBfT1BFUkFUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABIKCgZDUkVB
VEUQARIKCgZVUERBVEUQAhIKCgZERUxFVEUQAxIKCgZSRVNJWkUQBEJuChxjb20uZ29vZ2xl
LmNsb3VkLmRhdGFwcm9jLnYxQg9PcGVyYXRpb25zUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNv
bS9nby9kYXRhcHJvYy92Mi9hcGl2MS9kYXRhcHJvY3BiO2RhdGFwcm9jcGJK0jcKBxIFDgDT
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwAS
AxIAKQoJCgIDARIDEwApCggKAQgSAxUAUgoJCgIICxIDFQBSCggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgANQoJCgIIARIDGAA1CjYKAgQAEgQb
ADwBGiogTWV0YWRhdGEgZGVzY3JpYmluZyB0aGUgQmF0Y2ggb3BlcmF0aW9uLgoKCgoDBAAB
EgMbCB4KMgoEBAAEABIEHQIjAxokIE9wZXJhdGlvbiB0eXBlIGZvciBCYXRjaCByZXNvdXJj
ZXMKCgwKBQQABAABEgMdBxkKMQoGBAAEAAIAEgMfBCkaIiBCYXRjaCBvcGVyYXRpb24gdHlw
ZSBpcyB1bmtub3duLgoKDgoHBAAEAAIAARIDHwQkCg4KBwQABAACAAISAx8nKAomCgYEAAQA
AgESAyIEDhoXIEJhdGNoIG9wZXJhdGlvbiB0eXBlLgoKDgoHBAAEAAIBARIDIgQJCg4KBwQA
BAACAQISAyIMDQozCgQEAAIAEgMmAhMaJiBOYW1lIG9mIHRoZSBiYXRjaCBmb3IgdGhlIG9w
ZXJhdGlvbi4KCgwKBQQAAgAFEgMmAggKDAoFBAACAAESAyYJDgoMCgUEAAIAAxIDJhESCiwK
BAQAAgESAykCGBofIEJhdGNoIFVVSUQgZm9yIHRoZSBvcGVyYXRpb24uCgoMCgUEAAIBBRID
KQIICgwKBQQAAgEBEgMpCRMKDAoFBAACAQMSAykWFwo3CgQEAAICEgMsAiwaKiBUaGUgdGlt
ZSB3aGVuIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAAICBhIDLAIbCgwKBQQA
AgIBEgMsHCcKDAoFBAACAgMSAywqKwo0CgQEAAIDEgMvAioaJyBUaGUgdGltZSB3aGVuIHRo
ZSBvcGVyYXRpb24gZmluaXNoZWQuCgoMCgUEAAIDBhIDLwIbCgwKBQQAAgMBEgMvHCUKDAoF
BAACAwMSAy8oKQoiCgQEAAIEEgMyAigaFSBUaGUgb3BlcmF0aW9uIHR5cGUuCgoMCgUEAAIE
BhIDMgIUCgwKBQQAAgQBEgMyFSMKDAoFBAACBAMSAzImJwoyCgQEAAIFEgM1AhkaJSBTaG9y
dCBkZXNjcmlwdGlvbiBvZiB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBQUSAzUCCAoMCgUEAAIF
ARIDNQkUCgwKBQQAAgUDEgM1FxgKNAoEBAACBhIDOAIhGicgTGFiZWxzIGFzc29jaWF0ZWQg
d2l0aCB0aGUgb3BlcmF0aW9uLgoKDAoFBAACBgYSAzgCFQoMCgUEAAIGARIDOBYcCgwKBQQA
AgYDEgM4HyAKPwoEBAACBxIDOwIfGjIgV2FybmluZ3MgZW5jb3VudGVyZWQgZHVyaW5nIG9w
ZXJhdGlvbiBleGVjdXRpb24uCgoMCgUEAAIHBBIDOwIKCgwKBQQAAgcFEgM7CxEKDAoFBAAC
BwESAzsSGgoMCgUEAAIHAxIDOx0eCjgKAgQBEgQ/AGYBGiwgTWV0YWRhdGEgZGVzY3JpYmlu
ZyB0aGUgU2Vzc2lvbiBvcGVyYXRpb24uCgoKCgMEAQESAz8IIAo0CgQEAQQAEgRBAk0DGiYg
T3BlcmF0aW9uIHR5cGUgZm9yIFNlc3Npb24gcmVzb3VyY2VzCgoMCgUEAQQAARIDQQcbCjMK
BgQBBAACABIDQwQrGiQgU2Vzc2lvbiBvcGVyYXRpb24gdHlwZSBpcyB1bmtub3duLgoKDgoH
BAEEAAIAARIDQwQmCg4KBwQBBAACAAISA0MpKgovCgYEAQQAAgESA0YEDxogIENyZWF0ZSBT
ZXNzaW9uIG9wZXJhdGlvbiB0eXBlLgoKDgoHBAEEAAIBARIDRgQKCg4KBwQBBAACAQISA0YN
DgoyCgYEAQQAAgISA0kEEhojIFRlcm1pbmF0ZSBTZXNzaW9uIG9wZXJhdGlvbiB0eXBlLgoK
DgoHBAEEAAICARIDSQQNCg4KBwQBBAACAgISA0kQEQovCgYEAQQAAgMSA0wEDxogIERlbGV0
ZSBTZXNzaW9uIG9wZXJhdGlvbiB0eXBlLgoKDgoHBAEEAAIDARIDTAQKCg4KBwQBBAACAwIS
A0wNDgo1CgQEAQIAEgNQAhUaKCBOYW1lIG9mIHRoZSBzZXNzaW9uIGZvciB0aGUgb3BlcmF0
aW9uLgoKDAoFBAECAAUSA1ACCAoMCgUEAQIAARIDUAkQCgwKBQQBAgADEgNQExQKLgoEBAEC
ARIDUwIaGiEgU2Vzc2lvbiBVVUlEIGZvciB0aGUgb3BlcmF0aW9uLgoKDAoFBAECAQUSA1MC
CAoMCgUEAQIBARIDUwkVCgwKBQQBAgEDEgNTGBkKNwoEBAECAhIDVgIsGiogVGhlIHRpbWUg
d2hlbiB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAECAgYSA1YCGwoMCgUEAQIC
ARIDVhwnCgwKBQQBAgIDEgNWKisKOAoEBAECAxIDWQIqGisgVGhlIHRpbWUgd2hlbiB0aGUg
b3BlcmF0aW9uIHdhcyBmaW5pc2hlZC4KCgwKBQQBAgMGEgNZAhsKDAoFBAECAwESA1kcJQoM
CgUEAQIDAxIDWSgpCiIKBAQBAgQSA1wCKhoVIFRoZSBvcGVyYXRpb24gdHlwZS4KCgwKBQQB
AgQGEgNcAhYKDAoFBAECBAESA1wXJQoMCgUEAQIEAxIDXCgpCjIKBAQBAgUSA18CGRolIFNo
b3J0IGRlc2NyaXB0aW9uIG9mIHRoZSBvcGVyYXRpb24uCgoMCgUEAQIFBRIDXwIICgwKBQQB
AgUBEgNfCRQKDAoFBAECBQMSA18XGAo0CgQEAQIGEgNiAiEaJyBMYWJlbHMgYXNzb2NpYXRl
ZCB3aXRoIHRoZSBvcGVyYXRpb24uCgoMCgUEAQIGBhIDYgIVCgwKBQQBAgYBEgNiFhwKDAoF
BAECBgMSA2IfIAo/CgQEAQIHEgNlAh8aMiBXYXJuaW5ncyBlbmNvdW50ZXJlZCBkdXJpbmcg
b3BlcmF0aW9uIGV4ZWN1dGlvbi4KCgwKBQQBAgcEEgNlAgoKDAoFBAECBwUSA2ULEQoMCgUE
AQIHARIDZRIaCgwKBQQBAgcDEgNlHR4KKwoCBAISBWkAhQEBGh4gVGhlIHN0YXR1cyBvZiB0
aGUgb3BlcmF0aW9uLgoKCgoDBAIBEgNpCB4KJAoEBAIEABIEawJ3AxoWIFRoZSBvcGVyYXRp
b24gc3RhdGUuCgoMCgUEAgQAARIDawcMChgKBgQCBAACABIDbQQQGgkgVW51c2VkLgoKDgoH
BAIEAAIAARIDbQQLCg4KBwQCBAACAAISA20ODwowCgYEAgQAAgESA3AEEBohIFRoZSBvcGVy
YXRpb24gaGFzIGJlZW4gY3JlYXRlZC4KCg4KBwQCBAACAQESA3AECwoOCgcEAgQAAgECEgNw
Dg8KKgoGBAIEAAICEgNzBBAaGyBUaGUgb3BlcmF0aW9uIGlzIHJ1bm5pbmcuCgoOCgcEAgQA
AgIBEgNzBAsKDgoHBAIEAAICAhIDcw4PCkYKBgQCBAACAxIDdgQNGjcgVGhlIG9wZXJhdGlv
biBpcyBkb25lOyBlaXRoZXIgY2FuY2VsbGVkIG9yIGNvbXBsZXRlZC4KCg4KBwQCBAACAwES
A3YECAoOCgcEAgQAAgMCEgN2CwwKRQoEBAICABIDegI+GjggT3V0cHV0IG9ubHkuIEEgbWVz
c2FnZSBjb250YWluaW5nIHRoZSBvcGVyYXRpb24gc3RhdGUuCgoMCgUEAgIABhIDegIHCgwK
BQQCAgABEgN6CA0KDAoFBAICAAMSA3oQEQoMCgUEAgIACBIDehI9Cg8KCAQCAgAInAgAEgN6
EzwKTgoEBAICARIDfQJFGkEgT3V0cHV0IG9ubHkuIEEgbWVzc2FnZSBjb250YWluaW5nIHRo
ZSBkZXRhaWxlZCBvcGVyYXRpb24gc3RhdGUuCgoMCgUEAgIBBRIDfQIICgwKBQQCAgEBEgN9
CRQKDAoFBAICAQMSA30XGAoMCgUEAgIBCBIDfRlECg8KCAQCAgEInAgAEgN9GkMKUQoEBAIC
AhIEgAECQRpDIE91dHB1dCBvbmx5LiBBIG1lc3NhZ2UgY29udGFpbmluZyBhbnkgb3BlcmF0
aW9uIG1ldGFkYXRhIGRldGFpbHMuCgoNCgUEAgICBRIEgAECCAoNCgUEAgICARIEgAEJEAoN
CgUEAgICAxIEgAETFAoNCgUEAgICCBIEgAEVQAoQCggEAgICCJwIABIEgAEWPwo/CgQEAgID
EgaDAQKEATIaLyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhpcyBzdGF0ZSB3YXMgZW50ZXJl
ZC4KCg0KBQQCAgMGEgSDAQIbCg0KBQQCAgMBEgSDARwsCg0KBQQCAgMDEgSDAS8wCg0KBQQC
AgMIEgSEAQYxChAKCAQCAgMInAgAEgSEAQcwCjIKAgQDEgaIAQClAQEaJCBNZXRhZGF0YSBk
ZXNjcmliaW5nIHRoZSBvcGVyYXRpb24uCgoLCgMEAwESBIgBCCAKQwoEBAMCABIEigECRho1
IE91dHB1dCBvbmx5LiBOYW1lIG9mIHRoZSBjbHVzdGVyIGZvciB0aGUgb3BlcmF0aW9uLgoK
DQoFBAMCAAUSBIoBAggKDQoFBAMCAAESBIoBCRUKDQoFBAMCAAMSBIoBGBkKDQoFBAMCAAgS
BIoBGkUKEAoIBAMCAAicCAASBIoBG0QKPAoEBAMCARIEjQECRhouIE91dHB1dCBvbmx5LiBD
bHVzdGVyIFVVSUQgZm9yIHRoZSBvcGVyYXRpb24uCgoNCgUEAwIBBRIEjQECCAoNCgUEAwIB
ARIEjQEJFQoNCgUEAwIBAxIEjQEYGQoNCgUEAwIBCBIEjQEaRQoQCggEAwIBCJwIABIEjQEb
RAo2CgQEAwICEgSQAQJQGiggT3V0cHV0IG9ubHkuIEN1cnJlbnQgb3BlcmF0aW9uIHN0YXR1
cy4KCg0KBQQDAgIGEgSQAQIYCg0KBQQDAgIBEgSQARkfCg0KBQQDAgIDEgSQASIjCg0KBQQD
AgIIEgSQASRPChAKCAQDAgIInAgAEgSQASVOCj0KBAQDAgMSBpMBApQBMhotIE91dHB1dCBv
bmx5LiBUaGUgcHJldmlvdXMgb3BlcmF0aW9uIHN0YXR1cy4KCg0KBQQDAgMEEgSTAQIKCg0K
BQQDAgMGEgSTAQshCg0KBQQDAgMBEgSTASIwCg0KBQQDAgMDEgSTATM1Cg0KBQQDAgMIEgSU
AQYxChAKCAQDAgMInAgAEgSUAQcwCjAKBAQDAgQSBJcBAkkaIiBPdXRwdXQgb25seS4gVGhl
IG9wZXJhdGlvbiB0eXBlLgoKDQoFBAMCBAUSBJcBAggKDQoFBAMCBAESBJcBCRcKDQoFBAMC
BAMSBJcBGhwKDQoFBAMCBAgSBJcBHUgKEAoIBAMCBAicCAASBJcBHkcKPAoEBAMCBRIEmgEC
RhouIE91dHB1dCBvbmx5LiBTaG9ydCBkZXNjcmlwdGlvbiBvZiBvcGVyYXRpb24uCgoNCgUE
AwIFBRIEmgECCAoNCgUEAwIFARIEmgEJFAoNCgUEAwIFAxIEmgEXGQoNCgUEAwIFCBIEmgEa
RQoQCggEAwIFCJwIABIEmgEbRApBCgQEAwIGEgSdAQJOGjMgT3V0cHV0IG9ubHkuIExhYmVs
cyBhc3NvY2lhdGVkIHdpdGggdGhlIG9wZXJhdGlvbgoKDQoFBAMCBgYSBJ0BAhUKDQoFBAMC
BgESBJ0BFhwKDQoFBAMCBgMSBJ0BHyEKDQoFBAMCBggSBJ0BIk0KEAoIBAMCBgicCAASBJ0B
I0wKSwoEBAMCBxIEoAECTBo9IE91dHB1dCBvbmx5LiBFcnJvcnMgZW5jb3VudGVyZWQgZHVy
aW5nIG9wZXJhdGlvbiBleGVjdXRpb24uCgoNCgUEAwIHBBIEoAECCgoNCgUEAwIHBRIEoAEL
EQoNCgUEAwIHARIEoAESGgoNCgUEAwIHAxIEoAEdHwoNCgUEAwIHCBIEoAEgSwoQCggEAwIH
CJwIABIEoAEhSgoyCgQEAwIIEgajAQKkATIaIiBPdXRwdXQgb25seS4gQ2hpbGQgb3BlcmF0
aW9uIGlkcwoKDQoFBAMCCAQSBKMBAgoKDQoFBAMCCAUSBKMBCxEKDQoFBAMCCAESBKMBEiUK
DQoFBAMCCAMSBKMBKCoKDQoFBAMCCAgSBKQBBjEKEAoIBAMCCAicCAASBKQBBzAKPQoCBAQS
BqgBANMBARovIE1ldGFkYXRhIGRlc2NyaWJpbmcgdGhlIG5vZGUgZ3JvdXAgb3BlcmF0aW9u
LgoKCwoDBAQBEgSoAQgiCjoKBAQEBAASBqoBArkBAxoqIE9wZXJhdGlvbiB0eXBlIGZvciBu
b2RlIGdyb3VwIHJlc291cmNlcy4KCg0KBQQEBAABEgSqAQcdCjcKBgQEBAACABIErAEELhon
IE5vZGUgZ3JvdXAgb3BlcmF0aW9uIHR5cGUgaXMgdW5rbm93bi4KCg8KBwQEBAACAAESBKwB
BCkKDwoHBAQEAAIAAhIErAEsLQozCgYEBAQAAgESBK8BBA8aIyBDcmVhdGUgbm9kZSBncm91
cCBvcGVyYXRpb24gdHlwZS4KCg8KBwQEBAACAQESBK8BBAoKDwoHBAQEAAIBAhIErwENDgoz
CgYEBAQAAgISBLIBBA8aIyBVcGRhdGUgbm9kZSBncm91cCBvcGVyYXRpb24gdHlwZS4KCg8K
BwQEBAACAgESBLIBBAoKDwoHBAQEAAICAhIEsgENDgozCgYEBAQAAgMSBLUBBA8aIyBEZWxl
dGUgbm9kZSBncm91cCBvcGVyYXRpb24gdHlwZS4KCg8KBwQEBAACAwESBLUBBAoKDwoHBAQE
AAIDAhIEtQENDgozCgYEBAQAAgQSBLgBBA8aIyBSZXNpemUgbm9kZSBncm91cCBvcGVyYXRp
b24gdHlwZS4KCg8KBwQEBAACBAESBLgBBAoKDwoHBAQEAAIEAhIEuAENDgo9CgQEBAIAEgS8
AQJHGi8gT3V0cHV0IG9ubHkuIE5vZGUgZ3JvdXAgSUQgZm9yIHRoZSBvcGVyYXRpb24uCgoN
CgUEBAIABRIEvAECCAoNCgUEBAIAARIEvAEJFgoNCgUEBAIAAxIEvAEZGgoNCgUEBAIACBIE
vAEbRgoQCggEBAIACJwIABIEvAEcRQpTCgQEBAIBEgS/AQJGGkUgT3V0cHV0IG9ubHkuIENs
dXN0ZXIgVVVJRCBhc3NvY2lhdGVkIHdpdGggdGhlIG5vZGUgZ3JvdXAgb3BlcmF0aW9uLgoK
DQoFBAQCAQUSBL8BAggKDQoFBAQCAQESBL8BCRUKDQoFBAQCAQMSBL8BGBkKDQoFBAQCAQgS
BL8BGkUKEAoIBAQCAQicCAASBL8BG0QKNgoEBAQCAhIEwgECUBooIE91dHB1dCBvbmx5LiBD
dXJyZW50IG9wZXJhdGlvbiBzdGF0dXMuCgoNCgUEBAICBhIEwgECGAoNCgUEBAICARIEwgEZ
HwoNCgUEBAICAxIEwgEiIwoNCgUEBAICCBIEwgEkTwoQCggEBAICCJwIABIEwgElTgo9CgQE
BAIDEgbFAQLGATIaLSBPdXRwdXQgb25seS4gVGhlIHByZXZpb3VzIG9wZXJhdGlvbiBzdGF0
dXMuCgoNCgUEBAIDBBIExQECCgoNCgUEBAIDBhIExQELIQoNCgUEBAIDARIExQEiMAoNCgUE
BAIDAxIExQEzNAoNCgUEBAIDCBIExgEGMQoQCggEBAIDCJwIABIExgEHMAojCgQEBAIEEgTJ
AQIsGhUgVGhlIG9wZXJhdGlvbiB0eXBlLgoKDQoFBAQCBAYSBMkBAhgKDQoFBAQCBAESBMkB
GScKDQoFBAQCBAMSBMkBKisKPAoEBAQCBRIEzAECRRouIE91dHB1dCBvbmx5LiBTaG9ydCBk
ZXNjcmlwdGlvbiBvZiBvcGVyYXRpb24uCgoNCgUEBAIFBRIEzAECCAoNCgUEBAIFARIEzAEJ
FAoNCgUEBAIFAxIEzAEXGAoNCgUEBAIFCBIEzAEZRAoQCggEBAIFCJwIABIEzAEaQwpCCgQE
BAIGEgTPAQJNGjQgT3V0cHV0IG9ubHkuIExhYmVscyBhc3NvY2lhdGVkIHdpdGggdGhlIG9w
ZXJhdGlvbi4KCg0KBQQEAgYGEgTPAQIVCg0KBQQEAgYBEgTPARYcCg0KBQQEAgYDEgTPAR8g
Cg0KBQQEAgYIEgTPASFMChAKCAQEAgYInAgAEgTPASJLCksKBAQEAgcSBNIBAksaPSBPdXRw
dXQgb25seS4gRXJyb3JzIGVuY291bnRlcmVkIGR1cmluZyBvcGVyYXRpb24gZXhlY3V0aW9u
LgoKDQoFBAQCBwQSBNIBAgoKDQoFBAQCBwUSBNIBCxEKDQoFBAQCBwESBNIBEhoKDQoFBAQC
BwMSBNIBHR4KDQoFBAQCBwgSBNIBH0oKEAoIBAQCBwicCAASBNIBIEliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata ===
    # Fields for BatchOperationMetadata
    # Field: batch Type: 9 ()
    # Field: batch_uuid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: done_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_type Type: 14 (.google.cloud.dataproc.v1.BatchOperationMetadata.BatchOperationType)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.BatchOperationMetadata.LabelsEntry)
    # Field: warnings Type: 9 ()

# Enum: BatchOperationMetadata::BatchOperationType
our $BatchOperationMetadata_BATCH_OPERATION_TYPE_UNSPECIFIED = 0;
our $BatchOperationMetadata_BATCH = 1;

# === Message: Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata ===
    # Fields for SessionOperationMetadata
    # Field: session Type: 9 ()
    # Field: session_uuid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: done_time Type: 11 (.google.protobuf.Timestamp)
    # Field: operation_type Type: 14 (.google.cloud.dataproc.v1.SessionOperationMetadata.SessionOperationType)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.SessionOperationMetadata.LabelsEntry)
    # Field: warnings Type: 9 ()

# Enum: SessionOperationMetadata::SessionOperationType
our $SessionOperationMetadata_SESSION_OPERATION_TYPE_UNSPECIFIED = 0;
our $SessionOperationMetadata_CREATE = 1;
our $SessionOperationMetadata_TERMINATE = 2;
our $SessionOperationMetadata_DELETE = 3;

# === Message: Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus ===
    # Fields for ClusterOperationStatus
    # Field: state Type: 14 (.google.cloud.dataproc.v1.ClusterOperationStatus.State)
    # Field: inner_state Type: 9 ()
    # Field: details Type: 9 ()
    # Field: state_start_time Type: 11 (.google.protobuf.Timestamp)

# Enum: ClusterOperationStatus::State
our $ClusterOperationStatus_UNKNOWN = 0;
our $ClusterOperationStatus_PENDING = 1;
our $ClusterOperationStatus_RUNNING = 2;
our $ClusterOperationStatus_DONE = 3;

# === Message: Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata ===
    # Fields for ClusterOperationMetadata
    # Field: cluster_name Type: 9 ()
    # Field: cluster_uuid Type: 9 ()
    # Field: status Type: 11 (.google.cloud.dataproc.v1.ClusterOperationStatus)
    # Field: status_history Type: 11 (.google.cloud.dataproc.v1.ClusterOperationStatus)
    # Field: operation_type Type: 9 ()
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.ClusterOperationMetadata.LabelsEntry)
    # Field: warnings Type: 9 ()
    # Field: child_operation_ids Type: 9 ()

# === Message: Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata ===
    # Fields for NodeGroupOperationMetadata
    # Field: node_group_id Type: 9 ()
    # Field: cluster_uuid Type: 9 ()
    # Field: status Type: 11 (.google.cloud.dataproc.v1.ClusterOperationStatus)
    # Field: status_history Type: 11 (.google.cloud.dataproc.v1.ClusterOperationStatus)
    # Field: operation_type Type: 14 (.google.cloud.dataproc.v1.NodeGroupOperationMetadata.NodeGroupOperationType)
    # Field: description Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.dataproc.v1.NodeGroupOperationMetadata.LabelsEntry)
    # Field: warnings Type: 9 ()

# Enum: NodeGroupOperationMetadata::NodeGroupOperationType
our $NodeGroupOperationMetadata_NODE_GROUP_OPERATION_TYPE_UNSPECIFIED = 0;
our $NodeGroupOperationMetadata_CREATE = 1;
our $NodeGroupOperationMetadata_UPDATE = 2;
our $NodeGroupOperationMetadata_DELETE = 3;
our $NodeGroupOperationMetadata_RESIZE = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataproc::V1::Operations - Compiled Protocol Buffers messages for google/cloud/dataproc/v1/operations.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::Operations;

    my $msg = Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata->new({
        batch => $batch,
        batch_uuid => $batch_uuid,
        create_time => $create_time,
        done_time => $done_time,
    });

    # Read or update a field
    my $val = $msg->batch();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataproc/v1/operations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata

Metadata describing the Batch operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->batch() >> / C<< $msg->batch($value) >>

Type: C<String>

Name of the batch for the operation.

=item * C<< $msg->batch_uuid() >> / C<< $msg->batch_uuid($value) >>

Type: C<String>

Batch UUID for the operation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the operation was created.

=item * C<< $msg->done_time() >> / C<< $msg->done_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the operation finished.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::BatchOperationMetadata::BatchOperationType>)

The operation type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Short description of the operation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::BatchOperationMetadata::LabelsEntry>)

Labels associated with the operation.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<String>

Warnings encountered during operation execution.

=back

=head3 Enum: BatchOperationMetadata::BatchOperationType

=over 4

=item * C<BATCH_OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<BATCH> => C<1>

=back

=head2 Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata

Metadata describing the Session operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<String>

Name of the session for the operation.

=item * C<< $msg->session_uuid() >> / C<< $msg->session_uuid($value) >>

Type: C<String>

Session UUID for the operation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the operation was created.

=item * C<< $msg->done_time() >> / C<< $msg->done_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time when the operation was finished.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::SessionOperationMetadata::SessionOperationType>)

The operation type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Short description of the operation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::SessionOperationMetadata::LabelsEntry>)

Labels associated with the operation.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<String>

Warnings encountered during operation execution.

=back

=head3 Enum: SessionOperationMetadata::SessionOperationType

=over 4

=item * C<SESSION_OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<TERMINATE> => C<2>

=item * C<DELETE> => C<3>

=back

=head2 Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus

The status of the operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::ClusterOperationStatus::State>)

Output only. A message containing the operation state.

=item * C<< $msg->inner_state() >> / C<< $msg->inner_state($value) >>

Type: C<String>

Output only. A message containing the detailed operation state.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<String>

Output only. A message containing any operation metadata details.

=item * C<< $msg->state_start_time() >> / C<< $msg->state_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time this state was entered.

=back

=head3 Enum: ClusterOperationStatus::State

=over 4

=item * C<UNKNOWN> => C<0>

=item * C<PENDING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<DONE> => C<3>

=back

=head2 Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata

Metadata describing the operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cluster_name() >> / C<< $msg->cluster_name($value) >>

Type: C<String>

Output only. Name of the cluster for the operation.

=item * C<< $msg->cluster_uuid() >> / C<< $msg->cluster_uuid($value) >>

Type: C<String>

Output only. Cluster UUID for the operation.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus>)

Output only. Current operation status.

=item * C<< $msg->status_history() >> / C<< $msg->status_history($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus>)

Output only. The previous operation status.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<String>

Output only. The operation type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Short description of operation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::ClusterOperationMetadata::LabelsEntry>)

Output only. Labels associated with the operation

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<String>

Output only. Errors encountered during operation execution.

=item * C<< $msg->child_operation_ids() >> / C<< $msg->child_operation_ids($value) >>

Type: C<String>

Output only. Child operation ids

=back

=head2 Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata

Metadata describing the node group operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->node_group_id() >> / C<< $msg->node_group_id($value) >>

Type: C<String>

Output only. Node group ID for the operation.

=item * C<< $msg->cluster_uuid() >> / C<< $msg->cluster_uuid($value) >>

Type: C<String>

Output only. Cluster UUID associated with the node group operation.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus>)

Output only. Current operation status.

=item * C<< $msg->status_history() >> / C<< $msg->status_history($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::ClusterOperationStatus>)

Output only. The previous operation status.

=item * C<< $msg->operation_type() >> / C<< $msg->operation_type($value) >>

Type: C<Enum> (L<Google::Cloud::Dataproc::V1::NodeGroupOperationMetadata::NodeGroupOperationType>)

The operation type.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Short description of operation.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Dataproc::V1::Operations::NodeGroupOperationMetadata::LabelsEntry>)

Output only. Labels associated with the operation.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<String>

Output only. Errors encountered during operation execution.

=back

=head3 Enum: NodeGroupOperationMetadata::NodeGroupOperationType

=over 4

=item * C<NODE_GROUP_OPERATION_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<UPDATE> => C<2>

=item * C<DELETE> => C<3>

=item * C<RESIZE> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataproc::V1::Operations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
