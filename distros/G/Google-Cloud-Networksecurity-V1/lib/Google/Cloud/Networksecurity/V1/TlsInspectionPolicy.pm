package Google::Cloud::Networksecurity::V1::TlsInspectionPolicy;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3Rsc19pbnNwZWN0aW9uX3BvbGlj
eS5wcm90bxIfZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xl
L3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8izwgKE1Rsc0luc3BlY3Rpb25Qb2xpY3kSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1l
EiUKC2Rlc2NyaXB0aW9uGAIgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEkAKC2NyZWF0ZV90aW1l
GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAK
C3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1
cGRhdGVUaW1lEkAKB2NhX3Bvb2wYBSABKAlCJ+BBAvpBIQofcHJpdmF0ZWNhLmdvb2dsZWFw
aXMuY29tL0NhUG9vbFIGY2FQb29sElgKDHRydXN0X2NvbmZpZxgGIAEoCUI14EEB+kEvCi1j
ZXJ0aWZpY2F0ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vVHJ1c3RDb25maWdSC3RydXN0Q29u
ZmlnEjsKFWV4Y2x1ZGVfcHVibGljX2NhX3NldBgHIAEoCEID4EEBSABSEmV4Y2x1ZGVQdWJs
aWNDYVNldIgBARJsCg9taW5fdGxzX3ZlcnNpb24YCCABKA4yPy5nb29nbGUuY2xvdWQubmV0
d29ya3NlY3VyaXR5LnYxLlRsc0luc3BlY3Rpb25Qb2xpY3kuVGxzVmVyc2lvbkID4EEBUg1t
aW5UbHNWZXJzaW9uEnEKE3Rsc19mZWF0dXJlX3Byb2ZpbGUYCSABKA4yPC5nb29nbGUuY2xv
dWQubmV0d29ya3NlY3VyaXR5LnYxLlRsc0luc3BlY3Rpb25Qb2xpY3kuUHJvZmlsZUID4EEB
UhF0bHNGZWF0dXJlUHJvZmlsZRIzChNjdXN0b21fdGxzX2ZlYXR1cmVzGAogAygJQgPgQQFS
EWN1c3RvbVRsc0ZlYXR1cmVzIl0KClRsc1ZlcnNpb24SGwoXVExTX1ZFUlNJT05fVU5TUEVD
SUZJRUQQABILCgdUTFNfMV8wEAESCwoHVExTXzFfMRACEgsKB1RMU18xXzIQAxILCgdUTFNf
MV8zEAQiegoHUHJvZmlsZRIXChNQUk9GSUxFX1VOU1BFQ0lGSUVEEAASFgoSUFJPRklMRV9D
T01QQVRJQkxFEAESEgoOUFJPRklMRV9NT0RFUk4QAhIWChJQUk9GSUxFX1JFU1RSSUNURUQQ
AxISCg5QUk9GSUxFX0NVU1RPTRAEOo8B6kGLAQoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFw
aXMuY29tL1Rsc0luc3BlY3Rpb25Qb2xpY3kSVXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS90bHNJbnNwZWN0aW9uUG9saWNpZXMve3Rsc19pbnNwZWN0aW9uX3Bv
bGljeX1CGAoWX2V4Y2x1ZGVfcHVibGljX2NhX3NldCKjAgogQ3JlYXRlVGxzSW5zcGVjdGlv
blBvbGljeVJlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6QTQSMm5ldHdvcmtzZWN1cml0
eS5nb29nbGVhcGlzLmNvbS9UbHNJbnNwZWN0aW9uUG9saWN5UgZwYXJlbnQSPAoYdGxzX2lu
c3BlY3Rpb25fcG9saWN5X2lkGAIgASgJQgPgQQJSFXRsc0luc3BlY3Rpb25Qb2xpY3lJZBJt
ChV0bHNfaW5zcGVjdGlvbl9wb2xpY3kYAyABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3Nl
Y3VyaXR5LnYxLlRsc0luc3BlY3Rpb25Qb2xpY3lCA+BBAlITdGxzSW5zcGVjdGlvblBvbGlj
eSKhAQogTGlzdFRsc0luc3BlY3Rpb25Qb2xpY2llc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJ
QingQQL6QSMKIWxvY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsK
CXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRv
a2VuItsBCiFMaXN0VGxzSW5zcGVjdGlvblBvbGljaWVzUmVzcG9uc2USbAoXdGxzX2luc3Bl
Y3Rpb25fcG9saWNpZXMYASADKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYx
LlRsc0luc3BlY3Rpb25Qb2xpY3lSFXRsc0luc3BlY3Rpb25Qb2xpY2llcxImCg9uZXh0X3Bh
Z2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3Vu
cmVhY2hhYmxlIm8KHUdldFRsc0luc3BlY3Rpb25Qb2xpY3lSZXF1ZXN0Ek4KBG5hbWUYASAB
KAlCOuBBAvpBNAoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL1Rsc0luc3BlY3Rp
b25Qb2xpY3lSBG5hbWUiiAEKIERlbGV0ZVRsc0luc3BlY3Rpb25Qb2xpY3lSZXF1ZXN0Ek4K
BG5hbWUYASABKAlCOuBBAvpBNAoybmV0d29ya3NlY3VyaXR5Lmdvb2dsZWFwaXMuY29tL1Rs
c0luc3BlY3Rpb25Qb2xpY3lSBG5hbWUSFAoFZm9yY2UYAiABKAhSBWZvcmNlItMBCiBVcGRh
dGVUbHNJbnNwZWN0aW9uUG9saWN5UmVxdWVzdBJACgt1cGRhdGVfbWFzaxgBIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzaxJtChV0bHNfaW5zcGVj
dGlvbl9wb2xpY3kYAiABKAsyNC5nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxLlRs
c0luc3BlY3Rpb25Qb2xpY3lCA+BBAlITdGxzSW5zcGVjdGlvblBvbGljeULYAgojY29tLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFCGFRsc0luc3BlY3Rpb25Qb2xpY3lQcm90
b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtzZWN1cml0eS9hcGl2MS9uZXR3b3Jr
c2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCH0dvb2dsZS5DbG91ZC5OZXR3b3JrU2Vj
dXJpdHkuVjHKAh9Hb29nbGVcQ2xvdWRcTmV0d29ya1NlY3VyaXR5XFYx6gIiR29vZ2xlOjpD
bG91ZDo6TmV0d29ya1NlY3VyaXR5OjpWMepBXAofcHJpdmF0ZWNhLmdvb2dsZWFwaXMuY29t
L0NhUG9vbBI5cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NhUG9v
bHMve2NhX3Bvb2x9SvJPCgcSBQ4AiwIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAqCgkKAgMD
EgMVACkKCAoBCBIDFwA8CgkKAgglEgMXADwKCAoBCBIDGABkCgkKAggLEgMYAGQKCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgA5CgkKAggIEgMaADkKCAoBCBIDGwA8CgkKAggBEgMb
ADwKCAoBCBIDHAA8CgkKAggpEgMcADwKCAoBCBIDHQA7CgkKAggtEgMdADsKCQoBCBIEHgAh
AgoMCgQInQgAEgQeACECCooBCgIEABIFJQCkAQEafSBUaGUgVGxzSW5zcGVjdGlvblBvbGlj
eSByZXNvdXJjZSBjb250YWlucyByZWZlcmVuY2VzIHRvIENBIHBvb2xzIGluCiBDZXJ0aWZp
Y2F0ZSBBdXRob3JpdHkgU2VydmljZSBhbmQgYXNzb2NpYXRlZCBtZXRhZGF0YS4KCgoKAwQA
ARIDJQgbCgsKAwQABxIEJgIpBAoNCgUEAAedCBIEJgIpBAqVAQoEBAAEABIELQI8AxqGASBU
aGUgbWluaW11bSB2ZXJzaW9uIG9mIFRMUyBwcm90b2NvbCB0aGF0IGNhbiBiZSB1c2VkIGJ5
IGNsaWVudHMgb3Igc2VydmVycwogdG8gZXN0YWJsaXNoIGEgY29ubmVjdGlvbiB3aXRoIHRo
ZSBUTFMgaW5zcGVjdGlvbiBwcm94eS4KCgwKBQQABAABEgMtBxEKOAoGBAAEAAIAEgMvBCAa
KSBJbmRpY2F0ZXMgbm8gVExTIHZlcnNpb24gd2FzIHNwZWNpZmllZC4KCg4KBwQABAACAAES
Ay8EGwoOCgcEAAQAAgACEgMvHh8KGAoGBAAEAAIBEgMyBBAaCSBUTFMgMS4wCgoOCgcEAAQA
AgEBEgMyBAsKDgoHBAAEAAIBAhIDMg4PChgKBgQABAACAhIDNQQQGgkgVExTIDEuMQoKDgoH
BAAEAAICARIDNQQLCg4KBwQABAACAgISAzUODwoYCgYEAAQAAgMSAzgEEBoJIFRMUyAxLjIK
Cg4KBwQABAACAwESAzgECwoOCgcEAAQAAgMCEgM4Dg8KGAoGBAAEAAIEEgM7BBAaCSBUTFMg
MS4zCgoOCgcEAAQAAgQBEgM7BAsKDgoHBAAEAAIEAhIDOw4PCp4CCgQEAAQBEgRCAlYDGo8C
IFByb2ZpbGUgc3BlY2lmaWVzIHRoZSBzZXQgb2YgVExTIGNpcGhlciBzdWl0ZXMgKGFuZCBw
b3NzaWJseQogb3RoZXIgZmVhdHVyZXMgaW4gdGhlIGZ1dHVyZSkgdGhhdCBjYW4gYmUgdXNl
ZCBieSB0aGUgZmlyZXdhbGwgd2hlbgogbmVnb3RpYXRpbmcgVExTIGNvbm5lY3Rpb25zIHdp
dGggY2xpZW50cyBhbmQgc2VydmVycy4gVGhlIG1lYW5pbmcgb2YgdGhlc2UKIGZpZWxkcyBp
cyBpZGVudGljYWwgdG8gdGhlIGxvYWQgYmFsYW5jZXJzJyBTU0xQb2xpY3kgcmVzb3VyY2Uu
CgoMCgUEAAQBARIDQgcOCjQKBgQABAECABIDRAQcGiUgSW5kaWNhdGVzIG5vIHByb2ZpbGUg
d2FzIHNwZWNpZmllZC4KCg4KBwQABAECAAESA0QEFwoOCgcEAAQBAgACEgNEGhsKrgEKBgQA
BAECARIDSQQbGp4BIENvbXBhdGlibGUgcHJvZmlsZS4gQWxsb3dzIHRoZSBicm9hZGVzdCBz
ZXQgb2YgY2xpZW50cywgZXZlbiB0aG9zZQogd2hpY2ggc3VwcG9ydCBvbmx5IG91dC1vZi1k
YXRlIFNTTCBmZWF0dXJlcyB0byBuZWdvdGlhdGUgd2l0aCB0aGUgVExTCiBpbnNwZWN0aW9u
IHByb3h5LgoKDgoHBAAEAQIBARIDSQQWCg4KBwQABAECAQISA0kZGgqOAQoGBAAEAQICEgNN
BBcafyBNb2Rlcm4gcHJvZmlsZS4gU3VwcG9ydHMgYSB3aWRlIHNldCBvZiBTU0wgZmVhdHVy
ZXMsIGFsbG93aW5nIG1vZGVybgogY2xpZW50cyB0byBuZWdvdGlhdGUgU1NMIHdpdGggdGhl
IFRMUyBpbnNwZWN0aW9uIHByb3h5LgoKDgoHBAAEAQICARIDTQQSCg4KBwQABAECAgISA00V
FgqAAQoGBAAEAQIDEgNRBBsacSBSZXN0cmljdGVkIHByb2ZpbGUuIFN1cHBvcnRzIGEgcmVk
dWNlZCBzZXQgb2YgU1NMIGZlYXR1cmVzLCBpbnRlbmRlZCB0bwogbWVldCBzdHJpY3RlciBj
b21wbGlhbmNlIHJlcXVpcmVtZW50cy4KCg4KBwQABAECAwESA1EEFgoOCgcEAAQBAgMCEgNR
GRoKgQEKBgQABAECBBIDVQQXGnIgQ3VzdG9tIHByb2ZpbGUuIEFsbG93IG9ubHkgdGhlIHNl
dCBvZiBhbGxvd2VkIFNTTCBmZWF0dXJlcyBzcGVjaWZpZWQgaW4KIHRoZSBjdXN0b21fZmVh
dHVyZXMgZmllbGQgb2YgU3NsUG9saWN5LgoKDgoHBAAEAQIEARIDVQQSCg4KBwQABAECBAIS
A1UVFgrwAQoEBAACABIDXAI7GuIBIFJlcXVpcmVkLiBOYW1lIG9mIHRoZSByZXNvdXJjZS4g
TmFtZSBpcyBvZiB0aGUgZm9ybQogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L3Rsc0luc3BlY3Rpb25Qb2xpY2llcy97dGxzX2luc3BlY3Rpb25fcG9saWN5fQog
dGxzX2luc3BlY3Rpb25fcG9saWN5IHNob3VsZCBtYXRjaCB0aGUKIHBhdHRlcm46KF5bYS16
XShbYS16MC05LV17MCw2MX1bYS16MC05XSk/JCkuCgoMCgUEAAIABRIDXAIICgwKBQQAAgAB
EgNcCQ0KDAoFBAACAAMSA1wQEQoMCgUEAAIACBIDXBI6Cg8KCAQAAgAInAgAEgNcEzkKPwoE
BAACARIDXwJCGjIgT3B0aW9uYWwuIEZyZWUtdGV4dCBkZXNjcmlwdGlvbiBvZiB0aGUgcmVz
b3VyY2UuCgoMCgUEAAIBBRIDXwIICgwKBQQAAgEBEgNfCRQKDAoFBAACAQMSA18XGAoMCgUE
AAIBCBIDXxlBCg8KCAQAAgEInAgAEgNfGkAKSQoEBAACAhIEYgJjMho7IE91dHB1dCBvbmx5
LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdhcyBjcmVhdGVkLgoKDAoFBAAC
AgYSA2ICGwoMCgUEAAICARIDYhwnCgwKBQQAAgIDEgNiKisKDAoFBAACAggSA2MGMQoPCggE
AAICCJwIABIDYwcwCkkKBAQAAgMSBGYCZzIaOyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFt
cCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRlZC4KCgwKBQQAAgMGEgNmAhsKDAoFBAAC
AwESA2YcJwoMCgUEAAIDAxIDZiorCgwKBQQAAgMIEgNnBjEKDwoIBAACAwicCAASA2cHMArY
AQoEBAACBBIEbAJxBBrJASBSZXF1aXJlZC4gQSBDQSBwb29sIHJlc291cmNlIHVzZWQgdG8g
aXNzdWUgaW50ZXJjZXB0aW9uIGNlcnRpZmljYXRlcy4KIFRoZSBDQSBwb29sIHN0cmluZyBo
YXMgYSByZWxhdGl2ZSByZXNvdXJjZSBwYXRoIGZvbGxvd2luZyB0aGUgZm9ybQogInByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jYVBvb2xzL3tjYV9wb29sfSIu
CgoMCgUEAAIEBRIDbAIICgwKBQQAAgQBEgNsCRAKDAoFBAACBAMSA2wTFAoNCgUEAAIECBIE
bBVxAwoPCggEAAIECJwIABIDbQQqCg8KBwQAAgQInwgSBG4EcAUKnAMKBAQAAgUSBHkCfgQa
jQMgT3B0aW9uYWwuIEEgVHJ1c3RDb25maWcgcmVzb3VyY2UgdXNlZCB3aGVuIG1ha2luZyBh
IGNvbm5lY3Rpb24gdG8gdGhlIFRMUwogc2VydmVyLiBUaGlzIGlzIGEgcmVsYXRpdmUgcmVz
b3VyY2UgcGF0aCBmb2xsb3dpbmcgdGhlIGZvcm0KICJwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vdHJ1c3RDb25maWdzL3t0cnVzdF9jb25maWd9Ii4gVGhpcwog
aXMgbmVjZXNzYXJ5IHRvIGludGVyY2VwdCBUTFMgY29ubmVjdGlvbnMgdG8gc2VydmVycyB3
aXRoIGNlcnRpZmljYXRlcwogc2lnbmVkIGJ5IGEgcHJpdmF0ZSBDQSBvciBzZWxmLXNpZ25l
ZCBjZXJ0aWZpY2F0ZXMuCiBOb3RlIHRoYXQgU2VjdXJlIFdlYiBQcm94eSBkb2VzIG5vdCB5
ZXQgaG9ub3IgdGhpcyBmaWVsZC4KCgwKBQQAAgUFEgN5AggKDAoFBAACBQESA3kJFQoMCgUE
AAIFAxIDeRgZCg0KBQQAAgUIEgR5Gn4DCg8KCAQAAgUInAgAEgN6BCoKDwoHBAACBQifCBIE
ewR9BQrpBQoEBAACBhIGigECiwEvGtgFIE9wdGlvbmFsLiBJZiAgRkFMU0UgKHRoZSBkZWZh
dWx0KSwgdXNlIG91ciBkZWZhdWx0IHNldCBvZiBwdWJsaWMgQ0FzIGluCiBhZGRpdGlvbiB0
byBhbnkgQ0FzIHNwZWNpZmllZCBpbiB0cnVzdF9jb25maWcuIFRoZXNlIHB1YmxpYyBDQXMg
YXJlCiBjdXJyZW50bHkgYmFzZWQgb24gdGhlIE1vemlsbGEgUm9vdCBQcm9ncmFtIGFuZCBh
cmUgc3ViamVjdCB0byBjaGFuZ2Ugb3ZlcgogdGltZS4gSWYgVFJVRSwgZG8gbm90IGFjY2Vw
dCBvdXIgZGVmYXVsdCBzZXQgb2YgcHVibGljIENBcy4gT25seSBDQXMKIHNwZWNpZmllZCBp
biB0cnVzdF9jb25maWcgd2lsbCBiZSBhY2NlcHRlZC4gVGhpcyBkZWZhdWx0cyB0byBGQUxT
RSAodXNlCiBwdWJsaWMgQ0FzIGluIGFkZGl0aW9uIHRvIHRydXN0X2NvbmZpZykgZm9yIGJh
Y2t3YXJkcyBjb21wYXRpYmlsaXR5LCBidXQKIHRydXN0aW5nIHB1YmxpYyByb290IENBcyBp
cyAqbm90IHJlY29tbWVuZGVkKiB1bmxlc3MgdGhlIHRyYWZmaWMgaW4KIHF1ZXN0aW9uIGlz
IG91dGJvdW5kIHRvIHB1YmxpYyB3ZWIgc2VydmVycy4gV2hlbiBwb3NzaWJsZSwgcHJlZmVy
IHNldHRpbmcKIHRoaXMgdG8gImZhbHNlIiBhbmQgZXhwbGljaXRseSBzcGVjaWZ5aW5nIHRy
dXN0ZWQgQ0FzIGFuZCBjZXJ0aWZpY2F0ZXMgaW4gYQogVHJ1c3RDb25maWcuIE5vdGUgdGhh
dCBTZWN1cmUgV2ViIFByb3h5IGRvZXMgbm90IHlldCBob25vciB0aGlzIGZpZWxkLgoKDQoF
BAACBgQSBIoBAgoKDQoFBAACBgUSBIoBCw8KDQoFBAACBgESBIoBECUKDQoFBAACBgMSBIoB
KCkKDQoFBAACBggSBIsBBi4KEAoIBAACBgicCAASBIsBBy0KxwMKBAQAAgcSBJQBAkoauAMg
T3B0aW9uYWwuIE1pbmltdW0gVExTIHZlcnNpb24gdGhhdCB0aGUgZmlyZXdhbGwgc2hvdWxk
IHVzZSB3aGVuIG5lZ290aWF0aW5nCiBjb25uZWN0aW9ucyB3aXRoIGJvdGggY2xpZW50cyBh
bmQgc2VydmVycy4gSWYgdGhpcyBpcyBub3Qgc2V0LCB0aGVuIHRoZQogZGVmYXVsdCB2YWx1
ZSBpcyB0byBhbGxvdyB0aGUgYnJvYWRlc3Qgc2V0IG9mIGNsaWVudHMgYW5kIHNlcnZlcnMg
KFRMUyAxLjAKIG9yIGhpZ2hlcikuIFNldHRpbmcgdGhpcyB0byBtb3JlIHJlc3RyaWN0aXZl
IHZhbHVlcyBtYXkgaW1wcm92ZSBzZWN1cml0eSwKIGJ1dCBtYXkgYWxzbyBwcmV2ZW50IHRo
ZSBmaXJld2FsbCBmcm9tIGNvbm5lY3RpbmcgdG8gc29tZSBjbGllbnRzIG9yCiBzZXJ2ZXJz
LgogTm90ZSB0aGF0IFNlY3VyZSBXZWIgUHJveHkgZG9lcyBub3QgeWV0IGhvbm9yIHRoaXMg
ZmllbGQuCgoNCgUEAAIHBhIElAECDAoNCgUEAAIHARIElAENHAoNCgUEAAIHAxIElAEfIAoN
CgUEAAIHCBIElAEhSQoQCggEAAIHCJwIABIElAEiSAr9AgoEBAACCBIEmwECSxruAiBPcHRp
b25hbC4gVGhlIHNlbGVjdGVkIFByb2ZpbGUuIElmIHRoaXMgaXMgbm90IHNldCwgdGhlbiB0
aGUgZGVmYXVsdCB2YWx1ZQogaXMgdG8gYWxsb3cgdGhlIGJyb2FkZXN0IHNldCBvZiBjbGll
bnRzIGFuZCBzZXJ2ZXJzICgiUFJPRklMRV9DT01QQVRJQkxFIikuCiBTZXR0aW5nIHRoaXMg
dG8gbW9yZSByZXN0cmljdGl2ZSB2YWx1ZXMgbWF5IGltcHJvdmUgc2VjdXJpdHksIGJ1dCBt
YXkgYWxzbwogcHJldmVudCB0aGUgVExTIGluc3BlY3Rpb24gcHJveHkgZnJvbSBjb25uZWN0
aW5nIHRvIHNvbWUgY2xpZW50cyBvcgogc2VydmVycy4gTm90ZSB0aGF0IFNlY3VyZSBXZWIg
UHJveHkgZG9lcyBub3QgeWV0IGhvbm9yIHRoaXMgZmllbGQuCgoNCgUEAAIIBhIEmwECCQoN
CgUEAAIIARIEmwEKHQoNCgUEAAIIAxIEmwEgIQoNCgUEAAIICBIEmwEiSgoQCggEAAIICJwI
ABIEmwEjSQrNAgoEBAACCRIGogECowEvGrwCIE9wdGlvbmFsLiBMaXN0IG9mIGN1c3RvbSBU
TFMgY2lwaGVyIHN1aXRlcyBzZWxlY3RlZC4KIFRoaXMgZmllbGQgaXMgdmFsaWQgb25seSBp
ZiB0aGUgc2VsZWN0ZWQgdGxzX2ZlYXR1cmVfcHJvZmlsZSBpcyBDVVNUT00uCiBUaGUgW2Nv
bXB1dGUuU3NsUG9saWNpZXNTZXJ2aWNlLkxpc3RBdmFpbGFibGVGZWF0dXJlc11bXSBtZXRo
b2QgcmV0dXJucyB0aGUKIHNldCBvZiBmZWF0dXJlcyB0aGF0IGNhbiBiZSBzcGVjaWZpZWQg
aW4gdGhpcyBsaXN0LgogTm90ZSB0aGF0IFNlY3VyZSBXZWIgUHJveHkgZG9lcyBub3QgeWV0
IGhvbm9yIHRoaXMgZmllbGQuCgoNCgUEAAIJBBIEogECCgoNCgUEAAIJBRIEogELEQoNCgUE
AAIJARIEogESJQoNCgUEAAIJAxIEogEoKgoNCgUEAAIJCBIEowEGLgoQCggEAAIJCJwIABIE
owEHLQpFCgIEARIGpwEAugEBGjcgUmVxdWVzdCB1c2VkIGJ5IHRoZSBDcmVhdGVUbHNJbnNw
ZWN0aW9uUG9saWN5IG1ldGhvZC4KCgsKAwQBARIEpwEIKAqNAQoEBAECABIGqgECrwEEGn0g
UmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugb2YgdGhlIFRsc0luc3BlY3Rpb25Qb2xp
Y3kuIE11c3QgYmUgaW4gdGhlCiBmb3JtYXQgYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufWAuCgoNCgUEAQIABRIEqgECCAoNCgUEAQIAARIEqgEJDwoNCgUEAQIA
AxIEqgESEwoPCgUEAQIACBIGqgEUrwEDChAKCAQBAgAInAgAEgSrAQQqChEKBwQBAgAInwgS
BqwBBK4BBQqFAgoEBAECARIEtQECTxr2ASBSZXF1aXJlZC4gU2hvcnQgbmFtZSBvZiB0aGUg
VGxzSW5zcGVjdGlvblBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgogVGhpcyB2YWx1
ZSBzaG91bGQgYmUgMS02MyBjaGFyYWN0ZXJzIGxvbmcsIGNvbnRhaW5pbmcgb25seQogbGV0
dGVycywgbnVtYmVycywgaHlwaGVucywgYW5kIHVuZGVyc2NvcmVzLCBhbmQgc2hvdWxkIG5v
dCBzdGFydAogd2l0aCBhIG51bWJlci4gRS5nLiAidGxzX2luc3BlY3Rpb25fcG9saWN5MSIu
CgoNCgUEAQIBBRIEtQECCAoNCgUEAQIBARIEtQEJIQoNCgUEAQIBAxIEtQEkJQoNCgUEAQIB
CBIEtQEmTgoQCggEAQIBCJwIABIEtQEnTQpHCgQEAQICEga4AQK5AS8aNyBSZXF1aXJlZC4g
VGxzSW5zcGVjdGlvblBvbGljeSByZXNvdXJjZSB0byBiZSBjcmVhdGVkLgoKDQoFBAECAgYS
BLgBAhUKDQoFBAECAgESBLgBFisKDQoFBAECAgMSBLgBLi8KDQoFBAECAggSBLkBBi4KEAoI
BAECAgicCAASBLkBBy0KRwoCBAISBr0BANABARo5IFJlcXVlc3QgdXNlZCB3aXRoIHRoZSBM
aXN0VGxzSW5zcGVjdGlvblBvbGljaWVzIG1ldGhvZC4KCgsKAwQCARIEvQEIKAqxAQoEBAIC
ABIGwQECxgEEGqABIFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3
aGljaCB0aGUgVGxzSW5zcGVjdGlvblBvbGljaWVzCiBzaG91bGQgYmUgbGlzdGVkLCBzcGVj
aWZpZWQgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufWAuCgoNCgUEAgIABRIEwQECCAoNCgUEAgIAARIEwQEJDwoNCgUEAgIAAxIEwQES
EwoPCgUEAgIACBIGwQEUxgEDChAKCAQCAgAInAgAEgTCAQQqChEKBwQCAgAInwgSBsMBBMUB
BQpLCgQEAgIBEgTJAQIWGj0gTWF4aW11bSBudW1iZXIgb2YgVGxzSW5zcGVjdGlvblBvbGlj
aWVzIHRvIHJldHVybiBwZXIgY2FsbC4KCg0KBQQCAgEFEgTJAQIHCg0KBQQCAgEBEgTJAQgR
Cg0KBQQCAgEDEgTJARQVCuIBCgQEAgICEgTPAQIYGtMBIFRoZSB2YWx1ZSByZXR1cm5lZCBi
eSB0aGUgbGFzdAogJ0xpc3RUbHNJbnNwZWN0aW9uUG9saWNpZXNSZXNwb25zZScgSW5kaWNh
dGVzIHRoYXQgdGhpcyBpcyBhCiBjb250aW51YXRpb24gb2YgYSBwcmlvciAnTGlzdFRsc0lu
c3BlY3Rpb25Qb2xpY2llcycgY2FsbCwgYW5kCiB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJl
dHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoNCgUEAgICBRIEzwECCAoNCgUEAgICARIE
zwEJEwoNCgUEAgICAxIEzwEWFwpKCgIEAxIG0wEA3gEBGjwgUmVzcG9uc2UgcmV0dXJuZWQg
YnkgdGhlIExpc3RUbHNJbnNwZWN0aW9uUG9saWNpZXMgbWV0aG9kLgoKCwoDBAMBEgTTAQgp
CjgKBAQDAgASBNUBAjsaKiBMaXN0IG9mIFRsc0luc3BlY3Rpb25Qb2xpY2llcyByZXNvdXJj
ZXMuCgoNCgUEAwIABBIE1QECCgoNCgUEAwIABhIE1QELHgoNCgUEAwIAARIE1QEfNgoNCgUE
AwIAAxIE1QE5OgrpAQoEBAMCARIE2gECHRraASBJZiB0aGVyZSBtaWdodCBiZSBtb3JlIHJl
c3VsdHMgdGhhbiB0aG9zZSBhcHBlYXJpbmcgaW4gdGhpcyByZXNwb25zZSwgdGhlbgogJ25l
eHRfcGFnZV90b2tlbicgaXMgaW5jbHVkZWQuIFRvIGdldCB0aGUgbmV4dCBzZXQgb2YgcmVz
dWx0cywgY2FsbCB0aGlzCiBtZXRob2QgYWdhaW4gdXNpbmcgdGhlIHZhbHVlIG9mICduZXh0
X3BhZ2VfdG9rZW4nIGFzICdwYWdlX3Rva2VuJy4KCg0KBQQDAgEFEgTaAQIICg0KBQQDAgEB
EgTaAQkYCg0KBQQDAgEDEgTaARscCjQKBAQDAgISBN0BAiIaJiBMb2NhdGlvbnMgdGhhdCBj
b3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQDAgIEEgTdAQIKCg0KBQQDAgIFEgTdAQsRCg0K
BQQDAgIBEgTdARIdCg0KBQQDAgIDEgTdASAhCkIKAgQEEgbhAQDqAQEaNCBSZXF1ZXN0IHVz
ZWQgYnkgdGhlIEdldFRsc0luc3BlY3Rpb25Qb2xpY3kgbWV0aG9kLgoKCwoDBAQBEgThAQgl
CrYBCgQEBAIAEgbkAQLpAQQapQEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgVGxzSW5zcGVj
dGlvblBvbGljeSB0byBnZXQuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90bHNJbnNwZWN0aW9uUG9saWNpZXMve3Rs
c19pbnNwZWN0aW9uX3BvbGljeX1gLgoKDQoFBAQCAAUSBOQBAggKDQoFBAQCAAESBOQBCQ0K
DQoFBAQCAAMSBOQBEBEKDwoFBAQCAAgSBuQBEukBAwoQCggEBAIACJwIABIE5QEEKgoRCgcE
BAIACJ8IEgbmAQToAQUKRQoCBAUSBu0BAPwBARo3IFJlcXVlc3QgdXNlZCBieSB0aGUgRGVs
ZXRlVGxzSW5zcGVjdGlvblBvbGljeSBtZXRob2QuCgoLCgMEBQESBO0BCCgKugEKBAQFAgAS
BvEBAvYBBBqpASBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBUbHNJbnNwZWN0aW9uUG9saWN5
IHRvIGRlbGV0ZS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdAogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90bHNJbnNwZWN0aW9uUG9saWNpZXMve3Rsc19pbnNw
ZWN0aW9uX3BvbGljeX1gLgoKDQoFBAUCAAUSBPEBAggKDQoFBAUCAAESBPEBCQ0KDQoFBAUC
AAMSBPEBEBEKDwoFBAUCAAgSBvEBEvYBAwoQCggEBQIACJwIABIE8gEEKgoRCgcEBQIACJ8I
EgbzAQT1AQUKsAEKBAQFAgESBPsBAhEaoQEgSWYgc2V0IHRvIHRydWUsIGFueSBydWxlcyBm
b3IgdGhpcyBUbHNJbnNwZWN0aW9uUG9saWN5IHdpbGwgYWxzbyBiZQogZGVsZXRlZC4gKE90
aGVyd2lzZSwgdGhlIHJlcXVlc3Qgd2lsbCBvbmx5IHdvcmsgaWYgdGhlIFRsc0luc3BlY3Rp
b25Qb2xpY3kKIGhhcyBubyBydWxlcy4pCgoNCgUEBQIBBRIE+wECBgoNCgUEBQIBARIE+wEH
DAoNCgUEBQIBAxIE+wEPEApFCgIEBhIG/wEAiwIBGjcgUmVxdWVzdCB1c2VkIGJ5IHRoZSBV
cGRhdGVUbHNJbnNwZWN0aW9uUG9saWN5IG1ldGhvZC4KCgsKAwQGARIE/wEIKArlAgoEBAYC
ABIGhQIChgIvGtQCIE9wdGlvbmFsLiBGaWVsZCBtYXNrIGlzIHVzZWQgdG8gc3BlY2lmeSB0
aGUgZmllbGRzIHRvIGJlIG92ZXJ3cml0dGVuIGluIHRoZQogVGxzSW5zcGVjdGlvblBvbGlj
eSByZXNvdXJjZSBieSB0aGUgdXBkYXRlLgogVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhl
IHVwZGF0ZV9tYXNrIGFyZSByZWxhdGl2ZSB0byB0aGUgcmVzb3VyY2UsIG5vdAogdGhlIGZ1
bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuIGlmIGl0IGlzIGluIHRo
ZSBtYXNrLiBJZiB0aGUKIHVzZXIgZG9lcyBub3QgcHJvdmlkZSBhIG1hc2sgdGhlbiBhbGwg
ZmllbGRzIHdpbGwgYmUgb3ZlcndyaXR0ZW4uCgoNCgUEBgIABhIEhQICGwoNCgUEBgIAARIE
hQIcJwoNCgUEBgIAAxIEhQIqKwoNCgUEBgIACBIEhgIGLgoQCggEBgIACJwIABIEhgIHLQpB
CgQEBgIBEgaJAgKKAi8aMSBSZXF1aXJlZC4gVXBkYXRlZCBUbHNJbnNwZWN0aW9uUG9saWN5
IHJlc291cmNlLgoKDQoFBAYCAQYSBIkCAhUKDQoFBAYCAQESBIkCFisKDQoFBAYCAQMSBIkC
Li8KDQoFBAYCAQgSBIoCBi4KEAoIBAYCAQicCAASBIoCBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy ===
    # Fields for TlsInspectionPolicy
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ca_pool Type: 9 ()
    # Field: trust_config Type: 9 ()
    # Field: exclude_public_ca_set Type: 8 ()
    # Field: min_tls_version Type: 14 (.google.cloud.networksecurity.v1.TlsInspectionPolicy.TlsVersion)
    # Field: tls_feature_profile Type: 14 (.google.cloud.networksecurity.v1.TlsInspectionPolicy.Profile)
    # Field: custom_tls_features Type: 9 ()

# Enum: TlsInspectionPolicy::TlsVersion
our $TlsInspectionPolicy_TLS_VERSION_UNSPECIFIED = 0;
our $TlsInspectionPolicy_TLS_1_0 = 1;
our $TlsInspectionPolicy_TLS_1_1 = 2;
our $TlsInspectionPolicy_TLS_1_2 = 3;
our $TlsInspectionPolicy_TLS_1_3 = 4;

# Enum: TlsInspectionPolicy::Profile
our $TlsInspectionPolicy_PROFILE_UNSPECIFIED = 0;
our $TlsInspectionPolicy_PROFILE_COMPATIBLE = 1;
our $TlsInspectionPolicy_PROFILE_MODERN = 2;
our $TlsInspectionPolicy_PROFILE_RESTRICTED = 3;
our $TlsInspectionPolicy_PROFILE_CUSTOM = 4;

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::CreateTlsInspectionPolicyRequest ===
    # Fields for CreateTlsInspectionPolicyRequest
    # Field: parent Type: 9 ()
    # Field: tls_inspection_policy_id Type: 9 ()
    # Field: tls_inspection_policy Type: 11 (.google.cloud.networksecurity.v1.TlsInspectionPolicy)

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesRequest ===
    # Fields for ListTlsInspectionPoliciesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesResponse ===
    # Fields for ListTlsInspectionPoliciesResponse
    # Field: tls_inspection_policies Type: 11 (.google.cloud.networksecurity.v1.TlsInspectionPolicy)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::GetTlsInspectionPolicyRequest ===
    # Fields for GetTlsInspectionPolicyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::DeleteTlsInspectionPolicyRequest ===
    # Fields for DeleteTlsInspectionPolicyRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Message: Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::UpdateTlsInspectionPolicyRequest ===
    # Fields for UpdateTlsInspectionPolicyRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: tls_inspection_policy Type: 11 (.google.cloud.networksecurity.v1.TlsInspectionPolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1::TlsInspectionPolicy - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1/tls_inspection_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::TlsInspectionPolicy;

    my $msg = Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy->new({
        name => $name,
        description => $description,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1/tls_inspection_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy

The TlsInspectionPolicy resource contains references to CA pools in
Certificate Authority Service and associated metadata.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the resource. Name is of the form
projects/{project}/locations/{location}/tlsInspectionPolicies/{tls_inspection_policy}
tls_inspection_policy should match the
pattern:(^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$).

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Free-text description of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->ca_pool() >> / C<< $msg->ca_pool($value) >>

Type: C<String>

Required. A CA pool resource used to issue interception certificates.
The CA pool string has a relative resource path following the form
"projects/{project}/locations/{location}/caPools/{ca_pool}".

=item * C<< $msg->trust_config() >> / C<< $msg->trust_config($value) >>

Type: C<String>

Optional. A TrustConfig resource used when making a connection to the TLS
server. This is a relative resource path following the form
"projects/{project}/locations/{location}/trustConfigs/{trust_config}". This
is necessary to intercept TLS connections to servers with certificates
signed by a private CA or self-signed certificates.
Note that Secure Web Proxy does not yet honor this field.

=item * C<< $msg->exclude_public_ca_set() >> / C<< $msg->exclude_public_ca_set($value) >>

Type: C<Bool>

Optional. If  FALSE (the default), use our default set of public CAs in
addition to any CAs specified in trust_config. These public CAs are
currently based on the Mozilla Root Program and are subject to change over
time. If TRUE, do not accept our default set of public CAs. Only CAs
specified in trust_config will be accepted. This defaults to FALSE (use
public CAs in addition to trust_config) for backwards compatibility, but
trusting public root CAs is *not recommended* unless the traffic in
question is outbound to public web servers. When possible, prefer setting
this to "false" and explicitly specifying trusted CAs and certificates in a
TrustConfig. Note that Secure Web Proxy does not yet honor this field.

=item * C<< $msg->min_tls_version() >> / C<< $msg->min_tls_version($value) >>

Type: C<Enum> (L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsVersion>)

Optional. Minimum TLS version that the firewall should use when negotiating
connections with both clients and servers. If this is not set, then the
default value is to allow the broadest set of clients and servers (TLS 1.0
or higher). Setting this to more restrictive values may improve security,
but may also prevent the firewall from connecting to some clients or
servers.
Note that Secure Web Proxy does not yet honor this field.

=item * C<< $msg->tls_feature_profile() >> / C<< $msg->tls_feature_profile($value) >>

Type: C<Enum> (L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::Profile>)

Optional. The selected Profile. If this is not set, then the default value
is to allow the broadest set of clients and servers ("PROFILE_COMPATIBLE").
Setting this to more restrictive values may improve security, but may also
prevent the TLS inspection proxy from connecting to some clients or
servers. Note that Secure Web Proxy does not yet honor this field.

=item * C<< $msg->custom_tls_features() >> / C<< $msg->custom_tls_features($value) >>

Type: C<String>

Optional. List of custom TLS cipher suites selected.
This field is valid only if the selected tls_feature_profile is CUSTOM.
The [compute.SslPoliciesService.ListAvailableFeatures][] method returns the
set of features that can be specified in this list.
Note that Secure Web Proxy does not yet honor this field.

=back

=head3 Enum: TlsInspectionPolicy::TlsVersion

=over 4

=item * C<TLS_VERSION_UNSPECIFIED> => C<0>

=item * C<TLS_1_0> => C<1>

=item * C<TLS_1_1> => C<2>

=item * C<TLS_1_2> => C<3>

=item * C<TLS_1_3> => C<4>

=back

=head3 Enum: TlsInspectionPolicy::Profile

=over 4

=item * C<PROFILE_UNSPECIFIED> => C<0>

=item * C<PROFILE_COMPATIBLE> => C<1>

=item * C<PROFILE_MODERN> => C<2>

=item * C<PROFILE_RESTRICTED> => C<3>

=item * C<PROFILE_CUSTOM> => C<4>

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::CreateTlsInspectionPolicyRequest

Request used by the CreateTlsInspectionPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the TlsInspectionPolicy. Must be in the
format `projects/{project}/locations/{location}`.

=item * C<< $msg->tls_inspection_policy_id() >> / C<< $msg->tls_inspection_policy_id($value) >>

Type: C<String>

Required. Short name of the TlsInspectionPolicy resource to be created.
This value should be 1-63 characters long, containing only
letters, numbers, hyphens, and underscores, and should not start
with a number. E.g. "tls_inspection_policy1".

=item * C<< $msg->tls_inspection_policy() >> / C<< $msg->tls_inspection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy>)

Required. TlsInspectionPolicy resource to be created.

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesRequest

Request used with the ListTlsInspectionPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the TlsInspectionPolicies
should be listed, specified in the format
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of TlsInspectionPolicies to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last
'ListTlsInspectionPoliciesResponse' Indicates that this is a
continuation of a prior 'ListTlsInspectionPolicies' call, and
that the system should return the next page of data.

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesResponse

Response returned by the ListTlsInspectionPolicies method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tls_inspection_policies() >> / C<< $msg->tls_inspection_policies($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy>)

List of TlsInspectionPolicies resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
'next_page_token' is included. To get the next set of results, call this
method again using the value of 'next_page_token' as 'page_token'.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::GetTlsInspectionPolicyRequest

Request used by the GetTlsInspectionPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TlsInspectionPolicy to get. Must be in the format
`projects/{project}/locations/{location}/tlsInspectionPolicies/{tls_inspection_policy}`.

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::DeleteTlsInspectionPolicyRequest

Request used by the DeleteTlsInspectionPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TlsInspectionPolicy to delete. Must be in the
format
`projects/{project}/locations/{location}/tlsInspectionPolicies/{tls_inspection_policy}`.

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

If set to true, any rules for this TlsInspectionPolicy will also be
deleted. (Otherwise, the request will only work if the TlsInspectionPolicy
has no rules.)

=back

=head2 Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::UpdateTlsInspectionPolicyRequest

Request used by the UpdateTlsInspectionPolicy method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
TlsInspectionPolicy resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->tls_inspection_policy() >> / C<< $msg->tls_inspection_policy($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy>)

Required. Updated TlsInspectionPolicy resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
