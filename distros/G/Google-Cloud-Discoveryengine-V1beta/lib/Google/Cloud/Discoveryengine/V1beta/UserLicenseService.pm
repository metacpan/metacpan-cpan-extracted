package Google::Cloud::Discoveryengine::V1beta::UserLicenseService;

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
    eval { require Google::Cloud::Discoveryengine::V1beta::UserLicense };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX2xpY2Vuc2Vfc2Vy
dmljZS5wcm90bxIjZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEaHGdvb2ds
ZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjZnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS91c2VyX2xpY2Vuc2UucHJv
dG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGiBnb29nbGUvcHJvdG9i
dWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoX
Z29vZ2xlL3JwYy9zdGF0dXMucHJvdG8i5gEKF0xpc3RVc2VyTGljZW5zZXNSZXF1ZXN0EkgK
BnBhcmVudBgBIAEoCUIw4EEC+kEqCihkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb20v
VXNlclN0b3JlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSKZAQoYTGlzdFVzZXJM
aWNlbnNlc1Jlc3BvbnNlElUKDXVzZXJfbGljZW5zZXMYASADKAsyMC5nb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyTGljZW5zZVIMdXNlckxpY2Vuc2VzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJvCiNMaXN0TGljZW5zZUNvbmZp
Z3NVc2FnZVN0YXRzUmVxdWVzdBJICgZwYXJlbnQYASABKAlCMOBBAvpBKgooZGlzY292ZXJ5
ZW5naW5lLmdvb2dsZWFwaXMuY29tL1VzZXJTdG9yZVIGcGFyZW50IqEBCiRMaXN0TGljZW5z
ZUNvbmZpZ3NVc2FnZVN0YXRzUmVzcG9uc2USeQoabGljZW5zZV9jb25maWdfdXNhZ2Vfc3Rh
dHMYASADKAsyPC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNlbnNl
Q29uZmlnVXNhZ2VTdGF0c1IXbGljZW5zZUNvbmZpZ1VzYWdlU3RhdHMi6AMKHkJhdGNoVXBk
YXRlVXNlckxpY2Vuc2VzUmVxdWVzdBJ3Cg1pbmxpbmVfc291cmNlGAIgASgLMlAuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNS
ZXF1ZXN0LklubGluZVNvdXJjZUgAUgxpbmxpbmVTb3VyY2USSAoGcGFyZW50GAEgASgJQjDg
QQL6QSoKKGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9Vc2VyU3RvcmVSBnBhcmVu
dBJKCh9kZWxldGVfdW5hc3NpZ25lZF91c2VyX2xpY2Vuc2VzGAQgASgIQgPgQQFSHGRlbGV0
ZVVuYXNzaWduZWRVc2VyTGljZW5zZXMarAEKDElubGluZVNvdXJjZRJaCg11c2VyX2xpY2Vu
c2VzGAEgAygLMjAuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuVXNlckxp
Y2Vuc2VCA+BBAlIMdXNlckxpY2Vuc2VzEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xl
LnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrQggKBnNvdXJjZSLlAQofQmF0
Y2hVcGRhdGVVc2VyTGljZW5zZXNNZXRhZGF0YRI7CgtjcmVhdGVfdGltZRgBIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYAiAB
KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEiMKDXN1Y2Nlc3Nf
Y291bnQYAyABKANSDHN1Y2Nlc3NDb3VudBIjCg1mYWlsdXJlX2NvdW50GAQgASgDUgxmYWls
dXJlQ291bnQisQEKH0JhdGNoVXBkYXRlVXNlckxpY2Vuc2VzUmVzcG9uc2USVQoNdXNlcl9s
aWNlbnNlcxgBIAMoCzIwLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVz
ZXJMaWNlbnNlUgx1c2VyTGljZW5zZXMSNwoNZXJyb3Jfc2FtcGxlcxgCIAMoCzISLmdvb2ds
ZS5ycGMuU3RhdHVzUgxlcnJvclNhbXBsZXMyyggKElVzZXJMaWNlbnNlU2VydmljZRLjAQoQ
TGlzdFVzZXJMaWNlbnNlcxI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRh
Lkxpc3RVc2VyTGljZW5zZXNSZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2lu
ZS52MWJldGEuTGlzdFVzZXJMaWNlbnNlc1Jlc3BvbnNlIlKC0+STAkMSQS92MWJldGEve3Bh
cmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3VzZXJTdG9yZXMvKn0vdXNlckxpY2Vuc2Vz
2kEGcGFyZW50EpMCChxMaXN0TGljZW5zZUNvbmZpZ3NVc2FnZVN0YXRzEkguZ29vZ2xlLmNs
b3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuTGlzdExpY2Vuc2VDb25maWdzVXNhZ2VTdGF0
c1JlcXVlc3QaSS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaXN0TGlj
ZW5zZUNvbmZpZ3NVc2FnZVN0YXRzUmVzcG9uc2UiXoLT5JMCTxJNL3YxYmV0YS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovdXNlclN0b3Jlcy8qfS9saWNlbnNlQ29uZmlnc1Vz
YWdlU3RhdHPaQQZwYXJlbnQS5QIKF0JhdGNoVXBkYXRlVXNlckxpY2Vuc2VzEkMuZ29vZ2xl
LmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiLlAYLT5JMCUSJML3YxYmV0
YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovdXNlclN0b3Jlcy8qfTpiYXRjaFVw
ZGF0ZVVzZXJMaWNlbnNlczoBKspBigEKQ2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUu
djFiZXRhLkJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzUmVzcG9uc2USQ2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLkJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzTWV0YWRhdGEa
zwHKQR5kaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5jb23SQaoBaHR0cHM6Ly93d3cuZ29v
Z2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlz
LmNvbS9hdXRoL2Rpc2NvdmVyeWVuZ2luZS5yZWFkd3JpdGUsaHR0cHM6Ly93d3cuZ29vZ2xl
YXBpcy5jb20vYXV0aC9kaXNjb3ZlcnllbmdpbmUuc2VydmluZy5yZWFkd3JpdGVCngIKJ2Nv
bS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YUIXVXNlckxpY2Vuc2VTZXJ2
aWNlUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFi
ZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5H
SU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMUJldGHKAiNHb29nbGVcQ2xv
dWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVu
Z2luZTo6VjFiZXRhSvc/CgcSBQ4A+wEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAQAoJCgIDBRIDFwAtCgkKAgMGEgMYACoKCQoCAwcSAxkAKQoJCgID
CBIDGgAhCggKAQgSAxwAQAoJCgIIJRIDHABACggKAQgSAx0AaAoJCgIICxIDHQBoCggKAQgS
Ax4AIgoJCgIIChIDHgAiCggKAQgSAx8AOAoJCgIICBIDHwA4CggKAQgSAyAAQAoJCgIIARID
IABACggKAQgSAyEALQoJCgIIJBIDIQAtCggKAQgSAyIAQAoJCgIIKRIDIgBACggKAQgSAyMA
PwoJCgIILRIDIwA/CjEKAgYAEgQmAE4BGiUgU2VydmljZSBmb3IgbWFuYWdpbmcgVXNlciBM
aWNlbnNlcy4KCgoKAwYAARIDJggaCgoKAwYAAxIDJwJGCgwKBQYAA5kIEgMnAkYKCwoDBgAD
EgQoAitKCg0KBQYAA5oIEgQoAitKCigKBAYAAgASBC4CNAMaGiBMaXN0cyB0aGUgVXNlciBM
aWNlbnNlcy4KCgwKBQYAAgABEgMuBhYKDAoFBgACAAISAy4XLgoMCgUGAAIAAxIDLw8nCg0K
BQYAAgAEEgQwBDIGChEKCQYAAgAEsMq8IhIEMAQyBgoMCgUGAAIABBIDMwQ0Cg8KCAYAAgAE
mwgAEgMzBDQKlQEKBAYAAgESBDkCPwMahgEgTGlzdHMgYWxsIHRoZQogW0xpY2Vuc2VDb25m
aWdVc2FnZVN0YXRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5MaWNl
bnNlQ29uZmlnVXNhZ2VTdGF0c11zCiBhc3NvY2lhdGVkIHdpdGggdGhlIHByb2plY3QuCgoM
CgUGAAIBARIDOQYiCgwKBQYAAgECEgM5I0YKDAoFBgACAQMSAzoPMwoNCgUGAAIBBBIEOwQ9
BgoRCgkGAAIBBLDKvCISBDsEPQYKDAoFBgACAQQSAz4ENAoPCggGAAIBBJsIABIDPgQ0CmsK
BAYAAgISBEMCTQMaXSBVcGRhdGVzIHRoZSBVc2VyIExpY2Vuc2UuCiBUaGlzIG1ldGhvZCBp
cyB1c2VkIGZvciBiYXRjaCBhc3NpZ24vdW5hc3NpZ24gbGljZW5zZXMgdG8gdXNlcnMuCgoM
CgUGAAICARIDQwYdCgwKBQYAAgICEgNDHjwKDAoFBgACAgMSA0QPKwoNCgUGAAICBBIERQRI
BgoRCgkGAAICBLDKvCISBEUESAYKDQoFBgACAgQSBEkETAYKDwoHBgACAgSZCBIESQRMBgqU
AQoCBAASBVIAkAEBGoYBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtVc2VyTGljZW5zZVNlcnZp
Y2UuTGlzdFVzZXJMaWNlbnNlc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJl
dGEuVXNlckxpY2Vuc2VTZXJ2aWNlLkxpc3RVc2VyTGljZW5zZXNdLgoKCgoDBAABEgNSCB8K
wAEKBAQAAgASBFcCXAQasQEgUmVxdWlyZWQuIFRoZSBwYXJlbnQKIFtVc2VyU3RvcmVdW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJTdG9yZV0gcmVzb3VyY2Ug
bmFtZSwKIGZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vdXNlclN0b3Jlcy97dXNlcl9zdG9yZV9pZH1gLgoKDAoFBAACAAUSA1cCCAoMCgUEAAIA
ARIDVwkPCgwKBQQAAgADEgNXEhMKDQoFBAACAAgSBFcUXAMKDwoIBAACAAicCAASA1gEKgoP
CgcEAAIACJ8IEgRZBFsFCoICCgQEAAIBEgNjAj8a9AEgT3B0aW9uYWwuIFJlcXVlc3RlZCBw
YWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1zIHRoYW4KIHJlcXVlc3Rl
ZC4gSWYgdW5zcGVjaWZpZWQsIGRlZmF1bHRzIHRvIDEwLiBUaGUgbWF4aW11bSB2YWx1ZSBp
cyA1MDsgdmFsdWVzCiBhYm92ZSA1MCB3aWxsIGJlIGNvZXJjZWQgdG8gNTAuCgogSWYgdGhp
cyBmaWVsZCBpcyBuZWdhdGl2ZSwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcyByZXR1
cm5lZC4KCgwKBQQAAgEFEgNjAgcKDAoFBAACAQESA2MIEQoMCgUEAAIBAxIDYxQVCgwKBQQA
AgEIEgNjFj4KDwoIBAACAQicCAASA2MXPQqCAgoEBAACAhIDagJBGvQBIE9wdGlvbmFsLiBB
IHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdFVzZXJMaWNlbnNl
c2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdl
LgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8g
YExpc3RVc2VyTGljZW5zZXNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQg
dGhlIHBhZ2UgdG9rZW4uCgoMCgUEAAICBRIDagIICgwKBQQAAgIBEgNqCRMKDAoFBAACAgMS
A2oWFwoMCgUEAAICCBIDahhACg8KCAQAAgIInAgAEgNqGT8K6AQKBAQAAgMSA30CPRraBCBP
cHRpb25hbC4gRmlsdGVyIGZvciB0aGUgbGlzdCByZXF1ZXN0LgoKIFN1cHBvcnRlZCBmaWVs
ZHM6CgogKiBgbGljZW5zZV9hc3NpZ25tZW50X3N0YXRlYAogKiBgdXNlcl9wcmluY2lwYWxg
CiAqCiBFeGFtcGxlczoKCiAqIGBsaWNlbnNlX2Fzc2lnbm1lbnRfc3RhdGUgPSBBU1NJR05F
RGAgdG8gbGlzdCBhc3NpZ25lZCB1c2VyIGxpY2Vuc2VzLgogKiBgbGljZW5zZV9hc3NpZ25t
ZW50X3N0YXRlID0gTk9fTElDRU5TRWAgdG8gbGlzdCBub3QgbGljZW5zZWQgdXNlcnMuCiAq
IGBsaWNlbnNlX2Fzc2lnbm1lbnRfc3RhdGUgPSBOT19MSUNFTlNFX0FUVEVNUFRFRF9MT0dJ
TmAgdG8gbGlzdCB1c2Vycwogd2hvIGF0dGVtcHRlZCBsb2dpbiBidXQgbm8gbGljZW5zZSBh
c3NpZ25lZC4KICogYGxpY2Vuc2VfYXNzaWdubWVudF9zdGF0ZSAhPSBOT19MSUNFTlNFX0FU
VEVNUFRFRF9MT0dJTmAgdG8gZmlsdGVyCiBvdXQgdXNlcnMgd2hvIGF0dGVtcHRlZCBsb2dp
biBidXQgbm8gbGljZW5zZSBhc3NpZ25lZC4KICogYHVzZXJfcHJpbmNpcGFsID0gdXNlcjFA
ZXhhbXBsZS5jb21gIHRvIGxpc3QgdXNlciBsaWNlbnNlIGZvcgogYHVzZXIxQGV4YW1wbGUu
Y29tYC4KCgwKBQQAAgMFEgN9AggKDAoFBAACAwESA30JDwoMCgUEAAIDAxIDfRITCgwKBQQA
AgMIEgN9FDwKDwoIBAACAwicCAASA30VOwqFBQoEBAACBBIEjwECPxr2BCBPcHRpb25hbC4g
VGhlIG9yZGVyIGluIHdoaWNoIHRoZQogW1VzZXJMaWNlbnNlXVtnb29nbGUuY2xvdWQuZGlz
Y292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyTGljZW5zZV1zIGFyZSBsaXN0ZWQuCiBUaGUgdmFs
dWUgbXVzdCBiZSBhIGNvbW1hLXNlcGFyYXRlZCBsaXN0IG9mIGZpZWxkcy4gRGVmYXVsdCBz
b3J0aW5nIG9yZGVyCiBpcyBhc2NlbmRpbmcuIFRvIHNwZWNpZnkgZGVzY2VuZGluZyBvcmRl
ciBmb3IgYSBmaWVsZCwgYXBwZW5kIGEgIiBkZXNjIgogc3VmZml4LiBSZWR1bmRhbnQgc3Bh
Y2UgY2hhcmFjdGVycyBpbiB0aGUgc3ludGF4IGFyZSBpbnNpZ25pZmljYW50LgoKIFN1cHBv
cnRlZCBmaWVsZHMgKG9ubHkgYHVzZXJfcHJpbmNpcGFsYCBpcyBzdXBwb3J0ZWQgZm9yIG5v
dyk6CgogKiBgdXNlcl9wcmluY2lwYWxgCgogSWYgbm90IHNldCwgdGhlIGRlZmF1bHQgb3Jk
ZXJpbmcgaXMgYnkgYHVzZXJfcHJpbmNpcGFsYC4KCiBFeGFtcGxlczoKCiAqIGB1c2VyX3By
aW5jaXBhbGAgdG8gb3JkZXIgYnkgYHVzZXJfcHJpbmNpcGFsYCBpbiBhc2NlbmRpbmcgb3Jk
ZXIuCiAqIGB1c2VyX3ByaW5jaXBhbCBkZXNjYCB0byBvcmRlciBieSBgdXNlcl9wcmluY2lw
YWxgIGluIGRlc2NlbmRpbmcgb3JkZXIuCgoNCgUEAAIEBRIEjwECCAoNCgUEAAIEARIEjwEJ
EQoNCgUEAAIEAxIEjwEUFQoNCgUEAAIECBIEjwEWPgoQCggEAAIECJwIABIEjwEXPQqWAQoC
BAESBpQBAJwBARqHASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW1VzZXJMaWNlbnNlU2Vydmlj
ZS5MaXN0VXNlckxpY2Vuc2VzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0
YS5Vc2VyTGljZW5zZVNlcnZpY2UuTGlzdFVzZXJMaWNlbnNlc10uCgoLCgMEAQESBJQBCCAK
ZAoEBAECABIElwECKRpWIEFsbCB0aGUgY3VzdG9tZXIncwogW1VzZXJMaWNlbnNlXVtnb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyTGljZW5zZV1zLgoKDQoFBAEC
AAQSBJcBAgoKDQoFBAECAAYSBJcBCxYKDQoFBAECAAESBJcBFyQKDQoFBAECAAMSBJcBJygK
kAEKBAQBAgESBJsBAh0agQEgQSB0b2tlbiwgd2hpY2ggY2FuIGJlIHNlbnQgYXMgYHBhZ2Vf
dG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2UuIElmCiB0aGlzIGZpZWxkIGlzIG9t
aXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBhZ2VzLgoKDQoFBAECAQUSBJsBAggK
DQoFBAECAQESBJsBCRgKDQoFBAECAQMSBJsBGxwKtQEKAgQCEgahAQCqAQEapgEgUmVxdWVz
dCBtZXNzYWdlIGZvcgogW1VzZXJMaWNlbnNlU2VydmljZS5MaXN0TGljZW5zZUNvbmZpZ3NV
c2FnZVN0YXRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5Vc2VyTGlj
ZW5zZVNlcnZpY2UuTGlzdExpY2Vuc2VDb25maWdzVXNhZ2VTdGF0c10KIG1ldGhvZC4KCgsK
AwQCARIEoQEIKwqLAQoEBAICABIGpAECqQEEGnsgUmVxdWlyZWQuIFRoZSBwYXJlbnQgYnJh
bmNoIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn0vdXNlclN0b3Jlcy97dXNlcl9zdG9yZV9pZH1gLgoKDQoFBAICAAUS
BKQBAggKDQoFBAICAAESBKQBCQ8KDQoFBAICAAMSBKQBEhMKDwoFBAICAAgSBqQBFKkBAwoQ
CggEAgIACJwIABIEpQEEKgoRCgcEAgIACJ8IEgamAQSoAQUKtgEKAgQDEgavAQCzAQEapwEg
UmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtVc2VyTGljZW5zZVNlcnZpY2UuTGlzdExpY2Vuc2VD
b25maWdzVXNhZ2VTdGF0c11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
VXNlckxpY2Vuc2VTZXJ2aWNlLkxpc3RMaWNlbnNlQ29uZmlnc1VzYWdlU3RhdHNdCiBtZXRo
b2QuCgoLCgMEAwESBK8BCCwKewoEBAMCABIEsgECQhptIEFsbCB0aGUgY3VzdG9tZXIncwog
W0xpY2Vuc2VDb25maWdVc2FnZVN0YXRzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxYmV0YS5MaWNlbnNlQ29uZmlnVXNhZ2VTdGF0c10uCgoNCgUEAwIABBIEsgECCgoNCgUE
AwIABhIEsgELIgoNCgUEAwIAARIEsgEjPQoNCgUEAwIAAxIEsgFAQQqrAQoCBAQSBrgBAN0B
ARqcASBSZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbVXNlckxpY2Vuc2VTZXJ2aWNlLkJhdGNoVXBk
YXRlVXNlckxpY2Vuc2VzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YS5V
c2VyTGljZW5zZVNlcnZpY2UuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNdCiBtZXRob2QuCgoL
CgMEBAESBLgBCCYKXQoEBAQDABIGuwECxQEDGk0gVGhlIGlubGluZSBzb3VyY2UgZm9yIHRo
ZSBpbnB1dCBjb25maWcgZm9yIEJhdGNoVXBkYXRlVXNlckxpY2Vuc2VzCiBtZXRob2QuCgoN
CgUEBAMAARIEuwEKFgrFAQoGBAQDAAIAEga/AQTAATEasgEgUmVxdWlyZWQuIEEgbGlzdCBv
ZiB1c2VyIGxpY2Vuc2VzIHRvIHVwZGF0ZS4gRWFjaCB1c2VyIGxpY2Vuc2UKIG11c3QgaGF2
ZSBhIHZhbGlkCiBbVXNlckxpY2Vuc2UudXNlcl9wcmluY2lwYWxdW2dvb2dsZS5jbG91ZC5k
aXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJMaWNlbnNlLnVzZXJfcHJpbmNpcGFsXS4KCg8K
BwQEAwACAAQSBL8BBAwKDwoHBAQDAAIABhIEvwENGAoPCgcEBAMAAgABEgS/ARkmCg8KBwQE
AwACAAMSBL8BKSoKDwoHBAQDAAIACBIEwAEIMAoSCgoEBAMAAgAInAgAEgTAAQkvCjsKBgQE
AwACARIGwwEExAExGikgT3B0aW9uYWwuIFRoZSBsaXN0IG9mIGZpZWxkcyB0byB1cGRhdGUu
CgoPCgcEBAMAAgEGEgTDAQQdCg8KBwQEAwACAQESBMMBHikKDwoHBAQDAAIBAxIEwwEsLQoP
CgcEBAMAAgEIEgTEAQgwChIKCgQEAwACAQicCAASBMQBCS8KNAoEBAQIABIGyAECywEDGiQg
UmVxdWlyZWQuIFRoZSBzb3VyY2Ugb2YgdGhlIGlucHV0LgoKDQoFBAQIAAESBMgBCA4KUAoE
BAQCABIEygEEIxpCIFRoZSBpbmxpbmUgc291cmNlIGZvciB0aGUgaW5wdXQgY29udGVudCBm
b3IgZG9jdW1lbnQgZW1iZWRkaW5ncy4KCg0KBQQEAgAGEgTKAQQQCg0KBQQEAgABEgTKAREe
Cg0KBQQEAgADEgTKASEiCsIBCgQEBAIBEgbRAQLWAQQasQEgUmVxdWlyZWQuIFRoZSBwYXJl
bnQKIFtVc2VyU3RvcmVdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVz
ZXJTdG9yZV0gcmVzb3VyY2UgbmFtZSwKIGZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vdXNlclN0b3Jlcy97dXNlcl9zdG9yZV9pZH1gLgoKDQoF
BAQCAQUSBNEBAggKDQoFBAQCAQESBNEBCQ8KDQoFBAQCAQMSBNEBEhMKDwoFBAQCAQgSBtEB
FNYBAwoQCggEBAIBCJwIABIE0gEEKgoRCgcEBAIBCJ8IEgbTAQTVAQUKzgEKBAQEAgISBtsB
AtwBLxq9ASBPcHRpb25hbC4gSWYgdHJ1ZSwgaWYgdXNlciBsaWNlbnNlcyByZW1vdmVkIGFz
c29jaWF0ZWQgbGljZW5zZSBjb25maWcsIHRoZQogdXNlciBsaWNlbnNlIHdpbGwgYmUgZGVs
ZXRlZC4gQnkgZGVmYXVsdCB3aGljaCBpcyBmYWxzZSwgdGhlIHVzZXIgbGljZW5zZQogd2ls
bCBiZSB1cGRhdGVkIHRvIHVuYXNzaWduZWQgc3RhdGUuCgoNCgUEBAICBRIE2wECBgoNCgUE
BAICARIE2wEHJgoNCgUEBAICAxIE2wEpKgoNCgUEBAICCBIE3AEGLgoQCggEBAICCJwIABIE
3AEHLQqNAgoCBAUSBuMBAPABARr+ASBNZXRhZGF0YSByZWxhdGVkIHRvIHRoZSBwcm9ncmVz
cyBvZiB0aGUKIFtVc2VyTGljZW5zZVNlcnZpY2UuQmF0Y2hVcGRhdGVVc2VyTGljZW5zZXNd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVzZXJMaWNlbnNlU2Vydmlj
ZS5CYXRjaFVwZGF0ZVVzZXJMaWNlbnNlc10KIG9wZXJhdGlvbi4gVGhpcyB3aWxsIGJlIHJl
dHVybmVkIGJ5IHRoZSBnb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uLm1ldGFkYXRhCiBm
aWVsZC4KCgsKAwQFARIE4wEIJwomCgQEBQIAEgTlAQIsGhggT3BlcmF0aW9uIGNyZWF0ZSB0
aW1lLgoKDQoFBAUCAAYSBOUBAhsKDQoFBAUCAAESBOUBHCcKDQoFBAUCAAMSBOUBKisKZAoE
BAUCARIE6QECLBpWIE9wZXJhdGlvbiBsYXN0IHVwZGF0ZSB0aW1lLiBJZiB0aGUgb3BlcmF0
aW9uIGlzIGRvbmUsIHRoaXMgaXMgYWxzbyB0aGUKIGZpbmlzaCB0aW1lLgoKDQoFBAUCAQYS
BOkBAhsKDQoFBAUCAQESBOkBHCcKDQoFBAUCAQMSBOkBKisKPAoEBAUCAhIE7AECGhouIENv
dW50IG9mIHVzZXIgbGljZW5zZXMgc3VjY2Vzc2Z1bGx5IHVwZGF0ZWQuCgoNCgUEBQICBRIE
7AECBwoNCgUEBQICARIE7AEIFQoNCgUEBQICAxIE7AEYGQpBCgQEBQIDEgTvAQIaGjMgQ291
bnQgb2YgdXNlciBsaWNlbnNlcyB0aGF0IGZhaWxlZCB0byBiZSB1cGRhdGVkLgoKDQoFBAUC
AwUSBO8BAgcKDQoFBAUCAwESBO8BCBUKDQoFBAUCAwMSBO8BGBkKrAEKAgQGEgb1AQD7AQEa
nQEgUmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtVc2VyTGljZW5zZVNlcnZpY2UuQmF0Y2hVcGRh
dGVVc2VyTGljZW5zZXNdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLlVz
ZXJMaWNlbnNlU2VydmljZS5CYXRjaFVwZGF0ZVVzZXJMaWNlbnNlc10KIG1ldGhvZC4KCgsK
AwQGARIE9QEIJwoyCgQEBgIAEgT3AQIpGiQgVXNlckxpY2Vuc2VzIHN1Y2Nlc3NmdWxseSB1
cGRhdGVkLgoKDQoFBAYCAAQSBPcBAgoKDQoFBAYCAAYSBPcBCxYKDQoFBAYCAAESBPcBFyQK
DQoFBAYCAAMSBPcBJygKTAoEBAYCARIE+gECLxo+IEEgc2FtcGxlIG9mIGVycm9ycyBlbmNv
dW50ZXJlZCB3aGlsZSBwcm9jZXNzaW5nIHRoZSByZXF1ZXN0LgoKDQoFBAYCAQQSBPoBAgoK
DQoFBAYCAQYSBPoBCxwKDQoFBAYCAQESBPoBHSoKDQoFBAYCAQMSBPoBLS5iBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest ===
    # Fields for ListUserLicensesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse ===
    # Fields for ListUserLicensesResponse
    # Field: user_licenses Type: 11 (.google.cloud.discoveryengine.v1beta.UserLicense)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest ===
    # Fields for ListLicenseConfigsUsageStatsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse ===
    # Fields for ListLicenseConfigsUsageStatsResponse
    # Field: license_config_usage_stats Type: 11 (.google.cloud.discoveryengine.v1beta.LicenseConfigUsageStats)

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest ===
    # Fields for BatchUpdateUserLicensesRequest
    # Field: inline_source Type: 11 (.google.cloud.discoveryengine.v1beta.BatchUpdateUserLicensesRequest.InlineSource)
    # Field: parent Type: 9 ()
    # Field: delete_unassigned_user_licenses Type: 8 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesMetadata ===
    # Fields for BatchUpdateUserLicensesMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: success_count Type: 3 ()
    # Field: failure_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesResponse ===
    # Fields for BatchUpdateUserLicensesResponse
    # Field: user_licenses Type: 11 (.google.cloud.discoveryengine.v1beta.UserLicense)
    # Field: error_samples Type: 11 (.google.rpc.Status)

# === Service Client: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::UserLicenseServiceClient ===
package Google::Cloud::Discoveryengine::V1beta::UserLicenseService::UserLicenseServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1beta::UserLicenseService::UserLicenseServiceClient

Client stub representing the remote C<UserLicenseService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_user_licenses {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserLicenseService',
        method         => 'ListUserLicenses',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse',
    });
}

sub list_license_configs_usage_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserLicenseService',
        method         => 'ListLicenseConfigsUsageStats',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse',
    });
}

sub batch_update_user_licenses {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1beta.UserLicenseService',
        method         => 'BatchUpdateUserLicenses',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::UserLicenseService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/user_license_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::UserLicenseService;

    my $msg = Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
        filter => $filter,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/user_license_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesRequest

Request message for
[UserLicenseService.ListUserLicenses][google.cloud.discoveryengine.v1beta.UserLicenseService.ListUserLicenses].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent
[UserStore][google.cloud.discoveryengine.v1beta.UserStore] resource name,
format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, defaults to 10. The maximum value is 50; values
above 50 will be coerced to 50.

If this field is negative, an INVALID_ARGUMENT error is returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListUserLicenses` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListUserLicenses`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter for the list request.

Supported fields:

* `license_assignment_state`
* `user_principal`
*
Examples:

* `license_assignment_state = ASSIGNED` to list assigned user licenses.
* `license_assignment_state = NO_LICENSE` to list not licensed users.
* `license_assignment_state = NO_LICENSE_ATTEMPTED_LOGIN` to list users
who attempted login but no license assigned.
* `license_assignment_state != NO_LICENSE_ATTEMPTED_LOGIN` to filter
out users who attempted login but no license assigned.
* `user_principal = user1@example.com` to list user license for
`user1@example.com`.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. The order in which the
[UserLicense][google.cloud.discoveryengine.v1beta.UserLicense]s are listed.
The value must be a comma-separated list of fields. Default sorting order
is ascending. To specify descending order for a field, append a " desc"
suffix. Redundant space characters in the syntax are insignificant.

Supported fields (only `user_principal` is supported for now):

* `user_principal`

If not set, the default ordering is by `user_principal`.

Examples:

* `user_principal` to order by `user_principal` in ascending order.
* `user_principal desc` to order by `user_principal` in descending order.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListUserLicensesResponse

Response message for
[UserLicenseService.ListUserLicenses][google.cloud.discoveryengine.v1beta.UserLicenseService.ListUserLicenses].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_licenses() >> / C<< $msg->user_licenses($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense>)

All the customer's
[UserLicense][google.cloud.discoveryengine.v1beta.UserLicense]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page. If
this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsRequest

Request message for
[UserLicenseService.ListLicenseConfigsUsageStats][google.cloud.discoveryengine.v1beta.UserLicenseService.ListLicenseConfigsUsageStats]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::ListLicenseConfigsUsageStatsResponse

Response message for
[UserLicenseService.ListLicenseConfigsUsageStats][google.cloud.discoveryengine.v1beta.UserLicenseService.ListLicenseConfigsUsageStats]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config_usage_stats() >> / C<< $msg->license_config_usage_stats($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserLicense::LicenseConfigUsageStats>)

All the customer's
[LicenseConfigUsageStats][google.cloud.discoveryengine.v1beta.LicenseConfigUsageStats].

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest

Request message for
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1beta.UserLicenseService.BatchUpdateUserLicenses]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->inline_source() >> / C<< $msg->inline_source($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesRequest::InlineSource>)

The inline source for the input content for document embeddings.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent
[UserStore][google.cloud.discoveryengine.v1beta.UserStore] resource name,
format:
`projects/{project}/locations/{location}/userStores/{user_store_id}`.

=item * C<< $msg->delete_unassigned_user_licenses() >> / C<< $msg->delete_unassigned_user_licenses($value) >>

Type: C<Bool>

Optional. If true, if user licenses removed associated license config, the
user license will be deleted. By default which is false, the user license
will be updated to unassigned state.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesMetadata

Metadata related to the progress of the
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1beta.UserLicenseService.BatchUpdateUserLicenses]
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

=item * C<< $msg->success_count() >> / C<< $msg->success_count($value) >>

Type: C<Int64>

Count of user licenses successfully updated.

=item * C<< $msg->failure_count() >> / C<< $msg->failure_count($value) >>

Type: C<Int64>

Count of user licenses that failed to be updated.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::UserLicenseService::BatchUpdateUserLicensesResponse

Response message for
[UserLicenseService.BatchUpdateUserLicenses][google.cloud.discoveryengine.v1beta.UserLicenseService.BatchUpdateUserLicenses]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_licenses() >> / C<< $msg->user_licenses($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::UserLicense::UserLicense>)

UserLicenses successfully updated.

=item * C<< $msg->error_samples() >> / C<< $msg->error_samples($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

A sample of errors encountered while processing the request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::UserLicenseService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
