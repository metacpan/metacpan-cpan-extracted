package Google::Cloud::Advisorynotifications::V1::Service;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYWR2aXNvcnlub3RpZmljYXRpb25zL3YxL3NlcnZpY2UucHJvdG8S
JWdvb2dsZS5jbG91ZC5hZHZpc29yeW5vdGlmaWNhdGlvbnMudjEaHGdvb2dsZS9hcGkvYW5u
b3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIs0ECgxOb3RpZmljYXRpb24SEgoEbmFtZRgBIAEo
CVIEbmFtZRJICgdzdWJqZWN0GAIgASgLMi4uZ29vZ2xlLmNsb3VkLmFkdmlzb3J5bm90aWZp
Y2F0aW9ucy52MS5TdWJqZWN0UgdzdWJqZWN0EkoKCG1lc3NhZ2VzGAMgAygLMi4uZ29vZ2xl
LmNsb3VkLmFkdmlzb3J5bm90aWZpY2F0aW9ucy52MS5NZXNzYWdlUghtZXNzYWdlcxJACgtj
cmVhdGVfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3Jl
YXRlVGltZRJkChFub3RpZmljYXRpb25fdHlwZRgMIAEoDjI3Lmdvb2dsZS5jbG91ZC5hZHZp
c29yeW5vdGlmaWNhdGlvbnMudjEuTm90aWZpY2F0aW9uVHlwZVIQbm90aWZpY2F0aW9uVHlw
ZTrqAepB5gEKMWFkdmlzb3J5bm90aWZpY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Ob3RpZmlj
YXRpb24STm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vbm90aWZpY2F0aW9ucy97bm90aWZpY2F0aW9ufRJEcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L25vdGlmaWNhdGlvbnMve25vdGlmaWNhdGlvbn0qDW5vdGlm
aWNhdGlvbnMyDG5vdGlmaWNhdGlvbiKvAQoEVGV4dBIXCgdlbl90ZXh0GAEgASgJUgZlblRl
eHQSJQoObG9jYWxpemVkX3RleHQYAiABKAlSDWxvY2FsaXplZFRleHQSZwoSbG9jYWxpemF0
aW9uX3N0YXRlGAMgASgOMjguZ29vZ2xlLmNsb3VkLmFkdmlzb3J5bm90aWZpY2F0aW9ucy52
MS5Mb2NhbGl6YXRpb25TdGF0ZVIRbG9jYWxpemF0aW9uU3RhdGUiSgoHU3ViamVjdBI/CgR0
ZXh0GAEgASgLMisuZ29vZ2xlLmNsb3VkLmFkdmlzb3J5bm90aWZpY2F0aW9ucy52MS5UZXh0
UgR0ZXh0IvYCCgdNZXNzYWdlEkcKBGJvZHkYASABKAsyMy5nb29nbGUuY2xvdWQuYWR2aXNv
cnlub3RpZmljYXRpb25zLnYxLk1lc3NhZ2UuQm9keVIEYm9keRJTCgthdHRhY2htZW50cxgC
IAMoCzIxLmdvb2dsZS5jbG91ZC5hZHZpc29yeW5vdGlmaWNhdGlvbnMudjEuQXR0YWNobWVu
dFILYXR0YWNobWVudHMSOwoLY3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUgpjcmVhdGVUaW1lEkcKEWxvY2FsaXphdGlvbl90aW1lGAQgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIQbG9jYWxpemF0aW9uVGltZRpHCgRCb2R5Ej8KBHRl
eHQYASABKAsyKy5nb29nbGUuY2xvdWQuYWR2aXNvcnlub3RpZmljYXRpb25zLnYxLlRleHRS
BHRleHQidwoKQXR0YWNobWVudBI+CgNjc3YYAiABKAsyKi5nb29nbGUuY2xvdWQuYWR2aXNv
cnlub3RpZmljYXRpb25zLnYxLkNzdkgAUgNjc3YSIQoMZGlzcGxheV9uYW1lGAEgASgJUgtk
aXNwbGF5TmFtZUIGCgRkYXRhIpMBCgNDc3YSGAoHaGVhZGVycxgBIAMoCVIHaGVhZGVycxJO
CglkYXRhX3Jvd3MYAiADKAsyMS5nb29nbGUuY2xvdWQuYWR2aXNvcnlub3RpZmljYXRpb25z
LnYxLkNzdi5Dc3ZSb3dSCGRhdGFSb3dzGiIKBkNzdlJvdxIYCgdlbnRyaWVzGAEgAygJUgdl
bnRyaWVzIpsCChhMaXN0Tm90aWZpY2F0aW9uc1JlcXVlc3QSUQoGcGFyZW50GAEgASgJQjng
QQL6QTMSMWFkdmlzb3J5bm90aWZpY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Ob3RpZmljYXRp
b25SBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4Y
AyABKAlSCXBhZ2VUb2tlbhJLCgR2aWV3GAQgASgOMjcuZ29vZ2xlLmNsb3VkLmFkdmlzb3J5
bm90aWZpY2F0aW9ucy52MS5Ob3RpZmljYXRpb25WaWV3UgR2aWV3EiMKDWxhbmd1YWdlX2Nv
ZGUYBSABKAlSDGxhbmd1YWdlQ29kZSK9AQoZTGlzdE5vdGlmaWNhdGlvbnNSZXNwb25zZRJZ
Cg1ub3RpZmljYXRpb25zGAEgAygLMjMuZ29vZ2xlLmNsb3VkLmFkdmlzb3J5bm90aWZpY2F0
aW9ucy52MS5Ob3RpZmljYXRpb25SDW5vdGlmaWNhdGlvbnMSJgoPbmV4dF9wYWdlX3Rva2Vu
GAIgASgJUg1uZXh0UGFnZVRva2VuEh0KCnRvdGFsX3NpemUYAyABKAVSCXRvdGFsU2l6ZSKM
AQoWR2V0Tm90aWZpY2F0aW9uUmVxdWVzdBJNCgRuYW1lGAEgASgJQjngQQL6QTMKMWFkdmlz
b3J5bm90aWZpY2F0aW9ucy5nb29nbGVhcGlzLmNvbS9Ob3RpZmljYXRpb25SBG5hbWUSIwoN
bGFuZ3VhZ2VfY29kZRgFIAEoCVIMbGFuZ3VhZ2VDb2RlIoEECghTZXR0aW5ncxIXCgRuYW1l
GAEgASgJQgPgQQhSBG5hbWUSgwEKFW5vdGlmaWNhdGlvbl9zZXR0aW5ncxgCIAMoCzJJLmdv
b2dsZS5jbG91ZC5hZHZpc29yeW5vdGlmaWNhdGlvbnMudjEuU2V0dGluZ3MuTm90aWZpY2F0
aW9uU2V0dGluZ3NFbnRyeUID4EECUhRub3RpZmljYXRpb25TZXR0aW5ncxIXCgRldGFnGAMg
ASgJQgPgQQJSBGV0YWcahAEKGU5vdGlmaWNhdGlvblNldHRpbmdzRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSUQoFdmFsdWUYAiABKAsyOy5nb29nbGUuY2xvdWQuYWR2aXNvcnlub3RpZmlj
YXRpb25zLnYxLk5vdGlmaWNhdGlvblNldHRpbmdzUgV2YWx1ZToCOAE6tQHqQbEBCi1hZHZp
c29yeW5vdGlmaWNhdGlvbnMuZ29vZ2xlYXBpcy5jb20vU2V0dGluZ3MSOm9yZ2FuaXphdGlv
bnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vc2V0dGluZ3MSMHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXR0aW5ncyoIc2V0dGluZ3My
CHNldHRpbmdzIjAKFE5vdGlmaWNhdGlvblNldHRpbmdzEhgKB2VuYWJsZWQYASABKAhSB2Vu
YWJsZWQiXwoSR2V0U2V0dGluZ3NSZXF1ZXN0EkkKBG5hbWUYASABKAlCNeBBAvpBLwotYWR2
aXNvcnlub3RpZmljYXRpb25zLmdvb2dsZWFwaXMuY29tL1NldHRpbmdzUgRuYW1lImkKFVVw
ZGF0ZVNldHRpbmdzUmVxdWVzdBJQCghzZXR0aW5ncxgBIAEoCzIvLmdvb2dsZS5jbG91ZC5h
ZHZpc29yeW5vdGlmaWNhdGlvbnMudjEuU2V0dGluZ3NCA+BBAlIIc2V0dGluZ3MqSgoQTm90
aWZpY2F0aW9uVmlldxIhCh1OT1RJRklDQVRJT05fVklFV19VTlNQRUNJRklFRBAAEgkKBUJB
U0lDEAESCAoERlVMTBACKqABChFMb2NhbGl6YXRpb25TdGF0ZRIiCh5MT0NBTElaQVRJT05f
U1RBVEVfVU5TUEVDSUZJRUQQABIlCiFMT0NBTElaQVRJT05fU1RBVEVfTk9UX0FQUExJQ0FC
TEUQARIeChpMT0NBTElaQVRJT05fU1RBVEVfUEVORElORxACEiAKHExPQ0FMSVpBVElPTl9T
VEFURV9DT01QTEVURUQQAyraAQoQTm90aWZpY2F0aW9uVHlwZRIhCh1OT1RJRklDQVRJT05f
VFlQRV9VTlNQRUNJRklFRBAAEi8KK05PVElGSUNBVElPTl9UWVBFX1NFQ1VSSVRZX1BSSVZB
Q1lfQURWSVNPUlkQARInCiNOT1RJRklDQVRJT05fVFlQRV9TRU5TSVRJVkVfQUNUSU9OUxAC
EiIKHk5PVElGSUNBVElPTl9UWVBFX1NFQ1VSSVRZX01TQRADEiUKIU5PVElGSUNBVElPTl9U
WVBFX1RIUkVBVF9IT1JJWk9OUxAEMpkJChxBZHZpc29yeU5vdGlmaWNhdGlvbnNTZXJ2aWNl
EpQCChFMaXN0Tm90aWZpY2F0aW9ucxI/Lmdvb2dsZS5jbG91ZC5hZHZpc29yeW5vdGlmaWNh
dGlvbnMudjEuTGlzdE5vdGlmaWNhdGlvbnNSZXF1ZXN0GkAuZ29vZ2xlLmNsb3VkLmFkdmlz
b3J5bm90aWZpY2F0aW9ucy52MS5MaXN0Tm90aWZpY2F0aW9uc1Jlc3BvbnNlInyC0+STAm0S
Ni92MS97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKn0vbm90aWZpY2F0aW9u
c1ozEjEvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9ub3RpZmljYXRpb25z
2kEGcGFyZW50EoECCg9HZXROb3RpZmljYXRpb24SPS5nb29nbGUuY2xvdWQuYWR2aXNvcnlu
b3RpZmljYXRpb25zLnYxLkdldE5vdGlmaWNhdGlvblJlcXVlc3QaMy5nb29nbGUuY2xvdWQu
YWR2aXNvcnlub3RpZmljYXRpb25zLnYxLk5vdGlmaWNhdGlvbiJ6gtPkkwJtEjYvdjEve25h
bWU9b3JnYW5pemF0aW9ucy8qL2xvY2F0aW9ucy8qL25vdGlmaWNhdGlvbnMvKn1aMxIxL3Yx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovbm90aWZpY2F0aW9ucy8qfdpBBG5hbWUS
5wEKC0dldFNldHRpbmdzEjkuZ29vZ2xlLmNsb3VkLmFkdmlzb3J5bm90aWZpY2F0aW9ucy52
MS5HZXRTZXR0aW5nc1JlcXVlc3QaLy5nb29nbGUuY2xvdWQuYWR2aXNvcnlub3RpZmljYXRp
b25zLnYxLlNldHRpbmdzImyC0+STAl8SLy92MS97bmFtZT1vcmdhbml6YXRpb25zLyovbG9j
YXRpb25zLyovc2V0dGluZ3N9WiwSKi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3NldHRpbmdzfdpBBG5hbWUSmQIKDlVwZGF0ZVNldHRpbmdzEjwuZ29vZ2xlLmNsb3VkLmFk
dmlzb3J5bm90aWZpY2F0aW9ucy52MS5VcGRhdGVTZXR0aW5nc1JlcXVlc3QaLy5nb29nbGUu
Y2xvdWQuYWR2aXNvcnlub3RpZmljYXRpb25zLnYxLlNldHRpbmdzIpcBgtPkkwKFATI4L3Yx
L3tzZXR0aW5ncy5uYW1lPW9yZ2FuaXphdGlvbnMvKi9sb2NhdGlvbnMvKi9zZXR0aW5nc306
CHNldHRpbmdzWj8yMy92MS97c2V0dGluZ3MubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3NldHRpbmdzfToIc2V0dGluZ3PaQQhzZXR0aW5ncxpYykEkYWR2aXNvcnlub3RpZmljYXRp
b25zLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9j
bG91ZC1wbGF0Zm9ybUKmAwopY29tLmdvb2dsZS5jbG91ZC5hZHZpc29yeW5vdGlmaWNhdGlv
bnMudjFCDFNlcnZpY2VQcm90b1ABWl9jbG91ZC5nb29nbGUuY29tL2dvL2Fkdmlzb3J5bm90
aWZpY2F0aW9ucy9hcGl2MS9hZHZpc29yeW5vdGlmaWNhdGlvbnNwYjthZHZpc29yeW5vdGlm
aWNhdGlvbnNwYqoCJUdvb2dsZS5DbG91ZC5BZHZpc29yeU5vdGlmaWNhdGlvbnMuVjHKAiVH
b29nbGVcQ2xvdWRcQWR2aXNvcnlOb3RpZmljYXRpb25zXFYx6gIoR29vZ2xlOjpDbG91ZDo6
QWR2aXNvcnlOb3RpZmljYXRpb25zOjpWMepBiwEKLWFkdmlzb3J5bm90aWZpY2F0aW9ucy5n
b29nbGVhcGlzLmNvbS9Mb2NhdGlvbhIxb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9s
b2NhdGlvbnMve2xvY2F0aW9ufRIncHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259SolTCgcSBQ4A6wIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAuCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMK
CQoCAwQSAxYAKQoICgEIEgMYAEIKCQoCCCUSAxgAQgoICgEIEgMZAHYKCQoCCAsSAxkAdgoI
CgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC0KCQoCCAgSAxsALQoICgEIEgMcAEIKCQoC
CAESAxwAQgoICgEIEgMdAEIKCQoCCCkSAx0AQgoICgEIEgMeAEEKCQoCCC0SAx4AQQoJCgEI
EgQfACMCCgwKBAidCAASBB8AIwIKQwoCBgASBCYAVwEaNyBTZXJ2aWNlIHRvIG1hbmFnZSBT
ZWN1cml0eSBhbmQgUHJpdmFjeSBOb3RpZmljYXRpb25zLgoKCgoDBgABEgMmCCQKCgoDBgAD
EgMnAkwKDAoFBgADmQgSAycCTAoLCgMGAAMSBCgCKTcKDQoFBgADmggSBCgCKTcKOQoEBgAC
ABIELAI1AxorIExpc3RzIG5vdGlmaWNhdGlvbnMgdW5kZXIgYSBnaXZlbiBwYXJlbnQuCgoM
CgUGAAIAARIDLAYXCgwKBQYAAgACEgMsGDAKDAoFBgACAAMSAy0PKAoNCgUGAAIABBIELgQz
BgoRCgkGAAIABLDKvCISBC4EMwYKDAoFBgACAAQSAzQENAoPCggGAAIABJsIABIDNAQ0CiQK
BAYAAgESBDgCQAMaFiBHZXRzIGEgbm90aWZpY2F0aW9uLgoKDAoFBgACAQESAzgGFQoMCgUG
AAIBAhIDOBYsCgwKBQYAAgEDEgM4N0MKDQoFBgACAQQSBDkEPgYKEQoJBgACAQSwyrwiEgQ5
BD4GCgwKBQYAAgEEEgM/BDIKDwoIBgACAQSbCAASAz8EMgoqCgQGAAICEgRDAkkDGhwgR2V0
IG5vdGlmaWNhdGlvbiBzZXR0aW5ncy4KCgwKBQYAAgIBEgNDBhEKDAoFBgACAgISA0MSJAoM
CgUGAAICAxIDQy83Cg0KBQYAAgIEEgREBEcGChEKCQYAAgIEsMq8IhIERARHBgoMCgUGAAIC
BBIDSAQyCg8KCAYAAgIEmwgAEgNIBDIKLQoEBgACAxIETAJWAxofIFVwZGF0ZSBub3RpZmlj
YXRpb24gc2V0dGluZ3MuCgoMCgUGAAIDARIDTAYUCgwKBQYAAgMCEgNMFSoKDAoFBgACAwMS
A0w1PQoNCgUGAAIDBBIETQRUBgoRCgkGAAIDBLDKvCISBE0EVAYKDAoFBgACAwQSA1UENgoP
CggGAAIDBJsIABIDVQQ2CiAKAgUAEgRaAGUBGhQgTm90aWZpY2F0aW9uIHZpZXcuCgoKCgMF
AAESA1oFFQoyCgQFAAIAEgNcAiQaJSBOb3Qgc3BlY2lmaWVkLCBlcXVpdmFsZW50IHRvIEJB
U0lDLgoKDAoFBQACAAESA1wCHwoMCgUFAAIAAhIDXCIjCt8BCgQFAAIBEgNhAgwa0QEgU2Vy
dmVyIHJlc3BvbnNlcyBvbmx5IGluY2x1ZGUgdGl0bGUsIGNyZWF0aW9uIHRpbWUgYW5kIE5v
dGlmaWNhdGlvbiBJRC4KIE5vdGU6IGZvciBpbnRlcm5hbCB1c2UgcmVzcG9uc2VzIGFsc28g
aW5jbHVkZSB0aGUgbGFzdCB1cGRhdGUgdGltZSwKIHRoZSBsYXRlc3QgbWVzc2FnZSB0ZXh0
IGFuZCB3aGV0aGVyIG5vdGlmaWNhdGlvbiBoYXMgYXR0YWNobWVudHMuCgoMCgUFAAIBARID
YQIHCgwKBQUAAgECEgNhCgsKIgoEBQACAhIDZAILGhUgSW5jbHVkZSBldmVyeXRoaW5nLgoK
DAoFBQACAgESA2QCBgoMCgUFAAICAhIDZAkKCicKAgUBEgRoAHkBGhsgU3RhdHVzIG9mIGxv
Y2FsaXplZCB0ZXh0LgoKCgoDBQEBEgNoBRYKGAoEBQECABIDagIlGgsgTm90IHVzZWQuCgoM
CgUFAQIAARIDagIgCgwKBQUBAgACEgNqIyQK3QIKBAUBAgESA3ICKBrPAiBMb2NhbGl6YXRp
b24gaXMgbm90IGFwcGxpY2FibGUgZm9yIHJlcXVlc3RlZCBsYW5ndWFnZS4gVGhpcyBjYW4g
aGFwcGVuCiB3aGVuOgogLSBUaGUgcmVxdWVzdGVkIGxhbmd1YWdlIHdhcyBub3Qgc3VwcG9y
dGVkIGJ5IEFkdmlzb3J5IE5vdGlmaWNhdGlvbnMgYXQgdGhlCiB0aW1lIG9mIGxvY2FsaXph
dGlvbiAoaW5jbHVkaW5nIG5vdGlmaWNhdGlvbnMgY3JlYXRlZCBiZWZvcmUgdGhlCiBsb2Nh
bGl6YXRpb24gZmVhdHVyZSB3YXMgbGF1bmNoZWQpLgogLSBUaGUgcmVxdWVzdGVkIGxhbmd1
YWdlIGlzIEVuZ2xpc2gsIHNvIG9ubHkgdGhlIEVuZ2xpc2ggdGV4dCBpcyByZXR1cm5lZC4K
CgwKBQUBAgEBEgNyAiMKDAoFBQECAQISA3ImJwpVCgQFAQICEgN1AiEaSCBMb2NhbGl6YXRp
b24gZm9yIHJlcXVlc3RlZCBsYW5ndWFnZSBpcyBpbiBwcm9ncmVzcywgYW5kIG5vdCByZWFk
eSB5ZXQuCgoMCgUFAQICARIDdQIcCgwKBQUBAgICEgN1HyAKQAoEBQECAxIDeAIjGjMgTG9j
YWxpemF0aW9uIGZvciByZXF1ZXN0ZWQgbGFuZ3VhZ2UgaXMgY29tcGxldGVkLgoKDAoFBQEC
AwESA3gCHgoMCgUFAQIDAhIDeCEiCiMKAgUCEgV8AIsBARoWIFR5cGUgb2Ygbm90aWZpY2F0
aW9uCgoKCgMFAgESA3wFFQobCgQFAgIAEgN+AiQaDiBEZWZhdWx0IHR5cGUKCgwKBQUCAgAB
EgN+Ah8KDAoFBQICAAISA34iIwo7CgQFAgIBEgSBAQIyGi0gU2VjdXJpdHkgYW5kIHByaXZh
Y3kgYWR2aXNvcnkgbm90aWZpY2F0aW9ucwoKDQoFBQICAQESBIEBAi0KDQoFBQICAQISBIEB
MDEKLgoEBQICAhIEhAECKhogIFNlbnNpdGl2ZSBhY3Rpb24gbm90aWZpY2F0aW9ucwoKDQoF
BQICAgESBIQBAiUKDQoFBQICAgISBIQBKCkKJAoEBQICAxIEhwECJRoWIEdlbmVyYWwgc2Vj
dXJpdHkgTVNBCgoNCgUFAgIDARIEhwECIAoNCgUFAgIDAhIEhwEjJAojCgQFAgIEEgSKAQIo
GhUgVGhyZWF0IGhvcml6b25zIE1TQQoKDQoFBQICBAESBIoBAiMKDQoFBQICBAISBIoBJicK
YQoCBAASBo8BAKoBARpTIEEgbm90aWZpY2F0aW9uIG9iamVjdCBmb3Igbm90aWZ5aW5nIGN1
c3RvbWVycyBhYm91dCBzZWN1cml0eSBhbmQgcHJpdmFjeQogaXNzdWVzLgoKCwoDBAABEgSP
AQgUCg0KAwQABxIGkAEClgEECg8KBQQAB50IEgaQAQKWAQQK2gEKBAQAAgASBJwBAhIaywEg
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG5vdGlmaWNhdGlvbi4KIEZvcm1hdDoKIG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbm90aWZpY2F0
aW9ucy97bm90aWZpY2F0aW9ufQogb3IgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L25vdGlmaWNhdGlvbnMve25vdGlmaWNhdGlvbn0uCgoNCgUEAAIABRIEnAEC
CAoNCgUEAAIAARIEnAEJDQoNCgUEAAIAAxIEnAEQEQo1CgQEAAIBEgSfAQIWGicgVGhlIHN1
YmplY3QgbGluZSBvZiB0aGUgbm90aWZpY2F0aW9uLgoKDQoFBAACAQYSBJ8BAgkKDQoFBAAC
AQESBJ8BChEKDQoFBAACAQMSBJ8BFBUKNwoEBAACAhIEogECIBopIEEgbGlzdCBvZiBtZXNz
YWdlcyBpbiB0aGUgbm90aWZpY2F0aW9uLgoKDQoFBAACAgQSBKIBAgoKDQoFBAACAgYSBKIB
CxIKDQoFBAACAgESBKIBExsKDQoFBAACAgMSBKIBHh8KQQoEBAACAxIGpQECpgEyGjEgT3V0
cHV0IG9ubHkuIFRpbWUgdGhlIG5vdGlmaWNhdGlvbiB3YXMgY3JlYXRlZC4KCg0KBQQAAgMG
EgSlAQIbCg0KBQQAAgMBEgSlARwnCg0KBQQAAgMDEgSlASorCg0KBQQAAgMIEgSmAQYxChAK
CAQAAgMInAgAEgSmAQcwCiQKBAQAAgQSBKkBAioaFiBUeXBlIG9mIG5vdGlmaWNhdGlvbgoK
DQoFBAACBAYSBKkBAhIKDQoFBAACBAESBKkBEyQKDQoFBAACBAMSBKkBJykKUwoCBAESBq0B
ALYBARpFIEEgdGV4dCBvYmplY3QgY29udGFpbmluZyB0aGUgRW5nbGlzaCB0ZXh0IGFuZCBp
dHMgbG9jYWxpemVkIGNvcGllcy4KCgsKAwQBARIErQEIDAohCgQEAQIAEgSvAQIVGhMgVGhl
IEVuZ2xpc2ggY29weS4KCg0KBQQBAgAFEgSvAQIICg0KBQQBAgABEgSvAQkQCg0KBQQBAgAD
EgSvARMUCj0KBAQBAgESBLIBAhwaLyBUaGUgcmVxdWVzdGVkIGxvY2FsaXplZCBjb3B5IChp
ZiBhcHBsaWNhYmxlKS4KCg0KBQQBAgEFEgSyAQIICg0KBQQBAgEBEgSyAQkXCg0KBQQBAgED
EgSyARobCisKBAQBAgISBLUBAisaHSBTdGF0dXMgb2YgdGhlIGxvY2FsaXphdGlvbi4KCg0K
BQQBAgIGEgS1AQITCg0KBQQBAgIBEgS1ARQmCg0KBQQBAgIDEgS1ASkqCjEKAgQCEga5AQC8
AQEaIyBBIHN1YmplY3QgbGluZSBvZiBhIG5vdGlmaWNhdGlvbi4KCgsKAwQCARIEuQEIDwoh
CgQEAgIAEgS7AQIQGhMgVGhlIHRleHQgY29udGVudC4KCg0KBQQCAgAGEgS7AQIGCg0KBQQC
AgABEgS7AQcLCg0KBQQCAgADEgS7AQ4PCj4KAgQDEga/AQDRAQEaMCBBIG1lc3NhZ2Ugd2hp
Y2ggY29udGFpbnMgbm90aWZpY2F0aW9uIGRldGFpbHMuCgoLCgMEAwESBL8BCA8KMQoEBAMD
ABIGwQECxAEDGiEgQSBtZXNzYWdlIGJvZHkgY29udGFpbmluZyB0ZXh0LgoKDQoFBAMDAAES
BMEBCg4KNwoGBAMDAAIAEgTDAQQSGicgVGhlIHRleHQgY29udGVudCBvZiB0aGUgbWVzc2Fn
ZSBib2R5LgoKDwoHBAMDAAIABhIEwwEECAoPCgcEAwMAAgABEgTDAQkNCg8KBwQDAwACAAMS
BMMBEBEKJAoEBAMCABIExwECEBoWIFRoZSBtZXNzYWdlIGNvbnRlbnQuCgoNCgUEAwIABhIE
xwECBgoNCgUEAwIAARIExwEHCwoNCgUEAwIAAxIExwEODwosCgQEAwIBEgTKAQImGh4gVGhl
IGF0dGFjaG1lbnRzIHRvIGRvd25sb2FkLgoKDQoFBAMCAQQSBMoBAgoKDQoFBAMCAQYSBMoB
CxUKDQoFBAMCAQESBMoBFiEKDQoFBAMCAQMSBMoBJCUKLwoEBAMCAhIEzQECLBohIFRoZSBN
ZXNzYWdlIGNyZWF0aW9uIHRpbWVzdGFtcC4KCg0KBQQDAgIGEgTNAQIbCg0KBQQDAgIBEgTN
ARwnCg0KBQQDAgIDEgTNASorCi8KBAQDAgMSBNABAjIaISBUaW1lIHdoZW4gTWVzc2FnZSB3
YXMgbG9jYWxpemVkCgoNCgUEAwIDBhIE0AECGwoNCgUEAwIDARIE0AEcLQoNCgUEAwIDAxIE
0AEwMQpFCgIEBBIG1AEA3QEBGjcgQXR0YWNobWVudCB3aXRoIHNwZWNpZmljIGluZm9ybWF0
aW9uIGFib3V0IHRoZSBpc3N1ZS4KCgsKAwQEARIE1AEIEgouCgQEBAgAEgbWAQLZAQMaHiBE
YXRhIHR5cGUgb2YgdGhlIGF0dGFjaG1lbnQuCgoNCgUEBAgAARIE1gEIDAo5CgQEBAIAEgTY
AQQQGisgQSBDU1YgZmlsZSBhdHRhY2htZW50LiBNYXggc2l6ZSBpcyAxMCBNQi4KCg0KBQQE
AgAGEgTYAQQHCg0KBQQEAgABEgTYAQgLCg0KBQQEAgADEgTYAQ4PCiwKBAQEAgESBNwBAhoa
HiBUaGUgdGl0bGUgb2YgdGhlIGF0dGFjaG1lbnQuCgoNCgUEBAIBBRIE3AECCAoNCgUEBAIB
ARIE3AEJFQoNCgUEBAIBAxIE3AEYGQpwCgIEBRIG4QEA7wEBGmIgQSByZXByZXNlbnRhdGlv
biBvZiBhIENTViBmaWxlIGF0dGFjaG1lbnQsIGFzIGEgbGlzdCBvZiBjb2x1bW4gaGVhZGVy
cyBhbmQKIGEgbGlzdCBvZiBkYXRhIHJvd3MuCgoLCgMEBQESBOEBCAsKRgoEBAUDABIG4wEC
5wEDGjYgQSByZXByZXNlbnRhdGlvbiBvZiBhIHNpbmdsZSBkYXRhIHJvdyBpbiBhIENTViBm
aWxlLgoKDQoFBAUDAAESBOMBChAKdQoGBAUDAAIAEgTmAQQgGmUgVGhlIGRhdGEgZW50cmll
cyBpbiBhIENTViBmaWxlIHJvdywgYXMgYSBzdHJpbmcgYXJyYXkgcmF0aGVyIHRoYW4gYQog
c2luZ2xlIGNvbW1hLXNlcGFyYXRlZCBzdHJpbmcuCgoPCgcEBQMAAgAEEgTmAQQMCg8KBwQF
AwACAAUSBOYBDRMKDwoHBAUDAAIAARIE5gEUGwoPCgcEBQMAAgADEgTmAR4fCkMKBAQFAgAS
BOoBAh4aNSBUaGUgbGlzdCBvZiBoZWFkZXJzIGZvciBkYXRhIGNvbHVtbnMgaW4gYSBDU1Yg
ZmlsZS4KCg0KBQQFAgAEEgTqAQIKCg0KBQQFAgAFEgTqAQsRCg0KBQQFAgABEgTqARIZCg0K
BQQFAgADEgTqARwdCnYKBAQFAgESBO4BAiAaaCBUaGUgbGlzdCBvZiBkYXRhIHJvd3MgaW4g
YSBDU1YgZmlsZSwgYXMgc3RyaW5nIGFycmF5cyByYXRoZXIgdGhhbiBhcyBhCiBzaW5nbGUg
Y29tbWEtc2VwYXJhdGVkIHN0cmluZy4KCg0KBQQFAgEEEgTuAQIKCg0KBQQFAgEGEgTuAQsR
Cg0KBQQFAgEBEgTuARIbCg0KBQQFAgEDEgTuAR4fCkoKAgQGEgbyAQCSAgEaPCBSZXF1ZXN0
IGZvciBmZXRjaGluZyBhbGwgbm90aWZpY2F0aW9ucyBmb3IgYSBnaXZlbiBwYXJlbnQuCgoL
CgMEBgESBPIBCCAKzQEKBAQGAgASBvYBAvsBBBq8ASBSZXF1aXJlZC4gVGhlIHBhcmVudCwg
d2hpY2ggb3ducyB0aGlzIGNvbGxlY3Rpb24gb2Ygbm90aWZpY2F0aW9ucy4KIE11c3QgYmUg
b2YgdGhlIGZvcm0gIm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3ts
b2NhdGlvbn0iCiBvciAicHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
Ii4KCg0KBQQGAgAFEgT2AQIICg0KBQQGAgABEgT2AQkPCg0KBQQGAgADEgT2ARITCg8KBQQG
AgAIEgb2ART7AQMKEAoIBAYCAAicCAASBPcBBCoKEQoHBAYCAAifCBIG+AEE+gEFCvkBCgQE
BgIBEgSBAgIWGuoBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBub3RpZmljYXRpb25zIHRvIHJl
dHVybi4gVGhlIHNlcnZpY2UgbWF5IHJldHVybgogZmV3ZXIgdGhhbiB0aGlzIHZhbHVlLiBJ
ZiB1bnNwZWNpZmllZCBvciBlcXVhbCB0byAwLCBhdCBtb3N0IDUwCiBub3RpZmljYXRpb25z
IHdpbGwgYmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDUwOyB2YWx1ZXMgYWJv
dmUgNTAKIHdpbGwgYmUgY29lcmNlZCB0byA1MC4KCg0KBQQGAgEFEgSBAgIHCg0KBQQGAgEB
EgSBAggRCg0KBQQGAgEDEgSBAhQVCrEBCgQEBgICEgSGAgIYGqIBIEEgcGFnZSB0b2tlbiBy
ZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgcmVxdWVzdC4KIFdoZW4gcGFnaW5hdGluZywgYWxs
IG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgaW4gdGhlIHJlcXVlc3QKIG11c3QgbWF0Y2gg
dGhlIGNhbGwgdGhhdCByZXR1cm5lZCB0aGUgcGFnZSB0b2tlbi4KCg0KBQQGAgIFEgSGAgII
Cg0KBQQGAgIBEgSGAgkTCg0KBQQGAgIDEgSGAhYXCmcKBAQGAgMSBIoCAhwaWSBTcGVjaWZp
ZXMgd2hpY2ggcGFydHMgb2YgdGhlIG5vdGlmaWNhdGlvbiByZXNvdXJjZSBzaG91bGQgYmUg
cmV0dXJuZWQKIGluIHRoZSByZXNwb25zZS4KCg0KBQQGAgMGEgSKAgISCg0KBQQGAgMBEgSK
AhMXCg0KBQQGAgMDEgSKAhobCtICCgQEBgIEEgSRAgIbGsMCIElTTyBjb2RlIGZvciByZXF1
ZXN0ZWQgbG9jYWxpemF0aW9uIGxhbmd1YWdlLiAgSWYgdW5zZXQsIHdpbGwgYmUKIGludGVy
cGVyZXRlZCBhcyAiZW4iLiBJZiB0aGUgcmVxdWVzdGVkIGxhbmd1YWdlIGlzIHZhbGlkLCBi
dXQgbm90IHN1cHBvcnRlZAogZm9yIHRoaXMgbm90aWZpY2F0aW9uLCBFbmdsaXNoIHdpbGwg
YmUgcmV0dXJuZWQgd2l0aCBhbiAiTm90IGFwcGxpY2FibGUiCiBMb2NhbGl6YXRpb25TdGF0
ZS4gSWYgdGhlIElTTyBjb2RlIGlzIGludmFsaWQgKGkuZS4gbm90IGEgcmVhbCBsYW5ndWFn
ZSksCiB0aGlzIFJQQyB3aWxsIHRocm93IGFuIGVycm9yLgoKDQoFBAYCBAUSBJECAggKDQoF
BAYCBAESBJECCRYKDQoFBAYCBAMSBJECGRoKNwoCBAcSBpUCAJ8CARopIFJlc3BvbnNlIG9m
IExpc3ROb3RpZmljYXRpb25zIGVuZHBvaW50LgoKCwoDBAcBEgSVAgghCjsKBAQHAgASBJcC
AioaLSBMaXN0IG9mIG5vdGlmaWNhdGlvbnMgdW5kZXIgYSBnaXZlbiBwYXJlbnQuCgoNCgUE
BwIABBIElwICCgoNCgUEBwIABhIElwILFwoNCgUEBwIAARIElwIYJQoNCgUEBwIAAxIElwIo
KQqQAQoEBAcCARIEmwICHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUgc2VudCBhcyBgcGFn
ZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRoaXMgZmllbGQgaXMg
b21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoNCgUEBwIBBRIEmwIC
CAoNCgUEBwIBARIEmwIJGAoNCgUEBwIBAxIEmwIbHAo+CgQEBwICEgSeAgIXGjAgRXN0aW1h
dGlvbiBvZiBhIHRvdGFsIG51bWJlciBvZiBub3RpZmljYXRpb25zLgoKDQoFBAcCAgUSBJ4C
AgcKDQoFBAcCAgESBJ4CCBIKDQoFBAcCAgMSBJ4CFRYKNAoCBAgSBqICALQCARomIFJlcXVl
c3QgZm9yIGZldGNoaW5nIGEgbm90aWZpY2F0aW9uLgoKCwoDBAgBEgSiAggeCugBCgQECAIA
EganAgKsAgQa1wEgUmVxdWlyZWQuIEEgbmFtZSBvZiB0aGUgbm90aWZpY2F0aW9uIHRvIHJl
dHJpZXZlLgogRm9ybWF0Ogogb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9ub3RpZmljYXRpb25zL3tub3RpZmljYXRpb259CiBvciBwcm9qZWN0
cy97cHJvamVjdHN9L2xvY2F0aW9ucy97bG9jYXRpb259L25vdGlmaWNhdGlvbnMve25vdGlm
aWNhdGlvbn0uCgoNCgUECAIABRIEpwICCAoNCgUECAIAARIEpwIJDQoNCgUECAIAAxIEpwIQ
EQoPCgUECAIACBIGpwISrAIDChAKCAQIAgAInAgAEgSoAgQqChEKBwQIAgAInwgSBqkCBKsC
BQrRAgoEBAgCARIEswICGxrCAiBJU08gY29kZSBmb3IgcmVxdWVzdGVkIGxvY2FsaXphdGlv
biBsYW5ndWFnZS4gSWYgdW5zZXQsIHdpbGwgYmUKIGludGVycGVyZXRlZCBhcyAiZW4iLiBJ
ZiB0aGUgcmVxdWVzdGVkIGxhbmd1YWdlIGlzIHZhbGlkLCBidXQgbm90IHN1cHBvcnRlZAog
Zm9yIHRoaXMgbm90aWZpY2F0aW9uLCBFbmdsaXNoIHdpbGwgYmUgcmV0dXJuZWQgd2l0aCBh
biAiTm90IGFwcGxpY2FibGUiCiBMb2NhbGl6YXRpb25TdGF0ZS4gSWYgdGhlIElTTyBjb2Rl
IGlzIGludmFsaWQgKGkuZS4gbm90IGEgcmVhbCBsYW5ndWFnZSksCiB0aGlzIFJQQyB3aWxs
IHRocm93IGFuIGVycm9yLgoKDQoFBAgCAQUSBLMCAggKDQoFBAgCAQESBLMCCRYKDQoFBAgC
AQMSBLMCGRoKNAoCBAkSBrcCANECARomIFNldHRpbmdzIGZvciBBZHZpc29yeSBOb3RpZmlj
YXRpb25zLgoKCwoDBAkBEgS3AggQCg0KAwQJBxIGuAICvgIECg8KBQQJB50IEga4AgK+AgQK
xwEKBAQJAgASBMQCAj0auAEgSWRlbnRpZmllci4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IHNldHRpbmdzIHRvIHJldHJpZXZlLgogRm9ybWF0Ogogb3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXR0aW5ncyBvcgogcHJvamVjdHMve3By
b2plY3RzfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zZXR0aW5ncy4KCg0KBQQJAgAFEgTEAgII
Cg0KBQQJAgABEgTEAgkNCg0KBQQJAgADEgTEAhARCg0KBQQJAgAIEgTEAhI8ChAKCAQJAgAI
nAgAEgTEAhM7Cq0BCgQECQIBEgbJAgLKAi8anAEgUmVxdWlyZWQuIE1hcCBvZiBlYWNoIG5v
dGlmaWNhdGlvbiB0eXBlIGFuZCBpdHMgc2V0dGluZ3MgdG8gZ2V0L3NldCBhbGwKIHNldHRp
bmdzIGF0IG9uY2UuIFRoZSBzZXJ2ZXIgd2lsbCB2YWxpZGF0ZSB0aGUgdmFsdWUgZm9yIGVh
Y2ggbm90aWZpY2F0aW9uCiB0eXBlLgoKDQoFBAkCAQYSBMkCAiMKDQoFBAkCAQESBMkCJDkK
DQoFBAkCAQMSBMkCPD0KDQoFBAkCAQgSBMoCBi4KEAoIBAkCAQicCAASBMoCBy0KmQIKBAQJ
AgISBNACAjsaigIgUmVxdWlyZWQuIEZpbmdlcnByaW50IGZvciBvcHRpbWlzdGljIGNvbmN1
cnJlbmN5IHJldHVybmVkIGluIEdldCByZXF1ZXN0cy4KIE11c3QgYmUgcHJvdmlkZWQgZm9y
IFVwZGF0ZSByZXF1ZXN0cy4gSWYgdGhlIHZhbHVlIHByb3ZpZGVkIGRvZXMgbm90IG1hdGNo
CiB0aGUgdmFsdWUga25vd24gdG8gdGhlIHNlcnZlciwgQUJPUlRFRCB3aWxsIGJlIHRocm93
biwgYW5kIHRoZSBjbGllbnQKIHNob3VsZCByZXRyeSB0aGUgcmVhZC1tb2RpZnktd3JpdGUg
Y3ljbGUuCgoNCgUECQICBRIE0AICCAoNCgUECQICARIE0AIJDQoNCgUECQICAxIE0AIQEQoN
CgUECQICCBIE0AISOgoQCggECQICCJwIABIE0AITOQozCgIEChIG1AIA1wIBGiUgU2V0dGlu
Z3MgZm9yIGVhY2ggTm90aWZpY2F0aW9uVHlwZS4KCgsKAwQKARIE1AIIHApDCgQECgIAEgTW
AgITGjUgV2hldGhlciB0aGUgYXNzb2NpYXRlZCBOb3RpZmljYXRpb25UeXBlIGlzIGVuYWJs
ZWQuCgoNCgUECgIABRIE1gICBgoNCgUECgIAARIE1gIHDgoNCgUECgIAAxIE1gIREgowCgIE
CxIG2gIA5QIBGiIgUmVxdWVzdCBvZiBHZXRTZXR0aW5ncyBlbmRwb2ludC4KCgsKAwQLARIE
2gIIGgrHAQoEBAsCABIG3wIC5AIEGrYBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgc2V0dGluZ3MgdG8gcmV0cmlldmUuCiBGb3JtYXQ6CiBvcmdhbml6YXRpb25zL3tv
cmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3NldHRpbmdzIG9yCiBwcm9qZWN0
cy97cHJvamVjdHN9L2xvY2F0aW9ucy97bG9jYXRpb259L3NldHRpbmdzLgoKDQoFBAsCAAUS
BN8CAggKDQoFBAsCAAESBN8CCQ0KDQoFBAsCAAMSBN8CEBEKDwoFBAsCAAgSBt8CEuQCAwoQ
CggECwIACJwIABIE4AIEKgoRCgcECwIACJ8IEgbhAgTjAgUKMwoCBAwSBugCAOsCARolIFJl
cXVlc3Qgb2YgVXBkYXRlU2V0dGluZ3MgZW5kcG9pbnQuCgoLCgMEDAESBOgCCB0KJwoEBAwC
ABIE6gICQRoZIFJlcXVpcmVkLiBOZXcgc2V0dGluZ3MuCgoNCgUEDAIABhIE6gICCgoNCgUE
DAIAARIE6gILEwoNCgUEDAIAAxIE6gIWFwoNCgUEDAIACBIE6gIYQAoQCggEDAIACJwIABIE
6gIZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Notification ===
    # Fields for Notification
    # Field: name Type: 9 ()
    # Field: subject Type: 11 (.google.cloud.advisorynotifications.v1.Subject)
    # Field: messages Type: 11 (.google.cloud.advisorynotifications.v1.Message)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: notification_type Type: 14 (.google.cloud.advisorynotifications.v1.NotificationType)

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Text ===
    # Fields for Text
    # Field: en_text Type: 9 ()
    # Field: localized_text Type: 9 ()
    # Field: localization_state Type: 14 (.google.cloud.advisorynotifications.v1.LocalizationState)

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Subject ===
    # Fields for Subject
    # Field: text Type: 11 (.google.cloud.advisorynotifications.v1.Text)

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Message ===
    # Fields for Message
    # Field: body Type: 11 (.google.cloud.advisorynotifications.v1.Message.Body)
    # Field: attachments Type: 11 (.google.cloud.advisorynotifications.v1.Attachment)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: localization_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Attachment ===
    # Fields for Attachment
    # Field: csv Type: 11 (.google.cloud.advisorynotifications.v1.Csv)
    # Field: display_name Type: 9 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Csv ===
    # Fields for Csv
    # Field: headers Type: 9 ()
    # Field: data_rows Type: 11 (.google.cloud.advisorynotifications.v1.Csv.CsvRow)

# === Message: Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest ===
    # Fields for ListNotificationsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: view Type: 14 (.google.cloud.advisorynotifications.v1.NotificationView)
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse ===
    # Fields for ListNotificationsResponse
    # Field: notifications Type: 11 (.google.cloud.advisorynotifications.v1.Notification)
    # Field: next_page_token Type: 9 ()
    # Field: total_size Type: 5 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest ===
    # Fields for GetNotificationRequest
    # Field: name Type: 9 ()
    # Field: language_code Type: 9 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::Settings ===
    # Fields for Settings
    # Field: name Type: 9 ()
    # Field: notification_settings Type: 11 (.google.cloud.advisorynotifications.v1.Settings.NotificationSettingsEntry)
    # Field: etag Type: 9 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::NotificationSettings ===
    # Fields for NotificationSettings
    # Field: enabled Type: 8 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest ===
    # Fields for GetSettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest ===
    # Fields for UpdateSettingsRequest
    # Field: settings Type: 11 (.google.cloud.advisorynotifications.v1.Settings)

# === Service Client: Google::Cloud::Advisorynotifications::V1::Service::AdvisoryNotificationsServiceClient ===
package Google::Cloud::Advisorynotifications::V1::Service::AdvisoryNotificationsServiceClient;

=pod

=head2 Service Client: Google::Cloud::Advisorynotifications::V1::Service::AdvisoryNotificationsServiceClient

Client stub representing the remote C<AdvisoryNotificationsService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<advisorynotifications.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'advisorynotifications.googleapis.com:443' );

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

sub list_notifications {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.advisorynotifications.v1.AdvisoryNotificationsService',
        method         => 'ListNotifications',
        request        => $req,
        response_class => 'Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse',
    });
}

sub get_notification {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.advisorynotifications.v1.AdvisoryNotificationsService',
        method         => 'GetNotification',
        request        => $req,
        response_class => 'Google::Cloud::Advisorynotifications::V1::Service::Notification',
    });
}

sub get_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.advisorynotifications.v1.AdvisoryNotificationsService',
        method         => 'GetSettings',
        request        => $req,
        response_class => 'Google::Cloud::Advisorynotifications::V1::Service::Settings',
    });
}

sub update_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.advisorynotifications.v1.AdvisoryNotificationsService',
        method         => 'UpdateSettings',
        request        => $req,
        response_class => 'Google::Cloud::Advisorynotifications::V1::Service::Settings',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Advisorynotifications::V1::Service - Compiled Protocol Buffers messages for google/cloud/advisorynotifications/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Advisorynotifications::V1::Service;

    my $msg = Google::Cloud::Advisorynotifications::V1::Service::Notification->new({
        name => $name,
        subject => $subject,
        messages => $messages,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Advisorynotifications::V1::Service::Notification->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/advisorynotifications/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Advisorynotifications::V1::Service::Notification

A notification object for notifying customers about security and privacy
issues.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the notification.
Format:
organizations/{organization}/locations/{location}/notifications/{notification}
or projects/{project}/locations/{location}/notifications/{notification}.

=item * C<< $msg->subject() >> / C<< $msg->subject($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Subject>)

The subject line of the notification.

=item * C<< $msg->messages() >> / C<< $msg->messages($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Message>)

A list of messages in the notification.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the notification was created.

=item * C<< $msg->notification_type() >> / C<< $msg->notification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Advisorynotifications::V1::NotificationType>)

Type of notification

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Text

A text object containing the English text and its localized copies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->en_text() >> / C<< $msg->en_text($value) >>

Type: C<String>

The English copy.

=item * C<< $msg->localized_text() >> / C<< $msg->localized_text($value) >>

Type: C<String>

The requested localized copy (if applicable).

=item * C<< $msg->localization_state() >> / C<< $msg->localization_state($value) >>

Type: C<Enum> (L<Google::Cloud::Advisorynotifications::V1::LocalizationState>)

Status of the localization.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Subject

A subject line of a notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Text>)

The text content.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Message

A message which contains notification details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Message::Body>)

The message content.

=item * C<< $msg->attachments() >> / C<< $msg->attachments($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Attachment>)

The attachments to download.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The Message creation timestamp.

=item * C<< $msg->localization_time() >> / C<< $msg->localization_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when Message was localized

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Attachment

Attachment with specific information about the issue.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->csv() >> / C<< $msg->csv($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Csv>)

A CSV file attachment. Max size is 10 MB.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The title of the attachment.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Csv

A representation of a CSV file attachment, as a list of column headers and
a list of data rows.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<String>

The list of headers for data columns in a CSV file.

=item * C<< $msg->data_rows() >> / C<< $msg->data_rows($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Csv::CsvRow>)

The list of data rows in a CSV file, as string arrays rather than as a
single comma-separated string.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsRequest

Request for fetching all notifications for a given parent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of notifications.
Must be of the form "organizations/{organization}/locations/{location}"
or "projects/{project}/locations/{location}".

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of notifications to return. The service may return
fewer than this value. If unspecified or equal to 0, at most 50
notifications will be returned. The maximum value is 50; values above 50
will be coerced to 50.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token returned from a previous request.
When paginating, all other parameters provided in the request
must match the call that returned the page token.

=item * C<< $msg->view() >> / C<< $msg->view($value) >>

Type: C<Enum> (L<Google::Cloud::Advisorynotifications::V1::NotificationView>)

Specifies which parts of the notification resource should be returned
in the response.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

ISO code for requested localization language.  If unset, will be
interpereted as "en". If the requested language is valid, but not supported
for this notification, English will be returned with an "Not applicable"
LocalizationState. If the ISO code is invalid (i.e. not a real language),
this RPC will throw an error.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::ListNotificationsResponse

Response of ListNotifications endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->notifications() >> / C<< $msg->notifications($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Notification>)

List of notifications under a given parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->total_size() >> / C<< $msg->total_size($value) >>

Type: C<Int32>

Estimation of a total number of notifications.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::GetNotificationRequest

Request for fetching a notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the notification to retrieve.
Format:
organizations/{organization}/locations/{location}/notifications/{notification}
or projects/{projects}/locations/{location}/notifications/{notification}.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

ISO code for requested localization language. If unset, will be
interpereted as "en". If the requested language is valid, but not supported
for this notification, English will be returned with an "Not applicable"
LocalizationState. If the ISO code is invalid (i.e. not a real language),
this RPC will throw an error.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::Settings

Settings for Advisory Notifications.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the settings to retrieve.
Format:
organizations/{organization}/locations/{location}/settings or
projects/{projects}/locations/{location}/settings.

=item * C<< $msg->notification_settings() >> / C<< $msg->notification_settings($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Settings::NotificationSettingsEntry>)

Required. Map of each notification type and its settings to get/set all
settings at once. The server will validate the value for each notification
type.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Required. Fingerprint for optimistic concurrency returned in Get requests.
Must be provided for Update requests. If the value provided does not match
the value known to the server, ABORTED will be thrown, and the client
should retry the read-modify-write cycle.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::NotificationSettings

Settings for each NotificationType.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Whether the associated NotificationType is enabled.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::GetSettingsRequest

Request of GetSettings endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the settings to retrieve.
Format:
organizations/{organization}/locations/{location}/settings or
projects/{projects}/locations/{location}/settings.

=back

=head2 Google::Cloud::Advisorynotifications::V1::Service::UpdateSettingsRequest

Request of UpdateSettings endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->settings() >> / C<< $msg->settings($value) >>

Type: C<Message> (L<Google::Cloud::Advisorynotifications::V1::Service::Settings>)

Required. New settings.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Advisorynotifications::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
