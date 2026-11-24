package Google::Cloud::Dialogflow::V2::AnswerRecord;

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
    eval { require Google::Cloud::Dialogflow::V2::Generator };
    eval { require Google::Cloud::Dialogflow::V2::Participant };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9hbnN3ZXJfcmVjb3JkLnByb3RvEhpnb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9kaWFsb2dmbG93
L3YyL2dlbmVyYXRvci5wcm90bxosZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvdjIvcGFydGlj
aXBhbnQucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIp0DCgxBbnN3ZXJSZWNvcmQSEgoEbmFtZRgBIAEo
CVIEbmFtZRJYCg9hbnN3ZXJfZmVlZGJhY2sYAiABKAsyKi5nb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5BbnN3ZXJGZWVkYmFja0ID4EECUg5hbnN3ZXJGZWVkYmFjaxJtChZhZ2VudF9h
c3Npc3RhbnRfcmVjb3JkGAQgASgLMjAuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdl
bnRBc3Npc3RhbnRSZWNvcmRCA+BBA0gAUhRhZ2VudEFzc2lzdGFudFJlY29yZDqlAepBoQEK
JmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vQW5zd2VyUmVjb3JkEjBwcm9qZWN0cy97cHJv
amVjdH0vYW5zd2VyUmVjb3Jkcy97YW5zd2VyX3JlY29yZH0SRXByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hbnN3ZXJSZWNvcmRzL3thbnN3ZXJfcmVjb3JkfUII
CgZyZWNvcmQixQEKGExpc3RBbnN3ZXJSZWNvcmRzUmVxdWVzdBJGCgZwYXJlbnQYASABKAlC
LuBBAvpBKBImZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9BbnN3ZXJSZWNvcmRSBnBhcmVu
dBIbCgZmaWx0ZXIYAiABKAlCA+BBAVIGZmlsdGVyEiAKCXBhZ2Vfc2l6ZRgDIAEoBUID4EEB
UghwYWdlU2l6ZRIiCgpwYWdlX3Rva2VuGAQgASgJQgPgQQFSCXBhZ2VUb2tlbiKUAQoZTGlz
dEFuc3dlclJlY29yZHNSZXNwb25zZRJPCg5hbnN3ZXJfcmVjb3JkcxgBIAMoCzIoLmdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFuc3dlclJlY29yZFINYW5zd2VyUmVjb3JkcxImCg9u
ZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9rZW4isQEKGVVwZGF0ZUFuc3dlclJl
Y29yZFJlcXVlc3QSUgoNYW5zd2VyX3JlY29yZBgBIAEoCzIoLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LnYyLkFuc3dlclJlY29yZEID4EECUgxhbnN3ZXJSZWNvcmQSQAoLdXBkYXRlX21h
c2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2si
rgQKDkFuc3dlckZlZWRiYWNrEmgKEWNvcnJlY3RuZXNzX2xldmVsGAEgASgOMjsuZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuQW5zd2VyRmVlZGJhY2suQ29ycmVjdG5lc3NMZXZlbFIQ
Y29ycmVjdG5lc3NMZXZlbBJ7Ch9hZ2VudF9hc3Npc3RhbnRfZGV0YWlsX2ZlZWRiYWNrGAIg
ASgLMjIuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdlbnRBc3Npc3RhbnRGZWVkYmFj
a0gAUhxhZ2VudEFzc2lzdGFudERldGFpbEZlZWRiYWNrEhgKB2NsaWNrZWQYAyABKAhSB2Ns
aWNrZWQSOQoKY2xpY2tfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBS
CWNsaWNrVGltZRIcCglkaXNwbGF5ZWQYBCABKAhSCWRpc3BsYXllZBI9CgxkaXNwbGF5X3Rp
bWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtkaXNwbGF5VGltZSJwChBD
b3JyZWN0bmVzc0xldmVsEiEKHUNPUlJFQ1RORVNTX0xFVkVMX1VOU1BFQ0lGSUVEEAASDwoL
Tk9UX0NPUlJFQ1QQARIVChFQQVJUSUFMTFlfQ09SUkVDVBACEhEKDUZVTExZX0NPUlJFQ1QQ
A0IRCg9kZXRhaWxfZmVlZGJhY2sihQ4KFkFnZW50QXNzaXN0YW50RmVlZGJhY2sScgoQYW5z
d2VyX3JlbGV2YW5jZRgBIAEoDjJCLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFnZW50
QXNzaXN0YW50RmVlZGJhY2suQW5zd2VyUmVsZXZhbmNlQgPgQQFSD2Fuc3dlclJlbGV2YW5j
ZRJ+ChRkb2N1bWVudF9jb3JyZWN0bmVzcxgCIAEoDjJGLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkFnZW50QXNzaXN0YW50RmVlZGJhY2suRG9jdW1lbnRDb3JyZWN0bmVzc0ID4EEB
UhNkb2N1bWVudENvcnJlY3RuZXNzEnsKE2RvY3VtZW50X2VmZmljaWVuY3kYAyABKA4yRS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BZ2VudEFzc2lzdGFudEZlZWRiYWNrLkRvY3Vt
ZW50RWZmaWNpZW5jeUID4EEBUhJkb2N1bWVudEVmZmljaWVuY3kShAEKFnN1bW1hcml6YXRp
b25fZmVlZGJhY2sYBCABKAsySC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BZ2VudEFz
c2lzdGFudEZlZWRiYWNrLlN1bW1hcml6YXRpb25GZWVkYmFja0ID4EEBUhVzdW1tYXJpemF0
aW9uRmVlZGJhY2sSiwEKGWtub3dsZWRnZV9zZWFyY2hfZmVlZGJhY2sYBSABKAsySi5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BZ2VudEFzc2lzdGFudEZlZWRiYWNrLktub3dsZWRn
ZVNlYXJjaEZlZWRiYWNrQgPgQQFSF2tub3dsZWRnZVNlYXJjaEZlZWRiYWNrEosBChlrbm93
bGVkZ2VfYXNzaXN0X2ZlZWRiYWNrGAYgASgLMkouZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djIuQWdlbnRBc3Npc3RhbnRGZWVkYmFjay5Lbm93bGVkZ2VBc3Npc3RGZWVkYmFja0ID4EEB
Uhdrbm93bGVkZ2VBc3Npc3RGZWVkYmFjaxJ4ChJjb21wYW5pb25fZmVlZGJhY2sYCCABKAsy
RC5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BZ2VudEFzc2lzdGFudEZlZWRiYWNrLkNv
bXBhbmlvbkZlZWRiYWNrQgPgQQFSEWNvbXBhbmlvbkZlZWRiYWNrGvoCChVTdW1tYXJpemF0
aW9uRmVlZGJhY2sSOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSCXN0YXJ0VGltZRI7CgtzdWJtaXRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBSCnN1Ym1pdFRpbWUSIQoMc3VtbWFyeV90ZXh0GAMgASgJUgtzdW1tYXJ5
VGV4dBKEAQoNdGV4dF9zZWN0aW9ucxgEIAMoCzJaLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93
LnYyLkFnZW50QXNzaXN0YW50RmVlZGJhY2suU3VtbWFyaXphdGlvbkZlZWRiYWNrLlRleHRT
ZWN0aW9uc0VudHJ5QgPgQQFSDHRleHRTZWN0aW9ucxo/ChFUZXh0U2VjdGlvbnNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGmEKF0tub3dsZWRn
ZVNlYXJjaEZlZWRiYWNrEiMKDWFuc3dlcl9jb3BpZWQYASABKAhSDGFuc3dlckNvcGllZBIh
CgxjbGlja2VkX3VyaXMYAiADKAlSC2NsaWNrZWRVcmlzGmEKF0tub3dsZWRnZUFzc2lzdEZl
ZWRiYWNrEiMKDWFuc3dlcl9jb3BpZWQYASABKAhSDGFuc3dlckNvcGllZBIhCgxjbGlja2Vk
X3VyaXMYAiADKAlSC2NsaWNrZWRVcmlzGhMKEUNvbXBhbmlvbkZlZWRiYWNrIlEKD0Fuc3dl
clJlbGV2YW5jZRIgChxBTlNXRVJfUkVMRVZBTkNFX1VOU1BFQ0lGSUVEEAASDgoKSVJSRUxF
VkFOVBABEgwKCFJFTEVWQU5UEAIiVwoTRG9jdW1lbnRDb3JyZWN0bmVzcxIkCiBET0NVTUVO
VF9DT1JSRUNUTkVTU19VTlNQRUNJRklFRBAAEg0KCUlOQ09SUkVDVBABEgsKB0NPUlJFQ1QQ
AiJZChJEb2N1bWVudEVmZmljaWVuY3kSIwofRE9DVU1FTlRfRUZGSUNJRU5DWV9VTlNQRUNJ
RklFRBAAEg8KC0lORUZGSUNJRU5UEAESDQoJRUZGSUNJRU5UEAIi0gUKFEFnZW50QXNzaXN0
YW50UmVjb3JkEmwKGWFydGljbGVfc3VnZ2VzdGlvbl9hbnN3ZXIYBSABKAsyKS5nb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5BcnRpY2xlQW5zd2VyQgPgQQNIAFIXYXJ0aWNsZVN1Z2dl
c3Rpb25BbnN3ZXISSwoKZmFxX2Fuc3dlchgGIAEoCzIlLmdvb2dsZS5jbG91ZC5kaWFsb2dm
bG93LnYyLkZhcUFuc3dlckID4EEDSABSCWZhcUFuc3dlchJzChhkaWFsb2dmbG93X2Fzc2lz
dF9hbnN3ZXIYByABKAsyMi5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5EaWFsb2dmbG93
QXNzaXN0QW5zd2VyQgPgQQNIAFIWZGlhbG9nZmxvd0Fzc2lzdEFuc3dlchJpChRnZW5lcmF0
b3Jfc3VnZ2VzdGlvbhgIIAEoCzIvLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkdlbmVy
YXRvclN1Z2dlc3Rpb25CA+BBA0gAUhNnZW5lcmF0b3JTdWdnZXN0aW9uEmkKFGNvbXBhbmlv
bl9zdWdnZXN0aW9uGAkgASgLMi8uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQ29tcGFu
aW9uU3VnZ2VzdGlvbkID4EEDSABSE2NvbXBhbmlvblN1Z2dlc3Rpb24SqQEKHXJlYWN0aXZl
X2NvbXBhbmlvbl9zdWdnZXN0aW9uGAogASgLMl4uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cu
djIuU3RyZWFtaW5nUmVhY3RpdmVDb21wYW5pb25TdWdnZXN0aW9uc1Jlc3BvbnNlLlJlYWN0
aXZlTW9kZVJlc3BvbnNlQgPgQQNIAFIbcmVhY3RpdmVDb21wYW5pb25TdWdnZXN0aW9uQggK
BmFuc3dlcjKtBQoNQW5zd2VyUmVjb3JkcxLtAQoRTGlzdEFuc3dlclJlY29yZHMSNC5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5MaXN0QW5zd2VyUmVjb3Jkc1JlcXVlc3QaNS5nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5MaXN0QW5zd2VyUmVjb3Jkc1Jlc3BvbnNlImuC0+ST
AlwSJS92Mi97cGFyZW50PXByb2plY3RzLyp9L2Fuc3dlclJlY29yZHNaMxIxL3YyL3twYXJl
bnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vYW5zd2VyUmVjb3Jkc9pBBnBhcmVudBKxAgoS
VXBkYXRlQW5zd2VyUmVjb3JkEjUuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVXBkYXRl
QW5zd2VyUmVjb3JkUmVxdWVzdBooLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFuc3dl
clJlY29yZCK5AYLT5JMClgEyMy92Mi97YW5zd2VyX3JlY29yZC5uYW1lPXByb2plY3RzLyov
YW5zd2VyUmVjb3Jkcy8qfToNYW5zd2VyX3JlY29yZFpQMj8vdjIve2Fuc3dlcl9yZWNvcmQu
bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Fuc3dlclJlY29yZHMvKn06DWFuc3dlcl9y
ZWNvcmTaQRlhbnN3ZXJfcmVjb3JkLHVwZGF0ZV9tYXNrGnjKQRlkaWFsb2dmbG93Lmdvb2ds
ZWFwaXMuY29t0kFZaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2RpYWxvZ2Zsb3dCmAEKHmNv
bS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MkISQW5zd2VyUmVjb3Jkc1Byb3RvUAFaPmNs
b3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9n
Zmxvd3BiogICREaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkqVagoHEgUOAJEDAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgAm
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADQKCQoCAwUSAxcA
NgoJCgIDBhIDGAAqCgkKAgMHEgMZACkKCAoBCBIDGwA3CgkKAgglEgMbADcKCAoBCBIDHABV
CgkKAggLEgMcAFUKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAzCgkKAggIEgMeADMK
CAoBCBIDHwA3CgkKAggBEgMfADcKCAoBCBIDIAAgCgkKAggkEgMgACAKXQoCBgASBCQAQwEa
USBTZXJ2aWNlIGZvciBtYW5hZ2luZwogW0Fuc3dlclJlY29yZHNdW2dvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyLkFuc3dlclJlY29yZF0uCgoKCgMGAAESAyQIFQoKCgMGAAMSAyUCQQoM
CgUGAAOZCBIDJQJBCgsKAwYAAxIEJgIoMwoNCgUGAAOaCBIEJgIoMwpwCgQGAAIAEgQsAjUD
GmIgUmV0dXJucyB0aGUgbGlzdCBvZiBhbGwgYW5zd2VyIHJlY29yZHMgaW4gdGhlIHNwZWNp
ZmllZCBwcm9qZWN0IGluIHJldmVyc2UKIGNocm9ub2xvZ2ljYWwgb3JkZXIuCgoMCgUGAAIA
ARIDLAYXCgwKBQYAAgACEgMsGDAKDAoFBgACAAMSAy0PKAoNCgUGAAIABBIELgQzBgoRCgkG
AAIABLDKvCISBC4EMwYKDAoFBgACAAQSAzQENAoPCggGAAIABJsIABIDNAQ0CjQKBAYAAgES
BDgCQgMaJiBVcGRhdGVzIHRoZSBzcGVjaWZpZWQgYW5zd2VyIHJlY29yZC4KCgwKBQYAAgEB
EgM4BhgKDAoFBgACAQISAzgZMgoMCgUGAAIBAxIDOD1JCg0KBQYAAgEEEgQ5BEAGChEKCQYA
AgEEsMq8IhIEOQRABgoMCgUGAAIBBBIDQQRHCg8KCAYAAgEEmwgAEgNBBEcK8ggKAgQAEgRi
AHkBGuUIIEFuc3dlciByZWNvcmRzIGFyZSByZWNvcmRzIHRvIG1hbmFnZSBhbnN3ZXIgaGlz
dG9yeSBhbmQgZmVlZGJhY2tzIGZvcgogRGlhbG9nZmxvdy4KCiBDdXJyZW50bHksIGFuc3dl
ciByZWNvcmQgaW5jbHVkZXM6CgogLSBodW1hbiBhZ2VudCBhc3Npc3RhbnQgYXJ0aWNsZSBz
dWdnZXN0aW9uCiAtIGh1bWFuIGFnZW50IGFzc2lzdGFudCBmYXEgYXJ0aWNsZQoKIEl0IGRv
ZXNuJ3QgaW5jbHVkZToKCiAtIGBEZXRlY3RJbnRlbnRgIGludGVudCBtYXRjaGluZwogLSBg
RGV0ZWN0SW50ZW50YCBrbm93bGVkZ2UKCiBBbnN3ZXIgcmVjb3JkcyBhcmUgbm90IHJlbGF0
ZWQgdG8gdGhlIGNvbnZlcnNhdGlvbiBoaXN0b3J5IGluIHRoZQogRGlhbG9nZmxvdyBDb25z
b2xlLiBBIFJlY29yZCBpcyBnZW5lcmF0ZWQgZXZlbiB3aGVuIHRoZSBlbmQtdXNlciBkaXNh
YmxlcwogY29udmVyc2F0aW9uIGhpc3RvcnkgaW4gdGhlIGNvbnNvbGUuIFJlY29yZHMgYXJl
IGNyZWF0ZWQgd2hlbiB0aGVyZSdzIGEgaHVtYW4KIGFnZW50IGFzc2lzdGFudCBzdWdnZXN0
aW9uIGdlbmVyYXRlZC4KCiBBIHR5cGljYWwgd29ya2Zsb3cgZm9yIGN1c3RvbWVycyBwcm92
aWRlIGZlZWRiYWNrIHRvIGFuIGFuc3dlciBpczoKCiAxLiBGb3IgaHVtYW4gYWdlbnQgYXNz
aXN0YW50LCBjdXN0b21lcnMgZ2V0IHN1Z2dlc3Rpb24gdmlhIExpc3RTdWdnZXN0aW9ucwog
ICAgQVBJLiBUb2dldGhlciB3aXRoIHRoZSBhbnN3ZXJzLAogICAgW0Fuc3dlclJlY29yZC5u
YW1lXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BbnN3ZXJSZWNvcmQubmFtZV0gYXJl
CiAgICByZXR1cm5lZCB0byB0aGUgY3VzdG9tZXJzLgogMi4gVGhlIGN1c3RvbWVyIHVzZXMg
dGhlCiBbQW5zd2VyUmVjb3JkLm5hbWVdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFu
c3dlclJlY29yZC5uYW1lXSB0byBjYWxsIHRoZQogICAgW0Fuc3dlclJlY29yZHMuVXBkYXRl
QW5zd2VyUmVjb3JkXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BbnN3ZXJSZWNvcmRz
LlVwZGF0ZUFuc3dlclJlY29yZF0KICAgIG1ldGhvZCB0byBzZW5kIGZlZWRiYWNrIGFib3V0
IGEgc3BlY2lmaWMgYW5zd2VyIHRoYXQgdGhleSBiZWxpZXZlIGlzCiAgICB3cm9uZy4KCgoK
AwQAARIDYggUCgsKAwQABxIEYwJnBAoNCgUEAAedCBIEYwJnBAqYAQoEBAACABIDbAISGooB
IFRoZSB1bmlxdWUgaWRlbnRpZmllciBvZiB0aGlzIGFuc3dlciByZWNvcmQuCiBGb3JtYXQ6
IGBwcm9qZWN0cy88UHJvamVjdCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbgogSUQ+L2Fuc3dl
clJlY29yZHMvPEFuc3dlciBSZWNvcmQgSUQ+YC4KCgwKBQQAAgAFEgNsAggKDAoFBAACAAES
A2wJDQoMCgUEAAIAAxIDbBARCuUBCgQEAAIBEgNxAk4a1wEgUmVxdWlyZWQuIFRoZSBBbnN3
ZXJGZWVkYmFjayBmb3IgdGhpcyByZWNvcmQuIFlvdSBjYW4gc2V0IHRoaXMgd2l0aAogW0Fu
c3dlclJlY29yZHMuVXBkYXRlQW5zd2VyUmVjb3JkXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5BbnN3ZXJSZWNvcmRzLlVwZGF0ZUFuc3dlclJlY29yZF0KIGluIG9yZGVyIHRvIGdp
dmUgdXMgZmVlZGJhY2sgYWJvdXQgdGhpcyBhbnN3ZXIuCgoMCgUEAAIBBhIDcQIQCgwKBQQA
AgEBEgNxESAKDAoFBAACAQMSA3EjJAoMCgUEAAIBCBIDcSVNCg8KCAQAAgEInAgAEgNxJkwK
KwoEBAAIABIEdAJ4AxodIFRoZSByZWNvcmQgZm9yIHRoaXMgYW5zd2VyLgoKDAoFBAAIAAES
A3QIDgpCCgQEAAICEgR2BHc0GjQgT3V0cHV0IG9ubHkuIFRoZSByZWNvcmQgZm9yIGh1bWFu
IGFnZW50IGFzc2lzdGFudC4KCgwKBQQAAgIGEgN2BBgKDAoFBAACAgESA3YZLwoMCgUEAAIC
AxIDdjIzCgwKBQQAAgIIEgN3CDMKDwoIBAACAgicCAASA3cJMgqCAQoCBAESBX0ApAEBGnUg
UmVxdWVzdCBtZXNzYWdlIGZvcgogW0Fuc3dlclJlY29yZHMuTGlzdEFuc3dlclJlY29yZHNd
W2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFuc3dlclJlY29yZHMuTGlzdEFuc3dlclJl
Y29yZHNdLgoKCgoDBAEBEgN9CCAKogEKBAQBAgASBoEBAoYBBBqRASBSZXF1aXJlZC4gVGhl
IHByb2plY3QgdG8gbGlzdCBhbGwgYW5zd2VyIHJlY29yZHMgZm9yIGluIHJldmVyc2UKIGNo
cm9ub2xvZ2ljYWwgb3JkZXIuIEZvcm1hdDogYHByb2plY3RzLzxQcm9qZWN0IElEPi9sb2Nh
dGlvbnMvPExvY2F0aW9uCiBJRD5gLgoKDQoFBAECAAUSBIEBAggKDQoFBAECAAESBIEBCQ8K
DQoFBAECAAMSBIEBEhMKDwoFBAECAAgSBoEBFIYBAwoQCggEAQIACJwIABIEggEEKgoRCgcE
AQIACJ8IEgaDAQSFAQUKtwQKBAQBAgESBJgBAj0aqAQgT3B0aW9uYWwuIEZpbHRlcnMgdG8g
cmVzdHJpY3QgcmVzdWx0cyB0byBzcGVjaWZpYyBhbnN3ZXIgcmVjb3Jkcy4gVGhlCiBleHBy
ZXNzaW9uIGhhcyB0aGUgZm9sbG93aW5nIHN5bnRheDoKCiAgICAgPGZpZWxkPiA8b3BlcmF0
b3I+IDx2YWx1ZT4gW0FORCA8ZmllbGQ+IDxvcGVyYXRvcj4gPHZhbHVlPl0gLi4uCgogVGhl
IGZvbGxvd2luZyBmaWVsZHMgYW5kIG9wZXJhdG9ycyBhcmUgc3VwcG9ydGVkOgogKiBjb252
ZXJzYXRpb25faWQgd2l0aCBlcXVhbHMoPSkgb3BlcmF0b3IKCiBFeGFtcGxlczoKCiAqIGBj
b252ZXJzYXRpb25faWQ9YmFyYCBtYXRjaGVzIGFuc3dlciByZWNvcmRzIGluIHRoZQogICBg
cHJvamVjdHMvZm9vL2xvY2F0aW9ucy9nbG9iYWwvY29udmVyc2F0aW9ucy9iYXJgIGNvbnZl
cnNhdGlvbgogICAoYXNzdW1pbmcgdGhlIHBhcmVudCBpcyBgcHJvamVjdHMvZm9vL2xvY2F0
aW9ucy9nbG9iYWxgKS4KCiBGb3IgbW9yZSBpbmZvcm1hdGlvbiBhYm91dCBmaWx0ZXJpbmcs
IHNlZQogW0FQSSBGaWx0ZXJpbmddKGh0dHBzOi8vYWlwLmRldi8xNjApLgoKDQoFBAECAQUS
BJgBAggKDQoFBAECAQESBJgBCQ8KDQoFBAECAQMSBJgBEhMKDQoFBAECAQgSBJgBFDwKEAoI
BAECAQicCAASBJgBFTsKtAEKBAQBAgISBJ0BAj8apQEgT3B0aW9uYWwuIFRoZSBtYXhpbXVt
IG51bWJlciBvZiByZWNvcmRzIHRvIHJldHVybiBpbiBhIHNpbmdsZSBwYWdlLgogVGhlIHNl
cnZlciBtYXkgcmV0dXJuIGZld2VyIHJlY29yZHMgdGhhbiB0aGlzLiBJZiB1bnNwZWNpZmll
ZCwgd2UgdXNlIDEwLgogVGhlIG1heGltdW0gaXMgMTAwLgoKDQoFBAECAgUSBJ0BAgcKDQoF
BAECAgESBJ0BCBEKDQoFBAECAgMSBJ0BFBUKDQoFBAECAggSBJ0BFj4KEAoIBAECAgicCAAS
BJ0BFz0K6gEKBAQBAgMSBKMBAkEa2wEgT3B0aW9uYWwuIFRoZQogW0xpc3RBbnN3ZXJSZWNv
cmRzUmVzcG9uc2UubmV4dF9wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52
Mi5MaXN0QW5zd2VyUmVjb3Jkc1Jlc3BvbnNlLm5leHRfcGFnZV90b2tlbl0KIHZhbHVlIHJl
dHVybmVkIGZyb20gYSBwcmV2aW91cyBsaXN0IHJlcXVlc3QgdXNlZCB0byBjb250aW51ZSBs
aXN0aW5nIG9uCiB0aGUgbmV4dCBwYWdlLgoKDQoFBAECAwUSBKMBAggKDQoFBAECAwESBKMB
CRMKDQoFBAECAwMSBKMBFhcKDQoFBAECAwgSBKMBGEAKEAoIBAECAwicCAASBKMBGT8KhAEK
AgQCEgaoAQCzAQEadiBSZXNwb25zZSBtZXNzYWdlIGZvcgogW0Fuc3dlclJlY29yZHMuTGlz
dEFuc3dlclJlY29yZHNdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFuc3dlclJlY29y
ZHMuTGlzdEFuc3dlclJlY29yZHNdLgoKCwoDBAIBEgSoAQghCisKBAQCAgASBKoBAisaHSBU
aGUgbGlzdCBvZiBhbnN3ZXIgcmVjb3Jkcy4KCg0KBQQCAgAEEgSqAQIKCg0KBQQCAgAGEgSq
AQsXCg0KBQQCAgABEgSqARgmCg0KBQQCAgADEgSqASkqCsQCCgQEAgIBEgSyAQIdGrUCIEEg
dG9rZW4gdG8gcmV0cmlldmUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuIE9yIGVtcHR5IGlmIHRo
ZXJlIGFyZSBubyBtb3JlCiByZXN1bHRzLgogUGFzcyB0aGlzIHZhbHVlIGluIHRoZQogW0xp
c3RBbnN3ZXJSZWNvcmRzUmVxdWVzdC5wYWdlX3Rva2VuXVtnb29nbGUuY2xvdWQuZGlhbG9n
Zmxvdy52Mi5MaXN0QW5zd2VyUmVjb3Jkc1JlcXVlc3QucGFnZV90b2tlbl0KIGZpZWxkIGlu
IHRoZSBzdWJzZXF1ZW50IGNhbGwgdG8gYExpc3RBbnN3ZXJSZWNvcmRzYCBtZXRob2QgdG8g
cmV0cmlldmUgdGhlCiBuZXh0IHBhZ2Ugb2YgcmVzdWx0cy4KCg0KBQQCAgEFEgSyAQIICg0K
BQQCAgEBEgSyAQkYCg0KBQQCAgEDEgSyARscCoUBCgIEAxIGtwEAvgEBGncgUmVxdWVzdCBt
ZXNzYWdlIGZvcgogW0Fuc3dlclJlY29yZHMuVXBkYXRlQW5zd2VyUmVjb3JkXVtnb29nbGUu
Y2xvdWQuZGlhbG9nZmxvdy52Mi5BbnN3ZXJSZWNvcmRzLlVwZGF0ZUFuc3dlclJlY29yZF0u
CgoLCgMEAwESBLcBCCEKMgoEBAMCABIEuQECShokIFJlcXVpcmVkLiBBbnN3ZXIgcmVjb3Jk
IHRvIHVwZGF0ZS4KCg0KBQQDAgAGEgS5AQIOCg0KBQQDAgABEgS5AQ8cCg0KBQQDAgADEgS5
AR8gCg0KBQQDAgAIEgS5ASFJChAKCAQDAgAInAgAEgS5ASJICkkKBAQDAgESBrwBAr0BLxo5
IFJlcXVpcmVkLiBUaGUgbWFzayB0byBjb250cm9sIHdoaWNoIGZpZWxkcyBnZXQgdXBkYXRl
ZC4KCg0KBQQDAgEGEgS8AQIbCg0KBQQDAgEBEgS8ARwnCg0KBQQDAgEDEgS8ASorCg0KBQQD
AgEIEgS9AQYuChAKCAQDAgEInAgAEgS9AQctCnwKAgQEEgbCAQDqAQEabiBSZXByZXNlbnRz
IGZlZWRiYWNrIHRoZSBjdXN0b21lciBoYXMgYWJvdXQgdGhlIHF1YWxpdHkgJiBjb3JyZWN0
bmVzcyBvZiBhCiBjZXJ0YWluIGFuc3dlciBpbiBhIGNvbnZlcnNhdGlvbi4KCgsKAwQEARIE
wgEIFgo1CgQEBAQAEgbEAQLQAQMaJSBUaGUgY29ycmVjdG5lc3MgbGV2ZWwgb2YgYW4gYW5z
d2VyLgoKDQoFBAQEAAESBMQBBxcKMAoGBAQEAAIAEgTGAQQmGiAgQ29ycmVjdG5lc3MgbGV2
ZWwgdW5zcGVjaWZpZWQuCgoPCgcEBAQAAgABEgTGAQQhCg8KBwQEBAACAAISBMYBJCUKKgoG
BAQEAAIBEgTJAQQUGhogQW5zd2VyIGlzIHRvdGFsbHkgd3JvbmcuCgoPCgcEBAQAAgEBEgTJ
AQQPCg8KBwQEBAACAQISBMkBEhMKLgoGBAQEAAICEgTMAQQaGh4gQW5zd2VyIGlzIHBhcnRp
YWxseSBjb3JyZWN0LgoKDwoHBAQEAAICARIEzAEEFQoPCgcEBAQAAgICEgTMARgZCioKBgQE
BAACAxIEzwEEFhoaIEFuc3dlciBpcyBmdWxseSBjb3JyZWN0LgoKDwoHBAQEAAIDARIEzwEE
EQoPCgcEBAQAAgMCEgTPARQVCj0KBAQEAgASBNMBAikaLyBUaGUgY29ycmVjdG5lc3MgbGV2
ZWwgb2YgdGhlIHNwZWNpZmljIGFuc3dlci4KCg0KBQQEAgAGEgTTAQISCg0KBQQEAgABEgTT
ARMkCg0KBQQEAgADEgTTAScoClkKBAQECAASBtYBAtkBAxpJIE5vcm1hbGx5LCBkZXRhaWwg
ZmVlZGJhY2sgaXMgcHJvdmlkZWQgd2hlbiBhbnN3ZXIgaXMgbm90IGZ1bGx5IGNvcnJlY3Qu
CgoNCgUEBAgAARIE1gEIFwo8CgQEBAIBEgTYAQQ/Gi4gRGV0YWlsIGZlZWRiYWNrIG9mIGFn
ZW50IGFzc2lzdCBzdWdnZXN0aW9ucy4KCg0KBQQEAgEGEgTYAQQaCg0KBQQEAgEBEgTYARs6
Cg0KBQQEAgEDEgTYAT0+CvgBCgQEBAICEgTfAQITGukBIEluZGljYXRlcyB3aGV0aGVyIHRo
ZSBhbnN3ZXIvaXRlbSB3YXMgY2xpY2tlZCBieSB0aGUgaHVtYW4gYWdlbnQKIG9yIG5vdC4g
RGVmYXVsdCB0byBmYWxzZS4KIEZvciBrbm93bGVkZ2Ugc2VhcmNoIGFuZCBrbm93bGVkZ2Ug
YXNzaXN0LCB0aGUgYW5zd2VyIHJlY29yZCBpcyBjb25zaWRlcmVkCiB0byBiZSBjbGlja2Vk
IGlmIHRoZSBhbnN3ZXIgd2FzIGNvcGllZCBvciBhbnkgVVJJIHdhcyBjbGlja2VkLgoKDQoF
BAQCAgUSBN8BAgYKDQoFBAQCAgESBN8BBw4KDQoFBAQCAgMSBN8BERIKNgoEBAQCAxIE4gEC
KxooIFRpbWUgd2hlbiB0aGUgYW5zd2VyL2l0ZW0gd2FzIGNsaWNrZWQuCgoNCgUEBAIDBhIE
4gECGwoNCgUEBAIDARIE4gEcJgoNCgUEBAIDAxIE4gEpKgp+CgQEBAIEEgTmAQIVGnAgSW5k
aWNhdGVzIHdoZXRoZXIgdGhlIGFuc3dlci9pdGVtIHdhcyBkaXNwbGF5ZWQgdG8gdGhlIGh1
bWFuCiBhZ2VudCBpbiB0aGUgYWdlbnQgZGVza3RvcCBVSS4gRGVmYXVsdCB0byBmYWxzZS4K
Cg0KBQQEAgQFEgTmAQIGCg0KBQQEAgQBEgTmAQcQCg0KBQQEAgQDEgTmARMUCjgKBAQEAgUS
BOkBAi0aKiBUaW1lIHdoZW4gdGhlIGFuc3dlci9pdGVtIHdhcyBkaXNwbGF5ZWQuCgoNCgUE
BAIFBhIE6QECGwoNCgUEBAIFARIE6QEcKAoNCgUEBAIFAxIE6QErLAo3CgIEBRIG7QEA8wIB
GikgRGV0YWlsIGZlZWRiYWNrIG9mIEFnZW50IEFzc2lzdCByZXN1bHQuCgoLCgMEBQESBO0B
CB4KKQoEBAUEABIG7wEC+AEDGhkgUmVsZXZhbmNlIG9mIGFuIGFuc3dlci4KCg0KBQQFBAAB
EgTvAQcWCi8KBgQFBAACABIE8QEEJRofIEFuc3dlciByZWxldmFuY2UgdW5zcGVjaWZpZWQu
CgoPCgcEBQQAAgABEgTxAQQgCg8KBwQFBAACAAISBPEBIyQKMAoGBAUEAAIBEgT0AQQTGiAg
QW5zd2VyIGlzIGlycmVsZXZhbnQgdG8gcXVlcnkuCgoPCgcEBQQAAgEBEgT0AQQOCg8KBwQF
BAACAQISBPQBERIKLgoGBAUEAAICEgT3AQQRGh4gQW5zd2VyIGlzIHJlbGV2YW50IHRvIHF1
ZXJ5LgoKDwoHBAUEAAICARIE9wEEDAoPCgcEBQQAAgICEgT3AQ8QCioKBAQFBAESBvsBAoQC
AxoaIENvcnJlY3RuZXNzIG9mIGRvY3VtZW50LgoKDQoFBAUEAQESBPsBBxoKMwoGBAUEAQIA
EgT9AQQpGiMgRG9jdW1lbnQgY29ycmVjdG5lc3MgdW5zcGVjaWZpZWQuCgoPCgcEBQQBAgAB
EgT9AQQkCg8KBwQFBAECAAISBP0BJygKNwoGBAUEAQIBEgSAAgQSGicgSW5mb3JtYXRpb24g
aW4gZG9jdW1lbnQgaXMgaW5jb3JyZWN0LgoKDwoHBAUEAQIBARIEgAIEDQoPCgcEBQQBAgEC
EgSAAhARCjUKBgQFBAECAhIEgwIEEBolIEluZm9ybWF0aW9uIGluIGRvY3VtZW50IGlzIGNv
cnJlY3QuCgoPCgcEBQQBAgIBEgSDAgQLCg8KBwQFBAECAgISBIMCDg8KKQoEBAUEAhIGhwIC
kAIDGhkgRWZmaWNpZW5jeSBvZiBkb2N1bWVudC4KCg0KBQQFBAIBEgSHAgcZCjIKBgQFBAIC
ABIEiQIEKBoiIERvY3VtZW50IGVmZmljaWVuY3kgdW5zcGVjaWZpZWQuCgoPCgcEBQQCAgAB
EgSJAgQjCg8KBwQFBAICAAISBIkCJicKKgoGBAUEAgIBEgSMAgQUGhogRG9jdW1lbnQgaXMg
aW5lZmZpY2llbnQuCgoPCgcEBQQCAgEBEgSMAgQPCg8KBwQFBAICAQISBIwCEhMKKAoGBAUE
AgICEgSPAgQSGhggRG9jdW1lbnQgaXMgZWZmaWNpZW50LgoKDwoHBAUEAgICARIEjwIEDQoP
CgcEBQQCAgICEgSPAhARCjoKBAQFAwASBpMCAqACAxoqIEZlZWRiYWNrIGZvciBjb252ZXJz
YXRpb24gc3VtbWFyaXphdGlvbi4KCg0KBQQFAwABEgSTAgofCkEKBgQFAwACABIElQIELRox
IFRpbWVzdGFtcCB3aGVuIGNvbXBvc2luZyBvZiB0aGUgc3VtbWFyeSBzdGFydHMuCgoPCgcE
BQMAAgAGEgSVAgQdCg8KBwQFAwACAAESBJUCHigKDwoHBAUDAAIAAxIElQIrLAo7CgYEBQMA
AgESBJgCBC4aKyBUaW1lc3RhbXAgd2hlbiB0aGUgc3VtbWFyeSB3YXMgc3VibWl0dGVkLgoK
DwoHBAUDAAIBBhIEmAIEHQoPCgcEBQMAAgEBEgSYAh4pCg8KBwQFAwACAQMSBJgCLC0KMwoG
BAUDAAICEgSbAgQcGiMgVGV4dCBvZiBhY3R1YWwgc3VibWl0dGVkIHN1bW1hcnkuCgoPCgcE
BQMAAgIFEgSbAgQKCg8KBwQFAwACAgESBJsCCxcKDwoHBAUDAAICAxIEmwIaGwpICgYEBQMA
AgMSBp4CBJ8CMRo2IE9wdGlvbmFsLiBBY3R1YWwgdGV4dCBzZWN0aW9ucyBvZiBzdWJtaXR0
ZWQgc3VtbWFyeS4KCg8KBwQFAwACAwYSBJ4CBBcKDwoHBAUDAAIDARIEngIYJQoPCgcEBQMA
AgMDEgSeAigpCg8KBwQFAwACAwgSBJ8CCDAKEgoKBAUDAAIDCJwIABIEnwIJLwowCgQEBQMB
EgajAgKwAgMaICBGZWVkYmFjayBmb3Iga25vd2xlZGdlIHNlYXJjaC4KCg0KBQQFAwEBEgSj
AgohCtYBCgYEBQMBAgASBKgCBBsaxQEgV2hldGhlciB0aGUgYW5zd2VyIHdhcyBjb3BpZWQg
YnkgdGhlIGh1bWFuIGFnZW50IG9yIG5vdC4KIElmIHRoZSB2YWx1ZSBpcyBzZXQgdG8gYmUg
dHJ1ZSwKIFtBbnN3ZXJGZWVkYmFjay5jbGlja2VkXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxv
dy52Mi5BbnN3ZXJGZWVkYmFjay5jbGlja2VkXQogd2lsbCBiZSB1cGRhdGVkIHRvIGJlIHRy
dWUuCgoPCgcEBQMBAgAFEgSoAgQICg8KBwQFAwECAAESBKgCCRYKDwoHBAUDAQIAAxIEqAIZ
GgqwAgoGBAUDAQIBEgSvAgQlGp8CIFRoZSBVUklzIGNsaWNrZWQgYnkgdGhlIGh1bWFuIGFn
ZW50LiBUaGUgdmFsdWUgaXMgYXBwZW5kZWQgZm9yIGVhY2gKIFtVcGRhdGVBbnN3ZXJSZWNv
cmRSZXF1ZXN0XVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5VcGRhdGVBbnN3ZXJSZWNv
cmRSZXF1ZXN0XS4KIElmIHRoZSB2YWx1ZSBpcyBub3QgZW1wdHksCiBbQW5zd2VyRmVlZGJh
Y2suY2xpY2tlZF1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQW5zd2VyRmVlZGJhY2su
Y2xpY2tlZF0KIHdpbGwgYmUgdXBkYXRlZCB0byBiZSB0cnVlLgoKDwoHBAUDAQIBBBIErwIE
DAoPCgcEBQMBAgEFEgSvAg0TCg8KBwQFAwECAQESBK8CFCAKDwoHBAUDAQIBAxIErwIjJAow
CgQEBQMCEgazAgLAAgMaICBGZWVkYmFjayBmb3Iga25vd2xlZGdlIGFzc2lzdC4KCg0KBQQF
AwIBEgSzAgohCtkBCgYEBQMCAgASBLgCBBsayAEgV2hldGhlciB0aGUgc3VnZ2VzdGVkIGFu
c3dlciB3YXMgY29waWVkIGJ5IHRoZSBodW1hbiBhZ2VudC4KIElmIHRoZSB2YWx1ZSBpcyBz
ZXQgdG8gYmUgdHJ1ZSwKIFtBbnN3ZXJGZWVkYmFjay5jbGlja2VkXVtnb29nbGUuY2xvdWQu
ZGlhbG9nZmxvdy52Mi5BbnN3ZXJGZWVkYmFjay5jbGlja2VkXQogd2lsbCBiZSB1cGRhdGVk
IHRvIGJlIHRydWUuCgoPCgcEBQMCAgAFEgS4AgQICg8KBwQFAwICAAESBLgCCRYKDwoHBAUD
AgIAAxIEuAIZGgr4AQoGBAUDAgIBEgS/AgQlGucBIFRoZSBVUklzIGNsaWNrZWQgYnkgdGhl
IGh1bWFuIGFnZW50LiBUaGUgdmFsdWUgaXMgYXBwZW5kZWQgZm9yIGVhY2gKIFVwZGF0ZUFu
c3dlclJlY29yZFJlcXVlc3QuCiBJZiB0aGUgdmFsdWUgaXMgbm90IGVtcHR5LAogW0Fuc3dl
ckZlZWRiYWNrLmNsaWNrZWRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFuc3dlckZl
ZWRiYWNrLmNsaWNrZWRdCiB3aWxsIGJlIHVwZGF0ZWQgdG8gYmUgdHJ1ZS4KCg8KBwQFAwIC
AQQSBL8CBAwKDwoHBAUDAgIBBRIEvwINEwoPCgcEBQMCAgEBEgS/AhQgCg8KBwQFAwICAQMS
BL8CIyQKLQoEBAUDAxIEwwICHhofIEZlZWRiYWNrIGZvciBjb21wYW5pb24gYWdlbnQuCgoN
CgUEBQMDARIEwwIKGwq1AwoEBAUCABIEzQICUBqmAyBPcHRpb25hbC4gV2hldGhlciBvciBu
b3QgdGhlIHN1Z2dlc3RlZCBhbnN3ZXIgaXMgcmVsZXZhbnQuCgogRm9yIGV4YW1wbGU6Cgog
KiBRdWVyeTogIkNhbiBJIGNoYW5nZSBteSBtYWlsaW5nIGFkZHJlc3M/IgogKiBTdWdnZXN0
ZWQgZG9jdW1lbnQgc2F5czogIkl0ZW1zIG11c3QgYmUgcmV0dXJuZWQvZXhjaGFuZ2VkIHdp
dGhpbiA2MAogICBkYXlzIG9mIHRoZSBwdXJjaGFzZSBkYXRlLiIKICogW2Fuc3dlcl9yZWxl
dmFuY2VdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFnZW50QXNzaXN0YW50RmVlZGJh
Y2suYW5zd2VyX3JlbGV2YW5jZV06IFtBbnN3ZXJSZWxldmFuY2UuSVJSRUxFVkFOVF1bZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdlbnRBc3Npc3RhbnRGZWVkYmFjay5BbnN3ZXJS
ZWxldmFuY2UuSVJSRUxFVkFOVF0KCg0KBQQFAgAGEgTNAgIRCg0KBQQFAgABEgTNAhIiCg0K
BQQFAgADEgTNAiUmCg0KBQQFAgAIEgTNAidPChAKCAQFAgAInAgAEgTNAihOCoEECgQEBQIB
EgbYAgLZAi8a8AMgT3B0aW9uYWwuIFdoZXRoZXIgb3Igbm90IHRoZSBpbmZvcm1hdGlvbiBp
biB0aGUgZG9jdW1lbnQgaXMgY29ycmVjdC4KCiBGb3IgZXhhbXBsZToKCiAqIFF1ZXJ5OiAi
Q2FuIEkgcmV0dXJuIHRoZSBwYWNrYWdlIGluIDIgZGF5cyBvbmNlIHJlY2VpdmVkPyIKICog
U3VnZ2VzdGVkIGRvY3VtZW50IHNheXM6ICJJdGVtcyBtdXN0IGJlIHJldHVybmVkL2V4Y2hh
bmdlZCB3aXRoaW4gNjAKICAgZGF5cyBvZiB0aGUgcHVyY2hhc2UgZGF0ZS4iCiAqIEdyb3Vu
ZCB0cnV0aDogIk5vIHJldHVybiBvciBleGNoYW5nZSBpcyBhbGxvd2VkLiIKICogW2RvY3Vt
ZW50X2NvcnJlY3RuZXNzXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy52Mi5BZ2VudEFzc2lz
dGFudEZlZWRiYWNrLmRvY3VtZW50X2NvcnJlY3RuZXNzXTogW0lOQ09SUkVDVF1bZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdlbnRBc3Npc3RhbnRGZWVkYmFjay5Eb2N1bWVudENv
cnJlY3RuZXNzLklOQ09SUkVDVF0KCg0KBQQFAgEGEgTYAgIVCg0KBQQFAgEBEgTYAhYqCg0K
BQQFAgEDEgTYAi0uCg0KBQQFAgEIEgTZAgYuChAKCAQFAgEInAgAEgTZAgctCqEDCgQEBQIC
EgbhAgLiAi8akAMgT3B0aW9uYWwuIFdoZXRoZXIgb3Igbm90IHRoZSBzdWdnZXN0ZWQgZG9j
dW1lbnQgaXMgZWZmaWNpZW50LiBGb3IgZXhhbXBsZSwKIGlmIHRoZSBkb2N1bWVudCBpcyBw
b29ybHkgd3JpdHRlbiwgaGFyZCB0byB1bmRlcnN0YW5kLCBoYXJkIHRvIHVzZSBvcgogdG9v
IGxvbmcgdG8gZmluZCB1c2VmdWwgaW5mb3JtYXRpb24sCiBbZG9jdW1lbnRfZWZmaWNpZW5j
eV1bZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuQWdlbnRBc3Npc3RhbnRGZWVkYmFjay5k
b2N1bWVudF9lZmZpY2llbmN5XQogaXMKIFtEb2N1bWVudEVmZmljaWVuY3kuSU5FRkZJQ0lF
TlRdW2dvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLkFnZW50QXNzaXN0YW50RmVlZGJhY2su
RG9jdW1lbnRFZmZpY2llbmN5LklORUZGSUNJRU5UXS4KCg0KBQQFAgIGEgThAgIUCg0KBQQF
AgIBEgThAhUoCg0KBQQFAgIDEgThAissCg0KBQQFAgIIEgTiAgYuChAKCAQFAgIInAgAEgTi
AgctCkQKBAQFAgMSBuUCAuYCLxo0IE9wdGlvbmFsLiBGZWVkYmFjayBmb3IgY29udmVyc2F0
aW9uIHN1bW1hcml6YXRpb24uCgoNCgUEBQIDBhIE5QICFwoNCgUEBQIDARIE5QIYLgoNCgUE
BQIDAxIE5QIxMgoNCgUEBQIDCBIE5gIGLgoQCggEBQIDCJwIABIE5gIHLQo6CgQEBQIEEgbp
AgLqAi8aKiBPcHRpb25hbC4gRmVlZGJhY2sgZm9yIGtub3dsZWRnZSBzZWFyY2guCgoNCgUE
BQIEBhIE6QICGQoNCgUEBQIEARIE6QIaMwoNCgUEBQIEAxIE6QI2NwoNCgUEBQIECBIE6gIG
LgoQCggEBQIECJwIABIE6gIHLQo6CgQEBQIFEgbtAgLuAi8aKiBPcHRpb25hbC4gRmVlZGJh
Y2sgZm9yIGtub3dsZWRnZSBhc3Npc3QuCgoNCgUEBQIFBhIE7QICGQoNCgUEBQIFARIE7QIa
MwoNCgUEBQIFAxIE7QI2NwoNCgUEBQIFCBIE7gIGLgoQCggEBQIFCJwIABIE7gIHLQo5CgQE
BQIGEgbxAgLyAi8aKSBPcHRpb25hbC4gRmVlZGJhY2sgZm9yIGNvbXBhbmlvbiBhZ2VudC4K
Cg0KBQQFAgYGEgTxAgITCg0KBQQFAgYBEgTxAhQmCg0KBQQFAgYDEgTxAikqCg0KBQQFAgYI
EgTyAgYuChAKCAQFAgYInAgAEgTyAgctCkMKAgQGEgb2AgCRAwEaNSBSZXByZXNlbnRzIGEg
cmVjb3JkIG9mIGEgaHVtYW4gYWdlbnQgYXNzaXN0IGFuc3dlci4KCgsKAwQGARIE9gIIHAo3
CgQEBggAEgb4AgKQAwMaJyBPdXRwdXQgb25seS4gVGhlIGFnZW50IGFzc2lzdCBhbnN3ZXIu
CgoNCgUEBggAARIE+AIIDgo9CgQEBgIAEgb6AgT7AjQaLSBPdXRwdXQgb25seS4gVGhlIGFy
dGljbGUgc3VnZ2VzdGlvbiBhbnN3ZXIuCgoNCgUEBgIABhIE+gIEEQoNCgUEBgIAARIE+gIS
KwoNCgUEBgIAAxIE+gIuLwoNCgUEBgIACBIE+wIIMwoQCggEBgIACJwIABIE+wIJMgosCgQE
BgIBEgT+AgRJGh4gT3V0cHV0IG9ubHkuIFRoZSBGQVEgYW5zd2VyLgoKDQoFBAYCAQYSBP4C
BA0KDQoFBAYCAQESBP4CDhgKDQoFBAYCAQMSBP4CGxwKDQoFBAYCAQgSBP4CHUgKEAoIBAYC
AQicCAASBP4CHkcKOAoEBAYCAhIGgQMEggM0GiggT3V0cHV0IG9ubHkuIERpYWxvZ2Zsb3cg
YXNzaXN0IGFuc3dlci4KCg0KBQQGAgIGEgSBAwQaCg0KBQQGAgIBEgSBAxszCg0KBQQGAgID
EgSBAzY3Cg0KBQQGAgIIEgSCAwgzChAKCAQGAgIInAgAEgSCAwkyCjgKBAQGAgMSBoUDBIYD
NBooIE91dHB1dCBvbmx5LiBUaGUgZ2VuZXJhdG9yIHN1Z2dlc3Rpb24uCgoNCgUEBgIDBhIE
hQMEFwoNCgUEBgIDARIEhQMYLAoNCgUEBgIDAxIEhQMvMAoNCgUEBgIDCBIEhgMIMwoQCggE
BgIDCJwIABIEhgMJMgo4CgQEBgIEEgaJAwSKAzQaKCBPdXRwdXQgb25seS4gVGhlIGNvbXBh
bmlvbiBzdWdnZXN0aW9uLgoKDQoFBAYCBAYSBIkDBBcKDQoFBAYCBAESBIkDGCwKDQoFBAYC
BAMSBIkDLzAKDQoFBAYCBAgSBIoDCDMKEAoIBAYCBAicCAASBIoDCTIKQQoEBAYCBRIGjQME
jwM0GjEgT3V0cHV0IG9ubHkuIFRoZSByZWFjdGl2ZSBjb21wYW5pb24gc3VnZ2VzdGlvbi4K
Cg0KBQQGAgUGEgSNAwRGCg0KBQQGAgUBEgSOAwglCg0KBQQGAgUDEgSOAygqCg0KBQQGAgUI
EgSPAwgzChAKCAQGAgUInAgAEgSPAwkyYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord ===
    # Fields for AnswerRecord
    # Field: name Type: 9 ()
    # Field: answer_feedback Type: 11 (.google.cloud.dialogflow.v2.AnswerFeedback)
    # Field: agent_assistant_record Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantRecord)

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsRequest ===
    # Fields for ListAnswerRecordsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsResponse ===
    # Fields for ListAnswerRecordsResponse
    # Field: answer_records Type: 11 (.google.cloud.dialogflow.v2.AnswerRecord)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::UpdateAnswerRecordRequest ===
    # Fields for UpdateAnswerRecordRequest
    # Field: answer_record Type: 11 (.google.cloud.dialogflow.v2.AnswerRecord)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerFeedback ===
    # Fields for AnswerFeedback
    # Field: correctness_level Type: 14 (.google.cloud.dialogflow.v2.AnswerFeedback.CorrectnessLevel)
    # Field: agent_assistant_detail_feedback Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantFeedback)
    # Field: clicked Type: 8 ()
    # Field: click_time Type: 11 (.google.protobuf.Timestamp)
    # Field: displayed Type: 8 ()
    # Field: display_time Type: 11 (.google.protobuf.Timestamp)

# Enum: AnswerFeedback::CorrectnessLevel
our $AnswerFeedback_CORRECTNESS_LEVEL_UNSPECIFIED = 0;
our $AnswerFeedback_NOT_CORRECT = 1;
our $AnswerFeedback_PARTIALLY_CORRECT = 2;
our $AnswerFeedback_FULLY_CORRECT = 3;

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback ===
    # Fields for AgentAssistantFeedback
    # Field: answer_relevance Type: 14 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.AnswerRelevance)
    # Field: document_correctness Type: 14 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.DocumentCorrectness)
    # Field: document_efficiency Type: 14 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.DocumentEfficiency)
    # Field: summarization_feedback Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.SummarizationFeedback)
    # Field: knowledge_search_feedback Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.KnowledgeSearchFeedback)
    # Field: knowledge_assist_feedback Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.KnowledgeAssistFeedback)
    # Field: companion_feedback Type: 11 (.google.cloud.dialogflow.v2.AgentAssistantFeedback.CompanionFeedback)

# Enum: AgentAssistantFeedback::AnswerRelevance
our $AgentAssistantFeedback_ANSWER_RELEVANCE_UNSPECIFIED = 0;
our $AgentAssistantFeedback_IRRELEVANT = 1;
our $AgentAssistantFeedback_RELEVANT = 2;

# Enum: AgentAssistantFeedback::DocumentCorrectness
our $AgentAssistantFeedback_DOCUMENT_CORRECTNESS_UNSPECIFIED = 0;
our $AgentAssistantFeedback_INCORRECT = 1;
our $AgentAssistantFeedback_CORRECT = 2;

# Enum: AgentAssistantFeedback::DocumentEfficiency
our $AgentAssistantFeedback_DOCUMENT_EFFICIENCY_UNSPECIFIED = 0;
our $AgentAssistantFeedback_INEFFICIENT = 1;
our $AgentAssistantFeedback_EFFICIENT = 2;

# === Message: Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantRecord ===
    # Fields for AgentAssistantRecord
    # Field: article_suggestion_answer Type: 11 (.google.cloud.dialogflow.v2.ArticleAnswer)
    # Field: faq_answer Type: 11 (.google.cloud.dialogflow.v2.FaqAnswer)
    # Field: dialogflow_assist_answer Type: 11 (.google.cloud.dialogflow.v2.DialogflowAssistAnswer)
    # Field: generator_suggestion Type: 11 (.google.cloud.dialogflow.v2.GeneratorSuggestion)
    # Field: companion_suggestion Type: 11 (.google.cloud.dialogflow.v2.CompanionSuggestion)
    # Field: reactive_companion_suggestion Type: 11 (.google.cloud.dialogflow.v2.StreamingReactiveCompanionSuggestionsResponse.ReactiveModeResponse)

# === Service Client: Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecordsClient ===
package Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecordsClient;

=pod

=head2 Service Client: Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecordsClient

Client stub representing the remote C<AnswerRecords> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list_answer_records {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.AnswerRecords',
        method         => 'ListAnswerRecords',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsResponse',
    });
}

sub update_answer_record {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Dialogflow::V2::AnswerRecord::UpdateAnswerRecordRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.dialogflow.v2.AnswerRecords',
        method         => 'UpdateAnswerRecord',
        request        => $req,
        response_class => 'Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::AnswerRecord - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/answer_record.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::AnswerRecord;

    my $msg = Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord->new({
        name => $name,
        answer_feedback => $answer_feedback,
        agent_assistant_record => $agent_assistant_record,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/answer_record.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord

Answer records are records to manage answer history and feedbacks for
Dialogflow.

Currently, answer record includes:

- human agent assistant article suggestion
- human agent assistant faq article

It doesn't include:

- `DetectIntent` intent matching
- `DetectIntent` knowledge

Answer records are not related to the conversation history in the
Dialogflow Console. A Record is generated even when the end-user disables
conversation history in the console. Records are created when there's a human
agent assistant suggestion generated.

A typical workflow for customers provide feedback to an answer is:

1. For human agent assistant, customers get suggestion via ListSuggestions
   API. Together with the answers,
   [AnswerRecord.name][google.cloud.dialogflow.v2.AnswerRecord.name] are
   returned to the customers.
2. The customer uses the
[AnswerRecord.name][google.cloud.dialogflow.v2.AnswerRecord.name] to call the
   [AnswerRecords.UpdateAnswerRecord][google.cloud.dialogflow.v2.AnswerRecords.UpdateAnswerRecord]
   method to send feedback about a specific answer that they believe is
   wrong.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of this answer record.
Format: `projects/<Project ID>/locations/<Location
ID>/answerRecords/<Answer Record ID>`.

=item * C<< $msg->answer_feedback() >> / C<< $msg->answer_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerFeedback>)

Required. The AnswerFeedback for this record. You can set this with
[AnswerRecords.UpdateAnswerRecord][google.cloud.dialogflow.v2.AnswerRecords.UpdateAnswerRecord]
in order to give us feedback about this answer.

=item * C<< $msg->agent_assistant_record() >> / C<< $msg->agent_assistant_record($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantRecord>)

Output only. The record for human agent assistant.

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsRequest

Request message for
[AnswerRecords.ListAnswerRecords][google.cloud.dialogflow.v2.AnswerRecords.ListAnswerRecords].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project to list all answer records for in reverse
chronological order. Format: `projects/<Project ID>/locations/<Location
ID>`.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filters to restrict results to specific answer records. The
expression has the following syntax:

    <field> <operator> <value> [AND <field> <operator> <value>] ...

The following fields and operators are supported:
* conversation_id with equals(=) operator

Examples:

* `conversation_id=bar` matches answer records in the
  `projects/foo/locations/global/conversations/bar` conversation
  (assuming the parent is `projects/foo/locations/global`).

For more information about filtering, see
[API Filtering](https://aip.dev/160).

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of records to return in a single page.
The server may return fewer records than this. If unspecified, we use 10.
The maximum is 100.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. The
[ListAnswerRecordsResponse.next_page_token][google.cloud.dialogflow.v2.ListAnswerRecordsResponse.next_page_token]
value returned from a previous list request used to continue listing on
the next page.

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::ListAnswerRecordsResponse

Response message for
[AnswerRecords.ListAnswerRecords][google.cloud.dialogflow.v2.AnswerRecords.ListAnswerRecords].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->answer_records() >> / C<< $msg->answer_records($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord>)

The list of answer records.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve next page of results. Or empty if there are no more
results.
Pass this value in the
[ListAnswerRecordsRequest.page_token][google.cloud.dialogflow.v2.ListAnswerRecordsRequest.page_token]
field in the subsequent call to `ListAnswerRecords` method to retrieve the
next page of results.

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::UpdateAnswerRecordRequest

Request message for
[AnswerRecords.UpdateAnswerRecord][google.cloud.dialogflow.v2.AnswerRecords.UpdateAnswerRecord].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->answer_record() >> / C<< $msg->answer_record($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerRecord>)

Required. Answer record to update.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. The mask to control which fields get updated.

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::AnswerFeedback

Represents feedback the customer has about the quality & correctness of a
certain answer in a conversation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->correctness_level() >> / C<< $msg->correctness_level($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::AnswerFeedback::CorrectnessLevel>)

The correctness level of the specific answer.

=item * C<< $msg->agent_assistant_detail_feedback() >> / C<< $msg->agent_assistant_detail_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback>)

Detail feedback of agent assist suggestions.

=item * C<< $msg->clicked() >> / C<< $msg->clicked($value) >>

Type: C<Bool>

Indicates whether the answer/item was clicked by the human agent
or not. Default to false.
For knowledge search and knowledge assist, the answer record is considered
to be clicked if the answer was copied or any URI was clicked.

=item * C<< $msg->click_time() >> / C<< $msg->click_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the answer/item was clicked.

=item * C<< $msg->displayed() >> / C<< $msg->displayed($value) >>

Type: C<Bool>

Indicates whether the answer/item was displayed to the human
agent in the agent desktop UI. Default to false.

=item * C<< $msg->display_time() >> / C<< $msg->display_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time when the answer/item was displayed.

=back

=head3 Enum: AnswerFeedback::CorrectnessLevel

=over 4

=item * C<CORRECTNESS_LEVEL_UNSPECIFIED> => C<0>

=item * C<NOT_CORRECT> => C<1>

=item * C<PARTIALLY_CORRECT> => C<2>

=item * C<FULLY_CORRECT> => C<3>

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback

Detail feedback of Agent Assist result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->answer_relevance() >> / C<< $msg->answer_relevance($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::AgentAssistantFeedback::AnswerRelevance>)

Optional. Whether or not the suggested answer is relevant.

For example:

* Query: "Can I change my mailing address?"
* Suggested document says: "Items must be returned/exchanged within 60
  days of the purchase date."
* [answer_relevance][google.cloud.dialogflow.v2.AgentAssistantFeedback.answer_relevance]: [AnswerRelevance.IRRELEVANT][google.cloud.dialogflow.v2.AgentAssistantFeedback.AnswerRelevance.IRRELEVANT]

=item * C<< $msg->document_correctness() >> / C<< $msg->document_correctness($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::AgentAssistantFeedback::DocumentCorrectness>)

Optional. Whether or not the information in the document is correct.

For example:

* Query: "Can I return the package in 2 days once received?"
* Suggested document says: "Items must be returned/exchanged within 60
  days of the purchase date."
* Ground truth: "No return or exchange is allowed."
* [document_correctness][google.cloud.dialogflow.v2.AgentAssistantFeedback.document_correctness]: [INCORRECT][google.cloud.dialogflow.v2.AgentAssistantFeedback.DocumentCorrectness.INCORRECT]

=item * C<< $msg->document_efficiency() >> / C<< $msg->document_efficiency($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::AgentAssistantFeedback::DocumentEfficiency>)

Optional. Whether or not the suggested document is efficient. For example,
if the document is poorly written, hard to understand, hard to use or
too long to find useful information,
[document_efficiency][google.cloud.dialogflow.v2.AgentAssistantFeedback.document_efficiency]
is
[DocumentEfficiency.INEFFICIENT][google.cloud.dialogflow.v2.AgentAssistantFeedback.DocumentEfficiency.INEFFICIENT].

=item * C<< $msg->summarization_feedback() >> / C<< $msg->summarization_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback::SummarizationFeedback>)

Optional. Feedback for conversation summarization.

=item * C<< $msg->knowledge_search_feedback() >> / C<< $msg->knowledge_search_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback::KnowledgeSearchFeedback>)

Optional. Feedback for knowledge search.

=item * C<< $msg->knowledge_assist_feedback() >> / C<< $msg->knowledge_assist_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback::KnowledgeAssistFeedback>)

Optional. Feedback for knowledge assist.

=item * C<< $msg->companion_feedback() >> / C<< $msg->companion_feedback($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantFeedback::CompanionFeedback>)

Optional. Feedback for companion agent.

=back

=head3 Enum: AgentAssistantFeedback::AnswerRelevance

=over 4

=item * C<ANSWER_RELEVANCE_UNSPECIFIED> => C<0>

=item * C<IRRELEVANT> => C<1>

=item * C<RELEVANT> => C<2>

=back

=head3 Enum: AgentAssistantFeedback::DocumentCorrectness

=over 4

=item * C<DOCUMENT_CORRECTNESS_UNSPECIFIED> => C<0>

=item * C<INCORRECT> => C<1>

=item * C<CORRECT> => C<2>

=back

=head3 Enum: AgentAssistantFeedback::DocumentEfficiency

=over 4

=item * C<DOCUMENT_EFFICIENCY_UNSPECIFIED> => C<0>

=item * C<INEFFICIENT> => C<1>

=item * C<EFFICIENT> => C<2>

=back

=head2 Google::Cloud::Dialogflow::V2::AnswerRecord::AgentAssistantRecord

Represents a record of a human agent assist answer.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->article_suggestion_answer() >> / C<< $msg->article_suggestion_answer($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::ArticleAnswer>)

Output only. The article suggestion answer.

=item * C<< $msg->faq_answer() >> / C<< $msg->faq_answer($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::FaqAnswer>)

Output only. The FAQ answer.

=item * C<< $msg->dialogflow_assist_answer() >> / C<< $msg->dialogflow_assist_answer($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::DialogflowAssistAnswer>)

Output only. Dialogflow assist answer.

=item * C<< $msg->generator_suggestion() >> / C<< $msg->generator_suggestion($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Generator::GeneratorSuggestion>)

Output only. The generator suggestion.

=item * C<< $msg->companion_suggestion() >> / C<< $msg->companion_suggestion($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::CompanionSuggestion>)

Output only. The companion suggestion.

=item * C<< $msg->reactive_companion_suggestion() >> / C<< $msg->reactive_companion_suggestion($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::Participant::StreamingReactiveCompanionSuggestionsResponse::ReactiveModeResponse>)

Output only. The reactive companion suggestion.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::AnswerRecord::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
