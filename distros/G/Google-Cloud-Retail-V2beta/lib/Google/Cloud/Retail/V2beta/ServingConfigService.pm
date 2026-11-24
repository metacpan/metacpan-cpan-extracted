package Google::Cloud::Retail::V2beta::ServingConfigService;

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
    eval { require Google::Cloud::Retail::V2beta::ServingConfig };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9zZXJ2aW5nX2NvbmZpZ19zZXJ2aWNlLnBy
b3RvEhpnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9u
cy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aL2dvb2dsZS9jbG91ZC9y
ZXRhaWwvdjJiZXRhL3NlcnZpbmdfY29uZmlnLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIuMBChpDcmVhdGVT
ZXJ2aW5nQ29uZmlnUmVxdWVzdBI9CgZwYXJlbnQYASABKAlCJeBBAvpBHwodcmV0YWlsLmdv
b2dsZWFwaXMuY29tL0NhdGFsb2dSBnBhcmVudBJVCg5zZXJ2aW5nX2NvbmZpZxgCIAEoCzIp
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWdCA+BBAlINc2Vydmlu
Z0NvbmZpZxIvChFzZXJ2aW5nX2NvbmZpZ19pZBgDIAEoCUID4EECUg9zZXJ2aW5nQ29uZmln
SWQisAEKGlVwZGF0ZVNlcnZpbmdDb25maWdSZXF1ZXN0ElUKDnNlcnZpbmdfY29uZmlnGAEg
ASgLMikuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZ0ID4EECUg1z
ZXJ2aW5nQ29uZmlnEjsKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza1IKdXBkYXRlTWFzayJdChpEZWxldGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBI/CgRu
YW1lGAEgASgJQivgQQL6QSUKI3JldGFpbC5nb29nbGVhcGlzLmNvbS9TZXJ2aW5nQ29uZmln
UgRuYW1lIloKF0dldFNlcnZpbmdDb25maWdSZXF1ZXN0Ej8KBG5hbWUYASABKAlCK+BBAvpB
JQojcmV0YWlsLmdvb2dsZWFwaXMuY29tL1NlcnZpbmdDb25maWdSBG5hbWUioAEKGUxpc3RT
ZXJ2aW5nQ29uZmlnc1JlcXVlc3QSPQoGcGFyZW50GAEgASgJQiXgQQL6QR8KHXJldGFpbC5n
b29nbGVhcGlzLmNvbS9DYXRhbG9nUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFS
CHBhZ2VTaXplEiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuIpgBChpMaXN0
U2VydmluZ0NvbmZpZ3NSZXNwb25zZRJSCg9zZXJ2aW5nX2NvbmZpZ3MYASADKAsyKS5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnUg5zZXJ2aW5nQ29uZmlncxIm
Cg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iiwEKEUFkZENvbnRyb2xS
ZXF1ZXN0ElIKDnNlcnZpbmdfY29uZmlnGAEgASgJQivgQQL6QSUKI3JldGFpbC5nb29nbGVh
cGlzLmNvbS9TZXJ2aW5nQ29uZmlnUg1zZXJ2aW5nQ29uZmlnEiIKCmNvbnRyb2xfaWQYAiAB
KAlCA+BBAlIJY29udHJvbElkIo4BChRSZW1vdmVDb250cm9sUmVxdWVzdBJSCg5zZXJ2aW5n
X2NvbmZpZxgBIAEoCUIr4EEC+kElCiNyZXRhaWwuZ29vZ2xlYXBpcy5jb20vU2VydmluZ0Nv
bmZpZ1INc2VydmluZ0NvbmZpZxIiCgpjb250cm9sX2lkGAIgASgJQgPgQQJSCWNvbnRyb2xJ
ZDKDDQoUU2VydmluZ0NvbmZpZ1NlcnZpY2US/gEKE0NyZWF0ZVNlcnZpbmdDb25maWcSNi5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5DcmVhdGVTZXJ2aW5nQ29uZmlnUmVxdWVzdBop
Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWcigwGC0+STAlMiQS92
MmJldGEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyp9L3NlcnZp
bmdDb25maWdzOg5zZXJ2aW5nX2NvbmZpZ9pBJ3BhcmVudCxzZXJ2aW5nX2NvbmZpZyxzZXJ2
aW5nX2NvbmZpZ19pZBK3AQoTRGVsZXRlU2VydmluZ0NvbmZpZxI2Lmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjJiZXRhLkRlbGV0ZVNlcnZpbmdDb25maWdSZXF1ZXN0GhYuZ29vZ2xlLnByb3Rv
YnVmLkVtcHR5IlCC0+STAkMqQS92MmJldGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9jYXRhbG9ncy8qL3NlcnZpbmdDb25maWdzLyp92kEEbmFtZRKAAgoTVXBkYXRlU2Vydmlu
Z0NvbmZpZxI2Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlVwZGF0ZVNlcnZpbmdDb25m
aWdSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZyKF
AYLT5JMCYjJQL3YyYmV0YS97c2VydmluZ19jb25maWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn06DnNlcnZpbmdfY29uZmln2kEa
c2VydmluZ19jb25maWcsdXBkYXRlX21hc2sSxAEKEEdldFNlcnZpbmdDb25maWcSMy5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5HZXRTZXJ2aW5nQ29uZmlnUmVxdWVzdBopLmdvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWciUILT5JMCQxJBL3YyYmV0YS97
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3Mv
Kn3aQQRuYW1lEtcBChJMaXN0U2VydmluZ0NvbmZpZ3MSNS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYmV0YS5MaXN0U2VydmluZ0NvbmZpZ3NSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLnJldGFp
bC52MmJldGEuTGlzdFNlcnZpbmdDb25maWdzUmVzcG9uc2UiUoLT5JMCQxJBL3YyYmV0YS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY2F0YWxvZ3MvKn0vc2VydmluZ0NvbmZp
Z3PaQQZwYXJlbnQS2gEKCkFkZENvbnRyb2wSLS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0
YS5BZGRDb250cm9sUmVxdWVzdBopLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZp
bmdDb25maWcicoLT5JMCWyJWL3YyYmV0YS97c2VydmluZ19jb25maWc9cHJvamVjdHMvKi9s
b2NhdGlvbnMvKi9jYXRhbG9ncy8qL3NlcnZpbmdDb25maWdzLyp9OmFkZENvbnRyb2w6ASra
QQ5zZXJ2aW5nX2NvbmZpZxLjAQoNUmVtb3ZlQ29udHJvbBIwLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhLlJlbW92ZUNvbnRyb2xSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuU2VydmluZ0NvbmZpZyJ1gtPkkwJeIlkvdjJiZXRhL3tzZXJ2aW5nX2NvbmZpZz1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2NhdGFsb2dzLyovc2VydmluZ0NvbmZpZ3MvKn06cmVt
b3ZlQ29udHJvbDoBKtpBDnNlcnZpbmdfY29uZmlnGknKQRVyZXRhaWwuZ29vZ2xlYXBpcy5j
b23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQtgB
Ch5jb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGFCGVNlcnZpbmdDb25maWdTZXJ2aWNl
UHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJiZXRhL3JldGFpbHBi
O3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3VkLlJldGFpbC5WMkJldGHKAhpHb29n
bGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJiZXRh
SvY3CgcSBQ4A7wEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
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
EAAjCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQS
AxYAOQoJCgIDBRIDFwAlCgkKAgMGEgMYACoKCAoBCBIDGgA3CgkKAgglEgMaADcKCAoBCBID
GwBNCgkKAggLEgMbAE0KCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA6CgkKAggIEgMd
ADoKCAoBCBIDHgA3CgkKAggBEgMeADcKCAoBCBIDHwAkCgkKAggkEgMfACQKCAoBCBIDIAA3
CgkKAggpEgMgADcKCAoBCBIDIQA2CgkKAggtEgMhADYKMgoCBgASBCQAeAEaJiBTZXJ2aWNl
IGZvciBtb2RpZnlpbmcgU2VydmluZ0NvbmZpZy4KCgoKAwYAARIDJAgcCgoKAwYAAxIDJQI9
CgwKBQYAA5kIEgMlAj0KCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CuwBCgQGAAIAEgQu
AjUDGt0BIENyZWF0ZXMgYSBTZXJ2aW5nQ29uZmlnLgoKIEEgbWF4aW11bSBvZiAxMDAgW1Nl
cnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWdd
cwogYXJlIGFsbG93ZWQgaW4gYSBbQ2F0YWxvZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJl
dGEuQ2F0YWxvZ10sIG90aGVyd2lzZQogYSBGQUlMRURfUFJFQ09ORElUSU9OIGVycm9yIGlz
IHJldHVybmVkLgoKDAoFBgACAAESAy4GGQoMCgUGAAIAAhIDLho0CgwKBQYAAgADEgMuP0wK
DQoFBgACAAQSBC8EMgYKEQoJBgACAASwyrwiEgQvBDIGCg0KBQYAAgAEEgQzBDQyChAKCAYA
AgAEmwgAEgQzBDQyCmgKBAYAAgESBDoCQAMaWiBEZWxldGVzIGEgU2VydmluZ0NvbmZpZy4K
CiBSZXR1cm5zIGEgTm90Rm91bmQgZXJyb3IgaWYgdGhlIFNlcnZpbmdDb25maWcgZG9lcyBu
b3QgZXhpc3QuCgoMCgUGAAIBARIDOgYZCgwKBQYAAgECEgM6GjQKDAoFBgACAQMSAzsPJAoN
CgUGAAIBBBIEPAQ+BgoRCgkGAAIBBLDKvCISBDwEPgYKDAoFBgACAQQSAz8EMgoPCggGAAIB
BJsIABIDPwQyCigKBAYAAgISBEMCSQMaGiBVcGRhdGVzIGEgU2VydmluZ0NvbmZpZy4KCgwK
BQYAAgIBEgNDBhkKDAoFBgACAgISA0MaNAoMCgUGAAICAxIDQz9MCg0KBQYAAgIEEgREBEcG
ChEKCQYAAgIEsMq8IhIERARHBgoMCgUGAAICBBIDSARICg8KCAYAAgIEmwgAEgNIBEgKZQoE
BgACAxIETgJTAxpXIEdldHMgYSBTZXJ2aW5nQ29uZmlnLgoKIFJldHVybnMgYSBOb3RGb3Vu
ZCBlcnJvciBpZiB0aGUgU2VydmluZ0NvbmZpZyBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgMB
EgNOBhYKDAoFBgACAwISA04XLgoMCgUGAAIDAxIDTjlGCg0KBQYAAgMEEgRPBFEGChEKCQYA
AgMEsMq8IhIETwRRBgoMCgUGAAIDBBIDUgQyCg8KCAYAAgMEmwgAEgNSBDIKQAoEBgACBBIE
VgJcAxoyIExpc3RzIGFsbCBTZXJ2aW5nQ29uZmlncyBsaW5rZWQgdG8gdGhpcyBjYXRhbG9n
LgoKDAoFBgACBAESA1YGGAoMCgUGAAIEAhIDVhkyCgwKBQYAAgQDEgNXDykKDQoFBgACBAQS
BFgEWgYKEQoJBgACBASwyrwiEgRYBFoGCgwKBQYAAgQEEgNbBDQKDwoIBgACBASbCAASA1sE
NArHAwoEBgACBRIEZQJrAxq4AyBFbmFibGVzIGEgQ29udHJvbCBvbiB0aGUgc3BlY2lmaWVk
IFNlcnZpbmdDb25maWcuCiBUaGUgY29udHJvbCBpcyBhZGRlZCBpbiB0aGUgbGFzdCBwb3Np
dGlvbiBvZiB0aGUgbGlzdCBvZiBjb250cm9scwogaXQgYmVsb25ncyB0byAoZS5nLiBpZiBp
dCdzIGEgZmFjZXQgc3BlYyBjb250cm9sIGl0IHdpbGwgYmUgYXBwbGllZAogaW4gdGhlIGxh
c3QgcG9zaXRpb24gb2Ygc2VydmluZ0NvbmZpZy5mYWNldFNwZWNJZHMpCiBSZXR1cm5zIGEg
QUxSRUFEWV9FWElTVFMgZXJyb3IgaWYgdGhlIGNvbnRyb2wgaGFzIGFscmVhZHkgYmVlbiBh
cHBsaWVkLgogUmV0dXJucyBhIEZBSUxFRF9QUkVDT05ESVRJT04gZXJyb3IgaWYgdGhlIGFk
ZGl0aW9uIGNvdWxkIGV4Y2VlZCBtYXhpbXVtCiBudW1iZXIgb2YgY29udHJvbCBhbGxvd2Vk
IGZvciB0aGF0IHR5cGUgb2YgY29udHJvbC4KCgwKBQYAAgUBEgNlBhAKDAoFBgACBQISA2UR
IgoMCgUGAAIFAxIDZS06Cg0KBQYAAgUEEgRmBGkGChEKCQYAAgUEsMq8IhIEZgRpBgoMCgUG
AAIFBBIDagQ8Cg8KCAYAAgUEmwgAEgNqBDwKxAEKBAYAAgYSBHECdwMatQEgRGlzYWJsZXMg
YSBDb250cm9sIG9uIHRoZSBzcGVjaWZpZWQgU2VydmluZ0NvbmZpZy4KIFRoZSBjb250cm9s
IGlzIHJlbW92ZWQgZnJvbSB0aGUgU2VydmluZ0NvbmZpZy4KIFJldHVybnMgYSBOT1RfRk9V
TkQgZXJyb3IgaWYgdGhlIENvbnRyb2wgaXMgbm90IGVuYWJsZWQgZm9yIHRoZQogU2Vydmlu
Z0NvbmZpZy4KCgwKBQYAAgYBEgNxBhMKDAoFBgACBgISA3EUKAoMCgUGAAIGAxIDcTNACg0K
BQYAAgYEEgRyBHUGChEKCQYAAgYEsMq8IhIEcgR1BgoMCgUGAAIGBBIDdgQ8Cg8KCAYAAgYE
mwgAEgN2BDwKNgoCBAASBXsAjAEBGikgUmVxdWVzdCBmb3IgQ3JlYXRlU2VydmluZ0NvbmZp
ZyBtZXRob2QuCgoKCgMEAAESA3sIIgqLAQoEBAACABIFfgKBAQQafCBSZXF1aXJlZC4gRnVs
bCByZXNvdXJjZSBuYW1lIG9mIHBhcmVudC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
X251bWJlcn0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9
YAoKDAoFBAACAAUSA34CCAoMCgUEAAIAARIDfgkPCgwKBQQAAgADEgN+EhMKDgoFBAACAAgS
BX4UgQEDCg8KCAQAAgAInAgAEgN/BCoKDwoHBAACAAifCBIEgAEETwo2CgQEAAIBEgSEAQJM
GiggUmVxdWlyZWQuIFRoZSBTZXJ2aW5nQ29uZmlnIHRvIGNyZWF0ZS4KCg0KBQQAAgEGEgSE
AQIPCg0KBQQAAgEBEgSEARAeCg0KBQQAAgEDEgSEASEiCg0KBQQAAgEIEgSEASNLChAKCAQA
AgEInAgAEgSEASRKCt4BCgQEAAICEgSLAQJIGs8BIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNl
IGZvciB0aGUgU2VydmluZ0NvbmZpZywgd2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBj
b21wb25lbnQgb2YgdGhlIFNlcnZpbmdDb25maWcncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMg
dmFsdWUgc2hvdWxkIGJlIDQtNjMgY2hhcmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMK
IGFyZSAvW2Etel1bMC05XS1fLy4KCg0KBQQAAgIFEgSLAQIICg0KBQQAAgIBEgSLAQkaCg0K
BQQAAgIDEgSLAR0eCg0KBQQAAgIIEgSLAR9HChAKCAQAAgIInAgAEgSLASBGCjcKAgQBEgaP
AQCbAQEaKSBSZXF1ZXN0IGZvciBVcGRhdGVTZXJ2aW5nQ29uZmlnIG1ldGhvZC4KCgsKAwQB
ARIEjwEIIgo2CgQEAQIAEgSRAQJMGiggUmVxdWlyZWQuIFRoZSBTZXJ2aW5nQ29uZmlnIHRv
IHVwZGF0ZS4KCg0KBQQBAgAGEgSRAQIPCg0KBQQBAgABEgSRARAeCg0KBQQBAgADEgSRASEi
Cg0KBQQBAgAIEgSRASNLChAKCAQBAgAInAgAEgSRASRKCpcCCgQEAQIBEgSaAQIsGogCIElu
ZGljYXRlcyB3aGljaCBmaWVsZHMgaW4gdGhlIHByb3ZpZGVkCiBbU2VydmluZ0NvbmZpZ11b
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZ10gdG8gdXBkYXRlLiBU
aGUKIGZvbGxvd2luZyBhcmUgTk9UIHN1cHBvcnRlZDoKCiAqIFtTZXJ2aW5nQ29uZmlnLm5h
bWVdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNlcnZpbmdDb25maWcubmFtZV0KCiBJ
ZiBub3Qgc2V0LCBhbGwgc3VwcG9ydGVkIGZpZWxkcyBhcmUgdXBkYXRlZC4KCg0KBQQBAgEG
EgSaAQIbCg0KBQQBAgEBEgSaARwnCg0KBQQBAgEDEgSaASorCjcKAgQCEgaeAQCnAQEaKSBS
ZXF1ZXN0IGZvciBEZWxldGVTZXJ2aW5nQ29uZmlnIG1ldGhvZC4KCgsKAwQCARIEngEIIgrE
AQoEBAICABIGoQECpgEEGrMBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUg
U2VydmluZ0NvbmZpZyB0byBkZWxldGUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdF9u
dW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lkfS9z
ZXJ2aW5nQ29uZmlncy97c2VydmluZ19jb25maWdfaWR9YAoKDQoFBAICAAUSBKEBAggKDQoF
BAICAAESBKEBCQ0KDQoFBAICAAMSBKEBEBEKDwoFBAICAAgSBqEBEqYBAwoQCggEAgIACJwI
ABIEogEEKgoRCgcEAgIACJ8IEgajAQSlAQUKNAoCBAMSBqoBALMBARomIFJlcXVlc3QgZm9y
IEdldFNlcnZpbmdDb25maWcgbWV0aG9kLgoKCwoDBAMBEgSqAQgfCsEBCgQEAwIAEgatAQKy
AQQasAEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTZXJ2aW5nQ29uZmln
IHRvIGdldC4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X251bWJlcn0vbG9jYXRpb25z
L3tsb2NhdGlvbl9pZH0vY2F0YWxvZ3Mve2NhdGFsb2dfaWR9L3NlcnZpbmdDb25maWdzL3tz
ZXJ2aW5nX2NvbmZpZ19pZH1gCgoNCgUEAwIABRIErQECCAoNCgUEAwIAARIErQEJDQoNCgUE
AwIAAxIErQEQEQoPCgUEAwIACBIGrQESsgEDChAKCAQDAgAInAgAEgSuAQQqChEKBwQDAgAI
nwgSBq8BBLEBBQo2CgIEBBIGtgEAxgEBGiggUmVxdWVzdCBmb3IgTGlzdFNlcnZpbmdDb25m
aWdzIG1ldGhvZC4KCgsKAwQEARIEtgEIIQqJAQoEBAQCABIGuQECvAEEGnkgUmVxdWlyZWQu
IFRoZSBjYXRhbG9nIHJlc291cmNlIG5hbWUuIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFsb2dzL3tjYXRhbG9nX2lk
fWAKCg0KBQQEAgAFEgS5AQIICg0KBQQEAgABEgS5AQkPCg0KBQQEAgADEgS5ARITCg8KBQQE
AgAIEga5ARS8AQMKEAoIBAQCAAicCAASBLoBBCoKDwoHBAQCAAifCBIEuwEETwqtAQoEBAQC
ARIEwQECPxqeASBPcHRpb25hbC4gTWF4aW11bSBudW1iZXIgb2YgcmVzdWx0cyB0byByZXR1
cm4uIElmIHVuc3BlY2lmaWVkLCBkZWZhdWx0cwogdG8gMTAwLiBJZiBhIHZhbHVlIGdyZWF0
ZXIgdGhhbiAxMDAgaXMgcHJvdmlkZWQsIGF0IG1vc3QgMTAwIHJlc3VsdHMgYXJlCiByZXR1
cm5lZC4KCg0KBQQEAgEFEgTBAQIHCg0KBQQEAgEBEgTBAQgRCg0KBQQEAgEDEgTBARQVCg0K
BQQEAgEIEgTBARY+ChAKCAQEAgEInAgAEgTBARc9CooBCgQEBAICEgTFAQJBGnwgT3B0aW9u
YWwuIEEgcGFnZSB0b2tlbiwgcmVjZWl2ZWQgZnJvbSBhIHByZXZpb3VzIGBMaXN0U2Vydmlu
Z0NvbmZpZ3NgIGNhbGwuCiBQcm92aWRlIHRoaXMgdG8gcmV0cmlldmUgdGhlIHN1YnNlcXVl
bnQgcGFnZS4KCg0KBQQEAgIFEgTFAQIICg0KBQQEAgIBEgTFAQkTCg0KBQQEAgIDEgTFARYX
Cg0KBQQEAgIIEgTFARhAChAKCAQEAgIInAgAEgTFARk/CjcKAgQFEgbJAQDPAQEaKSBSZXNw
b25zZSBmb3IgTGlzdFNlcnZpbmdDb25maWdzIG1ldGhvZC4KCgsKAwQFARIEyQEIIgo7CgQE
BQIAEgTLAQItGi0gQWxsIHRoZSBTZXJ2aW5nQ29uZmlncyBmb3IgYSBnaXZlbiBjYXRhbG9n
LgoKDQoFBAUCAAQSBMsBAgoKDQoFBAUCAAYSBMsBCxgKDQoFBAUCAAESBMsBGSgKDQoFBAUC
AAMSBMsBKywKSgoEBAUCARIEzgECHRo8IFBhZ2luYXRpb24gdG9rZW4sIGlmIG5vdCByZXR1
cm5lZCBpbmRpY2F0ZXMgdGhlIGxhc3QgcGFnZS4KCg0KBQQFAgEFEgTOAQIICg0KBQQFAgEB
EgTOAQkYCg0KBQQFAgEDEgTOARscCi4KAgQGEgbSAQDfAQEaICBSZXF1ZXN0IGZvciBBZGRD
b250cm9sIG1ldGhvZC4KCgsKAwQGARIE0gEIGQq7AQoEBAYCABIG1QEC2gEEGqoBIFJlcXVp
cmVkLiBUaGUgc291cmNlIFNlcnZpbmdDb25maWcgcmVzb3VyY2UgbmFtZSAuIEZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2Nh
dGFsb2dzL3tjYXRhbG9nX2lkfS9zZXJ2aW5nQ29uZmlncy97c2VydmluZ19jb25maWdfaWR9
YAoKDQoFBAYCAAUSBNUBAggKDQoFBAYCAAESBNUBCRcKDQoFBAYCAAMSBNUBGhsKDwoFBAYC
AAgSBtUBHNoBAwoQCggEBgIACJwIABIE1gEEKgoRCgcEBgIACJ8IEgbXAQTZAQUKpwEKBAQG
AgESBN4BAkEamAEgUmVxdWlyZWQuIFRoZSBpZCBvZiB0aGUgY29udHJvbCB0byBhcHBseS4g
QXNzdW1lZCB0byBiZSBpbiB0aGUgc2FtZSBjYXRhbG9nCiBhcyB0aGUgc2VydmluZyBjb25m
aWcgLSBpZiBpZCBpcyBub3QgZm91bmQgYSBOT1RfRk9VTkQgZXJyb3IgaXMgcmV0dXJuZWQu
CgoNCgUEBgIBBRIE3gECCAoNCgUEBgIBARIE3gEJEwoNCgUEBgIBAxIE3gEWFwoNCgUEBgIB
CBIE3gEYQAoQCggEBgIBCJwIABIE3gEZPwoxCgIEBxIG4gEA7wEBGiMgUmVxdWVzdCBmb3Ig
UmVtb3ZlQ29udHJvbCBtZXRob2QuCgoLCgMEBwESBOIBCBwKuwEKBAQHAgASBuUBAuoBBBqq
ASBSZXF1aXJlZC4gVGhlIHNvdXJjZSBTZXJ2aW5nQ29uZmlnIHJlc291cmNlIG5hbWUgLiBG
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9u
X2lkfS9jYXRhbG9ncy97Y2F0YWxvZ19pZH0vc2VydmluZ0NvbmZpZ3Mve3NlcnZpbmdfY29u
ZmlnX2lkfWAKCg0KBQQHAgAFEgTlAQIICg0KBQQHAgABEgTlAQkXCg0KBQQHAgADEgTlARob
Cg8KBQQHAgAIEgblARzqAQMKEAoIBAcCAAicCAASBOYBBCoKEQoHBAcCAAifCBIG5wEE6QEF
CnMKBAQHAgESBO4BAkEaZSBSZXF1aXJlZC4gVGhlIGlkIG9mIHRoZSBjb250cm9sIHRvIGFw
cGx5LiBBc3N1bWVkIHRvIGJlIGluIHRoZSBzYW1lIGNhdGFsb2cKIGFzIHRoZSBzZXJ2aW5n
IGNvbmZpZy4KCg0KBQQHAgEFEgTuAQIICg0KBQQHAgEBEgTuAQkTCg0KBQQHAgEDEgTuARYX
Cg0KBQQHAgEIEgTuARhAChAKCAQHAgEInAgAEgTuARk/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest ===
    # Fields for CreateServingConfigRequest
    # Field: parent Type: 9 ()
    # Field: serving_config Type: 11 (.google.cloud.retail.v2beta.ServingConfig)
    # Field: serving_config_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::UpdateServingConfigRequest ===
    # Fields for UpdateServingConfigRequest
    # Field: serving_config Type: 11 (.google.cloud.retail.v2beta.ServingConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::DeleteServingConfigRequest ===
    # Fields for DeleteServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::GetServingConfigRequest ===
    # Fields for GetServingConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsRequest ===
    # Fields for ListServingConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsResponse ===
    # Fields for ListServingConfigsResponse
    # Field: serving_configs Type: 11 (.google.cloud.retail.v2beta.ServingConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::AddControlRequest ===
    # Fields for AddControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Message: Google::Cloud::Retail::V2beta::ServingConfigService::RemoveControlRequest ===
    # Fields for RemoveControlRequest
    # Field: serving_config Type: 9 ()
    # Field: control_id Type: 9 ()

# === Service Client: Google::Cloud::Retail::V2beta::ServingConfigService::ServingConfigServiceClient ===
package Google::Cloud::Retail::V2beta::ServingConfigService::ServingConfigServiceClient;

=pod

=head2 Service Client: Google::Cloud::Retail::V2beta::ServingConfigService::ServingConfigServiceClient

Client stub representing the remote C<ServingConfigService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<retail.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'retail.googleapis.com:443' );

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

sub create_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'CreateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig',
    });
}

sub delete_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::DeleteServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'DeleteServingConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::UpdateServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'UpdateServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig',
    });
}

sub get_serving_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::GetServingConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'GetServingConfig',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig',
    });
}

sub list_serving_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'ListServingConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsResponse',
    });
}

sub add_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::AddControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'AddControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig',
    });
}

sub remove_control {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Retail::V2beta::ServingConfigService::RemoveControlRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.retail.v2beta.ServingConfigService',
        method         => 'RemoveControl',
        request        => $req,
        response_class => 'Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::ServingConfigService - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/serving_config_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::ServingConfigService;

    my $msg = Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest->new({
        parent => $parent,
        serving_config => $serving_config,
        serving_config_id => $serving_config_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/serving_config_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::CreateServingConfigRequest

Request for CreateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Full resource name of parent. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig>)

Required. The ServingConfig to create.

=item * C<< $msg->serving_config_id() >> / C<< $msg->serving_config_id($value) >>

Type: C<String>

Required. The ID to use for the ServingConfig, which will become the final
component of the ServingConfig's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-_/.

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::UpdateServingConfigRequest

Request for UpdateServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig>)

Required. The ServingConfig to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Indicates which fields in the provided
[ServingConfig][google.cloud.retail.v2beta.ServingConfig] to update. The
following are NOT supported:

* [ServingConfig.name][google.cloud.retail.v2beta.ServingConfig.name]

If not set, all supported fields are updated.

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::DeleteServingConfigRequest

Request for DeleteServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to delete. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::GetServingConfigRequest

Request for GetServingConfig method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ServingConfig to get. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsRequest

Request for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The catalog resource name. Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}`

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Maximum number of results to return. If unspecified, defaults
to 100. If a value greater than 100 is provided, at most 100 results are
returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListServingConfigs` call.
Provide this to retrieve the subsequent page.

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::ListServingConfigsResponse

Response for ListServingConfigs method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_configs() >> / C<< $msg->serving_configs($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::ServingConfig::ServingConfig>)

All the ServingConfigs for a given catalog.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Pagination token, if not returned indicates the last page.

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::AddControlRequest

Request for AddControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config - if id is not found a NOT_FOUND error is returned.

=back

=head2 Google::Cloud::Retail::V2beta::ServingConfigService::RemoveControlRequest

Request for RemoveControl method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->serving_config() >> / C<< $msg->serving_config($value) >>

Type: C<String>

Required. The source ServingConfig resource name . Format:
`projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/servingConfigs/{serving_config_id}`

=item * C<< $msg->control_id() >> / C<< $msg->control_id($value) >>

Type: C<String>

Required. The id of the control to apply. Assumed to be in the same catalog
as the serving config.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::ServingConfigService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
