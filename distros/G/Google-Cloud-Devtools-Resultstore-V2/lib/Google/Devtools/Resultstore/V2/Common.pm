package Google::Devtools::Resultstore::V2::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY29tbW9uLnByb3RvEh5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byJ0ChBTdGF0dXNBdHRyaWJ1dGVzEj4KBnN0YXR1cxgBIAEoDjImLmdv
b2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5TdGF0dXNSBnN0YXR1cxIgCgtkZXNjcmlw
dGlvbhgCIAEoCVILZGVzY3JpcHRpb24iMgoIUHJvcGVydHkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlInoKBlRpbWluZxI5CgpzdGFydF90aW1lGAEgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGR1cmF0aW9uGAIgASgL
MhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUghkdXJhdGlvbiLKAgoKRGVwZW5kZW5jeRId
CgZ0YXJnZXQYASABKAlCA+BBA0gAUgZ0YXJnZXQSMgoRY29uZmlndXJlZF90YXJnZXQYAiAB
KAlCA+BBA0gAUhBjb25maWd1cmVkVGFyZ2V0Eh0KBmFjdGlvbhgDIAEoCUID4EEDSABSBmFj
dGlvbhI9CgJpZBgFIAEoCzItLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52Mi5EZXBl
bmRlbmN5LklkUgJpZBIUCgVsYWJlbBgEIAEoCVIFbGFiZWwaaQoCSWQSGwoJdGFyZ2V0X2lk
GAIgASgJUgh0YXJnZXRJZBIpChBjb25maWd1cmF0aW9uX2lkGAMgASgJUg9jb25maWd1cmF0
aW9uSWQSGwoJYWN0aW9uX2lkGAQgASgJUghhY3Rpb25JZEIKCghyZXNvdXJjZSrtAQoITGFu
Z3VhZ2USGAoUTEFOR1VBR0VfVU5TUEVDSUZJRUQQABIICgROT05FEAESCwoHQU5EUk9JRBAC
EgYKAkFTEAMSBgoCQ0MQBBIHCgNDU1MQBRIICgREQVJUEAYSBgoCR08QBxIHCgNHV1QQCBIL
CgdIQVNLRUxMEAkSCAoESkFWQRAKEgYKAkpTEAsSCAoETElTUBAMEggKBE9CSkMQDRIGCgJQ
WRAOEgYKAlNIEA8SCQoFU1dJRlQQEBIGCgJUUxASEgcKA1dFQhATEgkKBVNDQUxBEBQSCQoF
UFJPVE8QFRIHCgNYTUwQFirXAQoGU3RhdHVzEhYKElNUQVRVU19VTlNQRUNJRklFRBAAEgwK
CEJVSUxESU5HEAESCQoFQlVJTFQQAhITCg9GQUlMRURfVE9fQlVJTEQQAxILCgdURVNUSU5H
EAQSCgoGUEFTU0VEEAUSCgoGRkFJTEVEEAYSDQoJVElNRURfT1VUEAcSDQoJQ0FOQ0VMTEVE
EAgSDwoLVE9PTF9GQUlMRUQQCRIOCgpJTkNPTVBMRVRFEAoSCQoFRkxBS1kQCxILCgdVTktO
T1dOEAwSCwoHU0tJUFBFRBANKmAKDFVwbG9hZFN0YXR1cxIdChlVUExPQURfU1RBVFVTX1VO
U1BFQ0lGSUVEEAASDQoJVVBMT0FESU5HEAESEwoPUE9TVF9QUk9DRVNTSU5HEAISDQoJSU1N
VVRBQkxFEANCfgoiY29tLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9yZS52MkILQ29tbW9u
UHJvdG9QAVpJZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29s
cy9yZXN1bHRzdG9yZS92MjtyZXN1bHRzdG9yZUqrPgoHEgUOAPMBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACgK
CQoCAwISAxQAKQoICgEIEgMWAGAKCQoCCAsSAxYAYAoICgEIEgMXACIKCQoCCAoSAxcAIgoI
CgEIEgMYACwKCQoCCAgSAxgALAoICgEIEgMZADsKCQoCCAESAxkAOwqkAQoCBAASBB4AJAEa
lwEgRGVzY3JpYmVzIHRoZSBzdGF0dXMgb2YgYSByZXNvdXJjZSBpbiBib3RoIGVudW0gYW5k
IHN0cmluZyBmb3JtLgogT25seSB1c2UgZGVzY3JpcHRpb24gd2hlbiBjb252ZXlpbmcgYWRk
aXRpb25hbCBpbmZvIG5vdCBjYXB0dXJlZCBpbiB0aGUgZW51bQogbmFtZS4KCgoKAwQAARID
HggYCjEKBAQAAgASAyACFBokIEVudW0gcmVwcmVzZW50YXRpb24gb2YgdGhlIHN0YXR1cy4K
CgwKBQQAAgAGEgMgAggKDAoFBAACAAESAyAJDwoMCgUEAAIAAxIDIBITCjUKBAQAAgESAyMC
GRooIEEgbG9uZ2VyIGRlc2NyaXB0aW9uIGFib3V0IHRoZSBzdGF0dXMuCgoMCgUEAAIBBRID
IwIICgwKBQQAAgEBEgMjCRQKDAoFBAACAQMSAyMXGAo2CgIEARIEJwAtARoqIEEgZ2VuZXJp
YyBrZXktdmFsdWUgcHJvcGVydHkgZGVmaW5pdGlvbi4KCgoKAwQBARIDJwgQChcKBAQBAgAS
AykCERoKIFRoZSBrZXkuCgoMCgUEAQIABRIDKQIICgwKBQQBAgABEgMpCQwKDAoFBAECAAMS
AykPEAoZCgQEAQIBEgMsAhMaDCBUaGUgdmFsdWUuCgoMCgUEAQIBBRIDLAIICgwKBQQBAgEB
EgMsCQ4KDAoFBAECAQMSAywREgqeAQoCBAISBDEANwEakQEgVGhlIHRpbWluZyBvZiBhIHBh
cnRpY3VsYXIgSW52b2NhdGlvbiwgQWN0aW9uLCBldGMuIFRoZSBzdGFydF90aW1lIGlzCiBz
cGVjaWZpZWQsIHN0b3AgdGltZSBjYW4gYmUgY2FsY3VsYXRlZCBieSBhZGRpbmcgZHVyYXRp
b24gdG8gc3RhcnRfdGltZS4KCgoKAwQCARIDMQgOClAKBAQCAgASAzMCKxpDIFRoZSB0aW1l
IHRoZSByZXNvdXJjZSBzdGFydGVkIHJ1bm5pbmcuIFRoaXMgaXMgaW4gVVRDIEVwb2NoIHRp
bWUuCgoMCgUEAgIABhIDMwIbCgwKBQQCAgABEgMzHCYKDAoFBAICAAMSAzMpKgo3CgQEAgIB
EgM2AigaKiBUaGUgZHVyYXRpb24gZm9yIHdoaWNoIHRoZSByZXNvdXJjZSByYW4uCgoMCgUE
AgIBBhIDNgIaCgwKBQQCAgEBEgM2GyMKDAoFBAICAQMSAzYmJwqXAQoCBAMSBDsAZQEaigEg
UmVwcmVzZW50cyBhIGRlcGVuZGVuY3kgb2YgYSByZXNvdXJjZSBvbiBhbm90aGVyIHJlc291
cmNlLiBUaGlzIGNhbiBiZSB1c2VkCiB0byBkZWZpbmUgYSBncmFwaCBvciBhIHdvcmtmbG93
IHBhcmFkaWdtIHRocm91Z2ggcmVzb3VyY2VzLgoKCgoDBAMBEgM7CBIK+AEKBAQDAwASBEAC
SQMa6QEgVGhlIHJlc291cmNlIElEIGNvbXBvbmVudHMgb2YgYSByZXNvdXJjZSBkZXBlbmRl
ZCB1cG9uLiBJdCBtYXkgYmUgYSBUYXJnZXQsCiBDb25maWd1cmVkVGFyZ2V0LCBvciBBY3Rp
b24sIHdpdGggdGhlIGFwcHJvcHJpYXRlIGNvbXBvbmVudHMgZmlsbGVkIGluLgogSW52b2Nh
dGlvbiBJRCBpcyBlbGlkZWQsIGFzIHRoaXMgbXVzdCBwb2ludCB0byBhIHJlc291cmNlIHVu
ZGVyIHRoaXMKIEludm9jYXRpb24uCgoMCgUEAwMAARIDQAoMClQKBgQDAwACABIDQgQZGkUg
VGhlIHVuZW5jb2RlZCBUYXJnZXQgSUQgb2YgdGhlIFRhcmdldCwgQ29uZmlndXJlZFRhcmdl
dCwgb3IgQWN0aW9uLgoKDgoHBAMDAAIABRIDQgQKCg4KBwQDAwACAAESA0ILFAoOCgcEAwMA
AgADEgNCFxgKSQoGBAMDAAIBEgNFBCAaOiBUaGUgQ29uZmlndXJhdGlvbiBJRCBvZiB0aGUg
Q29uZmlndXJlZFRhcmdldCwgb3IgQWN0aW9uLgoKDgoHBAMDAAIBBRIDRQQKCg4KBwQDAwAC
AQESA0ULGwoOCgcEAwMAAgEDEgNFHh8KLQoGBAMDAAICEgNIBBkaHiBUaGUgQWN0aW9uIElE
IG9mIHRoZSBBY3Rpb24uCgoOCgcEAwMAAgIFEgNIBAoKDgoHBAMDAAICARIDSAsUCg4KBwQD
AwACAgMSA0gXGApdCgQEAwgAEgRNAlwDGk8gVGhlIHJlc291cmNlIGRlcGVuZGVkIHVwb24u
IEl0IG1heSBiZSBhIFRhcmdldCwgQ29uZmlndXJlZFRhcmdldCwgb3IKIEFjdGlvbi4KCgwK
BQQDCAABEgNNCBAKvgEKBAQDAgASA1EEQhqwASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2Yg
YSB0YXJnZXQuICBJdHMgZm9ybWF0IG11c3QgYmU6CiBpbnZvY2F0aW9ucy8ke0lOVk9DQVRJ
T05fSUR9L3RhcmdldHMvJHt1cmxfZW5jb2RlKFRBUkdFVF9JRCl9CiBUaGlzIG11c3QgcG9p
bnQgdG8gYSB0YXJnZXQgdW5kZXIgdGhlIHNhbWUgaW52b2NhdGlvbi4KCgwKBQQDAgAFEgNR
BAoKDAoFBAMCAAESA1ELEQoMCgUEAwIAAxIDURQVCgwKBQQDAgAIEgNRFkEKDwoIBAMCAAic
CAASA1EXQArzAQoEBAMCARIDVgRNGuUBIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiBhIGNv
bmZpZ3VyZWQgdGFyZ2V0LiAgSXRzIGZvcm1hdCBtdXN0IGJlOgogaW52b2NhdGlvbnMvJHtJ
TlZPQ0FUSU9OX0lEfS90YXJnZXRzLyR7dXJsX2VuY29kZShUQVJHRVRfSUQpfS9jb25maWd1
cmVkVGFyZ2V0cy8ke0NPTkZJR19JRH0KIFRoaXMgbXVzdCBwb2ludCB0byBhIGNvbmZpZ3Vy
ZWQgdGFyZ2V0IHVuZGVyIHRoZSBzYW1lIGludm9jYXRpb24uCgoMCgUEAwIBBRIDVgQKCgwK
BQQDAgEBEgNWCxwKDAoFBAMCAQMSA1YfIAoMCgUEAwIBCBIDViFMCg8KCAQDAgEInAgAEgNW
IksK9AEKBAQDAgISA1sEQhrmASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgYW4gYWN0aW9u
LiAgSXRzIGZvcm1hdCBtdXN0IGJlOgogaW52b2NhdGlvbnMvJHtJTlZPQ0FUSU9OX0lEfS90
YXJnZXRzLyR7dXJsX2VuY29kZShUQVJHRVRfSUQpfS9jb25maWd1cmVkVGFyZ2V0cy8ke0NP
TkZJR19JRH0vYWN0aW9ucy8ke0FDVElPTl9JRH0KIFRoaXMgbXVzdCBwb2ludCB0byBhbiBh
Y3Rpb24gdW5kZXIgdGhlIHNhbWUgaW52b2NhdGlvbi4KCgwKBQQDAgIFEgNbBAoKDAoFBAMC
AgESA1sLEQoMCgUEAwICAxIDWxQVCgwKBQQDAgIIEgNbFkEKDwoIBAMCAgicCAASA1sXQApS
CgQEAwIDEgNfAgwaRSBUaGUgSUQgb2YgdGhlIHJlc291cmNlIGRlcGVuZGVkIHVwb24sIG1h
dGNoaW5nIHJlc291cmNlIG5hbWUgYWJvdmUuCgoMCgUEAwIDBhIDXwIECgwKBQQDAgMBEgNf
BQcKDAoFBAMCAwMSA18KCwqsAQoEBAMCBBIDZAITGp4BIEEgbGFiZWwgZGVzY3JpYmluZyB0
aGlzIGRlcGVuZGVuY3kuCiBUaGUgbGFiZWwgIlJvb3QgQ2F1c2UiIGlzIGhhbmRsZWQgc3Bl
Y2lhbGx5LiBJdCBpcyB1c2VkIHRvIHBvaW50IHRvIHRoZQogZXhhY3QgcmVzb3VyY2UgdGhh
dCBjYXVzZWQgYSByZXNvdXJjZSB0byBmYWlsLgoKDAoFBAMCBAUSA2QCCAoMCgUEAwIEARID
ZAkOCgwKBQQDAgQDEgNkERIKWwoCBQASBWgAqgEBGk4gVGhlc2UgY29ycmVzcG9uZCB0byB0
aGUgcHJlZml4IG9mIHRoZSBydWxlIG5hbWUuIEVnIGNjX3Rlc3QgaGFzIGxhbmd1YWdlIEND
LgoKCgoDBQABEgNoBQ0KNwoEBQACABIDagIbGiogTGFuZ3VhZ2UgdW5zcGVjaWZpZWQgb3Ig
bm90IGxpc3RlZCBoZXJlLgoKDAoFBQACAAESA2oCFgoMCgUFAAIAAhIDahkaCjUKBAUAAgES
A20CCxooIE5vdCByZWxhdGVkIHRvIGFueSBwYXJ0aWN1bGFyIGxhbmd1YWdlCgoMCgUFAAIB
ARIDbQIGCgwKBQUAAgECEgNtCQoKFgoEBQACAhIDcAIOGgkgQW5kcm9pZAoKDAoFBQACAgES
A3ACCQoMCgUFAAICAhIDcAwNCiMKBAUAAgMSA3MCCRoWIEFjdGlvblNjcmlwdCAoRmxhc2gp
CgoMCgUFAAIDARIDcwIECgwKBQUAAgMCEgNzBwgKFwoEBQACBBIDdgIJGgogQysrIG9yIEMK
CgwKBQUAAgQBEgN2AgQKDAoFBQACBAISA3YHCAolCgQFAAIFEgN5AgoaGCBDYXNjYWRpbmct
U3R5bGUtU2hlZXRzCgoMCgUFAAIFARIDeQIFCgwKBQUAAgUCEgN5CAkKEwoEBQACBhIDfAIL
GgYgRGFydAoKDAoFBQACBgESA3wCBgoMCgUFAAIGAhIDfAkKChEKBAUAAgcSA38CCRoEIEdv
CgoMCgUFAAIHARIDfwIECgwKBQUAAgcCEgN/BwgKIgoEBQACCBIEggECChoUIEdvb2dsZS1X
ZWItVG9vbGtpdAoKDQoFBQACCAESBIIBAgUKDQoFBQACCAISBIIBCAkKFwoEBQACCRIEhQEC
DhoJIEhhc2tlbGwKCg0KBQUAAgkBEgSFAQIJCg0KBQUAAgkCEgSFAQwNChQKBAUAAgoSBIgB
AgwaBiBKYXZhCgoNCgUFAAIKARIEiAECBgoNCgUFAAIKAhIEiAEJCwoaCgQFAAILEgSLAQIK
GgwgSmF2YXNjcmlwdAoKDQoFBQACCwESBIsBAgQKDQoFBQACCwISBIsBBwkKFAoEBQACDBIE
jgECDBoGIExpc3AKCg0KBQUAAgwBEgSOAQIGCg0KBQUAAgwCEgSOAQkLChsKBAUAAg0SBJEB
AgwaDSBPYmplY3RpdmUtQwoKDQoFBQACDQESBJEBAgYKDQoFBQACDQISBJEBCQsKFgoEBQAC
DhIElAECChoIIFB5dGhvbgoKDQoFBQACDgESBJQBAgQKDQoFBQACDgISBJQBBwkKJgoEBQAC
DxIElwECChoYIFNoZWxsIChUeXBpY2FsbHkgQmFzaCkKCg0KBQUAAg8BEgSXAQIECg0KBQUA
Ag8CEgSXAQcJChUKBAUAAhASBJoBAg0aByBTd2lmdAoKDQoFBQACEAESBJoBAgcKDQoFBQAC
EAISBJoBCgwKGgoEBQACERIEnQECChoMIFR5cGVTY3JpcHQKCg0KBQUAAhEBEgSdAQIECg0K
BQUAAhECEgSdAQcJChoKBAUAAhISBKABAgsaDCBXZWJ0ZXN0aW5nCgoNCgUFAAISARIEoAEC
BQoNCgUFAAISAhIEoAEICgoVCgQFAAITEgSjAQINGgcgU2NhbGEKCg0KBQUAAhMBEgSjAQIH
Cg0KBQUAAhMCEgSjAQoMCh8KBAUAAhQSBKYBAg0aESBQcm90b2NvbCBCdWZmZXIKCg0KBQUA
AhQBEgSmAQIHCg0KBQUAAhQCEgSmAQoMCioKBAUAAhUSBKkBAgsaHCBFeHRlbnNpYmxlIE1h
cmt1cCBMYW5ndWFnZQoKDQoFBQACFQESBKkBAgUKDQoFBQACFQISBKkBCAoKJQoCBQESBq0B
AOEBARoXIFN0YXR1cyBvZiBhIHJlc291cmNlLgoKCwoDBQEBEgStAQULCkUKBAUBAgASBK8B
AhkaNyBUaGUgaW1wbGljaXQgZGVmYXVsdCBlbnVtIHZhbHVlLiBTaG91bGQgbmV2ZXIgYmUg
c2V0LgoKDQoFBQECAAESBK8BAhQKDQoFBQECAAISBK8BFxgKVAoEBQECARIEsgECDxpGIERp
c3BsYXlzIGFzICJCdWlsZGluZyIuIE1lYW5zIHRoZSB0YXJnZXQgaXMgY29tcGlsaW5nLCBs
aW5raW5nLCBldGMuCgoNCgUFAQIBARIEsgECCgoNCgUFAQIBAhIEsgENDgq9AQoEBQECAhIE
twECDBquASBEaXNwbGF5cyBhcyAiQnVpbHQiLiBNZWFucyB0aGUgdGFyZ2V0IHdhcyBidWls
dCBzdWNjZXNzZnVsbHkuCiBJZiB0ZXN0aW5nIHdhcyByZXF1ZXN0ZWQsIGl0IHNob3VsZCBu
ZXZlciByZWFjaCB0aGlzIHN0YXR1czogaXQgc2hvdWxkIGdvCiBzdHJhaWdodCBmcm9tIEJV
SUxESU5HIHRvIFRFU1RJTkcuCgoNCgUFAQICARIEtwECBwoNCgUFAQICAhIEtwEKCwpQCgQF
AQIDEgS6AQIWGkIgRGlzcGxheXMgYXMgIkJyb2tlbiIuIE1lYW5zIGJ1aWxkIGZhaWx1cmUg
c3VjaCBhcyBjb21waWxlIGVycm9yLgoKDQoFBQECAwESBLoBAhEKDQoFBQECAwISBLoBFBUK
QQoEBQECBBIEvQECDhozIERpc3BsYXlzIGFzICJUZXN0aW5nIi4gTWVhbnMgdGhlIHRlc3Qg
aXMgcnVubmluZy4KCg0KBQUBAgQBEgS9AQIJCg0KBQUBAgQCEgS9AQwNCkgKBAUBAgUSBMAB
Ag0aOiBEaXNwbGF5cyBhcyAiUGFzc2VkIi4gTWVhbnMgdGhlIHRlc3Qgd2FzIHJ1biBhbmQg
cGFzc2VkLgoKDQoFBQECBQESBMABAggKDQoFBQECBQISBMABCwwKSAoEBQECBhIEwwECDRo6
IERpc3BsYXlzIGFzICJGYWlsZWQiLiBNZWFucyB0aGUgdGVzdCB3YXMgcnVuIGFuZCBmYWls
ZWQuCgoNCgUFAQIGARIEwwECCAoNCgUFAQIGAhIEwwELDApOCgQFAQIHEgTGAQIQGkAgRGlz
cGxheXMgYXMgIlRpbWVkIG91dCIuIE1lYW5zIHRoZSB0ZXN0IGRpZG4ndCBmaW5pc2ggaW4g
dGltZS4KCg0KBQUBAgcBEgTGAQILCg0KBQUBAgcCEgTGAQ4PCmkKBAUBAggSBMoBAhAaWyBE
aXNwbGF5cyBhcyAiQ2FuY2VsbGVkIi4gTWVhbnMgdGhlIGJ1aWxkIG9yIHRlc3Qgd2FzIGNh
bmNlbGxlZC4KIEUuZy4gVXNlciBoaXQgY29udHJvbC1DLgoKDQoFBQECCAESBMoBAgsKDQoF
BQECCAISBMoBDg8KXgoEBQECCRIEzgECEhpQIERpc3BsYXlzIGFzICJUb29sIEZhaWxlZCIu
IE1lYW5zIHRoZSBidWlsZCBvciB0ZXN0IGhhZCBpbnRlcm5hbCB0b29sCiBmYWlsdXJlLgoK
DQoFBQECCQESBM4BAg0KDQoFBQECCQISBM4BEBEKrQIKBAUBAgoSBNQBAhIangIgRGlzcGxh
eXMgYXMgIkluY29tcGxldGUiLiBNZWFucyB0aGUgYnVpbGQgb3IgdGVzdCBkaWQgbm90IGNv
bXBsZXRlLiAgVGhpcwogbWlnaHQgaGFwcGVuIHdoZW4gYSBidWlsZCBicmVha2FnZSBvciB0
ZXN0IGZhaWx1cmUgY2F1c2VzIHRoZSB0b29sIHRvIHN0b3AKIHRyeWluZyB0byBidWlsZCBh
bnl0aGluZyBtb3JlIG9yIHJ1biBhbnkgbW9yZSB0ZXN0cywgd2l0aCB0aGUgZGVmYXVsdAog
YmF6ZWwgLS1ub2tlZXBfZ29pbmcgb3B0aW9uIG9yIHRoZSAtLW5vdGVzdF9rZWVwX2dvaW5n
IG9wdGlvbi4KCg0KBQUBAgoBEgTUAQIMCg0KBQUBAgoCEgTUAQ8RCoEBCgQFAQILEgTYAQIN
GnMgRGlzcGxheXMgYXMgIkZsYWt5Ii4gTWVhbnMgdGhlIGFnZ3JlZ2F0ZSBzdGF0dXMgY29u
dGFpbnMgc29tZSBydW5zIHRoYXQKIHdlcmUgc3VjY2Vzc2Z1bCwgYW5kIHNvbWUgdGhhdCB3
ZXJlIG5vdC4KCg0KBQUBAgsBEgTYAQIHCg0KBQUBAgsCEgTYAQoMCnoKBAUBAgwSBNwBAg8a
bCBEaXNwbGF5cyBhcyAiVW5rbm93biIuIE1lYW5zIHRoZSB0b29sIHVwbG9hZGluZyB0byB0
aGUgc2VydmVyIGRpZWQKIG1pZC11cGxvYWQgb3IgZG9lcyBub3Qga25vdyB0aGUgc3RhdGUu
CgoNCgUFAQIMARIE3AECCQoNCgUFAQIMAhIE3AEMDgqAAQoEBQECDRIE4AECDxpyIERpc3Bs
YXlzIGFzICJTa2lwcGVkIi4gTWVhbnMgYnVpbGRpbmcgYW5kIHRlc3Rpbmcgd2VyZSBza2lw
cGVkLgogKEUuZy4gUmVzdHJpY3RlZCB0byBhIGRpZmZlcmVudCBjb25maWd1cmF0aW9uLikK
Cg0KBQUBAg0BEgTgAQIJCg0KBQUBAg0CEgTgAQwOCnEKAgUCEgblAQDzAQEaYyBJbmRpY2F0
ZXMgdGhlIHVwbG9hZCBzdGF0dXMgb2YgdGhlIGludm9jYXRpb24sIHdoZXRoZXIgaXQgaXMK
IHBvc3QtcHJvY2Vzc2luZywgb3IgaW1tdXRhYmxlLCBldGMuCgoLCgMFAgESBOUBBREKRQoE
BQICABIE5wECIBo3IFRoZSBpbXBsaWNpdCBkZWZhdWx0IGVudW0gdmFsdWUuIFNob3VsZCBu
ZXZlciBiZSBzZXQuCgoNCgUFAgIAARIE5wECGwoNCgUFAgIAAhIE5wEeHwpFCgQFAgIBEgTq
AQIQGjcgVGhlIGludm9jYXRpb24gaXMgc3RpbGwgdXBsb2FkaW5nIHRvIHRoZSBSZXN1bHRT
dG9yZS4KCg0KBQUCAgEBEgTqAQILCg0KBQUCAgECEgTqAQ4PCmwKBAUCAgISBO4BAhYaXiBU
aGUgaW52b2NhdGlvbiB1cGxvYWQgaXMgY29tcGxldGUuIFRoZSBSZXN1bHRTdG9yZSBpcyBz
dGlsbCBwb3N0LXByb2Nlc3NpbmcKIHRoZSBpbnZvY2F0aW9uLgoKDQoFBQICAgESBO4BAhEK
DQoFBQICAgISBO4BFBUKhQEKBAUCAgMSBPIBAhAadyBBbGwgcG9zdC1wcm9jZXNzaW5nIGlz
IGNvbXBsZXRlLCBhbmQgdGhlIGludm9jYXRpb24gaXMgbm93IGltbXV0YWJsZS4KIERhdGEg
bWF5IGJlIHN1YmplY3QgdG8gVFRMIGFuZCBjYW4gYmUgZGVsZXRlZC4KCg0KBQUCAgMBEgTy
AQILCg0KBQUCAgMCEgTyAQ4PYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Common::StatusAttributes ===
    # Fields for StatusAttributes
    # Field: status Type: 14 (.google.devtools.resultstore.v2.Status)
    # Field: description Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Common::Property ===
    # Fields for Property
    # Field: key Type: 9 ()
    # Field: value Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Common::Timing ===
    # Fields for Timing
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: duration Type: 11 (.google.protobuf.Duration)

# === Message: Google::Devtools::Resultstore::V2::Common::Dependency ===
    # Fields for Dependency
    # Field: target Type: 9 ()
    # Field: configured_target Type: 9 ()
    # Field: action Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.Dependency.Id)
    # Field: label Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Common - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/common.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Common;

    my $msg = Google::Devtools::Resultstore::V2::Common::StatusAttributes->new({
        status => $status,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->status();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Common::StatusAttributes->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Common::StatusAttributes

Describes the status of a resource in both enum and string form.
Only use description when conveying additional info not captured in the enum
name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::Status>)

Enum representation of the status.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A longer description about the status.

=back

=head2 Google::Devtools::Resultstore::V2::Common::Property

A generic key-value property definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

The key.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The value.

=back

=head2 Google::Devtools::Resultstore::V2::Common::Timing

The timing of a particular Invocation, Action, etc. The start_time is
specified, stop time can be calculated by adding duration to start_time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the resource started running. This is in UTC Epoch time.

=item * C<< $msg->duration() >> / C<< $msg->duration($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The duration for which the resource ran.

=back

=head2 Google::Devtools::Resultstore::V2::Common::Dependency

Represents a dependency of a resource on another resource. This can be used
to define a graph or a workflow paradigm through resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. The name of a target.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}
This must point to a target under the same invocation.

=item * C<< $msg->configured_target() >> / C<< $msg->configured_target($value) >>

Type: C<String>

Output only. The name of a configured target.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}/configuredTargets/${CONFIG_ID}
This must point to a configured target under the same invocation.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Output only. The name of an action.  Its format must be:
invocations/${INVOCATION_ID}/targets/${url_encode(TARGET_ID)}/configuredTargets/${CONFIG_ID}/actions/${ACTION_ID}
This must point to an action under the same invocation.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Dependency::Id>)

The ID of the resource depended upon, matching resource name above.

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

A label describing this dependency.
The label "Root Cause" is handled specially. It is used to point to the
exact resource that caused a resource to fail.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
