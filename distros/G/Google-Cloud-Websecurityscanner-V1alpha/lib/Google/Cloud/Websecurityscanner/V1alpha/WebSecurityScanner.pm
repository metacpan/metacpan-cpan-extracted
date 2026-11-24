package Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner;

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
    eval { require Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl };
    eval { require Google::Cloud::Websecurityscanner::V1alpha::Finding };
    eval { require Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats };
    eval { require Google::Cloud::Websecurityscanner::V1alpha::ScanConfig };
    eval { require Google::Cloud::Websecurityscanner::V1alpha::ScanRun };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvd2ViX3NlY3VyaXR5
X3NjYW5uZXIucHJvdG8SJ2dvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBo
YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJv
dG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aOWdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFhbHBoYS9jcmF3
bGVkX3VybC5wcm90bxo1Z29vZ2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MWFscGhh
L2ZpbmRpbmcucHJvdG8aQGdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNjYW5uZXIvdjFhbHBo
YS9maW5kaW5nX3R5cGVfc3RhdHMucHJvdG8aOWdvb2dsZS9jbG91ZC93ZWJzZWN1cml0eXNj
YW5uZXIvdjFhbHBoYS9zY2FuX2NvbmZpZy5wcm90bxo2Z29vZ2xlL2Nsb3VkL3dlYnNlY3Vy
aXR5c2Nhbm5lci92MWFscGhhL3NjYW5fcnVuLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1w
dHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvIsEBChdDcmVhdGVT
Y2FuQ29uZmlnUmVxdWVzdBJLCgZwYXJlbnQYASABKAlCM+BBAvpBLQorY2xvdWRyZXNvdXJj
ZW1hbmFnZXIuZ29vZ2xlYXBpcy5jb20vUHJvamVjdFIGcGFyZW50ElkKC3NjYW5fY29uZmln
GAIgASgLMjMuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5D
b25maWdCA+BBAlIKc2NhbkNvbmZpZyJjChdEZWxldGVTY2FuQ29uZmlnUmVxdWVzdBJICgRu
YW1lGAEgASgJQjTgQQL6QS4KLHdlYnNlY3VyaXR5c2Nhbm5lci5nb29nbGVhcGlzLmNvbS9T
Y2FuQ29uZmlnUgRuYW1lImAKFEdldFNjYW5Db25maWdSZXF1ZXN0EkgKBG5hbWUYASABKAlC
NOBBAvpBLgosd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5Db25maWdS
BG5hbWUioQEKFkxpc3RTY2FuQ29uZmlnc1JlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6
QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RSBnBhcmVu
dBIdCgpwYWdlX3Rva2VuGAIgASgJUglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAMgASgFUghw
YWdlU2l6ZSK2AQoXVXBkYXRlU2NhbkNvbmZpZ1JlcXVlc3QSWQoLc2Nhbl9jb25maWcYAiAB
KAsyMy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2NhbkNvbmZp
Z0ID4EECUgpzY2FuQ29uZmlnEkAKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLkZpZWxkTWFza0ID4EECUgp1cGRhdGVNYXNrIpkBChdMaXN0U2NhbkNvbmZpZ3NSZXNw
b25zZRJWCgxzY2FuX2NvbmZpZ3MYASADKAsyMy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlz
Y2FubmVyLnYxYWxwaGEuU2NhbkNvbmZpZ1ILc2NhbkNvbmZpZ3MSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIl8KE1N0YXJ0U2NhblJ1blJlcXVlc3QSSAoEbmFt
ZRgBIAEoCUI04EEC+kEuCix3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2Nh
bkNvbmZpZ1IEbmFtZSJaChFHZXRTY2FuUnVuUmVxdWVzdBJFCgRuYW1lGAEgASgJQjHgQQL6
QSsKKXdlYnNlY3VyaXR5c2Nhbm5lci5nb29nbGVhcGlzLmNvbS9TY2FuUnVuUgRuYW1lIp8B
ChNMaXN0U2NhblJ1bnNSZXF1ZXN0EkwKBnBhcmVudBgBIAEoCUI04EEC+kEuCix3ZWJzZWN1
cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2NhbkNvbmZpZ1IGcGFyZW50Eh0KCnBhZ2Vf
dG9rZW4YAiABKAlSCXBhZ2VUb2tlbhIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplIo0B
ChRMaXN0U2NhblJ1bnNSZXNwb25zZRJNCglzY2FuX3J1bnMYASADKAsyMC5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2NhblJ1blIIc2NhblJ1bnMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlsKElN0b3BTY2FuUnVuUmVxdWVz
dBJFCgRuYW1lGAEgASgJQjHgQQL6QSsKKXdlYnNlY3VyaXR5c2Nhbm5lci5nb29nbGVhcGlz
LmNvbS9TY2FuUnVuUgRuYW1lIp8BChZMaXN0Q3Jhd2xlZFVybHNSZXF1ZXN0EkkKBnBhcmVu
dBgBIAEoCUIx4EEC+kErCil3ZWJzZWN1cml0eXNjYW5uZXIuZ29vZ2xlYXBpcy5jb20vU2Nh
blJ1blIGcGFyZW50Eh0KCnBhZ2VfdG9rZW4YAiABKAlSCXBhZ2VUb2tlbhIbCglwYWdlX3Np
emUYAyABKAVSCHBhZ2VTaXplIpkBChdMaXN0Q3Jhd2xlZFVybHNSZXNwb25zZRJWCgxjcmF3
bGVkX3VybHMYASADKAsyMy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxw
aGEuQ3Jhd2xlZFVybFILY3Jhd2xlZFVybHMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1u
ZXh0UGFnZVRva2VuIloKEUdldEZpbmRpbmdSZXF1ZXN0EkUKBG5hbWUYASABKAlCMeBBAvpB
Kwopd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL0ZpbmRpbmdSBG5hbWUiuQEK
E0xpc3RGaW5kaW5nc1JlcXVlc3QSSQoGcGFyZW50GAEgASgJQjHgQQL6QSsKKXdlYnNlY3Vy
aXR5c2Nhbm5lci5nb29nbGVhcGlzLmNvbS9TY2FuUnVuUgZwYXJlbnQSGwoGZmlsdGVyGAIg
ASgJQgPgQQJSBmZpbHRlchIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SGwoJcGFn
ZV9zaXplGAQgASgFUghwYWdlU2l6ZSKMAQoUTGlzdEZpbmRpbmdzUmVzcG9uc2USTAoIZmlu
ZGluZ3MYASADKAsyMC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEu
RmluZGluZ1IIZmluZGluZ3MSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRv
a2VuImgKG0xpc3RGaW5kaW5nVHlwZVN0YXRzUmVxdWVzdBJJCgZwYXJlbnQYASABKAlCMeBB
AvpBKwopd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL1NjYW5SdW5SBnBhcmVu
dCKHAQocTGlzdEZpbmRpbmdUeXBlU3RhdHNSZXNwb25zZRJnChJmaW5kaW5nX3R5cGVfc3Rh
dHMYASADKAsyOS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuRmlu
ZGluZ1R5cGVTdGF0c1IQZmluZGluZ1R5cGVTdGF0czK0FgoSV2ViU2VjdXJpdHlTY2FubmVy
Et0BChBDcmVhdGVTY2FuQ29uZmlnEkAuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5l
ci52MWFscGhhLkNyZWF0ZVNjYW5Db25maWdSZXF1ZXN0GjMuZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5Db25maWciUoLT5JMCNyIoL3YxYWxwaGEve3Bh
cmVudD1wcm9qZWN0cy8qfS9zY2FuQ29uZmlnczoLc2Nhbl9jb25maWfaQRJwYXJlbnQsc2Nh
bl9jb25maWcSpQEKEERlbGV0ZVNjYW5Db25maWcSQC5nb29nbGUuY2xvdWQud2Vic2VjdXJp
dHlzY2FubmVyLnYxYWxwaGEuRGVsZXRlU2NhbkNvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJv
dG9idWYuRW1wdHkiN4LT5JMCKiooL3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9zY2FuQ29u
Zmlncy8qfdpBBG5hbWUSvAEKDUdldFNjYW5Db25maWcSPS5nb29nbGUuY2xvdWQud2Vic2Vj
dXJpdHlzY2FubmVyLnYxYWxwaGEuR2V0U2NhbkNvbmZpZ1JlcXVlc3QaMy5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2NhbkNvbmZpZyI3gtPkkwIqEigvdjFh
bHBoYS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyp92kEEbmFtZRLPAQoPTGlzdFNj
YW5Db25maWdzEj8uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLkxp
c3RTY2FuQ29uZmlnc1JlcXVlc3QaQC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVy
LnYxYWxwaGEuTGlzdFNjYW5Db25maWdzUmVzcG9uc2UiOYLT5JMCKhIoL3YxYWxwaGEve3Bh
cmVudD1wcm9qZWN0cy8qfS9zY2FuQ29uZmlnc9pBBnBhcmVudBLuAQoQVXBkYXRlU2NhbkNv
bmZpZxJALmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5VcGRhdGVT
Y2FuQ29uZmlnUmVxdWVzdBozLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFh
bHBoYS5TY2FuQ29uZmlnImOC0+STAkMyNC92MWFscGhhL3tzY2FuX2NvbmZpZy5uYW1lPXBy
b2plY3RzLyovc2NhbkNvbmZpZ3MvKn06C3NjYW5fY29uZmln2kEXc2Nhbl9jb25maWcsdXBk
YXRlX21hc2sSwAEKDFN0YXJ0U2NhblJ1bhI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNj
YW5uZXIudjFhbHBoYS5TdGFydFNjYW5SdW5SZXF1ZXN0GjAuZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWFscGhhLlNjYW5SdW4iQILT5JMCMyIuL3YxYWxwaGEve25hbWU9
cHJvamVjdHMvKi9zY2FuQ29uZmlncy8qfTpzdGFydDoBKtpBBG5hbWUSvgEKCkdldFNjYW5S
dW4SOi5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuR2V0U2NhblJ1
blJlcXVlc3QaMC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuU2Nh
blJ1biJCgtPkkwI1EjMvdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyov
c2NhblJ1bnMvKn3aQQRuYW1lEtEBCgxMaXN0U2NhblJ1bnMSPC5nb29nbGUuY2xvdWQud2Vi
c2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuTGlzdFNjYW5SdW5zUmVxdWVzdBo9Lmdvb2dsZS5j
bG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5MaXN0U2NhblJ1bnNSZXNwb25zZSJE
gtPkkwI1EjMvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKn0vc2Nh
blJ1bnPaQQZwYXJlbnQSyAEKC1N0b3BTY2FuUnVuEjsuZ29vZ2xlLmNsb3VkLndlYnNlY3Vy
aXR5c2Nhbm5lci52MWFscGhhLlN0b3BTY2FuUnVuUmVxdWVzdBowLmdvb2dsZS5jbG91ZC53
ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYS5TY2FuUnVuIkqC0+STAj0iOC92MWFscGhhL3tu
YW1lPXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKi9zY2FuUnVucy8qfTpzdG9wOgEq2kEEbmFt
ZRLoAQoPTGlzdENyYXdsZWRVcmxzEj8uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5l
ci52MWFscGhhLkxpc3RDcmF3bGVkVXJsc1JlcXVlc3QaQC5nb29nbGUuY2xvdWQud2Vic2Vj
dXJpdHlzY2FubmVyLnYxYWxwaGEuTGlzdENyYXdsZWRVcmxzUmVzcG9uc2UiUoLT5JMCQxJB
L3YxYWxwaGEve3BhcmVudD1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1bnMvKn0v
Y3Jhd2xlZFVybHPaQQZwYXJlbnQSyQEKCkdldEZpbmRpbmcSOi5nb29nbGUuY2xvdWQud2Vi
c2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuR2V0RmluZGluZ1JlcXVlc3QaMC5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuRmluZGluZyJNgtPkkwJAEj4vdjFhbHBo
YS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1bnMvKi9maW5kaW5ncy8q
fdpBBG5hbWUS4wEKDExpc3RGaW5kaW5ncxI8Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNj
YW5uZXIudjFhbHBoYS5MaXN0RmluZGluZ3NSZXF1ZXN0Gj0uZ29vZ2xlLmNsb3VkLndlYnNl
Y3VyaXR5c2Nhbm5lci52MWFscGhhLkxpc3RGaW5kaW5nc1Jlc3BvbnNlIlaC0+STAkASPi92
MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9zY2FuQ29uZmlncy8qL3NjYW5SdW5zLyp9L2Zp
bmRpbmdz2kENcGFyZW50LGZpbHRlchL8AQoUTGlzdEZpbmRpbmdUeXBlU3RhdHMSRC5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYWxwaGEuTGlzdEZpbmRpbmdUeXBlU3Rh
dHNSZXF1ZXN0GkUuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLkxp
c3RGaW5kaW5nVHlwZVN0YXRzUmVzcG9uc2UiV4LT5JMCSBJGL3YxYWxwaGEve3BhcmVudD1w
cm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1bnMvKn0vZmluZGluZ1R5cGVTdGF0c9pB
BnBhcmVudBpVykEhd2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6
Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUKlAQorY29tLmdvb2ds
ZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFhbHBoYUIXV2ViU2VjdXJpdHlTY2FubmVy
UHJvdG9QAVpbY2xvdWQuZ29vZ2xlLmNvbS9nby93ZWJzZWN1cml0eXNjYW5uZXIvYXBpdjFh
bHBoYS93ZWJzZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5uZXJwYkr8XAoHEgUP
AJkDAQq9BAoBDBIDDwASMrIEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCgoICgECEgMRADAKCQoC
AwASAxMAJgoJCgIDARIDFAAhCgkKAgMCEgMVACkKCQoCAwMSAxYAIwoJCgIDBBIDFwBDCgkK
AgMFEgMYAD8KCQoCAwYSAxkASgoJCgIDBxIDGgBDCgkKAgMIEgMbAEAKCQoCAwkSAxwAJQoJ
CgIDChIDHQAqCggKAQgSAx8AcgoJCgIICxIDHwByCggKAQgSAyAAIgoJCgIIChIDIAAiCggK
AQgSAyEAOAoJCgIICBIDIQA4CggKAQgSAyIARAoJCgIIARIDIgBECvYBCgIGABIFJwCXAQEa
6AEgQ2xvdWQgV2ViIFNlY3VyaXR5IFNjYW5uZXIgU2VydmljZSBpZGVudGlmaWVzIHNlY3Vy
aXR5IHZ1bG5lcmFiaWxpdGllcyBpbiB3ZWIKIGFwcGxpY2F0aW9ucyBob3N0ZWQgb24gR29v
Z2xlIENsb3VkIFBsYXRmb3JtLiBJdCBjcmF3bHMgeW91ciBhcHBsaWNhdGlvbiwgYW5kCiBh
dHRlbXB0cyB0byBleGVyY2lzZSBhcyBtYW55IHVzZXIgaW5wdXRzIGFuZCBldmVudCBoYW5k
bGVycyBhcyBwb3NzaWJsZS4KCgoKAwYAARIDJwgaCgoKAwYAAxIDKAJJCgwKBQYAA5kIEgMo
AkkKCgoDBgADEgMpAlYKDAoFBgADmggSAykCVgopCgQGAAIAEgQsAjIDGhsgQ3JlYXRlcyBh
IG5ldyBTY2FuQ29uZmlnLgoKDAoFBgACAAESAywGFgoMCgUGAAIAAhIDLBcuCgwKBQYAAgAD
EgMsOUMKDQoFBgACAAQSBC0EMAYKEQoJBgACAASwyrwiEgQtBDAGCgwKBQYAAgAEEgMxBEAK
DwoIBgACAASbCAASAzEEQApHCgQGAAIBEgQ1AjoDGjkgRGVsZXRlcyBhbiBleGlzdGluZyBT
Y2FuQ29uZmlnIGFuZCBpdHMgY2hpbGQgcmVzb3VyY2VzLgoKDAoFBgACAQESAzUGFgoMCgUG
AAIBAhIDNRcuCgwKBQYAAgEDEgM1OU4KDQoFBgACAQQSBDYEOAYKEQoJBgACAQSwyrwiEgQ2
BDgGCgwKBQYAAgEEEgM5BDIKDwoIBgACAQSbCAASAzkEMgoiCgQGAAICEgQ9AkIDGhQgR2V0
cyBhIFNjYW5Db25maWcuCgoMCgUGAAICARIDPQYTCgwKBQYAAgICEgM9FCgKDAoFBgACAgMS
Az0zPQoNCgUGAAICBBIEPgRABgoRCgkGAAICBLDKvCISBD4EQAYKDAoFBgACAgQSA0EEMgoP
CggGAAICBJsIABIDQQQyCjgKBAYAAgMSBEUCSgMaKiBMaXN0cyBTY2FuQ29uZmlncyB1bmRl
ciBhIGdpdmVuIHByb2plY3QuCgoMCgUGAAIDARIDRQYVCgwKBQYAAgMCEgNFFiwKDAoFBgAC
AwMSA0U3TgoNCgUGAAIDBBIERgRIBgoRCgkGAAIDBLDKvCISBEYESAYKDAoFBgACAwQSA0kE
NAoPCggGAAIDBJsIABIDSQQ0ClkKBAYAAgQSBE0CUwMaSyBVcGRhdGVzIGEgU2NhbkNvbmZp
Zy4gVGhpcyBtZXRob2Qgc3VwcG9ydCBwYXJ0aWFsIHVwZGF0ZSBvZiBhIFNjYW5Db25maWcu
CgoMCgUGAAIEARIDTQYWCgwKBQYAAgQCEgNNFy4KDAoFBgACBAMSA005QwoNCgUGAAIEBBIE
TgRRBgoRCgkGAAIEBLDKvCISBE4EUQYKDAoFBgACBAQSA1IERQoPCggGAAIEBJsIABIDUgRF
CkIKBAYAAgUSBFYCXAMaNCBTdGFydCBhIFNjYW5SdW4gYWNjb3JkaW5nIHRvIHRoZSBnaXZl
biBTY2FuQ29uZmlnLgoKDAoFBgACBQESA1YGEgoMCgUGAAIFAhIDVhMmCgwKBQYAAgUDEgNW
MTgKDQoFBgACBQQSBFcEWgYKEQoJBgACBQSwyrwiEgRXBFoGCgwKBQYAAgUEEgNbBDIKDwoI
BgACBQSbCAASA1sEMgofCgQGAAIGEgRfAmQDGhEgR2V0cyBhIFNjYW5SdW4uCgoMCgUGAAIG
ARIDXwYQCgwKBQYAAgYCEgNfESIKDAoFBgACBgMSA18tNAoNCgUGAAIGBBIEYARiBgoRCgkG
AAIGBLDKvCISBGAEYgYKDAoFBgACBgQSA2MEMgoPCggGAAIGBJsIABIDYwQyCmMKBAYAAgcS
BGgCbQMaVSBMaXN0cyBTY2FuUnVucyB1bmRlciBhIGdpdmVuIFNjYW5Db25maWcsIGluIGRl
c2NlbmRpbmcgb3JkZXIgb2YgU2NhblJ1bgogc3RvcCB0aW1lLgoKDAoFBgACBwESA2gGEgoM
CgUGAAIHAhIDaBMmCgwKBQYAAgcDEgNoMUUKDQoFBgACBwQSBGkEawYKEQoJBgACBwSwyrwi
EgRpBGsGCgwKBQYAAgcEEgNsBDQKDwoIBgACBwSbCAASA2wENApBCgQGAAIIEgRwAnYDGjMg
U3RvcHMgYSBTY2FuUnVuLiBUaGUgc3RvcHBlZCBTY2FuUnVuIGlzIHJldHVybmVkLgoKDAoF
BgACCAESA3AGEQoMCgUGAAIIAhIDcBIkCgwKBQYAAggDEgNwLzYKDQoFBgACCAQSBHEEdAYK
EQoJBgACCASwyrwiEgRxBHQGCgwKBQYAAggEEgN1BDIKDwoIBgACCASbCAASA3UEMgo3CgQG
AAIJEgR5An4DGikgTGlzdCBDcmF3bGVkVXJscyB1bmRlciBhIGdpdmVuIFNjYW5SdW4uCgoM
CgUGAAIJARIDeQYVCgwKBQYAAgkCEgN5FiwKDAoFBgACCQMSA3k3TgoNCgUGAAIJBBIEegR8
BgoRCgkGAAIJBLDKvCISBHoEfAYKDAoFBgACCQQSA30ENAoPCggGAAIJBJsIABIDfQQ0CiEK
BAYAAgoSBoEBAoYBAxoRIEdldHMgYSBGaW5kaW5nLgoKDQoFBgACCgESBIEBBhAKDQoFBgAC
CgISBIEBESIKDQoFBgACCgMSBIEBLTQKDwoFBgACCgQSBoIBBIQBBgoTCgkGAAIKBLDKvCIS
BoIBBIQBBgoNCgUGAAIKBBIEhQEEMgoQCggGAAIKBJsIABIEhQEEMgo2CgQGAAILEgaJAQKO
AQMaJiBMaXN0IEZpbmRpbmdzIHVuZGVyIGEgZ2l2ZW4gU2NhblJ1bi4KCg0KBQYAAgsBEgSJ
AQYSCg0KBQYAAgsCEgSJARMmCg0KBQYAAgsDEgSJATFFCg8KBQYAAgsEEgaKAQSMAQYKEwoJ
BgACCwSwyrwiEgaKAQSMAQYKDQoFBgACCwQSBI0BBDsKEAoIBgACCwSbCAASBI0BBDsKQgoE
BgACDBIGkQEClgEDGjIgTGlzdCBhbGwgRmluZGluZ1R5cGVTdGF0cyB1bmRlciBhIGdpdmVu
IFNjYW5SdW4uCgoNCgUGAAIMARIEkQEGGgoNCgUGAAIMAhIEkQEbNgoNCgUGAAIMAxIEkQFB
XQoPCgUGAAIMBBIGkgEElAEGChMKCQYAAgwEsMq8IhIGkgEElAEGCg0KBQYAAgwEEgSVAQQ0
ChAKCAYAAgwEmwgAEgSVAQQ0CjoKAgQAEgaaAQCmAQEaLCBSZXF1ZXN0IGZvciB0aGUgYENy
ZWF0ZVNjYW5Db25maWdgIG1ldGhvZC4KCgsKAwQAARIEmgEIHwqfAQoEBAACABIGnQECogEE
Go4BIFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUgd2hlcmUgdGhlIHNjYW4g
aXMgY3JlYXRlZCwgd2hpY2ggc2hvdWxkIGJlIGEKIHByb2plY3QgcmVzb3VyY2UgbmFtZSBp
biB0aGUgZm9ybWF0ICdwcm9qZWN0cy97cHJvamVjdElkfScuCgoNCgUEAAIABRIEnQECCAoN
CgUEAAIAARIEnQEJDwoNCgUEAAIAAxIEnQESEwoPCgUEAAIACBIGnQEUogEDChAKCAQAAgAI
nAgAEgSeAQQqChEKBwQAAgAInwgSBp8BBKEBBQo3CgQEAAIBEgSlAQJGGikgUmVxdWlyZWQu
IFRoZSBTY2FuQ29uZmlnIHRvIGJlIGNyZWF0ZWQuCgoNCgUEAAIBBhIEpQECDAoNCgUEAAIB
ARIEpQENGAoNCgUEAAIBAxIEpQEbHAoNCgUEAAIBCBIEpQEdRQoQCggEAAIBCJwIABIEpQEe
RAo6CgIEARIGqQEAsgEBGiwgUmVxdWVzdCBmb3IgdGhlIGBEZWxldGVTY2FuQ29uZmlnYCBt
ZXRob2QuCgoLCgMEAQESBKkBCB8KogEKBAQBAgASBqwBArEBBBqRASBSZXF1aXJlZC4gVGhl
IHJlc291cmNlIG5hbWUgb2YgdGhlIFNjYW5Db25maWcgdG8gYmUgZGVsZXRlZC4gVGhlIG5h
bWUgZm9sbG93cyB0aGUKIGZvcm1hdCBvZiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNv
bmZpZ3Mve3NjYW5Db25maWdJZH0nLgoKDQoFBAECAAUSBKwBAggKDQoFBAECAAESBKwBCQ0K
DQoFBAECAAMSBKwBEBEKDwoFBAECAAgSBqwBErEBAwoQCggEAQIACJwIABIErQEEKgoRCgcE
AQIACJ8IEgauAQSwAQUKNwoCBAISBrUBAL4BARopIFJlcXVlc3QgZm9yIHRoZSBgR2V0U2Nh
bkNvbmZpZ2AgbWV0aG9kLgoKCwoDBAIBEgS1AQgcCqMBCgQEAgIAEga4AQK9AQQakgEgUmVx
dWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTY2FuQ29uZmlnIHRvIGJlIHJldHVy
bmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0IG9mICdwcm9qZWN0cy97cHJvamVj
dElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfScuCgoNCgUEAgIABRIEuAECCAoNCgUE
AgIAARIEuAEJDQoNCgUEAgIAAxIEuAEQEQoPCgUEAgIACBIGuAESvQEDChAKCAQCAgAInAgA
EgS5AQQqChEKBwQCAgAInwgSBroBBLwBBQo5CgIEAxIGwQEA1AEBGisgUmVxdWVzdCBmb3Ig
dGhlIGBMaXN0U2NhbkNvbmZpZ3NgIG1ldGhvZC4KCgsKAwQDARIEwQEIHgqEAQoEBAMCABIG
xAECyQEEGnQgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hv
dWxkIGJlIGEgcHJvamVjdCByZXNvdXJjZSBuYW1lIGluIHRoZQogZm9ybWF0ICdwcm9qZWN0
cy97cHJvamVjdElkfScuCgoNCgUEAwIABRIExAECCAoNCgUEAwIAARIExAEJDwoNCgUEAwIA
AxIExAESEwoPCgUEAwIACBIGxAEUyQEDChAKCAQDAgAInAgAEgTFAQQqChEKBwQDAgAInwgS
BsYBBMgBBQrPAQoEBAMCARIEzgECGBrAASBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFnZSBv
ZiByZXN1bHRzIHRvIGJlIHJldHVybmVkLiBUaGlzIHNob3VsZCBiZSBhCiBgbmV4dF9wYWdl
X3Rva2VuYCB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgTGlzdCByZXF1ZXN0Lgog
SWYgdW5zcGVjaWZpZWQsIHRoZSBmaXJzdCBwYWdlIG9mIHJlc3VsdHMgaXMgcmV0dXJuZWQu
CgoNCgUEAwIBBRIEzgECCAoNCgUEAwIBARIEzgEJEwoNCgUEAwIBAxIEzgEWFwquAQoEBAMC
AhIE0wECFhqfASBUaGUgbWF4aW11bSBudW1iZXIgb2YgU2NhbkNvbmZpZ3MgdG8gcmV0dXJu
LCBjYW4gYmUgbGltaXRlZCBieSBzZXJ2ZXIuCiBJZiBub3Qgc3BlY2lmaWVkIG9yIG5vdCBw
b3NpdGl2ZSwgdGhlIGltcGxlbWVudGF0aW9uIHdpbGwgc2VsZWN0IGEKIHJlYXNvbmFibGUg
dmFsdWUuCgoNCgUEAwICBRIE0wECBwoNCgUEAwICARIE0wEIEQoNCgUEAwICAxIE0wEUFQpB
CgIEBBIG1wEA4QEBGjMgUmVxdWVzdCBmb3IgdGhlIGBVcGRhdGVTY2FuQ29uZmlnUmVxdWVz
dGAgbWV0aG9kLgoKCwoDBAQBEgTXAQgfCrsBCgQEBAIAEgTbAQJGGqwBIFJlcXVpcmVkLiBU
aGUgU2NhbkNvbmZpZyB0byBiZSB1cGRhdGVkLiBUaGUgbmFtZSBmaWVsZCBtdXN0IGJlIHNl
dCB0byBpZGVudGlmeSB0aGUKIHJlc291cmNlIHRvIGJlIHVwZGF0ZWQuIFRoZSB2YWx1ZXMg
b2YgZmllbGRzIG5vdCBjb3ZlcmVkIGJ5IHRoZSBtYXNrCiB3aWxsIGJlIGlnbm9yZWQuCgoN
CgUEBAIABhIE2wECDAoNCgUEBAIAARIE2wENGAoNCgUEBAIAAxIE2wEbHAoNCgUEBAIACBIE
2wEdRQoQCggEBAIACJwIABIE2wEeRArBAQoEBAQCARIE4AECVRqyASBSZXF1aXJlZC4gVGhl
IHVwZGF0ZSBtYXNrIGFwcGxpZXMgdG8gdGhlIHJlc291cmNlLiBGb3IgdGhlIGBGaWVsZE1h
c2tgIGRlZmluaXRpb24sCiBzZWUKIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3By
b3RvY29sLWJ1ZmZlcnMvZG9jcy9yZWZlcmVuY2UvZ29vZ2xlLnByb3RvYnVmI2ZpZWxkbWFz
awoKDQoFBAQCAQYSBOABAhsKDQoFBAQCAQESBOABHCcKDQoFBAQCAQMSBOABKisKDQoFBAQC
AQgSBOABLFQKEAoIBAQCAQicCAASBOABLVMKOgoCBAUSBuQBAOsBARosIFJlc3BvbnNlIGZv
ciB0aGUgYExpc3RTY2FuQ29uZmlnc2AgbWV0aG9kLgoKCwoDBAUBEgTkAQgfCjEKBAQFAgAS
BOYBAicaIyBUaGUgbGlzdCBvZiBTY2FuQ29uZmlncyByZXR1cm5lZC4KCg0KBQQFAgAEEgTm
AQIKCg0KBQQFAgAGEgTmAQsVCg0KBQQFAgABEgTmARYiCg0KBQQFAgADEgTmASUmCm8KBAQF
AgESBOoBAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMs
IG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRoZSBsaXN0LgoK
DQoFBAUCAQUSBOoBAggKDQoFBAUCAQESBOoBCRgKDQoFBAUCAQMSBOoBGxwKNgoCBAYSBu4B
APcBARooIFJlcXVlc3QgZm9yIHRoZSBgU3RhcnRTY2FuUnVuYCBtZXRob2QuCgoLCgMEBgES
BO4BCBsKnwEKBAQGAgASBvEBAvYBBBqOASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUg
b2YgdGhlIFNjYW5Db25maWcgdG8gYmUgdXNlZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZv
cm1hdCBvZiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJ
ZH0nLgoKDQoFBAYCAAUSBPEBAggKDQoFBAYCAAESBPEBCQ0KDQoFBAYCAAMSBPEBEBEKDwoF
BAYCAAgSBvEBEvYBAwoQCggEBgIACJwIABIE8gEEKgoRCgcEBgIACJ8IEgbzAQT1AQUKNAoC
BAcSBvoBAIQCARomIFJlcXVlc3QgZm9yIHRoZSBgR2V0U2NhblJ1bmAgbWV0aG9kLgoKCwoD
BAcBEgT6AQgZCrYBCgQEBwIAEgb+AQKDAgQapQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBu
YW1lIG9mIHRoZSBTY2FuUnVuIHRvIGJlIHJldHVybmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRo
ZQogZm9ybWF0IG9mCiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5D
b25maWdJZH0vc2NhblJ1bnMve3NjYW5SdW5JZH0nLgoKDQoFBAcCAAUSBP4BAggKDQoFBAcC
AAESBP4BCQ0KDQoFBAcCAAMSBP4BEBEKDwoFBAcCAAgSBv4BEoMCAwoQCggEBwIACJwIABIE
/wEEKgoRCgcEBwIACJ8IEgaAAgSCAgUKNgoCBAgSBocCAJoCARooIFJlcXVlc3QgZm9yIHRo
ZSBgTGlzdFNjYW5SdW5zYCBtZXRob2QuCgoLCgMECAESBIcCCBsKnQEKBAQIAgASBooCAo8C
BBqMASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLCB3aGljaCBzaG91bGQg
YmUgYSBzY2FuIHJlc291cmNlIG5hbWUgaW4gdGhlCiBmb3JtYXQgJ3Byb2plY3RzL3twcm9q
ZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9Jy4KCg0KBQQIAgAFEgSKAgIICg0K
BQQIAgABEgSKAgkPCg0KBQQIAgADEgSKAhITCg8KBQQIAgAIEgaKAhSPAgMKEAoIBAgCAAic
CAASBIsCBCoKEQoHBAgCAAifCBIGjAIEjgIFCs8BCgQECAIBEgSUAgIYGsABIEEgdG9rZW4g
aWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdG8gYmUgcmV0dXJuZWQuIFRoaXMgc2hv
dWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2
aW91cyBMaXN0IHJlcXVlc3QuCiBJZiB1bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBhZ2Ugb2Yg
cmVzdWx0cyBpcyByZXR1cm5lZC4KCg0KBQQIAgEFEgSUAgIICg0KBQQIAgEBEgSUAgkTCg0K
BQQIAgEDEgSUAhYXCqsBCgQECAICEgSZAgIWGpwBIFRoZSBtYXhpbXVtIG51bWJlciBvZiBT
Y2FuUnVucyB0byByZXR1cm4sIGNhbiBiZSBsaW1pdGVkIGJ5IHNlcnZlci4KIElmIG5vdCBz
cGVjaWZpZWQgb3Igbm90IHBvc2l0aXZlLCB0aGUgaW1wbGVtZW50YXRpb24gd2lsbCBzZWxl
Y3QgYQogcmVhc29uYWJsZSB2YWx1ZS4KCg0KBQQIAgIFEgSZAgIHCg0KBQQIAgIBEgSZAggR
Cg0KBQQIAgIDEgSZAhQVCjcKAgQJEgadAgCkAgEaKSBSZXNwb25zZSBmb3IgdGhlIGBMaXN0
U2NhblJ1bnNgIG1ldGhvZC4KCgsKAwQJARIEnQIIHAouCgQECQIAEgSfAgIhGiAgVGhlIGxp
c3Qgb2YgU2NhblJ1bnMgcmV0dXJuZWQuCgoNCgUECQIABBIEnwICCgoNCgUECQIABhIEnwIL
EgoNCgUECQIAARIEnwITHAoNCgUECQIAAxIEnwIfIApvCgQECQIBEgSjAgIdGmEgVG9rZW4g
dG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVy
ZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQJAgEFEgSjAgIICg0K
BQQJAgEBEgSjAgkYCg0KBQQJAgEDEgSjAhscCjUKAgQKEganAgCxAgEaJyBSZXF1ZXN0IGZv
ciB0aGUgYFN0b3BTY2FuUnVuYCBtZXRob2QuCgoLCgMECgESBKcCCBoKtQEKBAQKAgASBqsC
ArACBBqkASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNjYW5SdW4gdG8g
YmUgc3RvcHBlZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZvcm1hdCBvZgogJ3Byb2plY3Rz
L3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2Fu
UnVuSWR9Jy4KCg0KBQQKAgAFEgSrAgIICg0KBQQKAgABEgSrAgkNCg0KBQQKAgADEgSrAhAR
Cg8KBQQKAgAIEgarAhKwAgMKEAoIBAoCAAicCAASBKwCBCoKEQoHBAoCAAifCBIGrQIErwIF
CjkKAgQLEga0AgDIAgEaKyBSZXF1ZXN0IGZvciB0aGUgYExpc3RDcmF3bGVkVXJsc2AgbWV0
aG9kLgoKCwoDBAsBEgS0AggeCrcBCgQECwIAEga4AgK9AgQapgEgUmVxdWlyZWQuIFRoZSBw
YXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgc2NhbiBydW4gcmVzb3Vy
Y2UgbmFtZSBpbiB0aGUKIGZvcm1hdAogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25m
aWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQLAgAFEgS4
AgIICg0KBQQLAgABEgS4AgkPCg0KBQQLAgADEgS4AhITCg8KBQQLAgAIEga4AhS9AgMKEAoI
BAsCAAicCAASBLkCBCoKEQoHBAsCAAifCBIGugIEvAIFCs8BCgQECwIBEgTCAgIYGsABIEEg
dG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdG8gYmUgcmV0dXJuZWQuIFRo
aXMgc2hvdWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVlIHJldHVybmVkIGZyb20g
YSBwcmV2aW91cyBMaXN0IHJlcXVlc3QuCiBJZiB1bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBh
Z2Ugb2YgcmVzdWx0cyBpcyByZXR1cm5lZC4KCg0KBQQLAgEFEgTCAgIICg0KBQQLAgEBEgTC
AgkTCg0KBQQLAgEDEgTCAhYXCq4BCgQECwICEgTHAgIWGp8BIFRoZSBtYXhpbXVtIG51bWJl
ciBvZiBDcmF3bGVkVXJscyB0byByZXR1cm4sIGNhbiBiZSBsaW1pdGVkIGJ5IHNlcnZlci4K
IElmIG5vdCBzcGVjaWZpZWQgb3Igbm90IHBvc2l0aXZlLCB0aGUgaW1wbGVtZW50YXRpb24g
d2lsbCBzZWxlY3QgYQogcmVhc29uYWJsZSB2YWx1ZS4KCg0KBQQLAgIFEgTHAgIHCg0KBQQL
AgIBEgTHAggRCg0KBQQLAgIDEgTHAhQVCjoKAgQMEgbLAgDSAgEaLCBSZXNwb25zZSBmb3Ig
dGhlIGBMaXN0Q3Jhd2xlZFVybHNgIG1ldGhvZC4KCgsKAwQMARIEywIIHwoxCgQEDAIAEgTN
AgInGiMgVGhlIGxpc3Qgb2YgQ3Jhd2xlZFVybHMgcmV0dXJuZWQuCgoNCgUEDAIABBIEzQIC
CgoNCgUEDAIABhIEzQILFQoNCgUEDAIAARIEzQIWIgoNCgUEDAIAAxIEzQIlJgpvCgQEDAIB
EgTRAgIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBv
ciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0K
BQQMAgEFEgTRAgIICg0KBQQMAgEBEgTRAgkYCg0KBQQMAgEDEgTRAhscCjQKAgQNEgbVAgDf
AgEaJiBSZXF1ZXN0IGZvciB0aGUgYEdldEZpbmRpbmdgIG1ldGhvZC4KCgsKAwQNARIE1QII
GQrLAQoEBA0CABIG2QIC3gIEGroBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgRmluZGluZyB0byBiZSByZXR1cm5lZC4gVGhlIG5hbWUgZm9sbG93cyB0aGUKIGZvcm1h
dCBvZgogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9
L3NjYW5SdW5zL3tzY2FuUnVuSWR9L2ZpbmRpbmdzL3tmaW5kaW5nSWR9Jy4KCg0KBQQNAgAF
EgTZAgIICg0KBQQNAgABEgTZAgkNCg0KBQQNAgADEgTZAhARCg8KBQQNAgAIEgbZAhLeAgMK
EAoIBA0CAAicCAASBNoCBCoKEQoHBA0CAAifCBIG2wIE3QIFCjYKAgQOEgbiAgD8AgEaKCBS
ZXF1ZXN0IGZvciB0aGUgYExpc3RGaW5kaW5nc2AgbWV0aG9kLgoKCwoDBA4BEgTiAggbCrcB
CgQEDgIAEgbmAgLrAgQapgEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwg
d2hpY2ggc2hvdWxkIGJlIGEgc2NhbiBydW4gcmVzb3VyY2UgbmFtZSBpbiB0aGUKIGZvcm1h
dAogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3Nj
YW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQOAgAFEgTmAgIICg0KBQQOAgABEgTmAgkPCg0K
BQQOAgADEgTmAhITCg8KBQQOAgAIEgbmAhTrAgMKEAoIBA4CAAicCAASBOcCBCoKEQoHBA4C
AAifCBIG6AIE6gIFCrABCgQEDgIBEgTxAgI9GqEBIFJlcXVpcmVkLiBUaGUgZmlsdGVyIGV4
cHJlc3Npb24uIFRoZSBleHByZXNzaW9uIG11c3QgYmUgaW4gdGhlIGZvcm1hdDogPGZpZWxk
PgogPG9wZXJhdG9yPiA8dmFsdWU+LgogU3VwcG9ydGVkIGZpZWxkOiAnZmluZGluZ190eXBl
Jy4KIFN1cHBvcnRlZCBvcGVyYXRvcjogJz0nLgoKDQoFBA4CAQUSBPECAggKDQoFBA4CAQES
BPECCQ8KDQoFBA4CAQMSBPECEhMKDQoFBA4CAQgSBPECFDwKEAoIBA4CAQicCAASBPECFTsK
zwEKBAQOAgISBPYCAhgawAEgQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0
cyB0byBiZSByZXR1cm5lZC4gVGhpcyBzaG91bGQgYmUgYQogYG5leHRfcGFnZV90b2tlbmAg
dmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIExpc3QgcmVxdWVzdC4KIElmIHVuc3Bl
Y2lmaWVkLCB0aGUgZmlyc3QgcGFnZSBvZiByZXN1bHRzIGlzIHJldHVybmVkLgoKDQoFBA4C
AgUSBPYCAggKDQoFBA4CAgESBPYCCRMKDQoFBA4CAgMSBPYCFhcKqwEKBAQOAgMSBPsCAhYa
nAEgVGhlIG1heGltdW0gbnVtYmVyIG9mIEZpbmRpbmdzIHRvIHJldHVybiwgY2FuIGJlIGxp
bWl0ZWQgYnkgc2VydmVyLgogSWYgbm90IHNwZWNpZmllZCBvciBub3QgcG9zaXRpdmUsIHRo
ZSBpbXBsZW1lbnRhdGlvbiB3aWxsIHNlbGVjdCBhCiByZWFzb25hYmxlIHZhbHVlLgoKDQoF
BA4CAwUSBPsCAgcKDQoFBA4CAwESBPsCCBEKDQoFBA4CAwMSBPsCFBUKNwoCBA8SBv8CAIYD
ARopIFJlc3BvbnNlIGZvciB0aGUgYExpc3RGaW5kaW5nc2AgbWV0aG9kLgoKCwoDBA8BEgT/
AggcCi4KBAQPAgASBIEDAiAaICBUaGUgbGlzdCBvZiBGaW5kaW5ncyByZXR1cm5lZC4KCg0K
BQQPAgAEEgSBAwIKCg0KBQQPAgAGEgSBAwsSCg0KBQQPAgABEgSBAxMbCg0KBQQPAgADEgSB
Ax4fCm8KBAQPAgESBIUDAh0aYSBUb2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9m
IHJlc3VsdHMsIG9yIGVtcHR5IGlmIHRoZXJlIGFyZSBubwogbW9yZSByZXN1bHRzIGluIHRo
ZSBsaXN0LgoKDQoFBA8CAQUSBIUDAggKDQoFBA8CAQESBIUDCRgKDQoFBA8CAQMSBIUDGxwK
PgoCBBASBokDAJMDARowIFJlcXVlc3QgZm9yIHRoZSBgTGlzdEZpbmRpbmdUeXBlU3RhdHNg
IG1ldGhvZC4KCgsKAwQQARIEiQMIIwq3AQoEBBACABIGjQMCkgMEGqYBIFJlcXVpcmVkLiBU
aGUgcGFyZW50IHJlc291cmNlIG5hbWUsIHdoaWNoIHNob3VsZCBiZSBhIHNjYW4gcnVuIHJl
c291cmNlIG5hbWUgaW4gdGhlCiBmb3JtYXQKICdwcm9qZWN0cy97cHJvamVjdElkfS9zY2Fu
Q29uZmlncy97c2NhbkNvbmZpZ0lkfS9zY2FuUnVucy97c2NhblJ1bklkfScuCgoNCgUEEAIA
BRIEjQMCCAoNCgUEEAIAARIEjQMJDwoNCgUEEAIAAxIEjQMSEwoPCgUEEAIACBIGjQMUkgMD
ChAKCAQQAgAInAgAEgSOAwQqChEKBwQQAgAInwgSBo8DBJEDBQo/CgIEERIGlgMAmQMBGjEg
UmVzcG9uc2UgZm9yIHRoZSBgTGlzdEZpbmRpbmdUeXBlU3RhdHNgIG1ldGhvZC4KCgsKAwQR
ARIElgMIJAo2CgQEEQIAEgSYAwIzGiggVGhlIGxpc3Qgb2YgRmluZGluZ1R5cGVTdGF0cyBy
ZXR1cm5lZC4KCg0KBQQRAgAEEgSYAwIKCg0KBQQRAgAGEgSYAwsbCg0KBQQRAgABEgSYAxwu
Cg0KBQQRAgADEgSYAzEyYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::CreateScanConfigRequest ===
    # Fields for CreateScanConfigRequest
    # Field: parent Type: 9 ()
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanConfig)

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::DeleteScanConfigRequest ===
    # Fields for DeleteScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanConfigRequest ===
    # Fields for GetScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsRequest ===
    # Fields for ListScanConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::UpdateScanConfigRequest ===
    # Fields for UpdateScanConfigRequest
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsResponse ===
    # Fields for ListScanConfigsResponse
    # Field: scan_configs Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StartScanRunRequest ===
    # Fields for StartScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanRunRequest ===
    # Fields for GetScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsRequest ===
    # Fields for ListScanRunsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsResponse ===
    # Fields for ListScanRunsResponse
    # Field: scan_runs Type: 11 (.google.cloud.websecurityscanner.v1alpha.ScanRun)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StopScanRunRequest ===
    # Fields for StopScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsRequest ===
    # Fields for ListCrawledUrlsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsResponse ===
    # Fields for ListCrawledUrlsResponse
    # Field: crawled_urls Type: 11 (.google.cloud.websecurityscanner.v1alpha.CrawledUrl)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetFindingRequest ===
    # Fields for GetFindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsRequest ===
    # Fields for ListFindingsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsResponse ===
    # Fields for ListFindingsResponse
    # Field: findings Type: 11 (.google.cloud.websecurityscanner.v1alpha.Finding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsRequest ===
    # Fields for ListFindingTypeStatsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsResponse ===
    # Fields for ListFindingTypeStatsResponse
    # Field: finding_type_stats Type: 11 (.google.cloud.websecurityscanner.v1alpha.FindingTypeStats)

# === Service Client: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::WebSecurityScannerClient ===
package Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::WebSecurityScannerClient;

=pod

=head2 Service Client: Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::WebSecurityScannerClient

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
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::CreateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'CreateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig',
    });
}

sub delete_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::DeleteScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'DeleteScanConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'GetScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig',
    });
}

sub list_scan_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'ListScanConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsResponse',
    });
}

sub update_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::UpdateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'UpdateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig',
    });
}

sub start_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StartScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'StartScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun',
    });
}

sub get_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'GetScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun',
    });
}

sub list_scan_runs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'ListScanRuns',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsResponse',
    });
}

sub stop_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StopScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'StopScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun',
    });
}

sub list_crawled_urls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'ListCrawledUrls',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsResponse',
    });
}

sub get_finding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetFindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'GetFinding',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding',
    });
}

sub list_findings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'ListFindings',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsResponse',
    });
}

sub list_finding_type_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1alpha.WebSecurityScanner',
        method         => 'ListFindingTypeStats',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/web_security_scanner.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::CreateScanConfigRequest->new({
        parent => $parent,
        scan_config => $scan_config,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::CreateScanConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/web_security_scanner.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::CreateScanConfigRequest

Request for the `CreateScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the scan is created, which should be a
project resource name in the format 'projects/{projectId}'.

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig>)

Required. The ScanConfig to be created.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::DeleteScanConfigRequest

Request for the `DeleteScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be deleted. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanConfigRequest

Request for the `GetScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be returned. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::UpdateScanConfigRequest

Request for the `UpdateScanConfigRequest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig>)

Required. The ScanConfig to be updated. The name field must be set to identify the
resource to be updated. The values of fields not covered by the mask
will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanConfigsResponse

Response for the `ListScanConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_configs() >> / C<< $msg->scan_configs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanConfig::ScanConfig>)

The list of ScanConfigs returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StartScanRunRequest

Request for the `StartScanRun` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be used. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetScanRunRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListScanRunsResponse

Response for the `ListScanRuns` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_runs() >> / C<< $msg->scan_runs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::ScanRun::ScanRun>)

The list of ScanRuns returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::StopScanRunRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListCrawledUrlsResponse

Response for the `ListCrawledUrls` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crawled_urls() >> / C<< $msg->crawled_urls($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::CrawledUrl::CrawledUrl>)

The list of CrawledUrls returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::GetFindingRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingsResponse

Response for the `ListFindings` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->findings() >> / C<< $msg->findings($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::Finding::Finding>)

The list of Findings returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::ListFindingTypeStatsResponse

Response for the `ListFindingTypeStats` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type_stats() >> / C<< $msg->finding_type_stats($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingTypeStats::FindingTypeStats>)

The list of FindingTypeStats returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::WebSecurityScanner::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
