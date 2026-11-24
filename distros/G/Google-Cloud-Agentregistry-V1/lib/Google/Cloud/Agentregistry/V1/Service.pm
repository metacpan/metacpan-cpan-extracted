package Google::Cloud::Agentregistry::V1::Service;

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
    eval { require Google::Cloud::Agentregistry::V1::Properties };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9zZXJ2aWNlLnByb3RvEh1nb29nbGUu
Y2xvdWQuYWdlbnRyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxouZ29vZ2xlL2Nsb3VkL2FnZW50cmVnaXN0
cnkvdjEvcHJvcGVydGllcy5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKTCwoHU2VydmljZRJWCgphZ2VudF9z
cGVjGAUgASgLMjAuZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuU2VydmljZS5BZ2Vu
dFNwZWNCA+BBAUgAUglhZ2VudFNwZWMSYwoPbWNwX3NlcnZlcl9zcGVjGAYgASgLMjQuZ29v
Z2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuU2VydmljZS5NY3BTZXJ2ZXJTcGVjQgPgQQFI
AFINbWNwU2VydmVyU3BlYxJfCg1lbmRwb2ludF9zcGVjGAcgASgLMjMuZ29vZ2xlLmNsb3Vk
LmFnZW50cmVnaXN0cnkudjEuU2VydmljZS5FbmRwb2ludFNwZWNCA+BBAUgAUgxlbmRwb2lu
dFNwZWMSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID
4EEBUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID4EEBUgtkZXNjcmlwdGlv
bhJNCgppbnRlcmZhY2VzGAQgAygLMiguZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEu
SW50ZXJmYWNlQgPgQQFSCmludGVyZmFjZXMSMAoRcmVnaXN0cnlfcmVzb3VyY2UYCiABKAlC
A+BBA1IQcmVnaXN0cnlSZXNvdXJjZRJACgtjcmVhdGVfdGltZRgIIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgJIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRrVAQoJQWdl
bnRTcGVjElEKBHR5cGUYASABKA4yNS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MS5T
ZXJ2aWNlLkFnZW50U3BlYy5UeXBlQgbgQQLgQQVSBHR5cGUSNgoHY29udGVudBgCIAEoCzIX
Lmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBAVIHY29udGVudCI9CgRUeXBlEhQKEFRZUEVf
VU5TUEVDSUZJRUQQABILCgdOT19TUEVDEAESEgoOQTJBX0FHRU5UX0NBUkQQAhrYAQoNTWNw
U2VydmVyU3BlYxJVCgR0eXBlGAEgASgOMjkuZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnku
djEuU2VydmljZS5NY3BTZXJ2ZXJTcGVjLlR5cGVCBuBBAuBBBVIEdHlwZRI2Cgdjb250ZW50
GAIgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEBUgdjb250ZW50IjgKBFR5cGUS
FAoQVFlQRV9VTlNQRUNJRklFRBAAEgsKB05PX1NQRUMQARINCglUT09MX1NQRUMQAhrHAQoM
RW5kcG9pbnRTcGVjElQKBHR5cGUYASABKA4yOC5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3Ry
eS52MS5TZXJ2aWNlLkVuZHBvaW50U3BlYy5UeXBlQgbgQQLgQQVSBHR5cGUSNgoHY29udGVu
dBgCIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBAVIHY29udGVudCIpCgRUeXBl
EhQKEFRZUEVfVU5TUEVDSUZJRUQQABILCgdOT19TUEVDEAE6eOpBdQokYWdlbnRyZWdpc3Ry
eS5nb29nbGVhcGlzLmNvbS9TZXJ2aWNlEjpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vc2VydmljZXMve3NlcnZpY2V9KghzZXJ2aWNlczIHc2VydmljZUIGCgRz
cGVjQt8BCiFjb20uZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjFCDFNlcnZpY2VQcm90
b1ABWkdjbG91ZC5nb29nbGUuY29tL2dvL2FnZW50cmVnaXN0cnkvYXBpdjEvYWdlbnRyZWdp
c3RyeXBiO2FnZW50cmVnaXN0cnlwYqoCHUdvb2dsZS5DbG91ZC5BZ2VudFJlZ2lzdHJ5LlYx
ygIdR29vZ2xlXENsb3VkXEFnZW50UmVnaXN0cnlcVjHqAiBHb29nbGU6OkNsb3VkOjpBZ2Vu
dFJlZ2lzdHJ5OjpWMUrhKwoHEgUOAKQBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAJgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAOAoJCgID
AxIDFQAmCgkKAgMEEgMWACkKCAoBCBIDGAA6CgkKAgglEgMYADoKCAoBCBIDGQBeCgkKAggL
EgMZAF4KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAtCgkKAggIEgMbAC0KCAoBCBID
HAA6CgkKAggBEgMcADoKCAoBCBIDHQA6CgkKAggpEgMdADoKCAoBCBIDHgA5CgkKAggtEgMe
ADkKMQoCBAASBSEApAEBGiQgUmVwcmVzZW50cyBhIHVzZXItZGVmaW5lZCBTZXJ2aWNlLgoK
CgoDBAABEgMhCA8KCwoDBAAHEgQiAicECg0KBQQAB50IEgQiAicECiYKBAQAAwASBCoCQgMa
GCBUaGUgc3BlYyBvZiB0aGUgYWdlbnQuCgoMCgUEAAMAARIDKgoTCi0KBgQAAwAEABIELAQ2
BRodIFRoZSB0eXBlIG9mIHRoZSBhZ2VudCBzcGVjLgoKDgoHBAADAAQAARIDLAkNCiQKCAQA
AwAEAAIAEgMuBhsaEyBVbnNwZWNpZmllZCB0eXBlLgoKEAoJBAADAAQAAgABEgMuBhYKEAoJ
BAADAAQAAgACEgMuGRoKVQoIBAADAAQAAgESAzEGEhpEIFRoZXJlIGlzIG5vIHNwZWMgZm9y
IHRoZSBBZ2VudC4gVGhlIGBjb250ZW50YCBmaWVsZCBtdXN0IGJlIGVtcHR5LgoKEAoJBAAD
AAQAAgEBEgMxBg0KEAoJBAADAAQAAgECEgMxEBEKewoIBAADAAQAAgISAzUGGRpqIFRoZSBj
b250ZW50IGlzIGFuIEEyQSBBZ2VudCBDYXJkIGZvbGxvd2luZyB0aGUgQTJBIHNwZWNpZmlj
YXRpb24uCiBUaGUgYGludGVyZmFjZXNgIGZpZWxkIG11c3QgYmUgZW1wdHkuCgoQCgkEAAMA
BAACAgESAzUGFAoQCgkEAAMABAACAgISAzUXGApKCgYEAAMAAgASBDkEPAYaOiBSZXF1aXJl
ZC4gSW1tdXRhYmxlLiBUaGUgdHlwZSBvZiB0aGUgYWdlbnQgc3BlYyBjb250ZW50LgoKDgoH
BAADAAIABhIDOQQICg4KBwQAAwACAAESAzkJDQoOCgcEAAMAAgADEgM5EBEKDwoHBAADAAIA
CBIEORI8BQoRCgoEAAMAAgAInAgAEgM6BiwKEQoKBAADAAIACJwIARIDOwYtCrsBCgYEAAMA
AgESA0EEUBqrASBPcHRpb25hbC4gVGhlIGNvbnRlbnQgb2YgdGhlIEFnZW50IHNwZWMgaW4g
dGhlIEpTT04gZm9ybWF0LgogVGhpcyBwYXlsb2FkIGlzIHZhbGlkYXRlZCBhZ2FpbnN0IHRo
ZSBzY2hlbWEgZm9yIHRoZSBzcGVjaWZpZWQgdHlwZS4KIFRoZSBjb250ZW50IHNpemUgaXMg
bGltaXRlZCB0byBgMTBLQmAuCgoOCgcEAAMAAgEGEgNBBBoKDgoHBAADAAIBARIDQRsiCg4K
BwQAAwACAQMSA0ElJgoOCgcEAAMAAgEIEgNBJ08KEQoKBAADAAIBCJwIABIDQShOCisKBAQA
AwESBEUCXgMaHSBUaGUgc3BlYyBvZiB0aGUgTUNQIFNlcnZlci4KCgwKBQQAAwEBEgNFChcK
YQoGBAADAQQAEgRIBFIFGlEgVGhlIHR5cGUgb2YgdGhlIE1DUCBTZXJ2ZXIgc3BlYy4gQWRk
aXRpb25hbCB2YWx1ZXMgbWF5IGJlIGFkZGVkIGluIHRoZQogZnV0dXJlLgoKDgoHBAADAQQA
ARIDSAkNCiQKCAQAAwEEAAIAEgNKBhsaEyBVbnNwZWNpZmllZCB0eXBlLgoKEAoJBAADAQQA
AgABEgNKBhYKEAoJBAADAQQAAgACEgNKGRoKWgoIBAADAQQAAgESA00GEhpJIFRoZXJlIGlz
IG5vIHNwZWMgZm9yIHRoZSBNQ1AgU2VydmVyLiBUaGUgYGNvbnRlbnRgIGZpZWxkIG11c3Qg
YmUgZW1wdHkuCgoQCgkEAAMBBAACAQESA00GDQoQCgkEAAMBBAACAQISA00QEQqNAQoIBAAD
AQQAAgISA1EGFBp8IFRoZSBjb250ZW50IGlzIGEgTUNQIFRvb2wgU3BlYyBmb2xsb3dpbmcg
dGhlIE9uZSBNQ1Agc3BlY2lmaWNhdGlvbi4KIFRoZSBwYXlsb2FkIGlzIHRoZSBzYW1lIGFz
IHRoZSBgdG9vbHMvbGlzdGAgcmVzcG9uc2UuCgoQCgkEAAMBBAACAgESA1EGDwoQCgkEAAMB
BAACAgISA1ESEwpPCgYEAAMBAgASBFUEWAYaPyBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUg
dHlwZSBvZiB0aGUgTUNQIFNlcnZlciBzcGVjIGNvbnRlbnQuCgoOCgcEAAMBAgAGEgNVBAgK
DgoHBAADAQIAARIDVQkNCg4KBwQAAwECAAMSA1UQEQoPCgcEAAMBAgAIEgRVElgFChEKCgQA
AwECAAicCAASA1YGLAoRCgoEAAMBAgAInAgBEgNXBi0KrQEKBgQAAwECARIDXQRQGp0BIE9w
dGlvbmFsLiBUaGUgY29udGVudCBvZiB0aGUgTUNQIFNlcnZlciBzcGVjLgogVGhpcyBwYXls
b2FkIGlzIHZhbGlkYXRlZCBhZ2FpbnN0IHRoZSBzY2hlbWEgZm9yIHRoZSBzcGVjaWZpZWQg
dHlwZS4KIFRoZSBjb250ZW50IHNpemUgaXMgbGltaXRlZCB0byBgMTBLQmAuCgoOCgcEAAMB
AgEGEgNdBBoKDgoHBAADAQIBARIDXRsiCg4KBwQAAwECAQMSA10lJgoOCgcEAAMBAgEIEgNd
J08KEQoKBAADAQIBCJwIABIDXShOCikKBAQAAwISBGECdQMaGyBUaGUgc3BlYyBvZiB0aGUg
ZW5kcG9pbnQuCgoMCgUEAAMCARIDYQoWCl8KBgQAAwIEABIEZARqBRpPIFRoZSB0eXBlIG9m
IHRoZSBlbmRwb2ludCBzcGVjLiBBZGRpdGlvbmFsIHZhbHVlcyBtYXkgYmUgYWRkZWQgaW4g
dGhlCiBmdXR1cmUuCgoOCgcEAAMCBAABEgNkCQ0KJAoIBAADAgQAAgASA2YGGxoTIFVuc3Bl
Y2lmaWVkIHR5cGUuCgoQCgkEAAMCBAACAAESA2YGFgoQCgkEAAMCBAACAAISA2YZGgpYCggE
AAMCBAACARIDaQYSGkcgVGhlcmUgaXMgbm8gc3BlYyBmb3IgdGhlIEVuZHBvaW50LiBUaGUg
YGNvbnRlbnRgIGZpZWxkIG11c3QgYmUgZW1wdHkuCgoQCgkEAAMCBAACAQESA2kGDQoQCgkE
AAMCBAACAQISA2kQEQpNCgYEAAMCAgASBG0EcAYaPSBSZXF1aXJlZC4gSW1tdXRhYmxlLiBU
aGUgdHlwZSBvZiB0aGUgZW5kcG9pbnQgc3BlYyBjb250ZW50LgoKDgoHBAADAgIABhIDbQQI
Cg4KBwQAAwICAAESA20JDQoOCgcEAAMCAgADEgNtEBEKDwoHBAADAgIACBIEbRJwBQoRCgoE
AAMCAgAInAgAEgNuBiwKEQoKBAADAgIACJwIARIDbwYtClYKBgQAAwICARIDdARQGkcgT3B0
aW9uYWwuIFRoZSBjb250ZW50IG9mIHRoZSBlbmRwb2ludCBzcGVjLgogUmVzZXJ2ZWQgZm9y
IGZ1dHVyZSB1c2UuCgoOCgcEAAMCAgEGEgN0BBoKDgoHBAADAgIBARIDdBsiCg4KBwQAAwIC
AQMSA3QlJgoOCgcEAAMCAgEIEgN0J08KEQoKBAADAgIBCJwIABIDdChOClAKBAQACAASBXgC
hAEDGkEgVGhlIHNwZWMgb2YgdGhlIHNlcnZpY2UuIEF0IGxlYXN0IG9uZSBvZiB0aGUgc3Bl
Y3MgbXVzdCBiZSBzZXQuCgoMCgUEAAgAARIDeAgMCmwKBAQAAgASA3sERhpfIE9wdGlvbmFs
LiBUaGUgc3BlYyBvZiB0aGUgQWdlbnQuIFdoZW4gYGFnZW50X3NwZWNgIGlzIHNldCwgdGhl
IHR5cGUgb2YKIHRoZSBzZXJ2aWNlIGlzIEFnZW50LgoKDAoFBAACAAYSA3sEDQoMCgUEAAIA
ARIDew4YCgwKBQQAAgADEgN7GxwKDAoFBAACAAgSA3sdRQoPCggEAAIACJwIABIDex5ECnsK
BAQAAgESA38ETxpuIE9wdGlvbmFsLiBUaGUgc3BlYyBvZiB0aGUgTUNQIFNlcnZlci4gV2hl
biBgbWNwX3NlcnZlcl9zcGVjYCBpcyBzZXQsIHRoZQogdHlwZSBvZiB0aGUgc2VydmljZSBp
cyBNQ1AgU2VydmVyLgoKDAoFBAACAQYSA38EEQoMCgUEAAIBARIDfxIhCgwKBQQAAgEDEgN/
JCUKDAoFBAACAQgSA38mTgoPCggEAAIBCJwIABIDfydNCnYKBAQAAgISBIMBBEwaaCBPcHRp
b25hbC4gVGhlIHNwZWMgb2YgdGhlIEVuZHBvaW50LiBXaGVuIGBlbmRwb2ludF9zcGVjYCBp
cyBzZXQsIHRoZSB0eXBlCiBvZiB0aGUgc2VydmljZSBpcyBFbmRwb2ludC4KCg0KBQQAAgIG
EgSDAQQQCg0KBQQAAgIBEgSDAREeCg0KBQQAAgIDEgSDASEiCg0KBQQAAgIIEgSDASNLChAK
CAQAAgIInAgAEgSDASRKCoQBCgQEAAIDEgSIAQI9GnYgSWRlbnRpZmllci4gVGhlIHJlc291
cmNlIG5hbWUgb2YgdGhlIFNlcnZpY2UuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vc2VydmljZXMve3NlcnZpY2V9YC4KCg0KBQQAAgMFEgSI
AQIICg0KBQQAAgMBEgSIAQkNCg0KBQQAAgMDEgSIARARCg0KBQQAAgMIEgSIARI8ChAKCAQA
AgMInAgAEgSIARM7CnMKBAQAAgQSBIwBAkMaZSBPcHRpb25hbC4gVXNlci1kZWZpbmVkIGRp
c3BsYXkgbmFtZSBmb3IgdGhlIFNlcnZpY2UuCiBDYW4gaGF2ZSBhIG1heGltdW0gbGVuZ3Ro
IG9mIGA2M2AgY2hhcmFjdGVycy4KCg0KBQQAAgQFEgSMAQIICg0KBQQAAgQBEgSMAQkVCg0K
BQQAAgQDEgSMARgZCg0KBQQAAgQIEgSMARpCChAKCAQAAgQInAgAEgSMARtBCnIKBAQAAgUS
BJABAkIaZCBPcHRpb25hbC4gVXNlci1kZWZpbmVkIGRlc2NyaXB0aW9uIG9mIGFuIFNlcnZp
Y2UuCiBDYW4gaGF2ZSBhIG1heGltdW0gbGVuZ3RoIG9mIGAyMDQ4YCBjaGFyYWN0ZXJzLgoK
DQoFBAACBQUSBJABAggKDQoFBAACBQESBJABCRQKDQoFBAACBQMSBJABFxgKDQoFBAACBQgS
BJABGUEKEAoIBAACBQicCAASBJABGkAKQQoEBAACBhIEkwECTRozIE9wdGlvbmFsLiBUaGUg
Y29ubmVjdGlvbiBkZXRhaWxzIGZvciB0aGUgU2VydmljZS4KCg0KBQQAAgYEEgSTAQIKCg0K
BQQAAgYGEgSTAQsUCg0KBQQAAgYBEgSTARUfCg0KBQQAAgYDEgSTASIjCg0KBQQAAgYIEgST
ASRMChAKCAQAAgYInAgAEgSTASVLCq0CCgQEAAIHEgSbAQJMGp4CIE91dHB1dCBvbmx5LiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgcmVzdWx0aW5nIEFnZW50LCBNQ1AgU2VydmVyLCBv
cgogRW5kcG9pbnQuIEZvcm1hdDoKCiAqIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vbWNwU2VydmVycy97bWNwX3NlcnZlcn1gCiAqIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3thZ2VudH1gCiAqIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZW5kcG9pbnRzL3tlbmRwb2ludH1g
CgoNCgUEAAIHBRIEmwECCAoNCgUEAAIHARIEmwEJGgoNCgUEAAIHAxIEmwEdHwoNCgUEAAIH
CBIEmwEgSwoQCggEAAIHCJwIABIEmwEhSgorCgQEAAIIEgaeAQKfATIaGyBPdXRwdXQgb25s
eS4gQ3JlYXRlIHRpbWUuCgoNCgUEAAIIBhIEngECGwoNCgUEAAIIARIEngEcJwoNCgUEAAII
AxIEngEqKwoNCgUEAAIICBIEnwEGMQoQCggEAAIICJwIABIEnwEHMAorCgQEAAIJEgaiAQKj
ATIaGyBPdXRwdXQgb25seS4gVXBkYXRlIHRpbWUuCgoNCgUEAAIJBhIEogECGwoNCgUEAAIJ
ARIEogEcJwoNCgUEAAIJAxIEogEqKwoNCgUEAAIJCBIEowEGMQoQCggEAAIJCJwIABIEowEH
MGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Service::Service ===
    # Fields for Service
    # Field: agent_spec Type: 11 (.google.cloud.agentregistry.v1.Service.AgentSpec)
    # Field: mcp_server_spec Type: 11 (.google.cloud.agentregistry.v1.Service.McpServerSpec)
    # Field: endpoint_spec Type: 11 (.google.cloud.agentregistry.v1.Service.EndpointSpec)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: interfaces Type: 11 (.google.cloud.agentregistry.v1.Interface)
    # Field: registry_resource Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Service - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Service;

    my $msg = Google::Cloud::Agentregistry::V1::Service::Service->new({
        agent_spec => $agent_spec,
        mcp_server_spec => $mcp_server_spec,
        endpoint_spec => $endpoint_spec,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->agent_spec();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Service::Service

Represents a user-defined Service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->agent_spec() >> / C<< $msg->agent_spec($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Service::Service::AgentSpec>)

Optional. The spec of the Agent. When `agent_spec` is set, the type of
the service is Agent.

=item * C<< $msg->mcp_server_spec() >> / C<< $msg->mcp_server_spec($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Service::Service::McpServerSpec>)

Optional. The spec of the MCP Server. When `mcp_server_spec` is set, the
type of the service is MCP Server.

=item * C<< $msg->endpoint_spec() >> / C<< $msg->endpoint_spec($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Service::Service::EndpointSpec>)

Optional. The spec of the Endpoint. When `endpoint_spec` is set, the type
of the service is Endpoint.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the Service.
Format: `projects/{project}/locations/{location}/services/{service}`.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined display name for the Service.
Can have a maximum length of `63` characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of an Service.
Can have a maximum length of `2048` characters.

=item * C<< $msg->interfaces() >> / C<< $msg->interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Properties::Interface>)

Optional. The connection details for the Service.

=item * C<< $msg->registry_resource() >> / C<< $msg->registry_resource($value) >>

Type: C<String>

Output only. The resource name of the resulting Agent, MCP Server, or
Endpoint. Format:

* `projects/{project}/locations/{location}/mcpServers/{mcp_server}`
* `projects/{project}/locations/{location}/agents/{agent}`
* `projects/{project}/locations/{location}/endpoints/{endpoint}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
