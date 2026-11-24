package Google::Cloud::Contentwarehouse::V1::Pipelines;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Common };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9waXBlbGluZXMucHJvdG8SIGdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvY29u
dGVudHdhcmVob3VzZS92MS9jb21tb24ucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnBy
b3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90byIVChNSdW5QaXBlbGluZVJlc3BvbnNlIv4J
ChNSdW5QaXBlbGluZU1ldGFkYXRhEigKEHRvdGFsX2ZpbGVfY291bnQYASABKAVSDnRvdGFs
RmlsZUNvdW50EioKEWZhaWxlZF9maWxlX2NvdW50GAIgASgFUg9mYWlsZWRGaWxlQ291bnQS
RwoJdXNlcl9pbmZvGAMgASgLMiouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEu
VXNlckluZm9SCHVzZXJJbmZvEpIBChxnY3NfaW5nZXN0X3BpcGVsaW5lX21ldGFkYXRhGAQg
ASgLMk8uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVuUGlwZWxpbmVNZXRh
ZGF0YS5HY3NJbmdlc3RQaXBlbGluZU1ldGFkYXRhSABSGWdjc0luZ2VzdFBpcGVsaW5lTWV0
YWRhdGESmQEKH2V4cG9ydF90b19jZHdfcGlwZWxpbmVfbWV0YWRhdGEYBiABKAsyUS5nb29n
bGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SdW5QaXBlbGluZU1ldGFkYXRhLkV4cG9y
dFRvQ2R3UGlwZWxpbmVNZXRhZGF0YUgAUhtleHBvcnRUb0Nkd1BpcGVsaW5lTWV0YWRhdGES
qQEKJXByb2Nlc3Nfd2l0aF9kb2NfYWlfcGlwZWxpbmVfbWV0YWRhdGEYByABKAsyVi5nb29n
bGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SdW5QaXBlbGluZU1ldGFkYXRhLlByb2Nl
c3NXaXRoRG9jQWlQaXBlbGluZU1ldGFkYXRhSABSIHByb2Nlc3NXaXRoRG9jQWlQaXBlbGlu
ZU1ldGFkYXRhEpABChxpbmRpdmlkdWFsX2RvY3VtZW50X3N0YXR1c2VzGAUgAygLMk4uZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVuUGlwZWxpbmVNZXRhZGF0YS5JbmRp
dmlkdWFsRG9jdW1lbnRTdGF0dXNSGmluZGl2aWR1YWxEb2N1bWVudFN0YXR1c2VzGjoKGUdj
c0luZ2VzdFBpcGVsaW5lTWV0YWRhdGESHQoKaW5wdXRfcGF0aBgBIAEoCVIJaW5wdXRQYXRo
GoIBChtFeHBvcnRUb0Nkd1BpcGVsaW5lTWV0YWRhdGESHAoJZG9jdW1lbnRzGAEgAygJUglk
b2N1bWVudHMSJAoOZG9jX2FpX2RhdGFzZXQYAiABKAlSDGRvY0FpRGF0YXNldBIfCgtvdXRw
dXRfcGF0aBgDIAEoCVIKb3V0cHV0UGF0aBqYAQogUHJvY2Vzc1dpdGhEb2NBaVBpcGVsaW5l
TWV0YWRhdGESHAoJZG9jdW1lbnRzGAEgAygJUglkb2N1bWVudHMSVgoOcHJvY2Vzc29yX2lu
Zm8YAiABKAsyLy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Qcm9jZXNzb3JJ
bmZvUg1wcm9jZXNzb3JJbmZvGmcKGEluZGl2aWR1YWxEb2N1bWVudFN0YXR1cxIfCgtkb2N1
bWVudF9pZBgBIAEoCVIKZG9jdW1lbnRJZBIqCgZzdGF0dXMYAiABKAsyEi5nb29nbGUucnBj
LlN0YXR1c1IGc3RhdHVzQhMKEXBpcGVsaW5lX21ldGFkYXRhInwKDVByb2Nlc3NvckluZm8S
JQoOcHJvY2Vzc29yX25hbWUYASABKAlSDXByb2Nlc3Nvck5hbWUSIwoNZG9jdW1lbnRfdHlw
ZRgCIAEoCVIMZG9jdW1lbnRUeXBlEh8KC3NjaGVtYV9uYW1lGAMgASgJUgpzY2hlbWFOYW1l
IpoCChRJbmdlc3RQaXBlbGluZUNvbmZpZxJFChNkb2N1bWVudF9hY2xfcG9saWN5GAEgASgL
MhUuZ29vZ2xlLmlhbS52MS5Qb2xpY3lSEWRvY3VtZW50QWNsUG9saWN5EkUKH2VuYWJsZV9k
b2N1bWVudF90ZXh0X2V4dHJhY3Rpb24YAiABKAhSHGVuYWJsZURvY3VtZW50VGV4dEV4dHJh
Y3Rpb24SGwoGZm9sZGVyGAMgASgJQgPgQQFSBmZvbGRlchJXCg5jbG91ZF9mdW5jdGlvbhgE
IAEoCUIw+kEtCitjbG91ZGZ1bmN0aW9ucy5nb29nbGVhcGlzLmNvbS9DbG91ZEZ1bmN0aW9u
Ug1jbG91ZEZ1bmN0aW9uIpgCChFHY3NJbmdlc3RQaXBlbGluZRIdCgppbnB1dF9wYXRoGAEg
ASgJUglpbnB1dFBhdGgSHwoLc2NoZW1hX25hbWUYAiABKAlSCnNjaGVtYU5hbWUSJQoOcHJv
Y2Vzc29yX3R5cGUYAyABKAlSDXByb2Nlc3NvclR5cGUSNgoXc2tpcF9pbmdlc3RlZF9kb2N1
bWVudHMYBCABKAhSFXNraXBJbmdlc3RlZERvY3VtZW50cxJkCg9waXBlbGluZV9jb25maWcY
BSABKAsyNi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5Jbmdlc3RQaXBlbGlu
ZUNvbmZpZ0ID4EEBUg5waXBlbGluZUNvbmZpZyKDBAokR2NzSW5nZXN0V2l0aERvY0FpUHJv
Y2Vzc29yc1BpcGVsaW5lEh0KCmlucHV0X3BhdGgYASABKAlSCWlucHV0UGF0aBJyCh1zcGxp
dF9jbGFzc2lmeV9wcm9jZXNzb3JfaW5mbxgCIAEoCzIvLmdvb2dsZS5jbG91ZC5jb250ZW50
d2FyZWhvdXNlLnYxLlByb2Nlc3NvckluZm9SGnNwbGl0Q2xhc3NpZnlQcm9jZXNzb3JJbmZv
EmcKF2V4dHJhY3RfcHJvY2Vzc29yX2luZm9zGAMgAygLMi8uZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjEuUHJvY2Vzc29ySW5mb1IVZXh0cmFjdFByb2Nlc3NvckluZm9zEkEK
HXByb2Nlc3Nvcl9yZXN1bHRzX2ZvbGRlcl9wYXRoGAQgASgJUhpwcm9jZXNzb3JSZXN1bHRz
Rm9sZGVyUGF0aBI2Chdza2lwX2luZ2VzdGVkX2RvY3VtZW50cxgFIAEoCFIVc2tpcEluZ2Vz
dGVkRG9jdW1lbnRzEmQKD3BpcGVsaW5lX2NvbmZpZxgGIAEoCzI2Lmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLkluZ2VzdFBpcGVsaW5lQ29uZmlnQgPgQQFSDnBpcGVsaW5l
Q29uZmlnIr4BChNFeHBvcnRUb0Nkd1BpcGVsaW5lEhwKCWRvY3VtZW50cxgBIAMoCVIJZG9j
dW1lbnRzEiwKEmV4cG9ydF9mb2xkZXJfcGF0aBgCIAEoCVIQZXhwb3J0Rm9sZGVyUGF0aBIp
Cg5kb2NfYWlfZGF0YXNldBgDIAEoCUID4EEBUgxkb2NBaURhdGFzZXQSMAoUdHJhaW5pbmdf
c3BsaXRfcmF0aW8YBCABKAJSEnRyYWluaW5nU3BsaXRSYXRpbyKBAgoYUHJvY2Vzc1dpdGhE
b2NBaVBpcGVsaW5lEhwKCWRvY3VtZW50cxgBIAMoCVIJZG9jdW1lbnRzEiwKEmV4cG9ydF9m
b2xkZXJfcGF0aBgCIAEoCVIQZXhwb3J0Rm9sZGVyUGF0aBJWCg5wcm9jZXNzb3JfaW5mbxgD
IAEoCzIvLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlByb2Nlc3NvckluZm9S
DXByb2Nlc3NvckluZm8SQQodcHJvY2Vzc29yX3Jlc3VsdHNfZm9sZGVyX3BhdGgYBCABKAlS
GnByb2Nlc3NvclJlc3VsdHNGb2xkZXJQYXRoQuQCCiRjb20uZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjFCDlBpcGVsaW5lc1Byb3RvUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28v
Y29udGVudHdhcmVob3VzZS9hcGl2MS9jb250ZW50d2FyZWhvdXNlcGI7Y29udGVudHdhcmVo
b3VzZXBiqgIgR29vZ2xlLkNsb3VkLkNvbnRlbnRXYXJlaG91c2UuVjHKAiBHb29nbGVcQ2xv
dWRcQ29udGVudFdhcmVob3VzZVxWMeoCI0dvb2dsZTo6Q2xvdWQ6OkNvbnRlbnRXYXJlaG91
c2U6OlYx6kFrCitjbG91ZGZ1bmN0aW9ucy5nb29nbGVhcGlzLmNvbS9DbG91ZEZ1bmN0aW9u
Ejxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZnVuY3Rpb25zL3tm
dW5jdGlvbn1KylUKBxIFDgCiAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADcKCQoCAwMSAxUA
JAoJCgIDBBIDFgAhCggKAQgSAxgAPQoJCgIIJRIDGAA9CggKAQgSAxkAZwoJCgIICxIDGQBn
CggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsALwoJCgIICBIDGwAvCggKAQgSAxwAPQoJ
CgIIARIDHAA9CggKAQgSAx0APQoJCgIIKRIDHQA9CggKAQgSAx4APAoJCgIILRIDHgA8CgkK
AQgSBB8AIgIKDAoECJ0IABIEHwAiAgo0CgIEABIDJQAeGikgUmVzcG9uc2UgbWVzc2FnZSBv
ZiBSdW5QaXBlbGluZSBtZXRob2QuCgoKCgMEAAESAyUIGwo1CgIEARIEKABmARopIE1ldGFk
YXRhIG1lc3NhZ2Ugb2YgUnVuUGlwZWxpbmUgbWV0aG9kLgoKCgoDBAEBEgMoCBsKPAoEBAED
ABIEKgIuAxouIFRoZSBtZXRhZGF0YSBtZXNzYWdlIGZvciBHY3NJbmdlc3QgcGlwZWxpbmUu
CgoMCgUEAQMAARIDKgojCm4KBgQBAwACABIDLQQaGl8gVGhlIGlucHV0IENsb3VkIFN0b3Jh
Z2UgZm9sZGVyIGluIHRoaXMgcGlwZWxpbmUuCiBGb3JtYXQ6IGBnczovLzxidWNrZXQtbmFt
ZT4vPGZvbGRlci1uYW1lPmAuCgoOCgcEAQMAAgAFEgMtBAoKDgoHBAEDAAIAARIDLQsVCg4K
BwQBAwACAAMSAy0YGQpACgQEAQMBEgQxAjoDGjIgVGhlIG1ldGFkYXRhIG1lc3NhZ2UgZm9y
IEV4cG9ydC10by1DRFcgcGlwZWxpbmUuCgoMCgUEAQMBARIDMQolCloKBgQBAwECABIDMwQi
GksgVGhlIGlucHV0IGxpc3Qgb2YgYWxsIHRoZSByZXNvdXJjZSBuYW1lcyBvZiB0aGUgZG9j
dW1lbnRzIHRvIGJlIGV4cG9ydGVkLgoKDgoHBAEDAQIABBIDMwQMCg4KBwQBAwECAAUSAzMN
EwoOCgcEAQMBAgABEgMzFB0KDgoHBAEDAQIAAxIDMyAhCjYKBgQBAwECARIDNgQeGicgVGhl
IG91dHB1dCBDRFcgZGF0YXNldCByZXNvdXJjZSBuYW1lLgoKDgoHBAEDAQIBBRIDNgQKCg4K
BwQBAwECAQESAzYLGQoOCgcEAQMBAgEDEgM2HB0KQgoGBAEDAQICEgM5BBsaMyBUaGUgb3V0
cHV0IENsb3VkIFN0b3JhZ2UgZm9sZGVyIGluIHRoaXMgcGlwZWxpbmUuCgoOCgcEAQMBAgIF
EgM5BAoKDgoHBAEDAQICARIDOQsWCg4KBwQBAwECAgMSAzkZGgpFCgQEAQMCEgQ9AkQDGjcg
VGhlIG1ldGFkYXRhIG1lc3NhZ2UgZm9yIFByb2Nlc3Mtd2l0aC1Eb2NBaSBwaXBlbGluZS4K
CgwKBQQBAwIBEgM9CioKXAoGBAEDAgIAEgNABCIaTSBUaGUgaW5wdXQgbGlzdCBvZiBhbGwg
dGhlIHJlc291cmNlIG5hbWVzIG9mIHRoZSBkb2N1bWVudHMgdG8gYmUKIHByb2Nlc3NlZC4K
Cg4KBwQBAwICAAQSA0AEDAoOCgcEAQMCAgAFEgNADRMKDgoHBAEDAgIAARIDQBQdCg4KBwQB
AwICAAMSA0AgIQpDCgYEAQMCAgESA0MEJRo0IFRoZSBEb2NBSSBwcm9jZXNzb3IgdG8gcHJv
Y2VzcyB0aGUgZG9jdW1lbnRzIHdpdGguCgoOCgcEAQMCAgEGEgNDBBEKDgoHBAEDAgIBARID
QxIgCg4KBwQBAwICAQMSA0MjJAo0CgQEAQMDEgRHAk0DGiYgVGhlIHN0YXR1cyBvZiBwcm9j
ZXNzaW5nIGEgZG9jdW1lbnQuCgoMCgUEAQMDARIDRwoiCj0KBgQBAwMCABIDSQQbGi4gRG9j
dW1lbnQgaWRlbnRpZmllciBvZiBhbiBleGlzdGluZyBkb2N1bWVudC4KCg4KBwQBAwMCAAUS
A0kECgoOCgcEAQMDAgABEgNJCxYKDgoHBAEDAwIAAxIDSRkaCjQKBgQBAwMCARIDTAQhGiUg
VGhlIHN0YXR1cyBwcm9jZXNzaW5nIHRoZSBkb2N1bWVudC4KCg4KBwQBAwMCAQYSA0wEFQoO
CgcEAQMDAgEBEgNMFhwKDgoHBAEDAwIBAxIDTB8gCkMKBAQBAgASA1ACHRo2IE51bWJlciBv
ZiBmaWxlcyB0aGF0IHdlcmUgcHJvY2Vzc2VkIGJ5IHRoZSBwaXBlbGluZS4KCgwKBQQBAgAF
EgNQAgcKDAoFBAECAAESA1AIGAoMCgUEAQIAAxIDUBscCk4KBAQBAgESA1MCHhpBIE51bWJl
ciBvZiBmaWxlcyB0aGF0IGhhdmUgZmFpbGVkIGF0IHNvbWUgcG9pbnQgaW4gdGhlIHBpcGVs
aW5lLgoKDAoFBAECAQUSA1MCBwoMCgUEAQIBARIDUwgZCgwKBQQBAgEDEgNTHB0KQQoEBAEC
AhIDVgIZGjQgVXNlciB1bmlxdWUgaWRlbnRpZmljYXRpb24gYW5kIGdyb3VwcyBpbmZvcm1h
dGlvbi4KCgwKBQQBAgIGEgNWAgoKDAoFBAECAgESA1YLFAoMCgUEAQICAxIDVhcYCiYKBAQB
CAASBFkCYgMaGCBUaGUgcGlwZWxpbmUgbWV0YWRhdGEuCgoMCgUEAQgAARIDWQgZCjwKBAQB
AgMSA1sEPxovIFRoZSBwaXBlbGluZSBtZXRhZGF0YSBmb3IgR2NzSW5nZXN0IHBpcGVsaW5l
LgoKDAoFBAECAwYSA1sEHQoMCgUEAQIDARIDWx46CgwKBQQBAgMDEgNbPT4KQAoEBAECBBID
XgREGjMgVGhlIHBpcGVsaW5lIG1ldGFkYXRhIGZvciBFeHBvcnQtdG8tQ0RXIHBpcGVsaW5l
LgoKDAoFBAECBAYSA14EHwoMCgUEAQIEARIDXiA/CgwKBQQBAgQDEgNeQkMKRQoEBAECBRID
YQRPGjggVGhlIHBpcGVsaW5lIG1ldGFkYXRhIGZvciBQcm9jZXNzLXdpdGgtRG9jQWkgcGlw
ZWxpbmUuCgoMCgUEAQIFBhIDYQQkCgwKBQQBAgUBEgNhJUoKDAoFBAECBQMSA2FNTgo9CgQE
AQIGEgNlAkUaMCBUaGUgbGlzdCBvZiByZXNwb25zZSBkZXRhaWxzIG9mIGVhY2ggZG9jdW1l
bnQuCgoMCgUEAQIGBBIDZQIKCgwKBQQBAgYGEgNlCyMKDAoFBAECBgESA2UkQAoMCgUEAQIG
AxIDZUNECi4KAgQCEgRpAHgBGiIgVGhlIERvY0FJIHByb2Nlc3NvciBpbmZvcm1hdGlvbi4K
CgoKAwQCARIDaQgVCuQBCgQEAgIAEgNuAhwa1gEgVGhlIHByb2Nlc3NvciByZXNvdXJjZSBu
YW1lLgogRm9ybWF0IGlzIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vcHJvY2Vzc29ycy97cHJvY2Vzc29yfWAsCiBvcgogYHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9wcm9jZXNzb3JzL3twcm9jZXNzb3J9L3Byb2Nlc3NvclZl
cnNpb25zL3twcm9jZXNzb3JWZXJzaW9ufWAKCgwKBQQCAgAFEgNuAggKDAoFBAICAAESA24J
FwoMCgUEAgIAAxIDbhobClAKBAQCAgESA3ECGxpDIFRoZSBwcm9jZXNzb3Igd2lsbCBwcm9j
ZXNzIHRoZSBkb2N1bWVudHMgd2l0aCB0aGlzIGRvY3VtZW50IHR5cGUuCgoMCgUEAgIBBRID
cQIICgwKBQQCAgEBEgNxCRYKDAoFBAICAQMSA3EZGgrSAQoEBAICAhIDdwIZGsQBIFRoZSBE
b2N1bWVudCBzY2hlbWEgcmVzb3VyY2UgbmFtZS4gQWxsIGRvY3VtZW50cyBwcm9jZXNzZWQg
YnkgdGhpcwogcHJvY2Vzc29yIHdpbGwgdXNlIHRoaXMgc2NoZW1hLgogRm9ybWF0OgogcHJv
amVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudFNj
aGVtYXMve2RvY3VtZW50X3NjaGVtYV9pZH0uCgoMCgUEAgICBRIDdwIICgwKBQQCAgIBEgN3
CRQKDAoFBAICAgMSA3cXGAotCgIEAxIFewCzAQEaICBUaGUgaW5nZXN0aW9uIHBpcGVsaW5l
IGNvbmZpZy4KCgoKAwQDARIDewgcCt0FCgQEAwIAEgSNAQIvGs4FIFRoZSBkb2N1bWVudCBs
ZXZlbCBhY2wgcG9saWN5IGNvbmZpZy4KIFRoaXMgcmVmZXJzIHRvIGFuIElkZW50aXR5IGFu
ZCBBY2Nlc3MgKElBTSkgcG9saWN5LCB3aGljaCBzcGVjaWZpZXMgYWNjZXNzCiBjb250cm9s
cyBmb3IgYWxsIGRvY3VtZW50cyBpbmdlc3RlZCBieSB0aGUgcGlwZWxpbmUuIFRoZQogW3Jv
bGVdW2dvb2dsZS5pYW0udjEuQmluZGluZy5yb2xlXSBhbmQKIFttZW1iZXJzXVtnb29nbGUu
aWFtLnYxLkJpbmRpbmcucm9sZV0gdW5kZXIgdGhlIHBvbGljeSBuZWVkcyB0byBiZQogc3Bl
Y2lmaWVkLgoKIFRoZSBmb2xsb3dpbmcgcm9sZXMgYXJlIHN1cHBvcnRlZCBmb3IgZG9jdW1l
bnQgbGV2ZWwgYWNsIGNvbnRyb2w6CiAqIHJvbGVzL2NvbnRlbnR3YXJlaG91c2UuZG9jdW1l
bnRBZG1pbgogKiByb2xlcy9jb250ZW50d2FyZWhvdXNlLmRvY3VtZW50RWRpdG9yCiAqIHJv
bGVzL2NvbnRlbnR3YXJlaG91c2UuZG9jdW1lbnRWaWV3ZXIKCiBUaGUgZm9sbG93aW5nIG1l
bWJlcnMgYXJlIHN1cHBvcnRlZCBmb3IgZG9jdW1lbnQgbGV2ZWwgYWNsIGNvbnRyb2w6CiAq
IHVzZXI6dXNlci1lbWFpbEBleGFtcGxlLmNvbQogKiBncm91cDpncm91cC1lbWFpbEBleGFt
cGxlLmNvbQogTm90ZSB0aGF0IGZvciBkb2N1bWVudHMgc2VhcmNoZWQgd2l0aCBMTE0sIG9u
bHkgc2luZ2xlIGxldmVsIHVzZXIgb3IgZ3JvdXAKIGFjbCBjaGVjayBpcyBzdXBwb3J0ZWQu
CgoNCgUEAwIABhIEjQECFgoNCgUEAwIAARIEjQEXKgoNCgUEAwIAAxIEjQEtLgqPAQoEBAMC
ARIEkgECKxqAASBUaGUgZG9jdW1lbnQgdGV4dCBleHRyYWN0aW9uIGVuYWJsZWQgZmxhZy4K
IElmIHRoZSBmbGFnIGlzIHNldCB0byB0cnVlLCBEV0ggd2lsbCBwZXJmb3JtIHRleHQgZXh0
cmFjdGlvbiBvbiB0aGUgcmF3CiBkb2N1bWVudC4KCg0KBQQDAgEFEgSSAQIGCg0KBQQDAgEB
EgSSAQcmCg0KBQQDAgEDEgSSASkqCsYBCgQEAwICEgSXAQI9GrcBIE9wdGlvbmFsLiBUaGUg
bmFtZSBvZiB0aGUgZm9sZGVyIHRvIHdoaWNoIGFsbCBpbmdlc3RlZCBkb2N1bWVudHMgd2ls
bCBiZQogbGlua2VkIGR1cmluZyBpbmdlc3Rpb24gcHJvY2Vzcy4gRm9ybWF0IGlzCiBgcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvY3VtZW50cy97Zm9sZGVy
X2lkfWAKCg0KBQQDAgIFEgSXAQIICg0KBQQDAgIBEgSXAQkPCg0KBQQDAgIDEgSXARITCg0K
BQQDAgIIEgSXARQ8ChAKCAQDAgIInAgAEgSXARU7CooHCgQEAwIDEgawAQKyAQUa+QYgVGhl
IENsb3VkIEZ1bmN0aW9uIHJlc291cmNlIG5hbWUuIFRoZSBDbG91ZCBGdW5jdGlvbiBuZWVk
cyB0byBsaXZlIGluc2lkZQogY29uc3VtZXIgcHJvamVjdCBhbmQgaXMgYWNjZXNzaWJsZSB0
byBEb2N1bWVudCBBSSBXYXJlaG91c2UgUDRTQS4KIE9ubHkgQ2xvdWQgRnVuY3Rpb25zIFYy
IGlzIHN1cHBvcnRlZC4gQ2xvdWQgZnVuY3Rpb24gZXhlY3V0aW9uIHNob3VsZAogY29tcGxl
dGUgd2l0aGluIDUgbWludXRlcyBvciB0aGlzIGZpbGUgaW5nZXN0aW9uIG1heSBmYWlsIGR1
ZSB0byB0aW1lb3V0LgogRm9ybWF0OiBgaHR0cHM6Ly97cmVnaW9ufS17cHJvamVjdF9pZH0u
Y2xvdWRmdW5jdGlvbnMubmV0L3tjbG91ZF9mdW5jdGlvbn1gCiBUaGUgZm9sbG93aW5nIGtl
eXMgYXJlIGF2YWlsYWJsZSB0aGUgcmVxdWVzdCBqc29uIHBheWxvYWQuCiAqIGRpc3BsYXlf
bmFtZQogKiBwcm9wZXJ0aWVzCiAqIHBsYWluX3RleHQKICogcmVmZXJlbmNlX2lkCiAqIGRv
Y3VtZW50X3NjaGVtYV9uYW1lCiAqIHJhd19kb2N1bWVudF9wYXRoCiAqIHJhd19kb2N1bWVu
dF9maWxlX3R5cGUKCiBUaGUgZm9sbG93aW5nIGtleXMgZnJvbSB0aGUgY2xvdWQgZnVuY3Rp
b24ganNvbiByZXNwb25zZSBwYXlsb2FkIHdpbGwgYmUKIGluZ2VzdGVkIHRvIHRoZSBEb2N1
bWVudCBBSSBXYXJlaG91c2UgYXMgcGFydCBvZiBEb2N1bWVudCBwcm90byBjb250ZW50CiBh
bmQvb3IgcmVsYXRlZCBpbmZvcm1hdGlvbi4gVGhlIG9yaWdpbmFsIHZhbHVlcyB3aWxsIGJl
IG92ZXJyaWRkZW4gaWYgYW55CiBrZXkgaXMgcHJlc2VudCBpbiB0aGUgcmVzcG9uc2UuCiAq
IGRpc3BsYXlfbmFtZQogKiBwcm9wZXJ0aWVzCiAqIHBsYWluX3RleHQKICogZG9jdW1lbnRf
YWNsX3BvbGljeQogKiBmb2xkZXIKCg0KBQQDAgMFEgSwAQIICg0KBQQDAgMBEgSwAQkXCg0K
BQQDAgMDEgSwARobCg8KBQQDAgMIEgawARyyAQQKEQoHBAMCAwifCBIGsAEdsgEDCkoKAgQE
Ega2AQDQAQEaPCBUaGUgY29uZmlndXJhdGlvbiBvZiB0aGUgQ2xvdWQgU3RvcmFnZSBJbmdl
c3Rpb24gcGlwZWxpbmUuCgoLCgMEBAESBLYBCBkKogEKBAQEAgASBLoBAhgakwEgVGhlIGlu
cHV0IENsb3VkIFN0b3JhZ2UgZm9sZGVyLiBBbGwgZmlsZXMgdW5kZXIgdGhpcyBmb2xkZXIg
d2lsbCBiZQogaW1wb3J0ZWQgdG8gRG9jdW1lbnQgV2FyZWhvdXNlLgogRm9ybWF0OiBgZ3M6
Ly88YnVja2V0LW5hbWU+Lzxmb2xkZXItbmFtZT5gLgoKDQoFBAQCAAUSBLoBAggKDQoFBAQC
AAESBLoBCRMKDQoFBAQCAAMSBLoBFhcK3AEKBAQEAgESBMABAhkazQEgVGhlIERvY3VtZW50
IFdhcmVob3VzZSBzY2hlbWEgcmVzb3VyY2UgbmFtZS4gQWxsIGRvY3VtZW50cyBwcm9jZXNz
ZWQgYnkKIHRoaXMgcGlwZWxpbmUgd2lsbCB1c2UgdGhpcyBzY2hlbWEuCiBGb3JtYXQ6CiBw
cm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvY3VtZW50
U2NoZW1hcy97ZG9jdW1lbnRfc2NoZW1hX2lkfS4KCg0KBQQEAgEFEgTAAQIICg0KBQQEAgEB
EgTAAQkUCg0KBQQEAgEDEgTAARcYCn0KBAQEAgISBMQBAhwabyBUaGUgRG9jIEFJIHByb2Nl
c3NvciB0eXBlIG5hbWUuIE9ubHkgdXNlZCB3aGVuIHRoZSBmb3JtYXQgb2YgaW5nZXN0ZWQK
IGZpbGVzIGlzIERvYyBBSSBEb2N1bWVudCBwcm90byBmb3JtYXQuCgoNCgUEBAICBRIExAEC
CAoNCgUEBAICARIExAEJFwoNCgUEBAICAxIExAEaGwrRAQoEBAQCAxIEyQECIxrCASBUaGUg
ZmxhZyB3aGV0aGVyIHRvIHNraXAgaW5nZXN0ZWQgZG9jdW1lbnRzLgogSWYgaXQgaXMgc2V0
IHRvIHRydWUsIGRvY3VtZW50cyBpbiBDbG91ZCBTdG9yYWdlIGNvbnRhaW5zIGtleSAic3Rh
dHVzIiB3aXRoCiB2YWx1ZSAic3RhdHVzPWluZ2VzdGVkIiBpbiBjdXN0b20gbWV0YWRhdGEg
d2lsbCBiZSBza2lwcGVkIHRvIGluZ2VzdC4KCg0KBQQEAgMFEgTJAQIGCg0KBQQEAgMBEgTJ
AQceCg0KBQQEAgMDEgTJASEiCsABCgQEBAIEEgbOAQLPAS8arwEgT3B0aW9uYWwuIFRoZSBj
b25maWcgZm9yIHRoZSBDbG91ZCBTdG9yYWdlIEluZ2VzdGlvbiBwaXBlbGluZS4KIEl0IHBy
b3ZpZGVzIGFkZGl0aW9uYWwgY3VzdG9taXphdGlvbiBvcHRpb25zIHRvIHJ1biB0aGUgcGlw
ZWxpbmUgYW5kIGNhbiBiZQogc2tpcHBlZCBpZiBpdCBpcyBub3QgYXBwbGljYWJsZS4KCg0K
BQQEAgQGEgTOAQIWCg0KBQQEAgQBEgTOARcmCg0KBQQEAgQDEgTOASkqCg0KBQQEAgQIEgTP
AQYuChAKCAQEAgQInAgAEgTPAQctCmEKAgQFEgbUAQD0AQEaUyBUaGUgY29uZmlndXJhdGlv
biBvZiB0aGUgQ2xvdWQgU3RvcmFnZSBJbmdlc3Rpb24gd2l0aCBEb2NBSSBQcm9jZXNzb3Jz
CiBwaXBlbGluZS4KCgsKAwQFARIE1AEILAqiAQoEBAUCABIE2AECGBqTASBUaGUgaW5wdXQg
Q2xvdWQgU3RvcmFnZSBmb2xkZXIuIEFsbCBmaWxlcyB1bmRlciB0aGlzIGZvbGRlciB3aWxs
IGJlCiBpbXBvcnRlZCB0byBEb2N1bWVudCBXYXJlaG91c2UuCiBGb3JtYXQ6IGBnczovLzxi
dWNrZXQtbmFtZT4vPGZvbGRlci1uYW1lPmAuCgoNCgUEBQIABRIE2AECCAoNCgUEBQIAARIE
2AEJEwoNCgUEBQIAAxIE2AEWFwqQAQoEBAUCARIE3QECMhqBASBUaGUgc3BsaXQgYW5kIGNs
YXNzaWZ5IHByb2Nlc3NvciBpbmZvcm1hdGlvbi4KIFRoZSBzcGxpdCBhbmQgY2xhc3NpZnkg
cmVzdWx0IHdpbGwgYmUgdXNlZCB0byBmaW5kIGEgbWF0Y2hlZCBleHRyYWN0CiBwcm9jZXNz
b3IuCgoNCgUEBQIBBhIE3QECDwoNCgUEBQIBARIE3QEQLQoNCgUEBQIBAxIE3QEwMQrwAQoE
BAUCAhIE4wECNRrhASBUaGUgZXh0cmFjdCBwcm9jZXNzb3JzIGluZm9ybWF0aW9uLgogT25l
IG1hdGNoZWQgZXh0cmFjdCBwcm9jZXNzb3Igd2lsbCBiZSB1c2VkIHRvIHByb2Nlc3MgZG9j
dW1lbnRzIGJhc2VkIG9uCiB0aGUgY2xhc3NpZnkgcHJvY2Vzc29yIHJlc3VsdC4gSWYgbm8g
Y2xhc3NpZnkgcHJvY2Vzc29yIGlzIHNwZWNpZmllZCwgdGhlCiBmaXJzdCBleHRyYWN0IHBy
b2Nlc3NvciB3aWxsIGJlIHVzZWQuCgoNCgUEBQICBBIE4wECCgoNCgUEBQICBhIE4wELGAoN
CgUEBQICARIE4wEZMAoNCgUEBQICAxIE4wEzNAqKAQoEBAUCAxIE6AECKxp8IFRoZSBDbG91
ZCBTdG9yYWdlIGZvbGRlciBwYXRoIHVzZWQgdG8gc3RvcmUgdGhlIHJhdyByZXN1bHRzIGZy
b20KIHByb2Nlc3NvcnMuCiBGb3JtYXQ6IGBnczovLzxidWNrZXQtbmFtZT4vPGZvbGRlci1u
YW1lPmAuCgoNCgUEBQIDBRIE6AECCAoNCgUEBQIDARIE6AEJJgoNCgUEBQIDAxIE6AEpKgrR
AQoEBAUCBBIE7QECIxrCASBUaGUgZmxhZyB3aGV0aGVyIHRvIHNraXAgaW5nZXN0ZWQgZG9j
dW1lbnRzLgogSWYgaXQgaXMgc2V0IHRvIHRydWUsIGRvY3VtZW50cyBpbiBDbG91ZCBTdG9y
YWdlIGNvbnRhaW5zIGtleSAic3RhdHVzIiB3aXRoCiB2YWx1ZSAic3RhdHVzPWluZ2VzdGVk
IiBpbiBjdXN0b20gbWV0YWRhdGEgd2lsbCBiZSBza2lwcGVkIHRvIGluZ2VzdC4KCg0KBQQF
AgQFEgTtAQIGCg0KBQQFAgQBEgTtAQceCg0KBQQFAgQDEgTtASEiCtYBCgQEBQIFEgbyAQLz
AS8axQEgT3B0aW9uYWwuIFRoZSBjb25maWcgZm9yIHRoZSBDbG91ZCBTdG9yYWdlIEluZ2Vz
dGlvbiB3aXRoIERvY0FJIFByb2Nlc3NvcnMKIHBpcGVsaW5lLiBJdCBwcm92aWRlcyBhZGRp
dGlvbmFsIGN1c3RvbWl6YXRpb24gb3B0aW9ucyB0byBydW4gdGhlIHBpcGVsaW5lCiBhbmQg
Y2FuIGJlIHNraXBwZWQgaWYgaXQgaXMgbm90IGFwcGxpY2FibGUuCgoNCgUEBQIFBhIE8gEC
FgoNCgUEBQIFARIE8gEXJgoNCgUEBQIFAxIE8gEpKgoNCgUEBQIFCBIE8wEGLgoQCggEBQIF
CJwIABIE8wEHLQpmCgIEBhIG+AEAjAIBGlggVGhlIGNvbmZpZ3VyYXRpb24gb2YgZXhwb3J0
aW5nIGRvY3VtZW50cyBmcm9tIHRoZSBEb2N1bWVudCBXYXJlaG91c2UgdG8gQ0RXCiBwaXBl
bGluZS4KCgsKAwQGARIE+AEIGwqnAQoEBAYCABIE/AECIBqYASBUaGUgbGlzdCBvZiBhbGwg
dGhlIHJlc291cmNlIG5hbWVzIG9mIHRoZSBkb2N1bWVudHMgdG8gYmUgcHJvY2Vzc2VkLgog
Rm9ybWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9kb2N1bWVudHMve2RvY3VtZW50X2lkfS4KCg0KBQQGAgAEEgT8AQIKCg0KBQQGAgAFEgT8
AQsRCg0KBQQGAgABEgT8ARIbCg0KBQQGAgADEgT8AR4fCpsBCgQEBgIBEgSBAgIgGowBIFRo
ZSBDbG91ZCBTdG9yYWdlIGZvbGRlciBwYXRoIHVzZWQgdG8gc3RvcmUgdGhlIGV4cG9ydGVk
IGRvY3VtZW50cyBiZWZvcmUKIGJlaW5nIHNlbnQgdG8gQ0RXLgogRm9ybWF0OiBgZ3M6Ly88
YnVja2V0LW5hbWU+Lzxmb2xkZXItbmFtZT5gLgoKDQoFBAYCAQUSBIECAggKDQoFBAYCAQES
BIECCRsKDQoFBAYCAQMSBIECHh8K5AEKBAQGAgISBIYCAkUa1QEgT3B0aW9uYWwuIFRoZSBD
RFcgZGF0YXNldCByZXNvdXJjZSBuYW1lLiBUaGlzIGZpZWxkIGlzIG9wdGlvbmFsLiBJZiBu
b3QKIHNldCwgdGhlIGRvY3VtZW50cyB3aWxsIGJlIGV4cG9ydGVkIHRvIENsb3VkIFN0b3Jh
Z2Ugb25seS4gRm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L3Byb2Nlc3NvcnMve3Byb2Nlc3Nvcn0vZGF0YXNldAoKDQoFBAYCAgUSBIYCAggKDQoF
BAYCAgESBIYCCRcKDQoFBAYCAgMSBIYCGhsKDQoFBAYCAggSBIYCHEQKEAoIBAYCAgicCAAS
BIYCHUMK9QEKBAQGAgMSBIsCAiEa5gEgUmF0aW8gb2YgdHJhaW5pbmcgZGF0YXNldCBzcGxp
dC4gV2hlbiBpbXBvcnRpbmcgaW50byBEb2N1bWVudCBBSSBXb3JrYmVuY2gsCiBkb2N1bWVu
dHMgd2lsbCBiZSBhdXRvbWF0aWNhbGx5IHNwbGl0IGludG8gdHJhaW5pbmcgYW5kIHRlc3Qg
c3BsaXQgY2F0ZWdvcnkKIHdpdGggdGhlIHNwZWNpZmllZCByYXRpby4gVGhpcyBmaWVsZCBp
cyByZXF1aXJlZCBpZiBkb2NfYWlfZGF0YXNldCBpcyBzZXQuCgoNCgUEBgIDBRIEiwICBwoN
CgUEBgIDARIEiwIIHAoNCgUEBgIDAxIEiwIfIApwCgIEBxIGkAIAogIBGmIgVGhlIGNvbmZp
Z3VyYXRpb24gb2YgcHJvY2Vzc2luZyBkb2N1bWVudHMgaW4gRG9jdW1lbnQgV2FyZWhvdXNl
IHdpdGggRG9jQWkKIHByb2Nlc3NvcnMgcGlwZWxpbmUuCgoLCgMEBwESBJACCCAKpwEKBAQH
AgASBJQCAiAamAEgVGhlIGxpc3Qgb2YgYWxsIHRoZSByZXNvdXJjZSBuYW1lcyBvZiB0aGUg
ZG9jdW1lbnRzIHRvIGJlIHByb2Nlc3NlZC4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0
X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tkb2N1bWVudF9pZH0u
CgoNCgUEBwIABBIElAICCgoNCgUEBwIABRIElAILEQoNCgUEBwIAARIElAISGwoNCgUEBwIA
AxIElAIeHwqbAQoEBAcCARIEmQICIBqMASBUaGUgQ2xvdWQgU3RvcmFnZSBmb2xkZXIgcGF0
aCB1c2VkIHRvIHN0b3JlIHRoZSBleHBvcnRlZCBkb2N1bWVudHMgYmVmb3JlCiBiZWluZyBz
ZW50IHRvIENEVy4KIEZvcm1hdDogYGdzOi8vPGJ1Y2tldC1uYW1lPi88Zm9sZGVyLW5hbWU+
YC4KCg0KBQQHAgEFEgSZAgIICg0KBQQHAgEBEgSZAgkbCg0KBQQHAgEDEgSZAh4fCi4KBAQH
AgISBJwCAiMaICBUaGUgQ0RXIHByb2Nlc3NvciBpbmZvcm1hdGlvbi4KCg0KBQQHAgIGEgSc
AgIPCg0KBQQHAgIBEgScAhAeCg0KBQQHAgIDEgScAiEiCooBCgQEBwIDEgShAgIrGnwgVGhl
IENsb3VkIFN0b3JhZ2UgZm9sZGVyIHBhdGggdXNlZCB0byBzdG9yZSB0aGUgcmF3IHJlc3Vs
dHMgZnJvbQogcHJvY2Vzc29ycy4KIEZvcm1hdDogYGdzOi8vPGJ1Y2tldC1uYW1lPi88Zm9s
ZGVyLW5hbWU+YC4KCg0KBQQHAgMFEgShAgIICg0KBQQHAgMBEgShAgkmCg0KBQQHAgMDEgSh
AikqYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse ===
    # Fields for RunPipelineResponse

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata ===
    # Fields for RunPipelineMetadata
    # Field: total_file_count Type: 5 ()
    # Field: failed_file_count Type: 5 ()
    # Field: user_info Type: 11 (.google.cloud.contentwarehouse.v1.UserInfo)
    # Field: gcs_ingest_pipeline_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RunPipelineMetadata.GcsIngestPipelineMetadata)
    # Field: export_to_cdw_pipeline_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RunPipelineMetadata.ExportToCdwPipelineMetadata)
    # Field: process_with_doc_ai_pipeline_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RunPipelineMetadata.ProcessWithDocAiPipelineMetadata)
    # Field: individual_document_statuses Type: 11 (.google.cloud.contentwarehouse.v1.RunPipelineMetadata.IndividualDocumentStatus)

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo ===
    # Fields for ProcessorInfo
    # Field: processor_name Type: 9 ()
    # Field: document_type Type: 9 ()
    # Field: schema_name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig ===
    # Fields for IngestPipelineConfig
    # Field: document_acl_policy Type: 11 (.google.iam.v1.Policy)
    # Field: enable_document_text_extraction Type: 8 ()
    # Field: folder Type: 9 ()
    # Field: cloud_function Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline ===
    # Fields for GcsIngestPipeline
    # Field: input_path Type: 9 ()
    # Field: schema_name Type: 9 ()
    # Field: processor_type Type: 9 ()
    # Field: skip_ingested_documents Type: 8 ()
    # Field: pipeline_config Type: 11 (.google.cloud.contentwarehouse.v1.IngestPipelineConfig)

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline ===
    # Fields for GcsIngestWithDocAiProcessorsPipeline
    # Field: input_path Type: 9 ()
    # Field: split_classify_processor_info Type: 11 (.google.cloud.contentwarehouse.v1.ProcessorInfo)
    # Field: extract_processor_infos Type: 11 (.google.cloud.contentwarehouse.v1.ProcessorInfo)
    # Field: processor_results_folder_path Type: 9 ()
    # Field: skip_ingested_documents Type: 8 ()
    # Field: pipeline_config Type: 11 (.google.cloud.contentwarehouse.v1.IngestPipelineConfig)

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline ===
    # Fields for ExportToCdwPipeline
    # Field: documents Type: 9 ()
    # Field: export_folder_path Type: 9 ()
    # Field: doc_ai_dataset Type: 9 ()
    # Field: training_split_ratio Type: 2 ()

# === Message: Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline ===
    # Fields for ProcessWithDocAiPipeline
    # Field: documents Type: 9 ()
    # Field: export_folder_path Type: 9 ()
    # Field: processor_info Type: 11 (.google.cloud.contentwarehouse.v1.ProcessorInfo)
    # Field: processor_results_folder_path Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Pipelines - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/pipelines.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::Pipelines;

    my $msg = Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/pipelines.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineResponse

Response message of RunPipeline method.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata

Metadata message of RunPipeline method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->total_file_count() >> / C<< $msg->total_file_count($value) >>

Type: C<Int32>

Number of files that were processed by the pipeline.

=item * C<< $msg->failed_file_count() >> / C<< $msg->failed_file_count($value) >>

Type: C<Int32>

Number of files that have failed at some point in the pipeline.

=item * C<< $msg->user_info() >> / C<< $msg->user_info($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::UserInfo>)

User unique identification and groups information.

=item * C<< $msg->gcs_ingest_pipeline_metadata() >> / C<< $msg->gcs_ingest_pipeline_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::GcsIngestPipelineMetadata>)

The pipeline metadata for GcsIngest pipeline.

=item * C<< $msg->export_to_cdw_pipeline_metadata() >> / C<< $msg->export_to_cdw_pipeline_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ExportToCdwPipelineMetadata>)

The pipeline metadata for Export-to-CDW pipeline.

=item * C<< $msg->process_with_doc_ai_pipeline_metadata() >> / C<< $msg->process_with_doc_ai_pipeline_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::ProcessWithDocAiPipelineMetadata>)

The pipeline metadata for Process-with-DocAi pipeline.

=item * C<< $msg->individual_document_statuses() >> / C<< $msg->individual_document_statuses($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::RunPipelineMetadata::IndividualDocumentStatus>)

The list of response details of each document.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo

The DocAI processor information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->processor_name() >> / C<< $msg->processor_name($value) >>

Type: C<String>

The processor resource name.
Format is `projects/{project}/locations/{location}/processors/{processor}`,
or
`projects/{project}/locations/{location}/processors/{processor}/processorVersions/{processorVersion}`

=item * C<< $msg->document_type() >> / C<< $msg->document_type($value) >>

Type: C<String>

The processor will process the documents with this document type.

=item * C<< $msg->schema_name() >> / C<< $msg->schema_name($value) >>

Type: C<String>

The Document schema resource name. All documents processed by this
processor will use this schema.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig

The ingestion pipeline config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_acl_policy() >> / C<< $msg->document_acl_policy($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Policy>)

The document level acl policy config.
This refers to an Identity and Access (IAM) policy, which specifies access
controls for all documents ingested by the pipeline. The
[role][google.iam.v1.Binding.role] and
[members][google.iam.v1.Binding.role] under the policy needs to be
specified.

The following roles are supported for document level acl control:
* roles/contentwarehouse.documentAdmin
* roles/contentwarehouse.documentEditor
* roles/contentwarehouse.documentViewer

The following members are supported for document level acl control:
* user:user-email@example.com
* group:group-email@example.com
Note that for documents searched with LLM, only single level user or group
acl check is supported.

=item * C<< $msg->enable_document_text_extraction() >> / C<< $msg->enable_document_text_extraction($value) >>

Type: C<Bool>

The document text extraction enabled flag.
If the flag is set to true, DWH will perform text extraction on the raw
document.

=item * C<< $msg->folder() >> / C<< $msg->folder($value) >>

Type: C<String>

Optional. The name of the folder to which all ingested documents will be
linked during ingestion process. Format is
`projects/{project}/locations/{location}/documents/{folder_id}`

=item * C<< $msg->cloud_function() >> / C<< $msg->cloud_function($value) >>

Type: C<String>

The Cloud Function resource name. The Cloud Function needs to live inside
consumer project and is accessible to Document AI Warehouse P4SA.
Only Cloud Functions V2 is supported. Cloud function execution should
complete within 5 minutes or this file ingestion may fail due to timeout.
Format: `https://{region}-{project_id}.cloudfunctions.net/{cloud_function}`
The following keys are available the request json payload.
* display_name
* properties
* plain_text
* reference_id
* document_schema_name
* raw_document_path
* raw_document_file_type

The following keys from the cloud function json response payload will be
ingested to the Document AI Warehouse as part of Document proto content
and/or related information. The original values will be overridden if any
key is present in the response.
* display_name
* properties
* plain_text
* document_acl_policy
* folder

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline

The configuration of the Cloud Storage Ingestion pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_path() >> / C<< $msg->input_path($value) >>

Type: C<String>

The input Cloud Storage folder. All files under this folder will be
imported to Document Warehouse.
Format: `gs://<bucket-name>/<folder-name>`.

=item * C<< $msg->schema_name() >> / C<< $msg->schema_name($value) >>

Type: C<String>

The Document Warehouse schema resource name. All documents processed by
this pipeline will use this schema.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=item * C<< $msg->processor_type() >> / C<< $msg->processor_type($value) >>

Type: C<String>

The Doc AI processor type name. Only used when the format of ingested
files is Doc AI Document proto format.

=item * C<< $msg->skip_ingested_documents() >> / C<< $msg->skip_ingested_documents($value) >>

Type: C<Bool>

The flag whether to skip ingested documents.
If it is set to true, documents in Cloud Storage contains key "status" with
value "status=ingested" in custom metadata will be skipped to ingest.

=item * C<< $msg->pipeline_config() >> / C<< $msg->pipeline_config($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig>)

Optional. The config for the Cloud Storage Ingestion pipeline.
It provides additional customization options to run the pipeline and can be
skipped if it is not applicable.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline

The configuration of the Cloud Storage Ingestion with DocAI Processors
pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_path() >> / C<< $msg->input_path($value) >>

Type: C<String>

The input Cloud Storage folder. All files under this folder will be
imported to Document Warehouse.
Format: `gs://<bucket-name>/<folder-name>`.

=item * C<< $msg->split_classify_processor_info() >> / C<< $msg->split_classify_processor_info($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo>)

The split and classify processor information.
The split and classify result will be used to find a matched extract
processor.

=item * C<< $msg->extract_processor_infos() >> / C<< $msg->extract_processor_infos($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo>)

The extract processors information.
One matched extract processor will be used to process documents based on
the classify processor result. If no classify processor is specified, the
first extract processor will be used.

=item * C<< $msg->processor_results_folder_path() >> / C<< $msg->processor_results_folder_path($value) >>

Type: C<String>

The Cloud Storage folder path used to store the raw results from
processors.
Format: `gs://<bucket-name>/<folder-name>`.

=item * C<< $msg->skip_ingested_documents() >> / C<< $msg->skip_ingested_documents($value) >>

Type: C<Bool>

The flag whether to skip ingested documents.
If it is set to true, documents in Cloud Storage contains key "status" with
value "status=ingested" in custom metadata will be skipped to ingest.

=item * C<< $msg->pipeline_config() >> / C<< $msg->pipeline_config($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::IngestPipelineConfig>)

Optional. The config for the Cloud Storage Ingestion with DocAI Processors
pipeline. It provides additional customization options to run the pipeline
and can be skipped if it is not applicable.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline

The configuration of exporting documents from the Document Warehouse to CDW
pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<String>

The list of all the resource names of the documents to be processed.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=item * C<< $msg->export_folder_path() >> / C<< $msg->export_folder_path($value) >>

Type: C<String>

The Cloud Storage folder path used to store the exported documents before
being sent to CDW.
Format: `gs://<bucket-name>/<folder-name>`.

=item * C<< $msg->doc_ai_dataset() >> / C<< $msg->doc_ai_dataset($value) >>

Type: C<String>

Optional. The CDW dataset resource name. This field is optional. If not
set, the documents will be exported to Cloud Storage only. Format:
projects/{project}/locations/{location}/processors/{processor}/dataset

=item * C<< $msg->training_split_ratio() >> / C<< $msg->training_split_ratio($value) >>

Type: C<Float>

Ratio of training dataset split. When importing into Document AI Workbench,
documents will be automatically split into training and test split category
with the specified ratio. This field is required if doc_ai_dataset is set.

=back

=head2 Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline

The configuration of processing documents in Document Warehouse with DocAi
processors pipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->documents() >> / C<< $msg->documents($value) >>

Type: C<String>

The list of all the resource names of the documents to be processed.
Format:
projects/{project_number}/locations/{location}/documents/{document_id}.

=item * C<< $msg->export_folder_path() >> / C<< $msg->export_folder_path($value) >>

Type: C<String>

The Cloud Storage folder path used to store the exported documents before
being sent to CDW.
Format: `gs://<bucket-name>/<folder-name>`.

=item * C<< $msg->processor_info() >> / C<< $msg->processor_info($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessorInfo>)

The CDW processor information.

=item * C<< $msg->processor_results_folder_path() >> / C<< $msg->processor_results_folder_path($value) >>

Type: C<String>

The Cloud Storage folder path used to store the raw results from
processors.
Format: `gs://<bucket-name>/<folder-name>`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::Pipelines::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
