package Google::Cloud::Visionai::V1alpha1::StreamingService;

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
    eval { require Google::Cloud::Visionai::V1alpha1::StreamingResources };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvc3RyZWFtaW5nX3NlcnZpY2UucHJv
dG8SHmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aOGdvb2dsZS9jbG91ZC92aXNp
b25haS92MWFscGhhMS9zdHJlYW1pbmdfcmVzb3VyY2VzLnByb3RvGh5nb29nbGUvcHJvdG9i
dWYvZHVyYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iuQQK
FFJlY2VpdmVFdmVudHNSZXF1ZXN0EmgKDXNldHVwX3JlcXVlc3QYASABKAsyQS5nb29nbGUu
Y2xvdWQudmlzaW9uYWkudjFhbHBoYTEuUmVjZWl2ZUV2ZW50c1JlcXVlc3QuU2V0dXBSZXF1
ZXN0SABSDHNldHVwUmVxdWVzdBJWCg5jb21taXRfcmVxdWVzdBgCIAEoCzItLmdvb2dsZS5j
bG91ZC52aXNpb25haS52MWFscGhhMS5Db21taXRSZXF1ZXN0SABSDWNvbW1pdFJlcXVlc3Qa
0wIKDFNldHVwUmVxdWVzdBIYCgdjbHVzdGVyGAEgASgJUgdjbHVzdGVyEhYKBnN0cmVhbRgC
IAEoCVIGc3RyZWFtEhoKCHJlY2VpdmVyGAMgASgJUghyZWNlaXZlchJXCg9jb250cm9sbGVk
X21vZGUYBCABKAsyLi5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQ29udHJvbGxl
ZE1vZGVSDmNvbnRyb2xsZWRNb2RlEkgKEmhlYXJ0YmVhdF9pbnRlcnZhbBgFIAEoCzIZLmdv
b2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRaGVhcnRiZWF0SW50ZXJ2YWwSUgoYd3JpdGVzX2Rv
bmVfZ3JhY2VfcGVyaW9kGAYgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhV3cml0
ZXNEb25lR3JhY2VQZXJpb2RCCQoHcmVxdWVzdCKoAQoLRXZlbnRVcGRhdGUSFgoGc3RyZWFt
GAEgASgJUgZzdHJlYW0SFAoFZXZlbnQYAiABKAlSBWV2ZW50EhYKBnNlcmllcxgDIAEoCVIG
c2VyaWVzEjsKC3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cFIKdXBkYXRlVGltZRIWCgZvZmZzZXQYBSABKANSBm9mZnNldCJ7ChxSZWNlaXZlRXZlbnRz
Q29udHJvbFJlc3BvbnNlEh4KCWhlYXJ0YmVhdBgBIAEoCEgAUgloZWFydGJlYXQSMAoTd3Jp
dGVzX2RvbmVfcmVxdWVzdBgCIAEoCEgAUhF3cml0ZXNEb25lUmVxdWVzdEIJCgdjb250cm9s
Is8BChVSZWNlaXZlRXZlbnRzUmVzcG9uc2USUAoMZXZlbnRfdXBkYXRlGAEgASgLMisuZ29v
Z2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkV2ZW50VXBkYXRlSABSC2V2ZW50VXBkYXRl
ElgKB2NvbnRyb2wYAiABKAsyPC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuUmVj
ZWl2ZUV2ZW50c0NvbnRyb2xSZXNwb25zZUgAUgdjb250cm9sQgoKCHJlc3BvbnNlIswBCgVM
ZWFzZRIOCgJpZBgBIAEoCVICaWQSFgoGc2VyaWVzGAIgASgJUgZzZXJpZXMSFAoFb3duZXIY
AyABKAlSBW93bmVyEjsKC2V4cGlyZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFIKZXhwaXJlVGltZRJICgpsZWFzZV90eXBlGAUgASgOMikuZ29vZ2xlLmNsb3Vk
LnZpc2lvbmFpLnYxYWxwaGExLkxlYXNlVHlwZVIJbGVhc2VUeXBlIrwBChNBY3F1aXJlTGVh
c2VSZXF1ZXN0EhYKBnNlcmllcxgBIAEoCVIGc2VyaWVzEhQKBW93bmVyGAIgASgJUgVvd25l
chItCgR0ZXJtGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgR0ZXJtEkgKCmxl
YXNlX3R5cGUYBCABKA4yKS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuTGVhc2VU
eXBlUglsZWFzZVR5cGUigAEKEVJlbmV3TGVhc2VSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIW
CgZzZXJpZXMYAiABKAlSBnNlcmllcxIUCgVvd25lchgDIAEoCVIFb3duZXISLQoEdGVybRgE
IAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIEdGVybSJTChNSZWxlYXNlTGVhc2VS
ZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIWCgZzZXJpZXMYAiABKAlSBnNlcmllcxIUCgVvd25l
chgDIAEoCVIFb3duZXIiFgoUUmVsZWFzZUxlYXNlUmVzcG9uc2UiwgEKD1JlcXVlc3RNZXRh
ZGF0YRIWCgZzdHJlYW0YASABKAlSBnN0cmVhbRIUCgVldmVudBgCIAEoCVIFZXZlbnQSFgoG
c2VyaWVzGAMgASgJUgZzZXJpZXMSGQoIbGVhc2VfaWQYBCABKAlSB2xlYXNlSWQSFAoFb3du
ZXIYBSABKAlSBW93bmVyEjgKCmxlYXNlX3Rlcm0YBiABKAsyGS5nb29nbGUucHJvdG9idWYu
RHVyYXRpb25SCWxlYXNlVGVybSKwAQoSU2VuZFBhY2tldHNSZXF1ZXN0EkAKBnBhY2tldBgB
IAEoCzImLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5QYWNrZXRIAFIGcGFja2V0
Ek0KCG1ldGFkYXRhGAIgASgLMi8uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLlJl
cXVlc3RNZXRhZGF0YUgAUghtZXRhZGF0YUIJCgdyZXF1ZXN0IhUKE1NlbmRQYWNrZXRzUmVz
cG9uc2Ui0wUKFVJlY2VpdmVQYWNrZXRzUmVxdWVzdBJpCg1zZXR1cF9yZXF1ZXN0GAYgASgL
MkIuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLlJlY2VpdmVQYWNrZXRzUmVxdWVz
dC5TZXR1cFJlcXVlc3RIAFIMc2V0dXBSZXF1ZXN0ElYKDmNvbW1pdF9yZXF1ZXN0GAcgASgL
Mi0uZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLkNvbW1pdFJlcXVlc3RIAFINY29t
bWl0UmVxdWVzdBrrAwoMU2V0dXBSZXF1ZXN0ElkKEmVhZ2VyX3JlY2VpdmVfbW9kZRgDIAEo
CzIpLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5FYWdlck1vZGVIAFIQZWFnZXJS
ZWNlaXZlTW9kZRJoChdjb250cm9sbGVkX3JlY2VpdmVfbW9kZRgEIAEoCzIuLmdvb2dsZS5j
bG91ZC52aXNpb25haS52MWFscGhhMS5Db250cm9sbGVkTW9kZUgAUhVjb250cm9sbGVkUmVj
ZWl2ZU1vZGUSSwoIbWV0YWRhdGEYASABKAsyLy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFh
bHBoYTEuUmVxdWVzdE1ldGFkYXRhUghtZXRhZGF0YRIaCghyZWNlaXZlchgCIAEoCVIIcmVj
ZWl2ZXISSAoSaGVhcnRiZWF0X2ludGVydmFsGAUgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1
cmF0aW9uUhFoZWFydGJlYXRJbnRlcnZhbBJSChh3cml0ZXNfZG9uZV9ncmFjZV9wZXJpb2QY
BiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SFXdyaXRlc0RvbmVHcmFjZVBlcmlv
ZEIPCg1jb25zdW1lcl9tb2RlQgkKB3JlcXVlc3QifAodUmVjZWl2ZVBhY2tldHNDb250cm9s
UmVzcG9uc2USHgoJaGVhcnRiZWF0GAEgASgISABSCWhlYXJ0YmVhdBIwChN3cml0ZXNfZG9u
ZV9yZXF1ZXN0GAIgASgISABSEXdyaXRlc0RvbmVSZXF1ZXN0QgkKB2NvbnRyb2wiwQEKFlJl
Y2VpdmVQYWNrZXRzUmVzcG9uc2USQAoGcGFja2V0GAEgASgLMiYuZ29vZ2xlLmNsb3VkLnZp
c2lvbmFpLnYxYWxwaGExLlBhY2tldEgAUgZwYWNrZXQSWQoHY29udHJvbBgDIAEoCzI9Lmdv
b2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5SZWNlaXZlUGFja2V0c0NvbnRyb2xSZXNw
b25zZUgAUgdjb250cm9sQgoKCHJlc3BvbnNlIgsKCUVhZ2VyTW9kZSKXAQoOQ29udHJvbGxl
ZE1vZGUSOAoXc3RhcnRpbmdfbG9naWNhbF9vZmZzZXQYASABKAlIAFIVc3RhcnRpbmdMb2dp
Y2FsT2Zmc2V0EjgKGGZhbGxiYWNrX3N0YXJ0aW5nX29mZnNldBgCIAEoCVIWZmFsbGJhY2tT
dGFydGluZ09mZnNldEIRCg9zdGFydGluZ19vZmZzZXQiJwoNQ29tbWl0UmVxdWVzdBIWCgZv
ZmZzZXQYASABKANSBm9mZnNldCpVCglMZWFzZVR5cGUSGgoWTEVBU0VfVFlQRV9VTlNQRUNJ
RklFRBAAEhUKEUxFQVNFX1RZUEVfUkVBREVSEAESFQoRTEVBU0VfVFlQRV9XUklURVIQAjK/
CAoQU3RyZWFtaW5nU2VydmljZRJ8CgtTZW5kUGFja2V0cxIyLmdvb2dsZS5jbG91ZC52aXNp
b25haS52MWFscGhhMS5TZW5kUGFja2V0c1JlcXVlc3QaMy5nb29nbGUuY2xvdWQudmlzaW9u
YWkudjFhbHBoYTEuU2VuZFBhY2tldHNSZXNwb25zZSIAKAEwARKFAQoOUmVjZWl2ZVBhY2tl
dHMSNS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuUmVjZWl2ZVBhY2tldHNSZXF1
ZXN0GjYuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLlJlY2VpdmVQYWNrZXRzUmVz
cG9uc2UiACgBMAESggEKDVJlY2VpdmVFdmVudHMSNC5nb29nbGUuY2xvdWQudmlzaW9uYWku
djFhbHBoYTEuUmVjZWl2ZUV2ZW50c1JlcXVlc3QaNS5nb29nbGUuY2xvdWQudmlzaW9uYWku
djFhbHBoYTEuUmVjZWl2ZUV2ZW50c1Jlc3BvbnNlIgAoATABEsEBCgxBY3F1aXJlTGVhc2US
My5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQWNxdWlyZUxlYXNlUmVxdWVzdBol
Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5MZWFzZSJVgtPkkwJPIkovdjFhbHBo
YTEve3Nlcmllcz1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NsdXN0ZXJzLyovc2VyaWVzLyp9
OmFjcXVpcmVMZWFzZToBKhK7AQoKUmVuZXdMZWFzZRIxLmdvb2dsZS5jbG91ZC52aXNpb25h
aS52MWFscGhhMS5SZW5ld0xlYXNlUmVxdWVzdBolLmdvb2dsZS5jbG91ZC52aXNpb25haS52
MWFscGhhMS5MZWFzZSJTgtPkkwJNIkgvdjFhbHBoYTEve3Nlcmllcz1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2NsdXN0ZXJzLyovc2VyaWVzLyp9OnJlbmV3TGVhc2U6ASoS0AEKDFJlbGVh
c2VMZWFzZRIzLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5SZWxlYXNlTGVhc2VS
ZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLlJlbGVhc2VMZWFzZVJl
c3BvbnNlIlWC0+STAk8iSi92MWFscGhhMS97c2VyaWVzPXByb2plY3RzLyovbG9jYXRpb25z
LyovY2x1c3RlcnMvKi9zZXJpZXMvKn06cmVsZWFzZUxlYXNlOgEqGkvKQRd2aXNpb25haS5n
b29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm1C4wEKImNvbS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTFCFVN0cmVh
bWluZ1NlcnZpY2VQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL3Zpc2lvbmFpL2FwaXYx
YWxwaGExL3Zpc2lvbmFpcGI7dmlzaW9uYWlwYqoCHkdvb2dsZS5DbG91ZC5WaXNpb25BSS5W
MUFscGhhMcoCHkdvb2dsZVxDbG91ZFxWaXNpb25BSVxWMWFscGhhMeoCIUdvb2dsZTo6Q2xv
dWQ6OlZpc2lvbkFJOjpWMWFscGhhMUrJXQoHEgUOAJoDAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwIS
AxQAQgoJCgIDAxIDFQAoCgkKAgMEEgMWACkKCAoBCBIDGAA7CgkKAgglEgMYADsKCAoBCBID
GQBVCgkKAggLEgMZAFUKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA2CgkKAggIEgMb
ADYKCAoBCBIDHAA7CgkKAggBEgMcADsKCAoBCBIDHQA7CgkKAggpEgMdADsKCAoBCBIDHgA6
CgkKAggtEgMeADoKQgoCBgASBCEASAEaNiBTdHJlYW1pbmcgc2VydmljZSBmb3IgcmVjZWl2
aW5nIGFuZCBzZW5kaW5nIHBhY2tldHMuCgoKCgMGAAESAyEIGAoKCgMGAAMSAyICPwoMCgUG
AAOZCBIDIgI/CgoKAwYAAxIDIwJWCgwKBQYAA5oIEgMjAlYKKwoEBgACABIEJgInAxodIFNl
bmQgcGFja2V0cyB0byB0aGUgc2VyaWVzLgoKDAoFBgACAAESAyYGEQoMCgUGAAIABRIDJhIY
CgwKBQYAAgACEgMmGSsKDAoFBgACAAYSAyY2PAoMCgUGAAIAAxIDJj1QCjAKBAYAAgESBCoC
KwMaIiBSZWNlaXZlIHBhY2tldHMgZnJvbSB0aGUgc2VyaWVzLgoKDAoFBgACAQESAyoGFAoM
CgUGAAIBBRIDKhUbCgwKBQYAAgECEgMqHDEKDAoFBgACAQYSAyo8QgoMCgUGAAIBAxIDKkNZ
CjUKBAYAAgISBC4CLwMaJyBSZWNlaXZlIGV2ZW50cyBnaXZlbiB0aGUgc3RyZWFtIG5hbWUu
CgoMCgUGAAICARIDLgYTCgwKBQYAAgIFEgMuFBoKDAoFBgACAgISAy4bLwoMCgUGAAICBhID
LjpACgwKBQYAAgIDEgMuQVYKLgoEBgACAxIEMgI3AxogIEFjcXVpcmVMZWFzZSBhY3F1aXJl
cyBhIGxlYXNlLgoKDAoFBgACAwESAzIGEgoMCgUGAAIDAhIDMhMmCgwKBQYAAgMDEgMyMTYK
DQoFBgACAwQSBDMENgYKEQoJBgACAwSwyrwiEgQzBDYGCioKBAYAAgQSBDoCPwMaHCBSZW5l
d0xlYXNlIHJlbmV3cyBhIGxlYXNlLgoKDAoFBgACBAESAzoGEAoMCgUGAAIEAhIDOhEiCgwK
BQYAAgQDEgM6LTIKDQoFBgACBAQSBDsEPgYKEQoJBgACBASwyrwiEgQ7BD4GCi0KBAYAAgUS
BEICRwMaHyBSbGVhc2VMZWFzZSByZWxlYXNlcyBhIGxlYXNlLgoKDAoFBgACBQESA0IGEgoM
CgUGAAIFAhIDQhMmCgwKBQYAAgUDEgNCMUUKDQoFBgACBQQSBEMERgYKEQoJBgACBQSwyrwi
EgRDBEYGCh0KAgUAEgRLAFQBGhEgVGhlIGxlYXNlIHR5cGUuCgoKCgMFAAESA0sFDgomCgQF
AAIAEgNNAh0aGSBMZWFzZSB0eXBlIHVuc3BlY2lmaWVkLgoKDAoFBQACAAESA00CGAoMCgUF
AAIAAhIDTRscCicKBAUAAgESA1ACGBoaIExlYXNlIGZvciBzdHJlYW0gcmVhZGVyLgoKDAoF
BQACAQESA1ACEwoMCgUFAAIBAhIDUBYXCicKBAUAAgISA1MCGBoaIExlYXNlIGZvciBzdHJl
YW0gd3JpdGVyLgoKDAoFBQACAgESA1MCEwoMCgUFAAICAhIDUxYXCjEKAgQAEgVXAIEBARok
IFJlcXVlc3QgbWVzc2FnZSBmb3IgUmVjZWl2ZUV2ZW50cy4KCgoKAwQAARIDVwgcCmMKBAQA
AwASBFoCeAMaVSBTZXR1cFJlcXVlc3QgaXMgdGhlIGZpcnN0IG1lc3NhZ2Ugc2VudCB0byB0
aGUgc2VydmljZSB0byBzZXR1cCB0aGUgUlBDCiBjb25uZWN0aW9uLgoKDAoFBAADAAESA1oK
FgoiCgYEAAMAAgASA1wEFxoTIFRoZSBjbHVzdGVyIG5hbWUuCgoOCgcEAAMAAgAFEgNcBAoK
DgoHBAADAAIAARIDXAsSCg4KBwQAAwACAAMSA1wVFgpaCgYEAAMAAgESA18EFhpLIFRoZSBz
dHJlYW0gbmFtZS4gVGhlIHNlcnZpY2Ugd2lsbCByZXR1cm4gdGhlIGV2ZW50cyBmb3IgdGhl
IGdpdmVuIHN0cmVhbS4KCg4KBwQAAwACAQUSA18ECgoOCgcEAAMAAgEBEgNfCxEKDgoHBAAD
AAIBAxIDXxQVCnYKBgQAAwACAhIDZAQYGmcgQSBuYW1lIGZvciB0aGUgcmVjZWl2ZXIgdG8g
c2VsZi1pZGVudGlmeS4KCiBUaGlzIGlzIHVzZWQgdG8ga2VlcCB0cmFjayBvZiBhIHJlY2Vp
dmVyJ3MgcmVhZCBwcm9ncmVzcy4KCg4KBwQAAwACAgUSA2QECgoOCgcEAAMAAgIBEgNkCxMK
DgoHBAADAAICAxIDZBYXClQKBgQAAwACAxIDZwQnGkUgQ29udHJvbGxlciBtb2RlIGNvbmZp
Z3VyYXRpb24gZm9yIHJlY2VpdmluZyBldmVudHMgZnJvbSB0aGUgc2VydmVyLgoKDgoHBAAD
AAIDBhIDZwQSCg4KBwQAAwACAwESA2cTIgoOCgcEAAMAAgMDEgNnJSYKqwIKBgQAAwACBBID
bwQ0GpsCIFRoZSBtYXhpbXVtIGR1cmF0aW9uIG9mIHNlcnZlciBzaWxlbmNlIGJlZm9yZSB0
aGUgY2xpZW50IGRldGVybWluZXMgdGhlCiBzZXJ2ZXIgdW5yZWFjaGFibGUuCgogVGhlIGNs
aWVudCBtdXN0IGVpdGhlciByZWNlaXZlIGFuIGBFdmVudGAgdXBkYXRlIG9yIGEgaGVhcnQg
YmVhdCBtZXNzYWdlCiBiZWZvcmUgdGhpcyBkdXJhdGlvbiBleHBpcmVzOyBvdGhlcndpc2Us
IHRoZSBjbGllbnQgd2lsbCBhdXRvbWF0aWNhbGx5CiBjYW5jZWwgdGhlIGN1cnJlbnQgY29u
bmVjdGlvbiBhbmQgcmV0cnkuCgoOCgcEAAMAAgQGEgNvBBwKDgoHBAADAAIEARIDbx0vCg4K
BwQAAwACBAMSA28yMwrqAQoGBAADAAIFEgN3BDoa2gEgVGhlIGdyYWNlIHBlcmlvZCBhZnRl
ciB3aGljaCBhIGB3cml0ZXNfZG9uZV9yZXF1ZXN0YCBpcyBpc3N1ZWQsIHRoYXQgYQogYFdy
aXRlc0RvbmVgIGlzIGV4cGVjdGVkIGZyb20gdGhlIGNsaWVudC4KCiBUaGUgc2VydmVyIGlz
IGZyZWUgdG8gY2FuY2VsIHRoZSBSUEMgc2hvdWxkIHRoaXMgZXhwaXJlLgoKIEEgc3lzdGVt
IGRlZmF1bHQgd2lsbCBiZSBjaG9zZW4gaWYgdW5zZXQuCgoOCgcEAAMAAgUGEgN3BBwKDgoH
BAADAAIFARIDdx01Cg4KBwQAAwACBQMSA3c4OQoNCgQEAAgAEgV6AoABAwoMCgUEAAgAARID
eggPCj0KBAQAAgASA3wEIxowIFRoZSBzZXR1cCByZXF1ZXN0IHRvIHNldHVwIHRoZSBSUEMg
Y29ubmVjdGlvbi4KCgwKBQQAAgAGEgN8BBAKDAoFBAACAAESA3wRHgoMCgUEAAIAAxIDfCEi
CkUKBAQAAgESA38EJRo4IFRoaXMgcmVxdWVzdCBjaGVja3BvaW50cyB0aGUgY29uc3VtZXIn
cyByZWFkIHByb2dyZXNzLgoKDAoFBAACAQYSA38EEQoMCgUEAAIBARIDfxIgCgwKBQQAAgED
EgN/IyQKKQoCBAESBoQBAJQBARobIFRoZSBldmVudCB1cGRhdGUgbWVzc2FnZS4KCgsKAwQB
ARIEhAEIEwpFCgQEAQIAEgSGAQIUGjcgVGhlIG5hbWUgb2YgdGhlIHN0cmVhbSB0aGF0IHRo
ZSBldmVudCBpcyBhdHRhY2hlZCB0by4KCg0KBQQBAgAFEgSGAQIICg0KBQQBAgABEgSGAQkP
Cg0KBQQBAgADEgSGARITCiYKBAQBAgESBIkBAhMaGCBUaGUgbmFtZSBvZiB0aGUgZXZlbnQu
CgoNCgUEAQIBBRIEiQECCAoNCgUEAQIBARIEiQEJDgoNCgUEAQIBAxIEiQEREgonCgQEAQIC
EgSMAQIUGhkgVGhlIG5hbWUgb2YgdGhlIHNlcmllcy4KCg0KBQQBAgIFEgSMAQIICg0KBQQB
AgIBEgSMAQkPCg0KBQQBAgIDEgSMARITCjwKBAQBAgMSBI8BAiwaLiBUaGUgdGltZXN0YW1w
IHdoZW4gdGhlIEV2ZW50IHVwZGF0ZSBoYXBwZW5zLgoKDQoFBAECAwYSBI8BAhsKDQoFBAEC
AwESBI8BHCcKDQoFBAECAwMSBI8BKisKZQoEBAECBBIEkwECExpXIFRoZSBvZmZzZXQgb2Yg
dGhlIG1lc3NhZ2UgdGhhdCB3aWxsIGJlIHVzZWQgdG8gYWNrbm93bGVkZ2Ugb2YgdGhlIG1l
c3NhZ2UKIHJlY2VpdmluZy4KCg0KBQQBAgQFEgSTAQIHCg0KBQQBAgQBEgSTAQgOCg0KBQQB
AgQDEgSTARESCjwKAgQCEgaXAQCoAQEaLiBDb250cm9sIG1lc3NhZ2UgZm9yIGEgUmVjZWl2
ZUV2ZW50c1Jlc3BvbnNlLgoKCwoDBAIBEgSXAQgkCiwKBAQCCAASBpkBAqcBAxocIFBvc3Np
YmxlIGNvbnRyb2wgbWVzc2FnZXMuCgoNCgUEAggAARIEmQEIDwojCgQEAgIAEgSbAQQXGhUg
QSBzZXJ2ZXIgaGVhcnRiZWF0LgoKDQoFBAICAAUSBJsBBAgKDQoFBAICAAESBJsBCRIKDQoF
BAICAAMSBJsBFRYKvgMKBAQCAgESBKYBBCEarwMgQSByZXF1ZXN0IHRvIHRoZSByZWNlaXZl
ciB0byBjb21wbGV0ZSBhbnkgZmluYWwgd3JpdGVzIGZvbGxvd2VkIGJ5IGEKIGBXcml0ZXNE
b25lYDsgZS5nLiBpc3N1ZSBhbnkgZmluYWwgYENvbW1pdFJlcXVlc3Rgcy4KCiBNYXkgYmUg
aWdub3JlZCBpZiBgV3JpdGVzRG9uZWAgaGFzIGFscmVhZHkgYmVlbiBpc3N1ZWQgYXQgYW55
IHBvaW50CiBwcmlvciB0byByZWNlaXZpbmcgdGhpcyBtZXNzYWdlLgoKIElmIGBXcml0ZXNE
b25lYCBkb2VzIG5vdCBnZXQgaXNzdWVkLCB0aGVuIHRoZSBzZXJ2ZXIgd2lsbCBmb3JjZWZ1
bGx5CiBjYW5jZWwgdGhlIGNvbm5lY3Rpb24sIGFuZCB0aGUgcmVjZWl2ZXIgd2lsbCBsaWtl
bHkgcmVjZWl2ZSBhbgogdW5pbmZvcm1hdGl2ZSBhZnRlciBgUmVhZGAgcmV0dXJucyBgZmFs
c2VgIGFuZCBgRmluaXNoYCBpcyBjYWxsZWQuCgoNCgUEAgIBBRIEpgEECAoNCgUEAgIBARIE
pgEJHAoNCgUEAgIBAxIEpgEfIAo3CgIEAxIGqwEAtAEBGikgUmVzcG9uc2UgbWVzc2FnZSBm
b3IgdGhlIFJlY2VpdmVFdmVudHMuCgoLCgMEAwESBKsBCB0KKgoEBAMIABIGrQECswEDGhog
UG9zc2libGUgcmVzcG9uc2UgdHlwZXMuCgoNCgUEAwgAARIErQEIEAopCgQEAwIAEgSvAQQh
GhsgVGhlIGV2ZW50IHVwZGF0ZSBtZXNzYWdlLgoKDQoFBAMCAAYSBK8BBA8KDQoFBAMCAAES
BK8BEBwKDQoFBAMCAAMSBK8BHyAKMgoEBAMCARIEsgEELRokIEEgY29udHJvbCBtZXNzYWdl
IGZyb20gdGhlIHNlcnZlci4KCg0KBQQDAgEGEgSyAQQgCg0KBQQDAgEBEgSyASEoCg0KBQQD
AgEDEgSyASssCiIKAgQEEga3AQDGAQEaFCBUaGUgbGVhc2UgbWVzc2FnZS4KCgsKAwQEARIE
twEIDQodCgQEBAIAEgS5AQIQGg8gVGhlIGxlYXNlIGlkLgoKDQoFBAQCAAUSBLkBAggKDQoF
BAQCAAESBLkBCQsKDQoFBAQCAAMSBLkBDg8KIAoEBAQCARIEvAECFBoSIFRoZSBzZXJpZXMg
bmFtZS4KCg0KBQQEAgEFEgS8AQIICg0KBQQEAgEBEgS8AQkPCg0KBQQEAgEDEgS8ARITCh8K
BAQEAgISBL8BAhMaESBUaGUgb3duZXIgbmFtZS4KCg0KBQQEAgIFEgS/AQIICg0KBQQEAgIB
EgS/AQkOCg0KBQQEAgIDEgS/ARESCiYKBAQEAgMSBMIBAiwaGCBUaGUgbGVhc2UgZXhwaXJl
IHRpbWUuCgoNCgUEBAIDBhIEwgECGwoNCgUEBAIDARIEwgEcJwoNCgUEBAIDAxIEwgEqKwof
CgQEBAIEEgTFAQIbGhEgVGhlIGxlYXNlIHR5cGUuCgoNCgUEBAIEBhIExQECCwoNCgUEBAIE
ARIExQEMFgoNCgUEBAIEAxIExQEZGgo2CgIEBRIGyQEA1QEBGiggUmVxdWVzdCBtZXNzYWdl
IGZvciBhY3F1aXJpbmcgYSBsZWFzZS4KCgsKAwQFARIEyQEIGwogCgQEBQIAEgTLAQIUGhIg
VGhlIHNlcmllcyBuYW1lLgoKDQoFBAUCAAUSBMsBAggKDQoFBAUCAAESBMsBCQ8KDQoFBAUC
AAMSBMsBEhMKHwoEBAUCARIEzgECExoRIFRoZSBvd25lciBuYW1lLgoKDQoFBAUCAQUSBM4B
AggKDQoFBAUCAQESBM4BCQ4KDQoFBAUCAQMSBM4BERIKHwoEBAUCAhIE0QECJBoRIFRoZSBs
ZWFzZSB0ZXJtLgoKDQoFBAUCAgYSBNEBAhoKDQoFBAUCAgESBNEBGx8KDQoFBAUCAgMSBNEB
IiMKHwoEBAUCAxIE1AECGxoRIFRoZSBsZWFzZSB0eXBlLgoKDQoFBAUCAwYSBNQBAgsKDQoF
BAUCAwESBNQBDBYKDQoFBAUCAwMSBNQBGRoKNQoCBAYSBtgBAOQBARonIFJlcXVlc3QgbWVz
c2FnZSBmb3IgcmVuZXdpbmcgYSBsZWFzZS4KCgsKAwQGARIE2AEIGQoZCgQEBgIAEgTaAQIQ
GgsgTGVhc2UgaWQuCgoNCgUEBgIABRIE2gECCAoNCgUEBgIAARIE2gEJCwoNCgUEBgIAAxIE
2gEODwocCgQEBgIBEgTdAQIUGg4gU2VyaWVzIG5hbWUuCgoNCgUEBgIBBRIE3QECCAoNCgUE
BgIBARIE3QEJDwoNCgUEBgIBAxIE3QESEwocCgQEBgICEgTgAQITGg4gTGVhc2Ugb3duZXIu
CgoNCgUEBgICBRIE4AECCAoNCgUEBgICARIE4AEJDgoNCgUEBgICAxIE4AEREgobCgQEBgID
EgTjAQIkGg0gTGVhc2UgdGVybS4KCg0KBQQGAgMGEgTjAQIaCg0KBQQGAgMBEgTjARsfCg0K
BQQGAgMDEgTjASIjCjQKAgQHEgbnAQDwAQEaJiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHJlbGVh
c2luZyBsZWFzZS4KCgsKAwQHARIE5wEIGwoZCgQEBwIAEgTpAQIQGgsgTGVhc2UgaWQuCgoN
CgUEBwIABRIE6QECCAoNCgUEBwIAARIE6QEJCwoNCgUEBwIAAxIE6QEODwocCgQEBwIBEgTs
AQIUGg4gU2VyaWVzIG5hbWUuCgoNCgUEBwIBBRIE7AECCAoNCgUEBwIBARIE7AEJDwoNCgUE
BwIBAxIE7AESEwocCgQEBwICEgTvAQITGg4gTGVhc2Ugb3duZXIuCgoNCgUEBwICBRIE7wEC
CAoNCgUEBwICARIE7wEJDgoNCgUEBwICAxIE7wEREgozCgIECBIG8wEA9QEBGiUgUmVzcG9u
c2UgbWVzc2FnZSBmb3IgcmVsZWFzZSBsZWFzZS4KCgsKAwQIARIE8wEIHApICgIECRIG+AEA
jQIBGjogUmVxdWVzdE1ldGFkYXRhIGlzIHRoZSBtZXRhZGF0YSBtZXNzYWdlIGZvciB0aGUg
cmVxdWVzdC4KCgsKAwQJARIE+AEIFwocCgQECQIAEgT6AQIUGg4gU3RyZWFtIG5hbWUuCgoN
CgUECQIABRIE+gECCAoNCgUECQIAARIE+gEJDwoNCgUECQIAAxIE+gESEwobCgQECQIBEgT9
AQITGg0gRXZldnQgbmFtZS4KCg0KBQQJAgEFEgT9AQIICg0KBQQJAgEBEgT9AQkOCg0KBQQJ
AgEDEgT9ARESChwKBAQJAgISBIACAhQaDiBTZXJpZXMgbmFtZS4KCg0KBQQJAgIFEgSAAgII
Cg0KBQQJAgIBEgSAAgkPCg0KBQQJAgIDEgSAAhITChkKBAQJAgMSBIMCAhYaCyBMZWFzZSBp
ZC4KCg0KBQQJAgMFEgSDAgIICg0KBQQJAgMBEgSDAgkRCg0KBQQJAgMDEgSDAhQVChsKBAQJ
AgQSBIYCAhMaDSBPd25lciBuYW1lLgoKDQoFBAkCBAUSBIYCAggKDQoFBAkCBAESBIYCCQ4K
DQoFBAkCBAMSBIYCERIKjwIKBAQJAgUSBIwCAioagAIgTGVhc2UgdGVybSBzcGVjaWZpZXMg
aG93IGxvbmcgdGhlIGNsaWVudCB3YW50cyB0aGUgc2Vzc2lvbiB0byBiZSBtYWludGFpbmVk
CiBieSB0aGUgc2VydmVyIGFmdGVyIHRoZSBjbGllbnQgbGVhdmVzLiBJZiB0aGUgbGVhc2Ug
dGVybSBpcyBub3Qgc2V0LCB0aGUKIHNlcnZlciB3aWxsIHJlbGVhc2UgdGhlIHNlc3Npb24g
aW1tZWRpYXRlbHkgYW5kIHRoZSBjbGllbnQgY2Fubm90IHJlY29ubmVjdAogdG8gdGhlIHNh
bWUgc2Vzc2lvbiBsYXRlci4KCg0KBQQJAgUGEgSMAgIaCg0KBQQJAgUBEgSMAhslCg0KBQQJ
AgUDEgSMAigpCjQKAgQKEgaQAgCYAgEaJiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHNlbmRpbmcg
cGFja2V0cy4KCgsKAwQKARIEkAIIGgoOCgQECggAEgaRAgKXAgMKDQoFBAoIAAESBJECCA8K
NAoEBAoCABIEkwIEFhomIFBhY2tldHMgc2VudCBvdmVyIHRoZSBzdHJlYW1pbmcgcnBjLgoK
DQoFBAoCAAYSBJMCBAoKDQoFBAoCAAESBJMCCxEKDQoFBAoCAAMSBJMCFBUKVgoEBAoCARIE
lgIEIRpIIFRoZSBmaXJzdCBtZXNzYWdlIG9mIHRoZSBzdHJlYW1pbmcgcnBjIGluY2x1ZGlu
ZyB0aGUgcmVxdWVzdCBtZXRhZGF0YS4KCg0KBQQKAgEGEgSWAgQTCg0KBQQKAgEBEgSWAhQc
Cg0KBQQKAgEDEgSWAh8gCjUKAgQLEgabAgCdAgEaJyBSZXNwb25zZSBtZXNzYWdlIGZvciBz
ZW5kaW5nIHBhY2tldHMuCgoLCgMECwESBJsCCBsKNgoCBAwSBqACAM8CARooIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgcmVjZWl2aW5nIHBhY2tldHMuCgoLCgMEDAESBKACCB0KXQoEBAwDABIG
ogICwwIDGk0gVGhlIG1lc3NhZ2Ugc3BlY2lmeWluZyB0aGUgaW5pdGlhbCBzZXR0aW5ncyBm
b3IgdGhlIFJlY2VpdmVQYWNrZXRzIHNlc3Npb24uCgoNCgUEDAMAARIEogIKFgpCCgYEDAMA
CAASBqQCBKoCBRowIFRoZSBtb2RlIGluIHdoaWNoIHRoZSBjb25zdW1lciByZWFkcyBtZXNz
YWdlcy4KCg8KBwQMAwAIAAESBKQCChcKNQoGBAwDAAIAEgSmAgYnGiUgT3B0aW9ucyBmb3Ig
Y29uZmlndXJpbmcgZWFnZXIgbW9kZS4KCg8KBwQMAwACAAYSBKYCBg8KDwoHBAwDAAIAARIE
pgIQIgoPCgcEDAMAAgADEgSmAiUmCjoKBgQMAwACARIEqQIGMRoqIE9wdGlvbnMgZm9yIGNv
bmZpZ3VyaW5nIGNvbnRyb2xsZWQgbW9kZS4KCg8KBwQMAwACAQYSBKkCBhQKDwoHBAwDAAIB
ARIEqQIVLAoPCgcEDAMAAgEDEgSpAi8wCk4KBgQMAwACAhIErQIEIRo+IFRoZSBjb25maWd1
cmF0aW9ucyB0aGF0IHNwZWNpZnkgd2hlcmUgcGFja2V0cyBhcmUgcmV0cmlldmVkLgoKDwoH
BAwDAAICBhIErQIEEwoPCgcEDAMAAgIBEgStAhQcCg8KBwQMAwACAgMSBK0CHyAKdwoGBAwD
AAIDEgSyAgQYGmcgQSBuYW1lIGZvciB0aGUgcmVjZWl2ZXIgdG8gc2VsZi1pZGVudGlmeS4K
CiBUaGlzIGlzIHVzZWQgdG8ga2VlcCB0cmFjayBvZiBhIHJlY2VpdmVyJ3MgcmVhZCBwcm9n
cmVzcy4KCg8KBwQMAwACAwUSBLICBAoKDwoHBAwDAAIDARIEsgILEwoPCgcEDAMAAgMDEgSy
AhYXCqUCCgYEDAMAAgQSBLoCBDQalAIgVGhlIG1heGltdW0gZHVyYXRpb24gb2Ygc2VydmVy
IHNpbGVuY2UgYmVmb3JlIHRoZSBjbGllbnQgZGV0ZXJtaW5lcyB0aGUKIHNlcnZlciB1bnJl
YWNoYWJsZS4KCiBUaGUgY2xpZW50IG11c3QgZWl0aGVyIHJlY2VpdmUgYSBgUGFja2V0YCBv
ciBhIGhlYXJ0IGJlYXQgbWVzc2FnZSBiZWZvcmUKIHRoaXMgZHVyYXRpb24gZXhwaXJlczsg
b3RoZXJ3aXNlLCB0aGUgY2xpZW50IHdpbGwgYXV0b21hdGljYWxseSBjYW5jZWwKIHRoZSBj
dXJyZW50IGNvbm5lY3Rpb24gYW5kIHJldHJ5LgoKDwoHBAwDAAIEBhIEugIEHAoPCgcEDAMA
AgQBEgS6Ah0vCg8KBwQMAwACBAMSBLoCMjMK6wEKBgQMAwACBRIEwgIEOhraASBUaGUgZ3Jh
Y2UgcGVyaW9kIGFmdGVyIHdoaWNoIGEgYHdyaXRlc19kb25lX3JlcXVlc3RgIGlzIGlzc3Vl
ZCwgdGhhdCBhCiBgV3JpdGVzRG9uZWAgaXMgZXhwZWN0ZWQgZnJvbSB0aGUgY2xpZW50LgoK
IFRoZSBzZXJ2ZXIgaXMgZnJlZSB0byBjYW5jZWwgdGhlIFJQQyBzaG91bGQgdGhpcyBleHBp
cmUuCgogQSBzeXN0ZW0gZGVmYXVsdCB3aWxsIGJlIGNob3NlbiBpZiB1bnNldC4KCg8KBwQM
AwACBQYSBMICBBwKDwoHBAwDAAIFARIEwgIdNQoPCgcEDAMAAgUDEgTCAjg5CjkKBAQMCAAS
BsYCAs4CAxopIFBvc3NpYmxlIHJlcXVlc3QgdHlwZXMgZnJvbSB0aGUgY2xpZW50LgoKDQoF
BAwIAAESBMYCCA8KggEKBAQMAgASBMoCBCMadCBUaGUgcmVxdWVzdCB0byBzZXR1cCB0aGUg
aW5pdGlhbCBzdGF0ZSBvZiBzZXNzaW9uLgoKIFRoZSBjbGllbnQgbXVzdCBzZW5kIGFuZCBv
bmx5IHNlbmQgdGhpcyBhcyB0aGUgZmlyc3QgbWVzc2FnZS4KCg0KBQQMAgAGEgTKAgQQCg0K
BQQMAgABEgTKAhEeCg0KBQQMAgADEgTKAiEiCkYKBAQMAgESBM0CBCUaOCBUaGlzIHJlcXVl
c3QgY2hlY2twb2ludHMgdGhlIGNvbnN1bWVyJ3MgcmVhZCBwcm9ncmVzcy4KCg0KBQQMAgEG
EgTNAgQRCg0KBQQMAgEBEgTNAhIgCg0KBQQMAgEDEgTNAiMkCj0KAgQNEgbSAgDjAgEaLyBD
b250cm9sIG1lc3NhZ2UgZm9yIGEgUmVjZWl2ZVBhY2tldHNSZXNwb25zZS4KCgsKAwQNARIE
0gIIJQosCgQEDQgAEgbUAgLiAgMaHCBQb3NzaWJsZSBjb250cm9sIG1lc3NhZ2VzLgoKDQoF
BA0IAAESBNQCCA8KIwoEBA0CABIE1gIEFxoVIEEgc2VydmVyIGhlYXJ0YmVhdC4KCg0KBQQN
AgAFEgTWAgQICg0KBQQNAgABEgTWAgkSCg0KBQQNAgADEgTWAhUWCr4DCgQEDQIBEgThAgQh
Gq8DIEEgcmVxdWVzdCB0byB0aGUgcmVjZWl2ZXIgdG8gY29tcGxldGUgYW55IGZpbmFsIHdy
aXRlcyBmb2xsb3dlZCBieSBhCiBgV3JpdGVzRG9uZWA7IGUuZy4gaXNzdWUgYW55IGZpbmFs
IGBDb21taXRSZXF1ZXN0YHMuCgogTWF5IGJlIGlnbm9yZWQgaWYgYFdyaXRlc0RvbmVgIGhh
cyBhbHJlYWR5IGJlZW4gaXNzdWVkIGF0IGFueSBwb2ludAogcHJpb3IgdG8gcmVjZWl2aW5n
IHRoaXMgbWVzc2FnZS4KCiBJZiBgV3JpdGVzRG9uZWAgZG9lcyBub3QgZ2V0IGlzc3VlZCwg
dGhlbiB0aGUgc2VydmVyIHdpbGwgZm9yY2VmdWxseQogY2FuY2VsIHRoZSBjb25uZWN0aW9u
LCBhbmQgdGhlIHJlY2VpdmVyIHdpbGwgbGlrZWx5IHJlY2VpdmUgYW4KIHVuaW5mb3JtYXRp
dmUgYWZ0ZXIgYFJlYWRgIHJldHVybnMgYGZhbHNlYCBhbmQgYEZpbmlzaGAgaXMgY2FsbGVk
LgoKDQoFBA0CAQUSBOECBAgKDQoFBA0CAQESBOECCRwKDQoFBA0CAQMSBOECHyAKNQoCBA4S
BuYCAO8CARonIFJlc3BvbnNlIG1lc3NhZ2UgZnJvbSBSZWNlaXZlUGFja2V0cy4KCgsKAwQO
ARIE5gIIHgoqCgQEDggAEgboAgLuAgMaGiBQb3NzaWJsZSByZXNwb25zZSB0eXBlcy4KCg0K
BQQOCAABEgToAggQCkMKBAQOAgASBOoCBBYaNSBBIGdlbnVpbmUgZGF0YSBwYXlsb2FkIG9y
aWdpbmF0aW5nIGZyb20gdGhlIHNlbmRlci4KCg0KBQQOAgAGEgTqAgQKCg0KBQQOAgABEgTq
AgsRCg0KBQQOAgADEgTqAhQVCjIKBAQOAgESBO0CBC4aJCBBIGNvbnRyb2wgbWVzc2FnZSBm
cm9tIHRoZSBzZXJ2ZXIuCgoNCgUEDgIBBhIE7QIEIQoNCgUEDgIBARIE7QIiKQoNCgUEDgIB
AxIE7QIsLQo+CgIEDxIG8gIA9AIBGjAgVGhlIG9wdGlvbnMgZm9yIHJlY2VpdmVyIHVuZGVy
IHRoZSBlYWdlciBtb2RlLgoKCwoDBA8BEgTyAggRCkMKAgQQEgb3AgCRAwEaNSBUaGUgb3B0
aW9ucyBmb3IgcmVjZWl2ZXIgdW5kZXIgdGhlIGNvbnRyb2xsZWQgbW9kZS4KCgsKAwQQARIE
9wIIFgpECgQEEAgAEgb5AgKGAwMaNCBUaGlzIGlzIHRoZSBvZmZzZXQgZnJvbSB3aGljaCB0
byBzdGFydCByZWNlaXZlaW5nLgoKDQoFBBAIAAESBPkCCBcKogMKBAQQAgASBIUDBCcakwMg
VGhpcyBjYW4gYmUgc2V0IHRvIHRoZSBmb2xsb3dpbmcgbG9naWNhbCBzdGFydGluZyBwb2lu
dHM6CgogImJlZ2luIjogVGhpcyB3aWxsIHJlYWQgZnJvbSB0aGUgZWFybGllc3QgYXZhaWxh
YmxlIG1lc3NhZ2UuCgogIm1vc3QtcmVjZW50IjogVGhpcyB3aWxsIHJlYWQgZnJvbSB0aGUg
bGF0ZXN0IGF2YWlsYWJsZSBtZXNzYWdlLgoKICJlbmQiOiBUaGlzIHdpbGwgcmVhZCBvbmx5
IGZ1dHVyZSBtZXNzYWdlcy4KCiAic3RvcmVkIjogVGhpcyB3aWxsIHJlc3VtZSByZWFkcyBv
bmUgcGFzdCB0aGUgbGFzdCBjb21taXR0ZWQgb2Zmc2V0LgogICAgICAgICAgIEl0IGlzIHRo
ZSBvbmx5IG9wdGlvbiB0aGF0IHJlc3VtZXMgcHJvZ3Jlc3M7IGFsbCBvdGhlcnMKICAgICAg
ICAgICBqdW1wIHVuaWxhdGVyYWxseS4KCg0KBQQQAgAFEgSFAwQKCg0KBQQQAgABEgSFAwsi
Cg0KBQQQAgADEgSFAyUmCpICCgQEEAIBEgSQAwImGoMCIFRoaXMgaXMgdGhlIGxvZ2ljYWwg
c3RhcnRpbmcgcG9pbnQgdG8gZmFsbGJhY2sgdXBvbiBzaG91bGQgdGhlCiBzcGVjaWZpZWQg
c3RhcnRpbmcgb2Zmc2V0IGJlIHVuYXZhaWxhYmxlLgoKIFRoaXMgY2FuIGJlIG9uZSBvZiB0
aGUgZm9sbG93aW5nIHZhbHVlczoKCiAiYmVnaW4iOiBUaGlzIHdpbGwgcmVhZCBmcm9tIHRo
ZSBlYXJsaWVzdCBhdmFpbGFibGUgbWVzc2FnZS4KCiAiZW5kIjogVGhpcyB3aWxsIHJlYWQg
b25seSBmdXR1cmUgbWVzc2FnZXMuCgoNCgUEEAIBBRIEkAMCCAoNCgUEEAIBARIEkAMJIQoN
CgUEEAIBAxIEkAMkJQqrAQoCBBESBpcDAJoDARqcASBUaGUgbWVzc2FnZSBmb3IgZXhwbGlj
aXRseSBjb21taXR0aW5nIHRoZSByZWFkIHByb2dyZXNzLgoKIFRoaXMgbWF5IG9ubHkgYmUg
dXNlZCB3aGVuIGBSZWNlaXZlUGFja2V0c0NvbnRyb2xsZWRNb2RlYCBpcyBzZXQgaW4gdGhl
CiBpbml0aWFsIHNldHVwIHJlcXVlc3QuCgoLCgMEEQESBJcDCBUKJQoEBBECABIEmQMCExoX
IFRoZSBvZmZzZXQgdG8gY29tbWl0LgoKDQoFBBECAAUSBJkDAgcKDQoFBBECAAESBJkDCA4K
DQoFBBECAAMSBJkDERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest ===
    # Fields for ReceiveEventsRequest
    # Field: setup_request Type: 11 (.google.cloud.visionai.v1alpha1.ReceiveEventsRequest.SetupRequest)
    # Field: commit_request Type: 11 (.google.cloud.visionai.v1alpha1.CommitRequest)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::EventUpdate ===
    # Fields for EventUpdate
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()
    # Field: series Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: offset Type: 3 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsControlResponse ===
    # Fields for ReceiveEventsControlResponse
    # Field: heartbeat Type: 8 ()
    # Field: writes_done_request Type: 8 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsResponse ===
    # Fields for ReceiveEventsResponse
    # Field: event_update Type: 11 (.google.cloud.visionai.v1alpha1.EventUpdate)
    # Field: control Type: 11 (.google.cloud.visionai.v1alpha1.ReceiveEventsControlResponse)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::Lease ===
    # Fields for Lease
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: lease_type Type: 14 (.google.cloud.visionai.v1alpha1.LeaseType)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::AcquireLeaseRequest ===
    # Fields for AcquireLeaseRequest
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: term Type: 11 (.google.protobuf.Duration)
    # Field: lease_type Type: 14 (.google.cloud.visionai.v1alpha1.LeaseType)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::RenewLeaseRequest ===
    # Fields for RenewLeaseRequest
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: term Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseRequest ===
    # Fields for ReleaseLeaseRequest
    # Field: id Type: 9 ()
    # Field: series Type: 9 ()
    # Field: owner Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseResponse ===
    # Fields for ReleaseLeaseResponse

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::RequestMetadata ===
    # Fields for RequestMetadata
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()
    # Field: series Type: 9 ()
    # Field: lease_id Type: 9 ()
    # Field: owner Type: 9 ()
    # Field: lease_term Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsRequest ===
    # Fields for SendPacketsRequest
    # Field: packet Type: 11 (.google.cloud.visionai.v1alpha1.Packet)
    # Field: metadata Type: 11 (.google.cloud.visionai.v1alpha1.RequestMetadata)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsResponse ===
    # Fields for SendPacketsResponse

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsRequest ===
    # Fields for ReceivePacketsRequest
    # Field: setup_request Type: 11 (.google.cloud.visionai.v1alpha1.ReceivePacketsRequest.SetupRequest)
    # Field: commit_request Type: 11 (.google.cloud.visionai.v1alpha1.CommitRequest)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsControlResponse ===
    # Fields for ReceivePacketsControlResponse
    # Field: heartbeat Type: 8 ()
    # Field: writes_done_request Type: 8 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsResponse ===
    # Fields for ReceivePacketsResponse
    # Field: packet Type: 11 (.google.cloud.visionai.v1alpha1.Packet)
    # Field: control Type: 11 (.google.cloud.visionai.v1alpha1.ReceivePacketsControlResponse)

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::EagerMode ===
    # Fields for EagerMode

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::ControlledMode ===
    # Fields for ControlledMode
    # Field: starting_logical_offset Type: 9 ()
    # Field: fallback_starting_offset Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamingService::CommitRequest ===
    # Fields for CommitRequest
    # Field: offset Type: 3 ()

# === Service Client: Google::Cloud::Visionai::V1alpha1::StreamingService::StreamingServiceClient ===
package Google::Cloud::Visionai::V1alpha1::StreamingService::StreamingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Visionai::V1alpha1::StreamingService::StreamingServiceClient

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
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'SendPackets',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsResponse',
    });
}

sub receive_packets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'ReceivePackets',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsResponse',
    });
}

sub receive_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'ReceiveEvents',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsResponse',
    });
}

sub acquire_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::AcquireLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'AcquireLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::Lease',
    });
}

sub renew_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::RenewLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'RenewLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::Lease',
    });
}

sub release_lease {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.visionai.v1alpha1.StreamingService',
        method         => 'ReleaseLease',
        request        => $req,
        response_class => 'Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::StreamingService - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/streaming_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::StreamingService;

    my $msg = Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest->new({
        setup_request => $setup_request,
        commit_request => $commit_request,
    });

    # Read or update a field
    my $val = $msg->setup_request();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/streaming_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest

Request message for ReceiveEvents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->setup_request() >> / C<< $msg->setup_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsRequest::SetupRequest>)

The setup request to setup the RPC connection.

=item * C<< $msg->commit_request() >> / C<< $msg->commit_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::CommitRequest>)

This request checkpoints the consumer's read progress.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::EventUpdate

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsControlResponse

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsResponse

Response message for the ReceiveEvents.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_update() >> / C<< $msg->event_update($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::EventUpdate>)

The event update message.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::ReceiveEventsControlResponse>)

A control message from the server.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::Lease

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

Type: C<Enum> (L<Google::Cloud::Visionai::V1alpha1::LeaseType>)

The lease type.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::AcquireLeaseRequest

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

Type: C<Enum> (L<Google::Cloud::Visionai::V1alpha1::LeaseType>)

The lease type.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::RenewLeaseRequest

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseRequest

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReleaseLeaseResponse

Response message for release lease.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::RequestMetadata

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsRequest

Request message for sending packets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packet() >> / C<< $msg->packet($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet>)

Packets sent over the streaming rpc.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::RequestMetadata>)

The first message of the streaming rpc including the request metadata.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::SendPacketsResponse

Response message for sending packets.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsRequest

Request message for receiving packets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->setup_request() >> / C<< $msg->setup_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsRequest::SetupRequest>)

The request to setup the initial state of session.

The client must send and only send this as the first message.

=item * C<< $msg->commit_request() >> / C<< $msg->commit_request($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::CommitRequest>)

This request checkpoints the consumer's read progress.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsControlResponse

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsResponse

Response message from ReceivePackets.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->packet() >> / C<< $msg->packet($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingResources::Packet>)

A genuine data payload originating from the sender.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamingService::ReceivePacketsControlResponse>)

A control message from the server.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::EagerMode

The options for receiver under the eager mode.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::ControlledMode

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

=head2 Google::Cloud::Visionai::V1alpha1::StreamingService::CommitRequest

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::StreamingService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
