package Google::Cloud::Documentai::V1beta3::Dataset;

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
    eval { require Google::Cloud::Documentai::V1beta3::Document };
    eval { require Google::Cloud::Documentai::V1beta3::DocumentIo };
    eval { require Google::Cloud::Documentai::V1beta3::DocumentSchema };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL2RhdGFzZXQucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9jbG91ZC9kb2N1bWVu
dGFpL3YxYmV0YTMvZG9jdW1lbnQucHJvdG8aMWdvb2dsZS9jbG91ZC9kb2N1bWVudGFpL3Yx
YmV0YTMvZG9jdW1lbnRfaW8ucHJvdG8aNWdvb2dsZS9jbG91ZC9kb2N1bWVudGFpL3YxYmV0
YTMvZG9jdW1lbnRfc2NoZW1hLnByb3RvIpYICgdEYXRhc2V0Em4KEmdjc19tYW5hZ2VkX2Nv
bmZpZxgDIAEoCzI5Lmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuRGF0YXNldC5H
Q1NNYW5hZ2VkQ29uZmlnQgPgQQFIAFIQZ2NzTWFuYWdlZENvbmZpZxKFAQoZZG9jdW1lbnRf
d2FyZWhvdXNlX2NvbmZpZxgFIAEoCzJALmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0
YTMuRGF0YXNldC5Eb2N1bWVudFdhcmVob3VzZUNvbmZpZ0IFGAHgQQFIAFIXZG9jdW1lbnRX
YXJlaG91c2VDb25maWcSgAEKGHVubWFuYWdlZF9kYXRhc2V0X2NvbmZpZxgGIAEoCzI/Lmdv
b2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuRGF0YXNldC5Vbm1hbmFnZWREYXRhc2V0
Q29uZmlnQgPgQQFIAFIWdW5tYW5hZ2VkRGF0YXNldENvbmZpZxISCgRuYW1lGAEgASgJUgRu
YW1lEkkKBXN0YXRlGAIgASgOMi4uZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5E
YXRhc2V0LlN0YXRlQgPgQQJSBXN0YXRlEigKDXNhdGlzZmllc19wenMYCCABKAhCA+BBA1IM
c2F0aXNmaWVzUHpzEigKDXNhdGlzZmllc19wemkYCSABKAhCA+BBA1IMc2F0aXNmaWVzUHpp
GmIKEEdDU01hbmFnZWRDb25maWcSTgoKZ2NzX3ByZWZpeBgBIAEoCzIqLmdvb2dsZS5jbG91
ZC5kb2N1bWVudGFpLnYxYmV0YTMuR2NzUHJlZml4QgPgQQJSCWdjc1ByZWZpeBqGAQoXRG9j
dW1lbnRXYXJlaG91c2VDb25maWcSIwoKY29sbGVjdGlvbhgBIAEoCUID4EEDUgpjb2xsZWN0
aW9uEkYKBnNjaGVtYRgCIAEoCUIu4EED+kEoCiZjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFw
aXMuY29tL1NjaGVtYVIGc2NoZW1hGhgKFlVubWFuYWdlZERhdGFzZXRDb25maWciVAoFU3Rh
dGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIRCg1VTklOSVRJQUxJWkVEEAESEAoMSU5JVElB
TElaSU5HEAISDwoLSU5JVElBTElaRUQQAzpu6kFrCiFkb2N1bWVudGFpLmdvb2dsZWFwaXMu
Y29tL0RhdGFzZXQSRnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9w
cm9jZXNzb3JzL3twcm9jZXNzb3J9L2RhdGFzZXRCEAoOc3RvcmFnZV9zb3VyY2UizAMKCkRv
Y3VtZW50SWQSbwoSZ2NzX21hbmFnZWRfZG9jX2lkGAEgASgLMkAuZ29vZ2xlLmNsb3VkLmRv
Y3VtZW50YWkudjFiZXRhMy5Eb2N1bWVudElkLkdDU01hbmFnZWREb2N1bWVudElkSABSD2dj
c01hbmFnZWREb2NJZBJrChB1bm1hbmFnZWRfZG9jX2lkGAQgASgLMj8uZ29vZ2xlLmNsb3Vk
LmRvY3VtZW50YWkudjFiZXRhMy5Eb2N1bWVudElkLlVubWFuYWdlZERvY3VtZW50SWRIAFIO
dW5tYW5hZ2VkRG9jSWQSTwoMcmV2aXNpb25fcmVmGAMgASgLMiwuZ29vZ2xlLmNsb3VkLmRv
Y3VtZW50YWkudjFiZXRhMy5SZXZpc2lvblJlZlILcmV2aXNpb25SZWYaVAoUR0NTTWFuYWdl
ZERvY3VtZW50SWQSHAoHZ2NzX3VyaRgBIAEoCUID4EECUgZnY3NVcmkSHgoJY3dfZG9jX2lk
GAIgASgJQgIYAVIHY3dEb2NJZBoxChNVbm1hbmFnZWREb2N1bWVudElkEhoKBmRvY19pZBgB
IAEoCUID4EECUgVkb2NJZEIGCgR0eXBlItsCCg1EYXRhc2V0U2NoZW1hEhIKBG5hbWUYASAB
KAlSBG5hbWUSXQoPZG9jdW1lbnRfc2NoZW1hGAMgASgLMi8uZ29vZ2xlLmNsb3VkLmRvY3Vt
ZW50YWkudjFiZXRhMy5Eb2N1bWVudFNjaGVtYUID4EEBUg5kb2N1bWVudFNjaGVtYRIoCg1z
YXRpc2ZpZXNfcHpzGAQgASgIQgPgQQNSDHNhdGlzZmllc1B6cxIoCg1zYXRpc2ZpZXNfcHpp
GAUgASgIQgPgQQNSDHNhdGlzZmllc1B6aTqCAepBfwonZG9jdW1lbnRhaS5nb29nbGVhcGlz
LmNvbS9EYXRhc2V0U2NoZW1hElRwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vcHJvY2Vzc29ycy97cHJvY2Vzc29yfS9kYXRhc2V0L2RhdGFzZXRTY2hlbWEitAIK
FUJhdGNoRGF0YXNldERvY3VtZW50cxKGAQoXaW5kaXZpZHVhbF9kb2N1bWVudF9pZHMYASAB
KAsyTC5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJldGEzLkJhdGNoRGF0YXNldERvY3Vt
ZW50cy5JbmRpdmlkdWFsRG9jdW1lbnRJZHNIAFIVaW5kaXZpZHVhbERvY3VtZW50SWRzEhgK
BmZpbHRlchgCIAEoCUgAUgZmaWx0ZXIabAoVSW5kaXZpZHVhbERvY3VtZW50SWRzElMKDGRv
Y3VtZW50X2lkcxgBIAMoCzIrLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMuRG9j
dW1lbnRJZEID4EECUgtkb2N1bWVudElkc0IKCghjcml0ZXJpYULIAgojY29tLmdvb2dsZS5j
bG91ZC5kb2N1bWVudGFpLnYxYmV0YTNCDERhdGFzZXRQcm90b1ABWkNjbG91ZC5nb29nbGUu
Y29tL2dvL2RvY3VtZW50YWkvYXBpdjFiZXRhMy9kb2N1bWVudGFpcGI7ZG9jdW1lbnRhaXBi
qgIfR29vZ2xlLkNsb3VkLkRvY3VtZW50QUkuVjFCZXRhM8oCH0dvb2dsZVxDbG91ZFxEb2N1
bWVudEFJXFYxYmV0YTPqAiJHb29nbGU6OkNsb3VkOjpEb2N1bWVudEFJOjpWMWJldGEz6kFi
CiZjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL1NjaGVtYRI4cHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NjaGVtYXMve3NjaGVtYX1Kri8KBxIFDgDA
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoCAwAS
AxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADgKCQoCAwMSAxUAOwoJCgIDBBIDFgA/CggKAQgS
AxgAPAoJCgIIJRIDGAA8CggKAQgSAxkAWgoJCgIICxIDGQBaCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsALQoJCgIICBIDGwAtCggKAQgSAxwAPAoJCgIIARIDHAA8CggKAQgSAx0A
PAoJCgIIKRIDHQA8CggKAQgSAx4AOwoJCgIILRIDHgA7CgkKAQgSBB8AIgIKDAoECJ0IABIE
HwAiAgqQAQoCBAASBCcAdgEagwEgQSBzaW5nbGV0b24gcmVzb3VyY2UgdW5kZXIgYQogW1By
b2Nlc3Nvcl1bZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkudjFiZXRhMy5Qcm9jZXNzb3JdIHdo
aWNoIGNvbmZpZ3VyZXMgYQogY29sbGVjdGlvbiBvZiBkb2N1bWVudHMuCgoKCgMEAAESAycI
DwoLCgMEAAcSBCgCKwQKDQoFBAAHnQgSBCgCKwQKUQoEBAADABIELgIyAxpDIENvbmZpZ3Vy
YXRpb24gc3BlY2lmaWMgdG8gdGhlIENsb3VkIFN0b3JhZ2UtYmFzZWQgaW1wbGVtZW50YXRp
b24uCgoMCgUEAAMAARIDLgoaCnwKBgQAAwACABIDMQRGGm0gUmVxdWlyZWQuIFRoZSBDbG91
ZCBTdG9yYWdlIFVSSSAoYSBkaXJlY3RvcnkpIHdoZXJlIHRoZSBkb2N1bWVudHMKIGJlbG9u
Z2luZyB0byB0aGUgZGF0YXNldCBtdXN0IGJlIHN0b3JlZC4KCg4KBwQAAwACAAYSAzEEDQoO
CgcEAAMAAgABEgMxDhgKDgoHBAADAAIAAxIDMRscCg4KBwQAAwACAAgSAzEdRQoRCgoEAAMA
AgAInAgAEgMxHkQKWQoEBAADARIENQJCAxpLIENvbmZpZ3VyYXRpb24gc3BlY2lmaWMgdG8g
dGhlIERvY3VtZW50IEFJIFdhcmVob3VzZS1iYXNlZCBpbXBsZW1lbnRhdGlvbi4KCgwKBQQA
AwEBEgM1CiEKYwoGBAADAQIAEgM4BEYaVCBPdXRwdXQgb25seS4gVGhlIGNvbGxlY3Rpb24g
aW4gRG9jdW1lbnQgQUkgV2FyZWhvdXNlIGFzc29jaWF0ZWQgd2l0aCB0aGUKIGRhdGFzZXQu
CgoOCgcEAAMBAgAFEgM4BAoKDgoHBAADAQIAARIDOAsVCg4KBwQAAwECAAMSAzgYGQoOCgcE
AAMBAgAIEgM4GkUKEQoKBAADAQIACJwIABIDOBtECmAKBgQAAwECARIEPARBBhpQIE91dHB1
dCBvbmx5LiBUaGUgc2NoZW1hIGluIERvY3VtZW50IEFJIFdhcmVob3VzZSBhc3NvY2lhdGVk
IHdpdGggdGhlCiBkYXRhc2V0LgoKDgoHBAADAQIBBRIDPAQKCg4KBwQAAwECAQESAzwLEQoO
CgcEAAMBAgEDEgM8FBUKDwoHBAADAQIBCBIEPBZBBQoRCgoEAAMBAgEInAgAEgM9Bi8KEQoJ
BAADAQIBCJ8IEgQ+BkAHCj4KBAQAAwISA0UCIxoxIENvbmZpZ3VyYXRpb24gc3BlY2lmaWMg
dG8gYW4gdW5tYW5hZ2VkIGRhdGFzZXQuCgoMCgUEAAMCARIDRQogCi4KBAQABAASBEgCVAMa
ICBEaWZmZXJlbnQgc3RhdGVzIG9mIGEgZGF0YXNldC4KCgwKBQQABAABEgNIBwwKPgoGBAAE
AAIAEgNKBBoaLyBEZWZhdWx0IHVuc3BlY2lmaWVkIGVudW0sIHNob3VsZCBub3QgYmUgdXNl
ZC4KCg4KBwQABAACAAESA0oEFQoOCgcEAAQAAgACEgNKGBkKMgoGBAAEAAIBEgNNBBYaIyBE
YXRhc2V0IGhhcyBub3QgYmVlbiBpbml0aWFsaXplZC4KCg4KBwQABAACAQESA00EEQoOCgcE
AAQAAgECEgNNFBUKLgoGBAAEAAICEgNQBBUaHyBEYXRhc2V0IGlzIGJlaW5nIGluaXRpYWxp
emVkLgoKDgoHBAAEAAICARIDUAQQCg4KBwQABAACAgISA1ATFAouCgYEAAQAAgMSA1MEFBof
IERhdGFzZXQgaGFzIGJlZW4gaW5pdGlhbGl6ZWQuCgoOCgcEAAQAAgMBEgNTBA8KDgoHBAAE
AAIDAhIDUxITCgwKBAQACAASBFYCZwMKDAoFBAAIAAESA1YIFgq2AQoEBAACABIEWgRbMRqn
ASBPcHRpb25hbC4gVXNlci1tYW5hZ2VkIENsb3VkIFN0b3JhZ2UgZGF0YXNldCBjb25maWd1
cmF0aW9uLiBVc2UgdGhpcwogY29uZmlndXJhdGlvbiBpZiB0aGUgZGF0YXNldCBkb2N1bWVu
dHMgYXJlIHN0b3JlZCB1bmRlciBhIHVzZXItbWFuYWdlZAogQ2xvdWQgU3RvcmFnZSBsb2Nh
dGlvbi4KCgwKBQQAAgAGEgNaBBQKDAoFBAACAAESA1oVJwoMCgUEAAIAAxIDWiorCgwKBQQA
AgAIEgNbCDAKDwoIBAACAAicCAASA1sJLwpeCgQEAAIBEgRfBGBEGlAgT3B0aW9uYWwuIERl
cHJlY2F0ZWQuIFdhcmVob3VzZS1iYXNlZCBkYXRhc2V0IGNvbmZpZ3VyYXRpb24gaXMgbm90
CiBzdXBwb3J0ZWQuCgoMCgUEAAIBBhIDXwQbCgwKBQQAAgEBEgNfHDUKDAoFBAACAQMSA184
OQoMCgUEAAIBCBIDYAhDCg0KBgQAAgEIAxIDYAkaCg8KCAQAAgEInAgAEgNgHEIKsAEKBAQA
AgISBGUEZjEaoQEgT3B0aW9uYWwuIFVubWFuYWdlZCBkYXRhc2V0IGNvbmZpZ3VyYXRpb24u
IFVzZSB0aGlzIGNvbmZpZ3VyYXRpb24gaWYgdGhlCiBkYXRhc2V0IGRvY3VtZW50cyBhcmUg
bWFuYWdlZCBieSB0aGUgZG9jdW1lbnQgc2VydmljZSBpbnRlcm5hbGx5IChub3QKIHVzZXIt
bWFuYWdlZCkuCgoMCgUEAAICBhIDZQQaCgwKBQQAAgIBEgNlGzMKDAoFBAACAgMSA2U2NwoM
CgUEAAICCBIDZggwCg8KCAQAAgIInAgAEgNmCS8KeAoEBAACAxIDbAISGmsgRGF0YXNldCBy
ZXNvdXJjZSBuYW1lLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9wcm9jZXNzb3JzL3twcm9jZXNzb3J9L2RhdGFzZXRgCgoMCgUEAAIDBRID
bAIICgwKBQQAAgMBEgNsCQ0KDAoFBAACAwMSA2wQEQpNCgQEAAIEEgNvAjsaQCBSZXF1aXJl
ZC4gU3RhdGUgb2YgdGhlIGRhdGFzZXQuIElnbm9yZWQgd2hlbiB1cGRhdGluZyBkYXRhc2V0
LgoKDAoFBAACBAYSA28CBwoMCgUEAAIEARIDbwgNCgwKBQQAAgQDEgNvEBEKDAoFBAACBAgS
A28SOgoPCggEAAIECJwIABIDbxM5CjQKBAQAAgUSA3ICRRonIE91dHB1dCBvbmx5LiBSZXNl
cnZlZCBmb3IgZnV0dXJlIHVzZS4KCgwKBQQAAgUFEgNyAgYKDAoFBAACBQESA3IHFAoMCgUE
AAIFAxIDchcYCgwKBQQAAgUIEgNyGUQKDwoIBAACBQicCAASA3IaQwo0CgQEAAIGEgN1AkUa
JyBPdXRwdXQgb25seS4gUmVzZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoMCgUEAAIGBRIDdQIG
CgwKBQQAAgYBEgN1BxQKDAoFBAACBgMSA3UXGAoMCgUEAAIGCBIDdRlECg8KCAQAAgYInAgA
EgN1GkMKIwoCBAESBXkAlQEBGhYgRG9jdW1lbnQgSWRlbnRpZmllci4KCgoKAwQBARIDeQgS
CngKBAQBAwASBXwCggEDGmkgSWRlbnRpZmllcyBhIGRvY3VtZW50IHVuaXF1ZWx5IHdpdGhp
biB0aGUgc2NvcGUgb2YgYSBkYXRhc2V0IGluIHRoZQogdXNlci1tYW5hZ2VkIENsb3VkIFN0
b3JhZ2Ugb3B0aW9uLgoKDAoFBAEDAAESA3wKHgpVCgYEAQMAAgASA34EQBpGIFJlcXVpcmVk
LiBUaGUgQ2xvdWQgU3RvcmFnZSBVUkkgd2hlcmUgdGhlIGFjdHVhbCBkb2N1bWVudCBpcyBz
dG9yZWQuCgoOCgcEAQMAAgAFEgN+BAoKDgoHBAEDAAIAARIDfgsSCg4KBwQBAwACAAMSA34V
FgoOCgcEAQMAAgAIEgN+Fz8KEQoKBAEDAAIACJwIABIDfhg+CkwKBgQBAwACARIEgQEELRo8
IElkIG9mIHRoZSBkb2N1bWVudCAoaW5kZXhlZCkgbWFuYWdlZCBieSBDb250ZW50IFdhcmVo
b3VzZS4KCg8KBwQBAwACAQUSBIEBBAoKDwoHBAEDAAIBARIEgQELFAoPCgcEAQMAAgEDEgSB
ARcYCg8KBwQBAwACAQgSBIEBGSwKEAoIBAEDAAIBCAMSBIEBGisKZAoEBAEDARIGhgECiQED
GlQgSWRlbnRpZmllcyBhIGRvY3VtZW50IHVuaXF1ZWx5IHdpdGhpbiB0aGUgc2NvcGUgb2Yg
YSBkYXRhc2V0IGluIHVubWFuYWdlZAogb3B0aW9uLgoKDQoFBAEDAQESBIYBCh0KMwoGBAED
AQIAEgSIAQQ/GiMgUmVxdWlyZWQuIFRoZSBpZCBvZiB0aGUgZG9jdW1lbnQuCgoPCgcEAQMB
AgAFEgSIAQQKCg8KBwQBAwECAAESBIgBCxEKDwoHBAEDAQIAAxIEiAEUFQoPCgcEAQMBAgAI
EgSIARY+ChIKCgQBAwECAAicCAASBIgBFz0KDgoEBAEIABIGiwECkQEDCg0KBQQBCAABEgSL
AQgMCkAKBAQBAgASBI0BBDAaMiBBIGRvY3VtZW50IGlkIHdpdGhpbiB1c2VyLW1hbmFnZWQg
Q2xvdWQgU3RvcmFnZS4KCg0KBQQBAgAGEgSNAQQYCg0KBQQBAgABEgSNARkrCg0KBQQBAgAD
EgSNAS4vCjcKBAQBAgESBJABBC0aKSBBIGRvY3VtZW50IGlkIHdpdGhpbiB1bm1hbmFnZWQg
ZGF0YXNldC4KCg0KBQQBAgEGEgSQAQQXCg0KBQQBAgEBEgSQARgoCg0KBQQBAgEDEgSQASss
CkUKBAQBAgISBJQBAh8aNyBQb2ludHMgdG8gYSBzcGVjaWZpYyByZXZpc2lvbiBvZiB0aGUg
ZG9jdW1lbnQgaWYgc2V0LgoKDQoFBAECAgYSBJQBAg0KDQoFBAECAgESBJQBDhoKDQoFBAEC
AgMSBJQBHR4KHwoCBAISBpgBAKsBARoRIERhdGFzZXQgU2NoZW1hLgoKCwoDBAIBEgSYAQgV
Cg0KAwQCBxIGmQECnAEECg8KBQQCB50IEgaZAQKcAQQKjwEKBAQCAgASBKEBAhIagAEgRGF0
YXNldCBzY2hlbWEgcmVzb3VyY2UgbmFtZS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJvY2Vzc29ycy97cHJvY2Vzc29yfS9kYXRhc2V0
L2RhdGFzZXRTY2hlbWFgCgoNCgUEAgIABRIEoQECCAoNCgUEAgIAARIEoQEJDQoNCgUEAgIA
AxIEoQEQEQowCgQEAgIBEgSkAQJOGiIgT3B0aW9uYWwuIFNjaGVtYSBvZiB0aGUgZGF0YXNl
dC4KCg0KBQQCAgEGEgSkAQIQCg0KBQQCAgEBEgSkAREgCg0KBQQCAgEDEgSkASMkCg0KBQQC
AgEIEgSkASVNChAKCAQCAgEInAgAEgSkASZMCjUKBAQCAgISBKcBAkUaJyBPdXRwdXQgb25s
eS4gUmVzZXJ2ZWQgZm9yIGZ1dHVyZSB1c2UuCgoNCgUEAgICBRIEpwECBgoNCgUEAgICARIE
pwEHFAoNCgUEAgICAxIEpwEXGAoNCgUEAgICCBIEpwEZRAoQCggEAgICCJwIABIEpwEaQwo1
CgQEAgIDEgSqAQJFGicgT3V0cHV0IG9ubHkuIFJlc2VydmVkIGZvciBmdXR1cmUgdXNlLgoK
DQoFBAICAwUSBKoBAgYKDQoFBAICAwESBKoBBxQKDQoFBAICAwMSBKoBFxgKDQoFBAICAwgS
BKoBGUQKEAoIBAICAwicCAASBKoBGkMKTgoCBAMSBq4BAMABARpAIERhdGFzZXQgZG9jdW1l
bnRzIHRoYXQgdGhlIGJhdGNoIG9wZXJhdGlvbiB3aWxsIGJlIGFwcGxpZWQgdG8uCgoLCgME
AwESBK4BCB0KMQoEBAMDABIGsAECtQEDGiEgTGlzdCBvZiBpbmRpdmlkdWFsIERvY3VtZW50
SWRzLgoKDQoFBAMDAAESBLABCh8KZQoGBAMDAAIAEgazAQS0ATEaUyBSZXF1aXJlZC4gTGlz
dCBvZiBEb2N1bWVudCBJRHMgaW5kaWNhdGluZyB3aGVyZSB0aGUgYWN0dWFsIGRvY3VtZW50
cyBhcmUKIHN0b3JlZC4KCg8KBwQDAwACAAQSBLMBBAwKDwoHBAMDAAIABhIEswENFwoPCgcE
AwMAAgABEgSzARgkCg8KBwQDAwACAAMSBLMBJygKDwoHBAMDAAIACBIEtAEIMAoSCgoEAwMA
AgAInAgAEgS0AQkvCg4KBAQDCAASBrcBAr8BAwoNCgUEAwgAARIEtwEIEAolCgQEAwIAEgS5
AQQ2GhcgRG9jdW1lbnQgaWRlbnRpZmllcnMuCgoNCgUEAwIABhIEuQEEGQoNCgUEAwIAARIE
uQEaMQoNCgUEAwIAAxIEuQE0NQqcAQoEBAMCARIEvgEEFhqNASBBIGZpbHRlciBtYXRjaGlu
ZyB0aGUgZG9jdW1lbnRzLgogRm9sbG93cyB0aGUgc2FtZSBmb3JtYXQgYW5kIHJlc3RyaWN0
aW9uIGFzCiBbZ29vZ2xlLmNsb3VkLmRvY3VtZW50YWkubWFzdGVyLkxpc3REb2N1bWVudHNS
ZXF1ZXN0LmZpbHRlcl0uCgoNCgUEAwIBBRIEvgEECgoNCgUEAwIBARIEvgELEQoNCgUEAwIB
AxIEvgEUFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::Dataset::Dataset ===
    # Fields for Dataset
    # Field: gcs_managed_config Type: 11 (.google.cloud.documentai.v1beta3.Dataset.GCSManagedConfig)
    # Field: document_warehouse_config Type: 11 (.google.cloud.documentai.v1beta3.Dataset.DocumentWarehouseConfig)
    # Field: unmanaged_dataset_config Type: 11 (.google.cloud.documentai.v1beta3.Dataset.UnmanagedDatasetConfig)
    # Field: name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.documentai.v1beta3.Dataset.State)
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# Enum: Dataset::State
our $Dataset_STATE_UNSPECIFIED = 0;
our $Dataset_UNINITIALIZED = 1;
our $Dataset_INITIALIZING = 2;
our $Dataset_INITIALIZED = 3;

# === Message: Google::Cloud::Documentai::V1beta3::Dataset::DocumentId ===
    # Fields for DocumentId
    # Field: gcs_managed_doc_id Type: 11 (.google.cloud.documentai.v1beta3.DocumentId.GCSManagedDocumentId)
    # Field: unmanaged_doc_id Type: 11 (.google.cloud.documentai.v1beta3.DocumentId.UnmanagedDocumentId)
    # Field: revision_ref Type: 11 (.google.cloud.documentai.v1beta3.RevisionRef)

# === Message: Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema ===
    # Fields for DatasetSchema
    # Field: name Type: 9 ()
    # Field: document_schema Type: 11 (.google.cloud.documentai.v1beta3.DocumentSchema)
    # Field: satisfies_pzs Type: 8 ()
    # Field: satisfies_pzi Type: 8 ()

# === Message: Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments ===
    # Fields for BatchDatasetDocuments
    # Field: individual_document_ids Type: 11 (.google.cloud.documentai.v1beta3.BatchDatasetDocuments.IndividualDocumentIds)
    # Field: filter Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::Dataset - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::Dataset;

    my $msg = Google::Cloud::Documentai::V1beta3::Dataset::Dataset->new({
        gcs_managed_config => $gcs_managed_config,
        document_warehouse_config => $document_warehouse_config,
        unmanaged_dataset_config => $unmanaged_dataset_config,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->gcs_managed_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::Dataset::Dataset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::Dataset::Dataset

A singleton resource under a
[Processor][google.cloud.documentai.v1beta3.Processor] which configures a
collection of documents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_managed_config() >> / C<< $msg->gcs_managed_config($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::Dataset::GCSManagedConfig>)

Optional. User-managed Cloud Storage dataset configuration. Use this
configuration if the dataset documents are stored under a user-managed
Cloud Storage location.

=item * C<< $msg->document_warehouse_config() >> / C<< $msg->document_warehouse_config($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::Dataset::DocumentWarehouseConfig>)

Optional. Deprecated. Warehouse-based dataset configuration is not
supported.

=item * C<< $msg->unmanaged_dataset_config() >> / C<< $msg->unmanaged_dataset_config($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::Dataset::UnmanagedDatasetConfig>)

Optional. Unmanaged dataset configuration. Use this configuration if the
dataset documents are managed by the document service internally (not
user-managed).

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Dataset resource name.
Format:
`projects/{project}/locations/{location}/processors/{processor}/dataset`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Documentai::V1beta3::Dataset::State>)

Required. State of the dataset. Ignored when updating dataset.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=back

=head3 Enum: Dataset::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<UNINITIALIZED> => C<1>

=item * C<INITIALIZING> => C<2>

=item * C<INITIALIZED> => C<3>

=back

=head2 Google::Cloud::Documentai::V1beta3::Dataset::DocumentId

Document Identifier.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_managed_doc_id() >> / C<< $msg->gcs_managed_doc_id($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::GCSManagedDocumentId>)

A document id within user-managed Cloud Storage.

=item * C<< $msg->unmanaged_doc_id() >> / C<< $msg->unmanaged_doc_id($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::DocumentId::UnmanagedDocumentId>)

A document id within unmanaged dataset.

=item * C<< $msg->revision_ref() >> / C<< $msg->revision_ref($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Document::RevisionRef>)

Points to a specific revision of the document if set.

=back

=head2 Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema

Dataset Schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Dataset schema resource name.
Format:
`projects/{project}/locations/{location}/processors/{processor}/dataset/datasetSchema`

=item * C<< $msg->document_schema() >> / C<< $msg->document_schema($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::DocumentSchema::DocumentSchema>)

Optional. Schema of the dataset.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=item * C<< $msg->satisfies_pzi() >> / C<< $msg->satisfies_pzi($value) >>

Type: C<Bool>

Output only. Reserved for future use.

=back

=head2 Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments

Dataset documents that the batch operation will be applied to.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->individual_document_ids() >> / C<< $msg->individual_document_ids($value) >>

Type: C<Message> (L<Google::Cloud::Documentai::V1beta3::Dataset::BatchDatasetDocuments::IndividualDocumentIds>)

Document identifiers.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter matching the documents.
Follows the same format and restriction as
[google.cloud.documentai.master.ListDocumentsRequest.filter].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::Dataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
