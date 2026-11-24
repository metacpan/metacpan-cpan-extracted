package Google::Devtools::Artifactregistry::V1::Attachment;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MS9hdHRhY2htZW50LnByb3Rv
EiNnb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKzBQoKQXR0YWNobWVudBISCgRuYW1lGAEgASgJUgRu
YW1lEhsKBnRhcmdldBgCIAEoCUID4EECUgZ0YXJnZXQSEgoEdHlwZRgDIAEoCVIEdHlwZRIx
ChRhdHRhY2htZW50X25hbWVzcGFjZRgEIAEoCVITYXR0YWNobWVudE5hbWVzcGFjZRJnCgth
bm5vdGF0aW9ucxgFIAMoCzJALmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYx
LkF0dGFjaG1lbnQuQW5ub3RhdGlvbnNFbnRyeUID4EEBUgthbm5vdGF0aW9ucxJACgtjcmVh
dGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRl
VGltZRJACgt1cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IKdXBkYXRlVGltZRJCCgVmaWxlcxgIIAMoCUIs4EEC+kEmCiRhcnRpZmFjdHJlZ2lz
dHJ5Lmdvb2dsZWFwaXMuY29tL0ZpbGVSBWZpbGVzEi0KEG9jaV92ZXJzaW9uX25hbWUYCSAB
KAlCA+BBA1IOb2NpVmVyc2lvbk5hbWUaPgoQQW5ub3RhdGlvbnNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOowB6kGIAQoqYXJ0aWZhY3RyZWdp
c3RyeS5nb29nbGVhcGlzLmNvbS9BdHRhY2htZW50Elpwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vcmVwb3NpdG9yaWVzL3tyZXBvc2l0b3J5fS9hdHRhY2htZW50
cy97YXR0YWNobWVudH0ivQEKFkxpc3RBdHRhY2htZW50c1JlcXVlc3QSSgoGcGFyZW50GAEg
ASgJQjLgQQL6QSwSKmFydGlmYWN0cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vQXR0YWNobWVu
dFIGcGFyZW50EhsKBmZpbHRlchgCIAEoCUID4EEBUgZmaWx0ZXISGwoJcGFnZV9zaXplGAMg
ASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAQgASgJUglwYWdlVG9rZW4ilAEKF0xpc3RB
dHRhY2htZW50c1Jlc3BvbnNlElEKC2F0dGFjaG1lbnRzGAEgAygLMi8uZ29vZ2xlLmRldnRv
b2xzLmFydGlmYWN0cmVnaXN0cnkudjEuQXR0YWNobWVudFILYXR0YWNobWVudHMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIl4KFEdldEF0dGFjaG1lbnRSZXF1
ZXN0EkYKBG5hbWUYASABKAlCMuBBAvpBLAoqYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlz
LmNvbS9BdHRhY2htZW50UgRuYW1lIuUBChdDcmVhdGVBdHRhY2htZW50UmVxdWVzdBJKCgZw
YXJlbnQYASABKAlCMuBBAvpBLBIqYXJ0aWZhY3RyZWdpc3RyeS5nb29nbGVhcGlzLmNvbS9B
dHRhY2htZW50UgZwYXJlbnQSKAoNYXR0YWNobWVudF9pZBgCIAEoCUID4EECUgxhdHRhY2ht
ZW50SWQSVAoKYXR0YWNobWVudBgDIAEoCzIvLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJl
Z2lzdHJ5LnYxLkF0dGFjaG1lbnRCA+BBAlIKYXR0YWNobWVudCJhChdEZWxldGVBdHRhY2ht
ZW50UmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKmFydGlmYWN0cmVnaXN0cnkuZ29v
Z2xlYXBpcy5jb20vQXR0YWNobWVudFIEbmFtZUL6AQonY29tLmdvb2dsZS5kZXZ0b29scy5h
cnRpZmFjdHJlZ2lzdHJ5LnYxQg9BdHRhY2htZW50UHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNv
bS9nby9hcnRpZmFjdHJlZ2lzdHJ5L2FwaXYxL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFj
dHJlZ2lzdHJ5cGKqAiBHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMcoCIEdvb2ds
ZVxDbG91ZFxBcnRpZmFjdFJlZ2lzdHJ5XFYx6gIjR29vZ2xlOjpDbG91ZDo6QXJ0aWZhY3RS
ZWdpc3RyeTo6VjFKyCcKBxIFDgCfAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBID
FgA9CgkKAgglEgMWAD0KCAoBCBIDFwBnCgkKAggLEgMXAGcKCAoBCBIDGAAiCgkKAggKEgMY
ACIKCAoBCBIDGQAwCgkKAggIEgMZADAKCAoBCBIDGgBACgkKAggBEgMaAEAKCAoBCBIDGwA9
CgkKAggpEgMbAD0KCAoBCBIDHAA8CgkKAggtEgMcADwKoAEKAgQAEgQgAFQBGpMBIEFuIEF0
dGFjaG1lbnQgcmVmZXJzIHRvIGFkZGl0aW9uYWwgbWV0YWRhdGEgdGhhdCBjYW4gYmUgYXR0
YWNoZWQgdG8KIGFydGlmYWN0cyBpbiBBcnRpZmFjdCBSZWdpc3RyeS4gQW4gYXR0YWNobWVu
dCBjb25zaXN0cyBvZiBvbmUgb3IgbW9yZSBmaWxlcy4KCgoKAwQAARIDIAgSCgsKAwQABxIE
IQIkBAoNCgUEAAedCBIEIQIkBApvCgQEAAIAEgMoAhIaYiBUaGUgbmFtZSBvZiB0aGUgYXR0
YWNobWVudC4gRS5nLgogYHByb2plY3RzL3AxL2xvY2F0aW9ucy91cy9yZXBvc2l0b3JpZXMv
cmVwby9hdHRhY2htZW50cy9zYm9tYC4KCgwKBQQAAgAFEgMoAggKDAoFBAACAAESAygJDQoM
CgUEAAIAAxIDKBARCrsBCgQEAAIBEgMtAj0arQEgUmVxdWlyZWQuIFRoZSB0YXJnZXQgdGhl
IGF0dGFjaG1lbnQgaXMgZm9yLCBjYW4gYmUgYSBWZXJzaW9uLCBQYWNrYWdlIG9yCiBSZXBv
c2l0b3J5LiBFLmcuCiBgcHJvamVjdHMvcDEvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9z
aXRvcmllcy9yZXBvMS9wYWNrYWdlcy9wMS92ZXJzaW9ucy92MWAuCgoMCgUEAAIBBRIDLQII
CgwKBQQAAgEBEgMtCQ8KDAoFBAACAQMSAy0SEwoMCgUEAAIBCBIDLRQ8Cg8KCAQAAgEInAgA
EgMtFTsKRAoEBAACAhIDMQISGjcgVHlwZSBvZiBhdHRhY2htZW50LgogRS5nLiBgYXBwbGlj
YXRpb24vdm5kLnNwZHgranNvbmAKCgwKBQQAAgIFEgMxAggKDAoFBAACAgESAzEJDQoMCgUE
AAICAxIDMRARCqkBCgQEAAIDEgM2AiIamwEgVGhlIG5hbWVzcGFjZSB0aGlzIGF0dGFjaG1l
bnQgYmVsb25ncyB0by4KIEUuZy4gSWYgYW4gYXR0YWNobWVudCBpcyBjcmVhdGVkIGJ5IGFy
dGlmYWN0IGFuYWx5c2lzLCBuYW1lc3BhY2UgaXMgc2V0CiB0byBgYXJ0aWZhY3RhbmFseXNp
cy5nb29nbGVhcGlzLmNvbWAuCgoMCgUEAAIDBRIDNgIICgwKBQQAAgMBEgM2CR0KDAoFBAAC
AwMSAzYgIQrkAQoEBAACBBIDPAJPGtYBIE9wdGlvbmFsLiBVc2VyIGFubm90YXRpb25zLiBU
aGVzZSBhdHRyaWJ1dGVzIGNhbiBvbmx5IGJlIHNldCBhbmQgdXNlZCBieQogdGhlIHVzZXIs
IGFuZCBub3QgYnkgQXJ0aWZhY3QgUmVnaXN0cnkuIFNlZQogaHR0cHM6Ly9nb29nbGUuYWlw
LmRldi8xMjgjYW5ub3RhdGlvbnMgZm9yIG1vcmUgZGV0YWlscyBzdWNoIGFzIGZvcm1hdCBh
bmQKIHNpemUgbGltaXRhdGlvbnMuCgoMCgUEAAIEBhIDPAIVCgwKBQQAAgQBEgM8FiEKDAoF
BAACBAMSAzwkJQoMCgUEAAIECBIDPCZOCg8KCAQAAgQInAgAEgM8J00KRgoEBAACBRIEPwJA
Mho4IE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBhdHRhY2htZW50IHdhcyBjcmVh
dGVkLgoKDAoFBAACBQYSAz8CGwoMCgUEAAIFARIDPxwnCgwKBQQAAgUDEgM/KisKDAoFBAAC
BQgSA0AGMQoPCggEAAIFCJwIABIDQAcwCksKBAQAAgYSBEMCRDIaPSBPdXRwdXQgb25seS4g
VGhlIHRpbWUgd2hlbiB0aGUgYXR0YWNobWVudCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAAC
BgYSA0MCGwoMCgUEAAIGARIDQxwnCgwKBQQAAgYDEgNDKisKDAoFBAACBggSA0QGMQoPCggE
AAIGCJwIABIDRAcwCtMBCgQEAAIHEgRJAk4EGsQBIFJlcXVpcmVkLiBUaGUgZmlsZXMgdGhh
dCBiZWxvbmcgdG8gdGhpcyBhdHRhY2htZW50LgogSWYgdGhlIGZpbGUgSUQgcGFydCBjb250
YWlucyBzbGFzaGVzLCB0aGV5IGFyZSBlc2NhcGVkLiBFLmcuCiBgcHJvamVjdHMvcDEvbG9j
YXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9maWxlcy9zaGE6PHNoYS1v
Zi1maWxlPmAuCgoMCgUEAAIHBBIDSQIKCgwKBQQAAgcFEgNJCxEKDAoFBAACBwESA0kSFwoM
CgUEAAIHAxIDSRobCg0KBQQAAgcIEgRJHE4DCg8KCAQAAgcInAgAEgNKBCoKDwoHBAACBwif
CBIESwRNBQrUAQoEBAACCBIDUwJKGsYBIE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGUg
T0NJIHZlcnNpb24gdGhhdCB0aGlzIGF0dGFjaG1lbnQgY3JlYXRlZC4gT25seQogcG9wdWxh
dGVkIGZvciBEb2NrZXIgYXR0YWNobWVudHMuIEUuZy4KIGBwcm9qZWN0cy9wMS9sb2NhdGlv
bnMvdXMtY2VudHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xL3BhY2thZ2VzL3AxL3ZlcnNpb25z
L3YxYC4KCgwKBQQAAggFEgNTAggKDAoFBAACCAESA1MJGQoMCgUEAAIIAxIDUxwdCgwKBQQA
AggIEgNTHkkKDwoIBAACCAicCAASA1MfSAouCgIEARIEVwBtARoiIFRoZSByZXF1ZXN0IHRv
IGxpc3QgYXR0YWNobWVudHMuCgoKCgMEAQESA1cIHgpbCgQEAQIAEgRZAl4EGk0gUmVxdWly
ZWQuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hvc2UgYXR0YWNobWVudHMg
d2lsbCBiZSBsaXN0ZWQuCgoMCgUEAQIABRIDWQIICgwKBQQBAgABEgNZCQ8KDAoFBAECAAMS
A1kSEwoNCgUEAQIACBIEWRReAwoPCggEAQIACJwIABIDWgQqCg8KBwQBAgAInwgSBFsEXQUK
0wEKBAQBAgESA2YCPRrFASBPcHRpb25hbC4gQW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVyaW5n
IHRoZSByZXN1bHRzIG9mIHRoZSByZXF1ZXN0LiBGaWx0ZXIKIHJ1bGVzIGFyZSBjYXNlIGlu
c2Vuc2l0aXZlLiBUaGUgZmllbGRzIGVsaWdpYmxlIGZvciBmaWx0ZXJpbmcgYXJlOgoKICAg
KiBgdGFyZ2V0YAogICAqIGB0eXBlYAogICAqIGBhdHRhY2htZW50X25hbWVzcGFjZWAKCgwK
BQQBAgEFEgNmAggKDAoFBAECAQESA2YJDwoMCgUEAQIBAxIDZhITCgwKBQQBAgEIEgNmFDwK
DwoIBAECAQicCAASA2YVOwpXCgQEAQICEgNpAhYaSiBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YXR0YWNobWVudHMgdG8gcmV0dXJuLiBNYXhpbXVtIHBhZ2Ugc2l6ZSBpcyAxLDAwMC4KCgwK
BQQBAgIFEgNpAgcKDAoFBAECAgESA2kIEQoMCgUEAQICAxIDaRQVClcKBAQBAgMSA2wCGBpK
IFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIGxp
c3QgcmVxdWVzdCwgaWYgYW55LgoKDAoFBAECAwUSA2wCCAoMCgUEAQIDARIDbAkTCgwKBQQB
AgMDEgNsFhcKNAoCBAISBHAAdwEaKCBUaGUgcmVzcG9uc2UgZnJvbSBsaXN0aW5nIGF0dGFj
aG1lbnRzLgoKCgoDBAIBEgNwCB8KKAoEBAICABIDcgImGhsgVGhlIGF0dGFjaG1lbnRzIHJl
dHVybmVkLgoKDAoFBAICAAQSA3ICCgoMCgUEAgIABhIDcgsVCgwKBQQCAgABEgNyFiEKDAoF
BAICAAMSA3IkJQp4CgQEAgIBEgN2Ah0aayBUaGUgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5l
eHQgcGFnZSBvZiBhdHRhY2htZW50cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlCiBubyBtb3Jl
IGF0dGFjaG1lbnRzIHRvIHJldHVybi4KCgwKBQQCAgEFEgN2AggKDAoFBAICAQESA3YJGAoM
CgUEAgIBAxIDdhscCjUKAgQDEgV6AIIBARooIFRoZSByZXF1ZXN0IHRvIHJldHJpZXZlIGFu
IGF0dGFjaG1lbnQuCgoKCgMEAwESA3oIHApCCgQEAwIAEgV8AoEBBBozIFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgYXR0YWNobWVudCB0byByZXRyaWV2ZS4KCgwKBQQDAgAFEgN8AggK
DAoFBAMCAAESA3wJDQoMCgUEAwIAAxIDfBARCg4KBQQDAgAIEgV8EoEBAwoPCggEAwIACJwI
ABIDfQQqChAKBwQDAgAInwgSBX4EgAEFCjcKAgQEEgaFAQCUAQEaKSBUaGUgcmVxdWVzdCB0
byBjcmVhdGUgYSBuZXcgYXR0YWNobWVudC4KCgsKAwQEARIEhQEIHwpiCgQEBAIAEgaIAQKN
AQQaUiBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHBhcmVudCByZXNvdXJjZSB3aGVyZSB0
aGUgYXR0YWNobWVudCB3aWxsIGJlCiBjcmVhdGVkLgoKDQoFBAQCAAUSBIgBAggKDQoFBAQC
AAESBIgBCQ8KDQoFBAQCAAMSBIgBEhMKDwoFBAQCAAgSBogBFI0BAwoQCggEBAIACJwIABIE
iQEEKgoRCgcEBAIACJ8IEgaKAQSMAQUKRwoEBAQCARIEkAECRBo5IFJlcXVpcmVkLiBUaGUg
YXR0YWNobWVudCBpZCB0byB1c2UgZm9yIHRoaXMgYXR0YWNobWVudC4KCg0KBQQEAgEFEgSQ
AQIICg0KBQQEAgEBEgSQAQkWCg0KBQQEAgEDEgSQARkaCg0KBQQEAgEIEgSQARtDChAKCAQE
AgEInAgAEgSQARxCCjcKBAQEAgISBJMBAkUaKSBSZXF1aXJlZC4gVGhlIGF0dGFjaG1lbnQg
dG8gYmUgY3JlYXRlZC4KCg0KBQQEAgIGEgSTAQIMCg0KBQQEAgIBEgSTAQ0XCg0KBQQEAgID
EgSTARobCg0KBQQEAgIIEgSTARxEChAKCAQEAgIInAgAEgSTAR1DCjQKAgQFEgaXAQCfAQEa
JiBUaGUgcmVxdWVzdCB0byBkZWxldGUgYW4gYXR0YWNobWVudC4KCgsKAwQFARIElwEIHwpB
CgQEBQIAEgaZAQKeAQQaMSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGF0dGFjaG1lbnQg
dG8gZGVsZXRlLgoKDQoFBAUCAAUSBJkBAggKDQoFBAUCAAESBJkBCQ0KDQoFBAUCAAMSBJkB
EBEKDwoFBAUCAAgSBpkBEp4BAwoQCggEBQIACJwIABIEmgEEKgoRCgcEBQIACJ8IEgabAQSd
AQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::Attachment ===
    # Fields for Attachment
    # Field: name Type: 9 ()
    # Field: target Type: 9 ()
    # Field: type Type: 9 ()
    # Field: attachment_namespace Type: 9 ()
    # Field: annotations Type: 11 (.google.devtools.artifactregistry.v1.Attachment.AnnotationsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: files Type: 9 ()
    # Field: oci_version_name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsRequest ===
    # Fields for ListAttachmentsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsResponse ===
    # Fields for ListAttachmentsResponse
    # Field: attachments Type: 11 (.google.devtools.artifactregistry.v1.Attachment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::GetAttachmentRequest ===
    # Fields for GetAttachmentRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::CreateAttachmentRequest ===
    # Fields for CreateAttachmentRequest
    # Field: parent Type: 9 ()
    # Field: attachment_id Type: 9 ()
    # Field: attachment Type: 11 (.google.devtools.artifactregistry.v1.Attachment)

# === Message: Google::Devtools::Artifactregistry::V1::Attachment::DeleteAttachmentRequest ===
    # Fields for DeleteAttachmentRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1::Attachment - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1/attachment.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1::Attachment;

    my $msg = Google::Devtools::Artifactregistry::V1::Attachment::Attachment->new({
        name => $name,
        target => $target,
        type => $type,
        attachment_namespace => $attachment_namespace,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1::Attachment::Attachment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1/attachment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1::Attachment::Attachment

An Attachment refers to additional metadata that can be attached to
artifacts in Artifact Registry. An attachment consists of one or more files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the attachment. E.g.
`projects/p1/locations/us/repositories/repo/attachments/sbom`.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Required. The target the attachment is for, can be a Version, Package or
Repository. E.g.
`projects/p1/locations/us-central1/repositories/repo1/packages/p1/versions/v1`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Type of attachment.
E.g. `application/vnd.spdx+json`

=item * C<< $msg->attachment_namespace() >> / C<< $msg->attachment_namespace($value) >>

Type: C<String>

The namespace this attachment belongs to.
E.g. If an attachment is created by artifact analysis, namespace is set
to `artifactanalysis.googleapis.com`.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Attachment::Attachment::AnnotationsEntry>)

Optional. User annotations. These attributes can only be set and used by
the user, and not by Artifact Registry. See
https://google.aip.dev/128#annotations for more details such as format and
size limitations.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the attachment was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the attachment was last updated.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<String>

Required. The files that belong to this attachment.
If the file ID part contains slashes, they are escaped. E.g.
`projects/p1/locations/us-central1/repositories/repo1/files/sha:<sha-of-file>`.

=item * C<< $msg->oci_version_name() >> / C<< $msg->oci_version_name($value) >>

Type: C<String>

Output only. The name of the OCI version that this attachment created. Only
populated for Docker attachments. E.g.
`projects/p1/locations/us-central1/repositories/repo1/packages/p1/versions/v1`.

=back

=head2 Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsRequest

The request to list attachments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource whose attachments will be listed.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Filter
rules are case insensitive. The fields eligible for filtering are:

  * `target`
  * `type`
  * `attachment_namespace`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of attachments to return. Maximum page size is 1,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsResponse

The response from listing attachments.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->attachments() >> / C<< $msg->attachments($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Attachment::Attachment>)

The attachments returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of attachments, or empty if there are
no more attachments to return.

=back

=head2 Google::Devtools::Artifactregistry::V1::Attachment::GetAttachmentRequest

The request to retrieve an attachment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the attachment to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1::Attachment::CreateAttachmentRequest

The request to create a new attachment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent resource where the attachment will be
created.

=item * C<< $msg->attachment_id() >> / C<< $msg->attachment_id($value) >>

Type: C<String>

Required. The attachment id to use for this attachment.

=item * C<< $msg->attachment() >> / C<< $msg->attachment($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1::Attachment::Attachment>)

Required. The attachment to be created.

=back

=head2 Google::Devtools::Artifactregistry::V1::Attachment::DeleteAttachmentRequest

The request to delete an attachment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the attachment to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1::Attachment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
