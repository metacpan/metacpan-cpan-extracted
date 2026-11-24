package Google::Cloud::Visionai::V1::StreamingService;

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
    eval { require Google::Cloud::Visionai::V1::StreamingResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvc3RyZWFtaW5nX3NlcnZpY2UucHJvdG8SGGdv
b2dsZS5jbG91ZC52aXNpb25haS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aMmdvb2dsZS9jbG91ZC92aXNpb25haS92MS9zdHJl
YW1pbmdfcmVzb3VyY2VzLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ipwQKFFJlY2VpdmVFdmVudHNSZXF1
ZXN0EmIKDXNldHVwX3JlcXVlc3QYASABKAsyOy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEu
UmVjZWl2ZUV2ZW50c1JlcXVlc3QuU2V0dXBSZXF1ZXN0SABSDHNldHVwUmVxdWVzdBJQCg5j
b21taXRfcmVxdWVzdBgCIAEoCzInLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5Db21taXRS
ZXF1ZXN0SABSDWNvbW1pdFJlcXVlc3QazQIKDFNldHVwUmVxdWVzdBIYCgdjbHVzdGVyGAEg
ASgJUgdjbHVzdGVyEhYKBnN0cmVhbRgCIAEoCVIGc3RyZWFtEhoKCHJlY2VpdmVyGAMgASgJ
UghyZWNlaXZlchJRCg9jb250cm9sbGVkX21vZGUYBCABKAsyKC5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjEuQ29udHJvbGxlZE1vZGVSDmNvbnRyb2xsZWRNb2RlEkgKEmhlYXJ0YmVhdF9p
bnRlcnZhbBgFIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRaGVhcnRiZWF0SW50
ZXJ2YWwSUgoYd3JpdGVzX2RvbmVfZ3JhY2VfcGVyaW9kGAYgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uUhV3cml0ZXNEb25lR3JhY2VQZXJpb2RCCQoHcmVxdWVzdCKoAQoLRXZl
bnRVcGRhdGUSFgoGc3RyZWFtGAEgASgJUgZzdHJlYW0SFAoFZXZlbnQYAiABKAlSBWV2ZW50
EhYKBnNlcmllcxgDIAEoCVIGc2VyaWVzEjsKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xl
LnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZRIWCgZvZmZzZXQYBSABKANSBm9mZnNl
dCJ7ChxSZWNlaXZlRXZlbnRzQ29udHJvbFJlc3BvbnNlEh4KCWhlYXJ0YmVhdBgBIAEoCEgA
UgloZWFydGJlYXQSMAoTd3JpdGVzX2RvbmVfcmVxdWVzdBgCIAEoCEgAUhF3cml0ZXNEb25l
UmVxdWVzdEIJCgdjb250cm9sIsMBChVSZWNlaXZlRXZlbnRzUmVzcG9uc2USSgoMZXZlbnRf
dXBkYXRlGAEgASgLMiUuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLkV2ZW50VXBkYXRlSABS
C2V2ZW50VXBkYXRlElIKB2NvbnRyb2wYAiABKAsyNi5nb29nbGUuY2xvdWQudmlzaW9uYWku
djEuUmVjZWl2ZUV2ZW50c0NvbnRyb2xSZXNwb25zZUgAUgdjb250cm9sQgoKCHJlc3BvbnNl
IsYBCgVMZWFzZRIOCgJpZBgBIAEoCVICaWQSFgoGc2VyaWVzGAIgASgJUgZzZXJpZXMSFAoF
b3duZXIYAyABKAlSBW93bmVyEjsKC2V4cGlyZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcFIKZXhwaXJlVGltZRJCCgpsZWFzZV90eXBlGAUgASgOMiMuZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxLkxlYXNlVHlwZVIJbGVhc2VUeXBlIrYBChNBY3F1aXJlTGVh
c2VSZXF1ZXN0EhYKBnNlcmllcxgBIAEoCVIGc2VyaWVzEhQKBW93bmVyGAIgASgJUgVvd25l
chItCgR0ZXJtGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgR0ZXJtEkIKCmxl
YXNlX3R5cGUYBCABKA4yIy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuTGVhc2VUeXBlUgls
ZWFzZVR5cGUigAEKEVJlbmV3TGVhc2VSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIWCgZzZXJp
ZXMYAiABKAlSBnNlcmllcxIUCgVvd25lchgDIAEoCVIFb3duZXISLQoEdGVybRgEIAEoCzIZ
Lmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIEdGVybSJTChNSZWxlYXNlTGVhc2VSZXF1ZXN0
Eg4KAmlkGAEgASgJUgJpZBIWCgZzZXJpZXMYAiABKAlSBnNlcmllcxIUCgVvd25lchgDIAEo
CVIFb3duZXIiFgoUUmVsZWFzZUxlYXNlUmVzcG9uc2UiwgEKD1JlcXVlc3RNZXRhZGF0YRIW
CgZzdHJlYW0YASABKAlSBnN0cmVhbRIUCgVldmVudBgCIAEoCVIFZXZlbnQSFgoGc2VyaWVz
GAMgASgJUgZzZXJpZXMSGQoIbGVhc2VfaWQYBCABKAlSB2xlYXNlSWQSFAoFb3duZXIYBSAB
KAlSBW93bmVyEjgKCmxlYXNlX3Rlcm0YBiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25SCWxlYXNlVGVybSKkAQoSU2VuZFBhY2tldHNSZXF1ZXN0EjoKBnBhY2tldBgBIAEoCzIg
Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5QYWNrZXRIAFIGcGFja2V0EkcKCG1ldGFkYXRh
GAIgASgLMikuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLlJlcXVlc3RNZXRhZGF0YUgAUght
ZXRhZGF0YUIJCgdyZXF1ZXN0IhUKE1NlbmRQYWNrZXRzUmVzcG9uc2UitQUKFVJlY2VpdmVQ
YWNrZXRzUmVxdWVzdBJjCg1zZXR1cF9yZXF1ZXN0GAYgASgLMjwuZ29vZ2xlLmNsb3VkLnZp
c2lvbmFpLnYxLlJlY2VpdmVQYWNrZXRzUmVxdWVzdC5TZXR1cFJlcXVlc3RIAFIMc2V0dXBS
ZXF1ZXN0ElAKDmNvbW1pdF9yZXF1ZXN0GAcgASgLMicuZ29vZ2xlLmNsb3VkLnZpc2lvbmFp
LnYxLkNvbW1pdFJlcXVlc3RIAFINY29tbWl0UmVxdWVzdBrZAwoMU2V0dXBSZXF1ZXN0ElMK
EmVhZ2VyX3JlY2VpdmVfbW9kZRgDIAEoCzIjLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5F
YWdlck1vZGVIAFIQZWFnZXJSZWNlaXZlTW9kZRJiChdjb250cm9sbGVkX3JlY2VpdmVfbW9k
ZRgEIAEoCzIoLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5Db250cm9sbGVkTW9kZUgAUhVj
b250cm9sbGVkUmVjZWl2ZU1vZGUSRQoIbWV0YWRhdGEYASABKAsyKS5nb29nbGUuY2xvdWQu
dmlzaW9uYWkudjEuUmVxdWVzdE1ldGFkYXRhUghtZXRhZGF0YRIaCghyZWNlaXZlchgCIAEo
CVIIcmVjZWl2ZXISSAoSaGVhcnRiZWF0X2ludGVydmFsGAUgASgLMhkuZ29vZ2xlLnByb3Rv
YnVmLkR1cmF0aW9uUhFoZWFydGJlYXRJbnRlcnZhbBJSChh3cml0ZXNfZG9uZV9ncmFjZV9w
ZXJpb2QYBiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SFXdyaXRlc0RvbmVHcmFj
ZVBlcmlvZEIPCg1jb25zdW1lcl9tb2RlQgkKB3JlcXVlc3QifAodUmVjZWl2ZVBhY2tldHND
b250cm9sUmVzcG9uc2USHgoJaGVhcnRiZWF0GAEgASgISABSCWhlYXJ0YmVhdBIwChN3cml0
ZXNfZG9uZV9yZXF1ZXN0GAIgASgISABSEXdyaXRlc0RvbmVSZXF1ZXN0QgkKB2NvbnRyb2wi
tQEKFlJlY2VpdmVQYWNrZXRzUmVzcG9uc2USOgoGcGFja2V0GAEgASgLMiAuZ29vZ2xlLmNs
b3VkLnZpc2lvbmFpLnYxLlBhY2tldEgAUgZwYWNrZXQSUwoHY29udHJvbBgDIAEoCzI3Lmdv
b2dsZS5jbG91ZC52aXNpb25haS52MS5SZWNlaXZlUGFja2V0c0NvbnRyb2xSZXNwb25zZUgA
Ugdjb250cm9sQgoKCHJlc3BvbnNlIgsKCUVhZ2VyTW9kZSKXAQoOQ29udHJvbGxlZE1vZGUS
OAoXc3RhcnRpbmdfbG9naWNhbF9vZmZzZXQYASABKAlIAFIVc3RhcnRpbmdMb2dpY2FsT2Zm
c2V0EjgKGGZhbGxiYWNrX3N0YXJ0aW5nX29mZnNldBgCIAEoCVIWZmFsbGJhY2tTdGFydGlu
Z09mZnNldEIRCg9zdGFydGluZ19vZmZzZXQiJwoNQ29tbWl0UmVxdWVzdBIWCgZvZmZzZXQY
ASABKANSBm9mZnNldCpVCglMZWFzZVR5cGUSGgoWTEVBU0VfVFlQRV9VTlNQRUNJRklFRBAA
EhUKEUxFQVNFX1RZUEVfUkVBREVSEAESFQoRTEVBU0VfVFlQRV9XUklURVIQAjLjBwoQU3Ry
ZWFtaW5nU2VydmljZRJwCgtTZW5kUGFja2V0cxIsLmdvb2dsZS5jbG91ZC52aXNpb25haS52
MS5TZW5kUGFja2V0c1JlcXVlc3QaLS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuU2VuZFBh
Y2tldHNSZXNwb25zZSIAKAEwARJ5Cg5SZWNlaXZlUGFja2V0cxIvLmdvb2dsZS5jbG91ZC52
aXNpb25haS52MS5SZWNlaXZlUGFja2V0c1JlcXVlc3QaMC5nb29nbGUuY2xvdWQudmlzaW9u
YWkudjEuUmVjZWl2ZVBhY2tldHNSZXNwb25zZSIAKAEwARJ2Cg1SZWNlaXZlRXZlbnRzEi4u
Z29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLlJlY2VpdmVFdmVudHNSZXF1ZXN0Gi8uZ29vZ2xl
LmNsb3VkLnZpc2lvbmFpLnYxLlJlY2VpdmVFdmVudHNSZXNwb25zZSIAKAEwARKvAQoMQWNx
dWlyZUxlYXNlEi0uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLkFjcXVpcmVMZWFzZVJlcXVl
c3QaHy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuTGVhc2UiT4LT5JMCSSJEL3YxL3tzZXJp
ZXM9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbHVzdGVycy8qL3Nlcmllcy8qfTphY3F1aXJl
TGVhc2U6ASoSqQEKClJlbmV3TGVhc2USKy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuUmVu
ZXdMZWFzZVJlcXVlc3QaHy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuTGVhc2UiTYLT5JMC
RyJCL3YxL3tzZXJpZXM9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jbHVzdGVycy8qL3Nlcmll
cy8qfTpyZW5ld0xlYXNlOgEqEr4BCgxSZWxlYXNlTGVhc2USLS5nb29nbGUuY2xvdWQudmlz
aW9uYWkudjEuUmVsZWFzZUxlYXNlUmVxdWVzdBouLmdvb2dsZS5jbG91ZC52aXNpb25haS52
MS5SZWxlYXNlTGVhc2VSZXNwb25zZSJPgtPkkwJJIkQvdjEve3Nlcmllcz1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NsdXN0ZXJzLyovc2VyaWVzLyp9OnJlbGVhc2VMZWFzZToBKhpLykEX
dmlzaW9uYWkuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9h
dXRoL2Nsb3VkLXBsYXRmb3JtQsUBChxjb20uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxQhVT
dHJlYW1pbmdTZXJ2aWNlUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby92aXNpb25haS9h
cGl2MS92aXNpb25haXBiO3Zpc2lvbmFpcGKqAhhHb29nbGUuQ2xvdWQuVmlzaW9uQUkuVjHK
AhhHb29nbGVcQ2xvdWRcVmlzaW9uQUlcVjHqAhtHb29nbGU6OkNsb3VkOjpWaXNpb25BSTo6
VjFKyV0KBxIFDgCVAwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUADwKCQoCAwMSAxUAKAoJCgID
BBIDFgApCggKAQgSAxgANQoJCgIIJRIDGAA1CggKAQgSAxkATwoJCgIICxIDGQBPCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsANgoJCgIICBIDGwA2CggKAQgSAxwANQoJCgIIARID
HAA1CggKAQgSAx0ANQoJCgIIKRIDHQA1CggKAQgSAx4ANAoJCgIILRIDHgA0CkIKAgYAEgQh
AEkBGjYgU3RyZWFtaW5nIHNlcnZpY2UgZm9yIHJlY2VpdmluZyBhbmQgc2VuZGluZyBwYWNr
ZXRzLgoKCgoDBgABEgMhCBgKCgoDBgADEgMiAj8KDAoFBgADmQgSAyICPwoLCgMGAAMSBCMC
JDcKDQoFBgADmggSBCMCJDcKKwoEBgACABIEJwIoLRodIFNlbmQgcGFja2V0cyB0byB0aGUg
c2VyaWVzLgoKDAoFBgACAAESAycGEQoMCgUGAAIABRIDJxIYCgwKBQYAAgACEgMnGSsKDAoF
BgACAAYSAygPFQoMCgUGAAIAAxIDKBYpCjAKBAYAAgESBCsCLDAaIiBSZWNlaXZlIHBhY2tl
dHMgZnJvbSB0aGUgc2VyaWVzLgoKDAoFBgACAQESAysGFAoMCgUGAAIBBRIDKxUbCgwKBQYA
AgECEgMrHDEKDAoFBgACAQYSAywPFQoMCgUGAAIBAxIDLBYsCjUKBAYAAgISBC8CMC8aJyBS
ZWNlaXZlIGV2ZW50cyBnaXZlbiB0aGUgc3RyZWFtIG5hbWUuCgoMCgUGAAICARIDLwYTCgwK
BQYAAgIFEgMvFBoKDAoFBgACAgISAy8bLwoMCgUGAAICBhIDMA8VCgwKBQYAAgIDEgMwFisK
LgoEBgACAxIEMwI4AxogIEFjcXVpcmVMZWFzZSBhY3F1aXJlcyBhIGxlYXNlLgoKDAoFBgAC
AwESAzMGEgoMCgUGAAIDAhIDMxMmCgwKBQYAAgMDEgMzMTYKDQoFBgACAwQSBDQENwYKEQoJ
BgACAwSwyrwiEgQ0BDcGCioKBAYAAgQSBDsCQAMaHCBSZW5ld0xlYXNlIHJlbmV3cyBhIGxl
YXNlLgoKDAoFBgACBAESAzsGEAoMCgUGAAIEAhIDOxEiCgwKBQYAAgQDEgM7LTIKDQoFBgAC
BAQSBDwEPwYKEQoJBgACBASwyrwiEgQ8BD8GCi0KBAYAAgUSBEMCSAMaHyBSbGVhc2VMZWFz
ZSByZWxlYXNlcyBhIGxlYXNlLgoKDAoFBgACBQESA0MGEgoMCgUGAAIFAhIDQxMmCgwKBQYA
AgUDEgNDMUUKDQoFBgACBQQSBEQERwYKEQoJBgACBQSwyrwiEgREBEcGCh0KAgUAEgRMAFUB
GhEgVGhlIGxlYXNlIHR5cGUuCgoKCgMFAAESA0wFDgomCgQFAAIAEgNOAh0aGSBMZWFzZSB0
eXBlIHVuc3BlY2lmaWVkLgoKDAoFBQACAAESA04CGAoMCgUFAAIAAhIDThscCicKBAUAAgES
A1ECGBoaIExlYXNlIGZvciBzdHJlYW0gcmVhZGVyLgoKDAoFBQACAQESA1ECEwoMCgUFAAIB
AhIDURYXCicKBAUAAgISA1QCGBoaIExlYXNlIGZvciBzdHJlYW0gd3JpdGVyLgoKDAoFBQAC
AgESA1QCEwoMCgUFAAICAhIDVBYXCjEKAgQAEgVYAIIBARokIFJlcXVlc3QgbWVzc2FnZSBm
b3IgUmVjZWl2ZUV2ZW50cy4KCgoKAwQAARIDWAgcCmMKBAQAAwASBFsCeQMaVSBTZXR1cFJl
cXVlc3QgaXMgdGhlIGZpcnN0IG1lc3NhZ2Ugc2VudCB0byB0aGUgc2VydmljZSB0byBzZXR1
cCB0aGUgUlBDCiBjb25uZWN0aW9uLgoKDAoFBAADAAESA1sKFgoiCgYEAAMAAgASA10EFxoT
IFRoZSBjbHVzdGVyIG5hbWUuCgoOCgcEAAMAAgAFEgNdBAoKDgoHBAADAAIAARIDXQsSCg4K
BwQAAwACAAMSA10VFgpaCgYEAAMAAgESA2AEFhpLIFRoZSBzdHJlYW0gbmFtZS4gVGhlIHNl
cnZpY2Ugd2lsbCByZXR1cm4gdGhlIGV2ZW50cyBmb3IgdGhlIGdpdmVuIHN0cmVhbS4KCg4K
BwQAAwACAQUSA2AECgoOCgcEAAMAAgEBEgNgCxEKDgoHBAADAAIBAxIDYBQVCnYKBgQAAwAC
AhIDZQQYGmcgQSBuYW1lIGZvciB0aGUgcmVjZWl2ZXIgdG8gc2VsZi1pZGVudGlmeS4KCiBU
aGlzIGlzIHVzZWQgdG8ga2VlcCB0cmFjayBvZiBhIHJlY2VpdmVyJ3MgcmVhZCBwcm9ncmVz
cy4KCg4KBwQAAwACAgUSA2UECgoOCgcEAAMAAgIBEgNlCxMKDgoHBAADAAICAxIDZRYXClQK
BgQAAwACAxIDaAQnGkUgQ29udHJvbGxlciBtb2RlIGNvbmZpZ3VyYXRpb24gZm9yIHJlY2Vp
dmluZyBldmVudHMgZnJvbSB0aGUgc2VydmVyLgoKDgoHBAADAAIDBhIDaAQSCg4KBwQAAwAC
AwESA2gTIgoOCgcEAAMAAgMDEgNoJSYKqwIKBgQAAwACBBIDcAQ0GpsCIFRoZSBtYXhpbXVt
IGR1cmF0aW9uIG9mIHNlcnZlciBzaWxlbmNlIGJlZm9yZSB0aGUgY2xpZW50IGRldGVybWlu
ZXMgdGhlCiBzZXJ2ZXIgdW5yZWFjaGFibGUuCgogVGhlIGNsaWVudCBtdXN0IGVpdGhlciBy
ZWNlaXZlIGFuIGBFdmVudGAgdXBkYXRlIG9yIGEgaGVhcnQgYmVhdCBtZXNzYWdlCiBiZWZv
cmUgdGhpcyBkdXJhdGlvbiBleHBpcmVzOyBvdGhlcndpc2UsIHRoZSBjbGllbnQgd2lsbCBh
dXRvbWF0aWNhbGx5CiBjYW5jZWwgdGhlIGN1cnJlbnQgY29ubmVjdGlvbiBhbmQgcmV0cnku
CgoOCgcEAAMAAgQGEgNwBBwKDgoHBAADAAIEARIDcB0vCg4KBwQAAwACBAMSA3AyMwrqAQoG
BAADAAIFEgN4BDoa2gEgVGhlIGdyYWNlIHBlcmlvZCBhZnRlciB3aGljaCBhIGB3cml0ZXNf
ZG9uZV9yZXF1ZXN0YCBpcyBpc3N1ZWQsIHRoYXQgYQogYFdyaXRlc0RvbmVgIGlzIGV4cGVj
dGVkIGZyb20gdGhlIGNsaWVudC4KCiBUaGUgc2VydmVyIGlzIGZyZWUgdG8gY2FuY2VsIHRo
ZSBSUEMgc2hvdWxkIHRoaXMgZXhwaXJlLgoKIEEgc3lzdGVtIGRlZmF1bHQgd2lsbCBiZSBj
aG9zZW4gaWYgdW5zZXQuCgoOCgcEAAMAAgUGEgN4BBwKDgoHBAADAAIFARIDeB01Cg4KBwQA
AwACBQMSA3g4OQoNCgQEAAgAEgV7AoEBAwoMCgUEAAgAARIDewgPCj0KBAQAAgASA30EIxow
IFRoZSBzZXR1cCByZXF1ZXN0IHRvIHNldHVwIHRoZSBSUEMgY29ubmVjdGlvbi4KCgwKBQQA
AgAGEgN9BBAKDAoFBAACAAESA30RHgoMCgUEAAIAAxIDfSEiCkYKBAQAAgESBIABBCUaOCBU
aGlzIHJlcXVlc3QgY2hlY2twb2ludHMgdGhlIGNvbnN1bWVyJ3MgcmVhZCBwcm9ncmVzcy4K
Cg0KBQQAAgEGEgSAAQQRCg0KBQQAAgEBEgSAARIgCg0KBQQAAgEDEgSAASMkCikKAgQBEgaF
AQCVAQEaGyBUaGUgZXZlbnQgdXBkYXRlIG1lc3NhZ2UuCgoLCgMEAQESBIUBCBMKRQoEBAEC
ABIEhwECFBo3IFRoZSBuYW1lIG9mIHRoZSBzdHJlYW0gdGhhdCB0aGUgZXZlbnQgaXMgYXR0
YWNoZWQgdG8uCgoNCgUEAQIABRIEhwECCAoNCgUEAQIAARIEhwEJDwoNCgUEAQIAAxIEhwES
EwomCgQEAQIBEgSKAQITGhggVGhlIG5hbWUgb2YgdGhlIGV2ZW50LgoKDQoFBAECAQUSBIoB
AggKDQoFBAECAQESBIoBCQ4KDQoFBAECAQMSBIoBERIKJwoEBAECAhIEjQECFBoZIFRoZSBu
YW1lIG9mIHRoZSBzZXJpZXMuCgoNCgUEAQICBRIEjQECCAoNCgUEAQICARIEjQEJDwoNCgUE
AQICAxIEjQESEwo8CgQEAQIDEgSQAQIsGi4gVGhlIHRpbWVzdGFtcCB3aGVuIHRoZSBFdmVu
dCB1cGRhdGUgaGFwcGVucy4KCg0KBQQBAgMGEgSQAQIbCg0KBQQBAgMBEgSQARwnCg0KBQQB
AgMDEgSQASorCmUKBAQBAgQSBJQBAhMaVyBUaGUgb2Zmc2V0IG9mIHRoZSBtZXNzYWdlIHRo
YXQgd2lsbCBiZSB1c2VkIHRvIGFja25vd2xlZGdlIG9mIHRoZSBtZXNzYWdlCiByZWNlaXZp
bmcuCgoNCgUEAQIEBRIElAECBwoNCgUEAQIEARIElAEIDgoNCgUEAQIEAxIElAEREgo8CgIE
AhIGmAEAqQEBGi4gQ29udHJvbCBtZXNzYWdlIGZvciBhIFJlY2VpdmVFdmVudHNSZXNwb25z
ZS4KCgsKAwQCARIEmAEIJAosCgQEAggAEgaaAQKoAQMaHCBQb3NzaWJsZSBjb250cm9sIG1l
c3NhZ2VzLgoKDQoFBAIIAAESBJoBCA8KIwoEBAICABIEnAEEFxoVIEEgc2VydmVyIGhlYXJ0
YmVhdC4KCg0KBQQCAgAFEgScAQQICg0KBQQCAgABEgScAQkSCg0KBQQCAgADEgScARUWCr4D
CgQEAgIBEgSnAQQhGq8DIEEgcmVxdWVzdCB0byB0aGUgcmVjZWl2ZXIgdG8gY29tcGxldGUg
YW55IGZpbmFsIHdyaXRlcyBmb2xsb3dlZCBieSBhCiBgV3JpdGVzRG9uZWA7IGUuZy4gaXNz
dWUgYW55IGZpbmFsIGBDb21taXRSZXF1ZXN0YHMuCgogTWF5IGJlIGlnbm9yZWQgaWYgYFdy
aXRlc0RvbmVgIGhhcyBhbHJlYWR5IGJlZW4gaXNzdWVkIGF0IGFueSBwb2ludAogcHJpb3Ig
dG8gcmVjZWl2aW5nIHRoaXMgbWVzc2FnZS4KCiBJZiBgV3JpdGVzRG9uZWAgZG9lcyBub3Qg
Z2V0IGlzc3VlZCwgdGhlbiB0aGUgc2VydmVyIHdpbGwgZm9yY2VmdWxseQogY2FuY2VsIHRo
ZSBjb25uZWN0aW9uLCBhbmQgdGhlIHJlY2VpdmVyIHdpbGwgbGlrZWx5IHJlY2VpdmUgYW4K
IHVuaW5mb3JtYXRpdmUgYWZ0ZXIgYFJlYWRgIHJldHVybnMgYGZhbHNlYCBhbmQgYEZpbmlz
aGAgaXMgY2FsbGVkLgoKDQoFBAICAQUSBKcBBAgKDQoFBAICAQESBKcBCRwKDQoFBAICAQMS
BKcBHyAKNwoCBAMSBqwBALUBARopIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZSBSZWNlaXZl
RXZlbnRzLgoKCwoDBAMBEgSsAQgdCioKBAQDCAASBq4BArQBAxoaIFBvc3NpYmxlIHJlc3Bv
bnNlIHR5cGVzLgoKDQoFBAMIAAESBK4BCBAKKQoEBAMCABIEsAEEIRobIFRoZSBldmVudCB1
cGRhdGUgbWVzc2FnZS4KCg0KBQQDAgAGEgSwAQQPCg0KBQQDAgABEgSwARAcCg0KBQQDAgAD
EgSwAR8gCjIKBAQDAgESBLMBBC0aJCBBIGNvbnRyb2wgbWVzc2FnZSBmcm9tIHRoZSBzZXJ2
ZXIuCgoNCgUEAwIBBhIEswEEIAoNCgUEAwIBARIEswEhKAoNCgUEAwIBAxIEswErLAoiCgIE
BBIGuAEAxwEBGhQgVGhlIGxlYXNlIG1lc3NhZ2UuCgoLCgMEBAESBLgBCA0KHQoEBAQCABIE
ugECEBoPIFRoZSBsZWFzZSBpZC4KCg0KBQQEAgAFEgS6AQIICg0KBQQEAgABEgS6AQkLCg0K
BQQEAgADEgS6AQ4PCiAKBAQEAgESBL0BAhQaEiBUaGUgc2VyaWVzIG5hbWUuCgoNCgUEBAIB
BRIEvQECCAoNCgUEBAIBARIEvQEJDwoNCgUEBAIBAxIEvQESEwofCgQEBAICEgTAAQITGhEg
VGhlIG93bmVyIG5hbWUuCgoNCgUEBAICBRIEwAECCAoNCgUEBAICARIEwAEJDgoNCgUEBAIC
AxIEwAEREgomCgQEBAIDEgTDAQIsGhggVGhlIGxlYXNlIGV4cGlyZSB0aW1lLgoKDQoFBAQC
AwYSBMMBAhsKDQoFBAQCAwESBMMBHCcKDQoFBAQCAwMSBMMBKisKHwoEBAQCBBIExgECGxoR
IFRoZSBsZWFzZSB0eXBlLgoKDQoFBAQCBAYSBMYBAgsKDQoFBAQCBAESBMYBDBYKDQoFBAQC
BAMSBMYBGRoKNgoCBAUSBsoBANYBARooIFJlcXVlc3QgbWVzc2FnZSBmb3IgYWNxdWlyaW5n
IGEgbGVhc2UuCgoLCgMEBQESBMoBCBsKIAoEBAUCABIEzAECFBoSIFRoZSBzZXJpZXMgbmFt
ZS4KCg0KBQQFAgAFEgTMAQIICg0KBQQFAgABEgTMAQkPCg0KBQQFAgADEgTMARITCh8KBAQF
AgESBM8BAhMaESBUaGUgb3duZXIgbmFtZS4KCg0KBQQFAgEFEgTPAQIICg0KBQQFAgEBEgTP
AQkOCg0KBQQFAgEDEgTPARESCh8KBAQFAgISBNIBAiQaESBUaGUgbGVhc2UgdGVybS4KCg0K
BQQFAgIGEgTSAQIaCg0KBQQFAgIBEgTSARsfCg0KBQQFAgIDEgTSASIjCh8KBAQFAgMSBNUB
AhsaESBUaGUgbGVhc2UgdHlwZS4KCg0KBQQFAgMGEgTVAQILCg0KBQQFAgMBEgTVAQwWCg0K
BQQFAgMDEgTVARkaCjUKAgQGEgbZAQDlAQEaJyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHJlbmV3
aW5nIGEgbGVhc2UuCgoLCgMEBgESBNkBCBkKGQoEBAYCABIE2wECEBoLIExlYXNlIGlkLgoK
DQoFBAYCAAUSBNsBAggKDQoFBAYCAAESBNsBCQsKDQoFBAYCAAMSBNsBDg8KHAoEBAYCARIE
3gECFBoOIFNlcmllcyBuYW1lLgoKDQoFBAYCAQUSBN4BAggKDQoFBAYCAQESBN4BCQ8KDQoF
BAYCAQMSBN4BEhMKHAoEBAYCAhIE4QECExoOIExlYXNlIG93bmVyLgoKDQoFBAYCAgUSBOEB
AggKDQoFBAYCAgESBOEBCQ4KDQoFBAYCAgMSBOEBERIKGwoEBAYCAxIE5AECJBoNIExlYXNl
IHRlcm0uCgoNCgUEBgIDBhIE5AECGgoNCgUEBgIDARIE5AEbHwoNCgUEBgIDAxIE5AEiIwo0
CgIEBxIG6AEA8QEBGiYgUmVxdWVzdCBtZXNzYWdlIGZvciByZWxlYXNpbmcgbGVhc2UuCgoL
CgMEBwESBOgBCBsKGQoEBAcCABIE6gECEBoLIExlYXNlIGlkLgoKDQoFBAcCAAUSBOoBAggK
DQoFBAcCAAESBOoBCQsKDQoFBAcCAAMSBOoBDg8KHAoEBAcCARIE7QECFBoOIFNlcmllcyBu
YW1lLgoKDQoFBAcCAQUSBO0BAggKDQoFBAcCAQESBO0BCQ8KDQoFBAcCAQMSBO0BEhMKHAoE
BAcCAhIE8AECExoOIExlYXNlIG93bmVyLgoKDQoFBAcCAgUSBPABAggKDQoFBAcCAgESBPAB
CQ4KDQoFBAcCAgMSBPABERIKMQoCBAgSBPQBAB8aJSBSZXNwb25zZSBtZXNzYWdlIGZvciBy
ZWxlYXNlIGxlYXNlLgoKCwoDBAgBEgT0AQgcCkgKAgQJEgb3AQCMAgEaOiBSZXF1ZXN0TWV0
YWRhdGEgaXMgdGhlIG1ldGFkYXRhIG1lc3NhZ2UgZm9yIHRoZSByZXF1ZXN0LgoKCwoDBAkB
EgT3AQgXChwKBAQJAgASBPkBAhQaDiBTdHJlYW0gbmFtZS4KCg0KBQQJAgAFEgT5AQIICg0K
BQQJAgABEgT5AQkPCg0KBQQJAgADEgT5ARITChsKBAQJAgESBPwBAhMaDSBFdmV2dCBuYW1l
LgoKDQoFBAkCAQUSBPwBAggKDQoFBAkCAQESBPwBCQ4KDQoFBAkCAQMSBPwBERIKHAoEBAkC
AhIE/wECFBoOIFNlcmllcyBuYW1lLgoKDQoFBAkCAgUSBP8BAggKDQoFBAkCAgESBP8BCQ8K
DQoFBAkCAgMSBP8BEhMKGQoEBAkCAxIEggICFhoLIExlYXNlIGlkLgoKDQoFBAkCAwUSBIIC
AggKDQoFBAkCAwESBIICCREKDQoFBAkCAwMSBIICFBUKGwoEBAkCBBIEhQICExoNIE93bmVy
IG5hbWUuCgoNCgUECQIEBRIEhQICCAoNCgUECQIEARIEhQIJDgoNCgUECQIEAxIEhQIREgqP
AgoEBAkCBRIEiwICKhqAAiBMZWFzZSB0ZXJtIHNwZWNpZmllcyBob3cgbG9uZyB0aGUgY2xp
ZW50IHdhbnRzIHRoZSBzZXNzaW9uIHRvIGJlIG1haW50YWluZWQKIGJ5IHRoZSBzZXJ2ZXIg
YWZ0ZXIgdGhlIGNsaWVudCBsZWF2ZXMuIElmIHRoZSBsZWFzZSB0ZXJtIGlzIG5vdCBzZXQs
IHRoZQogc2VydmVyIHdpbGwgcmVsZWFzZSB0aGUgc2Vzc2lvbiBpbW1lZGlhdGVseSBhbmQg
dGhlIGNsaWVudCBjYW5ub3QgcmVjb25uZWN0CiB0byB0aGUgc2FtZSBzZXNzaW9uIGxhdGVy
LgoKDQoFBAkCBQYSBIsCAhoKDQoFBAkCBQESBIsCGyUKDQoFBAkCBQMSBIsCKCkKNAoCBAoS
Bo8CAJcCARomIFJlcXVlc3QgbWVzc2FnZSBmb3Igc2VuZGluZyBwYWNrZXRzLgoKCwoDBAoB
EgSPAggaCg4KBAQKCAASBpACApYCAwoNCgUECggAARIEkAIIDwo0CgQECgIAEgSSAgQWGiYg
UGFja2V0cyBzZW50IG92ZXIgdGhlIHN0cmVhbWluZyBycGMuCgoNCgUECgIABhIEkgIECgoN
CgUECgIAARIEkgILEQoNCgUECgIAAxIEkgIUFQpWCgQECgIBEgSVAgQhGkggVGhlIGZpcnN0
IG1lc3NhZ2Ugb2YgdGhlIHN0cmVhbWluZyBycGMgaW5jbHVkaW5nIHRoZSByZXF1ZXN0IG1l
dGFkYXRhLgoKDQoFBAoCAQYSBJUCBBMKDQoFBAoCAQESBJUCFBwKDQoFBAoCAQMSBJUCHyAK
MwoCBAsSBJoCAB4aJyBSZXNwb25zZSBtZXNzYWdlIGZvciBzZW5kaW5nIHBhY2tldHMuCgoL
CgMECwESBJoCCBsKNgoCBAwSBp0CAMwCARooIFJlcXVlc3QgbWVzc2FnZSBmb3IgcmVjZWl2
aW5nIHBhY2tldHMuCgoLCgMEDAESBJ0CCB0KXQoEBAwDABIGnwICwAIDGk0gVGhlIG1lc3Nh
Z2Ugc3BlY2lmeWluZyB0aGUgaW5pdGlhbCBzZXR0aW5ncyBmb3IgdGhlIFJlY2VpdmVQYWNr
ZXRzIHNlc3Npb24uCgoNCgUEDAMAARIEnwIKFgpCCgYEDAMACAASBqECBKcCBRowIFRoZSBt
b2RlIGluIHdoaWNoIHRoZSBjb25zdW1lciByZWFkcyBtZXNzYWdlcy4KCg8KBwQMAwAIAAES
BKECChcKNQoGBAwDAAIAEgSjAgYnGiUgT3B0aW9ucyBmb3IgY29uZmlndXJpbmcgZWFnZXIg
bW9kZS4KCg8KBwQMAwACAAYSBKMCBg8KDwoHBAwDAAIAARIEowIQIgoPCgcEDAMAAgADEgSj
AiUmCjoKBgQMAwACARIEpgIGMRoqIE9wdGlvbnMgZm9yIGNvbmZpZ3VyaW5nIGNvbnRyb2xs
ZWQgbW9kZS4KCg8KBwQMAwACAQYSBKYCBhQKDwoHBAwDAAIBARIEpgIVLAoPCgcEDAMAAgED
EgSmAi8wCk4KBgQMAwACAhIEqgIEIRo+IFRoZSBjb25maWd1cmF0aW9ucyB0aGF0IHNwZWNp
Znkgd2hlcmUgcGFja2V0cyBhcmUgcmV0cmlldmVkLgoKDwoHBAwDAAICBhIEqgIEEwoPCgcE
DAMAAgIBEgSqAhQcCg8KBwQMAwACAgMSBKoCHyAKdwoGBAwDAAIDEgSvAgQYGmcgQSBuYW1l
IGZvciB0aGUgcmVjZWl2ZXIgdG8gc2VsZi1pZGVudGlmeS4KCiBUaGlzIGlzIHVzZWQgdG8g
a2VlcCB0cmFjayBvZiBhIHJlY2VpdmVyJ3MgcmVhZCBwcm9ncmVzcy4KCg8KBwQMAwACAwUS
BK8CBAoKDwoHBAwDAAIDARIErwILEwoPCgcEDAMAAgMDEgSvAhYXCqUCCgYEDAMAAgQSBLcC
BDQalAIgVGhlIG1heGltdW0gZHVyYXRpb24gb2Ygc2VydmVyIHNpbGVuY2UgYmVmb3JlIHRo
ZSBjbGllbnQgZGV0ZXJtaW5lcyB0aGUKIHNlcnZlciB1bnJlYWNoYWJsZS4KCiBUaGUgY2xp
ZW50IG11c3QgZWl0aGVyIHJlY2VpdmUgYSBgUGFja2V0YCBvciBhIGhlYXJ0IGJlYXQgbWVz
c2FnZSBiZWZvcmUKIHRoaXMgZHVyYXRpb24gZXhwaXJlczsgb3RoZXJ3aXNlLCB0aGUgY2xp
ZW50IHdpbGwgYXV0b21hdGljYWxseSBjYW5jZWwKIHRoZSBjdXJyZW50IGNvbm5lY3Rpb24g
YW5kIHJldHJ5LgoKDwoHBAwDAAIEBhIEtwIEHAoPCgcEDAMAAgQBEgS3Ah0vCg8KBwQMAwAC
BAMSBLcCMjMK6wEKBgQMAwACBRIEvwIEOhraASBUaGUgZ3JhY2UgcGVyaW9kIGFmdGVyIHdo
aWNoIGEgYHdyaXRlc19kb25lX3JlcXVlc3RgIGlzIGlzc3VlZCwgdGhhdCBhCiBgV3JpdGVz
RG9uZWAgaXMgZXhwZWN0ZWQgZnJvbSB0aGUgY2xpZW50LgoKIFRoZSBzZXJ2ZXIgaXMgZnJl
ZSB0byBjYW5jZWwgdGhlIFJQQyBzaG91bGQgdGhpcyBleHBpcmUuCgogQSBzeXN0ZW0gZGVm
YXVsdCB3aWxsIGJlIGNob3NlbiBpZiB1bnNldC4KCg8KBwQMAwACBQYSBL8CBBwKDwoHBAwD
AAIFARIEvwIdNQoPCgcEDAMAAgUDEgS/Ajg5CjkKBAQMCAASBsMCAssCAxopIFBvc3NpYmxl
IHJlcXVlc3QgdHlwZXMgZnJvbSB0aGUgY2xpZW50LgoKDQoFBAwIAAESBMMCCA8KggEKBAQM
AgASBMcCBCMadCBUaGUgcmVxdWVzdCB0byBzZXR1cCB0aGUgaW5pdGlhbCBzdGF0ZSBvZiBz
ZXNzaW9uLgoKIFRoZSBjbGllbnQgbXVzdCBzZW5kIGFuZCBvbmx5IHNlbmQgdGhpcyBhcyB0
aGUgZmlyc3QgbWVzc2FnZS4KCg0KBQQMAgAGEgTHAgQQCg0KBQQMAgABEgTHAhEeCg0KBQQM
AgADEgTHAiEiCkYKBAQMAgESBMoCBCUaOCBUaGlzIHJlcXVlc3QgY2hlY2twb2ludHMgdGhl
IGNvbnN1bWVyJ3MgcmVhZCBwcm9ncmVzcy4KCg0KBQQMAgEGEgTKAgQRCg0KBQQMAgEBEgTK
AhIgCg0KBQQMAgEDEgTKAiMkCj0KAgQNEgbPAgDgAgEaLyBDb250cm9sIG1lc3NhZ2UgZm9y
IGEgUmVjZWl2ZVBhY2tldHNSZXNwb25zZS4KCgsKAwQNARIEzwIIJQosCgQEDQgAEgbRAgLf
AgMaHCBQb3NzaWJsZSBjb250cm9sIG1lc3NhZ2VzLgoKDQoFBA0IAAESBNECCA8KIwoEBA0C
ABIE0wIEFxoVIEEgc2VydmVyIGhlYXJ0YmVhdC4KCg0KBQQNAgAFEgTTAgQICg0KBQQNAgAB
EgTTAgkSCg0KBQQNAgADEgTTAhUWCr4DCgQEDQIBEgTeAgQhGq8DIEEgcmVxdWVzdCB0byB0
aGUgcmVjZWl2ZXIgdG8gY29tcGxldGUgYW55IGZpbmFsIHdyaXRlcyBmb2xsb3dlZCBieSBh
CiBgV3JpdGVzRG9uZWA7IGUuZy4gaXNzdWUgYW55IGZpbmFsIGBDb21taXRSZXF1ZXN0YHMu
CgogTWF5IGJlIGlnbm9yZWQgaWYgYFdyaXRlc0RvbmVgIGhhcyBhbHJlYWR5IGJlZW4gaXNz
dWVkIGF0IGFueSBwb2ludAogcHJpb3IgdG8gcmVjZWl2aW5nIHRoaXMgbWVzc2FnZS4KCiBJ
ZiBgV3JpdGVzRG9uZWAgZG9lcyBub3QgZ2V0IGlzc3VlZCwgdGhlbiB0aGUgc2VydmVyIHdp
bGwgZm9yY2VmdWxseQogY2FuY2VsIHRoZSBjb25uZWN0aW9uLCBhbmQgdGhlIHJlY2VpdmVy
IHdpbGwgbGlrZWx5IHJlY2VpdmUgYW4KIHVuaW5mb3JtYXRpdmUgYWZ0ZXIgYFJlYWRgIHJl
dHVybnMgYGZhbHNlYCBhbmQgYEZpbmlzaGAgaXMgY2FsbGVkLgoKDQoFBA0CAQUSBN4CBAgK
DQoFBA0CAQESBN4CCRwKDQoFBA0CAQMSBN4CHyAKNQoCBA4SBuMCAOwCARonIFJlc3BvbnNl
IG1lc3NhZ2UgZnJvbSBSZWNlaXZlUGFja2V0cy4KCgsKAwQOARIE4wIIHgoqCgQEDggAEgbl
AgLrAgMaGiBQb3NzaWJsZSByZXNwb25zZSB0eXBlcy4KCg0KBQQOCAABEgTlAggQCkMKBAQO
AgASBOcCBBYaNSBBIGdlbnVpbmUgZGF0YSBwYXlsb2FkIG9yaWdpbmF0aW5nIGZyb20gdGhl
IHNlbmRlci4KCg0KBQQOAgAGEgTnAgQKCg0KBQQOAgABEgTnAgsRCg0KBQQOAgADEgTnAhQV
CjIKBAQOAgESBOoCBC4aJCBBIGNvbnRyb2wgbWVzc2FnZSBmcm9tIHRoZSBzZXJ2ZXIuCgoN
CgUEDgIBBhIE6gIEIQoNCgUEDgIBARIE6gIiKQoNCgUEDgIBAxIE6gIsLQo8CgIEDxIE7wIA
FBowIFRoZSBvcHRpb25zIGZvciByZWNlaXZlciB1bmRlciB0aGUgZWFnZXIgbW9kZS4KCgsK
AwQPARIE7wIIEQpDCgIEEBIG8gIAjAMBGjUgVGhlIG9wdGlvbnMgZm9yIHJlY2VpdmVyIHVu
ZGVyIHRoZSBjb250cm9sbGVkIG1vZGUuCgoLCgMEEAESBPICCBYKRAoEBBAIABIG9AICgQMD
GjQgVGhpcyBpcyB0aGUgb2Zmc2V0IGZyb20gd2hpY2ggdG8gc3RhcnQgcmVjZWl2ZWluZy4K
Cg0KBQQQCAABEgT0AggXCqIDCgQEEAIAEgSAAwQnGpMDIFRoaXMgY2FuIGJlIHNldCB0byB0
aGUgZm9sbG93aW5nIGxvZ2ljYWwgc3RhcnRpbmcgcG9pbnRzOgoKICJiZWdpbiI6IFRoaXMg
d2lsbCByZWFkIGZyb20gdGhlIGVhcmxpZXN0IGF2YWlsYWJsZSBtZXNzYWdlLgoKICJtb3N0
LXJlY2VudCI6IFRoaXMgd2lsbCByZWFkIGZyb20gdGhlIGxhdGVzdCBhdmFpbGFibGUgbWVz
c2FnZS4KCiAiZW5kIjogVGhpcyB3aWxsIHJlYWQgb25seSBmdXR1cmUgbWVzc2FnZXMuCgog
InN0b3JlZCI6IFRoaXMgd2lsbCByZXN1bWUgcmVhZHMgb25lIHBhc3QgdGhlIGxhc3QgY29t
bWl0dGVkIG9mZnNldC4KICAgICAgICAgICBJdCBpcyB0aGUgb25seSBvcHRpb24gdGhhdCBy
ZXN1bWVzIHByb2dyZXNzOyBhbGwgb3RoZXJzCiAgICAgICAgICAganVtcCB1bmlsYXRlcmFs
bHkuCgoNCgUEEAIABRIEgAMECgoNCgUEEAIAARIEgAMLIgoNCgUEEAIAAxIEgAMlJgqSAgoE
BBACARIEiwMCJhqDAiBUaGlzIGlzIHRoZSBsb2dpY2FsIHN0YXJ0aW5nIHBvaW50IHRvIGZh
bGxiYWNrIHVwb24gc2hvdWxkIHRoZQogc3BlY2lmaWVkIHN0YXJ0aW5nIG9mZnNldCBiZSB1
bmF2YWlsYWJsZS4KCiBUaGlzIGNhbiBiZSBvbmUgb2YgdGhlIGZvbGxvd2luZyB2YWx1ZXM6
CgogImJlZ2luIjogVGhpcyB3aWxsIHJlYWQgZnJvbSB0aGUgZWFybGllc3QgYXZhaWxhYmxl
IG1lc3NhZ2UuCgogImVuZCI6IFRoaXMgd2lsbCByZWFkIG9ubHkgZnV0dXJlIG1lc3NhZ2Vz
LgoKDQoFBBACAQUSBIsDAggKDQoFBBACAQESBIsDCSEKDQoFBBACAQMSBIsDJCUKqwEKAgQR
EgaSAwCVAwEanAEgVGhlIG1lc3NhZ2UgZm9yIGV4cGxpY2l0bHkgY29tbWl0dGluZyB0aGUg
cmVhZCBwcm9ncmVzcy4KCiBUaGlzIG1heSBvbmx5IGJlIHVzZWQgd2hlbiBgUmVjZWl2ZVBh
Y2tldHNDb250cm9sbGVkTW9kZWAgaXMgc2V0IGluIHRoZQogaW5pdGlhbCBzZXR1cCByZXF1
ZXN0LgoKCwoDBBEBEgSSAwgVCiUKBAQRAgASBJQDAhMaFyBUaGUgb2Zmc2V0IHRvIGNvbW1p
dC4KCg0KBQQRAgAFEgSUAwIHCg0KBQQRAgABEgSUAwgOCg0KBQQRAgADEgSUAxESYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest ===
    # Fields for ReceiveEventsRequest
    # Field: setup_request Type: 11 (.google.cloud.visionai.v1.ReceiveEventsRequest.SetupRequest)
    # Field: commit_request Type: 11 (.google.cloud.visionai.v1.CommitRequest)

# === Message: Google::Cloud::Visionai::V1::StreamingService::EventUpdate ===
    # Fields for EventUpdate
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()
    # Field: series Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: offset Type: 3 ()

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse ===
    # Fields for ReceiveEventsControlResponse
    # Field: heartbeat Type: 8 ()
    # Field: writes_done_request Type: 8 ()

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse ===
    # Fields for ReceiveEventsResponse
    # Field: event_update Type: 11 (.google.cloud.visionai.v1.EventUpdate)
    # Field: control Type: 11 (.google.cloud.visionai.v1.ReceiveEventsControlResponse)

# === Message: Google::Cloud::Visionai::V1::StreamingService::Lease ===
    # Fields for Lease
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: lease_type Type: 14 (.google.cloud.visionai.v1.LeaseType)

# === Message: Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest ===
    # Fields for AcquireLeaseRequest
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: term Type: 11 (.google.protobuf.Duration)
    # Field: lease_type Type: 14 (.google.cloud.visionai.v1.LeaseType)

# === Message: Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest ===
    # Fields for RenewLeaseRequest
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: term Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest ===
    # Fields for ReleaseLeaseRequest
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse ===
    # Fields for ReleaseLeaseResponse

# === Message: Google::Cloud::Visionai::V1::StreamingService::RequestMetadata ===
    # Fields for RequestMetadata
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()
    # Field: series Type: 9 ()
    # Field: lease_id Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: lease_term Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest ===
    # Fields for SendPacketsRequest
    # Field: packet Type: 11 (.google.cloud.visionai.v1.Packet)
    # Field: metadata Type: 11 (.google.cloud.visionai.v1.RequestMetadata)

# === Message: Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse ===
    # Fields for SendPacketsResponse

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest ===
    # Fields for ReceivePacketsRequest
    # Field: setup_request Type: 11 (.google.cloud.visionai.v1.ReceivePacketsRequest.SetupRequest)
    # Field: commit_request Type: 11 (.google.cloud.visionai.v1.CommitRequest)

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse ===
    # Fields for ReceivePacketsControlResponse
    # Field: heartbeat Type: 8 ()
    # Field: writes_done_request Type: 8 ()

# === Message: Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse ===
    # Fields for ReceivePacketsResponse
    # Field: packet Type: 11 (.google.cloud.visionai.v1.Packet)
    # Field: control Type: 11 (.google.cloud.visionai.v1.ReceivePacketsControlResponse)

# === Message: Google::Cloud::Visionai::V1::StreamingService::EagerMode ===
    # Fields for EagerMode

# === Message: Google::Cloud::Visionai::V1::StreamingService::ControlledMode ===
    # Fields for ControlledMode
    # Field: starting_logical_offset Type: 9 ()
    # Field: fallback_starting_offset Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamingService::CommitRequest ===
    # Fields for CommitRequest
    # Field: offset Type: 3 ()

# === Service Client: Google::Cloud::Visionai::V1::StreamingService::StreamingServiceClient ===
package Google::Cloud::Visionai::V1::StreamingService::StreamingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Visionai::V1::StreamingService::StreamingServiceClient

Client stub representing the remote C<StreamingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<visionai.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'visionai.googleapis.com:443' );

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

sub send_packets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'SendPackets',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse',
    });
}

sub receive_packets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'ReceivePackets',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse',
    });
}

sub receive_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'ReceiveEvents',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse',
    });
}

sub acquire_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'AcquireLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::Lease',
    });
}

sub renew_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'RenewLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::Lease',
    });
}

sub release_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1.StreamingService',
        method         => 'ReleaseLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::StreamingService - Compiled Protocol Buffers messages for google/cloud/visionai/v1/streaming_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::StreamingService;

    my $msg = Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest->new({
        setup_request => $setup_request,
        commit_request => $commit_request,
    });

    # Read or update a field
    my $val = $msg->setup_request();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/streaming_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest

Request message for ReceiveEvents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->setup_request() >> / C<< $msg->setup_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest::SetupRequest>)

The setup request to setup the RPC connection.

=item * C<< $msg->commit_request() >> / C<< $msg->commit_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::CommitRequest>)

This request checkpoints the consumer's read progress.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::EventUpdate

The event update message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

The name of the stream that the event is attached to.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

The name of the event.

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

The name of the series.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp when the Event update happens.

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int64>

The offset of the message that will be used to acknowledge of the message
receiving.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse

Control message for a ReceiveEventsResponse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->heartbeat() >> / C<< $msg->heartbeat($value) >>

Type: C<Bool>

A server heartbeat.

=item * C<< $msg->writes_done_request() >> / C<< $msg->writes_done_request($value) >>

Type: C<Bool>

A request to the receiver to complete any final writes followed by a
`WritesDone`; e.g. issue any final `CommitRequest`s.

May be ignored if `WritesDone` has already been issued at any point
prior to receiving this message.

If `WritesDone` does not get issued, then the server will forcefully
cancel the connection, and the receiver will likely receive an
uninformative after `Read` returns `false` and `Finish` is called.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse

Response message for the ReceiveEvents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_update() >> / C<< $msg->event_update($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::EventUpdate>)

The event update message.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse>)

A control message from the server.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::Lease

The lease message.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

The lease id.

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

The series name.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

The owner name.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The lease expire time.

=item * C<< $msg->lease_type() >> / C<< $msg->lease_type($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::LeaseType>)

The lease type.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest

Request message for acquiring a lease.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

The series name.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

The owner name.

=item * C<< $msg->term() >> / C<< $msg->term($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The lease term.

=item * C<< $msg->lease_type() >> / C<< $msg->lease_type($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::LeaseType>)

The lease type.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest

Request message for renewing a lease.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Lease id.

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

Series name.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

Lease owner.

=item * C<< $msg->term() >> / C<< $msg->term($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Lease term.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest

Request message for releasing lease.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Lease id.

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

Series name.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

Lease owner.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse

Response message for release lease.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1::StreamingService::RequestMetadata

RequestMetadata is the metadata message for the request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

Stream name.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

Evevt name.

=item * C<< $msg->series() >> / C<< $msg->series($value) >>

Type: C<String>

Series name.

=item * C<< $msg->lease_id() >> / C<< $msg->lease_id($value) >>

Type: C<String>

Lease id.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

Owner name.

=item * C<< $msg->lease_term() >> / C<< $msg->lease_term($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Lease term specifies how long the client wants the session to be maintained
by the server after the client leaves. If the lease term is not set, the
server will release the session immediately and the client cannot reconnect
to the same session later.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest

Request message for sending packets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packet() >> / C<< $msg->packet($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::Packet>)

Packets sent over the streaming rpc.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::RequestMetadata>)

The first message of the streaming rpc including the request metadata.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse

Response message for sending packets.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest

Request message for receiving packets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->setup_request() >> / C<< $msg->setup_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest::SetupRequest>)

The request to setup the initial state of session.

The client must send and only send this as the first message.

=item * C<< $msg->commit_request() >> / C<< $msg->commit_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::CommitRequest>)

This request checkpoints the consumer's read progress.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse

Control message for a ReceivePacketsResponse.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->heartbeat() >> / C<< $msg->heartbeat($value) >>

Type: C<Bool>

A server heartbeat.

=item * C<< $msg->writes_done_request() >> / C<< $msg->writes_done_request($value) >>

Type: C<Bool>

A request to the receiver to complete any final writes followed by a
`WritesDone`; e.g. issue any final `CommitRequest`s.

May be ignored if `WritesDone` has already been issued at any point
prior to receiving this message.

If `WritesDone` does not get issued, then the server will forcefully
cancel the connection, and the receiver will likely receive an
uninformative after `Read` returns `false` and `Finish` is called.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse

Response message from ReceivePackets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packet() >> / C<< $msg->packet($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingResources::Packet>)

A genuine data payload originating from the sender.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse>)

A control message from the server.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::EagerMode

The options for receiver under the eager mode.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1::StreamingService::ControlledMode

The options for receiver under the controlled mode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->starting_logical_offset() >> / C<< $msg->starting_logical_offset($value) >>

Type: C<String>

This can be set to the following logical starting points:

"begin": This will read from the earliest available message.

"most-recent": This will read from the latest available message.

"end": This will read only future messages.

"stored": This will resume reads one past the last committed offset.
          It is the only option that resumes progress; all others
          jump unilaterally.

=item * C<< $msg->fallback_starting_offset() >> / C<< $msg->fallback_starting_offset($value) >>

Type: C<String>

This is the logical starting point to fallback upon should the
specified starting offset be unavailable.

This can be one of the following values:

"begin": This will read from the earliest available message.

"end": This will read only future messages.

=back

=head2 Google::Cloud::Visionai::V1::StreamingService::CommitRequest

The message for explicitly committing the read progress.

This may only be used when `ReceivePacketsControlledMode` is set in the
initial setup request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->offset() >> / C<< $msg->offset($value) >>

Type: C<Int64>

The offset to commit.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::StreamingService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
