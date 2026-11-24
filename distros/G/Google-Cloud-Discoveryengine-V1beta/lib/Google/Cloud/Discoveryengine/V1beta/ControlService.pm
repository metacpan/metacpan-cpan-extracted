package Google::Cloud::Discoveryengine::V1beta::ControlService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::Control };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jb250cm9sX3NlcnZpY2Uu
cHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUvYXBp
L2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29v
Z2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvY29udHJvbC5wcm90bxobZ29vZ2xl
L3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90
byLPAQoUQ3JlYXRlQ29udHJvbFJlcXVlc3QSRgoGcGFyZW50GAEgASgJQi7gQQL6QSgSJmRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db250cm9sUgZwYXJlbnQSSwoHY29udHJv
bBgCIAEoCzIsLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNvbnRyb2xC
A+BBAlIHY29udHJvbBIiCgpjb250cm9sX2lkGAMgASgJQgPgQQJSCWNvbnRyb2xJZCKlAQoU
VXBkYXRlQ29udHJvbFJlcXVlc3QSSwoHY29udHJvbBgBIAEoCzIsLmdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkNvbnRyb2xCA+BBAlIHY29udHJvbBJACgt1cGRhdGVf
bWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFz
ayJaChREZWxldGVDb250cm9sUmVxdWVzdBJCCgRuYW1lGAEgASgJQi7gQQL6QSgKJmRpc2Nv
dmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db250cm9sUgRuYW1lIlcKEUdldENvbnRyb2xS
ZXF1ZXN0EkIKBG5hbWUYASABKAlCLuBBAvpBKAomZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0NvbnRyb2xSBG5hbWUiwAEKE0xpc3RDb250cm9sc1JlcXVlc3QSRgoGcGFyZW50
GAEgASgJQi7gQQL6QSgSJmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db250cm9s
UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9r
ZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIi
iAEKFExpc3RDb250cm9sc1Jlc3BvbnNlEkgKCGNvbnRyb2xzGAEgAygLMiwuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ29udHJvbFIIY29udHJvbHMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuMsMQCg5Db250cm9sU2VydmljZRKTAwoN
Q3JlYXRlQ29udHJvbBI5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNy
ZWF0ZUNvbnRyb2xSZXF1ZXN0GiwuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuQ29udHJvbCKYAoLT5JMC9QEiPS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2RhdGFTdG9yZXMvKn0vY29udHJvbHM6B2NvbnRyb2xaViJLL3YxYmV0YS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9
L2NvbnRyb2xzOgdjb250cm9sWlMiSC92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qfS9jb250cm9sczoHY29udHJvbNpBGXBh
cmVudCxjb250cm9sLGNvbnRyb2xfaWQSzQIKDURlbGV0ZUNvbnRyb2wSOS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxldGVDb250cm9sUmVxdWVzdBoWLmdvb2ds
ZS5wcm90b2J1Zi5FbXB0eSLoAYLT5JMC2gEqPS92MWJldGEve25hbWU9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9kYXRhU3RvcmVzLyovY29udHJvbHMvKn1aTSpLL3YxYmV0YS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qL2NvbnRy
b2xzLyp9WkoqSC92MWJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0
aW9ucy8qL2VuZ2luZXMvKi9jb250cm9scy8qfdpBBG5hbWUSpQMKDVVwZGF0ZUNvbnRyb2wS
OS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5VcGRhdGVDb250cm9sUmVx
dWVzdBosLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNvbnRyb2wiqgKC
0+STAo0CMkUvdjFiZXRhL3tjb250cm9sLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9k
YXRhU3RvcmVzLyovY29udHJvbHMvKn06B2NvbnRyb2xaXjJTL3YxYmV0YS97Y29udHJvbC5u
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyov
Y29udHJvbHMvKn06B2NvbnRyb2xaWzJQL3YxYmV0YS97Y29udHJvbC5uYW1lPXByb2plY3Rz
LyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyovY29udHJvbHMvKn06B2Nv
bnRyb2zaQRNjb250cm9sLHVwZGF0ZV9tYXNrEt0CCgpHZXRDb250cm9sEjYuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuR2V0Q29udHJvbFJlcXVlc3QaLC5nb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Db250cm9sIugBgtPkkwLaARI9L3YxYmV0
YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKi9jb250cm9scy8q
fVpNEksvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMv
Ki9kYXRhU3RvcmVzLyovY29udHJvbHMvKn1aShJIL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZW5naW5lcy8qL2NvbnRyb2xzLyp92kEEbmFt
ZRLwAgoMTGlzdENvbnRyb2xzEjguZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuTGlzdENvbnRyb2xzUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkxpc3RDb250cm9sc1Jlc3BvbnNlIuoBgtPkkwLaARI9L3YxYmV0YS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0b3Jlcy8qfS9jb250cm9sc1pNEksvdjFi
ZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFT
dG9yZXMvKn0vY29udHJvbHNaShJIL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRp
b25zLyovY29sbGVjdGlvbnMvKi9lbmdpbmVzLyp9L2NvbnRyb2xz2kEGcGFyZW50Gs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQpoCCidjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCE0NvbnRyb2xTZXJ2aWNlUHJvdG9Q
AVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2Nv
dmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29v
Z2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292
ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFi
ZXRhSsowCgcSBQ4A7QEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoC
AwQSAxYAOwoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgBACgkKAgglEgMaAEAKCAoB
CBIDGwBoCgkKAggLEgMbAGgKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA0CgkKAggI
EgMdADQKCAoBCBIDHgBACgkKAggBEgMeAEAKCAoBCBIDHwAtCgkKAggkEgMfAC0KCAoBCBID
IABACgkKAggpEgMgAEAKCAoBCBIDIQA/CgkKAggtEgMhAD8K4QEKAgYAEgUnAIYBARrTASBT
ZXJ2aWNlIGZvciBwZXJmb3JtaW5nIENSVUQgb3BlcmF0aW9ucyBvbiBDb250cm9scy4KIENv
bnRyb2xzIGFsbG93IGZvciBjdXN0b20gbG9naWMgdG8gYmUgaW1wbGVtZW50ZWQgaW4gdGhl
IHNlcnZpbmcgcGF0aC4KIENvbnRyb2xzIG5lZWQgdG8gYmUgYXR0YWNoZWQgdG8gYSBTZXJ2
aW5nIENvbmZpZyB0byBiZSBjb25zaWRlcmVkIGR1cmluZyBhCiByZXF1ZXN0LgoKCgoDBgAB
EgMnCBYKCgoDBgADEgMoAkYKDAoFBgADmQgSAygCRgoLCgMGAAMSBCkCLEoKDQoFBgADmggS
BCkCLEoKjQIKBAYAAgASBDQCQgMa/gEgQ3JlYXRlcyBhIENvbnRyb2wuCgogQnkgZGVmYXVs
dCAxMDAwIGNvbnRyb2xzIGFyZSBhbGxvd2VkIGZvciBhIGRhdGEgc3RvcmUuCiBBIHJlcXVl
c3QgY2FuIGJlIHN1Ym1pdHRlZCB0byBhZGp1c3QgdGhpcyBsaW1pdC4KIElmIHRoZSBbQ29u
dHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ29udHJvbF0gdG8g
Y3JlYXRlCiBhbHJlYWR5IGV4aXN0cywgYW4gQUxSRUFEWV9FWElTVFMgZXJyb3IgaXMgcmV0
dXJuZWQuCgoMCgUGAAIAARIDNAYTCgwKBQYAAgACEgM0FCgKDAoFBgACAAMSAzQzOgoNCgUG
AAIABBIENQRABgoRCgkGAAIABLDKvCISBDUEQAYKDAoFBgACAAQSA0EERwoPCggGAAIABJsI
ABIDQQRHCp0BCgQGAAIBEgRIAlMDGo4BIERlbGV0ZXMgYSBDb250cm9sLgoKIElmIHRoZSBb
Q29udHJvbF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ29udHJvbF0g
dG8gZGVsZXRlCiBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJu
ZWQuCgoMCgUGAAIBARIDSAYTCgwKBQYAAgECEgNIFCgKDAoFBgACAQMSA0gzSAoNCgUGAAIB
BBIESQRRBgoRCgkGAAIBBLDKvCISBEkEUQYKDAoFBgACAQQSA1IEMgoPCggGAAIBBJsIABID
UgQyCvQBCgQGAAICEgRaAmgDGuUBIFVwZGF0ZXMgYSBDb250cm9sLgoKIFtDb250cm9sXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Db250cm9sXSBhY3Rpb24gdHlw
ZSBjYW5ub3QKIGJlIGNoYW5nZWQuIElmIHRoZSBbQ29udHJvbF1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuQ29udHJvbF0KIHRvIHVwZGF0ZSBkb2VzIG5vdCBleGlz
dCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQuCgoMCgUGAAICARIDWgYTCgwKBQYA
AgICEgNaFCgKDAoFBgACAgMSA1ozOgoNCgUGAAICBBIEWwRmBgoRCgkGAAICBLDKvCISBFsE
ZgYKDAoFBgACAgQSA2cEQQoPCggGAAICBJsIABIDZwRBCh8KBAYAAgMSBGsCdgMaESBHZXRz
IGEgQ29udHJvbC4KCgwKBQYAAgMBEgNrBhAKDAoFBgACAwISA2sRIgoMCgUGAAIDAxIDay00
Cg0KBQYAAgMEEgRsBHQGChEKCQYAAgMEsMq8IhIEbAR0BgoMCgUGAAIDBBIDdQQyCg8KCAYA
AgMEmwgAEgN1BDIKcAoEBgACBBIFegKFAQMaYSBMaXN0cyBhbGwgQ29udHJvbHMgYnkgdGhl
aXIgcGFyZW50CiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5EYXRhU3RvcmVdLgoKDAoFBgACBAESA3oGEgoMCgUGAAIEAhIDehMmCgwKBQYAAgQD
EgN6MUUKDgoFBgACBAQSBXsEgwEGChIKCQYAAgQEsMq8IhIFewSDAQYKDQoFBgACBAQSBIQB
BDQKEAoIBgACBASbCAASBIQBBDQKMQoCBAASBokBAJ4BARojIFJlcXVlc3QgZm9yIENyZWF0
ZUNvbnRyb2wgbWV0aG9kLgoKCwoDBAABEgSJAQgcCo8CCgQEAAIAEgaOAQKTAQQa/gEgUmVx
dWlyZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBwYXJlbnQgZGF0YSBzdG9yZS4gRm9ybWF0
OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9u
cy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH1gCiBvcgogYHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29s
bGVjdGlvbl9pZH0vZW5naW5lcy97ZW5naW5lX2lkfWAuCgoNCgUEAAIABRIEjgECCAoNCgUE
AAIAARIEjgEJDwoNCgUEAAIAAxIEjgESEwoPCgUEAAIACBIGjgEUkwEDChAKCAQAAgAInAgA
EgSPAQQqChEKBwQAAgAInwgSBpABBJIBBQowCgQEAAIBEgSWAQI/GiIgUmVxdWlyZWQuIFRo
ZSBDb250cm9sIHRvIGNyZWF0ZS4KCg0KBQQAAgEGEgSWAQIJCg0KBQQAAgEBEgSWAQoRCg0K
BQQAAgEDEgSWARQVCg0KBQQAAgEIEgSWARY+ChAKCAQAAgEInAgAEgSWARc9CtMBCgQEAAIC
EgSdAQJBGsQBIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgQ29udHJvbCwgd2hp
Y2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIENvbnRyb2wncyBy
ZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgbXVzdCBiZSB3aXRoaW4gMS02MyBjaGFyYWN0
ZXJzLgogVmFsaWQgY2hhcmFjdGVycyBhcmUgL1thLXpdWzAtOV0tXy8uCgoNCgUEAAICBRIE
nQECCAoNCgUEAAICARIEnQEJEwoNCgUEAAICAxIEnQEWFwoNCgUEAAICCBIEnQEYQAoQCggE
AAICCJwIABIEnQEZPwoxCgIEARIGoQEArwEBGiMgUmVxdWVzdCBmb3IgVXBkYXRlQ29udHJv
bCBtZXRob2QuCgoLCgMEAQESBKEBCBwKMAoEBAECABIEowECPxoiIFJlcXVpcmVkLiBUaGUg
Q29udHJvbCB0byB1cGRhdGUuCgoNCgUEAQIABhIEowECCQoNCgUEAQIAARIEowEKEQoNCgUE
AQIAAxIEowEUFQoNCgUEAQIACBIEowEWPgoQCggEAQIACJwIABIEowEXPQr8AgoEBAECARIG
rQECrgEvGusCIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92
aWRlZAogW0NvbnRyb2xdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNv
bnRyb2xdIHRvIHVwZGF0ZS4gVGhlCiBmb2xsb3dpbmcgYXJlIE5PVCBzdXBwb3J0ZWQ6Cgog
KiBbQ29udHJvbC5uYW1lXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5D
b250cm9sLm5hbWVdCiAqIFtDb250cm9sLnNvbHV0aW9uX3R5cGVdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkNvbnRyb2wuc29sdXRpb25fdHlwZV0KCiBJZiBub3Qg
c2V0IG9yIGVtcHR5LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUgdXBkYXRlZC4KCg0KBQQB
AgEGEgStAQIbCg0KBQQBAgEBEgStARwnCg0KBQQBAgEDEgStASorCg0KBQQBAgEIEgSuAQYu
ChAKCAQBAgEInAgAEgSuAQctCjEKAgQCEgayAQC7AQEaIyBSZXF1ZXN0IGZvciBEZWxldGVD
b250cm9sIG1ldGhvZC4KCgsKAwQCARIEsgEIHArIAQoEBAICABIGtQECugEEGrcBIFJlcXVp
cmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgQ29udHJvbCB0byBkZWxldGUuIEZvcm1h
dDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlv
bnMve2NvbGxlY3Rpb25faWR9L2RhdGFTdG9yZXMve2RhdGFfc3RvcmVfaWR9L2NvbnRyb2xz
L3tjb250cm9sX2lkfWAKCg0KBQQCAgAFEgS1AQIICg0KBQQCAgABEgS1AQkNCg0KBQQCAgAD
EgS1ARARCg8KBQQCAgAIEga1ARK6AQMKEAoIBAICAAicCAASBLYBBCoKEQoHBAICAAifCBIG
twEEuQEFCi4KAgQDEga+AQDHAQEaICBSZXF1ZXN0IGZvciBHZXRDb250cm9sIG1ldGhvZC4K
CgsKAwQDARIEvgEIGQrFAQoEBAMCABIGwQECxgEEGrQBIFJlcXVpcmVkLiBUaGUgcmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgQ29udHJvbCB0byBnZXQuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9
L2RhdGFTdG9yZXMve2RhdGFfc3RvcmVfaWR9L2NvbnRyb2xzL3tjb250cm9sX2lkfWAKCg0K
BQQDAgAFEgTBAQIICg0KBQQDAgABEgTBAQkNCg0KBQQDAgADEgTBARARCg8KBQQDAgAIEgbB
ARLGAQMKEAoIBAMCAAicCAASBMIBBCoKEQoHBAMCAAifCBIGwwEExQEFCjAKAgQEEgbKAQDk
AQEaIiBSZXF1ZXN0IGZvciBMaXN0Q29udHJvbHMgbWV0aG9kLgoKCwoDBAQBEgTKAQgbCoQC
CgQEBAIAEgbPAQLUAQQa8wEgUmVxdWlyZWQuIFRoZSBkYXRhIHN0b3JlIHJlc291cmNlIG5h
bWUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
Y29sbGVjdGlvbnMve2NvbGxlY3Rpb25faWR9L2RhdGFTdG9yZXMve2RhdGFfc3RvcmVfaWR9
YAogb3IKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVj
dGlvbnMve2NvbGxlY3Rpb25faWR9L2VuZ2luZXMve2VuZ2luZV9pZH1gLgoKDQoFBAQCAAUS
BM8BAggKDQoFBAQCAAESBM8BCQ8KDQoFBAQCAAMSBM8BEhMKDwoFBAQCAAgSBs8BFNQBAwoQ
CggEBAIACJwIABIE0AEEKgoRCgcEBAIACJ8IEgbRAQTTAQUKegoEBAQCARIE2AECPxpsIE9w
dGlvbmFsLiBNYXhpbXVtIG51bWJlciBvZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdW5zcGVj
aWZpZWQsIGRlZmF1bHRzCiB0byA1MC4gTWF4IGFsbG93ZWQgdmFsdWUgaXMgMTAwMC4KCg0K
BQQEAgEFEgTYAQIHCg0KBQQEAgEBEgTYAQgRCg0KBQQEAgEDEgTYARQVCg0KBQQEAgEIEgTY
ARY+ChAKCAQEAgEInAgAEgTYARc9CoQBCgQEBAICEgTcAQJBGnYgT3B0aW9uYWwuIEEgcGFn
ZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0Q29udHJvbHNgIGNhbGwu
CiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCg0KBQQE
AgIFEgTcAQIICg0KBQQEAgIBEgTcAQkTCg0KBQQEAgIDEgTcARYXCg0KBQQEAgIIEgTcARhA
ChAKCAQEAgIInAgAEgTcARk/CoQCCgQEBAIDEgTjAQI9GvUBIE9wdGlvbmFsLiBBIGZpbHRl
ciB0byBhcHBseSBvbiB0aGUgbGlzdCByZXN1bHRzLiBTdXBwb3J0ZWQgZmVhdHVyZXM6Cgog
KiBMaXN0IGFsbCB0aGUgcHJvZHVjdHMgdW5kZXIgdGhlIHBhcmVudCBicmFuY2ggaWYKIFtm
aWx0ZXJdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxpc3RDb250cm9s
c1JlcXVlc3QuZmlsdGVyXSBpcwogdW5zZXQuIEN1cnJlbnRseSB0aGlzIGZpZWxkIGlzIHVu
c3VwcG9ydGVkLgoKDQoFBAQCAwUSBOMBAggKDQoFBAQCAwESBOMBCQ8KDQoFBAQCAwMSBOMB
EhMKDQoFBAQCAwgSBOMBFDwKEAoIBAQCAwicCAASBOMBFTsKMQoCBAUSBucBAO0BARojIFJl
c3BvbnNlIGZvciBMaXN0Q29udHJvbHMgbWV0aG9kLgoKCwoDBAUBEgTnAQgcCjgKBAQFAgAS
BOkBAiAaKiBBbGwgdGhlIENvbnRyb2xzIGZvciBhIGdpdmVuIGRhdGEgc3RvcmUuCgoNCgUE
BQIABBIE6QECCgoNCgUEBQIABhIE6QELEgoNCgUEBQIAARIE6QETGwoNCgUEBQIAAxIE6QEe
HwpKCgQEBQIBEgTsAQIdGjwgUGFnaW5hdGlvbiB0b2tlbiwgaWYgbm90IHJldHVybmVkIGlu
ZGljYXRlcyB0aGUgbGFzdCBwYWdlLgoKDQoFBAUCAQUSBOwBAggKDQoFBAUCAQESBOwBCRgK
DQoFBAUCAQMSBOwBGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest ===
    # Fields for CreateControlRequest
    # Field: parent Type: 9 ()
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1beta.Control)
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::UpdateControlRequest ===
    # Fields for UpdateControlRequest
    # Field: control Type: 11 (.google.cloud.discoveryengine.v1beta.Control)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::DeleteControlRequest ===
    # Fields for DeleteControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::GetControlRequest ===
    # Fields for GetControlRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsRequest ===
    # Fields for ListControlsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsResponse ===
    # Fields for ListControlsResponse
    # Field: controls Type: 11 (.google.cloud.discoveryengine.v1beta.Control)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Discoveryengine::V1beta::ControlService::ControlServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::ControlService::ControlServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::ControlService::ControlServiceClient

Client stub representing the remote C<ControlService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'CreateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Control::Control',
    });
}

sub delete_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ControlService::DeleteControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'DeleteControl',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ControlService::UpdateControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'UpdateControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Control::Control',
    });
}

sub get_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ControlService::GetControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'GetControl',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::Control::Control',
    });
}

sub list_controls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.ControlService',
        method         => 'ListControls',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ControlService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/control_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::ControlService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest->new({
        parent => $parent,
        control => $control,
        control_id => $control_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/control_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::CreateControlRequest

Request for CreateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent data store. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Control::Control>)

Required. The Control to create.

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The ID to use for the Control, which will become the final
component of the Control's resource name.

This value must be within 1-63 characters.
Valid characters are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::UpdateControlRequest

Request for UpdateControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->control() >> / C<< $msg->control($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Control::Control>)

Required. The Control to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[Control][google.cloud.discoveryengine.v1beta.Control] to update. The
following are NOT supported:

* [Control.name][google.cloud.discoveryengine.v1beta.Control.name]
* [Control.solution_type][google.cloud.discoveryengine.v1beta.Control.solution_type]

If not set or empty, all supported fields are updated.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::DeleteControlRequest

Request for DeleteControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to delete. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::GetControlRequest

Request for GetControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Control to get. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}/controls/{control_id}`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsRequest

Request for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The data store resource name. Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`
or
`projects/{project}/locations/{location}/collections/{collection_id}/engines/{engine_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 50. Max allowed value is 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListControls` call.
Provide this to retrieve the subsequent page.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. A filter to apply on the list results. Supported features:

* List all the products under the parent branch if
[filter][google.cloud.discoveryengine.v1beta.ListControlsRequest.filter] is
unset. Currently this field is unsupported.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::ControlService::ListControlsResponse

Response for ListControls method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->controls() >> / C<< $msg->controls($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Control::Control>)

All the Controls for a given data store.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::ControlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
