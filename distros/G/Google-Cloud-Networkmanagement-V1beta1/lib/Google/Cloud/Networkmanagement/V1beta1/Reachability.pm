package Google::Cloud::Networkmanagement::V1beta1::Reachability;

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
    eval { require Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjFiZXRhMS9yZWFjaGFiaWxpdHku
cHJvdG8SJmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJldGExGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo+
Z29vZ2xlL2Nsb3VkL25ldHdvcmttYW5hZ2VtZW50L3YxYmV0YTEvY29ubmVjdGl2aXR5X3Rl
c3QucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
Gh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItoBChxMaXN0Q29ubmVjdGl2aXR5
VGVzdHNSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFu
YWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgF
UghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQg
ASgJUgZmaWx0ZXISGQoIb3JkZXJfYnkYBSABKAlSB29yZGVyQnkiwQEKHUxpc3RDb25uZWN0
aXZpdHlUZXN0c1Jlc3BvbnNlElYKCXJlc291cmNlcxgBIAMoCzI4Lmdvb2dsZS5jbG91ZC5u
ZXR3b3JrbWFuYWdlbWVudC52MWJldGExLkNvbm5lY3Rpdml0eVRlc3RSCXJlc291cmNlcxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUY
AyADKAlSC3VucmVhY2hhYmxlImsKGkdldENvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0Ek0KBG5h
bWUYASABKAlCOeBBAvpBMwoxbmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb20vQ29u
bmVjdGl2aXR5VGVzdFIEbmFtZSLlAQodQ3JlYXRlQ29ubmVjdGl2aXR5VGVzdFJlcXVlc3QS
SwoGcGFyZW50GAEgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFw
aXMuY29tL1Byb2plY3RSBnBhcmVudBIcCgd0ZXN0X2lkGAIgASgJQgPgQQJSBnRlc3RJZBJZ
CghyZXNvdXJjZRgDIAEoCzI4Lmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJl
dGExLkNvbm5lY3Rpdml0eVRlc3RCA+BBAlIIcmVzb3VyY2UivAEKHVVwZGF0ZUNvbm5lY3Rp
dml0eVRlc3RSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3RvYnVm
LkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrElkKCHJlc291cmNlGAIgASgLMjguZ29vZ2xl
LmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuQ29ubmVjdGl2aXR5VGVzdEID4EEC
UghyZXNvdXJjZSJuCh1EZWxldGVDb25uZWN0aXZpdHlUZXN0UmVxdWVzdBJNCgRuYW1lGAEg
ASgJQjngQQL6QTMKMW5ldHdvcmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL0Nvbm5lY3Rp
dml0eVRlc3RSBG5hbWUibQocUmVydW5Db25uZWN0aXZpdHlUZXN0UmVxdWVzdBJNCgRuYW1l
GAEgASgJQjngQQL6QTMKMW5ldHdvcmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL0Nvbm5l
Y3Rpdml0eVRlc3RSBG5hbWUipAIKEU9wZXJhdGlvbk1ldGFkYXRhEjsKC2NyZWF0ZV90aW1l
GAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI1CghlbmRf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSFgoGdGFy
Z2V0GAMgASgJUgZ0YXJnZXQSEgoEdmVyYhgEIAEoCVIEdmVyYhIjCg1zdGF0dXNfZGV0YWls
GAUgASgJUgxzdGF0dXNEZXRhaWwSKQoQY2FuY2VsX3JlcXVlc3RlZBgGIAEoCFIPY2FuY2Vs
UmVxdWVzdGVkEh8KC2FwaV92ZXJzaW9uGAcgASgJUgphcGlWZXJzaW9uMqMNChNSZWFjaGFi
aWxpdHlTZXJ2aWNlEu0BChVMaXN0Q29ubmVjdGl2aXR5VGVzdHMSRC5nb29nbGUuY2xvdWQu
bmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5MaXN0Q29ubmVjdGl2aXR5VGVzdHNSZXF1ZXN0
GkUuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuTGlzdENvbm5lY3Rp
dml0eVRlc3RzUmVzcG9uc2UiR4LT5JMCQRI/L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy9nbG9iYWx9L2Nvbm5lY3Rpdml0eVRlc3RzEtwBChNHZXRDb25uZWN0aXZp
dHlUZXN0EkIuZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuR2V0Q29u
bmVjdGl2aXR5VGVzdFJlcXVlc3QaOC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQu
djFiZXRhMS5Db25uZWN0aXZpdHlUZXN0IkeC0+STAkESPy92MWJldGExL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy8qfRKhAgoWQ3JlYXRl
Q29ubmVjdGl2aXR5VGVzdBJFLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MWJl
dGExLkNyZWF0ZUNvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiKgAYLT5JMCSyI/L3YxYmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy9nbG9iYWx9L2Nvbm5lY3Rpdml0eVRlc3RzOghyZXNvdXJjZcpBTAo3Z29vZ2xlLmNs
b3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxYmV0YTEuQ29ubmVjdGl2aXR5VGVzdBIRT3BlcmF0
aW9uTWV0YWRhdGESqgIKFlVwZGF0ZUNvbm5lY3Rpdml0eVRlc3QSRS5nb29nbGUuY2xvdWQu
bmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5VcGRhdGVDb25uZWN0aXZpdHlUZXN0UmVxdWVz
dBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iqQGC0+STAlQySC92MWJldGExL3ty
ZXNvdXJjZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlU
ZXN0cy8qfToIcmVzb3VyY2XKQUwKN2dvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52
MWJldGExLkNvbm5lY3Rpdml0eVRlc3QSEU9wZXJhdGlvbk1ldGFkYXRhEp4CChVSZXJ1bkNv
bm5lY3Rpdml0eVRlc3QSRC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjFiZXRh
MS5SZXJ1bkNvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiKfAYLT5JMCSiJFL3YxYmV0YTEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Z2xvYmFsL2Nvbm5lY3Rpdml0eVRlc3RzLyp9OnJlcnVuOgEqykFMCjdnb29nbGUuY2xvdWQu
bmV0d29ya21hbmFnZW1lbnQudjFiZXRhMS5Db25uZWN0aXZpdHlUZXN0EhFPcGVyYXRpb25N
ZXRhZGF0YRL0AQoWRGVsZXRlQ29ubmVjdGl2aXR5VGVzdBJFLmdvb2dsZS5jbG91ZC5uZXR3
b3JrbWFuYWdlbWVudC52MWJldGExLkRlbGV0ZUNvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ0gtPkkwJBKj8vdjFiZXRhMS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY29ubmVjdGl2aXR5VGVzdHMvKn3KQSoKFWdv
b2dsZS5wcm90b2J1Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEaVMpBIG5ldHdvcmttYW5h
Z2VtZW50Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybUKgAgoqY29tLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVu
dC52MWJldGExQhhSZWFjaGFiaWxpdHlTZXJ2aWNlUHJvdG9QAVpYY2xvdWQuZ29vZ2xlLmNv
bS9nby9uZXR3b3JrbWFuYWdlbWVudC9hcGl2MWJldGExL25ldHdvcmttYW5hZ2VtZW50cGI7
bmV0d29ya21hbmFnZW1lbnRwYqoCJkdvb2dsZS5DbG91ZC5OZXR3b3JrTWFuYWdlbWVudC5W
MUJldGExygImR29vZ2xlXENsb3VkXE5ldHdvcmtNYW5hZ2VtZW50XFYxYmV0YTHqAilHb29n
bGU6OkNsb3VkOjpOZXR3b3JrTWFuYWdlbWVudDo6VjFiZXRhMUqsSQoHEgUOAK8CAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAEgKCQoCAwUSAxcALQoJ
CgIDBhIDGAAlCgkKAgMHEgMZACoKCQoCAwgSAxoAKQoICgEIEgMcAEMKCQoCCCUSAxwAQwoI
CgEIEgMdAG8KCQoCCAsSAx0AbwoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADkKCQoC
CAgSAx8AOQoICgEIEgMgAEMKCQoCCAESAyAAQwoICgEIEgMhAEMKCQoCCCkSAyEAQwoICgEI
EgMiAEIKCQoCCC0SAyIAQgqqBAoCBgASBS4AmQEBGtkDIFRoZSBSZWFjaGFiaWxpdHkgc2Vy
dmljZSBpbiB0aGUgR29vZ2xlIENsb3VkIE5ldHdvcmsgTWFuYWdlbWVudCBBUEkgcHJvdmlk
ZXMKIHNlcnZpY2VzIHRoYXQgYW5hbHl6ZSB0aGUgcmVhY2hhYmlsaXR5IHdpdGhpbiBhIHNp
bmdsZSBHb29nbGUgVmlydHVhbCBQcml2YXRlCiBDbG91ZCAoVlBDKSBuZXR3b3JrLCBiZXR3
ZWVuIHBlZXJlZCBWUEMgbmV0d29ya3MsIGJldHdlZW4gVlBDIGFuZCBvbi1wcmVtaXNlcwog
bmV0d29ya3MsIG9yIGJldHdlZW4gVlBDIG5ldHdvcmtzIGFuZCBpbnRlcm5ldCBob3N0cy4g
QSByZWFjaGFiaWxpdHkgYW5hbHlzaXMKIGlzIGJhc2VkIG9uIEdvb2dsZSBDbG91ZCBuZXR3
b3JrIGNvbmZpZ3VyYXRpb25zLgoKIFlvdSBjYW4gdXNlIHRoZSBhbmFseXNpcyByZXN1bHRz
IHRvIHZlcmlmeSB0aGVzZSBjb25maWd1cmF0aW9ucyBhbmQKIHRvIHRyb3VibGVzaG9vdCBj
b25uZWN0aXZpdHkgaXNzdWVzLgoyQSBUaGUgUmVhY2hhYmlsaXR5IHNlcnZpY2UgaW4gR29v
Z2xlIENsb3VkIE5ldHdvcmsgTWFuYWdlbWVudCBBUEkKCgoKAwYAARIDLggbCgoKAwYAAxID
LwJICgwKBQYAA5kIEgMvAkgKCwoDBgADEgQwAjE3Cg0KBQYAA5oIEgQwAjE3CkAKBAYAAgAS
BDQCOQMaMiBMaXN0cyBhbGwgQ29ubmVjdGl2aXR5IFRlc3RzIG93bmVkIGJ5IGEgcHJvamVj
dC4KCgwKBQYAAgABEgM0BhsKDAoFBgACAAISAzQcOAoMCgUGAAIAAxIDNQ8sCg0KBQYAAgAE
EgQ2BDgGChEKCQYAAgAEsMq8IhIENgQ4BgpBCgQGAAIBEgQ8AkEDGjMgR2V0cyB0aGUgZGV0
YWlscyBvZiBhIHNwZWNpZmljIENvbm5lY3Rpdml0eSBUZXN0LgoKDAoFBgACAQESAzwGGQoM
CgUGAAIBAhIDPBo0CgwKBQYAAgEDEgM9Dx8KDQoFBgACAQQSBD4EQAYKEQoJBgACAQSwyrwi
EgQ+BEAGCqoFCgQGAAICEgRQAloDGpsFIENyZWF0ZXMgYSBuZXcgQ29ubmVjdGl2aXR5IFRl
c3QuCiBBZnRlciB5b3UgY3JlYXRlIGEgdGVzdCwgdGhlIHJlYWNoYWJpbGl0eSBhbmFseXNp
cyBpcyBwZXJmb3JtZWQgYXMgcGFydAogb2YgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24s
IHdoaWNoIGNvbXBsZXRlcyB3aGVuIHRoZSBhbmFseXNpcyBjb21wbGV0ZXMuCgogSWYgdGhl
IGVuZHBvaW50IHNwZWNpZmljYXRpb25zIGluIGBDb25uZWN0aXZpdHlUZXN0YCBhcmUgaW52
YWxpZAogKGZvciBleGFtcGxlLCBjb250YWluaW5nIG5vbi1leGlzdGVudCByZXNvdXJjZXMg
aW4gdGhlIG5ldHdvcmssIG9yIHlvdQogZG9uJ3QgaGF2ZSByZWFkIHBlcm1pc3Npb25zIHRv
IHRoZSBuZXR3b3JrIGNvbmZpZ3VyYXRpb25zIG9mIGxpc3RlZAogcHJvamVjdHMpLCB0aGVu
IHRoZSByZWFjaGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2YWx1ZSBvZiBgVU5LTk9XTmAu
CgogSWYgdGhlIGVuZHBvaW50IHNwZWNpZmljYXRpb25zIGluIGBDb25uZWN0aXZpdHlUZXN0
YCBhcmUKIGluY29tcGxldGUsIHRoZSByZWFjaGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2
YWx1ZSBvZgogPGNvZGU+QU1CSUdVT1VTPC9jb2RlPi4gRm9yIG1vcmUgaW5mb3JtYXRpb24s
CiBzZWUgdGhlIENvbm5lY3Rpdml0eSBUZXN0IGRvY3VtZW50YXRpb24uCgoMCgUGAAICARID
UAYcCgwKBQYAAgICEgNQHToKDAoFBgACAgMSA1EPKwoNCgUGAAICBBIEUgRVBgoRCgkGAAIC
BLDKvCISBFIEVQYKDQoFBgACAgQSBFYEWQYKDwoHBgACAgSZCBIEVgRZBgqcBgoEBgACAxIE
agJ0AxqNBiBVcGRhdGVzIHRoZSBjb25maWd1cmF0aW9uIG9mIGFuIGV4aXN0aW5nIGBDb25u
ZWN0aXZpdHlUZXN0YC4KIEFmdGVyIHlvdSB1cGRhdGUgYSB0ZXN0LCB0aGUgcmVhY2hhYmls
aXR5IGFuYWx5c2lzIGlzIHBlcmZvcm1lZCBhcyBwYXJ0CiBvZiB0aGUgbG9uZyBydW5uaW5n
IG9wZXJhdGlvbiwgd2hpY2ggY29tcGxldGVzIHdoZW4gdGhlIGFuYWx5c2lzIGNvbXBsZXRl
cy4KIFRoZSBSZWFjaGFiaWxpdHkgc3RhdGUgaW4gdGhlIHRlc3QgcmVzb3VyY2UgaXMgdXBk
YXRlZCB3aXRoIHRoZSBuZXcgcmVzdWx0LgoKIElmIHRoZSBlbmRwb2ludCBzcGVjaWZpY2F0
aW9ucyBpbiBgQ29ubmVjdGl2aXR5VGVzdGAgYXJlIGludmFsaWQKIChmb3IgZXhhbXBsZSwg
dGhleSBjb250YWluIG5vbi1leGlzdGVudCByZXNvdXJjZXMgaW4gdGhlIG5ldHdvcmssIG9y
IHRoZQogdXNlciBkb2VzIG5vdCBoYXZlIHJlYWQgcGVybWlzc2lvbnMgdG8gdGhlIG5ldHdv
cmsgY29uZmlndXJhdGlvbnMgb2YKIGxpc3RlZCBwcm9qZWN0cyksIHRoZW4gdGhlIHJlYWNo
YWJpbGl0eSByZXN1bHQgcmV0dXJucyBhIHZhbHVlIG9mCiA8Y29kZT5VTktOT1dOPC9jb2Rl
Pi4KCiBJZiB0aGUgZW5kcG9pbnQgc3BlY2lmaWNhdGlvbnMgaW4gYENvbm5lY3Rpdml0eVRl
c3RgIGFyZSBpbmNvbXBsZXRlLCB0aGUKIHJlYWNoYWJpbGl0eSByZXN1bHQgcmV0dXJucyBh
IHZhbHVlIG9mIGBBTUJJR1VPVVNgLiBTZWUgdGhlIGRvY3VtZW50YXRpb24KIGluIGBDb25u
ZWN0aXZpdHlUZXN0YCBmb3IgbW9yZSBkZXRhaWxzLgoKDAoFBgACAwESA2oGHAoMCgUGAAID
AhIDah06CgwKBQYAAgMDEgNrDysKDQoFBgACAwQSBGwEbwYKEQoJBgACAwSwyrwiEgRsBG8G
Cg0KBQYAAgMEEgRwBHMGCg8KBwYAAgMEmQgSBHAEcwYK9wQKBAYAAgQSBoIBAowBAxrmBCBS
ZXJ1biBhbiBleGlzdGluZyBgQ29ubmVjdGl2aXR5VGVzdGAuCiBBZnRlciB0aGUgdXNlciB0
cmlnZ2VycyB0aGUgcmVydW4sIHRoZSByZWFjaGFiaWxpdHkgYW5hbHlzaXMgaXMgcGVyZm9y
bWVkCiBhcyBwYXJ0IG9mIHRoZSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uLCB3aGljaCBjb21w
bGV0ZXMgd2hlbiB0aGUgYW5hbHlzaXMKIGNvbXBsZXRlcy4KCiBFdmVuIHRob3VnaCB0aGUg
dGVzdCBjb25maWd1cmF0aW9uIHJlbWFpbnMgdGhlIHNhbWUsIHRoZSByZWFjaGFiaWxpdHkK
IHJlc3VsdCBtYXkgY2hhbmdlIGR1ZSB0byB1bmRlcmx5aW5nIG5ldHdvcmsgY29uZmlndXJh
dGlvbiBjaGFuZ2VzLgoKIElmIHRoZSBlbmRwb2ludCBzcGVjaWZpY2F0aW9ucyBpbiBgQ29u
bmVjdGl2aXR5VGVzdGAgYmVjb21lIGludmFsaWQgKGZvcgogZXhhbXBsZSwgc3BlY2lmaWVk
IHJlc291cmNlcyBhcmUgZGVsZXRlZCBpbiB0aGUgbmV0d29yaywgb3IgeW91IGxvc3QKIHJl
YWQgcGVybWlzc2lvbnMgdG8gdGhlIG5ldHdvcmsgY29uZmlndXJhdGlvbnMgb2YgbGlzdGVk
IHByb2plY3RzKSwgdGhlbgogdGhlIHJlYWNoYWJpbGl0eSByZXN1bHQgcmV0dXJucyBhIHZh
bHVlIG9mIGBVTktOT1dOYC4KCg0KBQYAAgQBEgSCAQYbCg0KBQYAAgQCEgSCARw4Cg0KBQYA
AgQDEgSDAQ8rCg8KBQYAAgQEEgaEAQSHAQYKEwoJBgACBASwyrwiEgaEAQSHAQYKDwoFBgAC
BAQSBogBBIsBBgoRCgcGAAIEBJkIEgaIAQSLAQYKOAoEBgACBRIGjwECmAEDGiggRGVsZXRl
cyBhIHNwZWNpZmljIGBDb25uZWN0aXZpdHlUZXN0YC4KCg0KBQYAAgUBEgSPAQYcCg0KBQYA
AgUCEgSPAR06Cg0KBQYAAgUDEgSQAQ8rCg8KBQYAAgUEEgaRAQSTAQYKEwoJBgACBQSwyrwi
EgaRAQSTAQYKDwoFBgACBQQSBpQBBJcBBgoRCgcGAAIFBJkIEgaUAQSXAQYKPwoCBAASBpwB
AMIBARoxIFJlcXVlc3QgZm9yIHRoZSBgTGlzdENvbm5lY3Rpdml0eVRlc3RzYCBtZXRob2Qu
CgoLCgMEAAESBJwBCCQKeAoEBAACABIGnwECpAEEGmggUmVxdWlyZWQuIFRoZSBwYXJlbnQg
cmVzb3VyY2Ugb2YgdGhlIENvbm5lY3Rpdml0eSBUZXN0czoKICAgICBgcHJvamVjdHMve3By
b2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWxgCgoNCgUEAAIABRIEnwECCAoNCgUEAAIAARIE
nwEJDwoNCgUEAAIAAxIEnwESEwoPCgUEAAIACBIGnwEUpAEDChAKCAQAAgAInAgAEgSgAQQq
ChEKBwQAAgAInwgSBqEBBKMBBQo4CgQEAAIBEgSnAQIWGiogTnVtYmVyIG9mIGBDb25uZWN0
aXZpdHlUZXN0c2AgdG8gcmV0dXJuLgoKDQoFBAACAQUSBKcBAgcKDQoFBAACAQESBKcBCBEK
DQoFBAACAQMSBKcBFBUKUwoEBAACAhIEqgECGBpFIFBhZ2UgdG9rZW4gZnJvbSBhbiBlYXJs
aWVyIHF1ZXJ5LCBhcyByZXR1cm5lZCBpbiBgbmV4dF9wYWdlX3Rva2VuYC4KCg0KBQQAAgIF
EgSqAQIICg0KBQQAAgIBEgSqAQkTCg0KBQQAAgIDEgSqARYXCusFCgQEAAIDEgS+AQIUGtwF
IExpc3RzIHRoZSBgQ29ubmVjdGl2aXR5VGVzdHNgIHRoYXQgbWF0Y2ggdGhlIGZpbHRlciBl
eHByZXNzaW9uLiBBIGZpbHRlcgogZXhwcmVzc2lvbiBmaWx0ZXJzIHRoZSByZXNvdXJjZXMg
bGlzdGVkIGluIHRoZSByZXNwb25zZS4gVGhlIGV4cHJlc3Npb24KIG11c3QgYmUgb2YgdGhl
IGZvcm0gYDxmaWVsZD4gPG9wZXJhdG9yPiA8dmFsdWU+YCB3aGVyZSBvcGVyYXRvcnM6IGA8
YCwgYD5gLAogYDw9YCwKIGA+PWAsCiBgIT1gLCBgPWAsIGA6YCBhcmUgc3VwcG9ydGVkIChj
b2xvbiBgOmAgcmVwcmVzZW50cyBhIEhBUyBvcGVyYXRvciB3aGljaCBpcwogcm91Z2hseSBz
eW5vbnltb3VzIHdpdGggZXF1YWxpdHkpLiA8ZmllbGQ+IGNhbiByZWZlciB0byBhIHByb3Rv
IG9yIEpTT04KIGZpZWxkLCBvciBhIHN5bnRoZXRpYyBmaWVsZC4gRmllbGQgbmFtZXMgY2Fu
IGJlIGNhbWVsQ2FzZSBvciBzbmFrZV9jYXNlLgoKIEV4YW1wbGVzOgogLSBGaWx0ZXIgYnkg
bmFtZToKICAgbmFtZSA9ICJwcm9qZWN0cy9wcm9qLTEvbG9jYXRpb25zL2dsb2JhbC9jb25u
ZWN0aXZpdHlUZXN0cy90ZXN0LTEKCiAtIEZpbHRlciBieSBsYWJlbHM6CiAgIC0gUmVzb3Vy
Y2VzIHRoYXQgaGF2ZSBhIGtleSBjYWxsZWQgYGZvb2AKICAgICBsYWJlbHMuZm9vOioKICAg
LSBSZXNvdXJjZXMgdGhhdCBoYXZlIGEga2V5IGNhbGxlZCBgZm9vYCB3aG9zZSB2YWx1ZSBp
cyBgYmFyYAogICAgIGxhYmVscy5mb28gPSBiYXIKCg0KBQQAAgMFEgS+AQIICg0KBQQAAgMB
EgS+AQkPCg0KBQQAAgMDEgS+ARITCi4KBAQAAgQSBMEBAhYaICBGaWVsZCB0byB1c2UgdG8g
c29ydCB0aGUgbGlzdC4KCg0KBQQAAgQFEgTBAQIICg0KBQQAAgQBEgTBAQkRCg0KBQQAAgQD
EgTBARQVCkAKAgQBEgbFAQDOAQEaMiBSZXNwb25zZSBmb3IgdGhlIGBMaXN0Q29ubmVjdGl2
aXR5VGVzdHNgIG1ldGhvZC4KCgsKAwQBARIExQEIJQorCgQEAQIAEgTHAQIqGh0gTGlzdCBv
ZiBDb25uZWN0aXZpdHkgVGVzdHMuCgoNCgUEAQIABBIExwECCgoNCgUEAQIABhIExwELGwoN
CgUEAQIAARIExwEcJQoNCgUEAQIAAxIExwEoKQpHCgQEAQIBEgTKAQIdGjkgUGFnZSB0b2tl
biB0byBmZXRjaCB0aGUgbmV4dCBzZXQgb2YgQ29ubmVjdGl2aXR5IFRlc3RzLgoKDQoFBAEC
AQUSBMoBAggKDQoFBAECAQESBMoBCRgKDQoFBAECAQMSBMoBGxwKWwoEBAECAhIEzQECIhpN
IExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVkICh3aGVuIHF1ZXJ5aW5nIGFs
bCBsb2NhdGlvbnMgd2l0aCBgLWApLgoKDQoFBAECAgQSBM0BAgoKDQoFBAECAgUSBM0BCxEK
DQoFBAECAgESBM0BEh0KDQoFBAECAgMSBM0BICEKPQoCBAISBtEBANoBARovIFJlcXVlc3Qg
Zm9yIHRoZSBgR2V0Q29ubmVjdGl2aXR5VGVzdGAgbWV0aG9kLgoKCwoDBAIBEgTRAQgiCpcB
CgQEAgIAEgbUAQLZAQQahgEgUmVxdWlyZWQuIGBDb25uZWN0aXZpdHlUZXN0YCByZXNvdXJj
ZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogICAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9j
YXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy97dGVzdF9pZH1gCgoNCgUEAgIABRIE
1AECCAoNCgUEAgIAARIE1AEJDQoNCgUEAgIAAxIE1AEQEQoPCgUEAgIACBIG1AES2QEDChAK
CAQCAgAInAgAEgTVAQQqChEKBwQCAgAInwgSBtYBBNgBBQpACgIEAxIG3QEA8wEBGjIgUmVx
dWVzdCBmb3IgdGhlIGBDcmVhdGVDb25uZWN0aXZpdHlUZXN0YCBtZXRob2QuCgoLCgMEAwES
BN0BCCUKgQEKBAQDAgASBuABAuUBBBpxIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IG9mIHRoZSBDb25uZWN0aXZpdHkgVGVzdCB0byBjcmVhdGU6CiAgICAgYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsYAoKDQoFBAMCAAUSBOABAggKDQoFBAMCAAES
BOABCQ8KDQoFBAMCAAMSBOABEhMKDwoFBAMCAAgSBuABFOUBAwoQCggEAwIACJwIABIE4QEE
KgoRCgcEAwIACJ8IEgbiAQTkAQUKywIKBAQDAgESBO8BAj4avAIgUmVxdWlyZWQuIFRoZSBs
b2dpY2FsIG5hbWUgb2YgdGhlIENvbm5lY3Rpdml0eSBUZXN0IGluIHlvdXIgcHJvamVjdAog
d2l0aCB0aGUgZm9sbG93aW5nIHJlc3RyaWN0aW9uczoKCiAqIE11c3QgY29udGFpbiBvbmx5
IGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1iZXJzLCBhbmQgaHlwaGVucy4KICogTXVzdCBzdGFy
dCB3aXRoIGEgbGV0dGVyLgogKiBNdXN0IGJlIGJldHdlZW4gMS00MCBjaGFyYWN0ZXJzLgog
KiBNdXN0IGVuZCB3aXRoIGEgbnVtYmVyIG9yIGEgbGV0dGVyLgogKiBNdXN0IGJlIHVuaXF1
ZSB3aXRoaW4gdGhlIGN1c3RvbWVyIHByb2plY3QKCg0KBQQDAgEFEgTvAQIICg0KBQQDAgEB
EgTvAQkQCg0KBQQDAgEDEgTvARMUCg0KBQQDAgEIEgTvARU9ChAKCAQDAgEInAgAEgTvARY8
CjcKBAQDAgISBPIBAkkaKSBSZXF1aXJlZC4gQSBgQ29ubmVjdGl2aXR5VGVzdGAgcmVzb3Vy
Y2UKCg0KBQQDAgIGEgTyAQISCg0KBQQDAgIBEgTyARMbCg0KBQQDAgIDEgTyAR4fCg0KBQQD
AgIIEgTyASBIChAKCAQDAgIInAgAEgTyASFHCkAKAgQEEgb2AQD+AQEaMiBSZXF1ZXN0IGZv
ciB0aGUgYFVwZGF0ZUNvbm5lY3Rpdml0eVRlc3RgIG1ldGhvZC4KCgsKAwQEARIE9gEIJQpo
CgQEBAIAEgb5AQL6AS8aWCBSZXF1aXJlZC4gTWFzayBvZiBmaWVsZHMgdG8gdXBkYXRlLiBB
dCBsZWFzdCBvbmUgcGF0aCBtdXN0IGJlIHN1cHBsaWVkIGluCiB0aGlzIGZpZWxkLgoKDQoF
BAQCAAYSBPkBAhsKDQoFBAQCAAESBPkBHCcKDQoFBAQCAAMSBPkBKisKDQoFBAQCAAgSBPoB
Bi4KEAoIBAQCAAicCAASBPoBBy0KSwoEBAQCARIE/QECSRo9IFJlcXVpcmVkLiBPbmx5IGZp
ZWxkcyBzcGVjaWZpZWQgaW4gdXBkYXRlX21hc2sgYXJlIHVwZGF0ZWQuCgoNCgUEBAIBBhIE
/QECEgoNCgUEBAIBARIE/QETGwoNCgUEBAIBAxIE/QEeHwoNCgUEBAIBCBIE/QEgSAoQCggE
BAIBCJwIABIE/QEhRwpACgIEBRIGgQIAigIBGjIgUmVxdWVzdCBmb3IgdGhlIGBEZWxldGVD
b25uZWN0aXZpdHlUZXN0YCBtZXRob2QuCgoLCgMEBQESBIECCCUKlgEKBAQFAgASBoQCAokC
BBqFASBSZXF1aXJlZC4gQ29ubmVjdGl2aXR5IFRlc3QgcmVzb3VyY2UgbmFtZSB1c2luZyB0
aGUgZm9ybToKICAgICBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9nbG9iYWwv
Y29ubmVjdGl2aXR5VGVzdHMve3Rlc3RfaWR9YAoKDQoFBAUCAAUSBIQCAggKDQoFBAUCAAES
BIQCCQ0KDQoFBAUCAAMSBIQCEBEKDwoFBAUCAAgSBoQCEokCAwoQCggEBQIACJwIABIEhQIE
KgoRCgcEBQIACJ8IEgaGAgSIAgUKPwoCBAYSBo0CAJYCARoxIFJlcXVlc3QgZm9yIHRoZSBg
UmVydW5Db25uZWN0aXZpdHlUZXN0YCBtZXRob2QuCgoLCgMEBgESBI0CCCQKlgEKBAQGAgAS
BpACApUCBBqFASBSZXF1aXJlZC4gQ29ubmVjdGl2aXR5IFRlc3QgcmVzb3VyY2UgbmFtZSB1
c2luZyB0aGUgZm9ybToKICAgICBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy9n
bG9iYWwvY29ubmVjdGl2aXR5VGVzdHMve3Rlc3RfaWR9YAoKDQoFBAYCAAUSBJACAggKDQoF
BAYCAAESBJACCQ0KDQoFBAYCAAMSBJACEBEKDwoFBAYCAAgSBpACEpUCAwoQCggEBgIACJwI
ABIEkQIEKgoRCgcEBgIACJ8IEgaSAgSUAgUKUAoCBAcSBpkCAK8CARpCIE1ldGFkYXRhIGRl
c2NyaWJpbmcgYW4gW09wZXJhdGlvbl1bZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbl0K
CgsKAwQHARIEmQIIGQozCgQEBwIAEgSbAgIsGiUgVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiB3
YXMgY3JlYXRlZC4KCg0KBQQHAgAGEgSbAgIbCg0KBQQHAgABEgSbAhwnCg0KBQQHAgADEgSb
AiorCjgKBAQHAgESBJ4CAikaKiBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIGZpbmlzaGVkIHJ1
bm5pbmcuCgoNCgUEBwIBBhIEngICGwoNCgUEBwIBARIEngIcJAoNCgUEBwIBAxIEngInKApz
CgQEBwICEgSiAgIUGmUgVGFyZ2V0IG9mIHRoZSBvcGVyYXRpb24gLSBmb3IgZXhhbXBsZQog
cHJvamVjdHMvcHJvamVjdC0xL2xvY2F0aW9ucy9nbG9iYWwvY29ubmVjdGl2aXR5VGVzdHMv
dGVzdC0xCgoNCgUEBwICBRIEogICCAoNCgUEBwICARIEogIJDwoNCgUEBwICAxIEogISEwo7
CgQEBwIDEgSlAgISGi0gTmFtZSBvZiB0aGUgdmVyYiBleGVjdXRlZCBieSB0aGUgb3BlcmF0
aW9uLgoKDQoFBAcCAwUSBKUCAggKDQoFBAcCAwESBKUCCQ0KDQoFBAcCAwMSBKUCEBEKPwoE
BAcCBBIEqAICGxoxIEh1bWFuLXJlYWRhYmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBp
ZiBhbnkuCgoNCgUEBwIEBRIEqAICCAoNCgUEBwIEARIEqAIJFgoNCgUEBwIEAxIEqAIZGgpK
CgQEBwIFEgSrAgIcGjwgU3BlY2lmaWVzIGlmIGNhbmNlbGxhdGlvbiB3YXMgcmVxdWVzdGVk
IGZvciB0aGUgb3BlcmF0aW9uLgoKDQoFBAcCBQUSBKsCAgYKDQoFBAcCBQESBKsCBxcKDQoF
BAcCBQMSBKsCGhsKHAoEBAcCBhIErgICGRoOIEFQSSB2ZXJzaW9uLgoKDQoFBAcCBgUSBK4C
AggKDQoFBAcCBgESBK4CCRQKDQoFBAcCBgMSBK4CFxhiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsRequest ===
    # Fields for ListConnectivityTestsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsResponse ===
    # Fields for ListConnectivityTestsResponse
    # Field: resources Type: 11 (.google.cloud.networkmanagement.v1beta1.ConnectivityTest)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::GetConnectivityTestRequest ===
    # Fields for GetConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::CreateConnectivityTestRequest ===
    # Fields for CreateConnectivityTestRequest
    # Field: parent Type: 9 ()
    # Field: test_id Type: 9 ()
    # Field: resource Type: 11 (.google.cloud.networkmanagement.v1beta1.ConnectivityTest)

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::UpdateConnectivityTestRequest ===
    # Fields for UpdateConnectivityTestRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: resource Type: 11 (.google.cloud.networkmanagement.v1beta1.ConnectivityTest)

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::DeleteConnectivityTestRequest ===
    # Fields for DeleteConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::RerunConnectivityTestRequest ===
    # Fields for RerunConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1beta1::Reachability::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: cancel_requested Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Networkmanagement::V1beta1::Reachability::ReachabilityServiceClient ===
package Google::Cloud::Networkmanagement::V1beta1::Reachability::ReachabilityServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1beta1::Reachability::ReachabilityServiceClient

Client stub representing the remote C<ReachabilityService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkmanagement.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkmanagement.googleapis.com:443' );

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

sub list_connectivity_tests {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'ListConnectivityTests',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsResponse',
    });
}

sub get_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::GetConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'GetConnectivityTest',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest',
    });
}

sub create_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::CreateConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'CreateConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::UpdateConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'UpdateConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rerun_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::RerunConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'RerunConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1beta1::Reachability::DeleteConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1beta1.ReachabilityService',
        method         => 'DeleteConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1beta1::Reachability - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1beta1/reachability.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1beta1::Reachability;

    my $msg = Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1beta1/reachability.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsRequest

Request for the `ListConnectivityTests` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the Connectivity Tests:
    `projects/{project_id}/locations/global`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Number of `ConnectivityTests` to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Page token from an earlier query, as returned in `next_page_token`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Lists the `ConnectivityTests` that match the filter expression. A filter
expression filters the resources listed in the response. The expression
must be of the form `<field> <operator> <value>` where operators: `<`, `>`,
`<=`,
`>=`,
`!=`, `=`, `:` are supported (colon `:` represents a HAS operator which is
roughly synonymous with equality). <field> can refer to a proto or JSON
field, or a synthetic field. Field names can be camelCase or snake_case.

Examples:
- Filter by name:
  name = "projects/proj-1/locations/global/connectivityTests/test-1

- Filter by labels:
  - Resources that have a key called `foo`
    labels.foo:*
  - Resources that have a key called `foo` whose value is `bar`
    labels.foo = bar

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Field to use to sort the list.

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::ListConnectivityTestsResponse

Response for the `ListConnectivityTests` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest>)

List of Connectivity Tests.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of Connectivity Tests.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::GetConnectivityTestRequest

Request for the `GetConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. `ConnectivityTest` resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::CreateConnectivityTestRequest

Request for the `CreateConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the Connectivity Test to create:
    `projects/{project_id}/locations/global`

=item * C<< $msg->test_id() >> / C<< $msg->test_id($value) >>

Type: C<String>

Required. The logical name of the Connectivity Test in your project
with the following restrictions:

* Must contain only lowercase letters, numbers, and hyphens.
* Must start with a letter.
* Must be between 1-40 characters.
* Must end with a number or a letter.
* Must be unique within the customer project

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest>)

Required. A `ConnectivityTest` resource

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::UpdateConnectivityTestRequest

Request for the `UpdateConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update. At least one path must be supplied in
this field.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest>)

Required. Only fields specified in update_mask are updated.

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::DeleteConnectivityTestRequest

Request for the `DeleteConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Connectivity Test resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::RerunConnectivityTestRequest

Request for the `RerunConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Connectivity Test resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1beta1::Reachability::OperationMetadata

Metadata describing an [Operation][google.longrunning.Operation]

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Target of the operation - for example
projects/project-1/locations/global/connectivityTests/test-1

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Name of the verb executed by the operation.

=item * C<< $msg->status_detail() >> / C<< $msg->status_detail($value) >>

Type: C<String>

Human-readable status of the operation, if any.

=item * C<< $msg->cancel_requested() >> / C<< $msg->cancel_requested($value) >>

Type: C<Bool>

Specifies if cancellation was requested for the operation.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

API version.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1beta1::Reachability::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
