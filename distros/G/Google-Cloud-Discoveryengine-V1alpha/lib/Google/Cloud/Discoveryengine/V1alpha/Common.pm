package Google::Cloud::Discoveryengine::V1alpha::Common;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY29tbW9uLnByb3RvEiRn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8irgEKCEludGVydmFsEhoKB21pbmltdW0YASABKAFIAFIHbWluaW11bRItChFl
eGNsdXNpdmVfbWluaW11bRgCIAEoAUgAUhBleGNsdXNpdmVNaW5pbXVtEhoKB21heGltdW0Y
AyABKAFIAVIHbWF4aW11bRItChFleGNsdXNpdmVfbWF4aW11bRgEIAEoAUgBUhBleGNsdXNp
dmVNYXhpbXVtQgUKA21pbkIFCgNtYXgiPwoPQ3VzdG9tQXR0cmlidXRlEhIKBHRleHQYASAD
KAlSBHRleHQSGAoHbnVtYmVycxgCIAMoAVIHbnVtYmVycyJCCghVc2VySW5mbxIXCgd1c2Vy
X2lkGAEgASgJUgZ1c2VySWQSHQoKdXNlcl9hZ2VudBgCIAEoCVIJdXNlckFnZW50IjAKD0Vt
YmVkZGluZ0NvbmZpZxIdCgpmaWVsZF9wYXRoGAEgASgJUglmaWVsZFBhdGgiJAoKRG91Ymxl
TGlzdBIWCgZ2YWx1ZXMYASADKAFSBnZhbHVlcyLCAQoQR3VpZGVkU2VhcmNoU3BlYxJAChxl
bmFibGVfcmVmaW5lbWVudF9hdHRyaWJ1dGVzGAEgASgIUhplbmFibGVSZWZpbmVtZW50QXR0
cmlidXRlcxI4ChhlbmFibGVfcmVsYXRlZF9xdWVzdGlvbnMYAiABKAhSFmVuYWJsZVJlbGF0
ZWRRdWVzdGlvbnMSMgoVbWF4X3JlbGF0ZWRfcXVlc3Rpb25zGAMgASgFUhNtYXhSZWxhdGVk
UXVlc3Rpb25zIkoKFEN1c3RvbUZpbmVUdW5pbmdTcGVjEjIKFWVuYWJsZV9zZWFyY2hfYWRh
cHRvchgBIAEoCFITZW5hYmxlU2VhcmNoQWRhcHRvciLZAgoJSWRwQ29uZmlnElIKCGlkcF90
eXBlGAEgASgOMjcuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLklkcENv
bmZpZy5JZHBUeXBlUgdpZHBUeXBlEnEKE2V4dGVybmFsX2lkcF9jb25maWcYAiABKAsyQS5n
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuSWRwQ29uZmlnLkV4dGVybmFs
SWRwQ29uZmlnUhFleHRlcm5hbElkcENvbmZpZxpDChFFeHRlcm5hbElkcENvbmZpZxIuChN3
b3JrZm9yY2VfcG9vbF9uYW1lGAEgASgJUhF3b3JrZm9yY2VQb29sTmFtZSJACgdJZHBUeXBl
EhgKFElEUF9UWVBFX1VOU1BFQ0lGSUVEEAASCgoGR1NVSVRFEAESDwoLVEhJUkRfUEFSVFkQ
AiJQCglQcmluY2lwYWwSGQoHdXNlcl9pZBgBIAEoCUgAUgZ1c2VySWQSGwoIZ3JvdXBfaWQY
AiABKAlIAFIHZ3JvdXBJZEILCglwcmluY2lwYWwqYgoQSW5kdXN0cnlWZXJ0aWNhbBIhCh1J
TkRVU1RSWV9WRVJUSUNBTF9VTlNQRUNJRklFRBAAEgsKB0dFTkVSSUMQARIJCgVNRURJQRAC
EhMKD0hFQUxUSENBUkVfRkhJUhAHKqQBCgxTb2x1dGlvblR5cGUSHQoZU09MVVRJT05fVFlQ
RV9VTlNQRUNJRklFRBAAEiAKHFNPTFVUSU9OX1RZUEVfUkVDT01NRU5EQVRJT04QARIYChRT
T0xVVElPTl9UWVBFX1NFQVJDSBACEhYKElNPTFVUSU9OX1RZUEVfQ0hBVBADEiEKHVNPTFVU
SU9OX1RZUEVfR0VORVJBVElWRV9DSEFUEAQqaAoNU2VhcmNoVXNlQ2FzZRIfChtTRUFSQ0hf
VVNFX0NBU0VfVU5TUEVDSUZJRUQQABIaChZTRUFSQ0hfVVNFX0NBU0VfU0VBUkNIEAESGgoW
U0VBUkNIX1VTRV9DQVNFX0JST1dTRRACKl8KClNlYXJjaFRpZXISGwoXU0VBUkNIX1RJRVJf
VU5TUEVDSUZJRUQQABIYChRTRUFSQ0hfVElFUl9TVEFOREFSRBABEhoKFlNFQVJDSF9USUVS
X0VOVEVSUFJJU0UQAipDCgtTZWFyY2hBZGRPbhIdChlTRUFSQ0hfQUREX09OX1VOU1BFQ0lG
SUVEEAASFQoRU0VBUkNIX0FERF9PTl9MTE0QASpxCg5GaWxlT3JpZ2luVHlwZRIgChxGSUxF
X09SSUdJTl9UWVBFX1VOU1BFQ0lGSUVEEAASEQoNVVNFUl9QUk9WSURFRBABEhAKDEFJX0dF
TkVSQVRFRBACEhgKFElOVEVSTkFMTFlfR0VORVJBVEVEEANCvAgKKGNvbS5nb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCC0NvbW1vblByb3RvUAFaUmNsb3VkLmdvb2ds
ZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7
ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlz
Y292ZXJ5RW5naW5lLlYxQWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYx
YWxwaGHqAidHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGHqQeYBCiVk
aXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQnJhbmNoElFwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNo
ZXMve2JyYW5jaH0SanByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b2xsZWN0aW9ucy97Y29sbGVjdGlvbn0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZX0vYnJhbmNo
ZXMve2JyYW5jaH3qQW0KKWRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db2xsZWN0
aW9uEkBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlv
bnMve2NvbGxlY3Rpb2596kFSCidkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vTG9j
YXRpb24SJ3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufepBfQouZGlz
Y292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0dyb3VuZGluZ0NvbmZpZxJLcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2dyb3VuZGluZ0NvbmZpZ3Mve2dyb3Vu
ZGluZ19jb25maWd96kF3CixkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vUmFua2lu
Z0NvbmZpZxJHcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jhbmtp
bmdDb25maWdzL3tyYW5raW5nX2NvbmZpZ33qQXkKI2hlYWx0aGNhcmUuZ29vZ2xlYXBpcy5j
b20vRmhpclN0b3JlElJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0v
ZGF0YXNldHMve2RhdGFzZXR9L2ZoaXJTdG9yZXMve2ZoaXJfc3RvcmV9SuVJCgcSBQ4AtAIB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAtCgkKAgMAEgMS
ACMKCAoBCBIDFABBCgkKAgglEgMUAEEKCAoBCBIDFQBpCgkKAggLEgMVAGkKCAoBCBIDFgAi
CgkKAggKEgMWACIKCAoBCBIDFwAsCgkKAggIEgMXACwKCAoBCBIDGABBCgkKAggBEgMYAEEK
CAoBCBIDGQAtCgkKAggkEgMZAC0KCAoBCBIDGgBBCgkKAggpEgMaAEEKCAoBCBIDGwBACgkK
AggtEgMbAEAKCQoBCBIEHAAgAgoMCgQInQgAEgQcACACCgkKAQgSBCEAJAIKDAoECJ0IARIE
IQAkAgoJCgEIEgQlACgCCgwKBAidCAISBCUAKAIKCQoBCBIEKQAsAgoMCgQInQgDEgQpACwC
CgkKAQgSBC0AMAIKDAoECJ0IBBIELQAwAgoJCgEIEgQxADQCCgwKBAidCAUSBDEANAIKdQoC
BQASBDgARQEaaSBUaGUgaW5kdXN0cnkgdmVydGljYWwgYXNzb2NpYXRlZCB3aXRoIHRoZQog
W0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRhdGFT
dG9yZV0uCgoKCgMFAAESAzgFFQolCgQFAAIAEgM6AiQaGCBWYWx1ZSB1c2VkIHdoZW4gdW5z
ZXQuCgoMCgUFAAIAARIDOgIfCgwKBQUAAgACEgM6IiMKYgoEBQACARIDPgIOGlUgVGhlIGdl
bmVyaWMgdmVydGljYWwgZm9yIGRvY3VtZW50cyB0aGF0IGFyZSBub3Qgc3BlY2lmaWMgdG8g
YW55IGluZHVzdHJ5CiB2ZXJ0aWNhbC4KCgwKBQUAAgEBEgM+AgkKDAoFBQACAQISAz4MDQor
CgQFAAICEgNBAgwaHiBUaGUgbWVkaWEgaW5kdXN0cnkgdmVydGljYWwuCgoMCgUFAAICARID
QQIHCgwKBQUAAgICEgNBCgsKLAoEBQACAxIDRAIWGh8gVGhlIGhlYWx0aGNhcmUgRkhJUiB2
ZXJ0aWNhbC4KCgwKBQUAAgMBEgNEAhEKDAoFBQACAwISA0QUFQojCgIFARIESABZARoXIFRo
ZSB0eXBlIG9mIHNvbHV0aW9uLgoKCgoDBQEBEgNIBREKHQoEBQECABIDSgIgGhAgRGVmYXVs
dCB2YWx1ZS4KCgwKBQUBAgABEgNKAhsKDAoFBQECAAISA0oeHworCgQFAQIBEgNNAiMaHiBV
c2VkIGZvciBSZWNvbW1lbmRhdGlvbnMgQUkuCgoMCgUFAQIBARIDTQIeCgwKBQUBAgECEgNN
ISIKKQoEBQECAhIDUAIbGhwgVXNlZCBmb3IgRGlzY292ZXJ5IFNlYXJjaC4KCgwKBQUBAgIB
EgNQAhYKDAoFBQECAgISA1AZGgpFCgQFAQIDEgNTAhkaOCBVc2VkIGZvciB1c2UgY2FzZXMg
cmVsYXRlZCB0byB0aGUgR2VuZXJhdGl2ZSBBSSBhZ2VudC4KCgwKBQUBAgMBEgNTAhQKDAoF
BQECAwISA1MXGArCAQoEBQECBBIDWAIkGrQBIFVzZWQgZm9yIHVzZSBjYXNlcyByZWxhdGVk
IHRvIHRoZSBHZW5lcmF0aXZlIENoYXQgYWdlbnQuCiBJdCdzIHVzZWQgZm9yIEdlbmVyYXRp
dmUgY2hhdCBlbmdpbmUgb25seSwgdGhlIGFzc29jaWF0ZWQgZGF0YSBzdG9yZXMKIG11c3Qg
ZW5yb2xsZWQgd2l0aCBgU09MVVRJT05fVFlQRV9DSEFUYCBzb2x1dGlvbi4KCgwKBQUBAgQB
EgNYAh8KDAoFBQECBAISA1giIwq5AQoCBQISBF4AaQEarAEgRGVmaW5lcyBhIGZ1cnRoZXIg
c3ViZGl2aXNpb24gb2YgYFNvbHV0aW9uVHlwZWAuCiBTcGVjaWZpY2FsbHkgYXBwbGllcyB0
bwogW1NPTFVUSU9OX1RZUEVfU0VBUkNIXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYWxwaGEuU29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCgoKAwUCARID
XgUSCjwKBAUCAgASA2ACIhovIFZhbHVlIHVzZWQgd2hlbiB1bnNldC4gV2lsbCBub3Qgb2Nj
dXIgaW4gQ1NTLgoKDAoFBQICAAESA2ACHQoMCgUFAgIAAhIDYCAhCocBCgQFAgIBEgNkAh0a
eiBTZWFyY2ggdXNlIGNhc2UuIEV4cGVjdHMgdGhlIHRyYWZmaWMgaGFzIGEgbm9uLWVtcHR5
CiBbcXVlcnldW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5TZWFyY2hS
ZXF1ZXN0LnF1ZXJ5XS4KCgwKBQUCAgEBEgNkAhgKDAoFBQICAQISA2QbHAqEAQoEBQICAhID
aAIdGncgQnJvd3NlIHVzZSBjYXNlLiBFeHBlY3RzIHRoZSB0cmFmZmljIGhhcyBhbiBlbXB0
eQogW3F1ZXJ5XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VhcmNo
UmVxdWVzdC5xdWVyeV0uCgoMCgUFAgICARIDaAIYCgwKBQUCAgICEgNoGxwKhgEKAgUDEgRt
AHYBGnogVGllcnMgb2Ygc2VhcmNoIGZlYXR1cmVzLiBEaWZmZXJlbnQgdGllcnMgbWlnaHQg
aGF2ZSBkaWZmZXJlbnQKIHByaWNpbmcuIFRvIGxlYXJuIG1vcmUsIGNoZWNrIHRoZSBwcmlj
aW5nIGRvY3VtZW50YXRpb24uCgoKCgMFAwESA20FDwpSCgQFAwIAEgNvAh4aRSBEZWZhdWx0
IHZhbHVlIHdoZW4gdGhlIGVudW0gaXMgdW5zcGVjaWZpZWQuIFRoaXMgaXMgaW52YWxpZCB0
byB1c2UuCgoMCgUFAwIAARIDbwIZCgwKBQUDAgACEgNvHB0KHQoEBQMCARIDcgIbGhAgU3Rh
bmRhcmQgdGllci4KCgwKBQUDAgEBEgNyAhYKDAoFBQMCAQISA3IZGgofCgQFAwICEgN1Ah0a
EiBFbnRlcnByaXNlIHRpZXIuCgoMCgUFAwICARIDdQIYCgwKBQUDAgICEgN1GxwKRwoCBQQS
BHkAfwEaOyBBZGQtb24gdGhhdCBwcm92aWRlcyBhZGRpdGlvbmFsIGZ1bmN0aW9uYWxpdHkg
Zm9yIHNlYXJjaC4KCgoKAwUEARIDeQUQClIKBAUEAgASA3sCIBpFIERlZmF1bHQgdmFsdWUg
d2hlbiB0aGUgZW51bSBpcyB1bnNwZWNpZmllZC4gVGhpcyBpcyBpbnZhbGlkIHRvIHVzZS4K
CgwKBQUEAgABEgN7AhsKDAoFBQQCAAISA3seHworCgQFBAIBEgN+AhgaHiBMYXJnZSBsYW5n
dWFnZSBtb2RlbCBhZGQtb24uCgoMCgUFBAIBARIDfgITCgwKBQUEAgECEgN+FhcKJwoCBQUS
BoIBAI4BARoZIFRoZSBvcmlnaW4gb2YgdGhlIGZpbGUuCgoLCgMFBQESBIIBBRMKHgoEBQUC
ABIEhAECIxoQIERlZmF1bHQgdmFsdWUuCgoNCgUFBQIAARIEhAECHgoNCgUFBQIAAhIEhAEh
IgoyCgQFBQIBEgSHAQIUGiQgVGhlIGZpbGUgd2FzIHByb3ZpZGVkIGJ5IHRoZSB1c2VyLgoK
DQoFBQUCAQESBIcBAg8KDQoFBQUCAQISBIcBEhMKNgoEBQUCAhIEigECExooIFRoZSBmaWxl
IHdhcyBnZW5lcmF0ZWQgYnkgYW4gQUkgbW9kZWwuCgoNCgUFBQICARIEigECDgoNCgUFBQIC
AhIEigEREgpPCgQFBQIDEgSNAQIbGkEgVGhlIGZpbGUgd2FzIGdlbmVyYXRlZCBmcm9tIG90
aGVyIGZpbGVzIGJ5IGFuIGludGVybmFsIHByb2Nlc3MuCgoNCgUFBQIDARIEjQECFgoNCgUF
BQIDAhIEjQEZGgoqCgIEABIGkQEAqwEBGhwgQSBmbG9hdGluZyBwb2ludCBpbnRlcnZhbC4K
CgsKAwQAARIEkQEIEArkAQoEBAAIABIGlwECnQEDGtMBIFRoZSBsb3dlciBib3VuZCBvZiB0
aGUgaW50ZXJ2YWwuIElmIG5laXRoZXIgb2YgdGhlIG1pbiBmaWVsZHMgYXJlCiBzZXQsIHRo
ZW4gdGhlIGxvd2VyIGJvdW5kIGlzIG5lZ2F0aXZlIGluZmluaXR5LgoKIFRoaXMgZmllbGQg
bXVzdCBiZSBub3QgbGFyZ2VyIHRoYW4gbWF4LgogT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9B
UkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAAgAARIElwEICwomCgQEAAIAEgSZ
AQQXGhggSW5jbHVzaXZlIGxvd2VyIGJvdW5kLgoKDQoFBAACAAUSBJkBBAoKDQoFBAACAAES
BJkBCxIKDQoFBAACAAMSBJkBFRYKJgoEBAACARIEnAEEIRoYIEV4Y2x1c2l2ZSBsb3dlciBi
b3VuZC4KCg0KBQQAAgEFEgScAQQKCg0KBQQAAgEBEgScAQscCg0KBQQAAgEDEgScAR8gCuUB
CgQEAAgBEgakAQKqAQMa1AEgVGhlIHVwcGVyIGJvdW5kIG9mIHRoZSBpbnRlcnZhbC4gSWYg
bmVpdGhlciBvZiB0aGUgbWF4IGZpZWxkcyBhcmUKIHNldCwgdGhlbiB0aGUgdXBwZXIgYm91
bmQgaXMgcG9zaXRpdmUgaW5maW5pdHkuCgogVGhpcyBmaWVsZCBtdXN0IGJlIG5vdCBzbWFs
bGVyIHRoYW4gbWluLgogT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoNCgUEAAgBARIEpAEICwomCgQEAAICEgSmAQQXGhggSW5jbHVzaXZl
IHVwcGVyIGJvdW5kLgoKDQoFBAACAgUSBKYBBAoKDQoFBAACAgESBKYBCxIKDQoFBAACAgMS
BKYBFRYKJgoEBAACAxIEqQEEIRoYIEV4Y2x1c2l2ZSB1cHBlciBib3VuZC4KCg0KBQQAAgMF
EgSpAQQKCg0KBQQAAgMBEgSpAQscCg0KBQQAAgMDEgSpAR8gCpQBCgIEARIGrwEAxgEBGoUB
IEEgY3VzdG9tIGF0dHJpYnV0ZSB0aGF0IGlzIG5vdCBleHBsaWNpdGx5IG1vZGVsZWQgaW4g
YSByZXNvdXJjZSwgZS5nLgogW1VzZXJFdmVudF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhLlVzZXJFdmVudF0uCgoLCgMEAQESBK8BCBcK0wMKBAQBAgASBLsBAhsa
xAMgVGhlIHRleHR1YWwgdmFsdWVzIG9mIHRoaXMgY3VzdG9tIGF0dHJpYnV0ZS4gRm9yIGV4
YW1wbGUsIGBbInllbGxvdyIsCiAiZ3JlZW4iXWAgd2hlbiB0aGUga2V5IGlzICJjb2xvciIu
CgogRW1wdHkgc3RyaW5nIGlzIG5vdCBhbGxvd2VkLiBPdGhlcndpc2UsIGFuIGBJTlZBTElE
X0FSR1VNRU5UYCBlcnJvciBpcwogcmV0dXJuZWQuCgogRXhhY3RseSBvbmUgb2YKIFtDdXN0
b21BdHRyaWJ1dGUudGV4dF1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhh
LkN1c3RvbUF0dHJpYnV0ZS50ZXh0XQogb3IKIFtDdXN0b21BdHRyaWJ1dGUubnVtYmVyc11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkN1c3RvbUF0dHJpYnV0ZS5u
dW1iZXJzXQogc2hvdWxkIGJlIHNldC4gT3RoZXJ3aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVO
VGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAQIABBIEuwECCgoNCgUEAQIABRIEuwELEQoN
CgUEAQIAARIEuwESFgoNCgUEAQIAAxIEuwEZGgr+AgoEBAECARIExQECHhrvAiBUaGUgbnVt
ZXJpY2FsIHZhbHVlcyBvZiB0aGlzIGN1c3RvbSBhdHRyaWJ1dGUuIEZvciBleGFtcGxlLCBg
WzIuMywgMTUuNF1gCiB3aGVuIHRoZSBrZXkgaXMgImxlbmd0aHNfY20iLgoKIEV4YWN0bHkg
b25lIG9mCiBbQ3VzdG9tQXR0cmlidXRlLnRleHRdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjFhbHBoYS5DdXN0b21BdHRyaWJ1dGUudGV4dF0KIG9yCiBbQ3VzdG9tQXR0cmli
dXRlLm51bWJlcnNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DdXN0
b21BdHRyaWJ1dGUubnVtYmVyc10KIHNob3VsZCBiZSBzZXQuIE90aGVyd2lzZSwgYW4gYElO
VkFMSURfQVJHVU1FTlRgIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAECAQQSBMUBAgoKDQoF
BAECAQUSBMUBCxEKDQoFBAECAQESBMUBEhkKDQoFBAECAQMSBMUBHB0KKwoCBAISBskBAOMB
ARodIEluZm9ybWF0aW9uIG9mIGFuIGVuZCB1c2VyLgoKCwoDBAIBEgTJAQgQCuQDCgQEAgIA
EgTVAQIVGtUDIEhpZ2hseSByZWNvbW1lbmRlZCBmb3IgbG9nZ2VkLWluIHVzZXJzLiBVbmlx
dWUgaWRlbnRpZmllciBmb3IgbG9nZ2VkLWluCiB1c2VyLCBzdWNoIGFzIGEgdXNlciBuYW1l
LiBEb24ndCBzZXQgZm9yIGFub255bW91cyB1c2Vycy4KCiBBbHdheXMgdXNlIGEgaGFzaGVk
IHZhbHVlIGZvciB0aGlzIElELgoKIERvbid0IHNldCB0aGUgZmllbGQgdG8gdGhlIHNhbWUg
Zml4ZWQgSUQgZm9yIGRpZmZlcmVudCB1c2Vycy4gVGhpcyBtaXhlcwogdGhlIGV2ZW50IGhp
c3Rvcnkgb2YgdGhvc2UgdXNlcnMgdG9nZXRoZXIsIHdoaWNoIHJlc3VsdHMgaW4gZGVncmFk
ZWQKIG1vZGVsIHF1YWxpdHkuCgogVGhlIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVk
IHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3RoZXJ3
aXNlLCBhbiBgSU5WQUxJRF9BUkdVTUVOVGAgZXJyb3IgaXMgcmV0dXJuZWQuCgoNCgUEAgIA
BRIE1QECCAoNCgUEAgIAARIE1QEJEAoNCgUEAgIAAxIE1QETFAqJBAoEBAICARIE4gECGBr6
AyBVc2VyIGFnZW50IGFzIGluY2x1ZGVkIGluIHRoZSBIVFRQIGhlYWRlci4KCiBUaGUgZmll
bGQgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQg
b2YgMSwwMDAKIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gYElOVkFMSURfQVJHVU1FTlRg
IGVycm9yIGlzIHJldHVybmVkLgoKIFRoaXMgc2hvdWxkIG5vdCBiZSBzZXQgd2hlbiB1c2lu
ZyB0aGUgY2xpZW50IHNpZGUgZXZlbnQgcmVwb3J0aW5nIHdpdGgKIEdUTSBvciBKYXZhU2Ny
aXB0IHRhZyBpbgogW1VzZXJFdmVudFNlcnZpY2UuQ29sbGVjdFVzZXJFdmVudF1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlVzZXJFdmVudFNlcnZpY2UuQ29sbGVj
dFVzZXJFdmVudF0KIG9yIGlmCiBbVXNlckV2ZW50LmRpcmVjdF91c2VyX3JlcXVlc3RdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Vc2VyRXZlbnQuZGlyZWN0X3Vz
ZXJfcmVxdWVzdF0KIGlzIHNldC4KCg0KBQQCAgEFEgTiAQIICg0KBQQCAgEBEgTiAQkTCg0K
BQQCAgEDEgTiARYXClUKAgQDEgbmAQDpAQEaRyBEZWZpbmVzIGVtYmVkZGluZyBjb25maWcs
IHVzZWQgZm9yIGJyaW5nIHlvdXIgb3duIGVtYmVkZGluZ3MgZmVhdHVyZS4KCgsKAwQDARIE
5gEIFwpICgQEAwIAEgToAQIYGjogRnVsbCBmaWVsZCBwYXRoIGluIHRoZSBzY2hlbWEgbWFw
cGVkIGFzIGVtYmVkZGluZyBmaWVsZC4KCg0KBQQDAgAFEgToAQIICg0KBQQDAgABEgToAQkT
Cg0KBQQDAgADEgToARYXChwKAgQEEgbsAQDvAQEaDiBEb3VibGUgbGlzdC4KCgsKAwQEARIE
7AEIEgoeCgQEBAIAEgTuAQIdGhAgRG91YmxlIHZhbHVlcy4KCg0KBQQEAgAEEgTuAQIKCg0K
BQQEAgAFEgTuAQsRCg0KBQQEAgABEgTuARIYCg0KBQQEAgADEgTuARscCisKAgQFEgbyAQD9
AQEaHSBEZWZpbmVzIGd1aWRlZCBzZWFyY2ggc3BlYy4KCgsKAwQFARIE8gEIGApkCgQEBQIA
EgT1AQIoGlYgV2hldGhlciBvciBub3QgdG8gZW5hYmxlIGFuZCBpbmNsdWRlIHJlZmluZW1l
bnQgYXR0cmlidXRlcyBpbiBndWRpZWQgc2VhcmNoCiByZXN1bHQuCgoNCgUEBQIABRIE9QEC
BgoNCgUEBQIAARIE9QEHIwoNCgUEBQIAAxIE9QEmJwpaCgQEBQIBEgT4AQIkGkwgV2hldGhl
ciBvciBub3QgdG8gZW5hYmxlIGFuZCBpbmNsdWRlIHJlbGF0ZWQgcXVlc3Rpb25zIGluIHNl
YXJjaCByZXNwb25zZS4KCg0KBQQFAgEFEgT4AQIGCg0KBQQFAgEBEgT4AQcfCg0KBQQFAgED
EgT4ASIjCpkBCgQEBQICEgT8AQIiGooBIE1heCBudW1iZXIgb2YgcmVsYXRlZCBxdWVzdGlv
bnMgdG8gYmUgcmV0dXJuZWQuIFRoZSB2YWxpZCByYW5nZSBpcyBbMSwgNV0uCiBJZiBlbmFi
bGVfcmVsYXRlZF9xdWVzdGlvbnMgaXMgdHJ1ZSwgdGhlIGRlZmF1bHQgdmFsdWUgaXMgMy4K
Cg0KBQQFAgIFEgT8AQIHCg0KBQQFAgIBEgT8AQgdCg0KBQQFAgIDEgT8ASAhCjAKAgQGEgaA
AgCEAgEaIiBEZWZpbmVzIGN1c3RvbSBmaW5lIHR1bmluZyBzcGVjLgoKCwoDBAYBEgSAAggc
Cl0KBAQGAgASBIMCAiEaTyBXaGV0aGVyIG9yIG5vdCB0byBlbmFibGUgYW5kIGluY2x1ZGUg
Y3VzdG9tIGZpbmUgdHVuZWQgc2VhcmNoIGFkYXB0b3IKIG1vZGVsLgoKDQoFBAYCAAUSBIMC
AgYKDQoFBAYCAAESBIMCBxwKDQoFBAYCAAMSBIMCHyAKKQoCBAcSBocCAKACARobIElkZW50
aXR5IFByb3ZpZGVyIENvbmZpZy4KCgsKAwQHARIEhwIIEQopCgQEBwMAEgaJAgKNAgMaGSBU
aGlyZCBwYXJ0eSBJRFAgQ29uZmlnLgoKDQoFBAcDAAESBIkCChsKWgoGBAcDAAIAEgSMAgQj
GkogV29ya2ZvcmNlIHBvb2wgbmFtZS4KIEV4YW1wbGU6ICJsb2NhdGlvbnMvZ2xvYmFsL3dv
cmtmb3JjZVBvb2xzL3Bvb2xfaWQiCgoPCgcEBwMAAgAFEgSMAgQKCg8KBwQHAwACAAESBIwC
Cx4KDwoHBAcDAAIAAxIEjAIhIgopCgQEBwQAEgaQAgKZAgMaGSBJZGVudGl0eSBQcm92aWRl
ciBUeXBlLgoKDQoFBAcEAAESBJACBw4KOAoGBAcEAAIAEgSSAgQdGiggRGVmYXVsdCB2YWx1
ZS4gQUNMIHNlYXJjaCBub3QgZW5hYmxlZC4KCg8KBwQHBAACAAESBJICBBgKDwoHBAcEAAIA
AhIEkgIbHAolCgYEBwQAAgESBJUCBA8aFSBHb29nbGUgMVAgcHJvdmlkZXIuCgoPCgcEBwQA
AgEBEgSVAgQKCg8KBwQHBAACAQISBJUCDQ4KJwoGBAcEAAICEgSYAgQUGhcgVGhpcmQgcGFy
dHkgcHJvdmlkZXIuCgoPCgcEBwQAAgIBEgSYAgQPCg8KBwQHBAACAgISBJgCEhMKMgoEBAcC
ABIEnAICFxokIElkZW50aXR5IHByb3ZpZGVyIHR5cGUgY29uZmlndXJlZC4KCg0KBQQHAgAG
EgScAgIJCg0KBQQHAgABEgScAgoSCg0KBQQHAgADEgScAhUWCjIKBAQHAgESBJ8CAiwaJCBF
eHRlcm5hbCBJZGVudGl0eSBwcm92aWRlciBjb25maWcuCgoNCgUEBwIBBhIEnwICEwoNCgUE
BwIBARIEnwIUJwoNCgUEBwIBAxIEnwIqKwo6CgIECBIGowIAtAIBGiwgUHJpbmNpcGFsIGlk
ZW50aWZpZXIgb2YgYSB1c2VyIG9yIGEgZ3JvdXAuCgoLCgMECAESBKMCCBEKTAoEBAgIABIG
pQICswIDGjwgVW5pb24gZmllbGQgcHJpbmNpcGFsLiBQcmluY2lwYWwgY2FuIGJlIGEgdXNl
ciBvciBhIGdyb3VwLgoKDQoFBAgIAAESBKUCCBEK/AEKBAQIAgASBKsCBBca7QEgVXNlciBp
ZGVudGlmaWVyLgogRm9yIEdvb2dsZSBXb3Jrc3BhY2UgdXNlciBhY2NvdW50LCB1c2VyX2lk
IHNob3VsZCBiZSB0aGUgZ29vZ2xlIHdvcmtzcGFjZQogdXNlciBlbWFpbC4KIEZvciBub24t
Z29vZ2xlIGlkZW50aXR5IHByb3ZpZGVyIHVzZXIgYWNjb3VudCwgdXNlcl9pZCBpcyB0aGUg
bWFwcGVkIHVzZXIKIGlkZW50aWZpZXIgY29uZmlndXJlZCBkdXJpbmcgdGhlIHdvcmtmb3Jj
ZXBvb2wgY29uZmlnLgoKDQoFBAgCAAUSBKsCBAoKDQoFBAgCAAESBKsCCxIKDQoFBAgCAAMS
BKsCFRYKgQIKBAQIAgESBLICBBga8gEgR3JvdXAgaWRlbnRpZmllci4KIEZvciBHb29nbGUg
V29ya3NwYWNlIHVzZXIgYWNjb3VudCwgZ3JvdXBfaWQgc2hvdWxkIGJlIHRoZSBnb29nbGUK
IHdvcmtzcGFjZSBncm91cCBlbWFpbC4KIEZvciBub24tZ29vZ2xlIGlkZW50aXR5IHByb3Zp
ZGVyIHVzZXIgYWNjb3VudCwgZ3JvdXBfaWQgaXMgdGhlIG1hcHBlZAogZ3JvdXAgaWRlbnRp
ZmllciBjb25maWd1cmVkIGR1cmluZyB0aGUgd29ya2ZvcmNlcG9vbCBjb25maWcuCgoNCgUE
CAIBBRIEsgIECgoNCgUECAIBARIEsgILEwoNCgUECAIBAxIEsgIWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::Interval ===
    # Fields for Interval
    # Field: minimum Type: 1 ()
    # Field: exclusive_minimum Type: 1 ()
    # Field: maximum Type: 1 ()
    # Field: exclusive_maximum Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::CustomAttribute ===
    # Fields for CustomAttribute
    # Field: text Type: 9 ()
    # Field: numbers Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::UserInfo ===
    # Fields for UserInfo
    # Field: user_id Type: 9 ()
    # Field: user_agent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::EmbeddingConfig ===
    # Fields for EmbeddingConfig
    # Field: field_path Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::DoubleList ===
    # Fields for DoubleList
    # Field: values Type: 1 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::GuidedSearchSpec ===
    # Fields for GuidedSearchSpec
    # Field: enable_refinement_attributes Type: 8 ()
    # Field: enable_related_questions Type: 8 ()
    # Field: max_related_questions Type: 5 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::CustomFineTuningSpec ===
    # Fields for CustomFineTuningSpec
    # Field: enable_search_adaptor Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::IdpConfig ===
    # Fields for IdpConfig
    # Field: idp_type Type: 14 (.google.cloud.discoveryengine.v1alpha.IdpConfig.IdpType)
    # Field: external_idp_config Type: 11 (.google.cloud.discoveryengine.v1alpha.IdpConfig.ExternalIdpConfig)

# Enum: IdpConfig::IdpType
our $IdpConfig_IDP_TYPE_UNSPECIFIED = 0;
our $IdpConfig_GSUITE = 1;
our $IdpConfig_THIRD_PARTY = 2;

# === Message: Google::Cloud::Discoveryengine::V1alpha::Common::Principal ===
    # Fields for Principal
    # Field: user_id Type: 9 ()
    # Field: group_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Common - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Common;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Common::Interval->new({
        minimum => $minimum,
        exclusive_minimum => $exclusive_minimum,
        maximum => $maximum,
        exclusive_maximum => $exclusive_maximum,
    });

    # Read or update a field
    my $val = $msg->minimum();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Common::Interval->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::Interval

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

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::CustomAttribute

A custom attribute that is not explicitly modeled in a resource, e.g.
[UserEvent][google.cloud.discoveryengine.v1alpha.UserEvent].

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
[CustomAttribute.text][google.cloud.discoveryengine.v1alpha.CustomAttribute.text]
or
[CustomAttribute.numbers][google.cloud.discoveryengine.v1alpha.CustomAttribute.numbers]
should be set. Otherwise, an `INVALID_ARGUMENT` error is returned.

=item * C<< $msg->numbers() >> / C<< $msg->numbers($value) >>

Type: C<Double>

The numerical values of this custom attribute. For example, `[2.3, 15.4]`
when the key is "lengths_cm".

Exactly one of
[CustomAttribute.text][google.cloud.discoveryengine.v1alpha.CustomAttribute.text]
or
[CustomAttribute.numbers][google.cloud.discoveryengine.v1alpha.CustomAttribute.numbers]
should be set. Otherwise, an `INVALID_ARGUMENT` error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::UserInfo

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

=item * C<< $msg->user_agent() >> / C<< $msg->user_agent($value) >>

Type: C<String>

User agent as included in the HTTP header.

The field must be a UTF-8 encoded string with a length limit of 1,000
characters. Otherwise, an `INVALID_ARGUMENT` error is returned.

This should not be set when using the client side event reporting with
GTM or JavaScript tag in
[UserEventService.CollectUserEvent][google.cloud.discoveryengine.v1alpha.UserEventService.CollectUserEvent]
or if
[UserEvent.direct_user_request][google.cloud.discoveryengine.v1alpha.UserEvent.direct_user_request]
is set.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::EmbeddingConfig

Defines embedding config, used for bring your own embeddings feature.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->field_path() >> / C<< $msg->field_path($value) >>

Type: C<String>

Full field path in the schema mapped as embedding field.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::DoubleList

Double list.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Double>

Double values.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::GuidedSearchSpec

Defines guided search spec.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_refinement_attributes() >> / C<< $msg->enable_refinement_attributes($value) >>

Type: C<Bool>

Whether or not to enable and include refinement attributes in gudied search
result.

=item * C<< $msg->enable_related_questions() >> / C<< $msg->enable_related_questions($value) >>

Type: C<Bool>

Whether or not to enable and include related questions in search response.

=item * C<< $msg->max_related_questions() >> / C<< $msg->max_related_questions($value) >>

Type: C<Int32>

Max number of related questions to be returned. The valid range is [1, 5].
If enable_related_questions is true, the default value is 3.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::CustomFineTuningSpec

Defines custom fine tuning spec.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_search_adaptor() >> / C<< $msg->enable_search_adaptor($value) >>

Type: C<Bool>

Whether or not to enable and include custom fine tuned search adaptor
model.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::IdpConfig

Identity Provider Config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->idp_type() >> / C<< $msg->idp_type($value) >>

Type: C<Enum> (L<Google::Cloud::Discoveryengine::V1alpha::IdpConfig::IdpType>)

Identity provider type configured.

=item * C<< $msg->external_idp_config() >> / C<< $msg->external_idp_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Common::IdpConfig::ExternalIdpConfig>)

External Identity provider config.

=back

=head3 Enum: IdpConfig::IdpType

=over 4

=item * C<IDP_TYPE_UNSPECIFIED> => C<0>

=item * C<GSUITE> => C<1>

=item * C<THIRD_PARTY> => C<2>

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Common::Principal

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

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
