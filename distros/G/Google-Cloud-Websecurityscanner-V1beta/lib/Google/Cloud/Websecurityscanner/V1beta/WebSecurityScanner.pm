package Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner;

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
    eval { require Google::Cloud::Websecurityscanner::V1beta::CrawledUrl };
    eval { require Google::Cloud::Websecurityscanner::V1beta::Finding };
    eval { require Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats };
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanConfig };
    eval { require Google::Cloud::Websecurityscanner::V1beta::ScanRun };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS93ZWJfc2VjdXJpdHlf
c2Nhbm5lci5wcm90bxImZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEa
HGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3Rv
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGjhnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9jcmF3bGVk
X3VybC5wcm90bxo0Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MWJldGEvZmlu
ZGluZy5wcm90bxo/Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MWJldGEvZmlu
ZGluZ190eXBlX3N0YXRzLnByb3RvGjhnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVy
L3YxYmV0YS9zY2FuX2NvbmZpZy5wcm90bxo1Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nh
bm5lci92MWJldGEvc2Nhbl9ydW4ucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90
bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8iwAEKF0NyZWF0ZVNjYW5Db25m
aWdSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291cmNlbWFuYWdl
ci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSWAoLc2Nhbl9jb25maWcYAiABKAsy
Mi5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5TY2FuQ29uZmlnQgPg
QQJSCnNjYW5Db25maWciYwoXRGVsZXRlU2NhbkNvbmZpZ1JlcXVlc3QSSAoEbmFtZRgBIAEo
CUI04EEC+kEuCix3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2NhbkNvbmZp
Z1IEbmFtZSJgChRHZXRTY2FuQ29uZmlnUmVxdWVzdBJICgRuYW1lGAEgASgJQjTgQQL6QS4K
LHdlYnNlY3VyaXR5c2Nhbm5lci5nb29nbGVhcGlzLmNvbS9TY2FuQ29uZmlnUgRuYW1lIqEB
ChZMaXN0U2NhbkNvbmZpZ3NSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91
ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSHQoKcGFn
ZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUi
tQEKF1VwZGF0ZVNjYW5Db25maWdSZXF1ZXN0ElgKC3NjYW5fY29uZmlnGAIgASgLMjIuZ29v
Z2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU2NhbkNvbmZpZ0ID4EECUgpz
Y2FuQ29uZmlnEkAKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxk
TWFza0ID4EECUgp1cGRhdGVNYXNrIpgBChdMaXN0U2NhbkNvbmZpZ3NSZXNwb25zZRJVCgxz
Y2FuX2NvbmZpZ3MYASADKAsyMi5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYx
YmV0YS5TY2FuQ29uZmlnUgtzY2FuQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4iXwoTU3RhcnRTY2FuUnVuUmVxdWVzdBJICgRuYW1lGAEgASgJQjTg
QQL6QS4KLHdlYnNlY3VyaXR5c2Nhbm5lci5nb29nbGVhcGlzLmNvbS9TY2FuQ29uZmlnUgRu
YW1lIloKEUdldFNjYW5SdW5SZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopd2Vic2Vj
dXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5SdW5SBG5hbWUinwEKE0xpc3RTY2Fu
UnVuc1JlcXVlc3QSTAoGcGFyZW50GAEgASgJQjTgQQL6QS4KLHdlYnNlY3VyaXR5c2Nhbm5l
ci5nb29nbGVhcGlzLmNvbS9TY2FuQ29uZmlnUgZwYXJlbnQSHQoKcGFnZV90b2tlbhgCIAEo
CVIJcGFnZVRva2VuEhsKCXBhZ2Vfc2l6ZRgDIAEoBVIIcGFnZVNpemUijAEKFExpc3RTY2Fu
UnVuc1Jlc3BvbnNlEkwKCXNjYW5fcnVucxgBIAMoCzIvLmdvb2dsZS5jbG91ZC53ZWJzZWN1
cml0eXNjYW5uZXIudjFiZXRhLlNjYW5SdW5SCHNjYW5SdW5zEiYKD25leHRfcGFnZV90b2tl
bhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJbChJTdG9wU2NhblJ1blJlcXVlc3QSRQoEbmFtZRgB
IAEoCUIx4EEC+kErCil3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2NhblJ1
blIEbmFtZSKfAQoWTGlzdENyYXdsZWRVcmxzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBB
AvpBKwopd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5SdW5SBnBhcmVu
dBIdCgpwYWdlX3Rva2VuGAIgASgJUglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAMgASgFUghw
YWdlU2l6ZSKYAQoXTGlzdENyYXdsZWRVcmxzUmVzcG9uc2USVQoMY3Jhd2xlZF91cmxzGAEg
AygLMjIuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuQ3Jhd2xlZFVy
bFILY3Jhd2xlZFVybHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu
IloKEUdldEZpbmRpbmdSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpBKwopd2Vic2VjdXJp
dHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL0ZpbmRpbmdSBG5hbWUiuQEKE0xpc3RGaW5kaW5n
c1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKXdlYnNlY3VyaXR5c2Nhbm5lci5n
b29nbGVhcGlzLmNvbS9TY2FuUnVuUgZwYXJlbnQSGwoGZmlsdGVyGAIgASgJQgPgQQJSBmZp
bHRlchIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAQgASgF
UghwYWdlU2l6ZSKLAQoUTGlzdEZpbmRpbmdzUmVzcG9uc2USSwoIZmluZGluZ3MYASADKAsy
Ly5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5GaW5kaW5nUghmaW5k
aW5ncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iaAobTGlzdEZp
bmRpbmdUeXBlU3RhdHNSZXF1ZXN0EkkKBnBhcmVudBgBIAEoCUIx4EEC+kErCil3ZWJzZWN1
cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2NhblJ1blIGcGFyZW50IoYBChxMaXN0Rmlu
ZGluZ1R5cGVTdGF0c1Jlc3BvbnNlEmYKEmZpbmRpbmdfdHlwZV9zdGF0cxgBIAMoCzI4Lmdv
b2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkZpbmRpbmdUeXBlU3RhdHNS
EGZpbmRpbmdUeXBlU3RhdHMyjhYKEldlYlNlY3VyaXR5U2Nhbm5lchLaAQoQQ3JlYXRlU2Nh
bkNvbmZpZxI/Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkNyZWF0
ZVNjYW5Db25maWdSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52
MWJldGEuU2NhbkNvbmZpZyJRgtPkkwI2IicvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKn0v
c2NhbkNvbmZpZ3M6C3NjYW5fY29uZmln2kEScGFyZW50LHNjYW5fY29uZmlnEqMBChBEZWxl
dGVTY2FuQ29uZmlnEj8uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEu
RGVsZXRlU2NhbkNvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiNoLT5JMC
KSonL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyp92kEEbmFtZRK5AQoN
R2V0U2NhbkNvbmZpZxI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRh
LkdldFNjYW5Db25maWdSZXF1ZXN0GjIuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5l
ci52MWJldGEuU2NhbkNvbmZpZyI2gtPkkwIpEicvdjFiZXRhL3tuYW1lPXByb2plY3RzLyov
c2NhbkNvbmZpZ3MvKn3aQQRuYW1lEswBCg9MaXN0U2NhbkNvbmZpZ3MSPi5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5MaXN0U2NhbkNvbmZpZ3NSZXF1ZXN0Gj8u
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuTGlzdFNjYW5Db25maWdz
UmVzcG9uc2UiOILT5JMCKRInL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyp9L3NjYW5Db25m
aWdz2kEGcGFyZW50EusBChBVcGRhdGVTY2FuQ29uZmlnEj8uZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWJldGEuVXBkYXRlU2NhbkNvbmZpZ1JlcXVlc3QaMi5nb29nbGUu
Y2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5TY2FuQ29uZmlnImKC0+STAkIyMy92
MWJldGEve3NjYW5fY29uZmlnLm5hbWU9cHJvamVjdHMvKi9zY2FuQ29uZmlncy8qfToLc2Nh
bl9jb25maWfaQRdzY2FuX2NvbmZpZyx1cGRhdGVfbWFzaxK9AQoMU3RhcnRTY2FuUnVuEjsu
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuU3RhcnRTY2FuUnVuUmVx
dWVzdBovLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLlNjYW5SdW4i
P4LT5JMCMiItL3YxYmV0YS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyp9OnN0YXJ0
OgEq2kEEbmFtZRK7AQoKR2V0U2NhblJ1bhI5Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNj
YW5uZXIudjFiZXRhLkdldFNjYW5SdW5SZXF1ZXN0Gi8uZ29vZ2xlLmNsb3VkLndlYnNlY3Vy
aXR5c2Nhbm5lci52MWJldGEuU2NhblJ1biJBgtPkkwI0EjIvdjFiZXRhL3tuYW1lPXByb2pl
Y3RzLyovc2NhbkNvbmZpZ3MvKi9zY2FuUnVucy8qfdpBBG5hbWUSzgEKDExpc3RTY2FuUnVu
cxI7Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkxpc3RTY2FuUnVu
c1JlcXVlc3QaPC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5MaXN0
U2NhblJ1bnNSZXNwb25zZSJDgtPkkwI0EjIvdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9z
Y2FuQ29uZmlncy8qfS9zY2FuUnVuc9pBBnBhcmVudBLFAQoLU3RvcFNjYW5SdW4SOi5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5TdG9wU2NhblJ1blJlcXVlc3Qa
Ly5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5TY2FuUnVuIkmC0+ST
AjwiNy92MWJldGEve25hbWU9cHJvamVjdHMvKi9zY2FuQ29uZmlncy8qL3NjYW5SdW5zLyp9
OnN0b3A6ASraQQRuYW1lEuUBCg9MaXN0Q3Jhd2xlZFVybHMSPi5nb29nbGUuY2xvdWQud2Vi
c2VjdXJpdHlzY2FubmVyLnYxYmV0YS5MaXN0Q3Jhd2xlZFVybHNSZXF1ZXN0Gj8uZ29vZ2xl
LmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuTGlzdENyYXdsZWRVcmxzUmVzcG9u
c2UiUYLT5JMCQhJAL3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKi9z
Y2FuUnVucy8qfS9jcmF3bGVkVXJsc9pBBnBhcmVudBLGAQoKR2V0RmluZGluZxI5Lmdvb2ds
ZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkdldEZpbmRpbmdSZXF1ZXN0Gi8u
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGEuRmluZGluZyJMgtPkkwI/
Ej0vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKi9zY2FuUnVucy8qL2Zp
bmRpbmdzLyp92kEEbmFtZRLgAQoMTGlzdEZpbmRpbmdzEjsuZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWJldGEuTGlzdEZpbmRpbmdzUmVxdWVzdBo8Lmdvb2dsZS5jbG91
ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkxpc3RGaW5kaW5nc1Jlc3BvbnNlIlWC0+ST
Aj8SPS92MWJldGEve3BhcmVudD1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1bnMv
Kn0vZmluZGluZ3PaQQ1wYXJlbnQsZmlsdGVyEvkBChRMaXN0RmluZGluZ1R5cGVTdGF0cxJD
Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLkxpc3RGaW5kaW5nVHlw
ZVN0YXRzUmVxdWVzdBpELmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRh
Lkxpc3RGaW5kaW5nVHlwZVN0YXRzUmVzcG9uc2UiVoLT5JMCRxJFL3YxYmV0YS97cGFyZW50
PXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKi9zY2FuUnVucy8qfS9maW5kaW5nVHlwZVN0YXRz
2kEGcGFyZW50GlXKQSF3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb23SQS5odHRw
czovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQqECCipjb20uZ29v
Z2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWJldGFCF1dlYlNlY3VyaXR5U2Nhbm5l
clByb3RvUAFaWmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJpdHlzY2FubmVyL2FwaXYx
YmV0YS93ZWJzZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJwYqoCJkdvb2ds
ZS5DbG91ZC5XZWJTZWN1cml0eVNjYW5uZXIuVjFCZXRhygImR29vZ2xlXENsb3VkXFdlYlNl
Y3VyaXR5U2Nhbm5lclxWMWJldGHqAilHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNjYW5u
ZXI6OlYxYmV0YUq+XQoHEgUPAJwDAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCgoICgECEgMRAC8KCQoCAwASAxMAJgoJCgIDARIDFAAhCgkKAgMCEgMVACkKCQoCAwMS
AxYAIwoJCgIDBBIDFwBCCgkKAgMFEgMYAD4KCQoCAwYSAxkASQoJCgIDBxIDGgBCCgkKAgMI
EgMbAD8KCQoCAwkSAxwAJQoJCgIDChIDHQAqCggKAQgSAx8AQwoJCgIIJRIDHwBDCggKAQgS
AyAAcQoJCgIICxIDIABxCggKAQgSAyEAIgoJCgIIChIDIQAiCggKAQgSAyIAOAoJCgIICBID
IgA4CggKAQgSAyMAQwoJCgIIARIDIwBDCggKAQgSAyQAQwoJCgIIKRIDJABDCggKAQgSAyUA
QgoJCgIILRIDJQBCCvYBCgIGABIFKgCaAQEa6AEgQ2xvdWQgV2ViIFNlY3VyaXR5IFNjYW5u
ZXIgU2VydmljZSBpZGVudGlmaWVzIHNlY3VyaXR5IHZ1bG5lcmFiaWxpdGllcyBpbiB3ZWIK
IGFwcGxpY2F0aW9ucyBob3N0ZWQgb24gR29vZ2xlIENsb3VkIFBsYXRmb3JtLiBJdCBjcmF3
bHMgeW91ciBhcHBsaWNhdGlvbiwgYW5kCiBhdHRlbXB0cyB0byBleGVyY2lzZSBhcyBtYW55
IHVzZXIgaW5wdXRzIGFuZCBldmVudCBoYW5kbGVycyBhcyBwb3NzaWJsZS4KCgoKAwYAARID
KggaCgoKAwYAAxIDKwJJCgwKBQYAA5kIEgMrAkkKCgoDBgADEgMsAlYKDAoFBgADmggSAywC
VgopCgQGAAIAEgQvAjUDGhsgQ3JlYXRlcyBhIG5ldyBTY2FuQ29uZmlnLgoKDAoFBgACAAES
Ay8GFgoMCgUGAAIAAhIDLxcuCgwKBQYAAgADEgMvOUMKDQoFBgACAAQSBDAEMwYKEQoJBgAC
AASwyrwiEgQwBDMGCgwKBQYAAgAEEgM0BEAKDwoIBgACAASbCAASAzQEQApHCgQGAAIBEgQ4
Aj0DGjkgRGVsZXRlcyBhbiBleGlzdGluZyBTY2FuQ29uZmlnIGFuZCBpdHMgY2hpbGQgcmVz
b3VyY2VzLgoKDAoFBgACAQESAzgGFgoMCgUGAAIBAhIDOBcuCgwKBQYAAgEDEgM4OU4KDQoF
BgACAQQSBDkEOwYKEQoJBgACAQSwyrwiEgQ5BDsGCgwKBQYAAgEEEgM8BDIKDwoIBgACAQSb
CAASAzwEMgoiCgQGAAICEgRAAkUDGhQgR2V0cyBhIFNjYW5Db25maWcuCgoMCgUGAAICARID
QAYTCgwKBQYAAgICEgNAFCgKDAoFBgACAgMSA0AzPQoNCgUGAAICBBIEQQRDBgoRCgkGAAIC
BLDKvCISBEEEQwYKDAoFBgACAgQSA0QEMgoPCggGAAICBJsIABIDRAQyCjgKBAYAAgMSBEgC
TQMaKiBMaXN0cyBTY2FuQ29uZmlncyB1bmRlciBhIGdpdmVuIHByb2plY3QuCgoMCgUGAAID
ARIDSAYVCgwKBQYAAgMCEgNIFiwKDAoFBgACAwMSA0g3TgoNCgUGAAIDBBIESQRLBgoRCgkG
AAIDBLDKvCISBEkESwYKDAoFBgACAwQSA0wENAoPCggGAAIDBJsIABIDTAQ0ClkKBAYAAgQS
BFACVgMaSyBVcGRhdGVzIGEgU2NhbkNvbmZpZy4gVGhpcyBtZXRob2Qgc3VwcG9ydCBwYXJ0
aWFsIHVwZGF0ZSBvZiBhIFNjYW5Db25maWcuCgoMCgUGAAIEARIDUAYWCgwKBQYAAgQCEgNQ
Fy4KDAoFBgACBAMSA1A5QwoNCgUGAAIEBBIEUQRUBgoRCgkGAAIEBLDKvCISBFEEVAYKDAoF
BgACBAQSA1UERQoPCggGAAIEBJsIABIDVQRFCkIKBAYAAgUSBFkCXwMaNCBTdGFydCBhIFNj
YW5SdW4gYWNjb3JkaW5nIHRvIHRoZSBnaXZlbiBTY2FuQ29uZmlnLgoKDAoFBgACBQESA1kG
EgoMCgUGAAIFAhIDWRMmCgwKBQYAAgUDEgNZMTgKDQoFBgACBQQSBFoEXQYKEQoJBgACBQSw
yrwiEgRaBF0GCgwKBQYAAgUEEgNeBDIKDwoIBgACBQSbCAASA14EMgofCgQGAAIGEgRiAmcD
GhEgR2V0cyBhIFNjYW5SdW4uCgoMCgUGAAIGARIDYgYQCgwKBQYAAgYCEgNiESIKDAoFBgAC
BgMSA2ItNAoNCgUGAAIGBBIEYwRlBgoRCgkGAAIGBLDKvCISBGMEZQYKDAoFBgACBgQSA2YE
MgoPCggGAAIGBJsIABIDZgQyCmMKBAYAAgcSBGsCcAMaVSBMaXN0cyBTY2FuUnVucyB1bmRl
ciBhIGdpdmVuIFNjYW5Db25maWcsIGluIGRlc2NlbmRpbmcgb3JkZXIgb2YgU2NhblJ1bgog
c3RvcCB0aW1lLgoKDAoFBgACBwESA2sGEgoMCgUGAAIHAhIDaxMmCgwKBQYAAgcDEgNrMUUK
DQoFBgACBwQSBGwEbgYKEQoJBgACBwSwyrwiEgRsBG4GCgwKBQYAAgcEEgNvBDQKDwoIBgAC
BwSbCAASA28ENApBCgQGAAIIEgRzAnkDGjMgU3RvcHMgYSBTY2FuUnVuLiBUaGUgc3RvcHBl
ZCBTY2FuUnVuIGlzIHJldHVybmVkLgoKDAoFBgACCAESA3MGEQoMCgUGAAIIAhIDcxIkCgwK
BQYAAggDEgNzLzYKDQoFBgACCAQSBHQEdwYKEQoJBgACCASwyrwiEgR0BHcGCgwKBQYAAggE
EgN4BDIKDwoIBgACCASbCAASA3gEMgo4CgQGAAIJEgV8AoEBAxopIExpc3QgQ3Jhd2xlZFVy
bHMgdW5kZXIgYSBnaXZlbiBTY2FuUnVuLgoKDAoFBgACCQESA3wGFQoMCgUGAAIJAhIDfBYs
CgwKBQYAAgkDEgN8N04KDQoFBgACCQQSBH0EfwYKEQoJBgACCQSwyrwiEgR9BH8GCg0KBQYA
AgkEEgSAAQQ0ChAKCAYAAgkEmwgAEgSAAQQ0CiEKBAYAAgoSBoQBAokBAxoRIEdldHMgYSBG
aW5kaW5nLgoKDQoFBgACCgESBIQBBhAKDQoFBgACCgISBIQBESIKDQoFBgACCgMSBIQBLTQK
DwoFBgACCgQSBoUBBIcBBgoTCgkGAAIKBLDKvCISBoUBBIcBBgoNCgUGAAIKBBIEiAEEMgoQ
CggGAAIKBJsIABIEiAEEMgo2CgQGAAILEgaMAQKRAQMaJiBMaXN0IEZpbmRpbmdzIHVuZGVy
IGEgZ2l2ZW4gU2NhblJ1bi4KCg0KBQYAAgsBEgSMAQYSCg0KBQYAAgsCEgSMARMmCg0KBQYA
AgsDEgSMATFFCg8KBQYAAgsEEgaNAQSPAQYKEwoJBgACCwSwyrwiEgaNAQSPAQYKDQoFBgAC
CwQSBJABBDsKEAoIBgACCwSbCAASBJABBDsKQgoEBgACDBIGlAECmQEDGjIgTGlzdCBhbGwg
RmluZGluZ1R5cGVTdGF0cyB1bmRlciBhIGdpdmVuIFNjYW5SdW4uCgoNCgUGAAIMARIElAEG
GgoNCgUGAAIMAhIElAEbNgoNCgUGAAIMAxIElAFBXQoPCgUGAAIMBBIGlQEElwEGChMKCQYA
AgwEsMq8IhIGlQEElwEGCg0KBQYAAgwEEgSYAQQ0ChAKCAYAAgwEmwgAEgSYAQQ0CjoKAgQA
EgadAQCpAQEaLCBSZXF1ZXN0IGZvciB0aGUgYENyZWF0ZVNjYW5Db25maWdgIG1ldGhvZC4K
CgsKAwQAARIEnQEIHwqfAQoEBAACABIGoAECpQEEGo4BIFJlcXVpcmVkLiBUaGUgcGFyZW50
IHJlc291cmNlIG5hbWUgd2hlcmUgdGhlIHNjYW4gaXMgY3JlYXRlZCwgd2hpY2ggc2hvdWxk
IGJlIGEKIHByb2plY3QgcmVzb3VyY2UgbmFtZSBpbiB0aGUgZm9ybWF0ICdwcm9qZWN0cy97
cHJvamVjdElkfScuCgoNCgUEAAIABRIEoAECCAoNCgUEAAIAARIEoAEJDwoNCgUEAAIAAxIE
oAESEwoPCgUEAAIACBIGoAEUpQEDChAKCAQAAgAInAgAEgShAQQqChEKBwQAAgAInwgSBqIB
BKQBBQo3CgQEAAIBEgSoAQJGGikgUmVxdWlyZWQuIFRoZSBTY2FuQ29uZmlnIHRvIGJlIGNy
ZWF0ZWQuCgoNCgUEAAIBBhIEqAECDAoNCgUEAAIBARIEqAENGAoNCgUEAAIBAxIEqAEbHAoN
CgUEAAIBCBIEqAEdRQoQCggEAAIBCJwIABIEqAEeRAo6CgIEARIGrAEAtQEBGiwgUmVxdWVz
dCBmb3IgdGhlIGBEZWxldGVTY2FuQ29uZmlnYCBtZXRob2QuCgoLCgMEAQESBKwBCB8KogEK
BAQBAgASBq8BArQBBBqRASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNj
YW5Db25maWcgdG8gYmUgZGVsZXRlZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZvcm1hdCBv
ZiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0nLgoK
DQoFBAECAAUSBK8BAggKDQoFBAECAAESBK8BCQ0KDQoFBAECAAMSBK8BEBEKDwoFBAECAAgS
Bq8BErQBAwoQCggEAQIACJwIABIEsAEEKgoRCgcEAQIACJ8IEgaxAQSzAQUKNwoCBAISBrgB
AMEBARopIFJlcXVlc3QgZm9yIHRoZSBgR2V0U2NhbkNvbmZpZ2AgbWV0aG9kLgoKCwoDBAIB
EgS4AQgcCqMBCgQEAgIAEga7AQLAAQQakgEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBTY2FuQ29uZmlnIHRvIGJlIHJldHVybmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRo
ZQogZm9ybWF0IG9mICdwcm9qZWN0cy97cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNv
bmZpZ0lkfScuCgoNCgUEAgIABRIEuwECCAoNCgUEAgIAARIEuwEJDQoNCgUEAgIAAxIEuwEQ
EQoPCgUEAgIACBIGuwESwAEDChAKCAQCAgAInAgAEgS8AQQqChEKBwQCAgAInwgSBr0BBL8B
BQo5CgIEAxIGxAEA1wEBGisgUmVxdWVzdCBmb3IgdGhlIGBMaXN0U2NhbkNvbmZpZ3NgIG1l
dGhvZC4KCgsKAwQDARIExAEIHgqEAQoEBAMCABIGxwECzAEEGnQgUmVxdWlyZWQuIFRoZSBw
YXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgcHJvamVjdCByZXNvdXJj
ZSBuYW1lIGluIHRoZQogZm9ybWF0ICdwcm9qZWN0cy97cHJvamVjdElkfScuCgoNCgUEAwIA
BRIExwECCAoNCgUEAwIAARIExwEJDwoNCgUEAwIAAxIExwESEwoPCgUEAwIACBIGxwEUzAED
ChAKCAQDAgAInAgAEgTIAQQqChEKBwQDAgAInwgSBskBBMsBBQrPAQoEBAMCARIE0QECGBrA
ASBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRvIGJlIHJldHVybmVk
LiBUaGlzIHNob3VsZCBiZSBhCiBgbmV4dF9wYWdlX3Rva2VuYCB2YWx1ZSByZXR1cm5lZCBm
cm9tIGEgcHJldmlvdXMgTGlzdCByZXF1ZXN0LgogSWYgdW5zcGVjaWZpZWQsIHRoZSBmaXJz
dCBwYWdlIG9mIHJlc3VsdHMgaXMgcmV0dXJuZWQuCgoNCgUEAwIBBRIE0QECCAoNCgUEAwIB
ARIE0QEJEwoNCgUEAwIBAxIE0QEWFwquAQoEBAMCAhIE1gECFhqfASBUaGUgbWF4aW11bSBu
dW1iZXIgb2YgU2NhbkNvbmZpZ3MgdG8gcmV0dXJuLCBjYW4gYmUgbGltaXRlZCBieSBzZXJ2
ZXIuCiBJZiBub3Qgc3BlY2lmaWVkIG9yIG5vdCBwb3NpdGl2ZSwgdGhlIGltcGxlbWVudGF0
aW9uIHdpbGwgc2VsZWN0IGEKIHJlYXNvbmFibGUgdmFsdWUuCgoNCgUEAwICBRIE1gECBwoN
CgUEAwICARIE1gEIEQoNCgUEAwICAxIE1gEUFQpBCgIEBBIG2gEA5AEBGjMgUmVxdWVzdCBm
b3IgdGhlIGBVcGRhdGVTY2FuQ29uZmlnUmVxdWVzdGAgbWV0aG9kLgoKCwoDBAQBEgTaAQgf
CrsBCgQEBAIAEgTeAQJGGqwBIFJlcXVpcmVkLiBUaGUgU2NhbkNvbmZpZyB0byBiZSB1cGRh
dGVkLiBUaGUgbmFtZSBmaWVsZCBtdXN0IGJlIHNldCB0byBpZGVudGlmeSB0aGUKIHJlc291
cmNlIHRvIGJlIHVwZGF0ZWQuIFRoZSB2YWx1ZXMgb2YgZmllbGRzIG5vdCBjb3ZlcmVkIGJ5
IHRoZSBtYXNrCiB3aWxsIGJlIGlnbm9yZWQuCgoNCgUEBAIABhIE3gECDAoNCgUEBAIAARIE
3gENGAoNCgUEBAIAAxIE3gEbHAoNCgUEBAIACBIE3gEdRQoQCggEBAIACJwIABIE3gEeRArB
AQoEBAQCARIE4wECVRqyASBSZXF1aXJlZC4gVGhlIHVwZGF0ZSBtYXNrIGFwcGxpZXMgdG8g
dGhlIHJlc291cmNlLiBGb3IgdGhlIGBGaWVsZE1hc2tgIGRlZmluaXRpb24sCiBzZWUKIGh0
dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvZG9jcy9yZWZl
cmVuY2UvZ29vZ2xlLnByb3RvYnVmI2ZpZWxkbWFzawoKDQoFBAQCAQYSBOMBAhsKDQoFBAQC
AQESBOMBHCcKDQoFBAQCAQMSBOMBKisKDQoFBAQCAQgSBOMBLFQKEAoIBAQCAQicCAASBOMB
LVMKOgoCBAUSBucBAO4BARosIFJlc3BvbnNlIGZvciB0aGUgYExpc3RTY2FuQ29uZmlnc2Ag
bWV0aG9kLgoKCwoDBAUBEgTnAQgfCjEKBAQFAgASBOkBAicaIyBUaGUgbGlzdCBvZiBTY2Fu
Q29uZmlncyByZXR1cm5lZC4KCg0KBQQFAgAEEgTpAQIKCg0KBQQFAgAGEgTpAQsVCg0KBQQF
AgABEgTpARYiCg0KBQQFAgADEgTpASUmCm8KBAQFAgESBO0BAh0aYSBUb2tlbiB0byByZXRy
aWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBu
bwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBAUCAQUSBO0BAggKDQoFBAUCAQES
BO0BCRgKDQoFBAUCAQMSBO0BGxwKNgoCBAYSBvEBAPoBARooIFJlcXVlc3QgZm9yIHRoZSBg
U3RhcnRTY2FuUnVuYCBtZXRob2QuCgoLCgMEBgESBPEBCBsKnwEKBAQGAgASBvQBAvkBBBqO
ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNjYW5Db25maWcgdG8gYmUg
dXNlZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZvcm1hdCBvZiAncHJvamVjdHMve3Byb2pl
Y3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0nLgoKDQoFBAYCAAUSBPQBAggKDQoF
BAYCAAESBPQBCQ0KDQoFBAYCAAMSBPQBEBEKDwoFBAYCAAgSBvQBEvkBAwoQCggEBgIACJwI
ABIE9QEEKgoRCgcEBgIACJ8IEgb2AQT4AQUKNAoCBAcSBv0BAIcCARomIFJlcXVlc3QgZm9y
IHRoZSBgR2V0U2NhblJ1bmAgbWV0aG9kLgoKCwoDBAcBEgT9AQgZCrYBCgQEBwIAEgaBAgKG
AgQapQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTY2FuUnVuIHRvIGJl
IHJldHVybmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0IG9mCiAncHJvamVjdHMv
e3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhblJ1bnMve3NjYW5S
dW5JZH0nLgoKDQoFBAcCAAUSBIECAggKDQoFBAcCAAESBIECCQ0KDQoFBAcCAAMSBIECEBEK
DwoFBAcCAAgSBoECEoYCAwoQCggEBwIACJwIABIEggIEKgoRCgcEBwIACJ8IEgaDAgSFAgUK
NgoCBAgSBooCAJ0CARooIFJlcXVlc3QgZm9yIHRoZSBgTGlzdFNjYW5SdW5zYCBtZXRob2Qu
CgoLCgMECAESBIoCCBsKnQEKBAQIAgASBo0CApICBBqMASBSZXF1aXJlZC4gVGhlIHBhcmVu
dCByZXNvdXJjZSBuYW1lLCB3aGljaCBzaG91bGQgYmUgYSBzY2FuIHJlc291cmNlIG5hbWUg
aW4gdGhlCiBmb3JtYXQgJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2Fu
Q29uZmlnSWR9Jy4KCg0KBQQIAgAFEgSNAgIICg0KBQQIAgABEgSNAgkPCg0KBQQIAgADEgSN
AhITCg8KBQQIAgAIEgaNAhSSAgMKEAoIBAgCAAicCAASBI4CBCoKEQoHBAgCAAifCBIGjwIE
kQIFCs8BCgQECAIBEgSXAgIYGsABIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJl
c3VsdHMgdG8gYmUgcmV0dXJuZWQuIFRoaXMgc2hvdWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9r
ZW5gIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBMaXN0IHJlcXVlc3QuCiBJZiB1
bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBhZ2Ugb2YgcmVzdWx0cyBpcyByZXR1cm5lZC4KCg0K
BQQIAgEFEgSXAgIICg0KBQQIAgEBEgSXAgkTCg0KBQQIAgEDEgSXAhYXCqsBCgQECAICEgSc
AgIWGpwBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBTY2FuUnVucyB0byByZXR1cm4sIGNhbiBi
ZSBsaW1pdGVkIGJ5IHNlcnZlci4KIElmIG5vdCBzcGVjaWZpZWQgb3Igbm90IHBvc2l0aXZl
LCB0aGUgaW1wbGVtZW50YXRpb24gd2lsbCBzZWxlY3QgYQogcmVhc29uYWJsZSB2YWx1ZS4K
Cg0KBQQIAgIFEgScAgIHCg0KBQQIAgIBEgScAggRCg0KBQQIAgIDEgScAhQVCjcKAgQJEgag
AgCnAgEaKSBSZXNwb25zZSBmb3IgdGhlIGBMaXN0U2NhblJ1bnNgIG1ldGhvZC4KCgsKAwQJ
ARIEoAIIHAouCgQECQIAEgSiAgIhGiAgVGhlIGxpc3Qgb2YgU2NhblJ1bnMgcmV0dXJuZWQu
CgoNCgUECQIABBIEogICCgoNCgUECQIABhIEogILEgoNCgUECQIAARIEogITHAoNCgUECQIA
AxIEogIfIApvCgQECQIBEgSmAgIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFn
ZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBp
biB0aGUgbGlzdC4KCg0KBQQJAgEFEgSmAgIICg0KBQQJAgEBEgSmAgkYCg0KBQQJAgEDEgSm
AhscCjUKAgQKEgaqAgC0AgEaJyBSZXF1ZXN0IGZvciB0aGUgYFN0b3BTY2FuUnVuYCBtZXRo
b2QuCgoLCgMECgESBKoCCBoKtQEKBAQKAgASBq4CArMCBBqkASBSZXF1aXJlZC4gVGhlIHJl
c291cmNlIG5hbWUgb2YgdGhlIFNjYW5SdW4gdG8gYmUgc3RvcHBlZC4gVGhlIG5hbWUgZm9s
bG93cyB0aGUKIGZvcm1hdCBvZgogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdz
L3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQKAgAFEgSuAgII
Cg0KBQQKAgABEgSuAgkNCg0KBQQKAgADEgSuAhARCg8KBQQKAgAIEgauAhKzAgMKEAoIBAoC
AAicCAASBK8CBCoKEQoHBAoCAAifCBIGsAIEsgIFCjkKAgQLEga3AgDLAgEaKyBSZXF1ZXN0
IGZvciB0aGUgYExpc3RDcmF3bGVkVXJsc2AgbWV0aG9kLgoKCwoDBAsBEgS3AggeCrcBCgQE
CwIAEga7AgLAAgQapgEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hp
Y2ggc2hvdWxkIGJlIGEgc2NhbiBydW4gcmVzb3VyY2UgbmFtZSBpbiB0aGUKIGZvcm1hdAog
J3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5S
dW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQLAgAFEgS7AgIICg0KBQQLAgABEgS7AgkPCg0KBQQL
AgADEgS7AhITCg8KBQQLAgAIEga7AhTAAgMKEAoIBAsCAAicCAASBLwCBCoKEQoHBAsCAAif
CBIGvQIEvwIFCs8BCgQECwIBEgTFAgIYGsABIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdl
IG9mIHJlc3VsdHMgdG8gYmUgcmV0dXJuZWQuIFRoaXMgc2hvdWxkIGJlIGEKIGBuZXh0X3Bh
Z2VfdG9rZW5gIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBMaXN0IHJlcXVlc3Qu
CiBJZiB1bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBhZ2Ugb2YgcmVzdWx0cyBpcyByZXR1cm5l
ZC4KCg0KBQQLAgEFEgTFAgIICg0KBQQLAgEBEgTFAgkTCg0KBQQLAgEDEgTFAhYXCq4BCgQE
CwICEgTKAgIWGp8BIFRoZSBtYXhpbXVtIG51bWJlciBvZiBDcmF3bGVkVXJscyB0byByZXR1
cm4sIGNhbiBiZSBsaW1pdGVkIGJ5IHNlcnZlci4KIElmIG5vdCBzcGVjaWZpZWQgb3Igbm90
IHBvc2l0aXZlLCB0aGUgaW1wbGVtZW50YXRpb24gd2lsbCBzZWxlY3QgYQogcmVhc29uYWJs
ZSB2YWx1ZS4KCg0KBQQLAgIFEgTKAgIHCg0KBQQLAgIBEgTKAggRCg0KBQQLAgIDEgTKAhQV
CjoKAgQMEgbOAgDVAgEaLCBSZXNwb25zZSBmb3IgdGhlIGBMaXN0Q3Jhd2xlZFVybHNgIG1l
dGhvZC4KCgsKAwQMARIEzgIIHwoxCgQEDAIAEgTQAgInGiMgVGhlIGxpc3Qgb2YgQ3Jhd2xl
ZFVybHMgcmV0dXJuZWQuCgoNCgUEDAIABBIE0AICCgoNCgUEDAIABhIE0AILFQoNCgUEDAIA
ARIE0AIWIgoNCgUEDAIAAxIE0AIlJgpvCgQEDAIBEgTUAgIdGmEgVG9rZW4gdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8K
IG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQMAgEFEgTUAgIICg0KBQQMAgEBEgTU
AgkYCg0KBQQMAgEDEgTUAhscCjQKAgQNEgbYAgDiAgEaJiBSZXF1ZXN0IGZvciB0aGUgYEdl
dEZpbmRpbmdgIG1ldGhvZC4KCgsKAwQNARIE2AIIGQrLAQoEBA0CABIG3AIC4QIEGroBIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgRmluZGluZyB0byBiZSByZXR1cm5l
ZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZvcm1hdCBvZgogJ3Byb2plY3RzL3twcm9qZWN0
SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9L2Zp
bmRpbmdzL3tmaW5kaW5nSWR9Jy4KCg0KBQQNAgAFEgTcAgIICg0KBQQNAgABEgTcAgkNCg0K
BQQNAgADEgTcAhARCg8KBQQNAgAIEgbcAhLhAgMKEAoIBA0CAAicCAASBN0CBCoKEQoHBA0C
AAifCBIG3gIE4AIFCjYKAgQOEgblAgD/AgEaKCBSZXF1ZXN0IGZvciB0aGUgYExpc3RGaW5k
aW5nc2AgbWV0aG9kLgoKCwoDBA4BEgTlAggbCrcBCgQEDgIAEgbpAgLuAgQapgEgUmVxdWly
ZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgc2NhbiBy
dW4gcmVzb3VyY2UgbmFtZSBpbiB0aGUKIGZvcm1hdAogJ3Byb2plY3RzL3twcm9qZWN0SWR9
L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0K
BQQOAgAFEgTpAgIICg0KBQQOAgABEgTpAgkPCg0KBQQOAgADEgTpAhITCg8KBQQOAgAIEgbp
AhTuAgMKEAoIBA4CAAicCAASBOoCBCoKEQoHBA4CAAifCBIG6wIE7QIFCrABCgQEDgIBEgT0
AgI9GqEBIFJlcXVpcmVkLiBUaGUgZmlsdGVyIGV4cHJlc3Npb24uIFRoZSBleHByZXNzaW9u
IG11c3QgYmUgaW4gdGhlIGZvcm1hdDogPGZpZWxkPgogPG9wZXJhdG9yPiA8dmFsdWU+Lgog
U3VwcG9ydGVkIGZpZWxkOiAnZmluZGluZ190eXBlJy4KIFN1cHBvcnRlZCBvcGVyYXRvcjog
Jz0nLgoKDQoFBA4CAQUSBPQCAggKDQoFBA4CAQESBPQCCQ8KDQoFBA4CAQMSBPQCEhMKDQoF
BA4CAQgSBPQCFDwKEAoIBA4CAQicCAASBPQCFTsKzwEKBAQOAgISBPkCAhgawAEgQSB0b2tl
biBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0byBiZSByZXR1cm5lZC4gVGhpcyBz
aG91bGQgYmUgYQogYG5leHRfcGFnZV90b2tlbmAgdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHBy
ZXZpb3VzIExpc3QgcmVxdWVzdC4KIElmIHVuc3BlY2lmaWVkLCB0aGUgZmlyc3QgcGFnZSBv
ZiByZXN1bHRzIGlzIHJldHVybmVkLgoKDQoFBA4CAgUSBPkCAggKDQoFBA4CAgESBPkCCRMK
DQoFBA4CAgMSBPkCFhcKqwEKBAQOAgMSBP4CAhYanAEgVGhlIG1heGltdW0gbnVtYmVyIG9m
IEZpbmRpbmdzIHRvIHJldHVybiwgY2FuIGJlIGxpbWl0ZWQgYnkgc2VydmVyLgogSWYgbm90
IHNwZWNpZmllZCBvciBub3QgcG9zaXRpdmUsIHRoZSBpbXBsZW1lbnRhdGlvbiB3aWxsIHNl
bGVjdCBhCiByZWFzb25hYmxlIHZhbHVlLgoKDQoFBA4CAwUSBP4CAgcKDQoFBA4CAwESBP4C
CBEKDQoFBA4CAwMSBP4CFBUKNwoCBA8SBoIDAIkDARopIFJlc3BvbnNlIGZvciB0aGUgYExp
c3RGaW5kaW5nc2AgbWV0aG9kLgoKCwoDBA8BEgSCAwgcCi4KBAQPAgASBIQDAiAaICBUaGUg
bGlzdCBvZiBGaW5kaW5ncyByZXR1cm5lZC4KCg0KBQQPAgAEEgSEAwIKCg0KBQQPAgAGEgSE
AwsSCg0KBQQPAgABEgSEAxMbCg0KBQQPAgADEgSEAx4fCm8KBAQPAgESBIgDAh0aYSBUb2tl
biB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRo
ZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoKDQoFBA8CAQUSBIgDAggK
DQoFBA8CAQESBIgDCRgKDQoFBA8CAQMSBIgDGxwKPgoCBBASBowDAJYDARowIFJlcXVlc3Qg
Zm9yIHRoZSBgTGlzdEZpbmRpbmdUeXBlU3RhdHNgIG1ldGhvZC4KCgsKAwQQARIEjAMIIwq3
AQoEBBACABIGkAMClQMEGqYBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUs
IHdoaWNoIHNob3VsZCBiZSBhIHNjYW4gcnVuIHJlc291cmNlIG5hbWUgaW4gdGhlCiBmb3Jt
YXQKICdwcm9qZWN0cy97cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfS9z
Y2FuUnVucy97c2NhblJ1bklkfScuCgoNCgUEEAIABRIEkAMCCAoNCgUEEAIAARIEkAMJDwoN
CgUEEAIAAxIEkAMSEwoPCgUEEAIACBIGkAMUlQMDChAKCAQQAgAInAgAEgSRAwQqChEKBwQQ
AgAInwgSBpIDBJQDBQo/CgIEERIGmQMAnAMBGjEgUmVzcG9uc2UgZm9yIHRoZSBgTGlzdEZp
bmRpbmdUeXBlU3RhdHNgIG1ldGhvZC4KCgsKAwQRARIEmQMIJAo2CgQEEQIAEgSbAwIzGigg
VGhlIGxpc3Qgb2YgRmluZGluZ1R5cGVTdGF0cyByZXR1cm5lZC4KCg0KBQQRAgAEEgSbAwIK
Cg0KBQQRAgAGEgSbAwsbCg0KBQQRAgABEgSbAxwuCg0KBQQRAgADEgSbAzEyYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::CreateScanConfigRequest ===
    # Fields for CreateScanConfigRequest
    # Field: parent Type: 9 ()
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfig)

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::DeleteScanConfigRequest ===
    # Fields for DeleteScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanConfigRequest ===
    # Fields for GetScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsRequest ===
    # Fields for ListScanConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::UpdateScanConfigRequest ===
    # Fields for UpdateScanConfigRequest
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsResponse ===
    # Fields for ListScanConfigsResponse
    # Field: scan_configs Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StartScanRunRequest ===
    # Fields for StartScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanRunRequest ===
    # Fields for GetScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsRequest ===
    # Fields for ListScanRunsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsResponse ===
    # Fields for ListScanRunsResponse
    # Field: scan_runs Type: 11 (.google.cloud.websecurityscanner.v1beta.ScanRun)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StopScanRunRequest ===
    # Fields for StopScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsRequest ===
    # Fields for ListCrawledUrlsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsResponse ===
    # Fields for ListCrawledUrlsResponse
    # Field: crawled_urls Type: 11 (.google.cloud.websecurityscanner.v1beta.CrawledUrl)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetFindingRequest ===
    # Fields for GetFindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsRequest ===
    # Fields for ListFindingsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsResponse ===
    # Fields for ListFindingsResponse
    # Field: findings Type: 11 (.google.cloud.websecurityscanner.v1beta.Finding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsRequest ===
    # Fields for ListFindingTypeStatsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsResponse ===
    # Fields for ListFindingTypeStatsResponse
    # Field: finding_type_stats Type: 11 (.google.cloud.websecurityscanner.v1beta.FindingTypeStats)

# === Service Client: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::WebSecurityScannerClient ===
package Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::WebSecurityScannerClient;

=pod

=head2 Service Client: Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::WebSecurityScannerClient

Client stub representing the remote C<WebSecurityScanner> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<websecurityscanner.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'websecurityscanner.googleapis.com:443' );

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

sub create_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::CreateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'CreateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig',
    });
}

sub delete_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::DeleteScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'DeleteScanConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'GetScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig',
    });
}

sub list_scan_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'ListScanConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsResponse',
    });
}

sub update_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::UpdateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'UpdateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig',
    });
}

sub start_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StartScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'StartScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun',
    });
}

sub get_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'GetScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun',
    });
}

sub list_scan_runs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'ListScanRuns',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsResponse',
    });
}

sub stop_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StopScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'StopScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun',
    });
}

sub list_crawled_urls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'ListCrawledUrls',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsResponse',
    });
}

sub get_finding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetFindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'GetFinding',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::Finding::Finding',
    });
}

sub list_findings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'ListFindings',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsResponse',
    });
}

sub list_finding_type_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1beta.WebSecurityScanner',
        method         => 'ListFindingTypeStats',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/web_security_scanner.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::CreateScanConfigRequest->new({
        parent => $parent,
        scan_config => $scan_config,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::CreateScanConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/web_security_scanner.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::CreateScanConfigRequest

Request for the `CreateScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the scan is created, which should be a
project resource name in the format 'projects/{projectId}'.

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig>)

Required. The ScanConfig to be created.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::DeleteScanConfigRequest

Request for the `DeleteScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be deleted. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanConfigRequest

Request for the `GetScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be returned. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsRequest

Request for the `ListScanConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, which should be a project resource name in the
format 'projects/{projectId}'.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to be returned. This should be a
`next_page_token` value returned from a previous List request.
If unspecified, the first page of results is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of ScanConfigs to return, can be limited by server.
If not specified or not positive, the implementation will select a
reasonable value.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::UpdateScanConfigRequest

Request for the `UpdateScanConfigRequest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig>)

Required. The ScanConfig to be updated. The name field must be set to identify the
resource to be updated. The values of fields not covered by the mask
will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanConfigsResponse

Response for the `ListScanConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_configs() >> / C<< $msg->scan_configs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanConfig::ScanConfig>)

The list of ScanConfigs returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StartScanRunRequest

Request for the `StartScanRun` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be used. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetScanRunRequest

Request for the `GetScanRun` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanRun to be returned. The name follows the
format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsRequest

Request for the `ListScanRuns` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, which should be a scan resource name in the
format 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to be returned. This should be a
`next_page_token` value returned from a previous List request.
If unspecified, the first page of results is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of ScanRuns to return, can be limited by server.
If not specified or not positive, the implementation will select a
reasonable value.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListScanRunsResponse

Response for the `ListScanRuns` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_runs() >> / C<< $msg->scan_runs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::ScanRun::ScanRun>)

The list of ScanRuns returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::StopScanRunRequest

Request for the `StopScanRun` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanRun to be stopped. The name follows the
format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsRequest

Request for the `ListCrawledUrls` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, which should be a scan run resource name in the
format
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to be returned. This should be a
`next_page_token` value returned from a previous List request.
If unspecified, the first page of results is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of CrawledUrls to return, can be limited by server.
If not specified or not positive, the implementation will select a
reasonable value.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListCrawledUrlsResponse

Response for the `ListCrawledUrls` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crawled_urls() >> / C<< $msg->crawled_urls($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl>)

The list of CrawledUrls returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::GetFindingRequest

Request for the `GetFinding` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Finding to be returned. The name follows the
format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}/findings/{findingId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsRequest

Request for the `ListFindings` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, which should be a scan run resource name in the
format
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. The filter expression. The expression must be in the format: <field>
<operator> <value>.
Supported field: 'finding_type'.
Supported operator: '='.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying a page of results to be returned. This should be a
`next_page_token` value returned from a previous List request.
If unspecified, the first page of results is returned.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of Findings to return, can be limited by server.
If not specified or not positive, the implementation will select a
reasonable value.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingsResponse

Response for the `ListFindings` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->findings() >> / C<< $msg->findings($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::Finding::Finding>)

The list of Findings returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsRequest

Request for the `ListFindingTypeStats` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name, which should be a scan run resource name in the
format
'projects/{projectId}/scanConfigs/{scanConfigId}/scanRuns/{scanRunId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::ListFindingTypeStatsResponse

Response for the `ListFindingTypeStats` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type_stats() >> / C<< $msg->finding_type_stats($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingTypeStats::FindingTypeStats>)

The list of FindingTypeStats returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::WebSecurityScanner::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
