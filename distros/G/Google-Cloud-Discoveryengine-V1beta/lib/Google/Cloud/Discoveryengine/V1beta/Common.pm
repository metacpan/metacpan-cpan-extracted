package Google::Cloud::Discoveryengine::V1beta::Common;

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
    eval { require Google::Type::Latlng };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9jb21tb24ucHJvdG8SI2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhhnb29nbGUvdHlwZS9s
YXRsbmcucHJvdG8irgEKCEludGVydmFsEhoKB21pbmltdW0YASABKAFIAFIHbWluaW11bRIt
ChFleGNsdXNpdmVfbWluaW11bRgCIAEoAUgAUhBleGNsdXNpdmVNaW5pbXVtEhoKB21heGlt
dW0YAyABKAFIAVIHbWF4aW11bRItChFleGNsdXNpdmVfbWF4aW11bRgEIAEoAUgBUhBleGNs
dXNpdmVNYXhpbXVtQgUKA21pbkIFCgNtYXgiPwoPQ3VzdG9tQXR0cmlidXRlEhIKBHRleHQY
ASADKAlSBHRleHQSGAoHbnVtYmVycxgCIAMoAVIHbnVtYmVycyLIAgoIVXNlckluZm8SFwoH
dXNlcl9pZBgBIAEoCVIGdXNlcklkEh0KCnVzZXJfYWdlbnQYAiABKAlSCXVzZXJBZ2VudBIg
Cgl0aW1lX3pvbmUYAyABKAlCA+BBAVIIdGltZVpvbmUScAoQcHJlY2lzZV9sb2NhdGlvbhgE
IAEoCzI9Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJJbmZvLlBy
ZWNpc2VMb2NhdGlvbkIG4EEE4EEBUg9wcmVjaXNlTG9jYXRpb24acAoPUHJlY2lzZUxvY2F0
aW9uEjAKBXBvaW50GAEgASgLMhMuZ29vZ2xlLnR5cGUuTGF0TG5nQgPgQQFIAFIFcG9pbnQS
HwoHYWRkcmVzcxgCIAEoCUID4EEBSABSB2FkZHJlc3NCCgoIbG9jYXRpb24iMAoPRW1iZWRk
aW5nQ29uZmlnEh0KCmZpZWxkX3BhdGgYASABKAlSCWZpZWxkUGF0aCIkCgpEb3VibGVMaXN0
EhYKBnZhbHVlcxgBIAMoAVIGdmFsdWVzItcCCglJZHBDb25maWcSUQoIaWRwX3R5cGUYASAB
KA4yNi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5JZHBDb25maWcuSWRw
VHlwZVIHaWRwVHlwZRJwChNleHRlcm5hbF9pZHBfY29uZmlnGAIgASgLMkAuZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuSWRwQ29uZmlnLkV4dGVybmFsSWRwQ29uZmln
UhFleHRlcm5hbElkcENvbmZpZxpDChFFeHRlcm5hbElkcENvbmZpZxIuChN3b3JrZm9yY2Vf
cG9vbF9uYW1lGAEgASgJUhF3b3JrZm9yY2VQb29sTmFtZSJACgdJZHBUeXBlEhgKFElEUF9U
WVBFX1VOU1BFQ0lGSUVEEAASCgoGR1NVSVRFEAESDwoLVEhJUkRfUEFSVFkQAiKAAQoJUHJp
bmNpcGFsEhkKB3VzZXJfaWQYASABKAlIAFIGdXNlcklkEhsKCGdyb3VwX2lkGAIgASgJSABS
B2dyb3VwSWQSLgoSZXh0ZXJuYWxfZW50aXR5X2lkGAMgASgJSABSEGV4dGVybmFsRW50aXR5
SWRCCwoJcHJpbmNpcGFsIugBChRIZWFsdGhjYXJlRmhpckNvbmZpZxI8ChplbmFibGVfY29u
ZmlndXJhYmxlX3NjaGVtYRgBIAEoCFIYZW5hYmxlQ29uZmlndXJhYmxlU2NoZW1hElkKKmVu
YWJsZV9zdGF0aWNfaW5kZXhpbmdfZm9yX2JhdGNoX2luZ2VzdGlvbhgCIAEoCFIlZW5hYmxl
U3RhdGljSW5kZXhpbmdGb3JCYXRjaEluZ2VzdGlvbhI3ChVpbml0aWFsX2ZpbHRlcl9ncm91
cHMYBCADKAlCA+BBAVITaW5pdGlhbEZpbHRlckdyb3VwcyL8AQoTU2VhcmNoTGlua1Byb21v
dGlvbhIZCgV0aXRsZRgBIAEoCUID4EECUgV0aXRsZRIVCgN1cmkYAiABKAlCA+BBAVIDdXJp
EksKCGRvY3VtZW50GAYgASgJQi/gQQH6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9Eb2N1bWVudFIIZG9jdW1lbnQSIAoJaW1hZ2VfdXJpGAMgASgJQgPgQQFSCGltYWdl
VXJpEiUKC2Rlc2NyaXB0aW9uGAQgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEh0KB2VuYWJsZWQY
BSABKAhCA+BBAVIHZW5hYmxlZCpiChBJbmR1c3RyeVZlcnRpY2FsEiEKHUlORFVTVFJZX1ZF
UlRJQ0FMX1VOU1BFQ0lGSUVEEAASCwoHR0VORVJJQxABEgkKBU1FRElBEAISEwoPSEVBTFRI
Q0FSRV9GSElSEAcqvwEKDFNvbHV0aW9uVHlwZRIdChlTT0xVVElPTl9UWVBFX1VOU1BFQ0lG
SUVEEAASIAocU09MVVRJT05fVFlQRV9SRUNPTU1FTkRBVElPThABEhgKFFNPTFVUSU9OX1RZ
UEVfU0VBUkNIEAISFgoSU09MVVRJT05fVFlQRV9DSEFUEAMSIQodU09MVVRJT05fVFlQRV9H
RU5FUkFUSVZFX0NIQVQQBBIZChVTT0xVVElPTl9UWVBFX0FJX01PREUQBSpoCg1TZWFyY2hV
c2VDYXNlEh8KG1NFQVJDSF9VU0VfQ0FTRV9VTlNQRUNJRklFRBAAEhoKFlNFQVJDSF9VU0Vf
Q0FTRV9TRUFSQ0gQARIaChZTRUFSQ0hfVVNFX0NBU0VfQlJPV1NFEAIqXwoKU2VhcmNoVGll
chIbChdTRUFSQ0hfVElFUl9VTlNQRUNJRklFRBAAEhgKFFNFQVJDSF9USUVSX1NUQU5EQVJE
EAESGgoWU0VBUkNIX1RJRVJfRU5URVJQUklTRRACKkMKC1NlYXJjaEFkZE9uEh0KGVNFQVJD
SF9BRERfT05fVU5TUEVDSUZJRUQQABIVChFTRUFSQ0hfQUREX09OX0xMTRABKpsEChBTdWJz
Y3JpcHRpb25UaWVyEiEKHVNVQlNDUklQVElPTl9USUVSX1VOU1BFQ0lGSUVEEAASHAoYU1VC
U0NSSVBUSU9OX1RJRVJfU0VBUkNIEAESKgomU1VCU0NSSVBUSU9OX1RJRVJfU0VBUkNIX0FO
RF9BU1NJU1RBTlQQAhIhCh1TVUJTQ1JJUFRJT05fVElFUl9OT1RFQk9PS19MTRADEiYKIlNV
QlNDUklQVElPTl9USUVSX0ZST05UTElORV9XT1JLRVIQBBIoCiRTVUJTQ1JJUFRJT05fVElF
Ul9BR0VOVFNQQUNFX1NUQVJURVIQChIpCiVTVUJTQ1JJUFRJT05fVElFUl9BR0VOVFNQQUNF
X0JVU0lORVNTEAYSIAocU1VCU0NSSVBUSU9OX1RJRVJfRU5URVJQUklTRRAHEikKJVNVQlND
UklQVElPTl9USUVSX0VOVEVSUFJJU0VfRU1FUkdJTkcQDxIZChVTVUJTQ1JJUFRJT05fVElF
Ul9FRFUQCBIdChlTVUJTQ1JJUFRJT05fVElFUl9FRFVfUFJPEAkSIgoeU1VCU0NSSVBUSU9O
X1RJRVJfRURVX0VNRVJHSU5HEAsSJgoiU1VCU0NSSVBUSU9OX1RJRVJfRURVX1BST19FTUVS
R0lORxAMEicKI1NVQlNDUklQVElPTl9USUVSX0ZST05UTElORV9TVEFSVEVSEA0qtwEKEFN1
YnNjcmlwdGlvblRlcm0SIQodU1VCU0NSSVBUSU9OX1RFUk1fVU5TUEVDSUZJRUQQABIfChtT
VUJTQ1JJUFRJT05fVEVSTV9PTkVfTU9OVEgQARIeChpTVUJTQ1JJUFRJT05fVEVSTV9PTkVf
WUVBUhACEiEKHVNVQlNDUklQVElPTl9URVJNX1RIUkVFX1lFQVJTEAMSHAoYU1VCU0NSSVBU
SU9OX1RFUk1fQ1VTVE9NEAZCnRIKJ2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YUILQ29tbW9uUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3Zlcnll
bmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIP
RElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHK
AiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6
OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRh6kHmAQolZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0JyYW5jaBJRcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9Empwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259
L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h96kFtCilkaXNjb3Zl
cnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvbhJAcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufepBUgonZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uEidwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn3qQXcKLGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlz
LmNvbS9SYW5raW5nQ29uZmlnEkdwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vcmFua2luZ0NvbmZpZ3Mve3JhbmtpbmdfY29uZmlnfepB0gIKL2Rpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9Db21wbGV0aW9uQ29uZmlnElBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vY29tcGxl
dGlvbkNvbmZpZxJpcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nv
bGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3JlfS9jb21wbGV0
aW9uQ29uZmlnEmJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29s
bGVjdGlvbnMve2NvbGxlY3Rpb259L2VuZ2luZXMve2VuZ2luZX0vY29tcGxldGlvbkNvbmZp
Z+pBnQEKOmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9CaWxsaW5nQWNjb3VudExp
Y2Vuc2VDb25maWcSX2JpbGxpbmdBY2NvdW50cy97YmlsbGluZ19hY2NvdW50fS9iaWxsaW5n
QWNjb3VudExpY2Vuc2VDb25maWdzL3tiaWxsaW5nX2FjY291bnRfbGljZW5zZV9jb25maWd9
6kF0CituZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRHYXRld2F5EkVwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRHYXRld2F5cy97YWdl
bnRfZ2F0ZXdheX3qQWIKIm1vZGVsYXJtb3IuZ29vZ2xlYXBpcy5jb20vVGVtcGxhdGUSPHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS90ZW1wbGF0ZXMve3RlbXBs
YXRlfepBwAEKIGRscC5nb29nbGVhcGlzLmNvbS9Db250ZW50UG9saWN5ElJvcmdhbml6YXRp
b25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L2NvbnRlbnRQb2xpY2ll
cy97Y29udGVudF9wb2xpY3l9Ekhwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vY29udGVudFBvbGljaWVzL3tjb250ZW50X3BvbGljeX3qQXkKI2hlYWx0aGNhcmUu
Z29vZ2xlYXBpcy5jb20vRmhpclN0b3JlElJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YXNldHMve2RhdGFzZXR9L2ZoaXJTdG9yZXMve2ZoaXJfc3RvcmV9
6kGkAQomaGVhbHRoY2FyZS5nb29nbGVhcGlzLmNvbS9GaGlyUmVzb3VyY2USenByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH0vZmhp
clN0b3Jlcy97Zmhpcl9zdG9yZX0vZmhpci97cmVzb3VyY2VfdHlwZX0ve2ZoaXJfcmVzb3Vy
Y2VfaWR96kF5CiJjbG91ZGttcy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXlzElNwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0va2V5UmluZ3Mve2tleV9yaW5nfS9j
cnlwdG9LZXlzL3tjcnlwdG9fa2V5fepBpwEKKWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0Ny
eXB0b0tleVZlcnNpb25zEnpwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0va2V5UmluZ3Mve2tleV9yaW5nfS9jcnlwdG9LZXlzL3tjcnlwdG9fa2V5fS9jcnlwdG9L
ZXlWZXJzaW9ucy97Y3J5cHRvX2tleV92ZXJzaW9ufUrKbgoHEgUOANIDAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAIgoICgEIEgMWAEAKCQoCCCUSAxYAQAoICgEIEgMXAGgKCQoCCAsSAxcA
aAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACwKCQoCCAgSAxkALAoICgEIEgMaAEAK
CQoCCAESAxoAQAoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMcAEAKCQoCCCkSAxwAQAoI
CgEIEgMdAD8KCQoCCC0SAx0APwoJCgEIEgQeACICCgwKBAidCAASBB4AIgIKCQoBCBIEIwAm
AgoMCgQInQgBEgQjACYCCgkKAQgSBCcAKgIKDAoECJ0IAhIEJwAqAgoJCgEIEgQrAC4CCgwK
BAidCAMSBCsALgIKCQoBCBIELwA0AgoMCgQInQgEEgQvADQCCgkKAQgSBDUAOAIKDAoECJ0I
BRIENQA4AgoJCgEIEgQ5ADwCCgwKBAidCAYSBDkAPAIKCQoBCBIEPQBAAgoMCgQInQgHEgQ9
AEACCgkKAQgSBEEARQIKDAoECJ0ICBIEQQBFAgoJCgEIEgRGAEkCCgwKBAidCAkSBEYASQIK
CQoBCBIESgBNAgoMCgQInQgKEgRKAE0CCgkKAQgSBE4AUQIKDAoECJ0ICxIETgBRAgoJCgEI
EgRSAFUCCgwKBAidCAwSBFIAVQIKdAoCBQASBFkAZgEaaCBUaGUgaW5kdXN0cnkgdmVydGlj
YWwgYXNzb2NpYXRlZCB3aXRoIHRoZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXS4KCgoKAwUAARIDWQUVCiUKBAUAAgASA1sC
JBoYIFZhbHVlIHVzZWQgd2hlbiB1bnNldC4KCgwKBQUAAgABEgNbAh8KDAoFBQACAAISA1si
IwpiCgQFAAIBEgNfAg4aVSBUaGUgZ2VuZXJpYyB2ZXJ0aWNhbCBmb3IgZG9jdW1lbnRzIHRo
YXQgYXJlIG5vdCBzcGVjaWZpYyB0byBhbnkgaW5kdXN0cnkKIHZlcnRpY2FsLgoKDAoFBQAC
AQESA18CCQoMCgUFAAIBAhIDXwwNCisKBAUAAgISA2ICDBoeIFRoZSBtZWRpYSBpbmR1c3Ry
eSB2ZXJ0aWNhbC4KCgwKBQUAAgIBEgNiAgcKDAoFBQACAgISA2IKCwosCgQFAAIDEgNlAhYa
HyBUaGUgaGVhbHRoY2FyZSBGSElSIHZlcnRpY2FsLgoKDAoFBQACAwESA2UCEQoMCgUFAAID
AhIDZRQVCiMKAgUBEgRpAH0BGhcgVGhlIHR5cGUgb2Ygc29sdXRpb24uCgoKCgMFAQESA2kF
EQodCgQFAQIAEgNrAiAaECBEZWZhdWx0IHZhbHVlLgoKDAoFBQECAAESA2sCGwoMCgUFAQIA
AhIDax4fCisKBAUBAgESA24CIxoeIFVzZWQgZm9yIFJlY29tbWVuZGF0aW9ucyBBSS4KCgwK
BQUBAgEBEgNuAh4KDAoFBQECAQISA24hIgopCgQFAQICEgNxAhsaHCBVc2VkIGZvciBEaXNj
b3ZlcnkgU2VhcmNoLgoKDAoFBQECAgESA3ECFgoMCgUFAQICAhIDcRkaCkUKBAUBAgMSA3QC
GRo4IFVzZWQgZm9yIHVzZSBjYXNlcyByZWxhdGVkIHRvIHRoZSBHZW5lcmF0aXZlIEFJIGFn
ZW50LgoKDAoFBQECAwESA3QCFAoMCgUFAQIDAhIDdBcYCsIBCgQFAQIEEgN5AiQatAEgVXNl
ZCBmb3IgdXNlIGNhc2VzIHJlbGF0ZWQgdG8gdGhlIEdlbmVyYXRpdmUgQ2hhdCBhZ2VudC4K
IEl0J3MgdXNlZCBmb3IgR2VuZXJhdGl2ZSBjaGF0IGVuZ2luZSBvbmx5LCB0aGUgYXNzb2Np
YXRlZCBkYXRhIHN0b3JlcwogbXVzdCBlbnJvbGxlZCB3aXRoIGBTT0xVVElPTl9UWVBFX0NI
QVRgIHNvbHV0aW9uLgoKDAoFBQECBAESA3kCHwoMCgUFAQIEAhIDeSIjCiAKBAUBAgUSA3wC
HBoTIFVzZWQgZm9yIEFJIE1vZGUuCgoMCgUFAQIFARIDfAIXCgwKBQUBAgUCEgN8GhsKugEK
AgUCEgaCAQCNAQEaqwEgRGVmaW5lcyBhIGZ1cnRoZXIgc3ViZGl2aXNpb24gb2YgYFNvbHV0
aW9uVHlwZWAuCiBTcGVjaWZpY2FsbHkgYXBwbGllcyB0bwogW1NPTFVUSU9OX1RZUEVfU0VB
UkNIXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Tb2x1dGlvblR5cGUu
U09MVVRJT05fVFlQRV9TRUFSQ0hdLgoKCwoDBQIBEgSCAQUSCj0KBAUCAgASBIQBAiIaLyBW
YWx1ZSB1c2VkIHdoZW4gdW5zZXQuIFdpbGwgbm90IG9jY3VyIGluIENTUy4KCg0KBQUCAgAB
EgSEAQIdCg0KBQUCAgACEgSEASAhCocBCgQFAgIBEgSIAQIdGnkgU2VhcmNoIHVzZSBjYXNl
LiBFeHBlY3RzIHRoZSB0cmFmZmljIGhhcyBhIG5vbi1lbXB0eQogW3F1ZXJ5XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hSZXF1ZXN0LnF1ZXJ5XS4KCg0K
BQUCAgEBEgSIAQIYCg0KBQUCAgECEgSIARscCoQBCgQFAgICEgSMAQIdGnYgQnJvd3NlIHVz
ZSBjYXNlLiBFeHBlY3RzIHRoZSB0cmFmZmljIGhhcyBhbiBlbXB0eQogW3F1ZXJ5XVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5TZWFyY2hSZXF1ZXN0LnF1ZXJ5XS4K
Cg0KBQUCAgIBEgSMAQIYCg0KBQUCAgICEgSMARscCogBCgIFAxIGkQEAmgEBGnogVGllcnMg
b2Ygc2VhcmNoIGZlYXR1cmVzLiBEaWZmZXJlbnQgdGllcnMgbWlnaHQgaGF2ZSBkaWZmZXJl
bnQKIHByaWNpbmcuIFRvIGxlYXJuIG1vcmUsIGNoZWNrIHRoZSBwcmljaW5nIGRvY3VtZW50
YXRpb24uCgoLCgMFAwESBJEBBQ8KUwoEBQMCABIEkwECHhpFIERlZmF1bHQgdmFsdWUgd2hl
biB0aGUgZW51bSBpcyB1bnNwZWNpZmllZC4gVGhpcyBpcyBpbnZhbGlkIHRvIHVzZS4KCg0K
BQUDAgABEgSTAQIZCg0KBQUDAgACEgSTARwdCh4KBAUDAgESBJYBAhsaECBTdGFuZGFyZCB0
aWVyLgoKDQoFBQMCAQESBJYBAhYKDQoFBQMCAQISBJYBGRoKIAoEBQMCAhIEmQECHRoSIEVu
dGVycHJpc2UgdGllci4KCg0KBQUDAgIBEgSZAQIYCg0KBQUDAgICEgSZARscCkkKAgUEEgad
AQCjAQEaOyBBZGQtb24gdGhhdCBwcm92aWRlcyBhZGRpdGlvbmFsIGZ1bmN0aW9uYWxpdHkg
Zm9yIHNlYXJjaC4KCgsKAwUEARIEnQEFEApTCgQFBAIAEgSfAQIgGkUgRGVmYXVsdCB2YWx1
ZSB3aGVuIHRoZSBlbnVtIGlzIHVuc3BlY2lmaWVkLiBUaGlzIGlzIGludmFsaWQgdG8gdXNl
LgoKDQoFBQQCAAESBJ8BAhsKDQoFBQQCAAISBJ8BHh8KLAoEBQQCARIEogECGBoeIExhcmdl
IGxhbmd1YWdlIG1vZGVsIGFkZC1vbi4KCg0KBQUEAgEBEgSiAQITCg0KBQUEAgECEgSiARYX
Ci4KAgUFEgamAQDSAQEaICBTdWJzY3JpcHRpb24gdGllciBpbmZvcm1hdGlvbi4KCgsKAwUF
ARIEpgEFFQoeCgQFBQIAEgSoAQIkGhAgRGVmYXVsdCB2YWx1ZS4KCg0KBQUFAgABEgSoAQIf
Cg0KBQUFAgACEgSoASIjCmcKBAUFAgESBKwBAh8aWSBTZWFyY2ggdGllci4KIFNlYXJjaCB0
aWVyIGNhbiBhY2Nlc3MgVmVydGV4IEFJIFNlYXJjaCBmZWF0dXJlcyBhbmQgTm90ZWJvb2tM
TSBmZWF0dXJlcy4KCg0KBQUFAgEBEgSsAQIaCg0KBQUFAgECEgSsAR0eCiwKBAUFAgISBK8B
Ai0aHiBHZW1pbmkgRW50ZXJwcmlzZSBQbHVzIHRpZXIuCgoNCgUFBQICARIErwECKAoNCgUF
BQICAhIErwErLApoCgQFBQIDEgSzAQIkGlogTm90ZWJvb2tMTSB0aWVyLgogTm90ZWJvb2tM
TSBpcyBhIHN1YnNjcmlwdGlvbiB0aWVyIGNhbiBvbmx5IGFjY2VzcyBOb3RlYm9va0xNIGZl
YXR1cmVzLgoKDQoFBQUCAwESBLMBAh8KDQoFBQUCAwISBLMBIiMKLQoEBQUCBBIEtgECKRof
IEdlbWluaSBGcm9udGxpbmUgd29ya2VyIHRpZXIuCgoNCgUFBQIEARIEtgECJAoNCgUFBQIE
AhIEtgEnKAotCgQFBQIFEgS5AQIsGh8gR2VtaW5pIEJ1c2luZXNzIFN0YXJ0ZXIgdGllci4K
Cg0KBQUFAgUBEgS5AQImCg0KBQUFAgUCEgS5ASkrCiUKBAUFAgYSBLwBAiwaFyBHZW1pbmkg
QnVzaW5lc3MgdGllci4KCg0KBQUFAgYBEgS8AQInCg0KBQUFAgYCEgS8ASorCjAKBAUFAgcS
BL8BAiMaIiBHZW1pbmkgRW50ZXJwcmlzZSBTdGFuZGFyZCB0aWVyLgoKDQoFBQUCBwESBL8B
Ah4KDQoFBQUCBwISBL8BISIKRQoEBQUCCBIEwgECLRo3IEdlbWluaSBFbnRlcnByaXNlIFN0
YW5kYXJkIHRpZXIgZm9yIGVtZXJnaW5nIG1hcmtldHMuCgoNCgUFBQIIARIEwgECJwoNCgUF
BQIIAhIEwgEqLAorCgQFBQIJEgTFAQIcGh0gR2VtaW5pIEVudGVycHJpc2UgRURVIHRpZXIu
CgoNCgUFBQIJARIExQECFwoNCgUFBQIJAhIExQEaGwovCgQFBQIKEgTIAQIgGiEgR2VtaW5p
IEVudGVycHJpc2UgRURVIFBybyB0aWVyLgoKDQoFBQUCCgESBMgBAhsKDQoFBQUCCgISBMgB
Hh8KRAoEBQUCCxIEywECJho2IEdlbWluaSBFbnRlcnByaXNlIEVEVSB0aWVyIGZvciBlbWVy
Z2luZyBtYXJrZXQgb25seS4KCg0KBQUFAgsBEgTLAQIgCg0KBQUFAgsCEgTLASMlCkMKBAUF
AgwSBM4BAioaNSBHZW1pbmkgRW50ZXJwcmlzZSBFRFUgUHJvIHRpZXIgZm9yIGVtZXJnaW5n
IG1hcmtldC4KCg0KBQUFAgwBEgTOAQIkCg0KBQUFAgwCEgTOAScpCi4KBAUFAg0SBNEBAisa
ICBHZW1pbmkgRnJvbnRsaW5lIFN0YXJ0ZXIgdGllci4KCg0KBQUFAg0BEgTRAQIlCg0KBQUF
Ag0CEgTRASgqCiIKAgUGEgbVAQDkAQEaFCBTdWJzY3JpcHRpb24gdGVybS4KCgsKAwUGARIE
1QEFFQoqCgQFBgIAEgTXAQIkGhwgRGVmYXVsdCB2YWx1ZSwgZG8gbm90IHVzZS4KCg0KBQUG
AgABEgTXAQIfCg0KBQUGAgACEgTXASIjChgKBAUGAgESBNoBAiIaCiAxIG1vbnRoLgoKDQoF
BQYCAQESBNoBAh0KDQoFBQYCAQISBNoBICEKFwoEBQYCAhIE3QECIRoJIDEgeWVhci4KCg0K
BQUGAgIBEgTdAQIcCg0KBQUGAgICEgTdAR8gChgKBAUGAgMSBOABAiQaCiAzIHllYXJzLgoK
DQoFBQYCAwESBOABAh8KDQoFBQYCAwISBOABIiMKMwoEBQYCBBIE4wECHxolIEN1c3RvbSB0
ZXJtLiBNdXN0IHNldCB0aGUgZW5kX2RhdGUuCgoNCgUFBgIEARIE4wECGgoNCgUFBgIEAhIE
4wEdHgoqCgIEABIG5wEAgQIBGhwgQSBmbG9hdGluZyBwb2ludCBpbnRlcnZhbC4KCgsKAwQA
ARIE5wEIEArkAQoEBAAIABIG7QEC8wEDGtMBIFRoZSBsb3dlciBib3VuZCBvZiB0aGUgaW50
ZXJ2YWwuIElmIG5laXRoZXIgb2YgdGhlIG1pbiBmaWVsZHMgYXJlCiBzZXQsIHRoZW4gdGhl
IGxvd2VyIGJvdW5kIGlzIG5lZ2F0aXZlIGluZmluaXR5LgoKIFRoaXMgZmllbGQgbXVzdCBi
ZSBub3QgbGFyZ2VyIHRoYW4gbWF4LgogT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVO
VGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAgAARIE7QEICwomCgQEAAIAEgTvAQQXGhgg
SW5jbHVzaXZlIGxvd2VyIGJvdW5kLgoKDQoFBAACAAUSBO8BBAoKDQoFBAACAAESBO8BCxIK
DQoFBAACAAMSBO8BFRYKJgoEBAACARIE8gEEIRoYIEV4Y2x1c2l2ZSBsb3dlciBib3VuZC4K
Cg0KBQQAAgEFEgTyAQQKCg0KBQQAAgEBEgTyAQscCg0KBQQAAgEDEgTyAR8gCuUBCgQEAAgB
Egb6AQKAAgMa1AEgVGhlIHVwcGVyIGJvdW5kIG9mIHRoZSBpbnRlcnZhbC4gSWYgbmVpdGhl
ciBvZiB0aGUgbWF4IGZpZWxkcyBhcmUKIHNldCwgdGhlbiB0aGUgdXBwZXIgYm91bmQgaXMg
cG9zaXRpdmUgaW5maW5pdHkuCgogVGhpcyBmaWVsZCBtdXN0IGJlIG5vdCBzbWFsbGVyIHRo
YW4gbWluLgogT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0
dXJuZWQuCgoNCgUEAAgBARIE+gEICwomCgQEAAICEgT8AQQXGhggSW5jbHVzaXZlIHVwcGVy
IGJvdW5kLgoKDQoFBAACAgUSBPwBBAoKDQoFBAACAgESBPwBCxIKDQoFBAACAgMSBPwBFRYK
JgoEBAACAxIE/wEEIRoYIEV4Y2x1c2l2ZSB1cHBlciBib3VuZC4KCg0KBQQAAgMFEgT/AQQK
Cg0KBQQAAgMBEgT/AQscCg0KBQQAAgMDEgT/AR8gCpMBCgIEARIGhQIAnAIBGoQBIEEgY3Vz
dG9tIGF0dHJpYnV0ZSB0aGF0IGlzIG5vdCBleHBsaWNpdGx5IG1vZGVsZWQgaW4gYSByZXNv
dXJjZSwgZS5nLgogW1VzZXJFdmVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MWJldGEuVXNlckV2ZW50XS4KCgsKAwQBARIEhQIIFwrRAwoEBAECABIEkQICGxrCAyBUaGUg
dGV4dHVhbCB2YWx1ZXMgb2YgdGhpcyBjdXN0b20gYXR0cmlidXRlLiBGb3IgZXhhbXBsZSwg
YFsieWVsbG93IiwKICJncmVlbiJdYCB3aGVuIHRoZSBrZXkgaXMgImNvbG9yIi4KCiBFbXB0
eSBzdHJpbmcgaXMgbm90IGFsbG93ZWQuIE90aGVyd2lzZSwgYW4gYElOVkFMSURfQVJHVU1F
TlRgIGVycm9yIGlzCiByZXR1cm5lZC4KCiBFeGFjdGx5IG9uZSBvZgogW0N1c3RvbUF0dHJp
YnV0ZS50ZXh0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5DdXN0b21B
dHRyaWJ1dGUudGV4dF0KIG9yCiBbQ3VzdG9tQXR0cmlidXRlLm51bWJlcnNdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkN1c3RvbUF0dHJpYnV0ZS5udW1iZXJzXQog
c2hvdWxkIGJlIHNldC4gT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoNCgUEAQIABBIEkQICCgoNCgUEAQIABRIEkQILEQoNCgUEAQIAARIE
kQISFgoNCgUEAQIAAxIEkQIZGgr8AgoEBAECARIEmwICHhrtAiBUaGUgbnVtZXJpY2FsIHZh
bHVlcyBvZiB0aGlzIGN1c3RvbSBhdHRyaWJ1dGUuIEZvciBleGFtcGxlLCBgWzIuMywgMTUu
NF1gCiB3aGVuIHRoZSBrZXkgaXMgImxlbmd0aHNfY20iLgoKIEV4YWN0bHkgb25lIG9mCiBb
Q3VzdG9tQXR0cmlidXRlLnRleHRdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkN1c3RvbUF0dHJpYnV0ZS50ZXh0XQogb3IKIFtDdXN0b21BdHRyaWJ1dGUubnVtYmVy
c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ3VzdG9tQXR0cmlidXRl
Lm51bWJlcnNdCiBzaG91bGQgYmUgc2V0LiBPdGhlcndpc2UsIGFuIGBJTlZBTElEX0FSR1VN
RU5UYCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgEEEgSbAgIKCg0KBQQBAgEFEgSbAgsR
Cg0KBQQBAgEBEgSbAhIZCg0KBQQBAgEDEgSbAhwdCisKAgQCEgafAgDVAgEaHSBJbmZvcm1h
dGlvbiBvZiBhbiBlbmQgdXNlci4KCgsKAwQCARIEnwIIEAqIAQoEBAIDABIGogICqwIDGngg
UHJlY2lzZSBsb2NhdGlvbiBpbmZvIHdpdGggbXVsdGlwbGUgcmVwcmVzZW50YXRpb24gb3B0
aW9ucy4KIEN1cnJlbnRseSBvbmx5IGxhdGl0dWRlIGFuZCBsb25naXR1ZGUgcG9pbnQgaXMg
c3VwcG9ydGVkLgoKDQoFBAIDAAESBKICChkKEAoGBAIDAAgAEgajAgSqAgUKDwoHBAIDAAgA
ARIEowIKEgpPCgYEAgMAAgASBKUCBkwaPyBPcHRpb25hbC4gTG9jYXRpb24gcmVwcmVzZW50
ZWQgYnkgYSBsYXRpdHVkZS9sb25naXR1ZGUgcG9pbnQuCgoPCgcEAgMAAgAGEgSlAgYYCg8K
BwQCAwACAAESBKUCGR4KDwoHBAIDAAIAAxIEpQIhIgoPCgcEAgMAAgAIEgSlAiNLChIKCgQC
AwACAAicCAASBKUCJEoKlgEKBgQCAwACARIEqQIGQhqFASBPcHRpb25hbC4gTG9jYXRpb24g
cmVwcmVzZW50ZWQgYnkgYSBuYXR1cmFsIGxhbmd1YWdlIGFkZHJlc3MuIFdpbGwKIGxhdGVy
IGJlIGdlb2NvZGVkIGFuZCBjb252ZXJ0ZWQgdG8gZWl0aGVyIGEgcG9pbnQgb3IgYSBwb2x5
Z29uLgoKDwoHBAIDAAIBBRIEqQIGDAoPCgcEAgMAAgEBEgSpAg0UCg8KBwQCAwACAQMSBKkC
FxgKDwoHBAIDAAIBCBIEqQIZQQoSCgoEAgMAAgEInAgAEgSpAhpACq8FCgQEAgIAEgS8AgIV
GqAFIEhpZ2hseSByZWNvbW1lbmRlZCBmb3IgbG9nZ2VkLWluIHVzZXJzLiBVbmlxdWUgaWRl
bnRpZmllciBmb3IgbG9nZ2VkLWluCiB1c2VyLCBzdWNoIGFzIGEgdXNlciBuYW1lLiBEb24n
dCBzZXQgZm9yIGFub255bW91cyB1c2Vycy4KCiBBbHdheXMgdXNlIGEgaGFzaGVkIHZhbHVl
IGZvciB0aGlzIElELgoKIERvbid0IHNldCB0aGUgZmllbGQgdG8gdGhlIHNhbWUgZml4ZWQg
SUQgZm9yIGRpZmZlcmVudCB1c2Vycy4gVGhpcyBtaXhlcwogdGhlIGV2ZW50IGhpc3Rvcnkg
b2YgdGhvc2UgdXNlcnMgdG9nZXRoZXIsIHdoaWNoIHJlc3VsdHMgaW4gZGVncmFkZWQKIG1v
ZGVsIHF1YWxpdHkuCgogVGhlIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmlu
ZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBh
biBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgogUmVwcmVzZW50cyBh
biBvcGFxdWUgSUQgdG8gdGhlIFNlYXJjaCBBUEkuIFRoZSBTZWFyY2ggQVBJIGRvZXNuJ3QK
IGludGVycHJldCB0aGUgdmFsdWUgaW4gYW55IHdheS4gVGhpcyBmaWVsZCBpcyB1c2VkIHRv
IGFzc29jaWF0ZSBldmVudHMKIHdpdGggYSB1c2VyIGFjcm9zcyBzZXNzaW9ucyBpZiB0aGUg
ZXZlbnRzIGFyZSBiZWluZyB1cGxvYWRlZC4KCg0KBQQCAgAFEgS8AgIICg0KBQQCAgABEgS8
AgkQCg0KBQQCAgADEgS8AhMUCocECgQEAgIBEgTJAgIYGvgDIFVzZXIgYWdlbnQgYXMgaW5j
bHVkZWQgaW4gdGhlIEhUVFAgaGVhZGVyLgoKIFRoZSBmaWVsZCBtdXN0IGJlIGEgVVRGLTgg
ZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxLDAwMAogY2hhcmFjdGVy
cy4gT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQu
CgogVGhpcyBzaG91bGQgbm90IGJlIHNldCB3aGVuIHVzaW5nIHRoZSBjbGllbnQgc2lkZSBl
dmVudCByZXBvcnRpbmcgd2l0aAogR1RNIG9yIEphdmFTY3JpcHQgdGFnIGluCiBbVXNlckV2
ZW50U2VydmljZS5Db2xsZWN0VXNlckV2ZW50XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5Vc2VyRXZlbnRTZXJ2aWNlLkNvbGxlY3RVc2VyRXZlbnRdCiBvciBpZgog
W1VzZXJFdmVudC5kaXJlY3RfdXNlcl9yZXF1ZXN0XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5Vc2VyRXZlbnQuZGlyZWN0X3VzZXJfcmVxdWVzdF0KIGlzIHNldC4K
Cg0KBQQCAgEFEgTJAgIICg0KBQQCAgEBEgTJAgkTCg0KBQQCAgEDEgTJAhYXCj8KBAQCAgIS
BMwCAkAaMSBPcHRpb25hbC4gSUFOQSB0aW1lIHpvbmUsIGUuZy4gRXVyb3BlL0J1ZGFwZXN0
LgoKDQoFBAICAgUSBMwCAggKDQoFBAICAgESBMwCCRIKDQoFBAICAgMSBMwCFRYKDQoFBAIC
AggSBMwCFz8KEAoIBAICAgicCAASBMwCGD4KrAEKBAQCAgMSBtECAtQCBBqbASBPcHRpb25h
bC4gSW5wdXQgb25seS4gUHJlY2lzZSBsb2NhdGlvbiBvZiB0aGUgdXNlci4KIEl0IGlzIHVz
ZWQgaW4gQ3VzdG9tIFJhbmtpbmcgdG8gY2FsY3VsYXRlIHRoZSBkaXN0YW5jZSBiZXR3ZWVu
IHRoZSB1c2VyIGFuZAogdGhlIHJlbGV2YW50IGRvY3VtZW50cy4KCg0KBQQCAgMGEgTRAgIR
Cg0KBQQCAgMBEgTRAhIiCg0KBQQCAgMDEgTRAiUmCg8KBQQCAgMIEgbRAifUAgMKEAoIBAIC
AwicCAASBNICBCwKEAoIBAICAwicCAESBNMCBCoKVQoCBAMSBtgCANsCARpHIERlZmluZXMg
ZW1iZWRkaW5nIGNvbmZpZywgdXNlZCBmb3IgYnJpbmcgeW91ciBvd24gZW1iZWRkaW5ncyBm
ZWF0dXJlLgoKCwoDBAMBEgTYAggXCkgKBAQDAgASBNoCAhgaOiBGdWxsIGZpZWxkIHBhdGgg
aW4gdGhlIHNjaGVtYSBtYXBwZWQgYXMgZW1iZWRkaW5nIGZpZWxkLgoKDQoFBAMCAAUSBNoC
AggKDQoFBAMCAAESBNoCCRMKDQoFBAMCAAMSBNoCFhcKHAoCBAQSBt4CAOECARoOIERvdWJs
ZSBsaXN0LgoKCwoDBAQBEgTeAggSCh4KBAQEAgASBOACAh0aECBEb3VibGUgdmFsdWVzLgoK
DQoFBAQCAAQSBOACAgoKDQoFBAQCAAUSBOACCxEKDQoFBAQCAAESBOACEhgKDQoFBAQCAAMS
BOACGxwKKQoCBAUSBuQCAP0CARobIElkZW50aXR5IFByb3ZpZGVyIENvbmZpZy4KCgsKAwQF
ARIE5AIIEQopCgQEBQMAEgbmAgLqAgMaGSBUaGlyZCBwYXJ0eSBJRFAgQ29uZmlnLgoKDQoF
BAUDAAESBOYCChsKWgoGBAUDAAIAEgTpAgQjGkogV29ya2ZvcmNlIHBvb2wgbmFtZS4KIEV4
YW1wbGU6ICJsb2NhdGlvbnMvZ2xvYmFsL3dvcmtmb3JjZVBvb2xzL3Bvb2xfaWQiCgoPCgcE
BQMAAgAFEgTpAgQKCg8KBwQFAwACAAESBOkCCx4KDwoHBAUDAAIAAxIE6QIhIgopCgQEBQQA
EgbtAgL2AgMaGSBJZGVudGl0eSBQcm92aWRlciBUeXBlLgoKDQoFBAUEAAESBO0CBw4KOAoG
BAUEAAIAEgTvAgQdGiggRGVmYXVsdCB2YWx1ZS4gQUNMIHNlYXJjaCBub3QgZW5hYmxlZC4K
Cg8KBwQFBAACAAESBO8CBBgKDwoHBAUEAAIAAhIE7wIbHAolCgYEBQQAAgESBPICBA8aFSBH
b29nbGUgMVAgcHJvdmlkZXIuCgoPCgcEBQQAAgEBEgTyAgQKCg8KBwQFBAACAQISBPICDQ4K
JwoGBAUEAAICEgT1AgQUGhcgVGhpcmQgcGFydHkgcHJvdmlkZXIuCgoPCgcEBQQAAgIBEgT1
AgQPCg8KBwQFBAACAgISBPUCEhMKMgoEBAUCABIE+QICFxokIElkZW50aXR5IHByb3ZpZGVy
IHR5cGUgY29uZmlndXJlZC4KCg0KBQQFAgAGEgT5AgIJCg0KBQQFAgABEgT5AgoSCg0KBQQF
AgADEgT5AhUWCjIKBAQFAgESBPwCAiwaJCBFeHRlcm5hbCBJZGVudGl0eSBwcm92aWRlciBj
b25maWcuCgoNCgUEBQIBBhIE/AICEwoNCgUEBQIBARIE/AIUJwoNCgUEBQIBAxIE/AIqKwo6
CgIEBhIGgAMAlQMBGiwgUHJpbmNpcGFsIGlkZW50aWZpZXIgb2YgYSB1c2VyIG9yIGEgZ3Jv
dXAuCgoLCgMEBgESBIADCBEKTAoEBAYIABIGggMClAMDGjwgVW5pb24gZmllbGQgcHJpbmNp
cGFsLiBQcmluY2lwYWwgY2FuIGJlIGEgdXNlciBvciBhIGdyb3VwLgoKDQoFBAYIAAESBIID
CBEK/AEKBAQGAgASBIgDBBca7QEgVXNlciBpZGVudGlmaWVyLgogRm9yIEdvb2dsZSBXb3Jr
c3BhY2UgdXNlciBhY2NvdW50LCB1c2VyX2lkIHNob3VsZCBiZSB0aGUgZ29vZ2xlIHdvcmtz
cGFjZQogdXNlciBlbWFpbC4KIEZvciBub24tZ29vZ2xlIGlkZW50aXR5IHByb3ZpZGVyIHVz
ZXIgYWNjb3VudCwgdXNlcl9pZCBpcyB0aGUgbWFwcGVkIHVzZXIKIGlkZW50aWZpZXIgY29u
ZmlndXJlZCBkdXJpbmcgdGhlIHdvcmtmb3JjZXBvb2wgY29uZmlnLgoKDQoFBAYCAAUSBIgD
BAoKDQoFBAYCAAESBIgDCxIKDQoFBAYCAAMSBIgDFRYKgQIKBAQGAgESBI8DBBga8gEgR3Jv
dXAgaWRlbnRpZmllci4KIEZvciBHb29nbGUgV29ya3NwYWNlIHVzZXIgYWNjb3VudCwgZ3Jv
dXBfaWQgc2hvdWxkIGJlIHRoZSBnb29nbGUKIHdvcmtzcGFjZSBncm91cCBlbWFpbC4KIEZv
ciBub24tZ29vZ2xlIGlkZW50aXR5IHByb3ZpZGVyIHVzZXIgYWNjb3VudCwgZ3JvdXBfaWQg
aXMgdGhlIG1hcHBlZAogZ3JvdXAgaWRlbnRpZmllciBjb25maWd1cmVkIGR1cmluZyB0aGUg
d29ya2ZvcmNlcG9vbCBjb25maWcuCgoNCgUEBgIBBRIEjwMECgoNCgUEBgIBARIEjwMLEwoN
CgUEBgIBAxIEjwMWFwpnCgQEBgICEgSTAwQiGlkgRm9yIDNQIGFwcGxpY2F0aW9uIGlkZW50
aXRpZXMgd2hpY2ggYXJlIG5vdCBwcmVzZW50IGluIHRoZSBjdXN0b21lcgogaWRlbnRpdHkg
cHJvdmlkZXIuCgoNCgUEBgICBRIEkwMECgoNCgUEBgICARIEkwMLHQoNCgUEBgICAxIEkwMg
IQpECgIEBxIGmAMArwMBGjYgQ29uZmlnIHRvIGRhdGEgc3RvcmUgZm9yIGBIRUFMVEhDQVJF
X0ZISVJgIHZlcnRpY2FsLgoKCwoDBAcBEgSYAwgcCs4BCgQEBwIAEgSdAwImGr8BIFdoZXRo
ZXIgdG8gZW5hYmxlIGNvbmZpZ3VyYWJsZSBzY2hlbWEgZm9yIGBIRUFMVEhDQVJFX0ZISVJg
IHZlcnRpY2FsLgoKIElmIHNldCB0byBgdHJ1ZWAsIHRoZSBwcmVkZWZpbmVkIGhlYWx0aGNh
cmUgZmhpciBzY2hlbWEgY2FuIGJlIGV4dGVuZGVkCiBmb3IgbW9yZSBjdXN0b21pemVkIHNl
YXJjaGluZyBhbmQgZmlsdGVyaW5nLgoKDQoFBAcCAAUSBJ0DAgYKDQoFBAcCAAESBJ0DByEK
DQoFBAcCAAMSBJ0DJCUK7AEKBAQHAgESBKUDAjYa3QEgV2hldGhlciB0byBlbmFibGUgc3Rh
dGljIGluZGV4aW5nIGZvciBgSEVBTFRIQ0FSRV9GSElSYCBiYXRjaAogaW5nZXN0aW9uLgoK
IElmIHNldCB0byBgdHJ1ZWAsIHRoZSBiYXRjaCBpbmdlc3Rpb24gd2lsbCBiZSBwcm9jZXNz
ZWQgaW4gYSBzdGF0aWMKIGluZGV4aW5nIG1vZGUgd2hpY2ggaXMgc2xvd2VyIGJ1dCBtb3Jl
IGNhcGFibGUgb2YgaGFuZGxpbmcgbGFyZ2VyCiB2b2x1bWUuCgoNCgUEBwIBBRIEpQMCBgoN
CgUEBwIBARIEpQMHMQoNCgUEBwIBAxIEpQM0NQqUAwoEBAcCAhIGrQMCrgMvGoMDIE9wdGlv
bmFsLiBOYW1lcyBvZiB0aGUgR3JvdXAgcmVzb3VyY2VzIHRvIHVzZSBhcyBhIGJhc2lzIGZv
ciB0aGUgaW5pdGlhbAogcGF0aWVudCBmaWx0ZXIsIGluIGZvcm1hdAogYHByb2plY3RzL3tw
cm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9kYXRhc2V0cy97ZGF0YXNldF9p
ZH0vZmhpclN0b3Jlcy97Zmhpcl9zdG9yZV9pZH0vZmhpci9Hcm91cC97Z3JvdXBfaWR9YC4K
IFRoZSBmaWx0ZXIgZ3JvdXAgbXVzdCBiZSBhIEZISVIgcmVzb3VyY2UgbmFtZSBvZgogdHlw
ZSBHcm91cCwgYW5kIHRoZSBmaWx0ZXIgd2lsbCBiZSBjb25zdHJ1Y3RlZCBmcm9tIHRoZSBk
aXJlY3QgbWVtYmVycyBvZgogdGhlIGdyb3VwIHdoaWNoIGFyZSBQYXRpZW50IHJlc291cmNl
cy4KCg0KBQQHAgIEEgStAwIKCg0KBQQHAgIFEgStAwsRCg0KBQQHAgIBEgStAxInCg0KBQQH
AgIDEgStAyorCg0KBQQHAgIIEgSuAwYuChAKCAQHAgIInAgAEgSuAwctCmUKAgQIEgazAwDS
AwEaVyBQcm9tb3Rpb24gcHJvdG8gaW5jbHVkZXMgdXJpIGFuZCBvdGhlciBoZWxwaW5nIGlu
Zm9ybWF0aW9uIHRvIGRpc3BsYXkgdGhlCiBwcm9tb3Rpb24uCgoLCgMECAESBLMDCBsKVgoE
BAgCABIEtgMCPBpIIFJlcXVpcmVkLiBUaGUgdGl0bGUgb2YgdGhlIHByb21vdGlvbi4KIE1h
eGltdW0gbGVuZ3RoOiAxNjAgY2hhcmFjdGVycy4KCg0KBQQIAgAFEgS2AwIICg0KBQQIAgAB
EgS2AwkOCg0KBQQIAgADEgS2AxESCg0KBQQIAgAIEgS2AxM7ChAKCAQIAgAInAgAEgS2AxQ6
Co8BCgQECAIBEgS6AwI6GoABIE9wdGlvbmFsLiBUaGUgVVJMIGZvciB0aGUgcGFnZSB0aGUg
dXNlciB3YW50cyB0byBwcm9tb3RlLiBNdXN0IGJlIHNldCBmb3IKIHNpdGUgc2VhcmNoLiBG
b3Igb3RoZXIgdmVydGljYWxzLCB0aGlzIGlzIG9wdGlvbmFsLgoKDQoFBAgCAQUSBLoDAggK
DQoFBAgCAQESBLoDCQwKDQoFBAgCAQMSBLoDDxAKDQoFBAgCAQgSBLoDETkKEAoIBAgCAQic
CAASBLoDEjgKxQEKBAQIAgISBr8DAsQDBBq0ASBPcHRpb25hbC4gVGhlIFtEb2N1bWVudF1b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1lbnRdIHRoZQogdXNl
ciB3YW50cyB0byBwcm9tb3RlLiBGb3Igc2l0ZSBzZWFyY2gsIGxlYXZlIHVuc2V0IGFuZCBv
bmx5IHBvcHVsYXRlIHVyaS4KIENhbiBiZSBzZXQgYWxvbmcgd2l0aCB1cmkuCgoNCgUECAIC
BRIEvwMCCAoNCgUECAICARIEvwMJEQoNCgUECAICAxIEvwMUFQoPCgUECAICCBIGvwMWxAMD
ChAKCAQIAgIInAgAEgTAAwQqChEKBwQIAgIInwgSBsEDBMMDBQo8CgQECAIDEgTHAwJAGi4g
T3B0aW9uYWwuIFRoZSBwcm9tb3Rpb24gdGh1bWJuYWlsIGltYWdlIHVybC4KCg0KBQQIAgMF
EgTHAwIICg0KBQQIAgMBEgTHAwkSCg0KBQQIAgMDEgTHAxUWCg0KBQQIAgMIEgTHAxc/ChAK
CAQIAgMInAgAEgTHAxg+ClUKBAQIAgQSBMsDAkIaRyBPcHRpb25hbC4gVGhlIFByb21vdGlv
biBkZXNjcmlwdGlvbi4KIE1heGltdW0gbGVuZ3RoOiAyMDAgY2hhcmFjdGVycy4KCg0KBQQI
AgQFEgTLAwIICg0KBQQIAgQBEgTLAwkUCg0KBQQIAgQDEgTLAxcYCg0KBQQIAgQIEgTLAxlB
ChAKCAQIAgQInAgAEgTLAxpACtMBCgQECAIFEgTRAwI8GsQBIE9wdGlvbmFsLiBUaGUgZW5h
YmxlZCBwcm9tb3Rpb24gd2lsbCBiZSByZXR1cm5lZCBmb3IgYW55IHNlcnZpbmcgY29uZmln
cwogYXNzb2NpYXRlZCB3aXRoIHRoZSBwYXJlbnQgb2YgdGhlIGNvbnRyb2wgdGhpcyBwcm9t
b3Rpb24gaXMgYXR0YWNoZWQgdG8uCgogVGhpcyBmbGFnIGlzIHVzZWQgZm9yIGJhc2ljIHNp
dGUgc2VhcmNoIG9ubHkuCgoNCgUECAIFBRIE0QMCBgoNCgUECAIFARIE0QMHDgoNCgUECAIF
AxIE0QMREgoNCgUECAIFCBIE0QMTOwoQCggECAIFCJwIABIE0QMUOmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::Interval ===
    # Fields for Interval
    # Field: minimum Type: 1 ()
    # Field: exclusive_minimum Type: 1 ()
    # Field: maximum Type: 1 ()
    # Field: exclusive_maximum Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::CustomAttribute ===
    # Fields for CustomAttribute
    # Field: text Type: 9 ()
    # Field: numbers Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::UserInfo ===
    # Fields for UserInfo
    # Field: user_id Type: 9 ()
    # Field: user_agent Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: precise_location Type: 11 (.google.cloud.discoveryengine.v1beta.UserInfo.PreciseLocation)

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::EmbeddingConfig ===
    # Fields for EmbeddingConfig
    # Field: field_path Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::DoubleList ===
    # Fields for DoubleList
    # Field: values Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig ===
    # Fields for IdpConfig
    # Field: idp_type Type: 14 (.google.cloud.discoveryengine.v1beta.IdpConfig.IdpType)
    # Field: external_idp_config Type: 11 (.google.cloud.discoveryengine.v1beta.IdpConfig.ExternalIdpConfig)

# Enum: IdpConfig::IdpType
our $IdpConfig_IDP_TYPE_UNSPECIFIED = 0;
our $IdpConfig_GSUITE = 1;
our $IdpConfig_THIRD_PARTY = 2;

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::Principal ===
    # Fields for Principal
    # Field: user_id Type: 9 ()
    # Field: group_id Type: 9 ()
    # Field: external_entity_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::HealthcareFhirConfig ===
    # Fields for HealthcareFhirConfig
    # Field: enable_configurable_schema Type: 8 ()
    # Field: enable_static_indexing_for_batch_ingestion Type: 8 ()
    # Field: initial_filter_groups Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Common::SearchLinkPromotion ===
    # Fields for SearchLinkPromotion
    # Field: title Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: document Type: 9 ()
    # Field: image_uri Type: 9 ()
    # Field: description Type: 9 ()
    # Field: enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Common - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Common;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Common::Interval->new({
        minimum => $minimum,
        exclusive_minimum => $exclusive_minimum,
        maximum => $maximum,
        exclusive_maximum => $exclusive_maximum,
    });

    # Read or update a field
    my $val = $msg->minimum();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Common::Interval->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Common::Interval

A floating point interval.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->minimum() >> / C<< $msg->minimum($value) >>

Type: C<Double>

Inclusive lower bound.

=item * C<< $msg->exclusive_minimum() >> / C<< $msg->exclusive_minimum($value) >>

Type: C<Double>

Exclusive lower bound.

=item * C<< $msg->maximum() >> / C<< $msg->maximum($value) >>

Type: C<Double>

Inclusive upper bound.

=item * C<< $msg->exclusive_maximum() >> / C<< $msg->exclusive_maximum($value) >>

Type: C<Double>

Exclusive upper bound.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::CustomAttribute

A custom attribute that is not explicitly modeled in a resource, e.g.
[UserEvent][google.cloud.discoveryengine.v1beta.UserEvent].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

The textual values of this custom attribute. For example, `["yellow",
"green"]` when the key is "color".

Empty string is not allowed. Otherwise, an `INVALID_ARGUMENT` error is
returned.

Exactly one of
[CustomAttribute.text][google.cloud.discoveryengine.v1beta.CustomAttribute.text]
or
[CustomAttribute.numbers][google.cloud.discoveryengine.v1beta.CustomAttribute.numbers]
should be set. Otherwise, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->numbers() >> / C<< $msg->numbers($value) >>

Type: C<Double>

The numerical values of this custom attribute. For example, `[2.3, 15.4]`
when the key is "lengths_cm".

Exactly one of
[CustomAttribute.text][google.cloud.discoveryengine.v1beta.CustomAttribute.text]
or
[CustomAttribute.numbers][google.cloud.discoveryengine.v1beta.CustomAttribute.numbers]
should be set. Otherwise, an `INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::UserInfo

Information of an end user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_id() >> / C<< $msg->user_id($value) >>

Type: C<String>

Highly recommended for logged-in users. Unique identifier for logged-in
user, such as a user name. Don't set for anonymous users.

Always use a hashed value for this ID.

Don't set the field to the same fixed ID for different users. This mixes
the event history of those users together, which results in degraded
model quality.

The field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an `INVALID_ARGUMENT` error is returned.

Represents an opaque ID to the Search API. The Search API doesn't
interpret the value in any way. This field is used to associate events
with a user across sessions if the events are being uploaded.

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

User agent as included in the HTTP header.

The field must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an `INVALID_ARGUMENT` error is returned.

This should not be set when using the client side event reporting with
GTM or JavaScript tag in
[UserEventService.CollectUserEvent][google.cloud.discoveryengine.v1beta.UserEventService.CollectUserEvent]
or if
[UserEvent.direct_user_request][google.cloud.discoveryengine.v1beta.UserEvent.direct_user_request]
is set.

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Optional. IANA time zone, e.g. Europe/Budapest.

=item * C<< $msg->precise_location() >> / C<< $msg->precise_location($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Common::UserInfo::PreciseLocation>)

Optional. Input only. Precise location of the user.
It is used in Custom Ranking to calculate the distance between the user and
the relevant documents.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::EmbeddingConfig

Defines embedding config, used for bring your own embeddings feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_path() >> / C<< $msg->field_path($value) >>

Type: C<String>

Full field path in the schema mapped as embedding field.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::DoubleList

Double list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Double>

Double values.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig

Identity Provider Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->idp_type() >> / C<< $msg->idp_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1beta::IdpConfig::IdpType>)

Identity provider type configured.

=item * C<< $msg->external_idp_config() >> / C<< $msg->external_idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Common::IdpConfig::ExternalIdpConfig>)

External Identity provider config.

=back

=head3 Enum: IdpConfig::IdpType

=over 4

=item * C<IDP_TYPE_UNSPECIFIED> => C<0>

=item * C<GSUITE> => C<1>

=item * C<THIRD_PARTY> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::Principal

Principal identifier of a user or a group.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_id() >> / C<< $msg->user_id($value) >>

Type: C<String>

User identifier.
For Google Workspace user account, user_id should be the google workspace
user email.
For non-google identity provider user account, user_id is the mapped user
identifier configured during the workforcepool config.

=item * C<< $msg->group_id() >> / C<< $msg->group_id($value) >>

Type: C<String>

Group identifier.
For Google Workspace user account, group_id should be the google
workspace group email.
For non-google identity provider user account, group_id is the mapped
group identifier configured during the workforcepool config.

=item * C<< $msg->external_entity_id() >> / C<< $msg->external_entity_id($value) >>

Type: C<String>

For 3P application identities which are not present in the customer
identity provider.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::HealthcareFhirConfig

Config to data store for `HEALTHCARE_FHIR` vertical.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_configurable_schema() >> / C<< $msg->enable_configurable_schema($value) >>

Type: C<Bool>

Whether to enable configurable schema for `HEALTHCARE_FHIR` vertical.

If set to `true`, the predefined healthcare fhir schema can be extended
for more customized searching and filtering.

=item * C<< $msg->enable_static_indexing_for_batch_ingestion() >> / C<< $msg->enable_static_indexing_for_batch_ingestion($value) >>

Type: C<Bool>

Whether to enable static indexing for `HEALTHCARE_FHIR` batch
ingestion.

If set to `true`, the batch ingestion will be processed in a static
indexing mode which is slower but more capable of handling larger
volume.

=item * C<< $msg->initial_filter_groups() >> / C<< $msg->initial_filter_groups($value) >>

Type: C<String>

Optional. Names of the Group resources to use as a basis for the initial
patient filter, in format
`projects/{project_id}/locations/{location_id}/datasets/{dataset_id}/fhirStores/{fhir_store_id}/fhir/Group/{group_id}`.
The filter group must be a FHIR resource name of
type Group, and the filter will be constructed from the direct members of
the group which are Patient resources.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Common::SearchLinkPromotion

Promotion proto includes uri and other helping information to display the
promotion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Required. The title of the promotion.
Maximum length: 160 characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

Optional. The URL for the page the user wants to promote. Must be set for
site search. For other verticals, this is optional.

=item * C<< $msg->document() >> / C<< $msg->document($value) >>

Type: C<String>

Optional. The [Document][google.cloud.discoveryengine.v1beta.Document] the
user wants to promote. For site search, leave unset and only populate uri.
Can be set along with uri.

=item * C<< $msg->image_uri() >> / C<< $msg->image_uri($value) >>

Type: C<String>

Optional. The promotion thumbnail image url.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The Promotion description.
Maximum length: 200 characters.

=item * C<< $msg->enabled() >> / C<< $msg->enabled($value) >>

Type: C<Bool>

Optional. The enabled promotion will be returned for any serving configs
associated with the parent of the control this promotion is attached to.

This flag is used for basic site search only.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
