package Google::Devtools::Artifactregistry::V1::File;

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
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9maWxlLnByb3RvEiNnb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iswEK
BEhhc2gSRgoEdHlwZRgBIAEoDjIyLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5
LnYxLkhhc2guSGFzaFR5cGVSBHR5cGUSFAoFdmFsdWUYAiABKAxSBXZhbHVlIk0KCEhhc2hU
eXBlEhkKFUhBU0hfVFlQRV9VTlNQRUNJRklFRBAAEgoKBlNIQTI1NhABEgcKA01ENRACEhEK
DURJUlNVTV9TSEEyNTYQAyL0BAoERmlsZRISCgRuYW1lGAEgASgJUgRuYW1lEh0KCnNpemVf
Ynl0ZXMYAyABKANSCXNpemVCeXRlcxJBCgZoYXNoZXMYBCADKAsyKS5nb29nbGUuZGV2dG9v
bHMuYXJ0aWZhY3RyZWdpc3RyeS52MS5IYXNoUgZoYXNoZXMSQAoLY3JlYXRlX3RpbWUYBSAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBk
YXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0
ZVRpbWUSFAoFb3duZXIYByABKAlSBW93bmVyEj4KCmZldGNoX3RpbWUYCCABKAsyGi5nb29n
bGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCWZldGNoVGltZRJhCgthbm5vdGF0aW9ucxgJ
IAMoCzI6Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxLkZpbGUuQW5ub3Rh
dGlvbnNFbnRyeUID4EEBUgthbm5vdGF0aW9ucxo+ChBBbm5vdGF0aW9uc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6eepBdgokYXJ0aWZhY3Ry
ZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9GaWxlEk5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBvc2l0b3J5fS9maWxlcy97ZmlsZX0i
xwEKEExpc3RGaWxlc1JlcXVlc3QSRAoGcGFyZW50GAEgASgJQizgQQL6QSYSJGFydGlmYWN0
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vRmlsZVIGcGFyZW50EhYKBmZpbHRlchgEIAEoCVIG
ZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEo
CVIJcGFnZVRva2VuEhkKCG9yZGVyX2J5GAUgASgJUgdvcmRlckJ5InwKEUxpc3RGaWxlc1Jl
c3BvbnNlEj8KBWZpbGVzGAEgAygLMikuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0
cnkudjEuRmlsZVIFZmlsZXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuIlIKDkdldEZpbGVSZXF1ZXN0EkAKBG5hbWUYASABKAlCLOBBAvpBJgokYXJ0aWZhY3Ry
ZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9GaWxlUgRuYW1lIlUKEURlbGV0ZUZpbGVSZXF1ZXN0
EkAKBG5hbWUYASABKAlCLOBBAvpBJgokYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNv
bS9GaWxlUgRuYW1lIpkBChFVcGRhdGVGaWxlUmVxdWVzdBJCCgRmaWxlGAEgASgLMikuZ29v
Z2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjEuRmlsZUID4EECUgRmaWxlEkAKC3Vw
ZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EECUgp1cGRh
dGVNYXNrQvQBCidjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFCCUZp
bGVQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2FydGlmYWN0cmVnaXN0cnkvYXBpdjEv
YXJ0aWZhY3RyZWdpc3RyeXBiO2FydGlmYWN0cmVnaXN0cnlwYqoCIEdvb2dsZS5DbG91ZC5B
cnRpZmFjdFJlZ2lzdHJ5LlYxygIgR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjHq
AiNHb29nbGU6OkNsb3VkOjpBcnRpZmFjdFJlZ2lzdHJ5OjpWMUrUNAoHEgUOANABAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkK
AgMBEgMTACMKCQoCAwISAxQAKgoJCgIDAxIDFQApCggKAQgSAxcAPQoJCgIIJRIDFwA9CggK
AQgSAxgAZwoJCgIICxIDGABnCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAKgoJCgII
CBIDGgAqCggKAQgSAxsAQAoJCgIIARIDGwBACggKAQgSAxwAPQoJCgIIKRIDHAA9CggKAQgS
Ax0APAoJCgIILRIDHQA8CiUKAgQAEgQgADUBGhkgQSBoYXNoIG9mIGZpbGUgY29udGVudC4K
CgoKAwQAARIDIAgMCjcKBAQABAASBCICLgMaKSBUaGUgYWxnb3JpdGhtIHVzZWQgdG8gY29t
cHV0ZSB0aGUgaGFzaC4KCgwKBQQABAABEgMiBw8KHQoGBAAEAAIAEgMkBB4aDiBVbnNwZWNp
ZmllZC4KCg4KBwQABAACAAESAyQEGQoOCgcEAAQAAgACEgMkHB0KHQoGBAAEAAIBEgMnBA8a
DiBTSEEyNTYgaGFzaC4KCg4KBwQABAACAQESAycECgoOCgcEAAQAAgECEgMnDQ4KGgoGBAAE
AAICEgMqBAwaCyBNRDUgaGFzaC4KCg4KBwQABAACAgESAyoEBwoOCgcEAAQAAgICEgMqCgsK
JAoGBAAEAAIDEgMtBBYaFSBEaXJzdW0gU0hBMjU2IGhhc2guCgoOCgcEAAQAAgMBEgMtBBEK
DgoHBAAEAAIDAhIDLRQVCjwKBAQAAgASAzECFBovIFRoZSBhbGdvcml0aG0gdXNlZCB0byBj
b21wdXRlIHRoZSBoYXNoIHZhbHVlLgoKDAoFBAACAAYSAzECCgoMCgUEAAIAARIDMQsPCgwK
BQQAAgADEgMxEhMKHgoEBAACARIDNAISGhEgVGhlIGhhc2ggdmFsdWUuCgoMCgUEAAIBBRID
NAIHCgwKBQQAAgEBEgM0CA0KDAoFBAACAQMSAzQQEQpbCgIEARIEOABbARpPIEZpbGVzIHN0
b3JlIGNvbnRlbnQgdGhhdCBpcyBwb3RlbnRpYWxseSBhc3NvY2lhdGVkIHdpdGggUGFja2Fn
ZXMgb3IgVmVyc2lvbnMuCgoKCgMEAQESAzgIDAoLCgMEAQcSBDkCPAQKDQoFBAEHnQgSBDkC
PAQKuAEKBAQBAgASA0ECEhqqASBUaGUgbmFtZSBvZiB0aGUgZmlsZSwgZm9yIGV4YW1wbGU6
CiBgcHJvamVjdHMvcDEvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBv
MS9maWxlcy9hJTJGYiUyRmMudHh0YC4KIElmIHRoZSBmaWxlIElEIHBhcnQgY29udGFpbnMg
c2xhc2hlcywgdGhleSBhcmUgZXNjYXBlZC4KCgwKBQQBAgAFEgNBAggKDAoFBAECAAESA0EJ
DQoMCgUEAQIAAxIDQRARCi0KBAQBAgESA0QCFxogIFRoZSBzaXplIG9mIHRoZSBGaWxlIGlu
IGJ5dGVzLgoKDAoFBAECAQUSA0QCBwoMCgUEAQIBARIDRAgSCgwKBQQBAgEDEgNEFRYKLgoE
BAECAhIDRwIbGiEgVGhlIGhhc2hlcyBvZiB0aGUgZmlsZSBjb250ZW50LgoKDAoFBAECAgQS
A0cCCgoMCgUEAQICBhIDRwsPCgwKBQQBAgIBEgNHEBYKDAoFBAECAgMSA0cZGgpACgQEAQID
EgRKAksyGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhlIEZpbGUgd2FzIGNyZWF0
ZWQuCgoMCgUEAQIDBhIDSgIbCgwKBQQBAgMBEgNKHCcKDAoFBAECAwMSA0oqKwoMCgUEAQID
CBIDSwYxCg8KCAQBAgMInAgAEgNLBzAKRQoEBAECBBIETgJPMho3IE91dHB1dCBvbmx5LiBU
aGUgdGltZSB3aGVuIHRoZSBGaWxlIHdhcyBsYXN0IHVwZGF0ZWQuCgoMCgUEAQIEBhIDTgIb
CgwKBQQBAgQBEgNOHCcKDAoFBAECBAMSA04qKwoMCgUEAQIECBIDTwYxCg8KCAQBAgQInAgA
EgNPBzAKTgoEBAECBRIDUgITGkEgVGhlIG5hbWUgb2YgdGhlIFBhY2thZ2Ugb3IgVmVyc2lv
biB0aGF0IG93bnMgdGhpcyBmaWxlLCBpZiBhbnkuCgoMCgUEAQIFBRIDUgIICgwKBQQBAgUB
EgNSCQ4KDAoFBAECBQMSA1IREgqJAQoEBAECBhIEVgJXMhp7IE91dHB1dCBvbmx5LiBUaGUg
dGltZSB3aGVuIHRoZSBsYXN0IGF0dGVtcHQgdG8gcmVmcmVzaCB0aGUgZmlsZSdzIGRhdGEg
d2FzCiBtYWRlLiBPbmx5IHNldCB3aGVuIHRoZSByZXBvc2l0b3J5IGlzIHJlbW90ZS4KCgwK
BQQBAgYGEgNWAhsKDAoFBAECBgESA1YcJgoMCgUEAQIGAxIDVikqCgwKBQQBAgYIEgNXBjEK
DwoIBAECBgicCAASA1cHMAo2CgQEAQIHEgNaAk8aKSBPcHRpb25hbC4gQ2xpZW50IHNwZWNp
ZmllZCBhbm5vdGF0aW9ucy4KCgwKBQQBAgcGEgNaAhUKDAoFBAECBwESA1oWIQoMCgUEAQIH
AxIDWiQlCgwKBQQBAgcIEgNaJk4KDwoIBAECBwicCAASA1onTQopCgIEAhIFXgCkAQEaHCBU
aGUgcmVxdWVzdCB0byBsaXN0IGZpbGVzLgoKCgoDBAIBEgNeCBgKlQEKBAQCAgASBGECZgQa
hgEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSByZXBvc2l0b3J5IHdob3NlIGZpbGVzIHdp
bGwgYmUgbGlzdGVkLiBGb3IKIGV4YW1wbGU6ICJwcm9qZWN0cy9wMS9sb2NhdGlvbnMvdXMt
Y2VudHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xCgoMCgUEAgIABRIDYQIICgwKBQQCAgABEgNh
CQ8KDAoFBAICAAMSA2ESEwoNCgUEAgIACBIEYRRmAwoPCggEAgIACJwIABIDYgQqCg8KBwQC
AgAInwgSBGMEZQUK2hAKBAQCAgESBJoBAhQayxAgQW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVy
aW5nIHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LiBGaWx0ZXIgcnVsZXMgYXJlCiBjYXNl
IGluc2Vuc2l0aXZlLiBUaGUgZmllbGRzIGVsaWdpYmxlIGZvciBmaWx0ZXJpbmcgYXJlOgoK
ICAgKiBgbmFtZWAKICAgKiBgb3duZXJgCiAgICogYGFubm90YXRpb25zYAoKIEV4YW1wbGVz
IG9mIHVzaW5nIGEgZmlsdGVyOgoKICBUbyBmaWx0ZXIgdGhlIHJlc3VsdHMgb2YgeW91ciBy
ZXF1ZXN0IHRvIGZpbGVzIHdpdGggdGhlIG5hbWUgYG15X2ZpbGUudHh0YAogIGluIHByb2pl
Y3QgYG15LXByb2plY3RgIGluIHRoZSBgdXMtY2VudHJhbGAgcmVnaW9uLCBpbiByZXBvc2l0
b3J5CiAgYG15LXJlcG9gLCBhcHBlbmQgdGhlIGZvbGxvd2luZyBmaWx0ZXIgZXhwcmVzc2lv
biB0byB5b3VyIHJlcXVlc3Q6CgogICAqIGBuYW1lPSJwcm9qZWN0cy9teS1wcm9qZWN0L2xv
Y2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0b3JpZXMvbXktcmVwby9maWxlcy9teS1maWxl
LnR4dCJgCgogIFlvdSBjYW4gYWxzbyB1c2Ugd2lsZGNhcmRzIHRvIG1hdGNoIGFueSBudW1i
ZXIgb2YgY2hhcmFjdGVycyBiZWZvcmUgb3IKICBhZnRlciB0aGUgdmFsdWU6CgogICAqIGBu
YW1lPSJwcm9qZWN0cy9teS1wcm9qZWN0L2xvY2F0aW9ucy91cy1jZW50cmFsMS9yZXBvc2l0
b3JpZXMvbXktcmVwby9maWxlcy9teS0qImAKICAgKiBgbmFtZT0icHJvamVjdHMvbXktcHJv
amVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVwb3NpdG9yaWVzL215LXJlcG8vZmlsZXMv
KmZpbGUudHh0ImAKICAgKiBgbmFtZT0icHJvamVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMv
dXMtY2VudHJhbDEvcmVwb3NpdG9yaWVzL215LXJlcG8vZmlsZXMvKmZpbGUqImAKCiAgVG8g
ZmlsdGVyIHRoZSByZXN1bHRzIG9mIHlvdXIgcmVxdWVzdCB0byBmaWxlcyBvd25lZCBieSB0
aGUgdmVyc2lvbiBgMS4wYAogIGluIHBhY2thZ2UgYHBrZzFgLCBhcHBlbmQgdGhlIGZvbGxv
d2luZyBmaWx0ZXIgZXhwcmVzc2lvbiB0byB5b3VyIHJlcXVlc3Q6CgogICAqIGBvd25lcj0i
cHJvamVjdHMvbXktcHJvamVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEvcmVwb3NpdG9yaWVz
L215LXJlcG8vcGFja2FnZXMvbXktcGFja2FnZS92ZXJzaW9ucy8xLjAiYAoKICBUbyBmaWx0
ZXIgdGhlIHJlc3VsdHMgb2YgeW91ciByZXF1ZXN0IHRvIGZpbGVzIHdpdGggdGhlIGFubm90
YXRpb24KICBrZXktdmFsdWUgcGFpciBbYGV4dGVybmFsX2xpbmtgOiBgZXh0ZXJuYWxfbGlu
a192YWx1ZWBdLCBhcHBlbmQgdGhlCiAgZm9sbG93aW5nIGZpbHRlciBleHByZXNzaW9uIHRv
IHlvdXIgcmVxdWVzdDoKCiAgICogYCJhbm5vdGF0aW9ucy5leHRlcm5hbF9saW5rOmV4dGVy
bmFsX2xpbmtfdmFsdWUiYAoKICBUbyBmaWx0ZXIganVzdCBmb3IgYSBzcGVjaWZpYyBhbm5v
dGF0aW9uIGtleSBgZXh0ZXJuYWxfbGlua2AsIGFwcGVuZCB0aGUKICBmb2xsb3dpbmcgZmls
dGVyIGV4cHJlc3Npb24gdG8geW91ciByZXF1ZXN0OgoKICAgKiBgImFubm90YXRpb25zLmV4
dGVybmFsX2xpbmsiYAoKICBJZiB0aGUgYW5ub3RhdGlvbiBrZXkgb3IgdmFsdWUgY29udGFp
bnMgc3BlY2lhbCBjaGFyYWN0ZXJzLCB5b3UgY2FuIGVzY2FwZQogIHRoZW0gYnkgc3Vycm91
bmRpbmcgdGhlIHZhbHVlIHdpdGggYmFja3RpY2tzLiBGb3IgZXhhbXBsZSwgdG8gZmlsdGVy
IHRoZQogIHJlc3VsdHMgb2YgeW91ciByZXF1ZXN0IHRvIGZpbGVzIHdpdGggdGhlIGFubm90
YXRpb24ga2V5LXZhbHVlIHBhaXIKICBbYGV4dGVybmFsLmxpbmtgOmBodHRwczovL2V4YW1w
bGUuY29tL215LWZpbGVgXSwgYXBwZW5kIHRoZSBmb2xsb3dpbmcKICBmaWx0ZXIgZXhwcmVz
c2lvbiB0byB5b3VyIHJlcXVlc3Q6CgogICAqIGBgICJhbm5vdGF0aW9ucy5gZXh0ZXJuYWwu
bGlua2A6YGh0dHBzOi8vZXhhbXBsZS5jb20vbXktZmlsZWAiIGBgCgogIFlvdSBjYW4gYWxz
byBmaWx0ZXIgd2l0aCBhbm5vdGF0aW9ucyB3aXRoIGEgd2lsZGNhcmQgdG8KICBtYXRjaCBh
bnkgbnVtYmVyIG9mIGNoYXJhY3RlcnMgYmVmb3JlIG9yIGFmdGVyIHRoZSB2YWx1ZToKCiAg
ICogYGAgImFubm90YXRpb25zLipfbGluazpgKmV4YW1wbGUuY29tKmAiIGBgCgoNCgUEAgIB
BRIEmgECCAoNCgUEAgIBARIEmgEJDwoNCgUEAgIBAxIEmgESEwpSCgQEAgICEgSdAQIWGkQg
VGhlIG1heGltdW0gbnVtYmVyIG9mIGZpbGVzIHRvIHJldHVybi4gTWF4aW11bSBwYWdlIHNp
emUgaXMgMSwwMDAuCgoNCgUEAgICBRIEnQECBwoNCgUEAgICARIEnQEIEQoNCgUEAgICAxIE
nQEUFQpYCgQEAgIDEgSgAQIYGkogVGhlIG5leHRfcGFnZV90b2tlbiB2YWx1ZSByZXR1cm5l
ZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBhbnkuCgoNCgUEAgIDBRIEoAEC
CAoNCgUEAgIDARIEoAEJEwoNCgUEAgIDAxIEoAEWFwoyCgQEAgIEEgSjAQIWGiQgVGhlIGZp
ZWxkIHRvIG9yZGVyIHRoZSByZXN1bHRzIGJ5LgoKDQoFBAICBAUSBKMBAggKDQoFBAICBAES
BKMBCREKDQoFBAICBAMSBKMBFBUKMAoCBAMSBqcBAK4BARoiIFRoZSByZXNwb25zZSBmcm9t
IGxpc3RpbmcgZmlsZXMuCgoLCgMEAwESBKcBCBkKIwoEBAMCABIEqQECGhoVIFRoZSBmaWxl
cyByZXR1cm5lZC4KCg0KBQQDAgAEEgSpAQIKCg0KBQQDAgAGEgSpAQsPCg0KBQQDAgABEgSp
ARAVCg0KBQQDAgADEgSpARgZCm0KBAQDAgESBK0BAh0aXyBUaGUgdG9rZW4gdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZSBvZiBmaWxlcywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5vCiBt
b3JlIGZpbGVzIHRvIHJldHVybi4KCg0KBQQDAgEFEgStAQIICg0KBQQDAgEBEgStAQkYCg0K
BQQDAgEDEgStARscCi8KAgQEEgaxAQC5AQEaISBUaGUgcmVxdWVzdCB0byByZXRyaWV2ZSBh
IGZpbGUuCgoLCgMEBAESBLEBCBYKPQoEBAQCABIGswECuAEEGi0gUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBmaWxlIHRvIHJldHJpZXZlLgoKDQoFBAQCAAUSBLMBAggKDQoFBAQCAAES
BLMBCQ0KDQoFBAQCAAMSBLMBEBEKDwoFBAQCAAgSBrMBErgBAwoQCggEBAIACJwIABIEtAEE
KgoRCgcEBAIACJ8IEga1AQS3AQUKLQoCBAUSBrwBAMQBARofIFRoZSByZXF1ZXN0IHRvIGRl
bGV0ZSBhIGZpbGUuCgoLCgMEBQESBLwBCBkKOwoEBAUCABIGvgECwwEEGisgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBmaWxlIHRvIGRlbGV0ZS4KCg0KBQQFAgAFEgS+AQIICg0KBQQF
AgABEgS+AQkNCg0KBQQFAgADEgS+ARARCg8KBQQFAgAIEga+ARLDAQMKEAoIBAUCAAicCAAS
BL8BBCoKEQoHBAUCAAifCBIGwAEEwgEFCi0KAgQGEgbHAQDQAQEaHyBUaGUgcmVxdWVzdCB0
byB1cGRhdGUgYSBmaWxlLgoKCwoDBAYBEgTHAQgZCkwKBAQGAgASBMkBAjkaPiBSZXF1aXJl
ZC4gVGhlIEZpbGUgdGhhdCByZXBsYWNlcyB0aGUgcmVzb3VyY2Ugb24gdGhlIHNlcnZlci4K
Cg0KBQQGAgAGEgTJAQIGCg0KBQQGAgABEgTJAQcLCg0KBQQGAgADEgTJAQ4PCg0KBQQGAgAI
EgTJARA4ChAKCAQGAgAInAgAEgTJARE3CsMBCgQEBgIBEgbOAQLPAS8asgEgUmVxdWlyZWQu
IFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRvIHRoZSByZXNvdXJjZS4gRm9yIHRoZSBgRmll
bGRNYXNrYAogZGVmaW5pdGlvbiwgc2VlCiBodHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNv
bS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVmZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNmaWVs
ZG1hc2sKCg0KBQQGAgEGEgTOAQIbCg0KBQQGAgEBEgTOARwnCg0KBQQGAgEDEgTOASorCg0K
BQQGAgEIEgTPAQYuChAKCAQGAgEInAgAEgTPAQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::File::Hash ===
    # Fields for Hash
    # Field: type Type: 14 (.google.devtools.artifactregistry.v1.Hash.HashType)
    # Field: value Type: 12 ()

# Enum: Hash::HashType
our $Hash_HASH_TYPE_UNSPECIFIED = 0;
our $Hash_SHA256 = 1;
our $Hash_MD5 = 2;
our $Hash_DIRSUM_SHA256 = 3;

# === Message: Google::Devtools::Artifactregistry::V1::File::File ===
    # Fields for File
    # Field: name Type: 9 ()
    # Field: size_bytes Type: 3 ()
    # Field: hashes Type: 11 (.google.devtools.artifactregistry.v1.Hash)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: owner Type: 9 ()
    # Field: fetch_time Type: 11 (.google.protobuf.Timestamp)
    # Field: annotations Type: 11 (.google.devtools.artifactregistry.v1.File.AnnotationsEntry)

# === Message: Google::Devtools::Artifactregistry::V1::File::ListFilesRequest ===
    # Fields for ListFilesRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::File::ListFilesResponse ===
    # Fields for ListFilesResponse
    # Field: files Type: 11 (.google.devtools.artifactregistry.v1.File)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::File::GetFileRequest ===
    # Fields for GetFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::File::DeleteFileRequest ===
    # Fields for DeleteFileRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::File::UpdateFileRequest ===
    # Fields for UpdateFileRequest
    # Field: file Type: 11 (.google.devtools.artifactregistry.v1.File)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::File - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/file.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::File;

    my $msg = Google::Devtools::Artifactregistry::V1::File::Hash->new({
        type => $type,
        value => $value,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::File::Hash->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::File::Hash

A hash of file content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Devtools::Artifactregistry::V1::Hash::HashType>)

The algorithm used to compute the hash value.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bytes>

The hash value.

=back

=head3 Enum: Hash::HashType

=over 4

=item * C<HASH_TYPE_UNSPECIFIED> => C<0>

=item * C<SHA256> => C<1>

=item * C<MD5> => C<2>

=item * C<DIRSUM_SHA256> => C<3>

=back

=head2 Google::Devtools::Artifactregistry::V1::File::File

Files store content that is potentially associated with Packages or Versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the file, for example:
`projects/p1/locations/us-central1/repositories/repo1/files/a%2Fb%2Fc.txt`.
If the file ID part contains slashes, they are escaped.

=item * C<< $msg->size_bytes() >> / C<< $msg->size_bytes($value) >>

Type: C<Int64>

The size of the File in bytes.

=item * C<< $msg->hashes() >> / C<< $msg->hashes($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::File::Hash>)

The hashes of the file content.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the File was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the File was last updated.

=item * C<< $msg->owner() >> / C<< $msg->owner($value) >>

Type: C<String>

The name of the Package or Version that owns this file, if any.

=item * C<< $msg->fetch_time() >> / C<< $msg->fetch_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the last attempt to refresh the file's data was
made. Only set when the repository is remote.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::File::File::AnnotationsEntry>)

Optional. Client specified annotations.

=back

=head2 Google::Devtools::Artifactregistry::V1::File::ListFilesRequest

The request to list files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the repository whose files will be listed. For
example: "projects/p1/locations/us-central1/repositories/repo1

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression for filtering the results of the request. Filter rules are
case insensitive. The fields eligible for filtering are:

  * `name`
  * `owner`
  * `annotations`

Examples of using a filter:

 To filter the results of your request to files with the name `my_file.txt`
 in project `my-project` in the `us-central` region, in repository
 `my-repo`, append the following filter expression to your request:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/files/my-file.txt"`

 You can also use wildcards to match any number of characters before or
 after the value:

  * `name="projects/my-project/locations/us-central1/repositories/my-repo/files/my-*"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/files/*file.txt"`
  * `name="projects/my-project/locations/us-central1/repositories/my-repo/files/*file*"`

 To filter the results of your request to files owned by the version `1.0`
 in package `pkg1`, append the following filter expression to your request:

  * `owner="projects/my-project/locations/us-central1/repositories/my-repo/packages/my-package/versions/1.0"`

 To filter the results of your request to files with the annotation
 key-value pair [`external_link`: `external_link_value`], append the
 following filter expression to your request:

  * `"annotations.external_link:external_link_value"`

 To filter just for a specific annotation key `external_link`, append the
 following filter expression to your request:

  * `"annotations.external_link"`

 If the annotation key or value contains special characters, you can escape
 them by surrounding the value with backticks. For example, to filter the
 results of your request to files with the annotation key-value pair
 [`external.link`:`https://example.com/my-file`], append the following
 filter expression to your request:

  * `` "annotations.`external.link`:`https://example.com/my-file`" ``

 You can also filter with annotations with a wildcard to
 match any number of characters before or after the value:

  * `` "annotations.*_link:`*example.com*`" ``

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of files to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

The field to order the results by.

=back

=head2 Google::Devtools::Artifactregistry::V1::File::ListFilesResponse

The response from listing files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::File::File>)

The files returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of files, or empty if there are no
more files to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::File::GetFileRequest

The request to retrieve a file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the file to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1::File::DeleteFileRequest

The request to delete a file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the file to delete.

=back

=head2 Google::Devtools::Artifactregistry::V1::File::UpdateFileRequest

The request to update a file.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file() >> / C<< $msg->file($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::File::File>)

Required. The File that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask`
definition, see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
