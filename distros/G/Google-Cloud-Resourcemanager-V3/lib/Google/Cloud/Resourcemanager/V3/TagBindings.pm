package Google::Cloud::Resourcemanager::V3::TagBindings;

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
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YzL3RhZ19iaW5kaW5ncy5wcm90bxIf
Z29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52MxocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9sb25ncnVu
bmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8i5QEK
ClRhZ0JpbmRpbmcSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEhYKBnBhcmVudBgCIAEoCVIG
cGFyZW50EhsKCXRhZ192YWx1ZRgDIAEoCVIIdGFnVmFsdWUSOQoZdGFnX3ZhbHVlX25hbWVz
cGFjZWRfbmFtZRgEIAEoCVIWdGFnVmFsdWVOYW1lc3BhY2VkTmFtZTpO6kFLCi5jbG91ZHJl
c291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9UYWdCaW5kaW5nEhl0YWdCaW5kaW5ncy97
dGFnX2JpbmRpbmd9IhoKGENyZWF0ZVRhZ0JpbmRpbmdNZXRhZGF0YSKWAQoXQ3JlYXRlVGFn
QmluZGluZ1JlcXVlc3QSUQoLdGFnX2JpbmRpbmcYASABKAsyKy5nb29nbGUuY2xvdWQucmVz
b3VyY2VtYW5hZ2VyLnYzLlRhZ0JpbmRpbmdCA+BBAlIKdGFnQmluZGluZxIoCg12YWxpZGF0
ZV9vbmx5GAIgASgIQgPgQQFSDHZhbGlkYXRlT25seSIaChhEZWxldGVUYWdCaW5kaW5nTWV0
YWRhdGEiZQoXRGVsZXRlVGFnQmluZGluZ1JlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEw
Ci5jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9UYWdCaW5kaW5nUgRuYW1l
IoEBChZMaXN0VGFnQmluZGluZ3NSZXF1ZXN0EiEKBnBhcmVudBgBIAEoCUIJ4EEC+kEDEgEq
UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9r
ZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpEBChdMaXN0VGFnQmluZGluZ3NSZXNwb25zZRJO
Cgx0YWdfYmluZGluZ3MYASADKAsyKy5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYz
LlRhZ0JpbmRpbmdSC3RhZ0JpbmRpbmdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiJ9ChhMaXN0RWZmZWN0aXZlVGFnc1JlcXVlc3QSGwoGcGFyZW50GAEgASgJ
QgPgQQJSBnBhcmVudBIgCglwYWdlX3NpemUYAiABKAVCA+BBAVIIcGFnZVNpemUSIgoKcGFn
ZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4imQEKGUxpc3RFZmZlY3RpdmVUYWdzUmVz
cG9uc2USVAoOZWZmZWN0aXZlX3RhZ3MYASADKAsyLS5nb29nbGUuY2xvdWQucmVzb3VyY2Vt
YW5hZ2VyLnYzLkVmZmVjdGl2ZVRhZ1INZWZmZWN0aXZlVGFncxImCg9uZXh0X3BhZ2VfdG9r
ZW4YAiABKAlSDW5leHRQYWdlVG9rZW4i1QIKDEVmZmVjdGl2ZVRhZxJOCgl0YWdfdmFsdWUY
ASABKAlCMfpBLgosY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVGFnVmFs
dWVSCHRhZ1ZhbHVlEjAKFG5hbWVzcGFjZWRfdGFnX3ZhbHVlGAIgASgJUhJuYW1lc3BhY2Vk
VGFnVmFsdWUSSAoHdGFnX2tleRgDIAEoCUIv+kEsCipjbG91ZHJlc291cmNlbWFuYWdlci5n
b29nbGVhcGlzLmNvbS9UYWdLZXlSBnRhZ0tleRIsChJuYW1lc3BhY2VkX3RhZ19rZXkYBCAB
KAlSEG5hbWVzcGFjZWRUYWdLZXkSLQoTdGFnX2tleV9wYXJlbnRfbmFtZRgGIAEoCVIQdGFn
S2V5UGFyZW50TmFtZRIcCglpbmhlcml0ZWQYBSABKAhSCWluaGVyaXRlZDKRBwoLVGFnQmlu
ZGluZ3MSpgEKD0xpc3RUYWdCaW5kaW5ncxI3Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFn
ZXIudjMuTGlzdFRhZ0JpbmRpbmdzUmVxdWVzdBo4Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1h
bmFnZXIudjMuTGlzdFRhZ0JpbmRpbmdzUmVzcG9uc2UiIILT5JMCERIPL3YzL3RhZ0JpbmRp
bmdz2kEGcGFyZW50EsgBChBDcmVhdGVUYWdCaW5kaW5nEjguZ29vZ2xlLmNsb3VkLnJlc291
cmNlbWFuYWdlci52My5DcmVhdGVUYWdCaW5kaW5nUmVxdWVzdBodLmdvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb24iW4LT5JMCHiIPL3YzL3RhZ0JpbmRpbmdzOgt0YWdfYmluZGluZ9pB
C3RhZ19iaW5kaW5nykEmCgpUYWdCaW5kaW5nEhhDcmVhdGVUYWdCaW5kaW5nTWV0YWRhdGES
yQEKEERlbGV0ZVRhZ0JpbmRpbmcSOC5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYz
LkRlbGV0ZVRhZ0JpbmRpbmdSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlv
biJcgtPkkwIbKhkvdjMve25hbWU9dGFnQmluZGluZ3MvKip92kEEbmFtZcpBMQoVZ29vZ2xl
LnByb3RvYnVmLkVtcHR5EhhEZWxldGVUYWdCaW5kaW5nTWV0YWRhdGESrgEKEUxpc3RFZmZl
Y3RpdmVUYWdzEjkuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5MaXN0RWZmZWN0
aXZlVGFnc1JlcXVlc3QaOi5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLkxpc3RF
ZmZlY3RpdmVUYWdzUmVzcG9uc2UiIoLT5JMCExIRL3YzL2VmZmVjdGl2ZVRhZ3PaQQZwYXJl
bnQakAHKQSNjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbdJBZ2h0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybS5yZWFkLW9ubHlC8QEKI2NvbS5nb29n
bGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzQhBUYWdCaW5kaW5nc1Byb3RvUAFaTWNsb3Vk
Lmdvb2dsZS5jb20vZ28vcmVzb3VyY2VtYW5hZ2VyL2FwaXYzL3Jlc291cmNlbWFuYWdlcnBi
O3Jlc291cmNlbWFuYWdlcnBiqgIfR29vZ2xlLkNsb3VkLlJlc291cmNlTWFuYWdlci5WM8oC
H0dvb2dsZVxDbG91ZFxSZXNvdXJjZU1hbmFnZXJcVjPqAiJHb29nbGU6OkNsb3VkOjpSZXNv
dXJjZU1hbmFnZXI6OlYzSstHCgcSBQ4AiwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkK
AgMDEgMVACMKCQoCAwQSAxYALQoJCgIDBRIDFwAlCggKAQgSAxkAPAoJCgIIJRIDGQA8CggK
AQgSAxoAZAoJCgIICxIDGgBkCggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAMQoJCgII
CBIDHAAxCggKAQgSAx0APAoJCgIIARIDHQA8CggKAQgSAx4APAoJCgIIKRIDHgA8CggKAQgS
Ax8AOwoJCgIILRIDHwA7CpoBCgIGABIEIwBaARqNASBBbGxvdyB1c2VycyB0byBjcmVhdGUg
YW5kIG1hbmFnZSBUYWdCaW5kaW5ncyBiZXR3ZWVuIFRhZ1ZhbHVlcyBhbmQKIGRpZmZlcmVu
dCBHb29nbGUgQ2xvdWQgcmVzb3VyY2VzIHRocm91Z2hvdXQgdGhlIEdDUCByZXNvdXJjZSBo
aWVyYXJjaHkuCgoKCgMGAAESAyMIEwoKCgMGAAMSAyQCSwoMCgUGAAOZCBIDJAJLCgsKAwYA
AxIEJQInQQoNCgUGAAOaCBIEJQInQQrzAQoEBgACABIELgI0AxrkASBMaXN0cyB0aGUgVGFn
QmluZGluZ3MgZm9yIHRoZSBnaXZlbiBHb29nbGUgQ2xvdWQgcmVzb3VyY2UsIGFzIHNwZWNp
ZmllZAogd2l0aCBgcGFyZW50YC4KCiBOT1RFOiBUaGUgYHBhcmVudGAgZmllbGQgaXMgZXhw
ZWN0ZWQgdG8gYmUgYSBmdWxsIHJlc291cmNlIG5hbWU6CiBodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjZnVsbF9yZXNvdXJjZV9uYW1lCgoM
CgUGAAIAARIDLgYVCgwKBQYAAgACEgMuFiwKDAoFBgACAAMSAy8PJgoNCgUGAAIABBIEMAQy
BgoRCgkGAAIABLDKvCISBDAEMgYKDAoFBgACAAQSAzMENAoPCggGAAIABJsIABIDMwQ0ClQK
BAYAAgESBDcCQgMaRiBDcmVhdGVzIGEgVGFnQmluZGluZyBiZXR3ZWVuIGEgVGFnVmFsdWUg
YW5kIGEgR29vZ2xlIENsb3VkIHJlc291cmNlLgoKDAoFBgACAQESAzcGFgoMCgUGAAIBAhID
NxcuCgwKBQYAAgEDEgM4DysKDQoFBgACAQQSBDkEPAYKEQoJBgACAQSwyrwiEgQ5BDwGCgwK
BQYAAgEEEgM9BDkKDwoIBgACAQSbCAASAz0EOQoNCgUGAAIBBBIEPgRBBgoPCgcGAAIBBJkI
EgQ+BEEGCiUKBAYAAgISBEUCTwMaFyBEZWxldGVzIGEgVGFnQmluZGluZy4KCgwKBQYAAgIB
EgNFBhYKDAoFBgACAgISA0UXLgoMCgUGAAICAxIDRg8rCg0KBQYAAgIEEgRHBEkGChEKCQYA
AgIEsMq8IhIERwRJBgoMCgUGAAICBBIDSgQyCg8KCAYAAgIEmwgAEgNKBDIKDQoFBgACAgQS
BEsETgYKDwoHBgACAgSZCBIESwROBgpvCgQGAAIDEgRTAlkDGmEgUmV0dXJuIGEgbGlzdCBv
ZiBlZmZlY3RpdmUgdGFncyBmb3IgdGhlIGdpdmVuIEdvb2dsZSBDbG91ZCByZXNvdXJjZSwg
YXMKIHNwZWNpZmllZCBpbiBgcGFyZW50YC4KCgwKBQYAAgMBEgNTBhcKDAoFBgACAwISA1MY
MAoMCgUGAAIDAxIDVA8oCg0KBQYAAgMEEgRVBFcGChEKCQYAAgMEsMq8IhIEVQRXBgoMCgUG
AAIDBBIDWAQ0Cg8KCAYAAgMEmwgAEgNYBDQKyAEKAgQAEgRfAHoBGrsBIEEgVGFnQmluZGlu
ZyByZXByZXNlbnRzIGEgY29ubmVjdGlvbiBiZXR3ZWVuIGEgVGFnVmFsdWUgYW5kIGEgY2xv
dWQKIHJlc291cmNlIE9uY2UgYSBUYWdCaW5kaW5nIGlzIGNyZWF0ZWQsIHRoZSBUYWdWYWx1
ZSBpcyBhcHBsaWVkIHRvIGFsbCB0aGUKIGRlc2NlbmRhbnRzIG9mIHRoZSBHb29nbGUgQ2xv
dWQgcmVzb3VyY2UuCgoKCgMEAAESA18IEgoLCgMEAAcSBGACYwQKDQoFBAAHnQgSBGACYwQK
6wEKBAQAAgASA2gCPhrdASBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIFRhZ0JpbmRp
bmcuIFRoaXMgaXMgYSBTdHJpbmcgb2YgdGhlIGZvcm06CiBgdGFnQmluZGluZ3Mve2Z1bGwt
cmVzb3VyY2UtbmFtZX0ve3RhZy12YWx1ZS1uYW1lfWAgKGUuZy4KIGB0YWdCaW5kaW5ncy8l
MkYlMkZjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbSUyRnByb2plY3RzJTJG
MTIzL3RhZ1ZhbHVlcy80NTZgKS4KCgwKBQQAAgAFEgNoAggKDAoFBAACAAESA2gJDQoMCgUE
AAIAAxIDaBARCgwKBQQAAgAIEgNoEj0KDwoIBAACAAicCAASA2gTPAqKAQoEBAACARIDbAIU
Gn0gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVzb3VyY2UgdGhlIFRhZ1ZhbHVl
IGlzIGJvdW5kIHRvLgogRS5nLiBgLy9jbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlz
LmNvbS9wcm9qZWN0cy8xMjNgCgoMCgUEAAIBBRIDbAIICgwKBQQAAgEBEgNsCQ8KDAoFBAAC
AQMSA2wSEwpUCgQEAAICEgNwAhcaRyBUaGUgVGFnVmFsdWUgb2YgdGhlIFRhZ0JpbmRpbmcu
CiBNdXN0IGJlIG9mIHRoZSBmb3JtIGB0YWdWYWx1ZXMvNDU2YC4KCgwKBQQAAgIFEgNwAggK
DAoFBAACAgESA3AJEgoMCgUEAAICAxIDcBUWCrUCCgQEAAIDEgN5AicapwIgVGhlIG5hbWVz
cGFjZWQgbmFtZSBmb3IgdGhlIFRhZ1ZhbHVlIG9mIHRoZSBUYWdCaW5kaW5nLgogTXVzdCBi
ZSBpbiB0aGUgZm9ybWF0CiBge3BhcmVudF9pZH0ve3RhZ19rZXlfc2hvcnRfbmFtZX0ve3No
b3J0X25hbWV9YC4KCiBGb3IgbWV0aG9kcyB0aGF0IHN1cHBvcnQgVGFnVmFsdWUgbmFtZXNw
YWNlZCBuYW1lLCBvbmx5IG9uZSBvZgogdGFnX3ZhbHVlX25hbWVzcGFjZWRfbmFtZSBvciB0
YWdfdmFsdWUgbWF5IGJlIGZpbGxlZC4gUmVxdWVzdHMgd2l0aCBib3RoCiBmaWVsZHMgd2ls
bCBiZSByZWplY3RlZC4KCgwKBQQAAgMFEgN5AggKDAoFBAACAwESA3kJIgoMCgUEAAIDAxID
eSUmCkMKAgQBEgN9ACMaOCBSdW50aW1lIG9wZXJhdGlvbiBpbmZvcm1hdGlvbiBmb3IgY3Jl
YXRpbmcgYSBUYWdWYWx1ZS4KCgoKAwQBARIDfQggCjsKAgQCEgaAAQCHAQEaLSBUaGUgcmVx
dWVzdCBtZXNzYWdlIHRvIGNyZWF0ZSBhIFRhZ0JpbmRpbmcuCgoLCgMEAgESBIABCB8KNwoE
BAICABIEggECRhopIFJlcXVpcmVkLiBUaGUgVGFnQmluZGluZyB0byBiZSBjcmVhdGVkLgoK
DQoFBAICAAYSBIIBAgwKDQoFBAICAAESBIIBDRgKDQoFBAICAAMSBIIBGxwKDQoFBAICAAgS
BIIBHUUKEAoIBAICAAicCAASBIIBHkQKiwEKBAQCAgESBIYBAkIafSBPcHRpb25hbC4gU2V0
IHRvIHRydWUgdG8gcGVyZm9ybSB0aGUgdmFsaWRhdGlvbnMgbmVjZXNzYXJ5IGZvciBjcmVh
dGluZyB0aGUKIHJlc291cmNlLCBidXQgbm90IGFjdHVhbGx5IHBlcmZvcm0gdGhlIGFjdGlv
bi4KCg0KBQQCAgEFEgSGAQIGCg0KBQQCAgEBEgSGAQcUCg0KBQQCAgEDEgSGARcYCg0KBQQC
AgEIEgSGARlBChAKCAQCAgEInAgAEgSGARpACkYKAgQDEgSKAQAjGjogUnVudGltZSBvcGVy
YXRpb24gaW5mb3JtYXRpb24gZm9yIGRlbGV0aW5nIGEgVGFnQmluZGluZy4KCgsKAwQDARIE
igEIIAo7CgIEBBIGjQEAlwEBGi0gVGhlIHJlcXVlc3QgbWVzc2FnZSB0byBkZWxldGUgYSBU
YWdCaW5kaW5nLgoKCwoDBAQBEgSNAQgfCsoBCgQEBAIAEgaRAQKWAQQauQEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBUYWdCaW5kaW5nLiBUaGlzIGlzIGEgU3RyaW5nIG9mIHRoZSBm
b3JtOgogYHRhZ0JpbmRpbmdzL3tpZH1gIChlLmcuCiBgdGFnQmluZGluZ3MvJTJGJTJGY2xv
dWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20lMkZwcm9qZWN0cyUyRjEyMy90YWdW
YWx1ZXMvNDU2YCkuCgoNCgUEBAIABRIEkQECCAoNCgUEBAIAARIEkQEJDQoNCgUEBAIAAxIE
kQEQEQoPCgUEBAIACBIGkQESlgEDChAKCAQEAgAInAgAEgSSAQQqChEKBwQEAgAInwgSBpMB
BJUBBQpJCgIEBRIGmgEAqwEBGjsgVGhlIHJlcXVlc3QgbWVzc2FnZSB0byBsaXN0IGFsbCBU
YWdCaW5kaW5ncyBmb3IgYSBwYXJlbnQuCgoLCgMEBQESBJoBCB4KrgEKBAQFAgASBp4BAqEB
BBqdASBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBhIHJlc291cmNlIGZv
ciB3aGljaCB5b3Ugd2FudCB0byBsaXN0CiBleGlzdGluZyBUYWdCaW5kaW5ncy4gRS5nLgog
Ii8vY2xvdWRyZXNvdXJjZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMvMTIzIgoK
DQoFBAUCAAUSBJ4BAggKDQoFBAUCAAESBJ4BCQ8KDQoFBAUCAAMSBJ4BEhMKDwoFBAUCAAgS
Bp4BFKEBAwoQCggEBQIACJwIABIEnwEEKgoPCgcEBQIACJ8IEgSgAQQ5CssBCgQEBQIBEgSm
AQI/GrwBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgVGFnQmluZGluZ3MgdG8g
cmV0dXJuIGluIHRoZSByZXNwb25zZS4gVGhlCiBzZXJ2ZXIgYWxsb3dzIGEgbWF4aW11bSBv
ZiAzMDAgVGFnQmluZGluZ3MgdG8gcmV0dXJuLiBJZiB1bnNwZWNpZmllZCwgdGhlCiBzZXJ2
ZXIgd2lsbCB1c2UgMTAwIGFzIHRoZSBkZWZhdWx0LgoKDQoFBAUCAQUSBKYBAgcKDQoFBAUC
AQESBKYBCBEKDQoFBAUCAQMSBKYBFBUKDQoFBAUCAQgSBKYBFj4KEAoIBAUCAQicCAASBKYB
Fz0KmQEKBAQFAgISBKoBAkEaigEgT3B0aW9uYWwuIEEgcGFnaW5hdGlvbiB0b2tlbiByZXR1
cm5lZCBmcm9tIGEgcHJldmlvdXMgY2FsbCB0bwogYExpc3RUYWdCaW5kaW5nc2AgdGhhdCBp
bmRpY2F0ZXMgd2hlcmUgdGhpcyBsaXN0aW5nIHNob3VsZCBjb250aW51ZSBmcm9tLgoKDQoF
BAUCAgUSBKoBAggKDQoFBAUCAgESBKoBCRMKDQoFBAUCAgMSBKoBFhcKDQoFBAUCAggSBKoB
GEAKEAoIBAUCAgicCAASBKoBGT8KLQoCBAYSBq4BAL4BARofIFRoZSBMaXN0VGFnQmluZGlu
Z3MgcmVzcG9uc2UuCgoLCgMEBgESBK4BCB8KVAoEBAYCABIEsAECJxpGIEEgcG9zc2libHkg
cGFnaW5hdGVkIGxpc3Qgb2YgVGFnQmluZGluZ3MgZm9yIHRoZSBzcGVjaWZpZWQgcmVzb3Vy
Y2UuCgoNCgUEBgIABBIEsAECCgoNCgUEBgIABhIEsAELFQoNCgUEBgIAARIEsAEWIgoNCgUE
BgIAAxIEsAElJgrJAwoEBAYCARIEvQECHRq6AyBQYWdpbmF0aW9uIHRva2VuLgoKIElmIHRo
ZSByZXN1bHQgc2V0IGlzIHRvbyBsYXJnZSB0byBmaXQgaW4gYSBzaW5nbGUgcmVzcG9uc2Us
IHRoaXMgdG9rZW4KIGlzIHJldHVybmVkLiBJdCBlbmNvZGVzIHRoZSBwb3NpdGlvbiBvZiB0
aGUgY3VycmVudCByZXN1bHQgY3Vyc29yLgogRmVlZGluZyB0aGlzIHZhbHVlIGludG8gYSBu
ZXcgbGlzdCByZXF1ZXN0IHdpdGggdGhlIGBwYWdlX3Rva2VuYCBwYXJhbWV0ZXIKIGdpdmVz
IHRoZSBuZXh0IHBhZ2Ugb2YgdGhlIHJlc3VsdHMuCgogV2hlbiBgbmV4dF9wYWdlX3Rva2Vu
YCBpcyBub3QgZmlsbGVkIGluLCB0aGVyZSBpcyBubyBuZXh0IHBhZ2UgYW5kCiB0aGUgbGlz
dCByZXR1cm5lZCBpcyB0aGUgbGFzdCBwYWdlIGluIHRoZSByZXN1bHQgc2V0LgoKIFBhZ2lu
YXRpb24gdG9rZW5zIGhhdmUgYSBsaW1pdGVkIGxpZmV0aW1lLgoKDQoFBAYCAQUSBL0BAggK
DQoFBAYCAQESBL0BCRgKDQoFBAYCAQMSBL0BGxwKOAoCBAcSBsEBAM8BARoqIFRoZSByZXF1
ZXN0IG1lc3NhZ2UgdG8gTGlzdEVmZmVjdGl2ZVRhZ3MKCgsKAwQHARIEwQEIIAqqAQoEBAcC
ABIExQECPRqbASBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBhIHJlc291
cmNlIGZvciB3aGljaCB5b3Ugd2FudCB0byBsaXN0CiB0aGUgZWZmZWN0aXZlIHRhZ3MuIEUu
Zy4KICIvL2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzLzEy
MyIKCg0KBQQHAgAFEgTFAQIICg0KBQQHAgABEgTFAQkPCg0KBQQHAgADEgTFARITCg0KBQQH
AgAIEgTFARQ8ChAKCAQHAgAInAgAEgTFARU7CuIBCgQEBwIBEgTKAQI/GtMBIE9wdGlvbmFs
LiBUaGUgbWF4aW11bSBudW1iZXIgb2YgZWZmZWN0aXZlIHRhZ3MgdG8gcmV0dXJuIGluIHRo
ZSByZXNwb25zZS4KIFRoZSBzZXJ2ZXIgYWxsb3dzIGEgbWF4aW11bSBvZiAzMDAgZWZmZWN0
aXZlIHRhZ3MgdG8gcmV0dXJuIGluIGEgc2luZ2xlCiBwYWdlLiBJZiB1bnNwZWNpZmllZCwg
dGhlIHNlcnZlciB3aWxsIHVzZSAxMDAgYXMgdGhlIGRlZmF1bHQuCgoNCgUEBwIBBRIEygEC
BwoNCgUEBwIBARIEygEIEQoNCgUEBwIBAxIEygEUFQoNCgUEBwIBCBIEygEWPgoQCggEBwIB
CJwIABIEygEXPQqbAQoEBAcCAhIEzgECQRqMASBPcHRpb25hbC4gQSBwYWdpbmF0aW9uIHRv
a2VuIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRvCiBgTGlzdEVmZmVjdGl2ZVRh
Z3NgIHRoYXQgaW5kaWNhdGVzIGZyb20gd2hlcmUgdGhpcyBsaXN0aW5nIHNob3VsZCBjb250
aW51ZS4KCg0KBQQHAgIFEgTOAQIICg0KBQQHAgIBEgTOAQkTCg0KBQQHAgIDEgTOARYXCg0K
BQQHAgIIEgTOARhAChAKCAQHAgIInAgAEgTOARk/CjIKAgQIEgbSAQDiAQEaJCBUaGUgcmVz
cG9uc2Ugb2YgTGlzdEVmZmVjdGl2ZVRhZ3MuCgoLCgMECAESBNIBCCEKVwoEBAgCABIE1AEC
KxpJIEEgcG9zc2libHkgcGFnaW5hdGVkIGxpc3Qgb2YgZWZmZWN0aXZlIHRhZ3MgZm9yIHRo
ZSBzcGVjaWZpZWQgcmVzb3VyY2UuCgoNCgUECAIABBIE1AECCgoNCgUECAIABhIE1AELFwoN
CgUECAIAARIE1AEYJgoNCgUECAIAAxIE1AEpKgrJAwoEBAgCARIE4QECHRq6AyBQYWdpbmF0
aW9uIHRva2VuLgoKIElmIHRoZSByZXN1bHQgc2V0IGlzIHRvbyBsYXJnZSB0byBmaXQgaW4g
YSBzaW5nbGUgcmVzcG9uc2UsIHRoaXMgdG9rZW4KIGlzIHJldHVybmVkLiBJdCBlbmNvZGVz
IHRoZSBwb3NpdGlvbiBvZiB0aGUgY3VycmVudCByZXN1bHQgY3Vyc29yLgogRmVlZGluZyB0
aGlzIHZhbHVlIGludG8gYSBuZXcgbGlzdCByZXF1ZXN0IHdpdGggdGhlIGBwYWdlX3Rva2Vu
YCBwYXJhbWV0ZXIKIGdpdmVzIHRoZSBuZXh0IHBhZ2Ugb2YgdGhlIHJlc3VsdHMuCgogV2hl
biBgbmV4dF9wYWdlX3Rva2VuYCBpcyBub3QgZmlsbGVkIGluLCB0aGVyZSBpcyBubyBuZXh0
IHBhZ2UgYW5kCiB0aGUgbGlzdCByZXR1cm5lZCBpcyB0aGUgbGFzdCBwYWdlIGluIHRoZSBy
ZXN1bHQgc2V0LgoKIFBhZ2luYXRpb24gdG9rZW5zIGhhdmUgYSBsaW1pdGVkIGxpZmV0aW1l
LgoKDQoFBAgCAQUSBOEBAggKDQoFBAgCAQESBOEBCRgKDQoFBAgCAQMSBOEBGxwK6gIKAgQJ
EgbpAQCLAgEa2wIgQW4gRWZmZWN0aXZlVGFnIHJlcHJlc2VudHMgYSB0YWcgdGhhdCBhcHBs
aWVzIHRvIGEgcmVzb3VyY2UgZHVyaW5nIHBvbGljeQogZXZhbHVhdGlvbi4gVGFncyBjYW4g
YmUgZWl0aGVyIGRpcmVjdGx5IGJvdW5kIHRvIGEgcmVzb3VyY2Ugb3IgaW5oZXJpdGVkIGZy
b20KIGl0cyBhbmNlc3Rvci4gRWZmZWN0aXZlVGFnIGNvbnRhaW5zIHRoZSBuYW1lIGFuZAog
bmFtZXNwYWNlZF9uYW1lIG9mIHRoZSB0YWcgdmFsdWUgYW5kIHRhZyBrZXksIHdpdGggYWRk
aXRpb25hbCBmaWVsZHMgb2YKIGBpbmhlcml0ZWRgIHRvIGluZGljYXRlIHRoZSBpbmhlcml0
YW5jZSBzdGF0dXMgb2YgdGhlIGVmZmVjdGl2ZSB0YWcuCgoLCgMECQESBOkBCBQKSwoEBAkC
ABIG6wEC7QEFGjsgUmVzb3VyY2UgbmFtZSBmb3IgVGFnVmFsdWUgaW4gdGhlIGZvcm1hdCBg
dGFnVmFsdWVzLzQ1NmAuCgoNCgUECQIABRIE6wECCAoNCgUECQIAARIE6wEJEgoNCgUECQIA
AxIE6wEVFgoPCgUECQIACBIG6wEX7QEEChEKBwQJAgAInwgSBusBGO0BAwqMAgoEBAkCARIE
8wECIhr9ASBUaGUgbmFtZXNwYWNlZCBuYW1lIG9mIHRoZSBUYWdWYWx1ZS4gQ2FuIGJlIGlu
IHRoZSBmb3JtCiBge29yZ2FuaXphdGlvbl9pZH0ve3RhZ19rZXlfc2hvcnRfbmFtZX0ve3Rh
Z192YWx1ZV9zaG9ydF9uYW1lfWAgb3IKIGB7cHJvamVjdF9pZH0ve3RhZ19rZXlfc2hvcnRf
bmFtZX0ve3RhZ192YWx1ZV9zaG9ydF9uYW1lfWAgb3IKIGB7cHJvamVjdF9udW1iZXJ9L3t0
YWdfa2V5X3Nob3J0X25hbWV9L3t0YWdfdmFsdWVfc2hvcnRfbmFtZX1gLgoKDQoFBAkCAQUS
BPMBAggKDQoFBAkCAQESBPMBCR0KDQoFBAkCAQMSBPMBICEKXwoEBAkCAhIG9wEC+QEFGk8g
VGhlIG5hbWUgb2YgdGhlIFRhZ0tleSwgaW4gdGhlIGZvcm1hdCBgdGFnS2V5cy97aWR9YCwg
c3VjaCBhcwogYHRhZ0tleXMvMTIzYC4KCg0KBQQJAgIFEgT3AQIICg0KBQQJAgIBEgT3AQkQ
Cg0KBQQJAgIDEgT3ARMUCg8KBQQJAgIIEgb3ARX5AQQKEQoHBAkCAgifCBIG9wEW+QEDCsUB
CgQECQIDEgT/AQIgGrYBIFRoZSBuYW1lc3BhY2VkIG5hbWUgb2YgdGhlIFRhZ0tleS4gQ2Fu
IGJlIGluIHRoZSBmb3JtCiBge29yZ2FuaXphdGlvbl9pZH0ve3RhZ19rZXlfc2hvcnRfbmFt
ZX1gIG9yCiBge3Byb2plY3RfaWR9L3t0YWdfa2V5X3Nob3J0X25hbWV9YCBvcgogYHtwcm9q
ZWN0X251bWJlcn0ve3RhZ19rZXlfc2hvcnRfbmFtZX1gLgoKDQoFBAkCAwUSBP8BAggKDQoF
BAkCAwESBP8BCRsKDQoFBAkCAwMSBP8BHh8KiAEKBAQJAgQSBIQCAiEaeiBUaGUgcGFyZW50
IG5hbWUgb2YgdGhlIHRhZyBrZXkuCiBNdXN0IGJlIGluIHRoZSBmb3JtYXQgYG9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbl9pZH1gIG9yCiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVy
fWAKCg0KBQQJAgQFEgSEAgIICg0KBQQJAgQBEgSEAgkcCg0KBQQJAgQDEgSEAh8gCpsCCgQE
CQIFEgSKAgIVGowCIEluZGljYXRlcyB0aGUgaW5oZXJpdGFuY2Ugc3RhdHVzIG9mIGEgdGFn
IHZhbHVlCiBhdHRhY2hlZCB0byB0aGUgZ2l2ZW4gcmVzb3VyY2UuIElmIHRoZSB0YWcgdmFs
dWUgaXMgaW5oZXJpdGVkIGZyb20gb25lIG9mCiB0aGUgcmVzb3VyY2UncyBhbmNlc3RvcnMs
IGluaGVyaXRlZCB3aWxsIGJlIHRydWUuIElmIGZhbHNlLCB0aGVuIHRoZSB0YWcKIHZhbHVl
IGlzIGRpcmVjdGx5IGF0dGFjaGVkIHRvIHRoZSByZXNvdXJjZSwgaW5oZXJpdGVkIHdpbGwg
YmUgZmFsc2UuCgoNCgUECQIFBRIEigICBgoNCgUECQIFARIEigIHEAoNCgUECQIFAxIEigIT
FGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding ===
    # Fields for TagBinding
    # Field: name Type: 9 ()
    # Field: parent Type: 9 ()
    # Field: tag_value Type: 9 ()
    # Field: tag_value_namespaced_name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingMetadata ===
    # Fields for CreateTagBindingMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest ===
    # Fields for CreateTagBindingRequest
    # Field: tag_binding Type: 11 (.google.cloud.resourcemanager.v3.TagBinding)
    # Field: validate_only Type: 8 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingMetadata ===
    # Fields for DeleteTagBindingMetadata

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest ===
    # Fields for DeleteTagBindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest ===
    # Fields for ListTagBindingsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse ===
    # Fields for ListTagBindingsResponse
    # Field: tag_bindings Type: 11 (.google.cloud.resourcemanager.v3.TagBinding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest ===
    # Fields for ListEffectiveTagsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse ===
    # Fields for ListEffectiveTagsResponse
    # Field: effective_tags Type: 11 (.google.cloud.resourcemanager.v3.EffectiveTag)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag ===
    # Fields for EffectiveTag
    # Field: tag_value Type: 9 ()
    # Field: namespaced_tag_value Type: 9 ()
    # Field: tag_key Type: 9 ()
    # Field: namespaced_tag_key Type: 9 ()
    # Field: tag_key_parent_name Type: 9 ()
    # Field: inherited Type: 8 ()

# === Service Client: Google::Cloud::Resourcemanager::V3::TagBindings::TagBindingsClient ===
package Google::Cloud::Resourcemanager::V3::TagBindings::TagBindingsClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V3::TagBindings::TagBindingsClient

Client stub representing the remote C<TagBindings> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

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

sub list_tag_bindings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'ListTagBindings',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse',
    });
}

sub create_tag_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'CreateTagBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_tag_binding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'DeleteTagBinding',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_effective_tags {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'ListEffectiveTags',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagBindings - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v3/tag_bindings.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::TagBindings;

    my $msg = Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding->new({
        name => $name,
        parent => $parent,
        tag_value => $tag_value,
        tag_value_namespaced_name => $tag_value_namespaced_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v3/tag_bindings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding

A TagBinding represents a connection between a TagValue and a cloud
resource Once a TagBinding is created, the TagValue is applied to all the
descendants of the Google Cloud resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of the TagBinding. This is a String of the form:
`tagBindings/{full-resource-name}/{tag-value-name}` (e.g.
`tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Fprojects%2F123/tagValues/456`).

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The full resource name of the resource the TagValue is bound to.
E.g. `//cloudresourcemanager.googleapis.com/projects/123`

=item * C<< $msg->tag_value() >> / C<< $msg->tag_value($value) >>

Type: C<String>

The TagValue of the TagBinding.
Must be of the form `tagValues/456`.

=item * C<< $msg->tag_value_namespaced_name() >> / C<< $msg->tag_value_namespaced_name($value) >>

Type: C<String>

The namespaced name for the TagValue of the TagBinding.
Must be in the format
`{parent_id}/{tag_key_short_name}/{short_name}`.

For methods that support TagValue namespaced name, only one of
tag_value_namespaced_name or tag_value may be filled. Requests with both
fields will be rejected.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingMetadata

Runtime operation information for creating a TagValue.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest

The request message to create a TagBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_binding() >> / C<< $msg->tag_binding($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding>)

Required. The TagBinding to be created.

=item * C<< $msg->validate_only() >> / C<< $msg->validate_only($value) >>

Type: C<Bool>

Optional. Set to true to perform the validations necessary for creating the
resource, but not actually perform the action.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingMetadata

Runtime operation information for deleting a TagBinding.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest

The request message to delete a TagBinding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the TagBinding. This is a String of the form:
`tagBindings/{id}` (e.g.
`tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Fprojects%2F123/tagValues/456`).

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest

The request message to list all TagBindings for a parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The full resource name of a resource for which you want to list
existing TagBindings. E.g.
"//cloudresourcemanager.googleapis.com/projects/123"

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of TagBindings to return in the response. The
server allows a maximum of 300 TagBindings to return. If unspecified, the
server will use 100 as the default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
`ListTagBindings` that indicates where this listing should continue from.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse

The ListTagBindings response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_bindings() >> / C<< $msg->tag_bindings($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding>)

A possibly paginated list of TagBindings for the specified resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token.

If the result set is too large to fit in a single response, this token
is returned. It encodes the position of the current result cursor.
Feeding this value into a new list request with the `page_token` parameter
gives the next page of the results.

When `next_page_token` is not filled in, there is no next page and
the list returned is the last page in the result set.

Pagination tokens have a limited lifetime.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest

The request message to ListEffectiveTags

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The full resource name of a resource for which you want to list
the effective tags. E.g.
"//cloudresourcemanager.googleapis.com/projects/123"

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of effective tags to return in the response.
The server allows a maximum of 300 effective tags to return in a single
page. If unspecified, the server will use 100 as the default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
`ListEffectiveTags` that indicates from where this listing should continue.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse

The response of ListEffectiveTags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->effective_tags() >> / C<< $msg->effective_tags($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag>)

A possibly paginated list of effective tags for the specified resource.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token.

If the result set is too large to fit in a single response, this token
is returned. It encodes the position of the current result cursor.
Feeding this value into a new list request with the `page_token` parameter
gives the next page of the results.

When `next_page_token` is not filled in, there is no next page and
the list returned is the last page in the result set.

Pagination tokens have a limited lifetime.

=back

=head2 Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag

An EffectiveTag represents a tag that applies to a resource during policy
evaluation. Tags can be either directly bound to a resource or inherited from
its ancestor. EffectiveTag contains the name and
namespaced_name of the tag value and tag key, with additional fields of
`inherited` to indicate the inheritance status of the effective tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag_value() >> / C<< $msg->tag_value($value) >>

Type: C<String>

Resource name for TagValue in the format `tagValues/456`.

=item * C<< $msg->namespaced_tag_value() >> / C<< $msg->namespaced_tag_value($value) >>

Type: C<String>

The namespaced name of the TagValue. Can be in the form
`{organization_id}/{tag_key_short_name}/{tag_value_short_name}` or
`{project_id}/{tag_key_short_name}/{tag_value_short_name}` or
`{project_number}/{tag_key_short_name}/{tag_value_short_name}`.

=item * C<< $msg->tag_key() >> / C<< $msg->tag_key($value) >>

Type: C<String>

The name of the TagKey, in the format `tagKeys/{id}`, such as
`tagKeys/123`.

=item * C<< $msg->namespaced_tag_key() >> / C<< $msg->namespaced_tag_key($value) >>

Type: C<String>

The namespaced name of the TagKey. Can be in the form
`{organization_id}/{tag_key_short_name}` or
`{project_id}/{tag_key_short_name}` or
`{project_number}/{tag_key_short_name}`.

=item * C<< $msg->tag_key_parent_name() >> / C<< $msg->tag_key_parent_name($value) >>

Type: C<String>

The parent name of the tag key.
Must be in the format `organizations/{organization_id}` or
`projects/{project_number}`

=item * C<< $msg->inherited() >> / C<< $msg->inherited($value) >>

Type: C<Bool>

Indicates the inheritance status of a tag value
attached to the given resource. If the tag value is inherited from one of
the resource's ancestors, inherited will be true. If false, then the tag
value is directly attached to the resource, inherited will be false.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V3::TagBindings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
