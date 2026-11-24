package Google::Cloud::Discoveryengine::V1alpha::UserEventService;

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
    eval { require Google::Api::Httpbody };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Discoveryengine::V1alpha::ImportConfig };
    eval { require Google::Cloud::Discoveryengine::V1alpha::PurgeConfig };
    eval { require Google::Cloud::Discoveryengine::V1alpha::UserEvent };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvdXNlcl9ldmVudF9zZXJ2
aWNlLnByb3RvEiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL2h0dHBib2R5LnByb3Rv
Ghlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5n
aW5lL3YxYWxwaGEvaW1wb3J0X2NvbmZpZy5wcm90bxo3Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVy
eWVuZ2luZS92MWFscGhhL3B1cmdlX2NvbmZpZy5wcm90bxo1Z29vZ2xlL2Nsb3VkL2Rpc2Nv
dmVyeWVuZ2luZS92MWFscGhhL3VzZXJfZXZlbnQucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvIusBChVXcml0ZVVzZXJFdmVudFJlcXVlc3QSSAoGcGFyZW50
GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3Rv
cmVSBnBhcmVudBJYCgp1c2VyX2V2ZW50GAIgASgLMi8uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLlVzZXJFdmVudEID4EECSABSCXVzZXJFdmVudIgBARIfCgt3cml0
ZV9hc3luYxgDIAEoCFIKd3JpdGVBc3luY0INCgtfdXNlcl9ldmVudCLFAQoXQ29sbGVjdFVz
ZXJFdmVudFJlcXVlc3QSSAoGcGFyZW50GAEgASgJQjDgQQL6QSoKKGRpc2NvdmVyeWVuZ2lu
ZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSBnBhcmVudBIiCgp1c2VyX2V2ZW50GAIgASgJ
QgPgQQJSCXVzZXJFdmVudBIVCgN1cmkYAyABKAlIAFIDdXJpiAEBEhUKA2V0cxgEIAEoA0gB
UgNldHOIAQFCBgoEX3VyaUIGCgRfZXRzMo8NChBVc2VyRXZlbnRTZXJ2aWNlEokDCg5Xcml0
ZVVzZXJFdmVudBI7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5Xcml0
ZVVzZXJFdmVudFJlcXVlc3QaLy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuVXNlckV2ZW50IogCgtPkkwKBAiJGL3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50czp3cml0ZToKdXNlcl9ldmVudFpi
IlQvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMv
Ki9kYXRhU3RvcmVzLyp9L3VzZXJFdmVudHM6d3JpdGU6CnVzZXJfZXZlbnRaRyI5L3YxYWxw
aGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS91c2VyRXZlbnRzOndyaXRlOgp1
c2VyX2V2ZW50EtQCChBDb2xsZWN0VXNlckV2ZW50Ej0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MWFscGhhLkNvbGxlY3RVc2VyRXZlbnRSZXF1ZXN0GhQuZ29vZ2xlLmFwaS5I
dHRwQm9keSLqAYLT5JMC4wESSC92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVudHM6Y29sbGVjdFpYElYvdjFhbHBoYS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9
L3VzZXJFdmVudHM6Y29sbGVjdFo9EjsvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyp9L3VzZXJFdmVudHM6Y29sbGVjdBKdAwoPUHVyZ2VVc2VyRXZlbnRzEjwuZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlB1cmdlVXNlckV2ZW50c1JlcXVl
c3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqwCgtPkkwKmASJGL3YxYWxwaGEv
e3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50
czpwdXJnZToBKlpZIlQvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVudHM6cHVyZ2U6ASrKQXwKPGdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5QdXJnZVVzZXJFdmVudHNSZXNw
b25zZRI8Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlB1cmdlVXNlckV2
ZW50c01ldGFkYXRhEqMDChBJbXBvcnRVc2VyRXZlbnRzEj0uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWFscGhhLkltcG9ydFVzZXJFdmVudHNSZXF1ZXN0Gh0uZ29vZ2xlLmxv
bmdydW5uaW5nLk9wZXJhdGlvbiKwAoLT5JMCqAEiRy92MWFscGhhL3twYXJlbnQ9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9L3VzZXJFdmVudHM6aW1wb3J0OgEqWloi
VS92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8q
L2RhdGFTdG9yZXMvKn0vdXNlckV2ZW50czppbXBvcnQ6ASrKQX4KPWdvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFhbHBoYS5JbXBvcnRVc2VyRXZlbnRzUmVzcG9uc2USPWdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5JbXBvcnRVc2VyRXZlbnRzTWV0YWRh
dGEaUspBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdv
b2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CoQIKKGNvbS5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGFCFVVzZXJFdmVudFNlcnZpY2VQcm90b1ABWlJjbG91
ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MWFscGhhL2Rpc2NvdmVyeWVu
Z2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIkR29vZ2xlLkNs
b3VkLkRpc2NvdmVyeUVuZ2luZS5WMUFscGhhygIkR29vZ2xlXENsb3VkXERpc2NvdmVyeUVu
Z2luZVxWMWFscGhh6gInR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWFscGhh
Sv4iCgcSBQ4ArAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAtCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYAIwoJCgIDBRIDFwBCCgkKAgMGEgMYAEEKCQoCAwcSAxkAPwoJCgIDCBIDGgAtCggKAQgS
AxwAQQoJCgIIJRIDHABBCggKAQgSAx0AaQoJCgIICxIDHQBpCggKAQgSAx4AIgoJCgIIChID
HgAiCggKAQgSAx8ANgoJCgIICBIDHwA2CggKAQgSAyAAQQoJCgIIARIDIABBCggKAQgSAyEA
LQoJCgIIJBIDIQAtCggKAQgSAyIAQQoJCgIIKRIDIgBBCggKAQgSAyMAQAoJCgIILRIDIwBA
CloKAgYAEgQmAHYBGk4gU2VydmljZSBmb3IgaW5nZXN0aW5nIGVuZCB1c2VyIGFjdGlvbnMg
b24gYSB3ZWJzaXRlIHRvIERpc2NvdmVyeSBFbmdpbmUgQVBJLgoKCgoDBgABEgMmCBgKCgoD
BgADEgMnAkYKDAoFBgADmQgSAycCRgoLCgMGAAMSBCgCKTcKDQoFBgADmggSBCgCKTcKKwoE
BgACABIELAI5AxodIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50LgoKDAoFBgACAAESAywG
FAoMCgUGAAIAAhIDLBUqCgwKBQYAAgADEgMsNT4KDQoFBgACAAQSBC0EOAYKEQoJBgACAASw
yrwiEgQtBDgGCqYCCgQGAAIBEgRAAkoDGpcCIFdyaXRlcyBhIHNpbmdsZSB1c2VyIGV2ZW50
IGZyb20gdGhlIGJyb3dzZXIuIFRoaXMgdXNlcyBhIEdFVCByZXF1ZXN0IHRvCiBkdWUgdG8g
YnJvd3NlciByZXN0cmljdGlvbiBvZiBQT1NULWluZyB0byBhIHRoaXJkLXBhcnR5IGRvbWFp
bi4KCiBUaGlzIG1ldGhvZCBpcyB1c2VkIG9ubHkgYnkgdGhlIERpc2NvdmVyeSBFbmdpbmUg
QVBJIEphdmFTY3JpcHQgcGl4ZWwgYW5kCiBHb29nbGUgVGFnIE1hbmFnZXIuIFVzZXJzIHNo
b3VsZCBub3QgY2FsbCB0aGlzIG1ldGhvZCBkaXJlY3RseS4KCgwKBQYAAgEBEgNABhYKDAoF
BgACAQISA0AXLgoMCgUGAAIBAxIDQDlMCg0KBQYAAgEEEgRBBEkGChEKCQYAAgEEsMq8IhIE
QQRJBgr3AQoEBgACAhIEUAJeAxroASBEZWxldGVzIHBlcm1hbmVudGx5IGFsbCB1c2VyIGV2
ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciBwcm92aWRlZC4KIERlcGVuZGluZyBvbiB0
aGUgbnVtYmVyIG9mIGV2ZW50cyBzcGVjaWZpZWQgYnkgdGhlIGZpbHRlciwgdGhpcyBvcGVy
YXRpb24KIGNvdWxkIHRha2UgaG91cnMgb3IgZGF5cyB0byBjb21wbGV0ZS4gVG8gdGVzdCBh
IGZpbHRlciwgdXNlIHRoZSBsaXN0CiBjb21tYW5kIGZpcnN0LgoKDAoFBgACAgESA1AGFQoM
CgUGAAICAhIDUBYsCgwKBQYAAgIDEgNRDysKDQoFBgACAgQSBFIEWQYKEQoJBgACAgSwyrwi
EgRSBFkGCg0KBQYAAgIEEgRaBF0GCg8KBwYAAgIEmQgSBFoEXQYK5gIKBAYAAgMSBGcCdQMa
1wIgQnVsayBpbXBvcnQgb2YgdXNlciBldmVudHMuIFJlcXVlc3QgcHJvY2Vzc2luZyBtaWdo
dCBiZQogc3luY2hyb25vdXMuIEV2ZW50cyB0aGF0IGFscmVhZHkgZXhpc3QgYXJlIHNraXBw
ZWQuCiBVc2UgdGhpcyBtZXRob2QgZm9yIGJhY2tmaWxsaW5nIGhpc3RvcmljYWwgdXNlciBl
dmVudHMuCgogT3BlcmF0aW9uLnJlc3BvbnNlIGlzIG9mIHR5cGUgSW1wb3J0UmVzcG9uc2Uu
IE5vdGUgdGhhdCBpdCBpcwogcG9zc2libGUgZm9yIGEgc3Vic2V0IG9mIHRoZSBpdGVtcyB0
byBiZSBzdWNjZXNzZnVsbHkgaW5zZXJ0ZWQuCiBPcGVyYXRpb24ubWV0YWRhdGEgaXMgb2Yg
dHlwZSBJbXBvcnRNZXRhZGF0YS4KCgwKBQYAAgMBEgNnBhYKDAoFBgACAwISA2cXLgoMCgUG
AAIDAxIDaA8rCg0KBQYAAgMEEgRpBHAGChEKCQYAAgMEsMq8IhIEaQRwBgoNCgUGAAIDBBIE
cQR0BgoPCgcGAAIDBJkIEgRxBHQGCjkKAgQAEgV5AJEBARosIFJlcXVlc3QgbWVzc2FnZSBm
b3IgV3JpdGVVc2VyRXZlbnQgbWV0aG9kLgoKCgoDBAABEgN5CB0KuAQKBAQAAgASBoQBAokB
BBqnBCBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLgogSWYgdGhlIHdyaXRl
IHVzZXIgZXZlbnQgYWN0aW9uIGlzIGFwcGxpZWQgaW4KIFtEYXRhU3RvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5EYXRhU3RvcmVdIGxldmVsLCB0aGUKIGZv
cm1hdCBpczoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29s
bGVjdGlvbnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9YC4KIElmIHRo
ZSB3cml0ZSB1c2VyIGV2ZW50IGFjdGlvbiBpcyBhcHBsaWVkIGluIFtMb2NhdGlvbl1bXSBs
ZXZlbCwgZm9yCiBleGFtcGxlLCB0aGUgZXZlbnQgd2l0aAogW0RvY3VtZW50XVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRG9jdW1lbnRdIGFjcm9zcyBtdWx0aXBs
ZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkRh
dGFTdG9yZV0sIHRoZSBmb3JtYXQgaXM6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259YC4KCg0KBQQAAgAFEgSEAQIICg0KBQQAAgABEgSEAQkPCg0KBQQAAgAD
EgSEARITCg8KBQQAAgAIEgaEARSJAQMKEAoIBAACAAicCAASBIUBBCoKEQoHBAACAAifCBIG
hgEEiAEFCi4KBAQAAgESBIwBAk0aICBSZXF1aXJlZC4gVXNlciBldmVudCB0byB3cml0ZS4K
Cg0KBQQAAgEEEgSMAQIKCg0KBQQAAgEGEgSMAQsUCg0KBQQAAgEBEgSMARUfCg0KBQQAAgED
EgSMASIjCg0KBQQAAgEIEgSMASRMChAKCAQAAgEInAgAEgSMASVLCpABCgQEAAICEgSQAQIX
GoEBIElmIHNldCB0byB0cnVlLCB0aGUgdXNlciBldmVudCBpcyB3cml0dGVuIGFzeW5jaHJv
bm91c2x5IGFmdGVyCiB2YWxpZGF0aW9uLCBhbmQgdGhlIEFQSSByZXNwb25kcyB3aXRob3V0
IHdhaXRpbmcgZm9yIHRoZSB3cml0ZS4KCg0KBQQAAgIFEgSQAQIGCg0KBQQAAgIBEgSQAQcS
Cg0KBQQAAgIDEgSQARUWCjwKAgQBEgaUAQCsAQEaLiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIENv
bGxlY3RVc2VyRXZlbnQgbWV0aG9kLgoKCwoDBAEBEgSUAQgfCqUBCgQEAQIAEgaXAQKcAQQa
lAEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgRGF0YVN0b3JlIHJlc291cmNlIG5hbWUsIHN1Y2gg
YXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlv
bnMve2NvbGxlY3Rpb259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9YC4KCg0KBQQBAgAFEgSX
AQIICg0KBQQBAgABEgSXAQkPCg0KBQQBAgADEgSXARITCg8KBQQBAgAIEgaXARScAQMKEAoI
BAECAAicCAASBJgBBCoKEQoHBAECAAifCBIGmQEEmwEFCmMKBAQBAgESBKABAkEaVSBSZXF1
aXJlZC4gVVJMIGVuY29kZWQgVXNlckV2ZW50IHByb3RvIHdpdGggYSBsZW5ndGggbGltaXQg
b2YgMiwwMDAsMDAwCiBjaGFyYWN0ZXJzLgoKDQoFBAECAQUSBKABAggKDQoFBAECAQESBKAB
CRMKDQoFBAECAQMSBKABFhcKDQoFBAECAQgSBKABGEAKEAoIBAECAQicCAASBKABGT8K8gEK
BAQBAgISBKYBAhoa4wEgVGhlIFVSTCBpbmNsdWRpbmcgY2dpLXBhcmFtZXRlcnMgYnV0IGV4
Y2x1ZGluZyB0aGUgaGFzaCBmcmFnbWVudCB3aXRoIGEKIGxlbmd0aCBsaW1pdCBvZiA1LDAw
MCBjaGFyYWN0ZXJzLiBUaGlzIGlzIG9mdGVuIG1vcmUgdXNlZnVsIHRoYW4gdGhlCiByZWZl
cmVyIFVSTCwgYmVjYXVzZSBtYW55IGJyb3dzZXJzIG9ubHkgc2VuZCB0aGUgZG9tYWluIGZv
ciB0aGlyZC1wYXJ0eQogcmVxdWVzdHMuCgoNCgUEAQICBBIEpgECCgoNCgUEAQICBRIEpgEL
EQoNCgUEAQICARIEpgESFQoNCgUEAQICAxIEpgEYGQqvAQoEBAECAxIEqwECGRqgASBUaGUg
ZXZlbnQgdGltZXN0YW1wIGluIG1pbGxpc2Vjb25kcy4gVGhpcyBwcmV2ZW50cyBicm93c2Vy
IGNhY2hpbmcgb2YKIG90aGVyd2lzZSBpZGVudGljYWwgZ2V0IHJlcXVlc3RzLiBUaGUgbmFt
ZSBpcyBhYmJyZXZpYXRlZCB0byByZWR1Y2UgdGhlCiBwYXlsb2FkIGJ5dGVzLgoKDQoFBAEC
AwQSBKsBAgoKDQoFBAECAwUSBKsBCxAKDQoFBAECAwESBKsBERQKDQoFBAECAwMSBKsBFxhi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest ===
    # Fields for WriteUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 11 (.google.cloud.discoveryengine.v1alpha.UserEvent)
    # Field: write_async Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1alpha::UserEventService::CollectUserEventRequest ===
    # Fields for CollectUserEventRequest
    # Field: parent Type: 9 ()
    # Field: user_event Type: 9 ()
    # Field: uri Type: 9 ()
    # Field: ets Type: 3 ()

# === Service Client: Google::Cloud::Discoveryengine::V1alpha::UserEventService::UserEventServiceClient ===
package Google::Cloud::Discoveryengine::V1alpha::UserEventService::UserEventServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1alpha::UserEventService::UserEventServiceClient

Client stub representing the remote C<UserEventService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub write_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.UserEventService',
        method         => 'WriteUserEvent',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent',
    });
}

sub collect_user_event {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::UserEventService::CollectUserEventRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.UserEventService',
        method         => 'CollectUserEvent',
        request        => $req,
        response_class => 'Google::Api::Httpbody::HttpBody',
    });
}

sub purge_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.UserEventService',
        method         => 'PurgeUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_user_events {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1alpha::ImportConfig::ImportUserEventsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1alpha.UserEventService',
        method         => 'ImportUserEvents',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::UserEventService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/user_event_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::UserEventService;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest->new({
        parent => $parent,
        user_event => $user_event,
        write_async => $write_async,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/user_event_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::UserEventService::WriteUserEventRequest

Request message for WriteUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name.
If the write user event action is applied in
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore] level, the
format is:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.
If the write user event action is applied in [Location][] level, for
example, the event with
[Document][google.cloud.discoveryengine.v1alpha.Document] across multiple
[DataStore][google.cloud.discoveryengine.v1alpha.DataStore], the format is:
`projects/{project}/locations/{location}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::UserEvent::UserEvent>)

Required. User event to write.

=item * C<< $msg->write_async() >> / C<< $msg->write_async($value) >>

Type: C<Bool>

If set to true, the user event is written asynchronously after
validation, and the API responds without waiting for the write.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::UserEventService::CollectUserEventRequest

Request message for CollectUserEvent method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent DataStore resource name, such as
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}`.

=item * C<< $msg->user_event() >> / C<< $msg->user_event($value) >>

Type: C<String>

Required. URL encoded UserEvent proto with a length limit of 2,000,000
characters.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URL including cgi-parameters but excluding the hash fragment with a
length limit of 5,000 characters. This is often more useful than the
referer URL, because many browsers only send the domain for third-party
requests.

=item * C<< $msg->ets() >> / C<< $msg->ets($value) >>

Type: C<Int64>

The event timestamp in milliseconds. This prevents browser caching of
otherwise identical get requests. The name is abbreviated to reduce the
payload bytes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::UserEventService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
