package Google::Cloud::Oracledatabase::V1::FlexComponent;

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
    eval { require Google::Cloud::Oracledatabase::V1::Common };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZmxleF9jb21wb25lbnQucHJvdG8S
Hmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxorZ29vZ2xlL2Nsb3VkL29y
YWNsZWRhdGFiYXNlL3YxL2NvbW1vbi5wcm90byKiAgoNRmxleENvbXBvbmVudBIXCgRuYW1l
GAEgASgJQgPgQQhSBG5hbWUSXAoKcHJvcGVydGllcxgCIAEoCzI3Lmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MS5GbGV4Q29tcG9uZW50UHJvcGVydGllc0ID4EEDUgpwcm9wZXJ0
aWVzOpkB6kGVAQorb3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5jb20vRmxleENvbXBvbmVu
dBJHcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2ZsZXhDb21wb25l
bnRzL3tmbGV4X2NvbXBvbmVudH0qDmZsZXhDb21wb25lbnRzMg1mbGV4Q29tcG9uZW50IokG
ChdGbGV4Q29tcG9uZW50UHJvcGVydGllcxIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSbgoN
aGFyZHdhcmVfdHlwZRgCIAEoDjJELmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5G
bGV4Q29tcG9uZW50UHJvcGVydGllcy5IYXJkd2FyZVR5cGVCA+BBA1IMaGFyZHdhcmVUeXBl
EhkKBXNoYXBlGAMgASgJQgPgQQNSBXNoYXBlEjUKFGF2YWlsYWJsZV9jb3JlX2NvdW50GAQg
ASgFQgPgQQNSEmF2YWlsYWJsZUNvcmVDb3VudBIzChNhdmFpbGFibGVfbWVtb3J5X2diGAUg
ASgFQgPgQQNSEWF2YWlsYWJsZU1lbW9yeUdiEkAKGmF2YWlsYWJsZV9sb2NhbF9zdG9yYWdl
X2diGAYgASgFQgPgQQNSF2F2YWlsYWJsZUxvY2FsU3RvcmFnZUdiElMKJWF2YWlsYWJsZV9k
Yl9ub2RlX3N0b3JhZ2VfcGVyX25vZGVfZ2IYByABKAVCA+BBA1IfYXZhaWxhYmxlRGJOb2Rl
U3RvcmFnZVBlck5vZGVHYhIxChJtaW5pbXVtX2NvcmVfY291bnQYCCABKAVCA+BBA1IQbWlu
aW11bUNvcmVDb3VudBJAChpydW50aW1lX21pbmltdW1fY29yZV9jb3VudBgJIAEoBUID4EED
UhdydW50aW1lTWluaW11bUNvcmVDb3VudBI0ChNkZXNjcmlwdGlvbl9zdW1tYXJ5GAogASgJ
QgPgQQNSEmRlc2NyaXB0aW9uU3VtbWFyeRJWCg1jb21wdXRlX21vZGVsGAsgASgOMiwuZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNvbXB1dGVNb2RlbEID4EEDUgxjb21wdXRl
TW9kZWwiRAoMSGFyZHdhcmVUeXBlEh0KGUhBUkRXQVJFX1RZUEVfVU5TUEVDSUZJRUQQABIL
CgdDT01QVVRFEAESCAoEQ0VMTBACIssBChlMaXN0RmxleENvbXBvbmVudHNSZXF1ZXN0EksK
BnBhcmVudBgBIAEoCUIz4EEC+kEtEitvcmFjbGVkYXRhYmFzZS5nb29nbGVhcGlzLmNvbS9G
bGV4Q29tcG9uZW50UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXpl
EiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID
4EEBUgZmaWx0ZXIiwwEKGkxpc3RGbGV4Q29tcG9uZW50c1Jlc3BvbnNlElYKD2ZsZXhfY29t
cG9uZW50cxgBIAMoCzItLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5GbGV4Q29t
cG9uZW50Ug5mbGV4Q29tcG9uZW50cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4SJQoLdW5yZWFjaGFibGUYAyADKAlCA+BBBlILdW5yZWFjaGFibGVC7AEKImNv
bS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjFCEkZsZXhDb21wb25lbnRQcm90b1AB
WkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFi
YXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5W
McoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9y
YWNsZURhdGFiYXNlOjpWMUrZJgoHEgUOAI4BAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
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
TGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQANQoI
CgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAGEKCQoCCAsSAxcAYQoICgEIEgMYACIKCQoC
CAoSAxgAIgoICgEIEgMZADMKCQoCCAgSAxkAMwoICgEIEgMaADsKCQoCCAESAxoAOwoICgEI
EgMbADsKCQoCCCkSAxsAOwoICgEIEgMcADoKCQoCCC0SAxwAOgo1CgIEABIEHwAvARopIERl
dGFpbHMgb2YgdGhlIEZsZXggQ29tcG9uZW50IHJlc291cmNlLgoKCgoDBAABEgMfCBUKCwoD
BAAHEgQgAiUECg0KBQQAB50IEgQgAiUECqYBCgQEAAIAEgMqAj0amAEgSWRlbnRpZmllci4g
U3BlY2lmaWVzIHRoZSBuYW1lIG9mIHRoZSBGbGV4IENvbXBvbmVudCByZXNvdXJjZSB3aXRo
IHRoZQogZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVnaW9ufS9m
bGV4Q29tcG9uZW50cy97ZmxleF9jb21wb25lbnR9CgoMCgUEAAIABRIDKgIICgwKBQQAAgAB
EgMqCQ0KDAoFBAACAAMSAyoQEQoMCgUEAAIACBIDKhI8Cg8KCAQAAgAInAgAEgMqEzsKQgoE
BAACARIELQIuMho0IE91dHB1dCBvbmx5LiBUaGUgcHJvcGVydGllcyBvZiB0aGUgRmxleCBD
b21wb25lbnQuCgoMCgUEAAIBBhIDLQIZCgwKBQQAAgEBEgMtGiQKDAoFBAACAQMSAy0nKAoM
CgUEAAIBCBIDLgYxCg8KCAQAAgEInAgAEgMuBzAKMwoCBAESBDIAaQEaJyBUaGUgcHJvcGVy
dGllcyBvZiB0aGUgRmxleCBDb21wb25lbnQuCgoKCgMEAQESAzIIHwohCgQEAQQAEgQ0Aj0D
GhMgSGFyZHdhcmVUeXBlIGVudW0KCgwKBQQBBAABEgM0BxMKJAoGBAEEAAIAEgM2BCIaFSBV
bnNwZWNpZmllZCBkZWZhdWx0CgoOCgcEAQQAAgABEgM2BB0KDgoHBAEEAAIAAhIDNiAhChgK
BgQBBAACARIDOQQQGgkgQ09NUFVURQoKDgoHBAEEAAIBARIDOQQLCg4KBwQBBAACAQISAzkO
DwoVCgYEAQQAAgISAzwEDRoGIENFTEwKCg4KBwQBBAACAgESAzwECAoOCgcEAQQAAgICEgM8
CwwKUgoEBAECABIDQAI+GkUgT3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBGbGV4IENv
bXBvbmVudCB1c2VkIGZvciB0aGUgREIgc3lzdGVtLgoKDAoFBAECAAUSA0ACCAoMCgUEAQIA
ARIDQAkNCgwKBQQBAgADEgNAEBEKDAoFBAECAAgSA0ASPQoPCggEAQIACJwIABIDQBM8CnQK
BAQBAgESA0QCTRpnIE91dHB1dCBvbmx5LiBUaGUgaGFyZHdhcmUgdHlwZSBvZiB0aGUgREIg
KENvbXB1dGUpIG9yIFN0b3JhZ2UgKENlbGwpIFNlcnZlcgogZm9yIHRoaXMgRmxleCBDb21w
b25lbnQuCgoMCgUEAQIBBhIDRAIOCgwKBQQBAgEBEgNEDxwKDAoFBAECAQMSA0QfIAoMCgUE
AQIBCBIDRCFMCg8KCAQBAgEInAgAEgNEIksKVAoEBAECAhIDRwI/GkcgT3V0cHV0IG9ubHku
IFRoZSBuYW1lIG9mIHRoZSBEQiBzeXN0ZW0gc2hhcGUgZm9yIHRoaXMgRmxleCBDb21wb25l
bnQuCgoMCgUEAQICBRIDRwIICgwKBQQBAgIBEgNHCQ4KDAoFBAECAgMSA0cREgoMCgUEAQIC
CBIDRxM+Cg8KCAQBAgIInAgAEgNHFD0KcQoEBAECAxIDSwJNGmQgT3V0cHV0IG9ubHkuIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiBDUFUgY29yZXMgdGhhdCBjYW4gYmUgZW5hYmxlZCBvbiB0
aGUgREIKIHN5c3RlbSBmb3IgdGhpcyBzaGFwZS4KCgwKBQQBAgMFEgNLAgcKDAoFBAECAwES
A0sIHAoMCgUEAQIDAxIDSx8gCgwKBQQBAgMIEgNLIUwKDwoIBAECAwicCAASA0siSwpyCgQE
AQIEEgNPAkwaZSBPdXRwdXQgb25seS4gVGhlIG1heGltdW0gbWVtb3J5IHNpemUgdGhhdCBj
YW4gYmUgZW5hYmxlZCBvbiB0aGUgREIgU2VydmVyCiBmb3IgdGhpcyBGbGV4IENvbXBvbmVu
dC4KCgwKBQQBAgQFEgNPAgcKDAoFBAECBAESA08IGwoMCgUEAQIEAxIDTx4fCgwKBQQBAgQI
EgNPIEsKDwoIBAECBAicCAASA08hSgp1CgQEAQIFEgRTAlQyGmcgT3V0cHV0IG9ubHkuIFRo
ZSBtYXhpbXVtIGxvY2FsIHN0b3JhZ2UgdGhhdCBjYW4gYmUgZW5hYmxlZCBvbiB0aGUgREIg
U2VydmVyCiBmb3IgdGhpcyBGbGV4IENvbXBvbmVudC4KCgwKBQQBAgUFEgNTAgcKDAoFBAEC
BQESA1MIIgoMCgUEAQIFAxIDUyUmCgwKBQQBAgUIEgNUBjEKDwoIBAECBQicCAASA1QHMAp0
CgQEAQIGEgRYAlkyGmYgT3V0cHV0IG9ubHkuIFRoZSBtYXhpbXVtIHN0b3JhZ2UgdGhhdCBj
YW4gYmUgZW5hYmxlZCBvbiB0aGUgU3RvcmFnZSBTZXJ2ZXIKIGZvciB0aGlzIEZsZXggQ29t
cG9uZW50LgoKDAoFBAECBgUSA1gCBwoMCgUEAQIGARIDWAgtCgwKBQQBAgYDEgNYMDEKDAoF
BAECBggSA1kGMQoPCggEAQIGCJwIABIDWQcwCnoKBAQBAgcSA10CSxptIE91dHB1dCBvbmx5
LiBUaGUgbWluaW11bSBudW1iZXIgb2YgQ1BVIGNvcmVzIHRoYXQgY2FuIGJlIGVuYWJsZWQg
b24gdGhlIERCCiBTZXJ2ZXIgZm9yIHRoaXMgRmxleCBDb21wb25lbnQuCgoMCgUEAQIHBRID
XQIHCgwKBQQBAgcBEgNdCBoKDAoFBAECBwMSA10dHgoMCgUEAQIHCBIDXR9KCg8KCAQBAgcI
nAgAEgNdIEkKcgoEBAECCBIEYQJiMhpkIE91dHB1dCBvbmx5LiBUaGUgcnVudGltZSBtaW5p
bXVtIG51bWJlciBvZiBDUFUgY29yZXMgdGhhdCBjYW4gYmUgZW5hYmxlZAogZm9yIHRoaXMg
RmxleCBDb21wb25lbnQuCgoMCgUEAQIIBRIDYQIHCgwKBQQBAggBEgNhCCIKDAoFBAECCAMS
A2ElJgoMCgUEAQIICBIDYgYxCg8KCAQBAggInAgAEgNiBzAKTAoEBAECCRIDZQJOGj8gT3V0
cHV0IG9ubHkuIFRoZSBkZXNjcmlwdGlvbiBzdW1tYXJ5IGZvciB0aGlzIEZsZXggQ29tcG9u
ZW50LgoKDAoFBAECCQUSA2UCCAoMCgUEAQIJARIDZQkcCgwKBQQBAgkDEgNlHyEKDAoFBAEC
CQgSA2UiTQoPCggEAQIJCJwIABIDZSNMClcKBAQBAgoSA2gCThpKIE91dHB1dCBvbmx5LiBU
aGUgY29tcHV0ZSBtb2RlbCBvZiB0aGUgREIgU2VydmVyIGZvciB0aGlzIEZsZXggQ29tcG9u
ZW50LgoKDAoFBAECCgYSA2gCDgoMCgUEAQIKARIDaA8cCgwKBQQBAgoDEgNoHyEKDAoFBAEC
CggSA2giTQoPCggEAQIKCJwIABIDaCNMCjIKAgQCEgVsAIABARolIE1lc3NhZ2UgZm9yIGxp
c3RpbmcgRmxleENvbXBvbmVudHMuCgoKCgMEAgESA2wIIQp1CgQEAgIAEgRvAnQEGmcgUmVx
dWlyZWQuIFBhcmVudCB2YWx1ZSBmb3IgTGlzdEZsZXhDb21wb25lbnRzUmVxdWVzdAogRm9y
bWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCgwKBQQCAgAF
EgNvAggKDAoFBAICAAESA28JDwoMCgUEAgIAAxIDbxITCg0KBQQCAgAIEgRvFHQDCg8KCAQC
AgAInAgAEgNwBCoKDwoHBAICAAifCBIEcQRzBQqWAQoEBAICARIDeAI/GogBIE9wdGlvbmFs
LiBSZXF1ZXN0ZWQgcGFnZSBzaXplLiBTZXJ2ZXIgbWF5IHJldHVybiBmZXdlciBpdGVtcyB0
aGFuCiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lmaWVkLCBzZXJ2ZXIgd2lsbCBwaWNrIGFuIGFw
cHJvcHJpYXRlIGRlZmF1bHQuCgoMCgUEAgIBBRIDeAIHCgwKBQQCAgEBEgN4CBEKDAoFBAIC
AQMSA3gUFQoMCgUEAgIBCBIDeBY+Cg8KCAQCAgEInAgAEgN4Fz0KWAoEBAICAhIDewJBGksg
T3B0aW9uYWwuIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdGhlIHNl
cnZlciBzaG91bGQgcmV0dXJuLgoKDAoFBAICAgUSA3sCCAoMCgUEAgICARIDewkTCgwKBQQC
AgIDEgN7FhcKDAoFBAICAggSA3sYQAoPCggEAgICCJwIABIDexk/CqIBCgQEAgIDEgN/Aj0a
lAEgT3B0aW9uYWwuIEFuIGV4cHJlc3Npb24gZm9yIGZpbHRlcmluZyB0aGUgcmVzdWx0cyBv
ZiB0aGUgcmVxdWVzdC4gT25seSB0aGUKIGBzaGFwZWAgZmllbGQgaXMgc3VwcG9ydGVkIGlu
IHRoZSBmb2xsb3dpbmcgZm9ybWF0OiBgc2hhcGU9IntzaGFwZX0iYC4KCgwKBQQCAgMFEgN/
AggKDAoFBAICAwESA38JDwoMCgUEAgIDAxIDfxITCgwKBQQCAgMIEgN/FDwKDwoIBAICAwic
CAASA38VOwo+CgIEAxIGgwEAjgEBGjAgTWVzc2FnZSBmb3IgcmVzcG9uc2UgdG8gbGlzdGlu
ZyBGbGV4Q29tcG9uZW50cwoKCwoDBAMBEgSDAQgiCikKBAQDAgASBIUBAi0aGyBUaGUgbGlz
dCBvZiBGbGV4Q29tcG9uZW50CgoNCgUEAwIABBIEhQECCgoNCgUEAwIABhIEhQELGAoNCgUE
AwIAARIEhQEZKAoNCgUEAwIAAxIEhQErLAqQAQoEBAMCARIEiQECHRqBASBBIHRva2VuLCB3
aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQg
cGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVl
bnQgcGFnZXMuCgoNCgUEAwIBBRIEiQECCAoNCgUEAwIBARIEiQEJGAoNCgUEAwIBAxIEiQEb
HApGCgQEAwICEgaMAQKNATUaNiBVbm9yZGVyZWQgbGlzdC4gTG9jYXRpb25zIHRoYXQgY291
bGQgbm90IGJlIHJlYWNoZWQuCgoNCgUEAwICBBIEjAECCgoNCgUEAwICBRIEjAELEQoNCgUE
AwICARIEjAESHQoNCgUEAwICAxIEjAEgIQoNCgUEAwICCBIEjQEGNAoQCggEAwICCJwIABIE
jQEHM2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent ===
    # Fields for FlexComponent
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.FlexComponentProperties)

# === Message: Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties ===
    # Fields for FlexComponentProperties
    # Field: name Type: 9 ()
    # Field: hardware_type Type: 14 (.google.cloud.oracledatabase.v1.FlexComponentProperties.HardwareType)
    # Field: shape Type: 9 ()
    # Field: available_core_count Type: 5 ()
    # Field: available_memory_gb Type: 5 ()
    # Field: available_local_storage_gb Type: 5 ()
    # Field: available_db_node_storage_per_node_gb Type: 5 ()
    # Field: minimum_core_count Type: 5 ()
    # Field: runtime_minimum_core_count Type: 5 ()
    # Field: description_summary Type: 9 ()
    # Field: compute_model Type: 14 (.google.cloud.oracledatabase.v1.ComputeModel)

# Enum: FlexComponentProperties::HardwareType
our $FlexComponentProperties_HARDWARE_TYPE_UNSPECIFIED = 0;
our $FlexComponentProperties_COMPUTE = 1;
our $FlexComponentProperties_CELL = 2;

# === Message: Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsRequest ===
    # Fields for ListFlexComponentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsResponse ===
    # Fields for ListFlexComponentsResponse
    # Field: flex_components Type: 11 (.google.cloud.oracledatabase.v1.FlexComponent)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::FlexComponent - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/flex_component.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::FlexComponent;

    my $msg = Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent->new({
        name => $name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/flex_component.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent

Details of the Flex Component resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Specifies the name of the Flex Component resource with the
format:
projects/{project}/locations/{region}/flexComponents/{flex_component}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties>)

Output only. The properties of the Flex Component.

=back

=head2 Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties

The properties of the Flex Component.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the Flex Component used for the DB system.

=item * C<< $msg->hardware_type() >> / C<< $msg->hardware_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::FlexComponentProperties::HardwareType>)

Output only. The hardware type of the DB (Compute) or Storage (Cell) Server
for this Flex Component.

=item * C<< $msg->shape() >> / C<< $msg->shape($value) >>

Type: C<String>

Output only. The name of the DB system shape for this Flex Component.

=item * C<< $msg->available_core_count() >> / C<< $msg->available_core_count($value) >>

Type: C<Int32>

Output only. The maximum number of CPU cores that can be enabled on the DB
system for this shape.

=item * C<< $msg->available_memory_gb() >> / C<< $msg->available_memory_gb($value) >>

Type: C<Int32>

Output only. The maximum memory size that can be enabled on the DB Server
for this Flex Component.

=item * C<< $msg->available_local_storage_gb() >> / C<< $msg->available_local_storage_gb($value) >>

Type: C<Int32>

Output only. The maximum local storage that can be enabled on the DB Server
for this Flex Component.

=item * C<< $msg->available_db_node_storage_per_node_gb() >> / C<< $msg->available_db_node_storage_per_node_gb($value) >>

Type: C<Int32>

Output only. The maximum storage that can be enabled on the Storage Server
for this Flex Component.

=item * C<< $msg->minimum_core_count() >> / C<< $msg->minimum_core_count($value) >>

Type: C<Int32>

Output only. The minimum number of CPU cores that can be enabled on the DB
Server for this Flex Component.

=item * C<< $msg->runtime_minimum_core_count() >> / C<< $msg->runtime_minimum_core_count($value) >>

Type: C<Int32>

Output only. The runtime minimum number of CPU cores that can be enabled
for this Flex Component.

=item * C<< $msg->description_summary() >> / C<< $msg->description_summary($value) >>

Type: C<String>

Output only. The description summary for this Flex Component.

=item * C<< $msg->compute_model() >> / C<< $msg->compute_model($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ComputeModel>)

Output only. The compute model of the DB Server for this Flex Component.

=back

=head3 Enum: FlexComponentProperties::HardwareType

=over 4

=item * C<HARDWARE_TYPE_UNSPECIFIED> => C<0>

=item * C<COMPUTE> => C<1>

=item * C<CELL> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsRequest

Message for listing FlexComponents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListFlexComponentsRequest
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Only the
`shape` field is supported in the following format: `shape="{shape}"`.

=back

=head2 Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsResponse

Message for response to listing FlexComponents

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->flex_components() >> / C<< $msg->flex_components($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent>)

The list of FlexComponent

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::FlexComponent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
