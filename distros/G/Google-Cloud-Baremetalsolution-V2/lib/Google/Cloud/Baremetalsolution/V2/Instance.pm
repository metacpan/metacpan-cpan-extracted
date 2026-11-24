package Google::Cloud::Baremetalsolution::V2::Instance;

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
    eval { require Google::Cloud::Baremetalsolution::V2::Common };
    eval { require Google::Cloud::Baremetalsolution::V2::Lun };
    eval { require Google::Cloud::Baremetalsolution::V2::Network };
    eval { require Google::Cloud::Baremetalsolution::V2::Volume };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmFyZW1ldGFsc29sdXRpb24vdjIvaW5zdGFuY2UucHJvdG8SIWdv
b2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxouZ29vZ2xlL2Nsb3VkL2Jh
cmVtZXRhbHNvbHV0aW9uL3YyL2NvbW1vbi5wcm90bxorZ29vZ2xlL2Nsb3VkL2JhcmVtZXRh
bHNvbHV0aW9uL3YyL2x1bi5wcm90bxovZ29vZ2xlL2Nsb3VkL2JhcmVtZXRhbHNvbHV0aW9u
L3YyL25ldHdvcmsucHJvdG8aLmdvb2dsZS9jbG91ZC9iYXJlbWV0YWxzb2x1dGlvbi92Mi92
b2x1bWUucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsMLCghJbnN0YW5jZRIXCgRuYW1lGAEgASgJQgPg
QQVSBG5hbWUSEwoCaWQYCyABKAlCA+BBA1ICaWQSQAoLY3JlYXRlX3RpbWUYAiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
JgoMbWFjaGluZV90eXBlGAQgASgJQgPgQQVSC21hY2hpbmVUeXBlEkwKBXN0YXRlGAUgASgO
MjEuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLkluc3RhbmNlLlN0YXRlQgPg
QQNSBXN0YXRlEjUKFmh5cGVydGhyZWFkaW5nX2VuYWJsZWQYBiABKAhSFWh5cGVydGhyZWFk
aW5nRW5hYmxlZBJPCgZsYWJlbHMYByADKAsyNy5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29s
dXRpb24udjIuSW5zdGFuY2UuTGFiZWxzRW50cnlSBmxhYmVscxI/CgRsdW5zGAggAygLMiYu
Z29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLkx1bkID4EEFUgRsdW5zEkgKB3Zv
bHVtZXMYECADKAsyKS5nb29nbGUuY2xvdWQuYmFyZW1ldGFsc29sdXRpb24udjIuVm9sdW1l
QgPgQQRSB3ZvbHVtZXMSSwoIbmV0d29ya3MYCSADKAsyKi5nb29nbGUuY2xvdWQuYmFyZW1l
dGFsc29sdXRpb24udjIuTmV0d29ya0ID4EEDUghuZXR3b3JrcxJQCiJpbnRlcmFjdGl2ZV9z
ZXJpYWxfY29uc29sZV9lbmFibGVkGAogASgIQgPgQQNSH2ludGVyYWN0aXZlU2VyaWFsQ29u
c29sZUVuYWJsZWQSGQoIb3NfaW1hZ2UYDCABKAlSB29zSW1hZ2USFQoDcG9kGA0gASgJQgPg
QQVSA3BvZBJmChBuZXR3b3JrX3RlbXBsYXRlGA4gASgJQjv6QTgKNmJhcmVtZXRhbHNvbHV0
aW9uLmdvb2dsZWFwaXMuY29tL1NlcnZlck5ldHdvcmtUZW1wbGF0ZVIPbmV0d29ya1RlbXBs
YXRlEmIKEmxvZ2ljYWxfaW50ZXJmYWNlcxgPIAMoCzIzLmdvb2dsZS5jbG91ZC5iYXJlbWV0
YWxzb2x1dGlvbi52Mi5Mb2dpY2FsSW50ZXJmYWNlUhFsb2dpY2FsSW50ZXJmYWNlcxIiCgps
b2dpbl9pbmZvGBEgASgJQgPgQQNSCWxvZ2luSW5mbxJdChB3b3JrbG9hZF9wcm9maWxlGBIg
ASgOMjIuZ29vZ2xlLmNsb3VkLmJhcmVtZXRhbHNvbHV0aW9uLnYyLldvcmtsb2FkUHJvZmls
ZVIPd29ya2xvYWRQcm9maWxlEi4KEGZpcm13YXJlX3ZlcnNpb24YEyABKAlCA+BBA1IPZmly
bXdhcmVWZXJzaW9uGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl
GAIgASgJUgV2YWx1ZToCOAEiggEKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASEAoM
UFJPVklTSU9OSU5HEAESCwoHUlVOTklORxACEgsKB0RFTEVURUQQAxIMCghVUERBVElORxAE
EgwKCFNUQVJUSU5HEAUSDAoIU1RPUFBJTkcQBhIMCghTSFVURE9XThAHOmzqQWkKKWJhcmVt
ZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlEjxwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0iWwoSR2V0SW5z
dGFuY2VSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopYmFyZW1ldGFsc29sdXRpb24u
Z29vZ2xlYXBpcy5jb20vSW5zdGFuY2VSBG5hbWUirQEKFExpc3RJbnN0YW5jZXNSZXF1ZXN0
EkEKBnBhcmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9j
YXRpb25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9r
ZW4YAyABKAlSCXBhZ2VUb2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlciKsAQoVTGlzdElu
c3RhbmNlc1Jlc3BvbnNlEkkKCWluc3RhbmNlcxgBIAMoCzIrLmdvb2dsZS5jbG91ZC5iYXJl
bWV0YWxzb2x1dGlvbi52Mi5JbnN0YW5jZVIJaW5zdGFuY2VzEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbhIgCgt1bnJlYWNoYWJsZRgDIAMoCVILdW5yZWFjaGFi
bGUiogEKFVVwZGF0ZUluc3RhbmNlUmVxdWVzdBJMCghpbnN0YW5jZRgBIAEoCzIrLmdvb2ds
ZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5JbnN0YW5jZUID4EECUghpbnN0YW5jZRI7
Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0
ZU1hc2siiwEKFVJlbmFtZUluc3RhbmNlUmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsK
KWJhcmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lEisKD25l
d19pbnN0YW5jZV9pZBgCIAEoCUID4EECUg1uZXdJbnN0YW5jZUlkIl0KFFJlc2V0SW5zdGFu
Y2VSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopYmFyZW1ldGFsc29sdXRpb24uZ29v
Z2xlYXBpcy5jb20vSW5zdGFuY2VSBG5hbWUiXQoUU3RhcnRJbnN0YW5jZVJlcXVlc3QSRQoE
bmFtZRgBIAEoCUIx4EEC+kErCiliYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9J
bnN0YW5jZVIEbmFtZSIXChVTdGFydEluc3RhbmNlUmVzcG9uc2UiXAoTU3RvcEluc3RhbmNl
UmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKWJhcmVtZXRhbHNvbHV0aW9uLmdvb2ds
ZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lIhYKFFN0b3BJbnN0YW5jZVJlc3BvbnNlIm4KJUVu
YWJsZUludGVyYWN0aXZlU2VyaWFsQ29uc29sZVJlcXVlc3QSRQoEbmFtZRgBIAEoCUIx4EEC
+kErCiliYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9JbnN0YW5jZVIEbmFtZSIo
CiZFbmFibGVJbnRlcmFjdGl2ZVNlcmlhbENvbnNvbGVSZXNwb25zZSJvCiZEaXNhYmxlSW50
ZXJhY3RpdmVTZXJpYWxDb25zb2xlUmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKWJh
cmVtZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlUgRuYW1lIikKJ0Rpc2Fi
bGVJbnRlcmFjdGl2ZVNlcmlhbENvbnNvbGVSZXNwb25zZSLCAQoQRGV0YWNoTHVuUmVxdWVz
dBJNCghpbnN0YW5jZRgBIAEoCUIx4EEC+kErCiliYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVh
cGlzLmNvbS9JbnN0YW5jZVIIaW5zdGFuY2USPgoDbHVuGAIgASgJQizgQQL6QSYKJGJhcmVt
ZXRhbHNvbHV0aW9uLmdvb2dsZWFwaXMuY29tL0x1blIDbHVuEh8KC3NraXBfcmVib290GAMg
ASgIUgpza2lwUmVib290IvQEChVTZXJ2ZXJOZXR3b3JrVGVtcGxhdGUSFwoEbmFtZRgBIAEo
CUID4EEDUgRuYW1lEjoKGWFwcGxpY2FibGVfaW5zdGFuY2VfdHlwZXMYAiADKAlSF2FwcGxp
Y2FibGVJbnN0YW5jZVR5cGVzEngKEmxvZ2ljYWxfaW50ZXJmYWNlcxgDIAMoCzJJLmdvb2ds
ZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52Mi5TZXJ2ZXJOZXR3b3JrVGVtcGxhdGUuTG9n
aWNhbEludGVyZmFjZVIRbG9naWNhbEludGVyZmFjZXMa8wEKEExvZ2ljYWxJbnRlcmZhY2US
EgoEbmFtZRgBIAEoCVIEbmFtZRJrCgR0eXBlGAIgASgOMlcuZ29vZ2xlLmNsb3VkLmJhcmVt
ZXRhbHNvbHV0aW9uLnYyLlNlcnZlck5ldHdvcmtUZW1wbGF0ZS5Mb2dpY2FsSW50ZXJmYWNl
LkludGVyZmFjZVR5cGVSBHR5cGUSGgoIcmVxdWlyZWQYAyABKAhSCHJlcXVpcmVkIkIKDUlu
dGVyZmFjZVR5cGUSHgoaSU5URVJGQUNFX1RZUEVfVU5TUEVDSUZJRUQQABIICgRCT05EEAES
BwoDTklDEAI6lQHqQZEBCjZiYXJlbWV0YWxzb2x1dGlvbi5nb29nbGVhcGlzLmNvbS9TZXJ2
ZXJOZXR3b3JrVGVtcGxhdGUSV3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0
aW9ufS9zZXJ2ZXJOZXR3b3JrVGVtcGxhdGUve3NlcnZlcl9uZXR3b3JrX3RlbXBsYXRlfUL8
AQolY29tLmdvb2dsZS5jbG91ZC5iYXJlbWV0YWxzb2x1dGlvbi52MkINSW5zdGFuY2VQcm90
b1ABWlNjbG91ZC5nb29nbGUuY29tL2dvL2JhcmVtZXRhbHNvbHV0aW9uL2FwaXYyL2JhcmVt
ZXRhbHNvbHV0aW9ucGI7YmFyZW1ldGFsc29sdXRpb25wYqoCIUdvb2dsZS5DbG91ZC5CYXJl
TWV0YWxTb2x1dGlvbi5WMsoCIUdvb2dsZVxDbG91ZFxCYXJlTWV0YWxTb2x1dGlvblxWMuoC
JEdvb2dsZTo6Q2xvdWQ6OkJhcmVNZXRhbFNvbHV0aW9uOjpWMkqGVgoHEgUOAOsCAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAOAoJCgIDAxIDFQA1CgkKAgMEEgMWADkKCQoCAwUSAxcAOAoJ
CgIDBhIDGAAqCgkKAgMHEgMZACkKCAoBCBIDGwA+CgkKAgglEgMbAD4KCAoBCBIDHABqCgkK
AggLEgMcAGoKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAuCgkKAggIEgMeAC4KCAoB
CBIDHwA+CgkKAggBEgMfAD4KCAoBCBIDIAA+CgkKAggpEgMgAD4KCAoBCBIDIQA9CgkKAggt
EgMhAD0KGAoCBAASBSQAlgEBGgsgQSBzZXJ2ZXIuCgoKCgMEAAESAyQIEAoLCgMEAAcSBCUC
KAQKDQoFBAAHnQgSBCUCKAQKNAoEBAAEABIEKwJDAxomIFRoZSBwb3NzaWJsZSBzdGF0ZXMg
Zm9yIHRoaXMgc2VydmVyLgoKDAoFBAAEAAESAysHDAozCgYEAAQAAgASAy0EGhokIFRoZSBz
ZXJ2ZXIgaXMgaW4gYW4gdW5rbm93biBzdGF0ZS4KCg4KBwQABAACAAESAy0EFQoOCgcEAAQA
AgACEgMtGBkKMQoGBAAEAAIBEgMwBBUaIiBUaGUgc2VydmVyIGlzIGJlaW5nIHByb3Zpc2lv
bmVkLgoKDgoHBAAEAAIBARIDMAQQCg4KBwQABAACAQISAzATFAonCgYEAAQAAgISAzMEEBoY
IFRoZSBzZXJ2ZXIgaXMgcnVubmluZy4KCg4KBwQABAACAgESAzMECwoOCgcEAAQAAgICEgMz
Dg8KLQoGBAAEAAIDEgM2BBAaHiBUaGUgc2VydmVyIGhhcyBiZWVuIGRlbGV0ZWQuCgoOCgcE
AAQAAgMBEgM2BAsKDgoHBAAEAAIDAhIDNg4PCi0KBgQABAACBBIDOQQRGh4gVGhlIHNlcnZl
ciBpcyBiZWluZyB1cGRhdGVkLgoKDgoHBAAEAAIEARIDOQQMCg4KBwQABAACBAISAzkPEAoo
CgYEAAQAAgUSAzwEERoZIFRoZSBzZXJ2ZXIgaXMgc3RhcnRpbmcuCgoOCgcEAAQAAgUBEgM8
BAwKDgoHBAAEAAIFAhIDPA8QCigKBgQABAACBhIDPwQRGhkgVGhlIHNlcnZlciBpcyBzdG9w
cGluZy4KCg4KBwQABAACBgESAz8EDAoOCgcEAAQAAgYCEgM/DxAKKAoGBAAEAAIHEgNCBBEa
GSBUaGUgc2VydmVyIGlzIHNodXRkb3duLgoKDgoHBAAEAAIHARIDQgQMCg4KBwQABAACBwIS
A0IPEAqCAgoEBAACABIDSgI8GvQBIEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhpcyBgSW5zdGFuY2VgLgogUmVzb3VyY2UgbmFtZXMgYXJlIHNjaGVtZWxlc3MgVVJJcyB0
aGF0IGZvbGxvdyB0aGUgY29udmVudGlvbnMgaW4KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9hcGlzL2Rlc2lnbi9yZXNvdXJjZV9uYW1lcy4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoMCgUE
AAIABRIDSgIICgwKBQQAAgABEgNKCQ0KDAoFBAACAAMSA0oQEQoMCgUEAAIACBIDShI7Cg8K
CAQAAgAInAgAEgNKEzoKVwoEBAACARIDTQI9GkogT3V0cHV0IG9ubHkuIEFuIGlkZW50aWZp
ZXIgZm9yIHRoZSBgSW5zdGFuY2VgLCBnZW5lcmF0ZWQgYnkgdGhlIGJhY2tlbmQuCgoMCgUE
AAIBBRIDTQIICgwKBQQAAgEBEgNNCQsKDAoFBAACAQMSA00OEAoMCgUEAAIBCBIDTRE8Cg8K
CAQAAgEInAgAEgNNEjsKMQoEBAACAhIEUAJRMhojIE91dHB1dCBvbmx5LiBDcmVhdGUgYSB0
aW1lIHN0YW1wLgoKDAoFBAACAgYSA1ACGwoMCgUEAAICARIDUBwnCgwKBQQAAgIDEgNQKisK
DAoFBAACAggSA1EGMQoPCggEAAICCJwIABIDUQcwCjEKBAQAAgMSBFQCVTIaIyBPdXRwdXQg
b25seS4gVXBkYXRlIGEgdGltZSBzdGFtcC4KCgwKBQQAAgMGEgNUAhsKDAoFBAACAwESA1Qc
JwoMCgUEAAIDAxIDVCorCgwKBQQAAgMIEgNVBjEKDwoIBAACAwicCAASA1UHMAqTAQoEBAAC
BBIDWgJEGoUBIEltbXV0YWJsZS4gVGhlIHNlcnZlciB0eXBlLgogW0F2YWlsYWJsZSBzZXJ2
ZXIKIHR5cGVzXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYmFyZS1tZXRhbC9kb2NzL2Jt
cy1wbGFubmluZyNzZXJ2ZXJfY29uZmlndXJhdGlvbnMpCgoMCgUEAAIEBRIDWgIICgwKBQQA
AgQBEgNaCRUKDAoFBAACBAMSA1oYGQoMCgUEAAIECBIDWhpDCg8KCAQAAgQInAgAEgNaG0IK
NAoEBAACBRIDXQI+GicgT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgc2VydmVyLgoK
DAoFBAACBQYSA10CBwoMCgUEAAIFARIDXQgNCgwKBQQAAgUDEgNdEBEKDAoFBAACBQgSA10S
PQoPCggEAAIFCJwIABIDXRM8Cm4KBAQAAgYSA2ECIhphIFRydWUgaWYgeW91IGVuYWJsZSBo
eXBlcnRocmVhZGluZyBmb3IgdGhlIHNlcnZlciwgb3RoZXJ3aXNlIGZhbHNlLgogVGhlIGRl
ZmF1bHQgdmFsdWUgaXMgZmFsc2UuCgoMCgUEAAIGBRIDYQIGCgwKBQQAAgYBEgNhBx0KDAoF
BAACBgMSA2EgIQopCgQEAAIHEgNkAiEaHCBMYWJlbHMgYXMga2V5IHZhbHVlIHBhaXJzLgoK
DAoFBAACBwYSA2QCFQoMCgUEAAIHARIDZBYcCgwKBQQAAgcDEgNkHyAKQwoEBAACCBIDZwJC
GjYgSW1tdXRhYmxlLiBMaXN0IG9mIExVTnMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc2VydmVy
LgoKDAoFBAACCAQSA2cCCgoMCgUEAAIIBhIDZwsOCgwKBQQAAggBEgNnDxMKDAoFBAACCAMS
A2cWFwoMCgUEAAIICBIDZxhBCg8KCAQAAggInAgAEgNnGUAKiAEKBAQAAgkSA2sCShp7IElu
cHV0IG9ubHkuIExpc3Qgb2YgVm9sdW1lcyB0byBhdHRhY2ggdG8gdGhpcyBJbnN0YW5jZSBv
biBjcmVhdGlvbi4KIFRoaXMgZmllbGQgd29uJ3QgYmUgcG9wdWxhdGVkIGluIEdldC9MaXN0
IHJlc3BvbnNlcy4KCgwKBQQAAgkEEgNrAgoKDAoFBAACCQYSA2sLEQoMCgUEAAIJARIDaxIZ
CgwKBQQAAgkDEgNrHB4KDAoFBAACCQgSA2sfSQoPCggEAAIJCJwIABIDayBICkkKBAQAAgoS
A24CTBo8IE91dHB1dCBvbmx5LiBMaXN0IG9mIG5ldHdvcmtzIGFzc29jaWF0ZWQgd2l0aCB0
aGlzIHNlcnZlci4KCgwKBQQAAgoEEgNuAgoKDAoFBAACCgYSA24LEgoMCgUEAAIKARIDbhMb
CgwKBQQAAgoDEgNuHh8KDAoFBAACCggSA24gSwoPCggEAAIKCJwIABIDbiFKCpcBCgQEAAIL
EgRyAnMyGogBIE91dHB1dCBvbmx5LiBUcnVlIGlmIHRoZSBpbnRlcmFjdGl2ZSBzZXJpYWwg
Y29uc29sZSBmZWF0dXJlIGlzIGVuYWJsZWQgZm9yCiB0aGUgaW5zdGFuY2UsIGZhbHNlIG90
aGVyd2lzZS4gVGhlIGRlZmF1bHQgdmFsdWUgaXMgZmFsc2UuCgoMCgUEAAILBRIDcgIGCgwK
BQQAAgsBEgNyBykKDAoFBAACCwMSA3IsLgoMCgUEAAILCBIDcwYxCg8KCAQAAgsInAgAEgNz
BzAKPgoEBAACDBIDdgIXGjEgVGhlIE9TIGltYWdlIGN1cnJlbnRseSBpbnN0YWxsZWQgb24g
dGhlIHNlcnZlci4KCgwKBQQAAgwFEgN2AggKDAoFBAACDAESA3YJEQoMCgUEAAIMAxIDdhQW
CrEBCgQEAAINEgN8AjwaowEgSW1tdXRhYmxlLiBQb2QgbmFtZS4KIFBvZCBpcyBhbiBpbmRl
cGVuZGVudCBwYXJ0IG9mIGluZnJhc3RydWN0dXJlLgogSW5zdGFuY2UgY2FuIGJlIGNvbm5l
Y3RlZCB0byB0aGUgYXNzZXRzIChuZXR3b3Jrcywgdm9sdW1lcykgYWxsb2NhdGVkCiBpbiB0
aGUgc2FtZSBwb2Qgb25seS4KCgwKBQQAAg0FEgN8AggKDAoFBAACDQESA3wJDAoMCgUEAAIN
AxIDfA8RCgwKBQQAAg0IEgN8EjsKDwoIBAACDQicCAASA3wTOgqrAQoEBAACDhIGgQECgwEF
GpoBIEluc3RhbmNlIG5ldHdvcmsgdGVtcGxhdGUgbmFtZS4gRm9yIGVnLCBib25kYWEtYm9u
ZGFhLCBib25kYWItbmljLCBldGMuCiBHZW5lcmFsbHksIHRoZSB0ZW1wbGF0ZSBuYW1lIGZv
bGxvd3MgdGhlIHN5bnRheCBvZgogImJvbmQ8Ym9uZF9tb2RlPiIgb3IgIm5pYyIuCgoNCgUE
AAIOBRIEgQECCAoNCgUEAAIOARIEgQEJGQoNCgUEAAIOAxIEgQEcHgoPCgUEAAIOCBIGgQEf
gwEEChEKBwQAAg4InwgSBoEBIIMBAwruAwoEBAACDxIEjAECNBrfAyBMaXN0IG9mIGxvZ2lj
YWwgaW50ZXJmYWNlcyBmb3IgdGhlIGluc3RhbmNlLiBUaGUgbnVtYmVyIG9mIGxvZ2ljYWwK
IGludGVyZmFjZXMgd2lsbCBiZSB0aGUgc2FtZSBhcyBudW1iZXIgb2YgaGFyZHdhcmUgYm9u
ZC9uaWMgb24gdGhlIGNob3NlbgogbmV0d29yayB0ZW1wbGF0ZS4gRm9yIHRoZSBub24tbXVs
dGl2bGFuIGNvbmZpZ3VyYXRpb25zIChmb3IgZWcsIGV4aXN0aW5nCiBzZXJ2ZXJzKSB0aGF0
IHVzZSBleGlzdGluZyBkZWZhdWx0IG5ldHdvcmsgdGVtcGxhdGUgKGJvbmRhYS1ib25kYWEp
LCBib3RoCiB0aGUgSW5zdGFuY2UubmV0d29ya3MgZmllbGQgYW5kIHRoZSBJbnN0YW5jZS5s
b2dpY2FsX2ludGVyZmFjZXMgZmllbGRzIHdpbGwKIGJlIGZpbGxlZCB0byBlbnN1cmUgYmFj
a3dhcmQgY29tcGF0aWJpbGl0eS4gRm9yIHRoZSBvdGhlcnMsIG9ubHkKIEluc3RhbmNlLmxv
Z2ljYWxfaW50ZXJmYWNlcyB3aWxsIGJlIGZpbGxlZC4KCg0KBQQAAg8EEgSMAQIKCg0KBQQA
Ag8GEgSMAQsbCg0KBQQAAg8BEgSMARwuCg0KBQQAAg8DEgSMATEzCkIKBAQAAhASBI8BAkUa
NCBPdXRwdXQgb25seS4gVGV4dCBmaWVsZCBhYm91dCBpbmZvIGZvciBsb2dnaW5nIGluLgoK
DQoFBAACEAUSBI8BAggKDQoFBAACEAESBI8BCRMKDQoFBAACEAMSBI8BFhgKDQoFBAACEAgS
BI8BGUQKEAoIBAACEAicCAASBI8BGkMKNgoEBAACERIEkgECKBooIFRoZSB3b3JrbG9hZCBw
cm9maWxlIGZvciB0aGUgaW5zdGFuY2UuCgoNCgUEAAIRBhIEkgECEQoNCgUEAAIRARIEkgES
IgoNCgUEAAIRAxIEkgElJwpDCgQEAAISEgSVAQJLGjUgT3V0cHV0IG9ubHkuIFRoZSBmaXJt
d2FyZSB2ZXJzaW9uIGZvciB0aGUgaW5zdGFuY2UuCgoNCgUEAAISBRIElQECCAoNCgUEAAIS
ARIElQEJGQoNCgUEAAISAxIElQEcHgoNCgUEAAISCBIElQEfSgoQCggEAAISCJwIABIElQEg
SQo6CgIEARIGmQEAoQEBGiwgTWVzc2FnZSBmb3IgcmVxdWVzdGluZyBzZXJ2ZXIgaW5mb3Jt
YXRpb24uCgoLCgMEAQESBJkBCBoKMQoEBAECABIGmwECoAEEGiEgUmVxdWlyZWQuIE5hbWUg
b2YgdGhlIHJlc291cmNlLgoKDQoFBAECAAUSBJsBAggKDQoFBAECAAESBJsBCQ0KDQoFBAEC
AAMSBJsBEBEKDwoFBAECAAgSBpsBEqABAwoQCggEAQIACJwIABIEnAEEKgoRCgcEAQIACJ8I
EgadAQSfAQUKOwoCBAISBqQBALYBARotIE1lc3NhZ2UgZm9yIHJlcXVlc3RpbmcgdGhlIGxp
c3Qgb2Ygc2VydmVycy4KCgsKAwQCARIEpAEIHApCCgQEAgIAEgamAQKrAQQaMiBSZXF1aXJl
ZC4gUGFyZW50IHZhbHVlIGZvciBMaXN0SW5zdGFuY2VzUmVxdWVzdC4KCg0KBQQCAgAFEgSm
AQIICg0KBQQCAgABEgSmAQkPCg0KBQQCAgADEgSmARITCg8KBQQCAgAIEgamARSrAQMKEAoI
BAICAAicCAASBKcBBCoKEQoHBAICAAifCBIGqAEEqgEFCpEBCgQEAgIBEgSvAQIWGoIBIFJl
cXVlc3RlZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1zIHRoYW4g
cmVxdWVzdGVkLgogSWYgdW5zcGVjaWZpZWQsIHRoZSBzZXJ2ZXIgd2lsbCBwaWNrIGFuIGFw
cHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAgIBBRIErwECBwoNCgUEAgIBARIErwEIEQoNCgUE
AgIBAxIErwEUFQpGCgQEAgICEgSyAQIYGjggQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ug
b2YgcmVzdWx0cyBmcm9tIHRoZSBzZXJ2ZXIuCgoNCgUEAgICBRIEsgECCAoNCgUEAgICARIE
sgEJEwoNCgUEAgICAxIEsgEWFwocCgQEAgIDEgS1AQIUGg4gTGlzdCBmaWx0ZXIuCgoNCgUE
AgIDBRIEtQECCAoNCgUEAgIDARIEtQEJDwoNCgUEAgIDAxIEtQESEwo5CgIEAxIGuQEAwgEB
GisgUmVzcG9uc2UgbWVzc2FnZSBmb3IgdGhlIGxpc3Qgb2Ygc2VydmVycy4KCgsKAwQDARIE
uQEIHQokCgQEAwIAEgS7AQIiGhYgVGhlIGxpc3Qgb2Ygc2VydmVycy4KCg0KBQQDAgAEEgS7
AQIKCg0KBQQDAgAGEgS7AQsTCg0KBQQDAgABEgS7ARQdCg0KBQQDAgADEgS7ASAhCkYKBAQD
AgESBL4BAh0aOCBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIGZyb20g
dGhlIHNlcnZlci4KCg0KBQQDAgEFEgS+AQIICg0KBQQDAgEBEgS+AQkYCg0KBQQDAgEDEgS+
ARscCjQKBAQDAgISBMEBAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hl
ZC4KCg0KBQQDAgIEEgTBAQIKCg0KBQQDAgIFEgTBAQsRCg0KBQQDAgIBEgTBARIdCg0KBQQD
AgIDEgTBASAhCjgKAgQEEgbFAQDSAQEaKiBNZXNzYWdlIHJlcXVlc3RpbmcgdG8gdXBkYXRp
bmcgYSBzZXJ2ZXIuCgoLCgMEBAESBMUBCB0KtQEKBAQEAgASBMoBAkEapgEgUmVxdWlyZWQu
IFRoZSBzZXJ2ZXIgdG8gdXBkYXRlLgoKIFRoZSBgbmFtZWAgZmllbGQgaXMgdXNlZCB0byBp
ZGVudGlmeSB0aGUgaW5zdGFuY2UgdG8gdXBkYXRlLgogRm9ybWF0OiBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0KCg0KBQQE
AgAGEgTKAQIKCg0KBQQEAgABEgTKAQsTCg0KBQQEAgADEgTKARYXCg0KBQQEAgAIEgTKARhA
ChAKCAQEAgAInAgAEgTKARk/CogBCgQEBAIBEgTRAQIsGnogVGhlIGxpc3Qgb2YgZmllbGRz
IHRvIHVwZGF0ZS4KIFRoZSBjdXJyZW50bHkgc3VwcG9ydGVkIGZpZWxkcyBhcmU6CiAgIGBs
YWJlbHNgCiAgIGBoeXBlcnRocmVhZGluZ19lbmFibGVkYAogICBgb3NfaW1hZ2VgCgoNCgUE
BAIBBhIE0QECGwoNCgUEBAIBARIE0QEcJwoNCgUEBAIBAxIE0QEqKwo2CgIEBRIG1QEA4QEB
GiggTWVzc2FnZSByZXF1ZXN0aW5nIHJlbmFtZSBvZiBhIHNlcnZlci4KCgsKAwQFARIE1QEI
HQqVAQoEBAUCABIG2AEC3QEEGoQBIFJlcXVpcmVkLiBUaGUgYG5hbWVgIGZpZWxkIGlzIHVz
ZWQgdG8gaWRlbnRpZnkgdGhlIGluc3RhbmNlLgogRm9ybWF0OiBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0KCg0KBQQFAgAF
EgTYAQIICg0KBQQFAgABEgTYAQkNCg0KBQQFAgADEgTYARARCg8KBQQFAgAIEgbYARLdAQMK
EAoIBAUCAAicCAASBNkBBCoKEQoHBAUCAAifCBIG2gEE3AEFCjcKBAQFAgESBOABAkYaKSBS
ZXF1aXJlZC4gVGhlIG5ldyBgaWRgIG9mIHRoZSBpbnN0YW5jZS4KCg0KBQQFAgEFEgTgAQII
Cg0KBQQFAgEBEgTgAQkYCg0KBQQFAgEDEgTgARscCg0KBQQFAgEIEgTgAR1FChAKCAQFAgEI
nAgAEgTgAR5ECjUKAgQGEgbkAQDsAQEaJyBNZXNzYWdlIHJlcXVlc3RpbmcgdG8gcmVzZXQg
YSBzZXJ2ZXIuCgoLCgMEBgESBOQBCBwKMQoEBAYCABIG5gEC6wEEGiEgUmVxdWlyZWQuIE5h
bWUgb2YgdGhlIHJlc291cmNlLgoKDQoFBAYCAAUSBOYBAggKDQoFBAYCAAESBOYBCQ0KDQoF
BAYCAAMSBOYBEBEKDwoFBAYCAAgSBuYBEusBAwoQCggEBgIACJwIABIE5wEEKgoRCgcEBgIA
CJ8IEgboAQTqAQUKNQoCBAcSBu8BAPcBARonIE1lc3NhZ2UgcmVxdWVzdGluZyB0byBzdGFy
dCBhIHNlcnZlci4KCgsKAwQHARIE7wEIHAoxCgQEBwIAEgbxAQL2AQQaISBSZXF1aXJlZC4g
TmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEBwIABRIE8QECCAoNCgUEBwIAARIE8QEJDQoN
CgUEBwIAAxIE8QEQEQoPCgUEBwIACBIG8QES9gEDChAKCAQHAgAInAgAEgTyAQQqChEKBwQH
AgAInwgSBvMBBPUBBQo2CgIECBIE+gEAIBoqIFJlc3BvbnNlIG1lc3NhZ2UgZnJvbSBzdGFy
dGluZyBhIHNlcnZlci4KCgsKAwQIARIE+gEIHQo0CgIECRIG/QEAhQIBGiYgTWVzc2FnZSBy
ZXF1ZXN0aW5nIHRvIHN0b3AgYSBzZXJ2ZXIuCgoLCgMECQESBP0BCBsKMQoEBAkCABIG/wEC
hAIEGiEgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDQoFBAkCAAUSBP8BAggK
DQoFBAkCAAESBP8BCQ0KDQoFBAkCAAMSBP8BEBEKDwoFBAkCAAgSBv8BEoQCAwoQCggECQIA
CJwIABIEgAIEKgoRCgcECQIACJ8IEgaBAgSDAgUKNgoCBAoSBIgCAB8aKiBSZXNwb25zZSBt
ZXNzYWdlIGZyb20gc3RvcHBpbmcgYSBzZXJ2ZXIuCgoLCgMECgESBIgCCBwKUwoCBAsSBosC
AJMCARpFIE1lc3NhZ2UgZm9yIGVuYWJsaW5nIHRoZSBpbnRlcmFjdGl2ZSBzZXJpYWwgY29u
c29sZSBvbiBhbiBpbnN0YW5jZS4KCgsKAwQLARIEiwIILQoxCgQECwIAEgaNAgKSAgQaISBS
ZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUECwIABRIEjQICCAoNCgUECwIA
ARIEjQIJDQoNCgUECwIAAxIEjQIQEQoPCgUECwIACBIGjQISkgIDChAKCAQLAgAInAgAEgSO
AgQqChEKBwQLAgAInwgSBo8CBJECBQpFCgIEDBIElgIAMRo5IE1lc3NhZ2UgZm9yIHJlc3Bv
bnNlIG9mIEVuYWJsZUludGVyYWN0aXZlU2VyaWFsQ29uc29sZS4KCgsKAwQMARIElgIILgpU
CgIEDRIGmQIAoQIBGkYgTWVzc2FnZSBmb3IgZGlzYWJsaW5nIHRoZSBpbnRlcmFjdGl2ZSBz
ZXJpYWwgY29uc29sZSBvbiBhbiBpbnN0YW5jZS4KCgsKAwQNARIEmQIILgoxCgQEDQIAEgab
AgKgAgQaISBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEDQIABRIEmwIC
CAoNCgUEDQIAARIEmwIJDQoNCgUEDQIAAxIEmwIQEQoPCgUEDQIACBIGmwISoAIDChAKCAQN
AgAInAgAEgScAgQqChEKBwQNAgAInwgSBp0CBJ8CBQpGCgIEDhIEpAIAMho6IE1lc3NhZ2Ug
Zm9yIHJlc3BvbnNlIG9mIERpc2FibGVJbnRlcmFjdGl2ZVNlcmlhbENvbnNvbGUuCgoLCgME
DgESBKQCCC8KQQoCBA8SBqcCALoCARozIE1lc3NhZ2UgZm9yIGRldGFjaCBzcGVjaWZpYyBM
VU4gZnJvbSBhbiBJbnN0YW5jZS4KCgsKAwQPARIEpwIIGAoxCgQEDwIAEgapAgKuAgQaISBS
ZXF1aXJlZC4gTmFtZSBvZiB0aGUgaW5zdGFuY2UuCgoNCgUEDwIABRIEqQICCAoNCgUEDwIA
ARIEqQIJEQoNCgUEDwIAAxIEqQIUFQoPCgUEDwIACBIGqQIWrgIDChAKCAQPAgAInAgAEgSq
AgQqChEKBwQPAgAInwgSBqsCBK0CBQo2CgQEDwIBEgaxAgK2AgQaJiBSZXF1aXJlZC4gTmFt
ZSBvZiB0aGUgTHVuIHRvIGRldGFjaC4KCg0KBQQPAgEFEgSxAgIICg0KBQQPAgEBEgSxAgkM
Cg0KBQQPAgEDEgSxAg8QCg8KBQQPAgEIEgaxAhG2AgMKEAoIBA8CAQicCAASBLICBCoKEQoH
BA8CAQifCBIGswIEtQIFCkgKBAQPAgISBLkCAhcaOiBJZiB0cnVlLCBwZXJmb3JtcyBsdW4g
dW5tYXBwaW5nIHdpdGhvdXQgaW5zdGFuY2UgcmVib290LgoKDQoFBA8CAgUSBLkCAgYKDQoF
BA8CAgESBLkCBxIKDQoFBA8CAgMSBLkCFRYKIQoCBBASBr0CAOsCARoTIE5ldHdvcmsgdGVt
cGxhdGUuCgoLCgMEEAESBL0CCB0KDQoDBBAHEga+AgLBAgQKDwoFBBAHnQgSBr4CAsECBAok
CgQEEAMAEgbEAgLdAgMaFCBMb2dpY2FsIGludGVyZmFjZS4KCg0KBQQQAwABEgTEAgoaCiMK
BgQQAwAEABIGxgIEzwIFGhEgSW50ZXJmYWNlIHR5cGUuCgoPCgcEEAMABAABEgTGAgkWCiYK
CAQQAwAEAAIAEgTIAgYlGhQgVW5zcGVjaWZpZWQgdmFsdWUuCgoRCgkEEAMABAACAAESBMgC
BiAKEQoJBBADAAQAAgACEgTIAiMkCigKCAQQAwAEAAIBEgTLAgYPGhYgQm9uZCBpbnRlcmZh
Y2UgdHlwZS4KChEKCQQQAwAEAAIBARIEywIGCgoRCgkEEAMABAACAQISBMsCDQ4KJwoIBBAD
AAQAAgISBM4CBg4aFSBOSUMgaW50ZXJmYWNlIHR5cGUuCgoRCgkEEAMABAACAgESBM4CBgkK
EQoJBBADAAQAAgICEgTOAgwNCowCCgYEEAMAAgASBNYCBBQa+wEgSW50ZXJmYWNlIG5hbWUu
CiBUaGlzIGlzIG5vdCBhIGdsb2JhbGx5IHVuaXF1ZSBpZGVudGlmaWVyLgogTmFtZSBpcyB1
bmlxdWUgb25seSBpbnNpZGUgdGhlIFNlcnZlck5ldHdvcmtUZW1wbGF0ZS4gVGhpcyBpcyBv
ZiBzeW50YXgKIDxib25kPjxpbnRlcmZhY2VfdHlwZV9pbmRleD48Ym9uZF9tb2RlPiBvciA8
bmljPjxpbnRlcmZhY2VfdHlwZV9pbmRleD4KIGFuZCBmb3JtcyBwYXJ0IG9mIHRoZSBuZXR3
b3JrIHRlbXBsYXRlIG5hbWUuCgoPCgcEEAMAAgAFEgTWAgQKCg8KBwQQAwACAAESBNYCCw8K
DwoHBBADAAIAAxIE1gISEwohCgYEEAMAAgESBNkCBBsaESBJbnRlcmZhY2UgdHlwZS4KCg8K
BwQQAwACAQYSBNkCBBEKDwoHBBADAAIBARIE2QISFgoPCgcEEAMAAgEDEgTZAhkaCkEKBgQQ
AwACAhIE3AIEFhoxIElmIHRydWUsIGludGVyZmFjZSBtdXN0IGhhdmUgbmV0d29yayBjb25u
ZWN0ZWQuCgoPCgcEEAMAAgIFEgTcAgQICg8KBwQQAwACAgESBNwCCREKDwoHBBADAAICAxIE
3AIUFQrGAgoEBBACABIE5AICPhq3AiBPdXRwdXQgb25seS4gVGVtcGxhdGUncyB1bmlxdWUg
bmFtZS4gVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBmb2xsb3dzIHRoZQogcGF0dGVybjoKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmVyTmV0d29ya1Rl
bXBsYXRlL3tzZXJ2ZXJfbmV0d29ya190ZW1wbGF0ZX1gCiBHZW5lcmFsbHksIHRoZSB7c2Vy
dmVyX25ldHdvcmtfdGVtcGxhdGV9IGZvbGxvd3MgdGhlIHN5bnRheCBvZgogImJvbmQ8aW50
ZXJmYWNlX3R5cGVfaW5kZXg+PGJvbmRfbW9kZT4iIG9yICJuaWM8aW50ZXJmYWNlX3R5cGVf
aW5kZXg+Ii4KCg0KBQQQAgAFEgTkAgIICg0KBQQQAgABEgTkAgkNCg0KBQQQAgADEgTkAhAR
Cg0KBQQQAgAIEgTkAhI9ChAKCAQQAgAInAgAEgTkAhM8Cj4KBAQQAgESBOcCAjAaMCBJbnN0
YW5jZSB0eXBlcyB0aGlzIHRlbXBsYXRlIGlzIGFwcGxpY2FibGUgdG8uCgoNCgUEEAIBBBIE
5wICCgoNCgUEEAIBBRIE5wILEQoNCgUEEAIBARIE5wISKwoNCgUEEAIBAxIE5wIuLwojCgQE
EAICEgTqAgIzGhUgTG9naWNhbCBpbnRlcmZhY2VzLgoKDQoFBBACAgQSBOoCAgoKDQoFBBAC
AgYSBOoCCxsKDQoFBBACAgESBOoCHC4KDQoFBBACAgMSBOoCMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::Instance ===
    # Fields for Instance
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: machine_type Type: 9 ()
    # Field: state Type: 14 (.google.cloud.baremetalsolution.v2.Instance.State)
    # Field: hyperthreading_enabled Type: 8 ()
    # Field: labels Type: 11 (.google.cloud.baremetalsolution.v2.Instance.LabelsEntry)
    # Field: luns Type: 11 (.google.cloud.baremetalsolution.v2.Lun)
    # Field: volumes Type: 11 (.google.cloud.baremetalsolution.v2.Volume)
    # Field: networks Type: 11 (.google.cloud.baremetalsolution.v2.Network)
    # Field: interactive_serial_console_enabled Type: 8 ()
    # Field: os_image Type: 9 ()
    # Field: pod Type: 9 ()
    # Field: network_template Type: 9 ()
    # Field: logical_interfaces Type: 11 (.google.cloud.baremetalsolution.v2.LogicalInterface)
    # Field: login_info Type: 9 ()
    # Field: workload_profile Type: 14 (.google.cloud.baremetalsolution.v2.WorkloadProfile)
    # Field: firmware_version Type: 9 ()

# Enum: Instance::State
our $Instance_STATE_UNSPECIFIED = 0;
our $Instance_PROVISIONING = 1;
our $Instance_RUNNING = 2;
our $Instance_DELETED = 3;
our $Instance_UPDATING = 4;
our $Instance_STARTING = 5;
our $Instance_STOPPING = 6;
our $Instance_SHUTDOWN = 7;

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::GetInstanceRequest ===
    # Fields for GetInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesRequest ===
    # Fields for ListInstancesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesResponse ===
    # Fields for ListInstancesResponse
    # Field: instances Type: 11 (.google.cloud.baremetalsolution.v2.Instance)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::UpdateInstanceRequest ===
    # Fields for UpdateInstanceRequest
    # Field: instance Type: 11 (.google.cloud.baremetalsolution.v2.Instance)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::RenameInstanceRequest ===
    # Fields for RenameInstanceRequest
    # Field: name Type: 9 ()
    # Field: new_instance_id Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::ResetInstanceRequest ===
    # Fields for ResetInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceRequest ===
    # Fields for StartInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceResponse ===
    # Fields for StartInstanceResponse

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceRequest ===
    # Fields for StopInstanceRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceResponse ===
    # Fields for StopInstanceResponse

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleRequest ===
    # Fields for EnableInteractiveSerialConsoleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleResponse ===
    # Fields for EnableInteractiveSerialConsoleResponse

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleRequest ===
    # Fields for DisableInteractiveSerialConsoleRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleResponse ===
    # Fields for DisableInteractiveSerialConsoleResponse

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::DetachLunRequest ===
    # Fields for DetachLunRequest
    # Field: instance Type: 9 ()
    # Field: lun Type: 9 ()
    # Field: skip_reboot Type: 8 ()

# === Message: Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate ===
    # Fields for ServerNetworkTemplate
    # Field: name Type: 9 ()
    # Field: applicable_instance_types Type: 9 ()
    # Field: logical_interfaces Type: 11 (.google.cloud.baremetalsolution.v2.ServerNetworkTemplate.LogicalInterface)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Instance - Compiled Protocol Buffers messages for google/cloud/baremetalsolution/v2/instance.proto

=head1 SYNOPSIS

    use Google::Cloud::Baremetalsolution::V2::Instance;

    my $msg = Google::Cloud::Baremetalsolution::V2::Instance::Instance->new({
        name => $name,
        id => $id,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Baremetalsolution::V2::Instance::Instance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/baremetalsolution/v2/instance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Baremetalsolution::V2::Instance::Instance

A server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of this `Instance`.
Resource names are schemeless URIs that follow the conventions in
https://cloud.google.com/apis/design/resource_names.
Format:
`projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Output only. An identifier for the `Instance`, generated by the backend.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create a time stamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update a time stamp.

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

Immutable. The server type.
[Available server
types](https://cloud.google.com/bare-metal/docs/bms-planning#server_configurations)

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::Instance::State>)

Output only. The state of the server.

=item * C<< $msg->hyperthreading_enabled() >> / C<< $msg->hyperthreading_enabled($value) >>

Type: C<Bool>

True if you enable hyperthreading for the server, otherwise false.
The default value is false.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Instance::Instance::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->luns() >> / C<< $msg->luns($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Lun::Lun>)

Immutable. List of LUNs associated with this server.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Volume::Volume>)

Input only. List of Volumes to attach to this Instance on creation.
This field won't be populated in Get/List responses.

=item * C<< $msg->networks() >> / C<< $msg->networks($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::Network>)

Output only. List of networks associated with this server.

=item * C<< $msg->interactive_serial_console_enabled() >> / C<< $msg->interactive_serial_console_enabled($value) >>

Type: C<Bool>

Output only. True if the interactive serial console feature is enabled for
the instance, false otherwise. The default value is false.

=item * C<< $msg->os_image() >> / C<< $msg->os_image($value) >>

Type: C<String>

The OS image currently installed on the server.

=item * C<< $msg->pod() >> / C<< $msg->pod($value) >>

Type: C<String>

Immutable. Pod name.
Pod is an independent part of infrastructure.
Instance can be connected to the assets (networks, volumes) allocated
in the same pod only.

=item * C<< $msg->network_template() >> / C<< $msg->network_template($value) >>

Type: C<String>

Instance network template name. For eg, bondaa-bondaa, bondab-nic, etc.
Generally, the template name follows the syntax of
"bond<bond_mode>" or "nic".

=item * C<< $msg->logical_interfaces() >> / C<< $msg->logical_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface>)

List of logical interfaces for the instance. The number of logical
interfaces will be the same as number of hardware bond/nic on the chosen
network template. For the non-multivlan configurations (for eg, existing
servers) that use existing default network template (bondaa-bondaa), both
the Instance.networks field and the Instance.logical_interfaces fields will
be filled to ensure backward compatibility. For the others, only
Instance.logical_interfaces will be filled.

=item * C<< $msg->login_info() >> / C<< $msg->login_info($value) >>

Type: C<String>

Output only. Text field about info for logging in.

=item * C<< $msg->workload_profile() >> / C<< $msg->workload_profile($value) >>

Type: C<Enum> (L<Google::Cloud::Baremetalsolution::V2::WorkloadProfile>)

The workload profile for the instance.

=item * C<< $msg->firmware_version() >> / C<< $msg->firmware_version($value) >>

Type: C<String>

Output only. The firmware version for the instance.

=back

=head3 Enum: Instance::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<DELETED> => C<3>

=item * C<UPDATING> => C<4>

=item * C<STARTING> => C<5>

=item * C<STOPPING> => C<6>

=item * C<SHUTDOWN> => C<7>

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::GetInstanceRequest

Message for requesting server information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesRequest

Message for requesting the list of servers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListInstancesRequest.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Requested page size. Server may return fewer items than requested.
If unspecified, the server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

List filter.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesResponse

Response message for the list of servers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instances() >> / C<< $msg->instances($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Instance::Instance>)

The list of servers.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results from the server.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::UpdateInstanceRequest

Message requesting to updating a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Instance::Instance>)

Required. The server to update.

The `name` field is used to identify the instance to update.
Format: projects/{project}/locations/{location}/instances/{instance}

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The list of fields to update.
The currently supported fields are:
  `labels`
  `hyperthreading_enabled`
  `os_image`

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::RenameInstanceRequest

Message requesting rename of a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The `name` field is used to identify the instance.
Format: projects/{project}/locations/{location}/instances/{instance}

=item * C<< $msg->new_instance_id() >> / C<< $msg->new_instance_id($value) >>

Type: C<String>

Required. The new `id` of the instance.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::ResetInstanceRequest

Message requesting to reset a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceRequest

Message requesting to start a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceResponse

Response message from starting a server.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceRequest

Message requesting to stop a server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceResponse

Response message from stopping a server.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleRequest

Message for enabling the interactive serial console on an instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleResponse

Message for response of EnableInteractiveSerialConsole.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleRequest

Message for disabling the interactive serial console on an instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleResponse

Message for response of DisableInteractiveSerialConsole.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Baremetalsolution::V2::Instance::DetachLunRequest

Message for detach specific LUN from an Instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->instance() >> / C<< $msg->instance($value) >>

Type: C<String>

Required. Name of the instance.

=item * C<< $msg->lun() >> / C<< $msg->lun($value) >>

Type: C<String>

Required. Name of the Lun to detach.

=item * C<< $msg->skip_reboot() >> / C<< $msg->skip_reboot($value) >>

Type: C<Bool>

If true, performs lun unmapping without instance reboot.

=back

=head2 Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate

Network template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Template's unique name. The full resource name follows the
pattern:
`projects/{project}/locations/{location}/serverNetworkTemplate/{server_network_template}`
Generally, the {server_network_template} follows the syntax of
"bond<interface_type_index><bond_mode>" or "nic<interface_type_index>".

=item * C<< $msg->applicable_instance_types() >> / C<< $msg->applicable_instance_types($value) >>

Type: C<String>

Instance types this template is applicable to.

=item * C<< $msg->logical_interfaces() >> / C<< $msg->logical_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate::LogicalInterface>)

Logical interfaces.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Baremetalsolution::V2::Instance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
