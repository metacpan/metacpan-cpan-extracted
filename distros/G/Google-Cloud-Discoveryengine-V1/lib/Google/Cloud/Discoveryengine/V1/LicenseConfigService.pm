package Google::Cloud::Discoveryengine::V1::LicenseConfigService;

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
    eval { require Google::Cloud::Discoveryengine::V1::LicenseConfig };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2xpY2Vuc2VfY29uZmlnX3NlcnZp
Y2UucHJvdG8SH2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaHGdvb2dsZS9hcGkv
YW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjRnb29n
bGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2xpY2Vuc2VfY29uZmlnLnByb3RvGiBnb29n
bGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90byLyAQoaQ3JlYXRlTGljZW5zZUNvbmZpZ1Jl
cXVlc3QSRwoGcGFyZW50GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVh
cGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EloKDmxpY2Vuc2VfY29uZmlnGAIgASgLMi4uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnQgPgQQJSDWxpY2Vu
c2VDb25maWcSLwoRbGljZW5zZV9jb25maWdfaWQYAyABKAlCA+BBAVIPbGljZW5zZUNvbmZp
Z0lkIroBChpVcGRhdGVMaWNlbnNlQ29uZmlnUmVxdWVzdBJaCg5saWNlbnNlX2NvbmZpZxgB
IAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ0ID
4EECUg1saWNlbnNlQ29uZmlnEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrImMKF0dldExpY2Vuc2VDb25maWdSZXF1
ZXN0EkgKBG5hbWUYASABKAlCNOBBAvpBLgosZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMu
Y29tL0xpY2Vuc2VDb25maWdSBG5hbWUixwEKGUxpc3RMaWNlbnNlQ29uZmlnc1JlcXVlc3QS
RwoGcGFyZW50GAEgASgJQi/gQQL6QSkKJ2Rpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9Mb2NhdGlvblIGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEBUghwYWdlU2l6ZRIi
CgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbhIbCgZmaWx0ZXIYBCABKAlCA+BB
AVIGZmlsdGVyIp0BChpMaXN0TGljZW5zZUNvbmZpZ3NSZXNwb25zZRJXCg9saWNlbnNlX2Nv
bmZpZ3MYASADKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VD
b25maWdSDmxpY2Vuc2VDb25maWdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBh
Z2VUb2tlbiLSAgoeRGlzdHJpYnV0ZUxpY2Vuc2VDb25maWdSZXF1ZXN0EocBCh5iaWxsaW5n
X2FjY291bnRfbGljZW5zZV9jb25maWcYASABKAlCQuBBAvpBPAo6ZGlzY292ZXJ5ZW5naW5l
Lmdvb2dsZWFwaXMuY29tL0JpbGxpbmdBY2NvdW50TGljZW5zZUNvbmZpZ1IbYmlsbGluZ0Fj
Y291bnRMaWNlbnNlQ29uZmlnEioKDnByb2plY3RfbnVtYmVyGAIgASgDQgPgQQJSDXByb2pl
Y3ROdW1iZXISHwoIbG9jYXRpb24YAyABKAlCA+BBAlIIbG9jYXRpb24SKAoNbGljZW5zZV9j
b3VudBgEIAEoA0ID4EECUgxsaWNlbnNlQ291bnQSLwoRbGljZW5zZV9jb25maWdfaWQYBSAB
KAlCA+BBAVIPbGljZW5zZUNvbmZpZ0lkIngKH0Rpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnUmVz
cG9uc2USVQoObGljZW5zZV9jb25maWcYASABKAsyLi5nb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkxpY2Vuc2VDb25maWdSDWxpY2Vuc2VDb25maWci1gIKG1JldHJhY3RMaWNl
bnNlQ29uZmlnUmVxdWVzdBKHAQoeYmlsbGluZ19hY2NvdW50X2xpY2Vuc2VfY29uZmlnGAEg
ASgJQkLgQQL6QTwKOmRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNvbS9CaWxsaW5nQWNj
b3VudExpY2Vuc2VDb25maWdSG2JpbGxpbmdBY2NvdW50TGljZW5zZUNvbmZpZxJbCg5saWNl
bnNlX2NvbmZpZxgCIAEoCUI04EEC+kEuCixkaXNjb3ZlcnllbmdpbmUuZ29vZ2xlYXBpcy5j
b20vTGljZW5zZUNvbmZpZ1INbGljZW5zZUNvbmZpZxImCgxmdWxsX3JldHJhY3QYAyABKAhC
A+BBAVILZnVsbFJldHJhY3QSKAoNbGljZW5zZV9jb3VudBgEIAEoA0ID4EEBUgxsaWNlbnNl
Q291bnQidQocUmV0cmFjdExpY2Vuc2VDb25maWdSZXNwb25zZRJVCg5saWNlbnNlX2NvbmZp
ZxgBIAEoCzIuLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZp
Z1INbGljZW5zZUNvbmZpZzLDDgoUTGljZW5zZUNvbmZpZ1NlcnZpY2US+AEKE0NyZWF0ZUxp
Y2Vuc2VDb25maWcSOy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkNyZWF0ZUxp
Y2Vuc2VDb25maWdSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5M
aWNlbnNlQ29uZmlnInSC0+STAkQiMi92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
Lyp9L2xpY2Vuc2VDb25maWdzOg5saWNlbnNlX2NvbmZpZ9pBJ3BhcmVudCxsaWNlbnNlX2Nv
bmZpZyxsaWNlbnNlX2NvbmZpZ19pZBL6AQoTVXBkYXRlTGljZW5zZUNvbmZpZxI7Lmdvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuVXBkYXRlTGljZW5zZUNvbmZpZ1JlcXVlc3Qa
Li5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VDb25maWcidoLT5JMC
UzJBL3YxL3tsaWNlbnNlX2NvbmZpZy5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovbGlj
ZW5zZUNvbmZpZ3MvKn06DmxpY2Vuc2VfY29uZmln2kEabGljZW5zZV9jb25maWcsdXBkYXRl
X21hc2sSvwEKEEdldExpY2Vuc2VDb25maWcSOC5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkdldExpY2Vuc2VDb25maWdSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnIkGC0+STAjQSMi92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2xpY2Vuc2VDb25maWdzLyp92kEEbmFtZRLSAQoSTGlzdExpY2Vuc2VD
b25maWdzEjouZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0TGljZW5zZUNv
bmZpZ3NSZXF1ZXN0GjsuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaXN0TGlj
ZW5zZUNvbmZpZ3NSZXNwb25zZSJDgtPkkwI0EjIvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qfS9saWNlbnNlQ29uZmlnc9pBBnBhcmVudBLwAgoXRGlzdHJpYnV0ZUxpY2Vu
c2VDb25maWcSPy5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkRpc3RyaWJ1dGVM
aWNlbnNlQ29uZmlnUmVxdWVzdBpALmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEu
RGlzdHJpYnV0ZUxpY2Vuc2VDb25maWdSZXNwb25zZSLRAYLT5JMCciJtL3YxL3tiaWxsaW5n
X2FjY291bnRfbGljZW5zZV9jb25maWc9YmlsbGluZ0FjY291bnRzLyovYmlsbGluZ0FjY291
bnRMaWNlbnNlQ29uZmlncy8qfTpkaXN0cmlidXRlTGljZW5zZUNvbmZpZzoBKtpBVmJpbGxp
bmdfYWNjb3VudF9saWNlbnNlX2NvbmZpZyxwcm9qZWN0X251bWJlcixsb2NhdGlvbixsaWNl
bnNlX2NvdW50LGxpY2Vuc2VfY29uZmlnX2lkEtYCChRSZXRyYWN0TGljZW5zZUNvbmZpZxI8
Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuUmV0cmFjdExpY2Vuc2VDb25maWdS
ZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5SZXRyYWN0TGljZW5z
ZUNvbmZpZ1Jlc3BvbnNlIsABgtPkkwJvImovdjEve2JpbGxpbmdfYWNjb3VudF9saWNlbnNl
X2NvbmZpZz1iaWxsaW5nQWNjb3VudHMvKi9iaWxsaW5nQWNjb3VudExpY2Vuc2VDb25maWdz
Lyp9OnJldHJhY3RMaWNlbnNlQ29uZmlnOgEq2kFIYmlsbGluZ19hY2NvdW50X2xpY2Vuc2Vf
Y29uZmlnLGxpY2Vuc2VfY29uZmlnLGZ1bGxfcmV0cmFjdCxsaWNlbnNlX2NvdW50Gs8BykEe
ZGlzY292ZXJ5ZW5naW5lLmdvb2dsZWFwaXMuY29t0kGqAWh0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9kaXNjb3ZlcnllbmdpbmUucmVhZHdyaXRlLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMu
Y29tL2F1dGgvZGlzY292ZXJ5ZW5naW5lLnNlcnZpbmcucmVhZHdyaXRlQowCCiNjb20uZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUIZTGljZW5zZUNvbmZpZ1NlcnZpY2VQcm90
b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVyeWVuZ2luZS9hcGl2MS9kaXNjb3Zl
cnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCH0dvb2ds
ZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjHKAh9Hb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5n
aW5lXFYx6gIiR29vZ2xlOjpDbG91ZDo6RGlzY292ZXJ5RW5naW5lOjpWMUrDSQoHEgUOALEC
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAD4KCQoCAwUS
AxcAKgoICgEIEgMZADwKCQoCCCUSAxkAPAoICgEIEgMaAGQKCQoCCAsSAxoAZAoICgEIEgMb
ACIKCQoCCAoSAxsAIgoICgEIEgMcADoKCQoCCAgSAxwAOgoICgEIEgMdADwKCQoCCAESAx0A
PAoICgEIEgMeAC0KCQoCCCQSAx4ALQoICgEIEgMfADwKCQoCCCkSAx8APAoICgEIEgMgADsK
CQoCCC0SAyAAOwpECgIGABIEIwBrARo4IFNlcnZpY2UgZm9yIG1hbmFnaW5nIGxpY2Vuc2Ug
Y29uZmlnIHJlbGF0ZWQgcmVzb3VyY2VzLgoKCgoDBgABEgMjCBwKCgoDBgADEgMkAkYKDAoF
BgADmQgSAyQCRgoLCgMGAAMSBCUCKEoKDQoFBgADmggSBCUCKEoKxgEKBAYAAgASBC0CNAMa
twEgQ3JlYXRlcyBhIFtMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkxpY2Vuc2VDb25maWddCiBUaGlzIG1ldGhvZCBzaG91bGQgb25seSBiZSB1c2Vk
IGZvciBjcmVhdGluZyBOb3RlYm9va0xtIGxpY2Vuc2VzIG9yIEdlbWluaQogRW50ZXJwcmlz
ZSBmcmVlIHRyaWFsIGxpY2Vuc2VzLgoKDAoFBgACAAESAy0GGQoMCgUGAAIAAhIDLRo0CgwK
BQYAAgADEgMtP0wKDQoFBgACAAQSBC4EMQYKEQoJBgACAASwyrwiEgQuBDEGCg0KBQYAAgAE
EgQyBDMyChAKCAYAAgAEmwgAEgQyBDMyCloKBAYAAgESBDcCPQMaTCBVcGRhdGVzIHRoZSBb
TGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNl
Q29uZmlnXQoKDAoFBgACAQESAzcGGQoMCgUGAAIBAhIDNxo0CgwKBQYAAgEDEgM3P0wKDQoF
BgACAQQSBDgEOwYKEQoJBgACAQSwyrwiEgQ4BDsGCgwKBQYAAgEEEgM8BEgKDwoIBgACAQSb
CAASAzwESApWCgQGAAICEgRAAkUDGkggR2V0cyBhIFtMaWNlbnNlQ29uZmlnXVtnb29nbGUu
Y2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VDb25maWddLgoKDAoFBgACAgESA0AG
FgoMCgUGAAICAhIDQBcuCgwKBQYAAgIDEgNAOUYKDQoFBgACAgQSBEEEQwYKEQoJBgACAgSw
yrwiEgRBBEMGCgwKBQYAAgIEEgNEBDIKDwoIBgACAgSbCAASA0QEMgp8CgQGAAIDEgRKAlAD
Gm4gTGlzdHMgYWxsIHRoZQogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ11zIGFzc29jaWF0ZWQKIHdpdGggdGhlIHByb2pl
Y3QuCgoMCgUGAAIDARIDSgYYCgwKBQYAAgMCEgNKGTIKDAoFBgACAwMSA0sPKQoNCgUGAAID
BBIETAROBgoRCgkGAAIDBLDKvCISBEwETgYKDAoFBgACAwQSA08ENAoPCggGAAIDBJsIABID
TwQ0CosBCgQGAAIEEgRVAl0DGn0gRGlzdHJpYnV0ZXMgYQogW0xpY2Vuc2VDb25maWddW2dv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ10gZnJvbSBiaWxs
aW5nCiBhY2NvdW50IGxldmVsIHRvIHByb2plY3QgbGV2ZWwuCgoMCgUGAAIEARIDVQYdCgwK
BQYAAgQCEgNVHjwKDAoFBgACBAMSA1YPLgoNCgUGAAIEBBIEVwRaBgoRCgkGAAIEBLDKvCIS
BFcEWgYKDQoFBgACBAQSBFsEXGEKEAoIBgACBASbCAASBFsEXGEKyAEKBAYAAgUSBGICagMa
uQEgVGhpcyBtZXRob2QgaXMgY2FsbGVkIGZyb20gdGhlIGJpbGxpbmcgYWNjb3VudCBzaWRl
IHRvIHJldHJhY3QgdGhlCiBbTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVy
eWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnXSBmcm9tIHRoZQogZ2l2ZW4gcHJvamVjdCBiYWNr
IHRvIHRoZSBiaWxsaW5nIGFjY291bnQuCgoMCgUGAAIFARIDYgYaCgwKBQYAAgUCEgNiGzYK
DAoFBgACBQMSA2MPKwoNCgUGAAIFBBIEZARnBgoRCgkGAAIFBLDKvCISBGQEZwYKDQoFBgAC
BQQSBGgEaVMKEAoIBgACBQSbCAASBGgEaVMKogEKAgQAEgVwAIUBARqUASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuQ3JlYXRlTGljZW5zZUNvbmZpZ11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnU2VydmljZS5D
cmVhdGVMaWNlbnNlQ29uZmlnXQogbWV0aG9kLgoKCgoDBAABEgNwCCIKZwoEBAACABIEcwJ4
BBpZIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9q
ZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDAoFBAACAAUSA3MCCAoM
CgUEAAIAARIDcwkPCgwKBQQAAgADEgNzEhMKDQoFBAACAAgSBHMUeAMKDwoIBAACAAicCAAS
A3QEKgoPCgcEAAIACJ8IEgR1BHcFCmcKBAQAAgESA3wCTBpaIFJlcXVpcmVkLiBUaGUKIFtM
aWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VD
b25maWddIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgN8Ag8KDAoFBAACAQESA3wQHgoMCgUEAAIB
AxIDfCEiCgwKBQQAAgEIEgN8I0sKDwoIBAACAQicCAASA3wkSgrkAgoEBAACAhIEhAECSBrV
AiBPcHRpb25hbC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlCiBbTGljZW5zZUNvbmZpZ11bZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnXSwgd2hpY2ggd2ls
bAogYmVjb21lIHRoZSBmaW5hbCBjb21wb25lbnQgb2YgdGhlCiBbTGljZW5zZUNvbmZpZ11b
Z29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnXSdzIHJlc291
cmNlCiBuYW1lLiBXZSBhcmUgdXNpbmcgdGhlIHRpZXIgKHByb2R1Y3QgZWRpdGlvbikgbmFt
ZSBhcyB0aGUgbGljZW5zZSBjb25maWcgaWQKIHN1Y2ggYXMgYHNlYXJjaGAgb3IgYHNlYXJj
aF9hbmRfYXNzaXN0YW50YC4KCg0KBQQAAgIFEgSEAQIICg0KBQQAAgIBEgSEAQkaCg0KBQQA
AgIDEgSEAR0eCg0KBQQAAgIIEgSEAR9HChAKCAQAAgIInAgAEgSEASBGCqMBCgIEARIGigEA
lgEBGpQBIFJlcXVlc3QgbWVzc2FnZSBmb3IKIFtMaWNlbnNlQ29uZmlnU2VydmljZS5VcGRh
dGVMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vu
c2VDb25maWdTZXJ2aWNlLlVwZGF0ZUxpY2Vuc2VDb25maWddCiBtZXRob2QuCgoLCgMEAQES
BIoBCCIKaAoEBAECABIEjQECTBpaIFJlcXVpcmVkLiBUaGUKIFtMaWNlbnNlQ29uZmlnXVtn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VDb25maWddIHRvIHVwZGF0
ZS4KCg0KBQQBAgAGEgSNAQIPCg0KBQQBAgABEgSNARAeCg0KBQQBAgADEgSNASEiCg0KBQQB
AgAIEgSNASNLChAKCAQBAgAInAgAEgSNASRKCugBCgQEAQIBEgaUAQKVAS8a1wEgT3B0aW9u
YWwuIEluZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbTGljZW5zZUNv
bmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnXSB0
byB1cGRhdGUuCgogSWYgYW4gdW5zdXBwb3J0ZWQgb3IgdW5rbm93biBmaWVsZCBpcyBwcm92
aWRlZCwgYW4gSU5WQUxJRF9BUkdVTUVOVCBlcnJvcgogaXMgcmV0dXJuZWQuCgoNCgUEAQIB
BhIElAECGwoNCgUEAQIBARIElAEcJwoNCgUEAQIBAxIElAEqKwoNCgUEAQIBCBIElQEGLgoQ
CggEAQIBCJwIABIElQEHLQqdAQoCBAISBpsBAK0BARqOASBSZXF1ZXN0IG1lc3NhZ2UgZm9y
CiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuR2V0TGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MS5MaWNlbnNlQ29uZmlnU2VydmljZS5HZXRMaWNlbnNlQ29u
ZmlnXQogbWV0aG9kLgoKCwoDBAIBEgSbAQgfCoMECgQEAgIAEganAQKsAQQa8gMgUmVxdWly
ZWQuIEZ1bGwgcmVzb3VyY2UgbmFtZSBvZgogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ10sIHN1Y2ggYXMKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbGljZW5zZUNvbmZpZ3MvKmAuCgog
SWYgdGhlIGNhbGxlciBkb2VzIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gYWNjZXNzIHRoZQog
W0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5z
ZUNvbmZpZ10sIHJlZ2FyZGxlc3MKIG9mIHdoZXRoZXIgb3Igbm90IGl0IGV4aXN0cywgYSBQ
RVJNSVNTSU9OX0RFTklFRCBlcnJvciBpcyByZXR1cm5lZC4KCiBJZiB0aGUgcmVxdWVzdGVk
CiBbTGljZW5zZUNvbmZpZ11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MS5MaWNl
bnNlQ29uZmlnXSBkb2VzIG5vdAogZXhpc3QsIGEgTk9UX0ZPVU5EIGVycm9yIGlzIHJldHVy
bmVkLgoKDQoFBAICAAUSBKcBAggKDQoFBAICAAESBKcBCQ0KDQoFBAICAAMSBKcBEBEKDwoF
BAICAAgSBqcBEqwBAwoQCggEAgIACJwIABIEqAEEKgoRCgcEAgIACJ8IEgapAQSrAQUKoQEK
AgQDEgayAQDRAQEakgEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0xpY2Vuc2VDb25maWdTZXJ2
aWNlLkxpc3RMaWNlbnNlQ29uZmlnc11bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52
MS5MaWNlbnNlQ29uZmlnU2VydmljZS5MaXN0TGljZW5zZUNvbmZpZ3NdCiBtZXRob2QuCgoL
CgMEAwESBLIBCCEKcAoEBAMCABIGtQECugEEGmAgUmVxdWlyZWQuIFRoZSBwYXJlbnQgYnJh
bmNoIHJlc291cmNlIG5hbWUsIHN1Y2ggYXMKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRp
b25zL3tsb2NhdGlvbn1gLgoKDQoFBAMCAAUSBLUBAggKDQoFBAMCAAESBLUBCQ8KDQoFBAMC
AAMSBLUBEhMKDwoFBAMCAAgSBrUBFLoBAwoQCggEAwIACJwIABIEtgEEKgoRCgcEAwIACJ8I
Ega3AQS5AQUKKAoEBAMCARIEvQECPxoaIE9wdGlvbmFsLiBOb3Qgc3VwcG9ydGVkLgoKDQoF
BAMCAQUSBL0BAgcKDQoFBAMCAQESBL0BCBEKDQoFBAMCAQMSBL0BFBUKDQoFBAMCAQgSBL0B
Fj4KEAoIBAMCAQicCAASBL0BFz0KKAoEBAMCAhIEwAECQRoaIE9wdGlvbmFsLiBOb3Qgc3Vw
cG9ydGVkLgoKDQoFBAMCAgUSBMABAggKDQoFBAMCAgESBMABCRMKDQoFBAMCAgMSBMABFhcK
DQoFBAMCAggSBMABGEAKEAoIBAMCAgicCAASBMABGT8KgwMKBAQDAgMSBNABAj0a9AIgT3B0
aW9uYWwuIFRoZSBmaWx0ZXIgdG8gYXBwbHkgdG8gdGhlIGxpc3QgcmVzdWx0cy4KCiBUaGUg
c3VwcG9ydGVkIGZpZWxkcyBhcmU6CgogICAqIGBzdWJzY3JpcHRpb25fdGllcmAKICAgKiBg
c3RhdGVgCgogRXhhbXBsZXM6CgogICAqIGBzdWJzY3JpcHRpb25fdGllcj1TVUJTQ1JJUFRJ
T05fVElFUl9TRUFSQ0gsc3RhdGU9QUNUSVZFYCAtIExpc3RzIGFsbAogICBhY3RpdmUgc2Vh
cmNoIGxpY2Vuc2UgY29uZmlncy4KICAgKiBgc3RhdGU9QUNUSVZFYCAtIExpc3RzIGFsbCBh
Y3RpdmUgbGljZW5zZSBjb25maWdzLgoKIFRoZSBmaWx0ZXIgc3RyaW5nIHNob3VsZCBiZSBh
IGNvbW1hLXNlcGFyYXRlZCBsaXN0IG9mIGZpZWxkPXZhbHVlIHBhaXJzLgoKDQoFBAMCAwUS
BNABAggKDQoFBAMCAwESBNABCQ8KDQoFBAMCAwMSBNABEhMKDQoFBAMCAwgSBNABFDwKEAoI
BAMCAwicCAASBNABFTsKogEKAgQEEgbWAQDdAQEakwEgUmVzcG9uc2UgbWVzc2FnZSBmb3IK
IFtMaWNlbnNlQ29uZmlnU2VydmljZS5MaXN0TGljZW5zZUNvbmZpZ3NdW2dvb2dsZS5jbG91
ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ1NlcnZpY2UuTGlzdExpY2Vuc2VD
b25maWdzXQogbWV0aG9kLgoKCwoDBAQBEgTWAQgiCmQKBAQEAgASBNkBAi0aViBBbGwgdGhl
IGN1c3RvbWVyJ3MKIFtMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5n
aW5lLnYxLkxpY2Vuc2VDb25maWddcy4KCg0KBQQEAgAEEgTZAQIKCg0KBQQEAgAGEgTZAQsY
Cg0KBQQEAgABEgTZARkoCg0KBQQEAgADEgTZASssCh4KBAQEAgESBNwBAh0aECBOb3Qgc3Vw
cG9ydGVkLgoKDQoFBAQCAQUSBNwBAggKDQoFBAQCAQESBNwBCRgKDQoFBAQCAQMSBNwBGxwK
qwEKAgQFEgbiAQD9AQEanAEgUmVxdWVzdCBtZXNzYWdlIGZvcgogW0xpY2Vuc2VDb25maWdT
ZXJ2aWNlLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5
ZW5naW5lLnYxLkxpY2Vuc2VDb25maWdTZXJ2aWNlLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmln
XQogbWV0aG9kLgoKCwoDBAUBEgTiAQgmCsQBCgQEBQIAEgbnAQLsAQQaswEgUmVxdWlyZWQu
IEZ1bGwgcmVzb3VyY2UgbmFtZSBvZiBbQmlsbGluZ0FjY291bnRMaWNlbnNlQ29uZmlnXVtd
LgoKIEZvcm1hdDoKIGBiaWxsaW5nQWNjb3VudHMve2JpbGxpbmdfYWNjb3VudH0vYmlsbGlu
Z0FjY291bnRMaWNlbnNlQ29uZmlncy97YmlsbGluZ19hY2NvdW50X2xpY2Vuc2VfY29uZmln
X2lkfWAuCgoNCgUEBQIABRIE5wECCAoNCgUEBQIAARIE5wEJJwoNCgUEBQIAAxIE5wEqKwoP
CgUEBQIACBIG5wEs7AEDChAKCAQFAgAInAgAEgToAQQqChEKBwQFAgAInwgSBukBBOsBBQpd
CgQEBQIBEgTwAQJEGk8gUmVxdWlyZWQuIFRoZSB0YXJnZXQgR0NQIHByb2plY3QgbnVtYmVy
IHRvIGRpc3RyaWJ1dGUgdGhlIGxpY2Vuc2UgY29uZmlnCiB0by4KCg0KBQQFAgEFEgTwAQIH
Cg0KBQQFAgEBEgTwAQgWCg0KBQQFAgEDEgTwARkaCg0KBQQFAgEIEgTwARtDChAKCAQFAgEI
nAgAEgTwARxCCl0KBAQFAgISBPQBAj8aTyBSZXF1aXJlZC4gVGhlIHRhcmdldCBHQ1AgcHJv
amVjdCByZWdpb24gdG8gZGlzdHJpYnV0ZSB0aGUgbGljZW5zZSBjb25maWcKIHRvLgoKDQoF
BAUCAgUSBPQBAggKDQoFBAUCAgESBPQBCREKDQoFBAUCAgMSBPQBFBUKDQoFBAUCAggSBPQB
Fj4KEAoIBAUCAgicCAASBPQBFz0KPwoEBAUCAxIE9wECQxoxIFJlcXVpcmVkLiBUaGUgbnVt
YmVyIG9mIGxpY2Vuc2VzIHRvIGRpc3RyaWJ1dGUuCgoNCgUEBQIDBRIE9wECBwoNCgUEBQID
ARIE9wEIFQoNCgUEBQIDAxIE9wEYGQoNCgUEBQIDCBIE9wEaQgoQCggEBQIDCJwIABIE9wEb
QQrDAQoEBAUCBBIE/AECSBq0ASBPcHRpb25hbC4gRGlzdHJpYnV0ZSBzZWF0cyB0byB0aGlz
IGxpY2Vuc2UgY29uZmlnIGluc3RlYWQgb2YgY3JlYXRpbmcgYSBuZXcKIG9uZS4gSWYgbm90
IHNwZWNpZmllZCwgYSBuZXcgbGljZW5zZSBjb25maWcgd2lsbCBiZSBjcmVhdGVkIGZyb20g
dGhlCiBiaWxsaW5nIGFjY291bnQgbGljZW5zZSBjb25maWcuCgoNCgUEBQIEBRIE/AECCAoN
CgUEBQIEARIE/AEJGgoNCgUEBQIEAxIE/AEdHgoNCgUEBQIECBIE/AEfRwoQCggEBQIECJwI
ABIE/AEgRgqsAQoCBAYSBoICAIUCARqdASBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0xpY2Vu
c2VDb25maWdTZXJ2aWNlLkRpc3RyaWJ1dGVMaWNlbnNlQ29uZmlnXVtnb29nbGUuY2xvdWQu
ZGlzY292ZXJ5ZW5naW5lLnYxLkxpY2Vuc2VDb25maWdTZXJ2aWNlLkRpc3RyaWJ1dGVMaWNl
bnNlQ29uZmlnXQogbWV0aG9kLgoKCwoDBAYBEgSCAggnCjUKBAQGAgASBIQCAiMaJyBUaGUg
dXBkYXRlZCBvciBjcmVhdGVkIExpY2Vuc2VDb25maWcuCgoNCgUEBgIABhIEhAICDwoNCgUE
BgIAARIEhAIQHgoNCgUEBgIAAxIEhAIhIgqlAQoCBAcSBooCAKkCARqWASBSZXF1ZXN0IG1l
c3NhZ2UgZm9yCiBbTGljZW5zZUNvbmZpZ1NlcnZpY2UuUmV0cmFjdExpY2Vuc2VDb25maWdd
W2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ1NlcnZpY2Uu
UmV0cmFjdExpY2Vuc2VDb25maWddCiBtZXRob2QuCgoLCgMEBwESBIoCCCMKxAEKBAQHAgAS
Bo8CApQCBBqzASBSZXF1aXJlZC4gRnVsbCByZXNvdXJjZSBuYW1lIG9mIFtCaWxsaW5nQWNj
b3VudExpY2Vuc2VDb25maWddW10uCgogRm9ybWF0OgogYGJpbGxpbmdBY2NvdW50cy97Ymls
bGluZ19hY2NvdW50fS9iaWxsaW5nQWNjb3VudExpY2Vuc2VDb25maWdzL3tiaWxsaW5nX2Fj
Y291bnRfbGljZW5zZV9jb25maWdfaWR9YC4KCg0KBQQHAgAFEgSPAgIICg0KBQQHAgABEgSP
AgknCg0KBQQHAgADEgSPAiorCg8KBQQHAgAIEgaPAiyUAgMKEAoIBAcCAAicCAASBJACBCoK
EQoHBAcCAAifCBIGkQIEkwIFCswBCgQEBwIBEgabAgKgAgQauwEgUmVxdWlyZWQuIEZ1bGwg
cmVzb3VyY2UgbmFtZSBvZgogW0xpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ10uCgogRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9saWNlbnNlQ29uZmlncy97bGljZW5zZV9jb25m
aWdfaWR9YC4KCg0KBQQHAgEFEgSbAgIICg0KBQQHAgEBEgSbAgkXCg0KBQQHAgEDEgSbAhob
Cg8KBQQHAgEIEgabAhygAgMKEAoIBAcCAQicCAASBJwCBCoKEQoHBAcCAQifCBIGnQIEnwIF
Cn0KBAQHAgISBKQCAkEabyBPcHRpb25hbC4gSWYgc2V0IHRvIHRydWUsIHJldHJhY3QgdGhl
IGVudGlyZSBsaWNlbnNlIGNvbmZpZy4gT3RoZXJ3aXNlLAogcmV0cmFjdCB0aGUgc3BlY2lm
aWVkIGxpY2Vuc2UgY291bnQuCgoNCgUEBwICBRIEpAICBgoNCgUEBwICARIEpAIHEwoNCgUE
BwICAxIEpAIWFwoNCgUEBwICCBIEpAIYQAoQCggEBwICCJwIABIEpAIZPwpjCgQEBwIDEgSo
AgJDGlUgT3B0aW9uYWwuIFRoZSBudW1iZXIgb2YgbGljZW5zZXMgdG8gcmV0cmFjdC4gT25s
eSB1c2VkIHdoZW4gZnVsbF9yZXRyYWN0IGlzCiBmYWxzZS4KCg0KBQQHAgMFEgSoAgIHCg0K
BQQHAgMBEgSoAggVCg0KBQQHAgMDEgSoAhgZCg0KBQQHAgMIEgSoAhpCChAKCAQHAgMInAgA
EgSoAhtBCqYBCgIECBIGrgIAsQIBGpcBIFJlc3BvbnNlIG1lc3NhZ2UgZm9yCiBbTGljZW5z
ZUNvbmZpZ1NlcnZpY2UuUmV0cmFjdExpY2Vuc2VDb25maWddW2dvb2dsZS5jbG91ZC5kaXNj
b3ZlcnllbmdpbmUudjEuTGljZW5zZUNvbmZpZ1NlcnZpY2UuUmV0cmFjdExpY2Vuc2VDb25m
aWddCiBtZXRob2QuCgoLCgMECAESBK4CCCQKKgoEBAgCABIEsAICIxocIFRoZSB1cGRhdGVk
IExpY2Vuc2VDb25maWcuCgoNCgUECAIABhIEsAICDwoNCgUECAIAARIEsAIQHgoNCgUECAIA
AxIEsAIhImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest ===
    # Fields for CreateLicenseConfigRequest
    # Field: parent Type: 9 ()
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfig)
    # Field: license_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest ===
    # Fields for UpdateLicenseConfigRequest
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest ===
    # Fields for GetLicenseConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest ===
    # Fields for ListLicenseConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse ===
    # Fields for ListLicenseConfigsResponse
    # Field: license_configs Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest ===
    # Fields for DistributeLicenseConfigRequest
    # Field: billing_account_license_config Type: 9 ()
    # Field: project_number Type: 3 ()
    # Field: location Type: 9 ()
    # Field: license_count Type: 3 ()
    # Field: license_config_id Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse ===
    # Fields for DistributeLicenseConfigResponse
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfig)

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest ===
    # Fields for RetractLicenseConfigRequest
    # Field: billing_account_license_config Type: 9 ()
    # Field: license_config Type: 9 ()
    # Field: full_retract Type: 8 ()
    # Field: license_count Type: 3 ()

# === Message: Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse ===
    # Fields for RetractLicenseConfigResponse
    # Field: license_config Type: 11 (.google.cloud.discoveryengine.v1.LicenseConfig)

# === Service Client: Google::Cloud::Discoveryengine::V1::LicenseConfigService::LicenseConfigServiceClient ===
package Google::Cloud::Discoveryengine::V1::LicenseConfigService::LicenseConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Discoveryengine::V1::LicenseConfigService::LicenseConfigServiceClient

Client stub representing the remote C<LicenseConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub create_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'CreateLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig',
    });
}

sub update_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'UpdateLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig',
    });
}

sub get_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'GetLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig',
    });
}

sub list_license_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'ListLicenseConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse',
    });
}

sub distribute_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'DistributeLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse',
    });
}

sub retract_license_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.discoveryengine.v1.LicenseConfigService',
        method         => 'RetractLicenseConfig',
        request        => $req,
        response_class => 'Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::LicenseConfigService - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/license_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::LicenseConfigService;

    my $msg = Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest->new({
        parent => $parent,
        license_config => $license_config,
        license_config_id => $license_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/license_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::CreateLicenseConfigRequest

Request message for
[LicenseConfigService.CreateLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.CreateLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>)

Required. The
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig] to create.

=item * C<< $msg->license_config_id() >> / C<< $msg->license_config_id($value) >>

Type: C<String>

Optional. The ID to use for the
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig], which will
become the final component of the
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig]'s resource
name. We are using the tier (product edition) name as the license config id
such as `search` or `search_and_assistant`.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::UpdateLicenseConfigRequest

Request message for
[LicenseConfigService.UpdateLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.UpdateLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>)

Required. The
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig] to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. Indicates which fields in the provided
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig] to update.

If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::GetLicenseConfigRequest

Request message for
[LicenseConfigService.GetLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.GetLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Full resource name of
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig], such as
`projects/{project}/locations/{location}/licenseConfigs/*`.

If the caller does not have permission to access the
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig], regardless
of whether or not it exists, a PERMISSION_DENIED error is returned.

If the requested
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig] does not
exist, a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsRequest

Request message for
[LicenseConfigService.ListLicenseConfigs][google.cloud.discoveryengine.v1.LicenseConfigService.ListLicenseConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent branch resource name, such as
`projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Not supported.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. Not supported.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. The filter to apply to the list results.

The supported fields are:

  * `subscription_tier`
  * `state`

Examples:

  * `subscription_tier=SUBSCRIPTION_TIER_SEARCH,state=ACTIVE` - Lists all
  active search license configs.
  * `state=ACTIVE` - Lists all active license configs.

The filter string should be a comma-separated list of field=value pairs.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::ListLicenseConfigsResponse

Response message for
[LicenseConfigService.ListLicenseConfigs][google.cloud.discoveryengine.v1.LicenseConfigService.ListLicenseConfigs]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_configs() >> / C<< $msg->license_configs($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>)

All the customer's
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig]s.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Not supported.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigRequest

Request message for
[LicenseConfigService.DistributeLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.DistributeLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->billing_account_license_config() >> / C<< $msg->billing_account_license_config($value) >>

Type: C<String>

Required. Full resource name of [BillingAccountLicenseConfig][].

Format:
`billingAccounts/{billing_account}/billingAccountLicenseConfigs/{billing_account_license_config_id}`.

=item * C<< $msg->project_number() >> / C<< $msg->project_number($value) >>

Type: C<Int64>

Required. The target GCP project number to distribute the license config
to.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. The target GCP project region to distribute the license config
to.

=item * C<< $msg->license_count() >> / C<< $msg->license_count($value) >>

Type: C<Int64>

Required. The number of licenses to distribute.

=item * C<< $msg->license_config_id() >> / C<< $msg->license_config_id($value) >>

Type: C<String>

Optional. Distribute seats to this license config instead of creating a new
one. If not specified, a new license config will be created from the
billing account license config.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::DistributeLicenseConfigResponse

Response message for
[LicenseConfigService.DistributeLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.DistributeLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>)

The updated or created LicenseConfig.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigRequest

Request message for
[LicenseConfigService.RetractLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.RetractLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->billing_account_license_config() >> / C<< $msg->billing_account_license_config($value) >>

Type: C<String>

Required. Full resource name of [BillingAccountLicenseConfig][].

Format:
`billingAccounts/{billing_account}/billingAccountLicenseConfigs/{billing_account_license_config_id}`.

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<String>

Required. Full resource name of
[LicenseConfig][google.cloud.discoveryengine.v1.LicenseConfig].

Format:
`projects/{project}/locations/{location}/licenseConfigs/{license_config_id}`.

=item * C<< $msg->full_retract() >> / C<< $msg->full_retract($value) >>

Type: C<Bool>

Optional. If set to true, retract the entire license config. Otherwise,
retract the specified license count.

=item * C<< $msg->license_count() >> / C<< $msg->license_count($value) >>

Type: C<Int64>

Optional. The number of licenses to retract. Only used when full_retract is
false.

=back

=head2 Google::Cloud::Discoveryengine::V1::LicenseConfigService::RetractLicenseConfigResponse

Response message for
[LicenseConfigService.RetractLicenseConfig][google.cloud.discoveryengine.v1.LicenseConfigService.RetractLicenseConfig]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->license_config() >> / C<< $msg->license_config($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::LicenseConfig::LicenseConfig>)

The updated LicenseConfig.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::LicenseConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
