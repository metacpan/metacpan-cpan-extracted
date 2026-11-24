package Google::Cloud::Contentwarehouse::V1::DocumentLinkService;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Common };
    eval { require Google::Cloud::Contentwarehouse::V1::Document };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9saW5rX3NlcnZp
Y2UucHJvdG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxotZ29v
Z2xlL2Nsb3VkL2NvbnRlbnR3YXJlaG91c2UvdjEvY29tbW9uLnByb3RvGi9nb29nbGUvY2xv
dWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudC5wcm90bxobZ29vZ2xlL3Byb3RvYnVm
L2VtcHR5LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIpoBChlMaXN0
TGlua2VkVGFyZ2V0c1Jlc3BvbnNlElUKDmRvY3VtZW50X2xpbmtzGAEgAygLMi4uZ29vZ2xl
LmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9jdW1lbnRMaW5rUg1kb2N1bWVudExpbmtz
EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiLCAQoYTGlzdExpbmtl
ZFRhcmdldHNSZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihjb250ZW50d2FyZWhv
dXNlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50UgZwYXJlbnQSXAoQcmVxdWVzdF9tZXRhZGF0
YRgCIAEoCzIxLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlcXVlc3RNZXRh
ZGF0YVIPcmVxdWVzdE1ldGFkYXRhIpoBChlMaXN0TGlua2VkU291cmNlc1Jlc3BvbnNlElUK
DmRvY3VtZW50X2xpbmtzGAEgAygLMi4uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuRG9jdW1lbnRMaW5rUg1kb2N1bWVudExpbmtzEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiL+AQoYTGlzdExpbmtlZFNvdXJjZXNSZXF1ZXN0EkgKBnBhcmVu
dBgBIAEoCUIw4EEC+kEqCihjb250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3Vt
ZW50UgZwYXJlbnQSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2Vu
GAQgASgJUglwYWdlVG9rZW4SXAoQcmVxdWVzdF9tZXRhZGF0YRgCIAEoCzIxLmdvb2dsZS5j
bG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlcXVlc3RNZXRhZGF0YVIPcmVxdWVzdE1ldGFk
YXRhIsUFCgxEb2N1bWVudExpbmsSEgoEbmFtZRgBIAEoCVIEbmFtZRJvChlzb3VyY2VfZG9j
dW1lbnRfcmVmZXJlbmNlGAIgASgLMjMuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuRG9jdW1lbnRSZWZlcmVuY2VSF3NvdXJjZURvY3VtZW50UmVmZXJlbmNlEm8KGXRhcmdl
dF9kb2N1bWVudF9yZWZlcmVuY2UYAyABKAsyMy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVo
b3VzZS52MS5Eb2N1bWVudFJlZmVyZW5jZVIXdGFyZ2V0RG9jdW1lbnRSZWZlcmVuY2USIAoL
ZGVzY3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9uEkAKC3VwZGF0ZV90aW1lGAUgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkAKC2NyZWF0ZV90
aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1l
EkoKBXN0YXRlGAcgASgOMjQuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9j
dW1lbnRMaW5rLlN0YXRlUgVzdGF0ZSI8CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EgoKBkFDVElWRRABEhAKDFNPRlRfREVMRVRFRBACOo4B6kGKAQosY29udGVudHdhcmVob3Vz
ZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudExpbmsSWnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudHMve2RvY3VtZW50fS9kb2N1bWVudExpbmtzL3tk
b2N1bWVudF9saW5rfSKdAgoZQ3JlYXRlRG9jdW1lbnRMaW5rUmVxdWVzdBJICgZwYXJlbnQY
ASABKAlCMOBBAvpBKgooY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVu
dFIGcGFyZW50ElgKDWRvY3VtZW50X2xpbmsYAiABKAsyLi5nb29nbGUuY2xvdWQuY29udGVu
dHdhcmVob3VzZS52MS5Eb2N1bWVudExpbmtCA+BBAlIMZG9jdW1lbnRMaW5rElwKEHJlcXVl
c3RfbWV0YWRhdGEYAyABKAsyMS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5S
ZXF1ZXN0TWV0YWRhdGFSD3JlcXVlc3RNZXRhZGF0YSLDAQoZRGVsZXRlRG9jdW1lbnRMaW5r
UmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4KLGNvbnRlbnR3YXJlaG91c2UuZ29vZ2xl
YXBpcy5jb20vRG9jdW1lbnRMaW5rUgRuYW1lElwKEHJlcXVlc3RfbWV0YWRhdGEYAiABKAsy
MS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SZXF1ZXN0TWV0YWRhdGFSD3Jl
cXVlc3RNZXRhZGF0YTLXBwoTRG9jdW1lbnRMaW5rU2VydmljZRLfAQoRTGlzdExpbmtlZFRh
cmdldHMSOi5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5MaXN0TGlua2VkVGFy
Z2V0c1JlcXVlc3QaOy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5MaXN0TGlu
a2VkVGFyZ2V0c1Jlc3BvbnNlIlGC0+STAkIiPS92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovZG9jdW1lbnRzLyp9L2xpbmtlZFRhcmdldHM6ASraQQZwYXJlbnQS3wEKEUxp
c3RMaW5rZWRTb3VyY2VzEjouZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuTGlz
dExpbmtlZFNvdXJjZXNSZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuTGlzdExpbmtlZFNvdXJjZXNSZXNwb25zZSJRgtPkkwJCIj0vdjEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50cy8qfS9saW5rZWRTb3VyY2VzOgEq2kEGcGFy
ZW50EuIBChJDcmVhdGVEb2N1bWVudExpbmsSOy5nb29nbGUuY2xvdWQuY29udGVudHdhcmVo
b3VzZS52MS5DcmVhdGVEb2N1bWVudExpbmtSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjEuRG9jdW1lbnRMaW5rIl+C0+STAkIiPS92MS97cGFyZW50PXByb2pl
Y3RzLyovbG9jYXRpb25zLyovZG9jdW1lbnRzLyp9L2RvY3VtZW50TGlua3M6ASraQRRwYXJl
bnQsZG9jdW1lbnRfbGluaxLBAQoSRGVsZXRlRG9jdW1lbnRMaW5rEjsuZ29vZ2xlLmNsb3Vk
LmNvbnRlbnR3YXJlaG91c2UudjEuRGVsZXRlRG9jdW1lbnRMaW5rUmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSJWgtPkkwJJIkQvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9kb2N1bWVudHMvKi9kb2N1bWVudExpbmtzLyp9OmRlbGV0ZToBKtpBBG5hbWUaU8pB
H2NvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQoACCiRjb20uZ29vZ2xlLmNsb3VkLmNvbnRl
bnR3YXJlaG91c2UudjFCGERvY3VtZW50TGlua1NlcnZpY2VQcm90b1ABWlBjbG91ZC5nb29n
bGUuY29tL2dvL2NvbnRlbnR3YXJlaG91c2UvYXBpdjEvY29udGVudHdhcmVob3VzZXBiO2Nv
bnRlbnR3YXJlaG91c2VwYqoCIEdvb2dsZS5DbG91ZC5Db250ZW50V2FyZWhvdXNlLlYxygIg
R29vZ2xlXENsb3VkXENvbnRlbnRXYXJlaG91c2VcVjHqAiNHb29nbGU6OkNsb3VkOjpDb250
ZW50V2FyZWhvdXNlOjpWMUr6NwoHEgUOAOwBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKQoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJ
CgIDAxIDFQAjCgkKAgMEEgMWADcKCQoCAwUSAxcAOQoJCgIDBhIDGAAlCgkKAgMHEgMZACkK
CAoBCBIDGwA9CgkKAgglEgMbAD0KCAoBCBIDHABnCgkKAggLEgMcAGcKCAoBCBIDHQAiCgkK
AggKEgMdACIKCAoBCBIDHgA5CgkKAggIEgMeADkKCAoBCBIDHwA9CgkKAggBEgMfAD0KCAoB
CBIDIAA9CgkKAggpEgMgAD0KCAoBCBIDIQA8CgkKAggtEgMhADwKfwoCBgASBCUAUAEacyBU
aGlzIHNlcnZpY2UgbGV0cyB5b3UgbWFuYWdlIGRvY3VtZW50LWxpbmtzLgogRG9jdW1lbnQt
TGlua3MgYXJlIHRyZWF0ZWQgYXMgc3ViLXJlc291cmNlcyB1bmRlciBzb3VyY2UgZG9jdW1l
bnRzLgoKCgoDBgABEgMlCBsKCgoDBgADEgMmAkcKDAoFBgADmQgSAyYCRwoLCgMGAAMSBCcC
KDcKDQoFBgADmggSBCcCKDcKQwoEBgACABIEKwIyAxo1IFJldHVybiBhbGwgdGFyZ2V0IGRv
Y3VtZW50LWxpbmtzIGZyb20gdGhlIGRvY3VtZW50LgoKDAoFBgACAAESAysGFwoMCgUGAAIA
AhIDKxgwCgwKBQYAAgADEgMsDygKDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAG
CgwKBQYAAgAEEgMxBDQKDwoIBgACAASbCAASAzEENApDCgQGAAIBEgQ1AjwDGjUgUmV0dXJu
IGFsbCBzb3VyY2UgZG9jdW1lbnQtbGlua3MgZnJvbSB0aGUgZG9jdW1lbnQuCgoMCgUGAAIB
ARIDNQYXCgwKBQYAAgECEgM1GDAKDAoFBgACAQMSAzYPKAoNCgUGAAIBBBIENwQ6BgoRCgkG
AAIBBLDKvCISBDcEOgYKDAoFBgACAQQSAzsENAoPCggGAAIBBJsIABIDOwQ0Ck4KBAYAAgIS
BD8CRQMaQCBDcmVhdGUgYSBsaW5rIGJldHdlZW4gYSBzb3VyY2UgZG9jdW1lbnQgYW5kIGEg
dGFyZ2V0IGRvY3VtZW50LgoKDAoFBgACAgESAz8GGAoMCgUGAAICAhIDPxkyCgwKBQYAAgID
EgM/PUkKDQoFBgACAgQSBEAEQwYKEQoJBgACAgSwyrwiEgRABEMGCgwKBQYAAgIEEgNEBEIK
DwoIBgACAgSbCAASA0QEQgpICgQGAAIDEgRIAk8DGjogUmVtb3ZlIHRoZSBsaW5rIGJldHdl
ZW4gdGhlIHNvdXJjZSBhbmQgdGFyZ2V0IGRvY3VtZW50cy4KCgwKBQYAAgMBEgNIBhgKDAoF
BgACAwISA0gZMgoMCgUGAAIDAxIDSQ8kCg0KBQYAAgMEEgRKBE0GChEKCQYAAgMEsMq8IhIE
SgRNBgoMCgUGAAIDBBIDTgQyCg8KCAYAAgMEmwgAEgNOBDIKSQoCBAASBFMAWgEaPSBSZXNw
b25zZSBtZXNzYWdlIGZvciBEb2N1bWVudExpbmtTZXJ2aWNlLkxpc3RMaW5rZWRUYXJnZXRz
LgoKCgoDBAABEgNTCCEKJQoEBAACABIDVQIrGhggVGFyZ2V0IGRvY3VtZW50LWxpbmtzLgoK
DAoFBAACAAQSA1UCCgoMCgUEAAIABhIDVQsXCgwKBQQAAgABEgNVGCYKDAoFBAACAAMSA1Up
KgqPAQoEBAACARIDWQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdl
X3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBmaWVsZCBpcyBv
bWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCgwKBQQAAgEFEgNZAggK
DAoFBAACAQESA1kJGAoMCgUEAAIBAxIDWRscCkgKAgQBEgRdAGsBGjwgUmVxdWVzdCBtZXNz
YWdlIGZvciBEb2N1bWVudExpbmtTZXJ2aWNlLkxpc3RMaW5rZWRUYXJnZXRzLgoKCgoDBAEB
EgNdCCAKtgEKBAQBAgASBGECZgQapwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBkb2N1
bWVudCwgZm9yIHdoaWNoIGFsbCB0YXJnZXQgbGlua3MgYXJlCiByZXR1cm5lZC4gRm9ybWF0
OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1
bWVudHMve3RhcmdldF9kb2N1bWVudF9pZH0uCgoMCgUEAQIABRIDYQIICgwKBQQBAgABEgNh
CQ8KDAoFBAECAAMSA2ESEwoNCgUEAQIACBIEYRRmAwoPCggEAQIACJwIABIDYgQqCg8KBwQB
AgAInwgSBGMEZQUKegoEBAECARIDagInGm0gVGhlIG1ldGEgaW5mb3JtYXRpb24gY29sbGVj
dGVkIGFib3V0IHRoZSBkb2N1bWVudCBjcmVhdG9yLCB1c2VkIHRvIGVuZm9yY2UKIGFjY2Vz
cyBjb250cm9sIGZvciB0aGUgc2VydmljZS4KCgwKBQQBAgEGEgNqAhEKDAoFBAECAQESA2oS
IgoMCgUEAQIBAxIDaiUmCkkKAgQCEgRuAHUBGj0gUmVzcG9uc2UgbWVzc2FnZSBmb3IgRG9j
dW1lbnRMaW5rU2VydmljZS5MaXN0TGlua2VkU291cmNlcy4KCgoKAwQCARIDbgghCiUKBAQC
AgASA3ACKxoYIFNvdXJjZSBkb2N1bWVudC1saW5rcy4KCgwKBQQCAgAEEgNwAgoKDAoFBAIC
AAYSA3ALFwoMCgUEAgIAARIDcBgmCgwKBQQCAgADEgNwKSoKjwEKBAQCAgESA3QCHRqBASBB
IHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUg
dGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5v
IHN1YnNlcXVlbnQgcGFnZXMuCgoMCgUEAgIBBRIDdAIICgwKBQQCAgEBEgN0CRgKDAoFBAIC
AQMSA3QbHApKCgIEAxIFeACUAQEaPSBSZXNwb25zZSBtZXNzYWdlIGZvciBEb2N1bWVudExp
bmtTZXJ2aWNlLkxpc3RMaW5rZWRTb3VyY2VzLgoKCgoDBAMBEgN4CCAKtwEKBAQDAgASBXwC
gQEEGqcBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgZG9jdW1lbnQsIGZvciB3aGljaCBh
bGwgc291cmNlIGxpbmtzIGFyZQogcmV0dXJuZWQuIEZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRzL3tzb3VyY2VfZG9j
dW1lbnRfaWR9LgoKDAoFBAMCAAUSA3wCCAoMCgUEAwIAARIDfAkPCgwKBQQDAgADEgN8EhMK
DgoFBAMCAAgSBXwUgQEDCg8KCAQDAgAInAgAEgN9BCoKEAoHBAMCAAifCBIFfgSAAQUK9AEK
BAQDAgESBIgBAhYa5QEgVGhlIG1heGltdW0gbnVtYmVyIG9mIGRvY3VtZW50LWxpbmtzIHRv
IHJldHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVl
LgoKIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIGRvY3VtZW50LWxpbmtzIHdpbGwgYmUg
cmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAxMDAwOyB2YWx1ZXMgYWJvdmUgMTAw
MCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCg0KBQQDAgEFEgSIAQIHCg0KBQQDAgEBEgSI
AQgRCg0KBQQDAgEDEgSIARQVCvsBCgQEAwICEgSPAQIYGuwBIEEgcGFnZSB0b2tlbiwgcmVj
ZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0TGlua2VkU291cmNlc2AgY2FsbC4KIFByb3Zp
ZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdlLgoKIFdoZW4gcGFnaW5h
dGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8gYExpc3RMaW5rZWRTb3Vy
Y2VzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdlIHRva2Vu
LgoKDQoFBAMCAgUSBI8BAggKDQoFBAMCAgESBI8BCRMKDQoFBAMCAgMSBI8BFhcKewoEBAMC
AxIEkwECJxptIFRoZSBtZXRhIGluZm9ybWF0aW9uIGNvbGxlY3RlZCBhYm91dCB0aGUgZG9j
dW1lbnQgY3JlYXRvciwgdXNlZCB0byBlbmZvcmNlCiBhY2Nlc3MgY29udHJvbCBmb3IgdGhl
IHNlcnZpY2UuCgoNCgUEAwIDBhIEkwECEQoNCgUEAwIDARIEkwESIgoNCgUEAwIDAxIEkwEl
JgpDCgIEBBIGlwEAxQEBGjUgQSBkb2N1bWVudC1saW5rIGJldHdlZW4gc291cmNlIGFuZCB0
YXJnZXQgZG9jdW1lbnQuCgoLCgMEBAESBJcBCBQKDQoDBAQHEgaYAQKbAQQKDwoFBAQHnQgS
BpgBApsBBAovCgQEBAQAEgaeAQKnAQMaHyBUaGUgc3RhdGUgb2YgYSBkb2N1bWVudC1saW5r
LgoKDQoFBAQEAAESBJ4BBwwKMAoGBAQEAAIAEgSgAQQaGiAgVW5rbm93biBzdGF0ZSBvZiBk
b2N1bWVudGxpbmsuCgoPCgcEBAQAAgABEgSgAQQVCg8KBwQEBAACAAISBKABGBkKUQoGBAQE
AAIBEgSjAQQPGkEgVGhlIGRvY3VtZW50bGluayBoYXMgYm90aCBzb3VyY2UgYW5kIHRhcmdl
dCBkb2N1bWVudHMgZGV0ZWN0ZWQuCgoPCgcEBAQAAgEBEgSjAQQKCg8KBwQEBAACAQISBKMB
DQ4KWAoGBAQEAAICEgSmAQQVGkggVGFyZ2V0IGRvY3VtZW50IGlzIGRlbGV0ZWQsIGFuZCBt
YXJrIHRoZSBkb2N1bWVudGxpbmsgYXMgc29mdC1kZWxldGVkLgoKDwoHBAQEAAICARIEpgEE
EAoPCgcEBAQAAgICEgSmARMUCrkCCgQEBAIAEgSuAQISGqoCIE5hbWUgb2YgdGhpcyBkb2N1
bWVudC1saW5rLgogSXQgaXMgcmVxdWlyZWQgdGhhdCB0aGUgcGFyZW50IGRlcml2ZWQgZm9y
bSB0aGUgbmFtZSB0byBiZSBjb25zaXN0ZW50IHdpdGgKIHRoZSBzb3VyY2UgZG9jdW1lbnQg
cmVmZXJlbmNlLiBPdGhlcndpc2UgYW4gZXhjZXB0aW9uIHdpbGwgYmUgdGhyb3duLgogRm9y
bWF0OgogcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9k
b2N1bWVudHMve3NvdXJjZV9kb2N1bWVudF9pZH0vZG9jdW1lbnRMaW5rcy97ZG9jdW1lbnRf
bGlua19pZH0uCgoNCgUEBAIABRIErgECCAoNCgUEBAIAARIErgEJDQoNCgUEBAIAAxIErgEQ
EQo7CgQEBAIBEgSxAQIyGi0gRG9jdW1lbnQgcmVmZXJlbmNlcyBvZiB0aGUgc291cmNlIGRv
Y3VtZW50LgoKDQoFBAQCAQYSBLEBAhMKDQoFBAQCAQESBLEBFC0KDQoFBAQCAQMSBLEBMDEK
OwoEBAQCAhIEtAECMhotIERvY3VtZW50IHJlZmVyZW5jZXMgb2YgdGhlIHRhcmdldCBkb2N1
bWVudC4KCg0KBQQEAgIGEgS0AQITCg0KBQQEAgIBEgS0ARQtCg0KBQQEAgIDEgS0ATAxCjIK
BAQEAgMSBLcBAhkaJCBEZXNjcmlwdGlvbiBvZiB0aGlzIGRvY3VtZW50LWxpbmsuCgoNCgUE
BAIDBRIEtwECCAoNCgUEBAIDARIEtwEJFAoNCgUEBAIDAxIEtwEXGApOCgQEBAIEEga6AQK7
ATIaPiBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgZG9jdW1lbnRMaW5rIGlzIGxh
c3QgdXBkYXRlZC4KCg0KBQQEAgQGEgS6AQIbCg0KBQQEAgQBEgS6ARwnCg0KBQQEAgQDEgS6
ASorCg0KBQQEAgQIEgS7AQYxChAKCAQEAgQInAgAEgS7AQcwCkkKBAQEAgUSBr4BAr8BMho5
IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBkb2N1bWVudExpbmsgaXMgY3JlYXRl
ZC4KCg0KBQQEAgUGEgS+AQIbCg0KBQQEAgUBEgS+ARwnCg0KBQQEAgUDEgS+ASorCg0KBQQE
AgUIEgS/AQYxChAKCAQEAgUInAgAEgS/AQcwCrgBCgQEBAIGEgTEAQISGqkBIFRoZSBzdGF0
ZSBvZiB0aGUgZG9jdW1lbnRsaW5rLiBJZiB0YXJnZXQgbm9kZSBoYXMgYmVlbiBkZWxldGVk
LCB0aGUKIGxpbmsgaXMgbWFya2VkIGFzIGludmFsaWQuIFJlbW92aW5nIGEgc291cmNlIG5v
ZGUgd2lsbCByZXN1bHQgaW4gcmVtb3ZhbAogb2YgYWxsIGFzc29jaWF0ZWQgbGlua3MuCgoN
CgUEBAIGBhIExAECBwoNCgUEBAIGARIExAEIDQoNCgUEBAIGAxIExAEQEQpLCgIEBRIGyAEA
2wEBGj0gUmVxdWVzdCBtZXNzYWdlIGZvciBEb2N1bWVudExpbmtTZXJ2aWNlLkNyZWF0ZURv
Y3VtZW50TGluay4KCgsKAwQFARIEyAEIIQrPAQoEBAUCABIGzQEC0gEEGr4BIFJlcXVpcmVk
LiBQYXJlbnQgb2YgdGhlIGRvY3VtZW50LWxpbmsgdG8gYmUgY3JlYXRlZC4KIHBhcmVudCBv
ZiBkb2N1bWVudC1saW5rIHNob3VsZCBiZSBhIGRvY3VtZW50LgogRm9ybWF0OgogcHJvamVj
dHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kb2N1bWVudHMve3Nv
dXJjZV9kb2N1bWVudF9pZH0uCgoNCgUEBQIABRIEzQECCAoNCgUEBQIAARIEzQEJDwoNCgUE
BQIAAxIEzQESEwoPCgUEBQIACBIGzQEU0gEDChAKCAQFAgAInAgAEgTOAQQqChEKBwQFAgAI
nwgSBs8BBNEBBQpkCgQEBQIBEgTWAQJKGlYgUmVxdWlyZWQuIERvY3VtZW50IGxpbmtzIGFz
c29jaWF0ZWQgd2l0aCB0aGUgc291cmNlIGRvY3VtZW50cwogKHNvdXJjZV9kb2N1bWVudF9p
ZCkuCgoNCgUEBQIBBhIE1gECDgoNCgUEBQIBARIE1gEPHAoNCgUEBQIBAxIE1gEfIAoNCgUE
BQIBCBIE1gEhSQoQCggEBQIBCJwIABIE1gEiSAp7CgQEBQICEgTaAQInGm0gVGhlIG1ldGEg
aW5mb3JtYXRpb24gY29sbGVjdGVkIGFib3V0IHRoZSBkb2N1bWVudCBjcmVhdG9yLCB1c2Vk
IHRvIGVuZm9yY2UKIGFjY2VzcyBjb250cm9sIGZvciB0aGUgc2VydmljZS4KCg0KBQQFAgIG
EgTaAQIRCg0KBQQFAgIBEgTaARIiCg0KBQQFAgIDEgTaASUmCksKAgQGEgbeAQDsAQEaPSBS
ZXF1ZXN0IG1lc3NhZ2UgZm9yIERvY3VtZW50TGlua1NlcnZpY2UuRGVsZXRlRG9jdW1lbnRM
aW5rLgoKCwoDBAYBEgTeAQghCsMBCgQEBgIAEgbiAQLnAQQasgEgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBkb2N1bWVudC1saW5rIHRvIGJlIGRlbGV0ZWQuCiBGb3JtYXQ6CiBwcm9q
ZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2RvY3VtZW50cy97
c291cmNlX2RvY3VtZW50X2lkfS9kb2N1bWVudExpbmtzL3tkb2N1bWVudF9saW5rX2lkfS4K
Cg0KBQQGAgAFEgTiAQIICg0KBQQGAgABEgTiAQkNCg0KBQQGAgADEgTiARARCg8KBQQGAgAI
EgbiARLnAQMKEAoIBAYCAAicCAASBOMBBCoKEQoHBAYCAAifCBIG5AEE5gEFCnsKBAQGAgES
BOsBAicabSBUaGUgbWV0YSBpbmZvcm1hdGlvbiBjb2xsZWN0ZWQgYWJvdXQgdGhlIGRvY3Vt
ZW50IGNyZWF0b3IsIHVzZWQgdG8gZW5mb3JjZQogYWNjZXNzIGNvbnRyb2wgZm9yIHRoZSBz
ZXJ2aWNlLgoKDQoFBAYCAQYSBOsBAhEKDQoFBAYCAQESBOsBEiIKDQoFBAYCAQMSBOsBJSZi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse ===
    # Fields for ListLinkedTargetsResponse
    # Field: document_links Type: 11 (.google.cloud.contentwarehouse.v1.DocumentLink)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest ===
    # Fields for ListLinkedTargetsRequest
    # Field: parent Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse ===
    # Fields for ListLinkedSourcesResponse
    # Field: document_links Type: 11 (.google.cloud.contentwarehouse.v1.DocumentLink)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest ===
    # Fields for ListLinkedSourcesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink ===
    # Fields for DocumentLink
    # Field: name Type: 9 ()
    # Field: source_document_reference Type: 11 (.google.cloud.contentwarehouse.v1.DocumentReference)
    # Field: target_document_reference Type: 11 (.google.cloud.contentwarehouse.v1.DocumentReference)
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.contentwarehouse.v1.DocumentLink.State)

# Enum: DocumentLink::State
our $DocumentLink_STATE_UNSPECIFIED = 0;
our $DocumentLink_ACTIVE = 1;
our $DocumentLink_SOFT_DELETED = 2;

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest ===
    # Fields for CreateDocumentLinkRequest
    # Field: parent Type: 9 ()
    # Field: document_link Type: 11 (.google.cloud.contentwarehouse.v1.DocumentLink)
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest ===
    # Fields for DeleteDocumentLinkRequest
    # Field: name Type: 9 ()
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Service Client: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLinkServiceClient ===
package Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLinkServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLinkServiceClient

Client stub representing the remote C<DocumentLinkService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<contentwarehouse.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'contentwarehouse.googleapis.com:443' );

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

sub list_linked_targets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentLinkService',
        method         => 'ListLinkedTargets',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse',
    });
}

sub list_linked_sources {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentLinkService',
        method         => 'ListLinkedSources',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse',
    });
}

sub create_document_link {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentLinkService',
        method         => 'CreateDocumentLink',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink',
    });
}

sub delete_document_link {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentLinkService',
        method         => 'DeleteDocumentLink',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentLinkService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document_link_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentLinkService;

    my $msg = Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse->new({
        document_links => $document_links,
        next_page_token => $next_page_token,
    });

    # Read or update a field
    my $val = $msg->document_links();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document_link_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse

Response message for DocumentLinkService.ListLinkedTargets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_links() >> / C<< $msg->document_links($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink>)

Target document-links.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest

Request message for DocumentLinkService.ListLinkedTargets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the document, for which all target links are
returned. Format:
projects/{project_number}/locations/{location}/documents/{target_document_id}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the document creator, used to enforce
access control for the service.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse

Response message for DocumentLinkService.ListLinkedSources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_links() >> / C<< $msg->document_links($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink>)

Source document-links.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest

Response message for DocumentLinkService.ListLinkedSources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the document, for which all source links are
returned. Format:
projects/{project_number}/locations/{location}/documents/{source_document_id}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of document-links to return. The service may return
fewer than this value.

If unspecified, at most 50 document-links will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListLinkedSources` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListLinkedSources`
must match the call that provided the page token.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the document creator, used to enforce
access control for the service.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink

A document-link between source and target document.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of this document-link.
It is required that the parent derived form the name to be consistent with
the source document reference. Otherwise an exception will be thrown.
Format:
projects/{project_number}/locations/{location}/documents/{source_document_id}/documentLinks/{document_link_id}.

=item * C<< $msg->source_document_reference() >> / C<< $msg->source_document_reference($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::DocumentReference>)

Document references of the source document.

=item * C<< $msg->target_document_reference() >> / C<< $msg->target_document_reference($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Document::DocumentReference>)

Document references of the target document.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of this document-link.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the documentLink is last updated.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the documentLink is created.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Contentwarehouse::V1::DocumentLink::State>)

The state of the documentlink. If target node has been deleted, the
link is marked as invalid. Removing a source node will result in removal
of all associated links.

=back

=head3 Enum: DocumentLink::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<SOFT_DELETED> => C<2>

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest

Request message for DocumentLinkService.CreateDocumentLink.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent of the document-link to be created.
parent of document-link should be a document.
Format:
projects/{project_number}/locations/{location}/documents/{source_document_id}.

=item * C<< $msg->document_link() >> / C<< $msg->document_link($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink>)

Required. Document links associated with the source documents
(source_document_id).

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the document creator, used to enforce
access control for the service.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest

Request message for DocumentLinkService.DeleteDocumentLink.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document-link to be deleted.
Format:
projects/{project_number}/locations/{location}/documents/{source_document_id}/documentLinks/{document_link_id}.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the document creator, used to enforce
access control for the service.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::DocumentLinkService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
