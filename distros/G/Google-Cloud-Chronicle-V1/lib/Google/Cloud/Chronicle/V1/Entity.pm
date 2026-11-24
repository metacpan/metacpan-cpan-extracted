package Google::Cloud::Chronicle::V1::Entity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Backstory::Entity };
    eval { require Google::Backstory::EntityRisk };
    eval { require Google::Backstory::Udm };
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2VudGl0eS5wcm90bxIZZ29vZ2xlLmNsb3Vk
LmNocm9uaWNsZS52MRoWYmFja3N0b3J5L2VudGl0eS5wcm90bxobYmFja3N0b3J5L2VudGl0
eV9yaXNrLnByb3RvGhNiYWNrc3RvcnkvdWRtLnByb3RvGhxnb29nbGUvYXBpL2Fubm90YXRp
b25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxobZ29vZ2xlL3Byb3Rv
YnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxocZ29v
Z2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byLCBQoGRW50aXR5EhIKBG5hbWUYASABKAlSBG5hbWUSPAoIbWV0YWRhdGEYAiABKAsy
IC5nb29nbGUuYmFja3N0b3J5LkVudGl0eU1ldGFkYXRhUghtZXRhZGF0YRIuCgZlbnRpdHkY
AyABKAsyFi5nb29nbGUuYmFja3N0b3J5Lk5vdW5SBmVudGl0eRI3CgphZGRpdGlvbmFsGAUg
ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKYWRkaXRpb25hbBI7CgpyaXNrX3Njb3Jl
GAYgASgLMhwuZ29vZ2xlLmJhY2tzdG9yeS5FbnRpdHlSaXNrUglyaXNrU2NvcmUSMAoGbWV0
cmljGAcgASgLMhguZ29vZ2xlLmJhY2tzdG9yeS5NZXRyaWNSBm1ldHJpYxI4CglyZWxhdGlv
bnMYCCADKAsyGi5nb29nbGUuYmFja3N0b3J5LlJlbGF0aW9uUglyZWxhdGlvbnM60wLqQc8C
Ch9jaHJvbmljbGUuZ29vZ2xlYXBpcy5jb20vRW50aXR5Ek5wcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZW50aXRpZXMve2Vu
dGl0eX0SY3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5j
ZXMve2luc3RhbmNlfS9hbmFseXRpY3Mve2FuYWx5dGljfS9lbnRpdGllcy97ZW50aXR5fRJl
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5z
dGFuY2V9L3dhdGNobGlzdHMve3dhdGNobGlzdH0vZW50aXRpZXMve2VudGl0eX0qCGVudGl0
aWVzMgZlbnRpdHki+AcKCVdhdGNobGlzdBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSJgoM
ZGlzcGxheV9uYW1lGAIgASgJQgPgQQJSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAMg
ASgJQgPgQQFSC2Rlc2NyaXB0aW9uEjIKEm11bHRpcGx5aW5nX2ZhY3RvchgFIAEoAkID4EEB
UhFtdWx0aXBseWluZ0ZhY3RvchKDAQobZW50aXR5X3BvcHVsYXRpb25fbWVjaGFuaXNtGAYg
ASgLMj4uZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5XYXRjaGxpc3QuRW50aXR5UG9wdWxh
dGlvbk1lY2hhbmlzbUID4EECUhllbnRpdHlQb3B1bGF0aW9uTWVjaGFuaXNtElgKDGVudGl0
eV9jb3VudBgHIAEoCzIwLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuV2F0Y2hsaXN0LkVu
dGl0eUNvdW50QgPgQQNSC2VudGl0eUNvdW50EkAKC2NyZWF0ZV90aW1lGAggASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1l
GAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEnYK
GndhdGNobGlzdF91c2VyX3ByZWZlcmVuY2VzGAogASgLMjMuZ29vZ2xlLmNsb3VkLmNocm9u
aWNsZS52MS5XYXRjaGxpc3RVc2VyUHJlZmVyZW5jZXNCA+BBAVIYd2F0Y2hsaXN0VXNlclBy
ZWZlcmVuY2VzGpgBChlFbnRpdHlQb3B1bGF0aW9uTWVjaGFuaXNtEmQKBm1hbnVhbBgBIAEo
CzJFLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuV2F0Y2hsaXN0LkVudGl0eVBvcHVsYXRp
b25NZWNoYW5pc20uTWFudWFsQgPgQQFIAFIGbWFudWFsGggKBk1hbnVhbEILCgltZWNoYW5p
c20aQQoLRW50aXR5Q291bnQSFwoEdXNlchgBIAEoBUID4EEDUgR1c2VyEhkKBWFzc2V0GAIg
ASgFQgPgQQNSBWFzc2V0OpQB6kGQAQoiY2hyb25pY2xlLmdvb2dsZWFwaXMuY29tL1dhdGNo
bGlzdBJTcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNl
cy97aW5zdGFuY2V9L3dhdGNobGlzdHMve3dhdGNobGlzdH0qCndhdGNobGlzdHMyCXdhdGNo
bGlzdCI3ChhXYXRjaGxpc3RVc2VyUHJlZmVyZW5jZXMSGwoGcGlubmVkGAEgASgIQgPgQQFS
BnBpbm5lZCJVChNHZXRXYXRjaGxpc3RSZXF1ZXN0Ej4KBG5hbWUYASABKAlCKuBBAvpBJAoi
Y2hyb25pY2xlLmdvb2dsZWFwaXMuY29tL1dhdGNobGlzdFIEbmFtZSK+AQoVTGlzdFdhdGNo
bGlzdHNSZXF1ZXN0EkIKBnBhcmVudBgBIAEoCUIq4EEC+kEkEiJjaHJvbmljbGUuZ29vZ2xl
YXBpcy5jb20vV2F0Y2hsaXN0UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBh
Z2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgE
IAEoCUID4EEBUgZmaWx0ZXIikAEKFkxpc3RXYXRjaGxpc3RzUmVzcG9uc2USSQoKd2F0Y2hs
aXN0cxgBIAMoCzIkLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuV2F0Y2hsaXN0QgPgQQFS
CndhdGNobGlzdHMSKwoPbmV4dF9wYWdlX3Rva2VuGAIgASgJQgPgQQFSDW5leHRQYWdlVG9r
ZW4izQEKFkNyZWF0ZVdhdGNobGlzdFJlcXVlc3QSQgoGcGFyZW50GAEgASgJQirgQQL6QSQS
ImNocm9uaWNsZS5nb29nbGVhcGlzLmNvbS9XYXRjaGxpc3RSBnBhcmVudBImCgx3YXRjaGxp
c3RfaWQYAiABKAlCA+BBAVILd2F0Y2hsaXN0SWQSRwoJd2F0Y2hsaXN0GAMgASgLMiQuZ29v
Z2xlLmNsb3VkLmNocm9uaWNsZS52MS5XYXRjaGxpc3RCA+BBAlIJd2F0Y2hsaXN0IqMBChZV
cGRhdGVXYXRjaGxpc3RSZXF1ZXN0EkcKCXdhdGNobGlzdBgBIAEoCzIkLmdvb2dsZS5jbG91
ZC5jaHJvbmljbGUudjEuV2F0Y2hsaXN0QgPgQQJSCXdhdGNobGlzdBJACgt1cGRhdGVfbWFz
axgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAVIKdXBkYXRlTWFzayJz
ChZEZWxldGVXYXRjaGxpc3RSZXF1ZXN0Ej4KBG5hbWUYASABKAlCKuBBAvpBJAoiY2hyb25p
Y2xlLmdvb2dsZWFwaXMuY29tL1dhdGNobGlzdFIEbmFtZRIZCgVmb3JjZRgCIAEoCEID4EEB
UgVmb3JjZTK+CAoNRW50aXR5U2VydmljZRKvAQoMR2V0V2F0Y2hsaXN0Ei4uZ29vZ2xlLmNs
b3VkLmNocm9uaWNsZS52MS5HZXRXYXRjaGxpc3RSZXF1ZXN0GiQuZ29vZ2xlLmNsb3VkLmNo
cm9uaWNsZS52MS5XYXRjaGxpc3QiSYLT5JMCPBI6L3YxL3tuYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovaW5zdGFuY2VzLyovd2F0Y2hsaXN0cy8qfdpBBG5hbWUSwgEKDkxpc3RXYXRj
aGxpc3RzEjAuZ29vZ2xlLmNsb3VkLmNocm9uaWNsZS52MS5MaXN0V2F0Y2hsaXN0c1JlcXVl
c3QaMS5nb29nbGUuY2xvdWQuY2hyb25pY2xlLnYxLkxpc3RXYXRjaGxpc3RzUmVzcG9uc2Ui
S4LT5JMCPBI6L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMv
Kn0vd2F0Y2hsaXN0c9pBBnBhcmVudBLZAQoPQ3JlYXRlV2F0Y2hsaXN0EjEuZ29vZ2xlLmNs
b3VkLmNocm9uaWNsZS52MS5DcmVhdGVXYXRjaGxpc3RSZXF1ZXN0GiQuZ29vZ2xlLmNsb3Vk
LmNocm9uaWNsZS52MS5XYXRjaGxpc3QibYLT5JMCRyI6L3YxL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vd2F0Y2hsaXN0czoJd2F0Y2hsaXN02kEdcGFy
ZW50LHdhdGNobGlzdCx3YXRjaGxpc3RfaWQS2wEKD1VwZGF0ZVdhdGNobGlzdBIxLmdvb2ds
ZS5jbG91ZC5jaHJvbmljbGUudjEuVXBkYXRlV2F0Y2hsaXN0UmVxdWVzdBokLmdvb2dsZS5j
bG91ZC5jaHJvbmljbGUudjEuV2F0Y2hsaXN0Im+C0+STAlEyRC92MS97d2F0Y2hsaXN0Lm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi93YXRjaGxpc3RzLyp9Ogl3
YXRjaGxpc3TaQRV3YXRjaGxpc3QsdXBkYXRlX21hc2sSrQEKD0RlbGV0ZVdhdGNobGlzdBIx
Lmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjEuRGVsZXRlV2F0Y2hsaXN0UmVxdWVzdBoWLmdv
b2dsZS5wcm90b2J1Zi5FbXB0eSJPgtPkkwI8KjovdjEve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9pbnN0YW5jZXMvKi93YXRjaGxpc3RzLyp92kEKbmFtZSxmb3JjZRpMykEYY2hy
b25pY2xlLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0
aC9jbG91ZC1wbGF0Zm9ybULCAQodY29tLmdvb2dsZS5jbG91ZC5jaHJvbmljbGUudjFCC0Vu
dGl0eVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vY2hyb25pY2xlL2FwaXYxL2Nocm9u
aWNsZXBiO2Nocm9uaWNsZXBiqgIZR29vZ2xlLkNsb3VkLkNocm9uaWNsZS5WMcoCGUdvb2ds
ZVxDbG91ZFxDaHJvbmljbGVcVjHqAhxHb29nbGU6OkNsb3VkOjpDaHJvbmljbGU6OlYxSs9R
CgcSBQ4AvQIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAi
CgkKAgMAEgMSACAKCQoCAwESAxMAJQoJCgIDAhIDFAAdCgkKAgMDEgMVACYKCQoCAwQSAxYA
IQoJCgIDBRIDFwApCgkKAgMGEgMYACMKCQoCAwcSAxkAJQoJCgIDCBIDGgAqCgkKAgMJEgMb
ACYKCQoCAwoSAxwAKQoICgEIEgMeADYKCQoCCCUSAx4ANgoICgEIEgMfAFIKCQoCCAsSAx8A
UgoICgEIEgMgACIKCQoCCAoSAyAAIgoICgEIEgMhACwKCQoCCAgSAyEALAoICgEIEgMiADYK
CQoCCAESAyIANgoICgEIEgMjADYKCQoCCCkSAyMANgoICgEIEgMkADUKCQoCCC0SAyQANQo/
CgIGABIEJwBWARozIEVudGl0eVNlcnZpY2UgY29udGFpbnMgYXBpcyBmb3IgZmluZGluZyBl
bnRpdGllcy4KCgoKAwYAARIDJwgVCgoKAwYAAxIDKAJACgwKBQYAA5kIEgMoAkAKCwoDBgAD
EgQpAio3Cg0KBQYAA5oIEgQpAio3CkIKBAYAAgASBC0CMgMaNCBHZXRzIHdhdGNobGlzdCBk
ZXRhaWxzIGZvciB0aGUgZ2l2ZW4gd2F0Y2hsaXN0IElELgoKDAoFBgACAAESAy0GEgoMCgUG
AAIAAhIDLRMmCgwKBQYAAgADEgMtMToKDQoFBgACAAQSBC4EMAYKEQoJBgACAASwyrwiEgQu
BDAGCgwKBQYAAgAEEgMxBDIKDwoIBgACAASbCAASAzEEMgo8CgQGAAIBEgQ1AjoDGi4gTGlz
dHMgYWxsIHdhdGNobGlzdHMgZm9yIHRoZSBnaXZlbiBpbnN0YW5jZS4KCgwKBQYAAgEBEgM1
BhQKDAoFBgACAQISAzUVKgoMCgUGAAIBAxIDNTVLCg0KBQYAAgEEEgQ2BDgGChEKCQYAAgEE
sMq8IhIENgQ4BgoMCgUGAAIBBBIDOQQ0Cg8KCAYAAgEEmwgAEgM5BDQKeAoEBgACAhIEPgJE
AxpqIENyZWF0ZXMgYSB3YXRjaGxpc3QgZm9yIHRoZSBnaXZlbiBpbnN0YW5jZS4KIE5vdGUg
dGhhdCB0aGVyZSBjYW4gYmUgYXQgbW9zdCAyMDAgd2F0Y2hsaXN0cyBwZXIgaW5zdGFuY2Uu
CgoMCgUGAAICARIDPgYVCgwKBQYAAgICEgM+FiwKDAoFBgACAgMSAz43QAoNCgUGAAICBBIE
PwRCBgoRCgkGAAICBLDKvCISBD8EQgYKDAoFBgACAgQSA0MESwoPCggGAAICBJsIABIDQwRL
Cj0KBAYAAgMSBEcCTQMaLyBVcGRhdGVzIHRoZSB3YXRjaGxpc3QgZm9yIHRoZSBnaXZlbiBp
bnN0YW5jZS4KCgwKBQYAAgMBEgNHBhUKDAoFBgACAwISA0cWLAoMCgUGAAIDAxIDRzdACg0K
BQYAAgMEEgRIBEsGChEKCQYAAgMEsMq8IhIESARLBgoMCgUGAAIDBBIDTARDCg8KCAYAAgME
mwgAEgNMBEMKPQoEBgACBBIEUAJVAxovIERlbGV0ZXMgdGhlIHdhdGNobGlzdCBmb3IgdGhl
IGdpdmVuIGluc3RhbmNlLgoKDAoFBgACBAESA1AGFQoMCgUGAAIEAhIDUBYsCgwKBQYAAgQD
EgNQN0wKDQoFBgACBAQSBFEEUwYKEQoJBgACBASwyrwiEgRRBFMGCgwKBQYAAgQEEgNUBDgK
DwoIBgACBASbCAASA1QEOAq3AwoCBAASBV4AggEBGqkDIEFuIEVudGl0eSBwcm92aWRlcyBh
ZGRpdGlvbmFsIGNvbnRleHQgYWJvdXQgYW4gZW50aXR5IGluIGEgVURNIGV2ZW50IChhc3Nl
dCwKIHVzZXIsIGV0Yy4pLiBGb3IgZXhhbXBsZSwgYSBQUk9DRVNTX0xBVU5DSCBldmVudCBk
ZXNjcmliZXMgdGhhdCB1c2VyCiAnYWJjQGV4YW1wbGUuY29ycCcgbGF1bmNoZWQgcHJvY2Vz
cyAnc2hhZHkuZXhlJy4gVGhlIGV2ZW50IGRvZXMgbm90IGluY2x1ZGUKIGluZm9ybWF0aW9u
IHRoYXQgdXNlciAnYWJjQGV4YW1wbGUuY29tJyBpcyBhIHJlY2VudGx5IHRlcm1pbmF0ZWQg
ZW1wbG95ZWUgd2hvCiBhZG1pbmlzdGVycyBhIHNlcnZlciBzdG9yaW5nIGZpbmFuY2UgZGF0
YS4gSW5mb3JtYXRpb24gc3RvcmVkIGluIG9uZSBvciBtb3JlCiBFbnRpdGllcyBjYW4gYWRk
IHRoaXMgYWRkaXRpb25hbCBjb250ZXh0LgoKCgoDBAABEgNeCA4KCwoDBAAHEgRfAmYECg0K
BQQAB50IEgRfAmYECtsCCgQEAAIAEgNtAhIazQIgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhl
IGVudGl0eS4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vZW50aXRpZXMve2VudGl0eX1gCiBgcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9
L2FuYWx5dGljcy97YW5hbHl0aWN9L2VudGl0aWVzL3tlbnRpdHl9YAogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNlfS93YXRj
aGxpc3RzL3t3YXRjaGxpc3R9L2VudGl0aWVzL3tlbnRpdHl9YAoKDAoFBAACAAUSA20CCAoM
CgUEAAIAARIDbQkNCgwKBQQAAgADEgNtEBEKPwoEBAACARIDcAIoGjIgRW50aXR5IG1ldGFk
YXRhIHN1Y2ggYXMgdGltZXN0YW1wLCBwcm9kdWN0LCBldGMuCgoMCgUEAAIBBhIDcAIaCgwK
BQQAAgEBEgNwGyMKDAoFBAACAQMSA3AmJwpBCgQEAAICEgNzAhwaNCBOb3VuIGluIHRoZSBV
RE0gZXZlbnQgdGhhdCB0aGlzIGVudGl0eSByZXByZXNlbnRzLgoKDAoFBAACAgYSA3MCEAoM
CgUEAAICARIDcxEXCgwKBQQAAgIDEgNzGhsKdQoEBAACAxIDdwIoGmggSW1wb3J0YW50IGVu
dGl0eSBkYXRhIHRoYXQgY2Fubm90IGJlIGFkZXF1YXRlbHkgcmVwcmVzZW50ZWQgd2l0aGlu
CiB0aGUgZm9ybWFsIHNlY3Rpb25zIG9mIHRoZSBFbnRpdHkuCgoMCgUEAAIDBhIDdwIYCgwK
BQQAAgMBEgN3GSMKDAoFBAACAwMSA3cmJwo5CgQEAAIEEgN6AiYaLCBSZXByZXNlbnRzIHRo
ZSBlbnRpdHkgcmlzayBzY29yZXMgcmVzb3VyY2UKCgwKBQQAAgQGEgN6AhYKDAoFBAACBAES
A3oXIQoMCgUEAAIEAxIDeiQlCkoKBAQAAgUSA30CHho9IE1ldHJpYyBkZXRhaWxzIG9mIHRo
ZSBlbnRpdHkuIFVzZWQgaWYgRW50aXR5VHlwZSBpcyBNRVRSSUMuCgoMCgUEAAIFBhIDfQIS
CgwKBQQAAgUBEgN9ExkKDAoFBAACBQMSA30cHQqJAQoEBAACBhIEgQECLBp7IE9uZSBvciBt
b3JlIHJlbGF0aW9uc2hpcHMgYmV0d2VlbiB0aGUgZW50aXR5IChhKSBhbmQgb3RoZXIgZW50
aXRpZXMsCiBpbmNsdWRpbmcgdGhlIHJlbGF0aW9uc2hpcCB0eXBlIGFuZCByZWxhdGVkIGVu
dGl0eS4KCg0KBQQAAgYEEgSBAQIKCg0KBQQAAgYGEgSBAQsdCg0KBQQAAgYBEgSBAR4nCg0K
BQQAAgYDEgSBASorCm4KAgQBEgaGAQDIAQEaYCBBIHdhdGNobGlzdCBpcyBhIGxpc3Qgb2Yg
ZW50aXRpZXMgdGhhdCBhbGxvd3MgZm9yIGJ1bGsgb3BlcmF0aW9ucyBvdmVyIHRoZQogaW5j
bHVkZWQgZW50aXRpZXMuCgoLCgMEAQESBIYBCBEKDQoDBAEHEgaHAQKMAQQKDwoFBAEHnQgS
BocBAowBBApCCgQEAQMAEgaPAQKZAQMaMiBNZWNoYW5pc20gdG8gcG9wdWxhdGUgZW50aXRp
ZXMgaW4gdGhlIHdhdGNobGlzdC4KCg0KBQQBAwABEgSPAQojCi4KBgQBAwADABIEkQEEFRoe
IEVudGl0aWVzIGFyZSBhZGRlZCBtYW51YWxseS4KCg8KBwQBAwADAAESBJEBDBIKYQoGBAED
AAgAEgaVAQSYAQUaTyBXYXlzIHRvIHBvcHVsYXRlIGVudGl0aWVzIGluIHdhdGNobGlzdC4K
IEN1cnJlbnRseSwgb25seSBtYW51YWwgaXMgc3VwcG9ydGVkLgoKDwoHBAEDAAgAARIElQEK
Ewo4CgYEAQMAAgASBJcBBkEaKCBPcHRpb25hbC4gRW50aXRpZXMgYXJlIGFkZGVkIG1hbnVh
bGx5LgoKDwoHBAEDAAIABhIElwEGDAoPCgcEAQMAAgABEgSXAQ0TCg8KBwQBAwACAAMSBJcB
FhcKDwoHBAEDAAIACBIElwEYQAoSCgoEAQMAAgAInAgAEgSXARk/CkgKBAQBAwESBpwBAqIB
Axo4IENvdW50IG9mIGRpZmZlcmVudCB0eXBlcyBvZiBlbnRpdGllcyBpbiB0aGUgd2F0Y2hs
aXN0LgoKDQoFBAEDAQESBJwBChUKTAoGBAEDAQIAEgSeAQQ/GjwgT3V0cHV0IG9ubHkuIENv
dW50IG9mIHVzZXIgdHlwZSBlbnRpdGllcyBpbiB0aGUgd2F0Y2hsaXN0LgoKDwoHBAEDAQIA
BRIEngEECQoPCgcEAQMBAgABEgSeAQoOCg8KBwQBAwECAAMSBJ4BERIKDwoHBAEDAQIACBIE
ngETPgoSCgoEAQMBAgAInAgAEgSeARQ9Ck0KBgQBAwECARIEoQEEQBo9IE91dHB1dCBvbmx5
LiBDb3VudCBvZiBhc3NldCB0eXBlIGVudGl0aWVzIGluIHRoZSB3YXRjaGxpc3QuCgoPCgcE
AQMBAgEFEgShAQQJCg8KBwQBAwECAQESBKEBCg8KDwoHBAEDAQIBAxIEoQESEwoPCgcEAQMB
AgEIEgShARQ/ChIKCgQBAwECAQicCAASBKEBFT4KnAEKBAQBAgASBKcBAj0ajQEgSWRlbnRp
Zmllci4gUmVzb3VyY2UgbmFtZSBvZiB0aGUgd2F0Y2hsaXN0LgogRm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2luc3RhbmNl
fS93YXRjaGxpc3RzL3t3YXRjaGxpc3R9YAoKDQoFBAECAAUSBKcBAggKDQoFBAECAAESBKcB
CQ0KDQoFBAECAAMSBKcBEBEKDQoFBAECAAgSBKcBEjwKEAoIBAECAAicCAASBKcBEzsKoQEK
BAQBAgESBKwBAkMakgEgUmVxdWlyZWQuIERpc3BsYXkgbmFtZSBvZiB0aGUgd2F0Y2hsaXN0
LgogTm90ZSB0aGF0IGl0IG11c3QgYmUgYXQgbGVhc3Qgb25lIGNoYXJhY3RlciBhbmQgbGVz
cyB0aGFuIDYzIGNoYXJhY3RlcnMKIChodHRwczovL2dvb2dsZS5haXAuZGV2LzE0OCkuCgoN
CgUEAQIBBRIErAECCAoNCgUEAQIBARIErAEJFQoNCgUEAQIBAxIErAEYGQoNCgUEAQIBCBIE
rAEaQgoQCggEAQIBCJwIABIErAEbQQo3CgQEAQICEgSvAQJCGikgT3B0aW9uYWwuIERlc2Ny
aXB0aW9uIG9mIHRoZSB3YXRjaGxpc3QuCgoNCgUEAQICBRIErwECCAoNCgUEAQICARIErwEJ
FAoNCgUEAQICAxIErwEXGAoNCgUEAQICCBIErwEZQQoQCggEAQICCJwIABIErwEaQAqHAQoE
BAECAxIEtAECSBp5IE9wdGlvbmFsLiBXZWlnaHQgYXBwbGllZCB0byB0aGUgcmlzayBzY29y
ZSBmb3IgZW50aXRpZXMKIGluIHRoaXMgd2F0Y2hsaXN0LgogVGhlIGRlZmF1bHQgaXMgMS4w
IGlmIGl0IGlzIG5vdCBzcGVjaWZpZWQuCgoNCgUEAQIDBRIEtAECBwoNCgUEAQIDARIEtAEI
GgoNCgUEAQIDAxIEtAEdHgoNCgUEAQIDCBIEtAEfRwoQCggEAQIDCJwIABIEtAEgRgpMCgQE
AQIEEga3AQK4AS8aPCBSZXF1aXJlZC4gTWVjaGFuaXNtIHRvIHBvcHVsYXRlIGVudGl0aWVz
IGluIHRoZSB3YXRjaGxpc3QuCgoNCgUEAQIEBhIEtwECGwoNCgUEAQIEARIEtwEcNwoNCgUE
AQIEAxIEtwE6OwoNCgUEAQIECBIEuAEGLgoQCggEAQIECJwIABIEuAEHLQo7CgQEAQIFEgS7
AQJLGi0gT3V0cHV0IG9ubHkuIEVudGl0eSBjb3VudCBpbiB0aGUgd2F0Y2hsaXN0LgoKDQoF
BAECBQYSBLsBAg0KDQoFBAECBQESBLsBDhoKDQoFBAECBQMSBLsBHR4KDQoFBAECBQgSBLsB
H0oKEAoIBAECBQicCAASBLsBIEkKPgoEBAECBhIGvgECvwEyGi4gT3V0cHV0IG9ubHkuIFRp
bWUgdGhlIHdhdGNobGlzdCB3YXMgY3JlYXRlZC4KCg0KBQQBAgYGEgS+AQIbCg0KBQQBAgYB
EgS+ARwnCg0KBQQBAgYDEgS+ASorCg0KBQQBAgYIEgS/AQYxChAKCAQBAgYInAgAEgS/AQcw
CkMKBAQBAgcSBsIBAsMBMhozIE91dHB1dCBvbmx5LiBUaW1lIHRoZSB3YXRjaGxpc3Qgd2Fz
IGxhc3QgdXBkYXRlZC4KCg0KBQQBAgcGEgTCAQIbCg0KBQQBAgcBEgTCARwnCg0KBQQBAgcD
EgTCASorCg0KBQQBAgcIEgTDAQYxChAKCAQBAgcInAgAEgTDAQcwCkkKBAQBAggSBsYBAscB
Lxo5IE9wdGlvbmFsLiBVc2VyIHByZWZlcmVuY2VzIGZvciB3YXRjaGxpc3QgY29uZmlndXJh
dGlvbi4KCg0KBQQBAggGEgTGAQIaCg0KBQQBAggBEgTGARs1Cg0KBQQBAggDEgTGATg6Cg0K
BQQBAggIEgTHAQYuChAKCAQBAggInAgAEgTHAQctClAKAgQCEgbLAQDOAQEaQiBBIGNvbGxl
Y3Rpb24gb2YgdXNlciBwcmVmZXJlbmNlcyBmb3Igd2F0Y2hsaXN0IFVJIGNvbmZpZ3VyYXRp
b24uCgoLCgMEAgESBMsBCCAKSwoEBAICABIEzQECOxo9IE9wdGlvbmFsLiBXaGV0aGVyIHRo
ZSB3YXRjaGxpc3QgaXMgcGlubmVkIG9uIHRoZSBkYXNoYm9hcmQuCgoNCgUEAgIABRIEzQEC
BgoNCgUEAgIAARIEzQEHDQoNCgUEAgIAAxIEzQEQEQoNCgUEAgIACBIEzQESOgoQCggEAgIA
CJwIABIEzQETOQo4CgIEAxIG0QEA3AEBGiogUmVxdWVzdCBtZXNzYWdlIGZvciBnZXR0aW5n
IGEgd2F0Y2hsaXN0LgoKCwoDBAMBEgTRAQgbCtoBCgQEAwIAEgbWAQLbAQQayQEgUmVxdWly
ZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9uIG9mIHdhdGNobGlz
dHMuCiBUaGUgbmFtZSBvZiB0aGUgd2F0Y2hsaXN0IHRvIHJldHJpZXZlLgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2lu
c3RhbmNlfS93YXRjaGxpc3RzL3t3YXRjaGxpc3R9YAoKDQoFBAMCAAUSBNYBAggKDQoFBAMC
AAESBNYBCQ0KDQoFBAMCAAMSBNYBEBEKDwoFBAMCAAgSBtYBEtsBAwoQCggEAwIACJwIABIE
1wEEKgoRCgcEAwIACJ8IEgbYAQTaAQUKNwoCBAQSBt8BAP0BARopIFJlcXVlc3QgbWVzc2Fn
ZSBmb3IgbGlzdGluZyB3YXRjaGxpc3RzLgoKCwoDBAQBEgTfAQgdCpoBCgQEBAIAEgbiAQLn
AQQaiQEgUmVxdWlyZWQuIFRoZSBwYXJlbnQsIHdoaWNoIG93bnMgdGhpcyBjb2xsZWN0aW9u
IG9mIHdhdGNobGlzdHMuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1gCgoNCgUEBAIABRIE4gECCAoNCgUE
BAIAARIE4gEJDwoNCgUEBAIAAxIE4gESEwoPCgUEBAIACBIG4gEU5wEDChAKCAQEAgAInAgA
EgTjAQQqChEKBwQEAgAInwgSBuQBBOYBBQrzAQoEBAQCARIE7QECPxrkASBPcHRpb25hbC4g
VGhlIG1heGltdW0gbnVtYmVyIG9mIHdhdGNobGlzdHMgdG8gcmV0dXJuLgogVGhlIHNlcnZp
Y2UgbWF5IHJldHVybiBmZXdlciB0aGFuIHRoaXMgdmFsdWUuCiBJZiB1bnNwZWNpZmllZCwg
YXQgbW9zdCAyMDAgd2F0Y2hsaXN0cyB3aWxsIGJlIHJldHVybmVkLgogVGhlIG1heGltdW0g
dmFsdWUgaXMgMjAwOyB2YWx1ZXMgYWJvdmUgMjAwIHdpbGwgYmUgY29lcmNlZCB0byAyMDAu
CgoNCgUEBAIBBRIE7QECBwoNCgUEBAIBARIE7QEIEQoNCgUEBAIBAxIE7QEUFQoNCgUEBAIB
CBIE7QEWPgoQCggEBAIBCJwIABIE7QEXPQqAAgoEBAQCAhIE9QECQRrxASBPcHRpb25hbC4g
QSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RXYXRjaGxpc3Rz
YCBjYWxsLgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2Uu
CgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwog
YExpc3RXYXRjaGxpc3RzYCBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhl
IHBhZ2UKIHRva2VuLgoKDQoFBAQCAgUSBPUBAggKDQoFBAQCAgESBPUBCRMKDQoFBAQCAgMS
BPUBFhcKDQoFBAQCAggSBPUBGEAKEAoIBAQCAgicCAASBPUBGT8KmwIKBAQEAgMSBPwBAj0a
jAIgT3B0aW9uYWwuIFdoaWNoIHdhdGNobGlzdCB0byByZXR1cm4gaW4gYWlwLmRldi8xNjAg
Zm9ybS4KIEN1cnJlbnRseSwgb25seSB0aGUgZm9sbG93aW5nIGZpbHRlcnMgYXJlIHN1cHBv
cnRlZDoKIC0gYHdhdGNobGlzdF91c2VyX3ByZWZlcmVuY2VzLnBpbm5lZD10cnVlYAogLSBg
aGFzX2VudGl0eShbRU5USVRZX0lORElDQVRPUl0sW0VOVElUWV9UWVBFXSlgCiAtIGBoYXNf
ZW50aXR5KFtFTlRJVFlfSU5ESUNBVE9SXSxbRU5USVRZX1RZUEVdLFtOQU1FU1BBQ0VdKWAK
Cg0KBQQEAgMFEgT8AQIICg0KBQQEAgMBEgT8AQkPCg0KBQQEAgMDEgT8ARITCg0KBQQEAgMI
EgT8ARQ8ChAKCAQEAgMInAgAEgT8ARU7CjgKAgQFEgaAAgCHAgEaKiBSZXNwb25zZSBtZXNz
YWdlIGZvciBsaXN0aW5nIHdhdGNobGlzdHMuCgoLCgMEBQESBIACCB4KRQoEBAUCABIEggIC
TRo3IE9wdGlvbmFsLiBUaGUgd2F0Y2hsaXN0cyBmcm9tIHRoZSBzcGVjaWZpZWQgaW5zdGFu
Y2UuCgoNCgUEBQIABBIEggICCgoNCgUEBQIABhIEggILFAoNCgUEBQIAARIEggIVHwoNCgUE
BQIAAxIEggIiIwoNCgUEBQIACBIEggIkTAoQCggEBQIACJwIABIEggIlSwqaAQoEBAUCARIE
hgICRhqLASBPcHRpb25hbC4gQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2Vf
dG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0CiBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9t
aXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAUCAQUSBIYCAggK
DQoFBAUCAQESBIYCCRgKDQoFBAUCAQMSBIYCGxwKDQoFBAUCAQgSBIYCHUUKEAoIBAUCAQic
CAASBIYCHkQKNwoCBAYSBooCAJ0CARopIFJlcXVlc3QgbWVzc2FnZSBmb3IgY3JlYXRpbmcg
d2F0Y2hsaXN0LgoKCwoDBAYBEgSKAggeCp4BCgQEBgIAEgaNAgKSAgQajQEgUmVxdWlyZWQu
IFRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hlcmUgdGhpcyB3YXRjaGxpc3Qgd2lsbCBiZSBjcmVh
dGVkLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2luc3RhbmNlcy97aW5zdGFuY2V9YAoKDQoFBAYCAAUSBI0CAggKDQoFBAYCAAESBI0CCQ8K
DQoFBAYCAAMSBI0CEhMKDwoFBAYCAAgSBo0CFJICAwoQCggEBgIACJwIABIEjgIEKgoRCgcE
BgIACJ8IEgaPAgSRAgUK1QEKBAQGAgESBJkCAkMaxgEgT3B0aW9uYWwuIFRoZSBJRCB0byB1
c2UgZm9yIHRoZSB3YXRjaGxpc3QsCiB3aGljaCB3aWxsIGJlY29tZSB0aGUgZmluYWwgY29t
cG9uZW50IG9mIHRoZSB3YXRjaGxpc3QncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUg
c2hvdWxkIGJlIDQtNjMgY2hhcmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMKIGFyZSAv
W2Etel1bMC05XS0vLgoKDQoFBAYCAQUSBJkCAggKDQoFBAYCAQESBJkCCRUKDQoFBAYCAQMS
BJkCGBkKDQoFBAYCAQgSBJkCGkIKEAoIBAYCAQicCAASBJkCG0EKMgoEBAYCAhIEnAICQxok
IFJlcXVpcmVkLiBUaGUgd2F0Y2hsaXN0IHRvIGNyZWF0ZS4KCg0KBQQGAgIGEgScAgILCg0K
BQQGAgIBEgScAgwVCg0KBQQGAgIDEgScAhgZCg0KBQQGAgIIEgScAhpCChAKCAQGAgIInAgA
EgScAhtBCjcKAgQHEgagAgCrAgEaKSBSZXF1ZXN0IG1lc3NhZ2UgZm9yIHVwZGF0aW5nIHdh
dGNobGlzdC4KCgsKAwQHARIEoAIIHgrfAQoEBAcCABIEpgICQxrQASBSZXF1aXJlZC4gVGhl
IHdhdGNobGlzdCB0byB1cGRhdGUuCgogVGhlIHdhdGNobGlzdCdzIGBuYW1lYCBmaWVsZCBp
cyB1c2VkIHRvIGlkZW50aWZ5IHRoZSB3YXRjaGxpc3QgdG8gdXBkYXRlLgogRm9ybWF0Ogog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9pbnN0YW5jZXMve2lu
c3RhbmNlfS93YXRjaGxpc3RzL3t3YXRjaGxpc3R9YAoKDQoFBAcCAAYSBKYCAgsKDQoFBAcC
AAESBKYCDBUKDQoFBAcCAAMSBKYCGBkKDQoFBAcCAAgSBKYCGkIKEAoIBAcCAAicCAASBKYC
G0EKOQoEBAcCARIGqQICqgIvGikgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1
cGRhdGUuCgoNCgUEBwIBBhIEqQICGwoNCgUEBwIBARIEqQIcJwoNCgUEBwIBAxIEqQIqKwoN
CgUEBwIBCBIEqgIGLgoQCggEBwIBCJwIABIEqgIHLQo3CgIECBIGrgIAvQIBGikgUmVxdWVz
dCBtZXNzYWdlIGZvciBkZWxldGluZyB3YXRjaGxpc3QuCgoLCgMECAESBK4CCB4KoQEKBAQI
AgASBrICArcCBBqQASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHdhdGNobGlzdCB0byBk
ZWxldGUuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2luc3RhbmNlcy97aW5zdGFuY2V9L3dhdGNobGlzdHMve3dhdGNobGlzdH1gCgoNCgUE
CAIABRIEsgICCAoNCgUECAIAARIEsgIJDQoNCgUECAIAAxIEsgIQEQoPCgUECAIACBIGsgIS
twIDChAKCAQIAgAInAgAEgSzAgQqChEKBwQIAgAInwgSBrQCBLYCBQquAQoEBAgCARIEvAIC
OhqfASBPcHRpb25hbC4gSWYgc2V0IHRvIHRydWUsIGFueSBlbnRpdGllcyB1bmRlciB0aGlz
IHdhdGNobGlzdCB3aWxsIGFsc28gYmUKIGRlbGV0ZWQuIChPdGhlcndpc2UsIHRoZSByZXF1
ZXN0IHdpbGwgb25seSB3b3JrIGlmIHRoZSB3YXRjaGxpc3QgaGFzIG5vCiBlbnRpdGllcy4p
CgoNCgUECAIBBRIEvAICBgoNCgUECAIBARIEvAIHDAoNCgUECAIBAxIEvAIPEAoNCgUECAIB
CBIEvAIROQoQCggECAIBCJwIABIEvAISOGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::Entity::Entity ===
    # Fields for Entity
    # Field: name Type: 9 ()
    # Field: metadata Type: 11 (.google.backstory.EntityMetadata)
    # Field: entity Type: 11 (.google.backstory.Noun)
    # Field: additional Type: 11 (.google.protobuf.Struct)
    # Field: risk_score Type: 11 (.google.backstory.EntityRisk)
    # Field: metric Type: 11 (.google.backstory.Metric)
    # Field: relations Type: 11 (.google.backstory.Relation)

# === Message: Google::Cloud::Chronicle::V1::Entity::Watchlist ===
    # Fields for Watchlist
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: multiplying_factor Type: 2 ()
    # Field: entity_population_mechanism Type: 11 (.google.cloud.chronicle.v1.Watchlist.EntityPopulationMechanism)
    # Field: entity_count Type: 11 (.google.cloud.chronicle.v1.Watchlist.EntityCount)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: watchlist_user_preferences Type: 11 (.google.cloud.chronicle.v1.WatchlistUserPreferences)

# === Message: Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences ===
    # Fields for WatchlistUserPreferences
    # Field: pinned Type: 8 ()

# === Message: Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest ===
    # Fields for GetWatchlistRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest ===
    # Fields for ListWatchlistsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse ===
    # Fields for ListWatchlistsResponse
    # Field: watchlists Type: 11 (.google.cloud.chronicle.v1.Watchlist)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest ===
    # Fields for CreateWatchlistRequest
    # Field: parent Type: 9 ()
    # Field: watchlist_id Type: 9 ()
    # Field: watchlist Type: 11 (.google.cloud.chronicle.v1.Watchlist)

# === Message: Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest ===
    # Fields for UpdateWatchlistRequest
    # Field: watchlist Type: 11 (.google.cloud.chronicle.v1.Watchlist)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest ===
    # Fields for DeleteWatchlistRequest
    # Field: name Type: 9 ()
    # Field: force Type: 8 ()

# === Service Client: Google::Cloud::Chronicle::V1::Entity::EntityServiceClient ===
package Google::Cloud::Chronicle::V1::Entity::EntityServiceClient;

=pod

=head2 Service Client: Google::Cloud::Chronicle::V1::Entity::EntityServiceClient

Client stub representing the remote C<EntityService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<chronicle.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'chronicle.googleapis.com:443' );

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

sub get_watchlist {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'GetWatchlist',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::Entity::Watchlist',
    });
}

sub list_watchlists {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'ListWatchlists',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse',
    });
}

sub create_watchlist {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'CreateWatchlist',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::Entity::Watchlist',
    });
}

sub update_watchlist {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'UpdateWatchlist',
        request        => $req,
        response_class => 'Google::Cloud::Chronicle::V1::Entity::Watchlist',
    });
}

sub delete_watchlist {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'DeleteWatchlist',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::Entity - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/entity.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::Entity;

    my $msg = Google::Cloud::Chronicle::V1::Entity::Entity->new({
        name => $name,
        metadata => $metadata,
        entity => $entity,
        additional => $additional,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::Entity::Entity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/entity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::Entity::Entity

An Entity provides additional context about an entity in a UDM event (asset,
user, etc.). For example, a PROCESS_LAUNCH event describes that user
'abc@example.corp' launched process 'shady.exe'. The event does not include
information that user 'abc@example.com' is a recently terminated employee who
administers a server storing finance data. Information stored in one or more
Entities can add this additional context.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the entity.
Format:
`projects/{project}/locations/{location}/instances/{instance}/entities/{entity}`
`projects/{project}/locations/{location}/instances/{instance}/analytics/{analytic}/entities/{entity}`
`projects/{project}/locations/{location}/instances/{instance}/watchlists/{watchlist}/entities/{entity}`

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Backstory::Entity::EntityMetadata>)

Entity metadata such as timestamp, product, etc.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<Message> (L<Google::Backstory::Udm::Noun>)

Noun in the UDM event that this entity represents.

=item * C<< $msg->additional() >> / C<< $msg->additional($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Important entity data that cannot be adequately represented within
the formal sections of the Entity.

=item * C<< $msg->risk_score() >> / C<< $msg->risk_score($value) >>

Type: C<Message> (L<Google::Backstory::EntityRisk::EntityRisk>)

Represents the entity risk scores resource

=item * C<< $msg->metric() >> / C<< $msg->metric($value) >>

Type: C<Message> (L<Google::Backstory::Entity::Metric>)

Metric details of the entity. Used if EntityType is METRIC.

=item * C<< $msg->relations() >> / C<< $msg->relations($value) >>

Type: C<Message> (L<Google::Backstory::Entity::Relation>)

One or more relationships between the entity (a) and other entities,
including the relationship type and related entity.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::Watchlist

A watchlist is a list of entities that allows for bulk operations over the
included entities.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the watchlist.
Format:
`projects/{project}/locations/{location}/instances/{instance}/watchlists/{watchlist}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. Display name of the watchlist.
Note that it must be at least one character and less than 63 characters
(https://google.aip.dev/148).

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the watchlist.

=item * C<< $msg->multiplying_factor() >> / C<< $msg->multiplying_factor($value) >>

Type: C<Float>

Optional. Weight applied to the risk score for entities
in this watchlist.
The default is 1.0 if it is not specified.

=item * C<< $msg->entity_population_mechanism() >> / C<< $msg->entity_population_mechanism($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityPopulationMechanism>)

Required. Mechanism to populate entities in the watchlist.

=item * C<< $msg->entity_count() >> / C<< $msg->entity_count($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::Watchlist::EntityCount>)

Output only. Entity count in the watchlist.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the watchlist was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the watchlist was last updated.

=item * C<< $msg->watchlist_user_preferences() >> / C<< $msg->watchlist_user_preferences($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences>)

Optional. User preferences for watchlist configuration.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::WatchlistUserPreferences

A collection of user preferences for watchlist UI configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pinned() >> / C<< $msg->pinned($value) >>

Type: C<Bool>

Optional. Whether the watchlist is pinned on the dashboard.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest

Request message for getting a watchlist.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The parent, which owns this collection of watchlists.
The name of the watchlist to retrieve.
Format:
`projects/{project}/locations/{location}/instances/{instance}/watchlists/{watchlist}`

=back

=head2 Google::Cloud::Chronicle::V1::Entity::ListWatchlistsRequest

Request message for listing watchlists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent, which owns this collection of watchlists.
Format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of watchlists to return.
The service may return fewer than this value.
If unspecified, at most 200 watchlists will be returned.
The maximum value is 200; values above 200 will be coerced to 200.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListWatchlists` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
`ListWatchlists` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Which watchlist to return in aip.dev/160 form.
Currently, only the following filters are supported:
- `watchlist_user_preferences.pinned=true`
- `has_entity([ENTITY_INDICATOR],[ENTITY_TYPE])`
- `has_entity([ENTITY_INDICATOR],[ENTITY_TYPE],[NAMESPACE])`

=back

=head2 Google::Cloud::Chronicle::V1::Entity::ListWatchlistsResponse

Response message for listing watchlists.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->watchlists() >> / C<< $msg->watchlists($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::Watchlist>)

Optional. The watchlists from the specified instance.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Optional. A token, which can be sent as `page_token` to retrieve the next
page. If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::CreateWatchlistRequest

Request message for creating watchlist.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this watchlist will be created.
Format: `projects/{project}/locations/{location}/instances/{instance}`

=item * C<< $msg->watchlist_id() >> / C<< $msg->watchlist_id($value) >>

Type: C<String>

Optional. The ID to use for the watchlist,
which will become the final component of the watchlist's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-/.

=item * C<< $msg->watchlist() >> / C<< $msg->watchlist($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::Watchlist>)

Required. The watchlist to create.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::UpdateWatchlistRequest

Request message for updating watchlist.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->watchlist() >> / C<< $msg->watchlist($value) >>

Type: C<Message> (L<Google::Cloud::Chronicle::V1::Entity::Watchlist>)

Required. The watchlist to update.

The watchlist's `name` field is used to identify the watchlist to update.
Format:
`projects/{project}/locations/{location}/instances/{instance}/watchlists/{watchlist}`

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Chronicle::V1::Entity::DeleteWatchlistRequest

Request message for deleting watchlist.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the watchlist to delete.
Format:
`projects/{project}/locations/{location}/instances/{instance}/watchlists/{watchlist}`

=item * C<< $msg->force() >> / C<< $msg->force($value) >>

Type: C<Bool>

Optional. If set to true, any entities under this watchlist will also be
deleted. (Otherwise, the request will only work if the watchlist has no
entities.)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::Entity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
