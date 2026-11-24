package Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::Grounding };
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZ3JvdW5kZWRfZ2VuZXJh
dGlvbl9zZXJ2aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnBy
b3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291
cmNlLnByb3RvGjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZ3JvdW5k
aW5nLnByb3RvIl8KEkNoZWNrR3JvdW5kaW5nU3BlYxIyChJjaXRhdGlvbl90aHJlc2hvbGQY
ASABKAFIAFIRY2l0YXRpb25UaHJlc2hvbGSIAQFCFQoTX2NpdGF0aW9uX3RocmVzaG9sZCL+
AwoVQ2hlY2tHcm91bmRpbmdSZXF1ZXN0EmEKEGdyb3VuZGluZ19jb25maWcYASABKAlCNuBB
AvpBMAouZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0dyb3VuZGluZ0NvbmZpZ1IP
Z3JvdW5kaW5nQ29uZmlnEikKEGFuc3dlcl9jYW5kaWRhdGUYAiABKAlSD2Fuc3dlckNhbmRp
ZGF0ZRJJCgVmYWN0cxgDIAMoCzIzLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5Hcm91bmRpbmdGYWN0UgVmYWN0cxJfCg5ncm91bmRpbmdfc3BlYxgEIAEoCzI4Lmdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DaGVja0dyb3VuZGluZ1NwZWNS
DWdyb3VuZGluZ1NwZWMSbAoLdXNlcl9sYWJlbHMYBSADKAsySy5nb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2hlY2tHcm91bmRpbmdSZXF1ZXN0LlVzZXJMYWJlbHNF
bnRyeVIKdXNlckxhYmVscxo9Cg9Vc2VyTGFiZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkS
FAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKOBAoWQ2hlY2tHcm91bmRpbmdSZXNwb25zZRIo
Cg1zdXBwb3J0X3Njb3JlGAEgASgCSABSDHN1cHBvcnRTY29yZYgBARJSCgxjaXRlZF9jaHVu
a3MYAyADKAsyLy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmFjdENo
dW5rUgtjaXRlZENodW5rcxJaCgZjbGFpbXMYBCADKAsyQi5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYWxwaGEuQ2hlY2tHcm91bmRpbmdSZXNwb25zZS5DbGFpbVIGY2xhaW1z
GocCCgVDbGFpbRIgCglzdGFydF9wb3MYASABKAVIAFIIc3RhcnRQb3OIAQESHAoHZW5kX3Bv
cxgCIAEoBUgBUgZlbmRQb3OIAQESHQoKY2xhaW1fdGV4dBgDIAEoCVIJY2xhaW1UZXh0EikK
EGNpdGF0aW9uX2luZGljZXMYBCADKAVSD2NpdGF0aW9uSW5kaWNlcxI9Chhncm91bmRpbmdf
Y2hlY2tfcmVxdWlyZWQYBiABKAhIAlIWZ3JvdW5kaW5nQ2hlY2tSZXF1aXJlZIgBAUIMCgpf
c3RhcnRfcG9zQgoKCF9lbmRfcG9zQhsKGV9ncm91bmRpbmdfY2hlY2tfcmVxdWlyZWRCEAoO
X3N1cHBvcnRfc2NvcmUy1QIKGUdyb3VuZGVkR2VuZXJhdGlvblNlcnZpY2US4wEKDkNoZWNr
R3JvdW5kaW5nEjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNoZWNr
R3JvdW5kaW5nUmVxdWVzdBo8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5DaGVja0dyb3VuZGluZ1Jlc3BvbnNlIlaC0+STAlAiSy92MWFscGhhL3tncm91bmRpbmdf
Y29uZmlnPXByb2plY3RzLyovbG9jYXRpb25zLyovZ3JvdW5kaW5nQ29uZmlncy8qfTpjaGVj
azoBKhpSykEeZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cu
Z29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKqAgooY29tLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIeR3JvdW5kZWRHZW5lcmF0aW9uU2VydmljZVBy
b3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEv
ZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWq
AiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRc
RGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdp
bmU6OlYxYWxwaGFKsCwKBxIFDgCVAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
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
c2UuCgoICgECEgMQAC0KCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMS
AxUAIwoJCgIDBBIDFgA+CggKAQgSAxgAQQoJCgIIJRIDGABBCggKAQgSAxkAaQoJCgIICxID
GQBpCggKAQgSAxoAIgoJCgIIChIDGgAiCggKAQgSAxsAPwoJCgIICBIDGwA/CggKAQgSAxwA
QQoJCgIIARIDHABBCggKAQgSAx0ALQoJCgIIJBIDHQAtCggKAQgSAx4AQQoJCgIIKRIDHgBB
CggKAQgSAx8AQAoJCgIILRIDHwBACi4KAgYAEgQiAC4BGiIgU2VydmljZSBmb3IgZ3JvdW5k
ZWQgZ2VuZXJhdGlvbi4KCgoKAwYAARIDIgghCgoKAwYAAxIDIwJGCgwKBQYAA5kIEgMjAkYK
CwoDBgADEgQkAiU3Cg0KBQYAA5oIEgQkAiU3CisKBAYAAgASBCgCLQMaHSBQZXJmb3JtcyBh
IGdyb3VuZGluZyBjaGVjay4KCgwKBQYAAgABEgMoBhQKDAoFBgACAAISAygVKgoMCgUGAAIA
AxIDKDVLCg0KBQYAAgAEEgQpBCwGChEKCQYAAgAEsMq8IhIEKQQsBgo0CgIEABIEMQA4ARoo
IFNwZWNpZmljYXRpb24gZm9yIHRoZSBncm91bmRpbmcgY2hlY2suCgoKCgMEAAESAzEIGgrL
AgoEBAACABIDNwIpGr0CIFRoZSB0aHJlc2hvbGQgKGluIFswLDFdKSB1c2VkIGZvciBkZXRl
cm1pbmluZyB3aGV0aGVyIGEgZmFjdCBtdXN0IGJlCiBjaXRlZCBmb3IgYSBjbGFpbSBpbiB0
aGUgYW5zd2VyIGNhbmRpZGF0ZS4gQ2hvb3NpbmcgYSBoaWdoZXIgdGhyZXNob2xkCiB3aWxs
IGxlYWQgdG8gZmV3ZXIgYnV0IHZlcnkgc3Ryb25nIGNpdGF0aW9ucywgd2hpbGUgY2hvb3Np
bmcgYSBsb3dlcgogdGhyZXNob2xkIG1heSBsZWFkIHRvIG1vcmUgYnV0IHNvbWV3aGF0IHdl
YWtlciBjaXRhdGlvbnMuIElmIHVuc2V0LCB0aGUKIHRocmVzaG9sZCB3aWxsIGRlZmF1bHQg
dG8gMC42LgoKDAoFBAACAAQSAzcCCgoMCgUEAAIABRIDNwsRCgwKBQQAAgABEgM3EiQKDAoF
BAACAAMSAzcnKAqmAQoCBAESBD0AYwEamQEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0dyb3Vu
ZGVkR2VuZXJhdGlvblNlcnZpY2UuQ2hlY2tHcm91bmRpbmddW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjFhbHBoYS5Hcm91bmRlZEdlbmVyYXRpb25TZXJ2aWNlLkNoZWNrR3Jv
dW5kaW5nXQogbWV0aG9kLgoKCgoDBAEBEgM9CB0KlwEKBAQBAgASBEACRQQaiAEgUmVxdWly
ZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBncm91bmRpbmcgY29uZmlnLCBzdWNoIGFz
CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFsL2dyb3VuZGluZ0NvbmZpZ3MvZGVmYXVs
dF9ncm91bmRpbmdfY29uZmlnYC4KCgwKBQQBAgAFEgNAAggKDAoFBAECAAESA0AJGQoMCgUE
AQIAAxIDQBwdCg0KBQQBAgAIEgRAHkUDCg8KCAQBAgAInAgAEgNBBCoKDwoHBAECAAifCBIE
QgREBQpXCgQEAQIBEgNIAh4aSiBBbnN3ZXIgY2FuZGlkYXRlIHRvIGNoZWNrLiBDYW4gaGF2
ZSBhIG1heGltdW0gbGVuZ3RoIG9mIDEwMjQgY2hhcmFjdGVycy4KCgwKBQQBAgEFEgNIAggK
DAoFBAECAQESA0gJGQoMCgUEAQIBAxIDSBwdClIKBAQBAgISA0wCIxpFIExpc3Qgb2YgZmFj
dHMgZm9yIHRoZSBncm91bmRpbmcgY2hlY2suCiBXZSBzdXBwb3J0IHVwIHRvIDIwMCBmYWN0
cy4KCgwKBQQBAgIEEgNMAgoKDAoFBAECAgYSA0wLGAoMCgUEAQICARIDTBkeCgwKBQQBAgID
EgNMISIKNAoEBAECAxIDTwIoGicgQ29uZmlndXJhdGlvbiBvZiB0aGUgZ3JvdW5kaW5nIGNo
ZWNrLgoKDAoFBAECAwYSA08CFAoMCgUEAQIDARIDTxUjCgwKBQQBAgMDEgNPJicK6wYKBAQB
AgQSA2ICJhrdBiBUaGUgdXNlciBsYWJlbHMgYXBwbGllZCB0byBhIHJlc291cmNlIG11c3Qg
bWVldCB0aGUgZm9sbG93aW5nIHJlcXVpcmVtZW50czoKCiAqIEVhY2ggcmVzb3VyY2UgY2Fu
IGhhdmUgbXVsdGlwbGUgbGFiZWxzLCB1cCB0byBhIG1heGltdW0gb2YgNjQuCiAqIEVhY2gg
bGFiZWwgbXVzdCBiZSBhIGtleS12YWx1ZSBwYWlyLgogKiBLZXlzIGhhdmUgYSBtaW5pbXVt
IGxlbmd0aCBvZiAxIGNoYXJhY3RlciBhbmQgYSBtYXhpbXVtIGxlbmd0aCBvZiA2MwogICBj
aGFyYWN0ZXJzIGFuZCBjYW5ub3QgYmUgZW1wdHkuIFZhbHVlcyBjYW4gYmUgZW1wdHkgYW5k
IGhhdmUgYSBtYXhpbXVtCiAgIGxlbmd0aCBvZiA2MyBjaGFyYWN0ZXJzLgogKiBLZXlzIGFu
ZCB2YWx1ZXMgY2FuIGNvbnRhaW4gb25seSBsb3dlcmNhc2UgbGV0dGVycywgbnVtZXJpYyBj
aGFyYWN0ZXJzLAogICB1bmRlcnNjb3JlcywgYW5kIGRhc2hlcy4gQWxsIGNoYXJhY3RlcnMg
bXVzdCB1c2UgVVRGLTggZW5jb2RpbmcsIGFuZAogICBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rl
cnMgYXJlIGFsbG93ZWQuCiAqIFRoZSBrZXkgcG9ydGlvbiBvZiBhIGxhYmVsIG11c3QgYmUg
dW5pcXVlLiBIb3dldmVyLCB5b3UgY2FuIHVzZSB0aGUgc2FtZQogICBrZXkgd2l0aCBtdWx0
aXBsZSByZXNvdXJjZXMuCiAqIEtleXMgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxl
dHRlciBvciBpbnRlcm5hdGlvbmFsIGNoYXJhY3Rlci4KCiBTZWUgW0dvb2dsZSBDbG91ZAog
RG9jdW1lbnRdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9yZXNvdXJjZS1tYW5hZ2VyL2Rv
Y3MvY3JlYXRpbmctbWFuYWdpbmctbGFiZWxzI3JlcXVpcmVtZW50cykKIGZvciBtb3JlIGRl
dGFpbHMuCgoMCgUEAQIEBhIDYgIVCgwKBQQBAgQBEgNiFiEKDAoFBAECBAMSA2IkJQqsAQoC
BAISBWgAlQEBGp4BIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZQogW0dyb3VuZGVkR2VuZXJh
dGlvblNlcnZpY2UuQ2hlY2tHcm91bmRpbmddW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjFhbHBoYS5Hcm91bmRlZEdlbmVyYXRpb25TZXJ2aWNlLkNoZWNrR3JvdW5kaW5nXQog
bWV0aG9kLgoKCgoDBAIBEgNoCB4KTAoEBAIDABIFagKIAQMaPSBUZXh0IGFuZCBjaXRhdGlv
biBpbmZvIGZvciBhIGNsYWltIGluIHRoZSBhbnN3ZXIgY2FuZGlkYXRlLgoKDAoFBAIDAAES
A2oKDwpoCgYEAgMAAgASA20EIRpZIFBvc2l0aW9uIGluZGljYXRpbmcgdGhlIHN0YXJ0IG9m
IHRoZSBjbGFpbSBpbiB0aGUgYW5zd2VyIGNhbmRpZGF0ZSwKIG1lYXN1cmVkIGluIGJ5dGVz
LgoKDgoHBAIDAAIABBIDbQQMCg4KBwQCAwACAAUSA20NEgoOCgcEAgMAAgABEgNtExwKDgoH
BAIDAAIAAxIDbR8gCl4KBgQCAwACARIDcQQfGk8gUG9zaXRpb24gaW5kaWNhdGluZyB0aGUg
ZW5kIG9mIHRoZSBjbGFpbSBpbiB0aGUgYW5zd2VyIGNhbmRpZGF0ZSwKIGV4Y2x1c2l2ZS4K
Cg4KBwQCAwACAQQSA3EEDAoOCgcEAgMAAgEFEgNxDRIKDgoHBAIDAAIBARIDcRMaCg4KBwQC
AwACAQMSA3EdHgqKAQoGBAIDAAICEgN1BBoaeyBUZXh0IGZvciB0aGUgY2xhaW0gaW4gdGhl
IGFuc3dlciBjYW5kaWRhdGUuIEFsd2F5cyBwcm92aWRlZCByZWdhcmRsZXNzIG9mCiB3aGV0
aGVyIGNpdGF0aW9ucyBvciBhbnRpLWNpdGF0aW9ucyBhcmUgZm91bmQuCgoOCgcEAgMAAgIF
EgN1BAoKDgoHBAIDAAICARIDdQsVCg4KBwQCAwACAgMSA3UYGQq5AgoGBAIDAAIDEgN8BCga
qQIgQSBsaXN0IG9mIGluZGljZXMgKGludG8gJ2NpdGVkX2NodW5rcycpIHNwZWNpZnlpbmcg
dGhlIGNpdGF0aW9ucwogYXNzb2NpYXRlZCB3aXRoIHRoZSBjbGFpbS4gRm9yIGluc3RhbmNl
IFsxLDMsNF0gbWVhbnMgdGhhdAogY2l0ZWRfY2h1bmtzWzFdLCBjaXRlZF9jaHVua3NbM10s
IGNpdGVkX2NodW5rc1s0XSBhcmUgdGhlIGZhY3RzIGNpdGVkCiBzdXBwb3J0aW5nIGZvciB0
aGUgY2xhaW0uIEEgY2l0YXRpb24gdG8gYSBmYWN0IGluZGljYXRlcyB0aGF0IHRoZSBjbGFp
bQogaXMgc3VwcG9ydGVkIGJ5IHRoZSBmYWN0LgoKDgoHBAIDAAIDBBIDfAQMCg4KBwQCAwAC
AwUSA3wNEgoOCgcEAgMAAgMBEgN8EyMKDgoHBAIDAAIDAxIDfCYnCswECgYEAgMAAgQSBIcB
BC8auwQgSW5kaWNhdGVzIHRoYXQgdGhpcyBjbGFpbSByZXF1aXJlZCBncm91bmRpbmcgY2hl
Y2suIFdoZW4gdGhlIHN5c3RlbQogZGVjaWRlZCB0aGlzIGNsYWltIGRvZXNuJ3QgcmVxdWly
ZSBhdHRyaWJ1dGlvbi9ncm91bmRpbmcgY2hlY2ssIHRoaXMKIGZpZWxkIHdpbGwgYmUgc2V0
IHRvIGZhbHNlLiBJbiB0aGF0IGNhc2UsIG5vIGdyb3VuZGluZyBjaGVjayB3YXMgZG9uZSBm
b3IKIHRoZSBjbGFpbSBhbmQgdGhlcmVmb3JlCiBbY2l0YXRpb25faW5kaWNlc11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNoZWNrR3JvdW5kaW5nUmVzcG9uc2Uu
Q2xhaW0uY2l0YXRpb25faW5kaWNlc10sCiBbYW50aV9jaXRhdGlvbl9pbmRpY2VzXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2hlY2tHcm91bmRpbmdSZXNwb25z
ZS5DbGFpbS5hbnRpX2NpdGF0aW9uX2luZGljZXNdLAogYW5kCiBbc2NvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DaGVja0dyb3VuZGluZ1Jlc3BvbnNlLkNs
YWltLnNjb3JlXQogc2hvdWxkIG5vdCBiZSByZXR1cm5lZC4KCg8KBwQCAwACBAQSBIcBBAwK
DwoHBAIDAAIEBRIEhwENEQoPCgcEAgMAAgQBEgSHARIqCg8KBwQCAwACBAMSBIcBLS4K0QEK
BAQCAgASBI0BAiMawgEgVGhlIHN1cHBvcnQgc2NvcmUgZm9yIHRoZSBpbnB1dCBhbnN3ZXIg
Y2FuZGlkYXRlLgogSGlnaGVyIHRoZSBzY29yZSwgaGlnaGVyIGlzIHRoZSBmcmFjdGlvbiBv
ZiBjbGFpbXMgdGhhdCBhcmUgc3VwcG9ydGVkIGJ5CiB0aGUgcHJvdmlkZWQgZmFjdHMuIFRo
aXMgaXMgYWx3YXlzIHNldCB3aGVuIGEgcmVzcG9uc2UgaXMgcmV0dXJuZWQuCgoNCgUEAgIA
BBIEjQECCgoNCgUEAgIABRIEjQELEAoNCgUEAgIAARIEjQERHgoNCgUEAgIAAxIEjQEhIgqJ
AQoEBAICARIEkQECJhp7IExpc3Qgb2YgZmFjdHMgY2l0ZWQgYWNyb3NzIGFsbCBjbGFpbXMg
aW4gdGhlIGFuc3dlciBjYW5kaWRhdGUuCiBUaGVzZSBhcmUgZGVyaXZlZCBmcm9tIHRoZSBm
YWN0cyBzdXBwbGllZCBpbiB0aGUgcmVxdWVzdC4KCg0KBQQCAgEEEgSRAQIKCg0KBQQCAgEG
EgSRAQsUCg0KBQQCAgEBEgSRARUhCg0KBQQCAgEDEgSRASQlClgKBAQCAgISBJQBAhwaSiBD
bGFpbSB0ZXh0cyBhbmQgY2l0YXRpb24gaW5mbyBhY3Jvc3MgYWxsIGNsYWltcyBpbiB0aGUg
YW5zd2VyIGNhbmRpZGF0ZS4KCg0KBQQCAgIEEgSUAQIKCg0KBQQCAgIGEgSUAQsQCg0KBQQC
AgIBEgSUAREXCg0KBQQCAgIDEgSUARobYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec ===
    # Fields for CheckGroundingSpec
    # Field: citation_threshold Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest ===
    # Fields for CheckGroundingRequest
    # Field: grounding_config Type: 9 ()
    # Field: answer_candidate Type: 9 ()
    # Field: facts Type: 11 (.google.cloud.discoveryengine.v1alpha.GroundingFact)
    # Field: grounding_spec Type: 11 (.google.cloud.discoveryengine.v1alpha.CheckGroundingSpec)
    # Field: user_labels Type: 11 (.google.cloud.discoveryengine.v1alpha.CheckGroundingRequest.UserLabelsEntry)

# === Message: Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse ===
    # Fields for CheckGroundingResponse
    # Field: support_score Type: 2 ()
    # Field: cited_chunks Type: 11 (.google.cloud.discoveryengine.v1alpha.FactChunk)
    # Field: claims Type: 11 (.google.cloud.discoveryengine.v1alpha.CheckGroundingResponse.Claim)

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::GroundedGenerationServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::GroundedGenerationServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::GroundedGenerationServiceClient

Client stub representing the remote C<GroundedGenerationService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub check_grounding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.GroundedGenerationService',
        method         => 'CheckGrounding',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/grounded_generation_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec->new({
        citation_threshold => $citation_threshold,
    });

    # Read or update a field
    my $val = $msg->citation_threshold();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/grounded_generation_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec

Specification for the grounding check.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->citation_threshold() >> / C<< $msg->citation_threshold($value) >>

Type: C<Double>

The threshold (in [0,1]) used for determining whether a fact must be
cited for a claim in the answer candidate. Choosing a higher threshold
will lead to fewer but very strong citations, while choosing a lower
threshold may lead to more but somewhat weaker citations. If unset, the
threshold will default to 0.6.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest

Request message for
[GroundedGenerationService.CheckGrounding][google.cloud.discoveryengine.v1alpha.GroundedGenerationService.CheckGrounding]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grounding_config() >> / C<< $msg->grounding_config($value) >>

Type: C<String>

Required. The resource name of the grounding config, such as
`projects/*/locations/global/groundingConfigs/default_grounding_config`.

=item * C<< $msg->answer_candidate() >> / C<< $msg->answer_candidate($value) >>

Type: C<String>

Answer candidate to check. Can have a maximum length of 1024 characters.

=item * C<< $msg->facts() >> / C<< $msg->facts($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact>)

List of facts for the grounding check.
We support up to 200 facts.

=item * C<< $msg->grounding_spec() >> / C<< $msg->grounding_spec($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec>)

Configuration of the grounding check.

=item * C<< $msg->user_labels() >> / C<< $msg->user_labels($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry>)

The user labels applied to a resource must meet the following requirements:

* Each resource can have multiple labels, up to a maximum of 64.
* Each label must be a key-value pair.
* Keys have a minimum length of 1 character and a maximum length of 63
  characters and cannot be empty. Values can be empty and have a maximum
  length of 63 characters.
* Keys and values can contain only lowercase letters, numeric characters,
  underscores, and dashes. All characters must use UTF-8 encoding, and
  international characters are allowed.
* The key portion of a label must be unique. However, you can use the same
  key with multiple resources.
* Keys must start with a lowercase letter or international character.

See [Google Cloud
Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
for more details.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse

Response message for the
[GroundedGenerationService.CheckGrounding][google.cloud.discoveryengine.v1alpha.GroundedGenerationService.CheckGrounding]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->support_score() >> / C<< $msg->support_score($value) >>

Type: C<Float>

The support score for the input answer candidate.
Higher the score, higher is the fraction of claims that are supported by
the provided facts. This is always set when a response is returned.

=item * C<< $msg->cited_chunks() >> / C<< $msg->cited_chunks($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Grounding::FactChunk>)

List of facts cited across all claims in the answer candidate.
These are derived from the facts supplied in the request.

=item * C<< $msg->claims() >> / C<< $msg->claims($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse::Claim>)

Claim texts and citation info across all claims in the answer candidate.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
