package Google::Cloud::Bigquery::Migration::V2::TranslationDetails;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL3RyYW5zbGF0aW9uX2RldGFp
bHMucHJvdG8SImdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8iywMKElRyYW5zbGF0aW9uRGV0YWlscxJrChVzb3Vy
Y2VfdGFyZ2V0X21hcHBpbmcYASADKAsyNy5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0
aW9uLnYyLlNvdXJjZVRhcmdldE1hcHBpbmdSE3NvdXJjZVRhcmdldE1hcHBpbmcSJgoPdGFy
Z2V0X2Jhc2VfdXJpGAIgASgJUg10YXJnZXRCYXNlVXJpEmQKEnNvdXJjZV9lbnZpcm9ubWVu
dBgDIAEoCzI1Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuU291cmNlRW52
aXJvbm1lbnRSEXNvdXJjZUVudmlyb25tZW50EjQKFnRhcmdldF9yZXR1cm5fbGl0ZXJhbHMY
BCADKAlSFHRhcmdldFJldHVybkxpdGVyYWxzEiEKDHRhcmdldF90eXBlcxgFIAMoCVILdGFy
Z2V0VHlwZXMSYQoRc3VnZ2VzdGlvbl9jb25maWcYBiABKAsyNC5nb29nbGUuY2xvdWQuYmln
cXVlcnkubWlncmF0aW9uLnYyLlN1Z2dlc3Rpb25Db25maWdSEHN1Z2dlc3Rpb25Db25maWci
egoQU3VnZ2VzdGlvbkNvbmZpZxJmChVza2lwX3N1Z2dlc3Rpb25fc3RlcHMYASADKAsyMi5n
b29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLlN1Z2dlc3Rpb25TdGVwUhNza2lw
U3VnZ2VzdGlvblN0ZXBzIp8DCg5TdWdnZXN0aW9uU3RlcBJqCg9zdWdnZXN0aW9uX3R5cGUY
ASABKA4yQS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyLlN1Z2dlc3Rpb25T
dGVwLlN1Z2dlc3Rpb25UeXBlUg5zdWdnZXN0aW9uVHlwZRJnCg5yZXdyaXRlX3RhcmdldBgC
IAEoDjJALmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuU3VnZ2VzdGlvblN0
ZXAuUmV3cml0ZVRhcmdldFINcmV3cml0ZVRhcmdldCJnCg5TdWdnZXN0aW9uVHlwZRIfChtT
VUdHRVNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABIXChNRVUVSWV9DVVNUT01JWkFUSU9OEAES
GwoXVFJBTlNMQVRJT05fRVhQTEFOQVRJT04QAiJPCg1SZXdyaXRlVGFyZ2V0Eh4KGlJFV1JJ
VEVfVEFSR0VUX1VOU1BFQ0lGSUVEEAASDgoKU09VUkNFX1NRTBABEg4KClRBUkdFVF9TUUwQ
AiK3AQoTU291cmNlVGFyZ2V0TWFwcGluZxJPCgtzb3VyY2Vfc3BlYxgBIAEoCzIuLmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuU291cmNlU3BlY1IKc291cmNlU3BlYxJP
Cgt0YXJnZXRfc3BlYxgCIAEoCzIuLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24u
djIuVGFyZ2V0U3BlY1IKdGFyZ2V0U3BlYyLDAQoKU291cmNlU3BlYxIbCghiYXNlX3VyaRgB
IAEoCUgAUgdiYXNlVXJpEkcKB2xpdGVyYWwYAiABKAsyKy5nb29nbGUuY2xvdWQuYmlncXVl
cnkubWlncmF0aW9uLnYyLkxpdGVyYWxIAFIHbGl0ZXJhbBIkCg1nY3NfZmlsZV9wYXRoGAQg
ASgJSABSC2djc0ZpbGVQYXRoEh8KCGVuY29kaW5nGAMgASgJQgPgQQFSCGVuY29kaW5nQggK
BnNvdXJjZSIxCgpUYXJnZXRTcGVjEiMKDXJlbGF0aXZlX3BhdGgYASABKAlSDHJlbGF0aXZl
UGF0aCKTAQoHTGl0ZXJhbBInCg5saXRlcmFsX3N0cmluZxgCIAEoCUgAUg1saXRlcmFsU3Ry
aW5nEiUKDWxpdGVyYWxfYnl0ZXMYAyABKAxIAFIMbGl0ZXJhbEJ5dGVzEigKDXJlbGF0aXZl
X3BhdGgYASABKAlCA+BBAlIMcmVsYXRpdmVQYXRoQg4KDGxpdGVyYWxfZGF0YSKnAQoRU291
cmNlRW52aXJvbm1lbnQSKQoQZGVmYXVsdF9kYXRhYmFzZRgBIAEoCVIPZGVmYXVsdERhdGFi
YXNlEiwKEnNjaGVtYV9zZWFyY2hfcGF0aBgCIAMoCVIQc2NoZW1hU2VhcmNoUGF0aBI5ChZt
ZXRhZGF0YV9zdG9yZV9kYXRhc2V0GAMgASgJQgPgQQFSFG1ldGFkYXRhU3RvcmVEYXRhc2V0
QtMBCiZjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MkIXVHJhbnNsYXRp
b25EZXRhaWxzUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS9taWdyYXRp
b24vYXBpdjIvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAiJHb29nbGUuQ2xvdWQuQmlnUXVl
cnkuTWlncmF0aW9uLlYyygIiR29vZ2xlXENsb3VkXEJpZ1F1ZXJ5XE1pZ3JhdGlvblxWMkrI
KgoHEgUOAKABAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
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
KwoJCgIDABIDEgApCggKAQgSAxQAPwoJCgIIJRIDFAA/CggKAQgSAxUAWwoJCgIICxIDFQBb
CggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOAoJCgIICBIDFwA4CggKAQgSAxgAPwoJ
CgIIARIDGAA/CggKAQgSAxkAQAoJCgIIKRIDGQBACl8KAgQAEgQdADQBGlMgVGhlIHRyYW5z
bGF0aW9uIGRldGFpbHMgdG8gY2FwdHVyZSB0aGUgbmVjZXNzYXJ5IHNldHRpbmdzIGZvciBh
IHRyYW5zbGF0aW9uCiBqb2IuCgoKCgMEAAESAx0IGgo1CgQEAAIAEgMfAjkaKCBUaGUgbWFw
cGluZyBmcm9tIHNvdXJjZSB0byB0YXJnZXQgU1FMLgoKDAoFBAACAAQSAx8CCgoMCgUEAAIA
BhIDHwseCgwKBQQAAgABEgMfHzQKDAoFBAACAAMSAx83OApBCgQEAAIBEgMiAh0aNCBUaGUg
YmFzZSBVUkkgZm9yIGFsbCB3cml0ZXMgdG8gcGVyc2lzdGVudCBzdG9yYWdlLgoKDAoFBAAC
AQUSAyICCAoMCgUEAAIBARIDIgkYCgwKBQQAAgEDEgMiGxwKSQoEBAACAhIDJQIrGjwgVGhl
IGRlZmF1bHQgc291cmNlIGVudmlyb25tZW50IHZhbHVlcyBmb3IgdGhlIHRyYW5zbGF0aW9u
LgoKDAoFBAACAgYSAyUCEwoMCgUEAAICARIDJRQmCgwKBQQAAgIDEgMlKSoK7wEKBAQAAgMS
AyoCLRrhASBUaGUgbGlzdCBvZiBsaXRlcmFsIHRhcmdldHMgdGhhdCB3aWxsIGJlIGRpcmVj
dGx5IHJldHVybmVkIHRvIHRoZSByZXNwb25zZS4KIEVhY2ggZW50cnkgY29uc2lzdHMgb2Yg
dGhlIGNvbnN0cnVjdGVkIHBhdGgsIEVYQ0xVRElORyB0aGUgYmFzZSBwYXRoLiBOb3QKIHBy
b3ZpZGluZyBhIHRhcmdldF9iYXNlX3VyaSB3aWxsIHByZXZlbnQgd3JpdGluZyB0byBwZXJz
aXN0ZW50IHN0b3JhZ2UuCgoMCgUEAAIDBBIDKgIKCgwKBQQAAgMFEgMqCxEKDAoFBAACAwES
AyoSKAoMCgUEAAIDAxIDKissCpkCCgQEAAIEEgMwAiMaiwIgVGhlIHR5cGVzIG9mIG91dHB1
dCB0byBnZW5lcmF0ZSwgZS5nLiBzcWwsIG1ldGFkYXRhLAogbGluZWFnZV9mcm9tX3NxbF9z
Y3JpcHRzLCBldGMuIElmIG5vdCBzcGVjaWZpZWQsIGEgZGVmYXVsdCBzZXQgb2YKIHRhcmdl
dHMgd2lsbCBiZSBnZW5lcmF0ZWQuIFNvbWUgYWRkaXRpb25hbCB0YXJnZXQgdHlwZXMgbWF5
IGJlIHNsb3dlciB0bwogZ2VuZXJhdGUuIFNlZSB0aGUgZG9jdW1lbnRhdGlvbiBmb3IgdGhl
IHNldCBvZiBhdmFpbGFibGUgdGFyZ2V0IHR5cGVzLgoKDAoFBAACBAQSAzACCgoMCgUEAAIE
BRIDMAsRCgwKBQQAAgQBEgMwEh4KDAoFBAACBAMSAzAhIgpSCgQEAAIFEgMzAikaRSBUaGUg
Y29uZmlndXJhdGlvbiBmb3IgdGhlIHN1Z2dlc3Rpb24gaWYgcmVxdWVzdGVkIGFzIGEgdGFy
Z2V0IHR5cGUuCgoMCgUEAAIFBhIDMwISCgwKBQQAAgUBEgMzEyQKDAoFBAACBQMSAzMnKApR
CgIEARIENwA6ARpFIFRoZSBjb25maWd1cmF0aW9uIGZvciB0aGUgc3VnZ2VzdGlvbiBpZiBy
ZXF1ZXN0ZWQgYXMgYSB0YXJnZXQgdHlwZS4KCgoKAwQBARIDNwgYCjQKBAQBAgASAzkCNBon
IFRoZSBsaXN0IG9mIHN1Z2dlc3Rpb24gc3RlcHMgdG8gc2tpcC4KCgwKBQQBAgAEEgM5AgoK
DAoFBAECAAYSAzkLGQoMCgUEAQIAARIDORovCgwKBQQBAgADEgM5MjMKJgoCBAISBD0AWwEa
GiBTdWdnZXN0aW9uIHN0ZXAgdG8gc2tpcC4KCgoKAwQCARIDPQgWCiAKBAQCBAASBD8CSAMa
EiBTdWdnZXN0aW9uIHR5cGUuCgoMCgUEAgQAARIDPwcVCi0KBgQCBAACABIDQQQkGh4gU3Vn
Z2VzdGlvbiB0eXBlIHVuc3BlY2lmaWVkLgoKDgoHBAIEAAIAARIDQQQfCg4KBwQCBAACAAIS
A0EiIwolCgYEAgQAAgESA0QEHBoWIFF1ZXJ5IGN1c3RvbWl6YXRpb24uCgoOCgcEAgQAAgEB
EgNEBBcKDgoHBAIEAAIBAhIDRBobCikKBgQCBAACAhIDRwQgGhogVHJhbnNsYXRpb24gZXhw
bGFuYXRpb24uCgoOCgcEAgQAAgIBEgNHBBsKDgoHBAIEAAICAhIDRx4fCjYKBAQCBAESBEsC
VAMaKCBUaGUgdGFyZ2V0IHRvIGFwcGx5IHRoZSBzdWdnZXN0aW9uIHRvLgoKDAoFBAIEAQES
A0sHFAosCgYEAgQBAgASA00EIxodIFJld3JpdGUgdGFyZ2V0IHVuc3BlY2lmaWVkLgoKDgoH
BAIEAQIAARIDTQQeCg4KBwQCBAECAAISA00hIgocCgYEAgQBAgESA1AEExoNIFNvdXJjZSBT
UUwuCgoOCgcEAgQBAgEBEgNQBA4KDgoHBAIEAQIBAhIDUBESChwKBgQCBAECAhIDUwQTGg0g
VGFyZ2V0IFNRTC4KCg4KBwQCBAECAgESA1MEDgoOCgcEAgQBAgICEgNTERIKJgoEBAICABID
VwIlGhkgVGhlIHR5cGUgb2Ygc3VnZ2VzdGlvbi4KCgwKBQQCAgAGEgNXAhAKDAoFBAICAAES
A1cRIAoMCgUEAgIAAxIDVyMkCiIKBAQCAgESA1oCIxoVIFRoZSByZXdyaXRlIHRhcmdldC4K
CgwKBQQCAgEGEgNaAg8KDAoFBAICAQESA1oQHgoMCgUEAgIBAxIDWiEiCkcKAgQDEgReAGQB
GjsgUmVwcmVzZW50cyBvbmUgbWFwcGluZyBmcm9tIGEgc291cmNlIFNRTCB0byBhIHRhcmdl
dCBTUUwuCgoKCgMEAwESA14IGwowCgQEAwIAEgNgAh0aIyBUaGUgc291cmNlIFNRTCBvciB0
aGUgcGF0aCB0byBpdC4KCgwKBQQDAgAGEgNgAgwKDAoFBAMCAAESA2ANGAoMCgUEAwIAAxID
YBscCjEKBAQDAgESA2MCHRokIFRoZSB0YXJnZXQgU1FMIG9yIHRoZSBwYXRoIGZvciBpdC4K
CgwKBQQDAgEGEgNjAgwKDAoFBAMCAQESA2MNGAoMCgUEAwIBAxIDYxscCkkKAgQEEgRnAHYB
Gj0gUmVwcmVzZW50cyBvbmUgcGF0aCB0byB0aGUgbG9jYXRpb24gdGhhdCBob2xkcyBzb3Vy
Y2UgZGF0YS4KCgoKAwQEARIDZwgSCigKBAQECAASBGkCcgMaGiBUaGUgc3BlY2lmaWMgc291
cmNlIFNRTC4KCgwKBQQECAABEgNpCA4KUwoEBAQCABIDawQYGkYgVGhlIGJhc2UgVVJJIGZv
ciBhbGwgZmlsZXMgdG8gYmUgcmVhZCBpbiBhcyBzb3VyY2VzIGZvciB0cmFuc2xhdGlvbi4K
CgwKBQQEAgAFEgNrBAoKDAoFBAQCAAESA2sLEwoMCgUEBAIAAxIDaxYXCh4KBAQEAgESA24E
GBoRIFNvdXJjZSBsaXRlcmFsLgoKDAoFBAQCAQYSA24ECwoMCgUEBAIBARIDbgwTCgwKBQQE
AgEDEgNuFhcKQQoEBAQCAhIDcQQdGjQgVGhlIHBhdGggdG8gYSBzaW5nbGUgc291cmNlIGZp
bGUgaW4gQ2xvdWQgU3RvcmFnZS4KCgwKBQQEAgIFEgNxBAoKDAoFBAQCAgESA3ELGAoMCgUE
BAICAxIDcRscClUKBAQEAgMSA3UCPxpIIE9wdGlvbmFsLiBUaGUgb3B0aW9uYWwgZmllbGQg
dG8gc3BlY2lmeSB0aGUgZW5jb2Rpbmcgb2YgdGhlIHNxbCBieXRlcy4KCgwKBQQEAgMFEgN1
AggKDAoFBAQCAwESA3UJEQoMCgUEBAIDAxIDdRQVCgwKBQQEAgMIEgN1Fj4KDwoIBAQCAwic
CAASA3UXPQpJCgIEBRIEeQB+ARo9IFJlcHJlc2VudHMgb25lIHBhdGggdG8gdGhlIGxvY2F0
aW9uIHRoYXQgaG9sZHMgdGFyZ2V0IGRhdGEuCgoKCgMEBQESA3kIEgqjAQoEBAUCABIDfQIb
GpUBIFRoZSByZWxhdGl2ZSBwYXRoIGZvciB0aGUgdGFyZ2V0IGRhdGEuIEdpdmVuIHNvdXJj
ZSBmaWxlCiBgYmFzZV91cmkvaW5wdXQvc3FsYCwgdGhlIG91dHB1dCB3b3VsZCBiZQogYHRh
cmdldF9iYXNlX3VyaS9zcWwvcmVsYXRpdmVfcGF0aC9pbnB1dC5zcWxgLgoKDAoFBAUCAAUS
A30CCAoMCgUEBQIAARIDfQkWCgwKBQQFAgADEgN9GRoKHQoCBAYSBoEBAI0BARoPIExpdGVy
YWwgZGF0YS4KCgsKAwQGARIEgQEIDworCgQEBggAEgaDAQKJAQMaGyBUaGUgbGl0ZXJhbCBT
UUwgY29udGVudHMuCgoNCgUEBggAARIEgwEIFAokCgQEBgIAEgSFAQQeGhYgTGl0ZXJhbCBz
dHJpbmcgZGF0YS4KCg0KBQQGAgAFEgSFAQQKCg0KBQQGAgABEgSFAQsZCg0KBQQGAgADEgSF
ARwdCiIKBAQGAgESBIgBBBwaFCBMaXRlcmFsIGJ5dGUgZGF0YS4KCg0KBQQGAgEFEgSIAQQJ
Cg0KBQQGAgEBEgSIAQoXCg0KBQQGAgEDEgSIARobCj4KBAQGAgISBIwBAkQaMCBSZXF1aXJl
ZC4gVGhlIGlkZW50aWZpZXIgb2YgdGhlIGxpdGVyYWwgZW50cnkuCgoNCgUEBgICBRIEjAEC
CAoNCgUEBgICARIEjAEJFgoNCgUEBgICAxIEjAEZGgoNCgUEBgICCBIEjAEbQwoQCggEBgIC
CJwIABIEjAEcQgpVCgIEBxIGkAEAoAEBGkcgUmVwcmVzZW50cyB0aGUgZGVmYXVsdCBzb3Vy
Y2UgZW52aXJvbm1lbnQgdmFsdWVzIGZvciB0aGUgdHJhbnNsYXRpb24uCgoLCgMEBwESBJAB
CBkKbAoEBAcCABIEkwECHhpeIFRoZSBkZWZhdWx0IGRhdGFiYXNlIG5hbWUgdG8gZnVsbHkg
cXVhbGlmeSBTUUwgb2JqZWN0cyB3aGVuIHRoZWlyIGRhdGFiYXNlCiBuYW1lIGlzIG1pc3Np
bmcuCgoNCgUEBwIABRIEkwECCAoNCgUEBwIAARIEkwEJGQoNCgUEBwIAAxIEkwEcHQqXAQoE
BAcCARIElwECKRqIASBUaGUgc2NoZW1hIHNlYXJjaCBwYXRoLiBXaGVuIFNRTCBvYmplY3Rz
IGFyZSBtaXNzaW5nIHNjaGVtYSBuYW1lLAogdHJhbnNsYXRpb24gZW5naW5lIHdpbGwgc2Vh
cmNoIHRocm91Z2ggdGhpcyBsaXN0IHRvIGZpbmQgdGhlIHZhbHVlLgoKDQoFBAcCAQQSBJcB
AgoKDQoFBAcCAQUSBJcBCxEKDQoFBAcCAQESBJcBEiQKDQoFBAcCAQMSBJcBJygKlwMKBAQH
AgISBJ8BAk0aiAMgT3B0aW9uYWwuIEV4cGVjdHMgYSB2YWxpZFEgQmlnUXVlcnkgZGF0YXNl
dCBJRCB0aGF0IGV4aXN0cywgZS5nLiwKIHByb2plY3QtMTIzLm1ldGFkYXRhX3N0b3JlXzEy
My4gIElmIHNwZWNpZmllZCwgdHJhbnNsYXRpb24gd2lsbCBzZWFyY2ggYW5kCiByZWFkIHRo
ZSByZXF1aXJlZCBzY2hlbWEgaW5mb3JtYXRpb24gZnJvbSBhIG1ldGFkYXRhIHN0b3JlIGlu
IHRoaXMgZGF0YXNldC4KIElmIG1ldGFkYXRhIHN0b3JlIGRvZXNuJ3QgZXhpc3QsIHRyYW5z
bGF0aW9uIHdpbGwgcGFyc2UgdGhlIG1ldGFkYXRhIGZpbGUKIGFuZCB1cGxvYWQgdGhlIHNj
aGVtYSBpbmZvIHRvIGEgdGVtcCB0YWJsZSBpbiB0aGUgZGF0YXNldCB0byBzcGVlZCB1cAog
ZnV0dXJlIHRyYW5zbGF0aW9uIGpvYnMuCgoNCgUEBwICBRIEnwECCAoNCgUEBwICARIEnwEJ
HwoNCgUEBwICAxIEnwEiIwoNCgUEBwICCBIEnwEkTAoQCggEBwICCJwIABIEnwElS2IGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails ===
    # Fields for TranslationDetails
    # Field: source_target_mapping Type: 11 (.google.cloud.bigquery.migration.v2.SourceTargetMapping)
    # Field: target_base_uri Type: 9 ()
    # Field: source_environment Type: 11 (.google.cloud.bigquery.migration.v2.SourceEnvironment)
    # Field: target_return_literals Type: 9 ()
    # Field: target_types Type: 9 ()
    # Field: suggestion_config Type: 11 (.google.cloud.bigquery.migration.v2.SuggestionConfig)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig ===
    # Fields for SuggestionConfig
    # Field: skip_suggestion_steps Type: 11 (.google.cloud.bigquery.migration.v2.SuggestionStep)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep ===
    # Fields for SuggestionStep
    # Field: suggestion_type Type: 14 (.google.cloud.bigquery.migration.v2.SuggestionStep.SuggestionType)
    # Field: rewrite_target Type: 14 (.google.cloud.bigquery.migration.v2.SuggestionStep.RewriteTarget)

# Enum: SuggestionStep::SuggestionType
our $SuggestionStep_SUGGESTION_TYPE_UNSPECIFIED = 0;
our $SuggestionStep_QUERY_CUSTOMIZATION = 1;
our $SuggestionStep_TRANSLATION_EXPLANATION = 2;

# Enum: SuggestionStep::RewriteTarget
our $SuggestionStep_REWRITE_TARGET_UNSPECIFIED = 0;
our $SuggestionStep_SOURCE_SQL = 1;
our $SuggestionStep_TARGET_SQL = 2;

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping ===
    # Fields for SourceTargetMapping
    # Field: source_spec Type: 11 (.google.cloud.bigquery.migration.v2.SourceSpec)
    # Field: target_spec Type: 11 (.google.cloud.bigquery.migration.v2.TargetSpec)

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec ===
    # Fields for SourceSpec
    # Field: base_uri Type: 9 ()
    # Field: literal Type: 11 (.google.cloud.bigquery.migration.v2.Literal)
    # Field: gcs_file_path Type: 9 ()
    # Field: encoding Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec ===
    # Fields for TargetSpec
    # Field: relative_path Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal ===
    # Fields for Literal
    # Field: literal_string Type: 9 ()
    # Field: literal_bytes Type: 12 ()
    # Field: relative_path Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment ===
    # Fields for SourceEnvironment
    # Field: default_database Type: 9 ()
    # Field: schema_search_path Type: 9 ()
    # Field: metadata_store_dataset Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationDetails - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/translation_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::TranslationDetails;

    my $msg = Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails->new({
        source_target_mapping => $source_target_mapping,
        target_base_uri => $target_base_uri,
        source_environment => $source_environment,
        target_return_literals => $target_return_literals,
    });

    # Read or update a field
    my $val = $msg->source_target_mapping();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/translation_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails

The translation details to capture the necessary settings for a translation
job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_target_mapping() >> / C<< $msg->source_target_mapping($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping>)

The mapping from source to target SQL.

=item * C<< $msg->target_base_uri() >> / C<< $msg->target_base_uri($value) >>

Type: C<String>

The base URI for all writes to persistent storage.

=item * C<< $msg->source_environment() >> / C<< $msg->source_environment($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment>)

The default source environment values for the translation.

=item * C<< $msg->target_return_literals() >> / C<< $msg->target_return_literals($value) >>

Type: C<String>

The list of literal targets that will be directly returned to the response.
Each entry consists of the constructed path, EXCLUDING the base path. Not
providing a target_base_uri will prevent writing to persistent storage.

=item * C<< $msg->target_types() >> / C<< $msg->target_types($value) >>

Type: C<String>

The types of output to generate, e.g. sql, metadata,
lineage_from_sql_scripts, etc. If not specified, a default set of
targets will be generated. Some additional target types may be slower to
generate. See the documentation for the set of available target types.

=item * C<< $msg->suggestion_config() >> / C<< $msg->suggestion_config($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig>)

The configuration for the suggestion if requested as a target type.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig

The configuration for the suggestion if requested as a target type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->skip_suggestion_steps() >> / C<< $msg->skip_suggestion_steps($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep>)

The list of suggestion steps to skip.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep

Suggestion step to skip.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->suggestion_type() >> / C<< $msg->suggestion_type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2::SuggestionStep::SuggestionType>)

The type of suggestion.

=item * C<< $msg->rewrite_target() >> / C<< $msg->rewrite_target($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2::SuggestionStep::RewriteTarget>)

The rewrite target.

=back

=head3 Enum: SuggestionStep::SuggestionType

=over 4

=item * C<SUGGESTION_TYPE_UNSPECIFIED> => C<0>

=item * C<QUERY_CUSTOMIZATION> => C<1>

=item * C<TRANSLATION_EXPLANATION> => C<2>

=back

=head3 Enum: SuggestionStep::RewriteTarget

=over 4

=item * C<REWRITE_TARGET_UNSPECIFIED> => C<0>

=item * C<SOURCE_SQL> => C<1>

=item * C<TARGET_SQL> => C<2>

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping

Represents one mapping from a source SQL to a target SQL.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_spec() >> / C<< $msg->source_spec($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec>)

The source SQL or the path to it.

=item * C<< $msg->target_spec() >> / C<< $msg->target_spec($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec>)

The target SQL or the path for it.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec

Represents one path to the location that holds source data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_uri() >> / C<< $msg->base_uri($value) >>

Type: C<String>

The base URI for all files to be read in as sources for translation.

=item * C<< $msg->literal() >> / C<< $msg->literal($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal>)

Source literal.

=item * C<< $msg->gcs_file_path() >> / C<< $msg->gcs_file_path($value) >>

Type: C<String>

The path to a single source file in Cloud Storage.

=item * C<< $msg->encoding() >> / C<< $msg->encoding($value) >>

Type: C<String>

Optional. The optional field to specify the encoding of the sql bytes.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec

Represents one path to the location that holds target data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->relative_path() >> / C<< $msg->relative_path($value) >>

Type: C<String>

The relative path for the target data. Given source file
`base_uri/input/sql`, the output would be
`target_base_uri/sql/relative_path/input.sql`.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal

Literal data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->literal_string() >> / C<< $msg->literal_string($value) >>

Type: C<String>

Literal string data.

=item * C<< $msg->literal_bytes() >> / C<< $msg->literal_bytes($value) >>

Type: C<Bytes>

Literal byte data.

=item * C<< $msg->relative_path() >> / C<< $msg->relative_path($value) >>

Type: C<String>

Required. The identifier of the literal entry.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment

Represents the default source environment values for the translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->default_database() >> / C<< $msg->default_database($value) >>

Type: C<String>

The default database name to fully qualify SQL objects when their database
name is missing.

=item * C<< $msg->schema_search_path() >> / C<< $msg->schema_search_path($value) >>

Type: C<String>

The schema search path. When SQL objects are missing schema name,
translation engine will search through this list to find the value.

=item * C<< $msg->metadata_store_dataset() >> / C<< $msg->metadata_store_dataset($value) >>

Type: C<String>

Optional. Expects a validQ BigQuery dataset ID that exists, e.g.,
project-123.metadata_store_123.  If specified, translation will search and
read the required schema information from a metadata store in this dataset.
If metadata store doesn't exist, translation will parse the metadata file
and upload the schema info to a temp table in the dataset to speed up
future translation jobs.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
