package Google::Cloud::Visionai::V1::StreamsResources;

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
CjBnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvc3RyZWFtc19yZXNvdXJjZXMucHJvdG8SGGdv
b2dsZS5jbG91ZC52aXNpb25haS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9u
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIq8FCgZTdHJlYW0SEgoE
bmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJECgZsYWJlbHMYBCAD
KAsyLC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuU3RyZWFtLkxhYmVsc0VudHJ5UgZsYWJl
bHMSUwoLYW5ub3RhdGlvbnMYBSADKAsyMS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuU3Ry
ZWFtLkFubm90YXRpb25zRW50cnlSC2Fubm90YXRpb25zEiEKDGRpc3BsYXlfbmFtZRgGIAEo
CVILZGlzcGxheU5hbWUSLgoTZW5hYmxlX2hsc19wbGF5YmFjaxgHIAEoCFIRZW5hYmxlSGxz
UGxheWJhY2sSMgoVbWVkaWFfd2FyZWhvdXNlX2Fzc2V0GAggASgJUhNtZWRpYVdhcmVob3Vz
ZUFzc2V0GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZToCOAEaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2
YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOnDqQW0KHnZpc2lvbmFpLmdvb2dsZWFwaXMuY29tL1N0
cmVhbRJLcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJz
L3tjbHVzdGVyfS9zdHJlYW1zL3tzdHJlYW19IukFCgVFdmVudBISCgRuYW1lGAEgASgJUgRu
YW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkMKBmxhYmVscxgEIAMoCzIrLmdvb2dsZS5j
bG91ZC52aXNpb25haS52MS5FdmVudC5MYWJlbHNFbnRyeVIGbGFiZWxzElIKC2Fubm90YXRp
b25zGAUgAygLMjAuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLkV2ZW50LkFubm90YXRpb25z
RW50cnlSC2Fubm90YXRpb25zEk4KD2FsaWdubWVudF9jbG9jaxgGIAEoDjIlLmdvb2dsZS5j
bG91ZC52aXNpb25haS52MS5FdmVudC5DbG9ja1IOYWxpZ25tZW50Q2xvY2sSPAoMZ3JhY2Vf
cGVyaW9kGAcgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgtncmFjZVBlcmlvZBo5
CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ASI3CgVDbG9jaxIVChFDTE9DS19VTlNQRUNJRklFRBAAEgsKB0NBUFRV
UkUQARIKCgZJTkdFU1QQAjpt6kFqCh12aXNpb25haS5nb29nbGVhcGlzLmNvbS9FdmVudBJJ
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVz
dGVyfS9ldmVudHMve2V2ZW50fSKkBQoGU2VyaWVzEhIKBG5hbWUYASABKAlSBG5hbWUSQAoL
Y3JlYXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSRAoGbGFiZWxzGAQgAygLMiwuZ29vZ2xlLmNsb3VkLnZp
c2lvbmFpLnYxLlNlcmllcy5MYWJlbHNFbnRyeVIGbGFiZWxzElMKC2Fubm90YXRpb25zGAUg
AygLMjEuZ29vZ2xlLmNsb3VkLnZpc2lvbmFpLnYxLlNlcmllcy5Bbm5vdGF0aW9uc0VudHJ5
Ugthbm5vdGF0aW9ucxI+CgZzdHJlYW0YBiABKAlCJuBBAvpBIAoedmlzaW9uYWkuZ29vZ2xl
YXBpcy5jb20vU3RyZWFtUgZzdHJlYW0SOwoFZXZlbnQYByABKAlCJeBBAvpBHwoddmlzaW9u
YWkuZ29vZ2xlYXBpcy5jb20vRXZlbnRSBWV2ZW50GjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaPgoQQW5ub3RhdGlvbnNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOm/qQWwKHnZp
c2lvbmFpLmdvb2dsZWFwaXMuY29tL1NlcmllcxJKcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfS9zZXJpZXMve3Nlcmllc30iqwUK
B0NoYW5uZWwSEgoEbmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJF
CgZsYWJlbHMYBCADKAsyLS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEuQ2hhbm5lbC5MYWJl
bHNFbnRyeVIGbGFiZWxzElQKC2Fubm90YXRpb25zGAUgAygLMjIuZ29vZ2xlLmNsb3VkLnZp
c2lvbmFpLnYxLkNoYW5uZWwuQW5ub3RhdGlvbnNFbnRyeVILYW5ub3RhdGlvbnMSPgoGc3Ry
ZWFtGAYgASgJQibgQQL6QSAKHnZpc2lvbmFpLmdvb2dsZWFwaXMuY29tL1N0cmVhbVIGc3Ry
ZWFtEjsKBWV2ZW50GAcgASgJQiXgQQL6QR8KHXZpc2lvbmFpLmdvb2dsZWFwaXMuY29tL0V2
ZW50UgVldmVudBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgC
IAEoCVIFdmFsdWU6AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATpz6kFwCh92aXNpb25haS5nb29nbGVhcGlzLmNv
bS9DaGFubmVsEk1wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2x1
c3RlcnMve2NsdXN0ZXJ9L2NoYW5uZWxzL3tjaGFubmVsfULFAQocY29tLmdvb2dsZS5jbG91
ZC52aXNpb25haS52MUIVU3RyZWFtc1Jlc291cmNlc1Byb3RvUAFaOGNsb3VkLmdvb2dsZS5j
b20vZ28vdmlzaW9uYWkvYXBpdjEvdmlzaW9uYWlwYjt2aXNpb25haXBiqgIYR29vZ2xlLkNs
b3VkLlZpc2lvbkFJLlYxygIYR29vZ2xlXENsb3VkXFZpc2lvbkFJXFYx6gIbR29vZ2xlOjpD
bG91ZDo6VmlzaW9uQUk6OlYxSo4rCgcSBQ4AvAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAo
CgkKAgMDEgMVACkKCAoBCBIDFwA1CgkKAgglEgMXADUKCAoBCBIDGABPCgkKAggLEgMYAE8K
CAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgA2CgkKAggIEgMaADYKCAoBCBIDGwA1CgkK
AggBEgMbADUKCAoBCBIDHAA1CgkKAggpEgMcADUKCAoBCBIDHQA0CgkKAggtEgMdADQK7AEK
AgQAEgQiAEMBGt8BIE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgU3RyZWFtIG9iamVjdC4gVGhl
IFN0cmVhbSBhbmQgdGhlIEV2ZW50IHJlc291cmNlcyBhcmUKIG1hbnkgdG8gbWFueTsgaS5l
LiwgZWFjaCBTdHJlYW0gcmVzb3VyY2UgY2FuIGFzc29jaWF0ZSB0byBtYW55IEV2ZW50CiBy
ZXNvdXJjZXMgYW5kIGVhY2ggRXZlbnQgcmVzb3VyY2UgY2FuIGFzc29jaWF0ZSB0byBtYW55
IFN0cmVhbSByZXNvdXJjZXMuCgoKCgMEAAESAyIIDgoLCgMEAAcSBCMCJgQKDQoFBAAHnQgS
BCMCJgQKJAoEBAACABIDKQISGhcgTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAAIABRID
KQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoyCgQEAAIBEgQsAi0yGiQgT3V0cHV0
IG9ubHkuIFRoZSBjcmVhdGUgdGltZXN0YW1wLgoKDAoFBAACAQYSAywCGwoMCgUEAAIBARID
LBwnCgwKBQQAAgEDEgMsKisKDAoFBAACAQgSAy0GMQoPCggEAAIBCJwIABIDLQcwCjIKBAQA
AgISBDACMTIaJCBPdXRwdXQgb25seS4gVGhlIHVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAAIC
BhIDMAIbCgwKBQQAAgIBEgMwHCcKDAoFBAACAgMSAzAqKwoMCgUEAAICCBIDMQYxCg8KCAQA
AgIInAgAEgMxBzAKKQoEBAACAxIDNAIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4K
CgwKBQQAAgMGEgM0AhUKDAoFBAACAwESAzQWHAoMCgUEAAIDAxIDNB8gClUKBAQAAgQSAzcC
JhpIIEFubm90YXRpb25zIHRvIGFsbG93IGNsaWVudHMgdG8gc3RvcmUgc21hbGwgYW1vdW50
cyBvZiBhcmJpdHJhcnkgZGF0YS4KCgwKBQQAAgQGEgM3AhUKDAoFBAACBAESAzcWIQoMCgUE
AAIEAxIDNyQlCjgKBAQAAgUSAzoCGhorIFRoZSBkaXNwbGF5IG5hbWUgZm9yIHRoZSBzdHJl
YW0gcmVzb3VyY2UuCgoMCgUEAAIFBRIDOgIICgwKBQQAAgUBEgM6CRUKDAoFBAACBQMSAzoY
GQpJCgQEAAIGEgM9Ah8aPCBXaGV0aGVyIHRvIGVuYWJsZSB0aGUgSExTIHBsYXliYWNrIHNl
cnZpY2Ugb24gdGhpcyBzdHJlYW0uCgoMCgUEAAIGBRIDPQIGCgwKBQQAAgYBEgM9BxoKDAoF
BAACBgMSAz0dHgrxAQoEBAACBxIDQgIjGuMBIFRoZSBuYW1lIG9mIHRoZSBtZWRpYSB3YXJl
aG91c2UgYXNzZXQgZm9yIGxvbmcgdGVybSBzdG9yYWdlIG9mIHN0cmVhbSBkYXRhLgogRm9y
bWF0OiBwcm9qZWN0cy8ke3BfaWR9L2xvY2F0aW9ucy8ke2xfaWR9L2NvcnBvcmEvJHtjX2lk
fS9hc3NldHMvJHthX2lkfQogUmVtYWluIGVtcHR5IGlmIHRoZSBtZWRpYSB3YXJlaG91c2Ug
c3RvcmFnZSBpcyBub3QgbmVlZGVkIGZvciB0aGUgc3RyZWFtLgoKDAoFBAACBwUSA0ICCAoM
CgUEAAIHARIDQgkeCgwKBQQAAgcDEgNCISIKMgoCBAESBEYAcgEaJiBNZXNzYWdlIGRlc2Ny
aWJpbmcgdGhlIEV2ZW50IG9iamVjdC4KCgoKAwQBARIDRggNCgsKAwQBBxIERwJKBAoNCgUE
AQedCBIERwJKBAo8CgQEAQQAEgRNAlcDGi4gQ2xvY2sgdGhhdCB3aWxsIGJlIHVzZWQgZm9y
IGpvaW5pbmcgc3RyZWFtcy4KCgwKBQQBBAABEgNNBwwKKAoGBAEEAAIAEgNPBBoaGSBDbG9j
ayBpcyBub3Qgc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDTwQVCg4KBwQBBAACAAISA08YGQpe
CgYEAQQAAgESA1MEEBpPIFVzZSB0aGUgdGltZXN0YW1wIHdoZW4gdGhlIGRhdGEgaXMgY2Fw
dHVyZWQuIENsaWVudHMgbmVlZCB0byBzeW5jIHRoZQogY2xvY2suCgoOCgcEAQQAAgEBEgNT
BAsKDgoHBAEEAAIBAhIDUw4PCj0KBgQBBAACAhIDVgQPGi4gVXNlIHRoZSB0aW1lc3RhbXAg
d2hlbiB0aGUgZGF0YSBpcyByZWNlaXZlZC4KCg4KBwQBBAACAgESA1YECgoOCgcEAQQAAgIC
EgNWDQ4KJAoEBAECABIDWgISGhcgTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoMCgUEAQIABRID
WgIICgwKBQQBAgABEgNaCQ0KDAoFBAECAAMSA1oQEQoyCgQEAQIBEgRdAl4yGiQgT3V0cHV0
IG9ubHkuIFRoZSBjcmVhdGUgdGltZXN0YW1wLgoKDAoFBAECAQYSA10CGwoMCgUEAQIBARID
XRwnCgwKBQQBAgEDEgNdKisKDAoFBAECAQgSA14GMQoPCggEAQIBCJwIABIDXgcwCjIKBAQB
AgISBGECYjIaJCBPdXRwdXQgb25seS4gVGhlIHVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAQIC
BhIDYQIbCgwKBQQBAgIBEgNhHCcKDAoFBAECAgMSA2EqKwoMCgUEAQICCBIDYgYxCg8KCAQB
AgIInAgAEgNiBzAKKQoEBAECAxIDZQIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4K
CgwKBQQBAgMGEgNlAhUKDAoFBAECAwESA2UWHAoMCgUEAQIDAxIDZR8gClUKBAQBAgQSA2gC
JhpIIEFubm90YXRpb25zIHRvIGFsbG93IGNsaWVudHMgdG8gc3RvcmUgc21hbGwgYW1vdW50
cyBvZiBhcmJpdHJhcnkgZGF0YS4KCgwKBQQBAgQGEgNoAhUKDAoFBAECBAESA2gWIQoMCgUE
AQIEAxIDaCQlCjIKBAQBAgUSA2sCHBolIFRoZSBjbG9jayB1c2VkIGZvciBqb2luaW5nIHN0
cmVhbXMuCgoMCgUEAQIFBhIDawIHCgwKBQQBAgUBEgNrCBcKDAoFBAECBQMSA2saGwr+AQoE
BAECBhIDcQIsGvABIEdyYWNlIHBlcmlvZCBmb3IgY2xlYW5pbmcgdXAgdGhlIGV2ZW50LiBU
aGlzIGlzIHRoZSB0aW1lIHRoZSBjb250cm9sbGVyCiB3YWl0cyBmb3IgYmVmb3JlIGRlbGV0
aW5nIHRoZSBldmVudC4gRHVyaW5nIHRoaXMgcGVyaW9kLCBpZiB0aGVyZSBpcyBhbnkKIGFj
dGl2ZSBjaGFubmVsIG9uIHRoZSBldmVudC4gVGhlIGRlbGV0aW9uIG9mIHRoZSBldmVudCBh
ZnRlciBncmFjZV9wZXJpb2QKIHdpbGwgYmUgaWdub3JlZC4KCgwKBQQBAgYGEgNxAhoKDAoF
BAECBgESA3EbJwoMCgUEAQIGAxIDcSorCjQKAgQCEgV1AJcBARonIE1lc3NhZ2UgZGVzY3Jp
YmluZyB0aGUgU2VyaWVzIG9iamVjdC4KCgoKAwQCARIDdQgOCgsKAwQCBxIEdgJ5BAoNCgUE
AgedCBIEdgJ5BAokCgQEAgIAEgN8AhIaFyBOYW1lIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQC
AgAFEgN8AggKDAoFBAICAAESA3wJDQoMCgUEAgIAAxIDfBARCjMKBAQCAgESBX8CgAEyGiQg
T3V0cHV0IG9ubHkuIFRoZSBjcmVhdGUgdGltZXN0YW1wLgoKDAoFBAICAQYSA38CGwoMCgUE
AgIBARIDfxwnCgwKBQQCAgEDEgN/KisKDQoFBAICAQgSBIABBjEKEAoIBAICAQicCAASBIAB
BzAKNAoEBAICAhIGgwEChAEyGiQgT3V0cHV0IG9ubHkuIFRoZSB1cGRhdGUgdGltZXN0YW1w
LgoKDQoFBAICAgYSBIMBAhsKDQoFBAICAgESBIMBHCcKDQoFBAICAgMSBIMBKisKDQoFBAIC
AggSBIQBBjEKEAoIBAICAgicCAASBIQBBzAKKgoEBAICAxIEhwECIRocIExhYmVscyBhcyBr
ZXkgdmFsdWUgcGFpcnMuCgoNCgUEAgIDBhIEhwECFQoNCgUEAgIDARIEhwEWHAoNCgUEAgID
AxIEhwEfIApWCgQEAgIEEgSKAQImGkggQW5ub3RhdGlvbnMgdG8gYWxsb3cgY2xpZW50cyB0
byBzdG9yZSBzbWFsbCBhbW91bnRzIG9mIGFyYml0cmFyeSBkYXRhLgoKDQoFBAICBAYSBIoB
AhUKDQoFBAICBAESBIoBFiEKDQoFBAICBAMSBIoBJCUKRwoEBAICBRIGjQECkAEEGjcgUmVx
dWlyZWQuIFN0cmVhbSB0aGF0IGlzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHNlcmllcy4KCg0K
BQQCAgUFEgSNAQIICg0KBQQCAgUBEgSNAQkPCg0KBQQCAgUDEgSNARITCg8KBQQCAgUIEgaN
ARSQAQMKEAoIBAICBQicCAASBI4BBCoKDwoHBAICBQifCBIEjwEEUApGCgQEAgIGEgaTAQKW
AQQaNiBSZXF1aXJlZC4gRXZlbnQgdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGggdGhpcyBzZXJp
ZXMuCgoNCgUEAgIGBRIEkwECCAoNCgUEAgIGARIEkwEJDgoNCgUEAgIGAxIEkwEREgoPCgUE
AgIGCBIGkwETlgEDChAKCAQCAgYInAgAEgSUAQQqCg8KBwQCAgYInwgSBJUBBE8KNgoCBAMS
BpoBALwBARooIE1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgQ2hhbm5lbCBvYmplY3QuCgoLCgME
AwESBJoBCA8KDQoDBAMHEgabAQKeAQQKDwoFBAMHnQgSBpsBAp4BBAolCgQEAwIAEgShAQIS
GhcgTmFtZSBvZiB0aGUgcmVzb3VyY2UuCgoNCgUEAwIABRIEoQECCAoNCgUEAwIAARIEoQEJ
DQoNCgUEAwIAAxIEoQEQEQo0CgQEAwIBEgakAQKlATIaJCBPdXRwdXQgb25seS4gVGhlIGNy
ZWF0ZSB0aW1lc3RhbXAuCgoNCgUEAwIBBhIEpAECGwoNCgUEAwIBARIEpAEcJwoNCgUEAwIB
AxIEpAEqKwoNCgUEAwIBCBIEpQEGMQoQCggEAwIBCJwIABIEpQEHMAo0CgQEAwICEgaoAQKp
ATIaJCBPdXRwdXQgb25seS4gVGhlIHVwZGF0ZSB0aW1lc3RhbXAuCgoNCgUEAwICBhIEqAEC
GwoNCgUEAwICARIEqAEcJwoNCgUEAwICAxIEqAEqKwoNCgUEAwICCBIEqQEGMQoQCggEAwIC
CJwIABIEqQEHMAoqCgQEAwIDEgSsAQIhGhwgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycy4K
Cg0KBQQDAgMGEgSsAQIVCg0KBQQDAgMBEgSsARYcCg0KBQQDAgMDEgSsAR8gClYKBAQDAgQS
BK8BAiYaSCBBbm5vdGF0aW9ucyB0byBhbGxvdyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFt
b3VudHMgb2YgYXJiaXRyYXJ5IGRhdGEuCgoNCgUEAwIEBhIErwECFQoNCgUEAwIEARIErwEW
IQoNCgUEAwIEAxIErwEkJQpHCgQEAwIFEgayAQK1AQQaNyBSZXF1aXJlZC4gU3RyZWFtIHRo
YXQgaXMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgc2VyaWVzLgoKDQoFBAMCBQUSBLIBAggKDQoF
BAMCBQESBLIBCQ8KDQoFBAMCBQMSBLIBEhMKDwoFBAMCBQgSBrIBFLUBAwoQCggEAwIFCJwI
ABIEswEEKgoPCgcEAwIFCJ8IEgS0AQRQCkYKBAQDAgYSBrgBArsBBBo2IFJlcXVpcmVkLiBF
dmVudCB0aGF0IGlzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIHNlcmllcy4KCg0KBQQDAgYFEgS4
AQIICg0KBQQDAgYBEgS4AQkOCg0KBQQDAgYDEgS4ARESCg8KBQQDAgYIEga4ARO7AQMKEAoI
BAMCBgicCAASBLkBBCoKDwoHBAMCBgifCBIEugEET2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::StreamsResources::Stream ===
    # Fields for Stream
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Stream.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1.Stream.AnnotationsEntry)
    # Field: display_name Type: 9 ()
    # Field: enable_hls_playback Type: 8 ()
    # Field: media_warehouse_asset Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamsResources::Event ===
    # Fields for Event
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Event.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1.Event.AnnotationsEntry)
    # Field: alignment_clock Type: 14 (.google.cloud.visionai.v1.Event.Clock)
    # Field: grace_period Type: 11 (.google.protobuf.Duration)

# Enum: Event::Clock
our $Event_CLOCK_UNSPECIFIED = 0;
our $Event_CAPTURE = 1;
our $Event_INGEST = 2;

# === Message: Google::Cloud::Visionai::V1::StreamsResources::Series ===
    # Fields for Series
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Series.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1.Series.AnnotationsEntry)
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::StreamsResources::Channel ===
    # Fields for Channel
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Channel.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1.Channel.AnnotationsEntry)
    # Field: stream Type: 9 ()
    # Field: event Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::StreamsResources - Compiled Protocol Buffers messages for google/cloud/visionai/v1/streams_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::StreamsResources;

    my $msg = Google::Cloud::Visionai::V1::StreamsResources::Stream->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::StreamsResources::Stream->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/streams_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::StreamsResources::Stream

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

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Stream::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Stream::AnnotationsEntry>)

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

=head2 Google::Cloud::Visionai::V1::StreamsResources::Event

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

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Event::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Event::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->alignment_clock() >> / C<< $msg->alignment_clock($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::Event::Clock>)

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

=head2 Google::Cloud::Visionai::V1::StreamsResources::Series

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

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Series::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Series::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

Required. Stream that is associated with this series.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

Required. Event that is associated with this series.

=back

=head2 Google::Cloud::Visionai::V1::StreamsResources::Channel

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

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Channel::LabelsEntry>)

Labels as key value pairs.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::StreamsResources::Channel::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->stream() >> / C<< $msg->stream($value) >>

Type: C<String>

Required. Stream that is associated with this series.

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<String>

Required. Event that is associated with this series.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::StreamsResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
