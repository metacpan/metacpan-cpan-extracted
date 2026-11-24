package Google::Dataflow::V1beta3::Snapshots;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvZGF0YWZsb3cvdjFiZXRhMy9zbmFwc2hvdHMucHJvdG8SF2dvb2dsZS5kYXRh
Zmxvdy52MWJldGEzGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpkBChZQdWJzdWJTbmFwc2hvdE1ldGFkYXRhEh0K
CnRvcGljX25hbWUYASABKAlSCXRvcGljTmFtZRIjCg1zbmFwc2hvdF9uYW1lGAIgASgJUgxz
bmFwc2hvdE5hbWUSOwoLZXhwaXJlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wUgpleHBpcmVUaW1lIsUDCghTbmFwc2hvdBIOCgJpZBgBIAEoCVICaWQSHQoKcHJv
amVjdF9pZBgCIAEoCVIJcHJvamVjdElkEiIKDXNvdXJjZV9qb2JfaWQYAyABKAlSC3NvdXJj
ZUpvYklkEj8KDWNyZWF0aW9uX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wUgxjcmVhdGlvblRpbWUSKwoDdHRsGAUgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0
aW9uUgN0dGwSPAoFc3RhdGUYBiABKA4yJi5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5TbmFw
c2hvdFN0YXRlUgVzdGF0ZRJYCg9wdWJzdWJfbWV0YWRhdGEYByADKAsyLy5nb29nbGUuZGF0
YWZsb3cudjFiZXRhMy5QdWJzdWJTbmFwc2hvdE1ldGFkYXRhUg5wdWJzdWJNZXRhZGF0YRIg
CgtkZXNjcmlwdGlvbhgIIAEoCVILZGVzY3JpcHRpb24SJgoPZGlza19zaXplX2J5dGVzGAkg
ASgDUg1kaXNrU2l6ZUJ5dGVzEhYKBnJlZ2lvbhgKIAEoCVIGcmVnaW9uInAKEkdldFNuYXBz
aG90UmVxdWVzdBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZWN0SWQSHwoLc25hcHNob3Rf
aWQYAiABKAlSCnNuYXBzaG90SWQSGgoIbG9jYXRpb24YAyABKAlSCGxvY2F0aW9uInMKFURl
bGV0ZVNuYXBzaG90UmVxdWVzdBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZWN0SWQSHwoL
c25hcHNob3RfaWQYAiABKAlSCnNuYXBzaG90SWQSGgoIbG9jYXRpb24YAyABKAlSCGxvY2F0
aW9uIhgKFkRlbGV0ZVNuYXBzaG90UmVzcG9uc2UiaAoUTGlzdFNuYXBzaG90c1JlcXVlc3QS
HQoKcHJvamVjdF9pZBgBIAEoCVIJcHJvamVjdElkEhUKBmpvYl9pZBgDIAEoCVIFam9iSWQS
GgoIbG9jYXRpb24YAiABKAlSCGxvY2F0aW9uIlgKFUxpc3RTbmFwc2hvdHNSZXNwb25zZRI/
CglzbmFwc2hvdHMYASADKAsyIS5nb29nbGUuZGF0YWZsb3cudjFiZXRhMy5TbmFwc2hvdFIJ
c25hcHNob3RzKmkKDVNuYXBzaG90U3RhdGUSGgoWVU5LTk9XTl9TTkFQU0hPVF9TVEFURRAA
EgsKB1BFTkRJTkcQARILCgdSVU5OSU5HEAISCQoFUkVBRFkQAxIKCgZGQUlMRUQQBBILCgdE
RUxFVEVEEAUyjQcKEFNuYXBzaG90c1YxQmV0YTMS6AEKC0dldFNuYXBzaG90EisuZ29vZ2xl
LmRhdGFmbG93LnYxYmV0YTMuR2V0U25hcHNob3RSZXF1ZXN0GiEuZ29vZ2xlLmRhdGFmbG93
LnYxYmV0YTMuU25hcHNob3QiiAGC0+STAoEBEkgvdjFiMy9wcm9qZWN0cy97cHJvamVjdF9p
ZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc25hcHNob3RzL3tzbmFwc2hvdF9pZH1aNRIzL3Yx
YjMvcHJvamVjdHMve3Byb2plY3RfaWR9L3NuYXBzaG90cy97c25hcHNob3RfaWR9EuwBCg5E
ZWxldGVTbmFwc2hvdBIuLmdvb2dsZS5kYXRhZmxvdy52MWJldGEzLkRlbGV0ZVNuYXBzaG90
UmVxdWVzdBovLmdvb2dsZS5kYXRhZmxvdy52MWJldGEzLkRlbGV0ZVNuYXBzaG90UmVzcG9u
c2UieYLT5JMCcypIL3YxYjMvcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9j
YXRpb259L3NuYXBzaG90cy97c25hcHNob3RfaWR9WicqJS92MWIzL3Byb2plY3RzL3twcm9q
ZWN0X2lkfS9zbmFwc2hvdHMSqQIKDUxpc3RTbmFwc2hvdHMSLS5nb29nbGUuZGF0YWZsb3cu
djFiZXRhMy5MaXN0U25hcHNob3RzUmVxdWVzdBouLmdvb2dsZS5kYXRhZmxvdy52MWJldGEz
Lkxpc3RTbmFwc2hvdHNSZXNwb25zZSK4AYLT5JMCsQESSC92MWIzL3Byb2plY3RzL3twcm9q
ZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9qb2JzL3tqb2JfaWR9L3NuYXBzaG90c1o8
EjovdjFiMy9wcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc25h
cHNob3RzWicSJS92MWIzL3Byb2plY3RzL3twcm9qZWN0X2lkfS9zbmFwc2hvdHMac8pBF2Rh
dGFmbG93Lmdvb2dsZWFwaXMuY29t0kFWaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2NvbXB1
dGVC0QEKG2NvbS5nb29nbGUuZGF0YWZsb3cudjFiZXRhM0IOU25hcHNob3RzUHJvdG9QAVo9
Y2xvdWQuZ29vZ2xlLmNvbS9nby9kYXRhZmxvdy9hcGl2MWJldGEzL2RhdGFmbG93cGI7ZGF0
YWZsb3dwYqoCHUdvb2dsZS5DbG91ZC5EYXRhZmxvdy5WMUJldGEzygIdR29vZ2xlXENsb3Vk
XERhdGFmbG93XFYxYmV0YTPqAiBHb29nbGU6OkNsb3VkOjpEYXRhZmxvdzo6VjFiZXRhM0qp
JAoHEgUOALMBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
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
IAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKAoJCgIDAxIDFQApCggKAQgSAxcA
OgoJCgIIJRIDFwA6CggKAQgSAxgAVAoJCgIICxIDGABUCggKAQgSAxkAIgoJCgIIChIDGQAi
CggKAQgSAxoALwoJCgIICBIDGgAvCggKAQgSAxsANAoJCgIIARIDGwA0CggKAQgSAxwAOgoJ
CgIIKRIDHAA6CggKAQgSAx0AOQoJCgIILRIDHQA5ClEKAgYAEgQgAEIBGkUgUHJvdmlkZXMg
bWV0aG9kcyB0byBtYW5hZ2Ugc25hcHNob3RzIG9mIEdvb2dsZSBDbG91ZCBEYXRhZmxvdyBq
b2JzLgoKCgoDBgABEgMgCBgKCgoDBgADEgMhAj8KDAoFBgADmQgSAyECPwoLCgMGAAMSBCIC
JDAKDQoFBgADmggSBCICJDAKMgoEBgACABIEJwIuAxokIEdldHMgaW5mb3JtYXRpb24gYWJv
dXQgYSBzbmFwc2hvdC4KCgwKBQYAAgABEgMnBhEKDAoFBgACAAISAycSJAoMCgUGAAIAAxID
Jy83Cg0KBQYAAgAEEgQoBC0GChEKCQYAAgAEsMq8IhIEKAQtBgojCgQGAAIBEgQxAjYDGhUg
RGVsZXRlcyBhIHNuYXBzaG90LgoKDAoFBgACAQESAzEGFAoMCgUGAAIBAhIDMRUqCgwKBQYA
AgEDEgMxNUsKDQoFBgACAQQSBDIENQYKEQoJBgACAQSwyrwiEgQyBDUGCiAKBAYAAgISBDkC
QQMaEiBMaXN0cyBzbmFwc2hvdHMuCgoMCgUGAAICARIDOQYTCgwKBQYAAgICEgM5FCgKDAoF
BgACAgMSAzkzSAoNCgUGAAICBBIEOgRABgoRCgkGAAICBLDKvCISBDoEQAYKHQoCBQASBEUA
WAEaESBTbmFwc2hvdCBzdGF0ZS4KCgoKAwUAARIDRQUSCh0KBAUAAgASA0cCHRoQIFVua25v
d24gc3RhdGUuCgoMCgUFAAIAARIDRwIYCgwKBQUAAgACEgNHGxwKaAoEBQACARIDSwIOGlsg
U25hcHNob3QgaW50ZW50IHRvIGNyZWF0ZSBoYXMgYmVlbiBwZXJzaXN0ZWQsIHNuYXBzaG90
dGluZyBvZiBzdGF0ZSBoYXMgbm90CiB5ZXQgc3RhcnRlZC4KCgwKBQUAAgEBEgNLAgkKDAoF
BQACAQISA0sMDQovCgQFAAICEgNOAg4aIiBTbmFwc2hvdHRpbmcgaXMgYmVpbmcgcGVyZm9y
bWVkLgoKDAoFBQACAgESA04CCQoMCgUFAAICAhIDTgwNCkEKBAUAAgMSA1ECDBo0IFNuYXBz
aG90IGhhcyBiZWVuIGNyZWF0ZWQgYW5kIGlzIHJlYWR5IHRvIGJlIHVzZWQuCgoMCgUFAAID
ARIDUQIHCgwKBQUAAgMCEgNRCgsKLQoEBQACBBIDVAINGiAgU25hcHNob3QgZmFpbGVkIHRv
IGJlIGNyZWF0ZWQuCgoMCgUFAAIEARIDVAIICgwKBQUAAgQCEgNUCwwKKQoEBQACBRIDVwIO
GhwgU25hcHNob3QgaGFzIGJlZW4gZGVsZXRlZC4KCgwKBQUAAgUBEgNXAgkKDAoFBQACBQIS
A1cMDQorCgIEABIEWwBkARofIFJlcHJlc2VudHMgYSBQdWJzdWIgc25hcHNob3QuCgoKCgME
AAESA1sIHgosCgQEAAIAEgNdAhgaHyBUaGUgbmFtZSBvZiB0aGUgUHVic3ViIHRvcGljLgoK
DAoFBAACAAUSA10CCAoMCgUEAAIAARIDXQkTCgwKBQQAAgADEgNdFhcKLwoEBAACARIDYAIb
GiIgVGhlIG5hbWUgb2YgdGhlIFB1YnN1YiBzbmFwc2hvdC4KCgwKBQQAAgEFEgNgAggKDAoF
BAACAQESA2AJFgoMCgUEAAIBAxIDYBkaCjYKBAQAAgISA2MCLBopIFRoZSBleHBpcmUgdGlt
ZSBvZiB0aGUgUHVic3ViIHNuYXBzaG90LgoKDAoFBAACAgYSA2MCGwoMCgUEAAICARIDYxwn
CgwKBQQAAgIDEgNjKisKLgoCBAESBWcAhgEBGiEgUmVwcmVzZW50cyBhIHNuYXBzaG90IG9m
IGEgam9iLgoKCgoDBAEBEgNnCBAKLgoEBAECABIDaQIQGiEgVGhlIHVuaXF1ZSBJRCBvZiB0
aGlzIHNuYXBzaG90LgoKDAoFBAECAAUSA2kCCAoMCgUEAQIAARIDaQkLCgwKBQQBAgADEgNp
Dg8KNAoEBAECARIDbAIYGicgVGhlIHByb2plY3QgdGhpcyBzbmFwc2hvdCBiZWxvbmdzIHRv
LgoKDAoFBAECAQUSA2wCCAoMCgUEAQIBARIDbAkTCgwKBQQBAgEDEgNsFhcKNgoEBAECAhID
bwIbGikgVGhlIGpvYiB0aGlzIHNuYXBzaG90IHdhcyBjcmVhdGVkIGZyb20uCgoMCgUEAQIC
BRIDbwIICgwKBQQBAgIBEgNvCRYKDAoFBAECAgMSA28ZGgoyCgQEAQIDEgNyAi4aJSBUaGUg
dGltZSB0aGlzIHNuYXBzaG90IHdhcyBjcmVhdGVkLgoKDAoFBAECAwYSA3ICGwoMCgUEAQID
ARIDchwpCgwKBQQBAgMDEgNyLC0KUAoEBAECBBIDdQIjGkMgVGhlIHRpbWUgYWZ0ZXIgd2hp
Y2ggdGhpcyBzbmFwc2hvdCB3aWxsIGJlIGF1dG9tYXRpY2FsbHkgZGVsZXRlZC4KCgwKBQQB
AgQGEgN1AhoKDAoFBAECBAESA3UbHgoMCgUEAQIEAxIDdSEiCiUKBAQBAgUSA3gCGhoYIFN0
YXRlIG9mIHRoZSBzbmFwc2hvdC4KCgwKBQQBAgUGEgN4Ag8KDAoFBAECBQESA3gQFQoMCgUE
AQIFAxIDeBgZCikKBAQBAgYSA3sCNhocIFB1Yi9TdWIgc25hcHNob3QgbWV0YWRhdGEuCgoM
CgUEAQIGBBIDewIKCgwKBQQBAgYGEgN7CyEKDAoFBAECBgESA3siMQoMCgUEAQIGAxIDezQ1
CkcKBAQBAgcSA34CGRo6IFVzZXIgc3BlY2lmaWVkIGRlc2NyaXB0aW9uIG9mIHRoZSBzbmFw
c2hvdC4gTWF5YmUgZW1wdHkuCgoMCgUEAQIHBRIDfgIICgwKBQQBAgcBEgN+CRQKDAoFBAEC
BwMSA34XGAphCgQEAQIIEgSCAQIcGlMgVGhlIGRpc2sgYnl0ZSBzaXplIG9mIHRoZSBzbmFw
c2hvdC4gT25seSBhdmFpbGFibGUgZm9yIHNuYXBzaG90cyBpbiBSRUFEWQogc3RhdGUuCgoN
CgUEAQIIBRIEggECBwoNCgUEAQIIARIEggEIFwoNCgUEAQIIAxIEggEaGwpPCgQEAQIJEgSF
AQIVGkEgQ2xvdWQgcmVnaW9uIHdoZXJlIHRoaXMgc25hcHNob3QgbGl2ZXMgaW4sIGUuZy4s
ICJ1cy1jZW50cmFsMSIuCgoNCgUEAQIJBRIEhQECCAoNCgUEAQIJARIEhQEJDwoNCgUEAQIJ
AxIEhQESFAo7CgIEAhIGiQEAkgEBGi0gUmVxdWVzdCB0byBnZXQgaW5mb3JtYXRpb24gYWJv
dXQgYSBzbmFwc2hvdAoKCwoDBAIBEgSJAQgaClIKBAQCAgASBIsBAhgaRCBUaGUgSUQgb2Yg
dGhlIENsb3VkIFBsYXRmb3JtIHByb2plY3QgdGhhdCB0aGUgc25hcHNob3QgYmVsb25ncyB0
by4KCg0KBQQCAgAFEgSLAQIICg0KBQQCAgABEgSLAQkTCg0KBQQCAgADEgSLARYXCicKBAQC
AgESBI4BAhkaGSBUaGUgSUQgb2YgdGhlIHNuYXBzaG90LgoKDQoFBAICAQUSBI4BAggKDQoF
BAICAQESBI4BCRQKDQoFBAICAQMSBI4BFxgKOQoEBAICAhIEkQECFhorIFRoZSBsb2NhdGlv
biB0aGF0IGNvbnRhaW5zIHRoaXMgc25hcHNob3QuCgoNCgUEAgICBRIEkQECCAoNCgUEAgIC
ARIEkQEJEQoNCgUEAgICAxIEkQEUFQotCgIEAxIGlQEAngEBGh8gUmVxdWVzdCB0byBkZWxl
dGUgYSBzbmFwc2hvdC4KCgsKAwQDARIElQEIHQpSCgQEAwIAEgSXAQIYGkQgVGhlIElEIG9m
IHRoZSBDbG91ZCBQbGF0Zm9ybSBwcm9qZWN0IHRoYXQgdGhlIHNuYXBzaG90IGJlbG9uZ3Mg
dG8uCgoNCgUEAwIABRIElwECCAoNCgUEAwIAARIElwEJEwoNCgUEAwIAAxIElwEWFwonCgQE
AwIBEgSaAQIZGhkgVGhlIElEIG9mIHRoZSBzbmFwc2hvdC4KCg0KBQQDAgEFEgSaAQIICg0K
BQQDAgEBEgSaAQkUCg0KBQQDAgEDEgSaARcYCjkKBAQDAgISBJ0BAhYaKyBUaGUgbG9jYXRp
b24gdGhhdCBjb250YWlucyB0aGlzIHNuYXBzaG90LgoKDQoFBAMCAgUSBJ0BAggKDQoFBAMC
AgESBJ0BCREKDQoFBAMCAgMSBJ0BFBUKMAoCBAQSBKEBACEaJCBSZXNwb25zZSBmcm9tIGRl
bGV0aW5nIGEgc25hcHNob3QuCgoLCgMEBAESBKEBCB4KKgoCBAUSBqQBAK0BARocIFJlcXVl
c3QgdG8gbGlzdCBzbmFwc2hvdHMuCgoLCgMEBQESBKQBCBwKNQoEBAUCABIEpgECGBonIFRo
ZSBwcm9qZWN0IElEIHRvIGxpc3Qgc25hcHNob3RzIGZvci4KCg0KBQQFAgAFEgSmAQIICg0K
BQQFAgABEgSmAQkTCg0KBQQFAgADEgSmARYXCkMKBAQFAgESBKkBAhQaNSBJZiBzcGVjaWZp
ZWQsIGxpc3Qgc25hcHNob3RzIGNyZWF0ZWQgZnJvbSB0aGlzIGpvYi4KCg0KBQQFAgEFEgSp
AQIICg0KBQQFAgEBEgSpAQkPCg0KBQQFAgEDEgSpARITCjIKBAQFAgISBKwBAhYaJCBUaGUg
bG9jYXRpb24gdG8gbGlzdCBzbmFwc2hvdHMgaW4uCgoNCgUEBQICBRIErAECCAoNCgUEBQIC
ARIErAEJEQoNCgUEBQICAxIErAEUFQoiCgIEBhIGsAEAswEBGhQgTGlzdCBvZiBzbmFwc2hv
dHMuCgoLCgMEBgESBLABCB0KIwoEBAYCABIEsgECIhoVIFJldHVybmVkIHNuYXBzaG90cy4K
Cg0KBQQGAgAEEgSyAQIKCg0KBQQGAgAGEgSyAQsTCg0KBQQGAgABEgSyARQdCg0KBQQGAgAD
EgSyASAhYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata ===
    # Fields for PubsubSnapshotMetadata
    # Field: topic_name Type: 9 ()
    # Field: snapshot_name Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Dataflow::V1beta3::Snapshots::Snapshot ===
    # Fields for Snapshot
    # Field: id Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: source_job_id Type: 9 ()
    # Field: creation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ttl Type: 11 (.google.protobuf.Duration)
    # Field: state Type: 14 (.google.dataflow.v1beta3.SnapshotState)
    # Field: pubsub_metadata Type: 11 (.google.dataflow.v1beta3.PubsubSnapshotMetadata)
    # Field: description Type: 9 ()
    # Field: disk_size_bytes Type: 3 ()
    # Field: region Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest ===
    # Fields for GetSnapshotRequest
    # Field: project_id Type: 9 ()
    # Field: snapshot_id Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest ===
    # Fields for DeleteSnapshotRequest
    # Field: project_id Type: 9 ()
    # Field: snapshot_id Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse ===
    # Fields for DeleteSnapshotResponse

# === Message: Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest ===
    # Fields for ListSnapshotsRequest
    # Field: project_id Type: 9 ()
    # Field: job_id Type: 9 ()
    # Field: location Type: 9 ()

# === Message: Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse ===
    # Fields for ListSnapshotsResponse
    # Field: snapshots Type: 11 (.google.dataflow.v1beta3.Snapshot)

# === Service Client: Google::Dataflow::V1beta3::Snapshots::SnapshotsV1Beta3Client ===
package Google::Dataflow::V1beta3::Snapshots::SnapshotsV1Beta3Client;

=pod

=head2 Service Client: Google::Dataflow::V1beta3::Snapshots::SnapshotsV1Beta3Client

Client stub representing the remote C<SnapshotsV1Beta3> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dataflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataflow.googleapis.com:443' );

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

sub get_snapshot {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.dataflow.v1beta3.SnapshotsV1Beta3',
        method         => 'GetSnapshot',
        request        => $req,
        response_class => 'Google::Dataflow::V1beta3::Snapshots::Snapshot',
    });
}

sub delete_snapshot {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.dataflow.v1beta3.SnapshotsV1Beta3',
        method         => 'DeleteSnapshot',
        request        => $req,
        response_class => 'Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse',
    });
}

sub list_snapshots {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.dataflow.v1beta3.SnapshotsV1Beta3',
        method         => 'ListSnapshots',
        request        => $req,
        response_class => 'Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Dataflow::V1beta3::Snapshots - Compiled Protocol Buffers messages for google/dataflow/v1beta3/snapshots.proto

=head1 SYNOPSIS

    use Google::Dataflow::V1beta3::Snapshots;

    my $msg = Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata->new({
        topic_name => $topic_name,
        snapshot_name => $snapshot_name,
        expire_time => $expire_time,
    });

    # Read or update a field
    my $val = $msg->topic_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/dataflow/v1beta3/snapshots.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata

Represents a Pubsub snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->topic_name() >> / C<< $msg->topic_name($value) >>

Type: C<String>

The name of the Pubsub topic.

=item * C<< $msg->snapshot_name() >> / C<< $msg->snapshot_name($value) >>

Type: C<String>

The name of the Pubsub snapshot.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The expire time of the Pubsub snapshot.

=back

=head2 Google::Dataflow::V1beta3::Snapshots::Snapshot

Represents a snapshot of a job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The unique ID of this snapshot.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project this snapshot belongs to.

=item * C<< $msg->source_job_id() >> / C<< $msg->source_job_id($value) >>

Type: C<String>

The job this snapshot was created from.

=item * C<< $msg->creation_time() >> / C<< $msg->creation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this snapshot was created.

=item * C<< $msg->ttl() >> / C<< $msg->ttl($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The time after which this snapshot will be automatically deleted.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Dataflow::V1beta3::SnapshotState>)

State of the snapshot.

=item * C<< $msg->pubsub_metadata() >> / C<< $msg->pubsub_metadata($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Snapshots::PubsubSnapshotMetadata>)

Pub/Sub snapshot metadata.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified description of the snapshot. Maybe empty.

=item * C<< $msg->disk_size_bytes() >> / C<< $msg->disk_size_bytes($value) >>

Type: C<Int64>

The disk byte size of the snapshot. Only available for snapshots in READY
state.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Cloud region where this snapshot lives in, e.g., "us-central1".

=back

=head2 Google::Dataflow::V1beta3::Snapshots::GetSnapshotRequest

Request to get information about a snapshot

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the Cloud Platform project that the snapshot belongs to.

=item * C<< $msg->snapshot_id() >> / C<< $msg->snapshot_id($value) >>

Type: C<String>

The ID of the snapshot.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The location that contains this snapshot.

=back

=head2 Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotRequest

Request to delete a snapshot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the Cloud Platform project that the snapshot belongs to.

=item * C<< $msg->snapshot_id() >> / C<< $msg->snapshot_id($value) >>

Type: C<String>

The ID of the snapshot.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The location that contains this snapshot.

=back

=head2 Google::Dataflow::V1beta3::Snapshots::DeleteSnapshotResponse

Response from deleting a snapshot.

Inherits from L<Protobuf::Message>.

=head2 Google::Dataflow::V1beta3::Snapshots::ListSnapshotsRequest

Request to list snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The project ID to list snapshots for.

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

If specified, list snapshots created from this job.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

The location to list snapshots in.

=back

=head2 Google::Dataflow::V1beta3::Snapshots::ListSnapshotsResponse

List of snapshots.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->snapshots() >> / C<< $msg->snapshots($value) >>

Type: C<Message> (L<Google::Dataflow::V1beta3::Snapshots::Snapshot>)

Returned snapshots.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Dataflow::V1beta3::Snapshots::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
