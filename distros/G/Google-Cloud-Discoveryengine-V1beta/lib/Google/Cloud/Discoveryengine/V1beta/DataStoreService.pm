package Google::Cloud::Discoveryengine::V1beta::DataStoreService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::DataStore };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9kYXRhX3N0b3JlX3NlcnZp
Y2UucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxo0
Z29vZ2xlL2Nsb3VkL2Rpc2NvdmVyeWVuZ2luZS92MWJldGEvZGF0YV9zdG9yZS5wcm90bxoj
Z29vZ2xlL2xvbmdydW5uaW5nL29wZXJhdGlvbnMucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9l
bXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9w
cm90b2J1Zi90aW1lc3RhbXAucHJvdG8i8QMKFkNyZWF0ZURhdGFTdG9yZVJlcXVlc3QSWgoQ
Y21la19jb25maWdfbmFtZRgFIAEoCUIu+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBp
cy5jb20vQ21la0NvbmZpZ0gAUg5jbWVrQ29uZmlnTmFtZRIjCgxkaXNhYmxlX2NtZWsYBiAB
KAhIAFILZGlzYWJsZUNtZWsSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKWRpc2NvdmVyeWVu
Z2luZS5nb29nbGVhcGlzLmNvbS9Db2xsZWN0aW9uUgZwYXJlbnQSUgoKZGF0YV9zdG9yZRgC
IAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZUID
4EECUglkYXRhU3RvcmUSJwoNZGF0YV9zdG9yZV9pZBgDIAEoCUID4EECUgtkYXRhU3RvcmVJ
ZBI9ChtjcmVhdGVfYWR2YW5jZWRfc2l0ZV9zZWFyY2gYBCABKAhSGGNyZWF0ZUFkdmFuY2Vk
U2l0ZVNlYXJjaBI/Chxza2lwX2RlZmF1bHRfc2NoZW1hX2NyZWF0aW9uGAcgASgIUhlza2lw
RGVmYXVsdFNjaGVtYUNyZWF0aW9uQg4KDGNtZWtfb3B0aW9ucyJbChNHZXREYXRhU3RvcmVS
ZXF1ZXN0EkQKBG5hbWUYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFw
aXMuY29tL0RhdGFTdG9yZVIEbmFtZSKTAQoXQ3JlYXRlRGF0YVN0b3JlTWV0YWRhdGESOwoL
Y3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVU
aW1lEjsKC3VwZGF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIK
dXBkYXRlVGltZSK2AQoVTGlzdERhdGFTdG9yZXNSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx
4EEC+kErCilkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20vQ29sbGVjdGlvblIGcGFy
ZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJ
cGFnZVRva2VuEhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyIpEBChZMaXN0RGF0YVN0b3Jlc1Jl
c3BvbnNlEk8KC2RhdGFfc3RvcmVzGAEgAygLMi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuRGF0YVN0b3JlUgpkYXRhU3RvcmVzEiYKD25leHRfcGFnZV90b2tlbhgC
IAEoCVINbmV4dFBhZ2VUb2tlbiJeChZEZWxldGVEYXRhU3RvcmVSZXF1ZXN0EkQKBG5hbWUY
ASABKAlCMOBBAvpBKgooZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29tL0RhdGFTdG9y
ZVIEbmFtZSKpAQoWVXBkYXRlRGF0YVN0b3JlUmVxdWVzdBJSCgpkYXRhX3N0b3JlGAEgASgL
Mi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlQgPgQQJS
CWRhdGFTdG9yZRI7Cgt1cGRhdGVfbWFzaxgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVs
ZE1hc2tSCnVwZGF0ZU1hc2sikwEKF0RlbGV0ZURhdGFTdG9yZU1ldGFkYXRhEjsKC2NyZWF0
ZV90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7
Cgt1cGRhdGVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0
ZVRpbWUysQ4KEERhdGFTdG9yZVNlcnZpY2USmAMKD0NyZWF0ZURhdGFTdG9yZRI7Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkNyZWF0ZURhdGFTdG9yZVJlcXVlc3Qa
HS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIqgCgtPkkwKQASIyL3YxYmV0YS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2RhdGFTdG9yZXM6CmRhdGFfc3RvcmVaTiJA
L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29sbGVjdGlvbnMvKn0v
ZGF0YVN0b3JlczoKZGF0YV9zdG9yZdpBH3BhcmVudCxkYXRhX3N0b3JlLGRhdGFfc3RvcmVf
aWTKQWwKLWdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZRI7
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQ3JlYXRlRGF0YVN0b3JlTWV0
YWRhdGESgAIKDEdldERhdGFTdG9yZRI4Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkdldERhdGFTdG9yZVJlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxYmV0YS5EYXRhU3RvcmUihQGC0+STAngSMi92MWJldGEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9kYXRhU3RvcmVzLyp9WkISQC92MWJldGEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9jb2xsZWN0aW9ucy8qL2RhdGFTdG9yZXMvKn3aQQRuYW1lEpMCCg5M
aXN0RGF0YVN0b3JlcxI6Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkxp
c3REYXRhU3RvcmVzUmVxdWVzdBo7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhLkxpc3REYXRhU3RvcmVzUmVzcG9uc2UihwGC0+STAngSMi92MWJldGEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9kYXRhU3RvcmVzWkISQC92MWJldGEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NvbGxlY3Rpb25zLyp9L2RhdGFTdG9yZXPaQQZwYXJl
bnQSzAIKD0RlbGV0ZURhdGFTdG9yZRI7Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkRlbGV0ZURhdGFTdG9yZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uItwBgtPkkwJ4KjIvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
ZGF0YVN0b3Jlcy8qfVpCKkAvdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
Y29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp92kEEbmFtZcpBVAoVZ29vZ2xlLnByb3RvYnVm
LkVtcHR5Ejtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EZWxldGVEYXRh
U3RvcmVNZXRhZGF0YRLHAgoPVXBkYXRlRGF0YVN0b3JlEjsuZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MWJldGEuVXBkYXRlRGF0YVN0b3JlUmVxdWVzdBouLmdvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZSLGAYLT5JMCpgEyPS92MWJldGEv
e2RhdGFfc3RvcmUubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2RhdGFTdG9yZXMvKn06
CmRhdGFfc3RvcmVaWTJLL3YxYmV0YS97ZGF0YV9zdG9yZS5uYW1lPXByb2plY3RzLyovbG9j
YXRpb25zLyovY29sbGVjdGlvbnMvKi9kYXRhU3RvcmVzLyp9OgpkYXRhX3N0b3Jl2kEWZGF0
YV9zdG9yZSx1cGRhdGVfbWFzaxrPAcpBHmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bdJBqgFodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnJlYWR3cml0
ZSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5zZXJ2
aW5nLnJlYWR3cml0ZUKcAgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFi
ZXRhQhVEYXRhU3RvcmVTZXJ2aWNlUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNj
b3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2lu
ZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5W
MUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6
Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSthSCgcSBQ4AywIBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMA
IQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYAPgoJCgIDBRIDFwAtCgkKAgMGEgMY
ACUKCQoCAwcSAxkAKgoJCgIDCBIDGgApCggKAQgSAxwAQAoJCgIIJRIDHABACggKAQgSAx0A
aAoJCgIICxIDHQBoCggKAQgSAx4AIgoJCgIIChIDHgAiCggKAQgSAx8ANgoJCgIICBIDHwA2
CggKAQgSAyAAQAoJCgIIARIDIABACggKAQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAQAoJ
CgIIKRIDIgBACggKAQgSAyMAPwoJCgIILRIDIwA/Cm0KAgYAEgQnAHkBGmEgU2VydmljZSBm
b3IgbWFuYWdpbmcKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkRhdGFTdG9yZV0gY29uZmlndXJhdGlvbi4KCgoKAwYAARIDJwgYCgoKAwYAAxID
KAJGCgwKBQYAA5kIEgMoAkYKCwoDBgADEgQpAixKCg0KBQYAA5oIEgQpAixKCskCCgQGAAIA
EgQ1AkQDGroCIENyZWF0ZXMgYSBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxYmV0YS5EYXRhU3RvcmVdLgoKIERhdGFTdG9yZSBpcyBmb3Igc3RvcmluZwog
W0RvY3VtZW50c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRG9jdW1l
bnRdLiBUbyBzZXJ2ZSB0aGVzZQogZG9jdW1lbnRzIGZvciBTZWFyY2gsIG9yIFJlY29tbWVu
ZGF0aW9uIHVzZSBjYXNlLCBhbgogW0VuZ2luZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuRW5naW5lXSBuZWVkcyB0byBiZSBjcmVhdGVkCiBzZXBhcmF0ZWx5LgoK
DAoFBgACAAESAzUGFQoMCgUGAAIAAhIDNRYsCgwKBQYAAgADEgM2DysKDQoFBgACAAQSBDcE
PgYKEQoJBgACAASwyrwiEgQ3BD4GCgwKBQYAAgAEEgM/BE0KDwoIBgACAASbCAASAz8ETQoN
CgUGAAIABBIEQARDBgoPCgcGAAIABJkIEgRABEMGClIKBAYAAgESBEcCTwMaRCBHZXRzIGEg
W0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0
b3JlXS4KCgwKBQYAAgEBEgNHBhIKDAoFBgACAQISA0cTJgoMCgUGAAIBAxIDRzE6Cg0KBQYA
AgEEEgRIBE0GChEKCQYAAgEEsMq8IhIESARNBgoMCgUGAAIBBBIDTgQyCg8KCAYAAgEEmwgA
EgNOBDIKdwoEBgACAhIEUwJbAxppIExpc3RzIGFsbCB0aGUgW0RhdGFTdG9yZV1bZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXXMKIGFzc29jaWF0ZWQg
d2l0aCB0aGUgcHJvamVjdC4KCgwKBQYAAgIBEgNTBhQKDAoFBgACAgISA1MVKgoMCgUGAAIC
AxIDUzVLCg0KBQYAAgIEEgRUBFkGChEKCQYAAgIEsMq8IhIEVARZBgoMCgUGAAICBBIDWgQ0
Cg8KCAYAAgIEmwgAEgNaBDQKVQoEBgACAxIEXgJrAxpHIERlbGV0ZXMgYSBbRGF0YVN0b3Jl
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EYXRhU3RvcmVdLgoKDAoF
BgACAwESA14GFQoMCgUGAAIDAhIDXhYsCgwKBQYAAgMDEgNfDysKDQoFBgACAwQSBGAEZQYK
EQoJBgACAwSwyrwiEgRgBGUGCgwKBQYAAgMEEgNmBDIKDwoIBgACAwSbCAASA2YEMgoNCgUG
AAIDBBIEZwRqBgoPCgcGAAIDBJkIEgRnBGoGClQKBAYAAgQSBG4CeAMaRiBVcGRhdGVzIGEg
W0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0
b3JlXQoKDAoFBgACBAESA24GFQoMCgUGAAIEAhIDbhYsCgwKBQYAAgQDEgNuN0AKDQoFBgAC
BAQSBG8EdgYKEQoJBgACBASwyrwiEgRvBHYGCgwKBQYAAgQEEgN3BEQKDwoIBgACBASbCAAS
A3cERAqOAQoCBAASBX4AtAEBGoABIFJlcXVlc3QgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5D
cmVhdGVEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRh
dGFTdG9yZVNlcnZpY2UuQ3JlYXRlRGF0YVN0b3JlXQogbWV0aG9kLgoKCgoDBAABEgN+CB4K
iQEKBAQACAASBoEBAosBAxp5IENNRUsgb3B0aW9ucyBmb3IgdGhlIERhdGFTdG9yZS4gU2V0
dGluZyB0aGlzIGZpZWxkIHdpbGwgb3ZlcnJpZGUgdGhlCiBkZWZhdWx0IENtZWtDb25maWcg
aWYgb25lIGlzIHNldCBmb3IgdGhlIHByb2plY3QuCgoNCgUEAAgAARIEgQEIFApXCgQEAAIA
EgaDAQSFAQcaRyBSZXNvdXJjZSBuYW1lIG9mIHRoZSBDbWVrQ29uZmlnIHRvIHVzZSBmb3Ig
cHJvdGVjdGluZyB0aGlzIERhdGFTdG9yZS4KCg0KBQQAAgAFEgSDAQQKCg0KBQQAAgABEgSD
AQsbCg0KBQQAAgADEgSDAR4fCg8KBQQAAgAIEgaDASCFAQYKEQoHBAACAAifCBIGgwEhhQEF
CqcBCgQEAAIBEgSKAQQaGpgBIERhdGFTdG9yZSB3aXRob3V0IENNRUsgcHJvdGVjdGlvbnMu
IElmIGEgZGVmYXVsdCBDbWVrQ29uZmlnIGlzIHNldCBmb3IKIHRoZSBwcm9qZWN0LCBzZXR0
aW5nIHRoaXMgZmllbGQgd2lsbCBvdmVycmlkZSB0aGUgZGVmYXVsdCBDbWVrQ29uZmlnIGFz
CiB3ZWxsLgoKDQoFBAACAQUSBIoBBAgKDQoFBAACAQESBIoBCRUKDQoFBAACAQMSBIoBGBkK
ggEKBAQAAgISBo8BApQBBBpyIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUs
IHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29s
bGVjdGlvbnMve2NvbGxlY3Rpb259YC4KCg0KBQQAAgIFEgSPAQIICg0KBQQAAgIBEgSPAQkP
Cg0KBQQAAgIDEgSPARITCg8KBQQAAgIIEgaPARSUAQMKEAoIBAACAgicCAASBJABBCoKEQoH
BAACAgifCBIGkQEEkwEFCmQKBAQAAgMSBJgBAkQaViBSZXF1aXJlZC4gVGhlIFtEYXRhU3Rv
cmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0gdG8K
IGNyZWF0ZS4KCg0KBQQAAgMGEgSYAQILCg0KBQQAAgMBEgSYAQwWCg0KBQQAAgMDEgSYARka
Cg0KBQQAAgMIEgSYARtDChAKCAQAAgMInAgAEgSYARxCCpgDCgQEAAIEEgSiAQJEGokDIFJl
cXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0sIHdoaWNoIHdpbGwKIGJlY29t
ZSB0aGUgZmluYWwgY29tcG9uZW50IG9mIHRoZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXSdzIHJlc291cmNlIG5hbWUuCgog
VGhpcyBmaWVsZCBtdXN0IGNvbmZvcm0gdG8gW1JGQy0xMDM0XShodHRwczovL3Rvb2xzLmll
dGYub3JnL2h0bWwvcmZjMTAzNCkKIHN0YW5kYXJkIHdpdGggYSBsZW5ndGggbGltaXQgb2Yg
NjMgY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbgogSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBp
cyByZXR1cm5lZC4KCg0KBQQAAgQFEgSiAQIICg0KBQQAAgQBEgSiAQkWCg0KBQQAAgQDEgSi
ARkaCg0KBQQAAgQIEgSiARtDChAKCAQAAgQInAgAEgSiARxCCv8BCgQEAAIFEgSpAQInGvAB
IEEgYm9vbGVhbiBmbGFnIGluZGljYXRpbmcgd2hldGhlciB1c2VyIHdhbnQgdG8gZGlyZWN0
bHkgY3JlYXRlIGFuIGFkdmFuY2VkCiBkYXRhIHN0b3JlIGZvciBzaXRlIHNlYXJjaC4KIElm
IHRoZSBkYXRhIHN0b3JlIGlzIG5vdCBjb25maWd1cmVkIGFzIHNpdGUKIHNlYXJjaCAoR0VO
RVJJQyB2ZXJ0aWNhbCBhbmQgUFVCTElDX1dFQlNJVEUgY29udGVudF9jb25maWcpLCB0aGlz
IGZsYWcgd2lsbAogYmUgaWdub3JlZC4KCg0KBQQAAgUFEgSpAQIGCg0KBQQAAgUBEgSpAQci
Cg0KBQQAAgUDEgSpASUmCo0DCgQEAAIGEgSzAQIoGv4CIEEgYm9vbGVhbiBmbGFnIGluZGlj
YXRpbmcgd2hldGhlciB0byBza2lwIHRoZSBkZWZhdWx0IHNjaGVtYSBjcmVhdGlvbiBmb3IK
IHRoZSBkYXRhIHN0b3JlLiBPbmx5IGVuYWJsZSB0aGlzIGZsYWcgaWYgeW91IGFyZSBjZXJ0
YWluIHRoYXQgdGhlIGRlZmF1bHQKIHNjaGVtYSBpcyBpbmNvbXBhdGlibGUgd2l0aCB5b3Vy
IHVzZSBjYXNlLgoKIElmIHNldCB0byB0cnVlLCB5b3UgbXVzdCBtYW51YWxseSBjcmVhdGUg
YSBzY2hlbWEgZm9yIHRoZSBkYXRhIHN0b3JlIGJlZm9yZQogYW55IGRvY3VtZW50cyBjYW4g
YmUgaW5nZXN0ZWQuCgogVGhpcyBmbGFnIGNhbm5vdCBiZSBzcGVjaWZpZWQgaWYgYGRhdGFf
c3RvcmUuc3RhcnRpbmdfc2NoZW1hYCBpcyBzcGVjaWZpZWQuCgoNCgUEAAIGBRIEswECBgoN
CgUEAAIGARIEswEHIwoNCgUEAAIGAxIEswEmJwqRAQoCBAESBrkBAMoBARqCASBSZXF1ZXN0
IG1lc3NhZ2UgZm9yCiBbRGF0YVN0b3JlU2VydmljZS5HZXREYXRhU3RvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZVNlcnZpY2UuR2V0RGF0YVN0
b3JlXQogbWV0aG9kLgoKCwoDBAEBEgS5AQgbCpwECgQEAQIAEgbEAQLJAQQaiwQgUmVxdWly
ZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRp
c2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXSwgc3VjaCBhcwogYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97Y29sbGVjdGlvbl9p
ZH0vZGF0YVN0b3Jlcy97ZGF0YV9zdG9yZV9pZH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBu
b3QgaGF2ZSBwZXJtaXNzaW9uIHRvIGFjY2VzcyB0aGUKIFtEYXRhU3RvcmVdW2dvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0sIHJlZ2FyZGxlc3Mgb2YK
IHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQRVJNSVNTSU9OX0RFTklFRCBlcnJvciBp
cyByZXR1cm5lZC4KCiBJZiB0aGUgcmVxdWVzdGVkIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0KIGRvZXMgbm90IGV4aXN0LCBh
IE5PVF9GT1VORCBlcnJvciBpcyByZXR1cm5lZC4KCg0KBQQBAgAFEgTEAQIICg0KBQQBAgAB
EgTEAQkNCg0KBQQBAgADEgTEARARCg8KBQQBAgAIEgbEARLJAQMKEAoIBAECAAicCAASBMUB
BCoKEQoHBAECAAifCBIGxgEEyAEFCvkBCgIEAhIG0AEA1wEBGuoBIE1ldGFkYXRhIHJlbGF0
ZWQgdG8gdGhlIHByb2dyZXNzIG9mIHRoZQogW0RhdGFTdG9yZVNlcnZpY2UuQ3JlYXRlRGF0
YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EYXRhU3RvcmVT
ZXJ2aWNlLkNyZWF0ZURhdGFTdG9yZV0KIG9wZXJhdGlvbi4gVGhpcyB3aWxsIGJlIHJldHVy
bmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBmaWVs
ZC4KCgsKAwQCARIE0AEIHwomCgQEAgIAEgTSAQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0aW1l
LgoKDQoFBAICAAYSBNIBAhsKDQoFBAICAAESBNIBHCcKDQoFBAICAAMSBNIBKisKZAoEBAIC
ARIE1gECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0aW9u
IGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAICAQYSBNYB
AhsKDQoFBAICAQESBNYBHCcKDQoFBAICAQMSBNYBKisKlQEKAgQDEgbcAQCCAgEahgEgUmVx
dWVzdCBtZXNzYWdlIGZvcgogW0RhdGFTdG9yZVNlcnZpY2UuTGlzdERhdGFTdG9yZXNdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZVNlcnZpY2UuTGlz
dERhdGFTdG9yZXNdCiBtZXRob2QuCgoLCgMEAwESBNwBCB0K7gIKBAQDAgASBuQBAukBBBrd
AiBSZXF1aXJlZC4gVGhlIHBhcmVudCBicmFuY2ggcmVzb3VyY2UgbmFtZSwgc3VjaCBhcwog
YHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb2xsZWN0aW9ucy97
Y29sbGVjdGlvbl9pZH1gLgoKIElmIHRoZSBjYWxsZXIgZG9lcyBub3QgaGF2ZSBwZXJtaXNz
aW9uIHRvIGxpc3QKIFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkRhdGFTdG9yZV1zIHVuZGVyIHRoaXMKIGxvY2F0aW9uLCByZWdhcmRsZXNzIG9m
IHdoZXRoZXIgb3Igbm90IHRoaXMgZGF0YSBzdG9yZSBleGlzdHMsIGEKIFBFUk1JU1NJT05f
REVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKDQoFBAMCAAUSBOQBAggKDQoFBAMCAAESBOQB
CQ8KDQoFBAMCAAMSBOQBEhMKDwoFBAMCAAgSBuQBFOkBAwoQCggEAwIACJwIABIE5QEEKgoR
CgcEAwIACJ8IEgbmAQToAQUKkgIKBAQDAgESBPEBAhYagwIgTWF4aW11bSBudW1iZXIgb2YK
IFtEYXRhU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFT
dG9yZV1zIHRvIHJldHVybi4gSWYKIHVuc3BlY2lmaWVkLCBkZWZhdWx0cyB0byAxMC4gVGhl
IG1heGltdW0gYWxsb3dlZCB2YWx1ZSBpcyA1MC4gVmFsdWVzIGFib3ZlCiA1MCB3aWxsIGJl
IGNvZXJjZWQgdG8gNTAuCgogSWYgdGhpcyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4gSU5WQUxJ
RF9BUkdVTUVOVCBpcyByZXR1cm5lZC4KCg0KBQQDAgEFEgTxAQIHCg0KBQQDAgEBEgTxAQgR
Cg0KBQQDAgEDEgTxARQVCs0ECgQEAwICEgT9AQIYGr4EIEEgcGFnZSB0b2tlbgogW0xpc3RE
YXRhU3RvcmVzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0RGF0YVN0b3Jlc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tl
bl0sCiByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMKIFtEYXRhU3RvcmVTZXJ2aWNlLkxpc3RE
YXRhU3RvcmVzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5EYXRhU3Rv
cmVTZXJ2aWNlLkxpc3REYXRhU3RvcmVzXQogY2FsbC4gUHJvdmlkZSB0aGlzIHRvIHJldHJp
ZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hlbiBwYWdpbmF0aW5nLCBhbGwgb3RoZXIg
cGFyYW1ldGVycyBwcm92aWRlZCB0bwogW0RhdGFTdG9yZVNlcnZpY2UuTGlzdERhdGFTdG9y
ZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZVNlcnZp
Y2UuTGlzdERhdGFTdG9yZXNdCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlIHBhZ2UgdG9rZW4uIE90aGVyd2lzZSwgYW4KIElOVkFMSURfQVJHVU1FTlQgZXJyb3Ig
aXMgcmV0dXJuZWQuCgoNCgUEAwICBRIE/QECCAoNCgUEAwICARIE/QEJEwoNCgUEAwICAxIE
/QEWFwpnCgQEAwIDEgSBAgIUGlkgRmlsdGVyIGJ5IHNvbHV0aW9uIHR5cGUgLgogRm9yIGV4
YW1wbGU6IGBmaWx0ZXIgPSAnc29sdXRpb25fdHlwZTpTT0xVVElPTl9UWVBFX1NFQVJDSCdg
CgoNCgUEAwIDBRIEgQICCAoNCgUEAwIDARIEgQIJDwoNCgUEAwIDAxIEgQISEwqWAQoCBAQS
BocCAJECARqHASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0RhdGFTdG9yZVNlcnZpY2UuTGlz
dERhdGFTdG9yZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFT
dG9yZVNlcnZpY2UuTGlzdERhdGFTdG9yZXNdCiBtZXRob2QuCgoLCgMEBAESBIcCCB4KYAoE
BAQCABIEigICJRpSIEFsbCB0aGUgY3VzdG9tZXIncwogW0RhdGFTdG9yZV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXXMuCgoNCgUEBAIABBIEigIC
CgoNCgUEBAIABhIEigILFAoNCgUEBAIAARIEigIVIAoNCgUEBAIAAxIEigIjJArsAQoEBAQC
ARIEkAICHRrdASBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMKIFtMaXN0RGF0YVN0b3Jl
c1JlcXVlc3QucGFnZV90b2tlbl1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuTGlzdERhdGFTdG9yZXNSZXF1ZXN0LnBhZ2VfdG9rZW5dCiB0byByZXRyaWV2ZSB0aGUg
bmV4dCBwYWdlLiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubwogc3Vi
c2VxdWVudCBwYWdlcy4KCg0KBQQEAgEFEgSQAgIICg0KBQQEAgEBEgSQAgkYCg0KBQQEAgED
EgSQAhscCpcBCgIEBRIGlgIApwIBGogBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtEYXRhU3Rv
cmVTZXJ2aWNlLkRlbGV0ZURhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuRGF0YVN0b3JlU2VydmljZS5EZWxldGVEYXRhU3RvcmVdCiBtZXRob2QuCgoL
CgMEBQESBJYCCB4KnAQKBAQFAgASBqECAqYCBBqLBCBSZXF1aXJlZC4gRnVsbCByZXNvdXJj
ZSBuYW1lIG9mCiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYx
YmV0YS5EYXRhU3RvcmVdLCBzdWNoIGFzCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
cy97bG9jYXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9uX2lkfS9kYXRhU3RvcmVzL3tk
YXRhX3N0b3JlX2lkfWAuCgogSWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Np
b24gdG8gZGVsZXRlIHRoZQogW0RhdGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWJldGEuRGF0YVN0b3JlXSwgcmVnYXJkbGVzcyBvZgogd2hldGhlciBvciBub3Qg
aXQgZXhpc3RzLCBhIFBFUk1JU1NJT05fREVOSUVEIGVycm9yIGlzIHJldHVybmVkLgoKIElm
IHRoZSBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5E
YXRhU3RvcmVdIHRvIGRlbGV0ZQogZG9lcyBub3QgZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9y
IGlzIHJldHVybmVkLgoKDQoFBAUCAAUSBKECAggKDQoFBAUCAAESBKECCQ0KDQoFBAUCAAMS
BKECEBEKDwoFBAUCAAgSBqECEqYCAwoQCggEBQIACJwIABIEogIEKgoRCgcEBQIACJ8IEgaj
AgSlAgUKlwEKAgQGEgasAgC+AgEaiAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0RhdGFTdG9y
ZVNlcnZpY2UuVXBkYXRlRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5EYXRhU3RvcmVTZXJ2aWNlLlVwZGF0ZURhdGFTdG9yZV0KIG1ldGhvZC4KCgsK
AwQGARIErAIIHgqnAwoEBAYCABIEtgICRBqYAyBSZXF1aXJlZC4gVGhlIFtEYXRhU3RvcmVd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0gdG8KIHVw
ZGF0ZS4KCiBJZiB0aGUgY2FsbGVyIGRvZXMgbm90IGhhdmUgcGVybWlzc2lvbiB0byB1cGRh
dGUgdGhlCiBbRGF0YVN0b3JlXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5EYXRhU3RvcmVdLCByZWdhcmRsZXNzIG9mCiB3aGV0aGVyIG9yIG5vdCBpdCBleGlzdHMs
IGEgUEVSTUlTU0lPTl9ERU5JRUQgZXJyb3IgaXMgcmV0dXJuZWQuCgogSWYgdGhlIFtEYXRh
U3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkRhdGFTdG9yZV0g
dG8gdXBkYXRlCiBkb2VzIG5vdCBleGlzdCwgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJu
ZWQuCgoNCgUEBgIABhIEtgICCwoNCgUEBgIAARIEtgIMFgoNCgUEBgIAAxIEtgIZGgoNCgUE
BgIACBIEtgIbQwoQCggEBgIACJwIABIEtgIcQgrYAQoEBAYCARIEvQICLBrJASBJbmRpY2F0
ZXMgd2hpY2ggZmllbGRzIGluIHRoZSBwcm92aWRlZAogW0RhdGFTdG9yZV1bZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3JlXSB0byB1cGRhdGUuCgogSWYg
YW4gdW5zdXBwb3J0ZWQgb3IgdW5rbm93biBmaWVsZCBpcyBwcm92aWRlZCwgYW4gSU5WQUxJ
RF9BUkdVTUVOVCBlcnJvcgogaXMgcmV0dXJuZWQuCgoNCgUEBgIBBhIEvQICGwoNCgUEBgIB
ARIEvQIcJwoNCgUEBgIBAxIEvQIqKwr5AQoCBAcSBsQCAMsCARrqASBNZXRhZGF0YSByZWxh
dGVkIHRvIHRoZSBwcm9ncmVzcyBvZiB0aGUKIFtEYXRhU3RvcmVTZXJ2aWNlLkRlbGV0ZURh
dGFTdG9yZV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuRGF0YVN0b3Jl
U2VydmljZS5EZWxldGVEYXRhU3RvcmVdCiBvcGVyYXRpb24uIFRoaXMgd2lsbCBiZSByZXR1
cm5lZCBieSB0aGUgZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbi5tZXRhZGF0YQogZmll
bGQuCgoLCgMEBwESBMQCCB8KJgoEBAcCABIExgICLBoYIE9wZXJhdGlvbiBjcmVhdGUgdGlt
ZS4KCg0KBQQHAgAGEgTGAgIbCg0KBQQHAgABEgTGAhwnCg0KBQQHAgADEgTGAiorCmQKBAQH
AgESBMoCAiwaViBPcGVyYXRpb24gbGFzdCB1cGRhdGUgdGltZS4gSWYgdGhlIG9wZXJhdGlv
biBpcyBkb25lLCB0aGlzIGlzIGFsc28gdGhlCiBmaW5pc2ggdGltZS4KCg0KBQQHAgEGEgTK
AgIbCg0KBQQHAgEBEgTKAhwnCg0KBQQHAgEDEgTKAiorYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest ===
    # Fields for CreateDataStoreRequest
    # Field: cmek_config_name Type: 9 ()
    # Field: disable_cmek Type: 8 ()
    # Field: parent Type: 9 ()
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1beta.DataStore)
    # Field: data_store_id Type: 9 ()
    # Field: create_advanced_site_search Type: 8 ()
    # Field: skip_default_schema_creation Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::GetDataStoreRequest ===
    # Fields for GetDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreMetadata ===
    # Fields for CreateDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresRequest ===
    # Fields for ListDataStoresRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresResponse ===
    # Fields for ListDataStoresResponse
    # Field: data_stores Type: 11 (.google.cloud.discoveryengine.v1beta.DataStore)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::DeleteDataStoreRequest ===
    # Fields for DeleteDataStoreRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::UpdateDataStoreRequest ===
    # Fields for UpdateDataStoreRequest
    # Field: data_store Type: 11 (.google.cloud.discoveryengine.v1beta.DataStore)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1beta::DataStoreService::DeleteDataStoreMetadata ===
    # Fields for DeleteDataStoreMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::DataStoreService::DataStoreServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::DataStoreService::DataStoreServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::DataStoreService::DataStoreServiceClient

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
        ? Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'CreateDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DataStoreService::GetDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'GetDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore',
    });
}

sub list_data_stores {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'ListDataStores',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresResponse',
    });
}

sub delete_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DataStoreService::DeleteDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'DeleteDataStore',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_data_store {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::DataStoreService::UpdateDataStoreRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.DataStoreService',
        method         => 'UpdateDataStore',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::DataStoreService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/data_store_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::DataStoreService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest->new({
        cmek_config_name => $cmek_config_name,
        disable_cmek => $disable_cmek,
        parent => $parent,
        data_store => $data_store,
    });

    # Read or update a field
    my $val = $msg->cmek_config_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/data_store_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreRequest

Request for
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.CreateDataStore]
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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1beta.DataStore] to
create.

=item * C<< $msg->data_store_id() >> / C<< $msg->data_store_id($value) >>

Type: C<String>

Required. The ID to use for the
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], which will
become the final component of the
[DataStore][google.cloud.discoveryengine.v1beta.DataStore]'s resource name.

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

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::GetDataStoreRequest

Request message for
[DataStoreService.GetDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.GetDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to access the
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested [DataStore][google.cloud.discoveryengine.v1beta.DataStore]
does not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::CreateDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.CreateDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.CreateDataStore]
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

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresRequest

Request message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1beta.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/collections/{collection_id}`.

If the caller does not have permission to list
[DataStore][google.cloud.discoveryengine.v1beta.DataStore]s under this
location, regardless of whether or not this data store exists, a
PERMISSION_DENIED error is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of
[DataStore][google.cloud.discoveryengine.v1beta.DataStore]s to return. If
unspecified, defaults to 10. The maximum allowed value is 50. Values above
50 will be coerced to 50.

If this field is negative, an INVALID_ARGUMENT is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token
[ListDataStoresResponse.next_page_token][google.cloud.discoveryengine.v1beta.ListDataStoresResponse.next_page_token],
received from a previous
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1beta.DataStoreService.ListDataStores]
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1beta.DataStoreService.ListDataStores]
must match the call that provided the page token. Otherwise, an
INVALID_ARGUMENT error is returned.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Filter by solution type .
For example: `filter = 'solution_type:SOLUTION_TYPE_SEARCH'`

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::ListDataStoresResponse

Response message for
[DataStoreService.ListDataStores][google.cloud.discoveryengine.v1beta.DataStoreService.ListDataStores]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_stores() >> / C<< $msg->data_stores($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore>)

All the customer's
[DataStore][google.cloud.discoveryengine.v1beta.DataStore]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as
[ListDataStoresRequest.page_token][google.cloud.discoveryengine.v1beta.ListDataStoresRequest.page_token]
to retrieve the next page. If this field is omitted, there are no
subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::DeleteDataStoreRequest

Request message for
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.DeleteDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], such as
`projects/{project}/locations/{location}/collections/{collection_id}/dataStores/{data_store_id}`.

If the caller does not have permission to delete the
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1beta.DataStore] to delete
does not exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::UpdateDataStoreRequest

Request message for
[DataStoreService.UpdateDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.UpdateDataStore]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_store() >> / C<< $msg->data_store($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::DataStore::DataStore>)

Required. The [DataStore][google.cloud.discoveryengine.v1beta.DataStore] to
update.

If the caller does not have permission to update the
[DataStore][google.cloud.discoveryengine.v1beta.DataStore], regardless of
whether or not it exists, a PERMISSION_DENIED error is returned.

If the [DataStore][google.cloud.discoveryengine.v1beta.DataStore] to update
does not exist, a NOT_FOUND error is returned.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[DataStore][google.cloud.discoveryengine.v1beta.DataStore] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::DataStoreService::DeleteDataStoreMetadata

Metadata related to the progress of the
[DataStoreService.DeleteDataStore][google.cloud.discoveryengine.v1beta.DataStoreService.DeleteDataStore]
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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::DataStoreService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
