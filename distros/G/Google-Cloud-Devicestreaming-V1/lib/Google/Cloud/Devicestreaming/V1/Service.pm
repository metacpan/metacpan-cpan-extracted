package Google::Cloud::Devicestreaming::V1::Service;

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
    eval { require Google::Cloud::Devicestreaming::V1::AdbService };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGV2aWNlc3RyZWFtaW5nL3YxL3NlcnZpY2UucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjFnb29nbGUvY2xvdWQvZGV2aWNl
c3RyZWFtaW5nL3YxL2FkYl9zZXJ2aWNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRp
b24ucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90bxogZ29vZ2xlL3Byb3RvYnVm
L2ZpZWxkX21hc2sucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i9gEK
GkNyZWF0ZURldmljZVNlc3Npb25SZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitj
bG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSWgoO
ZGV2aWNlX3Nlc3Npb24YAiABKAsyLi5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYx
LkRldmljZVNlc3Npb25CA+BBAlINZGV2aWNlU2Vzc2lvbhIvChFkZXZpY2Vfc2Vzc2lvbl9p
ZBgEIAEoCUID4EEBUg9kZXZpY2VTZXNzaW9uSWQiywEKGUxpc3REZXZpY2VTZXNzaW9uc1Jl
cXVlc3QSSwoGcGFyZW50GAQgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3VyY2VtYW5hZ2VyLmdv
b2dsZWFwaXMuY29tL1Byb2plY3RSBnBhcmVudBIgCglwYWdlX3NpemUYASABKAVCA+BBAVII
cGFnZVNpemUSIgoKcGFnZV90b2tlbhgCIAEoCUID4EEBUglwYWdlVG9rZW4SGwoGZmlsdGVy
GAMgASgJQgPgQQFSBmZpbHRlciKdAQoaTGlzdERldmljZVNlc3Npb25zUmVzcG9uc2USVwoP
ZGV2aWNlX3Nlc3Npb25zGAEgAygLMi4uZ29vZ2xlLmNsb3VkLmRldmljZXN0cmVhbWluZy52
MS5EZXZpY2VTZXNzaW9uUg5kZXZpY2VTZXNzaW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiAB
KAlSDW5leHRQYWdlVG9rZW4iYwoXR2V0RGV2aWNlU2Vzc2lvblJlcXVlc3QSSAoEbmFtZRgB
IAEoCUI04EEC+kEuCixkZXZpY2VzdHJlYW1pbmcuZ29vZ2xlYXBpcy5jb20vRGV2aWNlU2Vz
c2lvblIEbmFtZSJmChpDYW5jZWxEZXZpY2VTZXNzaW9uUmVxdWVzdBJICgRuYW1lGAEgASgJ
QjTgQQL6QS4KLGRldmljZXN0cmVhbWluZy5nb29nbGVhcGlzLmNvbS9EZXZpY2VTZXNzaW9u
UgRuYW1lIroBChpVcGRhdGVEZXZpY2VTZXNzaW9uUmVxdWVzdBJaCg5kZXZpY2Vfc2Vzc2lv
bhgBIAEoCzIuLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuRGV2aWNlU2Vzc2lv
bkID4EECUg1kZXZpY2VTZXNzaW9uEkAKC3VwZGF0ZV9tYXNrGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLkZpZWxkTWFza0ID4EEBUgp1cGRhdGVNYXNrIqkKCg1EZXZpY2VTZXNzaW9uEhcK
BG5hbWUYASABKAlCA+BBAVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBA1ILZGlz
cGxheU5hbWUSVgoFc3RhdGUYAyABKA4yOy5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5n
LnYxLkRldmljZVNlc3Npb24uU2Vzc2lvblN0YXRlQgPgQQNSBXN0YXRlEm4KD3N0YXRlX2hp
c3RvcmllcxgOIAMoCzJALmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuRGV2aWNl
U2Vzc2lvbi5TZXNzaW9uU3RhdGVFdmVudEID4EEDUg5zdGF0ZUhpc3RvcmllcxIyCgN0dGwY
DSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAUgAUgN0dGwSQgoLZXhwaXJl
X3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFIAFIKZXhwaXJl
VGltZRJNChJpbmFjdGl2aXR5X3RpbWVvdXQYByABKAsyGS5nb29nbGUucHJvdG9idWYuRHVy
YXRpb25CA+BBA1IRaW5hY3Rpdml0eVRpbWVvdXQSQAoLY3JlYXRlX3RpbWUYCCABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSSwoRYWN0aXZlX3N0
YXJ0X3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSD2FjdGl2
ZVN0YXJ0VGltZRJaCg5hbmRyb2lkX2RldmljZRgPIAEoCzIuLmdvb2dsZS5jbG91ZC5kZXZp
Y2VzdHJlYW1pbmcudjEuQW5kcm9pZERldmljZUID4EECUg1hbmRyb2lkRGV2aWNlElEKC2Ns
aWVudF9pbmZvGBUgASgLMisuZ29vZ2xlLmNsb3VkLmRldmljZXN0cmVhbWluZy52MS5DbGll
bnRJbmZvQgPgQQFSCmNsaWVudEluZm8a5AEKEVNlc3Npb25TdGF0ZUV2ZW50EmUKDXNlc3Np
b25fc3RhdGUYASABKA4yOy5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLkRldmlj
ZVNlc3Npb24uU2Vzc2lvblN0YXRlQgPgQQNSDHNlc3Npb25TdGF0ZRI+CgpldmVudF90aW1l
GAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUglldmVudFRpbWUSKAoN
c3RhdGVfbWVzc2FnZRgDIAEoCUID4EEDUgxzdGF0ZU1lc3NhZ2UijAEKDFNlc3Npb25TdGF0
ZRIdChlTRVNTSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASDQoJUkVRVUVTVEVEEAESCwoHUEVO
RElORxACEgoKBkFDVElWRRADEgsKB0VYUElSRUQQBBIMCghGSU5JU0hFRBAFEg8KC1VOQVZB
SUxBQkxFEAYSCQoFRVJST1IQBzqFAepBgQEKLGRldmljZXN0cmVhbWluZy5nb29nbGVhcGlz
LmNvbS9EZXZpY2VTZXNzaW9uEjJwcm9qZWN0cy97cHJvamVjdH0vZGV2aWNlU2Vzc2lvbnMv
e2RldmljZV9zZXNzaW9ufSoOZGV2aWNlU2Vzc2lvbnMyDWRldmljZVNlc3Npb25CDAoKZXhw
aXJhdGlvbiJICgpDbGllbnRJbmZvEhsKBmNsaWVudBgBIAEoCUID4EECUgZjbGllbnQSHQoH
dmVyc2lvbhgCIAEoCUID4EEBUgd2ZXJzaW9uIrUBCg1BbmRyb2lkRGV2aWNlEi0KEGFuZHJv
aWRfbW9kZWxfaWQYASABKAlCA+BBAlIOYW5kcm9pZE1vZGVsSWQSMQoSYW5kcm9pZF92ZXJz
aW9uX2lkGAIgASgJQgPgQQJSEGFuZHJvaWRWZXJzaW9uSWQSGwoGbG9jYWxlGAMgASgJQgPg
QQFSBmxvY2FsZRIlCgtvcmllbnRhdGlvbhgEIAEoCUID4EEBUgtvcmllbnRhdGlvbjLgCQoT
RGlyZWN0QWNjZXNzU2VydmljZRLsAQoTQ3JlYXRlRGV2aWNlU2Vzc2lvbhI7Lmdvb2dsZS5j
bG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuQ3JlYXRlRGV2aWNlU2Vzc2lvblJlcXVlc3QaLi5n
b29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLkRldmljZVNlc3Npb24iaILT5JMCOCIm
L3YxL3twYXJlbnQ9cHJvamVjdHMvKn0vZGV2aWNlU2Vzc2lvbnM6DmRldmljZV9zZXNzaW9u
2kEncGFyZW50LGRldmljZV9zZXNzaW9uLGRldmljZV9zZXNzaW9uX2lkEsYBChJMaXN0RGV2
aWNlU2Vzc2lvbnMSOi5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLkxpc3REZXZp
Y2VTZXNzaW9uc1JlcXVlc3QaOy5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLkxp
c3REZXZpY2VTZXNzaW9uc1Jlc3BvbnNlIjeC0+STAigSJi92MS97cGFyZW50PXByb2plY3Rz
Lyp9L2RldmljZVNlc3Npb25z2kEGcGFyZW50ErMBChBHZXREZXZpY2VTZXNzaW9uEjguZ29v
Z2xlLmNsb3VkLmRldmljZXN0cmVhbWluZy52MS5HZXREZXZpY2VTZXNzaW9uUmVxdWVzdBou
Lmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjEuRGV2aWNlU2Vzc2lvbiI1gtPkkwIo
EiYvdjEve25hbWU9cHJvamVjdHMvKi9kZXZpY2VTZXNzaW9ucy8qfdpBBG5hbWUSpAEKE0Nh
bmNlbERldmljZVNlc3Npb24SOy5nb29nbGUuY2xvdWQuZGV2aWNlc3RyZWFtaW5nLnYxLkNh
bmNlbERldmljZVNlc3Npb25SZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5IjiC0+ST
AjIiLS92MS97bmFtZT1wcm9qZWN0cy8qL2RldmljZVNlc3Npb25zLyp9OmNhbmNlbDoBKhLu
AQoTVXBkYXRlRGV2aWNlU2Vzc2lvbhI7Lmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcu
djEuVXBkYXRlRGV2aWNlU2Vzc2lvblJlcXVlc3QaLi5nb29nbGUuY2xvdWQuZGV2aWNlc3Ry
ZWFtaW5nLnYxLkRldmljZVNlc3Npb24iaoLT5JMCRzI1L3YxL3tkZXZpY2Vfc2Vzc2lvbi5u
YW1lPXByb2plY3RzLyovZGV2aWNlU2Vzc2lvbnMvKn06DmRldmljZV9zZXNzaW9u2kEaZGV2
aWNlX3Nlc3Npb24sdXBkYXRlX21hc2sSbwoKQWRiQ29ubmVjdBIrLmdvb2dsZS5jbG91ZC5k
ZXZpY2VzdHJlYW1pbmcudjEuQWRiTWVzc2FnZRouLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJl
YW1pbmcudjEuRGV2aWNlTWVzc2FnZSIAKAEwARpSykEeZGV2aWNlc3RyZWFtaW5nLmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybULtAQojY29tLmdvb2dsZS5jbG91ZC5kZXZpY2VzdHJlYW1pbmcudjFCDFNlcnZpY2VQ
cm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2RldmljZXN0cmVhbWluZy9hcGl2MS9kZXZp
Y2VzdHJlYW1pbmdwYjtkZXZpY2VzdHJlYW1pbmdwYqoCH0dvb2dsZS5DbG91ZC5EZXZpY2VT
dHJlYW1pbmcuVjHKAh9Hb29nbGVcQ2xvdWRcRGV2aWNlU3RyZWFtaW5nXFYx6gIiR29vZ2xl
OjpDbG91ZDo6RGV2aWNlU3RyZWFtaW5nOjpWMUrOWgoHEgUOAM4CAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgAmCgkKAgMBEgMTACEK
CQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADsKCQoCAwUSAxcAKAoJCgIDBhIDGAAl
CgkKAgMHEgMZACoKCQoCAwgSAxoAKQoICgEIEgMcADwKCQoCCCUSAxwAPAoICgEIEgMdAGQK
CQoCCAsSAx0AZAoICgEIEgMeACIKCQoCCAoSAx4AIgoICgEIEgMfAC0KCQoCCAgSAx8ALQoI
CgEIEgMgADwKCQoCCAESAyAAPAoICgEIEgMhADwKCQoCCCkSAyEAPAoICgEIEgMiADsKCQoC
CC0SAyIAOwrlAwoCBgASBC4AbAEa2AMgQSBzZXJ2aWNlIGZvciBhbGxvY2F0aW5nIEFuZHJv
aWQgZGV2aWNlcyBhbmQgaW50ZXJhY3Rpbmcgd2l0aCB0aGUKIGxpdmUtYWxsb2NhdGVkIGRl
dmljZXMuCgogRWFjaCBTZXNzaW9uIHdpbGwgd2FpdCBmb3IgYXZhaWxhYmxlIGNhcGFjaXR5
LCBhdCBhIGhpZ2hlcgogcHJpb3JpdHkgb3ZlciBUZXN0IEV4ZWN1dGlvbi4gV2hlbiBhbGxv
Y2F0ZWQsIHRoZSBzZXNzaW9uIHdpbGwgYmUgZXhwb3NlZAogdGhyb3VnaCBhIHN0cmVhbSBm
b3IgaW50ZWdyYXRpb24uCgogRGlyZWN0QWNjZXNzU2VydmljZSBpcyBjdXJyZW50bHkgYXZh
aWxhYmxlIGFzIGEgcHJldmlldyB0byBzZWxlY3QgZGV2ZWxvcGVycy4KIFlvdSBjYW4gcmVn
aXN0ZXIgdG9kYXkgb24gYmVoYWxmIG9mIHlvdSBhbmQgeW91ciB0ZWFtIGF0CiBodHRwczov
L2RldmVsb3Blci5hbmRyb2lkLmNvbS9zdHVkaW8vcHJldmlldy9hbmRyb2lkLWRldmljZS1z
dHJlYW1pbmcKCgoKAwYAARIDLggbCgoKAwYAAxIDLwJGCgwKBQYAA5kIEgMvAkYKCwoDBgAD
EgQwAjE3Cg0KBQYAA5oIEgQwAjE3CigKBAYAAgASBDQCOwMaGiBDcmVhdGVzIGEgRGV2aWNl
U2Vzc2lvbi4KCgwKBQYAAgABEgM0BhkKDAoFBgACAAISAzQaNAoMCgUGAAIAAxIDND9MCg0K
BQYAAgAEEgQ1BDgGChEKCQYAAgAEsMq8IhIENQQ4BgoNCgUGAAIABBIEOQQ6MgoQCggGAAIA
BJsIABIEOQQ6Mgo/CgQGAAIBEgQ+AkQDGjEgTGlzdHMgRGV2aWNlU2Vzc2lvbnMgb3duZWQg
YnkgdGhlIHByb2plY3QgdXNlci4KCgwKBQYAAgEBEgM+BhgKDAoFBgACAQISAz4ZMgoMCgUG
AAIBAxIDPw8pCg0KBQYAAgEEEgRABEIGChEKCQYAAgEEsMq8IhIEQARCBgoMCgUGAAIBBBID
QwQ0Cg8KCAYAAgEEmwgAEgNDBDQKtQEKBAYAAgISBEkCTgMapgEgR2V0cyBhIERldmljZVNl
c3Npb24sIHdoaWNoIGRvY3VtZW50cyB0aGUgYWxsb2NhdGlvbiBzdGF0dXMgYW5kCiB3aGV0
aGVyIHRoZSBkZXZpY2UgaXMgYWxsb2NhdGVkLiBDbGllbnRzIG1ha2luZyByZXF1ZXN0cyBm
cm9tIHRoaXMgQVBJCiBtdXN0IHBvbGwgR2V0RGV2aWNlU2Vzc2lvbi4KCgwKBQYAAgIBEgNJ
BhYKDAoFBgACAgISA0kXLgoMCgUGAAICAxIDSTlGCg0KBQYAAgIEEgRKBEwGChEKCQYAAgIE
sMq8IhIESgRMBgoMCgUGAAICBBIDTQQyCg8KCAYAAgIEmwgAEgNNBDIKhQIKBAYAAgMSBFUC
WwMa9gEgQ2FuY2VsIGEgRGV2aWNlU2Vzc2lvbi4KIFRoaXMgUlBDIGNoYW5nZXMgdGhlIERl
dmljZVNlc3Npb24gdG8gc3RhdGUgRklOSVNIRUQgYW5kIHRlcm1pbmF0ZXMgYWxsCiBjb25u
ZWN0aW9ucy4KIENhbmNlbGVkIHNlc3Npb25zIGFyZSBub3QgZGVsZXRlZCBhbmQgY2FuIGJl
IHJldHJpZXZlZCBvcgogbGlzdGVkIGJ5IHRoZSB1c2VyIHVudGlsIHRoZXkgZXhwaXJlIGJh
c2VkIG9uIHRoZSAyOCBkYXkgZGVsZXRpb24gcG9saWN5LgoKDAoFBgACAwESA1UGGQoMCgUG
AAIDAhIDVRo0CgwKBQYAAgMDEgNWDyQKDQoFBgACAwQSBFcEWgYKEQoJBgACAwSwyrwiEgRX
BFoGCl4KBAYAAgQSBF8CZQMaUCBVcGRhdGVzIHRoZSBjdXJyZW50IERldmljZVNlc3Npb24g
dG8gdGhlIGZpZWxkcyBkZXNjcmliZWQgYnkgdGhlCiB1cGRhdGVfbWFzay4KCgwKBQYAAgQB
EgNfBhkKDAoFBgACBAISA18aNAoMCgUGAAIEAxIDXz9MCg0KBQYAAgQEEgRgBGMGChEKCQYA
AgQEsMq8IhIEYARjBgoMCgUGAAIEBBIDZARICg8KCAYAAgQEmwgAEgNkBEgK/QEKBAYAAgUS
A2sCRRrvASBFeHBvc2VzIGFuIEFEQiBjb25uZWN0aW9uIGlmIHRoZSBkZXZpY2Ugc3VwcG9y
dHMgQURCLgogZ1JQQyBoZWFkZXJzIGFyZSB1c2VkIHRvIGF1dGhlbnRpY2F0ZSB0aGUgQ29u
bmVjdCBSUEMsIGFzIHdlbGwgYXMKIGFzc29jaWF0ZSB0byBhIHBhcnRpY3VsYXIgRGV2aWNl
U2Vzc2lvbi4KIEluIHBhcnRpY3VsYXIsIHRoZSB1c2VyIG11c3Qgc3BlY2lmeSB0aGUgIlgt
T21uaWxhYi1TZXNzaW9uLU5hbWUiIGhlYWRlci4KCgwKBQYAAgUBEgNrBhAKDAoFBgACBQUS
A2sRFwoMCgUGAAIFAhIDaxgiCgwKBQYAAgUGEgNrLTMKDAoFBgACBQMSA2s0QQpLCgIEABIF
bwCCAQEaPiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERpcmVjdEFjY2Vzc1NlcnZpY2UuQ3JlYXRl
RGV2aWNlU2Vzc2lvbi4KCgoKAwQAARIDbwgiCngKBAQAAgASBHICdwQaaiBSZXF1aXJlZC4g
VGhlIENvbXB1dGUgRW5naW5lIHByb2plY3QgdW5kZXIgd2hpY2ggdGhpcyBkZXZpY2Ugd2ls
bCBiZQogYWxsb2NhdGVkLiAicHJvamVjdHMve3Byb2plY3RfaWR9IgoKDAoFBAACAAUSA3IC
CAoMCgUEAAIAARIDcgkPCgwKBQQAAgADEgNyEhMKDQoFBAACAAgSBHIUdwMKDwoIBAACAAic
CAASA3MEKgoPCgcEAAIACJ8IEgR0BHYFCjMKBAQAAgESA3oCTBomIFJlcXVpcmVkLiBBIERl
dmljZVNlc3Npb24gdG8gY3JlYXRlLgoKDAoFBAACAQYSA3oCDwoMCgUEAAIBARIDehAeCgwK
BQQAAgEDEgN6ISIKDAoFBAACAQgSA3ojSwoPCggEAAIBCJwIABIDeiRKCt0BCgQEAAICEgSB
AQJIGs4BIE9wdGlvbmFsLiBUaGUgSUQgdG8gdXNlIGZvciB0aGUgRGV2aWNlU2Vzc2lvbiwg
d2hpY2ggd2lsbCBiZWNvbWUgdGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIERldmljZVNl
c3Npb24ncyByZXNvdXJjZSBuYW1lLgoKIFRoaXMgdmFsdWUgc2hvdWxkIGJlIDQtNjMgY2hh
cmFjdGVycywgYW5kIHZhbGlkIGNoYXJhY3RlcnMKIGFyZSAvW2Etel1bMC05XS0vLgoKDQoF
BAACAgUSBIEBAggKDQoFBAACAgESBIEBCRoKDQoFBAACAgMSBIEBHR4KDQoFBAACAggSBIEB
H0cKEAoIBAACAgicCAASBIEBIEYKSwoCBAESBoUBAJcBARo9IFJlcXVlc3QgbWVzc2FnZSBm
b3IgRGlyZWN0QWNjZXNzU2VydmljZS5MaXN0RGV2aWNlU2Vzc2lvbnMuCgoLCgMEAQESBIUB
CCEKWwoEBAECABIGhwECjAEEGksgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQg
dG8gcmVxdWVzdCwgZS5nLiAicHJvamVjdHMve3Byb2plY3RfaWR9IgoKDQoFBAECAAUSBIcB
AggKDQoFBAECAAESBIcBCQ8KDQoFBAECAAMSBIcBEhMKDwoFBAECAAgSBocBFIwBAwoQCggE
AQIACJwIABIEiAEEKgoRCgcEAQIACJ8IEgaJAQSLAQUKSQoEBAECARIEjwECPxo7IE9wdGlv
bmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgRGV2aWNlU2Vzc2lvbnMgdG8gcmV0dXJuLgoK
DQoFBAECAQUSBI8BAgcKDQoFBAECAQESBI8BCBEKDQoFBAECAQMSBI8BFBUKDQoFBAECAQgS
BI8BFj4KEAoIBAECAQicCAASBI8BFz0KOgoEBAECAhIEkgECQRosIE9wdGlvbmFsLiBBIGNv
bnRpbnVhdGlvbiB0b2tlbiBmb3IgcGFnaW5nLgoKDQoFBAECAgUSBJIBAggKDQoFBAECAgES
BJIBCRMKDQoFBAECAgMSBJIBFhcKDQoFBAECAggSBJIBGEAKEAoIBAECAgicCAASBJIBGT8K
ewoEBAECAxIElgECPRptIE9wdGlvbmFsLiBJZiBzcGVjaWZpZWQsIHJlc3BvbnNlcyB3aWxs
IGJlIGZpbHRlcmVkIGJ5IHRoZSBnaXZlbiBmaWx0ZXIuCiBBbGxvd2VkIGZpZWxkcyBhcmU6
IHNlc3Npb25fc3RhdGUuCgoNCgUEAQIDBRIElgECCAoNCgUEAQIDARIElgEJDwoNCgUEAQID
AxIElgESEwoNCgUEAQIDCBIElgEUPAoQCggEAQIDCJwIABIElgEVOwpMCgIEAhIGmgEAoQEB
Gj4gUmVzcG9uc2UgbWVzc2FnZSBmb3IgRGlyZWN0QWNjZXNzU2VydmljZS5MaXN0RGV2aWNl
U2Vzc2lvbnMuCgoLCgMEAgESBJoBCCIKVgoEBAICABIEnAECLRpIIFRoZSBzZXNzaW9ucyBt
YXRjaGluZyB0aGUgc3BlY2lmaWVkIGZpbHRlciBpbiB0aGUgZ2l2ZW4gY2xvdWQgcHJvamVj
dC4KCg0KBQQCAgAEEgScAQIKCg0KBQQCAgAGEgScAQsYCg0KBQQCAgABEgScARkoCg0KBQQC
AgADEgScASssCpABCgQEAgIBEgSgAQIdGoEBIEEgdG9rZW4sIHdoaWNoIGNhbiBiZSBzZW50
IGFzIGBwYWdlX3Rva2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlLgogSWYgdGhpcyBm
aWVsZCBpcyBvbWl0dGVkLCB0aGVyZSBhcmUgbm8gc3Vic2VxdWVudCBwYWdlcy4KCg0KBQQC
AgEFEgSgAQIICg0KBQQCAgEBEgSgAQkYCg0KBQQCAgEDEgSgARscCkkKAgQDEgakAQCtAQEa
OyBSZXF1ZXN0IG1lc3NhZ2UgZm9yIERpcmVjdEFjY2Vzc1NlcnZpY2UuR2V0RGV2aWNlU2Vz
c2lvbi4KCgsKAwQDARIEpAEIHwpwCgQEAwIAEganAQKsAQQaYCBSZXF1aXJlZC4gTmFtZSBv
ZiB0aGUgRGV2aWNlU2Vzc2lvbiwgZS5nLgogInByb2plY3RzL3twcm9qZWN0X2lkfS9kZXZp
Y2VTZXNzaW9ucy97c2Vzc2lvbl9pZH0iCgoNCgUEAwIABRIEpwECCAoNCgUEAwIAARIEpwEJ
DQoNCgUEAwIAAxIEpwEQEQoPCgUEAwIACBIGpwESrAEDChAKCAQDAgAInAgAEgSoAQQqChEK
BwQDAgAInwgSBqkBBKsBBQpMCgIEBBIGsAEAuQEBGj4gUmVxdWVzdCBtZXNzYWdlIGZvciBE
aXJlY3RBY2Nlc3NTZXJ2aWNlLkNhbmNlbERldmljZVNlc3Npb24uCgoLCgMEBAESBLABCCIK
cAoEBAQCABIGswECuAEEGmAgUmVxdWlyZWQuIE5hbWUgb2YgdGhlIERldmljZVNlc3Npb24s
IGUuZy4KICJwcm9qZWN0cy97cHJvamVjdF9pZH0vZGV2aWNlU2Vzc2lvbnMve3Nlc3Npb25f
aWR9IgoKDQoFBAQCAAUSBLMBAggKDQoFBAQCAAESBLMBCQ0KDQoFBAQCAAMSBLMBEBEKDwoF
BAQCAAgSBrMBErgBAwoQCggEBAIACJwIABIEtAEEKgoRCgcEBAIACJ8IEga1AQS3AQUKTAoC
BAUSBrwBAMUBARo+IFJlcXVlc3QgbWVzc2FnZSBmb3IgRGlyZWN0QWNjZXNzU2VydmljZS5V
cGRhdGVEZXZpY2VTZXNzaW9uLgoKCwoDBAUBEgS8AQgiCrQBCgQEBQIAEgTAAQJMGqUBIFJl
cXVpcmVkLiBEZXZpY2VTZXNzaW9uIHRvIHVwZGF0ZS4KIFRoZSBEZXZpY2VTZXNzaW9uJ3Mg
YG5hbWVgIGZpZWxkIGlzIHVzZWQgdG8gaWRlbnRpZnkgdGhlIHNlc3Npb24gdG8gdXBkYXRl
CiAicHJvamVjdHMve3Byb2plY3RfaWR9L2RldmljZVNlc3Npb25zL3tzZXNzaW9uX2lkfSIK
Cg0KBQQFAgAGEgTAAQIPCg0KBQQFAgABEgTAARAeCg0KBQQFAgADEgTAASEiCg0KBQQFAgAI
EgTAASNLChAKCAQFAgAInAgAEgTAASRKCjkKBAQFAgESBsMBAsQBLxopIE9wdGlvbmFsLiBU
aGUgbGlzdCBvZiBmaWVsZHMgdG8gdXBkYXRlLgoKDQoFBAUCAQYSBMMBAhsKDQoFBAUCAQES
BMMBHCcKDQoFBAUCAQMSBMMBKisKDQoFBAUCAQgSBMQBBi4KEAoIBAUCAQicCAASBMQBBy0K
VwoCBAYSBsgBALICARpJIFByb3RvYnVmIG1lc3NhZ2UgZGVzY3JpYmluZyB0aGUgZGV2aWNl
IG1lc3NhZ2UsIHVzZWQgZnJvbSBzZXZlcmFsIFJQQ3MuCgoLCgMEBgESBMgBCBUKDQoDBAYH
EgbJAQLOAQQKDwoFBAYHnQgSBskBAs4BBAo7CgQEBgQAEgbRAQLyAQMaKyBUaGUgc3RhdGUg
dGhhdCB0aGUgRGV2aWNlU2Vzc2lvbiByZXNpZGVzLgoKDQoFBAYEAAESBNEBBxMKNgoGBAYE
AAIAEgTTAQQiGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoPCgcE
BgQAAgABEgTTAQQdCg8KBwQGBAACAAISBNMBICEKiAEKBgQGBAACARIE1wEEEhp4IEluaXRp
YWwgc3RhdGUgb2YgYSBzZXNzaW9uIHJlcXVlc3QuIFRoZSBzZXNzaW9uIGlzIGJlaW5nIHZh
bGlkYXRlZCBmb3IKIGNvcnJlY3RuZXNzIGFuZCBhIGRldmljZSBpcyBub3QgeWV0IHJlcXVl
c3RlZC4KCg8KBwQGBAACAQESBNcBBA0KDwoHBAYEAAIBAhIE1wEQEQpSCgYEBgQAAgISBNoB
BBAaQiBUaGUgc2Vzc2lvbiBoYXMgYmVlbiB2YWxpZGF0ZWQgYW5kIGlzIGluIHRoZSBxdWV1
ZSBmb3IgYSBkZXZpY2UuCgoPCgcEBgQAAgIBEgTaAQQLCg8KBwQGBAACAgISBNoBDg8KWAoG
BAYEAAIDEgTeAQQPGkggVGhlIHNlc3Npb24gaGFzIGJlZW4gZ3JhbnRlZCBhbmQgdGhlIGRl
dmljZSBpcyBhY2NlcHRpbmcKIGNvbm5lY3Rpb25zLgoKDwoHBAYEAAIDARIE3gEECgoPCgcE
BgQAAgMCEgTeAQ0OCnIKBgQGBAACBBIE4gEEEBpiIFRoZSBzZXNzaW9uIGR1cmF0aW9uIGV4
Y2VlZGVkIHRoZSBkZXZpY2UncyByZXNlcnZhdGlvbiB0aW1lIHBlcmlvZCBhbmQKIHRpbWVk
IG91dCBhdXRvbWF0aWNhbGx5LgoKDwoHBAYEAAIEARIE4gEECwoPCgcEBgQAAgQCEgTiAQ4P
CrwBCgYEBgQAAgUSBOcBBBEaqwEgVGhlIHVzZXIgaXMgZmluaXNoZWQgd2l0aCB0aGUgc2Vz
c2lvbiBhbmQgaXQgd2FzIGNhbmNlbGVkIGJ5IHRoZSB1c2VyCiB3aGlsZSB0aGUgcmVxdWVz
dCB3YXMgc3RpbGwgZ2V0dGluZyBhbGxvY2F0ZWQgb3IgYWZ0ZXIgYWxsb2NhdGlvbiBhbmQK
IGR1cmluZyBkZXZpY2UgdXNhZ2UgcGVyaW9kLgoKDwoHBAYEAAIFARIE5wEEDAoPCgcEBgQA
AgUCEgTnAQ8QCu8BCgYEBgQAAgYSBO0BBBQa3gEgVW5hYmxlIHRvIGNvbXBsZXRlIHRoZSBz
ZXNzaW9uIGJlY2F1c2UgdGhlIGRldmljZSB3YXMgdW5hdmFpbGFibGUgYW5kCiBpdCBmYWls
ZWQgdG8gYWxsb2NhdGUgdGhyb3VnaCB0aGUgc2NoZWR1bGVyLiBGb3IgZXhhbXBsZSwgYSBk
ZXZpY2Ugbm90CiBpbiB0aGUgY2F0YWxvZyB3YXMgcmVxdWVzdGVkIG9yIHRoZSByZXF1ZXN0
IGV4cGlyZWQgaW4gdGhlIGFsbG9jYXRpb24KIHF1ZXVlLgoKDwoHBAYEAAIGARIE7QEEDwoP
CgcEBgQAAgYCEgTtARITCmwKBgQGBAACBxIE8QEEDhpcIFVuYWJsZSB0byBjb21wbGV0ZSB0
aGUgc2Vzc2lvbiBmb3IgYW4gaW50ZXJuYWwgcmVhc29uLCBzdWNoIGFzIGFuCiBpbmZyYXN0
cnVjdHVyZSBmYWlsdXJlLgoKDwoHBAYEAAIHARIE8QEECQoPCgcEBgQAAgcCEgTxAQwNCoUB
CgQEBgMAEgb2AQKBAgMadSBBIG1lc3NhZ2UgZW5jYXBzdWxhdGluZyBhIHNlcmllcyBvZiBT
ZXNzaW9uIHN0YXRlcyBhbmQgdGhlIHRpbWUgdGhhdCB0aGUKIERldmljZVNlc3Npb24gZmly
c3QgZW50ZXJlZCB0aG9zZSBzdGF0ZXMuCgoNCgUEBgMAARIE9gEKGwpGCgYEBgMAAgASBPgB
BE8aNiBPdXRwdXQgb25seS4gVGhlIHNlc3Npb25fc3RhdGUgdHJhY2tlZCBieSB0aGlzIGV2
ZW50CgoPCgcEBgMAAgAGEgT4AQQQCg8KBwQGAwACAAESBPgBER4KDwoHBAYDAAIAAxIE+AEh
IgoPCgcEBgMAAgAIEgT4ASNOChIKCgQGAwACAAicCAASBPgBJE0KXwoGBAYDAAIBEgb8AQT9
ATQaTSBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhhdCB0aGUgc2Vzc2lvbl9zdGF0ZSBmaXJz
dCBlbmNvdW50ZXJlZCB0aGF0CiBzdGF0ZS4KCg8KBwQGAwACAQYSBPwBBB0KDwoHBAYDAAIB
ARIE/AEeKAoPCgcEBgMAAgEDEgT8ASssCg8KBwQGAwACAQgSBP0BCDMKEgoKBAYDAAIBCJwI
ABIE/QEJMgpNCgYEBgMAAgISBIACBEkaPSBPdXRwdXQgb25seS4gQSBodW1hbi1yZWFkYWJs
ZSBtZXNzYWdlIHRvIGV4cGxhaW4gdGhlIHN0YXRlLgoKDwoHBAYDAAICBRIEgAIECgoPCgcE
BgMAAgIBEgSAAgsYCg8KBwQGAwACAgMSBIACGxwKDwoHBAYDAAICCBIEgAIdSAoSCgoEBgMA
AgIInAgAEgSAAh5HCm4KBAQGAgASBIUCAjsaYCBPcHRpb25hbC4gTmFtZSBvZiB0aGUgRGV2
aWNlU2Vzc2lvbiwgZS5nLgogInByb2plY3RzL3twcm9qZWN0X2lkfS9kZXZpY2VTZXNzaW9u
cy97c2Vzc2lvbl9pZH0iCgoNCgUEBgIABRIEhQICCAoNCgUEBgIAARIEhQIJDQoNCgUEBgIA
AxIEhQIQEQoNCgUEBgIACBIEhQISOgoQCggEBgIACJwIABIEhQITOQpWCgQEBgIBEgSIAgJG
GkggT3V0cHV0IG9ubHkuIFRoZSB0aXRsZSBvZiB0aGUgRGV2aWNlU2Vzc2lvbiB0byBiZSBw
cmVzZW50ZWQgaW4gdGhlIFVJLgoKDQoFBAYCAQUSBIgCAggKDQoFBAYCAQESBIgCCRUKDQoF
BAYCAQMSBIgCGBkKDQoFBAYCAQgSBIgCGkUKEAoIBAYCAQicCAASBIgCG0QKQAoEBAYCAhIE
iwICRRoyIE91dHB1dCBvbmx5LiBDdXJyZW50IHN0YXRlIG9mIHRoZSBEZXZpY2VTZXNzaW9u
LgoKDQoFBAYCAgYSBIsCAg4KDQoFBAYCAgESBIsCDxQKDQoFBAYCAgMSBIsCFxgKDQoFBAYC
AggSBIsCGUQKEAoIBAYCAgicCAASBIsCGkMKggEKBAQGAgMSBo8CApACMhpyIE91dHB1dCBv
bmx5LiBUaGUgaGlzdG9yaWNhbCBzdGF0ZSB0cmFuc2l0aW9ucyBvZiB0aGUgc2Vzc2lvbl9z
dGF0ZSBtZXNzYWdlCiBpbmNsdWRpbmcgdGhlIGN1cnJlbnQgc2Vzc2lvbiBzdGF0ZS4KCg0K
BQQGAgMEEgSPAgIKCg0KBQQGAgMGEgSPAgscCg0KBQQGAgMBEgSPAh0sCg0KBQQGAgMDEgSP
Ai8xCg0KBQQGAgMIEgSQAgYxChAKCAQGAgMInAgAEgSQAgcwClMKBAQGCAASBpMCAp4CAxpD
IFRoZSBhbW91bnQgb2YgdGltZSB0aGF0IGEgZGV2aWNlIHdpbGwgYmUgaW5pdGlhbGx5IGFs
bG9jYXRlZCBmb3IuCgoNCgUEBggAARIEkwIIEgq1AQoEBAYCBBIElwIETxqmASBPcHRpb25h
bC4gVGhlIGFtb3VudCBvZiB0aW1lIHRoYXQgYSBkZXZpY2Ugd2lsbCBiZSBpbml0aWFsbHkg
YWxsb2NhdGVkCiBmb3IuIFRoaXMgY2FuIGV2ZW50dWFsbHkgYmUgZXh0ZW5kZWQgd2l0aCB0
aGUgVXBkYXRlRGV2aWNlU2Vzc2lvbiBSUEMuCiBEZWZhdWx0OiAxNSBtaW51dGVzLgoKDQoF
BAYCBAYSBJcCBBwKDQoFBAYCBAESBJcCHSAKDQoFBAYCBAMSBJcCIyUKDQoFBAYCBAgSBJcC
Jk4KEAoIBAYCBAicCAASBJcCJ00KpgEKBAQGAgUSBpwCBJ0CMRqVASBPcHRpb25hbC4gSWYg
dGhlIGRldmljZSBpcyBzdGlsbCBpbiB1c2UgYXQgdGhpcyB0aW1lLCBhbnkgY29ubmVjdGlv
bnMKIHdpbGwgYmUgZW5kZWQgYW5kIHRoZSBTZXNzaW9uU3RhdGUgd2lsbCB0cmFuc2l0aW9u
IGZyb20gQUNUSVZFIHRvCiBGSU5JU0hFRC4KCg0KBQQGAgUGEgScAgQdCg0KBQQGAgUBEgSc
Ah4pCg0KBQQGAgUDEgScAiwtCg0KBQQGAgUIEgSdAggwChAKCAQGAgUInAgAEgSdAgkvCpcB
CgQEBgIGEgaiAgKjAjIahgEgT3V0cHV0IG9ubHkuIFRoZSBpbnRlcnZhbCBvZiB0aW1lIHRo
YXQgdGhpcyBkZXZpY2UgbXVzdCBiZSBpbnRlcmFjdGVkIHdpdGgKIGJlZm9yZSBpdCB0cmFu
c2l0aW9ucyBmcm9tIEFDVElWRSB0byBUSU1FT1VUX0lOQUNUSVZJVFkuCgoNCgUEBgIGBhIE
ogICGgoNCgUEBgIGARIEogIbLQoNCgUEBgIGAxIEogIwMQoNCgUEBgIGCBIEowIGMQoQCggE
BgIGCJwIABIEowIHMApFCgQEBgIHEgamAgKnAjIaNSBPdXRwdXQgb25seS4gVGhlIHRpbWUg
dGhhdCB0aGUgU2Vzc2lvbiB3YXMgY3JlYXRlZC4KCg0KBQQGAgcGEgSmAgIbCg0KBQQGAgcB
EgSmAhwnCg0KBQQGAgcDEgSmAiorCg0KBQQGAgcIEgSnAgYxChAKCAQGAgcInAgAEgSnAgcw
ClIKBAQGAggSBqoCAqsCMhpCIE91dHB1dCBvbmx5LiBUaGUgdGltZXN0YW1wIHRoYXQgdGhl
IHNlc3Npb24gZmlyc3QgYmVjYW1lIEFDVElWRS4KCg0KBQQGAggGEgSqAgIbCg0KBQQGAggB
EgSqAhwtCg0KBQQGAggDEgSqAjAxCg0KBQQGAggIEgSrAgYxChAKCAQGAggInAgAEgSrAgcw
Ci8KBAQGAgkSBK4CAk0aISBSZXF1aXJlZC4gVGhlIHJlcXVlc3RlZCBkZXZpY2UuCgoNCgUE
BgIJBhIErgICDwoNCgUEBgIJARIErgIQHgoNCgUEBgIJAxIErgIhIwoNCgUEBgIJCBIErgIk
TAoQCggEBgIJCJwIABIErgIlSwpYCgQEBgIKEgSxAgJHGkogT3B0aW9uYWwuIEluZm9ybWF0
aW9uIGFib3V0IHRoZSBjbGllbnQgd2hpY2ggaW52b2tlZCB0aGUgZGV2aWNlIHNlc3Npb24u
CgoNCgUEBgIKBhIEsQICDAoNCgUEBgIKARIEsQINGAoNCgUEBgIKAxIEsQIbHQoNCgUEBgIK
CBIEsQIeRgoQCggEBgIKCJwIABIEsQIfRQpOCgIEBxIGtQIAuwIBGkAgSW5mb3JtYXRpb24g
YWJvdXQgdGhlIGNsaWVudCB3aGljaCBpbnZva2VkIHRoZSBkZXZpY2Ugc2Vzc2lvbi4KCgsK
AwQHARIEtQIIEgpbCgQEBwIAEgS3AgI9Gk0gUmVxdWlyZWQuIENsaWVudCBuYW1lLCBzdWNo
IGFzIGdjbG91ZC4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDY0IGNoYXJhY3RlcnMuCgoNCgUE
BwIABRIEtwICCAoNCgUEBwIAARIEtwIJDwoNCgUEBwIAAxIEtwISEwoNCgUEBwIACBIEtwIU
PAoQCggEBwIACJwIABIEtwIVOwpOCgQEBwIBEgS6AgI+GkAgT3B0aW9uYWwuIENsaWVudCB2
ZXJzaW9uLiBUaGUgbWF4aW11bSBsZW5ndGggaXMgNjQgY2hhcmFjdGVycy4KCg0KBQQHAgEF
EgS6AgIICg0KBQQHAgEBEgS6AgkQCg0KBQQHAgEDEgS6AhMUCg0KBQQHAgEIEgS6AhU9ChAK
CAQHAgEInAgAEgS6AhY8CigKAgQIEga+AgDOAgEaGiBBIHNpbmdsZSBBbmRyb2lkIGRldmlj
ZS4KCgsKAwQIARIEvgIIFQqFAQoEBAgCABIEwQICRxp3IFJlcXVpcmVkLiBUaGUgaWQgb2Yg
dGhlIEFuZHJvaWQgZGV2aWNlIHRvIGJlIHVzZWQuCiBVc2UgdGhlIFRlc3RFbnZpcm9ubWVu
dERpc2NvdmVyeVNlcnZpY2UgdG8gZ2V0IHN1cHBvcnRlZCBvcHRpb25zLgoKDQoFBAgCAAUS
BMECAggKDQoFBAgCAAESBMECCRkKDQoFBAgCAAMSBMECHB0KDQoFBAgCAAgSBMECHkYKEAoI
BAgCAAicCAASBMECH0UKiQEKBAQIAgESBMUCAkkaeyBSZXF1aXJlZC4gVGhlIGlkIG9mIHRo
ZSBBbmRyb2lkIE9TIHZlcnNpb24gdG8gYmUgdXNlZC4KIFVzZSB0aGUgVGVzdEVudmlyb25t
ZW50RGlzY292ZXJ5U2VydmljZSB0byBnZXQgc3VwcG9ydGVkIG9wdGlvbnMuCgoNCgUECAIB
BRIExQICCAoNCgUECAIBARIExQIJGwoNCgUECAIBAxIExQIeHwoNCgUECAIBCBIExQIgSAoQ
CggECAIBCJwIABIExQIhRwqJAQoEBAgCAhIEyQICPRp7IE9wdGlvbmFsLiBUaGUgbG9jYWxl
IHRoZSB0ZXN0IGRldmljZSB1c2VkIGZvciB0ZXN0aW5nLgogVXNlIHRoZSBUZXN0RW52aXJv
bm1lbnREaXNjb3ZlcnlTZXJ2aWNlIHRvIGdldCBzdXBwb3J0ZWQgb3B0aW9ucy4KCg0KBQQI
AgIFEgTJAgIICg0KBQQIAgIBEgTJAgkPCg0KBQQIAgIDEgTJAhITCg0KBQQIAgIIEgTJAhQ8
ChAKCAQIAgIInAgAEgTJAhU7CogBCgQECAIDEgTNAgJCGnogT3B0aW9uYWwuIEhvdyB0aGUg
ZGV2aWNlIGlzIG9yaWVudGVkIGR1cmluZyB0aGUgdGVzdC4KIFVzZSB0aGUgVGVzdEVudmly
b25tZW50RGlzY292ZXJ5U2VydmljZSB0byBnZXQgc3VwcG9ydGVkIG9wdGlvbnMuCgoNCgUE
CAIDBRIEzQICCAoNCgUECAIDARIEzQIJFAoNCgUECAIDAxIEzQIXGAoNCgUECAIDCBIEzQIZ
QQoQCggECAIDCJwIABIEzQIaQGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest ===
    # Fields for CreateDeviceSessionRequest
    # Field: parent Type: 9 ()
    # Field: device_session Type: 11 (.google.cloud.devicestreaming.v1.DeviceSession)
    # Field: device_session_id Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest ===
    # Fields for ListDeviceSessionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse ===
    # Fields for ListDeviceSessionsResponse
    # Field: device_sessions Type: 11 (.google.cloud.devicestreaming.v1.DeviceSession)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest ===
    # Fields for GetDeviceSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest ===
    # Fields for CancelDeviceSessionRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest ===
    # Fields for UpdateDeviceSessionRequest
    # Field: device_session Type: 11 (.google.cloud.devicestreaming.v1.DeviceSession)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Cloud::Devicestreaming::V1::Service::DeviceSession ===
    # Fields for DeviceSession
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: state Type: 14 (.google.cloud.devicestreaming.v1.DeviceSession.SessionState)
    # Field: state_histories Type: 11 (.google.cloud.devicestreaming.v1.DeviceSession.SessionStateEvent)
    # Field: ttl Type: 11 (.google.protobuf.Duration)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: inactivity_timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: active_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: android_device Type: 11 (.google.cloud.devicestreaming.v1.AndroidDevice)
    # Field: client_info Type: 11 (.google.cloud.devicestreaming.v1.ClientInfo)

# Enum: DeviceSession::SessionState
our $DeviceSession_SESSION_STATE_UNSPECIFIED = 0;
our $DeviceSession_REQUESTED = 1;
our $DeviceSession_PENDING = 2;
our $DeviceSession_ACTIVE = 3;
our $DeviceSession_EXPIRED = 4;
our $DeviceSession_FINISHED = 5;
our $DeviceSession_UNAVAILABLE = 6;
our $DeviceSession_ERROR = 7;

# === Message: Google::Cloud::Devicestreaming::V1::Service::ClientInfo ===
    # Fields for ClientInfo
    # Field: client Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Google::Cloud::Devicestreaming::V1::Service::AndroidDevice ===
    # Fields for AndroidDevice
    # Field: android_model_id Type: 9 ()
    # Field: android_version_id Type: 9 ()
    # Field: locale Type: 9 ()
    # Field: orientation Type: 9 ()

# === Service Client: Google::Cloud::Devicestreaming::V1::Service::DirectAccessServiceClient ===
package Google::Cloud::Devicestreaming::V1::Service::DirectAccessServiceClient;

=pod

=head2 Service Client: Google::Cloud::Devicestreaming::V1::Service::DirectAccessServiceClient

Client stub representing the remote C<DirectAccessService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devicestreaming.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devicestreaming.googleapis.com:443' );

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

sub create_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'CreateDeviceSession',
        request        => $req,
        response_class => 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession',
    });
}

sub list_device_sessions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'ListDeviceSessions',
        request        => $req,
        response_class => 'Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse',
    });
}

sub get_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'GetDeviceSession',
        request        => $req,
        response_class => 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession',
    });
}

sub cancel_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'CancelDeviceSession',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub update_device_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'UpdateDeviceSession',
        request        => $req,
        response_class => 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession',
    });
}

sub adb_connect {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Devicestreaming::V1::AdbService::AdbMessage->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.devicestreaming.v1.DirectAccessService',
        method         => 'AdbConnect',
        request        => $req,
        response_class => 'Google::Cloud::Devicestreaming::V1::AdbService::DeviceMessage',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Devicestreaming::V1::Service - Compiled Protocol Buffers messages for google/cloud/devicestreaming/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Devicestreaming::V1::Service;

    my $msg = Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest->new({
        parent => $parent,
        device_session => $device_session,
        device_session_id => $device_session_id,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/devicestreaming/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest

Request message for DirectAccessService.CreateDeviceSession.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The Compute Engine project under which this device will be
allocated. "projects/{project_id}"

=item * C<< $msg->device_session() >> / C<< $msg->device_session($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::DeviceSession>)

Required. A DeviceSession to create.

=item * C<< $msg->device_session_id() >> / C<< $msg->device_session_id($value) >>

Type: C<String>

Optional. The ID to use for the DeviceSession, which will become the final
component of the DeviceSession's resource name.

This value should be 4-63 characters, and valid characters
are /[a-z][0-9]-/.

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest

Request message for DirectAccessService.ListDeviceSessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the parent to request, e.g. "projects/{project_id}"

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of DeviceSessions to return.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A continuation token for paging.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. If specified, responses will be filtered by the given filter.
Allowed fields are: session_state.

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse

Response message for DirectAccessService.ListDeviceSessions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->device_sessions() >> / C<< $msg->device_sessions($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::DeviceSession>)

The sessions matching the specified filter in the given cloud project.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest

Request message for DirectAccessService.GetDeviceSession.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DeviceSession, e.g.
"projects/{project_id}/deviceSessions/{session_id}"

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest

Request message for DirectAccessService.CancelDeviceSession.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the DeviceSession, e.g.
"projects/{project_id}/deviceSessions/{session_id}"

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest

Request message for DirectAccessService.UpdateDeviceSession.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->device_session() >> / C<< $msg->device_session($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::DeviceSession>)

Required. DeviceSession to update.
The DeviceSession's `name` field is used to identify the session to update
"projects/{project_id}/deviceSessions/{session_id}"

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Optional. The list of fields to update.

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::DeviceSession

Protobuf message describing the device message, used from several RPCs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Name of the DeviceSession, e.g.
"projects/{project_id}/deviceSessions/{session_id}"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The title of the DeviceSession to be presented in the UI.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Devicestreaming::V1::DeviceSession::SessionState>)

Output only. Current state of the DeviceSession.

=item * C<< $msg->state_histories() >> / C<< $msg->state_histories($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::DeviceSession::SessionStateEvent>)

Output only. The historical state transitions of the session_state message
including the current session state.

=item * C<< $msg->ttl() >> / C<< $msg->ttl($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The amount of time that a device will be initially allocated
for. This can eventually be extended with the UpdateDeviceSession RPC.
Default: 15 minutes.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. If the device is still in use at this time, any connections
will be ended and the SessionState will transition from ACTIVE to
FINISHED.

=item * C<< $msg->inactivity_timeout() >> / C<< $msg->inactivity_timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Output only. The interval of time that this device must be interacted with
before it transitions from ACTIVE to TIMEOUT_INACTIVITY.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time that the Session was created.

=item * C<< $msg->active_start_time() >> / C<< $msg->active_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp that the session first became ACTIVE.

=item * C<< $msg->android_device() >> / C<< $msg->android_device($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::AndroidDevice>)

Required. The requested device.

=item * C<< $msg->client_info() >> / C<< $msg->client_info($value) >>

Type: C<Message> (L<Google::Cloud::Devicestreaming::V1::Service::ClientInfo>)

Optional. Information about the client which invoked the device session.

=back

=head3 Enum: DeviceSession::SessionState

=over 4

=item * C<SESSION_STATE_UNSPECIFIED> => C<0>

=item * C<REQUESTED> => C<1>

=item * C<PENDING> => C<2>

=item * C<ACTIVE> => C<3>

=item * C<EXPIRED> => C<4>

=item * C<FINISHED> => C<5>

=item * C<UNAVAILABLE> => C<6>

=item * C<ERROR> => C<7>

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::ClientInfo

Information about the client which invoked the device session.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->client() >> / C<< $msg->client($value) >>

Type: C<String>

Required. Client name, such as gcloud. The maximum length is 64 characters.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Optional. Client version. The maximum length is 64 characters.

=back

=head2 Google::Cloud::Devicestreaming::V1::Service::AndroidDevice

A single Android device.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->android_model_id() >> / C<< $msg->android_model_id($value) >>

Type: C<String>

Required. The id of the Android device to be used.
Use the TestEnvironmentDiscoveryService to get supported options.

=item * C<< $msg->android_version_id() >> / C<< $msg->android_version_id($value) >>

Type: C<String>

Required. The id of the Android OS version to be used.
Use the TestEnvironmentDiscoveryService to get supported options.

=item * C<< $msg->locale() >> / C<< $msg->locale($value) >>

Type: C<String>

Optional. The locale the test device used for testing.
Use the TestEnvironmentDiscoveryService to get supported options.

=item * C<< $msg->orientation() >> / C<< $msg->orientation($value) >>

Type: C<String>

Optional. How the device is oriented during the test.
Use the TestEnvironmentDiscoveryService to get supported options.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Devicestreaming::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
