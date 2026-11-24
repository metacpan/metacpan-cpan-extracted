package Google::Cloud::Discoveryengine::V1alpha::DataStore;

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
    eval { require Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig };
    eval { require Google::Cloud::Discoveryengine::V1alpha::Schema };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZGF0YV9zdG9yZS5wcm90
bxIkZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUv
Y2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tbW9uLnByb3RvGkVnb29nbGUvY2xv
dWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZG9jdW1lbnRfcHJvY2Vzc2luZ19jb25maWcu
cHJvdG8aMWdvb2dsZS9jbG91ZC9kaXNjb3ZlcnllbmdpbmUvdjFhbHBoYS9zY2hlbWEucHJv
dG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ixwoKCURhdGFTdG9yZRIXCgRu
YW1lGAEgASgJQgPgQQVSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3Bs
YXlOYW1lEmgKEWluZHVzdHJ5X3ZlcnRpY2FsGAMgASgOMjYuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLkluZHVzdHJ5VmVydGljYWxCA+BBBVIQaW5kdXN0cnlWZXJ0
aWNhbBJZCg5zb2x1dGlvbl90eXBlcxgFIAMoDjIyLmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5Tb2x1dGlvblR5cGVSDXNvbHV0aW9uVHlwZXMSLwoRZGVmYXVsdF9z
Y2hlbWFfaWQYByABKAlCA+BBA1IPZGVmYXVsdFNjaGVtYUlkEmkKDmNvbnRlbnRfY29uZmln
GAYgASgOMj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9y
ZS5Db250ZW50Q29uZmlnQgPgQQVSDWNvbnRlbnRDb25maWcSQAoLY3JlYXRlX3RpbWUYBCAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSVwoNbGFu
Z3VhZ2VfaW5mbxgOIAEoCzIyLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5MYW5ndWFnZUluZm9SDGxhbmd1YWdlSW5mbxJTCgppZHBfY29uZmlnGBUgASgLMi8uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLklkcENvbmZpZ0ID4EEDUglpZHBD
b25maWcSJAoLYWNsX2VuYWJsZWQYGCABKAhCA+BBBVIKYWNsRW5hYmxlZBJgChB3b3Jrc3Bh
Y2VfY29uZmlnGBkgASgLMjUuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LldvcmtzcGFjZUNvbmZpZ1IPd29ya3NwYWNlQ29uZmlnEnwKGmRvY3VtZW50X3Byb2Nlc3Np
bmdfY29uZmlnGBsgASgLMj4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkRvY3VtZW50UHJvY2Vzc2luZ0NvbmZpZ1IYZG9jdW1lbnRQcm9jZXNzaW5nQ29uZmlnElUK
D3N0YXJ0aW5nX3NjaGVtYRgcIAEoCzIsLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFhbHBoYS5TY2hlbWFSDnN0YXJ0aW5nU2NoZW1hIn8KDUNvbnRlbnRDb25maWcSHgoaQ09O
VEVOVF9DT05GSUdfVU5TUEVDSUZJRUQQABIOCgpOT19DT05URU5UEAESFAoQQ09OVEVOVF9S
RVFVSVJFRBACEhIKDlBVQkxJQ19XRUJTSVRFEAMSFAoQR09PR0xFX1dPUktTUEFDRRAEOskB
6kHFAQooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9yZRI/cHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFTdG9yZXMve2RhdGFfc3Rv
cmV9Elhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlv
bnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9IrABCgxMYW5ndWFnZUlu
Zm8SIwoNbGFuZ3VhZ2VfY29kZRgBIAEoCVIMbGFuZ3VhZ2VDb2RlEj0KGG5vcm1hbGl6ZWRf
bGFuZ3VhZ2VfY29kZRgCIAEoCUID4EEDUhZub3JtYWxpemVkTGFuZ3VhZ2VDb2RlEh8KCGxh
bmd1YWdlGAMgASgJQgPgQQNSCGxhbmd1YWdlEhsKBnJlZ2lvbhgEIAEoCUID4EEDUgZyZWdp
b24irQIKD1dvcmtzcGFjZUNvbmZpZxJOCgR0eXBlGAEgASgOMjouZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWFscGhhLldvcmtzcGFjZUNvbmZpZy5UeXBlUgR0eXBlEiwKEmRh
c2hlcl9jdXN0b21lcl9pZBgCIAEoCVIQZGFzaGVyQ3VzdG9tZXJJZCKbAQoEVHlwZRIUChBU
WVBFX1VOU1BFQ0lGSUVEEAASEAoMR09PR0xFX0RSSVZFEAESDwoLR09PR0xFX01BSUwQAhIQ
CgxHT09HTEVfU0lURVMQAxITCg9HT09HTEVfQ0FMRU5EQVIQBBIPCgtHT09HTEVfQ0hBVBAF
EhEKDUdPT0dMRV9HUk9VUFMQBhIPCgtHT09HTEVfS0VFUBAHQpoCCihjb20uZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhQg5EYXRhU3RvcmVQcm90b1ABWlJjbG91ZC5n
b29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVuZ2lu
ZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNsb3Vk
LkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2lu
ZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhhSuY+
CgcSBQ4A1AEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAt
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA7CgkKAgMDEgMVAE8KCQoCAwQSAxYA
OwoJCgIDBRIDFwApCggKAQgSAxkAQQoJCgIIJRIDGQBBCggKAQgSAxoAaQoJCgIICxIDGgBp
CggKAQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwALwoJCgIICBIDHAAvCggKAQgSAx0AQQoJ
CgIIARIDHQBBCggKAQgSAx4ALQoJCgIIJBIDHgAtCggKAQgSAx8AQQoJCgIIKRIDHwBBCggK
AQgSAyAAQAoJCgIILRIDIABAClUKAgQAEgUjAJwBARpIIERhdGFTdG9yZSBjYXB0dXJlcyBn
bG9iYWwgc2V0dGluZ3MgYW5kIGNvbmZpZ3MgYXQgdGhlIERhdGFTdG9yZSBsZXZlbC4KCgoK
AwQAARIDIwgRCgsKAwQABxIEJAIoBAoNCgUEAAedCBIEJAIoBAoxCgQEAAQAEgQrAj4DGiMg
Q29udGVudCBjb25maWcgb2YgdGhlIGRhdGEgc3RvcmUuCgoMCgUEAAQAARIDKwcUCh8KBgQA
BAACABIDLQQjGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQABAACAAESAy0EHgoOCgcEAAQAAgAC
EgMtISIKgAEKBgQABAACARIDMQQTGnEgT25seSBjb250YWlucyBkb2N1bWVudHMgd2l0aG91
dCBhbnkKIFtEb2N1bWVudC5jb250ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuRG9jdW1lbnQuY29udGVudF0uCgoOCgcEAAQAAgEBEgMxBA4KDgoHBAAEAAIB
AhIDMRESCnkKBgQABAACAhIDNQQZGmogT25seSBjb250YWlucyBkb2N1bWVudHMgd2l0aAog
W0RvY3VtZW50LmNvbnRlbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5Eb2N1bWVudC5jb250ZW50XS4KCg4KBwQABAACAgESAzUEFAoOCgcEAAQAAgICEgM1FxgK
QgoGBAAEAAIDEgM4BBcaMyBUaGUgZGF0YSBzdG9yZSBpcyB1c2VkIGZvciBwdWJsaWMgd2Vi
c2l0ZSBzZWFyY2guCgoOCgcEAAQAAgMBEgM4BBIKDgoHBAAEAAIDAhIDOBUWCr4BCgYEAAQA
AgQSAz0EGRquASBUaGUgZGF0YSBzdG9yZSBpcyB1c2VkIGZvciB3b3Jrc3BhY2Ugc2VhcmNo
LiBEZXRhaWxzIG9mIHdvcmtzcGFjZQogZGF0YSBzdG9yZSBhcmUgc3BlY2lmaWVkIGluIHRo
ZQogW1dvcmtzcGFjZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLldvcmtzcGFjZUNvbmZpZ10uCgoOCgcEAAQAAgQBEgM9BBQKDgoHBAAEAAIEAhIDPRcY
CoUCCgQEAAIAEgNGAjwa9wEgSW1tdXRhYmxlLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9m
IHRoZSBkYXRhIHN0b3JlLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97
ZGF0YV9zdG9yZV9pZH1gLgoKIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQg
c3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTAyNAogY2hhcmFjdGVycy4KCgwKBQQA
AgAFEgNGAggKDAoFBAACAAESA0YJDQoMCgUEAAIAAxIDRhARCgwKBQQAAgAIEgNGEjsKDwoI
BAACAAicCAASA0YTOgq8AQoEBAACARIDTAJDGq4BIFJlcXVpcmVkLiBUaGUgZGF0YSBzdG9y
ZSBkaXNwbGF5IG5hbWUuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBz
dHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMjgKIGNoYXJhY3RlcnMuIE90aGVyd2lz
ZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1cm5lZC4KCgwKBQQAAgEFEgNM
AggKDAoFBAACAQESA0wJFQoMCgUEAAIBAxIDTBgZCgwKBQQAAgEIEgNMGkIKDwoIBAACAQic
CAASA0wbQQpPCgQEAAICEgRPAlAwGkEgSW1tdXRhYmxlLiBUaGUgaW5kdXN0cnkgdmVydGlj
YWwgdGhhdCB0aGUgZGF0YSBzdG9yZSByZWdpc3RlcnMuCgoMCgUEAAICBhIDTwISCgwKBQQA
AgIBEgNPEyQKDAoFBAACAgMSA08nKAoMCgUEAAICCBIDUAYvCg8KCAQAAgIInAgAEgNQBy4K
4gIKBAQAAgMSA1gCKxrUAiBUaGUgc29sdXRpb25zIHRoYXQgdGhlIGRhdGEgc3RvcmUgZW5y
b2xscy4gQXZhaWxhYmxlIHNvbHV0aW9ucyBmb3IgZWFjaAogW2luZHVzdHJ5X3ZlcnRpY2Fs
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRGF0YVN0b3JlLmluZHVz
dHJ5X3ZlcnRpY2FsXToKCiAqIGBNRURJQWA6IGBTT0xVVElPTl9UWVBFX1JFQ09NTUVOREFU
SU9OYCBhbmQgYFNPTFVUSU9OX1RZUEVfU0VBUkNIYC4KICogYFNJVEVfU0VBUkNIYDogYFNP
TFVUSU9OX1RZUEVfU0VBUkNIYCBpcyBhdXRvbWF0aWNhbGx5IGVucm9sbGVkLiBPdGhlcgog
ICBzb2x1dGlvbnMgY2Fubm90IGJlIGVucm9sbGVkLgoKDAoFBAACAwQSA1gCCgoMCgUEAAID
BhIDWAsXCgwKBQQAAgMBEgNYGCYKDAoFBAACAwMSA1gpKgqJAQoEBAACBBIDXQJLGnwgT3V0
cHV0IG9ubHkuIFRoZSBpZCBvZiB0aGUgZGVmYXVsdAogW1NjaGVtYV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNjaGVtYV0gYXNzY29jaWF0ZWQgdG8gdGhpcwog
ZGF0YSBzdG9yZS4KCgwKBQQAAgQFEgNdAggKDAoFBAACBAESA10JGgoMCgUEAAIEAxIDXR0e
CgwKBQQAAgQIEgNdH0oKDwoIBAACBAicCAASA10gSQrfAQoEBAACBRIDYgJNGtEBIEltbXV0
YWJsZS4gVGhlIGNvbnRlbnQgY29uZmlnIG9mIHRoZSBkYXRhIHN0b3JlLiBJZiB0aGlzIGZp
ZWxkIGlzIHVuc2V0LAogdGhlIHNlcnZlciBiZWhhdmlvciBkZWZhdWx0cyB0bwogW0NvbnRl
bnRDb25maWcuTk9fQ09OVEVOVF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFs
cGhhLkRhdGFTdG9yZS5Db250ZW50Q29uZmlnLk5PX0NPTlRFTlRdLgoKDAoFBAACBQYSA2IC
DwoMCgUEAAIFARIDYhAeCgwKBQQAAgUDEgNiISIKDAoFBAACBQgSA2IjTAoPCggEAAIFCJwI
ABIDYiRLCncKBAQAAgYSBGYCZzIaaSBPdXRwdXQgb25seS4gVGltZXN0YW1wIHRoZQogW0Rh
dGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9y
ZV0gd2FzIGNyZWF0ZWQgYXQuCgoMCgUEAAIGBhIDZgIbCgwKBQQAAgYBEgNmHCcKDAoFBAAC
BgMSA2YqKwoMCgUEAAIGCBIDZwYxCg8KCAQAAgYInAgAEgNnBzAKKwoEBAACBxIDagIiGh4g
TGFuZ3VhZ2UgaW5mbyBmb3IgRGF0YVN0b3JlLgoKDAoFBAACBwYSA2oCDgoMCgUEAAIHARID
ag8cCgwKBQQAAgcDEgNqHyEKRgoEBAACCBIDbQJIGjkgT3V0cHV0IG9ubHkuIERhdGEgc3Rv
cmUgbGV2ZWwgaWRlbnRpdHkgcHJvdmlkZXIgY29uZmlnLgoKDAoFBAACCAYSA20CCwoMCgUE
AAIIARIDbQwWCgwKBQQAAggDEgNtGRsKDAoFBAACCAgSA20cRwoPCggEAAIICJwIABIDbR1G
CsEGCgQEAAIJEgSAAQJCGrIGIEltbXV0YWJsZS4gV2hldGhlciBkYXRhIGluIHRoZQogW0Rh
dGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9y
ZV0gaGFzIEFDTAogaW5mb3JtYXRpb24uIElmIHNldCB0byBgdHJ1ZWAsIHRoZSBzb3VyY2Ug
ZGF0YSBtdXN0IGhhdmUgQUNMLiBBQ0wgd2lsbCBiZQogaW5nZXN0ZWQgd2hlbiBkYXRhIGlz
IGluZ2VzdGVkIGJ5CiBbRG9jdW1lbnRTZXJ2aWNlLkltcG9ydERvY3VtZW50c11bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRvY3VtZW50U2VydmljZS5JbXBvcnRE
b2N1bWVudHNdCiBtZXRob2RzLgoKIFdoZW4gQUNMIGlzIGVuYWJsZWQgZm9yIHRoZQogW0Rh
dGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFTdG9y
ZV0sCiBbRG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5E
b2N1bWVudF0gY2FuJ3QgYmUgYWNjZXNzZWQKIGJ5IGNhbGxpbmcKIFtEb2N1bWVudFNlcnZp
Y2UuR2V0RG9jdW1lbnRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5E
b2N1bWVudFNlcnZpY2UuR2V0RG9jdW1lbnRdCiBvcgogW0RvY3VtZW50U2VydmljZS5MaXN0
RG9jdW1lbnRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRG9jdW1l
bnRTZXJ2aWNlLkxpc3REb2N1bWVudHNdLgoKIEN1cnJlbnRseSBBQ0wgaXMgb25seSBzdXBw
b3J0ZWQgaW4gYEdFTkVSSUNgIGluZHVzdHJ5IHZlcnRpY2FsIHdpdGgKIG5vbi1gUFVCTElD
X1dFQlNJVEVgIGNvbnRlbnQgY29uZmlnLgoKDQoFBAACCQUSBIABAgYKDQoFBAACCQESBIAB
BxIKDQoFBAACCQMSBIABFRcKDQoFBAACCQgSBIABGEEKEAoIBAACCQicCAASBIABGUAKywIK
BAQAAgoSBIcBAigavAIgQ29uZmlnIHRvIHN0b3JlIGRhdGEgc3RvcmUgdHlwZSBjb25maWd1
cmF0aW9uIGZvciB3b3Jrc3BhY2UgZGF0YS4gVGhpcwogbXVzdCBiZSBzZXQgd2hlbgogW0Rh
dGFTdG9yZS5jb250ZW50X2NvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLkRhdGFTdG9yZS5jb250ZW50X2NvbmZpZ10KIGlzIHNldCBhcwogW0RhdGFTdG9y
ZS5Db250ZW50Q29uZmlnLkdPT0dMRV9XT1JLU1BBQ0VdW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmUuQ29udGVudENvbmZpZy5HT09HTEVfV09SS1NQ
QUNFXS4KCg0KBQQAAgoGEgSHAQIRCg0KBQQAAgoBEgSHARIiCg0KBQQAAgoDEgSHASUnCkgK
BAQAAgsSBIoBAjsaOiBDb25maWd1cmF0aW9uIGZvciBEb2N1bWVudCB1bmRlcnN0YW5kaW5n
IGFuZCBlbnJpY2htZW50LgoKDQoFBAACCwYSBIoBAhoKDQoFBAACCwESBIoBGzUKDQoFBAAC
CwMSBIoBODoK7gUKBAQAAgwSBJsBAh4a3wUgVGhlIHN0YXJ0IHNjaGVtYSB0byB1c2UgZm9y
IHRoaXMKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBo
YS5EYXRhU3RvcmVdIHdoZW4KIHByb3Zpc2lvbmluZyBpdC4gSWYgdW5zZXQsIGEgZGVmYXVs
dCB2ZXJ0aWNhbCBzcGVjaWFsaXplZCBzY2hlbWEgd2lsbCBiZQogdXNlZC4KCiBUaGlzIGZp
ZWxkIGlzIG9ubHkgdXNlZCBieSBbQ3JlYXRlRGF0YVN0b3JlXVtdIEFQSSwgYW5kIHdpbGwg
YmUgaWdub3JlZCBpZgogdXNlZCBpbiBvdGhlciBBUElzLiBUaGlzIGZpZWxkIHdpbGwgYmUg
b21pdHRlZCBmcm9tIGFsbCBBUEkgcmVzcG9uc2VzCiBpbmNsdWRpbmcgW0NyZWF0ZURhdGFT
dG9yZV1bXSBBUEkuIFRvIHJldHJpZXZlIGEgc2NoZW1hIG9mIGEKIFtEYXRhU3RvcmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdLCB1c2UKIFtT
Y2hlbWFTZXJ2aWNlLkdldFNjaGVtYV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWFscGhhLlNjaGVtYVNlcnZpY2UuR2V0U2NoZW1hXQogQVBJIGluc3RlYWQuCgogVGhlIHBy
b3ZpZGVkIHNjaGVtYSB3aWxsIGJlIHZhbGlkYXRlZCBhZ2FpbnN0IGNlcnRhaW4gcnVsZXMg
b24gc2NoZW1hLgogTGVhcm4gbW9yZSBmcm9tIFt0aGlzCiBkb2NdKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9nZW5lcmF0aXZlLWFpLWFwcC1idWlsZGVyL2RvY3MvcHJvdmlkZS1zY2hl
bWEpLgoKDQoFBAACDAYSBJsBAggKDQoFBAACDAESBJsBCRgKDQoFBAACDAMSBJsBGx0KLAoC
BAESBp8BALABARoeIExhbmd1YWdlIGluZm8gZm9yIERhdGFTdG9yZS4KCgsKAwQBARIEnwEI
FAo0CgQEAQIAEgShAQIbGiYgVGhlIGxhbmd1YWdlIGNvZGUgZm9yIHRoZSBEYXRhU3RvcmUu
CgoNCgUEAQIABRIEoQECCAoNCgUEAQIAARIEoQEJFgoNCgUEAQIAAxIEoQEZGgq6AQoEBAEC
ARIGpgECpwEyGqkBIE91dHB1dCBvbmx5LiBUaGlzIGlzIHRoZSBub3JtYWxpemVkIGZvcm0g
b2YgbGFuZ3VhZ2VfY29kZS4KIEUuZy46IGxhbmd1YWdlX2NvZGUgb2YgYGVuLUdCYCwgYGVu
X0dCYCwgYGVuLVVLYCBvciBgZW4tZ2JgCiB3aWxsIGhhdmUgbm9ybWFsaXplZF9sYW5ndWFn
ZV9jb2RlIG9mIGBlbi1HQmAuCgoNCgUEAQIBBRIEpgECCAoNCgUEAQIBARIEpgEJIQoNCgUE
AQIBAxIEpgEkJQoNCgUEAQIBCBIEpwEGMQoQCggEAQIBCJwIABIEpwEHMAqDAQoEBAECAhIE
qwECQhp1IE91dHB1dCBvbmx5LiBMYW5ndWFnZSBwYXJ0IG9mIG5vcm1hbGl6ZWRfbGFuZ3Vh
Z2VfY29kZS4KIEUuZy46IGBlbi1VU2AgLT4gYGVuYCwgYHpoLUhhbnMtSEtgIC0+IGB6aGAs
IGBlbmAgLT4gYGVuYC4KCg0KBQQBAgIFEgSrAQIICg0KBQQBAgIBEgSrAQkRCg0KBQQBAgID
EgSrARQVCg0KBQQBAgIIEgSrARZBChAKCAQBAgIInAgAEgSrARdACosBCgQEAQIDEgSvAQJA
Gn0gT3V0cHV0IG9ubHkuIFJlZ2lvbiBwYXJ0IG9mIG5vcm1hbGl6ZWRfbGFuZ3VhZ2VfY29k
ZSwgaWYgcHJlc2VudC4KIEUuZy46IGBlbi1VU2AgLT4gYFVTYCwgYHpoLUhhbnMtSEtgIC0+
IGBIS2AsIGBlbmAgLT4gYGAuCgoNCgUEAQIDBRIErwECCAoNCgUEAQIDARIErwEJDwoNCgUE
AQIDAxIErwESEwoNCgUEAQIDCBIErwEUPwoQCggEAQIDCJwIABIErwEVPgpQCgIEAhIGswEA
1AEBGkIgQ29uZmlnIHRvIHN0b3JlIGRhdGEgc3RvcmUgdHlwZSBjb25maWd1cmF0aW9uIGZv
ciB3b3Jrc3BhY2UgZGF0YQoKCwoDBAIBEgSzAQgXClEKBAQCBAASBrUBAs0BAxpBIFNwZWNp
ZmllcyB0aGUgdHlwZSBvZiBXb3Jrc3BhY2UgQXBwIHN1cHBvcnRlZCBieSB0aGlzIERhdGFT
dG9yZQoKDQoFBAIEAAESBLUBBwsKPAoGBAIEAAIAEgS3AQQZGiwgRGVmYXVsdHMgdG8gYW4g
dW5zcGVjaWZpZWQgV29ya3NwYWNlIHR5cGUuCgoPCgcEAgQAAgABEgS3AQQUCg8KBwQCBAAC
AAISBLcBFxgKOgoGBAIEAAIBEgS6AQQVGiogV29ya3NwYWNlIERhdGEgU3RvcmUgY29udGFp
bnMgRHJpdmUgZGF0YQoKDwoHBAIEAAIBARIEugEEEAoPCgcEAgQAAgECEgS6ARMUCjkKBgQC
BAACAhIEvQEEFBopIFdvcmtzcGFjZSBEYXRhIFN0b3JlIGNvbnRhaW5zIE1haWwgZGF0YQoK
DwoHBAIEAAICARIEvQEEDwoPCgcEAgQAAgICEgS9ARITCjoKBgQCBAACAxIEwAEEFRoqIFdv
cmtzcGFjZSBEYXRhIFN0b3JlIGNvbnRhaW5zIFNpdGVzIGRhdGEKCg8KBwQCBAACAwESBMAB
BBAKDwoHBAIEAAIDAhIEwAETFAo9CgYEAgQAAgQSBMMBBBgaLSBXb3Jrc3BhY2UgRGF0YSBT
dG9yZSBjb250YWlucyBDYWxlbmRhciBkYXRhCgoPCgcEAgQAAgQBEgTDAQQTCg8KBwQCBAAC
BAISBMMBFhcKOQoGBAIEAAIFEgTGAQQUGikgV29ya3NwYWNlIERhdGEgU3RvcmUgY29udGFp
bnMgQ2hhdCBkYXRhCgoPCgcEAgQAAgUBEgTGAQQPCg8KBwQCBAACBQISBMYBEhMKOwoGBAIE
AAIGEgTJAQQWGisgV29ya3NwYWNlIERhdGEgU3RvcmUgY29udGFpbnMgR3JvdXBzIGRhdGEK
Cg8KBwQCBAACBgESBMkBBBEKDwoHBAIEAAIGAhIEyQEUFQo5CgYEAgQAAgcSBMwBBBQaKSBX
b3Jrc3BhY2UgRGF0YSBTdG9yZSBjb250YWlucyBLZWVwIGRhdGEKCg8KBwQCBAACBwESBMwB
BA8KDwoHBAIEAAIHAhIEzAESEwoxCgQEAgIAEgTQAQIQGiMgVGhlIEdvb2dsZSBXb3Jrc3Bh
Y2UgZGF0YSBzb3VyY2UuCgoNCgUEAgIABhIE0AECBgoNCgUEAgIAARIE0AEHCwoNCgUEAgIA
AxIE0AEODwouCgQEAgIBEgTTAQIgGiAgT2JmdXNjYXRlZCBEYXNoZXIgY3VzdG9tZXIgSUQu
CgoNCgUEAgIBBRIE0wECCAoNCgUEAgIBARIE0wEJGwoNCgUEAgIBAxIE0wEeH2IGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore ===
    # Fields for DataStore
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: industry_vertical Type: 14 (.google.cloud.discoveryengine.v1alpha.IndustryVertical)
    # Field: solution_types Type: 14 (.google.cloud.discoveryengine.v1alpha.SolutionType)
    # Field: default_schema_id Type: 9 ()
    # Field: content_config Type: 14 (.google.cloud.discoveryengine.v1alpha.DataStore.ContentConfig)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: language_info Type: 11 (.google.cloud.discoveryengine.v1alpha.LanguageInfo)
    # Field: idp_config Type: 11 (.google.cloud.discoveryengine.v1alpha.IdpConfig)
    # Field: acl_enabled Type: 8 ()
    # Field: workspace_config Type: 11 (.google.cloud.discoveryengine.v1alpha.WorkspaceConfig)
    # Field: document_processing_config Type: 11 (.google.cloud.discoveryengine.v1alpha.DocumentProcessingConfig)
    # Field: starting_schema Type: 11 (.google.cloud.discoveryengine.v1alpha.Schema)

# Enum: DataStore::ContentConfig
our $DataStore_CONTENT_CONFIG_UNSPECIFIED = 0;
our $DataStore_NO_CONTENT = 1;
our $DataStore_CONTENT_REQUIRED = 2;
our $DataStore_PUBLIC_WEBSITE = 3;
our $DataStore_GOOGLE_WORKSPACE = 4;

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo ===
    # Fields for LanguageInfo
    # Field: language_code Type: 9 ()
    # Field: normalized_language_code Type: 9 ()
    # Field: language Type: 9 ()
    # Field: region Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig ===
    # Fields for WorkspaceConfig
    # Field: type Type: 14 (.google.cloud.discoveryengine.v1alpha.WorkspaceConfig.Type)
    # Field: dasher_customer_id Type: 9 ()

# Enum: WorkspaceConfig::Type
our $WorkspaceConfig_TYPE_UNSPECIFIED = 0;
our $WorkspaceConfig_GOOGLE_DRIVE = 1;
our $WorkspaceConfig_GOOGLE_MAIL = 2;
our $WorkspaceConfig_GOOGLE_SITES = 3;
our $WorkspaceConfig_GOOGLE_CALENDAR = 4;
our $WorkspaceConfig_GOOGLE_CHAT = 5;
our $WorkspaceConfig_GOOGLE_GROUPS = 6;
our $WorkspaceConfig_GOOGLE_KEEP = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::DataStore - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/data_store.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::DataStore;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore->new({
        name => $name,
        display_name => $display_name,
        industry_vertical => $industry_vertical,
        solution_types => $solution_types,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/data_store.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStore::DataStore

DataStore captures global settings and configs at the DataStore level.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The full resource name of the data store.
Format:
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The data store display name.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->industry_vertical() >> / C<< $msg->industry_vertical($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::IndustryVertical>)

Immutable. The industry vertical that the data store registers.

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::SolutionType>)

The solutions that the data store enrolls. Available solutions for each
[industry_vertical][google.cloud.discoveryengine.v1alpha.DataStore.industry_vertical]:

* `MEDIA`: `SOLUTION_TYPE_RECOMMENDATION` and `SOLUTION_TYPE_SEARCH`.
* `SITE_SEARCH`: `SOLUTION_TYPE_SEARCH` is automatically enrolled. Other
  solutions cannot be enrolled.

=item * C<< $msg->default_schema_id() >> / C<< $msg->default_schema_id($value) >>

Type: C<String>

Output only. The id of the default
[Schema][google.cloud.discoveryengine.v1alpha.Schema] asscociated to this
data store.

=item * C<< $msg->content_config() >> / C<< $msg->content_config($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::ContentConfig>)

Immutable. The content config of the data store. If this field is unset,
the server behavior defaults to
[ContentConfig.NO_CONTENT][google.cloud.discoveryengine.v1alpha.DataStore.ContentConfig.NO_CONTENT].

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] was created at.

=item * C<< $msg->language_info() >> / C<< $msg->language_info($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo>)

Language info for DataStore.

=item * C<< $msg->idp_config() >> / C<< $msg->idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::IdpConfig>)

Output only. Data store level identity provider config.

=item * C<< $msg->acl_enabled() >> / C<< $msg->acl_enabled($value) >>

Type: C<Bool>

Immutable. Whether data in the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] has ACL
information. If set to `true`, the source data must have ACL. ACL will be
ingested when data is ingested by
[DocumentService.ImportDocuments][google.cloud.discoveryengine.v1alpha.DocumentService.ImportDocuments]
methods.

When ACL is enabled for the
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore],
[Document][google.cloud.discoveryengine.v1alpha.Document] can't be accessed
by calling
[DocumentService.GetDocument][google.cloud.discoveryengine.v1alpha.DocumentService.GetDocument]
or
[DocumentService.ListDocuments][google.cloud.discoveryengine.v1alpha.DocumentService.ListDocuments].

Currently ACL is only supported in `GENERIC` industry vertical with
non-`PUBLIC_WEBSITE` content config.

=item * C<< $msg->workspace_config() >> / C<< $msg->workspace_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig>)

Config to store data store type configuration for workspace data. This
must be set when
[DataStore.content_config][google.cloud.discoveryengine.v1alpha.DataStore.content_config]
is set as
[DataStore.ContentConfig.GOOGLE_WORKSPACE][google.cloud.discoveryengine.v1alpha.DataStore.ContentConfig.GOOGLE_WORKSPACE].

=item * C<< $msg->document_processing_config() >> / C<< $msg->document_processing_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::DocumentProcessingConfig::DocumentProcessingConfig>)

Configuration for Document understanding and enrichment.

=item * C<< $msg->starting_schema() >> / C<< $msg->starting_schema($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Schema::Schema>)

The start schema to use for this
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] when
provisioning it. If unset, a default vertical specialized schema will be
used.

This field is only used by [CreateDataStore][] API, and will be ignored if
used in other APIs. This field will be omitted from all API responses
including [CreateDataStore][] API. To retrieve a schema of a
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], use
[SchemaService.GetSchema][google.cloud.discoveryengine.v1alpha.SchemaService.GetSchema]
API instead.

The provided schema will be validated against certain rules on schema.
Learn more from [this
doc](https://cloud.google.com/generative-ai-app-builder/docs/provide-schema).

=back

=head3 Enum: DataStore::ContentConfig

=over 4

=item * C<CONTENT_CONFIG_UNSPECIFIED> => C<0>

=item * C<NO_CONTENT> => C<1>

=item * C<CONTENT_REQUIRED> => C<2>

=item * C<PUBLIC_WEBSITE> => C<3>

=item * C<GOOGLE_WORKSPACE> => C<4>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStore::LanguageInfo

Language info for DataStore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language code for the DataStore.

=item * C<< $msg->normalized_language_code() >> / C<< $msg->normalized_language_code($value) >>

Type: C<String>

Output only. This is the normalized form of language_code.
E.g.: language_code of `en-GB`, `en_GB`, `en-UK` or `en-gb`
will have normalized_language_code of `en-GB`.

=item * C<< $msg->language() >> / C<< $msg->language($value) >>

Type: C<String>

Output only. Language part of normalized_language_code.
E.g.: `en-US` -> `en`, `zh-Hans-HK` -> `zh`, `en` -> `en`.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

Output only. Region part of normalized_language_code, if present.
E.g.: `en-US` -> `US`, `zh-Hans-HK` -> `HK`, `en` -> ``.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::DataStore::WorkspaceConfig

Config to store data store type configuration for workspace data

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::WorkspaceConfig::Type>)

The Google Workspace data source.

=item * C<< $msg->dasher_customer_id() >> / C<< $msg->dasher_customer_id($value) >>

Type: C<String>

Obfuscated Dasher customer ID.

=back

=head3 Enum: WorkspaceConfig::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<GOOGLE_DRIVE> => C<1>

=item * C<GOOGLE_MAIL> => C<2>

=item * C<GOOGLE_SITES> => C<3>

=item * C<GOOGLE_CALENDAR> => C<4>

=item * C<GOOGLE_CHAT> => C<5>

=item * C<GOOGLE_GROUPS> => C<6>

=item * C<GOOGLE_KEEP> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::DataStore::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
