package Google::Cloud::Talent::V4beta1::Job;

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
    eval { require Google::Cloud::Talent::V4beta1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvam9iLnByb3RvEhtnb29nbGUuY2xvdWQu
dGFsZW50LnY0YmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aKGdvb2dsZS9jbG91ZC90YWxlbnQvdjRiZXRhMS9jb21t
b24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiBQKA0pvYhISCgRu
YW1lGAEgASgJUgRuYW1lEj0KB2NvbXBhbnkYAiABKAlCI+BBAvpBHQobam9icy5nb29nbGVh
cGlzLmNvbS9Db21wYW55Ugdjb21wYW55EioKDnJlcXVpc2l0aW9uX2lkGAMgASgJQgPgQQJS
DXJlcXVpc2l0aW9uSWQSGQoFdGl0bGUYBCABKAlCA+BBAlIFdGl0bGUSJQoLZGVzY3JpcHRp
b24YBSABKAlCA+BBAlILZGVzY3JpcHRpb24SHAoJYWRkcmVzc2VzGAYgAygJUglhZGRyZXNz
ZXMSWwoQYXBwbGljYXRpb25faW5mbxgHIAEoCzIwLmdvb2dsZS5jbG91ZC50YWxlbnQudjRi
ZXRhMS5Kb2IuQXBwbGljYXRpb25JbmZvUg9hcHBsaWNhdGlvbkluZm8SSgoMam9iX2JlbmVm
aXRzGAggAygOMicuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYkJlbmVmaXRSC2pv
YkJlbmVmaXRzEloKEWNvbXBlbnNhdGlvbl9pbmZvGAkgASgLMi0uZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkNvbXBlbnNhdGlvbkluZm9SEGNvbXBlbnNhdGlvbkluZm8SYwoRY3Vz
dG9tX2F0dHJpYnV0ZXMYCiADKAsyNi5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9i
LkN1c3RvbUF0dHJpYnV0ZXNFbnRyeVIQY3VzdG9tQXR0cmlidXRlcxJKCgxkZWdyZWVfdHlw
ZXMYCyADKA4yJy5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuRGVncmVlVHlwZVILZGVn
cmVlVHlwZXMSHgoKZGVwYXJ0bWVudBgMIAEoCVIKZGVwYXJ0bWVudBJWChBlbXBsb3ltZW50
X3R5cGVzGA0gAygOMisuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkVtcGxveW1lbnRU
eXBlUg9lbXBsb3ltZW50VHlwZXMSHgoKaW5jZW50aXZlcxgOIAEoCVIKaW5jZW50aXZlcxIj
Cg1sYW5ndWFnZV9jb2RlGA8gASgJUgxsYW5ndWFnZUNvZGUSQgoJam9iX2xldmVsGBAgASgO
MiUuZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYkxldmVsUghqb2JMZXZlbBInCg9w
cm9tb3Rpb25fdmFsdWUYESABKAVSDnByb21vdGlvblZhbHVlEiYKDnF1YWxpZmljYXRpb25z
GBIgASgJUg5xdWFsaWZpY2F0aW9ucxIqChByZXNwb25zaWJpbGl0aWVzGBMgASgJUhByZXNw
b25zaWJpbGl0aWVzElEKDnBvc3RpbmdfcmVnaW9uGBQgASgOMiouZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLlBvc3RpbmdSZWdpb25SDXBvc3RpbmdSZWdpb24SSwoKdmlzaWJpbGl0
eRgVIAEoDjInLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5WaXNpYmlsaXR5QgIYAVIK
dmlzaWJpbGl0eRJACg5qb2Jfc3RhcnRfdGltZRgWIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBSDGpvYlN0YXJ0VGltZRI8Cgxqb2JfZW5kX3RpbWUYFyABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wUgpqb2JFbmRUaW1lEkwKFHBvc3RpbmdfcHVibGlzaF90aW1l
GBggASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIScG9zdGluZ1B1Ymxpc2hUaW1l
EkoKE3Bvc3RpbmdfZXhwaXJlX3RpbWUYGSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wUhFwb3N0aW5nRXhwaXJlVGltZRJPChNwb3N0aW5nX2NyZWF0ZV90aW1lGBogASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUhFwb3N0aW5nQ3JlYXRlVGltZRJPChNw
b3N0aW5nX3VwZGF0ZV90aW1lGBsgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUhFwb3N0aW5nVXBkYXRlVGltZRI1ChRjb21wYW55X2Rpc3BsYXlfbmFtZRgcIAEoCUID
4EEDUhJjb21wYW55RGlzcGxheU5hbWUSVAoMZGVyaXZlZF9pbmZvGB0gASgLMiwuZ29vZ2xl
LmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5EZXJpdmVkSW5mb0ID4EEDUgtkZXJpdmVkSW5m
bxJhChJwcm9jZXNzaW5nX29wdGlvbnMYHiABKAsyMi5nb29nbGUuY2xvdWQudGFsZW50LnY0
YmV0YTEuSm9iLlByb2Nlc3NpbmdPcHRpb25zUhFwcm9jZXNzaW5nT3B0aW9ucxpfCg9BcHBs
aWNhdGlvbkluZm8SFgoGZW1haWxzGAEgAygJUgZlbWFpbHMSIAoLaW5zdHJ1Y3Rpb24YAiAB
KAlSC2luc3RydWN0aW9uEhIKBHVyaXMYAyADKAlSBHVyaXMaowEKC0Rlcml2ZWRJbmZvEkMK
CWxvY2F0aW9ucxgBIAMoCzIlLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Mb2NhdGlv
blIJbG9jYXRpb25zEk8KDmpvYl9jYXRlZ29yaWVzGAMgAygOMiguZ29vZ2xlLmNsb3VkLnRh
bGVudC52NGJldGExLkpvYkNhdGVnb3J5Ug1qb2JDYXRlZ29yaWVzGroBChFQcm9jZXNzaW5n
T3B0aW9ucxJJCiFkaXNhYmxlX3N0cmVldF9hZGRyZXNzX3Jlc29sdXRpb24YASABKAhSHmRp
c2FibGVTdHJlZXRBZGRyZXNzUmVzb2x1dGlvbhJaChFodG1sX3Nhbml0aXphdGlvbhgCIAEo
DjItLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5IdG1sU2FuaXRpemF0aW9uUhBodG1s
U2FuaXRpemF0aW9uGnEKFUN1c3RvbUF0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRJCCgV2YWx1ZRgCIAEoCzIsLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5DdXN0b21B
dHRyaWJ1dGVSBXZhbHVlOgI4ATpr6kFoChdqb2JzLmdvb2dsZWFwaXMuY29tL0pvYhIucHJv
amVjdHMve3Byb2plY3R9L3RlbmFudHMve3RlbmFudH0vam9icy97am9ifRIdcHJvamVjdHMv
e3Byb2plY3R9L2pvYnMve2pvYn1CdAofY29tLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRh
MUIQSm9iUmVzb3VyY2VQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL3RhbGVudC9hcGl2
NGJldGExL3RhbGVudHBiO3RhbGVudHBiogIDQ1RTSoN+CgcSBQ4A+wIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAAyCgkKAgMDEgMVACkKCAoBCBIDFwBOCgkKAggLEgMXAE4KCAoBCBIDGAAi
CgkKAggKEgMYACIKCAoBCBIDGQAxCgkKAggIEgMZADEKCAoBCBIDGgA4CgkKAggBEgMaADgK
CAoBCBIDGwAhCgkKAggkEgMbACEK7QEKAgQAEgUhAPsCARrfASBBIEpvYiByZXNvdXJjZSBy
ZXByZXNlbnRzIGEgam9iIHBvc3RpbmcgKGFsc28gcmVmZXJyZWQgdG8gYXMgYSAiam9iIGxp
c3RpbmciCiBvciAiam9iIHJlcXVpc2l0aW9uIikuIEEgam9iIGJlbG9uZ3MgdG8gYQogW0Nv
bXBhbnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Db21wYW55XSwgd2hpY2ggaXMg
dGhlIGhpcmluZyBlbnRpdHkKIHJlc3BvbnNpYmxlIGZvciB0aGUgam9iLgoKCgoDBAABEgMh
CAsKCwoDBAAHEgQiAiYECg0KBQQAB50IEgQiAiYECj0KBAQAAwASBCkCPgMaLyBBcHBsaWNh
dGlvbiByZWxhdGVkIGRldGFpbHMgb2YgYSBqb2IgcG9zdGluZy4KCgwKBQQAAwABEgMpChkK
rgEKBgQAAwACABIDLgQfGp4BIFVzZSB0aGlzIGZpZWxkIHRvIHNwZWNpZnkgZW1haWwgYWRk
cmVzcyhlcykgdG8gd2hpY2ggcmVzdW1lcyBvcgogYXBwbGljYXRpb25zIGNhbiBiZSBzZW50
LgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgZm9yIGVhY2gg
ZW50cnkgaXMgMjU1LgoKDgoHBAADAAIABBIDLgQMCg4KBwQAAwACAAUSAy4NEwoOCgcEAAMA
AgABEgMuFBoKDgoHBAADAAIAAxIDLh0eCsYCCgYEAAMAAgESAzcEGxq2AiBVc2UgdGhpcyBm
aWVsZCB0byBwcm92aWRlIGluc3RydWN0aW9ucywgc3VjaCBhcyAiTWFpbCB5b3VyIGFwcGxp
Y2F0aW9uCiB0byAuLi4iLCB0aGF0IGEgY2FuZGlkYXRlIGNhbiBmb2xsb3cgdG8gYXBwbHkg
Zm9yIHRoZSBqb2IuCgogVGhpcyBmaWVsZCBhY2NlcHRzIGFuZCBzYW5pdGl6ZXMgSFRNTCBp
bnB1dCwgYW5kIGFsc28gYWNjZXB0cwogYm9sZCwgaXRhbGljLCBvcmRlcmVkIGxpc3QsIGFu
ZCB1bm9yZGVyZWQgbGlzdCBtYXJrdXAgdGFncy4KCiBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDMsMDAwLgoKDgoHBAADAAIBBRIDNwQKCg4KBwQAAwAC
AQESAzcLFgoOCgcEAAMAAgEDEgM3GRoKwQEKBgQAAwACAhIDPQQdGrEBIFVzZSB0aGlzIFVS
SSBmaWVsZCB0byBkaXJlY3QgYW4gYXBwbGljYW50IHRvIGEgd2Vic2l0ZSwgZm9yIGV4YW1w
bGUgdG8KIGxpbmsgdG8gYW4gb25saW5lIGFwcGxpY2F0aW9uIGZvcm0uCgogVGhlIG1heGlt
dW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBmb3IgZWFjaCBlbnRyeSBpcyAyLDAw
MC4KCg4KBwQAAwACAgQSAz0EDAoOCgcEAAMAAgIFEgM9DRMKDgoHBAADAAICARIDPRQYCg4K
BwQAAwACAgMSAz0bHAo2CgQEAAMBEgRBAk8DGiggRGVyaXZlZCBkZXRhaWxzIGFib3V0IHRo
ZSBqb2IgcG9zdGluZy4KCgwKBQQAAwEBEgNBChUKqgIKBgQAAwECABIDSQQkGpoCIFN0cnVj
dHVyZWQgbG9jYXRpb25zIG9mIHRoZSBqb2IsIHJlc29sdmVkIGZyb20KIFtKb2IuYWRkcmVz
c2VzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmFkZHJlc3Nlc10uCgogW2xv
Y2F0aW9uc11bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5EZXJpdmVkSW5mby5s
b2NhdGlvbnNdIGFyZQogZXhhY3RseSBtYXRjaGVkIHRvCiBbSm9iLmFkZHJlc3Nlc11bZ29v
Z2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5hZGRyZXNzZXNdIGluIHRoZSBzYW1lCiBv
cmRlci4KCg4KBwQAAwECAAQSA0kEDAoOCgcEAAMBAgAGEgNJDRUKDgoHBAADAQIAARIDSRYf
Cg4KBwQAAwECAAMSA0kiIwqmAQoGBAADAQIBEgNOBCwalgEgSm9iIGNhdGVnb3JpZXMgZGVy
aXZlZCBmcm9tCiBbSm9iLnRpdGxlXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9i
LnRpdGxlXSBhbmQKIFtKb2IuZGVzY3JpcHRpb25dW2dvb2dsZS5jbG91ZC50YWxlbnQudjRi
ZXRhMS5Kb2IuZGVzY3JpcHRpb25dLgoKDgoHBAADAQIBBBIDTgQMCg4KBwQAAwECAQYSA04N
GAoOCgcEAAMBAgEBEgNOGScKDgoHBAADAQIBAxIDTiorCisKBAQAAwISBFICZQMaHSBPcHRp
b25zIGZvciBqb2IgcHJvY2Vzc2luZy4KCgwKBQQAAwIBEgNSChsKbwoGBAADAgIAEgNVBC8a
YCBJZiBzZXQgdG8gYHRydWVgLCB0aGUgc2VydmljZSBkb2VzIG5vdCBhdHRlbXB0IHRvIHJl
c29sdmUgYQogbW9yZSBwcmVjaXNlIGFkZHJlc3MgZm9yIHRoZSBqb2IuCgoOCgcEAAMCAgAF
EgNVBAgKDgoHBAADAgIAARIDVQkqCg4KBwQAAwICAAMSA1UtLgr/AgoGBAADAgIBEgNkBCsa
7wIgT3B0aW9uIGZvciBqb2IgSFRNTCBjb250ZW50IHNhbml0aXphdGlvbi4gQXBwbGllZCBm
aWVsZHMgYXJlOgoKICogZGVzY3JpcHRpb24KICogYXBwbGljYXRpb25JbmZvLmluc3RydWN0
aW9uCiAqIGluY2VudGl2ZXMKICogcXVhbGlmaWNhdGlvbnMKICogcmVzcG9uc2liaWxpdGll
cwoKIEhUTUwgdGFncyBpbiB0aGVzZSBmaWVsZHMgbWF5IGJlIHN0cmlwcGVkIGlmIHNhbml0
aWF6YXRpb24gaXNuJ3QKIGRpc2FibGVkLgoKIERlZmF1bHRzIHRvCiBbSHRtbFNhbml0aXph
dGlvbi5TSU1QTEVfRk9STUFUVElOR19PTkxZXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0
YTEuSHRtbFNhbml0aXphdGlvbi5TSU1QTEVfRk9STUFUVElOR19PTkxZXS4KCg4KBwQAAwIC
AQYSA2QEFAoOCgcEAAMCAgEBEgNkFSYKDgoHBAADAgIBAxIDZCkqCpMECgQEAAIAEgN2AhIa
hQQgUmVxdWlyZWQgZHVyaW5nIGpvYiB1cGRhdGUuCgogVGhlIHJlc291cmNlIG5hbWUgZm9y
IHRoZSBqb2IuIFRoaXMgaXMgZ2VuZXJhdGVkIGJ5IHRoZSBzZXJ2aWNlIHdoZW4gYQogam9i
IGlzIGNyZWF0ZWQuCgogVGhlIGZvcm1hdCBpcwogInByb2plY3RzL3twcm9qZWN0X2lkfS90
ZW5hbnRzL3t0ZW5hbnRfaWR9L2pvYnMve2pvYl9pZH0iLiBGb3IKIGV4YW1wbGUsICJwcm9q
ZWN0cy9mb28vdGVuYW50cy9iYXIvam9icy9iYXoiLgoKIElmIHRlbmFudCBpZCBpcyB1bnNw
ZWNpZmllZCwgdGhlIGRlZmF1bHQgdGVuYW50IGlzIHVzZWQuIEZvcgogZXhhbXBsZSwgInBy
b2plY3RzL2Zvby9qb2JzL2JhciIuCgogVXNlIG9mIHRoaXMgZmllbGQgaW4gam9iIHF1ZXJp
ZXMgYW5kIEFQSSBjYWxscyBpcyBwcmVmZXJyZWQgb3ZlciB0aGUgdXNlIG9mCiBbcmVxdWlz
aXRpb25faWRdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2IucmVxdWlzaXRpb25f
aWRdIHNpbmNlIHRoaXMKIHZhbHVlIGlzIHVuaXF1ZS4KCgwKBQQAAgAFEgN2AggKDAoFBAAC
AAESA3YJDQoMCgUEAAIAAxIDdhARCsICCgQEAAIBEgaAAQKDAQQasQIgUmVxdWlyZWQuIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjb21wYW55IGxpc3RpbmcgdGhlIGpvYi4KCiBUaGUg
Zm9ybWF0IGlzCiAicHJvamVjdHMve3Byb2plY3RfaWR9L3RlbmFudHMve3RlbmFudF9pZH0v
Y29tcGFuaWVzL3tjb21wYW55X2lkfSIuIEZvcgogZXhhbXBsZSwgInByb2plY3RzL2Zvby90
ZW5hbnRzL2Jhci9jb21wYW5pZXMvYmF6Ii4KCiBJZiB0ZW5hbnQgaWQgaXMgdW5zcGVjaWZp
ZWQsIHRoZSBkZWZhdWx0IHRlbmFudCBpcyB1c2VkLiBGb3IKIGV4YW1wbGUsICJwcm9qZWN0
cy9mb28vY29tcGFuaWVzL2JhciIuCgoNCgUEAAIBBRIEgAECCAoNCgUEAAIBARIEgAEJEAoN
CgUEAAIBAxIEgAETFAoPCgUEAAIBCBIGgAEVgwEDChAKCAQAAgEInAgAEgSBAQQqCg8KBwQA
AgEInwgSBIIBBE0KlwQKBAQAAgISBI4BAkUaiAQgUmVxdWlyZWQuIFRoZSByZXF1aXNpdGlv
biBJRCwgYWxzbyByZWZlcnJlZCB0byBhcyB0aGUgcG9zdGluZyBJRCwgaXMKIGFzc2lnbmVk
IGJ5IHRoZSBjbGllbnQgdG8gaWRlbnRpZnkgYSBqb2IuIFRoaXMgZmllbGQgaXMgaW50ZW5k
ZWQgdG8gYmUgdXNlZAogYnkgY2xpZW50cyBmb3IgY2xpZW50IGlkZW50aWZpY2F0aW9uIGFu
ZCB0cmFja2luZyBvZiBwb3N0aW5ncy4gQSBqb2IgaXNuJ3QKIGFsbG93ZWQgdG8gYmUgY3Jl
YXRlZCBpZiB0aGVyZSBpcyBhbm90aGVyIGpvYiB3aXRoIHRoZSBzYW1lCiBbY29tcGFueV1b
Z29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5uYW1lXSwKIFtsYW5ndWFnZV9jb2Rl
XVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmxhbmd1YWdlX2NvZGVdIGFuZAog
W3JlcXVpc2l0aW9uX2lkXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLnJlcXVp
c2l0aW9uX2lkXS4KCiBUaGUgbWF4aW11bSBudW1iZXIgb2YgYWxsb3dlZCBjaGFyYWN0ZXJz
IGlzIDI1NS4KCg0KBQQAAgIFEgSOAQIICg0KBQQAAgIBEgSOAQkXCg0KBQQAAgIDEgSOARob
Cg0KBQQAAgIIEgSOARxEChAKCAQAAgIInAgAEgSOAR1DCn4KBAQAAgMSBJMBAjwacCBSZXF1
aXJlZC4gVGhlIHRpdGxlIG9mIHRoZSBqb2IsIHN1Y2ggYXMgIlNvZnR3YXJlIEVuZ2luZWVy
IgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMgaXMgNTAwLgoK
DQoFBAACAwUSBJMBAggKDQoFBAACAwESBJMBCQ4KDQoFBAACAwMSBJMBERIKDQoFBAACAwgS
BJMBEzsKEAoIBAACAwicCAASBJMBFDoK2QQKBAQAAgQSBKABAkIaygQgUmVxdWlyZWQuIFRo
ZSBkZXNjcmlwdGlvbiBvZiB0aGUgam9iLCB3aGljaCB0eXBpY2FsbHkgaW5jbHVkZXMgYQog
bXVsdGktcGFyYWdyYXBoIGRlc2NyaXB0aW9uIG9mIHRoZSBjb21wYW55IGFuZCByZWxhdGVk
IGluZm9ybWF0aW9uLgogU2VwYXJhdGUgZmllbGRzIGFyZSBwcm92aWRlZCBvbiB0aGUgam9i
IG9iamVjdCBmb3IKIFtyZXNwb25zaWJpbGl0aWVzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0
YmV0YTEuSm9iLnJlc3BvbnNpYmlsaXRpZXNdLAogW3F1YWxpZmljYXRpb25zXVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLnF1YWxpZmljYXRpb25zXSwgYW5kIG90aGVyCiBq
b2IgY2hhcmFjdGVyaXN0aWNzLiBVc2Ugb2YgdGhlc2Ugc2VwYXJhdGUgam9iIGZpZWxkcyBp
cyByZWNvbW1lbmRlZC4KCiBUaGlzIGZpZWxkIGFjY2VwdHMgYW5kIHNhbml0aXplcyBIVE1M
IGlucHV0LCBhbmQgYWxzbyBhY2NlcHRzCiBib2xkLCBpdGFsaWMsIG9yZGVyZWQgbGlzdCwg
YW5kIHVub3JkZXJlZCBsaXN0IG1hcmt1cCB0YWdzLgoKIFRoZSBtYXhpbXVtIG51bWJlciBv
ZiBhbGxvd2VkIGNoYXJhY3RlcnMgaXMgMTAwLDAwMC4KCg0KBQQAAgQFEgSgAQIICg0KBQQA
AgQBEgSgAQkUCg0KBQQAAgQDEgSgARcYCg0KBQQAAgQIEgSgARlBChAKCAQAAgQInAgAEgSg
ARpACs0ICgQEAAIFEgS3AQIgGr4IIFN0cm9uZ2x5IHJlY29tbWVuZGVkIGZvciB0aGUgYmVz
dCBzZXJ2aWNlIGV4cGVyaWVuY2UuCgogTG9jYXRpb24ocykgd2hlcmUgdGhlIGVtcGxveWVy
IGlzIGxvb2tpbmcgdG8gaGlyZSBmb3IgdGhpcyBqb2IgcG9zdGluZy4KCiBTcGVjaWZ5aW5n
IHRoZSBmdWxsIHN0cmVldCBhZGRyZXNzKGVzKSBvZiB0aGUgaGlyaW5nIGxvY2F0aW9uIGVu
YWJsZXMKIGJldHRlciBBUEkgcmVzdWx0cywgZXNwZWNpYWxseSBqb2Igc2VhcmNoZXMgYnkg
Y29tbXV0ZSB0aW1lLgoKIEF0IG1vc3QgNTAgbG9jYXRpb25zIGFyZSBhbGxvd2VkIGZvciBi
ZXN0IHNlYXJjaCBwZXJmb3JtYW5jZS4gSWYgYSBqb2IgaGFzCiBtb3JlIGxvY2F0aW9ucywg
aXQgaXMgc3VnZ2VzdGVkIHRvIHNwbGl0IGl0IGludG8gbXVsdGlwbGUgam9icyB3aXRoIHVu
aXF1ZQogW3JlcXVpc2l0aW9uX2lkXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9i
LnJlcXVpc2l0aW9uX2lkXXMgKGUuZy4KICdSZXFBJyBiZWNvbWVzICdSZXFBLTEnLCAnUmVx
QS0yJywgYW5kIHNvIG9uLikgYXMgbXVsdGlwbGUgam9icyB3aXRoIHRoZQogc2FtZSBbY29t
cGFueV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5jb21wYW55XSwKIFtsYW5n
dWFnZV9jb2RlXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmxhbmd1YWdlX2Nv
ZGVdIGFuZAogW3JlcXVpc2l0aW9uX2lkXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEu
Sm9iLnJlcXVpc2l0aW9uX2lkXSBhcmUgbm90CiBhbGxvd2VkLiBJZiB0aGUgb3JpZ2luYWwK
IFtyZXF1aXNpdGlvbl9pZF1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5yZXF1
aXNpdGlvbl9pZF0gbXVzdCBiZQogcHJlc2VydmVkLCBhIGN1c3RvbSBmaWVsZCBzaG91bGQg
YmUgdXNlZCBmb3Igc3RvcmFnZS4gSXQgaXMgYWxzbyBzdWdnZXN0ZWQKIHRvIGdyb3VwIHRo
ZSBsb2NhdGlvbnMgdGhhdCBjbG9zZSB0byBlYWNoIG90aGVyIGluIHRoZSBzYW1lIGpvYiBm
b3IgYmV0dGVyCiBzZWFyY2ggZXhwZXJpZW5jZS4KCiBUaGUgbWF4aW11bSBudW1iZXIgb2Yg
YWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDUwMC4KCg0KBQQAAgUEEgS3AQIKCg0KBQQAAgUFEgS3
AQsRCg0KBQQAAgUBEgS3ARIbCg0KBQQAAgUDEgS3AR4fCiwKBAQAAgYSBLoBAicaHiBKb2Ig
YXBwbGljYXRpb24gaW5mb3JtYXRpb24uCgoNCgUEAAIGBhIEugECEQoNCgUEAAIGARIEugES
IgoNCgUEAAIGAxIEugElJgozCgQEAAIHEgS9AQInGiUgVGhlIGJlbmVmaXRzIGluY2x1ZGVk
IHdpdGggdGhlIGpvYi4KCg0KBQQAAgcEEgS9AQIKCg0KBQQAAgcGEgS9AQsVCg0KBQQAAgcB
EgS9ARYiCg0KBQQAAgcDEgS9ASUmCngKBAQAAggSBMEBAikaaiBKb2IgY29tcGVuc2F0aW9u
IGluZm9ybWF0aW9uIChhLmsuYS4gInBheSByYXRlIikgaS5lLiwgdGhlIGNvbXBlbnNhdGlv
bgogdGhhdCB3aWxsIHBhaWQgdG8gdGhlIGVtcGxveWVlLgoKDQoFBAACCAYSBMEBAhIKDQoF
BAACCAESBMEBEyQKDQoFBAACCAMSBMEBJygK4QQKBAQAAgkSBM8BAjYa0gQgQSBtYXAgb2Yg
ZmllbGRzIHRvIGhvbGQgYm90aCBmaWx0ZXJhYmxlIGFuZCBub24tZmlsdGVyYWJsZSBjdXN0
b20gam9iCiBhdHRyaWJ1dGVzIHRoYXQgYXJlIG5vdCBjb3ZlcmVkIGJ5IHRoZSBwcm92aWRl
ZCBzdHJ1Y3R1cmVkIGZpZWxkcy4KCiBUaGUga2V5cyBvZiB0aGUgbWFwIGFyZSBzdHJpbmdz
IHVwIHRvIDY0IGJ5dGVzIGFuZCBtdXN0IG1hdGNoIHRoZQogcGF0dGVybjogYFthLXpBLVpd
W2EtekEtWjAtOV9dKmAuIEZvciBleGFtcGxlLCBrZXkwTGlrZVRoaXMgb3IKIEtFWV8xX0xJ
S0VfVEhJUy4KCiBBdCBtb3N0IDEwMCBmaWx0ZXJhYmxlIGFuZCBhdCBtb3N0IDEwMCB1bmZp
bHRlcmFibGUga2V5cyBhcmUgc3VwcG9ydGVkLgogRm9yIGZpbHRlcmFibGUgYHN0cmluZ192
YWx1ZXNgLCBhY3Jvc3MgYWxsIGtleXMgYXQgbW9zdCAyMDAgdmFsdWVzIGFyZQogYWxsb3dl
ZCwgd2l0aCBlYWNoIHN0cmluZyBubyBtb3JlIHRoYW4gMjU1IGNoYXJhY3RlcnMuIEZvciB1
bmZpbHRlcmFibGUKIGBzdHJpbmdfdmFsdWVzYCwgdGhlIG1heGltdW0gdG90YWwgc2l6ZSBv
ZiBgc3RyaW5nX3ZhbHVlc2AgYWNyb3NzIGFsbCBrZXlzCiBpcyA1MEtCLgoKDQoFBAACCQYS
BM8BAh4KDQoFBAACCQESBM8BHzAKDQoFBAACCQMSBM8BMzUKVgoEBAACChIE0gECKBpIIFRo
ZSBkZXNpcmVkIGVkdWNhdGlvbiBkZWdyZWVzIGZvciB0aGUgam9iLCBzdWNoIGFzIEJhY2hl
bG9ycywgTWFzdGVycy4KCg0KBQQAAgoEEgTSAQIKCg0KBQQAAgoGEgTSAQsVCg0KBQQAAgoB
EgTSARYiCg0KBQQAAgoDEgTSASUnCpEBCgQEAAILEgTYAQIZGoIBIFRoZSBkZXBhcnRtZW50
IG9yIGZ1bmN0aW9uYWwgYXJlYSB3aXRoaW4gdGhlIGNvbXBhbnkgd2l0aCB0aGUgb3Blbgog
cG9zaXRpb24uCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBp
cyAyNTUuCgoNCgUEAAILBRIE2AECCAoNCgUEAAILARIE2AEJEwoNCgUEAAILAxIE2AEWGArI
AQoEBAACDBIE3QECMBq5ASBUaGUgZW1wbG95bWVudCB0eXBlKHMpIG9mIGEgam9iLCBmb3Ig
ZXhhbXBsZSwKIFtmdWxsIHRpbWVdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5FbXBs
b3ltZW50VHlwZS5GVUxMX1RJTUVdIG9yCiBbcGFydCB0aW1lXVtnb29nbGUuY2xvdWQudGFs
ZW50LnY0YmV0YTEuRW1wbG95bWVudFR5cGUuUEFSVF9USU1FXS4KCg0KBQQAAgwEEgTdAQIK
Cg0KBQQAAgwGEgTdAQsZCg0KBQQAAgwBEgTdARoqCg0KBQQAAgwDEgTdAS0vCsIBCgQEAAIN
EgTjAQIZGrMBIEEgZGVzY3JpcHRpb24gb2YgYm9udXMsIGNvbW1pc3Npb24sIGFuZCBvdGhl
ciBjb21wZW5zYXRpb24KIGluY2VudGl2ZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBqb2Igbm90
IGluY2x1ZGluZyBzYWxhcnkgb3IgcGF5LgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxv
d2VkIGNoYXJhY3RlcnMgaXMgMTAsMDAwLgoKDQoFBAACDQUSBOMBAggKDQoFBAACDQESBOMB
CRMKDQoFBAACDQMSBOMBFhgK1gQKBAQAAg4SBPIBAhwaxwQgVGhlIGxhbmd1YWdlIG9mIHRo
ZSBwb3N0aW5nLiBUaGlzIGZpZWxkIGlzIGRpc3RpbmN0IGZyb20KIGFueSByZXF1aXJlbWVu
dHMgZm9yIGZsdWVuY3kgdGhhdCBhcmUgYXNzb2NpYXRlZCB3aXRoIHRoZSBqb2IuCgogTGFu
Z3VhZ2UgY29kZXMgbXVzdCBiZSBpbiBCQ1AtNDcgZm9ybWF0LCBzdWNoIGFzICJlbi1VUyIg
b3IgInNyLUxhdG4iLgogRm9yIG1vcmUgaW5mb3JtYXRpb24sIHNlZQogW1RhZ3MgZm9yIElk
ZW50aWZ5aW5nIExhbmd1YWdlc10oaHR0cHM6Ly90b29scy5pZXRmLm9yZy9odG1sL2JjcDQ3
KXs6CiBjbGFzcz0iZXh0ZXJuYWwiIHRhcmdldD0iX2JsYW5rIiB9LgoKIElmIHRoaXMgZmll
bGQgaXMgdW5zcGVjaWZpZWQgYW5kCiBbSm9iLmRlc2NyaXB0aW9uXVtnb29nbGUuY2xvdWQu
dGFsZW50LnY0YmV0YTEuSm9iLmRlc2NyaXB0aW9uXSBpcyBwcmVzZW50LAogZGV0ZWN0ZWQg
bGFuZ3VhZ2UgY29kZSBiYXNlZCBvbgogW0pvYi5kZXNjcmlwdGlvbl1bZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NGJldGExLkpvYi5kZXNjcmlwdGlvbl0gaXMgYXNzaWduZWQsCiBvdGhlcndp
c2UgZGVmYXVsdHMgdG8gJ2VuX1VTJy4KCg0KBQQAAg4FEgTyAQIICg0KBQQAAg4BEgTyAQkW
Cg0KBQQAAg4DEgTyARkbClQKBAQAAg8SBPUBAhoaRiBUaGUgZXhwZXJpZW5jZSBsZXZlbCBh
c3NvY2lhdGVkIHdpdGggdGhlIGpvYiwgc3VjaCBhcyAiRW50cnkgTGV2ZWwiLgoKDQoFBAAC
DwYSBPUBAgoKDQoFBAACDwESBPUBCxQKDQoFBAACDwMSBPUBFxkKrgMKBAQAAhASBP4BAh0a
nwMgQSBwcm9tb3Rpb24gdmFsdWUgb2YgdGhlIGpvYiwgYXMgZGV0ZXJtaW5lZCBieSB0aGUg
Y2xpZW50LgogVGhlIHZhbHVlIGRldGVybWluZXMgdGhlIHNvcnQgb3JkZXIgb2YgdGhlIGpv
YnMgcmV0dXJuZWQgd2hlbiBzZWFyY2hpbmcgZm9yCiBqb2JzIHVzaW5nIHRoZSBmZWF0dXJl
ZCBqb2JzIHNlYXJjaCBjYWxsLCB3aXRoIGhpZ2hlciBwcm9tb3Rpb25hbCB2YWx1ZXMKIGJl
aW5nIHJldHVybmVkIGZpcnN0IGFuZCB0aWVzIGJlaW5nIHJlc29sdmVkIGJ5IHJlbGV2YW5j
ZSBzb3J0LiBPbmx5IHRoZQogam9icyB3aXRoIGEgcHJvbW90aW9uVmFsdWUgPjAgYXJlIHJl
dHVybmVkIGluIGEgRkVBVFVSRURfSk9CX1NFQVJDSC4KCiBEZWZhdWx0IHZhbHVlIGlzIDAs
IGFuZCBuZWdhdGl2ZSB2YWx1ZXMgYXJlIHRyZWF0ZWQgYXMgMC4KCg0KBQQAAhAFEgT+AQIH
Cg0KBQQAAhABEgT+AQgXCg0KBQQAAhADEgT+ARocCpoDCgQEAAIREgSJAgIdGosDIEEgZGVz
Y3JpcHRpb24gb2YgdGhlIHF1YWxpZmljYXRpb25zIHJlcXVpcmVkIHRvIHBlcmZvcm0gdGhl
CiBqb2IuIFRoZSB1c2Ugb2YgdGhpcyBmaWVsZCBpcyByZWNvbW1lbmRlZAogYXMgYW4gYWx0
ZXJuYXRpdmUgdG8gdXNpbmcgdGhlIG1vcmUgZ2VuZXJhbAogW2Rlc2NyaXB0aW9uXVtnb29n
bGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLmRlc2NyaXB0aW9uXSBmaWVsZC4KCiBUaGlz
IGZpZWxkIGFjY2VwdHMgYW5kIHNhbml0aXplcyBIVE1MIGlucHV0LCBhbmQgYWxzbyBhY2Nl
cHRzCiBib2xkLCBpdGFsaWMsIG9yZGVyZWQgbGlzdCwgYW5kIHVub3JkZXJlZCBsaXN0IG1h
cmt1cCB0YWdzLgoKIFRoZSBtYXhpbXVtIG51bWJlciBvZiBhbGxvd2VkIGNoYXJhY3RlcnMg
aXMgMTAsMDAwLgoKDQoFBAACEQUSBIkCAggKDQoFBAACEQESBIkCCRcKDQoFBAACEQMSBIkC
GhwK/wIKBAQAAhISBJMCAh8a8AIgQSBkZXNjcmlwdGlvbiBvZiBqb2IgcmVzcG9uc2liaWxp
dGllcy4gVGhlIHVzZSBvZiB0aGlzIGZpZWxkIGlzCiByZWNvbW1lbmRlZCBhcyBhbiBhbHRl
cm5hdGl2ZSB0byB1c2luZyB0aGUgbW9yZSBnZW5lcmFsCiBbZGVzY3JpcHRpb25dW2dvb2ds
ZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2IuZGVzY3JpcHRpb25dIGZpZWxkLgoKIFRoaXMg
ZmllbGQgYWNjZXB0cyBhbmQgc2FuaXRpemVzIEhUTUwgaW5wdXQsIGFuZCBhbHNvIGFjY2Vw
dHMKIGJvbGQsIGl0YWxpYywgb3JkZXJlZCBsaXN0LCBhbmQgdW5vcmRlcmVkIGxpc3QgbWFy
a3VwIHRhZ3MuCgogVGhlIG1heGltdW0gbnVtYmVyIG9mIGFsbG93ZWQgY2hhcmFjdGVycyBp
cyAxMCwwMDAuCgoNCgUEAAISBRIEkwICCAoNCgUEAAISARIEkwIJGQoNCgUEAAISAxIEkwIc
HgqyBQoEBAACExIEnwICJBqjBSBUaGUgam9iIFtQb3N0aW5nUmVnaW9uXVtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEuUG9zdGluZ1JlZ2lvbl0gKGZvcgogZXhhbXBsZSwgc3RhdGUs
IGNvdW50cnkpIHRocm91Z2hvdXQgd2hpY2ggdGhlIGpvYiBpcyBhdmFpbGFibGUuIElmIHRo
aXMKIGZpZWxkIGlzIHNldCwgYQogW0xvY2F0aW9uRmlsdGVyXVtnb29nbGUuY2xvdWQudGFs
ZW50LnY0YmV0YTEuTG9jYXRpb25GaWx0ZXJdIGluIGEgc2VhcmNoCiBxdWVyeSB3aXRoaW4g
dGhlIGpvYiByZWdpb24gZmluZHMgdGhpcyBqb2IgcG9zdGluZyBpZiBhbiBleGFjdCBsb2Nh
dGlvbgogbWF0Y2ggaXNuJ3Qgc3BlY2lmaWVkLiBJZiB0aGlzIGZpZWxkIGlzIHNldCB0bwog
W1Bvc3RpbmdSZWdpb24uTkFUSU9OXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuUG9z
dGluZ1JlZ2lvbi5OQVRJT05dIG9yCiBbUG9zdGluZ1JlZ2lvbi5BRE1JTklTVFJBVElWRV9B
UkVBXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuUG9zdGluZ1JlZ2lvbi5BRE1JTklT
VFJBVElWRV9BUkVBXSwKIHNldHRpbmcgam9iIFtKb2IuYWRkcmVzc2VzXVtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEuSm9iLmFkZHJlc3Nlc10gdG8KIHRoZSBzYW1lIGxvY2F0aW9u
IGxldmVsIGFzIHRoaXMgZmllbGQgaXMgc3Ryb25nbHkgcmVjb21tZW5kZWQuCgoNCgUEAAIT
BhIEnwICDwoNCgUEAAITARIEnwIQHgoNCgUEAAITAxIEnwIhIwrQAQoEBAACFBIEqAICMRrB
ASBEZXByZWNhdGVkLiBUaGUgam9iIGlzIG9ubHkgdmlzaWJsZSB0byB0aGUgb3duZXIuCgog
VGhlIHZpc2liaWxpdHkgb2YgdGhlIGpvYi4KCiBEZWZhdWx0cyB0bwogW1Zpc2liaWxpdHku
QUNDT1VOVF9PTkxZXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuVmlzaWJpbGl0eS5B
Q0NPVU5UX09OTFldCiBpZiBub3Qgc3BlY2lmaWVkLgoKDQoFBAACFAYSBKgCAgwKDQoFBAAC
FAESBKgCDRcKDQoFBAACFAMSBKgCGhwKDQoFBAACFAgSBKgCHTAKDgoGBAACFAgDEgSoAh4v
CpwBCgQEAAIVEgSsAgIwGo0BIFRoZSBzdGFydCB0aW1lc3RhbXAgb2YgdGhlIGpvYiBpbiBV
VEMgdGltZSB6b25lLiBUeXBpY2FsbHkgdGhpcyBmaWVsZAogaXMgdXNlZCBmb3IgY29udHJh
Y3RpbmcgZW5nYWdlbWVudHMuIEludmFsaWQgdGltZXN0YW1wcyBhcmUgaWdub3JlZC4KCg0K
BQQAAhUGEgSsAgIbCg0KBQQAAhUBEgSsAhwqCg0KBQQAAhUDEgSsAi0vCogBCgQEAAIWEgSw
AgIuGnogVGhlIGVuZCB0aW1lc3RhbXAgb2YgdGhlIGpvYi4gVHlwaWNhbGx5IHRoaXMgZmll
bGQgaXMgdXNlZCBmb3IgY29udHJhY3RpbmcKIGVuZ2FnZW1lbnRzLiBJbnZhbGlkIHRpbWVz
dGFtcHMgYXJlIGlnbm9yZWQuCgoNCgUEAAIWBhIEsAICGwoNCgUEAAIWARIEsAIcKAoNCgUE
AAIWAxIEsAIrLQqvAQoEBAACFxIEtQICNhqgASBUaGUgdGltZXN0YW1wIHRoaXMgam9iIHBv
c3Rpbmcgd2FzIG1vc3QgcmVjZW50bHkgcHVibGlzaGVkLiBUaGUgZGVmYXVsdAogdmFsdWUg
aXMgdGhlIHRpbWUgdGhlIHJlcXVlc3QgYXJyaXZlcyBhdCB0aGUgc2VydmVyLiBJbnZhbGlk
IHRpbWVzdGFtcHMgYXJlCiBpZ25vcmVkLgoKDQoFBAACFwYSBLUCAhsKDQoFBAACFwESBLUC
HDAKDQoFBAACFwMSBLUCMzUKvhUKBAQAAhgSBOkCAjUarxUgU3Ryb25nbHkgcmVjb21tZW5k
ZWQgZm9yIHRoZSBiZXN0IHNlcnZpY2UgZXhwZXJpZW5jZS4KCiBUaGUgZXhwaXJhdGlvbiB0
aW1lc3RhbXAgb2YgdGhlIGpvYi4gQWZ0ZXIgdGhpcyB0aW1lc3RhbXAsIHRoZQogam9iIGlz
IG1hcmtlZCBhcyBleHBpcmVkLCBhbmQgaXQgbm8gbG9uZ2VyIGFwcGVhcnMgaW4gc2VhcmNo
IHJlc3VsdHMuIFRoZQogZXhwaXJlZCBqb2IgY2FuJ3QgYmUgbGlzdGVkIGJ5IHRoZQogW0xp
c3RKb2JzXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iU2VydmljZS5MaXN0Sm9i
c10gQVBJLCBidXQgaXQgY2FuCiBiZSByZXRyaWV2ZWQgd2l0aCB0aGUKIFtHZXRKb2JdW2dv
b2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5Kb2JTZXJ2aWNlLkdldEpvYl0gQVBJIG9yIHVw
ZGF0ZWQgd2l0aAogdGhlIFtVcGRhdGVKb2JdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRh
MS5Kb2JTZXJ2aWNlLlVwZGF0ZUpvYl0gQVBJIG9yCiBkZWxldGVkIHdpdGggdGhlCiBbRGVs
ZXRlSm9iXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iU2VydmljZS5EZWxldGVK
b2JdIEFQSS4gQW4KIGV4cGlyZWQgam9iIGNhbiBiZSB1cGRhdGVkIGFuZCBvcGVuZWQgYWdh
aW4gYnkgdXNpbmcgYSBmdXR1cmUgZXhwaXJhdGlvbgogdGltZXN0YW1wLiBVcGRhdGluZyBh
biBleHBpcmVkIGpvYiBmYWlscyBpZiB0aGVyZSBpcyBhbm90aGVyIGV4aXN0aW5nIG9wZW4K
IGpvYiB3aXRoIHNhbWUgW2NvbXBhbnldW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5K
b2IuY29tcGFueV0sCiBbbGFuZ3VhZ2VfY29kZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJl
dGExLkpvYi5sYW5ndWFnZV9jb2RlXSBhbmQKIFtyZXF1aXNpdGlvbl9pZF1bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExLkpvYi5yZXF1aXNpdGlvbl9pZF0uCgogVGhlIGV4cGlyZWQg
am9icyBhcmUgcmV0YWluZWQgaW4gb3VyIHN5c3RlbSBmb3IgOTAgZGF5cy4gSG93ZXZlciwg
dGhlCiBvdmVyYWxsIGV4cGlyZWQgam9iIGNvdW50IGNhbm5vdCBleGNlZWQgMyB0aW1lcyB0
aGUgbWF4aW11bSBudW1iZXIgb2YKIG9wZW4gam9icyBvdmVyIHByZXZpb3VzIDcgZGF5cy4g
SWYgdGhpcyB0aHJlc2hvbGQgaXMgZXhjZWVkZWQsCiBleHBpcmVkIGpvYnMgYXJlIGNsZWFu
ZWQgb3V0IGluIG9yZGVyIG9mIGVhcmxpZXN0IGV4cGlyZSB0aW1lLgogRXhwaXJlZCBqb2Jz
IGFyZSBubyBsb25nZXIgYWNjZXNzaWJsZSBhZnRlciB0aGV5IGFyZSBjbGVhbmVkCiBvdXQu
CgogSW52YWxpZCB0aW1lc3RhbXBzIGFyZSBpZ25vcmVkLCBhbmQgdHJlYXRlZCBhcyBleHBp
cmUgdGltZSBub3QgcHJvdmlkZWQuCgogSWYgdGhlIHRpbWVzdGFtcCBpcyBiZWZvcmUgdGhl
IGluc3RhbnQgcmVxdWVzdCBpcyBtYWRlLCB0aGUgam9iCiBpcyB0cmVhdGVkIGFzIGV4cGly
ZWQgaW1tZWRpYXRlbHkgb24gY3JlYXRpb24uIFRoaXMga2luZCBvZiBqb2IgY2FuCiBub3Qg
YmUgdXBkYXRlZC4gQW5kIHdoZW4gY3JlYXRpbmcgYSBqb2Igd2l0aCBwYXN0IHRpbWVzdGFt
cCwgdGhlCiBbcG9zdGluZ19wdWJsaXNoX3RpbWVdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRi
ZXRhMS5Kb2IucG9zdGluZ19wdWJsaXNoX3RpbWVdCiBtdXN0IGJlIHNldCBiZWZvcmUKIFtw
b3N0aW5nX2V4cGlyZV90aW1lXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSm9iLnBv
c3RpbmdfZXhwaXJlX3RpbWVdLgogVGhlIHB1cnBvc2Ugb2YgdGhpcyBmZWF0dXJlIGlzIHRv
IGFsbG93IG90aGVyIG9iamVjdHMsIHN1Y2ggYXMKIFtBcHBsaWNhdGlvbl1bZ29vZ2xlLmNs
b3VkLnRhbGVudC52NGJldGExLkFwcGxpY2F0aW9uXSwgdG8gcmVmZXIgYSBqb2IgdGhhdAog
ZGlkbid0IGV4aXN0IGluIHRoZSBzeXN0ZW0gcHJpb3IgdG8gYmVjb21pbmcgZXhwaXJlZC4g
SWYgeW91IHdhbnQgdG8gbW9kaWZ5CiBhIGpvYiB0aGF0IHdhcyBleHBpcmVkIG9uIGNyZWF0
aW9uLCBkZWxldGUgaXQgYW5kIGNyZWF0ZSBhIG5ldyBvbmUuCgogSWYgdGhpcyB2YWx1ZSBp
c24ndCBwcm92aWRlZCBhdCB0aGUgdGltZSBvZiBqb2IgY3JlYXRpb24gb3IgaXMgaW52YWxp
ZCwKIHRoZSBqb2IgcG9zdGluZyBleHBpcmVzIGFmdGVyIDMwIGRheXMgZnJvbSB0aGUgam9i
J3MgY3JlYXRpb24gdGltZS4gRm9yCiBleGFtcGxlLCBpZiB0aGUgam9iIHdhcyBjcmVhdGVk
IG9uIDIwMTcvMDEvMDEgMTM6MDBBTSBVVEMgd2l0aCBhbgogdW5zcGVjaWZpZWQgZXhwaXJh
dGlvbiBkYXRlLCB0aGUgam9iIGV4cGlyZXMgYWZ0ZXIgMjAxNy8wMS8zMSAxMzowMEFNIFVU
Qy4KCiBJZiB0aGlzIHZhbHVlIGlzbid0IHByb3ZpZGVkIG9uIGpvYiB1cGRhdGUsIGl0IGRl
cGVuZHMgb24gdGhlIGZpZWxkIG1hc2tzCiBzZXQgYnkKIFtVcGRhdGVKb2JSZXF1ZXN0LnVw
ZGF0ZV9tYXNrXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuVXBkYXRlSm9iUmVxdWVz
dC51cGRhdGVfbWFza10uCiBJZiB0aGUgZmllbGQgbWFza3MgaW5jbHVkZQogW2pvYl9lbmRf
dGltZV1bZ29vZ2xlLmNsb3VkLnRhbGVudC52NGJldGExLkpvYi5qb2JfZW5kX3RpbWVdLCBv
ciB0aGUgbWFza3MKIGFyZSBlbXB0eSBtZWFuaW5nIHRoYXQgZXZlcnkgZmllbGQgaXMgdXBk
YXRlZCwgdGhlIGpvYiBwb3N0aW5nIGV4cGlyZXMKIGFmdGVyIDMwIGRheXMgZnJvbSB0aGUg
am9iJ3MgbGFzdCB1cGRhdGUgdGltZS4gT3RoZXJ3aXNlIHRoZSBleHBpcmF0aW9uCiBkYXRl
IGlzbid0IHVwZGF0ZWQuCgoNCgUEAAIYBhIE6QICGwoNCgUEAAIYARIE6QIcLwoNCgUEAAIY
AxIE6QIyNApPCgQEAAIZEgbsAgLtAjIaPyBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3
aGVuIHRoaXMgam9iIHBvc3Rpbmcgd2FzIGNyZWF0ZWQuCgoNCgUEAAIZBhIE7AICGwoNCgUE
AAIZARIE7AIcLwoNCgUEAAIZAxIE7AIyNAoNCgUEAAIZCBIE7QIGMQoQCggEAAIZCJwIABIE
7QIHMApUCgQEAAIaEgbwAgLxAjIaRCBPdXRwdXQgb25seS4gVGhlIHRpbWVzdGFtcCB3aGVu
IHRoaXMgam9iIHBvc3Rpbmcgd2FzIGxhc3QgdXBkYXRlZC4KCg0KBQQAAhoGEgTwAgIbCg0K
BQQAAhoBEgTwAhwvCg0KBQQAAhoDEgTwAjI0Cg0KBQQAAhoIEgTxAgYxChAKCAQAAhoInAgA
EgTxAgcwCkkKBAQAAhsSBPQCAk8aOyBPdXRwdXQgb25seS4gRGlzcGxheSBuYW1lIG9mIHRo
ZSBjb21wYW55IGxpc3RpbmcgdGhlIGpvYi4KCg0KBQQAAhsFEgT0AgIICg0KBQQAAhsBEgT0
AgkdCg0KBQQAAhsDEgT0AiAiCg0KBQQAAhsIEgT0AiNOChAKCAQAAhsInAgAEgT0AiRNCkMK
BAQAAhwSBPcCAkwaNSBPdXRwdXQgb25seS4gRGVyaXZlZCBkZXRhaWxzIGFib3V0IHRoZSBq
b2IgcG9zdGluZy4KCg0KBQQAAhwGEgT3AgINCg0KBQQAAhwBEgT3Ag4aCg0KBQQAAhwDEgT3
Ah0fCg0KBQQAAhwIEgT3AiBLChAKCAQAAhwInAgAEgT3AiFKCisKBAQAAh0SBPoCAiwaHSBP
cHRpb25zIGZvciBqb2IgcHJvY2Vzc2luZy4KCg0KBQQAAh0GEgT6AgITCg0KBQQAAh0BEgT6
AhQmCg0KBQQAAh0DEgT6AikrYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Job::Job ===
    # Fields for Job
    # Field: name Type: 9 ()
    # Field: company Type: 9 ()
    # Field: requisition_id Type: 9 ()
    # Field: title Type: 9 ()
    # Field: description Type: 9 ()
    # Field: addresses Type: 9 ()
    # Field: application_info Type: 11 (.google.cloud.talent.v4beta1.Job.ApplicationInfo)
    # Field: job_benefits Type: 14 (.google.cloud.talent.v4beta1.JobBenefit)
    # Field: compensation_info Type: 11 (.google.cloud.talent.v4beta1.CompensationInfo)
    # Field: custom_attributes Type: 11 (.google.cloud.talent.v4beta1.Job.CustomAttributesEntry)
    # Field: degree_types Type: 14 (.google.cloud.talent.v4beta1.DegreeType)
    # Field: department Type: 9 ()
    # Field: employment_types Type: 14 (.google.cloud.talent.v4beta1.EmploymentType)
    # Field: incentives Type: 9 ()
    # Field: language_code Type: 9 ()
    # Field: job_level Type: 14 (.google.cloud.talent.v4beta1.JobLevel)
    # Field: promotion_value Type: 5 ()
    # Field: qualifications Type: 9 ()
    # Field: responsibilities Type: 9 ()
    # Field: posting_region Type: 14 (.google.cloud.talent.v4beta1.PostingRegion)
    # Field: visibility Type: 14 (.google.cloud.talent.v4beta1.Visibility)
    # Field: job_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: job_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_publish_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: posting_update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: company_display_name Type: 9 ()
    # Field: derived_info Type: 11 (.google.cloud.talent.v4beta1.Job.DerivedInfo)
    # Field: processing_options Type: 11 (.google.cloud.talent.v4beta1.Job.ProcessingOptions)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Job - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/job.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Job;

    my $msg = Google::Cloud::Talent::V4beta1::Job::Job->new({
        name => $name,
        company => $company,
        requisition_id => $requisition_id,
        title => $title,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Job::Job->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/job.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Job::Job

A Job resource represents a job posting (also referred to as a "job listing"
or "job requisition"). A job belongs to a
[Company][google.cloud.talent.v4beta1.Company], which is the hiring entity
responsible for the job.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required during job update.

The resource name for the job. This is generated by the service when a
job is created.

The format is
"projects/{project_id}/tenants/{tenant_id}/jobs/{job_id}". For
example, "projects/foo/tenants/bar/jobs/baz".

If tenant id is unspecified, the default tenant is used. For
example, "projects/foo/jobs/bar".

Use of this field in job queries and API calls is preferred over the use of
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id] since this
value is unique.

=item * C<< $msg->company() >> / C<< $msg->company($value) >>

Type: C<String>

Required. The resource name of the company listing the job.

The format is
"projects/{project_id}/tenants/{tenant_id}/companies/{company_id}". For
example, "projects/foo/tenants/bar/companies/baz".

If tenant id is unspecified, the default tenant is used. For
example, "projects/foo/companies/bar".

=item * C<< $msg->requisition_id() >> / C<< $msg->requisition_id($value) >>

Type: C<String>

Required. The requisition ID, also referred to as the posting ID, is
assigned by the client to identify a job. This field is intended to be used
by clients for client identification and tracking of postings. A job isn't
allowed to be created if there is another job with the same
[company][google.cloud.talent.v4beta1.Job.name],
[language_code][google.cloud.talent.v4beta1.Job.language_code] and
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id].

The maximum number of allowed characters is 255.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Required. The title of the job, such as "Software Engineer"

The maximum number of allowed characters is 500.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Required. The description of the job, which typically includes a
multi-paragraph description of the company and related information.
Separate fields are provided on the job object for
[responsibilities][google.cloud.talent.v4beta1.Job.responsibilities],
[qualifications][google.cloud.talent.v4beta1.Job.qualifications], and other
job characteristics. Use of these separate job fields is recommended.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 100,000.

=item * C<< $msg->addresses() >> / C<< $msg->addresses($value) >>

Type: C<String>

Strongly recommended for the best service experience.

Location(s) where the employer is looking to hire for this job posting.

Specifying the full street address(es) of the hiring location enables
better API results, especially job searches by commute time.

At most 50 locations are allowed for best search performance. If a job has
more locations, it is suggested to split it into multiple jobs with unique
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id]s (e.g.
'ReqA' becomes 'ReqA-1', 'ReqA-2', and so on.) as multiple jobs with the
same [company][google.cloud.talent.v4beta1.Job.company],
[language_code][google.cloud.talent.v4beta1.Job.language_code] and
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id] are not
allowed. If the original
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id] must be
preserved, a custom field should be used for storage. It is also suggested
to group the locations that close to each other in the same job for better
search experience.

The maximum number of allowed characters is 500.

=item * C<< $msg->application_info() >> / C<< $msg->application_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Job::Job::ApplicationInfo>)

Job application information.

=item * C<< $msg->job_benefits() >> / C<< $msg->job_benefits($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::JobBenefit>)

The benefits included with the job.

=item * C<< $msg->compensation_info() >> / C<< $msg->compensation_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Common::CompensationInfo>)

Job compensation information (a.k.a. "pay rate") i.e., the compensation
that will paid to the employee.

=item * C<< $msg->custom_attributes() >> / C<< $msg->custom_attributes($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Job::Job::CustomAttributesEntry>)

A map of fields to hold both filterable and non-filterable custom job
attributes that are not covered by the provided structured fields.

The keys of the map are strings up to 64 bytes and must match the
pattern: `[a-zA-Z][a-zA-Z0-9_]*`. For example, key0LikeThis or
KEY_1_LIKE_THIS.

At most 100 filterable and at most 100 unfilterable keys are supported.
For filterable `string_values`, across all keys at most 200 values are
allowed, with each string no more than 255 characters. For unfilterable
`string_values`, the maximum total size of `string_values` across all keys
is 50KB.

=item * C<< $msg->degree_types() >> / C<< $msg->degree_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::DegreeType>)

The desired education degrees for the job, such as Bachelors, Masters.

=item * C<< $msg->department() >> / C<< $msg->department($value) >>

Type: C<String>

The department or functional area within the company with the open
position.

The maximum number of allowed characters is 255.

=item * C<< $msg->employment_types() >> / C<< $msg->employment_types($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::EmploymentType>)

The employment type(s) of a job, for example,
[full time][google.cloud.talent.v4beta1.EmploymentType.FULL_TIME] or
[part time][google.cloud.talent.v4beta1.EmploymentType.PART_TIME].

=item * C<< $msg->incentives() >> / C<< $msg->incentives($value) >>

Type: C<String>

A description of bonus, commission, and other compensation
incentives associated with the job not including salary or pay.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->language_code() >> / C<< $msg->language_code($value) >>

Type: C<String>

The language of the posting. This field is distinct from
any requirements for fluency that are associated with the job.

Language codes must be in BCP-47 format, such as "en-US" or "sr-Latn".
For more information, see
[Tags for Identifying Languages](https://tools.ietf.org/html/bcp47){:
class="external" target="_blank" }.

If this field is unspecified and
[Job.description][google.cloud.talent.v4beta1.Job.description] is present,
detected language code based on
[Job.description][google.cloud.talent.v4beta1.Job.description] is assigned,
otherwise defaults to 'en_US'.

=item * C<< $msg->job_level() >> / C<< $msg->job_level($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::JobLevel>)

The experience level associated with the job, such as "Entry Level".

=item * C<< $msg->promotion_value() >> / C<< $msg->promotion_value($value) >>

Type: C<Int32>

A promotion value of the job, as determined by the client.
The value determines the sort order of the jobs returned when searching for
jobs using the featured jobs search call, with higher promotional values
being returned first and ties being resolved by relevance sort. Only the
jobs with a promotionValue >0 are returned in a FEATURED_JOB_SEARCH.

Default value is 0, and negative values are treated as 0.

=item * C<< $msg->qualifications() >> / C<< $msg->qualifications($value) >>

Type: C<String>

A description of the qualifications required to perform the
job. The use of this field is recommended
as an alternative to using the more general
[description][google.cloud.talent.v4beta1.Job.description] field.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->responsibilities() >> / C<< $msg->responsibilities($value) >>

Type: C<String>

A description of job responsibilities. The use of this field is
recommended as an alternative to using the more general
[description][google.cloud.talent.v4beta1.Job.description] field.

This field accepts and sanitizes HTML input, and also accepts
bold, italic, ordered list, and unordered list markup tags.

The maximum number of allowed characters is 10,000.

=item * C<< $msg->posting_region() >> / C<< $msg->posting_region($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::PostingRegion>)

The job [PostingRegion][google.cloud.talent.v4beta1.PostingRegion] (for
example, state, country) throughout which the job is available. If this
field is set, a
[LocationFilter][google.cloud.talent.v4beta1.LocationFilter] in a search
query within the job region finds this job posting if an exact location
match isn't specified. If this field is set to
[PostingRegion.NATION][google.cloud.talent.v4beta1.PostingRegion.NATION] or
[PostingRegion.ADMINISTRATIVE_AREA][google.cloud.talent.v4beta1.PostingRegion.ADMINISTRATIVE_AREA],
setting job [Job.addresses][google.cloud.talent.v4beta1.Job.addresses] to
the same location level as this field is strongly recommended.

=item * C<< $msg->visibility() >> / C<< $msg->visibility($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::Visibility>)

Deprecated. The job is only visible to the owner.

The visibility of the job.

Defaults to
[Visibility.ACCOUNT_ONLY][google.cloud.talent.v4beta1.Visibility.ACCOUNT_ONLY]
if not specified.

=item * C<< $msg->job_start_time() >> / C<< $msg->job_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The start timestamp of the job in UTC time zone. Typically this field
is used for contracting engagements. Invalid timestamps are ignored.

=item * C<< $msg->job_end_time() >> / C<< $msg->job_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The end timestamp of the job. Typically this field is used for contracting
engagements. Invalid timestamps are ignored.

=item * C<< $msg->posting_publish_time() >> / C<< $msg->posting_publish_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The timestamp this job posting was most recently published. The default
value is the time the request arrives at the server. Invalid timestamps are
ignored.

=item * C<< $msg->posting_expire_time() >> / C<< $msg->posting_expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Strongly recommended for the best service experience.

The expiration timestamp of the job. After this timestamp, the
job is marked as expired, and it no longer appears in search results. The
expired job can't be listed by the
[ListJobs][google.cloud.talent.v4beta1.JobService.ListJobs] API, but it can
be retrieved with the
[GetJob][google.cloud.talent.v4beta1.JobService.GetJob] API or updated with
the [UpdateJob][google.cloud.talent.v4beta1.JobService.UpdateJob] API or
deleted with the
[DeleteJob][google.cloud.talent.v4beta1.JobService.DeleteJob] API. An
expired job can be updated and opened again by using a future expiration
timestamp. Updating an expired job fails if there is another existing open
job with same [company][google.cloud.talent.v4beta1.Job.company],
[language_code][google.cloud.talent.v4beta1.Job.language_code] and
[requisition_id][google.cloud.talent.v4beta1.Job.requisition_id].

The expired jobs are retained in our system for 90 days. However, the
overall expired job count cannot exceed 3 times the maximum number of
open jobs over previous 7 days. If this threshold is exceeded,
expired jobs are cleaned out in order of earliest expire time.
Expired jobs are no longer accessible after they are cleaned
out.

Invalid timestamps are ignored, and treated as expire time not provided.

If the timestamp is before the instant request is made, the job
is treated as expired immediately on creation. This kind of job can
not be updated. And when creating a job with past timestamp, the
[posting_publish_time][google.cloud.talent.v4beta1.Job.posting_publish_time]
must be set before
[posting_expire_time][google.cloud.talent.v4beta1.Job.posting_expire_time].
The purpose of this feature is to allow other objects, such as
[Application][google.cloud.talent.v4beta1.Application], to refer a job that
didn't exist in the system prior to becoming expired. If you want to modify
a job that was expired on creation, delete it and create a new one.

If this value isn't provided at the time of job creation or is invalid,
the job posting expires after 30 days from the job's creation time. For
example, if the job was created on 2017/01/01 13:00AM UTC with an
unspecified expiration date, the job expires after 2017/01/31 13:00AM UTC.

If this value isn't provided on job update, it depends on the field masks
set by
[UpdateJobRequest.update_mask][google.cloud.talent.v4beta1.UpdateJobRequest.update_mask].
If the field masks include
[job_end_time][google.cloud.talent.v4beta1.Job.job_end_time], or the masks
are empty meaning that every field is updated, the job posting expires
after 30 days from the job's last update time. Otherwise the expiration
date isn't updated.

=item * C<< $msg->posting_create_time() >> / C<< $msg->posting_create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this job posting was created.

=item * C<< $msg->posting_update_time() >> / C<< $msg->posting_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this job posting was last updated.

=item * C<< $msg->company_display_name() >> / C<< $msg->company_display_name($value) >>

Type: C<String>

Output only. Display name of the company listing the job.

=item * C<< $msg->derived_info() >> / C<< $msg->derived_info($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Job::Job::DerivedInfo>)

Output only. Derived details about the job posting.

=item * C<< $msg->processing_options() >> / C<< $msg->processing_options($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Job::Job::ProcessingOptions>)

Options for job processing.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Job::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
