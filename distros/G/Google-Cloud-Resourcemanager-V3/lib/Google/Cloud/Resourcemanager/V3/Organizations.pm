package Google::Cloud::Resourcemanager::V3::Organizations;

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
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvcmVzb3VyY2VtYW5hZ2VyL3YzL29yZ2FuaXphdGlvbnMucHJvdG8S
H2dvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvaWFtL3Yx
L2lhbV9wb2xpY3kucHJvdG8aGmdvb2dsZS9pYW0vdjEvcG9saWN5LnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvItwECgxPcmdhbml6YXRpb24SFwoEbmFtZRgBIAEo
CUID4EEDUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EEDUgtkaXNwbGF5TmFtZRI5
ChVkaXJlY3RvcnlfY3VzdG9tZXJfaWQYAyABKAlCA+BBBUgAUhNkaXJlY3RvcnlDdXN0b21l
cklkEk4KBXN0YXRlGAQgASgOMjMuZ29vZ2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5P
cmdhbml6YXRpb24uU3RhdGVCA+BBA1IFc3RhdGUSQAoLY3JlYXRlX3RpbWUYBSABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3Rp
bWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUS
QAoLZGVsZXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmRlbGV0ZVRpbWUSFwoEZXRhZxgIIAEoCUID4EEDUgRldGFnIkAKBVN0YXRlEhUKEVNUQVRF
X1VOU1BFQ0lGSUVEEAASCgoGQUNUSVZFEAESFAoQREVMRVRFX1JFUVVFU1RFRBACOlbqQVMK
MGNsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL09yZ2FuaXphdGlvbhIcb3Jn
YW5pemF0aW9ucy97b3JnYW5pemF0aW9ufVIBAUIHCgVvd25lciJmChZHZXRPcmdhbml6YXRp
b25SZXF1ZXN0EkwKBG5hbWUYASABKAlCOOBBAvpBMgowY2xvdWRyZXNvdXJjZW1hbmFnZXIu
Z29vZ2xlYXBpcy5jb20vT3JnYW5pemF0aW9uUgRuYW1lIn0KGlNlYXJjaE9yZ2FuaXphdGlv
bnNSZXF1ZXN0EiAKCXBhZ2Vfc2l6ZRgBIAEoBUID4EEBUghwYWdlU2l6ZRIiCgpwYWdlX3Rv
a2VuGAIgASgJQgPgQQFSCXBhZ2VUb2tlbhIZCgVxdWVyeRgDIAEoCUID4EEBUgVxdWVyeSKa
AQobU2VhcmNoT3JnYW5pemF0aW9uc1Jlc3BvbnNlElMKDW9yZ2FuaXphdGlvbnMYASADKAsy
LS5nb29nbGUuY2xvdWQucmVzb3VyY2VtYW5hZ2VyLnYzLk9yZ2FuaXphdGlvblINb3JnYW5p
emF0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iHAoaRGVs
ZXRlT3JnYW5pemF0aW9uTWV0YWRhdGEiHgocVW5kZWxldGVPcmdhbml6YXRpb25NZXRhZGF0
YTLlBwoNT3JnYW5pemF0aW9ucxKkAQoPR2V0T3JnYW5pemF0aW9uEjcuZ29vZ2xlLmNsb3Vk
LnJlc291cmNlbWFuYWdlci52My5HZXRPcmdhbml6YXRpb25SZXF1ZXN0Gi0uZ29vZ2xlLmNs
b3VkLnJlc291cmNlbWFuYWdlci52My5Pcmdhbml6YXRpb24iKYLT5JMCHBIaL3YzL3tuYW1l
PW9yZ2FuaXphdGlvbnMvKn3aQQRuYW1lEroBChNTZWFyY2hPcmdhbml6YXRpb25zEjsuZ29v
Z2xlLmNsb3VkLnJlc291cmNlbWFuYWdlci52My5TZWFyY2hPcmdhbml6YXRpb25zUmVxdWVz
dBo8Lmdvb2dsZS5jbG91ZC5yZXNvdXJjZW1hbmFnZXIudjMuU2VhcmNoT3JnYW5pemF0aW9u
c1Jlc3BvbnNlIiiC0+STAhoSGC92My9vcmdhbml6YXRpb25zOnNlYXJjaNpBBXF1ZXJ5EowB
CgxHZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGljeVJlcXVlc3QaFS5n
b29nbGUuaWFtLnYxLlBvbGljeSJBgtPkkwIwIisvdjMve3Jlc291cmNlPW9yZ2FuaXphdGlv
bnMvKn06Z2V0SWFtUG9saWN5OgEq2kEIcmVzb3VyY2USjAEKDFNldElhbVBvbGljeRIiLmdv
b2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5
IkGC0+STAjAiKy92My97cmVzb3VyY2U9b3JnYW5pemF0aW9ucy8qfTpzZXRJYW1Qb2xpY3k6
ASraQQhyZXNvdXJjZRK+AQoSVGVzdElhbVBlcm1pc3Npb25zEiguZ29vZ2xlLmlhbS52MS5U
ZXN0SWFtUGVybWlzc2lvbnNSZXF1ZXN0GikuZ29vZ2xlLmlhbS52MS5UZXN0SWFtUGVybWlz
c2lvbnNSZXNwb25zZSJTgtPkkwI2IjEvdjMve3Jlc291cmNlPW9yZ2FuaXphdGlvbnMvKn06
dGVzdElhbVBlcm1pc3Npb25zOgEq2kEUcmVzb3VyY2UscGVybWlzc2lvbnMakAHKQSNjbG91
ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbdJBZ2h0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybS5yZWFkLW9ubHlC8wEKI2NvbS5nb29nbGUuY2xvdWQucmVz
b3VyY2VtYW5hZ2VyLnYzQhJPcmdhbml6YXRpb25zUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNv
bS9nby9yZXNvdXJjZW1hbmFnZXIvYXBpdjMvcmVzb3VyY2VtYW5hZ2VycGI7cmVzb3VyY2Vt
YW5hZ2VycGKqAh9Hb29nbGUuQ2xvdWQuUmVzb3VyY2VNYW5hZ2VyLlYzygIfR29vZ2xlXENs
b3VkXFJlc291cmNlTWFuYWdlclxWM+oCIkdvb2dsZTo6Q2xvdWQ6OlJlc291cmNlTWFuYWdl
cjo6VjNKjUIKBxIFDgDwAScKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
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
CgECEgMQACgKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJ
CgIDBBIDFgAoCgkKAgMFEgMXACQKCQoCAwYSAxgAKQoICgEIEgMaADwKCQoCCCUSAxoAPAoI
CgEIEgMbAGQKCQoCCAsSAxsAZAoICgEIEgMcACIKCQoCCAoSAxwAIgoICgEIEgMdADMKCQoC
CAgSAx0AMwoICgEIEgMeADwKCQoCCAESAx4APAoICgEIEgMfADwKCQoCCCkSAx8APAoICgEI
EgMgADsKCQoCCC0SAyAAOwpCCgIGABIEIwBrARo2IEFsbG93cyB1c2VycyB0byBtYW5hZ2Ug
dGhlaXIgb3JnYW5pemF0aW9uIHJlc291cmNlcy4KCgoKAwYAARIDIwgVCgoKAwYAAxIDJAJL
CgwKBQYAA5kIEgMkAksKCwoDBgADEgQlAidBCg0KBQYAA5oIEgQlAidBClsKBAYAAgASBCoC
LwMaTSBGZXRjaGVzIGFuIG9yZ2FuaXphdGlvbiByZXNvdXJjZSBpZGVudGlmaWVkIGJ5IHRo
ZSBzcGVjaWZpZWQgcmVzb3VyY2UgbmFtZS4KCgwKBQYAAgABEgMqBhUKDAoFBgACAAISAyoW
LAoMCgUGAAIAAxIDKjdDCg0KBQYAAgAEEgQrBC0GChEKCQYAAgAEsMq8IhIEKwQtBgoMCgUG
AAIABBIDLgQyCg8KCAYAAgAEmwgAEgMuBDIKlQMKBAYAAgESBDgCPgMahgMgU2VhcmNoZXMg
b3JnYW5pemF0aW9uIHJlc291cmNlcyB0aGF0IGFyZSB2aXNpYmxlIHRvIHRoZSB1c2VyIGFu
ZCBzYXRpc2Z5CiB0aGUgc3BlY2lmaWVkIGZpbHRlci4gVGhpcyBtZXRob2QgcmV0dXJucyBv
cmdhbml6YXRpb25zIGluIGFuIHVuc3BlY2lmaWVkCiBvcmRlci4gTmV3IG9yZ2FuaXphdGlv
bnMgZG8gbm90IG5lY2Vzc2FyaWx5IGFwcGVhciBhdCB0aGUgZW5kIG9mIHRoZQogcmVzdWx0
cywgYW5kIG1heSB0YWtlIGEgc21hbGwgYW1vdW50IG9mIHRpbWUgdG8gYXBwZWFyLgoKIFNl
YXJjaCB3aWxsIG9ubHkgcmV0dXJuIG9yZ2FuaXphdGlvbnMgb24gd2hpY2ggdGhlIHVzZXIg
aGFzIHRoZSBwZXJtaXNzaW9uCiBgcmVzb3VyY2VtYW5hZ2VyLm9yZ2FuaXphdGlvbnMuZ2V0
YAoKDAoFBgACAQESAzgGGQoMCgUGAAIBAhIDOBo0CgwKBQYAAgEDEgM5DyoKDQoFBgACAQQS
BDoEPAYKEQoJBgACAQSwyrwiEgQ6BDwGCgwKBQYAAgEEEgM9BDMKDwoIBgACAQSbCAASAz0E
MwrpAgoEBgACAhIERgJNAxraAiBHZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9y
IGFuIG9yZ2FuaXphdGlvbiByZXNvdXJjZS4gVGhlIHBvbGljeSBtYXkKIGJlIGVtcHR5IGlm
IG5vIHN1Y2ggcG9saWN5IG9yIHJlc291cmNlIGV4aXN0cy4gVGhlIGByZXNvdXJjZWAgZmll
bGQgc2hvdWxkCiBiZSB0aGUgb3JnYW5pemF0aW9uJ3MgcmVzb3VyY2UgbmFtZSwgZm9yIGV4
YW1wbGU6ICJvcmdhbml6YXRpb25zLzEyMyIuCgogQXV0aG9yaXphdGlvbiByZXF1aXJlcyB0
aGUgSUFNIHBlcm1pc3Npb24KIGByZXNvdXJjZW1hbmFnZXIub3JnYW5pemF0aW9ucy5nZXRJ
YW1Qb2xpY3lgIG9uIHRoZSBzcGVjaWZpZWQgb3JnYW5pemF0aW9uLgoKDAoFBgACAgESA0YG
EgoMCgUGAAICAhIDRhM0CgwKBQYAAgIDEgNHDyMKDQoFBgACAgQSBEgESwYKEQoJBgACAgSw
yrwiEgRIBEsGCgwKBQYAAgIEEgNMBDYKDwoIBgACAgSbCAASA0wENgrIAgoEBgACAxIEVQJc
Axq5AiBTZXRzIHRoZSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgb24gYW4gb3JnYW5pemF0aW9u
IHJlc291cmNlLiBSZXBsYWNlcyBhbnkKIGV4aXN0aW5nIHBvbGljeS4gVGhlIGByZXNvdXJj
ZWAgZmllbGQgc2hvdWxkIGJlIHRoZSBvcmdhbml6YXRpb24ncyByZXNvdXJjZQogbmFtZSwg
Zm9yIGV4YW1wbGU6ICJvcmdhbml6YXRpb25zLzEyMyIuCgogQXV0aG9yaXphdGlvbiByZXF1
aXJlcyB0aGUgSUFNIHBlcm1pc3Npb24KIGByZXNvdXJjZW1hbmFnZXIub3JnYW5pemF0aW9u
cy5zZXRJYW1Qb2xpY3lgIG9uIHRoZSBzcGVjaWZpZWQgb3JnYW5pemF0aW9uLgoKDAoFBgAC
AwESA1UGEgoMCgUGAAIDAhIDVRM0CgwKBQYAAgMDEgNWDyMKDQoFBgACAwQSBFcEWgYKEQoJ
BgACAwSwyrwiEgRXBFoGCgwKBQYAAgMEEgNbBDYKDwoIBgACAwSbCAASA1sENgr8AQoEBgAC
BBIEYwJqAxrtASBSZXR1cm5zIHRoZSBwZXJtaXNzaW9ucyB0aGF0IGEgY2FsbGVyIGhhcyBv
biB0aGUgc3BlY2lmaWVkIG9yZ2FuaXphdGlvbi4KIFRoZSBgcmVzb3VyY2VgIGZpZWxkIHNo
b3VsZCBiZSB0aGUgb3JnYW5pemF0aW9uJ3MgcmVzb3VyY2UgbmFtZSwKIGZvciBleGFtcGxl
OiAib3JnYW5pemF0aW9ucy8xMjMiLgoKIFRoZXJlIGFyZSBubyBwZXJtaXNzaW9ucyByZXF1
aXJlZCBmb3IgbWFraW5nIHRoaXMgQVBJIGNhbGwuCgoMCgUGAAIEARIDYwYYCgwKBQYAAgQC
EgNjGUAKDAoFBgACBAMSA2QPNwoNCgUGAAIEBBIEZQRoBgoRCgkGAAIEBLDKvCISBGUEaAYK
DAoFBgACBAQSA2kEQgoPCggGAAIEBJsIABIDaQRCCoEBCgIEABIFbwCrAQEadCBUaGUgcm9v
dCBub2RlIGluIHRoZSByZXNvdXJjZSBoaWVyYXJjaHkgdG8gd2hpY2ggYSBwYXJ0aWN1bGFy
IGVudGl0eSdzCiAoYSBjb21wYW55LCBmb3IgZXhhbXBsZSkgcmVzb3VyY2VzIGJlbG9uZy4K
CgoKAwQAARIDbwgUCgsKAwQABxIEcAJ0BAoNCgUEAAedCBIEcAJ0BAovCgQEAAQAEgV3AoAB
AxogIE9yZ2FuaXphdGlvbiBsaWZlY3ljbGUgc3RhdGVzLgoKDAoFBAAEAAESA3cHDApZCgYE
AAQAAgASA3kEGhpKIFVuc3BlY2lmaWVkIHN0YXRlLiAgVGhpcyBpcyBvbmx5IHVzZWZ1bCBm
b3IgZGlzdGluZ3Vpc2hpbmcgdW5zZXQgdmFsdWVzLgoKDgoHBAAEAAIAARIDeQQVCg4KBwQA
BAACAAISA3kYGQotCgYEAAQAAgESA3wEDxoeIFRoZSBub3JtYWwgYW5kIGFjdGl2ZSBzdGF0
ZS4KCg4KBwQABAACAQESA3wECgoOCgcEAAQAAgECEgN8DQ4KSwoGBAAEAAICEgN/BBkaPCBU
aGUgb3JnYW5pemF0aW9uIGhhcyBiZWVuIG1hcmtlZCBmb3IgZGVsZXRpb24gYnkgdGhlIHVz
ZXIuCgoOCgcEAAQAAgIBEgN/BBQKDgoHBAAEAAICAhIDfxcYCs8BCgQEAAIAEgSFAQI+GsAB
IE91dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgb3JnYW5pemF0aW9uLiBU
aGlzIGlzIHRoZQogb3JnYW5pemF0aW9uJ3MgcmVsYXRpdmUgcGF0aCBpbiB0aGUgQVBJLiBJ
dHMgZm9ybWF0IGlzCiAib3JnYW5pemF0aW9ucy9bb3JnYW5pemF0aW9uX2lkXSIuIEZvciBl
eGFtcGxlLCAib3JnYW5pemF0aW9ucy8xMjM0Ii4KCg0KBQQAAgAFEgSFAQIICg0KBQQAAgAB
EgSFAQkNCg0KBQQAAgADEgSFARARCg0KBQQAAgAIEgSFARI9ChAKCAQAAgAInAgAEgSFARM8
CrMCCgQEAAIBEgSLAQJGGqQCIE91dHB1dCBvbmx5LiBBIGh1bWFuLXJlYWRhYmxlIHN0cmlu
ZyB0aGF0IHJlZmVycyB0byB0aGUgb3JnYW5pemF0aW9uIGluIHRoZQogR29vZ2xlIENsb3Vk
IENvbnNvbGUuIFRoaXMgc3RyaW5nIGlzIHNldCBieSB0aGUgc2VydmVyIGFuZCBjYW5ub3Qg
YmUKIGNoYW5nZWQuIFRoZSBzdHJpbmcgd2lsbCBiZSBzZXQgdG8gdGhlIHByaW1hcnkgZG9t
YWluIChmb3IgZXhhbXBsZSwKICJnb29nbGUuY29tIikgb2YgdGhlIEdvb2dsZSBXb3Jrc3Bh
Y2UgY3VzdG9tZXIgdGhhdCBvd25zIHRoZSBvcmdhbml6YXRpb24uCgoNCgUEAAIBBRIEiwEC
CAoNCgUEAAIBARIEiwEJFQoNCgUEAAIBAxIEiwEYGQoNCgUEAAIBCBIEiwEaRQoQCggEAAIB
CJwIABIEiwEbRAqpAgoEBAAIABIGkwEClgEDGpgCIFRoZSBvd25lciBvZiB0aGlzIG9yZ2Fu
aXphdGlvbi4gVGhlIG93bmVyIHNob3VsZCBiZSBzcGVjaWZpZWQgb24KIGNyZWF0aW9uLiBP
bmNlIHNldCwgaXQgY2Fubm90IGJlIGNoYW5nZWQuCgogVGhlIGxpZmV0aW1lIG9mIHRoZSBv
cmdhbml6YXRpb24gYW5kIGFsbCBvZiBpdHMgZGVzY2VuZGFudHMgYXJlIGJvdW5kIHRvCiB0
aGUgb3duZXIuIElmIHRoZSBvd25lciBpcyBkZWxldGVkLCB0aGUgb3JnYW5pemF0aW9uIGFu
ZCBhbGwgaXRzCiBkZXNjZW5kYW50cyB3aWxsIGJlIGRlbGV0ZWQuCgoNCgUEAAgAARIEkwEI
DQpZCgQEAAICEgSVAQRPGksgSW1tdXRhYmxlLiBUaGUgRyBTdWl0ZSAvIFdvcmtzcGFjZSBj
dXN0b21lciBpZCB1c2VkIGluIHRoZSBEaXJlY3RvcnkgQVBJLgoKDQoFBAACAgUSBJUBBAoK
DQoFBAACAgESBJUBCyAKDQoFBAACAgMSBJUBIyQKDQoFBAACAggSBJUBJU4KEAoIBAACAgic
CAASBJUBJk0KSAoEBAACAxIEmQECPho6IE91dHB1dCBvbmx5LiBUaGUgb3JnYW5pemF0aW9u
J3MgY3VycmVudCBsaWZlY3ljbGUgc3RhdGUuCgoNCgUEAAIDBhIEmQECBwoNCgUEAAIDARIE
mQEIDQoNCgUEAAIDAxIEmQEQEQoNCgUEAAIDCBIEmQESPQoQCggEAAIDCJwIABIEmQETPApL
CgQEAAIEEgacAQKdATIaOyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIE9yZ2Fu
aXphdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgQGEgScAQIbCg0KBQQAAgQBEgScARwnCg0K
BQQAAgQDEgScASorCg0KBQQAAgQIEgSdAQYxChAKCAQAAgQInAgAEgSdAQcwClEKBAQAAgUS
BqABAqEBMhpBIE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGUgT3JnYW5pemF0aW9u
IHdhcyBsYXN0IG1vZGlmaWVkLgoKDQoFBAACBQYSBKABAhsKDQoFBAACBQESBKABHCcKDQoF
BAACBQMSBKABKisKDQoFBAACBQgSBKEBBjEKEAoIBAACBQicCAASBKEBBzAKWgoEBAACBhIG
pAECpQEyGkogT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoZSBPcmdhbml6YXRpb24g
d2FzIHJlcXVlc3RlZCBmb3IgZGVsZXRpb24uCgoNCgUEAAIGBhIEpAECGwoNCgUEAAIGARIE
pAEcJwoNCgUEAAIGAxIEpAEqKwoNCgUEAAIGCBIEpQEGMQoQCggEAAIGCJwIABIEpQEHMArp
AQoEBAACBxIEqgECPhraASBPdXRwdXQgb25seS4gQSBjaGVja3N1bSBjb21wdXRlZCBieSB0
aGUgc2VydmVyIGJhc2VkIG9uIHRoZSBjdXJyZW50IHZhbHVlCiBvZiB0aGUgT3JnYW5pemF0
aW9uIHJlc291cmNlLiBUaGlzIG1heSBiZSBzZW50IG9uIHVwZGF0ZSBhbmQgZGVsZXRlCiBy
ZXF1ZXN0cyB0byBlbnN1cmUgdGhlIGNsaWVudCBoYXMgYW4gdXAtdG8tZGF0ZSB2YWx1ZSBi
ZWZvcmUgcHJvY2VlZGluZy4KCg0KBQQAAgcFEgSqAQIICg0KBQQAAgcBEgSqAQkNCg0KBQQA
AgcDEgSqARARCg0KBQQAAgcIEgSqARI9ChAKCAQAAgcInAgAEgSqARM8CokBCgIEARIGrwEA
uQEBGnsgVGhlIHJlcXVlc3Qgc2VudCB0byB0aGUgYEdldE9yZ2FuaXphdGlvbmAgbWV0aG9k
LiBUaGUgYG5hbWVgIGZpZWxkIGlzCiByZXF1aXJlZC4gYG9yZ2FuaXphdGlvbl9pZGAgaXMg
bm8gbG9uZ2VyIGFjY2VwdGVkLgoKCwoDBAEBEgSvAQgeCtUBCgQEAQIAEgazAQK4AQQaxAEg
UmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBPcmdhbml6YXRpb24gdG8gZmV0
Y2guIFRoaXMgaXMgdGhlCiBvcmdhbml6YXRpb24ncyByZWxhdGl2ZSBwYXRoIGluIHRoZSBB
UEksIGZvcm1hdHRlZCBhcwogIm9yZ2FuaXphdGlvbnMvW29yZ2FuaXphdGlvbklkXSIuIEZv
ciBleGFtcGxlLCAib3JnYW5pemF0aW9ucy8xMjM0Ii4KCg0KBQQBAgAFEgSzAQIICg0KBQQB
AgABEgSzAQkNCg0KBQQBAgADEgSzARARCg8KBQQBAgAIEgazARK4AQMKEAoIBAECAAicCAAS
BLQBBCoKEQoHBAECAAifCBIGtQEEtwEFCkUKAgQCEga8AQDaAQEaNyBUaGUgcmVxdWVzdCBz
ZW50IHRvIHRoZSBgU2VhcmNoT3JnYW5pemF0aW9uc2AgbWV0aG9kLgoKCwoDBAIBEgS8AQgi
CsoBCgQEAgIAEgTAAQI/GrsBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2Ygb3Jn
YW5pemF0aW9ucyB0byByZXR1cm4gaW4gdGhlIHJlc3BvbnNlLgogVGhlIHNlcnZlciBjYW4g
cmV0dXJuIGZld2VyIG9yZ2FuaXphdGlvbnMgdGhhbiByZXF1ZXN0ZWQuIElmIHVuc3BlY2lm
aWVkLAogc2VydmVyIHBpY2tzIGFuIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUEAgIABRIE
wAECBwoNCgUEAgIAARIEwAEIEQoNCgUEAgIAAxIEwAEUFQoNCgUEAgIACBIEwAEWPgoQCggE
AgIACJwIABIEwAEXPQqYAQoEBAICARIExAECQRqJASBPcHRpb25hbC4gQSBwYWdpbmF0aW9u
IHRva2VuIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBjYWxsIHRvCiBgU2VhcmNoT3JnYW5p
emF0aW9uc2AgdGhhdCBpbmRpY2F0ZXMgZnJvbSB3aGVyZSBsaXN0aW5nIHNob3VsZCBjb250
aW51ZS4KCg0KBQQCAgEFEgTEAQIICg0KBQQCAgEBEgTEAQkTCg0KBQQCAgEDEgTEARYXCg0K
BQQCAgEIEgTEARhAChAKCAQCAgEInAgAEgTEARk/CqYGCgQEAgICEgTZAQI8GpcGIE9wdGlv
bmFsLiBBbiBvcHRpb25hbCBxdWVyeSBzdHJpbmcgdXNlZCB0byBmaWx0ZXIgdGhlIE9yZ2Fu
aXphdGlvbnMgdG8KIHJldHVybiBpbiB0aGUgcmVzcG9uc2UuIFF1ZXJ5IHJ1bGVzIGFyZSBj
YXNlLWluc2Vuc2l0aXZlLgoKCiBgYGAKIHwgRmllbGQgICAgICAgICAgICB8IERlc2NyaXB0
aW9uICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB8CiB8LS0tLS0tLS0tLS0tLS0t
LS0tfC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tfAogfCBk
aXJlY3RvcnlDdXN0b21lcklkLCBvd25lci5kaXJlY3RvcnlDdXN0b21lcklkIHwgRmlsdGVy
cyBieSBkaXJlY3RvcnkKIGN1c3RvbWVyIGlkLiB8CiB8IGRvbWFpbiAgICAgICAgICAgfCBG
aWx0ZXJzIGJ5IGRvbWFpbi4gICAgICAgICAgICAgICAgICAgICAgICAgfAogYGBgCgogT3Jn
YW5pemF0aW9ucyBtYXkgYmUgcXVlcmllZCBieSBgZGlyZWN0b3J5Q3VzdG9tZXJJZGAgb3Ig
YnkKIGBkb21haW5gLCB3aGVyZSB0aGUgZG9tYWluIGlzIGEgRyBTdWl0ZSBkb21haW4sIGZv
ciBleGFtcGxlOgoKICogUXVlcnkgYGRpcmVjdG9yeWN1c3RvbWVyaWQ6MTIzNDU2Nzg5YCBy
ZXR1cm5zIE9yZ2FuaXphdGlvbgogcmVzb3VyY2VzIHdpdGggYG93bmVyLmRpcmVjdG9yeV9j
dXN0b21lcl9pZGAgZXF1YWwgdG8gYDEyMzQ1Njc4OWAuCiAqIFF1ZXJ5IGBkb21haW46Z29v
Z2xlLmNvbWAgcmV0dXJucyBPcmdhbml6YXRpb24gcmVzb3VyY2VzIGNvcnJlc3BvbmRpbmcK
IHRvIHRoZSBkb21haW4gYGdvb2dsZS5jb21gLgoKDQoFBAICAgUSBNkBAggKDQoFBAICAgES
BNkBCQ4KDQoFBAICAgMSBNkBERIKDQoFBAICAggSBNkBEzsKEAoIBAICAgicCAASBNkBFDoK
TAoCBAMSBt0BAOgBARo+IFRoZSByZXNwb25zZSByZXR1cm5lZCBmcm9tIHRoZSBgU2VhcmNo
T3JnYW5pemF0aW9uc2AgbWV0aG9kLgoKCwoDBAMBEgTdAQgjCl0KBAQDAgASBOABAioaTyBU
aGUgbGlzdCBvZiBPcmdhbml6YXRpb25zIHRoYXQgbWF0Y2hlZCB0aGUgc2VhcmNoIHF1ZXJ5
LCBwb3NzaWJseQogcGFnaW5hdGVkLgoKDQoFBAMCAAQSBOABAgoKDQoFBAMCAAYSBOABCxcK
DQoFBAMCAAESBOABGCUKDQoFBAMCAAMSBOABKCkK3AIKBAQDAgESBOcBAh0azQIgQSBwYWdp
bmF0aW9uIHRva2VuIHRvIGJlIHVzZWQgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiBy
ZXN1bHRzLiBJZiB0aGUKIHJlc3VsdCBpcyB0b28gbGFyZ2UgdG8gZml0IHdpdGhpbiB0aGUg
cGFnZSBzaXplIHNwZWNpZmllZCBpbiB0aGUgcmVxdWVzdCwKIHRoaXMgZmllbGQgd2lsbCBi
ZSBzZXQgd2l0aCBhIHRva2VuIHRoYXQgY2FuIGJlIHVzZWQgdG8gZmV0Y2ggdGhlIG5leHQg
cGFnZQogb2YgcmVzdWx0cy4gSWYgdGhpcyBmaWVsZCBpcyBlbXB0eSwgaXQgaW5kaWNhdGVz
IHRoYXQgdGhpcyByZXNwb25zZQogY29udGFpbnMgdGhlIGxhc3QgcGFnZSBvZiByZXN1bHRz
LgoKDQoFBAMCAQUSBOcBAggKDQoFBAMCAQESBOcBCRgKDQoFBAMCAQMSBOcBGxwKdgoCBAQS
BOwBACUaaiBBIHN0YXR1cyBvYmplY3Qgd2hpY2ggaXMgdXNlZCBhcyB0aGUgYG1ldGFkYXRh
YCBmaWVsZCBmb3IgdGhlIG9wZXJhdGlvbgogcmV0dXJuZWQgYnkgRGVsZXRlT3JnYW5pemF0
aW9uLgoKCwoDBAQBEgTsAQgiCngKAgQFEgTwAQAnGmwgQSBzdGF0dXMgb2JqZWN0IHdoaWNo
IGlzIHVzZWQgYXMgdGhlIGBtZXRhZGF0YWAgZmllbGQgZm9yIHRoZSBPcGVyYXRpb24KIHJl
dHVybmVkIGJ5IFVuZGVsZXRlT3JnYW5pemF0aW9uLgoKCwoDBAUBEgTwAQgkYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::Organization ===
    # Fields for Organization
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: directory_customer_id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.resourcemanager.v3.Organization.State)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

# Enum: Organization::State
our $Organization_STATE_UNSPECIFIED = 0;
our $Organization_ACTIVE = 1;
our $Organization_DELETE_REQUESTED = 2;

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest ===
    # Fields for GetOrganizationRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest ===
    # Fields for SearchOrganizationsRequest
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: query Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse ===
    # Fields for SearchOrganizationsResponse
    # Field: organizations Type: 11 (.google.cloud.resourcemanager.v3.Organization)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::DeleteOrganizationMetadata ===
    # Fields for DeleteOrganizationMetadata

# === Message: Google::Cloud::Resourcemanager::V3::Organizations::UndeleteOrganizationMetadata ===
    # Fields for UndeleteOrganizationMetadata

# === Service Client: Google::Cloud::Resourcemanager::V3::Organizations::OrganizationsClient ===
package Google::Cloud::Resourcemanager::V3::Organizations::OrganizationsClient;

=pod

=head2 Service Client: Google::Cloud::Resourcemanager::V3::Organizations::OrganizationsClient

Client stub representing the remote C<Organizations> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<resourcemanager.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'resourcemanager.googleapis.com:443' );

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

sub get_organization {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'GetOrganization',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::Organizations::Organization',
    });
}

sub search_organizations {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'SearchOrganizations',
        request        => $req,
        response_class => 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Resourcemanager::V3::Organizations - Compiled Protocol Buffers messages for google/cloud/resourcemanager/v3/organizations.proto

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3::Organizations;

    my $msg = Google::Cloud::Resourcemanager::V3::Organizations::Organization->new({
        name => $name,
        display_name => $display_name,
        directory_customer_id => $directory_customer_id,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Resourcemanager::V3::Organizations::Organization->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/resourcemanager/v3/organizations.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Resourcemanager::V3::Organizations::Organization

The root node in the resource hierarchy to which a particular entity's
(a company, for example) resources belong.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the organization. This is the
organization's relative path in the API. Its format is
"organizations/[organization_id]". For example, "organizations/1234".

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. A human-readable string that refers to the organization in the
Google Cloud Console. This string is set by the server and cannot be
changed. The string will be set to the primary domain (for example,
"google.com") of the Google Workspace customer that owns the organization.

=item * C<< $msg->directory_customer_id() >> / C<< $msg->directory_customer_id($value) >>

Type: C<String>

Immutable. The G Suite / Workspace customer id used in the Directory API.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Resourcemanager::V3::Organization::State>)

Output only. The organization's current lifecycle state.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Organization was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Organization was last modified.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the Organization was requested for deletion.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. A checksum computed by the server based on the current value
of the Organization resource. This may be sent on update and delete
requests to ensure the client has an up-to-date value before proceeding.

=back

=head3 Enum: Organization::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<DELETE_REQUESTED> => C<2>

=back

=head2 Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest

The request sent to the `GetOrganization` method. The `name` field is
required. `organization_id` is no longer accepted.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Organization to fetch. This is the
organization's relative path in the API, formatted as
"organizations/[organizationId]". For example, "organizations/1234".

=back

=head2 Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest

The request sent to the `SearchOrganizations` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of organizations to return in the response.
The server can return fewer organizations than requested. If unspecified,
server picks an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A pagination token returned from a previous call to
`SearchOrganizations` that indicates from where listing should continue.

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Optional. An optional query string used to filter the Organizations to
return in the response. Query rules are case-insensitive.


```
| Field            | Description                                |
|------------------|--------------------------------------------|
| directoryCustomerId, owner.directoryCustomerId | Filters by directory
customer id. |
| domain           | Filters by domain.                         |
```

Organizations may be queried by `directoryCustomerId` or by
`domain`, where the domain is a G Suite domain, for example:

* Query `directorycustomerid:123456789` returns Organization
resources with `owner.directory_customer_id` equal to `123456789`.
* Query `domain:google.com` returns Organization resources corresponding
to the domain `google.com`.

=back

=head2 Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse

The response returned from the `SearchOrganizations` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->organizations() >> / C<< $msg->organizations($value) >>

Type: C<Message> (L<Google::Cloud::Resourcemanager::V3::Organizations::Organization>)

The list of Organizations that matched the search query, possibly
paginated.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A pagination token to be used to retrieve the next page of results. If the
result is too large to fit within the page size specified in the request,
this field will be set with a token that can be used to fetch the next page
of results. If this field is empty, it indicates that this response
contains the last page of results.

=back

=head2 Google::Cloud::Resourcemanager::V3::Organizations::DeleteOrganizationMetadata

A status object which is used as the `metadata` field for the operation
returned by DeleteOrganization.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Resourcemanager::V3::Organizations::UndeleteOrganizationMetadata

A status object which is used as the `metadata` field for the Operation
returned by UndeleteOrganization.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Resourcemanager::V3::Organizations::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
