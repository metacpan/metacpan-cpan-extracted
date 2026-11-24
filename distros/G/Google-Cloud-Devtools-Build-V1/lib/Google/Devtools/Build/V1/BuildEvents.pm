package Google::Devtools::Build::V1::BuildEvents;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Devtools::Build::V1::BuildStatus };
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvYnVpbGQvdjEvYnVpbGRfZXZlbnRzLnByb3RvEhhnb29nbGUu
ZGV2dG9vbHMuYnVpbGQudjEaK2dvb2dsZS9kZXZ0b29scy9idWlsZC92MS9idWlsZF9zdGF0
dXMucHJvdG8aGWdvb2dsZS9wcm90b2J1Zi9hbnkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8i/Q0KCkJ1aWxkRXZlbnQSOQoKZXZlbnRfdGltZRgBIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWV2ZW50VGltZRJ9ChppbnZvY2F0aW9uX2F0dGVt
cHRfc3RhcnRlZBgzIAEoCzI9Lmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5CdWlsZEV2ZW50
Lkludm9jYXRpb25BdHRlbXB0U3RhcnRlZEgAUhhpbnZvY2F0aW9uQXR0ZW1wdFN0YXJ0ZWQS
gAEKG2ludm9jYXRpb25fYXR0ZW1wdF9maW5pc2hlZBg0IAEoCzI+Lmdvb2dsZS5kZXZ0b29s
cy5idWlsZC52MS5CdWlsZEV2ZW50Lkludm9jYXRpb25BdHRlbXB0RmluaXNoZWRIAFIZaW52
b2NhdGlvbkF0dGVtcHRGaW5pc2hlZBJbCg5idWlsZF9lbnF1ZXVlZBg1IAEoCzIyLmdvb2ds
ZS5kZXZ0b29scy5idWlsZC52MS5CdWlsZEV2ZW50LkJ1aWxkRW5xdWV1ZWRIAFINYnVpbGRF
bnF1ZXVlZBJbCg5idWlsZF9maW5pc2hlZBg3IAEoCzIyLmdvb2dsZS5kZXZ0b29scy5idWls
ZC52MS5CdWlsZEV2ZW50LkJ1aWxkRmluaXNoZWRIAFINYnVpbGRGaW5pc2hlZBJbCg5jb25z
b2xlX291dHB1dBg4IAEoCzIyLmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5CdWlsZEV2ZW50
LkNvbnNvbGVPdXRwdXRIAFINY29uc29sZU91dHB1dBJ/Chljb21wb25lbnRfc3RyZWFtX2Zp
bmlzaGVkGDsgASgLMkEuZ29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxLkJ1aWxkRXZlbnQuQnVp
bGRDb21wb25lbnRTdHJlYW1GaW5pc2hlZEgAUhdjb21wb25lbnRTdHJlYW1GaW5pc2hlZBI3
CgtiYXplbF9ldmVudBg8IAEoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlIAFIKYmF6ZWxFdmVu
dBJKChVidWlsZF9leGVjdXRpb25fZXZlbnQYPSABKAsyFC5nb29nbGUucHJvdG9idWYuQW55
SABSE2J1aWxkRXhlY3V0aW9uRXZlbnQSRAoSc291cmNlX2ZldGNoX2V2ZW50GD4gASgLMhQu
Z29vZ2xlLnByb3RvYnVmLkFueUgAUhBzb3VyY2VGZXRjaEV2ZW50GnEKGEludm9jYXRpb25B
dHRlbXB0U3RhcnRlZBIlCg5hdHRlbXB0X251bWJlchgBIAEoA1INYXR0ZW1wdE51bWJlchIu
CgdkZXRhaWxzGAIgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueVIHZGV0YWlscxqfAQoZSW52
b2NhdGlvbkF0dGVtcHRGaW5pc2hlZBJSChFpbnZvY2F0aW9uX3N0YXR1cxgDIAEoCzIlLmdv
b2dsZS5kZXZ0b29scy5idWlsZC52MS5CdWlsZFN0YXR1c1IQaW52b2NhdGlvblN0YXR1cxIu
CgdkZXRhaWxzGAQgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueVIHZGV0YWlscxo/Cg1CdWls
ZEVucXVldWVkEi4KB2RldGFpbHMYASABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgdkZXRh
aWxzGn4KDUJ1aWxkRmluaXNoZWQSPQoGc3RhdHVzGAEgASgLMiUuZ29vZ2xlLmRldnRvb2xz
LmJ1aWxkLnYxLkJ1aWxkU3RhdHVzUgZzdGF0dXMSLgoHZGV0YWlscxgCIAEoCzIULmdvb2ds
ZS5wcm90b2J1Zi5BbnlSB2RldGFpbHMapgEKDUNvbnNvbGVPdXRwdXQSQQoEdHlwZRgBIAEo
DjItLmdvb2dsZS5kZXZ0b29scy5idWlsZC52MS5Db25zb2xlT3V0cHV0U3RyZWFtUgR0eXBl
EiEKC3RleHRfb3V0cHV0GAIgASgJSABSCnRleHRPdXRwdXQSJQoNYmluYXJ5X291dHB1dBgD
IAEoDEgAUgxiaW5hcnlPdXRwdXRCCAoGb3V0cHV0GsYBChxCdWlsZENvbXBvbmVudFN0cmVh
bUZpbmlzaGVkEmAKBHR5cGUYASABKA4yTC5nb29nbGUuZGV2dG9vbHMuYnVpbGQudjEuQnVp
bGRFdmVudC5CdWlsZENvbXBvbmVudFN0cmVhbUZpbmlzaGVkLkZpbmlzaFR5cGVSBHR5cGUi
RAoKRmluaXNoVHlwZRIbChdGSU5JU0hfVFlQRV9VTlNQRUNJRklFRBAAEgwKCEZJTklTSEVE
EAESCwoHRVhQSVJFRBACQgcKBWV2ZW50IuoBCghTdHJlYW1JZBIZCghidWlsZF9pZBgBIAEo
CVIHYnVpbGRJZBIjCg1pbnZvY2F0aW9uX2lkGAYgASgJUgxpbnZvY2F0aW9uSWQSTwoJY29t
cG9uZW50GAMgASgOMjEuZ29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxLlN0cmVhbUlkLkJ1aWxk
Q29tcG9uZW50Ugljb21wb25lbnQiTQoOQnVpbGRDb21wb25lbnQSFQoRVU5LTk9XTl9DT01Q
T05FTlQQABIOCgpDT05UUk9MTEVSEAESCgoGV09SS0VSEAISCAoEVE9PTBADKjoKE0NvbnNv
bGVPdXRwdXRTdHJlYW0SCwoHVU5LTk9XThAAEgoKBlNURE9VVBABEgoKBlNUREVSUhACQosB
Chxjb20uZ29vZ2xlLmRldnRvb2xzLmJ1aWxkLnYxQg9CdWlsZEV2ZW50UHJvdG9QAVo9Z29v
Z2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9idWlsZC92MTti
dWlsZPgBAcoCFUdvb2dsZVxDbG91ZFxCdWlsZFxWMUqLMgoHEgUOALoBAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgA1CgkKAgMBEgMT
ACMKCQoCAwISAxQAKQoICgEIEgMWAB8KCQoCCB8SAxYAHwoICgEIEgMXAFQKCQoCCAsSAxcA
VAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADAKCQoCCAgSAxkAMAoICgEIEgMaADUK
CQoCCAESAxoANQoICgEIEgMbADIKCQoCCCkSAxsAMgqbAQoCBAASBR8AkQEBGo0BIEFuIGV2
ZW50IHJlcHJlc2VudGluZyBzb21lIHN0YXRlIGNoYW5nZSB0aGF0IG9jY3VycmVkIGluIHRo
ZSBidWlsZC4gVGhpcwogbWVzc2FnZSBkb2VzIG5vdCBpbmNsdWRlIGZpZWxkIGZvciB1bmlx
dWVseSBpZGVudGlmeWluZyBhbiBldmVudC4KCgoKAwQAARIDHwgSClcKBAQAAwASBCECKQMa
SSBOb3RpZmljYXRpb24gdGhhdCB0aGUgYnVpbGQgc3lzdGVtIGhhcyBhdHRlbXB0ZWQgdG8g
cnVuIHRoZSBidWlsZCB0b29sLgoKDAoFBAADAAESAyEKIgrjAQoGBAADAAIAEgMlBB0a0wEg
VGhlIG51bWJlciBvZiB0aGUgaW52b2NhdGlvbiBhdHRlbXB0LCBzdGFydGluZyBhdCAxIGFu
ZCBpbmNyZWFzaW5nIGJ5IDEKIGZvciBlYWNoIG5ldyBhdHRlbXB0LiBDYW4gYmUgdXNlZCB0
byBkZXRlcm1pbmUgaWYgdGhlcmUgaXMgYSBsYXRlcgogaW52b2NhdGlvbiBhdHRlbXB0IHJl
cGxhY2luZyB0aGUgY3VycmVudCBvbmUgYSBjbGllbnQgaXMgcHJvY2Vzc2luZy4KCg4KBwQA
AwACAAUSAyUECQoOCgcEAAMAAgABEgMlChgKDgoHBAADAAIAAxIDJRscCkAKBgQAAwACARID
KAQkGjEgQXJiaXRyYXJ5IGRldGFpbHMgYWJvdXQgdGhlIGludm9jYXRpb24gYXR0ZW1wdC4K
Cg4KBwQAAwACAQYSAygEFwoOCgcEAAMAAgEBEgMoGB8KDgoHBAADAAIBAxIDKCIjCkUKBAQA
AwESBCwCMgMaNyBOb3RpZmljYXRpb24gdGhhdCBhbiBpbnZvY2F0aW9uIGF0dGVtcHQgaGFz
IGZpbmlzaGVkLgoKDAoFBAADAQESAywKIwowCgYEAAMBAgASAy4EJhohIEZpbmFsIHN0YXR1
cyBvZiB0aGUgaW52b2NhdGlvbi4KCg4KBwQAAwECAAYSAy4EDwoOCgcEAAMBAgABEgMuECEK
DgoHBAADAQIAAxIDLiQlCkAKBgQAAwECARIDMQQkGjEgQXJiaXRyYXJ5IGRldGFpbHMgYWJv
dXQgdGhlIGludm9jYXRpb24gYXR0ZW1wdC4KCg4KBwQAAwECAQYSAzEEFwoOCgcEAAMBAgEB
EgMxGB8KDgoHBAADAQIBAxIDMSIjCkAKBAQAAwISBDUCOAMaMiBOb3RpZmljYXRpb24gdGhh
dCB0aGUgYnVpbGQgcmVxdWVzdCBpcyBlbnF1ZXVlZC4KCgwKBQQAAwIBEgM1ChcKNAoGBAAD
AgIAEgM3BCQaJSBBZGRpdGlvbmFsIGRldGFpbHMgYWJvdXQgdGhlIEJ1aWxkLgoKDgoHBAAD
AgIABhIDNwQXCg4KBwQAAwICAAESAzcYHwoOCgcEAAMCAgADEgM3IiMK3AEKBAQAAwMSBD0C
QwMazQEgTm90aWZpY2F0aW9uIHRoYXQgdGhlIGJ1aWxkIHJlcXVlc3QgaGFzIGZpbmlzaGVk
LCBhbmQgbm8gZnVydGhlcgogaW52b2NhdGlvbnMgd2lsbCBvY2N1ci4gIE5vdGUgdGhhdCB0
aGlzIGFwcGxpZXMgdG8gdGhlIGVudGlyZSBCdWlsZC4KIEluZGl2aWR1YWwgaW52b2NhdGlv
bnMgdHJpZ2dlciBJbnZvY2F0aW9uRmluaXNoZWQgd2hlbiB0aGV5IGZpbmlzaC4KCgwKBQQA
AwMBEgM9ChcKKwoGBAADAwIAEgM/BBsaHCBGaW5hbCBzdGF0dXMgb2YgdGhlIGJ1aWxkLgoK
DgoHBAADAwIABhIDPwQPCg4KBwQAAwMCAAESAz8QFgoOCgcEAAMDAgADEgM/GRoKNAoGBAAD
AwIBEgNCBCQaJSBBZGRpdGlvbmFsIGRldGFpbHMgYWJvdXQgdGhlIEJ1aWxkLgoKDgoHBAAD
AwIBBhIDQgQXCg4KBwQAAwMCAQESA0IYHwoOCgcEAAMDAgEDEgNCIiMKTAoEBAADBBIERgJS
Axo+IFRleHR1YWwgb3V0cHV0IHdyaXR0ZW4gdG8gc3RhbmRhcmQgb3V0cHV0IG9yIHN0YW5k
YXJkIGVycm9yLgoKDAoFBAADBAESA0YKFwooCgYEAAMEAgASA0gEIRoZIFRoZSBvdXRwdXQg
c3RyZWFtIHR5cGUuCgoOCgcEAAMEAgAGEgNIBBcKDgoHBAADBAIAARIDSBgcCg4KBwQAAwQC
AAMSA0gfIAosCgYEAAMECAASBEsEUQUaHCBUaGUgb3V0cHV0IHN0cmVhbSBjb250ZW50LgoK
DgoHBAADBAgAARIDSwoQCjMKBgQAAwQCARIDTQYdGiQgUmVndWxhciBVVEYtOCBvdXRwdXQ7
IG5vcm1hbCB0ZXh0LgoKDgoHBAADBAIBBRIDTQYMCg4KBwQAAwQCAQESA00NGAoOCgcEAAME
AgEDEgNNGxwKVAoGBAADBAICEgNQBh4aRSBVc2VkIGlmIHRoZSBvdXRwdXQgaXMgbm90IFVU
Ri04IHRleHQgKGZvciBleGFtcGxlLCBhIGJpbmFyeSBwcm90bykuCgoOCgcEAAMEAgIFEgNQ
BgsKDgoHBAADBAICARIDUAwZCg4KBwQAAwQCAgMSA1AcHQqWAQoEBAADBRIEVgJoAxqHASBO
b3RpZmljYXRpb24gb2YgdGhlIGVuZCBvZiBhIGJ1aWxkIGV2ZW50IHN0cmVhbSBwdWJsaXNo
ZWQgYnkgYSBidWlsZAogY29tcG9uZW50IG90aGVyIHRoYW4gQ09OVFJPTExFUiAoU2VlIFN0
cmVhbUlkLkJ1aWxkQ29tcG9uZW50cykuCgoMCgUEAAMFARIDVgomCjIKBgQAAwUEABIEWARk
BRoiIEhvdyBkaWQgdGhlIGV2ZW50IHN0cmVhbSBmaW5pc2guCgoOCgcEAAMFBAABEgNYCRMK
TwoIBAADBQQAAgASA1oGIho+IFVua25vd24gb3IgdW5zcGVjaWZpZWQ7IGNhbGxlcnMgc2hv
dWxkIG5ldmVyIHNldCB0aGlzIHZhbHVlLgoKEAoJBAADBQQAAgABEgNaBh0KEAoJBAADBQQA
AgACEgNaICEKXAoIBAADBQQAAgESA14GExpLIFNldCBieSB0aGUgZXZlbnQgcHVibGlzaGVy
IHRvIGluZGljYXRlIGEgYnVpbGQgZXZlbnQgc3RyZWFtIGlzCiBmaW5pc2hlZC4KChAKCQQA
AwUEAAIBARIDXgYOChAKCQQAAwUEAAIBAhIDXhESCs0BCggEAAMFBAACAhIDYwYSGrsBIFNl
dCBieSB0aGUgV2F0Y2hCdWlsZCBSUEMgc2VydmVyIHdoZW4gdGhlIHB1Ymxpc2hlciBvZiBh
IGJ1aWxkIGV2ZW50CiBzdHJlYW0gc3RvcHMgcHVibGlzaGluZyBldmVudHMgd2l0aG91dCBw
dWJsaXNoaW5nIGEKIEJ1aWxkQ29tcG9uZW50U3RyZWFtRmluaXNoZWQgZXZlbnQgd2hvc2Ug
dHlwZSBlcXVhbHMgRklOSVNIRUQuCgoQCgkEAAMFBAACAgESA2MGDQoQCgkEAAMFBAACAgIS
A2MQEQovCgYEAAMFAgASA2cEGBogIEhvdyB0aGUgZXZlbnQgc3RyZWFtIGZpbmlzaGVkLgoK
DgoHBAADBQIABhIDZwQOCg4KBwQAAwUCAAESA2cPEwoOCgcEAAMFAgADEgNnFhcKfQoEBAAC
ABIDbAIrGnAgVGhpcyBzaG91bGQgYmUgcHJlY2lzZWx5IHRoZSB0aW1lIHdoZW4gdGhpcyBl
dmVudCBoYXBwZW5lZCwgYW5kIG5vdCB3aGVuCiB0aGUgZXZlbnQgcHJvdG8gd2FzIGNyZWF0
ZWQgb3Igc2VudC4KCgwKBQQAAgAGEgNsAhsKDAoFBAACAAESA2wcJgoMCgUEAAIAAxIDbCkq
CqkBCgQEAAgAEgVxApABAxqZASAvLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8v
Ly8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLwogRXZlbnRzIHRoYXQg
aW5kaWNhdGUgYSBzdGF0ZSBjaGFuZ2Ugb2YgYSBidWlsZCByZXF1ZXN0IGluIHRoZSBidWls
ZAogcXVldWUuCgoMCgUEAAgAARIDcQgNCjEKBAQAAgESA3MEPRokIEFuIGludm9jYXRpb24g
YXR0ZW1wdCBoYXMgc3RhcnRlZC4KCgwKBQQAAgEGEgNzBBwKDAoFBAACAQESA3MdNwoMCgUE
AAIBAxIDczo8CjIKBAQAAgISA3YEPxolIEFuIGludm9jYXRpb24gYXR0ZW1wdCBoYXMgZmlu
aXNoZWQuCgoMCgUEAAICBhIDdgQdCgwKBQQAAgIBEgN2HjkKDAoFBAACAgMSA3Y8PgolCgQE
AAIDEgN5BCYaGCBUaGUgYnVpbGQgaXMgZW5xdWV1ZWQuCgoMCgUEAAIDBhIDeQQRCgwKBQQA
AgMBEgN5EiAKDAoFBAACAwMSA3kjJQpICgQEAAIEEgN8BCYaOyBUaGUgYnVpbGQgaGFzIGZp
bmlzaGVkLiBTZXQgd2hlbiB0aGUgYnVpbGQgaXMgdGVybWluYXRlZC4KCgwKBQQAAgQGEgN8
BBEKDAoFBAACBAESA3wSIAoMCgUEAAIEAxIDfCMlCjAKBAQAAgUSA38EJhojIEFuIGV2ZW50
IGNvbnRhaW5pbmcgcHJpbnRlZCB0ZXh0LgoKDAoFBAACBQYSA38EEQoMCgUEAAIFARIDfxIg
CgwKBQQAAgUDEgN/IyUK1QEKBAQAAgYSBIQBBEAaxgEgSW5kaWNhdGVzIHRoZSBlbmQgb2Yg
YSBidWlsZCBldmVudCBzdHJlYW0gKHdpdGggdGhlIHNhbWUgU3RyZWFtSWQpIGZyb20KIGEg
YnVpbGQgY29tcG9uZW50IGV4ZWN1dGluZyB0aGUgcmVxdWVzdGVkIGJ1aWxkIHRhc2suCiAq
KiogVGhpcyBmaWVsZCBkb2VzIG5vdCBpbmRpY2F0ZSB0aGUgV2F0Y2hCdWlsZCBSUEMgaXMg
ZmluaXNoZWQuICoqKgoKDQoFBAACBgYSBIQBBCAKDQoFBAACBgESBIQBIToKDQoFBAACBgMS
BIQBPT8KVwoEBAACBxIEhwEEKRpJIFN0cnVjdHVyZWQgYnVpbGQgZXZlbnQgZ2VuZXJhdGVk
IGJ5IEJhemVsIGFib3V0IGl0cyBleGVjdXRpb24gcHJvZ3Jlc3MuCgoNCgUEAAIHBhIEhwEE
FwoNCgUEAAIHARIEhwEYIwoNCgUEAAIHAxIEhwEmKAplCgQEAAIIEgSLAQQzGlcgQW4gZXZl
bnQgdGhhdCBjb250YWlucyBzdXBwbGVtZW50YWwgdG9vbC1zcGVjaWZpYyBpbmZvcm1hdGlv
biBhYm91dAogYnVpbGQgZXhlY3V0aW9uLgoKDQoFBAACCAYSBIsBBBcKDQoFBAACCAESBIsB
GC0KDQoFBAACCAMSBIsBMDIKZQoEBAACCRIEjwEEMBpXIEFuIGV2ZW50IHRoYXQgY29udGFp
bnMgc3VwcGxlbWVudGFsIHRvb2wtc3BlY2lmaWMgaW5mb3JtYXRpb24gYWJvdXQKIHNvdXJj
ZSBmZXRjaGluZy4KCg0KBQQAAgkGEgSPAQQXCg0KBQQAAgkBEgSPARgqCg0KBQQAAgkDEgSP
AS0vCjsKAgQBEgaUAQCuAQEaLSBVbmlxdWUgaWRlbnRpZmllciBmb3IgYSBidWlsZCBldmVu
dCBzdHJlYW0uCgoLCgMEAQESBJQBCBAKeQoEBAEEABIGlwECowEDGmkgV2hpY2ggYnVpbGQg
Y29tcG9uZW50IGdlbmVyYXRlcyB0aGlzIGV2ZW50IHN0cmVhbS4gRWFjaCBidWlsZCBjb21w
b25lbnQKIG1heSBnZW5lcmF0ZSBvbmUgZXZlbnQgc3RyZWFtLgoKDQoFBAEEAAESBJcBBxUK
TgoGBAEEAAIAEgSZAQQaGj4gVW5rbm93biBvciB1bnNwZWNpZmllZDsgY2FsbGVycyBzaG91
bGQgbmV2ZXIgc2V0IHRoaXMgdmFsdWUuCgoPCgcEAQQAAgABEgSZAQQVCg8KBwQBBAACAAIS
BJkBGBkKNgoGBAEEAAIBEgScAQQTGiYgQSBjb21wb25lbnQgdGhhdCBjb29yZGluYXRlcyBi
dWlsZHMuCgoPCgcEAQQAAgEBEgScAQQOCg8KBwQBBAACAQISBJwBERIKTwoGBAEEAAICEgSf
AQQPGj8gQSBjb21wb25lbnQgdGhhdCBydW5zIGV4ZWN1dGFibGVzIG5lZWRlZCB0byBjb21w
bGV0ZSBhIGJ1aWxkLgoKDwoHBAEEAAICARIEnwEECgoPCgcEAQQAAgICEgSfAQ0OCjQKBgQB
BAACAxIEogEEDRokIEEgY29tcG9uZW50IHRoYXQgYnVpbGRzIHNvbWV0aGluZy4KCg8KBwQB
BAACAwESBKIBBAgKDwoHBAEEAAIDAhIEogELDAoqCgQEAQIAEgSmAQIWGhwgVGhlIGlkIG9m
IGEgQnVpbGQgbWVzc2FnZS4KCg0KBQQBAgAFEgSmAQIICg0KBQQBAgABEgSmAQkRCg0KBQQB
AgADEgSmARQVCoABCgQEAQIBEgSqAQIbGnIgVGhlIHVuaXF1ZSBpbnZvY2F0aW9uIElEIHdp
dGhpbiB0aGlzIGJ1aWxkLgogSXQgc2hvdWxkIGJlIHRoZSBzYW1lIGFzIHtpbnZvY2F0aW9u
fSAoYmVsb3cpIGR1cmluZyB0aGUgbWlncmF0aW9uLgoKDQoFBAECAQUSBKoBAggKDQoFBAEC
AQESBKoBCRYKDQoFBAECAQMSBKoBGRoKNgoEBAECAhIErQECHxooIFRoZSBjb21wb25lbnQg
dGhhdCBlbWl0dGVkIHRoaXMgZXZlbnQuCgoNCgUEAQICBhIErQECEAoNCgUEAQICARIErQER
GgoNCgUEAQICAxIErQEdHgoyCgIFABIGsQEAugEBGiQgVGhlIHR5cGUgb2YgY29uc29sZSBv
dXRwdXQgc3RyZWFtLgoKCwoDBQABEgSxAQUYCicKBAUAAgASBLMBAg4aGSBVbnNwZWNpZmll
ZCBvciB1bmtub3duLgoKDQoFBQACAAESBLMBAgkKDQoFBQACAAISBLMBDA0KJQoEBQACARIE
tgECDRoXIE5vcm1hbCBvdXRwdXQgc3RyZWFtLgoKDQoFBQACAQESBLYBAggKDQoFBQACAQIS
BLYBCwwKJAoEBQACAhIEuQECDRoWIEVycm9yIG91dHB1dCBzdHJlYW0uCgoNCgUFAAICARIE
uQECCAoNCgUFAAICAhIEuQELDGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Build::V1::BuildEvents::BuildEvent ===
    # Fields for BuildEvent
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: invocation_attempt_started Type: 11 (.google.devtools.build.v1.BuildEvent.InvocationAttemptStarted)
    # Field: invocation_attempt_finished Type: 11 (.google.devtools.build.v1.BuildEvent.InvocationAttemptFinished)
    # Field: build_enqueued Type: 11 (.google.devtools.build.v1.BuildEvent.BuildEnqueued)
    # Field: build_finished Type: 11 (.google.devtools.build.v1.BuildEvent.BuildFinished)
    # Field: console_output Type: 11 (.google.devtools.build.v1.BuildEvent.ConsoleOutput)
    # Field: component_stream_finished Type: 11 (.google.devtools.build.v1.BuildEvent.BuildComponentStreamFinished)
    # Field: bazel_event Type: 11 (.google.protobuf.Any)
    # Field: build_execution_event Type: 11 (.google.protobuf.Any)
    # Field: source_fetch_event Type: 11 (.google.protobuf.Any)

# === Message: Google::Devtools::Build::V1::BuildEvents::StreamId ===
    # Fields for StreamId
    # Field: build_id Type: 9 ()
    # Field: invocation_id Type: 9 ()
    # Field: component Type: 14 (.google.devtools.build.v1.StreamId.BuildComponent)

# Enum: StreamId::BuildComponent
our $StreamId_UNKNOWN_COMPONENT = 0;
our $StreamId_CONTROLLER = 1;
our $StreamId_WORKER = 2;
our $StreamId_TOOL = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Build::V1::BuildEvents - Compiled Protocol Buffers messages for google/devtools/build/v1/build_events.proto

=head1 SYNOPSIS

    use Google::Devtools::Build::V1::BuildEvents;

    my $msg = Google::Devtools::Build::V1::BuildEvents::BuildEvent->new({
        event_time => $event_time,
        invocation_attempt_started => $invocation_attempt_started,
        invocation_attempt_finished => $invocation_attempt_finished,
        build_enqueued => $build_enqueued,
    });

    # Read or update a field
    my $val = $msg->event_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Build::V1::BuildEvents::BuildEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/build/v1/build_events.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Build::V1::BuildEvents::BuildEvent

An event representing some state change that occurred in the build. This
message does not include field for uniquely identifying an event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

This should be precisely the time when this event happened, and not when
the event proto was created or sent.

=item * C<< $msg->invocation_attempt_started() >> / C<< $msg->invocation_attempt_started($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptStarted>)

An invocation attempt has started.

=item * C<< $msg->invocation_attempt_finished() >> / C<< $msg->invocation_attempt_finished($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::InvocationAttemptFinished>)

An invocation attempt has finished.

=item * C<< $msg->build_enqueued() >> / C<< $msg->build_enqueued($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildEnqueued>)

The build is enqueued.

=item * C<< $msg->build_finished() >> / C<< $msg->build_finished($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildFinished>)

The build has finished. Set when the build is terminated.

=item * C<< $msg->console_output() >> / C<< $msg->console_output($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::ConsoleOutput>)

An event containing printed text.

=item * C<< $msg->component_stream_finished() >> / C<< $msg->component_stream_finished($value) >>

Type: C<Message> (L<Google::Devtools::Build::V1::BuildEvents::BuildEvent::BuildComponentStreamFinished>)

Indicates the end of a build event stream (with the same StreamId) from
a build component executing the requested build task.
B<* This field does not indicate the WatchBuild RPC is finished. >*

=item * C<< $msg->bazel_event() >> / C<< $msg->bazel_event($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

Structured build event generated by Bazel about its execution progress.

=item * C<< $msg->build_execution_event() >> / C<< $msg->build_execution_event($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

An event that contains supplemental tool-specific information about
build execution.

=item * C<< $msg->source_fetch_event() >> / C<< $msg->source_fetch_event($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

An event that contains supplemental tool-specific information about
source fetching.

=back

=head2 Google::Devtools::Build::V1::BuildEvents::StreamId

Unique identifier for a build event stream.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->build_id() >> / C<< $msg->build_id($value) >>

Type: C<String>

The id of a Build message.

=item * C<< $msg->invocation_id() >> / C<< $msg->invocation_id($value) >>

Type: C<String>

The unique invocation ID within this build.
It should be the same as {invocation} (below) during the migration.

=item * C<< $msg->component() >> / C<< $msg->component($value) >>

Type: C<Enum> (L<Google::Devtools::Build::V1::StreamId::BuildComponent>)

The component that emitted this event.

=back

=head3 Enum: StreamId::BuildComponent

=over 4

=item * C<UNKNOWN_COMPONENT> => C<0>

=item * C<CONTROLLER> => C<1>

=item * C<WORKER> => C<2>

=item * C<TOOL> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Build::V1::BuildEvents::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
