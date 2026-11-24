package Google::Cloud::Discoveryengine::V1::DataStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1::DataStore };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2RhdGFfc3RvcmVfc2VydmljZS5w
cm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMGdvb2dsZS9j
bG91ZC9kaXNjb3ZlcnllbmdpbmUvdjEvZGF0YV9zdG9yZS5wcm90bxoeZ29vZ2xlL2lhbS92
MS9pYW1fcG9saWN5LnByb3RvGhpnb29nbGUvaWFtL3YxL3BvbGljeS5wcm90bxojZ29vZ2xl
L2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5w
cm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8i7QMKFkNyZWF0ZURhdGFTdG9yZVJlcXVlc3QSWgoQY21la19j
b25maWdfbmFtZRgFIAEoCUIu+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
Q21la0NvbmZpZ0gAUg5jbWVrQ29uZmlnTmFtZRIjCgxkaXNhYmxlX2NtZWsYBiABKAhIAFIL
ZGlzYWJsZUNtZWsSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWRpc2NvdmVyeWVuZ2luZS5n
b29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSTgoKZGF0YV9zdG9yZRgCIAEoCzIq
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlQgPgQQJSCWRhdGFT
dG9yZRInCg1kYXRhX3N0b3JlX2lkGAMgASgJQgPgQQJSC2RhdGFTdG9yZUlkEj0KG2NyZWF0
ZV9hZHZhbmNlZF9zaXRlX3NlYXJjaBgEIAEoCFIYY3JlYXRlQWR2YW5jZWRTaXRlU2VhcmNo
Ej8KHHNraXBfZGVmYXVsdF9zY2hlbWFfY3JlYXRpb24YByABKAhSGXNraXBEZWZhdWx0U2No
ZW1hQ3JlYXRpb25CDgoMY21la19vcHRpb25zIlsKE0dldERhdGFTdG9yZVJlcXVlc3QSRAoE
bmFtZRgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vRGF0
YVN0b3JlUgRuYW1lIpMBChdDcmVhdGVEYXRhU3RvcmVNZXRhZGF0YRI7CgtjcmVhdGVfdGlt
ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBk
YXRlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1l
IrYBChVMaXN0RGF0YVN0b3Jlc1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWRp
c2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSGwoJcGFn
ZV9zaXplGAIgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4S
FgoGZmlsdGVyGAQgASgJUgZmaWx0ZXIijQEKFkxpc3REYXRhU3RvcmVzUmVzcG9uc2USSwoL
ZGF0YV9zdG9yZXMYASADKAsyKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRh
dGFTdG9yZVIKZGF0YVN0b3JlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4iXgoWRGVsZXRlRGF0YVN0b3JlUmVxdWVzdBJECgRuYW1lGAEgASgJQjDgQQL6QSoK
KGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9EYXRhU3RvcmVSBG5hbWUipQEKFlVw
ZGF0ZURhdGFTdG9yZVJlcXVlc3QSTgoKZGF0YV9zdG9yZRgBIAEoCzIqLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlQgPgQQJSCWRhdGFTdG9yZRI7Cgt1cGRh
dGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCnVwZGF0ZU1hc2si
kwEKF0RlbGV0ZURhdGFTdG9yZU1ldGFkYXRhEjsKC2NyZWF0ZV90aW1lGAEgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgCIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUyzhEKEERhdGFTdG9y
ZVNlcnZpY2UShAMKD0NyZWF0ZURhdGFTdG9yZRI3Lmdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuQ3JlYXRlRGF0YVN0b3JlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24imAKC0+STAogBIi4vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
fS9kYXRhU3RvcmVzOgpkYXRhX3N0b3JlWkoiPC92MS97cGFyZW50PXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKn0vZGF0YVN0b3JlczoKZGF0YV9zdG9yZdpBH3BhcmVu
dCxkYXRhX3N0b3JlLGRhdGFfc3RvcmVfaWTKQWQKKWdvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuRGF0YVN0b3JlEjdnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNy
ZWF0ZURhdGFTdG9yZU1ldGFkYXRhEu8BCgxHZXREYXRhU3RvcmUSNC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkdldERhdGFTdG9yZVJlcXVlc3QaKi5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZSJ9gtPkkwJwEi4vdjEve25hbWU9cHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9Wj4SPC92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfdpBBG5hbWUSggIKDkxp
c3REYXRhU3RvcmVzEjYuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0RGF0
YVN0b3Jlc1JlcXVlc3QaNy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3RE
YXRhU3RvcmVzUmVzcG9uc2Uif4LT5JMCcBIuL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKn0vZGF0YVN0b3Jlc1o+EjwvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9u
cy8qL2NvbGxlY3Rpb25zLyp9L2RhdGFTdG9yZXPaQQZwYXJlbnQSvAIKD0RlbGV0ZURhdGFT
dG9yZRI3Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGVsZXRlRGF0YVN0b3Jl
UmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i0AGC0+STAnAqLi92MS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn1aPio8L3YxL3tuYW1l
PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp92kEE
bmFtZcpBUAoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ejdnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkRlbGV0ZURhdGFTdG9yZU1ldGFkYXRhErcCCg9VcGRhdGVEYXRhU3RvcmUS
Ny5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLlVwZGF0ZURhdGFTdG9yZVJlcXVl
c3QaKi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZSK+AYLT5JMC
ngEyOS92MS97ZGF0YV9zdG9yZS5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovZGF0YVN0
b3Jlcy8qfToKZGF0YV9zdG9yZVpVMkcvdjEve2RhdGFfc3RvcmUubmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfToKZGF0YV9zdG9yZdpB
FmRhdGFfc3RvcmUsdXBkYXRlX21hc2sS8AEKDEdldElhbVBvbGljeRIiLmdvb2dsZS5pYW0u
djEuR2V0SWFtUG9saWN5UmVxdWVzdBoVLmdvb2dsZS5pYW0udjEuUG9saWN5IqQBgtPkkwKS
ARJNL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyov
ZGF0YVN0b3Jlcy8qfTpnZXRJYW1Qb2xpY3laQRI/L3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn06Z2V0SWFtUG9saWN52kEIcmVzb3VyY2US/QEK
DFNldElhbVBvbGljeRIiLmdvb2dsZS5pYW0udjEuU2V0SWFtUG9saWN5UmVxdWVzdBoVLmdv
b2dsZS5pYW0udjEuUG9saWN5IrEBgtPkkwKYASJNL3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyovZGF0YVN0b3Jlcy8qfTpzZXRJYW1Qb2xpY3k6
ASpaRCI/L3YxL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMv
Kn06c2V0SWFtUG9saWN5OgEq2kEPcmVzb3VyY2UscG9saWN5Gs8BykEeZGlzY292ZXJ5ZW5n
aW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgv
Y2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9kaXNjb3Zl
cnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlz
Y292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQogCCiNjb20uZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MUIVRGF0YVN0b3JlU2VydmljZVByb3RvUAFaTWNsb3VkLmdvb2ds
ZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2Nv
dmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIfR29vZ2xlLkNsb3VkLkRpc2NvdmVy
eUVuZ2luZS5WMcoCH0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjHqAiJHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxSqpaCgcSBQ4A9AIBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJ
CgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAOgoJCgIDBRIDFwAoCgkKAgMGEgMYACQK
CQoCAwcSAxkALQoJCgIDCBIDGgAlCgkKAgMJEgMbACoKCQoCAwoSAxwAKQoICgEIEgMeADwK
CQoCCCUSAx4APAoICgEIEgMfAGQKCQoCCAsSAx8AZAoICgEIEgMgACIKCQoCCAoSAyAAIgoI
CgEIEgMhADYKCQoCCAgSAyEANgoICgEIEgMiADwKCQoCCAESAyIAPAoICgEIEgMjAC0KCQoC
CCQSAyMALQoICgEIEgMkADwKCQoCCCkSAyQAPAoICgEIEgMlADsKCQoCCC0SAyUAOwpqCgIG
ABIFKQCkAQEaXSBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbRGF0YVN0b3JlXVtnb29nbGUuY2xv
dWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0KIGNvbmZpZ3VyYXRpb24uCgoKCgMG
AAESAykIGAoKCgMGAAMSAyoCRgoMCgUGAAOZCBIDKgJGCgsKAwYAAxIEKwIuSgoNCgUGAAOa
CBIEKwIuSgq9AgoEBgACABIENwJGAxquAiBDcmVhdGVzIGEgW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdLgoKIERhdGFTdG9yZSBpcyBm
b3Igc3RvcmluZwogW0RvY3VtZW50c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5Eb2N1bWVudF0uIFRvIHNlcnZlIHRoZXNlCiBkb2N1bWVudHMgZm9yIFNlYXJjaCwgb3Ig
UmVjb21tZW5kYXRpb24gdXNlIGNhc2UsIGFuCiBbRW5naW5lXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxLkVuZ2luZV0gbmVlZHMgdG8gYmUgY3JlYXRlZAogc2VwYXJhdGVs
eS4KCgwKBQYAAgABEgM3BhUKDAoFBgACAAISAzcWLAoMCgUGAAIAAxIDOA8rCg0KBQYAAgAE
EgQ5BEAGChEKCQYAAgAEsMq8IhIEOQRABgoMCgUGAAIABBIDQQRNCg8KCAYAAgAEmwgAEgNB
BE0KDQoFBgACAAQSBEIERQYKDwoHBgACAASZCBIEQgRFBgpOCgQGAAIBEgRJAlEDGkAgR2V0
cyBhIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0
b3JlXS4KCgwKBQYAAgEBEgNJBhIKDAoFBgACAQISA0kTJgoMCgUGAAIBAxIDSTE6Cg0KBQYA
AgEEEgRKBE8GChEKCQYAAgEEsMq8IhIESgRPBgoMCgUGAAIBBBIDUAQyCg8KCAYAAgEEmwgA
EgNQBDIKcwoEBgACAhIEVQJdAxplIExpc3RzIGFsbCB0aGUgW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdcwogYXNzb2NpYXRlZCB3aXRo
IHRoZSBwcm9qZWN0LgoKDAoFBgACAgESA1UGFAoMCgUGAAICAhIDVRUqCgwKBQYAAgIDEgNV
NUsKDQoFBgACAgQSBFYEWwYKEQoJBgACAgSwyrwiEgRWBFsGCgwKBQYAAgIEEgNcBDQKDwoI
BgACAgSbCAASA1wENApRCgQGAAIDEgRgAm0DGkMgRGVsZXRlcyBhIFtEYXRhU3RvcmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlXS4KCgwKBQYAAgMBEgNg
BhUKDAoFBgACAwISA2AWLAoMCgUGAAIDAxIDYQ8rCg0KBQYAAgMEEgRiBGcGChEKCQYAAgME
sMq8IhIEYgRnBgoMCgUGAAIDBBIDaAQyCg8KCAYAAgMEmwgAEgNoBDIKDQoFBgACAwQSBGkE
bAYKDwoHBgACAwSZCBIEaQRsBgpQCgQGAAIEEgRwAnoDGkIgVXBkYXRlcyBhIFtEYXRhU3Rv
cmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlXQoKDAoFBgAC
BAESA3AGFQoMCgUGAAIEAhIDcBYsCgwKBQYAAgQDEgNwN0AKDQoFBgACBAQSBHEEeAYKEQoJ
BgACBASwyrwiEgRxBHgGCgwKBQYAAgQEEgN5BEQKDwoIBgACBASbCAASA3kERAqPAgoEBgAC
BRIGgAECiQEDGv4BIEdldHMgdGhlIElBTSBhY2Nlc3MgY29udHJvbCBwb2xpY3kgZm9yIGEK
IFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3Jl
XS4gQSBgTk9UX0ZPVU5EYCBlcnJvcgogaXMgcmV0dXJuZWQgaWYgdGhlIHJlc291cmNlIGRv
ZXMgbm90IGV4aXN0LiBBbiBlbXB0eSBwb2xpY3kgaXMgcmV0dXJuZWQgaWYKIHRoZSByZXNv
dXJjZSBleGlzdHMgYnV0IGRvZXMgbm90IGhhdmUgYSBwb2xpY3kgc2V0IG9uIGl0LgoKDQoF
BgACBQESBIABBhIKDQoFBgACBQISBIABEzQKDQoFBgACBQMSBIEBDyMKDwoFBgACBQQSBoIB
BIcBBgoTCgkGAAIFBLDKvCISBoIBBIcBBgoNCgUGAAIFBBIEiAEENgoQCggGAAIFBJsIABIE
iAEENgrQBAoEBgACBhIGmAECowEDGr8EIFNldHMgdGhlIElBTSBhY2Nlc3MgY29udHJvbCBw
b2xpY3kgZm9yIGEKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRGF0YVN0b3JlXS4gQSBgTk9UX0ZPVU5EYCBlcnJvcgogaXMgcmV0dXJuZWQgaWYgdGhl
IHJlc291cmNlIGRvZXMgbm90IGV4aXN0LgoKICoqSW1wb3J0YW50OioqIFdoZW4gc2V0dGlu
ZyBhIHBvbGljeSBkaXJlY3RseSBvbiBhIERhdGFTdG9yZSByZXNvdXJjZSwKIHRoZSBvbmx5
IHJlY29tbWVuZGVkIHJvbGVzIGluIHRoZSBiaW5kaW5ncyBhcmU6CiBgcm9sZXMvZGlzY292
ZXJ5ZW5naW5lLmFkbWluYAogYHJvbGVzL2Rpc2NvdmVyeWVuZ2luZS5hZ2VudHNwYWNlQWRt
aW5gCiBgcm9sZXMvZGlzY292ZXJ5ZW5naW5lLnZpZXdlcmAKIGByb2xlcy9kaXNjb3Zlcnll
bmdpbmUuYWdlbnRzcGFjZVZpZXdlcmAKIGByb2xlcy9kaXNjb3ZlcnllbmdpbmUudXNlcmAK
IGByb2xlcy9kaXNjb3ZlcnllbmdpbmUuYWdlbnRzcGFjZVVzZXJgCiBBdHRlbXB0aW5nIHRv
IGdyYW50IGFueSBvdGhlciByb2xlIHdpbGwgcmVzdWx0IGluIGEgd2FybmluZyBpbiBsb2dn
aW5nLgoKDQoFBgACBgESBJgBBhIKDQoFBgACBgISBJgBEzQKDQoFBgACBgMSBJkBDyMKDwoF
BgACBgQSBpoBBKEBBgoTCgkGAAIGBLDKvCISBpoBBKEBBgoNCgUGAAIGBBIEogEEPQoQCggG
AAIGBJsIABIEogEEPQqKAQoCBAASBqkBAN8BARp8IFJlcXVlc3QgZm9yCiBbRGF0YVN0b3Jl
U2VydmljZS5DcmVhdGVEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRGF0YVN0b3JlU2VydmljZS5DcmVhdGVEYXRhU3RvcmVdCiBtZXRob2QuCgoLCgMEAAES
BKkBCB4KiQEKBAQACAASBqwBArYBAxp5IENNRUsgb3B0aW9ucyBmb3IgdGhlIERhdGFTdG9y
ZS4gU2V0dGluZyB0aGlzIGZpZWxkIHdpbGwgb3ZlcnJpZGUgdGhlCiBkZWZhdWx0IENtZWtD
b25maWcgaWYgb25lIGlzIHNldCBmb3IgdGhlIHByb2plY3QuCgoNCgUEAAgAARIErAEIFApX
CgQEAAIAEgauAQSwAQcaRyBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDbWVrQ29uZmlnIHRvIHVz
ZSBmb3IgcHJvdGVjdGluZyB0aGlzIERhdGFTdG9yZS4KCg0KBQQAAgAFEgSuAQQKCg0KBQQA
AgABEgSuAQsbCg0KBQQAAgADEgSuAR4fCg8KBQQAAgAIEgauASCwAQYKEQoHBAACAAifCBIG
rgEhsAEFCqcBCgQEAAIBEgS1AQQaGpgBIERhdGFTdG9yZSB3aXRob3V0IENNRUsgcHJvdGVj
dGlvbnMuIElmIGEgZGVmYXVsdCBDbWVrQ29uZmlnIGlzIHNldCBmb3IKIHRoZSBwcm9qZWN0
LCBzZXR0aW5nIHRoaXMgZmllbGQgd2lsbCBvdmVycmlkZSB0aGUgZGVmYXVsdCBDbWVrQ29u
ZmlnIGFzCiB3ZWxsLgoKDQoFBAACAQUSBLUBBAgKDQoFBAACAQESBLUBCRUKDQoFBAACAQMS
BLUBGBkKggEKBAQAAgISBroBAr8BBBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
IG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY29sbGVjdGlvbnMve2NvbGxlY3Rpb259YC4KCg0KBQQAAgIFEgS6AQIICg0KBQQAAgIB
EgS6AQkPCg0KBQQAAgIDEgS6ARITCg8KBQQAAgIIEga6ARS/AQMKEAoIBAACAgicCAASBLsB
BCoKEQoHBAACAgifCBIGvAEEvgEFCmAKBAQAAgMSBMMBAkQaUiBSZXF1aXJlZC4gVGhlIFtE
YXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlXSB0
bwogY3JlYXRlLgoKDQoFBAACAwYSBMMBAgsKDQoFBAACAwESBMMBDBYKDQoFBAACAwMSBMMB
GRoKDQoFBAACAwgSBMMBG0MKEAoIBAACAwicCAASBMMBHEIKkAMKBAQAAgQSBM0BAkQagQMg
UmVxdWlyZWQuIFRoZSBJRCB0byB1c2UgZm9yIHRoZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdLCB3aGljaCB3aWxsIGJlY29tZQog
dGhlIGZpbmFsIGNvbXBvbmVudCBvZiB0aGUKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlXSdzIHJlc291cmNlIG5hbWUuCgogVGhpcyBm
aWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmlldGYub3Jn
L2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGggbGltaXQgb2YgNjMgY2hh
cmFjdGVycy4gT3RoZXJ3aXNlLCBhbgogSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1
cm5lZC4KCg0KBQQAAgQFEgTNAQIICg0KBQQAAgQBEgTNAQkWCg0KBQQAAgQDEgTNARkaCg0K
BQQAAgQIEgTNARtDChAKCAQAAgQInAgAEgTNARxCCv8BCgQEAAIFEgTUAQInGvABIEEgYm9v
bGVhbiBmbGFnIGluZGljYXRpbmcgd2hldGhlciB1c2VyIHdhbnQgdG8gZGlyZWN0bHkgY3Jl
YXRlIGFuIGFkdmFuY2VkCiBkYXRhIHN0b3JlIGZvciBzaXRlIHNlYXJjaC4KIElmIHRoZSBk
YXRhIHN0b3JlIGlzIG5vdCBjb25maWd1cmVkIGFzIHNpdGUKIHNlYXJjaCAoR0VORVJJQyB2
ZXJ0aWNhbCBhbmQgUFVCTElDX1dFQlNJVEUgY29udGVudF9jb25maWcpLCB0aGlzIGZsYWcg
d2lsbAogYmUgaWdub3JlZC4KCg0KBQQAAgUFEgTUAQIGCg0KBQQAAgUBEgTUAQciCg0KBQQA
AgUDEgTUASUmCo0DCgQEAAIGEgTeAQIoGv4CIEEgYm9vbGVhbiBmbGFnIGluZGljYXRpbmcg
d2hldGhlciB0byBza2lwIHRoZSBkZWZhdWx0IHNjaGVtYSBjcmVhdGlvbiBmb3IKIHRoZSBk
YXRhIHN0b3JlLiBPbmx5IGVuYWJsZSB0aGlzIGZsYWcgaWYgeW91IGFyZSBjZXJ0YWluIHRo
YXQgdGhlIGRlZmF1bHQKIHNjaGVtYSBpcyBpbmNvbXBhdGlibGUgd2l0aCB5b3VyIHVzZSBj
YXNlLgoKIElmIHNldCB0byB0cnVlLCB5b3UgbXVzdCBtYW51YWxseSBjcmVhdGUgYSBzY2hl
bWEgZm9yIHRoZSBkYXRhIHN0b3JlIGJlZm9yZQogYW55IGRvY3VtZW50cyBjYW4gYmUgaW5n
ZXN0ZWQuCgogVGhpcyBmbGFnIGNhbm5vdCBiZSBzcGVjaWZpZWQgaWYgYGRhdGFfc3RvcmUu
c3RhcnRpbmdfc2NoZW1hYCBpcyBzcGVjaWZpZWQuCgoNCgUEAAIGBRIE3gECBgoNCgUEAAIG
ARIE3gEHIwoNCgUEAAIGAxIE3gEmJwqMAQoCBAESBuQBAPUBARp+IFJlcXVlc3QgbWVzc2Fn
ZSBmb3IKIFtEYXRhU3RvcmVTZXJ2aWNlLkdldERhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVTZXJ2aWNlLkdldERhdGFTdG9yZV0KIG1ldGhv
ZC4KCgsKAwQBARIE5AEIGwqQBAoEBAECABIG7wEC9AEEGv8DIFJlcXVpcmVkLiBGdWxsIHJl
c291cmNlIG5hbWUgb2YKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnllbmdp
bmUudjEuRGF0YVN0b3JlXSwgc3VjaCBhcwogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9pZH0vZGF0YVN0b3Jlcy97
ZGF0YV9zdG9yZV9pZH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNz
aW9uIHRvIGFjY2VzcyB0aGUKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuRGF0YVN0b3JlXSwgcmVnYXJkbGVzcyBvZgogd2hldGhlciBvciBub3QgaXQg
ZXhpc3RzLCBhIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElmIHRo
ZSByZXF1ZXN0ZWQgW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5EYXRhU3RvcmVdCiBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0
dXJuZWQuCgoNCgUEAQIABRIE7wECCAoNCgUEAQIAARIE7wEJDQoNCgUEAQIAAxIE7wEQEQoP
CgUEAQIACBIG7wES9AEDChAKCAQBAgAInAgAEgTwAQQqChEKBwQBAgAInwgSBvEBBPMBBQr1
AQoCBAISBvsBAIICARrmASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0
aGUKIFtEYXRhU3RvcmVTZXJ2aWNlLkNyZWF0ZURhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVTZXJ2aWNlLkNyZWF0ZURhdGFTdG9yZV0KIG9w
ZXJhdGlvbi4gVGhpcyB3aWxsIGJlIHJldHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5p
bmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVsZC4KCgsKAwQCARIE+wEIHwomCgQEAgIAEgT9
AQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1lLgoKDQoFBAICAAYSBP0BAhsKDQoFBAICAAES
BP0BHCcKDQoFBAICAAMSBP0BKisKZAoEBAICARIEgQICLBpWIE9wZXJhdGlvbiBsYXN0IHVw
ZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUK
IGZpbmlzaCB0aW1lLgoKDQoFBAICAQYSBIECAhsKDQoFBAICAQESBIECHCcKDQoFBAICAQMS
BIECKisKkQEKAgQDEgaHAgCsAgEaggEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFTdG9y
ZVNlcnZpY2UuTGlzdERhdGFTdG9yZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djEuRGF0YVN0b3JlU2VydmljZS5MaXN0RGF0YVN0b3Jlc10KIG1ldGhvZC4KCgsKAwQDARIE
hwIIHQrqAgoEBAMCABIGjwIClAIEGtkCIFJlcXVpcmVkLiBUaGUgcGFyZW50IGJyYW5jaCBy
ZXNvdXJjZSBuYW1lLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfWAuCgogSWYgdGhlIGNhbGxl
ciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gbGlzdAogW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdcyB1bmRlciB0aGlzCiBsb2Nh
dGlvbiwgcmVnYXJkbGVzcyBvZiB3aGV0aGVyIG9yIG5vdCB0aGlzIGRhdGEgc3RvcmUgZXhp
c3RzLCBhCiBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQDAgAF
EgSPAgIICg0KBQQDAgABEgSPAgkPCg0KBQQDAgADEgSPAhITCg8KBQQDAgAIEgaPAhSUAgMK
EAoIBAMCAAicCAASBJACBCoKEQoHBAMCAAifCBIGkQIEkwIFCo0CCgQEAwIBEgSbAgIWGv4B
IE1heGltdW0gbnVtYmVyIG9mIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3Zlcnll
bmdpbmUudjEuRGF0YVN0b3JlXXMKIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1
bHRzIHRvIDEwLiBUaGUgbWF4aW11bSBhbGxvd2VkIHZhbHVlIGlzIDUwLgogVmFsdWVzIGFi
b3ZlIDUwIHdpbGwgYmUgY29lcmNlZCB0byA1MC4KCiBJZiB0aGlzIGZpZWxkIGlzIG5lZ2F0
aXZlLCBhbiBJTlZBTElEX0FSR1VNRU5UIGlzIHJldHVybmVkLgoKDQoFBAMCAQUSBJsCAgcK
DQoFBAMCAQESBJsCCBEKDQoFBAMCAQMSBJsCFBUKwQQKBAQDAgISBKcCAhgasgQgQSBwYWdl
IHRva2VuCiBbTGlzdERhdGFTdG9yZXNSZXNwb25zZS5uZXh0X3BhZ2VfdG9rZW5dW2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGlzdERhdGFTdG9yZXNSZXNwb25zZS5uZXh0
X3BhZ2VfdG9rZW5dLAogcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzCiBbRGF0YVN0b3JlU2Vy
dmljZS5MaXN0RGF0YVN0b3Jlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5E
YXRhU3RvcmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRv
IHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwg
b3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0bwogW0RhdGFTdG9yZVNlcnZpY2UuTGlzdERh
dGFTdG9yZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0b3JlU2Vy
dmljZS5MaXN0RGF0YVN0b3Jlc10KIG11c3QgbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRl
ZCB0aGUgcGFnZSB0b2tlbi4gT3RoZXJ3aXNlLCBhbgogSU5WQUxJRF9BUkdVTUVOVCBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQQDAgIFEgSnAgIICg0KBQQDAgIBEgSnAgkTCg0KBQQDAgID
EgSnAhYXCmcKBAQDAgMSBKsCAhQaWSBGaWx0ZXIgYnkgc29sdXRpb24gdHlwZSAuCiBGb3Ig
ZXhhbXBsZTogYGZpbHRlciA9ICdzb2x1dGlvbl90eXBlOlNPTFVUSU9OX1RZUEVfU0VBUkNI
J2AKCg0KBQQDAgMFEgSrAgIICg0KBQQDAgMBEgSrAgkPCg0KBQQDAgMDEgSrAhITCpIBCgIE
BBIGsQIAugIBGoMBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5M
aXN0RGF0YVN0b3Jlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3Rv
cmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVzXQogbWV0aG9kLgoKCwoDBAQBEgSxAggeClsKBAQE
AgASBLMCAiUaTSBBbGwgdGhlIGN1c3RvbWVyJ3MgW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdcy4KCg0KBQQEAgAEEgSzAgIKCg0KBQQE
AgAGEgSzAgsUCg0KBQQEAgABEgSzAhUgCg0KBQQEAgADEgSzAiMkCugBCgQEBAIBEgS5AgId
GtkBIEEgdG9rZW4gdGhhdCBjYW4gYmUgc2VudCBhcwogW0xpc3REYXRhU3RvcmVzUmVxdWVz
dC5wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpc3REYXRh
U3RvcmVzUmVxdWVzdC5wYWdlX3Rva2VuXQogdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4g
SWYgdGhpcyBmaWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8KIHN1YnNlcXVlbnQgcGFn
ZXMuCgoNCgUEBAIBBRIEuQICCAoNCgUEBAIBARIEuQIJGAoNCgUEBAIBAxIEuQIbHAqTAQoC
BAUSBr8CANACARqEASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5E
ZWxldGVEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0
b3JlU2VydmljZS5EZWxldGVEYXRhU3RvcmVdCiBtZXRob2QuCgoLCgMEBQESBL8CCB4KkAQK
BAQFAgASBsoCAs8CBBr/AyBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mCiBbRGF0
YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0sIHN1
Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVj
dGlvbnMve2NvbGxlY3Rpb25faWR9L2RhdGFTdG9yZXMve2RhdGFfc3RvcmVfaWR9YC4KCiBJ
ZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byBkZWxldGUgdGhlCiBb
RGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0s
IHJlZ2FyZGxlc3Mgb2YKIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9O
X0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdIHRvIGRlbGV0ZQogZG9lcyBu
b3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAUCAAUSBMoC
AggKDQoFBAUCAAESBMoCCQ0KDQoFBAUCAAMSBMoCEBEKDwoFBAUCAAgSBsoCEs8CAwoQCggE
BQIACJwIABIEywIEKgoRCgcEBQIACJ8IEgbMAgTOAgUKkwEKAgQGEgbVAgDnAgEahAEgUmVx
dWVzdCBtZXNzYWdlIGZvcgogW0RhdGFTdG9yZVNlcnZpY2UuVXBkYXRlRGF0YVN0b3JlXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZVNlcnZpY2UuVXBkYXRl
RGF0YVN0b3JlXQogbWV0aG9kLgoKCwoDBAYBEgTVAggeCpsDCgQEBgIAEgTfAgJEGowDIFJl
cXVpcmVkLiBUaGUgW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5EYXRhU3RvcmVdIHRvCiB1cGRhdGUuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZl
IHBlcm1pc3Npb24gdG8gdXBkYXRlIHRoZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MS5EYXRhU3RvcmVdLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9y
IG5vdCBpdCBleGlzdHMsIGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQu
CgogSWYgdGhlIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RGF0YVN0b3JlXSB0byB1cGRhdGUKIGRvZXMgbm90IGV4aXN0LCBhIE5PVF9GT1VORCBlcnJv
ciBpcyByZXR1cm5lZC4KCg0KBQQGAgAGEgTfAgILCg0KBQQGAgABEgTfAgwWCg0KBQQGAgAD
EgTfAhkaCg0KBQQGAgAIEgTfAhtDChAKCAQGAgAInAgAEgTfAhxCCtQBCgQEBgIBEgTmAgIs
GsUBIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbRGF0YVN0b3Jl
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRhdGFTdG9yZV0gdG8gdXBkYXRl
LgoKIElmIGFuIHVuc3VwcG9ydGVkIG9yIHVua25vd24gZmllbGQgaXMgcHJvdmlkZWQsIGFu
IElOVkFMSURfQVJHVU1FTlQgZXJyb3IKIGlzIHJldHVybmVkLgoKDQoFBAYCAQYSBOYCAhsK
DQoFBAYCAQESBOYCHCcKDQoFBAYCAQMSBOYCKisK9QEKAgQHEgbtAgD0AgEa5gEgTWV0YWRh
dGEgcmVsYXRlZCB0byB0aGUgcHJvZ3Jlc3Mgb2YgdGhlCiBbRGF0YVN0b3JlU2VydmljZS5E
ZWxldGVEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuRGF0YVN0
b3JlU2VydmljZS5EZWxldGVEYXRhU3RvcmVdCiBvcGVyYXRpb24uIFRoaXMgd2lsbCBiZSBy
ZXR1cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQog
ZmllbGQuCgoLCgMEBwESBO0CCB8KJgoEBAcCABIE7wICLBoYIE9wZXJhdGlvbiBjcmVhdGUg
dGltZS4KCg0KBQQHAgAGEgTvAgIbCg0KBQQHAgABEgTvAhwnCg0KBQQHAgADEgTvAiorCmQK
BAQHAgESBPMCAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJh
dGlvbiBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQHAgEG
EgTzAgIbCg0KBQQHAgEBEgTzAhwnCg0KBQQHAgEDEgTzAiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest ===
    # Fields for CreateDataStoreRequest
    # Field: cmek_config_name Type: 9 ()
    # Field: disable_cmek Type: 8 ()
    # Field: parent Type: 9 ()
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1.DataStore)
    # Field: data_store_id Type: 9 ()
    # Field: create_advanced_site_search Type: 8 ()
    # Field: skip_default_schema_creation Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest ===
    # Fields for GetDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreMetadata ===
    # Fields for CreateDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest ===
    # Fields for ListDataStoresRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse ===
    # Fields for ListDataStoresResponse
    # Field: data_stores Type: 11 (.google.cloud.discoveryengine.v1.DataStore)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest ===
    # Fields for DeleteDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest ===
    # Fields for UpdateDataStoreRequest
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1.DataStore)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreMetadata ===
    # Fields for DeleteDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1::DataStoreService::DataStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1::DataStoreService::DataStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::DataStoreService::DataStoreServiceClient

Client stub representing the remote C<DataStoreService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'CreateDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'GetDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DataStore::DataStore',
    });
}

sub list_data_stores {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'ListDataStores',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse',
    });
}

sub delete_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'DeleteDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'UpdateDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::DataStore::DataStore',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.DataStoreService',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::DataStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/data_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::DataStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest->new({
        cmek_config_name => $cmek_config_name,
        disable_cmek => $disable_cmek,
        parent => $parent,
        data_store => $data_store,
    });

    # Read or update a field
    my $val = $msg->cmek_config_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/data_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest

Request for
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1.DataStoreService.CreateDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cmek_config_name() >> / C<< $msg->cmek_config_name($value) >>

Type: C<String>

Resource name of the CmekConfig to use for protecting this DataStore.

=item * C<< $msg->disable_cmek() >> / C<< $msg->disable_cmek($value) >>

Type: C<Bool>

DataStore without CMEK protections. If a default CmekConfig is set for
the project, setting this field will override the default CmekConfig as
well.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}/collections/{collection}`.

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1.DataStore] to
create.

=item * C<< $msg->data_store_id() >> / C<< $msg->data_store_id($value) >>

Type: C<String>

Required. The ID to use for the
[DataStore][google.cloud.discoveryengine.v1.DataStore], which will become
the final component of the
[DataStore][google.cloud.discoveryengine.v1.DataStore]'s resource name.

This field must conform to [RFC-1034](https://tools.ietf.org/html/rfc1034)
standard with a length limit of 63 characters. Otherwise, an
INVALID_ARGUMENT error is returned.

=item * C<< $msg->create_advanced_site_search() >> / C<< $msg->create_advanced_site_search($value) >>

Type: C<Bool>

A boolean flag indicating whether user want to directly create an advanced
data store for site search.
If the data store is not configured as site
search (GENERIC vertical and PUBLIC_WEBSITE content_config), this flag will
be ignored.

=item * C<< $msg->skip_default_schema_creation() >> / C<< $msg->skip_default_schema_creation($value) >>

Type: C<Bool>

A boolean flag indicating whether to skip the default schema creation for
the data store. Only enable this flag if you are certain that the default
schema is incompatible with your use case.

If set to true, you must manually create a schema for the data store before
any documents can be ingested.

This flag cannot be specified if `data_store.starting_schema` is specified.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest

Request message for
[DataStoreService.GetDataStore][google.cloud.discoveryengine.v1.DataStoreService.GetDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to access the
[DataStore][google.cloud.discoveryengine.v1.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested [DataStore][google.cloud.discoveryengine.v1.DataStore]
does not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1.DataStoreService.CreateDataStore]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest

Request message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection_id}`.

If the caller does not have permission to list
[DataStore][google.cloud.discoveryengine.v1.DataStore]s under this
location, regardless of whether or not this data store exists, a
PERMISSION_DENIED error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of [DataStore][google.cloud.discoveryengine.v1.DataStore]s
to return. If unspecified, defaults to 10. The maximum allowed value is 50.
Values above 50 will be coerced to 50.

If this field is negative, an INVALID_ARGUMENT is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListDataStoresResponse.next_page_token][google.cloud.discoveryengine.v1.ListDataStoresResponse.next_page_token],
received from a previous
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1.DataStoreService.ListDataStores]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1.DataStoreService.ListDataStores]
must match the call that provided the page token. Otherwise, an
INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter by solution type .
For example: `filter = 'solution_type:SOLUTION_TYPE_SEARCH'`

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse

Response message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_stores() >> / C<< $msg->data_stores($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DataStore::DataStore>)

All the customer's [DataStore][google.cloud.discoveryengine.v1.DataStore]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListDataStoresRequest.page_token][google.cloud.discoveryengine.v1.ListDataStoresRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest

Request message for
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1.DataStoreService.DeleteDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to delete the
[DataStore][google.cloud.discoveryengine.v1.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1.DataStore] to delete
does not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest

Request message for
[DataStoreService.UpdateDataStore][google.cloud.discoveryengine.v1.DataStoreService.UpdateDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1.DataStore] to
update.

If the caller does not have permission to update the
[DataStore][google.cloud.discoveryengine.v1.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1.DataStore] to update
does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[DataStore][google.cloud.discoveryengine.v1.DataStore] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1.DataStoreService.DeleteDataStore]
operation. This will be returned by the google.longrunning.Operation.metadata
field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Operation last update time. If the operation is done, this is also the
finish time.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::DataStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
