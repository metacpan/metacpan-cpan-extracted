package Google::Cloud::Dialogflow::V2beta1::SipTrunk;

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
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92MmJldGExL3NpcF90cnVuay5wcm90bxIfZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5w
cm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9k
dXJhdGlvbi5wcm90bxobZ29vZ2xlL3Byb3RvYnVmL2VtcHR5LnByb3RvGiBnb29nbGUvcHJv
dG9idWYvZmllbGRfbWFzay5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
byKoAQoVQ3JlYXRlU2lwVHJ1bmtSZXF1ZXN0EkIKBnBhcmVudBgBIAEoCUIq4EEC+kEkEiJk
aWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1NpcFRydW5rUgZwYXJlbnQSSwoJc2lwX3RydW5r
GAIgASgLMikuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TaXBUcnVua0ID4EEC
UghzaXBUcnVuayJXChVEZWxldGVTaXBUcnVua1JlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC
+kEkCiJkaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1NpcFRydW5rUgRuYW1lIqABChRMaXN0
U2lwVHJ1bmtzUmVxdWVzdBJCCgZwYXJlbnQYASABKAlCKuBBAvpBJBIiZGlhbG9nZmxvdy5n
b29nbGVhcGlzLmNvbS9TaXBUcnVua1IGcGFyZW50EiAKCXBhZ2Vfc2l6ZRgCIAEoBUID4EEB
UghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAMgASgJQgPgQQFSCXBhZ2VUb2tlbiKJAQoVTGlz
dFNpcFRydW5rc1Jlc3BvbnNlEkgKCnNpcF90cnVua3MYASADKAsyKS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52MmJldGExLlNpcFRydW5rUglzaXBUcnVua3MSJgoPbmV4dF9wYWdlX3Rv
a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIlQKEkdldFNpcFRydW5rUmVxdWVzdBI+CgRuYW1l
GAEgASgJQirgQQL6QSQKImRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vU2lwVHJ1bmtSBG5h
bWUipgEKFVVwZGF0ZVNpcFRydW5rUmVxdWVzdBJLCglzaXBfdHJ1bmsYASABKAsyKS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNpcFRydW5rQgPgQQJSCHNpcFRydW5rEkAK
C3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1
cGRhdGVNYXNrIucECghTaXBUcnVuaxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSMAoRZXhw
ZWN0ZWRfaG9zdG5hbWUYAiADKAlCA+BBAlIQZXhwZWN0ZWRIb3N0bmFtZRJSCgtjb25uZWN0
aW9ucxgDIAMoCzIrLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ29ubmVjdGlv
bkID4EEDUgtjb25uZWN0aW9ucxImCgxkaXNwbGF5X25hbWUYBCABKAlCA+BBAVILZGlzcGxh
eU5hbWUSWAoOcGVlcl9ob3N0bmFtZXMYCCADKAsyLC5nb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52MmJldGExLlNpcEhvc3RuYW1lQgPgQQJSDXBlZXJIb3N0bmFtZXMSdAoVZ29vZ2xlX3Jv
b3RfY2VydF9maWxlGAkgASgOMjwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5T
aXBUcnVuay5Hb29nbGVSb290Q2VydEZpbGVCA+BBAVISZ29vZ2xlUm9vdENlcnRGaWxlIkgK
Ekdvb2dsZVJvb3RDZXJ0RmlsZRIZChVDRVJUX0ZJTEVfVU5TUEVDSUZJRUQQABIXChNFWFRF
Uk5BTF9QUklWQVRFX0NBEAU6eupBdwoiZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9TaXBU
cnVuaxI8cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3NpcFRydW5r
cy97c2lwdHJ1bmt9KglzaXBUcnVua3MyCHNpcFRydW5rIs8HCgpDb25uZWN0aW9uEigKDWNv
bm5lY3Rpb25faWQYASABKAlCA+BBA1IMY29ubmVjdGlvbklkEkwKBXN0YXRlGAIgASgOMjEu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Db25uZWN0aW9uLlN0YXRlQgPgQQNS
BXN0YXRlEkUKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDSABSCnVwZGF0ZVRpbWWIAQESZwoNZXJyb3JfZGV0YWlscxgEIAEoCzI4Lmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ29ubmVjdGlvbi5FcnJvckRldGFpbHNCA+BB
A0gBUgxlcnJvckRldGFpbHOIAQEa1QEKDEVycm9yRGV0YWlscxJzChFjZXJ0aWZpY2F0ZV9z
dGF0ZRgBIAEoDjI8Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ29ubmVjdGlv
bi5DZXJ0aWZpY2F0ZVN0YXRlQgPgQQNIAFIQY2VydGlmaWNhdGVTdGF0ZYgBARIoCg1lcnJv
cl9tZXNzYWdlGAIgASgJSAFSDGVycm9yTWVzc2FnZYgBAUIUChJfY2VydGlmaWNhdGVfc3Rh
dGVCEAoOX2Vycm9yX21lc3NhZ2UiaQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABIN
CglDT05ORUNURUQQARIQCgxESVNDT05ORUNURUQQAhIZChVBVVRIRU5USUNBVElPTl9GQUlM
RUQQAxINCglLRUVQQUxJVkUQBCKzAgoQQ2VydGlmaWNhdGVTdGF0ZRIhCh1DRVJUSUZJQ0FU
RV9TVEFURV9VTlNQRUNJRklFRBAAEhUKEUNFUlRJRklDQVRFX1ZBTElEEAESFwoTQ0VSVElG
SUNBVEVfSU5WQUxJRBACEhcKE0NFUlRJRklDQVRFX0VYUElSRUQQAxIiCh5DRVJUSUZJQ0FU
RV9IT1NUTkFNRV9OT1RfRk9VTkQQBBIfChtDRVJUSUZJQ0FURV9VTkFVVEhFTlRJQ0FURUQQ
BRIlCiFDRVJUSUZJQ0FURV9UUlVTVF9TVE9SRV9OT1RfRk9VTkQQBhInCiNDRVJUSUZJQ0FU
RV9IT1NUTkFNRV9JTlZBTElEX0ZPUk1BVBAHEh4KGkNFUlRJRklDQVRFX1FVT1RBX0VYQ0VF
REVEEAhCDgoMX3VwZGF0ZV90aW1lQhAKDl9lcnJvcl9kZXRhaWxzIrcICgtTaXBIb3N0bmFt
ZRIoCg1wZWVyX2hvc3RuYW1lGAEgASgJQgPgQQJSDHBlZXJIb3N0bmFtZRItChBlbmFibGVk
X3NpcF9waW5nGAIgASgIQgPgQQNSDmVuYWJsZWRTaXBQaW5nEkMKDXBpbmdfaW50ZXJ2YWwY
AyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBA1IMcGluZ0ludGVydmFsEjMK
E3BlZXJfc29ja2V0X2FkZHJlc3MYBCABKAlCA+BBA1IRcGVlclNvY2tldEFkZHJlc3MSVwoN
cHJvYmVfZGV0YWlscxgFIAEoCzItLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEu
UHJvYmVEZXRhaWxzQgPgQQNSDHByb2JlRGV0YWlscxJsChBjb25uZWN0aW9uX3N0YXRlGAYg
ASgOMjwuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TaXBIb3N0bmFtZS5Db25u
ZWN0aW9uU3RhdGVCA+BBA1IPY29ubmVjdGlvblN0YXRlEmsKDWVycm9yX2RldGFpbHMYByAB
KAsyQS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNpcEhvc3RuYW1lLkhvc3Ru
YW1lRXJyb3JEZXRhaWxzQgPgQQNSDGVycm9yRGV0YWlscxq5AQoUSG9zdG5hbWVFcnJvckRl
dGFpbHMSdwoRY2VydGlmaWNhdGVfc3RhdGUYASABKA4yRS5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52MmJldGExLlNpcEhvc3RuYW1lLkhvc3RuYW1lQ2VydGlmaWNhdGVTdGF0ZUID4EED
UhBjZXJ0aWZpY2F0ZVN0YXRlEigKDWVycm9yX21lc3NhZ2UYAiABKAlCA+BBA1IMZXJyb3JN
ZXNzYWdlIn4KD0Nvbm5lY3Rpb25TdGF0ZRIgChxDT05ORUNUSU9OX1NUQVRFX1VOU1BFQ0lG
SUVEEAASDQoJQ09OTkVDVEVEEAESEAoMRElTQ09OTkVDVEVEEAISGQoVQVVUSEVOVElDQVRJ
T05fRkFJTEVEEAMSDQoJS0VFUEFMSVZFEAQi5AEKGEhvc3RuYW1lQ2VydGlmaWNhdGVTdGF0
ZRIqCiZIT1NUTkFNRV9DRVJUSUZJQ0FURV9TVEFURV9VTlNQRUNJRklFRBAAEgkKBVZBTElE
EAESCwoHSU5WQUxJRBACEgsKB0VYUElSRUQQAxIWChJIT1NUTkFNRV9OT1RfRk9VTkQQBBIT
Cg9VTkFVVEhFTlRJQ0FURUQQBRIZChVUUlVTVF9TVE9SRV9OT1RfRk9VTkQQBhIbChdIT1NU
TkFNRV9JTlZBTElEX0ZPUk1BVBAHEhIKDlFVT1RBX0VYQ0VFREVEEAgi2AIKDFByb2JlRGV0
YWlscxJHCg9vcHRpb25zX2xhdGVuY3kYASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25CA+BBA1IOb3B0aW9uc0xhdGVuY3kSYQoMcHJvYmVfc3RhdHVzGAIgASgOMjkuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5Qcm9iZURldGFpbHMuUHJvYmVTdGF0dXNCA+BB
A1ILcHJvYmVTdGF0dXMSPAoJaW5pdF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcEID4EEDUghpbml0VGltZSJeCgtQcm9iZVN0YXR1cxIcChhQUk9CRV9TVEFUVVNf
VU5TUEVDSUZJRUQQABIYChRQUk9CRV9TVEFUVVNfU1VDQ0VTUxABEhcKE1BST0JFX1NUQVRV
U19GQUlMRUQQAjLTCAoJU2lwVHJ1bmtzEs0BCg5DcmVhdGVTaXBUcnVuaxI2Lmdvb2dsZS5j
bG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuQ3JlYXRlU2lwVHJ1bmtSZXF1ZXN0GikuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TaXBUcnVuayJYgtPkkwI/IjIvdjJiZXRhMS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3NpcFRydW5rczoJc2lwX3RydW5r2kEQ
cGFyZW50LHNpcF90cnVuaxKjAQoORGVsZXRlU2lwVHJ1bmsSNi5nb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLkRlbGV0ZVNpcFRydW5rUmVxdWVzdBoWLmdvb2dsZS5wcm90b2J1
Zi5FbXB0eSJBgtPkkwI0KjIvdjJiZXRhMS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3NpcFRydW5rcy8qfdpBBG5hbWUSwwEKDUxpc3RTaXBUcnVua3MSNS5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52MmJldGExLkxpc3RTaXBUcnVua3NSZXF1ZXN0GjYuZ29vZ2xlLmNsb3Vk
LmRpYWxvZ2Zsb3cudjJiZXRhMS5MaXN0U2lwVHJ1bmtzUmVzcG9uc2UiQ4LT5JMCNBIyL3Yy
YmV0YTEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9zaXBUcnVua3PaQQZwYXJl
bnQSsAEKC0dldFNpcFRydW5rEjMuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5H
ZXRTaXBUcnVua1JlcXVlc3QaKS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNp
cFRydW5rIkGC0+STAjQSMi92MmJldGExL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyov
c2lwVHJ1bmtzLyp92kEEbmFtZRLcAQoOVXBkYXRlU2lwVHJ1bmsSNi5nb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52MmJldGExLlVwZGF0ZVNpcFRydW5rUmVxdWVzdBopLmdvb2dsZS5jbG91
ZC5kaWFsb2dmbG93LnYyYmV0YTEuU2lwVHJ1bmsiZ4LT5JMCSTI8L3YyYmV0YTEve3NpcF90
cnVuay5uYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovc2lwVHJ1bmtzLyp9OglzaXBfdHJ1
bmvaQRVzaXBfdHJ1bmssdXBkYXRlX21hc2saeMpBGWRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5j
b23SQVlodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0
dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvZGlhbG9nZmxvd0KiAQojY29tLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTFCDVNpcFRydW5rUHJvdG9QAVpDY2xvdWQuZ29v
Z2xlLmNvbS9nby9kaWFsb2dmbG93L2FwaXYyYmV0YTEvZGlhbG9nZmxvd3BiO2RpYWxvZ2Zs
b3dwYqICAkRGqgIfR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuVjJCZXRhMUrDYgoHEgUOAJID
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
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWACgKCQoCAwUS
AxcAJQoJCgIDBhIDGAAqCgkKAgMHEgMZACkKCAoBCBIDGwA8CgkKAgglEgMbADwKCAoBCBID
HABaCgkKAggLEgMcAFoKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAuCgkKAggIEgMe
AC4KCAoBCBIDHwA8CgkKAggBEgMfADwKCAoBCBIDIAAgCgkKAggkEgMgACAKWQoCBgASBCMA
UgEaTSBTZXJ2aWNlIGZvciBtYW5hZ2luZyBbU2lwVHJ1bmtzXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy52MmJldGExLlNpcFRydW5rXS4KCgoKAwYAARIDIwgRCgoKAwYAAxIDJAJBCgwK
BQYAA5kIEgMkAkEKCwoDBgADEgQlAiczCg0KBQYAA5oIEgQlAiczCjwKBAYAAgASBCoCMAMa
LiBDcmVhdGVzIGEgU2lwVHJ1bmsgZm9yIGEgc3BlY2lmaWVkIGxvY2F0aW9uLgoKDAoFBgAC
AAESAyoGFAoMCgUGAAIAAhIDKhUqCgwKBQYAAgADEgMqNT0KDQoFBgACAAQSBCsELgYKEQoJ
BgACAASwyrwiEgQrBC4GCgwKBQYAAgAEEgMvBD4KDwoIBgACAASbCAASAy8EPgotCgQGAAIB
EgQzAjgDGh8gRGVsZXRlcyBhIHNwZWNpZmllZCBTaXBUcnVuay4KCgwKBQYAAgEBEgMzBhQK
DAoFBgACAQISAzMVKgoMCgUGAAIBAxIDMzVKCg0KBQYAAgEEEgQ0BDYGChEKCQYAAgEEsMq8
IhIENAQ2BgoMCgUGAAIBBBIDNwQyCg8KCAYAAgEEmwgAEgM3BDIKRgoEBgACAhIEOwJAAxo4
IFJldHVybnMgYSBsaXN0IG9mIFNpcFRydW5rcyBpbiB0aGUgc3BlY2lmaWVkIGxvY2F0aW9u
LgoKDAoFBgACAgESAzsGEwoMCgUGAAICAhIDOxQoCgwKBQYAAgIDEgM7M0gKDQoFBgACAgQS
BDwEPgYKEQoJBgACAgSwyrwiEgQ8BD4GCgwKBQYAAgIEEgM/BDQKDwoIBgACAgSbCAASAz8E
NAoxCgQGAAIDEgRDAkgDGiMgUmV0cmlldmVzIHRoZSBzcGVjaWZpZWQgU2lwVHJ1bmsuCgoM
CgUGAAIDARIDQwYRCgwKBQYAAgMCEgNDEiQKDAoFBgACAwMSA0MvNwoNCgUGAAIDBBIERARG
BgoRCgkGAAIDBLDKvCISBEQERgYKDAoFBgACAwQSA0cEMgoPCggGAAIDBJsIABIDRwQyCi8K
BAYAAgQSBEsCUQMaISBVcGRhdGVzIHRoZSBzcGVjaWZpZWQgU2lwVHJ1bmsuCgoMCgUGAAIE
ARIDSwYUCgwKBQYAAgQCEgNLFSoKDAoFBgACBAMSA0s1PQoNCgUGAAIEBBIETARPBgoRCgkG
AAIEBLDKvCISBEwETwYKDAoFBgACBAQSA1AEQwoPCggGAAIEBJsIABIDUARDCnwKAgQAEgRW
AGIBGnAgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IKIFtTaXBUcnVua3MuQ3JlYXRlU2lwVHJ1
bmtdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyYmV0YTEuU2lwVHJ1bmtzLkNyZWF0ZVNp
cFRydW5rXS4KCgoKAwQAARIDVggdCnsKBAQAAgASBFkCXgQabSBSZXF1aXJlZC4gVGhlIGxv
Y2F0aW9uIHRvIGNyZWF0ZSBhIFNJUCB0cnVuayBmb3IuCiBGb3JtYXQ6IGBwcm9qZWN0cy88
UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD5gLgoKDAoFBAACAAUSA1kCCAoM
CgUEAAIAARIDWQkPCgwKBQQAAgADEgNZEhMKDQoFBAACAAgSBFkUXgMKDwoIBAACAAicCAAS
A1oEKgoPCgcEAAIACJ8IEgRbBF0FCjEKBAQAAgESA2ECQhokIFJlcXVpcmVkLiBUaGUgU0lQ
IHRydW5rIHRvIGNyZWF0ZS4KCgwKBQQAAgEGEgNhAgoKDAoFBAACAQESA2ELFAoMCgUEAAIB
AxIDYRcYCgwKBQQAAgEIEgNhGUEKDwoIBAACAQicCAASA2EaQAp8CgIEARIEZgBwARpwIFRo
ZSByZXF1ZXN0IG1lc3NhZ2UgZm9yCiBbU2lwVHJ1bmtzLkRlbGV0ZVNpcFRydW5rXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNpcFRydW5rcy5EZWxldGVTaXBUcnVua10u
CgoKCgMEAQESA2YIHQqSAQoEBAECABIEagJvBBqDASBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIFNJUCB0cnVuayB0byBkZWxldGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVjdCBJ
RD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vc2lwVHJ1bmtzLzxTaXBUcnVuawogSUQ+YC4K
CgwKBQQBAgAFEgNqAggKDAoFBAECAAESA2oJDQoMCgUEAQIAAxIDahARCg0KBQQBAgAIEgRq
Em8DCg8KCAQBAgAInAgAEgNrBCoKDwoHBAECAAifCBIEbARuBQp7CgIEAhIFdACEAQEabiBU
aGUgcmVxdWVzdCBtZXNzYWdlIGZvcgogW1NpcFRydW5rcy5MaXN0U2lwVHJ1bmtzXVtnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MmJldGExLlNpcFRydW5rcy5MaXN0U2lwVHJ1bmtzXS4K
CgoKAwQCARIDdAgcCnkKBAQCAgASBHcCfAQaayBSZXF1aXJlZC4gVGhlIGxvY2F0aW9uIHRv
IGxpc3QgU0lQIHRydW5rcyBmcm9tLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+
L2xvY2F0aW9ucy88TG9jYXRpb24gSUQ+YC4KCgwKBQQCAgAFEgN3AggKDAoFBAICAAESA3cJ
DwoMCgUEAgIAAxIDdxITCg0KBQQCAgAIEgR3FHwDCg8KCAQCAgAInAgAEgN4BCoKDwoHBAIC
AAifCBIEeQR7BQpzCgQEAgIBEgSAAQI/GmUgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJl
ciBvZiBpdGVtcyB0byByZXR1cm4gaW4gYSBzaW5nbGUgcGFnZS4gQnkKIGRlZmF1bHQgMTAw
IGFuZCBhdCBtb3N0IDEwMDAuCgoNCgUEAgIBBRIEgAECBwoNCgUEAgIBARIEgAEIEQoNCgUE
AgIBAxIEgAEUFQoNCgUEAgIBCBIEgAEWPgoQCggEAgIBCJwIABIEgAEXPQpaCgQEAgICEgSD
AQJBGkwgT3B0aW9uYWwuIFRoZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJv
bSBhIHByZXZpb3VzIGxpc3QgcmVxdWVzdC4KCg0KBQQCAgIFEgSDAQIICg0KBQQCAgIBEgSD
AQkTCg0KBQQCAgIDEgSDARYXCg0KBQQCAgIIEgSDARhAChAKCAQCAgIInAgAEgSDARk/Cn0K
AgQDEgaIAQCPAQEabyBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3IKIFtTaXBUcnVua3MuTGlz
dFNpcFRydW5rc11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJiZXRhMS5TaXBUcnVua3Mu
TGlzdFNpcFRydW5rc10uCgoLCgMEAwESBIgBCB0KJwoEBAMCABIEigECIxoZIFRoZSBsaXN0
IG9mIFNJUCB0cnVua3MuCgoNCgUEAwIABBIEigECCgoNCgUEAwIABhIEigELEwoNCgUEAwIA
ARIEigEUHgoNCgUEAwIAAxIEigEhIgpvCgQEAwIBEgSOAQIdGmEgVG9rZW4gdG8gcmV0cmll
dmUgdGhlIG5leHQgcGFnZSBvZiByZXN1bHRzLCBvciBlbXB0eSBpZiB0aGVyZSBhcmUgbm8K
IG1vcmUgcmVzdWx0cyBpbiB0aGUgbGlzdC4KCg0KBQQDAgEFEgSOAQIICg0KBQQDAgEBEgSO
AQkYCg0KBQQDAgEDEgSOARscCngKAgQEEgaTAQCdAQEaaiBUaGUgcmVxdWVzdCBtZXNzYWdl
IGZvcgogW1NpcFRydW5rcy5HZXRTaXBUcnVua11bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djJiZXRhMS5TaXBUcnVua3MuR2V0U2lwVHJ1bmtdLgoKCwoDBAQBEgSTAQgaCpQBCgQEBAIA
EgaXAQKcAQQagwEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBTSVAgdHJ1bmsgdG8gZGVs
ZXRlLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9ucy88TG9jYXRp
b24gSUQ+L3NpcFRydW5rcy88U2lwVHJ1bmsKIElEPmAuCgoNCgUEBAIABRIElwECCAoNCgUE
BAIAARIElwEJDQoNCgUEBAIAAxIElwEQEQoPCgUEBAIACBIGlwESnAEDChAKCAQEAgAInAgA
EgSYAQQqChEKBwQEAgAInwgSBpkBBJsBBQp+CgIEBRIGoQEAqQEBGnAgVGhlIHJlcXVlc3Qg
bWVzc2FnZSBmb3IKIFtTaXBUcnVua3MuVXBkYXRlU2lwVHJ1bmtdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyYmV0YTEuU2lwVHJ1bmtzLlVwZGF0ZVNpcFRydW5rXS4KCgsKAwQFARIE
oQEIHQoxCgQEBQIAEgSjAQJCGiMgUmVxdWlyZWQuIFRoZSBTaXBUcnVuayB0byB1cGRhdGUu
CgoNCgUEBQIABhIEowECCgoNCgUEBQIAARIEowELFAoNCgUEBQIAAxIEowEXGAoNCgUEBQIA
CBIEowEZQQoQCggEBQIACJwIABIEowEaQAqCAQoEBAUCARIGpwECqAEvGnIgT3B0aW9uYWwu
IFRoZSBtYXNrIHRvIGNvbnRyb2wgd2hpY2ggZmllbGRzIGdldCB1cGRhdGVkLiBJZiB0aGUg
bWFzayBpcyBub3QKIHByZXNlbnQsIGFsbCBmaWVsZHMgd2lsbCBiZSB1cGRhdGVkLgoKDQoF
BAUCAQYSBKcBAhsKDQoFBAUCAQESBKcBHCcKDQoFBAUCAQMSBKcBKisKDQoFBAUCAQgSBKgB
Bi4KEAoIBAUCAQicCAASBKgBBy0KgwEKAgQGEgatAQDWAQEadSBTaXBUcnVuayBpcyB0aGUg
cmVzb3VyY2UgdGhhdCByZXByZXNlbnRzIGEgU0lQIHRydW5rIHRvIGNvbm5lY3QgdG8gR29v
Z2xlCiBUZWxlcGhvbnkgcGxhdGZvcm0gU0lQIHRydW5raW5nIHNlcnZpY2UuCgoLCgMEBgES
BK0BCBAKDQoDBAYHEgauAQKzAQQKDwoFBAYHnQgSBq4BArMBBApJCgQEBgQAEga2AQK8AQMa
OSBUaGUgdHlwZSBvZiBHb29nbGUgcm9vdCBjZXJ0aWZpY2F0ZSBmaWxlIHVzZWQgZm9yIG1U
TFMuCgoNCgUEBgQAARIEtgEHGQo0CgYEBgQAAgASBLgBBB4aJCBVbnNwZWNpZmllZCByb290
IGNlcnRpZmljYXRlIGZpbGUuCgoPCgcEBgQAAgABEgS4AQQZCg8KBwQGBAACAAISBLgBHB0K
KgoGBAYEAAIBEgS7AQQcGhogVXNlIGV4dGVybmFsIHByaXZhdGUgQ0EuCgoPCgcEBgQAAgEB
EgS7AQQXCg8KBwQGBAACAQISBLsBGhsKlwEKBAQGAgASBMEBAj0aiAEgSWRlbnRpZmllci4g
VGhlIHVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBTSVAgdHJ1bmsuCiBGb3JtYXQ6IGBwcm9q
ZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vc2lwVHJ1bmtzLzxT
aXBUcnVuawogSUQ+YC4KCg0KBQQGAgAFEgTBAQIICg0KBQQGAgABEgTBAQkNCg0KBQQGAgAD
EgTBARARCg0KBQQGAgAIEgTBARI8ChAKCAQGAgAInAgAEgTBARM7Cn0KBAQGAgESBsUBAsYB
LxptIFJlcXVpcmVkLiBUaGUgZXhwZWN0ZWQgaG9zdG5hbWVzIGluIHRoZSBwZWVyIGNlcnRp
ZmljYXRlIGZyb20gcGFydG5lciB0aGF0CiBpcyB1c2VkIGZvciBUTFMgYXV0aGVudGljYXRp
b24uCgoNCgUEBgIBBBIExQECCgoNCgUEBgIBBRIExQELEQoNCgUEBgIBARIExQESIwoNCgUE
BgIBAxIExQEmJwoNCgUEBgIBCBIExgEGLgoQCggEBgIBCJwIABIExgEHLQo8CgQEBgICEgbJ
AQLKATIaLCBPdXRwdXQgb25seS4gQ29ubmVjdGlvbnMgb2YgdGhlIFNJUCB0cnVuay4KCg0K
BQQGAgIEEgTJAQIKCg0KBQQGAgIGEgTJAQsVCg0KBQQGAgIBEgTJARYhCg0KBQQGAgIDEgTJ
ASQlCg0KBQQGAgIIEgTKAQYxChAKCAQGAgIInAgAEgTKAQcwCj4KBAQGAgMSBM0BAkMaMCBP
cHRpb25hbC4gSHVtYW4gcmVhZGFibGUgYWxpYXMgZm9yIHRoaXMgdHJ1bmsuCgoNCgUEBgID
BRIEzQECCAoNCgUEBgIDARIEzQEJFQoNCgUEBgIDAxIEzQEYGQoNCgUEBgIDCBIEzQEaQgoQ
CggEBgIDCJwIABIEzQEbQQo8CgQEBgIEEgbQAQLRAS8aLCBSZXF1aXJlZC4gUGVlciBob3N0
bmFtZXMgb2YgdGhlIFNJUCB0cnVuay4KCg0KBQQGAgQEEgTQAQIKCg0KBQQGAgQGEgTQAQsW
Cg0KBQQGAgQBEgTQARclCg0KBQQGAgQDEgTQASgpCg0KBQQGAgQIEgTRAQYuChAKCAQGAgQI
nAgAEgTRAQctClAKBAQGAgUSBtQBAtUBLxpAIE9wdGlvbmFsLiBUaGUgcm9vdCBjZXJ0aWZp
Y2F0ZSBmaWxlIHRvIHVzZSBmb3IgdGhpcyBTSVAgdHJ1bmsuCgoNCgUEBgIFBhIE1AECFAoN
CgUEBgIFARIE1AEVKgoNCgUEBgIFAxIE1AEtLgoNCgUEBgIFCBIE1QEGLgoQCggEBgIFCJwI
ABIE1QEHLQo2CgIEBxIG2QEAogIBGiggUmVwcmVzZW50cyBhIGNvbm5lY3Rpb24gZm9yIFNJ
UCBUcnVuay4KCgsKAwQHARIE2QEIEgo0CgQEBwQAEgbbAQLqAQMaJCBUaGUgc3RhdGUgb2Yg
U2lwIFRydW5rIGNvbm5lY3Rpb24uCgoNCgUEBwQAARIE2wEHDAo+CgYEBwQAAgASBN0BBBoa
LiBTSVAgVHJ1bmsgY29ubmVjdGlvbiBzdGF0ZSBpcyBOb3Qgc3BlY2lmaWVkLgoKDwoHBAcE
AAIAARIE3QEEFQoPCgcEBwQAAgACEgTdARgZCjQKBgQHBAACARIE4AEEEhokIFNJUCBUcnVu
ayBjb25uZWN0aW9uIGlzIGNvbm5lY3RlZC4KCg8KBwQHBAACAQESBOABBA0KDwoHBAcEAAIB
AhIE4AEQEQo3CgYEBwQAAgISBOMBBBUaJyBTSVAgVHJ1bmsgY29ubmVjdGlvbiBpcyBkaXNj
b25uZWN0ZWQuCgoPCgcEBwQAAgIBEgTjAQQQCg8KBwQHBAACAgISBOMBExQKQAoGBAcEAAID
EgTmAQQeGjAgU0lQIFRydW5rIGNvbm5lY3Rpb24gaGFzIGF1dGhlbnRpY2F0aW9uIGVycm9y
LgoKDwoHBAcEAAIDARIE5gEEGQoPCgcEBwQAAgMCEgTmARwdCjQKBgQHBAACBBIE6QEEEhok
IFNJUCBUcnVuayBjb25uZWN0aW9uIGlzIGtlZXBhbGl2ZS4KCg8KBwQHBAACBAESBOkBBA0K
DwoHBAcEAAIEAhIE6QEQEQpECgQEBwQBEgbtAQKIAgMaNCBUaGUgc3RhdGUgb2YgU2lwIFRy
dW5rIGNlcnRpZmljYXRlIGF1dGhlbnRpY2F0aW9uLgoKDQoFBAcEAQESBO0BBxcKNQoGBAcE
AQIAEgTvAQQmGiUgQ2VydGlmaWNhdGUgc3RhdGUgaXMgbm90IHNwZWNpZmllZC4KCg8KBwQH
BAECAAESBO8BBCEKDwoHBAcEAQIAAhIE7wEkJQonCgYEBwQBAgESBPIBBBoaFyBDZXJ0aWZp
Y2F0ZSBpcyB2YWxpZC4KCg8KBwQHBAECAQESBPIBBBUKDwoHBAcEAQIBAhIE8gEYGQo4CgYE
BwQBAgISBPUBBBwaKCBDYXRjaCBhbGwgZm9yIGFueSBlcnJvciBub3Qgc3BlY2lmaWVkLgoK
DwoHBAcEAQICARIE9QEEFwoPCgcEBwQBAgICEgT1ARobCjQKBgQHBAECAxIE+AEEHBokIENl
cnRpZmljYXRlIGxlYWYgbm9kZSBoYXMgZXhwaXJlZC4KCg8KBwQHBAECAwESBPgBBBcKDwoH
BAcEAQIDAhIE+AEaGwpUCgYEBwQBAgQSBPsBBCcaRCBUaGVyZSBpcyBubyBob3N0bmFtZSBk
ZWZpbmVkIHRvIGF1dGhlbnRpY2F0ZSBpbiBTaXBUcnVua2luZ1NlcnZlci4KCg8KBwQHBAEC
BAESBPsBBCIKDwoHBAcEAQIEAhIE+wElJgpGCgYEBwQBAgUSBP4BBCQaNiBObyBwYXRoIGZv
dW5kIGZyb20gdGhlIGxlYWYgY2VydGlmaWNhdGUgdG8gYW55IHJvb3QuCgoPCgcEBwQBAgUB
EgT+AQQfCg8KBwQHBAECBQISBP4BIiMKLQoGBAcEAQIGEgSBAgQqGh0gVHJ1c3Qgc3RvcmUg
ZG9lcyBub3QgZXhpc3QuCgoPCgcEBwQBAgYBEgSBAgQlCg8KBwQHBAECBgISBIECKCkKLgoG
BAcEAQIHEgSEAgQsGh4gSG9zdG5hbWUgaGFzIGludmFsaWQgZm9ybWF0LgoKDwoHBAcEAQIH
ARIEhAIEJwoPCgcEBwQBAgcCEgSEAiorCjYKBgQHBAECCBIEhwIEIxomIENlcnRpZmljYXRl
IGhhcyBleGhhdXN0ZWQgaXRzIHF1b3RhLgoKDwoHBAcEAQIIARIEhwIEHgoPCgcEBwQBAggC
EgSHAiEiCksKBAQHAwASBosCApICAxo7IFRoZSBlcnJvciBkZXRhaWxzIG9mIFNpcCBUcnVu
ayBjb25uZWN0aW9uIGF1dGhlbnRpY2F0aW9uLgoKDQoFBAcDAAESBIsCChYKTgoGBAcDAAIA
EgaNAgSOAjQaPCBPdXRwdXQgb25seS4gVGhlIHN0YXR1cyBvZiB0aGUgY2VydGlmaWNhdGUg
YXV0aGVudGljYXRpb24uCgoPCgcEBwMAAgAEEgSNAgQMCg8KBwQHAwACAAYSBI0CDR0KDwoH
BAcDAAIAARIEjQIeLwoPCgcEBwMAAgADEgSNAjIzCg8KBwQHAwACAAgSBI4CCDMKEgoKBAcD
AAIACJwIABIEjgIJMgpLCgYEBwMAAgESBJECBCYaOyBUaGUgZXJyb3IgbWVzc2FnZSBwcm92
aWRlZCBmcm9tIFNJUCB0cnVua2luZyBhdXRoIHNlcnZpY2UKCg8KBwQHAwACAQQSBJECBAwK
DwoHBAcDAAIBBRIEkQINEwoPCgcEBwMAAgEBEgSRAhQhCg8KBwQHAwACAQMSBJECJCUKTwoE
BAcCABIElQICRxpBIE91dHB1dCBvbmx5LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhl
IFNJUCBUcnVuayBjb25uZWN0aW9uLgoKDQoFBAcCAAUSBJUCAggKDQoFBAcCAAESBJUCCRYK
DQoFBAcCAAMSBJUCGRoKDQoFBAcCAAgSBJUCG0YKEAoIBAcCAAicCAASBJUCHEUKNQoEBAcC
ARIEmAICPhonIE91dHB1dCBvbmx5LiBTdGF0ZSBvZiB0aGUgY29ubmVjdGlvbi4KCg0KBQQH
AgEGEgSYAgIHCg0KBQQHAgEBEgSYAggNCg0KBQQHAgEDEgSYAhARCg0KBQQHAgEIEgSYAhI9
ChAKCAQHAgEInAgAEgSYAhM8CkIKBAQHAgISBpsCApwCMhoyIE91dHB1dCBvbmx5LiBXaGVu
IHRoZSBjb25uZWN0aW9uIHN0YXR1cyBjaGFuZ2VkLgoKDQoFBAcCAgQSBJsCAgoKDQoFBAcC
AgYSBJsCCyQKDQoFBAcCAgESBJsCJTAKDQoFBAcCAgMSBJsCMzQKDQoFBAcCAggSBJwCBjEK
EAoIBAcCAgicCAASBJwCBzAKdgoEBAcCAxIGoAICoQIyGmYgT3V0cHV0IG9ubHkuIFRoZSBl
cnJvciBkZXRhaWxzIGZvciB0aGUgY29ubmVjdGlvbi4gT25seSBwb3B1bGF0ZWQgd2hlbgog
YXV0aGVudGljYXRpb24gZXJyb3JzIG9jY3VyLgoKDQoFBAcCAwQSBKACAgoKDQoFBAcCAwYS
BKACCxcKDQoFBAcCAwESBKACGCUKDQoFBAcCAwMSBKACKCkKDQoFBAcCAwgSBKECBjEKEAoI
BAcCAwicCAASBKECBzAKOQoCBAgSBqUCAPgCARorIFJlcHJlc2VudHMgYSBwZWVyIGhvc3Ru
YW1lIGZvciBTSVAgVHJ1bmsuCgoLCgMECAESBKUCCBMKNwoEBAgEABIGpwICtgIDGicgVGhl
IHN0YXRlIG9mIFNCQyBob3N0bmFtZSBjb25uZWN0aW9uLgoKDQoFBAgEAAESBKcCBxYKQQoG
BAgEAAIAEgSpAgQlGjEgU0JDIGhvc3RuYW1lIGNvbm5lY3Rpb24gc3RhdGUgaXMgTm90IHNw
ZWNpZmllZC4KCg8KBwQIBAACAAESBKkCBCAKDwoHBAgEAAIAAhIEqQIjJAo3CgYECAQAAgES
BKwCBBIaJyBTQkMgaG9zdG5hbWUgY29ubmVjdGlvbiBpcyBjb25uZWN0ZWQuCgoPCgcECAQA
AgEBEgSsAgQNCg8KBwQIBAACAQISBKwCEBEKOgoGBAgEAAICEgSvAgQVGiogU0JDIGhvc3Ru
YW1lIGNvbm5lY3Rpb24gaXMgZGlzY29ubmVjdGVkLgoKDwoHBAgEAAICARIErwIEEAoPCgcE
CAQAAgICEgSvAhMUCkMKBgQIBAACAxIEsgIEHhozIFNCQyBob3N0bmFtZSBjb25uZWN0aW9u
IGhhcyBhdXRoZW50aWNhdGlvbiBlcnJvci4KCg8KBwQIBAACAwESBLICBBkKDwoHBAgEAAID
AhIEsgIcHQo3CgYECAQAAgQSBLUCBBIaJyBTQkMgaG9zdG5hbWUgY29ubmVjdGlvbiBpcyBr
ZWVwYWxpdmUuCgoPCgcECAQAAgQBEgS1AgQNCg8KBwQIBAACBAISBLUCEBEKRAoEBAgEARIG
uQIC1AIDGjQgVGhlIHN0YXRlIG9mIFNpcCBUcnVuayBjZXJ0aWZpY2F0ZSBhdXRoZW50aWNh
dGlvbi4KCg0KBQQIBAEBEgS5AgcfCjUKBgQIBAECABIEuwIELxolIENlcnRpZmljYXRlIHN0
YXRlIGlzIG5vdCBzcGVjaWZpZWQuCgoPCgcECAQBAgABEgS7AgQqCg8KBwQIBAECAAISBLsC
LS4KJwoGBAgEAQIBEgS+AgQOGhcgQ2VydGlmaWNhdGUgaXMgdmFsaWQuCgoPCgcECAQBAgEB
EgS+AgQJCg8KBwQIBAECAQISBL4CDA0KOAoGBAgEAQICEgTBAgQQGiggQ2F0Y2ggYWxsIGZv
ciBhbnkgZXJyb3Igbm90IHNwZWNpZmllZC4KCg8KBwQIBAECAgESBMECBAsKDwoHBAgEAQIC
AhIEwQIODwo0CgYECAQBAgMSBMQCBBAaJCBDZXJ0aWZpY2F0ZSBsZWFmIG5vZGUgaGFzIGV4
cGlyZWQuCgoPCgcECAQBAgMBEgTEAgQLCg8KBwQIBAECAwISBMQCDg8KVAoGBAgEAQIEEgTH
AgQbGkQgVGhlcmUgaXMgbm8gaG9zdG5hbWUgZGVmaW5lZCB0byBhdXRoZW50aWNhdGUgaW4g
U2lwVHJ1bmtpbmdTZXJ2ZXIuCgoPCgcECAQBAgQBEgTHAgQWCg8KBwQIBAECBAISBMcCGRoK
RgoGBAgEAQIFEgTKAgQYGjYgTm8gcGF0aCBmb3VuZCBmcm9tIHRoZSBsZWFmIGNlcnRpZmlj
YXRlIHRvIGFueSByb290LgoKDwoHBAgEAQIFARIEygIEEwoPCgcECAQBAgUCEgTKAhYXCi0K
BgQIBAECBhIEzQIEHhodIFRydXN0IHN0b3JlIGRvZXMgbm90IGV4aXN0LgoKDwoHBAgEAQIG
ARIEzQIEGQoPCgcECAQBAgYCEgTNAhwdCi4KBgQIBAECBxIE0AIEIBoeIEhvc3RuYW1lIGhh
cyBpbnZhbGlkIGZvcm1hdC4KCg8KBwQIBAECBwESBNACBBsKDwoHBAgEAQIHAhIE0AIeHwo2
CgYECAQBAggSBNMCBBcaJiBDZXJ0aWZpY2F0ZSBoYXMgZXhoYXVzdGVkIGl0cyBxdW90YS4K
Cg8KBwQIBAECCAESBNMCBBIKDwoHBAgEAQIIAhIE0wIVFgpTCgQECAMAEgbXAgLeAgMaQyBU
aGUgZXJyb3IgZGV0YWlscyBvZiBTaXAgVHJ1bmsgaG9zdG5hbWVjb25uZWN0aW9uIGF1dGhl
bnRpY2F0aW9uLgoKDQoFBAgDAAESBNcCCh4KTgoGBAgDAAIAEgbZAgTaAjQaPCBPdXRwdXQg
b25seS4gVGhlIHN0YXR1cyBvZiB0aGUgY2VydGlmaWNhdGUgYXV0aGVudGljYXRpb24uCgoP
CgcECAMAAgAGEgTZAgQcCg8KBwQIAwACAAESBNkCHS4KDwoHBAgDAAIAAxIE2QIxMgoPCgcE
CAMAAgAIEgTaAggzChIKCgQIAwACAAicCAASBNoCCTIKWAoGBAgDAAIBEgTdAgRJGkggT3V0
cHV0IG9ubHkuIFRoZSBlcnJvciBtZXNzYWdlIHByb3ZpZGVkIGZyb20gU0lQIHRydW5raW5n
IGF1dGggc2VydmljZQoKDwoHBAgDAAIBBRIE3QIECgoPCgcECAMAAgEBEgTdAgsYCg8KBwQI
AwACAQMSBN0CGxwKDwoHBAgDAAIBCBIE3QIdSAoSCgoECAMAAgEInAgAEgTdAh5HCi0KBAQI
AgASBOECAkQaHyBSZXF1aXJlZC4gUGVlciBob3N0bmFtZSBuYW1lLgoKDQoFBAgCAAUSBOEC
AggKDQoFBAgCAAESBOECCRYKDQoFBAgCAAMSBOECGRoKDQoFBAgCAAgSBOECG0MKEAoIBAgC
AAicCAASBOECHEIKQAoEBAgCARIE5AICSBoyIE91dHB1dCBvbmx5LiBQZWVyIGhvc3RuYW1l
IGVuYWJsZWQgZm9yIFNJUCBwaW5nLgoKDQoFBAgCAQUSBOQCAgYKDQoFBAgCAQESBOQCBxcK
DQoFBAgCAQMSBOQCGhsKDQoFBAgCAQgSBOQCHEcKEAoIBAgCAQicCAASBOQCHUYKQwoEBAgC
AhIG5wIC6AIyGjMgT3V0cHV0IG9ubHkuIEhvdyBvZnRlbiB0aGUgc2lwIHBpbmcgc2hvdWxk
IG9jY3VyLgoKDQoFBAgCAgYSBOcCAhoKDQoFBAgCAgESBOcCGygKDQoFBAgCAgMSBOcCKywK
DQoFBAgCAggSBOgCBjEKEAoIBAgCAgicCAASBOgCBzAKTwoEBAgCAxIE6wICTRpBIE91dHB1
dCBvbmx5LiBUaGUgcGVlcl9zb2NrZXQgYWRkcmVzcyBvZiB0aGUgcGFydG5lciBTQkMgcGlu
Z2VkLgoKDQoFBAgCAwUSBOsCAggKDQoFBAgCAwESBOsCCRwKDQoFBAgCAwMSBOsCHyAKDQoF
BAgCAwgSBOsCIUwKEAoIBAgCAwicCAASBOsCIksKQAoEBAgCBBIE7gICTRoyIE91dHB1dCBv
bmx5LiBUaGUgZGV0YWlscyBmcm9tIHRoZSBvcHRpb25zIHByb2JlLgoKDQoFBAgCBAYSBO4C
Ag4KDQoFBAgCBAESBO4CDxwKDQoFBAgCBAMSBO4CHyAKDQoFBAgCBAgSBO4CIUwKEAoIBAgC
BAicCAASBO4CIksKNwoEBAgCBRIG8QIC8gIyGicgT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRo
ZSBjb25uZWN0aW9uLgoKDQoFBAgCBQYSBPECAhEKDQoFBAgCBQESBPECEiIKDQoFBAgCBQMS
BPECJSYKDQoFBAgCBQgSBPICBjEKEAoIBAgCBQicCAASBPICBzAKdgoEBAgCBhIG9gIC9wIy
GmYgT3V0cHV0IG9ubHkuIFRoZSBlcnJvciBkZXRhaWxzIGZvciB0aGUgY29ubmVjdGlvbi4g
T25seSBwb3B1bGF0ZWQgd2hlbgogYXV0aGVudGljYXRpb24gZXJyb3JzIG9jY3VyLgoKDQoF
BAgCBgYSBPYCAhYKDQoFBAgCBgESBPYCFyQKDQoFBAgCBgMSBPYCJygKDQoFBAgCBggSBPcC
BjEKEAoIBAgCBgicCAASBPcCBzAKPQoCBAkSBvsCAJIDARovIFRoZSBwcm9iZSBkZXRhaWxz
IG9mIFNpcCBUcnVuayBwZWVyIGhvc3RuYW1lLgoKCwoDBAkBEgT7AggUCkgKBAQJBAASBv0C
AoYDAxo4IFRoZSBzdGF0dXMgb2YgSW5pdGlhdGVTaXBPcHRpb25zUGluZyB0byBwZWVyIGhv
c3RuYW1lLgoKDQoFBAkEAAESBP0CBxIKPAoGBAkEAAIAEgT/AgQhGiwgUGVlciBob3N0bmFt
ZSBwaW5nIHN0YXRlIGlzIG5vdCBzcGVjaWZpZWQuCgoPCgcECQQAAgABEgT/AgQcCg8KBwQJ
BAACAAISBP8CHyAKLwoGBAkEAAIBEgSCAwQdGh8gUGVlciBob3N0bmFtZSBwaW5nIHN1Y2Nl
ZWRlZC4KCg8KBwQJBAACAQESBIIDBBgKDwoHBAkEAAIBAhIEggMbHAosCgYECQQAAgISBIUD
BBwaHCBQZWVyIGhvc3RuYW1lIHBpbmcgZmFpbGVkLgoKDwoHBAkEAAICARIEhQMEFwoPCgcE
CQQAAgICEgSFAxobClYKBAQJAgASBokDAooDMhpGIE91dHB1dCBvbmx5LiBEdXJhdGlvbiBi
ZXR3ZWVuIE9QVElPTlMgc2VuZCBhbmQgT1BUSU9OUyAyMDAgcmVjZWl2ZWQuCgoNCgUECQIA
BhIEiQMCGgoNCgUECQIAARIEiQMbKgoNCgUECQIAAxIEiQMtLgoNCgUECQIACBIEigMGMQoQ
CggECQIACJwIABIEigMHMAoxCgQECQIBEgSNAwJLGiMgT3V0cHV0IG9ubHkuIFJlc3VsdCBv
ZiB0aGUgcHJvYmUuCgoNCgUECQIBBhIEjQMCDQoNCgUECQIBARIEjQMOGgoNCgUECQIBAxIE
jQMdHgoNCgUECQIBCBIEjQMfSgoQCggECQIBCJwIABIEjQMgSQpCCgQECQICEgaQAwKRAzIa
MiBPdXRwdXQgb25seS4gV2hlbiB0aGUgb3B0aW9ucyBwcm9iZSB3YXMgc3RhcnRlZC4KCg0K
BQQJAgIGEgSQAwIbCg0KBQQJAgIBEgSQAxwlCg0KBQQJAgIDEgSQAygpCg0KBQQJAgIIEgSR
AwYxChAKCAQJAgIInAgAEgSRAwcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest ===
    # Fields for CreateSipTrunkRequest
    # Field: parent Type: 9 ()
    # Field: sip_trunk Type: 11 (.google.cloud.dialogflow.v2beta1.SipTrunk)

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::DeleteSipTrunkRequest ===
    # Fields for DeleteSipTrunkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksRequest ===
    # Fields for ListSipTrunksRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksResponse ===
    # Fields for ListSipTrunksResponse
    # Field: sip_trunks Type: 11 (.google.cloud.dialogflow.v2beta1.SipTrunk)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::GetSipTrunkRequest ===
    # Fields for GetSipTrunkRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::UpdateSipTrunkRequest ===
    # Fields for UpdateSipTrunkRequest
    # Field: sip_trunk Type: 11 (.google.cloud.dialogflow.v2beta1.SipTrunk)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk ===
    # Fields for SipTrunk
    # Field: name Type: 9 ()
    # Field: expected_hostname Type: 9 ()
    # Field: connections Type: 11 (.google.cloud.dialogflow.v2beta1.Connection)
    # Field: display_name Type: 9 ()
    # Field: peer_hostnames Type: 11 (.google.cloud.dialogflow.v2beta1.SipHostname)
    # Field: google_root_cert_file Type: 14 (.google.cloud.dialogflow.v2beta1.SipTrunk.GoogleRootCertFile)

# Enum: SipTrunk::GoogleRootCertFile
our $SipTrunk_CERT_FILE_UNSPECIFIED = 0;
our $SipTrunk_EXTERNAL_PRIVATE_CA = 5;

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::Connection ===
    # Fields for Connection
    # Field: connection_id Type: 9 ()
    # Field: state Type: 14 (.google.cloud.dialogflow.v2beta1.Connection.State)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: error_details Type: 11 (.google.cloud.dialogflow.v2beta1.Connection.ErrorDetails)

# Enum: Connection::State
our $Connection_STATE_UNSPECIFIED = 0;
our $Connection_CONNECTED = 1;
our $Connection_DISCONNECTED = 2;
our $Connection_AUTHENTICATION_FAILED = 3;
our $Connection_KEEPALIVE = 4;

# Enum: Connection::CertificateState
our $Connection_CERTIFICATE_STATE_UNSPECIFIED = 0;
our $Connection_CERTIFICATE_VALID = 1;
our $Connection_CERTIFICATE_INVALID = 2;
our $Connection_CERTIFICATE_EXPIRED = 3;
our $Connection_CERTIFICATE_HOSTNAME_NOT_FOUND = 4;
our $Connection_CERTIFICATE_UNAUTHENTICATED = 5;
our $Connection_CERTIFICATE_TRUST_STORE_NOT_FOUND = 6;
our $Connection_CERTIFICATE_HOSTNAME_INVALID_FORMAT = 7;
our $Connection_CERTIFICATE_QUOTA_EXCEEDED = 8;

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipHostname ===
    # Fields for SipHostname
    # Field: peer_hostname Type: 9 ()
    # Field: enabled_sip_ping Type: 8 ()
    # Field: ping_interval Type: 11 (.google.protobuf.Duration)
    # Field: peer_socket_address Type: 9 ()
    # Field: probe_details Type: 11 (.google.cloud.dialogflow.v2beta1.ProbeDetails)
    # Field: connection_state Type: 14 (.google.cloud.dialogflow.v2beta1.SipHostname.ConnectionState)
    # Field: error_details Type: 11 (.google.cloud.dialogflow.v2beta1.SipHostname.HostnameErrorDetails)

# Enum: SipHostname::ConnectionState
our $SipHostname_CONNECTION_STATE_UNSPECIFIED = 0;
our $SipHostname_CONNECTED = 1;
our $SipHostname_DISCONNECTED = 2;
our $SipHostname_AUTHENTICATION_FAILED = 3;
our $SipHostname_KEEPALIVE = 4;

# Enum: SipHostname::HostnameCertificateState
our $SipHostname_HOSTNAME_CERTIFICATE_STATE_UNSPECIFIED = 0;
our $SipHostname_VALID = 1;
our $SipHostname_INVALID = 2;
our $SipHostname_EXPIRED = 3;
our $SipHostname_HOSTNAME_NOT_FOUND = 4;
our $SipHostname_UNAUTHENTICATED = 5;
our $SipHostname_TRUST_STORE_NOT_FOUND = 6;
our $SipHostname_HOSTNAME_INVALID_FORMAT = 7;
our $SipHostname_QUOTA_EXCEEDED = 8;

# === Message: Google::Cloud::Dialogflow::V2beta1::SipTrunk::ProbeDetails ===
    # Fields for ProbeDetails
    # Field: options_latency Type: 11 (.google.protobuf.Duration)
    # Field: probe_status Type: 14 (.google.cloud.dialogflow.v2beta1.ProbeDetails.ProbeStatus)
    # Field: init_time Type: 11 (.google.protobuf.Timestamp)

# Enum: ProbeDetails::ProbeStatus
our $ProbeDetails_PROBE_STATUS_UNSPECIFIED = 0;
our $ProbeDetails_PROBE_STATUS_SUCCESS = 1;
our $ProbeDetails_PROBE_STATUS_FAILED = 2;

# === Service Client: Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunksClient ===
package Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunksClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunksClient

Client stub representing the remote C<SipTrunks> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<dialogflow.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dialogflow.googleapis.com:443' );

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

sub create_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'CreateSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk',
    });
}

sub delete_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SipTrunk::DeleteSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'DeleteSipTrunk',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_sip_trunks {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'ListSipTrunks',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksResponse',
    });
}

sub get_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SipTrunk::GetSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'GetSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk',
    });
}

sub update_sip_trunk {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2beta1::SipTrunk::UpdateSipTrunkRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2beta1.SipTrunks',
        method         => 'UpdateSipTrunk',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::SipTrunk - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2beta1/sip_trunk.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2beta1::SipTrunk;

    my $msg = Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest->new({
        parent => $parent,
        sip_trunk => $sip_trunk,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2beta1/sip_trunk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest

The request message for
[SipTrunks.CreateSipTrunk][google.cloud.dialogflow.v2beta1.SipTrunks.CreateSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to create a SIP trunk for.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->sip_trunk() >> / C<< $msg->sip_trunk($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk>)

Required. The SIP trunk to create.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::DeleteSipTrunkRequest

The request message for
[SipTrunks.DeleteSipTrunk][google.cloud.dialogflow.v2beta1.SipTrunks.DeleteSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the SIP trunk to delete.
Format: `projects/<Project ID>/locations/<Location ID>/sipTrunks/<SipTrunk
ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksRequest

The request message for
[SipTrunks.ListSipTrunks][google.cloud.dialogflow.v2beta1.SipTrunks.ListSipTrunks].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location to list SIP trunks from.
Format: `projects/<Project ID>/locations/<Location ID>`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of items to return in a single page. By
default 100 and at most 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The next_page_token value returned from a previous list request.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::ListSipTrunksResponse

The response message for
[SipTrunks.ListSipTrunks][google.cloud.dialogflow.v2beta1.SipTrunks.ListSipTrunks].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sip_trunks() >> / C<< $msg->sip_trunks($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk>)

The list of SIP trunks.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Token to retrieve the next page of results, or empty if there are no
more results in the list.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::GetSipTrunkRequest

The request message for
[SipTrunks.GetSipTrunk][google.cloud.dialogflow.v2beta1.SipTrunks.GetSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the SIP trunk to delete.
Format: `projects/<Project ID>/locations/<Location ID>/sipTrunks/<SipTrunk
ID>`.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::UpdateSipTrunkRequest

The request message for
[SipTrunks.UpdateSipTrunk][google.cloud.dialogflow.v2beta1.SipTrunks.UpdateSipTrunk].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sip_trunk() >> / C<< $msg->sip_trunk($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk>)

Required. The SipTrunk to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The mask to control which fields get updated. If the mask is not
present, all fields will be updated.

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk

SipTrunk is the resource that represents a SIP trunk to connect to Google
Telephony platform SIP trunking service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the SIP trunk.
Format: `projects/<Project ID>/locations/<Location ID>/sipTrunks/<SipTrunk
ID>`.

=item * C<< $msg->expected_hostname() >> / C<< $msg->expected_hostname($value) >>

Type: C<String>

Required. The expected hostnames in the peer certificate from partner that
is used for TLS authentication.

=item * C<< $msg->connections() >> / C<< $msg->connections($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::Connection>)

Output only. Connections of the SIP trunk.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Human readable alias for this trunk.

=item * C<< $msg->peer_hostnames() >> / C<< $msg->peer_hostnames($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipHostname>)

Required. Peer hostnames of the SIP trunk.

=item * C<< $msg->google_root_cert_file() >> / C<< $msg->google_root_cert_file($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::GoogleRootCertFile>)

Optional. The root certificate file to use for this SIP trunk.

=back

=head3 Enum: SipTrunk::GoogleRootCertFile

=over 4

=item * C<CERT_FILE_UNSPECIFIED> => C<0>

=item * C<EXTERNAL_PRIVATE_CA> => C<5>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::Connection

Represents a connection for SIP Trunk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection_id() >> / C<< $msg->connection_id($value) >>

Type: C<String>

Output only. The unique identifier of the SIP Trunk connection.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::Connection::State>)

Output only. State of the connection.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the connection status changed.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::Connection::ErrorDetails>)

Output only. The error details for the connection. Only populated when
authentication errors occur.

=back

=head3 Enum: Connection::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CONNECTED> => C<1>

=item * C<DISCONNECTED> => C<2>

=item * C<AUTHENTICATION_FAILED> => C<3>

=item * C<KEEPALIVE> => C<4>

=back

=head3 Enum: Connection::CertificateState

=over 4

=item * C<CERTIFICATE_STATE_UNSPECIFIED> => C<0>

=item * C<CERTIFICATE_VALID> => C<1>

=item * C<CERTIFICATE_INVALID> => C<2>

=item * C<CERTIFICATE_EXPIRED> => C<3>

=item * C<CERTIFICATE_HOSTNAME_NOT_FOUND> => C<4>

=item * C<CERTIFICATE_UNAUTHENTICATED> => C<5>

=item * C<CERTIFICATE_TRUST_STORE_NOT_FOUND> => C<6>

=item * C<CERTIFICATE_HOSTNAME_INVALID_FORMAT> => C<7>

=item * C<CERTIFICATE_QUOTA_EXCEEDED> => C<8>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipHostname

Represents a peer hostname for SIP Trunk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->peer_hostname() >> / C<< $msg->peer_hostname($value) >>

Type: C<String>

Required. Peer hostname name.

=item * C<< $msg->enabled_sip_ping() >> / C<< $msg->enabled_sip_ping($value) >>

Type: C<Bool>

Output only. Peer hostname enabled for SIP ping.

=item * C<< $msg->ping_interval() >> / C<< $msg->ping_interval($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. How often the sip ping should occur.

=item * C<< $msg->peer_socket_address() >> / C<< $msg->peer_socket_address($value) >>

Type: C<String>

Output only. The peer_socket address of the partner SBC pinged.

=item * C<< $msg->probe_details() >> / C<< $msg->probe_details($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::ProbeDetails>)

Output only. The details from the options probe.

=item * C<< $msg->connection_state() >> / C<< $msg->connection_state($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::SipHostname::ConnectionState>)

Output only. State of the connection.

=item * C<< $msg->error_details() >> / C<< $msg->error_details($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipHostname::HostnameErrorDetails>)

Output only. The error details for the connection. Only populated when
authentication errors occur.

=back

=head3 Enum: SipHostname::ConnectionState

=over 4

=item * C<CONNECTION_STATE_UNSPECIFIED> => C<0>

=item * C<CONNECTED> => C<1>

=item * C<DISCONNECTED> => C<2>

=item * C<AUTHENTICATION_FAILED> => C<3>

=item * C<KEEPALIVE> => C<4>

=back

=head3 Enum: SipHostname::HostnameCertificateState

=over 4

=item * C<HOSTNAME_CERTIFICATE_STATE_UNSPECIFIED> => C<0>

=item * C<VALID> => C<1>

=item * C<INVALID> => C<2>

=item * C<EXPIRED> => C<3>

=item * C<HOSTNAME_NOT_FOUND> => C<4>

=item * C<UNAUTHENTICATED> => C<5>

=item * C<TRUST_STORE_NOT_FOUND> => C<6>

=item * C<HOSTNAME_INVALID_FORMAT> => C<7>

=item * C<QUOTA_EXCEEDED> => C<8>

=back

=head2 Google::Cloud::Dialogflow::V2beta1::SipTrunk::ProbeDetails

The probe details of Sip Trunk peer hostname.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->options_latency() >> / C<< $msg->options_latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. Duration between OPTIONS send and OPTIONS 200 received.

=item * C<< $msg->probe_status() >> / C<< $msg->probe_status($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2beta1::ProbeDetails::ProbeStatus>)

Output only. Result of the probe.

=item * C<< $msg->init_time() >> / C<< $msg->init_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. When the options probe was started.

=back

=head3 Enum: ProbeDetails::ProbeStatus

=over 4

=item * C<PROBE_STATUS_UNSPECIFIED> => C<0>

=item * C<PROBE_STATUS_SUCCESS> => C<1>

=item * C<PROBE_STATUS_FAILED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2beta1::SipTrunk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
