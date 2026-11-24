package Google::Cloud::Discoveryengine::V1::UserLicenseService;

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
    eval { require Google::Cloud::Discoveryengine::V1::UserLicense };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL3VzZXJfbGljZW5zZV9zZXJ2aWNl
LnByb3RvEh9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxGhxnb29nbGUvYXBpL2Fu
bm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoyZ29vZ2xl
L2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MS91c2VyX2xpY2Vuc2UucHJvdG8aI2dvb2dsZS9s
b25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFz
ay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29vZ2xlL3JwYy9z
dGF0dXMucHJvdG8i5gEKF0xpc3RVc2VyTGljZW5zZXNSZXF1ZXN0EkgKBnBhcmVudBgBIAEo
CUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vVXNlclN0b3JlUgZw
YXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4Y
AyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXISHgoI
b3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKVAQoYTGlzdFVzZXJMaWNlbnNlc1Jlc3Bv
bnNlElEKDXVzZXJfbGljZW5zZXMYASADKAsyLC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLlVzZXJMaWNlbnNlUgx1c2VyTGljZW5zZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIg
ASgJUg1uZXh0UGFnZVRva2VuIm8KI0xpc3RMaWNlbnNlQ29uZmlnc1VzYWdlU3RhdHNSZXF1
ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vVXNlclN0b3JlUgZwYXJlbnQinQEKJExpc3RMaWNlbnNlQ29uZmlnc1VzYWdlU3Rh
dHNSZXNwb25zZRJ1ChpsaWNlbnNlX2NvbmZpZ191c2FnZV9zdGF0cxgBIAMoCzI4Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ1VzYWdlU3RhdHNSF2xp
Y2Vuc2VDb25maWdVc2FnZVN0YXRzIuADCh5CYXRjaFVwZGF0ZVVzZXJMaWNlbnNlc1JlcXVl
c3QScwoNaW5saW5lX3NvdXJjZRgCIAEoCzJMLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNSZXF1ZXN0LklubGluZVNvdXJjZUgAUgxp
bmxpbmVTb3VyY2USSAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5n
b29nbGVhcGlzLmNvbS9Vc2VyU3RvcmVSBnBhcmVudBJKCh9kZWxldGVfdW5hc3NpZ25lZF91
c2VyX2xpY2Vuc2VzGAQgASgIQgPgQQFSHGRlbGV0ZVVuYXNzaWduZWRVc2VyTGljZW5zZXMa
qAEKDElubGluZVNvdXJjZRJWCg11c2VyX2xpY2Vuc2VzGAEgAygLMiwuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5zZUID4EECUgx1c2VyTGljZW5zZXMSQAoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQFSCnVw
ZGF0ZU1hc2tCCAoGc291cmNlIuUBCh9CYXRjaFVwZGF0ZVVzZXJMaWNlbnNlc01ldGFkYXRh
EjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3Jl
YXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3Rh
bXBSCnVwZGF0ZVRpbWUSIwoNc3VjY2Vzc19jb3VudBgDIAEoA1IMc3VjY2Vzc0NvdW50EiMK
DWZhaWx1cmVfY291bnQYBCABKANSDGZhaWx1cmVDb3VudCKtAQofQmF0Y2hVcGRhdGVVc2Vy
TGljZW5zZXNSZXNwb25zZRJRCg11c2VyX2xpY2Vuc2VzGAEgAygLMiwuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5zZVIMdXNlckxpY2Vuc2VzEjcKDWVycm9y
X3NhbXBsZXMYAiADKAsyEi5nb29nbGUucnBjLlN0YXR1c1IMZXJyb3JTYW1wbGVzMqIIChJV
c2VyTGljZW5zZVNlcnZpY2US1wEKEExpc3RVc2VyTGljZW5zZXMSOC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RVc2VyTGljZW5zZXNSZXF1ZXN0GjkuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0VXNlckxpY2Vuc2VzUmVzcG9uc2UiToLT5JMC
PxI9L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi91c2VyU3RvcmVzLyp9L3Vz
ZXJMaWNlbnNlc9pBBnBhcmVudBKHAgocTGlzdExpY2Vuc2VDb25maWdzVXNhZ2VTdGF0cxJE
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdExpY2Vuc2VDb25maWdzVXNh
Z2VTdGF0c1JlcXVlc3QaRS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RM
aWNlbnNlQ29uZmlnc1VzYWdlU3RhdHNSZXNwb25zZSJagtPkkwJLEkkvdjEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL3VzZXJTdG9yZXMvKn0vbGljZW5zZUNvbmZpZ3NVc2Fn
ZVN0YXRz2kEGcGFyZW50EtUCChdCYXRjaFVwZGF0ZVVzZXJMaWNlbnNlcxI/Lmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNSZXF1ZXN0
Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLZAYLT5JMCTSJIL3YxL3twYXJlbnQ9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi91c2VyU3RvcmVzLyp9OmJhdGNoVXBkYXRlVXNlckxp
Y2Vuc2VzOgEqykGCAQo/Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5CYXRjaFVw
ZGF0ZVVzZXJMaWNlbnNlc1Jlc3BvbnNlEj9nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLkJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzTWV0YWRhdGEazwHKQR5kaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVy
eWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNj
b3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCigIKI2NvbS5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxQhdVc2VyTGljZW5zZVNlcnZpY2VQcm90b1ABWk1jbG91ZC5nb29n
bGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNj
b3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2dsZS5DbG91ZC5EaXNjb3Zl
cnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx6gIiR29vZ2xl
OjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUrDPwoHEgUOAPkBAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADwKCQoCAwUSAxcALQoJCgIDBhIDGAAq
CgkKAgMHEgMZACkKCQoCAwgSAxoAIQoICgEIEgMcADwKCQoCCCUSAxwAPAoICgEIEgMdAGQK
CQoCCAsSAx0AZAoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfADgKCQoCCAgSAx8AOAoI
CgEIEgMgADwKCQoCCAESAyAAPAoICgEIEgMhAC0KCQoCCCQSAyEALQoICgEIEgMiADwKCQoC
CCkSAyIAPAoICgEIEgMjADsKCQoCCC0SAyMAOwoxCgIGABIEJgBOARolIFNlcnZpY2UgZm9y
IG1hbmFnaW5nIFVzZXIgTGljZW5zZXMuCgoKCgMGAAESAyYIGgoKCgMGAAMSAycCRgoMCgUG
AAOZCBIDJwJGCgsKAwYAAxIEKAIrSgoNCgUGAAOaCBIEKAIrSgooCgQGAAIAEgQuAjQDGhog
TGlzdHMgdGhlIFVzZXIgTGljZW5zZXMuCgoMCgUGAAIAARIDLgYWCgwKBQYAAgACEgMuFy4K
DAoFBgACAAMSAy8PJwoNCgUGAAIABBIEMAQyBgoRCgkGAAIABLDKvCISBDAEMgYKDAoFBgAC
AAQSAzMENAoPCggGAAIABJsIABIDMwQ0CpEBCgQGAAIBEgQ5Aj8DGoIBIExpc3RzIGFsbCB0
aGUKIFtMaWNlbnNlQ29uZmlnVXNhZ2VTdGF0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MS5MaWNlbnNlQ29uZmlnVXNhZ2VTdGF0c11zCiBhc3NvY2lhdGVkIHdpdGggdGhl
IHByb2plY3QuCgoMCgUGAAIBARIDOQYiCgwKBQYAAgECEgM5I0YKDAoFBgACAQMSAzoPMwoN
CgUGAAIBBBIEOwQ9BgoRCgkGAAIBBLDKvCISBDsEPQYKDAoFBgACAQQSAz4ENAoPCggGAAIB
BJsIABIDPgQ0CmsKBAYAAgISBEMCTQMaXSBVcGRhdGVzIHRoZSBVc2VyIExpY2Vuc2UuCiBU
aGlzIG1ldGhvZCBpcyB1c2VkIGZvciBiYXRjaCBhc3NpZ24vdW5hc3NpZ24gbGljZW5zZXMg
dG8gdXNlcnMuCgoMCgUGAAICARIDQwYdCgwKBQYAAgICEgNDHjwKDAoFBgACAgMSA0QPKwoN
CgUGAAICBBIERQRIBgoRCgkGAAICBLDKvCISBEUESAYKDQoFBgACAgQSBEkETAYKDwoHBgAC
AgSZCBIESQRMBgqQAQoCBAASBVIAjwEBGoIBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtVc2Vy
TGljZW5zZVNlcnZpY2UuTGlzdFVzZXJMaWNlbnNlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5Vc2VyTGljZW5zZVNlcnZpY2UuTGlzdFVzZXJMaWNlbnNlc10uCgoKCgME
AAESA1IIHwq7AQoEBAACABIEVgJbBBqsASBSZXF1aXJlZC4gVGhlIHBhcmVudCBbVXNlclN0
b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVzZXJTdG9yZV0KIHJlc291
cmNlIG5hbWUsIGZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vdXNlclN0b3Jlcy97dXNlcl9zdG9yZV9pZH1gLgoKDAoFBAACAAUSA1YCCAoMCgUE
AAIAARIDVgkPCgwKBQQAAgADEgNWEhMKDQoFBAACAAgSBFYUWwMKDwoIBAACAAicCAASA1cE
KgoPCgcEAAIACJ8IEgRYBFoFCokCCgQEAAIBEgNiAj8a+wEgT3B0aW9uYWwuIFJlcXVlc3Rl
ZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1zIHRoYW4KIHJlcXVl
c3RlZC4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1bHRzIHRvIDEwMC4gVGhlIG1heGltdW0gdmFs
dWUgaXMgMTAwMDsKIHZhbHVlcyBhYm92ZSAxMDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAw
LgoKIElmIHRoaXMgZmllbGQgaXMgbmVnYXRpdmUsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJy
b3IgaXMgcmV0dXJuZWQuCgoMCgUEAAIBBRIDYgIHCgwKBQQAAgEBEgNiCBEKDAoFBAACAQMS
A2IUFQoMCgUEAAIBCBIDYhY+Cg8KCAQAAgEInAgAEgNiFz0KggIKBAQAAgISA2kCQRr0ASBP
cHRpb25hbC4gQSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RV
c2VyTGljZW5zZXNgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNl
cXVlbnQgcGFnZS4KCiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHBy
b3ZpZGVkIHRvIGBMaXN0VXNlckxpY2Vuc2VzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0
IHByb3ZpZGVkIHRoZSBwYWdlIHRva2VuLgoKDAoFBAACAgUSA2kCCAoMCgUEAAICARIDaQkT
CgwKBQQAAgIDEgNpFhcKDAoFBAACAggSA2kYQAoPCggEAAICCJwIABIDaRk/CugECgQEAAID
EgN8Aj0a2gQgT3B0aW9uYWwuIEZpbHRlciBmb3IgdGhlIGxpc3QgcmVxdWVzdC4KCiBTdXBw
b3J0ZWQgZmllbGRzOgoKICogYGxpY2Vuc2VfYXNzaWdubWVudF9zdGF0ZWAKICogYHVzZXJf
cHJpbmNpcGFsYAogKgogRXhhbXBsZXM6CgogKiBgbGljZW5zZV9hc3NpZ25tZW50X3N0YXRl
ID0gQVNTSUdORURgIHRvIGxpc3QgYXNzaWduZWQgdXNlciBsaWNlbnNlcy4KICogYGxpY2Vu
c2VfYXNzaWdubWVudF9zdGF0ZSA9IE5PX0xJQ0VOU0VgIHRvIGxpc3Qgbm90IGxpY2Vuc2Vk
IHVzZXJzLgogKiBgbGljZW5zZV9hc3NpZ25tZW50X3N0YXRlID0gTk9fTElDRU5TRV9BVFRF
TVBURURfTE9HSU5gIHRvIGxpc3QgdXNlcnMKIHdobyBhdHRlbXB0ZWQgbG9naW4gYnV0IG5v
IGxpY2Vuc2UgYXNzaWduZWQuCiAqIGBsaWNlbnNlX2Fzc2lnbm1lbnRfc3RhdGUgIT0gTk9f
TElDRU5TRV9BVFRFTVBURURfTE9HSU5gIHRvIGZpbHRlcgogb3V0IHVzZXJzIHdobyBhdHRl
bXB0ZWQgbG9naW4gYnV0IG5vIGxpY2Vuc2UgYXNzaWduZWQuCiAqIGB1c2VyX3ByaW5jaXBh
bCA9IHVzZXIxQGV4YW1wbGUuY29tYCB0byBsaXN0IHVzZXIgbGljZW5zZSBmb3IKIGB1c2Vy
MUBleGFtcGxlLmNvbWAuCgoMCgUEAAIDBRIDfAIICgwKBQQAAgMBEgN8CQ8KDAoFBAACAwMS
A3wSEwoMCgUEAAIDCBIDfBQ8Cg8KCAQAAgMInAgAEgN8FTsKgQUKBAQAAgQSBI4BAj8a8gQg
T3B0aW9uYWwuIFRoZSBvcmRlciBpbiB3aGljaCB0aGUKIFtVc2VyTGljZW5zZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5zZV1zIGFyZSBsaXN0ZWQuIFRo
ZQogdmFsdWUgbXVzdCBiZSBhIGNvbW1hLXNlcGFyYXRlZCBsaXN0IG9mIGZpZWxkcy4gRGVm
YXVsdCBzb3J0aW5nIG9yZGVyIGlzCiBhc2NlbmRpbmcuIFRvIHNwZWNpZnkgZGVzY2VuZGlu
ZyBvcmRlciBmb3IgYSBmaWVsZCwgYXBwZW5kIGEgIiBkZXNjIgogc3VmZml4LiBSZWR1bmRh
bnQgc3BhY2UgY2hhcmFjdGVycyBpbiB0aGUgc3ludGF4IGFyZSBpbnNpZ25pZmljYW50LgoK
IFN1cHBvcnRlZCBmaWVsZHMgKG9ubHkgYHVzZXJfcHJpbmNpcGFsYCBpcyBzdXBwb3J0ZWQg
Zm9yIG5vdyk6CgogKiBgdXNlcl9wcmluY2lwYWxgCgogSWYgbm90IHNldCwgdGhlIGRlZmF1
bHQgb3JkZXJpbmcgaXMgYnkgYHVzZXJfcHJpbmNpcGFsYC4KCiBFeGFtcGxlczoKCiAqIGB1
c2VyX3ByaW5jaXBhbGAgdG8gb3JkZXIgYnkgYHVzZXJfcHJpbmNpcGFsYCBpbiBhc2NlbmRp
bmcgb3JkZXIuCiAqIGB1c2VyX3ByaW5jaXBhbCBkZXNjYCB0byBvcmRlciBieSBgdXNlcl9w
cmluY2lwYWxgIGluIGRlc2NlbmRpbmcgb3JkZXIuCgoNCgUEAAIEBRIEjgECCAoNCgUEAAIE
ARIEjgEJEQoNCgUEAAIEAxIEjgEUFQoNCgUEAAIECBIEjgEWPgoQCggEAAIECJwIABIEjgEX
PQqSAQoCBAESBpMBAJsBARqDASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1VzZXJMaWNlbnNl
U2VydmljZS5MaXN0VXNlckxpY2Vuc2VzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxLlVzZXJMaWNlbnNlU2VydmljZS5MaXN0VXNlckxpY2Vuc2VzXS4KCgsKAwQBARIEkwEI
IApgCgQEAQIAEgSWAQIpGlIgQWxsIHRoZSBjdXN0b21lcidzCiBbVXNlckxpY2Vuc2VdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlckxpY2Vuc2Vdcy4KCg0KBQQBAgAE
EgSWAQIKCg0KBQQBAgAGEgSWAQsWCg0KBQQBAgABEgSWARckCg0KBQQBAgADEgSWAScoCpAB
CgQEAQIBEgSaAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rv
a2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLiBJZgogdGhpcyBmaWVsZCBpcyBvbWl0
dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQBAgEFEgSaAQIICg0K
BQQBAgEBEgSaAQkYCg0KBQQBAgEDEgSaARscCrEBCgIEAhIGoAEAqQEBGqIBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtVc2VyTGljZW5zZVNlcnZpY2UuTGlzdExpY2Vuc2VDb25maWdzVXNh
Z2VTdGF0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5zZVNl
cnZpY2UuTGlzdExpY2Vuc2VDb25maWdzVXNhZ2VTdGF0c10KIG1ldGhvZC4KCgsKAwQCARIE
oAEIKwqLAQoEBAICABIGowECqAEEGnsgUmVxdWlyZWQuIFRoZSBwYXJlbnQgYnJhbmNoIHJl
c291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vdXNlclN0b3Jlcy97dXNlcl9zdG9yZV9pZH1gLgoKDQoFBAICAAUSBKMBAggK
DQoFBAICAAESBKMBCQ8KDQoFBAICAAMSBKMBEhMKDwoFBAICAAgSBqMBFKgBAwoQCggEAgIA
CJwIABIEpAEEKgoRCgcEAgIACJ8IEgalAQSnAQUKsgEKAgQDEgauAQCyAQEaowEgUmVzcG9u
c2UgbWVzc2FnZSBmb3IKIFtVc2VyTGljZW5zZVNlcnZpY2UuTGlzdExpY2Vuc2VDb25maWdz
VXNhZ2VTdGF0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5z
ZVNlcnZpY2UuTGlzdExpY2Vuc2VDb25maWdzVXNhZ2VTdGF0c10KIG1ldGhvZC4KCgsKAwQD
ARIErgEILAp3CgQEAwIAEgSxAQJCGmkgQWxsIHRoZSBjdXN0b21lcidzCiBbTGljZW5zZUNv
bmZpZ1VzYWdlU3RhdHNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5z
ZUNvbmZpZ1VzYWdlU3RhdHNdLgoKDQoFBAMCAAQSBLEBAgoKDQoFBAMCAAYSBLEBCyIKDQoF
BAMCAAESBLEBIz0KDQoFBAMCAAMSBLEBQEEKpwEKAgQEEga3AQDbAQEamAEgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW1VzZXJMaWNlbnNlU2VydmljZS5CYXRjaFVwZGF0ZVVzZXJMaWNlbnNl
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5Vc2VyTGljZW5zZVNlcnZpY2Uu
QmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNdCiBtZXRob2QuCgoLCgMEBAESBLcBCCYKXQoEBAQD
ABIGugECxAEDGk0gVGhlIGlubGluZSBzb3VyY2UgZm9yIHRoZSBpbnB1dCBjb25maWcgZm9y
IEJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzCiBtZXRob2QuCgoNCgUEBAMAARIEugEKFgrBAQoG
BAQDAAIAEga+AQS/ATEargEgUmVxdWlyZWQuIEEgbGlzdCBvZiB1c2VyIGxpY2Vuc2VzIHRv
IHVwZGF0ZS4gRWFjaCB1c2VyIGxpY2Vuc2UKIG11c3QgaGF2ZSBhIHZhbGlkCiBbVXNlckxp
Y2Vuc2UudXNlcl9wcmluY2lwYWxdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
VXNlckxpY2Vuc2UudXNlcl9wcmluY2lwYWxdLgoKDwoHBAQDAAIABBIEvgEEDAoPCgcEBAMA
AgAGEgS+AQ0YCg8KBwQEAwACAAESBL4BGSYKDwoHBAQDAAIAAxIEvgEpKgoPCgcEBAMAAgAI
EgS/AQgwChIKCgQEAwACAAicCAASBL8BCS8KOwoGBAQDAAIBEgbCAQTDATEaKSBPcHRpb25h
bC4gVGhlIGxpc3Qgb2YgZmllbGRzIHRvIHVwZGF0ZS4KCg8KBwQEAwACAQYSBMIBBB0KDwoH
BAQDAAIBARIEwgEeKQoPCgcEBAMAAgEDEgTCASwtCg8KBwQEAwACAQgSBMMBCDAKEgoKBAQD
AAIBCJwIABIEwwEJLwo0CgQEBAgAEgbHAQLKAQMaJCBSZXF1aXJlZC4gVGhlIHNvdXJjZSBv
ZiB0aGUgaW5wdXQuCgoNCgUEBAgAARIExwEIDgpPCgQEBAIAEgTJAQQjGkEgVGhlIGlubGlu
ZSBzb3VyY2UgZm9yIHRoZSBpbnB1dCBjb250ZW50IGZvciBsaWNlbnNlIGFzc2lnbm1lbnQu
CgoNCgUEBAIABhIEyQEEEAoNCgUEBAIAARIEyQERHgoNCgUEBAIAAxIEyQEhIgq9AQoEBAQC
ARIGzwEC1AEEGqwBIFJlcXVpcmVkLiBUaGUgcGFyZW50IFtVc2VyU3RvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXNlclN0b3JlXQogcmVzb3VyY2UgbmFtZSwgZm9y
bWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS91c2VyU3Rv
cmVzL3t1c2VyX3N0b3JlX2lkfWAuCgoNCgUEBAIBBRIEzwECCAoNCgUEBAIBARIEzwEJDwoN
CgUEBAIBAxIEzwESEwoPCgUEBAIBCBIGzwEU1AEDChAKCAQEAgEInAgAEgTQAQQqChEKBwQE
AgEInwgSBtEBBNMBBQrOAQoEBAQCAhIG2QEC2gEvGr0BIE9wdGlvbmFsLiBJZiB0cnVlLCBp
ZiB1c2VyIGxpY2Vuc2VzIHJlbW92ZWQgYXNzb2NpYXRlZCBsaWNlbnNlIGNvbmZpZywgdGhl
CiB1c2VyIGxpY2Vuc2Ugd2lsbCBiZSBkZWxldGVkLiBCeSBkZWZhdWx0IHdoaWNoIGlzIGZh
bHNlLCB0aGUgdXNlciBsaWNlbnNlCiB3aWxsIGJlIHVwZGF0ZWQgdG8gdW5hc3NpZ25lZCBz
dGF0ZS4KCg0KBQQEAgIFEgTZAQIGCg0KBQQEAgIBEgTZAQcmCg0KBQQEAgIDEgTZASkqCg0K
BQQEAgIIEgTaAQYuChAKCAQEAgIInAgAEgTaAQctCokCCgIEBRIG4QEA7gEBGvoBIE1ldGFk
YXRhIHJlbGF0ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW1VzZXJMaWNlbnNlU2Vydmlj
ZS5CYXRjaFVwZGF0ZVVzZXJMaWNlbnNlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MS5Vc2VyTGljZW5zZVNlcnZpY2UuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNdCiBvcGVy
YXRpb24uIFRoaXMgd2lsbCBiZSByZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbi5tZXRhZGF0YQogZmllbGQuCgoLCgMEBQESBOEBCCcKJgoEBAUCABIE4wEC
LBoYIE9wZXJhdGlvbiBjcmVhdGUgdGltZS4KCg0KBQQFAgAGEgTjAQIbCg0KBQQFAgABEgTj
ARwnCg0KBQQFAgADEgTjASorCmQKBAQFAgESBOcBAiwaViBPcGVyYXRpb24gbGFzdCB1cGRh
dGUgdGltZS4gSWYgdGhlIG9wZXJhdGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBm
aW5pc2ggdGltZS4KCg0KBQQFAgEGEgTnAQIbCg0KBQQFAgEBEgTnARwnCg0KBQQFAgEDEgTn
ASorCjwKBAQFAgISBOoBAhoaLiBDb3VudCBvZiB1c2VyIGxpY2Vuc2VzIHN1Y2Nlc3NmdWxs
eSB1cGRhdGVkLgoKDQoFBAUCAgUSBOoBAgcKDQoFBAUCAgESBOoBCBUKDQoFBAUCAgMSBOoB
GBkKQQoEBAUCAxIE7QECGhozIENvdW50IG9mIHVzZXIgbGljZW5zZXMgdGhhdCBmYWlsZWQg
dG8gYmUgdXBkYXRlZC4KCg0KBQQFAgMFEgTtAQIHCg0KBQQFAgMBEgTtAQgVCg0KBQQFAgMD
EgTtARgZCqgBCgIEBhIG8wEA+QEBGpkBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbVXNlckxp
Y2Vuc2VTZXJ2aWNlLkJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLlVzZXJMaWNlbnNlU2VydmljZS5CYXRjaFVwZGF0ZVVzZXJMaWNl
bnNlc10KIG1ldGhvZC4KCgsKAwQGARIE8wEIJwoyCgQEBgIAEgT1AQIpGiQgVXNlckxpY2Vu
c2VzIHN1Y2Nlc3NmdWxseSB1cGRhdGVkLgoKDQoFBAYCAAQSBPUBAgoKDQoFBAYCAAYSBPUB
CxYKDQoFBAYCAAESBPUBFyQKDQoFBAYCAAMSBPUBJygKTAoEBAYCARIE+AECLxo+IEEgc2Ft
cGxlIG9mIGVycm9ycyBlbmNvdW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRoZSByZXF1ZXN0
LgoKDQoFBAYCAQQSBPgBAgoKDQoFBAYCAQYSBPgBCxwKDQoFBAYCAQESBPgBHSoKDQoFBAYC
AQMSBPgBLS5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest ===
    # Fields for ListUserLicensesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse ===
    # Fields for ListUserLicensesResponse
    # Field: user_licenses Type: 11 (.google.cloud.discoveryengine.v1.UserLicense)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsRequest ===
    # Fields for ListLicenseConfigsUsageStatsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsResponse ===
    # Fields for ListLicenseConfigsUsageStatsResponse
    # Field: license_config_usage_stats Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfigUsageStats)

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesRequest ===
    # Fields for BatchUpdateUserLicensesRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1.BatchUpdateUserLicensesRequest.InlineSource)
    # Field: parent Type: 9 ()
    # Field: delete_unassigned_user_licenses Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesMetadata ===
    # Fields for BatchUpdateUserLicensesMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesResponse ===
    # Fields for BatchUpdateUserLicensesResponse
    # Field: user_licenses Type: 11 (.google.cloud.discoveryengine.v1.UserLicense)
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Service Client: Google::Cloud::Discoveryengine::V1::UserLicenseService::UserLicenseServiceClient ===
package Google::Cloud::Discoveryengine::V1::UserLicenseService::UserLicenseServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::UserLicenseService::UserLicenseServiceClient

Client stub representing the remote C<UserLicenseService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<discoveryengine.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'discoveryengine.googleapis.com:443' );

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

sub list_user_licenses {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserLicenseService',
        method         => 'ListUserLicenses',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse',
    });
}

sub list_license_configs_usage_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserLicenseService',
        method         => 'ListLicenseConfigsUsageStats',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsResponse',
    });
}

sub batch_update_user_licenses {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.UserLicenseService',
        method         => 'BatchUpdateUserLicenses',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserLicenseService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/user_license_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::UserLicenseService;

    my $msg = Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/user_license_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesRequest

Request message for
[UserLicenseService.ListUserLicenses][google.cloud.discoveryengine.v1.UserLicenseService.ListUserLicenses].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent [UserStore][google.cloud.discoveryengine.v1.UserStore]
resource name, format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, defaults to 100. The maximum value is 1000;
values above 1000 will be coerced to 1000.

If this field is negative, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListUserLicenses` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListUserLicenses`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter for the list request.

Supported fields:

* `license_assignment_state`
* `user_principal`
*
Examples:

* `license_assignment_state = ASSIGNED` to list assigned user licenses.
* `license_assignment_state = NO_LICENSE` to list not licensed users.
* `license_assignment_state = NO_LICENSE_ATTEMPTED_LOGIN` to list users
who attempted login but no license assigned.
* `license_assignment_state != NO_LICENSE_ATTEMPTED_LOGIN` to filter
out users who attempted login but no license assigned.
* `user_principal = user1@example.com` to list user license for
`user1@example.com`.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The order in which the
[UserLicense][google.cloud.discoveryengine.v1.UserLicense]s are listed. The
value must be a comma-separated list of fields. Default sorting order is
ascending. To specify descending order for a field, append a " desc"
suffix. Redundant space characters in the syntax are insignificant.

Supported fields (only `user_principal` is supported for now):

* `user_principal`

If not set, the default ordering is by `user_principal`.

Examples:

* `user_principal` to order by `user_principal` in ascending order.
* `user_principal desc` to order by `user_principal` in descending order.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::ListUserLicensesResponse

Response message for
[UserLicenseService.ListUserLicenses][google.cloud.discoveryengine.v1.UserLicenseService.ListUserLicenses].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_licenses() >> / C<< $msg->user_licenses($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense>)

All the customer's
[UserLicense][google.cloud.discoveryengine.v1.UserLicense]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page. If
this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsRequest

Request message for
[UserLicenseService.ListLicenseConfigsUsageStats][google.cloud.discoveryengine.v1.UserLicenseService.ListLicenseConfigsUsageStats]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::ListLicenseConfigsUsageStatsResponse

Response message for
[UserLicenseService.ListLicenseConfigsUsageStats][google.cloud.discoveryengine.v1.UserLicenseService.ListLicenseConfigsUsageStats]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config_usage_stats() >> / C<< $msg->license_config_usage_stats($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserLicense::LicenseConfigUsageStats>)

All the customer's
[LicenseConfigUsageStats][google.cloud.discoveryengine.v1.LicenseConfigUsageStats].

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesRequest

Request message for
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1.UserLicenseService.BatchUpdateUserLicenses]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesRequest::InlineSource>)

The inline source for the input content for license assignment.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent [UserStore][google.cloud.discoveryengine.v1.UserStore]
resource name, format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=item * C<< $msg->delete_unassigned_user_licenses() >> / C<< $msg->delete_unassigned_user_licenses($value) >>

Type: C<Bool>

Optional. If true, if user licenses removed associated license config, the
user license will be deleted. By default which is false, the user license
will be updated to unassigned state.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesMetadata

Metadata related to the progress of the
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1.UserLicenseService.BatchUpdateUserLicenses]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of user licenses successfully updated.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of user licenses that failed to be updated.

=back

=head2 Google::Cloud::Discoveryengine::V1::UserLicenseService::BatchUpdateUserLicensesResponse

Response message for
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1.UserLicenseService.BatchUpdateUserLicenses]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_licenses() >> / C<< $msg->user_licenses($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::UserLicense::UserLicense>)

UserLicenses successfully updated.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::UserLicenseService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
