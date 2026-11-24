package Google::Cloud::Websecurityscanner::V1::WebSecurityScanner;

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
    eval { require Google::Cloud::Websecurityscanner::V1::CrawledUrl };
    eval { require Google::Cloud::Websecurityscanner::V1::Finding };
    eval { require Google::Cloud::Websecurityscanner::V1::FindingTypeStats };
    eval { require Google::Cloud::Websecurityscanner::V1::ScanConfig };
    eval { require Google::Cloud::Websecurityscanner::V1::ScanRun };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL3dlYl9zZWN1cml0eV9zY2Fu
bmVyLnByb3RvEiJnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxGhxnb29nbGUv
YXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxo0Z29vZ2xl
L2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MS9jcmF3bGVkX3VybC5wcm90bxowZ29vZ2xl
L2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MS9maW5kaW5nLnByb3RvGjtnb29nbGUvY2xv
dWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL2ZpbmRpbmdfdHlwZV9zdGF0cy5wcm90bxo0Z29v
Z2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MS9zY2FuX2NvbmZpZy5wcm90bxoxZ29v
Z2xlL2Nsb3VkL3dlYnNlY3VyaXR5c2Nhbm5lci92MS9zY2FuX3J1bi5wcm90bxobZ29vZ2xl
L3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90
byKCAQoXQ3JlYXRlU2NhbkNvbmZpZ1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQS
TwoLc2Nhbl9jb25maWcYAiABKAsyLi5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVy
LnYxLlNjYW5Db25maWdSCnNjYW5Db25maWciLQoXRGVsZXRlU2NhbkNvbmZpZ1JlcXVlc3QS
EgoEbmFtZRgBIAEoCVIEbmFtZSIqChRHZXRTY2FuQ29uZmlnUmVxdWVzdBISCgRuYW1lGAEg
ASgJUgRuYW1lImwKFkxpc3RTY2FuQ29uZmlnc1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZw
YXJlbnQSHQoKcGFnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEhsKCXBhZ2Vfc2l6ZRgDIAEo
BVIIcGFnZVNpemUipwEKF1VwZGF0ZVNjYW5Db25maWdSZXF1ZXN0Ek8KC3NjYW5fY29uZmln
GAIgASgLMi4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5TY2FuQ29uZmln
UgpzY2FuQ29uZmlnEjsKC3VwZGF0ZV9tYXNrGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZp
ZWxkTWFza1IKdXBkYXRlTWFzayKUAQoXTGlzdFNjYW5Db25maWdzUmVzcG9uc2USUQoMc2Nh
bl9jb25maWdzGAEgAygLMi4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5T
Y2FuQ29uZmlnUgtzY2FuQ29uZmlncxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ
YWdlVG9rZW4iKQoTU3RhcnRTY2FuUnVuUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lIicK
EUdldFNjYW5SdW5SZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUiaQoTTGlzdFNjYW5SdW5z
UmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIdCgpwYWdlX3Rva2VuGAIgASgJUglw
YWdlVG9rZW4SGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZSKIAQoUTGlzdFNjYW5SdW5z
UmVzcG9uc2USSAoJc2Nhbl9ydW5zGAEgAygLMisuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5
c2Nhbm5lci52MS5TY2FuUnVuUghzY2FuUnVucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlS
DW5leHRQYWdlVG9rZW4iKAoSU3RvcFNjYW5SdW5SZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5h
bWUibAoWTGlzdENyYXdsZWRVcmxzUmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBId
CgpwYWdlX3Rva2VuGAIgASgJUglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAMgASgFUghwYWdl
U2l6ZSKUAQoXTGlzdENyYXdsZWRVcmxzUmVzcG9uc2USUQoMY3Jhd2xlZF91cmxzGAEgAygL
Mi4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5DcmF3bGVkVXJsUgtjcmF3
bGVkVXJscxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4iJwoRR2V0
RmluZGluZ1JlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZSKBAQoTTGlzdEZpbmRpbmdzUmVx
dWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIWCgZmaWx0ZXIYAiABKAlSBmZpbHRlchId
CgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4SGwoJcGFnZV9zaXplGAQgASgFUghwYWdl
U2l6ZSKHAQoUTGlzdEZpbmRpbmdzUmVzcG9uc2USRwoIZmluZGluZ3MYASADKAsyKy5nb29n
bGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLkZpbmRpbmdSCGZpbmRpbmdzEiYKD25l
eHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiI1ChtMaXN0RmluZGluZ1R5cGVT
dGF0c1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQiggEKHExpc3RGaW5kaW5nVHlw
ZVN0YXRzUmVzcG9uc2USYgoSZmluZGluZ190eXBlX3N0YXRzGAEgAygLMjQuZ29vZ2xlLmNs
b3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5GaW5kaW5nVHlwZVN0YXRzUhBmaW5kaW5nVHlw
ZVN0YXRzMukTChJXZWJTZWN1cml0eVNjYW5uZXISuQEKEENyZWF0ZVNjYW5Db25maWcSOy5n
b29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLkNyZWF0ZVNjYW5Db25maWdSZXF1
ZXN0Gi4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5TY2FuQ29uZmlnIjiC
0+STAjIiIy92MS97cGFyZW50PXByb2plY3RzLyp9L3NjYW5Db25maWdzOgtzY2FuX2NvbmZp
ZxKUAQoQRGVsZXRlU2NhbkNvbmZpZxI7Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5u
ZXIudjEuRGVsZXRlU2NhbkNvbmZpZ1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHki
K4LT5JMCJSojL3YxL3tuYW1lPXByb2plY3RzLyovc2NhbkNvbmZpZ3MvKn0SpgEKDUdldFNj
YW5Db25maWcSOC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLkdldFNjYW5D
b25maWdSZXF1ZXN0Gi4uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5TY2Fu
Q29uZmlnIiuC0+STAiUSIy92MS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyp9ErcB
Cg9MaXN0U2NhbkNvbmZpZ3MSOi5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYx
Lkxpc3RTY2FuQ29uZmlnc1JlcXVlc3QaOy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2Fu
bmVyLnYxLkxpc3RTY2FuQ29uZmlnc1Jlc3BvbnNlIiuC0+STAiUSIy92MS97cGFyZW50PXBy
b2plY3RzLyp9L3NjYW5Db25maWdzEsUBChBVcGRhdGVTY2FuQ29uZmlnEjsuZ29vZ2xlLmNs
b3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5VcGRhdGVTY2FuQ29uZmlnUmVxdWVzdBouLmdv
b2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEuU2NhbkNvbmZpZyJEgtPkkwI+Mi8v
djEve3NjYW5fY29uZmlnLm5hbWU9cHJvamVjdHMvKi9zY2FuQ29uZmlncy8qfToLc2Nhbl9j
b25maWcSqgEKDFN0YXJ0U2NhblJ1bhI3Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5u
ZXIudjEuU3RhcnRTY2FuUnVuUmVxdWVzdBorLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNj
YW5uZXIudjEuU2NhblJ1biI0gtPkkwIuIikvdjEve25hbWU9cHJvamVjdHMvKi9zY2FuQ29u
Zmlncy8qfTpzdGFydDoBKhKoAQoKR2V0U2NhblJ1bhI1Lmdvb2dsZS5jbG91ZC53ZWJzZWN1
cml0eXNjYW5uZXIudjEuR2V0U2NhblJ1blJlcXVlc3QaKy5nb29nbGUuY2xvdWQud2Vic2Vj
dXJpdHlzY2FubmVyLnYxLlNjYW5SdW4iNoLT5JMCMBIuL3YxL3tuYW1lPXByb2plY3RzLyov
c2NhbkNvbmZpZ3MvKi9zY2FuUnVucy8qfRK5AQoMTGlzdFNjYW5SdW5zEjcuZ29vZ2xlLmNs
b3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0U2NhblJ1bnNSZXF1ZXN0GjguZ29vZ2xl
LmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0U2NhblJ1bnNSZXNwb25zZSI2gtPk
kwIwEi4vdjEve3BhcmVudD1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyp9L3NjYW5SdW5zErIB
CgtTdG9wU2NhblJ1bhI2Lmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEuU3Rv
cFNjYW5SdW5SZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5T
Y2FuUnVuIj6C0+STAjgiMy92MS97bmFtZT1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2Nh
blJ1bnMvKn06c3RvcDoBKhLQAQoPTGlzdENyYXdsZWRVcmxzEjouZ29vZ2xlLmNsb3VkLndl
YnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0Q3Jhd2xlZFVybHNSZXF1ZXN0GjsuZ29vZ2xlLmNs
b3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0Q3Jhd2xlZFVybHNSZXNwb25zZSJEgtPk
kwI+EjwvdjEve3BhcmVudD1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1bnMvKn0v
Y3Jhd2xlZFVybHMSswEKCkdldEZpbmRpbmcSNS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlz
Y2FubmVyLnYxLkdldEZpbmRpbmdSZXF1ZXN0GisuZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5
c2Nhbm5lci52MS5GaW5kaW5nIkGC0+STAjsSOS92MS97bmFtZT1wcm9qZWN0cy8qL3NjYW5D
b25maWdzLyovc2NhblJ1bnMvKi9maW5kaW5ncy8qfRLEAQoMTGlzdEZpbmRpbmdzEjcuZ29v
Z2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0RmluZGluZ3NSZXF1ZXN0Gjgu
Z29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0RmluZGluZ3NSZXNwb25z
ZSJBgtPkkwI7EjkvdjEve3BhcmVudD1wcm9qZWN0cy8qL3NjYW5Db25maWdzLyovc2NhblJ1
bnMvKn0vZmluZGluZ3MS5AEKFExpc3RGaW5kaW5nVHlwZVN0YXRzEj8uZ29vZ2xlLmNsb3Vk
LndlYnNlY3VyaXR5c2Nhbm5lci52MS5MaXN0RmluZGluZ1R5cGVTdGF0c1JlcXVlc3QaQC5n
b29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLkxpc3RGaW5kaW5nVHlwZVN0YXRz
UmVzcG9uc2UiSYLT5JMCQxJBL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9zY2FuQ29uZmlncy8q
L3NjYW5SdW5zLyp9L2ZpbmRpbmdUeXBlU3RhdHMaVcpBIXdlYnNlY3VyaXR5c2Nhbm5lci5n
b29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm1CjQIKJmNvbS5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxQhdX
ZWJTZWN1cml0eVNjYW5uZXJQcm90b1ABWlZjbG91ZC5nb29nbGUuY29tL2dvL3dlYnNlY3Vy
aXR5c2Nhbm5lci9hcGl2MS93ZWJzZWN1cml0eXNjYW5uZXJwYjt3ZWJzZWN1cml0eXNjYW5u
ZXJwYqoCIkdvb2dsZS5DbG91ZC5XZWJTZWN1cml0eVNjYW5uZXIuVjHKAiJHb29nbGVcQ2xv
dWRcV2ViU2VjdXJpdHlTY2FubmVyXFYx6gIlR29vZ2xlOjpDbG91ZDo6V2ViU2VjdXJpdHlT
Y2FubmVyOjpWMUq/UwoHEgUOANACAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
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
ZS4KCggKAQISAxAAKwoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAPgoJCgIDAxID
FQA6CgkKAgMEEgMWAEUKCQoCAwUSAxcAPgoJCgIDBhIDGAA7CgkKAgMHEgMZACUKCQoCAwgS
AxoAKgoICgEIEgMcAD8KCQoCCCUSAxwAPwoICgEIEgMdAG0KCQoCCAsSAx0AbQoICgEIEgMe
ACIKCQoCCAoSAx4AIgoICgEIEgMfADgKCQoCCAgSAx8AOAoICgEIEgMgAD8KCQoCCAESAyAA
PwoICgEIEgMhAD8KCQoCCCkSAyEAPwoICgEIEgMiAD4KCQoCCC0SAyIAPgrnAQoCBgASBScA
igEBGtkBIFdlYiBTZWN1cml0eSBTY2FubmVyIFNlcnZpY2UgaWRlbnRpZmllcyBzZWN1cml0
eSB2dWxuZXJhYmlsaXRpZXMgaW4gd2ViCiBhcHBsaWNhdGlvbnMgaG9zdGVkIG9uIEdvb2ds
ZSBDbG91ZC4gSXQgY3Jhd2xzIHlvdXIgYXBwbGljYXRpb24sIGFuZAogYXR0ZW1wdHMgdG8g
ZXhlcmNpc2UgYXMgbWFueSB1c2VyIGlucHV0cyBhbmQgZXZlbnQgaGFuZGxlcnMgYXMgcG9z
c2libGUuCgoKCgMGAAESAycIGgoKCgMGAAMSAygCSQoMCgUGAAOZCBIDKAJJCgoKAwYAAxID
KQJWCgwKBQYAA5oIEgMpAlYKKQoEBgACABIELAIxAxobIENyZWF0ZXMgYSBuZXcgU2NhbkNv
bmZpZy4KCgwKBQYAAgABEgMsBhYKDAoFBgACAAISAywXLgoMCgUGAAIAAxIDLDlDCg0KBQYA
AgAEEgQtBDAGChEKCQYAAgAEsMq8IhIELQQwBgpHCgQGAAIBEgQ0AjgDGjkgRGVsZXRlcyBh
biBleGlzdGluZyBTY2FuQ29uZmlnIGFuZCBpdHMgY2hpbGQgcmVzb3VyY2VzLgoKDAoFBgAC
AQESAzQGFgoMCgUGAAIBAhIDNBcuCgwKBQYAAgEDEgM0OU4KDQoFBgACAQQSBDUENwYKEQoJ
BgACAQSwyrwiEgQ1BDcGCiIKBAYAAgISBDsCPwMaFCBHZXRzIGEgU2NhbkNvbmZpZy4KCgwK
BQYAAgIBEgM7BhMKDAoFBgACAgISAzsUKAoMCgUGAAICAxIDOzM9Cg0KBQYAAgIEEgQ8BD4G
ChEKCQYAAgIEsMq8IhIEPAQ+Bgo4CgQGAAIDEgRCAkYDGiogTGlzdHMgU2NhbkNvbmZpZ3Mg
dW5kZXIgYSBnaXZlbiBwcm9qZWN0LgoKDAoFBgACAwESA0IGFQoMCgUGAAIDAhIDQhYsCgwK
BQYAAgMDEgNCN04KDQoFBgACAwQSBEMERQYKEQoJBgACAwSwyrwiEgRDBEUGClkKBAYAAgQS
BEkCTgMaSyBVcGRhdGVzIGEgU2NhbkNvbmZpZy4gVGhpcyBtZXRob2Qgc3VwcG9ydCBwYXJ0
aWFsIHVwZGF0ZSBvZiBhIFNjYW5Db25maWcuCgoMCgUGAAIEARIDSQYWCgwKBQYAAgQCEgNJ
Fy4KDAoFBgACBAMSA0k5QwoNCgUGAAIEBBIESgRNBgoRCgkGAAIEBLDKvCISBEoETQYKQgoE
BgACBRIEUQJWAxo0IFN0YXJ0IGEgU2NhblJ1biBhY2NvcmRpbmcgdG8gdGhlIGdpdmVuIFNj
YW5Db25maWcuCgoMCgUGAAIFARIDUQYSCgwKBQYAAgUCEgNREyYKDAoFBgACBQMSA1ExOAoN
CgUGAAIFBBIEUgRVBgoRCgkGAAIFBLDKvCISBFIEVQYKHwoEBgACBhIEWQJdAxoRIEdldHMg
YSBTY2FuUnVuLgoKDAoFBgACBgESA1kGEAoMCgUGAAIGAhIDWREiCgwKBQYAAgYDEgNZLTQK
DQoFBgACBgQSBFoEXAYKEQoJBgACBgSwyrwiEgRaBFwGCmMKBAYAAgcSBGECZQMaVSBMaXN0
cyBTY2FuUnVucyB1bmRlciBhIGdpdmVuIFNjYW5Db25maWcsIGluIGRlc2NlbmRpbmcgb3Jk
ZXIgb2YgU2NhblJ1bgogc3RvcCB0aW1lLgoKDAoFBgACBwESA2EGEgoMCgUGAAIHAhIDYRMm
CgwKBQYAAgcDEgNhMUUKDQoFBgACBwQSBGIEZAYKEQoJBgACBwSwyrwiEgRiBGQGCkEKBAYA
AggSBGgCbQMaMyBTdG9wcyBhIFNjYW5SdW4uIFRoZSBzdG9wcGVkIFNjYW5SdW4gaXMgcmV0
dXJuZWQuCgoMCgUGAAIIARIDaAYRCgwKBQYAAggCEgNoEiQKDAoFBgACCAMSA2gvNgoNCgUG
AAIIBBIEaQRsBgoRCgkGAAIIBLDKvCISBGkEbAYKNwoEBgACCRIEcAJ0AxopIExpc3QgQ3Jh
d2xlZFVybHMgdW5kZXIgYSBnaXZlbiBTY2FuUnVuLgoKDAoFBgACCQESA3AGFQoMCgUGAAIJ
AhIDcBYsCgwKBQYAAgkDEgNwN04KDQoFBgACCQQSBHEEcwYKEQoJBgACCQSwyrwiEgRxBHMG
Ch8KBAYAAgoSBHcCewMaESBHZXRzIGEgRmluZGluZy4KCgwKBQYAAgoBEgN3BhAKDAoFBgAC
CgISA3cRIgoMCgUGAAIKAxIDdy00Cg0KBQYAAgoEEgR4BHoGChEKCQYAAgoEsMq8IhIEeAR6
Bgo1CgQGAAILEgV+AoIBAxomIExpc3QgRmluZGluZ3MgdW5kZXIgYSBnaXZlbiBTY2FuUnVu
LgoKDAoFBgACCwESA34GEgoMCgUGAAILAhIDfhMmCgwKBQYAAgsDEgN+MUUKDgoFBgACCwQS
BX8EgQEGChIKCQYAAgsEsMq8IhIFfwSBAQYKQgoEBgACDBIGhQECiQEDGjIgTGlzdCBhbGwg
RmluZGluZ1R5cGVTdGF0cyB1bmRlciBhIGdpdmVuIFNjYW5SdW4uCgoNCgUGAAIMARIEhQEG
GgoNCgUGAAIMAhIEhQEbNgoNCgUGAAIMAxIEhQFBXQoPCgUGAAIMBBIGhgEEiAEGChMKCQYA
AgwEsMq8IhIGhgEEiAEGCjoKAgQAEgaNAQCUAQEaLCBSZXF1ZXN0IGZvciB0aGUgYENyZWF0
ZVNjYW5Db25maWdgIG1ldGhvZC4KCgsKAwQAARIEjQEIHwqdAQoEBAACABIEkAECFBqOASBS
ZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lIHdoZXJlIHRoZSBzY2FuIGlzIGNy
ZWF0ZWQsIHdoaWNoIHNob3VsZCBiZSBhCiBwcm9qZWN0IHJlc291cmNlIG5hbWUgaW4gdGhl
IGZvcm1hdCAncHJvamVjdHMve3Byb2plY3RJZH0nLgoKDQoFBAACAAUSBJABAggKDQoFBAAC
AAESBJABCQ8KDQoFBAACAAMSBJABEhMKNwoEBAACARIEkwECHRopIFJlcXVpcmVkLiBUaGUg
U2NhbkNvbmZpZyB0byBiZSBjcmVhdGVkLgoKDQoFBAACAQYSBJMBAgwKDQoFBAACAQESBJMB
DRgKDQoFBAACAQMSBJMBGxwKOgoCBAESBpcBAJsBARosIFJlcXVlc3QgZm9yIHRoZSBgRGVs
ZXRlU2NhbkNvbmZpZ2AgbWV0aG9kLgoKCwoDBAEBEgSXAQgfCqABCgQEAQIAEgSaAQISGpEB
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2NhbkNvbmZpZyB0byBiZSBk
ZWxldGVkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0IG9mICdwcm9qZWN0cy97cHJv
amVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfScuCgoNCgUEAQIABRIEmgECCAoN
CgUEAQIAARIEmgEJDQoNCgUEAQIAAxIEmgEQEQo3CgIEAhIGngEAogEBGikgUmVxdWVzdCBm
b3IgdGhlIGBHZXRTY2FuQ29uZmlnYCBtZXRob2QuCgoLCgMEAgESBJ4BCBwKoQEKBAQCAgAS
BKEBAhIakgEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBTY2FuQ29uZmln
IHRvIGJlIHJldHVybmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0IG9mICdwcm9q
ZWN0cy97cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfScuCgoNCgUEAgIA
BRIEoQECCAoNCgUEAgIAARIEoQEJDQoNCgUEAgIAAxIEoQEQEQo5CgIEAxIGpQEAswEBGisg
UmVxdWVzdCBmb3IgdGhlIGBMaXN0U2NhbkNvbmZpZ3NgIG1ldGhvZC4KCgsKAwQDARIEpQEI
HgqCAQoEBAMCABIEqAECFBp0IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNlIG5hbWUs
IHdoaWNoIHNob3VsZCBiZSBhIHByb2plY3QgcmVzb3VyY2UgbmFtZSBpbiB0aGUKIGZvcm1h
dCAncHJvamVjdHMve3Byb2plY3RJZH0nLgoKDQoFBAMCAAUSBKgBAggKDQoFBAMCAAESBKgB
CQ8KDQoFBAMCAAMSBKgBEhMKzwEKBAQDAgESBK0BAhgawAEgQSB0b2tlbiBpZGVudGlmeWlu
ZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0byBiZSByZXR1cm5lZC4gVGhpcyBzaG91bGQgYmUgYQog
YG5leHRfcGFnZV90b2tlbmAgdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIExpc3Qg
cmVxdWVzdC4KIElmIHVuc3BlY2lmaWVkLCB0aGUgZmlyc3QgcGFnZSBvZiByZXN1bHRzIGlz
IHJldHVybmVkLgoKDQoFBAMCAQUSBK0BAggKDQoFBAMCAQESBK0BCRMKDQoFBAMCAQMSBK0B
FhcKrgEKBAQDAgISBLIBAhYanwEgVGhlIG1heGltdW0gbnVtYmVyIG9mIFNjYW5Db25maWdz
IHRvIHJldHVybiwgY2FuIGJlIGxpbWl0ZWQgYnkgc2VydmVyLgogSWYgbm90IHNwZWNpZmll
ZCBvciBub3QgcG9zaXRpdmUsIHRoZSBpbXBsZW1lbnRhdGlvbiB3aWxsIHNlbGVjdCBhCiBy
ZWFzb25hYmxlIHZhbHVlLgoKDQoFBAMCAgUSBLIBAgcKDQoFBAMCAgESBLIBCBEKDQoFBAMC
AgMSBLIBFBUKQQoCBAQSBrYBAMABARozIFJlcXVlc3QgZm9yIHRoZSBgVXBkYXRlU2NhbkNv
bmZpZ1JlcXVlc3RgIG1ldGhvZC4KCgsKAwQEARIEtgEIHwq7AQoEBAQCABIEugECHRqsASBS
ZXF1aXJlZC4gVGhlIFNjYW5Db25maWcgdG8gYmUgdXBkYXRlZC4gVGhlIG5hbWUgZmllbGQg
bXVzdCBiZSBzZXQgdG8gaWRlbnRpZnkgdGhlCiByZXNvdXJjZSB0byBiZSB1cGRhdGVkLiBU
aGUgdmFsdWVzIG9mIGZpZWxkcyBub3QgY292ZXJlZCBieSB0aGUgbWFzawogd2lsbCBiZSBp
Z25vcmVkLgoKDQoFBAQCAAYSBLoBAgwKDQoFBAQCAAESBLoBDRgKDQoFBAQCAAMSBLoBGxwK
wQEKBAQEAgESBL8BAiwasgEgUmVxdWlyZWQuIFRoZSB1cGRhdGUgbWFzayBhcHBsaWVzIHRv
IHRoZSByZXNvdXJjZS4gRm9yIHRoZSBgRmllbGRNYXNrYCBkZWZpbml0aW9uLAogc2VlCiBo
dHRwczovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzL2RvY3MvcmVm
ZXJlbmNlL2dvb2dsZS5wcm90b2J1ZiNmaWVsZG1hc2sKCg0KBQQEAgEGEgS/AQIbCg0KBQQE
AgEBEgS/ARwnCg0KBQQEAgEDEgS/ASorCjoKAgQFEgbDAQDKAQEaLCBSZXNwb25zZSBmb3Ig
dGhlIGBMaXN0U2NhbkNvbmZpZ3NgIG1ldGhvZC4KCgsKAwQFARIEwwEIHwoxCgQEBQIAEgTF
AQInGiMgVGhlIGxpc3Qgb2YgU2NhbkNvbmZpZ3MgcmV0dXJuZWQuCgoNCgUEBQIABBIExQEC
CgoNCgUEBQIABhIExQELFQoNCgUEBQIAARIExQEWIgoNCgUEBQIAAxIExQElJgpvCgQEBQIB
EgTJAQIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBv
ciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0K
BQQFAgEFEgTJAQIICg0KBQQFAgEBEgTJAQkYCg0KBQQFAgEDEgTJARscCjYKAgQGEgbNAQDR
AQEaKCBSZXF1ZXN0IGZvciB0aGUgYFN0YXJ0U2NhblJ1bmAgbWV0aG9kLgoKCwoDBAYBEgTN
AQgbCp0BCgQEBgIAEgTQAQISGo4BIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0
aGUgU2NhbkNvbmZpZyB0byBiZSB1c2VkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0
IG9mICdwcm9qZWN0cy97cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfScu
CgoNCgUEBgIABRIE0AECCAoNCgUEBgIAARIE0AEJDQoNCgUEBgIAAxIE0AEQEQo0CgIEBxIG
1AEA2QEBGiYgUmVxdWVzdCBmb3IgdGhlIGBHZXRTY2FuUnVuYCBtZXRob2QuCgoLCgMEBwES
BNQBCBkKtAEKBAQHAgASBNgBAhIapQEgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9m
IHRoZSBTY2FuUnVuIHRvIGJlIHJldHVybmVkLiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9y
bWF0IG9mCiAncHJvamVjdHMve3Byb2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJ
ZH0vc2NhblJ1bnMve3NjYW5SdW5JZH0nLgoKDQoFBAcCAAUSBNgBAggKDQoFBAcCAAESBNgB
CQ0KDQoFBAcCAAMSBNgBEBEKNgoCBAgSBtwBAOoBARooIFJlcXVlc3QgZm9yIHRoZSBgTGlz
dFNjYW5SdW5zYCBtZXRob2QuCgoLCgMECAESBNwBCBsKmwEKBAQIAgASBN8BAhQajAEgUmVx
dWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgc2Nh
biByZXNvdXJjZSBuYW1lIGluIHRoZQogZm9ybWF0ICdwcm9qZWN0cy97cHJvamVjdElkfS9z
Y2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfScuCgoNCgUECAIABRIE3wECCAoNCgUECAIAARIE
3wEJDwoNCgUECAIAAxIE3wESEwrPAQoEBAgCARIE5AECGBrAASBBIHRva2VuIGlkZW50aWZ5
aW5nIGEgcGFnZSBvZiByZXN1bHRzIHRvIGJlIHJldHVybmVkLiBUaGlzIHNob3VsZCBiZSBh
CiBgbmV4dF9wYWdlX3Rva2VuYCB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgTGlz
dCByZXF1ZXN0LgogSWYgdW5zcGVjaWZpZWQsIHRoZSBmaXJzdCBwYWdlIG9mIHJlc3VsdHMg
aXMgcmV0dXJuZWQuCgoNCgUECAIBBRIE5AECCAoNCgUECAIBARIE5AEJEwoNCgUECAIBAxIE
5AEWFwqrAQoEBAgCAhIE6QECFhqcASBUaGUgbWF4aW11bSBudW1iZXIgb2YgU2NhblJ1bnMg
dG8gcmV0dXJuLCBjYW4gYmUgbGltaXRlZCBieSBzZXJ2ZXIuCiBJZiBub3Qgc3BlY2lmaWVk
IG9yIG5vdCBwb3NpdGl2ZSwgdGhlIGltcGxlbWVudGF0aW9uIHdpbGwgc2VsZWN0IGEKIHJl
YXNvbmFibGUgdmFsdWUuCgoNCgUECAICBRIE6QECBwoNCgUECAICARIE6QEIEQoNCgUECAIC
AxIE6QEUFQo3CgIECRIG7QEA9AEBGikgUmVzcG9uc2UgZm9yIHRoZSBgTGlzdFNjYW5SdW5z
YCBtZXRob2QuCgoLCgMECQESBO0BCBwKLgoEBAkCABIE7wECIRogIFRoZSBsaXN0IG9mIFNj
YW5SdW5zIHJldHVybmVkLgoKDQoFBAkCAAQSBO8BAgoKDQoFBAkCAAYSBO8BCxIKDQoFBAkC
AAESBO8BExwKDQoFBAkCAAMSBO8BHyAKbwoEBAkCARIE8wECHRphIFRva2VuIHRvIHJldHJp
ZXZlIHRoZSBuZXh0IHBhZ2Ugb2YgcmVzdWx0cywgb3IgZW1wdHkgaWYgdGhlcmUgYXJlIG5v
CiBtb3JlIHJlc3VsdHMgaW4gdGhlIGxpc3QuCgoNCgUECQIBBRIE8wECCAoNCgUECQIBARIE
8wEJGAoNCgUECQIBAxIE8wEbHAo1CgIEChIG9wEA/AEBGicgUmVxdWVzdCBmb3IgdGhlIGBT
dG9wU2NhblJ1bmAgbWV0aG9kLgoKCwoDBAoBEgT3AQgaCrMBCgQECgIAEgT7AQISGqQBIFJl
cXVpcmVkLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgU2NhblJ1biB0byBiZSBzdG9wcGVk
LiBUaGUgbmFtZSBmb2xsb3dzIHRoZQogZm9ybWF0IG9mCiAncHJvamVjdHMve3Byb2plY3RJ
ZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhblJ1bnMve3NjYW5SdW5JZH0nLgoK
DQoFBAoCAAUSBPsBAggKDQoFBAoCAAESBPsBCQ0KDQoFBAoCAAMSBPsBEBEKOQoCBAsSBv8B
AI4CARorIFJlcXVlc3QgZm9yIHRoZSBgTGlzdENyYXdsZWRVcmxzYCBtZXRob2QuCgoLCgME
CwESBP8BCB4KtQEKBAQLAgASBIMCAhQapgEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgcmVzb3Vy
Y2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgc2NhbiBydW4gcmVzb3VyY2UgbmFtZSBpbiB0
aGUKIGZvcm1hdAogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29u
ZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQLAgAFEgSDAgIICg0KBQQLAgAB
EgSDAgkPCg0KBQQLAgADEgSDAhITCs8BCgQECwIBEgSIAgIYGsABIEEgdG9rZW4gaWRlbnRp
ZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdG8gYmUgcmV0dXJuZWQuIFRoaXMgc2hvdWxkIGJl
IGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVlIHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBM
aXN0IHJlcXVlc3QuCiBJZiB1bnNwZWNpZmllZCwgdGhlIGZpcnN0IHBhZ2Ugb2YgcmVzdWx0
cyBpcyByZXR1cm5lZC4KCg0KBQQLAgEFEgSIAgIICg0KBQQLAgEBEgSIAgkTCg0KBQQLAgED
EgSIAhYXCq4BCgQECwICEgSNAgIWGp8BIFRoZSBtYXhpbXVtIG51bWJlciBvZiBDcmF3bGVk
VXJscyB0byByZXR1cm4sIGNhbiBiZSBsaW1pdGVkIGJ5IHNlcnZlci4KIElmIG5vdCBzcGVj
aWZpZWQgb3Igbm90IHBvc2l0aXZlLCB0aGUgaW1wbGVtZW50YXRpb24gd2lsbCBzZWxlY3Qg
YQogcmVhc29uYWJsZSB2YWx1ZS4KCg0KBQQLAgIFEgSNAgIHCg0KBQQLAgIBEgSNAggRCg0K
BQQLAgIDEgSNAhQVCjoKAgQMEgaRAgCYAgEaLCBSZXNwb25zZSBmb3IgdGhlIGBMaXN0Q3Jh
d2xlZFVybHNgIG1ldGhvZC4KCgsKAwQMARIEkQIIHwoxCgQEDAIAEgSTAgInGiMgVGhlIGxp
c3Qgb2YgQ3Jhd2xlZFVybHMgcmV0dXJuZWQuCgoNCgUEDAIABBIEkwICCgoNCgUEDAIABhIE
kwILFQoNCgUEDAIAARIEkwIWIgoNCgUEDAIAAxIEkwIlJgpvCgQEDAIBEgSXAgIdGmEgVG9r
ZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0
aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQMAgEFEgSXAgII
Cg0KBQQMAgEBEgSXAgkYCg0KBQQMAgEDEgSXAhscCjQKAgQNEgabAgCgAgEaJiBSZXF1ZXN0
IGZvciB0aGUgYEdldEZpbmRpbmdgIG1ldGhvZC4KCgsKAwQNARIEmwIIGQrJAQoEBA0CABIE
nwICEhq6ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIEZpbmRpbmcgdG8g
YmUgcmV0dXJuZWQuIFRoZSBuYW1lIGZvbGxvd3MgdGhlCiBmb3JtYXQgb2YKICdwcm9qZWN0
cy97cHJvamVjdElkfS9zY2FuQ29uZmlncy97c2NhbkNvbmZpZ0lkfS9zY2FuUnVucy97c2Nh
blJ1bklkfS9maW5kaW5ncy97ZmluZGluZ0lkfScuCgoNCgUEDQIABRIEnwICCAoNCgUEDQIA
ARIEnwIJDQoNCgUEDQIAAxIEnwIQEQo2CgIEDhIGowIAuAIBGiggUmVxdWVzdCBmb3IgdGhl
IGBMaXN0RmluZGluZ3NgIG1ldGhvZC4KCgsKAwQOARIEowIIGwq1AQoEBA4CABIEpwICFBqm
ASBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNvdXJjZSBuYW1lLCB3aGljaCBzaG91bGQgYmUg
YSBzY2FuIHJ1biByZXNvdXJjZSBuYW1lIGluIHRoZQogZm9ybWF0CiAncHJvamVjdHMve3By
b2plY3RJZH0vc2NhbkNvbmZpZ3Mve3NjYW5Db25maWdJZH0vc2NhblJ1bnMve3NjYW5SdW5J
ZH0nLgoKDQoFBA4CAAUSBKcCAggKDQoFBA4CAAESBKcCCQ8KDQoFBA4CAAMSBKcCEhMKpgEK
BAQOAgESBK0CAhQalwEgVGhlIGZpbHRlciBleHByZXNzaW9uLiBUaGUgZXhwcmVzc2lvbiBt
dXN0IGJlIGluIHRoZSBmb3JtYXQ6IDxmaWVsZD4KIDxvcGVyYXRvcj4gPHZhbHVlPi4KIFN1
cHBvcnRlZCBmaWVsZDogJ2ZpbmRpbmdfdHlwZScuCiBTdXBwb3J0ZWQgb3BlcmF0b3I6ICc9
Jy4KCg0KBQQOAgEFEgStAgIICg0KBQQOAgEBEgStAgkPCg0KBQQOAgEDEgStAhITCs8BCgQE
DgICEgSyAgIYGsABIEEgdG9rZW4gaWRlbnRpZnlpbmcgYSBwYWdlIG9mIHJlc3VsdHMgdG8g
YmUgcmV0dXJuZWQuIFRoaXMgc2hvdWxkIGJlIGEKIGBuZXh0X3BhZ2VfdG9rZW5gIHZhbHVl
IHJldHVybmVkIGZyb20gYSBwcmV2aW91cyBMaXN0IHJlcXVlc3QuCiBJZiB1bnNwZWNpZmll
ZCwgdGhlIGZpcnN0IHBhZ2Ugb2YgcmVzdWx0cyBpcyByZXR1cm5lZC4KCg0KBQQOAgIFEgSy
AgIICg0KBQQOAgIBEgSyAgkTCg0KBQQOAgIDEgSyAhYXCqsBCgQEDgIDEgS3AgIWGpwBIFRo
ZSBtYXhpbXVtIG51bWJlciBvZiBGaW5kaW5ncyB0byByZXR1cm4sIGNhbiBiZSBsaW1pdGVk
IGJ5IHNlcnZlci4KIElmIG5vdCBzcGVjaWZpZWQgb3Igbm90IHBvc2l0aXZlLCB0aGUgaW1w
bGVtZW50YXRpb24gd2lsbCBzZWxlY3QgYQogcmVhc29uYWJsZSB2YWx1ZS4KCg0KBQQOAgMF
EgS3AgIHCg0KBQQOAgMBEgS3AggRCg0KBQQOAgMDEgS3AhQVCjcKAgQPEga7AgDCAgEaKSBS
ZXNwb25zZSBmb3IgdGhlIGBMaXN0RmluZGluZ3NgIG1ldGhvZC4KCgsKAwQPARIEuwIIHAou
CgQEDwIAEgS9AgIgGiAgVGhlIGxpc3Qgb2YgRmluZGluZ3MgcmV0dXJuZWQuCgoNCgUEDwIA
BBIEvQICCgoNCgUEDwIABhIEvQILEgoNCgUEDwIAARIEvQITGwoNCgUEDwIAAxIEvQIeHwpv
CgQEDwIBEgTBAgIdGmEgVG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiByZXN1
bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8KIG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlz
dC4KCg0KBQQPAgEFEgTBAgIICg0KBQQPAgEBEgTBAgkYCg0KBQQPAgEDEgTBAhscCj4KAgQQ
EgbFAgDKAgEaMCBSZXF1ZXN0IGZvciB0aGUgYExpc3RGaW5kaW5nVHlwZVN0YXRzYCBtZXRo
b2QuCgoLCgMEEAESBMUCCCMKtQEKBAQQAgASBMkCAhQapgEgUmVxdWlyZWQuIFRoZSBwYXJl
bnQgcmVzb3VyY2UgbmFtZSwgd2hpY2ggc2hvdWxkIGJlIGEgc2NhbiBydW4gcmVzb3VyY2Ug
bmFtZSBpbiB0aGUKIGZvcm1hdAogJ3Byb2plY3RzL3twcm9qZWN0SWR9L3NjYW5Db25maWdz
L3tzY2FuQ29uZmlnSWR9L3NjYW5SdW5zL3tzY2FuUnVuSWR9Jy4KCg0KBQQQAgAFEgTJAgII
Cg0KBQQQAgABEgTJAgkPCg0KBQQQAgADEgTJAhITCj8KAgQREgbNAgDQAgEaMSBSZXNwb25z
ZSBmb3IgdGhlIGBMaXN0RmluZGluZ1R5cGVTdGF0c2AgbWV0aG9kLgoKCwoDBBEBEgTNAggk
CjYKBAQRAgASBM8CAjMaKCBUaGUgbGlzdCBvZiBGaW5kaW5nVHlwZVN0YXRzIHJldHVybmVk
LgoKDQoFBBECAAQSBM8CAgoKDQoFBBECAAYSBM8CCxsKDQoFBBECAAESBM8CHC4KDQoFBBEC
AAMSBM8CMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest ===
    # Fields for CreateScanConfigRequest
    # Field: parent Type: 9 ()
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfig)

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest ===
    # Fields for DeleteScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest ===
    # Fields for GetScanConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest ===
    # Fields for ListScanConfigsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest ===
    # Fields for UpdateScanConfigRequest
    # Field: scan_config Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfig)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse ===
    # Fields for ListScanConfigsResponse
    # Field: scan_configs Type: 11 (.google.cloud.websecurityscanner.v1.ScanConfig)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest ===
    # Fields for StartScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest ===
    # Fields for GetScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest ===
    # Fields for ListScanRunsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse ===
    # Fields for ListScanRunsResponse
    # Field: scan_runs Type: 11 (.google.cloud.websecurityscanner.v1.ScanRun)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest ===
    # Fields for StopScanRunRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest ===
    # Fields for ListCrawledUrlsRequest
    # Field: parent Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse ===
    # Fields for ListCrawledUrlsResponse
    # Field: crawled_urls Type: 11 (.google.cloud.websecurityscanner.v1.CrawledUrl)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest ===
    # Fields for GetFindingRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest ===
    # Fields for ListFindingsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_token Type: 9 ()
    # Field: page_size Type: 5 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse ===
    # Fields for ListFindingsResponse
    # Field: findings Type: 11 (.google.cloud.websecurityscanner.v1.Finding)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest ===
    # Fields for ListFindingTypeStatsRequest
    # Field: parent Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse ===
    # Fields for ListFindingTypeStatsResponse
    # Field: finding_type_stats Type: 11 (.google.cloud.websecurityscanner.v1.FindingTypeStats)

# === Service Client: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::WebSecurityScannerClient ===
package Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::WebSecurityScannerClient;

=pod

=head2 Service Client: Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::WebSecurityScannerClient

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
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'CreateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig',
    });
}

sub delete_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'DeleteScanConfig',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub get_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'GetScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig',
    });
}

sub list_scan_configs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'ListScanConfigs',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse',
    });
}

sub update_scan_config {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'UpdateScanConfig',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig',
    });
}

sub start_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'StartScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun',
    });
}

sub get_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'GetScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun',
    });
}

sub list_scan_runs {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'ListScanRuns',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse',
    });
}

sub stop_scan_run {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'StopScanRun',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun',
    });
}

sub list_crawled_urls {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'ListCrawledUrls',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse',
    });
}

sub get_finding {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'GetFinding',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::Finding::Finding',
    });
}

sub list_findings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'ListFindings',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse',
    });
}

sub list_finding_type_stats {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.websecurityscanner.v1.WebSecurityScanner',
        method         => 'ListFindingTypeStats',
        request        => $req,
        response_class => 'Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::WebSecurityScanner - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/web_security_scanner.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::WebSecurityScanner;

    my $msg = Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest->new({
        parent => $parent,
        scan_config => $scan_config,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/web_security_scanner.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::CreateScanConfigRequest

Request for the `CreateScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource name where the scan is created, which should be a
project resource name in the format 'projects/{projectId}'.

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig>)

Required. The ScanConfig to be created.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::DeleteScanConfigRequest

Request for the `DeleteScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be deleted. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanConfigRequest

Request for the `GetScanConfig` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be returned. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::UpdateScanConfigRequest

Request for the `UpdateScanConfigRequest` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_config() >> / C<< $msg->scan_config($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig>)

Required. The ScanConfig to be updated. The name field must be set to identify the
resource to be updated. The values of fields not covered by the mask
will be ignored.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanConfigsResponse

Response for the `ListScanConfigs` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_configs() >> / C<< $msg->scan_configs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanConfig::ScanConfig>)

The list of ScanConfigs returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StartScanRunRequest

Request for the `StartScanRun` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the ScanConfig to be used. The name follows the
format of 'projects/{projectId}/scanConfigs/{scanConfigId}'.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetScanRunRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListScanRunsResponse

Response for the `ListScanRuns` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->scan_runs() >> / C<< $msg->scan_runs($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::ScanRun::ScanRun>)

The list of ScanRuns returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::StopScanRunRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListCrawledUrlsResponse

Response for the `ListCrawledUrls` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->crawled_urls() >> / C<< $msg->crawled_urls($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::CrawledUrl::CrawledUrl>)

The list of CrawledUrls returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::GetFindingRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsRequest

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

The filter expression. The expression must be in the format: <field>
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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingsResponse

Response for the `ListFindings` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->findings() >> / C<< $msg->findings($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::Finding::Finding>)

The list of Findings returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsRequest

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

=head2 Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::ListFindingTypeStatsResponse

Response for the `ListFindingTypeStats` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->finding_type_stats() >> / C<< $msg->finding_type_stats($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingTypeStats::FindingTypeStats>)

The list of FindingTypeStats returned.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::WebSecurityScanner::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
