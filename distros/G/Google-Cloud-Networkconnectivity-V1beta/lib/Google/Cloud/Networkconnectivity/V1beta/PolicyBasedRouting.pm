package Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting;

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
    eval { require Google::Cloud::Networkconnectivity::V1beta::Common };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvbmV0d29ya2Nvbm5lY3Rpdml0eS92MWJldGEvcG9saWN5X2Jhc2Vk
X3JvdXRpbmcucHJvdG8SJ2dvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0
YRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJv
dG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aNGdvb2dsZS9jbG91ZC9uZXR3b3JrY29ubmVjdGl2aXR5L3YxYmV0YS9jb21t
b24ucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i
qhEKEFBvbGljeUJhc2VkUm91dGUSeAoPdmlydHVhbF9tYWNoaW5lGBIgASgLMkguZ29vZ2xl
LmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRhLlBvbGljeUJhc2VkUm91dGUuVmly
dHVhbE1hY2hpbmVCA+BBAUgAUg52aXJ0dWFsTWFjaGluZRKQAQoXaW50ZXJjb25uZWN0X2F0
dGFjaG1lbnQYCSABKAsyUC5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJl
dGEuUG9saWN5QmFzZWRSb3V0ZS5JbnRlcmNvbm5lY3RBdHRhY2htZW50QgPgQQFIAFIWaW50
ZXJjb25uZWN0QXR0YWNobWVudBIsCg9uZXh0X2hvcF9pbGJfaXAYDCABKAlCA+BBAUgBUgxu
ZXh0SG9wSWxiSXASfwoVbmV4dF9ob3Bfb3RoZXJfcm91dGVzGBUgASgOMkUuZ29vZ2xlLmNs
b3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRhLlBvbGljeUJhc2VkUm91dGUuT3RoZXJS
b3V0ZXNCA+BBAUgBUhJuZXh0SG9wT3RoZXJSb3V0ZXMSGgoEbmFtZRgBIAEoCUIG4EEF4EEI
UgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEl0KBmxhYmVscxgEIAMoCzJFLmdvb2ds
ZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YS5Qb2xpY3lCYXNlZFJvdXRlLkxh
YmVsc0VudHJ5UgZsYWJlbHMSJQoLZGVzY3JpcHRpb24YBSABKAlCA+BBAVILZGVzY3JpcHRp
b24SQAoHbmV0d29yaxgGIAEoCUIm4EEC+kEgCh5jb21wdXRlLmdvb2dsZWFwaXMuY29tL05l
dHdvcmtSB25ldHdvcmsSXQoGZmlsdGVyGAogASgLMkAuZ29vZ2xlLmNsb3VkLm5ldHdvcmtj
b25uZWN0aXZpdHkudjFiZXRhLlBvbGljeUJhc2VkUm91dGUuRmlsdGVyQgPgQQJSBmZpbHRl
chIfCghwcmlvcml0eRgLIAEoBUID4EEBUghwcmlvcml0eRJjCgh3YXJuaW5ncxgOIAMoCzJC
Lmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YS5Qb2xpY3lCYXNlZFJv
dXRlLldhcm5pbmdzQgPgQQNSCHdhcm5pbmdzEiAKCXNlbGZfbGluaxgPIAEoCUID4EEDUghz
ZWxmTGluaxIXCgRraW5kGBAgASgJQgPgQQNSBGtpbmQaKQoOVmlydHVhbE1hY2hpbmUSFwoE
dGFncxgBIAMoCUID4EEBUgR0YWdzGjUKFkludGVyY29ubmVjdEF0dGFjaG1lbnQSGwoGcmVn
aW9uGAEgASgJQgPgQQFSBnJlZ2lvbhrAAgoGRmlsdGVyEiQKC2lwX3Byb3RvY29sGAEgASgJ
QgPgQQFSCmlwUHJvdG9jb2wSIAoJc3JjX3JhbmdlGAIgASgJQgPgQQFSCHNyY1JhbmdlEiIK
CmRlc3RfcmFuZ2UYAyABKAlCA+BBAVIJZGVzdFJhbmdlEoABChBwcm90b2NvbF92ZXJzaW9u
GAYgASgOMlAuZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRhLlBvbGlj
eUJhc2VkUm91dGUuRmlsdGVyLlByb3RvY29sVmVyc2lvbkID4EECUg9wcm90b2NvbFZlcnNp
b24iRwoPUHJvdG9jb2xWZXJzaW9uEiAKHFBST1RPQ09MX1ZFUlNJT05fVU5TUEVDSUZJRUQQ
ABIICgRJUFY0EAESCAoESVBWNhACGpEDCghXYXJuaW5ncxJgCgRjb2RlGAEgASgOMkcuZ29v
Z2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRhLlBvbGljeUJhc2VkUm91dGUu
V2FybmluZ3MuQ29kZUID4EEDUgRjb2RlEmUKBGRhdGEYAiADKAsyTC5nb29nbGUuY2xvdWQu
bmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEuUG9saWN5QmFzZWRSb3V0ZS5XYXJuaW5ncy5E
YXRhRW50cnlCA+BBA1IEZGF0YRIsCg93YXJuaW5nX21lc3NhZ2UYAyABKAlCA+BBA1IOd2Fy
bmluZ01lc3NhZ2UaNwoJRGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIg
ASgJUgV2YWx1ZToCOAEiVQoEQ29kZRIXChNXQVJOSU5HX1VOU1BFQ0lGSUVEEAASFwoTUkVT
T1VSQ0VfTk9UX0FDVElWRRABEhsKF1JFU09VUkNFX0JFSU5HX01PRElGSUVEEAIaOQoLTGFi
ZWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJA
CgtPdGhlclJvdXRlcxIcChhPVEhFUl9ST1VURVNfVU5TUEVDSUZJRUQQABITCg9ERUZBVUxU
X1JPVVRJTkcQATqFAepBgQEKM25ldHdvcmtjb25uZWN0aXZpdHkuZ29vZ2xlYXBpcy5jb20v
UG9saWN5QmFzZWRSb3V0ZRJKcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy9nbG9iYWwv
UG9saWN5QmFzZWRSb3V0ZXMve3BvbGljeV9iYXNlZF9yb3V0ZX1CCAoGdGFyZ2V0QgoKCG5l
eHRfaG9wItABChxMaXN0UG9saWN5QmFzZWRSb3V0ZXNSZXF1ZXN0EkEKBnBhcmVudBgBIAEo
CUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25SBnBhcmVudBIb
CglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VU
b2tlbhIWCgZmaWx0ZXIYBCABKAlSBmZpbHRlchIZCghvcmRlcl9ieRgFIAEoCVIHb3JkZXJC
eSLUAQodTGlzdFBvbGljeUJhc2VkUm91dGVzUmVzcG9uc2USaQoTcG9saWN5X2Jhc2VkX3Jv
dXRlcxgBIAMoCzI5Lmdvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YS5Q
b2xpY3lCYXNlZFJvdXRlUhFwb2xpY3lCYXNlZFJvdXRlcxImCg9uZXh0X3BhZ2VfdG9rZW4Y
AiABKAlSDW5leHRQYWdlVG9rZW4SIAoLdW5yZWFjaGFibGUYAyADKAlSC3VucmVhY2hhYmxl
Im0KGkdldFBvbGljeUJhc2VkUm91dGVSZXF1ZXN0Ek8KBG5hbWUYASABKAlCO+BBAvpBNQoz
bmV0d29ya2Nvbm5lY3Rpdml0eS5nb29nbGVhcGlzLmNvbS9Qb2xpY3lCYXNlZFJvdXRlUgRu
YW1lIqwCCh1DcmVhdGVQb2xpY3lCYXNlZFJvdXRlUmVxdWVzdBJBCgZwYXJlbnQYASABKAlC
KeBBAvpBIwohbG9jYXRpb25zLmdvb2dsZWFwaXMuY29tL0xvY2F0aW9uUgZwYXJlbnQSNgoV
cG9saWN5X2Jhc2VkX3JvdXRlX2lkGAIgASgJQgPgQQJSEnBvbGljeUJhc2VkUm91dGVJZBJs
ChJwb2xpY3lfYmFzZWRfcm91dGUYAyABKAsyOS5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5l
Y3Rpdml0eS52MWJldGEuUG9saWN5QmFzZWRSb3V0ZUID4EECUhBwb2xpY3lCYXNlZFJvdXRl
EiIKCnJlcXVlc3RfaWQYBCABKAlCA+BBAVIJcmVxdWVzdElkIpQBCh1EZWxldGVQb2xpY3lC
YXNlZFJvdXRlUmVxdWVzdBJPCgRuYW1lGAEgASgJQjvgQQL6QTUKM25ldHdvcmtjb25uZWN0
aXZpdHkuZ29vZ2xlYXBpcy5jb20vUG9saWN5QmFzZWRSb3V0ZVIEbmFtZRIiCgpyZXF1ZXN0
X2lkGAIgASgJQgPgQQFSCXJlcXVlc3RJZDKLCQoZUG9saWN5QmFzZWRSb3V0aW5nU2Vydmlj
ZRL3AQoVTGlzdFBvbGljeUJhc2VkUm91dGVzEkUuZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25u
ZWN0aXZpdHkudjFiZXRhLkxpc3RQb2xpY3lCYXNlZFJvdXRlc1JlcXVlc3QaRi5nb29nbGUu
Y2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEuTGlzdFBvbGljeUJhc2VkUm91dGVz
UmVzcG9uc2UiT4LT5JMCQBI+L3YxYmV0YS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25z
L2dsb2JhbH0vcG9saWN5QmFzZWRSb3V0ZXPaQQZwYXJlbnQS5AEKE0dldFBvbGljeUJhc2Vk
Um91dGUSQy5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEuR2V0UG9s
aWN5QmFzZWRSb3V0ZVJlcXVlc3QaOS5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0
eS52MWJldGEuUG9saWN5QmFzZWRSb3V0ZSJNgtPkkwJAEj4vdjFiZXRhL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zL2dsb2JhbC9wb2xpY3lCYXNlZFJvdXRlcy8qfdpBBG5hbWUStgIK
FkNyZWF0ZVBvbGljeUJhc2VkUm91dGUSRi5nb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rp
dml0eS52MWJldGEuQ3JlYXRlUG9saWN5QmFzZWRSb3V0ZVJlcXVlc3QaHS5nb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uIrQBgtPkkwJUIj4vdjFiZXRhL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvZ2xvYmFsfS9wb2xpY3lCYXNlZFJvdXRlczoScG9saWN5X2Jhc2VkX3Jv
dXRl2kEvcGFyZW50LHBvbGljeV9iYXNlZF9yb3V0ZSxwb2xpY3lfYmFzZWRfcm91dGVfaWTK
QSUKEFBvbGljeUJhc2VkUm91dGUSEU9wZXJhdGlvbk1ldGFkYXRhEvsBChZEZWxldGVQb2xp
Y3lCYXNlZFJvdXRlEkYuZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRh
LkRlbGV0ZVBvbGljeUJhc2VkUm91dGVSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9w
ZXJhdGlvbiJ6gtPkkwJAKj4vdjFiZXRhL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zL2ds
b2JhbC9wb2xpY3lCYXNlZFJvdXRlcy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5F
bXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEaVspBIm5ldHdvcmtjb25uZWN0aXZpdHkuZ29vZ2xl
YXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRm
b3JtQqgCCitjb20uZ29vZ2xlLmNsb3VkLm5ldHdvcmtjb25uZWN0aXZpdHkudjFiZXRhQhdQ
b2xpY3lCYXNlZFJvdXRpbmdQcm90b1ABWl1jbG91ZC5nb29nbGUuY29tL2dvL25ldHdvcmtj
b25uZWN0aXZpdHkvYXBpdjFiZXRhL25ldHdvcmtjb25uZWN0aXZpdHlwYjtuZXR3b3JrY29u
bmVjdGl2aXR5cGKqAidHb29nbGUuQ2xvdWQuTmV0d29ya0Nvbm5lY3Rpdml0eS5WMUJldGHK
AidHb29nbGVcQ2xvdWRcTmV0d29ya0Nvbm5lY3Rpdml0eVxWMWJldGHqAipHb29nbGU6OkNs
b3VkOjpOZXR3b3JrQ29ubmVjdGl2aXR5OjpWMWJldGFK6XAKBxIFDgCGAwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADAKCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgA+CgkKAgMFEgMXAC0KCQoCAwYS
AxgAJQoJCgIDBxIDGQApCggKAQgSAxsARAoJCgIIJRIDGwBECggKAQgSAxwAdAoJCgIICxID
HAB0CggKAQgSAx0AIgoJCgIIChIDHQAiCggKAQgSAx4AOAoJCgIICBIDHgA4CggKAQgSAx8A
RAoJCgIIARIDHwBECggKAQgSAyAARAoJCgIIKRIDIABECggKAQgSAyEAQwoJCgIILRIDIQBD
Cp0BCgIGABIEJQBXARqQASBQb2xpY3ktQmFzZWQgUm91dGluZyBhbGxvd3MgR0NQIGN1c3Rv
bWVycyB0byBzcGVjaWZ5IGZsZXhpYmlsZSByb3V0aW5nCiBwb2xpY2llcyBmb3IgTGF5ZXIg
NCB0cmFmZmljIHRyYXZlcnNpbmcgdGhyb3VnaCB0aGUgY29ubmVjdGVkIHNlcnZpY2UuCgoK
CgMGAAESAyUIIQoKCgMGAAMSAyYCSgoMCgUGAAOZCBIDJgJKCgsKAwYAAxIEJwIoNwoNCgUG
AAOaCBIEJwIoNwpKCgQGAAIAEgQrAjEDGjwgTGlzdHMgcG9saWN5LWJhc2VkIHJvdXRlcyBp
biBhIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKDAoFBgACAAESAysGGwoMCgUGAAIA
AhIDKxw4CgwKBQYAAgADEgMsDywKDQoFBgACAAQSBC0ELwYKEQoJBgACAASwyrwiEgQtBC8G
CgwKBQYAAgAEEgMwBDQKDwoIBgACAASbCAASAzAENAo8CgQGAAIBEgQ0AjoDGi4gR2V0cyBk
ZXRhaWxzIG9mIGEgc2luZ2xlIHBvbGljeS1iYXNlZCByb3V0ZS4KCgwKBQYAAgEBEgM0BhkK
DAoFBgACAQISAzQaNAoMCgUGAAIBAxIDNQ8fCg0KBQYAAgEEEgQ2BDgGChEKCQYAAgEEsMq8
IhIENgQ4BgoMCgUGAAIBBBIDOQQyCg8KCAYAAgEEmwgAEgM5BDIKUQoEBgACAhIEPQJJAxpD
IENyZWF0ZXMgYSBuZXcgcG9saWN5LWJhc2VkIHJvdXRlIGluIGEgZ2l2ZW4gcHJvamVjdCBh
bmQgbG9jYXRpb24uCgoMCgUGAAICARIDPQYcCgwKBQYAAgICEgM9HToKDAoFBgACAgMSAz4P
KwoNCgUGAAICBBIEPwRCBgoRCgkGAAICBLDKvCISBD8EQgYKDQoFBgACAgQSBEMERDoKEAoI
BgACAgSbCAASBEMERDoKDQoFBgACAgQSBEUESAYKDwoHBgACAgSZCBIERQRIBgo0CgQGAAID
EgRMAlYDGiYgRGVsZXRlcyBhIHNpbmdsZSBwb2xpY3ktYmFzZWQgcm91dGUuCgoMCgUGAAID
ARIDTAYcCgwKBQYAAgMCEgNMHToKDAoFBgACAwMSA00PKwoNCgUGAAIDBBIETgRQBgoRCgkG
AAIDBLDKvCISBE4EUAYKDAoFBgACAwQSA1EEMgoPCggGAAIDBJsIABIDUQQyCg0KBQYAAgME
EgRSBFUGCg8KBwYAAgMEmQgSBFIEVQYKhwIKAgQAEgVdAIsCARr5ASBQb2xpY3ktYmFzZWQg
cm91dGVzIHJvdXRlIEw0IG5ldHdvcmsgdHJhZmZpYyBiYXNlZCBvbiBub3QganVzdCBkZXN0
aW5hdGlvbiBJUAogYWRkcmVzcywgYnV0IGFsc28gc291cmNlIElQIGFkZHJlc3MsIHByb3Rv
Y29sLCBhbmQgbW9yZS4gSWYgYSBwb2xpY3ktYmFzZWQKIHJvdXRlIGNvbmZsaWN0cyB3aXRo
IG90aGVyIHR5cGVzIG9mIHJvdXRlcywgdGhlIHBvbGljeS1iYXNlZCByb3V0ZSBhbHdheXMK
IHRha2VzIHByZWNlZGVuY2UuCgoKCgMEAAESA10IGAoLCgMEAAcSBF4CYQQKDQoFBAAHnQgS
BF4CYQQKRQoEBAADABIEZAJoAxo3IFZNIGluc3RhbmNlcyB0aGF0IHRoaXMgcG9saWN5LWJh
c2VkIHJvdXRlIGFwcGxpZXMgdG8uCgoMCgUEAAMAARIDZAoYCqUBCgYEAAMAAgASA2cERhqV
ASBPcHRpb25hbC4gQSBsaXN0IG9mIFZNIGluc3RhbmNlIHRhZ3MgdGhhdCB0aGlzIHBvbGlj
eS1iYXNlZCByb3V0ZSBhcHBsaWVzCiB0by4gVk0gaW5zdGFuY2VzIHRoYXQgaGF2ZSBBTlkg
b2YgdGFncyBzcGVjaWZpZWQgaGVyZSBpbnN0YWxscyB0aGlzIFBCUi4KCg4KBwQAAwACAAQS
A2cEDAoOCgcEAAMAAgAFEgNnDRMKDgoHBAADAAIAARIDZxQYCg4KBwQAAwACAAMSA2cbHAoO
CgcEAAMAAgAIEgNnHUUKEQoKBAADAAIACJwIABIDZx5ECkIKBAQAAwESBGsCbwMaNCBJbnRl
cmNvbm5lY3RBdHRhY2htZW50IHRoYXQgdGhpcyByb3V0ZSBhcHBsaWVzIHRvLgoKDAoFBAAD
AQESA2sKIAqhAQoGBAADAQIAEgNuBD8akQEgT3B0aW9uYWwuIENsb3VkIHJlZ2lvbiB0byBp
bnN0YWxsIHRoaXMgcG9saWN5LWJhc2VkIHJvdXRlIG9uIGludGVyY29ubmVjdAogYXR0YWNo
bWVudC4gVXNlIGBhbGxgIHRvIGluc3RhbGwgaXQgb24gYWxsIGludGVyY29ubmVjdCBhdHRh
Y2htZW50cy4KCg4KBwQAAwECAAUSA24ECgoOCgcEAAMBAgABEgNuCxEKDgoHBAADAQIAAxID
bhQVCg4KBwQAAwECAAgSA24WPgoRCgoEAAMBAgAInAgAEgNuFz0KKwoEBAADAhIFcgKRAQMa
HCBGaWx0ZXIgbWF0Y2hlcyBMNCB0cmFmZmljLgoKDAoFBAADAgESA3IKEAowCgYEAAMCBAAS
BHQEfQUaICBUaGUgaW50ZXJuZXQgcHJvdG9jb2wgdmVyc2lvbi4KCg4KBwQAAwIEAAESA3QJ
GAohCggEAAMCBAACABIDdgYnGhAgRGVmYXVsdCB2YWx1ZS4KChAKCQQAAwIEAAIAARIDdgYi
ChAKCQQAAwIEAAIAAhIDdiUmCkEKCAQAAwIEAAIBEgN5Bg8aMCBUaGUgUEJSIGlzIGZvciBJ
UHY0IGludGVybmV0IHByb3RvY29sIHRyYWZmaWMuCgoQCgkEAAMCBAACAQESA3kGCgoQCgkE
AAMCBAACAQISA3kNDgpBCggEAAMCBAACAhIDfAYPGjAgVGhlIFBCUiBpcyBmb3IgSVB2NiBp
bnRlcm5ldCBwcm90b2NvbCB0cmFmZmljLgoKEAoJBAADAgQAAgIBEgN8BgoKEAoJBAADAgQA
AgICEgN8DQ4KkgEKBgQAAwICABIEgQEERBqBASBPcHRpb25hbC4gVGhlIElQIHByb3RvY29s
IHRoYXQgdGhpcyBwb2xpY3ktYmFzZWQgcm91dGUgYXBwbGllcyB0by4gVmFsaWQKIHZhbHVl
cyBhcmUgJ1RDUCcsICdVRFAnLCBhbmQgJ0FMTCcuIERlZmF1bHQgaXMgJ0FMTCcuCgoPCgcE
AAMCAgAFEgSBAQQKCg8KBwQAAwICAAESBIEBCxYKDwoHBAADAgIAAxIEgQEZGgoPCgcEAAMC
AgAIEgSBARtDChIKCgQAAwICAAicCAASBIEBHEIKygEKBgQAAwICARIEhgEEQhq5ASBPcHRp
b25hbC4gVGhlIHNvdXJjZSBJUCByYW5nZSBvZiBvdXRnb2luZyBwYWNrZXRzIHRoYXQgdGhp
cyBwb2xpY3ktYmFzZWQKIHJvdXRlIGFwcGxpZXMgdG8uIERlZmF1bHQgaXMgIjAuMC4wLjAv
MCIgaWYgcHJvdG9jb2wgdmVyc2lvbiBpcyBJUHY0IGFuZAogIjo6LzAiIGlmIHByb3RvY29s
IHZlcnNpb24gaXMgSVB2Ni4KCg8KBwQAAwICAQUSBIYBBAoKDwoHBAADAgIBARIEhgELFAoP
CgcEAAMCAgEDEgSGARcYCg8KBwQAAwICAQgSBIYBGUEKEgoKBAADAgIBCJwIABIEhgEaQArP
AQoGBAADAgICEgSLAQRDGr4BIE9wdGlvbmFsLiBUaGUgZGVzdGluYXRpb24gSVAgcmFuZ2Ug
b2Ygb3V0Z29pbmcgcGFja2V0cyB0aGF0IHRoaXMKIHBvbGljeS1iYXNlZCByb3V0ZSBhcHBs
aWVzIHRvLiBEZWZhdWx0IGlzICIwLjAuMC4wLzAiIGlmIHByb3RvY29sIHZlcnNpb24KIGlz
IElQdjQgYW5kICI6Oi8wIiBpZiBwcm90b2NvbCB2ZXJzaW9uIGlzIElQdjYuCgoPCgcEAAMC
AgIFEgSLAQQKCg8KBwQAAwICAgESBIsBCxUKDwoHBAADAgICAxIEiwEYGQoPCgcEAAMCAgII
EgSLARpCChIKCgQAAwICAgicCAASBIsBG0EKeQoGBAADAgIDEgaPAQSQATEaZyBSZXF1aXJl
ZC4gSW50ZXJuZXQgcHJvdG9jb2wgdmVyc2lvbnMgdGhpcyBwb2xpY3ktYmFzZWQgcm91dGUg
YXBwbGllcyB0by4KIElQVjQgYW5kIElQVjYgaXMgc3VwcG9ydGVkLgoKDwoHBAADAgIDBhIE
jwEEEwoPCgcEAAMCAgMBEgSPARQkCg8KBwQAAwICAwMSBI8BJygKDwoHBAADAgIDCBIEkAEI
MAoSCgoEAAMCAgMInAgAEgSQAQkvCjAKBAQAAwMSBpQBArIBAxogIEluZm9ybWF0aW9uYWwg
d2FybmluZyBtZXNzYWdlLgoKDQoFBAADAwESBJQBChIKXwoGBAADAwQAEgaXAQSjAQUaTSBX
YXJuaW5nIGNvZGUgZm9yIHBvbGljeS1iYXNlZCByb3V0aW5nLiBFeHBlY3QgdG8gYWRkIHZh
bHVlcyBpbiB0aGUKIGZ1dHVyZS4KCg8KBwQAAwMEAAESBJcBCQ0KIgoIBAADAwQAAgASBJkB
Bh4aECBEZWZhdWx0IHZhbHVlLgoKEQoJBAADAwQAAgABEgSZAQYZChEKCQQAAwMEAAIAAhIE
mQEcHQqtAQoIBAADAwQAAgESBJ4BBh4amgEgVGhlIHBvbGljeS1iYXNlZCByb3V0ZSBpcyBu
b3QgYWN0aXZlIGFuZCBmdW5jdGlvbmluZy4gQ29tbW9uIGNhdXNlcyBhcmUKIHRoYXQgdGhl
IGRlcGVuZGVudCBuZXR3b3JrIHdhcyBkZWxldGVkIG9yIHRoZSByZXNvdXJjZSBwcm9qZWN0
IHdhcwogdHVybmVkIG9mZi4KChEKCQQAAwMEAAIBARIEngEGGQoRCgkEAAMDBAACAQISBJ4B
HB0KYgoIBAADAwQAAgISBKIBBiIaUCBUaGUgcG9saWN5LWJhc2VkIHJvdXRlIGlzIGJlaW5n
IG1vZGlmaWVkIChlLmcuIGNyZWF0ZWQvZGVsZXRlZCkgYXQgdGhpcwogdGltZS4KChEKCQQA
AwMEAAICARIEogEGHQoRCgkEAAMDBAACAgISBKIBICEKPQoGBAADAwIAEgSmAQQ+Gi0gT3V0
cHV0IG9ubHkuIEEgd2FybmluZyBjb2RlLCBpZiBhcHBsaWNhYmxlLgoKDwoHBAADAwIABhIE
pgEECAoPCgcEAAMDAgABEgSmAQkNCg8KBwQAAwMCAAMSBKYBEBEKDwoHBAADAwIACBIEpgES
PQoSCgoEAAMDAgAInAgAEgSmARM8CpUDCgYEAAMDAgESBK4BBE0ahAMgT3V0cHV0IG9ubHku
IE1ldGFkYXRhIGFib3V0IHRoaXMgd2FybmluZyBpbiBrZXk6IHZhbHVlIGZvcm1hdC4gVGhl
IGtleQogc2hvdWxkIHByb3ZpZGVzIG1vcmUgZGV0YWlsIG9uIHRoZSB3YXJuaW5nIGJlaW5n
IHJldHVybmVkLiBGb3IgZXhhbXBsZSwKIGZvciB3YXJuaW5ncyB3aGVyZSB0aGVyZSBhcmUg
bm8gcmVzdWx0cyBpbiBhIGxpc3QgcmVxdWVzdCBmb3IgYQogcGFydGljdWxhciB6b25lLCB0
aGlzIGtleSBtaWdodCBiZSBzY29wZSBhbmQgdGhlIGtleSB2YWx1ZSBtaWdodCBiZSB0aGUK
IHpvbmUgbmFtZS4gT3RoZXIgZXhhbXBsZXMgbWlnaHQgYmUgYSBrZXkgaW5kaWNhdGluZyBh
IGRlcHJlY2F0ZWQgcmVzb3VyY2UKIGFuZCBhIHN1Z2dlc3RlZCByZXBsYWNlbWVudC4KCg8K
BwQAAwMCAQYSBK4BBBcKDwoHBAADAwIBARIErgEYHAoPCgcEAAMDAgEDEgSuAR8gCg8KBwQA
AwMCAQgSBK4BIUwKEgoKBAADAwIBCJwIABIErgEiSwpQCgYEAAMDAgISBLEBBEsaQCBPdXRw
dXQgb25seS4gQSBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgd2FybmluZyBj
b2RlLgoKDwoHBAADAwICBRIEsQEECgoPCgcEAAMDAgIBEgSxAQsaCg8KBwQAAwMCAgMSBLEB
HR4KDwoHBAADAwICCBIEsQEfSgoSCgoEAAMDAgIInAgAEgSxASBJCioKBAQABAASBrUBAr4B
AxoaIFRoZSBvdGhlciByb3V0aW5nIGNhc2VzLgoKDQoFBAAEAAESBLUBBxIKIAoGBAAEAAIA
EgS3AQQhGhAgRGVmYXVsdCB2YWx1ZS4KCg8KBwQABAACAAESBLcBBBwKDwoHBAAEAAIAAhIE
twEfIAr1AQoGBAAEAAIBEgS9AQQYGuQBIFVzZSB0aGUgcm91dGVzIGZyb20gdGhlIGRlZmF1
bHQgcm91dGluZyB0YWJsZXMgKHN5c3RlbS1nZW5lcmF0ZWQgcm91dGVzLAogY3VzdG9tIHJv
dXRlcywgcGVlcmluZyByb3V0ZSkgdG8gZGV0ZXJtaW5lIHRoZSBuZXh0IGhvcC4gVGhpcyBl
ZmZlY3RpdmVseQogZXhjbHVkZXMgbWF0Y2hpbmcgcGFja2V0cyBiZWluZyBhcHBsaWVkIG9u
IG90aGVyIFBCUnMgd2l0aCBhIGxvd2VyCiBwcmlvcml0eS4KCg8KBwQABAACAQESBL0BBBMK
DwoHBAAEAAIBAhIEvQEWFwreAQoEBAAIABIGwwECzAEDGs0BIFRhcmdldCBzcGVjaWZpZXMg
bmV0d29yayBlbmRwb2ludHMgdGhhdCB0aGlzIHBvbGljeS1iYXNlZCByb3V0ZSBhcHBsaWVz
IHRvLgogSWYgbm8gdGFyZ2V0IGlzIHNwZWNpZmllZCwgdGhlIFBCUiB3aWxsIGJlIGluc3Rh
bGxlZCBvbiBhbGwgbmV0d29yawogZW5kcG9pbnRzIChlLmcuIFZNcywgVlBOcywgYW5kIElu
dGVyY29ubmVjdHMpIGluIHRoZSBWUEMuCgoNCgUEAAgAARIEwwEIDgpRCgQEAAIAEgbFAQTG
ATEaQSBPcHRpb25hbC4gVk0gaW5zdGFuY2VzIHRoYXQgdGhpcyBwb2xpY3ktYmFzZWQgcm91
dGUgYXBwbGllcyB0by4KCg0KBQQAAgAGEgTFAQQSCg0KBQQAAgABEgTFARMiCg0KBQQAAgAD
EgTFASUnCg0KBQQAAgAIEgTGAQgwChAKCAQAAgAInAgAEgTGAQkvCmIKBAQAAgESBsoBBMsB
MRpSIE9wdGlvbmFsLiBUaGUgaW50ZXJjb25uZWN0IGF0dGFjaG1lbnRzIHRoYXQgdGhpcyBw
b2xpY3ktYmFzZWQgcm91dGUKIGFwcGxpZXMgdG8uCgoNCgUEAAIBBhIEygEEGgoNCgUEAAIB
ARIEygEbMgoNCgUEAAIBAxIEygE1NgoNCgUEAAIBCBIEywEIMAoQCggEAAIBCJwIABIEywEJ
LwoOCgQEAAgBEgbOAQLYAQMKDQoFBAAIAQESBM4BCBAKqgEKBAQAAgISBNIBBEkamwEgT3B0
aW9uYWwuIFRoZSBJUCBhZGRyZXNzIG9mIGEgZ2xvYmFsLWFjY2Vzcy1lbmFibGVkIEw0IElM
QiB0aGF0IGlzIHRoZQogbmV4dCBob3AgZm9yIG1hdGNoaW5nIHBhY2tldHMuIEZvciB0aGlz
IHZlcnNpb24sIG9ubHkgbmV4dEhvcElsYklwIGlzCiBzdXBwb3J0ZWQuCgoNCgUEAAICBRIE
0gEECgoNCgUEAAICARIE0gELGgoNCgUEAAICAxIE0gEdHwoNCgUEAAICCBIE0gEgSAoQCggE
AAICCJwIABIE0gEhRwpqCgQEAAIDEgbWAQTXATEaWiBPcHRpb25hbC4gT3RoZXIgcm91dGVz
IHRoYXQgd2lsbCBiZSByZWZlcmVuY2VkIHRvIGRldGVybWluZSB0aGUgbmV4dCBob3AKIG9m
IHRoZSBwYWNrZXQuCgoNCgUEAAIDBhIE1gEEDwoNCgUEAAIDARIE1gEQJQoNCgUEAAIDAxIE
1gEoKgoNCgUEAAIDCBIE1wEIMAoQCggEAAIDCJwIABIE1wEJLwquAQoEBAACBBIG3AEC3wEE
Gp0BIEltbXV0YWJsZS4gSWRlbnRpZmllci4gQSB1bmlxdWUgbmFtZSBvZiB0aGUgcmVzb3Vy
Y2UgaW4gdGhlIGZvcm0gb2YKIGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9u
cy9nbG9iYWwvUG9saWN5QmFzZWRSb3V0ZXMve3BvbGljeV9iYXNlZF9yb3V0ZV9pZH1gCgoN
CgUEAAIEBRIE3AECCAoNCgUEAAIEARIE3AEJDQoNCgUEAAIEAxIE3AEQEQoPCgUEAAIECBIG
3AES3wEDChAKCAQAAgQInAgAEgTdAQQrChAKCAQAAgQInAgBEgTeAQQsCkwKBAQAAgUSBuIB
AuMBMho8IE91dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIHBvbGljeS1iYXNlZCByb3V0ZSB3
YXMgY3JlYXRlZC4KCg0KBQQAAgUGEgTiAQIbCg0KBQQAAgUBEgTiARwnCg0KBQQAAgUDEgTi
ASorCg0KBQQAAgUIEgTjAQYxChAKCAQAAgUInAgAEgTjAQcwCkwKBAQAAgYSBuYBAucBMho8
IE91dHB1dCBvbmx5LiBUaW1lIHdoZW4gdGhlIHBvbGljeS1iYXNlZCByb3V0ZSB3YXMgdXBk
YXRlZC4KCg0KBQQAAgYGEgTmAQIbCg0KBQQAAgYBEgTmARwnCg0KBQQAAgYDEgTmASorCg0K
BQQAAgYIEgTnAQYxChAKCAQAAgYInAgAEgTnAQcwCiQKBAQAAgcSBOoBAiEaFiBVc2VyLWRl
ZmluZWQgbGFiZWxzLgoKDQoFBAACBwYSBOoBAhUKDQoFBAACBwESBOoBFhwKDQoFBAACBwMS
BOoBHyAKdQoEBAACCBIE7gECQhpnIE9wdGlvbmFsLiBBbiBvcHRpb25hbCBkZXNjcmlwdGlv
biBvZiB0aGlzIHJlc291cmNlLiBQcm92aWRlIHRoaXMgZmllbGQgd2hlbgogeW91IGNyZWF0
ZSB0aGUgcmVzb3VyY2UuCgoNCgUEAAIIBRIE7gECCAoNCgUEAAIIARIE7gEJFAoNCgUEAAII
AxIE7gEXGAoNCgUEAAIICBIE7gEZQQoQCggEAAIICJwIABIE7gEaQAqZAQoEBAACCRIG8gEC
9QEEGogBIFJlcXVpcmVkLiBGdWxseS1xdWFsaWZpZWQgVVJMIG9mIHRoZSBuZXR3b3JrIHRo
YXQgdGhpcyByb3V0ZSBhcHBsaWVzIHRvLAogZm9yIGV4YW1wbGU6IHByb2plY3RzL215LXBy
b2plY3QvZ2xvYmFsL25ldHdvcmtzL215LW5ldHdvcmsuCgoNCgUEAAIJBRIE8gECCAoNCgUE
AAIJARIE8gEJEAoNCgUEAAIJAxIE8gETFAoPCgUEAAIJCBIG8gEV9QEDChAKCAQAAgkInAgA
EgTzAQQqCg8KBwQAAgkInwgSBPQBBFAKOQoEBAACChIE+AECPhorIFJlcXVpcmVkLiBUaGUg
ZmlsdGVyIHRvIG1hdGNoIEw0IHRyYWZmaWMuCgoNCgUEAAIKBhIE+AECCAoNCgUEAAIKARIE
+AEJDwoNCgUEAAIKAxIE+AESFAoNCgUEAAIKCBIE+AEVPQoQCggEAAIKCJwIABIE+AEWPAry
AgoEBAACCxIE/wECPxrjAiBPcHRpb25hbC4gVGhlIHByaW9yaXR5IG9mIHRoaXMgcG9saWN5
LWJhc2VkIHJvdXRlLiBQcmlvcml0eSBpcyB1c2VkIHRvCiBicmVhayB0aWVzIGluIGNhc2Vz
IHdoZXJlIHRoZXJlIGFyZSBtb3JlIHRoYW4gb25lIG1hdGNoaW5nIHBvbGljeS1iYXNlZAog
cm91dGVzIGZvdW5kLiBJbiBjYXNlcyB3aGVyZSBtdWx0aXBsZSBwb2xpY3ktYmFzZWQgcm91
dGVzIGFyZSBtYXRjaGVkLCB0aGUKIG9uZSB3aXRoIHRoZSBsb3dlc3QtbnVtYmVyZWQgcHJp
b3JpdHkgdmFsdWUgd2lucy4gVGhlIGRlZmF1bHQgdmFsdWUgaXMKIDEwMDAuIFRoZSBwcmlv
cml0eSB2YWx1ZSBtdXN0IGJlIGZyb20gMSB0byA2NTUzNSwgaW5jbHVzaXZlLgoKDQoFBAAC
CwUSBP8BAgcKDQoFBAACCwESBP8BCBAKDQoFBAACCwMSBP8BExUKDQoFBAACCwgSBP8BFj4K
EAoIBAACCwicCAASBP8BFz0KjQEKBAQAAgwSBIMCAk4afyBPdXRwdXQgb25seS4gSWYgcG90
ZW50aWFsIG1pc2NvbmZpZ3VyYXRpb25zIGFyZSBkZXRlY3RlZCBmb3IgdGhpcyByb3V0ZSwK
IHRoaXMgZmllbGQgd2lsbCBiZSBwb3B1bGF0ZWQgd2l0aCB3YXJuaW5nIG1lc3NhZ2VzLgoK
DQoFBAACDAQSBIMCAgoKDQoFBAACDAYSBIMCCxMKDQoFBAACDAESBIMCFBwKDQoFBAACDAMS
BIMCHyEKDQoFBAACDAgSBIMCIk0KEAoIBAACDAicCAASBIMCI0wKUgoEBAACDRIEhgICRBpE
IE91dHB1dCBvbmx5LiBTZXJ2ZXItZGVmaW5lZCBmdWxseS1xdWFsaWZpZWQgVVJMIGZvciB0
aGlzIHJlc291cmNlLgoKDQoFBAACDQUSBIYCAggKDQoFBAACDQESBIYCCRIKDQoFBAACDQMS
BIYCFRcKDQoFBAACDQgSBIYCGEMKEAoIBAACDQicCAASBIYCGUIKggEKBAQAAg4SBIoCAj8a
dCBPdXRwdXQgb25seS4gVHlwZSBvZiB0aGlzIHJlc291cmNlLiBBbHdheXMKIG5ldHdvcmtj
b25uZWN0aXZpdHkjcG9saWN5QmFzZWRSb3V0ZSBmb3IgcG9saWN5LWJhc2VkIFJvdXRlIHJl
c291cmNlcy4KCg0KBQQAAg4FEgSKAgIICg0KBQQAAg4BEgSKAgkNCg0KBQQAAg4DEgSKAhAS
Cg0KBQQAAg4IEgSKAhM+ChAKCAQAAg4InAgAEgSKAhQ9CrEBCgIEARIGkAIApAIBGqIBIFJl
cXVlc3QgZm9yCiBbUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5MaXN0UG9saWN5QmFzZWRS
b3V0ZXNdW2dvb2dsZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YS5Qb2xpY3lC
YXNlZFJvdXRpbmdTZXJ2aWNlLkxpc3RQb2xpY3lCYXNlZFJvdXRlc10KIG1ldGhvZC4KCgsK
AwQBARIEkAIIJAo3CgQEAQIAEgaSAgKXAgQaJyBSZXF1aXJlZC4gVGhlIHBhcmVudCByZXNv
dXJjZSdzIG5hbWUuCgoNCgUEAQIABRIEkgICCAoNCgUEAQIAARIEkgIJDwoNCgUEAQIAAxIE
kgISEwoPCgUEAQIACBIGkgIUlwIDChAKCAQBAgAInAgAEgSTAgQqChEKBwQBAgAInwgSBpQC
BJYCBQpPCgQEAQIBEgSaAgIWGkEgVGhlIG1heGltdW0gbnVtYmVyIG9mIHJlc3VsdHMgcGVy
IHBhZ2UgdGhhdCBzaG91bGQgYmUgcmV0dXJuZWQuCgoNCgUEAQIBBRIEmgICBwoNCgUEAQIB
ARIEmgIIEQoNCgUEAQIBAxIEmgIUFQofCgQEAQICEgSdAgIYGhEgVGhlIHBhZ2UgdG9rZW4u
CgoNCgUEAQICBRIEnQICCAoNCgUEAQICARIEnQIJEwoNCgUEAQICAxIEnQIWFwpUCgQEAQID
EgSgAgIUGkYgQSBmaWx0ZXIgZXhwcmVzc2lvbiB0aGF0IGZpbHRlcnMgdGhlIHJlc3VsdHMg
bGlzdGVkIGluIHRoZSByZXNwb25zZS4KCg0KBQQBAgMFEgSgAgIICg0KBQQBAgMBEgSgAgkP
Cg0KBQQBAgMDEgSgAhITCjQKBAQBAgQSBKMCAhYaJiBTb3J0IHRoZSByZXN1bHRzIGJ5IGEg
Y2VydGFpbiBvcmRlci4KCg0KBQQBAgQFEgSjAgIICg0KBQQBAgQBEgSjAgkRCg0KBQQBAgQD
EgSjAhQVCrIBCgIEAhIGqQIAswIBGqMBIFJlc3BvbnNlIGZvcgogW1BvbGljeUJhc2VkUm91
dGluZ1NlcnZpY2UuTGlzdFBvbGljeUJhc2VkUm91dGVzXVtnb29nbGUuY2xvdWQubmV0d29y
a2Nvbm5lY3Rpdml0eS52MWJldGEuUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5MaXN0UG9s
aWN5QmFzZWRSb3V0ZXNdCiBtZXRob2QuCgoLCgMEAgESBKkCCCUKMwoEBAICABIEqwICNBol
IFBvbGljeS1iYXNlZCByb3V0ZXMgdG8gYmUgcmV0dXJuZWQuCgoNCgUEAgIABBIEqwICCgoN
CgUEAgIABhIEqwILGwoNCgUEAgIAARIEqwIcLwoNCgUEAgIAAxIEqwIyMwqhAQoEBAICARIE
rwICHRqSASBUaGUgbmV4dCBwYWdpbmF0aW9uIHRva2VuIGluIHRoZSBMaXN0IHJlc3BvbnNl
LiBJdCBzaG91bGQgYmUgdXNlZCBhcwogcGFnZV90b2tlbiBmb3IgdGhlIGZvbGxvd2luZyBy
ZXF1ZXN0LiBBbiBlbXB0eSB2YWx1ZSBtZWFucyBubyBtb3JlIHJlc3VsdC4KCg0KBQQCAgEF
EgSvAgIICg0KBQQCAgEBEgSvAgkYCg0KBQQCAgEDEgSvAhscCjQKBAQCAgISBLICAiIaJiBM
b2NhdGlvbnMgdGhhdCBjb3VsZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQCAgIEEgSyAgIKCg0K
BQQCAgIFEgSyAgsRCg0KBQQCAgIBEgSyAhIdCg0KBQQCAgIDEgSyAiAhCq0BCgIEAxIGuAIA
wAIBGp4BIFJlcXVlc3QgZm9yCiBbUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5HZXRQb2xp
Y3lCYXNlZFJvdXRlXVtnb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEu
UG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5HZXRQb2xpY3lCYXNlZFJvdXRlXQogbWV0aG9k
LgoKCwoDBAMBEgS4AggiCkkKBAQDAgASBroCAr8CBBo5IFJlcXVpcmVkLiBOYW1lIG9mIHRo
ZSBQb2xpY3lCYXNlZFJvdXRlIHJlc291cmNlIHRvIGdldC4KCg0KBQQDAgAFEgS6AgIICg0K
BQQDAgABEgS6AgkNCg0KBQQDAgADEgS6AhARCg8KBQQDAgAIEga6AhK/AgMKEAoIBAMCAAic
CAASBLsCBCoKEQoHBAMCAAifCBIGvAIEvgIFCrMBCgIEBBIGxQIA6gIBGqQBIFJlcXVlc3Qg
Zm9yCiBbUG9saWN5QmFzZWRSb3V0aW5nU2VydmljZS5DcmVhdGVQb2xpY3lCYXNlZFJvdXRl
XVtnb29nbGUuY2xvdWQubmV0d29ya2Nvbm5lY3Rpdml0eS52MWJldGEuUG9saWN5QmFzZWRS
b3V0aW5nU2VydmljZS5DcmVhdGVQb2xpY3lCYXNlZFJvdXRlXQogbWV0aG9kLgoKCwoDBAQB
EgTFAgglCk8KBAQEAgASBscCAswCBBo/IFJlcXVpcmVkLiBUaGUgcGFyZW50IHJlc291cmNl
J3MgbmFtZSBvZiB0aGUgUG9saWN5QmFzZWRSb3V0ZS4KCg0KBQQEAgAFEgTHAgIICg0KBQQE
AgABEgTHAgkPCg0KBQQEAgADEgTHAhITCg8KBQQEAgAIEgbHAhTMAgMKEAoIBAQCAAicCAAS
BMgCBCoKEQoHBAQCAAifCBIGyQIEywIFCpMECgQEBAIBEgTWAgJMGoQEIFJlcXVpcmVkLiBV
bmlxdWUgaWQgZm9yIHRoZSBwb2xpY3ktYmFzZWQgcm91dGUgdG8gY3JlYXRlLiBQcm92aWRl
ZCBieSB0aGUKIGNsaWVudCB3aGVuIHRoZSByZXNvdXJjZSBpcyBjcmVhdGVkLiBUaGUgbmFt
ZSBtdXN0IGNvbXBseSB3aXRoCiBodHRwczovL2dvb2dsZS5haXAuZGV2LzEyMiNyZXNvdXJj
ZS1pZC1zZWdtZW50cy4gU3BlY2lmaWNhbGx5LCB0aGUgbmFtZQogbXVzdCBiZSAxLTYzIGNo
YXJhY3RlcnMgbG9uZyBhbmQgbWF0Y2ggdGhlIHJlZ3VsYXIgZXhwcmVzc2lvbgogW2Etel0o
W2EtejAtOS1dKlthLXowLTldKT8uIFRoZSBmaXJzdCBjaGFyYWN0ZXIgbXVzdCBiZSBhIGxv
d2VyY2FzZSBsZXR0ZXIsCiBhbmQgYWxsIGZvbGxvd2luZyBjaGFyYWN0ZXJzIChleGNlcHQg
Zm9yIHRoZSBsYXN0IGNoYXJhY3RlcikgbXVzdCBiZSBhCiBkYXNoLCBsb3dlcmNhc2UgbGV0
dGVyLCBvciBkaWdpdC4gVGhlIGxhc3QgY2hhcmFjdGVyIG11c3QgYmUgYSBsb3dlcmNhc2UK
IGxldHRlciBvciBkaWdpdC4KCg0KBQQEAgEFEgTWAgIICg0KBQQEAgEBEgTWAgkeCg0KBQQE
AgEDEgTWAiEiCg0KBQQEAgEIEgTWAiNLChAKCAQEAgEInAgAEgTWAiRKCkgKBAQEAgISBtkC
AtoCLxo4IFJlcXVpcmVkLiBJbml0aWFsIHZhbHVlcyBmb3IgYSBuZXcgcG9saWN5LWJhc2Vk
IHJvdXRlLgoKDQoFBAQCAgYSBNkCAhIKDQoFBAQCAgESBNkCEyUKDQoFBAQCAgMSBNkCKCkK
DQoFBAQCAggSBNoCBi4KEAoIBAQCAgicCAASBNoCBy0KgwYKBAQEAgMSBOkCAkEa9AUgT3B0
aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNw
ZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgc28gdGhhdCBpZiB5b3UgbXVzdCByZXRyeSB5
b3VyIHJlcXVlc3QsIHRoZSBzZXJ2ZXIga25vd3MgdG8KIGlnbm9yZSB0aGUgcmVxdWVzdCBp
ZiBpdCBoYXMgYWxyZWFkeSBiZWVuIGNvbXBsZXRlZC4gVGhlIHNlcnZlciBndWFyYW50ZWVz
CiB0aGF0IGZvciBhdCBsZWFzdCA2MCBtaW51dGVzIHNpbmNlIHRoZSBmaXJzdCByZXF1ZXN0
LgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBh
biBpbml0aWFsIHJlcXVlc3QgYW5kCiB0aGUgcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBt
YWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdAogSUQsIHRoZSBz
ZXJ2ZXIgY2FuIGNoZWNrIGlmIG9yaWdpbmFsIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJl
cXVlc3QgSUQKIHdhcyByZWNlaXZlZCwgYW5kIGlmIHNvLCBpZ25vcmVzIHRoZSBzZWNvbmQg
cmVxdWVzdC4gVGhpcyBwcmV2ZW50cyBjbGllbnRzCiBmcm9tIGFjY2lkZW50YWxseSBjcmVh
dGluZyBkdXBsaWNhdGUgY29tbWl0bWVudHMuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBh
IHZhbGlkIFVVSUQgd2l0aCB0aGUgZXhjZXB0aW9uIHRoYXQgemVybyBVVUlEIGlzCiBub3Qg
c3VwcG9ydGVkICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoF
BAQCAwUSBOkCAggKDQoFBAQCAwESBOkCCRMKDQoFBAQCAwMSBOkCFhcKDQoFBAQCAwgSBOkC
GEAKEAoIBAQCAwicCAASBOkCGT8KswEKAgQFEgbvAgCGAwEapAEgUmVxdWVzdCBmb3IKIFtQ
b2xpY3lCYXNlZFJvdXRpbmdTZXJ2aWNlLkRlbGV0ZVBvbGljeUJhc2VkUm91dGVdW2dvb2ds
ZS5jbG91ZC5uZXR3b3JrY29ubmVjdGl2aXR5LnYxYmV0YS5Qb2xpY3lCYXNlZFJvdXRpbmdT
ZXJ2aWNlLkRlbGV0ZVBvbGljeUJhc2VkUm91dGVdCiBtZXRob2QuCgoLCgMEBQESBO8CCCUK
TgoEBAUCABIG8QIC9gIEGj4gUmVxdWlyZWQuIE5hbWUgb2YgdGhlIHBvbGljeS1iYXNlZCBy
b3V0ZSByZXNvdXJjZSB0byBkZWxldGUuCgoNCgUEBQIABRIE8QICCAoNCgUEBQIAARIE8QIJ
DQoNCgUEBQIAAxIE8QIQEQoPCgUEBQIACBIG8QIS9gIDChAKCAQFAgAInAgAEgTyAgQqChEK
BwQFAgAInwgSBvMCBPUCBQqDBgoEBAUCARIEhQMCQRr0BSBPcHRpb25hbC4gQW4gb3B0aW9u
YWwgcmVxdWVzdCBJRCB0byBpZGVudGlmeSByZXF1ZXN0cy4gU3BlY2lmeSBhIHVuaXF1ZQog
cmVxdWVzdCBJRCBzbyB0aGF0IGlmIHlvdSBtdXN0IHJldHJ5IHlvdXIgcmVxdWVzdCwgdGhl
IHNlcnZlciBrbm93cyB0bwogaWdub3JlIHRoZSByZXF1ZXN0IGlmIGl0IGhhcyBhbHJlYWR5
IGJlZW4gY29tcGxldGVkLiBUaGUgc2VydmVyIGd1YXJhbnRlZXMKIHRoYXQgZm9yIGF0IGxl
YXN0IDYwIG1pbnV0ZXMgYWZ0ZXIgdGhlIGZpcnN0IHJlcXVlc3QuCgogRm9yIGV4YW1wbGUs
IGNvbnNpZGVyIGEgc2l0dWF0aW9uIHdoZXJlIHlvdSBtYWtlIGFuIGluaXRpYWwgcmVxdWVz
dCBhbmQKIHRoZSByZXF1ZXN0IHRpbWVzIG91dC4gSWYgeW91IG1ha2UgdGhlIHJlcXVlc3Qg
YWdhaW4gd2l0aCB0aGUgc2FtZSByZXF1ZXN0CiBJRCwgdGhlIHNlcnZlciBjYW4gY2hlY2sg
aWYgb3JpZ2luYWwgb3BlcmF0aW9uIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2FzIHJl
Y2VpdmVkLCBhbmQgaWYgc28sIGlnbm9yZXMgdGhlIHNlY29uZCByZXF1ZXN0LiBUaGlzIHBy
ZXZlbnRzIGNsaWVudHMKIGZyb20gYWNjaWRlbnRhbGx5IGNyZWF0aW5nIGR1cGxpY2F0ZSBj
b21taXRtZW50cy4KCiBUaGUgcmVxdWVzdCBJRCBtdXN0IGJlIGEgdmFsaWQgVVVJRCB3aXRo
IHRoZSBleGNlcHRpb24gdGhhdCB6ZXJvIFVVSUQgaXMKIG5vdCBzdXBwb3J0ZWQgKDAwMDAw
MDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMCkuCgoNCgUEBQIBBRIEhQMCCAoNCgUE
BQIBARIEhQMJEwoNCgUEBQIBAxIEhQMWFwoNCgUEBQIBCBIEhQMYQAoQCggEBQIBCJwIABIE
hQMZP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute ===
    # Fields for PolicyBasedRoute
    # Field: virtual_machine Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.VirtualMachine)
    # Field: interconnect_attachment Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.InterconnectAttachment)
    # Field: next_hop_ilb_ip Type: 9 ()
    # Field: next_hop_other_routes Type: 14 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.OtherRoutes)
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: network Type: 9 ()
    # Field: filter Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.Filter)
    # Field: priority Type: 5 ()
    # Field: warnings Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute.Warnings)
    # Field: self_link Type: 9 ()
    # Field: kind Type: 9 ()

# Enum: PolicyBasedRoute::OtherRoutes
our $PolicyBasedRoute_OTHER_ROUTES_UNSPECIFIED = 0;
our $PolicyBasedRoute_DEFAULT_ROUTING = 1;

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesRequest ===
    # Fields for ListPolicyBasedRoutesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse ===
    # Fields for ListPolicyBasedRoutesResponse
    # Field: policy_based_routes Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::GetPolicyBasedRouteRequest ===
    # Fields for GetPolicyBasedRouteRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::CreatePolicyBasedRouteRequest ===
    # Fields for CreatePolicyBasedRouteRequest
    # Field: parent Type: 9 ()
    # Field: policy_based_route_id Type: 9 ()
    # Field: policy_based_route Type: 11 (.google.cloud.networkconnectivity.v1beta.PolicyBasedRoute)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::DeletePolicyBasedRouteRequest ===
    # Fields for DeletePolicyBasedRouteRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Service Client: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoutingServiceClient ===
package Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoutingServiceClient;

=pod

=head2 Service Client: Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoutingServiceClient

Client stub representing the remote C<PolicyBasedRoutingService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<networkconnectivity.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'networkconnectivity.googleapis.com:443' );

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

sub list_policy_based_routes {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService',
        method         => 'ListPolicyBasedRoutes',
        request        => $req,
        response_class => 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse',
    });
}

sub get_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::GetPolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService',
        method         => 'GetPolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute',
    });
}

sub create_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::CreatePolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService',
        method         => 'CreatePolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_policy_based_route {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::DeletePolicyBasedRouteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService',
        method         => 'DeletePolicyBasedRoute',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting - Compiled Protocol Buffers messages for google/cloud/networkconnectivity/v1beta/policy_based_routing.proto

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting;

    my $msg = Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute->new({
        virtual_machine => $virtual_machine,
        interconnect_attachment => $interconnect_attachment,
        next_hop_ilb_ip => $next_hop_ilb_ip,
        next_hop_other_routes => $next_hop_other_routes,
    });

    # Read or update a field
    my $val = $msg->virtual_machine();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networkconnectivity/v1beta/policy_based_routing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute

Policy-based routes route L4 network traffic based on not just destination IP
address, but also source IP address, protocol, and more. If a policy-based
route conflicts with other types of routes, the policy-based route always
takes precedence.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->virtual_machine() >> / C<< $msg->virtual_machine($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute::VirtualMachine>)

Optional. VM instances that this policy-based route applies to.

=item * C<< $msg->interconnect_attachment() >> / C<< $msg->interconnect_attachment($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute::InterconnectAttachment>)

Optional. The interconnect attachments that this policy-based route
applies to.

=item * C<< $msg->next_hop_ilb_ip() >> / C<< $msg->next_hop_ilb_ip($value) >>

Type: C<String>

Optional. The IP address of a global-access-enabled L4 ILB that is the
next hop for matching packets. For this version, only nextHopIlbIp is
supported.

=item * C<< $msg->next_hop_other_routes() >> / C<< $msg->next_hop_other_routes($value) >>

Type: C<Enum> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRoute::OtherRoutes>)

Optional. Other routes that will be referenced to determine the next hop
of the packet.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Identifier. A unique name of the resource in the form of
`projects/{project_number}/locations/global/PolicyBasedRoutes/{policy_based_route_id}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the policy-based route was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the policy-based route was updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute::LabelsEntry>)

User-defined labels.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. An optional description of this resource. Provide this field when
you create the resource.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Required. Fully-qualified URL of the network that this route applies to,
for example: projects/my-project/global/networks/my-network.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute::Filter>)

Required. The filter to match L4 traffic.

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Int32>

Optional. The priority of this policy-based route. Priority is used to
break ties in cases where there are more than one matching policy-based
routes found. In cases where multiple policy-based routes are matched, the
one with the lowest-numbered priority value wins. The default value is
1000. The priority value must be from 1 to 65535, inclusive.

=item * C<< $msg->warnings() >> / C<< $msg->warnings($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute::Warnings>)

Output only. If potential misconfigurations are detected for this route,
this field will be populated with warning messages.

=item * C<< $msg->self_link() >> / C<< $msg->self_link($value) >>

Type: C<String>

Output only. Server-defined fully-qualified URL for this resource.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

Output only. Type of this resource. Always
networkconnectivity#policyBasedRoute for policy-based Route resources.

=back

=head3 Enum: PolicyBasedRoute::OtherRoutes

=over 4

=item * C<OTHER_ROUTES_UNSPECIFIED> => C<0>

=item * C<DEFAULT_ROUTING> => C<1>

=back

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesRequest

Request for
[PolicyBasedRoutingService.ListPolicyBasedRoutes][google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService.ListPolicyBasedRoutes]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource's name.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of results per page that should be returned.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

A filter expression that filters the results listed in the response.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Sort the results by a certain order.

=back

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::ListPolicyBasedRoutesResponse

Response for
[PolicyBasedRoutingService.ListPolicyBasedRoutes][google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService.ListPolicyBasedRoutes]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->policy_based_routes() >> / C<< $msg->policy_based_routes($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute>)

Policy-based routes to be returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The next pagination token in the List response. It should be used as
page_token for the following request. An empty value means no more result.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::GetPolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.GetPolicyBasedRoute][google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService.GetPolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the PolicyBasedRoute resource to get.

=back

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::CreatePolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.CreatePolicyBasedRoute][google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService.CreatePolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource's name of the PolicyBasedRoute.

=item * C<< $msg->policy_based_route_id() >> / C<< $msg->policy_based_route_id($value) >>

Type: C<String>

Required. Unique id for the policy-based route to create. Provided by the
client when the resource is created. The name must comply with
https://google.aip.dev/122#resource-id-segments. Specifically, the name
must be 1-63 characters long and match the regular expression
[a-z]([a-z0-9-]*[a-z0-9])?. The first character must be a lowercase letter,
and all following characters (except for the last character) must be a
dash, lowercase letter, or digit. The last character must be a lowercase
letter or digit.

=item * C<< $msg->policy_based_route() >> / C<< $msg->policy_based_route($value) >>

Type: C<Message> (L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::PolicyBasedRoute>)

Required. Initial values for a new policy-based route.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server knows to
ignore the request if it has already been completed. The server guarantees
that for at least 60 minutes since the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, ignores the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::DeletePolicyBasedRouteRequest

Request for
[PolicyBasedRoutingService.DeletePolicyBasedRoute][google.cloud.networkconnectivity.v1beta.PolicyBasedRoutingService.DeletePolicyBasedRoute]
method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the policy-based route resource to delete.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID so that if you must retry your request, the server knows to
ignore the request if it has already been completed. The server guarantees
that for at least 60 minutes after the first request.

For example, consider a situation where you make an initial request and
the request times out. If you make the request again with the same request
ID, the server can check if original operation with the same request ID
was received, and if so, ignores the second request. This prevents clients
from accidentally creating duplicate commitments.

The request ID must be a valid UUID with the exception that zero UUID is
not supported (00000000-0000-0000-0000-000000000000).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networkconnectivity::V1beta::PolicyBasedRouting::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
