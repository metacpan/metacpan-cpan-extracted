package Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvdHJhbnNsYXRpb25f
dGFzay5wcm90bxInZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhIlgK
FlRyYW5zbGF0aW9uRmlsZU1hcHBpbmcSHQoKaW5wdXRfcGF0aBgBIAEoCVIJaW5wdXRQYXRo
Eh8KC291dHB1dF9wYXRoGAIgASgJUgpvdXRwdXRQYXRoIqkKChZUcmFuc2xhdGlvblRhc2tE
ZXRhaWxzEmUKEHRlcmFkYXRhX29wdGlvbnMYCiABKAsyOC5nb29nbGUuY2xvdWQuYmlncXVl
cnkubWlncmF0aW9uLnYyYWxwaGEuVGVyYWRhdGFPcHRpb25zSABSD3RlcmFkYXRhT3B0aW9u
cxJZCgxidGVxX29wdGlvbnMYCyABKAsyNC5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0
aW9uLnYyYWxwaGEuQnRlcU9wdGlvbnNIAFILYnRlcU9wdGlvbnMSHQoKaW5wdXRfcGF0aBgB
IAEoCVIJaW5wdXRQYXRoEh8KC291dHB1dF9wYXRoGAIgASgJUgpvdXRwdXRQYXRoEl4KCmZp
bGVfcGF0aHMYDCADKAsyPy5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxw
aGEuVHJhbnNsYXRpb25GaWxlTWFwcGluZ1IJZmlsZVBhdGhzEh8KC3NjaGVtYV9wYXRoGAMg
ASgJUgpzY2hlbWFQYXRoEnEKDWZpbGVfZW5jb2RpbmcYBCABKA4yTC5nb29nbGUuY2xvdWQu
YmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuVHJhbnNsYXRpb25UYXNrRGV0YWlscy5GaWxl
RW5jb2RpbmdSDGZpbGVFbmNvZGluZxJsChNpZGVudGlmaWVyX3NldHRpbmdzGAUgASgLMjsu
Z29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLklkZW50aWZpZXJTZXR0
aW5nc1ISaWRlbnRpZmllclNldHRpbmdzEoABChFzcGVjaWFsX3Rva2VuX21hcBgGIAMoCzJU
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5UcmFuc2xhdGlvblRh
c2tEZXRhaWxzLlNwZWNpYWxUb2tlbk1hcEVudHJ5Ug9zcGVjaWFsVG9rZW5NYXASRwoGZmls
dGVyGAcgASgLMi8uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLkZp
bHRlclIGZmlsdGVyEj4KG3RyYW5zbGF0aW9uX2V4Y2VwdGlvbl90YWJsZRgNIAEoCVIZdHJh
bnNsYXRpb25FeGNlcHRpb25UYWJsZRqNAQoUU3BlY2lhbFRva2VuTWFwRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSXwoFdmFsdWUYAiABKA4ySS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWln
cmF0aW9uLnYyYWxwaGEuVHJhbnNsYXRpb25UYXNrRGV0YWlscy5Ub2tlblR5cGVSBXZhbHVl
OgI4ASJ+CgxGaWxlRW5jb2RpbmcSHQoZRklMRV9FTkNPRElOR19VTlNQRUNJRklFRBAAEgkK
BVVURl84EAESDgoKSVNPXzg4NTlfMRACEgwKCFVTX0FTQ0lJEAMSCgoGVVRGXzE2EAQSDAoI
VVRGXzE2TEUQBRIMCghVVEZfMTZCRRAGInsKCVRva2VuVHlwZRIaChZUT0tFTl9UWVBFX1VO
U1BFQ0lGSUVEEAASCgoGU1RSSU5HEAESCQoFSU5UNjQQAhILCgdOVU1FUklDEAMSCAoEQk9P
TBAEEgsKB0ZMT0FUNjQQBRIICgREQVRFEAYSDQoJVElNRVNUQU1QEAdCEgoQbGFuZ3VhZ2Vf
b3B0aW9ucyJLCgZGaWx0ZXISQQodaW5wdXRfZmlsZV9leGNsdXNpb25fcHJlZml4ZXMYASAD
KAlSGmlucHV0RmlsZUV4Y2x1c2lvblByZWZpeGVzItcDChJJZGVudGlmaWVyU2V0dGluZ3MS
gAEKFm91dHB1dF9pZGVudGlmaWVyX2Nhc2UYASABKA4ySi5nb29nbGUuY2xvdWQuYmlncXVl
cnkubWlncmF0aW9uLnYyYWxwaGEuSWRlbnRpZmllclNldHRpbmdzLklkZW50aWZpZXJDYXNl
UhRvdXRwdXRJZGVudGlmaWVyQ2FzZRKJAQoXaWRlbnRpZmllcl9yZXdyaXRlX21vZGUYAiAB
KA4yUS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEuSWRlbnRpZmll
clNldHRpbmdzLklkZW50aWZpZXJSZXdyaXRlTW9kZVIVaWRlbnRpZmllclJld3JpdGVNb2Rl
IlUKDklkZW50aWZpZXJDYXNlEh8KG0lERU5USUZJRVJfQ0FTRV9VTlNQRUNJRklFRBAAEgwK
CE9SSUdJTkFMEAESCQoFVVBQRVIQAhIJCgVMT1dFUhADIlsKFUlkZW50aWZpZXJSZXdyaXRl
TW9kZRInCiNJREVOVElGSUVSX1JFV1JJVEVfTU9ERV9VTlNQRUNJRklFRBAAEggKBE5PTkUQ
ARIPCgtSRVdSSVRFX0FMTBACIhEKD1RlcmFkYXRhT3B0aW9ucyLiAgoLQnRlcU9wdGlvbnMS
YgoPcHJvamVjdF9kYXRhc2V0GAEgASgLMjkuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3Jh
dGlvbi52MmFscGhhLkRhdGFzZXRSZWZlcmVuY2VSDnByb2plY3REYXRhc2V0EigKEGRlZmF1
bHRfcGF0aF91cmkYAiABKAlSDmRlZmF1bHRQYXRoVXJpEn4KFGZpbGVfcmVwbGFjZW1lbnRf
bWFwGAMgAygLMkwuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MmFscGhhLkJ0
ZXFPcHRpb25zLkZpbGVSZXBsYWNlbWVudE1hcEVudHJ5UhJmaWxlUmVwbGFjZW1lbnRNYXAa
RQoXRmlsZVJlcGxhY2VtZW50TWFwRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ASJQChBEYXRhc2V0UmVmZXJlbmNlEh0KCmRhdGFzZXRfaWQYASAB
KAlSCWRhdGFzZXRJZBIdCgpwcm9qZWN0X2lkGAIgASgJUglwcm9qZWN0SWRC5AEKK2NvbS5n
b29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGFCFFRyYW5zbGF0aW9uVGFz
a1Byb3RvUAFaSWNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0aW9uL2FwaXYy
YWxwaGEvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAidHb29nbGUuQ2xvdWQuQmlnUXVlcnku
TWlncmF0aW9uLlYyQWxwaGHKAidHb29nbGVcQ2xvdWRcQmlnUXVlcnlcTWlncmF0aW9uXFYy
YWxwaGFKzDUKBxIFDgDOAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQADAKCAoBCBIDEgBECgkKAgglEgMSAEQKCAoBCBIDEwBgCgkKAggLEgMTAGAKCAoB
CBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA1CgkKAggIEgMVADUKCAoBCBIDFgBECgkKAggB
EgMWAEQKCAoBCBIDFwBFCgkKAggpEgMXAEUKVQoCBAASBBoAIAEaSSBNYXBwaW5nIGJldHdl
ZW4gYW4gaW5wdXQgYW5kIG91dHB1dCBmaWxlIHRvIGJlIHRyYW5zbGF0ZWQgaW4gYSBzdWJ0
YXNrLgoKCgoDBAABEgMaCB4KTQoEBAACABIDHAIYGkAgVGhlIENsb3VkIFN0b3JhZ2UgcGF0
aCBmb3IgYSBmaWxlIHRvIHRyYW5zbGF0aW9uIGluIGEgc3VidGFzay4KCgwKBQQAAgAFEgMc
AggKDAoFBAACAAESAxwJEwoMCgUEAAIAAxIDHBYXClQKBAQAAgESAx8CGRpHIFRoZSBDbG91
ZCBTdG9yYWdlIHBhdGggdG8gd3JpdGUgYmFjayB0aGUgY29ycmVzcG9uZGluZyBpbnB1dCBm
aWxlIHRvLgoKDAoFBAACAQUSAx8CCAoMCgUEAAIBARIDHwkUCgwKBQQAAgEDEgMfFxgKbQoC
BAESBSQAhAEBGmAgVGhlIHRyYW5zbGF0aW9uIHRhc2sgY29uZmlnIHRvIGNhcHR1cmUgbmVj
ZXNzYXJ5IHNldHRpbmdzIGZvciBhIHRyYW5zbGF0aW9uCiB0YXNrIGFuZCBzdWJ0YXNrLgoK
CgoDBAEBEgMkCB4KKAoEBAEEABIEJgI7AxoaIFRoZSBmaWxlIGVuY29kaW5nIHR5cGVzLgoK
DAoFBAEEAAESAyYHEwo4CgYEAQQAAgASAygEIhopIEZpbGUgZW5jb2Rpbmcgc2V0dGluZyBp
cyBub3Qgc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDKAQdCg4KBwQBBAACAAISAyggIQooCgYE
AQQAAgESAysEDhoZIEZpbGUgZW5jb2RpbmcgaXMgVVRGXzguCgoOCgcEAQQAAgEBEgMrBAkK
DgoHBAEEAAIBAhIDKwwNCi0KBgQBBAACAhIDLgQTGh4gRmlsZSBlbmNvZGluZyBpcyBJU09f
ODg1OV8xLgoKDgoHBAEEAAICARIDLgQOCg4KBwQBBAACAgISAy4REgorCgYEAQQAAgMSAzEE
ERocIEZpbGUgZW5jb2RpbmcgaXMgVVNfQVNDSUkuCgoOCgcEAQQAAgMBEgMxBAwKDgoHBAEE
AAIDAhIDMQ8QCikKBgQBBAACBBIDNAQPGhogRmlsZSBlbmNvZGluZyBpcyBVVEZfMTYuCgoO
CgcEAQQAAgQBEgM0BAoKDgoHBAEEAAIEAhIDNA0OCisKBgQBBAACBRIDNwQRGhwgRmlsZSBl
bmNvZGluZyBpcyBVVEZfMTZMRS4KCg4KBwQBBAACBQESAzcEDAoOCgcEAQQAAgUCEgM3DxAK
KwoGBAEEAAIGEgM6BBEaHCBGaWxlIGVuY29kaW5nIGlzIFVURl8xNkJFLgoKDgoHBAEEAAIG
ARIDOgQMCg4KBwQBBAACBgISAzoPEAosCgQEAQQBEgQ+AlYDGh4gVGhlIHNwZWNpYWwgdG9r
ZW4gZGF0YSB0eXBlLgoKDAoFBAEEAQESAz4HEAotCgYEAQQBAgASA0AEHxoeIFRva2VuIHR5
cGUgaXMgbm90IHNwZWNpZmllZC4KCg4KBwQBBAECAAESA0AEGgoOCgcEAQQBAgACEgNAHR4K
JgoGBAEEAQIBEgNDBA8aFyBUb2tlbiB0eXBlIGFzIHN0cmluZy4KCg4KBwQBBAECAQESA0ME
CgoOCgcEAQQBAgECEgNDDQ4KJwoGBAEEAQICEgNGBA4aGCBUb2tlbiB0eXBlIGFzIGludGVn
ZXIuCgoOCgcEAQQBAgIBEgNGBAkKDgoHBAEEAQICAhIDRgwNCicKBgQBBAECAxIDSQQQGhgg
VG9rZW4gdHlwZSBhcyBudW1lcmljLgoKDgoHBAEEAQIDARIDSQQLCg4KBwQBBAECAwISA0kO
DwonCgYEAQQBAgQSA0wEDRoYIFRva2VuIHR5cGUgYXMgYm9vbGVhbi4KCg4KBwQBBAECBAES
A0wECAoOCgcEAQQBAgQCEgNMCwwKJQoGBAEEAQIFEgNPBBAaFiBUb2tlbiB0eXBlIGFzIGZs
b2F0LgoKDgoHBAEEAQIFARIDTwQLCg4KBwQBBAECBQISA08ODwokCgYEAQQBAgYSA1IEDRoV
IFRva2VuIHR5cGUgYXMgZGF0ZS4KCg4KBwQBBAECBgESA1IECAoOCgcEAQQBAgYCEgNSCwwK
KQoGBAEEAQIHEgNVBBIaGiBUb2tlbiB0eXBlIGFzIHRpbWVzdGFtcC4KCg4KBwQBBAECBwES
A1UEDQoOCgcEAQQBAgcCEgNVEBEKSAoEBAEIABIEWQJfAxo6IFRoZSBsYW5ndWFnZSBzcGVj
aWZpYyBzZXR0aW5ncyBmb3IgdGhlIHRyYW5zbGF0aW9uIHRhc2suCgoMCgUEAQgAARIDWQgY
CksKBAQBAgASA1sEKho+IFRoZSBUZXJhZGF0YSBTUUwgc3BlY2lmaWMgc2V0dGluZ3MgZm9y
IHRoZSB0cmFuc2xhdGlvbiB0YXNrLgoKDAoFBAECAAYSA1sEEwoMCgUEAQIAARIDWxQkCgwK
BQQBAgADEgNbJykKQwoEBAECARIDXgQiGjYgVGhlIEJURVEgc3BlY2lmaWMgc2V0dGluZ3Mg
Zm9yIHRoZSB0cmFuc2xhdGlvbiB0YXNrLgoKDAoFBAECAQYSA14EDwoMCgUEAQIBARIDXhAc
CgwKBQQBAgEDEgNeHyEKQgoEBAECAhIDYgIYGjUgVGhlIENsb3VkIFN0b3JhZ2UgcGF0aCBm
b3IgdHJhbnNsYXRpb24gaW5wdXQgZmlsZXMuCgoMCgUEAQICBRIDYgIICgwKBQQBAgIBEgNi
CRMKDAoFBAECAgMSA2IWFwpDCgQEAQIDEgNlAhkaNiBUaGUgQ2xvdWQgU3RvcmFnZSBwYXRo
IGZvciB0cmFuc2xhdGlvbiBvdXRwdXQgZmlsZXMuCgoMCgUEAQIDBRIDZQIICgwKBQQBAgMB
EgNlCRQKDAoFBAECAwMSA2UXGApDCgQEAQIEEgNoAjIaNiBDbG91ZCBTdG9yYWdlIGZpbGVz
IHRvIGJlIHByb2Nlc3NlZCBmb3IgdHJhbnNsYXRpb24uCgoMCgUEAQIEBBIDaAIKCgwKBQQB
AgQGEgNoCyEKDAoFBAECBAESA2giLAoMCgUEAQIEAxIDaC8xCmMKBAQBAgUSA2wCGRpWIFRo
ZSBDbG91ZCBTdG9yYWdlIHBhdGggdG8gRERMIGZpbGVzIGFzIHRhYmxlIHNjaGVtYSB0byBh
c3Npc3Qgc2VtYW50aWMKIHRyYW5zbGF0aW9uLgoKDAoFBAECBQUSA2wCCAoMCgUEAQIFARID
bAkUCgwKBQQBAgUDEgNsFxgKJgoEBAECBhIDbwIhGhkgVGhlIGZpbGUgZW5jb2RpbmcgdHlw
ZS4KCgwKBQQBAgYGEgNvAg4KDAoFBAECBgESA28PHAoMCgUEAQIGAxIDbx8gCjAKBAQBAgcS
A3ICLRojIFRoZSBzZXR0aW5ncyBmb3IgU1FMIGlkZW50aWZpZXJzLgoKDAoFBAECBwYSA3IC
FAoMCgUEAQIHARIDchUoCgwKBQQBAgcDEgNyKywKxwMKBAQBAggSA3oCLxq5AyBUaGUgbWFw
IGNhcHR1cmluZyBzcGVjaWFsIHRva2VucyB0byBiZSByZXBsYWNlZCBkdXJpbmcgdHJhbnNs
YXRpb24uIFRoZSBrZXkKIGlzIHNwZWNpYWwgdG9rZW4gaW4gc3RyaW5nLiBUaGUgdmFsdWUg
aXMgdGhlIHRva2VuIGRhdGEgdHlwZS4gVGhpcyBpcyB1c2VkCiB0byB0cmFuc2xhdGUgU1FM
IHF1ZXJ5IHRlbXBsYXRlIHdoaWNoIGNvbnRhaW5zIHNwZWNpYWwgdG9rZW4gYXMgcGxhY2UK
IGhvbGRlci4gVGhlIHNwZWNpYWwgdG9rZW4gbWFrZXMgYSBxdWVyeSBpbnZhbGlkIHRvIHBh
cnNlLiBUaGlzIG1hcCB3aWxsIGJlCiBhcHBsaWVkIHRvIGFubm90YXRlIHRob3NlIHNwZWNp
YWwgdG9rZW4gd2l0aCB0eXBlcyB0byBsZXQgcGFyc2VyIHVuZGVyc3RhbmQKIGhvdyB0byBw
YXJzZSB0aGVtIGludG8gcHJvcGVyIHN0cnVjdHVyZSB3aXRoIHR5cGUgaW5mb3JtYXRpb24u
CgoMCgUEAQIIBhIDegIYCgwKBQQBAggBEgN6GSoKDAoFBAECCAMSA3otLgo5CgQEAQIJEgN9
AhQaLCBUaGUgZmlsdGVyIGFwcGxpZWQgdG8gdHJhbnNsYXRpb24gZGV0YWlscy4KCgwKBQQB
AgkGEgN9AggKDAoFBAECCQESA30JDwoMCgUEAQIJAxIDfRITCr8CCgQEAQIKEgSDAQIqGrAC
IFNwZWNpZmllcyB0aGUgZXhhY3QgbmFtZSBvZiB0aGUgYmlncXVlcnkgdGFibGUgKCJkYXRh
c2V0LnRhYmxlIikgdG8gYmUgdXNlZAogZm9yIHN1cmZhY2luZyByYXcgdHJhbnNsYXRpb24g
ZXJyb3JzLiBJZiB0aGUgdGFibGUgZG9lcyBub3QgZXhpc3QsIHdlIHdpbGwKIGNyZWF0ZSBp
dC4gSWYgaXQgYWxyZWFkeSBleGlzdHMgYW5kIHRoZSBzY2hlbWEgaXMgdGhlIHNhbWUsIHdl
IHdpbGwgcmUtdXNlLgogSWYgdGhlIHRhYmxlIGV4aXN0cyBhbmQgdGhlIHNjaGVtYSBpcyBk
aWZmZXJlbnQsIHdlIHdpbGwgdGhyb3cgYW4gZXJyb3IuCgoNCgUEAQIKBRIEgwECCAoNCgUE
AQIKARIEgwEJJAoNCgUEAQIKAxIEgwEnKQpECgIEAhIGhwEAigEBGjYgVGhlIGZpbHRlciBh
cHBsaWVkIHRvIGZpZWxkcyBvZiB0cmFuc2xhdGlvbiBkZXRhaWxzLgoKCwoDBAIBEgSHAQgO
ClAKBAQCAgASBIkBAjQaQiBUaGUgbGlzdCBvZiBwcmVmaXhlcyB1c2VkIHRvIGV4Y2x1ZGUg
cHJvY2Vzc2luZyBmb3IgaW5wdXQgZmlsZXMuCgoNCgUEAgIABBIEiQECCgoNCgUEAgIABRIE
iQELEQoNCgUEAgIAARIEiQESLwoNCgUEAgIAAxIEiQEyMwo0CgIEAxIGjQEArgEBGiYgU2V0
dGluZ3MgcmVsYXRlZCB0byBTUUwgaWRlbnRpZmllcnMuCgoLCgMEAwESBI0BCBoKKwoEBAME
ABIGjwECmwEDGhsgVGhlIGlkZW50aWZpZXIgY2FzZSB0eXBlLgoKDQoFBAMEAAESBI8BBxUK
NwoGBAMEAAIAEgSRAQQkGicgVGhlIGlkZW50aWZpZXIgY2FzZSBpcyBub3Qgc3BlY2lmaWVk
LgoKDwoHBAMEAAIAARIEkQEEHwoPCgcEAwQAAgACEgSRASIjCkgKBgQDBAACARIElAEEERo4
IElkZW50aWZpZXJzJyBjYXNlcyB3aWxsIGJlIGtlcHQgYXMgdGhlIG9yaWdpbmFsIGNhc2Vz
LgoKDwoHBAMEAAIBARIElAEEDAoPCgcEAwQAAgECEgSUAQ8QCjUKBgQDBAACAhIElwEEDhol
IElkZW50aWZpZXJzIHdpbGwgYmUgaW4gdXBwZXIgY2FzZXMuCgoPCgcEAwQAAgIBEgSXAQQJ
Cg8KBwQDBAACAgISBJcBDA0KNQoGBAMEAAIDEgSaAQQOGiUgSWRlbnRpZmllcnMgd2lsbCBi
ZSBpbiBsb3dlciBjYXNlcy4KCg8KBwQDBAACAwESBJoBBAkKDwoHBAMEAAIDAhIEmgEMDQoy
CgQEAwQBEgaeAQKnAQMaIiBUaGUgU1FMIGlkZW50aWZpZXIgcmV3cml0ZSBtb2RlLgoKDQoF
BAMEAQESBJ4BBxwKPQoGBAMEAQIAEgSgAQQsGi0gU1FMIElkZW50aWZpZXIgcmV3cml0ZSBt
b2RlIGlzIHVuc3BlY2lmaWVkLgoKDwoHBAMEAQIAARIEoAEEJwoPCgcEAwQBAgACEgSgASor
CjMKBgQDBAECARIEowEEDRojIFNRTCBpZGVudGlmaWVycyB3b24ndCBiZSByZXdyaXRlLgoK
DwoHBAMEAQIBARIEowEECAoPCgcEAwQBAgECEgSjAQsMCjYKBgQDBAECAhIEpgEEFBomIEFs
bCBTUUwgaWRlbnRpZmllcnMgd2lsbCBiZSByZXdyaXRlLgoKDwoHBAMEAQICARIEpgEEDwoP
CgcEAwQBAgICEgSmARITCkcKBAQDAgASBKoBAiwaOSBUaGUgc2V0dGluZyB0byBjb250cm9s
IG91dHB1dCBxdWVyaWVzJyBpZGVudGlmaWVyIGNhc2UuCgoNCgUEAwIABhIEqgECEAoNCgUE
AwIAARIEqgERJwoNCgUEAwIAAxIEqgEqKwo/CgQEAwIBEgStAQI0GjEgU3BlY2lmaWVzIHRo
ZSByZXdyaXRlIG1vZGUgZm9yIFNRTCBpZGVudGlmaWVycy4KCg0KBQQDAgEGEgStAQIXCg0K
BQQDAgEBEgStARgvCg0KBQQDAgEDEgStATIzCkgKAgQEEgaxAQCzAQEaOiBUZXJhZGF0YSBT
UUwgc3BlY2lmaWMgdHJhbnNsYXRpb24gdGFzayByZWxhdGVkIHNldHRpbmdzLgoKCwoDBAQB
EgSxAQgXCjcKAgQFEga2AQDDAQEaKSBCVEVRIHRyYW5zbGF0aW9uIHRhc2sgcmVsYXRlZCBz
ZXR0aW5ncy4KCgsKAwQFARIEtgEIEwqEAQoEBAUCABIEuQECJxp2IFNwZWNpZmllcyB0aGUg
cHJvamVjdCBhbmQgZGF0YXNldCBpbiBCaWdRdWVyeSB0aGF0IHdpbGwgYmUgdXNlZCBmb3IK
IGV4dGVybmFsIHRhYmxlIGNyZWF0aW9uIGR1cmluZyB0aGUgdHJhbnNsYXRpb24uCgoNCgUE
BQIABhIEuQECEgoNCgUEBQIAARIEuQETIgoNCgUEBQIAAxIEuQElJgqTAQoEBAUCARIEvQEC
HhqEASBUaGUgQ2xvdWQgU3RvcmFnZSBsb2NhdGlvbiB0byBiZSB1c2VkIGFzIHRoZSBkZWZh
dWx0IHBhdGggZm9yIGZpbGVzIHRoYXQKIGFyZSBub3Qgb3RoZXJ3aXNlIHNwZWNpZmllZCBp
biB0aGUgZmlsZSByZXBsYWNlbWVudCBtYXAuCgoNCgUEBQIBBRIEvQECCAoNCgUEBQIBARIE
vQEJGQoNCgUEBQIBAxIEvQEcHQqxAQoEBAUCAhIEwgECLxqiASBNYXBzIHRoZSBsb2NhbCBw
YXRocyB0aGF0IGFyZSB1c2VkIGluIEJURVEgc2NyaXB0cyAodGhlIGtleXMpIHRvIHRoZSBw
YXRocwogaW4gQ2xvdWQgU3RvcmFnZSB0aGF0IHNob3VsZCBiZSB1c2VkIGluIHRoZWlyIHN0
ZWFkIGluIHRoZSB0cmFuc2xhdGlvbiAodGhlCiB2YWx1ZSkuCgoNCgUEBQICBhIEwgECFQoN
CgUEBQICARIEwgEWKgoNCgUEBQICAxIEwgEtLgowCgIEBhIGxgEAzgEBGiIgUmVmZXJlbmNl
IHRvIGEgQmlnUXVlcnkgZGF0YXNldC4KCgsKAwQGARIExgEIGArCAQoEBAYCABIEygECGBqz
ASBBIHVuaXF1ZSBJRCBmb3IgdGhpcyBkYXRhc2V0LCB3aXRob3V0IHRoZSBwcm9qZWN0IG5h
bWUuIFRoZSBJRAogbXVzdCBjb250YWluIG9ubHkgbGV0dGVycyAoYS16LCBBLVopLCBudW1i
ZXJzICgwLTkpLCBvciB1bmRlcnNjb3JlcyAoXykuCiBUaGUgbWF4aW11bSBsZW5ndGggaXMg
MSwwMjQgY2hhcmFjdGVycy4KCg0KBQQGAgAFEgTKAQIICg0KBQQGAgABEgTKAQkTCg0KBQQG
AgADEgTKARYXCj4KBAQGAgESBM0BAhgaMCBUaGUgSUQgb2YgdGhlIHByb2plY3QgY29udGFp
bmluZyB0aGlzIGRhdGFzZXQuCgoNCgUEBgIBBRIEzQECCAoNCgUEBgIBARIEzQEJEwoNCgUE
BgIBAxIEzQEWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping ===
    # Fields for TranslationFileMapping
    # Field: input_path Type: 9 ()
    # Field: output_path Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails ===
    # Fields for TranslationTaskDetails
    # Field: teradata_options Type: 11 (.google.cloud.bigquery.migration.v2alpha.TeradataOptions)
    # Field: bteq_options Type: 11 (.google.cloud.bigquery.migration.v2alpha.BteqOptions)
    # Field: input_path Type: 9 ()
    # Field: output_path Type: 9 ()
    # Field: file_paths Type: 11 (.google.cloud.bigquery.migration.v2alpha.TranslationFileMapping)
    # Field: schema_path Type: 9 ()
    # Field: file_encoding Type: 14 (.google.cloud.bigquery.migration.v2alpha.TranslationTaskDetails.FileEncoding)
    # Field: identifier_settings Type: 11 (.google.cloud.bigquery.migration.v2alpha.IdentifierSettings)
    # Field: special_token_map Type: 11 (.google.cloud.bigquery.migration.v2alpha.TranslationTaskDetails.SpecialTokenMapEntry)
    # Field: filter Type: 11 (.google.cloud.bigquery.migration.v2alpha.Filter)
    # Field: translation_exception_table Type: 9 ()

# Enum: TranslationTaskDetails::FileEncoding
our $TranslationTaskDetails_FILE_ENCODING_UNSPECIFIED = 0;
our $TranslationTaskDetails_UTF_8 = 1;
our $TranslationTaskDetails_ISO_8859_1 = 2;
our $TranslationTaskDetails_US_ASCII = 3;
our $TranslationTaskDetails_UTF_16 = 4;
our $TranslationTaskDetails_UTF_16LE = 5;
our $TranslationTaskDetails_UTF_16BE = 6;

# Enum: TranslationTaskDetails::TokenType
our $TranslationTaskDetails_TOKEN_TYPE_UNSPECIFIED = 0;
our $TranslationTaskDetails_STRING = 1;
our $TranslationTaskDetails_INT64 = 2;
our $TranslationTaskDetails_NUMERIC = 3;
our $TranslationTaskDetails_BOOL = 4;
our $TranslationTaskDetails_FLOAT64 = 5;
our $TranslationTaskDetails_DATE = 6;
our $TranslationTaskDetails_TIMESTAMP = 7;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter ===
    # Fields for Filter
    # Field: input_file_exclusion_prefixes Type: 9 ()

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings ===
    # Fields for IdentifierSettings
    # Field: output_identifier_case Type: 14 (.google.cloud.bigquery.migration.v2alpha.IdentifierSettings.IdentifierCase)
    # Field: identifier_rewrite_mode Type: 14 (.google.cloud.bigquery.migration.v2alpha.IdentifierSettings.IdentifierRewriteMode)

# Enum: IdentifierSettings::IdentifierCase
our $IdentifierSettings_IDENTIFIER_CASE_UNSPECIFIED = 0;
our $IdentifierSettings_ORIGINAL = 1;
our $IdentifierSettings_UPPER = 2;
our $IdentifierSettings_LOWER = 3;

# Enum: IdentifierSettings::IdentifierRewriteMode
our $IdentifierSettings_IDENTIFIER_REWRITE_MODE_UNSPECIFIED = 0;
our $IdentifierSettings_NONE = 1;
our $IdentifierSettings_REWRITE_ALL = 2;

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions ===
    # Fields for TeradataOptions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions ===
    # Fields for BteqOptions
    # Field: project_dataset Type: 11 (.google.cloud.bigquery.migration.v2alpha.DatasetReference)
    # Field: default_path_uri Type: 9 ()
    # Field: file_replacement_map Type: 11 (.google.cloud.bigquery.migration.v2alpha.BteqOptions.FileReplacementMapEntry)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference ===
    # Fields for DatasetReference
    # Field: dataset_id Type: 9 ()
    # Field: project_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/translation_task.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping->new({
        input_path => $input_path,
        output_path => $output_path,
    });

    # Read or update a field
    my $val = $msg->input_path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/translation_task.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping

Mapping between an input and output file to be translated in a subtask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_path() >> / C<< $msg->input_path($value) >>

Type: C<String>

The Cloud Storage path for a file to translation in a subtask.

=item * C<< $msg->output_path() >> / C<< $msg->output_path($value) >>

Type: C<String>

The Cloud Storage path to write back the corresponding input file to.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails

The translation task config to capture necessary settings for a translation
task and subtask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->teradata_options() >> / C<< $msg->teradata_options($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions>)

The Teradata SQL specific settings for the translation task.

=item * C<< $msg->bteq_options() >> / C<< $msg->bteq_options($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions>)

The BTEQ specific settings for the translation task.

=item * C<< $msg->input_path() >> / C<< $msg->input_path($value) >>

Type: C<String>

The Cloud Storage path for translation input files.

=item * C<< $msg->output_path() >> / C<< $msg->output_path($value) >>

Type: C<String>

The Cloud Storage path for translation output files.

=item * C<< $msg->file_paths() >> / C<< $msg->file_paths($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping>)

Cloud Storage files to be processed for translation.

=item * C<< $msg->schema_path() >> / C<< $msg->schema_path($value) >>

Type: C<String>

The Cloud Storage path to DDL files as table schema to assist semantic
translation.

=item * C<< $msg->file_encoding() >> / C<< $msg->file_encoding($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTaskDetails::FileEncoding>)

The file encoding type.

=item * C<< $msg->identifier_settings() >> / C<< $msg->identifier_settings($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings>)

The settings for SQL identifiers.

=item * C<< $msg->special_token_map() >> / C<< $msg->special_token_map($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails::SpecialTokenMapEntry>)

The map capturing special tokens to be replaced during translation. The key
is special token in string. The value is the token data type. This is used
to translate SQL query template which contains special token as place
holder. The special token makes a query invalid to parse. This map will be
applied to annotate those special token with types to let parser understand
how to parse them into proper structure with type information.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter>)

The filter applied to translation details.

=item * C<< $msg->translation_exception_table() >> / C<< $msg->translation_exception_table($value) >>

Type: C<String>

Specifies the exact name of the bigquery table ("dataset.table") to be used
for surfacing raw translation errors. If the table does not exist, we will
create it. If it already exists and the schema is the same, we will re-use.
If the table exists and the schema is different, we will throw an error.

=back

=head3 Enum: TranslationTaskDetails::FileEncoding

=over 4

=item * C<FILE_ENCODING_UNSPECIFIED> => C<0>

=item * C<UTF_8> => C<1>

=item * C<ISO_8859_1> => C<2>

=item * C<US_ASCII> => C<3>

=item * C<UTF_16> => C<4>

=item * C<UTF_16LE> => C<5>

=item * C<UTF_16BE> => C<6>

=back

=head3 Enum: TranslationTaskDetails::TokenType

=over 4

=item * C<TOKEN_TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INT64> => C<2>

=item * C<NUMERIC> => C<3>

=item * C<BOOL> => C<4>

=item * C<FLOAT64> => C<5>

=item * C<DATE> => C<6>

=item * C<TIMESTAMP> => C<7>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter

The filter applied to fields of translation details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_file_exclusion_prefixes() >> / C<< $msg->input_file_exclusion_prefixes($value) >>

Type: C<String>

The list of prefixes used to exclude processing for input files.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings

Settings related to SQL identifiers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->output_identifier_case() >> / C<< $msg->output_identifier_case($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::IdentifierSettings::IdentifierCase>)

The setting to control output queries' identifier case.

=item * C<< $msg->identifier_rewrite_mode() >> / C<< $msg->identifier_rewrite_mode($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2alpha::IdentifierSettings::IdentifierRewriteMode>)

Specifies the rewrite mode for SQL identifiers.

=back

=head3 Enum: IdentifierSettings::IdentifierCase

=over 4

=item * C<IDENTIFIER_CASE_UNSPECIFIED> => C<0>

=item * C<ORIGINAL> => C<1>

=item * C<UPPER> => C<2>

=item * C<LOWER> => C<3>

=back

=head3 Enum: IdentifierSettings::IdentifierRewriteMode

=over 4

=item * C<IDENTIFIER_REWRITE_MODE_UNSPECIFIED> => C<0>

=item * C<NONE> => C<1>

=item * C<REWRITE_ALL> => C<2>

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions

Teradata SQL specific translation task related settings.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions

BTEQ translation task related settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_dataset() >> / C<< $msg->project_dataset($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference>)

Specifies the project and dataset in BigQuery that will be used for
external table creation during the translation.

=item * C<< $msg->default_path_uri() >> / C<< $msg->default_path_uri($value) >>

Type: C<String>

The Cloud Storage location to be used as the default path for files that
are not otherwise specified in the file replacement map.

=item * C<< $msg->file_replacement_map() >> / C<< $msg->file_replacement_map($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions::FileReplacementMapEntry>)

Maps the local paths that are used in BTEQ scripts (the keys) to the paths
in Cloud Storage that should be used in their stead in the translation (the
value).

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference

Reference to a BigQuery dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

A unique ID for this dataset, without the project name. The ID
must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_).
The maximum length is 1,024 characters.

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

The ID of the project containing this dataset.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
