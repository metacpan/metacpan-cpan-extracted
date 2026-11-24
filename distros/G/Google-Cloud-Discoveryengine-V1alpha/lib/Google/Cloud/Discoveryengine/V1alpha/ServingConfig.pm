package Google::Cloud::Discoveryengine::V1alpha::ServingConfig;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Common };
    eval { require Google::Cloud::Discoveryengine::V1alpha::SearchService };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvc2VydmluZ19jb25maWcu
cHJvdG8SJGdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29v
Z2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL2NvbW1vbi5wcm90bxo5Z29vZ2xl
L2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWFscGhhL3NlYXJjaF9zZXJ2aWNlLnByb3RvGh9n
b29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqoRCg1TZXJ2aW5nQ29uZmlnEmQKDG1l
ZGlhX2NvbmZpZxgHIAEoCzI/Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5TZXJ2aW5nQ29uZmlnLk1lZGlhQ29uZmlnSABSC21lZGlhQ29uZmlnEmoKDmdlbmVyaWNf
Y29uZmlnGAogASgLMkEuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNl
cnZpbmdDb25maWcuR2VuZXJpY0NvbmZpZ0gAUg1nZW5lcmljQ29uZmlnEhcKBG5hbWUYASAB
KAlCA+BBBVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUS
XwoNc29sdXRpb25fdHlwZRgDIAEoDjIyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5Tb2x1dGlvblR5cGVCBuBBAuBBBVIMc29sdXRpb25UeXBlEhkKCG1vZGVsX2lk
GAQgASgJUgdtb2RlbElkEicKD2RpdmVyc2l0eV9sZXZlbBgFIAEoCVIOZGl2ZXJzaXR5TGV2
ZWwSYAoQZW1iZWRkaW5nX2NvbmZpZxgUIAEoCzI1Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5FbWJlZGRpbmdDb25maWdSD2VtYmVkZGluZ0NvbmZpZxItChJyYW5r
aW5nX2V4cHJlc3Npb24YFSABKAlSEXJhbmtpbmdFeHByZXNzaW9uEmQKEmd1aWRlZF9zZWFy
Y2hfc3BlYxgWIAEoCzI2Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5H
dWlkZWRTZWFyY2hTcGVjUhBndWlkZWRTZWFyY2hTcGVjEnEKF2N1c3RvbV9maW5lX3R1bmlu
Z19zcGVjGBggASgLMjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkN1
c3RvbUZpbmVUdW5pbmdTcGVjUhRjdXN0b21GaW5lVHVuaW5nU3BlYxJACgtjcmVhdGVfdGlt
ZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJA
Cgt1cGRhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IK
dXBkYXRlVGltZRIsChJmaWx0ZXJfY29udHJvbF9pZHMYCyADKAlSEGZpbHRlckNvbnRyb2xJ
ZHMSKgoRYm9vc3RfY29udHJvbF9pZHMYDCADKAlSD2Jvb3N0Q29udHJvbElkcxIwChRyZWRp
cmVjdF9jb250cm9sX2lkcxgOIAMoCVIScmVkaXJlY3RDb250cm9sSWRzEjAKFHN5bm9ueW1z
X2NvbnRyb2xfaWRzGA8gAygJUhJzeW5vbnltc0NvbnRyb2xJZHMSPQobb25ld2F5X3N5bm9u
eW1zX2NvbnRyb2xfaWRzGBAgAygJUhhvbmV3YXlTeW5vbnltc0NvbnRyb2xJZHMSNAoWZGlz
c29jaWF0ZV9jb250cm9sX2lkcxgRIAMoCVIUZGlzc29jaWF0ZUNvbnRyb2xJZHMSNgoXcmVw
bGFjZW1lbnRfY29udHJvbF9pZHMYEiADKAlSFXJlcGxhY2VtZW50Q29udHJvbElkcxIsChJp
Z25vcmVfY29udHJvbF9pZHMYEyADKAlSEGlnbm9yZUNvbnRyb2xJZHMaugIKC01lZGlhQ29u
ZmlnElEKJGNvbnRlbnRfd2F0Y2hlZF9wZXJjZW50YWdlX3RocmVzaG9sZBgCIAEoAkgAUiFj
b250ZW50V2F0Y2hlZFBlcmNlbnRhZ2VUaHJlc2hvbGQSSwohY29udGVudF93YXRjaGVkX3Nl
Y29uZHNfdGhyZXNob2xkGAUgASgCSABSHmNvbnRlbnRXYXRjaGVkU2Vjb25kc1RocmVzaG9s
ZBIuChNkZW1vdGlvbl9ldmVudF90eXBlGAEgASgJUhFkZW1vdGlvbkV2ZW50VHlwZRJBCh1j
b250ZW50X2ZyZXNobmVzc19jdXRvZmZfZGF5cxgEIAEoBVIaY29udGVudEZyZXNobmVzc0N1
dG9mZkRheXNCGAoWZGVtb3RlX2NvbnRlbnRfd2F0Y2hlZBqGAQoNR2VuZXJpY0NvbmZpZxJ1
ChNjb250ZW50X3NlYXJjaF9zcGVjGAEgASgLMkUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3QuQ29udGVudFNlYXJjaFNwZWNSEWNvbnRlbnRT
ZWFyY2hTcGVjOoAD6kH8AgosZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL1NlcnZp
bmdDb25maWcSX3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRh
U3RvcmVzL3tkYXRhX3N0b3JlfS9zZXJ2aW5nQ29uZmlncy97c2VydmluZ19jb25maWd9Enhw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2Nv
bGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L3NlcnZpbmdDb25maWdzL3tzZXJ2
aW5nX2NvbmZpZ30ScXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZW5naW5lcy97ZW5naW5lfS9zZXJ2aW5nQ29uZmln
cy97c2VydmluZ19jb25maWd9QhEKD3ZlcnRpY2FsX2NvbmZpZ0KeAgooY29tLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUISU2VydmluZ0NvbmZpZ1Byb3RvUAFaUmNs
b3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5
ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUu
Q2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5
RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxw
aGFK/FcKBxIFDgCXAgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
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
EgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADsKCQoCAwMSAxUAQwoJCgID
BBIDFgApCggKAQgSAxgAQQoJCgIIJRIDGABBCggKAQgSAxkAaQoJCgIICxIDGQBpCggKAQgS
AxoAIgoJCgIIChIDGgAiCggKAQgSAxsAMwoJCgIICBIDGwAzCggKAQgSAxwAQQoJCgIIARID
HABBCggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4AQQoJCgIIKRIDHgBBCggKAQgSAx8A
QAoJCgIILRIDHwBACt4BCgIEABIFJQCXAgEa0AEgQ29uZmlndXJlcyBtZXRhZGF0YSB0aGF0
IGlzIHVzZWQgdG8gZ2VuZXJhdGUgc2VydmluZyB0aW1lIHJlc3VsdHMgKGUuZy4KIHNlYXJj
aCByZXN1bHRzIG9yIHJlY29tbWVuZGF0aW9uIHByZWRpY3Rpb25zKS4KIFRoZSBTZXJ2aW5n
Q29uZmlnIGlzIHBhc3NlZCBpbiB0aGUgc2VhcmNoIGFuZCBwcmVkaWN0IHJlcXVlc3QgYW5k
IGdlbmVyYXRlcwogcmVzdWx0cy4KCgoKAwQAARIDJQgVCgsKAwQABxIEJgIrBAoNCgUEAAed
CBIEJgIrBArtBgoEBAADABIEPAJZAxreBiBTcGVjaWZpZXMgdGhlIGNvbmZpZ3VyYXRpb25z
IG5lZWRlZCBmb3IgTWVkaWEgRGlzY292ZXJ5LiBDdXJyZW50bHkgd2UKIHN1cHBvcnQ6Cgog
KiBgZGVtb3RlX2NvbnRlbnRfd2F0Y2hlZGA6IFRocmVzaG9sZCBmb3Igd2F0Y2hlZCBjb250
ZW50IGRlbW90aW9uLgogQ3VzdG9tZXJzIGNhbiBzcGVjaWZ5IGlmIHVzaW5nIHdhdGNoZWQg
Y29udGVudCBkZW1vdGlvbiBvciB1c2Ugdmlld2VkCiBkZXRhaWwgcGFnZS4gVXNpbmcgdGhl
IGNvbnRlbnQgd2F0Y2hlZCBkZW1vdGlvbiwgY3VzdG9tZXJzIG5lZWQgdG8gc3BlY2lmeQog
dGhlIHdhdGNoZWQgbWludXRlcyBvciBwZXJjZW50YWdlIGV4Y2VlZHMgdGhlIHRocmVzaG9s
ZCwgdGhlIGNvbnRlbnQgd2lsbAogYmUgZGVtb3RlZCBpbiB0aGUgcmVjb21tZW5kYXRpb24g
cmVzdWx0LgogKiBgcHJvbW90ZV9mcmVzaF9jb250ZW50YDogY3V0b2ZmIGRheXMgZm9yIGZy
ZXNoIGNvbnRlbnQgcHJvbW90aW9uLgogQ3VzdG9tZXJzIGNhbiBzcGVjaWZ5IGlmIHVzaW5n
IGNvbnRlbnQgZnJlc2huZXNzIHByb21vdGlvbi4gSWYgdGhlIGNvbnRlbnQKIHdhcyBwdWJs
aXNoZWQgd2l0aGluIHRoZSBjdXRvZmYgZGF5cywgdGhlIGNvbnRlbnQgd2lsbCBiZSBwcm9t
b3RlZCBpbiB0aGUKIHJlY29tbWVuZGF0aW9uIHJlc3VsdC4KIENhbiBvbmx5IGJlIHNldCBp
ZgogW1NvbHV0aW9uVHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LlNvbHV0aW9uVHlwZV0gaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9O
X1RZUEVfUkVDT01NRU5EQVRJT05dLgoKDAoFBAADAAESAzwKFQqzAQoGBAADAAgAEgRABEcF
GqIBIFNwZWNpZnkgdGhlIHRocmVzaG9sZCBmb3IgZGVtb3Rpbmcgd2F0Y2hlZCBjb250ZW50
LCB0aGUgdGhyZXNob2xkIGNhbiBiZQogZWl0aGVyIHBlcmNlbnRhZ2Ugb3IgbWludXRlcyB2
YWx1ZS4KIFRoaXMgbXVzdCBiZSBzZXQgZm9yIGBtZWRpYS1jb21wbGV0ZWAgZXZlbnQgdHlw
ZS4KCg4KBwQAAwAIAAESA0AKIAqGAQoGBAADAAIAEgNDBjUadyBTcGVjaWZpZXMgdGhlIGNv
bnRlbnQgd2F0Y2hlZCBwZXJjZW50YWdlIHRocmVzaG9sZCBmb3IgZGVtb3Rpb24uCiBUaHJl
c2hvbGQgdmFsdWUgbXVzdCBiZSBiZXR3ZWVuIFswLCAxLjBdIGluY2x1c2l2ZS4KCg4KBwQA
AwACAAUSA0MGCwoOCgcEAAMAAgABEgNDDDAKDgoHBAADAAIAAxIDQzM0Ck4KBgQAAwACARID
RgYyGj8gU3BlY2lmaWVzIHRoZSBjb250ZW50IHdhdGNoZWQgbWludXRlcyB0aHJlc2hvbGQg
Zm9yIGRlbW90aW9uLgoKDgoHBAADAAIBBRIDRgYLCg4KBwQAAwACAQESA0YMLQoOCgcEAAMA
AgEDEgNGMDEKiwMKBgQAAwACAhIDUwQjGvsCIFNwZWNpZmllcyB0aGUgZXZlbnQgdHlwZSB1
c2VkIGZvciBkZW1vdGluZyByZWNvbW1lbmRhdGlvbiByZXN1bHQuCiBDdXJyZW50bHkgc3Vw
cG9ydGVkIHZhbHVlczoKCiAqIGB2aWV3LWl0ZW1gOiBJdGVtIHZpZXdlZC4KICogYG1lZGlh
LXBsYXlgOiBTdGFydC9yZXN1bWUgd2F0Y2hpbmcgYSB2aWRlbywgcGxheWluZyBhIHNvbmcs
IGV0Yy4KICogYG1lZGlhLWNvbXBsZXRlYDogRmluaXNoZWQgb3Igc3RvcHBlZCBtaWR3YXkg
dGhyb3VnaCBhIHZpZGVvLCBzb25nLAogZXRjLgoKIElmIHVuc2V0LCB3YXRjaCBoaXN0b3J5
IGRlbW90aW9uIHdpbGwgbm90IGJlIGFwcGxpZWQuIENvbnRlbnQgZnJlc2huZXNzCiBkZW1v
dGlvbiB3aWxsIHN0aWxsIGJlIGFwcGxpZWQuCgoOCgcEAAMAAgIFEgNTBAoKDgoHBAADAAIC
ARIDUwseCg4KBwQAAwACAgMSA1MhIgq0AQoGBAADAAIDEgNYBCwapAEgU3BlY2lmaWVzIHRo
ZSBjb250ZW50IGZyZXNobmVzcyB1c2VkIGZvciByZWNvbW1lbmRhdGlvbiByZXN1bHQuCiBD
b250ZW50cyB3aWxsIGJlIGRlbW90ZWQgaWYgY29udGVudHMgd2VyZSBwdWJsaXNoZWQgZm9y
IG1vcmUgdGhhbiBjb250ZW50CiBmcmVzaG5lc3MgY3V0b2ZmIGRheXMuCgoOCgcEAAMAAgMF
EgNYBAkKDgoHBAADAAIDARIDWAonCg4KBwQAAwACAwMSA1gqKwqmAQoEBAADARIEXwJjAxqX
ASBTcGVjaWZpZXMgdGhlIGNvbmZpZ3VyYXRpb25zIG5lZWRlZCBmb3IgR2VuZXJpYyBEaXNj
b3ZlcnkuQ3VycmVudGx5IHdlCiBzdXBwb3J0OgoKICogYGNvbnRlbnRfc2VhcmNoX3NwZWNg
OiBjb25maWd1cmF0aW9uIGZvciBnZW5lcmljIGNvbnRlbnQgc2VhcmNoLgoKDAoFBAADAQES
A18KFwp2CgYEAAMBAgASA2IEPBpnIFNwZWNpZmllcyB0aGUgZXhwZWN0ZWQgYmVoYXZpb3Ig
b2YgY29udGVudCBzZWFyY2guCiBPbmx5IHZhbGlkIGZvciBjb250ZW50LXNlYXJjaCBlbmFi
bGVkIGRhdGEgc3RvcmUuCgoOCgcEAAMBAgAGEgNiBCMKDgoHBAADAQIAARIDYiQ3Cg4KBwQA
AwECAAMSA2I6OwoyCgQEAAgAEgRmAmwDGiQgSW5kdXN0cnkgdmVydGljYWwgc3BlY2lmaWMg
Y29uZmlnLgoKDAoFBAAIAAESA2YIFwo8CgQEAAIAEgNoBCEaLyBUaGUgTWVkaWFDb25maWcg
b2YgdGhlIHNlcnZpbmcgY29uZmlndXJhdGlvbi4KCgwKBQQAAgAGEgNoBA8KDAoFBAACAAES
A2gQHAoMCgUEAAIAAxIDaB8gCj4KBAQAAgESA2sEJhoxIFRoZSBHZW5lcmljQ29uZmlnIG9m
IHRoZSBzZXJ2aW5nIGNvbmZpZ3VyYXRpb24uCgoMCgUEAAIBBhIDawQRCgwKBQQAAgEBEgNr
EiAKDAoFBAACAQMSA2sjJQqtAQoEBAACAhIDcAI8Gp8BIEltbXV0YWJsZS4gRnVsbHkgcXVh
bGlmaWVkIG5hbWUKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9L2VuZ2luZXMve2VuZ2luZV9pZH0vc2Vydmlu
Z0NvbmZpZ3Mve3NlcnZpbmdfY29uZmlnX2lkfWAKCgwKBQQAAgIFEgNwAggKDAoFBAACAgES
A3AJDQoMCgUEAAICAxIDcBARCgwKBQQAAgIIEgNwEjsKDwoIBAACAgicCAASA3ATOgrmAQoE
BAACAxIDdwJDGtgBIFJlcXVpcmVkLiBUaGUgaHVtYW4gcmVhZGFibGUgc2VydmluZyBjb25m
aWcgZGlzcGxheSBuYW1lLiBVc2VkIGluIERpc2NvdmVyeQogVUkuCgogVGhpcyBmaWVsZCBt
dXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAx
MjgKIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBp
cyByZXR1cm5lZC4KCgwKBQQAAgMFEgN3AggKDAoFBAACAwESA3cJFQoMCgUEAAIDAxIDdxgZ
CgwKBQQAAgMIEgN3GkIKDwoIBAACAwicCAASA3cbQQpvCgQEAAIEEgR7An4EGmEgUmVxdWly
ZWQuIEltbXV0YWJsZS4gU3BlY2lmaWVzIHRoZSBzb2x1dGlvbiB0eXBlIHRoYXQgYSBzZXJ2
aW5nIGNvbmZpZyBjYW4KIGJlIGFzc29jaWF0ZWQgd2l0aC4KCgwKBQQAAgQGEgN7Ag4KDAoF
BAACBAESA3sPHAoMCgUEAAIEAxIDex8gCg0KBQQAAgQIEgR7IX4DCg8KCAQAAgQInAgAEgN8
BCoKDwoIBAACBAicCAESA30EKwqiAwoEBAACBRIEiAECFhqTAyBUaGUgaWQgb2YgdGhlIG1v
ZGVsIHRvIHVzZSBhdCBzZXJ2aW5nIHRpbWUuCiBDdXJyZW50bHkgb25seSBSZWNvbW1lbmRh
dGlvbk1vZGVscyBhcmUgc3VwcG9ydGVkLgogQ2FuIGJlIGNoYW5nZWQgYnV0IG9ubHkgdG8g
YSBjb21wYXRpYmxlIG1vZGVsIChlLmcuCiBvdGhlcnMteW91LW1heS1saWtlIENUUiB0byBv
dGhlcnMteW91LW1heS1saWtlIENWUikuCgogUmVxdWlyZWQgd2hlbgogW1NvbHV0aW9uVHlw
ZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlwZV0g
aXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfUkVDT01NRU5E
QVRJT05dLgoKDQoFBAACBQUSBIgBAggKDQoFBAACBQESBIgBCREKDQoFBAACBQMSBIgBFBUK
rgQKBAQAAgYSBJkBAh0anwQgSG93IG11Y2ggZGl2ZXJzaXR5IHRvIHVzZSBpbiByZWNvbW1l
bmRhdGlvbiBtb2RlbCByZXN1bHRzIGUuZy4KIGBtZWRpdW0tZGl2ZXJzaXR5YCBvciBgaGln
aC1kaXZlcnNpdHlgLiBDdXJyZW50bHkgc3VwcG9ydGVkIHZhbHVlczoKCiAqIGBuby1kaXZl
cnNpdHlgCiAqIGBsb3ctZGl2ZXJzaXR5YAogKiBgbWVkaXVtLWRpdmVyc2l0eWAKICogYGhp
Z2gtZGl2ZXJzaXR5YAogKiBgYXV0by1kaXZlcnNpdHlgCgogSWYgbm90IHNwZWNpZmllZCwg
d2UgY2hvb3NlIGRlZmF1bHQgYmFzZWQgb24gcmVjb21tZW5kYXRpb24gbW9kZWwKIHR5cGUu
IERlZmF1bHQgdmFsdWU6IGBuby1kaXZlcnNpdHlgLgoKIENhbiBvbmx5IGJlIHNldCBpZgog
W1NvbHV0aW9uVHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNv
bHV0aW9uVHlwZV0gaXMKIFtTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFUSU9OXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZ
UEVfUkVDT01NRU5EQVRJT05dLgoKDQoFBAACBgUSBJkBAggKDQoFBAACBgESBJkBCRgKDQoF
BAACBgMSBJkBGxwKggUKBAQAAgcSBKIBAiga8wQgQnJpbmcgeW91ciBvd24gZW1iZWRkaW5n
IGNvbmZpZy4gVGhlIGNvbmZpZyBpcyB1c2VkIGZvciBzZWFyY2ggc2VtYW50aWMKIHJldHJp
ZXZhbC4gVGhlIHJldHJpZXZhbCBpcyBiYXNlZCBvbiB0aGUgZG90IHByb2R1Y3Qgb2YKIFtT
ZWFyY2hSZXF1ZXN0LkVtYmVkZGluZ1NwZWMuRW1iZWRkaW5nVmVjdG9yLnZlY3Rvcl1bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNlYXJjaFJlcXVlc3QuRW1iZWRk
aW5nU3BlYy5FbWJlZGRpbmdWZWN0b3IudmVjdG9yXQogYW5kIHRoZSBkb2N1bWVudCBlbWJl
ZGRpbmdzIHRoYXQgYXJlIHByb3ZpZGVkIGJ5IHRoaXMgRW1iZWRkaW5nQ29uZmlnLiBJZgog
W1NlYXJjaFJlcXVlc3QuRW1iZWRkaW5nU3BlYy5FbWJlZGRpbmdWZWN0b3IudmVjdG9yXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VhcmNoUmVxdWVzdC5FbWJl
ZGRpbmdTcGVjLkVtYmVkZGluZ1ZlY3Rvci52ZWN0b3JdCiBpcyBwcm92aWRlZCwgaXQgb3Zl
cnJpZGVzIHRoaXMKIFtTZXJ2aW5nQ29uZmlnLmVtYmVkZGluZ19jb25maWddW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZXJ2aW5nQ29uZmlnLmVtYmVkZGluZ19j
b25maWddLgoKDQoFBAACBwYSBKIBAhEKDQoFBAACBwESBKIBEiIKDQoFBAACBwMSBKIBJScK
qwkKBAQAAggSBMIBAiEanAkgVGhlIHJhbmtpbmcgZXhwcmVzc2lvbiBjb250cm9scyB0aGUg
Y3VzdG9taXplZCByYW5raW5nIG9uIHJldHJpZXZhbAogZG9jdW1lbnRzLiBUbyBsZXZlcmFn
ZSB0aGlzLCBkb2N1bWVudCBlbWJlZGRpbmcgaXMgcmVxdWlyZWQuIFRoZSByYW5raW5nCiBl
eHByZXNzaW9uIHNldHRpbmcgaW4gU2VydmluZ0NvbmZpZyBhcHBsaWVzIHRvIGFsbCBzZWFy
Y2ggcmVxdWVzdHMgc2VydmVkCiBieSB0aGUgc2VydmluZyBjb25maWcuIEhvd2V2ZXIsIGlm
CiBbU2VhcmNoUmVxdWVzdC5yYW5raW5nX2V4cHJlc3Npb25dW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5TZWFyY2hSZXF1ZXN0LnJhbmtpbmdfZXhwcmVzc2lvbl0K
IGlzIHNwZWNpZmllZCwgaXQgb3ZlcnJpZGVzIHRoZSBTZXJ2aW5nQ29uZmlnIHJhbmtpbmcg
ZXhwcmVzc2lvbi4KCiBUaGUgcmFua2luZyBleHByZXNzaW9uIGlzIGEgc2luZ2xlIGZ1bmN0
aW9uIG9yIG11bHRpcGxlIGZ1bmN0aW9ucyB0aGF0IGFyZQogam9pbmVkIGJ5ICIrIi4KCiAg
ICogcmFua2luZ19leHByZXNzaW9uID0gZnVuY3Rpb24sIHsgIiArICIsIGZ1bmN0aW9uIH07
CgogU3VwcG9ydGVkIGZ1bmN0aW9uczoKCiAgICogZG91YmxlICogcmVsZXZhbmNlX3Njb3Jl
CiAgICogZG91YmxlICogZG90UHJvZHVjdChlbWJlZGRpbmdfZmllbGRfcGF0aCkKCiBGdW5j
dGlvbiB2YXJpYWJsZXM6CgogICAqIGByZWxldmFuY2Vfc2NvcmVgOiBwcmUtZGVmaW5lZCBr
ZXl3b3JkcywgdXNlZCBmb3IgbWVhc3VyZSByZWxldmFuY2UKICAgYmV0d2VlbiBxdWVyeSBh
bmQgZG9jdW1lbnQuCiAgICogYGVtYmVkZGluZ19maWVsZF9wYXRoYDogdGhlIGRvY3VtZW50
IGVtYmVkZGluZyBmaWVsZAogICB1c2VkIHdpdGggcXVlcnkgZW1iZWRkaW5nIHZlY3Rvci4K
ICAgKiBgZG90UHJvZHVjdGA6IGVtYmVkZGluZyBmdW5jdGlvbiBiZXR3ZWVuIGVtYmVkZGlu
Z19maWVsZF9wYXRoIGFuZCBxdWVyeQogICBlbWJlZGRpbmcgdmVjdG9yLgoKICBFeGFtcGxl
IHJhbmtpbmcgZXhwcmVzc2lvbjoKCiAgICBJZiBkb2N1bWVudCBoYXMgYW4gZW1iZWRkaW5n
IGZpZWxkIGRvY19lbWJlZGRpbmcsIHRoZSByYW5raW5nIGV4cHJlc3Npb24KICAgIGNvdWxk
IGJlIGAwLjUgKiByZWxldmFuY2Vfc2NvcmUgKyAwLjMgKiBkb3RQcm9kdWN0KGRvY19lbWJl
ZGRpbmcpYC4KCg0KBQQAAggFEgTCAQIICg0KBQQAAggBEgTCAQkbCg0KBQQAAggDEgTCAR4g
CiYKBAQAAgkSBMUBAisaGCBHdWlkZWQgc2VhcmNoIGNvbmZpZ3MuCgoNCgUEAAIJBhIExQEC
EgoNCgUEAAIJARIExQETJQoNCgUEAAIJAxIExQEoKgrgAQoEBAACChIEywECNBrRASBDdXN0
b20gZmluZSB0dW5pbmcgY29uZmlncy4KIElmCiBbU2VhcmNoUmVxdWVzdC5jdXN0b21fZmlu
ZV90dW5pbmdfc3BlY11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNl
YXJjaFJlcXVlc3QuY3VzdG9tX2ZpbmVfdHVuaW5nX3NwZWNdCiBpcyBzZXQsIGl0IGhhcyBo
aWdoZXIgcHJpb3JpdHkgdGhhbiB0aGUgY29uZmlncyBzZXQgaGVyZS4KCg0KBQQAAgoGEgTL
AQIWCg0KBQQAAgoBEgTLARcuCg0KBQQAAgoDEgTLATEzCj8KBAQAAgsSBs4BAs8BMhovIE91
dHB1dCBvbmx5LiBTZXJ2aW5nQ29uZmlnIGNyZWF0ZWQgdGltZXN0YW1wLgoKDQoFBAACCwYS
BM4BAhsKDQoFBAACCwESBM4BHCcKDQoFBAACCwMSBM4BKisKDQoFBAACCwgSBM8BBjEKEAoI
BAACCwicCAASBM8BBzAKPwoEBAACDBIG0gEC0wEyGi8gT3V0cHV0IG9ubHkuIFNlcnZpbmdD
b25maWcgdXBkYXRlZCB0aW1lc3RhbXAuCgoNCgUEAAIMBhIE0gECGwoNCgUEAAIMARIE0gEc
JwoNCgUEAAIMAxIE0gEqKwoNCgUEAAIMCBIE0wEGMQoQCggEAAIMCJwIABIE0wEHMArPAQoE
BAACDRIE2QECKhrAASBGaWx0ZXIgY29udHJvbHMgdG8gdXNlIGluIHNlcnZpbmcgcGF0aC4K
IEFsbCB0cmlnZ2VyZWQgZmlsdGVyIGNvbnRyb2xzIHdpbGwgYmUgYXBwbGllZC4KIEZpbHRl
ciBjb250cm9scyBtdXN0IGJlIGluIHRoZSBzYW1lIGRhdGEgc3RvcmUgYXMgdGhlIHNlcnZp
bmcgY29uZmlnLgogTWF4aW11bSBvZiAyMCBmaWx0ZXIgY29udHJvbHMuCgoNCgUEAAINBBIE
2QECCgoNCgUEAAINBRIE2QELEQoNCgUEAAINARIE2QESJAoNCgUEAAINAxIE2QEnKQrLAQoE
BAACDhIE3wECKRq8ASBCb29zdCBjb250cm9scyB0byB1c2UgaW4gc2VydmluZyBwYXRoLgog
QWxsIHRyaWdnZXJlZCBib29zdCBjb250cm9scyB3aWxsIGJlIGFwcGxpZWQuCiBCb29zdCBj
b250cm9scyBtdXN0IGJlIGluIHRoZSBzYW1lIGRhdGEgc3RvcmUgYXMgdGhlIHNlcnZpbmcg
Y29uZmlnLgogTWF4aW11bSBvZiAyMCBib29zdCBjb250cm9scy4KCg0KBQQAAg4EEgTfAQIK
Cg0KBQQAAg4FEgTfAQsRCg0KBQQAAg4BEgTfARIjCg0KBQQAAg4DEgTfASYoCuICCgQEAAIP
EgToAQIsGtMCIElEcyBvZiB0aGUgcmVkaXJlY3QgY29udHJvbHMuIE9ubHkgdGhlIGZpcnN0
IHRyaWdnZXJlZCByZWRpcmVjdAogYWN0aW9uIGlzIGFwcGxpZWQsIGV2ZW4gaWYgbXVsdGlw
bGUgYXBwbHkuIE1heGltdW0gbnVtYmVyIG9mCiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAuCgog
Q2FuIG9ubHkgYmUgc2V0IGlmCiBbU29sdXRpb25UeXBlXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VB
UkNIXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBl
LlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAg8EEgToAQIKCg0KBQQAAg8FEgToAQsR
Cg0KBQQAAg8BEgToARImCg0KBQQAAg8DEgToASkrCvoCCgQEAAIQEgTxAQIsGusCIENvbmRp
dGlvbiBzeW5vbnltcyBzcGVjaWZpY2F0aW9ucy4gSWYgbXVsdGlwbGUgc3lub255bXMgY29u
ZGl0aW9ucwogbWF0Y2gsIGFsbCBtYXRjaGluZyBzeW5vbnltcyBjb250cm9scyBpbiB0aGUg
bGlzdCB3aWxsIGV4ZWN1dGUuCiBNYXhpbXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBp
cyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0IGlmCiBbU29sdXRpb25UeXBlXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlXSBpcwogW1NPTFVUSU9O
X1RZUEVfU0VBUkNIXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29s
dXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCg0KBQQAAhAEEgTxAQIKCg0KBQQA
AhAFEgTxAQsRCg0KBQQAAhABEgTxARImCg0KBQQAAhADEgTxASkrCo8DCgQEAAIREgT6AQIz
GoADIENvbmRpdGlvbiBvbmV3YXkgc3lub255bXMgc3BlY2lmaWNhdGlvbnMuIElmIG11bHRp
cGxlIG9uZXdheSBzeW5vbnltcwogY29uZGl0aW9ucyBtYXRjaCwgYWxsIG1hdGNoaW5nIG9u
ZXdheSBzeW5vbnltcyBjb250cm9scyBpbiB0aGUgbGlzdAogd2lsbCBleGVjdXRlLiBNYXhp
bXVtIG51bWJlciBvZiBzcGVjaWZpY2F0aW9ucyBpcyAxMDAuCgogQ2FuIG9ubHkgYmUgc2V0
IGlmCiBbU29sdXRpb25UeXBlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuU29sdXRpb25UeXBlXSBpcwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVf
U0VBUkNIXS4KCg0KBQQAAhEEEgT6AQIKCg0KBQQAAhEFEgT6AQsRCg0KBQQAAhEBEgT6ARIt
Cg0KBQQAAhEDEgT6ATAyCqsDCgQEAAISEgSFAgIuGpwDIENvbmRpdGlvbiBkbyBub3QgYXNz
b2NpYXRlIHNwZWNpZmljYXRpb25zLiBJZiBtdWx0aXBsZSBkbyBub3QKIGFzc29jaWF0ZSBj
b25kaXRpb25zIG1hdGNoLCBhbGwgbWF0Y2hpbmcgZG8gbm90IGFzc29jaWF0ZSBjb250cm9s
cyBpbgogdGhlIGxpc3Qgd2lsbCBleGVjdXRlLgogT3JkZXIgZG9lcyBub3QgbWF0dGVyLgog
TWF4aW11bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoKIENhbiBvbmx5IGJl
IHNldCBpZgogW1NvbHV0aW9uVHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNvbHV0aW9uVHlwZV0gaXMKIFtTT0xVVElPTl9UWVBFX1NFQVJDSF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9U
WVBFX1NFQVJDSF0uCgoNCgUEAAISBBIEhQICCgoNCgUEAAISBRIEhQILEQoNCgUEAAISARIE
hQISKAoNCgUEAAISAxIEhQIrLQr9AgoEBAACExIEjwICLxruAiBDb25kaXRpb24gcmVwbGFj
ZW1lbnQgc3BlY2lmaWNhdGlvbnMuCiBBcHBsaWVkIGFjY29yZGluZyB0byB0aGUgb3JkZXIg
aW4gdGhlIGxpc3QuCiBBIHByZXZpb3VzbHkgcmVwbGFjZWQgdGVybSBjYW4gbm90IGJlIHJl
LXJlcGxhY2VkLgogTWF4aW11bSBudW1iZXIgb2Ygc3BlY2lmaWNhdGlvbnMgaXMgMTAwLgoK
IENhbiBvbmx5IGJlIHNldCBpZgogW1NvbHV0aW9uVHlwZV1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlwZV0gaXMKIFtTT0xVVElPTl9UWVBFX1NF
QVJDSF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNvbHV0aW9uVHlw
ZS5TT0xVVElPTl9UWVBFX1NFQVJDSF0uCgoNCgUEAAITBBIEjwICCgoNCgUEAAITBRIEjwIL
EQoNCgUEAAITARIEjwISKQoNCgUEAAITAxIEjwIsLgrRAQoEBAACFBIElgICKhrCASBDb25k
aXRpb24gaWdub3JlIHNwZWNpZmljYXRpb25zLiBJZiBtdWx0aXBsZSBpZ25vcmUKIGNvbmRp
dGlvbnMgbWF0Y2gsIGFsbCBtYXRjaGluZyBpZ25vcmUgY29udHJvbHMgaW4gdGhlIGxpc3Qg
d2lsbAogZXhlY3V0ZS4KIE9yZGVyIGRvZXMgbm90IG1hdHRlci4KIE1heGltdW0gbnVtYmVy
IG9mIHNwZWNpZmljYXRpb25zIGlzIDEwMC4KCg0KBQQAAhQEEgSWAgIKCg0KBQQAAhQFEgSW
AgsRCg0KBQQAAhQBEgSWAhIkCg0KBQQAAhQDEgSWAicpYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig ===
    # Fields for ServingConfig
    # Field: media_config Type: 11 (.google.cloud.discoveryengine.v1alpha.ServingConfig.MediaConfig)
    # Field: generic_config Type: 11 (.google.cloud.discoveryengine.v1alpha.ServingConfig.GenericConfig)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: solution_type Type: 14 (.google.cloud.discoveryengine.v1alpha.SolutionType)
    # Field: model_id Type: 9 ()
    # Field: diversity_level Type: 9 ()
    # Field: embedding_config Type: 11 (.google.cloud.discoveryengine.v1alpha.EmbeddingConfig)
    # Field: ranking_expression Type: 9 ()
    # Field: guided_search_spec Type: 11 (.google.cloud.discoveryengine.v1alpha.GuidedSearchSpec)
    # Field: custom_fine_tuning_spec Type: 11 (.google.cloud.discoveryengine.v1alpha.CustomFineTuningSpec)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: filter_control_ids Type: 9 ()
    # Field: boost_control_ids Type: 9 ()
    # Field: redirect_control_ids Type: 9 ()
    # Field: synonyms_control_ids Type: 9 ()
    # Field: oneway_synonyms_control_ids Type: 9 ()
    # Field: dissociate_control_ids Type: 9 ()
    # Field: replacement_control_ids Type: 9 ()
    # Field: ignore_control_ids Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ServingConfig - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/serving_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::ServingConfig;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig->new({
        media_config => $media_config,
        generic_config => $generic_config,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->media_config();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/serving_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig

Configures metadata that is used to generate serving time results (e.g.
search results or recommendation predictions).
The ServingConfig is passed in the search and predict request and generates
results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->media_config() >> / C<< $msg->media_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::MediaConfig>)

The MediaConfig of the serving configuration.

=item * C<< $msg->generic_config() >> / C<< $msg->generic_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::ServingConfig::GenericConfig>)

The GenericConfig of the serving configuration.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human readable serving config display name. Used in Discovery
UI.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->solution_type() >> / C<< $msg->solution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SolutionType>)

Required. Immutable. Specifies the solution type that a serving config can
be associated with.

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

The id of the model to use at serving time.
Currently only RecommendationModels are supported.
Can be changed but only to a compatible model (e.g.
others-you-may-like CTR to others-you-may-like CVR).

Required when
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->diversity_level() >> / C<< $msg->diversity_level($value) >>

Type: C<String>

How much diversity to use in recommendation model results e.g.
`medium-diversity` or `high-diversity`. Currently supported values:

* `no-diversity`
* `low-diversity`
* `medium-diversity`
* `high-diversity`
* `auto-diversity`

If not specified, we choose default based on recommendation model
type. Default value: `no-diversity`.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_RECOMMENDATION][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_RECOMMENDATION].

=item * C<< $msg->embedding_config() >> / C<< $msg->embedding_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::EmbeddingConfig>)

Bring your own embedding config. The config is used for search semantic
retrieval. The retrieval is based on the dot product of
[SearchRequest.EmbeddingSpec.EmbeddingVector.vector][google.cloud.discoveryengine.v1alpha.SearchRequest.EmbeddingSpec.EmbeddingVector.vector]
and the document embeddings that are provided by this EmbeddingConfig. If
[SearchRequest.EmbeddingSpec.EmbeddingVector.vector][google.cloud.discoveryengine.v1alpha.SearchRequest.EmbeddingSpec.EmbeddingVector.vector]
is provided, it overrides this
[ServingConfig.embedding_config][google.cloud.discoveryengine.v1alpha.ServingConfig.embedding_config].

=item * C<< $msg->ranking_expression() >> / C<< $msg->ranking_expression($value) >>

Type: C<String>

The ranking expression controls the customized ranking on retrieval
documents. To leverage this, document embedding is required. The ranking
expression setting in ServingConfig applies to all search requests served
by the serving config. However, if
[SearchRequest.ranking_expression][google.cloud.discoveryengine.v1alpha.SearchRequest.ranking_expression]
is specified, it overrides the ServingConfig ranking expression.

The ranking expression is a single function or multiple functions that are
joined by "+".

  * ranking_expression = function, { " + ", function };

Supported functions:

  * double * relevance_score
  * double * dotProduct(embedding_field_path)

Function variables:

  * `relevance_score`: pre-defined keywords, used for measure relevance
  between query and document.
  * `embedding_field_path`: the document embedding field
  used with query embedding vector.
  * `dotProduct`: embedding function between embedding_field_path and query
  embedding vector.

 Example ranking expression:

   If document has an embedding field doc_embedding, the ranking expression
   could be `0.5 * relevance_score + 0.3 * dotProduct(doc_embedding)`.

=item * C<< $msg->guided_search_spec() >> / C<< $msg->guided_search_spec($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::GuidedSearchSpec>)

Guided search configs.

=item * C<< $msg->custom_fine_tuning_spec() >> / C<< $msg->custom_fine_tuning_spec($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::CustomFineTuningSpec>)

Custom fine tuning configs.
If
[SearchRequest.custom_fine_tuning_spec][google.cloud.discoveryengine.v1alpha.SearchRequest.custom_fine_tuning_spec]
is set, it has higher priority than the configs set here.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. ServingConfig created timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. ServingConfig updated timestamp.

=item * C<< $msg->filter_control_ids() >> / C<< $msg->filter_control_ids($value) >>

Type: C<String>

Filter controls to use in serving path.
All triggered filter controls will be applied.
Filter controls must be in the same data store as the serving config.
Maximum of 20 filter controls.

=item * C<< $msg->boost_control_ids() >> / C<< $msg->boost_control_ids($value) >>

Type: C<String>

Boost controls to use in serving path.
All triggered boost controls will be applied.
Boost controls must be in the same data store as the serving config.
Maximum of 20 boost controls.

=item * C<< $msg->redirect_control_ids() >> / C<< $msg->redirect_control_ids($value) >>

Type: C<String>

IDs of the redirect controls. Only the first triggered redirect
action is applied, even if multiple apply. Maximum number of
specifications is 100.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->synonyms_control_ids() >> / C<< $msg->synonyms_control_ids($value) >>

Type: C<String>

Condition synonyms specifications. If multiple synonyms conditions
match, all matching synonyms controls in the list will execute.
Maximum number of specifications is 100.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->oneway_synonyms_control_ids() >> / C<< $msg->oneway_synonyms_control_ids($value) >>

Type: C<String>

Condition oneway synonyms specifications. If multiple oneway synonyms
conditions match, all matching oneway synonyms controls in the list
will execute. Maximum number of specifications is 100.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->dissociate_control_ids() >> / C<< $msg->dissociate_control_ids($value) >>

Type: C<String>

Condition do not associate specifications. If multiple do not
associate conditions match, all matching do not associate controls in
the list will execute.
Order does not matter.
Maximum number of specifications is 100.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->replacement_control_ids() >> / C<< $msg->replacement_control_ids($value) >>

Type: C<String>

Condition replacement specifications.
Applied according to the order in the list.
A previously replaced term can not be re-replaced.
Maximum number of specifications is 100.

Can only be set if
[SolutionType][google.cloud.discoveryengine.v1alpha.SolutionType] is
[SOLUTION_TYPE_SEARCH][google.cloud.discoveryengine.v1alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->ignore_control_ids() >> / C<< $msg->ignore_control_ids($value) >>

Type: C<String>

Condition ignore specifications. If multiple ignore
conditions match, all matching ignore controls in the list will
execute.
Order does not matter.
Maximum number of specifications is 100.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::ServingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
