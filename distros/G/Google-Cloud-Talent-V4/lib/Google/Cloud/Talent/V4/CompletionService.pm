package Google::Cloud::Talent::V4::CompletionService;

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
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvdGFsZW50L3Y0L2NvbXBsZXRpb25fc2VydmljZS5wcm90bxIWZ29v
Z2xlLmNsb3VkLnRhbGVudC52NBocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
GWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC90YWxlbnQvdjQvY29t
bW9uLnByb3RvIsYEChRDb21wbGV0ZVF1ZXJ5UmVxdWVzdBI6CgZ0ZW5hbnQYASABKAlCIuBB
AvpBHAoaam9icy5nb29nbGVhcGlzLmNvbS9UZW5hbnRSBnRlbmFudBIZCgVxdWVyeRgCIAEo
CUID4EECUgVxdWVyeRIlCg5sYW5ndWFnZV9jb2RlcxgDIAMoCVINbGFuZ3VhZ2VDb2RlcxIg
CglwYWdlX3NpemUYBCABKAVCA+BBAlIIcGFnZVNpemUSOgoHY29tcGFueRgFIAEoCUIg+kEd
Chtqb2JzLmdvb2dsZWFwaXMuY29tL0NvbXBhbnlSB2NvbXBhbnkSUgoFc2NvcGUYBiABKA4y
PC5nb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBsZXRlUXVlcnlSZXF1ZXN0LkNvbXBsZXRp
b25TY29wZVIFc2NvcGUSTwoEdHlwZRgHIAEoDjI7Lmdvb2dsZS5jbG91ZC50YWxlbnQudjQu
Q29tcGxldGVRdWVyeVJlcXVlc3QuQ29tcGxldGlvblR5cGVSBHR5cGUiSwoPQ29tcGxldGlv
blNjb3BlEiAKHENPTVBMRVRJT05fU0NPUEVfVU5TUEVDSUZJRUQQABIKCgZURU5BTlQQARIK
CgZQVUJMSUMQAiJgCg5Db21wbGV0aW9uVHlwZRIfChtDT01QTEVUSU9OX1RZUEVfVU5TUEVD
SUZJRUQQABINCglKT0JfVElUTEUQARIQCgxDT01QQU5ZX05BTUUQAhIMCghDT01CSU5FRBAD
Iu8CChVDb21wbGV0ZVF1ZXJ5UmVzcG9uc2USbQoSY29tcGxldGlvbl9yZXN1bHRzGAEgAygL
Mj4uZ29vZ2xlLmNsb3VkLnRhbGVudC52NC5Db21wbGV0ZVF1ZXJ5UmVzcG9uc2UuQ29tcGxl
dGlvblJlc3VsdFIRY29tcGxldGlvblJlc3VsdHMSRAoIbWV0YWRhdGEYAiABKAsyKC5nb29n
bGUuY2xvdWQudGFsZW50LnY0LlJlc3BvbnNlTWV0YWRhdGFSCG1ldGFkYXRhGqABChBDb21w
bGV0aW9uUmVzdWx0Eh4KCnN1Z2dlc3Rpb24YASABKAlSCnN1Z2dlc3Rpb24STwoEdHlwZRgC
IAEoDjI7Lmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QuQ29t
cGxldGlvblR5cGVSBHR5cGUSGwoJaW1hZ2VfdXJpGAMgASgJUghpbWFnZVVyaTKiAgoKQ29t
cGxldGlvbhKlAQoNQ29tcGxldGVRdWVyeRIsLmdvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29t
cGxldGVRdWVyeVJlcXVlc3QaLS5nb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBsZXRlUXVl
cnlSZXNwb25zZSI3gtPkkwIxEi8vdjQve3RlbmFudD1wcm9qZWN0cy8qL3RlbmFudHMvKn06
Y29tcGxldGVRdWVyeRpsykETam9icy5nb29nbGVhcGlzLmNvbdJBU2h0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9qb2JzQnAKGmNvbS5nb29nbGUuY2xvdWQudGFsZW50LnY0QhZDb21wbGV0
aW9uU2VydmljZVByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vdGFsZW50L2FwaXY0L3Rh
bGVudHBiO3RhbGVudHBiogIDQ1RTSoopCgcSBQ4AogEBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhID
FAApCgkKAgMDEgMVACMKCQoCAwQSAxYALQoICgEIEgMYAEkKCQoCCAsSAxgASQoICgEIEgMZ
ACIKCQoCCAoSAxkAIgoICgEIEgMaADcKCQoCCAgSAxoANwoICgEIEgMbADMKCQoCCAESAxsA
MwoICgEIEgMcACEKCQoCCCQSAxwAIQowCgIGABIEHwAsARokIEEgc2VydmljZSBoYW5kbGVz
IGF1dG8gY29tcGxldGlvbi4KCgoKAwYAARIDHwgSCgoKAwYAAxIDIAI7CgwKBQYAA5kIEgMg
AjsKCwoDBgADEgQhAiMtCg0KBQYAA5oIEgQhAiMtCoQBCgQGAAIAEgQnAisDGnYgQ29tcGxl
dGVzIHRoZSBzcGVjaWZpZWQgcHJlZml4IHdpdGgga2V5d29yZCBzdWdnZXN0aW9ucy4KIElu
dGVuZGVkIGZvciB1c2UgYnkgYSBqb2Igc2VhcmNoIGF1dG8tY29tcGxldGUgc2VhcmNoIGJv
eC4KCgwKBQYAAgABEgMnBhMKDAoFBgACAAISAycUKAoMCgUGAAIAAxIDJzNICg0KBQYAAgAE
EgQoBCoGChEKCQYAAgAEsMq8IhIEKAQqBgooCgIEABIFLwCLAQEaGyBBdXRvLWNvbXBsZXRl
IHBhcmFtZXRlcnMuCgoKCgMEAAESAy8IHAo4CgQEAAQAEgQxAjsDGiogRW51bSB0byBzcGVj
aWZ5IHRoZSBzY29wZSBvZiBjb21wbGV0aW9uLgoKDAoFBAAEAAESAzEHFgofCgYEAAQAAgAS
AzMEJRoQIERlZmF1bHQgdmFsdWUuCgoOCgcEAAQAAgABEgMzBCAKDgoHBAAEAAIAAhIDMyMk
Ck8KBgQABAACARIDNgQPGkAgU3VnZ2VzdGlvbnMgYXJlIGJhc2VkIG9ubHkgb24gdGhlIGRh
dGEgcHJvdmlkZWQgYnkgdGhlIGNsaWVudC4KCg4KBwQABAACAQESAzYECgoOCgcEAAQAAgEC
EgM2DQ4KYwoGBAAEAAICEgM6BA8aVCBTdWdnZXN0aW9ucyBhcmUgYmFzZWQgb24gYWxsIGpv
YnMgZGF0YSBpbiB0aGUgc3lzdGVtIHRoYXQncyB2aXNpYmxlIHRvCiB0aGUgY2xpZW50CgoO
CgcEAAQAAgIBEgM6BAoKDgoHBAAEAAICAhIDOg0OCjcKBAQABAESBD4CXgMaKSBFbnVtIHRv
IHNwZWNpZnkgYXV0by1jb21wbGV0aW9uIHRvcGljcy4KCgwKBQQABAEBEgM+BxUKHwoGBAAE
AQIAEgNABCQaECBEZWZhdWx0IHZhbHVlLgoKDgoHBAAEAQIAARIDQAQfCg4KBwQABAECAAIS
A0AiIwqkAgoGBAAEAQIBEgNJBBIalAIgU3VnZ2VzdCBqb2IgdGl0bGVzIGZvciBqb2JzIGF1
dG9jb21wbGV0ZS4KCiBGb3IKIFtDb21wbGV0aW9uVHlwZS5KT0JfVElUTEVdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QuQ29tcGxldGlvblR5cGUuSk9C
X1RJVExFXQogdHlwZSwgb25seSBvcGVuIGpvYnMgd2l0aCB0aGUgc2FtZQogW2xhbmd1YWdl
X2NvZGVzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkNvbXBsZXRlUXVlcnlSZXF1ZXN0Lmxh
bmd1YWdlX2NvZGVzXQogYXJlIHJldHVybmVkLgoKDgoHBAAEAQIBARIDSQQNCg4KBwQABAEC
AQISA0kQEQq+AgoGBAAEAQICEgNSBBUargIgU3VnZ2VzdCBjb21wYW55IG5hbWVzIGZvciBq
b2JzIGF1dG9jb21wbGV0ZS4KCiBGb3IKIFtDb21wbGV0aW9uVHlwZS5DT01QQU5ZX05BTUVd
W2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QuQ29tcGxldGlv
blR5cGUuQ09NUEFOWV9OQU1FXQogdHlwZSwgb25seSBjb21wYW5pZXMgaGF2aW5nIG9wZW4g
am9icyB3aXRoIHRoZSBzYW1lCiBbbGFuZ3VhZ2VfY29kZXNdW2dvb2dsZS5jbG91ZC50YWxl
bnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QubGFuZ3VhZ2VfY29kZXNdCiBhcmUgcmV0dXJu
ZWQuCgoOCgcEAAQBAgIBEgNSBBAKDgoHBAAEAQICAhIDUhMUCrQDCgYEAAQBAgMSA10EERqk
AyBTdWdnZXN0IGJvdGggam9iIHRpdGxlcyBhbmQgY29tcGFueSBuYW1lcyBmb3Igam9icyBh
dXRvY29tcGxldGUuCgogRm9yCiBbQ29tcGxldGlvblR5cGUuQ09NQklORURdW2dvb2dsZS5j
bG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QuQ29tcGxldGlvblR5cGUuQ09N
QklORURdCiB0eXBlLCBvbmx5IG9wZW4gam9icyB3aXRoIHRoZSBzYW1lCiBbbGFuZ3VhZ2Vf
Y29kZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJlcXVlc3QubGFu
Z3VhZ2VfY29kZXNdCiBvciBjb21wYW5pZXMgaGF2aW5nIG9wZW4gam9icyB3aXRoIHRoZSBz
YW1lCiBbbGFuZ3VhZ2VfY29kZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGxldGVR
dWVyeVJlcXVlc3QubGFuZ3VhZ2VfY29kZXNdCiBhcmUgcmV0dXJuZWQuCgoOCgcEAAQBAgMB
EgNdBAwKDgoHBAAEAQIDAhIDXQ8QCr0BCgQEAAIAEgRkAmcEGq4BIFJlcXVpcmVkLiBSZXNv
dXJjZSBuYW1lIG9mIHRlbmFudCB0aGUgY29tcGxldGlvbiBpcyBwZXJmb3JtZWQgd2l0aGlu
LgoKIFRoZSBmb3JtYXQgaXMgInByb2plY3RzL3twcm9qZWN0X2lkfS90ZW5hbnRzL3t0ZW5h
bnRfaWR9IiwgZm9yIGV4YW1wbGUsCiAicHJvamVjdHMvZm9vL3RlbmFudHMvYmFyIi4KCgwK
BQQAAgAFEgNkAggKDAoFBAACAAESA2QJDwoMCgUEAAIAAxIDZBITCg0KBQQAAgAIEgRkFGcD
Cg8KCAQAAgAInAgAEgNlBCoKDgoHBAACAAifCBIDZgRMCnMKBAQAAgESA2wCPBpmIFJlcXVp
cmVkLiBUaGUgcXVlcnkgdXNlZCB0byBnZW5lcmF0ZSBzdWdnZXN0aW9ucy4KCiBUaGUgbWF4
aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCgwKBQQAAgEFEgNs
AggKDAoFBAACAQESA2wJDgoMCgUEAAIBAxIDbBESCgwKBQQAAgEIEgNsEzsKDwoIBAACAQic
CAASA2wUOgqIAgoEBAACAhIDdAIlGvoBIFRoZSBsaXN0IG9mIGxhbmd1YWdlcyBvZiB0aGUg
cXVlcnkuIFRoaXMgaXMKIHRoZSBCQ1AtNDcgbGFuZ3VhZ2UgY29kZSwgc3VjaCBhcyAiZW4t
VVMiIG9yICJzci1MYXRuIi4KIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUKIFtUYWdzIGZv
ciBJZGVudGlmeWluZyBMYW5ndWFnZXNdKGh0dHBzOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9i
Y3A0NykuCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBpcyAy
NTUuCgoMCgUEAAICBBIDdAIKCgwKBQQAAgIFEgN0CxEKDAoFBAACAgESA3QSIAoMCgUEAAIC
AxIDdCMkClgKBAQAAgMSA3kCPxpLIFJlcXVpcmVkLiBDb21wbGV0aW9uIHJlc3VsdCBjb3Vu
dC4KCiBUaGUgbWF4aW11bSBhbGxvd2VkIHBhZ2Ugc2l6ZSBpcyAxMC4KCgwKBQQAAgMFEgN5
AgcKDAoFBAACAwESA3kIEQoMCgUEAAIDAxIDeRQVCgwKBQQAAgMIEgN5Fj4KDwoIBAACAwic
CAASA3kXPQrXAQoEBAACBBIGgAECggEEGsYBIElmIHByb3ZpZGVkLCByZXN0cmljdHMgY29t
cGxldGlvbiB0byBzcGVjaWZpZWQgY29tcGFueS4KCiBUaGUgZm9ybWF0IGlzCiAicHJvamVj
dHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9pZH0vY29tcGFuaWVzL3tjb21wYW55
X2lkfSIsIGZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zvby90ZW5hbnRzL2Jhci9jb21wYW5p
ZXMvYmF6Ii4KCg0KBQQAAgQFEgSAAQIICg0KBQQAAgQBEgSAAQkQCg0KBQQAAgQDEgSAARMU
Cg8KBQQAAgQIEgaAARWCAQMKDwoHBAACBAifCBIEgQEETQqcAQoEBAACBRIEhgECHBqNASBU
aGUgc2NvcGUgb2YgdGhlIGNvbXBsZXRpb24uIFRoZSBkZWZhdWx0cyBpcwogW0NvbXBsZXRp
b25TY29wZS5QVUJMSUNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjQuQ29tcGxldGVRdWVyeVJl
cXVlc3QuQ29tcGxldGlvblNjb3BlLlBVQkxJQ10uCgoNCgUEAAIFBhIEhgECEQoNCgUEAAIF
ARIEhgESFwoNCgUEAAIFAxIEhgEaGwqWAQoEBAACBhIEigECGhqHASBUaGUgY29tcGxldGlv
biB0b3BpYy4gVGhlIGRlZmF1bHQgaXMKIFtDb21wbGV0aW9uVHlwZS5DT01CSU5FRF1bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NC5Db21wbGV0ZVF1ZXJ5UmVxdWVzdC5Db21wbGV0aW9uVHlw
ZS5DT01CSU5FRF0uCgoNCgUEAAIGBhIEigECEAoNCgUEAAIGARIEigERFQoNCgUEAAIGAxIE
igEYGQowCgIEARIGjgEAogEBGiIgUmVzcG9uc2Ugb2YgYXV0by1jb21wbGV0ZSBxdWVyeS4K
CgsKAwQBARIEjgEIHQo+CgQEAQMAEgaQAQKaAQMaLiBSZXNvdXJjZSB0aGF0IHJlcHJlc2Vu
dHMgY29tcGxldGlvbiByZXN1bHRzLgoKDQoFBAEDAAESBJABChoKLwoGBAEDAAIAEgSSAQQa
Gh8gVGhlIHN1Z2dlc3Rpb24gZm9yIHRoZSBxdWVyeS4KCg8KBwQBAwACAAUSBJIBBAoKDwoH
BAEDAAIAARIEkgELFQoPCgcEAQMAAgADEgSSARgZCicKBgQBAwACARIElQEEMRoXIFRoZSBj
b21wbGV0aW9uIHRvcGljLgoKDwoHBAEDAAIBBhIElQEEJwoPCgcEAQMAAgEBEgSVASgsCg8K
BwQBAwACAQMSBJUBLzAKjAEKBgQBAwACAhIEmQEEGRp8IFRoZSBVUkkgb2YgdGhlIGNvbXBh
bnkgaW1hZ2UgZm9yCiBbQ09NUEFOWV9OQU1FXVtnb29nbGUuY2xvdWQudGFsZW50LnY0LkNv
bXBsZXRlUXVlcnlSZXF1ZXN0LkNvbXBsZXRpb25UeXBlLkNPTVBBTllfTkFNRV0uCgoPCgcE
AQMAAgIFEgSZAQQKCg8KBwQBAwACAgESBJkBCxQKDwoHBAEDAAICAxIEmQEXGAo/CgQEAQIA
EgSdAQIzGjEgUmVzdWx0cyBvZiB0aGUgbWF0Y2hpbmcgam9iL2NvbXBhbnkgY2FuZGlkYXRl
cy4KCg0KBQQBAgAEEgSdAQIKCg0KBQQBAgAGEgSdAQsbCg0KBQQBAgABEgSdARwuCg0KBQQB
AgADEgSdATEyCmAKBAQBAgESBKEBAiAaUiBBZGRpdGlvbmFsIGluZm9ybWF0aW9uIGZvciB0
aGUgQVBJIGludm9jYXRpb24sIHN1Y2ggYXMgdGhlIHJlcXVlc3QKIHRyYWNraW5nIGlkLgoK
DQoFBAECAQYSBKEBAhIKDQoFBAECAQESBKEBExsKDQoFBAECAQMSBKEBHh9iBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::CompletionService::CompleteQueryRequest ===
    # Fields for CompleteQueryRequest
    # Field: tenant Type: 9 ()
    # Field: query Type: 9 ()
    # Field: language_codes Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: company Type: 9 ()
    # Field: scope Type: 14 (.google.cloud.talent.v4.CompleteQueryRequest.CompletionScope)
    # Field: type Type: 14 (.google.cloud.talent.v4.CompleteQueryRequest.CompletionType)

# Enum: CompleteQueryRequest::CompletionScope
our $CompleteQueryRequest_COMPLETION_SCOPE_UNSPECIFIED = 0;
our $CompleteQueryRequest_TENANT = 1;
our $CompleteQueryRequest_PUBLIC = 2;

# Enum: CompleteQueryRequest::CompletionType
our $CompleteQueryRequest_COMPLETION_TYPE_UNSPECIFIED = 0;
our $CompleteQueryRequest_JOB_TITLE = 1;
our $CompleteQueryRequest_COMPANY_NAME = 2;
our $CompleteQueryRequest_COMBINED = 3;

# === Message: Google::Cloud::Talent::V4::CompletionService::CompleteQueryResponse ===
    # Fields for CompleteQueryResponse
    # Field: completion_results Type: 11 (.google.cloud.talent.v4.CompleteQueryResponse.CompletionResult)
    # Field: metadata Type: 11 (.google.cloud.talent.v4.ResponseMetadata)

# === Service Client: Google::Cloud::Talent::V4::CompletionService::CompletionClient ===
package Google::Cloud::Talent::V4::CompletionService::CompletionClient;

=pod

=head2 Service Client: Google::Cloud::Talent::V4::CompletionService::CompletionClient

Client stub representing the remote C<Completion> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub complete_query {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Talent::V4::CompletionService::CompleteQueryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.talent.v4.Completion',
        method         => 'CompleteQuery',
        request        => $req,
        response_class => 'Google::Cloud::Talent::V4::CompletionService::CompleteQueryResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::CompletionService - Compiled Protocol Buffers messages for google/cloud/talent/v4/completion_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::CompletionService;

    my $msg = Google::Cloud::Talent::V4::CompletionService::CompleteQueryRequest->new({
        tenant => $tenant,
        query => $query,
        language_codes => $language_codes,
        page_size => $page_size,
    });

    # Read or update a field
    my $val = $msg->tenant();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::CompletionService::CompleteQueryRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/completion_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::CompletionService::CompleteQueryRequest

Auto-complete parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tenant() >> / C<< $msg->tenant($value) >>

Type: C<String>

Required. Resource name of tenant the completion is performed within.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=item * C<< $msg->query() >> / C<< $msg->query($value) >>

Type: C<String>

Required. The query used to generate suggestions.

The maximum number of allowed characters is 255.

=item * C<< $msg->language_codes() >> / C<< $msg->language_codes($value) >>

Type: C<String>

The list of languages of the query. This is
the BCP-47 language code, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47).

The maximum number of allowed characters is 255.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Required. Completion result count.

The maximum allowed page size is 10.

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<String>

If provided, restricts completion to specified company.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}", for
example, "projects/foo/tenants/bar/companies/baz".

=item * C<< $msg->scope() >> / C<< $msg->scope($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CompleteQueryRequest::CompletionScope>)

The scope of the completion. The defaults is
[CompletionScope.PUBLIC][google.cloud.talent.v4.CompleteQueryRequest.CompletionScope.PUBLIC].

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4::CompleteQueryRequest::CompletionType>)

The completion topic. The default is
[CompletionType.COMBINED][google.cloud.talent.v4.CompleteQueryRequest.CompletionType.COMBINED].

=back

=head3 Enum: CompleteQueryRequest::CompletionScope

=over 4

=item * C<COMPLETION_SCOPE_UNSPECIFIED> => C<0>

=item * C<TENANT> => C<1>

=item * C<PUBLIC> => C<2>

=back

=head3 Enum: CompleteQueryRequest::CompletionType

=over 4

=item * C<COMPLETION_TYPE_UNSPECIFIED> => C<0>

=item * C<JOB_TITLE> => C<1>

=item * C<COMPANY_NAME> => C<2>

=item * C<COMBINED> => C<3>

=back

=head2 Google::Cloud::Talent::V4::CompletionService::CompleteQueryResponse

Response of auto-complete query.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->completion_results() >> / C<< $msg->completion_results($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::CompletionService::CompleteQueryResponse::CompletionResult>)

Results of the matching job/company candidates.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Common::ResponseMetadata>)

Additional information for the API invocation, such as the request
tracking id.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::CompletionService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
