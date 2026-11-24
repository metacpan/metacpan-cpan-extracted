package Google::Cloud::Talent::V4::CompanyService;

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
    eval { require Google::Cloud::Talent::V4::Common };
    eval { require Google::Cloud::Talent::V4::Company };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2NvbXBhbnlfc2VydmljZS5wcm90bxIWZ29vZ2xl
LmNsb3VkLnRhbGVudC52NBocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xl
L2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC90YWxlbnQvdjQvY29tbW9u
LnByb3RvGiRnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2NvbXBhbnkucHJvdG8aG2dvb2dsZS9w
cm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8i
kgEKFENyZWF0ZUNvbXBhbnlSZXF1ZXN0EjoKBnBhcmVudBgBIAEoCUIi4EEC+kEcChpqb2Jz
Lmdvb2dsZWFwaXMuY29tL1RlbmFudFIGcGFyZW50Ej4KB2NvbXBhbnkYAiABKAsyHy5nb29n
bGUuY2xvdWQudGFsZW50LnY0LkNvbXBhbnlCA+BBAlIHY29tcGFueSJMChFHZXRDb21wYW55
UmVxdWVzdBI3CgRuYW1lGAEgASgJQiPgQQL6QR0KG2pvYnMuZ29vZ2xlYXBpcy5jb20vQ29t
cGFueVIEbmFtZSKTAQoUVXBkYXRlQ29tcGFueVJlcXVlc3QSPgoHY29tcGFueRgBIAEoCzIf
Lmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueUID4EECUgdjb21wYW55EjsKC3VwZGF0
ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1IKdXBkYXRlTWFzayJP
ChREZWxldGVDb21wYW55UmVxdWVzdBI3CgRuYW1lGAEgASgJQiPgQQL6QR0KG2pvYnMuZ29v
Z2xlYXBpcy5jb20vQ29tcGFueVIEbmFtZSK6AQoUTGlzdENvbXBhbmllc1JlcXVlc3QSOgoG
cGFyZW50GAEgASgJQiLgQQL6QRwKGmpvYnMuZ29vZ2xlYXBpcy5jb20vVGVuYW50UgZwYXJl
bnQSHQoKcGFnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEhsKCXBhZ2Vfc2l6ZRgDIAEoBVII
cGFnZVNpemUSKgoRcmVxdWlyZV9vcGVuX2pvYnMYBCABKAhSD3JlcXVpcmVPcGVuSm9icyLE
AQoVTGlzdENvbXBhbmllc1Jlc3BvbnNlEj0KCWNvbXBhbmllcxgBIAMoCzIfLmdvb2dsZS5j
bG91ZC50YWxlbnQudjQuQ29tcGFueVIJY29tcGFuaWVzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbhJECghtZXRhZGF0YRgDIAEoCzIoLmdvb2dsZS5jbG91ZC50
YWxlbnQudjQuUmVzcG9uc2VNZXRhZGF0YVIIbWV0YWRhdGEywwcKDkNvbXBhbnlTZXJ2aWNl
Eq0BCg1DcmVhdGVDb21wYW55EiwuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5DcmVhdGVDb21w
YW55UmVxdWVzdBofLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueSJNgtPkkwI2Iisv
djQve3BhcmVudD1wcm9qZWN0cy8qL3RlbmFudHMvKn0vY29tcGFuaWVzOgdjb21wYW552kEO
cGFyZW50LGNvbXBhbnkSlAEKCkdldENvbXBhbnkSKS5nb29nbGUuY2xvdWQudGFsZW50LnY0
LkdldENvbXBhbnlSZXF1ZXN0Gh8uZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Db21wYW55IjqC
0+STAi0SKy92NC97bmFtZT1wcm9qZWN0cy8qL3RlbmFudHMvKi9jb21wYW5pZXMvKn3aQQRu
YW1lEroBCg1VcGRhdGVDb21wYW55EiwuZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5VcGRhdGVD
b21wYW55UmVxdWVzdBofLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGFueSJagtPkkwI+
MjMvdjQve2NvbXBhbnkubmFtZT1wcm9qZWN0cy8qL3RlbmFudHMvKi9jb21wYW5pZXMvKn06
B2NvbXBhbnnaQRNjb21wYW55LHVwZGF0ZV9tYXNrEpEBCg1EZWxldGVDb21wYW55EiwuZ29v
Z2xlLmNsb3VkLnRhbGVudC52NC5EZWxldGVDb21wYW55UmVxdWVzdBoWLmdvb2dsZS5wcm90
b2J1Zi5FbXB0eSI6gtPkkwItKisvdjQve25hbWU9cHJvamVjdHMvKi90ZW5hbnRzLyovY29t
cGFuaWVzLyp92kEEbmFtZRKqAQoNTGlzdENvbXBhbmllcxIsLmdvb2dsZS5jbG91ZC50YWxl
bnQudjQuTGlzdENvbXBhbmllc1JlcXVlc3QaLS5nb29nbGUuY2xvdWQudGFsZW50LnY0Lkxp
c3RDb21wYW5pZXNSZXNwb25zZSI8gtPkkwItEisvdjQve3BhcmVudD1wcm9qZWN0cy8qL3Rl
bmFudHMvKn0vY29tcGFuaWVz2kEGcGFyZW50GmzKQRNqb2JzLmdvb2dsZWFwaXMuY29t0kFT
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczov
L3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2pvYnNCbQoaY29tLmdvb2dsZS5jbG91ZC50YWxl
bnQudjRCE0NvbXBhbnlTZXJ2aWNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby90YWxl
bnQvYXBpdjQvdGFsZW50cGI7dGFsZW50cGKiAgNDVFNKuSgKBxIFDgC3AQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAtCgkKAgMFEgMXAC4KCQoCAwYS
AxgAJQoJCgIDBxIDGQAqCggKAQgSAxsASQoJCgIICxIDGwBJCggKAQgSAxwAIgoJCgIIChID
HAAiCggKAQgSAx0ANAoJCgIICBIDHQA0CggKAQgSAx4AMwoJCgIIARIDHgAzCggKAQgSAx8A
IQoJCgIIJBIDHwAhClgKAgYAEgQiAFIBGkwgQSBzZXJ2aWNlIHRoYXQgaGFuZGxlcyBjb21w
YW55IG1hbmFnZW1lbnQsIGluY2x1ZGluZyBDUlVEIGFuZCBlbnVtZXJhdGlvbi4KCgoKAwYA
ARIDIggWCgoKAwYAAxIDIwI7CgwKBQYAA5kIEgMjAjsKCwoDBgADEgQkAiYtCg0KBQYAA5oI
EgQkAiYtCi0KBAYAAgASBCkCLwMaHyBDcmVhdGVzIGEgbmV3IGNvbXBhbnkgZW50aXR5LgoK
DAoFBgACAAESAykGEwoMCgUGAAIAAhIDKRQoCgwKBQYAAgADEgMpMzoKDQoFBgACAAQSBCoE
LQYKEQoJBgACAASwyrwiEgQqBC0GCgwKBQYAAgAEEgMuBDwKDwoIBgACAASbCAASAy4EPAos
CgQGAAIBEgQyAjcDGh4gUmV0cmlldmVzIHNwZWNpZmllZCBjb21wYW55LgoKDAoFBgACAQES
AzIGEAoMCgUGAAIBAhIDMhEiCgwKBQYAAgEDEgMyLTQKDQoFBgACAQQSBDMENQYKEQoJBgAC
AQSwyrwiEgQzBDUGCgwKBQYAAgEEEgM2BDIKDwoIBgACAQSbCAASAzYEMgoqCgQGAAICEgQ6
AkADGhwgVXBkYXRlcyBzcGVjaWZpZWQgY29tcGFueS4KCgwKBQYAAgIBEgM6BhMKDAoFBgAC
AgISAzoUKAoMCgUGAAICAxIDOjM6Cg0KBQYAAgIEEgQ7BD4GChEKCQYAAgIEsMq8IhIEOwQ+
BgoMCgUGAAICBBIDPwRBCg8KCAYAAgIEmwgAEgM/BEEKZQoEBgACAxIERAJJAxpXIERlbGV0
ZXMgc3BlY2lmaWVkIGNvbXBhbnkuCiBQcmVyZXF1aXNpdGU6IFRoZSBjb21wYW55IGhhcyBu
byBqb2JzIGFzc29jaWF0ZWQgd2l0aCBpdC4KCgwKBQYAAgMBEgNEBhMKDAoFBgACAwISA0QU
KAoMCgUGAAIDAxIDRDNICg0KBQYAAgMEEgRFBEcGChEKCQYAAgMEsMq8IhIERQRHBgoMCgUG
AAIDBBIDSAQyCg8KCAYAAgMEmwgAEgNIBDIKQAoEBgACBBIETAJRAxoyIExpc3RzIGFsbCBj
b21wYW5pZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBwcm9qZWN0LgoKDAoFBgACBAESA0wGEwoM
CgUGAAIEAhIDTBQoCgwKBQYAAgQDEgNMM0gKDQoFBgACBAQSBE0ETwYKEQoJBgACBASwyrwi
EgRNBE8GCgwKBQYAAgQEEgNQBDQKDwoIBgACBASbCAASA1AENAo2CgIEABIEVQBhARoqIFRo
ZSBSZXF1ZXN0IG9mIHRoZSBDcmVhdGVDb21wYW55IG1ldGhvZC4KCgoKAwQAARIDVQgcCsEB
CgQEAAIAEgRaAl0EGrIBIFJlcXVpcmVkLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSB0ZW5hbnQg
dW5kZXIgd2hpY2ggdGhlIGNvbXBhbnkgaXMgY3JlYXRlZC4KCiBUaGUgZm9ybWF0IGlzICJw
cm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97dGVuYW50X2lkfSIsIGZvciBleGFtcGxl
LAogInByb2plY3RzL2Zvby90ZW5hbnRzL2JhciIuCgoMCgUEAAIABRIDWgIICgwKBQQAAgAB
EgNaCQ8KDAoFBAACAAMSA1oSEwoNCgUEAAIACBIEWhRdAwoPCggEAAIACJwIABIDWwQqCg4K
BwQAAgAInwgSA1wETAozCgQEAAIBEgNgAj8aJiBSZXF1aXJlZC4gVGhlIGNvbXBhbnkgdG8g
YmUgY3JlYXRlZC4KCgwKBQQAAgEGEgNgAgkKDAoFBAACAQESA2AKEQoMCgUEAAIBAxIDYBQV
CgwKBQQAAgEIEgNgFj4KDwoIBAACAQicCAASA2AXPQo0CgIEARIEZABuARooIFJlcXVlc3Qg
Zm9yIGdldHRpbmcgYSBjb21wYW55IGJ5IG5hbWUuCgoKCgMEAQESA2QIGQrmAQoEBAECABIE
agJtBBrXASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGNvbXBhbnkgdG8g
YmUgcmV0cmlldmVkLgoKIFRoZSBmb3JtYXQgaXMKICJwcm9qZWN0cy97cHJvamVjdF9pZH0v
dGVuYW50cy97dGVuYW50X2lkfS9jb21wYW5pZXMve2NvbXBhbnlfaWR9IiwgZm9yCiBleGFt
cGxlLCAicHJvamVjdHMvYXBpLXRlc3QtcHJvamVjdC90ZW5hbnRzL2Zvby9jb21wYW5pZXMv
YmFyIi4KCgwKBQQBAgAFEgNqAggKDAoFBAECAAESA2oJDQoMCgUEAQIAAxIDahARCg0KBQQB
AgAIEgRqEm0DCg8KCAQBAgAInAgAEgNrBCoKDgoHBAECAAifCBIDbARNCjgKAgQCEgVxAIEB
ARorIFJlcXVlc3QgZm9yIHVwZGF0aW5nIGEgc3BlY2lmaWVkIGNvbXBhbnkuCgoKCgMEAgES
A3EIHApdCgQEAgIAEgN0Aj8aUCBSZXF1aXJlZC4gVGhlIGNvbXBhbnkgcmVzb3VyY2UgdG8g
cmVwbGFjZSB0aGUgY3VycmVudCByZXNvdXJjZSBpbiB0aGUKIHN5c3RlbS4KCgwKBQQCAgAG
EgN0AgkKDAoFBAICAAESA3QKEQoMCgUEAgIAAxIDdBQVCgwKBQQCAgAIEgN0Fj4KDwoIBAIC
AAicCAASA3QXPQrBAwoEBAICARIEgAECLBqyAyBTdHJvbmdseSByZWNvbW1lbmRlZCBmb3Ig
dGhlIGJlc3Qgc2VydmljZSBleHBlcmllbmNlLgoKIElmIFt1cGRhdGVfbWFza11bZ29vZ2xl
LmNsb3VkLnRhbGVudC52NC5VcGRhdGVDb21wYW55UmVxdWVzdC51cGRhdGVfbWFza10KIGlz
IHByb3ZpZGVkLCBvbmx5IHRoZSBzcGVjaWZpZWQgZmllbGRzIGluCiBbY29tcGFueV1bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NC5VcGRhdGVDb21wYW55UmVxdWVzdC5jb21wYW55XSBhcmUg
dXBkYXRlZC4KIE90aGVyd2lzZSBhbGwgdGhlIGZpZWxkcyBhcmUgdXBkYXRlZC4KCiBBIGZp
ZWxkIG1hc2sgdG8gc3BlY2lmeSB0aGUgY29tcGFueSBmaWVsZHMgdG8gYmUgdXBkYXRlZC4g
T25seQogdG9wIGxldmVsIGZpZWxkcyBvZiBbQ29tcGFueV1bZ29vZ2xlLmNsb3VkLnRhbGVu
dC52NC5Db21wYW55XSBhcmUKIHN1cHBvcnRlZC4KCg0KBQQCAgEGEgSAAQIbCg0KBQQCAgEB
EgSAARwnCg0KBQQCAgEDEgSAASorCiwKAgQDEgaEAQCOAQEaHiBSZXF1ZXN0IHRvIGRlbGV0
ZSBhIGNvbXBhbnkuCgoLCgMEAwESBIQBCBwK2QEKBAQDAgASBooBAo0BBBrIASBSZXF1aXJl
ZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGNvbXBhbnkgdG8gYmUgZGVsZXRlZC4KCiBU
aGUgZm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9p
ZH0vY29tcGFuaWVzL3tjb21wYW55X2lkfSIsIGZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zv
by90ZW5hbnRzL2Jhci9jb21wYW5pZXMvYmF6Ii4KCg0KBQQDAgAFEgSKAQIICg0KBQQDAgAB
EgSKAQkNCg0KBQQDAgADEgSKARARCg8KBQQDAgAIEgaKARKNAQMKEAoIBAMCAAicCAASBIsB
BCoKDwoHBAMCAAifCBIEjAEETQpHCgIEBBIGkQEAqgEBGjkgTGlzdCBjb21wYW5pZXMgZm9y
IHdoaWNoIHRoZSBjbGllbnQgaGFzIEFDTCB2aXNpYmlsaXR5LgoKCwoDBAQBEgSRAQgcCsMB
CgQEBAIAEgaWAQKZAQQasgEgUmVxdWlyZWQuIFJlc291cmNlIG5hbWUgb2YgdGhlIHRlbmFu
dCB1bmRlciB3aGljaCB0aGUgY29tcGFueSBpcyBjcmVhdGVkLgoKIFRoZSBmb3JtYXQgaXMg
InByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5hbnRfaWR9IiwgZm9yIGV4YW1w
bGUsCiAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyIi4KCg0KBQQEAgAFEgSWAQIICg0KBQQE
AgABEgSWAQkPCg0KBQQEAgADEgSWARITCg8KBQQEAgAIEgaWARSZAQMKEAoIBAQCAAicCAAS
BJcBBCoKDwoHBAQCAAifCBIEmAEETApECgQEBAIBEgScAQIYGjYgVGhlIHN0YXJ0aW5nIGlu
ZGljYXRvciBmcm9tIHdoaWNoIHRvIHJldHVybiByZXN1bHRzLgoKDQoFBAQCAQUSBJwBAggK
DQoFBAQCAQESBJwBCRMKDQoFBAQCAQMSBJwBFhcKggEKBAQEAgISBKABAhYadCBUaGUgbWF4
aW11bSBudW1iZXIgb2YgY29tcGFuaWVzIHRvIGJlIHJldHVybmVkLCBhdCBtb3N0IDEwMC4K
IERlZmF1bHQgaXMgMTAwIGlmIGEgbm9uLXBvc2l0aXZlIG51bWJlciBpcyBwcm92aWRlZC4K
Cg0KBQQEAgIFEgSgAQIHCg0KBQQEAgIBEgSgAQgRCg0KBQQEAgIDEgSgARQVCocCCgQEBAID
EgSpAQIdGvgBIFNldCB0byB0cnVlIGlmIHRoZSBjb21wYW5pZXMgcmVxdWVzdGVkIG11c3Qg
aGF2ZSBvcGVuIGpvYnMuCgogRGVmYXVsdHMgdG8gZmFsc2UuCgogSWYgdHJ1ZSwgYXQgbW9z
dAogW3BhZ2Vfc2l6ZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5MaXN0Q29tcGFuaWVzUmVx
dWVzdC5wYWdlX3NpemVdIG9mCiBjb21wYW5pZXMgYXJlIGZldGNoZWQsIGFtb25nIHdoaWNo
IG9ubHkgdGhvc2Ugd2l0aCBvcGVuIGpvYnMgYXJlIHJldHVybmVkLgoKDQoFBAQCAwUSBKkB
AgYKDQoFBAQCAwESBKkBBxgKDQoFBAQCAwMSBKkBGxwKMwoCBAUSBq0BALcBARolIFRoZSBM
aXN0IGNvbXBhbmllcyByZXNwb25zZSBvYmplY3QuCgoLCgMEBQESBK0BCB0KMQoEBAUCABIE
rwECIRojIENvbXBhbmllcyBmb3IgdGhlIGN1cnJlbnQgY2xpZW50LgoKDQoFBAUCAAQSBK8B
AgoKDQoFBAUCAAYSBK8BCxIKDQoFBAUCAAESBK8BExwKDQoFBAUCAAMSBK8BHyAKPQoEBAUC
ARIEsgECHRovIEEgdG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRz
LgoKDQoFBAUCAQUSBLIBAggKDQoFBAUCAQESBLIBCRgKDQoFBAUCAQMSBLIBGxwKYAoEBAUC
AhIEtgECIBpSIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gZm9yIHRoZSBBUEkgaW52b2NhdGlv
biwgc3VjaCBhcyB0aGUgcmVxdWVzdAogdHJhY2tpbmcgaWQuCgoNCgUEBQICBhIEtgECEgoN
CgUEBQICARIEtgETGwoNCgUEBQICAxIEtgEeH2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::CompanyService::CreateCompanyRequest ===
    # Fields for CreateCompanyRequest
    # Field: parent Type: 9 ()
    # Field: company Type: 11 (.google.cloud.talent.v4.Company)

# === Message: Google::Cloud::Talent::V4::CompanyService::GetCompanyRequest ===
    # Fields for GetCompanyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4::CompanyService::UpdateCompanyRequest ===
    # Fields for UpdateCompanyRequest
    # Field: company Type: 11 (.google.cloud.talent.v4.Company)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Talent::V4::CompanyService::DeleteCompanyRequest ===
    # Fields for DeleteCompanyRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Talent::V4::CompanyService::ListCompaniesRequest ===
    # Fields for ListCompaniesRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: require_open_jobs Type: 8 ()

# === Message: Google::Cloud::Talent::V4::CompanyService::ListCompaniesResponse ===
    # Fields for ListCompaniesResponse
    # Field: companies Type: 11 (.google.cloud.talent.v4.Company)
    # Field: next_page_token Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.talent.v4.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4::CompanyService::CompanyServiceClient ===
package Google::Cloud::Talent::V4::CompanyService::CompanyServiceClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4::CompanyService::CompanyServiceClient

Client stub representing the remote C<CompanyService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<talent.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'talent.googleapis.com:443' );

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

sub create_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompanyService::CreateCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.CompanyService',
        method         => 'CreateCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Company::Company',
    });
}

sub get_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompanyService::GetCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.CompanyService',
        method         => 'GetCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Company::Company',
    });
}

sub update_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompanyService::UpdateCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.CompanyService',
        method         => 'UpdateCompany',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::Company::Company',
    });
}

sub delete_company {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompanyService::DeleteCompanyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.CompanyService',
        method         => 'DeleteCompany',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_companies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompanyService::ListCompaniesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.CompanyService',
        method         => 'ListCompanies',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::CompanyService::ListCompaniesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::CompanyService - Compiled Protocol Buffers messages for google/cloud/talent/v4/company_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::CompanyService;

    my $msg = Google::Cloud::Talent::V4::CompanyService::CreateCompanyRequest->new({
        parent => $parent,
        company => $company,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::CompanyService::CreateCompanyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/company_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::CompanyService::CreateCompanyRequest

The Request of the CreateCompany method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the company is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Company::Company>)

Required. The company to be created.

=back

=head2 Google::Cloud::Talent::V4::CompanyService::GetCompanyRequest

Request for getting a company by name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the company to be retrieved.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/api-test-project/tenants/foo/companies/bar".

=back

=head2 Google::Cloud::Talent::V4::CompanyService::UpdateCompanyRequest

Request for updating a specified company.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Company::Company>)

Required. The company resource to replace the current resource in the
system.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Strongly recommended for the best service experience.

If [update_mask][google.cloud.talent.v4.UpdateCompanyRequest.update_mask]
is provided, only the specified fields in
[company][google.cloud.talent.v4.UpdateCompanyRequest.company] are updated.
Otherwise all the fields are updated.

A field mask to specify the company fields to be updated. Only
top level fields of [Company][google.cloud.talent.v4.Company] are
supported.

=back

=head2 Google::Cloud::Talent::V4::CompanyService::DeleteCompanyRequest

Request to delete a company.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the company to be deleted.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/foo/tenants/bar/companies/baz".

=back

=head2 Google::Cloud::Talent::V4::CompanyService::ListCompaniesRequest

List companies for which the client has ACL visibility.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Resource name of the tenant under which the company is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The starting indicator from which to return results.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of companies to be returned, at most 100.
Default is 100 if a non-positive number is provided.

=item * C<< $msg->require_open_jobs() >> / C<< $msg->require_open_jobs($value) >>

Type: C<Bool>

Set to true if the companies requested must have open jobs.

Defaults to false.

If true, at most
[page_size][google.cloud.talent.v4.ListCompaniesRequest.page_size] of
companies are fetched, among which only those with open jobs are returned.

=back

=head2 Google::Cloud::Talent::V4::CompanyService::ListCompaniesResponse

The List companies response object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->companies() >> / C<< $msg->companies($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Company::Company>)

Companies for the current client.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::CompanyService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
