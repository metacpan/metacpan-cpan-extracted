package Google::Cloud::Visionai::V1alpha1::StreamsResources;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvc3RyZWFtc19yZXNvdXJjZXMucHJv
dG8SHmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3Rv
YnVmL2R1cmF0aW9uLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrsF
CgZTdHJlYW0SEgoEbmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJK
CgZsYWJlbHMYBCADKAsyMi5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuU3RyZWFt
LkxhYmVsc0VudHJ5UgZsYWJlbHMSWQoLYW5ub3RhdGlvbnMYBSADKAsyNy5nb29nbGUuY2xv
dWQudmlzaW9uYWkudjFhbHBoYTEuU3RyZWFtLkFubm90YXRpb25zRW50cnlSC2Fubm90YXRp
b25zEiEKDGRpc3BsYXlfbmFtZRgGIAEoCVILZGlzcGxheU5hbWUSLgoTZW5hYmxlX2hsc19w
bGF5YmFjaxgHIAEoCFIRZW5hYmxlSGxzUGxheWJhY2sSMgoVbWVkaWFfd2FyZWhvdXNlX2Fz
c2V0GAggASgJUhNtZWRpYVdhcmVob3VzZUFzc2V0GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaPgoQQW5ub3RhdGlvbnNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOnDqQW0KHnZp
c2lvbmFpLmdvb2dsZWFwaXMuY29tL1N0cmVhbRJLcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9zdHJlYW1zL3tzdHJlYW19IvsF
CgVFdmVudBISCgRuYW1lGAEgASgJUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1l
GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkkK
BmxhYmVscxgEIAMoCzIxLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMS5FdmVudC5M
YWJlbHNFbnRyeVIGbGFiZWxzElgKC2Fubm90YXRpb25zGAUgAygLMjYuZ29vZ2xlLmNsb3Vk
LnZpc2lvbmFpLnYxYWxwaGExLkV2ZW50LkFubm90YXRpb25zRW50cnlSC2Fubm90YXRpb25z
ElQKD2FsaWdubWVudF9jbG9jaxgGIAEoDjIrLmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFs
cGhhMS5FdmVudC5DbG9ja1IOYWxpZ25tZW50Q2xvY2sSPAoMZ3JhY2VfcGVyaW9kGAcgASgL
MhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgtncmFjZVBlcmlvZBo5CgtMYWJlbHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4KEEFubm90
YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4
ASI3CgVDbG9jaxIVChFDTE9DS19VTlNQRUNJRklFRBAAEgsKB0NBUFRVUkUQARIKCgZJTkdF
U1QQAjpt6kFqCh12aXNpb25haS5nb29nbGVhcGlzLmNvbS9FdmVudBJJcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9ldmVudHMv
e2V2ZW50fSKwBQoGU2VyaWVzEhIKBG5hbWUYASABKAlSBG5hbWUSQAoLY3JlYXRlX3RpbWUY
AiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoL
dXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVw
ZGF0ZVRpbWUSSgoGbGFiZWxzGAQgAygLMjIuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxw
aGExLlNlcmllcy5MYWJlbHNFbnRyeVIGbGFiZWxzElkKC2Fubm90YXRpb25zGAUgAygLMjcu
Z29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxYWxwaGExLlNlcmllcy5Bbm5vdGF0aW9uc0VudHJ5
Ugthbm5vdGF0aW9ucxI+CgZzdHJlYW0YBiABKAlCJuBBAvpBIAoedmlzaW9uYWkuZ29vZ2xl
YXBpcy5jb20vU3RyZWFtUgZzdHJlYW0SOwoFZXZlbnQYByABKAlCJeBBAvpBHwoddmlzaW9u
YWkuZ29vZ2xlYXBpcy5jb20vRXZlbnRSBWV2ZW50GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaPgoQQW5ub3RhdGlvbnNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOm/qQWwKHnZp
c2lvbmFpLmdvb2dsZWFwaXMuY29tL1NlcmllcxJKcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9zZXJpZXMve3Nlcmllc30itwUK
B0NoYW5uZWwSEgoEbmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJL
CgZsYWJlbHMYBCADKAsyMy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQ2hhbm5l
bC5MYWJlbHNFbnRyeVIGbGFiZWxzEloKC2Fubm90YXRpb25zGAUgAygLMjguZ29vZ2xlLmNs
b3VkLnZpc2lvbmFpLnYxYWxwaGExLkNoYW5uZWwuQW5ub3RhdGlvbnNFbnRyeVILYW5ub3Rh
dGlvbnMSPgoGc3RyZWFtGAYgASgJQibgQQL6QSAKHnZpc2lvbmFpLmdvb2dsZWFwaXMuY29t
L1N0cmVhbVIGc3RyZWFtEjsKBWV2ZW50GAcgASgJQiXgQQL6QR8KHXZpc2lvbmFpLmdvb2ds
ZWFwaXMuY29tL0V2ZW50UgVldmVudBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATpz6kFwCh92aXNpb25haS5n
b29nbGVhcGlzLmNvbS9DaGFubmVsEk1wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vY2x1c3RlcnMve2NsdXN0ZXJ9L2NoYW5uZWxzL3tjaGFubmVsfULjAQoiY29t
Lmdvb2dsZS5jbG91ZC52aXNpb25haS52MWFscGhhMUIVU3RyZWFtc1Jlc291cmNlc1Byb3Rv
UAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vdmlzaW9uYWkvYXBpdjFhbHBoYTEvdmlzaW9uYWlw
Yjt2aXNpb25haXBiqgIeR29vZ2xlLkNsb3VkLlZpc2lvbkFJLlYxQWxwaGExygIeR29vZ2xl
XENsb3VkXFZpc2lvbkFJXFYxYWxwaGEx6gIhR29vZ2xlOjpDbG91ZDo6VmlzaW9uQUk6OlYx
YWxwaGExSoIrCgcSBQ4AvAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAoCgkKAgMDEgMVACkK
CAoBCBIDFwA7CgkKAgglEgMXADsKCAoBCBIDGABVCgkKAggLEgMYAFUKCAoBCBIDGQAiCgkK
AggKEgMZACIKCAoBCBIDGgA2CgkKAggIEgMaADYKCAoBCBIDGwA7CgkKAggBEgMbADsKCAoB
CBIDHAA7CgkKAggpEgMcADsKCAoBCBIDHQA6CgkKAggtEgMdADoK7AEKAgQAEgQiAEEBGt8B
IE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgU3RyZWFtIG9iamVjdC4gVGhlIFN0cmVhbSBhbmQg
dGhlIEV2ZW50IHJlc291cmNlcyBhcmUKIG1hbnkgdG8gbWFueTsgaS5lLiwgZWFjaCBTdHJl
YW0gcmVzb3VyY2UgY2FuIGFzc29jaWF0ZSB0byBtYW55IEV2ZW50CiByZXNvdXJjZXMgYW5k
IGVhY2ggRXZlbnQgcmVzb3VyY2UgY2FuIGFzc29jaWF0ZSB0byBtYW55IFN0cmVhbSByZXNv
dXJjZXMuCgoKCgMEAAESAyIIDgoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKJAoEBAAC
ABIDKQISGhcgTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIABRIDKQIICgwKBQQAAgAB
EgMpCQ0KDAoFBAACAAMSAykQEQoxCgQEAAIBEgMsAlgaJCBPdXRwdXQgb25seS4gVGhlIGNy
ZWF0ZSB0aW1lc3RhbXAuCgoMCgUEAAIBBhIDLAIbCgwKBQQAAgEBEgMsHCcKDAoFBAACAQMS
AywqKwoMCgUEAAIBCBIDLCxXCg8KCAQAAgEInAgAEgMsLVYKMQoEBAACAhIDLwJYGiQgT3V0
cHV0IG9ubHkuIFRoZSB1cGRhdGUgdGltZXN0YW1wLgoKDAoFBAACAgYSAy8CGwoMCgUEAAIC
ARIDLxwnCgwKBQQAAgIDEgMvKisKDAoFBAACAggSAy8sVwoPCggEAAICCJwIABIDLy1WCikK
BAQAAgMSAzICIRocIExhYmVscyBhcyBrZXkgdmFsdWUgcGFpcnMuCgoMCgUEAAIDBhIDMgIV
CgwKBQQAAgMBEgMyFhwKDAoFBAACAwMSAzIfIApVCgQEAAIEEgM1AiYaSCBBbm5vdGF0aW9u
cyB0byBhbGxvdyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFtb3VudHMgb2YgYXJiaXRyYXJ5
IGRhdGEuCgoMCgUEAAIEBhIDNQIVCgwKBQQAAgQBEgM1FiEKDAoFBAACBAMSAzUkJQo4CgQE
AAIFEgM4AhoaKyBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGUgc3RyZWFtIHJlc291cmNlLgoK
DAoFBAACBQUSAzgCCAoMCgUEAAIFARIDOAkVCgwKBQQAAgUDEgM4GBkKSQoEBAACBhIDOwIf
GjwgV2hldGhlciB0byBlbmFibGUgdGhlIEhMUyBwbGF5YmFjayBzZXJ2aWNlIG9uIHRoaXMg
c3RyZWFtLgoKDAoFBAACBgUSAzsCBgoMCgUEAAIGARIDOwcaCgwKBQQAAgYDEgM7HR4K8QEK
BAQAAgcSA0ACIxrjASBUaGUgbmFtZSBvZiB0aGUgbWVkaWEgd2FyZWhvdXNlIGFzc2V0IGZv
ciBsb25nIHRlcm0gc3RvcmFnZSBvZiBzdHJlYW0gZGF0YS4KIEZvcm1hdDogcHJvamVjdHMv
JHtwX2lkfS9sb2NhdGlvbnMvJHtsX2lkfS9jb3Jwb3JhLyR7Y19pZH0vYXNzZXRzLyR7YV9p
ZH0KIFJlbWFpbiBlbXB0eSBpZiB0aGUgbWVkaWEgd2FyZWhvdXNlIHN0b3JhZ2UgaXMgbm90
IG5lZWRlZCBmb3IgdGhlIHN0cmVhbS4KCgwKBQQAAgcFEgNAAggKDAoFBAACBwESA0AJHgoM
CgUEAAIHAxIDQCEiCjIKAgQBEgREAG4BGiYgTWVzc2FnZSBkZXNjcmliaW5nIHRoZSBFdmVu
dCBvYmplY3QuCgoKCgMEAQESA0QIDQoLCgMEAQcSBEUCSAQKDQoFBAEHnQgSBEUCSAQKPAoE
BAEEABIESwJVAxouIENsb2NrIHRoYXQgd2lsbCBiZSB1c2VkIGZvciBqb2luaW5nIHN0cmVh
bXMuCgoMCgUEAQQAARIDSwcMCigKBgQBBAACABIDTQQaGhkgQ2xvY2sgaXMgbm90IHNwZWNp
ZmllZC4KCg4KBwQBBAACAAESA00EFQoOCgcEAQQAAgACEgNNGBkKXgoGBAEEAAIBEgNRBBAa
TyBVc2UgdGhlIHRpbWVzdGFtcCB3aGVuIHRoZSBkYXRhIGlzIGNhcHR1cmVkLiBDbGllbnRz
IG5lZWQgdG8gc3luYyB0aGUKIGNsb2NrLgoKDgoHBAEEAAIBARIDUQQLCg4KBwQBBAACAQIS
A1EODwo9CgYEAQQAAgISA1QEDxouIFVzZSB0aGUgdGltZXN0YW1wIHdoZW4gdGhlIGRhdGEg
aXMgcmVjZWl2ZWQuCgoOCgcEAQQAAgIBEgNUBAoKDgoHBAEEAAICAhIDVA0OCiQKBAQBAgAS
A1gCEhoXIE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDAoFBAECAAUSA1gCCAoMCgUEAQIAARID
WAkNCgwKBQQBAgADEgNYEBEKMQoEBAECARIDWwJYGiQgT3V0cHV0IG9ubHkuIFRoZSBjcmVh
dGUgdGltZXN0YW1wLgoKDAoFBAECAQYSA1sCGwoMCgUEAQIBARIDWxwnCgwKBQQBAgEDEgNb
KisKDAoFBAECAQgSA1ssVwoPCggEAQIBCJwIABIDWy1WCjEKBAQBAgISA14CWBokIE91dHB1
dCBvbmx5LiBUaGUgdXBkYXRlIHRpbWVzdGFtcC4KCgwKBQQBAgIGEgNeAhsKDAoFBAECAgES
A14cJwoMCgUEAQICAxIDXiorCgwKBQQBAgIIEgNeLFcKDwoIBAECAgicCAASA14tVgopCgQE
AQIDEgNhAiEaHCBMYWJlbHMgYXMga2V5IHZhbHVlIHBhaXJzLgoKDAoFBAECAwYSA2ECFQoM
CgUEAQIDARIDYRYcCgwKBQQBAgMDEgNhHyAKVQoEBAECBBIDZAImGkggQW5ub3RhdGlvbnMg
dG8gYWxsb3cgY2xpZW50cyB0byBzdG9yZSBzbWFsbCBhbW91bnRzIG9mIGFyYml0cmFyeSBk
YXRhLgoKDAoFBAECBAYSA2QCFQoMCgUEAQIEARIDZBYhCgwKBQQBAgQDEgNkJCUKMgoEBAEC
BRIDZwIcGiUgVGhlIGNsb2NrIHVzZWQgZm9yIGpvaW5pbmcgc3RyZWFtcy4KCgwKBQQBAgUG
EgNnAgcKDAoFBAECBQESA2cIFwoMCgUEAQIFAxIDZxobCv4BCgQEAQIGEgNtAiwa8AEgR3Jh
Y2UgcGVyaW9kIGZvciBjbGVhbmluZyB1cCB0aGUgZXZlbnQuIFRoaXMgaXMgdGhlIHRpbWUg
dGhlIGNvbnRyb2xsZXIKIHdhaXRzIGZvciBiZWZvcmUgZGVsZXRpbmcgdGhlIGV2ZW50LiBE
dXJpbmcgdGhpcyBwZXJpb2QsIGlmIHRoZXJlIGlzIGFueQogYWN0aXZlIGNoYW5uZWwgb24g
dGhlIGV2ZW50LiBUaGUgZGVsZXRpb24gb2YgdGhlIGV2ZW50IGFmdGVyIGdyYWNlX3Blcmlv
ZAogd2lsbCBiZSBpZ25vcmVkLgoKDAoFBAECBgYSA20CGgoMCgUEAQIGARIDbRsnCgwKBQQB
AgYDEgNtKisKNAoCBAISBXEAlQEBGicgTWVzc2FnZSBkZXNjcmliaW5nIHRoZSBTZXJpZXMg
b2JqZWN0LgoKCgoDBAIBEgNxCA4KCwoDBAIHEgRyAnUECg0KBQQCB50IEgRyAnUECiQKBAQC
AgASA3gCEhoXIE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDAoFBAICAAUSA3gCCAoMCgUEAgIA
ARIDeAkNCgwKBQQCAgADEgN4EBEKMQoEBAICARIDewJYGiQgT3V0cHV0IG9ubHkuIFRoZSBj
cmVhdGUgdGltZXN0YW1wLgoKDAoFBAICAQYSA3sCGwoMCgUEAgIBARIDexwnCgwKBQQCAgED
EgN7KisKDAoFBAICAQgSA3ssVwoPCggEAgIBCJwIABIDey1WCjEKBAQCAgISA34CWBokIE91
dHB1dCBvbmx5LiBUaGUgdXBkYXRlIHRpbWVzdGFtcC4KCgwKBQQCAgIGEgN+AhsKDAoFBAIC
AgESA34cJwoMCgUEAgICAxIDfiorCgwKBQQCAgIIEgN+LFcKDwoIBAICAgicCAASA34tVgoq
CgQEAgIDEgSBAQIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4KCg0KBQQCAgMGEgSB
AQIVCg0KBQQCAgMBEgSBARYcCg0KBQQCAgMDEgSBAR8gClYKBAQCAgQSBIQBAiYaSCBBbm5v
dGF0aW9ucyB0byBhbGxvdyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFtb3VudHMgb2YgYXJi
aXRyYXJ5IGRhdGEuCgoNCgUEAgIEBhIEhAECFQoNCgUEAgIEARIEhAEWIQoNCgUEAgIEAxIE
hAEkJQpHCgQEAgIFEgaHAQKMAQQaNyBSZXF1aXJlZC4gU3RyZWFtIHRoYXQgaXMgYXNzb2Np
YXRlZCB3aXRoIHRoaXMgc2VyaWVzLgoKDQoFBAICBQUSBIcBAggKDQoFBAICBQESBIcBCQ8K
DQoFBAICBQMSBIcBEhMKDwoFBAICBQgSBocBFIwBAwoQCggEAgIFCJwIABIEiAEEKgoRCgcE
AgIFCJ8IEgaJAQSLAQUKRgoEBAICBhIGjwEClAEEGjYgUmVxdWlyZWQuIEV2ZW50IHRoYXQg
aXMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc2VyaWVzLgoKDQoFBAICBgUSBI8BAggKDQoFBAIC
BgESBI8BCQ4KDQoFBAICBgMSBI8BERIKDwoFBAICBggSBo8BE5QBAwoQCggEAgIGCJwIABIE
kAEEKgoRCgcEAgIGCJ8IEgaRAQSTAQUKNgoCBAMSBpgBALwBARooIE1lc3NhZ2UgZGVzY3Jp
YmluZyB0aGUgQ2hhbm5lbCBvYmplY3QuCgoLCgMEAwESBJgBCA8KDQoDBAMHEgaZAQKcAQQK
DwoFBAMHnQgSBpkBApwBBAolCgQEAwIAEgSfAQISGhcgTmFtZSBvZiB0aGUgcmVzb3VyY2Uu
CgoNCgUEAwIABRIEnwECCAoNCgUEAwIAARIEnwEJDQoNCgUEAwIAAxIEnwEQEQoyCgQEAwIB
EgSiAQJYGiQgT3V0cHV0IG9ubHkuIFRoZSBjcmVhdGUgdGltZXN0YW1wLgoKDQoFBAMCAQYS
BKIBAhsKDQoFBAMCAQESBKIBHCcKDQoFBAMCAQMSBKIBKisKDQoFBAMCAQgSBKIBLFcKEAoI
BAMCAQicCAASBKIBLVYKMgoEBAMCAhIEpQECWBokIE91dHB1dCBvbmx5LiBUaGUgdXBkYXRl
IHRpbWVzdGFtcC4KCg0KBQQDAgIGEgSlAQIbCg0KBQQDAgIBEgSlARwnCg0KBQQDAgIDEgSl
ASorCg0KBQQDAgIIEgSlASxXChAKCAQDAgIInAgAEgSlAS1WCioKBAQDAgMSBKgBAiEaHCBM
YWJlbHMgYXMga2V5IHZhbHVlIHBhaXJzLgoKDQoFBAMCAwYSBKgBAhUKDQoFBAMCAwESBKgB
FhwKDQoFBAMCAwMSBKgBHyAKVgoEBAMCBBIEqwECJhpIIEFubm90YXRpb25zIHRvIGFsbG93
IGNsaWVudHMgdG8gc3RvcmUgc21hbGwgYW1vdW50cyBvZiBhcmJpdHJhcnkgZGF0YS4KCg0K
BQQDAgQGEgSrAQIVCg0KBQQDAgQBEgSrARYhCg0KBQQDAgQDEgSrASQlCkcKBAQDAgUSBq4B
ArMBBBo3IFJlcXVpcmVkLiBTdHJlYW0gdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGggdGhpcyBz
ZXJpZXMuCgoNCgUEAwIFBRIErgECCAoNCgUEAwIFARIErgEJDwoNCgUEAwIFAxIErgESEwoP
CgUEAwIFCBIGrgEUswEDChAKCAQDAgUInAgAEgSvAQQqChEKBwQDAgUInwgSBrABBLIBBQpG
CgQEAwIGEga2AQK7AQQaNiBSZXF1aXJlZC4gRXZlbnQgdGhhdCBpcyBhc3NvY2lhdGVkIHdp
dGggdGhpcyBzZXJpZXMuCgoNCgUEAwIGBRIEtgECCAoNCgUEAwIGARIEtgEJDgoNCgUEAwIG
AxIEtgEREgoPCgUEAwIGCBIGtgETuwEDChAKCAQDAgYInAgAEgS3AQQqChEKBwQDAgYInwgS
BrgBBLoBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream ===
    # Fields for Stream
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Stream.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1alpha1.Stream.AnnotationsEntry)
    # Field: display_name Type: 9 ()
    # Field: enable_hls_playback Type: 8 ()
    # Field: media_warehouse_asset Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamsResources::Event ===
    # Fields for Event
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Event.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1alpha1.Event.AnnotationsEntry)
    # Field: alignment_clock Type: 14 (.google.cloud.visionai.v1alpha1.Event.Clock)
    # Field: grace_period Type: 11 (.google.protobuf.Duration)

# Enum: Event::Clock
our $Event_CLOCK_UNSPECIFIED = 0;
our $Event_CAPTURE = 1;
our $Event_INGEST = 2;

# === Message: Google::Cloud::Visionai::V1alpha1::StreamsResources::Series ===
    # Fields for Series
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Series.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1alpha1.Series.AnnotationsEntry)
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel ===
    # Fields for Channel
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Channel.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1alpha1.Channel.AnnotationsEntry)
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::StreamsResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/streams_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::StreamsResources;

    my $msg = Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/streams_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream

Message describing the Stream object. The Stream and the Event resources are
many to many; i.e., each Stream resource can associate to many Event
resources and each Event resource can associate to many Stream resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Stream::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name for the stream resource.

=item * C<< $msg->enable_hls_playback() >> / C<< $msg->enable_hls_playback($value) >>

Type: C<Bool>

Whether to enable the HLS playback service on this stream.

=item * C<< $msg->media_warehouse_asset() >> / C<< $msg->media_warehouse_asset($value) >>

Type: C<String>

The name of the media warehouse asset for long term storage of stream data.
Format: projects/${p_id}/locations/${l_id}/corpora/${c_id}/assets/${a_id}
Remain empty if the media warehouse storage is not needed for the stream.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamsResources::Event

Message describing the Event object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Event::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->alignment_clock() >> / C<< $msg->alignment_clock($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1alpha1::Event::Clock>)

The clock used for joining streams.

=item * C<< $msg->grace_period() >> / C<< $msg->grace_period($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Grace period for cleaning up the event. This is the time the controller
waits for before deleting the event. During this period, if there is any
active channel on the event. The deletion of the event after grace_period
will be ignored.

=back

=head3 Enum: Event::Clock

=over 4

=item * C<CLOCK_UNSPECIFIED> => C<0>

=item * C<CAPTURE> => C<1>

=item * C<INGEST> => C<2>

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamsResources::Series

Message describing the Series object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Series::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

Required. Stream that is associated with this series.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

Required. Event that is associated with this series.

=back

=head2 Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel

Message describing the Channel object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Channel::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

Required. Stream that is associated with this series.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

Required. Event that is associated with this series.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::StreamsResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
