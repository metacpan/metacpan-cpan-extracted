package Google::Cloud::Contentwarehouse::V1::DocumentSchemaService;

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
    eval { require Google::Cloud::Contentwarehouse::V1::DocumentSchema };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9zY2hlbWFfc2Vy
dmljZS5wcm90bxIgZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUv
YXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjZn
b29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9kb2N1bWVudF9zY2hlbWEucHJvdG8a
G2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90byLHAQobQ3JlYXRlRG9jdW1lbnRTY2hlbWFS
ZXF1ZXN0EkgKBnBhcmVudBgBIAEoCUIw4EEC+kEqCihjb250ZW50d2FyZWhvdXNlLmdvb2ds
ZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSXgoPZG9jdW1lbnRfc2NoZW1hGAIgASgLMjAu
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9jdW1lbnRTY2hlbWFCA+BBAlIO
ZG9jdW1lbnRTY2hlbWEiZgoYR2V0RG9jdW1lbnRTY2hlbWFSZXF1ZXN0EkoKBG5hbWUYASAB
KAlCNuBBAvpBMAouY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudFNj
aGVtYVIEbmFtZSLJAQobVXBkYXRlRG9jdW1lbnRTY2hlbWFSZXF1ZXN0EkoKBG5hbWUYASAB
KAlCNuBBAvpBMAouY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Eb2N1bWVudFNj
aGVtYVIEbmFtZRJeCg9kb2N1bWVudF9zY2hlbWEYAiABKAsyMC5nb29nbGUuY2xvdWQuY29u
dGVudHdhcmVob3VzZS52MS5Eb2N1bWVudFNjaGVtYUID4EECUg5kb2N1bWVudFNjaGVtYSJp
ChtEZWxldGVEb2N1bWVudFNjaGVtYVJlcXVlc3QSSgoEbmFtZRgBIAEoCUI24EEC+kEwCi5j
b250ZW50d2FyZWhvdXNlLmdvb2dsZWFwaXMuY29tL0RvY3VtZW50U2NoZW1hUgRuYW1lIqIB
ChpMaXN0RG9jdW1lbnRTY2hlbWFzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgoo
Y29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBh
Z2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu
IqIBChtMaXN0RG9jdW1lbnRTY2hlbWFzUmVzcG9uc2USWwoQZG9jdW1lbnRfc2NoZW1hcxgB
IAMoCzIwLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkRvY3VtZW50U2NoZW1h
Ug9kb2N1bWVudFNjaGVtYXMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuMpUJChVEb2N1bWVudFNjaGVtYVNlcnZpY2US7gEKFENyZWF0ZURvY3VtZW50U2NoZW1h
Ej0uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuQ3JlYXRlRG9jdW1lbnRTY2hl
bWFSZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRG9jdW1lbnRT
Y2hlbWEiZYLT5JMCRiIzL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vZG9j
dW1lbnRTY2hlbWFzOg9kb2N1bWVudF9zY2hlbWHaQRZwYXJlbnQsZG9jdW1lbnRfc2NoZW1h
Et4BChRVcGRhdGVEb2N1bWVudFNjaGVtYRI9Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhv
dXNlLnYxLlVwZGF0ZURvY3VtZW50U2NoZW1hUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5jb250
ZW50d2FyZWhvdXNlLnYxLkRvY3VtZW50U2NoZW1hIlWC0+STAjgyMy92MS97bmFtZT1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50U2NoZW1hcy8qfToBKtpBFG5hbWUsZG9jdW1l
bnRfc2NoZW1hEsUBChFHZXREb2N1bWVudFNjaGVtYRI6Lmdvb2dsZS5jbG91ZC5jb250ZW50
d2FyZWhvdXNlLnYxLkdldERvY3VtZW50U2NoZW1hUmVxdWVzdBowLmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLkRvY3VtZW50U2NoZW1hIkKC0+STAjUSMy92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50U2NoZW1hcy8qfdpBBG5hbWUSsQEKFERl
bGV0ZURvY3VtZW50U2NoZW1hEj0uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEu
RGVsZXRlRG9jdW1lbnRTY2hlbWFSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IkKC
0+STAjUqMy92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RvY3VtZW50U2NoZW1h
cy8qfdpBBG5hbWUS2AEKE0xpc3REb2N1bWVudFNjaGVtYXMSPC5nb29nbGUuY2xvdWQuY29u
dGVudHdhcmVob3VzZS52MS5MaXN0RG9jdW1lbnRTY2hlbWFzUmVxdWVzdBo9Lmdvb2dsZS5j
bG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkxpc3REb2N1bWVudFNjaGVtYXNSZXNwb25zZSJE
gtPkkwI1EjMvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kb2N1bWVudFNj
aGVtYXPaQQZwYXJlbnQaU8pBH2NvbnRlbnR3YXJlaG91c2UuZ29vZ2xlYXBpcy5jb23SQS5o
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQoICCiRjb20u
Z29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjFCGkRvY3VtZW50U2NoZW1hU2Vydmlj
ZVByb3RvUAFaUGNsb3VkLmdvb2dsZS5jb20vZ28vY29udGVudHdhcmVob3VzZS9hcGl2MS9j
b250ZW50d2FyZWhvdXNlcGI7Y29udGVudHdhcmVob3VzZXBiqgIgR29vZ2xlLkNsb3VkLkNv
bnRlbnRXYXJlaG91c2UuVjHKAiBHb29nbGVcQ2xvdWRcQ29udGVudFdhcmVob3VzZVxWMeoC
I0dvb2dsZTo6Q2xvdWQ6OkNvbnRlbnRXYXJlaG91c2U6OlYxSpcnCgcSBQ4AtAEBCrwECgEM
EgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRo
ZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1h
eSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNl
bnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0
dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1
aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdh
cmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFu
ICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBB
TlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBm
b3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxp
bWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACYKCQoC
AwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAQAoJCgIDBRIDFwAlCggK
AQgSAxkAPQoJCgIIJRIDGQA9CggKAQgSAxoAZwoJCgIICxIDGgBnCggKAQgSAxsAIgoJCgII
ChIDGwAiCggKAQgSAxwAOwoJCgIICBIDHAA7CggKAQgSAx0APQoJCgIIARIDHQA9CggKAQgS
Ax4APQoJCgIIKRIDHgA9CggKAQgSAx8APAoJCgIILRIDHwA8CjsKAgYAEgQiAF0BGi8gVGhp
cyBzZXJ2aWNlIGxldHMgeW91IG1hbmFnZSBkb2N1bWVudCBzY2hlbWEuCgoKCgMGAAESAyII
HQoKCgMGAAMSAyMCRwoMCgUGAAOZCBIDIwJHCgsKAwYAAxIEJAIlNwoNCgUGAAOaCBIEJAIl
NwoqCgQGAAIAEgQoAi8DGhwgQ3JlYXRlcyBhIGRvY3VtZW50IHNjaGVtYS4KCgwKBQYAAgAB
EgMoBhoKDAoFBgACAAISAygbNgoMCgUGAAIAAxIDKQ8dCg0KBQYAAgAEEgQqBC0GChEKCQYA
AgAEsMq8IhIEKgQtBgoMCgUGAAIABBIDLgRECg8KCAYAAgAEmwgAEgMuBEQK0QMKBAYAAgES
BDgCPwMawgMgVXBkYXRlcyBhIERvY3VtZW50IFNjaGVtYS4gUmV0dXJucyBJTlZBTElEX0FS
R1VNRU5UIGlmIHRoZSBuYW1lIG9mIHRoZQogRG9jdW1lbnQgU2NoZW1hIGlzIG5vbi1lbXB0
eSBhbmQgZG9lcyBub3QgZXF1YWwgdGhlIGV4aXN0aW5nIG5hbWUuCiBTdXBwb3J0cyBvbmx5
IGFwcGVuZGluZyBuZXcgcHJvcGVydGllcywgYWRkaW5nIG5ldyBFTlVNIHBvc3NpYmxlIHZh
bHVlcywKIGFuZCB1cGRhdGluZyB0aGUKIFtFbnVtVHlwZU9wdGlvbnMudmFsaWRhdGlvbl9j
aGVja19kaXNhYmxlZF1bZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuRW51bVR5
cGVPcHRpb25zLnZhbGlkYXRpb25fY2hlY2tfZGlzYWJsZWRdCiBmbGFnIGZvciBFTlVNIHBv
c3NpYmxlIHZhbHVlcy4gVXBkYXRpbmcgZXhpc3RpbmcgcHJvcGVydGllcyB3aWxsIHJlc3Vs
dAogaW50byBJTlZBTElEX0FSR1VNRU5ULgoKDAoFBgACAQESAzgGGgoMCgUGAAIBAhIDOBs2
CgwKBQYAAgEDEgM5Dx0KDQoFBgACAQQSBDoEPQYKEQoJBgACAQSwyrwiEgQ6BD0GCgwKBQYA
AgEEEgM+BEIKDwoIBgACAQSbCAASAz4EQgphCgQGAAICEgRDAkgDGlMgR2V0cyBhIGRvY3Vt
ZW50IHNjaGVtYS4gUmV0dXJucyBOT1RfRk9VTkQgaWYgdGhlIGRvY3VtZW50IHNjaGVtYSBk
b2VzIG5vdAogZXhpc3QuCgoMCgUGAAICARIDQwYXCgwKBQYAAgICEgNDGDAKDAoFBgACAgMS
A0M7SQoNCgUGAAICBBIERARGBgoRCgkGAAICBLDKvCISBEQERgYKDAoFBgACAgQSA0cEMgoP
CggGAAICBJsIABIDRwQyCrABCgQGAAIDEgRNAlMDGqEBIERlbGV0ZXMgYSBkb2N1bWVudCBz
Y2hlbWEuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSBkb2N1bWVudCBzY2hlbWEgZG9lcwog
bm90IGV4aXN0LiBSZXR1cm5zIEJBRF9SRVFVRVNUIGlmIHRoZSBkb2N1bWVudCBzY2hlbWEg
aGFzIGRvY3VtZW50cwogZGVwZW5kaW5nIG9uIGl0LgoKDAoFBgACAwESA00GGgoMCgUGAAID
AhIDTRs2CgwKBQYAAgMDEgNODyQKDQoFBgACAwQSBE8EUQYKEQoJBgACAwSwyrwiEgRPBFEG
CgwKBQYAAgMEEgNSBDIKDwoIBgACAwSbCAASA1IEMgonCgQGAAIEEgRWAlwDGhkgTGlzdHMg
ZG9jdW1lbnQgc2NoZW1hcy4KCgwKBQYAAgQBEgNWBhkKDAoFBgACBAISA1YaNAoMCgUGAAIE
AxIDVw8qCg0KBQYAAgQEEgRYBFoGChEKCQYAAgQEsMq8IhIEWARaBgoMCgUGAAIEBBIDWwQ0
Cg8KCAYAAgQEmwgAEgNbBDQKTQoCBAASBGAAawEaQSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERv
Y3VtZW50U2NoZW1hU2VydmljZS5DcmVhdGVEb2N1bWVudFNjaGVtYS4KCgoKAwQAARIDYAgj
CioKBAQAAgASBGICZwQaHCBSZXF1aXJlZC4gVGhlIHBhcmVudCBuYW1lLgoKDAoFBAACAAUS
A2ICCAoMCgUEAAIAARIDYgkPCgwKBQQAAgADEgNiEhMKDQoFBAACAAgSBGIUZwMKDwoIBAAC
AAicCAASA2MEKgoPCgcEAAIACJ8IEgRkBGYFCjcKBAQAAgESA2oCThoqIFJlcXVpcmVkLiBU
aGUgZG9jdW1lbnQgc2NoZW1hIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNqAhAKDAoFBAACAQES
A2oRIAoMCgUEAAIBAxIDaiMkCgwKBQQAAgEIEgNqJU0KDwoIBAACAQicCAASA2omTApKCgIE
ARIEbgB2ARo+IFJlcXVlc3QgbWVzc2FnZSBmb3IgRG9jdW1lbnRTY2hlbWFTZXJ2aWNlLkdl
dERvY3VtZW50U2NoZW1hLgoKCgoDBAEBEgNuCCAKRgoEBAECABIEcAJ1BBo4IFJlcXVpcmVk
LiBUaGUgbmFtZSBvZiB0aGUgZG9jdW1lbnQgc2NoZW1hIHRvIHJldHJpZXZlLgoKDAoFBAEC
AAUSA3ACCAoMCgUEAQIAARIDcAkNCgwKBQQBAgADEgNwEBEKDQoFBAECAAgSBHASdQMKDwoI
BAECAAicCAASA3EEKgoPCgcEAQIACJ8IEgRyBHQFCk4KAgQCEgV5AIYBARpBIFJlcXVlc3Qg
bWVzc2FnZSBmb3IgRG9jdW1lbnRTY2hlbWFTZXJ2aWNlLlVwZGF0ZURvY3VtZW50U2NoZW1h
LgoKCgoDBAIBEgN5CCMKpQEKBAQCAgASBX0CggEEGpUBIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgZG9jdW1lbnQgc2NoZW1hIHRvIHVwZGF0ZS4KIEZvcm1hdDoKIHByb2plY3RzL3tw
cm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vZG9jdW1lbnRTY2hlbWFzL3tk
b2N1bWVudF9zY2hlbWFfaWR9LgoKDAoFBAICAAUSA30CCAoMCgUEAgIAARIDfQkNCgwKBQQC
AgADEgN9EBEKDgoFBAICAAgSBX0SggEDCg8KCAQCAgAInAgAEgN+BCoKEAoHBAICAAifCBIF
fwSBAQUKPQoEBAICARIEhQECThovIFJlcXVpcmVkLiBUaGUgZG9jdW1lbnQgc2NoZW1hIHRv
IHVwZGF0ZSB3aXRoLgoKDQoFBAICAQYSBIUBAhAKDQoFBAICAQESBIUBESAKDQoFBAICAQMS
BIUBIyQKDQoFBAICAQgSBIUBJU0KEAoIBAICAQicCAASBIUBJkwKTwoCBAMSBokBAJEBARpB
IFJlcXVlc3QgbWVzc2FnZSBmb3IgRG9jdW1lbnRTY2hlbWFTZXJ2aWNlLkRlbGV0ZURvY3Vt
ZW50U2NoZW1hLgoKCwoDBAMBEgSJAQgjCkYKBAQDAgASBosBApABBBo2IFJlcXVpcmVkLiBU
aGUgbmFtZSBvZiB0aGUgZG9jdW1lbnQgc2NoZW1hIHRvIGRlbGV0ZS4KCg0KBQQDAgAFEgSL
AQIICg0KBQQDAgABEgSLAQkNCg0KBQQDAgADEgSLARARCg8KBQQDAgAIEgaLARKQAQMKEAoI
BAMCAAicCAASBIwBBCoKEQoHBAMCAAifCBIGjQEEjwEFCk4KAgQEEgaUAQCqAQEaQCBSZXF1
ZXN0IG1lc3NhZ2UgZm9yIERvY3VtZW50U2NoZW1hU2VydmljZS5MaXN0RG9jdW1lbnRTY2hl
bWFzLgoKCwoDBAQBEgSUAQgiCpEBCgQEBAIAEgaXAQKcAQQagAEgUmVxdWlyZWQuIFRoZSBw
YXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIGRvY3VtZW50IHNjaGVtYXMu
CiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlv
bn0uCgoNCgUEBAIABRIElwECCAoNCgUEBAIAARIElwEJDwoNCgUEBAIAAxIElwESEwoPCgUE
BAIACBIGlwEUnAEDChAKCAQEAgAInAgAEgSYAQQqChEKBwQEAgAInwgSBpkBBJsBBQr3AQoE
BAQCARIEogECFhroASBUaGUgbWF4aW11bSBudW1iZXIgb2YgZG9jdW1lbnQgc2NoZW1hcyB0
byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heSByZXR1cm4KIGZld2VyIHRoYW4gdGhpcyB2YWx1
ZS4KIElmIHVuc3BlY2lmaWVkLCBhdCBtb3N0IDUwIGRvY3VtZW50IHNjaGVtYXMgd2lsbCBi
ZSByZXR1cm5lZC4KIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEwMDA7IHZhbHVlcyBhYm92ZSAx
MDAwIHdpbGwgYmUgY29lcmNlZCB0byAxMDAwLgoKDQoFBAQCAQUSBKIBAgcKDQoFBAQCAQES
BKIBCBEKDQoFBAQCAQMSBKIBFBUK/wEKBAQEAgISBKkBAhga8AEgQSBwYWdlIHRva2VuLCBy
ZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3REb2N1bWVudFNjaGVtYXNgIGNhbGwuCiBQ
cm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVlbnQgcGFnZS4KCiBXaGVuIHBh
Z2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvIGBMaXN0RG9jdW1l
bnRTY2hlbWFzYAogbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHByb3ZpZGVkIHRoZSBwYWdl
IHRva2VuLgoKDQoFBAQCAgUSBKkBAggKDQoFBAQCAgESBKkBCRMKDQoFBAQCAgMSBKkBFhcK
TwoCBAUSBq0BALQBARpBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yIERvY3VtZW50U2NoZW1hU2Vy
dmljZS5MaXN0RG9jdW1lbnRTY2hlbWFzLgoKCwoDBAUBEgStAQgjCj8KBAQFAgASBK8BAi8a
MSBUaGUgZG9jdW1lbnQgc2NoZW1hcyBmcm9tIHRoZSBzcGVjaWZpZWQgcGFyZW50LgoKDQoF
BAUCAAQSBK8BAgoKDQoFBAUCAAYSBK8BCxkKDQoFBAUCAAESBK8BGioKDQoFBAUCAAMSBK8B
LS4KkAEKBAQFAgESBLMBAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBh
Z2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuCiBJZiB0aGlzIGZpZWxkIGlz
IG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAUCAQUSBLMB
AggKDQoFBAUCAQESBLMBCRgKDQoFBAUCAQMSBLMBGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest ===
    # Fields for CreateDocumentSchemaRequest
    # Field: parent Type: 9 ()
    # Field: document_schema Type: 11 (.google.cloud.contentwarehouse.v1.DocumentSchema)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest ===
    # Fields for GetDocumentSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest ===
    # Fields for UpdateDocumentSchemaRequest
    # Field: name Type: 9 ()
    # Field: document_schema Type: 11 (.google.cloud.contentwarehouse.v1.DocumentSchema)

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest ===
    # Fields for DeleteDocumentSchemaRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest ===
    # Fields for ListDocumentSchemasRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse ===
    # Fields for ListDocumentSchemasResponse
    # Field: document_schemas Type: 11 (.google.cloud.contentwarehouse.v1.DocumentSchema)
    # Field: next_page_token Type: 9 ()

# === Service Client: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DocumentSchemaServiceClient ===
package Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DocumentSchemaServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DocumentSchemaServiceClient

Client stub representing the remote C<DocumentSchemaService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<contentwarehouse.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'contentwarehouse.googleapis.com:443' );

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

sub create_document_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentSchemaService',
        method         => 'CreateDocumentSchema',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema',
    });
}

sub update_document_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentSchemaService',
        method         => 'UpdateDocumentSchema',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema',
    });
}

sub get_document_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentSchemaService',
        method         => 'GetDocumentSchema',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema',
    });
}

sub delete_document_schema {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentSchemaService',
        method         => 'DeleteDocumentSchema',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_document_schemas {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.DocumentSchemaService',
        method         => 'ListDocumentSchemas',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentSchemaService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/document_schema_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::DocumentSchemaService;

    my $msg = Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest->new({
        parent => $parent,
        document_schema => $document_schema,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/document_schema_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest

Request message for DocumentSchemaService.CreateDocumentSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent name.

=item * C<< $msg->document_schema() >> / C<< $msg->document_schema($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema>)

Required. The document schema to create.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::GetDocumentSchemaRequest

Request message for DocumentSchemaService.GetDocumentSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document schema to retrieve.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::UpdateDocumentSchemaRequest

Request message for DocumentSchemaService.UpdateDocumentSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document schema to update.
Format:
projects/{project_number}/locations/{location}/documentSchemas/{document_schema_id}.

=item * C<< $msg->document_schema() >> / C<< $msg->document_schema($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema>)

Required. The document schema to update with.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::DeleteDocumentSchemaRequest

Request message for DocumentSchemaService.DeleteDocumentSchema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the document schema to delete.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasRequest

Request message for DocumentSchemaService.ListDocumentSchemas.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of document schemas.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of document schemas to return. The service may return
fewer than this value.
If unspecified, at most 50 document schemas will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListDocumentSchemas` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListDocumentSchemas`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::ListDocumentSchemasResponse

Response message for DocumentSchemaService.ListDocumentSchemas.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->document_schemas() >> / C<< $msg->document_schemas($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema>)

The document schemas from the specified parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
