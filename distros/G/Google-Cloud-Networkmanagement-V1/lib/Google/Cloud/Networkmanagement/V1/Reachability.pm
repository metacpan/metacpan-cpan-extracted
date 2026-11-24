package Google::Cloud::Networkmanagement::V1::Reachability;

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
    eval { require Google::Cloud::Networkmanagement::V1::ConnectivityTest };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvbmV0d29ya21hbmFnZW1lbnQvdjEvcmVhY2hhYmlsaXR5LnByb3Rv
EiFnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEaHGdvb2dsZS9hcGkvYW5ub3Rh
dGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjlnb29nbGUvY2xv
dWQvbmV0d29ya21hbmFnZW1lbnQvdjEvY29ubmVjdGl2aXR5X3Rlc3QucHJvdG8aI2dvb2ds
ZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHku
cHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvItoBChxMaXN0Q29ubmVjdGl2aXR5VGVzdHNSZXF1ZXN0EksK
BnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlz
LmNvbS9Qcm9qZWN0UgZwYXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpw
YWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGQoI
b3JkZXJfYnkYBSABKAlSB29yZGVyQnkivAEKHUxpc3RDb25uZWN0aXZpdHlUZXN0c1Jlc3Bv
bnNlElEKCXJlc291cmNlcxgBIAMoCzIzLmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVu
dC52MS5Db25uZWN0aXZpdHlUZXN0UglyZXNvdXJjZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1bnJlYWNoYWJsZSJr
ChpHZXRDb25uZWN0aXZpdHlUZXN0UmVxdWVzdBJNCgRuYW1lGAEgASgJQjngQQL6QTMKMW5l
dHdvcmttYW5hZ2VtZW50Lmdvb2dsZWFwaXMuY29tL0Nvbm5lY3Rpdml0eVRlc3RSBG5hbWUi
4AEKHUNyZWF0ZUNvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC
+kEtCitjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJl
bnQSHAoHdGVzdF9pZBgCIAEoCUID4EECUgZ0ZXN0SWQSVAoIcmVzb3VyY2UYAyABKAsyMy5n
b29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuQ29ubmVjdGl2aXR5VGVzdEID4EEC
UghyZXNvdXJjZSK3AQodVXBkYXRlQ29ubmVjdGl2aXR5VGVzdFJlcXVlc3QSQAoLdXBkYXRl
X21hc2sYASABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1h
c2sSVAoIcmVzb3VyY2UYAiABKAsyMy5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQu
djEuQ29ubmVjdGl2aXR5VGVzdEID4EECUghyZXNvdXJjZSJuCh1EZWxldGVDb25uZWN0aXZp
dHlUZXN0UmVxdWVzdBJNCgRuYW1lGAEgASgJQjngQQL6QTMKMW5ldHdvcmttYW5hZ2VtZW50
Lmdvb2dsZWFwaXMuY29tL0Nvbm5lY3Rpdml0eVRlc3RSBG5hbWUibQocUmVydW5Db25uZWN0
aXZpdHlUZXN0UmVxdWVzdBJNCgRuYW1lGAEgASgJQjngQQL6QTMKMW5ldHdvcmttYW5hZ2Vt
ZW50Lmdvb2dsZWFwaXMuY29tL0Nvbm5lY3Rpdml0eVRlc3RSBG5hbWUipAIKEU9wZXJhdGlv
bk1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcFIKY3JlYXRlVGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSB2VuZFRpbWUSFgoGdGFyZ2V0GAMgASgJUgZ0YXJnZXQSEgoEdmVyYhgEIAEo
CVIEdmVyYhIjCg1zdGF0dXNfZGV0YWlsGAUgASgJUgxzdGF0dXNEZXRhaWwSKQoQY2FuY2Vs
X3JlcXVlc3RlZBgGIAEoCFIPY2FuY2VsUmVxdWVzdGVkEh8KC2FwaV92ZXJzaW9uGAcgASgJ
UgphcGlWZXJzaW9uMpYNChNSZWFjaGFiaWxpdHlTZXJ2aWNlEucBChVMaXN0Q29ubmVjdGl2
aXR5VGVzdHMSPy5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuTGlzdENvbm5l
Y3Rpdml0eVRlc3RzUmVxdWVzdBpALmdvb2dsZS5jbG91ZC5uZXR3b3JrbWFuYWdlbWVudC52
MS5MaXN0Q29ubmVjdGl2aXR5VGVzdHNSZXNwb25zZSJLgtPkkwI8EjovdjEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWx9L2Nvbm5lY3Rpdml0eVRlc3Rz2kEGcGFyZW50
EtQBChNHZXRDb25uZWN0aXZpdHlUZXN0Ej0uZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2Vt
ZW50LnYxLkdldENvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLm5ldHdv
cmttYW5hZ2VtZW50LnYxLkNvbm5lY3Rpdml0eVRlc3QiSYLT5JMCPBI6L3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy8qfdpBBG5hbWUS
rAIKFkNyZWF0ZUNvbm5lY3Rpdml0eVRlc3QSQC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFn
ZW1lbnQudjEuQ3JlYXRlQ29ubmVjdGl2aXR5VGVzdFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uIrABgtPkkwJGIjovdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy9nbG9iYWx9L2Nvbm5lY3Rpdml0eVRlc3RzOghyZXNvdXJjZdpBF3BhcmVudCx0ZXN0
X2lkLHJlc291cmNlykFHCjJnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuQ29u
bmVjdGl2aXR5VGVzdBIRT3BlcmF0aW9uTWV0YWRhdGESsgIKFlVwZGF0ZUNvbm5lY3Rpdml0
eVRlc3QSQC5nb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuVXBkYXRlQ29ubmVj
dGl2aXR5VGVzdFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrYBgtPk
kwJPMkMvdjEve3Jlc291cmNlLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2Nv
bm5lY3Rpdml0eVRlc3RzLyp9OghyZXNvdXJjZdpBFHVwZGF0ZV9tYXNrLHJlc291cmNlykFH
CjJnb29nbGUuY2xvdWQubmV0d29ya21hbmFnZW1lbnQudjEuQ29ubmVjdGl2aXR5VGVzdBIR
T3BlcmF0aW9uTWV0YWRhdGESjwIKFVJlcnVuQ29ubmVjdGl2aXR5VGVzdBI/Lmdvb2dsZS5j
bG91ZC5uZXR3b3JrbWFuYWdlbWVudC52MS5SZXJ1bkNvbm5lY3Rpdml0eVRlc3RSZXF1ZXN0
Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKVAYLT5JMCRSJAL3YxL3tuYW1lPXBy
b2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy8qfTpyZXJ1bjoB
KspBRwoyZ29vZ2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLkNvbm5lY3Rpdml0eVRl
c3QSEU9wZXJhdGlvbk1ldGFkYXRhEvEBChZEZWxldGVDb25uZWN0aXZpdHlUZXN0EkAuZ29v
Z2xlLmNsb3VkLm5ldHdvcmttYW5hZ2VtZW50LnYxLkRlbGV0ZUNvbm5lY3Rpdml0eVRlc3RS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJ2gtPkkwI8KjovdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2Nvbm5lY3Rpdml0eVRlc3RzLyp92kEE
bmFtZcpBKgoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRpUykEg
bmV0d29ya21hbmFnZW1lbnQuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQocCCiVjb20uZ29vZ2xlLmNsb3VkLm5ldHdv
cmttYW5hZ2VtZW50LnYxQhhSZWFjaGFiaWxpdHlTZXJ2aWNlUHJvdG9QAVpTY2xvdWQuZ29v
Z2xlLmNvbS9nby9uZXR3b3JrbWFuYWdlbWVudC9hcGl2MS9uZXR3b3JrbWFuYWdlbWVudHBi
O25ldHdvcmttYW5hZ2VtZW50cGKqAiFHb29nbGUuQ2xvdWQuTmV0d29ya01hbmFnZW1lbnQu
VjHKAiFHb29nbGVcQ2xvdWRcTmV0d29ya01hbmFnZW1lbnRcVjHqAiRHb29nbGU6OkNsb3Vk
OjpOZXR3b3JrTWFuYWdlbWVudDo6VjFKyUoKBxIFDgC0AgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACoKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgBDCgkKAgMFEgMXAC0KCQoCAwYSAxgAJQoJCgID
BxIDGQAqCgkKAgMIEgMaACkKCAoBCBIDHAA+CgkKAgglEgMcAD4KCAoBCBIDHQBqCgkKAggL
EgMdAGoKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwA5CgkKAggIEgMfADkKCAoBCBID
IAA+CgkKAggBEgMgAD4KCAoBCBIDIQA+CgkKAggpEgMhAD4KCAoBCBIDIgA9CgkKAggtEgMi
AD0KqgQKAgYAEgUuAJ4BARrZAyBUaGUgUmVhY2hhYmlsaXR5IHNlcnZpY2UgaW4gdGhlIEdv
b2dsZSBDbG91ZCBOZXR3b3JrIE1hbmFnZW1lbnQgQVBJIHByb3ZpZGVzCiBzZXJ2aWNlcyB0
aGF0IGFuYWx5emUgdGhlIHJlYWNoYWJpbGl0eSB3aXRoaW4gYSBzaW5nbGUgR29vZ2xlIFZp
cnR1YWwgUHJpdmF0ZQogQ2xvdWQgKFZQQykgbmV0d29yaywgYmV0d2VlbiBwZWVyZWQgVlBD
IG5ldHdvcmtzLCBiZXR3ZWVuIFZQQyBhbmQgb24tcHJlbWlzZXMKIG5ldHdvcmtzLCBvciBi
ZXR3ZWVuIFZQQyBuZXR3b3JrcyBhbmQgaW50ZXJuZXQgaG9zdHMuIEEgcmVhY2hhYmlsaXR5
IGFuYWx5c2lzCiBpcyBiYXNlZCBvbiBHb29nbGUgQ2xvdWQgbmV0d29yayBjb25maWd1cmF0
aW9ucy4KCiBZb3UgY2FuIHVzZSB0aGUgYW5hbHlzaXMgcmVzdWx0cyB0byB2ZXJpZnkgdGhl
c2UgY29uZmlndXJhdGlvbnMgYW5kCiB0byB0cm91Ymxlc2hvb3QgY29ubmVjdGl2aXR5IGlz
c3Vlcy4KMkEgVGhlIFJlYWNoYWJpbGl0eSBzZXJ2aWNlIGluIEdvb2dsZSBDbG91ZCBOZXR3
b3JrIE1hbmFnZW1lbnQgQVBJCgoKCgMGAAESAy4IGwoKCgMGAAMSAy8CSAoMCgUGAAOZCBID
LwJICgsKAwYAAxIEMAIxNwoNCgUGAAOaCBIEMAIxNwpACgQGAAIAEgQ0AjoDGjIgTGlzdHMg
YWxsIENvbm5lY3Rpdml0eSBUZXN0cyBvd25lZCBieSBhIHByb2plY3QuCgoMCgUGAAIAARID
NAYbCgwKBQYAAgACEgM0HDgKDAoFBgACAAMSAzUPLAoNCgUGAAIABBIENgQ4BgoRCgkGAAIA
BLDKvCISBDYEOAYKDAoFBgACAAQSAzkENAoPCggGAAIABJsIABIDOQQ0CkEKBAYAAgESBD0C
QwMaMyBHZXRzIHRoZSBkZXRhaWxzIG9mIGEgc3BlY2lmaWMgQ29ubmVjdGl2aXR5IFRlc3Qu
CgoMCgUGAAIBARIDPQYZCgwKBQYAAgECEgM9GjQKDAoFBgACAQMSAz4PHwoNCgUGAAIBBBIE
PwRBBgoRCgkGAAIBBLDKvCISBD8EQQYKDAoFBgACAQQSA0IEMgoPCggGAAIBBJsIABIDQgQy
CqoFCgQGAAICEgRSAl0DGpsFIENyZWF0ZXMgYSBuZXcgQ29ubmVjdGl2aXR5IFRlc3QuCiBB
ZnRlciB5b3UgY3JlYXRlIGEgdGVzdCwgdGhlIHJlYWNoYWJpbGl0eSBhbmFseXNpcyBpcyBw
ZXJmb3JtZWQgYXMgcGFydAogb2YgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24sIHdoaWNo
IGNvbXBsZXRlcyB3aGVuIHRoZSBhbmFseXNpcyBjb21wbGV0ZXMuCgogSWYgdGhlIGVuZHBv
aW50IHNwZWNpZmljYXRpb25zIGluIGBDb25uZWN0aXZpdHlUZXN0YCBhcmUgaW52YWxpZAog
KGZvciBleGFtcGxlLCBjb250YWluaW5nIG5vbi1leGlzdGVudCByZXNvdXJjZXMgaW4gdGhl
IG5ldHdvcmssIG9yIHlvdQogZG9uJ3QgaGF2ZSByZWFkIHBlcm1pc3Npb25zIHRvIHRoZSBu
ZXR3b3JrIGNvbmZpZ3VyYXRpb25zIG9mIGxpc3RlZAogcHJvamVjdHMpLCB0aGVuIHRoZSBy
ZWFjaGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2YWx1ZSBvZiBgVU5LTk9XTmAuCgogSWYg
dGhlIGVuZHBvaW50IHNwZWNpZmljYXRpb25zIGluIGBDb25uZWN0aXZpdHlUZXN0YCBhcmUK
IGluY29tcGxldGUsIHRoZSByZWFjaGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2YWx1ZSBv
ZgogPGNvZGU+QU1CSUdVT1VTPC9jb2RlPi4gRm9yIG1vcmUgaW5mb3JtYXRpb24sCiBzZWUg
dGhlIENvbm5lY3Rpdml0eSBUZXN0IGRvY3VtZW50YXRpb24uCgoMCgUGAAICARIDUgYcCgwK
BQYAAgICEgNSHToKDAoFBgACAgMSA1MPKwoNCgUGAAICBBIEVARXBgoRCgkGAAICBLDKvCIS
BFQEVwYKDAoFBgACAgQSA1gERQoPCggGAAICBJsIABIDWARFCg0KBQYAAgIEEgRZBFwGCg8K
BwYAAgIEmQgSBFkEXAYKnAYKBAYAAgMSBG0CeAMajQYgVXBkYXRlcyB0aGUgY29uZmlndXJh
dGlvbiBvZiBhbiBleGlzdGluZyBgQ29ubmVjdGl2aXR5VGVzdGAuCiBBZnRlciB5b3UgdXBk
YXRlIGEgdGVzdCwgdGhlIHJlYWNoYWJpbGl0eSBhbmFseXNpcyBpcyBwZXJmb3JtZWQgYXMg
cGFydAogb2YgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24sIHdoaWNoIGNvbXBsZXRlcyB3
aGVuIHRoZSBhbmFseXNpcyBjb21wbGV0ZXMuCiBUaGUgUmVhY2hhYmlsaXR5IHN0YXRlIGlu
IHRoZSB0ZXN0IHJlc291cmNlIGlzIHVwZGF0ZWQgd2l0aCB0aGUgbmV3IHJlc3VsdC4KCiBJ
ZiB0aGUgZW5kcG9pbnQgc3BlY2lmaWNhdGlvbnMgaW4gYENvbm5lY3Rpdml0eVRlc3RgIGFy
ZSBpbnZhbGlkCiAoZm9yIGV4YW1wbGUsIHRoZXkgY29udGFpbiBub24tZXhpc3RlbnQgcmVz
b3VyY2VzIGluIHRoZSBuZXR3b3JrLCBvciB0aGUKIHVzZXIgZG9lcyBub3QgaGF2ZSByZWFk
IHBlcm1pc3Npb25zIHRvIHRoZSBuZXR3b3JrIGNvbmZpZ3VyYXRpb25zIG9mCiBsaXN0ZWQg
cHJvamVjdHMpLCB0aGVuIHRoZSByZWFjaGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2YWx1
ZSBvZgogPGNvZGU+VU5LTk9XTjwvY29kZT4uCgogSWYgdGhlIGVuZHBvaW50IHNwZWNpZmlj
YXRpb25zIGluIGBDb25uZWN0aXZpdHlUZXN0YCBhcmUgaW5jb21wbGV0ZSwgdGhlCiByZWFj
aGFiaWxpdHkgcmVzdWx0IHJldHVybnMgYSB2YWx1ZSBvZiBgQU1CSUdVT1VTYC4gU2VlIHRo
ZSBkb2N1bWVudGF0aW9uCiBpbiBgQ29ubmVjdGl2aXR5VGVzdGAgZm9yIG1vcmUgZGV0YWls
cy4KCgwKBQYAAgMBEgNtBhwKDAoFBgACAwISA20dOgoMCgUGAAIDAxIDbg8rCg0KBQYAAgME
EgRvBHIGChEKCQYAAgMEsMq8IhIEbwRyBgoMCgUGAAIDBBIDcwRCCg8KCAYAAgMEmwgAEgNz
BEIKDQoFBgACAwQSBHQEdwYKDwoHBgACAwSZCBIEdAR3Bgr3BAoEBgACBBIGhgECkAEDGuYE
IFJlcnVuIGFuIGV4aXN0aW5nIGBDb25uZWN0aXZpdHlUZXN0YC4KIEFmdGVyIHRoZSB1c2Vy
IHRyaWdnZXJzIHRoZSByZXJ1biwgdGhlIHJlYWNoYWJpbGl0eSBhbmFseXNpcyBpcyBwZXJm
b3JtZWQKIGFzIHBhcnQgb2YgdGhlIGxvbmcgcnVubmluZyBvcGVyYXRpb24sIHdoaWNoIGNv
bXBsZXRlcyB3aGVuIHRoZSBhbmFseXNpcwogY29tcGxldGVzLgoKIEV2ZW4gdGhvdWdoIHRo
ZSB0ZXN0IGNvbmZpZ3VyYXRpb24gcmVtYWlucyB0aGUgc2FtZSwgdGhlIHJlYWNoYWJpbGl0
eQogcmVzdWx0IG1heSBjaGFuZ2UgZHVlIHRvIHVuZGVybHlpbmcgbmV0d29yayBjb25maWd1
cmF0aW9uIGNoYW5nZXMuCgogSWYgdGhlIGVuZHBvaW50IHNwZWNpZmljYXRpb25zIGluIGBD
b25uZWN0aXZpdHlUZXN0YCBiZWNvbWUgaW52YWxpZCAoZm9yCiBleGFtcGxlLCBzcGVjaWZp
ZWQgcmVzb3VyY2VzIGFyZSBkZWxldGVkIGluIHRoZSBuZXR3b3JrLCBvciB5b3UgbG9zdAog
cmVhZCBwZXJtaXNzaW9ucyB0byB0aGUgbmV0d29yayBjb25maWd1cmF0aW9ucyBvZiBsaXN0
ZWQgcHJvamVjdHMpLCB0aGVuCiB0aGUgcmVhY2hhYmlsaXR5IHJlc3VsdCByZXR1cm5zIGEg
dmFsdWUgb2YgYFVOS05PV05gLgoKDQoFBgACBAESBIYBBhsKDQoFBgACBAISBIYBHDgKDQoF
BgACBAMSBIcBDysKDwoFBgACBAQSBogBBIsBBgoTCgkGAAIEBLDKvCISBogBBIsBBgoPCgUG
AAIEBBIGjAEEjwEGChEKBwYAAgQEmQgSBowBBI8BBgo4CgQGAAIFEgaTAQKdAQMaKCBEZWxl
dGVzIGEgc3BlY2lmaWMgYENvbm5lY3Rpdml0eVRlc3RgLgoKDQoFBgACBQESBJMBBhwKDQoF
BgACBQISBJMBHToKDQoFBgACBQMSBJQBDysKDwoFBgACBQQSBpUBBJcBBgoTCgkGAAIFBLDK
vCISBpUBBJcBBgoNCgUGAAIFBBIEmAEEMgoQCggGAAIFBJsIABIEmAEEMgoPCgUGAAIFBBIG
mQEEnAEGChEKBwYAAgUEmQgSBpkBBJwBBgo/CgIEABIGoQEAxwEBGjEgUmVxdWVzdCBmb3Ig
dGhlIGBMaXN0Q29ubmVjdGl2aXR5VGVzdHNgIG1ldGhvZC4KCgsKAwQAARIEoQEIJAp4CgQE
AAIAEgakAQKpAQQaaCBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBvZiB0aGUgQ29u
bmVjdGl2aXR5IFRlc3RzOgogICAgIGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25z
L2dsb2JhbGAKCg0KBQQAAgAFEgSkAQIICg0KBQQAAgABEgSkAQkPCg0KBQQAAgADEgSkARIT
Cg8KBQQAAgAIEgakARSpAQMKEAoIBAACAAicCAASBKUBBCoKEQoHBAACAAifCBIGpgEEqAEF
CjgKBAQAAgESBKwBAhYaKiBOdW1iZXIgb2YgYENvbm5lY3Rpdml0eVRlc3RzYCB0byByZXR1
cm4uCgoNCgUEAAIBBRIErAECBwoNCgUEAAIBARIErAEIEQoNCgUEAAIBAxIErAEUFQpTCgQE
AAICEgSvAQIYGkUgUGFnZSB0b2tlbiBmcm9tIGFuIGVhcmxpZXIgcXVlcnksIGFzIHJldHVy
bmVkIGluIGBuZXh0X3BhZ2VfdG9rZW5gLgoKDQoFBAACAgUSBK8BAggKDQoFBAACAgESBK8B
CRMKDQoFBAACAgMSBK8BFhcK6wUKBAQAAgMSBMMBAhQa3AUgTGlzdHMgdGhlIGBDb25uZWN0
aXZpdHlUZXN0c2AgdGhhdCBtYXRjaCB0aGUgZmlsdGVyIGV4cHJlc3Npb24uIEEgZmlsdGVy
CiBleHByZXNzaW9uIGZpbHRlcnMgdGhlIHJlc291cmNlcyBsaXN0ZWQgaW4gdGhlIHJlc3Bv
bnNlLiBUaGUgZXhwcmVzc2lvbgogbXVzdCBiZSBvZiB0aGUgZm9ybSBgPGZpZWxkPiA8b3Bl
cmF0b3I+IDx2YWx1ZT5gIHdoZXJlIG9wZXJhdG9yczogYDxgLCBgPmAsCiBgPD1gLAogYD49
YCwKIGAhPWAsIGA9YCwgYDpgIGFyZSBzdXBwb3J0ZWQgKGNvbG9uIGA6YCByZXByZXNlbnRz
IGEgSEFTIG9wZXJhdG9yIHdoaWNoIGlzCiByb3VnaGx5IHN5bm9ueW1vdXMgd2l0aCBlcXVh
bGl0eSkuIDxmaWVsZD4gY2FuIHJlZmVyIHRvIGEgcHJvdG8gb3IgSlNPTgogZmllbGQsIG9y
IGEgc3ludGhldGljIGZpZWxkLiBGaWVsZCBuYW1lcyBjYW4gYmUgY2FtZWxDYXNlIG9yIHNu
YWtlX2Nhc2UuCgogRXhhbXBsZXM6CiAtIEZpbHRlciBieSBuYW1lOgogICBuYW1lID0gInBy
b2plY3RzL3Byb2otMS9sb2NhdGlvbnMvZ2xvYmFsL2Nvbm5lY3Rpdml0eVRlc3RzL3Rlc3Qt
MQoKIC0gRmlsdGVyIGJ5IGxhYmVsczoKICAgLSBSZXNvdXJjZXMgdGhhdCBoYXZlIGEga2V5
IGNhbGxlZCBgZm9vYAogICAgIGxhYmVscy5mb286KgogICAtIFJlc291cmNlcyB0aGF0IGhh
dmUgYSBrZXkgY2FsbGVkIGBmb29gIHdob3NlIHZhbHVlIGlzIGBiYXJgCiAgICAgbGFiZWxz
LmZvbyA9IGJhcgoKDQoFBAACAwUSBMMBAggKDQoFBAACAwESBMMBCQ8KDQoFBAACAwMSBMMB
EhMKLgoEBAACBBIExgECFhogIEZpZWxkIHRvIHVzZSB0byBzb3J0IHRoZSBsaXN0LgoKDQoF
BAACBAUSBMYBAggKDQoFBAACBAESBMYBCREKDQoFBAACBAMSBMYBFBUKQAoCBAESBsoBANMB
ARoyIFJlc3BvbnNlIGZvciB0aGUgYExpc3RDb25uZWN0aXZpdHlUZXN0c2AgbWV0aG9kLgoK
CwoDBAEBEgTKAQglCisKBAQBAgASBMwBAioaHSBMaXN0IG9mIENvbm5lY3Rpdml0eSBUZXN0
cy4KCg0KBQQBAgAEEgTMAQIKCg0KBQQBAgAGEgTMAQsbCg0KBQQBAgABEgTMARwlCg0KBQQB
AgADEgTMASgpCkcKBAQBAgESBM8BAh0aOSBQYWdlIHRva2VuIHRvIGZldGNoIHRoZSBuZXh0
IHNldCBvZiBDb25uZWN0aXZpdHkgVGVzdHMuCgoNCgUEAQIBBRIEzwECCAoNCgUEAQIBARIE
zwEJGAoNCgUEAQIBAxIEzwEbHApbCgQEAQICEgTSAQIiGk0gTG9jYXRpb25zIHRoYXQgY291
bGQgbm90IGJlIHJlYWNoZWQgKHdoZW4gcXVlcnlpbmcgYWxsIGxvY2F0aW9ucyB3aXRoIGAt
YCkuCgoNCgUEAQICBBIE0gECCgoNCgUEAQICBRIE0gELEQoNCgUEAQICARIE0gESHQoNCgUE
AQICAxIE0gEgIQo9CgIEAhIG1gEA3wEBGi8gUmVxdWVzdCBmb3IgdGhlIGBHZXRDb25uZWN0
aXZpdHlUZXN0YCBtZXRob2QuCgoLCgMEAgESBNYBCCIKlwEKBAQCAgASBtkBAt4BBBqGASBS
ZXF1aXJlZC4gYENvbm5lY3Rpdml0eVRlc3RgIHJlc291cmNlIG5hbWUgdXNpbmcgdGhlIGZv
cm06CiAgICAgYHByb2plY3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMvZ2xvYmFsL2Nvbm5l
Y3Rpdml0eVRlc3RzL3t0ZXN0X2lkfWAKCg0KBQQCAgAFEgTZAQIICg0KBQQCAgABEgTZAQkN
Cg0KBQQCAgADEgTZARARCg8KBQQCAgAIEgbZARLeAQMKEAoIBAICAAicCAASBNoBBCoKEQoH
BAICAAifCBIG2wEE3QEFCkAKAgQDEgbiAQD4AQEaMiBSZXF1ZXN0IGZvciB0aGUgYENyZWF0
ZUNvbm5lY3Rpdml0eVRlc3RgIG1ldGhvZC4KCgsKAwQDARIE4gEIJQqBAQoEBAMCABIG5QEC
6gEEGnEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIENvbm5lY3Rpdml0
eSBUZXN0IHRvIGNyZWF0ZToKICAgICBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9u
cy9nbG9iYWxgCgoNCgUEAwIABRIE5QECCAoNCgUEAwIAARIE5QEJDwoNCgUEAwIAAxIE5QES
EwoPCgUEAwIACBIG5QEU6gEDChAKCAQDAgAInAgAEgTmAQQqChEKBwQDAgAInwgSBucBBOkB
BQrLAgoEBAMCARIE9AECPhq8AiBSZXF1aXJlZC4gVGhlIGxvZ2ljYWwgbmFtZSBvZiB0aGUg
Q29ubmVjdGl2aXR5IFRlc3QgaW4geW91ciBwcm9qZWN0CiB3aXRoIHRoZSBmb2xsb3dpbmcg
cmVzdHJpY3Rpb25zOgoKICogTXVzdCBjb250YWluIG9ubHkgbG93ZXJjYXNlIGxldHRlcnMs
IG51bWJlcnMsIGFuZCBoeXBoZW5zLgogKiBNdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCiAq
IE11c3QgYmUgYmV0d2VlbiAxLTQwIGNoYXJhY3RlcnMuCiAqIE11c3QgZW5kIHdpdGggYSBu
dW1iZXIgb3IgYSBsZXR0ZXIuCiAqIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUgY3VzdG9t
ZXIgcHJvamVjdAoKDQoFBAMCAQUSBPQBAggKDQoFBAMCAQESBPQBCRAKDQoFBAMCAQMSBPQB
ExQKDQoFBAMCAQgSBPQBFT0KEAoIBAMCAQicCAASBPQBFjwKNwoEBAMCAhIE9wECSRopIFJl
cXVpcmVkLiBBIGBDb25uZWN0aXZpdHlUZXN0YCByZXNvdXJjZQoKDQoFBAMCAgYSBPcBAhIK
DQoFBAMCAgESBPcBExsKDQoFBAMCAgMSBPcBHh8KDQoFBAMCAggSBPcBIEgKEAoIBAMCAgic
CAASBPcBIUcKQAoCBAQSBvsBAIMCARoyIFJlcXVlc3QgZm9yIHRoZSBgVXBkYXRlQ29ubmVj
dGl2aXR5VGVzdGAgbWV0aG9kLgoKCwoDBAQBEgT7AQglCmgKBAQEAgASBv4BAv8BLxpYIFJl
cXVpcmVkLiBNYXNrIG9mIGZpZWxkcyB0byB1cGRhdGUuIEF0IGxlYXN0IG9uZSBwYXRoIG11
c3QgYmUgc3VwcGxpZWQgaW4KIHRoaXMgZmllbGQuCgoNCgUEBAIABhIE/gECGwoNCgUEBAIA
ARIE/gEcJwoNCgUEBAIAAxIE/gEqKwoNCgUEBAIACBIE/wEGLgoQCggEBAIACJwIABIE/wEH
LQpLCgQEBAIBEgSCAgJJGj0gUmVxdWlyZWQuIE9ubHkgZmllbGRzIHNwZWNpZmllZCBpbiB1
cGRhdGVfbWFzayBhcmUgdXBkYXRlZC4KCg0KBQQEAgEGEgSCAgISCg0KBQQEAgEBEgSCAhMb
Cg0KBQQEAgEDEgSCAh4fCg0KBQQEAgEIEgSCAiBIChAKCAQEAgEInAgAEgSCAiFHCkAKAgQF
EgaGAgCPAgEaMiBSZXF1ZXN0IGZvciB0aGUgYERlbGV0ZUNvbm5lY3Rpdml0eVRlc3RgIG1l
dGhvZC4KCgsKAwQFARIEhgIIJQqWAQoEBAUCABIGiQICjgIEGoUBIFJlcXVpcmVkLiBDb25u
ZWN0aXZpdHkgVGVzdCByZXNvdXJjZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogICAgIGBwcm9q
ZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy97
dGVzdF9pZH1gCgoNCgUEBQIABRIEiQICCAoNCgUEBQIAARIEiQIJDQoNCgUEBQIAAxIEiQIQ
EQoPCgUEBQIACBIGiQISjgIDChAKCAQFAgAInAgAEgSKAgQqChEKBwQFAgAInwgSBosCBI0C
BQo/CgIEBhIGkgIAmwIBGjEgUmVxdWVzdCBmb3IgdGhlIGBSZXJ1bkNvbm5lY3Rpdml0eVRl
c3RgIG1ldGhvZC4KCgsKAwQGARIEkgIIJAqWAQoEBAYCABIGlQICmgIEGoUBIFJlcXVpcmVk
LiBDb25uZWN0aXZpdHkgVGVzdCByZXNvdXJjZSBuYW1lIHVzaW5nIHRoZSBmb3JtOgogICAg
IGBwcm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlU
ZXN0cy97dGVzdF9pZH1gCgoNCgUEBgIABRIElQICCAoNCgUEBgIAARIElQIJDQoNCgUEBgIA
AxIElQIQEQoPCgUEBgIACBIGlQISmgIDChAKCAQGAgAInAgAEgSWAgQqChEKBwQGAgAInwgS
BpcCBJkCBQpQCgIEBxIGngIAtAIBGkIgTWV0YWRhdGEgZGVzY3JpYmluZyBhbiBbT3BlcmF0
aW9uXVtnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uXQoKCwoDBAcBEgSeAggZCjMKBAQH
AgASBKACAiwaJSBUaGUgdGltZSB0aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDQoFBAcC
AAYSBKACAhsKDQoFBAcCAAESBKACHCcKDQoFBAcCAAMSBKACKisKOAoEBAcCARIEowICKRoq
IFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmluZy4KCg0KBQQHAgEGEgSj
AgIbCg0KBQQHAgEBEgSjAhwkCg0KBQQHAgEDEgSjAicoCnMKBAQHAgISBKcCAhQaZSBUYXJn
ZXQgb2YgdGhlIG9wZXJhdGlvbiAtIGZvciBleGFtcGxlCiBwcm9qZWN0cy9wcm9qZWN0LTEv
bG9jYXRpb25zL2dsb2JhbC9jb25uZWN0aXZpdHlUZXN0cy90ZXN0LTEKCg0KBQQHAgIFEgSn
AgIICg0KBQQHAgIBEgSnAgkPCg0KBQQHAgIDEgSnAhITCjsKBAQHAgMSBKoCAhIaLSBOYW1l
IG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoNCgUEBwIDBRIEqgIC
CAoNCgUEBwIDARIEqgIJDQoNCgUEBwIDAxIEqgIQEQo/CgQEBwIEEgStAgIbGjEgSHVtYW4t
cmVhZGFibGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCg0KBQQHAgQFEgSt
AgIICg0KBQQHAgQBEgStAgkWCg0KBQQHAgQDEgStAhkaCkoKBAQHAgUSBLACAhwaPCBTcGVj
aWZpZXMgaWYgY2FuY2VsbGF0aW9uIHdhcyByZXF1ZXN0ZWQgZm9yIHRoZSBvcGVyYXRpb24u
CgoNCgUEBwIFBRIEsAICBgoNCgUEBwIFARIEsAIHFwoNCgUEBwIFAxIEsAIaGwocCgQEBwIG
EgSzAgIZGg4gQVBJIHZlcnNpb24uCgoNCgUEBwIGBRIEswICCAoNCgUEBwIGARIEswIJFAoN
CgUEBwIGAxIEswIXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest ===
    # Fields for ListConnectivityTestsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse ===
    # Fields for ListConnectivityTestsResponse
    # Field: resources Type: 11 (.google.cloud.networkmanagement.v1.ConnectivityTest)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest ===
    # Fields for GetConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest ===
    # Fields for CreateConnectivityTestRequest
    # Field: parent Type: 9 ()
    # Field: test_id Type: 9 ()
    # Field: resource Type: 11 (.google.cloud.networkmanagement.v1.ConnectivityTest)

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest ===
    # Fields for UpdateConnectivityTestRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: resource Type: 11 (.google.cloud.networkmanagement.v1.ConnectivityTest)

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest ===
    # Fields for DeleteConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest ===
    # Fields for RerunConnectivityTestRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkmanagement::V1::Reachability::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_detail Type: 9 ()
    # Field: cancel_requested Type: 8 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Networkmanagement::V1::Reachability::ReachabilityServiceClient ===
package Google::Cloud::Networkmanagement::V1::Reachability::ReachabilityServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkmanagement::V1::Reachability::ReachabilityServiceClient

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
        ? Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'ListConnectivityTests',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse',
    });
}

sub get_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'GetConnectivityTest',
        request        => $req,
        response_class => 'Google::Cloud::Networkmanagement::V1::ConnectivityTest::ConnectivityTest',
    });
}

sub create_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'CreateConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'UpdateConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub rerun_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'RerunConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_connectivity_test {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'DeleteConnectivityTest',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkmanagement::V1::Reachability - Compiled Protocol Buffers messages for google/cloud/networkmanagement/v1/reachability.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1::Reachability;

    my $msg = Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkmanagement/v1/reachability.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest

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

=head2 Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse

Response for the `ListConnectivityTests` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resources() >> / C<< $msg->resources($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::ConnectivityTest::ConnectivityTest>)

List of Connectivity Tests.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Page token to fetch the next set of Connectivity Tests.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached (when querying all locations with `-`).

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::GetConnectivityTestRequest

Request for the `GetConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. `ConnectivityTest` resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::CreateConnectivityTestRequest

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

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::ConnectivityTest::ConnectivityTest>)

Required. A `ConnectivityTest` resource

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest

Request for the `UpdateConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Mask of fields to update. At least one path must be supplied in
this field.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<Message> (L<Google::Cloud::Networkmanagement::V1::ConnectivityTest::ConnectivityTest>)

Required. Only fields specified in update_mask are updated.

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::DeleteConnectivityTestRequest

Request for the `DeleteConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Connectivity Test resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::RerunConnectivityTestRequest

Request for the `RerunConnectivityTest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Connectivity Test resource name using the form:
    `projects/{project_id}/locations/global/connectivityTests/{test_id}`

=back

=head2 Google::Cloud::Networkmanagement::V1::Reachability::OperationMetadata

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkmanagement::V1::Reachability::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
