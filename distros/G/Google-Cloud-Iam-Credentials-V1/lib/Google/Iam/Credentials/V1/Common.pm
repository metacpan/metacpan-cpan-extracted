package Google::Iam::Credentials::V1::Common;

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
CiZnb29nbGUvaWFtL2NyZWRlbnRpYWxzL3YxL2NvbW1vbi5wcm90bxIZZ29vZ2xlLmlhbS5j
cmVkZW50aWFscy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIssBChpHZW5lcmF0ZUFjY2Vzc1Rva2Vu
UmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWlhbS5nb29nbGVhcGlzLmNvbS9TZXJ2
aWNlQWNjb3VudFIEbmFtZRIcCglkZWxlZ2F0ZXMYAiADKAlSCWRlbGVnYXRlcxIZCgVzY29w
ZRgEIAMoCUID4EECUgVzY29wZRI1CghsaWZldGltZRgHIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblIIbGlmZXRpbWUifQobR2VuZXJhdGVBY2Nlc3NUb2tlblJlc3BvbnNlEiEK
DGFjY2Vzc190b2tlbhgBIAEoCVILYWNjZXNzVG9rZW4SOwoLZXhwaXJlX3RpbWUYAyABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpleHBpcmVUaW1lIo0BCg9TaWduQmxvYlJl
cXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFpYW0uZ29vZ2xlYXBpcy5jb20vU2Vydmlj
ZUFjY291bnRSBG5hbWUSHAoJZGVsZWdhdGVzGAMgAygJUglkZWxlZ2F0ZXMSHQoHcGF5bG9h
ZBgFIAEoDEID4EECUgdwYXlsb2FkIkoKEFNpZ25CbG9iUmVzcG9uc2USFQoGa2V5X2lkGAEg
ASgJUgVrZXlJZBIfCgtzaWduZWRfYmxvYhgEIAEoDFIKc2lnbmVkQmxvYiKMAQoOU2lnbkp3
dFJlcXVlc3QSPQoEbmFtZRgBIAEoCUIp4EEC+kEjCiFpYW0uZ29vZ2xlYXBpcy5jb20vU2Vy
dmljZUFjY291bnRSBG5hbWUSHAoJZGVsZWdhdGVzGAMgAygJUglkZWxlZ2F0ZXMSHQoHcGF5
bG9hZBgFIAEoCUID4EECUgdwYXlsb2FkIkcKD1NpZ25Kd3RSZXNwb25zZRIVCgZrZXlfaWQY
ASABKAlSBWtleUlkEh0KCnNpZ25lZF9qd3QYAiABKAlSCXNpZ25lZEp3dCK7AQoWR2VuZXJh
dGVJZFRva2VuUmVxdWVzdBI9CgRuYW1lGAEgASgJQingQQL6QSMKIWlhbS5nb29nbGVhcGlz
LmNvbS9TZXJ2aWNlQWNjb3VudFIEbmFtZRIcCglkZWxlZ2F0ZXMYAiADKAlSCWRlbGVnYXRl
cxIfCghhdWRpZW5jZRgDIAEoCUID4EECUghhdWRpZW5jZRIjCg1pbmNsdWRlX2VtYWlsGAQg
ASgIUgxpbmNsdWRlRW1haWwiLwoXR2VuZXJhdGVJZFRva2VuUmVzcG9uc2USFAoFdG9rZW4Y
ASABKAlSBXRva2VuQqwCCiNjb20uZ29vZ2xlLmNsb3VkLmlhbS5jcmVkZW50aWFscy52MUIZ
SUFNQ3JlZGVudGlhbHNDb21tb25Qcm90b1ABWkVjbG91ZC5nb29nbGUuY29tL2dvL2lhbS9j
cmVkZW50aWFscy9hcGl2MS9jcmVkZW50aWFsc3BiO2NyZWRlbnRpYWxzcGL4AQGqAh9Hb29n
bGUuQ2xvdWQuSWFtLkNyZWRlbnRpYWxzLlYxygIfR29vZ2xlXENsb3VkXElhbVxDcmVkZW50
aWFsc1xWMepBWQohaWFtLmdvb2dsZWFwaXMuY29tL1NlcnZpY2VBY2NvdW50EjRwcm9qZWN0
cy97cHJvamVjdH0vc2VydmljZUFjY291bnRzL3tzZXJ2aWNlX2FjY291bnR9SrA2CgcSBQ4A
vQEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMA
EgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAoCgkKAgMDEgMVACkKCAoBCBIDFwAfCgkKAggf
EgMXAB8KCAoBCBIDGAA8CgkKAgglEgMYADwKCAoBCBIDGQBcCgkKAggLEgMZAFwKCAoBCBID
GgAiCgkKAggKEgMaACIKCAoBCBIDGwA6CgkKAggIEgMbADoKCAoBCBIDHAA8CgkKAggBEgMc
ADwKCAoBCBIDHQA9CgkKAggpEgMdAD0KCQoBCBIEHgAhAgoMCgQInQgAEgQeACECCgoKAgQA
EgQjAEYBCgoKAwQAARIDIwgiCpUCCgQEAAIAEgQoAi0EGoYCIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgc2VydmljZSBhY2NvdW50IGZvciB3aGljaCB0aGUgY3JlZGVu
dGlhbHMKIGFyZSByZXF1ZXN0ZWQsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogYHByb2pl
Y3RzLy0vc2VydmljZUFjY291bnRzL3tBQ0NPVU5UX0VNQUlMX09SX1VOSVFVRUlEfWAuIFRo
ZSBgLWAgd2lsZGNhcmQKIGNoYXJhY3RlciBpcyByZXF1aXJlZDsgcmVwbGFjaW5nIGl0IHdp
dGggYSBwcm9qZWN0IElEIGlzIGludmFsaWQuCgoMCgUEAAIABRIDKAIICgwKBQQAAgABEgMo
CQ0KDAoFBAACAAMSAygQEQoNCgUEAAIACBIEKBItAwoPCggEAAIACJwIABIDKQQqCg8KBwQA
AgAInwgSBCoELAUKvQQKBAQAAgESAzkCIBqvBCBUaGUgc2VxdWVuY2Ugb2Ygc2VydmljZSBh
Y2NvdW50cyBpbiBhIGRlbGVnYXRpb24gY2hhaW4uIEVhY2ggc2VydmljZQogYWNjb3VudCBt
dXN0IGJlIGdyYW50ZWQgdGhlIGByb2xlcy9pYW0uc2VydmljZUFjY291bnRUb2tlbkNyZWF0
b3JgIHJvbGUKIG9uIGl0cyBuZXh0IHNlcnZpY2UgYWNjb3VudCBpbiB0aGUgY2hhaW4uIFRo
ZSBsYXN0IHNlcnZpY2UgYWNjb3VudCBpbiB0aGUKIGNoYWluIG11c3QgYmUgZ3JhbnRlZCB0
aGUgYHJvbGVzL2lhbS5zZXJ2aWNlQWNjb3VudFRva2VuQ3JlYXRvcmAgcm9sZQogb24gdGhl
IHNlcnZpY2UgYWNjb3VudCB0aGF0IGlzIHNwZWNpZmllZCBpbiB0aGUgYG5hbWVgIGZpZWxk
IG9mIHRoZQogcmVxdWVzdC4KCiBUaGUgZGVsZWdhdGVzIG11c3QgaGF2ZSB0aGUgZm9sbG93
aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy97QUNDT1VOVF9FTUFJ
TF9PUl9VTklRVUVJRH1gLiBUaGUgYC1gIHdpbGRjYXJkCiBjaGFyYWN0ZXIgaXMgcmVxdWly
ZWQ7IHJlcGxhY2luZyBpdCB3aXRoIGEgcHJvamVjdCBJRCBpcyBpbnZhbGlkLgoKDAoFBAAC
AQQSAzkCCgoMCgUEAAIBBRIDOQsRCgwKBQQAAgEBEgM5EhsKDAoFBAACAQMSAzkeHwrbAQoE
BAACAhIDPwJFGs0BIFJlcXVpcmVkLiBDb2RlIHRvIGlkZW50aWZ5IHRoZSBzY29wZXMgdG8g
YmUgaW5jbHVkZWQgaW4gdGhlIE9BdXRoIDIuMCBhY2Nlc3MgdG9rZW4uCiBTZWUgaHR0cHM6
Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vaWRlbnRpdHkvcHJvdG9jb2xzL2dvb2dsZXNjb3Bl
cyBmb3IgbW9yZQogaW5mb3JtYXRpb24uCiBBdCBsZWFzdCBvbmUgdmFsdWUgcmVxdWlyZWQu
CgoMCgUEAAICBBIDPwIKCgwKBQQAAgIFEgM/CxEKDAoFBAACAgESAz8SFwoMCgUEAAICAxID
PxobCgwKBQQAAgIIEgM/HEQKDwoIBAACAgicCAASAz8dQwrqAQoEBAACAxIDRQIoGtwBIFRo
ZSBkZXNpcmVkIGxpZmV0aW1lIGR1cmF0aW9uIG9mIHRoZSBhY2Nlc3MgdG9rZW4gaW4gc2Vj
b25kcy4KIE11c3QgYmUgc2V0IHRvIGEgdmFsdWUgbGVzcyB0aGFuIG9yIGVxdWFsIHRvIDM2
MDAgKDEgaG91cikuIElmIGEgdmFsdWUgaXMKIG5vdCBzcGVjaWZpZWQsIHRoZSB0b2tlbidz
IGxpZmV0aW1lIHdpbGwgYmUgc2V0IHRvIGEgZGVmYXVsdCB2YWx1ZSBvZiBvbmUKIGhvdXIu
CgoMCgUEAAIDBhIDRQIaCgwKBQQAAgMBEgNFGyMKDAoFBAACAwMSA0UmJwoKCgIEARIESABP
AQoKCgMEAQESA0gIIwoqCgQEAQIAEgNKAhoaHSBUaGUgT0F1dGggMi4wIGFjY2VzcyB0b2tl
bi4KCgwKBQQBAgAFEgNKAggKDAoFBAECAAESA0oJFQoMCgUEAQIAAxIDShgZCkkKBAQBAgES
A04CLBo8IFRva2VuIGV4cGlyYXRpb24gdGltZS4KIFRoZSBleHBpcmF0aW9uIHRpbWUgaXMg
YWx3YXlzIHNldC4KCgwKBQQBAgEGEgNOAhsKDAoFBAECAQESA04cJwoMCgUEAQIBAxIDTior
CgoKAgQCEgRRAGsBCgoKAwQCARIDUQgXCpUCCgQEAgIAEgRWAlsEGoYCIFJlcXVpcmVkLiBU
aGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc2VydmljZSBhY2NvdW50IGZvciB3aGljaCB0aGUg
Y3JlZGVudGlhbHMKIGFyZSByZXF1ZXN0ZWQsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0Ogog
YHByb2plY3RzLy0vc2VydmljZUFjY291bnRzL3tBQ0NPVU5UX0VNQUlMX09SX1VOSVFVRUlE
fWAuIFRoZSBgLWAgd2lsZGNhcmQKIGNoYXJhY3RlciBpcyByZXF1aXJlZDsgcmVwbGFjaW5n
IGl0IHdpdGggYSBwcm9qZWN0IElEIGlzIGludmFsaWQuCgoMCgUEAgIABRIDVgIICgwKBQQC
AgABEgNWCQ0KDAoFBAICAAMSA1YQEQoNCgUEAgIACBIEVhJbAwoPCggEAgIACJwIABIDVwQq
Cg8KBwQCAgAInwgSBFgEWgUKvQQKBAQCAgESA2cCIBqvBCBUaGUgc2VxdWVuY2Ugb2Ygc2Vy
dmljZSBhY2NvdW50cyBpbiBhIGRlbGVnYXRpb24gY2hhaW4uIEVhY2ggc2VydmljZQogYWNj
b3VudCBtdXN0IGJlIGdyYW50ZWQgdGhlIGByb2xlcy9pYW0uc2VydmljZUFjY291bnRUb2tl
bkNyZWF0b3JgIHJvbGUKIG9uIGl0cyBuZXh0IHNlcnZpY2UgYWNjb3VudCBpbiB0aGUgY2hh
aW4uIFRoZSBsYXN0IHNlcnZpY2UgYWNjb3VudCBpbiB0aGUKIGNoYWluIG11c3QgYmUgZ3Jh
bnRlZCB0aGUgYHJvbGVzL2lhbS5zZXJ2aWNlQWNjb3VudFRva2VuQ3JlYXRvcmAgcm9sZQog
b24gdGhlIHNlcnZpY2UgYWNjb3VudCB0aGF0IGlzIHNwZWNpZmllZCBpbiB0aGUgYG5hbWVg
IGZpZWxkIG9mIHRoZQogcmVxdWVzdC4KCiBUaGUgZGVsZWdhdGVzIG11c3QgaGF2ZSB0aGUg
Zm9sbG93aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy97QUNDT1VO
VF9FTUFJTF9PUl9VTklRVUVJRH1gLiBUaGUgYC1gIHdpbGRjYXJkCiBjaGFyYWN0ZXIgaXMg
cmVxdWlyZWQ7IHJlcGxhY2luZyBpdCB3aXRoIGEgcHJvamVjdCBJRCBpcyBpbnZhbGlkLgoK
DAoFBAICAQQSA2cCCgoMCgUEAgIBBRIDZwsRCgwKBQQCAgEBEgNnEhsKDAoFBAICAQMSA2ce
HworCgQEAgICEgNqAj0aHiBSZXF1aXJlZC4gVGhlIGJ5dGVzIHRvIHNpZ24uCgoMCgUEAgIC
BRIDagIHCgwKBQQCAgIBEgNqCA8KDAoFBAICAgMSA2oSEwoMCgUEAgICCBIDahQ8Cg8KCAQC
AgIInAgAEgNqFTsKCgoCBAMSBG0AcwEKCgoDBAMBEgNtCBgKNwoEBAMCABIDbwIUGiogVGhl
IElEIG9mIHRoZSBrZXkgdXNlZCB0byBzaWduIHRoZSBibG9iLgoKDAoFBAMCAAUSA28CCAoM
CgUEAwIAARIDbwkPCgwKBQQDAgADEgNvEhMKHwoEBAMCARIDcgIYGhIgVGhlIHNpZ25lZCBi
bG9iLgoKDAoFBAMCAQUSA3ICBwoMCgUEAwIBARIDcggTCgwKBQQDAgEDEgNyFhcKCwoCBAQS
BXUAjwEBCgoKAwQEARIDdQgWCpUCCgQEBAIAEgR6An8EGoYCIFJlcXVpcmVkLiBUaGUgcmVz
b3VyY2UgbmFtZSBvZiB0aGUgc2VydmljZSBhY2NvdW50IGZvciB3aGljaCB0aGUgY3JlZGVu
dGlhbHMKIGFyZSByZXF1ZXN0ZWQsIGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogYHByb2pl
Y3RzLy0vc2VydmljZUFjY291bnRzL3tBQ0NPVU5UX0VNQUlMX09SX1VOSVFVRUlEfWAuIFRo
ZSBgLWAgd2lsZGNhcmQKIGNoYXJhY3RlciBpcyByZXF1aXJlZDsgcmVwbGFjaW5nIGl0IHdp
dGggYSBwcm9qZWN0IElEIGlzIGludmFsaWQuCgoMCgUEBAIABRIDegIICgwKBQQEAgABEgN6
CQ0KDAoFBAQCAAMSA3oQEQoNCgUEBAIACBIEehJ/AwoPCggEBAIACJwIABIDewQqCg8KBwQE
AgAInwgSBHwEfgUKvgQKBAQEAgESBIsBAiAarwQgVGhlIHNlcXVlbmNlIG9mIHNlcnZpY2Ug
YWNjb3VudHMgaW4gYSBkZWxlZ2F0aW9uIGNoYWluLiBFYWNoIHNlcnZpY2UKIGFjY291bnQg
bXVzdCBiZSBncmFudGVkIHRoZSBgcm9sZXMvaWFtLnNlcnZpY2VBY2NvdW50VG9rZW5DcmVh
dG9yYCByb2xlCiBvbiBpdHMgbmV4dCBzZXJ2aWNlIGFjY291bnQgaW4gdGhlIGNoYWluLiBU
aGUgbGFzdCBzZXJ2aWNlIGFjY291bnQgaW4gdGhlCiBjaGFpbiBtdXN0IGJlIGdyYW50ZWQg
dGhlIGByb2xlcy9pYW0uc2VydmljZUFjY291bnRUb2tlbkNyZWF0b3JgIHJvbGUKIG9uIHRo
ZSBzZXJ2aWNlIGFjY291bnQgdGhhdCBpcyBzcGVjaWZpZWQgaW4gdGhlIGBuYW1lYCBmaWVs
ZCBvZiB0aGUKIHJlcXVlc3QuCgogVGhlIGRlbGVnYXRlcyBtdXN0IGhhdmUgdGhlIGZvbGxv
d2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvLS9zZXJ2aWNlQWNjb3VudHMve0FDQ09VTlRfRU1B
SUxfT1JfVU5JUVVFSUR9YC4gVGhlIGAtYCB3aWxkY2FyZAogY2hhcmFjdGVyIGlzIHJlcXVp
cmVkOyByZXBsYWNpbmcgaXQgd2l0aCBhIHByb2plY3QgSUQgaXMgaW52YWxpZC4KCg0KBQQE
AgEEEgSLAQIKCg0KBQQEAgEFEgSLAQsRCg0KBQQEAgEBEgSLARIbCg0KBQQEAgEDEgSLAR4f
CmAKBAQEAgISBI4BAj4aUiBSZXF1aXJlZC4gVGhlIEpXVCBwYXlsb2FkIHRvIHNpZ246IGEg
SlNPTiBvYmplY3QgdGhhdCBjb250YWlucyBhIEpXVCBDbGFpbXMgU2V0LgoKDQoFBAQCAgUS
BI4BAggKDQoFBAQCAgESBI4BCRAKDQoFBAQCAgMSBI4BExQKDQoFBAQCAggSBI4BFT0KEAoI
BAQCAgicCAASBI4BFjwKDAoCBAUSBpEBAJcBAQoLCgMEBQESBJEBCBcKNwoEBAUCABIEkwEC
FBopIFRoZSBJRCBvZiB0aGUga2V5IHVzZWQgdG8gc2lnbiB0aGUgSldULgoKDQoFBAUCAAUS
BJMBAggKDQoFBAUCAAESBJMBCQ8KDQoFBAUCAAMSBJMBEhMKHwoEBAUCARIElgECGBoRIFRo
ZSBzaWduZWQgSldULgoKDQoFBAUCAQUSBJYBAggKDQoFBAUCAQESBJYBCRMKDQoFBAUCAQMS
BJYBFhcKDAoCBAYSBpkBALgBAQoLCgMEBgESBJkBCB4KlwIKBAQGAgASBp4BAqMBBBqGAiBS
ZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIHNlcnZpY2UgYWNjb3VudCBmb3Ig
d2hpY2ggdGhlIGNyZWRlbnRpYWxzCiBhcmUgcmVxdWVzdGVkLCBpbiB0aGUgZm9sbG93aW5n
IGZvcm1hdDoKIGBwcm9qZWN0cy8tL3NlcnZpY2VBY2NvdW50cy97QUNDT1VOVF9FTUFJTF9P
Ul9VTklRVUVJRH1gLiBUaGUgYC1gIHdpbGRjYXJkCiBjaGFyYWN0ZXIgaXMgcmVxdWlyZWQ7
IHJlcGxhY2luZyBpdCB3aXRoIGEgcHJvamVjdCBJRCBpcyBpbnZhbGlkLgoKDQoFBAYCAAUS
BJ4BAggKDQoFBAYCAAESBJ4BCQ0KDQoFBAYCAAMSBJ4BEBEKDwoFBAYCAAgSBp4BEqMBAwoQ
CggEBgIACJwIABIEnwEEKgoRCgcEBgIACJ8IEgagAQSiAQUKvgQKBAQGAgESBK8BAiAarwQg
VGhlIHNlcXVlbmNlIG9mIHNlcnZpY2UgYWNjb3VudHMgaW4gYSBkZWxlZ2F0aW9uIGNoYWlu
LiBFYWNoIHNlcnZpY2UKIGFjY291bnQgbXVzdCBiZSBncmFudGVkIHRoZSBgcm9sZXMvaWFt
LnNlcnZpY2VBY2NvdW50VG9rZW5DcmVhdG9yYCByb2xlCiBvbiBpdHMgbmV4dCBzZXJ2aWNl
IGFjY291bnQgaW4gdGhlIGNoYWluLiBUaGUgbGFzdCBzZXJ2aWNlIGFjY291bnQgaW4gdGhl
CiBjaGFpbiBtdXN0IGJlIGdyYW50ZWQgdGhlIGByb2xlcy9pYW0uc2VydmljZUFjY291bnRU
b2tlbkNyZWF0b3JgIHJvbGUKIG9uIHRoZSBzZXJ2aWNlIGFjY291bnQgdGhhdCBpcyBzcGVj
aWZpZWQgaW4gdGhlIGBuYW1lYCBmaWVsZCBvZiB0aGUKIHJlcXVlc3QuCgogVGhlIGRlbGVn
YXRlcyBtdXN0IGhhdmUgdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMvLS9zZXJ2
aWNlQWNjb3VudHMve0FDQ09VTlRfRU1BSUxfT1JfVU5JUVVFSUR9YC4gVGhlIGAtYCB3aWxk
Y2FyZAogY2hhcmFjdGVyIGlzIHJlcXVpcmVkOyByZXBsYWNpbmcgaXQgd2l0aCBhIHByb2pl
Y3QgSUQgaXMgaW52YWxpZC4KCg0KBQQGAgEEEgSvAQIKCg0KBQQGAgEFEgSvAQsRCg0KBQQG
AgEBEgSvARIbCg0KBQQGAgEDEgSvAR4fCnMKBAQGAgISBLMBAj8aZSBSZXF1aXJlZC4gVGhl
IGF1ZGllbmNlIGZvciB0aGUgdG9rZW4sIHN1Y2ggYXMgdGhlIEFQSSBvciBhY2NvdW50IHRo
YXQgdGhpcyB0b2tlbgogZ3JhbnRzIGFjY2VzcyB0by4KCg0KBQQGAgIFEgSzAQIICg0KBQQG
AgIBEgSzAQkRCg0KBQQGAgIDEgSzARQVCg0KBQQGAgIIEgSzARY+ChAKCAQGAgIInAgAEgSz
ARc9Co8BCgQEBgIDEgS3AQIZGoABIEluY2x1ZGUgdGhlIHNlcnZpY2UgYWNjb3VudCBlbWFp
bCBpbiB0aGUgdG9rZW4uIElmIHNldCB0byBgdHJ1ZWAsIHRoZQogdG9rZW4gd2lsbCBjb250
YWluIGBlbWFpbGAgYW5kIGBlbWFpbF92ZXJpZmllZGAgY2xhaW1zLgoKDQoFBAYCAwUSBLcB
AgYKDQoFBAYCAwESBLcBBxQKDQoFBAYCAwMSBLcBFxgKDAoCBAcSBroBAL0BAQoLCgMEBwES
BLoBCB8KLAoEBAcCABIEvAECExoeIFRoZSBPcGVuSWQgQ29ubmVjdCBJRCB0b2tlbi4KCg0K
BQQHAgAFEgS8AQIICg0KBQQHAgABEgS8AQkOCg0KBQQHAgADEgS8ARESYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest ===
    # Fields for GenerateAccessTokenRequest
    # Field: name Type: 9 ()
    # Field: delegates Type: 9 ()
    # Field: scope Type: 9 ()
    # Field: lifetime Type: 11 (.google.protobuf.Duration)

# === Message: Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse ===
    # Fields for GenerateAccessTokenResponse
    # Field: access_token Type: 9 ()
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Iam::Credentials::V1::Common::SignBlobRequest ===
    # Fields for SignBlobRequest
    # Field: name Type: 9 ()
    # Field: delegates Type: 9 ()
    # Field: payload Type: 12 ()

# === Message: Google::Iam::Credentials::V1::Common::SignBlobResponse ===
    # Fields for SignBlobResponse
    # Field: key_id Type: 9 ()
    # Field: signed_blob Type: 12 ()

# === Message: Google::Iam::Credentials::V1::Common::SignJwtRequest ===
    # Fields for SignJwtRequest
    # Field: name Type: 9 ()
    # Field: delegates Type: 9 ()
    # Field: payload Type: 9 ()

# === Message: Google::Iam::Credentials::V1::Common::SignJwtResponse ===
    # Fields for SignJwtResponse
    # Field: key_id Type: 9 ()
    # Field: signed_jwt Type: 9 ()

# === Message: Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest ===
    # Fields for GenerateIdTokenRequest
    # Field: name Type: 9 ()
    # Field: delegates Type: 9 ()
    # Field: audience Type: 9 ()
    # Field: include_email Type: 8 ()

# === Message: Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse ===
    # Fields for GenerateIdTokenResponse
    # Field: token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::Credentials::V1::Common - Compiled Protocol Buffers messages for google/iam/credentials/v1/common.proto

=head1 SYNOPSIS

    use Google::Iam::Credentials::V1::Common;

    my $msg = Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest->new({
        name => $name,
        delegates => $delegates,
        scope => $scope,
        lifetime => $lifetime,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/credentials/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the service account for which the credentials
are requested, in the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->delegates() >> / C<< $msg->delegates($value) >>

Type: C<String>

The sequence of service accounts in a delegation chain. Each service
account must be granted the `roles/iam.serviceAccountTokenCreator` role
on its next service account in the chain. The last service account in the
chain must be granted the `roles/iam.serviceAccountTokenCreator` role
on the service account that is specified in the `name` field of the
request.

The delegates must have the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<String>

Required. Code to identify the scopes to be included in the OAuth 2.0 access token.
See https://developers.google.com/identity/protocols/googlescopes for more
information.
At least one value required.

=item * C<< $msg->lifetime() >> / C<< $msg->lifetime($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The desired lifetime duration of the access token in seconds.
Must be set to a value less than or equal to 3600 (1 hour). If a value is
not specified, the token's lifetime will be set to a default value of one
hour.

=back

=head2 Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->access_token() >> / C<< $msg->access_token($value) >>

Type: C<String>

The OAuth 2.0 access token.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Token expiration time.
The expiration time is always set.

=back

=head2 Google::Iam::Credentials::V1::Common::SignBlobRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the service account for which the credentials
are requested, in the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->delegates() >> / C<< $msg->delegates($value) >>

Type: C<String>

The sequence of service accounts in a delegation chain. Each service
account must be granted the `roles/iam.serviceAccountTokenCreator` role
on its next service account in the chain. The last service account in the
chain must be granted the `roles/iam.serviceAccountTokenCreator` role
on the service account that is specified in the `name` field of the
request.

The delegates must have the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

Required. The bytes to sign.

=back

=head2 Google::Iam::Credentials::V1::Common::SignBlobResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key_id() >> / C<< $msg->key_id($value) >>

Type: C<String>

The ID of the key used to sign the blob.

=item * C<< $msg->signed_blob() >> / C<< $msg->signed_blob($value) >>

Type: C<Bytes>

The signed blob.

=back

=head2 Google::Iam::Credentials::V1::Common::SignJwtRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the service account for which the credentials
are requested, in the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->delegates() >> / C<< $msg->delegates($value) >>

Type: C<String>

The sequence of service accounts in a delegation chain. Each service
account must be granted the `roles/iam.serviceAccountTokenCreator` role
on its next service account in the chain. The last service account in the
chain must be granted the `roles/iam.serviceAccountTokenCreator` role
on the service account that is specified in the `name` field of the
request.

The delegates must have the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<String>

Required. The JWT payload to sign: a JSON object that contains a JWT Claims Set.

=back

=head2 Google::Iam::Credentials::V1::Common::SignJwtResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key_id() >> / C<< $msg->key_id($value) >>

Type: C<String>

The ID of the key used to sign the JWT.

=item * C<< $msg->signed_jwt() >> / C<< $msg->signed_jwt($value) >>

Type: C<String>

The signed JWT.

=back

=head2 Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the service account for which the credentials
are requested, in the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->delegates() >> / C<< $msg->delegates($value) >>

Type: C<String>

The sequence of service accounts in a delegation chain. Each service
account must be granted the `roles/iam.serviceAccountTokenCreator` role
on its next service account in the chain. The last service account in the
chain must be granted the `roles/iam.serviceAccountTokenCreator` role
on the service account that is specified in the `name` field of the
request.

The delegates must have the following format:
`projects/-/serviceAccounts/{ACCOUNT_EMAIL_OR_UNIQUEID}`. The `-` wildcard
character is required; replacing it with a project ID is invalid.

=item * C<< $msg->audience() >> / C<< $msg->audience($value) >>

Type: C<String>

Required. The audience for the token, such as the API or account that this token
grants access to.

=item * C<< $msg->include_email() >> / C<< $msg->include_email($value) >>

Type: C<Bool>

Include the service account email in the token. If set to `true`, the
token will contain `email` and `email_verified` claims.

=back

=head2 Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<String>

The OpenId Connect ID token.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::Credentials::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
