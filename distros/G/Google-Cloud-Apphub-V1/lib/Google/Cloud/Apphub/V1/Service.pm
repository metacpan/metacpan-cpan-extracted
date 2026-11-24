package Google::Cloud::Apphub::V1::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Apphub::V1::Attributes };
    eval { require Google::Cloud::Apphub::V1::Properties };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvYXBwaHViL3YxL3NlcnZpY2UucHJvdG8SFmdvb2dsZS5jbG91ZC5h
cHBodWIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkv
ZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Ns
b3VkL2FwcGh1Yi92MS9hdHRyaWJ1dGVzLnByb3RvGidnb29nbGUvY2xvdWQvYXBwaHViL3Yx
L3Byb3BlcnRpZXMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iowcK
B1NlcnZpY2USFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEo
CUID4EEBUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID4EEBUgtkZXNjcmlw
dGlvbhJaChFzZXJ2aWNlX3JlZmVyZW5jZRgEIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHBodWIu
djEuU2VydmljZVJlZmVyZW5jZUID4EEDUhBzZXJ2aWNlUmVmZXJlbmNlEl0KEnNlcnZpY2Vf
cHJvcGVydGllcxgFIAEoCzIpLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuU2VydmljZVByb3Bl
cnRpZXNCA+BBA1IRc2VydmljZVByb3BlcnRpZXMSRwoKYXR0cmlidXRlcxgGIAEoCzIiLmdv
b2dsZS5jbG91ZC5hcHBodWIudjEuQXR0cmlidXRlc0ID4EEBUgphdHRyaWJ1dGVzEmEKEmRp
c2NvdmVyZWRfc2VydmljZRgHIAEoCUIy4EEC4EEF+kEpEidhcHBodWIuZ29vZ2xlYXBpcy5j
b20vRGlzY292ZXJlZFNlcnZpY2VSEWRpc2NvdmVyZWRTZXJ2aWNlEkAKC2NyZWF0ZV90aW1l
GAggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAK
C3VwZGF0ZV90aW1lGAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1
cGRhdGVUaW1lEh0KA3VpZBgKIAEoCUIL4ozP1wgCCAHgQQNSA3VpZBJACgVzdGF0ZRgLIAEo
DjIlLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuU2VydmljZS5TdGF0ZUID4EEDUgVzdGF0ZSJU
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCgoGQUNUSVZF
EAISDAoIREVMRVRJTkcQAxIMCghERVRBQ0hFRBAEOo0B6kGJAQodYXBwaHViLmdvb2dsZWFw
aXMuY29tL1NlcnZpY2USVXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9hcHBsaWNhdGlvbnMve2FwcGxpY2F0aW9ufS9zZXJ2aWNlcy97c2VydmljZX0qCHNlcnZp
Y2VzMgdzZXJ2aWNlIikKEFNlcnZpY2VSZWZlcmVuY2USFQoDdXJpGAEgASgJQgPgQQNSA3Vy
aSLKBAoRU2VydmljZVByb3BlcnRpZXMSJAoLZ2NwX3Byb2plY3QYASABKAlCA+BBA1IKZ2Nw
UHJvamVjdBIfCghsb2NhdGlvbhgCIAEoCUID4EEDUghsb2NhdGlvbhIXCgR6b25lGAMgASgJ
QgPgQQNSBHpvbmUSVAoPZnVuY3Rpb25hbF90eXBlGAQgASgLMiYuZ29vZ2xlLmNsb3VkLmFw
cGh1Yi52MS5GdW5jdGlvbmFsVHlwZUID4EEDUg5mdW5jdGlvbmFsVHlwZRJaChFyZWdpc3Ry
YXRpb25fdHlwZRgFIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuUmVnaXN0cmF0aW9u
VHlwZUID4EEDUhByZWdpc3RyYXRpb25UeXBlEnEKEWV4dGVuZGVkX21ldGFkYXRhGAYgAygL
Mj8uZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5TZXJ2aWNlUHJvcGVydGllcy5FeHRlbmRlZE1l
dGFkYXRhRW50cnlCA+BBA1IQZXh0ZW5kZWRNZXRhZGF0YRJBCghpZGVudGl0eRgHIAEoCzIg
Lmdvb2dsZS5jbG91ZC5hcHBodWIudjEuSWRlbnRpdHlCA+BBA1IIaWRlbnRpdHkabQoVRXh0
ZW5kZWRNZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5Ej4KBXZhbHVlGAIgASgLMigu
Z29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5FeHRlbmRlZE1ldGFkYXRhUgV2YWx1ZToCOAEijwMK
EURpc2NvdmVyZWRTZXJ2aWNlEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJaChFzZXJ2aWNl
X3JlZmVyZW5jZRgCIAEoCzIoLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuU2VydmljZVJlZmVy
ZW5jZUID4EEDUhBzZXJ2aWNlUmVmZXJlbmNlEl0KEnNlcnZpY2VfcHJvcGVydGllcxgDIAEo
CzIpLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuU2VydmljZVByb3BlcnRpZXNCA+BBA1IRc2Vy
dmljZVByb3BlcnRpZXM6pQHqQaEBCidhcHBodWIuZ29vZ2xlYXBpcy5jb20vRGlzY292ZXJl
ZFNlcnZpY2UST3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kaXNj
b3ZlcmVkU2VydmljZXMve2Rpc2NvdmVyZWRfc2VydmljZX0qEmRpc2NvdmVyZWRTZXJ2aWNl
czIRZGlzY292ZXJlZFNlcnZpY2VCrgEKGmNvbS5nb29nbGUuY2xvdWQuYXBwaHViLnYxQgxT
ZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBodWIvYXBpdjEvYXBwaHVi
cGI7YXBwaHVicGKqAhZHb29nbGUuQ2xvdWQuQXBwSHViLlYxygIWR29vZ2xlXENsb3VkXEFw
cEh1YlxWMeoCGUdvb2dsZTo6Q2xvdWQ6OkFwcEh1Yjo6VjFKoy8KBxIFDgCzAQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgID
ARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUAMQoJCgIDBBIDFgAxCgkKAgMFEgMXACkKCAoB
CBIDGQAzCgkKAgglEgMZADMKCAoBCBIDGgBJCgkKAggLEgMaAEkKCAoBCBIDGwAiCgkKAggK
EgMbACIKCAoBCBIDHAAtCgkKAggIEgMcAC0KCAoBCBIDHQAzCgkKAggBEgMdADMKCAoBCBID
HgAzCgkKAggpEgMeADMKCAoBCBIDHwAyCgkKAggtEgMfADIKzgEKAgQAEgQkAHEBGsEBIFNl
cnZpY2UgaXMgYW4gQXBwIEh1YiBkYXRhIG1vZGVsIHRoYXQgY29udGFpbnMgYSBkaXNjb3Zl
cmVkIHNlcnZpY2UsIHdoaWNoCiByZXByZXNlbnRzIGEgbmV0d29yayBvciBBUEkgaW50ZXJm
YWNlIHRoYXQgZXhwb3NlcyBzb21lIGZ1bmN0aW9uYWxpdHkgdG8KIGNsaWVudHMgZm9yIGNv
bnN1bXB0aW9uIG92ZXIgdGhlIG5ldHdvcmsuCgoKCgMEAAESAyQIDwoLCgMEAAcSBCUCKgQK
DQoFBAAHnQgSBCUCKgQKHgoEBAAEABIELQI8AxoQIFNlcnZpY2Ugc3RhdGUuCgoMCgUEAAQA
ARIDLQcMCiMKBgQABAACABIDLwQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgAB
EgMvBBUKDgoHBAAEAAIAAhIDLxgZCi4KBgQABAACARIDMgQRGh8gVGhlIHNlcnZpY2UgaXMg
YmVpbmcgY3JlYXRlZC4KCg4KBwQABAACAQESAzIEDAoOCgcEAAQAAgECEgMyDxAKJgoGBAAE
AAICEgM1BA8aFyBUaGUgc2VydmljZSBpcyByZWFkeS4KCg4KBwQABAACAgESAzUECgoOCgcE
AAQAAgICEgM1DQ4KLgoGBAAEAAIDEgM4BBEaHyBUaGUgc2VydmljZSBpcyBiZWluZyBkZWxl
dGVkLgoKDgoHBAAEAAIDARIDOAQMCg4KBwQABAACAwISAzgPEApHCgYEAAQAAgQSAzsEERo4
IFRoZSB1bmRlcmx5aW5nIG5ldHdvcmtpbmcgcmVzb3VyY2VzIGhhdmUgYmVlbiBkZWxldGVk
LgoKDgoHBAAEAAIEARIDOwQMCg4KBwQABAACBAISAzsPEAqsAQoEBAACABIDQAI9Gp4BIElk
ZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIGEgU2VydmljZS4gRm9ybWF0OgogYCJw
cm9qZWN0cy97aG9zdC1wcm9qZWN0LWlkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBsaWNh
dGlvbnMve2FwcGxpY2F0aW9uLWlkfS9zZXJ2aWNlcy97c2VydmljZS1pZH0iYAoKDAoFBAAC
AAUSA0ACCAoMCgUEAAIAARIDQAkNCgwKBQQAAgADEgNAEBEKDAoFBAACAAgSA0ASPAoPCggE
AAIACJwIABIDQBM7CmgKBAQAAgESA0QCQxpbIE9wdGlvbmFsLiBVc2VyLWRlZmluZWQgbmFt
ZSBmb3IgdGhlIFNlcnZpY2UuCiBDYW4gaGF2ZSBhIG1heGltdW0gbGVuZ3RoIG9mIDYzIGNo
YXJhY3RlcnMuCgoMCgUEAAIBBRIDRAIICgwKBQQAAgEBEgNECRUKDAoFBAACAQMSA0QYGQoM
CgUEAAIBCBIDRBpCCg8KCAQAAgEInAgAEgNEG0EKbgoEBAACAhIDSAJCGmEgT3B0aW9uYWwu
IFVzZXItZGVmaW5lZCBkZXNjcmlwdGlvbiBvZiBhIFNlcnZpY2UuCiBDYW4gaGF2ZSBhIG1h
eGltdW0gbGVuZ3RoIG9mIDIwNDggY2hhcmFjdGVycy4KCgwKBQQAAgIFEgNIAggKDAoFBAAC
AgESA0gJFAoMCgUEAAICAxIDSBcYCgwKBQQAAgIIEgNIGUEKDwoIBAACAgicCAASA0gaQAp+
CgQEAAIDEgRMAk0yGnAgT3V0cHV0IG9ubHkuIFJlZmVyZW5jZSB0byBhbiB1bmRlcmx5aW5n
IG5ldHdvcmtpbmcgcmVzb3VyY2UgdGhhdCBjYW4KIGNvbXByaXNlIGEgU2VydmljZS4gVGhl
c2UgYXJlIGltbXV0YWJsZS4KCgwKBQQAAgMGEgNMAhIKDAoFBAACAwESA0wTJAoMCgUEAAID
AxIDTCcoCgwKBQQAAgMIEgNNBjEKDwoIBAACAwicCAASA00HMAp8CgQEAAIEEgRRAlIyGm4g
T3V0cHV0IG9ubHkuIFByb3BlcnRpZXMgb2YgYW4gdW5kZXJseWluZyBjb21wdXRlIHJlc291
cmNlIHRoYXQgY2FuIGNvbXByaXNlCiBhIFNlcnZpY2UuIFRoZXNlIGFyZSBpbW11dGFibGUu
CgoMCgUEAAIEBhIDUQITCgwKBQQAAgQBEgNRFCYKDAoFBAACBAMSA1EpKgoMCgUEAAIECBID
UgYxCg8KCAQAAgQInAgAEgNSBzAKNgoEBAACBRIDVQJFGikgT3B0aW9uYWwuIENvbnN1bWVy
IHByb3ZpZGVkIGF0dHJpYnV0ZXMuCgoMCgUEAAIFBhIDVQIMCgwKBQQAAgUBEgNVDRcKDAoF
BAACBQMSA1UaGwoMCgUEAAIFCBIDVRxECg8KCAQAAgUInAgAEgNVHUMKWgoEBAACBhIEWAJe
BBpMIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBvcmln
aW5hbCBkaXNjb3ZlcmVkIHNlcnZpY2UuCgoMCgUEAAIGBRIDWAIICgwKBQQAAgYBEgNYCRsK
DAoFBAACBgMSA1geHwoNCgUEAAIGCBIEWCBeAwoPCggEAAIGCJwIABIDWQQqCg8KCAQAAgYI
nAgBEgNaBCsKDwoHBAACBgifCBIEWwRdBQopCgQEAAIHEgRhAmIyGhsgT3V0cHV0IG9ubHku
IENyZWF0ZSB0aW1lLgoKDAoFBAACBwYSA2ECGwoMCgUEAAIHARIDYRwnCgwKBQQAAgcDEgNh
KisKDAoFBAACBwgSA2IGMQoPCggEAAIHCJwIABIDYgcwCikKBAQAAggSBGUCZjIaGyBPdXRw
dXQgb25seS4gVXBkYXRlIHRpbWUuCgoMCgUEAAIIBhIDZQIbCgwKBQQAAggBEgNlHCcKDAoF
BAACCAMSA2UqKwoMCgUEAAIICBIDZgYxCg8KCAQAAggInAgAEgNmBzAKawoEBAACCRIEagJt
BBpdIE91dHB1dCBvbmx5LiBBIHVuaXZlcnNhbGx5IHVuaXF1ZSBpZGVudGlmaWVyIChVVUlE
KSBmb3IgdGhlIGBTZXJ2aWNlYCBpbgogdGhlIFVVSUQ0IGZvcm1hdC4KCgwKBQQAAgkFEgNq
AggKDAoFBAACCQESA2oJDAoMCgUEAAIJAxIDag8RCg0KBQQAAgkIEgRqEm0DChIKCwQAAgkI
zPH5igEBEgNrBCoKDwoIBAACCQicCAASA2wELQoqCgQEAAIKEgNwAj8aHSBPdXRwdXQgb25s
eS4gU2VydmljZSBzdGF0ZS4KCgwKBQQAAgoGEgNwAgcKDAoFBAACCgESA3AIDQoMCgUEAAIK
AxIDcBASCgwKBQQAAgoIEgNwEz4KDwoIBAACCgicCAASA3AUPQpZCgIEARIEdAB4ARpNIFJl
ZmVyZW5jZSB0byBhbiB1bmRlcmx5aW5nIG5ldHdvcmtpbmcgcmVzb3VyY2UgdGhhdCBjYW4g
Y29tcHJpc2UgYSBTZXJ2aWNlLgoKCgoDBAEBEgN0CBgKfAoEBAECABIDdwI9Gm8gT3V0cHV0
IG9ubHkuIFRoZSB1bmRlcmx5aW5nIHJlc291cmNlIFVSSS4gRm9yIGV4YW1wbGUsIFVSSSBv
ZiBGb3J3YXJkaW5nCiBSdWxlLCBVUkwgTWFwLCBhbmQgQmFja2VuZCBTZXJ2aWNlLgoKDAoF
BAECAAUSA3cCCAoMCgUEAQIAARIDdwkMCgwKBQQBAgADEgN3DxAKDAoFBAECAAgSA3cRPAoP
CggEAQIACJwIABIDdxI7ClYKAgQCEgV7AJkBARpJIFByb3BlcnRpZXMgb2YgYW4gdW5kZXJs
eWluZyBjbG91ZCByZXNvdXJjZSB0aGF0IGNhbiBjb21wcmlzZSBhIFNlcnZpY2UuCgoKCgME
AgESA3sIGQpqCgQEAgIAEgN+AkUaXSBPdXRwdXQgb25seS4gVGhlIHNlcnZpY2UgcHJvamVj
dCBpZGVudGlmaWVyIHRoYXQgdGhlIHVuZGVybHlpbmcgY2xvdWQKIHJlc291cmNlIHJlc2lk
ZXMgaW4uCgoMCgUEAgIABRIDfgIICgwKBQQCAgABEgN+CRQKDAoFBAICAAMSA34XGAoMCgUE
AgIACBIDfhlECg8KCAQCAgAInAgAEgN+GkMKagoEBAICARIEggECQhpcIE91dHB1dCBvbmx5
LiBUaGUgbG9jYXRpb24gdGhhdCB0aGUgdW5kZXJseWluZyByZXNvdXJjZSByZXNpZGVzIGlu
LCBmb3IKIGV4YW1wbGUsIHVzLXdlc3QxLgoKDQoFBAICAQUSBIIBAggKDQoFBAICAQESBIIB
CREKDQoFBAICAQMSBIIBFBUKDQoFBAICAQgSBIIBFkEKEAoIBAICAQicCAASBIIBF0AKfAoE
BAICAhIEhgECPhpuIE91dHB1dCBvbmx5LiBUaGUgbG9jYXRpb24gdGhhdCB0aGUgdW5kZXJs
eWluZyByZXNvdXJjZSByZXNpZGVzIGluIGlmIGl0IGlzCiB6b25hbCwgZm9yIGV4YW1wbGUs
IHVzLXdlc3QxLWEpLgoKDQoFBAICAgUSBIYBAggKDQoFBAICAgESBIYBCQ0KDQoFBAICAgMS
BIYBEBEKDQoFBAICAggSBIYBEj0KEAoIBAICAgicCAASBIYBEzwKNwoEBAICAxIGiQECigEy
GicgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSBzZXJ2aWNlLgoKDQoFBAICAwYSBIkB
AhAKDQoFBAICAwESBIkBESAKDQoFBAICAwMSBIkBIyQKDQoFBAICAwgSBIoBBjEKEAoIBAIC
AwicCAASBIoBBzAKRAoEBAICBBIGjQECjgEyGjQgT3V0cHV0IG9ubHkuIFRoZSByZWdpc3Ry
YXRpb24gdHlwZSBvZiB0aGUgc2VydmljZS4KCg0KBQQCAgQGEgSNAQISCg0KBQQCAgQBEgSN
ARMkCg0KBQQCAgQDEgSNAScoCg0KBQQCAgQIEgSOAQYxChAKCAQCAgQInAgAEgSOAQcwCv8B
CgQEAgIFEgaUAQKVATIa7gEgT3V0cHV0IG9ubHkuIEFkZGl0aW9uYWwgbWV0YWRhdGEgc3Bl
Y2lmaWMgdG8gdGhlIHJlc291cmNlIHR5cGUuCiBUaGUga2V5IGlzIGEgc3RyaW5nIHRoYXQg
aWRlbnRpZmllcyB0aGUgdHlwZSBvZiBtZXRhZGF0YSBhbmQgdGhlIHZhbHVlIGlzCiB0aGUg
bWV0YWRhdGEgY29udGVudHMgc3BlY2lmaWMgdG8gdGhhdCB0eXBlLgogS2V5IGZvcm1hdDog
YGFwcGh1Yi5nb29nbGVhcGlzLmNvbS97bWV0YWRhdGFUeXBlfWAKCg0KBQQCAgUGEgSUAQIf
Cg0KBQQCAgUBEgSUASAxCg0KBQQCAgUDEgSUATQ1Cg0KBQQCAgUIEgSVAQYxChAKCAQCAgUI
nAgAEgSVAQcwCkYKBAQCAgYSBJgBAkQaOCBPdXRwdXQgb25seS4gVGhlIGlkZW50aXR5IGFz
c29jaWF0ZWQgd2l0aCB0aGUgc2VydmljZS4KCg0KBQQCAgYGEgSYAQIKCg0KBQQCAgYBEgSY
AQsTCg0KBQQCAgYDEgSYARYXCg0KBQQCAgYIEgSYARhDChAKCAQCAgYInAgAEgSYARlCCswB
CgIEAxIGngEAswEBGr0BIERpc2NvdmVyZWRTZXJ2aWNlIGlzIGEgbmV0d29yayBvciBBUEkg
aW50ZXJmYWNlIHRoYXQgZXhwb3NlcyBzb21lCiBmdW5jdGlvbmFsaXR5IHRvIGNsaWVudHMg
Zm9yIGNvbnN1bXB0aW9uIG92ZXIgdGhlIG5ldHdvcmsuIEEgZGlzY292ZXJlZAogc2Vydmlj
ZSBjYW4gYmUgcmVnaXN0ZXJlZCB0byBhIEFwcCBIdWIgc2VydmljZS4KCgsKAwQDARIEngEI
GQoNCgMEAwcSBp8BAqQBBAoPCgUEAwedCBIGnwECpAEECqABCgQEAwIAEgSoAQI9GpEBIElk
ZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkaXNjb3ZlcmVkIHNlcnZpY2Uu
IEZvcm1hdDoKIGAicHJvamVjdHMve2hvc3QtcHJvamVjdC1pZH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vZGlzY292ZXJlZFNlcnZpY2VzL3t1dWlkfSJgCgoNCgUEAwIABRIEqAECCAoNCgUE
AwIAARIEqAEJDQoNCgUEAwIAAxIEqAEQEQoNCgUEAwIACBIEqAESPAoQCggEAwIACJwIABIE
qAETOwqAAQoEBAMCARIGrAECrQEyGnAgT3V0cHV0IG9ubHkuIFJlZmVyZW5jZSB0byBhbiB1
bmRlcmx5aW5nIG5ldHdvcmtpbmcgcmVzb3VyY2UgdGhhdCBjYW4KIGNvbXByaXNlIGEgU2Vy
dmljZS4gVGhlc2UgYXJlIGltbXV0YWJsZS4KCg0KBQQDAgEGEgSsAQISCg0KBQQDAgEBEgSs
ARMkCg0KBQQDAgEDEgSsAScoCg0KBQQDAgEIEgStAQYxChAKCAQDAgEInAgAEgStAQcwCn4K
BAQDAgISBrEBArIBMhpuIE91dHB1dCBvbmx5LiBQcm9wZXJ0aWVzIG9mIGFuIHVuZGVybHlp
bmcgY29tcHV0ZSByZXNvdXJjZSB0aGF0IGNhbiBjb21wcmlzZQogYSBTZXJ2aWNlLiBUaGVz
ZSBhcmUgaW1tdXRhYmxlLgoKDQoFBAMCAgYSBLEBAhMKDQoFBAMCAgESBLEBFCYKDQoFBAMC
AgMSBLEBKSoKDQoFBAMCAggSBLIBBjEKEAoIBAMCAgicCAASBLIBBzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apphub::V1::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: service_reference Type: 11 (.google.cloud.apphub.v1.ServiceReference)
    # Field: service_properties Type: 11 (.google.cloud.apphub.v1.ServiceProperties)
    # Field: attributes Type: 11 (.google.cloud.apphub.v1.Attributes)
    # Field: discovered_service Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()
    # Field: state Type: 14 (.google.cloud.apphub.v1.Service.State)

# Enum: Service::State
our $Service_STATE_UNSPECIFIED = 0;
our $Service_CREATING = 1;
our $Service_ACTIVE = 2;
our $Service_DELETING = 3;
our $Service_DETACHED = 4;

# === Message: Google::Cloud::Apphub::V1::Service::ServiceReference ===
    # Fields for ServiceReference
    # Field: uri Type: 9 ()

# === Message: Google::Cloud::Apphub::V1::Service::ServiceProperties ===
    # Fields for ServiceProperties
    # Field: gcp_project Type: 9 ()
    # Field: location Type: 9 ()
    # Field: zone Type: 9 ()
    # Field: functional_type Type: 11 (.google.cloud.apphub.v1.FunctionalType)
    # Field: registration_type Type: 11 (.google.cloud.apphub.v1.RegistrationType)
    # Field: extended_metadata Type: 11 (.google.cloud.apphub.v1.ServiceProperties.ExtendedMetadataEntry)
    # Field: identity Type: 11 (.google.cloud.apphub.v1.Identity)

# === Message: Google::Cloud::Apphub::V1::Service::DiscoveredService ===
    # Fields for DiscoveredService
    # Field: name Type: 9 ()
    # Field: service_reference Type: 11 (.google.cloud.apphub.v1.ServiceReference)
    # Field: service_properties Type: 11 (.google.cloud.apphub.v1.ServiceProperties)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apphub::V1::Service - Compiled Protocol Buffers messages for google/cloud/apphub/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Apphub::V1::Service;

    my $msg = Google::Cloud::Apphub::V1::Service::Service->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        service_reference => $service_reference,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apphub::V1::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apphub/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apphub::V1::Service::Service

Service is an App Hub data model that contains a discovered service, which
represents a network or API interface that exposes some functionality to
clients for consumption over the network.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of a Service. Format:
`"projects/{host-project-id}/locations/{location}/applications/{application-id}/services/{service-id}"`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined name for the Service.
Can have a maximum length of 63 characters.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of a Service.
Can have a maximum length of 2048 characters.

=item * C<< $msg->service_reference() >> / C<< $msg->service_reference($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Service::ServiceReference>)

Output only. Reference to an underlying networking resource that can
comprise a Service. These are immutable.

=item * C<< $msg->service_properties() >> / C<< $msg->service_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Service::ServiceProperties>)

Output only. Properties of an underlying compute resource that can comprise
a Service. These are immutable.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Attributes>)

Optional. Consumer provided attributes.

=item * C<< $msg->discovered_service() >> / C<< $msg->discovered_service($value) >>

Type: C<String>

Required. Immutable. The resource name of the original discovered service.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A universally unique identifier (UUID) for the `Service` in
the UUID4 format.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Apphub::V1::Service::State>)

Output only. Service state.

=back

=head3 Enum: Service::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=item * C<DETACHED> => C<4>

=back

=head2 Google::Cloud::Apphub::V1::Service::ServiceReference

Reference to an underlying networking resource that can comprise a Service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Output only. The underlying resource URI. For example, URI of Forwarding
Rule, URL Map, and Backend Service.

=back

=head2 Google::Cloud::Apphub::V1::Service::ServiceProperties

Properties of an underlying cloud resource that can comprise a Service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcp_project() >> / C<< $msg->gcp_project($value) >>

Type: C<String>

Output only. The service project identifier that the underlying cloud
resource resides in.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Output only. The location that the underlying resource resides in, for
example, us-west1.

=item * C<< $msg->zone() >> / C<< $msg->zone($value) >>

Type: C<String>

Output only. The location that the underlying resource resides in if it is
zonal, for example, us-west1-a).

=item * C<< $msg->functional_type() >> / C<< $msg->functional_type($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Properties::FunctionalType>)

Output only. The type of the service.

=item * C<< $msg->registration_type() >> / C<< $msg->registration_type($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Properties::RegistrationType>)

Output only. The registration type of the service.

=item * C<< $msg->extended_metadata() >> / C<< $msg->extended_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Service::ServiceProperties::ExtendedMetadataEntry>)

Output only. Additional metadata specific to the resource type.
The key is a string that identifies the type of metadata and the value is
the metadata contents specific to that type.
Key format: `apphub.googleapis.com/{metadataType}`

=item * C<< $msg->identity() >> / C<< $msg->identity($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Properties::Identity>)

Output only. The identity associated with the service.

=back

=head2 Google::Cloud::Apphub::V1::Service::DiscoveredService

DiscoveredService is a network or API interface that exposes some
functionality to clients for consumption over the network. A discovered
service can be registered to a App Hub service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the discovered service. Format:
`"projects/{host-project-id}/locations/{location}/discoveredServices/{uuid}"`

=item * C<< $msg->service_reference() >> / C<< $msg->service_reference($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Service::ServiceReference>)

Output only. Reference to an underlying networking resource that can
comprise a Service. These are immutable.

=item * C<< $msg->service_properties() >> / C<< $msg->service_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Service::ServiceProperties>)

Output only. Properties of an underlying compute resource that can comprise
a Service. These are immutable.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apphub::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
