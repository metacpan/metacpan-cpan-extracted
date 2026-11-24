package Google::Cloud::Networkservices::V1::TlsRoute;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvbmV0d29ya3NlcnZpY2VzL3YxL3Rsc19yb3V0ZS5wcm90bxIfZ29v
Z2xlLmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1
cmF0aW9uLnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLdCgoIVGxzUm91dGUSFwoEbmFtZRgBIAEoCUID
4EEIUgRuYW1lEiAKCXNlbGZfbGluaxgIIAEoCUID4EEDUghzZWxmTGluaxJACgtjcmVhdGVf
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGlt
ZRJACgt1cGRhdGVfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BB
A1IKdXBkYXRlVGltZRIlCgtkZXNjcmlwdGlvbhgEIAEoCUID4EEBUgtkZXNjcmlwdGlvbhJO
CgVydWxlcxgFIAMoCzIzLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuVGxzUm91
dGUuUm91dGVSdWxlQgPgQQJSBXJ1bGVzEkMKBm1lc2hlcxgGIAMoCUIr4EEB+kElCiNuZXR3
b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vTWVzaFIGbWVzaGVzEkoKCGdhdGV3YXlzGAcg
AygJQi7gQQH6QSgKJm5ldHdvcmtzZXJ2aWNlcy5nb29nbGVhcGlzLmNvbS9HYXRld2F5Ughn
YXRld2F5cxJUCg50YXJnZXRfcHJveGllcxgNIAMoCUIt4EEB+kEnCiVjb21wdXRlLmdvb2ds
ZWFwaXMuY29tL1RhcmdldFRjcFByb3h5Ug10YXJnZXRQcm94aWVzElIKBmxhYmVscxgLIAMo
CzI1Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuVGxzUm91dGUuTGFiZWxzRW50
cnlCA+BBAVIGbGFiZWxzGrQBCglSb3V0ZVJ1bGUSUwoHbWF0Y2hlcxgBIAMoCzI0Lmdvb2ds
ZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuVGxzUm91dGUuUm91dGVNYXRjaEID4EECUgdt
YXRjaGVzElIKBmFjdGlvbhgCIAEoCzI1Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMu
djEuVGxzUm91dGUuUm91dGVBY3Rpb25CA+BBAlIGYWN0aW9uGkUKClJvdXRlTWF0Y2gSHgoI
c25pX2hvc3QYASADKAlCA+BBAVIHc25pSG9zdBIXCgRhbHBuGAIgAygJQgPgQQFSBGFscG4a
tQEKC1JvdXRlQWN0aW9uEmMKDGRlc3RpbmF0aW9ucxgBIAMoCzI6Lmdvb2dsZS5jbG91ZC5u
ZXR3b3Jrc2VydmljZXMudjEuVGxzUm91dGUuUm91dGVEZXN0aW5hdGlvbkID4EECUgxkZXN0
aW5hdGlvbnMSQQoMaWRsZV90aW1lb3V0GAQgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0
aW9uQgPgQQFSC2lkbGVUaW1lb3V0GoEBChBSb3V0ZURlc3RpbmF0aW9uElAKDHNlcnZpY2Vf
bmFtZRgBIAEoCUIt4EEC+kEnCiVjb21wdXRlLmdvb2dsZWFwaXMuY29tL0JhY2tlbmRTZXJ2
aWNlUgtzZXJ2aWNlTmFtZRIbCgZ3ZWlnaHQYAiABKAVCA+BBAVIGd2VpZ2h0GjkKC0xhYmVs
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6a+pB
aAonbmV0d29ya3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1Rsc1JvdXRlEj1wcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vdGxzUm91dGVzL3t0bHNfcm91dGV9ItYB
ChRMaXN0VGxzUm91dGVzUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInbmV0d29y
a3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1Rsc1JvdXRlUgZwYXJlbnQSGwoJcGFnZV9zaXpl
GAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SOQoWcmV0
dXJuX3BhcnRpYWxfc3VjY2VzcxgEIAEoCEID4EEBUhRyZXR1cm5QYXJ0aWFsU3VjY2VzcyKr
AQoVTGlzdFRsc1JvdXRlc1Jlc3BvbnNlEkgKCnRsc19yb3V0ZXMYASADKAsyKS5nb29nbGUu
Y2xvdWQubmV0d29ya3NlcnZpY2VzLnYxLlRsc1JvdXRlUgl0bHNSb3V0ZXMSJgoPbmV4dF9w
YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hhYmxlGAMgAygJUgt1
bnJlYWNoYWJsZSJZChJHZXRUbHNSb3V0ZVJlcXVlc3QSQwoEbmFtZRgBIAEoCUIv4EEC+kEp
CiduZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vVGxzUm91dGVSBG5hbWUi1AEKFUNy
ZWF0ZVRsc1JvdXRlUmVxdWVzdBJHCgZwYXJlbnQYASABKAlCL+BBAvpBKRInbmV0d29ya3Nl
cnZpY2VzLmdvb2dsZWFwaXMuY29tL1Rsc1JvdXRlUgZwYXJlbnQSJQoMdGxzX3JvdXRlX2lk
GAIgASgJQgPgQQJSCnRsc1JvdXRlSWQSSwoJdGxzX3JvdXRlGAMgASgLMikuZ29vZ2xlLmNs
b3VkLm5ldHdvcmtzZXJ2aWNlcy52MS5UbHNSb3V0ZUID4EECUgh0bHNSb3V0ZSKmAQoVVXBk
YXRlVGxzUm91dGVSZXF1ZXN0EkAKC3VwZGF0ZV9tYXNrGAEgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrEksKCXRsc19yb3V0ZRgCIAEoCzIpLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuVGxzUm91dGVCA+BBAlIIdGxzUm91dGUi
XAoVRGVsZXRlVGxzUm91dGVSZXF1ZXN0EkMKBG5hbWUYASABKAlCL+BBAvpBKQonbmV0d29y
a3NlcnZpY2VzLmdvb2dsZWFwaXMuY29tL1Rsc1JvdXRlUgRuYW1lQuUCCiNjb20uZ29vZ2xl
LmNsb3VkLm5ldHdvcmtzZXJ2aWNlcy52MUINVGxzUm91dGVQcm90b1ABWk1jbG91ZC5nb29n
bGUuY29tL2dvL25ldHdvcmtzZXJ2aWNlcy9hcGl2MS9uZXR3b3Jrc2VydmljZXNwYjtuZXR3
b3Jrc2VydmljZXNwYqoCH0dvb2dsZS5DbG91ZC5OZXR3b3JrU2VydmljZXMuVjHKAh9Hb29n
bGVcQ2xvdWRcTmV0d29ya1NlcnZpY2VzXFYx6gIiR29vZ2xlOjpDbG91ZDo6TmV0d29ya1Nl
cnZpY2VzOjpWMepBdAolY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9UYXJnZXRUY3BQcm94eRJL
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3RhcmdldFRjcFByb3hp
ZXMve3RhcmdldF90Y3BfcHJveHl9SudNCgcSBQ4AkAIBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhID
FAAoCgkKAgMDEgMVACoKCQoCAwQSAxYAKQoICgEIEgMYADwKCQoCCCUSAxgAPAoICgEIEgMZ
AGQKCQoCCAsSAxkAZAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC4KCQoCCAgSAxsA
LgoICgEIEgMcADwKCQoCCAESAxwAPAoICgEIEgMdADwKCQoCCCkSAx0APAoICgEIEgMeADsK
CQoCCC0SAx4AOwoJCgEIEgQfACICCgwKBAidCAASBB8AIgIKbAoCBAASBSYArgEBGl8gVGxz
Um91dGUgZGVmaW5lcyBob3cgdHJhZmZpYyBzaG91bGQgYmUgcm91dGVkIGJhc2VkIG9uIFNO
SSBhbmQgb3RoZXIgbWF0Y2hpbmcKIEwzIGF0dHJpYnV0ZXMuCgoKCgMEAAESAyYIEAoLCgME
AAcSBCcCKgQKDQoFBAAHnQgSBCcCKgQKYQoEBAADABIELgI2AxpTIFNwZWNpZmllcyBob3cg
dG8gbWF0Y2ggdHJhZmZpYyBhbmQgaG93IHRvIHJvdXRlIHRyYWZmaWMgd2hlbiB0cmFmZmlj
IGlzCiBtYXRjaGVkLgoKDAoFBAADAAESAy4KEwrBAQoGBAADAAIAEgMyBE0asQEgUmVxdWly
ZWQuIFJvdXRlTWF0Y2ggZGVmaW5lcyB0aGUgcHJlZGljYXRlIHVzZWQgdG8gbWF0Y2ggcmVx
dWVzdHMgdG8gYQogZ2l2ZW4gYWN0aW9uLiBNdWx0aXBsZSBtYXRjaCB0eXBlcyBhcmUgIk9S
ImVkIGZvciBldmFsdWF0aW9uLiBBdGxlYXN0IG9uZQogUm91dGVNYXRjaCBtdXN0IGJlIHN1
cHBsaWVkLgoKDgoHBAADAAIABBIDMgQMCg4KBwQAAwACAAYSAzINFwoOCgcEAAMAAgABEgMy
GB8KDgoHBAADAAIAAxIDMiIjCg4KBwQAAwACAAgSAzIkTAoRCgoEAAMAAgAInAgAEgMyJUsK
UwoGBAADAAIBEgM1BEQaRCBSZXF1aXJlZC4gVGhlIGRldGFpbGVkIHJ1bGUgZGVmaW5pbmcg
aG93IHRvIHJvdXRlIG1hdGNoZWQgdHJhZmZpYy4KCg4KBwQAAwACAQYSAzUEDwoOCgcEAAMA
AgEBEgM1EBYKDgoHBAADAAIBAxIDNRkaCg4KBwQAAwACAQgSAzUbQwoRCgoEAAMAAgEInAgA
EgM1HEIKjAEKBAQAAwESBDoCSgMafiBSb3V0ZU1hdGNoIGRlZmluZXMgdGhlIHByZWRpY2F0
ZSB1c2VkIHRvIG1hdGNoIHJlcXVlc3RzIHRvIGEgZ2l2ZW4gYWN0aW9uLgogTXVsdGlwbGUg
bWF0Y2ggdHlwZXMgYXJlICJBTkQiZWQgZm9yIGV2YWx1YXRpb24uCgoMCgUEAAMBARIDOgoU
CqEDCgYEAAMBAgASA0MEShqRAyBPcHRpb25hbC4gU05JIChzZXJ2ZXIgbmFtZSBpbmRpY2F0
b3IpIHRvIG1hdGNoIGFnYWluc3QuCiBTTkkgd2lsbCBiZSBtYXRjaGVkIGFnYWluc3QgYWxs
IHdpbGRjYXJkIGRvbWFpbnMsIGkuZS4gYHd3dy5leGFtcGxlLmNvbWAKIHdpbGwgYmUgZmly
c3QgbWF0Y2hlZCBhZ2FpbnN0IGB3d3cuZXhhbXBsZS5jb21gLCB0aGVuIGAqLmV4YW1wbGUu
Y29tYCwKIHRoZW4gYCouY29tLmAKIFBhcnRpYWwgd2lsZGNhcmRzIGFyZSBub3Qgc3VwcG9y
dGVkLCBhbmQgdmFsdWVzIGxpa2UgKncuZXhhbXBsZS5jb20gYXJlCiBpbnZhbGlkLgogQXQg
bGVhc3Qgb25lIG9mIHNuaV9ob3N0IGFuZCBhbHBuIGlzIHJlcXVpcmVkLgogVXAgdG8gMTAw
IHNuaSBob3N0cyBhY3Jvc3MgYWxsIG1hdGNoZXMgY2FuIGJlIHNldC4KCg4KBwQAAwECAAQS
A0MEDAoOCgcEAAMBAgAFEgNDDRMKDgoHBAADAQIAARIDQxQcCg4KBwQAAwECAAMSA0MfIAoO
CgcEAAMBAgAIEgNDIUkKEQoKBAADAQIACJwIABIDQyJICtYBCgYEAAMBAgESA0kERhrGASBP
cHRpb25hbC4gQUxQTiAoQXBwbGljYXRpb24tTGF5ZXIgUHJvdG9jb2wgTmVnb3RpYXRpb24p
IHRvIG1hdGNoIGFnYWluc3QuCiBFeGFtcGxlczogImh0dHAvMS4xIiwgImgyIi4KIEF0IGxl
YXN0IG9uZSBvZiBzbmlfaG9zdCBhbmQgYWxwbiBpcyByZXF1aXJlZC4KIFVwIHRvIDUgYWxw
bnMgYWNyb3NzIGFsbCBtYXRjaGVzIGNhbiBiZSBzZXQuCgoOCgcEAAMBAgEEEgNJBAwKDgoH
BAADAQIBBRIDSQ0TCg4KBwQAAwECAQESA0kUGAoOCgcEAAMBAgEDEgNJGxwKDgoHBAADAQIB
CBIDSR1FChEKCgQAAwECAQicCAASA0keRApYCgQEAAMCEgRNAloDGkogVGhlIHNwZWNpZmlj
YXRpb25zIGZvciByb3V0aW5nIHRyYWZmaWMgYW5kIGFwcGx5aW5nIGFzc29jaWF0ZWQgcG9s
aWNpZXMuCgoMCgUEAAMCARIDTQoVCokBCgYEAAMCAgASBFAEUTEaeSBSZXF1aXJlZC4gVGhl
IGRlc3RpbmF0aW9uIHNlcnZpY2VzIHRvIHdoaWNoIHRyYWZmaWMgc2hvdWxkIGJlIGZvcndh
cmRlZC4KIEF0IGxlYXN0IG9uZSBkZXN0aW5hdGlvbiBzZXJ2aWNlIGlzIHJlcXVpcmVkLgoK
DgoHBAADAgIABBIDUAQMCg4KBwQAAwICAAYSA1ANHQoOCgcEAAMCAgABEgNQHioKDgoHBAAD
AgIAAxIDUC0uCg4KBwQAAwICAAgSA1EIMAoRCgoEAAMCAgAInAgAEgNRCS8KtwIKBgQAAwIC
ARIEWARZMRqmAiBPcHRpb25hbC4gU3BlY2lmaWVzIHRoZSBpZGxlIHRpbWVvdXQgZm9yIHRo
ZSBzZWxlY3RlZCByb3V0ZS4gVGhlIGlkbGUKIHRpbWVvdXQgaXMgZGVmaW5lZCBhcyB0aGUg
cGVyaW9kIGluIHdoaWNoIHRoZXJlIGFyZSBubyBieXRlcyBzZW50IG9yCiByZWNlaXZlZCBv
biBlaXRoZXIgdGhlIHVwc3RyZWFtIG9yIGRvd25zdHJlYW0gY29ubmVjdGlvbi4gSWYgbm90
IHNldCwgdGhlCiBkZWZhdWx0IGlkbGUgdGltZW91dCBpcyAxIGhvdXIuIElmIHNldCB0byAw
cywgdGhlIHRpbWVvdXQgd2lsbCBiZQogZGlzYWJsZWQuCgoOCgcEAAMCAgEGEgNYBBwKDgoH
BAADAgIBARIDWB0pCg4KBwQAAwICAQMSA1gsLQoOCgcEAAMCAgEIEgNZCDAKEQoKBAADAgIB
CJwIABIDWQkvCkUKBAQAAwMSBF0CawMaNyBEZXNjcmliZSB0aGUgZGVzdGluYXRpb24gZm9y
IHRyYWZmaWMgdG8gYmUgcm91dGVkIHRvLgoKDAoFBAADAwESA10KGgpMCgYEAAMDAgASBF8E
ZAYaPCBSZXF1aXJlZC4gVGhlIFVSTCBvZiBhIEJhY2tlbmRTZXJ2aWNlIHRvIHJvdXRlIHRy
YWZmaWMgdG8uCgoOCgcEAAMDAgAFEgNfBAoKDgoHBAADAwIAARIDXwsXCg4KBwQAAwMCAAMS
A18aGwoPCgcEAAMDAgAIEgRfHGQFChEKCgQAAwMCAAicCAASA2AGLAoRCgkEAAMDAgAInwgS
BGEGYwcK+QEKBgQAAwMCARIDagQ+GukBIE9wdGlvbmFsLiBTcGVjaWZpZXMgdGhlIHByb3Bv
cnRpb24gb2YgcmVxdWVzdHMgZm9yd2FyZGVkIHRvIHRoZSBiYWNrZW5kCiByZWZlcmVuY2Vk
IGJ5IHRoZSBzZXJ2aWNlX25hbWUgZmllbGQuIFRoaXMgaXMgY29tcHV0ZWQgYXM6CiAtIHdl
aWdodC9TdW0od2VpZ2h0cyBpbiBkZXN0aW5hdGlvbnMpCiBXZWlnaHRzIGluIGFsbCBkZXN0
aW5hdGlvbnMgZG9lcyBub3QgbmVlZCB0byBzdW0gdXAgdG8gMTAwLgoKDgoHBAADAwIBBRID
agQJCg4KBwQAAwMCAQESA2oKEAoOCgcEAAMDAgEDEgNqExQKDgoHBAADAwIBCBIDahU9ChEK
CgQAAwMCAQicCAASA2oWPAqBAQoEBAACABIDbwI9GnQgSWRlbnRpZmllci4gTmFtZSBvZiB0
aGUgVGxzUm91dGUgcmVzb3VyY2UuIEl0IG1hdGNoZXMgcGF0dGVybgogYHByb2plY3RzLyov
bG9jYXRpb25zLyovdGxzUm91dGVzL3Rsc19yb3V0ZV9uYW1lPmAuCgoMCgUEAAIABRIDbwII
CgwKBQQAAgABEgNvCQ0KDAoFBAACAAMSA28QEQoMCgUEAAIACBIDbxI8Cg8KCAQAAgAInAgA
EgNvEzsKPwoEBAACARIDcgJDGjIgT3V0cHV0IG9ubHkuIFNlcnZlci1kZWZpbmVkIFVSTCBv
ZiB0aGlzIHJlc291cmNlCgoMCgUEAAIBBRIDcgIICgwKBQQAAgEBEgNyCRIKDAoFBAACAQMS
A3IVFgoMCgUEAAIBCBIDchdCCg8KCAQAAgEInAgAEgNyGEEKSQoEBAACAhIEdQJ2Mho7IE91
dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIHJlc291cmNlIHdhcyBjcmVhdGVk
LgoKDAoFBAACAgYSA3UCGwoMCgUEAAICARIDdRwnCgwKBQQAAgIDEgN1KisKDAoFBAACAggS
A3YGMQoPCggEAAICCJwIABIDdgcwCkkKBAQAAgMSBHkCejIaOyBPdXRwdXQgb25seS4gVGhl
IHRpbWVzdGFtcCB3aGVuIHRoZSByZXNvdXJjZSB3YXMgdXBkYXRlZC4KCgwKBQQAAgMGEgN5
AhsKDAoFBAACAwESA3kcJwoMCgUEAAIDAxIDeSorCgwKBQQAAgMIEgN6BjEKDwoIBAACAwic
CAASA3oHMApeCgQEAAIEEgN+AkIaUSBPcHRpb25hbC4gQSBmcmVlLXRleHQgZGVzY3JpcHRp
b24gb2YgdGhlIHJlc291cmNlLiBNYXggbGVuZ3RoIDEwMjQKIGNoYXJhY3RlcnMuCgoMCgUE
AAIEBRIDfgIICgwKBQQAAgQBEgN+CRQKDAoFBAACBAMSA34XGAoMCgUEAAIECBIDfhlBCg8K
CAQAAgQInAgAEgN+GkAKzQEKBAQAAgUSBIMBAkgavgEgUmVxdWlyZWQuIFJ1bGVzIHRoYXQg
ZGVmaW5lIGhvdyB0cmFmZmljIGlzIHJvdXRlZCBhbmQgaGFuZGxlZC4gQXQgbGVhc3Qgb25l
CiBSb3V0ZVJ1bGUgbXVzdCBiZSBzdXBwbGllZC4gSWYgdGhlcmUgYXJlIG11bHRpcGxlIHJ1
bGVzIHRoZW4gdGhlIGFjdGlvbgogdGFrZW4gd2lsbCBiZSB0aGUgZmlyc3QgcnVsZSB0byBt
YXRjaC4KCg0KBQQAAgUEEgSDAQIKCg0KBQQAAgUGEgSDAQsUCg0KBQQAAgUBEgSDARUaCg0K
BQQAAgUDEgSDAR0eCg0KBQQAAgUIEgSDAR9HChAKCAQAAgUInAgAEgSDASBGCq4CCgQEAAIG
EgaMAQKRAQQanQIgT3B0aW9uYWwuIE1lc2hlcyBkZWZpbmVzIGEgbGlzdCBvZiBtZXNoZXMg
dGhpcyBUbHNSb3V0ZSBpcyBhdHRhY2hlZCB0bywgYXMKIG9uZSBvZiB0aGUgcm91dGluZyBy
dWxlcyB0byByb3V0ZSB0aGUgcmVxdWVzdHMgc2VydmVkIGJ5IHRoZSBtZXNoLgoKIEVhY2gg
bWVzaCByZWZlcmVuY2Ugc2hvdWxkIG1hdGNoIHRoZSBwYXR0ZXJuOgogYHByb2plY3RzLyov
bG9jYXRpb25zLyovbWVzaGVzLzxtZXNoX25hbWU+YAoKIFRoZSBhdHRhY2hlZCBNZXNoIHNo
b3VsZCBiZSBvZiBhIHR5cGUgU0lERUNBUgoKDQoFBAACBgQSBIwBAgoKDQoFBAACBgUSBIwB
CxEKDQoFBAACBgESBIwBEhgKDQoFBAACBgMSBIwBGxwKDwoFBAACBggSBowBHZEBAwoQCggE
AAIGCJwIABIEjQEEKgoRCgcEAAIGCJ8IEgaOAQSQAQUKjQIKBAQAAgcSBpgBAp0BBBr8ASBP
cHRpb25hbC4gR2F0ZXdheXMgZGVmaW5lcyBhIGxpc3Qgb2YgZ2F0ZXdheXMgdGhpcyBUbHNS
b3V0ZSBpcyBhdHRhY2hlZCB0bywKIGFzIG9uZSBvZiB0aGUgcm91dGluZyBydWxlcyB0byBy
b3V0ZSB0aGUgcmVxdWVzdHMgc2VydmVkIGJ5IHRoZSBnYXRld2F5LgoKIEVhY2ggZ2F0ZXdh
eSByZWZlcmVuY2Ugc2hvdWxkIG1hdGNoIHRoZSBwYXR0ZXJuOgogYHByb2plY3RzLyovbG9j
YXRpb25zLyovZ2F0ZXdheXMvPGdhdGV3YXlfbmFtZT5gCgoNCgUEAAIHBBIEmAECCgoNCgUE
AAIHBRIEmAELEQoNCgUEAAIHARIEmAESGgoNCgUEAAIHAxIEmAEdHgoPCgUEAAIHCBIGmAEf
nQEDChAKCAQAAgcInAgAEgSZAQQqChEKBwQAAgcInwgSBpoBBJwBBQq6AgoEBAACCBIGpQEC
qgEEGqkCIE9wdGlvbmFsLiBUYXJnZXRQcm94aWVzIGRlZmluZXMgYSBsaXN0IG9mIFRhcmdl
dFRjcFByb3hpZXMgdGhpcyBUbHNSb3V0ZSBpcwogYXR0YWNoZWQgdG8sIGFzIG9uZSBvZiB0
aGUgcm91dGluZyBydWxlcyB0byByb3V0ZSB0aGUgcmVxdWVzdHMgc2VydmVkIGJ5CiB0aGUg
VGFyZ2V0VGNwUHJveHkuCgogRWFjaCBUYXJnZXRUY3BQcm94eSByZWZlcmVuY2Ugc2hvdWxk
IG1hdGNoIHRoZSBwYXR0ZXJuOgogYHByb2plY3RzLyovbG9jYXRpb25zLyovdGFyZ2V0VGNw
UHJveGllcy88dGFyZ2V0X3RjcF9wcm94eV9uYW1lPmAKCg0KBQQAAggEEgSlAQIKCg0KBQQA
AggFEgSlAQsRCg0KBQQAAggBEgSlARIgCg0KBQQAAggDEgSlASMlCg8KBQQAAggIEgalASaq
AQMKEAoIBAACCAicCAASBKYBBCoKEQoHBAACCAifCBIGpwEEqQEFClIKBAQAAgkSBK0BAksa
RCBPcHRpb25hbC4gU2V0IG9mIGxhYmVsIHRhZ3MgYXNzb2NpYXRlZCB3aXRoIHRoZSBUbHNS
b3V0ZSByZXNvdXJjZS4KCg0KBQQAAgkGEgStAQIVCg0KBQQAAgkBEgStARYcCg0KBQQAAgkD
EgStAR8hCg0KBQQAAgkIEgStASJKChAKCAQAAgkInAgAEgStASNJCjsKAgQBEgaxAQDHAQEa
LSBSZXF1ZXN0IHVzZWQgd2l0aCB0aGUgTGlzdFRsc1JvdXRlcyBtZXRob2QuCgoLCgMEAQES
BLEBCBwKkwEKBAQBAgASBrQBArkBBBqCASBSZXF1aXJlZC4gVGhlIHByb2plY3QgYW5kIGxv
Y2F0aW9uIGZyb20gd2hpY2ggdGhlIFRsc1JvdXRlcyBzaG91bGQgYmUKIGxpc3RlZCwgc3Bl
Y2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3RzLyovbG9jYXRpb25zLypgLgoKDQoFBAEC
AAUSBLQBAggKDQoFBAECAAESBLQBCQ8KDQoFBAECAAMSBLQBEhMKDwoFBAECAAgSBrQBFLkB
AwoQCggEAQIACJwIABIEtQEEKgoRCgcEAQIACJ8IEga2AQS4AQUKPwoEBAECARIEvAECFhox
IE1heGltdW0gbnVtYmVyIG9mIFRsc1JvdXRlcyB0byByZXR1cm4gcGVyIGNhbGwuCgoNCgUE
AQIBBRIEvAECBwoNCgUEAQIBARIEvAEIEQoNCgUEAQIBAxIEvAEUFQrJAQoEBAECAhIEwQEC
GBq6ASBUaGUgdmFsdWUgcmV0dXJuZWQgYnkgdGhlIGxhc3QgYExpc3RUbHNSb3V0ZXNSZXNw
b25zZWAKIEluZGljYXRlcyB0aGF0IHRoaXMgaXMgYSBjb250aW51YXRpb24gb2YgYSBwcmlv
ciBgTGlzdFRsc1JvdXRlc2AgY2FsbCwKIGFuZCB0aGF0IHRoZSBzeXN0ZW0gc2hvdWxkIHJl
dHVybiB0aGUgbmV4dCBwYWdlIG9mIGRhdGEuCgoNCgUEAQICBRIEwQECCAoNCgUEAQICARIE
wQEJEwoNCgUEAQICAxIEwQEWFwrLAQoEBAECAxIExgECSxq8ASBPcHRpb25hbC4gSWYgdHJ1
ZSwgYWxsb3cgcGFydGlhbCByZXNwb25zZXMgZm9yIG11bHRpLXJlZ2lvbmFsIEFnZ3JlZ2F0
ZWQKIExpc3QgcmVxdWVzdHMuIE90aGVyd2lzZSBpZiBvbmUgb2YgdGhlIGxvY2F0aW9ucyBp
cyBkb3duIG9yIHVucmVhY2hhYmxlLAogdGhlIEFnZ3JlZ2F0ZWQgTGlzdCByZXF1ZXN0IHdp
bGwgZmFpbC4KCg0KBQQBAgMFEgTGAQIGCg0KBQQBAgMBEgTGAQcdCg0KBQQBAgMDEgTGASAh
Cg0KBQQBAgMIEgTGASJKChAKCAQBAgMInAgAEgTGASNJCj4KAgQCEgbKAQDYAQEaMCBSZXNw
b25zZSByZXR1cm5lZCBieSB0aGUgTGlzdFRsc1JvdXRlcyBtZXRob2QuCgoLCgMEAgESBMoB
CB0KKwoEBAICABIEzAECIxodIExpc3Qgb2YgVGxzUm91dGUgcmVzb3VyY2VzLgoKDQoFBAIC
AAQSBMwBAgoKDQoFBAICAAYSBMwBCxMKDQoFBAICAAESBMwBFB4KDQoFBAICAAMSBMwBISIK
6QEKBAQCAgESBNEBAh0a2gEgSWYgdGhlcmUgbWlnaHQgYmUgbW9yZSByZXN1bHRzIHRoYW4g
dGhvc2UgYXBwZWFyaW5nIGluIHRoaXMgcmVzcG9uc2UsIHRoZW4KIGBuZXh0X3BhZ2VfdG9r
ZW5gIGlzIGluY2x1ZGVkLiBUbyBnZXQgdGhlIG5leHQgc2V0IG9mIHJlc3VsdHMsIGNhbGwg
dGhpcwogbWV0aG9kIGFnYWluIHVzaW5nIHRoZSB2YWx1ZSBvZiBgbmV4dF9wYWdlX3Rva2Vu
YCBhcyBgcGFnZV90b2tlbmAuCgoNCgUEAgIBBRIE0QECCAoNCgUEAgIBARIE0QEJGAoNCgUE
AgIBAxIE0QEbHAqfAgoEBAICAhIE1wECIhqQAiBVbnJlYWNoYWJsZSByZXNvdXJjZXMuIFBv
cHVsYXRlZCB3aGVuIHRoZSByZXF1ZXN0IG9wdHMgaW50bwogW3JldHVybl9wYXJ0aWFsX3N1
Y2Nlc3NdW2dvb2dsZS5jbG91ZC5uZXR3b3Jrc2VydmljZXMudjEuTGlzdFRsc1JvdXRlc1Jl
cXVlc3QucmV0dXJuX3BhcnRpYWxfc3VjY2Vzc10KIGFuZCByZWFkaW5nIGFjcm9zcyBjb2xs
ZWN0aW9ucyBlLmcuIHdoZW4gYXR0ZW1wdGluZyB0byBsaXN0IGFsbCByZXNvdXJjZXMKIGFj
cm9zcyBhbGwgc3VwcG9ydGVkIGxvY2F0aW9ucy4KCg0KBQQCAgIEEgTXAQIKCg0KBQQCAgIF
EgTXAQsRCg0KBQQCAgIBEgTXARIdCg0KBQQCAgIDEgTXASAhCjcKAgQDEgbbAQDkAQEaKSBS
ZXF1ZXN0IHVzZWQgYnkgdGhlIEdldFRsc1JvdXRlIG1ldGhvZC4KCgsKAwQDARIE2wEIGgp3
CgQEAwIAEgbeAQLjAQQaZyBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBUbHNSb3V0ZSB0byBn
ZXQuIE11c3QgYmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovdGxz
Um91dGVzLypgLgoKDQoFBAMCAAUSBN4BAggKDQoFBAMCAAESBN4BCQ0KDQoFBAMCAAMSBN4B
EBEKDwoFBAMCAAgSBt4BEuMBAwoQCggEAwIACJwIABIE3wEEKgoRCgcEAwIACJ8IEgbgAQTi
AQUKNAoCBAQSBucBAPYBARomIFJlcXVlc3QgdXNlZCBieSB0aGUgVGxzUm91dGUgbWV0aG9k
LgoKCwoDBAQBEgTnAQgdCnEKBAQEAgASBuoBAu8BBBphIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG9mIHRoZSBUbHNSb3V0ZS4gTXVzdCBiZSBpbiB0aGUKIGZvcm1hdCBgcHJv
amVjdHMvKi9sb2NhdGlvbnMvKmAuCgoNCgUEBAIABRIE6gECCAoNCgUEBAIAARIE6gEJDwoN
CgUEBAIAAxIE6gESEwoPCgUEBAIACBIG6gEU7wEDChAKCAQEAgAInAgAEgTrAQQqChEKBwQE
AgAInwgSBuwBBO4BBQpMCgQEBAIBEgTyAQJDGj4gUmVxdWlyZWQuIFNob3J0IG5hbWUgb2Yg
dGhlIFRsc1JvdXRlIHJlc291cmNlIHRvIGJlIGNyZWF0ZWQuCgoNCgUEBAIBBRIE8gECCAoN
CgUEBAIBARIE8gEJFQoNCgUEBAIBAxIE8gEYGQoNCgUEBAIBCBIE8gEaQgoQCggEBAIBCJwI
ABIE8gEbQQo6CgQEBAICEgT1AQJCGiwgUmVxdWlyZWQuIFRsc1JvdXRlIHJlc291cmNlIHRv
IGJlIGNyZWF0ZWQuCgoNCgUEBAICBhIE9QECCgoNCgUEBAICARIE9QELFAoNCgUEBAICAxIE
9QEXGAoNCgUEBAICCBIE9QEZQQoQCggEBAICCJwIABIE9QEaQAo6CgIEBRIG+QEAhAIBGiwg
UmVxdWVzdCB1c2VkIGJ5IHRoZSBVcGRhdGVUbHNSb3V0ZSBtZXRob2QuCgoLCgMEBQESBPkB
CB0K2gIKBAQFAgASBv8BAoACLxrJAiBPcHRpb25hbC4gRmllbGQgbWFzayBpcyB1c2VkIHRv
IHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIFRsc1JvdXRl
IHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuCiBUaGUgZmllbGRzIHNwZWNpZmllZCBpbiB0aGUg
dXBkYXRlX21hc2sgYXJlIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90CiB0aGUgZnVs
bCByZXF1ZXN0LiBBIGZpZWxkIHdpbGwgYmUgb3ZlcndyaXR0ZW4gaWYgaXQgaXMgaW4gdGhl
IG1hc2suIElmIHRoZQogdXNlciBkb2VzIG5vdCBwcm92aWRlIGEgbWFzayB0aGVuIGFsbCBm
aWVsZHMgd2lsbCBiZSBvdmVyd3JpdHRlbi4KCg0KBQQFAgAGEgT/AQIbCg0KBQQFAgABEgT/
ARwnCg0KBQQFAgADEgT/ASorCg0KBQQFAgAIEgSAAgYuChAKCAQFAgAInAgAEgSAAgctCjQK
BAQFAgESBIMCAkIaJiBSZXF1aXJlZC4gVXBkYXRlZCBUbHNSb3V0ZSByZXNvdXJjZS4KCg0K
BQQFAgEGEgSDAgIKCg0KBQQFAgEBEgSDAgsUCg0KBQQFAgEDEgSDAhcYCg0KBQQFAgEIEgSD
AhlBChAKCAQFAgEInAgAEgSDAhpACjoKAgQGEgaHAgCQAgEaLCBSZXF1ZXN0IHVzZWQgYnkg
dGhlIERlbGV0ZVRsc1JvdXRlIG1ldGhvZC4KCgsKAwQGARIEhwIIHQp6CgQEBgIAEgaKAgKP
AgQaaiBSZXF1aXJlZC4gQSBuYW1lIG9mIHRoZSBUbHNSb3V0ZSB0byBkZWxldGUuIE11c3Qg
YmUgaW4gdGhlIGZvcm1hdAogYHByb2plY3RzLyovbG9jYXRpb25zLyovdGxzUm91dGVzLypg
LgoKDQoFBAYCAAUSBIoCAggKDQoFBAYCAAESBIoCCQ0KDQoFBAYCAAMSBIoCEBEKDwoFBAYC
AAgSBooCEo8CAwoQCggEBgIACJwIABIEiwIEKgoRCgcEBgIACJ8IEgaMAgSOAgViBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute ===
    # Fields for TlsRoute
    # Field: name Type: 9 ()
    # Field: self_link Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: description Type: 9 ()
    # Field: rules Type: 11 (.google.cloud.networkservices.v1.TlsRoute.RouteRule)
    # Field: meshes Type: 9 ()
    # Field: gateways Type: 9 ()
    # Field: target_proxies Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.networkservices.v1.TlsRoute.LabelsEntry)

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesRequest ===
    # Fields for ListTlsRoutesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: return_partial_success Type: 8 ()

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesResponse ===
    # Fields for ListTlsRoutesResponse
    # Field: tls_routes Type: 11 (.google.cloud.networkservices.v1.TlsRoute)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::GetTlsRouteRequest ===
    # Fields for GetTlsRouteRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::CreateTlsRouteRequest ===
    # Fields for CreateTlsRouteRequest
    # Field: parent Type: 9 ()
    # Field: tls_route_id Type: 9 ()
    # Field: tls_route Type: 11 (.google.cloud.networkservices.v1.TlsRoute)

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::UpdateTlsRouteRequest ===
    # Fields for UpdateTlsRouteRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: tls_route Type: 11 (.google.cloud.networkservices.v1.TlsRoute)

# === Message: Google::Cloud::Networkservices::V1::TlsRoute::DeleteTlsRouteRequest ===
    # Fields for DeleteTlsRouteRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkservices::V1::TlsRoute - Compiled Protocol Buffers messages for google/cloud/networkservices/v1/tls_route.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkservices::V1::TlsRoute;

    my $msg = Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute->new({
        name => $name,
        self_link => $self_link,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkservices/v1/tls_route.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute

TlsRoute defines how traffic should be routed based on SNI and other matching
L3 attributes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Name of the TlsRoute resource. It matches pattern
`projects/*/locations/*/tlsRoutes/tls_route_name>`.

=item * C<< $msg->self_link() >> / C<< $msg->self_link($value) >>

Type: C<String>

Output only. Server-defined URL of this resource

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the resource was updated.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. A free-text description of the resource. Max length 1024
characters.

=item * C<< $msg->rules() >> / C<< $msg->rules($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteRule>)

Required. Rules that define how traffic is routed and handled. At least one
RouteRule must be supplied. If there are multiple rules then the action
taken will be the first rule to match.

=item * C<< $msg->meshes() >> / C<< $msg->meshes($value) >>

Type: C<String>

Optional. Meshes defines a list of meshes this TlsRoute is attached to, as
one of the routing rules to route the requests served by the mesh.

Each mesh reference should match the pattern:
`projects/*/locations/*/meshes/<mesh_name>`

The attached Mesh should be of a type SIDECAR

=item * C<< $msg->gateways() >> / C<< $msg->gateways($value) >>

Type: C<String>

Optional. Gateways defines a list of gateways this TlsRoute is attached to,
as one of the routing rules to route the requests served by the gateway.

Each gateway reference should match the pattern:
`projects/*/locations/*/gateways/<gateway_name>`

=item * C<< $msg->target_proxies() >> / C<< $msg->target_proxies($value) >>

Type: C<String>

Optional. TargetProxies defines a list of TargetTcpProxies this TlsRoute is
attached to, as one of the routing rules to route the requests served by
the TargetTcpProxy.

Each TargetTcpProxy reference should match the pattern:
`projects/*/locations/*/targetTcpProxies/<target_tcp_proxy_name>`

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::LabelsEntry>)

Optional. Set of label tags associated with the TlsRoute resource.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesRequest

Request used with the ListTlsRoutes method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the TlsRoutes should be
listed, specified in the format `projects/*/locations/*`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of TlsRoutes to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The value returned by the last `ListTlsRoutesResponse`
Indicates that this is a continuation of a prior `ListTlsRoutes` call,
and that the system should return the next page of data.

=item * C<< $msg->return_partial_success() >> / C<< $msg->return_partial_success($value) >>

Type: C<Bool>

Optional. If true, allow partial responses for multi-regional Aggregated
List requests. Otherwise if one of the locations is down or unreachable,
the Aggregated List request will fail.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesResponse

Response returned by the ListTlsRoutes method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tls_routes() >> / C<< $msg->tls_routes($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute>)

List of TlsRoute resources.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

If there might be more results than those appearing in this response, then
`next_page_token` is included. To get the next set of results, call this
method again using the value of `next_page_token` as `page_token`.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unreachable resources. Populated when the request opts into
[return_partial_success][google.cloud.networkservices.v1.ListTlsRoutesRequest.return_partial_success]
and reading across collections e.g. when attempting to list all resources
across all supported locations.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::GetTlsRouteRequest

Request used by the GetTlsRoute method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TlsRoute to get. Must be in the format
`projects/*/locations/*/tlsRoutes/*`.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::CreateTlsRouteRequest

Request used by the TlsRoute method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource of the TlsRoute. Must be in the
format `projects/*/locations/*`.

=item * C<< $msg->tls_route_id() >> / C<< $msg->tls_route_id($value) >>

Type: C<String>

Required. Short name of the TlsRoute resource to be created.

=item * C<< $msg->tls_route() >> / C<< $msg->tls_route($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute>)

Required. TlsRoute resource to be created.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::UpdateTlsRouteRequest

Request used by the UpdateTlsRoute method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Field mask is used to specify the fields to be overwritten in the
TlsRoute resource by the update.
The fields specified in the update_mask are relative to the resource, not
the full request. A field will be overwritten if it is in the mask. If the
user does not provide a mask then all fields will be overwritten.

=item * C<< $msg->tls_route() >> / C<< $msg->tls_route($value) >>

Type: C<Message> (L<Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute>)

Required. Updated TlsRoute resource.

=back

=head2 Google::Cloud::Networkservices::V1::TlsRoute::DeleteTlsRouteRequest

Request used by the DeleteTlsRoute method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. A name of the TlsRoute to delete. Must be in the format
`projects/*/locations/*/tlsRoutes/*`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkservices::V1::TlsRoute::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
