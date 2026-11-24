package Google::Cloud::Workflows::V1beta::Workflows;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvd29ya2Zsb3dzL3YxYmV0YS93b3JrZmxvd3MucHJvdG8SHWdvb2ds
ZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3Rv
Ghdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxojZ29vZ2xlL2xvbmdydW5uaW5nL29w
ZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3By
b3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8ihAYKCFdvcmtmbG93EhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiAB
KAlSC2Rlc2NyaXB0aW9uEkgKBXN0YXRlGAMgASgOMi0uZ29vZ2xlLmNsb3VkLndvcmtmbG93
cy52MWJldGEuV29ya2Zsb3cuU3RhdGVCA+BBA1IFc3RhdGUSJAoLcmV2aXNpb25faWQYBCAB
KAlCA+BBA1IKcmV2aXNpb25JZBJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90
b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgGIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJRChRyZXZpc2lv
bl9jcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IS
cmV2aXNpb25DcmVhdGVUaW1lEksKBmxhYmVscxgIIAMoCzIzLmdvb2dsZS5jbG91ZC53b3Jr
Zmxvd3MudjFiZXRhLldvcmtmbG93LkxhYmVsc0VudHJ5UgZsYWJlbHMSJwoPc2VydmljZV9h
Y2NvdW50GAkgASgJUg5zZXJ2aWNlQWNjb3VudBIpCg9zb3VyY2VfY29udGVudHMYCiABKAlI
AFIOc291cmNlQ29udGVudHMaOQoLTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ASIqCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EgoKBkFDVElWRRABOmTqQWEKIXdvcmtmbG93cy5nb29nbGVhcGlzLmNvbS9Xb3JrZmxvdxI8
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3dvcmtmbG93cy97d29y
a2Zsb3d9Qg0KC3NvdXJjZV9jb2RlIsgBChRMaXN0V29ya2Zsb3dzUmVxdWVzdBJBCgZwYXJl
bnQYASABKAlCKeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZw
YXJlbnQSGwoJcGFnZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJ
UglwYWdlVG9rZW4SFgoGZmlsdGVyGAQgASgJUgZmaWx0ZXISGQoIb3JkZXJfYnkYBSABKAlS
B29yZGVyQnkiqAEKFUxpc3RXb3JrZmxvd3NSZXNwb25zZRJFCgl3b3JrZmxvd3MYASADKAsy
Jy5nb29nbGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5Xb3JrZmxvd1IJd29ya2Zsb3dzEiYK
D25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgD
IAMoCVILdW5yZWFjaGFibGUiUwoSR2V0V29ya2Zsb3dSZXF1ZXN0Ej0KBG5hbWUYASABKAlC
KeBBAvpBIwohd29ya2Zsb3dzLmdvb2dsZWFwaXMuY29tL1dvcmtmbG93UgRuYW1lIsoBChVD
cmVhdGVXb3JrZmxvd1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9u
cy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EkgKCHdvcmtmbG93GAIgASgLMicu
Z29vZ2xlLmNsb3VkLndvcmtmbG93cy52MWJldGEuV29ya2Zsb3dCA+BBAlIId29ya2Zsb3cS
JAoLd29ya2Zsb3dfaWQYAyABKAlCA+BBAlIKd29ya2Zsb3dJZCJWChVEZWxldGVXb3JrZmxv
d1JlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiF3b3JrZmxvd3MuZ29vZ2xlYXBpcy5j
b20vV29ya2Zsb3dSBG5hbWUingEKFVVwZGF0ZVdvcmtmbG93UmVxdWVzdBJICgh3b3JrZmxv
dxgBIAEoCzInLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLldvcmtmbG93QgPgQQJS
CHdvcmtmbG93EjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxk
TWFza1IKdXBkYXRlTWFzayLUAQoRT3BlcmF0aW9uTWV0YWRhdGESOwoLY3JlYXRlX3RpbWUY
ASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjUKCGVuZF90
aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZRIWCgZ0YXJn
ZXQYAyABKAlSBnRhcmdldBISCgR2ZXJiGAQgASgJUgR2ZXJiEh8KC2FwaV92ZXJzaW9uGAUg
ASgJUgphcGlWZXJzaW9uMvkICglXb3JrZmxvd3MSvgEKDUxpc3RXb3JrZmxvd3MSMy5nb29n
bGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5MaXN0V29ya2Zsb3dzUmVxdWVzdBo0Lmdvb2ds
ZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLkxpc3RXb3JrZmxvd3NSZXNwb25zZSJCgtPkkwIz
EjEvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vd29ya2Zsb3dz2kEG
cGFyZW50EqsBCgtHZXRXb3JrZmxvdxIxLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRh
LkdldFdvcmtmbG93UmVxdWVzdBonLmdvb2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLldv
cmtmbG93IkCC0+STAjMSMS92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi93
b3JrZmxvd3MvKn3aQQRuYW1lEukBCg5DcmVhdGVXb3JrZmxvdxI0Lmdvb2dsZS5jbG91ZC53
b3JrZmxvd3MudjFiZXRhLkNyZWF0ZVdvcmtmbG93UmVxdWVzdBodLmdvb2dsZS5sb25ncnVu
bmluZy5PcGVyYXRpb24igQGC0+STAj0iMS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qfS93b3JrZmxvd3M6CHdvcmtmbG932kEbcGFyZW50LHdvcmtmbG93LHdvcmtm
bG93X2lkykEdCghXb3JrZmxvdxIRT3BlcmF0aW9uTWV0YWRhdGES1AEKDkRlbGV0ZVdvcmtm
bG93EjQuZ29vZ2xlLmNsb3VkLndvcmtmbG93cy52MWJldGEuRGVsZXRlV29ya2Zsb3dSZXF1
ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJtgtPkkwIzKjEvdjFiZXRhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovd29ya2Zsb3dzLyp92kEEbmFtZcpBKgoVZ29v
Z2xlLnByb3RvYnVmLkVtcHR5EhFPcGVyYXRpb25NZXRhZGF0YRLrAQoOVXBkYXRlV29ya2Zs
b3cSNC5nb29nbGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5VcGRhdGVXb3JrZmxvd1JlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIoMBgtPkkwJGMjovdjFiZXRhL3t3
b3JrZmxvdy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovd29ya2Zsb3dzLyp9Ogh3b3Jr
Zmxvd9pBFHdvcmtmbG93LHVwZGF0ZV9tYXNrykEdCghXb3JrZmxvdxIRT3BlcmF0aW9uTWV0
YWRhdGEaTMpBGHdvcmtmbG93cy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CdgohY29tLmdvb2dsZS5jbG91ZC53b3Jr
Zmxvd3MudjFiZXRhQg5Xb3JrZmxvd3NQcm90b1ABWj9jbG91ZC5nb29nbGUuY29tL2dvL3dv
cmtmbG93cy9hcGl2MWJldGEvd29ya2Zsb3dzcGI7d29ya2Zsb3dzcGJKiVEKBxIFDgDEAgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIA
JgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkKAgMFEgMX
ACUKCQoCAwYSAxgAKgoJCgIDBxIDGQApCggKAQgSAxsAVgoJCgIICxIDGwBWCggKAQgSAxwA
IgoJCgIIChIDHAAiCggKAQgSAx0ALwoJCgIICBIDHQAvCggKAQgSAx4AOgoJCgIIARIDHgA6
Cq4BCgIGABIEIwBpARqhASBXb3JrZmxvd3MgaXMgdXNlZCB0byBkZXBsb3kgYW5kIGV4ZWN1
dGUgd29ya2Zsb3cgcHJvZ3JhbXMuCiBXb3JrZmxvd3MgbWFrZXMgc3VyZSB0aGUgcHJvZ3Jh
bSBleGVjdXRlcyByZWxpYWJseSwgZGVzcGl0ZSBoYXJkd2FyZSBhbmQKIG5ldHdvcmtpbmcg
aW50ZXJydXB0aW9ucy4KCgoKAwYAARIDIwgRCgoKAwYAAxIDJAJACgwKBQYAA5kIEgMkAkAK
CwoDBgADEgQlAiY3Cg0KBQYAA5oIEgQlAiY3CmUKBAYAAgASBCoCLwMaVyBMaXN0cyBXb3Jr
Zmxvd3MgaW4gYSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KIFRoZSBkZWZhdWx0IG9y
ZGVyIGlzIG5vdCBzcGVjaWZpZWQuCgoMCgUGAAIAARIDKgYTCgwKBQYAAgACEgMqFCgKDAoF
BgACAAMSAyozSAoNCgUGAAIABBIEKwQtBgoRCgkGAAIABLDKvCISBCsELQYKDAoFBgACAAQS
Ay4ENAoPCggGAAIABJsIABIDLgQ0CjIKBAYAAgESBDICNwMaJCBHZXRzIGRldGFpbHMgb2Yg
YSBzaW5nbGUgV29ya2Zsb3cuCgoMCgUGAAIBARIDMgYRCgwKBQYAAgECEgMyEiQKDAoFBgAC
AQMSAzIvNwoNCgUGAAIBBBIEMwQ1BgoRCgkGAAIBBLDKvCISBDMENQYKDAoFBgACAQQSAzYE
MgoPCggGAAIBBJsIABIDNgQyCuUBCgQGAAICEgQ8AkcDGtYBIENyZWF0ZXMgYSBuZXcgd29y
a2Zsb3cuIElmIGEgd29ya2Zsb3cgd2l0aCB0aGUgc3BlY2lmaWVkIG5hbWUgYWxyZWFkeQog
ZXhpc3RzIGluIHRoZSBzcGVjaWZpZWQgcHJvamVjdCBhbmQgbG9jYXRpb24sIHRoZSBsb25n
IHJ1bm5pbmcgb3BlcmF0aW9uCiB3aWxsIHJldHVybiBbQUxSRUFEWV9FWElTVFNdW2dvb2ds
ZS5ycGMuQ29kZS5BTFJFQURZX0VYSVNUU10gZXJyb3IuCgoMCgUGAAICARIDPAYUCgwKBQYA
AgICEgM8FSoKDAoFBgACAgMSAz0PKwoNCgUGAAICBBIEPgRBBgoRCgkGAAICBLDKvCISBD4E
QQYKDAoFBgACAgQSA0IESQoPCggGAAICBJsIABIDQgRJCg0KBQYAAgIEEgRDBEYGCg8KBwYA
AgIEmQgSBEMERgYKigEKBAYAAgMSBEwCVgMafCBEZWxldGVzIGEgd29ya2Zsb3cgd2l0aCB0
aGUgc3BlY2lmaWVkIG5hbWUuCiBUaGlzIG1ldGhvZCBhbHNvIGNhbmNlbHMgYW5kIGRlbGV0
ZXMgYWxsIHJ1bm5pbmcgZXhlY3V0aW9ucyBvZiB0aGUKIHdvcmtmbG93LgoKDAoFBgACAwES
A0wGFAoMCgUGAAIDAhIDTBUqCgwKBQYAAgMDEgNNDysKDQoFBgACAwQSBE4EUAYKEQoJBgAC
AwSwyrwiEgROBFAGCgwKBQYAAgMEEgNRBDIKDwoIBgACAwSbCAASA1EEMgoNCgUGAAIDBBIE
UgRVBgoPCgcGAAIDBJkIEgRSBFUGCqQCCgQGAAIEEgRdAmgDGpUCIFVwZGF0ZXMgYW4gZXhp
c3Rpbmcgd29ya2Zsb3cuCiBSdW5uaW5nIHRoaXMgbWV0aG9kIGhhcyBubyBpbXBhY3Qgb24g
YWxyZWFkeSBydW5uaW5nIGV4ZWN1dGlvbnMgb2YgdGhlCiB3b3JrZmxvdy4gQSBuZXcgcmV2
aXNpb24gb2YgdGhlIHdvcmtmbG93IG1heSBiZSBjcmVhdGVkIGFzIGEgcmVzdWx0IG9mIGEK
IHN1Y2Nlc3NmdWwgdXBkYXRlIG9wZXJhdGlvbi4gSW4gdGhhdCBjYXNlLCBzdWNoIHJldmlz
aW9uIHdpbGwgYmUgdXNlZAogaW4gbmV3IHdvcmtmbG93IGV4ZWN1dGlvbnMuCgoMCgUGAAIE
ARIDXQYUCgwKBQYAAgQCEgNdFSoKDAoFBgACBAMSA14PKwoNCgUGAAIEBBIEXwRiBgoRCgkG
AAIEBLDKvCISBF8EYgYKDAoFBgACBAQSA2MEQgoPCggGAAIEBJsIABIDYwRCCg0KBQYAAgQE
EgRkBGcGCg8KBwYAAgQEmQgSBGQEZwYKPAoCBAASBWwAvQEBGi8gV29ya2Zsb3cgcHJvZ3Jh
bSB0byBiZSBleGVjdXRlZCBieSBXb3JrZmxvd3MuCgoKCgMEAAESA2wIEAoLCgMEAAcSBG0C
cAQKDQoFBAAHnQgSBG0CcAQKbAoEBAAEABIEdAJ6AxpeIERlc2NyaWJlcyB0aGUgY3VycmVu
dCBzdGF0ZSBvZiB3b3JrZmxvdyBkZXBsb3ltZW50LiBNb3JlIHN0YXRlcyBtYXkgYmUKIGFk
ZGVkIGluIHRoZSBmdXR1cmUuCgoMCgUEAAQAARIDdAcMCh8KBgQABAACABIDdgQaGhAgSW52
YWxpZCBzdGF0ZS4KCg4KBwQABAACAAESA3YEFQoOCgcEAAQAAgACEgN2GBkKTAoGBAAEAAIB
EgN5BA8aPSBUaGUgd29ya2Zsb3cgaGFzIGJlZW4gZGVwbG95ZWQgc3VjY2Vzc2Z1bGx5IGFu
ZCBpcyBzZXJ2aW5nLgoKDgoHBAAEAAIBARIDeQQKCg4KBwQABAACAQISA3kNDgp3CgQEAAIA
EgN+AhIaaiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgd29ya2Zsb3cuCiBGb3JtYXQ6IHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mve3dvcmtm
bG93fQoKDAoFBAACAAUSA34CCAoMCgUEAAIAARIDfgkNCgwKBQQAAgADEgN+EBEKcAoEBAAC
ARIEggECGRpiIERlc2NyaXB0aW9uIG9mIHRoZSB3b3JrZmxvdyBwcm92aWRlZCBieSB0aGUg
dXNlci4KIE11c3QgYmUgYXQgbW9zdCAxMDAwIHVuaWNvZGUgY2hhcmFjdGVycyBsb25nLgoK
DQoFBAACAQUSBIIBAggKDQoFBAACAQESBIIBCRQKDQoFBAACAQMSBIIBFxgKPgoEBAACAhIE
hQECPhowIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgd29ya2Zsb3cgZGVwbG95bWVudC4K
Cg0KBQQAAgIGEgSFAQIHCg0KBQQAAgIBEgSFAQgNCg0KBQQAAgIDEgSFARARCg0KBQQAAgII
EgSFARI9ChAKCAQAAgIInAgAEgSFARM8Cv4DCgQEAAIDEgSSAQJFGu8DIE91dHB1dCBvbmx5
LiBUaGUgcmV2aXNpb24gb2YgdGhlIHdvcmtmbG93LgogQSBuZXcgcmV2aXNpb24gb2YgYSB3
b3JrZmxvdyBpcyBjcmVhdGVkIGFzIGEgcmVzdWx0IG9mIHVwZGF0aW5nIHRoZQogZm9sbG93
aW5nIHByb3BlcnRpZXMgb2YgYSB3b3JrZmxvdzoKCiAtIFtTZXJ2aWNlIGFjY291bnRdW2dv
b2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLldvcmtmbG93LnNlcnZpY2VfYWNjb3VudF0K
IC0gW1dvcmtmbG93IGNvZGUgdG8gYmUKIGV4ZWN1dGVkXVtnb29nbGUuY2xvdWQud29ya2Zs
b3dzLnYxYmV0YS5Xb3JrZmxvdy5zb3VyY2VfY29udGVudHNdCgogVGhlIGZvcm1hdCBpcyAi
MDAwMDAxLWE0ZCIsIHdoZXJlIHRoZSBmaXJzdCA2IGNoYXJhY3RlcnMgZGVmaW5lCiB0aGUg
emVyby1wYWRkZWQgcmV2aXNpb24gb3JkaW5hbCBudW1iZXIuIFRoZXkgYXJlIGZvbGxvd2Vk
IGJ5IGEgaHlwaGVuIGFuZAogMyBoZXhhZGVjaW1hbCByYW5kb20gY2hhcmFjdGVycy4KCg0K
BQQAAgMFEgSSAQIICg0KBQQAAgMBEgSSAQkUCg0KBQQAAgMDEgSSARcYCg0KBQQAAgMIEgSS
ARlEChAKCAQAAgMInAgAEgSSARpDCk4KBAQAAgQSBpUBApYBMho+IE91dHB1dCBvbmx5LiBU
aGUgdGltZXN0YW1wIG9mIHdoZW4gdGhlIHdvcmtmbG93IHdhcyBjcmVhdGVkLgoKDQoFBAAC
BAYSBJUBAhsKDQoFBAACBAESBJUBHCcKDQoFBAACBAMSBJUBKisKDQoFBAACBAgSBJYBBjEK
EAoIBAACBAicCAASBJYBBzAKSQoEBAACBRIGmQECmgEyGjkgT3V0cHV0IG9ubHkuIFRoZSBs
YXN0IHVwZGF0ZSB0aW1lc3RhbXAgb2YgdGhlIHdvcmtmbG93LgoKDQoFBAACBQYSBJkBAhsK
DQoFBAACBQESBJkBHCcKDQoFBAACBQMSBJkBKisKDQoFBAACBQgSBJoBBjEKEAoIBAACBQic
CAASBJoBBzAKYwoEBAACBhIGngECnwEyGlMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAg
dGhhdCB0aGUgbGF0ZXN0IHJldmlzaW9uIG9mIHRoZSB3b3JrZmxvdwogd2FzIGNyZWF0ZWQu
CgoNCgUEAAIGBhIEngECGwoNCgUEAAIGARIEngEcMAoNCgUEAAIGAxIEngEzNAoNCgUEAAIG
CBIEnwEGMQoQCggEAAIGCJwIABIEnwEHMAq0AgoEBAACBxIEpgECIRqlAiBMYWJlbHMgYXNz
b2NpYXRlZCB3aXRoIHRoaXMgd29ya2Zsb3cuCiBMYWJlbHMgY2FuIGNvbnRhaW4gYXQgbW9z
dCA2NCBlbnRyaWVzLiBLZXlzIGFuZCB2YWx1ZXMgY2FuIGJlIG5vIGxvbmdlcgogdGhhbiA2
MyBjaGFyYWN0ZXJzIGFuZCBjYW4gb25seSBjb250YWluIGxvd2VyY2FzZSBsZXR0ZXJzLCBu
dW1lcmljCiBjaGFyYWN0ZXJzLCB1bmRlcnNjb3JlcyBhbmQgZGFzaGVzLiBMYWJlbCBrZXlz
IG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlci4KIEludGVybmF0aW9uYWwgY2hhcmFjdGVycyBh
cmUgYWxsb3dlZC4KCg0KBQQAAgcGEgSmAQIVCg0KBQQAAgcBEgSmARYcCg0KBQQAAgcDEgSm
AR8gCvYECgQEAAIIEgS0AQIdGucEIFRoZSBzZXJ2aWNlIGFjY291bnQgYXNzb2NpYXRlZCB3
aXRoIHRoZSBsYXRlc3Qgd29ya2Zsb3cgdmVyc2lvbi4KIFRoaXMgc2VydmljZSBhY2NvdW50
IHJlcHJlc2VudHMgdGhlIGlkZW50aXR5IG9mIHRoZSB3b3JrZmxvdyBhbmQgZGV0ZXJtaW5l
cwogd2hhdCBwZXJtaXNzaW9ucyB0aGUgd29ya2Zsb3cgaGFzLgogRm9ybWF0OiBwcm9qZWN0
cy97cHJvamVjdH0vc2VydmljZUFjY291bnRzL3thY2NvdW50fSBvciB7YWNjb3VudH0KCiBV
c2luZyBgLWAgYXMgYSB3aWxkY2FyZCBmb3IgdGhlIGB7cHJvamVjdH1gIG9yIG5vdCBwcm92
aWRpbmcgb25lIGF0IGFsbAogd2lsbCBpbmZlciB0aGUgcHJvamVjdCBmcm9tIHRoZSBhY2Nv
dW50LiBUaGUgYHthY2NvdW50fWAgdmFsdWUgY2FuIGJlIHRoZQogYGVtYWlsYCBhZGRyZXNz
IG9yIHRoZSBgdW5pcXVlX2lkYCBvZiB0aGUgc2VydmljZSBhY2NvdW50LgoKIElmIG5vdCBw
cm92aWRlZCwgd29ya2Zsb3cgd2lsbCB1c2UgdGhlIHByb2plY3QncyBkZWZhdWx0IHNlcnZp
Y2UgYWNjb3VudC4KIE1vZGlmeWluZyB0aGlzIGZpZWxkIGZvciBhbiBleGlzdGluZyB3b3Jr
ZmxvdyByZXN1bHRzIGluIGEgbmV3IHdvcmtmbG93CiByZXZpc2lvbi4KCg0KBQQAAggFEgS0
AQIICg0KBQQAAggBEgS0AQkYCg0KBQQAAggDEgS0ARscCpYBCgQEAAgAEga5AQK8AQMahQEg
UmVxdWlyZWQuIExvY2F0aW9uIG9mIHRoZSB3b3JrZmxvdyBzb3VyY2UgY29kZS4KIE1vZGlm
eWluZyB0aGlzIGZpZWxkIGZvciBhbiBleGlzdGluZyB3b3JrZmxvdyByZXN1bHRzIGluIGEg
bmV3IHdvcmtmbG93CiByZXZpc2lvbi4KCg0KBQQACAABEgS5AQgTCkYKBAQAAgkSBLsBBCAa
OCBXb3JrZmxvdyBjb2RlIHRvIGJlIGV4ZWN1dGVkLiBUaGUgc2l6ZSBsaW1pdCBpcyAxMjhL
Qi4KCg0KBQQAAgkFEgS7AQQKCg0KBQQAAgkBEgS7AQsaCg0KBQQAAgkDEgS7AR0fCnAKAgQB
EgbCAQDhAQEaYiBSZXF1ZXN0IGZvciB0aGUKIFtMaXN0V29ya2Zsb3dzXVtnb29nbGUuY2xv
dWQud29ya2Zsb3dzLnYxYmV0YS5Xb3JrZmxvd3MuTGlzdFdvcmtmbG93c10KIG1ldGhvZC4K
CgsKAwQBARIEwgEIHAqMAQoEBAECABIGxQECygEEGnwgUmVxdWlyZWQuIFByb2plY3QgYW5k
IGxvY2F0aW9uIGZyb20gd2hpY2ggdGhlIHdvcmtmbG93cyBzaG91bGQgYmUgbGlzdGVkLgog
Rm9ybWF0OiBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0KCg0KBQQB
AgAFEgTFAQIICg0KBQQBAgABEgTFAQkPCg0KBQQBAgADEgTFARITCg8KBQQBAgAIEgbFARTK
AQMKEAoIBAECAAicCAASBMYBBCoKEQoHBAECAAifCBIGxwEEyQEFCpQCCgQEAQIBEgTQAQIW
GoUCIE1heGltdW0gbnVtYmVyIG9mIHdvcmtmbG93cyB0byByZXR1cm4gcGVyIGNhbGwuIFRo
ZSBzZXJ2aWNlIG1heSByZXR1cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdGhlIHZh
bHVlIGlzIG5vdCBzcGVjaWZpZWQsIGEgZGVmYXVsdCB2YWx1ZSBvZgogNTAwIHdpbGwgYmUg
dXNlZC4gVGhlIG1heGltdW0gcGVybWl0dGVkIHZhbHVlIGlzIDEwMDAgYW5kIHZhbHVlcyBn
cmVhdGVyCiB0aGFuIDEwMDAgd2lsbCBiZSBjb2VyY2VkIGRvd24gdG8gMTAwMC4KCg0KBQQB
AgEFEgTQAQIHCg0KBQQBAgEBEgTQAQgRCg0KBQQBAgEDEgTQARQVCvMBCgQEAQICEgTXAQIY
GuQBIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0V29ya2Zs
b3dzYCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBh
Z2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0
byBgTGlzdFdvcmtmbG93c2AgbXVzdAogbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0
aGUgcGFnZSB0b2tlbi4KCg0KBQQBAgIFEgTXAQIICg0KBQQBAgIBEgTXAQkTCg0KBQQBAgID
EgTXARYXCkEKBAQBAgMSBNoBAhQaMyBGaWx0ZXIgdG8gcmVzdHJpY3QgcmVzdWx0cyB0byBz
cGVjaWZpYyB3b3JrZmxvd3MuCgoNCgUEAQIDBRIE2gECCAoNCgUEAQIDARIE2gEJDwoNCgUE
AQIDAxIE2gESEwqYAgoEBAECBBIE4AECFhqJAiBDb21tYS1zZXBhcmF0ZWQgbGlzdCBvZiBm
aWVsZHMgdGhhdCB0aGF0IHNwZWNpZnkgdGhlIG9yZGVyIG9mIHRoZSByZXN1bHRzLgogRGVm
YXVsdCBzb3J0aW5nIG9yZGVyIGZvciBhIGZpZWxkIGlzIGFzY2VuZGluZy4gVG8gc3BlY2lm
eSBkZXNjZW5kaW5nIG9yZGVyCiBmb3IgYSBmaWVsZCwgYXBwZW5kIGEgIiBkZXNjIiBzdWZm
aXguCiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgcmVzdWx0cyB3aWxsIGJlIHJldHVybmVkIGlu
IGFuIHVuc3BlY2lmaWVkIG9yZGVyLgoKDQoFBAECBAUSBOABAggKDQoFBAECBAESBOABCREK
DQoFBAECBAMSBOABFBUKcQoCBAISBuYBAPABARpjIFJlc3BvbnNlIGZvciB0aGUKIFtMaXN0
V29ya2Zsb3dzXVtnb29nbGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5Xb3JrZmxvd3MuTGlz
dFdvcmtmbG93c10KIG1ldGhvZC4KCgsKAwQCARIE5gEIHQo2CgQEAgIAEgToAQIiGiggVGhl
IHdvcmtmbG93cyB3aGljaCBtYXRjaCB0aGUgcmVxdWVzdC4KCg0KBQQCAgAEEgToAQIKCg0K
BQQCAgAGEgToAQsTCg0KBQQCAgABEgToARQdCg0KBQQCAgADEgToASAhCpABCgQEAgIBEgTs
AQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rva2VuYCB0byBy
ZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVy
ZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQCAgEFEgTsAQIICg0KBQQCAgEBEgTs
AQkYCg0KBQQCAgEDEgTsARscCiYKBAQCAgISBO8BAiIaGCBVbnJlYWNoYWJsZSByZXNvdXJj
ZXMuCgoNCgUEAgICBBIE7wECCgoNCgUEAgICBRIE7wELEQoNCgUEAgICARIE7wESHQoNCgUE
AgICAxIE7wEgIQprCgIEAxIG9AEA/QEBGl0gUmVxdWVzdCBmb3IgdGhlCiBbR2V0V29ya2Zs
b3ddW2dvb2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLldvcmtmbG93cy5HZXRXb3JrZmxv
d10gbWV0aG9kLgoKCwoDBAMBEgT0AQgaCp4BCgQEAwIAEgb3AQL8AQQajQEgUmVxdWlyZWQu
IE5hbWUgb2YgdGhlIHdvcmtmbG93IHdoaWNoIGluZm9ybWF0aW9uIHNob3VsZCBiZSByZXRy
aWV2ZWQuCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS93b3JrZmxvd3Mve3dvcmtmbG93fQoKDQoFBAMCAAUSBPcBAggKDQoFBAMCAAESBPcBCQ0K
DQoFBAMCAAMSBPcBEBEKDwoFBAMCAAgSBvcBEvwBAwoQCggEAwIACJwIABIE+AEEKgoRCgcE
AwIACJ8IEgb5AQT7AQUKcgoCBAQSBoICAJgCARpkIFJlcXVlc3QgZm9yIHRoZQogW0NyZWF0
ZVdvcmtmbG93XVtnb29nbGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5Xb3JrZmxvd3MuQ3Jl
YXRlV29ya2Zsb3ddCiBtZXRob2QuCgoLCgMEBAESBIICCB0KiwEKBAQEAgASBoUCAooCBBp7
IFJlcXVpcmVkLiBQcm9qZWN0IGFuZCBsb2NhdGlvbiBpbiB3aGljaCB0aGUgd29ya2Zsb3cg
c2hvdWxkIGJlIGNyZWF0ZWQuCiBGb3JtYXQ6ICBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0KCg0KBQQEAgAFEgSFAgIICg0KBQQEAgABEgSFAgkPCg0KBQQEAgAD
EgSFAhITCg8KBQQEAgAIEgaFAhSKAgMKEAoIBAQCAAicCAASBIYCBCoKEQoHBAQCAAifCBIG
hwIEiQIFCjEKBAQEAgESBI0CAkEaIyBSZXF1aXJlZC4gV29ya2Zsb3cgdG8gYmUgY3JlYXRl
ZC4KCg0KBQQEAgEGEgSNAgIKCg0KBQQEAgEBEgSNAgsTCg0KBQQEAgEDEgSNAhYXCg0KBQQE
AgEIEgSNAhhAChAKCAQEAgEInAgAEgSNAhk/CtQCCgQEBAICEgSXAgJCGsUCIFJlcXVpcmVk
LiBUaGUgSUQgb2YgdGhlIHdvcmtmbG93IHRvIGJlIGNyZWF0ZWQuIEl0IGhhcyB0byBmdWxm
aWxsIHRoZQogZm9sbG93aW5nIHJlcXVpcmVtZW50czoKCiAqIE11c3QgY29udGFpbiBvbmx5
IGxldHRlcnMsIG51bWJlcnMsIHVuZGVyc2NvcmVzIGFuZCBoeXBoZW5zLgogKiBNdXN0IHN0
YXJ0IHdpdGggYSBsZXR0ZXIuCiAqIE11c3QgYmUgYmV0d2VlbiAxLTY0IGNoYXJhY3RlcnMu
CiAqIE11c3QgZW5kIHdpdGggYSBudW1iZXIgb3IgYSBsZXR0ZXIuCiAqIE11c3QgYmUgdW5p
cXVlIHdpdGhpbiB0aGUgY3VzdG9tZXIgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoNCgUEBAIC
BRIElwICCAoNCgUEBAICARIElwIJFAoNCgUEBAICAxIElwIXGAoNCgUEBAICCBIElwIZQQoQ
CggEBAICCJwIABIElwIaQApyCgIEBRIGnQIApgIBGmQgUmVxdWVzdCBmb3IgdGhlCiBbRGVs
ZXRlV29ya2Zsb3ddW2dvb2dsZS5jbG91ZC53b3JrZmxvd3MudjFiZXRhLldvcmtmbG93cy5E
ZWxldGVXb3JrZmxvd10KIG1ldGhvZC4KCgsKAwQFARIEnQIIHQqFAQoEBAUCABIGoAICpQIE
GnUgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHdvcmtmbG93IHRvIGJlIGRlbGV0ZWQuCiBGb3Jt
YXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS93b3JrZmxvd3Mv
e3dvcmtmbG93fQoKDQoFBAUCAAUSBKACAggKDQoFBAUCAAESBKACCQ0KDQoFBAUCAAMSBKAC
EBEKDwoFBAUCAAgSBqACEqUCAwoQCggEBQIACJwIABIEoQIEKgoRCgcEBQIACJ8IEgaiAgSk
AgUKcgoCBAYSBqsCALICARpkIFJlcXVlc3QgZm9yIHRoZQogW1VwZGF0ZVdvcmtmbG93XVtn
b29nbGUuY2xvdWQud29ya2Zsb3dzLnYxYmV0YS5Xb3JrZmxvd3MuVXBkYXRlV29ya2Zsb3dd
CiBtZXRob2QuCgoLCgMEBgESBKsCCB0KMQoEBAYCABIErQICQRojIFJlcXVpcmVkLiBXb3Jr
ZmxvdyB0byBiZSB1cGRhdGVkLgoKDQoFBAYCAAYSBK0CAgoKDQoFBAYCAAESBK0CCxMKDQoF
BAYCAAMSBK0CFhcKDQoFBAYCAAgSBK0CGEAKEAoIBAYCAAicCAASBK0CGT8KYwoEBAYCARIE
sQICLBpVIExpc3Qgb2YgZmllbGRzIHRvIGJlIHVwZGF0ZWQuIElmIG5vdCBwcmVzZW50LCB0
aGUgZW50aXJlIHdvcmtmbG93CiB3aWxsIGJlIHVwZGF0ZWQuCgoNCgUEBgIBBhIEsQICGwoN
CgUEBgIBARIEsQIcJwoNCgUEBgIBAxIEsQIqKwpGCgIEBxIGtQIAxAIBGjggUmVwcmVzZW50
cyB0aGUgbWV0YWRhdGEgb2YgdGhlIGxvbmctcnVubmluZyBvcGVyYXRpb24uCgoLCgMEBwES
BLUCCBkKMwoEBAcCABIEtwICLBolIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0
ZWQuCgoNCgUEBwIABhIEtwICGwoNCgUEBwIAARIEtwIcJwoNCgUEBwIAAxIEtwIqKwo4CgQE
BwIBEgS6AgIpGiogVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBydW5uaW5nLgoK
DQoFBAcCAQYSBLoCAhsKDQoFBAcCAQESBLoCHCQKDQoFBAcCAQMSBLoCJygKTQoEBAcCAhIE
vQICFBo/IFNlcnZlci1kZWZpbmVkIHJlc291cmNlIHBhdGggZm9yIHRoZSB0YXJnZXQgb2Yg
dGhlIG9wZXJhdGlvbi4KCg0KBQQHAgIFEgS9AgIICg0KBQQHAgIBEgS9AgkPCg0KBQQHAgID
EgS9AhITCjsKBAQHAgMSBMACAhIaLSBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRo
ZSBvcGVyYXRpb24uCgoNCgUEBwIDBRIEwAICCAoNCgUEBwIDARIEwAIJDQoNCgUEBwIDAxIE
wAIQEQo4CgQEBwIEEgTDAgIZGiogQVBJIHZlcnNpb24gdXNlZCB0byBzdGFydCB0aGUgb3Bl
cmF0aW9uLgoKDQoFBAcCBAUSBMMCAggKDQoFBAcCBAESBMMCCRQKDQoFBAcCBAMSBMMCFxhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Workflows::V1beta::Workflows::Workflow ===
    # Fields for Workflow
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.workflows.v1beta.Workflow.State)
    # Field: revision_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: revision_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.workflows.v1beta.Workflow.LabelsEntry)
    # Field: service_account Type: 9 ()
    # Field: source_contents Type: 9 ()

# Enum: Workflow::State
our $Workflow_STATE_UNSPECIFIED = 0;
our $Workflow_ACTIVE = 1;

# === Message: Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest ===
    # Fields for ListWorkflowsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse ===
    # Fields for ListWorkflowsResponse
    # Field: workflows Type: 11 (.google.cloud.workflows.v1beta.Workflow)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest ===
    # Fields for GetWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest ===
    # Fields for CreateWorkflowRequest
    # Field: parent Type: 9 ()
    # Field: workflow Type: 11 (.google.cloud.workflows.v1beta.Workflow)
    # Field: workflow_id Type: 9 ()

# === Message: Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest ===
    # Fields for DeleteWorkflowRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest ===
    # Fields for UpdateWorkflowRequest
    # Field: workflow Type: 11 (.google.cloud.workflows.v1beta.Workflow)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Workflows::V1beta::Workflows::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: api_version Type: 9 ()

# === Service Client: Google::Cloud::Workflows::V1beta::Workflows::WorkflowsClient ===
package Google::Cloud::Workflows::V1beta::Workflows::WorkflowsClient;

=pod

=head2 Service Client: Google::Cloud::Workflows::V1beta::Workflows::WorkflowsClient

Client stub representing the remote C<Workflows> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<workflows.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'workflows.googleapis.com:443' );

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

sub list_workflows {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.v1beta.Workflows',
        method         => 'ListWorkflows',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse',
    });
}

sub get_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.v1beta.Workflows',
        method         => 'GetWorkflow',
        request        => $req,
        response_class => 'Google::Cloud::Workflows::V1beta::Workflows::Workflow',
    });
}

sub create_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.v1beta.Workflows',
        method         => 'CreateWorkflow',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.v1beta.Workflows',
        method         => 'DeleteWorkflow',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_workflow {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.workflows.v1beta.Workflows',
        method         => 'UpdateWorkflow',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Workflows::V1beta::Workflows - Compiled Protocol Buffers messages for google/cloud/workflows/v1beta/workflows.proto

=head1 SYNOPSIS

    use Google::Cloud::Workflows::V1beta::Workflows;

    my $msg = Google::Cloud::Workflows::V1beta::Workflows::Workflow->new({
        name => $name,
        description => $description,
        state => $state,
        revision_id => $revision_id,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Workflows::V1beta::Workflows::Workflow->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/workflows/v1beta/workflows.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Workflows::V1beta::Workflows::Workflow

Workflow program to be executed by Workflows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the workflow.
Format: projects/{project}/locations/{location}/workflows/{workflow}

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of the workflow provided by the user.
Must be at most 1000 unicode characters long.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Workflows::V1beta::Workflow::State>)

Output only. State of the workflow deployment.

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Output only. The revision of the workflow.
A new revision of a workflow is created as a result of updating the
following properties of a workflow:

- [Service account][google.cloud.workflows.v1beta.Workflow.service_account]
- [Workflow code to be
executed][google.cloud.workflows.v1beta.Workflow.source_contents]

The format is "000001-a4d", where the first 6 characters define
the zero-padded revision ordinal number. They are followed by a hyphen and
3 hexadecimal random characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp of when the workflow was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last update timestamp of the workflow.

=item * C<< $msg->revision_create_time() >> / C<< $msg->revision_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp that the latest revision of the workflow
was created.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::V1beta::Workflows::Workflow::LabelsEntry>)

Labels associated with this workflow.
Labels can contain at most 64 entries. Keys and values can be no longer
than 63 characters and can only contain lowercase letters, numeric
characters, underscores and dashes. Label keys must start with a letter.
International characters are allowed.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

The service account associated with the latest workflow version.
This service account represents the identity of the workflow and determines
what permissions the workflow has.
Format: projects/{project}/serviceAccounts/{account} or {account}

Using `-` as a wildcard for the `{project}` or not providing one at all
will infer the project from the account. The `{account}` value can be the
`email` address or the `unique_id` of the service account.

If not provided, workflow will use the project's default service account.
Modifying this field for an existing workflow results in a new workflow
revision.

=item * C<< $msg->source_contents() >> / C<< $msg->source_contents($value) >>

Type: C<String>

Workflow code to be executed. The size limit is 128KB.

=back

=head3 Enum: Workflow::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsRequest

Request for the
[ListWorkflows][google.cloud.workflows.v1beta.Workflows.ListWorkflows]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Project and location from which the workflows should be listed.
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of workflows to return per call. The service may return
fewer than this value. If the value is not specified, a default value of
500 will be used. The maximum permitted value is 1000 and values greater
than 1000 will be coerced down to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListWorkflows` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListWorkflows` must
match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter to restrict results to specific workflows.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Comma-separated list of fields that that specify the order of the results.
Default sorting order for a field is ascending. To specify descending order
for a field, append a " desc" suffix.
If not specified, the results will be returned in an unspecified order.

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::ListWorkflowsResponse

Response for the
[ListWorkflows][google.cloud.workflows.v1beta.Workflows.ListWorkflows]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workflows() >> / C<< $msg->workflows($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::V1beta::Workflows::Workflow>)

The workflows which match the request.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable resources.

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::GetWorkflowRequest

Request for the
[GetWorkflow][google.cloud.workflows.v1beta.Workflows.GetWorkflow] method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the workflow which information should be retrieved.
Format: projects/{project}/locations/{location}/workflows/{workflow}

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::CreateWorkflowRequest

Request for the
[CreateWorkflow][google.cloud.workflows.v1beta.Workflows.CreateWorkflow]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Project and location in which the workflow should be created.
Format:  projects/{project}/locations/{location}

=item * C<< $msg->workflow() >> / C<< $msg->workflow($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::V1beta::Workflows::Workflow>)

Required. Workflow to be created.

=item * C<< $msg->workflow_id() >> / C<< $msg->workflow_id($value) >>

Type: C<String>

Required. The ID of the workflow to be created. It has to fulfill the
following requirements:

* Must contain only letters, numbers, underscores and hyphens.
* Must start with a letter.
* Must be between 1-64 characters.
* Must end with a number or a letter.
* Must be unique within the customer project and location.

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::DeleteWorkflowRequest

Request for the
[DeleteWorkflow][google.cloud.workflows.v1beta.Workflows.DeleteWorkflow]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the workflow to be deleted.
Format: projects/{project}/locations/{location}/workflows/{workflow}

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::UpdateWorkflowRequest

Request for the
[UpdateWorkflow][google.cloud.workflows.v1beta.Workflows.UpdateWorkflow]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->workflow() >> / C<< $msg->workflow($value) >>

Type: C<Message> (L<Google::Cloud::Workflows::V1beta::Workflows::Workflow>)

Required. Workflow to be updated.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

List of fields to be updated. If not present, the entire workflow
will be updated.

=back

=head2 Google::Cloud::Workflows::V1beta::Workflows::OperationMetadata

Represents the metadata of the long-running operation.

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

Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Name of the verb executed by the operation.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

API version used to start the operation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Workflows::V1beta::Workflows::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
